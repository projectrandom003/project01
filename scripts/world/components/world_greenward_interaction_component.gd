class_name WorldGreenwardInteractionComponent
extends Node
## Dedicated child node for one Greenward composition responsibility.

var world: GreenwardWorld
var composition_data: GreenwardCompositionData

func configure(owner_world: GreenwardWorld, data: GreenwardCompositionData) -> void:
	world = owner_world
	composition_data = data

func _anchor(anchor_name: String, fallback: Vector2) -> Vector2:
	if composition_data == null:
		return fallback
	var value: Variant = composition_data.anchors.get(anchor_name, fallback)
	return value if typeof(value) == TYPE_VECTOR2 else fallback

func build_extra_interactive_and_animated() -> void:
	# 1–2 more interactive locations (guarded by GreenwardWorld.MAX_INTERACTIVE_PROPS).
	if world.can_add_interactive_prop():
		world.add_interactive_prop("wisp_lantern", _anchor("shrine_wisp", Vector2(34, -28)), "Shrine Wisp", "It leans toward the moonpetal bloom.", 1, {"moonpetal": 1})
	if world.can_add_interactive_prop():
		world.add_interactive_prop("crystal_cluster", _anchor("grove_shard", Vector2(-36, 8)), "Grove Shard", "Cold to the touch, and faintly singing.", 0, {"glade_sap": 1})
	# A couple more AnimatedProps (waterfall / foam / wildlife), capped internally.
	world.add_animated_prop("waterfall", _anchor("extra_waterfall", Vector2(13.8, 13.4)), 0.9, false, AnimatedProp.MOTION_FLICKER, 0)
	world.add_animated_prop("foam_ripple", _anchor("extra_foam", Vector2(5.2, 13.9)), 0.9, false, AnimatedProp.MOTION_PULSE, 0)
	world.add_animated_prop("butterfly", _anchor("butterfly", Vector2(9.0, 9.0)), 0.85, true, AnimatedProp.MOTION_DRIFT, 0)


# ------------------------------- data-driven generic region (non-Greenward)
