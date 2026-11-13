extends Node

const IntroScript = preload("res://scripts/ui/opening_cinematic.gd")

func _ready() -> void:
	var intro = IntroScript.new()
	intro.size = Vector2(1280, 720)
	add_child(intro)
	await get_tree().process_frame
	if intro._protagonists.size() != 2:
		push_error("[opening-ui] Gerald and Lilith were not added to the prologue.")
		get_tree().quit(1)
		return
	print("[opening-ui] OK — opening prologue uses registered Gerald and Lilith character art.")
	intro._finish()
	get_tree().quit(0)
