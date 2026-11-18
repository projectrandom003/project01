extends SceneTree

const TILESET_PATH := "res://assets/environment/castle_gardens/terrain/royal_garden_ground_isometric_tileset.tres"
const OUTPUT_PATH := "res://scenes/world/castle_gardens/components/castle_road_edge_transitions.tscn"

func _initialize() -> void:
    call_deferred("_author")

func _author() -> void:
    var layer := TileMapLayer.new()
    layer.name = "HandPaintedRoadEdgeTransitions"
    layer.tile_set = load(TILESET_PATH) as TileSet
    layer.z_index = -27
    layer.z_as_relative = false
    layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

    var world_points: Array[Vector2] = []
    for y in [280, 360, 440, 520, 600, 680, 760, 840, 920, 1000, 1080]:
        world_points.append(Vector2(570, y))
        world_points.append(Vector2(710, y))

    # Outer shoulders of the west and east fountain loops.
    for p in [
        Vector2(230, 650), Vector2(230, 700), Vector2(250, 750),
        Vector2(295, 790), Vector2(355, 805), Vector2(420, 785),
        Vector2(470, 750), Vector2(1050, 650), Vector2(1050, 700),
        Vector2(1030, 750), Vector2(985, 790), Vector2(925, 805),
        Vector2(860, 785), Vector2(810, 750)
    ]:
        world_points.append(p)

    # The lower parterre's outer shoulder, kept clear of its planted beds.
    for p in [
        Vector2(505, 815), Vector2(495, 865), Vector2(520, 915),
        Vector2(575, 950), Vector2(640, 965), Vector2(705, 950),
        Vector2(760, 915), Vector2(785, 865), Vector2(775, 815)
    ]:
        world_points.append(p)

    var seen: Dictionary = {}
    var index := 0
    for point in world_points:
        var cell := layer.local_to_map(point)
        if seen.has(cell):
            continue
        seen[cell] = true
        var atlas := Vector2i(0, 2)
        if index % 4 == 1:
            atlas = Vector2i(2, 2)
        elif index % 4 == 2:
            atlas = Vector2i(3, 2)
        elif index % 4 == 3:
            atlas = Vector2i(0, 1)
        layer.set_cell(cell, 0, atlas)
        index += 1

    var root := Node2D.new()
    root.name = "RoyalRoadEdgeTransitions"
    root.add_child(layer)
    layer.owner = root
    var packed := PackedScene.new()
    assert(packed.pack(root) == OK)
    assert(ResourceSaver.save(packed, OUTPUT_PATH) == OK)
    print("HAND_PAINTED_EDGE_TRANSITION_CELLS=", seen.size())
    print("EDGE_TRANSITION_ATLAS=royal_garden_ground_isometric_tileset")
    print("EDGE_TRANSITION_SCENE=", OUTPUT_PATH)
    quit()
