extends RefCounted
## Bounded aggregate growth (D22) with tax appeal and leaving (D32) and home
## desirability (D33). Plans use only the prior completed state.
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
## D33: 1 on serviced level-2 homes held back by nuisance; they drop one level next round.
var dropping: PackedByteArray = PackedByteArray()

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
	dropping.resize(count)
	dropping.fill(0)
	city.desirability.rebuild(city)
	for i in city.lot_anchors: levels[city.occupancy[i]] += city.development[i]
	population = levels[city.HOME] * Balance.RESIDENTS_PER_LEVEL
	jobs = levels[city.SHOP] * Balance.SHOP_JOBS_PER_LEVEL + levels[city.WORKSHOP] * Balance.WORKSHOP_JOBS_PER_LEVEL
	var drops: int = 0
	for i in city.lot_anchors:
		if city.development[i] > city.desirability.cap(city, i) and serviced(city, i):
			dropping[i] = 1
			drops += 1
	var rate: int = city.tax_rate
	var targets: PackedInt32Array = PackedInt32Array([0, 0, 0, 0, 0, 0])
	targets[city.HOME] = mini(2 * count, Balance.appealed(Balance.STARTER_HOME_LEVELS + jobs / 2, rate))
	var business_target: int = Balance.appealed((population + 15) / 16, rate)
	targets[city.SHOP] = business_target
	targets[city.WORKSHOP] = business_target
	for kind in [city.HOME, city.SHOP, city.WORKSHOP]:
		demand[kind] = maxi(0, targets[kind] - levels[kind])
		if rate > Balance.TAX_STANDARD: surplus[kind] = maxi(0, levels[kind] - targets[kind])
		# Nuisance drops count towards a type's leaving for the round (D33).
		var already: int = drops if kind == city.HOME else 0
		if surplus[kind] > 0: _plan_leaving(city, kind, maxi(0, mini(surplus[kind], Balance.LEAVE_LIMIT) - already))
	var remaining: PackedInt32Array = demand.duplicate()
	for kind in [city.HOME, city.SHOP, city.WORKSHOP]:
		remaining[kind] = mini(remaining[kind], Balance.GROWTH_LIMIT)
	# D33: homes by desirability (higher first), then map order; businesses in map
	# order. Budgets are per type, so the two groups never compete. Reservation still
	# uses only the prior state.
	var homes: Array = []
	var others: Array = []
	for i in city.lot_anchors:
		if city.occupancy[i] == city.HOME: homes.append(i)
		else: others.append(i)
	var scores: PackedInt32Array = city.desirability.lot_score
	homes.sort_custom(func(a, b): return scores[a] > scores[b] or (scores[a] == scores[b] and a < b))
	for i in homes + others:
		var kind: int = city.occupancy[i]
		if city.development[i] >= city.desirability.cap(city, i): continue
		if remaining[kind] > 0 and serviced(city, i):
			planned[i] = 1
			remaining[kind] -= 1

## Level-2 lots first, then later row-major index first; developed, serviced lots only.
func _plan_leaving(city: RefCounted, kind: int, amount: int) -> void:
	for level in [Balance.MAX_LEVEL, 1]:
		for n in range(city.lot_anchors.size() - 1, -1, -1):
			if amount <= 0: return
			var i: int = city.lot_anchors[n]
			if city.occupancy[i] == kind and city.development[i] == level and serviced(city, i) and dropping[i] == 0:
				leaving[i] = 1
				amount -= 1

func advance_round(city: RefCounted) -> void:
	var next_levels: PackedByteArray = city.development.duplicate()
	var next_loss: PackedByteArray = city.service_loss.duplicate()
	for i in city.lot_anchors:
		if serviced(city, i):
			next_loss[i] = 0
			next_levels[i] += planned[i]
			next_levels[i] -= leaving[i] + dropping[i]
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
	if dropping[i] != 0: return "dropping"
	if surplus[city.occupancy[i]] > 0: return "surplus" if city.development[i] > 0 else "demand"
	if city.development[i] >= Balance.MAX_LEVEL: return "full"
	if city.development[i] >= city.desirability.cap(city, i): return "held"
	if demand[city.occupancy[i]] == 0: return "demand"
	return "growing" if planned[i] != 0 else "queued"
