extends RefCounted
## D33 / D36: derived land value. Parks and water raise it; developed industry nearby
## lowers it for residential and commercial lots; commercial lots also gain from
## developed residential lots nearby (customers). Industry ignores land value and is
## ordered by freight steps to the outside link instead. Never saved.
const Balance = preload("res://content/balance.gd")
const NONE: int = -1
## Per tile: 1 when a water tile is within WATER_RADIUS side-steps (terrain is immutable).
var water_near: PackedByteArray = PackedByteArray()
## Per tile: developed industrial lots within NUISANCE_RADIUS of this tile.
var tile_nuisance: PackedByteArray = PackedByteArray()
## Per tile: overlay value (a lot's tiles show that lot's value).
var tile_score: PackedInt32Array = PackedInt32Array()
## Per lot anchor: value and its parts.
var lot_score: PackedInt32Array = PackedInt32Array()
var lot_water: PackedByteArray = PackedByteArray()
var lot_workshops: PackedByteArray = PackedByteArray()
## D36: developed residential lots within CUSTOMER_RADIUS of a commercial lot.
var lot_customers: PackedByteArray = PackedByteArray()
## D36: road steps from the outside-link road over connected roads (NONE elsewhere).
var road_steps: PackedInt32Array = PackedInt32Array()
## D36: fewest road steps from the link to a connected road beside the lot (NONE if none).
var lot_freight: PackedInt32Array = PackedInt32Array()
var _water_size: Vector2i = Vector2i(-1, -1)

## Terrain never changes in play, so the water field is recomputed only with the
## other derived state (rebuild_derived), or when the map size changes.
func rebuild_terrain(city: RefCounted) -> void:
	var count: int = city.width * city.height
	water_near.resize(count)
	water_near.fill(0)
	for i in range(count):
		if city.terrain[i] != city.WATER: continue
		var center: Vector2i = city.cell_of(i)
		for dy in range(-Balance.WATER_RADIUS, Balance.WATER_RADIUS + 1):
			var reach: int = Balance.WATER_RADIUS - absi(dy)
			for dx in range(-reach, reach + 1):
				var cell: Vector2i = center + Vector2i(dx, dy)
				if city.inside(cell): water_near[city.index(cell)] = 1
	_water_size = Vector2i(city.width, city.height)

func rebuild(city: RefCounted) -> void:
	var count: int = city.width * city.height
	if water_near.size() != count or _water_size != Vector2i(city.width, city.height): rebuild_terrain(city)
	tile_nuisance.resize(count)
	tile_nuisance.fill(0)
	lot_score.resize(count)
	lot_score.fill(0)
	lot_water.resize(count)
	lot_water.fill(0)
	lot_workshops.resize(count)
	lot_workshops.fill(0)
	lot_customers.resize(count)
	lot_customers.fill(0)
	var size: int = Balance.LOT_SIZE
	var radius: int = Balance.NUISANCE_RADIUS
	for w in city.lot_anchors:
		if city.occupancy[w] != city.WORKSHOP or city.development[w] == 0: continue
		var counted: Dictionary = {}
		for i in _near(city, w, radius):
			tile_nuisance[i] = mini(255, tile_nuisance[i] + 1)
			var owner: int = city.footprint_owner[i]
			if owner >= 0 and (city.occupancy[owner] == city.HOME or city.occupancy[owner] == city.SHOP) and not counted.has(owner):
				counted[owner] = true
				lot_workshops[owner] = mini(255, lot_workshops[owner] + 1)
	for h in city.lot_anchors:
		if city.occupancy[h] != city.HOME or city.development[h] == 0: continue
		var counted: Dictionary = {}
		for i in _near(city, h, Balance.CUSTOMER_RADIUS):
			var owner: int = city.footprint_owner[i]
			if owner >= 0 and city.occupancy[owner] == city.SHOP and not counted.has(owner):
				counted[owner] = true
				lot_customers[owner] = mini(255, lot_customers[owner] + 1)
	for a in city.lot_anchors:
		for i in city.footprint_cells(a, size):
			if water_near[i] != 0:
				lot_water[a] = 1
				break
		lot_score[a] = lot_value(city, a)
	tile_score.resize(count)
	for i in range(count):
		var owner: int = city.footprint_owner[i]
		if owner >= 0 and city.is_zone(city.occupancy[owner]):
			tile_score[i] = lot_score[owner]
		else:
			tile_score[i] = score(city.amenity.covered[i] != 0, water_near[i] != 0, tile_nuisance[i])
	_rebuild_freight(city)

## Tiles within the given side-steps of a lot footprint, including the footprint.
func _near(city: RefCounted, anchor: int, radius: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	var origin: Vector2i = city.cell_of(anchor)
	var size: int = Balance.LOT_SIZE
	for y in range(origin.y - radius, origin.y + size + radius):
		for x in range(origin.x - radius, origin.x + size + radius):
			var cell := Vector2i(x, y)
			if city.inside(cell) and city.distance_to_footprint(cell, anchor, size) <= radius: out.append(city.index(cell))
	return out

static func score(park: bool, water: bool, workshops: int) -> int:
	return (Balance.DESIRABILITY_PARK if park else 0) + (Balance.DESIRABILITY_WATER if water else 0) - Balance.NUISANCE_PER_WORKSHOP * mini(workshops, Balance.NUISANCE_COUNT_LIMIT)

func lot_value(city: RefCounted, a: int) -> int:
	var park: bool = city.amenity.lot_covered[a] != 0
	var kind: int = city.occupancy[a]
	if kind == city.HOME: return score(park, lot_water[a] != 0, lot_workshops[a])
	if kind == city.SHOP: return score(park, lot_water[a] != 0, lot_workshops[a]) + customers(a)
	if kind == city.WORKSHOP: return score(park, lot_water[a] != 0, 0)
	return 0

func customers(a: int) -> int:
	return Balance.CUSTOMER_BONUS * mini(lot_customers[a], Balance.CUSTOMER_COUNT_LIMIT)

## Breadth-first road steps from the link road over connected roads (fixed neighbour order).
func _rebuild_freight(city: RefCounted) -> void:
	var count: int = city.width * city.height
	road_steps.resize(count)
	road_steps.fill(NONE)
	lot_freight.resize(count)
	lot_freight.fill(NONE)
	var root: Vector2i = city.access.root
	if root.x < 0 or city.access.connected_roads[city.index(root)] == 0: return
	var queue := PackedInt32Array([city.index(root)])
	road_steps[queue[0]] = 0
	var head: int = 0
	while head < queue.size():
		var i: int = queue[head]
		head += 1
		var cell: Vector2i = city.cell_of(i)
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = cell + direction
			if not city.inside(next): continue
			var n: int = city.index(next)
			if city.access.connected_roads[n] != 0 and road_steps[n] == NONE:
				road_steps[n] = road_steps[i] + 1
				queue.append(n)
	for a in city.lot_anchors:
		var best: int = NONE
		for n in city.perimeter(a):
			if road_steps[n] != NONE and (best == NONE or road_steps[n] < best): best = road_steps[n]
		lot_freight[a] = best

## Highest level a lot may reach (D33/D36/D37): residential and commercial lots by land
## value (below 0 held at 1; then gated at 2 until the D37 level-3 and level-4 values);
## industry by town residents (workforce) instead.
func cap(city: RefCounted, anchor: int) -> int:
	if city.occupancy[anchor] == city.WORKSHOP:
		var workforce: int = city.growth.population
		if workforce >= Balance.WORKFORCE_LEVEL4: return Balance.MAX_LEVEL
		if workforce >= Balance.WORKFORCE_LEVEL3: return 3
		return Balance.GATED_LEVEL
	if city.occupancy[anchor] != city.HOME and city.occupancy[anchor] != city.SHOP: return Balance.MAX_LEVEL
	var value: int = lot_score[anchor]
	var kind: int = city.occupancy[anchor]
	if value < 0: return Balance.HELD_LEVEL
	if value >= Balance.value_needed(kind, 4): return Balance.MAX_LEVEL
	if value >= Balance.value_needed(kind, 3): return 3
	return Balance.GATED_LEVEL

## D37: display-only wealth band of a developed residential lot.
func wealth(city: RefCounted, anchor: int) -> String:
	if city.occupancy[anchor] != city.HOME or city.development[anchor] == 0: return ""
	var value: int = lot_score[anchor]
	return "well-off" if value >= Balance.LEVEL4_VALUE else "comfortable" if value >= Balance.LEVEL3_VALUE else "modest"

## Non-zero parts of a lot value, e.g. "park +2, trade +1, industry −4".
func parts(city: RefCounted, anchor: int) -> String:
	var out: Array[String] = []
	if city.amenity.lot_covered[anchor] != 0: out.append("park +%d" % Balance.DESIRABILITY_PARK)
	if lot_water[anchor] != 0: out.append("water +%d" % Balance.DESIRABILITY_WATER)
	if city.occupancy[anchor] == city.SHOP and customers(anchor) > 0: out.append("trade +%d" % customers(anchor))
	var shops: int = mini(lot_workshops[anchor], Balance.NUISANCE_COUNT_LIMIT)
	if shops > 0 and city.occupancy[anchor] != city.WORKSHOP: out.append("industry −%d" % (Balance.NUISANCE_PER_WORKSHOP * shops))
	return ", ".join(out)
