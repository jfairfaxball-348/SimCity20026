extends RefCounted
## D33 / M2g: home desirability, growth order, held homes, drops, recovery and schema 8.
const City = preload("res://scripts/sim/city_state.gd")
const Clock = preload("res://scripts/sim/simulation_clock.gd")
const Codec = preload("res://scripts/persistence/save_codec.gd")
const Balance = preload("res://content/balance.gd")
const FIXTURE: String = "res://tests/fixtures/m2g-schema8.json"
const FIXTURE_SHA: String = "beaeb0b9fee8d13c091b1c995be90a33f57a418fbe219abe1f44a6219a51ee61"
var t: SceneTree
var growth = preload("res://tests/growth_tests.gd").new()

func days(city: City, count: int) -> void:
	growth.days(city, count)

func at(city: City, x: int, y: int) -> int:
	return city.index(Vector2i(x, y))

## Sets development directly (fixture-style) and rebuilds derived state.
func develop(city: City, levels: Dictionary) -> void:
	for anchor in levels: city.development[int(anchor)] = int(levels[anchor])
	city.rebuild_derived()

func to_round(city: City) -> void:
	while city.tick % Balance.GROWTH_DAYS != Balance.GROWTH_DAYS - 1: days(city, 1)
	days(city, 1)

func run(tester: SceneTree) -> void:
	t = tester
	growth.t = t
	test_scores()
	test_order()
	test_held()
	test_with_leaving()
	test_fixture()
	print("PASS group: M2g desirability, order, held homes, drops, recovery and schema 8")

func test_scores() -> void:
	var c: City = t.land(24, 16)
	c.apply_command("road", t.row(8, 0, 23))
	c.apply_command("home", [Vector2i(10, 5)])
	var h: int = at(c, 10, 5)
	t.check(c.desirability.lot_score[h] == 0 and c.desirability.parts(c, h) == "", "a home with no surroundings scores 0")
	c.apply_command("workshop", [Vector2i(10, 9), Vector2i(13, 9)])
	var across: int = at(c, 10, 9)
	var farther: int = at(c, 13, 9)
	t.check(c.desirability.lot_score[h] == 0, "empty workshop lots cause no nuisance")
	develop(c, {across: 1})
	t.check(c.desirability.lot_score[h] == -2 and c.desirability.parts(c, h) == "industry −2" and c.desirability.cap(c, h) == Balance.HELD_LEVEL, "a developed workshop across a one-tile road (2 steps) deters: −2, held at level 1")
	develop(c, {farther: 2})
	t.check(c.desirability.lot_score[h] == -2 and c.desirability.lot_workshops[h] == 1, "a workshop 3 steps away causes no nuisance")
	c.apply_command("park", [Vector2i(9, 3)])
	t.check(c.desirability.lot_score[h] == 0 and c.desirability.parts(c, h) == "park +2, industry −2" and c.desirability.cap(c, h) == Balance.MAX_LEVEL, "a park within 3 steps offsets one workshop")
	c.apply_command("workshop", [Vector2i(7, 5), Vector2i(13, 5), Vector2i(10, 2)])
	develop(c, {at(c, 7, 5): 1, at(c, 13, 5): 2, at(c, 10, 2): 1})
	t.check(c.desirability.lot_workshops[h] == 4 and c.desirability.lot_score[h] == -4 and c.desirability.parts(c, h) == "park +2, industry −6", "nuisance counts at most three workshops (floor −6)")
	t.check(c.desirability.tile_score[at(c, 11, 6)] == c.desirability.lot_score[h], "overlay shows a home lot's own score on its tiles")
	t.check(c.desirability.tile_score[at(c, 11, 12)] == -2 and c.desirability.tile_score[at(c, 22, 14)] == 0, "overlay field: −2 beside one workshop, 0 far away")
	t.check(c.desirability.tile_score[at(c, 9, 0)] == 2, "overlay field: +2 within a park's reach")
	var shore: City = t.land(16, 12)
	for y in range(12): shore.terrain[shore.index(Vector2i(0, y))] = City.WATER
	shore.rebuild_derived()
	shore.apply_command("home", [Vector2i(3, 4), Vector2i(4, 8)])
	t.check(shore.desirability.lot_score[shore.index(Vector2i(3, 4))] == 1 and shore.desirability.parts(shore, shore.index(Vector2i(3, 4))) == "water +1", "water within 3 steps adds +1")
	t.check(shore.desirability.lot_score[shore.index(Vector2i(4, 8))] == 0, "water 4 steps away adds nothing")
	t.check(shore.desirability.tile_score[shore.index(Vector2i(3, 0))] == 1 and shore.desirability.tile_score[shore.index(Vector2i(4, 0))] == 0, "overlay water reach is 3 steps")
	var land: City = t.land(16, 12)
	land.apply_command("home", [Vector2i(3, 4)])
	t.check(land.desirability.lot_score[land.index(Vector2i(3, 4))] == 0, "all-land map has no stale water bonus after terrain setup")

func test_order() -> void:
	var c: City = t.land(24, 12)
	c.apply_command("road", t.row(6, 4, 23))
	c.apply_command("power", [Vector2i(0, 5)])
	c.apply_command("home", t.lots_row(3, 4, 4))
	c.apply_command("park", [Vector2i(14, 0)])
	var h: Array[int] = [at(c, 4, 3), at(c, 7, 3), at(c, 10, 3), at(c, 13, 3)]
	days(c, 5)
	t.check(c.development[h[3]] == 1 and c.development[h[0]] == 1 and c.development[h[1]] == 1 and c.development[h[2]] == 0, "the park-covered home grows first, then map order (D26 order kept)")
	var n: City = t.land(24, 12)
	n.apply_command("road", t.row(6, 4, 23))
	n.apply_command("power", [Vector2i(0, 5)])
	n.apply_command("home", t.lots_row(3, 4, 6))
	n.apply_command("workshop", [Vector2i(4, 7)])
	develop(n, {at(n, 4, 7): 1})
	t.check(n.growth.demand[City.HOME] == 5, "four workshop jobs make five home levels of demand")
	days(n, 5)
	var others: bool = true
	for x in [7, 10, 13, 16, 19]: others = others and n.development[at(n, x, 3)] == 1
	t.check(n.development[at(n, 4, 3)] == 0 and others, "the home beside the workshop grows last despite the lowest map index")

func held_town() -> City:
	var c: City = t.land(24, 12)
	c.apply_command("road", t.row(6, 4, 23))
	c.apply_command("power", [Vector2i(0, 5)])
	c.apply_command("home", [Vector2i(10, 3)])
	c.apply_command("workshop", [Vector2i(10, 7)])
	develop(c, {at(c, 10, 3): 2, at(c, 10, 7): 1})
	return c

func test_held() -> void:
	var c: City = held_town()
	var h: int = at(c, 10, 3)
	var occupancy: PackedByteArray = c.occupancy.duplicate()
	var cash: int = c.cash
	t.check(c.growth.dropping[h] == 1 and c.growth.reason(c, h) == "dropping", "a level-2 home beside a developed workshop is marked to drop")
	var copy: City = Codec.decode(c.canonical()).city
	to_round(c)
	t.check(c.development[h] == 1 and c.growth.reason(c, h) == "held" and c.growth.demand[City.HOME] > 0, "it drops one level and is then held at level 1 despite demand")
	to_round(c)
	to_round(c)
	t.check(c.development[h] == 1 and c.occupancy == occupancy and c.cash == cash, "held homes stay at level 1; nothing is demolished and no cash changes")
	c.apply_command("park", [Vector2i(11, 1)])
	t.check(c.desirability.lot_score[h] == 0 and c.growth.reason(c, h) != "held", "a park within 3 steps lifts the hold")
	to_round(c)
	t.check(c.development[h] == 2, "with the hold lifted the home regrows to level 2")
	to_round(copy)
	copy.apply_command("clear", [Vector2i(11, 8)])
	t.check(copy.desirability.lot_score[at(copy, 10, 3)] == 0, "clearing the workshop removes the nuisance")
	to_round(copy)
	t.check(copy.development[at(copy, 10, 3)] == 2, "after clearing the workshop the home regrows to level 2")
	# Determinism and continuation with held homes.
	var a: City = held_town()
	var b: City = Codec.decode(a.canonical()).city
	for item: City in [a, b]:
		days(item, 17)
		item.apply_command("park", [Vector2i(11, 1)])
		days(item, 23)
	t.check(a.canonical() == b.canonical() and a.canonical().contains("\"schema_version\":8"), "schema-8 save/load continuation matches the uninterrupted town")

func test_with_leaving() -> void:
	var c: City = growth.town()
	var levels: Dictionary = {}
	for x in [4, 7, 10, 13, 16, 19]: levels[at(c, x, 3)] = 2
	levels[at(c, 4, 7)] = 2
	levels[at(c, 7, 7)] = 1
	levels[at(c, 13, 7)] = 2
	levels[at(c, 16, 7)] = 1
	develop(c, levels)
	c.set_tax_rate(25)
	var held: Array[int] = [at(c, 13, 3), at(c, 16, 3)]
	t.check(c.growth.dropping[held[0]] == 1 and c.growth.dropping[held[1]] == 1 and c.growth.leaving.count(1) - _business_leaving(c) == 2, "two nuisance drops count towards the four home levels leaving under high taxes")
	var before: Dictionary = {}
	for x in [4, 7, 10, 13, 16, 19]: before[x] = c.development[at(c, x, 3)]
	to_round(c)
	var lost: int = 0
	var each_one: bool = true
	for x in [4, 7, 10, 13, 16, 19]:
		var drop: int = int(before[x]) - c.development[at(c, x, 3)]
		lost += drop
		each_one = each_one and drop <= 1
	t.check(lost == Balance.LEAVE_LIMIT and each_one, "drops and tax leaving remove four home levels in one round, at most one per lot")

func _business_leaving(c: City) -> int:
	var n: int = 0
	for a in c.lot_anchors:
		if c.occupancy[a] != City.HOME and c.growth.leaving[a] != 0: n += 1
	return n

func test_fixture() -> void:
	t.check(FileAccess.get_sha256(FIXTURE) == FIXTURE_SHA, "schema-8 fixture hash")
	var text: String = FileAccess.get_file_as_string(FIXTURE).strip_edges()
	var loaded: Dictionary = Codec.decode(text)
	t.check(loaded.ok and loaded.migrated_from == 0 and loaded.city.canonical() == text, "schema-8 fixture exact round trip")
	if not loaded.ok: return
	var c: City = loaded.city
	var rescued: int = at(c, 13, 3)
	var held: int = at(c, 16, 3)
	t.check(c.desirability.parts(c, rescued) == "park +2, industry −2" and c.development[rescued] == 2 and c.growth.reason(c, held) == "held" and c.development[held] == 1, "schema-8 fixture: the park rescues one home while its neighbour stays held")
	var opening: int = c.cash
	c.advance_day()
	t.check(c.tick == 60 and c.cash == opening + 17000 and c.growth.population == 44 and c.pending_us == 234567, "schema-8 fixture settles exactly $170 with 44 residents")
