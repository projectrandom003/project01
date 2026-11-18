extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var packed := load("res://scenes/world/castle_royal_gardens.tscn") as PackedScene
    if packed == null:
        push_error("Playable Royal Gardens scene failed to load")
        quit(1)
        return
    var world := packed.instantiate()
    root.add_child(world)
    for i in range(5):
        await process_frame
    var paths := world.get_node_or_null("PathwayTiles/Tiles") as TileMapLayer
    var beds := world.get_node_or_null("Flora/FountainFlowerbeds") as Node2D
    var lighting := world.get_node_or_null("Lighting") as Node2D
    var effects := world.get_node_or_null("EnvironmentEffects") as Node2D
    if paths == null or beds == null or lighting == null or effects == null:
        push_error("Playable world is missing shared garden systems")
        quit(1)
        return
    var light_count := 0
    for child in lighting.get_children():
        if child is PointLight2D:
            light_count += 1
    print("PLAYABLE_GARDEN_PATH_CELLS=", paths.get_used_cells().size())
    print("PLAYABLE_GARDEN_FLOWERBED_SPRITES=", beds.get_child_count())
    print("PLAYABLE_GARDEN_LIGHTS=", light_count)
    print("PLAYABLE_GARDEN_AMBIENT_EFFECTS=", effects.get_child_count())
    if paths.get_used_cells().size() < 70 or beds.get_child_count() < 38 or light_count < 10 or effects.get_child_count() < 1:
        push_error("Playable garden did not receive the enriched presentation")
        quit(1)
        return
    print("PLAYABLE_ROYAL_GARDEN_SMOKE_OK")
    quit(0)
