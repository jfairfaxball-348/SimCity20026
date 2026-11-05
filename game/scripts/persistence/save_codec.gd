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
	if schema not in [1, 2, 3, City.SCHEMA]:
		return fail("This save uses an unsupported format (%d). The file was not changed." % schema)
	# Each historical format has its own version pair and allowed occupancy IDs.
	var version: String = {1: "m1-1", 2: "m2b-1", 3: "m2c-1", 4: City.SIMULATION}[schema]
	var content: String = version
	if data.get("simulation_version") != version or data.get("content_version") != content:
		return fail("This save belongs to a different simulation/content version.")
	var max_use: int = {1: City.HOME, 2: City.POWER, 3: City.WORKSHOP, 4: City.PARK}[schema]
	if not integer(data.get("width"), 8, 128) or not integer(data.get("height"), 8, 128):
		return fail("Invalid map dimensions.")
	if not signed_integer_string(data.get("seed")) or not signed_integer_string(data.get("random_state")):
		return fail("Invalid seed or random state.")
	for field in ["cash", "tick", "sequence", "pending_us"]:
		var maximum: int = Balance.MAX_CASH if field == "cash" else City.MAX_PENDING_US if field == "pending_us" else City.MAX_TICK
		if not integer(data.get(field), 0, maximum):
			return fail("Invalid %s in save." % field)
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
	if schema == City.SCHEMA:
		if not valid_budget(data.get("last_budget"), int(data.tick), count):
			return fail("Invalid monthly budget record.")
	elif data.has("last_budget"):
		return fail("Earlier-format save contains unsupported budget data.")
	var city: City = City.new()
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
	if schema >= 3:
		city.development = PackedByteArray(data.development)
		city.service_loss = PackedByteArray(data.service_loss)
	city.last_budget = data.last_budget.duplicate() if schema == City.SCHEMA else {}
	# Normalize parsed JSON numbers for exact snapshots.
	for key in city.last_budget: city.last_budget[key] = int(city.last_budget[key])
	city.cash = int(data.cash)
	city.tick = int(data.tick)
	city.pending_us = int(data.pending_us)
	city.sequence = int(data.sequence)
	# Migration retains all earlier values and adds zero-filled growth arrays.
	city.rebuild_derived()
	for i in range(count):
		if city.service_loss[i] != 0 and city.growth.serviced(city, i):
			return fail("A serviced plot cannot retain a service-loss counter.")
	return {"ok": true, "city": city, "message": "City restored.", "schema": schema,
		"migrated_from": schema if schema != City.SCHEMA else 0}

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

static func valid_budget(value: Variant, tick: int, count: int) -> bool:
	if typeof(value) != TYPE_DICTIONARY: return false
	if value.is_empty(): return true
	var bounds: Dictionary = {"tick": tick, "opening_cash": Balance.MAX_CASH,
		"residents": count * 8, "jobs": count * 8, "roads": count, "stations": count, "parks": count}
	if value.size() != bounds.size(): return false
	for key in bounds:
		if not integer(value.get(key), 0, bounds[key]): return false
	if int(value.tick) == 0 or int(value.tick) % Balance.MONTH_DAYS != 0: return false
	if int(value.residents) % 4 != 0 or int(value.jobs) % 2 != 0: return false
	# Historical counts must fit the saved map even though today's layout may differ.
	var minimum_zones: int = (int(value.residents) + 7) / 8 + (int(value.jobs) + 7) / 8
	return int(value.roads) + int(value.stations) + int(value.parks) + minimum_zones <= count
