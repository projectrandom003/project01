extends Node

func _ready() -> void:
	var screen := MapScreen.new()
	screen.size = Vector2(1280, 720)
	add_child(screen)
	await get_tree().process_frame
	if screen._map_canvas == null:
		push_error("[map-ui] Map canvas did not build.")
		get_tree().quit(1)
		return
	screen._map_canvas.queue_redraw()
	print("[map-ui] OK — full map screen and live world-map canvas instantiated.")
	get_tree().quit(0)
