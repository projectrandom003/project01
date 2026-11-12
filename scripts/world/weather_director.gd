class_name WeatherDirector
extends RefCounted
## WEATHER ARCHITECTURE (Phase 3, Visual World) — pure, deterministic,
## headless-testable. It holds NO nodes, NO SceneTree state and NO rendering.
##
## WeatherDirector is a lightweight state machine that DESCRIBES what the world
## should look like (fog density, particle scale, rain amount, wind, tint) as a
## set of plain numbers. The world (GreenwardWorld) reads params() and applies
## them to the fog quad / CPUParticles2D / lights. This keeps weather trivially
## unit-testable: construct it, drive it with fixed tick(delta) steps, and assert
## on params() — a given (seed, tick sequence) always yields the same timeline
## because the transition RNG is seeded (no global RNG).
##
## HONEST LIMITATIONS
##  * There is NO real weather simulation: no fluid dynamics, no precipitation
##    physics, no accumulation, no wind field. States are authored "moods" with
##    deterministic, timed transitions and a smooth 0..1 `intensity` ramp.
##  * RAIN / SNOW VFX (if the world enables them) are intentionally LIGHTWEIGHT:
##    at most one cheap downward CPU particle emitter, capped by
##    GreenwardStyle.MAX_PARTICLES and DISABLED on the "mobile" performance tier.
##    No per-drop nodes, no collisions, no splashes. This is only a hook/seam.
##  * All art is procedural placeholder; weather only tints / moves existing art.
##    No device profiling has been performed — the mobile tier is a coarse
##    platform hint from GreenwardStyle.performance_tier().

## Emitted whenever set_state()/tick() changes the active weather state.
signal state_changed(new_state: int)
## Emitted when a transition fires (convenience for listeners that re-read params).
signal params_changed

# State ids (plain int constants so callers never depend on an enum lookup).
const CLEAR := 0
const MIST := 1
const RAIN := 2
const POLLEN_BLOOM := 3

const ALL_STATES: Array = [CLEAR, MIST, RAIN, POLLEN_BLOOM]

const STATE_NAMES: Dictionary = {
	CLEAR: "clear",
	MIST: "mist",
	RAIN: "rain",
	POLLEN_BLOOM: "pollen_bloom",
}

# Deterministic transition table: from each state, the list of possible next
# states. The seeded RNG picks one, so a fixed seed reproduces a fixed timeline.
const TRANSITIONS: Dictionary = {
	CLEAR: [MIST, POLLEN_BLOOM, CLEAR],
	MIST: [CLEAR, RAIN, MIST],
	RAIN: [MIST, CLEAR],
	POLLEN_BLOOM: [CLEAR, MIST],
}

# Target intensity of each state; `intensity` ramps toward this at RAMP_SPEED.
const STATE_INTENSITY: Dictionary = {
	CLEAR: 0.0,
	MIST: 0.7,
	RAIN: 1.0,
	POLLEN_BLOOM: 0.6,
}

const MIN_DWELL := 18.0   # seconds a state is held before a transition may fire
const MAX_DWELL := 34.0
const RAMP_SPEED := 0.35  # intensity units per second

var current_state: int = CLEAR
var intensity: float = 0.0
var seed_value: int = 20240611

var _rng: RandomNumberGenerator
var _dwell: float = 0.0
var _dwell_limit: float = 24.0


func _init(p_seed: int = 20240611) -> void:
	seed_value = p_seed
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value
	current_state = CLEAR
	intensity = 0.0
	_dwell = 0.0
	_dwell_limit = _rng.randf_range(MIN_DWELL, MAX_DWELL)


static func state_name(s: int) -> String:
	return str(STATE_NAMES.get(s, "clear"))


static func is_valid_state(s: int) -> bool:
	return ALL_STATES.has(s)


## Force a (clamped) state. Resets the dwell timer and begins ramping intensity
## toward the new state's target. Emits state_changed + params_changed.
func set_state(s: int) -> void:
	if not is_valid_state(s):
		return
	current_state = s
	_dwell = 0.0
	_dwell_limit = _rng.randf_range(MIN_DWELL, MAX_DWELL)
	state_changed.emit(current_state)
	params_changed.emit()


## Advance by `delta` seconds. Returns TRUE iff a state transition fired.
## Intensity always ramps toward the current state's target; a transition is
## chosen deterministically once the per-state dwell timer expires.
func tick(delta: float) -> bool:
	if not (delta > 0.0):
		return false
	_dwell += delta
	var target_intensity := float(STATE_INTENSITY.get(current_state, 0.0))
	intensity = move_toward(intensity, target_intensity, RAMP_SPEED * delta)
	if _dwell >= _dwell_limit:
		var options: Array = TRANSITIONS.get(current_state, [CLEAR])
		var next := int(options[_rng.randi() % options.size()])
		set_state(next)
		return true
	return false


## Full, cheap parameter snapshot consumed by the world. Keys intentionally
## include the exact contract: fog_density, particle_scale, rain_amount,
## wind_boost, tint — plus colour/state/cap metadata. Particle counts are capped
## by GreenwardStyle.MAX_PARTICLES and reduced on the mobile tier.
func params() -> Dictionary:
	var tier := GreenwardStyle.performance_tier()
	var mobile := tier == "mobile"
	var cap := GreenwardStyle.MAX_PARTICLES
	if mobile:
		cap = int(cap * 0.4)

	var fog_density := 0.0
	var fog_color: Color = GreenwardStyle.phase("Day").get("fog", Color(0.8, 0.88, 0.95, 1.0))
	var particle_scale := 1.0
	var rain_amount := 0
	var pollen_amount := 0
	var wind_boost := 0.0
	var tint := Color.WHITE

	match current_state:
		MIST:
			fog_density = 0.30 * intensity
			fog_color = GreenwardStyle.phase("Dawn").get("fog", Color(0.7, 0.6, 0.65, 1.0))
			particle_scale = 0.8
			wind_boost = 0.15 * intensity
			tint = Color(0.88, 0.93, 0.98)
		RAIN:
			fog_density = 0.18 * intensity
			fog_color = GreenwardStyle.WATER.deep
			particle_scale = 1.2
			# Light rain hook: a single capped emitter; disabled on mobile.
			rain_amount = 0 if mobile else int(cap * 0.5 * intensity)
			wind_boost = 0.6 * intensity
			tint = Color(0.72, 0.82, 0.92)
		POLLEN_BLOOM:
			fog_density = 0.06 * intensity
			fog_color = GreenwardStyle.ACCENTS.petal_alt
			particle_scale = 1.5
			pollen_amount = int(cap * 0.12 * intensity)
			wind_boost = 0.25 * intensity
			tint = Color(1.0, 0.96, 0.82)
		_:  # CLEAR
			fog_density = 0.0
			fog_color = GreenwardStyle.phase("Day").get("fog", Color(0.8, 0.88, 0.95, 1.0))
			particle_scale = 1.0
			tint = Color.WHITE

	return {
		"state": current_state,
		"state_name": state_name(current_state),
		"intensity": clampf(intensity, 0.0, 1.0),
		"fog_density": clampf(fog_density, 0.0, 0.6),
		"fog_color": fog_color,
		"particle_scale": particle_scale,
		"rain_amount": clampi(rain_amount, 0, GreenwardStyle.MAX_PARTICLES),
		"pollen_amount": clampi(pollen_amount, 0, GreenwardStyle.MAX_PARTICLES),
		"wind_boost": clampf(wind_boost, 0.0, 1.0),
		"tint": tint,
		"mobile": mobile,
		"particle_cap": cap,
		"performance_tier": tier,
	}


## Silent hard reset to CLEAR / intensity 0 with a fresh seeded RNG.
func reset() -> void:
	_rng.seed = seed_value
	current_state = CLEAR
	intensity = 0.0
	_dwell = 0.0
	_dwell_limit = _rng.randf_range(MIN_DWELL, MAX_DWELL)
