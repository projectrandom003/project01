extends SceneTree

const TEXTURE_PATH := "res://assets/reverie_custom/royal_gardens/production/royal_cobble_ribbon_96.png"
const OUTPUT_PATH := "res://scenes/world/castle_gardens/components/castle_road_surface_assembly.tscn"


func _initialize() -> void:
    call_deferred("_author")

func _make_ribbon(points: PackedVector2Array, half_width: float) -> PackedVector2Array:
    var left: PackedVector2Array = []
    var right: PackedVector2Array = []
    for i in range(points.size()):
        var previous := points[maxi(i - 1, 0)]
        var following := points[mini(i + 1, points.size() - 1)]
        var tangent := (following - previous).normalized()
        var normal := Vector2(-tangent.y, tangent.x)
        left.append(points[i] + normal * half_width)
        right.append(points[i] - normal * half_width)
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
            Vector2(640, 510), Vector2(640, 580), Vector2(640, 680),
            Vector2(640, 780), Vector2(640, 880), Vector2(640, 980),
            Vector2(640, 1080), Vector2(640, 1180)
        ]),
        PackedVector2Array([
            Vector2(575, 620), Vector2(545, 620), Vector2(515, 615),
            Vector2(485, 608), Vector2(455, 602), Vector2(425, 598),
            Vector2(395, 596), Vector2(365, 596), Vector2(335, 600),
            Vector2(305, 610), Vector2(278, 626), Vector2(255, 646),
            Vector2(240, 670), Vector2(236, 695), Vector2(242, 720),
            Vector2(258, 742), Vector2(282, 760), Vector2(310, 774),
            Vector2(340, 782), Vector2(370, 782), Vector2(400, 775),
            Vector2(430, 762), Vector2(460, 744), Vector2(490, 724),
            Vector2(520, 706), Vector2(548, 695), Vector2(575, 690)
        ]),
        PackedVector2Array([
            Vector2(705, 620), Vector2(735, 620), Vector2(765, 615),
            Vector2(795, 608), Vector2(825, 602), Vector2(855, 598),
            Vector2(885, 596), Vector2(915, 596), Vector2(945, 600),
            Vector2(975, 610), Vector2(1002, 626), Vector2(1025, 646),
            Vector2(1040, 670), Vector2(1044, 695), Vector2(1038, 720),
            Vector2(1022, 742), Vector2(998, 760), Vector2(970, 774),
            Vector2(940, 782), Vector2(910, 782), Vector2(880, 775),
            Vector2(850, 762), Vector2(820, 744), Vector2(790, 724),
            Vector2(760, 706), Vector2(732, 695), Vector2(705, 690)
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
        ]),
        PackedVector2Array([
            Vector2(420, 875), Vector2(405, 900), Vector2(385, 925),
            Vector2(365, 950), Vector2(350, 975), Vector2(340, 1000),
            Vector2(335, 1030), Vector2(335, 1060), Vector2(335, 1090),
            Vector2(335, 1160)
        ]),
        PackedVector2Array([
            Vector2(860, 875), Vector2(875, 900), Vector2(895, 925),
            Vector2(915, 950), Vector2(930, 975), Vector2(940, 1000),
            Vector2(945, 1030), Vector2(945, 1060), Vector2(945, 1090),
            Vector2(945, 1160)
        ]),
        PackedVector2Array([
            Vector2(535, 535), Vector2(560, 520), Vector2(585, 510),
            Vector2(610, 504), Vector2(640, 502), Vector2(670, 504),
            Vector2(695, 510), Vector2(720, 520), Vector2(745, 535)
        ])
    ]
    var branch_widths: Array[float] = [48.0, 34.0, 34.0, 42.0, 32.0, 32.0, 30.0, 30.0, 50.0]
    var assembly := Node2D.new()
    assembly.name = "RoyalRoadSurfaceAssembly"
    assembly.z_index = -28
    for i in range(branch_paths.size()):
        var road := Polygon2D.new()
        road.name = ["CentralGrandPromenade", "WestFountainGardenLoop", "EastFountainGardenLoop", "GrandFountainParterreLoop", "WestParterreConnector", "EastParterreConnector", "WestLowerGateWalk", "EastLowerGateWalk", "NorthCastleThresholdApron"][i]
        road.texture = cobble
        road.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
        road.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        road.polygon = _make_ribbon(branch_paths[i], branch_widths[i])
        road.uv = _make_uv(road.polygon)
        assembly.add_child(road)
        road.owner = assembly
    var packed := PackedScene.new()
    assert(packed.pack(assembly) == OK, "Could not pack static Royal Gardens road ribbons")
    assert(ResourceSaver.save(packed, OUTPUT_PATH) == OK, "Could not save static Royal Gardens road ribbons")
    print("STATIC_ROAD_RIBBONS=", branch_paths.size())
    print("ROAD_HALF_WIDTHS=", branch_widths)
    print("COBBLE_TEXTURE=", TEXTURE_PATH)
    print("STATIC_BRANCH_SCENE_SAVED=", OUTPUT_PATH)
    quit()
