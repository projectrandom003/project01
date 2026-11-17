class_name RoamingMonster
extends Interactable
## A visible world monster that roams, notices the player and starts a battle.
## It is intentionally NOT a fake battle: it requests a real encounter from the
## game controller, and stays defeated until it respawns.
##
## Phase 3 / Step 5: each spawn gets a DETERMINISTIC (group_id + spawn_index)
## palette tint, visual_scale variance, silhouette hint and a small prop accent,
## so a group of the same enemy reads as varied without touching any JSON. The
## animator is wired for roaming (WALK) / alert (RUN) / idle (IDLE). All gameplay
## behaviour (setup, _begin_encounter, EventBus.encounter_requested, walking,
## is_boss, visual_scale, battle_finished handling) is preserved.
##
## Milestone 21: integrated with reusable enemy components and state machine
## (controller/visual/movement/detection/targeting/combat/health/status/
## animation/interaction/audio/vfx) while preserving existing behavior.

const ANIM_IDLE := 0
const ANIM_WALK := 1
const ANIM_RUN := 2

var group_id: String = ""
var home_position: Vector2 = Vector2.ZERO
var roam_radius: float = 70.0
var move_speed: float = 26.0
var is_boss: bool = false
## Optional quest lock for arena bosses. The gate opens only after the required
## quest reaches the authored objective step (or later).
var required_quest: String = ""
var required_quest_step: int = 0
var engaged: bool = false
var defeated: bool = false
var respawn_seconds: float = 75.0
## Set by GreenwardWorld before setup(); drives deterministic per-spawn variety.
var spawn_index: int = 0
var _engagement_cooldown: float = 0.0
var _spawn_grace: float = 3.0

var visual: ActorVisual
var visual_definition: Dictionary = {}
var _roam_target: Vector2
var _player: Node2D

# --- modular components/state (reusable, behavior-preserving integration) ---
var roaming_behavior: EnemyRoamingBehavior = null
var enemy_controller: Node = null
var enemy_visual_component: Node = null
var movement_component: Node = null
var detection_component: Node = null
var targeting_component: Node = null
var combat_component: Node = null
var health_component: Node = null
var status_component: Node = null
var animation_component: Node = null
var interaction_component: Node = null
var audio_component: Node = null
var vfx_component: Node = null
var state_machine: Node = null


func setup(p_group_id: String, p_home: Vector2, p_enemy_def: Dictionary, p_boss: bool) -> void:
	group_id = p_group_id
	home_position = p_home
	position = p_home
	is_boss = p_boss
	prompt = "Challenge" if p_boss else "Fight"
	interaction_radius = 70.0
	visual_definition = p_enemy_def
	respawn_seconds = 120.0 if p_boss else 75.0
	move_speed = 14.0 if p_boss else 26.0
	_sync_components_from_setup()


func _ready() -> void:
	super._ready()
	add_to_group("world_minimap_monsters")
	_roam_target = position
	_resolve_modular_components()
	_sync_components_from_setup()
	var vseed := absi(("%s|%d" % [group_id, spawn_index]).hash())
	if enemy_visual_component != null:
		visual = enemy_visual_component.configure_enemy(self, visual_definition, is_boss, vseed)
	if not EventBus.battle_finished.is_connected(_on_battle_finished):
		EventBus.battle_finished.connect(_on_battle_finished)
	_sync_components_after_visual_setup()
	_set_enemy_state(&"patrol" if not defeated else &"dead")

func _resolve_modular_components() -> void:
	roaming_behavior = get_node_or_null("Components/EnemyRoamingBehavior") as EnemyRoamingBehavior
	enemy_controller = get_node_or_null("Components/EnemyController")
	if enemy_controller == null:
		push_error("RoamingMonster requires its authored EnemyController child")
		return
	enemy_visual_component = enemy_controller.visual
	movement_component = enemy_controller.movement
	detection_component = enemy_controller.detection
	targeting_component = enemy_controller.targeting
	combat_component = enemy_controller.combat
	health_component = enemy_controller.health
	status_component = enemy_controller.status_effects
	animation_component = enemy_controller.animation
	interaction_component = enemy_controller.interaction
	audio_component = enemy_controller.audio
	vfx_component = enemy_controller.vfx
	state_machine = enemy_controller.state_machine
	if animation_component != null and "visual" in animation_component and visual != null:
		animation_component.visual = visual
	if enemy_visual_component != null and enemy_visual_component.has_method("resolve_nodes"):
		enemy_visual_component.call("resolve_nodes", self)

func _sync_components_from_setup() -> void:
	if movement_component != null:
		if "home_position" in movement_component: movement_component.home_position = home_position
		if "move_speed" in movement_component: movement_component.move_speed = move_speed
		if "roam_radius" in movement_component: movement_component.roam_radius = roam_radius
		if "current_target_position" in movement_component: movement_component.current_target_position = _roam_target
	if interaction_component != null:
		if "prompt_text" in interaction_component: interaction_component.prompt_text = prompt
		if interaction_component.has_method("set_enabled"): interaction_component.call("set_enabled", enabled)
	if health_component != null and health_component.has_method("configure"):
		var hp := 1.0
		if visual_definition.has("base") and typeof(visual_definition.get("base")) == TYPE_DICTIONARY:
			hp = float((visual_definition.get("base") as Dictionary).get("hp", 100.0))
		health_component.call("configure", hp, hp)


func _sync_components_after_visual_setup() -> void:
	if animation_component != null and "visual" in animation_component and visual != null:
		animation_component.visual = visual
	if enemy_visual_component != null and enemy_visual_component.has_method("emit_setup_completed"):
		enemy_visual_component.call("emit_setup_completed")


func _process(delta: float) -> void:
	if defeated:
		_set_enemy_state(&"dead")
		return
	# Engagement cooldown: hold position, never engage, never chase.
	if _engagement_cooldown > 0.0:
		_engagement_cooldown -= delta
		if _engagement_cooldown < 0.0:
			_engagement_cooldown = 0.0
		_play_anim_state(&"idle")
		_set_enemy_state(&"idle")
		return
	if engaged:
		_set_enemy_state(&"attack")
		return
	# Boss encounters are authored arena fixtures, not roaming wildlife. Keep
	# their world position fixed; the player must approach the arena encounter
	# and explicitly interact with it to begin battle.
	if is_boss:
		_roam_target = home_position
		if position.distance_to(home_position) > 0.5:
			position = home_position
		_play_anim_state(&"idle")
		_set_enemy_state(&"idle")
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return

	# Passive roaming is composed by its scene-owned behavior node; encounter
	# initiation remains exclusively behind explicit Interactable.interact().
	if roaming_behavior != null:
		roaming_behavior.process_roaming(self, _player, delta)
	elif enemy_controller != null and enemy_controller.has_method("process_ai"):
		enemy_controller.call("process_ai", delta, {})


func can_interact() -> bool:
	if not super.can_interact() or defeated or engaged or _engagement_cooldown > 0.0:
		return false
	if required_quest.is_empty():
		return true
	return GameState.quest_domain.quest_state(required_quest) == "active" and GameState.quest_domain.quest_step_index(required_quest) >= required_quest_step


func interact() -> void:
	if not can_interact() or engaged or defeated or _engagement_cooldown > 0.0:
		return
	if interaction_component != null and interaction_component.has_method("begin_interaction"):
		interaction_component.call("begin_interaction", _player)
	_begin_encounter()
	if interaction_component != null and interaction_component.has_method("complete_interaction"):
		interaction_component.call("complete_interaction", _player)


func _begin_encounter() -> void:
	# This method is only reached by explicit Interactable.interact() (E / A).
	# Spawn grace must never block a deliberate player challenge.
	if engaged or defeated or _engagement_cooldown > 0.0:
		return
	engaged = true
	if animation_component != null and animation_component.has_method("play_state"):
		animation_component.call("play_state", &"attack")
	_set_enemy_state(&"attack")
	if enemy_controller != null and enemy_controller.has_method("emit_encounter_started"):
		enemy_controller.call("emit_encounter_started")
	EventBus.encounter_requested.emit(group_id, self)


func _on_battle_finished(result: Dictionary) -> void:
	if str(result.get("group_id", "")) != group_id:
		return
	if not engaged:
		return
	var victory := bool(result.get("victory", false))
	if enemy_controller != null and enemy_controller.has_method("emit_encounter_finished"):
		enemy_controller.call("emit_encounter_finished", victory)
	if victory:
		_defeat()
	else:
		engaged = false
		_engagement_cooldown = 8.0
		position = home_position
		_roam_target = home_position
		_set_enemy_state(&"return")
		_set_enemy_state(&"idle")


func _defeat() -> void:
	engaged = false
	defeated = true
	enabled = false
	visible = false
	_set_enemy_state(&"dead")
	if health_component != null and "is_dead" in health_component:
		health_component.is_dead = true
		if health_component.has_signal("died"):
			health_component.emit_signal("died")
	if enemy_controller != null and enemy_controller.has_method("emit_defeated"):
		enemy_controller.call("emit_defeated")
	await get_tree().create_timer(respawn_seconds).timeout
	if not is_instance_valid(self):
		return
	defeated = false
	enabled = true
	visible = true
	position = home_position
	_roam_target = home_position
	_spawn_grace = 2.0
	_engagement_cooldown = 0.0
	if health_component != null and health_component.has_method("revive"):
		health_component.call("revive", 1.0)
	if interaction_component != null and interaction_component.has_method("set_enabled"):
		interaction_component.call("set_enabled", true)
	if enemy_controller != null and enemy_controller.has_method("emit_respawned"):
		enemy_controller.call("emit_respawned")
	_set_enemy_state(&"patrol")


func _world() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group("world")


func _target_walkable(pos: Vector2) -> bool:
	var w := _world()
	if w == null or not is_instance_valid(w):
		return true
	if not w.has_method("is_walkable"):
		return true
	return bool(w.is_walkable(pos))


func _set_enemy_state(state_name: StringName) -> void:
	if enemy_controller != null and enemy_controller.has_method("request_state"):
		var current = state_machine.get("current_state_name") if state_machine != null and "current_state_name" in state_machine else null
		if current != state_name:
			enemy_controller.call("request_state", state_name, {})
	elif state_machine != null and state_machine.has_method("set_state"):
		var current = state_machine.get("current_state_name") if "current_state_name" in state_machine else null
		if current != state_name:
			state_machine.call("set_state", state_name, {})


func _play_anim_state(state_name: StringName) -> void:
	if animation_component != null and animation_component.has_method("play_state"):
		animation_component.call("play_state", state_name)


# --- modular API helpers (reusable/integration surface) ---
func get_enemy_component(component_name: StringName) -> Node:
	match component_name:
		&"controller": return enemy_controller
		&"visual": return enemy_visual_component
		&"movement": return movement_component
		&"detection": return detection_component
		&"targeting": return targeting_component
		&"combat": return combat_component
		&"health": return health_component
		&"status": return status_component
		&"animation": return animation_component
		&"interaction": return interaction_component
		&"audio": return audio_component
		&"vfx": return vfx_component
		&"state_machine": return state_machine
	return null
