class_name GothicWorldBoundsComponent
extends Node
## Authored Gothic Castle environment responsibility node.

var environment: GothicCastleEnvironmentComponent

func configure(owner: GothicCastleEnvironmentComponent) -> void:
	environment = owner

func _build_bounds() -> void:
	var bounds := StaticBody2D.new()
	bounds.name = "WorldBounds"
	bounds.collision_layer = 1
	bounds.collision_mask = 0
	environment.world.add_child(bounds)
	var mins := ReverieRouteData.ORIGIN + Vector2(
			(ReverieRouteData.GRID_MIN.x - ReverieRouteData.GRID_MAX.y) * 32.0,
			(ReverieRouteData.GRID_MIN.x + ReverieRouteData.GRID_MIN.y) * 16.0)
	var maxs := ReverieRouteData.ORIGIN + Vector2(
			(ReverieRouteData.GRID_MAX.x - ReverieRouteData.GRID_MIN.y) * 32.0,
			(ReverieRouteData.GRID_MAX.x + ReverieRouteData.GRID_MAX.y) * 16.0)
	var rects := {
		"Left": Rect2(Vector2(mins.x - 64, mins.y), Vector2(48, maxs.y - mins.y + 256)),
		"Right": Rect2(Vector2(maxs.x + 16, mins.y), Vector2(48, maxs.y - mins.y + 256)),
		"Top": Rect2(Vector2(mins.x - 64, mins.y - 64), Vector2(maxs.x - mins.x + 128, 48)),
		"Bottom": Rect2(Vector2(mins.x - 64, maxs.y + 16), Vector2(maxs.x - mins.x + 128, 48)),
	}
	for name in rects:
		var shape := RectangleShape2D.new()
		shape.size = (rects[name] as Rect2).size
		var collider := CollisionShape2D.new()
		collider.name = name
		collider.shape = shape
		collider.position = (rects[name] as Rect2).position + shape.size * 0.5
		bounds.add_child(collider)
