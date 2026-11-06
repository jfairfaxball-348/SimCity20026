extends Control
## D32 demand meter: one compact line under the population count. Each of H, S and W
## shows its letter, a small bar from a centre line (up for demand, down for levels
## leaving under high taxes) and a signed number. Presentation only: main.gd passes
## values read from the model.
const Style = preload("res://scripts/presentation/ui_style.gd")
const LETTERS: Array[String] = ["H", "S", "W"]
## The bar is full at the growth round cap on a square-root scale, so a single level
## is clearly visible; the number always shows the true value.
const FULL: int = 8
const BAR: float = 8.0
const GAP: float = 4.0
const COLUMN_GAP: float = 14.0
const TRACK := Color("d3d1bd")
const UP := Style.ACCENT
const DOWN := Color("a4572f")

var values: Array[int] = [0, 0, 0]
var font_size: int = 14

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_describe()
	_resize()

func set_values(next: Array) -> void:
	var typed: Array[int] = []
	for value in next: typed.append(int(value))
	if typed == values: return
	values = typed
	_describe()
	_resize()
	queue_redraw()

func set_font_size(amount: int) -> void:
	font_size = amount
	_resize()
	queue_redraw()

static func signed(value: int) -> String:
	return "+%d" % value if value > 0 else "−%d" % -value if value < 0 else "0"

## Plain-text reading of the meter, e.g. "H +3 · S 0 · W −2".
func summary() -> String:
	var parts: Array[String] = []
	for n in range(3): parts.append("%s %s" % [LETTERS[n], signed(values[n])])
	return " · ".join(parts)

func _describe() -> void:
	tooltip_text = "Demand meter (H homes, S shops, W workshops), in building levels: " + summary() + ".\nUp / +: levels the town welcomes now. Down / −: levels leaving at the next check because taxes are above 10%.\nLower the tax rate in Budget [B] to attract growth. Growth is checked every five days."

func _font() -> Font:
	return get_theme_default_font() if is_inside_tree() else ThemeDB.fallback_font

func _width(text: String) -> float:
	return ceilf(_font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)

func _line_height() -> float:
	return ceilf(_font().get_height(font_size)) + 2

func _resize() -> void:
	var width: float = 0.0
	for n in range(3):
		width += _width(LETTERS[n]) + GAP + BAR + GAP + _width(signed(values[n]))
	custom_minimum_size = Vector2(width + COLUMN_GAP * 2, _line_height())
	update_minimum_size()

func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE or what == NOTIFICATION_THEME_CHANGED: _resize()

func _draw() -> void:
	var font: Font = _font()
	var height: float = _line_height()
	var top: float = maxf(0.0, (size.y - height) / 2)
	var baseline: float = top + 1 + font.get_ascent(font_size)
	var bar_top: float = top + 1
	var bar_height: float = height - 2
	var middle: float = bar_top + bar_height / 2
	var reach: float = bar_height / 2
	var x: float = 0.0
	for n in range(3):
		var value: int = values[n]
		draw_string(font, Vector2(x, baseline), LETTERS[n], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Style.MUTED)
		x += _width(LETTERS[n]) + GAP
		draw_rect(Rect2(x, bar_top, BAR, bar_height), TRACK)
		var extent: float = roundf(reach * sqrt(minf(absi(value), FULL) / FULL))
		if value > 0: draw_rect(Rect2(x, middle - extent, BAR, extent), UP)
		elif value < 0: draw_rect(Rect2(x, middle, BAR, extent), DOWN)
		draw_line(Vector2(x - 1, middle), Vector2(x + BAR + 1, middle), Style.INK, 1.0)
		x += BAR + GAP
		draw_string(font, Vector2(x, baseline), signed(value), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Style.INK)
		x += _width(signed(value)) + COLUMN_GAP
