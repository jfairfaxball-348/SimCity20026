extends RefCounted
## D32 / M2f: tax rate, appeal, leaving, command, saves and the schema-7 fixture.
const City = preload("res://scripts/sim/city_state.gd")
const Clock = preload("res://scripts/sim/simulation_clock.gd")
const Codec = preload("res://scripts/persistence/save_codec.gd")
const Store = preload("res://scripts/persistence/save_store.gd")
const Balance = preload("res://content/balance.gd")
const FIXTURE: String = "res://tests/fixtures/m2f-schema7.json"
const FIXTURE_SHA: String = "59f46e3f0b01d0f2b8b9e149b21cae97fce860b8849d5e9f48207e24639b339c"
var t: SceneTree
var growth = preload("res://tests/growth_tests.gd").new()

func days(city: City, count: int) -> void:
	growth.days(city, count)

## The standard 24x12 lot town grown to its equilibrium: 40 residents / 18 jobs, with
## two homes held beside developed workshops (D33).
func grown() -> City:
	var city: City = growth.town()
	days(city, 40)
	return city

## Eleven home lots, three shop and three workshop lots on one 36-tile street:
## more home land than the standard rate can fill.
func roomy() -> City:
	var city: City = t.land(40, 12)
	city.apply_command("road", t.row(6, 4, 39))
	city.apply_command("power", [Vector2i(0, 5)])
	city.apply_command("home", t.lots_row(3, 4, 11))
	city.apply_command("shop", t.lots_row(7, 4, 3))
	city.apply_command("workshop", t.lots_row(7, 13, 3))
	return city

func home_levels(city: City) -> int:
	return city.growth.levels[City.HOME]

func run(tester: SceneTree) -> void:
	t = tester
	growth.t = t
	test_rates()
	test_command()
	test_appeal()
	test_leaving()
	test_saves()
	test_fixture()
	print("PASS group: M2f tax rate, appeal, leaving, command and schema 7")

func test_rates() -> void:
	var exact: bool = true
	for value in range(0, 2000): exact = exact and Balance.appealed(value, Balance.TAX_STANDARD) == value
	t.check(exact, "standard-rate appeal leaves every D22 target unchanged")
	t.check(Balance.appeal(0) == 140 and Balance.appeal(10) == 100 and Balance.appeal(25) == 40, "appeal spans 140% at 0% to 40% at 25%")
	var data: Dictionary = {"tick": 30, "opening_cash": 0, "residents": 48, "jobs": 18, "roads": 20, "stations": 1, "parks": 0, "tax_rate": 10}
	t.check(City.Economy.totals(data).income == 10000 + 48 * 200 + 18 * 400, "10% taxes equal D25 exactly: $2 per resident, $4 per job")
	data.tax_rate = 0
	t.check(City.Economy.totals(data).income == 10000, "0% collects only the grant")
	data.tax_rate = 25
	t.check(City.Economy.totals(data).income == 10000 + 48 * 500 + 18 * 1000 and City.Economy.totals(data).expenses == 8000, "25% collects $5 and $10; upkeep unchanged")
	var city: City = grown()
	t.check(city.growth.population == 40 and city.growth.jobs == 18 and city.tax_rate == 10, "standard town settles at 40 residents / 18 jobs at 10%")
	var opening: int = city.cash
	days(city, 20) # tick 60: the next settlement
	t.check(city.last_budget.tax_rate == 10 and city.cash > opening, "settlement ledger records its standard rate")
	city.set_tax_rate(20)
	var forecast: Dictionary = City.Economy.totals(city.budget)
	t.check(city.budget.tax_rate == 20 and forecast.income == 10000 + city.budget.residents * 400 + city.budget.jobs * 800, "forecast uses the current rate immediately")
	days(city, 30)
	t.check(city.last_budget.tax_rate == 20 and city.last_budget.tick == 90, "settlement records the rate in force")
	t.check(city.cash == City.Economy.totals(city.last_budget).closing_cash, "recomputed last settlement matches cash at the recorded rate")

func test_command() -> void:
	var city: City = growth.town()
	var sequence: int = city.sequence
	var cash: int = city.cash
	var rng_state: int = city.rng.state
	var same: Dictionary = city.set_tax_rate(10)
	t.check(same.ok and not same.has("record") and city.sequence == sequence, "setting the current rate is a free no-op without a sequence step")
	for bad in [-1, 26, 12.0, "12", null, true]:
		var result: Dictionary = city.set_tax_rate(bad)
		t.check(not result.ok and city.tax_rate == 10 and city.sequence == sequence, "invalid tax rate rejected: %s" % str(bad))
	var changed: Dictionary = city.set_tax_rate(12)
	t.check(changed.ok and city.tax_rate == 12 and city.sequence == sequence + 1 and city.cash == cash and city.rng.state == rng_state, "rate change is ordered, free and consumes no RNG")
	t.check(changed.record == {"tick": city.tick, "sequence": sequence + 1, "kind": "tax_rate", "indices": [], "cost": 0, "rate": 12}, "rate change produces an auditable command record")
	var paused: City = growth.town()
	var demand: int = paused.growth.demand[City.HOME]
	paused.set_tax_rate(0)
	t.check(paused.growth.demand[City.HOME] > demand and paused.tick == 0, "demand refreshes immediately while paused")
	paused.sequence = City.MAX_TICK
	t.check(not paused.set_tax_rate(5).ok and paused.tax_rate == 0, "rate change refused at the command limit")
	# Replay and continuation: identical command streams give identical towns.
	var a: City = growth.town()
	var b: City = growth.town()
	for c: City in [a, b]:
		days(c, 12)
		c.set_tax_rate(4)
		days(c, 23)
	t.check(a.canonical() == b.canonical(), "identical tax command streams replay identically")
	var restored: City = Codec.decode(a.canonical()).city
	for c: City in [a, restored]:
		c.set_tax_rate(18)
		days(c, 31)
	t.check(a.canonical() == restored.canonical(), "save/load continuation with rate changes matches the uninterrupted town")

func test_appeal() -> void:
	var empty: City = growth.town()
	empty.set_tax_rate(25)
	t.check(empty.growth.demand[City.HOME] == 1, "empty town at 25% still has starter home demand")
	empty.set_tax_rate(0)
	t.check(empty.growth.demand[City.HOME] == 4, "empty town at 0% welcomes four starter home levels")
	var city: City = grown()
	t.check(city.growth.demand[City.HOME] == 2 and city.growth.demand[City.SHOP] == 0, "standard equilibrium has only the held homes' unusable demand")
	city.set_tax_rate(0)
	t.check(city.growth.demand[City.HOME] == 7 and city.growth.demand[City.SHOP] == 1 and city.growth.demand[City.WORKSHOP] == 1, "0% raises the targets: 7 home, 1 shop and 1 workshop levels")
	var low: City = roomy()
	low.set_tax_rate(6)
	var standard: City = roomy()
	days(low, 120)
	days(standard, 120)
	t.check(low.growth.population > standard.growth.population and standard.growth.population >= 40, "a lower rate grows a larger town on the same land")
	var surplus_free: bool = true
	for rate in range(0, Balance.TAX_STANDARD + 1):
		city.set_tax_rate(rate)
		surplus_free = surplus_free and city.growth.surplus == PackedInt32Array([0, 0, 0, 0, 0, 0]) and city.growth.leaving.count(1) == 0
	t.check(surplus_free, "at or below 10% nothing is marked to leave")

func test_leaving() -> void:
	var city: City = grown()
	var anchors: Array[int] = []
	for x in [4, 7, 10, 13, 16, 19]: anchors.append(3 * 24 + x)
	var occupancy: PackedByteArray = city.occupancy.duplicate()
	var cash: int = city.cash
	city.set_tax_rate(25)
	t.check(city.growth.surplus[City.HOME] == 5 and city.growth.surplus[City.SHOP] == 2 and city.growth.surplus[City.WORKSHOP] == 2, "25% surplus: 5 home, 2 shop and 2 workshop levels above target")
	var marked: Array[int] = []
	for a in anchors:
		if city.growth.leaving[a] != 0: marked.append(a)
	t.check(marked == [anchors[0], anchors[1], anchors[2], anchors[5]], "the four level-2 home lots leave first, later map order first")
	t.check(city.growth.reason(city, anchors[5]) == "leaving" and city.growth.reason(city, anchors[3]) == "surplus", "inspector reasons distinguish leaving and surplus lots")
	while city.tick % Balance.GROWTH_DAYS != Balance.GROWTH_DAYS - 1: days(city, 1)
	var levels_before: int = home_levels(city)
	days(city, 1)
	var all_one: bool = true
	for a in anchors: all_one = all_one and city.development[a] == 1
	t.check(home_levels(city) == levels_before - 4 and all_one, "a round removes at most four home levels, one per lot")
	t.check(city.growth.leaving[anchors[5]] != 0 and city.growth.leaving[anchors[4]] != 0 and city.growth.leaving[anchors[3]] != 0 and city.growth.leaving[anchors[2]] != 0 and city.growth.leaving[anchors[0]] == 0, "with every home at level 1, later map order leaves first")
	days(city, 60)
	var settled: bool = true
	for kind in [City.HOME, City.SHOP, City.WORKSHOP]: settled = settled and city.growth.surplus[kind] == 0
	t.check(settled and city.growth.population < 40, "leaving stops at the 25% targets")
	t.check(city.occupancy == occupancy and city.lot_anchors.size() == 12, "leaving never removes a zone")
	t.check(city.cash != cash, "settlements continue while the town shrinks")
	city.set_tax_rate(10)
	days(city, 80)
	t.check(city.growth.population >= 40 and city.growth.jobs == 18, "lowering the rate lets the town recover to its standard size")
	# Unserviced lots are left to service-loss decline, never chosen to leave.
	var cut: City = grown()
	cut.apply_command("clear", [growth.ROOT])
	cut.set_tax_rate(25)
	t.check(cut.growth.surplus[City.HOME] > 0 and cut.growth.leaving.count(1) == 0, "unserviced lots are not chosen to leave")
	var types_exclusive: bool = true
	for rate in range(Balance.TAX_STANDARD + 1, Balance.TAX_MAX + 1):
		city.set_tax_rate(rate)
		for kind in [City.HOME, City.SHOP, City.WORKSHOP]:
			types_exclusive = types_exclusive and not (city.growth.demand[kind] > 0 and city.growth.surplus[kind] > 0)
	t.check(types_exclusive, "a type never has demand and surplus together")

func test_saves() -> void:
	var city: City = grown()
	city.set_tax_rate(15)
	days(city, 30)
	var text: String = city.canonical()
	var decoded: Dictionary = Codec.decode(text)
	t.check(decoded.ok and decoded.migrated_from == 0 and decoded.city.canonical() == text and decoded.city.tax_rate == 15 and decoded.city.last_budget.tax_rate == 15, "schema-7 town with rate and ledger round-trips exactly")
	var data: Dictionary = JSON.parse_string(text)
	for bad in [-1, 26, 1.5, "15", null, true]:
		var copy: Dictionary = data.duplicate(true)
		copy.tax_rate = bad
		t.check(not Codec.decode(JSON.stringify(copy)).ok, "schema 7 rejects tax rate %s" % str(bad))
		copy = data.duplicate(true)
		copy.last_budget.tax_rate = bad
		t.check(not Codec.decode(JSON.stringify(copy)).ok, "schema 7 rejects ledger tax rate %s" % str(bad))
	var missing: Dictionary = data.duplicate(true)
	missing.erase("tax_rate")
	t.check(not Codec.decode(JSON.stringify(missing)).ok, "schema 7 requires a tax rate")
	missing = data.duplicate(true)
	missing.last_budget.erase("tax_rate")
	t.check(not Codec.decode(JSON.stringify(missing)).ok, "schema-7 ledger requires its tax rate")
	var empty_ledger: City = growth.town()
	empty_ledger.set_tax_rate(3)
	var empty_text: String = empty_ledger.canonical()
	t.check(Codec.decode(empty_text).ok and Codec.decode(empty_text).city.last_budget.is_empty(), "schema-7 empty ledger stays empty")
	for fixture in ["m1-schema1", "m2a-schema1", "m2b-schema2", "m2c-schema3", "m2d-schema4", "m3a-schema5", "m2e-schema6"]:
		var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/%s.json" % fixture))
		var loaded: Dictionary = Codec.decode(JSON.stringify(legacy))
		t.check(loaded.ok and loaded.city.tax_rate == 10 and (loaded.city.last_budget.is_empty() or loaded.city.last_budget.tax_rate == 10), "earlier format starts at the standard rate: " + fixture)
		legacy.tax_rate = 10
		t.check(not Codec.decode(JSON.stringify(legacy)).ok, "earlier format rejects hidden tax rate: " + fixture)
		legacy.erase("tax_rate")
		if typeof(legacy.get("last_budget")) == TYPE_DICTIONARY and not legacy.last_budget.is_empty():
			legacy.last_budget.tax_rate = 10
			t.check(not Codec.decode(JSON.stringify(legacy)).ok, "earlier ledger rejects hidden tax rate: " + fixture)
	# A migrated schema-6 town at the standard rate evolves exactly like 0.7.x.
	var six: City = Codec.decode(FileAccess.get_file_as_string("res://tests/fixtures/m2e-schema6.json")).city
	var opening: int = six.cash
	days(six, 1)
	t.check(six.cash == opening + 4400 and six.last_budget.tax_rate == 10, "migrated schema-6 town settles the same $44 at 10%")

func test_fixture() -> void:
	t.check(FileAccess.get_sha256(FIXTURE) == FIXTURE_SHA, "schema-7 fixture hash")
	var text: String = FileAccess.get_file_as_string(FIXTURE).strip_edges()
	var loaded: Dictionary = Codec.decode(text)
	t.check(loaded.ok and loaded.migrated_from == 7 and loaded.cleared_tiles == 0 and loaded.city.canonical() == t.migrated_text(text), "schema-7 fixture migrates with every value kept")
	if not loaded.ok: return
	var city: City = loaded.city
	t.check(city.tax_rate == 14 and city.last_budget.tax_rate == 14 and city.tick == 59 and city.growth.population == 32 and city.growth.jobs == 12, "schema-7 fixture holds a 14% town of 32 residents / 12 jobs with a 14% ledger")
	var opening: int = city.cash
	city.advance_day()
	t.check(city.tick == 60 and city.cash == opening + 17680 and city.pending_us == 234567 and city.last_budget.tax_rate == 14, "schema-7 fixture settles exactly $176.80 at 14%")
