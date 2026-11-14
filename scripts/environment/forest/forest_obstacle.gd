class_name ModularForestObstacle
extends ModularForestProp
## Static world obstacle. Collision is an authored child node and remains
## independent from the decorative sprite dimensions.

@export var collision_size: Vector2 = Vector2(42.0, 20.0)
@export var collision_offset: Vector2 = Vector2(0.0, -2.0)

@onready var obstacle_shape: CollisionShape2D = get_node_or_null("StaticBody2D/CollisionShape2D") as CollisionShape2D


func _ready() -> void:
	super._ready()
	if obstacle_shape != null:
		var rectangle := obstacle_shape.shape as RectangleShape2D
		if rectangle == null:
			rectangle = RectangleShape2D.new()
			obstacle_shape.shape = rectangle
		rectangle.size = collision_size
		obstacle_shape.position = collision_offset
