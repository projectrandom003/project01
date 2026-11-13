extends Node
## Focused quest progression smoke test. Restores the user's in-memory quest
## state before exit and never writes to the save file.

func _ready() -> void:
	await get_tree().process_frame
	var old_quests: Dictionary = GameState.quests.duplicate(true)
	var old_flags: Dictionary = GameState.flags.duplicate(true)
	var failures: Array[String] = []

	# The corrupted treant victory must advance the active main quest to its
	# return-to-Maelin step, which then becomes ready for turn-in.
	GameState.quests = {
		"hollow_roots": { "state": "active", "step": 0, "progress": 0 }
	}
	GameState.record_kill("corrupted_treant", 1)
	if GameState.quest_step_index("hollow_roots") != 1 or not GameState.quest_ready("hollow_roots"):
		failures.append("Corrupted Treant kill did not advance hollow_roots to turn-in.")

	# Unlock and verify the next two boss chapters.
	GameState.quests["hollow_roots"] = { "state": "complete", "step": 2, "progress": 0 }
	if not GameState.start_quest("elder_memory", "elder_maelin"):
		failures.append("elder_memory did not unlock after hollow_roots.")
	GameState.record_kill("elder_hollow", 1)
	if not GameState.quest_ready("elder_memory"):
		failures.append("Elder Hollow kill did not ready elder_memory turn-in.")

	GameState.quests["elder_memory"] = { "state": "complete", "step": 2, "progress": 0 }
	if not GameState.start_quest("matron_bloom", "elder_maelin"):
		failures.append("matron_bloom did not unlock after elder_memory.")
	GameState.record_kill("fallen_matron", 1)
	if not GameState.quest_ready("matron_bloom"):
		failures.append("Fallen Matron kill did not ready matron_bloom turn-in.")

	# NPC markers distinguish available, active and ready-to-turn-in quests.
	GameState.quests = {}
	if GameState.quest_marker_for_npc("elder_maelin") != "available":
		failures.append("Elder Maelin does not show an available quest marker.")
	if not GameState.start_quest("glade_whisper", "elder_maelin"):
		failures.append("Glade quest did not start for marker test.")
	if GameState.quest_marker_for_npc("elder_maelin") != "active":
		failures.append("Elder Maelin active quest marker is missing.")
	GameState.record_kill("mossling", 3)
	if GameState.quest_marker_for_npc("elder_maelin") != "ready":
		failures.append("Elder Maelin ready-to-turn-in marker is missing.")

	# Side quests must auto-complete their opening talk step and count kills.
	GameState.quests = {}
	if GameState.quest_marker_for_npc("merchant_sera") != "available":
		failures.append("Sera does not show an available quest marker.")
	if not GameState.start_quest("sera_caravan", "merchant_sera"):
		failures.append("Sera side quest did not start.")
	GameState.record_kill("thornhound", 2)
	if not GameState.quest_ready("sera_caravan"):
		failures.append("Two thornhound kills did not ready Sera's turn-in.")

	GameState.quests = {}
	if GameState.quest_marker_for_npc("wanderer_pip") != "available":
		failures.append("Pip does not show an available quest marker.")
	if not GameState.start_quest("pip_whispers", "wanderer_pip"):
		failures.append("Pip side quest did not start.")
	GameState.record_kill("glade_wisp", 3)
	if not GameState.quest_ready("pip_whispers"):
		failures.append("Three wisp kills did not ready Pip's turn-in.")

	# Tracking regression: the selected quest must remain pinned, switching
	# quests must replace the old target, and live player movement must update
	# both distance and direction (not use a stale saved position).
	GameState.quests = {
		"glade_whisper": { "state": "active", "step": 1, "progress": 0 },
		"hollow_roots": { "state": "active", "step": 0, "progress": 0 }
	}
	GameState.set_tracked_quest("glade_whisper")
	if GameState.tracked_quest() != "glade_whisper":
		failures.append("Track button did not set the selected quest.")
	GameState.set_tracked_quest("hollow_roots")
	if GameState.tracked_quest() != "hollow_roots":
		failures.append("Switching tracked quests did not replace the previous target.")
	var fake_player := Node2D.new()
	fake_player.name = "QuestTrackingTestPlayer"
	fake_player.add_to_group("player")
	add_child(fake_player)
	fake_player.global_position = Vector2(100.0, 120.0)
	var live_pos := GameState._find_player_position()
	if live_pos.distance_to(fake_player.global_position) > 0.01:
		failures.append("Quest bearing still reads a stale saved player position.")
	var expected_destination := GameState.quest_destination("hollow_roots")
	if GameState.distance_to_tracked() <= 0.0 or GameState.direction_to_tracked().length_squared() < 0.9:
		failures.append("Tracked quest does not produce a live distance and direction.")

	# A kill objective should resolve to the actual roaming boss, not merely
	# the static centre coordinate from the quest data.
	GameState.quests["elder_memory"] = { "state": "active", "step": 0, "progress": 0 }
	GameState.set_tracked_quest("elder_memory")
	var fake_boss := RoamingMonster.new()
	fake_boss.setup("elder_hollow", Vector2(520.0, 640.0), {
		"id": "elder_hollow", "name": "Elder Hollow", "element": "nature", "palette": {}
	}, true)
	add_child(fake_boss)
	await get_tree().process_frame
	if GameState.quest_target_position("elder_memory").distance_to(fake_boss.global_position) > 0.01:
		failures.append("Quest tracking does not follow the live matching boss position.")
	var fake_world := Node2D.new()
	add_child(fake_world)
	var fake_entities := Node2D.new()
	fake_world.add_child(fake_entities)
	var marker := QuestDestinationMarker.new()
	fake_entities.add_child(marker)
	await get_tree().process_frame
	if not marker.visible or marker.global_position.distance_to(fake_boss.global_position) > 0.01:
		failures.append("World quest beacon is not visible at the live target.")
	fake_world.queue_free()
	fake_boss.queue_free()
	GameState.quests = {}
	GameState.flags["tracked_quest"] = "glade_whisper"
	var hud_test := HUD.new()
	add_child(hud_test)
	if hud_test._quest_label == null or not hud_test._quest_label.visible:
		failures.append("HUD hides a manually tracked available quest.")
	GameState.flags.erase("tracked_quest")
	hud_test.queue_free()
	fake_player.remove_from_group("player")
	fake_player.queue_free()

	# Restore in-memory player state and stop the delayed save timer so this
	# diagnostic can never persist its synthetic test quests.
	GameState.quests = old_quests
	GameState.flags = old_flags
	if GameState._save_timer != null:
		GameState._save_timer.stop()

	if failures.is_empty():
		print("[quest-flow] OK — main boss chain + both side-quest kill paths.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("[quest-flow] " + failure)
		get_tree().quit(1)
