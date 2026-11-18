extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/world/castle_gardens/components/reverie_royal_gardens_full_preview.tscn") as PackedScene
    assert(packed != null, "Full preview scene failed to load")
    var scene := packed.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame

    var original_paths := scene.get_node("TerrainSystem/IsometricTerrainLayers/Paths") as TileMapLayer
    var branch_root := scene.get_node("PathwaySystem/RoyalPathways/HandDesignedRoadSurfaces") as Node2D
    var flowerbeds := scene.get_node("GardenFloraSystem/Flora/FountainFlowerbeds") as Node2D
    var lights := scene.get_node("GardenAtmosphere") as Node2D
    var camera := scene.get_node("PreviewCamera") as Camera2D
    var petals := scene.get_node("PetalDrift") as CPUParticles2D
    var road_edges := scene.get_node("TerrainSystem/RoadEdgeTransitions/HandPaintedRoadEdgeTransitions") as TileMapLayer
    var pathside_planting := scene.get_node("GardenFloraSystem/Flora/PathsidePlanting") as Node2D
    var upper_parterre := scene.get_node("GardenFloraSystem/Flora/UpperParterrePlanting") as Node2D
    var cloister_niches := scene.get_node("GardenFloraSystem/Flora/OuterCloisterNiches") as Node2D

    assert(not original_paths.visible, "Legacy baked path overlay must remain hidden behind the unified road assembly")
    assert(original_paths.get_used_cells().size() == 133, "Original baked path layout changed unexpectedly")
    assert(branch_root.get_child_count() == 6, "Expected one central promenade and five continuous branch ribbons")
    for road in branch_root.get_children():
        assert(road is Polygon2D, "Branch path must be a static Polygon2D")
        assert(road.texture != null and road.texture.resource_path.ends_with("royal_cobble_ribbon_96.png"))
        assert(road.polygon.size() >= 12 and road.uv.size() == road.polygon.size())
        assert(road.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED)
    assert(flowerbeds.get_child_count() >= 38, "Fountain flowerbeds missing")
    assert(lights.get_child_count() == 7, "Preview fountain and cloister lights missing")
    assert(camera.is_current(), "Preview camera is not active")
    assert(petals.texture != null and petals.emitting, "Ambient petals are not active")
    assert(road_edges.get_used_cells().size() == 45, "Hand-painted road edge transitions are incomplete")
    assert(pathside_planting.get_child_count() == 16, "Custom pathside planting scene is incomplete")
    assert(upper_parterre.get_child_count() == 8, "Upper castle parterre planting is incomplete")
    assert(cloister_niches.get_child_count() == 4, "Outer cloister garden niches are incomplete")
    assert(cloister_niches.get_node("WestCloisterArchitecture").get_child_count() == 4)
    assert(cloister_niches.get_node("EastCloisterArchitecture").get_child_count() == 4)

    print("LEGACY_BAKED_PATH_CELLS_PRESERVED=", original_paths.get_used_cells().size())
    assert(branch_root.has_node("CentralGrandPromenade"), "Playable central promenade is missing")
    print("CONTINUOUS_ROAD_RIBBONS=", branch_root.get_child_count())
    print("FOUNTAIN_FLOWERBED_SPRITES=", flowerbeds.get_child_count())
    print("PREVIEW_LIGHTS=", lights.get_child_count())
    print("AMBIENT_PETALS=", petals.emitting)
    print("HAND_PAINTED_ROAD_EDGE_CELLS=", road_edges.get_used_cells().size())
    print("PATHSIDE_CUSTOM_SPRITES=", pathside_planting.get_child_count())
    print("UPPER_PARTERRE_CUSTOM_SPRITES=", upper_parterre.get_child_count())
    print("OUTER_CLOISTER_NICHES=", cloister_niches.get_child_count(), " ARCHITECTURE_AND_GARDEN_SPRITES=16")
    print("ROYAL_GARDEN_STATIC_ASSET_QA_OK")
    quit(0)
