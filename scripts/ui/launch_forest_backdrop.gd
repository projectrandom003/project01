class_name LaunchForestBackdrop
extends Control
## Shared illustrated, animated opening/loading/title background.

const ART_PATH := "res://assets/ui/backgrounds/launch_forest_background.svg"
var _art: Texture2D
var _time := 0.0
var _particles: Array[Vector3] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art = load(ART_PATH) as Texture2D
	for i in range(46):
		var x := fposmod(float(i) * 173.0 + 29.0, 1920.0)
		var y := fposmod(float(i) * 97.0 + 41.0, 1080.0)
		_particles.append(Vector3(x, y, 0.8 + float(i % 5) * 0.45))
	set_process(true)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var target := Rect2(Vector2.ZERO, size)
	if _art != null:
		draw_texture_rect(_art, target, false)
	else:
		draw_rect(target, Color("#101b20"))
	var w := size.x
	var h := size.y
	# Slow shafts of moonlight drifting through the canopy.
	for i in range(4):
		var drift := sin(_time * 0.16 + float(i) * 1.7) * w * 0.025
		var x := w * (0.49 + float(i) * 0.105) + drift
		var alpha := 0.025 + 0.012 * sin(_time * 0.7 + float(i))
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - w * 0.012, h * 0.12),
			Vector2(x + w * 0.012, h * 0.12),
			Vector2(x + w * 0.095, h * 0.82),
			Vector2(x - w * 0.045, h * 0.82)
		]), Color(0.72, 0.88, 0.76, alpha))
	# Broad, translucent mist ribbons with a gentle lateral drift.
	for i in range(4):
		var y := h * (0.68 + float(i) * 0.075) + sin(_time * 0.22 + float(i)) * 9.0
		var drift := fposmod(_time * (8.0 + float(i) * 3.0) + float(i) * w * 0.31, w + 260.0) - 130.0
		var points := PackedVector2Array([
			Vector2(drift - 260.0, y + 18.0),
			Vector2(drift - 110.0, y - 9.0),
			Vector2(drift + 40.0, y + 5.0),
			Vector2(drift + 220.0, y - 15.0),
			Vector2(drift + 330.0, y + 25.0),
			Vector2(drift + 330.0, y + 52.0),
			Vector2(drift - 260.0, y + 52.0)
		])
		draw_colored_polygon(points, Color(0.70, 0.84, 0.78, 0.035))
	# Fireflies and tiny drifting petals, each with its own phase and speed.
	for i in range(_particles.size()):
		var p: Vector3 = _particles[i]
		var x := fposmod(p.x + sin(_time * 0.24 + float(i)) * 22.0, w)
		var y := fposmod(p.y - _time * (5.0 + p.z * 2.0), h)
		var pulse := 0.45 + 0.55 * sin(_time * (1.1 + p.z * 0.12) + float(i) * 0.8)
		var color := Color("#d9efb6") if i % 3 != 0 else Color("#c4dfff")
		draw_circle(Vector2(x, y), 2.0 + p.z * 0.65, Color(color.r, color.g, color.b, 0.12 + pulse * 0.34))
		if i % 4 == 0:
			draw_line(Vector2(x - 4.0, y - 2.0), Vector2(x + 4.0, y + 2.0), Color(0.84, 0.72, 0.62, 0.18), 1.2)
	# A soft pulse at the path's old glade seal.
	var seal := Vector2(w * 0.57, h * 0.76)
	var pulse := 1.0 + sin(_time * 1.1) * 0.055
	draw_arc(seal, h * 0.075 * pulse, _time * 0.10, _time * 0.10 + TAU * 0.72, 72, Color(0.73, 0.88, 0.68, 0.16), 1.8)
