class_name GameRosterDomainComponent
extends Node
## Owns roster, party composition, character progression, bonds and equipment.

const PARTY_MAX := 4
const STARTING_CHARACTERS := ["gerald", "lilith", "kael"]
const MAX_PROFILE_LEVEL := 60

var roster: Array = []
var party: Array = []
var gear_levels: Dictionary = {}
var gear_rerolls: Dictionary = {}

var _uid_counter: int = 0


func reset_uid_counter() -> void:
	_uid_counter = 0


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


## Grants any missing starting character directly (no duplicate/awakening
## bookkeeping) so new and migrated saves always own the full trio.
func _ensure_starting_characters() -> void:
	for character_id in STARTING_CHARACTERS:
		if owns_character(character_id):
			continue
		if ContentDB.get_character(character_id) == null:
			push_error("[GameState] Missing starting character definition: " + character_id)
			continue
		roster.append(CharacterInstance.create(character_id, _make_uid()))


## Replaces the party with the starting trio in canonical order.
func _reset_party_to_starters() -> void:
	party.clear()
	for character_id in STARTING_CHARACTERS:
		for instance in roster:
			if instance.char_id == character_id:
				party.append(instance.uid)
				break


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
			GameState.queue_save()
			return { "instance": instance, "is_new": false, "awakening_gain": gained }
	var created := CharacterInstance.create(character_id, _make_uid())
	roster.append(created)
	if party.size() < PARTY_MAX:
		party.append(created.uid)
		EventBus.party_changed.emit()
	EventBus.roster_changed.emit()
	GameState.queue_save()
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
	GameState.queue_save()
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
	GameState.queue_save()
	return { "levels": levels_gained }


func add_party_xp(amount: int) -> void:
	for instance in party_instances():
		add_xp_to_character(instance, amount)
	add_profile_xp(amount / 2)


func add_profile_xp(amount: int) -> void:
	GameState.profile_domain.add_xp(amount)

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
	if GameState.inventory_domain.currency("gold") < gold_cost:
		return { "ok": false, "reason": "Need %d gold." % gold_cost }
	if GameState.inventory_domain.item_count("dew_of_awakening") < dew_cost:
		return { "ok": false, "reason": "Need %d Dew of Awakening." % dew_cost }
	return { "ok": true, "gold": gold_cost, "dew": dew_cost }


func ascend(uid: String) -> bool:
	var info := ascension_info(uid)
	if not bool(info.get("ok", false)):
		return false
	var instance := _find_instance(uid)
	if instance == null:
		return false
	GameState.inventory_domain.spend_currency("gold", int(info.gold))
	GameState.inventory_domain.remove_item("dew_of_awakening", int(info.dew))
	instance.ascension += 1
	instance.level += 1
	EventBus.roster_changed.emit()
	GameState.queue_save()
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
	GameState.queue_save()
	return true


func add_bond(uid: String, amount: int) -> void:
	if amount <= 0:
		return
	var instance := _find_instance(uid)
	if instance == null:
		return
	instance.bond = mini(instance.bond + amount, 100)
	EventBus.roster_changed.emit()
	GameState.queue_save()


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
	if not CharacterInstance.SLOTS.has(slot):
		return false
	if GameState.inventory_domain.item_count(item_id) <= 0:
		return false
	GameState.inventory_domain.remove_item(item_id, 1)
	var previous := instance.equipped_item(slot)
	if not previous.is_empty():
		GameState.inventory_domain.add_item(previous, 1)
	instance.equip(item_id, slot)
	gear_levels.erase(uid + "|" + slot)
	EventBus.roster_changed.emit()
	GameState.queue_save()
	return true


func unequip_item(uid: String, slot: String) -> bool:
	var instance := _find_instance(uid)
	if instance == null:
		return false
	var current := instance.equipped_item(slot)
	if current.is_empty():
		return false
	instance.unequip(slot)
	gear_levels.erase(uid + "|" + slot)
	GameState.inventory_domain.add_item(current, 1)
	EventBus.roster_changed.emit()
	GameState.queue_save()
	return true


func gear_reroll_info(uid: String, slot: String) -> Dictionary:
	var instance := _find_instance(uid)
	if instance == null or not CharacterInstance.SLOTS.has(slot):
		return {"ok": false, "reason": "Invalid character or equipment slot."}
	var item_id := instance.equipped_item(slot)
	if item_id.is_empty():
		return {"ok": false, "reason": "Equip an item in this slot first."}
	var stats: Dictionary = ContentDB.get_item(item_id).get("stats", {})
	var candidates: Array[String] = []
	for stat in ["hp", "atk", "def", "spd", "crit", "crit_dmg"]:
		if float(stats.get(stat, 0.0)) > 0.0:
			candidates.append(stat)
	if candidates.is_empty():
		return {"ok": false, "reason": "This equipment has no rerollable stats."}
	if GameState.inventory_domain.currency("gold") < 120:
		return {"ok": false, "reason": "Need 120 gold."}
	if GameState.inventory_domain.item_count("gothic_shard") < 1:
		return {"ok": false, "reason": "Need 1 Gothic Shard."}
	return {"ok": true, "gold": 120, "shards": 1, "item_id": item_id, "candidates": candidates}


func reroll_gear(uid: String, slot: String) -> Dictionary:
	var info := gear_reroll_info(uid, slot)
	if not bool(info.get("ok", false)):
		return {"ok": false, "reason": str(info.get("reason", "Cannot reroll this equipment."))}
	var key := uid + "|" + slot
	var old_roll: Dictionary = gear_rerolls.get(key, {})
	var candidates: Array = info.get("candidates", [])
	if candidates.size() > 1 and not old_roll.is_empty():
		var previous_stat := str(old_roll.get("stat", ""))
		var alternatives: Array = candidates.filter(func(stat): return str(stat) != previous_stat)
		if not alternatives.is_empty():
			candidates = alternatives
	var chosen := str(candidates[randi_range(0, candidates.size() - 1)])
	var base_stats: Dictionary = ContentDB.get_item(str(info.item_id)).get("stats", {})
	var amount := maxf(1.0, float(base_stats.get(chosen, 0.0)) * 0.10)
	if not GameState.inventory_domain.spend_currency("gold", int(info.gold)):
		return {"ok": false, "reason": "Gold balance changed; reroll cancelled."}
	if not GameState.inventory_domain.remove_item("gothic_shard", int(info.shards)):
		GameState.inventory_domain.add_currency("gold", int(info.gold))
		return {"ok": false, "reason": "Gothic Shard unavailable; gold returned."}
	gear_rerolls[key] = {"stat": chosen, "value": amount}
	EventBus.roster_changed.emit()
	GameState.queue_save()
	return {"ok": true, "stat": chosen, "value": amount, "previous": old_roll.duplicate(true)}


func gear_level(uid: String, slot: String) -> int:
	return clampi(int(gear_levels.get(uid + "|" + slot, 0)), 0, 5)


func gear_upgrade_info(uid: String, slot: String) -> Dictionary:
	var instance := _find_instance(uid)
	if instance == null or not CharacterInstance.SLOTS.has(slot):
		return { "ok": false, "reason": "Invalid character or equipment slot." }
	var item_id := instance.equipped_item(slot)
	if item_id.is_empty():
		return { "ok": false, "reason": "Equip an item in this slot first." }
	var level := gear_level(uid, slot)
	if level >= 5:
		return { "ok": false, "reason": "This item is fully enhanced." }
	var gold_cost := 180 * (level + 1)
	var sap_cost := level + 1
	if GameState.inventory_domain.currency("gold") < gold_cost:
		return { "ok": false, "reason": "Need %d gold." % gold_cost }
	if GameState.inventory_domain.item_count("glade_sap") < sap_cost:
		return { "ok": false, "reason": "Need %d Glade Sap." % sap_cost }
	return { "ok": true, "level": level, "next": level + 1, "gold": gold_cost, "sap": sap_cost, "item_id": item_id }


func enhance_gear(uid: String, slot: String) -> bool:
	var info := gear_upgrade_info(uid, slot)
	if not bool(info.get("ok", false)):
		return false
	if not GameState.inventory_domain.spend_currency("gold", int(info.gold)):
		return false
	if not GameState.inventory_domain.remove_item("glade_sap", int(info.sap)):
		GameState.inventory_domain.add_currency("gold", int(info.gold))
		return false
	gear_levels[uid + "|" + slot] = int(info.next)
	EventBus.roster_changed.emit()
	GameState.queue_save()
	return true



