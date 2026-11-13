extends Control

func _ready() -> void:
	var combat_script := load("res://scripts/ui/screens/combat_screen.gd")
	var screen: Control = combat_script.new()
	screen.group_id = "fallen_matron_encounter"
	add_child(screen)
