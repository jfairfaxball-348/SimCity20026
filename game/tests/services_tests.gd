extends RefCounted
## D38 / R2c: police and fire stations: placement, working, coverage edges, budget,
## the level-4 gate and its drops, summary items, schema 11, the r2c fixture and
## determinism.
const City = preload("res://scripts/sim/city_state.gd")
const Codec = preload("res://scripts/persistence/save_codec.gd")
const Balance = preload("res://content/balance.gd")
const Economy = preload("res://scripts/sim/economy.gd")
const Summary = preload("res://scripts/presentation/town_summary.gd")
const FIXTURE: String = "res://tests/fixtures/r2c-schema11.json"
const FIXTURE_SHA: String = "ba65a9bf1c608cfb1de211f7099e1f6622df3b73819d66d7938fce00bde1870e"
const R2B_FIXTURE: String = "res://tests/fixtures/r2b-schema10.json"
var t: SceneTree
var density = preload("res://tests/density_tests.gd").new()
var growth = preload("res://tests/growth_tests.gd").new()

func at(city: City, x: int, y: int) -> int:
	return city.index(Vector2i(x, y))

func days(city: City, count: int) -> void:
	growth.days(city, count)

func run(tester: SceneTree) -> void:
	t = tester
	density.t = t
	growth.t = t
	test_placement()
	test_working()
	test_coverage()
	test_budget()
	test_gate()
	test_summary()
	test_saves()
	test_determinism()
	print("PASS group: R2c police and fire stations, coverage, level-4 gate and schema 11")

func test_placement() -> void:
	var c: City = density.street()
	var cash: int = c.cash
	var placed: Dictionary = c.apply_command("police", [Vector2i(10, 3)])
	t.check(placed.ok and c.cash == cash - Balance.POLICE_COST and c.civic_anchors == PackedInt32Array([at(c, 10, 3)]), "a police station costs $400 and is recorded once at its anchor")
	var tiles: int = 0
	for i in range(c.occupancy.size()):
		if c.occupancy[i] == City.POLICE: tiles += 1
	t.check(tiles == 9 and c.footprint_owner[at(c, 12, 5)] == at(c, 10, 3) and City.footprint_size(City.FIRE) == 3, "stations are whole 3x3 footprints")
	t.check(not c.preview("fire", [Vector2i(4, 3), Vector2i(16, 3)]).ok, "stations are placed one at a time")
	var blocked: Dictionary = c.preview("home", [Vector2i(11, 2)])
	t.check(not blocked.ok and String(blocked.message) == "Clear the existing police station first.", "a lot over a station names the station")
	t.check(not c.preview("fire", [Vector2i(10, 5)]).ok and not c.preview("fire", [Vector2i(22, 3)]).ok, "stations need empty land wholly inside the map")
	c.apply_command("fire", [Vector2i(13, 3)])
	t.check(c.lot_anchors.is_empty() and c.civic_anchors.size() == 2 and c.station_anchors.size() == 1, "stations are neither zone lots nor power plants")
	cash = c.cash
	var cleared: Dictionary = c.apply_command("clear", [Vector2i(14, 4)])
	t.check(cleared.ok and c.cash == cash and c.civic_anchors.size() == 1 and c.occupancy[at(c, 13, 3)] == City.EMPTY and c.occupancy[at(c, 15, 5)] == City.EMPTY, "clearing any tile removes the whole station for free")
	var w: City = t.land(16, 8)
	w.terrain[w.index(Vector2i(5, 1))] = City.WATER
	w.rebuild_derived()
	t.check(not w.preview("police", [Vector2i(4, 0)]).ok, "stations cannot be built on water")

func test_working() -> void:
	var c: City = density.street()
	c.apply_command("police", [Vector2i(10, 0)])
	var lone: int = at(c, 10, 0)
	t.check(c.services.working[lone] == 0 and c.services.idle_count == 1, "a station without a road beside it does not work")
	c.apply_command("fire", [Vector2i(4, 8)])
	var plant_side: int = at(c, 4, 8)
	t.check(c.power.home_state[plant_side] == c.power.POWERED and c.access.served_homes[plant_side] == 0 and c.services.working[plant_side] == 0, "power from the plant alone is not enough: it needs road access")
	c.apply_command("police", [Vector2i(16, 3)])
	var good: int = at(c, 16, 3)
	t.check(c.services.working[good] == 1 and c.access.home_reason(c, Vector2i(17, 4)) == "connected" and c.power.home_reason(c, Vector2i(17, 4)) == "powered", "a station beside a connected, powered road works")
	t.check(c.power.total_used == 2, "each powered station draws one unit")
	# Twenty lots fill one plant; a station farther along the street is short of power.
	var s: City = t.land(64, 12)
	s.apply_command("road", t.row(6, 4, 63))
	s.apply_command("power", [Vector2i(0, 5)])
	s.apply_command("home", t.lots_row(3, 4, 20))
	s.apply_command("police", [Vector2i(61, 7)])
	var far: int = at(s, 61, 7)
	t.check(s.power.home_state[far] == s.power.SHORTAGE and s.services.working[far] == 0 and s.services.station_lots[far] == 0, "a station short of power does not work or cover anything")
	s.apply_command("clear", [Vector2i(61, 3)])
	t.check(s.services.working[far] == 1 and s.services.station_lots[far] > 0, "freeing a unit lets it work")

func test_coverage() -> void:
	var c: City = t.land(48, 24)
	c.apply_command("road", t.row(12, 0, 47))
	c.apply_command("power", [Vector2i(0, 13)])
	c.apply_command("police", [Vector2i(20, 9)])
	c.apply_command("fire", [Vector2i(23, 9)])
	for x in range(26, 34):
		for y in range(9, 12): c.terrain[c.index(Vector2i(x, y))] = City.WATER
	c.rebuild_derived()
	c.apply_command("home", [Vector2i(6, 9), Vector2i(34, 9), Vector2i(37, 9), Vector2i(40, 9)])
	var police_edge: int = at(c, 6, 9)
	var both: int = at(c, 34, 9)
	var fire_edge: int = at(c, 37, 9)
	var none: int = at(c, 40, 9)
	t.check(c.footprint_gap(at(c, 20, 9), 3, police_edge, 3) == 12 and c.services.cover_text(police_edge) == "police cover only", "a lot exactly 12 steps from the police station is covered")
	t.check(c.footprint_gap(at(c, 23, 9), 3, fire_edge, 3) == 12 and c.services.cover_text(fire_edge) == "fire cover only" and c.services.cover_text(none) == "no police or fire cover", "fire reaches 12 steps, not 15")
	t.check(c.services.covered(both) and c.services.missing(both) == "" and c.services.missing(none) == "police and fire", "a lot across water within both reaches is covered by both")
	t.check(c.services.police_tile[at(c, 28, 17)] == 1 and c.services.police_tile[at(c, 28, 18)] == 0 and c.services.police_tile[at(c, 29, 17)] == 0, "overlay tiles stop at 12 steps from the footprint")
	var d: City = t.land(48, 24)
	d.apply_command("road", t.row(12, 0, 47))
	d.apply_command("power", [Vector2i(0, 13)])
	d.apply_command("police", [Vector2i(20, 9)])
	d.apply_command("home", [Vector2i(5, 9)])
	t.check(d.footprint_gap(at(d, 20, 9), 3, at(d, 5, 9), 3) == 13 and d.services.lot_police[at(d, 5, 9)] == 0, "a lot 13 steps away is not covered")
	d.apply_command("police", [Vector2i(10, 13)])
	t.check(d.services.lot_police[at(d, 5, 9)] == 1 and d.services.police_count == 2 and d.services.station_lots[at(d, 10, 13)] == 1, "a second station covers it; overlap does not stack")

func test_budget() -> void:
	var c: City = density.street()
	c.apply_command("police", [Vector2i(10, 3)])
	c.apply_command("fire", [Vector2i(10, 0)])
	t.check(c.budget.police == 1 and c.budget.fire == 1, "the forecast counts police and fire stations, working or not")
	var totals: Dictionary = Economy.totals(c.budget)
	var expected: int = 20 * Balance.ROAD_UPKEEP + Balance.STATION_UPKEEP + Balance.POLICE_UPKEEP + Balance.FIRE_UPKEEP
	t.check(totals.expenses == expected and Balance.POLICE_UPKEEP == 3000 and Balance.FIRE_UPKEEP == 3000, "each station adds $30 a month to upkeep")
	var opening: int = c.cash
	days(c, 30)
	t.check(c.last_budget.police == 1 and c.last_budget.fire == 1 and c.cash == opening + Balance.MONTH_GRANT - expected, "the settlement records and charges both stations exactly")
	var old: Dictionary = c.last_budget.duplicate()
	old.erase("police")
	old.erase("fire")
	t.check(Economy.totals(old).expenses == 20 * Balance.ROAD_UPKEEP + Balance.STATION_UPKEEP, "ledgers without station counts charge no station upkeep")

func test_gate() -> void:
	var c: City = density.street(true)
	c.apply_command("home", [Vector2i(16, 3)])
	c.apply_command("park", [Vector2i(17, 1)])
	var home: int = at(c, 16, 3)
	density.develop(c, {home: 4})
	t.check(c.services.covered(home) and c.growth.reason(c, home) == "full", "a covered park lot at level 4 is full")
	var cash: int = c.cash
	c.apply_command("clear", [Vector2i(14, 11)])
	t.check(c.desirability.value_cap(c, home) == 4 and c.desirability.cap(c, home) == 3 and c.growth.dropping[home] == 1 and c.growth.reason(c, home) == "dropping", "removing the fire station marks the level-4 lot to drop to 3")
	days(c, 5)
	t.check(c.development[home] == 3 and c.growth.dropping[home] == 0 and c.growth.reason(c, home) == "uncovered" and c.services.missing(home) == "fire" and c.cash == cash, "it drops one level without demolition and is explained as missing fire")
	days(c, 20)
	t.check(c.development[home] == 3, "it stays at level 3 without cover")
	c.apply_command("fire", [Vector2i(13, 10)])
	t.check(c.desirability.cap(c, home) == 4 and c.growth.reason(c, home) != "uncovered", "rebuilding the fire station lifts the gate again")
	var water: City = density.street(true)
	for x in range(4, 7): water.terrain[water.index(Vector2i(x, 0))] = City.WATER
	water.rebuild_derived()
	water.apply_command("home", [Vector2i(4, 3)])
	t.check(water.desirability.cap(water, at(water, 4, 3)) == 3, "cover never lifts a lot past its land-value gate")
	# Drops for missing cover count towards a type's D32 leaving.
	var l: City = density.street(true)
	l.apply_command("home", t.lots_row(3, 4, 6))
	for x in [5, 11, 17]: l.apply_command("park", [Vector2i(x, 1)])
	var homes: Array[int] = []
	for x in [4, 7, 10, 13, 16, 19]: homes.append(at(l, x, 3))
	density.develop(l, {homes[0]: 4, homes[1]: 1, homes[2]: 4, homes[3]: 1, homes[4]: 4, homes[5]: 1})
	l.apply_command("clear", [Vector2i(11, 11)])
	l.set_tax_rate(25)
	var drops: int = 0
	var leaves: int = 0
	for h in homes:
		drops += l.growth.dropping[h]
		leaves += l.growth.leaving[h]
	t.check(drops == 3 and leaves == mini(l.growth.surplus[City.HOME], Balance.LEAVE_LIMIT) - 3, "service drops count towards residential leaving")

func test_summary() -> void:
	var bare: City = density.park_town(false)
	days(bare, 60)
	var uncovered: Dictionary = {}
	for item in Summary.build(bare):
		if String(item.kind) == "uncovered": uncovered = item
	t.check(int(uncovered.get("count", 0)) == 2 and "need police and fire cover to reach level 4" in String(uncovered.get("text", "")) and String(uncovered.get("action", "")) == "show", "the summary counts lots that need police and fire cover")
	var covered: City = density.park_town(true)
	days(covered, 60)
	var kinds: Array = []
	for item in Summary.build(covered): kinds.append(String(item.kind))
	t.check(not "uncovered" in kinds and not "idle_station" in kinds, "a covered town has no cover item")
	covered.apply_command("police", [Vector2i(0, 0)])
	var idle: Dictionary = {}
	for item in Summary.build(covered):
		if String(item.kind) == "idle_station": idle = item
	t.check(int(idle.get("count", 0)) == 1 and int(idle.get("example", -1)) == 0 and "not working" in String(idle.get("text", "")), "a station without road access or power is a summary status item")

func test_saves() -> void:
	t.check(FileAccess.get_sha256(FIXTURE) == FIXTURE_SHA, "schema-11 fixture hash")
	var text: String = FileAccess.get_file_as_string(FIXTURE).strip_edges()
	var loaded: Dictionary = Codec.decode(text)
	t.check(loaded.ok and loaded.migrated_from == 0 and loaded.city.canonical() == text, "schema-11 fixture exact round trip")
	if loaded.ok:
		var c: City = loaded.city
		t.check(c.civic_anchors.size() == 2 and c.services.covered(at(c, 4, 3)) and c.development[at(c, 4, 3)] == 4 and c.development[at(c, 10, 3)] == 4 and c.last_budget.police == 1 and c.last_budget.fire == 1, "schema-11 fixture holds both stations, covered level-4 lots and station counts")
		var opening: int = c.cash
		c.advance_day()
		t.check(c.tick == 90 and c.cash == opening + 29400 and c.growth.population == 104, "schema-11 fixture settles exactly $294 with 104 residents")
	var data: Dictionary = JSON.parse_string(text)
	data.last_budget.erase("fire")
	t.check(not Codec.decode(JSON.stringify(data)).ok, "a schema-11 ledger needs its station counts")
	var ten: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(R2B_FIXTURE))
	ten.last_budget.police = 0
	t.check(not Codec.decode(JSON.stringify(ten)).ok, "schema-10 ledgers reject station counts")
	ten = JSON.parse_string(FileAccess.get_file_as_string(R2B_FIXTURE))
	ten.occupancy[0] = City.POLICE
	t.check(not Codec.decode(JSON.stringify(ten)).ok, "schema 10 rejects police and fire IDs")
	var bad: Dictionary = JSON.parse_string(text)
	var anchor: int = at(loaded.city, 10, 10)
	bad.development[anchor] = 1
	t.check(not Codec.decode(JSON.stringify(bad)).ok, "stations hold no development")
	bad = JSON.parse_string(text)
	bad.footprint_anchor[anchor] = 0
	t.check(not Codec.decode(JSON.stringify(bad)).ok, "a station must be a whole anchored footprint")
	# The R2b fixture keeps everything; its uncovered level-4 lots drop at the next round.
	var r2b_text: String = FileAccess.get_file_as_string(R2B_FIXTURE).strip_edges()
	var old: Dictionary = Codec.decode(r2b_text)
	t.check(old.ok and old.migrated_from == 10 and old.cleared_tiles == 0 and old.city.canonical() == t.migrated_text(r2b_text) and old.city.last_budget.police == 0 and old.city.last_budget.fire == 0, "schema-10 fixture migrates with every value kept and zero station counts")
	if old.ok:
		var m: City = old.city
		t.check(m.growth.dropping[at(m, 4, 3)] == 1 and m.growth.dropping[at(m, 10, 3)] == 1, "its two uncovered level-4 lots are marked to drop")
		var opening: int = m.cash
		m.advance_day()
		t.check(m.development[at(m, 4, 3)] == 3 and m.development[at(m, 10, 3)] == 3 and m.growth.population == 64 and m.cash == opening + 29400, "they drop to level 3 at the next round, and the month settles $294")

func test_determinism() -> void:
	var a: City = density.park_town(true)
	var b: City = density.park_town(true)
	var state: int = a.rng.state
	days(a, 90)
	days(b, 90)
	t.check(a.canonical() == b.canonical() and a.rng.state == state, "identical covered towns stay identical and consume no randomness")
	var x: City = density.park_town(true)
	days(x, 20)
	var y: City = Codec.decode(x.canonical()).city
	days(x, 70)
	days(y, 70)
	t.check(x.canonical() == y.canonical(), "save/load continuation with stations matches the uninterrupted town")
