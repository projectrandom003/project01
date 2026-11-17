class_name GenericAttackPresentationComponent
extends Control
## Owns ordinary unit lunge, strike-trail and impact-slash choreography.
## Character-specific moves are delegated to their own presentation components.

var battlefield: Battlefield


func bind(owner: Battlefield) -> void:
	battlefield = owner
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func play_attack(attacker: BattlefieldActor, target: BattlefieldActor, element: String = "neutral") -> void:
	if attacker == null or not is_instance_valid(attacker):
		return
	var origin: Vector2 = attacker.position
	var direction := Vector2.RIGHT
	if target != null and is_instance_valid(target):
		direction = (target.position - origin).normalized()
	attacker.face(direction)
	attacker.play_attack()
	# Attackers travel toward the selected enemy, stopping just outside its
	# silhouette; the effect then lands on the enemy's upper body.
	var reach := origin
	var impact_point := origin + direction * 42.0
	if target != null and is_instance_valid(target):
		var distance: float = origin.distance_to(target.position)
		# Close the full gap and stop just outside the boss silhouette. A short
		# percentage lunge leaves the attacker stranded mid-arena and reads as
		# attacking another party member instead of the selected enemy.
		var safe_gap := 118.0 if target.unit != null and target.unit.is_boss else 48.0
		reach = target.position - direction * minf(safe_gap, maxf(28.0, distance * 0.16))
		# Aim the visible hit at the Matron's torso, not at the ground between units.
		impact_point = target.position + (Vector2(-14.0, -88.0) if target.unit != null and target.unit.def_id == "fallen_matron" else Vector2(0, -28.0))
	var tween := create_tween()
	tween.tween_property(attacker, "position", origin - direction * 18.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(attacker, "scale", Vector2(0.92, 1.08), 0.12).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(attacker, "scale", Vector2(1.12, 0.92), 0.10).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(attacker, "position", reach, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if target != null and is_instance_valid(target):
			_spawn_attack_trail(origin + Vector2(0, -42.0), impact_point, element)
			_spawn_slash(impact_point, direction, element)
			var knock: Vector2 = target.position + direction * 18.0
			var kb := create_tween()
			kb.tween_property(target, "position", knock, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			kb.tween_property(target, "position", target.home_position, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			_spawn_slash(attacker.position + direction * 24.0, direction, element))
	# Reconcile to the authored slot, not the lunge's starting point. This
	# prevents small layout changes or a partially interrupted previous move
	# from accumulating battlefield drift across successive turns.
	tween.tween_property(attacker, "position", attacker.home_position, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(attacker, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## A visible strike trail connects the attacker to the actual target.
## It makes the hit direction unambiguous, especially against large bosses.
func _spawn_attack_trail(from: Vector2, to: Vector2, element: String) -> void:
	var color := UITheme.element_color(element)
	if color == UITheme.TEXT_DIM:
		color = Color(0.88, 0.9, 1.0)
	var trail := preload("res://scenes/ui/combat/components/attack_trail.tscn").instantiate() as Line2D
	trail.default_color = Color(color.r, color.g, color.b, 0.88)
	trail.points = PackedVector2Array([
		from + Vector2(0, -38),
		(from + to) * 0.5 + Vector2(0, -64),
		to,
	])
	trail.z_index = 32
	add_child(trail)
	var tween := create_tween()
	tween.tween_property(trail, "width", 1.0, 0.22)
	tween.parallel().tween_property(trail, "modulate:a", 0.0, 0.22)
	tween.tween_callback(trail.queue_free)


## A crescent slash at the target's position.
func _spawn_slash(pos: Vector2, direction: Vector2, element: String) -> void:
	var color := UITheme.element_color(element)
	if color == UITheme.TEXT_DIM:
		color = Color(0.92, 0.92, 0.98)
	var slash := preload("res://scenes/ui/combat/components/impact_slash.tscn").instantiate() as Line2D
	slash.default_color = Color(color.r, color.g, color.b, 0.9)
	var normal := Vector2(-direction.y, direction.x)
	slash.points = PackedVector2Array([
		pos - direction * 22.0 - normal * 26.0,
		pos + direction * 10.0,
		pos - direction * 10.0 + normal * 30.0,
	])
	slash.z_index = 30
	add_child(slash)
	var tween := create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.28)
	tween.tween_callback(slash.queue_free)
