class_name MatronAttackPresentationComponent
extends Control
## Owns Fallen Matron-specific attack and phase-transition choreography.
## Visual only: CombatEngine remains authoritative for damage and turn resolution.

var battlefield: Battlefield


func bind(owner: Battlefield) -> void:
	battlefield = owner
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func play_attack(boss: BattlefieldActor, target: BattlefieldActor, skill_id: String, ultimate: bool) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	_play_matron_attack(boss, target, skill_id, ultimate)


## Fallen Matron's four attacks have separate silhouettes and timing. Visual-only:
## damage and turn resolution remain owned by CombatEngine.
func _play_matron_attack(boss: BattlefieldActor, target: BattlefieldActor,
		skill_id: String, ultimate: bool) -> void:
	boss.play_attack()
	var origin := boss.position
	var target_pos := target.position if target != null and is_instance_valid(target) else origin + Vector2(-180, 0)
	# A readable danger marker appears before the Matron's attack resolves.
	if skill_id in ["corruption_bolt", "soul_drain"]:
		_spawn_matron_telegraph(target_pos, 0.38 if not ultimate else 0.55)
	elif skill_id == "shadow_lash":
		for entry in battlefield._actors:
			var marked: BattlefieldActor = entry
			if marked.is_player and not marked.dead and marked.unit != null and marked.unit.is_alive():
				_spawn_matron_telegraph(marked.position, 0.42)
	match skill_id:
		"corruption_bolt":
			var windup := create_tween()
			windup.tween_property(boss, "scale", Vector2(1.12, 0.92), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			windup.tween_callback(func() -> void: _spawn_matron_orb(origin + Vector2(-22, -78), target_pos))
			windup.tween_property(boss, "scale", Vector2.ONE, 0.24)
		"shadow_lash":
			var windup := create_tween()
			windup.tween_property(boss, "position", origin + Vector2(0, -12), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			windup.tween_callback(func() -> void:
				for entry in battlefield._actors:
					var victim: BattlefieldActor = entry
					if victim.is_player and not victim.dead and victim.unit != null and victim.unit.is_alive():
						_spawn_shadow_lash(victim.position))
			windup.tween_property(boss, "position", origin, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		"soul_drain":
			var drain := create_tween()
			drain.tween_property(boss, "scale", Vector2(0.92, 1.12), 0.22).set_trans(Tween.TRANS_SINE)
			drain.tween_callback(func() -> void: _spawn_soul_drain(target_pos, origin + Vector2(-20, -76)))
			drain.tween_property(boss, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_SINE)
		"matron_verdict":
			_play_matron_verdict(boss, target_pos)
		_:
			_spawn_shadow_lash(target_pos)


func _spawn_matron_telegraph(at: Vector2, duration: float) -> void:
	var marker := preload("res://scenes/ui/combat/components/ground_telegraph.tscn").instantiate() as Node2D
	marker.position = at + Vector2(0, 8)
	marker.z_index = 34
	var ring := marker.get_node("Ring") as Line2D
	ring.width = 3.0
	ring.default_color = Color(0.92, 0.24, 0.62, 0.88)
	var points := PackedVector2Array()
	for i in range(49):
		var angle := TAU * float(i) / 48.0
		points.append(Vector2(cos(angle), sin(angle)) * 34.0)
	ring.points = points
	var cross := marker.get_node("Cross") as Line2D
	cross.width = 1.5
	cross.default_color = Color(1.0, 0.62, 0.83, 0.72)
	cross.points = PackedVector2Array([Vector2(-46, 0), Vector2(46, 0)])
	add_child(marker)
	marker.scale = Vector2(0.45, 0.45)
	var tween := create_tween()
	tween.tween_property(marker, "scale", Vector2(1.25, 1.25), maxf(0.12, duration)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ring, "default_color:a", 0.0, maxf(0.12, duration))
	tween.tween_callback(marker.queue_free)


func _spawn_matron_orb(from: Vector2, to: Vector2) -> void:
	var orb := preload("res://scenes/ui/combat/components/matron_orb.tscn").instantiate() as Polygon2D
	orb.color = Color("#bd65f5")
	orb.position = from
	orb.z_index = 42
	add_child(orb)
	var tween := create_tween()
	tween.tween_property(orb, "position", to + Vector2(0, -22), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if is_instance_valid(orb):
			_spawn_matron_burst(orb.position)
			orb.queue_free())


func _spawn_shadow_lash(target_pos: Vector2) -> void:
	for i in range(3):
		var lash := preload("res://scenes/ui/combat/components/shadow_lash.tscn").instantiate() as Line2D
		lash.width = 8.0 - float(i) * 1.5
		lash.default_color = Color(0.34, 0.08, 0.48, 0.92 - float(i) * 0.18)
		var start := Vector2(battlefield.size.x * 0.82, battlefield.size.y * 0.76 + float(i - 1) * 18.0)
		var bend := (start + target_pos) * 0.5 + Vector2(-12, -55.0 - float(i) * 12.0)
		lash.points = PackedVector2Array([start, bend, target_pos + Vector2(0, -24)])
		lash.z_index = 40 + i
		add_child(lash)
		var tween := create_tween()
		tween.tween_property(lash, "modulate:a", 0.0, 0.46).set_delay(0.08 * float(i))
		tween.tween_callback(lash.queue_free)


func _spawn_soul_drain(from: Vector2, to: Vector2) -> void:
	var beam := preload("res://scenes/ui/combat/components/soul_drain_beam.tscn").instantiate() as Line2D
	beam.width = 13.0
	beam.default_color = Color(0.72, 0.35, 0.92, 0.78)
	beam.points = PackedVector2Array([from, (from + to) * 0.5 + Vector2(0, -24), to])
	beam.z_index = 38
	add_child(beam)
	var tween := create_tween()
	tween.tween_property(beam, "width", 3.0, 0.55)
	tween.parallel().tween_property(beam, "modulate:a", 0.0, 0.55)
	tween.tween_callback(beam.queue_free)
	_spawn_matron_burst(to)


func _play_matron_verdict(boss: BattlefieldActor, target_pos: Vector2) -> void:
	# Stage 1 — the garden goes silent; the Matron gathers the whole arena.
	var overlay := preload("res://scenes/ui/combat/components/matron_verdict_overlay.tscn").instantiate() as Control
	add_child(overlay)
	var veil := overlay.get_node("Veil") as ColorRect
	var title := overlay.get_node("Title") as Label
	var seal_center := boss.position + Vector2(0, -72)
	_spawn_verdict_seal(seal_center)
	var intro := create_tween()
	intro.tween_property(veil, "color:a", 0.66, 0.42)
	intro.parallel().tween_property(title, "modulate:a", 1.0, 0.32)
	intro.tween_property(boss, "position:y", boss.home_position.y - 42.0, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	intro.parallel().tween_property(boss, "scale", Vector2(1.16, 0.9), 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.tween_interval(0.28)
	# Stage 2 — every living ally receives a growing floor sigil and a warning.
	intro.tween_callback(func() -> void:
		for entry in battlefield._actors:
			var victim: BattlefieldActor = entry
			if victim.is_player and not victim.dead and victim.unit != null and victim.unit.is_alive():
				_spawn_ritual_rings(victim.position + Vector2(0, 4))
				_spawn_verdict_warning(victim.position)
		)
	intro.tween_interval(0.72)
	# Stage 3 — vertical corruption pillars strike together; this is the damage beat.
	intro.tween_callback(func() -> void:
		title.text = "BLOOM. WITHER. RETURN."
		battlefield.cinematic_impact.emit(13.0, 0.48)
		for entry in battlefield._actors:
			var victim: BattlefieldActor = entry
			if victim.is_player and not victim.dead and victim.unit != null and victim.unit.is_alive():
				_spawn_verdict_column(victim.position)
				_spawn_matron_burst(victim.position + Vector2(0, -30))
				_spawn_matron_burst(victim.position + Vector2(-28, -12))
				_spawn_matron_burst(victim.position + Vector2(28, -12))
		)
	intro.tween_interval(0.34)
	intro.tween_property(veil, "color:a", 0.0, 0.5)
	intro.parallel().tween_property(title, "modulate:a", 0.0, 0.28)
	intro.parallel().tween_property(boss, "scale", Vector2.ONE, 0.48).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	intro.parallel().tween_property(boss, "position", boss.home_position, 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.tween_callback(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
	)


func _spawn_verdict_seal(center: Vector2) -> void:
	var seal := preload("res://scenes/ui/combat/components/matron_verdict_seal.tscn").instantiate() as Node2D
	seal.position = center
	seal.z_index = 24
	var radii := [34.0, 58.0, 82.0]
	for ring_index in radii.size():
		var ring := seal.get_node("Ring%d" % (ring_index + 1)) as Line2D
		var radius: float = radii[ring_index]
		ring.width = 2.2 if radius < 60.0 else 1.4
		ring.default_color = Color(0.82, 0.34, 1.0, 0.78)
		var points := PackedVector2Array()
		for i in range(97):
			var angle := TAU * float(i) / 96.0
			points.append(Vector2(cos(angle), sin(angle)) * radius)
		ring.points = points
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var spoke := seal.get_node("Spoke%d" % (i + 1)) as Line2D
		spoke.width = 2.0
		spoke.default_color = Color("#eaa5ff")
		spoke.points = PackedVector2Array([Vector2(cos(angle), sin(angle)) * 22.0, Vector2(cos(angle), sin(angle)) * 82.0])
	add_child(seal)
	var pulse := create_tween()
	pulse.tween_property(seal, "rotation", TAU * 0.5, 1.7)
	pulse.parallel().tween_property(seal, "scale", Vector2(1.16, 1.16), 0.85)
	pulse.tween_property(seal, "modulate:a", 0.0, 0.45)
	pulse.tween_callback(seal.queue_free)


func _spawn_verdict_warning(center: Vector2) -> void:
	var warning := preload("res://scenes/ui/combat/components/ground_telegraph.tscn").instantiate() as Node2D
	warning.position = center + Vector2(0, 8)
	warning.z_index = 37
	var ring := warning.get_node("Ring") as Line2D
	ring.width = 4.0
	ring.default_color = Color("#ff5ac8")
	var points := PackedVector2Array()
	for i in range(65):
		var angle := TAU * float(i) / 64.0
		points.append(Vector2(cos(angle), sin(angle)) * 38.0)
	ring.points = points
	var cross := warning.get_node("Cross") as Line2D
	cross.width = 2.0
	cross.default_color = Color(1.0, 0.72, 0.92, 0.9)
	cross.points = PackedVector2Array([Vector2(-52, 0), Vector2(52, 0)])
	add_child(warning)
	var pulse := create_tween()
	pulse.tween_property(warning, "scale", Vector2(1.55, 1.55), 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.parallel().tween_property(ring, "default_color:a", 0.0, 0.7)
	pulse.tween_callback(warning.queue_free)


func _spawn_verdict_column(center: Vector2) -> void:
	var column := preload("res://scenes/ui/combat/components/verdict_column.tscn").instantiate() as Polygon2D
	column.name = "MatronVerdictColumn"
	column.color = Color(0.82, 0.3, 1.0, 0.0)
	column.position = center + Vector2(0, -185)
	column.z_index = 43
	add_child(column)
	var core := column.get_node("Core") as Polygon2D
	core.color = Color(1.0, 0.82, 1.0, 0.0)
	var strike := create_tween()
	strike.tween_property(column, "color:a", 0.78, 0.08)
	strike.parallel().tween_property(core, "color:a", 0.95, 0.06)
	strike.tween_interval(0.12)
	strike.tween_property(column, "color:a", 0.0, 0.34)
	strike.parallel().tween_property(core, "color:a", 0.0, 0.22)
	strike.tween_callback(column.queue_free)


func _spawn_ritual_rings(center: Vector2) -> void:
	for ring_index in range(3):
		var ring := preload("res://scenes/ui/combat/components/magic_effect_line.tscn").instantiate() as Line2D
		var points := PackedVector2Array()
		for point_index in range(49):
			var angle := TAU * float(point_index) / 48.0
			points.append(Vector2(cos(angle), sin(angle)) * (18.0 + float(ring_index) * 15.0))
		ring.points = points
		ring.closed = true
		ring.width = 3.0 - float(ring_index) * 0.5
		ring.default_color = Color(0.78, 0.34, 0.98, 0.85 - float(ring_index) * 0.18)
		ring.position = center
		ring.z_index = 36 + ring_index
		add_child(ring)
		var tween := create_tween()
		tween.tween_property(ring, "scale", Vector2(4.0, 2.2), 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.72)
		tween.tween_callback(ring.queue_free)


func _spawn_matron_burst(pos: Vector2) -> void:
	var particles := preload("res://scenes/ui/combat/components/matron_burst.tscn").instantiate() as CPUParticles2D
	particles.z_index = 44
	particles.position = pos
	add_child(particles)
	particles.finished.connect(particles.queue_free)
	particles.emitting = true


## Phase transition flourish for the Fallen Matron: a visible corruption surge.
func play_matron_phase(phase_number: int) -> void:
	var boss: BattlefieldActor = null
	for entry in battlefield._actors:
		var candidate: BattlefieldActor = entry
		if candidate.unit != null and candidate.unit.def_id == "fallen_matron":
			boss = candidate
			break
	if boss == null:
		return
	var pulse := create_tween()
	pulse.tween_property(boss, "scale", Vector2(1.24, 0.82), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(boss, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var center := boss.position + Vector2(0, -48)
	_spawn_matron_burst(center)
	_spawn_matron_burst(center + Vector2(-42, 12))
	_spawn_matron_burst(center + Vector2(42, 12))
	_spawn_ritual_rings(boss.position)
	var aura := preload("res://scenes/ui/combat/components/effect_glow_light.tscn").instantiate() as PointLight2D
	aura.color = Color("#a23fe0") if phase_number <= 2 else Color("#d34cff")
	aura.texture_scale = 2.4
	aura.position = Vector2(0, -50)
	boss.add_child(aura)
	var light_tween := create_tween()
	light_tween.tween_property(aura, "energy", 1.8, 0.18)
	light_tween.tween_property(aura, "energy", 0.0, 0.75)
	light_tween.tween_callback(aura.queue_free)


