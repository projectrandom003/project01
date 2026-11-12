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
	var source: ActorFrameSource = SpriteFramesActorSource.register_character(character_id)
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

func play(state: int, direction: int = -1) -> void:
	if animator != null:
		animator.play(state, direction)
	queue_redraw()


func set_move_direction(v: Vector2) -> void:
	if animator != null:
		animator.set_direction_from_vector(v)
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
	queue_redraw()


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
		"glade_wisp":
			kind = Kind.SPIRIT
			_draw_spirit()
		"thornhound":
			_draw_hound()
		"corrupted_treant", "elder_hollow":
			_draw_treant()
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
	var scale_boss := 1.7 if def_id == "elder_hollow" else 1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing * visual_scale * scale_boss, visual_scale * scale_boss))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22, 0), Vector2(-14, -42), Vector2(-18, -66), Vector2(-6, -74),
		Vector2(6, -72), Vector2(16, -60), Vector2(14, -36), Vector2(24, 0)
	]), _primary)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6, -6), Vector2(-3, -62), Vector2(5, -62), Vector2(9, -6)
	]), _primary.lightened(0.16))
	# Face hollow
	draw_circle(Vector2(0, -52), 9.0, Color(0.04, 0.06, 0.05, 0.92))
	draw_circle(Vector2(-4, -54), 1.8, _accent)
	draw_circle(Vector2(4, -54), 1.8, _accent)
	draw_line(Vector2(-4, -46), Vector2(4, -45), _accent.darkened(0.2), 1.2)
	# Branches
	draw_line(Vector2(-14, -58), Vector2(-30, -76), _primary, 4.0)
	draw_line(Vector2(14, -56), Vector2(30, -72), _primary, 4.0)
	draw_line(Vector2(-26, -70), Vector2(-34, -84), _primary, 2.5)
	draw_line(Vector2(26, -68), Vector2(36, -82), _primary, 2.5)
	# Canopy
	draw_circle(Vector2(-20, -82), 14.0, Color("#2f5234"))
	draw_circle(Vector2(18, -80), 13.0, Color("#2f5234"))
	draw_circle(Vector2(0, -90), 17.0, Color("#3f6b3f"))
	draw_circle(Vector2(-8, -94), 8.0, Color("#5d8f52"))
	# Glowing heart for the boss
	if def_id == "elder_hollow":
		draw_circle(Vector2(0, -34), 5.0, Color(0.7, 1.0, 0.55, 0.9))
		draw_circle(Vector2(0, -34), 13.0, Color(0.7, 1.0, 0.55, 0.18))
