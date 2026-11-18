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

## Public compatibility constants; locomotion owns the tuning values.
const WALK_SPEED := PlayerLocomotionComponent.WALK_SPEED
const RUN_SPEED := PlayerLocomotionComponent.RUN_SPEED
const ACCELERATION := PlayerLocomotionComponent.ACCELERATION
const FRICTION := PlayerLocomotionComponent.FRICTION
const TURN_BRAKE_MULT := PlayerLocomotionComponent.TURN_BRAKE_MULT
const SPEED_BLEND_RATE := PlayerLocomotionComponent.SPEED_BLEND_RATE
const STOP_SNAP_SPEED := PlayerLocomotionComponent.STOP_SNAP_SPEED
const TOUCH_SPRINT_ENTER := PlayerLocomotionComponent.TOUCH_SPRINT_ENTER
const TOUCH_SPRINT_EXIT := PlayerLocomotionComponent.TOUCH_SPRINT_EXIT

# Animation state ids (mirror CharacterAnimator.State / ActorVisual.S_*).
const ANIM_IDLE := 0
const ANIM_WALK := 1
const ANIM_RUN := 2
const GLOW_INTERVAL := 0.25

var input_enabled: bool = true
var visual: ActorVisual
var camera: Camera2D
var nearby_interactable: Interactable = null
var interaction_component: CharacterInteractionComponent
var locomotion_component: PlayerLocomotionComponent
var avatar_component: PlayerAvatarComponent
var presentation_component: PlayerPresentationComponent
## "" = the Wanderer placeholder avatar. Any other value is a party character id
## whose validated world_sheet.tres is driving the Sprite2D.
var avatar_id: String = ""

var facing_direction: Vector2 = Vector2(0.0, 1.0)


func _ready() -> void:
	add_to_group("player")
	input_enabled = true
	collision_layer = 2
	collision_mask = 1
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	presentation_component = get_node_or_null("PresentationComponent") as PlayerPresentationComponent
	var camera_rig := get_node_or_null("Camera2D") as PlayerCameraRig
	interaction_component = get_node_or_null("InteractionComponent") as CharacterInteractionComponent
	locomotion_component = get_node_or_null("LocomotionComponent") as PlayerLocomotionComponent
	avatar_component = get_node_or_null("AvatarComponent") as PlayerAvatarComponent
	if shape == null or presentation_component == null or camera_rig == null or interaction_component == null or locomotion_component == null or avatar_component == null:
		push_error("Player scene is missing a required authored child component")
		return
	visual = presentation_component.configure_visual_nodes()
	camera = camera_rig
	camera_rig.set_base_zoom(1.1)
	if visual == null:
		push_error("PlayerPresentationComponent could not resolve ActorVisual")
		return
	if not interaction_component.interactable_changed.is_connected(_on_interactable_changed):
		interaction_component.interactable_changed.connect(_on_interactable_changed)
	set_avatar("kael")

# ------------------------------------------------------------ avatar switching

## The Tab cycle has a deliberate story order, independent of party/save order.
## The Wanderer placeholder is never a selectable avatar.
func available_avatars() -> Array[String]:
	return avatar_component.available_avatars() if avatar_component != null else []


func cycle_avatar() -> String:
	return avatar_component.cycle_avatar() if avatar_component != null else avatar_id


func set_avatar(character_id: String) -> void:
	if avatar_component != null:
		avatar_component.set_avatar(character_id)


func _set_zoom(value: float) -> void:
	if camera is PlayerCameraRig:
		(camera as PlayerCameraRig).set_base_zoom(value)
	elif camera != null:
		camera.zoom = Vector2.ONE * clampf(value, 0.64, 1.85)


func _update_water_visual(in_water: bool) -> void:
	if presentation_component != null:
		presentation_component.update_water_visual(in_water)


func _scan_for_interactable() -> void:
	if interaction_component != null:
		nearby_interactable = interaction_component.refresh_nearest()


func _on_interactable_changed(interactable: Node) -> void:
	nearby_interactable = interactable as Interactable


func try_interact() -> void:
	if interaction_component != null and interaction_component.get_current() != null:
		if visual != null:
			visual.play_interact()
		interaction_component.try_interact()


func current_prompt() -> String:
	return interaction_component.current_prompt() if interaction_component != null else ""


func restore_facing(facing: Vector2) -> void:
	if presentation_component != null:
		facing_direction = presentation_component.restore_facing(facing)
	else:
		facing_direction = facing.normalized() if facing.length_squared() > 0.0001 else Vector2(0.0, 1.0)
		GameState.session_domain.set_player_facing(facing_direction)


# ------------------------------------------------- cosmetic animation hooks

func play_damage() -> void:
	if presentation_component != null:
		presentation_component.play_damage()
	elif visual != null:
		visual.hit()


func play_victory() -> void:
	if presentation_component != null:
		presentation_component.play_victory()
	elif visual != null:
		visual.play_victory()


func play_defeat() -> void:
	if presentation_component != null:
		presentation_component.play_defeat()
	elif visual != null:
		visual.play_defeat()


func play_attack() -> void:
	if presentation_component != null:
		presentation_component.play_attack()
	elif visual != null:
		visual.play_attack()


func play_cast() -> void:
	if presentation_component != null:
		presentation_component.play_cast()
	elif visual != null:
		visual.play_cast()
