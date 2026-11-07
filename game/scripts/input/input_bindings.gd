extends RefCounted
## Input actions for keyboard and (D41) gamepad, with remappable defaults. install()
## rebuilds every managed action from the defaults plus a validated set of overrides
## {"keys": {action: key code}, "pad": {action: button index}}.

const KEY_DEFAULTS: Dictionary = {
	"tool_road": [KEY_1], "tool_home": [KEY_2], "tool_clear": [KEY_3], "tool_power": [KEY_P],
	"tool_shop": [KEY_6], "tool_workshop": [KEY_7],
	"tool_park": [KEY_8], "tool_police": [KEY_9], "tool_fire": [KEY_0], "show_budget": [KEY_B], "show_project": [KEY_J], "show_summary": [KEY_T], "show_graphs": [KEY_H], "toggle_mute": [KEY_M],
	"pause_city": [KEY_SPACE], "normal_speed": [KEY_4], "fast_speed": [KEY_5],
	"pan_left": [KEY_A, KEY_LEFT], "pan_right": [KEY_D, KEY_RIGHT],
	"pan_up": [KEY_W, KEY_UP], "pan_down": [KEY_S, KEY_DOWN],
	"toggle_grid": [KEY_G], "toggle_access": [KEY_R], "toggle_power": [KEY_E], "toggle_desirability": [KEY_V], "toggle_services": [KEY_C], "center_camera": [KEY_HOME],
	"cancel_stroke": [KEY_ESCAPE], "zoom_in": [KEY_EQUAL, KEY_KP_ADD],
	"zoom_out": [KEY_MINUS, KEY_KP_SUBTRACT], "display_settings": [KEY_F6], "toggle_guide": [KEY_F1]}
## Keyboard actions the player may remap (one key each), in Controls order.
const REMAP_KEYS: Array[String] = ["tool_road", "tool_home", "tool_shop", "tool_workshop", "tool_power", "tool_park", "tool_police", "tool_fire", "tool_clear",
	"pause_city", "normal_speed", "fast_speed", "show_budget", "show_project", "show_summary", "show_graphs",
	"toggle_grid", "toggle_access", "toggle_power", "toggle_desirability", "toggle_services", "toggle_mute", "center_camera"]
## D41 gamepad buttons the player may remap, with their defaults.
const PAD_DEFAULTS: Dictionary = {"pause_city": JOY_BUTTON_START, "cycle_speed": JOY_BUTTON_X, "show_summary": JOY_BUTTON_Y,
	"tool_prev": JOY_BUTTON_LEFT_SHOULDER, "tool_next": JOY_BUTTON_RIGHT_SHOULDER, "pad_menu": JOY_BUTTON_BACK, "center_camera": JOY_BUTTON_LEFT_STICK}
const REMAP_PAD: Array[String] = ["pause_city", "cycle_speed", "show_summary", "tool_prev", "tool_next", "pad_menu", "center_camera"]
## Fixed gamepad buttons: South (place / accept), East (cancel), Guide and the d-pad.
const PAD_FIXED: Array[int] = [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_GUIDE, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]
## Keys that can never be assigned: escape, F1, F6, modifiers, movement and zoom keys.
const RESERVED_KEYS: Array[int] = [KEY_ESCAPE, KEY_F1, KEY_F6, KEY_CTRL, KEY_ALT, KEY_SHIFT, KEY_META, KEY_CAPSLOCK, KEY_TAB, KEY_ENTER, KEY_KP_ENTER,
	KEY_W, KEY_A, KEY_S, KEY_D, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_EQUAL, KEY_MINUS, KEY_KP_ADD, KEY_KP_SUBTRACT]
const PAD_NAMES: Dictionary = {0: "South", 1: "East", 2: "West", 3: "North", 4: "Back", 5: "Guide", 6: "Start", 7: "L3", 8: "R3",
	9: "LB", 10: "RB", 11: "D-pad up", 12: "D-pad down", 13: "D-pad left", 14: "D-pad right", 15: "Misc", 16: "Paddle 1", 17: "Paddle 2", 18: "Paddle 3", 19: "Paddle 4", 20: "Touchpad"}
const TOOL_ORDER: Array[String] = ["road", "home", "shop", "workshop", "power", "park", "police", "fire", "clear"]
const ACTION_NAMES: Dictionary = {"tool_road": "Roads", "tool_home": "Residential", "tool_shop": "Commercial", "tool_workshop": "Industrial",
	"tool_power": "Power plant", "tool_park": "Park", "tool_police": "Police station", "tool_fire": "Fire station", "tool_clear": "Clear",
	"pause_city": "Pause / resume", "normal_speed": "Normal speed", "fast_speed": "Fast speed", "show_budget": "Budget", "show_project": "Project",
	"show_summary": "Town summary", "show_graphs": "Graphs", "toggle_grid": "Grid", "toggle_access": "Road marks", "toggle_power": "Power marks",
	"toggle_desirability": "Land value overlay", "toggle_services": "Services overlay", "toggle_mute": "Mute", "center_camera": "Centre on link",
	"cycle_speed": "Change speed", "tool_prev": "Previous tool", "tool_next": "Next tool", "pad_menu": "Menu"}
const DEADZONE: float = 0.5

static func empty() -> Dictionary:
	return {"keys": {}, "pad": {}}

static func key_for(action: String, overrides: Dictionary) -> int:
	if overrides.get("keys", {}).has(action): return int(overrides["keys"][action])
	return int(KEY_DEFAULTS[action][0])

static func pad_for(action: String, overrides: Dictionary) -> int:
	if overrides.get("pad", {}).has(action): return int(overrides["pad"][action])
	return int(PAD_DEFAULTS[action])

static func key_name(code: int) -> String:
	return OS.get_keycode_string(code)

static func pad_name(button: int) -> String:
	return String(PAD_NAMES.get(button, "Button %d" % button))

## "" when valid, otherwise the reason (used by Controls and by settings validation).
static func problem(overrides: Variant) -> String:
	if typeof(overrides) != TYPE_DICTIONARY or overrides.size() != 2 or not overrides.has("keys") or not overrides.has("pad"): return "Bindings are malformed."
	if typeof(overrides["keys"]) != TYPE_DICTIONARY or typeof(overrides["pad"]) != TYPE_DICTIONARY: return "Bindings are malformed."
	for action in overrides["keys"]:
		if not String(action) in REMAP_KEYS: return "Unknown action %s." % action
		var code: Variant = overrides["keys"][action]
		if typeof(code) not in [TYPE_INT, TYPE_FLOAT] or float(code) != floor(float(code)) or int(code) <= 0 or int(code) > (KEY_SPECIAL | 0xFFFF): return "Invalid key."
		if key_name(int(code)).is_empty(): return "That key has no name."
		if int(code) in RESERVED_KEYS: return "%s is reserved." % key_name(int(code))
	for action in overrides["pad"]:
		if not String(action) in REMAP_PAD: return "Unknown action %s." % action
		var button: Variant = overrides["pad"][action]
		if typeof(button) not in [TYPE_INT, TYPE_FLOAT] or float(button) != floor(float(button)) or int(button) < 0 or int(button) > 20: return "Invalid button."
		if int(button) in PAD_FIXED: return "%s is fixed for navigation." % pad_name(int(button))
	var used: Dictionary = {}
	for action in REMAP_KEYS:
		var code: int = key_for(action, overrides)
		if used.has(code): return "%s is already used by %s." % [key_name(code), ACTION_NAMES[used[code]]]
		used[code] = action
	var pads: Dictionary = {}
	for action in REMAP_PAD:
		var button: int = pad_for(action, overrides)
		if pads.has(button): return "%s is already used by %s." % [pad_name(button), ACTION_NAMES[pads[button]]]
		pads[button] = action
	return ""

## Rebuilds every managed action. Invalid overrides are ignored (defaults used).
static func install(overrides: Dictionary = {}) -> void:
	if overrides.is_empty() or not problem(overrides).is_empty(): overrides = empty()
	for action: String in KEY_DEFAULTS:
		_reset(action)
		var codes: Array = KEY_DEFAULTS[action]
		if action in REMAP_KEYS: codes = [key_for(action, overrides)]
		for code in codes: _add_key(action, int(code))
	for action: String in ["save_city", "load_city"]:
		_reset(action)
		for logical in [false, true]:
			var event := InputEventKey.new()
			if logical: event.keycode = KEY_S if action == "save_city" else KEY_L
			else: event.physical_keycode = KEY_S if action == "save_city" else KEY_L
			event.ctrl_pressed = true
			InputMap.action_add_event(action, event)
	# D41 gamepad: remappable buttons, then the fixed navigation, place, cancel, zoom and pan.
	for action: String in ["cycle_speed", "tool_prev", "tool_next", "pad_menu", "pad_place", "cursor_left", "cursor_right", "cursor_up", "cursor_down"]:
		_reset(action)
	for action in REMAP_PAD: _add_button(action, pad_for(action, overrides))
	_add_button("pad_place", JOY_BUTTON_A)
	_add_button("cancel_stroke", JOY_BUTTON_B)
	for entry in [["cursor_left", JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0], ["cursor_right", JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0],
			["cursor_up", JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0], ["cursor_down", JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0]]:
		_add_button(entry[0], entry[1])
		_add_axis(entry[0], entry[2], entry[3])
	for entry in [["pan_left", JOY_AXIS_RIGHT_X, -1.0], ["pan_right", JOY_AXIS_RIGHT_X, 1.0], ["pan_up", JOY_AXIS_RIGHT_Y, -1.0], ["pan_down", JOY_AXIS_RIGHT_Y, 1.0],
			["zoom_in", JOY_AXIS_TRIGGER_RIGHT, 1.0], ["zoom_out", JOY_AXIS_TRIGGER_LEFT, 1.0]]:
		_add_axis(entry[0], entry[1], entry[2])
	_ensure_ui()

## Godot's own interface actions gain the gamepad: South accepts, East cancels, the
## d-pad and left stick move focus. Added once; existing keyboard events stay.
static func _ensure_ui() -> void:
	for entry in [["ui_accept", JOY_BUTTON_A, -1, 0.0], ["ui_cancel", JOY_BUTTON_B, -1, 0.0],
			["ui_up", JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0], ["ui_down", JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0],
			["ui_left", JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0], ["ui_right", JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0]]:
		var action: String = entry[0]
		if not InputMap.has_action(action): InputMap.add_action(action, DEADZONE)
		var has_button: bool = false
		var has_axis: bool = int(entry[2]) < 0
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton and event.button_index == int(entry[1]): has_button = true
			if event is InputEventJoypadMotion and event.axis == int(entry[2]) and signf(event.axis_value) == signf(entry[3]): has_axis = true
		if not has_button: _add_button(action, int(entry[1]))
		if not has_axis: _add_axis(action, int(entry[2]), float(entry[3]))

static func _reset(action: String) -> void:
	if InputMap.has_action(action): InputMap.action_erase_events(action)
	else: InputMap.add_action(action, DEADZONE)
	InputMap.action_set_deadzone(action, DEADZONE)

static func _add_key(action: String, code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	InputMap.action_add_event(action, event)
	# Logical-only events also occur with accessibility / virtual keyboards.
	var logical := InputEventKey.new()
	logical.keycode = code
	InputMap.action_add_event(action, logical)

static func _add_button(action: String, button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.device = -1
	InputMap.action_add_event(action, event)

static func _add_axis(action: String, axis: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	event.device = -1
	InputMap.action_add_event(action, event)
