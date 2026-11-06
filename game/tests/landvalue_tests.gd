extends RefCounted
## D36 / R2a: land value for every zone, commercial order and holds, industrial
## freight order, schema 9 and the r2a fixture.
const City = preload("res://scripts/sim/city_state.gd")
const Codec = preload("res://scripts/persistence/save_codec.gd")
const Balance = preload("res://content/balance.gd")
const Summary = preload("res://scripts/presentation/town_summary.gd")
const FIXTURE: String = "res://tests/fixtures/r2a-schema9.json"
const FIXTURE_SHA: String = "a9684518451dc8dad85b0026e4b0cf2371c82e7d5f2406d17a37ac53d0081ab4"
var t: SceneTree
var growth = preload("res://tests/growth_tests.gd").new()

func days(city: City, count: int) -> void:
	growth.days(city, count)

func at(city: City, x: int, y: int) -> int:
	return city.index(Vector2i(x, y))

func develop(city: City, levels: Dictionary) -> void:
	for anchor in levels: city.development[int(anchor)] = int(levels[anchor])
	city.rebuild_derived()

## A 24x12 street from the outside link at (23,6) with a 4x4 plant at its west end.
func street() -> City:
	var c: City = t.land(24, 12)
	c.apply_command("road", t.row(6, 4, 23))
	c.apply_command("power", [Vector2i(0, 5)])
	return c

func run(tester: SceneTree) -> void:
	t = tester
	growth.t = t
	test_values()
	test_commercial()
	test_drops()
	test_freight()
	test_recovery_and_purity()
	test_saves()
	print("PASS group: R2a land value, commercial order and holds, industrial freight and schema 9")

func test_values() -> void:
	var c: City = street()
	c.apply_command("home", t.lots_row(3, 4, 6))
	c.apply_command("shop", [Vector2i(10, 7)])
	c.apply_command("workshop", [Vector2i(13, 7), Vector2i(16, 7)])
	var shop: int = at(c, 10, 7)
	t.check(c.desirability.lot_score[shop] == 0 and c.desirability.parts(c, shop) == "", "an empty town gives a commercial lot no value parts")
	develop(c, {at(c, 10, 3): 1})
	t.check(c.desirability.lot_customers[shop] == 1 and c.desirability.parts(c, shop) == "trade +1", "a developed residential lot 2 steps away is one customer (+1)")
	develop(c, {at(c, 7, 3): 1, at(c, 13, 3): 1, at(c, 4, 3): 1, at(c, 16, 3): 1})
	t.check(c.desirability.lot_customers[shop] == 3 and c.desirability.customers(shop) == 2, "residential lots 3 steps away count, 6 steps away do not, and customers cap at +2")
	develop(c, {at(c, 13, 7): 1})
	t.check(c.desirability.lot_score[shop] == 0 and c.desirability.parts(c, shop) == "trade +2, industry −2", "developed industry beside a commercial lot lowers it by 2")
	t.check(c.desirability.lot_score[at(c, 16, 7)] == 0 and c.desirability.parts(c, at(c, 16, 7)) == "", "industry does not lower an industrial lot's value")
	t.check(c.desirability.lot_score[at(c, 13, 3)] == -2 and c.desirability.cap(c, at(c, 13, 3)) == Balance.HELD_LEVEL, "residential rules are unchanged (D33)")
	t.check(c.desirability.tile_score[at(c, 11, 8)] == c.desirability.lot_score[shop], "overlay shows a commercial lot's own value on its tiles")
	var lone: City = street()
	lone.apply_command("shop", [Vector2i(10, 7)])
	lone.apply_command("workshop", [Vector2i(13, 7)])
	develop(lone, {at(lone, 13, 7): 1})
	t.check(lone.desirability.lot_score[at(lone, 10, 7)] == -2 and lone.desirability.cap(lone, at(lone, 10, 7)) == Balance.HELD_LEVEL, "a commercial lot below 0 is held at level 1")

func test_commercial() -> void:
	var c: City = street()
	c.apply_command("home", [Vector2i(16, 3), Vector2i(19, 3)])
	c.apply_command("shop", [Vector2i(4, 7), Vector2i(19, 7)])
	develop(c, {at(c, 16, 3): 1, at(c, 19, 3): 1})
	t.check(c.growth.demand[City.SHOP] == 1 and c.desirability.lot_score[at(c, 19, 7)] == 2, "eight residents make one commercial level of demand; the lot beside them has customers +2")
	days(c, 5)
	t.check(c.development[at(c, 19, 7)] == 1 and c.development[at(c, 4, 7)] == 0, "the commercial lot with higher land value grows first despite a later map index")
	var held: City = street()
	held.apply_command("home", t.lots_row(3, 4, 6))
	held.apply_command("shop", [Vector2i(10, 7)])
	held.apply_command("workshop", [Vector2i(13, 7)])
	develop(held, {at(held, 4, 3): 2, at(held, 16, 3): 2, at(held, 19, 3): 1, at(held, 13, 7): 1})
	t.check(held.desirability.lot_score[at(held, 10, 7)] == -2 and held.growth.demand[City.SHOP] > 0, "a commercial lot beside industry with no customers is below 0 despite demand")
	days(held, 5)
	t.check(held.development[at(held, 10, 7)] == 1 and held.growth.reason(held, at(held, 10, 7)) == "held", "it grows to level 1 and is then held")
	var items: Array = Summary.build(held)
	var item: Dictionary = {}
	for entry in items:
		if String(entry.kind) == "held": item = entry
	t.check(int(item.get("count", 0)) == 1 and "1 commercial lot held at level 1" in String(item.get("text", "")), "the summary names a held commercial lot")

func test_drops() -> void:
	var c: City = street()
	c.apply_command("shop", [Vector2i(4, 7), Vector2i(7, 7), Vector2i(10, 7), Vector2i(16, 7), Vector2i(19, 7)])
	c.apply_command("workshop", [Vector2i(13, 7)])
	var shops: Array[int] = [at(c, 4, 7), at(c, 7, 7), at(c, 10, 7), at(c, 16, 7), at(c, 19, 7)]
	var levels: Dictionary = {at(c, 13, 7): 1}
	for s in shops: levels[s] = 2
	develop(c, levels)
	t.check(c.growth.dropping[shops[2]] == 1 and c.growth.dropping[shops[3]] == 1 and c.growth.reason(c, shops[2]) == "dropping", "serviced level-2 commercial lots below 0 are marked to drop")
	c.set_tax_rate(25)
	var leaving: Array[int] = []
	for s in shops:
		if c.growth.leaving[s] != 0: leaving.append(s)
	t.check(leaving == [shops[1], shops[4]], "two commercial drops count towards the four levels leaving; the others leave later map order first")
	var before: Dictionary = {}
	for s in shops: before[s] = c.development[s]
	var occupancy: PackedByteArray = c.occupancy.duplicate()
	days(c, 5)
	var lost: int = 0
	var one_each: bool = true
	for s in shops:
		lost += int(before[s]) - c.development[s]
		one_each = one_each and int(before[s]) - c.development[s] <= 1
	t.check(lost == Balance.LEAVE_LIMIT and one_each and c.occupancy == occupancy, "four commercial levels go in one round, at most one per lot, and nothing is demolished")

func test_freight() -> void:
	var c: City = street()
	c.apply_command("home", [Vector2i(10, 3)])
	c.apply_command("workshop", [Vector2i(4, 7), Vector2i(19, 7), Vector2i(10, 0)])
	t.check(c.desirability.road_steps[at(c, 23, 6)] == 0 and c.desirability.road_steps[at(c, 4, 6)] == 19, "road steps count from the link road (0)")
	t.check(c.desirability.lot_freight[at(c, 19, 7)] == 2 and c.desirability.lot_freight[at(c, 4, 7)] == 17 and c.desirability.lot_freight[at(c, 10, 0)] == -1, "a lot's freight is the nearest connected road beside it; a lot with no road has none")
	develop(c, {at(c, 10, 3): 1})
	t.check(c.growth.demand[City.WORKSHOP] == 1, "four residents make one industrial level of demand")
	days(c, 5)
	t.check(c.development[at(c, 19, 7)] == 1 and c.development[at(c, 4, 7)] == 0, "the industrial lot nearer the link grows first despite a later map index")
	var cut: City = street()
	cut.apply_command("workshop", [Vector2i(19, 7)])
	cut.apply_command("clear", [Vector2i(23, 6)])
	t.check(cut.desirability.lot_freight[at(cut, 19, 7)] == -1, "without the link road there is no freight distance")

func test_recovery_and_purity() -> void:
	var c: City = street()
	c.apply_command("home", t.lots_row(3, 4, 6))
	c.apply_command("shop", [Vector2i(10, 7)])
	c.apply_command("workshop", [Vector2i(13, 7)])
	develop(c, {at(c, 4, 3): 2, at(c, 16, 3): 2, at(c, 19, 3): 1, at(c, 13, 7): 1, at(c, 10, 7): 1})
	t.check(c.growth.reason(c, at(c, 10, 7)) == "held", "the commercial lot starts held")
	var cash: int = c.cash
	c.apply_command("clear", [Vector2i(14, 8)])
	t.check(c.desirability.lot_score[at(c, 10, 7)] >= 0 and c.cash == cash, "clearing the industry (free) lifts the hold")
	days(c, 5)
	t.check(c.development[at(c, 10, 7)] == 2, "the commercial lot then regrows to level 2")
	var a: City = street()
	a.apply_command("home", t.lots_row(3, 4, 6))
	a.apply_command("shop", [Vector2i(4, 7), Vector2i(16, 7)])
	a.apply_command("workshop", [Vector2i(13, 7), Vector2i(19, 7)])
	var before: String = a.canonical()
	var state: int = a.rng.state
	var scores: PackedInt32Array = a.desirability.lot_score.duplicate()
	var freight: PackedInt32Array = a.desirability.lot_freight.duplicate()
	a.desirability.rebuild(a)
	t.check(a.canonical() == before and a.rng.state == state and a.desirability.lot_score == scores and a.desirability.lot_freight == freight, "rebuilding land value is pure and repeatable")
	var b: City = Codec.decode(a.canonical()).city
	days(a, 40)
	days(b, 40)
	t.check(a.canonical() == b.canonical() and a.canonical().contains("\"schema_version\":%d" % City.SCHEMA), "current-schema save/load continuation matches the uninterrupted town")

func test_saves() -> void:
	t.check(FileAccess.get_sha256(FIXTURE) == FIXTURE_SHA, "schema-9 fixture hash")
	var text: String = FileAccess.get_file_as_string(FIXTURE).strip_edges()
	var loaded: Dictionary = Codec.decode(text)
	t.check(loaded.ok and loaded.migrated_from == 9 and loaded.cleared_tiles == 0 and loaded.city.canonical() == t.migrated_text(text), "schema-9 fixture migrates with every value kept")
	if loaded.ok:
		var c: City = loaded.city
		t.check(c.growth.reason(c, at(c, 16, 7)) == "held" and c.development[at(c, 16, 7)] == 1 and c.desirability.parts(c, at(c, 16, 7)) == "trade +2, industry −4", "schema-9 fixture holds a commercial lot between two industrial lots")
		t.check(c.development[at(c, 19, 7)] == 2 and c.development[at(c, 13, 7)] == 1 and c.desirability.lot_freight[at(c, 19, 7)] == 2, "schema-9 fixture: the industrial lot nearest the link grew first")
		var opening: int = c.cash
		c.advance_day()
		t.check(c.tick == 60 and c.cash == opening + 17200 and c.growth.population == 40 and c.pending_us == 234567, "schema-9 fixture settles exactly $172 with 40 residents")
	var every: bool = true
	for fixture in ["m1-schema1", "m2a-schema1", "m2b-schema2", "m2c-schema3", "m2d-schema4", "m3a-schema5", "m2e-schema6", "m2f-schema7", "m2g-schema8"]:
		var result: Dictionary = Codec.decode(FileAccess.get_file_as_string("res://tests/fixtures/%s.json" % fixture))
		every = every and result.ok and int(result.migrated_from) > 0 and Codec.decode(result.city.canonical()).ok and result.city.canonical().contains("\"schema_version\":%d" % City.SCHEMA)
	t.check(every, "every earlier fixture loads and resaves as the current schema")
	var eight: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/m2g-schema8.json"))
	eight.simulation_version = "r2a-1"
	eight.content_version = "r2a-1"
	t.check(not Codec.decode(JSON.stringify(eight)).ok, "schema 8 with the r2a version strings is rejected")
