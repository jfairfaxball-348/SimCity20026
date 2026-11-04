extends SceneTree
const City = preload("res://scripts/sim/city_state.gd")
const Balance = preload("res://content/balance.gd")
const Clock = preload("res://scripts/sim/simulation_clock.gd")
const Codec = preload("res://scripts/persistence/save_codec.gd")
const Store = preload("res://scripts/persistence/save_store.gd")
const FileOps = preload("res://scripts/persistence/file_ops.gd")
const World = preload("res://scripts/presentation/world_view.gd")
var checks: int = 0
var failures: Array[String] = []

class FaultFiles extends FileOps:
	var fault: String = ""
	func write_text(path: String, text: String) -> Error:
		if fault == "write": return ERR_CANT_CREATE
		return super.write_text(path, "{" if fault == "truncate" else text)
	func copy_file(from: String, to: String) -> Error:
		if fault == "backup_copy": return ERR_CANT_CREATE
		return super.copy_file(from, to)
	func replace_file(from: String, to: String) -> Error:
		if fault == "backup_replace" and to.ends_with(".bak"): return ERR_CANT_CREATE
		if fault == "promote" and to.ends_with(".json"): return ERR_CANT_CREATE
		return super.replace_file(from, to)

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: ", label)

func fresh() -> City:
	var city := City.new()
	city.initialize(91, 8, 8)
	city.terrain.fill(City.LAND)
	city.rebuild_access()
	return city

func command(city: City, kind: String, cells: Array[Vector2i]) -> Dictionary:
	return city.apply_command(kind, cells)

func run() -> void:
	test_commands()
	test_access()
	test_clock()
	test_codec()
	test_storage()
	test_picking()
	await test_scene()
	if "--prove-failure-exit" in OS.get_cmdline_user_args():
		check(false, "Deliberate runner failure to verify exit code")
	print(JSON.stringify({"suite": "M2a", "checks": checks, "failed": failures.size(), "failures": failures}))
	quit(0 if failures.is_empty() else 1)

func test_commands() -> void:
	var city: City = fresh()
	var cells: Array[Vector2i] = [Vector2i(3,3),Vector2i(4,3),Vector2i(3,3)]
	var before: String = city.canonical()
	var preview: Dictionary = city.preview("road",cells)
	check(preview.ok and preview.cost == 2 * Balance.ROAD_COST, "deduplicated preview price")
	check(city.canonical() == before, "preview never mutates model")
	var result: Dictionary = command(city,"road",cells)
	check(result.ok and result.changed.size() == 2, "road stroke accepted")
	check(city.cash == Balance.STARTING_CASH - 2 * Balance.ROAD_COST, "exact charge")
	check(result.record.sequence == 1 and result.record.tick == 0, "ordered command record")
	before = city.canonical()
	check(command(city,"road",cells).ok and city.canonical() == before, "repeated road is exact no-op")
	check(not command(city,"home",[Vector2i(5,3),Vector2i(3,3)]).ok and city.canonical() == before, "conflict rejects entire stroke")
	for bad in [Vector2i(-1,0), Vector2i(8,0), Vector2i(0,8), Vector2i(0,-1)]:
		check(not command(city,"road",[Vector2i(5,3),bad]).ok and city.canonical() == before, "bounds rejection %s" % bad)
	city.terrain[city.index(Vector2i(1,1))] = City.WATER
	before = city.canonical()
	for kind in ["road","home","clear"]:
		check(not command(city,kind,[Vector2i(5,3),Vector2i(1,1)]).ok and city.canonical() == before, "water rejection " + kind)
	check(not command(city,"invalid",cells).ok and city.canonical() == before, "unknown tool rejection")
	city.cash = Balance.HOME_COST - 1
	before = city.canonical()
	check(not command(city,"home",[Vector2i(5,3)]).ok and city.canonical() == before, "insufficient funds preserves complete state")
	city.cash = Balance.HOME_COST
	check(command(city,"home",[Vector2i(5,3)]).ok and city.cash == 0, "exact affordability")
	check(command(city,"home",[Vector2i(5,3)]).ok and city.cash == 0, "no-op valid with zero funds")
	var old_terrain: PackedByteArray = city.terrain.duplicate()
	check(command(city,"clear",[Vector2i(5,3)]).ok and city.cash == 0, "clear free with no refund")
	check(city.terrain == old_terrain and city.occupancy[city.index(Vector2i(5,3))] == City.EMPTY, "clear preserves terrain")
	before = city.canonical()
	check(command(city,"clear",[Vector2i(5,3)]).ok and city.canonical() == before, "empty clear idempotent")
	check(command(city,"road",[]).ok and city.canonical() == before, "empty stroke idempotent")
	var a: City = fresh()
	var b: City = fresh()
	command(a,"road",[Vector2i(2,2),Vector2i(3,2)])
	command(b,"road",[Vector2i(3,2),Vector2i(2,2)])
	check(a.canonical() == b.canonical(), "stroke order canonicalized")
	a.initialize(123)
	b.initialize(123)
	check(a.canonical() == b.canonical(), "seed reproduces terrain and rng")
	b.initialize(124)
	check(a.terrain != b.terrain, "seed changes coastline")
	check(a.terrain[a.index(Vector2i(32,32))] == City.LAND, "starting ground is buildable")
	a.initialize(123,8,128)
	check(a.terrain.size() == 1024 and a.terrain[a.index(Vector2i(7,127))] == City.LAND, "narrow tall map shoreline stays inside bounds")
	print("PASS group: construction and seeded maps")

func test_access() -> void:
	var city: City = fresh()
	var gate := Vector2i(7,4)
	check(city.access.root == gate and city.access.connected_roads.count(1) == 0, "link exists without free roads or service")
	command(city,"road",[Vector2i(6,4),Vector2i(5,4),Vector2i(4,4)])
	command(city,"home",[Vector2i(4,3),Vector2i(2,1),Vector2i(2,3)])
	command(city,"road",[Vector2i(2,2)])
	check(city.access.home_reason(city,Vector2i(4,3)) == "disconnected_road", "inactive root leaves neighbouring district unserved")
	check(city.access.home_reason(city,Vector2i(1,1)) == "not_home", "open land is not a home zone")
	command(city,"road",[gate])
	check(city.access.connected_roads.count(1) == 4 and city.access.served_homes.count(1) == 1, "only the rooted district gets access")
	check(city.access.home_reason(city,Vector2i(4,3)) == "connected", "home beside rooted road has access")
	check(city.access.home_reason(city,Vector2i(2,1)) == "disconnected_road", "isolated district reason identifies disconnected road")
	var snapshot: String = city.canonical()
	var served: PackedByteArray = city.access.served_homes.duplicate()
	city.preview("clear",[Vector2i(5,4)])
	command(city,"home",[gate,Vector2i(3,3)])
	check(city.canonical() == snapshot and city.access.served_homes == served, "preview and rejected stroke preserve access and money")
	command(city,"clear",[Vector2i(5,4)])
	check(city.access.connected_roads.count(1) == 2 and city.access.served_homes.count(1) == 0, "bridge demolition splits road and home service immediately")
	var restored: City = Codec.decode(city.canonical()).city
	check(restored.access.connected_roads == city.access.connected_roads and restored.access.served_homes == city.access.served_homes, "disconnected network is reconstructed on load")
	for item in [city,restored]: command(item,"road",[Vector2i(5,4)])
	check(city.canonical() == restored.canonical() and city.access.served_homes == restored.access.served_homes and city.access.served_homes.count(1) == 1, "reconnection and save continuation agree")
	command(city,"clear",[gate])
	check(city.access.root == gate and city.access.connected_roads.count(1) == 0, "demolished root stays marked and deactivates all roads")
	command(city,"home",[gate])
	check(city.access.home_reason(city,gate) == "link_occupied", "home on marker explicitly explains blocked link")
	command(city,"clear",[gate])
	command(city,"road",[gate])
	check(city.access.served_homes.count(1) == 1, "clearing blocked root and rebuilding restores service")
	command(city,"home",[Vector2i(5,5)])
	check(city.access.served_homes[city.index(Vector2i(5,5))] == 1, "new home gains access without a road edit")
	command(city,"clear",[Vector2i(5,5)])
	check(city.access.served_homes[city.index(Vector2i(5,5))] == 0, "home demolition removes derived service")

	city = fresh()
	command(city,"road",[gate,Vector2i(6,3),Vector2i(0,5),Vector2i(7,0)])
	command(city,"home",[Vector2i(6,2),Vector2i(6,5),Vector2i(0,4)])
	check(city.access.connected_roads.count(1) == 1, "diagonal, wrapped-row, and other-edge roads do not join root")
	check(city.access.home_reason(city,Vector2i(6,5)) == "no_adjacent_road", "diagonal home needs a side-sharing road")
	check(city.access.served_homes.count(1) == 0, "diagonal roads and homes cannot transmit service")
	command(city,"home",[Vector2i(6,4),Vector2i(5,4)])
	command(city,"road",[Vector2i(4,4)])
	check(city.access.served_homes[city.index(Vector2i(6,4))] == 1 and city.access.served_homes[city.index(Vector2i(5,4))] == 0 and city.access.connected_roads.count(1) == 1, "homes do not relay access to other homes or roads")

	var loop: Array[Vector2i] = [gate,Vector2i(6,4),Vector2i(5,4),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5)]
	var a: City = fresh()
	var b: City = fresh()
	command(a,"road",loop)
	loop.reverse()
	command(b,"road",loop)
	check(a.access.connected_roads.count(1) == 6 and a.access.connected_roads == b.access.connected_roads and a.canonical() == b.canonical(), "cyclic graph terminates deterministically regardless of stroke order")
	command(a,"clear",[Vector2i(6,4)])
	check(a.access.connected_roads.count(1) == 5, "alternate route preserves service after one bridge removal")
	snapshot = a.canonical()
	a.rebuild_access()
	check(a.canonical() == snapshot, "derived rebuild leaves authoritative data and RNG unchanged")

	city = fresh()
	city.terrain[city.index(gate)] = City.WATER
	city.rebuild_access()
	check(city.access.root == Vector2i(7,3), "water at preferred root uses nearest boundary land with stable tie-break")
	for y in range(8):
		for x in range(8):
			if x in [0,7] or y in [0,7]: city.terrain[city.index(Vector2i(x,y))] = City.WATER
	city.rebuild_access()
	command(city,"home",[Vector2i(4,4)])
	check(city.access.root == Vector2i(-1,-1) and city.access.home_reason(city,Vector2i(4,4)) == "no_outside_link", "water-only boundary is valid but explains unavailable access")
	restored = Codec.decode(city.canonical()).city
	check(restored.access.root == city.access.root and restored.access.served_homes == city.access.served_homes, "unusual legacy terrain loads without fabricating a link")
	for dimensions in [Vector2i(8,128),Vector2i(128,8),Vector2i(64,64),Vector2i(128,128)]:
		for map_seed in [0,91,198624]:
			city.initialize(map_seed,dimensions.x,dimensions.y)
			check(city.access.root == Vector2i(dimensions.x-1,dimensions.y/2), "seeded map has buildable east link %s seed %d" % [dimensions,map_seed])
	city.cash = Balance.MAX_CASH
	city.terrain.fill(City.LAND)
	var all_cells: Array[Vector2i] = []
	for y in range(128):
		for x in range(128): all_cells.append(Vector2i(x,y))
	command(city,"road",all_cells)
	check(city.access.connected_roads.count(1) == 16384, "maximum map flood fill reaches every road without recursion")

	var fixture: String = FileAccess.get_file_as_string("res://tests/fixtures/m1-schema1.json").strip_edges()
	var decoded: Dictionary = Codec.decode(fixture)
	check(decoded.ok and decoded.city.canonical() == fixture, "pre-M2a fixture loads with byte-identical canonical M1 state")
	if decoded.ok:
		city = decoded.city
		check(city.access.connected_roads.count(1) == 3 and city.access.served_homes.count(1) == 1, "legacy roads derive connected and disconnected districts")
		check(city.access.home_reason(city,Vector2i(5,3)) == "connected" and city.access.home_reason(city,Vector2i(2,1)) == "disconnected_road", "legacy zones receive accurate reasons")
		restored = Codec.decode(city.canonical()).city
		for item in [city,restored]:
			command(item,"clear",[Vector2i(6,4)])
			Clock.advance(item,1_000_000,1)
		check(city.canonical() == restored.canonical() and city.rng.randi() == restored.rng.randi() and city.access.served_homes == restored.access.served_homes, "legacy round trip preserves continued commands clock RNG and access")
	print("PASS group: rooted road access, explanations, and M1 fixture")

func test_clock() -> void:
	var a: City = fresh()
	var before: String = a.canonical()
	check(Clock.advance(a,5_000_000,0) == 0 and a.canonical() == before, "pause freezes clock and backlog")
	check(command(a,"road",[Vector2i(2,2)]).ok and a.tick == 0, "construction while paused")
	var b: City = fresh()
	var c: City = fresh()
	for i in range(120): Clock.advance(b,25_000,1)
	for i in range(30): Clock.advance(c,100_000,1)
	check(b.canonical() == c.canonical() and b.tick == 3, "frame partition independence")
	Clock.advance(b,250_000,3)
	check(b.tick == 3 and b.pending_us == 750_000, "fast speed retains fractional day")
	Clock.advance(b,100_000,3)
	check(b.tick == 4 and b.pending_us == 50_000, "fast speed exact accumulation")
	var d: City = fresh()
	check(Clock.advance(d,20_000_000,1) == 8 and d.pending_us == 12_000_000, "stalled frame bounds work and retains backlog")
	Clock.advance(d,0,1)
	Clock.advance(d,0,1)
	check(d.tick == 20 and d.pending_us == 0, "backlog drains without lost ticks")
	before = d.canonical()
	Clock.advance(d,-1,1)
	Clock.advance(d,100,7)
	check(before == d.canonical(), "invalid clock inputs ignored")
	var long_frame: City = fresh()
	var partitioned: City = fresh()
	Clock.advance(long_frame, 90_000_000, 1)
	for i in range(90): Clock.advance(partitioned, 1_000_000, 1)
	while long_frame.pending_us >= Clock.STEP_US: Clock.advance(long_frame, 0, 1)
	check(long_frame.canonical() == partitioned.canonical(), "90-second frame retains the same time as partitioned frames")
	Clock.advance(long_frame, 9_000_000_000_000_000_000, 3)
	check(long_frame.pending_us == City.MAX_PENDING_US - 8 * Clock.STEP_US, "extreme stall is bounded without integer overflow")
	print("PASS group: fixed clock")

func test_codec() -> void:
	var city: City = fresh()
	command(city,"home",[Vector2i(4,4)])
	Clock.advance(city,250_000,3)
	city.rng.state = 9223372036854775001
	var decoded: Dictionary = Codec.decode(city.canonical())
	check(decoded.ok and decoded.city.canonical() == city.canonical(), "save round trip exact, including 64-bit state")
	var restored: City = decoded.city
	check(city.rng.randi() == restored.rng.randi(), "lossless random stream continuation")
	for item in [city,restored]:
		command(item,"road",[Vector2i(5,5)])
		Clock.advance(item,1_100_000,3)
	check(city.canonical() == restored.canonical(), "continued state after reload matches uninterrupted state")
	for bad_text in ["", "{", "[]", "null", "{\"schema_version\":1}"]:
		check(not Codec.decode(bad_text).ok, "reject malformed/incomplete data: " + bad_text)
	check(not Codec.decode(" ".repeat(Codec.MAX_BYTES + 1)).ok, "oversize save rejected")
	var mutations: Array = [
		["schema_version",2], ["schema_version",0], ["schema_version",true],
		["simulation_version","future"], ["content_version","future"],
		["width",129], ["height",7], ["width",64.5], ["cash",-1],
		["cash",1.5], ["cash",true], ["tick",-1], ["sequence",-1],
		["pending_us",City.MAX_PENDING_US + 1], ["seed","abc"],
		["random_state",9223372036854775001], ["random_state","9223372036854775808"],
		["random_state","01"], ["occupancy",[]], ["terrain",{}]]
	var original: String = city.canonical()
	for mutation in mutations:
		var data: Dictionary = city.snapshot()
		data[mutation[0]] = mutation[1]
		check(not Codec.decode(JSON.stringify(data)).ok, "invalid field: %s = %s" % mutation)
	var data: Dictionary = city.snapshot()
	data.terrain[0] = 2
	check(not Codec.decode(JSON.stringify(data)).ok, "unknown terrain identifier")
	data = city.snapshot()
	data.occupancy[0] = 3
	check(not Codec.decode(JSON.stringify(data)).ok, "unknown use identifier")
	data = city.snapshot()
	data.terrain[0] = City.WATER
	data.occupancy[0] = City.HOME
	check(not Codec.decode(JSON.stringify(data)).ok, "inconsistent occupied water")
	check(city.canonical() == original, "failed decoding never mutates live model")
	for number in ["-9223372036854775808","9223372036854775807","0"]:
		check(Codec.signed_integer_string(number), "valid signed state " + number)
	print("PASS group: save validation and deterministic continuation")

func test_storage() -> void:
	var files := FaultFiles.new()
	var store := Store.new(files)
	var base: String = OS.get_environment("CITY_TEST_DIR")
	if base.is_empty(): base = "user://tests"
	var path: String = base.path_join("storage_%d/city.json" % Time.get_ticks_usec())
	var city: City = fresh()
	var first: String = city.canonical()
	check(store.save_city(city,path).ok, "first save writes verified primary")
	check(store.load_city(path).city.canonical() == first, "disk primary round trip")
	command(city,"road",[Vector2i(2,2)])
	var second: String = city.canonical()
	check(store.save_city(city,path).ok, "second save replaces existing Windows file")
	check(store.load_city(path + ".bak").city.canonical() == first, "backup is preceding good state")
	for fault in ["write","truncate","backup_copy","backup_replace","promote"]:
		files.fault = fault
		command(city,"home",[Vector2i(3,3)])
		check(not store.save_city(city,path).ok, "save fails visibly at " + fault)
		check(store.load_city(path).city.canonical() == second, "primary retained after " + fault)
		check(store.load_city(path + ".bak").ok, "valid backup retained after " + fault)
	files.fault = ""
	files.write_text(path,"{broken")
	var good_backup: String = store.load_city(path + ".bak").city.canonical()
	check(not store.load_city(path).ok, "corrupt primary rejected")
	check(store.save_city(city,path).ok, "save recovers from corrupt primary")
	check(store.load_city(path + ".bak").city.canonical() == good_backup, "corrupt primary never rotates over good backup")
	files.write_text(path + ".tmp", "{interrupted")
	check(store.load_city(path).city.canonical() == city.canonical(), "interrupted temp write does not affect current save")
	check(not store.load_city(path + ".missing").ok, "missing save fails clearly")
	print("PASS group: real filesystem and injected failure recovery")

func test_picking() -> void:
	var view := World.new()
	view.city = fresh()
	view.origin = Vector2.ZERO
	check(view.cell_at(Vector2(-1,0)) == Vector2i(-1,0), "negative viewport coordinates do not truncate onto map")
	for zoom in [1,2,3]:
		view.zoom = zoom
		view.origin = Vector2(13,9)
		var cell := Vector2i(3,4)
		check(view.cell_at(view.tile_rect(cell).get_center()) == cell, "cell picking after camera and zoom %d" % zoom)
		view.clamp_camera()
		check(Rect2(Vector2.ZERO,World.VIEW).has_point(view.tile_rect(view.city.access.root).get_center()), "small legacy map stays visible at zoom %d" % zoom)
	view.free()
	print("PASS group: camera transform")

func test_scene() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	check(scene != null, "main scene and dependency scripts load")
	var main: Control = scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	check(main.world != null and main.city.width == 64, "real scene initializes model and viewport")
	check(not main._is_world_position(main.side.get_global_rect().get_center()), "sidebar excluded from world picking")
	check(not main._is_world_position(main.top.get_global_rect().get_center()), "toolbar excluded from world picking")
	main._select_tool("home")
	main._extend_stroke(Vector2i(30,30))
	main._commit_stroke()
	check(main.city.occupancy[main.city.index(Vector2i(30,30))] == City.HOME, "scene command uses authoritative model")
	main.queue_free()
	await process_frame
	print("PASS group: scene initialization and model binding")
