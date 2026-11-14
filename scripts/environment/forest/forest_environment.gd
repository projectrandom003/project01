class_name ModularForestEnvironment
extends Node2D
## Reusable forest composition root. Kept isolated from GreenwardWorld until
## the scene is visually approved and the migration is explicitly scheduled.

const PROP_SCENE: PackedScene = preload("res://scenes/environment/forest/forest_prop.tscn")
const VEGETATION_SCENE: PackedScene = preload("res://scenes/environment/forest/forest_vegetation.tscn")
const OBSTACLE_SCENE: PackedScene = preload("res://scenes/environment/forest/forest_obstacle.tscn")
const FALLEN_LOG_SCENE: PackedScene = preload("res://scenes/environment/forest/forest_fallen_log.tscn")
const TREE_SCENE: PackedScene = preload("res://scenes/world/forest_tree.tscn")
const STUMP_SCENE: PackedScene = preload("res://scenes/environment/forest/forest_stump.tscn")
const ROOT_CLUSTER_SCENE: PackedScene = preload("res://scenes/environment/forest/forest_root_cluster.tscn")
const FIREFLY_SCENE: PackedScene = preload("res://scenes/environment/forest/forest_firefly.tscn")
const GLOWING_KINDS := [&"spirit_bloom", &"glow_mushroom", &"crystal_cluster", &"rune_stone"]

@export_range(0.0, 1.0, 0.01) var time_of_day: float = 0.84
@export_range(0.0, 0.5, 0.01) var dawn_start: float = 0.18
@export_range(0.0, 0.5, 0.01) var dawn_end: float = 0.30
@export_range(0.0, 0.5, 0.01) var dusk_start: float = 0.70
@export_range(0.0, 0.5, 0.01) var dusk_end: float = 0.88

@onready var ground: Node2D = $Ground
@onready var ground_details: Node2D = $GroundDetails
@onready var world_objects: Node2D = $WorldObjects
@onready var ambient: Node2D = $Ambient
@onready var wind_controller: ForestWindController = $WindController


func _ready() -> void:
	world_objects.y_sort_enabled = true
	_apply_time_of_day()


func add_ground_chunk(chunk_scene: PackedScene, local_position: Vector2 = Vector2.ZERO) -> Node2D:
	if chunk_scene == null:
		return null
	var chunk := chunk_scene.instantiate() as Node2D
	if chunk == null:
		return null
	ground.add_child(chunk)
	chunk.position = local_position
	chunk.add_to_group("forest_ground_chunks")
	return chunk


func add_ground_detail(detail_node: Node2D, local_position: Vector2 = Vector2.ZERO) -> Node2D:
	if detail_node == null:
		return null
	ground_details.add_child(detail_node)
	detail_node.position = local_position
	detail_node.add_to_group("forest_ground_details")
	return detail_node


func add_prop(kind: String, world_position: Vector2, scale_value: float = 1.0,
		variant: int = 0, flip: bool = false, category: String = "vegetation") -> ModularForestProp:
	var scene := VEGETATION_SCENE if category == "vegetation" else PROP_SCENE
	var prop := scene.instantiate() as ModularForestProp
	prop.configure(kind, variant, scale_value, flip)
	prop.sway_enabled = category == "vegetation"
	world_objects.add_child(prop)
	prop.position = world_position
	_configure_forest_instance(prop)
	prop.add_to_group("forest_" + category)
	return prop


func add_obstacle(kind: String, world_position: Vector2, collision: Vector2,
		scale_value: float = 1.0, variant: int = 0, flip: bool = false) -> ModularForestObstacle:
	var obstacle := OBSTACLE_SCENE.instantiate() as ModularForestObstacle
	obstacle.prop_kind = kind
	obstacle.variant = variant
	obstacle.prop_scale = scale_value
	obstacle.flip_h = flip
	obstacle.collision_size = collision
	world_objects.add_child(obstacle)
	obstacle.position = world_position
	obstacle.add_to_group("forest_obstacles")
	return obstacle


func add_fallen_log(world_position: Vector2) -> Node2D:
	var log := FALLEN_LOG_SCENE.instantiate() as Node2D
	world_objects.add_child(log)
	log.position = world_position
	log.add_to_group("forest_obstacles")
	log.add_to_group("forest_fallen_logs")
	return log


func add_tree(kind: String, world_position: Vector2, scale_value: float = 1.0,
		variant: int = 0, flip: bool = false, wind_material: Material = null) -> ForestTree:
	var tree := TREE_SCENE.instantiate() as ForestTree
	var shared_wind := wind_material
	if shared_wind == null and wind_controller != null:
		shared_wind = wind_controller.wind_material
	tree.setup(kind, variant, flip, scale_value, shared_wind)
	world_objects.add_child(tree)
	tree.position = world_position
	tree.add_to_group("forest_trees")
	return tree


func add_stump(local_position: Vector2) -> Node2D:
	return _add_authored_world_object(STUMP_SCENE, local_position, ["forest_obstacles", "forest_stumps"])


func add_root_cluster(local_position: Vector2) -> Node2D:
	return _add_authored_world_object(ROOT_CLUSTER_SCENE, local_position, ["forest_obstacles", "forest_roots"])


func add_firefly(local_position: Vector2) -> Node2D:
	var firefly := FIREFLY_SCENE.instantiate() as Node2D
	ambient.add_child(firefly)
	firefly.position = local_position
	firefly.add_to_group("forest_ambient")
	firefly.add_to_group("forest_fireflies")
	if firefly.has_method("set_activity"):
		firefly.call("set_activity", _night_activity())
	return firefly


func add_family_scene(scene: PackedScene, local_position: Vector2,
		group_names: Array[String] = []) -> Node2D:
	var instance := _add_authored_world_object(scene, local_position, group_names)
	if instance != null:
		_configure_forest_instance(instance)
	return instance


func _add_authored_world_object(scene: PackedScene, local_position: Vector2,
		group_names: Array[String]) -> Node2D:
	if scene == null:
		return null
	var instance := scene.instantiate() as Node2D
	if instance == null:
		return null
	world_objects.add_child(instance)
	instance.position = local_position
	for group_name in group_names:
		if not group_name.is_empty():
			instance.add_to_group(group_name)
	return instance


func set_time_of_day(value: float) -> void:
	time_of_day = fposmod(value, 1.0)
	_apply_time_of_day()


func set_wind_intensity(value: float) -> void:
	if wind_controller != null:
		wind_controller.set_wind_intensity(value)


func _night_activity() -> float:
	var dawn := smoothstep(dawn_start, dawn_end, time_of_day)
	var dusk := smoothstep(dusk_start, dusk_end, time_of_day)
	return clampf(maxf(1.0 - dawn, dusk), 0.0, 1.0)


func _apply_time_of_day() -> void:
	var activity := _night_activity()
	for firefly in get_tree().get_nodes_in_group("forest_fireflies"):
		if is_ancestor_of(firefly) and firefly.has_method("set_activity"):
			firefly.call("set_activity", activity)
	for glow_prop in get_tree().get_nodes_in_group("forest_glowing"):
		if is_ancestor_of(glow_prop) and glow_prop.has_method("set_glow_activity"):
			glow_prop.call("set_glow_activity", activity)


func _configure_forest_instance(instance: Node) -> void:
	if instance is ModularForestProp:
		var prop := instance as ModularForestProp
		if prop.sway_enabled and wind_controller != null:
			prop.set_wind_material(wind_controller.wind_material)
		if prop.prop_kind in GLOWING_KINDS:
			prop.glow_enabled = true
			prop.add_to_group("forest_glowing")
			prop.set_glow_activity(_night_activity())
	elif instance is ForestTree:
		var canopy := instance.get_node_or_null("Canopy") as Sprite2D
		if canopy != null and wind_controller != null:
			canopy.material = wind_controller.wind_material


func clear_generated() -> void:
	for child in ground.get_children():
		if child.is_in_group("forest_ground_chunks"):
			child.queue_free()
	for layer in [ground_details, world_objects, ambient]:
		for child in layer.get_children():
			child.queue_free()
