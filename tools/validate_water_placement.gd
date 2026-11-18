extends SceneTree
func _initialize():
 var scene=(load("res://scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn") as PackedScene).instantiate()
 var water=scene.get_node("Water") as TileMapLayer
 var cells=water.get_used_cells()
 if cells.size()!=12:
  push_error("Expected 12 water tiles, found "+str(cells.size()))
  quit(1)
  return
 for c in cells:
  if water.get_cell_source_id(c)!=0 or water.get_cell_atlas_coords(c)!=Vector2i(0,2):
   push_error("Water tile uses unexpected source/atlas at "+str(c))
   quit(1)
   return
 var west=water.to_global(water.map_to_local(Vector2i(26,16)))
 var east=water.to_global(water.map_to_local(Vector2i(35,7)))
 if west.distance_to(Vector2(350,690))>5 or east.distance_to(Vector2(930,690))>5:
  push_error("Pond centers are not aligned with fountain artwork: "+str(west)+" / "+str(east))
  quit(1)
  return
 print("WATER_PLACEMENT_QA PASS; 2 organized 3x2 pond footprints; west=",west," east=",east)
 scene.free()
 quit(0)
