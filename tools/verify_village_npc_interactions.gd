extends Node
## Headless integration test for Greenward's live NPC proximity and dialogue path.

const WORLD_SCENE: PackedScene = preload("res://scenes/world/greenward_world.tscn")
var checks := 0
var failures := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := WORLD_SCENE.instantiate()
	add_child(world)
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player") as Player
	_check(player != null, "world spawns a Player")
	if player == null:
		_finish()
		return
	var expected := {
		"elder_maelin": {"dialogue": "elder_maelin", "anchor": Vector2(-89.6, 185.6)},
		"merchant_sera": {"dialogue": "merchant_sera", "anchor": Vector2(130, 336)},
		"wanderer_pip": {"dialogue": "wanderer_pip", "anchor": Vector2(-160, 320)},
	}
	var village := world.get_node_or_null("Village")
	for npc_id in expected:
		var npc: WorldNPC = null
		for node in get_tree().get_nodes_in_group("interactables"):
			if node is WorldNPC and node.npc_id == npc_id:
				npc = node
				break
		_check(npc != null, "live world contains " + npc_id)
		if npc == null:
			continue
		_check(npc.can_interact(), npc_id + " is enabled")
		_check(npc.is_in_group("interactables"), npc_id + " registers as interactable")
		var spec: Dictionary = expected[npc_id]
		_check(npc.dialogue_id == str(spec["dialogue"]), npc_id + " is wired to its intended dialogue resource")
		_check(npc.global_position.distance_to(spec["anchor"]) <= 3.0, npc_id + " is placed at its authored village NPC anchor")
		player.global_position = npc.global_position + Vector2(0, 26)
		player.call("_scan_for_interactable")
		_check(player.nearby_interactable == npc, "player selects nearby " + npc_id)
		if player.nearby_interactable != npc:
			continue
		var received := [""]
		var callback := func(dialogue_id: String) -> void:
			received[0] = dialogue_id
		EventBus.dialogue_requested.connect(callback)
		player.try_interact()
		if EventBus.dialogue_requested.is_connected(callback):
			EventBus.dialogue_requested.disconnect(callback)
		_check(received[0] == npc.dialogue_id, npc_id + " emits its configured dialogue")
	print("[village_npc_interactions] %s — %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	world.queue_free()
	await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[village_npc_interactions] FAIL: " + label)

func _finish() -> void:
	print("[village_npc_interactions] FAIL — %d checks, %d failures" % [checks, failures])
	get_tree().quit(1)
