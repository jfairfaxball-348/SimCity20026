extends RefCounted
## Artwork kits (6 November 2026): draws the world with a CC0 Kenney tile pack instead
## of the original code-drawn placeholders. Presentation only: it reads the model and
## never changes it. Roguelike Modern City is the owner-chosen default (U22/U23); Tiny
## City stays an experimental option; the original renderer in world_view.gd remains
## the fallback. See docs/artwork-review/.
##
## Gaps in each pack are filled with explicitly marked ORIGINAL placeholders:
## water (both packs), grass (Tiny City: flat fill of its own sample grass colour),
## the zone outline and symbol on empty lots, and the power-station bolt sign.
const City = preload("res://scripts/sim/city_state.gd")
const TILE: int = 16
const MODES: Array[String] = ["original", "tiny_city", "modern_city"]
const LABELS: Dictionary = {"original": "Original", "tiny_city": "Tiny City", "modern_city": "Modern City"}
## Owner-chosen default (U23). "original" is the fallback for unknown modes.
const DEFAULT_MODE: String = "modern_city"
const TINY_SHEET := preload("res://assets/experiments/city_art/tiny_city/tilemap_packed.png")
const MODERN_SHEET := preload("res://assets/experiments/city_art/roguelike_modern_city/tilemap_packed.png")

## Original placeholder colours, identical to the original renderer.
const ORIGINAL_WATER := Color("527e80")
const ORIGINAL_WATER_ALT := Color("557f80")
const ORIGINAL_SAND := Color("c6bf8e")

var mode: String
var sheet: Texture2D
var columns: int
var spec: Dictionary

func _init(art_mode: String) -> void:
	mode = art_mode
	if mode == "tiny_city":
		sheet = TINY_SHEET
		columns = 12
		spec = tiny_spec()
	else:
		sheet = MODERN_SHEET
		columns = 37
		spec = modern_spec()

## Kenney Tiny City 1.0 (12x11 tiles of 16 px). Tile numbers are row-major indices.
static func tiny_spec() -> Dictionary:
	return {
		"grass": [Color8(132, 198, 105)], # pack has no grass tile: flat fill of its sample grass colour
		"asphalt": Color8(82, 96, 124),
		"curb": {"top": [63, Rect2(0, 0, 16, 8)], "bottom": [75, Rect2(0, 8, 16, 8)], "left": [61, Rect2(0, 0, 8, 16)], "right": [62, Rect2(8, 0, 8, 16)]},
		"trees": [80, 79, 71], # conifers 67/68 share the grass colour and vanish on it
		"park_tree": 80,
		"empty_lot": [88],
		"lots": {
			City.HOME: {1: [[0, 1, 2], [24, 25, 26], [48, 52, 53]], 2: [[4, 16, 5], [36, 40, 41], [48, 52, 53]]},
			City.SHOP: {1: [[6, 7, 8], [30, 31, 32], [56, 57, 59]], 2: [[10, 22, 11], [42, 46, 47], [56, 57, 59]]},
			City.WORKSHOP: {1: [[6, 7, 8], [30, 31, 32], [50, 51, 53]], 2: [[10, 22, 11], [36, 40, 41], [50, 51, 53]]},
		},
		"station": [[6, 7, 7, 8], [18, 19, 19, 20], [30, 31, 31, 32], [48, 50, 51, 53]],
		"station_props": [[87, Vector2i(0, 2)]],
	}

## Kenney Roguelike Modern City 2.0 (37x28 tiles of 16 px). Roofs use the pack's plain
## roof fills with an outline in the pack's own darker roof shade; facades are pack
## wall tiles with pack window/door/awning overlays.
static func modern_spec() -> Dictionary:
	return {
		"grass": [888, 889],
		"sand": 894,
		"water": Color8(99, 197, 207), # pack water exists only as pool tiles: flat fill of the pool colour
		"road": 714, "road_h": 712, "road_v": 749,
		"trees": [438, 440, 512],
		"park_tree": 438,
		"empty_lot": [892, 893],
		"roof": {City.HOME: [5, Color8(135, 81, 70)], City.SHOP: [29, Color8(180, 164, 136)], City.WORKSHOP: [13, Color8(100, 102, 105)], City.POWER: [21, Color8(134, 137, 142)]},
		"wall": {City.HOME: [185, 186, 188], City.SHOP: [193, 194, 196], City.WORKSHOP: [189, 190, 192], City.POWER: [189, 190, 192]},
		"front": {City.HOME: [580, 1019, 580], City.SHOP: [617, 800, 617], City.WORKSHOP: [582, 806, 807]},
		"upper": {City.HOME: [580, 580, 580], City.SHOP: [356, 357, 359], City.WORKSHOP: [582, 582, 582]},
		"roof_props": {City.WORKSHOP: 543},
		"station_props": [[543, Vector2i(0, 0)], [545, Vector2i(3, 0)], [804, Vector2i(1, 3)], [805, Vector2i(2, 3)], [322, Vector2i(0, 3)]],
	}

func tile(canvas: CanvasItem, index: int, at: Vector2, z: float) -> void:
	var src := Rect2((index % columns) * TILE, (index / columns) * TILE, TILE, TILE)
	canvas.draw_texture_rect_region(sheet, Rect2(at, Vector2.ONE * TILE * z), src)

func part(canvas: CanvasItem, index: int, region: Rect2, at: Vector2, z: float) -> void:
	var src := Rect2(Vector2((index % columns) * TILE, (index / columns) * TILE) + region.position, region.size)
	canvas.draw_texture_rect_region(sheet, Rect2(at + region.position * z, region.size * z), src)

func grass(canvas: CanvasItem, rect: Rect2, at: Vector2, z: float, variation: int) -> void:
	var options: Array = spec.grass
	var choice = options[variation % options.size()]
	if choice is Color: canvas.draw_rect(rect, choice)
	else: tile(canvas, int(choice), at, z)

## Ground, roads, parks and decoration for one cell. Lots and stations are drawn per footprint.
func draw_cell(canvas: CanvasItem, city: City, cell: Vector2i, i: int, rect: Rect2, at: Vector2, z: float, variation: int) -> void:
	if city.terrain[i] == City.WATER:
		if spec.has("water"): canvas.draw_rect(rect, spec.water)
		else: canvas.draw_rect(rect, ORIGINAL_WATER if variation % 3 else ORIGINAL_WATER_ALT) # original placeholder
		return
	var shore: bool = cell.x > 0 and city.terrain[i - 1] == City.WATER
	if shore and spec.has("sand"): tile(canvas, int(spec.sand), at, z)
	else: grass(canvas, rect, at, z, variation)
	if shore and not spec.has("sand"):
		canvas.draw_rect(Rect2(at, Vector2(2, 16) * z), ORIGINAL_SAND) # original placeholder strip
	match city.occupancy[i]:
		City.ROAD:
			draw_road(canvas, city, cell, rect, at, z)
		City.PARK:
			tile(canvas, int(spec.park_tree), at, z)
		City.EMPTY:
			if variation < 13: tile(canvas, int(spec.trees[variation % spec.trees.size()]), at, z)

func draw_road(canvas: CanvasItem, city: City, cell: Vector2i, rect: Rect2, at: Vector2, z: float) -> void:
	var linked: Dictionary = {}
	for side in [["top", Vector2i.UP], ["bottom", Vector2i.DOWN], ["left", Vector2i.LEFT], ["right", Vector2i.RIGHT]]:
		var n: Vector2i = cell + side[1]
		linked[side[0]] = city.inside(n) and city.occupancy[city.index(n)] == City.ROAD
	if spec.has("curb"):
		# Tiny City roads are two-tile-wide halves: build a one-tile road from the
		# pack's asphalt colour plus the pack's curb strips on unlinked sides.
		canvas.draw_rect(rect, spec.asphalt)
		for side in spec.curb:
			if not linked[side]: part(canvas, int(spec.curb[side][0]), spec.curb[side][1], at, z)
		return
	var horizontal: bool = (linked.left or linked.right) and not (linked.top or linked.bottom)
	var vertical: bool = (linked.top or linked.bottom) and not (linked.left or linked.right)
	tile(canvas, int(spec.road_h if horizontal else spec.road_v if vertical else spec.road), at, z)

## One building per 3x3 lot (D30). Empty lots show pack ground plus the ORIGINAL zone
## outline and symbol so zoning stays readable.
func draw_lot(canvas: CanvasItem, kind: int, level: int, at: Vector2, size: int, z: float, zone_color: Color) -> bool:
	if level == 0:
		var grounds: Array = spec.empty_lot
		for y in range(size):
			for x in range(size): tile(canvas, int(grounds[(x + y) % grounds.size()]), at + Vector2(x, y) * TILE * z, z)
		var rect := Rect2(at, Vector2.ONE * TILE * size * z)
		canvas.draw_rect(rect.grow(-z), Color(zone_color, 0.35))
		canvas.draw_rect(rect.grow(-2 * z), zone_color, false, 2 * z)
		return false # caller draws the original zone symbol
	if spec.has("lots"):
		# D37: Tiny City has no taller tiles; levels 3-4 reuse level 2 (the caller adds
		# the original stage pips).
		var rows: Array = spec.lots[kind][mini(level, 2)]
		for y in range(rows.size()):
			for x in range(rows[y].size()): tile(canvas, int(rows[y][x]), at + Vector2(x, y) * TILE * z, z)
		return true
	# D37: levels 3-4 are full-height facades (no visible roof rows) with a thin roof
	# edge; level 4 adds an ORIGINAL code-drawn parapet band.
	var roof_rows: int = 2 if level == 1 else 1 if level == 2 else 0
	_modern_building(canvas, kind, at, size, roof_rows, z)
	var front: Array = spec.front[kind]
	for x in range(size): tile(canvas, int(front[x]), at + Vector2(x, size - 1) * TILE * z, z)
	var upper: Array = spec.upper[kind]
	for row in range(1, size - roof_rows):
		for x in range(size): tile(canvas, int(upper[x]), at + Vector2(x, size - 1 - row) * TILE * z, z)
	if level >= 3:
		var roof: Array = spec.roof[kind]
		canvas.draw_rect(Rect2(at, Vector2(size * TILE, 3) * z), roof[1])
		if level >= 4: canvas.draw_rect(Rect2(at + Vector2(0, 3) * z, Vector2(size * TILE, 2) * z), Color(0.2, 0.22, 0.24, 0.85)) # original parapet
	if spec.roof_props.has(kind): tile(canvas, int(spec.roof_props[kind]), at + Vector2(size - 1, 0) * TILE * z, z)
	return true

func _modern_building(canvas: CanvasItem, kind: int, at: Vector2, size: int, roof_rows: int, z: float) -> void:
	var roof: Array = spec.roof[kind]
	var wall: Array = spec.wall[kind]
	for y in range(size):
		for x in range(size):
			var index: int = int(roof[0]) if y < roof_rows else int(wall[0 if x == 0 else 2 if x == size - 1 else 1])
			tile(canvas, index, at + Vector2(x, y) * TILE * z, z)
	canvas.draw_rect(Rect2(at, Vector2(size * TILE, roof_rows * TILE) * z).grow(-0.5 * z), roof[1], false, z)

func draw_station(canvas: CanvasItem, at: Vector2, size: int, z: float) -> void:
	if spec.has("station"):
		var rows: Array = spec.station
		for y in range(rows.size()):
			for x in range(rows[y].size()): tile(canvas, int(rows[y][x]), at + Vector2(x, y) * TILE * z, z)
	else:
		_modern_building(canvas, City.POWER, at, size, size - 1, z)
	for prop in spec.station_props:
		tile(canvas, int(prop[0]), at + Vector2(prop[1]) * TILE * z, z)
