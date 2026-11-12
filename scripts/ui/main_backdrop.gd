class_name MainBackdrop
extends Control
## Original procedural title-screen backdrop (Phase 3 placeholder art).
##
## Drawn from primitives using the SAME GreenwardStyle palette as the world so
## the title shares the game's visual identity: deep indigo night sky, warm
## sunrise glow, mossy floating islands, a dark forest silhouette and a few
## drifting firefly / pollen motes. All art is procedural placeholder; there are
## no final assets. `MainBackdrop` stays a Control with mouse_filter = IGNORE and
## a cheap _draw()/_process pair, safe in headless mode.

var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 2.0 or h <= 2.0:
		return

	# Deep indigo night sky, sourced from GreenwardStyle.SKY.
	var sky_top := GreenwardStyle.SKY.night_top
	var sky_bottom := GreenwardStyle.SKY.night_bottom
	var horizon := GreenwardStyle.SKY.dusk_bottom
	for index in 48:
		var t := float(index) / 47.0
		var color := sky_top.lerp(sky_bottom, t)
		if t > 0.72:
			color = color.lerp(horizon, (t - 0.72) / 0.28 * 0.55)
		color.a = 1.0
		draw_rect(Rect2(0, h * t, w, h / 47.0 + 1.0), color)

	# Warm sunrise glow behind the islands (magic ember / lantern gold).
	var glow := GreenwardStyle.MAGIC.ember
	draw_circle(Vector2(w * 0.72, h * 0.42), minf(w, h) * 0.30, Color(glow.r, glow.g, glow.b, 0.045))
	draw_circle(Vector2(w * 0.72, h * 0.42), minf(w, h) * 0.17, Color(glow.r, glow.g, glow.b, 0.075))

	# Stars.
	for index in 64:
		var x := fmod(float(index) * 137.0 + 31.0, w)
		var y := fmod(float(index) * 83.0 + 17.0, h * 0.62)
		var alpha := 0.18 + 0.22 * sin(_time * 0.7 + index)
		draw_circle(Vector2(x, y), 1.0 + float(index % 3) * 0.35, Color(0.86, 0.93, 1.0, alpha))

	# Floating islands: dark stone silhouettes with a soft mossy canopy rim.
	var stone_dark := GreenwardStyle.STONE.dark
	var canopy_deep := GreenwardStyle.CANOPY.deep
	var canopy_mid := GreenwardStyle.CANOPY.mid
	var islands := [
		{ "center": Vector2(w * 0.74, h * 0.31), "size": 1.15, "phase": 0.0 },
		{ "center": Vector2(w * 0.88, h * 0.19), "size": 0.62, "phase": 1.7 },
		{ "center": Vector2(w * 0.60, h * 0.16), "size": 0.45, "phase": 3.1 },
	]
	for island in islands:
		var center: Vector2 = island["center"]
		var scale_value: float = float(island["size"])
		var drift := sin(_time * 0.22 + float(island["phase"])) * 5.0
		center.y += drift
		var span := 150.0 * scale_value
		var depth := 54.0 * scale_value
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-span, 0),
			center + Vector2(-span * 0.72, depth * 0.42),
			center + Vector2(-span * 0.30, depth),
			center + Vector2(span * 0.10, depth * 1.16),
			center + Vector2(span * 0.52, depth * 0.62),
			center + Vector2(span, 0),
			center + Vector2(span * 0.54, -depth * 0.34),
			center + Vector2(-span * 0.48, -depth * 0.30),
		]), stone_dark)
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-span, 0),
			center + Vector2(-span * 0.52, -depth * 0.34),
			center + Vector2(0, -depth * 0.48),
			center + Vector2(span * 0.56, -depth * 0.30),
			center + Vector2(span, 0),
			center + Vector2(span * 0.40, -depth * 0.08),
			center + Vector2(-span * 0.42, -depth * 0.06),
		]), canopy_deep)
		for tree_index in 7:
			var tx := -span * 0.72 + float(tree_index) * span * 0.24
			var th := (14.0 + float((tree_index * 7) % 5) * 4.0) * scale_value
			draw_line(center + Vector2(tx, -depth * 0.20), center + Vector2(tx, -depth * 0.20 - th), GreenwardStyle.INK, 1.8 * scale_value)
			draw_circle(center + Vector2(tx, -depth * 0.20 - th), 7.0 * scale_value, canopy_mid)

	# Forest silhouette along the bottom edge.
	var tree_count := 26
	for index in tree_count:
		var x := float(index) / float(tree_count - 1) * w
		var sway := sin(_time * 0.5 + index * 0.7) * 3.0
		var height := h * (0.10 + 0.035 * float((index * 11) % 5))
		draw_line(Vector2(x, h), Vector2(x + sway, h - height), GreenwardStyle.CANOPY.deep, 5.0)
		draw_circle(Vector2(x + sway, h - height), 18.0 + float(index % 4) * 6.0, GreenwardStyle.CANOPY.deep)

	# Ground haze.
	var bg := GreenwardStyle.UI.bg
	draw_rect(Rect2(0, h * 0.90, w, h * 0.10), Color(bg.r, bg.g, bg.b, 0.72))

	# Drifting firefly / pollen motes — the same accents the world uses at night.
	_draw_motes(w, h)


func _draw_motes(w: float, h: float) -> void:
	var firefly := GreenwardStyle.ACCENTS.firefly
	var petal := GreenwardStyle.ACCENTS.petal_alt
	for index in 10:
		var fx := fmod(float(index) * 197.0 + 53.0 + sin(_time * 0.3 + float(index)) * 40.0, w)
		var fy := h * 0.35 + fmod(float(index) * 89.0 + 21.0 + cos(_time * 0.4 + float(index) * 1.3) * 60.0, h * 0.5)
		var pulse := 0.35 + 0.35 * sin(_time * 2.0 + float(index) * 1.7)
		var c := firefly if index % 2 == 0 else petal
		draw_circle(Vector2(fx, fy), 4.5, Color(c.r, c.g, c.b, pulse * 0.14))
		draw_circle(Vector2(fx, fy), 2.0, Color(c.r, c.g, c.b, pulse * 0.55))
