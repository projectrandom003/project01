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
    var north_courts := scene.get_node("GardenFloraSystem/Flora/NorthApproachCeremonialCourts") as Node2D
    var seating := scene.get_node("GardenFloraSystem/Flora/OuterGardenSeatingAlcoves") as Node2D
    var central_gazebo := scene.get_node("GardenFloraSystem/Flora/RoseArchitecture/RoyalGazebo") as Sprite2D
    var outer_woodland := scene.get_node("GardenFloraSystem/Flora/OuterWoodlandFrame") as Node2D
    var south_cloisters := scene.get_node("GardenFloraSystem/Flora/SouthOuterCloisterExtensions") as Node2D

    assert(not original_paths.visible, "Legacy baked path overlay must remain hidden behind the unified road assembly")
    assert(not central_gazebo.visible, "Central promenade must remain clear to the main entrance gate")
    assert(outer_woodland.get_child_count() == 6, "Outer woodland frame must retain six custom blossom trees")
    assert(original_paths.get_used_cells().size() == 133, "Original baked path layout changed unexpectedly")
    assert(branch_root.get_child_count() == 9, "Expected nine authored road ribbons, including the lower side-gate walks")
    assert(branch_root.has_node("NorthCastleThresholdApron"), "North castle threshold apron is missing")
    assert(branch_root.has_node("WestLowerGateWalk") and branch_root.has_node("EastLowerGateWalk"), "Lower side-gate walks are missing")
    var west_loop := branch_root.get_node("WestFountainGardenLoop") as Polygon2D
    var east_loop := branch_root.get_node("EastFountainGardenLoop") as Polygon2D
    assert(west_loop.polygon[0].distance_to(west_loop.polygon[west_loop.polygon.size() - 1]) > 60.0,
        "West fountain walkway must be an open ribbon, not a self-intersecting closed loop")
    assert(east_loop.polygon[0].distance_to(east_loop.polygon[east_loop.polygon.size() - 1]) > 60.0,
        "East fountain walkway must be an open ribbon, not a self-intersecting closed loop")
    for road in branch_root.get_children():
        assert(road is Polygon2D, "Branch path must be a static Polygon2D")
        assert(road.texture != null and road.texture.resource_path.ends_with("royal_cobble_ribbon_96.png"))
        assert(road.polygon.size() >= 12 and road.uv.size() == road.polygon.size())
        assert(road.texture_repeat == CanvasItem.TEXTURE_REPEAT_ENABLED)
    assert(flowerbeds.get_child_count() >= 38, "Fountain flowerbeds missing")
    assert(lights.get_child_count() == 11, "Preview fountain, cloister, approach and seating lights missing")
    assert(camera.is_current(), "Preview camera is not active")
    assert(petals.texture != null and petals.emitting, "Ambient petals are not active")
    assert(road_edges.get_used_cells().size() == 45, "Hand-painted road edge transitions are incomplete")
    assert(pathside_planting.get_child_count() == 16, "Custom pathside planting scene is incomplete")
    assert(upper_parterre.get_child_count() == 8, "Upper castle parterre planting is incomplete")
    assert(cloister_niches.get_child_count() == 4, "Outer cloister garden niches are incomplete")
    assert(cloister_niches.get_node("WestCloisterArchitecture").get_child_count() == 4)
    assert(cloister_niches.get_node("EastCloisterArchitecture").get_child_count() == 4)
    assert(north_courts.get_child_count() == 2, "North approach must have paired modular courts")
    assert(north_courts.get_node("WestApproachCourt").get_child_count() == 7)
    assert(north_courts.get_node("EastApproachCourt").get_child_count() == 7)
    assert(seating.get_child_count() == 2, "Paired outer seating alcoves are missing")
    assert(seating.get_node("WestSeatingAlcove").get_child_count() == 5)
    assert(seating.get_node("EastSeatingAlcove").get_child_count() == 5)
    assert(south_cloisters.get_child_count() == 8, "South outer cloister extensions are incomplete")

    print("LEGACY_BAKED_PATH_CELLS_PRESERVED=", original_paths.get_used_cells().size())
    assert(branch_root.has_node("CentralGrandPromenade"), "Playable central promenade is missing")
    print("ROAD_SURFACE_MODULES=", branch_root.get_child_count(), " NORTH_THRESHOLD_APRON=true")
    print("FOUNTAIN_FLOWERBED_SPRITES=", flowerbeds.get_child_count())
    print("PREVIEW_LIGHTS=", lights.get_child_count())
    print("AMBIENT_PETALS=", petals.emitting)
    print("HAND_PAINTED_ROAD_EDGE_CELLS=", road_edges.get_used_cells().size())
    print("PATHSIDE_CUSTOM_SPRITES=", pathside_planting.get_child_count())
    print("UPPER_PARTERRE_CUSTOM_SPRITES=", upper_parterre.get_child_count())
    print("OUTER_CLOISTER_NICHES=", cloister_niches.get_child_count(), " ARCHITECTURE_AND_GARDEN_SPRITES=16")
    print("NORTH_APPROACH_COURTS=", north_courts.get_child_count(), " PURPOSE_BUILT_SPRITES=14")
    print("OUTER_SEATING_ALCOVES=", seating.get_child_count(), " CUSTOM_SPRITES=10")
    print("SOUTH_CLOISTER_EXTENSION_SPRITES=", south_cloisters.get_child_count())
    print("ROYAL_GARDEN_STATIC_ASSET_QA_OK")
    quit(0)
