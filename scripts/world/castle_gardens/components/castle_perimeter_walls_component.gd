class_name CastlePerimeterWallsComponent
extends Node2D
## Validates the four authored perimeter wall-run scenes. Geometry and collision
## are owned by each reusable CastlePerimeterWallRunComponent instance.

const REQUIRED_RUNS := ["NorthWall", "WestWall", "EastWall", "SouthWall"]

func _ready() -> void:
	for run_name in REQUIRED_RUNS:
		var run := get_node_or_null(run_name) as CastlePerimeterWallRunComponent
		if run == null:
			push_error("CastlePerimeterWalls requires the authored %s wall-run scene." % run_name)
			return
		if run.get_node_or_null("WallCollision") is not StaticBody2D:
			push_error("Castle perimeter %s is missing its authored WallCollision body." % run_name)
			return