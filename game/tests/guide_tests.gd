extends RefCounted
## D29 / M3b (refreshed): the read-only First steps evaluation.
const City = preload("res://scripts/sim/city_state.gd")
const Codec = preload("res://scripts/persistence/save_codec.gd")
const Guide = preload("res://scripts/presentation/opening_guide.gd")
var t: SceneTree
var growth = preload("res://tests/growth_tests.gd").new()

## Evaluates twice, checking purity and determinism, and returns the result.
func evaluate(city: City, seen: bool, label: String) -> Dictionary:
	var before: String = city.canonical()
	var sequence: int = city.sequence
	var state: int = city.rng.state
	var first: Dictionary = Guide.evaluate(city, seen)
	var second: Dictionary = Guide.evaluate(city, seen)
	t.check(first == second and city.canonical() == before and city.sequence == sequence and city.rng.state == state, "guide evaluation is pure and repeatable: " + label)
	return first

func run(tester: SceneTree) -> void:
	t = tester
	growth.t = t
	var fresh := City.new()
	fresh.initialize()
	var g: Dictionary = evaluate(fresh, false, "default town")
	t.check(g.state == "step" and g.step == 1 and g.target == fresh.access.root and g.action == "show" and g.total == 5, "a fresh default town is step 1, targeting the gold flag")
	# Progression on a small all-land town.
	var c: City = t.land(24, 12)
	t.check(evaluate(c, false, "empty land").step == 1, "empty land starts at step 1")
	c.apply_command("road", t.row(6, 4, 23))
	g = evaluate(c, false, "flag road")
	t.check(g.step == 2 and g.target == c.access.root and g.size == 1, "a flag road gives step 2, still showing the flag")
	c.apply_command("home", [Vector2i(4, 3)])
	g = evaluate(c, false, "home lot")
	t.check(g.step == 3 and g.target == Vector2i(4, 3) and g.size == 3, "a home lot beside the street gives step 3 targeting its 3x3 footprint")
	c.apply_command("power", [Vector2i(0, 5)])
	g = evaluate(c, false, "station")
	t.check(g.step == 4 and g.target == Vector2i(4, 3) and "meter" in String(g.text), "a station gives step 4 on the serviced home; the text points at the meter")
	growth.days(c, 5)
	g = evaluate(c, false, "grown")
	t.check(g.step == 5 and g.action == "project" and g.target == Guide.NONE and "T shows" in String(g.text), "one growth round gives step 5 with Open Project and a T summary pointer")
	g = evaluate(c, true, "project seen")
	t.check(g.state == "done" and g.action == "" and "Help" in String(g.text), "opening Project completes the steps")
	c.apply_command("clear", [c.access.root])
	t.check(evaluate(c, true, "flag cleared").step == 1, "clearing the flag road returns the card to step 1")
	# Non-advancing cases.
	var split: City = t.land(24, 16)
	split.apply_command("road", t.join(t.row(8, 4, 23), t.row(12, 0, 10)))
	split.apply_command("home", [Vector2i(0, 9)])
	t.check(evaluate(split, false, "disconnected district").step == 2, "a home on a district not joined to the flag stays at step 2")
	var diagonal: City = t.land(24, 12)
	diagonal.apply_command("road", t.row(6, 4, 23))
	diagonal.apply_command("home", [Vector2i(1, 3)])
	t.check(evaluate(diagonal, false, "diagonal").step == 2, "a home touching the street only diagonally stays at step 2")
	var shops: City = t.land(24, 12)
	shops.apply_command("road", t.row(6, 4, 23))
	shops.apply_command("shop", [Vector2i(4, 3)])
	shops.apply_command("workshop", [Vector2i(4, 7)])
	shops.apply_command("power", [Vector2i(0, 5)])
	t.check(evaluate(shops, false, "businesses only").step == 2, "shops and workshops never advance the home steps")
	var separate: City = t.land(24, 16)
	separate.apply_command("road", t.join(t.row(8, 4, 23), t.row(12, 0, 10)))
	separate.apply_command("home", [Vector2i(4, 5)])
	separate.apply_command("power", [Vector2i(11, 10)])
	t.check(separate.station_anchors.size() == 1 and separate.access.root == Vector2i(23, 8), "the separate-network town has its station and flag road")
	t.check(evaluate(separate, false, "separate network").step == 3, "a station on a separate network leaves step 3")
	# No outside link: an all-water boundary.
	var island: City = t.land(8, 8)
	for i in range(64):
		var cell: Vector2i = island.cell_of(i)
		if cell.x == 0 or cell.y == 0 or cell.x == 7 or cell.y == 7: island.terrain[i] = City.WATER
	island.rebuild_derived()
	g = evaluate(island, false, "no link")
	t.check(g.state == "no_link" and g.action == "" and g.target == Guide.NONE and "no outside link" in String(g.text), "an all-water boundary gives the no-link card with no target")
	# Fixtures evaluate deterministically; the completed M2e town is done.
	for fixture in ["m1-schema1", "m2a-schema1", "m2b-schema2", "m2c-schema3", "m2d-schema4", "m3a-schema5", "m2e-schema6", "m2f-schema7", "m2g-schema8"]:
		var loaded: Dictionary = Codec.decode(FileAccess.get_file_as_string("res://tests/fixtures/%s.json" % fixture))
		var result: Dictionary = evaluate(loaded.city, false, fixture)
		if fixture == "m2e-schema6": t.check(result.state == "done", "the completed schema-6 fixture is done without opening Project")
		if fixture == "m3a-schema5": t.check(result.step == 2, "the M3a fixture's cleared single-tile homes put it at step 2")
		if fixture == "m2g-schema8": t.check(result.step == 5, "the schema-8 fixture town with grown homes is at the optional step 5")
	var long: bool = true
	for text in Guide.TEXTS + [Guide.DONE_TEXT, Guide.NO_LINK_TEXT]: long = long and String(text).length() <= 90
	t.check(long, "every card text stays within 90 characters")
	print("PASS group: M3b first steps evaluation, progression, non-advancing cases and purity")
