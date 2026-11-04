extends Control
const City = preload("res://scripts/sim/city_state.gd")
const Clock = preload("res://scripts/sim/simulation_clock.gd")
const Store = preload("res://scripts/persistence/save_store.gd")
const Balance = preload("res://content/balance.gd")
const World = preload("res://scripts/presentation/world_view.gd")
const Style = preload("res://scripts/presentation/ui_style.gd")
const Bindings = preload("res://scripts/input/input_bindings.gd")
const SAVE_PATH: String = "user://saves/manual.json"
const SIZES: Array[Vector2i] = [Vector2i(1280,720), Vector2i(1366,768), Vector2i(1920,1080), Vector2i(1280,800)]
const PAN_VECTORS: Dictionary = {"pan_left": Vector2.LEFT, "pan_right": Vector2.RIGHT, "pan_up": Vector2.UP, "pan_down": Vector2.DOWN}

var city: City = City.new()
var store: Store = Store.new()
var world: World
var world_viewport: SubViewport
var world_texture: TextureRect
var world_rect: Rect2
var world_scale: int = 1
var tool: String = "road"
var speed: int = 0
var focus_paused: bool = false
var last_usec: int = 0
var dirty: bool = false
var stroke: Array[Vector2i] = []
var panning: bool = false
var ui_panels: Array[Control] = []
var tool_buttons: Dictionary = {}
var speed_buttons: Dictionary = {}
var top: PanelContainer
var side: PanelContainer
var bottom: PanelContainer
var cash_label: Label
var day_label: Label
var grid_label: Label
var selection_label: Label
var inspector: PanelContainer
var access_label: Label
var power_label: Label
var scope_label: Label
var legend_label: Label
var access_button: Button
var power_button: Button
var inspected_cell: Vector2i = Vector2i(-1, -1)
var inspector_target: Rect2 = Rect2()
var preview_label: Label
var status_label: Label
var zoom_label: Label
var settings: AcceptDialog
var help_dialog: AcceptDialog
var load_dialog: ConfirmationDialog
var quit_dialog: ConfirmationDialog
var recovery_dialog: ConfirmationDialog
var font_size: int = 16

func _ready() -> void:
	get_tree().auto_accept_quit = false
	DisplayServer.window_set_min_size(Vector2i(1280, 720))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = Style.make_theme(font_size)
	Bindings.install()
	city.initialize()
	world_viewport = SubViewport.new()
	world_viewport.size = Vector2i(640,360)
	world_viewport.disable_3d = true
	world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(world_viewport)
	world = World.new()
	world.city = city
	world_viewport.add_child(world)
	world_texture = TextureRect.new()
	world_texture.texture = world_viewport.get_texture()
	world_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(world_texture)
	_build_ui()
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()
	_select_tool("road")
	_set_speed(0)
	_center_camera()
	_inspect_cell(city.access.root)
	last_usec = Time.get_ticks_usec()
	_status("Begin at the gold flag: lay a road on its tile, connect streets and home plots along their sides, then add a power station (P) beside a street.")

func _build_ui() -> void:
	top = _panel()
	var row := HBoxContainer.new()
	top.add_child(row)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(heading)
	var title := _label("UNTITLED CITY BUILDER", 21)
	heading.add_child(title)
	heading.add_child(_label("A quiet place to begin · planning sandbox", 14, Style.MUTED))
	cash_label = _label("", 21)
	cash_label.custom_minimum_size.x = 178
	row.add_child(cash_label)
	day_label = _label("", 16)
	day_label.custom_minimum_size.x = 145
	row.add_child(day_label)
	grid_label = _label("", 16)
	grid_label.custom_minimum_size.x = 150
	row.add_child(grid_label)
	for value in [0,1,3]:
		var button := _button("Pause" if value == 0 else "%dx" % value, func(): _set_speed(value))
		button.toggle_mode = true
		row.add_child(button)
		speed_buttons[value] = button
	row.add_child(_button("Save", _save_clicked))
	row.add_child(_button("Load", _load_clicked))
	side = _panel()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	side.add_child(column)
	column.add_child(_label("LAY OUT YOUR TOWN", 13, Style.MUTED))
	var power_price: String = Balance.money(Balance.POWER_COST).trim_suffix(".00")
	for entry in [["road", "1  Roads · $10"], ["home", "2  Home zones · $25"], ["power", "P  Power station · " + power_price], ["clear", "3  Clear · free"]]:
		var kind: String = entry[0]
		var button := _button(entry[1], func(): _select_tool(kind))
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 36
		match kind:
			"clear": button.tooltip_text = "Clear is free, with no refund."
			"power": button.tooltip_text = "One station per placement. It supplies %d home plots through the roads it touches." % Balance.POWER_CAPACITY
			_: button.tooltip_text = "Price per tile; identical repainting is free."
		column.add_child(button)
		tool_buttons[kind] = button
	column.add_child(HSeparator.new())
	var outside_button := _button("Outside link  [Home]", _center_camera)
	column.add_child(outside_button)
	var marks := HBoxContainer.new()
	marks.add_theme_constant_override("separation", 6)
	column.add_child(marks)
	access_button = _button("Road [R]", _toggle_access)
	access_button.tooltip_text = "Road access marks: + connected / − missing"
	power_button = _button("Power [E]", _toggle_power)
	power_button.tooltip_text = "Power marks: bolt powered / × unpowered plot"
	for toggle: Button in [access_button, power_button]:
		toggle.toggle_mode = true
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		marks.add_child(toggle)
	access_button.set_pressed_no_signal(world.access_visible)
	power_button.set_pressed_no_signal(world.power_visible)
	var display_button := _button("Display & text", _open_settings)
	var help_button := _button("Controls & notes", _open_help)
	for button: Button in [outside_button, access_button, power_button, display_button, help_button] + tool_buttons.values():
		for style_name in ["normal", "hover", "pressed", "focus"]:
			var compact: StyleBox = theme.get_stylebox(style_name, "Button").duplicate()
			compact.content_margin_top = 4
			compact.content_margin_bottom = 4
			if button == access_button or button == power_button:
				compact.content_margin_left = 6
				compact.content_margin_right = 6
			button.add_theme_stylebox_override(style_name, compact)
	preview_label = _label("", 16, Style.ACCENT)
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_label.custom_minimum_size.y = 40
	column.add_child(preview_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var zoom_row := HBoxContainer.new()
	column.add_child(zoom_row)
	zoom_row.add_child(_button("−", func(): _zoom(-1)))
	zoom_label = _label("1x", 16)
	zoom_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zoom_row.add_child(zoom_label)
	zoom_row.add_child(_button("+", func(): _zoom(1)))
	column.add_child(display_button)
	column.add_child(help_button)
	inspector = _panel()
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 6)
	inspector.add_child(details)
	selection_label = _label("", 16)
	access_label = _label("", 16, Style.ACCENT)
	power_label = _label("", 16, Style.ACCENT)
	legend_label = _label("", 14, Style.MUTED)
	scope_label = _label("Growth not implemented; plots stay empty.", 16, Style.MUTED)
	for label: Label in [selection_label, access_label, power_label, legend_label, scope_label]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# Establish wrapping width before the first container layout; a zero-width
		# label otherwise requests a very tall panel on native startup.
		label.custom_minimum_size.x = 348
		details.add_child(label)
	power_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_update_legend()
	bottom = _panel()
	status_label = _label("", 15)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom.add_child(status_label)
	_build_dialogs()
	_refresh_metrics()

func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	ui_panels.append(panel)
	return panel

func _label(text: String, size_value: int = 16, color: Color = Style.INK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(callback)
	return button

func _build_dialogs() -> void:
	settings = AcceptDialog.new()
	settings.title = "Display & text"
	add_child(settings)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	settings.add_child(column)
	column.add_child(_label("Window size", 18))
	var sizes := HBoxContainer.new()
	column.add_child(sizes)
	for resolution in SIZES:
		sizes.add_child(_button("%d × %d" % [resolution.x,resolution.y], func(): DisplayServer.window_set_size(resolution)))
	column.add_child(_label("Interface text", 18))
	var texts := HBoxContainer.new()
	column.add_child(texts)
	for amount in [16,18,20]:
		texts.add_child(_button("Standard" if amount == 16 else "Larger" if amount == 18 else "Largest", func(): _set_text_size(amount)))
	column.add_child(_button("Toggle grid  [G]", func(): world.grid_visible = not world.grid_visible; world.queue_redraw()))
	column.add_child(_button("Center view  [Home]", _center_camera))
	column.add_child(_label("Pixel world stays crisp; interface text scales separately.", 15, Style.MUTED))
	help_dialog = AcceptDialog.new()
	help_dialog.title = "Controls & notes"
	help_dialog.dialog_text = "1 / 2 / 3   Roads, home zones, clear     P   Power station\nLeft drag   Preview a stroke; release to build\nRight mouse / Escape   Cancel stroke\nWASD / arrows / middle drag   Pan     Wheel / + / −   Zoom\nSpace   Pause / resume     4 / 5   Normal / fast\nCtrl+S / Ctrl+L   Save / load     Home   Outside link\nR   Road access marks: + connected / − missing\nE   Power marks: bolt powered / × unpowered plot\n\nLay a road on the gold flag to activate the outside link.\nJoin roads along shared sides; diagonals do not connect.\nA home needs a connected road beside it. Hover to inspect.\n\nA power station supplies %d plots through the roads and\nstations it touches, nearest plots first. It works without\nthe outside link: road access and power are separate needs.\n\nNo residents, growth, or taxes yet. Plots stay empty.\nManual saves are local; Load is explicit after restarting.\nOriginal geometric graphics. Godot/font: bundled notices." % Balance.POWER_CAPACITY
	add_child(help_dialog)
	load_dialog = ConfirmationDialog.new()
	load_dialog.title = "Load saved city?"
	load_dialog.dialog_text = "Replace your unsaved layout with the saved city?"
	load_dialog.get_ok_button().text = "Load city"
	load_dialog.confirmed.connect(func(): _load_path(SAVE_PATH))
	add_child(load_dialog)
	quit_dialog = ConfirmationDialog.new()
	quit_dialog.title = "Keep your changes?"
	quit_dialog.dialog_text = "Save this city before leaving?"
	quit_dialog.get_ok_button().text = "Save & quit"
	quit_dialog.add_button("Discard & quit", false, "discard")
	quit_dialog.confirmed.connect(func():
		if _save_city(): get_tree().quit())
	quit_dialog.custom_action.connect(func(action: String):
		if action == "discard": get_tree().quit())
	add_child(quit_dialog)
	recovery_dialog = ConfirmationDialog.new()
	recovery_dialog.title = "Save could not be loaded"
	recovery_dialog.get_ok_button().text = "Load previous backup"
	recovery_dialog.confirmed.connect(func(): _load_path(SAVE_PATH + ".bak"))
	add_child(recovery_dialog)

func _layout_ui() -> void:
	var available: Vector2 = get_viewport_rect().size
	world_scale = maxi(1, floori(minf(available.x / 640, available.y / 360)))
	world_rect = Rect2(((available - Vector2(640,360) * world_scale) / 2).floor(), Vector2(640,360) * world_scale)
	world_texture.position = world_rect.position
	world_texture.size = world_rect.size
	if top == null: return
	top.position = Vector2(16,16)
	top.size = Vector2(available.x - 32,80)
	side.position = Vector2(16,110)
	side.size = Vector2(228 if font_size == 16 else 252, available.y - 208)
	bottom.position = Vector2(16,available.y - 84)
	bottom.size = Vector2(available.x - 32,68)
	# Wider rather than taller at larger text, so the centred outside link stays uncovered.
	var inspector_width: int = 380 if font_size == 16 else 430 if font_size == 18 else 460
	var inspector_height: int = 320
	for label: Label in [selection_label, access_label, power_label, legend_label, scope_label]:
		label.custom_minimum_size.x = inspector_width - 32
	inspector_target = Rect2(Vector2(available.x - inspector_width - 16, bottom.position.y - inspector_height - 12), Vector2(inspector_width, inspector_height))
	_fit_inspector()
	_cancel_stroke()

func _fit_inspector() -> void:
	# Labels can briefly wrap at a previous width while text size changes, which grows
	# the panel; a Control never shrinks by itself, so restore the target each refresh.
	if inspector != null and inspector_target.size != Vector2.ZERO and inspector.get_rect() != inspector_target:
		inspector.size = inspector_target.size
		inspector.position = inspector_target.position

func _set_text_size(amount: int) -> void:
	font_size = amount
	theme = Style.make_theme(amount)
	(side.get_child(0) as VBoxContainer).add_theme_constant_override("separation", 6 if amount == 16 else 4)
	selection_label.add_theme_font_size_override("font_size", amount)
	access_label.add_theme_font_size_override("font_size", amount)
	power_label.add_theme_font_size_override("font_size", amount)
	scope_label.add_theme_font_size_override("font_size", amount)
	legend_label.add_theme_font_size_override("font_size", amount - 2)
	preview_label.add_theme_font_size_override("font_size", amount)
	status_label.add_theme_font_size_override("font_size", amount)
	_layout_ui()
	_status("Interface text updated.")

func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	var elapsed: int = now - last_usec
	last_usec = now
	if not focus_paused and not _modal_open():
		if Clock.advance(city, elapsed, speed) > 0:
			dirty = true
			_refresh_metrics()
		var direction := Vector2.ZERO
		for action in PAN_VECTORS:
			if Input.is_action_pressed(action, true): direction += PAN_VECTORS[action]
		if direction != Vector2.ZERO and not Input.is_physical_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_CTRL):
			world.pan_pixels(direction.normalized() * 360 * minf(float(elapsed) / 1_000_000, 0.1))
	_update_hover()

func _input(event: InputEvent) -> void:
	# A tap can begin and end between render frames, especially with virtual keys.
	# Give it a visible step; held keys continue through the camera polling above.
	if event is InputEventKey and event.pressed and not event.echo and not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed and not _modal_open():
		var direction := Vector2.ZERO
		for action in PAN_VECTORS:
			if event.is_action_pressed(action, false, true): direction += PAN_VECTORS[action]
		if direction != Vector2.ZERO:
			world.pan_pixels(direction * 16)
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and not stroke.is_empty():
			if _is_world_position(event.position):
				_extend_stroke(world.cell_at(_view_position(event.position)))
				_commit_stroke()
			else:
				_cancel_stroke()
				_status("Stroke cancelled outside the map view. No charge.")
			get_viewport().set_input_as_handled()
		if event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
			panning = false
	if event is InputEventMouseMotion and panning:
		world.pan_pixels(-event.relative / world_scale)
		get_viewport().set_input_as_handled()

func _shortcut_input(event: InputEvent) -> void:
	if _modal_open(): return
	if event is InputEventKey and event.echo: return
	var handled: bool = true
	for kind in ["road", "home", "power", "clear"]:
		if event.is_action_pressed("tool_" + kind):
			_select_tool(kind)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("save_city"):
		_save_clicked()
	elif event.is_action_pressed("load_city"):
		_load_clicked()
	elif event.is_action_pressed("pause_city"):
		_set_speed(1 if speed == 0 else 0)
	elif event.is_action_pressed("normal_speed"):
		_set_speed(1)
	elif event.is_action_pressed("fast_speed"):
		_set_speed(3)
	elif event.is_action_pressed("toggle_grid"):
		world.grid_visible = not world.grid_visible
		world.queue_redraw()
	elif event.is_action_pressed("toggle_access"):
		_toggle_access()
	elif event.is_action_pressed("toggle_power"):
		_toggle_power()
	elif event.is_action_pressed("center_camera"):
		_center_camera()
	elif event.is_action_pressed("cancel_stroke"):
		_cancel_stroke()
	elif event.is_action_pressed("display_settings"):
		_open_settings()
	elif event.is_action_pressed("zoom_in"):
		_zoom(1)
	elif event.is_action_pressed("zoom_out"):
		_zoom(-1)
	else:
		handled = false
	if handled: get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if _modal_open(): return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_stroke()
		elif _is_world_position(event.position):
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					_extend_stroke(world.cell_at(_view_position(event.position)))
				MOUSE_BUTTON_MIDDLE:
					panning = true
				MOUSE_BUTTON_WHEEL_UP:
					_zoom(1, _view_position(event.position))
				MOUSE_BUTTON_WHEEL_DOWN:
					_zoom(-1, _view_position(event.position))
	if event is InputEventMouseMotion and not stroke.is_empty() and _is_world_position(event.position):
		_extend_stroke(world.cell_at(_view_position(event.position)))

func _modal_open() -> bool:
	return settings != null and (settings.visible or help_dialog.visible or load_dialog.visible or quit_dialog.visible or recovery_dialog.visible)

func _is_world_position(point: Vector2) -> bool:
	if not world_rect.has_point(point) or _modal_open(): return false
	for panel in ui_panels:
		if panel.visible and panel.get_global_rect().has_point(point): return false
	return true

func _view_position(point: Vector2) -> Vector2:
	return (point - world_rect.position) / world_scale

func _extend_stroke(cell: Vector2i) -> void:
	if tool == "power":
		# One station per placement: the preview follows the pointer instead of painting.
		stroke.clear()
		stroke.append(cell)
	elif stroke.is_empty():
		stroke.append(cell)
	else:
		var current: Vector2i = stroke.back()
		# Orthogonal interpolation keeps roads connected across sparse pointer events.
		while current != cell and stroke.size() < city.width * city.height:
			if current.x != cell.x: current.x += signi(cell.x - current.x)
			else: current.y += signi(cell.y - current.y)
			if not stroke.has(current): stroke.append(current)
	_update_preview()

func _update_hover() -> void:
	var position_now: Vector2 = get_global_mouse_position()
	var next: Vector2i = world.cell_at(_view_position(position_now)) if _is_world_position(position_now) else Vector2i(-1,-1)
	if next != world.hover:
		world.hover = next
		_update_preview()
	if city.inside(next): inspected_cell = next
	_inspect_cell(inspected_cell)

func _inspect_cell(cell: Vector2i) -> void:
	_fit_inspector()
	if not city.inside(cell):
		selection_label.text = "%d × %d coastal map" % [city.width, city.height]
		access_label.text = "No boundary land for an outside link. Road access is unavailable."
		power_label.text = _power_text(cell)
		return
	inspected_cell = cell
	var i: int = city.index(cell)
	power_label.text = _power_text(cell)
	var land_use: String = "Water" if city.terrain[i] == City.WATER else ["Open ground", "Road", "Empty home zone", "Power station"][city.occupancy[i]]
	selection_label.text = "TILE %d, %d · %s" % [cell.x, cell.y, land_use]
	if city.access.root.x < 0:
		access_label.text = "No boundary land for an outside link. Road access is unavailable."
	elif cell == city.access.root:
		access_label.text = "Outside link active. Join roads along shared sides." if city.occupancy[i] == City.ROAD else "Outside link: clear this home plot, then lay a road here." if city.occupancy[i] == City.HOME else "Outside link inactive. Lay a road on this flagged tile."
	elif city.occupancy[i] == City.POWER:
		access_label.text = "Power works without the outside link. Stations do not carry road access."
	elif city.occupancy[i] == City.HOME:
		match city.access.home_reason(city, cell):
			"connected": access_label.text = "Road access connected. A road beside this plot reaches the outside link."
			"disconnected_road": access_label.text = "No road access. The road beside this plot must connect to the outside link."
			"no_outside_link": access_label.text = "No boundary land for an outside link. Road access is unavailable."
			_: access_label.text = "No road beside this plot. Add a road along a shared side, then connect it to the outside link."
	elif city.occupancy[i] == City.ROAD:
		access_label.text = "Road connected to the outside link." if city.access.connected_roads[i] != 0 else "Road disconnected. Join it to the flagged outside link along shared sides."
	else:
		access_label.text = "Water cannot be built on." if city.terrain[i] == City.WATER else "Place home plots beside connected roads. Diagonals do not provide access."

func _power_text(cell: Vector2i) -> String:
	var grid = city.power
	if not city.inside(cell) or city.terrain[city.index(cell)] == City.WATER:
		return ""
	var i: int = city.index(cell)
	var network: int = grid.network_of[i]
	match city.occupancy[i]:
		City.HOME:
			match grid.home_reason(city, cell):
				"powered": return "Powered. Network: %s." % _network_use(grid.home_network[i])
				"shortage": return "No power: its network is full (%d of %d units). Add a station; nearest plots are served first." % [grid.network_used[grid.home_network[i]], grid.network_capacity[grid.home_network[i]]]
				"disconnected": return "No power: the road beside this plot does not reach a power station."
				"no_source": return "No power station yet. Place one (P) beside a road that reaches this plot."
			return "No power: add a road beside this plot that reaches a power station."
		City.ROAD:
			if grid.carries_power(i): return "Carries power. Network: %s." % _network_use(network)
			return "No power station built yet." if grid.station_count == 0 else "No power station on this road network."
		City.POWER:
			return "Supplies %d units. Network: %s, %d station%s." % [Balance.POWER_CAPACITY, _network_use(network), grid.network_stations[network], "" if grid.network_stations[network] == 1 else "s"]
	return "Power stations (P) supply plots through the roads they touch."

func _network_use(network: int) -> String:
	var grid = city.power
	var text: String = "%d of %d units used" % [grid.network_used[network], grid.network_capacity[network]]
	var short: int = grid.network_short[network]
	return text + (", %d plot%s short" % [short, "" if short == 1 else "s"] if short > 0 else "")

func _update_legend() -> void:
	var parts: Array[String] = []
	parts.append("+/− road access" if world.access_visible else "road marks hidden (R)")
	parts.append("bolt/× power" if world.power_visible else "power marks hidden (E)")
	legend_label.text = "Marks: " + " · ".join(parts)

func _toggle_access() -> void:
	world.access_visible = not world.access_visible
	access_button.set_pressed_no_signal(world.access_visible)
	_update_legend()
	world.queue_redraw()

func _toggle_power() -> void:
	world.power_visible = not world.power_visible
	power_button.set_pressed_no_signal(world.power_visible)
	_update_legend()
	world.queue_redraw()

func _update_preview() -> void:
	var cells: Array[Vector2i] = stroke.duplicate()
	if cells.is_empty() and city.inside(world.hover): cells.append(world.hover)
	var result: Dictionary = city.preview(tool, cells)
	world.preview_cells = stroke.duplicate()
	world.preview_valid = bool(result.ok)
	if not result.ok:
		preview_label.text = String(result.message)
	elif tool == "power" and not result.changed.is_empty():
		preview_label.text = "%s for %d plots\n%s" % [Balance.money(int(result.cost)), Balance.POWER_CAPACITY, "Release to build" if not stroke.is_empty() else "Click to place"]
	elif not stroke.is_empty():
		preview_label.text = "Stroke: %s\nRelease to build" % Balance.money(int(result.cost))
	else:
		preview_label.text = "Cost: %s" % Balance.money(int(result.cost))
	world.queue_redraw()

func _commit_stroke() -> void:
	var result: Dictionary = city.apply_command(tool, stroke)
	if result.ok and not result.changed.is_empty():
		dirty = true
		print("COMMAND ", JSON.stringify(result.record))
	_status(String(result.message))
	_cancel_stroke()
	_refresh_metrics()
	world.queue_redraw()

func _cancel_stroke() -> void:
	stroke.clear()
	panning = false
	if world != null:
		world.preview_cells.clear()
		world.queue_redraw()
		if preview_label != null: _update_preview()

func _select_tool(kind: String) -> void:
	_cancel_stroke()
	tool = kind
	for key in tool_buttons:
		tool_buttons[key].set_pressed_no_signal(key == tool)
	_update_preview()

func _set_speed(value: int) -> void:
	speed = value
	last_usec = Time.get_ticks_usec()
	for key in speed_buttons:
		speed_buttons[key].set_pressed_no_signal(key == value)
	_refresh_metrics()

func _refresh_metrics() -> void:
	cash_label.text = Balance.money(city.cash)
	day_label.text = "Day %d\n%s" % [city.tick + 1, "Paused" if speed == 0 or focus_paused else "%dx speed" % speed]
	var grid = city.power
	grid_label.text = "Power %d / %d\n%s" % [grid.total_used, grid.total_capacity, "No stations" if grid.station_count == 0 else "%d plot%s short" % [grid.short_homes, "" if grid.short_homes == 1 else "s"] if grid.short_homes > 0 else "No shortage"]

func _status(message: String) -> void:
	status_label.text = message

func _zoom(change: int, anchor: Vector2 = Vector2(400,180)) -> void:
	_cancel_stroke()
	world.set_zoom(world.zoom + change, anchor)
	zoom_label.text = "%dx" % world.zoom

func _center_camera() -> void:
	_cancel_stroke()
	world.zoom = 1
	var target: Vector2i = city.access.root if city.access.root.x >= 0 else Vector2i(city.width / 2, city.height / 2)
	world.origin = Vector2(target) * World.TILE + Vector2.ONE * World.TILE / 2 - Vector2(400,140)
	world.clamp_camera()
	zoom_label.text = "1x"
	_inspect_cell(city.access.root)
	world.queue_redraw()

func _save_clicked() -> void:
	_save_city()

func _save_city() -> bool:
	_cancel_stroke()
	var result: Dictionary = store.save_city(city, SAVE_PATH)
	if result.ok: dirty = false
	_status(String(result.message))
	print("SAVE ", result.ok, " ", ProjectSettings.globalize_path(SAVE_PATH))
	return bool(result.ok)

func _load_clicked() -> void:
	_cancel_stroke()
	if dirty and FileAccess.file_exists(SAVE_PATH):
		load_dialog.popup_centered(Vector2i(520,180))
	else:
		_load_path(SAVE_PATH)

func _load_path(path: String) -> void:
	_cancel_stroke()
	var result: Dictionary = store.load_city(path)
	if not result.ok:
		_status(String(result.message) + " Current city unchanged.")
		if path == SAVE_PATH and store.load_city(SAVE_PATH + ".bak").ok:
			recovery_dialog.dialog_text = String(result.message) + "\n\nA previous valid backup is available. Load it instead?"
			recovery_dialog.popup_centered(Vector2i(620,220))
		return
	city = result.city
	world.city = city
	inspected_cell = city.access.root
	dirty = false
	_set_speed(0)
	world.clamp_camera()
	world.queue_redraw()
	_update_preview()
	var preserved_name: String = Store.preserved_path(path.trim_suffix(".bak"), maxi(1, int(result.get("migrated_from", 0)))).get_file()
	if int(result.get("migrated_from", 0)) > 0 and path.ends_with(".bak"):
		_status("Previous backup restored from earlier format %d. Save to make it current; earlier-format bytes are kept as %s before being replaced." % [result.migrated_from, preserved_name])
	elif int(result.get("migrated_from", 0)) > 0:
		_status("Earlier save format %d loaded; nothing was written. Saving updates it and keeps the original as %s." % [result.migrated_from, preserved_name])
	else:
		_status("Previous backup restored. Save to make it the current save." if path.ends_with(".bak") else "City restored. Time is paused; your layout and funds are intact.")
	if path.ends_with(".bak"): dirty = true
	print("LOAD ", path, " sequence=", city.sequence, " tick=", city.tick)

func _open_settings() -> void:
	_cancel_stroke()
	settings.popup_centered(Vector2i(680,360))

func _open_help() -> void:
	_cancel_stroke()
	help_dialog.popup_centered(Vector2i(680,560))

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		focus_paused = true
		_cancel_stroke()
		if day_label != null: _refresh_metrics()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		focus_paused = false
		last_usec = Time.get_ticks_usec()
		if day_label != null: _refresh_metrics()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_cancel_stroke()
		if dirty: quit_dialog.popup_centered(Vector2i(520,180))
		else: get_tree().quit()
