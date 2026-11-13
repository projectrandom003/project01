extends Node

var encounter_count := 0

func _ready() -> void:
	EventBus.encounter_requested.connect(_on_encounter)
	var player_stub := Node2D.new()
	player_stub.name = "TestPlayer"
	player_stub.add_to_group("player")
	add_child(player_stub)
	var monster := RoamingMonster.new()
	monster.setup("manual_interaction_test", Vector2.ZERO, ContentDB.get_enemy("moonpetal_sprite"), false)
	add_child(monster)
	await get_tree().create_timer(3.25).timeout
	if encounter_count == 0 and not monster.engaged:
		print("[encounter] PASS proximity never starts combat")
	else:
		push_error("[encounter] FAIL monster initiated combat without interaction")
	monster.interact()
	await get_tree().process_frame
	if encounter_count == 1 and monster.engaged:
		print("[encounter] PASS explicit interaction starts combat")
	else:
		push_error("[encounter] FAIL explicit interaction did not start combat")
	print("[encounter] checks complete")
	get_tree().quit(0 if encounter_count == 1 and monster.engaged else 1)


func _on_encounter(_group_id: String, _source: Node) -> void:
	encounter_count += 1
