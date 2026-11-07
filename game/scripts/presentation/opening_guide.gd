extends RefCounted
## D29 (refreshed for 0.10.0-m2h): read-only First steps evaluation. It derives the
## first unmet step from the current town plus one session flag (project dialog
## opened). It never changes the model and is never saved.
## D42: card texts name the player's current keys; {action} placeholders are filled from
## the bindings (the defaults when none are given).
const City = preload("res://scripts/sim/city_state.gd")
const Bindings = preload("res://scripts/input/input_bindings.gd")
const TOTAL: int = 5
const NONE := Vector2i(-1, -1)
const TEMPLATES: Array[String] = [
	"Lay a road ({tool_road}) on the gold flag. It joins your town to the outside link.",
	"Zone a residential lot ({tool_home}) beside a road joined to the flag. Diagonals don't count.",
	"Place a power plant ({tool_power}) touching that street. It powers 20 lots.",
	"Run time ({pause_city} or 1x). Lots with road and power grow; R on the meter is demand.",
	"Optional goal: open Project ({show_project}). {show_summary} shows what holds the town back.",
]
const DONE_TEMPLATE: String = "Done. Next: parks, then police ({tool_police}) and fire ({tool_fire}) for level 4. Help has every rule."
## The texts with the default keys (kept for readers and tests).
static var TEXTS: Array[String] = texts({})
static var DONE_TEXT: String = done_text({})
const NO_LINK_TEXT: String = "This map has no outside link, so road access is unavailable."

## Key names by action: the given ones over the defaults.
static func key_names(keys: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for action in Bindings.REMAP_KEYS: out[action] = Bindings.key_name(int(Bindings.KEY_DEFAULTS[action][0]))
	out.merge(keys, true)
	return out

static func texts(keys: Dictionary) -> Array[String]:
	var names: Dictionary = key_names(keys)
	var out: Array[String] = []
	for template in TEMPLATES: out.append(template.format(names))
	return out

static func done_text(keys: Dictionary) -> String:
	return DONE_TEMPLATE.format(key_names(keys))

## Returns {state: "step"|"done"|"no_link", step, total, text, target (cell or NONE),
## size (bracket size in tiles), action: "show"|"project"|""}. keys: action → key name.
static func evaluate(city: City, project_seen: bool, keys: Dictionary = {}) -> Dictionary:
	var lines: Array[String] = texts(keys)
	var root: Vector2i = city.access.root
	if root.x < 0:
		return _result("no_link", 0, NO_LINK_TEXT, NONE, 1, "")
	if city.occupancy[city.index(root)] != City.ROAD:
		return _result("step", 1, lines[0], root, 1, "show")
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
		return _result("step", 2, lines[1], root, 1, "show")
	if serviced < 0:
		return _result("step", 3, lines[2], city.cell_of(accessed), City.footprint_size(City.HOME), "show")
	if not developed:
		return _result("step", 4, lines[3], city.cell_of(serviced), City.footprint_size(City.HOME), "show")
	if not project_seen and not city.project.completed:
		return _result("step", 5, lines[4], NONE, 1, "project")
	return _result("done", TOTAL, done_text(keys), NONE, 1, "")

static func _result(state: String, step: int, text: String, target: Vector2i, size: int, action: String) -> Dictionary:
	return {"state": state, "step": step, "total": TOTAL, "text": text, "target": target, "size": size, "action": action}
