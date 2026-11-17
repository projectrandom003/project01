class_name RoyalGarden
extends Node2D
## Symmetrical flower-bed layout composed from reusable authored prop scenes.

const PROP_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/garden_sprite_prop.tscn")
const CIRCLE_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/garden_collision_circle.tscn")

func build_symmetrical(origin: Vector2) -> void:
	var flower_tex := load("res://assets/environment/castle_gardens/flower_bed_lush.png") as Texture2D
	if flower_tex == null:
		flower_tex = load("res://assets/environment/castle_gardens/flower_bed.png") as Texture2D
	var urn_tex := load("res://assets/environment/castle_gardens/urn_planter.png") as Texture2D
	if flower_tex == null:
		return
	var offsets := [Vector2(-140, 40), Vector2(140, 40), Vector2(-140, 120), Vector2(140, 120), Vector2(-220, 80), Vector2(220, 80), Vector2(-180, 20), Vector2(180, 20)]
	for i in offsets.size():
		var off: Vector2 = offsets[i]
		var bed := _add_visual(flower_tex, origin + off, Vector2(0, -4), Vector2(1.0 + 0.05 * float(i % 2), 1.0))
		bed.get_node("Body").queue_free()
		bed.get_node("LanternGlow").queue_free()
	if urn_tex != null:
		for off in [Vector2(-80, 0), Vector2(80, 0), Vector2(-80, 160), Vector2(80, 160), Vector2(-40, 80), Vector2(40, 80)]:
			var urn := _add_visual(urn_tex, origin + off, Vector2(0, -10), Vector2.ONE)
			urn.reparent($UrnPlanters)
			urn.get_node("Body").queue_free()
			urn.get_node("LanternGlow").queue_free()
			var blocker := CIRCLE_SCENE.instantiate() as StaticBody2D
			var circle := CircleShape2D.new()
			circle.radius = 8.0
			(blocker.get_node("CollisionShape2D") as CollisionShape2D).shape = circle
			blocker.position = origin + off + Vector2(0, 2)
			$Collisions.add_child(blocker)

func _add_visual(texture: Texture2D, pos: Vector2, offset: Vector2, scale_value: Vector2) -> Node2D:
	var prop := PROP_SCENE.instantiate() as Node2D
	prop.position = pos
	var sprite := prop.get_node("Sprite") as Sprite2D
	sprite.texture = texture
	sprite.offset = offset
	sprite.scale = scale_value
	$FlowerBeds.add_child(prop)
	return prop
