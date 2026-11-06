extends RefCounted
## D38: derived police and fire coverage. A station works with road access and an
## allocated power unit; a working station covers zone lots whose footprint is within
## SERVICE_RADIUS side-steps of its own (terrain ignored, no stacking). Never saved and
## never consumes RNG. CityState rebuilds this after access and power.
const Balance = preload("res://content/balance.gd")
## Per station anchor: 1 when the station works.
var working: PackedByteArray = PackedByteArray()
## Per tile: 1 within reach of a working police / fire station (overlay).
var police_tile: PackedByteArray = PackedByteArray()
var fire_tile: PackedByteArray = PackedByteArray()
## Per zone-lot anchor: 1 when covered by a working police / fire station.
var lot_police: PackedByteArray = PackedByteArray()
var lot_fire: PackedByteArray = PackedByteArray()
## Per station anchor: zone lots it covers.
var station_lots: PackedInt32Array = PackedInt32Array()
var police_count: int = 0
var fire_count: int = 0
var idle_count: int = 0

func rebuild(city: RefCounted) -> void:
	var count: int = city.width * city.height
	# Explicit per-array resets (no aliasing of packed arrays).
	working.resize(count)
	working.fill(0)
	police_tile.resize(count)
	police_tile.fill(0)
	fire_tile.resize(count)
	fire_tile.fill(0)
	lot_police.resize(count)
	lot_police.fill(0)
	lot_fire.resize(count)
	lot_fire.fill(0)
	station_lots.resize(count)
	station_lots.fill(0)
	police_count = 0
	fire_count = 0
	idle_count = 0
	var size: int = Balance.CIVIC_SIZE
	var radius: int = Balance.SERVICE_RADIUS
	for s in city.civic_anchors:
		var police: bool = city.occupancy[s] == city.POLICE
		if police: police_count += 1
		else: fire_count += 1
		if not works(city, s):
			idle_count += 1
			continue
		working[s] = 1
		var origin: Vector2i = city.cell_of(s)
		for y in range(maxi(0, origin.y - radius), mini(city.height, origin.y + size + radius)):
			for x in range(maxi(0, origin.x - radius), mini(city.width, origin.x + size + radius)):
				if city.distance_to_footprint(Vector2i(x, y), s, size) > radius: continue
				if police: police_tile[y * city.width + x] = 1
				else: fire_tile[y * city.width + x] = 1
		for a in city.lot_anchors:
			if city.footprint_gap(s, size, a, Balance.LOT_SIZE) > radius: continue
			if police: lot_police[a] = 1
			else: lot_fire[a] = 1
			station_lots[s] += 1

## Road access and an allocated power unit (the same test as a serviced lot).
static func works(city: RefCounted, anchor: int) -> bool:
	return city.access.served_homes[anchor] != 0 and city.power.home_state[anchor] == city.power.POWERED

func covered(anchor: int) -> bool:
	return lot_police[anchor] != 0 and lot_fire[anchor] != 0

## D38: highest level allowed by services alone.
func level_cap(anchor: int) -> int:
	return Balance.MAX_LEVEL if covered(anchor) else Balance.SERVICE_GATED_LEVEL

## Inspector wording for a lot's cover.
func cover_text(anchor: int) -> String:
	var p: bool = lot_police[anchor] != 0
	var f: bool = lot_fire[anchor] != 0
	return "police and fire cover" if p and f else "police cover only" if p else "fire cover only" if f else "no police or fire cover"

## The missing services of a lot, e.g. "fire" or "police and fire" ("" when covered).
func missing(anchor: int) -> String:
	var out: Array[String] = []
	if lot_police[anchor] == 0: out.append("police")
	if lot_fire[anchor] == 0: out.append("fire")
	return " and ".join(out)
