extends RefCounted
## D37 / R2b: levels 0-4, capacities, land-value and workforce gates, drops, leaving
## order, wealth, a park town past the old ceiling, schema 10 and the r2b fixture.
const City = preload("res://scripts/sim/city_state.gd")
const Codec = preload("res://scripts/persistence/save_codec.gd")
const Balance = preload("res://content/balance.gd")
const Summary = preload("res://scripts/presentation/town_summary.gd")
const FIXTURE: String = "res://tests/fixtures/r2b-schema10.json"
const FIXTURE_SHA: String = "b838fe109e76ba2500b21d6ba3ae722d8ec106afe4c9fec3aa2afa23d1534041"
var t: SceneTree
var growth = preload("res://tests/growth_tests.gd").new()

func days(city: City, count: int) -> void:
	growth.days(city, count)

func at(city: City, x: int, y: int) -> int:
	return city.index(Vector2i(x, y))

func develop(city: City, levels: Dictionary) -> void:
	for anchor in levels: city.development[int(anchor)] = int(levels[anchor])
	city.rebuild_derived()

## The standard street. With covered, the map is two rows taller and a police station
## at (10,10) and a fire station at (13,10) sit on a side road (x 23, row 13), so every
## lot from x 4 to 21 is within the D38 reach of both.
func street(covered: bool = false) -> City:
	var c: City = t.land(24, 14 if covered else 12)
	c.apply_command("road", t.row(6, 4, 23))
	c.apply_command("power", [Vector2i(0, 5)])
	if covered: cover(c)
	return c

func cover(c: City) -> void:
	c.apply_command("road", t.join(t.column(23, 7, 13), t.row(13, 10, 22)))
	c.apply_command("police", [Vector2i(10, 10)])
	c.apply_command("fire", [Vector2i(13, 10)])

## The fixture's park town: six residential lots, three parks, three commercial and
## three industrial lots on the standard street.
func park_town(covered: bool = true) -> City:
	var c: City = street(covered)
	c.apply_command("home", t.lots_row(3, 4, 6))
	for x in [5, 11, 17]: c.apply_command("park", [Vector2i(x, 1)])
	c.apply_command("shop", t.lots_row(7, 4, 3))
	c.apply_command("workshop", t.lots_row(7, 13, 3))
	return c

func run(tester: SceneTree) -> void:
	t = tester
	growth.t = t
	test_capacities()
	test_gates()
	test_workforce()
	test_drops_and_leaving()
	test_park_town()
	test_saves()
	print("PASS group: R2b levels 0-4, gates, drops, leaving order, wealth and schema 10")

func test_capacities() -> void:
	t.check(Balance.MAX_LEVEL == 4 and Balance.capacity(City.HOME, 1) == 4 and Balance.capacity(City.HOME, 2) == 8 and Balance.capacity(City.HOME, 3) == 20 and Balance.capacity(City.HOME, 4) == 40, "residential lots hold 4 / 8 / 20 / 40 residents at levels 1-4")
	t.check(Balance.capacity(City.SHOP, 2) == 4 and Balance.capacity(City.SHOP, 4) == 20 and Balance.capacity(City.WORKSHOP, 2) == 8 and Balance.capacity(City.WORKSHOP, 4) == 28 and Balance.capacity(City.ROAD, 3) == 0, "commercial and industrial capacities, unchanged at levels 1-2")
	var c: City = street()
	c.apply_command("home", [Vector2i(4, 3), Vector2i(7, 3)])
	c.apply_command("workshop", [Vector2i(4, 7)])
	develop(c, {at(c, 4, 3): 4, at(c, 7, 3): 3, at(c, 4, 7): 3})
	t.check(c.growth.population == 60 and c.growth.jobs == 16 and c.budget.residents == 60 and c.budget.jobs == 16, "totals and the budget forecast sum per-level capacities (40 + 20 residents, 16 jobs)")
	t.check(c.power.total_used == 3, "each lot still uses one power unit at every level")

func test_gates() -> void:
	var c: City = street(true)
	for x in range(4, 7): c.terrain[c.index(Vector2i(x, 0))] = City.WATER
	c.rebuild_derived()
	c.apply_command("home", [Vector2i(4, 3), Vector2i(10, 3), Vector2i(16, 3)])
	c.apply_command("park", [Vector2i(17, 1)])
	var water_home: int = at(c, 4, 3)
	var plain: int = at(c, 10, 3)
	var park_home: int = at(c, 16, 3)
	t.check(c.desirability.lot_score[plain] == 0 and c.desirability.cap(c, plain) == Balance.GATED_LEVEL, "a residential lot with land value 0 stops at level 2")
	t.check(c.desirability.lot_score[water_home] == 1 and c.desirability.cap(c, water_home) == 3, "water (+1) lets a residential lot reach level 3")
	t.check(c.desirability.lot_score[park_home] == 2 and c.desirability.cap(c, park_home) == 4, "a park (+2) lets a residential lot reach level 4")
	develop(c, {plain: 2, water_home: 3, park_home: 4})
	t.check(c.growth.reason(c, plain) == "gated" and c.growth.reason(c, water_home) == "gated" and c.growth.reason(c, park_home) == "full", "gated and full reasons at the caps")
	t.check(c.desirability.wealth(c, plain) == "modest" and c.desirability.wealth(c, water_home) == "comfortable" and c.desirability.wealth(c, park_home) == "well-off" and c.desirability.wealth(c, at(c, 4, 7)) == "", "wealth bands follow land value on developed residential lots only")
	var shops: City = street(true)
	shops.apply_command("home", [Vector2i(4, 3), Vector2i(16, 3)])
	shops.apply_command("shop", [Vector2i(4, 7), Vector2i(16, 7)])
	shops.apply_command("park", [Vector2i(17, 10)])
	develop(shops, {at(shops, 4, 3): 2, at(shops, 16, 3): 2})
	var trade_only: int = at(shops, 4, 7)
	var trade_park: int = at(shops, 16, 7)
	t.check(shops.desirability.lot_score[trade_only] == 1 and shops.desirability.cap(shops, trade_only) == Balance.GATED_LEVEL, "commercial trade alone keeps a commercial lot at level 2")
	t.check(shops.desirability.lot_score[trade_park] == 3 and shops.desirability.cap(shops, trade_park) == 3, "commercial value 3 (trade plus a park) reaches level 3")
	shops.apply_command("home", [Vector2i(19, 3)])
	develop(shops, {at(shops, 19, 3): 1})
	t.check(shops.desirability.lot_score[trade_park] == 4 and shops.desirability.cap(shops, trade_park) == 4, "commercial value 4 reaches level 4")

func test_workforce() -> void:
	var c: City = street(true)
	c.apply_command("home", t.lots_row(3, 4, 6))
	c.apply_command("workshop", [Vector2i(19, 7)])
	var industry: int = at(c, 19, 7)
	develop(c, {at(c, 4, 3): 4, at(c, 7, 3): 4, at(c, 10, 3): 2})
	t.check(c.growth.population == 88 and c.desirability.cap(c, industry) == Balance.GATED_LEVEL, "industry stops at level 2 below 100 residents")
	develop(c, {at(c, 13, 3): 3})
	t.check(c.growth.population == 108 and c.desirability.cap(c, industry) == 3, "100 residents let industry reach level 3")
	c.apply_command("home", [Vector2i(4, 7), Vector2i(7, 7)])
	develop(c, {at(c, 10, 3): 4, at(c, 13, 3): 4, at(c, 16, 3): 4, at(c, 19, 3): 4, at(c, 4, 7): 4, at(c, 7, 7): 4})
	t.check(c.growth.population >= Balance.WORKFORCE_LEVEL4 and c.desirability.cap(c, industry) == 4, "250 residents let industry reach level 4")
	develop(c, {industry: 2})
	t.check(c.growth.reason(c, industry) != "gated", "a level-2 industrial lot with a large workforce is not gated")
	var small: City = street()
	small.apply_command("home", [Vector2i(4, 3), Vector2i(7, 3)])
	small.apply_command("workshop", [Vector2i(19, 7)])
	develop(small, {at(small, 4, 3): 4, at(small, 7, 3): 4, at(small, 19, 7): 2})
	var room: Dictionary = {}
	for entry in Summary.build(small):
		if String(entry.kind) == "no_room" and int(entry.zone) == City.WORKSHOP: room = entry
	t.check(small.growth.demand[City.WORKSHOP] > 0 and "grow the town past 100 residents" in String(room.get("text", "")) and not "land value" in String(room.get("text", "")), "the summary tells gated industry to grow the workforce, not land value")

func test_drops_and_leaving() -> void:
	var c: City = street(true)
	c.apply_command("home", [Vector2i(16, 3)])
	c.apply_command("park", [Vector2i(17, 1)])
	var home: int = at(c, 16, 3)
	develop(c, {home: 4})
	t.check(c.growth.reason(c, home) == "full" and c.growth.dropping[home] == 0, "a park-covered level-4 lot is full")
	var cash: int = c.cash
	c.apply_command("clear", [Vector2i(17, 1)])
	t.check(c.desirability.cap(c, home) == Balance.GATED_LEVEL and c.growth.dropping[home] == 1 and c.growth.reason(c, home) == "dropping", "clearing the park marks the level-4 lot to drop")
	days(c, 5)
	t.check(c.development[home] == 3 and c.growth.dropping[home] == 1 and c.cash == cash, "it drops one level per round, without demolition")
	days(c, 5)
	t.check(c.development[home] == 2 and c.growth.dropping[home] == 0 and c.growth.reason(c, home) == "gated", "it settles at level 2, gated")
	c.apply_command("park", [Vector2i(17, 1)])
	t.check(c.desirability.cap(c, home) == 4, "a new park lifts the gate again")
	var l: City = street(true)
	l.apply_command("home", t.lots_row(3, 4, 6))
	for x in [5, 11, 17]: l.apply_command("park", [Vector2i(x, 1)])
	var homes: Array[int] = []
	for x in [4, 7, 10, 13, 16, 19]: homes.append(at(l, x, 3))
	# Park-covered lots at x 4, 10 and 16 may pass level 2; the others stay at level 1.
	develop(l, {homes[0]: 2, homes[1]: 1, homes[2]: 4, homes[3]: 1, homes[4]: 3, homes[5]: 1})
	l.set_tax_rate(25)
	var marked: Array[int] = []
	for h in homes:
		if l.growth.leaving[h] != 0: marked.append(h)
	t.check(marked == [homes[0], homes[2], homes[4], homes[5]], "high taxes take the level-4 lot, then level 3, then level 2, then later map order")

func test_park_town() -> void:
	var c: City = park_town()
	days(c, 50)
	t.check(c.growth.population == 104 and c.growth.jobs == 44, "a park town grows past the old 48-resident ceiling to 104 residents / 44 jobs")
	var levels: PackedByteArray = c.development.duplicate()
	days(c, 150)
	t.check(c.development == levels and c.growth.population == 104, "it then settles: no change over 150 more days")
	t.check(c.development.count(4) == 2 and c.development[at(c, 19, 7)] == 3, "two residential lots reach level 4 and the industrial lot nearest the link level 3")
	# D38: the same town without police and fire stops at level 3.
	var bare: City = park_town(false)
	days(bare, 200)
	t.check(bare.development.count(4) == 0 and bare.development[at(bare, 4, 3)] == 3 and bare.growth.reason(bare, at(bare, 4, 3)) == "uncovered", "without police and fire the park town stops at level 3, explained as uncovered")
	var b: City = park_town()
	var m: City = Codec.decode(b.canonical()).city
	days(b, 60)
	days(m, 60)
	t.check(b.canonical() == m.canonical(), "save/load continuation of the park town matches the uninterrupted town")

func test_saves() -> void:
	t.check(FileAccess.get_sha256(FIXTURE) == FIXTURE_SHA, "schema-10 fixture hash")
	var text: String = FileAccess.get_file_as_string(FIXTURE).strip_edges()
	var loaded: Dictionary = Codec.decode(text)
	# D38: schema 10 now migrates; services_tests checks the drop of its uncovered level-4 lots.
	t.check(loaded.ok and loaded.migrated_from == 10 and loaded.city.canonical() == t.migrated_text(text), "schema-10 fixture migrates with every value kept")
	if loaded.ok:
		var c: City = loaded.city
		t.check(c.development[at(c, 4, 3)] == 4 and c.development[at(c, 19, 7)] == 3 and c.growth.reason(c, at(c, 7, 3)) == "gated" and c.growth.reason(c, at(c, 13, 3)) == "held", "schema-10 fixture holds level-4, level-3, gated and held lots")
	var data: Dictionary = JSON.parse_string(text)
	data.development[at(loaded.city, 4, 3)] = 5
	t.check(not Codec.decode(JSON.stringify(data)).ok, "schema 10 rejects level 5")
	var nine: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/r2a-schema9.json"))
	var lot: int = 3 * 24 + 4
	nine.development[lot] = 3
	t.check(not Codec.decode(JSON.stringify(nine)).ok, "earlier schemas still reject levels above 2")
	var ledger: Dictionary = JSON.parse_string(text)
	ledger.last_budget.residents = 3000
	t.check(Codec.decode(JSON.stringify(ledger)).ok, "schema-10 ledgers allow more residents than the old 8-per-cell bound")
	ledger.last_budget.residents = int(ledger.width) * int(ledger.height) * 40 + 1
	t.check(not Codec.decode(JSON.stringify(ledger)).ok, "and reject more")
	var every: bool = true
	for fixture in ["m1-schema1", "m2a-schema1", "m2b-schema2", "m2c-schema3", "m2d-schema4", "m3a-schema5", "m2e-schema6", "m2f-schema7", "m2g-schema8", "r2a-schema9", "r2b-schema10"]:
		var result: Dictionary = Codec.decode(FileAccess.get_file_as_string("res://tests/fixtures/%s.json" % fixture))
		every = every and result.ok and int(result.migrated_from) > 0 and result.city.canonical().contains("\"schema_version\":%d" % City.SCHEMA)
	t.check(every, "every earlier fixture loads and resaves as the current schema")
