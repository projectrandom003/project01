class_name WorldRegionBuilderComponent
extends Node
## Owns data-driven composition for non-Greenward regions and their portals.

var world: GreenwardWorld


func configure(owner_world: GreenwardWorld) -> void:
	world = owner_world


func build_generic_region() -> void:
	if world == null:
		return
	var env := world.environment_data()
	var tint := Color(str(env.get("ambient_tint", "#7fe3e0")))
	if world.region_id == "moonpetal_hollow":
		build_moonpetal_hollow_composition(tint)
	var pois: Variant = world.region.get("pois", [])
	if typeof(pois) != TYPE_ARRAY:
		pois = []
	var cluster_kinds := [
		"birch_tree", "moss_rock", "fern", "flower_cluster",
		"glow_mushroom", "reeds", "crystal_cluster", "wisp_lantern",
	]
	var offsets := [
		Vector2(-1.2, 0), Vector2(1.2, 0), Vector2(0, -1.2),
		Vector2(0, 1.2), Vector2(-0.9, -0.9), Vector2(0.9, 0.9),
	]
	var prop_count := 0
	var poi_index := 0
	for poi in pois:
		if typeof(poi) != TYPE_DICTIONARY:
			continue
		var grid: Variant = poi.get("grid", [0, 0])
		if typeof(grid) != TYPE_ARRAY or grid.size() != 2:
			continue
		var center := Vector2(float(grid[0]), float(grid[1]))
		for j in offsets.size():
			if prop_count >= GreenwardWorld.GENERIC_PROP_CAP:
				break
			var kind := str(cluster_kinds[(poi_index + j) % cluster_kinds.size()])
			world.add_prop(kind, center + offsets[j], 0.85, j % 2 == 0, j % 3)
			prop_count += 1
		if poi_index < 2:
			world.add_animated_prop("foam_ripple", center + Vector2(0.6, 0.8), 0.9, false, AnimatedProp.MOTION_PULSE, 0)
		world.add_light(center, tint, 1.1, 2.4)
		poi_index += 1

	var interactives := [
		["rune_stone", "Moonlit Rune", "The vale keeps its own quiet counsel."],
		["spirit_bloom", "Silver Bloom", "It opens only under a borrowed moon."],
	]
	for index in interactives.size():
		if not world.can_add_interactive_prop():
			break
		var entry: Array = interactives[index]
		var anchor := Vector2(8.0, 8.0) + Vector2(float(index) * 2.0, 0.0)
		world.add_interactive_prop(str(entry[0]), anchor, str(entry[1]), str(entry[2]), index % 2)
	world.add_animated_prop("moth", Vector2(9, 7), 0.85, false, AnimatedProp.MOTION_DRIFT, 0)
	world.add_animated_prop("firefly_sprite", Vector2(7, 9), 0.85, true, AnimatedProp.MOTION_DRIFT, 0)


func spawn_region_portals() -> void:
	if world == null:
		return
	var connections: Variant = world.region.get("connections", [])
	if typeof(connections) != TYPE_ARRAY:
		return
	var entry_points: Variant = world.region.get("entry_points", {})
	var entry_dict: Dictionary = entry_points if typeof(entry_points) == TYPE_DICTIONARY else {}
	for connection in connections:
		if typeof(connection) != TYPE_DICTIONARY:
			continue
		var via := str(connection.get("via", ""))
		var grid: Variant = entry_dict.get(via, null)
		if typeof(grid) != TYPE_ARRAY or grid.size() != 2:
			continue
		var portal := GreenwardWorld.REGION_PORTAL_SCENE.instantiate() as RegionPortal
		portal.setup(world.region_id, connection)
		portal.position = IsoMath.grid_to_world(float(grid[0]), float(grid[1]))
		world.entities.add_child(portal)
		world.register_portal(portal)


func build_moonpetal_hollow_composition(cool_tint: Color) -> void:
	var gate := Vector2(6, 4.4)
	world.add_prop("village_gate", gate, 0.95, false, 1)
	for i in 3:
		world.add_prop("stone_path", Vector2(6, 5.2 + i * 0.8), 0.95, false, i % 2)
	world.add_prop("birch_grove", Vector2(3.4, 8.2), 0.9, false, 0)
	world.add_prop("birch_grove", Vector2(9.2, 8.4), 0.9, true, 2)
	world.add_prop("moon_lantern", Vector2(4.4, 6.2), 0.95, false, 0)
	world.add_prop("moon_lantern", Vector2(8.0, 6.2), 0.95, true, 1)
	world.add_prop("moon_shrine", Vector2(6, 9.4), 0.95, false, 1)
	world.add_prop("gazebo", Vector2(10.6, 10.2), 0.9, false, 1)
	world.add_prop("spirit_bloom", Vector2(4.8, 9.6), 0.9, false, 0)
	world.add_prop("spirit_bloom", Vector2(9.0, 10.6), 0.85, true, 2)
	world.add_prop("crystal_cluster", Vector2(7.6, 10.4), 0.9, false, 1)
	world.add_prop("wisp_lantern", Vector2(11.2, 8.0), 0.9, false, 0)
	world.add_light(Vector2(6, 6), cool_tint, 1.2, 2.6)
	world.add_light(Vector2(6, 9.4), cool_tint, 1.0, 2.2)
	world.add_light(Vector2(4.4, 6.2), GreenwardStyle.LIGHT.cool_moon, 0.9, 1.8)
	world.add_light(Vector2(8.0, 6.2), GreenwardStyle.LIGHT.cool_moon, 0.9, 1.8)
