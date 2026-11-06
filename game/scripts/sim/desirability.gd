extends RefCounted
## D33: derived neighbourhood desirability for home lots. Parks and water attract;
## developed workshops nearby deter. Never saved; rebuilt with growth totals.
const Balance = preload("res://content/balance.gd")
## Per tile: 1 when a water tile is within WATER_RADIUS side-steps (terrain is immutable).
var water_near: PackedByteArray = PackedByteArray()
## Per tile: developed workshop lots within NUISANCE_RADIUS of this tile.
var tile_nuisance: PackedByteArray = PackedByteArray()
## Per tile: overlay score (a home lot's tiles show that lot's score).
var tile_score: PackedInt32Array = PackedInt32Array()
## Per home-lot anchor: score and its parts.
var lot_score: PackedInt32Array = PackedInt32Array()
var lot_water: PackedByteArray = PackedByteArray()
var lot_workshops: PackedByteArray = PackedByteArray()
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
	var size: int = Balance.LOT_SIZE
	var radius: int = Balance.NUISANCE_RADIUS
	for w in city.lot_anchors:
		if city.occupancy[w] != city.WORKSHOP or city.development[w] == 0: continue
		var origin: Vector2i = city.cell_of(w)
		var counted: Dictionary = {}
		for y in range(origin.y - radius, origin.y + size + radius):
			for x in range(origin.x - radius, origin.x + size + radius):
				var cell := Vector2i(x, y)
				if not city.inside(cell) or city.distance_to_footprint(cell, w, size) > radius: continue
				var i: int = city.index(cell)
				tile_nuisance[i] = mini(255, tile_nuisance[i] + 1)
				var owner: int = city.footprint_owner[i]
				if owner >= 0 and city.occupancy[owner] == city.HOME and not counted.has(owner):
					counted[owner] = true
					lot_workshops[owner] = mini(255, lot_workshops[owner] + 1)
	for a in city.lot_anchors:
		if city.occupancy[a] != city.HOME: continue
		for i in city.footprint_cells(a, size):
			if water_near[i] != 0:
				lot_water[a] = 1
				break
		lot_score[a] = score(city.amenity.lot_covered[a] != 0, lot_water[a] != 0, lot_workshops[a])
	tile_score.resize(count)
	for i in range(count):
		var owner: int = city.footprint_owner[i]
		if owner >= 0 and city.occupancy[owner] == city.HOME:
			tile_score[i] = lot_score[owner]
		else:
			tile_score[i] = score(city.amenity.covered[i] != 0, water_near[i] != 0, tile_nuisance[i])

static func score(park: bool, water: bool, workshops: int) -> int:
	return (Balance.DESIRABILITY_PARK if park else 0) + (Balance.DESIRABILITY_WATER if water else 0) - Balance.NUISANCE_PER_WORKSHOP * mini(workshops, Balance.NUISANCE_COUNT_LIMIT)

## Highest level a home lot may reach (D33); other lots use the D22 maximum.
func cap(city: RefCounted, anchor: int) -> int:
	if city.occupancy[anchor] == city.HOME and lot_score[anchor] < 0: return Balance.HELD_LEVEL
	return Balance.MAX_LEVEL

## Non-zero parts of a home lot's score, e.g. "park +2, industry −4".
func parts(city: RefCounted, anchor: int) -> String:
	var out: Array[String] = []
	if city.amenity.lot_covered[anchor] != 0: out.append("park +%d" % Balance.DESIRABILITY_PARK)
	if lot_water[anchor] != 0: out.append("water +%d" % Balance.DESIRABILITY_WATER)
	var shops: int = mini(lot_workshops[anchor], Balance.NUISANCE_COUNT_LIMIT)
	if shops > 0: out.append("industry −%d" % (Balance.NUISANCE_PER_WORKSHOP * shops))
	return ", ".join(out)
