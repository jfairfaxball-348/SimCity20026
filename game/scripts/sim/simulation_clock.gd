extends RefCounted
const City = preload("res://scripts/sim/city_state.gd")
const STEP_US: int = 1_000_000
const MAX_STEPS_PER_FRAME: int = 8

## Integer elapsed time, retained backlog, no scene or wall-clock dependencies.
static func advance(city: City, elapsed_us: int, speed: int) -> int:
	if speed not in [1, 3] or elapsed_us < 0 or city.tick >= City.MAX_TICK:
		return 0
	# Preserve long-frame time up to the explicit one-hour backlog bound.
	# Clamp before multiplication so an extreme elapsed value cannot overflow.
	var accepted_us: int = mini(elapsed_us, City.MAX_PENDING_US)
	city.pending_us = mini(city.pending_us + accepted_us * speed, City.MAX_PENDING_US)
	var steps: int = mini(city.pending_us / STEP_US, MAX_STEPS_PER_FRAME)
	steps = mini(steps, City.MAX_TICK - city.tick)
	city.tick += steps
	city.pending_us -= steps * STEP_US
	return steps
