class_name BattlefieldLayoutComponent
extends Node
## Owns arena setup, combatant actor lifecycle and responsive battlefield placement.

var battlefield: Battlefield
var actors: Array = []
var by_uid: Dictionary = {}
var stage: Node2D
var embers: CPUParticles2D


func bind(owner: Battlefield) -> void:
	battlefield = owner
	actors = battlefield._actors
	by_uid = battlefield._by_uid


func build_environment() -> void:
	if battlefield == null:
		return
	var field_backdrop := battlefield.get_node_or_null("GreenwardForestBackdrop") as Control
	var boss_backdrop := battlefield.get_node_or_null("GreenwardRootArenaBackdrop") as Control
	var estate_backdrop := battlefield.get_node_or_null("WitheredEstateBackdrop") as Control
	embers = battlefield.get_node_or_null("Embers") as CPUParticles2D
	stage = battlefield.get_node_or_null("Actors") as Node2D
	if field_backdrop == null or boss_backdrop == null or estate_backdrop == null or embers == null or stage == null:
		push_error("Battlefield scene is missing an authored backdrop, Embers, or Actors node.")
		return
	field_backdrop.visible = battlefield.arena_id not in ["fallen_matron_encounter", "corrupted_treant", "elder_hollow"]
	boss_backdrop.visible = battlefield.arena_id in ["corrupted_treant", "elder_hollow"]
	boss_backdrop.set("arena_id", battlefield.arena_id)
	estate_backdrop.visible = battlefield.arena_id == "fallen_matron_encounter"
	embers.color = Color(0.85, 0.6, 0.95, 0.22) if battlefield.arena_id == "fallen_matron_encounter" else Color(0.62, 0.9, 0.48, 0.20)
	battlefield._embers = embers
	battlefield._stage = stage

func setup(party: Array, enemies: Array) -> void:
	clear_actors()
	for unit in party:
		_add_actor(unit, true)
	for unit in enemies:
		_add_actor(unit, false)
	layout()
	battlefield.call_deferred("_layout")
	face_opponents()


func _add_actor(unit: Combatant, is_player: bool) -> void:
	if unit == null:
		return
	var actor := Battlefield.ACTOR_SCENE.instantiate() as BattlefieldActor
	stage.add_child(actor)
	actor.setup(unit, is_player)
	actor.clicked.connect(battlefield._on_actor_clicked)
	actors.append(actor)
	by_uid[unit.uid] = actor


func clear_actors() -> void:
	for actor in actors:
		if is_instance_valid(actor):
			actor.queue_free()
	actors.clear()
	by_uid.clear()


func actor_for_uid(uid: String) -> BattlefieldActor:
	return by_uid.get(uid, null) as BattlefieldActor


func layout() -> void:
	if stage == null:
		return
	var width := battlefield.size.x
	var height := battlefield.size.y
	if width <= 0.0 or height <= 0.0:
		return
	var party_slot := 0
	var enemy_slot := 0
	for entry in actors:
		var actor: BattlefieldActor = entry
		if actor.is_player:
			actor.set_home(Vector2(
				width * (Battlefield.PARTY_X + Battlefield.PARTY_DX * float(party_slot)),
				height * (Battlefield.PARTY_Y + Battlefield.PARTY_DY * float(party_slot))))
			party_slot += 1
		elif actor.unit != null and actor.unit.is_boss:
			actor.set_home(Vector2(width * Battlefield.BOSS_X, height * Battlefield.BOSS_Y))
		else:
			actor.set_home(Vector2(
				width * (Battlefield.ENEMY_X + Battlefield.ENEMY_DX * float(enemy_slot)),
				height * (Battlefield.ENEMY_Y + Battlefield.ENEMY_DY * float(enemy_slot))))
			enemy_slot += 1
		if not actor.dead:
			actor.position = actor.home_position
	if embers != null:
		embers.position = Vector2(width * 0.5, height * 0.55)
		embers.emission_rect_extents = Vector2(width * 0.5, height * 0.4)


func face_opponents() -> void:
	for entry in actors:
		var actor: BattlefieldActor = entry
		if actor.dead:
			continue
		actor.face(Vector2(1.0, 0.0) if actor.is_player else Vector2(-1.0, 0.0))


func refresh_actors() -> void:
	for entry in actors:
		var actor: BattlefieldActor = entry
		actor.refresh()


func set_active(uid: String) -> void:
	for entry in actors:
		var actor: BattlefieldActor = entry
		actor.set_active(actor.unit != null and actor.unit.uid == uid)


func set_target_team(team: int, enabled: bool) -> void:
	for entry in actors:
		var actor: BattlefieldActor = entry
		if actor.unit == null:
			continue
		actor.set_targetable(enabled and actor.unit.team == team and actor.unit.is_alive())
