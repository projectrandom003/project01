class_name WorldPropFactoryComponent
extends Node
## Owns runtime prop, interactive prop, animated prop and point-light construction.

var world: GreenwardWorld


func configure(owner: GreenwardWorld) -> void:
	world = owner


func make_prop_sprite(kind: String, world_position: Vector2, scale_value: float, flip: bool, variant: int = 0) -> Sprite2D:
	if world == null:
		return null
	var texture := ProceduralArt.prop_texture(kind, variant)
	if texture == null:
		return null
	record_texture(kind, variant)
	bump_prop_count(kind)
	var sprite := world.WORLD_PROP_SPRITE_SCENE.instantiate() as Sprite2D
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height() + 6.0)
	sprite.position = world_position
	sprite.scale = Vector2.ONE * scale_value
	sprite.flip_h = flip
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if kind in world.FOLIAGE_KINDS:
		sprite.material = world.wind_material
	return sprite


func add_prop(kind: String, grid_position: Vector2, scale_value: float = 1.0, flip: bool = false, variant: int = 0) -> Sprite2D:
	if world == null:
		return null
	if "bridge" in kind or kind == "wooden_bridge" or kind == "stone_bridge":
		if world.water_and_bridges != null:
			world.water_and_bridges.register_bridge(grid_position)
		elif world.navigation_component != null:
			world.navigation_component.add_bridge_position(grid_position)
	var sprite := make_prop_sprite(
		kind, IsoMath.grid_to_world(grid_position.x, grid_position.y), scale_value, flip, variant
	)
	if sprite != null and world.entities != null:
		world.entities.add_child(sprite)
	return sprite


func add_light(grid_position: Vector2, color: Color, energy: float, light_scale: float) -> void:
	if world == null:
		return
	if world.lighting_component != null and world.lighting_component.add_light(grid_position, color, energy, light_scale):
		record_glow(color)
		return
	if world.lighting_component == null and world._lights.size() < world.MAX_LIGHTS:
		var light := world.WORLD_POINT_LIGHT_SCENE.instantiate() as PointLight2D
		light.texture = ProceduralArt.soft_glow(color, 128)
		light.color = color
		light.energy = energy
		light.texture_scale = light_scale
		light.blend_mode = Light2D.BLEND_MODE_ADD
		light.position = IsoMath.grid_to_world(grid_position.x, grid_position.y) + Vector2(0, -36)
		world.entities.add_child(light)
		world._lights.append({ "light": light, "energy": energy, "color": color })
		record_glow(color)


func add_animated_prop(kind: String, grid_position: Vector2, scale_value: float, flip: bool, motion: int, variant: int = 0) -> AnimatedProp:
	if world == null or world._animated_props.size() >= world.MAX_ANIMATED_PROPS:
		return null
	var animated_prop := world.ANIMATED_PROP_SCENE.instantiate() as AnimatedProp
	animated_prop.setup(
		kind, IsoMath.grid_to_world(grid_position.x, grid_position.y), scale_value, flip, motion, variant
	)
	world.entities.add_child(animated_prop)
	world._animated_props.append(animated_prop)
	record_texture(kind, variant)
	bump_prop_count(kind)
	return animated_prop


func add_interactive_prop(kind: String, grid_position: Vector2, display_name: String, lore: String, variant: int = 0, rewards: Dictionary = {}) -> void:
	if world == null:
		return
	var prop := world.INTERACTIVE_PROP_SCENE.instantiate() as InteractiveProp
	prop.setup(kind, IsoMath.grid_to_world(grid_position.x, grid_position.y), display_name, lore, variant)
	if not rewards.is_empty():
		var stable_id := world.region_id + "_" + display_name.to_lower().replace(" ", "_").replace("'", "")
		prop.configure_collectible(stable_id, rewards, "Collected %s" % display_name)
	world.entities.add_child(prop)
	world._interactive_props.append(prop)
	record_texture(kind, variant)
	bump_prop_count(kind)


func record_texture(kind: String, variant: int) -> void:
	if world != null:
		world._texture_keys["prop:%s|%d" % [kind, variant]] = true


func record_glow(color: Color) -> void:
	if world != null:
		world._texture_keys["glow:%s" % color.to_html()] = true


func bump_prop_count(kind: String) -> void:
	if world != null:
		world._prop_kind_counts[kind] = int(world._prop_kind_counts.get(kind, 0)) + 1
