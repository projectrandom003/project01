class_name Combatant
extends RefCounted
## One unit in a battle. Pure data + status math; no scene access.

var uid: String = ""
var def_id: String = ""
var display_name: String = ""
var team: int = 0                    # 0 = player, 1 = enemy
var element: String = "neutral"
var rarity: String = "common"
var role: String = ""
var level: int = 1
var combat_index: int = -1

var max_hp: float = 100.0
var hp: float = 100.0
var atk: float = 10.0
var defense: float = 10.0
var speed: float = 10.0
var crit_chance: float = 0.05
var crit_mult: float = 1.6

var energy: float = 0.0
var max_energy: float = 100.0
var shield: float = 0.0

var skills: Array = []
var ultimate: String = ""
var passive_id: String = ""
var equipment_element: String = ""
var palette: Dictionary = {}
var is_boss: bool = false
var phases: Array = []
var triggered_phases: Array = []

var statuses: Array = []             # [{id, turns, potency}]
var skill_cooldowns: Dictionary = {}  # skill_id -> turns remaining (plus active-turn offset)


func is_alive() -> bool:
	return hp > 0.0


func hp_ratio() -> float:
	return clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)


func status_total(status_id: String) -> float:
	var total := 0.0
	for status in statuses:
		if str(status.get("id", "")) == status_id:
			total += float(status.get("potency", 0.0))
	return total


func has_status(status_id: String) -> bool:
	for status in statuses:
		if str(status.get("id", "")) == status_id:
			return true
	return false


func effective_atk() -> float:
	var multiplier := 1.0 + status_total("atk_up") - status_total("atk_down")
	return maxf(1.0, atk * clampf(multiplier, 0.25, 3.0))


func effective_defense() -> float:
	var multiplier := 1.0 + status_total("def_up") - status_total("def_down")
	return maxf(1.0, defense * clampf(multiplier, 0.2, 3.0))


func effective_speed() -> float:
	var multiplier := 1.0 + status_total("spd_up") - status_total("spd_down")
	return maxf(1.0, speed * clampf(multiplier, 0.25, 3.0))


func ultimate_ready() -> bool:
	return not ultimate.is_empty() and energy >= max_energy


func cooldown_remaining(skill_id: String) -> int:
	return maxi(0, int(skill_cooldowns.get(skill_id, 0)))


func is_skill_on_cooldown(skill_id: String) -> bool:
	return int(skill_cooldowns.get(skill_id, 0)) > 0


func start_skill_cooldown(skill_id: String, turns: int) -> void:
	if turns <= 0:
		skill_cooldowns.erase(skill_id)
		return
	# The extra tick is consumed at the start of the current actor's next turn,
	# so a value of 2 blocks two complete future turns.
	skill_cooldowns[skill_id] = turns + 1


func tick_skill_cooldowns() -> Array:
	var ready: Array = []
	for skill_id in skill_cooldowns.keys():
		var remaining := int(skill_cooldowns[skill_id]) - 1
		if remaining <= 0:
			skill_cooldowns.erase(skill_id)
			ready.append(str(skill_id))
		else:
			skill_cooldowns[skill_id] = remaining
	return ready


func add_energy(amount: float) -> void:
	energy = clampf(energy + amount, 0.0, max_energy)


func apply_status(status_id: String, turns: int, potency: float) -> void:
	if status_id == "shield":
		shield += max_hp * potency
		return
	if status_id == "cleanse":
		return
	for status in statuses:
		if str(status.get("id", "")) == status_id:
			status.turns = maxi(int(status.get("turns", 0)), turns)
			status.potency = maxf(float(status.get("potency", 0.0)), potency)
			return
	statuses.append({ "id": status_id, "turns": turns, "potency": potency })


func cleanse() -> void:
	var kept: Array = []
	for status in statuses:
		var status_id := str(status.get("id", ""))
		if status_id in ["atk_up", "def_up", "spd_up", "regen"]:
			kept.append(status)
	statuses = kept


func take_damage(amount: float) -> Dictionary:
	var incoming := maxf(0.0, amount)
	var absorbed := minf(shield, incoming)
	shield -= absorbed
	incoming -= absorbed
	hp = maxf(0.0, hp - incoming)
	return { "damage": incoming, "absorbed": absorbed, "dead": hp <= 0.0 }


func heal(amount: float) -> float:
	var before := hp
	hp = minf(max_hp, hp + maxf(0.0, amount))
	return hp - before


func status_names() -> Array:
	var names: Array = []
	for status in statuses:
		names.append(str(status.get("id", "")))
	return names
