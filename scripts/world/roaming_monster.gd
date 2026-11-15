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
var engaged: bool = false
var defeated: bool = false
var respawn_seconds: float = 75.0
## Set by GreenwardWorld before setup(); drives deterministic per-spawn variety.
var spawn_index: int = 0
var _engagement_cooldown: float = 0.0
var _spawn_grace: float = 3.0

var visual: ActorVisual
var visual_definition: Dictionary = {}
var _accent_sprite: Sprite2D
var _roam_target: Vector2
var _roam_timer: float = 0.0
var _player: Node2D
var _name_label: Label

# --- modular components/state (reusable, behavior-preserving integration) ---
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
	_roam_target = position
	_resolve_modular_components()
	_sync_components_from_setup()

	# ---- deterministic per-spawn variety (group_id + spawn_index) ----
	var vseed := absi(("%s|%d" % [group_id, spawn_index]).hash())
	var tints: Array = [
		GreenwardStyle.MAGIC.teal, GreenwardStyle.MAGIC.violet,
		GreenwardStyle.ACCENTS.berry, GreenwardStyle.CANOPY.bright,
		GreenwardStyle.MAGIC.gold,
	]
	var tint: Color = tints[vseed % tints.size()]
	var tinted := _tint_palette(visual_definition.get("palette", {}), tint, 0.12 + float(vseed % 10) * 0.01)
	var scale_variance := 0.85 + float(vseed % 30) * 0.01  # 0.85 .. 1.14

	var enemy_name := str(visual_definition.get("name", "Monster"))
	var def_id := str(visual_definition.get("id", ""))
	var kind := ActorVisual.Kind.MONSTER
	if def_id == "glade_wisp":
		kind = ActorVisual.Kind.SPIRIT

	visual = get_node_or_null("ActorVisual") as ActorVisual
	if visual == null:
		visual = ActorVisual.new() # compatibility for direct test instantiation
		visual.name = "ActorVisual"
		add_child(visual)
	visual.setup(tinted, kind, def_id, "Monster", str(visual_definition.get("element", "neutral")))
	visual.is_boss = is_boss
	visual.visual_scale = (1.35 if is_boss else 1.0) * scale_variance
	# Vary silhouette where feasible via existing ActorVisual.Kind / def_id /
	# race values. Bosses keep their true def_id so the treant boss still draws.
	if not is_boss and def_id != "moonpetal_sprite":
		var silhouettes := ["mossling", "thornhound", "fae_marauder", "glade_wisp", "corrupted_treant"]
		visual.def_id = str(silhouettes[(vseed >> 3) % silhouettes.size()])
	# PART 4: exercise the SpriteFramesActorSource registration seam for this
	# enemy definition id. No disk sheets exist, so the procedural fallback stays.
	visual.configure_character(def_id)
	_add_accent(vseed)

	_name_label = get_node_or_null("NameLabel") as Label
	if _name_label == null:
		_name_label = Label.new()
		_name_label.name = "NameLabel"
		_name_label.position = Vector2(-80, -100 if is_boss else -68)
		_name_label.size = Vector2(160, 22)
		add_child(_name_label)
	_name_label.text = enemy_name
	_name_label.position.y = -100 if is_boss else -68
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 12 if not is_boss else 15)
	_name_label.add_theme_color_override("font_color", GreenwardStyle.MAGIC.ember if not is_boss else GreenwardStyle.UI.gold)
	_name_label.add_theme_color_override("font_outline_color", GreenwardStyle.INK)
	_name_label.add_theme_constant_override("outline_size", 4)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_accent_sprite = get_node_or_null("Accent") as Sprite2D
	if _accent_sprite == null:
		_accent_sprite = Sprite2D.new()
		_accent_sprite.name = "Accent"
		_accent_sprite.centered = false
		add_child(_accent_sprite)

	if not EventBus.battle_finished.is_connected(_on_battle_finished):
		EventBus.battle_finished.connect(_on_battle_finished)
	_sync_components_after_visual_setup()
	_set_enemy_state(&"patrol" if not defeated else &"dead")


func _resolve_modular_components() -> void:
	enemy_controller = get_node_or_null("Components/EnemyController")
	enemy_visual_component = get_node_or_null("Components/EnemyVisual")
	movement_component = get_node_or_null("Components/EnemyMovement")
	detection_component = get_node_or_null("Components/EnemyDetection")
	targeting_component = get_node_or_null("Components/EnemyTargeting")
	combat_component = get_node_or_null("Components/EnemyCombat")
	health_component = get_node_or_null("Components/EnemyHealth")
	status_component = get_node_or_null("Components/EnemyStatusEffects")
	animation_component = get_node_or_null("Components/EnemyAnimation")
	interaction_component = get_node_or_null("Components/EnemyInteraction")
	audio_component = get_node_or_null("Components/EnemyAudio")
	vfx_component = get_node_or_null("Components/EnemyVFX")
	state_machine = get_node_or_null("StateMachine")
	if enemy_controller != null and "owner_enemy" in enemy_controller:
		enemy_controller.owner_enemy = self
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


static func _to_color(v: Variant) -> Color:
	if v is Color:
		return v
	if v is String and str(v).begins_with("#"):
		return Color(str(v))
	return Color("#4f6b3a")


func _tint_palette(p: Dictionary, tint: Color, amount: float) -> Dictionary:
	var out := {}
	for key in p.keys():
		out[key] = _to_color(p[key]).lerp(tint, amount)
	return out


## A tiny deterministic decorative prop accent near the monster's feet.
func _add_accent(vseed: int) -> void:
	if is_boss or (vseed % 3 == 0):
		return
	var kinds := ["crystal", "glow_mushroom", "rune_stone", "spirit_bloom", "mushroom", "pebble"]
	var kind := str(kinds[vseed % kinds.size()])
	var tex := ProceduralArt.prop_texture(kind, vseed % 2)
	if tex == null:
		return
	if _accent_sprite == null:
		return
	_accent_sprite.texture = tex
	_accent_sprite.offset = Vector2(-float(tex.get_width()) * 0.5, -float(tex.get_height()) + 6.0)
	_accent_sprite.scale = Vector2.ONE * 0.4
	_accent_sprite.position = Vector2(14.0 * (1.0 if vseed % 2 == 0 else -1.0), 0.0)
	_accent_sprite.visible = true


func _process(delta: float) -> void:
	if defeated:
		_set_enemy_state(&"dead")
		return
	# Engagement cooldown: hold position, never engage, never chase.
	if _engagement_cooldown > 0.0:
		_engagement_cooldown -= delta
		if _engagement_cooldown < 0.0:
			_engagement_cooldown = 0.0
		if visual != null:
			visual.walking = false
			visual.play(ANIM_IDLE)
		_play_anim_state(&"idle")
		_set_enemy_state(&"idle")
		return
	if engaged:
		_set_enemy_state(&"attack")
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return

	# Preserve existing passive-roam behavior: no auto aggro/chase, interact-only encounter.
	# Detection/targeting components are updated/evaluated for modular architecture integration.
	if detection_component != null and detection_component.has_method("evaluate"):
		detection_component.call("evaluate", self, _player as Node2D)
	if targeting_component != null and targeting_component.has_method("clear_target"):
		targeting_component.call("clear_target")
	if status_component != null and status_component.has_method("tick"):
		status_component.call("tick", delta)
	if combat_component != null and "attack_cooldown_remaining" in combat_component:
		# combat component has its own cooldown timer via _process; keep state idle while roaming
		pass

	# Monsters never initiate combat from proximity or chase the player.
	# They roam inside their home radius and remain passive until the player
	# approaches and explicitly presses E / the Interact button.
	_roam_timer -= delta
	if _roam_timer <= 0.0:
		_roam_timer = randf_range(2.0, 5.0)
		if movement_component != null and movement_component.has_method("reset_roam_timer"):
			# keep component in sync (component timer unused for authoritative movement below)
			pass
		var found := false
		for _attempt in 8:
			var offset := Vector2(randf_range(-roam_radius, roam_radius), randf_range(-roam_radius, roam_radius))
			var candidate := home_position + offset
			if _target_walkable(candidate):
				_roam_target = candidate
				found = true
				break
		if not found:
			_roam_target = position
		if movement_component != null and "current_target_position" in movement_component:
			movement_component.current_target_position = _roam_target
	if position.distance_to(_roam_target) > 4.0 and _target_walkable(_roam_target):
		var to_target := _roam_target - position
		position = position.move_toward(_roam_target, move_speed * delta)
		if visual != null:
			visual.walking = true
			visual.set_move_direction(to_target)
			visual.play(ANIM_WALK)
		_play_anim_state(&"patrol")
		_set_enemy_state(&"patrol")
	else:
		if visual != null:
			visual.walking = false
			visual.play(ANIM_IDLE)
		_play_anim_state(&"idle")
		_set_enemy_state(&"idle")

	if state_machine != null and state_machine.has_method("process_state"):
		state_machine.call("process_state", delta, {})


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
	if visual != null:
		visual.walking = false
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
	if state_machine != null and state_machine.has_method("set_state"):
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
