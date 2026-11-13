extends Control
## Authored Greenward combat background with lightweight ambient overlays.
var _time := 0.0
var _redraw_accumulator := 0.0
var _art: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art = load("res://assets/backgrounds/greenward_battle.svg") as Texture2D

func _process(delta: float) -> void:
	_time += delta
	_redraw_accumulator += delta
	if _redraw_accumulator >= 1.0 / 30.0:
		_redraw_accumulator = fmod(_redraw_accumulator, 1.0 / 30.0)
		queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if _art != null:
		draw_texture_rect(_art, Rect2(Vector2.ZERO, size), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#17251d"))
	# Thin drifting ground mist and sparse fireflies remain animated.
	for i in range(4):
		var y := size.y * (0.66 + float(i) * 0.065)
		var drift := sin(_time * 0.22 + float(i)) * 22.0
		draw_rect(Rect2(drift - 90.0, y, size.x + 180.0, size.y * 0.035), Color(0.76, 0.88, 0.68, 0.035))
	for i in range(20):
		var x := fposmod(float(i) * 97.0 + sin(_time * 0.4 + i) * 26.0, size.x)
		var y := fposmod(float(i) * 51.0 - _time * (4.0 + float(i % 3)), size.y * 0.78)
		draw_circle(Vector2(x, y), 1.5, Color(0.82, 0.94, 0.62, 0.28 + 0.16 * sin(_time + i)))
