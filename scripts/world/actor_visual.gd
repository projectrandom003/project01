class_name ActorVisual
extends Node2D
## TEMPORARY procedural placeholder renderer; real sprites plug in via
## set_frame_source().
##
## Every actor is drawn from primitives with a palette supplied by data. This
## keeps the world readable and consistent before final sprite sheets exist. Real
## art replaces this node without touching movement, AI or combat.
##
## Phase 3 / Step 4 — EXTENSIBLE ANIMATION ARCHITECTURE:
##  * A pure CharacterAnimator drives 8 states x 8 directions; `_process` ticks
##    it and, on frame change, either swaps the child Sprite2D's texture OR
##    _queue_visual_redraw()s the procedural fallback.
##  * `frame_source` (default: ProceduralActorFrames) is the SEAM for final
##    painted sprites. `set_frame_source()` with a frame-backed source switches
##    rendering to the child Sprite2D; a source with no frames / a null frame()
##    result falls back GRACEFULLY to `_draw()` (never crashes headless).
##  * Backward compatibility: `walking` and `facing` remain public and are
##    reconciled into the animator each `_process`, so existing callers keep
##    working. `anim_time` keeps advancing.
##  * All art here is procedural placeholder; there are no final assets.

enum Kind { HUMAN, MONSTER, SPIRIT }

# State ids mirror CharacterAnimator.State (authoritative contract), kept as
# plain int constants to avoid any dependency on cross-class enum lookup.
const S_IDLE := 0
const S_WALK := 1
const S_RUN := 2
const S_INTERACT := 3
const S_ATTACK := 4
const S_DAMAGE := 5
const S_VICTORY := 6
const S_DEFEAT := 7
const S_CAST := 8  # Phase-4 additive CAST state (CharacterAnimator.CAST_STATE)

# ------------------------------------------------------------------ public vars
var kind: Kind = Kind.HUMAN
var palette: Dictionary = {}
var def_id: String = ""
## PART 4: character id wired through the SpriteFrames registration path
## (set ONLY by configure_character; "" for the player demo / procedural actors).
var character_id: String = ""
var element: String = "neutral"
var race: String = "Human"
var visual_scale: float = 1.0
var facing: float = 1.0
var walking: bool = false
var is_boss: bool = false
var anim_time: float = 0.0
var hit_flash: float = 0.0

# ------------------------------------------------------ animation architecture
var animator: CharacterAnimator
var frame_source: ActorFrameSource
var using_temporary_art: bool = true
signal animation_finished(state: int)

var _sprite: Sprite2D
var procedural_renderer: ActorProceduralRendererComponent
var character_effects_component: ActorCharacterEffectsComponent
var pose_component: ActorPoseComponent
var sprite_component: ActorSpriteComponent
var animation_component: CharacterAnimationComponent
var _sprite_active: bool = false
var _last_sprite_key: int = -1
var _custom_source: bool = false
var _last_walking: bool = false
var _last_facing: float = 1.0
var _base_visual_scale: float = 1.0
var _turn_pose_remaining: float = 0.0
var _turn_pose_sign: float = 1.0
var _last_pose_direction: int = CharacterAnimator.Direction.DOWN
const TURN_POSE_DURATION := 0.14
const FALLEN_MATRON_WORLD_TEXTURE: Texture2D = preload("res://assets/enemies/fallen_matron/phase_1.png")

# Direction-derived view flags (recomputed in _compute_view each draw).
var _view_moving: bool = false
var _view_back: bool = false
var _view_diag: bool = false
var _view_profile: bool = false
var _view_face: float = 1.0

var _skin: Color
var _primary: Color
var _secondary: Color
var _hair: Color
var _accent: Color


# ------------------------------------------------------------------ lifecycle

func setup(p_palette: Dictionary, p_kind: Kind = Kind.HUMAN, p_def_id: String = "", p_race: String = "Human", p_element: String = "neutral") -> void:
	palette = p_palette
	kind = p_kind
	def_id = p_def_id
	race = p_race
	element = p_element
	_refresh_colors()
	_init_animator()
	if not _custom_source:
		frame_source = ProceduralActorFrames.new(palette, is_boss)
	using_temporary_art = frame_source.is_temporary() if frame_source != null else true
	_queue_visual_redraw()


func _ready() -> void:
	_refresh_colors()
	_init_animator()
	animation_component = get_node_or_null("CharacterAnimationComponent") as CharacterAnimationComponent
	procedural_renderer = get_node_or_null("ProceduralRenderer") as ActorProceduralRendererComponent
	character_effects_component = get_node_or_null("CharacterEffects") as ActorCharacterEffectsComponent
	pose_component = get_node_or_null("Pose") as ActorPoseComponent
	sprite_component = get_node_or_null("SpritePresentation") as ActorSpriteComponent
	if animation_component == null or procedural_renderer == null or character_effects_component == null or pose_component == null or sprite_component == null:
		push_error("ActorVisual requires its authored CharacterAnimationComponent, ProceduralRenderer, Pose and SpritePresentation children.")
		return
	procedural_renderer.bind(self)
	character_effects_component.bind(self)
	pose_component.bind(self)
	sprite_component.bind(self)
	if frame_source == null:
		frame_source = ProceduralActorFrames.new(palette, is_boss)
	using_temporary_art = frame_source.is_temporary() if frame_source != null else true
	procedural_renderer.queue_redraw()
	_ensure_sprite()
	if _sprite_active:
		_update_sprite_frame()
	else:
		_hide_sprite()
	_queue_visual_redraw()

func _ensure_sprite_component() -> void:
	if sprite_component == null:
		sprite_component = get_node_or_null("SpritePresentation") as ActorSpriteComponent
	if sprite_component == null:
		push_error("ActorVisual requires its authored SpritePresentation child.")
		return
	sprite_component.bind(self)

func _exit_tree() -> void:
	# Release the frame-backed source while the RenderingServer is still alive.
	# For the Phase-4 demonstration character this is a SpriteFramesActorSource
	# holding an in-memory SpriteFrames of ~432 cached ImageTextures; setting the
	# reference to null here lets that whole RefCounted resource graph free its
	# texture RIDs during SceneTree teardown instead of surviving to the dummy
	# renderer's shutdown (which reports "leaked RID allocations at exit").
	# ProceduralActorFrames (the procedural fallback) is equally safe to drop:
	# _ready() recreates it if the node ever re-enters the tree.
	frame_source = null
	_sprite_active = false


func _refresh_colors() -> void:
	_skin = _as_color(palette.get("skin", "#f3d7c0"), Color("#f3d7c0"))
	_primary = _as_color(palette.get("primary", "#3f5a6b"), Color("#3f5a6b"))
	_secondary = _as_color(palette.get("secondary", "#c9a45a"), Color("#c9a45a"))
	_hair = _as_color(palette.get("hair", "#4a3020"), Color("#4a3020"))
	_accent = _as_color(palette.get("accent", "#7fe3e0"), GreenwardStyle.MAGIC.teal)


static func _as_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	if value is String:
		var text: String = value
		if text.begins_with("#"):
			return Color(text)
	return fallback


func _init_animator() -> void:
	if animator != null:
		return
	animator = CharacterAnimator.new()
	animator.state_changed.connect(_on_animator_state_changed)
	animator.one_shot_finished.connect(_on_one_shot_finished)


# ------------------------------------------------------- frame-source SEAM

## Register a frame source. A source with has_frames()==true renders via the
## child Sprite2D; otherwise (or on a null frame) we KEEP the procedural
## `_draw()` fallback. This is the seam where final painted sprites plug in.
func set_frame_source(source: ActorFrameSource) -> void:
	_ensure_sprite_component()
	if sprite_component != null:
		sprite_component.set_frame_source(source)

func configure_character(character_id: String) -> Dictionary:
	_ensure_sprite_component()
	return sprite_component.configure_character(character_id) if sprite_component != null else {"character_id": character_id, "registered": false, "fallback_active": true}

func character_art_report() -> Dictionary:
	_ensure_sprite_component()
	return sprite_component.character_art_report() if sprite_component != null else {}

func _ensure_sprite() -> void:
	_ensure_sprite_component()
	if sprite_component != null:
		sprite_component.ensure_sprite()

func _hide_sprite() -> void:
	_ensure_sprite_component()
	if sprite_component != null:
		sprite_component.hide_sprite()

func _mirrors_by_facing() -> bool:
	_ensure_sprite_component()
	return sprite_component.mirrors_by_facing() if sprite_component != null else true

func set_body_scale(value: float) -> void:
	_ensure_sprite_component()
	if sprite_component != null:
		sprite_component.set_body_scale(value)

func _apply_effects_geometry() -> void:
	var effects := get_node_or_null("Effects") as Node2D
	if effects != null:
		effects.scale = Vector2.ONE * visual_scale


func _apply_sprite_geometry() -> void:
	_ensure_sprite_component()
	if sprite_component != null:
		sprite_component.apply_sprite_geometry()

func _update_sprite_frame() -> void:
	_ensure_sprite_component()
	if sprite_component != null:
		sprite_component.update_sprite_frame()

func play(state: int, direction: int = -1, speed_scale: float = 1.0) -> void:
	if animator != null:
		animator.play(state, direction, speed_scale)
	_update_locomotion_animation(state, speed_scale)
	if not _sprite_active:
		_queue_visual_redraw()


## The authored AnimationPlayer handles secondary body motion; CharacterAnimator
## remains the source of truth for directional sprite frames and one-shots.
func _update_locomotion_animation(state: int, speed_scale: float = 1.0) -> void:
	if animation_component == null:
		return
	var locomotion_state: StringName = &"idle"
	if state == S_WALK:
		locomotion_state = &"walk"
	elif state == S_RUN:
		locomotion_state = &"run"
	animation_component.play_locomotion(locomotion_state, speed_scale)


func set_move_direction(v: Vector2) -> void:
	if animator != null:
		animator.set_direction_from_vector(v)
	if not _sprite_active:
		_queue_visual_redraw()


func hit() -> void:
	hit_flash = 1.0
	if animator != null:
		animator.play_forced(S_DAMAGE)
	_queue_visual_redraw()


func play_interact() -> void:
	_play_state(S_INTERACT)


func play_attack(variant: String = "slash_combo") -> void:
	_set_gerald_attack_variant(variant)
	_play_state(S_ATTACK)


func play_victory() -> void:
	_play_state(S_VICTORY)


func play_defeat() -> void:
	_play_state(S_DEFEAT)


## Select one of Gerald's authored skill effects and start the shared CAST one-shot.
## Existing no-argument callers retain the ground-eruption default.
func play_cast(skill_variant: String = "ground_eruption") -> void:
	_set_gerald_skill_variant(skill_variant)
	if animator != null:
		animator.play_cast()
	_queue_visual_redraw()


func play_skill(skill_id: String) -> void:
	var variant := "ground_eruption"
	match skill_id.to_lower():
		"blade_wave":
			variant = "blade_wave"
		"guardian_aura":
			variant = "guardian_aura"
		"ground_eruption":
			variant = "ground_eruption"
	play_cast(variant)


func _set_gerald_attack_variant(variant: String) -> void:
	if character_id != "gerald":
		return
	var fx := get_node_or_null("Effects/GeraldCombatFX")
	if fx != null and fx.has_method("set_attack_variant"):
		fx.call("set_attack_variant", variant)


func _set_gerald_skill_variant(variant: String) -> void:
	if character_id != "gerald":
		return
	var fx := get_node_or_null("Effects/GeraldCombatFX")
	if fx != null and fx.has_method("set_skill_variant"):
		fx.call("set_skill_variant", variant)


func _play_state(s: int) -> void:
	if animator != null:
		animator.play(s)
	_queue_visual_redraw()


func _on_animator_state_changed(_state: int, _direction: int) -> void:
	if animator != null and _direction != _last_pose_direction:
		var direction_step := wrapi(_direction - _last_pose_direction, -4, 4)
		_turn_pose_sign = -1.0 if direction_step < 0 else 1.0
		_turn_pose_remaining = TURN_POSE_DURATION
		_last_pose_direction = _direction
	if _sprite_active:
		_update_sprite_frame()
	_queue_visual_redraw()


func _on_one_shot_finished(state: int) -> void:
	animation_finished.emit(state)
	# DEFEAT holds its last frame (non-looping death pose).
	if state == S_DEFEAT:
		return
	# Return to locomotion/idle once a one-shot completes, unless a listener of
	# animation_finished already chose a different state.
	if animator != null and animator.state == state and animator.is_finished():
		var target := S_WALK if walking else S_IDLE
		animator.play_forced(target)
	_queue_visual_redraw()


# ------------------------------------------------------------------ process

func _process(delta: float) -> void:
	# anim_time keeps advancing (existing _draw() uses it for smooth bob).
	anim_time += delta
	hit_flash = maxf(0.0, hit_flash - delta * 3.0)
	if animator == null:
		return
	_reconcile_compat()
	animator.tick(delta)
	if _sprite_active:
		_update_sprite_frame()
		_update_locomotion_pose(delta)
		# A frame-backed sprite does not need the procedural _draw() pass every
		# rendered frame. Redraw only for a changed frame, cast aura or hit flash.
		if (character_id == "kael") or (character_id == "lilith") or (animator.state == S_CAST) or hit_flash > 0.0:
			_queue_visual_redraw()
			if character_effects_component != null:
				character_effects_component.queue_redraw()
	else:
		# Procedural fallback uses anim_time for its limbs, bob and effects.
		_queue_visual_redraw()
		if character_effects_component != null:
			character_effects_component.queue_redraw()


## Adds continuous in-between body motion between the authored sprite frames.
## Grounded heroes get contact/recovery bounce and stride sway; Lilith floats
## with a weightless hover rather than pretending to plant feet.
func _update_locomotion_pose(delta: float) -> void:
	if pose_component != null:
		pose_component.update_locomotion_pose(delta)

func _reconcile_compat() -> void:
	if pose_component != null:
		pose_component.reconcile_compat()

func _queue_visual_redraw() -> void:
	if procedural_renderer != null and is_instance_valid(procedural_renderer):
		procedural_renderer.queue_redraw()
	else:
		queue_redraw()


func _draw() -> void:
	if procedural_renderer != null and is_instance_valid(procedural_renderer):
		procedural_renderer.queue_redraw()