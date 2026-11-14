extends SceneTree
## Runtime movement probe for actual Greenward gameplay (GameScreen).

const GAME_SCENE: PackedScene = preload("res://scenes/game.tscn")

func _init() -> void:
	# Wait for autoloads/content.
	await create_timer(0.2).timeout
	var root := get_root()
	var game := GAME_SCENE.instantiate()
	root.add_child(game)
	await create_timer(0.6).timeout
	await _run_probe(game)
	game.queue_free()
	await create_timer(0.1).timeout
	quit()

func _player(game: Node) -> Node:
	if game == null: return null
	if "world" in game and game.world != null and is_instance_valid(game.world):
		return game.world.player
	return null

func _report(label: String, p: CharacterBody2D) -> void:
	if p == null:
		print("PROBE[%s] no player" % label)
		return
	var slides := p.get_slide_collision_count()
	var cols := []
	for i in slides:
		var c := p.get_slide_collision(i)
		if c:
			var obj = c.get_collider()
			cols.append("%s|n=%s" % [str(obj.name) if obj else "null", str(c.get_normal())])
	print("PROBE[%s] pos=%s vel=%s floor=%s wall=%s slides=%d cols=%s input_enabled=%s pm=%s world_pm=%s" % [
		label, str(p.global_position), str(p.velocity), str(p.is_on_floor()), str(p.is_on_wall()),
		slides, str(cols), str(p.input_enabled), str(p.process_mode),
		str(p.get_parent().process_mode) if p.get_parent() else "?"
	])

func _press(dir: String, frames: int, p: CharacterBody2D) -> void:
	var action := "move_%s" % dir
	Input.action_press(action)
	for i in frames:
		await physics_frame
		if i == 0 or i == frames-1 or i == 5:
			print("PROBE[%s f%d] strength=%.2f vec=%s" % [dir, i, Input.get_action_strength(action), str(Input.get_vector("move_left","move_right","move_up","move_down"))])
			_report(dir, p)
	Input.action_release(action)
	await physics_frame
	_report(dir+"_released", p)

func _run_probe(game: Node) -> void:
	var p := _player(game) as CharacterBody2D
	_report("start", p)
	if p == null:
		return
	print("PROBE actions: up=%s down=%s left=%s right=%s" % [
		str(InputMap.has_action("move_up")), str(InputMap.has_action("move_down")),
		str(InputMap.has_action("move_left")), str(InputMap.has_action("move_right"))])
	for dir in ["up","down","left","right"]:
		_press(dir, 12, p)
		await create_timer(0.05).timeout
	# diagonal
	Input.action_press("move_up"); Input.action_press("move_right")
	for i in 8:
		await physics_frame
		if i==0 or i==7:
			_report("up_right_%d" % i, p)
	Input.action_release("move_up"); Input.action_release("move_right")
	await physics_frame
	_report("diag_released", p)
