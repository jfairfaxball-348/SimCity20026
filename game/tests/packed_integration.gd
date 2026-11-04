extends SceneTree
## External driver against the release PCK under the pinned editor runtime.
## Standard release templates disable --script. Actual EXE UI checks are separate.
const Store = preload("res://scripts/persistence/save_store.gd")
const City = preload("res://scripts/sim/city_state.gd")
const FileOps = preload("res://scripts/persistence/file_ops.gd")
var main: Control
var checks: int = 0
var failures: Array[String] = []

class IsolatedStore extends Store:
	var test_path: String
	func _init(path: String) -> void:
		super()
		test_path = path
	func save_city(city: City, _path: String) -> Dictionary:
		return super.save_city(city,test_path)
	func load_city(path: String) -> Dictionary:
		var actual: String = test_path + path.trim_prefix("user://saves/manual.json") if path.begins_with("user://saves/manual.json") else path
		return super.load_city(actual)

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("FAIL: ",label)

func frames(count: int = 3) -> void:
	for i in range(count): await process_frame

func click(point: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = point
	Input.parse_input_event(move)
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		Input.parse_input_event(event)
		await frames()

func key(code: Key, ctrl: bool = false) -> void:
	for down in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		# Exercise logical-only accessibility input as well as core physical tests.
		event.physical_keycode = 0
		event.ctrl_pressed = ctrl
		event.pressed = down
		Input.parse_input_event(event)
		await frames()

func drag_cells(from: Vector2i, to: Vector2i) -> void:
	var down := InputEventMouseButton.new()
	down.position = screen_cell(from)
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	Input.parse_input_event(down)
	await frames()
	var motion := InputEventMouseMotion.new()
	motion.position = screen_cell(to)
	Input.parse_input_event(motion)
	await frames()
	var up: InputEventMouseButton = down.duplicate()
	up.position = screen_cell(to)
	up.pressed = false
	Input.parse_input_event(up)
	await frames()

func screen_cell(cell: Vector2i) -> Vector2:
	return main.world_rect.position + main.world.tile_rect(cell).get_center() * main.world_scale

func screen_tile(cell: Vector2i) -> Rect2:
	var rect: Rect2 = main.world.tile_rect(cell)
	return Rect2(main.world_rect.position + rect.position * main.world_scale, rect.size * main.world_scale)

const LONGEST_ACCESS: String = "No road beside this plot. Add a road along a shared side, then connect it to the outside link."
const LONGEST_POWER: String = "No power: its network is full (20 of 20 units). Add a station; nearest plots are served first."
const REJECTIONS: Array[String] = ["Not enough funds for the whole stroke.", "Clear the existing road, zone, or station first.", "Keep the outside-link flag free for its road."]

func run() -> void:
	check(not FileAccess.file_exists("res://project.godot"), "driver loads exported pack, not source project")
	check(not FileAccess.file_exists("res://tests/run_tests.gd") and not ResourceLoader.exists("res://tests/run_tests.gd"), "test runner excluded from release package")
	check(not FileAccess.file_exists("res://tests/fixtures/m1-schema1.json"), "legacy fixture excluded from release package")
	var isolated := IsolatedStore.new("user://tests/export_%d/manual.json" % Time.get_ticks_usec())
	root.size = Vector2i(1280,720)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.store = isolated
	await frames()
	check(main.inspector.position.y >= main.top.get_global_rect().end.y and main.inspector.get_global_rect().end.y < main.bottom.position.y, "first-frame inspector fits without prior resize")
	check(main._is_world_position(screen_cell(main.city.access.root)), "first-frame outside link is visible and pickable")
	main.set_process(false)
	for resolution in main.SIZES:
		root.size = resolution
		await frames()
		main._layout_ui()
		await frames()
		check(main.world_scale == floori(minf(float(resolution.x)/640,float(resolution.y)/360)), "integer world scale %s" % resolution)
		for amount in [16,18,20]:
			main._set_text_size(amount)
			main._center_camera()
			await frames()
			var link: Rect2 = screen_tile(main.city.access.root)
			check(main._is_world_position(link.get_center()) and not main.inspector.get_global_rect().intersects(link) and not main.side.get_global_rect().intersects(link), "centred outside link uncovered by panels %s text %d" % [resolution,amount])
			main.grid_label.text = "Power 100 / 120\n10 plots short"
			for message in REJECTIONS:
				main.preview_label.text = message
				await frames()
				check(main.side.get_global_rect().end.y <= main.bottom.position.y, "sidebar with rejection '%s' above footer %s text %d" % [message,resolution,amount])
				var bottom_child: Control = main.side.get_child(0).get_child(main.side.get_child(0).get_child_count()-1)
				check(bottom_child.get_global_rect().end.y <= main.side.get_global_rect().end.y, "all sidebar controls visible with '%s' %s text %d" % [message,resolution,amount])
			check(main.top.get_global_rect().end.x <= resolution.x, "toolbar with power total fits %s text %d" % [resolution,amount])
			var marks: Control = main.access_button.get_parent()
			check(main.access_button.get_global_rect().end.x <= marks.get_global_rect().end.x + 0.5 and main.power_button.get_global_rect().end.x <= main.side.get_global_rect().end.x, "both mark toggles fit the sidebar %s text %d" % [resolution,amount])
			check(main.bottom.get_global_rect().end.y <= resolution.y, "footer fits %s text %d" % [resolution,amount])
			check(main.inspector.position.y >= main.top.get_global_rect().end.y, "inspector below toolbar %s text %d" % [resolution,amount])
			for cell in [Vector2i(63,32),Vector2i(42,28)]:
				main._inspect_cell(cell)
				# Exercise the longest home reasons in every layout, without placing a city.
				main.access_label.text = LONGEST_ACCESS
				main.power_label.text = LONGEST_POWER
				await frames()
				check(main.scope_label.get_global_rect().end.y <= main.inspector.get_global_rect().end.y and main.inspector.get_global_rect().end.y < main.bottom.position.y, "inspector text fits %s text %d cell %s" % [resolution,amount,cell])
				check(main.power_label.get_global_rect().end.y <= main.legend_label.get_global_rect().position.y and main.inspector.size.y <= 320.5, "power reason does not overlap marks legend %s text %d cell %s" % [resolution,amount,cell])
		main._set_text_size(16)
		main._center_camera()
		var point: Vector2 = screen_cell(Vector2i(42,28))
		check(main._is_world_position(point), "world picking target visible %s" % resolution)
		check(main.world.cell_at(main._view_position(point)) == Vector2i(42,28), "screen to cell transform %s" % resolution)
	root.size = Vector2i(1280,720)
	main._set_text_size(16)
	main._center_camera()
	main.set_process(true)
	await frames()
	check(main._is_world_position(screen_cell(main.city.access.root)), "outside link visible and pickable at startup")
	check(not main._is_world_position(main.inspector.get_global_rect().get_center()), "inspector blocks painting through UI")
	var before: String = main.city.canonical()
	await click(main.tool_buttons.home.get_global_rect().get_center())
	check(main.tool == "home" and main.city.canonical() == before, "toolbar click selects tool without painting")
	await click(screen_cell(Vector2i(42,28)))
	check(main.city.occupancy[main.city.index(Vector2i(42,28))] == City.HOME, "pointer click builds selected cell")
	check(main.city.cash == 997500, "pointer click exact price")
	check("Release to build" not in main.preview_label.text, "completed stroke clears preview instructions")
	await click(screen_cell(Vector2i(42,28)))
	check(main.city.cash == 997500, "repeat click free")
	await key(KEY_1)
	before = main.city.canonical()
	await click(screen_cell(Vector2i(42,28)))
	check(main.city.canonical() == before, "conflicting UI placement rejected")
	await key(KEY_3)
	await click(screen_cell(Vector2i(42,28)))
	check(main.city.occupancy[main.city.index(Vector2i(42,28))] == City.EMPTY and main.city.cash == 997500, "keyboard tool and pointer demolition")
	# UI-focus regression: Space must pause/play, not activate the focused tool.
	await click(main.tool_buttons.road.get_global_rect().get_center())
	await key(KEY_SPACE)
	check(main.speed == 1, "Space works after clicking a tool")
	await key(KEY_SPACE)
	check(main.speed == 0, "Space pauses after clicking a tool")
	await key(KEY_5)
	check(main.speed == 3, "fast speed shortcut")
	await key(KEY_SPACE)
	check(main.speed == 0, "pause from fast speed")
	await key(KEY_EQUAL)
	check(main.world.zoom == 2, "keyboard zoom")
	await key(KEY_HOME)
	check(main.world.zoom == 1 and main.world.origin == Vector2(400,380), "center/reset view")
	var origin_before: Vector2 = main.world.origin
	for down_now in [true,false]:
		var tap := InputEventKey.new()
		tap.keycode = KEY_LEFT
		tap.pressed = down_now
		Input.parse_input_event(tap)
	await frames()
	check(main.world.origin.x < origin_before.x, "camera responds to a tap shorter than one frame")
	await key(KEY_HOME)
	origin_before = main.world.origin
	await key(KEY_S,true)
	check(main.world.origin == origin_before, "save shortcut does not move camera")
	# Releasing a real input stroke over UI must cancel without charge.
	before = main.city.canonical()
	var down := InputEventMouseButton.new()
	down.position = screen_cell(Vector2i(43,28))
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	Input.parse_input_event(down)
	await frames()
	check(not main.stroke.is_empty(), "pointer down opens a preview stroke")
	var up: InputEventMouseButton = down.duplicate()
	up.position = main.side.get_global_rect().get_center()
	up.pressed = false
	Input.parse_input_event(up)
	await frames()
	check(main.stroke.is_empty() and main.city.canonical() == before, "release over UI cancels whole stroke")
	# M2a: use shipped input and scene for a visible connection/break/reconnection.
	await key(KEY_2)
	await click(screen_cell(Vector2i(59,31)))
	main._inspect_cell(Vector2i(59,31))
	check("No road beside" in main.access_label.text and "Growth not implemented" in main.scope_label.text, "empty zone explains missing road and absent growth")
	check("No power station yet" in main.power_label.text and main.grid_label.text.begins_with("Power 0 / 0"), "empty zone explains the missing power source")
	await key(KEY_1)
	await drag_cells(Vector2i(59,32),Vector2i(61,32))
	main._inspect_cell(Vector2i(59,31))
	check("must connect to the outside link" in main.access_label.text and main.city.access.served_homes.count(1) == 0, "isolated district explanation in shipped UI")
	await drag_cells(Vector2i(61,32),Vector2i(63,32))
	main._inspect_cell(Vector2i(59,31))
	check("Road access connected" in main.access_label.text and main.city.access.served_homes.count(1) == 1, "connecting root immediately updates home access")
	await key(KEY_3)
	await click(screen_cell(Vector2i(61,32)))
	main._inspect_cell(Vector2i(59,31))
	check("No road access" in main.access_label.text and main.city.access.served_homes.count(1) == 0, "demolishing bridge immediately explains service loss")
	await key(KEY_1)
	await click(screen_cell(Vector2i(61,32)))
	check(main.city.access.served_homes.count(1) == 1, "rebuilding bridge restores service")
	# M2b: shipped controls for supply, shortage, disconnection, and recovery.
	# Cells stay west of the 720p inspector so pointer strokes land on the map.
	var cash_before: int = main.city.cash
	await key(KEY_P)
	check(main.tool == "power" and main.tool_buttons.power.button_pressed, "P selects the power station tool")
	await drag_cells(Vector2i(39,32),Vector2i(39,33))
	check(main.city.power.station_count == 1 and main.city.occupancy[main.city.index(Vector2i(39,33))] == City.POWER and main.city.cash == cash_before - 50000, "dragging the power tool places exactly one paid station")
	await key(KEY_3)
	await click(screen_cell(Vector2i(39,33)))
	await key(KEY_P)
	await click(screen_cell(Vector2i(39,32)))
	check(main.city.power.station_count == 1 and main.city.occupancy[main.city.index(Vector2i(39,32))] == City.POWER and main.city.cash == cash_before - 100000, "clear has no refund; one click places a station")
	main._inspect_cell(Vector2i(59,31))
	check("road beside this plot does not reach" in main.power_label.text and "Road access connected" in main.access_label.text, "plot with road access explains its separate missing power")
	await key(KEY_1)
	await drag_cells(Vector2i(40,32),Vector2i(58,32))
	main._inspect_cell(Vector2i(59,31))
	check("Powered" in main.power_label.text and "Road access connected" in main.access_label.text and main.grid_label.text.begins_with("Power 1 / 20"), "connected plot reports road access and power separately")
	await key(KEY_2)
	await drag_cells(Vector2i(40,31),Vector2i(58,31))
	await drag_cells(Vector2i(40,33),Vector2i(50,33))
	check(main.city.power.powered_homes == 20 and main.city.power.short_homes == 11 and "11 plots short" in main.grid_label.text, "eleven-plot shortage shown in the toolbar")
	main._inspect_cell(Vector2i(59,31))
	check("network is full" in main.power_label.text and "20 of 20" in main.power_label.text and "Road access connected" in main.access_label.text, "farthest plot explains the capacity shortage")
	main._inspect_cell(Vector2i(50,33))
	check("network is full" in main.power_label.text, "equal-distance tie beyond capacity is short")
	main._inspect_cell(Vector2i(49,33))
	check("Powered" in main.power_label.text and "11 plots short" in main.power_label.text, "nearer plot keeps power and reports the network shortage")
	await key(KEY_3)
	await click(screen_cell(Vector2i(45,32)))
	main._inspect_cell(Vector2i(50,31))
	check("does not reach a power station" in main.power_label.text and main.city.power.short_homes == 0 and "No shortage" in main.grid_label.text, "removing a bridge disconnects far plots and ends the shortage")
	main._inspect_cell(Vector2i(45,31))
	check("add a road beside this plot" in main.power_label.text, "plot beside the removed road explains it needs a road")
	await key(KEY_1)
	await click(screen_cell(Vector2i(45,32)))
	check(main.city.power.short_homes == 11, "reconnecting the bridge restores the shortage")
	await key(KEY_P)
	await click(screen_cell(Vector2i(63,31)))
	main._inspect_cell(Vector2i(59,31))
	check(main.city.power.short_homes == 0 and main.city.power.powered_homes == 31 and "Powered" in main.power_label.text and main.grid_label.text.begins_with("Power 31 / 40"), "second station on the same network recovers every plot")
	main._inspect_cell(Vector2i(63,31))
	check("2 stations" in main.power_label.text and "Power works without the outside link" in main.access_label.text, "station inspector reports network capacity")
	await key(KEY_E)
	check(not main.world.power_visible and not main.power_button.button_pressed and "power marks hidden" in main.legend_label.text, "power marks keyboard toggle")
	await click(main.power_button.get_global_rect().get_center())
	check(main.world.power_visible and main.power_button.button_pressed, "power marks sidebar toggle")
	await key(KEY_1)
	await key(KEY_R)
	check(not main.world.access_visible and not main.access_button.button_pressed, "access overlay keyboard toggle")
	await click(main.access_button.get_global_rect().get_center())
	check(main.world.access_visible, "access overlay toolbar toggle")
	await click(screen_cell(Vector2i(43,28)))
	await key(KEY_S,true)
	var saved: String = main.city.canonical()
	check(isolated.load_city(main.SAVE_PATH).ok and not main.dirty, "Ctrl+S persists through actual scene/storage")
	main.queue_free()
	await frames()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.store = isolated
	await frames()
	await key(KEY_L,true)
	check(main.city.canonical() == saved, "new scene restores saved state through Ctrl+L")
	main._inspect_cell(Vector2i(59,31))
	check(main.city.access.served_homes.count(1) == 31 and "Road access connected" in main.access_label.text, "restart/load reconstructs home access and explanation")
	check(main.city.power.station_count == 2 and main.city.power.powered_homes == 31 and "Powered" in main.power_label.text and main.grid_label.text.begins_with("Power 31 / 40"), "restart/load reconstructs power allocation and explanation")
	check(main.speed == 0, "loaded city starts paused")
	var files := FileOps.new()
	files.write_text(isolated.test_path, "{truncated")
	before = main.city.canonical()
	await key(KEY_L,true)
	check(main.city.canonical() == before, "corrupt UI load preserves current city")
	check("Current city unchanged" in main.status_label.text, "corrupt UI load explains outcome")
	check(main.recovery_dialog.visible, "corrupt UI load offers the previous valid backup")
	main.recovery_dialog.hide()
	await frames()
	# Earlier-format save through the shipped UI: load migrates in memory, save keeps the original.
	var fixture_path: String = (get_script() as Script).resource_path.get_base_dir().path_join("fixtures/m2a-schema1.json")
	var legacy: String = FileAccess.get_file_as_string(fixture_path)
	check(not legacy.is_empty(), "M2a fixture readable from the source tree by the external driver")
	files.write_text(isolated.test_path, legacy)
	await key(KEY_L,true)
	check(main.city.sequence == 7 and main.city.width == 10 and main.city.access.served_homes.count(1) == 4 and "Earlier save format 1" in main.status_label.text and "manual.schema1.json" in main.status_label.text, "UI load migrates an M2a save and explains it")
	check(FileAccess.get_file_as_string(isolated.test_path) == legacy, "UI load leaves the earlier save file unchanged")
	await key(KEY_S,true)
	var preserved: String = isolated.test_path.get_base_dir().path_join("manual.schema1.json")
	check(FileAccess.get_file_as_string(preserved) == legacy and int(isolated.load_city(main.SAVE_PATH).get("schema", 0)) == 2, "UI save writes schema 2 and preserves the original bytes")
	var metadata: Dictionary = {"suite":"packed-integration", "engine":Engine.get_version_info().string,
		"runtime":"editor_with_release_pck","checks":checks,"failed":failures.size(),"failures":failures,
		"display_backend":DisplayServer.get_name(),"screen_dpi":DisplayServer.screen_get_dpi()}
	print(JSON.stringify(metadata))
	main.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)
