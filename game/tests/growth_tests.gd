extends RefCounted
const City = preload("res://scripts/sim/city_state.gd")
const Clock = preload("res://scripts/sim/simulation_clock.gd")
const Codec = preload("res://scripts/persistence/save_codec.gd")
const Store = preload("res://scripts/persistence/save_store.gd")
var t: SceneTree

## Anchor indices in the standard 24x12 lot town.
const HOME_A: int = 3 * 24 + 4
const HOME_B: int = 3 * 24 + 7
const HOME_C: int = 3 * 24 + 10
const HOME_D: int = 3 * 24 + 13
const ROOT := Vector2i(23, 6)

func command(city: City, kind: String, cells: Array[Vector2i]) -> Dictionary:
	return city.apply_command(kind, cells)

func days(city: City, count: int) -> void:
	for day in range(count): Clock.advance(city, 1_000_000, 1)

## Six home lots above and three shop plus three workshop lots below a 20-tile
## street from the outside link, with one 4x4 station at its west end (D30).
func town() -> City:
	var city: City = t.land(24, 12)
	command(city, "road", t.row(6, 4, 23))
	command(city, "power", [Vector2i(0, 5)])
	command(city, "home", t.lots_row(3, 4, 6))
	command(city, "shop", t.lots_row(7, 4, 3))
	command(city, "workshop", t.lots_row(7, 13, 3))
	return city

func run(tester: SceneTree) -> void:
	t = tester
	var city: City = town()
	var before: String = city.canonical()
	var cash: int = city.cash
	var sequence: int = city.sequence
	var rng_state: int = city.rng.state
	t.check(city.lot_anchors.size() == 12 and city.cash == 1_000_000 - 20 * 1000 - 50000 - 12 * 2500, "standard lot town costs its lots, roads and station exactly")
	t.check(city.growth.population == 0 and city.growth.jobs == 0 and city.growth.demand[City.HOME] == 3, "empty town has explicit three-level home bootstrap")
	t.check(city.power.total_used == 12 and city.access.served_homes.count(1) == 12, "all three empty zone types get access and request one power unit per lot")
	t.check(Clock.advance(city, 20_000_000, 0) == 0 and city.canonical() == before, "paused growth leaves all state unchanged")
	days(city, 4)
	t.check(city.development.count(0) == 288, "no growth before fifth tick")
	days(city, 1)
	t.check(city.growth.population == 12 and city.growth.jobs == 0, "first round grows homes only, businesses cannot use same-round residents")
	t.check(city.development[HOME_A] == 1 and city.development[HOME_C] == 1 and city.development[HOME_D] == 0, "bootstrap budget allocated to first three eligible lots in anchor order")
	t.check(city.development.count(1) == 3, "growth state is stored only on lot anchors")
	t.check(city.growth.reason(city, HOME_D) == "demand" and city.growth.reason(city, HOME_D + 24 + 1) == "demand", "unfilled lot explains satisfied demand from any of its tiles")
	days(city, 5)
	t.check(city.growth.population == 12 and city.growth.jobs == 6, "second round grows one shop and one workshop, homes cannot use same-round jobs")
	days(city, 5)
	t.check(city.growth.population == 24 and city.growth.jobs == 6 and city.development[HOME_A] == 2, "jobs support home upgrades, one level per lot per round")
	days(city, 25)
	# D33: the homes across the street from the two developed workshops are held at level 1.
	t.check(city.growth.population == 40 and city.growth.jobs == 18 and city.development.count(2) == 6, "serviced mixed lot town settles at 40 residents / 18 jobs with two homes held beside workshops")
	t.check(city.growth.reason(city, HOME_D) == "held" and city.growth.reason(city, HOME_D + 3) == "held" and city.development[HOME_D] == 1, "homes across from developed workshops are held at level 1")
	t.check(city.growth.demand[City.HOME] == 2 and city.growth.demand[City.SHOP] == 0 and city.growth.demand[City.WORKSHOP] == 0, "equilibrium leaves only the home demand that held lots cannot use")
	var levels: PackedByteArray = city.development.duplicate()
	days(city, 100)
	t.check(city.development == levels and city.cash > cash and city.sequence == sequence and city.rng.state == rng_state, "satisfied demand retains buildings; monthly income changes cash, but not commands or RNG")
	cash = city.cash
	before = city.canonical()
	t.check(command(city, "home", [Vector2i(4, 3)]).ok and city.canonical() == before, "identical lot repaint preserves grown buildings for free")
	t.check(not command(city, "shop", [Vector2i(4, 3), Vector2i(20, 0)]).ok and city.canonical() == before, "mixed conflicting lot stroke rejects atomically")
	command(city, "clear", [Vector2i(5, 4)])
	t.check(city.growth.population == 32 and city.development[HOME_A] == 0 and city.service_loss[HOME_A] == 0 and city.cash == cash, "clear immediately removes residents and counters without refund")
	# Disconnect the district while leaving its power source intact.
	city = town()
	days(city, 40)
	command(city, "clear", [ROOT])
	t.check(city.power.total_used == 12 and city.access.served_homes.count(1) == 0, "disconnected district remains powered but cannot grow")
	days(city, 5)
	t.check(city.growth.population == 40 and city.service_loss[HOME_A] == 1 and city.growth.reason(city, HOME_A) == "declining", "first missing-service round retains residents with a decline explanation")
	var decoded: Dictionary = Codec.decode(city.canonical())
	t.check(decoded.ok and decoded.city.canonical() == city.canonical(), "save preserves pending decline exactly")
	var restored: City = decoded.city
	days(city, 5)
	days(restored, 5)
	t.check(city.growth.population == 16 and city.growth.jobs == 6 and city.service_loss[HOME_A] == 0 and city.canonical() == restored.canonical(), "second missing-service round loses one level simultaneously across reload")
	days(city, 5)
	command(city, "road", [ROOT])
	t.check(city.service_loss.count(1) == 0, "restoration while paused resets every serviced loss counter")
	command(city, "clear", [ROOT])
	days(city, 5)
	t.check(city.growth.population == 16, "brief paused repair breaks consecutive missing-service rounds")
	days(city, 15)
	t.check(city.growth.population == 0 and city.growth.jobs == 0 and city.service_loss.count(1) == 0, "continued disconnection declines to empty without underflow")
	command(city, "road", [ROOT])
	days(city, 40)
	t.check(city.growth.population == 40 and city.growth.jobs == 18, "fully declined town recovers through bootstrap after reconnection")
	# A new nearer lot displaces a grown lot under the retained power rule.
	city = displacement_town()
	var far: int = city.index(Vector2i(65, 1))
	t.check(city.power.home_state[far] == city.power.POWERED and city.power.total_used == 20, "twenty home lots fill one station")
	command(city, "shop", [Vector2i(0, 1)])
	t.check(city.power.home_state[far] == city.power.SHORTAGE and city.development[far] == 2, "nearer empty shop lot can displace grown home lot without immediate eviction")
	days(city, 10)
	t.check(city.development[far] == 1 and city.power.total_used == 20, "power shortage alone declines a connected home lot after grace")
	command(city, "power", [Vector2i(68, 5)])
	days(city, 30)
	t.check(city.power.short_homes == 0 and city.service_loss[far] == 0, "second station restores shortage service and clears decline")
	# Growth skips an unserved early lot, rather than wasting demand on it.
	city = town()
	command(city, "home", [Vector2i(20, 0)])
	days(city, 5)
	t.check(city.development[20] == 0 and city.growth.population == 12, "unserved early lot does not consume starter demand")
	test_caps()
	test_continuation()
	test_migration_validation()
	test_fixture()
	print("PASS group: aggregate lot growth, bootstrap, decline/recovery, continuation")

## Twenty home lots on one station along a 72-tile street from the outside link;
## the far lot is level 2.
func displacement_town() -> City:
	var city: City = t.land(72, 9)
	command(city, "road", t.row(4, 0, 71))
	command(city, "power", [Vector2i(0, 5)])
	command(city, "home", t.lots_row(1, 8, 20))
	city.development[city.index(Vector2i(65, 1))] = 2
	city.rebuild_derived()
	return city

func test_fixture() -> void:
	var path: String = "res://tests/fixtures/m2c-schema3.json"
	t.check(FileAccess.get_sha256(path) == "cbcd607b2f9996da22be16944b792f8617479118b1f4e567ab64604630af9dfc", "M2c fixture bytes preserved")
	var text: String = FileAccess.get_file_as_string(path).strip_edges()
	var decoded: Dictionary = Codec.decode(text)
	t.check(decoded.ok and decoded.migrated_from == 3 and decoded.city.canonical() == t.migrated_text(text), "schema-3 fixture migrates retaining every value except cleared footprints")
	if not decoded.ok: return
	var city: City = decoded.city
	t.check(decoded.cleared_tiles == 13 and city.tick == 45 and city.pending_us == 400000 and city.growth.population == 0 and city.service_loss.count(1) == 0, "schema-3 fixture keeps time but its single-tile zones and station are cleared")
	days(city, 5)
	t.check(city.growth.population == 0 and city.pending_us == 400000, "migrated fixture continues with fractional time and no phantom growth")

func test_caps() -> void:
	# Many eligible lots with large prior-state demand; cap each type independently.
	for target in [City.HOME, City.SHOP]:
		var city: City = t.land(128, 17)
		city.cash = 1_000_000_000_000
		var roads: Array[Vector2i] = []
		for y in [4, 8, 12]: roads.append_array(t.row(y, 0, 127))
		roads.append_array(t.column(127, 4, 12))
		command(city, "road", roads)
		for k in range(7): command(city, "power", [Vector2i(4 * k, 13)])
		var provider: int = City.WORKSHOP if target == City.HOME else City.HOME
		command(city, ["", "", "home", "", "shop"][target], t.lots_row(1, 0, 42))
		command(city, ["", "", "home", "", "", "workshop"][provider], t.lots_row(5, 0, 42))
		command(city, "home" if target == City.HOME else "workshop", t.lots_row(9, 0, 42))
		for anchor in city.lot_anchors:
			if anchor / 128 == 5: city.development[anchor] = 2
		city.rebuild_derived()
		var old: PackedInt32Array = city.growth.levels.duplicate()
		t.check(city.power.short_homes == 0 and city.growth.reason(city, 128 + 24) == "queued", "eligible ninth lot explains round cap for type %d" % target)
		days(city, 5)
		t.check(city.growth.levels[target] - old[target] == 8, "eight-level citywide round cap for type %d" % target)
		if target == City.SHOP:
			t.check(city.growth.levels[City.WORKSHOP] - old[City.WORKSHOP] == 8, "workshop has its own eight-level cap")
	var huge: City = t.land(128, 128)
	huge.cash = 1_000_000_000_000
	var road_cells: Array[Vector2i] = t.column(127, 0, 127)
	for m in range(26): road_cells.append_array(t.row(5 * m, 0, 126))
	command(huge, "road", road_cells)
	for m in range(25):
		command(huge, "power", [Vector2i(0, 5 * m + 1)])
		for kind in ["home", "shop", "workshop"]:
			var anchors: Array[Vector2i] = []
			for k in range(41):
				if ["home", "shop", "workshop"][k % 3] == kind: anchors.append(Vector2i(4 + 3 * k, 5 * m + 1))
			command(huge, kind, anchors)
	var start: int = Time.get_ticks_usec()
	days(huge, 250)
	var elapsed: int = Time.get_ticks_usec() - start
	t.check(huge.lot_anchors.size() == 1025 and huge.tick == 250 and huge.development.count(0) + huge.development.count(1) + huge.development.count(2) == 16384, "128x128 lot city ticks bounded, valid levels after 50 rounds")
	t.check(huge.canonical().to_utf8_buffer().size() < Codec.MAX_BYTES and Codec.decode(huge.canonical()).ok, "maximum map with growth stays within bounded save size and validates")
	print("INFO growth 128x128 lots, 250 days / 50 rounds: ", elapsed, " us (headless; not a performance target)")

func test_continuation() -> void:
	var a: City = town()
	days(a, 9)
	Clock.advance(a, 345_678, 1)
	var b: City = Codec.decode(a.canonical()).city
	var before: String = a.canonical()
	a.rebuild_derived()
	t.check(a.canonical() == before, "growth planning is derived and leaves authoritative values untouched")
	for iteration in range(30):
		if iteration == 5 or iteration == 17:
			for city in [a, b]: command(city, "clear", [ROOT])
		if iteration == 9 or iteration == 22:
			for city in [a, b]: command(city, "road", [ROOT])
		Clock.advance(a, 2_000_000, 3)
		for frame in range(20): Clock.advance(b, 100_000, 3)
	t.check(a.canonical() == b.canonical() and a.growth.demand == b.growth.demand, "frame partition and save/reload preserve growth and decline across repeated network edits")
	a = town()
	b = town()
	Clock.advance(a, 40_000_000, 1)
	while a.pending_us >= Clock.STEP_US: Clock.advance(a, 0, 1)
	days(b, 40)
	t.check(a.canonical() == b.canonical(), "backlog executes all intervening growth rounds in order")
	a.tick = City.MAX_TICK - 1
	Clock.advance(a, 8_000_000, 3)
	before = a.canonical()
	t.check(a.tick == City.MAX_TICK and Clock.advance(a, 5_000_000, 3) == 0 and a.canonical() == before, "terminal clock limit cannot overrun growth")

func test_migration_validation() -> void:
	var city: City = town()
	days(city, 15)
	for field in ["development", "service_loss"]:
		for value in [null, [], {}, [0]]:
			var bad: Dictionary = city.snapshot()
			bad[field] = value
			t.check(not Codec.decode(JSON.stringify(bad)).ok, "reject malformed growth array %s %s" % [field, value])
	var station_tile: int = city.index(Vector2i(0, 5))
	for mutation in [["development", HOME_A, 3], ["development", HOME_A, -1], ["development", HOME_A, 0.5], ["development", HOME_A, true], ["development", station_tile, 1], ["development", HOME_A + 1, 1], ["service_loss", HOME_A, 2], ["service_loss", HOME_A, 1], ["service_loss", 0, 1]]:
		var bad: Dictionary = city.snapshot()
		bad[mutation[0]][mutation[1]] = mutation[2]
		t.check(not Codec.decode(JSON.stringify(bad)).ok, "reject inconsistent growth %s" % str(mutation))
	# Every legacy format rejects new zone IDs even with its own version strings.
	for schema in [1, 2]:
		var bad: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/m2a-schema1.json" if schema == 1 else "res://tests/fixtures/m2b-schema2.json"))
		bad.occupancy[bad.terrain.find(0)] = City.SHOP
		t.check(not Codec.decode(JSON.stringify(bad)).ok, "old format %d rejects shop ID" % schema)
	var legacy: String = FileAccess.get_file_as_string("res://tests/fixtures/m2b-schema2.json")
	var files = t.FaultFiles.new()
	var store := Store.new(files)
	var base: String = OS.get_environment("CITY_TEST_DIR")
	if base.is_empty(): base = "user://tests"
	var path: String = base.path_join("growth_migration_%d/manual.json" % Time.get_ticks_usec())
	files.write_text(path, legacy)
	var loaded: Dictionary = store.load_city(path)
	t.check(loaded.ok and loaded.migrated_from == 2 and loaded.city.development.count(0) == 80 and FileAccess.get_file_as_string(path) == legacy, "schema-2 load has zero growth, retains source bytes")
	files.fault = "preserve_copy"
	t.check(not store.save_city(loaded.city, path).ok and FileAccess.get_file_as_string(path) == legacy, "schema-2 preservation failure prevents replacing primary")
	files.fault = ""
	t.check(store.save_city(loaded.city, path).ok and FileAccess.get_file_as_string(Store.preserved_path(path, 2)) == legacy and store.load_city(path).schema == City.SCHEMA, "schema-2 primary preserved byte-for-byte before a current-schema save")
	var recovery: String = base.path_join("growth_recovery_%d/manual.json" % Time.get_ticks_usec())
	files.write_text(recovery, "{broken")
	files.write_text(recovery + ".bak", legacy)
	store.save_city(loaded.city, recovery)
	files.fault = "preserve_copy"
	t.check(not store.save_city(loaded.city, recovery).ok and FileAccess.get_file_as_string(recovery + ".bak") == legacy, "schema-2 backup preservation failure prevents rotation")
	files.fault = ""
	t.check(store.save_city(loaded.city, recovery).ok and FileAccess.get_file_as_string(Store.preserved_path(recovery, 2)) == legacy, "schema-2 backup preserved after corrupt-primary recovery")
