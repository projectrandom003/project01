@tool
class_name CastlePerimeterWallRunComponent
extends Node2D
## Reusable architectural wall run. Stable facade, parapet, plinth, pier layer
## and collision nodes are authored in castle_perimeter_wall_run.tscn.
## @tool keeps the generated wall geometry visible while editing the map.

const PIER_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/castle_perimeter_pier.tscn")

@export_range(96.0, 2400.0, 24.0) var run_length := 1920.0:
	set(value):
		run_length = maxf(value, 96.0)
		if is_node_ready():
			_rebuild_geometry()

@export_range(96.0, 360.0, 24.0) var bay_width := 240.0:
	set(value):
		bay_width = maxf(value, 96.0)
		if is_node_ready():
			_rebuild_geometry()

@onready var facade: Polygon2D = $Facade
@onready var parapet: Polygon2D = $Parapet
@onready var plinth: Polygon2D = $Plinth
@onready var piers: Node2D = $Piers
@onready var collision_body: StaticBody2D = $WallCollision
@onready var collision_shape: CollisionShape2D = $WallCollision/CollisionShape2D


func _ready() -> void:
	_rebuild_geometry()


func _rebuild_geometry() -> void:
	if not is_instance_valid(facade) or not is_instance_valid(parapet) or not is_instance_valid(plinth) or not is_instance_valid(piers) or not is_instance_valid(collision_body) or not is_instance_valid(collision_shape):
		return
	_build_facade()
	_build_piers()
	_configure_collision()


func _build_facade() -> void:
	var half := run_length * 0.5
	facade.polygon = _rect(-half, half, -48.0, 48.0)
	parapet.polygon = _rect(-half, half, -78.0, -57.0)
	plinth.polygon = _rect(-half, half, 43.0, 60.0)


func _build_piers() -> void:
	for child in piers.get_children():
		piers.remove_child(child)
		child.free()
	var count := maxi(1, int(floor(run_length / bay_width)))
	for index in range(count + 1):
		var pier := PIER_SCENE.instantiate() as Node2D
		if pier == null:
			push_error("CastlePerimeterWallRun could not instantiate its pier scene.")
			return
		pier.name = "Pier_%02d" % index
		pier.position.x = -run_length * 0.5 + float(index) * run_length / float(count)
		piers.add_child(pier)


func _configure_collision() -> void:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(run_length, 38.0)
	collision_shape.shape = shape


func _rect(left: float, right: float, top: float, bottom: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(left, top), Vector2(right, top),
		Vector2(right, bottom), Vector2(left, bottom)
	])
