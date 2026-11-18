class_name CombatSessionComponent
extends Node
## Owns battle initialization and party/enemy staging for one CombatScreen.

var screen: CombatScreen

func bind(owner_screen: CombatScreen) -> void:
	screen = owner_screen

func start_battle() -> void:
	if screen == null or not is_instance_valid(screen):
		return
	screen._resolved = false
	screen._targeting_component.reset()
	screen._turn_token += 1
	if screen._feedback != null:
		screen._feedback.clear_log()

	var group: Dictionary = ContentDB.get_enemy_group(screen.group_id)
	if group.is_empty():
		push_error("[CombatScreen] Unknown enemy group: " + screen.group_id)
		screen._claim(false)
		return
	screen._title_label.text = str(group.get("name", screen.group_id))
	screen._round_label.text = "Round 1"

	var player_units := CombatFactory.player_units()
	var enemy_units := CombatFactory.enemy_units(screen.group_id)
	if player_units.is_empty() or enemy_units.is_empty():
		push_error("[CombatScreen] Battle has no units.")
		screen._claim(false)
		return

	screen.engine = CombatEngine.new()
	screen.engine.setup(player_units, enemy_units, randi())
	for unit in enemy_units:
		if unit.is_boss:
			if screen._boss_name_label != null:
				screen._boss_name_label.text = unit.display_name
			if screen._boss_hp_bar != null:
				screen._boss_hp_bar.max_value = unit.max_hp
				screen._boss_hp_bar.value = unit.hp
			if screen._boss_bar_container != null:
				screen._boss_bar_container.visible = true
			screen._show_banner("Boss: " + unit.display_name)

	var party_units: Array = []
	var enemy_stage_units: Array = []
	for unit in screen.engine.combatants:
		if unit.team == CombatEngine.PLAYER_TEAM:
			party_units.append(unit)
		else:
			enemy_stage_units.append(unit)
	if screen._battlefield != null:
		screen._battlefield.setup(party_units, enemy_stage_units)
	screen._build_roster(party_units)
	screen._log("[color=#e8c27a]Battle begins.[/color]")
	await screen._process_events(screen.engine.start())


## Executes a validated player or AI choice through the same presentation path.
## The engine resolves outcomes; this component coordinates the screen-facing
## action lifecycle so manual, enemy and auto turns cannot drift apart.
func execute_action(skill_id: String, targets: Array) -> void:
	if screen == null or not is_instance_valid(screen) or screen.engine == null or screen._resolved:
		return
	var actor: Combatant = screen.engine.current_actor()
	if actor == null:
		return
	var played_skill: SkillDef = ContentDB.get_skill(skill_id)
	if played_skill != null and played_skill.ultimate:
		screen._show_banner(played_skill.display_name)
	screen._cancel_targeting()
	var events := screen.engine.execute(screen.engine.current_actor_index, skill_id, targets)
	await screen._process_events(events)
