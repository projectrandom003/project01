class_name GameRewardDomainComponent
extends Node
## Owns banner roll orchestration and battle reward application.

var pity: Dictionary = {}

func pull_banner(banner_id: String, count: int) -> Dictionary:
	var banner: Dictionary = ContentDB.get_banner(banner_id)
	if banner.is_empty():
		return {"ok": false, "error": "Unknown banner."}
	if count != 1 and count != 10:
		return {"ok": false, "error": "Invalid summon count."}
	var cost_data: Dictionary = banner.get("cost", {})
	var currency_id := str(cost_data.get("currency", "crystals"))
	var cost := int(cost_data.get("ten" if count == 10 else "single", 0))
	if not GameState.inventory_domain.spend_currency(currency_id, cost):
		return {"ok": false, "error": "Not enough %s." % ContentDB.get_item(currency_id).get("name", currency_id)}

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var pity_state: Dictionary = pity.get(banner_id, GachaService.empty_pity())
	var outcome := GachaService.pull(banner, rng, pity_state, count)
	pity[banner_id] = outcome.pity
	var results: Array = []
	for roll in outcome.results:
		var added: Dictionary = GameState.roster_domain.add_character(str(roll.character_id))
		roll["is_new"] = bool(added.get("is_new", false))
		roll["awakening_gain"] = int(added.get("awakening_gain", 0))
		results.append(roll)
	GameState.queue_save()
	return {"ok": true, "results": results, "pity": outcome.pity, "spent": cost, "currency": currency_id}


func build_battle_rewards(group_id: String, roll_bonus_drops: bool = false) -> Dictionary:
	var group: Dictionary = ContentDB.get_enemy_group(group_id)
	var rewards: Dictionary = group.get("rewards", {})
	var level_mult := 1.0 + 0.12 * maxi(0, int(group.get("level", 1)) - 1)
	var items: Dictionary = rewards.get("items", {}).duplicate(true)
	if roll_bonus_drops:
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		for drop in group.get("drops", []):
			if typeof(drop) != TYPE_DICTIONARY:
				continue
			var chance := clampf(float(drop.get("chance", 0.0)), 0.0, 1.0)
			if chance >= 1.0 or (chance > 0.0 and rng.randf() < chance):
				var item_id := str(drop.get("item", ""))
				var minimum := maxi(1, int(drop.get("min", 1)))
				var maximum := maxi(minimum, int(drop.get("max", minimum)))
				var amount := rng.randi_range(minimum, maximum)
				if not item_id.is_empty():
					items[item_id] = int(items.get(item_id, 0)) + amount
	return {
		"gold": int(round(float(rewards.get("gold", 0)) * level_mult)),
		"crystals": int(round(float(rewards.get("crystals", 0)) * level_mult)),
		"xp": int(round(float(rewards.get("xp", 0)) * level_mult)),
		"items": items,
	}


func apply_battle_result(group_id: String, victory: bool, precomputed_rewards: Dictionary = {}) -> Dictionary:
	if not victory:
		return {"applied": false}
	var group: Dictionary = ContentDB.get_enemy_group(group_id)
	var rewards: Dictionary = precomputed_rewards.duplicate(true) if not precomputed_rewards.is_empty() else build_battle_rewards(group_id, true)
	GameState.inventory_domain.add_currency("gold", int(rewards.get("gold", 0)))
	GameState.inventory_domain.add_currency("crystals", int(rewards.get("crystals", 0)))
	var granted_items: Dictionary = rewards.get("items", {}).duplicate(true)
	GameState.inventory_domain.grant_reward_items(granted_items)
	rewards["items"] = granted_items
	GameState.roster_domain.add_party_xp(int(rewards.get("xp", 0)))
	for uid in GameState.roster_domain.party:
		GameState.roster_domain.add_bond(uid, 2)
	for enemy_id in group.get("quest_kills", {}).keys():
		GameState.quest_domain.record_kill(str(enemy_id), int(group["quest_kills"][enemy_id]))
	EventBus.toast_requested.emit("Victory — +%d gold, +%d crystals" % [int(rewards.get("gold", 0)), int(rewards.get("crystals", 0))])
	GameState.queue_save()
	return {"applied": true, "rewards": rewards}
