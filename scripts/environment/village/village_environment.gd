class_name ModularVillageEnvironment
extends Node2D
## Reusable village composition root, isolated from live GreenwardWorld.

const PATH_SCENE: PackedScene = preload("res://scenes/environment/village/village_path.tscn")

@export var layout_seed: int = 24017
@export var apply_authored_anchors_on_ready: bool = false

@onready var ground_details: Node2D = $GroundDetails
@onready var paths: Node2D = $PathNetwork
@onready var buildings: Node2D = $Buildings
@onready var tree_groups: Node2D = $TreeGroups
@onready var furniture: Node2D = $Furniture
@onready var npc_layer: Node2D = $NPCs
@onready var landmarks: Node2D = $Landmarks
@onready var ambient: Node2D = $Ambient

signal composition_built(seed_value: int, placed_count: int)

func _ready() -> void:
	for layer in [buildings, tree_groups, furniture, npc_layer, landmarks]:
		layer.y_sort_enabled = true
	if apply_authored_anchors_on_ready:
		build_from_anchors()

func add_path(points: PackedVector2Array, width: float = 34.0) -> Node2D:
	if points.size() < 2:
		return null
	var path := PATH_SCENE.instantiate() as Node2D
	if path == null:
		return null
	paths.add_child(path)
	path.call("configure", points, width)
	return path

func add_authored(scene: PackedScene, target_layer: StringName, local_position: Vector2) -> Node2D:
	if scene == null:
		return null
	var target := _layer_for(target_layer)
	if target == null:
		return null
	var instance := scene.instantiate() as Node2D
	if instance == null:
		return null
	target.add_child(instance)
	instance.position = local_position
	return instance

func build_from_anchors() -> int:
	var placed := 0
	for anchor in find_children("*", "VillagePlacementAnchor", true, false):
		var marker := anchor as VillagePlacementAnchor
		var instance := marker.instantiate_placed(layout_seed)
		if instance == null:
			continue
		var target := _layer_for(StringName(marker.anchor_role))
		if target == null:
			instance.free()
			continue
		target.add_child(instance)
		placed += 1
	composition_built.emit(layout_seed, placed)
	return placed

func set_layout_seed(value: int) -> void:
	layout_seed = value

func clear_generated() -> void:
	for layer in [ground_details, paths, buildings, tree_groups, furniture, npc_layer, landmarks, ambient]:
		for child in layer.get_children():
			if child.is_in_group("village_authored_anchor"):
				continue
			child.queue_free()

func _layer_for(role: StringName) -> Node2D:
	match role:
		&"building": return buildings
		&"tree": return tree_groups
		&"furniture": return furniture
		&"npc": return npc_layer
		&"landmark": return landmarks
		&"path": return paths
		_: return ground_details
