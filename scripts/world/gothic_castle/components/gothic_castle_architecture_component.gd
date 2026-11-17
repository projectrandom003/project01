class_name GothicCastleArchitectureComponent
extends Node
## Authored Gothic Castle environment responsibility node.

var environment: GothicCastleEnvironmentComponent

func configure(owner: GothicCastleEnvironmentComponent) -> void:
	environment = owner

func _build_bridge_and_stairs() -> void:
	# Bridge deck makes the water channel traversable (no collision on deck).
	for x in range(ReverieRouteData.BRANCH_AQUEDUCT[2].x - 4, ReverieRouteData.BRANCH_AQUEDUCT[2].x - 1):
		environment._place("Pathways", "Bridges", "bridge_stone_x_2x3", Vector2i(x, ReverieRouteData.BRANCH_AQUEDUCT[2].y), environment.path_layer)
	environment._place("Pathways", "Bridges", "bridge_railing_x_2x1",
			Vector2i(ReverieRouteData.BRANCH_AQUEDUCT[2].x - 4, ReverieRouteData.BRANCH_AQUEDUCT[2].y - 2), environment.props_layer)
	# Walkable stairs on the main route.
	environment._place("Pathways", "Stairs", "stairs_stone_x_4step", Vector2i(28, 8), environment.path_layer)
	environment._place("Pathways", "Stairs", "stairs_stone_x_4step", Vector2i(56, 4), environment.path_layer)

func _build_castle() -> void:
	# A physically present, sealed landmark: wall ring + corner towers + roofs.
	for cell in ReverieRouteData.castle_wall_cells():
		var along_x := cell.x != ReverieRouteData.CASTLE_CENTER.x - 6 and cell.x != ReverieRouteData.CASTLE_CENTER.x + 6
		var piece_id := "gothic_wall_x_2x1" if along_x else "gothic_wall_y_1x2"
		var sub := "Walls"
		environment._place("Gothic_Castle", sub, piece_id, cell, environment.castle_layer)
	var c := ReverieRouteData.CASTLE_CENTER
	for anchor in [Vector2i(c.x - 7, c.y - 5), Vector2i(c.x + 6, c.y - 5),
					Vector2i(c.x - 7, c.y + 3), Vector2i(c.x + 6, c.y + 3)]:
		environment._place("Gothic_Castle", "Towers", "tower_body_2x2", anchor, environment.castle_layer)
		environment._place("Gothic_Castle", "Towers", "tower_roof_2x2", anchor, environment.castle_layer)
		environment._place("Gothic_Castle", "Towers", "spire_tall_1x1", anchor, environment.castle_layer)
	environment._place("Gothic_Castle", "Architecture", "gothic_facade_4x1", Vector2i(c.x - 2, c.y - 3), environment.castle_layer)
	# The gatehouse faces away from the road and is sealed by its own collision.
	environment._place("Gothic_Castle", "Architecture", "gothic_gatehouse_3x1", Vector2i(c.x - 1, c.y + 3), environment.castle_layer)
	for x in range(c.x - 4, c.x + 5, 3):
		environment._place("Gothic_Castle", "Banners", "banner_gothic_large_01", Vector2i(x, c.y - 4), environment.castle_layer)
	for x in [c.x - 5, c.x + 5]:
		environment._place("Gothic_Castle", "Decorations", "gargoyle_01", Vector2i(x, c.y - 4), environment.castle_layer)
		environment._place("Gothic_Castle", "Decorations", "torch_wall_cold", Vector2i(x, c.y + 4), environment.castle_layer)
	for x in range(c.x - 5, c.x + 6, 3):
		environment._place("Gothic_Castle", "Architecture", "buttress_x_1x1", Vector2i(x, c.y + 4), environment.castle_layer)
