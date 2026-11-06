extends RefCounted
## Authoritative data and synchronous ordered commands; no scene dependencies.
## Road access and power are derived from terrain/occupancy and never serialized.
const Balance = preload("res://content/balance.gd")
const Access = preload("res://scripts/sim/road_access.gd")
const Power = preload("res://scripts/sim/power_grid.gd")
const Growth = preload("res://scripts/sim/growth.gd")
const Economy = preload("res://scripts/sim/economy.gd")
const Amenity = preload("res://scripts/sim/amenity.gd")
const Desirability = preload("res://scripts/sim/desirability.gd")
const Services = preload("res://scripts/sim/services.gd")
const LAND: int = 0
const WATER: int = 1
const EMPTY: int = 0
const ROAD: int = 1
const HOME: int = 2
const POWER: int = 3
const SHOP: int = 4
const WORKSHOP: int = 5
const PARK: int = 6
## D38 civic services.
const POLICE: int = 7
const FIRE: int = 8
const MAX_TICK: int = 1_000_000_000
const MAX_PENDING_US: int = 3_600_000_000
const SCHEMA: int = 12
const SIMULATION: String = "r3-1"
const CONTENT: String = "r3-1"
## Supported earlier format (M1/M2a): IDs 0..2 only, migrated in memory (D20).
const LEGACY_SCHEMA: int = 1
const LEGACY_VERSION: String = "m1-1"
const TOOLS: Dictionary = {"road": ROAD, "home": HOME, "shop": SHOP, "workshop": WORKSHOP, "power": POWER, "park": PARK, "police": POLICE, "fire": FIRE, "clear": EMPTY}
const NO_LOT: int = -1

var width: int = 64
var height: int = 64
var seed_value: int = 198624
var terrain: PackedByteArray = PackedByteArray()
var occupancy: PackedByteArray = PackedByteArray()
var development: PackedByteArray = PackedByteArray()
var service_loss: PackedByteArray = PackedByteArray()
## D30: 1 on the top-left tile of every zone lot and power station, otherwise 0.
var footprint_anchor: PackedByteArray = PackedByteArray()
var cash: int = Balance.STARTING_CASH
## D32: town tax rate in whole percent.
var tax_rate: int = Balance.TAX_STANDARD
var tick: int = 0
var pending_us: int = 0
var sequence: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Derived: anchor index owning each footprint tile, or NO_LOT. Rebuilt, never saved.
var footprint_owner: PackedInt32Array = PackedInt32Array()
## Derived row-major anchor lists.
var lot_anchors: PackedInt32Array = PackedInt32Array()
var station_anchors: PackedInt32Array = PackedInt32Array()
## D38: police and fire station anchors, row-major.
var civic_anchors: PackedInt32Array = PackedInt32Array()
var access: Access = Access.new()
var power: Power = Power.new()
var growth: Growth = Growth.new()
var amenity: Amenity = Amenity.new()
var desirability: Desirability = Desirability.new()
var services: Services = Services.new()
var project: Dictionary = {"completed": false, "park_index": -1}
var last_budget: Dictionary = {}
## D39: one record per settlement, [tick, residents, commercial jobs, industrial jobs,
## closing cash, net], oldest first, at most Balance.HISTORY_LIMIT.
var history: Array = []
var budget: Dictionary = {}

func initialize(map_seed: int = 198624, map_width: int = 64, map_height: int = 64) -> void:
	width = clampi(map_width, 8, 128)
	height = clampi(map_height, 8, 128)
	seed_value = map_seed
	rng.seed = seed_value
	cash = Balance.STARTING_CASH
	tax_rate = Balance.TAX_STANDARD
	tick = 0
	pending_us = 0
	sequence = 0
	last_budget = {}
	history = []
	project = {"completed": false, "park_index": -1}
	terrain.resize(width * height)
	terrain.fill(LAND)
	occupancy.resize(width * height)
	occupancy.fill(EMPTY)
	development.resize(width * height)
	development.fill(0)
	service_loss.resize(width * height)
	service_loss.fill(0)
	footprint_anchor.resize(width * height)
	footprint_anchor.fill(0)
	# An original seeded shoreline. The central starting ground is always connected.
	for y in range(height):
		var shoreline: int = clampi(width / 10 + y / 14 + rng.randi_range(-1, 1), 1, width - 1)
		for x in range(shoreline):
			terrain[index(Vector2i(x, y))] = WATER
	rebuild_derived()

func rebuild_derived() -> void:
	# Terrain is immutable in play. Call after initialization/validated decoding,
	# or from fixture setup after changing terrain. Commands own occupancy edits.
	# Footprints first; access next because power placement rules read the root.
	rebuild_footprints()
	access.rebuild(self)
	power.rebuild(self)
	amenity.rebuild(self)
	services.rebuild(self)
	desirability.rebuild_terrain(self)
	growth.refresh(self)
	budget = Economy.inputs(self)

func rebuild_footprints() -> void:
	var count: int = width * height
	footprint_owner.resize(count)
	footprint_owner.fill(NO_LOT)
	lot_anchors.resize(0)
	station_anchors.resize(0)
	civic_anchors.resize(0)
	for i in range(count):
		if footprint_anchor[i] == 0: continue
		var size: int = footprint_size(occupancy[i])
		for cell in footprint_cells(i, size):
			footprint_owner[cell] = i
		if occupancy[i] == POWER: station_anchors.append(i)
		elif is_civic(occupancy[i]): civic_anchors.append(i)
		else: lot_anchors.append(i)

static func is_zone(kind: int) -> bool:
	return kind in [HOME, SHOP, WORKSHOP]

## D38: police and fire stations.
static func is_civic(kind: int) -> bool:
	return kind == POLICE or kind == FIRE

## Footprints that need road access and a power unit: zone lots and civic stations.
static func is_served(kind: int) -> bool:
	return is_zone(kind) or is_civic(kind)

## D30: zones occupy LOT_SIZE squares, stations STATION_SIZE squares, the rest one tile.
static func footprint_size(kind: int) -> int:
	if is_zone(kind): return Balance.LOT_SIZE
	if kind == POWER: return Balance.STATION_SIZE
	if is_civic(kind): return Balance.CIVIC_SIZE
	return 1

static func is_footprint_kind(kind: int) -> bool:
	return footprint_size(kind) > 1

func is_lot_anchor(i: int) -> bool:
	return footprint_anchor[i] != 0 and is_zone(occupancy[i])

## Anchor index of the lot or station covering this cell, or NO_LOT.
func anchor_at(cell: Vector2i) -> int:
	return footprint_owner[index(cell)] if inside(cell) else NO_LOT

func footprint_cells(anchor: int, size: int = -1) -> PackedInt32Array:
	if size < 0: size = footprint_size(occupancy[anchor])
	var out: PackedInt32Array = PackedInt32Array()
	var x0: int = anchor % width
	var y0: int = anchor / width
	for y in range(y0, mini(height, y0 + size)):
		for x in range(x0, mini(width, x0 + size)):
			out.append(y * width + x)
	return out

## Side-sharing neighbours outside the footprint, in row-major order; corners excluded.
func perimeter(anchor: int, size: int = -1) -> PackedInt32Array:
	if size < 0: size = footprint_size(occupancy[anchor])
	var x0: int = anchor % width
	var y0: int = anchor / width
	var out: PackedInt32Array = PackedInt32Array()
	if y0 > 0:
		for x in range(x0, x0 + size): out.append((y0 - 1) * width + x)
	for y in range(y0, y0 + size):
		if x0 > 0: out.append(y * width + x0 - 1)
		if x0 + size < width: out.append(y * width + x0 + size)
	if y0 + size < height:
		for x in range(x0, x0 + size): out.append((y0 + size) * width + x)
	return out

## Manhattan distance from a tile to the nearest tile of a footprint.
func distance_to_footprint(cell: Vector2i, anchor: int, size: int = -1) -> int:
	if size < 0: size = footprint_size(occupancy[anchor])
	var x0: int = anchor % width
	var y0: int = anchor / width
	var dx: int = maxi(0, maxi(x0 - cell.x, cell.x - (x0 + size - 1)))
	var dy: int = maxi(0, maxi(y0 - cell.y, cell.y - (y0 + size - 1)))
	return dx + dy

## Manhattan gap between two footprints (0 when they overlap, 1 when they touch).
func footprint_gap(a: int, size_a: int, b: int, size_b: int) -> int:
	var ax: int = a % width
	var ay: int = a / width
	var bx: int = b % width
	var by: int = b / width
	var dx: int = maxi(0, maxi(ax - (bx + size_b - 1), bx - (ax + size_a - 1)))
	var dy: int = maxi(0, maxi(ay - (by + size_b - 1), by - (ay + size_a - 1)))
	return dx + dy

func advance_day() -> void:
	tick += 1
	if tick % Balance.GROWTH_DAYS == 0:
		growth.advance_round(self)
	if tick % Balance.MONTH_DAYS == 0:
		Economy.settle(self)
	if tick % Balance.GROWTH_DAYS == 0:
		budget = Economy.inputs(self)

func inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

func index(cell: Vector2i) -> int:
	return cell.y * width + cell.x

func cell_of(i: int) -> Vector2i:
	return Vector2i(i % width, i / width)

## For zone and power tools, cells are footprint anchors (top-left tiles). For
## clear, any tile of a lot or station selects the whole footprint (D30).
func preview(kind: String, cells: Array[Vector2i]) -> Dictionary:
	if not TOOLS.has(kind):
		return _failure("Unknown construction tool.")
	if cells.size() > width * height:
		return _failure("That stroke is too large.")
	var unique: Dictionary = {}
	for cell in cells:
		if not inside(cell):
			return _failure("Keep the entire stroke inside the map.")
		unique[index(cell)] = true
	if kind in ["power", "park", "police", "fire"] and unique.size() > 1:
		return _failure("Place one facility at a time.")
	var indices: Array = unique.keys()
	indices.sort()
	var target: int = TOOLS[kind]
	var changed: Array[int] = []
	var anchors: Array[int] = []
	if is_footprint_kind(target):
		var size: int = footprint_size(target)
		var claimed: Dictionary = {}
		var noun: String = "power plant" if target == POWER else "police station" if target == POLICE else "fire station" if target == FIRE else "lot"
		for raw_index in indices:
			var a: int = int(raw_index)
			var origin: Vector2i = cell_of(a)
			if not inside(origin + Vector2i(size - 1, size - 1)):
				return _failure("Keep the whole %s inside the map." % noun)
			if footprint_anchor[a] != 0 and occupancy[a] == target:
				continue # identical repaint: free and unchanged
			for i in footprint_cells(a, size):
				if terrain[i] == WATER:
					return _failure("Water cannot be built on or cleared.")
				if occupancy[i] != EMPTY:
					return _failure(_occupied_message(i))
				if access.root.x >= 0 and i == index(access.root):
					return _failure("Keep the outside-link flag free for its road.")
				if claimed.has(i):
					return _failure("Lots in one stroke cannot overlap.")
				claimed[i] = true
				changed.append(i)
			anchors.append(a)
	else:
		var expanded: Dictionary = {}
		for raw_index in indices:
			var i: int = int(raw_index)
			if terrain[i] == WATER:
				return _failure("Water cannot be built on or cleared.")
			if kind == "clear" and footprint_owner[i] != NO_LOT:
				for tile in footprint_cells(footprint_owner[i]): expanded[tile] = true
			else:
				expanded[i] = true
		var tiles: Array = expanded.keys()
		tiles.sort()
		for raw_index in tiles:
			var i: int = int(raw_index)
			if occupancy[i] == target:
				continue
			if kind != "clear" and occupancy[i] != EMPTY:
				return _failure(_occupied_message(i))
			if kind == "park" and access.root.x >= 0 and i == index(access.root):
				return _failure("Keep the outside-link flag free for its road.")
			changed.append(i)
	changed.sort()
	var units: int = anchors.size() if is_footprint_kind(target) else changed.size()
	var charge: int = units * Balance.cost(kind)
	if charge > cash:
		return _failure("Not enough funds for the whole stroke.", charge)
	if sequence >= MAX_TICK and not changed.is_empty():
		return _failure("This prototype has reached its command limit.")
	return {"ok": true, "message": "", "cost": charge, "changed": changed, "anchors": anchors, "target": target}

func apply_command(kind: String, cells: Array[Vector2i]) -> Dictionary:
	var result: Dictionary = preview(kind, cells)
	if not result.ok:
		return result
	var changed: Array = result.changed
	if changed.is_empty():
		result.message = "Nothing changed. No charge."
		return result
	# All validation has finished. Only this boundary mutates construction state.
	for i in changed:
		if int(i) == int(project.park_index): project.park_index = -1
		occupancy[int(i)] = int(result.target)
		development[int(i)] = 0
		service_loss[int(i)] = 0
		footprint_anchor[int(i)] = 0
	for a in result.anchors:
		footprint_anchor[int(a)] = 1
	cash -= int(result.cost)
	sequence += 1
	rebuild_derived()
	# Restoration breaks consecutive loss immediately, even while time is paused.
	for i in lot_anchors:
		if service_loss[i] != 0 and growth.serviced(self, i): service_loss[i] = 0
	var recorded: Array = result.anchors.duplicate() if is_footprint_kind(int(result.target)) else changed.duplicate()
	result["record"] = {"tick": tick, "sequence": sequence, "kind": kind,
		"indices": recorded, "cost": result.cost}
	var built: int = result.anchors.size()
	if kind == "police" or kind == "fire":
		result.message = "%s built · %s · with road access and power it covers lots within %d steps." % ["Police station" if kind == "police" else "Fire station", Balance.money(int(result.cost)), Balance.SERVICE_RADIUS]
	elif kind == "power":
		result.message = "Power plant built · %s · supplies up to %d lots on its network." % [Balance.money(int(result.cost)), Balance.POWER_CAPACITY / Balance.HOME_POWER_DEMAND]
	elif is_footprint_kind(int(result.target)):
		result.message = "%d lot%s · %s" % [built, "" if built == 1 else "s", Balance.money(int(result.cost))]
	else:
		result.message = "%d tile%s · %s" % [changed.size(), "" if changed.size() == 1 else "s", Balance.money(int(result.cost))]
	return result

## D32: ordered, validated and free; the current rate is a no-op without a sequence step.
func set_tax_rate(rate: Variant) -> Dictionary:
	if typeof(rate) != TYPE_INT or rate < Balance.TAX_MIN or rate > Balance.TAX_MAX:
		return _failure("Choose a whole tax rate from %d%% to %d%%." % [Balance.TAX_MIN, Balance.TAX_MAX])
	if rate == tax_rate:
		return {"ok": true, "cost": 0, "changed": [], "anchors": [], "message": "Tax rate unchanged at %d%%." % tax_rate}
	if sequence >= MAX_TICK: return _failure("This prototype has reached its command limit.")
	tax_rate = rate
	sequence += 1
	growth.refresh(self)
	budget = Economy.inputs(self)
	return {"ok": true, "cost": 0, "changed": [], "anchors": [], "message": "",
		"record": {"tick": tick, "sequence": sequence, "kind": "tax_rate", "indices": [], "cost": 0, "rate": rate}}

func snapshot() -> Dictionary:
	return {"schema_version": SCHEMA, "simulation_version": SIMULATION,
		"content_version": CONTENT, "width": width, "height": height,
		"seed": str(seed_value), "random_state": str(rng.state),
		"terrain": Array(terrain), "occupancy": Array(occupancy),
		"footprint_anchor": Array(footprint_anchor),
		"development": Array(development), "service_loss": Array(service_loss),
		"last_budget": last_budget.duplicate(), "history": history.duplicate(true), "project": project.duplicate(),
		"cash": cash, "tax_rate": tax_rate, "tick": tick, "pending_us": pending_us, "sequence": sequence}

func canonical() -> String:
	return JSON.stringify(snapshot(), "", true)

func _occupied_message(i: int) -> String:
	if is_civic(occupancy[i]): return "Clear the existing %s station first." % ("police" if occupancy[i] == POLICE else "fire")
	return "Clear the existing road, zone, or power plant first."

func _failure(message: String, cost: int = 0) -> Dictionary:
	return {"ok": false, "message": message, "cost": cost, "changed": [], "anchors": []}

## D28/D30: count distinct developed, serviced home lots with a tile within the
## park radius of this park; coverage never pools between parks.
func project_homes(park_index: int) -> int:
	if park_index < 0 or park_index >= occupancy.size() or occupancy[park_index] != PARK: return 0
	var center: Vector2i = cell_of(park_index)
	var count: int = 0
	for a in lot_anchors:
		if occupancy[a] == HOME and development[a] > 0 and growth.serviced(self, a) and distance_to_footprint(center, a) <= Balance.PARK_RADIUS:
			count += 1
	return count

func complete_project(cell: Vector2i) -> Dictionary:
	if project.completed: return _failure("This town has already completed its project.")
	if not inside(cell) or occupancy[index(cell)] != PARK: return _failure("Choose an existing pocket park.")
	if project_homes(index(cell)) < 3: return _failure("This park needs three developed residential lots with road access and power within 3 side-steps.")
	if sequence >= MAX_TICK: return _failure("This prototype has reached its command limit.")
	project = {"completed": true, "park_index": index(cell)}
	sequence += 1
	return {"ok": true, "cost": 0, "changed": [index(cell)],
		"message": "A welcoming square completed. Flowers celebrate it; the park benefit is unchanged.",
		"record": {"tick": tick, "sequence": sequence, "kind": "complete_project", "indices": [index(cell)], "cost": 0}}
