extends Node
const TREE_SCENE: PackedScene = preload("res://scenes/world/forest_tree.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	player.position = Vector2.ZERO
	add_child(player)
	var tree := TREE_SCENE.instantiate() as Node2D
	tree.position = Vector2.ZERO
	add_child(tree)
	tree.setup("glade_tree", 0, false, 1.0, null)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var canopy := tree.get_node("Canopy") as Sprite2D
	var shape_node := tree.get_node("OcclusionArea/CollisionShape2D") as CollisionShape2D
	var rect := shape_node.shape as RectangleShape2D
	var player_shape := player.get_node("CollisionShape2D") as CollisionShape2D
	var player_rect := Rect2(player_shape.position - Vector2(9.0, 11.0), Vector2(18.0, 22.0))
	var area_rect := Rect2(shape_node.position - rect.size * 0.5, rect.size)
	if not area_rect.intersects(player_rect):
		push_error("Tree canopy occlusion footprint does not intersect the grounded player collider")
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.60).timeout
	if canopy.modulate.a > 0.40:
		push_error("Tree canopy did not fade while player was underneath; alpha=%s" % canopy.modulate.a)
		get_tree().quit(1)
		return
	print("FOREST_TREE_OCCLUSION_OK player_ground_anchor=DETECTED canopy_fade_alpha=%.2f" % canopy.modulate.a)
	player.position = Vector2(500, 500)
	await get_tree().physics_frame
	await get_tree().create_timer(0.35).timeout
	if canopy.modulate.a < 0.90:
		push_error("Tree canopy did not restore after player exited; alpha=%s" % canopy.modulate.a)
		get_tree().quit(1)
		return
	print("FOREST_TREE_OCCLUSION_RESTORE_OK alpha=%.2f" % canopy.modulate.a)
	get_tree().quit(0)
