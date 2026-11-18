extends SceneTree

const TEXTURE_PATH := "res://assets/reverie_custom/royal_gardens/production/royal_cobble_ribbon_96.png"
const OUTPUT_PATH := "res://scenes/world/castle_gardens/components/castle_road_surface_assembly.tscn"
const ROAD_HALF_WIDTH := 42.0

func _initialize() -> void:
    call_deferred("_author")

func _make_ribbon(points: PackedVector2Array) -> PackedVector2Array:
    var left: PackedVector2Array = []
    var right: PackedVector2Array = []
    for i in range(points.size()):
        var previous := points[maxi(i - 1, 0)]
        var following := points[mini(i + 1, points.size() - 1)]
        var tangent := (following - previous).normalized()
        var normal := Vector2(-tangent.y, tangent.x)
        left.append(points[i] + normal * ROAD_HALF_WIDTH)
        right.append(points[i] - normal * ROAD_HALF_WIDTH)
    var polygon := left.duplicate()
    for i in range(right.size() - 1, -1, -1):
        polygon.append(right[i])
    return polygon

func _make_uv(polygon: PackedVector2Array) -> PackedVector2Array:
    var result: PackedVector2Array = []
    for point in polygon:
        result.append(point)
    return result

func _author() -> void:
    var cobble := load(TEXTURE_PATH) as Texture2D
    assert(cobble != null, "Seamless custom cobblestone texture is missing")
    var branch_paths: Array[PackedVector2Array] = [
        PackedVector2Array([
            Vector2(640, 240), Vector2(640, 320), Vector2(640, 400),
            Vector2(640, 480), Vector2(640, 580), Vector2(640, 680),
            Vector2(640, 780), Vector2(640, 880), Vector2(640, 980),
            Vector2(640, 1080), Vector2(640, 1180)
        ]),
        PackedVector2Array([
            Vector2(575, 620), Vector2(550, 625), Vector2(525, 632),
            Vector2(500, 642), Vector2(475, 655), Vector2(450, 672),
            Vector2(428, 690), Vector2(405, 708), Vector2(380, 721),
            Vector2(355, 729), Vector2(332, 730), Vector2(312, 723),
            Vector2(295, 710), Vector2(283, 693), Vector2(278, 675),
            Vector2(280, 657), Vector2(290, 640), Vector2(305, 625),
            Vector2(325, 613), Vector2(348, 605), Vector2(375, 601),
            Vector2(402, 600), Vector2(430, 602), Vector2(458, 605),
            Vector2(486, 609), Vector2(515, 613), Vector2(545, 617),
            Vector2(575, 620)
        ]),
        PackedVector2Array([
            Vector2(705, 620), Vector2(730, 625), Vector2(755, 632),
            Vector2(780, 642), Vector2(805, 655), Vector2(830, 672),
            Vector2(852, 690), Vector2(875, 708), Vector2(900, 721),
            Vector2(925, 729), Vector2(948, 730), Vector2(968, 723),
            Vector2(985, 710), Vector2(997, 693), Vector2(1002, 675),
            Vector2(1000, 657), Vector2(990, 640), Vector2(975, 625),
            Vector2(955, 613), Vector2(932, 605), Vector2(905, 601),
            Vector2(878, 600), Vector2(850, 602), Vector2(822, 605),
            Vector2(794, 609), Vector2(765, 613), Vector2(735, 617),
            Vector2(705, 620)
        ]),
        PackedVector2Array([
            Vector2(560, 790), Vector2(548, 805), Vector2(540, 825),
            Vector2(538, 845), Vector2(543, 865), Vector2(555, 885),
            Vector2(572, 902), Vector2(592, 914), Vector2(615, 922),
            Vector2(640, 925), Vector2(665, 922), Vector2(688, 914),
            Vector2(708, 902), Vector2(725, 885), Vector2(737, 865),
            Vector2(742, 845), Vector2(740, 825), Vector2(732, 805),
            Vector2(720, 790), Vector2(700, 778), Vector2(680, 770),
            Vector2(660, 766), Vector2(640, 765), Vector2(620, 766),
            Vector2(600, 770), Vector2(580, 778), Vector2(560, 790)
        ]),
        PackedVector2Array([
            Vector2(560, 790), Vector2(510, 785), Vector2(465, 790),
            Vector2(430, 810), Vector2(410, 840), Vector2(420, 875)
        ]),
        PackedVector2Array([
            Vector2(720, 790), Vector2(770, 785), Vector2(815, 790),
            Vector2(850, 810), Vector2(870, 840), Vector2(860, 875)
        ])
    ]
    var assembly := Node2D.new()
    assembly.name = "RoyalRoadSurfaceAssembly"
    assembly.z_index = -28
    for i in range(branch_paths.size()):
        var road := Polygon2D.new()
        road.name = ["CentralGrandPromenade", "WestFountainGardenLoop", "EastFountainGardenLoop", "GrandFountainParterreLoop", "WestParterreConnector", "EastParterreConnector"][i]
        road.texture = cobble
        road.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
        road.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        road.polygon = _make_ribbon(branch_paths[i])
        road.uv = _make_uv(road.polygon)
        assembly.add_child(road)
        road.owner = assembly
    var packed := PackedScene.new()
    assert(packed.pack(assembly) == OK, "Could not pack static Royal Gardens road ribbons")
    assert(ResourceSaver.save(packed, OUTPUT_PATH) == OK, "Could not save static Royal Gardens road ribbons")
    print("STATIC_ROAD_RIBBONS=", branch_paths.size())
    print("ROAD_HALF_WIDTH=", ROAD_HALF_WIDTH)
    print("COBBLE_TEXTURE=", TEXTURE_PATH)
    print("STATIC_BRANCH_SCENE_SAVED=", OUTPUT_PATH)
    quit()
