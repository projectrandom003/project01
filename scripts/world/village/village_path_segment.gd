class_name VillagePathSegment
extends Node2D
## Reusable authored village path segment. Node-based visual component designed
## to compose a continuous, traversable isometric street network.
## Visual continuity with ground is handled by its sprite/shape children in scene.

@export var path_id: String = ""
@export var connects: PackedStringArray = PackedStringArray()
@export var traversable: bool = true

@onready var _visual: Node2D = get_node_or_null("Visual")

func _ready() -> void:
	if _visual != null:
		_visual.visible = true
