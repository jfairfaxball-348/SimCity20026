extends RefCounted
const INK := Color("243f38")
const PAPER := Color("ede9d9")
const MUTED := Color("69766a")
const ACCENT := Color("496a54")

static func box(color: Color, radius: int = 8) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.set_corner_radius_all(radius)
	result.content_margin_left = 16
	result.content_margin_right = 16
	result.content_margin_top = 10
	result.content_margin_bottom = 10
	return result

static func make_theme(font_size: int = 16) -> Theme:
	var result := Theme.new()
	result.default_font_size = font_size
	result.set_color("font_color", "Label", INK)
	result.set_color("font_color", "Button", INK)
	result.set_color("font_hover_color", "Button", INK)
	result.set_color("font_pressed_color", "Button", Color("fff9df"))
	result.set_color("font_focus_color", "Button", INK)
	result.set_stylebox("normal", "Button", box(Color("dcdcc8")))
	result.set_stylebox("hover", "Button", box(Color("ced6b8")))
	result.set_stylebox("pressed", "Button", box(ACCENT))
	var focus := box(Color(0, 0, 0, 0))
	focus.border_color = Color("c59150")
	focus.set_border_width_all(2)
	result.set_stylebox("focus", "Button", focus)
	result.set_stylebox("panel", "PanelContainer", box(PAPER))
	result.set_stylebox("panel", "AcceptDialog", box(PAPER))
	result.set_constant("separation", "VBoxContainer", 10)
	result.set_constant("separation", "HBoxContainer", 10)
	return result
