class_name AnimatedProp
extends Node2D
## Cheap, data-driven animated prop wrapper (Phase 3 placeholder art).
##
## Wraps ONE Sprite2D built from ProceduralArt.prop_texture(kind, variant) and
## applies a tiny procedural motion (bob / sway / pulse / flicker / drift) in
## _process. Designed to be CHEAP and headless-safe:
##  * no per-frame allocations — all state is scalars / built-in value types;
##  * no new nodes after setup() (one Sprite2D child, created once);
##  * set_active() gates BOTH visibility and processing for off-screen use;
##  * amplitudes/frequencies are small and deterministic (phase from kind+variant
##    +position hash, no global RNG), and the world caps how many are spawned.
##
## All art is procedural placeholder; there are no final assets.

# Motion ids (plain int constants so callers never depend on enum lookup).
const MOTION_NONE := 0
const MOTION_BOB := 1
const MOTION_SWAY := 2
const MOTION_PULSE := 3
const MOTION_FLICKER := 4
const MOTION_DRIFT := 5

const MOTION_NAMES: Dictionary = {
	MOTION_NONE: "none",
	MOTION_BOB: "bob",
	MOTION_SWAY: "sway",
	MOTION_PULSE: "pulse",
	MOTION_FLICKER: "flicker",
	MOTION_DRIFT: "drift",
}

var kind: String = ""
var variant: int = 0
var animated: bool = true
var motion: int = MOTION_BOB
var amplitude: float = 3.0
var frequency: float = 1.3
var phase: float = 0.0
var base_scale: float = 1.0
var drift_extent: Vector2 = Vector2(22.0, 9.0)

var _sprite: Sprite2D
var _time: float = 0.0
var _base_modulate: Color = Color.WHITE
var _active: bool = true


## Build the prop. `motion` is one of the MOTION_* constants. `p_position` is a
## world-space position (the node's position). Called before or after add_child()
## — both are safe.
func setup(p_kind: String, p_position: Vector2, p_scale: float, p_flip: bool, p_motion: int, p_variant: int = 0) -> void:
	kind = p_kind
	variant = p_variant
	motion = clampi(p_motion, MOTION_NONE, MOTION_DRIFT)
	base_scale = maxf(0.05, p_scale)
	position = p_position
	phase = fmod(float(absi(("%s|%d|%s" % [p_kind, p_variant, str(p_position)]).hash())) * 0.0001, TAU)
	_apply_motion_defaults()
	_build_sprite(p_flip)
	animated = (motion != MOTION_NONE)
	_active = true
	set_process(animated)


func _apply_motion_defaults() -> void:
	match motion:
		MOTION_BOB:
			amplitude = 3.0
			frequency = 1.2
		MOTION_SWAY:
			amplitude = 4.0
			frequency = 1.0
		MOTION_PULSE:
			amplitude = 0.06
			frequency = 2.0
		MOTION_FLICKER:
			amplitude = 0.28
			frequency = 6.0
		MOTION_DRIFT:
			amplitude = 1.0
			frequency = 0.8
		_:
			amplitude = 0.0
			frequency = 0.0


func _build_sprite(p_flip: bool) -> void:
	if _sprite != null:
		return
	var tex := ProceduralArt.prop_texture(kind, variant)
	if tex == null:
		tex = ProceduralArt.white_pixel()
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = tex
	_sprite.centered = false
	_sprite.offset = Vector2(-float(tex.get_width()) * 0.5, -float(tex.get_height()) + 6.0)
	_sprite.scale = Vector2.ONE * base_scale
	_sprite.flip_h = p_flip
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)
	_base_modulate = _sprite.modulate


func _ready() -> void:
	# Defensive: a bare AnimatedProp.new() added without setup() still renders.
	if _sprite == null:
		_apply_motion_defaults()
		_build_sprite(false)
	set_process(_active and animated)


func _process(delta: float) -> void:
	if not animated or _sprite == null or not _active:
		return
	_time += delta
	var t := _time * frequency + phase
	# Reset the (value-type) properties each frame so motions never accumulate.
	_sprite.position = Vector2.ZERO
	_sprite.rotation = 0.0
	_sprite.scale = Vector2.ONE * base_scale
	_sprite.modulate = _base_modulate
	match motion:
		MOTION_BOB:
			_sprite.position = Vector2(0.0, sin(t) * amplitude)
		MOTION_SWAY:
			_sprite.position = Vector2(sin(t) * amplitude, 0.0)
			_sprite.rotation = sin(t) * 0.05
		MOTION_PULSE:
			_sprite.scale = Vector2.ONE * base_scale * (1.0 + sin(t) * amplitude)
		MOTION_FLICKER:
			var m := _sprite.modulate
			m.a = clampf(0.72 + sin(t) * amplitude, 0.0, 1.0)
			_sprite.modulate = m
		MOTION_DRIFT:
			_sprite.position = Vector2(sin(t) * drift_extent.x, cos(t * 0.7) * drift_extent.y)
			_sprite.flip_h = sin(t) < 0.0


## Toggle the cheap motion on/off. Does not hide the prop.
func set_animated(enabled: bool) -> void:
	animated = enabled and motion != MOTION_NONE
	set_process(_active and animated)


## Visibility + process gating for off-screen use (cheap distance toggle).
func set_active(active: bool) -> void:
	if active == _active:
		return
	_active = active
	visible = active
	set_process(active and animated)


static func motion_name(m: int) -> String:
	return str(MOTION_NAMES.get(m, "none"))
