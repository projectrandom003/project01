extends SceneTree
func _initialize():
 var s=(load("res://scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn") as PackedScene).instantiate()
 var n=s.get_node("Paths") as TileMapLayer
 for c in n.get_used_cells():
  print(c," -> ",n.map_to_local(c))
 quit()
