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
		if fault == "preserve_copy" and (to.contains(".schema1.json") or to.contains(".schema2.json")): return ERR_CANT_CREATE
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
	city.rebuild_derived()
	return city

func command(city: City, kind: String, cells: Array[Vector2i]) -> Dictionary:
	return city.apply_command(kind, cells)

func run() -> void:
	test_commands()
	test_access()
	test_power()
	test_migration()
	preload("res://tests/growth_tests.gd").new().run(self)
	test_clock()
	test_codec()
	test_storage()
	test_picking()
	await test_scene()
	if "--prove-failure-exit" in OS.get_cmdline_user_args():
		check(false, "Deliberate runner failure to verify exit code")
	print(JSON.stringify({"suite": "M2c", "checks": checks, "failed": failures.size(), "failures": failures}))
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
	a.rebuild_derived()
	check(a.canonical() == snapshot, "derived rebuild leaves authoritative data and RNG unchanged")

	city = fresh()
	city.terrain[city.index(gate)] = City.WATER
	city.rebuild_derived()
	check(city.access.root == Vector2i(7,3), "water at preferred root uses nearest boundary land with stable tie-break")
	for y in range(8):
		for x in range(8):
			if x in [0,7] or y in [0,7]: city.terrain[city.index(Vector2i(x,y))] = City.WATER
	city.rebuild_derived()
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
	check(decoded.ok and decoded.city.canonical() == migrated_text(fixture), "pre-M2a fixture migrates with version fields and zero growth arrays")
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
		["schema_version",4], ["schema_version",1], ["schema_version",0], ["schema_version",true],
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
	data.occupancy[0] = 6
	check(not Codec.decode(JSON.stringify(data)).ok, "unknown use identifier")
	data = city.snapshot()
	data.occupancy[0] = City.POWER
	check(Codec.decode(JSON.stringify(data)).ok, "schema 2 accepts power-station identifier")
	data.erase("development")
	data.erase("service_loss")
	data.schema_version = 1
	data.simulation_version = "m1-1"
	data.content_version = "m1-1"
	check(not Codec.decode(JSON.stringify(data)).ok, "schema 1 rejects identifier 3 instead of reinterpreting it")
	data = city.snapshot()
	data.terrain[0] = City.WATER
	data.occupancy[0] = City.HOME
	check(not Codec.decode(JSON.stringify(data)).ok, "inconsistent occupied water")
	data.occupancy[0] = City.POWER
	check(not Codec.decode(JSON.stringify(data)).ok, "power station on water rejected")
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
	main._select_tool("power")
	main._extend_stroke(Vector2i(31,30))
	main._extend_stroke(Vector2i(33,30))
	check(main.stroke.size() == 1 and main.stroke[0] == Vector2i(33,30), "power tool previews exactly one station under the pointer")
	main._commit_stroke()
	check(main.city.occupancy[main.city.index(Vector2i(33,30))] == City.POWER and main.city.power.station_count == 1 and main.city.cash == Balance.STARTING_CASH - Balance.HOME_COST - Balance.POWER_COST, "scene places one paid station")
	main._inspect_cell(Vector2i(33,30))
	check(main.power_label.text.contains("Supplies 20 units") and main.grid_label.text.begins_with("Power 0 / 20"), "inspector and toolbar report station capacity")
	main.queue_free()
	await process_frame
	print("PASS group: scene initialization and model binding")

func land(w: int, h: int) -> City:
	var city := City.new()
	city.initialize(91, w, h)
	city.terrain.fill(City.LAND)
	city.rebuild_derived()
	return city

func row(y: int, from_x: int, to_x: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in range(from_x, to_x + 1): out.append(Vector2i(x, y))
	return out

func column(x: int, from_y: int, to_y: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(from_y, to_y + 1): out.append(Vector2i(x, y))
	return out

func join(a: Array[Vector2i], b: Array[Vector2i]) -> Array[Vector2i]:
	var out: Array[Vector2i] = a.duplicate()
	out.append_array(b)
	return out

func one(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = [cell]
	return out

func reason(city: City, cell: Vector2i) -> String:
	return city.power.home_reason(city, cell)

func net(city: City, cell: Vector2i) -> int:
	return city.power.network_of[city.index(cell)]

## Expected migration: retain all old fields and add zero development/loss arrays.
func migrated_text(legacy: String) -> String:
	var data: Dictionary = JSON.parse_string(legacy)
	data.schema_version = City.SCHEMA
	data.simulation_version = City.SIMULATION
	data.content_version = City.CONTENT
	var zeros: Array = []
	zeros.resize(int(data.width) * int(data.height))
	zeros.fill(0)
	for field in ["width", "height", "cash", "tick", "sequence", "pending_us"]: data[field] = int(data[field])
	data.terrain = Array(PackedByteArray(data.terrain))
	data.occupancy = Array(PackedByteArray(data.occupancy))
	data.development = zeros.duplicate()
	data.service_loss = zeros.duplicate()
	return JSON.stringify(data, "", true)

func test_power() -> void:
	# One network: exact capacity accounting and nearest-first shortage ties.
	var city: City = land(12, 8)
	command(city, "road", row(4, 1, 10))
	command(city, "home", join(row(3, 1, 10), row(5, 1, 10)))
	check(city.power.station_count == 0 and city.power.total_capacity == 0 and city.power.powered_homes == 0, "no free power source exists")
	check(reason(city, Vector2i(4, 3)) == "no_source", "plots explain that no power station exists")
	check(net(city, Vector2i(1, 4)) == net(city, Vector2i(10, 4)) and net(city, Vector2i(4, 3)) == -1, "roads form one network; home plots are not network tiles")
	var before_cash: int = city.cash
	var built: Dictionary = command(city, "power", one(Vector2i(0, 4)))
	check(built.ok and built.record.cost == Balance.POWER_COST and city.cash == before_cash - Balance.POWER_COST, "station charges its exact price once")
	check(city.power.total_capacity == Balance.POWER_CAPACITY and city.power.total_used == 20 and city.power.powered_homes == 20 and city.power.short_homes == 0, "twenty plots exactly fill one station")
	check(city.access.connected_roads.count(1) == 0 and reason(city, Vector2i(4, 3)) == "powered" and city.access.home_reason(city, Vector2i(4, 3)) == "disconnected_road", "power works on a road network without outside access")
	command(city, "home", one(Vector2i(0, 3)))
	check(reason(city, Vector2i(0, 3)) == "powered", "plot beside a station draws power directly")
	check(reason(city, Vector2i(10, 3)) == "powered" and reason(city, Vector2i(10, 5)) == "shortage", "equal-distance shortage tie resolves by row-major plot order")
	check(city.power.short_homes == 1 and city.power.network_short[net(city, Vector2i(5, 4))] == 1 and city.power.total_used == 20 and city.power.network_used[net(city, Vector2i(5, 4))] == 20, "shortage counted without exceeding capacity")
	var states: PackedByteArray = city.power.home_state.duplicate()
	var other: City = land(12, 8)
	command(other, "home", one(Vector2i(0, 3)))
	var homes: Array[Vector2i] = join(row(5, 1, 10), row(3, 1, 10))
	homes.reverse()
	command(other, "home", homes)
	command(other, "power", one(Vector2i(0, 4)))
	var roads: Array[Vector2i] = row(4, 1, 10)
	roads.reverse()
	command(other, "road", roads)
	check(other.occupancy == city.occupancy and other.power.home_state == states and other.power.home_network == city.power.home_network, "allocation ignores command history and stroke order")
	# Station on the east end: nearest-first and row-major order disagree here.
	var east: City = land(12, 8)
	command(east, "road", row(4, 0, 9))
	command(east, "power", one(Vector2i(10, 4)))
	command(east, "home", join(join(row(3, 0, 9), row(5, 0, 9)), one(Vector2i(10, 3))))
	check(reason(east, Vector2i(10, 3)) == "powered" and reason(east, Vector2i(9, 5)) == "powered" and reason(east, Vector2i(0, 3)) == "powered" and reason(east, Vector2i(0, 5)) == "shortage", "the farthest plot is short, not the last plot in row-major order")

	# Rejected or unaffordable commands spend nothing and leave power unchanged.
	var snapshot: String = city.canonical()
	var attempts: Array = [["power", [Vector2i(2, 6), Vector2i(3, 6)]], ["power", [Vector2i(4, 4)]], ["power", [Vector2i(4, 3)]],
		["power", [Vector2i(11, 4)]], ["power", [Vector2i(12, 0)]], ["home", [Vector2i(0, 4)]], ["road", [Vector2i(0, 4)]]]
	for attempt in attempts:
		var cells: Array[Vector2i] = []
		cells.assign(attempt[1])
		check(not command(city, attempt[0], cells).ok and city.canonical() == snapshot and city.power.home_state == states, "rejected %s %s keeps funds, map, and power" % [attempt[0], attempt[1]])
	var pair: Array[Vector2i] = [Vector2i(2, 6), Vector2i(3, 6)]
	check(String(city.preview("power", one(Vector2i(11, 4))).message).contains("outside-link") and String(city.preview("power", pair).message).contains("one power station"), "station rejections explain the link and one-at-a-time rules")
	other.terrain[other.index(Vector2i(5, 7))] = City.WATER
	other.rebuild_derived()
	snapshot = other.canonical()
	check(not command(other, "power", one(Vector2i(5, 7))).ok and other.canonical() == snapshot, "station on water rejected")
	city.cash = Balance.POWER_COST - 1
	snapshot = city.canonical()
	check(not command(city, "power", one(Vector2i(5, 6))).ok and city.canonical() == snapshot and city.power.home_state == states, "unaffordable station rejected without partial spending")
	city.cash = Balance.POWER_COST
	check(command(city, "power", one(Vector2i(5, 6))).ok and city.cash == 0, "exactly affordable station")
	check(city.power.total_capacity == 40 and city.power.short_homes == 0 and reason(city, Vector2i(10, 5)) == "powered" and city.power.home_network[city.index(Vector2i(5, 5))] == net(city, Vector2i(5, 6)), "a second network relieves the shortage through a shared plot")
	snapshot = city.canonical()
	check(command(city, "power", one(Vector2i(5, 6))).ok and city.canonical() == snapshot, "repeating a station is a free no-op")
	check(command(city, "clear", one(Vector2i(5, 6))).ok and city.cash == 0 and city.occupancy[city.index(Vector2i(5, 6))] == City.EMPTY, "station removal is free with no refund")
	check(city.power.home_state == states and city.power.station_count == 1, "removing a source restores the shortage immediately")

	# Bridge and source removal, then reconnection.
	city.cash = Balance.STARTING_CASH
	command(city, "clear", one(Vector2i(6, 4)))
	check(reason(city, Vector2i(7, 3)) == "disconnected" and reason(city, Vector2i(5, 3)) == "powered" and city.power.short_homes == 0, "bridge removal disconnects the far district and frees capacity")
	check(reason(city, Vector2i(6, 3)) == "no_adjacent_network" and not city.power.carries_power(city.index(Vector2i(7, 4))) and net(city, Vector2i(7, 4)) != net(city, Vector2i(5, 4)), "split network without a station carries no power")
	command(city, "road", one(Vector2i(6, 4)))
	check(city.power.home_state == states, "rebuilding the bridge restores the exact allocation")
	command(city, "clear", one(Vector2i(0, 4)))
	check(city.power.station_count == 0 and city.power.total_used == 0 and reason(city, Vector2i(4, 3)) == "no_source", "removing the only station explains the missing source")
	command(city, "power", one(Vector2i(0, 4)))
	check(city.power.home_state == states, "rebuilding the station restores supply")

	# Relay rules: stations join roads for power only; diagonals and homes carry nothing.
	var relay: City = fresh()
	command(relay, "road", [Vector2i(7, 4), Vector2i(6, 4)])
	command(relay, "power", one(Vector2i(5, 4)))
	command(relay, "road", one(Vector2i(4, 4)))
	command(relay, "home", [Vector2i(4, 3), Vector2i(6, 3)])
	check(net(relay, Vector2i(7, 4)) == net(relay, Vector2i(4, 4)), "a station relays power between the roads it touches")
	check(relay.access.connected_roads[relay.index(Vector2i(4, 4))] == 0 and relay.access.home_reason(relay, Vector2i(4, 3)) == "disconnected_road" and reason(relay, Vector2i(4, 3)) == "powered", "a station does not relay road access")
	check(relay.access.home_reason(relay, Vector2i(6, 3)) == "connected" and reason(relay, Vector2i(6, 3)) == "powered", "connected plot reports both conditions separately")
	command(relay, "power", one(Vector2i(1, 1)))
	command(relay, "road", [Vector2i(2, 2), Vector2i(3, 1)])
	command(relay, "home", [Vector2i(2, 1), Vector2i(4, 1)])
	check(net(relay, Vector2i(2, 2)) != net(relay, Vector2i(1, 1)) and not relay.power.carries_power(relay.index(Vector2i(2, 2))), "a diagonal road does not join a station")
	check(reason(relay, Vector2i(2, 1)) == "powered" and reason(relay, Vector2i(4, 1)) == "disconnected", "home plots do not relay power")

	# Equal distance through two networks resolves by network order, whatever the build order.
	for flipped in [false, true]:
		var tie: City = land(8, 8)
		var steps: Array = [["power", Vector2i(1, 3)], ["road", Vector2i(2, 3)], ["road", Vector2i(4, 3)], ["power", Vector2i(5, 3)], ["home", Vector2i(3, 3)]]
		if flipped: steps.reverse()
		for step in steps: command(tie, step[0], one(step[1]))
		check(tie.power.home_network[tie.index(Vector2i(3, 3))] == net(tie, Vector2i(2, 3)) and net(tie, Vector2i(2, 3)) < net(tie, Vector2i(4, 3)), "equal-distance networks resolve by network order (reversed build %s)" % flipped)

	# A full nearer network spills a later plot to a farther network with room.
	var spill: City = land(16, 12)
	command(spill, "power", one(Vector2i(1, 1)))
	command(spill, "road", column(2, 1, 10))
	homes = join(column(3, 1, 10), column(1, 2, 10))
	homes.append(Vector2i(2, 0))
	command(spill, "home", homes)
	command(spill, "road", row(11, 3, 14))
	command(spill, "power", one(Vector2i(15, 11)))
	command(spill, "home", one(Vector2i(2, 11)))
	var near: int = net(spill, Vector2i(2, 5))
	var far: int = net(spill, Vector2i(3, 11))
	check(near != far and reason(spill, Vector2i(2, 11)) == "powered" and spill.power.home_network[spill.index(Vector2i(2, 11))] == far, "plot uses a farther network with room when the nearer one is full")
	check(spill.power.network_used[near] == 20 and spill.power.network_used[far] == 1 and spill.power.total_used == 21, "per-network and total accounting agree")
	command(spill, "clear", one(Vector2i(15, 11)))
	check(reason(spill, Vector2i(2, 11)) == "shortage" and spill.power.home_network[spill.index(Vector2i(2, 11))] == near and spill.power.network_short[near] == 1, "losing the spare network leaves the plot short on the full network")

	# Save continuation; derived power is reconstructed and never serialized.
	var decoded: Dictionary = Codec.decode(spill.canonical())
	check(decoded.ok and decoded.migrated_from == 0 and decoded.city.power.home_state == spill.power.home_state and decoded.city.power.network_used == spill.power.network_used, "reload reconstructs the power allocation")
	var keys: Array = spill.snapshot().keys()
	keys.sort()
	check(keys == ["cash", "content_version", "development", "height", "occupancy", "pending_us", "random_state", "schema_version", "seed", "sequence", "service_loss", "simulation_version", "terrain", "tick", "width"], "power and access are absent from saves")
	for item: City in [spill, decoded.city]:
		command(item, "power", one(Vector2i(15, 11)))
		Clock.advance(item, 2_000_000, 3)
	check(spill.canonical() == decoded.city.canonical() and spill.power.home_state == decoded.city.power.home_state and spill.rng.randi() == decoded.city.rng.randi(), "continued commands after reload match the uninterrupted city")
	states = spill.power.home_state.duplicate()
	snapshot = spill.canonical()
	spill.rebuild_derived()
	check(spill.canonical() == snapshot and spill.power.home_state == states, "derived rebuild leaves authoritative state and RNG unchanged")
	for i in range(20): Clock.advance(spill, 1_000_000, 3)
	check(spill.power.home_state == states and spill.tick > 0, "clock ticks never change power")

	# Bounded at the 128x128 ceiling: 64 road networks, eight sourced.
	var big := City.new()
	big.initialize(5, 128, 128)
	big.terrain.fill(City.LAND)
	big.rebuild_derived()
	big.cash = Balance.MAX_CASH
	var road_cells: Array[Vector2i] = []
	var home_cells: Array[Vector2i] = []
	for y in range(128):
		for x in range(1, 128):
			if y % 2 == 0: road_cells.append(Vector2i(x, y))
			else: home_cells.append(Vector2i(x, y))
	command(big, "road", road_cells)
	command(big, "home", home_cells)
	for y in range(0, 128, 16): command(big, "power", one(Vector2i(0, y)))
	var started: int = Time.get_ticks_usec()
	big.rebuild_derived()
	var elapsed: int = Time.get_ticks_usec() - started
	check(big.power.network_stations.size() == 64 and big.power.total_capacity == 160 and big.power.total_used == 160, "max map labels every network and caps supply")
	check(big.power.powered_homes == 160 and big.power.short_homes == 127 + 7 * 254 - 160, "max map shortage count is exact")
	big.occupancy.fill(City.ROAD)
	big.occupancy[0] = City.POWER
	big.rebuild_derived()
	check(big.power.network_stations.size() == 1 and big.power.distance[big.index(Vector2i(127, 127))] == 254, "full-map iterative search reaches the far corner")
	print("INFO power rebuild 128x128 striped city: %d us (local headless editor runtime; not a performance claim)" % elapsed)
	print("PASS group: power networks, capacity, nearest-first allocation")

func test_migration() -> void:
	check(FileAccess.get_sha256("res://tests/fixtures/m1-schema1.json") == "f954b5c782f32d240e54912baea00ac6960b599fe5aa90f4eed96efeceadbb83", "M1 fixture bytes preserved")
	check(FileAccess.get_sha256("res://tests/fixtures/m2a-schema1.json") == "a85895efbc23707538a8c97399a7cf9bd831bfeb21b8182144b68653d82f0c93", "M2a fixture bytes preserved")
	var legacy: String = FileAccess.get_file_as_string("res://tests/fixtures/m2a-schema1.json")
	var decoded: Dictionary = Codec.decode(legacy.strip_edges())
	check(decoded.ok and decoded.migrated_from == 1 and decoded.city.canonical() == migrated_text(legacy.strip_edges()), "M2a fixture migrates with version fields and zero growth arrays")
	var city: City = decoded.city
	check(city.access.root == Vector2i(9, 4) and city.access.connected_roads.count(1) == 6 and city.access.served_homes.count(1) == 4, "migrated M2a city derives the access recorded by unchanged M2a code")
	var expected: Dictionary = {Vector2i(2, 4): "no_adjacent_road", Vector2i(3, 2): "disconnected_road", Vector2i(4, 0): "disconnected_road",
		Vector2i(5, 4): "connected", Vector2i(7, 3): "connected", Vector2i(7, 5): "connected", Vector2i(8, 3): "connected"}
	var same: bool = true
	for cell: Vector2i in expected: same = same and city.access.home_reason(city, cell) == expected[cell]
	check(same, "migrated M2a home reasons match the unchanged M2a results")
	check(city.power.station_count == 0 and reason(city, Vector2i(7, 3)) == "no_source", "legacy city gains no fabricated power")
	var restored: City = Codec.decode(city.canonical()).city
	check(Codec.decode(city.canonical()).migrated_from == 0 and restored.canonical() == city.canonical(), "migrated city round-trips as schema 3")
	for item: City in [city, restored]:
		command(item, "power", one(Vector2i(7, 1)))
	check(reason(city, Vector2i(3, 2)) == "powered" and city.access.home_reason(city, Vector2i(3, 2)) == "disconnected_road" and reason(city, Vector2i(7, 3)) == "disconnected", "station powers the legacy isolated district while road access stays missing")
	for item: City in [city, restored]:
		command(item, "road", one(Vector2i(6, 2)))
		Clock.advance(item, 1_000_000, 1)
	check(reason(city, Vector2i(7, 3)) == "powered" and city.access.home_reason(city, Vector2i(3, 2)) == "connected" and city.cash == 971500 - Balance.POWER_COST - Balance.ROAD_COST, "rebuilt legacy bridge joins access and power")
	check(city.canonical() == restored.canonical() and city.power.home_state == restored.power.home_state and city.rng.randi() == restored.rng.randi(), "legacy continuation matches after a schema-3 reload")

	# Store-level migration: loading writes nothing; first save preserves the original bytes.
	var files := FaultFiles.new()
	var store := Store.new(files)
	var base: String = OS.get_environment("CITY_TEST_DIR")
	if base.is_empty(): base = "user://tests"
	var path: String = base.path_join("migration_%d/manual.json" % Time.get_ticks_usec())
	var preserved: String = Store.preserved_path(path, 1)
	files.write_text(path, legacy)
	var loaded: Dictionary = store.load_city(path)
	check(loaded.ok and loaded.migrated_from == 1 and FileAccess.get_file_as_string(path) == legacy and not files.exists(preserved), "loading an earlier save writes nothing")
	files.fault = "preserve_copy"
	check(not store.save_city(loaded.city, path).ok and FileAccess.get_file_as_string(path) == legacy and not files.exists(preserved), "failed preservation leaves the earlier save untouched")
	files.fault = ""
	check(store.save_city(loaded.city, path).ok and int(store.load_city(path).schema) == 3, "migrated city saves as schema 3")
	check(preserved.get_file() == "manual.schema1.json" and FileAccess.get_file_as_string(preserved) == legacy, "original earlier-format bytes kept beside the save")
	check(FileAccess.get_file_as_string(path + ".bak") == legacy, "previous-good backup holds the earlier save")
	command(loaded.city, "power", one(Vector2i(7, 1)))
	check(store.save_city(loaded.city, path).ok and FileAccess.get_file_as_string(preserved) == legacy and int(store.load_city(path + ".bak").schema) == 3, "later saves rotate schema 3 and never overwrite the preserved original")

	# Recovery from an earlier-format backup when the primary is corrupt.
	var recover_path: String = base.path_join("recover_%d/manual.json" % Time.get_ticks_usec())
	files.write_text(recover_path, "{corrupt")
	files.write_text(recover_path + ".bak", legacy)
	var from_backup: Dictionary = store.load_city(recover_path + ".bak")
	check(from_backup.ok and from_backup.migrated_from == 1, "earlier-format backup loads for recovery")
	check(store.save_city(from_backup.city, recover_path).ok and FileAccess.get_file_as_string(recover_path + ".bak") == legacy and not files.exists(Store.preserved_path(recover_path, 1)), "save over a corrupt primary leaves the earlier-format backup untouched")
	command(from_backup.city, "road", one(Vector2i(6, 2)))
	files.fault = "preserve_copy"
	check(not store.save_city(from_backup.city, recover_path).ok and FileAccess.get_file_as_string(recover_path + ".bak") == legacy, "failed preservation never rotates over an earlier-format backup")
	files.fault = ""
	check(store.save_city(from_backup.city, recover_path).ok and FileAccess.get_file_as_string(Store.preserved_path(recover_path, 1)) == legacy and int(store.load_city(recover_path + ".bak").schema) == 3, "earlier-format backup is preserved before rotation replaces it")

	# Unsupported or inconsistent saves are refused without changing their files.
	var future: Dictionary = loaded.city.snapshot()
	future.schema_version = 4
	var future_path: String = path.get_base_dir().path_join("future.json")
	files.write_text(future_path, JSON.stringify(future))
	var future_text: String = FileAccess.get_file_as_string(future_path)
	var refused: Dictionary = store.load_city(future_path)
	check(not refused.ok and String(refused.message).contains("newer version") and FileAccess.get_file_as_string(future_path) == future_text, "newer schema refused clearly without changing the file")
	var mismatched: Dictionary = loaded.city.snapshot()
	mismatched.simulation_version = "m1-1"
	mismatched.content_version = "m1-1"
	check(not Codec.decode(JSON.stringify(mismatched)).ok, "schema 2 with schema-1 version strings refused")
	# Current-format sample for a future migration: exact schema-2 round trip with a station.
	check(FileAccess.get_sha256("res://tests/fixtures/m2b-schema2.json") == "27dbbaefca8ec3e1419d61b0e278c855cd8392c81d76b553128cf9c4c2b8c37a", "M2b schema-2 fixture bytes preserved")
	var current_text: String = FileAccess.get_file_as_string("res://tests/fixtures/m2b-schema2.json").strip_edges()
	var current: Dictionary = Codec.decode(current_text)
	check(current.ok and current.migrated_from == 2 and current.city.canonical() == migrated_text(current_text), "M2b fixture migrates preserving all earlier fields")
	if current.ok:
		var sample: City = current.city
		check(sample.power.station_count == 1 and sample.power.total_used == 4 and sample.power.short_homes == 0, "M2b fixture derives its recorded supply")
		check(reason(sample, Vector2i(8, 1)) == "powered" and sample.access.home_reason(sample, Vector2i(8, 1)) == "no_adjacent_road" and reason(sample, Vector2i(7, 3)) == "disconnected" and sample.access.home_reason(sample, Vector2i(7, 3)) == "connected", "M2b fixture keeps power and road access independent")
	print("PASS group: schema-1 migration and preserved originals")
