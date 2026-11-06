extends RefCounted
## D35: a display-only calendar derived from the tick; never saved and never a rule.
## Tick 0 is 1 January of START_YEAR; months are the D25 30-day budget month.
const Balance = preload("res://content/balance.gd")
const START_YEAR: int = 1950
const MONTHS_PER_YEAR: int = 12
const SHORT: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const LONG: Array[String] = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

## Zero-based month count since 1 January START_YEAR.
static func month_index(tick: int) -> int:
	return maxi(tick, 0) / Balance.MONTH_DAYS

static func day_of_month(tick: int) -> int:
	return maxi(tick, 0) % Balance.MONTH_DAYS + 1

static func year(tick: int) -> int:
	return START_YEAR + month_index(tick) / MONTHS_PER_YEAR

## "1 Jan 1950" for tick 0.
static func date(tick: int) -> String:
	return "%d %s %d" % [day_of_month(tick), SHORT[month_index(tick) % MONTHS_PER_YEAR], year(tick)]

## "Jan 1950" for any tick in that month.
static func month(tick: int) -> String:
	return "%s %d" % [SHORT[month_index(tick) % MONTHS_PER_YEAR], year(tick)]

## "January 1950": the month closed by a settlement at a positive multiple of 30 ticks.
static func settled_month(settlement_tick: int) -> String:
	var t: int = maxi(settlement_tick - 1, 0)
	return "%s %d" % [LONG[month_index(t) % MONTHS_PER_YEAR], year(t)]
