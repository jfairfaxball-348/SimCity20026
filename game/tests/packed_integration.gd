extends SceneTree
## External driver against the release PCK under the pinned editor runtime.
## Standard release templates disable --script. Actual EXE UI checks are separate.
const Store = preload("res://scripts/persistence/save_store.gd")
const City = preload("res://scripts/sim/city_state.gd")
const FileOps = preload("res://scripts/persistence/file_ops.gd")
const Clock = preload("res://scripts/sim/simulation_clock.gd")
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

## Moves the camera so pointer targets otherwise under the inspector or toolbar are clickable.
func view_from(origin: Vector2) -> void:
	main.world.origin = origin
	main.world.clamp_camera()
	main.world.queue_redraw()
	await frames()

func lots_row(y: int, x0: int, count: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for k in range(count): out.append(Vector2i(x0 + 3 * k, y))
	return out

const LONGEST_ACCESS: String = "No road beside this lot. Add one and join it to the outside link."
const LONGEST_POWER: String = "No power: network full (20/20). Add a plant; nearest lots get power first."
const REJECTIONS: Array[String] = ["Not enough funds for the whole stroke.", "Clear the existing road, zone, or power plant first.", "Keep the outside-link flag free for its road.", "Keep the whole power plant inside the map."]

func run() -> void:
	check(not FileAccess.file_exists("res://project.godot"), "driver loads exported pack, not source project")
	check(not FileAccess.file_exists("res://tests/run_tests.gd") and not ResourceLoader.exists("res://tests/run_tests.gd"), "test runner excluded from release package")
	check(not FileAccess.file_exists("res://tests/fixtures/m1-schema1.json") and not FileAccess.file_exists("res://tests/fixtures/m2e-schema6.json"), "fixtures excluded from release package")
	var isolated := IsolatedStore.new("user://tests/export_%d/manual.json" % Time.get_ticks_usec())
	root.size = Vector2i(1280,720)
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.store = isolated
	await frames()
	check(main.inspector.position.y >= main.top.get_global_rect().end.y and main.inspector.get_global_rect().end.y < main.bottom.position.y, "first-frame inspector fits without prior resize")
	check(main._is_world_position(screen_cell(main.city.access.root)), "first-frame outside link is visible and pickable")
	check("3x3 residential lots" in main.status_label.text and "4x4 power plant" in main.status_label.text, "start-up guidance names lot and station sizes")
	check(main.guide_panel.visible and main.guide_state.step == 1 and "1 OF 5" in main.guide_heading.text and main.world.guide_target == main.city.access.root and main.speed == 0 and not main.dirty, "start-up shows the First steps card at step 1, paused and clean")
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
			main.grid_label.text = "Power 100 / 120\n10 lots short"
			main.population_label.text = "Residents 131072 · Jobs 131072"
			main.demand_label.text = "Tax 25% · Net −$99999.00 · DEFICIT"
			main.demand_meter.set_values([32768, -8192, -8192])
			for message in REJECTIONS:
				main.preview_label.text = message
				await frames()
				check(main.side.get_global_rect().end.y <= main.bottom.position.y, "sidebar with rejection '%s' above footer %s text %d" % [message,resolution,amount])
				var bottom_child: Control = main.side.get_child(0).get_child(main.side.get_child(0).get_child_count()-1)
				check(bottom_child.get_global_rect().end.y <= main.side.get_global_rect().end.y, "all sidebar controls visible with '%s' %s text %d" % [message,resolution,amount])
			main.preview_label.text = "3 lots: $75.00\nRelease to build"
			await frames()
			check(main.side.get_global_rect().end.y <= main.bottom.position.y, "sidebar with a lot-run price above footer %s text %d" % [resolution,amount])
			check(main.top.get_global_rect().end.x <= resolution.x, "toolbar with power total fits %s text %d" % [resolution,amount])
			check(main.top.get_global_rect().encloses(main.demand_meter.get_global_rect()) and main.demand_meter.size.x >= main.demand_meter.get_combined_minimum_size().x, "demand meter fits inside the toolbar unclipped %s text %d" % [resolution,amount])
			check(main.top.get_global_rect().end.y <= main.side.position.y, "toolbar does not overlap sidebar %s text %d" % [resolution,amount])
			var marks: Control = main.access_button.get_parent()
			check(main.access_button.get_global_rect().end.x <= marks.get_global_rect().end.x + 0.5 and main.power_button.get_global_rect().end.x <= main.side.get_global_rect().end.x, "both mark toggles fit the sidebar %s text %d" % [resolution,amount])
			check(main.bottom.get_global_rect().end.y <= resolution.y, "footer fits %s text %d" % [resolution,amount])
			check(main.inspector.position.y >= main.top.get_global_rect().end.y, "inspector below toolbar %s text %d" % [resolution,amount])
			main._set_guide_visible(true)
			await frames()
			var card: Rect2 = main.guide_panel.get_global_rect()
			var link_tile: Rect2 = screen_tile(main.city.access.root)
			var clear_of: bool = not card.intersects(main.top.get_global_rect()) and not card.intersects(main.side.get_global_rect()) and not card.intersects(main.inspector.get_global_rect()) and not card.intersects(main.bottom.get_global_rect())
			check(Rect2(Vector2.ZERO, Vector2(resolution)).encloses(card) and clear_of and not card.intersects(link_tile), "First steps card is inside the window, clear of every panel and the link %s text %d" % [resolution, amount])
			check(main.guide_text.get_global_rect().end.y <= card.end.y + 0.5 and main.guide_hide.get_global_rect().end.y <= card.end.y + 0.5 and main.guide_hide.get_global_rect().end.x <= card.end.x + 0.5, "card text and buttons fit inside the card %s text %d" % [resolution, amount])
			main._show_cell(main.city.access.root)
			await frames()
			var target: Rect2 = screen_tile(main.city.access.root)
			var covered: bool = false
			for panel in main.ui_panels:
				if panel.visible and panel.get_global_rect().intersects(target.grow(-1)): covered = true
			check(main.world_rect.encloses(target) and not covered, "Show target is in the world view and uncovered %s text %d" % [resolution, amount])
			main._center_camera()
			main._set_guide_visible(false)
			for cell in [Vector2i(63,32),Vector2i(42,28)]:
				main._inspect_cell(cell)
				# Exercise the longest lot reasons in every layout, without placing a city.
				main.access_label.text = LONGEST_ACCESS
				main.power_label.text = LONGEST_POWER
				main.selection_label.text = "TILE 127, 127 · Residential lot L2 · 8 residents"
				main.scope_label.text = "Demand −32768 (taxes) · next check 30 Dec 2779727\nLoses a level in 2 check(s) unless services return."
				main.legend_label.text = "Land value −1: park +2, water +1, trade +2, industry −6"
				await frames()
				check(main.scope_label.get_global_rect().end.y <= main.inspector.get_global_rect().end.y and main.inspector.get_global_rect().end.y < main.bottom.position.y, "inspector text fits %s text %d cell %s (inspector %s, lines sel %d acc %d pow %d leg %d scope %d)" % [resolution,amount,cell,main.inspector.get_global_rect(),main.selection_label.get_line_count(),main.access_label.get_line_count(),main.power_label.get_line_count(),main.legend_label.get_line_count(),main.scope_label.get_line_count()])
				check(main.power_label.get_global_rect().end.y <= main.legend_label.get_global_rect().position.y and main.inspector.size.y <= 320.5, "power reason does not overlap marks legend %s text %d cell %s" % [resolution,amount,cell])
			# The longest migration message must fit the status bar.
			main._status("Earlier format 5 loaded; 16384 old single-tile zone/power tiles cleared for 3x3 lots and 4x4 power plants, tax rate set to the standard 10%. Nothing written; saving keeps the original as manual.schema5.json.")
			await frames()
			check(main.status_label.get_global_rect().end.y <= main.bottom.get_global_rect().end.y + 0.5 and main.bottom.get_global_rect().end.y <= resolution.y, "longest migration status fits the footer %s text %d" % [resolution,amount])
			main._open_help()
			await frames()
			check(main.help_dialog.size.y <= resolution.y and main.help_dialog.get_ok_button().get_global_rect().end.y <= resolution.y, "growth help and OK fit %s text %d" % [resolution,amount])
			main.help_dialog.hide()
			main._open_budget()
			await frames()
			check(main.budget_dialog.size.y <= resolution.y and main.budget_dialog.get_ok_button().get_global_rect().end.y <= resolution.y, "budget scroll area and OK fit %s text %d" % [resolution,amount])
			check(main._modal_open(), "budget suspends simulation %s text %d" % [resolution,amount])
			main.budget_dialog.hide()
			check(main.bottom.get_global_rect().encloses(main.summary_button.get_global_rect()), "town summary button fits the status bar %s text %d" % [resolution, amount])
			main._open_summary()
			await frames()
			check(main.summary_dialog.size.y <= resolution.y and main.summary_dialog.get_ok_button().get_global_rect().end.y <= resolution.y and main._modal_open(), "town summary dialog fits and suspends time %s text %d" % [resolution, amount])
			main.summary_dialog.hide()
			main._open_project()
			await frames()
			check(main.project_dialog.size.y <= resolution.y and main.project_dialog.get_ok_button().get_global_rect().end.y <= resolution.y and main.project_text.get_minimum_size().x < 650, "project dialog fits %s text %d" % [resolution, amount])
			check(main._modal_open() and main.project_complete.disabled, "empty project is modal and cannot complete %s text %d" % [resolution, amount])
			main.project_dialog.hide()
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
	var press := InputEventMouseButton.new()
	press.position = screen_cell(Vector2i(42,28))
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	Input.parse_input_event(press)
	await frames()
	check(main.world.preview_cells.size() == 9 and main.world.preview_cells.has(Vector2i(41,27)) and main.world.preview_cells.has(Vector2i(43,29)) and "1 lot" in main.preview_label.text, "pressing the home tool previews the whole 3x3 lot around the pointer and its price")
	var release: InputEventMouseButton = press.duplicate()
	release.pressed = false
	Input.parse_input_event(release)
	await frames()
	check(main.city.occupancy[main.city.index(Vector2i(42,28))] == City.HOME and main.city.anchor_at(Vector2i(42,28)) == main.city.index(Vector2i(41,27)), "pointer click builds a lot centred on the clicked tile")
	check(main.city.cash == 997500 and main.city.occupancy.count(City.HOME) == 9, "pointer click charges one lot price for nine tiles")
	check("Release to build" not in main.preview_label.text, "completed stroke clears preview instructions")
	await click(screen_cell(Vector2i(42,28)))
	check(main.city.cash == 997500, "repeat click free")
	await key(KEY_1)
	before = main.city.canonical()
	await click(screen_cell(Vector2i(43,29)))
	check(main.city.canonical() == before, "road on a lot tile rejected")
	await key(KEY_3)
	await click(screen_cell(Vector2i(43,29)))
	check(main.city.occupancy.count(City.HOME) == 0 and main.city.lot_anchors.is_empty() and main.city.cash == 997500, "keyboard clear on a corner tile demolishes the whole lot")
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
	await click(screen_cell(Vector2i(58,30)))
	main._inspect_cell(Vector2i(58,30))
	check("No road beside" in main.access_label.text and "Waiting for road access and power" in main.scope_label.text and "Residential lot L0" in main.selection_label.text, "empty lot explains missing road and waiting growth")
	check("No power plant yet" in main.power_label.text and main.grid_label.text.begins_with("Power 0 / 0"), "empty lot explains the missing power source")
	await key(KEY_1)
	await drag_cells(Vector2i(59,32),Vector2i(61,32))
	main._inspect_cell(Vector2i(57,31))
	check("Join this street to the outside link" in main.access_label.text and main.city.access.served_homes.count(1) == 0, "isolated district explanation from a corner tile of the lot")
	await drag_cells(Vector2i(61,32),Vector2i(63,32))
	main._inspect_cell(Vector2i(58,30))
	check("Road access connected" in main.access_label.text and main.city.access.served_homes.count(1) == 1, "connecting root immediately updates lot access")
	await key(KEY_3)
	await click(screen_cell(Vector2i(61,32)))
	main._inspect_cell(Vector2i(58,30))
	check("No road access" in main.access_label.text and main.city.access.served_homes.count(1) == 0, "demolishing bridge immediately explains service loss")
	await key(KEY_1)
	await click(screen_cell(Vector2i(61,32)))
	check(main.city.access.served_homes.count(1) == 1, "rebuilding bridge restores service")
	# M2b with 4x4 stations: supply, shortage, disconnection, and recovery through shipped controls.
	var cash_before: int = main.city.cash
	await key(KEY_P)
	check(main.tool == "power" and main.tool_buttons.power.button_pressed, "P selects the power station tool")
	await drag_cells(Vector2i(39,33),Vector2i(39,32))
	check(main.city.power.station_count == 1 and main.city.station_anchors == PackedInt32Array([main.city.index(Vector2i(38,31))]) and main.city.occupancy.count(City.POWER) == 16 and main.city.cash == cash_before - 50000, "dragging the power tool places exactly one paid 4x4 station at the release point")
	await key(KEY_3)
	await click(screen_cell(Vector2i(41,34)))
	check(main.city.occupancy.count(City.POWER) == 0, "clearing a station corner tile removes the whole station")
	await key(KEY_P)
	await click(screen_cell(Vector2i(39,32)))
	check(main.city.power.station_count == 1 and main.city.occupancy[main.city.index(Vector2i(38,31))] == City.POWER and main.city.cash == cash_before - 100000, "clear has no refund; one click places a station")
	main._inspect_cell(Vector2i(58,30))
	check("road beside this lot does not reach" in main.power_label.text and "Road access connected" in main.access_label.text, "lot with road access explains its separate missing power")
	await key(KEY_1)
	await drag_cells(Vector2i(42,32),Vector2i(58,32))
	main._inspect_cell(Vector2i(58,30))
	check("Powered" in main.power_label.text and "Road access connected" in main.access_label.text and main.grid_label.text.begins_with("Power 1 / 20"), "connected lot reports road access and power separately")
	await key(KEY_2)
	await drag_cells(Vector2i(43,30),Vector2i(61,30))
	check(main.city.lot_anchors.size() == 7, "one drag lays a row of seven lots, skipping the identical existing lot")
	await drag_cells(Vector2i(43,34),Vector2i(52,34))
	await key(KEY_1)
	await drag_cells(Vector2i(37,27),Vector2i(37,41))
	await drag_cells(Vector2i(38,38),Vector2i(52,38))
	await key(KEY_2)
	await drag_cells(Vector2i(35,28),Vector2i(35,40))
	check(main.city.lot_anchors.size() == 16, "a vertical drag lays a column of lots")
	await drag_cells(Vector2i(39,40),Vector2i(51,40))
	await click(screen_cell(Vector2i(39,29)))
	await click(screen_cell(Vector2i(39,36)))
	check(main.city.lot_anchors.size() == 23 and main.city.power.powered_homes == 20 and main.city.power.short_homes == 3 and "3 lots short" in main.grid_label.text, "three-lot shortage shown in the toolbar")
	main._inspect_cell(Vector2i(58,30))
	check("network full" in main.power_label.text and "20/20" in main.power_label.text and "Road access connected" in main.access_label.text, "a far lot explains the capacity shortage")
	main._inspect_cell(Vector2i(51,40))
	check("network full" in main.power_label.text, "the farthest lot beyond capacity is short")
	main._inspect_cell(Vector2i(48,40))
	check("Powered" in main.power_label.text and "3 lots short" in main.power_label.text, "nearer lot keeps power and reports the network shortage")
	await key(KEY_3)
	await click(screen_cell(Vector2i(45,32)))
	main._inspect_cell(Vector2i(49,30))
	check("does not reach a power plant" in main.power_label.text and main.city.power.short_homes == 0 and "No shortage" in main.grid_label.text, "removing a bridge disconnects far lots and ends the shortage")
	await key(KEY_1)
	await click(screen_cell(Vector2i(45,32)))
	check(main.city.power.short_homes == 3, "reconnecting the bridge restores the shortage")
	await view_from(Vector2(400,420))
	await key(KEY_P)
	await click(screen_cell(Vector2i(55,34)))
	await key(KEY_HOME)
	main._inspect_cell(Vector2i(58,30))
	check(main.city.power.short_homes == 0 and main.city.power.powered_homes == 23 and "Powered" in main.power_label.text and main.grid_label.text.begins_with("Power 23 / 40"), "second station on the same network recovers every lot")
	main._inspect_cell(Vector2i(55,34))
	check("2 plants" in main.power_label.text and "Power works without the outside link" in main.access_label.text, "station inspector reports network capacity from any tile")
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
	main._inspect_cell(Vector2i(58,30))
	check(main.city.access.served_homes.count(1) == 11 and "Road access connected" in main.access_label.text, "restart/load reconstructs lot access and explanation")
	check(main.city.power.station_count == 2 and main.city.power.powered_homes == 23 and "Powered" in main.power_label.text and main.grid_label.text.begins_with("Power 23 / 40"), "restart/load reconstructs power allocation and explanation")
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
	check(main.city.sequence == 7 and main.city.width == 10 and main.city.access.served_homes.count(1) == 0 and main.city.occupancy.count(City.HOME) == 0, "UI load migrates an M2a save and clears its single-tile homes")
	check("Earlier format 1" in main.status_label.text and "7 old single-tile" in main.status_label.text and "manual.schema1.json" in main.status_label.text, "UI migration message explains cleared tiles and the preserved original")
	check(FileAccess.get_file_as_string(isolated.test_path) == legacy, "UI load leaves the earlier save file unchanged")
	await key(KEY_S,true)
	var preserved: String = isolated.test_path.get_base_dir().path_join("manual.schema1.json")
	check(FileAccess.get_file_as_string(preserved) == legacy and int(isolated.load_city(main.SAVE_PATH).get("schema", 0)) == City.SCHEMA, "UI save writes the current schema and preserves the original bytes")
	await growth_flow(isolated)
	await economy_flow(isolated)
	await project_flow(isolated)
	await artwork_flow(isolated)
	await tax_flow(isolated)
	await desirability_flow(isolated)
	await summary_flow(isolated)
	await guide_flow(isolated)
	await calendar_flow(isolated)
	await landvalue_flow(isolated)
	await density_flow(isolated)
	var metadata: Dictionary = {"suite":"packed-integration", "engine":Engine.get_version_info().string,
		"runtime":"editor_with_release_pck","checks":checks,"failed":failures.size(),"failures":failures,
		"display_backend":DisplayServer.get_name(),"screen_dpi":DisplayServer.screen_get_dpi()}
	print(JSON.stringify(metadata))
	main.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)

func growth_days(count: int) -> void:
	for day in range(count): Clock.advance(main.city, 1_000_000, 1)
	main._refresh_metrics()
	main.world.queue_redraw()
	await frames()

func fresh_scene(isolated: IsolatedStore, guide: bool = false) -> void:
	main.queue_free()
	await frames()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	main.store = isolated
	main.set_process(false)
	await frames()
	# Feature flows hide the First steps card; guide_flow tests it with the card shown.
	if not guide: main._set_guide_visible(false)

func growth_flow(isolated: IsolatedStore) -> void:
	await fresh_scene(isolated)
	# Lift the view so both lot rows beside the street stay clear of the inspector.
	await view_from(Vector2(400,420))
	await key(KEY_1)
	await drag_cells(Vector2i(42, 32), Vector2i(63, 32))
	await key(KEY_P)
	await click(screen_cell(Vector2i(39, 32)))
	await key(KEY_2)
	await drag_cells(Vector2i(43, 30), Vector2i(58, 30))
	await key(KEY_6)
	check(main.tool == "shop", "6 selects shipped shop tool")
	await drag_cells(Vector2i(43, 34), Vector2i(49, 34))
	await key(KEY_7)
	check(main.tool == "workshop", "7 selects shipped workshop tool")
	await drag_cells(Vector2i(52, 34), Vector2i(58, 34))
	check(main.city.lot_anchors.size() == 12 and main.city.growth.population == 0 and main.city.power.total_used == 12, "pointer-built empty mixed lot town receives service")
	await growth_days(5)
	main._inspect_cell(Vector2i(43, 30))
	check(main.city.growth.population == 12 and main.city.growth.jobs == 0 and "L1" in main.selection_label.text and "Demand met" in main.scope_label.text, "pack bootstrap updates residents, lot level, and demand explanation")
	await growth_days(35)
	# D33/D36: industry nearest the link grows first, so the two homes across the street
	# from those developed workshops are held at level 1.
	check(main.city.growth.population == 40 and main.city.growth.jobs == 18 and "Residents 40" in main.population_label.text and main.demand_meter.summary() == "R +2 · C 0 · I 0" and "Tax 10%" in main.demand_label.text, "shipped growth settles at 40 / 18 with matching HUD and the held homes' demand")
	main._inspect_cell(Vector2i(58, 30))
	check(main.city.growth.reason(main.city, main.city.index(Vector2i(58, 30))) == "held" and "Land value −2 (modest): industry −2" in main.legend_label.text and "Held at L1" in main.scope_label.text, "shipped inspector explains a home held by a workshop across the street")
	await key(KEY_S, true)
	var saved: String = main.city.canonical()
	await fresh_scene(isolated)
	await key(KEY_L, true)
	check(main.city.canonical() == saved and main.speed == 0 and main.city.growth.population == 40, "new scene load restores developed mixed lot town paused")
	# A second street and lots beyond capacity, then the shipped explanations.
	var extra_roads: Array[Vector2i] = [Vector2i(41, 28), Vector2i(41, 29), Vector2i(41, 30)]
	for x in range(42, 63): extra_roads.append(Vector2i(x, 28))
	main.city.apply_command("road", extra_roads)
	main.city.apply_command("home", lots_row(25, 42, 7))
	project_command("home", [Vector2i(60, 29), Vector2i(60, 33)])
	main._refresh_metrics()
	main._inspect_cell(Vector2i(61, 26))
	check(main.city.lot_anchors.size() == 21 and main.city.power.short_homes == 1 and "network full" in main.power_label.text and "Waiting for road access and power" in main.scope_label.text, "the farthest new lot has separate growth and capacity explanations")
	await growth_days(10)
	check(main.city.development[main.city.index(Vector2i(60, 25))] == 0, "short lot stays empty through growth rounds")
	await key(KEY_3)
	await click(screen_cell(Vector2i(61, 32)))
	await growth_days(5)
	main._inspect_cell(Vector2i(43, 30))
	check("Loses a level in 1" in main.scope_label.text and "No road access" in main.access_label.text, "disconnection explains remaining decline grace")
	await growth_days(5)
	check(main.city.growth.population == 24, "disconnected developed district declines in packed game")
	await key(KEY_1)
	await click(screen_cell(Vector2i(61, 32)))
	await view_from(Vector2(400,300))
	await key(KEY_P)
	await click(screen_cell(Vector2i(39, 25)))
	check(main.city.station_anchors.size() == 2 and main.city.power.short_homes == 0, "second 4x4 station placed by pointer relieves the shortage")
	await growth_days(30)
	check(main.city.growth.population == 48 and main.city.power.short_homes == 0, "reconnect and second station restore growth and supply")
	# Schema-2 migration through shipped scene/storage, with source bytes retained.
	var path: String = (get_script() as Script).resource_path.get_base_dir().path_join("fixtures/m2b-schema2.json")
	var legacy: String = FileAccess.get_file_as_string(path)
	FileOps.new().write_text(isolated.test_path, legacy)
	main.dirty = false
	await key(KEY_L, true)
	check("Earlier format 2" in main.status_label.text and main.city.growth.population == 0 and main.city.station_anchors.is_empty() and FileAccess.get_file_as_string(isolated.test_path) == legacy, "UI schema-2 load clears single-tile footprints and leaves original unchanged")
	await key(KEY_S, true)
	check(FileAccess.get_file_as_string(Store.preserved_path(isolated.test_path, 2)) == legacy and isolated.load_city(main.SAVE_PATH).schema == City.SCHEMA, "UI save preserves schema-2 original")

func economy_flow(isolated: IsolatedStore) -> void:
	await fresh_scene(isolated)
	await key(KEY_1)
	await drag_cells(Vector2i(42, 32), Vector2i(63, 32))
	await key(KEY_P)
	await click(screen_cell(Vector2i(39, 32)))
	await key(KEY_2)
	await drag_cells(Vector2i(43, 30), Vector2i(58, 30))
	await key(KEY_8)
	check(main.tool == "park" and main.tool_buttons.park.button_pressed, "8 selects shipped park tool")
	await drag_cells(Vector2i(58, 29), Vector2i(58, 28))
	check(main.city.occupancy.count(City.PARK) == 1 and main.city.occupancy[main.city.index(Vector2i(58, 28))] == City.PARK, "park pointer drag places only endpoint facility")
	main._inspect_cell(Vector2i(58, 28))
	check("3 side-steps" in main.access_label.text and "Upkeep $10/month" in main.scope_label.text, "shipped park inspector explains coverage effect and upkeep")
	await growth_days(5)
	main._inspect_cell(Vector2i(58, 30))
	check(main.city.development[main.city.index(Vector2i(57, 29))] == 1 and main.city.development[main.city.index(Vector2i(54, 29))] == 1 and "Land value +2" in main.legend_label.text and ": park +2" in main.legend_label.text, "shipped park changes which lots receive starter growth")
	await growth_days(25)
	check(main.city.last_budget.tick == 30 and City.Economy.totals(main.city.last_budget).net == 3200 and main.city.cash == 906200, "shipped month: $124 income minus $92 upkeep gives $32")
	await key(KEY_B)
	check(main.budget_dialog.visible and "12 serviced residents" in main.budget_text.text and "1 power plants" in main.budget_text.text and "LAST SETTLEMENT" in main.budget_text.text and "Shortfall waived $0.00" in main.budget_text.text, "B shows auditable forecast and actual ledger counting one 4x4 station")
	main.budget_dialog.hide()
	await key(KEY_S, true)
	var saved: String = main.city.canonical()
	await fresh_scene(isolated)
	await key(KEY_L, true)
	check(main.city.canonical() == saved and main.city.amenity.lot_covered[main.city.index(Vector2i(57, 29))] == 1, "shipped restart/load preserves ledger and reconstructs lot coverage")
	# Controlled zero-reserve overbuild, then real UI removal/recovery.
	main.city.cash = 0
	for y in range(24, 28):
		for x in range(44, 48): main.city.occupancy[main.city.index(Vector2i(x, y))] = City.POWER
	main.city.footprint_anchor[main.city.index(Vector2i(44, 24))] = 1
	main.city.rebuild_derived()
	await growth_days(30)
	await key(KEY_B)
	check(main.city.cash == 0 and "DEFICIT" in main.budget_text.text and "Shortfall waived $28.00" in main.budget_text.text, "shipped deficit explains exact waiver and retains services")
	main.budget_dialog.hide()
	await key(KEY_3)
	await click(screen_cell(Vector2i(46, 27)))
	check(main.city.station_anchors.size() == 1, "free UI removal clears the unused 4x4 station from one tile")
	await growth_days(30)
	check(main.city.cash == 3200 and not "DEFICIT" in main.demand_label.text, "free UI removal recovers from zero cash next month")
	var path: String = (get_script() as Script).resource_path.get_base_dir().path_join("fixtures/m2c-schema3.json")
	var legacy: String = FileAccess.get_file_as_string(path)
	FileOps.new().write_text(isolated.test_path, legacy)
	main.dirty = false
	await key(KEY_L, true)
	check(main.city.last_budget.is_empty() and main.city.growth.population == 0 and "Earlier format 3" in main.status_label.text and "13 old single-tile" in main.status_label.text, "shipped schema-3 migration clears single-tile footprints without fabricated history")
	await key(KEY_S, true)
	check(FileAccess.get_file_as_string(Store.preserved_path(isolated.test_path, 3)) == legacy, "shipped schema-3 bytes preserved before save")

func project_flow(isolated: IsolatedStore) -> void:
	await fresh_scene(isolated)
	var before: String = main.city.canonical()
	await click(main.project_button.get_global_rect().get_center())
	main._set_speed(1)
	main.focus_paused = false
	main.last_usec = Time.get_ticks_usec() - 2000000
	main._process(2.0)
	check(main.city.canonical() == before, "open project actually suspends elapsed simulation time")
	main._set_speed(0)
	check("J Project" in main.help_text.text and "3x3 lots" in main.help_text.text, "Help documents the project shortcut and lot sizes")
	check(main.project_dialog.visible and "No parks yet" in main.project_text.text and main.project_complete.disabled, "Project button opens no-park explanation")
	await key(KEY_ESCAPE)
	check(not main.project_dialog.visible and main.city.canonical() == before, "project cancellation changes no state")
	main.city.initialize(91, 16, 22)
	main.city.terrain.fill(City.LAND)
	main.city.rebuild_derived()
	var roads: Array[Vector2i] = []
	for x in range(6, 16): roads.append(Vector2i(x, 11))
	project_command("road", roads)
	project_command("power", [Vector2i(12, 12)])
	project_command("home", [Vector2i(6, 8), Vector2i(11, 8), Vector2i(9, 12)])
	project_command("park", [Vector2i(0, 0)])
	project_command("park", [Vector2i(10, 10)])
	await growth_days(5)
	await key(KEY_J)
	check(main.project_choice.item_count == 2 and main.project_choice.get_item_id(0) == 0 and main.project_complete.disabled, "J opens row-major parks and defaults to first")
	main.project_choice.select(1)
	main.project_choice.item_selected.emit(1)
	await frames()
	check(not main.project_complete.disabled and "3 / 3" in main.project_text.text and "RESIDENTIAL LOTS" in main.project_text.text, "choosing a qualifying park enables completion")
	project_command("clear", [Vector2i(15, 11)])
	before = main.city.canonical()
	main._complete_project()
	check(main.city.canonical() == before and main.project_complete.disabled, "UI stale enabled request is rejected by model")
	project_command("road", [Vector2i(15, 11)])
	main._refresh_project()
	main.dirty = false
	main.project_complete.pressed.emit()
	await frames()
	check(main.city.project.completed and main.dirty and "Completed:" in main.project_text.text and not main.project_complete.visible, "explicit UI completion marks unsaved and acknowledges cosmetic result")
	before = main.city.canonical()
	main.project_show.pressed.emit()
	await frames()
	check(not main.project_dialog.visible and main.city.canonical() == before and "Project completed" in main.scope_label.text, "Show park closes modal, centres and explains unchanged benefit without mutation")
	await key(KEY_S, true)
	var saved: String = main.city.canonical()
	await fresh_scene(isolated)
	await key(KEY_L, true)
	await key(KEY_J)
	check(main.city.canonical() == saved and main.project_show.visible and not main.project_choice.visible, "restart/load shows completed project and anchor")
	main.project_dialog.hide()
	project_command("clear", [Vector2i(10, 10)])
	await key(KEY_S, true)
	await key(KEY_L, true)
	await key(KEY_J)
	check("was cleared" in main.project_text.text and not main.project_show.visible and main.city.project.completed, "cleared anchor reload retains achievement without Show park")
	main.project_dialog.hide()
	# Invalid project file cannot replace the live model.
	var bad: Dictionary = main.city.snapshot()
	bad.project.park_index = 99999
	FileOps.new().write_text(isolated.test_path, JSON.stringify(bad))
	before = main.city.canonical()
	main._load_path(main.SAVE_PATH)
	check(main.city.canonical() == before and "Current city unchanged" in main.status_label.text, "malformed project load retains live town")
	main.recovery_dialog.hide()

## EXPERIMENTAL artwork evaluation: both Kenney packs resolve inside the release PCK
## and switching art through the shipped Display buttons never touches the model.
func artwork_flow(isolated: IsolatedStore) -> void:
	await fresh_scene(isolated)
	check(main.world.art_mode == "modern_city" and main.world.art != null, "a fresh game starts with the default Modern City artwork")
	for path in ["res://assets/experiments/city_art/tiny_city/tilemap_packed.png", "res://assets/experiments/city_art/roguelike_modern_city/tilemap_packed.png"]:
		var texture: Texture2D = load(path)
		check(texture != null and texture.get_size() == (Vector2(192, 176) if "tiny" in path else Vector2(592, 448)), "experimental atlas resolves in the exported pack: " + path.get_base_dir().get_file())
	var roads: Array[Vector2i] = []
	for x in range(42, 64): roads.append(Vector2i(x, 32))
	project_command("road", roads)
	project_command("power", [Vector2i(38, 31)])
	project_command("home", [Vector2i(42, 29), Vector2i(45, 29)])
	project_command("shop", [Vector2i(42, 33)])
	project_command("workshop", [Vector2i(45, 33)])
	project_command("park", [Vector2i(48, 28)])
	await growth_days(15)
	var before: String = main.city.canonical()
	main._open_settings()
	await frames()
	check(main.settings.size.y <= 720 and main.settings.get_ok_button().get_global_rect().end.y <= 720, "display dialog with artwork row fits 720p")
	var buttons: Array = []
	for child in main.settings.find_children("*", "Button", true, false):
		if (child as Button).text in ["Original", "Tiny City", "Modern City"]: buttons.append(child)
	check(buttons.size() == 3 and "Modern City default" in main.settings.find_children("*", "Label", true, false).map(func(l): return l.text).reduce(func(a, b): return a + "|" + b, ""), "display dialog offers three artwork modes and names the default")
	for button in buttons:
		(button as Button).pressed.emit()
		await frames()
		var expected: String = {"Original": "original", "Tiny City": "tiny_city", "Modern City": "modern_city"}[(button as Button).text]
		check(main.world.art_mode == expected and (main.world.art == null) == (expected == "original") and "Presentation only" in main.status_label.text, "display button selects %s artwork" % expected)
		check(main.city.canonical() == before, "switching to %s artwork leaves the town unchanged" % expected)
	main.settings.hide()
	await key(KEY_S, true)
	var saved_modern: String = FileAccess.get_file_as_string(isolated.test_path)
	main._set_art("original")
	await key(KEY_S, true)
	check(FileAccess.get_file_as_string(isolated.test_path) == saved_modern and not "art" in JSON.parse_string(saved_modern), "artwork mode is never written to saves")
	main._set_art("tiny_city")
	await growth_days(10)
	main._set_art("modern_city")
	await growth_days(10)
	check(main.city.growth.population > 0 and main.city.tick == 35, "simulation keeps running under the experimental artwork modes")
	main.world.set_art("unknown")
	check(main.world.art_mode == "original" and main.world.art == null, "an unknown artwork mode falls back to the original renderer")

## D32 / M2f: the shipped meter, Budget tax row, rate effects and saved rate.
func tax_flow(isolated: IsolatedStore) -> void:
	await fresh_scene(isolated)
	check(main.demand_meter.is_visible_in_tree() and main.demand_meter.summary() == "R +3 · C 0 · I 0" and "Tax 10%" in main.demand_label.text, "fresh game shows the starter home demand on the meter at the standard rate")
	var roads: Array[Vector2i] = []
	for x in range(42, 64): roads.append(Vector2i(x, 32))
	project_command("road", roads)
	project_command("power", [Vector2i(38, 31)])
	project_command("home", [Vector2i(42, 29), Vector2i(45, 29), Vector2i(48, 29), Vector2i(51, 29)])
	project_command("shop", [Vector2i(42, 33), Vector2i(45, 33)])
	project_command("workshop", [Vector2i(48, 33), Vector2i(51, 33)])
	main._refresh_metrics()
	await frames()
	check(main.demand_meter.summary() == "R +3 · C 0 · I 0" and "R +3" in main.demand_meter.tooltip_text, "meter shows the three-level starter home demand")
	await key(KEY_B)
	check(main.budget_dialog.visible and main._modal_open() and "Tax rate 10%" in main.tax_label.text and main.tax_buttons.standard.disabled, "B opens the Budget dialog at the standard rate")
	var tick: int = main.city.tick
	var sequence: int = main.city.sequence
	for step in range(5):
		main.tax_buttons.raise.pressed.emit()
		await frames(1)
	check(main.city.tax_rate == 15 and main.city.sequence == sequence + 5 and main.city.tick == tick, "five raise presses set 15% as five ordered commands without advancing time")
	check("Tax rate 15%" in main.tax_label.text and "$3 per serviced resident" in main.tax_note.text and "Tax 15%" in main.budget_text.text and "Tax 15%" in main.demand_label.text and "Tax rate 15%" in main.status_label.text, "Budget, toolbar and status agree on 15%")
	check(main.demand_meter.summary() == "R +2 · C 0 · I 0", "15% lowers the starter home demand on the meter")
	for step in range(20):
		main.tax_buttons.lower.pressed.emit()
	await frames()
	check(main.city.tax_rate == 0 and main.tax_buttons.lower.disabled and main.demand_meter.summary() == "R +4 · C 0 · I 0", "lower stops at 0% and the meter shows the larger 0% demand")
	for step in range(30):
		main.tax_buttons.raise.pressed.emit()
	await frames()
	check(main.city.tax_rate == 25 and main.tax_buttons.raise.disabled, "raise stops at 25%")
	main.tax_buttons.standard.pressed.emit()
	await frames()
	check(main.city.tax_rate == 10 and main.tax_buttons.standard.disabled, "Standard returns to 10%")
	main.budget_dialog.hide()
	await growth_days(40)
	var grown: int = main.city.growth.population
	await key(KEY_B)
	for step in range(10):
		main.tax_buttons.raise.pressed.emit()
	await frames()
	main.budget_dialog.hide()
	main._refresh_metrics()
	await frames()
	var values: Array[int] = main.meter_values()
	check(main.city.tax_rate == 20 and (values[0] < 0 or values[1] < 0 or values[2] < 0) and "−" in main.demand_meter.summary(), "20% shows leaving levels as negative meter values")
	var anchor: Vector2i = Vector2i(51, 29)
	main._inspect_cell(anchor)
	check("(taxes)" in main.scope_label.text or "Taxes above 10%" in main.scope_label.text or "Demand" in main.scope_label.text, "inspector explains demand under high taxes")
	await growth_days(15)
	check(main.city.growth.population < grown and main.city.lot_anchors.size() == 8, "high taxes shrink the shipped town without removing lots")
	await key(KEY_S, true)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(isolated.test_path))
	check(int(saved.schema_version) == City.SCHEMA and int(saved.tax_rate) == 20 and saved.simulation_version == City.SIMULATION, "shipped save writes the current schema with the 20% rate")
	var canonical: String = main.city.canonical()
	await fresh_scene(isolated)
	await key(KEY_L, true)
	check(main.city.tax_rate == 20 and main.city.canonical() == canonical and "Tax 20%" in main.demand_label.text, "shipped load restores the town and its tax rate")
	var six_path: String = (get_script() as Script).resource_path.get_base_dir().path_join("fixtures/m2e-schema6.json")
	var six: String = FileAccess.get_file_as_string(six_path)
	await fresh_scene(isolated)
	isolated.files.write_text(isolated.test_path, six)
	await key(KEY_L, true)
	check(main.city.lot_anchors.size() == 3 and main.city.tax_rate == 10 and "Earlier format 6" in main.status_label.text and "every lot kept" in main.status_label.text and "standard 10%" in main.status_label.text and "manual.schema6.json" in main.status_label.text, "UI schema-6 load keeps every lot at the standard rate and names the preserved original")
	await key(KEY_S, true)
	check(FileAccess.get_file_as_string(Store.preserved_path(isolated.test_path, 6)) == six and int(isolated.load_city(main.SAVE_PATH).schema) == City.SCHEMA, "UI save preserves schema-6 bytes and writes the current schema")

## D33 / M2g: the shipped overlay, held home, park rescue and schema-7 migration.
func desirability_flow(isolated: IsolatedStore) -> void:
	await fresh_scene(isolated)
	check(not main.world.desirability_visible and not "+ raises" in main.legend_label.text, "the land value overlay starts off")
	var roads: Array[Vector2i] = []
	for x in range(42, 64): roads.append(Vector2i(x, 32))
	project_command("road", roads)
	project_command("power", [Vector2i(38, 31)])
	project_command("home", [Vector2i(51, 29)])
	project_command("workshop", [Vector2i(51, 33)])
	main.city.development[main.city.index(Vector2i(51, 29))] = 2
	main.city.development[main.city.index(Vector2i(51, 33))] = 1
	main.city.rebuild_derived()
	main._refresh_metrics()
	await key(KEY_V)
	main._inspect_cell(Vector2i(45, 40))
	check(main.world.desirability_visible and "+ raises" in main.legend_label.text and "Land value overlay on" in main.status_label.text, "V turns the overlay on with a legend and status explanation")
	var home: int = main.city.index(Vector2i(51, 29))
	main._inspect_cell(Vector2i(52, 30))
	check(main.city.desirability.tile_score[home] == -2 and "Drops to L1 next check" in main.scope_label.text, "shipped inspector warns that a level-2 home beside a developed workshop will drop")
	await growth_days(5)
	main._inspect_cell(Vector2i(52, 30))
	check(main.city.development[home] == 1 and "Held at L1" in main.scope_label.text, "the home drops one level and is held")
	await key(KEY_8)
	await click(screen_cell(Vector2i(52, 27)))
	main._inspect_cell(Vector2i(52, 30))
	check(main.city.occupancy[main.city.index(Vector2i(52, 27))] == City.PARK and main.city.desirability.lot_score[home] == 0 and "Land value 0 (modest): park +2, industry −2" in main.legend_label.text, "a park placed by pointer offsets the workshop")
	await growth_days(5)
	check(main.city.development[home] == 2, "the rescued home regrows to level 2 in the shipped game")
	main._open_settings()
	await frames()
	var toggle: Button = null
	for child in main.settings.find_children("*", "Button", true, false):
		if "Land value overlay" in (child as Button).text: toggle = child
	check(toggle != null and main.settings.size.y <= 720 and main.settings.get_ok_button().get_global_rect().end.y <= 720, "display dialog with the overlay toggle fits 720p")
	if toggle != null:
		toggle.pressed.emit()
		await frames()
	check(not main.world.desirability_visible and "overlay off" in main.status_label.text, "the Display toggle turns the overlay off")
	main.settings.hide()
	await key(KEY_V)
	await key(KEY_S, true)
	var saved: String = FileAccess.get_file_as_string(isolated.test_path)
	check(not "desirab" in saved and int(JSON.parse_string(saved).schema_version) == City.SCHEMA, "overlay state is never saved; saves are the current schema")
	var seven_path: String = (get_script() as Script).resource_path.get_base_dir().path_join("fixtures/m2f-schema7.json")
	var seven: String = FileAccess.get_file_as_string(seven_path)
	await fresh_scene(isolated)
	isolated.files.write_text(isolated.test_path, seven)
	await key(KEY_L, true)
	check(main.city.tax_rate == 14 and "Earlier format 7" in main.status_label.text and "every lot kept" in main.status_label.text and not "standard 10%" in main.status_label.text, "UI schema-7 load keeps every lot and its own tax rate")
	await key(KEY_S, true)
	check(FileAccess.get_file_as_string(Store.preserved_path(isolated.test_path, 7)) == seven and int(isolated.load_city(main.SAVE_PATH).schema) == City.SCHEMA, "UI save preserves schema-7 bytes and writes the current schema")

## D34 / M2h: the shipped summary dialog, its actions and its read-only guarantee.
func summary_flow(isolated: IsolatedStore) -> void:
	await fresh_scene(isolated)
	await key(KEY_T)
	check(main.summary_dialog.visible and main._modal_open() and main.summary_items.size() == 1 and main.summary_items[0].kind == "empty" and "Residents 0" in main.summary_heading.text, "T opens the summary of an empty town")
	check(main.summary_actions.size() == 1 and main.summary_actions[0].text == "Show", "the empty-town item has a Show action")
	main.summary_actions[0].pressed.emit()
	await frames()
	check(not main.summary_dialog.visible and main.inspected_cell == main.city.access.root, "Show closes the summary and inspects the gold flag")
	# A grown street with homes held across from developed workshops.
	var roads: Array[Vector2i] = []
	for x in range(42, 64): roads.append(Vector2i(x, 32))
	project_command("road", roads)
	project_command("power", [Vector2i(38, 31)])
	project_command("home", lots_row(29, 42, 6))
	project_command("shop", lots_row(33, 42, 3))
	project_command("workshop", lots_row(33, 51, 3))
	await growth_days(40)
	var before: String = main.city.canonical()
	var sequence: int = main.city.sequence
	main.summary_button.pressed.emit()
	await frames()
	check(main.summary_dialog.visible and main.summary_items[0].kind == "held" and "2 residential lots held" in main.summary_items[0].text and main.city.canonical() == before and main.city.sequence == sequence, "the status-bar button opens a read-only summary led by the held homes")
	var tick: int = main.city.tick
	main._set_speed(3)
	main.set_process(true)
	await frames(10)
	main.set_process(false)
	main._set_speed(0)
	check(main.city.tick == tick and main.summary_dialog.visible, "time stays suspended at 3x while the summary is open")
	main.summary_actions[0].pressed.emit()
	await frames()
	var held: int = int(main.summary_items[0].example)
	check(main.inspected_cell == main.city.cell_of(held) and "Held at L1" in main.scope_label.text and main._is_world_position(screen_cell(main.city.cell_of(held))), "Show centres on and inspects the first held home")
	main.city.set_tax_rate(25)
	main._refresh_metrics()
	await key(KEY_T)
	check(main.summary_items[0].kind == "leaving" and main.summary_actions[0].text == "Budget", "under 25% taxes the summary leads with leaving levels and a Budget action")
	main.summary_actions[0].pressed.emit()
	await frames()
	check(main.budget_dialog.visible and not main.summary_dialog.visible and "Tax rate 25%" in main.tax_label.text, "the Budget action opens Budget at the tax row")
	main.budget_dialog.hide()
	main._set_text_size(20)
	await key(KEY_T)
	await frames()
	check(main.summary_dialog.size.y <= 720 and main.summary_dialog.get_ok_button().get_global_rect().end.y <= 720, "a several-item summary fits 720p at the largest text")
	main.summary_dialog.hide()
	main._set_text_size(16)

## D29 / M3b: the shipped First steps card with real pointer and key input.
func guide_flow(isolated: IsolatedStore) -> void:
	await fresh_scene(isolated, true)
	check(main.guide_panel.visible and main.guide_state.step == 1 and main.guide_action.text == "Show" and main.guide_hide.text == "Hide", "a restarted scene shows the card again at step 1")
	var before: String = main.city.canonical()
	var origin: Vector2 = main.world.origin
	main.world.origin = Vector2.ZERO
	main.world.clamp_camera()
	await click(main.guide_action.get_global_rect().get_center())
	check(main.world.origin != Vector2.ZERO and main.inspected_cell == main.city.access.root and main.city.canonical() == before and not main.dirty, "Show recentres on the flag and inspects it without changing the town")
	main.world.origin = origin
	main.world.clamp_camera()
	await frames()
	check(main._is_world_position(screen_cell(Vector2i(60, 32))) and main._is_world_position(screen_cell(Vector2i(53, 32))), "the opening street area is uncovered by the card")
	await key(KEY_1)
	await drag_cells(Vector2i(56, 32), Vector2i(63, 32))
	check(main.guide_state.step == 2 and main.world.guide_target == main.city.access.root, "a pointer-laid flag road advances to step 2")
	await key(KEY_2)
	await click(screen_cell(Vector2i(61, 30)))
	check(main.guide_state.step == 3 and main.world.guide_target == Vector2i(60, 29) and main.world.guide_size == 3, "a home lot by pointer advances to step 3 with a 3x3 bracket")
	await key(KEY_P)
	await click(screen_cell(Vector2i(53, 32)))
	check(main.city.station_anchors.size() == 1 and main.guide_state.step == 4 and "meter" in main.guide_text.text, "a pointer-placed station advances to step 4")
	await key(KEY_SPACE)
	check(main.speed == 1, "Space starts time as step 4 asks")
	await key(KEY_SPACE)
	await growth_days(5)
	check(main.guide_state.step == 5 and main.guide_action.text == "Open Project", "one growth round advances to step 5 with Open Project")
	await key(KEY_J)
	main.project_dialog.hide()
	await frames()
	check(main.guide_state.state == "done" and "DONE" in main.guide_heading.text and main.guide_hide.text == "Close" and not main.guide_action.visible, "J opens Project and completes the steps")
	# Visibility routes.
	await click(main.guide_hide.get_global_rect().get_center())
	check(not main.guide_panel.visible and main.world.guide_target == Vector2i(-1, -1), "Close hides the card and its marker")
	await key(KEY_SPACE)
	check(main.speed == 1, "Space still toggles time after a card click")
	await key(KEY_SPACE)
	await key(KEY_2)
	check(main.tool == "home", "tool keys still work after a card click")
	await key(KEY_F1)
	check(main.guide_panel.visible, "F1 shows the card again")
	await key(KEY_F1)
	check(not main.guide_panel.visible, "F1 hides it")
	main._open_help()
	await frames()
	main.help_dialog.custom_action.emit("guide")
	await frames()
	check(main.guide_panel.visible and not main.help_dialog.visible, "Help's Show first steps closes Help and shows the card")
	await key(KEY_B)
	await key(KEY_F1)
	check(main.guide_panel.visible and main.budget_dialog.visible, "F1 is ignored while a modal dialog is open")
	main.budget_dialog.hide()
	await frames()
	# Input safety over the card.
	before = main.city.canonical()
	var cash: int = main.city.cash
	await key(KEY_1)
	await click(main.guide_text.get_global_rect().get_center())
	check(main.city.canonical() == before, "a click over the card never paints")
	var down := InputEventMouseButton.new()
	down.position = screen_cell(Vector2i(45, 36))
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	Input.parse_input_event(down)
	await frames()
	var motion := InputEventMouseMotion.new()
	motion.position = main.guide_text.get_global_rect().get_center()
	Input.parse_input_event(motion)
	await frames()
	var up: InputEventMouseButton = down.duplicate()
	up.position = motion.position
	up.pressed = false
	Input.parse_input_event(up)
	await frames()
	check(main.city.canonical() == before and main.city.cash == cash, "a stroke released over the card cancels without charge")
	# Saves are identical whether the card is shown or hidden.
	await key(KEY_S, true)
	var shown: String = FileAccess.get_file_as_string(isolated.test_path)
	main._set_guide_visible(false)
	await key(KEY_S, true)
	check(FileAccess.get_file_as_string(isolated.test_path) == shown and not "guide" in shown, "saved bytes are identical with the card shown or hidden")
	# Load rechecks the steps and keeps visibility; a failed load changes nothing.
	var fixture: String = (get_script() as Script).resource_path.get_base_dir().path_join("fixtures/m3a-schema5.json")
	isolated.files.write_text(isolated.test_path, FileAccess.get_file_as_string(fixture))
	main.dirty = false
	await key(KEY_L, true)
	check(not main.guide_panel.visible and main.guide_state.step == 2, "load rechecks the steps (cleared M3a homes: step 2) and keeps the card hidden")
	main._set_guide_visible(true)
	var state: Dictionary = main.guide_state.duplicate()
	isolated.files.write_text(isolated.test_path, "{broken")
	isolated.files.write_text(isolated.test_path + ".bak", "{broken")
	await key(KEY_L, true)
	check(main.guide_panel.visible and main.guide_state == state, "a failed load leaves the card unchanged")
	main.recovery_dialog.hide()
	# Text size while the card is shown.
	main._set_text_size(20)
	await frames()
	var card: Rect2 = main.guide_panel.get_global_rect()
	check(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(card) and not card.intersects(main.inspector.get_global_rect()) and main.guide_hide.get_global_rect().end.y <= card.end.y + 0.5, "the card re-lays out at the largest text")
	check(absf(main.bottom.position.y - card.end.y - 12) <= 1.0, "the card keeps its 12 px gap above the status bar after a text-size change")
	main._set_text_size(16)

## D35 / R1: the shipped calendar and R/C/I wording; the date is never saved.
func calendar_flow(isolated: IsolatedStore) -> void:
	await fresh_scene(isolated)
	check(main.day_label.text.begins_with("1 Jan 1950"), "a new town starts on 1 Jan 1950")
	var words: String = main.help_text.text
	for kind in main.tool_buttons: words += "
" + main.tool_buttons[kind].text + "
" + main.tool_buttons[kind].tooltip_text
	words += "
" + main.demand_meter.tooltip_text + "
" + main.status_label.text
	var old_words: bool = false
	for word in ["Home", "Shop", "Workshop", "workshop", "station", "H homes", "H/S/W"]:
		if word in words.replace("[Home]", "").replace("Home returns", ""): old_words = true
	check(not old_words and "2  Residential" in main.tool_buttons.home.text and "6  Commercial" in main.tool_buttons.shop.text and "7  Industrial" in main.tool_buttons.workshop.text and "P  Power plant" in main.tool_buttons.power.text, "tools, tooltips, Help, meter and start-up status use Residential / Commercial / Industrial and power plant")
	project_command("road", [Vector2i(63, 32), Vector2i(62, 32), Vector2i(61, 32)])
	project_command("home", [Vector2i(60, 29)])
	main._inspect_cell(Vector2i(60, 29))
	await frames()
	check("Residential lot L0" in main.selection_label.text and "next check 6 Jan 1950" in main.scope_label.text, "the inspector names the lot and the next check as a date")
	await growth_days(29)
	check(main.day_label.text.begins_with("30 Jan 1950") and main.city.last_budget.is_empty(), "day 30 is 30 Jan 1950, before the first settlement")
	await growth_days(1)
	check(main.city.tick == 30 and main.day_label.text.begins_with("1 Feb 1950") and not main.city.last_budget.is_empty(), "the first settlement happens on 1 Feb 1950")
	main._open_budget()
	await frames()
	check("CURRENT FORECAST · Feb 1950 · settles 1 Mar 1950" in main.budget_text.text and "LAST SETTLEMENT · January 1950, settled 1 Feb 1950" in main.budget_text.text, "Budget names the forecast month and the month the last settlement closed")
	main.budget_dialog.hide()
	main._open_summary()
	await frames()
	check(main.summary_heading.text.begins_with("1 Feb 1950 · "), "the town summary heading shows the date")
	main.summary_dialog.hide()
	await growth_days(330)
	check(main.city.tick == 360 and main.day_label.text.begins_with("1 Jan 1951"), "twelve 30-day months make a year: tick 360 is 1 Jan 1951")
	await key(KEY_S, true)
	var saved: String = FileAccess.get_file_as_string(isolated.test_path)
	check(not saved.is_empty() and not "1951" in saved and not "Jan" in saved and int(JSON.parse_string(saved).schema_version) == City.SCHEMA, "the save is the current schema and stores no date")

## D36 / R2a: a held commercial lot and industry ordered by freight in the shipped game.
func landvalue_flow(isolated: IsolatedStore) -> void:
	await fresh_scene(isolated)
	var roads: Array[Vector2i] = []
	for x in range(42, 64): roads.append(Vector2i(x, 32))
	project_command("road", roads)
	project_command("power", [Vector2i(38, 31)])
	project_command("home", lots_row(29, 42, 6))
	project_command("shop", [Vector2i(42, 33), Vector2i(54, 33)])
	project_command("workshop", [Vector2i(51, 33), Vector2i(57, 33)])
	await growth_days(20)
	var near_link: int = main.city.index(Vector2i(57, 33))
	var far: int = main.city.index(Vector2i(51, 33))
	check(main.city.development[near_link] == 2 and main.city.development[far] == 0, "shipped industry nearest the link grows first")
	await growth_days(39)
	var shop: int = main.city.index(Vector2i(54, 33))
	check(main.city.development[shop] == 1 and main.city.growth.reason(main.city, shop) == "held", "a commercial lot between two industrial lots is held at level 1")
	main._inspect_cell(Vector2i(55, 34))
	await frames()
	check("Commercial lot L1" in main.selection_label.text and "Land value −2: trade +2, industry −4" in main.legend_label.text and "Held at L1 by industry" in main.scope_label.text, "the inspector explains the held commercial lot")
	main._inspect_cell(Vector2i(58, 34))
	await frames()
	check("Industrial lot L2" in main.selection_label.text and "Freight 4 road steps · ignores land value" in main.legend_label.text, "the inspector gives an industrial lot its freight steps")
	main._open_summary()
	await frames()
	var held: Dictionary = {}
	for entry in main.summary_items:
		if String(entry.kind) == "held": held = entry
	check(int(held.get("count", 0)) == 3 and "3 lots held at level 1" in String(held.get("text", "")), "the summary counts held residential and commercial lots together")
	main.summary_dialog.hide()
	await key(KEY_V)
	check(main.world.desirability_visible and main.city.desirability.tile_score[main.city.index(Vector2i(55, 34))] == -2, "V shows the commercial lot's land value")
	await key(KEY_V)

## D37 / R2b: upper levels, gates, wealth and the longest new texts in the shipped game.
func density_flow(isolated: IsolatedStore) -> void:
	await fresh_scene(isolated)
	var roads: Array[Vector2i] = []
	for x in range(42, 64): roads.append(Vector2i(x, 32))
	project_command("road", roads)
	project_command("power", [Vector2i(38, 31)])
	project_command("home", [Vector2i(42, 29), Vector2i(48, 29)])
	project_command("park", [Vector2i(43, 27)])
	project_command("shop", [Vector2i(54, 29)])
	project_command("workshop", [Vector2i(57, 29)])
	var tower: int = main.city.index(Vector2i(42, 29))
	var plain: int = main.city.index(Vector2i(48, 29))
	main.city.development[tower] = 4
	main.city.development[plain] = 2
	main.city.development[main.city.index(Vector2i(57, 29))] = 2
	main.city.rebuild_derived()
	main._refresh_metrics()
	await frames()
	check(main.city.growth.population == 48 and "Residents 48" in main.population_label.text, "a level-4 lot (40) and a level-2 lot (8) make 48 residents in the shipped HUD")
	main._inspect_cell(Vector2i(43, 30))
	await frames()
	check("Residential lot L4 · 40 residents" in main.selection_label.text and "(well-off): park +2" in main.legend_label.text and "Fully developed (level 4)" in main.scope_label.text, "the inspector shows a level-4 lot, its wealth and that it is full")
	main._inspect_cell(Vector2i(49, 30))
	await frames()
	check("L3 needs land value 1 (now 0): park or water." in main.scope_label.text and "(modest)" in main.legend_label.text, "the inspector explains the level-3 gate on a plain street")
	main._inspect_cell(Vector2i(58, 30))
	await frames()
	check("L3 needs 100 residents in town (now 48)." in main.scope_label.text, "the inspector explains the industrial workforce gate")
	main._set_text_size(20)
	await frames()
	main._inspect_cell(Vector2i(43, 30))
	main.scope_label.text = "Demand −32768 (taxes) · next check 30 Dec 2779727\nL4 needs land value 4 (now 3): park or residents."
	main.legend_label.text = "Land value −1 (well-off): park +2, water +1, industry −6"
	await frames()
	check(main.scope_label.get_global_rect().end.y <= main.inspector.get_global_rect().end.y and main.inspector.size.y <= 320.5, "the longest gate and wealth texts fit the inspector at the largest text")
	main._set_text_size(16)
	await frames()
	await growth_days(5)
	check(main.city.development[plain] == 2 and main.city.development[tower] == 4, "the gated lot stays at level 2 and the tower stays at level 4")

func project_command(kind: String, cells: Array[Vector2i]) -> Dictionary:
	return main.city.apply_command(kind, cells)
