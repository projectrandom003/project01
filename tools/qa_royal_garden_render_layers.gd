extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var preview := (load("res://scenes/world/castle_gardens/components/reverie_royal_gardens_full_preview.tscn") as PackedScene).instantiate()
	root.add_child(preview)
	await process_frame
	var preview_edges := preview.get_node("TerrainSystem/RoadEdgeTransitions/HandPaintedRoadEdgeTransitions") as TileMapLayer
	var preview_ground := preview.get_node("TerrainSystem/IsometricTerrainLayers/BaseGround") as TileMapLayer
	var preview_path_system := preview.get_node("PathwaySystem") as Node2D
	var preview_roads := preview.get_node("PathwaySystem/RoyalPathways/HandDesignedRoadSurfaces") as Node2D
	var preview_castle := preview.get_node("CastleSystem/ModularCastleAssembly") as Node2D
	var preview_keep := preview_castle.get_node("CastleKeep") as Node2D
	var preview_gate := preview_castle.get_node("GrandGatehouse") as Node2D

	var preview_road_z := preview_path_system.z_index + preview_roads.z_index
	assert(preview_ground.z_index == -30)
	assert(preview_edges.z_index == -19 and not preview_edges.z_as_relative)
	assert(preview_path_system.z_index == 10)
	assert(preview_roads.z_index == -28 and preview_road_z == -18)
	assert(preview_ground.z_index < preview_edges.z_index and preview_edges.z_index < preview_road_z,
		"Preview draw order must be ground, road-edge transition, cobblestone surface")
	assert(is_equal_approx(preview_castle.scale.x, 1.4))
	assert(is_equal_approx(preview_keep.scale.x, 1.30))
	assert(is_equal_approx(preview_gate.scale.x, 0.98))

	var playable := (load("res://scenes/world/castle_royal_gardens.tscn") as PackedScene).instantiate()
	root.add_child(playable)
	await process_frame
	var live_terrain := playable.get_node("Terrain") as Node2D
	var live_edges := playable.get_node("Terrain/TerrainTransitions/RoadEdgeTransitions/HandPaintedRoadEdgeTransitions") as TileMapLayer
	var live_path_system := playable.get_node("PathwayTiles") as Node2D
	var live_roads := playable.get_node("PathwayTiles/HandDesignedRoadSurfaces") as Node2D
	var live_road_z := live_path_system.z_index + live_roads.z_index
	assert(live_terrain.z_index == -20)
	assert(live_edges.z_index == -19 and not live_edges.z_as_relative)
	assert(live_path_system.z_index == 10 and live_roads.z_index == -28)
	assert(live_road_z == -18)
	assert(live_terrain.z_index < live_edges.z_index and live_edges.z_index < live_road_z,
		"Playable draw order must be ground, road-edge transition, cobblestone surface")

	print("PREVIEW_LAYER_ORDER=", preview_ground.z_index, "<", preview_edges.z_index, "<", preview_road_z)
	print("PLAYABLE_LAYER_ORDER=", live_terrain.z_index, "<", live_edges.z_index, "<", live_road_z)
	print("CASTLE_COLLECTION_SCALE=", preview_castle.scale, " KEEP=", preview_keep.scale, " GATE=", preview_gate.scale)
	print("ROYAL_GARDEN_RENDER_LAYER_QA_OK")
	quit(0)
