extends RefCounted
## Provisional construction and power values, in cents and abstract power units.
## No economy/growth is simulated. Changing these changes the content version.
const STARTING_CASH: int = 1_000_000
const ROAD_COST: int = 1_000
const HOME_COST: int = 2_500
const POWER_COST: int = 50_000
const POWER_CAPACITY: int = 20
const HOME_POWER_DEMAND: int = 1
const MAX_CASH: int = 1_000_000_000_000

static func cost(kind: String) -> int:
	match kind:
		"road": return ROAD_COST
		"home": return HOME_COST
		"power": return POWER_COST
	return 0

static func money(cents: int) -> String:
	return "$%d.%02d" % [cents / 100, cents % 100]
