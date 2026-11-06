extends RefCounted
## D34 / M2h: the derived town summary on constructed towns.
const City = preload("res://scripts/sim/city_state.gd")
const Balance = preload("res://content/balance.gd")
const Summary = preload("res://scripts/presentation/town_summary.gd")
var t: SceneTree
var growth = preload("res://tests/growth_tests.gd").new()

func days(city: City, count: int) -> void:
	growth.days(city, count)

func kinds(items: Array) -> Array:
	return items.map(func(item): return String(item.kind))

func item(items: Array, kind: String) -> Dictionary:
	for entry in items:
		if String(entry.kind) == kind: return entry
	return {}

## Checks purity: building a summary must not change the town.
func pure(city: City) -> Array:
	var before: String = city.canonical()
	var sequence: int = city.sequence
	var state: int = city.rng.state
	var items: Array = Summary.build(city)
	t.check(city.canonical() == before and city.sequence == sequence and city.rng.state == state, "building the summary leaves the town unchanged (%s)" % ", ".join(kinds(items)))
	var levels_ordered: bool = true
	var blockers: Array = items.filter(func(entry): return not String(entry.kind) in ["deficit", "empty", "satisfied"])
	for n in range(1, blockers.size()): levels_ordered = levels_ordered and int(blockers[n - 1].levels) >= int(blockers[n].levels)
	t.check(levels_ordered and blockers.size() <= Summary.MAX_BLOCKERS, "blockers are ordered by levels affected, at most five (%s)" % ", ".join(kinds(items)))
	return items

func run(tester: SceneTree) -> void:
	t = tester
	growth.t = t
	# Empty town.
	var empty: City = t.land(24, 12)
	var items: Array = pure(empty)
	t.check(kinds(items) == ["empty"] and int(items[0].example) == empty.index(empty.access.root) and items[0].action == "show" and "No zones yet" in String(items[0].text), "an empty town gets the starting steps and shows the flag")
	# Lots with no road on the flag and no station.
	var bare: City = t.land(24, 12)
	bare.apply_command("home", t.lots_row(3, 4, 2))
	items = pure(bare)
	t.check(kinds(items) == ["no_link", "no_power", "no_room"], "no flag road: no-link, no-power, then no-room for the starter demand")
	t.check(int(item(items, "no_link").count) == 2 and int(item(items, "no_link").levels) == 4 and int(item(items, "no_link").example) == bare.index(bare.access.root), "no-link counts both lots, 2 levels each, and shows the flag")
	t.check(int(item(items, "no_room").levels) == 3 and int(item(items, "no_room").zone) == City.HOME and "3 residential levels wanted" in String(item(items, "no_room").text), "no-room reports the three starter home levels")
	# A served town with one isolated lot.
	var town: City = growth.town()
	town.apply_command("home", [Vector2i(20, 0)])
	items = pure(town)
	var isolated: int = town.index(Vector2i(20, 0))
	t.check(int(item(items, "access").count) == 1 and int(item(items, "access").example) == isolated and int(item(items, "no_power").example) == isolated and not "no_link" in kinds(items), "an isolated lot is reported for access and power separately, with itself as the example")
	t.check(String(item(items, "access").text).begins_with("1 lot without road access"), "access text uses the singular for one lot")
	# Shortage.
	var crowded: City = growth.displacement_town()
	crowded.apply_command("shop", [Vector2i(0, 1)])
	items = pure(crowded)
	var short: Dictionary = item(items, "short")
	t.check(int(short.count) == 1 and int(short.built) == 1 and "(1 with buildings that will lose levels)" in String(short.text) and int(short.example) == crowded.index(Vector2i(65, 1)), "a shortage names the displaced grown lot and its pending decline")
	# Held homes beside workshops (D33).
	var grown: City = growth.town()
	days(grown, 40)
	items = pure(grown)
	t.check(kinds(items) == ["held", "no_room"] and int(item(items, "held").count) == 2 and int(item(items, "held").example) == grown.index(Vector2i(13, 3)), "a grown town reports its two held homes first, then the unusable home demand")
	t.check("2 residential lots held at level 1" in String(item(items, "held").text) and "2 residential levels wanted" in String(item(items, "no_room").text), "held and no-room texts give counts and remedies")
	# Leaving under high taxes (D32).
	grown.set_tax_rate(25)
	items = pure(grown)
	t.check(items[0].kind == "leaving" and int(items[0].levels) == 9 and items[0].action == "budget" and "25%" in String(items[0].text), "high taxes put the nine leaving levels first with a Budget action")
	# A satisfied town: workshops kept three steps from every home.
	var calm: City = t.land(33, 12)
	calm.apply_command("road", t.row(6, 4, 32))
	calm.apply_command("power", [Vector2i(0, 5)])
	calm.apply_command("home", t.lots_row(3, 4, 6))
	calm.apply_command("shop", t.lots_row(7, 4, 3))
	calm.apply_command("workshop", t.lots_row(7, 24, 3))
	days(calm, 60)
	items = pure(calm)
	t.check(calm.growth.population == 48 and kinds(items) == ["satisfied"] and items[0].action == "", "a buffered town at equilibrium has nothing holding it back")
	# A deficit follows any blockers; here an empty town with two stations.
	var costly: City = t.land(24, 12)
	costly.apply_command("road", t.row(6, 4, 23))
	costly.apply_command("power", [Vector2i(0, 5)])
	costly.apply_command("power", [Vector2i(0, 0)])
	items = pure(costly)
	var net: int = City.Economy.totals(costly.budget).net
	t.check(kinds(items) == ["empty", "deficit"] and int(item(items, "deficit").count) == -net and item(items, "deficit").action == "budget" and Balance.money(-net) in String(item(items, "deficit").text), "a deficit item states the exact monthly shortfall and opens Budget")
	# Ranking keeps at most five, by levels then table order.
	var synthetic: Array = []
	for entry in [["no_room", 3], ["held", 4], ["leaving", 9], ["access", 4], ["short", 2], ["no_power", 4], ["no_room", 1]]:
		synthetic.append({"kind": entry[0], "levels": entry[1]})
	t.check(kinds(Summary.rank(synthetic)) == ["leaving", "access", "no_power", "held", "no_room"], "ranking: most levels first, table order on ties, at most five")
	print("PASS group: M2h town summary items, ordering, purity and texts")
