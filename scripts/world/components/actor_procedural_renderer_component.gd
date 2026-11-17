class_name ActorProceduralRendererComponent
extends Node2D
## Owns the complete procedural fallback renderer and character-specific drawn effects.

var visual: ActorVisual
var monster_painter: ProceduralMonsterPainter


func bind(owner_visual: ActorVisual) -> void:
	visual = owner_visual
	monster_painter = ProceduralMonsterPainter.new()
	monster_painter.bind(self, owner_visual)
	position = Vector2.ZERO
	queue_redraw()

func _compute_view() -> void:
	if visual.animator == null:
		visual._view_moving = visual.walking
		visual._view_back = false
		visual._view_diag = false
		visual._view_profile = false
		visual._view_face = 1.0
		return
	var st := visual.animator.state
	visual._view_moving = (st == ActorVisual.S_WALK or st == ActorVisual.S_RUN)
	var d := visual.animator.direction
	visual._view_back = d in [3, 4, 5]        # UP / UP_LEFT / UP_RIGHT -> back of head
	visual._view_diag = d in [1, 3, 5, 7]    # 3/4 view
	visual._view_profile = (d == 2 or d == 6)  # pure LEFT / RIGHT profile
	visual._view_face = -1.0 if d in [5, 6, 7] else 1.0


func _draw() -> void:
	# Frame-source path: the child Sprite2D renders the figure (and its baked
	# shadow). We only draw the hit-flash overlay here.
	if visual._sprite_active:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if visual.animator != null and visual.animator.state == CharacterAnimator.CAST_STATE:
			_draw_cast_aura(1.0)
		if visual.hit_flash > 0.0:
			draw_circle(Vector2(0, -24.0 * visual.visual_scale), 20.0 * visual.visual_scale, Color(1, 1, 1, visual.hit_flash * 0.35))
		return

	_compute_view()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var shadow_width := 11.0 * visual.visual_scale * (1.9 if visual.is_boss else 1.0)
	draw_ellipse_shadow(Vector2(0, 0), Vector2(shadow_width, 4.0 * visual.visual_scale))

	var moving := visual._view_moving
	var bob := sin(visual.anim_time * (9.0 if moving else 2.2)) * (2.2 if moving else 0.9)
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(visual.facing * visual.visual_scale, visual.visual_scale))

	match visual.kind:
		ActorVisual.Kind.HUMAN:
			_draw_human()
		ActorVisual.Kind.SPIRIT:
			_draw_spirit()
		ActorVisual.Kind.MONSTER:
			_draw_monster()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if visual.animator != null and visual.animator.state == CharacterAnimator.CAST_STATE:
		_draw_cast_aura(1.0)
	if visual.hit_flash > 0.0:
		draw_circle(Vector2(0, -24.0 * visual.visual_scale), 20.0 * visual.visual_scale, Color(1, 1, 1, visual.hit_flash * 0.35))


## Phase-2: a magic casting aura drawn on top of the normal figure. Uses visual._accent
## so it stays coherent with the GreenwardStyle visual.palette; BOTH the Sprite2D path
## and the procedural fallback path render it while CAST (state 8) is active.
func _draw_cast_aura(intensity: float) -> void:
	var center := Vector2(0, -26.0 * visual.visual_scale)
	var col := visual._accent
	draw_circle(center, 30.0 * visual.visual_scale, Color(col.r, col.g, col.b, 0.12 * intensity))
	draw_circle(center, 18.0 * visual.visual_scale, Color(col.r, col.g, col.b, 0.20 * intensity))
	draw_arc(center, 26.0 * visual.visual_scale, 0.0, TAU, 24, Color(col.r, col.g, col.b, 0.5 * intensity), 2.0)
	for i in 6:
		var ang := TAU * float(i) / 6.0 + visual.anim_time * 0.9
		var p := center + Vector2(cos(ang), sin(ang)) * 24.0 * visual.visual_scale
		draw_circle(p, 2.2 * visual.visual_scale, Color(col.r, col.g, col.b, 0.85 * intensity))


## Kael's personal VFX language: ember motes at rest, directional ash while
## moving, a sword crescent timed to the attack's impact frames, and a layered
## crimson seal during CAST. These are additive overlays; the authored sprite
## frames remain the source of truth for his silhouette and sword pose.

## Lilith's spectral effects are deliberately cool, soft and weightless.
## Her magic reads as moonlit spirit energy rather than fire or physical impacts.


func draw_ellipse_shadow(center: Vector2, radius: Vector2) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var points := PackedVector2Array()
	for index in 18:
		var angle := TAU * float(index) / 18.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, Color(0.02, 0.05, 0.04, 0.32))


func _draw_human() -> void:
	var frame_f := 0.0
	if visual.animator != null:
		frame_f = float(visual.animator.frame)
	var amp := 5.0 if visual.animator != null and visual.animator.state == ActorVisual.S_RUN else 4.0
	var walk_swing := (sin(visual.anim_time * 10.0 + frame_f * 0.8) * amp) if visual._view_moving else 0.0

	# Cape behind body; a broader cape-BACK is drawn when visual.facing UP.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -34), Vector2(8, -34), Vector2(13, -8), Vector2(0, -4), Vector2(-13, -8)
	]), visual._primary.darkened(0.28))
	if visual._view_back:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-10, -36), Vector2(10, -36), Vector2(12, -6), Vector2(-12, -6)
		]), visual._secondary.darkened(0.35))

	# Legs — feet stay on ONE baseline (y = -1).
	draw_line(Vector2(-4, -15), Vector2(-5 + walk_swing, -2), visual._primary.darkened(0.4), 4.5)
	draw_line(Vector2(4, -15), Vector2(5 - walk_swing, -2), visual._primary.darkened(0.4), 4.5)
	draw_line(Vector2(-7 + walk_swing, -1), Vector2(-2 + walk_swing, -1), Color("#2a2018"), 3.0)
	draw_line(Vector2(2 - walk_swing, -1), Vector2(7 - walk_swing, -1), Color("#2a2018"), 3.0)

	# Torso and belt
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9, -33), Vector2(9, -33), Vector2(11, -16), Vector2(-11, -16)
	]), visual._primary)
	draw_rect(Rect2(-10, -19, 20, 3), visual._secondary)
	if not visual._view_back:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-2, -33), Vector2(4, -33), Vector2(5, -17), Vector2(-1, -17)
		]), visual._secondary.lightened(0.2))

	# Arms
	draw_line(Vector2(-9, -30), Vector2(-14, -20 + walk_swing * 0.3), visual._skin, 3.4)
	draw_line(Vector2(9, -30), Vector2(14, -20 - walk_swing * 0.3), visual._skin, 3.4)

	# Head
	draw_circle(Vector2(0, -42), 9.2, visual._skin)
	if visual._view_back:
		# Back of the head: hair covers everything, facial features hidden.
		draw_colored_polygon(PackedVector2Array([
			Vector2(-9, -38), Vector2(-10, -46), Vector2(-6, -52), Vector2(0, -54),
			Vector2(6, -52), Vector2(10, -46), Vector2(9, -38)
		]), visual._hair)
		draw_circle(Vector2(0, -30), 1.6, visual._accent)  # nape glint / cape-back detail
	else:
		# Hair silhouette (front or 3/4).
		draw_colored_polygon(PackedVector2Array([
			Vector2(-10, -43), Vector2(-9, -51), Vector2(-2, -55), Vector2(7, -53),
			Vector2(11, -46), Vector2(8, -41), Vector2(7, -48), Vector2(1, -50),
			Vector2(-4, -47), Vector2(-6, -40)
		]), visual._hair)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-8, -46), Vector2(-4, -52), Vector2(4, -51), Vector2(7, -45),
			Vector2(2, -48), Vector2(-2, -45)
		]), visual._hair.lightened(0.08))
		# Eyes: diagonals shift the pair, profiles show a single eye.
		var ex := 0.0
		if visual._view_diag:
			ex = 1.8 * visual._view_face
		if visual._view_profile:
			var eye_x := 3.0 * visual._view_face
			draw_circle(Vector2(eye_x, -41.5), 1.35, Color("#1c2230"))
			draw_circle(Vector2(eye_x + 0.4 * visual._view_face, -42.0), 0.5, visual._accent)
		else:
			draw_circle(Vector2(-3.2 + ex, -41.5), 1.15, Color("#1c2230"))
			draw_circle(Vector2(3.2 + ex, -41.5), 1.15, Color("#1c2230"))
			draw_circle(Vector2(-2.8 + ex, -42.0), 0.45, visual._accent)
			draw_circle(Vector2(3.6 + ex, -42.0), 0.45, visual._accent)

	_draw_race_features()

	# Weapon at the back
	if visual.race in ["Elf", "Human", "Beastkin", "Vampire"]:
		draw_line(Vector2(-12, -36), Vector2(10, -18), visual._secondary.darkened(0.25), 1.8)
		draw_line(Vector2(-12, -36), Vector2(-15, -41), visual._secondary, 1.8)
	else:
		draw_line(Vector2(12, -34), Vector2(15, -50), visual._secondary, 2.0)
		draw_circle(Vector2(15, -52), 3.0, visual._accent)


func _draw_race_features() -> void:
	match visual.race:
		"Elf":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-9, -42), Vector2(-15, -46), Vector2(-9, -38)
			]), visual._skin)
			draw_colored_polygon(PackedVector2Array([
				Vector2(9, -42), Vector2(15, -46), Vector2(9, -38)
			]), visual._skin)
			draw_circle(Vector2(0, -50), 1.6, visual._accent)
		"Beastkin":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-8, -51), Vector2(-11, -61), Vector2(-2, -53)
			]), visual._hair)
			draw_colored_polygon(PackedVector2Array([
				Vector2(8, -51), Vector2(11, -61), Vector2(2, -53)
			]), visual._hair)
			draw_circle(Vector2(-8, -53), 2.4, visual._secondary)
			draw_circle(Vector2(8, -53), 2.4, visual._secondary)
		"Demon":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-8, -50), Vector2(-12, -60), Vector2(-4, -52)
			]), visual._secondary)
			draw_colored_polygon(PackedVector2Array([
				Vector2(8, -50), Vector2(12, -60), Vector2(4, -52)
			]), visual._secondary)
			draw_line(Vector2(-2, -51), Vector2(2, -51), visual._secondary, 1.0)
		"Angel":
			draw_arc(Vector2(0, -58), 8.0, PI * 0.15, PI * 0.85, 12, Color(1.0, 0.92, 0.6, 0.85), 1.6)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-12, -34), Vector2(-24, -42), Vector2(-14, -22)
			]), Color(1.0, 0.98, 0.9, 0.35))
			draw_colored_polygon(PackedVector2Array([
				Vector2(12, -34), Vector2(24, -42), Vector2(14, -22)
			]), Color(1.0, 0.98, 0.9, 0.35))
		"Mermaid":
			draw_circle(Vector2(0, -50), 1.8, visual._accent)
			draw_line(Vector2(-7, -38), Vector2(7, -38), visual._accent, 1.2)
		"Vampire":
			draw_line(Vector2(-5, -45), Vector2(5, -45), visual._secondary, 1.2)
			draw_circle(Vector2(0, -38.5), 1.2, Color("#ff8fb3"))
		"Spirit":
			draw_circle(Vector2(0, -42), 12.0, Color(visual._accent.r, visual._accent.g, visual._accent.b, 0.12))
			draw_circle(Vector2(-5, -56), 1.4, visual._accent)
			draw_circle(Vector2(6, -59), 1.0, visual._accent)
		"Ancient":
			draw_line(Vector2(-9, -40), Vector2(-16, -36), visual._secondary, 2.0)
			draw_line(Vector2(9, -40), Vector2(16, -36), visual._secondary, 2.0)
			draw_circle(Vector2(0, -46), 2.2, visual._accent)


func _draw_spirit() -> void:
	var hover := sin(visual.anim_time * 1.8) * 3.0
	var center := Vector2(0, -34 + hover)
	draw_circle(center, 18.0, Color(visual._accent.r, visual._accent.g, visual._accent.b, 0.10))
	draw_circle(center, 10.0, Color(visual._primary.r, visual._primary.g, visual._primary.b, 0.9))
	draw_circle(center, 6.5, visual._accent)
	draw_circle(center + Vector2(-2, -2), 2.2, Color(1, 1, 1, 0.9))
	draw_circle(center + Vector2(3.2, 1.4), 1.6, Color("#1c2230"))
	draw_circle(center + Vector2(-4.2, 1.4), 1.6, Color("#1c2230"))
	for index in 3:
		var offset := Vector2(sin(visual.anim_time * 2.2 + index) * 6.0, 8.0 + index * 5.0)
		draw_circle(center + offset, 2.4 - index * 0.5, Color(visual._accent.r, visual._accent.g, visual._accent.b, 0.4 - index * 0.1))


func _draw_monster() -> void:
	match visual.def_id:
		"glade_wisp":
			visual.kind = ActorVisual.Kind.SPIRIT
			_draw_spirit()
		"fae_marauder":
			visual.kind = ActorVisual.Kind.HUMAN
			visual.race = "Demon"
			_draw_human()
		_:
			monster_painter.paint(visual.def_id)


