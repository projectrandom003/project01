extends Node

var did_finish := false

func _ready() -> void:
	var intro := OpeningCinematic.new()
	intro.size = Vector2(1280, 720)
	intro.finished.connect(_on_finished)
	add_child(intro)
	await get_tree().process_frame
	if intro._caption == null or intro._skip_button == null:
		push_error("[opening] Missing caption or skip control.")
		get_tree().quit(1)
		return
	intro._skip_button.pressed.emit()
	if not did_finish:
		push_error("[opening] Skip did not finish the cinematic.")
		get_tree().quit(1)
		return
	print("[opening] OK — prologue renders, captions exist, and Skip advances.")
	get_tree().quit(0)

func _on_finished() -> void:
	did_finish = true
