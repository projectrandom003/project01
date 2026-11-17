class_name CombatTurnOrderComponent
extends Node
## Renders the initiative strip from the combat engine's live turn queue.

var screen: CombatScreen


func bind(owner_screen: CombatScreen) -> void:
	screen = owner_screen


func refresh() -> void:
	if screen == null or screen._turn_box == null or screen.engine == null:
		return
	var engine := screen.engine
	UIFactory.clear(screen._turn_box)
	var sequence: Array[int] = []
	var seen_indices: Dictionary = {}
	var living_count := engine.living(CombatEngine.PLAYER_TEAM).size() + engine.living(CombatEngine.ENEMY_TEAM).size()
	var active_index := engine.current_actor_index
	if active_index >= 0 and active_index < engine.combatants.size():
		var active_unit: Combatant = engine.combatants[active_index]
		if active_unit.is_alive():
			sequence.append(active_index)
			seen_indices[active_index] = true
	if not engine.order.is_empty() and engine.turn_pointer >= 0:
		for offset in range(1, engine.order.size() + 1):
			var order_position := (engine.turn_pointer + offset) % engine.order.size()
			var next_index := int(engine.order[order_position])
			if next_index < 0 or next_index >= engine.combatants.size() or seen_indices.has(next_index):
				continue
			var next_unit: Combatant = engine.combatants[next_index]
			if next_unit.is_alive():
				sequence.append(next_index)
				seen_indices[next_index] = true
	if sequence.size() < living_count:
		var remaining_indices := engine.living_indices(CombatEngine.PLAYER_TEAM) + engine.living_indices(CombatEngine.ENEMY_TEAM)
		remaining_indices.sort_custom(func(a: int, b: int) -> bool:
			return engine.unit_speed(engine.combatants[a]) > engine.unit_speed(engine.combatants[b])
		)
		for next_index in remaining_indices:
			if not seen_indices.has(next_index):
				sequence.append(next_index)
				seen_indices[next_index] = true
	if sequence.is_empty():
		screen._turn_box.add_child(UIFactory.label("—", 10, UITheme.TEXT_FAINT))
		return
	for index in sequence.size():
		var unit: Combatant = engine.combatants[sequence[index]]
		if unit == null:
			continue
		var portrait := CombatScreen.PORTRAIT_VIEW_SCENE.instantiate() as PortraitView
		portrait.show_frame = true
		portrait.show_rarity_effect = false
		portrait.selected = index == 0
		portrait.dim = not unit.is_alive()
		var definition := ContentDB.get_character(unit.def_id) if unit.team == CombatEngine.PLAYER_TEAM else null
		if definition != null:
			portrait.setup_character(definition)
		else:
			portrait.setup(unit.palette, "Monster" if unit.team == CombatEngine.ENEMY_TEAM else "Human", unit.element, unit.rarity, unit.def_id.hash())
			if unit.def_id == "fallen_matron":
				var matron_phase := 1
				if unit.hp_ratio() <= 0.33:
					matron_phase = 3
				elif unit.hp_ratio() <= 0.66:
					matron_phase = 2
				var matron_atlas := load("res://assets/enemies/fallen_matron/phase_%d.png" % matron_phase) as Texture2D
				if matron_atlas != null:
					var matron_portrait := AtlasTexture.new()
					matron_portrait.atlas = matron_atlas
					matron_portrait.region = Rect2(62, 0, 296, 250)
					portrait.set_portrait_texture(matron_portrait)
		portrait.tooltip_text = unit.display_name
		screen._turn_box.add_child(portrait)
		portrait.custom_minimum_size = Vector2(38, 42)
		portrait.size = Vector2(38, 42)
		if index < sequence.size() - 1:
			var arrow := UIFactory.label("›", 13, UITheme.GOLD if index == 0 else UITheme.TEXT_FAINT)
			arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			screen._turn_box.add_child(arrow)
