extends RefCounted
## Bounded aggregate growth (D22) with tax appeal and leaving (D32). Plans use only
## the prior completed state.
const Balance = preload("res://content/balance.gd")
var population: int = 0
var jobs: int = 0
var levels: PackedInt32Array = PackedInt32Array()
var demand: PackedInt32Array = PackedInt32Array()
var planned: PackedByteArray = PackedByteArray()
## D32: levels above target that leave while the rate is above standard, per type.
var surplus: PackedInt32Array = PackedInt32Array()
## D32: 1 on lots that lose one level to high taxes next round.
var leaving: PackedByteArray = PackedByteArray()

func serviced(city: RefCounted, i: int) -> bool:
	return city.access.served_homes[i] != 0 and city.power.home_state[i] == city.power.POWERED

func refresh(city: RefCounted) -> void:
	levels.resize(6)
	levels.fill(0)
	demand.resize(6)
	demand.fill(0)
	surplus.resize(6)
	surplus.fill(0)
	var count: int = city.width * city.height
	planned.resize(count)
	planned.fill(0)
	leaving.resize(count)
	leaving.fill(0)
	for i in city.lot_anchors: levels[city.occupancy[i]] += city.development[i]
	population = levels[city.HOME] * Balance.RESIDENTS_PER_LEVEL
	jobs = levels[city.SHOP] * Balance.SHOP_JOBS_PER_LEVEL + levels[city.WORKSHOP] * Balance.WORKSHOP_JOBS_PER_LEVEL
	var rate: int = city.tax_rate
	var targets: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0])
	targets[city.HOME] = mini(2 * count, Balance.appealed(Balance.STARTER_HOME_LEVELS + jobs / 2, rate))
	var business_target: int = Balance.appealed((population + 15) / 16, rate)
	targets[city.SHOP] = business_target
	targets[city.WORKSHOP] = business_target
	for kind in [city.HOME, city.SHOP, city.WORKSHOP]:
		demand[kind] = maxi(0, targets[kind] - levels[kind])
		if rate > Balance.TAX_STANDARD: surplus[kind] = maxi(0, levels[kind] - targets[kind])
		if surplus[kind] > 0: _plan_leaving(city, kind, mini(surplus[kind], Balance.LEAVE_LIMIT))
	var remaining: PackedInt32Array = demand.duplicate()
	for kind in [city.HOME, city.SHOP, city.WORKSHOP]:
		remaining[kind] = mini(remaining[kind], Balance.GROWTH_LIMIT)
	# Covered homes first, then all other zones; row-major within each group.
	# Reservation still uses only the prior state, with shared per-type budgets.
	for priority in [true, false]:
		for i in city.lot_anchors:
			var kind: int = city.occupancy[i]
			if city.development[i] >= Balance.MAX_LEVEL: continue
			var preferred: bool = kind == city.HOME and city.amenity.lot_covered[i] != 0
			if preferred != priority: continue
			if remaining[kind] > 0 and serviced(city, i):
				planned[i] = 1
				remaining[kind] -= 1

## Level-2 lots first, then later row-major index first; developed, serviced lots only.
func _plan_leaving(city: RefCounted, kind: int, amount: int) -> void:
	for level in [Balance.MAX_LEVEL, 1]:
		for n in range(city.lot_anchors.size() - 1, -1, -1):
			if amount <= 0: return
			var i: int = city.lot_anchors[n]
			if city.occupancy[i] == kind and city.development[i] == level and serviced(city, i):
				leaving[i] = 1
				amount -= 1

func advance_round(city: RefCounted) -> void:
	var next_levels: PackedByteArray = city.development.duplicate()
	var next_loss: PackedByteArray = city.service_loss.duplicate()
	for i in city.lot_anchors:
		if serviced(city, i):
			next_loss[i] = 0
			next_levels[i] += planned[i]
			next_levels[i] -= leaving[i]
		elif city.development[i] > 0:
			next_loss[i] += 1
			if next_loss[i] >= Balance.DECLINE_ROUNDS:
				next_levels[i] -= 1
				next_loss[i] = 0
	city.development = next_levels
	city.service_loss = next_loss
	refresh(city)

## i may be any tile of a lot; the lot's anchor holds its state (D30).
func reason(city: RefCounted, i: int) -> String:
	if not city.is_zone(city.occupancy[i]): return "not_zone"
	i = city.footprint_owner[i]
	if i < 0: return "not_zone"
	if not serviced(city, i): return "declining" if city.development[i] > 0 else "services"
	if leaving[i] != 0: return "leaving"
	if surplus[city.occupancy[i]] > 0: return "surplus" if city.development[i] > 0 else "demand"
	if city.development[i] >= Balance.MAX_LEVEL: return "full"
	if demand[city.occupancy[i]] == 0: return "demand"
	return "growing" if planned[i] != 0 else "queued"
