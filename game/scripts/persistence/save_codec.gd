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
	if schema != City.SCHEMA and schema != City.LEGACY_SCHEMA:
		return fail("This save uses an unsupported format (%d). The file was not changed." % schema)
	# Schema 1 (M1/M2a) is accepted only with its own version pair and IDs 0..2.
	var version: String = City.SIMULATION if schema == City.SCHEMA else City.LEGACY_VERSION
	var content: String = City.CONTENT if schema == City.SCHEMA else City.LEGACY_VERSION
	if data.get("simulation_version") != version or data.get("content_version") != content:
		return fail("This save belongs to a different simulation/content version.")
	var max_use: int = City.POWER if schema == City.SCHEMA else City.HOME
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
	for i in range(count):
		if not integer(data.terrain[i], City.LAND, City.WATER) or not integer(data.occupancy[i], City.EMPTY, max_use):
			return fail("Unknown terrain or land-use identifier.")
		if int(data.terrain[i]) == City.WATER and int(data.occupancy[i]) != City.EMPTY:
			return fail("Save contains construction on water.")
	var city: City = City.new()
	city.width = int(data.width)
	city.height = int(data.height)
	city.seed_value = String(data.seed).to_int()
	city.rng.seed = city.seed_value
	city.rng.state = String(data.random_state).to_int()
	city.terrain = PackedByteArray(data.terrain)
	city.occupancy = PackedByteArray(data.occupancy)
	city.cash = int(data.cash)
	city.tick = int(data.tick)
	city.pending_us = int(data.pending_us)
	city.sequence = int(data.sequence)
	# Migration from schema 1 changes only the version fields written by snapshot().
	city.rebuild_derived()
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
