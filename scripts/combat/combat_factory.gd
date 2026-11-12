class_name CombatFactory
extends RefCounted
## Translates saved progression (CharacterInstance) and enemy group data into
## battle-ready Combatants. All stat scaling lives here so combat math stays
## pure and testable.

const PLAYER_HP_SCALE := 1.0


static func player_units() -> Array:
	var units: Array = []
	var bonus := GameState.collection_bonus()
	for instance in GameState.party_instances():
		var unit := build_from_character(instance, bonus)
		if unit != null:
			units.append(unit)
	return units


static func build_from_character(instance: CharacterInstance, collection_bonus: float = 1.0) -> Combatant:
	var definition: CharacterDef = ContentDB.get_character(instance.char_id)
	if definition == null:
		return null
	var unit := Combatant.new()
	unit.uid = "p_" + instance.uid
	unit.def_id = definition.id
	unit.display_name = definition.display_name
	unit.element = definition.element
	unit.rarity = definition.rarity
	unit.role = definition.role
	unit.level = instance.level
	unit.palette = definition.palette
	var mult := instance.power_multiplier() * collection_bonus
	unit.max_hp = definition.effective_stat("hp", instance.level, instance.ascension) * mult * PLAYER_HP_SCALE
	unit.atk = definition.effective_stat("atk", instance.level, instance.ascension) * mult
	unit.defense = definition.effective_stat("def", instance.level, instance.ascension) * mult
	unit.speed = definition.effective_stat("spd", instance.level, instance.ascension) * (1.0 + 0.02 * (instance.level - 1))
	unit.crit_chance = definition.effective_stat("crit", instance.level, instance.ascension)
	unit.crit_mult = definition.effective_stat("crit_dmg", instance.level, instance.ascension)
	# Bond bonus: small ATK increase per bond level.
	unit.atk *= (1.0 + GameState.bond_bonus_atk(instance.uid))
	unit.skills = definition.skills.duplicate()
	unit.ultimate = definition.ultimate
	unit.passive_id = definition.passive_id
	_apply_equipment(unit, instance)
	unit.hp = unit.max_hp
	unit.energy = 0.0
	return unit


static func _apply_equipment(unit: Combatant, instance: CharacterInstance) -> void:
	for slot in CharacterInstance.SLOTS:
		var item_id := instance.equipped_item(slot)
		if item_id.is_empty():
			continue
		var item: Dictionary = ContentDB.get_item(item_id)
		var stats: Dictionary = item.get("stats", {})
		unit.max_hp += float(stats.get("hp", 0))
		unit.atk += float(stats.get("atk", 0))
		unit.defense += float(stats.get("def", 0))
		unit.speed += float(stats.get("spd", 0))
		unit.crit_chance += float(stats.get("crit", 0))
		if stats.has("crit_dmg"):
			unit.crit_mult += float(stats.get("crit_dmg", 0))
		# The first elemental item (weapon slots are checked first) defines the
		# wielder's resonance element. The combat engine turns that into damage.
		if unit.equipment_element.is_empty():
			var element := str(item.get("element", ""))
			if not element.is_empty() and element != "neutral":
				unit.equipment_element = element


static func enemy_units(group_id: String) -> Array:
	var group: Dictionary = ContentDB.get_enemy_group(group_id)
	var units: Array = []
	if group.is_empty():
		return units
	var level := maxi(1, int(group.get("level", 1)))
	var level_mult := 1.0 + 0.15 * (level - 1)
	var seen: Dictionary = {}
	for enemy_id in group.get("enemies", []):
		var definition: Dictionary = ContentDB.get_enemy(str(enemy_id))
		if definition.is_empty():
			continue
		var unit := Combatant.new()
		var count := int(seen.get(enemy_id, 0)) + 1
		seen[enemy_id] = count
		unit.uid = "e_%s_%d" % [enemy_id, count]
		unit.def_id = str(enemy_id)
		unit.display_name = str(definition.get("name", enemy_id))
		if count > 1:
			unit.display_name += " " + String.chr(64 + count)
		unit.element = str(definition.get("element", "neutral"))
		unit.rarity = str(definition.get("rarity", "common"))
		unit.role = str(definition.get("role", "Enemy"))
		unit.level = level
		unit.palette = definition.get("palette", {})
		var base: Dictionary = definition.get("base", {})
		unit.max_hp = float(base.get("hp", 100)) * level_mult
		unit.atk = float(base.get("atk", 10)) * level_mult
		unit.defense = float(base.get("def", 10)) * level_mult
		unit.speed = float(base.get("spd", 10)) * (1.0 + 0.02 * (level - 1))
		unit.crit_chance = float(base.get("crit", 0.03))
		unit.crit_mult = 1.6
		unit.skills = definition.get("skills", []).duplicate()
		unit.ultimate = str(definition.get("ultimate", ""))
		unit.is_boss = bool(group.get("boss", false)) or bool(group.get("elite", false))
		unit.phases = definition.get("phases", [])
		unit.hp = unit.max_hp
		unit.energy = 0.0
		units.append(unit)
	return units
