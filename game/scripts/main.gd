extends Control
const City = preload("res://scripts/sim/city_state.gd")
const Clock = preload("res://scripts/sim/simulation_clock.gd")
const Store = preload("res://scripts/persistence/save_store.gd")
const Balance = preload("res://content/balance.gd")
const World = preload("res://scripts/presentation/world_view.gd")
const Style = preload("res://scripts/presentation/ui_style.gd")
const Bindings = preload("res://scripts/input/input_bindings.gd")
const ArtKit = preload("res://scripts/presentation/art_kit.gd")
const Meter = preload("res://scripts/presentation/demand_meter.gd")
const Summary = preload("res://scripts/presentation/town_summary.gd")
const Guide = preload("res://scripts/presentation/opening_guide.gd")
const Calendar = preload("res://scripts/presentation/calendar.gd")
const Settings = preload("res://scripts/persistence/settings_store.gd")
const HistoryGraph = preload("res://scripts/presentation/history_graph.gd")
const AudioDirector = preload("res://scripts/presentation/audio_director.gd")
const SAVE_PATH: String = "user://saves/manual.json"
const SIZES: Array[Vector2i] = Settings.WINDOW_SIZES
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
## D30: the pressed tile of a lot run; strokes hold lot/station anchors for those tools.
var stroke_origin: Vector2i = Vector2i(-1, -1)
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
var population_label: Label
var demand_label: Label
## D32: glanceable H/S/W demand meter in the top bar.
var demand_meter: Meter
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
var budget_dialog: AcceptDialog
var budget_text: Label
var budget_button: Button
## D32: Budget dialog tax row.
var tax_label: Label
var tax_note: Label
var tax_buttons: Dictionary = {}
var project_dialog: AcceptDialog
var project_choice: OptionButton
var project_text: Label
var project_complete: Button
var project_show: Button
var project_button: Button
## D34: read-only town summary.
var summary_dialog: AcceptDialog
var summary_heading: Label
var summary_column: VBoxContainer
var summary_button: Button
var summary_items: Array = []
var summary_actions: Array[Button] = []
## D29: session-only First steps card.
var guide_panel: PanelContainer
var guide_heading: Label
var guide_text: Label
var guide_action: Button
var guide_hide: Button
var guide_visible: bool = true
var project_seen: bool = false
var guide_state: Dictionary = {}
var help_text: Label
var help_dialog: AcceptDialog
var load_dialog: ConfirmationDialog
var quit_dialog: ConfirmationDialog
var recovery_dialog: ConfirmationDialog
var font_size: int = 16
## D39: remembered settings, the window size chosen in Display, and the autosave period.
var settings_store: Settings = Settings.new()
var remembered_window: Array = []
var applying_settings: bool = false
var autosave_period: int = 0
var graphs_dialog: AcceptDialog
var graphs_view: HistoryGraph
var graphs_note: Label
## D40: sound, music and animation (presentation only).
var audio: AudioDirector
var animation_on: bool = true
var anim_clock: float = 0.0
var anim_since_draw: float = 0.0
var sound_dialog: AcceptDialog
var volume_labels: Dictionary = {}
var mute_toggle: CheckButton
var animation_toggle: CheckButton
## D41: gamepad route, Menu, prompts and remappable controls.
var pad_active: bool = false
var pad_cursor: Vector2i = Vector2i(-1, -1)
var pad_held: Vector2i = Vector2i.ZERO
var pad_repeat: float = 0.0
var bindings: Dictionary = Bindings.empty()
var prompt_panel: PanelContainer
var prompt_label: Label
var pad_menu: AcceptDialog
var controls_dialog: AcceptDialog
var controls_note: Label
var controls_rows: Dictionary = {}
var rebind_wait: Dictionary = {}
## [button, action, format] for buttons whose text names a remappable key.
var key_labels: Array = []
var modal_windows: Array[Window] = []
## D42: the fixed part of Help; a generated Your keys block goes above it.
var help_body: String = ""
const PAD_REPEAT_DELAY: float = 0.3
const PAD_REPEAT_RATE: float = 12.0

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
	audio = AudioDirector.new()
	add_child(audio)
	_build_ui()
	get_viewport().size_changed.connect(_layout_ui)
	_layout_ui()
	_select_tool("road")
	_set_speed(0)
	_center_camera()
	_inspect_cell(city.access.root)
	# Modern City artwork is the default (U23); an optional launch argument such as
	# -- --art=original or -- --art=tiny_city selects another mode.
	world.set_art(ArtKit.DEFAULT_MODE)
	_apply_settings()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--art="): world.set_art(argument.trim_prefix("--art="))
	autosave_period = city.tick / Store.AUTOSAVE_DAYS
	last_usec = Time.get_ticks_usec()
	_status("Begin at the gold flag: lay a road on its tile, zone 3x3 residential lots beside connected streets, then add a 4x4 power plant (P) beside a street.")

func _build_ui() -> void:
	top = _panel()
	var row := HBoxContainer.new()
	top.add_child(row)
	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 0)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(heading)
	population_label = _label("", 18)
	demand_label = _label("", 14, Style.MUTED)
	heading.add_child(population_label)
	demand_meter = Meter.new()
	heading.add_child(demand_meter)
	heading.add_child(demand_label)
	demand_label.tooltip_text = "Tax rate and this month's forecast net (income minus upkeep). Open Budget [B] to change the rate."
	cash_label = _label("", 21)
	cash_label.custom_minimum_size.x = 178
	var funds := VBoxContainer.new()
	funds.add_theme_constant_override("separation", 4)
	row.add_child(funds)
	funds.add_child(cash_label)
	budget_button = _button("Budget [B]", _open_budget)
	key_labels.append([budget_button, "show_budget", "Budget [%s]"])
	budget_button.add_theme_font_size_override("font_size", 14)
	for style_name in ["normal", "hover", "pressed", "focus"]:
		var compact: StyleBox = theme.get_stylebox(style_name, "Button").duplicate()
		compact.content_margin_top = 2
		compact.content_margin_bottom = 2
		budget_button.add_theme_stylebox_override(style_name, compact)
	var town_actions := HBoxContainer.new()
	funds.add_child(town_actions)
	town_actions.add_child(budget_button)
	project_button = _button("Project [J]", _open_project)
	key_labels.append([project_button, "show_project", "Project [%s]"])
	project_button.add_theme_font_size_override("font_size", 14)
	town_actions.add_child(project_button)
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
	for entry in [["road", "1  Roads · $10"], ["home", "2  Residential · $25"], ["shop", "6  Commercial · $25"], ["workshop", "7  Industrial · $25"], ["power", "P  Power plant · " + power_price], ["park", "8 Park"], ["police", "9 Police"], ["fire", "0 Fire"], ["clear", "3  Clear · free"]]:
		var kind: String = entry[0]
		var button := _button(entry[1], func(): _select_tool(kind))
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 30
		match kind:
			"park": button.tooltip_text = "$100 · One park; $10/month. Residential and commercial lots within 3 side-steps gain +2 land value: they grow first and it offsets one nearby industrial lot. Overlap does not stack."
			"police", "fire": button.tooltip_text = Balance.money(Balance.POLICE_COST if kind == "police" else Balance.FIRE_COST).trim_suffix(".00") + (" · One 3x3 %s station; %s/month. With road access and power it covers lots within %d steps. Level 4 needs police and fire cover." % [kind, Balance.money(Balance.POLICE_UPKEEP if kind == "police" else Balance.FIRE_UPKEEP).trim_suffix(".00"), Balance.SERVICE_RADIUS])
			"clear": button.tooltip_text = "Clear is free, with no refund."
			"power": button.tooltip_text = "One 4x4 power plant per placement. It supplies %d zone lots through the roads it touches, including empty lots." % Balance.POWER_CAPACITY
			"road": button.tooltip_text = "Price per tile; identical repainting is free."
			_: button.tooltip_text = "Price per 3x3 lot; drag to lay a row of lots. Identical repainting is free."
		# D38: park, police and fire share one row so the sidebar keeps its height at
		# 720p; their prices are in the tooltips and the placement preview.
		if kind in ["park", "police", "fire"]:
			if kind == "park":
				var civic_row := HBoxContainer.new()
				civic_row.add_theme_constant_override("separation", 4)
				column.add_child(civic_row)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.alignment = HORIZONTAL_ALIGNMENT_CENTER
			column.get_child(column.get_child_count() - 1).add_child(button)
		else:
			column.add_child(button)
		tool_buttons[kind] = button
		var label_text: String = entry[1]
		var gap: String = "  " if label_text.contains("  ") else " "
		key_labels.append([button, "tool_" + kind, "%s" + gap + label_text.substr(label_text.find(gap) + gap.length())])
	column.add_child(HSeparator.new())
	var outside_button := _button("Link [Home]", _center_camera)
	key_labels.append([outside_button, "center_camera", "Link [%s]"])
	var navigation := HBoxContainer.new()
	column.add_child(navigation)
	outside_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.add_child(outside_button)
	navigation.add_child(_button("−", func(): _zoom(-1)))
	navigation.add_child(_button("+", func(): _zoom(1)))
	var marks := HBoxContainer.new()
	marks.add_theme_constant_override("separation", 6)
	column.add_child(marks)
	access_button = _button("Road [R]", _toggle_access)
	key_labels.append([access_button, "toggle_access", "Road [%s]"])
	access_button.tooltip_text = "Road access marks: + connected / − missing"
	power_button = _button("Power [E]", _toggle_power)
	key_labels.append([power_button, "toggle_power", "Power [%s]"])
	power_button.tooltip_text = "Power marks: bolt powered / × unpowered lot"
	for toggle: Button in [access_button, power_button]:
		toggle.toggle_mode = true
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		marks.add_child(toggle)
	access_button.set_pressed_no_signal(world.access_visible)
	power_button.set_pressed_no_signal(world.power_visible)
	var display_button := _button("Display", _open_settings)
	display_button.tooltip_text = "Window size and text size (F6)"
	var help_button := _button("Help", _open_help)
	help_button.tooltip_text = "Controls and growth rules"
	for button: Button in [outside_button, access_button, power_button, display_button, help_button, project_button] + tool_buttons.values():
		for style_name in ["normal", "hover", "pressed", "focus"]:
			var compact: StyleBox = theme.get_stylebox(style_name, "Button").duplicate()
			compact.content_margin_top = 4
			compact.content_margin_bottom = 4
			if button == access_button or button == power_button or button in [tool_buttons.park, tool_buttons.police, tool_buttons.fire]:
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
	zoom_label = _label("1x", 16)
	zoom_label.visible = false
	column.add_child(zoom_label)
	var options := HBoxContainer.new()
	column.add_child(options)
	for button in [display_button, help_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		options.add_child(button)
	inspector = _panel()
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 6)
	inspector.add_child(details)
	selection_label = _label("", 16)
	access_label = _label("", 16, Style.ACCENT)
	power_label = _label("", 16, Style.ACCENT)
	legend_label = _label("", 14, Style.MUTED)
	scope_label = _label("", 16, Style.MUTED)
	for label: Label in [selection_label, access_label, power_label, legend_label, scope_label]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# Establish wrapping width before the first container layout; a zero-width
		# label otherwise requests a very tall panel on native startup.
		label.custom_minimum_size.x = 348
		details.add_child(label)
	power_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_update_legend()
	bottom = _panel()
	var footer := HBoxContainer.new()
	bottom.add_child(footer)
	status_label = _label("", 15)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(status_label)
	summary_button = _button("Town summary [T]", _open_summary)
	key_labels.append([summary_button, "show_summary", "Town summary [%s]"])
	summary_button.tooltip_text = "The biggest measurable causes holding the town back, with where to look."
	summary_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	summary_button.add_theme_font_size_override("font_size", 14)
	for style_name in ["normal", "hover", "pressed", "focus"]:
		var compact: StyleBox = theme.get_stylebox(style_name, "Button").duplicate()
		compact.content_margin_top = 3
		compact.content_margin_bottom = 3
		summary_button.add_theme_stylebox_override(style_name, compact)
	footer.add_child(summary_button)
	_build_guide()
	# D41: gamepad prompts below the top bar, shown only while the gamepad is in use.
	prompt_panel = _panel()
	prompt_panel.visible = false
	prompt_label = _label("South build · East cancel · LB/RB tool · LT/RT zoom · West speed · North summary · Back menu", 14)
	prompt_panel.add_child(prompt_label)
	_build_dialogs()
	# D41: every dialog suspends time and puts focus on a button when it opens.
	for window: AcceptDialog in [settings, project_dialog, summary_dialog, budget_dialog, help_dialog, load_dialog, quit_dialog, recovery_dialog, graphs_dialog, sound_dialog, pad_menu, controls_dialog]:
		modal_windows.append(window)
		var target: AcceptDialog = window
		window.visibility_changed.connect(func(): if target.visible: _focus_dialog.call_deferred(target))
		# Dialogs take their own input: East closes them (Back also closes the Menu),
		# except while a Controls row is waiting for a button.
		window.window_input.connect(func(event: InputEvent): _dialog_pad_input(target, event))
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
		sizes.add_child(_button("%d × %d" % [resolution.x,resolution.y], func():
			DisplayServer.window_set_size(resolution)
			remembered_window = [resolution.x, resolution.y]
			_remember_settings()))
	column.add_child(_label("Interface text", 18))
	var texts := HBoxContainer.new()
	column.add_child(texts)
	for amount in [16,18,20]:
		texts.add_child(_button("Standard" if amount == 16 else "Larger" if amount == 18 else "Largest", func(): _set_text_size(amount)))
	column.add_child(_label("Artwork (Modern City default; Original fallback)", 18))
	var arts := HBoxContainer.new()
	column.add_child(arts)
	for mode in ArtKit.MODES:
		arts.add_child(_button(ArtKit.LABELS[mode], func(): _set_art(mode)))
	column.add_child(_button("Toggle grid  [G]", _toggle_grid))
	column.add_child(_button("Land value overlay  [V]", _toggle_desirability))
	column.add_child(_button("Services overlay  [C]", _toggle_services))
	# D40: Center view and Sound & motion share a row so Display still fits 720p.
	var extras := HBoxContainer.new()
	extras.add_theme_constant_override("separation", 8)
	column.add_child(extras)
	for button: Button in [_button("Center view  [Home]", _center_camera), _button("Sound & motion…", _open_sound), _button("Controls…", _open_controls)]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		extras.add_child(button)
	column.add_child(_label("Pixel world stays crisp; interface text scales separately.", 15, Style.MUTED))
	help_dialog = AcceptDialog.new()
	help_dialog.title = "Controls & notes"
	help_text = _label("1 Roads · 2 Residential · 6 Commercial · 7 Industrial\nP Power plant · 8 Park · 9 Police · 0 Fire · 3 Clear · B Budget\nT Town summary: the biggest causes holding the town back.\nH Graphs: residents, jobs and funds month by month.\nM mutes or unmutes; Display > Sound & motion sets volumes and animation.\nKeys shown here are the defaults; Display > Controls changes keys and buttons.\nGamepad: stick / d-pad cursor, South build, East cancel, LB/RB tool,\nLT/RT zoom, right stick pan, Start pause, West speed, North summary,\nBack menu (every dialog and command), L3 back to the link.\nF1 shows or hides the First steps card.\nJ Project: a square with three serviced residential lots.\nZones and police/fire stations are 3x3; power plants are 4x4. Clear removes a whole lot.\nDrag builds; right click / Escape cancels.\nWASD / arrows / middle drag pan; wheel / + / − zoom.\nSpace pauses; 4 / 5 normal / fast; Home returns to the link.\nCtrl+S / Ctrl+L save / load; R / E road / power marks.\nV land value overlay · C services overlay.\nDemand meter: R residential, C commercial, I industrial.\nDates run in 30-day months from 1 Jan 1950.\n\nJoin roads from the gold flag; zone beside them.\nAdd a power plant: 20 lots, even empty ones, nearest first.\nEvery 5 days, serviced lots with demand can gain a level (0-4).\nLevels 3-4 hold far more; they need land value 1 / 2\n(commercial 3 / 4); industry needs 100 / 250 residents. Plain streets stop at level 2.\nLevel 4 also needs police and fire cover: a station with road\naccess and power covers lots within 12 steps ($30/month each).\nStarter demand supports 12 residents before jobs exist.\nTwo rounds without road access or power lose a level.\nReconnect or add capacity to recover.\n\nLand value: park within 3 +2, water within 3 +1,\neach developed industrial lot within 2 steps −2 (up to 3).\nCommercial: +1 per developed residential lot within 3 (up to 2).\nResidential and commercial: higher grows first;\nbelow 0 a lot stops at level 1.\nIndustry ignores land value: nearest the link (by road) grows first.\nParks add no extra demand.\nBudget settles every 30 days after growth. B shows costs.\nTax rate (Budget, 0-25%, standard 10%): lower attracts\ngrowth but raises less; above 10% surplus levels leave.\nClear surplus facilities for free to reduce a deficit.\nNo debt: unpaid costs are waived; services stay on.\nSave manually; Load after restarting. Every 60 days of play\nthe game also autosaves to one of 3 slots (Load > Load autosave);\nautosaves never replace your manual save.\nDisplay, text, art, overlays and the First steps choice are remembered.", 16)
	add_child(help_dialog)
	help_body = help_text.text
	help_dialog.add_button("Show first steps", false, "guide")
	help_dialog.add_button("Open save folder", false, "saves")
	help_dialog.custom_action.connect(func(action: String):
		if action == "guide":
			help_dialog.hide()
			_set_guide_visible(true, true)
		elif action == "saves":
			_open_save_folder())
	var help_scroll := ScrollContainer.new()
	help_scroll.custom_minimum_size = Vector2(640, 440)
	help_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	help_dialog.add_child(help_scroll)
	help_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help_scroll.add_child(help_text)
	_build_project_dialog()
	_build_summary_dialog()
	budget_dialog = AcceptDialog.new()
	budget_dialog.title = "Monthly budget"
	add_child(budget_dialog)
	budget_dialog.add_button("Graphs [H]", false, "graphs")
	budget_dialog.custom_action.connect(func(action: String):
		if action == "graphs": _open_graphs())
	var budget_column := VBoxContainer.new()
	budget_dialog.add_child(budget_column)
	var tax_row := HBoxContainer.new()
	budget_column.add_child(tax_row)
	tax_label = _label("", 18)
	tax_label.custom_minimum_size.x = 170
	tax_row.add_child(tax_label)
	for entry in [["lower", "−  Lower", -1], ["raise", "+  Raise", 1]]:
		var step: int = entry[2]
		var button := _button(entry[1], func(): _set_tax(city.tax_rate + step))
		tax_row.add_child(button)
		tax_buttons[entry[0]] = button
	tax_buttons["standard"] = _button("Standard %d%%" % Balance.TAX_STANDARD, func(): _set_tax(Balance.TAX_STANDARD))
	tax_row.add_child(tax_buttons.standard)
	tax_note = _label("", 15, Style.MUTED)
	tax_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tax_note.custom_minimum_size.x = 700
	budget_column.add_child(tax_note)
	budget_column.add_child(HSeparator.new())
	var budget_scroll := ScrollContainer.new()
	budget_scroll.custom_minimum_size = Vector2(700, 330)
	budget_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	budget_column.add_child(budget_scroll)
	budget_text = _label("", 16)
	budget_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	budget_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	budget_scroll.add_child(budget_text)
	load_dialog = ConfirmationDialog.new()
	load_dialog.title = "Load saved city?"
	load_dialog.dialog_text = "Replace your unsaved layout with the saved city?"
	load_dialog.get_ok_button().text = "Load city"
	load_dialog.confirmed.connect(func(): _load_path(SAVE_PATH))
	load_dialog.add_button("Load autosave", false, "autosave")
	load_dialog.custom_action.connect(func(action: String):
		if action == "autosave":
			load_dialog.hide()
			_load_autosave())
	add_child(load_dialog)
	_build_graphs_dialog()
	_build_sound_dialog()
	_build_pad_menu()
	_build_controls_dialog()

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
	var inspector_width: int = 380 if font_size == 16 else 480 if font_size == 18 else 520
	var inspector_height: int = 320
	for label: Label in [selection_label, access_label, power_label, legend_label, scope_label]:
		label.custom_minimum_size.x = inspector_width - 32
	inspector_target = Rect2(Vector2(available.x - inspector_width - 16, bottom.position.y - inspector_height - 12), Vector2(inspector_width, inspector_height))
	_fit_inspector()
	_layout_guide()
	_layout_prompts()
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
	demand_meter.set_font_size(14 + (amount - 16) / 2)
	_refresh_guide()
	_layout_ui()
	_status("Interface text updated.")
	_remember_settings()

func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	var elapsed: int = now - last_usec
	last_usec = now
	if not focus_paused and not _modal_open():
		var levels_before: int = _total_levels()
		var settled_before: int = int(city.last_budget.get("tick", 0))
		if Clock.advance(city, elapsed, speed) > 0:
			_sound_after_time(levels_before, settled_before)
			dirty = true
			_refresh_metrics()
			world.queue_redraw()
			_maybe_autosave()
		var direction := Vector2.ZERO
		for action in PAN_VECTORS:
			if Input.is_action_pressed(action, true): direction += PAN_VECTORS[action]
		# D41: the right stick pans through the same actions (analog, so not exact-matched).
		if direction == Vector2.ZERO and pad_active:
			direction = Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
		if direction != Vector2.ZERO and not Input.is_physical_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_CTRL):
			world.pan_pixels(direction.normalized() * 360 * minf(float(elapsed) / 1_000_000, 0.1))
	if not focus_paused and not _modal_open(): _pad_cursor_step(float(elapsed) / 1_000_000.0)
	_update_hover()
	_animate(float(elapsed) / 1_000_000.0)

## D40: real-time animation clock; about ten redraws a second while animation is on.
func _animate(seconds: float) -> void:
	if not animation_on or world == null: return
	anim_clock = fmod(anim_clock + clampf(seconds, 0.0, 0.5), 1200.0)
	anim_since_draw += seconds
	if anim_since_draw >= 0.1:
		anim_since_draw = 0.0
		world.anim_time = anim_clock
		world.queue_redraw()

func _total_levels() -> int:
	return city.growth.levels[City.HOME] + city.growth.levels[City.SHOP] + city.growth.levels[City.WORKSHOP]

## D40: one grow chime when a round raised the town's levels; a bell for a deficit month.
func _sound_after_time(levels_before: int, settled_before: int) -> void:
	if int(city.last_budget.get("tick", 0)) != settled_before and City.Economy.totals(city.last_budget).net < 0:
		audio.play("alert")
	elif _total_levels() > levels_before:
		audio.play("grow")

func _input(event: InputEvent) -> void:
	# D41: a Controls row waiting for a new key or button takes the next press.
	if not rebind_wait.is_empty():
		if _capture_rebind(event): get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) >= Bindings.DEADZONE):
		_set_pad_active(true)
		if not _modal_open():
			if _pad_input(event): get_viewport().set_input_as_handled()
		elif event.is_action_pressed("pad_menu") and pad_menu.visible:
			pad_menu.hide()
			get_viewport().set_input_as_handled()
		return
	if (event is InputEventMouseMotion and event.relative.length() > 0.5) or (event is InputEventKey and event.pressed) or event is InputEventMouseButton:
		_set_pad_active(false)
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
	for kind in ["road", "home", "shop", "workshop", "power", "park", "police", "fire", "clear"]:
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
		_toggle_grid()
	elif event.is_action_pressed("toggle_access"):
		_toggle_access()
	elif event.is_action_pressed("toggle_power"):
		_toggle_power()
	elif event.is_action_pressed("toggle_desirability"):
		_toggle_desirability()
	elif event.is_action_pressed("toggle_services"):
		_toggle_services()
	elif event.is_action_pressed("center_camera"):
		_center_camera()
	elif event.is_action_pressed("cancel_stroke"):
		_cancel_stroke()
	elif event.is_action_pressed("show_project"):
		_open_project()
	elif event.is_action_pressed("show_summary"):
		_open_summary()
	elif event.is_action_pressed("show_graphs"):
		_open_graphs()
	elif event.is_action_pressed("toggle_mute"):
		_set_muted(not audio.muted)
	elif event.is_action_pressed("toggle_guide"):
		_set_guide_visible(not guide_visible, true)
	elif event.is_action_pressed("show_budget"):
		_open_budget()
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
	for window in modal_windows:
		if window.visible: return true
	return false

func _is_world_position(point: Vector2) -> bool:
	if not world_rect.has_point(point) or _modal_open(): return false
	for panel in ui_panels:
		if panel.visible and panel.get_global_rect().has_point(point): return false
	return true

func _view_position(point: Vector2) -> Vector2:
	return (point - world_rect.position) / world_scale

func _extend_stroke(cell: Vector2i) -> void:
	if tool in ["home", "shop", "workshop"]:
		# D30: a straight run of adjacent lots along the drag's dominant axis.
		if stroke.is_empty(): stroke_origin = cell
		stroke.clear()
		var size: int = Balance.LOT_SIZE
		var delta: Vector2i = cell - stroke_origin
		var step := Vector2i(signi(delta.x), 0) if absi(delta.x) >= absi(delta.y) else Vector2i(0, signi(delta.y))
		var steps: int = (absi(delta.x) if step.y == 0 else absi(delta.y)) / size
		for k in range(steps + 1):
			stroke.append(_command_cell(stroke_origin) + step * size * k)
	elif tool in ["power", "park", "police", "fire"]:
		# One facility per placement: the preview follows the pointer instead of painting.
		stroke.clear()
		stroke.append(_command_cell(cell))
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
	if pad_active: next = pad_cursor
	if next != world.hover:
		world.hover = next
		_update_preview()
	if city.inside(next): inspected_cell = next
	_inspect_cell(inspected_cell)

func _inspect_cell(cell: Vector2i) -> void:
	_fit_inspector()
	scope_label.text = _growth_text(cell)
	_update_legend(cell)
	if not city.inside(cell):
		selection_label.text = "%d × %d coastal map" % [city.width, city.height]
		access_label.text = "No boundary land for an outside link. Road access is unavailable."
		power_label.text = _power_text(cell)
		return
	inspected_cell = cell
	var i: int = city.index(cell)
	power_label.text = _power_text(cell)
	var land_use: String = "Water" if city.terrain[i] == City.WATER else ["Open ground", "Road", "Residential lot", "Power plant", "Commercial lot", "Industrial lot", "Pocket park", "Police station", "Fire station"][city.occupancy[i]]
	if City.is_zone(city.occupancy[i]):
		var a: int = city.footprint_owner[i]
		land_use += " L%d · %d %s" % [city.development[a], Balance.capacity(city.occupancy[i], city.development[a]), "residents" if city.occupancy[i] == City.HOME else "jobs"]
	selection_label.text = "TILE %d, %d · %s" % [cell.x, cell.y, land_use]
	if city.access.root.x < 0:
		access_label.text = "No boundary land for an outside link. Road access is unavailable."
	elif cell == city.access.root:
		access_label.text = "Outside link active. Join roads along shared sides." if city.occupancy[i] == City.ROAD else "Outside link: clear this zone, then lay a road here." if City.is_zone(city.occupancy[i]) else "Outside link inactive. Lay a road on this flagged tile."
	elif city.occupancy[i] == City.PARK:
		access_label.text = "Covers residential lots within 3 side-steps. Overlap does not stack."
	elif city.occupancy[i] == City.POWER:
		access_label.text = "Power works without the outside link. Power plants do not carry road access."
	elif City.is_served(city.occupancy[i]):
		match city.access.home_reason(city, cell):
			"connected": access_label.text = "Road access connected to the outside link."
			"disconnected_road": access_label.text = "No road access. Join this street to the outside link."
			"no_outside_link": access_label.text = "No boundary land for an outside link. Road access is unavailable."
			_: access_label.text = "No road beside this lot. Add one and join it to the outside link."
	elif city.occupancy[i] == City.ROAD:
		access_label.text = "Road connected to the outside link." if city.access.connected_roads[i] != 0 else "Road disconnected. Join it to the flagged outside link along shared sides."
	else:
		access_label.text = "Water cannot be built on." if city.terrain[i] == City.WATER else "Place zones beside connected roads. Diagonals do not provide access."

func _growth_text(cell: Vector2i) -> String:
	if city.tick >= City.MAX_TICK: return "Calendar limit reached. Growth is stopped."
	var next_day: int = city.tick + Balance.GROWTH_DAYS - city.tick % Balance.GROWTH_DAYS + 1
	if city.inside(cell) and city.occupancy[city.index(cell)] == City.PARK:
		if city.project.completed and int(city.project.park_index) == city.index(cell):
			return "Project completed. Flowers only; park priority unchanged. Upkeep $10/month."
		return "Residential and commercial lots within 3 steps gain +2 land value: they grow first and it offsets one industrial lot. No extra demand. Upkeep $10/month."
	if city.inside(cell) and City.is_civic(city.occupancy[city.index(cell)]):
		return _station_text(city.anchor_at(cell))
	if not city.inside(cell) or not City.is_zone(city.occupancy[city.index(cell)]):
		return "Next growth: %s. Zones need road access, power and demand." % Calendar.date(next_day - 1)
	var i: int = city.anchor_at(cell)
	var kind: int = city.occupancy[i]
	var wanted: String = "Demand −%d (taxes)" % city.growth.surplus[kind] if city.growth.surplus[kind] > 0 else "Demand %d" % city.growth.demand[kind]
	var prefix: String = "%s · next check %s\n" % [wanted, Calendar.date(next_day - 1)]
	match city.growth.reason(city, i):
		"growing": return prefix + "Ready to gain one level."
		"queued": return prefix + ("Waiting turn; nearer the link grows first." if kind == City.WORKSHOP else "Waiting turn; higher land value grows first.")
		"demand": return prefix + "Demand met. More residents support jobs; jobs support residents."
		"full": return prefix + "Fully developed (level %d)." % Balance.MAX_LEVEL
		"leaving": return prefix + "High taxes: loses a level next check. Lower the rate to keep it."
		"held": return prefix + "Held at L1 by industry: add a park or move it."
		"gated":
			var next: int = city.development[i] + 1
			if kind == City.WORKSHOP:
				return prefix + "L%d needs %d residents in town (now %d)." % [next, Balance.WORKFORCE_LEVEL4 if next >= 4 else Balance.WORKFORCE_LEVEL3, city.growth.population]
			return prefix + "L%d needs land value %d (now %d): %s." % [next, Balance.value_needed(kind, next), city.desirability.lot_score[i], "park or residents" if kind == City.SHOP else "park or water"]
		"uncovered": return prefix + "L4 needs police and fire cover (missing %s)." % city.services.missing(i)
		"dropping":
			var cap: int = city.desirability.cap(city, i)
			if cap <= Balance.HELD_LEVEL: return prefix + "Drops to L1 next check (industry): add a park."
			if city.desirability.value_cap(city, i) > cap: return prefix + "Drops to L%d next check: needs police and fire cover." % cap
			return prefix + "Drops to L%d next check: %s." % [cap, "too few residents" if kind == City.WORKSHOP else "land value too low"]
		"surplus": return prefix + "Taxes above %d%%: more levels may leave." % Balance.TAX_STANDARD
		"declining": return prefix + "Loses a level in %d check(s) unless services return." % (Balance.DECLINE_ROUNDS - city.service_loss[i])
	return prefix + "Waiting for road access and power."

## D38: a police or fire station's state, reach and covered lots.
func _station_text(anchor: int) -> String:
	var name: String = "police" if city.occupancy[anchor] == City.POLICE else "fire"
	var upkeep: String = Balance.money(Balance.POLICE_UPKEEP if name == "police" else Balance.FIRE_UPKEEP).trim_suffix(".00")
	if city.services.working[anchor] == 0:
		var needs: Array[String] = []
		if city.access.served_homes[anchor] == 0: needs.append("road access")
		if city.power.home_state[anchor] != city.power.POWERED: needs.append("power")
		return "Not working: needs %s. Upkeep %s/month." % [" and ".join(needs), upkeep]
	var lots: int = city.services.station_lots[anchor]
	return "Working: %s cover for %d lot%s within %d steps. Level 4 needs police and fire. Upkeep %s/month." % [name.capitalize(), lots, "" if lots == 1 else "s", Balance.SERVICE_RADIUS, upkeep]

func _power_text(cell: Vector2i) -> String:
	var grid = city.power
	if not city.inside(cell) or city.terrain[city.index(cell)] == City.WATER:
		return ""
	var i: int = city.index(cell)
	var network: int = grid.network_of[i]
	match city.occupancy[i]:
		City.HOME, City.SHOP, City.WORKSHOP, City.POLICE, City.FIRE:
			match grid.home_reason(city, cell):
				"powered": return "Powered. Network: %s." % _network_use(grid.home_network[city.footprint_owner[i]])
				"shortage": return "No power: network full (%d/%d). Add a plant; nearest lots get power first." % [grid.network_used[grid.home_network[city.footprint_owner[i]]], grid.network_capacity[grid.home_network[city.footprint_owner[i]]]]
				"disconnected": return "No power: the road beside this lot does not reach a power plant."
				"no_source": return "No power plant yet. Place one (P) beside a road that reaches this lot."
			return "No power: add a road beside this lot that reaches a power plant."
		City.ROAD:
			if grid.carries_power(i): return "Carries power. Network: %s." % _network_use(network)
			return "No power plant built yet." if grid.station_count == 0 else "No power plant on this road network."
		City.PARK:
			return "Needs no services; carries no roads or power."
		City.POWER:
			return "Supplies %d units. Network: %s, %d plant%s." % [Balance.POWER_CAPACITY, _network_use(network), grid.network_stations[network], "" if grid.network_stations[network] == 1 else "s"]
	return "Power plants (P) supply lots through the roads they touch."

func _network_use(network: int) -> String:
	var grid = city.power
	var text: String = "%d of %d units used" % [grid.network_used[network], grid.network_capacity[network]]
	var short: int = grid.network_short[network]
	return text + (", %d lot%s short" % [short, "" if short == 1 else "s"] if short > 0 else "")

func _update_legend(cell: Vector2i = inspected_cell) -> void:
	var parts: Array[String] = []
	parts.append("+/− road access" if world.access_visible else "road marks hidden (R)")
	parts.append("bolt/× power" if world.power_visible else "power marks hidden (E)")
	legend_label.text = "Marks: " + " · ".join(parts)
	if world.desirability_visible:
		legend_label.text = "Land value: + raises · hatching lowers (V)"
	if world.services_visible:
		legend_label.text = "Services (C): square police · triangle fire · × not working"
	# D33/D36: a lot's legend line lists its land-value parts, or industry's freight;
	# D38: with the Services overlay on, its police and fire cover instead.
	var a: int = city.anchor_at(cell)
	if a >= 0 and world.services_visible and City.is_zone(city.occupancy[a]):
		legend_label.text = "Services (C): " + city.services.cover_text(a)
		return
	if a >= 0 and (city.occupancy[a] == City.HOME or city.occupancy[a] == City.SHOP):
		var lot_parts: String = city.desirability.parts(city, a)
		var band: String = city.desirability.wealth(city, a)
		legend_label.text = "Land value %s%s: %s" % [Meter.signed(city.desirability.lot_score[a]), "" if band.is_empty() else " (%s)" % band, "nothing nearby" if lot_parts.is_empty() else lot_parts]
	elif a >= 0 and city.occupancy[a] == City.WORKSHOP:
		var steps: int = city.desirability.lot_freight[a]
		legend_label.text = ("Freight %d road step%s · ignores land value" % [steps, "" if steps == 1 else "s"]) if steps >= 0 else "Freight: not joined to the link · ignores land value"


func _toggle_access() -> void:
	world.access_visible = not world.access_visible
	access_button.set_pressed_no_signal(world.access_visible)
	_update_legend()
	world.queue_redraw()
	_remember_settings()

func _toggle_grid() -> void:
	world.grid_visible = not world.grid_visible
	world.queue_redraw()
	_remember_settings()

## D33: presentation only; the overlay state is never saved.
func _toggle_desirability() -> void:
	world.desirability_visible = not world.desirability_visible
	world.queue_redraw()
	_update_legend()
	_remember_settings()
	_status("Land value overlay on: + marks raise it (park +2, water +1); hatching lowers it (each developed industrial lot within 2 steps −2). Residential and commercial lots below 0 stop at level 1." if world.desirability_visible else "Land value overlay off (V).")

## D38: presentation only; the overlay state is never saved.
func _toggle_services() -> void:
	world.services_visible = not world.services_visible
	world.queue_redraw()
	_update_legend()
	_remember_settings()
	_status(("Services overlay on: a square marks police cover, a triangle fire cover, within %d steps of a working station. Level 4 needs both; × marks a station without road access or power." % Balance.SERVICE_RADIUS) if world.services_visible else "Services overlay off (C).")

func _toggle_power() -> void:
	world.power_visible = not world.power_visible
	power_button.set_pressed_no_signal(world.power_visible)
	_update_legend()
	world.queue_redraw()
	_remember_settings()

## Lots and stations are addressed by their top-left anchor; the pointer is at offset (1, 1).
func _command_cell(pointer: Vector2i) -> Vector2i:
	return pointer - Vector2i(1, 1) if City.is_footprint_kind(City.TOOLS[tool]) else pointer

func _update_preview() -> void:
	var cells: Array[Vector2i] = stroke.duplicate()
	if cells.is_empty() and city.inside(world.hover): cells.append(_command_cell(world.hover))
	var result: Dictionary = city.preview(tool, cells)
	var highlight: Dictionary = {}
	var size: int = City.footprint_size(City.TOOLS[tool])
	for cell in cells:
		if size > 1:
			for i in city.footprint_cells(city.index(cell), size) if city.inside(cell) else PackedInt32Array():
				highlight[city.cell_of(i)] = true
			# A footprint hanging off the map is drawn only where it covers the map.
			if not city.inside(cell):
				for y in range(size):
					for x in range(size):
						if city.inside(cell + Vector2i(x, y)): highlight[cell + Vector2i(x, y)] = true
		else:
			highlight[cell] = true
	for i in result.changed: highlight[city.cell_of(int(i))] = true
	world.preview_cells.assign(highlight.keys())
	world.preview_valid = bool(result.ok)
	if not result.ok:
		preview_label.text = String(result.message)
	elif tool == "power" and not result.changed.is_empty():
		preview_label.text = "%s for %d lots\n%s" % [Balance.money(int(result.cost)), Balance.POWER_CAPACITY, "Release to build" if not stroke.is_empty() else "Click to place"]
	elif (tool == "police" or tool == "fire") and not result.changed.is_empty():
		preview_label.text = "%s · covers %d steps\n%s" % [Balance.money(int(result.cost)), Balance.SERVICE_RADIUS, "Release to build" if not stroke.is_empty() else "Click to place"]
	elif not stroke.is_empty() and size > 1 and tool in ["home", "shop", "workshop"]:
		preview_label.text = "%d lot%s: %s\nRelease to build" % [result.anchors.size(), "" if result.anchors.size() == 1 else "s", Balance.money(int(result.cost))]
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
		audio.play("clear" if tool == "clear" else "build")
	elif not result.ok:
		audio.play("reject")
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
	population_label.text = "Residents %d · Jobs %d" % [city.growth.population, city.growth.jobs]
	var forecast: Dictionary = City.Economy.totals(city.budget)
	demand_label.text = "Tax %d%% · Net %s%s" % [city.tax_rate, Balance.money(forecast.net), " · DEFICIT" if forecast.net < 0 else ""]
	demand_meter.set_values(meter_values())
	_refresh_guide()
	budget_button.tooltip_text = "Current forecast; changes with services and development. Next settlement: %s." % Calendar.date(city.tick + 30 - city.tick % 30)
	day_label.text = "%s\n%s" % [Calendar.date(city.tick), "Paused" if speed == 0 or focus_paused else "%dx speed" % speed]
	var grid = city.power
	grid_label.text = "Power %d / %d\n%s" % [grid.total_used, grid.total_capacity, "No plants" if grid.station_count == 0 else "%d lot%s short" % [grid.short_homes, "" if grid.short_homes == 1 else "s"] if grid.short_homes > 0 else "No shortage"]

## D32: signed meter values; negative only while levels leave above the standard rate.
func meter_values() -> Array[int]:
	var out: Array[int] = []
	for kind in [City.HOME, City.SHOP, City.WORKSHOP]:
		out.append(-city.growth.surplus[kind] if city.growth.surplus[kind] > 0 else city.growth.demand[kind])
	return out

## D32: one ordered tax command; time stays suspended while the Budget dialog is open.
func _set_tax(rate: int) -> void:
	var result: Dictionary = city.set_tax_rate(rate)
	if result.ok and result.has("record"):
		dirty = true
		print("COMMAND ", JSON.stringify(result.record))
		var appeal: int = Balance.appeal(city.tax_rate)
		result.message = "Tax rate %d%% · residents %s, jobs %s a month · demand %d%% of standard%s." % [city.tax_rate, _rate_money(Balance.RESIDENT_TAX_PER_POINT * city.tax_rate), _rate_money(Balance.JOB_TAX_PER_POINT * city.tax_rate), appeal, "; surplus levels leave" if city.tax_rate > Balance.TAX_STANDARD else ""]
	_status(String(result.message))
	_refresh_metrics()
	if city.inside(inspected_cell): _inspect_cell(inspected_cell)
	if budget_dialog.visible: _fill_budget()
	world.queue_redraw()

static func _rate_money(cents: int) -> String:
	return Balance.money(cents).trim_suffix(".00")

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
	# D39: with an autosave on disk the dialog always opens, so Load autosave is reachable.
	var autosave: bool = store.has_autosave(SAVE_PATH)
	if (dirty and FileAccess.file_exists(SAVE_PATH)) or autosave:
		load_dialog.dialog_text = ("Replace your unsaved layout with a saved city?" if dirty else "Load your manual save, or the newest autosave?") + ("
Autosaves are kept separately from your manual save." if autosave else "")
		load_dialog.popup_centered(Vector2i(560,200))
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
	autosave_period = city.tick / Store.AUTOSAVE_DAYS
	_set_speed(0)
	world.clamp_camera()
	world.queue_redraw()
	_update_preview()
	var preserved_name: String = Store.preserved_path(path.trim_suffix(".bak"), maxi(1, int(result.get("migrated_from", 0)))).get_file()
	# Formats 1-5 lose their single-tile zones and stations (D30); format 6 keeps
	# everything. Every earlier format starts at the standard tax rate (D32).
	var cleared: String = "every lot kept" if int(result.get("migrated_from", 0)) >= 6 else "%d old single-tile zone/power tiles cleared for 3x3 lots and 4x4 power plants" % int(result.get("cleared_tiles", 0))
	if int(result.get("migrated_from", 0)) < 7: cleared += ", tax rate set to the standard %d%%" % Balance.TAX_STANDARD
	if int(result.get("migrated_from", 0)) > 0 and path.ends_with(".bak"):
		_status("Backup restored from earlier format %d; %s. Save to make it current; its bytes are kept as %s first." % [result.migrated_from, cleared, preserved_name])
	elif int(result.get("migrated_from", 0)) > 0:
		_status("Earlier format %d loaded; %s. Nothing written; saving keeps the original as %s." % [result.migrated_from, cleared, preserved_name])
	else:
		_status("Previous backup restored. Save to make it the current save." if path.ends_with(".bak") else "City restored. Time is paused; your layout and funds are intact.")
	if path.ends_with(".bak"): dirty = true
	# D29: keep the card's visibility and project flag; recheck steps for the loaded town.
	_refresh_guide()
	print("LOAD ", path, " sequence=", city.sequence, " tick=", city.tick)

## D39: an autosave each time running time passes a multiple of AUTOSAVE_DAYS. It never
## touches the manual save and leaves the unsaved flag set.
func _maybe_autosave() -> void:
	var period: int = city.tick / Store.AUTOSAVE_DAYS
	if period <= autosave_period: return
	autosave_period = period
	var result: Dictionary = store.save_autosave(city, SAVE_PATH)
	if result.ok: _status("Autosaved %s (slot %d of %d)." % [Calendar.date(city.tick), int(result.slot), Store.AUTOSAVE_SLOTS])
	else: _status(String(result.message))
	print("AUTOSAVE ", result.ok, " slot=", result.get("slot", 0), " tick=", city.tick)

func _load_autosave() -> void:
	_cancel_stroke()
	var result: Dictionary = store.load_autosave(SAVE_PATH)
	if not result.ok:
		_status("No valid autosave yet. Current city unchanged.")
		return
	city = result.city
	world.city = city
	inspected_cell = city.access.root
	_set_speed(0)
	world.clamp_camera()
	world.queue_redraw()
	_update_preview()
	# A loaded autosave is unsaved work until the player saves it manually.
	dirty = true
	autosave_period = city.tick / Store.AUTOSAVE_DAYS
	_refresh_metrics()
	_refresh_guide()
	_status("Autosave from %s loaded (slot %d). Save to keep it as your manual save." % [Calendar.date(city.tick), int(result.slot)])
	print("LOAD AUTOSAVE slot=", result.slot, " sequence=", city.sequence, " tick=", city.tick)

## D39: current presentation choices, as the settings file stores them.
func settings_values() -> Dictionary:
	return {"settings_version": Settings.VERSION, "window": remembered_window.duplicate(), "text_size": font_size,
		"art": world.art_mode, "grid": world.grid_visible, "road_marks": world.access_visible,
		"power_marks": world.power_visible, "land_value": world.desirability_visible,
		"services": world.services_visible, "guide_hidden": not guide_visible,
		"master_volume": int(audio.volumes.master), "effects_volume": int(audio.volumes.effects),
		"music_volume": int(audio.volumes.music), "muted": audio.muted, "animation": animation_on,
		"bindings": bindings.duplicate(true)}

func _remember_settings() -> void:
	if applying_settings or world == null: return
	var result: Dictionary = settings_store.save_settings(settings_values())
	if not result.ok: print("SETTINGS ", result.message)

func _apply_settings() -> void:
	var loaded: Dictionary = settings_store.load_settings()
	var values: Dictionary = loaded.settings
	applying_settings = true
	world.set_art(String(values.art))
	world.grid_visible = bool(values.grid)
	world.access_visible = bool(values.road_marks)
	world.power_visible = bool(values.power_marks)
	world.desirability_visible = bool(values.land_value)
	world.services_visible = bool(values.services)
	access_button.set_pressed_no_signal(world.access_visible)
	power_button.set_pressed_no_signal(world.power_visible)
	remembered_window = values.window.duplicate()
	if remembered_window.size() == 2 and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(int(remembered_window[0]), int(remembered_window[1])))
	if int(values.text_size) != font_size: _set_text_size(int(values.text_size))
	guide_visible = not bool(values.guide_hidden)
	audio.volumes = {"master": int(values.master_volume), "effects": int(values.effects_volume), "music": int(values.music_volume)}
	audio.muted = bool(values.muted)
	audio.apply()
	_set_animation(bool(values.animation))
	bindings = values.bindings.duplicate(true)
	Bindings.install(bindings)
	_refresh_key_labels()
	_refresh_sound_dialog()
	applying_settings = false
	_refresh_guide()
	_update_legend()
	world.queue_redraw()
	print("SETTINGS ", loaded.message)

## D40: Sound & motion: three volumes, Mute all and Animation, all remembered.
func _build_sound_dialog() -> void:
	sound_dialog = AcceptDialog.new()
	sound_dialog.title = "Sound & motion"
	sound_dialog.get_ok_button().text = "Close"
	add_child(sound_dialog)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	sound_dialog.add_child(column)
	for entry in [["master", "Master"], ["effects", "Sounds"], ["music", "Music"]]:
		var key: String = entry[0]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		column.add_child(row)
		var label := _label("", 18)
		label.custom_minimum_size.x = 190
		row.add_child(label)
		volume_labels[key] = label
		row.add_child(_button("−", func(): _change_volume(key, -10)))
		row.add_child(_button("+", func(): _change_volume(key, 10)))
	mute_toggle = CheckButton.new()
	mute_toggle.text = "Mute all  [M]"
	mute_toggle.toggled.connect(func(value: bool): _set_muted(value))
	column.add_child(mute_toggle)
	animation_toggle = CheckButton.new()
	animation_toggle.text = "Animation (water, smoke, flag)"
	animation_toggle.toggled.connect(func(value: bool):
		_set_animation(value)
		_remember_settings())
	column.add_child(animation_toggle)
	column.add_child(_label("All sounds and music are made by this game's own code.", 15, Style.MUTED))

func _open_sound() -> void:
	_cancel_stroke()
	settings.hide()
	_refresh_sound_dialog()
	sound_dialog.popup_centered(Vector2i(520, 360))

func _refresh_sound_dialog() -> void:
	if sound_dialog == null: return
	for key in volume_labels:
		(volume_labels[key] as Label).text = "%s %d%%" % [{"master": "Master", "effects": "Sounds", "music": "Music"}[key], int(audio.volumes[key])]
		(volume_labels[key] as Label).add_theme_font_size_override("font_size", font_size + 2)
	mute_toggle.set_pressed_no_signal(audio.muted)
	animation_toggle.set_pressed_no_signal(animation_on)

func _change_volume(key: String, step: int) -> void:
	audio.volumes[key] = clampi(int(audio.volumes[key]) + step, 0, 100)
	audio.apply()
	_refresh_sound_dialog()
	_remember_settings()
	if key == "effects": audio.play("build")

func _set_muted(value: bool) -> void:
	audio.muted = value
	audio.apply()
	_refresh_sound_dialog()
	_status("Sound muted (M to unmute)." if value else "Sound on (M to mute).")
	_remember_settings()

func _set_animation(value: bool) -> void:
	animation_on = value
	if not value:
		anim_clock = 0.0
		world.anim_time = 0.0
	world.queue_redraw()
	if animation_toggle != null: animation_toggle.set_pressed_no_signal(value)

## D41: the gamepad's own actions while no dialog is open. Returns true when handled.
func _pad_input(event: InputEvent) -> bool:
	if event.is_action_pressed("pad_place"):
		_ensure_cursor()
		_extend_stroke(pad_cursor)
		return true
	if event.is_action_released("pad_place"):
		if not stroke.is_empty():
			_extend_stroke(pad_cursor)
			_commit_stroke()
		return true
	if event.is_action_pressed("cancel_stroke"):
		_cancel_stroke()
		return true
	if event.is_action_pressed("tool_prev") or event.is_action_pressed("tool_next"):
		var order: Array[String] = Bindings.TOOL_ORDER
		var step: int = 1 if event.is_action_pressed("tool_next") else -1
		_select_tool(order[posmod(order.find(tool) + step, order.size())])
		_status("Tool: %s." % tool_buttons[tool].text)
		return true
	if event.is_action_pressed("zoom_in"):
		_zoom(1)
		return true
	if event.is_action_pressed("zoom_out"):
		_zoom(-1)
		return true
	if event.is_action_pressed("pause_city"):
		_set_speed(1 if speed == 0 else 0)
		return true
	if event.is_action_pressed("cycle_speed"):
		_set_speed({0: 1, 1: 3, 3: 0}[speed])
		_status("Speed: %s." % ("paused" if speed == 0 else "%dx" % speed))
		return true
	if event.is_action_pressed("show_summary"):
		_open_summary()
		return true
	if event.is_action_pressed("pad_menu"):
		_open_pad_menu()
		return true
	if event.is_action_pressed("center_camera"):
		_center_camera()
		pad_cursor = city.access.root
		return true
	return false

func _set_pad_active(value: bool) -> void:
	if value == pad_active: return
	pad_active = value
	if value: _ensure_cursor()
	prompt_panel.visible = value
	world.pad_cursor_visible = value
	_layout_prompts()
	world.queue_redraw()

## Starts the cursor at the cell under the mouse, else at the centre of the view.
func _ensure_cursor() -> void:
	if city.inside(pad_cursor): return
	pad_cursor = world.hover if city.inside(world.hover) else world.cell_at(World.VIEW / 2)
	pad_cursor = Vector2i(clampi(pad_cursor.x, 0, city.width - 1), clampi(pad_cursor.y, 0, city.height - 1))

## Tile steps from the stick or d-pad: one at once, then about 12 a second when held.
func _pad_cursor_step(seconds: float) -> void:
	var vector: Vector2 = Input.get_vector("cursor_left", "cursor_right", "cursor_up", "cursor_down")
	var direction := Vector2i(signi(roundi(vector.x * 1.4)), signi(roundi(vector.y * 1.4)))
	if direction == Vector2i.ZERO:
		pad_held = Vector2i.ZERO
		return
	_set_pad_active(true)
	if direction != pad_held:
		pad_held = direction
		pad_repeat = PAD_REPEAT_DELAY
		_move_cursor(direction)
		return
	pad_repeat -= seconds
	while pad_repeat <= 0.0:
		pad_repeat += 1.0 / PAD_REPEAT_RATE
		_move_cursor(direction)

func _move_cursor(direction: Vector2i) -> void:
	_ensure_cursor()
	pad_cursor = Vector2i(clampi(pad_cursor.x + direction.x, 0, city.width - 1), clampi(pad_cursor.y + direction.y, 0, city.height - 1))
	# Keep the cursor two tiles inside the visible map, panning when it nears an edge.
	var rect: Rect2 = world.tile_rect(pad_cursor)
	var margin: float = World.TILE * 2 * world.zoom
	var shift := Vector2.ZERO
	if rect.position.x < margin: shift.x = rect.position.x - margin
	elif rect.end.x > World.VIEW.x - margin: shift.x = rect.end.x - World.VIEW.x + margin
	if rect.position.y < margin + 40: shift.y = rect.position.y - margin - 40
	elif rect.end.y > World.VIEW.y - margin - 40: shift.y = rect.end.y - World.VIEW.y + margin + 40
	if shift != Vector2.ZERO: world.pan_pixels(shift)
	if not stroke.is_empty(): _extend_stroke(pad_cursor)
	world.hover = pad_cursor
	_update_preview()

func _layout_prompts() -> void:
	if prompt_panel == null or side == null: return
	prompt_label.add_theme_font_size_override("font_size", 14 + (font_size - 16) / 2)
	var left: float = side.position.x + side.size.x + 12
	var width: float = inspector_target.position.x + inspector_target.size.x - left
	prompt_panel.size = Vector2(width, 0)
	prompt_panel.size = Vector2(width, prompt_panel.get_combined_minimum_size().y)
	prompt_panel.position = Vector2(left, top.position.y + top.size.y + 6)

func _dialog_pad_input(dialog: AcceptDialog, event: InputEvent) -> void:
	if not (event is InputEventJoypadButton) or not event.pressed or not rebind_wait.is_empty(): return
	_set_pad_active(true)
	if event.button_index == JOY_BUTTON_B or (dialog == pad_menu and event.is_action_pressed("pad_menu")):
		dialog.hide()
		dialog.set_input_as_handled()

## D41: focus the OK button (Cancel for confirmations) so the gamepad starts somewhere visible.
func _focus_dialog(dialog: AcceptDialog) -> void:
	if not dialog.visible: return
	if dialog == pad_menu:
		var buttons: Array = pad_menu.find_children("*", "Button", true, false)
		buttons.erase(pad_menu.get_ok_button())
		if not buttons.is_empty(): (buttons[0] as Button).grab_focus()
		return
	var focused: Control = dialog.gui_get_focus_owner()
	if focused != null and focused.is_visible_in_tree(): return
	var target: Button = dialog.get_cancel_button() if dialog is ConfirmationDialog else dialog.get_ok_button()
	target.grab_focus()

func _build_pad_menu() -> void:
	pad_menu = AcceptDialog.new()
	pad_menu.title = "Menu"
	pad_menu.get_ok_button().text = "Resume"
	add_child(pad_menu)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	pad_menu.add_child(grid)
	var entries: Array = [["Budget", _open_budget], ["Town summary", _open_summary], ["Graphs", _open_graphs], ["Project", _open_project],
		["Help", _open_help], ["Display", _open_settings], ["Sound & motion", _open_sound], ["Controls", _open_controls],
		["Save", _save_clicked], ["Load", _load_clicked], ["First steps: show / hide", func(): _set_guide_visible(not guide_visible, true)],
		["First steps: next step", _guide_action_pressed], ["Pause / resume", func(): _set_speed(1 if speed == 0 else 0)], ["Back to the link", _center_camera],
		["Open save folder", _open_save_folder]]
	for entry in entries:
		var action: Callable = entry[1]
		var button := _button(entry[0], func():
			pad_menu.hide()
			action.call())
		button.custom_minimum_size = Vector2(250, 36)
		grid.add_child(button)

func _open_pad_menu() -> void:
	_cancel_stroke()
	pad_menu.popup_centered(Vector2i(560, 440))

## D41: the Controls dialog lists every remappable key and button.
func _build_controls_dialog() -> void:
	controls_dialog = AcceptDialog.new()
	controls_dialog.title = "Controls"
	controls_dialog.get_ok_button().text = "Close"
	add_child(controls_dialog)
	controls_dialog.add_button("Reset all", false, "reset")
	controls_dialog.custom_action.connect(func(action: String):
		if action == "reset": _reset_bindings())
	# The dialog is its own embedded window, so a waiting row reads input here.
	controls_dialog.window_input.connect(func(event: InputEvent):
		if not rebind_wait.is_empty() and _capture_rebind(event): controls_dialog.set_input_as_handled())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	controls_dialog.add_child(column)
	controls_note = _label("Choose a Key or Pad button, then press the new key or gamepad button. Escape or East cancels.", 15, Style.MUTED)
	controls_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_note.custom_minimum_size.x = 640
	column.add_child(controls_note)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(660, 360)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 4)
	scroll.add_child(rows)
	var actions: Array[String] = Bindings.REMAP_KEYS.duplicate()
	for action in Bindings.REMAP_PAD:
		if not action in actions: actions.append(action)
	for action in actions:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		rows.add_child(row)
		var name := _label(Bindings.ACTION_NAMES[action], 16)
		name.custom_minimum_size.x = 230
		row.add_child(name)
		var entry: Dictionary = {}
		for kind in ["key", "pad"]:
			var allowed: bool = (action in Bindings.REMAP_KEYS) if kind == "key" else (action in Bindings.REMAP_PAD)
			var kind_name: String = kind
			var button := _button("", func(): _start_rebind(action, kind_name))
			button.custom_minimum_size.x = 200
			button.disabled = not allowed
			row.add_child(button)
			entry[kind] = button
		controls_rows[action] = entry

func _open_controls() -> void:
	_cancel_stroke()
	settings.hide()
	pad_menu.hide()
	rebind_wait = {}
	_refresh_controls()
	controls_dialog.popup_centered(Vector2i(720, 560))

func _refresh_controls() -> void:
	if rebind_wait.is_empty(): controls_dialog.dialog_close_on_escape = true
	for action in controls_rows:
		var entry: Dictionary = controls_rows[action]
		entry.key.text = ("Key: " + Bindings.key_name(Bindings.key_for(action, bindings))) if action in Bindings.REMAP_KEYS else "Key: —"
		entry.pad.text = ("Pad: " + Bindings.pad_name(Bindings.pad_for(action, bindings))) if action in Bindings.REMAP_PAD else "Pad: —"
		if rebind_wait.get("action", "") == action:
			(entry[rebind_wait.kind] as Button).text = "Press a key…" if rebind_wait.kind == "key" else "Press a button…"

func _start_rebind(action: String, kind: String) -> void:
	rebind_wait = {"action": action, "kind": kind}
	# Escape and East cancel the wait instead of closing Controls.
	controls_dialog.dialog_close_on_escape = false
	controls_note.text = "Press the new %s for %s. Escape or East cancels." % ["key" if kind == "key" else "gamepad button", Bindings.ACTION_NAMES[action]]
	_refresh_controls()

## Returns true when the event was used by a waiting Controls row.
func _capture_rebind(event: InputEvent) -> bool:
	var kind: String = rebind_wait.kind
	var action: String = rebind_wait.action
	var cancel: bool = (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B)
	if cancel:
		rebind_wait = {}
		controls_note.text = "Unchanged."
		_refresh_controls()
		return true
	var value: int = -1
	if kind == "key" and event is InputEventKey and event.pressed and not event.echo:
		value = int(event.keycode) if event.keycode != KEY_NONE else int(event.physical_keycode)
	elif kind == "pad" and event is InputEventJoypadButton and event.pressed:
		value = int(event.button_index)
	if value < 0: return event is InputEventKey or event is InputEventJoypadButton
	var candidate: Dictionary = bindings.duplicate(true)
	var group: String = "keys" if kind == "key" else "pad"
	var default: int = int(Bindings.KEY_DEFAULTS[action][0]) if kind == "key" else int(Bindings.PAD_DEFAULTS[action])
	if value == default: candidate[group].erase(action)
	else: candidate[group][action] = value
	var problem: String = Bindings.problem(candidate)
	rebind_wait = {}
	if not problem.is_empty():
		controls_note.text = "Not changed: " + problem
	else:
		_apply_bindings(candidate)
		controls_note.text = "%s is now %s." % [Bindings.ACTION_NAMES[action], Bindings.key_name(value) if kind == "key" else Bindings.pad_name(value)]
	_refresh_controls()
	return true

func _apply_bindings(candidate: Dictionary) -> void:
	bindings = candidate
	Bindings.install(bindings)
	_refresh_key_labels()
	_remember_settings()

func _reset_bindings() -> void:
	rebind_wait = {}
	_apply_bindings(Bindings.empty())
	controls_note.text = "All keys and buttons are back to their defaults."
	_refresh_controls()

## Buttons that name a key show the current binding; so do the card and Help (D42).
func _refresh_key_labels() -> void:
	for entry in key_labels:
		(entry[0] as Button).text = String(entry[2]) % Bindings.key_name(Bindings.key_for(String(entry[1]), bindings))
	_refresh_help()
	_refresh_guide()

func _current_key_names() -> Dictionary:
	var out: Dictionary = {}
	for action in Bindings.REMAP_KEYS: out[action] = Bindings.key_name(Bindings.key_for(action, bindings))
	return out

## D42: Help opens with the player's current keys and gamepad buttons.
func _refresh_help() -> void:
	if help_text == null: return
	var k: Dictionary = _current_key_names()
	var pad := func(action: String) -> String: return Bindings.pad_name(Bindings.pad_for(action, bindings))
	var block: String = "YOUR KEYS (change them in Display > Controls)\n"
	block += "Roads %s · Residential %s · Commercial %s · Industrial %s\nPower plant %s · Park %s · Police %s · Fire %s · Clear %s\n" % [k.tool_road, k.tool_home, k.tool_shop, k.tool_workshop, k.tool_power, k.tool_park, k.tool_police, k.tool_fire, k.tool_clear]
	block += "Pause %s · Normal %s · Fast %s · Budget %s · Project %s\nSummary %s · Graphs %s · Mute %s · Link %s\n" % [k.pause_city, k.normal_speed, k.fast_speed, k.show_budget, k.show_project, k.show_summary, k.show_graphs, k.toggle_mute, k.center_camera]
	block += "Grid %s · Road marks %s · Power marks %s · Land value %s · Services %s\n" % [k.toggle_grid, k.toggle_access, k.toggle_power, k.toggle_desirability, k.toggle_services]
	block += "Gamepad: Menu %s · Pause %s · Speed %s · Summary %s · Tools %s / %s · Link %s\n" % [pad.call("pad_menu"), pad.call("pause_city"), pad.call("cycle_speed"), pad.call("show_summary"), pad.call("tool_prev"), pad.call("tool_next"), pad.call("center_camera")]
	help_text.text = block + "\nTHE REST OF HELP names the default keys.\n\n" + help_body

## D42: opens the local saves folder in the file manager; nothing is sent anywhere.
func _open_save_folder() -> String:
	var folder: String = ProjectSettings.globalize_path(store.save_folder(SAVE_PATH))
	DirAccess.make_dir_recursive_absolute(folder)
	if DisplayServer.get_name() != "headless": OS.shell_open(folder)
	_status("Saves are in %s (manual.json and autosave1-3.json; settings.json is one folder up)." % folder)
	return folder

func _build_graphs_dialog() -> void:
	graphs_dialog = AcceptDialog.new()
	graphs_dialog.title = "Town history"
	graphs_dialog.get_ok_button().text = "Close"
	add_child(graphs_dialog)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	graphs_dialog.add_child(column)
	graphs_note = _label("", 15, Style.MUTED)
	graphs_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	graphs_note.custom_minimum_size.x = 700
	column.add_child(graphs_note)
	graphs_view = HistoryGraph.new()
	graphs_view.custom_minimum_size = Vector2(700, 400)
	column.add_child(graphs_view)

## D39: read-only graphs of the saved monthly history.
func _open_graphs() -> void:
	_cancel_stroke()
	budget_dialog.hide()
	graphs_note.add_theme_font_size_override("font_size", font_size - 1)
	var months: int = city.history.size()
	graphs_note.text = "No months recorded yet. The graphs fill in at each monthly settlement." if months == 0 else "%d month%s recorded (up to %d are kept). Values are taken at each monthly settlement." % [months, "" if months == 1 else "s", Balance.HISTORY_LIMIT]
	graphs_view.set_history(city.history, font_size)
	graphs_dialog.popup_centered(Vector2i(760, 560))

func _open_settings() -> void:
	_cancel_stroke()
	settings.popup_centered(Vector2i(680,480))

## Presentation only; the simulation, saves and controls are unchanged.
func _set_art(mode: String) -> void:
	world.set_art(mode)
	_remember_settings()
	var note: String = {"original": " (original fallback)", "tiny_city": " (experimental Kenney CC0 pack)", "modern_city": " (default, Kenney CC0 pack)"}[world.art_mode]
	_status("Artwork: %s%s. Presentation only; the town and simulation are unchanged." % [ArtKit.LABELS[world.art_mode], note])

func _open_help() -> void:
	_cancel_stroke()
	help_text.add_theme_font_size_override("font_size", font_size)
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

func _open_budget() -> void:
	_cancel_stroke()
	_fill_budget()
	budget_dialog.popup_centered(Vector2i(760, 600))

func _fill_budget() -> void:
	tax_label.text = "Tax rate %d%%" % city.tax_rate
	tax_label.add_theme_font_size_override("font_size", font_size + 2)
	tax_note.add_theme_font_size_override("font_size", font_size - 1)
	tax_buttons.lower.disabled = city.tax_rate <= Balance.TAX_MIN
	tax_buttons.raise.disabled = city.tax_rate >= Balance.TAX_MAX
	tax_buttons.standard.disabled = city.tax_rate == Balance.TAX_STANDARD
	tax_note.text = "Each month: %s per serviced resident, %s per serviced job. Demand %d%% of standard (%d-%d%%, standard %d%%). Lower rates attract residents and businesses; %s" % [_rate_money(Balance.RESIDENT_TAX_PER_POINT * city.tax_rate), _rate_money(Balance.JOB_TAX_PER_POINT * city.tax_rate), Balance.appeal(city.tax_rate), Balance.TAX_MIN, Balance.TAX_MAX, Balance.TAX_STANDARD, "above %d%%, up to %d levels of each type leave per check while above demand." % [Balance.TAX_STANDARD, Balance.LEAVE_LIMIT]]
	var next_day: int = city.tick + Balance.MONTH_DAYS - city.tick % Balance.MONTH_DAYS + 1
	budget_text.add_theme_font_size_override("font_size", font_size)
	budget_text.text = "CURRENT FORECAST · %s · settles %s after growth\n" % [Calendar.month(city.tick), Calendar.date(next_day - 1)]
	budget_text.text += _budget_breakdown(city.budget)
	budget_text.text += "\nForecast uses today's services and development.\nNo tax from unserved buildings, even during decline grace.\n"
	if city.last_budget.is_empty():
		budget_text.text += "\nLAST SETTLEMENT · none recorded yet\n"
	else:
		var last: Dictionary = City.Economy.totals(city.last_budget)
		budget_text.text += "\nLAST SETTLEMENT · %s, settled %s\n" % [Calendar.settled_month(int(city.last_budget.tick)), Calendar.date(int(city.last_budget.tick))]
		budget_text.text += _budget_breakdown(city.last_budget)
		budget_text.text += "\nOpening %s → closing %s\nShortfall waived %s · surplus capped %s\n" % [Balance.money(city.last_budget.opening_cash), Balance.money(last.closing_cash), Balance.money(last.waiver), Balance.money(last.capped)]
	budget_text.text += "\nRECOVERY · Clear surplus roads, power plants, parks or stations for free.\nRestore road access and power to restore taxes.\nAt zero, unpaid costs are waived: no debt or service cuts.\nWith everything cleared, the $100 monthly grant rebuilds cash."

func _budget_breakdown(data: Dictionary) -> String:
	var result: Dictionary = City.Economy.totals(data)
	var rate: int = int(data.get("tax_rate", Balance.TAX_STANDARD))
	return "Tax %d%%: grant $100 + %d serviced residents × %s + %d serviced jobs × %s = %s\nUpkeep: %d roads × $1 + %d power plants × $60 + %d parks × $10\n+ %d police × $30 + %d fire × $30 = %s\nNet %s%s" % [rate, data.residents, _rate_money(Balance.RESIDENT_TAX_PER_POINT * rate), data.jobs, _rate_money(Balance.JOB_TAX_PER_POINT * rate), Balance.money(result.income), data.roads, data.stations, data.parks, int(data.get("police", 0)), int(data.get("fire", 0)), Balance.money(result.expenses), Balance.money(result.net), " · DEFICIT: costs exceed income" if result.net < 0 else ""]

func _build_project_dialog() -> void:
	project_dialog = AcceptDialog.new()
	project_dialog.title = "A welcoming square"
	project_dialog.get_ok_button().text = "Close"
	add_child(project_dialog)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	project_dialog.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 16)
	scroll.add_child(column)
	project_choice = OptionButton.new()
	project_choice.item_selected.connect(func(_index: int): _refresh_project())
	column.add_child(project_choice)
	project_text = _label("", 16)
	project_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	project_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(project_text)
	project_complete = _button("Complete square", _complete_project)
	column.add_child(project_complete)
	project_show = _button("Show park", _show_project_park)
	column.add_child(project_show)

func _open_project() -> void:
	_cancel_stroke()
	project_choice.clear()
	for i in range(city.occupancy.size()):
		if city.occupancy[i] == City.PARK:
			project_choice.add_item("Park (%d, %d)" % [i % city.width, i / city.width], i)
	if project_choice.item_count > 0: project_choice.select(0)
	_refresh_project()
	project_dialog.popup_centered(Vector2i(700, 520))
	project_seen = true
	_refresh_guide()

func _project_index() -> int:
	if city.project.completed: return int(city.project.park_index)
	return project_choice.get_selected_id() if project_choice.item_count > 0 else -1

func _refresh_project() -> void:
	var i: int = _project_index()
	var valid: bool = i >= 0 and i < city.occupancy.size() and city.occupancy[i] == City.PARK
	project_choice.visible = not city.project.completed and project_choice.item_count > 0
	project_show.visible = valid
	project_complete.visible = not city.project.completed
	project_complete.disabled = not valid or city.project_homes(i) < 3
	project_text.add_theme_font_size_override("font_size", font_size)
	if city.project.completed:
		project_text.text = "Completed: a welcoming square.\nFlowers celebrate your town; the park benefit is unchanged.\n"
		if not valid: project_text.text += "The decorated park was cleared. Your completion is kept; rebuilding does not repeat the project.\n"
	else:
		project_text.text = "Optional goal: three developed RESIDENTIAL LOTS with a tile within 3 side-steps of one park, each with road access and power. Each lot counts once, at either level.\n\n"
		project_text.text += "%d / 3 qualifying residential lots.\n" % city.project_homes(i) if valid else "No parks yet. Place a pocket park with 8.\n"
		project_text.text += "\nComplete the square to add flowers. Decoration only: no extra growth, income or service. No deadline or penalty.\n"
	project_text.text += "\nA park costs $100 to place and $10/month. It already prioritizes nearby residential lots within existing demand; completion does not change that benefit."

func _complete_project() -> void:
	var i: int = _project_index()
	var cell := Vector2i(i % city.width, i / city.width) if i >= 0 else Vector2i(-1, -1)
	var result: Dictionary = city.complete_project(cell)
	if result.ok:
		dirty = true
		world.queue_redraw()
	_status(result.message)
	_refresh_project()

func _build_summary_dialog() -> void:
	summary_dialog = AcceptDialog.new()
	summary_dialog.title = "Town summary"
	summary_dialog.get_ok_button().text = "Close"
	add_child(summary_dialog)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(700, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	summary_dialog.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	summary_heading = _label("", 16, Style.MUTED)
	summary_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary_heading)
	summary_column = VBoxContainer.new()
	summary_column.add_theme_constant_override("separation", 10)
	column.add_child(summary_column)

## D34: read-only; building the summary and opening it never change the town.
func _open_summary() -> void:
	_cancel_stroke()
	_fill_summary()
	summary_dialog.popup_centered(Vector2i(760, 560))

func _fill_summary() -> void:
	summary_items = Summary.build(city)
	summary_actions.clear()
	for child in summary_column.get_children():
		summary_column.remove_child(child)
		child.queue_free()
	summary_heading.add_theme_font_size_override("font_size", font_size - 1)
	summary_heading.text = "%s · Residents %d · Jobs %d · Tax %d%%\nWhat is holding the town back, biggest first:" % [Calendar.date(city.tick), city.growth.population, city.growth.jobs, city.tax_rate]
	for item in summary_items:
		var row := HBoxContainer.new()
		summary_column.add_child(row)
		var text := _label(String(item.text), font_size)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.custom_minimum_size.x = 520
		row.add_child(text)
		var action: String = String(item.action)
		if action.is_empty(): continue
		var entry: Dictionary = item
		var button := _button("Show" if action == "show" else "Budget", func(): _summary_action(entry))
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.custom_minimum_size.x = 96
		row.add_child(button)
		summary_actions.append(button)

func _summary_action(item: Dictionary) -> void:
	summary_dialog.hide()
	if String(item.action) == "budget":
		_open_budget()
	elif int(item.example) >= 0:
		_show_cell(city.cell_of(int(item.example)))

## Centres the view on a cell and points the inspector at it (Show actions).
func _show_cell(cell: Vector2i) -> void:
	world.zoom = 1
	world.origin = Vector2(cell) * World.TILE + Vector2.ONE * World.TILE / 2 - Vector2(400, 140)
	world.clamp_camera()
	zoom_label.text = "1x"
	world.queue_redraw()
	_inspect_cell(cell)

func _build_guide() -> void:
	guide_panel = _panel()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	guide_panel.add_child(column)
	guide_heading = _label("", 13, Style.MUTED)
	column.add_child(guide_heading)
	guide_text = _label("", 16)
	guide_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide_text.custom_minimum_size.x = 448
	column.add_child(guide_text)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	column.add_child(buttons)
	guide_action = _button("Show", _guide_action_pressed)
	guide_hide = _button("Hide", func(): _set_guide_visible(false, true))
	for button: Button in [guide_action, guide_hide]:
		for style_name in ["normal", "hover", "pressed", "focus"]:
			var compact: StyleBox = theme.get_stylebox(style_name, "Button").duplicate()
			compact.content_margin_top = 3
			compact.content_margin_bottom = 3
			button.add_theme_stylebox_override(style_name, compact)
		buttons.add_child(button)

## D29: read-only; evaluation and every card action leave the town and unsaved flag alone.
func _refresh_guide() -> void:
	if guide_panel == null: return
	guide_state = Guide.evaluate(city, project_seen, _current_key_names())
	var state: String = String(guide_state.state)
	guide_heading.text = "FIRST STEPS · DONE" if state == "done" else "FIRST STEPS" if state == "no_link" else "FIRST STEPS · %d OF %d" % [guide_state.step, guide_state.total]
	guide_text.text = String(guide_state.text)
	guide_text.add_theme_font_size_override("font_size", font_size)
	guide_heading.add_theme_font_size_override("font_size", 13 + (font_size - 16) / 2)
	var action: String = String(guide_state.action)
	guide_action.visible = not action.is_empty()
	guide_action.text = "Open Project" if action == "project" else "Show"
	guide_hide.text = "Close" if state in ["done", "no_link"] else "Hide"
	guide_panel.visible = guide_visible
	world.guide_target = guide_state.target if guide_visible else Guide.NONE
	world.guide_size = int(guide_state.size)
	world.queue_redraw()
	_layout_guide()
	# Wrapped text settles its height a frame later; place the card again then.
	call_deferred("_layout_guide")

func _layout_guide() -> void:
	if guide_panel == null or side == null or inspector_target.size == Vector2.ZERO: return
	var left: float = side.position.x + side.size.x + 12
	var width: float = minf(480, inspector_target.position.x - 12 - left)
	guide_text.custom_minimum_size.x = width - 32
	guide_panel.size = Vector2(width, 0)
	var height: float = guide_panel.get_combined_minimum_size().y
	guide_panel.size = Vector2(width, height)
	guide_panel.position = Vector2(left, bottom.position.y - 12 - height)

## D39: player actions (Hide/Close, F1, Help) remember the choice in settings.
func _set_guide_visible(value: bool, remember: bool = false) -> void:
	guide_visible = value
	_refresh_guide()
	if remember: _remember_settings()

func _guide_action_pressed() -> void:
	match String(guide_state.get("action", "")):
		"show": _show_cell(guide_state.target)
		"project": _open_project()

func _show_project_park() -> void:
	var i: int = _project_index()
	if i < 0 or i >= city.occupancy.size() or city.occupancy[i] != City.PARK: return
	var cell := Vector2i(i % city.width, i / city.width)
	world.zoom = 1
	world.origin = Vector2(cell) * World.TILE + Vector2.ONE * World.TILE / 2 - Vector2(400, 140)
	world.clamp_camera()
	world.queue_redraw()
	_inspect_cell(cell)
	project_dialog.hide()
