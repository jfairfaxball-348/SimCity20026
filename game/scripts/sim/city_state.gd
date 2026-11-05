extends RefCounted
## Authoritative data and synchronous ordered commands; no scene dependencies.
## Road access and power are derived from terrain/occupancy and never serialized.
const Balance = preload("res://content/balance.gd")
const Access = preload("res://scripts/sim/road_access.gd")
const Power = preload("res://scripts/sim/power_grid.gd")
const Growth = preload("res://scripts/sim/growth.gd")
const Economy = preload("res://scripts/sim/economy.gd")
const Amenity = preload("res://scripts/sim/amenity.gd")
const LAND: int = 0
const WATER: int = 1
const EMPTY: int = 0
const ROAD: int = 1
const HOME: int = 2
const POWER: int = 3
const SHOP: int = 4
const WORKSHOP: int = 5
const PARK: int = 6
const MAX_TICK: int = 1_000_000_000
const MAX_PENDING_US: int = 3_600_000_000
const SCHEMA: int = 4
const SIMULATION: String = "m2d-1"
const CONTENT: String = "m2d-1"
## Supported earlier format (M1/M2a): IDs 0..2 only, migrated in memory (D20).
const LEGACY_SCHEMA: int = 1
const LEGACY_VERSION: String = "m1-1"
const TOOLS: Dictionary = {"road": ROAD, "home": HOME, "shop": SHOP, "workshop": WORKSHOP, "power": POWER, "park": PARK, "clear": EMPTY}

var width: int = 64
var height: int = 64
var seed_value: int = 198624
var terrain: PackedByteArray = PackedByteArray()
var occupancy: PackedByteArray = PackedByteArray()
var development: PackedByteArray = PackedByteArray()
var service_loss: PackedByteArray = PackedByteArray()
var cash: int = Balance.STARTING_CASH
var tick: int = 0
var pending_us: int = 0
var sequence: int = 0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var access: Access = Access.new()
var power: Power = Power.new()
var growth: Growth = Growth.new()
var amenity: Amenity = Amenity.new()
var last_budget: Dictionary = {}
var budget: Dictionary = {}

func initialize(map_seed: int = 198624, map_width: int = 64, map_height: int = 64) -> void:
	width = clampi(map_width, 8, 128)
	height = clampi(map_height, 8, 128)
	seed_value = map_seed
	rng.seed = seed_value
	cash = Balance.STARTING_CASH
	tick = 0
	pending_us = 0
	sequence = 0
	last_budget = {}
	terrain.resize(width * height)
	terrain.fill(LAND)
	occupancy.resize(width * height)
	occupancy.fill(EMPTY)
	development.resize(width * height)
	development.fill(0)
	service_loss.resize(width * height)
	service_loss.fill(0)
	# An original seeded shoreline. The central starting ground is always connected.
	for y in range(height):
		var shoreline: int = clampi(width / 10 + y / 14 + rng.randi_range(-1, 1), 1, width - 1)
		for x in range(shoreline):
			terrain[index(Vector2i(x, y))] = WATER
	rebuild_derived()

func rebuild_derived() -> void:
	# Terrain is immutable in play. Call after initialization/validated decoding,
	# or from fixture setup after changing terrain. Commands own occupancy edits.
	# Access first: power placement rules read the outside-link root.
	access.rebuild(self)
	power.rebuild(self)
	amenity.rebuild(self)
	growth.refresh(self)
	budget = Economy.inputs(self)

static func is_zone(kind: int) -> bool:
	return kind in [HOME, SHOP, WORKSHOP]

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
	if kind in ["power", "park"] and unique.size() > 1:
		return _failure("Place one facility at a time.")
	var indices: Array = unique.keys()
	indices.sort()
	var changed: Array[int] = []
	var target: int = TOOLS[kind]
	for raw_index in indices:
		var i: int = int(raw_index)
		if terrain[i] == WATER:
			return _failure("Water cannot be built on or cleared.")
		if occupancy[i] == target:
			continue
		if kind != "clear" and occupancy[i] != EMPTY:
			return _failure("Clear the existing road, zone, or station first.")
		if kind in ["power", "park"] and access.root.x >= 0 and i == index(access.root):
			return _failure("Keep the outside-link flag free for its road.")
		changed.append(i)
	var charge: int = changed.size() * Balance.cost(kind)
	if charge > cash:
		return _failure("Not enough funds for the whole stroke.", charge)
	if sequence >= MAX_TICK and not changed.is_empty():
		return _failure("This prototype has reached its command limit.")
	return {"ok": true, "message": "", "cost": charge, "changed": changed, "target": target}

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
		occupancy[int(i)] = int(result.target)
		development[int(i)] = 0
		service_loss[int(i)] = 0
	cash -= int(result.cost)
	sequence += 1
	rebuild_derived()
	# Restoration breaks consecutive loss immediately, even while time is paused.
	for i in range(width * height):
		if service_loss[i] != 0 and growth.serviced(self, i): service_loss[i] = 0
	result["record"] = {"tick": tick, "sequence": sequence, "kind": kind,
		"indices": changed.duplicate(), "cost": result.cost}
	if kind == "power":
		result.message = "Power station built · %s · supplies up to %d plots on its network." % [Balance.money(int(result.cost)), Balance.POWER_CAPACITY / Balance.HOME_POWER_DEMAND]
	else:
		result.message = "%d tile%s · %s" % [changed.size(), "" if changed.size() == 1 else "s", Balance.money(int(result.cost))]
	return result

func snapshot() -> Dictionary:
	return {"schema_version": SCHEMA, "simulation_version": SIMULATION,
		"content_version": CONTENT, "width": width, "height": height,
		"seed": str(seed_value), "random_state": str(rng.state),
		"terrain": Array(terrain), "occupancy": Array(occupancy),
		"development": Array(development), "service_loss": Array(service_loss),
		"last_budget": last_budget.duplicate(),
		"cash": cash, "tick": tick, "pending_us": pending_us, "sequence": sequence}

func canonical() -> String:
	return JSON.stringify(snapshot(), "", true)

func _failure(message: String, cost: int = 0) -> Dictionary:
	return {"ok": false, "message": message, "cost": cost, "changed": []}
