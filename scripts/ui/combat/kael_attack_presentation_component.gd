class_name KaelAttackPresentationComponent
extends Control
## Owns Kael-specific attack choreography and transient visual effects.
## CombatEngine remains authoritative for all damage and turn resolution.

var battlefield: Battlefield

func bind(owner: Battlefield) -> void:
	battlefield = owner
	mouse_filter = Control.MOUSE_FILTER_IGNORE
## Kael's moves each have a separate visual rhythm. All damage remains
## authoritative in CombatEngine; this choreography never applies gameplay hits.
func play_attack(attacker: BattlefieldActor, target: BattlefieldActor,
		skill_id: String, ultimate: bool) -> void:
	var origin := attacker.position
	var has_target := target != null and is_instance_valid(target)
	var direction := (target.position - origin).normalized() if has_target else Vector2.RIGHT
	attacker.face(direction)
	var target_home := target.position if has_target else origin + direction * 150.0
	var impact := target_home + Vector2(0, -34.0)
	var fire := Color("#ff563f")
	var gold := Color("#ffc16a")
	var pale := Color("#fff0d0")

	if skill_id == "rally_cry":
		# Plant the feet, draw the blade across the chest, then release a team-wide oath.
		attacker.visual.play_cast()
		var rally := create_tween()
		rally.tween_property(attacker, "scale", Vector2(0.86, 1.16), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		rally.tween_callback(func() -> void:
			_spawn_kael_rally_ring(attacker.position, fire, gold)
			for entry in battlefield._actors:
				var ally: BattlefieldActor = entry
				if ally.is_player and not ally.dead:
					_spawn_kael_aura(ally)
		)
		rally.tween_property(attacker, "scale", Vector2(1.12, 0.90), 0.16)
		rally.tween_property(attacker, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_ELASTIC)
		return

	if skill_id == "ember_lance":
		# A compressed ember condenses at the sword hand, then pierces the arena.
		attacker.visual.play_cast()
		var cast := create_tween()
		cast.tween_property(attacker, "scale", Vector2(0.92, 1.10), 0.22).set_trans(Tween.TRANS_BACK)
		cast.tween_callback(func() -> void:
			_spawn_kael_lance(origin + Vector2(14, -58), impact, fire, gold, pale)
		)
		cast.tween_property(attacker, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK)
		return

	if skill_id == "blazing_charge" or ultimate:
		# Ultimate: hold the arena for a heartbeat, then cross it in a blazing
		# three-beat cut. The final detonation is intentionally the largest beat.
		attacker.visual.play_cast()
		var ultimate_tween := create_tween()
		ultimate_tween.tween_property(attacker, "scale", Vector2(0.78, 1.22), 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ultimate_tween.parallel().tween_property(attacker, "rotation", deg_to_rad(-8.0), 0.30)
		ultimate_tween.tween_callback(func() -> void:
			_spawn_kael_ground_seal(origin, fire, gold)
			battlefield.cinematic_impact.emit(0.22, 0.18)
		)
		ultimate_tween.tween_interval(0.16)
		var dash_end := target_home - direction * (105.0 if has_target and target.unit != null and target.unit.is_boss else 58.0)
		ultimate_tween.tween_property(attacker, "position", dash_end, 0.24).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		ultimate_tween.parallel().tween_property(attacker, "scale", Vector2(1.22, 0.84), 0.24)
		ultimate_tween.tween_callback(func() -> void:
			for beat in 3:
				var offset := Vector2(0, -52.0 - float(beat) * 12.0)
				_spawn_kael_cross_slash(impact + offset, direction, fire if beat != 2 else pale, 1.0 + float(beat) * 0.24)
			_spawn_kael_impact(impact, fire, gold, 1.0)
			battlefield.cinematic_impact.emit(0.72, 0.30)
		)
		ultimate_tween.tween_interval(0.14)
		ultimate_tween.tween_callback(func() -> void:
			_spawn_kael_ultimate_burst(impact, fire, gold, pale)
			battlefield.cinematic_impact.emit(1.0, 0.48)
			if has_target:
				var recoil := create_tween()
				recoil.tween_property(target, "position", target_home + direction * 30.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				recoil.tween_property(target, "position", target_home, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)
		ultimate_tween.tween_property(attacker, "position", origin, 0.34).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		ultimate_tween.parallel().tween_property(attacker, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK)
		ultimate_tween.parallel().tween_property(attacker, "rotation", 0.0, 0.34)
		return

	# Basic attack: a three-beat combo with varied arc, hit-stop and recovery.
	var reach := target_home - direction * (112.0 if has_target and target.unit != null and target.unit.is_boss else 52.0)
	attacker.visual.play_attack()
	var combo := create_tween()
	combo.tween_property(attacker, "position", origin - direction * 15.0, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	combo.tween_property(attacker, "position", reach, 0.20).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	combo.parallel().tween_property(attacker, "scale", Vector2(1.14, 0.88), 0.20)
	combo.tween_callback(func() -> void:
		if has_target:
			_spawn_kael_cross_slash(impact + Vector2(0, -8), direction, gold, 0.86)
			_spawn_kael_impact(impact, fire, gold, 0.46)
	)
	combo.tween_interval(0.07)
	combo.tween_callback(func() -> void:
		if has_target:
			_spawn_kael_cross_slash(impact + Vector2(4, 4), direction.rotated(0.42), fire, 1.0)
			_spawn_kael_impact(impact + Vector2(5, 0), fire, gold, 0.56)
	)
	combo.tween_interval(0.06)
	combo.tween_callback(func() -> void:
		if has_target:
			_spawn_kael_cross_slash(impact + Vector2(-4, -4), direction.rotated(-0.48), pale, 1.14)
			_spawn_kael_impact(impact, fire, gold, 0.72)
			var knock := create_tween()
			knock.tween_property(target, "position", target_home + direction * 22.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			knock.tween_property(target, "position", target_home, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	combo.tween_property(attacker, "position", origin, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	combo.parallel().tween_property(attacker, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK)


func _spawn_kael_cross_slash(center: Vector2, direction: Vector2, color: Color, strength: float) -> void:
	var slash := preload("res://scenes/ui/combat/components/kael_cross_slash.tscn").instantiate() as Line2D
	slash.width = 10.0 * strength
	slash.default_color = Color(color.r, color.g, color.b, 0.94)
	var normal := Vector2(-direction.y, direction.x)
	slash.points = PackedVector2Array([
		center - direction * 34.0 - normal * 25.0,
		center - direction * 5.0 + normal * 2.0,
		center + direction * 31.0 + normal * 27.0,
	])
	slash.z_index = 42
	add_child(slash)
	var tween := create_tween()
	tween.tween_property(slash, "width", 1.0, 0.22)
	tween.parallel().tween_property(slash, "modulate:a", 0.0, 0.22)
	tween.tween_callback(slash.queue_free)


func _spawn_kael_impact(pos: Vector2, fire: Color, gold: Color, strength: float) -> void:
	var flash := preload("res://scenes/ui/combat/components/kael_impact_flash.tscn").instantiate() as Polygon2D
	flash.scale = Vector2.ONE * strength
	flash.color = Color(gold.r, gold.g, gold.b, 0.86)
	flash.position = pos
	flash.z_index = 48
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector2(3.6, 3.6), 0.18).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.18)
	tween.tween_callback(flash.queue_free)
	battlefield.spawn_elemental_burst(pos, "fire")


func _spawn_kael_lance(from: Vector2, to: Vector2, fire: Color, gold: Color, pale: Color) -> void:
	var spear := preload("res://scenes/ui/combat/components/kael_lance.tscn").instantiate() as Node2D
	spear.position = from
	spear.z_index = 50
	(spear.get_node("Shaft") as Line2D).default_color = fire
	(spear.get_node("Core") as Line2D).default_color = pale
	(spear.get_node("Glow") as PointLight2D).color = fire
	add_child(spear)
	var delta := to - from
	spear.rotation = delta.angle()
	var travel := create_tween()
	travel.tween_property(spear, "position", to, 0.34).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	travel.parallel().tween_property(spear, "scale", Vector2(1.25, 0.8), 0.34)
	travel.tween_callback(func() -> void:
		_spawn_kael_impact(to, fire, gold, 0.82)
		spear.queue_free()
	)


func _spawn_kael_rally_ring(center: Vector2, fire: Color, gold: Color) -> void:
	for ring_index in 3:
		var ring := preload("res://scenes/ui/combat/components/magic_effect_line.tscn").instantiate() as Line2D
		ring.width = 2.0 if ring_index == 0 else 1.2
		ring.default_color = Color(gold.r, gold.g, gold.b, 0.78 - float(ring_index) * 0.16)
		var pts := PackedVector2Array()
		for i in 49:
			var a := TAU * float(i) / 48.0
			pts.append(Vector2(cos(a) * (24.0 + float(ring_index) * 12.0), sin(a) * (8.0 + float(ring_index) * 4.0)))
		ring.points = pts
		ring.position = center + Vector2(0, 8)
		ring.z_index = 24
		add_child(ring)
		var tween := create_tween()
		tween.tween_property(ring, "scale", Vector2(2.6, 2.6), 0.48 + float(ring_index) * 0.08)
		tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.48 + float(ring_index) * 0.08)
		tween.tween_callback(ring.queue_free)
	battlefield.spawn_elemental_burst(center + Vector2(0, -32), "fire")


func _spawn_kael_aura(ally: BattlefieldActor) -> void:
	var aura := preload("res://scenes/ui/combat/components/kael_rally_aura.tscn").instantiate() as PointLight2D
	aura.color = Color("#ff9b50")
	ally.add_child(aura)
	var tween := create_tween()
	tween.tween_property(aura, "energy", 1.15, 0.22)
	tween.tween_property(aura, "energy", 0.0, 1.0)
	tween.tween_callback(aura.queue_free)


func _spawn_kael_ground_seal(center: Vector2, fire: Color, gold: Color) -> void:
	for ring_index in 3:
		var ring := preload("res://scenes/ui/combat/components/magic_effect_line.tscn").instantiate() as Line2D
		ring.width = 2.6 - float(ring_index) * 0.55
		ring.default_color = Color(fire.r, fire.g, fire.b, 0.78 - float(ring_index) * 0.16)
		var pts := PackedVector2Array()
		for i in 65:
			var a := TAU * float(i) / 64.0
			var radius := 20.0 + float(ring_index) * 13.0
			pts.append(Vector2(cos(a) * radius, sin(a) * radius * 0.42))
		ring.points = pts
		ring.position = center + Vector2(0, 8)
		ring.z_index = 28
		add_child(ring)
		var tween := create_tween()
		tween.tween_property(ring, "rotation", TAU * (1.0 if ring_index % 2 == 0 else -1.0), 0.9)
		tween.parallel().tween_property(ring, "scale", Vector2(2.3, 2.3), 0.9)
		tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.9)
		tween.tween_callback(ring.queue_free)
	battlefield.spawn_elemental_burst(center, "fire")


func _spawn_kael_ultimate_burst(center: Vector2, fire: Color, gold: Color, pale: Color) -> void:
	var bloom := preload("res://scenes/ui/combat/components/effect_glow_light.tscn").instantiate() as PointLight2D
	bloom.color = fire
	bloom.texture_scale = 0.3
	bloom.position = center
	bloom.z_index = 54
	add_child(bloom)
	var light := create_tween()
	light.tween_property(bloom, "energy", 3.4, 0.12)
	light.tween_property(bloom, "energy", 0.0, 0.62)
	light.tween_callback(bloom.queue_free)
	var burst := preload("res://scenes/ui/combat/components/kael_ultimate_particles.tscn").instantiate() as CPUParticles2D
	burst.color = gold
	burst.position = center
	burst.z_index = 52
	add_child(burst)
	burst.finished.connect(burst.queue_free)
	burst.emitting = true
	_spawn_kael_cross_slash(center, Vector2.RIGHT, pale, 2.1)
	_spawn_kael_cross_slash(center, Vector2.RIGHT.rotated(PI * 0.5), fire, 1.8)
	var ring := preload("res://scenes/ui/combat/components/magic_effect_line.tscn").instantiate() as Line2D
	ring.width = 5.0
	ring.default_color = Color(fire.r, fire.g, fire.b, 0.9)
	var points := PackedVector2Array()
	for i in 65:
		var a := TAU * float(i) / 64.0
		points.append(Vector2(cos(a) * 42.0, sin(a) * 18.0))
	ring.points = points
	ring.position = center
	ring.z_index = 50
	add_child(ring)
	var ring_tween := create_tween()
	ring_tween.tween_property(ring, "scale", Vector2(2.8, 2.8), 0.42).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	ring_tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.42)
	ring_tween.tween_callback(ring.queue_free)
