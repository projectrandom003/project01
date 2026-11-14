class_name DirectionalEquipmentLayers
extends Node2D
## Selects one authored equipment layer for the active 8-way facing.
## CharacterAnimator remains the source of direction; when parented beneath an
## ActorVisual this node mirrors its animator direction without modifying the
## shared renderer or creating a competing animation controller.

const DIRECTION_NODE_NAMES: Array[StringName] = [
	&"Down", &"DownRight", &"Right", &"UpRight",
	&"Up", &"UpLeft", &"Left", &"DownLeft",
]

var current_direction: int = 0


func _ready() -> void:
	set_direction(current_direction)


func _process(_delta: float) -> void:
	var actor_visual := get_parent() as ActorVisual
	if actor_visual == null or actor_visual.animator == null:
		return
	if actor_visual.animator.direction != current_direction:
		set_direction(actor_visual.animator.direction)


func set_direction(direction: int) -> void:
	current_direction = clampi(direction, 0, DIRECTION_NODE_NAMES.size() - 1)
	for index in DIRECTION_NODE_NAMES.size():
		var layer := get_node_or_null(NodePath(String(DIRECTION_NODE_NAMES[index]))) as Node2D
		if layer != null:
			layer.visible = index == current_direction


func get_active_layer() -> Node2D:
	return get_node_or_null(NodePath(String(DIRECTION_NODE_NAMES[current_direction]))) as Node2D
