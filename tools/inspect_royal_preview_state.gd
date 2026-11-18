extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/world/castle_gardens/components/reverie_royal_gardens_full_preview.tscn") as PackedScene
	assert(packed != null)
	var scene := packed.instantiate() as Node2D
	root.add_child(scene)
	await process_frame
	await process_frame
	var camera := get_root().get_camera_2d()
	print("VIEWPORT_SIZE=", get_root().get_visible_rect().size)
	print("PREVIEW_CAMERA_LOCAL=", scene.get_node("PreviewCamera").position)
	print("PREVIEW_CAMERA_ZOOM=", scene.get_node("PreviewCamera").zoom)
	print("ACTIVE_CAMERA=", camera)
	if camera != null:
		print("ACTIVE_CAMERA_POSITION=", camera.global_position)
		print("ACTIVE_CAMERA_CENTER=", camera.get_screen_center_position())
		print("ACTIVE_CAMERA_ZOOM=", camera.zoom)
	for path in [
		"TerrainSystem/IsometricTerrainLayers/BaseGround",
		"TerrainSystem/RoadEdgeTransitions/HandPaintedRoadEdgeTransitions",
		"PathwaySystem/RoyalPathways/HandDesignedRoadSurfaces/CentralGrandPromenade",
		"CastleSystem/ModularCastleAssembly",
		"GardenFloraSystem/Flora/SignatureTrees",
		"FenceSystem/GardenFences",
		"GardenWaterSystem/Water"
	]:
		var node := scene.get_node_or_null(path)
		if node is CanvasItem:
			print("NODE ", path, " POS=", node.global_position, " Z=", node.z_index, " VISIBLE=", node.visible)
	print("INSPECT_PREVIEW_STATE_OK")
	quit()
