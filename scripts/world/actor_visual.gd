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
##    queue_redraw()s the procedural fallback.
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
	queue_redraw()


func _ready() -> void:
	_refresh_colors()
	_init_animator()
	if frame_source == null:
		frame_source = ProceduralActorFrames.new(palette, is_boss)
	using_temporary_art = frame_source.is_temporary() if frame_source != null else true
	_ensure_sprite()
	if _sprite_active:
		_update_sprite_frame()
	else:
		_hide_sprite()
	queue_redraw()


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
	if source == null:
		_custom_source = false
		frame_source = ProceduralActorFrames.new(palette, is_boss)
		using_temporary_art = true
		_sprite_active = false
		_hide_sprite()
		queue_redraw()
		return
	_custom_source = true
	frame_source = source
	using_temporary_art = source.is_temporary()
	_last_sprite_key = -1
	_sprite_active = source.has_frames()
	if _sprite_active:
		_ensure_sprite()
		_update_sprite_frame()
	else:
		_hide_sprite()
		queue_redraw()


# --------------------------------------- PART 4: sprite-sheet integration
# ADDITIVE. No disk sheets exist yet, so configure_character() leaves the
# existing ProceduralActorFrames fallback untouched for every world actor.

## Exercise the SpriteFramesActorSource registration seam for a character id.
## ONLY swaps the frame source when a real, fully validated sheet was loaded;
## otherwise the current ProceduralActorFrames fallback is left in place (the
## `using_temporary_art` computation is unchanged). Returns a status report.
func configure_character(character_id: String) -> Dictionary:
	self.character_id = character_id
	# register_playable() prefers a character's FINAL playable art (its own
	# registered art folder) and falls back to the collectible registry.
	var source: ActorFrameSource = SpriteFramesActorSource.register_playable(character_id)
	var registered := false
	if source != null and source.has_frames() and source.validate_sheets().is_empty():
		set_frame_source(source)
		registered = true
	return {
		"character_id": character_id,
		"registered": registered,
		"fallback_active": not registered,
		"using_temporary_art": using_temporary_art,
		"source": frame_source.source_label() if frame_source != null else "",
	}


## Machine-readable snapshot of this visual's character-art integration state.
func character_art_report() -> Dictionary:
	var fs: ActorFrameSource = frame_source
	var has_frames := false
	var is_temporary := true
	var animation_count := 0
	var frame_source_label := ""
	if fs != null:
		has_frames = fs.has_frames()
		is_temporary = fs.is_temporary()
		frame_source_label = fs.source_label()
		if fs.has_method("load_report"):
			var rep: Variant = fs.call("load_report")
			if rep is Dictionary:
				animation_count = int((rep as Dictionary).get("animation_count", 0))
	return {
		"character_id": character_id,
		"frame_source": frame_source_label,
		"using_temporary_art": using_temporary_art,
		"has_frames": has_frames,
		"is_temporary": is_temporary,
		"animation_count": animation_count,
	}


func _ensure_sprite() -> void:
	if _sprite != null or not is_inside_tree():
		return
	_sprite = Sprite2D.new()
	_sprite.name = "FrameSprite"
	_sprite.centered = false
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.visible = false
	add_child(_sprite)


func _hide_sprite() -> void:
	if _sprite != null:
		_sprite.visible = false
	_last_sprite_key = -1


## Production 8-direction sheets must not be mirrored from `facing`; the
## procedural fallback and any single-silhouette source still are.
func _mirrors_by_facing() -> bool:
	return frame_source == null or frame_source.mirrors_by_facing()


## Set a character's world-height scale while keeping the feet / hover baseline anchored.
func set_body_scale(value: float) -> void:
	_base_visual_scale = clampf(value, 0.45, 1.5)
	visual_scale = _base_visual_scale
	if _sprite != null and _sprite.texture != null:
		_apply_sprite_geometry()


func _apply_sprite_geometry() -> void:
	if _sprite == null or _sprite.texture == null:
		return
	var tex := _sprite.texture
	var anchor_v: Variant = GreenwardStyle.SPRITE_SPECS.get("anchor", Vector2(0.5, 1.0))
	var anchor: Vector2 = anchor_v if anchor_v is Vector2 else Vector2(0.5, 1.0)
	_sprite.centered = false
	# bottom-centre offset matching SPRITE_SPECS.anchor
	_sprite.offset = Vector2(-float(tex.get_width()) * anchor.x, -float(tex.get_height()) * anchor.y)
	_sprite.scale = Vector2.ONE * visual_scale
	_sprite.flip_h = facing < 0.0 and _mirrors_by_facing()


func _update_sprite_frame() -> void:
	if _sprite == null or frame_source == null or not _sprite_active:
		return
	var key := (animator.state << 16) | (animator.direction << 8) | animator.frame
	if key == _last_sprite_key and _sprite.visible:
		return
	var tex: Texture2D
	if animator.state == CharacterAnimator.CAST_STATE:
		# Phase-4: state 8 works via frame_source. Exercise the additive CAST
		# frame API, with a graceful fallback to frame(8, ...) for sources that
		# do not override cast_frame() (base class returns null).
		tex = frame_source.cast_frame(animator.direction, animator.frame)
		if tex == null:
			tex = frame_source.frame(animator.state, animator.direction, animator.frame)
	else:
		tex = frame_source.frame(animator.state, animator.direction, animator.frame)
	if tex == null:
		# Graceful fallback: never crash when no frame is available.
		_sprite_active = false
		_hide_sprite()
		queue_redraw()
		return
	_last_sprite_key = key
	_sprite.texture = tex
	_apply_sprite_geometry()
	_sprite.visible = true
	queue_redraw()


# --------------------------------------------------------------- public API

func play(state: int, direction: int = -1, speed_scale: float = 1.0) -> void:
	if animator != null:
		animator.play(state, direction, speed_scale)
	if not _sprite_active:
		queue_redraw()


func set_move_direction(v: Vector2) -> void:
	if animator != null:
		animator.set_direction_from_vector(v)
	if not _sprite_active:
		queue_redraw()


func hit() -> void:
	hit_flash = 1.0
	if animator != null:
		animator.play_forced(S_DAMAGE)
	queue_redraw()


func play_interact() -> void:
	_play_state(S_INTERACT)


func play_attack() -> void:
	_play_state(S_ATTACK)


func play_victory() -> void:
	_play_state(S_VICTORY)


func play_defeat() -> void:
	_play_state(S_DEFEAT)


## Phase-2: start the additive CAST one-shot (state 8) on the animator.
func play_cast() -> void:
	if animator != null:
		animator.play_cast()
	queue_redraw()


func _play_state(s: int) -> void:
	if animator != null:
		animator.play(s)
	queue_redraw()


func _on_animator_state_changed(_state: int, _direction: int) -> void:
	if animator != null and _direction != _last_pose_direction:
		var direction_step := wrapi(_direction - _last_pose_direction, -4, 4)
		_turn_pose_sign = -1.0 if direction_step < 0 else 1.0
		_turn_pose_remaining = TURN_POSE_DURATION
		_last_pose_direction = _direction
	if _sprite_active:
		_update_sprite_frame()
	queue_redraw()


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
	queue_redraw()


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
		if (character_id == "kael") or (animator.state == S_CAST) or hit_flash > 0.0:
			queue_redraw()
	else:
		# Procedural fallback uses anim_time for its limbs, bob and effects.
		queue_redraw()


## Adds continuous in-between body motion between the authored sprite frames.
## Grounded heroes get contact/recovery bounce and stride sway; Lilith floats
## with a weightless hover rather than pretending to plant feet.
func _update_locomotion_pose(delta: float) -> void:
	if _sprite == null or not _sprite_active or _sprite.texture == null or animator == null:
		return
	var state := animator.state
	var locomotion := state == S_WALK or state == S_RUN
	var idle := state == S_IDLE
	if not locomotion and not idle:
		# Kael's authored action poses get a little secondary body animation:
		# weight shifts into the sword strike, a recoil on impact, and a lifted
		# chest during the cast. Keep it restrained so the hand-drawn frames lead.
		if character_id == "kael":
			var action_count := float(maxi(1, animator.frame_count()))
			var action_t := clampf((float(animator.frame) + animator.elapsed * animator.fps() * animator.speed_scale) / action_count, 0.0, 1.0)
			_sprite.position = Vector2.ZERO
			_sprite.rotation = 0.0
			_sprite.scale = Vector2.ONE * _base_visual_scale
			match state:
				S_ATTACK:
					var windup := smoothstep(0.0, 0.30, action_t) * (1.0 - smoothstep(0.72, 1.0, action_t))
					var impact := smoothstep(0.34, 0.48, action_t) * (1.0 - smoothstep(0.52, 0.68, action_t))
					_sprite.position = Vector2(-2.2 * windup + 1.4 * impact, -1.0 * windup)
					_sprite.rotation = deg_to_rad(-5.0 * windup + 2.0 * impact)
					_sprite.scale = Vector2(_base_visual_scale * (1.0 + 0.025 * impact), _base_visual_scale * (1.0 - 0.025 * impact))
				S_CAST:
					var gather := sin(PI * action_t)
					_sprite.position = Vector2(sin(anim_time * 7.0) * 0.7, -2.2 * gather)
					_sprite.rotation = sin(anim_time * 3.0) * 0.012
					_sprite.scale = Vector2(_base_visual_scale * (1.0 - 0.018 * gather), _base_visual_scale * (1.0 + 0.025 * gather))
				S_DAMAGE:
					var recoil := 1.0 - action_t
					_sprite.position = Vector2(2.0 * recoil, -0.8 * recoil)
					_sprite.rotation = deg_to_rad(3.0 * recoil)
				S_VICTORY:
					var rise := sin(PI * action_t)
					_sprite.position = Vector2(0.0, -2.0 * rise)
					_sprite.rotation = sin(action_t * PI * 2.0) * 0.018
				_:
					_sprite.position = Vector2.ZERO
					_sprite.rotation = 0.0
			return
		_sprite.position = Vector2.ZERO
		_sprite.rotation = 0.0
		_sprite.scale = Vector2.ONE * _base_visual_scale
		return
	var phase := 0.0
	if locomotion:
		var count := float(maxi(1, animator.frame_count()))
		var frame_progress := (float(animator.frame) + animator.elapsed * animator.fps() * animator.speed_scale) / count
		phase = frame_progress * TAU
	var bob := 0.0
	var sway := 0.0
	var squash := 0.0
	if character_id == "lilith" or race == "Spirit":
		# Lilith's lower silhouette is spectral flame, not feet: keep her hovering.
		bob = sin(anim_time * (3.0 if locomotion else 1.8)) * (2.5 if locomotion else 1.8)
		sway = sin(anim_time * 1.65) * 0.8
		_sprite.rotation = sin(anim_time * 1.25) * 0.018
	else:
		var cadence := 2.0 if locomotion else 1.0
		var contact := pow(maxf(0.0, cos(phase * cadence)), 8.0) if locomotion else 0.0
		var lift := absf(sin(phase * cadence)) if locomotion else 0.0
		if character_id == "gerald":
			# Heavy guardian: compact rise, deliberate landing and slight coat sway.
			bob = -1.45 * lift
			sway = sin(phase) * 0.65 if locomotion else sin(anim_time * 1.1) * 0.25
			squash = 0.028 * contact
		elif character_id == "kael":
			# Kael: quick, light footwork with a more expressive idle breath.
			bob = -2.45 * lift if locomotion else sin(anim_time * 2.15) * 0.78
			sway = sin(phase) * (1.2 if state == S_RUN else 0.88) if locomotion else sin(anim_time * 1.35) * 0.34
			squash = (0.042 if state == S_RUN else 0.032) * contact
			_sprite.rotation = sin(anim_time * 1.1) * 0.006 if idle else 0.0
		else:
			# Other grounded characters keep the restrained default motion.
			bob = -2.15 * lift
			sway = sin(phase) * 1.05 if locomotion else sin(anim_time * 1.5) * 0.3
			squash = 0.035 * contact
			_sprite.rotation = 0.0
	var scale_x := _base_visual_scale * (1.0 + squash * 0.55)
	var scale_y := _base_visual_scale * (1.0 - squash)
	_sprite.position = Vector2(sway, bob)
	_sprite.scale = Vector2(scale_x, scale_y)
	if _turn_pose_remaining > 0.0:
		_turn_pose_remaining = maxf(0.0, _turn_pose_remaining - delta)
		var turn_weight := sin(PI * (1.0 - _turn_pose_remaining / TURN_POSE_DURATION))
		_sprite.rotation += deg_to_rad(3.0) * _turn_pose_sign * turn_weight



## Backward compatibility: external writes to `walking` / `facing` are folded
## into the animator here (rather than removing the vars). Only reacts on change
## edges and only touches pure locomotion states, so one-shots are never cut.
func _reconcile_compat() -> void:
	if walking != _last_walking:
		_last_walking = walking
		if walking:
			if animator.state == S_IDLE and animator.is_looping():
				animator.play(S_WALK)
		elif animator.state == S_WALK or animator.state == S_RUN:
			animator.play(S_IDLE)
	if facing != _last_facing:
		_last_facing = facing
		if _sprite != null and _sprite_active:
			_sprite.flip_h = facing < 0.0 and _mirrors_by_facing()


# ------------------------------------------------------------------ drawing

func _compute_view() -> void:
	if animator == null:
		_view_moving = walking
		_view_back = false
		_view_diag = false
		_view_profile = false
		_view_face = 1.0
		return
	var st := animator.state
	_view_moving = (st == S_WALK or st == S_RUN)
	var d := animator.direction
	_view_back = d in [3, 4, 5]        # UP / UP_LEFT / UP_RIGHT -> back of head
	_view_diag = d in [1, 3, 5, 7]    # 3/4 view
	_view_profile = (d == 2 or d == 6)  # pure LEFT / RIGHT profile
	_view_face = -1.0 if d in [5, 6, 7] else 1.0


func _draw() -> void:
	# Frame-source path: the child Sprite2D renders the figure (and its baked
	# shadow). We only draw the hit-flash overlay here.
	if _sprite_active:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if animator != null and animator.state == CharacterAnimator.CAST_STATE:
			_draw_cast_aura(1.0)
		if character_id == "kael":
			_draw_kael_combat_fx()
		if hit_flash > 0.0:
			draw_circle(Vector2(0, -24.0 * visual_scale), 20.0 * visual_scale, Color(1, 1, 1, hit_flash * 0.35))
		return

	_compute_view()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var shadow_width := 11.0 * visual_scale * (1.9 if is_boss else 1.0)
	draw_ellipse_shadow(Vector2(0, 0), Vector2(shadow_width, 4.0 * visual_scale))

	var moving := _view_moving
	var bob := sin(anim_time * (9.0 if moving else 2.2)) * (2.2 if moving else 0.9)
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(facing * visual_scale, visual_scale))

	match kind:
		Kind.HUMAN:
			_draw_human()
		Kind.SPIRIT:
			_draw_spirit()
		Kind.MONSTER:
			_draw_monster()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if animator != null and animator.state == CharacterAnimator.CAST_STATE:
		_draw_cast_aura(1.0)
	if hit_flash > 0.0:
		draw_circle(Vector2(0, -24.0 * visual_scale), 20.0 * visual_scale, Color(1, 1, 1, hit_flash * 0.35))


## Phase-2: a magic casting aura drawn on top of the normal figure. Uses _accent
## so it stays coherent with the GreenwardStyle palette; BOTH the Sprite2D path
## and the procedural fallback path render it while CAST (state 8) is active.
func _draw_cast_aura(intensity: float) -> void:
	var center := Vector2(0, -26.0 * visual_scale)
	var col := _accent
	draw_circle(center, 30.0 * visual_scale, Color(col.r, col.g, col.b, 0.12 * intensity))
	draw_circle(center, 18.0 * visual_scale, Color(col.r, col.g, col.b, 0.20 * intensity))
	draw_arc(center, 26.0 * visual_scale, 0.0, TAU, 24, Color(col.r, col.g, col.b, 0.5 * intensity), 2.0)
	for i in 6:
		var ang := TAU * float(i) / 6.0 + anim_time * 0.9
		var p := center + Vector2(cos(ang), sin(ang)) * 24.0 * visual_scale
		draw_circle(p, 2.2 * visual_scale, Color(col.r, col.g, col.b, 0.85 * intensity))


## Kael's personal VFX language: ember motes at rest, directional ash while
## moving, a sword crescent timed to the attack's impact frames, and a layered
## crimson seal during CAST. These are additive overlays; the authored sprite
## frames remain the source of truth for his silhouette and sword pose.
func _draw_kael_combat_fx() -> void:
	if animator == null:
		return
	var crimson := Color("#ff3158")
	var hot_red := Color("#ff9aab")
	var deep_red := Color("#8d1639")
	var state := animator.state
	var frame_count := float(maxi(1, animator.frame_count()))
	var progress := clampf((float(animator.frame) + animator.elapsed * animator.fps() * animator.speed_scale) / frame_count, 0.0, 1.0)
	var center := Vector2(0.0, -39.0 * visual_scale)

	if state == S_IDLE:
		# A few slow, individually phased embers keep the still pose alive.
		for i in 5:
			var phase := anim_time * (0.72 + float(i % 3) * 0.13) + float(i) * 1.31
			var p := Vector2(cos(phase) * (15.0 + float(i % 2) * 5.0), -17.0 - fposmod(anim_time * (5.0 + float(i % 3)) + float(i) * 11.0, 52.0))
			var alpha := 0.24 + 0.28 * (0.5 + 0.5 * sin(phase * 1.7))
			draw_circle(p * visual_scale, (0.8 + float(i % 2) * 0.45) * visual_scale, Color(crimson.r, crimson.g, crimson.b, alpha))
			draw_line(p * visual_scale, (p + Vector2(-1.2, 2.8)) * visual_scale, Color(hot_red.r, hot_red.g, hot_red.b, alpha * 0.7), 0.8 * visual_scale)
		# A restrained ember glow pulses around the sword hand / chest.
		var pulse := 0.5 + 0.5 * sin(anim_time * 2.4)
		draw_circle(center + Vector2(8, 4) * visual_scale, (5.0 + pulse * 2.0) * visual_scale, Color(crimson.r, crimson.g, crimson.b, 0.035 + pulse * 0.035))
	elif state == S_WALK or state == S_RUN:
		var stride := 1.0 if state == S_RUN else 0.65
		for i in 4:
			var phase := anim_time * (8.5 if state == S_RUN else 6.0) + float(i) * 1.7
			var p := Vector2(-10.0 - fposmod(anim_time * 13.0 + float(i) * 9.0, 15.0), -4.0 - fposmod(anim_time * (17.0 + float(i)) + float(i) * 13.0, 23.0))
			draw_circle(p * visual_scale, (0.75 + 0.35 * sin(phase)) * visual_scale, Color(crimson.r, crimson.g, crimson.b, 0.30 * stride))
	elif state == S_ATTACK:
		# The bright crescent appears only across the active blade frames.
		var slash := smoothstep(0.27, 0.48, progress) * (1.0 - smoothstep(0.67, 0.86, progress))
		if slash > 0.01:
			var sweep := lerpf(-0.95, 1.05, clampf((progress - 0.27) / 0.52, 0.0, 1.0))
			var radius := 28.0 * visual_scale
			var slash_center := Vector2(7.0, -43.0) * visual_scale
			draw_arc(slash_center, radius, sweep - 1.05, sweep + 0.78, 28, Color(crimson.r, crimson.g, crimson.b, 0.88 * slash), 3.0 * visual_scale, true)
			draw_arc(slash_center, radius - 3.5 * visual_scale, sweep - 0.92, sweep + 0.62, 24, Color(hot_red.r, hot_red.g, hot_red.b, 0.72 * slash), 1.2 * visual_scale, true)
			var tip := slash_center + Vector2(cos(sweep + 0.78), sin(sweep + 0.78)) * radius
			draw_circle(tip, 2.0 * visual_scale * slash, Color(1.0, 0.82, 0.86, slash))
		var impact := smoothstep(0.40, 0.48, progress) * (1.0 - smoothstep(0.53, 0.63, progress))
		if impact > 0.01:
			draw_circle(Vector2(10, -36) * visual_scale, (8.0 + 12.0 * impact) * visual_scale, Color(crimson.r, crimson.g, crimson.b, 0.20 * impact))
			for i in 7:
				var a := TAU * float(i) / 7.0 + anim_time * 0.8
				var ray := Vector2(cos(a), sin(a))
				draw_line(Vector2(10, -36) * visual_scale + ray * 5.0 * visual_scale, Vector2(10, -36) * visual_scale + ray * (12.0 + 8.0 * impact) * visual_scale, Color(hot_red.r, hot_red.g, hot_red.b, 0.8 * impact), 1.1 * visual_scale)
	elif state == S_CAST:
		# Ground seal expands, rotates and resolves into a rising crimson flare.
		var gather := smoothstep(0.0, 0.34, progress)
		var release := smoothstep(0.56, 0.82, progress) * (1.0 - smoothstep(0.9, 1.0, progress))
		var ring_radius := lerpf(9.0, 31.0, gather) * visual_scale
		var ring_alpha := 0.20 + 0.48 * (1.0 - release)
		var ground := Vector2(0, -2.0) * visual_scale
		draw_arc(ground, ring_radius, anim_time * 0.9, anim_time * 0.9 + TAU, 36, Color(crimson.r, crimson.g, crimson.b, ring_alpha), 1.8 * visual_scale, true)
		draw_arc(ground, ring_radius * 0.72, -anim_time * 1.4, -anim_time * 1.4 + TAU, 32, Color(hot_red.r, hot_red.g, hot_red.b, ring_alpha * 0.62), 0.9 * visual_scale, true)
		for i in 8:
			var a := TAU * float(i) / 8.0 + anim_time * 0.7
			var p := ground + Vector2(cos(a), sin(a) * 0.42) * ring_radius
			draw_circle(p, 1.35 * visual_scale, Color(hot_red.r, hot_red.g, hot_red.b, ring_alpha))
		if release > 0.01:
			var pillar_height := 70.0 * release * visual_scale
			draw_line(Vector2(0, -5) * visual_scale, Vector2(0, -5) * visual_scale - Vector2(0, pillar_height), Color(crimson.r, crimson.g, crimson.b, 0.38 * release), 5.0 * visual_scale)
			draw_line(Vector2(0, -5) * visual_scale, Vector2(0, -5) * visual_scale - Vector2(0, pillar_height * 0.82), Color(hot_red.r, hot_red.g, hot_red.b, 0.78 * release), 1.5 * visual_scale)
		for i in 9:
			var p := Vector2(sin(anim_time * 2.0 + float(i) * 2.1) * (9.0 + float(i % 3) * 5.0), -8.0 - fposmod(anim_time * (24.0 + float(i)) + float(i) * 13.0, 78.0))
			draw_circle(p * visual_scale, 1.0 * visual_scale, Color(hot_red.r, hot_red.g, hot_red.b, 0.68 * release + 0.12))
	elif state == S_DAMAGE:
		var hurt := 1.0 - progress
		if hurt > 0.01:
			draw_circle(center, 18.0 * visual_scale, Color(crimson.r, crimson.g, crimson.b, 0.10 * hurt))
			for i in 5:
				var a := TAU * float(i) / 5.0
				draw_line(center + Vector2(cos(a), sin(a)) * 8.0 * visual_scale, center + Vector2(cos(a), sin(a)) * 17.0 * visual_scale, Color(hot_red.r, hot_red.g, hot_red.b, 0.55 * hurt), 1.0 * visual_scale)
	elif state == S_VICTORY:
		var glow := 0.45 + 0.35 * sin(anim_time * 3.0)
		for i in 7:
			var a := TAU * float(i) / 7.0 + anim_time * 0.35
			var p := center + Vector2(cos(a) * 23.0, sin(a) * 29.0) * visual_scale
			draw_circle(p, 1.2 * visual_scale, Color(hot_red.r, hot_red.g, hot_red.b, glow))
	elif state == S_DEFEAT:
		for i in 8:
			var p := Vector2(cos(float(i) * 2.4) * (8.0 + float(i % 3) * 4.0), -4.0 - fposmod(anim_time * 8.0 + float(i) * 11.0, 42.0))
			draw_circle(p * visual_scale, 0.8 * visual_scale, Color(deep_red.r, deep_red.g, deep_red.b, 0.42))


func draw_ellipse_shadow(center: Vector2, radius: Vector2) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var points := PackedVector2Array()
	for index in 18:
		var angle := TAU * float(index) / 18.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, Color(0.02, 0.05, 0.04, 0.32))


func _draw_human() -> void:
	var frame_f := 0.0
	if animator != null:
		frame_f = float(animator.frame)
	var amp := 5.0 if animator != null and animator.state == S_RUN else 4.0
	var walk_swing := (sin(anim_time * 10.0 + frame_f * 0.8) * amp) if _view_moving else 0.0

	# Cape behind body; a broader cape-BACK is drawn when facing UP.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -34), Vector2(8, -34), Vector2(13, -8), Vector2(0, -4), Vector2(-13, -8)
	]), _primary.darkened(0.28))
	if _view_back:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-10, -36), Vector2(10, -36), Vector2(12, -6), Vector2(-12, -6)
		]), _secondary.darkened(0.35))

	# Legs — feet stay on ONE baseline (y = -1).
	draw_line(Vector2(-4, -15), Vector2(-5 + walk_swing, -2), _primary.darkened(0.4), 4.5)
	draw_line(Vector2(4, -15), Vector2(5 - walk_swing, -2), _primary.darkened(0.4), 4.5)
	draw_line(Vector2(-7 + walk_swing, -1), Vector2(-2 + walk_swing, -1), Color("#2a2018"), 3.0)
	draw_line(Vector2(2 - walk_swing, -1), Vector2(7 - walk_swing, -1), Color("#2a2018"), 3.0)

	# Torso and belt
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9, -33), Vector2(9, -33), Vector2(11, -16), Vector2(-11, -16)
	]), _primary)
	draw_rect(Rect2(-10, -19, 20, 3), _secondary)
	if not _view_back:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-2, -33), Vector2(4, -33), Vector2(5, -17), Vector2(-1, -17)
		]), _secondary.lightened(0.2))

	# Arms
	draw_line(Vector2(-9, -30), Vector2(-14, -20 + walk_swing * 0.3), _skin, 3.4)
	draw_line(Vector2(9, -30), Vector2(14, -20 - walk_swing * 0.3), _skin, 3.4)

	# Head
	draw_circle(Vector2(0, -42), 9.2, _skin)
	if _view_back:
		# Back of the head: hair covers everything, facial features hidden.
		draw_colored_polygon(PackedVector2Array([
			Vector2(-9, -38), Vector2(-10, -46), Vector2(-6, -52), Vector2(0, -54),
			Vector2(6, -52), Vector2(10, -46), Vector2(9, -38)
		]), _hair)
		draw_circle(Vector2(0, -30), 1.6, _accent)  # nape glint / cape-back detail
	else:
		# Hair silhouette (front or 3/4).
		draw_colored_polygon(PackedVector2Array([
			Vector2(-10, -43), Vector2(-9, -51), Vector2(-2, -55), Vector2(7, -53),
			Vector2(11, -46), Vector2(8, -41), Vector2(7, -48), Vector2(1, -50),
			Vector2(-4, -47), Vector2(-6, -40)
		]), _hair)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-8, -46), Vector2(-4, -52), Vector2(4, -51), Vector2(7, -45),
			Vector2(2, -48), Vector2(-2, -45)
		]), _hair.lightened(0.08))
		# Eyes: diagonals shift the pair, profiles show a single eye.
		var ex := 0.0
		if _view_diag:
			ex = 1.8 * _view_face
		if _view_profile:
			var eye_x := 3.0 * _view_face
			draw_circle(Vector2(eye_x, -41.5), 1.35, Color("#1c2230"))
			draw_circle(Vector2(eye_x + 0.4 * _view_face, -42.0), 0.5, _accent)
		else:
			draw_circle(Vector2(-3.2 + ex, -41.5), 1.15, Color("#1c2230"))
			draw_circle(Vector2(3.2 + ex, -41.5), 1.15, Color("#1c2230"))
			draw_circle(Vector2(-2.8 + ex, -42.0), 0.45, _accent)
			draw_circle(Vector2(3.6 + ex, -42.0), 0.45, _accent)

	_draw_race_features()

	# Weapon at the back
	if race in ["Elf", "Human", "Beastkin", "Vampire"]:
		draw_line(Vector2(-12, -36), Vector2(10, -18), _secondary.darkened(0.25), 1.8)
		draw_line(Vector2(-12, -36), Vector2(-15, -41), _secondary, 1.8)
	else:
		draw_line(Vector2(12, -34), Vector2(15, -50), _secondary, 2.0)
		draw_circle(Vector2(15, -52), 3.0, _accent)


func _draw_race_features() -> void:
	match race:
		"Elf":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-9, -42), Vector2(-15, -46), Vector2(-9, -38)
			]), _skin)
			draw_colored_polygon(PackedVector2Array([
				Vector2(9, -42), Vector2(15, -46), Vector2(9, -38)
			]), _skin)
			draw_circle(Vector2(0, -50), 1.6, _accent)
		"Beastkin":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-8, -51), Vector2(-11, -61), Vector2(-2, -53)
			]), _hair)
			draw_colored_polygon(PackedVector2Array([
				Vector2(8, -51), Vector2(11, -61), Vector2(2, -53)
			]), _hair)
			draw_circle(Vector2(-8, -53), 2.4, _secondary)
			draw_circle(Vector2(8, -53), 2.4, _secondary)
		"Demon":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-8, -50), Vector2(-12, -60), Vector2(-4, -52)
			]), _secondary)
			draw_colored_polygon(PackedVector2Array([
				Vector2(8, -50), Vector2(12, -60), Vector2(4, -52)
			]), _secondary)
			draw_line(Vector2(-2, -51), Vector2(2, -51), _secondary, 1.0)
		"Angel":
			draw_arc(Vector2(0, -58), 8.0, PI * 0.15, PI * 0.85, 12, Color(1.0, 0.92, 0.6, 0.85), 1.6)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-12, -34), Vector2(-24, -42), Vector2(-14, -22)
			]), Color(1.0, 0.98, 0.9, 0.35))
			draw_colored_polygon(PackedVector2Array([
				Vector2(12, -34), Vector2(24, -42), Vector2(14, -22)
			]), Color(1.0, 0.98, 0.9, 0.35))
		"Mermaid":
			draw_circle(Vector2(0, -50), 1.8, _accent)
			draw_line(Vector2(-7, -38), Vector2(7, -38), _accent, 1.2)
		"Vampire":
			draw_line(Vector2(-5, -45), Vector2(5, -45), _secondary, 1.2)
			draw_circle(Vector2(0, -38.5), 1.2, Color("#ff8fb3"))
		"Spirit":
			draw_circle(Vector2(0, -42), 12.0, Color(_accent.r, _accent.g, _accent.b, 0.12))
			draw_circle(Vector2(-5, -56), 1.4, _accent)
			draw_circle(Vector2(6, -59), 1.0, _accent)
		"Ancient":
			draw_line(Vector2(-9, -40), Vector2(-16, -36), _secondary, 2.0)
			draw_line(Vector2(9, -40), Vector2(16, -36), _secondary, 2.0)
			draw_circle(Vector2(0, -46), 2.2, _accent)


func _draw_spirit() -> void:
	var hover := sin(anim_time * 1.8) * 3.0
	var center := Vector2(0, -34 + hover)
	draw_circle(center, 18.0, Color(_accent.r, _accent.g, _accent.b, 0.10))
	draw_circle(center, 10.0, Color(_primary.r, _primary.g, _primary.b, 0.9))
	draw_circle(center, 6.5, _accent)
	draw_circle(center + Vector2(-2, -2), 2.2, Color(1, 1, 1, 0.9))
	draw_circle(center + Vector2(3.2, 1.4), 1.6, Color("#1c2230"))
	draw_circle(center + Vector2(-4.2, 1.4), 1.6, Color("#1c2230"))
	for index in 3:
		var offset := Vector2(sin(anim_time * 2.2 + index) * 6.0, 8.0 + index * 5.0)
		draw_circle(center + offset, 2.4 - index * 0.5, Color(_accent.r, _accent.g, _accent.b, 0.4 - index * 0.1))


func _draw_monster() -> void:
	match def_id:
		"mossling":
			_draw_mossling()
		"moonpetal_sprite":
			_draw_moonpetal_sprite()
		"glade_wisp":
			kind = Kind.SPIRIT
			_draw_spirit()
		"thornhound":
			_draw_hound()
		"corrupted_treant", "elder_hollow":
			_draw_treant()
		"fallen_matron":
			_draw_fallen_matron()
		"fae_marauder":
			kind = Kind.HUMAN
			race = "Demon"
			_draw_human()
		_:
			_draw_blob()


func _draw_blob() -> void:
	var squash := sin(anim_time * 2.6) * 1.5
	draw_colored_polygon(PackedVector2Array([
		Vector2(-17, -3), Vector2(-19, -18 - squash), Vector2(-10, -30), Vector2(0, -33 - squash),
		Vector2(11, -29), Vector2(19, -17 - squash), Vector2(16, -3)
	]), _primary)
	draw_circle(Vector2(-6, -23), 5.0, Color(_secondary.r, _secondary.g, _secondary.b, 0.7))
	draw_circle(Vector2(6, -25), 6.0, Color(_secondary.r, _secondary.g, _secondary.b, 0.55))
	draw_circle(Vector2(-5, -17), 2.1, Color("#10131c"))
	draw_circle(Vector2(5, -17), 2.1, Color("#10131c"))
	draw_circle(Vector2(-4.4, -17.7), 0.7, Color("#d9ff9f"))
	draw_circle(Vector2(5.6, -17.7), 0.7, Color("#d9ff9f"))
	draw_circle(Vector2(0, -12), 1.0, Color(_accent.r, _accent.g, _accent.b, 0.7))
	for index in 4:
		var x := -12.0 + index * 8.0
		draw_line(Vector2(x, -30), Vector2(x + 2, -36 - (index % 2) * 3), Color("#5d8f52"), 1.8)


func _draw_mossling() -> void:
	var bob := sin(anim_time * 2.7) * 1.8
	var blink := 0.65 + 0.35 * sin(anim_time * 1.4)
	# Low, squat moss creature with a layered fern mantle and seed-like eyes.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-20, -4), Vector2(-22, -17 - bob), Vector2(-14, -29 - bob),
		Vector2(-5, -33 - bob), Vector2(8, -31 - bob), Vector2(20, -20 - bob),
		Vector2(18, -5), Vector2(8, 1), Vector2(-12, 1)
	]), _primary.darkened(0.12))
	draw_ellipse_shadow(Vector2(0, -16 - bob), Vector2(13, 12))
	for i in 5:
		var x := -16.0 + float(i) * 8.0
		var sway := sin(anim_time * 2.0 + float(i) * 0.9) * 2.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, -24 - bob), Vector2(x - 5 + sway, -35 - bob),
			Vector2(x + 1, -43 - bob - float(i % 2) * 3.0),
			Vector2(x + 6 + sway, -30 - bob)
		]), _secondary if i % 2 == 0 else _primary.lightened(0.18))
	# Tiny amber eyes and a softly glowing mouth mark.
	draw_circle(Vector2(-6, -19 - bob), 2.5, Color("#152017"))
	draw_circle(Vector2(6, -19 - bob), 2.5, Color("#152017"))
	draw_circle(Vector2(-5.5, -20 - bob), 0.9, Color(_accent.r, _accent.g, _accent.b, blink))
	draw_circle(Vector2(6.5, -20 - bob), 0.9, Color(_accent.r, _accent.g, _accent.b, blink))
	draw_arc(Vector2(0, -12 - bob), 3.0, 0.2, PI - 0.2, 8, _secondary, 1.2)
	draw_circle(Vector2(-13, -7), 3.0, _secondary.darkened(0.2))
	draw_circle(Vector2(13, -7), 3.0, _secondary.darkened(0.2))


func _draw_moonpetal_sprite() -> void:
	var bob := sin(anim_time * 2.1) * 3.0
	var wing := sin(anim_time * 9.0) * 5.0
	var center := Vector2(0, -31 + bob)
	# Four translucent moonpetal wings, flapping independently of the body.
	for side in [-1.0, 1.0]:
		var spread := 20.0 + wing * 0.45
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(side * 5, -7),
			center + Vector2(side * (spread + 9), -22 - wing * 0.35),
			center + Vector2(side * (spread + 5), -2),
			center + Vector2(side * 7, 5)
		]), Color(_secondary.r, _secondary.g, _secondary.b, 0.62))
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(side * 4, 0),
			center + Vector2(side * (spread + 7), 10 + wing * 0.3),
			center + Vector2(side * (spread - 1), 22),
			center + Vector2(side * 3, 8)
		]), Color(_accent.r, _accent.g, _accent.b, 0.42))
	# Pearl body and long luminous antennae.
	draw_circle(center, 16.0, Color(_accent.r, _accent.g, _accent.b, 0.10))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -12), center + Vector2(8, -2),
		center + Vector2(5, 13), center + Vector2(0, 18),
		center + Vector2(-5, 13), center + Vector2(-8, -2)
	]), _primary.lightened(0.22))
	draw_circle(center + Vector2(0, -13), 6.5, _secondary.lightened(0.2))
	draw_circle(center + Vector2(-2.2, -14), 1.2, Color("#182333"))
	draw_circle(center + Vector2(2.2, -14), 1.2, Color("#182333"))
	draw_line(center + Vector2(-3, -18), center + Vector2(-8, -27), _accent, 1.3)
	draw_line(center + Vector2(3, -18), center + Vector2(8, -27), _accent, 1.3)
	draw_circle(center + Vector2(-8, -27), 2.0, Color("#f4d9ff"))
	draw_circle(center + Vector2(8, -27), 2.0, Color("#f4d9ff"))
	draw_circle(center + Vector2(0, 3), 3.2, Color("#f4d9ff", 0.8))


func _draw_hound() -> void:
	var stride := sin(anim_time * 10.0) * 3.0 if _view_moving else 0.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -18), Vector2(-12, -27), Vector2(2, -29), Vector2(14, -23),
		Vector2(20, -15), Vector2(12, -8), Vector2(-12, -8), Vector2(-20, -12)
	]), _primary)
	draw_circle(Vector2(17, -24), 8.0, _primary.lightened(0.08))
	draw_colored_polygon(PackedVector2Array([
		Vector2(12, -30), Vector2(13, -38), Vector2(18, -31)
	]), _secondary)
	draw_colored_polygon(PackedVector2Array([
		Vector2(20, -30), Vector2(23, -37), Vector2(25, -28)
	]), _secondary)
	draw_circle(Vector2(20, -25), 1.8, Color("#1c2230"))
	draw_circle(Vector2(21, -25.5), 0.6, _accent)
	# Thorn spines
	for index in 5:
		var x := -12.0 + index * 6.0
		draw_line(Vector2(x, -28), Vector2(x + 2, -35), Color("#8fbf6a"), 1.4)
	# Legs
	draw_line(Vector2(-13, -9), Vector2(-15 + stride, 0), _primary.darkened(0.4), 3.0)
	draw_line(Vector2(-4, -9), Vector2(-2 - stride, 0), _primary.darkened(0.4), 3.0)
	draw_line(Vector2(9, -9), Vector2(11 + stride, 0), _primary.darkened(0.4), 3.0)
	draw_line(Vector2(16, -9), Vector2(18 - stride, 0), _primary.darkened(0.4), 3.0)


func _draw_treant() -> void:
	if def_id == "elder_hollow":
		_draw_elder_hollow()
	else:
		_draw_corrupted_treant()


func _draw_elder_hollow() -> void:
	# A tall, watchful woodland oracle: a hollow bark mask beneath a layered
	# leaf mantle, hanging root-beard and a lantern-heart. Not a generic owl.
	var sway := sin(anim_time * 0.72) * 2.0
	var pulse := 0.72 + 0.28 * sin(anim_time * 1.8)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing * visual_scale * 1.48, visual_scale * 1.48))
	# Wide root-feet and tapered trunk robe.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-27, 1), Vector2(-21, -24), Vector2(-18, -55), Vector2(-22, -88),
		Vector2(-15, -112), Vector2(0, -120), Vector2(17, -108), Vector2(21, -82),
		Vector2(16, -50), Vector2(26, -20), Vector2(31, 2), Vector2(12, -7),
		Vector2(0, -25), Vector2(-12, -7)
	]), Color("#465b43"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -7), Vector2(-5, -54), Vector2(-2, -96), Vector2(8, -62),
		Vector2(13, -8), Vector2(1, -20)
	]), Color("#71815a"))
	# Carved grain, old knots and moss seams.
	for i in range(5):
		var x := -17.0 + float(i) * 8.0
		draw_line(Vector2(x, -17), Vector2(x + sin(float(i)) * 3.0, -82 - float(i % 2) * 9.0), Color("#293d32"), 2.0)
	draw_arc(Vector2(-12, -69), 5.0, 0.2, 5.7, 16, Color("#a0a36a"), 1.4)
	draw_arc(Vector2(13, -47), 4.0, 0.0, TAU, 16, Color("#a0a36a"), 1.4)
	# Branch arms form a cloak-like silhouette, with twig fingers.
	draw_line(Vector2(-15, -91), Vector2(-35, -73 + sway), Color("#493f32"), 7.0)
	draw_line(Vector2(-35, -73 + sway), Vector2(-48, -49 + sway), Color("#493f32"), 4.0)
	draw_line(Vector2(-43, -59 + sway), Vector2(-53, -65 + sway), Color("#493f32"), 2.0)
	draw_line(Vector2(15, -91), Vector2(35, -73 - sway), Color("#493f32"), 7.0)
	draw_line(Vector2(35, -73 - sway), Vector2(48, -49 - sway), Color("#493f32"), 4.0)
	draw_line(Vector2(43, -59 - sway), Vector2(53, -65 - sway), Color("#493f32"), 2.0)
	# Face: angular hollow mask, not round eyes on a round head.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16, -112), Vector2(-13, -132), Vector2(-5, -141),
		Vector2(8, -138), Vector2(17, -124), Vector2(13, -103),
		Vector2(3, -94), Vector2(-10, -99)
	]), Color("#202d27"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10, -119), Vector2(-5, -126), Vector2(-1, -115), Vector2(-8, -111)
	]), Color("#d7e8a8", 0.9))
	draw_colored_polygon(PackedVector2Array([
		Vector2(10, -119), Vector2(5, -126), Vector2(1, -115), Vector2(8, -111)
	]), Color("#d7e8a8", 0.9))
	draw_circle(Vector2(-5, -119), 2.0, Color("#f2ffce"))
	draw_circle(Vector2(5, -119), 2.0, Color("#f2ffce"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-3, -108), Vector2(0, -101), Vector2(3, -108), Vector2(0, -113)
	]), Color("#101a17"))
	# A layered crown of crooked branches and broad leaves.
	draw_line(Vector2(-12, -128), Vector2(-28, -151 + sway), Color("#403b2d"), 4.0)
	draw_line(Vector2(-28, -151 + sway), Vector2(-43, -160 + sway), Color("#403b2d"), 2.8)
	draw_line(Vector2(-27, -150 + sway), Vector2(-25, -169 + sway), Color("#403b2d"), 2.5)
	draw_line(Vector2(12, -128), Vector2(28, -151 - sway), Color("#403b2d"), 4.0)
	draw_line(Vector2(28, -151 - sway), Vector2(43, -160 - sway), Color("#403b2d"), 2.8)
	draw_line(Vector2(27, -150 - sway), Vector2(25, -169 - sway), Color("#403b2d"), 2.5)
	for i in range(9):
		var lx := -38.0 + float(i) * 9.0
		var ly := -153.0 - float(i % 3) * 7.0 + sway
		draw_colored_polygon(PackedVector2Array([
			Vector2(lx, ly), Vector2(lx + 5, ly - 13), Vector2(lx + 14, ly - 9), Vector2(lx + 9, ly + 1)
		]), Color("#5e8b4e") if i % 2 == 0 else Color("#8ca65b"))
	# Hanging root beard and moss tassels.
	for i in range(7):
		var x := -15.0 + float(i) * 5.0
		draw_line(Vector2(x, -99), Vector2(x + sin(anim_time + float(i)) * 2.0, -74 - float(i % 3) * 5.0), Color("#8a7850"), 1.8)
	# Lantern-heart glows softly through a split in the bark.
	var heart := Color("#dfff9b")
	var heart_y := -65.0 + sin(anim_time * 1.6) * 1.4
	draw_circle(Vector2(0, heart_y), 16.0, Color(0.72, 1.0, 0.48, 0.12 * pulse))
	draw_circle(Vector2(0, heart_y), 7.0, Color(0.78, 1.0, 0.55, 0.28 * pulse))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, heart_y - 9), Vector2(6, heart_y - 1), Vector2(0, heart_y + 8), Vector2(-6, heart_y - 1)
	]), heart)
	# Rooted toes spread over the ground plane.
	draw_line(Vector2(-17, -5), Vector2(-38, 4), Color("#374a36"), 5.0)
	draw_line(Vector2(16, -5), Vector2(38, 4), Color("#374a36"), 5.0)
	for i in range(5):
		var a := anim_time * 0.35 + TAU * float(i) / 5.0
		var mote := Vector2(cos(a) * 31.0, -78.0 + sin(a) * 34.0)
		draw_circle(mote, 1.8, Color(0.82, 1.0, 0.55, 0.52 * pulse))


func _draw_corrupted_treant() -> void:
	# Greenward's fallen guardian: a massive ancient trunk with asymmetric
	# branch antlers, layered foliage, thorn limbs and vivid violet blight.
	var sway := sin(anim_time * 0.9) * 2.4
	var pulse := 0.7 + 0.3 * sin(anim_time * 2.2)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing * visual_scale * 1.32, visual_scale * 1.32))
	# Root mantle and broad trunk torso.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-36, 3), Vector2(-29, -30), Vector2(-25, -67), Vector2(-32, -98),
		Vector2(-20, -128), Vector2(-5, -145), Vector2(17, -139), Vector2(31, -112),
		Vector2(25, -76), Vector2(35, -36), Vector2(43, 3), Vector2(18, -8),
		Vector2(0, -28), Vector2(-17, -7)
	]), Color("#554334"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -8), Vector2(-9, -52), Vector2(-2, -104), Vector2(12, -65),
		Vector2(20, -5), Vector2(2, -27)
	]), Color("#826044"))
	# Massive split roots and branch-like arms.
	draw_line(Vector2(-23, -12), Vector2(-49, 9), Color("#4b382d"), 9.0)
	draw_line(Vector2(-49, 9), Vector2(-65, 5), Color("#4b382d"), 5.0)
	draw_line(Vector2(22, -12), Vector2(49, 8), Color("#4b382d"), 9.0)
	draw_line(Vector2(49, 8), Vector2(65, 4), Color("#4b382d"), 5.0)
	draw_line(Vector2(-22, -115), Vector2(-52, -90 + sway), Color("#49382c"), 10.0)
	draw_line(Vector2(-52, -90 + sway), Vector2(-70, -64 + sway), Color("#49382c"), 6.0)
	draw_line(Vector2(-52, -90 + sway), Vector2(-77, -94 + sway), Color("#49382c"), 4.0)
	draw_line(Vector2(22, -115), Vector2(52, -88 - sway), Color("#49382c"), 10.0)
	draw_line(Vector2(52, -88 - sway), Vector2(71, -58 - sway), Color("#49382c"), 6.0)
	draw_line(Vector2(52, -88 - sway), Vector2(80, -96 - sway), Color("#49382c"), 4.0)
	# Bark plates, knots and exposed root grain.
	for i in range(7):
		var x := -25.0 + float(i) * 8.0
		draw_line(Vector2(x, -23), Vector2(x + sin(float(i) * 1.7) * 4.0, -105 - float(i % 3) * 8.0), Color("#342a25"), 2.6)
	draw_arc(Vector2(-14, -77), 8.0, 0.2, 5.8, 18, Color("#aa8051"), 2.0)
	draw_arc(Vector2(18, -50), 6.0, 0.0, TAU, 18, Color("#aa8051"), 1.8)
	# Deep face cavity and blazing corruption core.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-19, -119), Vector2(-15, -143), Vector2(0, -153), Vector2(18, -139),
		Vector2(20, -116), Vector2(10, -101), Vector2(-9, -102)
	]), Color("#1a171c"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-13, -129), Vector2(-4, -136), Vector2(-2, -122), Vector2(-13, -119)
	]), Color("#e85bd7"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(13, -129), Vector2(4, -136), Vector2(2, -122), Vector2(13, -119)
	]), Color("#e85bd7"))
	draw_circle(Vector2(0, -110), 5.5, Color("#c638e7", 0.7 * pulse))
	# Huge antler crown, broken and uneven like a dead canopy.
	for side in [-1.0, 1.0]:
		var root := Vector2(side * 13.0, -143.0)
		var branch := Vector2(side * (49.0 + sway), -177.0)
		draw_line(root, branch, Color("#3e3029"), 7.0)
		draw_line(branch, Vector2(side * 78.0, -194.0 + sway), Color("#3e3029"), 4.0)
		draw_line(branch, Vector2(side * 70.0, -157.0 + sway), Color("#3e3029"), 3.5)
		draw_line(Vector2(side * 47.0, -177.0), Vector2(side * 43.0, -198.0), Color("#3e3029"), 3.0)
	# Leaf crown in broken clumps, not a smooth green blob.
	for i in range(11):
		var lx := -70.0 + float(i) * 14.0
		var ly := -179.0 - float(i % 3) * 7.0 + sin(anim_time * 1.3 + float(i)) * 2.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(lx, ly), Vector2(lx + 5, ly - 17), Vector2(lx + 16, ly - 13), Vector2(lx + 13, ly + 1)
		]), Color("#4f7139") if i % 2 == 0 else Color("#81994a"))
	# Purple corruption fissures and thorn growths.
	for i in range(6):
		var x := -21.0 + float(i) * 8.0
		draw_line(Vector2(x, -40), Vector2(x + sin(anim_time * 1.6 + i) * 3.0, -103 - float(i % 2) * 11.0), Color(0.85, 0.22, 0.92, 0.82 * pulse), 2.3)
	for i in range(5):
		var x := -28.0 + float(i) * 14.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, -56), Vector2(x + 5, -76), Vector2(x + 10, -55)
		]), Color("#6c365d"))
	# Bright flower-core embedded in the chest.
	var heart_y := -74.0 + sin(anim_time * 2.0) * 1.8
	draw_circle(Vector2(0, heart_y), 18.0, Color(0.86, 0.16, 0.96, 0.16 * pulse))
	for i in range(6):
		var a := TAU * float(i) / 6.0 + anim_time * 0.12
		var petal := Vector2(cos(a) * 9.0, heart_y + sin(a) * 9.0)
		draw_circle(petal, 4.2, Color("#d34df0", 0.9 * pulse))
	draw_circle(Vector2(0, heart_y), 4.5, Color("#fff0ff"))
	# Floating blight sparks around the silhouette.
	for i in range(8):
		var a := anim_time * 0.42 + TAU * float(i) / 8.0
		var mote := Vector2(cos(a) * 82.0, -102.0 + sin(a) * 67.0)
		draw_circle(mote, 2.0, Color(0.95, 0.38, 1.0, 0.55 * pulse))


func _draw_fallen_matron() -> void:
	# Use the supplied painted Matron cutout in the overworld too. The former
	# vector stand-in was a generic low-detail figure and did not match her
	# authored horns, silver-lilac hair, lace gown or ornate costume.
	var pulse := 0.75 + 0.25 * sin(anim_time * 2.1)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing * visual_scale, visual_scale))
	# Grounded violet aura and painted full-body silhouette.
	draw_circle(Vector2(0, -60), 43.0, Color(0.56, 0.18, 0.82, 0.075 * pulse))
	draw_texture_rect(FALLEN_MATRON_WORLD_TEXTURE, Rect2(-48, -137, 96, 132), false)
	# Small animated corruption motes frame the figure without obscuring it.
	for i in range(6):
		var angle := anim_time * 0.65 + TAU * float(i) / 6.0
		var point := Vector2(cos(angle) * 43.0, -73.0 + sin(angle) * 29.0)
		draw_circle(point, 2.0, Color(0.82, 0.43, 1.0, 0.42 + 0.24 * pulse))
		draw_circle(point, 4.5, Color(0.72, 0.24, 1.0, 0.10 * pulse))
	return
	# Legacy vector fallback retained below for projects without the painted asset.
	var sway := sin(anim_time * 1.25) * 2.0
	# Long layered skirt and train.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -45), Vector2(-21, -28), Vector2(-30, -3),
		Vector2(-19, 2), Vector2(0, -4), Vector2(20, 2),
		Vector2(31, -3), Vector2(20, -30), Vector2(12, -46)
	]), _primary)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-7, -43), Vector2(-10, -24), Vector2(-8, -4),
		Vector2(0, -7), Vector2(8, -4), Vector2(10, -24), Vector2(7, -43)
	]), _secondary)
	# Fine dark pleats and gold edging.
	for i in range(5):
		var x := -20.0 + float(i) * 10.0
		draw_line(Vector2(x, -27), Vector2(x + sin(anim_time + float(i)) * 1.5, -4), _primary.darkened(0.2), 1.2)
	draw_line(Vector2(-24, -5), Vector2(0, -10), Color("#c9a45a"), 1.2)
	draw_line(Vector2(0, -10), Vector2(25, -5), Color("#c9a45a"), 1.2)
	# Bodice, shoulders and high collar.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-13, -67), Vector2(-9, -49), Vector2(0, -44),
		Vector2(9, -49), Vector2(13, -67), Vector2(7, -73), Vector2(-7, -73)
	]), _primary)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, -69), Vector2(0, -61), Vector2(5, -69), Vector2(3, -75), Vector2(-3, -75)
	]), _secondary)
	# Arms extend slightly outward as if holding the magic in place.
	draw_line(Vector2(-10, -65), Vector2(-22, -52 + sway), _secondary, 5.0)
	draw_line(Vector2(-22, -52 + sway), Vector2(-29, -58 + sway), _skin, 4.0)
	draw_line(Vector2(10, -65), Vector2(22, -52 - sway), _secondary, 5.0)
	draw_line(Vector2(22, -52 - sway), Vector2(29, -58 - sway), _skin, 4.0)
	# Neck and pale face.
	draw_rect(Rect2(-4, -81, 8, 11), _skin)
	draw_circle(Vector2(0, -91), 12.0, _skin)
	draw_circle(Vector2(-4, -92), 1.2, Color("#30243b"))
	draw_circle(Vector2(4, -92), 1.2, Color("#30243b"))
	draw_line(Vector2(-3, -86), Vector2(3, -86), Color("#9a6077"), 1.0)
	# Silver-lavender hair frames the face and falls over both shoulders.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -95), Vector2(-16, -108), Vector2(-8, -116),
		Vector2(4, -116), Vector2(15, -106), Vector2(13, -91),
		Vector2(9, -84), Vector2(8, -103), Vector2(-8, -103),
		Vector2(-9, -84), Vector2(-14, -78), Vector2(-15, -92)
	]), _hair)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -87), Vector2(-17, -62), Vector2(-13, -46),
		Vector2(-8, -56), Vector2(-8, -86)
	]), _hair.lightened(0.08))
	draw_colored_polygon(PackedVector2Array([
		Vector2(12, -87), Vector2(18, -64), Vector2(13, -45),
		Vector2(8, -56), Vector2(8, -86)
	]), _hair.darkened(0.08))
	# Horned filigree headpiece.
	draw_line(Vector2(-8, -101), Vector2(-15, -112), Color("#33243d"), 3.0)
	draw_line(Vector2(-15, -112), Vector2(-20, -119), Color("#33243d"), 2.0)
	draw_line(Vector2(8, -101), Vector2(15, -112), Color("#33243d"), 3.0)
	draw_line(Vector2(15, -112), Vector2(20, -119), Color("#33243d"), 2.0)
	draw_line(Vector2(-9, -102), Vector2(9, -102), Color("#c9a45a"), 1.5)
	# Violet heartstone at the centre of her chest.
	draw_circle(Vector2(0, -58), 9.0, Color(_accent.r, _accent.g, _accent.b, 0.16 * pulse))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -65), Vector2(5, -59), Vector2(0, -52), Vector2(-5, -59)
	]), _accent)
	draw_circle(Vector2(0, -59), 2.0, Color("#f1d7ff"))
	# Corruption ribbons curl around her without hiding the costume.
	for side in [-1.0, 1.0]:
		var drift := sin(anim_time * 1.8 + side) * 4.0
		var ribbon := PackedVector2Array([
			Vector2(side * 19, -39),
			Vector2(side * (31 + drift), -48),
			Vector2(side * (34 + drift), -67),
			Vector2(side * 25, -78)
		])
		draw_polyline(ribbon, Color(_accent.r, _accent.g, _accent.b, 0.72), 2.2, true)
	# Floating petals and violet motes.
	for i in range(6):
		var angle := anim_time * 0.65 + TAU * float(i) / 6.0
		var p := Vector2(cos(angle) * (34.0 + sin(anim_time + float(i)) * 3.0), -72.0 + sin(angle) * 24.0)
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(0, -3), p + Vector2(3, 0), p + Vector2(0, 3), p + Vector2(-3, 0)
		]), Color(_accent.r, _accent.g, _accent.b, 0.35 + 0.25 * pulse))
