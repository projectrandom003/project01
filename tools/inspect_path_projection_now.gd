extends SceneTree
func _initialize():
 var n=load("res://scenes/world/castle_gardens/components/castle_pathways.tscn").instantiate()
 var l=n.get_node("Tiles")
 for p in [Vector2(170,420),Vector2(1110,420),Vector2(1110,1080),Vector2(170,1080),Vector2(170,550),Vector2(1110,550),Vector2(170,980),Vector2(1110,980),Vector2(640,470),Vector2(640,1000),Vector2(350,690),Vector2(930,690)]:
  var c=l.local_to_map(p)
  print("P ",p," CELL ",c," CENTER ",l.map_to_local(c))
 quit()
