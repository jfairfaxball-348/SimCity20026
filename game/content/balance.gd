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
## D37: zone levels 0-4. Per-lot capacity by level (levels 1-2 keep D22's 4/2/4 per level).
const MAX_LEVEL: int = 4
## Highest level stored by schemas 3-9 (D22).
const LEGACY_MAX_LEVEL: int = 2
const RESIDENTS_BY_LEVEL: Array[int] = [0, 4, 8, 20, 40]
const SHOP_JOBS_BY_LEVEL: Array[int] = [0, 2, 4, 10, 20]
const WORKSHOP_JOBS_BY_LEVEL: Array[int] = [0, 4, 8, 16, 28]
## Kept for readers of the per-level D22 numbers (levels 1-2).
const RESIDENTS_PER_LEVEL: int = 4
const SHOP_JOBS_PER_LEVEL: int = 2
const WORKSHOP_JOBS_PER_LEVEL: int = 4
## D37 gates: land value needed for levels 3 and 4. Residential needs 1 / 2; commercial,
## whose trade adds up to +2, needs COMMERCIAL_EXTRA more (3 / 4: trade plus a park).
## Below the level-3 value a lot is capped at GATED_LEVEL.
const GATED_LEVEL: int = 2
const LEVEL3_VALUE: int = 1
const LEVEL4_VALUE: int = 2
const COMMERCIAL_EXTRA: int = 2
## D37: industry ignores land value but needs a workforce: town residents (prior state)
## for industrial levels 3 and 4.
const WORKFORCE_LEVEL3: int = 100
const WORKFORCE_LEVEL4: int = 250
const STARTER_HOME_LEVELS: int = 3
const GROWTH_DAYS: int = 5
const GROWTH_LIMIT: int = 8
const DECLINE_ROUNDS: int = 2
const MAX_CASH: int = 1_000_000_000_000
const MONTH_DAYS: int = 30
const MONTH_GRANT: int = 10_000
## D32: resident/job tax at the standard rate; each percentage point is a tenth of it.
const RESIDENT_TAX: int = 200
const JOB_TAX: int = 400
const TAX_MIN: int = 0
const TAX_MAX: int = 25
const TAX_STANDARD: int = 10
const RESIDENT_TAX_PER_POINT: int = RESIDENT_TAX / TAX_STANDARD
const JOB_TAX_PER_POINT: int = JOB_TAX / TAX_STANDARD
## D32 appeal: percent change in demand targets per point below the standard rate.
const APPEAL_PER_POINT: int = 4
## D32: most levels of one type that leave per growth round above the standard rate.
const LEAVE_LIMIT: int = 4
const ROAD_UPKEEP: int = 100
const STATION_UPKEEP: int = 6_000
const PARK_UPKEEP: int = 1_000
const PARK_COST: int = 10_000
const PARK_RADIUS: int = 3
## D33 home desirability: park and water bonuses within their radii; each developed
## workshop lot within the nuisance radius deters (counted up to a limit). Homes below
## zero are held at HELD_LEVEL.
const DESIRABILITY_PARK: int = 2
const DESIRABILITY_WATER: int = 1
const WATER_RADIUS: int = 3
const NUISANCE_PER_WORKSHOP: int = 2
const NUISANCE_RADIUS: int = 2
const NUISANCE_COUNT_LIMIT: int = 3
const HELD_LEVEL: int = 1
## D36: a commercial lot gains per developed residential lot within the customer
## radius, counted up to a limit.
const CUSTOMER_BONUS: int = 1
const CUSTOMER_RADIUS: int = 3
const CUSTOMER_COUNT_LIMIT: int = 2
## D30 footprints: zones are square lots; power stations are larger squares.
const LOT_SIZE: int = 3
const STATION_SIZE: int = 4
## D38: police and fire stations. Each is a 3x3 civic building that works with road
## access and one power unit, and covers zone lots within SERVICE_RADIUS side-steps
## (footprint to footprint). Level 4 needs police and fire cover; without both a lot
## is capped at SERVICE_GATED_LEVEL.
const CIVIC_SIZE: int = 3
const POLICE_COST: int = 40_000
const FIRE_COST: int = 40_000
const POLICE_UPKEEP: int = 3_000
const FIRE_UPKEEP: int = 3_000
const SERVICE_RADIUS: int = 12
const SERVICE_GATED_LEVEL: int = 3

## D37: residents (residential) or jobs (commercial/industrial) a lot holds at a level.
static func capacity(kind: int, level: int) -> int:
	level = clampi(level, 0, MAX_LEVEL)
	match kind:
		2: return RESIDENTS_BY_LEVEL[level]
		4: return SHOP_JOBS_BY_LEVEL[level]
		5: return WORKSHOP_JOBS_BY_LEVEL[level]
	return 0

## D37: land value a residential (2) or commercial (4) lot needs to reach a level
## (0 for levels up to GATED_LEVEL).
static func value_needed(kind: int, level: int) -> int:
	var extra: int = COMMERCIAL_EXTRA if kind == 4 else 0
	if level >= 4: return LEVEL4_VALUE + extra
	if level == 3: return LEVEL3_VALUE + extra
	return 0

static func cost(kind: String) -> int:
	match kind:
		"road": return ROAD_COST
		"home": return HOME_COST
		"shop", "workshop": return ZONE_COST
		"power": return POWER_COST
		"park": return PARK_COST
		"police": return POLICE_COST
		"fire": return FIRE_COST
	return 0

## D32: demand-target multiplier in percent (140 at 0%, 100 at 10%, 40 at 25%).
static func appeal(rate: int) -> int:
	return 100 + APPEAL_PER_POINT * (TAX_STANDARD - rate)

## Rounds half up: value x appeal percent, in integers.
static func appealed(value: int, rate: int) -> int:
	return (value * appeal(rate) + 50) / 100

static func money(cents: int) -> String:
	return ("−" if cents < 0 else "") + "$%d.%02d" % [absi(cents) / 100, absi(cents) % 100]
