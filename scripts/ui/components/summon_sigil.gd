class_name SummonSigil
extends Control
## Animated, reusable summoning glyph. Rarity changes only its accent color.

var elapsed := 0.0
var glow := Color("#b58cff")


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * (0.20 + 0.12 * clampf(elapsed / 1.8, 0.0, 1.0))
	var pulse := 1.0 + 0.045 * sin(elapsed * 5.0)
	for ring in range(3):
		var r := radius * (0.66 + float(ring) * 0.22) * pulse
		var direction := 0.18 if ring % 2 == 0 else -0.14
		draw_arc(center, r, elapsed * direction, elapsed * direction + TAU * 0.88, 96, Color(glow.r, glow.g, glow.b, 0.42 - float(ring) * 0.08), 2.0)
	for i in range(8):
		var angle := TAU * float(i) / 8.0 + elapsed * 0.22
		var inner := center + Vector2(cos(angle), sin(angle)) * radius * 0.62
		var outer := center + Vector2(cos(angle), sin(angle)) * radius * 1.08
		draw_line(inner, outer, Color(glow.r, glow.g, glow.b, 0.45), 2.0)
		draw_circle(outer, 3.0 + 1.5 * sin(elapsed * 4.0 + i), Color("#fff0c8"))
	draw_circle(center, 12.0 + 5.0 * sin(elapsed * 6.0), Color(glow.r, glow.g, glow.b, 0.75))
