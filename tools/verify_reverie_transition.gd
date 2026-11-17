extends SceneTree

func _init() -> void:
	await process_frame
	var state = root.get_node_or_null("/root/GameState")
	var game_scene := load("res://scenes/game.tscn") as PackedScene
	if state == null or game_scene == null:
		push_error("Transition verification could not resolve GameState or game.tscn.")
		quit(1)
		return

	var game := game_scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var session = game.get_node_or_null("WorldSession")
	if session == null:
		push_error("Game scene is missing WorldSession.")
		quit(1)
		return

	# Establish the source region through the real session API. Merely changing
	# GameState after GameScreen has already built Greenward does not change the
	# session's current_region_id or the active world instance.
	var existing_world = session.get("world")
	if existing_world != null and is_instance_valid(existing_world):
		existing_world.queue_free()
		await process_frame
	var start_world = session.call("build_world", "castle_royal_gardens", "")
	if start_world == null:
		push_error("Could not build Castle Royal Gardens as the source region.")
		quit(1)
		return
	state.call("set_active_world", "castle_royal_gardens")
	await process_frame
	await process_frame

	var forward: Dictionary = session.call("transition_to", "gothic_castle_boss_zone", "royal_gate")
	print("FORWARD_OK=", forward.get("ok", false), " REGION=", forward.get("region_id", ""))
	if not bool(forward.get("ok", false)):
		push_error("Royal Gardens -> Gothic Castle transition failed: " + str(forward.get("reason", "unknown reason")))
		quit(1)
		return
	await process_frame
	await process_frame
	print("REGION_NOW=", state.get("player_region"))
	var active_world = session.get("world")
	var player_exists := active_world != null and active_world.get("player") != null
	print("WORLD=", active_world.name if active_world != null else "null", " PLAYER=", player_exists)
	if active_world == null or str(session.get("current_region_id")) != "gothic_castle_boss_zone" or not player_exists:
		push_error("Gothic Castle did not become the active playable world.")
		quit(1)
		return

	var backward: Dictionary = session.call("transition_to", "castle_royal_gardens", "boss_path")
	print("RETURN_OK=", backward.get("ok", false), " REGION=", backward.get("region_id", ""))
	if not bool(backward.get("ok", false)):
		push_error("Gothic Castle -> Royal Gardens return transition failed: " + str(backward.get("reason", "unknown reason")))
		quit(1)
		return
	await process_frame
	await process_frame
	print("REGION_BACK=", state.get("player_region"))
	if str(session.get("current_region_id")) != "castle_royal_gardens":
		push_error("Return transition did not restore Castle Royal Gardens.")
		quit(1)
		return
	print("REVERIE TRANSITION VERIFICATION: PASS")
	quit(0)
