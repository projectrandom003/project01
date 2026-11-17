class_name ActorCharacterEffectsComponent
extends Node2D
## Owns character-identity-specific additive combat VFX, separate from body rendering.

var visual: ActorVisual


func bind(owner_visual: ActorVisual) -> void:
	visual = owner_visual
	position = Vector2.ZERO
	z_index = 2
	queue_redraw()


func _draw() -> void:
	if visual == null:
		return
	if visual.character_id == "kael":
		_draw_kael_combat_fx()
	elif visual.character_id == "lilith":
		_draw_lilith_spectral_fx()


func _draw_kael_combat_fx() -> void:
	if visual.animator == null:
		return
	var crimson := Color("#ff3158")
	var hot_red := Color("#ff9aab")
	var deep_red := Color("#8d1639")
	var state := visual.animator.state
	var frame_count := float(maxi(1, visual.animator.frame_count()))
	var progress := clampf((float(visual.animator.frame) + visual.animator.elapsed * visual.animator.fps() * visual.animator.speed_scale) / frame_count, 0.0, 1.0)
	var center := Vector2(0.0, -39.0 * visual.visual_scale)

	if state == ActorVisual.S_IDLE:
		# A few slow, individually phased embers keep the still pose alive.
		for i in 5:
			var phase := visual.anim_time * (0.72 + float(i % 3) * 0.13) + float(i) * 1.31
			var p := Vector2(cos(phase) * (15.0 + float(i % 2) * 5.0), -17.0 - fposmod(visual.anim_time * (5.0 + float(i % 3)) + float(i) * 11.0, 52.0))
			var alpha := 0.24 + 0.28 * (0.5 + 0.5 * sin(phase * 1.7))
			draw_circle(p * visual.visual_scale, (0.8 + float(i % 2) * 0.45) * visual.visual_scale, Color(crimson.r, crimson.g, crimson.b, alpha))
			draw_line(p * visual.visual_scale, (p + Vector2(-1.2, 2.8)) * visual.visual_scale, Color(hot_red.r, hot_red.g, hot_red.b, alpha * 0.7), 0.8 * visual.visual_scale)
		# A restrained ember glow pulses around the sword hand / chest.
		var pulse := 0.5 + 0.5 * sin(visual.anim_time * 2.4)
		draw_circle(center + Vector2(8, 4) * visual.visual_scale, (5.0 + pulse * 2.0) * visual.visual_scale, Color(crimson.r, crimson.g, crimson.b, 0.035 + pulse * 0.035))
	elif state == ActorVisual.S_WALK or state == ActorVisual.S_RUN:
		var stride := 1.0 if state == ActorVisual.S_RUN else 0.65
		for i in 4:
			var phase := visual.anim_time * (8.5 if state == ActorVisual.S_RUN else 6.0) + float(i) * 1.7
			var p := Vector2(-10.0 - fposmod(visual.anim_time * 13.0 + float(i) * 9.0, 15.0), -4.0 - fposmod(visual.anim_time * (17.0 + float(i)) + float(i) * 13.0, 23.0))
			draw_circle(p * visual.visual_scale, (0.75 + 0.35 * sin(phase)) * visual.visual_scale, Color(crimson.r, crimson.g, crimson.b, 0.30 * stride))
	elif state == ActorVisual.S_ATTACK:
		# The bright crescent appears only across the active blade frames.
		var slash := smoothstep(0.27, 0.48, progress) * (1.0 - smoothstep(0.67, 0.86, progress))
		if slash > 0.01:
			var sweep := lerpf(-0.95, 1.05, clampf((progress - 0.27) / 0.52, 0.0, 1.0))
			var radius := 28.0 * visual.visual_scale
			var slash_center := Vector2(7.0, -43.0) * visual.visual_scale
			draw_arc(slash_center, radius, sweep - 1.05, sweep + 0.78, 28, Color(crimson.r, crimson.g, crimson.b, 0.88 * slash), 3.0 * visual.visual_scale, true)
			draw_arc(slash_center, radius - 3.5 * visual.visual_scale, sweep - 0.92, sweep + 0.62, 24, Color(hot_red.r, hot_red.g, hot_red.b, 0.72 * slash), 1.2 * visual.visual_scale, true)
			var tip := slash_center + Vector2(cos(sweep + 0.78), sin(sweep + 0.78)) * radius
			draw_circle(tip, 2.0 * visual.visual_scale * slash, Color(1.0, 0.82, 0.86, slash))
		var impact := smoothstep(0.40, 0.48, progress) * (1.0 - smoothstep(0.53, 0.63, progress))
		if impact > 0.01:
			draw_circle(Vector2(10, -36) * visual.visual_scale, (8.0 + 12.0 * impact) * visual.visual_scale, Color(crimson.r, crimson.g, crimson.b, 0.20 * impact))
			for i in 7:
				var a := TAU * float(i) / 7.0 + visual.anim_time * 0.8
				var ray := Vector2(cos(a), sin(a))
				draw_line(Vector2(10, -36) * visual.visual_scale + ray * 5.0 * visual.visual_scale, Vector2(10, -36) * visual.visual_scale + ray * (12.0 + 8.0 * impact) * visual.visual_scale, Color(hot_red.r, hot_red.g, hot_red.b, 0.8 * impact), 1.1 * visual.visual_scale)
	elif state == ActorVisual.S_CAST:
		# Ground seal expands, rotates and resolves into a rising crimson flare.
		var gather := smoothstep(0.0, 0.34, progress)
		var release := smoothstep(0.56, 0.82, progress) * (1.0 - smoothstep(0.9, 1.0, progress))
		var ring_radius := lerpf(9.0, 31.0, gather) * visual.visual_scale
		var ring_alpha := 0.20 + 0.48 * (1.0 - release)
		var ground := Vector2(0, -2.0) * visual.visual_scale
		draw_arc(ground, ring_radius, visual.anim_time * 0.9, visual.anim_time * 0.9 + TAU, 36, Color(crimson.r, crimson.g, crimson.b, ring_alpha), 1.8 * visual.visual_scale, true)
		draw_arc(ground, ring_radius * 0.72, -visual.anim_time * 1.4, -visual.anim_time * 1.4 + TAU, 32, Color(hot_red.r, hot_red.g, hot_red.b, ring_alpha * 0.62), 0.9 * visual.visual_scale, true)
		for i in 8:
			var a := TAU * float(i) / 8.0 + visual.anim_time * 0.7
			var p := ground + Vector2(cos(a), sin(a) * 0.42) * ring_radius
			draw_circle(p, 1.35 * visual.visual_scale, Color(hot_red.r, hot_red.g, hot_red.b, ring_alpha))
		if release > 0.01:
			var pillar_height := 70.0 * release * visual.visual_scale
			draw_line(Vector2(0, -5) * visual.visual_scale, Vector2(0, -5) * visual.visual_scale - Vector2(0, pillar_height), Color(crimson.r, crimson.g, crimson.b, 0.38 * release), 5.0 * visual.visual_scale)
			draw_line(Vector2(0, -5) * visual.visual_scale, Vector2(0, -5) * visual.visual_scale - Vector2(0, pillar_height * 0.82), Color(hot_red.r, hot_red.g, hot_red.b, 0.78 * release), 1.5 * visual.visual_scale)
		for i in 9:
			var p := Vector2(sin(visual.anim_time * 2.0 + float(i) * 2.1) * (9.0 + float(i % 3) * 5.0), -8.0 - fposmod(visual.anim_time * (24.0 + float(i)) + float(i) * 13.0, 78.0))
			draw_circle(p * visual.visual_scale, 1.0 * visual.visual_scale, Color(hot_red.r, hot_red.g, hot_red.b, 0.68 * release + 0.12))
	elif state == ActorVisual.S_DAMAGE:
		var hurt := 1.0 - progress
		if hurt > 0.01:
			draw_circle(center, 18.0 * visual.visual_scale, Color(crimson.r, crimson.g, crimson.b, 0.10 * hurt))
			for i in 5:
				var a := TAU * float(i) / 5.0
				draw_line(center + Vector2(cos(a), sin(a)) * 8.0 * visual.visual_scale, center + Vector2(cos(a), sin(a)) * 17.0 * visual.visual_scale, Color(hot_red.r, hot_red.g, hot_red.b, 0.55 * hurt), 1.0 * visual.visual_scale)
	elif state == ActorVisual.S_VICTORY:
		var glow := 0.45 + 0.35 * sin(visual.anim_time * 3.0)
		for i in 7:
			var a := TAU * float(i) / 7.0 + visual.anim_time * 0.35
			var p := center + Vector2(cos(a) * 23.0, sin(a) * 29.0) * visual.visual_scale
			draw_circle(p, 1.2 * visual.visual_scale, Color(hot_red.r, hot_red.g, hot_red.b, glow))
	elif state == ActorVisual.S_DEFEAT:
		for i in 8:
			var p := Vector2(cos(float(i) * 2.4) * (8.0 + float(i % 3) * 4.0), -4.0 - fposmod(visual.anim_time * 8.0 + float(i) * 11.0, 42.0))
			draw_circle(p * visual.visual_scale, 0.8 * visual.visual_scale, Color(deep_red.r, deep_red.g, deep_red.b, 0.42))

func _draw_lilith_spectral_fx() -> void:
	if visual.animator == null:
		return
	var state := visual.animator.state
	var frame_count := float(maxi(1, visual.animator.frame_count()))
	var progress := clampf((float(visual.animator.frame) + visual.animator.elapsed * visual.animator.fps() * visual.animator.speed_scale) / frame_count, 0.0, 1.0)
	var cyan := Color("#74dcff")
	var ice := Color("#d8f6ff")
	var blue := Color("#398cff")
	var violet := Color("#8c8dff")
	var center := Vector2(0.0, -35.0 * visual.visual_scale)

	if state == ActorVisual.S_IDLE:
		var pulse := 0.5 + 0.5 * sin(visual.anim_time * 2.1)
		draw_circle(center + Vector2(0, 3) * visual.visual_scale, (13.0 + pulse * 3.0) * visual.visual_scale, Color(cyan.r, cyan.g, cyan.b, 0.045 + pulse * 0.035))
		for i in 7:
			var phase := visual.anim_time * (0.48 + float(i % 3) * 0.11) + float(i) * TAU / 7.0
			var orbit := Vector2(cos(phase) * (15.0 + 2.5 * sin(phase * 1.7)), sin(phase * 1.25) * 13.0 - 5.0)
			var p := center + orbit * visual.visual_scale
			var alpha := 0.25 + 0.30 * (0.5 + 0.5 * sin(phase * 1.8))
			draw_circle(p, (1.0 + 0.45 * pulse) * visual.visual_scale, Color(ice.r, ice.g, ice.b, alpha))
			draw_line(p, p + Vector2(-1.0, -3.5) * visual.visual_scale, Color(cyan.r, cyan.g, cyan.b, alpha * 0.65), 0.8 * visual.visual_scale)
	elif state == ActorVisual.S_WALK or state == ActorVisual.S_RUN:
		var strength := 1.0 if state == ActorVisual.S_RUN else 0.68
		for i in 6:
			var phase := visual.anim_time * (7.0 + float(i % 3)) + float(i) * 1.8
			var p := Vector2(-9.0 - fposmod(visual.anim_time * 10.0 + float(i) * 8.0, 17.0), -7.0 - fposmod(visual.anim_time * (15.0 + float(i % 3)) + float(i) * 12.0, 34.0))
			draw_circle(p * visual.visual_scale, (0.75 + 0.35 * sin(phase)) * visual.visual_scale, Color(cyan.r, cyan.g, cyan.b, 0.34 * strength))
			draw_line(p * visual.visual_scale, (p + Vector2(-3.0, 2.0)) * visual.visual_scale, Color(ice.r, ice.g, ice.b, 0.22 * strength), 0.8 * visual.visual_scale)
	elif state == ActorVisual.S_ATTACK:
		var sweep_alpha := smoothstep(0.16, 0.42, progress) * (1.0 - smoothstep(0.68, 0.91, progress))
		if sweep_alpha > 0.01:
			var angle := lerpf(-1.25, 0.72, clampf((progress - 0.16) / 0.70, 0.0, 1.0))
			var origin := Vector2(5.0, -42.0) * visual.visual_scale
			var radius := 29.0 * visual.visual_scale
			draw_arc(origin, radius, angle - 1.08, angle + 0.72, 32, Color(blue.r, blue.g, blue.b, 0.82 * sweep_alpha), 3.2 * visual.visual_scale, true)
			draw_arc(origin, radius - 4.0 * visual.visual_scale, angle - 0.92, angle + 0.55, 28, Color(ice.r, ice.g, ice.b, 0.78 * sweep_alpha), 1.25 * visual.visual_scale, true)
			draw_circle(origin + Vector2(cos(angle + 0.72), sin(angle + 0.72)) * radius, 2.0 * visual.visual_scale * sweep_alpha, Color(ice.r, ice.g, ice.b, sweep_alpha))
			var impact := smoothstep(0.43, 0.51, progress) * (1.0 - smoothstep(0.57, 0.69, progress))
			if impact > 0.01:
				draw_circle(origin, (7.0 + 15.0 * impact) * visual.visual_scale, Color(cyan.r, cyan.g, cyan.b, 0.18 * impact))
				for i in 8:
					var ray := Vector2.RIGHT.rotated(TAU * float(i) / 8.0 + visual.anim_time)
					draw_line(origin + ray * 5.0 * visual.visual_scale, origin + ray * (13.0 + 8.0 * impact) * visual.visual_scale, Color(ice.r, ice.g, ice.b, 0.68 * impact), 1.0 * visual.visual_scale)
	elif state == ActorVisual.S_CAST:
		var gather := smoothstep(0.0, 0.38, progress)
		var release := smoothstep(0.56, 0.82, progress) * (1.0 - smoothstep(0.9, 1.0, progress))
		var ground := Vector2(0, -3.0) * visual.visual_scale
		var radius := lerpf(8.0, 30.0, gather) * visual.visual_scale
		var spin := visual.anim_time * 0.75
		draw_arc(ground, radius, spin, spin + TAU, 40, Color(cyan.r, cyan.g, cyan.b, 0.28 + 0.46 * (1.0 - release)), 1.8 * visual.visual_scale, true)
		draw_arc(ground, radius * 0.72, -spin * 1.7, -spin * 1.7 + TAU, 36, Color(violet.r, violet.g, violet.b, 0.42), 1.0 * visual.visual_scale, true)
		for i in 8:
			var a := TAU * float(i) / 8.0 + spin
			var ray := Vector2(cos(a), sin(a) * 0.48) * radius
			draw_line(ground + ray * 0.78, ground + ray, Color(ice.r, ice.g, ice.b, 0.7), 1.1 * visual.visual_scale)
		if release > 0.01:
			for i in 12:
				var a := TAU * float(i) / 12.0 + spin * 0.6
				var p := Vector2(cos(a) * (8.0 + float(i % 3) * 5.0), -8.0 - fposmod(visual.anim_time * 19.0 + float(i) * 9.0, 67.0))
				draw_circle(p * visual.visual_scale, 1.1 * visual.visual_scale, Color(ice.r, ice.g, ice.b, 0.72 * release))
			draw_line(Vector2(0, -5) * visual.visual_scale, Vector2(0, -66) * visual.visual_scale, Color(cyan.r, cyan.g, cyan.b, 0.24 * release), 7.0 * visual.visual_scale)
			draw_line(Vector2(0, -5) * visual.visual_scale, Vector2(0, -58) * visual.visual_scale, Color(ice.r, ice.g, ice.b, 0.56 * release), 1.4 * visual.visual_scale)
	elif state == ActorVisual.S_DAMAGE:
		var recoil := 1.0 - progress
		draw_arc(center, (13.0 + 17.0 * (1.0 - recoil)) * visual.visual_scale, 0.0, TAU, 32, Color(cyan.r, cyan.g, cyan.b, 0.42 * recoil), 1.8 * visual.visual_scale, true)
		for i in 6:
			var a := TAU * float(i) / 6.0
			var ray := Vector2.RIGHT.rotated(a)
			draw_line(center + ray * 8.0 * visual.visual_scale, center + ray * (15.0 + 8.0 * recoil) * visual.visual_scale, Color(ice.r, ice.g, ice.b, 0.48 * recoil), 1.0 * visual.visual_scale)
	elif state == ActorVisual.S_VICTORY:
		for i in 9:
			var a := TAU * float(i) / 9.0 + visual.anim_time * 0.42
			var p := center + Vector2(cos(a) * 24.0, sin(a) * 29.0) * visual.visual_scale
			draw_circle(p, (1.1 + 0.45 * sin(visual.anim_time * 2.0 + float(i))) * visual.visual_scale, Color(ice.r, ice.g, ice.b, 0.58))
	elif state == ActorVisual.S_DEFEAT:
		for i in 10:
			var p := Vector2(cos(float(i) * 2.4) * (7.0 + float(i % 3) * 5.0), -5.0 - fposmod(visual.anim_time * 6.0 + float(i) * 9.0, 48.0))
			draw_circle(p * visual.visual_scale, 1.0 * visual.visual_scale, Color(cyan.r, cyan.g, cyan.b, 0.34))
