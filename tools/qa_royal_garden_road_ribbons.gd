extends SceneTree

const WORLD_SCENE := "res://scenes/world/castle_royal_gardens.tscn"
const ROAD_TEXTURE := "res://assets/reverie_custom/royal_gardens/production/royal_cobble_ribbon_96.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load(WORLD_SCENE) as PackedScene
	assert(packed != null, "Playable Royal Gardens scene must load")
	var world := packed.instantiate() as Node2D
	root.add_child(world)
	await process_frame

	var pathway_root := world.get_node_or_null("PathwayTiles") as CanvasItem
	var road_assembly := world.get_node_or_null("PathwayTiles/HandDesignedRoadSurfaces") as Node2D
	var terrain_root := world.get_node_or_null("Terrain") as CanvasItem
	assert(pathway_root != null and road_assembly != null and terrain_root != null,
		"Playable world must contain authored terrain and road assembly nodes")

	var effective_road_z := pathway_root.z_index + road_assembly.z_index
	assert(effective_road_z > terrain_root.z_index,
		"Road surfaces must render above the generated grass terrain")
	assert(pathway_root.z_index == 10 and road_assembly.z_index == -28,
		"Road z-order contract changed unexpectedly")

	var ribbons := road_assembly.get_children()
	assert(ribbons.size() == 9, "Expected nine authored garden road ribbons")
	assert(road_assembly.has_node("NorthCastleThresholdApron"), "North castle threshold apron is missing")
	assert(road_assembly.has_node("WestLowerGateWalk") and road_assembly.has_node("EastLowerGateWalk"), "Lower side-gate walks are missing")
	for ribbon in ribbons:
		assert(ribbon is Polygon2D, "Every road ribbon must remain a Polygon2D node")
		var polygon := ribbon as Polygon2D
		assert(polygon.polygon.size() >= 10, "%s needs a shaped polygon" % polygon.name)
		assert(polygon.uv.size() == polygon.polygon.size(), "%s needs authored UVs" % polygon.name)
		assert(polygon.texture != null and polygon.texture.resource_path == ROAD_TEXTURE,
			"%s must use the approved custom cobblestone artwork" % polygon.name)

	print("PLAYABLE_ROAD_RIBBONS=", ribbons.size())
	print("PATHWAY_Z=", pathway_root.z_index, " ROAD_ASSEMBLY_Z=", road_assembly.z_index,
		" EFFECTIVE_ROAD_Z=", effective_road_z, " TERRAIN_Z=", terrain_root.z_index)
	print("ROAD_TEXTURE=", ROAD_TEXTURE)
	print("PLAYABLE_ROAD_RIBBON_QA_OK")
	quit()
