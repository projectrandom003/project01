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

const ACTOR_VISUAL_SCENE: PackedScene = preload("res://scenes/characters/actor_visual.tscn")
const WALK_SPEED := 235.0
const RUN_SPEED := 350.0
const ACCELERATION := 1700.0
const FRICTION := 2100.0
## Movement-feel tuning. Reversing or sharply turning against current velocity
## brakes up to TURN_BRAKE_MULT x harder so direction changes feel snappy.
const TURN_BRAKE_MULT := 1.8
## Walk <-> sprint target speed eases at this rate (1/s) instead of snapping.
const SPEED_BLEND_RATE := 10.0
## Below this speed with no input the player stops dead (no idle creep).
const STOP_SNAP_SPEED := 18.0
## Touch joystick sprint: push past ENTER, ease back below EXIT (hysteresis).
const TOUCH_SPRINT_ENTER := 0.92
const TOUCH_SPRINT_EXIT := 0.80
## Camera leads the player's movement by up to LOOKAHEAD px (vertical damped).
const LOOKAHEAD := 28.0
const LOOKAHEAD_VERTICAL := 0.6
const LOOKAHEAD_RATE := 5.0
const MIN_ZOOM := 0.72
const MAX_ZOOM := 1.85
## Gerald is a large Guardian, but must remain within the scale of the
## village environment. His sprite is deliberately a little shorter than a
## standard 128 px glade tree; do not compensate by zooming the camera out.
const GERALD_CAMERA_ZOOM_FACTOR := 1.0

## The Wanderer's original hero palette (unchanged placeholder identity).
const HERO_PALETTE := {
	"hair": "#5a3a2a",
	"primary": "#2f4a6b",
	"secondary": "#c9a45a",
	"accent": "#7fe3e0",
	"skin": "#f0cbb0",
}

# Animation state ids (mirror CharacterAnimator.State / ActorVisual.S_*).
const ANIM_IDLE := 0
const ANIM_WALK := 1
const ANIM_RUN := 2
const GLOW_INTERVAL := 0.25

var input_enabled: bool = true
var visual: ActorVisual
var camera: Camera2D
var nearby_interactable: Interactable = null
## "" = the Wanderer placeholder avatar. Any other value is a party character id
## whose validated world_sheet.tres is driving the Sprite2D.
var avatar_id: String = ""

# World-art scale ratios. Kael's 183 px frame is the 1.0 reference.
# Gerald's 128 px frame is scaled to 0.75x Kael's rendered frame height.
# These values affect sprite geometry only, not gameplay collision dimensions.
const AVATAR_HEIGHT_SCALE := {
	"kael": 1.0,
	"gerald": (0.75 * 183.0) / 128.0,
	"lilith": 130.0 / 183.0,
}

var _zoom: float = 1.1
var _speed_target: float = WALK_SPEED
var _touch_sprint: bool = false
var _scan_accumulator: float = 0.0
var _glow_timer: float = 0.0
var _in_water: bool = false
var _water_surface: Sprite2D = null
var _name_label: Label
var _glow: PointLight2D
var facing_direction: Vector2 = Vector2(0.0, 1.0)


func _ready() -> void:
	add_to_group("player")
	input_enabled = true
	collision_layer = 2
	collision_mask = 1

	# Prefer the authored Player scene hierarchy. Runtime fallbacks preserve
	# compatibility with headless tests and legacy callers that still use Player.new().
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null:
		shape = CollisionShape2D.new()
		var capsule := CapsuleShape2D.new()
		capsule.radius = 9.0
		capsule.height = 22.0
		shape.shape = capsule
		shape.position = Vector2(0, -10)
		add_child(shape)

	visual = get_node_or_null("ActorVisual") as ActorVisual
	if visual == null:
		visual = ACTOR_VISUAL_SCENE.instantiate() as ActorVisual
		add_child(visual)
	# Hero palette kept as stable String literals (matches GreenwardStyle.MAGIC /
	# CANOPY accents; there is no character-palette entry in GreenwardStyle).
	visual.setup(HERO_PALETTE, ActorVisual.Kind.HUMAN, "player", "Human", "wind")
	# Do not attach the generic Wanderer demo frames here. The player must
	# never render a placeholder before Kael's final playable art is selected.

	_name_label = get_node_or_null("NameLabel") as Label
	if _name_label == null:
		_name_label = Label.new() # compatibility for Player.new() test fixtures
		_name_label.name = "NameLabel"
		_name_label.position = Vector2(-70, -78)
		_name_label.size = Vector2(140, 20)
		add_child(_name_label)
	_name_label.text = str(GameState.profile.get("name", "Wanderer"))
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 11)
	_name_label.add_theme_color_override("font_color", Color(0.86, 0.95, 1.0, 0.9))
	_name_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.06, 0.9))
	_name_label.add_theme_constant_override("outline_size", 4)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	camera = get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		camera = Camera2D.new()
		camera.position = Vector2(0, -30)
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 12.0
		add_child(camera)
	camera.zoom = Vector2.ONE * _zoom
	camera.make_current()

	# Warm personal light so the hero reads against night ambience.
	_glow = get_node_or_null("PersonalGlow") as PointLight2D
	if _glow == null:
		_glow = PointLight2D.new() # compatibility for Player.new() test fixtures
		_glow.name = "PersonalGlow"
		_glow.position = Vector2(0, -18)
		add_child(_glow)
	_glow.texture = ProceduralArt.soft_glow(Color(1.0, 0.86, 0.88, 0.55), 128)
	_glow.color = Color(1.0, 0.9, 0.72)
	_glow.energy = 0.55
	_glow.texture_scale = 2.6
	_water_surface = get_node_or_null("WaterSurface") as Sprite2D
	if _water_surface == null:
		_water_surface = Sprite2D.new() # compatibility for Player.new() test fixtures
		_water_surface.name = "WaterSurface"
		_water_surface.texture = ProceduralArt.white_pixel()
		_water_surface.scale = Vector2(46, 5)
		_water_surface.position = Vector2(0, -20)
		_water_surface.modulate = Color(0.35, 0.68, 0.86, 0.58)
		_water_surface.z_index = 5
		_water_surface.visible = false
		add_child(_water_surface)
	_water_surface.texture = ProceduralArt.white_pixel()

	_connect_visual_events()
	# Kael is the canonical player-controlled protagonist. Start the world
	# avatar with his validated playable art instead of the Wanderer demo.
	set_avatar("kael")


func _physics_process(delta: float) -> void:
	if not input_enabled:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		move_and_slide()
		visual.walking = false
		_touch_sprint = false
		_update_camera_lookahead(delta, Vector2.ZERO, 0.0)
		if visual != null:
			visual.set_move_direction(Vector2.ZERO)
			visual.play(ANIM_IDLE)
		GameState.set_player_facing(facing_direction)
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var touch_driven := TouchInput.move_vector.length_squared() > 0.01
	if touch_driven:
		input_vector = TouchInput.move_vector
	input_vector = input_vector.limit_length(1.0)

	# Keyboard/gamepad sprint action, or (touch) joystick pushed to the edge.
	var sprinting := Input.is_action_pressed("sprint")
	if touch_driven:
		var push := input_vector.length()
		if _touch_sprint:
			_touch_sprint = push >= TOUCH_SPRINT_EXIT
		else:
			_touch_sprint = push >= TOUCH_SPRINT_ENTER
		sprinting = sprinting or _touch_sprint
	else:
		_touch_sprint = false
	var nominal_speed := RUN_SPEED if sprinting else WALK_SPEED
	var speed := nominal_speed
	# Water slows movement: check world water detection.
	var world := get_tree().get_first_node_in_group("world")
	var in_water := false
	if world != null and world.has_method("is_water_world"):
		in_water = bool(world.is_water_world(global_position))
	if in_water != _in_water:
		_in_water = in_water
		_update_water_visual(in_water)
	if in_water:
		# Swimming is deliberately slower than walking on land, but remains responsive.
		speed *= 0.5
	# Ease the speed target so walk <-> sprint transitions ramp instead of snapping.
	_speed_target = lerpf(_speed_target, speed, 1.0 - exp(-SPEED_BLEND_RATE * delta))
	if input_vector.length_squared() > 0.001:
		var accel := ACCELERATION
		if velocity.length_squared() > 25.0:
			# Reversing / hard turns brake harder so direction changes feel crisp.
			var align := velocity.normalized().dot(input_vector.normalized())
			if align < 0.3:
				accel *= lerpf(TURN_BRAKE_MULT, 1.0, clampf((align + 1.0) / 1.3, 0.0, 1.0))
		velocity = velocity.move_toward(input_vector * _speed_target, accel * delta)
		if absf(input_vector.x) > 0.08:
			visual.facing = 1.0 if input_vector.x > 0.0 else -1.0
		facing_direction = input_vector.normalized()
		GameState.set_player_facing(facing_direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		if velocity.length() < STOP_SNAP_SPEED:
			velocity = Vector2.ZERO
		# Preserve last facing when idle.

	move_and_slide()

	# Drive the 8-direction animator from actual movement. The locomotion
	# sheets are 16 frames per direction (movement rebuild); the 1.36 / 1.40
	# playback lift is tuned to that stride. Playback is scaled by real speed
	# relative to the NOMINAL (non-water) speed, so feet slow down while wading
	# or accelerating instead of pedalling at full pace.
	var movement_ratio := clampf(velocity.length() / maxf(1.0, nominal_speed), 0.0, 1.0)
	var moving := velocity.length() > STOP_SNAP_SPEED
	var dir_vec := velocity.normalized() if moving else (input_vector if input_vector.length_squared() > 0.001 else facing_direction)
	visual.set_move_direction(dir_vec)
	visual.walking = moving  # backward-compatible assignment
	if moving:
		var locomotion_speed := (1.40 if sprinting else 1.36) * lerpf(0.55, 1.0, movement_ratio)
		visual.play(ANIM_RUN if sprinting else ANIM_WALK, -1, locomotion_speed)
		if velocity.length_squared() > 1.0:
			facing_direction = velocity.normalized()
			GameState.set_player_facing(facing_direction)
	else:
		visual.play(ANIM_IDLE, -1, 1.0)
	_update_camera_lookahead(delta, velocity, movement_ratio)



## Camera leads the movement direction a little so the player sees more of
## where they are heading. Uses Camera2D.offset so camera.position (and its
## smoothing speed) stay exactly as configured.
func _update_camera_lookahead(delta: float, move_velocity: Vector2, ratio: float) -> void:
	if camera == null:
		return
	var target := Vector2.ZERO
	if move_velocity.length_squared() > 1.0:
		var dir := move_velocity.normalized()
		target = Vector2(dir.x, dir.y * LOOKAHEAD_VERTICAL) * LOOKAHEAD * ratio
	camera.offset = camera.offset.lerp(target, 1.0 - exp(-LOOKAHEAD_RATE * delta))


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
	if event.is_action_pressed("switch_avatar"):
		if event is InputEventKey and event.echo:
			return
		if input_enabled:
			cycle_avatar()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(_zoom - 0.08)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(_zoom + 0.08)


# ------------------------------------------------------------ avatar switching

## The Tab cycle has a deliberate story order, independent of party/save order.
## The Wanderer placeholder is never a selectable avatar.
func available_avatars() -> Array[String]:
	var party_ids: Array[String] = []
	for instance in GameState.party_instances():
		var character_id := str(instance.char_id)
		if not character_id.is_empty() and not party_ids.has(character_id):
			party_ids.append(character_id)
	var ids: Array[String] = []
	for character_id in ["kael", "lilith", "gerald"]:
		if not party_ids.has(character_id):
			continue
		var source := SpriteFramesActorSource.from_playable(character_id)
		if source != null and source.has_frames() and source.validate_sheets().is_empty():
			ids.append(character_id)
	return ids


## Cycle through the validated party characters and return the newly active id.
func cycle_avatar() -> String:
	var ids := available_avatars()
	if ids.size() <= 1:
		EventBus.toast_requested.emit("No other playable avatars in the party yet.")
		return avatar_id
	var index := ids.find(avatar_id)
	var next_id := ids[(index + 1) % ids.size()] if index >= 0 else ids[0]
	set_avatar(next_id)
	return avatar_id


## Set the world actor to a real party character. Empty ids are rejected.
func set_avatar(character_id: String) -> void:
	if visual == null or character_id.is_empty():
		return
	var definition := ContentDB.get_character(character_id)
	if definition == null or definition.id.is_empty():
		return
	var kind := ActorVisual.Kind.HUMAN
	if definition.race == "Spirit":
		kind = ActorVisual.Kind.SPIRIT
	elif definition.race == "Monster":
		kind = ActorVisual.Kind.MONSTER
	visual.setup(definition.palette, kind, character_id, definition.race, definition.element)
	var report := visual.configure_character(character_id)
	if not bool(report.get("registered", false)):
		# No validated sheet after all: stay on the Wanderer rather than leaving
		# the previous avatar's textures on screen under a new name.
		set_avatar("")
		return
	avatar_id = character_id
	# Apply the canonical lore-height ratio through the sprite geometry API,
	# preserving a stable ground/hover anchor during every animation pose.
	visual.set_body_scale(float(AVATAR_HEIGHT_SCALE.get(character_id, 1.0)))
	_apply_camera_zoom()
	if _name_label != null:
		_name_label.text = definition.display_name
	EventBus.toast_requested.emit("Now playing as " + definition.display_name)


func _set_zoom(value: float) -> void:
	_zoom = clampf(value, MIN_ZOOM, MAX_ZOOM)
	_apply_camera_zoom()


func _apply_camera_zoom() -> void:
	if camera == null:
		return
	var avatar_factor := GERALD_CAMERA_ZOOM_FACTOR if avatar_id == "gerald" else 1.0
	camera.zoom = Vector2.ONE * (_zoom * avatar_factor)


func _update_water_visual(in_water: bool) -> void:
	if visual != null:
		if in_water:
			# Keep the original sprite pixels/colors intact. Lower the actor behind
			# the waterline so roughly the lower half of the 128px sheet is submerged.
			visual.position = Vector2(0, 44)
		else:
			visual.position = Vector2.ZERO
	# Authored WaterSurface child is toggled rather than created/freed at runtime.
	if _water_surface != null:
		_water_surface.visible = in_water


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


func restore_facing(facing: Vector2) -> void:
	if facing.length_squared() < 0.0001:
		facing = Vector2(0.0, 1.0)
	facing_direction = facing.normalized()
	if visual != null:
		if absf(facing_direction.x) > 0.1:
			visual.facing = 1.0 if facing_direction.x > 0.0 else -1.0
		visual.set_move_direction(facing_direction)
		visual.play(ANIM_IDLE)
	GameState.set_player_facing(facing_direction)


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
