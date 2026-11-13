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
var _matron_art: Sprite2D = null
var _matron_phase: int = 0
var _matron_art_home := Vector2(0, -96)
var _matron_hit_tween: Tween = null
var _matron_attack_tween: Tween = null
var _matron_phase_tween: Tween = null
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
var _pulse: float = 0.0
var _hit_shake: float = 0.0
var _base_scale: float = 1.0


func setup(p_unit: Combatant, p_is_player: bool) -> void:
	unit = p_unit
	is_player = p_is_player
	var hit := Control.new()
	hit.name = "Hitbox"
	hit.custom_minimum_size = Vector2(72, 110)
	hit.position = Vector2(-36, -96)
	hit.size = Vector2(72, 110)
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	hit.gui_input.connect(_on_hit_input)
	add_child(hit)
	_name_label = Label.new()
	_name_label.text = unit.display_name
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.add_theme_color_override("font_color", UITheme.TEXT)
	_name_label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.05, 0.95))
	_name_label.add_theme_constant_override("outline_size", 4)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)
	_intent_label = Label.new()
	_intent_label.name = "EnemyIntent"
	_intent_label.visible = false
	_intent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intent_label.add_theme_font_size_override("font_size", 10)
	_intent_label.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
	_intent_label.add_theme_color_override("font_outline_color", Color(0.02, 0.015, 0.025, 0.98))
	_intent_label.add_theme_constant_override("outline_size", 5)
	_intent_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_intent_label)

	visual = ActorVisual.new()
	add_child(visual)
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
	# Fallen Matron uses the extracted character-sheet cutout when installed.
	# Keep the procedural actor as a safe fallback until the PNG is present.
	if not is_player and unit.def_id == "fallen_matron":
		var matron_texture_path := "res://assets/enemies/fallen_matron/phase_1.png"
		if ResourceLoader.exists(matron_texture_path):
			var matron_texture := load(matron_texture_path) as Texture2D
			if matron_texture != null:
				_matron_art = Sprite2D.new()
				_matron_art.name = "FallenMatronIllustration"
				_matron_art.texture = matron_texture
				_matron_art.position = _matron_art_home
				# Normalize the source cutout to a consistent on-stage height.
				_matron_art.scale = Vector2.ONE * (180.0 / 528.0)
				_matron_art.z_index = 4
				add_child(_matron_art)
				visual.visible = false
				_start_matron_idle_particles()
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


## The Matron's three health thresholds drive her three supplied original cutouts.
## Each cutout is normalized to the same stage height; only corruption/aura grows.
func _start_matron_idle_particles() -> void:
	# The Matron's cutout is intentionally preserved; drifting violet motes,
	# stronger breathing and veil sway keep the boss visibly alive between turns.
	var motes := CPUParticles2D.new()
	motes.name = "MatronCorruptionMotes"
	motes.amount = 18
	motes.lifetime = 3.2
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 54.0
	motes.position = Vector2(0, -88)
	motes.direction = Vector2(0, -1)
	motes.spread = 42.0
	motes.initial_velocity_min = 5.0
	motes.initial_velocity_max = 18.0
	motes.gravity = Vector2(0, -5.0)
	motes.scale_amount_min = 0.35
	motes.scale_amount_max = 0.85
	motes.color = Color(0.72, 0.32, 0.96, 0.62)
	motes.z_index = 6
	add_child(motes)
	motes.emitting = true


func _refresh_matron_phase() -> void:
	if _matron_art == null or unit == null or unit.def_id != "fallen_matron":
		return
	var next_phase := 1
	if _hp_ratio <= 0.33:
		next_phase = 3
	elif _hp_ratio <= 0.66:
		next_phase = 2
	if next_phase == _matron_phase:
		return
	var previous_phase := _matron_phase
	_matron_phase = next_phase
	# Each stage uses its own cutout from the supplied boss reference sheet.
	# Their source crops have different dimensions, so normalize by authored
	# visual height rather than applying one scale to every stage.
	var phase_path := "res://assets/enemies/fallen_matron/phase_%d.png" % _matron_phase
	var phase_texture := load(phase_path) as Texture2D
	if phase_texture != null:
		_matron_art.texture = phase_texture
	# Source PNGs: phase 1 = 420x528, phase 2 = 410x386,
	# phase 3 = 500x400. Keep their visible height consistent at 180px.
	var target_scale := 180.0 / 528.0
	match _matron_phase:
		2:
			target_scale = 180.0 / 386.0
		3:
			target_scale = 180.0 / 400.0
	_matron_art_home = Vector2(0, -96)
	_matron_art.position = _matron_art_home
	if _matron_phase_tween != null and _matron_phase_tween.is_running():
		_matron_phase_tween.kill()
	_matron_phase_tween = create_tween()
	_matron_phase_tween.tween_property(_matron_art, "scale", Vector2.ONE * target_scale, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_matron_art.modulate = Color(1.0, 1.0, 1.0, 1.0) if _matron_phase == 1 else Color(1.04, 0.94, 1.12, 1.0) if _matron_phase == 2 else Color(1.12, 0.82, 1.22, 1.0)
	if previous_phase > 0:
		_spawn_matron_phase_burst()
	queue_redraw()


func _spawn_matron_phase_burst() -> void:
	var burst := CPUParticles2D.new()
	burst.name = "MatronPhaseBurst"
	burst.amount = 42 if _matron_phase == 3 else 30
	burst.one_shot = true
	burst.explosiveness = 0.92
	burst.lifetime = 0.85
	burst.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 22.0
	burst.direction = Vector2.UP
	burst.spread = 180.0
	burst.initial_velocity_min = 35.0
	burst.initial_velocity_max = 125.0 if _matron_phase == 3 else 90.0
	burst.gravity = Vector2(0.0, -18.0)
	burst.scale_amount_min = 0.35
	burst.scale_amount_max = 1.05
	burst.color = Color("#ed72ff") if _matron_phase == 3 else Color("#b96cff")
	burst.position = _matron_art_home + Vector2(0, -55)
	burst.z_index = 7
	add_child(burst)
	burst.finished.connect(burst.queue_free)
	burst.emitting = true


func refresh() -> void:
	if unit == null:
		return
	_hp_ratio = unit.hp_ratio()
	_refresh_matron_phase()
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
	_refresh_matron_phase()
	if _hit_shake > 0.0:
		_hit_shake = maxf(0.0, _hit_shake - delta * 4.0)
	if visual == null:
		return
	# A subtle breathing bob keeps the idle loop alive without extra nodes.
	var bob := sin(_pulse * 1.7) * 1.6
	if _matron_art != null and is_instance_valid(_matron_art):
		if not dead:
			_matron_art.position = _matron_art_home + Vector2(_hit_shake * 6.0 + sin(_pulse * 0.82) * 2.0, bob * 2.25)
			var action_running := (_matron_attack_tween != null and _matron_attack_tween.is_running()) or (_matron_hit_tween != null and _matron_hit_tween.is_running()) or (_matron_phase_tween != null and _matron_phase_tween.is_running())
			if not action_running:
				var base_scale := 180.0 / (528.0 if _matron_phase == 1 else 386.0 if _matron_phase == 2 else 400.0)
				var breath := sin(_pulse * 1.35)
				_matron_art.scale = Vector2(base_scale * (1.0 + breath * 0.024), base_scale * (1.0 - breath * 0.018))
				_matron_art.rotation = sin(_pulse * 0.62) * 0.022
	else:
		if not dead:
			visual.position = Vector2(_hit_shake * 6.0, bob)


## Damage reaction: white flash + a short shake + the damage animation.
func take_hit() -> void:
	if visual == null:
		return
	_hit_shake = 1.0
	if _matron_art != null and is_instance_valid(_matron_art):
		if _matron_hit_tween != null and _matron_hit_tween.is_running():
			_matron_hit_tween.kill()
		_matron_hit_tween = create_tween()
		_matron_hit_tween.tween_property(_matron_art, "modulate", Color(2.0, 1.45, 2.2, 1.0), 0.055)
		_matron_hit_tween.tween_property(_matron_art, "modulate", Color.WHITE, 0.24)
		_matron_hit_tween.parallel().tween_property(_matron_art, "rotation", deg_to_rad(3.0), 0.06)
		_matron_hit_tween.tween_property(_matron_art, "rotation", 0.0, 0.18)
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
	if _matron_art != null and is_instance_valid(_matron_art):
		if _matron_attack_tween != null and _matron_attack_tween.is_running():
			_matron_attack_tween.kill()
		var attack := create_tween()
		_matron_attack_tween = attack
		var base_scale := 180.0 / (528.0 if _matron_phase == 1 else 386.0 if _matron_phase == 2 else 400.0)
		# A readable anticipation squash, a sharp forward snap, then a heavier
		# recoil. The idle breathing resumes only after this action finishes.
		attack.tween_property(_matron_art, "scale", Vector2(base_scale * 0.92, base_scale * 1.09), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		attack.parallel().tween_property(_matron_art, "rotation", deg_to_rad(5.0), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		attack.tween_property(_matron_art, "scale", Vector2(base_scale * 1.12, base_scale * 0.90), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		attack.parallel().tween_property(_matron_art, "rotation", deg_to_rad(-5.0), 0.10)
		attack.tween_property(_matron_art, "rotation", 0.0, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		attack.parallel().tween_property(_matron_art, "scale", Vector2.ONE * base_scale, 0.26)
		attack.tween_callback(func() -> void: _matron_attack_tween = null)
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
	if _matron_art != null and is_instance_valid(_matron_art):
		var fall := create_tween()
		fall.tween_property(_matron_art, "rotation", deg_to_rad(-12.0), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		fall.parallel().tween_property(_matron_art, "position:y", _matron_art.position.y + 30.0, 0.55)
		fall.parallel().tween_property(_matron_art, "modulate", Color(0.62, 0.38, 0.78, 0.0), 0.62)
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


func _draw() -> void:
	# Ground shadow (drawn under the figure: a Node2D paints itself before its
	# children, so the figure sits on top of it).
	var shadow_radius := 16.0 * _base_scale * (1.25 if unit != null and unit.is_boss else 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(0, 2), shadow_radius * 0.55, Color(0, 0, 0, 0.22))
	draw_circle(Vector2(0, 2), shadow_radius * 0.34, Color(0, 0, 0, 0.20))

	# Enemy identity sigils: a quiet elemental rune under each monster makes
	# crowded encounters easier to parse without competing with target rings.
	if not is_player and unit != null and unit.is_alive():
		var element_color := UITheme.element_color(unit.element)
		if element_color == UITheme.TEXT_DIM:
			element_color = Color("#c6cad6")
		var rune_alpha := 0.12 + 0.05 * (0.5 + 0.5 * sin(_pulse * 1.8))
		var rune_color := Color(element_color.r, element_color.g, element_color.b, rune_alpha)
		var rune_radius := shadow_radius * (1.05 if unit.is_boss else 0.82)
		draw_arc(Vector2(0, 2), rune_radius, _pulse * 0.12, _pulse * 0.12 + TAU * 0.82, 40, rune_color, 2.0 if unit.is_boss else 1.3)
		if unit.is_boss:
			draw_arc(Vector2(0, 2), rune_radius * 1.18, -_pulse * 0.08, -_pulse * 0.08 + TAU * 0.62, 36, Color(rune_color.r, rune_color.g, rune_color.b, rune_alpha * 0.7), 1.0)

	# The Fallen Matron's corruption expands at 66% and 33% HP. The
	# concentric violet sigils sit behind her illustration and pulse gently.
	if _matron_art != null and _matron_phase > 0:
		var pulse := 0.5 + 0.5 * sin(_pulse * (2.2 + float(_matron_phase) * 0.55))
		var alpha := 0.24 + float(_matron_phase - 1) * 0.13 + pulse * 0.12
		var glow := Color(0.68, 0.24, 0.98, alpha)
		var center := Vector2(0, -88)
		var radius := 48.0 + float(_matron_phase - 1) * 7.0
		draw_arc(center, radius, _pulse * -0.35, _pulse * -0.35 + PI * 1.55, 42, glow, 2.2 + float(_matron_phase) * 0.55, true)
		draw_arc(center, radius + 11.0, _pulse * 0.22, _pulse * 0.22 + PI * 1.15, 36, Color(0.88, 0.46, 1.0, alpha * 0.72), 1.5, true)
		if _matron_phase == 3:
			draw_arc(center, radius + 22.0, _pulse * -0.16, _pulse * -0.16 + PI * 1.75, 48, Color(0.96, 0.3, 0.88, alpha * 0.8), 2.0, true)

	# Target marker: a pulsing ring under a targetable enemy.
	if targetable and not dead:
		var glow := 0.5 + 0.5 * sin(_pulse * 4.0)
		var marker_color := Color(UITheme.GOLD_BRIGHT.r, UITheme.GOLD_BRIGHT.g, UITheme.GOLD_BRIGHT.b, 0.35 + 0.35 * glow)
		draw_arc(Vector2(0, 2), shadow_radius * (0.75 + 0.06 * glow), 0.0, TAU, 32, marker_color, 3.0)
		draw_arc(Vector2(0, 2), shadow_radius * (0.92 + 0.08 * glow), 0.0, TAU, 32,
			Color(marker_color.r, marker_color.g, marker_color.b, marker_color.a * 0.48), 1.2)

	# Active actor: a teal arc so the current turn is obvious.
	if active and not dead:
		draw_arc(Vector2(0, 2), shadow_radius * 0.92, 0.0, TAU, 28,
			Color(UITheme.TEAL.r, UITheme.TEAL.g, UITheme.TEAL.b, 0.75), 2.5)

	if dead:
		return

	# HP plate on the ground under the figure.
	var plate_x := -PLATE_WIDTH * 0.5
	var plate_y := PLATE_OFFSET
	draw_rect(Rect2(plate_x - 1.0, plate_y - 1.0, PLATE_WIDTH + 2.0, PLATE_HEIGHT + 2.0),
		Color(0.02, 0.03, 0.06, 0.85))
	draw_rect(Rect2(plate_x, plate_y, PLATE_WIDTH, PLATE_HEIGHT), Color(0.12, 0.10, 0.13, 0.95))
	var fill := PLATE_WIDTH * clampf(_hp_ratio, 0.0, 1.0)
	if fill > 0.5:
		draw_rect(Rect2(plate_x, plate_y, fill, PLATE_HEIGHT), _hp_color)
	else:
		draw_rect(Rect2(plate_x, plate_y, fill, PLATE_HEIGHT), _hp_color)

	if _name_label != null:
		_name_label.position = Vector2(-PLATE_WIDTH * 0.5, plate_y + PLATE_HEIGHT + 2.0)
		_name_label.size = Vector2(PLATE_WIDTH, 16)


func _on_hit_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(self)
