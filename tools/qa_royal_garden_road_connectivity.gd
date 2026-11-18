extends SceneTree
func _initialize():
 var packed=load("res://scenes/world/castle_gardens/components/castle_pathways.tscn")
 var n=packed.instantiate()
 root.add_child(n)
 await process_frame
 var layer=n.get_node("Tiles") as TileMapLayer
 var cells=layer.get_used_cells()
 var remaining={}
 for c in cells: remaining[c]=true
 var dirs=[Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1),Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
 var components=[]
 while not remaining.is_empty():
  var seed=remaining.keys()[0]
  var stack=[seed]
  var comp=[]
  remaining.erase(seed)
  while not stack.is_empty():
   var c=stack.pop_back()
   comp.append(c)
   for d in dirs:
    var nb=c+d
    if remaining.has(nb):
     remaining.erase(nb)
     stack.append(nb)
  components.append(comp)
 components.sort_custom(func(a,b): return a.size() < b.size())
 print("ROAD_USED_CELLS=",cells.size())
 print("ROAD_CONNECTED_COMPONENTS=",components.size()," SIZES=",components.map(func(c): return c.size()))
 if components.size() != 1:
  push_error("ROAD_NETWORK_DISCONNECTED: %d components" % components.size())
  quit(1)
  return
 print("ROAD_NETWORK_CONTINUOUS_OK")
 for comp in components:
  if comp.size() <= 7:
   print("ISOLATED_COMPONENT=",comp)
 print("SPINE_TO_CROSS_JUNCTION=",layer.get_cell_source_id(Vector2i(30,12)))
 print("WEST_FOUNTAIN_LANDING=",layer.get_cell_source_id(Vector2i(26,16)))
 print("EAST_FOUNTAIN_LANDING=",layer.get_cell_source_id(Vector2i(35,7)))
 print("PERIMETER_CORNER=",layer.get_cell_source_id(Vector2i(19,15)))
 quit()
