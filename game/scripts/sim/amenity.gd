extends RefCounted
## D26: bounded local coverage; overlapping parks do not stack.
const Balance = preload("res://content/balance.gd")
var covered: PackedByteArray = PackedByteArray()

func rebuild(city: RefCounted) -> void:
	covered.resize(city.width * city.height)
	covered.fill(0)
	for i in range(covered.size()):
		if city.occupancy[i] != city.PARK: continue
		var center := Vector2i(i % city.width, i / city.width)
		for dy in range(-Balance.PARK_RADIUS, Balance.PARK_RADIUS + 1):
			var reach: int = Balance.PARK_RADIUS - absi(dy)
			for dx in range(-reach, reach + 1):
				var cell := center + Vector2i(dx, dy)
				if city.inside(cell): covered[city.index(cell)] = 1
