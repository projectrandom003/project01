extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var scene=(load("res://scenes/world/castle_gardens/components/reverie_royal_gardens_full_preview.tscn") as PackedScene).instantiate()
    root.add_child(scene)
    await process_frame
    var layer=scene.get_node("PathwaySystem/RoyalPathways/Tiles") as TileMapLayer
    for p in [Vector2(350,690),Vector2(930,690),Vector2(640,820),Vector2(640,500),Vector2(500,650),Vector2(780,650)]:
        var cell=layer.local_to_map(p)
        print("WORLD ",p," CELL ",cell," CENTER ",layer.map_to_local(cell))
    for c in layer.get_used_cells():
        print("CELL ",c," POS ",layer.map_to_local(c))
    quit()
