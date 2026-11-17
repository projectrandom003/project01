extends Node
## Headless test runner for the Project Fantasy vertical slice.
##
## Run with:
##   Godot --headless --path . res://tests/test_runner.tscn
##
## The runner snapshots the local save and the live GameState before exercising
## gameplay, then restores both, so running tests never destroys a player save.

const _CraftingServiceScript = preload("res://scripts/items/crafting_service.gd")

var passed: int = 0
var failed: int = 0
var failures: Array[String] = []

var _state_snapshot: Dictionary = {}
var _save_snapshot: String = ""
var _had_save: bool = false
var _loaded_from_save: bool = false

# Phase-4 signal counter for transition_to()/transitioned observations.
var _phase4_transition_count: int = 0
var _roaming_encounter_count: int = 0
var _region_change_count: int = 0


func _on_test_region_change(_target_region: String, _entry_point: String) -> void:
	_region_change_count += 1


func _phase4_on_transitioned(_from_state: int, _to_state: int, _direction: int) -> void:
	_phase4_transition_count += 1


func _on_test_roaming_encounter(_group_id: String, _source: Node) -> void:
	_roaming_encounter_count += 1


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_snapshot()
	_test_content()
	await _test_player_node_composition()
	_test_application_scene_composition()
	_test_math()
	_test_gacha()
	await _test_ui_regressions()
	_test_combat()
	_test_combat_cooldowns()
	_test_combat_engine_ownership()
	# --- Phase 2: passives, equipment, strict content validation, quest gating ---
	_test_passive_multipliers()
	_test_passive_battle_hooks()
	_test_equipment_bonuses()
	_test_gear_enhancement()
	_test_crafting_service()
	_test_shop_service()
	_test_invalid_json()
	_test_duplicate_keys()
	_test_missing_references()
	_test_invalid_banner_configs()
	_test_quest_requirements()
	_test_moonpetal_story_content()
	_test_reward_validation()
	# --- Phase 3: visual style, animation, procedural art, world integration ---
	_test_visual_style()
	_test_character_animator()
	_test_actor_frame_source()
	_test_procedural_variety()
	_test_chunk_visual_quality()
	_test_weather_director()
	await _test_animated_and_interactive_props()
	await _test_roaming_monster_manual_encounter()
	await _test_world_visual_integration()
	# --- Phase 4: multi-region graph, asset manifest/loading fallbacks, additive
	#     CAST animation, chunk preparer, world integration, procedural art ---
	_test_region_definitions()
	_test_region_graph_transitions()
	_test_region_gate_unlocks()
	_test_invalid_connections()
	_test_region_save_state()
	await _test_reverie_expansion()
	await _test_new_journey_castle_continue()
	await _test_continue_exact_position_and_return_to_title()
	await _test_continue_legacy_greenward_save()
	await _test_continue_does_not_revert_to_greenward_when_save_is_castle()
	_test_asset_manifest()
	await _test_asset_loading_fallbacks()
	await _test_animation_sheet_validation()
	_test_animation_transitions()
	_test_chunk_preparer()
	await _test_world_region_integration()
	_test_procedural_art_phase4()
	# --- Phase 5: character art pipeline/specs/registry, portrait + sprite
	#     loading seams, missing-asset fallbacks, premium UI presentation, world
	#     visual standards and the honest ZERO-final-asset status contract ---
	_test_character_art_pipeline()
	_test_character_art_specs()
	_test_character_asset_registry()
	await _test_character_portrait_loading()
	_test_sprite_sheet_registration()
	await _test_missing_asset_fallbacks()
	await _test_gacha_presentation()
	await _test_world_visual_standards()
	_test_asset_status_honesty()
	_test_state()
	await _test_ui()
	_test_minimap_marker_filtering()
	# --- Phase 6 Round 3A: character progression ---
	_test_progression_xp()
	_test_progression_leveling()
	_test_progression_max_level()
	_test_progression_stat_growth()
	_test_progression_ascension()
	_test_progression_insufficient_materials()
	_test_progression_insufficient_gold()
	_test_progression_save_load()
	_test_progression_invalid_upgrade()
	_test_progression_combat_stats()
	await _test_exploration_rewards()
	await _test_bonus_drop_rewards()
	await _test_settings_regressions()
	_restore()
	# Drain deferred queue_free() calls and renderer/UI teardown work before
	# quitting. The suite constructs and detaches many dynamic Controls across
	# repeated scene loads; allow enough frames for deferred UI frees to settle.
	for _frame in range(10):
		await get_tree().process_frame
	print("")
	print("==================================================")
	print("PROJECT FANTASY TESTS: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		for message in failures:
			print("  FAIL  " + message)
	print("==================================================")
	get_tree().quit(0 if failed == 0 else 1)

# ------------------------------------------------------------------- harness

func check(condition: bool, label: String, detail: String = "") -> void:
	if condition:
		passed += 1
		return
	failed += 1
	var message := label if detail.is_empty() else "%s — %s" % [label, detail]
	failures.append(message)
	push_error("[TEST] " + message)


func near(a: float, b: float, epsilon: float = 0.001) -> bool:
	return absf(a - b) <= epsilon


# ------------------------------------------------- Phase 2 shared test helpers

## Build a deterministic Combatant from scratch (no saved data, no ContentDB).
func _unit(uid: String, passive_id: String = "", element: String = "neutral") -> Combatant:
	var c := Combatant.new()
	c.uid = uid
	c.display_name = uid
	c.element = element
	c.passive_id = passive_id
	c.max_hp = 1000.0
	c.hp = 1000.0
	c.atk = 100.0
	c.defense = 100.0
	c.speed = 100.0
	c.crit_chance = 0.0
	return c


## True if any validation error string contains needle.
func _has_error(errors: Array, needle: String) -> bool:
	for e in errors:
		if needle in str(e):
			return true
	return false


## A complete, valid banner document used as the base for negative configs.
func _base_banner() -> Dictionary:
	return {
		"name": "Test Banner",
		"type": "standard",
		"subtitle": "synthetic",
		"featured": ["lyra_vey"],
		"featured_rate": 0.5,
		"rates": { "common": 0.52, "rare": 0.30, "epic": 0.13, "legendary": 0.045, "mythic": 0.005 },
		"hard_pity": 70,
		"featured_pity": 140,
		"ten_pull_epic_guarantee": true,
		"cost": { "currency": "crystals", "single": 150, "ten": 1350 },
		"pool": {
			"common": ["mira_sol"],
			"rare": ["bramble", "thistle", "kael"],
			"epic": ["lyra_vey", "coralyn", "vespera", "arachnia"],
			"legendary": ["seraphine", "nyx", "terra"],
			"mythic": ["ignis"]
		}
	}


func _passive_event_amount(events: Array, passive_id: String) -> float:
	for ev in events:
		if str(ev.get("type", "")) == "passive" and str(ev.get("passive", "")) == passive_id:
			return float(ev.get("amount", -1.0))
	return -1.0


func _shield_event_amount(events: Array, source: String) -> float:
	for ev in events:
		if str(ev.get("type", "")) == "shield" and str(ev.get("source", "")) == source:
			return float(ev.get("amount", -1.0))
	return -1.0


func _has_status_event(events: Array, status_id: String, source: String) -> bool:
	for ev in events:
		if str(ev.get("type", "")) == "status" and str(ev.get("status", "")) == status_id and str(ev.get("source", "")) == source:
			return true
	return false


func _snapshot() -> void:
	_state_snapshot = GameState._to_dict().duplicate(true)
	_had_save = FileAccess.file_exists(SaveService.SAVE_PATH)
	if _had_save:
		_save_snapshot = FileAccess.get_file_as_string(SaveService.SAVE_PATH)
	_loaded_from_save = GameState.loaded_from_save
	GameState._save_timer.stop()
	GameState._autosave_timer.stop()


func _restore() -> void:
	GameState._load_from_dict(_state_snapshot.duplicate(true))
	GameState.loaded_from_save = _loaded_from_save
	if _had_save:
		var file := FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(_save_snapshot)
			file.close()
	else:
		SaveService.delete_save()
	GameState._autosave_timer.start()


# ------------------------------------------------------------------- content

func _test_player_node_composition() -> void:
	var packed := load("res://scenes/characters/player.tscn") as PackedScene
	check(packed != null, "Player composition scene loads")
	if packed == null:
		return
	var player := packed.instantiate() as Player
	add_child(player)
	await get_tree().process_frame
	check(player.get_node_or_null("LocomotionComponent") is PlayerLocomotionComponent, "Player scene owns a locomotion component")
	check(player.get_node_or_null("InteractionComponent") is CharacterInteractionComponent, "Player scene owns an interaction component")
	check(player.get_node_or_null("AvatarComponent") is PlayerAvatarComponent, "Player scene owns an avatar configuration component")
	check(player.get_node_or_null("PresentationComponent") is PlayerPresentationComponent, "Player scene owns a presentation component")
	check(player.presentation_component != null and EventBus.battle_finished.is_connected(player.presentation_component._on_battle_finished), "Player presentation component owns battle-result event binding")
	check(player.get_node_or_null("PersonalGlow") is PlayerPersonalLightComponent, "Player scene owns a personal-light component")
	check(player.get_child_count() == 12, "Player binds its authored 12-node hierarchy without runtime child construction", str(player.get_child_count()))
	check(player.camera is PlayerCameraRig, "Player camera is a dedicated camera rig node")
	var camera_rig := player.camera as PlayerCameraRig
	camera_rig.update_follow_offset(1.0, Vector2(100.0, 0.0), 1.0)
	check(camera_rig.offset.x > 27.0, "Player camera rig owns smoothed movement lookahead")
	camera_rig.update_follow_offset(1.0, Vector2.ZERO, 0.0)
	check(camera_rig.offset.length() < 1.0, "Player camera rig recenters when movement stops")
	check(player.visual != null and player.visual.get_parent() == player, "Player visual is a composed child node")
	check(player.get_node_or_null("NameLabel") is Label, "Player scene authors the name label")
	check(player.get_node_or_null("WaterSurface") is Sprite2D, "Player scene authors the water surface")
	check(player.get_node_or_null("PersonalGlow") is PlayerPersonalLightComponent, "Player scene authors the personal light")
	check(player.locomotion_component != null and player.locomotion_component.body == player, "Locomotion component binds to its owning Player")
	var kael_motion := PlayerLocomotionComponent.movement_profile("kael")
	var gerald_motion := PlayerLocomotionComponent.movement_profile("gerald")
	var lilith_motion := PlayerLocomotionComponent.movement_profile("lilith")
	check(float(gerald_motion.walk) < float(kael_motion.walk) and float(gerald_motion.accel) < float(kael_motion.accel), "Gerald has deliberately heavier, slower world locomotion")
	check(float(lilith_motion.walk) > float(kael_motion.walk) and float(lilith_motion.accel) > float(kael_motion.accel), "Lilith has a lighter, more responsive world locomotion")
	check(float(gerald_motion.friction) > float(kael_motion.friction) and float(lilith_motion.friction) < float(kael_motion.friction), "Character weight also shapes stopping distance")
	check(is_equal_approx(float(PlayerLocomotionComponent.movement_profile("unknown").walk), float(kael_motion.walk)), "Unknown avatars safely use the balanced default movement profile")
	check(player.interaction_component != null and player.interaction_component.interactable_changed.is_connected(player._on_interactable_changed), "Player receives interaction component state through a signal")
	# Exercise the real nearest-target contract independently of the periodic scan.
	player.interaction_component.scan_enabled = false
	var far_target := Interactable.new()
	far_target.name = "PlayerTestFarInteractable"
	far_target.position = Vector2(52.0, 0.0)
	far_target.prompt = "Far target"
	add_child(far_target)
	var near_target := Interactable.new()
	near_target.name = "PlayerTestNearInteractable"
	near_target.position = Vector2(18.0, 0.0)
	near_target.prompt = "Near target"
	add_child(near_target)
	await get_tree().process_frame
	check(player.interaction_component.refresh_nearest() == near_target, "Player interaction selects the nearest valid target")
	check(player.current_prompt() == "Near target", "Player facade exposes the active interaction prompt")
	near_target.enabled = false
	check(player.interaction_component.refresh_nearest() == far_target, "Player interaction skips disabled targets and selects the next valid target")
	far_target.visible = false
	check(player.interaction_component.refresh_nearest() == null, "Player interaction ignores hidden targets")
	far_target.visible = true
	near_target.enabled = true
	player.interaction_component.refresh_nearest()
	var interaction_requests := {"count": 0}
	player.interaction_component.interaction_requested.connect(func(_target: Node) -> void: interaction_requests["count"] = int(interaction_requests["count"]) + 1)
	check(player.interaction_component.try_interact(), "Player interaction accepts an explicit interaction request")
	check(int(interaction_requests["count"]) == 1, "Player interaction emits exactly one request per activation", "requests=" + str(interaction_requests["count"]))
	near_target.enabled = false
	check(not player.interaction_component.try_interact(), "Player interaction safely rejects a disabled stale target")
	near_target.enabled = true
	player.interaction_component.refresh_nearest()
	near_target.position = Vector2(500.0, 0.0)
	check(not player.interaction_component.try_interact(), "Player interaction safely rejects a target that moved out of range")
	check(player.current_prompt().is_empty(), "Player interaction clears stale prompts after a rejected activation")
	player.velocity = Vector2.ZERO
	var locomotion_start := player.global_position
	Input.action_press("move_right")
	for frame in range(4):
		await get_tree().physics_frame
	Input.action_release("move_right")
	check(player.velocity.x > 0.0, "Player locomotion accelerates from real InputMap movement")
	check(player.global_position.x > locomotion_start.x, "Player CharacterBody2D advances under physics movement")
	check(player.visual != null and player.visual.walking, "Player locomotion drives the ActorVisual walking state")
	var moving_speed := player.velocity.length()
	for frame in range(18):
		await get_tree().physics_frame
	check(player.velocity.length() < moving_speed, "Player locomotion applies friction after movement input is released")
	near_target.queue_free()
	far_target.queue_free()
	player.queue_free()
	await get_tree().process_frame


func _test_application_scene_composition() -> void:
	check(GameState.inventory_domain != null, "Inventory domain is bound on the live GameState autoload")
	check(GameState.quest_domain != null, "Quest domain is bound on the live GameState autoload")
	check(GameState.roster_domain != null, "Roster domain is bound on the live GameState autoload")
	check(GameState.reward_domain != null, "Reward domain is bound on the live GameState autoload")
	check(GameState.inventory_domain.currency("gold") == GameState.currency("gold"), "InventoryDomain is the direct wallet API while GameState keeps its compatibility wrapper")
	check(GameState.roster_domain.owns_character("kael") == GameState.owns_character("kael"), "RosterDomain is the direct roster API while GameState keeps its compatibility wrapper")
	check(GameState.quest_domain.quest_state("the_first_path") == GameState.quest_state("the_first_path"), "QuestDomain is the direct quest API while GameState keeps its compatibility wrapper")
	check(GameState.reward_domain.has_method("apply_battle_result"), "RewardDomain directly owns battle reward application")
	check(GameState.persistence_component is GameStatePersistenceComponent and GameState.persistence_component.get_parent() == GameState, "GameState binds its authored persistence component")
	check(GameState._save_timer is Timer and GameState._save_timer.get_parent() == GameState, "GameState binds its authored save timer")
	check(GameState._autosave_timer is Timer and GameState._autosave_timer.get_parent() == GameState, "GameState binds its authored autosave timer")
	check(GameState.get_child_count() == 9, "GameState owns only its nine authored domain, persistence and timer children", str(GameState.get_child_count()))
	check(GameState.inventory_domain.inventory == GameState.inventory, "InventoryDomain owns inventory data behind the GameState compatibility property")
	check(GameState.roster_domain.roster == GameState.roster and GameState.roster_domain.party == GameState.party, "RosterDomain owns roster and party data behind compatibility properties")
	check(GameState.roster_domain.gear_levels == GameState.gear_levels, "RosterDomain owns gear progression data behind the compatibility property")
	check(GameState.quest_domain.quests == GameState.quests and GameState.quest_domain.flags == GameState.flags, "QuestDomain owns quest and world-flag data behind compatibility properties")
	check(GameState.reward_domain.pity == GameState.pity, "RewardDomain owns summon pity data behind the compatibility property")
	check(GameState.profile_domain is GameProfileDomainComponent and GameState.profile_domain.get_parent() == GameState, "ProfileDomain owns player profile data")
	check(GameState.profile_domain.profile == GameState.profile, "ProfileDomain data is exposed through the GameState compatibility property")
	check(GameState.session_domain is GameSessionDomainComponent and GameState.session_domain.get_parent() == GameState, "SessionDomain owns active-world and player-location state")
	check(GameState.session_domain.player_region == GameState.player_region and GameState.session_domain.region_positions == GameState.region_positions, "SessionDomain data is exposed through GameState compatibility properties")
	var state_scene := load("res://scenes/core/game_state.tscn") as PackedScene
	check(state_scene != null, "Persistent GameState scene loads")
	if state_scene != null:
		var state := state_scene.get_state()
		var state_nodes: Array[String] = []
		for index in state.get_node_count():
			state_nodes.append(str(state.get_node_name(index)))
		check(state_nodes.has("InventoryDomain"), "Persistent GameState authors an inventory-domain node")
		check(state_nodes.has("QuestDomain"), "Persistent GameState authors a quest-domain node")
		check(state_nodes.has("RosterDomain"), "Persistent GameState authors a roster-domain node")
		check(state_nodes.has("RewardDomain"), "Persistent GameState authors a reward-domain node")
		check(state_nodes.has("Persistence"), "Persistent GameState authors its persistence component")
		check(state_nodes.has("SaveTimer"), "Persistent GameState authors its debounce-save timer")
		check(state_nodes.has("AutosaveTimer"), "Persistent GameState authors its periodic autosave timer")
		check(state_nodes.has("ProfileDomain"), "Persistent GameState authors a profile domain")
		check(state_nodes.has("SessionDomain"), "Persistent GameState authors a session domain")
	var game_scene := load("res://scenes/game.tscn") as PackedScene
	check(game_scene != null, "Game composition scene loads")
	if game_scene != null:
		var game_state := game_scene.get_state()
		var game_nodes: Array[String] = []
		for index in game_state.get_node_count():
			game_nodes.append(str(game_state.get_node_name(index)))
		check(game_nodes.has("WorldHost"), "Game scene authors a dedicated WorldHost node")
		check(game_nodes.has("WorldSession"), "Game scene authors a world-session controller node")
		check(game_nodes.has("OverlayRouter"), "Game scene authors an overlay-router component")
		check(game_nodes.has("CombatRouter"), "Game scene authors a combat-router component")
		check(game_nodes.has("UI"), "Game scene authors the UI hierarchy")
		check(game_nodes.has("InputRouter"), "Game scene authors its gameplay input router")
		check(game_nodes.has("Runtime"), "Game scene authors its runtime/HUD refresh component")
	var shop_layout := load("res://scenes/ui/components/shop_screen_layout.tscn") as PackedScene
	check(shop_layout != null, "Shop screen static layout scene loads")
	if shop_layout != null:
		var shop_state := shop_layout.get_state()
		var shop_nodes: Array[String] = []
		for index in shop_state.get_node_count():
			shop_nodes.append(str(shop_state.get_node_name(index)))
		check(shop_nodes.has("WalletLabel") and shop_nodes.has("StockScroll"), "Shop screen authors its wallet and stock-list shell")
	var crafting_panel_scene := load("res://scenes/ui/components/inventory_crafting_panel.tscn") as PackedScene
	check(crafting_panel_scene != null, "Inventory crafting panel authored scene loads")
	if crafting_panel_scene != null:
		var crafting_state := crafting_panel_scene.get_state()
		var crafting_nodes: Array[String] = []
		for index in crafting_state.get_node_count():
			crafting_nodes.append(str(crafting_state.get_node_name(index)))
		check(crafting_nodes.has("Body") and crafting_nodes.has("RecipeList") and crafting_nodes.has("CloseButton"), "Inventory crafting panel authors its body, recipe list and close control")
	var gacha_scene := load("res://scenes/ui/gacha_screen.tscn") as PackedScene
	check(gacha_scene != null, "Gacha screen scene loads")
	if gacha_scene != null:
		var gacha_state := gacha_scene.get_state()
		var gacha_nodes: Array[String] = []
		for index in gacha_state.get_node_count():
			gacha_nodes.append(str(gacha_state.get_node_name(index)))
		check(gacha_nodes.has("BannerContent"), "Gacha scene authors its banner-content component")
		check(gacha_nodes.has("SummonFlow"), "Gacha scene authors its summon-flow component")
		check(gacha_nodes.has("SummoningChamberAtmosphere"), "Gacha scene authors its chamber-atmosphere component")
	var collection_scene := load("res://scenes/ui/collection_screen.tscn") as PackedScene
	check(collection_scene != null, "Collection screen scene loads")
	if collection_scene != null:
		var collection_state := collection_scene.get_state()
		var collection_nodes: Array[String] = []
		for index in collection_state.get_node_count():
			collection_nodes.append(str(collection_state.get_node_name(index)))
		check(collection_nodes.has("Roster"), "Collection scene authors its roster component")
		check(collection_nodes.has("Detail"), "Collection scene authors its detail component")
	var actor_visual_scene := load("res://scenes/characters/actor_visual.tscn") as PackedScene
	check(actor_visual_scene != null, "ActorVisual scene loads")
	if actor_visual_scene != null:
		var actor_visual_state := actor_visual_scene.get_state()
		var actor_visual_nodes: Array[String] = []
		for index in actor_visual_state.get_node_count():
			actor_visual_nodes.append(str(actor_visual_state.get_node_name(index)))
		check(actor_visual_nodes.has("ProceduralRenderer"), "ActorVisual scene authors its procedural renderer component")
		check(actor_visual_nodes.has("CharacterEffects"), "ActorVisual scene authors its character-specific effects component")
		check(actor_visual_nodes.has("Pose"), "ActorVisual scene authors its locomotion-pose component")
		check(actor_visual_nodes.has("SpritePresentation"), "ActorVisual scene authors its frame-source and sprite-presentation component")
	var hud_scene := load("res://scenes/ui/hud.tscn") as PackedScene
	check(hud_scene != null, "HUD scene loads")
	if hud_scene != null:
		var hud_state := hud_scene.get_state()
		var hud_nodes: Array[String] = []
		for index in hud_state.get_node_count():
			hud_nodes.append(str(hud_state.get_node_name(index)))
		check(hud_nodes.has("Currency"), "HUD scene authors its currency component")
		check(hud_nodes.has("Party"), "HUD scene authors its party component")
		check(hud_nodes.has("Quest"), "HUD scene authors its quest component")
		check(hud_nodes.has("Toast"), "HUD scene authors its toast component")
	var settings_scene := load("res://scenes/ui/settings_screen.tscn") as PackedScene
	check(settings_scene != null, "Settings screen scene loads")
	if settings_scene != null:
		var settings_state := settings_scene.get_state()
		var settings_nodes: Array[String] = []
		for index in settings_state.get_node_count():
			settings_nodes.append(str(settings_state.get_node_name(index)))
		check(settings_nodes.has("Controls"), "Settings scene authors its controls/rebinding component")
		check(settings_nodes.has("Persistence"), "Settings scene authors its settings-persistence component")
	var settings_layout := load("res://scenes/ui/components/settings_screen_layout.tscn") as PackedScene
	check(settings_layout != null, "Settings static layout scene loads")
	if settings_layout != null:
		var settings_layout_state := settings_layout.get_state()
		var settings_layout_nodes: Array[String] = []
		for index in settings_layout_state.get_node_count():
			settings_layout_nodes.append(str(settings_layout_state.get_node_name(index)))
		check(settings_layout_nodes.has("MasterSlider") and settings_layout_nodes.has("FullscreenCheck") and settings_layout_nodes.has("ResolutionOption"), "Settings scene authors audio and display controls")
		check(settings_layout_nodes.has("ControlsBox") and settings_layout_nodes.has("ApplyButton") and settings_layout_nodes.has("CancelButton"), "Settings scene authors controls list and footer actions")
	var combat_scene := load("res://scenes/ui/combat_screen.tscn") as PackedScene
	check(combat_scene != null, "Combat screen scene loads")
	if combat_scene != null:
		var combat_state := combat_scene.get_state()
		var combat_nodes: Array[String] = []
		for index in combat_state.get_node_count():
			combat_nodes.append(str(combat_state.get_node_name(index)))
		check(combat_nodes.has("Feedback"), "Combat screen authors its transient feedback component")
		check(combat_nodes.has("TurnFlow"), "Combat screen authors its turn-flow component")
		check(combat_nodes.has("Targeting"), "Combat screen authors its targeting component")
		check(combat_nodes.has("TurnOrder"), "Combat screen authors its turn-order presentation component")
		check(combat_nodes.has("Results"), "Combat screen authors its battle-result component")
		check(combat_nodes.has("Events"), "Combat screen authors its combat-event presentation component")
		check(combat_nodes.has("HUD"), "Combat screen authors its battle HUD/roster component")
		check(combat_nodes.has("LayoutBuilder"), "Combat screen authors its layout-binding component")
	var battlefield_scene := load("res://scenes/ui/battlefield.tscn") as PackedScene
	check(battlefield_scene != null, "Battlefield composition scene loads")
	if battlefield_scene != null:
		var battlefield_state := battlefield_scene.get_state()
		var battlefield_nodes: Array[String] = []
		for index in battlefield_state.get_node_count():
			battlefield_nodes.append(str(battlefield_state.get_node_name(index)))
		check(battlefield_nodes.has("Layout"), "Battlefield scene authors its layout/actor component")
		check(battlefield_nodes.has("Effects"), "Battlefield scene authors its combat-effects component")
		check(battlefield_nodes.has("KaelAttackPresentation"), "Battlefield scene authors Kael-specific attack choreography separately")
		check(battlefield_nodes.has("MatronAttackPresentation"), "Battlefield scene authors Fallen Matron-specific attack choreography separately")
		check(battlefield_nodes.has("GenericAttackPresentation"), "Battlefield scene authors generic attack choreography separately")
	var world_scene := load("res://scenes/world/greenward_world.tscn") as PackedScene
	check(world_scene != null, "Greenward world composition scene loads")
	if world_scene != null:
		var world_state := world_scene.get_state()
		var world_nodes: Array[String] = []
		for index in world_state.get_node_count():
			world_nodes.append(str(world_state.get_node_name(index)))
		check(world_nodes.has("Navigation"), "World scene authors its navigation component")
		check(world_nodes.has("PlayerSpawn"), "World scene authors its player-spawn component")
		check(world_nodes.has("Entities"), "World scene authors its entity-spawner component")
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	check(main_scene != null, "Main application scene loads")
	if main_scene != null:
		var main_state := main_scene.get_state()
		var main_nodes: Array[String] = []
		for index in main_state.get_node_count():
			main_nodes.append(str(main_state.get_node_name(index)))
		check(main_nodes.has("StartupFlow") and main_nodes.has("GameplayFlow"), "Main scene authors its startup and gameplay flow components")


func _test_content() -> void:
	check(ContentDB.validation_errors.is_empty(), "ContentDB validation", "; ".join(ContentDB.validation_errors))
	check(ContentDB.characters.size() >= 12, "At least 12 characters", str(ContentDB.characters.size()))
	check(ContentDB.skills.size() >= 30, "At least 30 skills", str(ContentDB.skills.size()))
	for skill_id in ContentDB.skills.keys():
		var skill: SkillDef = ContentDB.get_skill(str(skill_id))
		check(skill != null and not skill.animation_key.is_empty(), "Skill has an animation key: " + str(skill_id))
		check(skill != null and not skill.vfx_key.is_empty(), "Skill has a VFX key: " + str(skill_id))
		check(skill != null and skill.scaling_stat in ["atk", "def", "hp", "spd"], "Skill scaling stat is supported: " + str(skill_id))
		check(skill != null and skill.cooldown_turns >= 0, "Skill cooldown is non-negative: " + str(skill_id))
		check(skill != null and not skill.ai_tags.is_empty(), "Skill has AI tags: " + str(skill_id))
	check(ContentDB.enemies.size() >= 6, "At least 6 enemies", str(ContentDB.enemies.size()))
	check(ContentDB.enemy_groups.size() >= 5, "At least 5 enemy groups", str(ContentDB.enemy_groups.size()))
	check(ContentDB.items.size() >= 10, "At least 10 items", str(ContentDB.items.size()))
	check(ContentDB.banners.size() >= 2, "At least 2 banners", str(ContentDB.banners.size()))
	check(ContentDB.quests.size() >= 2, "At least 2 quests", str(ContentDB.quests.size()))
	check(not ContentDB.regions.is_empty(), "At least 1 region")

	for character_id in ContentDB.characters.keys():
		var character: CharacterDef = ContentDB.get_character(str(character_id))
		check(character != null, "Character definition exists: " + str(character_id))
		if character == null:
			continue
		check(not character.display_name.is_empty(), "Character has a name: " + str(character_id))
		check(character.skills.size() >= 2, "Character has 2+ active skills: " + str(character_id))
		check(character.skills.size() + (0 if character.ultimate.is_empty() else 1) >= 3, "Character has a 3-ability kit: " + str(character_id))
		for skill_id in character.skills:
			check(ContentDB.skills.has(skill_id), "Character skill resolves: %s/%s" % [character_id, skill_id])
		check(
			character.ultimate.is_empty() or ContentDB.skills.has(character.ultimate),
			"Character ultimate resolves: " + str(character_id)
		)
		check(character.stat("hp") > 0.0 and character.stat("atk") > 0.0, "Character stats positive: " + str(character_id))

	for group_id in ContentDB.enemy_groups.keys():
		var group: Dictionary = ContentDB.get_enemy_group(str(group_id))
		var units := CombatFactory.enemy_units(str(group_id))
		check(
			units.size() == group.get("enemies", []).size(),
			"Enemy group builds every unit: " + str(group_id),
			"%d/%d" % [units.size(), group.get("enemies", []).size()]
		)
		for unit in units:
			check(unit.max_hp > 0.0 and unit.atk > 0.0, "Enemy stats positive: " + str(unit.def_id))

	var boss_units := CombatFactory.enemy_units("elder_hollow")
	check(boss_units.size() == 1 and boss_units[0].is_boss, "Boss group is flagged as boss")

	for banner_id in ContentDB.banners.keys():
		var banner: Dictionary = ContentDB.get_banner(str(banner_id))
		var rate_total := 0.0
		for rarity in banner.get("rates", {}).keys():
			rate_total += float(banner["rates"][rarity])
		check(near(rate_total, 1.0, 0.02), "Banner rates sum to 1: " + str(banner_id), str(rate_total))
		check(not banner.get("pool", {}).is_empty(), "Banner has a pool: " + str(banner_id))
		check(not banner.get("featured", []).is_empty(), "Banner has a featured character: " + str(banner_id))

	for quest_id in ContentDB.quests.keys():
		var quest: Dictionary = ContentDB.get_quest(str(quest_id))
		check(not quest.get("steps", []).is_empty(), "Quest has steps: " + str(quest_id))
		for step in quest.get("steps", []):
			check(
				str(step.get("type", "")) in ["talk", "kill", "collect", "visit"],
				"Quest step type is supported: %s/%s" % [quest_id, step.get("type", "")]
			)


# ---------------------------------------------------------------------- math

func _test_math() -> void:
	var points := [
		Vector2.ZERO,
		Vector2(1, 0),
		Vector2(0, 1),
		Vector2(-7.5, 3.25),
		Vector2(123.75, -42.5),
		Vector2(16, 16),
	]
	for point in points:
		var world := IsoMath.grid_to_world(point.x, point.y)
		var round_trip := IsoMath.world_to_grid(world)
		check(
			near(round_trip.x, point.x, 0.0001) and near(round_trip.y, point.y, 0.0001),
			"Iso round trip: " + str(point),
			str(round_trip)
		)

	check(IsoMath.chunk_of_grid(Vector2(0, 0), 16) == Vector2i(0, 0), "Chunk origin")
	check(IsoMath.chunk_of_grid(Vector2(-0.1, -0.1), 16) == Vector2i(-1, -1), "Chunk negative floor")
	check(IsoMath.chunk_of_grid(Vector2(16.0, 31.9), 16) == Vector2i(1, 1), "Chunk positive")
	check(IsoMath.chunk_origin_grid(Vector2i(-2, 3), 16) == Vector2(-32, 48), "Chunk origin grid")

	var streamer := ChunkStreamer.new(16, 2)
	var needed := streamer.needed_chunks(Vector2.ZERO)
	check(needed.size() == 25, "Radius-2 streamer needs 25 chunks", str(needed.size()))
	check(needed[0] == Vector2i(0, 0), "Streamer starts at the center chunk")
	var unique := {}
	for chunk in needed:
		unique[chunk] = true
	check(unique.size() == needed.size(), "Streamer chunk list has no duplicates")
	check(streamer.is_needed(Vector2i(2, -2), Vector2.ZERO), "Chunk inside radius is needed")
	check(not streamer.is_needed(Vector2i(3, 0), Vector2.ZERO), "Chunk outside radius is not needed")

	var tight := ChunkStreamer.new(16, 0)
	check(tight.needed_chunks(Vector2.ZERO).size() == 1, "Radius-0 streamer needs 1 chunk")
	check(
		near(IsoMath.distance_to_segment(Vector2(0, 0), Vector2(-10, 0), Vector2(10, 0)), 0.0),
		"Point on segment has zero distance"
	)
	check(
		near(IsoMath.distance_to_segment(Vector2(0, 5), Vector2(-10, 0), Vector2(10, 0)), 5.0),
		"Perpendicular distance to segment"
	)


# --------------------------------------------------------------------- gacha

func _test_gacha() -> void:
	var banner: Dictionary = ContentDB.get_banner("crimson_covenant")
	check(not banner.is_empty(), "Summon banner loads")

	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var outcome := GachaService.pull(banner, rng, GachaService.empty_pity(), 10)
	check(outcome.results.size() == 10, "Ten-pull returns 10 results", str(outcome.results.size()))
	var best_rank := -1
	for roll in outcome.results:
		var character: CharacterDef = ContentDB.get_character(str(roll.character_id))
		check(character != null, "Ten-pull result is a real character: " + str(roll.character_id))
		best_rank = maxi(best_rank, int(GachaService.RARITY_RANK.get(roll.rarity, -1)))
	check(best_rank >= 2, "Ten-pull guarantees Epic or better", str(best_rank))

	rng.seed = 99
	var pity_state := GachaService.empty_pity()
	pity_state.legendary = int(banner.get("hard_pity", 70)) - 1
	var hard_pity := GachaService.pull(banner, rng, pity_state, 1)
	check(hard_pity.results[0].rarity == "legendary", "Hard pity forces a Legendary")
	check(int(hard_pity.pity.legendary) == 0, "Hard pity counter resets")

	var guaranteed_banner := {
		"rates": { "common": 1.0 },
		"featured": ["lyra_vey"],
		"featured_rate": 0.0,
		"hard_pity": 1000,
		"featured_pity": 1000,
		"ten_pull_epic_guarantee": true,
		"pool": { "common": ["mira_sol"], "epic": ["lyra_vey"] },
	}
	rng.seed = 5
	var floor_pull := GachaService.pull(guaranteed_banner, rng, GachaService.empty_pity(), 10)
	var last_roll: Dictionary = floor_pull.results[floor_pull.results.size() - 1]
	check(last_roll.rarity == "epic" and bool(last_roll.get("guaranteed", false)), "Ten-pull floor replaces the last roll")

	var featured_banner := {
		"rates": { "epic": 1.0 },
		"featured": ["lyra_vey"],
		"featured_rate": 0.0,
		"hard_pity": 1000,
		"featured_pity": 1,
		"pool": { "epic": ["lyra_vey"] },
	}
	var featured_state := GachaService.empty_pity()
	featured_state.featured = 1
	var forced := GachaService.pull(featured_banner, rng, featured_state, 1)
	check(bool(forced.results[0].featured), "Featured pity forces the featured character")
	check(int(forced.pity.featured) == 0, "Featured pity counter resets")

	# A featured unit must not also appear in the off-banner pool: otherwise the
	# displayed 0% rate-up is secretly boosted by ordinary pool selection.
	var no_rate_up_banner := {
		"rates": { "epic": 1.0 },
		"featured": ["lyra_vey"],
		"featured_rate": 0.0,
		"hard_pity": 1000,
		"featured_pity": 1000,
		"pool": { "epic": ["lyra_vey", "coralyn"] },
	}
	rng.seed = 20261116
	var no_rate_up := GachaService.pull(no_rate_up_banner, rng, GachaService.empty_pity(), 30)
	var featured_leaks := 0
	for roll in no_rate_up.results:
		if bool(roll.get("featured", false)) or str(roll.get("character_id", "")) == "lyra_vey":
			featured_leaks += 1
	check(featured_leaks == 0, "Featured character is excluded from off-banner selection at 0% rate-up", str(featured_leaks))

	# The ten-pull Epic floor must also reset featured pity when the guaranteed
	# replacement is the featured character.
	var floor_featured_state := GachaService.empty_pity()
	floor_featured_state.featured = 7
	var floor_featured := GachaService.pull(guaranteed_banner, rng, floor_featured_state, 10)
	check(bool(floor_featured.results[9].get("featured", false)), "Ten-pull floor can return the featured character")
	check(int(floor_featured.pity.featured) == 0, "Featured pity resets after a featured ten-pull floor result")


func _test_ui_regressions() -> void:
	# Preserve both requested featured banners and their independent artwork paths.
	var vesper_banner: Dictionary = ContentDB.get_banner("crimson_covenant")
	var scarlet_banner: Dictionary = ContentDB.get_banner("scarlet_requiem")
	check(ContentDB.banners.size() == 2, "Summon interface displays exactly the two requested featured banners")
	check(not vesper_banner.is_empty() and str(vesper_banner.get("name", "")) == "Hollow Moon Overture" and str((vesper_banner.get("featured", [""]) as Array)[0]) == "nyx", "Hollow Moon Overture features Nyx Vaelora")
	check(not scarlet_banner.is_empty() and str((scarlet_banner.get("featured", [""]) as Array)[0]) == "scarlet_requiem", "Scarlet Requiem remains a separate second featured banner")
	check(ResourceLoader.exists("res://assets/characters/scarlet_requiem/banner_portrait.jpg"), "Scarlet Requiem banner uses the supplied portrait asset")
	check(ResourceLoader.exists("res://assets/ui/backgrounds/summoning_chamber_background.svg"), "Summon screen keeps its dedicated chamber background")

	# Exercise the actual second banner selection and both close paths.
	var gacha_scene := load("res://scenes/ui/gacha_screen.tscn") as PackedScene
	var gacha := gacha_scene.instantiate() as GachaScreen if gacha_scene != null else null
	check(gacha != null, "Summon screen instantiates for banner interaction regression")
	if gacha != null:
		add_child(gacha)
		await get_tree().process_frame
		check(gacha._tabs != null and gacha._tabs.get_child_count() == 3, "Both summon tabs remain visible beside the return control")
		gacha._select_banner("scarlet_requiem")
		await get_tree().process_frame
		check(gacha._selected_banner == "scarlet_requiem" and gacha._featured_id == "scarlet_requiem", "Second summon page selects Scarlet Requiem and its featured character")
		check(gacha.find_child("ReturnToGameButton", true, false) is Button, "Summon page provides its dedicated return button")
		var return_to_game := gacha.find_child("ReturnToGameButton", true, false) as Button
		return_to_game.emit_signal("pressed")
		await get_tree().process_frame
		check(not is_instance_valid(gacha), "Return button closes the summon overlay")

	var escape_gacha := gacha_scene.instantiate() as GachaScreen if gacha_scene != null else null
	if escape_gacha != null:
		add_child(escape_gacha)
		await get_tree().process_frame
		var escape_event := InputEventKey.new()
		escape_event.keycode = KEY_ESCAPE
		escape_event.pressed = true
		escape_gacha._input(escape_event)
		await get_tree().process_frame
		check(not is_instance_valid(escape_gacha), "Escape closes the summon overlay from its second page")

	# The minimap's collapsed restore button must remain inside its compact hitbox.
	var minimap_scene := load("res://scenes/ui/minimap.tscn") as PackedScene
	check(minimap_scene != null, "Minimap scene loads for UI interaction regression")
	if minimap_scene == null:
		return
	var minimap := minimap_scene.instantiate() as Minimap
	add_child(minimap)
	await get_tree().process_frame
	minimap._toggle_collapse()
	var restore_button := minimap.get_node("CollapseButton") as Button
	check(minimap.size == Vector2(60, 28), "Collapsed minimap uses compact dimensions")
	check(restore_button.visible and restore_button.position.x >= 0.0 and restore_button.position.x + restore_button.size.x <= minimap.size.x, "Collapsed minimap keeps its restore button inside the visible control")
	restore_button.emit_signal("pressed")
	check(minimap.size == Vector2(224, 224) and minimap.get_node("MapCanvas").visible, "Minimap restore button reopens the full map")
	minimap.queue_free()
	await get_tree().process_frame


# -------------------------------------------------------------------- combat

func _test_combat() -> void:
	var players: Array = []
	for character_id in ["mira_sol", "kael", "bramble"]:
		var instance := CharacterInstance.create(character_id, "test_" + character_id)
		var unit := CombatFactory.build_from_character(instance, 1.0)
		check(unit != null, "Player combatant builds: " + character_id)
		if unit != null:
			players.append(unit)
	check(players.size() == 3, "Starter party builds 3 combatants")

	var enemies := CombatFactory.enemy_units("glade_mossling_pack")
	check(enemies.size() == 3, "Enemy group builds 3 combatants", str(enemies.size()))

	var engine := CombatEngine.new()
	engine.setup(players, enemies, 2024)
	check(engine.combatants.size() == 6, "Engine holds all combatants")
	var events := engine.start()
	var guard := 0
	while not engine.finished and guard < 500:
		guard += 1
		var actor_index := engine.current_actor_index
		if actor_index < 0:
			break
		var choice := CombatAI.choose(engine, actor_index)
		var skill_id := str(choice.get("skill_id", ""))
		if skill_id.is_empty():
			break
		var turn_events := engine.execute(actor_index, skill_id, choice.get("targets", []))
		events.append_array(turn_events)
		if turn_events.is_empty():
			break
	check(engine.finished, "Battle reaches a conclusion", "guard=%d" % guard)
	check(engine.winner_team == CombatEngine.PLAYER_TEAM, "Starter party wins the opening battle", str(engine.winner_team))
	check(engine.log.size() > 0, "Battle writes a log")

	var has_action := false
	var has_damage := false
	var has_victory := false
	for event in events:
		match str(event.get("type", "")):
			"action":
				has_action = true
			"damage":
				has_damage = true
			"victory":
				has_victory = true
	check(has_action and has_damage and has_victory, "Battle event stream is complete")

	check(near(ElementTable.multiplier("fire", "wind"), ElementTable.ADVANTAGE), "Fire beats Wind")
	check(near(ElementTable.multiplier("wind", "fire"), ElementTable.DISADVANTAGE), "Wind is resisted by Fire")
	check(near(ElementTable.multiplier("light", "dark"), ElementTable.ADVANTAGE), "Light beats Dark")
	check(near(ElementTable.multiplier("neutral", "fire"), 1.0), "Neutral is neutral")

	var scaling_probe := Combatant.new()
	scaling_probe.atk = 100.0
	scaling_probe.defense = 60.0
	scaling_probe.speed = 40.0
	scaling_probe.max_hp = 900.0
	check(near(CombatSkillResolver.effective_scaling_value(scaling_probe, "atk"), 100.0), "Skill attack scaling reads effective attack")
	check(near(CombatSkillResolver.effective_scaling_value(scaling_probe, "def"), 60.0), "Skill defense scaling reads effective defense")
	check(near(CombatSkillResolver.effective_scaling_value(scaling_probe, "hp"), 900.0), "Skill HP scaling reads max HP")
	check(near(CombatSkillResolver.effective_scaling_value(scaling_probe, "spd"), 40.0), "Skill speed scaling reads effective speed")
	scaling_probe.apply_status("atk_up", 2, 0.25)
	scaling_probe.apply_status("def_up", 2, 0.5)
	scaling_probe.apply_status("spd_down", 2, 0.2)
	check(near(CombatSkillResolver.effective_scaling_value(scaling_probe, "atk"), 125.0), "Attack scaling respects attack buffs")
	check(near(CombatSkillResolver.effective_scaling_value(scaling_probe, "def"), 90.0), "Defense scaling respects defense buffs")
	check(near(CombatSkillResolver.effective_scaling_value(scaling_probe, "spd"), 32.0), "Speed scaling respects speed debuffs")

	var boss := CombatFactory.enemy_units("elder_hollow")
	check(boss.size() == 1 and boss[0].is_boss, "Boss combatant is flagged")


func _test_combat_cooldowns() -> void:
	var actor := _unit("cooldown_actor")
	var enemy := _unit("cooldown_enemy")
	actor.speed = 200.0
	enemy.speed = 100.0
	actor.skills = ["gale_shot"]
	enemy.skills = ["moss_slam"]
	var gale_shot: SkillDef = ContentDB.get_skill("gale_shot")
	var previous_cooldown := gale_shot.cooldown_turns
	gale_shot.cooldown_turns = 2
	var engine := CombatEngine.new()
	engine.setup([actor], [enemy], 8181)
	engine.start()
	check(engine.current_actor() == actor, "Cooldown regression begins on the faster player actor")
	var original_target_rule := gale_shot.target
	var energy_before_invalid := actor.energy
	gale_shot.target = "invalid_target_rule"
	check(engine.execute(actor.combat_index, "gale_shot").is_empty(), "Engine rejects a skill with an unsupported target rule")
	check(near(actor.energy, energy_before_invalid) and not actor.is_skill_on_cooldown("gale_shot"), "Rejected target rule consumes neither energy nor cooldown")
	gale_shot.target = original_target_rule
	actor.start_skill_cooldown("gale_shot", 2)
	check(actor.is_skill_on_cooldown("gale_shot") and actor.cooldown_remaining("gale_shot") == 3, "Cooldown starts at its authored duration")
	var energy_before := actor.energy
	check(engine.execute(actor.combat_index, "gale_shot").is_empty(), "Engine rejects a skill while it is cooling down")
	check(near(actor.energy, energy_before), "Rejected cooldown action does not grant energy")
	check(str(CombatAI.choose(engine, actor.combat_index).get("skill_id", "")) == "", "Combat AI excludes skills that are cooling down")
	engine.advance_turn()
	check(engine.current_actor() == enemy, "Enemy receives its turn while the player skill cools down")
	engine.advance_turn()
	check(engine.current_actor() == actor and actor.cooldown_remaining("gale_shot") == 2, "First player turn ticks cooldown to two remaining turns")
	engine.advance_turn()
	engine.advance_turn()
	check(engine.current_actor() == actor and actor.cooldown_remaining("gale_shot") == 1, "Second player turn ticks cooldown to one remaining turn")
	engine.advance_turn()
	var ready_events := engine.advance_turn()
	var cooldown_ready_event := false
	for event in ready_events:
		if str(event.get("type", "")) == "cooldown_ready" and str(event.get("skill_id", "")) == "gale_shot":
			cooldown_ready_event = true
	check(engine.current_actor() == actor and cooldown_ready_event and not actor.is_skill_on_cooldown("gale_shot"), "Cooldown expires on the correct actor turn and emits a ready event")
	var events := engine.execute(actor.combat_index, "gale_shot")
	var action_found := false
	for event in events:
		if str(event.get("type", "")) == "action" and str(event.get("skill_id", "")) == "gale_shot":
			action_found = true
	check(action_found, "Skill becomes executable when its cooldown expires")
	check(actor.cooldown_remaining("gale_shot") == 3, "Successful skill use starts its configured cooldown plus the next-turn offset")
	engine.setup([actor], [enemy], 8182)
	check(not actor.is_skill_on_cooldown("gale_shot"), "Starting a new battle clears previous battle cooldowns")
	gale_shot.cooldown_turns = previous_cooldown


func _test_combat_engine_ownership() -> void:
	var engine: CombatEngine = CombatEngine.new()
	var resolver: CombatSkillResolver = engine.skill_resolver
	var engine_ref: WeakRef = weakref(engine)
	check(resolver.engine == engine, "Combat skill resolver binds to its owning engine")
	engine = null
	check(engine_ref.get_ref() == null, "Combat skill resolver does not retain the engine strongly")
	check(resolver.engine == null, "Combat skill resolver weak owner clears after engine release")
	resolver = null

# --------------------------------------------------------------------- state

func _test_state() -> void:
	check(GameState.persistence_component is GameStatePersistenceComponent and GameState.persistence_component.get_parent() == GameState, "GameState owns its authored persistence component")
	var persistence_snapshot: Dictionary = GameState._to_dict()
	check(persistence_snapshot.has("profile") and persistence_snapshot.has("region_positions") and persistence_snapshot.has("gear_levels"), "GameState delegates complete save serialization to its persistence component")
	check(SaveService.validate_save_data({"profile": {"name": "Legacy"}}).is_empty(), "Save validation accepts minimal legacy save containers")
	check(not SaveService.validate_save_data({"profile": [], "roster": "broken"}).is_empty(), "Save validation rejects incorrectly typed profile and roster")
	check(not SaveService.validate_save_data({"profile": {"name": "Broken"}, "inventory": {"glade_sap": -1}}).is_empty(), "Save validation rejects negative inventory counts")
	GameState.loaded_from_save = true
	GameState.new_game("Test Wanderer")
	check(not GameState.loaded_from_save, "Starting a new game clears the resumed-save flag")
	check(GameState.roster.size() == 3, "New game grants 3 characters", str(GameState.roster.size()))
	check(GameState.party.size() == 3, "New game fills a 3-person party", str(GameState.party.size()))
	check(GameState.currency("gold") == 500, "New game starts with 500 gold", str(GameState.currency("gold")))
	check(GameState.currency("crystals") == 1500, "New game starts with 1500 crystals", str(GameState.currency("crystals")))

	GameState.add_currency("gold", 100)
	check(GameState.currency("gold") == 600, "Currency can be added")
	check(GameState.spend_currency("gold", 50), "Currency can be spent")
	check(GameState.currency("gold") == 550, "Currency spend is exact")
	check(not GameState.spend_currency("gold", 999999), "Overspending is rejected")

	GameState.add_item("glade_sap", 2)
	check(GameState.item_count("glade_sap") == 5, "Items stack", str(GameState.item_count("glade_sap")))
	check(GameState.remove_item("glade_sap", 1), "Items can be removed")
	check(not GameState.remove_item("glade_sap", 999), "Over-removal is rejected")

	var first: Variant = GameState.add_character("coralyn")
	check(bool(first.get("is_new", false)), "New character is reported as new")
	var duplicate: Variant = GameState.add_character("coralyn")
	check(not bool(duplicate.get("is_new", true)), "Duplicate is reported as duplicate")
	check(int(duplicate.get("awakening_gain", -1)) == 0, "First duplicate does not awaken")
	var second_duplicate: Variant = GameState.add_character("coralyn")
	check(int(second_duplicate.get("awakening_gain", -1)) == 1, "Second duplicate grants awakening")
	var coralyn: CharacterInstance = second_duplicate.get("instance", null)
	check(coralyn != null and coralyn.awakening == 1, "Awakening is stored on the instance")
	check(GameState.unique_owned_count() == 4, "Roster tracks unique characters", str(GameState.unique_owned_count()))

	var uids: Array = []
	for instance in GameState.roster:
		uids.append(instance.uid)
	uids.append("not-a-real-uid")
	check(GameState.set_party(uids), "Party accepts a valid selection")
	check(GameState.party.size() == 4, "Party is capped at 4", str(GameState.party.size()))
	check(not GameState.set_party([]), "Empty party is rejected")

	check(GameState.start_quest("glade_whisper", "elder_maelin"), "Quest starts")
	check(GameState.quest_step_index("glade_whisper") == 1, "Giver conversation completes the first talk step")
	GameState.record_kill("mossling", 3)
	check(GameState.quest_step_index("glade_whisper") == 2, "Kill objective advances the quest")
	check(GameState.quest_ready("glade_whisper"), "Quest is ready at the final talk step")
	var crystals_before: Variant = GameState.currency("crystals")
	var bows_before: Variant = GameState.item_count("gladewood_bow")
	check(GameState.complete_quest("glade_whisper"), "Quest can be completed")
	check(GameState.quest_state("glade_whisper") == "complete", "Quest state is complete")
	check(GameState.currency("crystals") == crystals_before + 120, "Quest crystals are granted")
	check(GameState.item_count("gladewood_bow") == bows_before + 1, "Quest equipment is granted")
	check(GameState.currency("gold") == 850, "Quest gold is granted", str(GameState.currency("gold")))

	GameState.save_now()
	var loaded := SaveService.load_save()
	check(int(loaded.get("version", 0)) == SaveService.SAVE_VERSION, "Save is versioned")
	check(str(loaded.get("profile", {}).get("name", "")) == "Test Wanderer", "Save stores the profile")
	check(loaded.get("roster", []).size() == 4, "Save stores the roster", str(loaded.get("roster", []).size()))
	check(loaded.get("party", []).size() == 4, "Save stores the party")
	loaded["profile"]["name"] = "Second Atomic Save"
	check(SaveService.write_save(loaded.duplicate(true)), "Second save safely replaces the previous save")
	var reloaded_second := SaveService.load_save()
	check(str(reloaded_second.get("profile", {}).get("name", "")) == "Second Atomic Save", "Second atomic save is the readable current save")
	check(not FileAccess.file_exists(SaveService.SAVE_PATH + ".tmp") and not FileAccess.file_exists(SaveService.SAVE_PATH + ".previous.tmp"), "Successful save leaves no temporary replacement files")
	var save_abs := ProjectSettings.globalize_path(SaveService.SAVE_PATH)
	var previous_abs := ProjectSettings.globalize_path(SaveService.SAVE_PATH + ".previous.tmp")
	check(DirAccess.rename_absolute(save_abs, previous_abs) == OK, "Simulate interruption after protecting the previous save")
	var recovery_payload: Dictionary = reloaded_second.duplicate(true)
	recovery_payload["profile"]["name"] = "Recovered Replacement"
	check(SaveService.write_save(recovery_payload), "Next save recovers an interrupted replacement before writing")
	var recovered := SaveService.load_save()
	check(str(recovered.get("profile", {}).get("name", "")) == "Recovered Replacement", "Recovered replacement becomes the current readable save")
	check(not FileAccess.file_exists(SaveService.SAVE_PATH + ".previous.tmp"), "Recovered save removes stale backup after successful replacement")
	check(DirAccess.rename_absolute(save_abs, previous_abs) == OK, "Prepare stale backup artifact for reset regression")
	SaveService.delete_save()
	check(not SaveService.has_save() and not FileAccess.file_exists(SaveService.SAVE_PATH + ".tmp") and not FileAccess.file_exists(SaveService.SAVE_PATH + ".previous.tmp"), "Deleting save removes current and interrupted-write artifacts")
	GameState.save_now()
	check(SaveService.has_save(), "Normal save can be written after reset cleanup")
	var corrupt_file := FileAccess.open(SaveService.SAVE_PATH, FileAccess.WRITE)
	corrupt_file.store_string("{\"profile\":\"invalid\"}")
	corrupt_file.close()
	check(SaveService.load_save().is_empty(), "Malformed save is rejected without typed-load crash")
	check(FileAccess.file_exists(SaveService.BACKUP_PATH), "Malformed save is copied to a recovery backup")
	check(not SaveService.has_save(), "Corrupt source is removed only after backup succeeds")
	GameState.save_now()
	if FileAccess.file_exists(SaveService.BACKUP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveService.BACKUP_PATH))


# ------------------------------------------------------------------------ UI

func _test_ui() -> void:
	var gacha_scene := load("res://scenes/ui/gacha_screen.tscn") as PackedScene
	var collection_scene := load("res://scenes/ui/collection_screen.tscn") as PackedScene
	var screens: Array = [
		gacha_scene.instantiate() if gacha_scene != null else null,
		collection_scene.instantiate() if collection_scene != null else null,
		InventoryScreen.new(),
		QuestScreen.new(),
		PauseMenu.new(),
		ShopScreen.new(),
	]
	for screen in screens:
		if screen == null:
			check(false, "UI screen scene resource is available")
			continue
		add_child(screen)
		await get_tree().process_frame
		check(screen.is_inside_tree(), "Screen enters the tree: " + screen.get_class())
		var overlay_panel := screen.get_node_or_null("OverlayShell/Margin/Panel") as PanelContainer
		check(overlay_panel != null and overlay_panel.size_flags_vertical == Control.SIZE_EXPAND_FILL, "Overlay shell panel fills available height: " + screen.name)
		check(screen.content != null and screen.content.get_child_count() > 0, "Screen builds content: " + screen.name)
		if screen is ShopScreen:
			check(screen.find_children("*", "Button", true, false).size() >= 8, "Merchant shop displays all eight stock items")
			var shop_inventory_before: Dictionary = GameState.inventory.duplicate(true)
			var shop_profile_before: Dictionary = GameState.profile.duplicate(true)
			GameState.inventory = {}
			GameState.profile["gold"] = 100
			screen._refresh_stock()
			var moonpetal_buy: Button = null
			for candidate in screen.find_children("*", "Button", true, false):
				if candidate is Button and candidate.text == "Buy  60 G":
					moonpetal_buy = candidate
					break
			check(moonpetal_buy != null and not moonpetal_buy.disabled, "Affordable Moonpetal stock is enabled")
			if moonpetal_buy != null:
				moonpetal_buy.pressed.emit()
				await get_tree().process_frame
			check(GameState.currency("gold") == 40 and GameState.item_count("moonpetal") == 1, "Shop UI purchase updates wallet and inventory")
			check(screen._wallet_label.text == "Gold  40", "Shop wallet display refreshes after purchase")
			var owned_label_found := false
			for label_node in screen.find_children("*", "Label", true, false):
				if label_node is Label and label_node.text == "Owned: 1":
					owned_label_found = true
			check(owned_label_found, "Shop stock ownership count refreshes after purchase")
			GameState.inventory = shop_inventory_before
			GameState.profile = shop_profile_before
			screen._refresh_stock()
		if screen is InventoryScreen:
			var inventory_layout: Control = screen.content.get_child(0)
			var inventory_split := inventory_layout.get_node("Split") as HBoxContainer
			var inventory_left := inventory_split.get_node("Left") as Control
			var inventory_detail := inventory_split.get_node("DetailPanel") as Control
			check(inventory_split.alignment == BoxContainer.ALIGNMENT_CENTER, "Inventory split centers its two authored columns")
			check(inventory_left.size_flags_horizontal == Control.SIZE_FILL, "Inventory item grid keeps a bounded left column")
			check(inventory_detail.size_flags_horizontal == Control.SIZE_FILL, "Inventory detail panel does not expand past the viewport")
			check(inventory_detail.position.x + inventory_detail.size.x <= inventory_split.size.x + 1.0, "Inventory detail panel remains inside the overlay width")
			check(screen.grid_component is InventoryGridComponent and screen.grid_component.get_parent() == screen.content.get_child(0), "Inventory layout owns its grid and detail component")
			check(screen.crafting_component is InventoryCraftingComponent and screen.crafting_component.get_parent() == screen.content.get_child(0), "Inventory layout owns its crafting component")
			check(screen.crafting_component._window is PanelContainer and screen.crafting_component._window.get_parent() == screen.content, "Inventory crafting component instances its authored overlay under screen content")
			check(screen.crafting_component._list is VBoxContainer and screen.crafting_component._window.find_child("CloseButton", true, false) is Button, "Inventory crafting component binds authored recipe list and close button")
			screen.crafting_component.open()
			check(screen.crafting_component._window.visible, "Inventory crafting overlay opens through its component")
			var crafting_close := screen.crafting_component._window.find_child("CloseButton", true, false) as Button
			if crafting_close != null:
				crafting_close.pressed.emit()
			check(not screen.crafting_component._window.visible, "Inventory crafting overlay closes through its authored close button")
			check(screen.grid_component._grid is GridContainer, "Inventory grid component binds the authored item grid")
			var material_filter := screen.content.find_child("MaterialsButton", true, false) as Button
			var all_filter := screen.content.find_child("AllButton", true, false) as Button
			if material_filter != null:
				material_filter.pressed.emit()
			check(screen.grid_component._filter == "material", "Inventory filter button delegates to the grid component")
			if all_filter != null:
				all_filter.pressed.emit()
			check(screen.grid_component._filter == "all", "Inventory All filter restores the full item view")
			screen._controller.notification_requested.emit("Inventory is full.", "warning")
			check(screen._notification.visible and screen._notification.label_node.text == "Inventory is full.", "Inventory controller notifications reach the authored notification panel")
			screen._notification.show_message("", "info")
			check(screen._crafting_window != null and not screen._crafting_window.visible, "Crafting panel starts hidden")
			var crafting_buttons: Array[Node] = screen.find_children("*", "Button", true, false)
			var crafting_button_found := false
			for candidate in crafting_buttons:
				if candidate is Button and candidate.text == "Crafting":
					crafting_button_found = true
					candidate.pressed.emit()
					break
			check(crafting_button_found, "Inventory exposes Crafting action")
			await get_tree().process_frame
			check(screen._crafting_window.visible, "Crafting action opens recipe panel")
			check(screen._crafting_list.get_child_count() == 3, "Crafting panel lists all three recipes")
			var inventory_before_crafting: Dictionary = GameState.inventory.duplicate(true)
			var profile_before_crafting: Dictionary = GameState.profile.duplicate(true)
			GameState.inventory = {"glade_sap": 2, "moonpetal": 1}
			GameState.profile["gold"] = 500
			screen._refresh_crafting_window()
			var wayfarer_button: Button = null
			var sunfire_button: Button = null
			for recipe_card in screen._crafting_list.get_children():
				var recipe_labels: Array[Node] = recipe_card.find_children("*", "Label", true, false)
				var recipe_name := ""
				for recipe_label in recipe_labels:
					if recipe_label is Label and recipe_label.text in ["Wayfarer Charm", "Sunfire Blade"]:
						recipe_name = recipe_label.text
						break
				var recipe_buttons: Array[Node] = recipe_card.find_children("*", "Button", true, false)
				for recipe_button in recipe_buttons:
					if recipe_button is Button and recipe_button.text == "Craft":
						if recipe_name == "Wayfarer Charm":
							wayfarer_button = recipe_button
						elif recipe_name == "Sunfire Blade":
							sunfire_button = recipe_button
			check(wayfarer_button != null and not wayfarer_button.disabled, "Affordable recipe is enabled in crafting UI")
			check(sunfire_button != null and sunfire_button.disabled, "Unaffordable recipe is disabled in crafting UI")
			if wayfarer_button != null and not wayfarer_button.disabled:
				wayfarer_button.pressed.emit()
				await get_tree().process_frame
			check(GameState.item_count("wayfarer_charm") == 1, "Crafting UI grants selected recipe output")
			check(GameState.item_count("glade_sap") == 0 and GameState.item_count("moonpetal") == 0 and GameState.currency("gold") == 350, "Crafting UI consumes exact material and gold costs")
			GameState.inventory = inventory_before_crafting
			GameState.profile = profile_before_crafting
		screen.queue_free()
		await get_tree().process_frame
	var title_scene := load("res://scenes/ui/title_screen.tscn") as PackedScene
	check(title_scene != null, "Authored title screen scene loads")
	var title := title_scene.instantiate() as TitleScreen if title_scene != null else null
	if title == null:
		return
	add_child(title)
	await get_tree().process_frame
	check(title.get_child_count() > 0, "Title screen builds")
	var title_bounds := Rect2(Vector2.ZERO, title.size)
	var title_controls := ["ContinueButton", "NewJourneyButton", "LoadGameButton", "SettingsButton", "ExtrasButton", "QuitGameButton"]
	var title_controls_fit := true
	for control_name in title_controls:
		var title_button := title.get_node_or_null(control_name) as Control
		if title_button == null or not title_bounds.encloses(title_button.get_rect()):
			title_controls_fit = false
	check(title_controls_fit, "All six title-screen controls fit inside the active viewport")
	var title_backdrop := title.get_node_or_null("TitleArtwork") as Control
	check(title_backdrop != null and title_bounds.encloses(title_backdrop.get_rect()), "Title-screen artwork stays inside the active viewport")
	title.queue_free()
	await get_tree().process_frame

	var combat_scene := load("res://scenes/ui/combat_screen.tscn") as PackedScene
	var combat := combat_scene.instantiate() as CombatScreen if combat_scene != null else null
	if combat != null:
		combat.group_id = "glade_mossling_pack"
		add_child(combat)
	await get_tree().process_frame
	await get_tree().process_frame
	check(combat != null and combat.engine != null, "Combat screen starts an engine")
	check(combat != null and combat._turn_order_component is CombatTurnOrderComponent and combat._turn_order_component.get_parent() == combat, "CombatScreen binds its turn-order component")
	check(combat != null and combat._result_component is CombatResultComponent and combat._result_component.get_parent() == combat, "CombatScreen binds its result component")
	check(combat != null and combat._event_presentation_component is CombatEventPresentationComponent and combat._event_presentation_component.get_parent() == combat, "CombatScreen binds its event-presentation component")
	check(combat != null and combat._hud_component is CombatHudComponent and combat._hud_component.get_parent() == combat, "CombatScreen binds its HUD/roster component")
	check(combat != null and combat._layout_component is CombatLayoutComponent and combat._layout_component.get_parent() == combat, "CombatScreen binds its authored layout component")
	check(combat != null and combat._session_component is CombatSessionComponent and combat._session_component.get_parent() == combat, "CombatScreen binds its authored battle-session component")
	check(combat != null and combat._input_component is CombatInputComponent and combat._input_component.get_parent() == combat, "CombatScreen binds its authored input component")
	check(combat != null and combat._battlefield != null and combat._battlefield._layout_component is BattlefieldLayoutComponent and combat._battlefield._layout_component.get_parent() == combat._battlefield, "Battlefield binds its authored layout/actor component")
	check(combat != null and combat._battlefield != null and combat._battlefield._effects_component is BattlefieldEffectsComponent and combat._battlefield._effects_component.get_parent() == combat._battlefield, "Battlefield binds its authored combat-effects component")
	check(combat != null and combat._battlefield != null and combat._battlefield._kael_attack_component is KaelAttackPresentationComponent and combat._battlefield._kael_attack_component.get_parent() == combat._battlefield, "Battlefield binds its dedicated Kael attack presentation component")
	check(combat != null and combat._battlefield != null and combat._battlefield._effects_component.kael_attack_component == combat._battlefield._kael_attack_component, "Battlefield effects facade delegates Kael choreography to its dedicated component")
	check(combat != null and combat._battlefield != null and combat._battlefield._matron_attack_component is MatronAttackPresentationComponent and combat._battlefield._matron_attack_component.get_parent() == combat._battlefield, "Battlefield binds its dedicated Fallen Matron attack presentation component")
	check(combat != null and combat._battlefield != null and combat._battlefield._effects_component.matron_attack_component == combat._battlefield._matron_attack_component, "Battlefield effects facade delegates Fallen Matron choreography to its dedicated component")
	check(combat != null and combat._battlefield != null and combat._battlefield._generic_attack_component is GenericAttackPresentationComponent and combat._battlefield._generic_attack_component.get_parent() == combat._battlefield, "Battlefield binds its dedicated generic attack presentation component")
	check(combat != null and combat._battlefield != null and combat._battlefield._effects_component.generic_attack_component == combat._battlefield._generic_attack_component, "Battlefield effects facade delegates ordinary attacks to its dedicated component")
	check(combat != null and combat._battlefield != null and combat._battlefield._impact_component is BattlefieldImpactEffectsComponent and combat._battlefield._impact_component.get_parent() == combat._battlefield, "Battlefield binds its dedicated impact-effects component")
	check(combat != null and combat._battlefield != null and combat._battlefield._effects_component.impact_component == combat._battlefield._impact_component, "Battlefield effects facade delegates transient impact visuals to the authored impact component")
	var battlefield_actor_scene := load("res://scenes/ui/battlefield_actor.tscn") as PackedScene
	var battlefield_actor := battlefield_actor_scene.instantiate() as BattlefieldActor if battlefield_actor_scene != null else null
	check(battlefield_actor != null and battlefield_actor.get_node_or_null("GroundFX") is BattlefieldActorGroundFX, "BattlefieldActor owns its GroundFX as an authored child scene")
	check(battlefield_actor != null and battlefield_actor.get_node_or_null("MatronPresentation") is FallenMatronPresentationComponent, "BattlefieldActor owns its bespoke Fallen Matron presentation as an authored child scene")
	if battlefield_actor != null:
		battlefield_actor.free()
	if combat != null and combat.engine != null:
		check(combat.engine.combatants.size() >= 4, "Combat screen builds both teams", str(combat.engine.combatants.size()))
	if combat != null and combat._battlefield != null:
		var generic_attacker: BattlefieldActor = null
		var generic_target: BattlefieldActor = null
		for actor_entry in combat._battlefield.actors():
			var stage_actor := actor_entry as BattlefieldActor
			if stage_actor.is_player and generic_target == null:
				generic_target = stage_actor
			elif not stage_actor.is_player and generic_attacker == null:
				generic_attacker = stage_actor
		check(generic_attacker != null and generic_target != null, "Combat stage exposes a valid enemy-to-party choreography pair")
		if generic_attacker != null and generic_target != null:
			var attack_origin := generic_attacker.position
			var target_home := generic_target.home_position
			combat._battlefield._generic_attack_component.play_attack(generic_attacker, generic_target, "neutral")
			await get_tree().create_timer(0.38).timeout
			check(generic_attacker.position.distance_to(attack_origin) > 2.0, "Generic combat choreography visibly lunges the attacker toward its target")
			await get_tree().create_timer(0.82).timeout
			check(generic_attacker.position.distance_to(attack_origin) < 1.5, "Generic combat choreography returns the attacker to its home position")
			check(generic_target.position.distance_to(target_home) < 1.5, "Generic combat choreography restores the target after its impact reaction")
	if combat != null:
		combat.queue_free()
	await get_tree().process_frame

	var game_scene: PackedScene = load("res://scenes/game.tscn")
	check(game_scene != null, "Game scene loads")
	if game_scene != null:
		var game := game_scene.instantiate()
		add_child(game)
		await get_tree().process_frame
		await get_tree().process_frame
		check(game.world != null, "Game screen creates a world")
		check(game.hud != null, "Game screen creates a HUD")
		check(game.hud._currency_component is HUDCurrencyComponent and game.hud._currency_component.get_parent() == game.hud, "HUD binds its currency component")
		check(game.hud._party_component is HUDPartyComponent and game.hud._party_component.get_parent() == game.hud, "HUD binds its party component")
		check(game.hud._quest_component is HUDQuestComponent and game.hud._quest_component.get_parent() == game.hud, "HUD binds its quest component")
		check(game.hud._toast_component is HUDToastComponent and game.hud._toast_component.get_parent() == game.hud, "HUD binds its toast component")
		check(game.input_router is GameInputRouterComponent and game.input_router.get_parent() == game, "GameScreen binds its authored input router")
		check(game.runtime_component is GameRuntimeComponent and game.runtime_component.get_parent() == game, "GameScreen delegates HUD refresh and suspended-world recovery to its runtime component")
		check(game.world.player != null, "World creates a player")
		check(game.world.current_area_name() != "", "World reports an area", game.world.current_area_name())
		game._on_shop_requested()
		await get_tree().process_frame
		check(game.active_overlay is ShopScreen, "Dialogue shop request opens the merchant overlay")
		check(game.world.process_mode == Node.PROCESS_MODE_DISABLED, "Merchant overlay suspends world simulation")
		if game.active_overlay != null:
			game.active_overlay.close_screen()
		await get_tree().process_frame
		check(game.active_overlay == null and game.world.process_mode == Node.PROCESS_MODE_INHERIT, "Closing merchant overlay restores world simulation")
		# Exercise a complete real dialogue branch through GameScreen and the
		# authored DialogueBox controls, without changing quest or inventory data.
		game._on_dialogue_requested("edgar_market_keeper")
		check(game.dialogue.visible and game.dialogue._node_id == "greet", "NPC dialogue request opens the authored greeting node")
		check(game.world.process_mode == Node.PROCESS_MODE_DISABLED, "Opening NPC dialogue suspends world simulation")
		game.dialogue._finish_typing()
		var market_choice: Button = null
		for choice_node in game.dialogue._choices_box.get_children():
			if choice_node is Button and (choice_node as Button).text == "You run the market?":
				market_choice = choice_node as Button
				break
		check(market_choice != null, "Dialogue presents the authored market choice after typing finishes")
		if market_choice != null:
			market_choice.pressed.emit()
		check(game.dialogue.visible and game.dialogue._node_id == "market", "Choosing market advances to the correct dialogue node")
		game.dialogue._finish_typing()
		var leave_choice: Button = null
		for choice_node in game.dialogue._choices_box.get_children():
			if choice_node is Button and (choice_node as Button).text == "I see. Thank you.":
				leave_choice = choice_node as Button
				break
		check(leave_choice != null, "Dialogue market node presents its leave choice")
		if leave_choice != null:
			leave_choice.pressed.emit()
		await get_tree().process_frame
		check(not game.dialogue.visible and game.world.process_mode == Node.PROCESS_MODE_INHERIT, "Closing NPC dialogue restores world simulation")
		var pause_event := InputEventKey.new()
		pause_event.keycode = KEY_ESCAPE
		pause_event.physical_keycode = KEY_ESCAPE
		pause_event.pressed = true
		game.input_router.handle_unhandled_input(pause_event)
		await get_tree().process_frame
		check(game.active_overlay is PauseMenu, "Escape input routes through the authored input router to the pause menu")
		check(game.world.process_mode == Node.PROCESS_MODE_DISABLED, "Opening the pause menu suspends world simulation")
		if game.active_overlay != null:
			game.active_overlay.close_screen()
		await get_tree().process_frame
		var controller_pause_event := InputEventJoypadButton.new()
		controller_pause_event.button_index = JOY_BUTTON_START
		controller_pause_event.pressed = true
		game.input_router.handle_unhandled_input(controller_pause_event)
		await get_tree().process_frame
		check(game.active_overlay is PauseMenu, "Controller Start input routes to the pause menu")
		check(game.world.process_mode == Node.PROCESS_MODE_DISABLED, "Controller pause suspends world simulation")
		if game.active_overlay != null:
			game.active_overlay.close_screen()
		await get_tree().process_frame
		game.input_router.handle_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
		await get_tree().process_frame
		check(game.active_overlay is PauseMenu, "Mobile back notification routes to the pause menu")
		check(game.world.process_mode == Node.PROCESS_MODE_DISABLED, "Mobile back pause suspends world simulation")
		if game.active_overlay != null:
			game.active_overlay.close_screen()
		await get_tree().process_frame
		game.queue_free()
		await get_tree().process_frame


# --------------------------------------------- Phase 2: passive multiplier hooks

## Exercises whisperstep, rooted, deep_roots, hold_the_line, hollow_crown,
## nothing_to_lose and patient_weaver through the real CombatEngine helpers,
## plus the supported-id registry. Combatants are built directly (no save data).
func _test_passive_multipliers() -> void:
	# Every shipped character must declare a supported passive id.
	for character_id in ContentDB.characters.keys():
		var def: CharacterDef = ContentDB.get_character(str(character_id))
		check(
			def != null and PassiveEffects.SUPPORTED_IDS.has(def.passive_id),
			"Character passive id is supported: " + str(character_id),
			"" if def == null else def.passive_id
		)
	check(PassiveEffects.SUPPORTED_IDS.size() == 12, "Twelve passive ids are supported", str(PassiveEffects.SUPPORTED_IDS.size()))

	# Whisperstep: whole-team speed bonus, also feeding turn order.
	var ws := _unit("ws", "whisperstep")
	var ws_ally := _unit("ws_ally", "")
	var ws_enemy := _unit("ws_enemy", "")
	ws_enemy.speed = 105.0
	var e_ws := CombatEngine.new()
	e_ws.setup([ws, ws_ally], [ws_enemy], 7)
	check(near(e_ws.unit_speed(ws_ally), 100.0 * PassiveEffects.WHISPERSTEP_SPEED), "Whisperstep boosts an ally's speed", str(e_ws.unit_speed(ws_ally)))
	check(CombatPassiveResolver.has_passive(ws, "whisperstep") and CombatPassiveResolver.team_has_passive([ws, ws_ally], "whisperstep"), "CombatPassiveResolver exposes pure passive and team queries")
	check(near(e_ws.unit_speed(ws), 100.0 * PassiveEffects.WHISPERSTEP_SPEED), "Whisperstep boosts the owner's speed")
	check(near(e_ws.unit_speed(ws_enemy), 105.0), "Whisperstep does not boost the enemy team", str(e_ws.unit_speed(ws_enemy)))
	check(e_ws.order[0] == ws.combat_index, "Whisperstep speed feeds turn order", str(e_ws.order))

	# Control engine without whisperstep: raw speeds and order are unchanged.
	var c0 := _unit("c0", "")
	var c0_enemy := _unit("c0_enemy", "")
	c0_enemy.speed = 105.0
	var e_ctrl := CombatEngine.new()
	e_ctrl.setup([c0], [c0_enemy], 7)
	check(near(e_ctrl.unit_speed(c0), 100.0), "No whisperstep: speed is unmodified")
	check(e_ctrl.order[0] == c0_enemy.combat_index, "Control: faster enemy acts first", str(e_ctrl.order))

	# Rooted: incoming reduction only below the HP threshold.
	var rooted := _unit("rooted", "rooted")
	var rooted_ally := _unit("rooted_ally", "")
	var r_enemy := _unit("r_enemy", "")
	var e_root := CombatEngine.new()
	e_root.setup([rooted, rooted_ally], [r_enemy], 7)
	check(near(e_root.incoming_multiplier(rooted), 1.0), "Rooted inactive at full HP", str(e_root.incoming_multiplier(rooted)))
	rooted.hp = 300.0
	check(near(e_root.incoming_multiplier(rooted), PassiveEffects.ROOTED_REDUCTION), "Rooted reduces incoming damage below half HP", str(e_root.incoming_multiplier(rooted)))

	# Deep Roots: defense multiplier on the owner only.
	var deep := _unit("deep", "deep_roots")
	var plain := _unit("plain", "")
	var d_enemy := _unit("d_enemy", "")
	var e_deep := CombatEngine.new()
	e_deep.setup([deep, plain], [d_enemy], 7)
	check(near(e_deep.unit_defense(deep), 100.0 * PassiveEffects.DEEP_ROOTS_DEFENSE), "Deep Roots raises the owner's defense", str(e_deep.unit_defense(deep)))
	check(near(e_deep.unit_defense(plain), 100.0), "Deep Roots does not affect allies", str(e_deep.unit_defense(plain)))

	# Hold the Line: reduction comes from a DIFFERENT living ally.
	var target := _unit("target", "")
	var holder := _unit("holder", "hold_the_line")
	var h_enemy := _unit("h_enemy", "")
	var e_hold := CombatEngine.new()
	e_hold.setup([target, holder], [h_enemy], 7)
	check(near(e_hold.incoming_multiplier(target), PassiveEffects.HOLD_THE_LINE_REDUCTION), "Hold the Line reduces an ally's incoming damage", str(e_hold.incoming_multiplier(target)))
	check(near(e_hold.incoming_multiplier(holder), 1.0), "Hold the Line does not reduce the holder's own damage", str(e_hold.incoming_multiplier(holder)))
	holder.hp = 0.0
	check(near(e_hold.incoming_multiplier(target), 1.0), "Hold the Line stops when the holder is dead", str(e_hold.incoming_multiplier(target)))

	# Hollow Crown: dark skills only, vs a debuffed target.
	var hc := _unit("hc", "hollow_crown")
	var clean_target := _unit("clean_target", "")
	var debuffed := _unit("debuffed", "")
	debuffed.apply_status("poison", 3, 0.05)
	var e_hc := CombatEngine.new()
	check(near(e_hc.outgoing_multiplier(hc, "dark", debuffed), PassiveEffects.HOLLOW_CROWN_DAMAGE), "Hollow Crown boosts dark damage vs a debuffed target", str(e_hc.outgoing_multiplier(hc, "dark", debuffed)))
	check(near(e_hc.outgoing_multiplier(hc, "dark", clean_target), 1.0), "Hollow Crown does nothing vs a clean target")
	check(near(e_hc.outgoing_multiplier(hc, "fire", debuffed), 1.0), "Hollow Crown only applies to dark skills")

	# Nothing to Lose: outgoing bonus below the HP threshold.
	var ntl := _unit("ntl", "nothing_to_lose")
	var ntl_target := _unit("ntl_target", "")
	var e_ntl := CombatEngine.new()
	check(near(e_ntl.outgoing_multiplier(ntl, "fire", ntl_target), 1.0), "Nothing to Lose inactive at full HP")
	ntl.hp = 200.0
	check(near(e_ntl.outgoing_multiplier(ntl, "fire", ntl_target), PassiveEffects.NOTHING_TO_LOSE_DAMAGE), "Nothing to Lose boosts damage below 40% HP", str(e_ntl.outgoing_multiplier(ntl, "fire", ntl_target)))

	# Patient Weaver: bonus vs a stunned target.
	var pw := _unit("pw", "patient_weaver")
	var stunned := _unit("stunned", "")
	stunned.apply_status("stun", 2, 1.0)
	var awake := _unit("awake", "")
	var e_pw := CombatEngine.new()
	check(near(e_pw.outgoing_multiplier(pw, "dark", stunned), PassiveEffects.PATIENT_WEAVER_DAMAGE), "Patient Weaver boosts damage vs a stunned target", str(e_pw.outgoing_multiplier(pw, "dark", stunned)))
	check(near(e_pw.outgoing_multiplier(pw, "dark", awake), 1.0), "Patient Weaver does nothing vs a non-stunned target")


# --------------------------------------------- Phase 2: passives via full turns

## Drives small_miracles, dawnkeeper, tidecall, ashen_wake and sanguine_waltz
## through real CombatEngine.setup()/execute() turns and inspects the event
## stream and resulting unit state.
func _test_passive_battle_hooks() -> void:
	# Small Miracles: one-time battle-start energy for the whole team.
	var sm := _unit("sm", "small_miracles")
	var sm_ally := _unit("sm_ally", "")
	var sm_enemy := _unit("sm_enemy", "")
	var e_sm := CombatEngine.new()
	e_sm.setup([sm, sm_ally], [sm_enemy], 11)
	check(near(sm.energy, PassiveEffects.SMALL_MIRACLES_ENERGY), "Small Miracles grants the owner start-of-battle energy", str(sm.energy))
	check(near(sm_ally.energy, PassiveEffects.SMALL_MIRACLES_ENERGY), "Small Miracles grants the whole team start-of-battle energy", str(sm_ally.energy))
	check(near(sm_enemy.energy, 0.0), "Small Miracles does not grant energy to the enemy team", str(sm_enemy.energy))
	e_sm.start()
	check(near(sm.energy, PassiveEffects.SMALL_MIRACLES_ENERGY), "Small Miracles is not re-applied by start()", str(sm.energy))

	# Dawnkeeper: a one-time 20-energy refund on the first heal only.
	var mend_gain := ContentDB.get_skill("dawn_mend").energy_gain
	var dk := _unit("dk", "dawnkeeper")
	dk.hp = 400.0
	var dk_enemy := _unit("dk_enemy", "")
	var e_dk := CombatEngine.new()
	e_dk.setup([dk], [dk_enemy], 12345)
	e_dk.current_actor_index = dk.combat_index
	var ev1 := e_dk.execute(dk.combat_index, "dawn_mend", [dk.combat_index])
	check(near(_passive_event_amount(ev1, "dawnkeeper"), PassiveEffects.DAWNKEEPER_ENERGY), "Dawnkeeper emits a 20-energy refund event on the first heal")
	check(near(dk.energy, mend_gain + PassiveEffects.DAWNKEEPER_ENERGY), "Dawnkeeper refunds energy on the first heal", str(dk.energy))
	e_dk.current_actor_index = dk.combat_index
	var ev2 := e_dk.execute(dk.combat_index, "dawn_mend", [dk.combat_index])
	check(_passive_event_amount(ev2, "dawnkeeper") < 0.0, "Dawnkeeper does not refund on the second heal")
	check(near(dk.energy, mend_gain * 2.0 + PassiveEffects.DAWNKEEPER_ENERGY), "Second heal grants only the skill's energy_gain", str(dk.energy))

	# Tidecall: healing grants an 8% max-HP shield.
	var tc := _unit("tc", "tidecall")
	tc.hp = 400.0
	var tc_enemy := _unit("tc_enemy", "")
	var e_tc := CombatEngine.new()
	e_tc.setup([tc], [tc_enemy], 12345)
	e_tc.current_actor_index = tc.combat_index
	var tc_events := e_tc.execute(tc.combat_index, "dawn_mend", [tc.combat_index])
	check(near(tc.shield, tc.max_hp * PassiveEffects.TIDECALL_SHIELD), "Tidecall grants an 8% max-HP shield on heal", str(tc.shield))
	check(near(_shield_event_amount(tc_events, "tidecall"), tc.max_hp * PassiveEffects.TIDECALL_SHIELD, 1.0), "Tidecall emits a shield event with the right amount")
	var plain_healer := _unit("plain_healer", "")
	plain_healer.hp = 400.0
	var ph_enemy := _unit("ph_enemy", "")
	var e_plain := CombatEngine.new()
	e_plain.setup([plain_healer], [ph_enemy], 12345)
	e_plain.current_actor_index = plain_healer.combat_index
	e_plain.execute(plain_healer.combat_index, "dawn_mend", [plain_healer.combat_index])
	check(near(plain_healer.shield, 0.0), "A healer without Tidecall grants no shield", str(plain_healer.shield))

	# Ashen Wake: critical hits apply a 2-turn burn.
	var aw := _unit("aw", "ashen_wake")
	aw.crit_chance = 1.0
	var aw_target := _unit("aw_target", "")
	var e_aw := CombatEngine.new()
	e_aw.setup([aw], [aw_target], 12345)
	e_aw.current_actor_index = aw.combat_index
	var aw_events := e_aw.execute(aw.combat_index, "spark", [aw_target.combat_index])
	check(aw_target.has_status("burn"), "Ashen Wake applies burn on a critical hit")
	var burn_turns := -1
	for status in aw_target.statuses:
		if str(status.get("id", "")) == "burn":
			burn_turns = int(status.get("turns", 0))
	check(burn_turns == PassiveEffects.ASHEN_WAKE_BURN_TURNS, "Ashen Wake burn lasts two turns", str(burn_turns))
	check(_has_status_event(aw_events, "burn", "ashen_wake"), "Ashen Wake emits a burn status event")
	# Control: no critical hit -> no burn.
	var aw2 := _unit("aw2", "ashen_wake")
	aw2.crit_chance = 0.0
	var aw2_target := _unit("aw2_target", "")
	var e_aw2 := CombatEngine.new()
	e_aw2.setup([aw2], [aw2_target], 12345)
	e_aw2.current_actor_index = aw2.combat_index
	e_aw2.execute(aw2.combat_index, "spark", [aw2_target.combat_index])
	check(not aw2_target.has_status("burn"), "Ashen Wake does not apply burn without a critical hit")

	# Sanguine Waltz: heal for 20% of damage dealt.
	var sw := _unit("sw", "sanguine_waltz")
	sw.hp = 100.0
	var sw_target := _unit("sw_target", "")
	var e_sw := CombatEngine.new()
	e_sw.setup([sw], [sw_target], 12345)
	e_sw.current_actor_index = sw.combat_index
	var sw_events := e_sw.execute(sw.combat_index, "spark", [sw_target.combat_index])
	var dealt := -1.0
	var lifesteal_heal := -1.0
	for ev in sw_events:
		if str(ev.get("type", "")) == "damage":
			dealt = float(ev.get("amount", 0))
		elif str(ev.get("type", "")) == "heal" and str(ev.get("status", "")) == "lifesteal":
			lifesteal_heal = float(ev.get("amount", 0))
	check(dealt > 0.0, "Sanguine Waltz test lands a damage event", str(dealt))
	check(lifesteal_heal > 0.0, "Sanguine Waltz emits a lifesteal heal event", str(lifesteal_heal))
	check(near(lifesteal_heal, dealt * PassiveEffects.SANGUINE_WALTZ_LIFESTEAL, 1.5), "Sanguine Waltz heals 20% of damage dealt", "heal=%f dealt=%f" % [lifesteal_heal, dealt])
	check(sw.hp > 100.0, "Sanguine Waltz raises the attacker's HP", str(sw.hp))


# --------------------------------------------- Phase 2: equipment & resonance

## Verifies additive equipment stats, weapon-first equipment_element derivation
## from CombatFactory, and the resonance/attunement multipliers in the engine.
func _test_equipment_bonuses() -> void:
	# A bare and an equipped combatant built from the same character/level.
	var bare_inst := CharacterInstance.create("mira_sol", "eq_bare")
	var bare := CombatFactory.build_from_character(bare_inst, 1.0)
	var eq_inst := CharacterInstance.create("mira_sol", "eq_full")
	eq_inst.equip("gladewood_bow", "weapon")   # wind weapon: +24 atk, +4 spd
	eq_inst.equip("mossweave_vest", "armor")    # armor: +120 hp, +16 def
	var eq := CombatFactory.build_from_character(eq_inst, 1.0)
	check(bare != null and eq != null, "CombatFactory builds bare and equipped combatants")
	check(near(eq.atk - bare.atk, 24.0), "Equipment adds weapon attack", "%f" % (eq.atk - bare.atk))
	check(near(eq.defense - bare.defense, 16.0), "Equipment adds armor defense", "%f" % (eq.defense - bare.defense))
	check(near(eq.speed - bare.speed, 4.0), "Equipment adds weapon speed", "%f" % (eq.speed - bare.speed))
	check(near(eq.max_hp - bare.max_hp, 120.0), "Equipment adds armor HP", "%f" % (eq.max_hp - bare.max_hp))
	check(eq.equipment_element == "wind", "equipment_element comes from the elemental weapon", eq.equipment_element)
	check(bare.equipment_element == "", "no equipment means no resonance element", bare.equipment_element)

	# Weapon-first ordering: inject a synthetic elemental ARMOR, confirm the
	# weapon's element wins, then immediately restore ContentDB.items.
	var injected := "test_tide_mail"
	ContentDB.items[injected] = {
		"name": "Test Tide Mail", "category": "equipment", "slot": "armor",
		"element": "water", "stats": { "def": 5 }
	}
	var order_inst := CharacterInstance.create("mira_sol", "eq_order")
	order_inst.equip("gladewood_bow", "weapon")   # wind, weapon (checked first)
	order_inst.equip(injected, "armor")           # water, armor
	var order_unit := CombatFactory.build_from_character(order_inst, 1.0)
	check(order_unit.equipment_element == "wind", "weapon element wins over an elemental armor (weapon-first)", order_unit.equipment_element)
	var armor_only := CharacterInstance.create("mira_sol", "eq_armor")
	armor_only.equip(injected, "armor")
	var armor_unit := CombatFactory.build_from_character(armor_only, 1.0)
	check(armor_unit.equipment_element == "water", "a lone elemental armor sets the resonance element", armor_unit.equipment_element)
	ContentDB.items.erase(injected)

	# Resonance (+8% matching skill) and attunement (+4% matching wielder element).
	var foe := _unit("res_foe", "")
	var e_res := CombatEngine.new()
	check(near(CombatEngine.EQUIPMENT_RESONANCE, 1.08), "EQUIPMENT_RESONANCE is 1.08")
	check(near(CombatEngine.EQUIPMENT_ATTUNEMENT, 1.04), "EQUIPMENT_ATTUNEMENT is 1.04")
	var both := _unit("res_both", "", "fire")
	both.equipment_element = "fire"
	check(near(e_res.outgoing_multiplier(both, "fire", foe), CombatEngine.EQUIPMENT_RESONANCE * CombatEngine.EQUIPMENT_ATTUNEMENT), "matching skill + matching wielder => resonance x attunement", str(e_res.outgoing_multiplier(both, "fire", foe)))
	var res_only := _unit("res_only", "", "water")
	res_only.equipment_element = "fire"
	check(near(e_res.outgoing_multiplier(res_only, "fire", foe), CombatEngine.EQUIPMENT_RESONANCE), "matching skill only => resonance", str(e_res.outgoing_multiplier(res_only, "fire", foe)))
	var att_only := _unit("res_att", "", "water")
	att_only.equipment_element = "water"
	check(near(e_res.outgoing_multiplier(att_only, "fire", foe), CombatEngine.EQUIPMENT_ATTUNEMENT), "matching wielder only => attunement", str(e_res.outgoing_multiplier(att_only, "fire", foe)))
	var neither := _unit("res_none", "", "light")
	neither.equipment_element = "water"
	check(near(e_res.outgoing_multiplier(neither, "fire", foe), 1.0), "unrelated equipment element => no bonus", str(e_res.outgoing_multiplier(neither, "fire", foe)))
	var neutral := _unit("res_neutral", "", "fire")
	check(near(e_res.outgoing_multiplier(neutral, "fire", foe), 1.0), "no equipment element => neutral 1.0", str(e_res.outgoing_multiplier(neutral, "fire", foe)))


func _test_gear_enhancement() -> void:
	if GameState.roster.is_empty():
		check(false, "gear enhancement test has a roster character")
		return
	var instance: CharacterInstance = GameState.roster[0]
	var uid := instance.uid
	var previous_item := instance.equipped_item("weapon")
	var previous_level: Variant = GameState.gear_level(uid, "weapon")
	var old_gold: Variant = GameState.currency("gold")
	var old_sap: Variant = GameState.item_count("glade_sap")
	var old_weapon_count: Variant = GameState.item_count("gladewood_bow")
	var old_gear_levels: Variant = GameState.gear_levels.duplicate(true)
	instance.equip("gladewood_bow", "weapon")
	GameState.gear_levels[uid + "|weapon"] = 0
	GameState.profile["gold"] = 10000
	GameState.inventory["glade_sap"] = 5
	var base_unit := CombatFactory.build_from_character(instance, 1.0)
	var info: Variant = GameState.gear_upgrade_info(uid, "weapon")
	check(bool(info.get("ok", false)), "equipped weapon exposes a valid enhancement offer", str(info))
	check(GameState.enhance_gear(uid, "weapon"), "weapon enhancement consumes its stated resources")
	var enhanced_unit := CombatFactory.build_from_character(instance, 1.0)
	check(GameState.gear_level(uid, "weapon") == 1, "weapon enhancement level persists at +1")
	check(near(enhanced_unit.atk - base_unit.atk, 24.0 * 0.08, 0.05), "+1 enhancement adds 8% of weapon stat bonuses", str(enhanced_unit.atk - base_unit.atk))
	var serialized: Dictionary = GameState._to_dict()
	check(int(serialized.get("gear_levels", {}).get(uid + "|weapon", 0)) == 1, "gear enhancement survives save serialization")
	check(GameState.item_count("glade_sap") == 4 and GameState.currency("gold") == 9820, "enhancement charges exact gold and sap costs")
	# Restore the live test fixture; the runner also restores the full save snapshot.
	if not previous_item.is_empty():
		instance.equip(previous_item, "weapon")
	else:
		instance.unequip("weapon")
	GameState.gear_levels = old_gear_levels
	GameState.profile["gold"] = old_gold
	if old_sap > 0:
		GameState.inventory["glade_sap"] = old_sap
	else:
		GameState.inventory.erase("glade_sap")
	if old_weapon_count > 0:
		GameState.inventory["gladewood_bow"] = old_weapon_count
	else:
		GameState.inventory.erase("gladewood_bow")
	if previous_level > 0:
		GameState.gear_levels[uid + "|weapon"] = previous_level


# --------------------------------------------- Phase 2: invalid JSON parse path

## Feeds malformed JSON text through ContentValidator.validate_text() and
## confirms the parse path rejects it, while well-formed text still parses.
func _test_invalid_json() -> void:
	var broken := "{ \"name\": \"x\", \"rates\": [1, 2 "
	var errs := ContentValidator.validate_text("banners.json", broken, {})
	check(_has_error(errs, "invalid JSON"), "malformed JSON text is rejected by the parse path")
	check(_has_error(errs, "banners.json"), "invalid-JSON error names the file")

	var well_formed := "{\"name\": \"x\"}"
	var errs2 := ContentValidator.validate_text("banners.json", well_formed, {})
	check(not _has_error(errs2, "invalid JSON"), "well-formed JSON text parses without a parse error")

	var scalar := "42"
	var errs3 := ContentValidator.validate_text("items.json", scalar, {})
	check(_has_error(errs3, "top-level JSON value must be an object"), "a non-object top-level JSON value is rejected")


# --------------------------------------------- Phase 2: duplicate-key scanner

## Repeated keys in raw JSON text are reported by _scan_duplicate_keys and also
## surface through the validate_text() scan path. No temp files are written.
func _test_duplicate_keys() -> void:
	var dup := ContentValidator._scan_duplicate_keys("characters.json", "{\"lyra_vey\": 1, \"lyra_vey\": 2}")
	check(_has_error(dup, "duplicate key 'lyra_vey'"), "a repeated character id is reported")
	check(_has_error(dup, "characters.json"), "duplicate-key error identifies the file")

	var nested := ContentValidator._scan_duplicate_keys("items.json", "{\"gold\": 1, \"bag\": { \"sap\": 1, \"sap\": 2 }}")
	check(_has_error(nested, "duplicate key 'sap'"), "a repeated nested key is reported with its path")

	var via_text := ContentValidator.validate_text("banners.json", "{\"rates\": {}, \"rates\": {}}", {})
	check(_has_error(via_text, "duplicate key 'rates'"), "validate_text surfaces duplicate keys")

	var clean := ContentValidator._scan_duplicate_keys("items.json", "{\"a\": 1, \"b\": 2}")
	check(clean.is_empty(), "distinct keys produce no duplicate-key errors")


# --------------------------------------------- Phase 2: missing references

## Synthetic documents with dangling references must produce errors that
## identify the file and the offending field (skill / enemy / character).
func _test_missing_references() -> void:
	var report := ContentValidator.validate_all()
	var ctx: Dictionary = report.get("data", {})
	var report_errors: Array = report.get("errors", [])
	check(report_errors.is_empty(), "validate_all: shipped data is clean")
	check(ctx.size() == 9, "validate_all parsed all 9 content files", str(ctx.size()))
	var greenward_composition := load("res://resources/world/greenward_composition.tres") as GreenwardCompositionData
	check(greenward_composition != null, "Greenward composition resource loads")
	if greenward_composition != null:
		check(greenward_composition.validate().is_empty(), "Greenward composition data validates", str(greenward_composition.validate()))
		check(greenward_composition.village_npcs.size() == 3 and greenward_composition.river_props.size() == 13 and greenward_composition.river_animated_props.size() == 7, "Greenward village and river placements are data-backed")
		check(greenward_composition.anchors.size() == 20 and greenward_composition.path_routes.size() == 5, "Greenward landmark anchors and route endpoints are validated region data")

	# Character referencing a nonexistent skill id.
	var char_doc := {
		"test_ghost": {
			"name": "Ghost", "element": "fire", "rarity": "common",
			"base": { "hp": 100, "atk": 10, "def": 10, "spd": 10, "crit": 0.05 },
			"skills": ["ghost_skill_xyz", "gale_shot"],
			"ultimate": "",
			"passive": { "id": "rooted", "name": "R", "text": "T" },
			"palette": { "hair": "#ffffff", "primary": "#ffffff", "secondary": "#ffffff", "accent": "#ffffff", "skin": "#ffffff" }
		}
	}
	var e1 := ContentValidator.validate_document("characters.json", char_doc, ctx)
	check(_has_error(e1, "references missing skill 'ghost_skill_xyz'"), "character missing-skill reference is caught")
	check(_has_error(e1, "characters.json") and _has_error(e1, "skills"), "missing-skill error identifies file and field")

	# Enemy group referencing a missing enemy.
	var group_doc := {
		"test_group": {
			"name": "Ghost Group", "region": "greenward", "level": 1,
			"enemies": ["ghost_enemy_xyz"],
			"rewards": { "gold": 10, "items": { "glade_sap": 1 } },
			"elite": false, "boss": false
		}
	}
	var e2 := ContentValidator.validate_document("enemy_groups.json", group_doc, ctx)
	check(_has_error(e2, "references missing enemy 'ghost_enemy_xyz'"), "enemy group missing-enemy reference is caught")
	check(_has_error(e2, "enemy_groups.json") and _has_error(e2, "enemies"), "missing-enemy error identifies file and field")

	# Banner pool referencing a missing character.
	var banner := _base_banner()
	banner["pool"]["common"] = ["mira_sol", "ghost_character_xyz"]
	var e3 := ContentValidator.validate_document("banners.json", { "test_banner": banner }, ctx)
	check(_has_error(e3, "references missing character 'ghost_character_xyz'"), "banner pool missing-character reference is caught")
	check(_has_error(e3, "banners.json") and _has_error(e3, "pool"), "missing-character error identifies file and field")


# --------------------------------------------- Phase 2: invalid banner configs

## At least two distinct bad banner configurations must be rejected with a
## meaningful message; a fully valid banner is the baseline.
func _test_invalid_banner_configs() -> void:
	var ctx: Dictionary = ContentValidator.validate_all().get("data", {})

	var ok := ContentValidator.validate_document("banners.json", { "test_banner": _base_banner() }, ctx)
	check(ok.is_empty(), "a fully valid banner config passes validation", str(ok))

	# 1. Rates do not sum to ~1.0.
	var bad_rates := _base_banner()
	bad_rates["rates"]["common"] = 0.90
	var e1 := ContentValidator.validate_document("banners.json", { "test_banner": bad_rates }, ctx)
	check(_has_error(e1, "rates must sum to 1.0"), "banner rates summing to 1.38 are rejected")

	# 2. Unknown rarity key.
	var bad_rarity := _base_banner()
	bad_rarity["rates"]["divine"] = 0.10
	var e2 := ContentValidator.validate_document("banners.json", { "test_banner": bad_rarity }, ctx)
	check(_has_error(e2, "unknown rarity"), "banner with unknown rarity 'divine' is rejected")

	# 3. hard_pity <= 0.
	var bad_pity := _base_banner()
	bad_pity["hard_pity"] = 0
	var e3 := ContentValidator.validate_document("banners.json", { "test_banner": bad_pity }, ctx)
	check(_has_error(e3, "hard_pity") and _has_error(e3, "must be between 1"), "banner hard_pity=0 is rejected")

	# 4. Featured character absent from the pool.
	var bad_featured := _base_banner()
	bad_featured["pool"]["epic"] = ["coralyn", "vespera", "arachnia"]
	var e4 := ContentValidator.validate_document("banners.json", { "test_banner": bad_featured }, ctx)
	check(_has_error(e4, "is not in the banner pool"), "featured character missing from the pool is rejected")

	# 5. Bad cost currency (references a missing item).
	var bad_cost := _base_banner()
	bad_cost["cost"]["currency"] = "ghost_currency"
	var e5 := ContentValidator.validate_document("banners.json", { "test_banner": bad_cost }, ctx)
	check(_has_error(e5, "references missing item 'ghost_currency'"), "banner cost with an unknown currency is rejected")


# --------------------------------------------- Phase 2: quest prerequisites

## start_quest() enforces the data requires prerequisite. Self-contained:
## starts from a fresh new_game() and is restored by the runner's snapshot.
func _test_quest_requirements() -> void:
	GameState.new_game("Quest Requirements Test")
	check(not GameState.start_quest("hollow_roots"), "hollow_roots is blocked while its prerequisite is incomplete")
	check(GameState.quest_state("hollow_roots") == "not_started", "a blocked quest remains not_started")

	# A normal quest with no requires still starts (and serves as the prereq).
	check(GameState.start_quest("glade_whisper", "elder_maelin"), "a quest with no requires starts")
	GameState.record_kill("mossling", 3)
	check(GameState.quest_ready("glade_whisper"), "the prerequisite quest reaches its ready state")
	check(GameState.complete_quest("glade_whisper"), "the prerequisite quest completes")
	check(GameState.quest_state("glade_whisper") == "complete", "the prerequisite state is complete")
	check(GameState.start_quest("hollow_roots"), "hollow_roots starts once its prerequisite is complete")
	check(GameState.quest_state("hollow_roots") == "active", "hollow_roots is active after starting")

	# A quest whose requires points at a nonexistent quest cannot start.
	ContentDB.quests["test_bad_prereq"] = {
		"name": "Bad Prereq", "region": "greenward", "summary": "Synthetic",
		"requires": "does_not_exist", "steps": [], "rewards": {}
	}
	check(not GameState.start_quest("test_bad_prereq"), "a quest with a nonexistent prerequisite quest is rejected")
	ContentDB.quests.erase("test_bad_prereq")


# --------------------------------------------- Moonpetal Hollow story content

func _test_moonpetal_story_content() -> void:
	var quest: Dictionary = ContentDB.get_quest("moonpetal_echoes")
	check(not quest.is_empty(), "Moonpetal Hollow story quest loads")
	check(str(quest.get("region", "")) == "moonpetal_hollow", "Moonpetal story quest is region-bound")
	check(str(quest.get("requires", "")) == "matron_bloom", "Moonpetal story follows the Fallen Matron arc")
	var dialogue: Dictionary = ContentDB.get_dialogue("moonkeeper_liora")
	check(not dialogue.is_empty() and dialogue.get("nodes", {}).has("turnin"), "Moonkeeper dialogue includes a quest turn-in")
	var group: Dictionary = ContentDB.get_enemy_group("moonpetal_echoes_pack")
	check(group.get("enemies", []).count("moonpetal_sprite") == 2, "Moonpetal encounter group contains two quest sprites")
	var region: Dictionary = ContentDB.get_region("moonpetal_hollow")
	var npc_found := false
	for poi in region.get("pois", []):
		if str(poi.get("id", "")) == "moonkeeper_liora":
			npc_found = true
	check(npc_found, "Moonkeeper Liora is registered as a Moonpetal point of interest")
	var spawn_count := 0
	for spawn in region.get("spawns", []):
		if str(spawn.get("group", "")) == "moonpetal_echoes_pack":
			spawn_count += 1
	check(spawn_count == 2, "Moonpetal story encounter has two authored spawn sites")

	GameState.new_game("Moonpetal Story Test")
	check(not GameState.start_quest("moonpetal_echoes"), "Moonpetal story remains locked before Matron is defeated")
	GameState.quests["matron_bloom"] = {"state": "complete", "step": 2}
	check(GameState.start_quest("moonpetal_echoes", "moonkeeper_liora"), "Moonpetal story starts after the Matron arc")
	GameState.record_kill("moonpetal_sprite", 3)
	check(GameState.quest_ready("moonpetal_echoes"), "calming three sprites readies the Silver Pool quest")
	check(GameState.complete_quest("moonpetal_echoes"), "Silver Pool quest can be completed and rewarded")

# --------------------------------------------- Phase 2: reward validation

## Reward tables referencing missing item ids must be rejected for both quests
## and enemy groups, and grant_reward_items() must route currencies vs items.
func _test_reward_validation() -> void:
	var ctx: Dictionary = ContentValidator.validate_all().get("data", {})

	var good_quest := {
		"test_quest": {
			"name": "Synthetic Quest", "region": "greenward", "summary": "Synthetic",
			"steps": [
				{ "type": "talk", "target": "elder_maelin", "text": "Talk" },
				{ "type": "kill", "target": "mossling", "count": 1, "text": "Kill" }
			],
			"rewards": { "gold": 10, "items": { "glade_sap": 1 } }
		}
	}
	var good_group := {
		"test_group": {
			"name": "Synthetic Group", "region": "greenward", "level": 1,
			"enemies": ["mossling"],
			"rewards": { "gold": 10, "items": { "glade_sap": 1 } },
			"elite": false, "boss": false
		}
	}
	var q_ok := ContentValidator.validate_document("quests.json", good_quest, ctx)
	var g_ok := ContentValidator.validate_document("enemy_groups.json", good_group, ctx)
	check(q_ok.is_empty(), "a valid quest reward passes validation", str(q_ok))
	check(g_ok.is_empty(), "a valid enemy-group reward passes validation", str(g_ok))

	var bad_quest := good_quest.duplicate(true)
	bad_quest["test_quest"]["rewards"]["items"] = { "ghost_item_xyz": 1 }
	var q_bad := ContentValidator.validate_document("quests.json", bad_quest, ctx)
	check(_has_error(q_bad, "references missing item 'ghost_item_xyz'"), "quest reward missing-item reference is caught")
	check(_has_error(q_bad, "quests.json"), "quest reward error identifies the file")

	var bad_group := good_group.duplicate(true)
	bad_group["test_group"]["rewards"]["items"] = { "ghost_item_abc": 1 }
	var g_bad := ContentValidator.validate_document("enemy_groups.json", bad_group, ctx)
	check(_has_error(g_bad, "references missing item 'ghost_item_abc'"), "enemy-group reward missing-item reference is caught")
	check(_has_error(g_bad, "enemy_groups.json"), "enemy-group reward error identifies the file")

	# grant_reward_items(): currency-category entries -> wallet, others -> inventory.
	GameState.new_game("Reward Routing Test")
	var crystals_before: Variant = GameState.currency("crystals")
	var sap_before: Variant = GameState.item_count("glade_sap")
	GameState.grant_reward_items({ "crystals": 25, "glade_sap": 2 })
	check(GameState.currency("crystals") == crystals_before + 25, "a currency reward is routed to add_currency")
	check(GameState.item_count("glade_sap") == sap_before + 2, "a material reward is routed to add_item")
	check(GameState.item_count("crystals") == 0, "a currency reward does not enter the inventory")
	check(GameState.currency("glade_sap") == 0, "a material reward does not enter the wallet")
	GameState.grant_reward_items({ "glade_sap": 0 })
	check(GameState.item_count("glade_sap") == sap_before + 2, "a zero-amount reward is ignored")


# ------------------------------------------------------- Phase 3 shared helpers
# Signal counters and small drivers used ONLY by the Phase 3 visual tests. The
# _phase3_ prefix avoids any collision with the Phase 2 helpers above.

var _phase3_one_shot_count: int = 0
var _phase3_activated_count: int = 0


func _phase3_on_one_shot(_state: int) -> void:
	_phase3_one_shot_count += 1


func _phase3_on_activated(_prop) -> void:
	_phase3_activated_count += 1


## Apply a fixed, deterministic sequence so two animators can be compared.
func _phase3_drive_anim(a: CharacterAnimator) -> void:
	a.play(CharacterAnimator.State.WALK, CharacterAnimator.Direction.RIGHT)
	a.tick(0.05)
	a.set_direction(CharacterAnimator.Direction.UP_LEFT)
	a.tick(0.13)
	a.play(CharacterAnimator.State.RUN)
	a.tick(0.07)
	a.play_forced(CharacterAnimator.State.ATTACK)
	a.tick(0.2)


## Free the standalone nodes returned by ChunkBuilder.build(). detail is a
## child of terrain, so freeing terrain frees it too (never double-freed).
func _phase3_free_chunk(data: Dictionary) -> void:
	var terr: Variant = data.get("terrain")
	if terr is Node and is_instance_valid(terr):
		(terr as Node).free()
	var wat: Variant = data.get("water")
	if wat is Node and is_instance_valid(wat):
		(wat as Node).free()


# ------------------------------------------------- Phase 3: visual style authority
## GreenwardStyle is the single colour/lighting/sprite-spec authority. Verifies
## coherence, valid Colour ranges, phase coverage, timing consistency with
## CharacterAnimator and the documented performance caps.
func _test_visual_style() -> void:
	check(GreenwardStyle.coherence_report().is_empty(),
		"GreenwardStyle.coherence_report() is empty", str(GreenwardStyle.coherence_report()))

	var cols: Array = GreenwardStyle.all_colors()
	check(not cols.is_empty(), "all_colors() is non-empty", str(cols.size()))
	var colors_valid := true
	var distinct := {}
	for raw in cols:
		if typeof(raw) != TYPE_COLOR:
			colors_valid = false
			continue
		var c: Color = raw
		if c.r < 0.0 or c.r > 1.0 or c.g < 0.0 or c.g > 1.0 or c.b < 0.0 or c.b > 1.0 or c.a < 0.0 or c.a > 1.0:
			colors_valid = false
		distinct[var_to_str(c)] = true
	check(colors_valid, "every all_colors() element is a valid Color in [0,1]")
	check(distinct.size() >= 30, "at least 30 distinct colours across the palette", str(distinct.size()))
	check(not GreenwardStyle.WATER.shallow.is_equal_approx(GreenwardStyle.WATER.deep), "water shallow/deep are distinct")
	check(not GreenwardStyle.CANOPY.deep.is_equal_approx(GreenwardStyle.CANOPY.mid), "canopy deep/mid are distinct")
	check(not GreenwardStyle.MAGIC.teal.is_equal_approx(GreenwardStyle.MAGIC.gold), "magic teal/gold are distinct")

	var phases: Array[String] = GreenwardStyle.REQUIRED_PHASES
	var keys: Array[String] = GreenwardStyle.REQUIRED_PHASE_KEYS
	check(phases.size() >= 6, "REQUIRED_PHASES covers the canonical phases", str(phases.size()))
	var keys_ok := true
	var colors_ok2 := true
	var nums_ok := true
	var bool_ok := true
	var tints := {}
	for phase_name in phases:
		var entry: Dictionary = GreenwardStyle.phase(phase_name)
		for k in keys:
			if not entry.has(k):
				keys_ok = false
		for ck in ["tint", "fog", "sky_top", "sky_bottom"]:
			if typeof(entry.get(ck)) != TYPE_COLOR:
				colors_ok2 = false
		for nk in ["ambient", "light_energy", "fog_density"]:
			var nv: Variant = entry.get(nk)
			if not (typeof(nv) == TYPE_FLOAT or typeof(nv) == TYPE_INT):
				nums_ok = false
			elif float(nv) < 0.0 or float(nv) > 1.0:
				nums_ok = false
		if typeof(entry.get("fireflies")) != TYPE_BOOL:
			bool_ok = false
		var tv: Variant = entry.get("tint")
		if typeof(tv) == TYPE_COLOR:
			tints[var_to_str(tv)] = true
	check(keys_ok, "every REQUIRED_PHASES entry has all REQUIRED_PHASE_KEYS")
	check(colors_ok2, "phase tint/fog/sky_top/sky_bottom are Colors")
	check(nums_ok, "phase ambient/light_energy/fog_density are floats in [0,1]")
	check(bool_ok, "phase fireflies is a bool")
	check(tints.size() >= 2, "at least two phases return different tints", str(tints.size()))

	var elem_match := true
	var elem_distinct := {}
	for ek in GreenwardStyle.ELEMENTS.keys():
		var ec: Color = GreenwardStyle.element_color(str(ek))
		if not ec.is_equal_approx(GreenwardStyle.ELEMENTS[ek]):
			elem_match = false
		elem_distinct[var_to_str(ec)] = true
	check(elem_match, "element_color() matches ELEMENTS for every element")
	check(GreenwardStyle.element_color("no_such_element").is_equal_approx(GreenwardStyle.ELEMENTS["neutral"]), "unknown element falls back to neutral")
	check(elem_distinct.size() >= 3, "at least 3 distinct element colours", str(elem_distinct.size()))

	var kinds: Array[String] = GreenwardStyle.prop_kinds()
	check(kinds.size() >= 47, "at least 47 prop kinds", str(kinds.size()))
	var kset := {}
	for k in kinds:
		kset[k] = true
	check(kset.size() == kinds.size(), "prop_kinds() has no duplicates")
	var authored_report := ProceduralArt.authored_environment_report()
	check(int(authored_report.get("total_kinds", -1)) == kinds.size(), "Authored environment audit covers the complete prop catalogue")
	check(int(authored_report.get("authored_count", 0)) == authored_report.get("authored", []).size(), "Authored environment count matches registered sprites")
	check(authored_report.get("invalid_assets", []).is_empty(), "Every registered authored environment sprite exists", str(authored_report.get("invalid_assets", [])))
	check(authored_report.get("procedural_fallback", []).size() + authored_report.get("authored", []).size() == kinds.size(), "Every prop kind is classified as authored or procedural fallback")
	check(authored_report.get("authored", []).size() == 14, "Fourteen environment props currently use authored SVG assets", str(authored_report.get("authored", [])))
	var pal_ok := true
	var vc_ok := true
	for k in kinds:
		var pal: Dictionary = GreenwardStyle.prop_palette(k)
		var extracted_pal: Dictionary = GreenwardPropPalette.palette(k)
		if extracted_pal != pal:
			pal_ok = false
		if pal.is_empty():
			pal_ok = false
		for pk in pal.keys():
			if typeof(pal[pk]) != TYPE_COLOR:
				pal_ok = false
		if GreenwardStyle.variant_count(k) < 1:
			vc_ok = false
	check(pal_ok, "prop_palette() is non-empty with Color values for every kind")
	check(vc_ok, "variant_count() >= 1 for every kind")
	var sample: Array[String] = ["willow_tree", "birch_tree", "pine_tree", "flower", "flower_cluster", "cottage", "wooden_bridge", "shrine"]
	var complex_ok := true
	for k in sample:
		if GreenwardStyle.variant_count(k) < 2:
			complex_ok = false
	check(complex_ok, "tree/flower/structure kinds expose >= 2 variants")

	var S: Dictionary = GreenwardStyle.SPRITE_SPECS
	check(int(S["world_width"]) == 96, "SPRITE_SPECS.world_width == 96")
	check(int(S["world_height"]) == 128, "SPRITE_SPECS.world_height == 128")
	check(int(S["boss_width"]) == 128, "SPRITE_SPECS.boss_width == 128")
	check(int(S["boss_height"]) == 192, "SPRITE_SPECS.boss_height == 192")
	check(S["anchor"] == Vector2(0.5, 1.0), "SPRITE_SPECS.anchor == (0.5,1.0)")
	check(int(S["outline_px"]) == 2, "SPRITE_SPECS.outline_px == 2")
	check(int(S["state_count"]) == 8, "SPRITE_SPECS.state_count == 8")
	check(int(S["direction_count"]) == 8, "SPRITE_SPECS.direction_count == 8")
	var fc: Array = S["frame_counts"]
	var fv: Array = S["fps_values"]
	var lf: Array = S["loop_flags"]
	check(fc.size() == 8 and fv.size() == 8 and lf.size() == 8, "SPRITE_SPECS int-indexed timing arrays have 8 entries")
	var timing_int_ok := true
	for raw in CharacterAnimator.ALL_STATES:
		var st := int(raw)
		if int(fc[st]) != int(CharacterAnimator.STATE_FRAMES[st]):
			timing_int_ok = false
		if not near(float(fv[st]), float(CharacterAnimator.STATE_FPS[st])):
			timing_int_ok = false
		if bool(lf[st]) != bool(CharacterAnimator.STATE_LOOPING[st]):
			timing_int_ok = false
	check(timing_int_ok, "SPRITE_SPECS frame_counts/fps_values/loop_flags match CharacterAnimator")
	var sname: Array = S["state_names"]
	var frames_map: Dictionary = S["frames"]
	var fps_map: Dictionary = S["fps"]
	var loop_map: Dictionary = S["loop"]
	var name_ok := true
	for raw in CharacterAnimator.ALL_STATES:
		var st2 := int(raw)
		var nm: String = str(sname[st2])
		if int(frames_map[nm]) != int(CharacterAnimator.STATE_FRAMES[st2]):
			name_ok = false
		if not near(float(fps_map[nm]), float(CharacterAnimator.STATE_FPS[st2])):
			name_ok = false
		if bool(loop_map[nm]) != bool(CharacterAnimator.STATE_LOOPING[st2]):
			name_ok = false
	check(name_ok, "SPRITE_SPECS name-keyed frames/fps/loop agree with CharacterAnimator")

	var tier := GreenwardStyle.performance_tier()
	check(tier == "mobile" or tier == "desktop", "performance_tier() is mobile or desktop", tier)
	check(GreenwardStyle.MAX_PROPS_PER_CHUNK > 0, "MAX_PROPS_PER_CHUNK > 0", str(GreenwardStyle.MAX_PROPS_PER_CHUNK))
	check(GreenwardStyle.MAX_PARTICLES > 0, "MAX_PARTICLES > 0", str(GreenwardStyle.MAX_PARTICLES))
	check(GreenwardStyle.DETAIL_DENSITY > 0.0 and GreenwardStyle.DETAIL_DENSITY <= 1.0, "DETAIL_DENSITY in (0,1]", str(GreenwardStyle.DETAIL_DENSITY))


# ------------------------------------------- Phase 3: character animator (pure)
## CharacterAnimator is a pure, deterministic 8x8 state machine. Exercises
## validation, play()/priority, 8-way direction mapping, looping and one-shot
## ticking, snapshot round-trips and determinism — with no SceneTree needed.
func _test_character_animator() -> void:
	check(CharacterAnimator.ALL_STATES == CharacterAnimationSpecCatalog.ALL_STATES, "CharacterAnimator state ids delegate to the immutable spec catalog")
	check(CharacterAnimator.ALL_DIRECTIONS == CharacterAnimationSpecCatalog.ALL_DIRECTIONS, "CharacterAnimator direction ids delegate to the immutable spec catalog")
	check(CharacterAnimator.STATE_NAMES == CharacterAnimationSpecCatalog.STATE_NAMES and CharacterAnimator.DIRECTION_NAMES == CharacterAnimationSpecCatalog.DIRECTION_NAMES, "animation state/direction labels remain catalog-aligned")
	check(CharacterAnimator.STATE_FRAMES == CharacterAnimationSpecCatalog.STATE_FRAMES and CharacterAnimator.STATE_FPS == CharacterAnimationSpecCatalog.STATE_FPS, "animation frame counts and playback rates remain catalog-aligned")
	check(CharacterAnimator.STATE_PRIORITY == CharacterAnimationSpecCatalog.STATE_PRIORITY and CharacterAnimator.STATE_LOOPING == CharacterAnimationSpecCatalog.STATE_LOOPING, "animation priority and looping contracts remain catalog-aligned")
	check(CharacterAnimator.ALL_STATES.size() == 8, "ALL_STATES has 8 states", str(CharacterAnimator.ALL_STATES.size()))
	check(CharacterAnimator.ALL_DIRECTIONS.size() == 8, "ALL_DIRECTIONS has 8 directions", str(CharacterAnimator.ALL_DIRECTIONS.size()))
	var sn_ok := true
	for raw in CharacterAnimator.ALL_STATES:
		if CharacterAnimator.state_name(int(raw)).is_empty():
			sn_ok = false
	check(sn_ok, "state_name() is non-empty for all states")
	var dn_ok := true
	for raw in CharacterAnimator.ALL_DIRECTIONS:
		if CharacterAnimator.direction_name(int(raw)).is_empty():
			dn_ok = false
	check(dn_ok, "direction_name() is non-empty for all directions")
	var valid_ok := true
	for raw in CharacterAnimator.ALL_STATES:
		if not CharacterAnimator.is_valid_state(int(raw)):
			valid_ok = false
	for raw in CharacterAnimator.ALL_DIRECTIONS:
		if not CharacterAnimator.is_valid_direction(int(raw)):
			valid_ok = false
	check(valid_ok, "is_valid_state/direction accept every valid id")
	check(not CharacterAnimator.is_valid_state(-1) and not CharacterAnimator.is_valid_state(99), "is_valid_state rejects -1 and 99")
	check(not CharacterAnimator.is_valid_direction(-1) and not CharacterAnimator.is_valid_direction(99), "is_valid_direction rejects -1 and 99")

	var a := CharacterAnimator.new()
	check(a.state == CharacterAnimator.State.IDLE and a.direction == CharacterAnimator.Direction.DOWN and a.frame == 0, "animator starts at IDLE/DOWN/frame 0")
	check(a.play(CharacterAnimator.State.WALK) == true, "play() returns true on a real change")
	check(a.state == CharacterAnimator.State.WALK, "play() sets the new state")
	check(a.frame == 0 and near(a.elapsed, 0.0), "state change resets frame and elapsed")
	check(a.tick(0.1) == true, "tick() advances a looping frame")
	check(a.frame >= 1, "WALK frame advanced at its fps", str(a.frame))
	check(a.play(CharacterAnimator.State.WALK) == false, "play() is a no-op when the state is unchanged")
	check(a.play(CharacterAnimator.State.RUN) == true, "play() to a different state reports a change")
	check(a.state == CharacterAnimator.State.RUN and a.frame == 0 and near(a.elapsed, 0.0), "a new state resets frame/elapsed")

	var b := CharacterAnimator.new()
	check(b.play(CharacterAnimator.State.DEFEAT) == true, "DEFEAT can start from IDLE")
	b.play(CharacterAnimator.State.IDLE)
	check(b.state == CharacterAnimator.State.DEFEAT, "IDLE cannot interrupt an unfinished DEFEAT one-shot")
	var c := CharacterAnimator.new()
	c.play(CharacterAnimator.State.IDLE)
	check(c.play(CharacterAnimator.State.DEFEAT) == true, "DEFEAT can interrupt IDLE")
	check(c.state == CharacterAnimator.State.DEFEAT, "DEFEAT wins over IDLE")
	b.play_forced(CharacterAnimator.State.IDLE)
	check(b.state == CharacterAnimator.State.IDLE, "play_forced() bypasses priority")

	var d := CharacterAnimator.new()
	var dir_cases: Array = [
		[Vector2(1, 0), CharacterAnimator.Direction.RIGHT],
		[Vector2(1, 1), CharacterAnimator.Direction.DOWN_RIGHT],
		[Vector2(0, 1), CharacterAnimator.Direction.DOWN],
		[Vector2(-1, 1), CharacterAnimator.Direction.DOWN_LEFT],
		[Vector2(-1, 0), CharacterAnimator.Direction.LEFT],
		[Vector2(-1, -1), CharacterAnimator.Direction.UP_LEFT],
		[Vector2(0, -1), CharacterAnimator.Direction.UP],
		[Vector2(1, -1), CharacterAnimator.Direction.UP_RIGHT],
	]
	var dir_match := 0
	var dir_set := {}
	for case in dir_cases:
		var vec: Vector2 = case[0]
		var expected := int(case[1])
		if d.set_direction_from_vector(vec) == expected:
			dir_match += 1
		dir_set[expected] = true
	check(dir_match == 8, "all 8 vectors map to their expected Direction enum", "%d/8" % dir_match)
	check(dir_set.size() == 8, "the 8 vectors cover all 8 distinct directions", str(dir_set.size()))
	var keep := d.direction
	check(d.set_direction_from_vector(Vector2.ZERO) == keep, "zero vector keeps the current direction")

	var e := CharacterAnimator.new()
	check(e.is_looping(), "IDLE is a looping state")
	check(e.tick(0.12) == true, "tick() returns true when the frame advances")
	check(e.frame >= 1, "IDLE frame advanced after 0.12s", str(e.frame))
	var wrap_ok := true
	for i in 20:
		e.tick(0.37)
		if e.frame < 0 or e.frame >= e.frame_count():
			wrap_ok = false
	check(wrap_ok, "looping frames always wrap within frame_count()")

	var f := CharacterAnimator.new()
	_phase3_one_shot_count = 0
	f.one_shot_finished.connect(_phase3_on_one_shot)
	f.play_forced(CharacterAnimator.State.ATTACK)
	check(f.state == CharacterAnimator.State.ATTACK and not f.is_looping(), "ATTACK is a one-shot state")
	var total := 0.0
	while total < 2.0:
		f.tick(0.1)
		total += 0.1
	check(f.is_finished(), "one-shot reaches is_finished()")
	check(f.playing == false, "one-shot stops playing")
	check(f.frame == f.frame_count() - 1, "one-shot clamps to the last frame", str(f.frame))
	check(_phase3_one_shot_count == 1, "one_shot_finished emitted exactly once", str(_phase3_one_shot_count))

	var g := CharacterAnimator.new()
	g.play(CharacterAnimator.State.RUN, CharacterAnimator.Direction.UP_LEFT)
	g.tick(0.09)
	var snap: Dictionary = g.snapshot()
	var g2 := CharacterAnimator.from_snapshot(snap)
	check(snap == g2.snapshot(), "snapshot()/from_snapshot() round-trip identically")
	check(g2.state == g.state and g2.direction == g.direction and g2.frame == g.frame, "round-trip preserves state/direction/frame")
	check(near(g2.elapsed, g.elapsed) and near(g2.speed_scale, g.speed_scale), "round-trip preserves elapsed/speed_scale")

	var h1 := CharacterAnimator.new()
	var h2 := CharacterAnimator.new()
	_phase3_drive_anim(h1)
	_phase3_drive_anim(h2)
	check(h1.snapshot() == h2.snapshot(), "identical call sequences produce identical snapshots")

	var fps_ok := true
	var fc_ok := true
	for raw in CharacterAnimator.ALL_STATES:
		var s := int(raw)
		var tmp := CharacterAnimator.new()
		tmp.play_forced(s)
		if not (tmp.fps() > 0.0):
			fps_ok = false
		if not (tmp.frame_count() > 0):
			fc_ok = false
	check(fps_ok, "fps() > 0 for all 8 states")
	check(fc_ok, "frame_count() > 0 for all 8 states")
	var bad := CharacterAnimator.new()
	bad.play(99)
	check(bad.state == CharacterAnimator.State.IDLE, "invalid play() state clamps to IDLE without crashing")
	bad.set_direction(99)
	check(bad.direction == CharacterAnimator.Direction.DOWN, "invalid direction clamps to DOWN")
	var bad2 := CharacterAnimator.new()
	bad2.play_forced(-1)
	check(bad2.state == CharacterAnimator.State.IDLE, "play_forced(-1) clamps to IDLE")


# ------------------------------------------- Phase 3: actor frame source (seam)
## The ActorFrameSource / ProceduralActorFrames seam must honour the 8x8 state x
## direction contract, return cached 96x128 frames, and produce genuinely
## distinct pixels per state/direction/frame index (bounded texture sampling).
func _test_actor_frame_source() -> void:
	var base := ActorFrameSource.new()
	check(base.has_frames() == false, "base ActorFrameSource.has_frames() is false")
	check(base.frame(0, 0, 0) == null, "base ActorFrameSource.frame() returns null")
	check(base.is_temporary() == true, "base ActorFrameSource is temporary")
	var bspec: Dictionary = base.specs()
	check(bspec.has("replacement"), "base specs() exposes a 'replacement' spec")
	check("96 x 128" in str(bspec.get("replacement", "")), "replacement spec mentions the 96 x 128 canvas")
	check(bspec.get("states", []).size() == 8 and bspec.get("directions", []).size() == 8, "base specs() lists 8 states and 8 directions")
	check(int(bspec.get("states_count", 0)) == 8 and int(bspec.get("directions_count", 0)) == 8, "base specs() reports 8 states/directions")

	var pal := {"hair": "#5a3a2a", "primary": "#2f4a6b", "secondary": "#c9a45a", "accent": "#7fe3e0", "skin": "#f0cbb0"}
	var src := ProceduralActorFrames.new(pal)
	check(src.has_frames() == true, "ProceduralActorFrames.has_frames() is true")
	check(src.is_temporary() == true, "ProceduralActorFrames.is_temporary() is true")
	var label := src.source_label()
	check("placeholder" in label or "temporary" in label, "source_label() marks the source as placeholder/temporary", label)

	var f0_nonnull := true
	var f0_w := true
	var f0_h := true
	for raws in CharacterAnimator.ALL_STATES:
		var s := int(raws)
		for rawd in CharacterAnimator.ALL_DIRECTIONS:
			var d2 := int(rawd)
			var tex: Texture2D = src.frame(s, d2, 0)
			if tex == null:
				f0_nonnull = false
				continue
			var img := tex.get_image()
			if img.get_width() != 96:
				f0_w = false
			if img.get_height() != 128:
				f0_h = false
	check(f0_nonnull, "frame 0 is non-null for all 8x8 (state,direction) combos")
	check(f0_w, "every sampled frame is 96px wide")
	check(f0_h, "every sampled frame is 128px tall")

	var full_ok := true
	var full_count := 0
	for raws in [CharacterAnimator.State.IDLE, CharacterAnimator.State.RUN, CharacterAnimator.State.VICTORY]:
		var s := int(raws)
		var cnt := src.frame_count(s, CharacterAnimator.Direction.DOWN)
		for fi in cnt:
			full_count += 1
			var tex2: Texture2D = src.frame(s, CharacterAnimator.Direction.DOWN, fi)
			if tex2 == null or tex2.get_image().get_width() != 96 or tex2.get_image().get_height() != 128:
				full_ok = false
	check(full_ok, "all frames of IDLE/RUN/VICTORY render at 96x128")
	var expected_full_count := 0
	for raws2 in [CharacterAnimator.State.IDLE, CharacterAnimator.State.RUN, CharacterAnimator.State.VICTORY]:
		expected_full_count += int(CharacterAnimator.STATE_FRAMES[int(raws2)])
	check(full_count == expected_full_count, "sampled all frames of 3 states (bounded)", "%d (expected %d)" % [full_count, expected_full_count])

	var c1 := src.frame(CharacterAnimator.State.WALK, CharacterAnimator.Direction.RIGHT, 0)
	var c2 := src.frame(CharacterAnimator.State.WALK, CharacterAnimator.Direction.RIGHT, 0)
	check(c1 == c2, "frame() is cached (identical object for the same address)")

	var st_a := src.frame(CharacterAnimator.State.IDLE, CharacterAnimator.Direction.DOWN, 0)
	var st_b := src.frame(CharacterAnimator.State.ATTACK, CharacterAnimator.Direction.DOWN, 0)
	check(st_a.get_image().get_data() != st_b.get_image().get_data(), "frames for different states differ in pixels")
	var dir_a := src.frame(CharacterAnimator.State.WALK, CharacterAnimator.Direction.DOWN, 0)
	var dir_b := src.frame(CharacterAnimator.State.WALK, CharacterAnimator.Direction.UP, 0)
	check(dir_a.get_image().get_data() != dir_b.get_image().get_data(), "frames for different directions differ in pixels")
	var fi_a := src.frame(CharacterAnimator.State.WALK, CharacterAnimator.Direction.DOWN, 0)
	var fi_b := src.frame(CharacterAnimator.State.WALK, CharacterAnimator.Direction.DOWN, 1)
	check(fi_a.get_image().get_data() != fi_b.get_image().get_data(), "frames for different frame indices differ in pixels")

	var timing_ok := true
	for raw in CharacterAnimator.ALL_STATES:
		var s := int(raw)
		if src.frame_count(s, 0) != int(CharacterAnimator.STATE_FRAMES[s]):
			timing_ok = false
		if not near(src.fps(s), float(CharacterAnimator.STATE_FPS[s])):
			timing_ok = false
		if src.is_looping(s) != bool(CharacterAnimator.STATE_LOOPING[s]):
			timing_ok = false
	check(timing_ok, "frame_count/fps/is_looping match CharacterAnimator for all states")

	var pspec: Dictionary = src.specs()
	check(pspec.get("temporary") == true, "ProceduralActorFrames.specs().temporary == true")
	check(pspec.has("canvas") and pspec.has("anchor") and pspec.has("replacement"), "specs() exposes canvas/anchor/replacement")
	check(pspec.get("anchor") == Vector2(0.5, 1.0), "specs().anchor is bottom-centre (0.5,1.0)")
	check(src.frame(CharacterAnimator.State.IDLE, CharacterAnimator.Direction.DOWN, 99999) != null, "out-of-range frame index clamps and stays non-null")


# --------------------------------------------- Phase 3: procedural art variety
## ProceduralArt must expose >=47 distinct prop families, visually distinct
## variants (not just recolours), cached textures, distinct 96x128 character
## frames, and lazy regeneration after clear_cache().
func _test_procedural_variety() -> void:
	var kinds: Array[String] = ProceduralArt.prop_kinds()
	check(kinds.size() >= 47, "ProceduralArt.prop_kinds() >= 47", str(kinds.size()))
	var kset := {}
	for k in kinds:
		kset[k] = true
	check(kset.size() == kinds.size(), "prop_kinds() has no duplicates")
	var required: Array[String] = ["willow_tree", "birch_tree", "pine_tree", "blossom_tree", "dead_tree", "cottage", "wooden_bridge", "stone_bridge", "dock", "well", "shrine", "ruin_arch", "waterfall", "river_rock", "foam_ripple", "spirit_bloom", "rune_stone", "crystal_cluster", "wisp_lantern", "butterfly", "moth", "bird"]
	var missing: Array[String] = []
	for r in required:
		if not kset.has(r):
			missing.append(r)
	check(missing.is_empty(), "all new prop families are present", ", ".join(missing))

	var tex_ok := true
	for k in kinds:
		var t: Texture2D = ProceduralArt.prop_texture(k, 0)
		if t == null or t.get_width() <= 0 or t.get_height() <= 0:
			tex_ok = false
	check(tex_ok, "prop_texture(kind,0) is a positive-size texture for every kind")

	var distinct_pairs := 0
	var compared := 0
	for k in kinds:
		if ProceduralArt.variant_count(k) >= 2:
			compared += 1
			var a0: Texture2D = ProceduralArt.prop_texture(k, 0)
			var a1: Texture2D = ProceduralArt.prop_texture(k, 1)
			if a0.get_image().get_data() != a1.get_image().get_data():
				distinct_pairs += 1
	check(compared >= 20, "at least 20 kinds expose >= 2 variants", str(compared))
	check(distinct_pairs >= 20, "at least 20 kinds have visually distinct variant 0/1", str(distinct_pairs))

	var ca := ProceduralArt.prop_texture("glade_tree", 0)
	var cb := ProceduralArt.prop_texture("glade_tree", 0)
	check(ca == cb, "prop_texture() is cached (identical object)")

	var pal := {"hair": "#5a3a2a", "primary": "#2f4a6b", "secondary": "#c9a45a", "accent": "#7fe3e0", "skin": "#f0cbb0"}
	var cf0: Texture2D = ProceduralArt.character_frame(pal, 0, 0, 0)
	var cimg := cf0.get_image()
	check(cimg.get_width() == 96 and cimg.get_height() == 128, "character_frame() is 96x128")
	var direct_character_image := Image.create(96, 128, false, Image.FORMAT_RGBA8)
	direct_character_image.fill(Color(0, 0, 0, 0))
	ProceduralCharacterArt.draw_frame(direct_character_image, pal, 0, 0, 0)
	check(direct_character_image.get_data() == cimg.get_data(), "ProceduralArt facade delegates to ProceduralCharacterArt with pixel-identical output")
	check(cimg.get_format() == Image.FORMAT_RGBA8, "character_frame() is RGBA8")
	var cf0b: Texture2D = ProceduralArt.character_frame(pal, 0, 0, 0)
	check(cf0 == cf0b, "character_frame() is cached")
	check(cf0.get_image().get_data() != ProceduralArt.character_frame(pal, 4, 0, 0).get_image().get_data(), "character frames differ by state")
	check(cf0.get_image().get_data() != ProceduralArt.character_frame(pal, 0, 4, 0).get_image().get_data(), "character frames differ by direction")
	check(cf0.get_image().get_data() != ProceduralArt.character_frame(pal, 0, 0, 1).get_image().get_data(), "character frames differ by frame index")

	check(ProceduralArt.soft_glow() != null, "soft_glow() returns a texture")
	check(ProceduralArt.white_pixel() != null, "white_pixel() returns a texture")

	var tree_kinds: Array[String] = ["glade_tree", "willow_tree", "birch_tree", "pine_tree", "blossom_tree", "dead_tree"]
	var tree_images: Array = []
	for k in tree_kinds:
		tree_images.append(ProceduralArt.prop_texture(k, 0).get_image().get_data())
	var tree_distinct := 0
	for i in tree_images.size():
		var unique := true
		for j in i:
			if tree_images[i] == tree_images[j]:
				unique = false
		if unique:
			tree_distinct += 1
	check(tree_distinct >= 3, "at least 3 tree kinds produce distinct textures", str(tree_distinct))

	# clear_cache() MUST be last so it cannot disturb the assertions above.
	ProceduralArt.clear_cache()
	check(ProceduralArt.prop_texture("glade_tree", 0) != null, "prop_texture() regenerates after clear_cache()")
	check(ProceduralArt.character_frame(pal, 0, 0, 0) != null, "character_frame() regenerates after clear_cache()")


# ------------------------------------------ Phase 3: chunk visual quality
## ChunkBuilder.build() must return a deterministic, batched, capped chunk: one
## MultiMesh per layer, the detail layer parented to terrain, valid prop entries,
## and >=5 distinct prop kinds across the world.
func _test_chunk_visual_quality() -> void:
	var region: Dictionary = ContentDB.get_region("greenward")
	check(not region.is_empty(), "greenward region loads for chunk build")
	var scatter_kinds := {}
	for prop_kind in GreenwardStyle.prop_kinds():
		scatter_kinds[prop_kind] = true
	var scatter_rng_a := RandomNumberGenerator.new()
	scatter_rng_a.seed = 7319
	var scatter_rng_b := RandomNumberGenerator.new()
	scatter_rng_b.seed = 7319
	var scatter_a := ChunkPropScatter.resolve_prop("glade_tree", scatter_rng_a, scatter_kinds, 0.4, 0.1)
	var scatter_b := ChunkPropScatter.resolve_prop("glade_tree", scatter_rng_b, scatter_kinds, 0.4, 0.1)
	check(scatter_a == scatter_b, "ChunkPropScatter preserves seeded deterministic prop resolution")
	check(["pine_tree", "birch_tree", "willow_tree", "glade_tree"].has(str(scatter_a.get("kind", ""))), "highland tree scatter respects elevation-biased candidates")
	check(int(scatter_a.get("variant", -1)) >= 0 and int(scatter_a.get("variant", -1)) < GreenwardStyle.variant_count(str(scatter_a.get("kind", ""))), "prop scatter variant stays inside the selected kind's range")
	var scatter_entry := ChunkPropScatter.prop_entry("pine_tree", 2, Vector2(64, 96), 0.8, true, false)
	check(scatter_entry.get("type") == "pine_tree" and scatter_entry.get("position") == Vector2(64, 96) and bool(scatter_entry.get("flip")) and not bool(scatter_entry.get("detail")), "ChunkPropScatter emits the complete canonical prop record")
	var scatter_choice := ChunkPropScatter.choose_prop([{"type": "flower", "weight": 1.0}], 1.0, 0.0, scatter_rng_a)
	check(scatter_choice == "flower", "ChunkPropScatter weighted selection respects region prop definitions")
	# Boss territories must remain independent and far enough apart that their
	# biome influence fields cannot merge into one ambiguous arena.
	var extracted_boss_zones: Array = ChunkRegionLayoutResolver._boss_zones(region)
	check(extracted_boss_zones == ChunkBuilder._boss_zones(region), "ChunkRegionLayoutResolver preserves the legacy boss-zone layout")
	check(ChunkRegionLayoutResolver._path_segments(region) == ChunkBuilder._path_segments(region), "ChunkRegionLayoutResolver preserves deterministic authored routes")
	var boss_zones: Array = ChunkBuilder._boss_zones(region)
	check(boss_zones.size() == 2, "Greenward defines two distinct boss territories", str(boss_zones.size()))
	var elder_zone: Dictionary = {}
	var matron_zone: Dictionary = {}
	for zone in boss_zones:
		if str(zone.get("id", "")) == "elder":
			elder_zone = zone
		elif str(zone.get("id", "")) == "matron":
			matron_zone = zone
	check(not elder_zone.is_empty(), "Elder Hollow has its own terrain zone")
	check(not matron_zone.is_empty(), "Fallen Matron has its own terrain zone")
	if not elder_zone.is_empty() and not matron_zone.is_empty():
		var elder_center: Vector2 = elder_zone.get("center", Vector2.ZERO)
		var matron_center: Vector2 = matron_zone.get("center", Vector2.ZERO)
		var influence_gap := elder_center.distance_to(matron_center) - float(elder_zone.get("radius", 0.0)) - float(matron_zone.get("radius", 0.0))
		check(influence_gap > 0.0, "boss biome influence fields do not overlap", str(influence_gap))
		check(elder_zone.get("color") != matron_zone.get("color"), "boss territories use distinct biome palettes")
		# Navigation must classify the two boss areas independently inside the
		# same region, and must not confuse either with the village approach.
		var navigation := QuestNavigationResolver.new()
		var elder_world := IsoMath.grid_to_world(-88.0, 76.0)
		var matron_world := IsoMath.grid_to_world(116.0, 78.0)
		var village_world := IsoMath.grid_to_world(8.0, 8.0)
		check(navigation._territory_for("greenward", elder_world, {}) == "elder_hollow", "Elder Hollow resolves as its own navigation territory")
		check(navigation._territory_for("greenward", matron_world, {}) == "withered_estate", "Fallen Matron resolves as its own navigation territory")
		check(navigation._territory_for("greenward", village_world, {}).is_empty(), "Greenward village approach is outside both boss territories")
		check(QuestNavigationResolver._in_territory("greenward", elder_world, "elder_hollow"), "Elder Hollow territory membership is recognized")
		check(QuestNavigationTerritoryResolver.territory_for("greenward", elder_world, {}) == "elder_hollow", "Dedicated territory resolver classifies Elder Hollow")
		check(not QuestNavigationResolver._in_territory("greenward", elder_world, "withered_estate"), "Elder Hollow is not classified as the Matron territory")
	var seed := int(region.get("noise_seed", 1337))
	var elevation := FastNoiseLite.new()
	elevation.seed = seed
	var moisture := FastNoiseLite.new()
	moisture.seed = seed + 91
	var terrain_mat := ShaderMaterial.new()
	terrain_mat.shader = load("res://resources/shaders/terrain.gdshader")
	var water_mat := ShaderMaterial.new()
	water_mat.shader = load("res://resources/shaders/water.gdshader")
	check(terrain_mat.shader != null, "terrain.gdshader loads")
	check(water_mat.shader != null, "water.gdshader loads")

	var coords: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, -1)]
	var builds: Array = []
	for c in coords:
		builds.append(ChunkBuilder.build(c, region, elevation, moisture, terrain_mat, water_mat))
	var data0: Dictionary = builds[0]
	for k in ["coord", "terrain", "water", "props", "detail"]:
		check(data0.has(k), "chunk returns key: " + str(k))
	check(data0["coord"] == Vector2i(0, 0), "chunk echoes its coord")

	var terrain: MultiMeshInstance2D = data0["terrain"]
	check(terrain is MultiMeshInstance2D, "chunk terrain is a MultiMeshInstance2D")
	check(terrain.multimesh != null, "terrain has a MultiMesh")
	check(terrain.multimesh.instance_count == 256, "terrain batches a 16x16 grid (256 instances)", str(terrain.multimesh.instance_count))
	check(terrain.multimesh.use_colors == true, "terrain multimesh uses per-instance colors")
	check(terrain.multimesh.transform_format == MultiMesh.TRANSFORM_2D, "terrain multimesh uses TRANSFORM_2D")

	var water: Variant = data0["water"]
	check(water == null or water is MultiMeshInstance2D, "water is null or a MultiMeshInstance2D")
	var detail: Variant = data0["detail"]
	check(detail == null or detail is MultiMeshInstance2D, "detail is null or a MultiMeshInstance2D")
	if detail != null:
		var dn: MultiMeshInstance2D = detail
		check(dn.multimesh.instance_count >= 0, "detail instance_count is non-negative", str(dn.multimesh.instance_count))
		check(dn.get_parent() == terrain, "detail is parented to terrain (never re-parented)")

	var children_ok := true
	for child in terrain.get_children():
		if not (child is MultiMeshInstance2D):
			children_ok = false
	check(terrain.get_child_count() <= 2, "terrain has few children (one draw call per layer)", str(terrain.get_child_count()))
	check(children_ok, "every terrain child is a MultiMeshInstance2D (no per-tile Sprite2D)")

	var valid_kinds := {}
	for k in ProceduralArt.prop_kinds():
		valid_kinds[k] = true
	var all_props: Array = []
	var type_union := {}
	var props_cap_ok := true
	var props_positive := false
	for b in builds:
		var bprops: Array = b["props"]
		if bprops.size() > 0:
			props_positive = true
		if bprops.size() > GreenwardStyle.MAX_PROPS_PER_CHUNK:
			props_cap_ok = false
		for p in bprops:
			all_props.append(p)
			type_union[str(p.get("type", ""))] = true
	check(props_positive, "at least one forest chunk spawns props")
	check(props_cap_ok, "every chunk respects MAX_PROPS_PER_CHUNK", str(GreenwardStyle.MAX_PROPS_PER_CHUNK))
	check(all_props.size() > 0, "a sample of props was collected across coords")
	var type_ok := true
	var variant_ok := true
	var position_ok := true
	var scale_ok := true
	var flip_ok := true
	for p in all_props:
		var t := str(p.get("type", ""))
		if not valid_kinds.has(t):
			type_ok = false
		var v := int(p.get("variant", -1))
		if not (v >= 0 and v < ProceduralArt.variant_count(t)):
			variant_ok = false
		if typeof(p.get("position")) != TYPE_VECTOR2:
			position_ok = false
		if not (float(p.get("scale", 0.0)) > 0.0):
			scale_ok = false
		if typeof(p.get("flip")) != TYPE_BOOL:
			flip_ok = false
	check(type_ok, "every prop.type is a valid GreenwardStyle prop kind")
	check(variant_ok, "every prop.variant is in [0, variant_count(type))")
	check(position_ok, "every prop.position is a Vector2")
	check(scale_ok, "every prop.scale is positive")
	check(flip_ok, "every prop.flip is a bool")
	check(type_union.size() >= 5, "prop types across coords contain >=5 distinct kinds", str(type_union.size()))

	var data0b := ChunkBuilder.build(Vector2i(0, 0), region, elevation, moisture, terrain_mat, water_mat)
	var p1: Array = data0["props"]
	var p2: Array = data0b["props"]
	check(p1.size() == p2.size(), "rebuild yields the same prop count", "%d/%d" % [p1.size(), p2.size()])
	var fields_det := true
	var n := mini(p1.size(), p2.size())
	for i in n:
		var pa: Dictionary = p1[i]
		var pb: Dictionary = p2[i]
		var same_type: bool = bool(pa.get("type") == pb.get("type"))
		var same_pos: bool = bool(pa.get("position") == pb.get("position"))
		var same_scale: bool = near(float(pa.get("scale")), float(pb.get("scale")))
		var same_flip: bool = bool(pa.get("flip") == pb.get("flip"))
		var same_variant: bool = bool(pa.get("variant") == pb.get("variant"))
		if not (same_type and same_pos and same_scale and same_flip and same_variant):
			fields_det = false
	check(fields_det, "rebuild prop type/position/scale/flip/variant are identical")
	var colors_det := true
	var mm1: MultiMesh = (data0["terrain"] as MultiMeshInstance2D).multimesh
	var mm2: MultiMesh = (data0b["terrain"] as MultiMeshInstance2D).multimesh
	for raw in [0, 1, 7, 63, 127, 200, 255]:
		var idx := int(raw)
		var col1 := mm1.get_instance_color(idx)
		var col2 := mm2.get_instance_color(idx)
		if not (near(col1.r, col2.r) and near(col1.g, col2.g) and near(col1.b, col2.b) and near(col1.a, col2.a)):
			colors_det = false
	check(colors_det, "rebuild terrain instance colors are identical for sampled indices")

	for b in builds:
		_phase3_free_chunk(b)
	_phase3_free_chunk(data0b)


# --------------------------------------------- Phase 3: weather director
## WeatherDirector is a pure, seeded state machine. Covers its four states,
## params() contract, intensity bounds, determinism and reset().
func _test_weather_director() -> void:
	check(WeatherDirector.ALL_STATES.size() == 4, "weather has 4 states")
	check(WeatherDirector.ALL_STATES.has(WeatherDirector.CLEAR) and WeatherDirector.ALL_STATES.has(WeatherDirector.MIST) and WeatherDirector.ALL_STATES.has(WeatherDirector.RAIN) and WeatherDirector.ALL_STATES.has(WeatherDirector.POLLEN_BLOOM), "ALL_STATES covers CLEAR/MIST/RAIN/POLLEN_BLOOM")
	var names_ok := true
	for raw in WeatherDirector.ALL_STATES:
		if WeatherDirector.state_name(int(raw)).is_empty():
			names_ok = false
	check(names_ok, "state_name() is non-empty for all weather states")
	check(WeatherDirector.state_name(WeatherDirector.RAIN) == "rain", "RAIN state_name is 'rain'")
	check(WeatherDirector.is_valid_state(WeatherDirector.RAIN), "is_valid_state accepts RAIN")
	check(not WeatherDirector.is_valid_state(-1) and not WeatherDirector.is_valid_state(99), "is_valid_state rejects -1 and 99")

	var w := WeatherDirector.new(4242)
	w.set_state(WeatherDirector.RAIN)
	check(w.current_state == WeatherDirector.RAIN, "set_state(RAIN) sets current_state")
	var tick_ok := true
	var inten_ok := true
	for i in 30:
		var r = w.tick(0.5)
		if typeof(r) != TYPE_BOOL:
			tick_ok = false
		if w.intensity < 0.0 or w.intensity > 1.0:
			inten_ok = false
	check(tick_ok, "tick() returns a bool")
	check(inten_ok, "intensity stays in [0,1]")

	w.set_state(WeatherDirector.RAIN)
	w.tick(0.5)
	w.tick(0.5)
	var p: Dictionary = w.params()
	var required_keys: Array[String] = ["state", "state_name", "intensity", "fog_density", "fog_color", "particle_scale", "rain_amount", "pollen_amount", "wind_boost", "tint", "mobile", "particle_cap", "performance_tier"]
	var keys_present := true
	for k in required_keys:
		if not p.has(k):
			keys_present = false
	check(keys_present, "params() exposes all documented keys")
	check(p.get("state") == WeatherDirector.RAIN, "params().state reflects current_state")
	check(typeof(p.get("fog_color")) == TYPE_COLOR, "params().fog_color is a Color")
	check(typeof(p.get("tint")) == TYPE_COLOR, "params().tint is a Color")
	var numeric_ok := true
	for nk in ["intensity", "fog_density", "particle_scale", "rain_amount", "pollen_amount", "wind_boost"]:
		var nv: float = float(p[nk])
		if is_nan(nv) or is_inf(nv) or nv < 0.0:
			numeric_ok = false
	check(numeric_ok, "params() numeric values are finite and non-negative")
	check(int(p["particle_cap"]) <= GreenwardStyle.MAX_PARTICLES, "params().particle_cap <= MAX_PARTICLES", str(p["particle_cap"]))
	check(int(p["rain_amount"]) <= int(p["particle_cap"]), "params().rain_amount <= particle_cap", "%d/%d" % [int(p["rain_amount"]), int(p["particle_cap"])])

	var w1 := WeatherDirector.new(777)
	var w2 := WeatherDirector.new(777)
	for i in 120:
		w1.tick(0.4)
		w2.tick(0.4)
	check(w1.current_state == w2.current_state, "two same-seed WeatherDirectors converge on current_state")
	check(near(w1.intensity, w2.intensity), "two same-seed WeatherDirectors converge on intensity")

	w1.reset()
	check(w1.current_state == WeatherDirector.CLEAR, "reset() restores CLEAR")
	check(near(w1.intensity, 0.0), "reset() restores intensity 0")
	w1.set_state(WeatherDirector.MIST)
	w1.set_state(99)
	check(w1.current_state == WeatherDirector.MIST, "invalid set_state() leaves state unchanged (no crash)")

	var weather_component := WorldWeatherComponent.new()
	var managed_weather := weather_component.configure({
		"noise_seed": 321,
		"environment": {"weather_bias": ["mist"]},
	})
	check(managed_weather.seed_value == 826, "world weather component applies the deterministic region seed offset")
	check(managed_weather.current_state == WeatherDirector.MIST, "world weather component applies the region weather bias")
	check(weather_component.params().get("state") == WeatherDirector.MIST, "world weather component exposes director parameters")
	check(not weather_component.tick(0.25), "world weather component advances weather without forcing a transition")
	weather_component.free()

	var follow_component := WorldEffectFollowComponent.new()
	var follow_ambient := Node2D.new()
	var follow_fireflies := Node2D.new()
	var follow_rain := Node2D.new()
	var follow_fog := Node2D.new()
	follow_component.configure(follow_ambient, follow_fireflies, follow_rain, follow_fog)
	follow_component.follow_player(Vector2(640.0, 320.0))
	check(follow_ambient.global_position == Vector2(640.0, 320.0) and follow_fireflies.global_position == Vector2(640.0, 320.0), "world effect follower centers ambient particles and fireflies on the player")
	check(follow_rain.global_position == Vector2(640.0, -100.0), "world effect follower preserves the rain's upward camera offset")
	check(follow_fog.global_position == Vector2(640.0, 320.0), "world effect follower centers fog on the player")
	follow_component.free()
	follow_ambient.free()
	follow_fireflies.free()
	follow_rain.free()
	follow_fog.free()

	var fog_component := WorldFogComponent.new()
	fog_component.configure(Vector2(4.0, 8.0), Vector2(2600.0, 1700.0), Color(0.8, 0.88, 0.95), 0.08, true)
	check(fog_component.quad != null and fog_component.fog_material != null, "world fog component owns its shader material and fog quad")
	check(fog_component.quad.z_index == 20 and fog_component.quad.scale == Vector2(1300.0, 850.0), "world fog component preserves the world-space quad dimensions and draw order")
	check(fog_component.quad.position == Vector2(4.0, 8.0) and fog_component.quad.visible, "world fog component applies its initial position and visibility")
	fog_component.apply_appearance(Color(0.2, 0.3, 0.4), 0.35)
	check(is_equal_approx(float(fog_component.fog_material.get_shader_parameter("density")), 0.35), "world fog component updates shader density")
	check(fog_component.fog_material.get_shader_parameter("fog_color") == Color(0.2, 0.3, 0.4, 1.0), "world fog component applies opaque fog colour")
	fog_component.apply_appearance(Color.WHITE, 0.9)
	check(is_equal_approx(float(fog_component.fog_material.get_shader_parameter("density")), 0.6), "world fog component clamps density to its safe upper bound")
	fog_component.free()

	var particle_root := Node2D.new()
	var pollen_emitter := CPUParticles2D.new()
	pollen_emitter.name = "PollenMotes"
	particle_root.add_child(pollen_emitter)
	var firefly_emitter := CPUParticles2D.new()
	firefly_emitter.name = "Fireflies"
	particle_root.add_child(firefly_emitter)
	var rain_emitter := CPUParticles2D.new()
	rain_emitter.name = "Rain"
	particle_root.add_child(rain_emitter)
	var ambient_component := WorldAmbientEffectsComponent.new()
	ambient_component.configure(particle_root, true)
	check(pollen_emitter.texture != null and firefly_emitter.texture != null and rain_emitter.texture != null, "ambient effects component configures all three particle textures")
	check(firefly_emitter.emitting and not rain_emitter.emitting, "ambient effects component initializes night fireflies and keeps rain disabled")
	ambient_component.apply_atmosphere(
		{"fireflies": true},
		{"particle_scale": 1.0, "tint": Color(0.5, 0.6, 0.7), "rain_amount": 7},
		false, 100, Color.WHITE, Color.WHITE, false, Color.WHITE
	)
	check(pollen_emitter.amount == 4 and pollen_emitter.emitting, "ambient effects component scales pollen during firefly phases")
	check(firefly_emitter.amount == 6 and firefly_emitter.emitting, "ambient effects component caps firefly density from the phase")
	check(rain_emitter.amount == 7 and rain_emitter.emitting, "ambient effects component applies weather rain amount")
	ambient_component.apply_atmosphere(
		{"fireflies": true}, {"particle_scale": 1.0, "rain_amount": 7},
		true, 100, Color.WHITE, Color.WHITE, false, Color.WHITE
	)
	check(pollen_emitter.amount == 2 and firefly_emitter.amount == 3, "ambient effects component halves ambient particles on mobile")
	check(not rain_emitter.emitting, "ambient effects component disables rain on mobile")
	ambient_component.free()
	particle_root.free()

	var light_root := Node2D.new()
	var lighting_component := WorldLightingComponent.new()
	light_root.add_child(lighting_component)
	lighting_component.configure(light_root, 2)
	var lamp_color := Color(1.0, 0.72, 0.38)
	check(lighting_component.add_light(Vector2(3.0, 4.0), lamp_color, 1.4, 2.0), "localized lighting component creates a point light")
	check(lighting_component.lights.size() == 1, "localized lighting component tracks its managed light")
	var managed_lamp: PointLight2D = lighting_component.lights[0].light
	check(managed_lamp.get_parent() == light_root and managed_lamp.position == IsoMath.grid_to_world(3.0, 4.0) + Vector2(0, -36), "localized lighting component preserves the entity parent and grid offset")
	check(managed_lamp.texture != null and managed_lamp.blend_mode == Light2D.BLEND_MODE_ADD and is_equal_approx(managed_lamp.energy, 1.4), "localized lighting component preserves glow texture, additive blend and base energy")
	lighting_component.apply_atmosphere(1.0, Color.WHITE, Color.WHITE, Color.WHITE)
	check(is_equal_approx(managed_lamp.energy, 1.75), "localized lighting component scales light energy from the day/night phase")
	check(managed_lamp.color == lamp_color.lerp(Color.WHITE, 0.10).lerp(Color.WHITE, 0.06).lerp(Color.WHITE, 0.05), "localized lighting component applies the phase, environment and zone tint blend")
	check(lighting_component.add_light(Vector2.ZERO, Color.WHITE, 1.0, 1.0), "localized lighting component accepts lights up to its configured cap")
	check(not lighting_component.add_light(Vector2.ONE, Color.WHITE, 1.0, 1.0) and lighting_component.lights.size() == 2, "localized lighting component enforces its light cap")
	light_root.free()

	var presentation_config := EnvironmentPresentationConfig.new()
	presentation_config.day_night_enabled = false
	presentation_config.ambient_particles_enabled = false
	presentation_config.weather_enabled = false
	presentation_config.fog_enabled = false
	presentation_config.water_presentation_enabled = false
	presentation_config.localized_lights_enabled = false
	presentation_config.environmental_sound_enabled = false
	presentation_config.fog_density_scale = 2.0
	presentation_config.ambient_tint = Color(0.7, 0.8, 0.9)
	presentation_config.weather_bias = ["rain"]
	var config_day_night := DayNight.new()
	var config_effect_root := Node2D.new()
	var config_pollen := CPUParticles2D.new()
	config_pollen.name = "PollenMotes"
	config_effect_root.add_child(config_pollen)
	var config_fireflies := CPUParticles2D.new()
	config_fireflies.name = "Fireflies"
	config_effect_root.add_child(config_fireflies)
	var config_rain := CPUParticles2D.new()
	config_rain.name = "Rain"
	config_effect_root.add_child(config_rain)
	var config_ambient := WorldAmbientEffectsComponent.new()
	config_ambient.configure(config_effect_root, true)
	var config_fog := WorldFogComponent.new()
	config_fog.configure(Vector2.ZERO, Vector2(100.0, 100.0), Color.WHITE, 0.1, true)
	var config_lights_root := Node2D.new()
	var config_lighting := WorldLightingComponent.new()
	config_lights_root.add_child(config_lighting)
	config_lighting.configure(config_lights_root, 2)
	config_lighting.add_light(Vector2.ZERO, Color.WHITE, 1.0, 1.0)
	var config_water_root := Node2D.new()
	var config_sound_root := Node2D.new()
	var presentation_component := WorldPresentationConfigComponent.new()
	check(presentation_component.configure(presentation_config, config_day_night, config_ambient, config_fog, config_lighting, config_water_root, config_sound_root), "world presentation config component accepts the authored resource")
	check(not config_day_night.is_processing(), "world presentation config can disable the day/night cycle")
	check(not config_pollen.visible and not config_fireflies.visible and not config_rain.visible and not config_rain.emitting, "world presentation config gates ambient particles and weather visuals")
	check(not config_fog.quad.visible, "world presentation config can disable fog presentation")
	config_fog.apply_appearance(Color.WHITE, 0.2)
	check(is_equal_approx(float(config_fog.fog_material.get_shader_parameter("density")), 0.4), "world presentation config scales fog density")
	check(not (config_lighting.lights[0].light as PointLight2D).visible, "world presentation config can disable localized lights")
	check(not config_water_root.visible and not config_sound_root.visible, "world presentation config gates water and environmental sound roots")
	var config_weather := WorldWeatherComponent.new()
	check(config_weather.configure({"noise_seed": 10, "environment": {"weather_bias": ["mist"]}}, presentation_config.weather_bias).current_state == WeatherDirector.RAIN, "presentation config weather bias overrides the region default")
	config_day_night.free()
	config_effect_root.free()
	config_ambient.free()
	config_fog.free()
	config_lights_root.free()
	config_sound_root.free()
	config_water_root.free()
	presentation_component.free()
	config_weather.free()

	var bridge_navigation := WorldNavigationComponent.new()
	var water_bridge_component := WorldWaterBridgeComponent.new()
	water_bridge_component.configure(bridge_navigation)
	var water_surface := MultiMeshInstance2D.new()
	check(water_bridge_component.attach_water_surface(water_surface), "water/bridge component accepts a streamed water surface")
	check(water_surface.get_parent() == water_bridge_component and water_surface.z_index == -1, "water/bridge component parents water on its dedicated layer with preserved relative depth")
	water_bridge_component.register_bridge(Vector2(2.0, 5.0))
	check(bridge_navigation.get_bridge_positions().size() == 1 and bridge_navigation.get_bridge_positions()[0] == IsoMath.grid_to_world(2.0, 5.0), "water/bridge component delegates bridge traversal registration to navigation")
	water_bridge_component.set_water_enabled(false)
	check(not water_bridge_component.visible, "water/bridge component gates its presentation root")
	water_bridge_component.free()
	bridge_navigation.free()


# ------------------------------- Phase 3: animated & interactive props
## AnimatedProp/InteractiveProp are headless-safe Node2D wrappers. They build a
## Sprite2D, gate visibility/processing, emit activated on interact and NEVER
## mutate GameState.
func _test_animated_and_interactive_props() -> void:
	var ap := AnimatedProp.new()
	ap.setup("waterfall", Vector2.ZERO, 1.0, false, AnimatedProp.MOTION_FLICKER, 0)
	add_child(ap)
	await get_tree().process_frame
	check(ap.is_inside_tree(), "AnimatedProp enters the tree")
	var sprite_ok := false
	for child in ap.get_children():
		if child is Sprite2D and (child as Sprite2D).texture != null:
			sprite_ok = true
	check(sprite_ok, "AnimatedProp has a Sprite2D child with a non-null texture")
	var motions: Array[int] = [AnimatedProp.MOTION_NONE, AnimatedProp.MOTION_BOB, AnimatedProp.MOTION_SWAY, AnimatedProp.MOTION_PULSE, AnimatedProp.MOTION_FLICKER, AnimatedProp.MOTION_DRIFT]
	var motion_names_ok := true
	for m in motions:
		if AnimatedProp.motion_name(m).is_empty():
			motion_names_ok = false
	check(motion_names_ok, "motion_name() is non-empty for all motions")
	ap.set_active(false)
	check(ap.visible == false, "set_active(false) hides the prop")
	check(ap.is_processing() == false, "set_active(false) stops processing")
	ap.set_active(true)
	check(ap.visible == true, "set_active(true) restores visibility")
	check(ap.is_processing() == true, "set_active(true) restores processing")
	ap.queue_free()
	await get_tree().process_frame

	var ip := InteractiveProp.new()
	ip.setup("rune_stone", Vector2.ZERO, "Test Rune", "lore", 0)
	add_child(ip)
	await get_tree().process_frame
	check(ip.can_interact() == true, "InteractiveProp.can_interact() is true")
	check(not ip.prompt.is_empty(), "InteractiveProp.prompt is non-empty", ip.prompt)
	check(ip.interaction_radius > 0.0, "InteractiveProp.interaction_radius > 0", str(ip.interaction_radius))
	check(ip.is_in_group("interactables"), "InteractiveProp is in the 'interactables' group")
	_phase3_activated_count = 0
	ip.activated.connect(_phase3_on_activated)
	var before_state: Variant = GameState._to_dict().duplicate(true)
	ip.interact()
	var after_state: Variant = GameState._to_dict().duplicate(true)
	check(_phase3_activated_count == 1, "interact() emits activated exactly once", str(_phase3_activated_count))
	check(before_state == after_state, "interact() does not mutate GameState")
	ip.queue_free()
	await get_tree().process_frame


## Proximity alone must never launch an encounter; the player must explicitly
## interact with the nearby roaming monster.
func _test_roaming_monster_manual_encounter() -> void:
	var player_probe := CharacterBody2D.new()
	player_probe.name = "ManualEncounterPlayerProbe"
	player_probe.add_to_group("player")
	add_child(player_probe)
	var monster_scene := load("res://scenes/world/roaming_monster.tscn") as PackedScene
	check(monster_scene != null, "RoamingMonster composition scene loads")
	if monster_scene == null:
		player_probe.queue_free()
		return
	var monster := monster_scene.instantiate() as RoamingMonster
	monster.name = "ManualEncounterMonsterProbe"
	monster.setup("glade_mossling_pack", Vector2.ZERO, ContentDB.get_enemy("mossling"), false)
	add_child(monster)
	_roaming_encounter_count = 0
	if not EventBus.encounter_requested.is_connected(_on_test_roaming_encounter):
		EventBus.encounter_requested.connect(_on_test_roaming_encounter)
	await get_tree().process_frame
	check(monster.movement_component is EnemyMovement, "RoamingMonster delegates passive roaming to its EnemyMovement component")
	check(monster.roaming_behavior is EnemyRoamingBehavior, "RoamingMonster delegates its passive frame loop to an authored EnemyRoamingBehavior node")
	check(monster.enemy_controller is EnemyController and monster.enemy_controller.state_machine == monster.state_machine, "RoamingMonster binds its state machine through EnemyController")
	monster._set_enemy_state(&"idle")
	check(monster.state_machine.current_state_name == &"idle", "RoamingMonster routes state changes through EnemyController")
	check(monster.enemy_visual_component is EnemyVisualComponent and (monster.enemy_visual_component.get_parent() == monster or monster.enemy_visual_component.get_parent() == monster.get_node_or_null("Components")), "RoamingMonster delegates palette variation, silhouette, nameplate and accent setup to its EnemyVisual component")
	check(monster.get_node_or_null("ActorVisual") is ActorVisual and monster.get_node_or_null("NameLabel") is Label and monster.get_node_or_null("Accent") is Sprite2D, "RoamingMonster binds its authored actor, nameplate and accent scenes")
	monster._process(0.016)
	var status_probe := EnemyStatusEffects.new()
	monster.add_child(status_probe)
	monster.status_component = status_probe
	status_probe.apply_status("tick_probe", 1.0)
	monster._process(0.1)
	check(near(float(status_probe.statuses["tick_probe"].duration), 0.9), "RoamingMonster ticks enemy status effects exactly once per frame")
	check(not monster.engaged, "Roaming monster stays passive when player is nearby")
	check(_roaming_encounter_count == 0, "Proximity does not emit encounter_requested")
	check(monster.can_interact(), "Nearby roaming monster remains interactable")
	monster.interact()
	check(monster.engaged, "Explicit monster interaction marks encounter engaged")
	check(_roaming_encounter_count == 1, "Explicit monster interaction emits exactly one encounter request", str(_roaming_encounter_count))
	var boss := monster_scene.instantiate() as RoamingMonster
	boss.name = "StationaryBossArenaProbe"
	boss.setup("elder_hollow", Vector2(520.0, 0.0), ContentDB.get_enemy("elder_hollow"), true)
	add_child(boss)
	await get_tree().process_frame
	var boss_home := boss.home_position
	var previous_baltoria_quest: Dictionary = GameState.quest_domain.quests.get("baltoria_summoning", {}).duplicate(true)
	boss.required_quest = "baltoria_summoning"
	boss.required_quest_step = 1
	GameState.quest_domain.quests.erase("baltoria_summoning")
	check(not boss.can_interact(), "Baltoria remains sealed before its summoning quest is started")
	GameState.quest_domain.quests["baltoria_summoning"] = {"state": "active", "step": 0, "progress": 0}
	check(not boss.can_interact(), "Baltoria remains sealed while the player is speaking to the gatekeeper")
	GameState.quest_domain.quests["baltoria_summoning"] = {"state": "active", "step": 1, "progress": 0}
	check(boss.can_interact(), "Baltoria unlocks only when the active quest reaches the defeat objective")
	var boss_position_probe := player_probe.position
	player_probe.position = boss_home
	boss.position = boss_home
	boss.interact()
	check(boss.engaged, "Unlocked Baltoria starts only through explicit arena interaction")
	check(_roaming_encounter_count == 2, "Unlocked Baltoria emits one encounter request", str(_roaming_encounter_count))
	boss.engaged = false
	boss.position = boss_home + Vector2(90.0, 0.0)
	player_probe.position = boss_position_probe
	if previous_baltoria_quest.is_empty():
		GameState.quest_domain.quests.erase("baltoria_summoning")
	else:
		GameState.quest_domain.quests["baltoria_summoning"] = previous_baltoria_quest
	boss.position = boss_home + Vector2(90.0, 0.0)
	boss._process(0.016)
	check(boss.position.distance_to(boss_home) < 0.5, "Boss encounter remains anchored to its authored arena position")
	check(boss.global_position.distance_to(player_probe.global_position) > boss.interaction_radius, "Boss is outside the player's interaction radius before entering its arena")
	boss.position = boss_home
	player_probe.position = boss_home
	check(boss.global_position.distance_to(player_probe.global_position) <= boss.interaction_radius, "Boss enters interaction range only when the player reaches its arena")
	if EventBus.encounter_requested.is_connected(_on_test_roaming_encounter):
		EventBus.encounter_requested.disconnect(_on_test_roaming_encounter)
	monster.queue_free()
	boss.queue_free()
	player_probe.queue_free()
	await get_tree().process_frame


# ------------------------------- Phase 3: assembled world integration
## Instantiate the real game.tscn and verify the world wires up weather,
## day/night, streamed MultiMesh chunks and the player's temporary animation
## pipeline, then drive the actor visual without crashing.
func _test_world_visual_integration() -> void:
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	check(game_scene != null, "game.tscn loads for visual integration")
	if game_scene == null:
		return
	var game := game_scene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	check(game.world != null, "assembled scene creates a world")
	check(game.world.player != null, "assembled world creates a player")
	check(game.hud != null, "assembled scene creates a HUD (GameScreen.hud)")
	var portrait_party := game.hud.get_node_or_null("PartyPanel") as Control
	var portrait_hint := game.hud.get_node_or_null("HintLabel") as Control
	game.hud._apply_responsive_layout(Vector2(390, 844))
	check(portrait_party != null and not portrait_party.visible, "portrait HUD hides the overlapping party panel")
	check(portrait_hint != null and not portrait_hint.visible, "portrait HUD hides desktop keyboard hint")
	check(game.hud._minimap != null and is_equal_approx(game.hud._minimap.offset_left, -188.0) and is_equal_approx(game.hud._minimap.offset_right, -18.0), "portrait HUD compacts minimap to 170px")
	check(game.hud._minimap != null and game.hud._minimap.marker_component is MinimapMarkerComponent and game.hud._minimap.marker_component.get_parent() == game.hud._minimap, "Minimap owns an authored marker-data component")
	if game.hud._minimap != null and game.hud._minimap.marker_component != null:
		game.hud._minimap._find_world()
		game.hud._minimap._update_markers()
		check(game.hud._minimap.marker_component.active_world == game.world, "Minimap marker component binds the active world before collecting markers")
	var portrait_prompt := game.hud.get_node_or_null("PromptCenter") as Control
	check(portrait_prompt != null and is_equal_approx(portrait_prompt.offset_top, -523.28) and is_equal_approx(portrait_prompt.offset_bottom, -455.76), "portrait HUD moves interaction prompt above touch controls")
	game.hud._apply_responsive_layout(Vector2(1280, 720))
	check(portrait_party != null and portrait_party.visible, "landscape HUD restores party panel")
	check(game.hud._minimap != null and is_equal_approx(game.hud._minimap.offset_left, -244.0) and is_equal_approx(game.hud._minimap.offset_right, -20.0), "landscape HUD restores full-size minimap")
	check(game.world.current_area_name() != "", "world reports a non-empty area name", str(game.world.current_area_name()))
	check(game.world.weather is WeatherDirector, "world wires a WeatherDirector")
	check(game.world.day_night is DayNight, "world wires a DayNight")
	check(game.world.npcs.size() >= 3 and game.world.npcs.all(func(npc): return npc is WorldNPC and npc.get_parent() == game.world.entities), "entity spawner creates and registers all three Greenward NPCs under the entities layer")
	check(game.world.npcs.all(func(npc): return npc.get_node_or_null("ActorVisual") is ActorVisual and npc.get_node_or_null("NameLabel") is Label and npc.get_node_or_null("SubtitleLabel") is Label and npc.get_node_or_null("InteractionRing") != null and npc.get_node_or_null("QuestMarker") != null), "all world NPCs own their complete authored presentation hierarchy")
	check(game.world.chunk_streaming_component is WorldChunkStreamingComponent, "assembled world wires its chunk streaming component")
	check(game.world.chunk_streaming_component.get_parent() == game.world, "chunk streaming component is owned by the world")
	check(game.world.chunk_lifecycle_component is WorldChunkLifecycleComponent, "assembled world wires its chunk lifecycle component")
	check(game.world.chunk_lifecycle_component.get_parent() == game.world and game.world.chunk_lifecycle_component.world == game.world, "chunk lifecycle component is owned and configured by the world")
	check(game.world.region_builder_component is WorldRegionBuilderComponent, "assembled world wires its data-driven region builder")
	check(game.world.region_builder_component.get_parent() == game.world and game.world.region_builder_component.world == game.world, "region builder component is owned and configured by the world")
	check(game.world.greenward_builder_component is WorldGreenwardBuilderComponent, "assembled world wires its Greenward composition builder")
	check(game.world.greenward_builder_component.get_parent() == game.world and game.world.greenward_builder_component.world == game.world, "Greenward builder component is owned and configured by the world")
	check(game.world.streamer == game.world.chunk_streaming_component.streamer and game.world._preparer == game.world.chunk_streaming_component.preparer, "world streaming compatibility references alias the component services")
	check(game.world._prepared_nodes == game.world.chunk_streaming_component.prepared_nodes, "world prepared-node tracking aliases the component cache")
	check(game.world.water_and_bridges is WorldWaterBridgeComponent, "assembled world wires its water/bridge presentation component")
	check(game.world.water_and_bridges.navigation == game.world.navigation_component, "water/bridge component shares the world navigation owner")
	check(game.world.lighting_component is WorldLightingComponent, "assembled world wires its localized lighting component")
	check(game.world.lighting_component.get_parent() == game.world, "assembled world owns its localized lighting component")
	check(game.world.region_context_component is WorldRegionContextComponent and game.world.region_context_component.world == game.world and game.world.region_context_component.get_parent() == game.world, "world region-context component is owned and configured")
	check(game.world.day_night_presentation_component is WorldDayNightPresentationComponent and game.world.day_night_presentation_component.world == game.world and game.world.day_night_presentation_component.get_parent() == game.world, "world day/night presentation component is owned and configured")
	check(game.world.atmosphere_component is WorldAtmosphereComponent and game.world.atmosphere_component.world == game.world and game.world.atmosphere_component.get_parent() == game.world, "world atmosphere component is owned and configured")
	check(game.world.prop_factory_component is WorldPropFactoryComponent and game.world.prop_factory_component.world == game.world and game.world.prop_factory_component.get_parent() == game.world, "world prop factory component is owned and configured")
	check(game.world.visual_standards_component is WorldVisualStandardsComponent and game.world.visual_standards_component.world == game.world and game.world.visual_standards_component.get_parent() == game.world, "world visual-standards component is owned and configured")
	check(game.world.day_night.phase_changed.is_connected(game.world.day_night_presentation_component._on_phase_changed), "day/night phase signal is routed directly to its presentation component")
	check(game.world.day_phase() == game.world.day_night.phase_at(game.world.day_night.time_of_day), "day/night facade delegates phase resolution to its component")
	check(game.world._environment() == game.world.region_context_component.environment() and not game.world._environment().is_empty(), "world environment facade delegates to region context")
	check(game.world.current_area_name() == game.world.region_context_component.current_area_name(), "world area-name facade delegates to region context")
	check(game.world._lights == game.world.lighting_component.lights, "assembled world retains a live light-array compatibility alias")
	var chunks: Dictionary = game.world.loaded_chunks
	check(chunks.size() > 0, "world has loaded chunks", str(chunks.size()))
	if chunks.size() > 0:
		var first: Dictionary = chunks.values()[0]
		check(first.get("terrain") is MultiMeshInstance2D, "first loaded chunk's terrain is a MultiMeshInstance2D")
		check(first.get("terrain").get_parent() == game.world.terrain_layer, "chunk lifecycle component parents materialized terrain into the world terrain layer")
	var pv: ActorVisual = game.world.player.visual
	check(pv != null, "player exposes an ActorVisual")
	check(pv.animator != null, "player visual has an animator")
	check(pv.frame_source != null, "player visual has a frame source")
	check(pv.using_temporary_art == false, "Kael player visual uses registered playable art")
	var kael_art_report: Dictionary = pv.character_art_report()
	check(kael_art_report.get("has_frames", false) == true, "Kael playable sprite sheet has frames")
	check(kael_art_report.get("animation_count", 0) == 72, "Kael playable sprite sheet exposes all 72 animations")
	pv.play(CharacterAnimator.State.ATTACK)
	pv.set_move_direction(Vector2(1, 0))
	check(pv.animator.state == CharacterAnimator.State.ATTACK, "visual.play(ATTACK) updates the animator state")
	check(pv.animator.direction == CharacterAnimator.Direction.RIGHT, "visual.set_move_direction((1,0)) sets RIGHT")
	var report: Dictionary = game.world.visual_style_report()
	check(not report.is_empty(), "visual_style_report() returns a non-empty Dictionary")
	var reported_player_art: Dictionary = report.get("character_art", {})
	check(reported_player_art.get("using_temporary_art", true) == false, "World visual report reflects Kael's final playable art")
	check(reported_player_art.get("animation_count", 0) == 72, "World visual report exposes all 72 Kael animations")

	# Exercise the actual GameScreen input route, not only monster.interact().
	# A nearby monster must remain passive until an explicit interact action.
	var encounter_probe := load("res://scenes/world/roaming_monster.tscn").instantiate() as RoamingMonster
	encounter_probe.name = "GameScreenManualEncounterProbe"
	encounter_probe.setup("glade_mossling_pack", Vector2.ZERO, ContentDB.get_enemy("mossling"), false)
	game.world.add_child(encounter_probe)
	encounter_probe.global_position = game.world.player.global_position
	await get_tree().process_frame
	game.world.player._scan_for_interactable()
	check(encounter_probe.can_interact(), "assembled world exposes nearby monster as interactable")
	check(not encounter_probe.engaged and game.active_combat == null, "assembled world does not start combat from proximity")
	var previous_touch_mode := TouchInput.using_touch
	TouchInput.using_touch = true
	game.hud._process(0.13)
	check(game.hud._touch_interact != null and game.hud._touch_interact.visible, "mobile HUD reveals Interact button for a nearby monster")
	TouchInput.using_touch = previous_touch_mode
	var interact_event := InputEventAction.new()
	interact_event.action = "interact"
	interact_event.pressed = true
	game._unhandled_input(interact_event)
	check(encounter_probe.engaged, "GameScreen interact action engages the nearby monster")
	check(game.active_combat != null, "GameScreen interact action opens the real combat screen")
	if game.active_combat != null:
		check(game.active_combat.group_id == "glade_mossling_pack", "manual interaction opens the matching enemy group")
		check(game.active_combat.engine != null and game.active_combat.engine.combatants.size() >= 4, "main-game encounter route creates both combat teams")
		check(game.active_combat._battlefield != null, "main-game encounter route mounts the authored battlefield")
		check(game.active_combat._battlefield != null and game.active_combat._battlefield.actors().size() >= 4, "main-game encounter route presents all combatants on the battlefield")
		check(game.active_combat._hud_component != null and game.active_combat._skills_box != null, "main-game encounter route builds the combat action HUD")
		check(game.active_combat._turn_order_component != null and game.active_combat._turn_box != null, "main-game encounter route builds the turn-order display")
		var routed_report: Dictionary = game.active_combat.presentation_report()
		check(routed_report.get("screen", "") == "combat" and routed_report.get("battlefield_report", {}).get("actors", 0) >= 4, "main-game combat presentation report confirms live battlefield actors")
	game.queue_free()
	await get_tree().process_frame

	# Exercise the authored mobile button's pressed signal through the real
	# GameScreen connection in a fresh scene, independently of keyboard input.
	var touch_game := game_scene.instantiate()
	add_child(touch_game)
	await get_tree().process_frame
	await get_tree().process_frame
	var touch_probe := load("res://scenes/world/roaming_monster.tscn").instantiate() as RoamingMonster
	touch_probe.name = "GameScreenTouchEncounterProbe"
	touch_probe.setup("glade_mossling_pack", Vector2.ZERO, ContentDB.get_enemy("mossling"), false)
	touch_game.world.add_child(touch_probe)
	touch_probe.global_position = touch_game.world.player.global_position
	await get_tree().process_frame
	touch_game.world.player._scan_for_interactable()
	var touch_previous_mode := TouchInput.using_touch
	TouchInput.using_touch = true
	touch_game.hud._process(0.13)
	check(touch_game.hud._touch_interact != null, "touch integration exposes the authored Interact control")
	check(not touch_probe.engaged and touch_game.active_combat == null, "touch integration remains passive before button press")
	if touch_game.hud._touch_interact != null:
		touch_game.hud._touch_interact.pressed.emit()
	check(touch_probe.engaged, "authored touch Interact button engages the nearby monster")
	check(touch_game.active_combat != null, "authored touch Interact button opens the real combat screen")
	if touch_game.active_combat != null:
		check(touch_game.active_combat.group_id == "glade_mossling_pack", "touch interaction opens the matching enemy group")
	TouchInput.using_touch = touch_previous_mode
	touch_game.queue_free()
	await get_tree().process_frame

	var backdrop_scene := load("res://scenes/ui/main_backdrop.tscn") as PackedScene
	var backdrop := backdrop_scene.instantiate() as MainBackdrop if backdrop_scene != null else null
	check(backdrop != null, "MainBackdrop loads from its authored composition scene")
	if backdrop != null:
		add_child(backdrop)
		await get_tree().process_frame
		check(backdrop.is_inside_tree(), "MainBackdrop enters the tree without crashing")
		check(backdrop.presentation is MainBackdropPresentationComponent and backdrop.presentation.get_parent() == backdrop, "MainBackdrop binds its authored presentation component")
		check(backdrop.presentation.layout_component is MainBackdropLayoutComponent and backdrop.presentation.layout_component.get_parent() == backdrop.presentation, "MainBackdrop presentation owns its responsive layout node")
		check(backdrop.presentation.animation_component is MainBackdropAnimationComponent and backdrop.presentation.animation_component.get_parent() == backdrop.presentation, "MainBackdrop presentation owns its ambient animation node")
		check(backdrop.presentation.layout_component.presentation == backdrop.presentation, "Backdrop layout component binds to its presentation owner")
		check(backdrop.presentation.animation_component.presentation == backdrop.presentation, "Backdrop animation component binds to its presentation owner")
		check(backdrop.get_node_or_null("SkyGradient") is ColorRect and backdrop.get_node_or_null("SkyGradientTexture") is TextureRect and backdrop.get_node_or_null("MoonLayer") is Node2D, "Backdrop presentation component binds authored sky and moon layers")
		backdrop.queue_free()
		await get_tree().process_frame


# ===================================================================== Phase 4
# Phase 4 shared helpers. Prefixed _phase4_ to avoid collisions with the
# Phase-2/Phase-3 helpers. Everything here is pure data / headless-safe.


## Build one fully-valid SYNTHETIC region definition (no files are touched).
func _phase4_valid_region_doc(zone: String, origin: Array) -> Dictionary:
	return {
		"name": "Synthetic " + zone,
		"subtitle": "synthetic test region",
		"chunk_size": 16,
		"tile_width": 64,
		"tile_height": 32,
		"load_radius": 1,
		"noise_seed": 4242,
		"spawn_grid": [8, 8],
		"biome": {
			"water_level": -0.2,
			"deep_water_level": -0.35,
			"grass_colors": ["#4f7a46", "#568449"],
			"path_color": "#8a7a55",
			"water_shallow": "#3f8f96",
			"water_deep": "#1f5568",
		},
		"props": [ { "type": "glade_tree", "weight": 0.5, "min_elevation": -0.1 } ],
		"clearing_radius": 4.0,
		"pois": [],
		"spawns": [],
		"world_origin": origin,
		"environment": {
			"zone": zone,
			"weather_bias": ["clear", "mist"],
			"fog_density": 0.2,
			"ambient_tint": "#7fe3e0",
			"ambient_music": "",
		},
		"entry_points": { "gate_a": [8, 8], "gate_b": [9, 9] },
		"connections": [],
	}


## Two fully-valid synthetic regions with a bidirectional, reachable link.
func _phase4_valid_doc() -> Dictionary:
	var a := _phase4_valid_region_doc("temperate_forest", [0.0, 0.0])
	a["connections"] = [ {
		"id": "to_b", "to": "region_b", "via": "gate_a", "entry": "entry_b",
		"kind": "gate", "label": "To Region B",
	} ]
	var b := _phase4_valid_region_doc("moonlit_vale", [100.0, 0.0])
	b["entry_points"] = { "entry_b": [6, 6] }
	b["connections"] = [ {
		"id": "back_a", "to": "greenward", "via": "entry_b", "entry": "gate_b",
		"kind": "gate", "label": "Back to Greenward",
	} ]
	return { "greenward": a, "region_b": b }


## A fixed, deterministic sequence (incl. CAST) for determinism comparisons.
func _phase4_drive_anim(a: CharacterAnimator) -> void:
	a.play_cast()
	a.tick(0.05)
	a.set_direction_from_vector(Vector2(1, 1))
	a.transition_to(CharacterAnimator.State.RUN)
	a.tick(0.1)
	a.play_forced(CharacterAnimator.State.ATTACK)
	a.tick(0.2)


## True when a Dictionary exposes every key in keys.
func _phase4_has_keys(entry: Dictionary, keys: Array) -> bool:
	for k in keys:
		if not entry.has(str(k)):
			return false
	return true


# -------------------------------------------- Phase 4: region definitions
## Validates the two shipped region definitions (fields, biome/seed distinction,
## spawn-group and connection references) and exercises the full RegionGraph
## accessor/validation surface. Pure: no nodes, no files, no GameState writes.
func _test_region_definitions() -> void:
	var regions: Dictionary = ContentDB.regions
	check(regions.size() >= 2, "ContentDB has at least 2 regions", str(regions.size()))
	check(regions.has("greenward") and regions.has("moonpetal_hollow"), "greenward + moonpetal_hollow are present")
	var both_nonempty := true
	for rid in ["greenward", "moonpetal_hollow"]:
		if not (regions.get(rid, {}) is Dictionary) or (regions.get(rid, {}) as Dictionary).is_empty():
			both_nonempty = false
	check(both_nonempty, "both region definitions are non-empty dictionaries")

	for rid in ["greenward", "moonpetal_hollow"]:
		var r: Dictionary = regions[rid]
		check(int(r.get("chunk_size", 0)) > 0, "chunk_size > 0: " + rid, str(r.get("chunk_size", 0)))
		check(int(r.get("tile_width", 0)) > 0, "tile_width > 0: " + rid)
		check(int(r.get("tile_height", 0)) > 0, "tile_height > 0: " + rid)
		check(int(r.get("load_radius", -1)) >= 0, "load_radius >= 0: " + rid)
		check(typeof(r.get("noise_seed", null)) == TYPE_INT or typeof(r.get("noise_seed", null)) == TYPE_FLOAT, "noise_seed is numeric: " + rid)
		check((r.get("spawn_grid", []) as Array).size() == 2, "spawn_grid has 2 coords: " + rid)
		check(r.get("biome", {}) is Dictionary and not (r.get("biome", {}) as Dictionary).is_empty(), "biome is a non-empty dict: " + rid)
		check((r.get("props", []) as Array).size() > 0, "props non-empty: " + rid)
		check(float(r.get("clearing_radius", -1.0)) >= 0.0, "clearing_radius >= 0: " + rid)
		check(r.get("pois", null) is Array, "pois is an array: " + rid)
		check(r.get("spawns", null) is Array, "spawns is an array: " + rid)

	var g: Dictionary = regions["greenward"]
	var m: Dictionary = regions["moonpetal_hollow"]
	check(g["biome"]["grass_colors"] != m["biome"]["grass_colors"], "the two biomes' grass_colors differ")
	check(int(g["noise_seed"]) != int(m["noise_seed"]), "the two noise_seed values differ")

	var group_ok := true
	var spawn_seen := 0
	for rid in ["greenward", "moonpetal_hollow"]:
		for sp in (regions[rid] as Dictionary).get("spawns", []):
			spawn_seen += 1
			var spd: Dictionary = sp
			if not ContentDB.enemy_groups.has(str(spd.get("group", ""))):
				group_ok = false
	check(spawn_seen > 0, "regions declare spawns to validate", str(spawn_seen))
	check(group_ok, "every spawns[].group exists in ContentDB.enemy_groups")

	var ext_ok := true
	for rid in ["greenward", "moonpetal_hollow"]:
		var r2: Dictionary = regions[rid]
		if not (r2.has("world_origin") and r2.has("environment") and r2.has("entry_points") and r2.has("connections")):
			ext_ok = false
	check(ext_ok, "each region has world_origin/environment/entry_points/connections")
	check(g["world_origin"] != m["world_origin"], "world_origin values differ between regions")
	check(str(g["environment"]["zone"]) != str(m["environment"]["zone"]), "environment.zone differs between regions")

	var conn_to_ok := true
	var conn_seen := 0
	for rid in ["greenward", "moonpetal_hollow"]:
		for c in (regions[rid] as Dictionary).get("connections", []):
			conn_seen += 1
			var cd: Dictionary = c
			if not regions.has(str(cd.get("to", ""))):
				conn_to_ok = false
	check(conn_seen > 0, "regions declare connections to validate", str(conn_seen))
	check(conn_to_ok, "every connections[].to names an existing region")

	var graph := RegionGraph.new(ContentDB.regions)
	var region_ids := graph.region_ids()
	check(region_ids.size() >= 2, "RegionGraph.region_ids().size() >= 2", str(region_ids.size()))
	check(graph.has_region("greenward") and graph.has_region("moonpetal_hollow"), "graph.has_region() for greenward and moonpetal_hollow")
	if graph.has_region("castle_royal_gardens"):
		check(graph.region_name("castle_royal_gardens") != "", "graph.region_name() non-empty for castle_royal_gardens")
	check(not graph.definition("greenward").is_empty() and not graph.definition("moonpetal_hollow").is_empty(), "graph.definition() non-empty for both")
	check(graph.region_name("greenward") != "" and graph.region_name("moonpetal_hollow") != "", "graph.region_name() non-empty for both")
	check(not graph.entry_points("greenward").is_empty() and not graph.entry_points("moonpetal_hollow").is_empty(), "graph.entry_points() non-empty for both")
	var eg1 := graph.entry_grid("greenward", "moonpetal_path")
	var eg2 := graph.entry_grid("moonpetal_hollow", "hollow_gate")
	check(typeof(eg1) == TYPE_VECTOR2 and typeof(eg2) == TYPE_VECTOR2, "graph.entry_grid() returns Vector2")
	check(eg1 == Vector2(30, 8) and eg2 == Vector2(6, 6), "graph.entry_grid() resolves the real coords", "%s / %s" % [eg1, eg2])
	check(graph.connections_from("greenward").size() > 0 and graph.connections_from("moonpetal_hollow").size() > 0, "graph.connections_from() > 0 for both")
	check(typeof(graph.spawn_grid("greenward")) == TYPE_VECTOR2 and typeof(graph.spawn_grid("moonpetal_hollow")) == TYPE_VECTOR2, "graph.spawn_grid() returns Vector2")
	check(graph.spawns("greenward").size() > 0 and graph.spawns("moonpetal_hollow").size() > 0, "graph.spawns() non-empty for both")
	check(not graph.environment("greenward").is_empty() and not graph.environment("moonpetal_hollow").is_empty(), "graph.environment() non-empty for both")
	check(graph.load_radius("greenward") > 0 and graph.load_radius("moonpetal_hollow") > 0, "graph.load_radius() > 0 for both")
	check(not graph.summary().is_empty(), "graph.summary() non-empty")
	check(graph.validate().is_empty(), "graph.validate() == []", str(graph.validate()))
	check(RegionGraph.validate_definitions(ContentDB.regions).is_empty(), "RegionGraph.validate_definitions(regions) == []")
	check(ContentValidator.validate_region_graph(ContentDB.regions).is_empty(), "ContentValidator.validate_region_graph(regions) == []")


# -------------------------------------- Phase 4: region graph transitions
## Exercises can_travel/resolve_transition/connection plus the LOGICAL world
## coordinate space, and re-asserts that IsoMath grid<->world is unchanged.
func _test_region_graph_transitions() -> void:
	var graph := RegionGraph.new(ContentDB.regions)
	check(graph.can_travel("greenward", "moonpetal_hollow") == true, "can_travel greenward -> moonpetal_hollow")
	check(graph.can_travel("moonpetal_hollow", "greenward") == true, "can_travel moonpetal_hollow -> greenward")
	check(graph.can_travel("greenward", "nonexistent") == false, "can_travel to a nonexistent region is false")
	check(graph.can_travel("greenward", "greenward") == false, "can_travel to self is false")

	var t := graph.resolve_transition("greenward", "moonpetal_path")
	check(bool(t.get("valid", false)), "resolve_transition valid == true")
	check(str(t.get("to", "")) == "moonpetal_hollow", "resolve_transition to == moonpetal_hollow")
	check(str(t.get("via", "")) == "moonpetal_path", "resolve_transition via == moonpetal_path")
	check(str(t.get("entry", "")) == "hollow_gate", "resolve_transition entry == hollow_gate")
	check(str(t.get("kind", "")) == "gate", "resolve_transition kind == gate")
	check(not str(t.get("label", "")).is_empty(), "resolve_transition label non-empty")
	check(typeof(t.get("from_grid")) == TYPE_VECTOR2 and typeof(t.get("to_grid")) == TYPE_VECTOR2, "resolve_transition grids are Vector2")
	check(t.get("from_grid") == Vector2(30, 8) and t.get("to_grid") == Vector2(6, 6), "resolve_transition grids match the entry points")
	check(str(t.get("error", "none")).is_empty(), "resolve_transition has no error on success")

	var back := graph.resolve_transition("moonpetal_hollow", "greenward_gate")
	check(bool(back.get("valid", false)) and str(back.get("to", "")) == "greenward", "reverse connection resolves back to greenward")

	var bad := graph.resolve_transition("greenward", "does_not_exist")
	check(not bool(bad.get("valid", true)), "unknown connection id -> valid == false")
	check(not str(bad.get("error", "")).is_empty(), "unknown connection id -> non-empty error")

	var cd := graph.connection("greenward", "moonpetal_path")
	check(str(cd.get("to", "")) == "moonpetal_hollow", "connection() returns the right dict")
	check(graph.connection("greenward", "does_not_exist").is_empty(), "connection() unknown id returns {}")

	var og := graph.world_origin("greenward")
	var om := graph.world_origin("moonpetal_hollow")
	check(og != om, "world_origin differs between the two regions", "%s / %s" % [og, om])
	check(og == Vector2.ZERO and om == Vector2(4096, 0), "world_origin values are the shipped (0,0)/(4096,0)")
	var probe := Vector2(123.5, -47.25)
	var rg := graph.world_to_local_position("greenward", graph.local_to_world_position("greenward", probe))
	var rm := graph.world_to_local_position("moonpetal_hollow", graph.local_to_world_position("moonpetal_hollow", probe))
	check(near(rg.x, probe.x) and near(rg.y, probe.y), "greenward local->world->local round-trip within epsilon")
	check(near(rm.x, probe.x) and near(rm.y, probe.y), "moonpetal local->world->local round-trip within epsilon")
	var wg := graph.world_position_of_grid("greenward", Vector2(8, 8))
	var wm := graph.world_position_of_grid("moonpetal_hollow", Vector2(8, 8))
	check(wg != wm, "world_position_of_grid((8,8)) differs by region origin")
	check(wg == Vector2(0, 256) and wm == Vector2(4096, 256), "world_position_of_grid offsets by world_origin")
	check(graph.region_at_world_position(Vector2(4096, 10)) == "moonpetal_hollow", "region_at_world_position near moonpetal origin -> moonpetal_hollow")
	check(graph.region_at_world_position(Vector2(5, 5)) == "greenward", "region_at_world_position near (0,0) -> greenward")

	check(IsoMath.grid_to_world(1, 0) == Vector2(32, 16), "IsoMath.grid_to_world(1,0) unchanged")
	check(IsoMath.grid_to_world(0, 1) == Vector2(-32, 16), "IsoMath.grid_to_world(0,1) unchanged")
	var iso_rt := IsoMath.world_to_grid(IsoMath.grid_to_world(8, 8))
	check(near(iso_rt.x, 8.0) and near(iso_rt.y, 8.0), "IsoMath grid->world->grid round trip unchanged")


# -------------------------------------- Phase 4: invalid connection documents
## Feeds SYNTHETIC region dictionaries (in-memory, no files) through all three
## validators and asserts SPECIFIC error substrings for each defect, plus a
## fully-valid zero-error baseline and the raw-text validate_text() path.
func _test_region_gate_unlocks() -> void:
	var garden_region: Dictionary = ContentDB.get_region("castle_royal_gardens")
	var connections: Array = garden_region.get("connections", [])
	var gate_data: Dictionary = {}
	for connection in connections:
		if str(connection.get("id", "")) == "boss_path_gate":
			gate_data = connection
	check(str(gate_data.get("requires_quest", "")) == "garden_shadows", "Royal Road gate declares the garden restoration quest prerequisite")
	var previous_quest: Dictionary = GameState.quest_domain.quests.get("garden_shadows", {}).duplicate(true)
	GameState.quest_domain.quests.erase("garden_shadows")
	var portal := RegionPortal.new()
	portal.setup("castle_royal_gardens", gate_data)
	add_child(portal)
	await get_tree().process_frame
	check(portal.can_interact() and not portal._requirement_met(), "Locked regional gate remains inspectable but cannot transition")
	_region_change_count = 0
	if not EventBus.region_change_requested.is_connected(_on_test_region_change):
		EventBus.region_change_requested.connect(_on_test_region_change)
	portal.interact()
	check(_region_change_count == 0, "Locked Royal Road gate does not emit a region transition")
	GameState.quest_domain.quests["garden_shadows"] = {"state": "complete", "step": 3, "progress": 0}
	check(portal._requirement_met(), "Completing the garden restoration quest unlocks the Royal Road")
	portal.interact()
	check(_region_change_count == 1, "Unlocked Royal Road gate emits exactly one region transition")
	if EventBus.region_change_requested.is_connected(_on_test_region_change):
		EventBus.region_change_requested.disconnect(_on_test_region_change)
	portal.queue_free()
	if previous_quest.is_empty():
		GameState.quest_domain.quests.erase("garden_shadows")
	else:
		GameState.quest_domain.quests["garden_shadows"] = previous_quest
	await get_tree().process_frame


func _test_invalid_connections() -> void:
	var ctx: Dictionary = ContentValidator.validate_all().get("data", {})

	var valid := _phase4_valid_doc()
	check(ContentValidator.validate_document("regions.json", valid, ctx).is_empty(), "valid synthetic 2-region doc: validate_document == []", str(ContentValidator.validate_document("regions.json", valid, ctx)))
	check(ContentValidator.validate_region_graph(valid).is_empty(), "valid synthetic doc: validate_region_graph == []")
	check(RegionGraph.validate_definitions(valid).is_empty(), "valid synthetic doc: RegionGraph.validate_definitions == []")

	var c1 := _phase4_valid_doc()
	c1["greenward"]["connections"][0]["to"] = "ghost_region"
	check(_has_error(ContentValidator.validate_document("regions.json", c1, ctx), "references missing region 'ghost_region'"), "validate_document: 'to' missing region error")
	check(_has_error(ContentValidator.validate_region_graph(c1), "references missing region 'ghost_region'"), "validate_region_graph: 'to' missing region error")
	check(_has_error(RegionGraph.validate_definitions(c1), "references missing region 'ghost_region'"), "RegionGraph: 'to' missing region error")

	var c2 := _phase4_valid_doc()
	c2["greenward"]["connections"][0]["to"] = "greenward"
	check(_has_error(ContentValidator.validate_document("regions.json", c2, ctx), "connection cannot target itself"), "validate_document: self-loop error")
	check(_has_error(ContentValidator.validate_region_graph(c2), "connection cannot target itself"), "validate_region_graph: self-loop error")
	check(_has_error(RegionGraph.validate_definitions(c2), "connection cannot target itself"), "RegionGraph: self-loop error")

	var c3 := _phase4_valid_doc()
	c3["greenward"]["connections"][0]["via"] = "bad_via"
	check(_has_error(ContentValidator.validate_document("regions.json", c3, ctx), "references missing entry point 'bad_via'"), "validate_document: dangling 'via' error")
	check(_has_error(ContentValidator.validate_region_graph(c3), "dangling 'via' entry point"), "validate_region_graph: dangling 'via' error")
	check(_has_error(RegionGraph.validate_definitions(c3), "dangling 'via' entry point"), "RegionGraph: dangling 'via' error")

	var c4 := _phase4_valid_doc()
	c4["greenward"]["connections"][0]["entry"] = "bad_entry"
	check(_has_error(ContentValidator.validate_document("regions.json", c4, ctx), "references missing entry point 'bad_entry' in destination region"), "validate_document: dangling 'entry' error")
	check(_has_error(ContentValidator.validate_region_graph(c4), "dangling 'entry' point 'bad_entry'"), "validate_region_graph: dangling 'entry' error")
	check(_has_error(RegionGraph.validate_definitions(c4), "dangling 'entry' point 'bad_entry'"), "RegionGraph: dangling 'entry' error")

	var c5 := _phase4_valid_doc()
	var dup_conn: Dictionary = c5["greenward"]["connections"][0]
	dup_conn["id"] = "dup"
	var dup_conn2: Dictionary = dup_conn.duplicate(true)
	c5["greenward"]["connections"] = [dup_conn, dup_conn2]
	check(_has_error(ContentValidator.validate_document("regions.json", c5, ctx), "duplicate connection id 'dup'"), "duplicate connection id error")

	var c6 := _phase4_valid_doc()
	c6["greenward"]["connections"][0]["kind"] = "teleporter"
	var e6 := ContentValidator.validate_document("regions.json", c6, ctx)
	check(_has_error(e6, "must be one of"), "invalid kind -> 'must be one of' error")
	check(_has_error(e6, "kind"), "invalid kind error names 'kind'")

	var c7 := _phase4_valid_doc()
	c7["greenward"]["connections"][0]["label"] = ""
	var e7 := ContentValidator.validate_document("regions.json", c7, ctx)
	check(_has_error(e7, "must not be empty"), "empty label -> 'must not be empty' error")
	check(_has_error(e7, "label"), "empty label error names 'label'")

	var c8 := _phase4_valid_doc()
	c8["greenward"]["world_origin"] = [1, 2, 3]
	var e8 := ContentValidator.validate_document("regions.json", c8, ctx)
	check(_has_error(e8, "expected exactly two coordinates"), "malformed world_origin -> two-coordinates error")
	check(_has_error(e8, "world_origin"), "malformed world_origin error names world_origin")

	var c9 := _phase4_valid_doc()
	c9["greenward"]["environment"]["fog_density"] = 1.5
	check(_has_error(ContentValidator.validate_document("regions.json", c9, ctx), "must be between 0 and 1"), "fog_density > 1 rejected")
	var c9b := _phase4_valid_doc()
	c9b["greenward"]["environment"]["fog_density"] = -0.5
	check(_has_error(ContentValidator.validate_document("regions.json", c9b, ctx), "must be between 0 and 1"), "fog_density < 0 rejected")

	var c10 := _phase4_valid_doc()
	c10["greenward"]["environment"]["weather_bias"] = ["hurricane"]
	var e10 := ContentValidator.validate_document("regions.json", c10, ctx)
	check(_has_error(e10, "must be one of"), "invalid weather_bias value -> 'must be one of' error")
	check(_has_error(e10, "weather_bias"), "invalid weather_bias error names weather_bias")

	var c11 := _phase4_valid_doc()
	c11["greenward"]["environment"]["ambient_tint"] = "not-a-colour"
	var e11 := ContentValidator.validate_document("regions.json", c11, ctx)
	check(_has_error(e11, "expected a #rrggbb colour"), "invalid ambient_tint -> colour error")
	check(_has_error(e11, "ambient_tint"), "invalid ambient_tint error names ambient_tint")

	var c12 := _phase4_valid_doc()
	c12["greenward"]["entry_points"]["gate_a"] = [8]
	var e12 := ContentValidator.validate_document("regions.json", c12, ctx)
	check(_has_error(e12, "expected exactly two coordinates"), "bad entry_points grid -> two-coordinates error")
	check(_has_error(e12, "entry_points"), "bad entry_points grid error names entry_points")

	var c13 := _phase4_valid_doc()
	c13["greenward"]["spawns"] = [ { "group": "ghost_group_xyz", "grid": [4, 6], "radius": 3, "count": 2 } ]
	check(_has_error(ContentValidator.validate_document("regions.json", c13, ctx), "references missing enemy group 'ghost_group_xyz'"), "dangling spawns[].group error")

	var text_doc := _phase4_valid_doc()
	text_doc["greenward"]["connections"][0]["to"] = "greenward"
	var raw := JSON.stringify(text_doc)
	check(_has_error(ContentValidator.validate_text("regions.json", raw, ctx), "connection cannot target itself"), "validate_text() raw path reports self-loop")
	check(not raw.is_empty(), "synthetic JSON text is non-empty")


# ------------------------------------------ Phase 4: region-aware save state
## Snapshots/restores GameState within the test. Verifies player_region,
## per-region positions, the legacy position mirror, _to_dict() keys and a full
## round-trip + backwards compatibility for old saves without the new keys.
func _test_region_save_state() -> void:
	var original: Dictionary = GameState._to_dict().duplicate(true)
	var original_loaded: bool = GameState.loaded_from_save

	check(ContentDB.regions.has(GameState.player_region), "player_region is a valid region id at start", GameState.player_region)
	GameState.set_player_region("moonpetal_hollow")
	check(GameState.player_region == "moonpetal_hollow", "set_player_region updates player_region")

	GameState.set_region_position("greenward", Vector2(11.5, 22.25))
	check(GameState.has_region_position("greenward"), "has_region_position(greenward) true after set")
	var pg: Variant = GameState.region_position("greenward")
	check(near(pg.x, 11.5) and near(pg.y, 22.25), "region_position(greenward) round-trips the Vector2")
	GameState.set_region_position("moonpetal_hollow", Vector2(33.5, 44.75))
	check(GameState.has_region_position("moonpetal_hollow"), "has_region_position(moonpetal_hollow) true")
	var pm: Variant = GameState.region_position("moonpetal_hollow")
	check(near(pm.x, 33.5) and near(pm.y, 44.75), "region_position(moonpetal_hollow) round-trips")
	check(near(GameState.region_position("greenward").x, 11.5), "greenward position is independent of moonpetal")
	check(GameState.has_region_position("greenward") and GameState.has_region_position("moonpetal_hollow"), "region_positions holds independent slots per region")
	check(near(GameState.region_position("greenward").x, 11.5) and near(GameState.region_position("moonpetal_hollow").x, 33.5), "region_positions stores each region independently")

	GameState.set_player_region("greenward")
	GameState.set_player_position(Vector2(5.0, 6.0))
	check(GameState.player_position == Vector2(5.0, 6.0), "set_player_position still sets player_position")
	check(GameState.has_player_position == true, "set_player_position still sets has_player_position")
	check(near(float((GameState.region_positions["greenward"] as Dictionary).get("x", 0.0)), 5.0), "set_player_position mirrors x into region_positions[player_region]")
	check(near(GameState.region_position("greenward").y, 6.0), "set_player_position mirrors into region slot")

	var snap: Dictionary = GameState._to_dict()
	check(snap.has("region") and snap.has("region_positions"), "_to_dict contains region + region_positions")
	for key in ["profile", "roster", "party", "inventory", "quests", "pity", "flags", "position", "has_position"]:
		check(snap.has(key), "_to_dict preserves original key: " + str(key))
	check(snap.get("region") == GameState.player_region, "_to_dict region matches player_region")

	GameState.set_player_region("moonpetal_hollow")
	GameState.set_region_position("greenward", Vector2(1.25, 2.5))
	GameState.set_region_position("moonpetal_hollow", Vector2(7.75, 8.5))
	var saved: Dictionary = GameState._to_dict().duplicate(true)
	GameState.new_game("Region RoundTrip")
	check(GameState.player_region == "greenward", "new_game() resets player_region to greenward")
	check(GameState.region_positions.is_empty(), "new_game() clears region_positions")
	GameState._load_from_dict(saved)
	check(GameState.player_region == str(saved.get("region", "")), "round-trip preserves player_region")
	check(GameState.player_region == "moonpetal_hollow", "round-trip player_region is moonpetal_hollow")
	check(GameState.region_positions == saved.get("region_positions", {}), "round-trip preserves region_positions")
	check(near(GameState.region_position("moonpetal_hollow").x, 7.75), "round-trip restores a stored region Vector2")

	var old: Dictionary = original.duplicate(true)
	old.erase("region")
	old.erase("region_positions")
	old.erase("active_world_id")
	old.erase("player_facing")
	GameState._load_from_dict(old)
	check(GameState.player_region == "greenward", "old save (no region key) defaults player_region to greenward")
	if bool(old.get("has_position", false)):
		check(GameState.has_region_position("greenward"), "legacy save migrates stored position into active greenward region slot")
		check(near(GameState.region_position("greenward").x, GameState.player_position.x), "migrated legacy region position preserves x")
	else:
		check(GameState.region_positions.is_empty(), "old save without position leaves region_positions empty")
	check(not GameState.profile.is_empty(), "old save loads fully without crashing")

	GameState._load_from_dict(original.duplicate(true))
	GameState.loaded_from_save = original_loaded


## Reproduce New Journey -> Castle -> return to title -> Continue using the real
## GameState, world resolver, SaveService JSON file, and startup-flow component.
func _test_new_journey_castle_continue() -> void:
	var startup_script := load("res://scripts/game/components/main_startup_flow_component.gd")
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	check(startup_script != null and game_scene != null, "Continue regression scenes load")
	if startup_script == null or game_scene == null:
		return

	var test_host := Control.new()
	add_child(test_host)
	var startup := startup_script.new() as MainStartupFlowComponent
	test_host.add_child(startup)
	startup.bind(test_host)
	# Exercise the current startup flow's new-journey setup instead of the removed
	# MainMenu handler; the title screen owns this action in the current UI.
	startup._prepare_new_journey()
	check(not GameState.loaded_from_save, "New Journey enters unsaved journey state")

	var first_game := game_scene.instantiate() as GameScreen
	add_child(first_game)
	await get_tree().process_frame
	await get_tree().process_frame
	check(first_game.current_region_id == "castle_royal_gardens", "New Journey resolves to Royal Gardens")
	var perimeter = first_game.world.get_node_or_null("GardenPerimeterWalls") if first_game.world != null else null
	check(perimeter is CastlePerimeterWallsComponent, "Castle map validates its authored perimeter wall assembly")
	if perimeter is CastlePerimeterWallsComponent:
		check(perimeter.get_child_count() == 4, "Castle perimeter is composed of four authored architectural wall-run scenes")
		for wall_run in perimeter.get_children():
			check(wall_run is CastlePerimeterWallRunComponent, "Perimeter segment uses the reusable wall-run component", str(wall_run.name))
			check(wall_run.get_node_or_null("Facade") is Polygon2D and wall_run.get_node_or_null("Parapet") is Polygon2D and wall_run.get_node_or_null("Plinth") is Polygon2D and wall_run.get_node_or_null("Piers") is Node2D, "Perimeter wall owns authored architectural presentation layers", str(wall_run.name))
			check(wall_run.get_node_or_null("WallCollision") is StaticBody2D, "Each perimeter wall run retains its authored collision barrier", str(wall_run.name))
			var wall_shape := wall_run.get_node_or_null("WallCollision/CollisionShape2D") as CollisionShape2D
			var wall_rect := wall_shape.shape as RectangleShape2D if wall_shape != null else null
			check(wall_rect != null and is_equal_approx(wall_rect.size.x, wall_run.run_length) and is_equal_approx(wall_rect.size.y, 38.0), "Perimeter collision dimensions match the configured wall run", str(wall_run.name))
			var expected_piers := int(floor(wall_run.run_length / wall_run.bay_width)) + 1
			check(wall_run.get_node_or_null("Piers").get_child_count() == expected_piers, "Perimeter pier spacing is generated from the wall run's bay width", str(wall_run.name))
	check(first_game.world.get_node_or_null("PlayerSpawner") is CastlePlayerSpawnerComponent, "Castle player spawning is owned by an authored child component")
	check(first_game.world.get_node_or_null("WorldRuntime") is CastleWorldRuntimeComponent, "Castle position persistence is owned by an authored runtime component")
	check(first_game.world.get_node_or_null("Presentation") is CastleWorldPresentationComponent, "Castle visual reporting is owned by an authored presentation component")
	check(first_game.world.get_node_or_null("Castle") == null, "Royal Gardens does not contain the separate Gothic Castle architecture")
	var royal_gardens_gothic_textures: Array[String] = []
	var royal_gardens_scan: Array[Node] = [first_game.world]
	while not royal_gardens_scan.is_empty():
		var inspected: Node = royal_gardens_scan.pop_back()
		if inspected is Sprite2D:
			var sprite_texture := (inspected as Sprite2D).texture
			if sprite_texture != null and sprite_texture.resource_path.contains("/Gothic_Castle/"):
				royal_gardens_gothic_textures.append(sprite_texture.resource_path)
		for child in inspected.get_children():
			royal_gardens_scan.append(child)
	check(royal_gardens_gothic_textures.is_empty(), "Royal Gardens does not render Gothic Castle region textures", str(royal_gardens_gothic_textures))
	check(first_game.world.get_node_or_null("GardenPerimeterWalls") is CastlePerimeterWallsComponent, "Royal Gardens keeps its own perimeter without a castle overlay")
	check(first_game.world.get_node_or_null("Terrain/GrassDetails") is Node2D and first_game.world.get_node_or_null("Lighting") is Node2D and first_game.world.get_node_or_null("EnvironmentEffects") is Node2D, "Terrain and lighting layers are authored in the Royal Gardens scene")
	var terrain_config := first_game.world.get_node_or_null("Terrain/Configuration") as Node2D
	check(terrain_config != null and terrain_config.get_meta("ground_min", null) is Vector2i and terrain_config.get_meta("ground_max", null) is Vector2i and terrain_config.get_child_count() == 6, "Terrain bounds, tile metrics, seed and six grass detail placements are scene-authored")
	check(first_game.world.get_node_or_null("PathwayTiles/RoyalPromenade") is Node2D and first_game.world.get_node_or_null("PathwayTiles/RoyalPromenade").get_child_count() == 105, "Royal Promenade is a reusable authored pathway assembly")
	check(first_game.world.get_node_or_null("OuterRoad") is Node2D and first_game.world.get_node_or_null("OuterRoad").get_child_count() == 90, "Outer Road is a reusable authored road assembly")
	check(first_game.world.get_node_or_null("Water/FountainCourt") is Node2D and first_game.world.get_node_or_null("Water/OuterPonds") is Node2D, "Water features are owned by a reusable water assembly")
	check(first_game.world.get_node_or_null("Water") is CastleWaterComponent and first_game.world.get_node_or_null("Water/WaterZones/LeftPond") is Marker2D and first_game.world.is_water_world(IsoMath.grid_to_world(23.75, 10.31)), "Water interaction zones are owned by authored water markers and their component")
	check(first_game.world.get_node_or_null("Flora/TreeAvenue") is Node2D and first_game.world.get_node_or_null("Flora/FlowerBorders") is Node2D and first_game.world.get_node_or_null("Flora/HedgesAndShrubs") is Node2D and first_game.world.get_node_or_null("Flora/WorldPerimeter") is Node2D, "Flora is organized into authored tree, flower, hedge and perimeter groups")
	check(first_game.world.get_node_or_null("Props/Furniture") is Node2D and first_game.world.get_node_or_null("Props/Lighting") is Node2D and first_game.world.get_node_or_null("Props/Statues") is Node2D, "Props are organized into furniture, lighting and statue groups")
	check(first_game.world.get_node_or_null("NPCPlacement") is NpcPlacement and first_game.world.get_node_or_null("MapSpawnPoints") is MapSpawnPoints, "NPC and player spawn markers are owned by reusable marker scenes")
	var guard_marker := first_game.world.get_node_or_null("NPCPlacement/GuardLeft") as Marker2D
	check(guard_marker != null and guard_marker.get_meta("npc_id", "") == "castle_guard_left" and guard_marker.get_meta("grid_position", null) is Vector2, "NPC identity and grid placement are authored on their marker")
	var npc_markers := first_game.world.get_node_or_null("NPCPlacement")
	check(npc_markers != null and npc_markers.get_child_count() == 4, "All four Royal Gardens NPCs have authored placement markers")
	if npc_markers != null:
		for npc_marker in npc_markers.get_children():
			check(npc_marker is Marker2D and npc_marker.has_meta("npc_id") and npc_marker.has_meta("display_name") and npc_marker.has_meta("dialogue_id") and npc_marker.has_meta("role") and npc_marker.has_meta("race") and npc_marker.get_meta("palette", null) is Dictionary and npc_marker.get_meta("grid_position", null) is Vector2, "NPC marker owns complete identity, palette and grid configuration", str(npc_marker.name))
	var light_anchors := first_game.world.get_node_or_null("Lighting/Anchors") as Node2D
	check(light_anchors != null and light_anchors.get_child_count() == 7, "Garden lighting positions are owned by seven authored anchor markers")
	check(light_anchors != null and light_anchors.get_node("Light01").has_meta("light_offset") and light_anchors.get_node("Shadow").has_meta("presentation_offset") and light_anchors.get_node("AmbientParticles").has_meta("presentation_offset"), "Light, shadow and ambient offsets are authored on their presentation markers")
	check(first_game.world.get_node_or_null("WorldRuntime").get("save_position_interval") == 1.0, "World persistence cadence is configurable on its runtime node")
	check(first_game.world.get_node_or_null("Bounds/Left") is CollisionShape2D and first_game.world.get_node_or_null("Bounds/Right") is CollisionShape2D and first_game.world.get_node_or_null("Bounds/Top") is CollisionShape2D and first_game.world.get_node_or_null("Bounds/Bottom") is CollisionShape2D, "World boundary collision is an authored reusable scene")
	check(first_game.world.get_node_or_null("TerrainBuilder") is CastleTerrainComponent, "Castle map delegates ground generation to its terrain component")
	check(first_game.world.get_node_or_null("LightingBuilder") is CastleLightingComponent, "Castle map delegates lighting and ambient effects to its lighting component")
	check(first_game.world.get_node_or_null("NPCSpawner") is CastleNPCSpawnerComponent, "Castle map delegates marker-based NPC creation to its spawner component")
	var expansion := first_game.world.get_node_or_null("ExpansionBuilder")
	check(expansion != null and expansion.get_node("ExpansionGround").get_child_count() == 7, "Authored ceremonial approach creates all seven path pieces")
	check(expansion != null and expansion.get_node("ExpansionFlora").get_child_count() == 15, "Authored ceremonial approach creates all fifteen flora pieces")
	check(expansion != null and expansion.get_node("ExpansionProps").get_child_count() >= 6, "All six authored approach props are present alongside any runtime cache props")
	var wall_x_scene: PackedScene = load("res://scenes/world/castle_gardens/v02/architecture/castle_wall_x.tscn")
	var wall_y_scene: PackedScene = load("res://scenes/world/castle_gardens/v02/architecture/castle_wall_y.tscn")
	var wall_x = wall_x_scene.instantiate() if wall_x_scene != null else null
	var wall_y = wall_y_scene.instantiate() if wall_y_scene != null else null
	check(wall_x is CastleFacadeWall and wall_x.orientation == "x", "Castle X wall uses a screen-facing architectural facade")
	check(wall_y is CastleFacadeWall and wall_y.orientation == "y", "Castle Y wall uses a screen-facing architectural facade")
	check(wall_x is Node2D and wall_x.y_sort_enabled and wall_y is Node2D and wall_y.y_sort_enabled, "Both wall orientations participate in isometric depth sorting")
	check(wall_x.get_node_or_null("Body/Footprint0") is CollisionShape2D and wall_y.get_node_or_null("Body/Footprint0") is CollisionShape2D, "Both wall orientations retain authored footprint collision")
	if wall_x != null:
		wall_x.free()
	if wall_y != null:
		wall_y.free()
	var expected_position := Vector2(1100.0, 700.0)
	var first_player = first_game.world.get("player") if first_game.world != null else null
	if first_player != null:
		first_player.position = expected_position
		first_game._persist_current_world_state()
	else:
		check(false, "Castle player exists for save regression")
	first_game.queue_free()
	await get_tree().process_frame

	# Continue is the actual title-screen handler and must reload from disk rather
	# than relying on the state left in memory by the outgoing world.
	startup._on_title_action("continue")
	check(GameState.loaded_from_save, "Continue marks state as loaded from save")
	check(GameState.active_world_id == "castle_royal_gardens", "Continue restores Castle world ID from disk", GameState.active_world_id)
	check(GameState.player_region == "castle_royal_gardens", "Continue restores Castle region from disk", GameState.player_region)
	check(GameState.player_position == expected_position, "Continue restores saved player position", str(GameState.player_position))

	var continued_game := game_scene.instantiate() as GameScreen
	add_child(continued_game)
	await get_tree().process_frame
	await get_tree().process_frame
	check(continued_game.current_region_id == "castle_royal_gardens", "Continue world resolver instantiates Castle")
	var resumed_castle := continued_game.world as CastleRoyalGardens
	check(resumed_castle != null and resumed_castle.get_world_monsters().size() == 2, "Castle world spawns its two authored sentinel encounters", str(resumed_castle.get_world_monsters().size()) if resumed_castle != null else "missing Castle")
	check(resumed_castle != null and resumed_castle.get_node_or_null("Entities/QuestDestinationMarker") is QuestDestinationMarker, "Castle world owns an authored quest destination marker")
	check(GameState.quest_domain.quest_marker_for_npc("royal_gardener") == "available", "Royal Gardener advertises the Castle garden quest")
	GameState.quest_domain.quests.erase("garden_shadows")
	check(GameState.quest_domain.start_quest("garden_shadows", "royal_gardener"), "Royal Gardener can start the Castle garden quest")
	check(GameState.quest_domain.quest_step_index("garden_shadows") == 1, "Castle quest advances past its giver after acceptance")
	check(GameState.quest_domain.quest_marker_for_npc("royal_gardener") == "active", "Royal Gardener displays an active quest marker during the hunt")
	GameState.quest_domain.record_kill("gothic_sentinel", 2)
	check(GameState.quest_domain.quest_ready("garden_shadows"), "Two sentinel defeats unlock the Castle quest turn-in")
	check(GameState.quest_domain.complete_quest("garden_shadows"), "Castle garden quest grants completion and rewards")
	check(GameState.quest_domain.quest_state("garden_shadows") == "complete", "Castle garden quest persists its completed state")
	var continued_player = continued_game.world.get("player") if continued_game.world != null else null
	check(continued_player != null, "Continued Castle player exists")
	if continued_player != null:
		check(continued_player.position.distance_to(expected_position) < 0.01, "Continued Castle player returns to saved position", str(continued_player.position))
	continued_game.queue_free()
	test_host.queue_free()
	await get_tree().process_frame


func _test_continue_exact_position_and_return_to_title() -> void:
	# Explicit regression: New Journey -> Castle -> move/save -> return-to-title flow
	# (persist as GameScreen does) -> Continue restores latest world, exact position,
	# facing, and progression state from disk.
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	check(game_scene != null, "Continue regression: game scene loads")
	if game_scene == null:
		return
	SaveService.delete_save()
	GameState.loaded_from_save = false
	GameState.new_game("Continue Regression")
	# Explicit new journey start in Royal Gardens (menu/start flow intent).
	GameState.set_player_region("castle_royal_gardens")
	GameState.set_active_world("castle_royal_gardens")
	GameState.has_player_position = false
	GameState.region_positions.clear()
	GameState.save_now()
	# Simulate progression/inventory changes that must persist.
	GameState.add_currency("gold", 123)
	var party: Variant = GameState.party_instances()
	if not party.is_empty():
		GameState.add_xp_to_character(party[0], 250)
	GameState.inventory["glade_sap"] = int(GameState.inventory.get("glade_sap", 0)) + 7
	var first_game := game_scene.instantiate() as GameScreen
	add_child(first_game)
	await get_tree().process_frame
	await get_tree().process_frame
	check(first_game.current_region_id == "castle_royal_gardens", "Continue regression: new journey starts in Royal Gardens", first_game.current_region_id)
	var expected_position := Vector2(640.0, 620.0) # Clear authored PlayerSpawn tile; do not test persistence inside HedgeWestB collision.
	var expected_facing := Vector2(-1.0, 0.0)
	var first_player = first_game.world.get("player") if first_game.world != null else null
	check(first_player != null, "Continue regression: Castle player exists")
	if first_player != null:
		first_player.position = expected_position
		if "facing_direction" in first_player:
			first_player.facing_direction = expected_facing
	# Simulate return-to-title persistence path.
	first_game._persist_current_world_state()
	var save_data := SaveService.load_save()
	check(str(save_data.get("active_world_id", "")) == "castle_royal_gardens", "Continue regression: return-to-title saves Castle active world", str(save_data.get("active_world_id", "")))
	check(str(save_data.get("region", "")) == "castle_royal_gardens", "Continue regression: return-to-title saves Castle region", str(save_data.get("region", "")))
	var saved_pos: Dictionary = save_data.get("position", {})
	check(absf(float(saved_pos.get("x", 0.0)) - expected_position.x) < 0.01 and absf(float(saved_pos.get("y", 0.0)) - expected_position.y) < 0.01, "Continue regression: exact player position saved to disk", str(saved_pos))
	var saved_rpos: Dictionary = save_data.get("region_positions", {}).get("castle_royal_gardens", {})
	check(absf(float(saved_rpos.get("x", 0.0)) - expected_position.x) < 0.01 and absf(float(saved_rpos.get("y", 0.0)) - expected_position.y) < 0.01, "Continue regression: exact Castle region position saved to disk", str(saved_rpos))
	first_game.queue_free()
	await get_tree().process_frame

	# Clear in-memory state, then Continue/load from disk (actual restore path).
	GameState.profile.clear()
	GameState.roster.clear()
	GameState.party.clear()
	GameState.inventory.clear()
	GameState.quests.clear()
	GameState.flags.clear()
	GameState.loaded_from_save = false
	var loaded := SaveService.load_save()
	GameState._load_from_dict(loaded)
	GameState.loaded_from_save = true
	check(GameState.active_world_id == "castle_royal_gardens", "Continue regression: loaded active world is Castle", GameState.active_world_id)
	check(GameState.player_region == "castle_royal_gardens", "Continue regression: loaded region is Castle", GameState.player_region)
	check(GameState.player_position.distance_to(expected_position) < 0.01, "Continue regression: loaded exact player position", str(GameState.player_position))
	check(GameState.player_facing.distance_to(expected_facing.normalized()) < 0.01, "Continue regression: loaded facing direction", str(GameState.player_facing))
	check(GameState.has_region_position("castle_royal_gardens"), "Continue regression: Castle region position restored")
	check(GameState.region_position("castle_royal_gardens").distance_to(expected_position) < 0.01, "Continue regression: restored Castle region position is exact", str(GameState.region_position("castle_royal_gardens")))
	check(int(GameState.currency("gold")) >= 623, "Continue regression: progression/currency restored", str(GameState.currency("gold")))
	check(int(GameState.inventory.get("glade_sap", 0)) >= 10, "Continue regression: inventory restored", str(GameState.inventory.get("glade_sap", 0)))

	var continued_game := game_scene.instantiate() as GameScreen
	add_child(continued_game)
	await get_tree().process_frame
	await get_tree().process_frame
	check(continued_game.current_region_id == "castle_royal_gardens", "Continue regression: resolver instantiates Castle world", continued_game.current_region_id)
	var continued_player = continued_game.world.get("player") if continued_game.world != null else null
	check(continued_player != null, "Continue regression: continued player exists")
	if continued_player != null:
		check(continued_player.position.distance_to(expected_position) < 0.01, "Continue regression: continued player placed at exact saved position", str(continued_player.position))
	continued_game.queue_free()
	await get_tree().process_frame


func _test_continue_legacy_greenward_save() -> void:
	# Legacy/Greenward saves must continue to load Greenward correctly and must not
	# be corrupted or incorrectly migrated to Castle.
	var legacy := {
		"version": 1,
		"profile": {
			"name": "Legacy Wanderer",
			"level": 3,
			"xp": 10,
			"gold": 777,
			"gems": 0,
			"crystals": 42,
			"guild_tokens": 0,
			"ancient_coins": 0,
			"event_tokens": 0,
			"created_at": 1000.0,
		},
		"roster": [
			{"uid": "legacy_gerald", "char_id": "gerald", "level": 3, "xp": 0, "ascension": 0, "awakening": 0, "dupes": 0, "bond": 0, "equipment": {}},
			{"uid": "legacy_lilith", "char_id": "lilith", "level": 2, "xp": 0, "ascension": 0, "awakening": 0, "dupes": 0, "bond": 0, "equipment": {}},
			{"uid": "legacy_kael", "char_id": "kael", "level": 1, "xp": 0, "ascension": 0, "awakening": 0, "dupes": 0, "bond": 0, "equipment": {}},
		],
		"party": ["legacy_gerald", "legacy_lilith", "legacy_kael"],
		"inventory": {"glade_sap": 5},
		"quests": {},
		"pity": {},
		"flags": {},
		"gear_levels": {},
		"position": {"x": 111.0, "y": 222.0},
		"has_position": true,
		# Intentionally no active_world_id / player_facing / region_positions
		"region": "greenward",
	}
	SaveService.write_save(legacy)
	var reloaded := SaveService.load_save()
	GameState._load_from_dict(reloaded)
	GameState.loaded_from_save = true
	check(GameState.active_world_id == "greenward", "Legacy save: active world remains Greenward", GameState.active_world_id)
	check(GameState.player_region == "greenward", "Legacy save: region remains Greenward", GameState.player_region)
	check(GameState.has_player_position, "Legacy save: has player position")
	check(GameState.player_position.distance_to(Vector2(111.0, 222.0)) < 0.01, "Legacy save: exact position restored", str(GameState.player_position))
	check(int(GameState.currency("gold")) == 777, "Legacy save: currencies/progress preserved", str(GameState.currency("gold")))
	check(int(GameState.inventory.get("glade_sap", 0)) == 5, "Legacy save: inventory preserved")
	# Verify resolver/build path for legacy continue targets Greenward.
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	if game_scene != null:
		var legacy_game := game_scene.instantiate() as GameScreen
		add_child(legacy_game)
		await get_tree().process_frame
		await get_tree().process_frame
		check(legacy_game.current_region_id == "greenward", "Legacy save: continue resolves to Greenward world", legacy_game.current_region_id)
		legacy_game.queue_free()
		await get_tree().process_frame


func _test_continue_does_not_revert_to_greenward_when_save_is_castle() -> void:
	# Regression for the reported bug: Continue must restore the latest persisted
	# Castle save (world + exact position/state), never Greenward, and must not be
	# overwritten by stale in-memory defaults during/after exit persistence.
	# (Do not call GameScreen._return_to_title() here: it changes the scene tree
	# and breaks the headless test runner.)
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	check(game_scene != null, "Continue castle regression: game scene loads")
	if game_scene == null:
		return
	SaveService.delete_save()
	GameState.loaded_from_save = false
	GameState.new_game("Castle Continue Regression")
	# Explicit new journey start in Royal Gardens.
	GameState.set_player_region("castle_royal_gardens")
	GameState.set_active_world("castle_royal_gardens")
	GameState.has_player_position = false
	GameState.region_positions.clear()
	GameState.save_now()
	var first_game := game_scene.instantiate() as GameScreen
	add_child(first_game)
	await get_tree().process_frame
	await get_tree().process_frame
	check(first_game.current_region_id == "castle_royal_gardens", "Continue castle regression: New Journey starts in Castle", first_game.current_region_id)
	var exact_pos := Vector2(1000.0, 700.0)
	var player = first_game.world.get("player") if first_game.world != null else null
	if player != null:
		player.position = exact_pos
		if "facing_direction" in player:
			player.facing_direction = Vector2(0, -1)
	# Persist as return-to-title does (authoritative current region) and simulate
	# leaving gameplay without a scene change that would disrupt the test runner.
	first_game._persist_current_world_state()
	var disk := SaveService.load_save()
	check(str(disk.get("active_world_id", "")) == "castle_royal_gardens", "Continue castle regression: disk save remains Castle after exit persistence", str(disk.get("active_world_id", "")))
	check(str(disk.get("region", "")) == "castle_royal_gardens", "Continue castle regression: disk region remains Castle", str(disk.get("region", "")))
	# Simulate stale in-memory drift/defaults after title transition; Continue must
	# restore from disk, not from memory.
	GameState.set_player_region("greenward")
	GameState.set_active_world("greenward")
	GameState.has_player_position = false
	GameState.loaded_from_save = false
	first_game.queue_free()
	await get_tree().process_frame
	var loaded := SaveService.load_save()
	GameState._load_from_dict(loaded)
	GameState.loaded_from_save = true
	check(GameState.active_world_id == "castle_royal_gardens", "Continue castle regression: Continue loads Castle world from disk", GameState.active_world_id)
	check(GameState.player_region == "castle_royal_gardens", "Continue castle regression: Continue loads Castle region from disk", GameState.player_region)
	check(GameState.player_position.distance_to(exact_pos) < 0.01, "Continue castle regression: exact position restored", str(GameState.player_position))
	var resumed := game_scene.instantiate() as GameScreen
	add_child(resumed)
	await get_tree().process_frame
	await get_tree().process_frame
	check(resumed.current_region_id == "castle_royal_gardens", "Continue castle regression: resumed world is Castle", resumed.current_region_id)
	var resumed_player = resumed.world.get("player") if resumed.world != null else null
	if resumed_player != null:
		check(resumed_player.position.distance_to(exact_pos) < 0.01, "Continue castle regression: resumed player at exact saved position", str(resumed_player.position))
	resumed.queue_free()
	await get_tree().process_frame



# ----------------------------------------------- Phase 4: asset manifest
## Verifies the 8-class replacement contract (entries, import settings, expected
## paths, disk/status reality), sheet-spec validation errors and the seams.
func _test_asset_manifest() -> void:
	check(AssetManifest.ASSET_CLASSES.size() == 8, "ASSET_CLASSES.size() == 8", str(AssetManifest.ASSET_CLASSES.size()))
	var entries: Array[Dictionary] = AssetManifest.entries()
	check(entries.size() == 8, "entries().size() == 8", str(entries.size()))
	var required_keys: Array = ["id", "class", "path", "width", "height", "anchor", "frames", "import", "naming", "seam", "status"]
	for e in entries:
		check(_phase4_has_keys(e, required_keys), "entry has all 11 keys: " + str(e.get("id", "?")))
	var dims_ok := true
	var paths_ok := true
	var imports_ok := true
	for e in entries:
		if int(e.get("width", 0)) <= 0 or int(e.get("height", 0)) <= 0:
			dims_ok = false
		if not str(e.get("path", "")).begins_with("res://assets/"):
			paths_ok = false
		var imp: Dictionary = e.get("import", {})
		if not (imp.has("filter") and imp.has("mipmaps") and imp.has("compression")):
			imports_ok = false
	check(dims_ok, "every entry width/height are positive ints")
	check(paths_ok, "every entry.path starts with res://assets/")
	check(imports_ok, "every import dict has filter/mipmaps/compression")

	for cid in AssetManifest.ASSET_CLASSES:
		check(not AssetManifest.asset_spec(cid).is_empty(), "asset_spec non-empty: " + cid)
		check(not AssetManifest.import_settings(cid).is_empty(), "import_settings non-empty: " + cid)
	check(AssetManifest.expected_path(entries[0]) == str(entries[0].get("path", "")), "expected_path matches entry.path")

	var disk: Dictionary = AssetManifest.check_disk()
	check(disk.size() == 8, "check_disk() returns 8 entries")
	for cid in AssetManifest.ASSET_CLASSES:
		check(not bool(disk.get(cid, true)), "check_disk()[" + cid + "] is false (no final asset on disk)")

	var report: Dictionary = AssetManifest.status_report()
	check(int(report["counts"]["final"]) == 0, "status counts.final == 0")
	check(int(report["counts"]["temporary"]) == 8, "status counts.temporary == 8")
	check(int(report["counts"]["missing"]) == 8, "status counts.missing == 8")
	check(int(report["total"]) == 8, "status total == 8")
	check((report["final"] as Array).is_empty(), "status final array is empty")

	var valid_sheet: Dictionary = AssetManifest.asset_spec("character_sprites")
	valid_sheet["class"] = "character_sprites"
	check(AssetManifest.validate_sheet_specs(valid_sheet).is_empty(), "a valid sheet spec passes validate_sheet_specs()", str(AssetManifest.validate_sheet_specs(valid_sheet)))
	var bad_w: Dictionary = valid_sheet.duplicate(true)
	bad_w["width"] = 100
	check(_has_error(AssetManifest.validate_sheet_specs(bad_w), "width"), "wrong width is reported")
	var bad_h: Dictionary = valid_sheet.duplicate(true)
	bad_h["height"] = 100
	check(_has_error(AssetManifest.validate_sheet_specs(bad_h), "height"), "wrong height is reported")
	var bad_anchor: Dictionary = valid_sheet.duplicate(true)
	bad_anchor["anchor"] = ""
	check(_has_error(AssetManifest.validate_sheet_specs(bad_anchor), "missing anchor"), "missing anchor is reported")
	var bad_trans: Dictionary = valid_sheet.duplicate(true)
	bad_trans["transparent"] = false
	check(_has_error(AssetManifest.validate_sheet_specs(bad_trans), "background must be transparent"), "transparent==false is reported")
	var bad_frames: Dictionary = valid_sheet.duplicate(true)
	bad_frames["frames"] = 3
	check(_has_error(AssetManifest.validate_sheet_specs(bad_frames), "frame layout"), "bad frame count is reported")
	var bad_fmt: Dictionary = valid_sheet.duplicate(true)
	bad_fmt["format"] = "JPEG"
	check(_has_error(AssetManifest.validate_sheet_specs(bad_fmt), "invalid format"), "invalid format is reported")

	var seams: Dictionary = AssetManifest.replacement_seams()
	check(seams.size() == 8, "replacement_seams() covers all 8 classes")
	for cid in AssetManifest.ASSET_CLASSES:
		check(not str(seams.get(cid, "")).is_empty(), "replacement_seams non-empty: " + cid)

	var expected_ids: Array = ["character_sprites", "character_portraits", "environment_tilesets", "buildings", "vegetation", "monster_sprites", "skill_effects", "ui_illustrations"]
	var all_ids := true
	for cid in expected_ids:
		if not AssetManifest.ASSET_CLASSES.has(cid):
			all_ids = false
	check(all_ids, "the 8 class ids cover sprites/portraits/tilesets/buildings/vegetation/monsters/vfx/UI")


# ---------------------------------- Phase 4: asset-loading fallback seam
## Verifies missing-disk graceful fallback, the base/procedural/demo frame
## sources, the 9x8 CAST-capable demo sheet, and ActorVisual's null-source
## fallback on an in-tree node. ASYNC: awaits process frames for the visual.
func _test_asset_loading_fallbacks() -> void:
	var missing_src := SpriteFramesActorSource.from_disk("definitely_missing_id") as SpriteFramesActorSource
	check(missing_src != null and is_instance_valid(missing_src), "from_disk() does not crash on a missing id")
	check(missing_src.has_frames() == false, "missing disk source has_frames() == false")
	check(missing_src.is_temporary() == true, "missing disk source is_temporary() == true")
	check(missing_src.frame(0, 0, 0) == null, "missing disk source frame() returns null")
	check(_has_error(missing_src.validate_sheets(), "no sprite sheet registered"), "missing disk source validate_sheets() reports the missing sheet")
	check(not missing_src.load_report().is_empty(), "missing disk source load_report() is non-empty")

	var base := ActorFrameSource.new()
	check(base.has_frames() == false, "base ActorFrameSource.has_frames() == false")
	check(base.is_temporary() == true, "base ActorFrameSource.is_temporary() == true")
	check(base.frame(0, 0, 0) == null, "base ActorFrameSource.frame() == null")
	check(not base.validate_sheets().is_empty(), "base ActorFrameSource.validate_sheets() is non-empty")

	var proc := ProceduralActorFrames.new({})
	check(proc.has_frames() == true, "ProceduralActorFrames.has_frames() == true")
	check(proc.is_temporary() == true, "ProceduralActorFrames.is_temporary() == true")
	var proc_all := true
	var proc_count := 0
	for raws in CharacterAnimator.EXTENDED_STATES:
		var s := int(raws)
		for rawd in CharacterAnimator.ALL_DIRECTIONS:
			proc_count += 1
			if proc.frame(s, int(rawd), 0) == null:
				proc_all = false
	check(proc_all, "ProceduralActorFrames.frame() non-null for all 9 states x 8 directions")
	check(proc_count == 72, "sampled all 9x8 (state,direction) addresses", str(proc_count))

	var demo := DemoCharacterFrames.new("player", {})
	check(demo.is_temporary() == true, "DemoCharacterFrames.is_temporary() == true")
	check(demo.has_frames() == true, "DemoCharacterFrames.has_frames() == true")
	var label := demo.source_label()
	check("temporary" in label or "demo" in label or "placeholder" in label, "DemoCharacterFrames.source_label() is clearly temporary", label)
	check(demo.loaded_from_disk == false, "DemoCharacterFrames.loaded_from_disk == false")
	check(demo.validate_sheets().is_empty(), "DemoCharacterFrames.validate_sheets() == []")
	check(int(demo.load_report().get("animation_count", 0)) == CharacterAnimator.EXTENDED_STATES.size() * CharacterAnimator.ALL_DIRECTIONS.size(), "demo animation count == 9 x 8")
	var demo_frames_ok := true
	for raws in CharacterAnimator.EXTENDED_STATES:
		var s := int(raws)
		for rawd in CharacterAnimator.ALL_DIRECTIONS:
			var tex: Texture2D = demo.frame(s, int(rawd), 0)
			if tex == null or tex.get_width() != 96 or tex.get_height() != 128:
				demo_frames_ok = false
	check(demo_frames_ok, "demo frame(state,dir,0) is non-null 96x128 for all 9x8")
	var demo_cast_ok := true
	for rawd in CharacterAnimator.ALL_DIRECTIONS:
		if demo.cast_frame(int(rawd), 0) == null:
			demo_cast_ok = false
	check(demo_cast_ok, "demo cast_frame(dir,0) is non-null for all 8 directions")

	var actor_visual_scene := load("res://scenes/characters/actor_visual.tscn") as PackedScene
	var av := actor_visual_scene.instantiate() as ActorVisual
	add_child(av)
	await get_tree().process_frame
	check(av.procedural_renderer is ActorProceduralRendererComponent and av.procedural_renderer.get_parent() == av, "ActorVisual owns and binds its procedural renderer component")
	check(av.procedural_renderer.monster_painter is ProceduralMonsterPainter and av.procedural_renderer.monster_painter.renderer == av.procedural_renderer and av.procedural_renderer.monster_painter.visual == av, "procedural renderer owns and binds its species painter")
	check(av.character_effects_component is ActorCharacterEffectsComponent and av.character_effects_component.get_parent() == av and av.character_effects_component.visual == av, "ActorVisual owns and binds its character-specific effects component")
	check(av.pose_component is ActorPoseComponent and av.pose_component.get_parent() == av, "ActorVisual owns and binds its pose component")
	check(av.sprite_component is ActorSpriteComponent and av.sprite_component.get_parent() == av, "ActorVisual owns and binds its sprite-presentation component")
	check(av.animation_component is CharacterAnimationComponent and av.animation_component.get_parent() == av, "ActorVisual delegates locomotion playback to its animation component")
	av.set_frame_source(ActorFrameSource.new())
	check(av.using_temporary_art == true, "ActorVisual with a frameless source stays temporary")
	check(is_instance_valid(av), "frameless set_frame_source() does not crash the visual")
	av.set_frame_source(null)
	check(av.frame_source != null and av.frame_source is ProceduralActorFrames, "set_frame_source(null) restores ProceduralActorFrames")
	check(av.frame_source.is_temporary() == true and av.using_temporary_art == true, "restored frame source is temporary")
	av.queue_free()
	await get_tree().process_frame


# ------------------------------- Phase 4: animation sheet validation
## Re-checks the frozen 8-state contract, the additive 9th CAST state, timing
## coherence, CAST frame generation/pixel distinctness, and in-tree play_cast().
## ASYNC: awaits a frame for the in-tree ActorVisual.
func _test_animation_sheet_validation() -> void:
	check(CharacterAnimator.ALL_STATES.size() == 8, "ALL_STATES.size() == 8 (compatibility)", str(CharacterAnimator.ALL_STATES.size()))
	check(CharacterAnimator.EXTENDED_STATES.size() == 9, "EXTENDED_STATES.size() == 9")
	var core_present := true
	for raw in CharacterAnimator.ALL_STATES:
		if not CharacterAnimator.EXTENDED_STATES.has(int(raw)):
			core_present = false
	check(core_present, "EXTENDED_STATES contains all 8 core states")
	check(CharacterAnimator.EXTENDED_STATES.has(CharacterAnimator.CAST_STATE), "EXTENDED_STATES contains CAST")
	check(CharacterAnimator.CAST_STATE == 8, "CAST_STATE == 8")

	var fc_ok := true
	var fps_ok := true
	var loop_ok := true
	var prio_ok := true
	for raw in CharacterAnimator.EXTENDED_STATES:
		var s := int(raw)
		if CharacterAnimator.frame_count_for(s) <= 0:
			fc_ok = false
		if not (CharacterAnimator.fps_for(s) > 0.0):
			fps_ok = false
		if typeof(CharacterAnimator.looping_for(s)) != TYPE_BOOL:
			loop_ok = false
		if CharacterAnimator.priority_for(s) <= 0:
			prio_ok = false
	check(fc_ok, "frame_count_for() > 0 for all 9 states")
	check(fps_ok, "fps_for() > 0 for all 9 states")
	check(loop_ok, "looping_for() returns bool for all 9 states")
	check(prio_ok, "priority_for() > 0 for all 9 states")
	check(CharacterAnimator.frame_count_for(8) == CharacterAnimator.CAST_FRAMES, "frame_count_for(8) == CAST_FRAMES")
	check(near(CharacterAnimator.fps_for(8), CharacterAnimator.CAST_FPS), "fps_for(8) == CAST_FPS")
	check(CharacterAnimator.looping_for(8) == false, "looping_for(8) == false")
	check(CharacterAnimator.priority_for(8) == CharacterAnimator.CAST_PRIORITY, "priority_for(8) == CAST_PRIORITY")
	check(CharacterAnimator.is_valid_state(8) == true, "is_valid_state(8) == true")
	check(CharacterAnimator.is_valid_state(-1) == false, "is_valid_state(-1) == false")
	check(CharacterAnimator.is_valid_state(99) == false, "is_valid_state(99) == false")
	check(CharacterAnimator.state_name(8) == "cast", "state_name(8) == 'cast'")
	var dn_ok := true
	for rawd in CharacterAnimator.ALL_DIRECTIONS:
		if CharacterAnimator.direction_name(int(rawd)).is_empty():
			dn_ok = false
	check(dn_ok, "direction_name() non-empty for all 8 directions")

	var S: Dictionary = GreenwardStyle.SPRITE_SPECS
	var timing_ok := true
	for raw in CharacterAnimator.ALL_STATES:
		var s := int(raw)
		if int((S["frame_counts"] as Array)[s]) != int(CharacterAnimator.STATE_FRAMES[s]):
			timing_ok = false
		if not near(float((S["fps_values"] as Array)[s]), float(CharacterAnimator.STATE_FPS[s])):
			timing_ok = false
		if bool((S["loop_flags"] as Array)[s]) != bool(CharacterAnimator.STATE_LOOPING[s]):
			timing_ok = false
	check(timing_ok, "SPRITE_SPECS timing arrays still match CharacterAnimator for the 8 core states")
	check(GreenwardStyle.coherence_report().is_empty(), "GreenwardStyle.coherence_report() == []")
	check(not (GreenwardStyle.CAST_SPEC as Dictionary).is_empty(), "GreenwardStyle.CAST_SPEC is non-empty")

	var cf0: Texture2D = ProceduralArt.character_frame({}, 8, 0, 0)
	check(cf0 != null, "character_frame({},8,0,0) is non-null")
	check(ProceduralArt.character_frame({}, 8, 0, 0) == cf0, "character_frame() is cached")
	var cf_dims_ok := true
	for rawd in CharacterAnimator.ALL_DIRECTIONS:
		var t: Texture2D = ProceduralArt.character_frame({}, 8, int(rawd), 0)
		if t == null or t.get_width() != 96 or t.get_height() != 128:
			cf_dims_ok = false
	check(cf_dims_ok, "CAST frame(8,dir,0) is 96x128 for all 8 directions")
	check(cf0.get_image().get_data() != ProceduralArt.character_frame({}, 8, 4, 0).get_image().get_data(), "CAST frames differ by direction")
	check(cf0.get_image().get_data() != ProceduralArt.character_frame({}, 8, 0, 1).get_image().get_data(), "CAST frames differ by frame index")
	check(cf0.get_image().get_data() != ProceduralArt.character_frame({}, 0, 0, 0).get_image().get_data(), "CAST frame differs from state 0 frame")

	var paf := ProceduralActorFrames.new({})
	var cast_fc_ok := true
	for rawd in CharacterAnimator.ALL_DIRECTIONS:
		if paf.cast_frame_count(int(rawd)) != CharacterAnimator.CAST_FRAMES:
			cast_fc_ok = false
	check(cast_fc_ok, "ProceduralActorFrames.cast_frame_count() == CAST_FRAMES for all dirs")
	check(near(paf.cast_fps(), CharacterAnimator.CAST_FPS), "ProceduralActorFrames.cast_fps() == CAST_FPS")
	check(paf.cast_frame(0, 0) != null, "ProceduralActorFrames.cast_frame(0,0) is non-null")

	var ext: Dictionary = ActorFrameSource.new().extended_specs()
	check((ext.get("extended_states", []) as Array).size() == 9, "extended_specs() lists 9 extended states")
	check(ext.has("cast") and str((ext.get("cast", {}) as Dictionary).get("name", "")) == "cast", "extended_specs() exposes CAST info")

	var actor_visual_scene := load("res://scenes/characters/actor_visual.tscn") as PackedScene
	var av := actor_visual_scene.instantiate() as ActorVisual
	add_child(av)
	await get_tree().process_frame
	check(av.animator != null, "in-tree ActorVisual has an animator")
	av.play_cast()
	check(av.animator.state == CharacterAnimator.CAST_STATE, "ActorVisual.play_cast() sets animator state to CAST")
	check(av.animator.cast_active(), "play_cast() leaves cast_active() true")
	check(is_instance_valid(av), "play_cast() does not crash the visual")
	av.queue_free()
	await get_tree().process_frame


# ---------------------------------- Phase 4: animation transitions/CAST
## Pure CharacterAnimator transition tests: play_cast, transition_to signal/
## previous_state, can_transition priority, finish_and_return, one-shot return,
## 8-way direction, CAST ticking, snapshot round-trip and determinism.
func _test_animation_transitions() -> void:
	var a := CharacterAnimator.new()
	check(a.play_cast() == true, "play_cast() returns true on a real change")
	check(a.state == CharacterAnimator.CAST_STATE, "play_cast() sets state to CAST")
	check(a.cast_active() == true, "cast_active() true while casting")

	_phase4_transition_count = 0
	var b := CharacterAnimator.new()
	b.transitioned.connect(_phase4_on_transitioned)
	check(b.transition_to(CharacterAnimator.State.WALK) == true, "transition_to() returns true on a real change")
	check(b.previous_state == CharacterAnimator.State.IDLE, "transition_to() records previous_state")
	check(_phase4_transition_count == 1, "transitioned emitted exactly once on the first change")
	check(b.transition_to(CharacterAnimator.State.WALK) == false, "transition_to() returns false on a no-change")
	check(_phase4_transition_count == 1, "transitioned NOT emitted again on a no-change")
	check(b.transition_to(CharacterAnimator.State.RUN) == true, "transition_to() to RUN changes state")
	check(b.previous_state == CharacterAnimator.State.WALK, "previous_state updates on the next change")
	check(_phase4_transition_count == 2, "transitioned emitted once per real change (total 2)")

	check(CharacterAnimator.can_transition(CharacterAnimator.CAST_STATE, CharacterAnimator.State.IDLE) == false, "lower-priority IDLE cannot interrupt CAST")
	check(CharacterAnimator.can_transition(CharacterAnimator.CAST_STATE, CharacterAnimator.State.DAMAGE) == true, "higher-priority DAMAGE can interrupt CAST")
	check(CharacterAnimator.can_transition(CharacterAnimator.State.IDLE, CharacterAnimator.State.ATTACK) == true, "locomotion IDLE can transition freely")
	check(CharacterAnimator.can_transition(CharacterAnimator.State.ATTACK, CharacterAnimator.State.IDLE) == false, "lower-priority target cannot interrupt an ATTACK one-shot")
	check(CharacterAnimator.can_transition(-1, CharacterAnimator.State.IDLE) == false, "can_transition() rejects an invalid source")

	for raw_key in CharacterAnimator.RETURN_STATES.keys():
		var s := int(raw_key)
		var anim := CharacterAnimator.new()
		anim.play_forced(s)
		var expected := int(CharacterAnimator.RETURN_STATES[raw_key])
		check(anim.finish_and_return() == expected and anim.state == expected, "finish_and_return(%d) -> %d" % [s, expected])
	var cast_anim := CharacterAnimator.new()
	cast_anim.play_cast()
	check(cast_anim.finish_and_return() == CharacterAnimator.State.IDLE, "CAST finish_and_return() returns IDLE")
	check(cast_anim.is_looping(), "CAST finish_and_return() restores a looping state")
	check(cast_anim.previous_state == CharacterAnimator.CAST_STATE, "finish_and_return() records previous_state = CAST")

	var atk := CharacterAnimator.new()
	atk.play_forced(CharacterAnimator.State.ATTACK)
	var elapsed := 0.0
	while elapsed < 2.0:
		atk.tick(0.1)
		elapsed += 0.1
	check(atk.is_finished(), "ATTACK one-shot reaches is_finished()")
	check(atk.finish_and_return() == CharacterAnimator.State.IDLE and atk.state == CharacterAnimator.State.IDLE, "finished ATTACK returns to IDLE locomotion")

	var prio := CharacterAnimator.new()
	prio.play_forced(CharacterAnimator.State.DEFEAT)
	check(prio.play(CharacterAnimator.State.ATTACK) == false, "play() blocked during an unfinished higher-priority one-shot")
	check(prio.state == CharacterAnimator.State.DEFEAT, "blocked play() leaves state unchanged")
	prio.play_forced(CharacterAnimator.State.IDLE)
	check(prio.state == CharacterAnimator.State.IDLE, "play_forced() bypasses priority")
	var pcast := CharacterAnimator.new()
	pcast.play_cast()
	check(pcast.play(CharacterAnimator.State.IDLE) == false and pcast.state == CharacterAnimator.CAST_STATE, "lower-priority play() cannot interrupt an unfinished CAST")

	var dv := CharacterAnimator.new()
	var dir_cases: Array = [
		[Vector2(1, 0), CharacterAnimator.Direction.RIGHT],
		[Vector2(1, 1), CharacterAnimator.Direction.DOWN_RIGHT],
		[Vector2(0, 1), CharacterAnimator.Direction.DOWN],
		[Vector2(-1, 1), CharacterAnimator.Direction.DOWN_LEFT],
		[Vector2(-1, 0), CharacterAnimator.Direction.LEFT],
		[Vector2(-1, -1), CharacterAnimator.Direction.UP_LEFT],
		[Vector2(0, -1), CharacterAnimator.Direction.UP],
		[Vector2(1, -1), CharacterAnimator.Direction.UP_RIGHT],
	]
	var dir_match := 0
	var dir_set := {}
	for case in dir_cases:
		var vec: Vector2 = case[0]
		var expected_dir := int(case[1])
		if dv.set_direction_from_vector(vec) == expected_dir:
			dir_match += 1
		dir_set[expected_dir] = true
	check(dir_match == 8, "set_direction_from_vector maps all 8 directions", "%d/8" % dir_match)
	check(dir_set.size() == 8, "the 8 vectors cover 8 distinct directions")

	var demo := DemoCharacterFrames.new("player", {})
	var addr_ok := true
	for raws in [CharacterAnimator.State.IDLE, CharacterAnimator.State.WALK, CharacterAnimator.State.RUN]:
		var s := int(raws)
		for rawd in CharacterAnimator.ALL_DIRECTIONS:
			var tex: Texture2D = demo.frame(s, int(rawd), 0)
			if tex == null or tex.get_width() != 96 or tex.get_height() != 128:
				addr_ok = false
	check(addr_ok, "IDLE/WALK/RUN frame(s,d,0) is 96x128 in all 8 directions (DemoCharacterFrames)")

	var ticker := CharacterAnimator.new()
	ticker.play_cast()
	check(near(ticker.fps(), CharacterAnimator.CAST_FPS), "CAST ticks at CAST_FPS")
	check(ticker.is_looping() == false, "CAST is non-looping")
	var start_frame := ticker.frame
	ticker.tick(0.1)
	check(ticker.frame > start_frame, "tick() advances CAST frames")
	var guard := 0
	while not ticker.is_finished() and guard < 100:
		ticker.tick(0.2)
		guard += 1
	check(ticker.is_finished(), "CAST one-shot reaches is_finished()")
	check(ticker.frame == CharacterAnimator.CAST_FRAMES - 1, "CAST clamps to the last frame")

	var snap_a := CharacterAnimator.new()
	snap_a.play_cast()
	snap_a.tick(0.09)
	snap_a.set_direction(CharacterAnimator.Direction.UP_LEFT)
	var snap: Dictionary = snap_a.snapshot()
	var snap_b := CharacterAnimator.from_snapshot(snap)
	check(snap == snap_b.snapshot(), "snapshot()/from_snapshot() round-trip including CAST")
	check(snap_b.state == CharacterAnimator.CAST_STATE, "round-trip preserves CAST state")
	check(snap_b.cast_active(), "round-tripped animator is cast_active")

	var d1 := CharacterAnimator.new()
	var d2 := CharacterAnimator.new()
	_phase4_drive_anim(d1)
	_phase4_drive_anim(d2)
	check(d1.snapshot() == d2.snapshot(), "identical call sequences produce identical snapshots (incl. CAST)")


# ------------------------------------------ Phase 4: chunk preparer
## Pure bounded LRU ChunkPreparer: request dedupe, pending/sentinel, store/take/
## peek/evict/clear, capacity eviction order, stats and determinism. Also
## re-asserts ChunkStreamer behaviour and GreenwardStyle's prop cap are unchanged.
func _test_chunk_preparer() -> void:
	var p := ChunkPreparer.new(3)
	check(p != null and p is RefCounted, "ChunkPreparer.new(3) is a RefCounted (pure, no nodes)")

	p.request(Vector2i(0, 0))
	p.request(Vector2i(0, 0))
	check(p.pending_count() == 1, "request() dedupes identical coords")
	p.request_many([Vector2i(1, 0), Vector2i(1, 0), Vector2i(2, 0)])
	check(p.pending_count() == 3, "request_many() dedupes and appends", str(p.pending_count()))

	var first: Variant = p.next_pending()
	check(first == Vector2i(0, 0), "next_pending() returns the first queued coord")
	var drained := 0
	while p.pending_count() > 0:
		p.next_pending()
		drained += 1
	check(drained == 2, "next_pending() drains the remaining queue", str(drained))
	check(p.next_pending() == Vector2i(2147483647, 2147483647), "next_pending() returns the EMPTY_COORD sentinel when empty")
	check(p.next_pending() == ChunkPreparer.EMPTY_COORD, "sentinel equals ChunkPreparer.EMPTY_COORD")

	var data := { "terrain": "opaque", "n": 42 }
	p.store(Vector2i(5, 5), data)
	check(p.has_prepared(Vector2i(5, 5)), "has_prepared() true after store()")
	check(p.peek(Vector2i(5, 5)) == data, "peek() returns the stored opaque Dictionary")
	var taken: Variant = p.take(Vector2i(5, 5))
	check(taken == data, "take() returns the stored data")
	check(not p.has_prepared(Vector2i(5, 5)), "take() removes the entry")
	check(p.take(Vector2i(5, 5)) == null, "take() on a missing coord returns null")

	p.store(Vector2i(6, 6), {})
	p.evict(Vector2i(6, 6))
	check(not p.has_prepared(Vector2i(6, 6)), "evict() removes the entry")

	p.clear()
	check(p.pending_count() == 0 and p.stats()["cached"] == 0, "clear() resets pending + cache")

	for i in 5:
		p.store(Vector2i(i, 0), { "i": i })
	check(p.stats()["cached"] <= 3, "bounded capacity: cached <= 3", str(p.stats()["cached"]))
	check(p.stats()["cached"] == 3, "bounded capacity: cached == 3")
	check(not p.has_prepared(Vector2i(0, 0)) and not p.has_prepared(Vector2i(1, 0)), "the oldest coords are evicted")
	check(p.has_prepared(Vector2i(2, 0)) and p.has_prepared(Vector2i(3, 0)) and p.has_prepared(Vector2i(4, 0)), "the 3 newest coords survive")
	p.store(Vector2i(2, 0), { "i": 2 })
	p.store(Vector2i(5, 0), { "i": 5 })
	check(p.has_prepared(Vector2i(2, 0)) and not p.has_prepared(Vector2i(3, 0)), "LRU order is deterministic after a touch")

	var st: Dictionary = p.stats()
	check(st.has("pending") and st.has("cached") and st.has("capacity"), "stats() exposes pending/cached/capacity")
	check(int(st["capacity"]) == 3, "stats().capacity == 3")

	var q := ChunkPreparer.new(3)
	for i in 5:
		q.store(Vector2i(i, 0), { "i": i })
	q.store(Vector2i(2, 0), { "i": 2 })
	q.store(Vector2i(5, 0), { "i": 5 })
	check(p.stats() == q.stats(), "identical operations produce identical stats()")

	var streamer := ChunkStreamer.new(16, 2)
	check(streamer.needed_chunks(Vector2.ZERO).size() == 25, "ChunkStreamer radius 2 needs 25 chunks (unchanged)")
	check(streamer.needed_chunks(Vector2.ZERO)[0] == Vector2i(0, 0), "ChunkStreamer centre chunk is first (unchanged)")
	check(GreenwardStyle.MAX_PROPS_PER_CHUNK > 0, "GreenwardStyle.MAX_PROPS_PER_CHUNK > 0")


# ------------------------------- Phase 4: world region integration
## ASYNC: explicitly load the legacy Greenward world, verify its presentation
## and RegionPortal, then briefly build a second GreenwardWorld for
## moonpetal_hollow. This stays independent of the new-journey start world.
func _test_world_region_integration() -> void:
	var original_state: Dictionary = GameState._to_dict().duplicate(true)
	var original_loaded: bool = GameState.loaded_from_save
	GameState.set_active_world("greenward")
	GameState.loaded_from_save = true
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	check(game_scene != null, "game.tscn loads for region integration")
	if game_scene == null:
		GameState._load_from_dict(original_state)
		GameState.loaded_from_save = original_loaded
		return
	var game := game_scene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	check(game.world != null, "game.world is created")
	check(game.hud != null, "game.hud is created")
	check(game.world.player != null, "world.player is created")
	check(game.current_region_id == "greenward", "game.current_region_id == greenward", game.current_region_id)
	check(game.world.region_id == "greenward", "world.region_id == greenward")
	check(game.world.current_area_name() != "", "world.current_area_name() non-empty")
	check(game.world.current_zone() != "", "world.current_zone() non-empty")
	check(game.world.region_display_name() != "", "world.region_display_name() non-empty")
	check(game.world.loaded_chunks.size() > 0, "world.loaded_chunks.size() > 0", str(game.world.loaded_chunks.size()))
	var report: Dictionary = game.world.visual_style_report()
	check(not report.is_empty(), "visual_style_report() non-empty")
	for key in ["region_id", "region_name", "zone", "entry_points", "connections", "world_origin", "portals"]:
		check(report.has(key), "visual_style_report() has NEW key: " + str(key))
	check(game.world.region_graph().validate().is_empty(), "world.region_graph().validate() == []")

	var portal_count := 0
	for child in game.world.entities.get_children():
		if child is RegionPortal:
			portal_count += 1
	check(portal_count > 0, "at least one RegionPortal exists in world.entities", str(portal_count))
	check(game.world._portals.size() > 0, "world._portals tracks the spawned gates")

	var w2 := load("res://scenes/world/greenward_world.tscn").instantiate() as GreenwardWorld
	w2.region_id = "moonpetal_hollow"
	w2.entry_point = "hollow_gate"
	add_child(w2)
	await get_tree().process_frame
	await get_tree().process_frame
	check(w2.player != null, "second world creates a player")
	check(w2.current_area_name() != "", "second world reports an area name")
	check(w2.loaded_chunks.size() > 0, "second world loads chunks", str(w2.loaded_chunks.size()))
	check("Moonpetal" in w2.region_display_name(), "second world display name contains 'Moonpetal'", w2.region_display_name())
	check(w2.current_zone() != "", "second world reports a zone")
	check(w2.visual_style_report().get("region_id", "") == "moonpetal_hollow", "second world report region_id == moonpetal_hollow")
	check(is_instance_valid(w2), "second world built without crashing")
	var liora_found := false
	for npc in w2.npcs:
		if npc.npc_id == "moonkeeper_liora":
			liora_found = true
	check(liora_found, "Moonpetal Hollow spawns Moonkeeper Liora")
	var moonpetal_encounter_found := false
	for entity in w2.entities.get_children():
		if entity is RoamingMonster and entity.group_id == "moonpetal_echoes_pack":
			moonpetal_encounter_found = true
	check(moonpetal_encounter_found, "Moonpetal Hollow spawns its Silver Pool encounter")
	w2.queue_free()
	await get_tree().process_frame

	game.queue_free()
	await get_tree().process_frame
	GameState._load_from_dict(original_state)
	GameState.loaded_from_save = original_loaded


# ------------------------------------ Phase 4: procedural art additions
## Verifies >=53 prop kinds, the 6 new landmark kinds (variants, distinct
## pixels, palettes, coherence), PROP_TYPES parity, caching, and lazy
## regeneration after clear_all_caches(). Texture generation stays BOUNDED.
func _test_procedural_art_phase4() -> void:
	var kinds: Array[String] = ProceduralArt.prop_kinds()
	check(kinds.size() >= 53, "ProceduralArt.prop_kinds().size() >= 53", str(kinds.size()))
	var new_kinds: Array[String] = ["watchtower", "market_stall", "stone_wall", "gazebo", "banner_post", "moon_shrine"]
	var kset := {}
	for k in kinds:
		kset[k] = true
	var all_new_present := true
	for k in new_kinds:
		if not kset.has(k):
			all_new_present = false
	check(all_new_present, "all 6 new Phase-4 prop kinds are present")
	for k in new_kinds:
		check(ProceduralArt.variant_count(k) >= 2, "variant_count >= 2: " + k, str(ProceduralArt.variant_count(k)))
	for k in new_kinds:
		check(ProceduralArt.prop_texture(k, 0) != null, "prop_texture(kind,0) non-null: " + k)
	for k in new_kinds:
		var v0: Texture2D = ProceduralArt.prop_texture(k, 0)
		var v1: Texture2D = ProceduralArt.prop_texture(k, 1)
		check(v0.get_image().get_data() != v1.get_image().get_data(), "variant 0/1 pixels differ: " + k)

	var all_nonnull := true
	var sampled := 0
	for k in kinds:
		sampled += 1
		if ProceduralArt.prop_texture(k, 0) == null:
			all_nonnull = false
	check(all_nonnull, "prop_texture(kind,0) non-null for all kinds", str(sampled))
	check(sampled == kinds.size(), "sampled every prop kind", str(sampled))
	check(ProceduralArt.prop_texture("watchtower", 0) == ProceduralArt.prop_texture("watchtower", 0), "prop_texture() is cached")

	check(ContentValidator.PROP_TYPES.size() >= 53, "ContentValidator.PROP_TYPES.size() >= 53", str(ContentValidator.PROP_TYPES.size()))
	for k in new_kinds:
		check(ContentValidator.PROP_TYPES.has(k), "PROP_TYPES includes: " + k)

	for k in new_kinds:
		check(not GreenwardStyle.prop_palette(k).is_empty(), "prop_palette() non-empty: " + k)
	check(GreenwardStyle.coherence_report().is_empty(), "GreenwardStyle.coherence_report() == []")

	var before: Texture2D = ProceduralArt.prop_texture("watchtower", 0)
	var before_char: Texture2D = ProceduralArt.character_frame({}, 8, 0, 0)
	check(before != null and before_char != null, "baseline textures exist before cache clear")
	ProceduralArt.clear_all_caches()
	check(ProceduralArt.prop_texture("watchtower", 0) != null, "prop_texture() regenerates after clear_all_caches()")
	check(ProceduralArt.character_frame({}, 8, 0, 0) != null, "character_frame() regenerates after clear_all_caches()")
	check(ProceduralArt.prop_texture("watchtower", 0) != before, "clear_all_caches() drops cached texture objects (lazy regen)")


# ===================================================================== Phase 5
# Phase 5 shared helpers. Prefixed _phase5_ to avoid collisions with the
# Phase-2/3/4 helpers. Pure data / headless-safe; never writes to res://.


## The 12 canonical Phase-5 character ids.
func _phase5_ids() -> Array[String]:
	return CharacterArtSpec.ids()


## The 10 canonical Phase-5 production asset-kind ids.
func _phase5_kinds() -> Array[String]:
	return CharacterArtPipeline.kinds()


## Build a fully-valid validate_asset() candidate directly from spec(kind).
func _phase5_valid_candidate(kind: String) -> Dictionary:
	var s: Dictionary = CharacterArtPipeline.spec(kind)
	return {
		"width": int(s.get("width", 0)),
		"height": int(s.get("height", 0)),
		"anchor": str(s.get("anchor", "")),
		"transparent": true,
		"frames": int(s.get("frames", 0)),
		"format": str(s.get("format", "")),
		"naming": "lyra_vey/%s.%s" % [kind, str(s.get("extension", "png"))],
	}


## True when a pipeline spec carries every required field with a sane value.
func _phase5_spec_fields_ok(s: Dictionary) -> bool:
	if s.is_empty():
		return false
	if int(s.get("width", 0)) <= 0 or int(s.get("height", 0)) <= 0:
		return false
	if str(s.get("anchor", "")).strip_edges().is_empty():
		return false
	if not bool(s.get("transparent", false)):
		return false
	if int(s.get("frames", 0)) <= 0:
		return false
	var imp: Variant = s.get("import", null)
	if not (imp is Dictionary) or (imp as Dictionary).is_empty():
		return false
	if str(s.get("naming", "")).strip_edges().is_empty():
		return false
	if str(s.get("seam", "")).strip_edges().is_empty():
		return false
	return true


## True when NO final .png/.webp/.tres file exists for a (character, kind) stem.
func _phase5_no_final_image(char_id: String, kind: String) -> bool:
	var stem := "res://assets/characters/%s/%s" % [char_id, kind]
	for ext in ["png", "webp", "tres"]:
		if FileAccess.file_exists("%s.%s" % [stem, ext]):
			return false
	return true


## Synthetic ImageTexture of a given size/format, filled fully transparent.
func _phase5_image_texture(width: int, height: int, fmt: int) -> ImageTexture:
	var img := Image.create(width, height, false, fmt)
	img.fill(Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------ Phase 5 / group 1
## CharacterArtPipeline: the ten-kind production contract, the 9x8 sheet
## layout, 72 animation names, self-check, spec-built valid candidates and
## precise errors for every invalid candidate / an unknown kind.
func _test_character_art_pipeline() -> void:
	var kinds: Array[String] = _phase5_kinds()
	check(kinds.size() >= 10, "pipeline kinds().size() >= 10", str(kinds.size()))
	var expected_kinds: Array[String] = [
		"full_body_illustration", "character_portrait", "combat_sprite",
		"movement_sheet", "attack_sheet", "cast_sheet", "skill_vfx",
		"ultimate_vfx", "victory_sheet", "defeat_sheet",
	]
	for k in expected_kinds:
		check(CharacterArtPipeline.ASSET_KINDS.has(k), "ASSET_KINDS covers: " + k)
	for k in kinds:
		check(_phase5_spec_fields_ok(CharacterArtPipeline.spec(k)), "spec(k) complete & sane: " + k)
	for k in kinds:
		check(not CharacterArtPipeline.import_settings(k).is_empty(), "import_settings(k) non-empty: " + k)

	var layout: Dictionary = CharacterArtPipeline.sheet_layout()
	check(int(layout.get("state_count", 0)) == 9, "sheet_layout state_count == 9")
	check(int(layout.get("direction_count", 0)) == 8, "sheet_layout direction_count == 8")
	var per_state: Dictionary = layout.get("per_state", {})
	var grid: Dictionary = layout.get("grid", {})
	check(per_state.size() == 9, "sheet_layout per_state covers 9 states")
	check(grid.size() == 9, "sheet_layout grid covers 9 states")
	var coverage_ok := true
	for st in per_state.keys():
		var entry: Dictionary = per_state[st]
		var anims: Array = entry.get("animations", [])
		var cols: Array = grid.get(st, [])
		if anims.size() != 8 or cols.size() != 8:
			coverage_ok = false
	check(coverage_ok, "sheet_layout covers 9 states x 8 directions")

	check(CharacterArtPipeline.animation_names().size() == 72, "animation_names().size() == 72")
	check(not CharacterArtPipeline.naming_examples().is_empty(), "naming_examples() non-empty")
	check(not CharacterArtPipeline.replacement_seams().is_empty(), "replacement_seams() non-empty")
	check(not CharacterArtPipeline.summary().is_empty(), "summary() non-empty")
	check(CharacterArtPipeline.self_check().is_empty(), "self_check() == []", str(CharacterArtPipeline.self_check()))

	for k in kinds:
		var errs: Array[String] = CharacterArtPipeline.validate_asset(k, _phase5_valid_candidate(k))
		check(errs.is_empty(), "validate_asset(k, spec-built candidate) == []: " + k, str(errs))
	var ex: Dictionary = CharacterArtPipeline.example_candidate("movement_sheet")
	check(not ex.is_empty(), "example_candidate('movement_sheet') present")
	check(CharacterArtPipeline.validate_asset("movement_sheet", ex).is_empty(), "example_candidate() itself validates")

	var base: Dictionary = _phase5_valid_candidate("movement_sheet")
	var bad_w: Dictionary = base.duplicate(true)
	bad_w["width"] = 1
	check(_has_error(CharacterArtPipeline.validate_asset("movement_sheet", bad_w), "width"), "wrong width reported")
	var bad_h: Dictionary = base.duplicate(true)
	bad_h["height"] = 1
	check(_has_error(CharacterArtPipeline.validate_asset("movement_sheet", bad_h), "height"), "wrong height reported")
	var bad_a: Dictionary = base.duplicate(true)
	bad_a.erase("anchor")
	check(_has_error(CharacterArtPipeline.validate_asset("movement_sheet", bad_a), "anchor"), "missing anchor reported")
	var bad_t: Dictionary = base.duplicate(true)
	bad_t["transparent"] = false
	check(_has_error(CharacterArtPipeline.validate_asset("movement_sheet", bad_t), "transparent"), "transparent==false reported")
	var bad_f: Dictionary = base.duplicate(true)
	bad_f["frames"] = 1
	check(_has_error(CharacterArtPipeline.validate_asset("movement_sheet", bad_f), "frame"), "wrong frame count reported")
	var bad_fmt: Dictionary = base.duplicate(true)
	bad_fmt["format"] = "opaque jpeg"
	check(_has_error(CharacterArtPipeline.validate_asset("movement_sheet", bad_fmt), "invalid format"), "invalid format reported")
	check(_has_error(CharacterArtPipeline.validate_asset("unknown_kind_xyz", base), "unknown asset kind"), "UNKNOWN kind reported")


# ------------------------------------------------------ Phase 5 / group 2
## CharacterArtSpec: 12 authored specs cross-checked against characters.json
## (identity + 5-colour palette), distinct per-kind prompts, the 9-state
## animation contract, distinct premium tiers and the 12 on-disk SPEC.md files.
func _test_character_art_specs() -> void:
	var ids: Array[String] = _phase5_ids()
	check(ids.size() == 12, "CharacterArtSpec.ids().size() == 12", str(ids.size()))
	check(CharacterArtSpec.all().size() == 12, "CharacterArtSpec.all().size() == 12")
	check(CharacterArtSpec.validate_specs().is_empty(), "validate_specs() == []", str(CharacterArtSpec.validate_specs()))
	check(CharacterArtSpec.identity_table().size() == 12, "identity_table() has 12 entries")
	check(not CharacterArtSpec.STYLE_ANCHOR.strip_edges().is_empty(), "STYLE_ANCHOR non-empty")
	check(CharacterArtSpec.STYLE_ANCHOR == CharacterArtPromptBuilder.STYLE_ANCHOR, "CharacterArtSpec shares the dedicated prompt builder style anchor")
	check(CharacterArtSpec.for_id("nonexistent_character") == null, "for_id(unknown) returns null safely")

	var required_keys: Array[String] = [
		"id", "display_name", "title", "race", "element", "rarity", "role",
		"physical_appearance", "hair_style", "hair_color", "outfit", "accessories",
		"weapon", "personality", "visual_theme", "palette", "animation_requirements",
		"portrait_requirements", "generation_prompt", "portrait_prompt", "sheet_prompt",
	]
	var palette_keys: Array[String] = ["hair", "primary", "secondary", "accent", "skin"]
	var states: Array[String] = ["idle", "walk", "run", "interact", "attack", "damage", "victory", "defeat", "cast"]
	var themes: Dictionary = {}
	var premium_notes: Dictionary = {}
	var docs_ok := true

	for cid in ids:
		var spec = CharacterArtSpec.for_id(cid)
		check(spec != null, "for_id() non-null: " + cid)
		if spec == null:
			continue
		var d: Dictionary = spec.call("to_dict") as Dictionary
		check(CharacterArtPromptBuilder.full_body_prompt(d) == str(d.get("generation_prompt", "")), "full-body prompt builder preserves spec output: " + cid)
		check(CharacterArtPromptBuilder.portrait_prompt(d) == str(d.get("portrait_prompt", "")), "portrait prompt builder preserves spec output: " + cid)
		check(CharacterArtPromptBuilder.sheet_prompt(d) == str(d.get("sheet_prompt", "")), "sprite-sheet prompt builder preserves spec output: " + cid)
		check(CharacterArtPromptBuilder.vfx_prompt(d) == str(spec.call("prompt_for", "vfx")), "VFX prompt builder preserves spec output: " + cid)
		var keys_ok := true
		var fields_ok := true
		for key in required_keys:
			if not d.has(key):
				keys_ok = false
			var v: Variant = d.get(key, null)
			if v == null:
				fields_ok = false
			elif v is String and str(v).strip_edges().is_empty():
				fields_ok = false
			elif v is Dictionary and (v as Dictionary).is_empty():
				fields_ok = false
		check(keys_ok, "to_dict() has all required keys: " + cid)
		check(fields_ok, "every required field non-empty: " + cid)

		var def: CharacterDef = ContentDB.get_character(cid)
		var identity_ok := def != null
		if def != null:
			identity_ok = (str(d.get("display_name", "")) == def.display_name
				and str(d.get("title", "")) == def.title
				and str(d.get("race", "")) == def.race
				and str(d.get("element", "")) == def.element
				and str(d.get("rarity", "")) == def.rarity
				and str(d.get("role", "")) == def.role)
		check(identity_ok, "identity fields equal ContentDB: " + cid)
		var pal_ok := def != null
		if def != null:
			var spec_pal: Dictionary = d.get("palette", {})
			for pk in palette_keys:
				if str(spec_pal.get(pk, "")) != str(def.palette.get(pk, "")):
					pal_ok = false
		check(pal_ok, "palette's 5 hex keys match characters.json: " + cid)

		var prompts: Array = [
			str(spec.call("prompt_for", "full_body")),
			str(spec.call("prompt_for", "portrait")),
			str(spec.call("prompt_for", "sheet")),
			str(spec.call("prompt_for", "vfx")),
		]
		var prompts_ok := true
		var distinct_prompts: Dictionary = {}
		for p in prompts:
			var ps := str(p)
			if ps.strip_edges().is_empty():
				prompts_ok = false
			distinct_prompts[ps] = true
		check(prompts_ok and distinct_prompts.size() == 4, "4 prompts non-empty & distinct: " + cid)

		var anims: Array = spec.call("required_animations") as Array
		var anim_ok := anims.size() == 72
		for st in states:
			var count := 0
			for a in anims:
				if str(a).begins_with(st + "_"):
					count += 1
			if count != 8:
				anim_ok = false
		check(anim_ok, "required_animations() covers all 9 states: " + cid)
		check(not (d.get("portrait_requirements", {}) as Dictionary).is_empty(), "portrait_requirements non-empty: " + cid)

		var rar := str(d.get("rarity", ""))
		var tier := str(d.get("tier_note", ""))
		if rar == "legendary" or rar == "mythic":
			check(not tier.strip_edges().is_empty(), "distinct premium tier described: " + cid)
			premium_notes[tier] = true
		else:
			check(tier.strip_edges().is_empty(), "standard tier has no premium note: " + cid)
		themes[str(d.get("visual_theme", ""))] = true
		if not FileAccess.file_exists("res://assets/characters/%s/SPEC.md" % cid):
			docs_ok = false

	check(themes.size() >= 10, "visual_theme strings have >= 10 distinct values", str(themes.size()))
	check(premium_notes.size() >= 2, "premium tier descriptions are distinct", str(premium_notes.size()))
	check(docs_ok, "all 12 res://assets/characters/<id>/SPEC.md exist")
	var ignis_spec = CharacterArtSpec.for_id("ignis")
	check(str(ignis_spec.call("prompt_for", "unknown_kind")) == "", "prompt_for(unknown kind) == ''")


# ------------------------------------------------------ Phase 5 / group 3
## CharacterAssetRegistry: 120 honest entries, zero FINAL assets, and the
## untouched Phase-4 AssetManifest 0/8/8 regression contract.
func _test_character_asset_registry() -> void:
	var ids: Array[String] = CharacterAssetRegistry.character_ids()
	var kinds: Array[String] = CharacterAssetRegistry.kinds()
	check(ids.size() == 12, "character_ids().size() == 12")
	check(kinds.size() >= 10, "kinds().size() >= 10", str(kinds.size()))
	var entries: Array[Dictionary] = CharacterAssetRegistry.entries()
	check(entries.size() == 120, "entries().size() == 120 (12 x 10)", str(entries.size()))
	var per_id_ok := true
	for cid in ids:
		if CharacterAssetRegistry.entries_for(cid).size() != kinds.size():
			per_id_ok = false
	check(per_id_ok, "entries_for(id).size() == kinds().size() for all 12")

	var path_ok := true
	var never_final := true
	for cid in ids:
		for k in kinds:
			var path: String = CharacterAssetRegistry.expected_path(cid, k)
			if not path.begins_with("res://assets/characters/") or not (cid in path):
				path_ok = false
			if CharacterAssetRegistry.status_for(cid, k) == "final":
				never_final = false
	check(path_ok, "expected_path(id,k) starts with res://assets/characters/ and contains id")
	check(never_final, "status_for(id,k) is never 'final' across all 120")

	var disk: Dictionary = CharacterAssetRegistry.check_disk()
	check(disk.size() == 120, "check_disk().size() == 120", str(disk.size()))
	var all_false := true
	for key in disk.keys():
		if bool(disk[key]):
			all_false = false
	check(all_false, "check_disk() is false for all 120 entries")

	var report: Dictionary = CharacterAssetRegistry.report()
	var counts: Dictionary = report.get("counts", {})
	check(int(counts.get("final", -1)) == 0, "report counts.final == 0")
	check(int(counts.get("temporary", -1)) == 120, "report counts.temporary == 120")
	check(int(counts.get("missing", -1)) == 120, "report counts.missing == 120")
	check(int(report.get("total", -1)) == 120, "report total == 120")
	check((report.get("by_character", {}) as Dictionary).size() == 12, "report by_character has 12 entries")
	check(_has_error(CharacterAssetRegistry.validate_finished_asset("ignis", "movement_sheet"), "missing final asset"), "validate_finished_asset() reports absent file")
	check(not CharacterAssetRegistry.production_manifest().is_empty(), "production_manifest() non-empty")
	check(not CharacterAssetRegistry.replacement_seams().is_empty(), "replacement_seams() non-empty")

	var old: Dictionary = AssetManifest.status_report()
	check(int(old["counts"]["final"]) == 0, "REGRESSION: AssetManifest counts.final == 0")
	check(int(old["counts"]["temporary"]) == 8, "REGRESSION: AssetManifest counts.temporary == 8")
	check(int(old["counts"]["missing"]) == 8, "REGRESSION: AssetManifest counts.missing == 8")
	check(int(old["total"]) == 8, "REGRESSION: AssetManifest total == 8")
	var old_disk: Dictionary = AssetManifest.check_disk()
	check(old_disk.size() == 8, "REGRESSION: AssetManifest check_disk() has 8 entries")
	var old_false := true
	for key in old_disk.keys():
		if bool(old_disk[key]):
			old_false = false
	check(old_false, "REGRESSION: AssetManifest check_disk() false for all 8")


# ------------------------------------------------------ Phase 5 / group 4
## PortraitAssetSource contract + PortraitView integration (ASYNC): the 12
## missing portraits, synthetic-texture validation, and premium/fallback
## reports. Awaits one frame for the in-tree PortraitView.
func _test_character_portrait_loading() -> void:
	var ids: Array[String] = PortraitAssetSource.character_ids()
	check(ids.size() == 12, "PortraitAssetSource.character_ids().size() == 12")
	var missing_ok := true
	var status_ok := true
	var path_ok := true
	for cid in ids:
		if PortraitAssetSource.texture_for(cid) != null:
			missing_ok = false
		if PortraitAssetSource.has_portrait(cid):
			missing_ok = false
		if PortraitAssetSource.status(cid) == "final":
			status_ok = false
		var p: String = PortraitAssetSource.expected_path(cid)
		if not p.begins_with("res://assets/characters/") or not (cid in p) or not p.ends_with(".png"):
			path_ok = false
	check(missing_ok, "texture_for(id)==null and has_portrait(id)==false for all 12")
	check(status_ok, "status(id) is never 'final' for all 12")
	check(path_ok, "expected_path(id) is well-formed for all 12")

	var null_errs: Array[String] = PortraitAssetSource.validate_portrait(null)
	check(not null_errs.is_empty(), "validate_portrait(null) returns errors")
	check(_has_error(null_errs, "null"), "validate_portrait(null) error mentions null")
	var good: ImageTexture = _phase5_image_texture(256, 384, Image.FORMAT_RGBA8)
	check(PortraitAssetSource.validate_portrait(good).is_empty(), "synthetic 256x384 transparent RGBA8 portrait validates", str(PortraitAssetSource.validate_portrait(good)))
	var wrong_size: ImageTexture = _phase5_image_texture(128, 192, Image.FORMAT_RGBA8)
	check(_has_error(PortraitAssetSource.validate_portrait(wrong_size), "256x384"), "wrong-sized portrait reports dimension error")
	var bad_fmt: ImageTexture = _phase5_image_texture(256, 384, Image.FORMAT_RGB8)
	check(_has_error(PortraitAssetSource.validate_portrait(bad_fmt), "not RGBA8"), "non-RGBA8 portrait reports format error")
	check(not PortraitAssetSource.import_settings().is_empty(), "import_settings() non-empty")
	check(not PortraitAssetSource.report().is_empty(), "report() non-empty")
	check(not PortraitAssetSource.replacement_seam().strip_edges().is_empty(), "replacement_seam() non-empty")

	var pv := PortraitView.new()
	pv.custom_minimum_size = Vector2(252, 292)
	add_child(pv)
	await get_tree().process_frame
	check(pv.custom_minimum_size == Vector2(252, 292), "PortraitView preserves parent-assigned featured portrait dimensions")
	pv.setup_character(ContentDB.get_character("ignis"))
	var rep: Dictionary = pv.portrait_report()
	check(str(rep.get("character_id", "")) == "ignis", "portrait_report character_id == ignis")
	check(bool(rep.get("has_texture", true)) == false, "ignis has_texture == false")
	check(bool(rep.get("fallback_active", false)) == true, "ignis fallback_active == true")
	check(bool(rep.get("premium", false)) == true, "ignis premium == true")
	check(str(rep.get("rarity", "")) == "mythic", "ignis rarity == mythic")
	check(bool(rep.get("show_rarity_effect", false)) == true, "ignis show_rarity_effect == true")
	pv.set_portrait_texture(good)
	var rep2: Dictionary = pv.portrait_report()
	check(bool(rep2.get("has_texture", false)) == true, "set_portrait_texture(tex) -> has_texture true")
	check(bool(rep2.get("fallback_active", true)) == false, "set_portrait_texture(tex) -> fallback_active false")
	pv.set_portrait_texture(null)
	var rep3: Dictionary = pv.portrait_report()
	check(bool(rep3.get("has_texture", true)) == false, "set_portrait_texture(null) -> has_texture false")
	check(bool(rep3.get("fallback_active", false)) == true, "set_portrait_texture(null) -> fallback_active true")
	pv.dim = true
	pv.selected = true
	pv.show_frame = false
	check(pv.dim == true and pv.selected == true and pv.show_frame == false, "dim/selected/show_frame toggles persist")
	check(str(pv.portrait_report().get("character_id", "")) == "ignis", "portrait_report still valid after overlay toggles")
	pv.setup({}, "Elf", "wind", "epic", 7)
	check(pv.character_id == "", "setup({}) raw-palette path keeps character_id empty")
	check(pv.portrait_texture == null, "setup({}) keeps the procedural fallback")
	check(bool(pv.portrait_report().get("fallback_active", false)) == true, "setup({}) portrait_report fallback_active true")
	pv.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------ Phase 5 / group 5
## SpriteFramesActorSource registration / validation reports and the bounded
## 9x8 demo sheet: name-set parity, 96x128 frames and the ActorVisual seam.
func _test_sprite_sheet_registration() -> void:
	var reg = SpriteFramesActorSource.register_character("ignis")
	check(reg != null, "register_character('ignis') non-null")
	if reg != null:
		check(reg.has_frames() == false, "registered ignis source has_frames() == false")
		check(reg.is_temporary() == true, "registered ignis source is_temporary() == true")
	var vr: Dictionary = SpriteFramesActorSource.validation_report("ignis")
	check(not vr.is_empty(), "validation_report('ignis') non-empty")
	check(bool(vr.get("fallback_active", false)) == true, "validation_report fallback_active == true")
	check(bool(vr.get("registered", true)) == false, "validation_report registered == false")
	check(not (vr.get("expected_paths", {}) as Dictionary).is_empty(), "validation_report expected_paths non-empty")

	var missing: SpriteFramesActorSource = SpriteFramesActorSource.from_disk("definitely_missing_id") as SpriteFramesActorSource
	check(missing != null, "from_disk(missing) non-crashing")
	check(missing.has_frames() == false, "from_disk(missing) has_frames() == false")
	check(missing.frame(0, 0, 0) == null, "from_disk(missing) frame() == null")
	check(_has_error(missing.validate_sheets(), "no sprite sheet registered"), "from_disk(missing) validate_sheets() error")
	check(missing.animation_names().is_empty(), "animation_names() empty for a missing sheet")
	var rr: Dictionary = missing.registration_report()
	check(not rr.is_empty(), "registration_report() keys present")
	for key in ["character_id", "loaded_from_disk", "has_frames", "is_temporary", "animation_count", "validation_errors", "source"]:
		check(rr.has(key), "registration_report() has key: " + str(key))

	var demo := DemoCharacterFrames.new("player", {})
	check(demo.validate_sheets().is_empty(), "demo validate_sheets() == []", str(demo.validate_sheets()))
	check(demo.animation_names().size() == 72, "demo animation_names().size() == 72")
	check(demo.is_temporary() == true, "demo is_temporary() == true")
	check(demo.loaded_from_disk == false, "demo loaded_from_disk == false")
	check(demo.has_frames() == true, "demo has_frames() == true")

	var pipeline_names: Array[String] = CharacterArtPipeline.animation_names()
	var demo_names: Array[String] = demo.animation_names()
	var pset: Dictionary = {}
	var dset: Dictionary = {}
	for n in pipeline_names:
		pset[n] = true
	for n in demo_names:
		dset[n] = true
	check(pset.size() == 72 and dset.size() == 72, "pipeline and demo each expose 72 distinct names")
	var sets_equal := pset.size() == dset.size()
	for n in pset.keys():
		if not dset.has(n):
			sets_equal = false
	check(sets_equal, "pipeline animation name SET == demo animation name SET")
	check(dset.has("idle_0") and dset.has("walk_7") and dset.has("cast_3") and dset.has("defeat_0"), "demo names include idle_0/walk_7/cast_3/defeat_0")

	# Bounded sampling: frame 0 for all 9x8, plus ALL frames of 2 states.
	var dims_ok := true
	var sampled := 0
	for raw_s in CharacterAnimator.EXTENDED_STATES:
		var s := int(raw_s)
		for raw_d in CharacterAnimator.ALL_DIRECTIONS:
			var d := int(raw_d)
			sampled += 1
			var tex: Texture2D = demo.frame(s, d, 0)
			if tex == null or tex.get_width() != 96 or tex.get_height() != 128:
				dims_ok = false
	check(dims_ok, "demo frame(s,d,0) is 96x128 for all 9 states x 8 dirs")
	check(sampled == 72, "sampled all 72 frame-0 addresses", str(sampled))
	var full_ok := true
	var full_sampled := 0
	for raw_s in [0, 8]:
		var s := int(raw_s)
		var count := CharacterAnimator.frame_count_for(s)
		for raw_d in CharacterAnimator.ALL_DIRECTIONS:
			for i in count:
				full_sampled += 1
				var tex: Texture2D = demo.frame(s, int(raw_d), i)
				if tex == null or tex.get_width() != 96 or tex.get_height() != 128:
					full_ok = false
	check(full_ok, "all frames of idle+cast are 96x128", str(full_sampled))
	check(full_sampled == (5 + 7) * 8, "sampled all frames of 2 states (5+7)*8", str(full_sampled))

	var actor_visual_scene := load("res://scenes/characters/actor_visual.tscn") as PackedScene
	var av := actor_visual_scene.instantiate() as ActorVisual
	av.setup({})
	var cfg: Dictionary = av.configure_character("ignis")
	check(bool(cfg.get("fallback_active", false)) == true, "configure_character('ignis') fallback_active == true")
	check(av.frame_source is ProceduralActorFrames, "configure_character leaves ProceduralActorFrames in place")
	check(not av.character_art_report().is_empty(), "character_art_report() non-empty")
	av.free()  # never added to the tree; release the standalone node explicitly


# ------------------------------------------------------ Phase 5 / group 6
## Zero-final-asset fallbacks remain active for all 12 characters, frameless /
## null ActorVisual sources fall back safely, and an assembled game scene keeps
## temporary art. ASYNC: awaits frames for the in-tree visual and game scene.
func _test_missing_asset_fallbacks() -> void:
	var ids: Array[String] = _phase5_ids()
	var kinds: Array[String] = CharacterAssetRegistry.kinds()
	var portraits_missing := true
	var sheets_missing := true
	for cid in ids:
		if PortraitAssetSource.texture_for(cid) != null:
			portraits_missing = false
		var reg = SpriteFramesActorSource.register_character(cid)
		if reg == null or reg.has_frames():
			sheets_missing = false
		if CharacterAssetRegistry.status_for(cid, "movement_sheet") == "final":
			sheets_missing = false
	check(portraits_missing, "PortraitAssetSource.texture_for(id)==null for all 12")
	check(sheets_missing, "register_character(id).has_frames()==false and movement_sheet not final for all 12")

	var actor_visual_scene := load("res://scenes/characters/actor_visual.tscn") as PackedScene
	var av := actor_visual_scene.instantiate() as ActorVisual
	add_child(av)
	await get_tree().process_frame
	check(av.procedural_renderer is ActorProceduralRendererComponent and av.procedural_renderer.get_parent() == av, "ActorVisual owns and binds its procedural renderer component")
	check(av.pose_component is ActorPoseComponent and av.pose_component.get_parent() == av, "ActorVisual owns and binds its pose component")
	check(av.sprite_component is ActorSpriteComponent and av.sprite_component.get_parent() == av, "ActorVisual owns and binds its sprite-presentation component")
	check(av.animation_component is CharacterAnimationComponent and av.animation_component.get_parent() == av, "ActorVisual delegates locomotion playback to its animation component")
	av.set_frame_source(ActorFrameSource.new())
	check(av.using_temporary_art == true, "frameless ActorFrameSource keeps using_temporary_art true")
	check(is_instance_valid(av), "frameless source does not crash the visual")
	av.set_frame_source(null)
	check(av.frame_source is ProceduralActorFrames, "set_frame_source(null) restores ProceduralActorFrames")
	av.queue_free()
	await get_tree().process_frame

	var proc := ProceduralActorFrames.new({})
	var proc_ok := true
	var proc_count := 0
	for raw_s in CharacterAnimator.EXTENDED_STATES:
		var s := int(raw_s)
		for raw_d in CharacterAnimator.ALL_DIRECTIONS:
			proc_count += 1
			if proc.frame(s, int(raw_d), 0) == null:
				proc_ok = false
	check(proc_ok, "ProceduralActorFrames.frame(s,d,0) non-null for all 9x8")
	check(proc_count == 72, "sampled all 9x8 procedural addresses", str(proc_count))

	var demo := DemoCharacterFrames.new("player", {})
	check(demo.is_temporary() == true, "DemoCharacterFrames.is_temporary() == true")
	var no_images := true
	for cid in ids:
		for k in kinds:
			if not _phase5_no_final_image(cid, k):
				no_images = false
	check(no_images, "no .png/.webp/.tres at any of the 120 expected paths")

	var game_scene: PackedScene = load("res://scenes/game.tscn")
	check(game_scene != null, "game.tscn loads for fallback probe")
	if game_scene != null:
		var game := game_scene.instantiate()
		add_child(game)
		await get_tree().process_frame
		await get_tree().process_frame
		check(game.world != null and game.world.player != null, "assembled scene has a world player")
		if game.world != null and game.world.player != null:
			check(game.world.player.visual != null, "player exposes an ActorVisual")
			if game.world.player.visual != null:
				check(game.world.player.visual.using_temporary_art == false, "assembled Kael player uses final playable sprite art")
				var art_report: Dictionary = game.world.player.visual.character_art_report()
				check(art_report.get("has_frames", false) == true and art_report.get("animation_count", 0) == 72, "assembled Kael sheet has all 72 registered animations")
		game.queue_free()
		await get_tree().process_frame


# ------------------------------------------------------ Phase 5 / group 7
## UITheme premium rarity presentation + the three assembled UI screens'
## presentation reports and the PortraitView premium aura. ASYNC: adds nodes
## to the tree, awaits frames, then frees them all.
func _test_gacha_presentation() -> void:
	check(UITheme.is_premium_rarity("legendary") == true, "is_premium_rarity('legendary') == true")
	check(UITheme.is_premium_rarity("mythic") == true, "is_premium_rarity('mythic') == true")
	for r in ["common", "rare", "epic"]:
		check(UITheme.is_premium_rarity(str(r)) == false, "is_premium_rarity('" + str(r) + "') == false")
	var rarities: Array[String] = ["common", "rare", "epic", "legendary", "mythic"]
	for r in rarities:
		var effect: Dictionary = UITheme.rarity_effect(r)
		check(not effect.is_empty(), "rarity_effect('" + r + "') non-empty")
		check(effect.get("glow") is Color, "rarity_effect('" + r + "').glow is a Color")
		check(float(effect.get("border_width", 0)) > 0.0, "rarity_effect('" + r + "').border_width > 0")
		check(typeof(effect.get("aura")) == TYPE_FLOAT or typeof(effect.get("aura")) == TYPE_INT, "rarity_effect('" + r + "').aura is a number")
		check(not str(effect.get("tier", "")).is_empty(), "rarity_effect('" + r + "').tier present")
	var common_w := float(UITheme.rarity_effect("common").get("border_width", 0))
	check(float(UITheme.rarity_effect("legendary").get("border_width", 0)) > common_w, "legendary border_width > common")
	check(float(UITheme.rarity_effect("mythic").get("border_width", 0)) > common_w, "mythic border_width > common")
	check(not UITheme.rarity_glow("mythic").is_equal_approx(UITheme.rarity_glow("common")), "rarity_glow(mythic) != rarity_glow(common)")
	check(not UITheme.rarity_tier_label("mythic").strip_edges().is_empty(), "rarity_tier_label(mythic) non-empty")
	check(not UITheme.rarity_tier_label("legendary").strip_edges().is_empty(), "rarity_tier_label(legendary) non-empty")
	check(UITheme.rarity_tier_label("common").is_empty(), "rarity_tier_label(common) empty for standard tier")
	check(UITheme.RARITY_EFFECTS.size() == 5, "RARITY_EFFECTS covers 5 tiers")

	var gacha_scene := load("res://scenes/ui/gacha_screen.tscn") as PackedScene
	var collection_scene := load("res://scenes/ui/collection_screen.tscn") as PackedScene
	var gacha := gacha_scene.instantiate() as GachaScreen if gacha_scene != null else null
	var collection := collection_scene.instantiate() as CollectionScreen if collection_scene != null else null
	var combat_scene := load("res://scenes/ui/combat_screen.tscn") as PackedScene
	var combat := combat_scene.instantiate() as CombatScreen if combat_scene != null else null
	if combat != null:
		combat.group_id = "glade_mossling_pack"  # set BEFORE add_child
	if gacha != null:
		add_child(gacha)
	if collection != null:
		add_child(collection)
	if combat != null:
		add_child(combat)
	await get_tree().process_frame
	await get_tree().process_frame
	check(gacha != null and gacha.content != null and gacha.content.get_child_count() > 0, "GachaScreen builds content from its authored component scene")
	check(gacha != null and gacha._tabs.get_node_or_null("ReturnToGameButton") is Button, "GachaScreen exposes an explicit Return to Game close control")
	var results_close_test := GachaScreen.SUMMON_RESULTS_SCENE.instantiate() as Control
	check(results_close_test.get_node_or_null("Center/Panel/Content/Footer/ExitSummonButton") is Button, "Summon results expose a Return to Game close control")
	results_close_test.free()
	var reveal_close_test := GachaScreen.SUMMON_REVEAL_SCENE.instantiate() as Control
	check(reveal_close_test.get_node_or_null("CloseSummonButton") is Button, "Summon reveal exposes a close control")
	reveal_close_test.free()
	check(gacha != null and gacha._banner_content is GachaBannerContentComponent and gacha._banner_content.get_parent() == gacha, "GachaScreen binds its authored banner-content component")
	check(gacha != null and gacha._summon_flow is GachaSummonFlowComponent and gacha._summon_flow.get_parent() == gacha, "GachaScreen binds its authored summon-flow component")
	check(gacha != null and gacha.get_node_or_null("SummoningChamberAtmosphere") != null, "GachaScreen owns its authored chamber-atmosphere scene")
	check(gacha != null and gacha._main.get_child_count() == 2 and gacha._main.get_child(0) is ScrollContainer and gacha._main.get_child(1) is ScrollContainer, "Summon banner and detail columns have independent vertical scrolling")
	var summon_currency_before: Variant = GameState.inventory_domain.currency("crystals")
	if gacha != null:
		gacha._summon_busy = true
		gacha._pull(1)
	await get_tree().process_frame
	check(GameState.inventory_domain.currency("crystals") == summon_currency_before, "A second summon request is ignored while the reveal flow is busy")
	if gacha != null:
		gacha._summon_busy = false
	check(collection != null and collection.content != null and collection.content.get_child_count() > 0, "CollectionScreen builds content with children")
	check(collection != null and collection._roster_component is CollectionRosterComponent and collection._roster_component.get_parent() == collection, "CollectionScreen binds its authored roster component")
	check(collection != null and collection._detail_component is CollectionDetailComponent and collection._detail_component.get_parent() == collection, "CollectionScreen binds its authored detail component")
	check(combat != null and combat.get_child_count() > 0, "CombatScreen loads its authored component tree")
	var gacha_rep: Dictionary = gacha.presentation_report() if gacha != null else {}
	check(not gacha_rep.is_empty(), "GachaScreen.presentation_report() non-empty")
	check(bool(gacha_rep.get("rarity_effects_enabled", false)) == true, "Gacha presentation_report rarity_effects_enabled == true")
	var coll_rep: Dictionary = collection.presentation_report() if collection != null else {}
	check(not coll_rep.is_empty(), "CollectionScreen.presentation_report() non-empty")
	check(bool(coll_rep.get("rarity_effects_enabled", false)) == true, "Collection presentation_report rarity_effects_enabled == true")
	var skill_rep: Dictionary = combat.skill_presentation_report() if combat != null else {}
	check(not skill_rep.is_empty(), "CombatScreen.skill_presentation_report() non-empty")
	check(bool(skill_rep.get("ultimate_styling", false)) == true, "Combat skill_presentation_report ultimate_styling == true")
	check(combat != null and combat.engine != null, "CombatScreen.engine != null")
	if combat != null and combat.engine != null:
		check(combat.engine.combatants.size() >= 4, "CombatScreen engine.combatants.size() >= 4", str(combat.engine.combatants.size()))

	var pv := PortraitView.new()
	add_child(pv)
	await get_tree().process_frame
	pv.setup_character(ContentDB.get_character("ignis"))
	var pv_rep: Dictionary = pv.portrait_report()
	check(pv.show_rarity_effect == true, "PortraitView mythic show_rarity_effect == true")
	check(bool(pv_rep.get("premium", false)) == true, "PortraitView mythic premium == true")
	if gacha != null:
		gacha.queue_free()
	if collection != null:
		collection.queue_free()
	if combat != null:
		combat.queue_free()
	pv.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------ Phase 5 / group 8
## WorldVisualStandards contract, the 4 new procedural prop kinds, PROP_TYPES
## parity, and assembled-world visual reports. ASYNC: builds game.tscn and a
## second Moonpetal Hollow world, awaits frames, then frees both.
func _test_world_visual_standards() -> void:
	var cats: Array[String] = WorldVisualStandards.categories()
	check(cats.size() == 6, "categories().size() == 6", str(cats.size()))
	for c in ["player", "npc", "monster", "building", "vegetation", "environment_object"]:
		check(WorldVisualStandards.CATEGORIES.has(str(c)), "CATEGORIES covers: " + str(c))
	check(WorldVisualStandards.validate().is_empty(), "validate() == []", str(WorldVisualStandards.validate()))
	for c in cats:
		var s: Dictionary = WorldVisualStandards.standard(c)
		var ok := not s.is_empty()
		for key in ["canvas_width", "canvas_height", "anchor", "outline_px", "palette_group", "z_index", "batching_rule", "fallback"]:
			if not s.has(key):
				ok = false
		check(ok, "standard(c) has canvas/anchor/outline/palette_group/z_index/batching/fallback: " + c)
	check(not WorldVisualStandards.region_tint("greenward").is_equal_approx(WorldVisualStandards.region_tint("moonpetal_hollow")), "region_tint(greenward) != region_tint(moonpetal_hollow)")
	check(not WorldVisualStandards.summary().is_empty(), "summary() non-empty")
	check(not WorldVisualStandards.apply_notes().is_empty(), "apply_notes() non-empty")

	var kinds: Array[String] = ProceduralArt.prop_kinds()
	check(kinds.size() == 59, "ProceduralArt.prop_kinds().size() == 59", str(kinds.size()))
	var new_kinds: Array[String] = ["birch_grove", "moon_lantern", "stone_path", "village_gate", "bench", "crate"]
	for k in new_kinds:
		check(kinds.has(k), "new prop kind present: " + k)
		check(ProceduralArt.variant_count(k) >= 2, "variant_count >= 2: " + k, str(ProceduralArt.variant_count(k)))
		check(ProceduralArt.prop_texture(k, 0) != null, "prop_texture(k,0) non-null: " + k)
		var v0: Texture2D = ProceduralArt.prop_texture(k, 0)
		var v1: Texture2D = ProceduralArt.prop_texture(k, 1)
		check(v0.get_image().get_data() != v1.get_image().get_data(), "variant 0/1 pixels differ: " + k)
		check(not GreenwardStyle.prop_palette(k).is_empty(), "prop_palette() non-empty: " + k)
		check(ContentValidator.PROP_TYPES.has(k), "PROP_TYPES includes: " + k)
	check(ContentValidator.PROP_TYPES.size() >= 59, "ContentValidator.PROP_TYPES.size() >= 59", str(ContentValidator.PROP_TYPES.size()))
	check(GreenwardStyle.coherence_report().is_empty(), "GreenwardStyle.coherence_report() == []")

	var game_scene: PackedScene = load("res://scenes/game.tscn")
	check(game_scene != null, "game.tscn loads for world standards")
	if game_scene != null:
		var game := game_scene.instantiate()
		add_child(game)
		await get_tree().process_frame
		await get_tree().process_frame
		check(game.world != null, "assembled scene creates a world")
		check(game.get_node_or_null("Runtime") is GameRuntimeComponent and game.get_node("Runtime").get_parent() == game, "GameScreen uses its authored runtime component")
		check(game.get_node_or_null("WorldSession") is GameWorldSessionComponent and game.get_node("WorldSession").get_parent() == game, "GameScreen uses its authored world-session component")
		check(game.get_node_or_null("OverlayRouter") is GameOverlayRouterComponent and game.get_node("OverlayRouter").get_parent() == game, "GameScreen uses its authored overlay router")
		check(game.get_node_or_null("CombatRouter") is GameCombatRouterComponent and game.get_node("CombatRouter").get_parent() == game, "GameScreen uses its authored combat router")
		check(game.get_node_or_null("InputRouter") is GameInputRouterComponent and game.get_node("InputRouter").get_parent() == game, "GameScreen uses its authored input router")
		if game.world != null:
			if game.world is GreenwardWorld:
				var world_node := game.world as GreenwardWorld
				check(world_node.navigation_component is WorldNavigationComponent, "world scene owns a navigation component")
				check(world_node.weather_component is WorldWeatherComponent, "world scene owns a weather component")
				check(world_node.lighting_component is WorldLightingComponent, "world scene owns a localized lighting component")
				check(world_node.lighting_component.get_parent() == world_node, "localized lighting component is owned by the world scene")
				check(world_node._lights == world_node.lighting_component.lights, "world light compatibility array aliases the component-managed lights")
				check(world_node.weather_component.get_parent() == world_node, "weather component is owned by the world scene")
				check(world_node.weather == world_node.weather_component.director, "world weather compatibility reference delegates to the component director")
				check(world_node.navigation_component.world == world_node, "navigation component binds to its owning world")
				check(world_node.navigation_component.elevation == world_node.elevation, "navigation component receives the world's elevation field")
				check(world_node.chunk_streaming_component is WorldChunkStreamingComponent and world_node.chunk_streaming_component.get_parent() == world_node, "world scene owns its chunk-streaming component")
				check(world_node.chunk_lifecycle_component is WorldChunkLifecycleComponent and world_node.chunk_lifecycle_component.get_parent() == world_node, "world scene owns its chunk-lifecycle component")
				check(world_node.region_builder_component is WorldRegionBuilderComponent and world_node.region_builder_component.get_parent() == world_node, "world scene owns its region-builder component")
				check(world_node.greenward_builder_component is WorldGreenwardBuilderComponent and world_node.greenward_builder_component.get_parent() == world_node, "world scene owns its Greenward-builder component")
				var greenward_data := world_node.greenward_builder_component.composition_data as GreenwardCompositionData
				check(greenward_data != null, "Greenward builder consumes its authored composition resource")
				var greenward_builder := world_node.greenward_builder_component
				check(greenward_builder.river_builder is WorldGreenwardRiverComponent and greenward_builder.river_builder.get_parent() == greenward_builder, "Greenward builder owns its dedicated river node component")
				check(greenward_builder.landmark_builder is WorldGreenwardLandmarkComponent and greenward_builder.landmark_builder.get_parent() == greenward_builder, "Greenward builder owns its dedicated landmark node component")
				check(greenward_builder.route_builder is WorldGreenwardRouteComponent and greenward_builder.route_builder.get_parent() == greenward_builder, "Greenward builder owns its dedicated route node component")
				check(greenward_builder.interaction_builder is WorldGreenwardInteractionComponent and greenward_builder.interaction_builder.get_parent() == greenward_builder, "Greenward builder owns its dedicated interaction node component")
				if greenward_data != null:
					check(greenward_builder.river_builder.world == world_node and greenward_builder.river_builder.composition_data == greenward_data, "river node component binds to its owning world and composition data")
					check(greenward_builder.landmark_builder.world == world_node and greenward_builder.landmark_builder.composition_data == greenward_data, "landmark node component binds to its owning world and composition data")
					check(greenward_builder.route_builder.world == world_node and greenward_builder.route_builder.composition_data == greenward_data, "route node component binds to its owning world and composition data")
					check(greenward_builder.interaction_builder.world == world_node and greenward_builder.interaction_builder.composition_data == greenward_data, "interaction node component binds to its owning world and composition data")
					check(greenward_data.validate().is_empty(), "Greenward composition resource passes schema validation", str(greenward_data.validate()))
					check(greenward_data.village_npcs.size() == 3 and greenward_data.river_props.size() == 13 and greenward_data.river_animated_props.size() == 7, "Greenward NPC and river placements are stored as region data")
				check(world_node.region_context_component is WorldRegionContextComponent and world_node.region_context_component.get_parent() == world_node, "world scene owns its region-context component")
				check(world_node.day_night_presentation_component is WorldDayNightPresentationComponent and world_node.day_night_presentation_component.get_parent() == world_node, "world scene owns its day/night presentation component")
				check(world_node.atmosphere_component is WorldAtmosphereComponent and world_node.atmosphere_component.get_parent() == world_node, "world scene owns its atmosphere component")
				check(world_node.prop_factory_component is WorldPropFactoryComponent and world_node.prop_factory_component.get_parent() == world_node, "world scene owns its prop-factory component")
				check(world_node.visual_standards_component is WorldVisualStandardsComponent and world_node.visual_standards_component.get_parent() == world_node, "world scene owns its visual-standards component")
				check(world_node.effect_follow_component is WorldEffectFollowComponent and world_node.effect_follow_component.get_parent() == world_node, "world scene owns its effect-follow component")
				check(world_node.fog_component is WorldFogComponent and world_node.fog_component.get_parent() == world_node, "world scene owns its fog component")
				check(world_node.ambient_effects_component is WorldAmbientEffectsComponent and world_node.ambient_effects_component.get_parent() == world_node, "world scene owns its ambient-effects component")
				check(world_node.presentation_config_component is WorldPresentationConfigComponent and world_node.presentation_config_component.get_parent() == world_node, "world scene owns its presentation-config component")
				check(world_node.is_water_world(Vector2.ZERO) == world_node.navigation_component.is_water_world(Vector2.ZERO), "world water API delegates to navigation component")
			var vsr: Dictionary = game.world.visual_standards_report()
			check(not vsr.is_empty(), "visual_standards_report() non-empty")
			check(bool(vsr.get("standards_valid", false)) == true, "visual_standards_report standards_valid == true")
			var vs: Dictionary = game.world.visual_style_report()
			check(not vs.is_empty(), "visual_style_report() non-empty")
			for key in ["visual_standards", "visual_standards_valid", "character_art", "prop_kind_total"]:
				check(vs.has(key), "visual_style_report() has NEW key: " + str(key))
			for key in ["region_id", "region_name", "zone", "entry_points", "connections", "world_origin", "portals"]:
				check(vs.has(key), "visual_style_report() keeps Phase-4 key: " + str(key))
		check(game.get_node("WorldHost").get_child_count() == 1, "WorldHost starts with exactly one active world")
		game.world_session.build_world("gothic_castle_boss_zone")
		await get_tree().process_frame
		check(game.get_node("WorldHost").get_child_count() == 1, "loading Gothic Castle replaces rather than stacks the previous world")
		check(game.world_session.world is GothicCastleBossZone, "Gothic Castle loads as its own region scene")
		game.world_session.build_world("castle_royal_gardens")
		await get_tree().process_frame
		check(game.get_node("WorldHost").get_child_count() == 1, "returning to Royal Gardens leaves only one world in WorldHost")
		check(game.world_session.world is CastleRoyalGardens, "Royal Gardens reloads as its own region scene")
		game.queue_free()
		await get_tree().process_frame

	var w2 := load("res://scenes/world/greenward_world.tscn").instantiate() as GreenwardWorld
	w2.region_id = "moonpetal_hollow"
	w2.entry_point = "hollow_gate"
	add_child(w2)
	await get_tree().process_frame
	await get_tree().process_frame
	check(not w2.visual_standards_report().is_empty(), "second world visual_standards_report() non-empty")
	check(w2.region_id == "moonpetal_hollow", "second world region_id == moonpetal_hollow", w2.region_id)
	check(w2.current_area_name() != "", "second world current_area_name() non-empty")
	check(w2.navigation_component is WorldNavigationComponent and w2.navigation_component.get_parent() == w2, "world scene authors and owns its navigation component")
	check(w2.chunk_streaming_component is WorldChunkStreamingComponent and w2.chunk_streaming_component.get_parent() == w2, "world scene authors and owns its chunk-streaming component")
	check(w2.chunk_lifecycle_component is WorldChunkLifecycleComponent and w2.chunk_lifecycle_component.get_parent() == w2, "world scene authors and owns its chunk-lifecycle component")
	check(w2.region_builder_component is WorldRegionBuilderComponent and w2.region_builder_component.get_parent() == w2, "world scene authors and owns its region-builder component")
	check(w2.greenward_builder_component is WorldGreenwardBuilderComponent and w2.greenward_builder_component.get_parent() == w2, "world scene authors and owns its Greenward-builder component")
	var w2_greenward_builder := w2.greenward_builder_component
	var w2_composition_data := w2_greenward_builder.composition_data as GreenwardCompositionData
	check(w2_greenward_builder.river_builder is WorldGreenwardRiverComponent and w2_greenward_builder.river_builder.get_parent() == w2_greenward_builder, "Greenward builder authors and owns its river subcomponent")
	check(w2_greenward_builder.landmark_builder is WorldGreenwardLandmarkComponent and w2_greenward_builder.landmark_builder.get_parent() == w2_greenward_builder, "Greenward builder authors and owns its landmark subcomponent")
	check(w2_greenward_builder.route_builder is WorldGreenwardRouteComponent and w2_greenward_builder.route_builder.get_parent() == w2_greenward_builder, "Greenward builder authors and owns its route subcomponent")
	check(w2_greenward_builder.interaction_builder is WorldGreenwardInteractionComponent and w2_greenward_builder.interaction_builder.get_parent() == w2_greenward_builder, "Greenward builder authors and owns its interaction subcomponent")
	check(w2_composition_data != null and w2_greenward_builder.river_builder.composition_data == w2_composition_data and w2_greenward_builder.river_builder.world == w2, "river subcomponent receives the owning world and composition data")
	check(w2_composition_data != null and w2_greenward_builder.landmark_builder.composition_data == w2_composition_data and w2_greenward_builder.landmark_builder.world == w2, "landmark subcomponent receives the owning world and composition data")
	check(w2_composition_data != null and w2_greenward_builder.route_builder.composition_data == w2_composition_data and w2_greenward_builder.route_builder.world == w2, "route subcomponent receives the owning world and composition data")
	check(w2_composition_data != null and w2_greenward_builder.interaction_builder.composition_data == w2_composition_data and w2_greenward_builder.interaction_builder.world == w2, "interaction subcomponent receives the owning world and composition data")
	check(w2.region_context_component is WorldRegionContextComponent and w2.region_context_component.get_parent() == w2, "world scene authors and owns its region-context component")
	check(w2.day_night_presentation_component is WorldDayNightPresentationComponent and w2.day_night_presentation_component.get_parent() == w2, "world scene authors and owns its day/night component")
	check(w2.atmosphere_component is WorldAtmosphereComponent and w2.atmosphere_component.get_parent() == w2, "world scene authors and owns its atmosphere component")
	check(w2.prop_factory_component is WorldPropFactoryComponent and w2.prop_factory_component.get_parent() == w2, "world scene authors and owns its prop-factory component")
	check(w2.visual_standards_component is WorldVisualStandardsComponent and w2.visual_standards_component.get_parent() == w2, "world scene authors and owns its visual-standards component")
	check(w2.effect_follow_component is WorldEffectFollowComponent and w2.effect_follow_component.get_parent() == w2, "world scene authors and owns its effect-follow component")
	check(w2.fog_component is WorldFogComponent and w2.fog_component.get_parent() == w2, "world scene authors and owns its fog component")
	check(w2.ambient_effects_component is WorldAmbientEffectsComponent and w2.ambient_effects_component.get_parent() == w2, "world scene authors and owns its ambient-effects component")
	check(w2.presentation_config_component is WorldPresentationConfigComponent and w2.presentation_config_component.get_parent() == w2, "world scene authors and owns its presentation-config component")
	check(w2.navigation_component.world == w2, "authored world scene binds its navigation component")
	check(w2.entity_spawner is WorldEntitySpawnerComponent and w2.entity_spawner.world == w2, "world entity-spawner component binds to its owning world")
	check(w2.weather_component is WorldWeatherComponent and w2.weather_component.get_parent() == w2, "authored world scene binds its weather component")
	check(w2.weather == w2.weather_component.director, "direct world weather facade preserves the component director reference")
	if w2.navigation_component != null:
		check(w2.navigation_component.elevation == w2.elevation, "authored world navigation receives the elevation field")
		check(w2.is_water_world(Vector2.ZERO) == w2.navigation_component.is_water_world(Vector2.ZERO), "direct world water API delegates to navigation component")
	check(w2.loaded_chunks.size() > 0, "second world loaded_chunks.size() > 0", str(w2.loaded_chunks.size()))
	check(bool(w2.visual_standards_report().get("standards_valid", false)) == true, "second world standards_valid == true")
	w2.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------ Phase 5 / group 9
## Honest ZERO-final-asset status: manifest/regression counts, spec/manifest
## docs present, no final image at any of the 120 expected paths, and a
## deterministic CharacterAssetRegistry.report().
func _test_asset_status_honesty() -> void:
	var sr: Dictionary = AssetManifest.status_report()
	check(int(sr["counts"]["final"]) == 0, "AssetManifest FINAL == 0")
	check(int(sr["counts"]["temporary"]) == 8, "AssetManifest TEMPORARY == 8")
	check(int(sr["counts"]["missing"]) == 8, "AssetManifest MISSING == 8")
	check(int(sr["total"]) == 8, "AssetManifest total == 8")
	var disk: Dictionary = AssetManifest.check_disk()
	check(disk.size() == 8, "AssetManifest check_disk() has 8 entries")
	var disk_false := true
	for key in disk.keys():
		if bool(disk[key]):
			disk_false = false
	check(disk_false, "AssetManifest check_disk() false for all 8")
	check(int(CharacterAssetRegistry.report()["counts"]["final"]) == 0, "CharacterAssetRegistry report counts.final == 0")

	var ids: Array[String] = CharacterAssetRegistry.character_ids()
	var kinds: Array[String] = CharacterAssetRegistry.kinds()
	var never_final := true
	for cid in ids:
		for k in kinds:
			if CharacterAssetRegistry.status_for(cid, k) == "final":
				never_final = false
	check(never_final, "no status_for(id,k) is 'final' across all 120")

	var docs: Array[String] = [
		"res://assets/ASSET_PRODUCTION_MANIFEST.md",
		"res://assets/CHARACTER_SPECS.md",
		"res://assets/GENERATION_PROMPTS.md",
		"res://assets/CHARACTER_ART_PIPELINE.md",
		"res://assets/README.md",
		"res://assets/ASSET_STATUS.md",
	]
	for doc in docs:
		check(FileAccess.file_exists(doc), "spec/manifest doc exists: " + doc)
	for cid in _phase5_ids():
		check(FileAccess.file_exists("res://assets/characters/%s/SPEC.md" % cid), "SPEC.md exists: " + cid)

	var no_final_images := true
	var checked := 0
	for cid in ids:
		for k in kinds:
			checked += 1
			if FileAccess.file_exists(CharacterAssetRegistry.expected_path(cid, k)):
				no_final_images = false
			if not _phase5_no_final_image(cid, k):
				no_final_images = false
	check(no_final_images, "no .png/.webp/.tres final asset at any expected path")
	check(checked == 120, "sampled all 120 expected_path values", str(checked))

	var r1: Dictionary = CharacterAssetRegistry.report()
	var r2: Dictionary = CharacterAssetRegistry.report()
	var c1: Dictionary = r1["counts"]
	var c2: Dictionary = r2["counts"]
	check(int(c1["final"]) == int(c2["final"]) and int(c1["temporary"]) == int(c2["temporary"])
		and int(c1["missing"]) == int(c2["missing"]) and int(c1["total"]) == int(c2["total"]),
		"CharacterAssetRegistry.report() counts deterministic across two calls")
	check(int(r1["total"]) == int(r2["total"]), "report() total deterministic")

# ------------------------------------------------------------------- Phase 6 Round 3A: character progression

func _test_progression_xp() -> void:
	check(GameState.xp_to_next(1) == 100, "XP to next at level 1 is 100")
	check(GameState.xp_to_next(2) == 185, "XP to next at level 2 is 185")
	check(GameState.xp_to_next(20) == 100 + 19 * 85, "XP formula scales with level")

	var instance := _find_test_instance()
	if instance == null:
		check(false, "Find test instance for XP test")
		return
	var start_xp := instance.xp
	var result: Dictionary = GameState.add_xp_to_character(instance, 50)
	check(int(result.get("levels", -1)) == 0, "50 XP does not level up from 0")
	check(instance.xp == start_xp + 50, "XP accumulates correctly")
	check(GameState.xp_to_next(1) > 0, "XP requirement positive")

func _test_progression_leveling() -> void:
	var instance := _find_test_instance()
	if instance == null:
		check(false, "Find test instance for leveling test")
		return
	var start_level := instance.level
	var xp_needed: Variant = GameState.xp_to_next(instance.level)
	var result: Dictionary = GameState.add_xp_to_character(instance, xp_needed)
	check(int(result.get("levels", 0)) >= 1, "Full XP grants at least 1 level")
	check(instance.level > start_level, "Level increases after enough XP")
	check(instance.xp >= 0, "XP non-negative after level up")

func _test_progression_max_level() -> void:
	var instance := _find_test_instance()
	if instance == null:
		check(false, "Find test instance for max level test")
		return
	instance.level = instance.level_cap()
	instance.xp = 9999
	var result: Dictionary = GameState.add_xp_to_character(instance, 10000)
	check(instance.level == instance.level_cap(), "Level does not exceed cap")
	check(instance.xp == 0, "XP reset to 0 at max level")
	check(instance.is_max_level(), "is_max_level true at cap")

func _test_progression_stat_growth() -> void:
	var def: CharacterDef = ContentDB.get_character("lyra_vey")
	check(def != null, "Lyra def exists")
	var growth: Dictionary = def.growth
	check(not growth.is_empty(), "Growth data present")
	check(float(growth.get("hp", 0)) > 0, "HP growth positive")
	check(float(growth.get("atk", 0)) > 0, "ATK growth positive")
	var base_hp := def.stat("hp")
	var eff_hp_l1 := def.effective_stat("hp", 1, 0)
	check(near(base_hp, eff_hp_l1), "Level 1 effective stat equals base")
	var eff_hp_l2 := def.effective_stat("hp", 2, 0)
	check(eff_hp_l2 > eff_hp_l1, "Level 2 HP > Level 1 HP")

func _test_progression_ascension() -> void:
	var instance := _find_test_instance()
	if instance == null:
		check(false, "Find test instance for ascension test")
		return
	instance.level = instance.level_cap()
	var info: Dictionary = GameState.ascension_info(instance.uid)
	check(info.has("ok"), "ascension_info returns ok key")
	var result: Variant = GameState.ascend(instance.uid)
	if bool(info.get("ok", false)):
		check(result == true, "Ascension succeeds when requirements met")
	else:
		check(result == false, "Ascension fails when requirements not met")

func _test_progression_insufficient_materials() -> void:
	var instance := _find_test_instance()
	if instance == null:
		check(false, "Find test instance for materials test")
		return
	instance.level = instance.level_cap()
	var saved_dew: Variant = GameState.item_count("dew_of_awakening")
	GameState.remove_item("dew_of_awakening", saved_dew)
	var result: Variant = GameState.ascend(instance.uid)
	check(result == false, "Ascension fails without dew of awakening")
	GameState.add_item("dew_of_awakening", saved_dew)

func _test_progression_insufficient_gold() -> void:
	var instance := _find_test_instance()
	if instance == null:
		check(false, "Find test instance for gold test")
		return
	instance.level = instance.level_cap()
	GameState.add_item("dew_of_awakening", 5)
	var saved_gold: Variant = GameState.currency("gold")
	GameState.spend_currency("gold", saved_gold)
	var result: Variant = GameState.ascend(instance.uid)
	check(result == false, "Ascension fails without gold")
	GameState.add_currency("gold", saved_gold)

func _test_progression_save_load() -> void:
	var instance := _find_test_instance()
	if instance == null:
		check(false, "Find test instance for save/load test")
		return
	var original_level := instance.level
	var original_xp := instance.xp
	var original_ascension := instance.ascension
	var dict := instance.to_dict()
	var restored := CharacterInstance.from_dict(dict)
	check(restored.level == original_level, "Level persists in to_dict/from_dict")
	check(restored.xp == original_xp, "XP persists in to_dict/from_dict")
	check(restored.ascension == original_ascension, "Ascension persists in to_dict/from_dict")
	check(restored.uid == instance.uid, "UID persists")
	check(restored.char_id == instance.char_id, "char_id persists")

func _test_progression_invalid_upgrade() -> void:
	var result: Variant = GameState.equip_item("nonexistent_uid", "gold")
	check(result == false, "Equip fails for invalid UID")
	var instance := _find_test_instance()
	if instance == null:
		check(false, "Find test instance for invalid upgrade test")
		return
	var result2: Variant = GameState.equip_item(instance.uid, "gold")
	check(result2 == false, "Equip fails for non-equipment item")
	var result3: Variant = GameState.unequip_item(instance.uid, "weapon")
	check(true, "Unequip does not crash on empty slot")

func _test_progression_combat_stats() -> void:
	var instance := _find_test_instance()
	if instance == null:
		check(false, "Find test instance for combat stats test")
		return
	var units := CombatFactory.player_units()
	check(units.size() > 0, "player_units returns units")
	var unit = units[0]
	check(unit.max_hp > 0, "Combatant has positive HP")
	check(unit.atk > 0, "Combatant has positive ATK")
	check(unit.crit_mult >= 1.0, "Combatant crit_mult >= 1.0")

func _find_test_instance() -> CharacterInstance:
	for instance in GameState.roster:
		return instance
	return null



# ------------------------------------------------------ exploration rewards
func _test_exploration_rewards() -> void:
	var saved_state: Dictionary = GameState._to_dict().duplicate(true)
	var prev_loaded: Variant = GameState.loaded_from_save
	GameState.flags.erase("collectible:greenward_moonpetal_herbs")
	GameState.flags.erase("collectible:greenward_hollowed_crystal")
	# Exploration gathering nodes in this test belong to Greenward.
	GameState.loaded_from_save = true
	GameState.set_player_region("greenward")
	GameState.set_active_world("greenward")
	GameState.has_player_position = false
	var game_scene: PackedScene = load("res://scenes/game.tscn")
	var game := game_scene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var herbs: InteractiveProp = null
	var crystal: InteractiveProp = null
	for node in get_tree().get_nodes_in_group("interactables"):
		if node is InteractiveProp:
			if node.collectible_id == "greenward_moonpetal_herbs":
				herbs = node
			elif node.collectible_id == "greenward_hollowed_crystal":
				crystal = node
	check(herbs != null and crystal != null, "World builds both configured gathering nodes")
	if herbs != null and crystal != null:
		var moonpetal_before: Variant = GameState.item_count("moonpetal")
		var sap_before: Variant = GameState.item_count("glade_sap")
		herbs.interact()
		crystal.interact()
		check(GameState.item_count("moonpetal") == moonpetal_before + 1, "Moonpetal herb grants its configured material")
		check(GameState.item_count("glade_sap") == sap_before + 2, "Hollowed crystal grants its configured materials")
		check(not herbs.visible and not herbs.enabled, "Gathered herb node is disabled and hidden")
		check(not crystal.visible and not crystal.enabled, "Gathered crystal node is disabled and hidden")
		herbs.interact()
		check(GameState.item_count("moonpetal") == moonpetal_before + 1, "Gathered herb cannot be claimed twice")
		var serialized_state: Dictionary = GameState._to_dict().duplicate(true)
		GameState.flags.clear()
		GameState._load_from_dict(serialized_state)
		check(bool(GameState.flags.get("collectible:greenward_moonpetal_herbs", false)), "Collectible flag survives save-data round trip")
	game.queue_free()
	await get_tree().process_frame
	var reload_game := game_scene.instantiate()
	add_child(reload_game)
	await get_tree().process_frame
	await get_tree().process_frame
	var herbs_hidden := false
	var crystal_hidden := false
	for node in get_tree().get_nodes_in_group("interactables"):
		if node is InteractiveProp:
			if node.collectible_id == "greenward_moonpetal_herbs":
				herbs_hidden = not node.visible and not node.enabled
			elif node.collectible_id == "greenward_hollowed_crystal":
				crystal_hidden = not node.visible and not node.enabled
	check(herbs_hidden and crystal_hidden, "Claimed gathering nodes stay hidden after world recreation")
	reload_game.queue_free()
	await get_tree().process_frame
	GameState._load_from_dict(saved_state)
	GameState.loaded_from_save = prev_loaded


func _test_bonus_drop_rewards() -> void:
	for group_id in ["glade_mossling_pack", "thornhound_hunt", "moonpetal_sprite_pack"]:
		var group: Dictionary = ContentDB.get_enemy_group(group_id)
		check(not group.is_empty(), "Bonus-drop encounter exists: " + group_id)
		for drop in group.get("drops", []):
			var item_id := str(drop.get("item", ""))
			check(ContentDB.items.has(item_id), "Bonus drop item resolves: %s/%s" % [group_id, item_id])
			check(float(drop.get("chance", -1.0)) >= 0.0 and float(drop.get("chance", 2.0)) <= 1.0, "Bonus drop chance is within 0..1: " + group_id)
			check(int(drop.get("min", 0)) > 0 and int(drop.get("max", 0)) >= int(drop.get("min", 0)), "Bonus drop amount range is valid: " + group_id)
	var previous_group: Variant = ContentDB.enemy_groups.get("test_bonus_drop", null)
	var saved_state: Dictionary = GameState._to_dict().duplicate(true)
	ContentDB.enemy_groups["test_bonus_drop"] = {
		"name": "Deterministic Bonus Drop Test",
		"level": 1,
		"rewards": {"gold": 0, "crystals": 0, "xp": 0, "items": {}},
		"drops": [{"item": "moonpetal", "chance": 1.0, "min": 2, "max": 2}],
		"quest_kills": {},
	}
	var preview: Dictionary = GameState.build_battle_rewards("test_bonus_drop", true)
	check(int(preview.get("items", {}).get("moonpetal", 0)) == 2, "Reward preview rolls the guaranteed test drop")
	ContentDB.enemy_groups["test_zero_bonus_drop"] = {
		"name": "Zero Chance Drop Test",
		"level": 1,
		"rewards": {"gold": 0, "crystals": 0, "xp": 0, "items": {}},
		"drops": [{"item": "moonpetal", "chance": 0.0, "min": 1, "max": 1}],
		"quest_kills": {},
	}
	var zero_preview: Dictionary = GameState.build_battle_rewards("test_zero_bonus_drop", true)
	check(zero_preview.get("items", {}).is_empty(), "A zero-chance bonus drop never appears")
	ContentDB.enemy_groups.erase("test_zero_bonus_drop")
	var before: Variant = GameState.item_count("moonpetal")
	var applied: Dictionary = GameState.apply_battle_result("test_bonus_drop", true, preview)
	check(GameState.item_count("moonpetal") == before + 2, "Claim grants the exact precomputed bonus drop")
	check(applied.get("rewards", {}).get("items", {}) == preview.get("items", {}), "Displayed reward payload equals granted reward payload")
	if previous_group == null:
		ContentDB.enemy_groups.erase("test_bonus_drop")
	else:
		ContentDB.enemy_groups["test_bonus_drop"] = previous_group
	GameState._load_from_dict(saved_state)

	var sprite_monster := load("res://scenes/world/roaming_monster.tscn").instantiate() as RoamingMonster
	sprite_monster.setup("moonpetal_sprite_pack", Vector2.ZERO, ContentDB.get_enemy("moonpetal_sprite"), false)
	add_child(sprite_monster)
	await get_tree().process_frame
	check(sprite_monster.visual != null and sprite_monster.visual.def_id == "moonpetal_sprite", "Moonpetal Sprite keeps its unique species visual")
	sprite_monster.queue_free()
	await get_tree().process_frame



func _test_shop_service() -> void:
	var shop_signal_count := [0]
	var shop_listener := func() -> void: shop_signal_count[0] += 1
	EventBus.shop_requested.connect(shop_listener)
	var dialogue_action := DialogueBox.new()
	dialogue_action._run_action("open_shop")
	check(int(shop_signal_count[0]) == 1, "dialogue open_shop action requests the merchant screen")
	EventBus.shop_requested.disconnect(shop_listener)
	dialogue_action.free()
	var old_inventory: Dictionary = GameState.inventory.duplicate(true)
	var old_profile: Dictionary = GameState.profile.duplicate(true)
	GameState.inventory = {}
	GameState.profile["gold"] = 30
	var insufficient: Dictionary = ShopService.purchase("moonpetal")
	check(not bool(insufficient.get("ok", false)), "merchant blocks purchases without enough Gold")
	check(GameState.item_count("moonpetal") == 0 and GameState.currency("gold") == 30, "failed merchant purchase changes nothing")
	GameState.profile["gold"] = 100
	var purchased: Dictionary = ShopService.purchase("moonpetal")
	check(bool(purchased.get("ok", false)), "merchant sells valid stock items")
	check(GameState.item_count("moonpetal") == 1, "merchant purchase grants one item")
	check(GameState.currency("gold") == 40, "merchant purchase deducts exact Gold price")
	var unknown: Dictionary = ShopService.purchase("not_in_stock")
	check(not bool(unknown.get("ok", false)), "merchant rejects items outside the stock list")
	GameState.inventory = old_inventory
	GameState.profile = old_profile

func _test_crafting_service() -> void:
	var old_inventory: Dictionary = GameState.inventory.duplicate(true)
	var old_profile: Dictionary = GameState.profile.duplicate(true)
	GameState.inventory = {"glade_sap": 5, "moonpetal": 2}
	GameState.profile["gold"] = 1000
	var unknown := _CraftingServiceScript.recipe_status("not_a_recipe")
	check(not bool(unknown.get("ok", false)), "crafting rejects unknown recipe ids")
	var insufficient := _CraftingServiceScript.recipe_status("sunfire_blade")
	check(not bool(insufficient.get("ok", false)), "crafting blocks recipes with missing ingredients")
	check(not _CraftingServiceScript.craft("sunfire_blade").get("ok", false), "failed craft does not grant output")
	check(GameState.currency("gold") == 1000 and GameState.item_count("glade_sap") == 5, "failed craft leaves wallet and materials unchanged")
	var status := _CraftingServiceScript.recipe_status("wayfarer_charm")
	check(bool(status.get("craftable", false)), "wayfarer charm becomes craftable with required materials")
	var crafted := _CraftingServiceScript.craft("wayfarer_charm")
	check(bool(crafted.get("ok", false)), "valid recipe crafts successfully")
	check(GameState.item_count("glade_sap") == 3 and GameState.item_count("moonpetal") == 1, "craft consumes exact material costs")
	check(GameState.currency("gold") == 850, "craft consumes exact gold cost")
	check(GameState.item_count("wayfarer_charm") == 1, "craft grants configured output")
	var saved: Dictionary = GameState._to_dict()
	check(int(saved.get("inventory", {}).get("wayfarer_charm", 0)) == 1, "crafted output is included in save serialization")
	GameState.inventory = old_inventory
	GameState.profile = old_profile

func _settings_events_match(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i].as_text() != b[i].as_text():
			return false
	return true


func _test_settings_regressions() -> void:
	var action := "move_up"
	var original: Array = InputMap.action_get_events(action).duplicate(true)
	var custom := InputEventKey.new()
	custom.keycode = KEY_K
	var staged := load("res://scenes/ui/settings_screen.tscn").instantiate() as SettingsScreen
	add_child(staged)
	await get_tree().process_frame
	check(staged._controls_component is SettingsControlsComponent and staged._controls_component.get_parent() == staged, "SettingsScreen binds its controls component")
	check(staged._persistence_component is SettingsPersistenceComponent and staged._persistence_component.get_parent() == staged, "SettingsScreen binds its persistence component")
	check(staged.content != null, "settings screen builds its controls panel")
	var display_hint := staged.content.find_child("DisplayHint", true, false) as Label
	var controls_hint := staged.content.find_child("ControlsHint", true, false) as Label
	var general_hint := staged.content.find_child("GeneralHint", true, false) as Label
	check(display_hint != null and display_hint.size_flags_horizontal == Control.SIZE_EXPAND_FILL and display_hint.autowrap_mode != TextServer.AUTOWRAP_OFF, "settings display hint expands and wraps within its column")
	check(controls_hint != null and controls_hint.size_flags_horizontal == Control.SIZE_EXPAND_FILL and controls_hint.autowrap_mode != TextServer.AUTOWRAP_OFF, "settings controls hint expands and wraps within its column")
	check(general_hint != null and general_hint.size_flags_horizontal == Control.SIZE_EXPAND_FILL and general_hint.autowrap_mode != TextServer.AUTOWRAP_OFF, "settings general hint expands and wraps within its column")
	check(staged.content.get_child_count() == 1 and staged.content.get_child(0) is ScrollContainer, "settings content remains scrollable when sections stack on compact screens")
	staged._set_columns_for_width(868.0)
	check(staged._columns_layout.columns == 1, "settings sections stack at compact viewport widths")
	staged._set_columns_for_width(1280.0)
	check(staged._columns_layout.columns == 2, "settings sections return to two columns at desktop viewport widths")
	staged._assign_event(action, custom)
	check(_settings_events_match(InputMap.action_get_events(action), original), "settings rebind is staged until Apply")
	staged._cancel()
	await get_tree().process_frame
	check(_settings_events_match(InputMap.action_get_events(action), original), "settings Cancel leaves project InputMap unchanged")
	var applied := load("res://scenes/ui/settings_screen.tscn").instantiate() as SettingsScreen
	add_child(applied)
	await get_tree().process_frame
	applied._assign_event(action, custom)
	applied._apply()
	var current: Array = InputMap.action_get_events(action)
	check(current.size() == 1 and current[0] is InputEventKey and (current[0] as InputEventKey).keycode == KEY_K, "settings Apply changes runtime key binding")
	var reopened := load("res://scenes/ui/settings_screen.tscn").instantiate() as SettingsScreen
	add_child(reopened)
	await get_tree().process_frame
	var controls: Dictionary = reopened._working.get("controls", {})
	var binding: Variant = controls.get(action, {})
	check(binding is Dictionary and str(binding.get("type", "")) == "key", "settings persists a structured key binding")
	current = InputMap.action_get_events(action)
	check(current.size() == 1 and current[0] is InputEventKey and (current[0] as InputEventKey).keycode == KEY_K, "settings restores saved binding when reopened")
	reopened._restore_defaults()
	reopened._cancel()
	await get_tree().process_frame
	current = InputMap.action_get_events(action)
	check(current.size() == 1 and current[0] is InputEventKey and (current[0] as InputEventKey).keycode == KEY_K, "settings Cancel discards staged Restore Defaults")
	var reset := load("res://scenes/ui/settings_screen.tscn").instantiate() as SettingsScreen
	add_child(reset)
	await get_tree().process_frame
	reset._restore_defaults()
	reset._apply()
	check(_settings_events_match(InputMap.action_get_events(action), original), "settings Apply Restore Defaults restores project keymap")
	reset.close_screen()
	await get_tree().process_frame
	var cfg := ConfigFile.new()
	if cfg.load(SettingsScreen.CONFIG_PATH) == OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SettingsScreen.CONFIG_PATH))
	

# ------------------------------------------- Royal Gardens expansion / boss ---
func _test_reverie_expansion() -> void:
	var zone: Dictionary = ContentDB.get_region("gothic_castle_boss_zone")
	check(not zone.is_empty(), "boss zone region exists")
	check(bool(zone.get("standalone", false)), "boss zone is standalone")
	var castle: Dictionary = ContentDB.get_region("castle_royal_gardens")
	check(castle.get("entry_points", {}).has("boss_path"), "castle has boss_path entry point")
	var linked := false
	for c in castle.get("connections", []):
		var conn: Dictionary = c
		if str(conn.get("to", "")) == "gothic_castle_boss_zone":
			linked = true
	check(linked, "castle connects to the boss zone")
	check(str(ContentDB.get_quest("baltoria_summoning").get("requires", "")) == "blight_purification",
		"boss quest requires the side quest")
	check(bool(ContentDB.get_enemy_group("baltoria_encounter").get("boss", false)),
		"baltoria encounter is flagged as a boss")
	check(str(ContentDB.get_dialogue("arena_gatekeeper").get("start", "")) == "locked",
		"arena gate starts locked until the side quest is complete")

	var npc_placement_scene := load("res://scenes/world/castle_gardens/components/npc_placement.tscn") as PackedScene
	var npc_placement := npc_placement_scene.instantiate() as Node2D if npc_placement_scene != null else null
	check(npc_placement != null, "Royal Gardens NPC placement scene loads")
	if npc_placement != null:
		var west_guard := npc_placement.get_node("GuardLeft") as Marker2D
		var east_guard := npc_placement.get_node("GuardRight") as Marker2D
		check(str(west_guard.get_meta("display_name", "")) == "West Gate Guard" and str(east_guard.get_meta("display_name", "")) == "East Gate Guard", "Gate guards have distinct readable names")
		var west_grid: Vector2 = west_guard.get_meta("grid_position")
		var east_grid: Vector2 = east_guard.get_meta("grid_position")
		var guard_label_spacing := IsoMath.grid_to_world(east_grid.x, east_grid.y).distance_to(IsoMath.grid_to_world(west_grid.x, west_grid.y))
		check(guard_label_spacing >= 200.0, "Royal Gardens gate guard nameplates have enough horizontal/diagonal separation", str(guard_label_spacing))
		npc_placement.free()

	var paths: Dictionary = ReverieRouteData.all_path_cells()
	check(paths.size() > 70, "main route and branches contain enough tiles", str(paths.size()))
	var visited := {}
	var queue: Array[Vector2i] = [Vector2i(0, 0)]
	visited[Vector2i(0, 0)] = true
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for delta in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = cell + delta
			if paths.has(next) and not visited.has(next):
				visited[next] = true
				queue.append(next)
	var reachable := true
	for cell in ReverieRouteData.main_cells():
		if not visited.has(cell):
			reachable = false
	check(reachable, "main route is continuous from gate to arena")
	for end_cell in [Vector2i(18, -10), Vector2i(38, 18), Vector2i(52, -14)]:
		check(visited.has(end_cell), "side branch is reachable: " + str(end_cell))

	for scene_path in ["res://scenes/world/castle_royal_gardens.tscn",
			"res://scenes/world/gothic_castle_boss_zone.tscn"]:
		var packed := load(scene_path) as PackedScene
		check(packed != null, "map scene loads: " + scene_path)
		if packed != null:
			var world := packed.instantiate()
			check(world != null, "map scene instantiates: " + scene_path)
			if world != null:
				world.free()

	# The Gothic Castle region must never instantiate Royal Gardens textures.
	var gothic_world := load("res://scenes/world/gothic_castle_boss_zone.tscn").instantiate() as GothicCastleBossZone
	add_child(gothic_world)
	await get_tree().process_frame
	var gothic_environment := gothic_world.get_node_or_null("Components/Environment") as GothicCastleEnvironmentComponent
	check(gothic_environment != null, "Gothic Castle environment composition facade is authored")
	if gothic_environment != null:
		check(gothic_environment.get_node_or_null("GroundBuilder") is GothicGroundBuilderComponent, "Gothic Castle ground generation is an authored child node")
		check(gothic_environment.get_node_or_null("ArchitectureBuilder") is GothicCastleArchitectureComponent, "Gothic Castle architecture generation is an authored child node")
		check(gothic_environment.get_node_or_null("ArenaBuilder") is GothicBossArenaBuilderComponent, "Gothic boss arena generation is an authored child node")
		check(gothic_environment.get_node_or_null("RouteDecoration") is GothicRouteDecorationComponent, "Gothic route decoration is an authored child node")
		check(gothic_environment.get_node_or_null("BoundsBuilder") is GothicWorldBoundsComponent, "Gothic world bounds are an authored child node")
		for child_name in ["GroundBuilder", "ArchitectureBuilder", "ArenaBuilder", "RouteDecoration", "BoundsBuilder"]:
			var child_component := gothic_environment.get_node(child_name)
			check(child_component.get("environment") == gothic_environment, "Gothic environment child is bound to its owning facade", child_name)
	var pending_nodes: Array[Node] = [gothic_world]
	var royal_garden_textures: Array[String] = []
	while not pending_nodes.is_empty():
		var inspected: Node = pending_nodes.pop_back()
		if inspected is Sprite2D:
			var sprite_texture := (inspected as Sprite2D).texture
			if sprite_texture != null and sprite_texture.resource_path.contains("/Royal_Gardens/"):
				royal_garden_textures.append(sprite_texture.resource_path)
		for child in inspected.get_children():
			pending_nodes.append(child)
	check(royal_garden_textures.is_empty(), "Gothic Castle does not render any Royal Gardens textures", str(royal_garden_textures))
	check(gothic_world.ground_layer.get_child_count() > 1000, "Gothic Castle builds its own full stone ground field", str(gothic_world.ground_layer.get_child_count()))
	gothic_world.queue_free()
	await get_tree().process_frame

	var approach_scene := load("res://scenes/world/castle_gardens/components/castle_expansion_approach_placements.tscn") as PackedScene
	var approach := approach_scene.instantiate() as Node2D if approach_scene != null else null
	check(approach != null and approach.get_child_count() == 30, "Ceremonial approach and cache layout are authored as 30 placement markers")
	if approach != null:
		for placement in approach.get_children():
			if placement.name == "GardenerSealCache":
				check(placement.get_meta("placement_type", "") == "collectible" and placement.get_meta("collectible_id", "") == "castle_royal_seal_cache" and placement.get_meta("rewards", {}) is Dictionary, "Garden cache identity and rewards are authored on its marker")
			else:
				check(placement is Marker2D and placement.has_meta("target_layer") and placement.has_meta("category") and placement.has_meta("subfolder") and placement.has_meta("asset_id") and placement.get_meta("grid_position", null) is Vector2, "Approach placement owns its asset and grid configuration", str(placement.name))
		approach.free()

	var manifest_file := FileAccess.open("res://assets/reverie_pack_v01/manifest.json", FileAccess.READ)
	if manifest_file != null:
		var parsed = JSON.parse_string(manifest_file.get_as_text())
		var records: Array = parsed.get("assets", [])
		check(records.size() == 200, "all delivered assets imported", str(records.size()))
		var sample: Dictionary = records[0]
		var piece_path := "res://scenes/world/reverie_pack/%s/%s/%s.tscn" % [
				str(sample.get("category", "")), str(sample.get("subfolder", "")), str(sample.get("id", ""))]
		check(ResourceLoader.exists(piece_path), "modular piece scenes exist")
	var save_sample := {
		"version": 1,
		"profile": {"name": "Tester"},
		"region": "gothic_castle_boss_zone",
		"active_world_id": "gothic_castle_boss_zone",
		"region_positions": {"gothic_castle_boss_zone": {"x": 640.0, "y": 360.0}},
	}
	var save_errors: Array = SaveService.validate_save_data(save_sample)
	check(save_errors.is_empty(), "new region save data remains compatible", str(save_errors))


func _test_minimap_marker_filtering() -> void:
	var npc := Node.new()
	npc.add_to_group("world_minimap_npcs")
	var monster := Node.new()
	monster.add_to_group("world_minimap_monsters")
	var gatherable := Node.new()
	check(not MinimapMarkerComponent.should_render_interactable_marker(npc), "Minimap does not duplicate NPCs in the generic interactable layer")
	check(not MinimapMarkerComponent.should_render_interactable_marker(monster), "Minimap does not duplicate monsters in the generic interactable layer")
	check(MinimapMarkerComponent.should_render_interactable_marker(gatherable), "Minimap retains generic gatherable/interactable markers")
	npc.free()
	monster.free()
	gatherable.free()
