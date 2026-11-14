class_name FeaturedSummonStage
extends Control
## Procedural animated ritual frame around the featured character portrait.
## The stage is a reusable scene node; only its rarity accent is data-driven.

var accent := Color("#b58cff")
var elapsed := 0.0


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _draw() -> void:
	var c := size * Vector2(0.5, 0.53)
	var radius := minf(size.x * 0.43, size.y * 0.46)
	var pulse := 1.0 + sin(elapsed * 1.35) * 0.018
	draw_circle(c, radius * 0.94, Color(accent.r, accent.g, accent.b, 0.035))
	for ring in range(4):
		var r := radius * (0.43 + ring * 0.145) * pulse
		var direction := 0.035 if ring % 2 == 0 else -0.025
		draw_arc(c, r, elapsed * direction, elapsed * direction + TAU * 0.91, 96, Color(accent.r, accent.g, accent.b, 0.30 - ring * 0.045), 1.4)
	for i in range(12):
		var a := TAU * float(i) / 12.0 + elapsed * 0.025
		var inner := c + Vector2.RIGHT.rotated(a) * radius * 0.48
		var outer := c + Vector2.RIGHT.rotated(a) * radius * 0.72
		draw_line(inner, outer, Color(accent.r, accent.g, accent.b, 0.34), 1.2)
		draw_circle(outer, 2.0 if i % 3 else 3.0, Color("#f4dfb1", 0.78))
	# Shallow ritual dais anchors the portrait visually.
	var floor_y := size.y * 0.89
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x * 0.16, floor_y), Vector2(size.x * 0.5, floor_y - 18),
		Vector2(size.x * 0.84, floor_y), Vector2(size.x * 0.5, floor_y + 18)
	]), Color(0.13, 0.12, 0.22, 0.88))
	draw_polyline(PackedVector2Array([
		Vector2(size.x * 0.16, floor_y), Vector2(size.x * 0.5, floor_y - 18),
		Vector2(size.x * 0.84, floor_y), Vector2(size.x * 0.5, floor_y + 18),
		Vector2(size.x * 0.16, floor_y)
	]), Color(accent.r, accent.g, accent.b, 0.52), 1.5)
