extends RefCounted
## Provisional construction and power values, in cents and abstract power units.
## Aggregate monthly economy (D25-D26). Changes require a content version.
const STARTING_CASH: int = 1_000_000
const ROAD_COST: int = 1_000
const HOME_COST: int = 2_500
const POWER_COST: int = 50_000
const POWER_CAPACITY: int = 20
const HOME_POWER_DEMAND: int = 1
const ZONE_COST: int = 2_500
const MAX_LEVEL: int = 2
const RESIDENTS_PER_LEVEL: int = 4
const SHOP_JOBS_PER_LEVEL: int = 2
const WORKSHOP_JOBS_PER_LEVEL: int = 4
const STARTER_HOME_LEVELS: int = 3
const GROWTH_DAYS: int = 5
const GROWTH_LIMIT: int = 8
const DECLINE_ROUNDS: int = 2
const MAX_CASH: int = 1_000_000_000_000
const MONTH_DAYS: int = 30
const MONTH_GRANT: int = 10_000
const RESIDENT_TAX: int = 200
const JOB_TAX: int = 400
const ROAD_UPKEEP: int = 100
const STATION_UPKEEP: int = 6_000
const PARK_UPKEEP: int = 1_000
const PARK_COST: int = 10_000
const PARK_RADIUS: int = 3

static func cost(kind: String) -> int:
	match kind:
		"road": return ROAD_COST
		"home": return HOME_COST
		"shop", "workshop": return ZONE_COST
		"power": return POWER_COST
		"park": return PARK_COST
	return 0

static func money(cents: int) -> String:
	return ("−" if cents < 0 else "") + "$%d.%02d" % [absi(cents) / 100, absi(cents) % 100]
