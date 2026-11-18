extends SceneTree
func _initialize():
	var p=load("res://scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn") as PackedScene
	var s=p.instantiate()
	for n in ["BaseGround","GroundVariation","Paths","Water","FlowerDetails","Hedges","Vegetation","Foreground"]:
		var l=s.get_node(n) as TileMapLayer
		print("\n",n," count=",l.get_used_cells().size())
		var cells=l.get_used_cells()
		for i in range(min(cells.size(),40)):
			var c=cells[i]
			print(c," atlas=",l.get_cell_atlas_coords(c)," alt=",l.get_cell_alternative_tile(c))
	quit()
