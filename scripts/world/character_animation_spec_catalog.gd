class_name CharacterAnimationSpecCatalog
extends RefCounted
## Frozen integer-keyed animation timing, priority, naming and direction lookup data.
## CharacterAnimator owns transitions, playback state and frame progression.

# Phase-3 core states, FROZEN for compatibility. The 550 headless tests and the
# GreenwardStyle.SPRITE_SPECS timing arrays assert exactly these 8 values in
# this order. Phase-4 CAST is an ADDITIVE 9th state exposed only via the
# EXTENDED_* constants and *_for() helpers below -- do NOT add 8 here.
const ALL_STATES: Array = [
	0, 1, 2, 3,
	4, 5, 6, 7,
]

const ALL_DIRECTIONS: Array = [
	0, 1, 2, 3,
	4, 5, 6, 7,
]

const STATE_NAMES: Dictionary = {
	0: "idle",
	1: "walk",
	2: "run",
	3: "interact",
	4: "attack",
	5: "damage",
	6: "victory",
	7: "defeat",
}

const DIRECTION_NAMES: Dictionary = {
	0: "down",
	1: "down_right",
	2: "right",
	3: "up_right",
	4: "up",
	5: "up_left",
	6: "left",
	7: "down_left",
}

# Playback timing. Targets come from documentation/ART_PIPELINE.md section 3:
#   Idle     4-6 frames @ 8-10 fps
#   Walk/Run 6-8 frames @ 12 / 14 fps
#   Attack   5-8 frames @ 15 fps, Cast 6-8 @ 12 fps, Hurt 2 @ 12 fps,
#   Death    5-8 frames, non-looping.
# The five non-movement states are ONE-SHOTS. The counts/fps below are the
# single source of truth shared with ActorFrameSource and the sprite sheets.
const STATE_FPS: Dictionary = {
	0: 9.0,
	1: 12.0,
	2: 16.0,
	3: 12.0,
	4: 15.0,
	5: 12.0,
	6: 12.0,
	7: 10.0,
}

const STATE_FRAMES: Dictionary = {
	0: 5,
	1: 16,
	2: 16,
	3: 6,
	4: 6,
	5: 2,
	6: 8,
	7: 6,
}

# Looping states wrap forever; the other five are one-shots that clamp on the
# last frame, stop, and emit one_shot_finished exactly once.
const STATE_LOOPING: Dictionary = {
	0: true,
	1: true,
	2: true,
	3: false,
	4: false,
	5: false,
	6: false,
	7: false,
}

# Higher number == higher priority. Required order:
#   DEFEAT > VICTORY > DAMAGE > ATTACK > INTERACT > RUN > WALK > IDLE
# A lower-priority play() cannot interrupt a higher-priority UNFINISHED
# one-shot. Looping states never lock, so movement stays responsive.
const STATE_PRIORITY: Dictionary = {
	7: 8,
	6: 7,
	5: 6,
	4: 5,
	3: 4,
	2: 3,
	1: 2,
	0: 1,
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
	2, 1, 0, 7,
	6, 5, 4, 3,
]

