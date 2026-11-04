extends Node2D
## Original code-drawn placeholders. No game-derived textures or assets.
const City = preload("res://scripts/sim/city_state.gd")
const TILE: int = 16
const VIEW: Vector2 = Vector2(640, 360)
const GRASS := Color("82966b")
const GRASS_LIGHT := Color("8b9e72")
const WATER := Color("527e80")
var city: City
var origin: Vector2 = Vector2(32, 240)
var zoom: int = 1
var grid_visible: bool = true
var access_visible: bool = true
var hover: Vector2i = Vector2i(-1, -1)
var preview_cells: Array[Vector2i] = []
var preview_valid: bool = true

func cell_at(view_position: Vector2) -> Vector2i:
	return Vector2i(((origin + view_position / zoom) / TILE).floor())

func tile_rect(cell: Vector2i) -> Rect2:
	return Rect2((Vector2(cell) * TILE - origin) * zoom, Vector2.ONE * TILE * zoom)

func pan_pixels(delta: Vector2) -> void:
	origin += delta / zoom
	clamp_camera()
	queue_redraw()

func set_zoom(value: int, anchor: Vector2 = VIEW / 2) -> void:
	var before: Vector2 = origin + anchor / zoom
	zoom = clampi(value, 1, 3)
	origin = before - anchor / zoom
	clamp_camera()
	queue_redraw()

func clamp_camera() -> void:
	if city == null:
		return
	var map_size := Vector2(city.width, city.height) * TILE
	var visible_size: Vector2 = VIEW / zoom
	origin.x = (map_size.x - visible_size.x) / 2 if map_size.x < visible_size.x else clampf(origin.x, -16, map_size.x - visible_size.x + 16)
	origin.y = (map_size.y - visible_size.y) / 2 if map_size.y < visible_size.y else clampf(origin.y, -16, map_size.y - visible_size.y + 16)
	origin = origin.round()

func _draw() -> void:
	if city == null:
		return
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("2d4644"))
	var first: Vector2i = Vector2i((origin / TILE).floor())
	var last: Vector2i = Vector2i(((origin + VIEW / zoom) / TILE).ceil())
	for y in range(maxi(0, first.y), mini(city.height, last.y + 1)):
		for x in range(maxi(0, first.x), mini(city.width, last.x + 1)):
			_draw_cell(Vector2i(x, y))
	_draw_outside_link()
	var cells: Array[Vector2i] = preview_cells.duplicate()
	if cells.is_empty() and city.inside(hover):
		cells.append(hover)
	var highlight: Color = Color("dce8ab") if preview_valid else Color("edaa89")
	for cell in cells:
		var rect: Rect2 = tile_rect(cell)
		draw_rect(rect.grow(-zoom), Color(highlight, 0.25))
		draw_rect(rect.grow(-zoom), highlight, false, zoom)

func _draw_cell(cell: Vector2i) -> void:
	var rect: Rect2 = tile_rect(cell)
	var at: Vector2 = rect.position
	var z: float = float(zoom)
	var i: int = city.index(cell)
	var variation: int = posmod(cell.x * 317 + cell.y * 137 + city.seed_value, 97)
	if city.terrain[i] == City.WATER:
		draw_rect(rect, WATER if variation % 3 else Color("557f80"))
		if variation % 4 == 0:
			draw_line(at + Vector2(3, 9) * z, at + Vector2(8, 9) * z, Color("6a9796"), z)
		return
	draw_rect(rect, GRASS_LIGHT if variation % 3 == 0 else GRASS)
	if cell.x > 0 and city.terrain[i - 1] == City.WATER:
		draw_rect(Rect2(at, Vector2(2, 16) * z), Color("c6bf8e"))
	match city.occupancy[i]:
		City.ROAD:
			_draw_road(cell, at, z)
		City.HOME:
			draw_rect(rect.grow(-z), Color("577c62"))
			draw_rect(rect.grow(-2 * z), Color("a3b389"), false, z)
			# An unoccupied planning plot, intentionally not a grown house.
			draw_rect(Rect2(at + Vector2(5, 5) * z, Vector2(6, 6) * z), Color("d4d3a8"), false, z)
			for offset in [Vector2(2, 2), Vector2(12, 2), Vector2(2, 12), Vector2(12, 12)]:
				draw_rect(Rect2(at + offset * z, Vector2(2, 2) * z), Color("e5dfbb"))
		_:
			if variation < 13:
				# Decorative shrubs, with no collision or simulation role.
				draw_rect(Rect2(at + Vector2(7, 8) * z, Vector2(2, 4) * z), Color("5d7152"))
				draw_rect(Rect2(at + Vector2(4, 5) * z, Vector2(7, 5) * z), Color("637e55"))
				draw_rect(Rect2(at + Vector2(5, 4) * z, Vector2(4, 3) * z), Color("9aaa75"))
			elif variation < 40:
				draw_rect(Rect2(at + Vector2(4, 10) * z, Vector2(2, 1) * z), Color("9ead7a"))
	if grid_visible:
		draw_line(at, at + Vector2(16, 0) * z, Color(0.22, 0.33, 0.24, 0.13), z)
		draw_line(at, at + Vector2(0, 16) * z, Color(0.22, 0.33, 0.24, 0.13), z)
	if access_visible and city.occupancy[i] in [City.ROAD, City.HOME]:
		var connected: bool = city.access.connected_roads[i] != 0 or city.access.served_homes[i] != 0
		var mark: Vector2 = at + Vector2(11, 4) * z
		draw_rect(Rect2(mark - Vector2(3, 3) * z, Vector2(7, 7) * z), Color("304842"))
		var color := Color("e1edbb") if connected else Color("f0be97")
		draw_line(mark - Vector2(2, 0) * z, mark + Vector2(2, 0) * z, color, z)
		if connected:
			draw_line(mark - Vector2(0, 2) * z, mark + Vector2(0, 2) * z, color, z)

func _draw_outside_link() -> void:
	if city.access.root.x < 0: return
	var rect: Rect2 = tile_rect(city.access.root)
	var z: float = float(zoom)
	var color := Color("f0d68e")
	draw_rect(rect.grow(-z), color, false, 2 * z)
	# Keep the original flag inside its tile so it never obscures nearby roads.
	# The persistent inspector and Outside link button supply the readable name.
	var pole: Vector2 = rect.position + Vector2(14, 13) * z
	draw_line(pole, pole - Vector2(0, 11) * z, color, z)
	draw_rect(Rect2(pole - Vector2(5, 11) * z, Vector2(5, 4) * z), color)

func _draw_road(cell: Vector2i, at: Vector2, z: float) -> void:
	var road: Color = Color("696e63")
	draw_rect(Rect2(at + Vector2(2, 2) * z, Vector2(12, 12) * z), Color("bbb99a"))
	draw_rect(Rect2(at + Vector2(3, 3) * z, Vector2(10, 10) * z), road)
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var neighbour: Vector2i = cell + direction
		if city.inside(neighbour) and city.occupancy[city.index(neighbour)] == City.ROAD:
			var center: Vector2 = at + Vector2(8, 8) * z
			draw_line(center, center + Vector2(direction) * 8 * z, road, 10 * z)
			draw_line(center + Vector2(direction) * 3 * z, center + Vector2(direction) * 5 * z, Color("c8c6a4"), z)
