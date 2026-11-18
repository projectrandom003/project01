extends SceneTree
func _initialize() -> void:
 var scene_path := "res://scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn"
 var packed := load(scene_path) as PackedScene
 var scene := packed.instantiate()
 var water := scene.get_node("Water") as TileMapLayer
 water.clear()
 for cell in [Vector2i(25,15),Vector2i(26,15),Vector2i(27,15),Vector2i(25,16),Vector2i(26,16),Vector2i(27,16),Vector2i(34,6),Vector2i(35,6),Vector2i(36,6),Vector2i(34,7),Vector2i(35,7),Vector2i(36,7)]:
  water.set_cell(cell, 0, Vector2i(0,2), 0)
 var west_center := water.to_global(water.map_to_local(Vector2i(26,16)))
 var east_center := water.to_global(water.map_to_local(Vector2i(35,7)))
 var out := PackedScene.new()
 var err := out.pack(scene)
 if err == OK:
  err = ResourceSaver.save(out, scene_path)
 if err != OK:
  push_error("Could not save water layout: " + str(err))
  quit(1)
  return
 print("WATER_LAYOUT_OK cells=",water.get_used_cells().size()," west=",west_center," east=",east_center)
 scene.free()
 quit(0)
