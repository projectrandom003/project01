class_name CharacterAnimator
extends RefCounted
## Pure, deterministic, scene-independent character-animation STATE MACHINE.
##
## This is the headless-testable foundation for character animation in PROJECT
## FANTASY. It holds NO nodes, does NOT touch the SceneTree, reads NO files and
## allocates NO resources: it is plain data plus integer/frame arithmetic, so a
## unit test can construct it, drive it with a fixed sequence of calls, and
## always get the exact same result. Signals are used only for observation.
##
## ANIMATION MODEL -- 8 STATES x 8 DIRECTIONS
## The requested animation list is:
##   Idle / Walk / Run / Directional / Interact / Attack / Damage /
##   Victory / Defeat.
## "Directional" is NOT a ninth state. It is the DIRECTION dimension (below),
## applied ON TOP of a state (most visibly WALK and RUN, but any state can be
## rendered in any direction). The model is therefore 8 STATES and a separate
## 8-value DIRECTION axis: 8 x 8 = 64 possible (state, direction) pairs, all
## driven by ONE state machine. Keeping direction orthogonal to state is what
## lets a frame source address (state, direction, frame_index) directly.
##
## STATES (integer ids, stable contract shared with ActorFrameSource):
##   0 IDLE, 1 WALK, 2 RUN, 3 INTERACT, 4 ATTACK, 5 DAMAGE, 6 VICTORY, 7 DEFEAT
## DIRECTIONS (integer ids):
##   0 DOWN, 1 DOWN_RIGHT, 2 RIGHT, 3 UP_RIGHT,
##   4 UP,   5 UP_LEFT,     6 LEFT, 7 DOWN_LEFT
##
## The next round wires this into ActorVisual; the machine itself never needs
## Godot's renderer, so it is fully unit-testable in a headless runner.

# ---------------------------------------------------------------------------
# Enums / shared integer contract
# ---------------------------------------------------------------------------

enum State {
	IDLE = 0,
	WALK = 1,
	RUN = 2,
	INTERACT = 3,
	ATTACK = 4,
	DAMAGE = 5,
	VICTORY = 6,
	DEFEAT = 7,
	CAST = 8,
}

enum Direction {
	DOWN = 0,
	DOWN_RIGHT = 1,
	RIGHT = 2,
	UP_RIGHT = 3,
	UP = 4,
	UP_LEFT = 5,
	LEFT = 6,
	DOWN_LEFT = 7,
}

# Phase-3 core states, FROZEN for compatibility. The 550 headless tests and the
# GreenwardStyle.SPRITE_SPECS timing arrays assert exactly these 8 values in
# this order. Phase-4 CAST is an ADDITIVE 9th state exposed only via the
# EXTENDED_* constants and *_for() helpers below -- do NOT add 8 here.
const ALL_STATES: Array = [
	State.IDLE, State.WALK, State.RUN, State.INTERACT,
	State.ATTACK, State.DAMAGE, State.VICTORY, State.DEFEAT,
]

const ALL_DIRECTIONS: Array = [
	Direction.DOWN, Direction.DOWN_RIGHT, Direction.RIGHT, Direction.UP_RIGHT,
	Direction.UP, Direction.UP_LEFT, Direction.LEFT, Direction.DOWN_LEFT,
]

const STATE_NAMES: Dictionary = {
	State.IDLE: "idle",
	State.WALK: "walk",
	State.RUN: "run",
	State.INTERACT: "interact",
	State.ATTACK: "attack",
	State.DAMAGE: "damage",
	State.VICTORY: "victory",
	State.DEFEAT: "defeat",
}

const DIRECTION_NAMES: Dictionary = {
	Direction.DOWN: "down",
	Direction.DOWN_RIGHT: "down_right",
	Direction.RIGHT: "right",
	Direction.UP_RIGHT: "up_right",
	Direction.UP: "up",
	Direction.UP_LEFT: "up_left",
	Direction.LEFT: "left",
	Direction.DOWN_LEFT: "down_left",
}

# Playback timing. Targets come from documentation/ART_PIPELINE.md section 3:
#   Idle     4-6 frames @ 8-10 fps
#   Walk/Run 6-8 frames @ 12 / 14 fps
#   Attack   5-8 frames @ 15 fps, Cast 6-8 @ 12 fps, Hurt 2 @ 12 fps,
#   Death    5-8 frames, non-looping.
# The five non-movement states are ONE-SHOTS. The counts/fps below are the
# single source of truth shared with ActorFrameSource and the sprite sheets.
const STATE_FPS: Dictionary = {
	State.IDLE: 9.0,
	State.WALK: 60.0,
	State.RUN: 64.0,
	State.INTERACT: 12.0,
	State.ATTACK: 15.0,
	State.DAMAGE: 12.0,
	State.VICTORY: 12.0,
	State.DEFEAT: 10.0,
}

const STATE_FRAMES: Dictionary = {
	State.IDLE: 5,
	State.WALK: 64,
	State.RUN: 64,
	State.INTERACT: 6,
	State.ATTACK: 6,
	State.DAMAGE: 2,
	State.VICTORY: 8,
	State.DEFEAT: 6,
}

# Looping states wrap forever; the other five are one-shots that clamp on the
# last frame, stop, and emit one_shot_finished exactly once.
const STATE_LOOPING: Dictionary = {
	State.IDLE: true,
	State.WALK: true,
	State.RUN: true,
	State.INTERACT: false,
	State.ATTACK: false,
	State.DAMAGE: false,
	State.VICTORY: false,
	State.DEFEAT: false,
}

# Higher number == higher priority. Required order:
#   DEFEAT > VICTORY > DAMAGE > ATTACK > INTERACT > RUN > WALK > IDLE
# A lower-priority play() cannot interrupt a higher-priority UNFINISHED
# one-shot. Looping states never lock, so movement stays responsive.
const STATE_PRIORITY: Dictionary = {
	State.DEFEAT: 8,
	State.VICTORY: 7,
	State.DAMAGE: 6,
	State.ATTACK: 5,
	State.INTERACT: 4,
	State.RUN: 3,
	State.WALK: 2,
	State.IDLE: 1,
}

# ---------------------------------------------------------------------------
# Phase-4 ADDITIVE CAST state (9th state). Deliberately kept OUT of the frozen
# 8-element arrays/dicts above so every Phase-3 test and the
# GreenwardStyle.SPRITE_SPECS timing arrays stay byte-for-byte unchanged. All
# new timing/lookup flows through the static *_for() helpers.
# ---------------------------------------------------------------------------

const CAST_STATE := 8
const CAST_FRAMES := 7
const CAST_FPS := 12.0
const CAST_LOOPING := false
# CAST sits at the ATTACK tier (5): a lower-priority request cannot interrupt an
# unfinished cast, while DAMAGE(6)/VICTORY(7)/DEFEAT(8) still can. Integer tiers
# keep priority_for() consistent with the integer-keyed STATE_PRIORITY dict.
const CAST_PRIORITY := 5

# All 9 animatable states (8 core + CAST). is_valid_state() consults THIS list.
const EXTENDED_STATES := [0, 1, 2, 3, 4, 5, 6, 7, 8]
const EXTENDED_STATE_NAMES := {
	0: "idle", 1: "walk", 2: "run", 3: "interact",
	4: "attack", 5: "damage", 6: "victory", 7: "defeat", 8: "cast",
}
# Looping / locomotion states that never lock on priority.
const LOCOMOTION_STATES := [0, 1, 2]
# One-shot -> state to return to when it finishes. DEFEAT holds (7 -> 7).
const RETURN_STATES := {3: 0, 4: 0, 5: 0, 6: 0, 7: 7, 8: 0}

# Order of directions by increasing screen angle (atan2(y, x) in [0, TAU)).
# Index 0 == angle 0 (RIGHT), stepping clockwise in 45-degree sectors.
const _DIR_BY_ANGLE: Array = [
	Direction.RIGHT, Direction.DOWN_RIGHT, Direction.DOWN, Direction.DOWN_LEFT,
	Direction.LEFT, Direction.UP_LEFT, Direction.UP, Direction.UP_RIGHT,
]

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted whenever the (state, direction) PAIR changes. Direction-only changes
## are reported too (the signal carries both values), so a sprite renderer can
## always stay in sync. A state change additionally implies frame was reset to
## 0 (read `frame` directly on this signal).
signal state_changed(state: int, direction: int)
## Emitted whenever `frame` changes value (tick advance / wrap).
signal frame_changed(frame: int)
## Emitted ONCE when a one-shot reaches its final frame and stops.
signal one_shot_finished(state: int)
## Phase-4: emitted by transition_to() on a real state change, carrying the
## state we left, the state we entered, and the (possibly updated) direction.
signal transitioned(from_state: int, to_state: int, direction: int)

# ---------------------------------------------------------------------------
# Public state (all plain data; safe to snapshot)
# ---------------------------------------------------------------------------

var state: int = State.IDLE
var direction: int = Direction.DOWN
var frame: int = 0
var speed_scale: float = 1.0
var playing: bool = true
var elapsed: float = 0.0
## Phase-4: the state we were in before the last transition_to() call.
var previous_state: int = State.IDLE

# Internal: latches one-shot completion so one_shot_finished can never be
# emitted twice, even if external code fiddles with `playing`.
var _one_shot_done: bool = false

# ---------------------------------------------------------------------------
# Playback control
# ---------------------------------------------------------------------------

## Request a new animation state. Returns TRUE only if `state` actually
## changed. A lower-priority request is rejected (returns false, changes
## nothing) while a higher-priority unfinished one-shot is playing; use
## play_forced() to bypass priority. On an accepted state change the frame and
## elapsed time reset to 0 and playing becomes true. `p_speed_scale` scales the
## effective fps (STATE_FPS[state] * speed_scale). A negative new_direction
## means "keep the current direction".
func play(new_state: int, new_direction: int = -1, p_speed_scale: float = 1.0) -> bool:
	if _locked_by_priority(_clamp_state(new_state)):
		return false
	return _apply(new_state, new_direction, p_speed_scale)


## Force a state change, ignoring priority. Keeps the current speed_scale.
func play_forced(new_state: int, new_direction: int = -1) -> void:
	_apply(new_state, new_direction, speed_scale)


# ---------------------------------------------------------------------------
# Phase-4 additive transitions / CAST helpers (do NOT alter play()/tick()/
# play_forced()/snapshot()/from_snapshot() semantics for states 0-7).
# ---------------------------------------------------------------------------

## Request a transition, respecting priority exactly like play(), but also
## recording `previous_state` and emitting `transitioned` on a real state
## change. Returns TRUE iff the STATE changed. A negative direction keeps the
## current direction. Invalid states clamp exactly as play() does.
func transition_to(new_state: int, new_direction: int = -1) -> bool:
	var target := _clamp_state(new_state)
	if _locked_by_priority(target):
		return false
	previous_state = state
	var changed := _apply(new_state, new_direction, speed_scale)
	if changed:
		transitioned.emit(previous_state, state, direction)
	return changed


## PURE priority + validity rule (no instance state needed). Looping/locomotion
## sources never lock; a non-looping source cannot be interrupted by a strictly
## lower-priority state. Both states must be valid extended states.
static func can_transition(from: int, to: int) -> bool:
	if not is_valid_state(from) or not is_valid_state(to):
		return false
	if from in LOCOMOTION_STATES:
		return true
	return priority_for(to) >= priority_for(from)


## Force the state back to its RETURN_STATES target after a one-shot completes.
## DEFEAT holds (returns 7); CAST and the other one-shots return to IDLE.
func finish_and_return() -> int:
	var target := int(RETURN_STATES.get(state, State.IDLE))
	previous_state = state
	play_forced(target)
	return target


## Start the additive CAST one-shot (state 8). A negative direction keeps the
## current direction. Respects priority just like play(). Returns whether the
## state actually changed.
func play_cast(direction: int = -1) -> bool:
	return play(CAST_STATE, direction)


## TRUE while the animator is currently in the CAST state.
func cast_active() -> bool:
	return state == CAST_STATE


## Set the 8-way direction directly. Invalid values clamp to DOWN. Emits
## state_changed when the direction actually changes.
func set_direction(new_direction: int) -> void:
	var target := _clamp_direction(new_direction)
	if target != direction:
		direction = target
		state_changed.emit(state, direction)


## Map a movement vector to one of the 8 directions and set it. The zero vector
## keeps the current direction. Returns the resulting (chosen) direction.
## Mapping is deterministic: the vector angle is quantised into eight 45-degree
## sectors centred on the cardinal/diagonal directions; exact 22.5-degree ties
## resolve to the next (clockwise) sector.
func set_direction_from_vector(v: Vector2) -> int:
	if v.length_squared() <= 0.000001:
		return direction
	var a := v.angle()
	if a < 0.0:
		a += TAU
	var sector := int(round(a / (PI * 0.25))) % 8
	var chosen := int(_DIR_BY_ANGLE[sector])
	if chosen != direction:
		direction = chosen
		state_changed.emit(state, direction)
	return direction


## Advance the animation by `delta` seconds. Effective rate is
## STATE_FPS[state] * speed_scale (never <= 0; a non-positive/invalid value is
## treated as 1 fps). Returns TRUE (and emits frame_changed) iff `frame`
## changed. Looping states wrap; one-shots clamp at the last frame, set
## playing=false and emit one_shot_finished exactly once, then HOLD that frame.
func tick(delta: float) -> bool:
	if not playing:
		return false
	if not (delta > 0.0):
		return false
	var rate := fps() * speed_scale
	if not (rate > 0.0 and rate < 1000000.0):
		rate = 1.0
	var frame_duration := 1.0 / rate
	elapsed += delta
	var steps := 0
	while elapsed >= frame_duration and steps < 4096:
		elapsed -= frame_duration
		steps += 1
	if steps <= 0:
		return false
	var count := frame_count()
	var old_frame := frame
	var looping := is_looping()
	if looping:
		frame = (frame + steps) % count
	else:
		var last := count - 1
		frame = mini(frame + steps, last)
	var frame_did_change := frame != old_frame
	if frame_did_change:
		frame_changed.emit(frame)
	if not looping and frame >= count - 1 and not _one_shot_done:
		_one_shot_done = true
		playing = false
		one_shot_finished.emit(state)
	return frame_did_change


## TRUE once a one-shot has completed (reached and held its last frame).
## Looping states are never finished.
func is_finished() -> bool:
	return (not is_looping()) and _one_shot_done


## Whether the current state loops. Routed through looping_for() so the
## additive CAST state (8) is handled without touching the frozen 8-key dict.
## For states 0-7 the result is byte-for-byte identical to the old lookup.
func is_looping() -> bool:
	return looping_for(state)


## Number of frames for the current state (always >= 1).
func frame_count() -> int:
	return maxi(1, frame_count_for(state))


## Nominal playback rate (fps) for the current state, before speed_scale.
## Guarded: a non-positive / non-finite value is treated as 1.0.
func fps() -> float:
	var base := fps_for(state)
	if not (base > 0.0):
		return 1.0
	return base


## Silent hard reset to the initial IDLE / DOWN / frame 0 state. Does NOT emit
## signals; use play() when observers must be notified.
func reset() -> void:
	state = State.IDLE
	direction = Direction.DOWN
	frame = 0
	speed_scale = 1.0
	playing = true
	elapsed = 0.0
	_one_shot_done = false

# ---------------------------------------------------------------------------
# Static helpers / determinism
# ---------------------------------------------------------------------------

static func state_name(s: int) -> String:
	return str(EXTENDED_STATE_NAMES.get(s, "unknown"))


static func direction_name(d: int) -> String:
	return str(DIRECTION_NAMES.get(d, "unknown"))


# ---- Phase-4 additive helpers ---------------------------------------------
# Handle CAST (8) explicitly, then fall back to the frozen 8-key dicts. For
# states 0-7 these return EXACTLY what the old dict lookups returned, so every
# Phase-3 play()/tick()/snapshot() behaviour is preserved byte-for-byte.
static func frame_count_for(s: int) -> int:
	if s == CAST_STATE:
		return CAST_FRAMES
	return int(STATE_FRAMES.get(s, 1))


static func fps_for(s: int) -> float:
	if s == CAST_STATE:
		return CAST_FPS
	return float(STATE_FPS.get(s, 1.0))


static func looping_for(s: int) -> bool:
	if s == CAST_STATE:
		return CAST_LOOPING
	return bool(STATE_LOOPING.get(s, false))


static func priority_for(s: int) -> int:
	if s == CAST_STATE:
		return CAST_PRIORITY
	return int(STATE_PRIORITY.get(s, 0))


static func is_valid_state(s: int) -> bool:
	return EXTENDED_STATES.has(s)


static func is_valid_direction(d: int) -> bool:
	return ALL_DIRECTIONS.has(d)


## Serialise the complete deterministic state to a plain Dictionary.
func snapshot() -> Dictionary:
	return {
		"state": state,
		"direction": direction,
		"frame": frame,
		"speed_scale": speed_scale,
		"playing": playing,
		"elapsed": elapsed,
		"one_shot_done": _one_shot_done,
	}


## Reconstruct an animator from a snapshot (defensive: missing/invalid keys
## clamp to safe defaults). Does not re-emit signals.
static func from_snapshot(d: Dictionary) -> CharacterAnimator:
	var animator := CharacterAnimator.new()
	animator.state = _clamp_state(int(d.get("state", State.IDLE)))
	animator.direction = _clamp_direction(int(d.get("direction", Direction.DOWN)))
	animator.speed_scale = _safe_speed(float(d.get("speed_scale", 1.0)))
	animator.frame = clampi(int(d.get("frame", 0)), 0, animator.frame_count() - 1)
	animator.elapsed = maxf(0.0, float(d.get("elapsed", 0.0)))
	animator.playing = bool(d.get("playing", true))
	animator._one_shot_done = bool(d.get("one_shot_done", false))
	return animator

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

static func _clamp_state(s: int) -> int:
	if is_valid_state(s):
		return s
	return State.IDLE


static func _clamp_direction(d: int) -> int:
	if is_valid_direction(d):
		return d
	return Direction.DOWN


static func _safe_speed(p: float) -> float:
	if not (p > 0.0):
		return 0.0
	return minf(p, 1000.0)


## TRUE when the current state is an unfinished one-shot whose priority is
## higher than the requested state's priority (i.e. the request is blocked).
func _locked_by_priority(target_state: int) -> bool:
	if is_looping() or not playing or _one_shot_done:
		return false
	var current_priority := priority_for(state)
	var target_priority := priority_for(target_state)
	return target_priority < current_priority


## Apply a state/direction/speed change; emit state_changed on any change;
## return whether the STATE changed.
func _apply(new_state: int, new_direction: int, p_speed_scale: float) -> bool:
	speed_scale = _safe_speed(p_speed_scale)
	var target_state := _clamp_state(new_state)
	var target_direction := direction
	if new_direction >= 0:
		target_direction = _clamp_direction(new_direction)
	var state_did_change := target_state != state
	if state_did_change:
		state = target_state
		frame = 0
		elapsed = 0.0
		playing = true
		_one_shot_done = false
	var direction_did_change := target_direction != direction
	if direction_did_change:
		direction = target_direction
	if state_did_change or direction_did_change:
		state_changed.emit(state, direction)
	return state_did_change
