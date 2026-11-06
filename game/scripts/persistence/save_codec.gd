extends RefCounted
const City = preload("res://scripts/sim/city_state.gd")
const Balance = preload("res://content/balance.gd")
const MAX_BYTES: int = 512 * 1024

static func decode(text: String) -> Dictionary:
	if text.to_utf8_buffer().size() > MAX_BYTES:
		return fail("Save file is too large.")
	var parser: JSON = JSON.new()
	if parser.parse(text) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return fail("Save file is incomplete or is not valid city data.")
	var data: Dictionary = parser.data
	if not integer(data.get("schema_version"), 1, 1000000):
		return fail("Save schema is missing or invalid.")
	var schema: int = int(data.schema_version)
	if schema > City.SCHEMA:
		return fail("This save was made by a newer version of the game (format %d). The file was not changed." % schema)
	if schema not in [1, 2, 3, 4, 5, 6, City.SCHEMA]:
		return fail("This save uses an unsupported format (%d). The file was not changed." % schema)
	# Each historical format has its own version pair and allowed occupancy IDs.
	var version: String = {1: "m1-1", 2: "m2b-1", 3: "m2c-1", 4: "m2d-1", 5: "m3a-1", 6: "m2e-1", 7: City.SIMULATION}[schema]
	var content: String = version
	if data.get("simulation_version") != version or data.get("content_version") != content:
		return fail("This save belongs to a different simulation/content version.")
	var max_use: int = {1: City.HOME, 2: City.POWER, 3: City.WORKSHOP, 4: City.PARK, 5: City.PARK, 6: City.PARK, 7: City.PARK}[schema]
	if not integer(data.get("width"), 8, 128) or not integer(data.get("height"), 8, 128):
		return fail("Invalid map dimensions.")
	if not signed_integer_string(data.get("seed")) or not signed_integer_string(data.get("random_state")):
		return fail("Invalid seed or random state.")
	for field in ["cash", "tick", "sequence", "pending_us"]:
		var maximum: int = Balance.MAX_CASH if field == "cash" else City.MAX_PENDING_US if field == "pending_us" else City.MAX_TICK
		if not integer(data.get(field), 0, maximum):
			return fail("Invalid %s in save." % field)
	# D32: schema 7 stores the town tax rate; earlier formats never did.
	if schema >= 7:
		if not integer(data.get("tax_rate"), Balance.TAX_MIN, Balance.TAX_MAX):
			return fail("Invalid tax rate in save.")
	elif data.has("tax_rate"):
		return fail("Earlier-format save contains unsupported tax data.")
	var count: int = int(data.width) * int(data.height)
	if typeof(data.get("terrain")) != TYPE_ARRAY or typeof(data.get("occupancy")) != TYPE_ARRAY:
		return fail("Missing map arrays.")
	if data.terrain.size() != count or data.occupancy.size() != count:
		return fail("Map array length does not match dimensions.")
	if schema >= 3:
		for field in ["development", "service_loss"]:
			if typeof(data.get(field)) != TYPE_ARRAY or data[field].size() != count:
				return fail("Missing or invalid %s array." % field)
	else:
		# Older formats never stored development. Do not reinterpret hidden new state.
		if data.has("development") or data.has("service_loss"):
			return fail("Earlier-format save contains unsupported growth data.")
	if schema >= 6:
		if typeof(data.get("footprint_anchor")) != TYPE_ARRAY or data.footprint_anchor.size() != count:
			return fail("Missing or invalid footprint array.")
	elif data.has("footprint_anchor"):
		return fail("Earlier-format save contains unsupported footprint data.")
	for i in range(count):
		if not integer(data.terrain[i], City.LAND, City.WATER) or not integer(data.occupancy[i], City.EMPTY, max_use):
			return fail("Unknown terrain or land-use identifier.")
		if int(data.terrain[i]) == City.WATER and int(data.occupancy[i]) != City.EMPTY:
			return fail("Save contains construction on water.")
		if schema >= 3:
			if not integer(data.development[i], 0, Balance.MAX_LEVEL) or not integer(data.service_loss[i], 0, Balance.DECLINE_ROUNDS - 1):
				return fail("Invalid development or service-loss value.")
			if (not City.is_zone(int(data.occupancy[i])) and int(data.development[i]) != 0) or (int(data.development[i]) == 0 and int(data.service_loss[i]) != 0):
				return fail("Development does not match its zone.")
	if schema >= 6 and not valid_footprints(data):
		return fail("Lots or stations in this save do not form whole, separate footprints.")
	if schema >= 4:
		if not valid_budget(data.get("last_budget"), int(data.tick), count, schema):
			return fail("Invalid monthly budget record.")
	elif data.has("last_budget"):
		return fail("Earlier-format save contains unsupported budget data.")
	if schema >= 5:
		if not valid_project(data.get("project"), data.occupancy): return fail("Invalid neighbourhood project record.")
	elif data.has("project"):
		return fail("Earlier-format save contains unsupported project data.")
	var city: City = City.new()
	if schema >= 5:
		city.project = {"completed": data.project.completed, "park_index": int(data.project.park_index)}
	city.width = int(data.width)
	city.height = int(data.height)
	city.seed_value = String(data.seed).to_int()
	city.rng.seed = city.seed_value
	city.rng.state = String(data.random_state).to_int()
	city.terrain = PackedByteArray(data.terrain)
	city.occupancy = PackedByteArray(data.occupancy)
	city.development.resize(count)
	city.development.fill(0)
	city.service_loss.resize(count)
	city.service_loss.fill(0)
	city.footprint_anchor.resize(count)
	city.footprint_anchor.fill(0)
	if schema >= 3:
		city.development = PackedByteArray(data.development)
		city.service_loss = PackedByteArray(data.service_loss)
	if schema >= 6:
		city.footprint_anchor = PackedByteArray(data.footprint_anchor)
	# D30 migration: single-tile zones and stations cannot become 3x3 lots or 4x4
	# stations, so they are cleared; every other authoritative value is kept.
	var cleared: int = 0
	if schema < 6:
		for i in range(count):
			if City.is_zone(city.occupancy[i]) or city.occupancy[i] == City.POWER:
				city.occupancy[i] = City.EMPTY
				cleared += 1
		city.development.fill(0)
		city.service_loss.fill(0)
	city.last_budget = data.last_budget.duplicate() if schema >= 4 else {}
	# Normalize parsed JSON numbers for exact snapshots.
	for key in city.last_budget: city.last_budget[key] = int(city.last_budget[key])
	# D32: earlier settlements were all collected at the standard rate.
	if schema < 7 and not city.last_budget.is_empty(): city.last_budget["tax_rate"] = Balance.TAX_STANDARD
	city.tax_rate = int(data.tax_rate) if schema >= 7 else Balance.TAX_STANDARD
	city.cash = int(data.cash)
	city.tick = int(data.tick)
	city.pending_us = int(data.pending_us)
	city.sequence = int(data.sequence)
	city.rebuild_derived()
	for i in city.lot_anchors:
		if city.service_loss[i] != 0 and city.growth.serviced(city, i):
			return fail("A serviced lot cannot retain a service-loss counter.")
	return {"ok": true, "city": city, "message": "City restored.", "schema": schema,
		"migrated_from": schema if schema != City.SCHEMA else 0, "cleared_tiles": cleared}

static func integer(value: Variant, minimum: int, maximum: int) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var number: float = float(value)
	return is_finite(number) and number >= minimum and number <= maximum and floor(number) == number

static func signed_integer_string(value: Variant) -> bool:
	if typeof(value) != TYPE_STRING or value.length() > 20 or value.is_empty():
		return false
	return value.is_valid_int() and str(value.to_int()) == value

static func fail(message: String) -> Dictionary:
	return {"ok": false, "message": message}

static func valid_budget(value: Variant, tick: int, count: int, schema: int = City.SCHEMA) -> bool:
	if typeof(value) != TYPE_DICTIONARY: return false
	if value.is_empty(): return true
	var bounds: Dictionary = {"tick": tick, "opening_cash": Balance.MAX_CASH,
		"residents": count * 8, "jobs": count * 8, "roads": count, "stations": count, "parks": count}
	if schema >= 7: bounds["tax_rate"] = Balance.TAX_MAX
	if value.size() != bounds.size(): return false
	for key in bounds:
		if not integer(value.get(key), 0, bounds[key]): return false
	if int(value.tick) == 0 or int(value.tick) % Balance.MONTH_DAYS != 0: return false
	if int(value.residents) % 4 != 0 or int(value.jobs) % 2 != 0: return false
	# Historical counts must fit the saved map even though today's layout may differ.
	var minimum_zones: int = (int(value.residents) + 7) / 8 + (int(value.jobs) + 7) / 8
	return int(value.roads) + int(value.stations) + int(value.parks) + minimum_zones <= count

## D30: every zone or station tile belongs to exactly one whole, in-map footprint
## of one kind, anchored at its top-left tile; growth state lives only on lot anchors.
static func valid_footprints(data: Dictionary) -> bool:
	var w: int = int(data.width)
	var h: int = int(data.height)
	var count: int = w * h
	var owner: PackedInt32Array = PackedInt32Array()
	owner.resize(count)
	owner.fill(-1)
	for i in range(count):
		if not integer(data.footprint_anchor[i], 0, 1): return false
		if int(data.footprint_anchor[i]) == 0: continue
		var kind: int = int(data.occupancy[i])
		if not City.is_footprint_kind(kind): return false
		var size: int = City.footprint_size(kind)
		var x0: int = i % w
		var y0: int = i / w
		if x0 + size > w or y0 + size > h: return false
		for y in range(y0, y0 + size):
			for x in range(x0, x0 + size):
				var t: int = y * w + x
				if owner[t] != -1 or int(data.occupancy[t]) != kind: return false
				owner[t] = i
	for i in range(count):
		var kind: int = int(data.occupancy[i])
		if City.is_footprint_kind(kind) and owner[i] == -1: return false
		var is_anchor: bool = int(data.footprint_anchor[i]) == 1
		if (int(data.development[i]) != 0 or int(data.service_loss[i]) != 0) and not (is_anchor and City.is_zone(kind)): return false
	return true

static func valid_project(value: Variant, occupancy: Array) -> bool:
	if typeof(value) != TYPE_DICTIONARY or value.size() != 2: return false
	if typeof(value.get("completed")) != TYPE_BOOL or not integer(value.get("park_index"), -1, occupancy.size() - 1): return false
	var i: int = int(value.park_index)
	if not value.completed: return i == -1
	return i == -1 or int(occupancy[i]) == City.PARK
