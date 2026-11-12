class_name CombatUnitCard
extends PanelContainer
## One combatant card used by both the party and enemy rows. Purely visual:
## CombatScreen owns the engine and asks cards to refresh after events.

signal clicked(card: CombatUnitCard)

var unit: Combatant
var portrait: PortraitView
var _name_label: Label
var _sub_label: Label
var _hp_bar: ProgressBar
var _hp_label: Label
var _energy_bar: ProgressBar
var _energy_label: Label
var _status_label: Label
var _boss_badge: Label
var _current: bool = false
var _targetable: bool = false
var _selected: bool = false
var _hp_tween: Tween = null


func setup(p_unit: Combatant) -> void:
	unit = p_unit
	custom_minimum_size = Vector2(148, 196)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var box := UIFactory.vbox(2)
	add_child(box)

	var portrait_center := CenterContainer.new()
	portrait = PortraitView.new()
	portrait.custom_minimum_size = Vector2(122, 104)
	var definition: CharacterDef = ContentDB.get_character(unit.def_id)
	if definition != null:
		portrait.setup_character(definition)
	else:
		var enemy: Dictionary = ContentDB.get_enemy(unit.def_id)
		portrait.setup(
			enemy.get("palette", {}),
			"Monster",
			unit.element,
			unit.rarity,
			unit.def_id.hash()
		)
	portrait_center.add_child(portrait)
	box.add_child(portrait_center)

	_name_label = UIFactory.label(unit.display_name, 12, UITheme.TEXT)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(_name_label)

	_sub_label = UIFactory.label("Lv %d · %s" % [unit.level, unit.role], 9, UITheme.TEXT_DIM)
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_sub_label)

	var hp_row := UIFactory.hbox(4)
	_hp_bar = UIFactory.bar(UITheme.GREEN if unit.team == 0 else UITheme.DANGER, 8)
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(_hp_bar)
	_hp_label = UIFactory.label("", 8, UITheme.TEXT_DIM)
	hp_row.add_child(_hp_label)
	box.add_child(hp_row)

	var energy_row := UIFactory.hbox(4)
	_energy_bar = UIFactory.bar(UITheme.GOLD, 5)
	_energy_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	energy_row.add_child(_energy_bar)
	_energy_label = UIFactory.label("", 8, UITheme.GOLD)
	energy_row.add_child(_energy_label)
	box.add_child(energy_row)
	energy_row.visible = unit.team == 0

	_status_label = UIFactory.label("", 8, UITheme.TEAL)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(_status_label)

	_boss_badge = UIFactory.label("BOSS", 8, UITheme.GOLD)
	_boss_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_badge.visible = unit.is_boss
	box.add_child(_boss_badge)

	gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clicked.emit(self)
	)
	mouse_entered.connect(func() -> void:
		if _targetable:
			add_theme_stylebox_override("panel", UITheme.style(Color("#243252"), UITheme.GOLD_BRIGHT, 10, 2, 6))
	)
	mouse_exited.connect(func() -> void: _apply_style())
	refresh()


func refresh() -> void:
	if unit == null:
		return
	_hp_bar.max_value = maxf(1.0, unit.max_hp)
	var target_hp := clampf(unit.hp, 0.0, unit.max_hp)
	if _hp_tween != null and is_instance_valid(_hp_tween):
		_hp_tween.kill()
	_hp_tween = create_tween()
	_hp_tween.tween_property(_hp_bar, "value", target_hp, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hp_label.text = "%d/%d" % [int(ceil(unit.hp)), int(round(unit.max_hp))]
	_energy_bar.max_value = maxf(1.0, unit.max_energy)
	_energy_bar.value = clampf(unit.energy, 0.0, unit.max_energy)
	_energy_label.text = "EN %d" % int(round(unit.energy))
	var status := UIFactory.status_text(unit)
	if unit.shield > 0.5:
		status = ("Shield %d" % int(round(unit.shield))) + (" · " + status if not status.is_empty() else "")
	_status_label.text = status
	portrait.dim = not unit.is_alive()
	modulate = Color(1, 1, 1, 0.42) if not unit.is_alive() else Color.WHITE
	_apply_style()


func set_current(value: bool) -> void:
	_current = value
	_apply_style()


func set_targetable(value: bool) -> void:
	_targetable = value
	_apply_style()


func set_selected(value: bool) -> void:
	_selected = value
	_apply_style()


func is_targetable() -> bool:
	return _targetable


func flash(color: Color = Color.WHITE) -> void:
	self_modulate = color
	var tween := create_tween()
	tween.tween_property(self, "self_modulate", Color.WHITE, 0.32)


func _apply_style() -> void:
	var border := UITheme.rarity_color(unit.rarity) if unit != null else UITheme.BORDER
	var width := 1
	var bg := Color("#111a2d")
	# Premium rarity border in the resting state only, so the _current /
	# _targetable / _selected overrides below stay byte-identical. Uses
	# UITheme.rarity_effect; ZERO final portraits exist (portrait is fallback).
	if unit != null and UITheme.is_premium_rarity(unit.rarity) and not (_current or _targetable or _selected):
		var effect := UITheme.rarity_effect(unit.rarity)
		var glow: Color = effect.get("glow", UITheme.GOLD_BRIGHT)
		width = int(effect.get("border_width", 3))
		border = border.lerp(Color(glow.r, glow.g, glow.b, 1.0), 0.35)
		bg = Color("#141d33")
	if _current:
		border = UITheme.TEAL
		width = 2
		bg = Color("#15243a")
	if _targetable:
		border = UITheme.GOLD_BRIGHT
		width = 2
	if _selected:
		border = Color("#ffffff")
		width = 3
	add_theme_stylebox_override("panel", UITheme.style(bg, border, 10, width, 6))
