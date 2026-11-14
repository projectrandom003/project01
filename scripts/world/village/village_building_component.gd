class_name VillageBuildingComponent
extends Interactable
## Reusable node-authored building visual, physical footprint and interaction nodes.

signal interaction_requested

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

@onready var visual_root: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite
@onready var collision_root: Node2D = $Collision
@onready var solid_body: StaticBody2D = $Collision/StaticBody2D
@onready var solid_shape: CollisionShape2D = $Collision/StaticBody2D/CollisionShape
@onready var interaction_area: Area2D = $Interaction
@onready var interaction_shape: CollisionShape2D = $Interaction/CollisionShape

func _ready() -> void:
	super._ready()
	prompt = interaction_prompt
	interaction_radius = interaction_radius_value
	_apply_visual()
	_apply_collision()
	_update_interaction()

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
