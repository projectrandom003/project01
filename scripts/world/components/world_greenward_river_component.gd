class_name WorldGreenwardRiverComponent
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

func build_river() -> void:
	if world == null or composition_data == null:
		return
	for prop in composition_data.river_props:
		world.add_prop(
			str(prop.get("kind", "")),
			prop.get("grid", Vector2.ZERO),
			float(prop.get("scale", 1.0)),
			bool(prop.get("flip", false)),
			int(prop.get("variant", 0))
		)
	for prop in composition_data.river_animated_props:
		world.add_animated_prop(
			str(prop.get("kind", "")),
			prop.get("grid", Vector2.ZERO),
			float(prop.get("scale", 1.0)),
			bool(prop.get("flip", false)),
			int(prop.get("motion", AnimatedProp.MOTION_NONE)),
			int(prop.get("variant", 0))
		)
	for light in composition_data.river_lights:
		world.add_light(
			light.get("grid", Vector2.ZERO),
			GreenwardStyle.WATER.glint,
			float(light.get("energy", 0.7)),
			float(light.get("scale", 1.8))
		)
