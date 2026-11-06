extends RefCounted
## D26: bounded local coverage; overlapping parks do not stack.
## D30: a lot is covered when any of its tiles is within the park radius.
const Balance = preload("res://content/balance.gd")
var covered: PackedByteArray = PackedByteArray()
var lot_covered: PackedByteArray = PackedByteArray()

func rebuild(city: RefCounted) -> void:
	covered.resize(city.width * city.height)
	covered.fill(0)
	lot_covered.resize(city.width * city.height)
	lot_covered.fill(0)
	var parks: Array[Vector2i] = []
	for i in range(covered.size()):
		if city.occupancy[i] != city.PARK: continue
		var center := Vector2i(i % city.width, i / city.width)
		parks.append(center)
		for dy in range(-Balance.PARK_RADIUS, Balance.PARK_RADIUS + 1):
			var reach: int = Balance.PARK_RADIUS - absi(dy)
			for dx in range(-reach, reach + 1):
				var cell := center + Vector2i(dx, dy)
				if city.inside(cell): covered[city.index(cell)] = 1
	for anchor in city.lot_anchors:
		for park in parks:
			if city.distance_to_footprint(park, anchor) <= Balance.PARK_RADIUS:
				lot_covered[anchor] = 1
				break
