class_name WorldChunkLifecycleComponent
extends Node
## Owns chunk materialization into the scene tree and deterministic unload cleanup.

var world: GreenwardWorld

const VILLAGE_TREE_KINDS := {
	"glade_tree": true, "ancient_tree": true, "willow_tree": true, "birch_tree": true,
	"pine_tree": true, "blossom_tree": true, "dead_tree": true,
}


func configure(owner_world: GreenwardWorld) -> void:
	world = owner_world


func should_suppress_streamed_tree(kind: String, world_position: Vector2) -> bool:
	if world == null or world.region_id != GreenwardWorld.DEFAULT_REGION_ID:
		return false
	if not VILLAGE_TREE_KINDS.has(kind):
		return false
	# Authored village composition replaces streamed trees in its designed clearing.
	var village_center := IsoMath.grid_to_world(8.0, 8.0)
	return world_position.distance_to(village_center) <= 520.0


func load_chunk(coord: Vector2i) -> void:
	if world == null or world.loaded_chunks.has(coord):
		return
	var data: Dictionary
	if world._preparer != null and world._preparer.has_prepared(coord):
		data = world._preparer.take(coord)
		world._prepared_nodes.erase(coord)
	else:
		data = ChunkBuilder.build(
			coord, world.region, world.elevation, world.moisture,
			world.terrain_material, world.water_material
		)
	var use_ground_prototype := world.region_id == GreenwardWorld.DEFAULT_REGION_ID and coord == GreenwardWorld.PROTOTYPE_GROUND_CHUNK
	var terrain_node: Node = data.terrain
	if use_ground_prototype and GreenwardWorld.GROUND_CHUNK_SCENE != null:
		var ground_chunk := GreenwardWorld.GROUND_CHUNK_SCENE.instantiate()
		if ground_chunk != null:
			ground_chunk.name = "GroundChunk_%d_%d" % [coord.x, coord.y]
			world.terrain_layer.add_child(ground_chunk)
			if ground_chunk.has_method("setup"):
				ground_chunk.setup(
					coord,
					int(data.get("chunk_size", world.chunk_size)),
					data.get("ground_colors", []),
					data.get("origin_grid", IsoMath.chunk_origin_grid(coord, world.chunk_size))
				)
			var detail_node: Node = data.get("detail", null)
			if detail_node != null and is_instance_valid(detail_node):
				if detail_node.get_parent() != null:
					detail_node.get_parent().remove_child(detail_node)
				ground_chunk.add_child(detail_node)
			terrain_node = ground_chunk
			var old_terrain: Node = data.get("terrain", null)
			if old_terrain != null and is_instance_valid(old_terrain) and old_terrain != terrain_node:
				old_terrain.queue_free()
	else:
		world.terrain_layer.add_child(data.terrain)
	if data.water != null:
		if world.water_and_bridges != null:
			world.water_and_bridges.attach_water_surface(data.water)
		else:
			data.water.z_index = 1
			world.terrain_layer.add_child(data.water)

	var prop_nodes: Array = []
	for entry in data.props:
		var variant := int(entry.get("variant", 0))
		var scale_value := float(entry.scale)
		if bool(entry.get("detail", false)):
			scale_value *= 0.88
		var kind_str := str(entry.type)
		if should_suppress_streamed_tree(kind_str, entry.position):
			continue
		var prop_node: Node2D = null
		if use_ground_prototype and kind_str == "glade_tree" and GreenwardWorld.FOREST_TREE_SCENE != null:
			var tree := GreenwardWorld.FOREST_TREE_SCENE.instantiate()
			if tree != null:
				tree.position = entry.position
				prop_node = tree
				world.entities.add_child(tree)
				if tree.has_method("setup"):
					tree.setup("glade_tree", variant, bool(entry.flip), scale_value, world.wind_material)
				world._record_texture("glade_tree", variant)
				world._bump_prop_count("glade_tree")
		if prop_node == null:
			var sprite := world._make_prop_sprite(kind_str, entry.position, scale_value, bool(entry.flip), variant)
			if sprite != null:
				world.entities.add_child(sprite)
				prop_node = sprite
		if prop_node != null:
			prop_nodes.append(prop_node)

	world.loaded_chunks[coord] = {
		"terrain": terrain_node,
		"water": data.water,
		"props": prop_nodes,
	}


func unload_chunk(coord: Vector2i) -> void:
	if world == null or not world.loaded_chunks.has(coord):
		return
	var data: Dictionary = world.loaded_chunks[coord]
	for key in ["terrain", "water"]:
		var node: Node = data.get(key, null)
		if node != null and is_instance_valid(node):
			node.queue_free()
	for prop in data.get("props", []):
		if is_instance_valid(prop):
			prop.queue_free()
	world.loaded_chunks.erase(coord)
