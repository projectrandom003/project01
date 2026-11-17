class_name CastleLightingComponent
extends Node
## Instantiates reusable lighting scenes using authored anchor metadata.

const LIGHT_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/castle_garden_light.tscn")
const AMBIENT_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/castle_garden_ambient_particles.tscn")
const SHADOW_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/castle_garden_shadow.tscn")

var world: CastleRoyalGardens


func bind(owner_world: CastleRoyalGardens) -> void:
	world = owner_world


func build() -> void:
	if world == null:
		push_error("CastleLightingComponent must be bound before build().")
		return
	var lighting := world.get_node_or_null("Lighting") as Node2D
	var effects := world.get_node_or_null("EnvironmentEffects") as Node2D
	var anchors := world.get_node_or_null("Lighting/Anchors") as Node2D
	if lighting == null or effects == null or anchors == null:
		push_error("CastleLightingComponent requires authored Lighting, EnvironmentEffects and Lighting/Anchors.")
		return
	for anchor in anchors.get_children():
		if not (anchor is Marker2D):
			continue
		var marker := anchor as Marker2D
		var grid_value: Variant = marker.get_meta("grid_position", null)
		var offset_value: Variant = marker.get_meta("light_offset", Vector2.ZERO)
		if not (grid_value is Vector2) or not (offset_value is Vector2):
			push_error("Castle lighting anchor %s requires Vector2 grid_position and light_offset metadata." % marker.name)
			continue
		var light := LIGHT_SCENE.instantiate() as PointLight2D
		if light == null:
			push_error("CastleLightingComponent could not instantiate garden light scene.")
			return
		light.name = "GardenLight_%s" % marker.name
		light.position = IsoMath.grid_to_world(grid_value.x, grid_value.y) + offset_value
		light.texture = _make_radial_light_texture()
		lighting.add_child(light)
	_add_marker_effect(anchors, "Shadow", SHADOW_SCENE, lighting, "presentation_offset")
	_add_marker_effect(anchors, "AmbientParticles", AMBIENT_SCENE, effects, "presentation_offset")


func _add_marker_effect(anchors: Node2D, marker_name: String, packed: PackedScene, target: Node2D, offset_key: String) -> void:
	var marker := anchors.get_node_or_null(marker_name) as Marker2D
	if marker == null:
		push_error("Castle lighting requires authored %s marker." % marker_name)
		return
	var grid_value: Variant = marker.get_meta("grid_position", null)
	var offset_value: Variant = marker.get_meta(offset_key, null)
	if not (grid_value is Vector2) or not (offset_value is Vector2):
		push_error("Castle lighting marker %s requires Vector2 grid_position and %s metadata." % [marker_name, offset_key])
		return
	var effect := packed.instantiate() as CanvasItem
	if effect == null:
		push_error("Castle lighting could not instantiate effect for %s." % marker_name)
		return
	var effect_position: Vector2 = IsoMath.grid_to_world(grid_value.x, grid_value.y) + offset_value
	if effect is Node2D:
		(effect as Node2D).position = effect_position
	elif effect is Control:
		(effect as Control).position = effect_position
	target.add_child(effect)


func _make_radial_light_texture() -> Texture2D:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center := Vector2(32, 32)
	for y in range(64):
		for x in range(64):
			var distance := Vector2(x, y).distance_to(center) / 32.0
			var alpha := pow(clampf(1.0 - distance, 0.0, 1.0), 2.2)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)
