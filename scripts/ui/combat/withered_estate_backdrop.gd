extends Control
## Layered ruined conservatory backdrop with low-cost atmospheric animation.
## Architecture and floor are authored in SVG; this script adds living fog,
## light shafts, ritual pulse and drifting corruption motes.
var _clock := 0.0
var _redraw_accumulator := 0.0
var _art: Texture2D
var _fog_phase := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art = load("res://assets/backgrounds/withered_estate_battle.svg") as Texture2D

func _process(delta: float) -> void:
	_clock += delta
	_fog_phase = fposmod(_fog_phase + delta * 0.018, 1.0)
	_redraw_accumulator += delta
	if _redraw_accumulator >= 1.0 / 24.0:
		_redraw_accumulator = fmod(_redraw_accumulator, 1.0 / 24.0)
		queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if _art != null:
		draw_texture_rect(_art, Rect2(Vector2.ZERO, size), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#100b1b"))

	# Narrow, shifting shafts of moonlight through the shattered glass roof.
	var beam_alpha := 0.045 + 0.018 * sin(_clock * 0.42)
	for beam in range(3):
		var x := size.x * (0.22 + float(beam) * 0.28) + sin(_clock * 0.11 + beam) * size.x * 0.018
		var width := size.x * (0.045 if beam == 1 else 0.032)
		var beam_color := Color(0.72, 0.58, 0.88, beam_alpha)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - width, 0), Vector2(x + width, 0),
			Vector2(x + width * 2.8, size.y * 0.72),
			Vector2(x - width * 1.6, size.y * 0.72)
		]), beam_color)

	# Wide translucent ribbons drift at different speeds to create parallax fog.
	for layer in range(3):
		var y := size.y * (0.60 + float(layer) * 0.105)
		var drift := fposmod(_fog_phase * (0.65 + layer * 0.22) + float(layer) * 0.31, 1.0)
		var x := drift * size.x
		var alpha := 0.035 + 0.012 * sin(_clock * 0.55 + layer)
		var fog := Color(0.67, 0.49, 0.75, alpha)
		var width := size.x * 0.44
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - width, y + 12), Vector2(x - width * 0.55, y - 14),
			Vector2(x + width * 0.30, y - 6), Vector2(x + width, y + 22),
			Vector2(x + width * 0.4, y + 34)
		]), fog)

	# Ground sigil responds gently to the Matron's corruption.
	var center := Vector2(size.x * 0.50, size.y * 0.79)
	var pulse := 1.0 + 0.035 * sin(_clock * 1.7)
	for radius in [size.y * 0.105, size.y * 0.145, size.y * 0.185]:
		draw_arc(center, radius * pulse, _clock * 0.018, TAU + _clock * 0.018, 96, Color(0.72, 0.30, 0.96, 0.27), 1.8, true)
	for i in range(24):
		var phase := float(i) * 1.73
		var x := fposmod(float(i) * 137.0 + sin(_clock * 0.35 + phase) * 24.0, size.x)
		var y := fposmod(float(i) * 71.0 - _clock * (5.0 + float(i % 4) * 1.7), size.y)
		var flicker := 0.55 + 0.45 * sin(_clock * 2.2 + phase)
		draw_circle(Vector2(x, y), 1.2 + float(i % 3) * 0.65, Color(0.84, 0.58, 1.0, 0.22 + flicker * 0.28))
