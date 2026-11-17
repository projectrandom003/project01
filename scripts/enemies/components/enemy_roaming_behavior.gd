class_name EnemyRoamingBehavior
extends Node
## Coordinates the passive, interaction-only roaming loop for a world enemy.
## Movement, detection, targeting, status, animation and encounter state remain
## owned by their dedicated components; this node only composes one frame.

func process_roaming(monster: Node2D, player: Node2D, delta: float) -> void:
	if monster == null or player == null:
		return
	var detection: Node = monster.get("detection_component")
	var targeting: Node = monster.get("targeting_component")
	var status: Node = monster.get("status_component")
	var movement: Node = monster.get("movement_component")
	var visual: Node = monster.get("visual")
	var animation: Node = monster.get("animation_component")
	var controller: Node = monster.get("enemy_controller")
	var state_machine: Node = monster.get("state_machine")
	if detection != null and detection.has_method("evaluate"):
		detection.call("evaluate", monster, player)
	if targeting != null and targeting.has_method("clear_target"):
		targeting.call("clear_target")
	if status != null and status.has_method("tick"):
		status.call("tick", delta)
	if movement == null:
		return
	if movement.tick_roam_timer(delta):
		var candidate: Vector2 = movement.pick_roam_target(monster.position, Callable(self, "_target_walkable"))
		movement.reset_roam_timer()
		monster.set("_roam_target", candidate)
	var target: Vector2 = monster.get("_roam_target")
	var moving := monster.position.distance_to(target) > 4.0 and _target_walkable(target)
	var direction := Vector2.ZERO
	if moving:
		direction = movement.move_toward_target(monster, target, delta)
	moving = direction.length_squared() > 0.0001
	movement.set_mode(&"patrol" if moving else &"idle")
	if visual != null:
		visual.set("walking", moving)
		if moving:
			visual.call("set_move_direction", direction)
			visual.call("play", 1)
		else:
			visual.call("play", 0)
	if animation != null and animation.has_method("play_state"):
		animation.call("play_state", &"patrol" if moving else &"idle")
	if controller != null and controller.has_method("request_state"):
		var current = state_machine.get("current_state_name") if state_machine != null and "current_state_name" in state_machine else null
		var desired: StringName = &"patrol" if moving else &"idle"
		if current != desired:
			controller.call("request_state", desired, {})
	elif state_machine != null and state_machine.has_method("set_state"):
		var current = state_machine.get("current_state_name") if "current_state_name" in state_machine else null
		var desired: StringName = &"patrol" if moving else &"idle"
		if current != desired:
			state_machine.call("set_state", desired, {})


	if controller != null and controller.has_method("process_ai"):
		controller.call("process_ai", delta, {})
	elif state_machine != null and state_machine.has_method("process_state"):
		state_machine.call("process_state", delta, {})

func _target_walkable(position: Vector2) -> bool:
	var world := get_tree().get_first_node_in_group("world")
	if world == null or not is_instance_valid(world):
		return true
	if not world.has_method("is_walkable"):
		return true
	return bool(world.call("is_walkable", position))
