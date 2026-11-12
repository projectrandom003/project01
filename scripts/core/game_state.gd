extends Node
## Player session state: profile, roster, party, inventory, quests, pity and
## persisted position. All gameplay systems go through this facade so a future
## authoritative server can replace the storage layer without touching UI.
##
## SECURITY NOTE: this build is offline. Gacha rolls, currencies and rewards are
## computed client-side for the vertical slice. Phase 12 moves every one of
## those decisions behind the server boundary (see documentation/BACKEND.md).

const PARTY_MAX := 4
const MAX_PROFILE_LEVEL := 60

var profile: Dictionary = {}
var roster: Array = []
var party: Array = []
var inventory: Dictionary = {}
var quests: Dictionary = {}
var pity: Dictionary = {}
var flags: Dictionary = {}
var player_position: Vector2 = Vector2.ZERO
var has_player_position: bool = false
var loaded_from_save: bool = false

# Per-region position support. `player_position` / `has_player_position` are
# KEPT unchanged (legacy single-slot save keys). The new fields layer on top:
# `player_region` records the active region and `region_positions` remembers a
# saved position per region id. Values are stored as JSON-safe {x, y} dicts.
var player_region: String = "greenward"
var region_positions: Dictionary = {}

var _save_timer: Timer
var _autosave_timer: Timer
var _uid_counter: int = 0


func _ready() -> void:
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 1.0
	_save_timer.timeout.connect(save_now)
	add_child(_save_timer)

	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = 60.0
	_autosave_timer.timeout.connect(save_now)
	add_child(_autosave_timer)
	_autosave_timer.start()

	if SaveService.has_save():
		var data := SaveService.load_save()
		if not data.is_empty():
			_load_from_dict(data)
			loaded_from_save = true
	if profile.is_empty():
		new_game()
	print("[GameState] %s — %d characters, %d in party." % [
		"loaded save" if loaded_from_save else "new journey",
		roster.size(), party.size()
	])


# ---------------------------------------------------------------- lifecycle

func new_game(player_name: String = "Wanderer") -> void:
	profile = {
		"name": player_name,
		"level": 1,
		"xp": 0,
		"gold": 500,
		"gems": 0,
		"crystals": 1500,
		"guild_tokens": 0,
		"ancient_coins": 0,
		"event_tokens": 0,
		"created_at": Time.get_unix_time_from_system(),
	}
	roster.clear()
	party.clear()
	inventory = { "glade_sap": 3, "mossweave_vest": 1 }
	quests = {}
	pity = {}
	flags = {}
	player_position = Vector2.ZERO
	has_player_position = false
	player_region = "greenward"
	region_positions = {}
	_uid_counter = 0
	add_character("mira_sol")
	add_character("kael")
	add_character("bramble")
	save_now()
	EventBus.roster_changed.emit()
	EventBus.party_changed.emit()
	EventBus.currency_changed.emit()


func save_now() -> void:
	if profile.is_empty():
		return
	SaveService.write_save(_to_dict())


func queue_save() -> void:
	if _save_timer != null:
		_save_timer.start()


func reset_progress() -> void:
	SaveService.delete_save()
	new_game()


func _to_dict() -> Dictionary:
	var roster_data: Array = []
	for instance in roster:
		roster_data.append(instance.to_dict())
	return {
		"profile": profile,
		"roster": roster_data,
		"party": party,
		"inventory": inventory,
		"quests": quests,
		"pity": pity,
		"flags": flags,
		"position": { "x": player_position.x, "y": player_position.y },
		"has_position": has_player_position,
		"region": player_region,
		"region_positions": region_positions.duplicate(true),
	}


func _load_from_dict(data: Dictionary) -> void:
	profile = data.get("profile", {})
	if profile.is_empty():
		return
	roster.clear()
	for entry in data.get("roster", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var instance := CharacterInstance.from_dict(entry)
		if ContentDB.get_character(instance.char_id) == null or instance.uid.is_empty():
			continue
		roster.append(instance)
	party.clear()
	for uid in data.get("party", []):
		if _find_instance(str(uid)) != null and not party.has(str(uid)):
			party.append(str(uid))
	_fill_party()
	inventory = data.get("inventory", {})
	quests = data.get("quests", {})
	pity = data.get("pity", {})
	flags = data.get("flags", {})
	var pos: Dictionary = data.get("position", {})
	player_position = Vector2(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)))
	has_player_position = bool(data.get("has_position", false))
	# Per-region fields are OPTIONAL so old saves (which lack them) still load.
	player_region = str(data.get("region", "greenward"))
	var rp: Variant = data.get("region_positions", {})
	region_positions = rp.duplicate(true) if typeof(rp) == TYPE_DICTIONARY else {}


func set_player_position(position: Vector2) -> void:
	player_position = position
	has_player_position = true
	# Mirror into the active region's saved slot (kept JSON-safe as {x, y}).
	region_positions[player_region] = { "x": position.x, "y": position.y }


# -------------------------------------------------------------- region state

func set_player_region(region_id: String) -> void:
	player_region = region_id


func set_region_position(region_id: String, p: Vector2) -> void:
	region_positions[region_id] = { "x": p.x, "y": p.y }


func region_position(region_id: String) -> Vector2:
	var value: Variant = region_positions.get(region_id, null)
	if value is Vector2:
		return value
	if typeof(value) == TYPE_DICTIONARY:
		var d: Dictionary = value
		return Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))
	return Vector2.ZERO


func has_region_position(region_id: String) -> bool:
	return region_positions.has(region_id)


# ---------------------------------------------------------------- currencies

func currency(kind: String) -> int:
	return int(profile.get(kind, 0))


func add_currency(kind: String, amount: int) -> void:
	profile[kind] = currency(kind) + amount
	EventBus.currency_changed.emit()
	queue_save()


func spend_currency(kind: String, amount: int) -> bool:
	if amount < 0:
		return false
	if currency(kind) < amount:
		return false
	profile[kind] = currency(kind) - amount
	EventBus.currency_changed.emit()
	queue_save()
	return true


func add_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	inventory[item_id] = int(inventory.get(item_id, 0)) + amount
	EventBus.inventory_changed.emit()
	queue_save()


## Reward payloads may name either materials or wallet currencies. Route each
## entry to the correct store so data authors do not have to special-case them.
func grant_reward_items(rewards: Dictionary) -> void:
	for item_id in rewards.keys():
		var id := str(item_id)
		var amount := int(rewards[item_id])
		if amount <= 0:
			continue
		if str(ContentDB.get_item(id).get("category", "")) == "currency":
			add_currency(id, amount)
		else:
			add_item(id, amount)


func item_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


func remove_item(item_id: String, amount: int = 1) -> bool:
	if item_count(item_id) < amount:
		return false
	var remaining := item_count(item_id) - amount
	if remaining <= 0:
		inventory.erase(item_id)
	else:
		inventory[item_id] = remaining
	EventBus.inventory_changed.emit()
	queue_save()
	return true


# ------------------------------------------------------------------- roster

func _make_uid() -> String:
	_uid_counter += 1
	return "c%d_%d" % [Time.get_ticks_usec(), _uid_counter]


func _find_instance(uid: String) -> CharacterInstance:
	for instance in roster:
		if instance.uid == uid:
			return instance
	return null


func owns_character(character_id: String) -> bool:
	for instance in roster:
		if instance.char_id == character_id:
			return true
	return false


func add_character(character_id: String) -> Dictionary:
	if ContentDB.get_character(character_id) == null:
		return { "is_new": false, "error": "unknown_character" }
	for instance in roster:
		if instance.char_id == character_id:
			instance.dupes += 1
			var gained := 0
			if instance.dupes % 2 == 0 and instance.awakening < CharacterInstance.MAX_AWAKENING:
				instance.awakening += 1
				gained = 1
			EventBus.roster_changed.emit()
			queue_save()
			return { "instance": instance, "is_new": false, "awakening_gain": gained }
	var created := CharacterInstance.create(character_id, _make_uid())
	roster.append(created)
	if party.size() < PARTY_MAX:
		party.append(created.uid)
		EventBus.party_changed.emit()
	EventBus.roster_changed.emit()
	queue_save()
	return { "instance": created, "is_new": true, "awakening_gain": 0 }


func party_instances() -> Array:
	var result: Array = []
	for uid in party:
		var instance := _find_instance(uid)
		if instance != null:
			result.append(instance)
	return result


func set_party(uids: Array) -> bool:
	var cleaned: Array = []
	for uid in uids:
		var text := str(uid)
		if _find_instance(text) != null and not cleaned.has(text) and cleaned.size() < PARTY_MAX:
			cleaned.append(text)
	if cleaned.is_empty():
		return false
	party = cleaned
	EventBus.party_changed.emit()
	queue_save()
	return true


func _fill_party() -> void:
	for instance in roster:
		if party.size() >= PARTY_MAX:
			break
		if not party.has(instance.uid):
			party.append(instance.uid)


func unique_owned_count() -> int:
	var ids: Dictionary = {}
	for instance in roster:
		ids[instance.char_id] = true
	return ids.size()


func collection_bonus() -> float:
	return 1.0 + minf(0.15, 0.01 * floori(unique_owned_count() / 3.0))


func xp_to_next(level: int) -> int:
	return 100 + (level - 1) * 85


func add_xp_to_character(instance: CharacterInstance, amount: int) -> Dictionary:
	if instance == null or amount <= 0:
		return { "levels": 0 }
	var levels_gained := 0
	instance.xp += amount
	while not instance.is_max_level() and instance.xp >= xp_to_next(instance.level):
		instance.xp -= xp_to_next(instance.level)
		instance.level += 1
		levels_gained += 1
	if instance.is_max_level():
		instance.xp = 0
	EventBus.roster_changed.emit()
	queue_save()
	return { "levels": levels_gained }


func add_party_xp(amount: int) -> void:
	for instance in party_instances():
		add_xp_to_character(instance, amount)
	add_profile_xp(amount / 2)


func add_profile_xp(amount: int) -> void:
	if amount <= 0:
		return
	profile.xp = int(profile.get("xp", 0)) + amount
	var level := int(profile.get("level", 1))
	while level < MAX_PROFILE_LEVEL and int(profile.xp) >= 250 + (level - 1) * 180:
		profile.xp = int(profile.xp) - (250 + (level - 1) * 180)
		level += 1
	profile.level = level
	queue_save()


func ascension_info(uid: String) -> Dictionary:
	var instance := _find_instance(uid)
	if instance == null:
		return { "ok": false, "reason": "Character not found." }
	if instance.ascension >= CharacterInstance.MAX_ASCENSION:
		return { "ok": false, "reason": "Already fully ascended." }
	if not instance.is_max_level():
		return { "ok": false, "reason": "Reach level %d first." % instance.level_cap() }
	var gold_cost := 800 * (instance.ascension + 1)
	var dew_cost := instance.ascension + 1
	if currency("gold") < gold_cost:
		return { "ok": false, "reason": "Need %d gold." % gold_cost }
	if item_count("dew_of_awakening") < dew_cost:
		return { "ok": false, "reason": "Need %d Dew of Awakening." % dew_cost }
	return { "ok": true, "gold": gold_cost, "dew": dew_cost }


func ascend(uid: String) -> bool:
	var info := ascension_info(uid)
	if not bool(info.get("ok", false)):
		return false
	var instance := _find_instance(uid)
	if instance == null:
		return false
	spend_currency("gold", int(info.gold))
	remove_item("dew_of_awakening", int(info.dew))
	instance.ascension += 1
	instance.level += 1
	EventBus.roster_changed.emit()
	queue_save()
	return true


func awakening_info(uid: String) -> Dictionary:
	var instance := _find_instance(uid)
	if instance == null:
		return { "ok": false, "reason": "Character not found." }
	if instance.awakening >= CharacterInstance.MAX_AWAKENING:
		return { "ok": false, "reason": "Already fully awakened." }
	if instance.dupes < 2:
		return { "ok": false, "reason": "Need 2 duplicate copies (have %d)." % instance.dupes }
	return { "ok": true, "dupes_needed": 2, "current": instance.awakening, "next": instance.awakening + 1 }


func awaken(uid: String) -> bool:
	var info := awakening_info(uid)
	if not bool(info.get("ok", false)):
		return false
	var instance := _find_instance(uid)
	if instance == null:
		return false
	instance.dupes -= int(info.dupes_needed)
	instance.awakening += 1
	EventBus.roster_changed.emit()
	queue_save()
	return true


func add_bond(uid: String, amount: int) -> void:
	if amount <= 0:
		return
	var instance := _find_instance(uid)
	if instance == null:
		return
	instance.bond = mini(instance.bond + amount, 100)
	EventBus.roster_changed.emit()
	queue_save()


func bond_level(uid: String) -> int:
	var instance := _find_instance(uid)
	if instance == null:
		return 0
	return int(instance.bond / 10)


func bond_bonus_atk(uid: String) -> float:
	return float(bond_level(uid)) * 0.02



func equip_item(uid: String, item_id: String) -> bool:
	var instance := _find_instance(uid)
	if instance == null:
		return false
	var item: Dictionary = ContentDB.get_item(item_id)
	if str(item.get("category", "")) != "equipment":
		return false
	var slot := str(item.get("slot", ""))
	if slot.is_empty():
		return false
	if item_count(item_id) <= 0:
		return false
	remove_item(item_id, 1)
	var previous := instance.equipped_item(slot)
	if not previous.is_empty():
		add_item(previous, 1)
	instance.equip(item_id, slot)
	EventBus.roster_changed.emit()
	queue_save()
	return true


func unequip_item(uid: String, slot: String) -> bool:
	var instance := _find_instance(uid)
	if instance == null:
		return false
	var current := instance.equipped_item(slot)
	if current.is_empty():
		return false
	instance.unequip(slot)
	add_item(current, 1)
	EventBus.roster_changed.emit()
	queue_save()
	return true


# ------------------------------------------------------------------- quests

func quest_state(quest_id: String) -> String:
	var entry: Dictionary = quests.get(quest_id, {})
	return str(entry.get("state", "not_started"))


func quest_step_index(quest_id: String) -> int:
	var entry: Dictionary = quests.get(quest_id, {})
	return int(entry.get("step", 0))


func quest_step(quest_id: String) -> Dictionary:
	var definition: Dictionary = ContentDB.get_quest(quest_id)
	var steps: Array = definition.get("steps", [])
	var index := quest_step_index(quest_id)
	if index < 0 or index >= steps.size():
		return {}
	return steps[index]


func tracked_quest() -> String:
	return str(flags.get("tracked_quest", ""))


func set_tracked_quest(quest_id: String) -> void:
	if quest_id.is_empty():
		untrack_quest()
		return
	flags["tracked_quest"] = quest_id
	queue_save()
	EventBus.quest_updated.emit(quest_id)


func untrack_quest() -> void:
	flags.erase("tracked_quest")
	queue_save()


func quest_destination(quest_id: String) -> Vector2:
	# Returns the world-space destination of the currently active step, or
	# Vector2.ZERO if unknown. Used by the HUD tracker and the world map.
	if quest_id.is_empty():
		return Vector2.ZERO
	var step := quest_step(quest_id)
	if step.is_empty():
		return Vector2.ZERO
	var grid: Variant = step.get("grid", null)
	if typeof(grid) == TYPE_ARRAY and (grid as Array).size() == 2:
		var g: Array = grid
		return IsoMath.grid_to_world(float(g[0]), float(g[1]))
	# Fall back to the region spawn grid if no explicit grid was authored.
	var region: Dictionary = ContentDB.get_region("greenward")
	var spawn: Array = region.get("spawn_grid", [8, 8])
	return IsoMath.grid_to_world(float(spawn[0]), float(spawn[1]))


func distance_to_tracked() -> float:
	var qid := tracked_quest()
	if qid.is_empty() or quest_state(qid) != "active":
		return 0.0
	var player := _find_player_position()
	return player.distance_to(quest_destination(qid))


func direction_to_tracked() -> Vector2:
	var qid := tracked_quest()
	if qid.is_empty() or quest_state(qid) != "active":
		return Vector2.ZERO
	var player := _find_player_position()
	var delta := quest_destination(qid) - player
	if delta.length_squared() < 0.0001:
		return Vector2.ZERO
	return delta.normalized()


func _find_player_position() -> Vector2:
	if has_player_position:
		return player_position
	return Vector2.ZERO


func start_quest(quest_id: String, giver_id: String = "") -> bool:
	var definition: Dictionary = ContentDB.get_quest(quest_id)
	if definition.is_empty():
		return false
	if quest_state(quest_id) != "not_started":
		return false
	var requires := str(definition.get("requires", ""))
	if not requires.is_empty() and quest_state(requires) != "complete":
		return false
	quests[quest_id] = { "state": "active", "step": 0, "progress": 0 }
	var first := quest_step(quest_id)
	# The conversation that grants a quest satisfies its first "talk" step.
	if str(first.get("type", "")) == "talk" and str(first.get("target", "")) == giver_id:
		quests[quest_id].step = 1
	EventBus.quest_updated.emit(quest_id)
	queue_save()
	return true


func quest_ready(quest_id: String) -> bool:
	if quest_state(quest_id) != "active":
		return false
	var step := quest_step(quest_id)
	if step.is_empty():
		return true
	var definition: Dictionary = ContentDB.get_quest(quest_id)
	var steps: Array = definition.get("steps", [])
	return str(step.get("type", "")) == "talk" and quest_step_index(quest_id) == steps.size() - 1


func record_kill(enemy_id: String, count: int = 1) -> void:
	var changed := false
	for quest_id in quests.keys():
		if quest_state(quest_id) != "active":
			continue
		var step := quest_step(quest_id)
		if step.is_empty() or str(step.get("type", "")) != "kill":
			continue
		if str(step.get("target", "")) != enemy_id:
			continue
		var entry: Dictionary = quests[quest_id]
		entry.progress = int(entry.get("progress", 0)) + count
		if int(entry.progress) >= int(step.get("count", 1)):
			entry.progress = 0
			entry.step = int(entry.step) + 1
		quests[quest_id] = entry
		changed = true
		EventBus.quest_updated.emit(quest_id)
	if changed:
		queue_save()


func advance_quest(quest_id: String) -> void:
	if quest_state(quest_id) != "active":
		return
	var entry: Dictionary = quests[quest_id]
	entry.step = int(entry.get("step", 0)) + 1
	entry.progress = 0
	quests[quest_id] = entry
	EventBus.quest_updated.emit(quest_id)
	queue_save()


func complete_quest(quest_id: String) -> bool:
	if not quest_ready(quest_id):
		return false
	var definition: Dictionary = ContentDB.get_quest(quest_id)
	var rewards: Dictionary = definition.get("rewards", {})
	add_currency("gold", int(rewards.get("gold", 0)))
	add_currency("crystals", int(rewards.get("crystals", 0)))
	grant_reward_items(rewards.get("items", {}))
	if int(rewards.get("xp", 0)) > 0:
		add_party_xp(int(rewards.get("xp", 0)))
	# Bond gain: quest completion strengthens bonds.
	for uid in party:
		add_bond(uid, 5)
	var entry: Dictionary = quests[quest_id]
	entry.state = "complete"
	entry.step = definition.get("steps", []).size()
	quests[quest_id] = entry
	EventBus.quest_updated.emit(quest_id)
	EventBus.toast_requested.emit("Quest complete: %s" % definition.get("name", quest_id))
	queue_save()
	return true


func active_quests() -> Array:
	var result: Array = []
	for quest_id in quests.keys():
		if quest_state(quest_id) == "active":
			result.append(quest_id)
	return result


func check_condition(condition: String) -> bool:
	if condition.is_empty():
		return true
	var parts := condition.split(":")
	match parts[0]:
		"quest_state":
			return parts.size() >= 3 and quest_state(parts[1]) == parts[2]
		"quest_ready":
			return quest_ready(parts[1])
		"quest_active":
			return quest_state(parts[1]) == "active"
		"quest_complete":
			return quest_state(parts[1]) == "complete"
		"has_character":
			return owns_character(parts[1])
		"level_at_least":
			return int(profile.get("level", 1)) >= int(parts[1])
	return false


# -------------------------------------------------------------------- gacha

func pull_banner(banner_id: String, count: int) -> Dictionary:
	var banner: Dictionary = ContentDB.get_banner(banner_id)
	if banner.is_empty():
		return { "ok": false, "error": "Unknown banner." }
	if count != 1 and count != 10:
		return { "ok": false, "error": "Invalid summon count." }
	var cost_data: Dictionary = banner.get("cost", {})
	var currency_id := str(cost_data.get("currency", "crystals"))
	var cost := int(cost_data.get("ten" if count == 10 else "single", 0))
	if not spend_currency(currency_id, cost):
		return { "ok": false, "error": "Not enough %s." % ContentDB.get_item(currency_id).get("name", currency_id) }

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var state: Dictionary = pity.get(banner_id, GachaService.empty_pity())
	var outcome := GachaService.pull(banner, rng, state, count)
	pity[banner_id] = outcome.pity

	var results: Array = []
	for roll in outcome.results:
		var added := add_character(str(roll.character_id))
		roll["is_new"] = bool(added.get("is_new", false))
		roll["awakening_gain"] = int(added.get("awakening_gain", 0))
		results.append(roll)
	queue_save()
	return { "ok": true, "results": results, "pity": outcome.pity, "spent": cost, "currency": currency_id }


# ------------------------------------------------------------------- battle

func build_battle_rewards(group_id: String) -> Dictionary:
	var group: Dictionary = ContentDB.get_enemy_group(group_id)
	var rewards: Dictionary = group.get("rewards", {})
	var level_mult := 1.0 + 0.12 * maxi(0, int(group.get("level", 1)) - 1)
	return {
		"gold": int(round(float(rewards.get("gold", 0)) * level_mult)),
		"crystals": int(round(float(rewards.get("crystals", 0)) * level_mult)),
		"xp": int(round(float(rewards.get("xp", 0)) * level_mult)),
		"items": rewards.get("items", {}),
	}


func apply_battle_result(group_id: String, victory: bool) -> Dictionary:
	if not victory:
		return { "applied": false }
	var group: Dictionary = ContentDB.get_enemy_group(group_id)
	var rewards := build_battle_rewards(group_id)
	add_currency("gold", int(rewards.gold))
	add_currency("crystals", int(rewards.crystals))
	grant_reward_items(rewards.items)
	add_party_xp(int(rewards.xp))
	# Bond gain: small amount per battle victory.
	for uid in party:
		add_bond(uid, 2)
	for enemy_id in group.get("quest_kills", {}).keys():
		record_kill(str(enemy_id), int(group["quest_kills"][enemy_id]))
	EventBus.toast_requested.emit("Victory — +%d gold, +%d crystals" % [rewards.gold, rewards.crystals])
	queue_save()
	return { "applied": true, "rewards": rewards }
