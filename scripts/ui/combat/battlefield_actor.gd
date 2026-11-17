class_name BattlefieldActor
extends Node2D
## One combatant standing on the battlefield.
##
## PRESENTATION ONLY. It owns the figure (an ActorVisual, so real sprite sheets
## and the procedural placeholder creatures share one code path), the ground
## shadow, the HP plate and the reactive hooks (idle, hit, lunge, death).
## It never touches combat maths: the engine owns HP, damage and turns.

signal clicked(actor: BattlefieldActor)

## Scale for a real painted sprite sheet (the 96x128 world frames).
const SPRITE_SCALE := 1.35
## Scale for the procedural placeholder creature (roughly half the height of a
## painted sprite, so it needs a bigger multiplier to read the same).
const PLACEOLDER_SCALE := 2.0
## Bosses are visibly larger than ordinary combatants.
const BOSS_MULTIPLIER := 1.55

const PLATE_WIDTH := 72.0
const PLATE_HEIGHT := 6.0
const PLATE_OFFSET := 14.0


var unit: Combatant = null
var visual: ActorVisual = null
var _matron_presentation: FallenMatronPresentationComponent
var _boss_action_tween: Tween = null
var is_player: bool = false
var home_position: Vector2 = Vector2.ZERO
var targetable: bool = false
var active: bool = false
var dead: bool = false

var _hp_ratio: float = 1.0
var _hp_color: Color = Color(0.4, 0.9, 0.5)
var _name_label: Label = null
var _intent_label: Label = null
var _hp_plate: ProgressBar = null
var _pulse: float = 0.0
var _hit_shake: float = 0.0
var _base_scale: float = 1.0
var _ground_fx: BattlefieldActorGroundFX = null


func setup(p_unit: Combatant, p_is_player: bool) -> void:
	unit = p_unit
	is_player = p_is_player
	_ground_fx = get_node_or_null("GroundFX") as BattlefieldActorGroundFX
	_matron_presentation = get_node_or_null("MatronPresentation") as FallenMatronPresentationComponent
	var hit := get_node_or_null("Hitbox") as Control
	_name_label = get_node_or_null("NameLabel") as Label
	_intent_label = get_node_or_null("EnemyIntent") as Label
	_hp_plate = get_node_or_null("HPPlate") as ProgressBar
	visual = get_node_or_null("ActorVisual") as ActorVisual
	if _ground_fx == null or _matron_presentation == null or hit == null or _name_label == null or _intent_label == null or _hp_plate == null or visual == null:
		push_error("BattlefieldActor is missing an authored visual, hitbox, label, HP plate, or GroundFX child.")
		return
	hit.custom_minimum_size = Vector2(72, 110)
	hit.position = Vector2(-36, -96)
	hit.size = Vector2(72, 110)
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	if not hit.gui_input.is_connected(_on_hit_input):
		hit.gui_input.connect(_on_hit_input)
	_name_label.text = unit.display_name
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.add_theme_color_override("font_color", UITheme.TEXT)
	_name_label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.05, 0.95))
	_name_label.add_theme_constant_override("outline_size", 4)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.position = Vector2(-PLATE_WIDTH * 0.5, PLATE_OFFSET + PLATE_HEIGHT + 2.0)
	_name_label.size = Vector2(PLATE_WIDTH, 16)
	_intent_label.visible = false
	_intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intent_label.add_theme_font_size_override("font_size", 10)
	_intent_label.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
	_intent_label.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.025, 0.98))
	_intent_label.add_theme_constant_override("outline_size", 5)
	_intent_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The HP plate is scene-owned; this component only configures its presentation.
	if _hp_plate != null:
		_hp_plate.min_value = 0.0
		_hp_plate.max_value = 1.0
		_hp_plate.show_percentage = false
		_hp_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var plate_bg := StyleBoxFlat.new()
		plate_bg.bg_color = Color(0.02, 0.03, 0.06, 0.85)
		plate_bg.border_width_left = 1
		plate_bg.border_width_top = 1
		plate_bg.border_width_right = 1
		plate_bg.border_width_bottom = 1
		plate_bg.border_color = Color(0.01, 0.015, 0.025, 0.95)
		_hp_plate.add_theme_stylebox_override("background", plate_bg)
		var plate_fill := StyleBoxFlat.new()
		plate_fill.bg_color = _hp_color
		_hp_plate.add_theme_stylebox_override("fill", plate_fill)

	visual.is_boss = unit.is_boss
	if is_player:
		var definition := ContentDB.get_character(unit.def_id)
		var race := "Human"
		var kind := ActorVisual.Kind.HUMAN
		if definition != null:
			race = definition.race
			if definition.race == "Spirit":
				kind = ActorVisual.Kind.SPIRIT
			elif definition.race == "Monster":
				kind = ActorVisual.Kind.MONSTER
			visual.setup(definition.palette, kind, unit.def_id, race, unit.element)
			# Real sprite sheets plug in here (Gerald / Lilith / Kael); everyone
			# else keeps the procedural placeholder creature.
			visual.configure_character(unit.def_id)
		else:
			visual.setup(unit.palette, kind, unit.def_id, race, unit.element)
	else:
		# Enemies have no painted sheets yet: the procedural creature renderer
		# draws a species-specific placeholder from the enemy palette.
		visual.setup(unit.palette, ActorVisual.Kind.MONSTER, unit.def_id, "Monster", unit.element)
	# The bespoke boss presentation is a scene-owned child component.
	_matron_presentation.configure(unit, visual)
	_base_scale = SPRITE_SCALE if not visual.using_temporary_art else PLACEOLDER_SCALE
	if unit.is_boss:
		# These hand-drawn silhouettes have different authored heights. Give
		# each a stage-fit scale instead of multiplying every boss equally and
		# clipping the tallest crowns against the top of the battlefield.
		match unit.def_id:
			"corrupted_treant":
				_base_scale = 1.35
			"elder_hollow":
				_base_scale = 1.15
			"fallen_matron":
				_base_scale = 1.35
			_:
				_base_scale *= BOSS_MULTIPLIER
	visual.visual_scale = _base_scale
	_hp_color = UITheme.GREEN if is_player else UITheme.DANGER
	var element_color := UITheme.element_color(unit.element)
	if element_color == UITheme.TEXT_DIM:
		element_color = Color("#c6cad6")
	_ground_fx.configure(is_player, unit.is_boss, unit.def_id == "fallen_matron", element_color)
	_sync_ground_fx()
	face(Vector2(-1.0, 0.0) if is_player else Vector2(1.0, 0.0))
	refresh()


## Direction the figure looks in (screen space).
func face(direction: Vector2) -> void:
	if visual == null:
		return
	if direction.length_squared() < 0.001:
		return
	visual.set_move_direction(direction.normalized())
	visual.facing = 1.0 if direction.x >= 0.0 else -1.0


func refresh() -> void:
	if unit == null:
		return
	_hp_ratio = unit.hp_ratio()
	if _hp_plate != null:
		_hp_plate.value = _hp_ratio
		var plate_fill := _hp_plate.get_theme_stylebox("fill") as StyleBoxFlat
		if plate_fill != null:
			plate_fill.bg_color = _hp_color
	_matron_presentation.refresh_phase(_hp_ratio)
	_name_label.text = ("◆  " if targetable else "") + unit.display_name
	_name_label.add_theme_color_override("font_color",
		UITheme.GOLD_BRIGHT if targetable else UITheme.TEXT if unit.is_alive() else UITheme.TEXT_DIM)
	if not unit.is_alive():
		modulate = Color(1, 1, 1, 0.38)
	queue_redraw()


func set_intent(skill_name: String) -> void:
	if _intent_label == null:
		return
	_intent_label.visible = not skill_name.is_empty() and not is_player and not dead
	_intent_label.text = "!  %s" % skill_name.to_upper() if _intent_label.visible else ""
	_intent_label.position = Vector2(-78, -124 if unit != null and unit.is_boss else -104)
	_intent_label.size = Vector2(156, 20)
	queue_redraw()


func set_targetable(value: bool) -> void:
	if targetable == value:
		return
	targetable = value
	queue_redraw()


func set_active(value: bool) -> void:
	active = value
	queue_redraw()


## The ground position this actor returns to after an attack.
func set_home(position: Vector2) -> void:
	home_position = position


func _process(delta: float) -> void:
	_pulse += delta
	_sync_ground_fx()
	_matron_presentation.refresh_phase(_hp_ratio)
	if _hit_shake > 0.0:
		_hit_shake = maxf(0.0, _hit_shake - delta * 4.0)
	if visual == null:
		return
	# A subtle breathing bob keeps the idle loop alive without extra nodes.
	var bob := sin(_pulse * 1.7) * 1.6
	if _matron_presentation != null and _matron_presentation.active:
		_matron_presentation.update_idle(_pulse, _hit_shake, bob, dead)
	elif not dead:
		visual.position = Vector2(_hit_shake * 6.0, bob)


## Damage reaction: white flash + a short shake + the damage animation.
func take_hit() -> void:
	if visual == null:
		return
	_hit_shake = 1.0
	if _matron_presentation != null and _matron_presentation.active:
		_matron_presentation.take_hit()
		return
	visual.hit()
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(2.2, 2.2, 2.4, 1.0), 0.05)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.28)
	if unit != null and unit.is_boss:
		if _boss_action_tween != null and _boss_action_tween.is_running():
			_boss_action_tween.kill()
		_boss_action_tween = create_tween()
		_boss_action_tween.tween_property(visual, "rotation", deg_to_rad(4.0), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_boss_action_tween.parallel().tween_property(visual, "scale", Vector2(1.12, 0.88), 0.07)
		_boss_action_tween.tween_property(visual, "rotation", deg_to_rad(-1.8), 0.07)
		_boss_action_tween.parallel().tween_property(visual, "scale", Vector2(0.96, 1.04), 0.08)
		_boss_action_tween.tween_property(visual, "rotation", 0.0, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_boss_action_tween.parallel().tween_property(visual, "scale", Vector2.ONE, 0.13)


## The attack lunge is driven by the battlefield (it knows the target).
func play_attack() -> void:
	if visual == null:
		return
	if _matron_presentation != null and _matron_presentation.active:
		_matron_presentation.play_attack()
		return
	visual.play_attack()
	if unit != null and unit.is_boss:
		if _boss_action_tween != null and _boss_action_tween.is_running():
			_boss_action_tween.kill()
		_boss_action_tween = create_tween()
		# Bosses telegraph with a heavier coil, snap into the strike, then settle
		# back into their idle silhouette instead of using the same tiny hit bob.
		_boss_action_tween.tween_property(visual, "scale", Vector2(0.90, 1.12), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_boss_action_tween.parallel().tween_property(visual, "rotation", deg_to_rad(-3.0), 0.20)
		_boss_action_tween.tween_property(visual, "scale", Vector2(1.14, 0.88), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_boss_action_tween.parallel().tween_property(visual, "rotation", deg_to_rad(2.5), 0.10)
		_boss_action_tween.tween_property(visual, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_boss_action_tween.parallel().tween_property(visual, "rotation", 0.0, 0.30)


func play_victory() -> void:
	if visual == null:
		return
	visual.play_victory()


func play_death() -> void:
	if visual == null:
		return
	dead = true
	if _matron_presentation != null and _matron_presentation.active:
		_matron_presentation.play_death()
	else:
		visual.play_defeat()
		if unit != null and unit.is_boss:
			if _boss_action_tween != null and _boss_action_tween.is_running():
				_boss_action_tween.kill()
			_boss_action_tween = create_tween()
			_boss_action_tween.tween_property(visual, "rotation", deg_to_rad(12.0), 0.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			_boss_action_tween.parallel().tween_property(visual, "position:y", visual.position.y + 24.0, 0.62)
			_boss_action_tween.parallel().tween_property(visual, "scale", Vector2(0.72, 1.18), 0.62)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0.0), 0.68)
	_name_label.modulate = Color(1, 1, 1, 0.0)


func _sync_ground_fx() -> void:
	if _ground_fx == null or not is_instance_valid(_ground_fx) or unit == null:
		return
	_ground_fx.update_state(_pulse, targetable, active, dead, _base_scale, _matron_presentation.get_phase())


func _on_hit_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(self)
