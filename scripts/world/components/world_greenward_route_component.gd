class_name WorldGreenwardRouteComponent
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

func build_paths() -> void:
	if composition_data == null:
		return
	var way_kinds := ["signpost", "lantern", "stone_bridge", "wisp_lantern"]
	for r in composition_data.path_routes.size():
		var route := composition_data.path_routes[r]
		var a: Vector2 = route.get("from", Vector2.ZERO)
		var b: Vector2 = route.get("to", Vector2.ZERO)
		var marker_count := int(route.get("marker_count", 7))
		var long_route := marker_count >= 18
		var perp := (b - a).normalized().orthogonal() * 0.8
		for i in marker_count:
			var t := float(i + 1) / float(marker_count + 1)
			var curve := sin(t * PI) * sin(t * TAU * 1.1 + float(r)) * (1.25 if long_route else 0.8)
			var grid := a.lerp(b, t) + perp + (b - a).normalized().orthogonal() * curve
			if i % 3 == 0 or r < 2:
				var kind := str(way_kinds[(r + i) % way_kinds.size()])
				world.add_prop(kind, grid, 0.88 + float(i % 3) * 0.08, i % 2 == 0, i % 2)
			if i % 5 == 2:
				world.add_light(grid, GreenwardStyle.LIGHT.warm_lantern, 0.58, 1.45)
	world.add_animated_prop("foam_ripple", _anchor("river_foam_a", Vector2(7.0, 12.4)), 0.9, false, AnimatedProp.MOTION_PULSE, 0)
	world.add_animated_prop("foam_ripple", _anchor("river_foam_b", Vector2(9.4, 12.8)), 0.9, true, AnimatedProp.MOTION_PULSE, 0)
