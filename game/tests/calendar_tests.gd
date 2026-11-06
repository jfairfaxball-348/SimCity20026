extends RefCounted
## D35 / R1: the display-only calendar and the Residential / Commercial / Industrial wording.
const City = preload("res://scripts/sim/city_state.gd")
const Balance = preload("res://content/balance.gd")
const Calendar = preload("res://scripts/presentation/calendar.gd")
const Meter = preload("res://scripts/presentation/demand_meter.gd")
const Summary = preload("res://scripts/presentation/town_summary.gd")
const Guide = preload("res://scripts/presentation/opening_guide.gd")
var t: SceneTree

func run(tree: SceneTree) -> void:
	t = tree
	test_calendar()
	test_wording()
	print("PASS group: R1 calendar and Residential / Commercial / Industrial wording")

func test_calendar() -> void:
	t.check(Calendar.date(0) == "1 Jan 1950" and Calendar.month(0) == "Jan 1950", "tick 0 is 1 January 1950")
	t.check(Calendar.date(29) == "30 Jan 1950" and Calendar.date(30) == "1 Feb 1950", "months are the 30-day budget month")
	t.check(Calendar.date(Balance.MONTH_DAYS * 11) == "1 Dec 1950" and Calendar.date(359) == "30 Dec 1950" and Calendar.date(360) == "1 Jan 1951", "twelve months make a 360-day year")
	t.check(Calendar.settled_month(30) == "January 1950" and Calendar.settled_month(360) == "December 1950" and Calendar.settled_month(390) == "January 1951", "a settlement names the month it closed")
	t.check(Calendar.date(-5) == "1 Jan 1950", "negative ticks clamp to the start date")
	var last: String = Calendar.date(City.MAX_TICK)
	t.check(Calendar.year(City.MAX_TICK) == 1950 + City.MAX_TICK / 360 and last.length() <= 15, "the tick limit still gives a short, valid date (%s)" % last)
	var every_month: bool = true
	for m in range(24):
		every_month = every_month and Calendar.date(m * 30).begins_with("1 " + Calendar.SHORT[m % 12])
	t.check(every_month, "every month boundary starts on day 1 of the next month name")
	var c := City.new()
	c.initialize()
	var before: String = c.canonical()
	Calendar.date(c.tick)
	t.check(c.canonical() == before and not "1950" in before, "the calendar reads the tick only and nothing date-like is saved")

func test_wording() -> void:
	t.check(Meter.LETTERS == ["R", "C", "I"], "the demand meter letters are R / C / I")
	var m := Meter.new()
	m.set_values([3, 0, -2])
	t.check(m.summary() == "R +3 · C 0 · I −2" and "R residential, C commercial, I industrial" in m.tooltip_text, "the meter reading and tooltip use the R / C / I words")
	m.free()
	t.check(Summary.ZONE_NAMES.values() == ["residential", "commercial", "industrial"], "summary items name residential, commercial and industrial lots")
	var guide_words: String = " ".join(Guide.TEXTS) + " " + Guide.DONE_TEXT
	t.check(not "home" in guide_words.to_lower() and not "station" in guide_words and "residential lot" in guide_words and "power plant" in guide_words, "First steps use residential lot and power plant")
	var c := City.new()
	c.initialize(198624, 16, 16)
	var plant: Dictionary = c.apply_command("power", [Vector2i(8, 8)])
	t.check(plant.ok and String(plant.message).begins_with("Power plant built"), "placing a power plant reports a power plant")
	var blocked: Dictionary = c.apply_command("road", [Vector2i(9, 9)])
	t.check(not blocked.ok and "power plant" in String(blocked.message), "rejections name the power plant")
