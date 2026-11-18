extends SceneTree
func _initialize():
 var s=(load("res://scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn") as PackedScene).instantiate()
 for lname in ["Water","Paths"]:
  var n=s.get_node(lname) as TileMapLayer
  print("\n",lname," count ",n.get_used_cells().size())
  for c in n.get_used_cells():
   print("CELL ",c," atlas ",n.get_cell_atlas_coords(c)," alt ",n.get_cell_alternative_tile(c)," xy ",n.to_global(n.map_to_local(c)))
 quit()
