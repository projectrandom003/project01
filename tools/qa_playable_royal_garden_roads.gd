extends SceneTree
func _initialize():
 var packed=load("res://scenes/world/castle_royal_gardens.tscn")
 if packed == null:
  push_error("PLAYABLE_GARDEN_LOAD_FAILED")
  quit(1)
  return
 var world=packed.instantiate()
 root.add_child(world)
 await process_frame
 var layer=world.get_node_or_null("PathwayTiles/Tiles") as TileMapLayer
 if layer == null:
  push_error("PLAYABLE_GARDEN_PATH_LAYER_MISSING")
  quit(1)
  return
 print("PLAYABLE_GARDEN_LOAD_OK")
 print("PLAYABLE_ROAD_CELL_COUNT=",layer.get_used_cells().size())
 print("PLAYABLE_SPINE_CROSS_JUNCTION=",layer.get_cell_source_id(Vector2i(30,12)))
 print("PLAYABLE_WEST_FOUNTAIN_COURT=",layer.get_cell_source_id(Vector2i(26,16)))
 print("PLAYABLE_EAST_FOUNTAIN_COURT=",layer.get_cell_source_id(Vector2i(35,7)))
 print("PLAYABLE_PERIMETER_COURT=",layer.get_cell_source_id(Vector2i(19,15)))
 quit()
