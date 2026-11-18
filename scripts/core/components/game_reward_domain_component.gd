class_name GameRewardDomainComponent
extends Node
## Owns banner roll orchestration and battle reward application.

var pity: Dictionary = {}

const DAILY_REWARDS := [
	{"gold": 300},
	{"crystals": 100},
	{"items": {"glade_sap": 2}},
	{"gold": 500},
	{"items": {"gothic_shard": 1}},
	{"crystals": 200},
	{"crystals": 500, "ancient_coins": 1, "items": {"moonpetal": 2}}
]


func daily_reward_status() -> Dictionary:
	var today := _local_day_key()
	var saved: Dictionary = GameState.daily_rewards
	var last_claim := str(saved.get("last_claim_date", ""))
	var day := clampi(int(saved.get("cycle_day", 1)), 1, DAILY_REWARDS.size())
	return {
		"can_claim": last_claim != today,
		"day": day,
		"last_claim_date": last_claim,
		"today": today,
		"reward": DAILY_REWARDS[day - 1].duplicate(true)
	}


func claim_daily_reward() -> Dictionary:
	var status := daily_reward_status()
	if not bool(status.can_claim):
		return {"ok": false, "reason": "Today's reward has already been claimed."}
	var reward: Dictionary = status.reward
	var next_day := int(status.day) + 1
	if next_day > DAILY_REWARDS.size():
		next_day = 1
	if int(reward.get("gold", 0)) > 0:
		GameState.inventory_domain.add_currency("gold", int(reward.gold))
	if int(reward.get("crystals", 0)) > 0:
		GameState.inventory_domain.add_currency("crystals", int(reward.crystals))
	if int(reward.get("ancient_coins", 0)) > 0:
		GameState.inventory_domain.add_currency("ancient_coins", int(reward.ancient_coins))
	var items: Dictionary = reward.get("items", {})
	if not items.is_empty():
		GameState.inventory_domain.grant_reward_items(items)
	GameState.daily_rewards = {
		"last_claim_date": str(status.today),
		"cycle_day": next_day,
		"last_claimed_day": int(status.day)
	}
	GameState.queue_save()
	return {"ok": true, "day": int(status.day), "reward": reward, "next_day": next_day}


func _local_day_key() -> String:
	var date := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(date.year), int(date.month), int(date.day)]



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
		"ancient_coins": int(rewards.get("ancient_coins", 0)),
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
	GameState.inventory_domain.add_currency("ancient_coins", int(rewards.get("ancient_coins", 0)))
	var granted_items: Dictionary = rewards.get("items", {}).duplicate(true)
	GameState.inventory_domain.grant_reward_items(granted_items)
	rewards["items"] = granted_items
	GameState.roster_domain.add_party_xp(int(rewards.get("xp", 0)))
	for uid in GameState.roster_domain.party:
		GameState.roster_domain.add_bond(uid, 2)
	for enemy_id in group.get("quest_kills", {}).keys():
		GameState.quest_domain.record_kill(str(enemy_id), int(group["quest_kills"][enemy_id]))
	var reward_toast := "Victory — +%d gold, +%d crystals" % [int(rewards.get("gold", 0)), int(rewards.get("crystals", 0))]
	if int(rewards.get("ancient_coins", 0)) > 0:
		reward_toast += ", +%d Ancient Coins" % int(rewards.get("ancient_coins", 0))
	EventBus.toast_requested.emit(reward_toast)
	GameState.queue_save()
	return {"applied": true, "rewards": rewards}
