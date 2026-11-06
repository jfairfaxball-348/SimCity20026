extends Control
## D39: original line graphs of the monthly history: residents; jobs (commercial solid,
## industrial dashed); funds. Read-only. Each panel names its highest value and the
## first and last month, so it reads without colour.
const Calendar = preload("res://scripts/presentation/calendar.gd")
const Balance = preload("res://content/balance.gd")
const Style = preload("res://scripts/presentation/ui_style.gd")
var history: Array = []
var font_size: int = 16

func set_history(records: Array, size_value: int) -> void:
	history = records
	font_size = size_value
	queue_redraw()

static func panels() -> Array:
	return [["Residents", [1], false], ["Jobs: commercial (solid), industrial (dashed)", [2, 3], false], ["Funds (cash after each month)", [4], true]]

func _draw() -> void:
	var font: Font = get_theme_default_font()
	var small: int = font_size - 2
	var line_h: float = font.get_height(small)
	var gap: float = 10.0
	var panel_h: float = (size.y - 2 * gap) / 3.0
	for p in range(3):
		var spec: Array = panels()[p]
		var top: float = p * (panel_h + gap)
		var area := Rect2(Vector2(0, top), Vector2(size.x, panel_h))
		draw_rect(area, Color(Style.INK, 0.05))
		var highest: int = 0
		for record in history:
			for k in spec[1]: highest = maxi(highest, int(record[k]))
		var label: String = "%s · highest %s" % [spec[0], Balance.money(highest) if spec[2] else str(highest)]
		draw_string(font, Vector2(6, top + line_h), label, HORIZONTAL_ALIGNMENT_LEFT, size.x - 12, small, Style.INK)
		var plot := Rect2(Vector2(8, top + line_h + 6), Vector2(size.x - 16, panel_h - 2 * line_h - 14))
		draw_line(Vector2(plot.position.x, plot.end.y), plot.end, Style.MUTED, 1.0)
		draw_line(plot.position, Vector2(plot.position.x, plot.end.y), Style.MUTED, 1.0)
		if not history.is_empty():
			var first: String = Calendar.settled_month(int(history[0][0]))
			var last: String = Calendar.settled_month(int(history[-1][0]))
			draw_string(font, Vector2(6, top + panel_h - 4), first, HORIZONTAL_ALIGNMENT_LEFT, size.x / 2 - 6, small, Style.MUTED)
			draw_string(font, Vector2(size.x / 2, top + panel_h - 4), last, HORIZONTAL_ALIGNMENT_RIGHT, size.x / 2 - 6, small, Style.MUTED)
		for n in range(spec[1].size()):
			var k: int = spec[1][n]
			var points := PackedVector2Array()
			for m in range(history.size()):
				var x: float = plot.position.x + (plot.size.x * m / maxf(1.0, history.size() - 1) if history.size() > 1 else plot.size.x / 2)
				var y: float = plot.end.y - (plot.size.y * int(history[m][k]) / float(highest) if highest > 0 else 0.0)
				points.append(Vector2(x, y))
			if points.size() == 1:
				draw_rect(Rect2(points[0] - Vector2(2, 2), Vector2(5, 5)), Style.ACCENT)
				continue
			for m in range(points.size() - 1):
				if n == 0: draw_line(points[m], points[m + 1], Style.ACCENT, 2.0)
				else: draw_dashed_line(points[m], points[m + 1], Style.INK, 2.0, 5.0)
