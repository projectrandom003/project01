extends Node

func _ready() -> void:
	var checks := [
		{ "id": "corrupted_treant", "node": "GreenwardRootArenaBackdrop" },
		{ "id": "elder_hollow", "node": "GreenwardRootArenaBackdrop" },
		{ "id": "fallen_matron_encounter", "node": "WitheredEstateBackdrop" },
		{ "id": "glade_mossling_pack", "node": "GreenwardForestBackdrop" }
	]
	var failures: Array[String] = []
	for check in checks:
		var stage := Battlefield.new()
		stage.arena_id = str(check.id)
		stage.size = Vector2(960, 360)
		add_child(stage)
		await get_tree().process_frame
		if stage.get_node_or_null(str(check.node)) == null:
			failures.append("Arena %s did not create %s." % [str(check.id), str(check.node)])
		stage.queue_free()
		await get_tree().process_frame
	if failures.is_empty():
		print("[arena-ui] OK — Greenward boss arenas and Withered Estate select correctly.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("[arena-ui] " + failure)
		get_tree().quit(1)
