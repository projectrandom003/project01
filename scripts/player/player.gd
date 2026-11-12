class_name Player
extends CharacterBody2D
## Eight-direction isometric player controller.
## Keyboard, controller and touch joystick all feed the same input vector, so
## movement feel is identical on every platform.
##
## Phase 3 / Step 4: input now also drives the ActorVisual 8-direction animation
## pipeline (WALK / RUN / IDLE) and a few cosmetic one-shots through EventBus.
## All public behaviour (input, movement, camera, zoom, interaction scan,
## try_interact(), current_prompt(), input_enabled, visual, camera,
## nearby_interactable, WALK_SPEED/RUN_SPEED, the "player" group) is preserved.

const WALK_SPEED := 235.0
const RUN_SPEED := 350.0
const ACCELERATION := 1700.0
const FRICTION := 2100.0
const MIN_ZOOM := 0.72
const MAX_ZOOM := 1.85

# Animation state ids (mirror CharacterAnimator.State / ActorVisual.S_*).
const ANIM_IDLE := 0
const ANIM_WALK := 1
const ANIM_RUN := 2
const GLOW_INTERVAL := 0.25

var input_enabled: bool = true
var visual: ActorVisual
var camera: Camera2D
var nearby_interactable: Interactable = null

var _zoom: float = 1.1
var _scan_accumulator: float = 0.0
var _glow_timer: float = 0.0
var _name_label: Label
var _glow: PointLight2D


func _ready() -> void:
	add_to_group("player")
	input_enabled = true
	collision_layer = 2
	collision_mask = 1

	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 9.0
	capsule.height = 22.0
	shape.shape = capsule
	shape.position = Vector2(0, -10)
	add_child(shape)

	visual = ActorVisual.new()
	# Hero palette kept as stable String literals (matches GreenwardStyle.MAGIC /
	# CANOPY accents; there is no character-palette entry in GreenwardStyle).
	var hero_palette := {
		"hair": "#5a3a2a",
		"primary": "#2f4a6b",
		"secondary": "#c9a45a",
		"accent": "#7fe3e0",
		"skin": "#f0cbb0",
	}
	visual.setup(hero_palette, ActorVisual.Kind.HUMAN, "player", "Human", "wind")
	add_child(visual)
	# Phase-2: register the ONE fully integrated demonstration character. The
	# in-memory SpriteFrames sheet is TEMPORARY procedural art (no painted
	# assets exist yet) but exercises the whole SpriteFramesActorSource path.
	# Its is_temporary() is TRUE, so visual.using_temporary_art stays TRUE.
	visual.set_frame_source(DemoCharacterFrames.new("player", hero_palette))

	_name_label = Label.new()
	_name_label.text = str(GameState.profile.get("name", "Wanderer"))
	_name_label.position = Vector2(-70, -78)
	_name_label.size = Vector2(140, 20)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.add_theme_color_override("font_color", Color(0.86, 0.95, 1.0, 0.9))
	_name_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.06, 0.9))
	_name_label.add_theme_constant_override("outline_size", 4)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

	camera = Camera2D.new()
	camera.position = Vector2(0, -30)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.zoom = Vector2.ONE * _zoom
	add_child(camera)
	camera.make_current()

	# Warm personal light so the hero reads against night ambience.
	_glow = PointLight2D.new()
	_glow.texture = ProceduralArt.soft_glow(Color(1.0, 0.86, 0.62, 0.55), 128)
	_glow.color = Color(1.0, 0.9, 0.72)
	_glow.energy = 0.55
	_glow.texture_scale = 2.6
	_glow.position = Vector2(0, -18)
	add_child(_glow)

	_connect_visual_events()


func _physics_process(delta: float) -> void:
	if not input_enabled:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		move_and_slide()
		visual.walking = false
		if visual != null:
			visual.set_move_direction(Vector2.ZERO)
			visual.play(ANIM_IDLE)
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if TouchInput.move_vector.length_squared() > 0.01:
		input_vector = TouchInput.move_vector
	input_vector = input_vector.limit_length(1.0)

	var sprinting := Input.is_action_pressed("sprint")
	var speed := RUN_SPEED if sprinting else WALK_SPEED
	if input_vector.length_squared() > 0.001:
		velocity = velocity.move_toward(input_vector * speed, ACCELERATION * delta)
		if absf(input_vector.x) > 0.08:
			visual.facing = 1.0 if input_vector.x > 0.0 else -1.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	move_and_slide()

	# Drive the 8-direction animator + explicit locomotion state.
	var moving := velocity.length() > 18.0
	visual.set_move_direction(input_vector)
	visual.walking = moving  # backward-compatible assignment
	if moving:
		visual.play(ANIM_RUN if sprinting else ANIM_WALK)
	else:
		visual.play(ANIM_IDLE)


func _process(delta: float) -> void:
	_scan_accumulator += delta
	if _scan_accumulator >= 0.12:
		_scan_accumulator = 0.0
		_scan_for_interactable()

	if Input.is_action_pressed("zoom_in"):
		_set_zoom(_zoom - 0.65 * delta)
	if Input.is_action_pressed("zoom_out"):
		_set_zoom(_zoom + 0.65 * delta)

	_glow_timer += delta
	if _glow_timer >= GLOW_INTERVAL:
		_glow_timer = 0.0
		_update_glow()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(_zoom - 0.08)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(_zoom + 0.08)


func _set_zoom(value: float) -> void:
	_zoom = clampf(value, MIN_ZOOM, MAX_ZOOM)
	if camera != null:
		camera.zoom = Vector2.ONE * _zoom


func _scan_for_interactable() -> void:
	var best: Interactable = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("interactables"):
		if not (node is Interactable):
			continue
		var candidate := node as Interactable
		if not candidate.can_interact():
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance <= candidate.interaction_radius and distance < best_distance:
			best = candidate
			best_distance = distance
	nearby_interactable = best


func try_interact() -> void:
	if nearby_interactable != null and is_instance_valid(nearby_interactable):
		if visual != null:
			visual.play_interact()
		nearby_interactable.interact()


func current_prompt() -> String:
	if nearby_interactable == null:
		return ""
	return nearby_interactable.prompt


# ------------------------------------------------- cosmetic animation hooks

## Public one-shot hooks (safe to call from anywhere). There is no EventBus
## DAMAGE signal, so play_damage() is exposed directly; the other three are
## wired to existing EventBus signals below.
func play_damage() -> void:
	if visual != null:
		visual.hit()


func play_victory() -> void:
	if visual != null:
		visual.play_victory()


func play_defeat() -> void:
	if visual != null:
		visual.play_defeat()


func play_attack() -> void:
	if visual != null:
		visual.play_attack()


## Phase-2: trigger the additive CAST one-shot on the demonstration character.
func play_cast() -> void:
	if visual != null:
		visual.play_cast()


func _connect_visual_events() -> void:
	if not EventBus.battle_finished.is_connected(_on_battle_finished):
		EventBus.battle_finished.connect(_on_battle_finished)
	if not EventBus.encounter_requested.is_connected(_on_encounter_requested):
		EventBus.encounter_requested.connect(_on_encounter_requested)


func _on_battle_finished(result: Dictionary) -> void:
	if bool(result.get("victory", false)):
		play_victory()
	else:
		play_defeat()


func _on_encounter_requested(_group_id: String, _source: Node) -> void:
	play_attack()


## Optional: modulate the personal glow energy from the active day phase.
func _update_glow() -> void:
	if _glow == null:
		return
	var phase := _find_phase()
	var data := GreenwardStyle.phase(phase)
	var ambient := float(data.get("ambient", 1.0))
	_glow.energy = clampf(0.35 + (1.0 - ambient) * 0.9, 0.35, 1.2)


func _find_phase() -> String:
	var n: Node = self
	while n != null:
		if n.has_method("day_phase"):
			return n.day_phase()
		n = n.get_parent()
	return "Day"
