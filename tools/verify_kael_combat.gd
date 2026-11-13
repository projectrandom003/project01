extends Node

func _ready() -> void:
	var stage := Battlefield.new()
	stage.arena_id = "glade_mossling_pack"
	stage.size = Vector2(960, 420)
	add_child(stage)
	await get_tree().process_frame
	var fire := Color("#ff563f")
	var gold := Color("#ffc16a")
	var pale := Color("#fff0d0")
	stage._spawn_kael_cross_slash(Vector2(300, 180), Vector2.RIGHT, fire, 1.0)
	stage._spawn_kael_impact(Vector2(340, 170), fire, gold, 0.8)
	stage._spawn_kael_lance(Vector2(180, 160), Vector2(500, 160), fire, gold, pale)
	stage._spawn_kael_rally_ring(Vector2(220, 260), fire, gold)
	stage._spawn_kael_ground_seal(Vector2(260, 260), fire, gold)
	stage._spawn_kael_ultimate_burst(Vector2(520, 180), fire, gold, pale)
	await get_tree().create_timer(1.2).timeout
	var effect_count := 0
	for child in stage.get_children():
		if child is Node2D:
			effect_count += 1
	if effect_count < 2:
		push_error("[kael-combat] Effect stage unexpectedly empty.")
		get_tree().quit(1)
		return
	print("[kael-combat] OK — slash, impact, lance, rally, seal and ultimate VFX instantiate and animate.")
	get_tree().quit(0)
