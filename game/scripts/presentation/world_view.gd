extends Node2D
## Original code-drawn placeholders. No game-derived textures or assets.
const City = preload("res://scripts/sim/city_state.gd")
const ArtKit = preload("res://scripts/presentation/art_kit.gd")
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
var power_visible: bool = true
## D33/D36: land value overlay (off by default, never saved).
var desirability_visible: bool = false
## D38: police and fire coverage overlay (off by default, never saved).
var services_visible: bool = false
## D29: the First steps target, outlined with corner brackets while the card is shown.
var guide_target: Vector2i = Vector2i(-1, -1)
var guide_size: int = 1
var hover: Vector2i = Vector2i(-1, -1)
var preview_cells: Array[Vector2i] = []
var preview_valid: bool = true
## EXPERIMENTAL artwork evaluation: "original" (approved fallback) or a Kenney pack kit.
var art_mode: String = "original"
var art = null

func set_art(mode: String) -> void:
	art_mode = mode if mode in ArtKit.MODES else "original"
	art = null if art_mode == "original" else ArtKit.new(art_mode)
	queue_redraw()

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
	# Ground first, then each visible lot/station once over its whole footprint (D30).
	var anchors: Dictionary = {}
	for y in range(maxi(0, first.y), mini(city.height, last.y + 1)):
		for x in range(maxi(0, first.x), mini(city.width, last.x + 1)):
			_draw_cell(Vector2i(x, y))
			var owner: int = city.footprint_owner[city.index(Vector2i(x, y))]
			if owner >= 0: anchors[owner] = true
	var ordered: Array = anchors.keys()
	ordered.sort()
	for anchor in ordered:
		_draw_footprint(int(anchor))
	if desirability_visible:
		_draw_desirability(first, last, ordered)
	if services_visible:
		_draw_services(first, last, ordered)
	_draw_outside_link()
	if city.inside(guide_target): _draw_guide_bracket()
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
	if art != null:
		art.draw_cell(self, city, cell, i, rect, at, z, variation)
		if city.terrain[i] == City.WATER: return
		if city.occupancy[i] == City.PARK and city.project.completed and int(city.project.park_index) == i:
			_draw_flowers(at, z)
		_draw_grid_and_marks(i, at, z)
		return
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
		City.POWER, City.HOME, City.SHOP, City.WORKSHOP, City.POLICE, City.FIRE:
			pass # drawn once per footprint in _draw_footprint
		City.PARK:
			# Original pocket garden: pale path, rectangular bench, rounded tree crown.
			draw_rect(rect.grow(-z), Color("4c795b"))
			draw_line(at + Vector2(3, 14) * z, at + Vector2(10, 7) * z, Color("d7c49a"), 2 * z)
			draw_rect(Rect2(at + Vector2(10, 11) * z, Vector2(4, 2) * z), Color("b58a60"))
			draw_rect(Rect2(at + Vector2(5, 7) * z, Vector2(2, 4) * z), Color("735d44"))
			draw_circle(at + Vector2(6, 5) * z, 4 * z, Color("a7c880"))
			if city.project.completed and int(city.project.park_index) == i:
				_draw_flowers(at, z)
		_:
			if variation < 13:
				# Decorative shrubs, with no collision or simulation role.
				draw_rect(Rect2(at + Vector2(7, 8) * z, Vector2(2, 4) * z), Color("5d7152"))
				draw_rect(Rect2(at + Vector2(4, 5) * z, Vector2(7, 5) * z), Color("637e55"))
				draw_rect(Rect2(at + Vector2(5, 4) * z, Vector2(4, 3) * z), Color("9aaa75"))
			elif variation < 40:
				draw_rect(Rect2(at + Vector2(4, 10) * z, Vector2(2, 1) * z), Color("9ead7a"))
	_draw_grid_and_marks(i, at, z)

func _draw_grid_and_marks(i: int, at: Vector2, z: float) -> void:
	if grid_visible:
		draw_line(at, at + Vector2(16, 0) * z, Color(0.22, 0.33, 0.24, 0.13), z)
		draw_line(at, at + Vector2(0, 16) * z, Color(0.22, 0.33, 0.24, 0.13), z)
	if city.occupancy[i] == City.ROAD:
		_draw_marks(i, at, z)

## Original three-flower cluster for the completed project park; no simulation effect.
func _draw_flowers(at: Vector2, z: float) -> void:
	for flower in [Vector2(11, 4), Vector2(13, 7), Vector2(9, 14)]:
		draw_line(at + flower * z, at + (flower + Vector2(0, 2)) * z, Color("dce8ab"), z)
		draw_rect(Rect2(at + (flower - Vector2.ONE) * z, Vector2(3, 3) * z), Color("edb6a3"))
		draw_rect(Rect2(at + flower * z, Vector2.ONE * z), Color("fff0bb"))

## Road access (+/-) and power (bolt/x) marks. Lots carry one set at their anchor.
func _draw_marks(i: int, at: Vector2, z: float) -> void:
	if access_visible:
		var connected: bool = city.access.connected_roads[i] != 0 or city.access.served_homes[i] != 0
		var mark: Vector2 = at + Vector2(11, 4) * z
		draw_rect(Rect2(mark - Vector2(3, 3) * z, Vector2(7, 7) * z), Color("304842"))
		var color := Color("e1edbb") if connected else Color("f0be97")
		draw_line(mark - Vector2(2, 0) * z, mark + Vector2(2, 0) * z, color, z)
		if connected:
			draw_line(mark - Vector2(0, 2) * z, mark + Vector2(0, 2) * z, color, z)
	if power_visible:
		_draw_power_mark(i, at, z)

## D33 overlay: + marks for each positive point, diagonal hatching for negatives
## (one stripe per 2 points, at most 3), and a smoke mark on developed workshops.
## Tints only reinforce the marks, so meaning never relies on colour alone.
func _draw_desirability(first: Vector2i, last: Vector2i, anchors: Array) -> void:
	var z: float = float(zoom)
	for y in range(maxi(0, first.y), mini(city.height, last.y + 1)):
		for x in range(maxi(0, first.x), mini(city.width, last.x + 1)):
			var i: int = city.index(Vector2i(x, y))
			if city.terrain[i] == City.WATER: continue
			var score: int = city.desirability.tile_score[i]
			if score == 0: continue
			var at: Vector2 = tile_rect(Vector2i(x, y)).position
			if score > 0:
				draw_rect(Rect2(at, Vector2.ONE * TILE * z), Color(0.86, 1.0, 0.62, 0.22))
				for k in range(mini(score, 3)):
					var mark: Vector2 = at + Vector2(3 + 5 * k, 12) * z
					draw_rect(Rect2(mark - Vector2(2, 2) * z, Vector2(5, 5) * z), Color("2f4a3a"))
					draw_line(mark - Vector2(1, 0) * z, mark + Vector2(2, 0) * z, Color("e8f7c4"), z)
					draw_line(mark - Vector2(0, 1) * z, mark + Vector2(0, 2) * z, Color("e8f7c4"), z)
			else:
				draw_rect(Rect2(at, Vector2.ONE * TILE * z), Color(0.55, 0.26, 0.12, 0.26))
				for k in range(mini(3, (1 - score) / 2)):
					var offset: float = 5 + 5 * k
					draw_line(at + Vector2(0, offset) * z, at + Vector2(offset, 0) * z, Color(0.33, 0.15, 0.07, 0.9), 2 * z)
	for anchor in anchors:
		var a: int = int(anchor)
		if city.occupancy[a] != City.WORKSHOP or city.development[a] == 0: continue
		var top: Vector2 = tile_rect(city.cell_of(a)).position + Vector2(38, 6) * z
		for puff in [[Vector2(0, 0), 3.0], [Vector2(4, -3), 2.5], [Vector2(8, -5), 2.0]]:
			draw_circle(top + puff[0] * z, (puff[1] + 0.8) * z, Color("3d4446"))
			draw_circle(top + puff[0] * z, puff[1] * z, Color("d9dcd6"))

## D38 overlay: a small square on tiles within reach of a working police station, a
## small triangle within reach of a working fire station, and a cross over stations
## that do not work. A light tint marks full cover; meaning never relies on colour.
func _draw_services(first: Vector2i, last: Vector2i, anchors: Array) -> void:
	var z: float = float(zoom)
	var services = city.services
	for y in range(maxi(0, first.y), mini(city.height, last.y + 1)):
		for x in range(maxi(0, first.x), mini(city.width, last.x + 1)):
			var i: int = city.index(Vector2i(x, y))
			var police: bool = services.police_tile[i] != 0
			var fire: bool = services.fire_tile[i] != 0
			if not police and not fire: continue
			var at: Vector2 = tile_rect(Vector2i(x, y)).position
			if police and fire: draw_rect(Rect2(at, Vector2.ONE * TILE * z), Color(0.75, 0.86, 1.0, 0.18))
			if police:
				draw_rect(Rect2(at + Vector2(2, 2) * z, Vector2(6, 6) * z), Color("24324a"))
				draw_rect(Rect2(at + Vector2(3, 3) * z, Vector2(4, 4) * z), Color("c9dcf5"))
			if fire:
				var tri := PackedVector2Array([at + Vector2(8, 14) * z, at + Vector2(14, 14) * z, at + Vector2(11, 8) * z])
				draw_colored_polygon(tri, Color("4a2620"))
				draw_colored_polygon(PackedVector2Array([at + Vector2(9.5, 13) * z, at + Vector2(12.5, 13) * z, at + Vector2(11, 10) * z]), Color("f7c9a4"))
	for anchor in anchors:
		var a: int = int(anchor)
		if not City.is_civic(city.occupancy[a]) or services.working[a] != 0: continue
		var rect := Rect2(tile_rect(city.cell_of(a)).position, Vector2.ONE * TILE * City.footprint_size(city.occupancy[a]) * z)
		for pass_color in [[Color("2a2a2a"), 4 * z], [Color("f0be97"), 2 * z]]:
			draw_line(rect.position + Vector2(6, 6) * z, rect.end - Vector2(6, 6) * z, pass_color[0], pass_color[1])
			draw_line(Vector2(rect.end.x, rect.position.y) + Vector2(-6, 6) * z, Vector2(rect.position.x, rect.end.y) + Vector2(6, -6) * z, pass_color[0], pass_color[1])

## D38: original civic buildings for the original renderer. Police: a slate hall with a
## flat roof, a column porch and blue-grey windows. Fire: a brick hall with two large
## bay doors and a narrow hose tower.
func _draw_civic(kind: int, at: Vector2, rect: Rect2, z: float) -> void:
	var p := func(x: float, y: float) -> Vector2: return at + Vector2(x, y) * z
	var dark := Color("4b575a")
	draw_rect(rect.grow(-z), Color("6f7d72"))
	draw_rect(rect.grow(-2 * z), Color("c9c7a2"), false, z)
	if kind == City.POLICE:
		draw_rect(Rect2(p.call(5, 12), Vector2(38, 30) * z), Color("8c98a6"))
		draw_rect(Rect2(p.call(4, 9), Vector2(40, 4) * z), Color("3d4a5c"))
		for x in [9, 17, 31, 39]: draw_rect(Rect2(p.call(x - 1, 30), Vector2(2, 12) * z), Color("e3e0cf"))
		draw_rect(Rect2(p.call(7, 28), Vector2(34, 2) * z), Color("e3e0cf"))
		for x in [9, 33]: draw_rect(Rect2(p.call(x, 17), Vector2(6, 6) * z), Color("c9dcf5"))
		draw_rect(Rect2(p.call(21, 34), Vector2(6, 8) * z), dark)
	else:
		draw_rect(Rect2(p.call(4, 14), Vector2(30, 28) * z), Color("a8574a"))
		draw_rect(Rect2(p.call(3, 11), Vector2(32, 4) * z), Color("6e3a32"))
		for x in [7, 20]:
			draw_rect(Rect2(p.call(x, 26), Vector2(11, 16) * z), Color("e3d9b5"))
			for y in [30, 34, 38]: draw_line(p.call(x, y), p.call(x + 11, y), Color("9a917a"), z)
		draw_rect(Rect2(p.call(36, 4), Vector2(8, 38) * z), Color("8f4a3f"))
		draw_rect(Rect2(p.call(35, 2), Vector2(10, 3) * z), Color("6e3a32"))
		for y in [9, 17]: draw_rect(Rect2(p.call(38, y), Vector2(4, 4) * z), dark)

## D38: original signs drawn in every art mode so the two stations differ by shape:
## a shield for police, a flame for fire, on a dark plate.
func _draw_civic_sign(kind: int, at: Vector2, z: float) -> void:
	var c: Vector2 = at + Vector2(24, 20) * z
	draw_rect(Rect2(c - Vector2(7, 7) * z, Vector2(14, 14) * z), Color("2f3b40"))
	if kind == City.POLICE:
		var shield := PackedVector2Array([c + Vector2(-4, -4) * z, c + Vector2(4, -4) * z, c + Vector2(4, 1) * z, c + Vector2(0, 5) * z, c + Vector2(-4, 1) * z])
		draw_colored_polygon(shield, Color("c9dcf5"))
		draw_rect(Rect2(c + Vector2(-1, -2) * z, Vector2(2, 3) * z), Color("3d4a5c"))
	else:
		var flame := PackedVector2Array([c + Vector2(0, -5) * z, c + Vector2(4, 1) * z, c + Vector2(2, 5) * z, c + Vector2(-2, 5) * z, c + Vector2(-4, 1) * z])
		draw_colored_polygon(flame, Color("f2a65a"))
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -1) * z, c + Vector2(2, 3) * z, c + Vector2(-2, 3) * z]), Color("f6d76b"))

## D29 marker: four static L-shaped corners around the target footprint, distinct in
## shape from hover and stroke previews. No animation.
func _draw_guide_bracket() -> void:
	var z: float = float(zoom)
	var rect: Rect2 = tile_rect(guide_target)
	rect.size = Vector2.ONE * TILE * guide_size * z
	rect = rect.grow(2 * z)
	var arm: float = 5 * z
	for corner in [[rect.position, Vector2(1, 1)], [Vector2(rect.end.x, rect.position.y), Vector2(-1, 1)], [rect.end, Vector2(-1, -1)], [Vector2(rect.position.x, rect.end.y), Vector2(1, -1)]]:
		var at: Vector2 = corner[0]
		var dir: Vector2 = corner[1]
		for pass_color in [[Color("243f38"), 3 * z], [Color("f6d76b"), 1.5 * z]]:
			draw_line(at, at + Vector2(dir.x * arm, 0), pass_color[0], pass_color[1])
			draw_line(at, at + Vector2(0, dir.y * arm), pass_color[0], pass_color[1])

func _draw_footprint(anchor: int) -> void:
	var kind: int = city.occupancy[anchor]
	var size: int = City.footprint_size(kind)
	var at: Vector2 = tile_rect(Vector2i(anchor % city.width, anchor / city.width)).position
	var z: float = float(zoom)
	var rect := Rect2(at, Vector2.ONE * TILE * size * z)
	if City.is_civic(kind):
		if art != null: art.draw_civic(self, kind, at, size, z)
		else: _draw_civic(kind, at, rect, z)
		_draw_civic_sign(kind, at, z)
		_draw_marks(anchor, at, z)
		return
	if art != null:
		if kind == City.POWER:
			art.draw_station(self, at, size, z)
			# Original bolt sign: neither pack has a power-station sprite.
			draw_rect(Rect2(at + Vector2(25, 17) * z, Vector2(14, 14) * z), Color("3f5257"))
			_draw_bolt(at + Vector2(32, 24) * z, 2 * z, Color("f2d36b"))
		else:
			var color := Color("577c62") if kind == City.HOME else Color("557f94") if kind == City.SHOP else Color("9a7954")
			if not art.draw_lot(self, kind, city.development[anchor], at, size, z, color):
				_draw_zone_symbol(kind, 0, at + Vector2(16, 16) * z, z)
			_draw_stage_pips(city.development[anchor], at, size, z)
			_draw_marks(anchor, at, z)
		return
	if kind == City.POWER:
		_draw_station(at, rect, z)
	else:
		_draw_lot(anchor, at, rect, z)
		_draw_stage_pips(city.development[anchor], at, size, z)
		_draw_marks(anchor, at, z)

func _draw_power_mark(i: int, at: Vector2, z: float) -> void:
	# Shape, not colour alone: a bolt means supplied, a cross means an unpowered plot.
	var use: int = city.occupancy[i]
	var powered: bool = city.power.home_state[i] == city.power.POWERED if City.is_served(use) else city.power.carries_power(i)
	if (use != City.ROAD and not City.is_served(use)) or (use == City.ROAD and not powered):
		return
	var mark: Vector2 = at + Vector2(4, 12) * z
	draw_rect(Rect2(mark - Vector2(3, 3) * z, Vector2(7, 7) * z), Color("304842"))
	if powered:
		_draw_bolt(mark, z, Color("f2d36b"))
	else:
		var color := Color("f0be97")
		draw_line(mark + Vector2(-2, -2) * z, mark + Vector2(2, 2) * z, color, z)
		draw_line(mark + Vector2(-2, 2) * z, mark + Vector2(2, -2) * z, color, z)

## D30: one original code-drawn building per 3x3 lot. Zone families keep distinct
## silhouettes (pitched roof, awning, sawtooth roof) as well as colours.
func _draw_lot(i: int, at: Vector2, rect: Rect2, z: float) -> void:
	var kind: int = city.occupancy[i]
	var level: int = city.development[i]
	var color := Color("577c62") if kind == City.HOME else Color("557f94") if kind == City.SHOP else Color("9a7954")
	var wall := Color("e3d9b5")
	var dark := Color("4b575a")
	var ink := Color("6e5552")
	draw_rect(rect.grow(-z), color)
	draw_rect(rect.grow(-2 * z), Color("d4d3a8"), false, z)
	if level == 0:
		# An empty parcel shows its zone symbol on the middle tile.
		_draw_zone_symbol(kind, 0, at + Vector2(16, 16) * z, z)
		return
	var p := func(x: float, y: float) -> Vector2: return at + Vector2(x, y) * z
	if level >= 3:
		_draw_tall_lot(kind, level, p, z, wall, dark, ink)
		return
	match kind:
		City.HOME:
			var top: float = 22.0 if level == 1 else 15.0
			draw_rect(Rect2(p.call(12, top), Vector2(24, 40 - top) * z), wall)
			draw_colored_polygon(PackedVector2Array([p.call(9, top), p.call(24, top - 10), p.call(39, top)]), Color("a5604c"))
			draw_polyline(PackedVector2Array([p.call(9, top), p.call(24, top - 10), p.call(39, top)]), ink, z)
			draw_rect(Rect2(p.call(22, 32), Vector2(4, 8) * z), dark)
			var rows: Array = [26] if level == 1 else [19, 27]
			for y in rows:
				for x in [15, 29]: draw_rect(Rect2(p.call(x, y), Vector2(4, 4) * z), dark)
		City.SHOP:
			var top: float = 21.0 if level == 1 else 10.0
			draw_rect(Rect2(p.call(8, top), Vector2(32, 40 - top) * z), wall)
			var band: float = 21.0 if level == 1 else 23.0
			for x in range(6, 42, 6):
				draw_rect(Rect2(p.call(x, band - 4), Vector2(6, 5) * z), Color("c9775a") if (x / 6) % 2 == 0 else Color("efe3c0"))
			for x in [11, 27]: draw_rect(Rect2(p.call(x, band + 4), Vector2(10, 7) * z), Color("8fb3b5"))
			draw_rect(Rect2(p.call(22, 31), Vector2(4, 9) * z), dark)
			if level == 2:
				for x in [12, 22, 32]: draw_rect(Rect2(p.call(x, 13), Vector2(4, 4) * z), dark)
		_:
			var top: float = 22.0 if level == 1 else 16.0
			draw_rect(Rect2(p.call(6, top), Vector2(36, 40 - top) * z), Color("d8cfa6"))
			var teeth: PackedVector2Array = PackedVector2Array()
			for x in range(6, 42, 9):
				teeth.append(p.call(x, top))
				teeth.append(p.call(x + 9, top - 7))
				teeth.append(p.call(x + 9, top))
			draw_polyline(teeth, ink, z)
			draw_rect(Rect2(p.call(18, 30), Vector2(12, 10) * z), Color("6e6a5c"))
			if level == 2:
				draw_rect(Rect2(p.call(34, top - 14), Vector2(4, 8) * z), Color("8c6f4e"))
				for x in [9, 36]: draw_rect(Rect2(p.call(x, top + 4), Vector2(3, 3) * z), dark)

## D37: original taller buildings for levels 3-4 in the same zone families: flat-roofed
## residential blocks and a tower, a storeyed shop and an office block, and larger
## factories with more chimneys.
func _draw_tall_lot(kind: int, level: int, p: Callable, z: float, wall: Color, dark: Color, ink: Color) -> void:
	var tower: bool = level >= 4
	match kind:
		City.HOME:
			var left: float = 10.0 if tower else 7.0
			var width: float = 28.0 if tower else 34.0
			var top: float = 3.0 if tower else 9.0
			draw_rect(Rect2(p.call(left, top), Vector2(width, 40 - top) * z), wall)
			draw_rect(Rect2(p.call(left - 1, top - 2), Vector2(width + 2, 3) * z), Color("a5604c"))
			draw_rect(Rect2(p.call(left - 1, top - 2), Vector2(width + 2, 3) * z), ink, false, z)
			var rows: int = 5 if tower else 3
			for r in range(rows):
				for x in range(int(left) + 4, int(left + width) - 4, 7):
					draw_rect(Rect2(p.call(x, top + 4 + r * 6), Vector2(3, 3) * z), dark)
			draw_rect(Rect2(p.call(22, 33), Vector2(4, 7) * z), dark)
			if tower: draw_rect(Rect2(p.call(28, top - 6), Vector2(6, 4) * z), Color("8c8f86"))
		City.SHOP:
			var top: float = 2.0 if tower else 6.0
			draw_rect(Rect2(p.call(7, top), Vector2(34, 40 - top) * z), Color("cfd8d2") if tower else wall)
			if tower:
				for x in range(10, 38, 6):
					draw_rect(Rect2(p.call(x, top + 3), Vector2(3, 26) * z), Color("8fb3b5"))
				draw_rect(Rect2(p.call(7, 30), Vector2(34, 2) * z), dark)
			else:
				for r in range(2):
					for x in [12, 22, 32]: draw_rect(Rect2(p.call(x, top + 4 + r * 7), Vector2(4, 4) * z), dark)
			for x in range(6, 42, 6):
				draw_rect(Rect2(p.call(x, 27), Vector2(6, 4) * z), Color("c9775a") if (x / 6) % 2 == 0 else Color("efe3c0"))
			for x in [11, 27]: draw_rect(Rect2(p.call(x, 32), Vector2(10, 6) * z), Color("8fb3b5"))
			draw_rect(Rect2(p.call(22, 32), Vector2(4, 8) * z), dark)
		_:
			var top: float = 12.0 if tower else 16.0
			draw_rect(Rect2(p.call(3, top), Vector2(42, 40 - top) * z), Color("d8cfa6"))
			var teeth: PackedVector2Array = PackedVector2Array()
			for x in range(3, 45, 7):
				teeth.append(p.call(x, top))
				teeth.append(p.call(mini(x + 7, 45), top - 6))
				teeth.append(p.call(mini(x + 7, 45), top))
			draw_polyline(teeth, ink, z)
			var chimneys: Array = [8, 20, 34] if tower else [10, 34]
			for x in chimneys:
				draw_rect(Rect2(p.call(x, top - 16), Vector2(4, 10) * z), Color("8c6f4e"))
				draw_rect(Rect2(p.call(x, top - 16), Vector2(4, 2) * z), Color("b8a27a"))
			draw_rect(Rect2(p.call(14, 29), Vector2(20, 11) * z), Color("6e6a5c"))
			for x in [7, 38]: draw_rect(Rect2(p.call(x, top + 5), Vector2(3, 3) * z), dark)

## D37: an original stage marker on levels 3-4 lots in every art mode: one small square
## pip per level above 2, so the stage does not rely on the building art alone.
func _draw_stage_pips(level: int, at: Vector2, size: int, z: float) -> void:
	if level < 3: return
	var count: int = level - 2
	var origin: Vector2 = at + Vector2(size * TILE - 4 - 5 * count, 2) * z
	draw_rect(Rect2(origin - Vector2(1, 1) * z, Vector2(5 * count + 1, 6) * z), Color("304842"))
	for n in range(count):
		draw_rect(Rect2(origin + Vector2(5 * n + 1, 1) * z, Vector2(3, 3) * z), Color("f6d76b"))

func _draw_zone_symbol(kind: int, level: int, at: Vector2, z: float) -> void:
	var roof_y: int = 6 if level < 2 else 3
	var ink := Color("eeddb5") if level == 0 else Color("6e5552")
	if kind == City.HOME:
		draw_polyline(PackedVector2Array([at + Vector2(3, roof_y + 2) * z, at + Vector2(8, roof_y - 1) * z, at + Vector2(13, roof_y + 2) * z]), ink, z)
	elif kind == City.SHOP:
		draw_rect(Rect2(at + Vector2(3, roof_y) * z, Vector2(10, 2) * z), ink)
		for x in [3, 7, 11]: draw_rect(Rect2(at + Vector2(x, roof_y + 2) * z, Vector2(2, 2) * z), ink)
	else:
		draw_polyline(PackedVector2Array([at + Vector2(3, roof_y + 2) * z, at + Vector2(7, roof_y - 1) * z, at + Vector2(7, roof_y + 2) * z, at + Vector2(12, roof_y - 1) * z, at + Vector2(12, roof_y + 2) * z]), ink, z)

func _draw_bolt(center: Vector2, z: float, color: Color) -> void:
	var points := PackedVector2Array([center + Vector2(1, -3) * z, center + Vector2(-1, 0) * z,
		center + Vector2(1, 0) * z, center + Vector2(-1, 3) * z])
	draw_polyline(points, color, z)

func _draw_station(at: Vector2, rect: Rect2, z: float) -> void:
	# D30: an original 4x4 generating hall with two chimneys and a large bolt sign.
	draw_rect(rect.grow(-z), Color("3f5257"))
	draw_rect(rect.grow(-2 * z), Color("6d7f7d"), false, z)
	for chimney in [Rect2(14, 4, 5, 16), Rect2(44, 8, 5, 12)]:
		draw_rect(Rect2(at + chimney.position * z, chimney.size * z), Color("8c6f4e"))
		draw_rect(Rect2(at + chimney.position * z, Vector2(chimney.size.x, 2) * z), Color("b8a27a"))
	draw_rect(Rect2(at + Vector2(6, 19) * z, Vector2(52, 5) * z), Color("8c6f4e"))
	draw_rect(Rect2(at + Vector2(8, 24) * z, Vector2(48, 32) * z), Color("d8cfa6"))
	draw_rect(Rect2(at + Vector2(8, 56) * z, Vector2(48, 2) * z), Color("a59c7a"))
	draw_rect(Rect2(at + Vector2(27, 46) * z, Vector2(10, 10) * z), Color("4b575a"))
	draw_rect(Rect2(at + Vector2(25, 28) * z, Vector2(14, 14) * z), Color("3f5257"))
	_draw_bolt(at + Vector2(32, 35) * z, 2 * z, Color("f2d36b"))

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
