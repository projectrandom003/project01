extends SceneTree
func _initialize() -> void:
 var packed := load("res://scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn") as PackedScene
 var scene := packed.instantiate()
 var paths := scene.get_node("Paths") as TileMapLayer
 paths.clear()
 # Isometric coordinates: increment x and y together to preserve screen-space X.
 # This creates one centered vertical promenade from the gate toward the garden.
 for y in range(5, 25):
  paths.set_cell(Vector2i(y + 19, y), 0, Vector2i((y - 5) % 4, 0), 0)
 var out := PackedScene.new()
 var err := out.pack(scene)
 if err == OK:
  err = ResourceSaver.save(out, "res://scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn")
 if err != OK:
  push_error("Could not save centered promenade: " + str(err))
  quit(1)
  return
 print("CENTERED_PROMENADE_OK cells=", paths.get_used_cells().size(), " start=", paths.to_global(paths.map_to_local(Vector2i(24, 5))), " end=", paths.to_global(paths.map_to_local(Vector2i(54, 35))))
 scene.free()
 quit(0)
