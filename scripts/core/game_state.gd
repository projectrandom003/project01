extends Node
## Player session state: profile, roster, party, inventory, quests, pity and
## persisted position. All gameplay systems go through this facade so a future
## authoritative server can replace the storage layer without touching UI.
##
## SECURITY NOTE: this build is offline. Gacha rolls, currencies and rewards are
## computed client-side for the vertical slice. Phase 12 moves every one of
## those decisions behind the server boundary (see documentation/BACKEND.md).

const PARTY_MAX := 4
## The starting trio. Order is the initial party order shown in the UI.
const STARTING_CHARACTERS := ["gerald", "lilith", "kael"]
## Former starters. Their definitions stay in content data (art specs and
## banner validation reference them), but new_game() never grants them and
## legacy saves are migrated to the new trio.
const REMOVED_CHARACTERS := ["mira_sol", "bramble"]
const MAX_PROFILE_LEVEL := 60

var profile: Dictionary:
	get:
		return profile_domain.profile if profile_domain != null else {}
	set(value):
		if profile_domain != null:
			profile_domain.profile = value

## Compatibility-facing properties backed by their owning domain components.
var roster: Array:
	get:
		return roster_domain.roster if roster_domain != null else []
	set(value):
		if roster_domain != null:
			roster_domain.roster = value
var party: Array:
	get:
		return roster_domain.party if roster_domain != null else []
	set(value):
		if roster_domain != null:
			roster_domain.party = value
var inventory: Dictionary:
	get:
		return inventory_domain.inventory if inventory_domain != null else {}
	set(value):
		if inventory_domain != null:
			inventory_domain.inventory = value
var quests: Dictionary:
	get:
		return quest_domain.quests if quest_domain != null else {}
	set(value):
		if quest_domain != null:
			quest_domain.quests = value
var flags: Dictionary:
	get:
		return quest_domain.flags if quest_domain != null else {}
	set(value):
		if quest_domain != null:
			quest_domain.flags = value
var pity: Dictionary:
	get:
		return reward_domain.pity if reward_domain != null else {}
	set(value):
		if reward_domain != null:
			reward_domain.pity = value
var daily_rewards: Dictionary = {}
## Persistent per-character gear enhancement levels, keyed by "uid|slot".
var gear_levels: Dictionary:
	get:
		return roster_domain.gear_levels if roster_domain != null else {}
	set(value):
		if roster_domain != null:
			roster_domain.gear_levels = value
var gear_rerolls: Dictionary:
	get:
		return roster_domain.gear_rerolls if roster_domain != null else {}
	set(value):
		if roster_domain != null:
			roster_domain.gear_rerolls = value
# Session state remains available through these compatibility-facing properties.
var player_position: Vector2:
	get:
		return session_domain.player_position if session_domain != null else Vector2.ZERO
	set(value):
		if session_domain != null:
			session_domain.player_position = value
var has_player_position: bool:
	get:
		return session_domain.has_player_position if session_domain != null else false
	set(value):
		if session_domain != null:
			session_domain.has_player_position = value
var player_facing: Vector2:
	get:
		return session_domain.player_facing if session_domain != null else Vector2(0.0, 1.0)
	set(value):
		if session_domain != null:
			session_domain.player_facing = value
var loaded_from_save: bool:
	get:
		return session_domain.loaded_from_save if session_domain != null else false
	set(value):
		if session_domain != null:
			session_domain.loaded_from_save = value
var player_region: String:
	get:
		return session_domain.player_region if session_domain != null else "greenward"
	set(value):
		if session_domain != null:
			session_domain.player_region = value
var active_world_id: String:
	get:
		return session_domain.active_world_id if session_domain != null else "greenward"
	set(value):
		if session_domain != null:
			session_domain.active_world_id = value
var region_positions: Dictionary:
	get:
		return session_domain.region_positions if session_domain != null else {}
	set(value):
		if session_domain != null:
			session_domain.region_positions = value

@onready var lifecycle_component: GameStateLifecycleComponent = get_node("Lifecycle") as GameStateLifecycleComponent
# Compatibility references; lifecycle ownership lives in GameStateLifecycleComponent.
@onready var _save_timer: Timer = $SaveTimer
@onready var _autosave_timer: Timer = $AutosaveTimer
@onready var inventory_domain: GameInventoryDomainComponent = get_node("InventoryDomain") as GameInventoryDomainComponent
@onready var quest_domain: GameQuestDomainComponent = get_node("QuestDomain") as GameQuestDomainComponent
@onready var roster_domain: GameRosterDomainComponent = get_node("RosterDomain") as GameRosterDomainComponent
@onready var reward_domain: GameRewardDomainComponent = get_node("RewardDomain") as GameRewardDomainComponent
@onready var profile_domain: GameProfileDomainComponent = get_node("ProfileDomain") as GameProfileDomainComponent
@onready var session_domain: GameSessionDomainComponent = get_node("SessionDomain") as GameSessionDomainComponent
@onready var persistence_component: GameStatePersistenceComponent = get_node("Persistence") as GameStatePersistenceComponent


func _ready() -> void:
	persistence_component.bind(self)
	lifecycle_component.configure(self)
	lifecycle_component.initialize()


# ---------------------------------------------------------------- lifecycle

func new_game(player_name: String = "Wanderer") -> void:
	lifecycle_component.new_game(player_name)


func save_now() -> void:
	lifecycle_component.save_now()


func queue_save() -> void:
	lifecycle_component.queue_save()


func reset_progress() -> void:
	lifecycle_component.reset_progress()


func _to_dict() -> Dictionary:
	return persistence_component.to_dict() if persistence_component != null else {}

func _load_from_dict(data: Dictionary) -> void:
	if persistence_component != null:
		persistence_component.load_from_dict(data)

func set_player_position(position: Vector2) -> void:
	session_domain.set_player_position(position)


# -------------------------------------------------------------- region state
func set_player_region(region_id: String) -> void:
	session_domain.set_player_region(region_id)


func set_active_world(world_id: String) -> void:
	session_domain.set_active_world(world_id)


func set_player_facing(facing: Vector2) -> void:
	session_domain.set_player_facing(facing)


func set_region_position(region_id: String, position: Vector2) -> void:
	session_domain.set_region_position(region_id, position)


func region_position(region_id: String) -> Vector2:
	return session_domain.region_position(region_id)


func has_region_position(region_id: String) -> bool:
	return session_domain.has_region_position(region_id)


# ---------------------------------------------------------------- currencies

func currency(kind: String) -> int:
	return inventory_domain.currency(kind)


func add_currency(kind: String, amount: int) -> void:
	inventory_domain.add_currency(kind, amount)


func spend_currency(kind: String, amount: int) -> bool:
	return inventory_domain.spend_currency(kind, amount)


func add_item(item_id: String, amount: int = 1) -> void:
	inventory_domain.add_item(item_id, amount)


## Reward payloads may name either materials or wallet currencies.
func grant_reward_items(rewards: Dictionary) -> void:
	inventory_domain.grant_reward_items(rewards)


func item_count(item_id: String) -> int:
	return inventory_domain.item_count(item_id)


func remove_item(item_id: String, amount: int = 1) -> bool:
	return inventory_domain.remove_item(item_id, amount)


# ------------------------------------------------------------------- roster

func _make_uid() -> String:
	return roster_domain._make_uid()


func _find_instance(uid: String) -> CharacterInstance:
	return roster_domain._find_instance(uid)


func owns_character(character_id: String) -> bool:
	return roster_domain.owns_character(character_id)


func _ensure_starting_characters() -> void:
	roster_domain._ensure_starting_characters()


func _reset_party_to_starters() -> void:
	roster_domain._reset_party_to_starters()


func add_character(character_id: String) -> Dictionary:
	return roster_domain.add_character(character_id)


func party_instances() -> Array:
	return roster_domain.party_instances()


func set_party(uids: Array) -> bool:
	return roster_domain.set_party(uids)


func _fill_party() -> void:
	roster_domain._fill_party()


func unique_owned_count() -> int:
	return roster_domain.unique_owned_count()


func collection_bonus() -> float:
	return roster_domain.collection_bonus()


func xp_to_next(level: int) -> int:
	return roster_domain.xp_to_next(level)


func add_xp_to_character(instance: CharacterInstance, amount: int) -> Dictionary:
	return roster_domain.add_xp_to_character(instance, amount)


func add_party_xp(amount: int) -> void:
	roster_domain.add_party_xp(amount)


func add_profile_xp(amount: int) -> void:
	profile_domain.add_xp(amount)


func ascension_info(uid: String) -> Dictionary:
	return roster_domain.ascension_info(uid)


func ascend(uid: String) -> bool:
	return roster_domain.ascend(uid)


func awakening_info(uid: String) -> Dictionary:
	return roster_domain.awakening_info(uid)


func awaken(uid: String) -> bool:
	return roster_domain.awaken(uid)


func add_bond(uid: String, amount: int) -> void:
	roster_domain.add_bond(uid, amount)


func bond_level(uid: String) -> int:
	return roster_domain.bond_level(uid)


func bond_bonus_atk(uid: String) -> float:
	return roster_domain.bond_bonus_atk(uid)


func equip_item(uid: String, item_id: String) -> bool:
	return roster_domain.equip_item(uid, item_id)


func unequip_item(uid: String, slot: String) -> bool:
	return roster_domain.unequip_item(uid, slot)


func gear_level(uid: String, slot: String) -> int:
	return roster_domain.gear_level(uid, slot)


func gear_reroll_info(uid: String, slot: String) -> Dictionary:
	return roster_domain.gear_reroll_info(uid, slot)


func reroll_gear(uid: String, slot: String) -> Dictionary:
	return roster_domain.reroll_gear(uid, slot)


func gear_upgrade_info(uid: String, slot: String) -> Dictionary:
	return roster_domain.gear_upgrade_info(uid, slot)


func enhance_gear(uid: String, slot: String) -> bool:
	return roster_domain.enhance_gear(uid, slot)


# ------------------------------------------------------------------- quests

func quest_state(quest_id: String) -> String:
	return quest_domain.quest_state(quest_id)


func quest_step_index(quest_id: String) -> int:
	return quest_domain.quest_step_index(quest_id)


func quest_step(quest_id: String) -> Dictionary:
	return quest_domain.quest_step(quest_id)


func tracked_quest() -> String:
	return quest_domain.tracked_quest()


func set_tracked_quest(quest_id: String) -> void:
	quest_domain.set_tracked_quest(quest_id)


func untrack_quest() -> void:
	quest_domain.untrack_quest()


func quest_destination(quest_id: String) -> Vector2:
	return quest_domain.quest_destination(quest_id)


func quest_target_position(quest_id: String) -> Vector2:
	return quest_domain.quest_target_position(quest_id)


func distance_to_tracked() -> float:
	return quest_domain.distance_to_tracked()


func direction_to_tracked() -> Vector2:
	return quest_domain.direction_to_tracked()


func _find_player_position() -> Vector2:
	return quest_domain._find_player_position()


func start_quest(quest_id: String, giver_id: String = "") -> bool:
	return quest_domain.start_quest(quest_id, giver_id)


func quest_ready(quest_id: String) -> bool:
	return quest_domain.quest_ready(quest_id)


func record_kill(enemy_id: String, count: int = 1) -> void:
	quest_domain.record_kill(enemy_id, count)


func advance_quest(quest_id: String) -> void:
	quest_domain.advance_quest(quest_id)


func complete_quest(quest_id: String) -> bool:
	return quest_domain.complete_quest(quest_id)


func quest_marker_for_npc(npc_id: String) -> String:
	return quest_domain.quest_marker_for_npc(npc_id)


func active_quests() -> Array:
	return quest_domain.active_quests()


func check_condition(condition: String) -> bool:
	return quest_domain.check_condition(condition)


# -------------------------------------------------------------------- gacha

func pull_banner(banner_id: String, count: int) -> Dictionary:
	return reward_domain.pull_banner(banner_id, count)


func daily_reward_status() -> Dictionary:
	return reward_domain.daily_reward_status()


func claim_daily_reward() -> Dictionary:
	return reward_domain.claim_daily_reward()


# ------------------------------------------------------------------- battle

func build_battle_rewards(group_id: String, roll_bonus_drops: bool = false) -> Dictionary:
	return reward_domain.build_battle_rewards(group_id, roll_bonus_drops)


func apply_battle_result(group_id: String, victory: bool, precomputed_rewards: Dictionary = {}) -> Dictionary:
	return reward_domain.apply_battle_result(group_id, victory, precomputed_rewards)