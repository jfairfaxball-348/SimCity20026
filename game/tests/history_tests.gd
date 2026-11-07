extends RefCounted
## D39 / R3: monthly history, schema 12, autosave rotation and the manual-slot
## guarantee, and remembered settings with safe fallbacks.
const City = preload("res://scripts/sim/city_state.gd")
const Codec = preload("res://scripts/persistence/save_codec.gd")
const Store = preload("res://scripts/persistence/save_store.gd")
const FileOps = preload("res://scripts/persistence/file_ops.gd")
const Settings = preload("res://scripts/persistence/settings_store.gd")
const Balance = preload("res://content/balance.gd")
const Economy = preload("res://scripts/sim/economy.gd")
const FIXTURE: String = "res://tests/fixtures/r3-schema12.json"
const FIXTURE_SHA: String = "19fb4b21f865f1bb8fb5fe806ed9417345db66edcd8580b95be34a7a5dde7a1e"
var t: SceneTree
var density = preload("res://tests/density_tests.gd").new()
var growth = preload("res://tests/growth_tests.gd").new()

class BrokenWrites extends FileOps:
	var fail_suffix: String = ""
	func write_text(path: String, text: String) -> Error:
		if not fail_suffix.is_empty() and path.ends_with(fail_suffix): return ERR_CANT_CREATE
		return super.write_text(path, text)

func days(city: City, count: int) -> void:
	growth.days(city, count)

func base_dir(label: String) -> String:
	var base: String = OS.get_environment("CITY_TEST_DIR")
	if base.is_empty(): base = "user://tests"
	return base.path_join("%s_%d" % [label, Time.get_ticks_usec()])

func run(tester: SceneTree) -> void:
	t = tester
	density.t = t
	growth.t = t
	test_history()
	test_history_saves()
	test_autosaves()
	test_settings()
	print("PASS group: R3 history, schema 12, autosaves and settings")

func test_history() -> void:
	var c: City = density.park_town(true)
	var state: int = c.rng.state
	days(c, 29)
	t.check(c.history.is_empty(), "no history before the first settlement")
	days(c, 1)
	var shop_jobs: int = 0
	var workshop_jobs: int = 0
	for a in c.lot_anchors:
		if c.occupancy[a] == City.SHOP: shop_jobs += Balance.capacity(City.SHOP, c.development[a])
		elif c.occupancy[a] == City.WORKSHOP: workshop_jobs += Balance.capacity(City.WORKSHOP, c.development[a])
	t.check(c.history == [[30, c.growth.population, shop_jobs, workshop_jobs, c.cash, Economy.totals(c.last_budget).net]], "each settlement appends tick, residents, commercial and industrial jobs, cash and net")
	days(c, 60)
	t.check(c.history.size() == 3 and int(c.history[2][0]) == 90 and c.rng.state == state, "one record per month; history consumes no randomness")
	var small: City = t.land(8, 8)
	for month in range(Balance.HISTORY_LIMIT + 5):
		for d in range(Balance.MONTH_DAYS): small.advance_day()
	t.check(small.history.size() == Balance.HISTORY_LIMIT and int(small.history[0][0]) == 6 * Balance.MONTH_DAYS and int(small.history[-1][0]) == small.tick, "history keeps the latest 240 months")
	var x: City = density.park_town(true)
	days(x, 45)
	var y: City = Codec.decode(x.canonical()).city
	days(x, 90)
	days(y, 90)
	t.check(x.canonical() == y.canonical() and x.history.size() == 4, "history survives save/load and continues identically")

func test_history_saves() -> void:
	t.check(FileAccess.get_sha256(FIXTURE) == FIXTURE_SHA, "schema-12 fixture hash")
	var text: String = FileAccess.get_file_as_string(FIXTURE).strip_edges()
	var loaded: Dictionary = Codec.decode(text)
	t.check(loaded.ok and loaded.migrated_from == 0 and loaded.city.canonical() == text, "schema-12 fixture exact round trip")
	if loaded.ok:
		var c: City = loaded.city
		t.check(c.history == [[30, 60, 8, 16, 782600, 12600], [60, 104, 12, 32, 812000, 29400]], "schema-12 fixture holds two months of history")
		var opening: int = c.cash
		c.advance_day()
		t.check(c.tick == 90 and c.cash == opening + 29400 and c.history.size() == 3 and c.history[2] == [90, 104, 12, 32, c.cash, 29400], "its next settlement adds the third month exactly")
	var cases: Array = [
		["history", "not a list"], ["unordered", [[60, 0, 0, 0, 0, 0], [30, 0, 0, 0, 0, 0]]],
		["off-month", [[31, 0, 0, 0, 0, 0]]], ["future", [[120, 0, 0, 0, 0, 0]]],
		["short record", [[30, 0, 0, 0, 0]]], ["negative cash", [[30, 0, 0, 0, -1, 0]]],
		["fractional", [[30, 0.5, 0, 0, 0, 0]]]]
	for entry in cases:
		var data: Dictionary = JSON.parse_string(text)
		data.history = entry[1]
		t.check(not Codec.decode(JSON.stringify(data)).ok, "schema 12 rejects %s history" % entry[0])
	var many: Dictionary = JSON.parse_string(text)
	many.tick = 30 * 300
	many.history = []
	for m in range(Balance.HISTORY_LIMIT + 1): many.history.append([30 * (m + 1), 0, 0, 0, 0, 0])
	t.check(not Codec.decode(JSON.stringify(many)).ok, "schema 12 rejects more than 240 records")
	many.history.pop_back()
	t.check(Codec.decode(JSON.stringify(many)).ok, "and accepts exactly 240")
	var eleven: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/r2c-schema11.json"))
	eleven.history = []
	t.check(not Codec.decode(JSON.stringify(eleven)).ok, "schema 11 rejects a history field")
	# The largest map with a full history and big numbers stays under the save cap.
	var big: City = City.new()
	big.initialize(7, 128, 128)
	big.tick = 30 * Balance.HISTORY_LIMIT
	for m in range(Balance.HISTORY_LIMIT): big.history.append([30 * (m + 1), 655360, 327680, 458752, Balance.MAX_CASH, -Balance.MAX_CASH])
	var big_text: String = big.canonical()
	t.check(big_text.to_utf8_buffer().size() < Codec.MAX_BYTES and Codec.decode(big_text).ok, "a 128x128 town with a full history fits under 512 KiB (%d bytes)" % big_text.to_utf8_buffer().size())

func test_autosaves() -> void:
	var dir: String = base_dir("autosave")
	var manual: String = dir.path_join("manual.json")
	var store := Store.new()
	var c: City = density.park_town(true)
	t.check(store.save_city(c, manual).ok, "a manual save exists first")
	var manual_bytes: String = FileAccess.get_file_as_string(manual)
	var slots: Array[int] = []
	for n in range(4):
		days(c, 60)
		var result: Dictionary = store.save_autosave(c, manual)
		slots.append(int(result.get("slot", 0)))
	t.check(slots == [1, 2, 3, 1], "autosaves rotate through slots 1, 2, 3, 1")
	t.check(FileAccess.get_file_as_string(manual) == manual_bytes and not FileAccess.file_exists(manual + ".bak") and not FileAccess.file_exists(Store.preserved_path(manual, 11)), "autosaves never touch the manual save, its backup or preserved copies")
	var newest: Dictionary = store.load_autosave(manual)
	t.check(newest.ok and int(newest.slot) == 1 and newest.city.canonical() == c.canonical(), "Load autosave picks the index slot, the newest")
	FileOps.new().write_text(Store.autosave_path(manual, 1), "{")
	var fallback: Dictionary = store.load_autosave(manual)
	t.check(fallback.ok and int(fallback.slot) == 3 and fallback.city.tick == c.tick - 60, "a corrupt newest slot falls back to the next older one")
	FileOps.new().write_text(Store.autosave_index_path(manual), "9")
	t.check(store.last_autosave_slot(manual) == 0 and store.next_autosave_slot(manual) == 1, "an invalid index is ignored")
	var by_date: Dictionary = store.load_autosave(manual)
	t.check(by_date.ok and int(by_date.slot) == 3, "without a valid index the latest-dated valid slot loads")
	var empty_dir: String = base_dir("autosave_none").path_join("manual.json")
	t.check(not store.load_autosave(empty_dir).ok and store.next_autosave_slot(empty_dir) == 1, "with no autosaves, Load autosave reports none and slot 1 is next")
	var faulty := BrokenWrites.new()
	faulty.fail_suffix = ".json.tmp"
	var broken := Store.new(faulty)
	var failed: Dictionary = broken.save_autosave(c, manual)
	t.check(not failed.ok and "manual save is unchanged" in String(failed.message) and FileAccess.get_file_as_string(manual) == manual_bytes, "a failed autosave reports it and leaves the manual save alone")

func test_settings() -> void:
	var previous: String = Settings.override_path
	Settings.override_path = base_dir("settings").path_join("settings.json")
	var store := Settings.new()
	var first: Dictionary = store.load_settings()
	t.check(not first.ok and first.settings == Settings.defaults(), "a missing settings file gives the defaults")
	var values: Dictionary = Settings.defaults()
	values.window = [1366, 768]
	values.text_size = 20
	values.art = "original"
	values.services = true
	values.guide_hidden = true
	t.check(store.save_settings(values).ok, "settings save")
	var back: Dictionary = store.load_settings()
	t.check(back.ok and back.settings == values, "settings round-trip exactly")
	var good: String = FileAccess.get_file_as_string(Settings.path())
	var bad_cases: Dictionary = {"malformed": "{", "list": "[]", "wrong version": good.replace("\"settings_version\":2", "\"settings_version\":3"),
		"odd window": good.replace("[1366,768]", "[1000,700]"), "text size": good.replace("\"text_size\":20", "\"text_size\":17"),
		"art": good.replace("\"original\"", "\"pastel\""), "flag type": good.replace("\"services\":true", "\"services\":1"),
		"extra key": good.replace("{", "{\"volume\":3,"), "missing key": good.replace("\"grid\":true,", ""),
		"oversized": good + " ".repeat(Settings.MAX_BYTES)}
	for label in bad_cases:
		FileOps.new().write_text(Settings.path(), bad_cases[label])
		var loaded: Dictionary = store.load_settings()
		t.check(not loaded.ok and loaded.settings == Settings.defaults(), "%s settings fall back to the defaults" % label)
	var invalid: Dictionary = Settings.defaults()
	invalid.text_size = 99
	t.check(not store.save_settings(invalid).ok, "invalid settings are never written")
	Settings.override_path = previous
