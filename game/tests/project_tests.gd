extends RefCounted
const City = preload("res://scripts/sim/city_state.gd")
const Codec = preload("res://scripts/persistence/save_codec.gd")
const Store = preload("res://scripts/persistence/save_store.gd")
const Clock = preload("res://scripts/sim/simulation_clock.gd")
var t: SceneTree
const PARK := Vector2i(5, 2)

func town() -> City:
	var c: City = t.fresh()
	c.apply_command("road", t.row(4, 1, 7))
	c.apply_command("power", [Vector2i(1, 5)])
	c.apply_command("home", [Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3)])
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
	var c: City = town()
	var i: int = c.index(PARK)
	var before: String = c.canonical()
	t.check(c.project_homes(i) == 0 and not c.complete_project(PARK).ok and c.canonical() == before, "empty home plots do not qualify; failure atomic")
	days(c, 5)
	t.check(c.project_homes(i) == 3 and not c.project.completed, "three level-one homes qualify without automatic completion")
	c.apply_command("clear", [Vector2i(7, 4)])
	before = c.canonical()
	t.check(c.project_homes(i) == 0 and not c.complete_project(PARK).ok and c.canonical() == before, "road loss invalidates stale completion immediately during decline grace")
	c.apply_command("road", [Vector2i(7, 4)])
	t.check(c.project_homes(i) == 3, "road restoration immediately restores eligibility")
	c.apply_command("clear", [Vector2i(1, 5)])
	t.check(c.project_homes(i) == 0, "power loss immediately blocks standing developed homes")
	c.apply_command("power", [Vector2i(1, 5)])
	t.check(c.project_homes(i) == 3, "power restoration restores eligibility")
	c.development[c.index(Vector2i(6, 3))] = 0
	c.development[c.index(Vector2i(4, 3))] = 2
	c.development[c.index(Vector2i(5, 3))] = 2
	c.rebuild_derived()
	t.check(c.project_homes(i) == 2 and not c.complete_project(PARK).ok, "two level-two plots are insufficient")
	c.development[c.index(Vector2i(6, 3))] = 1
	c.rebuild_derived()
	for cell in [Vector2i(-1, -1), Vector2i(8, 8), Vector2i(4, 3)]:
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
	c.apply_command("clear", [Vector2i(7, 4)])
	days(c, 20)
	t.check(c.project.completed and c.project.park_index == i and c.project_homes(i) == 0, "completion survives later service loss and decline")
	t.check(Codec.decode(c.canonical()).city.canonical() == c.canonical(), "completed history loads without currently qualifying homes")
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
	t.check(loaded.ok and loaded.migrated_from == 0 and loaded.city.canonical() == fixture_text, "schema-5 fixture exact round trip")
	if loaded.ok:
		var saved: City = loaded.city
		saved.advance_day()
		t.check(saved.tick == 60 and saved.cash == 934900 and saved.pending_us == 234567 and saved.project == {"completed": true, "park_index": 21}, "schema-5 fixture next settlement preserves completion and fractional time")
	print("PASS group: project eligibility, atomic completion, lifetime and schema 5")

func test_geometry() -> void:
	var c: City = t.fresh()
	c.apply_command("road", t.row(4, 0, 7))
	c.apply_command("power", [Vector2i(7, 5)])
	c.apply_command("park", [Vector2i(0, 0)])
	c.apply_command("home", [Vector2i(0, 3), Vector2i(1, 3)])
	c.development[c.index(Vector2i(0, 3))] = 1
	c.development[c.index(Vector2i(1, 3))] = 2
	c.rebuild_derived()
	t.check(c.project_homes(0) == 1, "corner-clipped radius includes three and excludes four side-steps")
	c.apply_command("park", [Vector2i(6, 1)])
	t.check(c.project_homes(c.index(Vector2i(6, 1))) == 0, "disjoint parks cannot pool homes")
	c.occupancy[c.index(Vector2i(0, 3))] = City.SHOP
	c.rebuild_derived()
	t.check(c.project_homes(0) == 0, "developed shop excluded")
	c.occupancy[c.index(Vector2i(0, 3))] = City.WORKSHOP
	c.rebuild_derived()
	t.check(c.project_homes(0) == 0, "developed workshop excluded")
	# Capacity allocation displaces a developed home; park does not protect it.
	c = t.land(32, 8)
	c.apply_command("road", t.row(4, 0, 31))
	c.apply_command("power", [Vector2i(0, 5)])
	c.apply_command("home", t.row(3, 10, 29))
	c.apply_command("park", [Vector2i(29, 2)])
	c.development[c.index(Vector2i(29, 3))] = 2
	c.rebuild_derived()
	t.check(c.project_homes(c.index(Vector2i(29, 2))) == 1, "distant supplied developed home qualifies")
	c.apply_command("shop", [Vector2i(1, 3)])
	t.check(c.project_homes(c.index(Vector2i(29, 2))) == 0, "nearest-first power displacement removes project eligibility")
	c.apply_command("power", [Vector2i(31, 5)])
	t.check(c.project_homes(c.index(Vector2i(29, 2))) == 1, "added capacity restores project eligibility")

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
	for invalid in [null, {}, {"completed": 1, "park_index": -1}, {"completed": false, "park_index": c.index(PARK)}, {"completed": true, "park_index": true}, {"completed": true, "park_index": 1.5}, {"completed": true, "park_index": 64}, {"completed": true, "park_index": -2}, {"completed": true, "park_index": 0}, {"completed": true, "park_index": -1, "extra": 0}]:
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
	var legacy: String = FileAccess.get_file_as_string("res://tests/fixtures/m2d-schema4.json")
	var files = t.FaultFiles.new()
	var store := Store.new(files)
	var base: String = OS.get_environment("CITY_TEST_DIR")
	if base.is_empty(): base = "user://tests"
	for backup in [false, true]:
		var path: String = base.path_join("project_%d_%s/manual.json" % [Time.get_ticks_usec(), str(backup)])
		files.write_text(path, "{broken" if backup else legacy)
		if backup: files.write_text(path + ".bak", legacy)
		if backup: store.save_city(c, path)
		files.fault = "preserve_copy"
		var primary: String = FileAccess.get_file_as_string(path)
		t.check(not store.save_city(c, path).ok and FileAccess.get_file_as_string(path) == primary and (not backup or FileAccess.get_file_as_string(path + ".bak") == legacy), "schema-4 preservation failure retains primary/backup %s" % str(backup))
		files.fault = ""
		t.check(store.save_city(c, path).ok and FileAccess.get_file_as_string(Store.preserved_path(path, 4)) == legacy, "schema-4 bytes preserved before replacement %s" % str(backup))
