extends RefCounted
## D25: integer monthly accounting. No hidden debt or service cuts.
const Balance = preload("res://content/balance.gd")

static func inputs(city: RefCounted) -> Dictionary:
	var data: Dictionary = {"tick": city.tick, "opening_cash": city.cash,
		"residents": 0, "jobs": 0, "roads": 0, "stations": 0, "parks": 0}
	for i in range(city.width * city.height):
		match city.occupancy[i]:
			city.ROAD: data.roads += 1
			city.PARK: data.parks += 1
	# D30: one station and one lot per anchor, never per tile.
	data.stations = city.station_anchors.size()
	for i in city.lot_anchors:
		if not city.growth.serviced(city, i): continue
		match city.occupancy[i]:
			city.HOME: data.residents += city.development[i] * Balance.RESIDENTS_PER_LEVEL
			city.SHOP: data.jobs += city.development[i] * Balance.SHOP_JOBS_PER_LEVEL
			city.WORKSHOP: data.jobs += city.development[i] * Balance.WORKSHOP_JOBS_PER_LEVEL
	return data

static func totals(data: Dictionary) -> Dictionary:
	var income: int = Balance.MONTH_GRANT + int(data.residents) * Balance.RESIDENT_TAX + int(data.jobs) * Balance.JOB_TAX
	var expenses: int = int(data.roads) * Balance.ROAD_UPKEEP + int(data.stations) * Balance.STATION_UPKEEP + int(data.parks) * Balance.PARK_UPKEEP
	var raw_cash: int = int(data.opening_cash) + income - expenses
	return {"income": income, "expenses": expenses, "net": income - expenses,
		"waiver": maxi(0, -raw_cash), "capped": maxi(0, raw_cash - Balance.MAX_CASH),
		"closing_cash": clampi(raw_cash, 0, Balance.MAX_CASH)}

static func settle(city: RefCounted) -> void:
	city.last_budget = inputs(city)
	city.cash = totals(city.last_budget).closing_cash

