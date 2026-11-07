extends RefCounted
## D41 / R5: default keyboard and gamepad bindings, remap validation and settings v3.
const Bindings = preload("res://scripts/input/input_bindings.gd")
const Settings = preload("res://scripts/persistence/settings_store.gd")
const FileOps = preload("res://scripts/persistence/file_ops.gd")
var t: SceneTree

func run(tester: SceneTree) -> void:
	t = tester
	test_defaults()
	test_problems()
	test_install()
	test_settings_v3()
	Bindings.install()
	print("PASS group: R5 bindings, remapping and settings version 3")

func has_key(action: String, code: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and (event.keycode == code or event.physical_keycode == code): return true
	return false

func has_button(action: String, button: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button: return true
	return false

func has_axis(action: String, axis: int, value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and signf(event.axis_value) == signf(value): return true
	return false

func test_defaults() -> void:
	Bindings.install()
	t.check(has_key("tool_home", KEY_2) and has_key("pause_city", KEY_SPACE) and has_key("toggle_services", KEY_C) and has_key("center_camera", KEY_HOME), "keyboard defaults are unchanged")
	t.check(has_button("pad_place", JOY_BUTTON_A) and has_button("cancel_stroke", JOY_BUTTON_B) and has_button("pause_city", JOY_BUTTON_START) and has_button("pad_menu", JOY_BUTTON_BACK) and has_button("show_summary", JOY_BUTTON_Y) and has_button("cycle_speed", JOY_BUTTON_X), "gamepad: South place, East cancel, Start pause, Back menu, North summary, West speed")
	t.check(has_button("tool_prev", JOY_BUTTON_LEFT_SHOULDER) and has_button("tool_next", JOY_BUTTON_RIGHT_SHOULDER) and has_button("center_camera", JOY_BUTTON_LEFT_STICK), "LB / RB change tool and L3 centres the view")
	t.check(has_button("cursor_left", JOY_BUTTON_DPAD_LEFT) and has_axis("cursor_left", JOY_AXIS_LEFT_X, -1.0) and has_axis("cursor_down", JOY_AXIS_LEFT_Y, 1.0), "the d-pad and left stick move the cursor")
	t.check(has_axis("zoom_in", JOY_AXIS_TRIGGER_RIGHT, 1.0) and has_axis("zoom_out", JOY_AXIS_TRIGGER_LEFT, 1.0) and has_axis("pan_right", JOY_AXIS_RIGHT_X, 1.0) and has_key("pan_right", KEY_D), "triggers zoom; the right stick pans alongside the keys")
	t.check(Bindings.problem(Bindings.empty()).is_empty(), "the defaults have no conflicts")
	t.check(has_button("ui_accept", JOY_BUTTON_A) and has_button("ui_cancel", JOY_BUTTON_B) and has_button("ui_down", JOY_BUTTON_DPAD_DOWN) and has_axis("ui_left", JOY_AXIS_LEFT_X, -1.0) and has_key("ui_accept", KEY_ENTER), "dialogs navigate with the gamepad as well as the keyboard")
	var before: int = InputMap.action_get_events("ui_accept").size()
	Bindings.install()
	t.check(InputMap.action_get_events("ui_accept").size() == before, "installing again adds no duplicate interface events")
	var Guide = load("res://scripts/presentation/opening_guide.gd")
	var remapped: Array[String] = Guide.texts({"tool_home": "Q", "pause_city": "P"})
	t.check("residential lot (Q)" in remapped[1] and "(P or 1x)" in remapped[3] and "(1)" in remapped[0], "card texts use the given keys over the defaults")
	t.check(Guide.done_text({}) == "Done. Next: parks, then police (9) and fire (0) for level 4. Help has every rule." and "police (K)" in Guide.done_text({"tool_police": "K"}), "the done card points at parks, police and fire")
	t.check(Bindings.TOOL_ORDER.size() == 9 and Bindings.pad_name(JOY_BUTTON_A) == "South" and Bindings.key_name(KEY_2) == "2", "tool order and plain input names")

func test_problems() -> void:
	var cases: Array = [
		[{"keys": {"tool_home": KEY_W}, "pad": {}}, "reserved"],
		[{"keys": {"tool_home": KEY_ESCAPE}, "pad": {}}, "reserved"],
		[{"keys": {"tool_home": KEY_1}, "pad": {}}, "already used by Roads"],
		[{"keys": {"pan_left": KEY_Q}, "pad": {}}, "Unknown action"],
		[{"keys": {}, "pad": {"tool_next": JOY_BUTTON_A}}, "fixed for navigation"],
		[{"keys": {}, "pad": {"tool_next": JOY_BUTTON_DPAD_UP}}, "fixed for navigation"],
		[{"keys": {}, "pad": {"tool_next": JOY_BUTTON_START}}, "already used by"],
		[{"keys": {}, "pad": {"tool_next": 21}}, "Invalid button"],
		[{"keys": {"tool_home": 1.5}, "pad": {}}, "Invalid key"],
		[{"keys": {}}, "malformed"],
		[[], "malformed"]]
	for entry in cases:
		var reason: String = Bindings.problem(entry[0])
		t.check(String(entry[1]) in reason, "bindings %s are refused (%s)" % [str(entry[0]), reason])
	var swap: Dictionary = {"keys": {"tool_road": KEY_2, "tool_home": KEY_1}, "pad": {"tool_prev": JOY_BUTTON_RIGHT_SHOULDER, "tool_next": JOY_BUTTON_LEFT_SHOULDER}}
	t.check(Bindings.problem(swap).is_empty(), "two actions may swap keys or buttons")

func test_install() -> void:
	Bindings.install({"keys": {"tool_home": KEY_Q, "toggle_mute": KEY_N}, "pad": {"tool_next": JOY_BUTTON_MISC1}})
	t.check(has_key("tool_home", KEY_Q) and not has_key("tool_home", KEY_2) and has_key("toggle_mute", KEY_N), "a remapped key replaces the default")
	t.check(has_button("tool_next", JOY_BUTTON_MISC1) and not has_button("tool_next", JOY_BUTTON_RIGHT_SHOULDER) and has_button("pad_place", JOY_BUTTON_A), "a remapped button replaces its default; fixed buttons stay")
	Bindings.install({"keys": {"tool_home": KEY_1}, "pad": {}})
	t.check(has_key("tool_home", KEY_2) and has_key("tool_road", KEY_1), "invalid overrides fall back to the defaults")
	Bindings.install()

func test_settings_v3() -> void:
	var previous: String = Settings.override_path
	var base: String = OS.get_environment("CITY_TEST_DIR")
	if base.is_empty(): base = "user://tests"
	Settings.override_path = base.path_join("settings_v3_%d/settings.json" % Time.get_ticks_usec())
	var store := Settings.new()
	t.check(int(Settings.defaults().settings_version) == 3 and Settings.defaults().bindings == Bindings.empty(), "version-3 defaults have no remapped bindings")
	var v2: Dictionary = Settings.defaults_v2()
	v2.music_volume = 50
	FileOps.new().write_text(Settings.path(), JSON.stringify(v2))
	var migrated: Dictionary = store.load_settings()
	t.check(migrated.ok and int(migrated.settings.music_volume) == 50 and migrated.settings.bindings == Bindings.empty() and int(migrated.settings.settings_version) == 3, "a version-2 file keeps its values and gains empty bindings")
	var values: Dictionary = Settings.defaults()
	values.bindings = {"keys": {"tool_home": KEY_Q}, "pad": {"pad_menu": JOY_BUTTON_MISC1}}
	t.check(store.save_settings(values).ok and store.load_settings().settings == values, "version-3 settings with bindings round-trip")
	var text: String = FileAccess.get_file_as_string(Settings.path())
	FileOps.new().write_text(Settings.path(), text.replace("\"tool_home\":%d" % KEY_Q, "\"tool_home\":%d" % KEY_1))
	t.check(not store.load_settings().ok, "a settings file with clashing bindings falls back to the defaults")
	var clash: Dictionary = Settings.defaults()
	clash.bindings = {"keys": {"tool_home": KEY_W}, "pad": {}}
	t.check(not store.save_settings(clash).ok, "invalid bindings are never written")
	Settings.override_path = previous
