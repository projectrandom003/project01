class_name VillageBuildingComponent
extends Interactable
## Reusable node-authored building with separated visual/collision/interaction parts.
## Preserves existing sprite-driven approved visuals while exposing modular
## substructure nodes (foundation/walls/roof/doors/windows/decorations/lighting).

signal interaction_requested
signal door_toggled(open: bool)
signal building_light_toggled(enabled: bool)

@export var interaction_prompt: String = "Enter"
@export_range(16.0, 256.0, 1.0) var interaction_radius_value: float = 96.0

@export var building_id: StringName = &""
@export var building_kind: String = ""
@export var visual_variant: int = 0
@export_range(0.1, 3.0, 0.01) var visual_scale: float = 1.0
@export var visual_flip_h: bool = false
@export var blocks_movement: bool = true
@export var collision_size: Vector2 = Vector2(72.0, 26.0)
@export var collision_offset: Vector2 = Vector2(0.0, -8.0)
@export var interaction_enabled: bool = false:
	set(value):
		interaction_enabled = value
		_update_interaction()

@export_group("Modular Parts")
@export var building_config: Resource
@export var foundation_visible: bool = true
@export var walls_visible: bool = true
@export var roof_visible: bool = true
@export var doors_visible: bool = true
@export var windows_visible: bool = true
@export var decorations_visible: bool = true
@export var lighting_visible: bool = true
@export var door_open: bool = false
@export var building_lights_on: bool = true

@onready var visual_root: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite
@onready var foundation_node: Node2D = get_node_or_null("Visual/Foundation") as Node2D
@onready var walls_node: Node2D = get_node_or_null("Visual/Walls") as Node2D
@onready var roof_node: Node2D = get_node_or_null("Visual/Roof") as Node2D
@onready var doors_node: Node2D = get_node_or_null("Visual/Doors") as Node2D
@onready var windows_node: Node2D = get_node_or_null("Visual/Windows") as Node2D
@onready var decorations_node: Node2D = get_node_or_null("Visual/Decorations") as Node2D
@onready var lighting_node: Node2D = get_node_or_null("Visual/Lighting") as Node2D
@onready var collision_root: Node2D = $Collision
@onready var solid_body: StaticBody2D = $Collision/StaticBody2D
@onready var solid_shape: CollisionShape2D = $Collision/StaticBody2D/CollisionShape
@onready var interaction_area: Area2D = $Interaction
@onready var interaction_shape: CollisionShape2D = $Interaction/CollisionShape
@onready var animation_player: AnimationPlayer = get_node_or_null("Animation") as AnimationPlayer

func _ready() -> void:
	super._ready()
	_apply_building_config()
	prompt = interaction_prompt
	interaction_radius = interaction_radius_value
	_apply_visual()
	_apply_collision()
	_update_interaction()
	_apply_part_visibility()

func _apply_building_config() -> void:
	if building_config == null:
		return
	var cfg = building_config
	if "building_kind" in cfg and String(cfg.building_kind) != "": building_kind = String(cfg.building_kind)
	if "visual_variant" in cfg: visual_variant = int(cfg.visual_variant)
	if "visual_scale" in cfg: visual_scale = float(cfg.visual_scale)
	if "blocks_movement" in cfg: blocks_movement = bool(cfg.blocks_movement)
	if "collision_size" in cfg: collision_size = Vector2(cfg.collision_size)
	if "collision_offset" in cfg: collision_offset = Vector2(cfg.collision_offset)
	if "interaction_enabled" in cfg: interaction_enabled = bool(cfg.interaction_enabled)
	if "interaction_prompt" in cfg and String(cfg.interaction_prompt) != "": interaction_prompt = String(cfg.interaction_prompt)
	if "foundation_visible" in cfg: foundation_visible = bool(cfg.foundation_visible)
	if "walls_visible" in cfg: walls_visible = bool(cfg.walls_visible)
	if "roof_visible" in cfg: roof_visible = bool(cfg.roof_visible)
	if "doors_visible" in cfg: doors_visible = bool(cfg.doors_visible)
	if "windows_visible" in cfg: windows_visible = bool(cfg.windows_visible)
	if "decorations_visible" in cfg: decorations_visible = bool(cfg.decorations_visible)
	if "lighting_visible" in cfg: lighting_visible = bool(cfg.lighting_visible)

func apply_building_config(cfg: Resource) -> void:
	building_config = cfg
	_apply_building_config()
	_apply_visual()
	_apply_collision()
	_update_interaction()
	_apply_part_visibility()

func _apply_visual() -> void:
	if sprite == null or building_kind.is_empty():
		return
	var texture := ProceduralArt.prop_texture(building_kind, visual_variant)
	if texture == null:
		return
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.offset = Vector2(-float(texture.get_width()) * 0.5, -float(texture.get_height()) + 6.0)
	sprite.scale = Vector2.ONE * visual_scale
	sprite.flip_h = visual_flip_h
	sprite.material = null
	_apply_part_visibility()

func _apply_part_visibility() -> void:
	if foundation_node != null: foundation_node.visible = foundation_visible
	if walls_node != null: walls_node.visible = walls_visible
	if roof_node != null: roof_node.visible = roof_visible
	if doors_node != null: doors_node.visible = doors_visible
	if windows_node != null: windows_node.visible = windows_visible
	if decorations_node != null: decorations_node.visible = decorations_visible
	if lighting_node != null: lighting_node.visible = lighting_visible and building_lights_on

func set_door_open(value: bool) -> void:
	if door_open == value:
		return
	door_open = value
	_apply_part_visibility()
	door_toggled.emit(door_open)

func set_building_lights(value: bool) -> void:
	if building_lights_on == value:
		return
	building_lights_on = value
	_apply_part_visibility()
	building_light_toggled.emit(building_lights_on)

func get_part(part_name: StringName) -> Node2D:
	match String(part_name):
		"foundation": return foundation_node
		"walls": return walls_node
		"roof": return roof_node
		"doors": return doors_node
		"windows": return windows_node
		"decorations": return decorations_node
		"lighting": return lighting_node
		"visual": return visual_root
	return null

func _apply_collision() -> void:
	if solid_body == null or solid_shape == null:
		return
	if solid_shape.shape != null and not solid_shape.shape.resource_local_to_scene:
		solid_shape.shape = solid_shape.shape.duplicate(true)
	solid_body.collision_layer = 1 if blocks_movement else 0
	solid_body.collision_mask = 0
	solid_shape.disabled = not blocks_movement
	solid_shape.position = collision_offset
	var rectangle := solid_shape.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		solid_shape.shape = rectangle
	rectangle.size = collision_size

func set_visual_texture(texture: Texture2D) -> void:
	if sprite != null:
		sprite.texture = texture

func interact() -> void:
	if not can_interact():
		return
	interaction_requested.emit()

func _update_interaction() -> void:
	enabled = interaction_enabled
	var area := get_node_or_null("Interaction") as Area2D
	var shape := get_node_or_null("Interaction/CollisionShape") as CollisionShape2D
	if area != null:
		area.monitoring = interaction_enabled
		area.monitorable = interaction_enabled
	if shape != null:
		shape.disabled = not interaction_enabled
