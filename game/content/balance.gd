extends RefCounted
## Provisional M1 construction prices, in cents. No economy/growth is simulated.
const STARTING_CASH: int = 1_000_000
const ROAD_COST: int = 1_000
const HOME_COST: int = 2_500
const MAX_CASH: int = 1_000_000_000_000

static func cost(kind: String) -> int:
	return ROAD_COST if kind == "road" else HOME_COST if kind == "home" else 0

static func money(cents: int) -> String:
	return "$%d.%02d" % [cents / 100, cents % 100]
