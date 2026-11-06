extends RefCounted
## D34 town summary: a pure, read-only ranking of the measurable causes holding the
## town back, built from existing derived state. It never changes the model. Each item
## names its condition, where to look (an example lot) and a remedy; the per-lot
## inspector remains the detailed explanation.
const City = preload("res://scripts/sim/city_state.gd")
const Balance = preload("res://content/balance.gd")
const MAX_BLOCKERS: int = 5
## Tie-break order for blockers affecting the same number of levels.
const ORDER: Array[String] = ["no_link", "access", "no_power", "short", "held", "leaving", "no_room"]
const ZONE_NAMES: Dictionary = {City.HOME: "residential", City.SHOP: "commercial", City.WORKSHOP: "industrial"}

## Returns an Array of Dictionaries: kind, levels, count, built, example (cell index or
## -1), action ("show", "budget" or ""), zone (for no_room) and text.
static func build(city: City) -> Array:
	var blockers: Array = []
	var root: Vector2i = city.access.root
	var root_index: int = city.index(root) if root.x >= 0 else -1
	if not city.lot_anchors.is_empty():
		var no_access: Array = []
		var no_power: Array = []
		var short: Array = []
		var held: Array = []
		for a in city.lot_anchors:
			if city.access.served_homes[a] == 0: no_access.append(a)
			var state: int = city.power.home_state[a]
			if state == city.power.SHORTAGE: short.append(a)
			elif state != city.power.POWERED: no_power.append(a)
			if city.occupancy[a] == City.HOME and city.growth.serviced(city, a) and city.desirability.cap(city, a) < Balance.MAX_LEVEL and city.development[a] >= Balance.HELD_LEVEL:
				held.append(a)
		var link_missing: bool = root_index >= 0 and city.occupancy[root_index] != City.ROAD
		if link_missing and not no_access.is_empty():
			blockers.append(_lots("no_link", no_access, city, root_index))
		elif not no_access.is_empty():
			blockers.append(_lots("access", no_access, city))
		if not no_power.is_empty(): blockers.append(_lots("no_power", no_power, city))
		if not short.is_empty(): blockers.append(_lots("short", short, city))
		if not held.is_empty():
			var item: Dictionary = _lots("held", held, city)
			item.levels = held.size()
			blockers.append(item)
		if city.tax_rate > Balance.TAX_STANDARD:
			var surplus: int = 0
			for kind in [City.HOME, City.SHOP, City.WORKSHOP]: surplus += city.growth.surplus[kind]
			if surplus > 0:
				blockers.append({"kind": "leaving", "levels": surplus, "count": surplus, "built": surplus, "example": -1, "action": "budget", "zone": -1})
		for kind in [City.HOME, City.SHOP, City.WORKSHOP]:
			var wanted: int = city.growth.demand[kind]
			if wanted <= 0: continue
			var room: bool = false
			for a in city.lot_anchors:
				if city.occupancy[a] == kind and city.growth.serviced(city, a) and city.development[a] < city.desirability.cap(city, a):
					room = true
					break
			if not room:
				blockers.append({"kind": "no_room", "levels": wanted, "count": wanted, "built": 0, "example": root_index, "action": "show" if root_index >= 0 else "", "zone": kind})
	var items: Array = rank(blockers)
	var net: int = City.Economy.totals(city.budget).net
	if city.lot_anchors.is_empty():
		items.append({"kind": "empty", "levels": 0, "count": 0, "built": 0, "example": root_index, "action": "show" if root_index >= 0 else "", "zone": -1})
	elif items.is_empty() and net >= 0:
		items.append({"kind": "satisfied", "levels": 0, "count": 0, "built": 0, "example": -1, "action": "", "zone": -1})
	if net < 0:
		items.append({"kind": "deficit", "levels": 0, "count": -net, "built": 0, "example": -1, "action": "budget", "zone": -1})
	for item in items: item["text"] = describe(item, city)
	return items

## Most levels affected first; table order breaks ties, then input order. At most
## MAX_BLOCKERS are kept.
static func rank(blockers: Array) -> Array:
	var ranked: Array = []
	for n in range(blockers.size()): ranked.append([blockers[n], n])
	ranked.sort_custom(func(x, y):
		var a: Dictionary = x[0]
		var b: Dictionary = y[0]
		if a.levels != b.levels: return a.levels > b.levels
		if a.kind != b.kind: return ORDER.find(a.kind) < ORDER.find(b.kind)
		return x[1] < y[1])
	var out: Array = []
	for pair in ranked.slice(0, MAX_BLOCKERS): out.append(pair[0])
	return out

static func _lots(kind: String, anchors: Array, city: City, example: int = -2) -> Dictionary:
	var built: int = 0
	for a in anchors:
		if city.development[int(a)] > 0: built += 1
	return {"kind": kind, "levels": Balance.MAX_LEVEL * anchors.size(), "count": anchors.size(), "built": built,
		"example": int(anchors[0]) if example == -2 else example, "action": "show", "zone": -1}

static func _plural(count: int, word: String) -> String:
	return "%d %s%s" % [count, word, "" if count == 1 else "s"]

static func _built(item: Dictionary) -> String:
	return "" if int(item.built) == 0 else " (%d with buildings that will lose levels)" % int(item.built)

static func describe(item: Dictionary, city: City) -> String:
	match String(item.kind):
		"no_link": return "The gold flag has no road, so %s cannot reach the edge of the map%s. Lay a road on the flag and join your streets to it." % [_plural(item.count, "lot"), _built(item)]
		"access": return "%s without road access%s. Join a road beside each lot to streets that reach the gold flag." % [_plural(item.count, "lot"), _built(item)]
		"no_power": return "%s without power%s. Place a power plant (P) beside their street, or join the street to a powered one." % [_plural(item.count, "lot"), _built(item)]
		"short": return "%s short of power%s. Each power plant supplies %d lots: add a plant on that network." % [_plural(item.count, "lot"), _built(item), Balance.POWER_CAPACITY / Balance.HOME_POWER_DEMAND]
		"held": return "%s held at level 1 by nearby industry. Add a park within 3 steps, or keep industrial lots 3+ steps away." % _plural(item.count, "residential lot")
		"leaving": return "%s leaving because the tax rate is %d%% (above %d%%). Lower it in Budget to keep them." % [_plural(item.count, "level"), city.tax_rate, Balance.TAX_STANDARD]
		"no_room":
			var name: String = ZONE_NAMES[int(item.zone)]
			return "%s wanted, but no %s lot can grow. Zone more %s lots beside connected, powered streets." % [_plural(item.count, name + " level"), name, name]
		"deficit": return "Monthly deficit of %s. Clear unused roads, power plants or parks, restore services, or review the tax rate in Budget." % Balance.money(int(item.count))
		"empty": return "No zones yet. Lay a road on the gold flag, zone 3x3 residential lots beside it, then add a 4x4 power plant (P)."
		"satisfied": return "Nothing measurable is holding the town back. Demand is met; residents and jobs create more demand as the town grows, and lower taxes raise it."
	return ""
