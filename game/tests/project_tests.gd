extends RefCounted
const City = preload("res://scripts/sim/city_state.gd")
const Codec = preload("res://scripts/persistence/save_codec.gd")
const Store = preload("res://scripts/persistence/save_store.gd")
const Clock = preload("res://scripts/sim/simulation_clock.gd")
var t: SceneTree
var growth = preload("res://tests/growth_tests.gd").new()
## The M2e specification's feasibility layout: three home lots around one park.
const PARK := Vector2i(10, 10)
const LOT_A := Vector2i(6, 8)
const LOT_B := Vector2i(11, 8)
const LOT_C := Vector2i(9, 12)
const ROOT := Vector2i(15, 11)
const STATION := Vector2i(12, 12)
const M2E_FIXTURE_SHA: String = "c6bbc25000b43e4084be8e318f48fab74ca0418982fab17868210f25cd8b41f4"

func town() -> City:
	var c: City = t.land(16, 22)
	c.apply_command("road", t.row(11, 6, 15))
	c.apply_command("power", [STATION])
	c.apply_command("home", [LOT_A, LOT_B, LOT_C])
	c.apply_command("park", [PARK])
	return c

func days(c: City, count: int) -> void:
	for _day in range(count): c.advance_day()

func same_sim(a: City, b: City) -> bool:
	var aa: Dictionary = a.snapshot()
	var bb: Dictionary = b.snapshot()
	for key in ["project", "sequence"]:
		aa.erase(key)
		bb.erase(key)
	return aa == bb and a.power.home_state == b.power.home_state and a.access.served_homes == b.access.served_homes and a.budget == b.budget

func run(tester: SceneTree) -> void:
	t = tester
	growth.t = t
	var c: City = town()
	var i: int = c.index(PARK)
	var before: String = c.canonical()
	t.check(c.cash == 922500 and c.lot_anchors.size() == 3, "the specified three-lot square layout is buildable")
	for lot in [LOT_A, LOT_B, LOT_C]:
		t.check(c.distance_to_footprint(PARK, c.index(lot)) <= 3 and c.access.home_reason(c, lot) == "connected", "lot %s touches the street and lies within three side-steps of the park" % lot)
	t.check(c.project_homes(i) == 0 and not c.complete_project(PARK).ok and c.canonical() == before, "empty home lots do not qualify; failure atomic")
	days(c, 5)
	t.check(c.project_homes(i) == 3 and not c.project.completed, "three level-one home lots qualify without automatic completion")
	c.apply_command("clear", [ROOT])
	before = c.canonical()
	t.check(c.project_homes(i) == 0 and not c.complete_project(PARK).ok and c.canonical() == before, "road loss invalidates stale completion immediately during decline grace")
	c.apply_command("road", [ROOT])
	t.check(c.project_homes(i) == 3, "road restoration immediately restores eligibility")
	c.apply_command("clear", [Vector2i(14, 14)])
	t.check(c.project_homes(i) == 0, "power loss immediately blocks standing developed lots")
	c.apply_command("power", [STATION])
	t.check(c.project_homes(i) == 3, "power restoration restores eligibility")
	c.development[c.index(LOT_C)] = 0
	c.development[c.index(LOT_A)] = 2
	c.development[c.index(LOT_B)] = 2
	c.rebuild_derived()
	t.check(c.project_homes(i) == 2 and not c.complete_project(PARK).ok, "two level-two lots are insufficient")
	c.development[c.index(LOT_C)] = 1
	c.rebuild_derived()
	for cell in [Vector2i(-1, -1), Vector2i(16, 22), Vector2i(7, 9)]:
		before = c.canonical()
		t.check(not c.complete_project(cell).ok and c.canonical() == before, "invalid completion target is atomic %s" % cell)
	c.cash = 0
	c.rebuild_derived()
	var paired: City = Codec.decode(c.canonical()).city
	var seq: int = c.sequence
	t.check(c.complete_project(PARK).ok and c.project.completed and c.project.park_index == i and c.sequence == seq + 1 and same_sim(c, paired), "zero-cash completion changes only project and one sequence")
	before = c.canonical()
	t.check(not c.complete_project(PARK).ok and c.canonical() == before, "repeat completion cannot reward or advance sequence")
	c.apply_command("park", [PARK])
	t.check(c.canonical() == before, "identical park repaint retains decoration without change")
	days(c, 90)
	days(paired, 90)
	t.check(same_sim(c, paired), "completion has no simulation effect over three months")
	c.apply_command("clear", [ROOT])
	days(c, 20)
	t.check(c.project.completed and c.project.park_index == i and c.project_homes(i) == 0, "completion survives later service loss and decline")
	t.check(Codec.decode(c.canonical()).city.canonical() == c.canonical(), "completed history loads without currently qualifying lots")
	c.apply_command("clear", [PARK])
	t.check(c.project.completed and c.project.park_index == -1 and Codec.decode(c.canonical()).city.canonical() == c.canonical(), "clearing anchor retains completion and round-trips")
	c.cash = 10000
	c.apply_command("park", [PARK])
	t.check(c.project.park_index == -1 and not c.complete_project(PARK).ok, "replacement cannot regain decoration or repeat project")
	c.initialize()
	t.check(c.project == {"completed": false, "park_index": -1}, "new town resets project")
	c = town()
	days(c, 5)
	c.sequence = City.MAX_TICK
	before = c.canonical()
	t.check(not c.complete_project(PARK).ok and c.canonical() == before, "completion respects command limit")
	test_geometry()
	test_saves()
	var fixture: String = "res://tests/fixtures/m3a-schema5.json"
	t.check(FileAccess.get_sha256(fixture) == "805fb299a49c14babfa7d96a375026c435037d5db546f89b01565e743cf489ef", "schema-5 completed fixture hash")
	var fixture_text: String = FileAccess.get_file_as_string(fixture).strip_edges()
	var loaded: Dictionary = Codec.decode(fixture_text)
	t.check(loaded.ok and loaded.migrated_from == 5 and loaded.cleared_tiles == t.legacy_footprint_tiles(fixture_text) and loaded.city.canonical() == t.migrated_text(fixture_text), "schema-5 fixture migrates keeping completion and its park")
	if loaded.ok:
		var saved: City = loaded.city
		saved.advance_day()
		t.check(saved.tick == 60 and saved.cash == 938500 and saved.pending_us == 234567 and saved.project == {"completed": true, "park_index": 21}, "migrated schema-5 fixture settles grant minus road and park upkeep and keeps completion")
	var current: String = "res://tests/fixtures/m2e-schema6.json"
	t.check(FileAccess.get_sha256(current) == M2E_FIXTURE_SHA, "schema-6 lot fixture hash")
	var current_text: String = FileAccess.get_file_as_string(current).strip_edges()
	var current_loaded: Dictionary = Codec.decode(current_text)
	t.check(current_loaded.ok and current_loaded.migrated_from == 6 and current_loaded.cleared_tiles == 0 and current_loaded.city.canonical() == t.migrated_text(current_text), "schema-6 lot fixture migrates unchanged at the standard tax rate")
	if current_loaded.ok:
		var lots: City = current_loaded.city
		var opening: int = lots.cash
		t.check(lots.tick == 59 and lots.lot_anchors.size() == 3 and lots.station_anchors.size() == 1 and lots.growth.population == 12 and lots.last_budget.tick == 30 and lots.project.completed, "schema-6 fixture holds developed lots, a 4x4 station, a park, a ledger and a completed project")
		lots.advance_day()
		t.check(lots.tick == 60 and lots.cash == opening + 4400 and lots.pending_us == 234567 and lots.project == {"completed": true, "park_index": i}, "schema-6 fixture continues to an exact $44 settlement keeping completion and fractional time")
	print("PASS group: project eligibility with lots, atomic completion, lifetime and saves")

func test_geometry() -> void:
	var c: City = t.land(16, 16)
	c.apply_command("road", t.join(t.column(3, 0, 8), t.row(8, 4, 15)))
	c.apply_command("power", [Vector2i(4, 4)])
	c.apply_command("park", [Vector2i(0, 0)])
	c.apply_command("home", [Vector2i(0, 3), Vector2i(4, 0)])
	var near: int = c.index(Vector2i(0, 3))
	c.development[near] = 1
	c.development[c.index(Vector2i(4, 0))] = 2
	c.rebuild_derived()
	t.check(c.growth.serviced(c, near) and c.growth.serviced(c, c.index(Vector2i(4, 0))), "both geometry lots have road access and power")
	t.check(c.project_homes(0) == 1, "a lot with a tile at three side-steps counts; a lot whose nearest tile is four away does not")
	c.apply_command("park", [Vector2i(14, 0)])
	t.check(c.project_homes(c.index(Vector2i(14, 0))) == 0, "disjoint parks cannot pool lots")
	for tile in c.footprint_cells(near): c.occupancy[tile] = City.SHOP
	c.rebuild_derived()
	t.check(c.project_homes(0) == 0, "developed shop lot excluded")
	for tile in c.footprint_cells(near): c.occupancy[tile] = City.WORKSHOP
	c.rebuild_derived()
	t.check(c.project_homes(0) == 0, "developed workshop lot excluded")
	# Capacity allocation displaces a developed lot; a park does not protect it.
	c = growth.displacement_town()
	c.apply_command("park", [Vector2i(66, 0)])
	t.check(c.project_homes(c.index(Vector2i(66, 0))) == 1, "distant supplied developed lot qualifies")
	c.apply_command("shop", [Vector2i(0, 1)])
	t.check(c.project_homes(c.index(Vector2i(66, 0))) == 0, "nearest-first power displacement removes project eligibility")
	c.apply_command("power", [Vector2i(68, 5)])
	t.check(c.project_homes(c.index(Vector2i(66, 0))) == 1, "added capacity restores project eligibility")

func test_saves() -> void:
	var c: City = town()
	t.check(Codec.decode(c.canonical()).city.canonical() == c.canonical(), "incomplete project round trip")
	days(c, 59)
	c.pending_us = 234567
	c.complete_project(PARK)
	var b: City = Codec.decode(c.canonical()).city
	Clock.advance(c, 1200000, 1)
	Clock.advance(b, 600000, 1)
	Clock.advance(b, 600000, 1)
	t.check(c.canonical() == b.canonical() and c.tick == 60, "completed project continuation crosses month with fractional frame partition")
	var data: Dictionary = c.snapshot()
	for invalid in [null, {}, {"completed": 1, "park_index": -1}, {"completed": false, "park_index": c.index(PARK)}, {"completed": true, "park_index": true}, {"completed": true, "park_index": 1.5}, {"completed": true, "park_index": 352}, {"completed": true, "park_index": -2}, {"completed": true, "park_index": 0}, {"completed": true, "park_index": -1, "extra": 0}]:
		data.project = invalid
		t.check(not Codec.decode(JSON.stringify(data)).ok, "invalid project record rejected %s" % str(invalid))
	data.erase("project")
	t.check(not Codec.decode(JSON.stringify(data)).ok, "current save missing project rejected")
	for fixture in ["m1-schema1", "m2a-schema1", "m2b-schema2", "m2c-schema3", "m2d-schema4"]:
		var text: String = FileAccess.get_file_as_string("res://tests/fixtures/" + fixture + ".json")
		var decoded: Dictionary = Codec.decode(text)
		t.check(decoded.ok and decoded.city.project == {"completed": false, "park_index": -1}, "migration starts incomplete: " + fixture)
		var old: Dictionary = JSON.parse_string(text)
		old.project = {"completed": false, "park_index": -1}
		t.check(not Codec.decode(JSON.stringify(old)).ok, "legacy schema rejects hidden project: " + fixture)
	var schema5: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/m3a-schema5.json"))
	var zeros: Array = []
	zeros.resize(schema5.occupancy.size())
	zeros.fill(0)
	schema5.footprint_anchor = zeros
	t.check(not Codec.decode(JSON.stringify(schema5)).ok, "schema 5 rejects hidden footprint data")
	var files = t.FaultFiles.new()
	var store := Store.new(files)
	var base: String = OS.get_environment("CITY_TEST_DIR")
	if base.is_empty(): base = "user://tests"
	for source in [["m2d-schema4", 4], ["m3a-schema5", 5], ["m2e-schema6", 6], ["m2f-schema7", 7]]:
		var legacy: String = FileAccess.get_file_as_string("res://tests/fixtures/%s.json" % source[0])
		for backup in [false, true]:
			var path: String = base.path_join("project_%d_%d_%s/manual.json" % [source[1], Time.get_ticks_usec(), str(backup)])
			files.write_text(path, "{broken" if backup else legacy)
			if backup: files.write_text(path + ".bak", legacy)
			if backup: store.save_city(c, path)
			files.fault = "preserve_copy"
			var primary: String = FileAccess.get_file_as_string(path)
			t.check(not store.save_city(c, path).ok and FileAccess.get_file_as_string(path) == primary and (not backup or FileAccess.get_file_as_string(path + ".bak") == legacy), "schema-%d preservation failure retains primary/backup %s" % [source[1], str(backup)])
			files.fault = ""
			t.check(store.save_city(c, path).ok and FileAccess.get_file_as_string(Store.preserved_path(path, source[1])) == legacy, "schema-%d bytes preserved before replacement %s" % [source[1], str(backup)])
