extends SceneTree
func _initialize():
	var s=(load("res://scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn") as PackedScene).instantiate()
	var l=s.get_node("BaseGround") as TileMapLayer
	var cells=l.get_used_cells()
	var minx=999999; var maxx=-999999; var miny=999999; var maxy=-999999
	for c in cells:
		minx=min(minx,c.x); maxx=max(maxx,c.x); miny=min(miny,c.y); maxy=max(maxy,c.y)
	print("BOUNDS ",minx,"..",maxx," / ",miny,"..",maxy)
	for c in [Vector2i(24,0),Vector2i(24,5),Vector2i(24,10),Vector2i(24,15),Vector2i(24,20),Vector2i(24,25),Vector2i(24,-5),Vector2i(24,-10),Vector2i(24,-15)]:
		print("MAP ",c," local ",l.map_to_local(c)," world ",l.to_global(l.map_to_local(c)))
	quit()
