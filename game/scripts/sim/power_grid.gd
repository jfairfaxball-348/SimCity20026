extends RefCounted
## Derived, scene-independent power networks and nearest-first allocation (D19).
## Never serialized and never consumes RNG. CityState rebuilds this with road
## access after initialization, validated decoding, and each successful command.
const Balance = preload("res://content/balance.gd")
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const NONE: int = -1
const NOT_HOME: int = 0
const POWERED: int = 1
const SHORTAGE: int = 2
const DISCONNECTED: int = 3
const NO_NETWORK: int = 4

## Per cell: network index for road/station tiles, otherwise NONE.
var network_of: PackedInt32Array = PackedInt32Array()
## Per cell: steps from the nearest station in the same network, otherwise NONE.
var distance: PackedInt32Array = PackedInt32Array()
## Per cell: home allocation state (NOT_HOME, POWERED, SHORTAGE, DISCONNECTED, NO_NETWORK).
var home_state: PackedByteArray = PackedByteArray()
## Per cell: network a powered plot draws from, or the nearest full network for a shortage.
var home_network: PackedInt32Array = PackedInt32Array()
## Per network, indexed in row-major order of each network's first tile.
var network_stations: PackedInt32Array = PackedInt32Array()
var network_capacity: PackedInt32Array = PackedInt32Array()
var network_used: PackedInt32Array = PackedInt32Array()
var network_short: PackedInt32Array = PackedInt32Array()
var station_count: int = 0
var total_capacity: int = 0
var total_used: int = 0
var powered_homes: int = 0
var short_homes: int = 0

func rebuild(city: RefCounted) -> void:
	var count: int = city.width * city.height
	# Explicit per-array resets: packed arrays inside an Array literal may be copies.
	network_of.resize(count)
	network_of.fill(NONE)
	distance.resize(count)
	distance.fill(NONE)
	home_network.resize(count)
	home_network.fill(NONE)
	home_state.resize(count)
	home_state.fill(NOT_HOME)
	network_stations.resize(0)
	network_capacity.resize(0)
	network_used.resize(0)
	network_short.resize(0)
	station_count = 0
	total_used = 0
	powered_homes = 0
	short_homes = 0
	_label_networks(city, count)
	total_capacity = station_count * Balance.POWER_CAPACITY
	_measure_distances(city, count)
	_allocate(city, count)

func _carries(city: RefCounted, i: int) -> bool:
	return city.occupancy[i] == city.ROAD or city.occupancy[i] == city.POWER

func _neighbour(city: RefCounted, i: int, direction: Vector2i) -> int:
	var x: int = i % city.width + direction.x
	var y: int = i / city.width + direction.y
	if x < 0 or y < 0 or x >= city.width or y >= city.height:
		return NONE
	return y * city.width + x

func _label_networks(city: RefCounted, count: int) -> void:
	# A row-major scan fixes network order; each flood fill is iterative.
	var queue: PackedInt32Array = PackedInt32Array()
	for start in range(count):
		if network_of[start] != NONE or not _carries(city, start): continue
		var id: int = network_stations.size()
		var stations: int = 0
		network_of[start] = id
		queue.resize(0)
		queue.append(start)
		var head: int = 0
		while head < queue.size():
			var i: int = queue[head]
			head += 1
			if city.occupancy[i] == city.POWER and city.footprint_anchor[i] != 0:
				stations += 1
			for direction in DIRECTIONS:
				var n: int = _neighbour(city, i, direction)
				if n != NONE and network_of[n] == NONE and _carries(city, n):
					network_of[n] = id
					queue.append(n)
		network_stations.append(stations)
		network_capacity.append(stations * Balance.POWER_CAPACITY)
		network_used.append(0)
		network_short.append(0)
		station_count += stations

func _measure_distances(city: RefCounted, count: int) -> void:
	# Multi-source search from every station at once, seeded in row-major order.
	var queue: PackedInt32Array = PackedInt32Array()
	for i in range(count):
		if city.occupancy[i] == city.POWER:
			distance[i] = 0
			queue.append(i)
	var head: int = 0
	while head < queue.size():
		var i: int = queue[head]
		head += 1
		for direction in DIRECTIONS:
			var n: int = _neighbour(city, i, direction)
			if n != NONE and distance[n] == NONE and _carries(city, n):
				distance[n] = distance[i] + 1
				queue.append(n)

func _allocate(city: RefCounted, count: int) -> void:
	# D30: lots (state kept at their anchors) touching a sourced network through
	# any perimeter tile are served by (nearest distance, anchor index).
	# D38: police and fire stations draw one unit each in the same order.
	var order: Array[int] = []
	for i in city.lot_anchors + city.civic_anchors:
		var nearest: int = NONE
		var touches: bool = false
		for n in city.perimeter(i):
			if network_of[n] == NONE: continue
			touches = true
			if distance[n] != NONE and (nearest == NONE or distance[n] + 1 < nearest):
				nearest = distance[n] + 1
		if nearest == NONE:
			home_state[i] = DISCONNECTED if touches else NO_NETWORK
		else:
			order.append(nearest * count + i)
	order.sort()
	for key in order:
		var i: int = key % count
		var chosen: int = NONE
		var chosen_distance: int = 0
		var nearest_network: int = NONE
		var nearest_distance: int = 0
		for n in city.perimeter(i):
			if network_of[n] == NONE or distance[n] == NONE: continue
			var network: int = network_of[n]
			var steps: int = distance[n] + 1
			if nearest_network == NONE or steps < nearest_distance or (steps == nearest_distance and network < nearest_network):
				nearest_network = network
				nearest_distance = steps
			if network_used[network] + Balance.HOME_POWER_DEMAND > network_capacity[network]: continue
			if chosen == NONE or steps < chosen_distance or (steps == chosen_distance and network < chosen):
				chosen = network
				chosen_distance = steps
		if chosen != NONE:
			network_used[chosen] += Balance.HOME_POWER_DEMAND
			total_used += Balance.HOME_POWER_DEMAND
			home_state[i] = POWERED
			home_network[i] = chosen
			powered_homes += 1
		else:
			home_state[i] = SHORTAGE
			home_network[i] = nearest_network
			network_short[nearest_network] += 1
			short_homes += 1

func network_at(city: RefCounted, cell: Vector2i) -> int:
	return network_of[city.index(cell)] if city.inside(cell) else NONE

## True for road/station tiles whose network includes at least one station.
func carries_power(i: int) -> bool:
	return network_of[i] != NONE and network_stations[network_of[i]] > 0

## Reason for the lot covering this cell (any of its tiles may be given).
func home_reason(city: RefCounted, cell: Vector2i) -> String:
	if not city.inside(cell) or not city.is_served(city.occupancy[city.index(cell)]):
		return "not_home"
	var anchor: int = city.anchor_at(cell)
	if anchor < 0: return "not_home"
	match home_state[anchor]:
		POWERED: return "powered"
		SHORTAGE: return "shortage"
	if station_count == 0: return "no_source"
	return "disconnected" if home_state[anchor] == DISCONNECTED else "no_adjacent_network"
