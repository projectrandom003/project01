class_name Battlefield
extends Control
## The battle stage: a dark-fantasy environment with the party on the LEFT and
## the enemies on the RIGHT.
##
## PRESENTATION ONLY. The battlefield owns the actors, their positions, the
## ground shadows, the damage numbers and the attack choreography. Every
## number it shows comes from the CombatEngine's event stream, so it can never
## cause or duplicate damage.
##
## Positions are FRACTIONS of the battlefield size, so the layout follows the
## 1280x720 base viewport (and any other window size) without hardcoding.
## Party size is not hardcoded: slots are assigned by index, so any number of
## allies fits.

signal actor_clicked(actor: BattlefieldActor)
signal cinematic_impact(intensity: float, duration: float)

# Party slots (front-most first, receding up-left into the depth).
const PARTY_X := 0.315
const PARTY_DX := -0.085
const PARTY_Y := 0.855
const PARTY_DY := -0.075

# Enemy slots (front-most first, receding up-right).
const ENEMY_X := 0.735
const ENEMY_DX := -0.052
const ENEMY_Y := 0.865
const ENEMY_DY := -0.112

# The boss stands apart, further back and larger.
const BOSS_X := 0.845
const BOSS_Y := 0.905

const DAMAGE_FONT := 26

var arena_id: String = ""
var _actors: Array = []
var _by_uid: Dictionary = {}
var _stage: Node2D = null
var _embers: CPUParticles2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_build_environment()
	resized.connect(_layout)


func _build_environment() -> void:
	# The Withered Estate replaces the generic gradient with a bespoke
	# layered conservatory: stained glass, hanging wisteria, statues, wet
	# reflective tiles and the Matron's pulsing ritual seal.
	var backdrop := Control.new()
	if arena_id == "fallen_matron_encounter":
		backdrop.set_script(load("res://scripts/ui/combat/withered_estate_backdrop.gd"))
		backdrop.name = "WitheredEstateBackdrop"
	elif arena_id in ["corrupted_treant", "elder_hollow"]:
		backdrop.set_script(load("res://scripts/ui/combat/greenward_boss_backdrop.gd"))
		backdrop.name = "GreenwardRootArenaBackdrop"
		backdrop.set("arena_id", arena_id)
	else:
		backdrop.set_script(load("res://scripts/ui/combat/greenward_field_backdrop.gd"))
		backdrop.name = "GreenwardForestBackdrop"
	UIFactory.set_full_rect(backdrop)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	# Drifting embers (one light CPU layer, kept cheap for mobile).
	_embers = CPUParticles2D.new()
	_embers.amount = 22
	_embers.lifetime = 7.0
	_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_embers.emission_rect_extents = Vector2(640, 150)
	_embers.direction = Vector2(0.15, -1)
	_embers.initial_velocity_min = 6.0
	_embers.initial_velocity_max = 20.0
	_embers.gravity = Vector2(1.5, -2.5)
	_embers.scale_amount_min = 0.3
	_embers.scale_amount_max = 0.9
	_embers.color = Color(0.85, 0.6, 0.95, 0.22) if arena_id == "fallen_matron_encounter" else Color(0.62, 0.9, 0.48, 0.20)
	_embers.z_index = 1
	add_child(_embers)

	# The actor stage (Node2D) sits above the painted environment.
	_stage = Node2D.new()
	_stage.name = "Actors"
	add_child(_stage)


## Build the stage from the two teams. Enemies are laid out with the boss
## apart; the party uses consecutive slots.
func setup(party: Array, enemies: Array) -> void:
	clear_actors()
	for unit in party:
		_add_actor(unit, true)
	for unit in enemies:
		_add_actor(unit, false)
	_layout()
	call_deferred("_layout")
	face_opponents()


func _add_actor(unit: Combatant, is_player: bool) -> void:
	if unit == null:
		return
	var actor := BattlefieldActor.new()
	_stage.add_child(actor)
	actor.setup(unit, is_player)
	actor.clicked.connect(_on_actor_clicked)
	_actors.append(actor)
	_by_uid[unit.uid] = actor


func clear_actors() -> void:
	for actor in _actors:
		if is_instance_valid(actor):
			actor.queue_free()
	_actors.clear()
	_by_uid.clear()


func actors() -> Array:
	return _actors


func actor_for_uid(uid: String) -> BattlefieldActor:
	return _by_uid.get(uid, null) as BattlefieldActor


func _layout() -> void:
	if _stage == null:
		return
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var party_slot := 0
	var enemy_slot := 0
	for entry in _actors:
		var actor: BattlefieldActor = entry
		if actor.is_player:
			actor.set_home(Vector2(
				w * (PARTY_X + PARTY_DX * float(party_slot)),
				h * (PARTY_Y + PARTY_DY * float(party_slot))))
			party_slot += 1
		elif actor.unit != null and actor.unit.is_boss:
			actor.set_home(Vector2(w * BOSS_X, h * BOSS_Y))
		else:
			actor.set_home(Vector2(
				w * (ENEMY_X + ENEMY_DX * float(enemy_slot)),
				h * (ENEMY_Y + ENEMY_DY * float(enemy_slot))))
			enemy_slot += 1
		if not actor.dead:
			actor.position = actor.home_position
	if _embers != null:
		_embers.position = Vector2(w * 0.5, h * 0.55)
		_embers.emission_rect_extents = Vector2(w * 0.5, h * 0.4)


## Party faces right, enemies face left.
func face_opponents() -> void:
	for entry in _actors:
		var actor: BattlefieldActor = entry
		if actor.dead:
			continue
		actor.face(Vector2(1.0, 0.0) if actor.is_player else Vector2(-1.0, 0.0))


func refresh_actors() -> void:
	for entry in _actors:
		var actor: BattlefieldActor = entry
		actor.refresh()


func set_active(uid: String) -> void:
	for entry in _actors:
		var actor: BattlefieldActor = entry
		actor.set_active(actor.unit != null and actor.unit.uid == uid)


## Highlight every valid target of the given team.
func set_target_team(team: int, enabled: bool) -> void:
	for entry in _actors:
		var actor: BattlefieldActor = entry
		if actor.unit == null:
			continue
		actor.set_targetable(enabled and actor.unit.team == team and actor.unit.is_alive())


func _on_actor_clicked(actor: BattlefieldActor) -> void:
	actor_clicked.emit(actor)


# ------------------------------------------------------------------- effects

## The full attack choreography: anticipation, approach, effect, impact,
## knockback, return. Purely visual - the engine has already resolved damage.
func play_attack(attacker: BattlefieldActor, target: BattlefieldActor,
		element: String = "neutral", skill_id: String = "", ultimate: bool = false) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return
	if attacker.unit != null and attacker.unit.def_id == "fallen_matron":
		_play_matron_attack(attacker, target, skill_id, ultimate)
		return
	if attacker.unit != null and attacker.unit.def_id == "kael":
		_play_kael_attack(attacker, target, skill_id, ultimate)
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
	tween.tween_property(attacker, "position", origin, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(attacker, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Kael's moves each have a separate visual rhythm. All damage remains
## authoritative in CombatEngine; this choreography never applies gameplay hits.
func _play_kael_attack(attacker: BattlefieldActor, target: BattlefieldActor,
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
			for entry in _actors:
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
			cinematic_impact.emit(0.22, 0.18)
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
			cinematic_impact.emit(0.72, 0.30)
		)
		ultimate_tween.tween_interval(0.14)
		ultimate_tween.tween_callback(func() -> void:
			_spawn_kael_ultimate_burst(impact, fire, gold, pale)
			cinematic_impact.emit(1.0, 0.48)
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
	var slash := Line2D.new()
	slash.width = 10.0 * strength
	slash.default_color = Color(color.r, color.g, color.b, 0.94)
	slash.begin_cap_mode = Line2D.LINE_CAP_ROUND
	slash.end_cap_mode = Line2D.LINE_CAP_ROUND
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
	var flash := Polygon2D.new()
	var points := PackedVector2Array()
	for i in 12:
		var angle := TAU * float(i) / 12.0
		points.append(Vector2(cos(angle), sin(angle)) * (8.0 + float(i % 2) * 5.0) * strength)
	flash.polygon = points
	flash.color = Color(gold.r, gold.g, gold.b, 0.86)
	flash.position = pos
	flash.z_index = 48
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector2(3.6, 3.6), 0.18).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.18)
	tween.tween_callback(flash.queue_free)
	spawn_elemental_burst(pos, "fire")


func _spawn_kael_lance(from: Vector2, to: Vector2, fire: Color, gold: Color, pale: Color) -> void:
	var spear := Node2D.new()
	spear.position = from
	spear.z_index = 50
	add_child(spear)
	var shaft := Line2D.new()
	shaft.width = 8.0
	shaft.default_color = fire
	shaft.points = PackedVector2Array([Vector2(-28, 0), Vector2(0, 0), Vector2(34, 0)])
	spear.add_child(shaft)
	var core := Line2D.new()
	core.width = 2.5
	core.default_color = pale
	core.points = PackedVector2Array([Vector2(-24, 0), Vector2(32, 0)])
	spear.add_child(core)
	var glow := PointLight2D.new()
	glow.color = fire
	glow.energy = 1.7
	glow.texture = _make_soft_glow()
	glow.texture_scale = 0.75
	spear.add_child(glow)
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
		var ring := Line2D.new()
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
	spawn_elemental_burst(center + Vector2(0, -32), "fire")


func _spawn_kael_aura(ally: BattlefieldActor) -> void:
	var aura := PointLight2D.new()
	aura.name = "KaelRallyAura"
	aura.color = Color("#ff9b50")
	aura.energy = 0.0
	aura.texture = _make_soft_glow()
	aura.texture_scale = 1.4
	aura.position = Vector2(0, -42)
	ally.add_child(aura)
	var tween := create_tween()
	tween.tween_property(aura, "energy", 1.15, 0.22)
	tween.tween_property(aura, "energy", 0.0, 1.0)
	tween.tween_callback(aura.queue_free)


func _spawn_kael_ground_seal(center: Vector2, fire: Color, gold: Color) -> void:
	for ring_index in 3:
		var ring := Line2D.new()
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
	spawn_elemental_burst(center, "fire")


func _spawn_kael_ultimate_burst(center: Vector2, fire: Color, gold: Color, pale: Color) -> void:
	var bloom := PointLight2D.new()
	bloom.color = fire
	bloom.energy = 0.0
	bloom.texture = _make_soft_glow()
	bloom.texture_scale = 0.3
	bloom.position = center
	bloom.z_index = 54
	add_child(bloom)
	var light := create_tween()
	light.tween_property(bloom, "energy", 3.4, 0.12)
	light.tween_property(bloom, "energy", 0.0, 0.62)
	light.tween_callback(bloom.queue_free)
	var burst := CPUParticles2D.new()
	burst.amount = 64
	burst.one_shot = true
	burst.explosiveness = 0.96
	burst.lifetime = 0.85
	burst.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 16.0
	burst.direction = Vector2.UP
	burst.spread = 180.0
	burst.initial_velocity_min = 75.0
	burst.initial_velocity_max = 220.0
	burst.gravity = Vector2(0, 110)
	burst.scale_amount_min = 0.5
	burst.scale_amount_max = 1.8
	burst.color = gold
	burst.position = center
	burst.z_index = 52
	add_child(burst)
	burst.finished.connect(burst.queue_free)
	burst.emitting = true
	_spawn_kael_cross_slash(center, Vector2.RIGHT, pale, 2.1)
	_spawn_kael_cross_slash(center, Vector2.RIGHT.rotated(PI * 0.5), fire, 1.8)
	var ring := Line2D.new()
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
		for entry in _actors:
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
				for entry in _actors:
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
	var marker := Node2D.new()
	marker.position = at + Vector2(0, 8)
	marker.z_index = 34
	add_child(marker)
	var ring := Line2D.new()
	ring.width = 3.0
	ring.default_color = Color(0.92, 0.24, 0.62, 0.88)
	ring.closed = true
	var points := PackedVector2Array()
	for i in range(49):
		var angle := TAU * float(i) / 48.0
		points.append(Vector2(cos(angle), sin(angle)) * 34.0)
	ring.points = points
	marker.add_child(ring)
	var cross := Line2D.new()
	cross.width = 1.5
	cross.default_color = Color(1.0, 0.62, 0.83, 0.72)
	cross.points = PackedVector2Array([Vector2(-46, 0), Vector2(46, 0)])
	marker.add_child(cross)
	marker.scale = Vector2(0.45, 0.45)
	var tween := create_tween()
	tween.tween_property(marker, "scale", Vector2(1.25, 1.25), maxf(0.12, duration)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ring, "default_color:a", 0.0, maxf(0.12, duration))
	tween.tween_callback(marker.queue_free)


func _spawn_matron_orb(from: Vector2, to: Vector2) -> void:
	var orb := Polygon2D.new()
	orb.polygon = PackedVector2Array([Vector2(0, -13), Vector2(10, -5), Vector2(8, 8), Vector2(0, 13), Vector2(-8, 8), Vector2(-10, -5)])
	orb.color = Color("#bd65f5")
	orb.position = from
	orb.z_index = 42
	add_child(orb)
	var glow := PointLight2D.new()
	glow.color = Color("#a34be8")
	glow.energy = 1.4
	glow.texture = _make_soft_glow()
	glow.texture_scale = 0.65
	orb.add_child(glow)
	var tween := create_tween()
	tween.tween_property(orb, "position", to + Vector2(0, -22), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		if is_instance_valid(orb):
			_spawn_matron_burst(orb.position)
			orb.queue_free())


func _spawn_shadow_lash(target_pos: Vector2) -> void:
	for i in range(3):
		var lash := Line2D.new()
		lash.width = 8.0 - float(i) * 1.5
		lash.default_color = Color(0.34, 0.08, 0.48, 0.92 - float(i) * 0.18)
		lash.begin_cap_mode = Line2D.LINE_CAP_ROUND
		lash.end_cap_mode = Line2D.LINE_CAP_ROUND
		var start := Vector2(size.x * 0.82, size.y * 0.76 + float(i - 1) * 18.0)
		var bend := (start + target_pos) * 0.5 + Vector2(-12, -55.0 - float(i) * 12.0)
		lash.points = PackedVector2Array([start, bend, target_pos + Vector2(0, -24)])
		lash.z_index = 40 + i
		add_child(lash)
		var tween := create_tween()
		tween.tween_property(lash, "modulate:a", 0.0, 0.46).set_delay(0.08 * float(i))
		tween.tween_callback(lash.queue_free)


func _spawn_soul_drain(from: Vector2, to: Vector2) -> void:
	var beam := Line2D.new()
	beam.width = 13.0
	beam.default_color = Color(0.72, 0.35, 0.92, 0.78)
	beam.begin_cap_mode = Line2D.LINE_CAP_ROUND
	beam.end_cap_mode = Line2D.LINE_CAP_ROUND
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
	var veil := ColorRect.new()
	veil.name = "MatronVerdictVeil"
	veil.color = Color(0.025, 0.002, 0.045, 0.0)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.z_index = 20
	add_child(veil)
	var title := Label.new()
	title.name = "MatronVerdictTitle"
	title.text = "THE GARDEN CLAIMS ITS DUE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#f0b8ff"))
	title.add_theme_color_override("font_outline_color", Color("#25052f"))
	title.add_theme_constant_override("outline_size", 7)
	title.anchor_left = 0.08
	title.anchor_right = 0.92
	title.anchor_top = 0.12
	title.anchor_bottom = 0.23
	title.modulate.a = 0.0
	title.z_index = 26
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
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
		for entry in _actors:
			var victim: BattlefieldActor = entry
			if victim.is_player and not victim.dead and victim.unit != null and victim.unit.is_alive():
				_spawn_ritual_rings(victim.position + Vector2(0, 4))
				_spawn_verdict_warning(victim.position)
		)
	intro.tween_interval(0.72)
	# Stage 3 — vertical corruption pillars strike together; this is the damage beat.
	intro.tween_callback(func() -> void:
		title.text = "BLOOM. WITHER. RETURN."
		cinematic_impact.emit(13.0, 0.48)
		for entry in _actors:
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
		if is_instance_valid(veil):
			veil.queue_free()
		if is_instance_valid(title):
			title.queue_free()
	)


func _spawn_verdict_seal(center: Vector2) -> void:
	var seal := Node2D.new()
	seal.name = "MatronVerdictSeal"
	seal.position = center
	seal.z_index = 24
	add_child(seal)
	for radius in [34.0, 58.0, 82.0]:
		var ring := Line2D.new()
		ring.width = 2.2 if radius < 60.0 else 1.4
		ring.default_color = Color(0.82, 0.34, 1.0, 0.78)
		ring.closed = true
		var points := PackedVector2Array()
		for i in range(97):
			var angle := TAU * float(i) / 96.0
			points.append(Vector2(cos(angle), sin(angle)) * radius)
		ring.points = points
		seal.add_child(ring)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var spoke := Line2D.new()
		spoke.width = 2.0
		spoke.default_color = Color("#eaa5ff")
		spoke.points = PackedVector2Array([Vector2(cos(angle), sin(angle)) * 22.0, Vector2(cos(angle), sin(angle)) * 82.0])
		seal.add_child(spoke)
	var pulse := create_tween()
	pulse.tween_property(seal, "rotation", TAU * 0.5, 1.7)
	pulse.parallel().tween_property(seal, "scale", Vector2(1.16, 1.16), 0.85)
	pulse.tween_property(seal, "modulate:a", 0.0, 0.45)
	pulse.tween_callback(seal.queue_free)


func _spawn_verdict_warning(center: Vector2) -> void:
	var warning := Node2D.new()
	warning.position = center + Vector2(0, 8)
	warning.z_index = 37
	add_child(warning)
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = Color("#ff5ac8")
	ring.closed = true
	var points := PackedVector2Array()
	for i in range(65):
		var angle := TAU * float(i) / 64.0
		points.append(Vector2(cos(angle), sin(angle)) * 38.0)
	ring.points = points
	warning.add_child(ring)
	var cross := Line2D.new()
	cross.width = 2.0
	cross.default_color = Color(1.0, 0.72, 0.92, 0.9)
	cross.points = PackedVector2Array([Vector2(-52, 0), Vector2(52, 0)])
	warning.add_child(cross)
	var pulse := create_tween()
	pulse.tween_property(warning, "scale", Vector2(1.55, 1.55), 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.parallel().tween_property(ring, "default_color:a", 0.0, 0.7)
	pulse.tween_callback(warning.queue_free)


func _spawn_verdict_column(center: Vector2) -> void:
	var column := Polygon2D.new()
	column.name = "MatronVerdictColumn"
	column.polygon = PackedVector2Array([Vector2(-42, 20), Vector2(-20, -430), Vector2(20, -430), Vector2(42, 20)])
	column.color = Color(0.82, 0.3, 1.0, 0.0)
	column.position = center + Vector2(0, -185)
	column.z_index = 43
	add_child(column)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([Vector2(-12, 12), Vector2(-5, -390), Vector2(5, -390), Vector2(12, 12)])
	core.color = Color(1.0, 0.82, 1.0, 0.0)
	column.add_child(core)
	var strike := create_tween()
	strike.tween_property(column, "color:a", 0.78, 0.08)
	strike.parallel().tween_property(core, "color:a", 0.95, 0.06)
	strike.tween_interval(0.12)
	strike.tween_property(column, "color:a", 0.0, 0.34)
	strike.parallel().tween_property(core, "color:a", 0.0, 0.22)
	strike.tween_callback(column.queue_free)


func _spawn_ritual_rings(center: Vector2) -> void:
	for ring_index in range(3):
		var ring := Line2D.new()
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
	var particles := CPUParticles2D.new()
	particles.amount = 24
	particles.lifetime = 0.7
	particles.one_shot = true
	particles.explosiveness = 0.94
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 10.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 45.0
	particles.initial_velocity_max = 150.0
	particles.gravity = Vector2(0, 35)
	particles.scale_amount_min = 0.45
	particles.scale_amount_max = 1.35
	particles.color = Color("#c36cf2")
	particles.z_index = 44
	particles.position = pos
	add_child(particles)
	particles.finished.connect(particles.queue_free)
	particles.emitting = true


func _make_soft_glow() -> Texture2D:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var distance := Vector2(x - 31.5, y - 31.5).length() / 31.5
			var alpha := clampf(1.0 - distance, 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 1, 1, alpha * alpha))
	return ImageTexture.create_from_image(image)


## A visible strike trail connects the attacker to the actual target.
## It makes the hit direction unambiguous, especially against large bosses.
func _spawn_attack_trail(from: Vector2, to: Vector2, element: String) -> void:
	var color := UITheme.element_color(element)
	if color == UITheme.TEXT_DIM:
		color = Color(0.88, 0.9, 1.0)
	var trail := Line2D.new()
	trail.width = 5.0
	trail.default_color = Color(color.r, color.g, color.b, 0.88)
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
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
	var slash := Line2D.new()
	slash.width = 7.0
	slash.default_color = Color(color.r, color.g, color.b, 0.9)
	slash.begin_cap_mode = Line2D.LINE_CAP_ROUND
	slash.end_cap_mode = Line2D.LINE_CAP_ROUND
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


## A floating damage / heal number above an actor.
func spawn_damage_number(actor: BattlefieldActor, text: String, color: Color,
		delay: float = 0.0) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", DAMAGE_FONT)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.05, 0.95))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 60
	_stage.add_child(label)
	var start: Vector2 = actor.position + Vector2(-28.0, -74.0 * actor.visual.visual_scale)
	label.position = start
	label.size = Vector2(56, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(label, "position:y", start.y - 54.0, 0.85) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.85).set_delay(0.25)
	if text.contains("!"):
		label.scale = Vector2(1.5, 1.5)
		tween.tween_property(label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC)
	tween.chain().tween_callback(label.queue_free)


## The elemental burst at the impact point.
func spawn_elemental_burst(pos: Vector2, element: String) -> void:
	var color := UITheme.element_color(element)
	if color == UITheme.TEXT_DIM:
		color = Color(0.85, 0.85, 0.9)
	var particles := CPUParticles2D.new()
	particles.amount = 14
	particles.lifetime = 0.55
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 7.0
	particles.direction = Vector2(0, -1)
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 110.0
	particles.gravity = Vector2(0, 90)
	particles.scale_amount_min = 0.4
	particles.scale_amount_max = 1.1
	particles.color = color
	particles.z_index = 35
	particles.position = pos
	add_child(particles)
	particles.finished.connect(particles.queue_free)
	particles.emitting = true


## Phase transition flourish for the Fallen Matron: a visible corruption surge.
func play_matron_phase(phase_number: int) -> void:
	var boss: BattlefieldActor = null
	for entry in _actors:
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
	var aura := PointLight2D.new()
	aura.color = Color("#a23fe0") if phase_number <= 2 else Color("#d34cff")
	aura.energy = 0.0
	aura.texture = _make_soft_glow()
	aura.texture_scale = 2.4
	aura.position = Vector2(0, -50)
	boss.add_child(aura)
	var light_tween := create_tween()
	light_tween.tween_property(aura, "energy", 1.8, 0.18)
	light_tween.tween_property(aura, "energy", 0.0, 0.75)
	light_tween.tween_callback(aura.queue_free)


func play_death(actor: BattlefieldActor) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	actor.play_death()


func play_victory_animations() -> void:
	for entry in _actors:
		var actor: BattlefieldActor = entry
		if actor.is_player and not actor.dead:
			actor.play_victory()


# ------------------------------------------------------------------ report

## Machine-readable snapshot of the battlefield, for tests and tooling.
func presentation_report() -> Dictionary:
	var party := 0
	var enemies := 0
	var bosses := 0
	var sprites := 0
	for entry in _actors:
		var actor: BattlefieldActor = entry
		if actor.is_player:
			party += 1
		else:
			enemies += 1
			if actor.unit != null and actor.unit.is_boss:
				bosses += 1
		if actor.visual != null and not actor.visual.using_temporary_art:
			sprites += 1
	return {
		"actors": _actors.size(),
		"party": party,
		"enemies": enemies,
		"bosses": bosses,
		"painted_sprites": sprites,
		"positions": _positions(),
	}


func _positions() -> Array:
	var out: Array = []
	for entry in _actors:
		var actor: BattlefieldActor = entry
		out.append({
			"uid": actor.unit.uid if actor.unit != null else "",
			"team": "party" if actor.is_player else "enemy",
			"position": actor.position,
		})
	return out
