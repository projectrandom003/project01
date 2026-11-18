extends SceneTree
func _initialize():
 var packed=load("res://scenes/world/castle_gardens/components/reverie_royal_gardens_full_preview.tscn")
 var atlas=load("res://assets/reverie_custom/royal_gardens/production/reverie_fence_tileset_32.png")
 if packed == null or atlas == null:
  push_error("FENCE_TILESET_OR_PREVIEW_LOAD_FAILED")
  quit(1)
  return
 if atlas.get_width()!=96 or atlas.get_height()!=64:
  push_error("FENCE_ATLAS_DIMENSIONS_INVALID")
  quit(1)
  return
 var world=packed.instantiate()
 root.add_child(world)
 await process_frame
 var runs=world.get_node_or_null("FenceSystem/GardenFences/FenceRuns")
 var path_group=runs.get_node_or_null("StonePathwayFenceSides") if runs else null
 if path_group==null:
  push_error("PATH_SIDE_FENCES_MISSING")
  quit(1)
  return
 print("FENCE_ATLAS=96x64; CELL=32x32; CELLS=6")
 print("PATH_SIDE_FENCE_SPRITES=",path_group.get_child_count())
 print("PATH_SIDE_POSITIONS_WEST=",path_group.get_children().filter(func(n): return n.name.begins_with("West")).size())
 print("PATH_SIDE_POSITIONS_EAST=",path_group.get_children().filter(func(n): return n.name.begins_with("East")).size())
 if path_group.get_child_count()!=22:
  push_error("PATH_SIDE_FENCE_COUNT_INVALID")
  quit(1)
  return
 print("GENERATED_32PX_FENCES_QA_OK")
 quit()
