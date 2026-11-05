extends RefCounted
const City = preload("res://scripts/sim/city_state.gd")
const Clock = preload("res://scripts/sim/simulation_clock.gd")
const Codec = preload("res://scripts/persistence/save_codec.gd")
const Store = preload("res://scripts/persistence/save_store.gd")
const Balance = preload("res://content/balance.gd")
var t: SceneTree
var growth = preload("res://tests/growth_tests.gd").new()

func days(city: City, count: int) -> void:
	growth.days(city, count)

func command(city: City, kind: String, cells: Array[Vector2i]) -> Dictionary:
	return city.apply_command(kind, cells)

func run(tester: SceneTree) -> void:
	t = tester
	growth.t = t
	var city: City = growth.town()
	var opening: int = city.cash
	var sequence: int = city.sequence
	var random_state: int = city.rng.state
	days(city, 29)
	t.check(city.cash == opening and city.last_budget.is_empty(), "no settlement before tick 30")
	days(city, 1)
	# Tick 25 has 36 residents / 12 jobs; tick 30 growth raises jobs to 18.
	t.check(city.last_budget.residents == 36 and city.last_budget.jobs == 18, "month taxes use completed same-day growth: 36 residents, 18 jobs")
	t.check(city.last_budget.roads == 11 and city.last_budget.stations == 1, "monthly ledger counts roads and stations exactly")
	t.check(city.cash == opening + 17300 and City.Economy.totals(city.last_budget).net == 17300, "$244 income minus $71 upkeep equals $173 net")
	t.check(city.sequence == sequence and city.rng.state == random_state, "accounting changes no commands or RNG")
	days(city, 30)
	t.check(city.cash == opening + 17300 + 19700 and city.last_budget.tick == 60, "second month settles once: $268 income minus $71 upkeep")
	command(city, "clear", [Vector2i(11, 4)])
	t.check(city.growth.population == 48 and city.budget.residents == 0 and city.budget.jobs == 0, "disconnection removes tax immediately during standing-development grace")
	t.check(City.Economy.totals(city.budget).net == 3000, "disconnected station still costs upkeep; cleared road no longer costs")
	command(city, "road", [Vector2i(11, 4)])
	t.check(city.budget.residents == 48 and city.budget.jobs == 18, "reconnection restores taxes immediately")
	# A supplied late home loses power to a newly zoned nearer plot.
	city = t.land(32, 8)
	command(city, "road", t.row(4, 0, 31))
	command(city, "power", [Vector2i(0, 5)])
	command(city, "home", t.row(3, 10, 29))
	city.development[city.index(Vector2i(29, 3))] = 2
	city.rebuild_derived()
	t.check(city.budget.residents == 8, "powered developed home contributes eight taxable residents")
	command(city, "shop", [Vector2i(1, 3)])
	t.check(city.budget.residents == 0 and city.growth.population == 8, "capacity displacement removes tax before decline")
	command(city, "power", [Vector2i(31, 5)])
	t.check(city.budget.residents == 8, "capacity repair restores tax while adding station upkeep")
	test_parks()
	test_recovery()
	test_continuation()
	test_validation()
	var fixture: String = "res://tests/fixtures/m2d-schema4.json"
	t.check(FileAccess.get_sha256(fixture) == "59bdaa0de040c6a6ab8afb8ce48779312e4731a55c28e3a88005d0d415d445be", "schema-4 boundary fixture bytes preserved")
	var text: String = FileAccess.get_file_as_string(fixture).strip_edges()
	var decoded: Dictionary = Codec.decode(text)
	t.check(decoded.ok and decoded.migrated_from == 4 and decoded.city.canonical() == t.migrated_text(text), "schema-4 boundary fixture exact round trip")
	if decoded.ok:
		var saved: City = decoded.city
		var before_cash: int = saved.cash
		t.check(saved.tick == 59 and saved.pending_us == 234567 and saved.last_budget.tick == 30 and saved.occupancy.count(City.PARK) == 1, "fixture records park, prior budget and fractional month boundary")
		days(saved, 1)
		t.check(saved.last_budget.tick == 60 and saved.cash == before_cash + 18700 and saved.pending_us == 234567, "fixture continues to exact next $187 settlement")
	print("PASS group: monthly accounting, park priority, deficit recovery, schema 4")

func test_parks() -> void:
	var plain: City = growth.town()
	var city: City = growth.town()
	var before: String = city.canonical()
	t.check(not command(city, "park", [Vector2i(9, 2), Vector2i(8, 2)]).ok and city.canonical() == before, "multi-park command rejects atomically")
	t.check(not command(city, "park", [Vector2i(11, 4)]).ok and city.canonical() == before, "park cannot occupy outside link")
	var cash: int = city.cash
	t.check(command(city, "park", [Vector2i(7, 2)]).ok and city.cash == cash - 10000, "park costs exactly $100")
	var coverage: PackedByteArray = city.amenity.covered.duplicate()
	t.check(coverage[city.index(Vector2i(5, 3))] == 1 and coverage[city.index(Vector2i(4, 3))] == 0, "Manhattan radius includes distance 3 and excludes distance 4")
	before = city.canonical()
	t.check(command(city, "park", [Vector2i(7, 2)]).ok and city.canonical() == before, "identical park repaint is free and unchanged")
	days(city, 5)
	days(plain, 5)
	t.check(city.development[41] == 1 and city.development[42] == 1 and city.development[38] == 0 and plain.development[38] == 1 and plain.development[41] == 0, "park meaningfully redirects scarce starter growth to covered homes")
	t.check(city.growth.population == 12 and plain.growth.population == 12, "park creates no demand or extra same-round population")
	t.check(city.development[37] == 1, "remaining demand uses first uncovered home in map order")
	t.check(city.power.total_used == 12 and city.power.total_capacity == 20, "park consumes no power and does not add supply")
	command(city, "park", [Vector2i(7, 1)])
	t.check(city.amenity.covered[41] == 1 and city.budget.parks == 2 and City.Economy.totals(city.budget).expenses == 9100, "overlap is boolean but both parks pay upkeep")
	command(city, "clear", [Vector2i(7, 2), Vector2i(7, 1)])
	t.check(city.amenity.covered.count(1) == 0 and city.budget.parks == 0, "free clearing removes coverage and upkeep immediately")
	city = growth.town()
	command(city, "clear", [Vector2i(11, 4)])
	command(city, "park", [Vector2i(7, 2)])
	days(city, 5)
	t.check(city.growth.population == 0, "park priority cannot bypass missing services")
	city = t.land(8, 8)
	command(city, "park", [Vector2i(0, 0)])
	t.check(city.amenity.covered.count(1) == 10, "corner coverage clips deterministically to map")
	city.cash = 9999
	before = city.canonical()
	t.check(not command(city, "park", [Vector2i(4, 0)]).ok and city.canonical() == before, "unaffordable park rejects with no partial spending")

func test_recovery() -> void:
	var city: City = t.land(12, 8)
	for x in range(12): command(city, "power", [Vector2i(x, 0)])
	city.cash = 0
	city.rebuild_derived()
	t.check(City.Economy.totals(city.budget).net == -62000, "costly unused overbuild exposes exact $620 operating deficit")
	days(city, 30)
	var result: Dictionary = City.Economy.totals(city.last_budget)
	t.check(city.cash == 0 and result.waiver == 62000 and result.expenses == 72000, "unpaid shortfall is explicit and waived, never negative cash")
	t.check(city.power.total_capacity == 240 and city.occupancy.count(City.POWER) == 12, "waiver neither disables nor destroys services")
	t.check(not command(city, "road", [Vector2i(11, 4)]).ok, "zero cash still rejects paid construction")
	t.check(command(city, "clear", t.row(0, 0, 11)).ok and city.cash == 0, "zero cash permits free demolition with no refund")
	days(city, 180)
	t.check(city.cash == 60000, "empty cleared town rebuilds $600 in six months with no hidden arrears")
	command(city, "road", t.row(4, 8, 11))
	command(city, "power", [Vector2i(7, 4)])
	command(city, "home", [Vector2i(8, 3)])
	days(city, 30)
	t.check(city.growth.population == 8 and city.cash > 3500, "grant-funded fresh opening grows and remains solvent after deficit recovery")
	city = t.land(8, 8)
	city.cash = Balance.MAX_CASH - 1
	days(city, 30)
	t.check(city.cash == Balance.MAX_CASH and City.Economy.totals(city.last_budget).capped == 9999, "cash cap reports exact discarded surplus without overflow")
	t.check(Balance.money(-101) == "−$1.01", "negative monthly net formats cents correctly")

func test_continuation() -> void:
	var a: City = growth.town()
	command(a, "park", [Vector2i(7, 2)])
	days(a, 29)
	Clock.advance(a, 765432, 1)
	var b: City = Codec.decode(a.canonical()).city
	Clock.advance(a, 40_000_000, 1)
	while a.pending_us >= Clock.STEP_US: Clock.advance(a, 0, 1)
	for frame in range(400): Clock.advance(b, 100000, 1)
	t.check(a.canonical() == b.canonical() and a.last_budget.tick == 60, "fractional reload and frame partition cross two monthly boundaries exactly")
	var before: String = a.canonical()
	a.rebuild_derived()
	t.check(a.canonical() == before, "rebuilding coverage and budget forecast never settles or mutates history")
	var legacy: String = FileAccess.get_file_as_string("res://tests/fixtures/m2c-schema3.json")
	var migrated: City = Codec.decode(legacy).city
	var cash: int = migrated.cash
	days(migrated, 14)
	t.check(migrated.tick == 59 and migrated.cash == cash and migrated.last_budget.is_empty(), "old tick-45 save incurs no retroactive settlement")
	days(migrated, 1)
	t.check(migrated.last_budget.tick == 60 and migrated.cash == cash + 3000, "migrated town settles only at next future month")
	var files = t.FaultFiles.new()
	var store := Store.new(files)
	var base: String = OS.get_environment("CITY_TEST_DIR")
	if base.is_empty(): base = "user://tests"
	var path: String = base.path_join("economy_migration_%d/manual.json" % Time.get_ticks_usec())
	files.write_text(path, legacy)
	files.fault = "preserve_copy"
	t.check(not store.save_city(migrated, path).ok and FileAccess.get_file_as_string(path) == legacy, "schema-3 preservation failure retains primary")
	files.fault = ""
	t.check(store.save_city(migrated, path).ok and FileAccess.get_file_as_string(Store.preserved_path(path, 3)) == legacy and store.load_city(path).schema == City.SCHEMA, "schema-3 original preserved byte-identically before schema-4 replacement")
	var backup_path: String = path + "_recovery.json"
	files.write_text(backup_path, "{broken")
	files.write_text(backup_path + ".bak", legacy)
	store.save_city(migrated, backup_path)
	files.fault = "preserve_copy"
	t.check(not store.save_city(migrated, backup_path).ok and FileAccess.get_file_as_string(backup_path + ".bak") == legacy, "schema-3 backup survives failed preservation after corrupt-primary recovery")
	files.fault = ""
	t.check(store.save_city(migrated, backup_path).ok and FileAccess.get_file_as_string(Store.preserved_path(backup_path, 3)) == legacy, "schema-3 backup preserved before rotation")

func test_validation() -> void:
	var city: City = growth.town()
	days(city, 30)
	t.check(Codec.decode(city.canonical()).ok and Codec.decode(city.canonical()).city.canonical() == city.canonical(), "settlement history round trips exactly")
	for value in [null, [], 4, {"tick": 30}]:
		var bad: Dictionary = city.snapshot()
		bad.last_budget = value
		t.check(not Codec.decode(JSON.stringify(bad)).ok, "reject malformed ledger %s" % str(value))
	for mutation in [["tick", 0], ["tick", 29], ["tick", 60], ["roads", 97], ["parks", -1], ["stations", true], ["jobs", 1], ["residents", 3], ["opening_cash", Balance.MAX_CASH + 1]]:
		var bad: Dictionary = city.snapshot()
		bad.last_budget[mutation[0]] = mutation[1]
		t.check(not Codec.decode(JSON.stringify(bad)).ok, "reject invalid ledger %s" % str(mutation))
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/m2c-schema3.json"))
	legacy.last_budget = {}
	t.check(not Codec.decode(JSON.stringify(legacy)).ok, "schema 3 rejects hidden economy state")
	legacy.erase("last_budget")
	legacy.occupancy[0] = City.PARK
	t.check(not Codec.decode(JSON.stringify(legacy)).ok, "schema 3 rejects park ID")
