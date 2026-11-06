extends RefCounted
## D29 (refreshed for 0.10.0-m2h): read-only First steps evaluation. It derives the
## first unmet step from the current town plus one session flag (project dialog
## opened). It never changes the model and is never saved.
const City = preload("res://scripts/sim/city_state.gd")
const TOTAL: int = 5
const NONE := Vector2i(-1, -1)
const TEXTS: Array[String] = [
	"Lay a road (1) on the gold flag. It joins your town to the outside link.",
	"Zone a residential lot (2) beside a road joined to the flag. Diagonals don't count.",
	"Place a power plant (P) touching that street. It powers 20 lots.",
	"Run time (Space or 1x). Lots with road and power grow; R on the meter is demand.",
	"Optional goal: open Project (J). T shows what holds the town back.",
]
const DONE_TEXT: String = "First steps done. T shows what holds the town back; Help lists every rule."
const NO_LINK_TEXT: String = "This map has no outside link, so road access is unavailable."

## Returns {state: "step"|"done"|"no_link", step, total, text, target (cell or NONE),
## size (bracket size in tiles), action: "show"|"project"|""}.
static func evaluate(city: City, project_seen: bool) -> Dictionary:
	var root: Vector2i = city.access.root
	if root.x < 0:
		return _result("no_link", 0, NO_LINK_TEXT, NONE, 1, "")
	if city.occupancy[city.index(root)] != City.ROAD:
		return _result("step", 1, TEXTS[0], root, 1, "show")
	var accessed: int = -1
	var serviced: int = -1
	var developed: bool = false
	for a in city.lot_anchors:
		if city.occupancy[a] != City.HOME: continue
		if city.development[a] > 0: developed = true
		if city.access.served_homes[a] == 0: continue
		if accessed < 0: accessed = a
		if serviced < 0 and city.power.home_state[a] == city.power.POWERED: serviced = a
	if accessed < 0:
		return _result("step", 2, TEXTS[1], root, 1, "show")
	if serviced < 0:
		return _result("step", 3, TEXTS[2], city.cell_of(accessed), City.footprint_size(City.HOME), "show")
	if not developed:
		return _result("step", 4, TEXTS[3], city.cell_of(serviced), City.footprint_size(City.HOME), "show")
	if not project_seen and not city.project.completed:
		return _result("step", 5, TEXTS[4], NONE, 1, "project")
	return _result("done", TOTAL, DONE_TEXT, NONE, 1, "")

static func _result(state: String, step: int, text: String, target: Vector2i, size: int, action: String) -> Dictionary:
	return {"state": state, "step": step, "total": TOTAL, "text": text, "target": target, "size": size, "action": action}
