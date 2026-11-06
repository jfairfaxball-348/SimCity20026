extends RefCounted

static func install() -> void:
	var keys: Dictionary = {
		"tool_road": [KEY_1], "tool_home": [KEY_2], "tool_clear": [KEY_3], "tool_power": [KEY_P],
		"tool_shop": [KEY_6], "tool_workshop": [KEY_7],
		"tool_park": [KEY_8], "show_budget": [KEY_B], "show_project": [KEY_J], "show_summary": [KEY_T],
		"pause_city": [KEY_SPACE], "normal_speed": [KEY_4], "fast_speed": [KEY_5],
		"pan_left": [KEY_A, KEY_LEFT], "pan_right": [KEY_D, KEY_RIGHT],
		"pan_up": [KEY_W, KEY_UP], "pan_down": [KEY_S, KEY_DOWN],
		"toggle_grid": [KEY_G], "toggle_access": [KEY_R], "toggle_power": [KEY_E], "toggle_desirability": [KEY_V], "center_camera": [KEY_HOME],
		"cancel_stroke": [KEY_ESCAPE], "zoom_in": [KEY_EQUAL, KEY_KP_ADD],
		"zoom_out": [KEY_MINUS, KEY_KP_SUBTRACT], "display_settings": [KEY_F6], "toggle_guide": [KEY_F1]}
	for action: String in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = code
			InputMap.action_add_event(action, event)
			# Logical-only events also occur with accessibility / virtual keyboards.
			var logical := InputEventKey.new()
			logical.keycode = code
			InputMap.action_add_event(action, logical)
	for action: String in ["save_city", "load_city"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = KEY_S if action == "save_city" else KEY_L
		event.ctrl_pressed = true
		InputMap.action_add_event(action, event)
		var logical := InputEventKey.new()
		logical.keycode = event.physical_keycode
		logical.ctrl_pressed = true
		InputMap.action_add_event(action, logical)
