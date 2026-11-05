extends RefCounted
## Derived, scene-independent access. Never serialized and never consumes RNG.
## All successful construction commands rebuild this bounded map synchronously.
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
var root: Vector2i = Vector2i(-1, -1)
var connected_roads: PackedByteArray = PackedByteArray()
var served_homes: PackedByteArray = PackedByteArray()

func rebuild(city: RefCounted) -> void:
	root = _find_root(city)
	connected_roads.resize(city.width * city.height)
	connected_roads.fill(0)
	served_homes.resize(city.width * city.height)
	served_homes.fill(0)
	if root.x < 0 or city.occupancy[city.index(root)] != city.ROAD:
		return
	var queue: Array[Vector2i] = [root]
	connected_roads[city.index(root)] = 1
	var head: int = 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for direction in DIRECTIONS:
			var neighbour: Vector2i = cell + direction
			if not city.inside(neighbour): continue
			var i: int = city.index(neighbour)
			if city.is_zone(city.occupancy[i]):
				served_homes[i] = 1
			elif city.occupancy[i] == city.ROAD and connected_roads[i] == 0:
				connected_roads[i] = 1
				queue.append(neighbour)

func _find_root(city: RefCounted) -> Vector2i:
	var preferred := Vector2i(city.width - 1, city.height / 2)
	var chosen := Vector2i(-1, -1)
	var best_distance: int = city.width + city.height
	# Row-major scan supplies a fixed tie-break, including unusual legacy terrain.
	for y in range(city.height):
		for x in range(city.width):
			if x != 0 and x != city.width - 1 and y != 0 and y != city.height - 1: continue
			var cell := Vector2i(x, y)
			if city.terrain[city.index(cell)] != city.LAND: continue
			var distance: int = absi(x - preferred.x) + absi(y - preferred.y)
			if distance < best_distance:
				chosen = cell
				best_distance = distance
	return chosen

func home_reason(city: RefCounted, cell: Vector2i) -> String:
	if not city.inside(cell) or not city.is_zone(city.occupancy[city.index(cell)]):
		return "not_home"
	if root.x < 0: return "no_outside_link"
	if cell == root: return "link_occupied"
	if served_homes[city.index(cell)] != 0: return "connected"
	for direction in DIRECTIONS:
		var neighbour: Vector2i = cell + direction
		if city.inside(neighbour) and city.occupancy[city.index(neighbour)] == city.ROAD:
			return "disconnected_road"
	return "no_adjacent_road"
