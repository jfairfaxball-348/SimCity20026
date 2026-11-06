extends RefCounted
## D25/D32: integer monthly accounting at the town's tax rate. No hidden debt or service cuts.
const Balance = preload("res://content/balance.gd")

static func inputs(city: RefCounted) -> Dictionary:
	var data: Dictionary = {"tick": city.tick, "opening_cash": city.cash,
		"residents": 0, "jobs": 0, "roads": 0, "stations": 0, "parks": 0, "police": 0, "fire": 0, "tax_rate": city.tax_rate}
	for i in range(city.width * city.height):
		match city.occupancy[i]:
			city.ROAD: data.roads += 1
			city.PARK: data.parks += 1
	# D30: one station and one lot per anchor, never per tile.
	data.stations = city.station_anchors.size()
	# D38: police and fire stations, working or not.
	for s in city.civic_anchors:
		if city.occupancy[s] == city.POLICE: data.police += 1
		else: data.fire += 1
	for i in city.lot_anchors:
		if not city.growth.serviced(city, i): continue
		match city.occupancy[i]:
			city.HOME: data.residents += Balance.capacity(city.HOME, city.development[i])
			city.SHOP: data.jobs += Balance.capacity(city.SHOP, city.development[i])
			city.WORKSHOP: data.jobs += Balance.capacity(city.WORKSHOP, city.development[i])
	return data

static func totals(data: Dictionary) -> Dictionary:
	var rate: int = int(data.get("tax_rate", Balance.TAX_STANDARD))
	var income: int = Balance.MONTH_GRANT + int(data.residents) * Balance.RESIDENT_TAX_PER_POINT * rate + int(data.jobs) * Balance.JOB_TAX_PER_POINT * rate
	var expenses: int = int(data.roads) * Balance.ROAD_UPKEEP + int(data.stations) * Balance.STATION_UPKEEP + int(data.parks) * Balance.PARK_UPKEEP + int(data.get("police", 0)) * Balance.POLICE_UPKEEP + int(data.get("fire", 0)) * Balance.FIRE_UPKEEP
	var raw_cash: int = int(data.opening_cash) + income - expenses
	return {"income": income, "expenses": expenses, "net": income - expenses,
		"waiver": maxi(0, -raw_cash), "capped": maxi(0, raw_cash - Balance.MAX_CASH),
		"closing_cash": clampi(raw_cash, 0, Balance.MAX_CASH)}

static func settle(city: RefCounted) -> void:
	city.last_budget = inputs(city)
	city.cash = totals(city.last_budget).closing_cash

