class_name GothicRouteDecorationComponent
extends Node
## Authored Gothic Castle environment responsibility node.

var environment: GothicCastleEnvironmentComponent

func configure(owner: GothicCastleEnvironmentComponent) -> void:
	environment = owner

func _decorate_route() -> void:
	var path_cells := ReverieRouteData.all_path_cells()
	# Gothic Castle entry grounds: dead trees, ironwork, cold lanterns and
	# corrupted stonework. Royal Gardens props belong only to that region.
	for anchor in [Vector2i(2, -4), Vector2i(6, -4), Vector2i(10, -4), Vector2i(4, 4),
					Vector2i(12, 4), Vector2i(8, -8), Vector2i(14, -11)]:
		environment._place("Corrupted_Environment", "Vegetation", "tree_dead_01", anchor, environment.flora_layer)
	for anchor in [Vector2i(1, 5), Vector2i(5, 5), Vector2i(9, 5), Vector2i(13, -6)]:
		environment._place("Corrupted_Environment", "Vegetation", "tree_corrupted_01", anchor, environment.flora_layer)
	for anchor in [Vector2i(3, -2), Vector2i(11, -2), Vector2i(7, 2)]:
		environment._place("Gothic_Castle", "Decorations", "gothic_statue_knight", anchor, environment.props_layer)
	for x in range(0, 15, 3):
		environment._place("Gothic_Castle", "Decorations", "lantern_gothic_post", Vector2i(x, -2), environment.props_layer)
		environment._place("Corrupted_Environment", "Vegetation", "bush_corrupted_01", Vector2i(x, 2), environment.flora_layer)
	for anchor in [Vector2i(8, -9), Vector2i(12, -9), Vector2i(16, -9)]:
		environment._place("Gothic_Castle", "Decorations", "gothic_statue_saint", anchor, environment.props_layer)
	# Former garden branch is now a blighted grove: twisted growth and dead
	# trees, with no fountains, flowerbeds, blossom trees or royal ornament.
	for anchor in [Vector2i(8, -7), Vector2i(10, -7), Vector2i(12, -7),
					Vector2i(14, -7), Vector2i(16, -7)]:
		environment._place("Corrupted_Environment", "Vegetation", "tree_corrupted_02", anchor, environment.flora_layer)
		environment._place("Corrupted_Environment", "Vegetation", "corrupted_flower_01", Vector2i(anchor.x, anchor.y + 2), environment.flora_layer)
	environment._place("Corrupted_Environment", "Structures", "corrupted_fountain_2x2", Vector2i(18, -12), environment.props_layer)
	# Corruption grows gradually: withered first, broken ruins and crystals later.
	var cell_list: Array[Vector2i] = []
	for cell in path_cells:
		cell_list.append(cell)
	for i in range(cell_list.size()):
		var cell: Vector2i = cell_list[i]
		var progress := float(i) / maxf(1.0, float(cell_list.size() - 1))
		if progress < 0.3:
			continue
		if i % 7 != 0:
			continue
		var offset := Vector2i((i % 3) - 1, ((i / 3) % 3) - 1)
		var anchor := cell + offset
		if path_cells.has(anchor):
			continue
		if progress < 0.52:
			environment._place("Corrupted_Environment", "Vegetation", "tree_dead_01", anchor, environment.flora_layer)
		elif progress < 0.74:
			environment._place("Corrupted_Environment", "Vegetation", "tree_corrupted_01", anchor, environment.flora_layer)
			environment._place("Corrupted_Environment", "Vegetation", "corruption_growth_02", anchor + Vector2i(1, 1), environment.flora_layer)
		else:
			environment._place("Corrupted_Environment", "Structures", "ruined_pillar_01", anchor, environment.props_layer)
			environment._place("Corrupted_Environment", "Structures", "corrupted_brazier", anchor + Vector2i(1, 0), environment.props_layer)
	for anchor in [Vector2i(20, 8), Vector2i(24, 8), Vector2i(28, 10), Vector2i(34, 12),
					Vector2i(42, 4), Vector2i(50, 4), Vector2i(54, 8)]:
		environment._place("Corrupted_Environment", "Vegetation", "tree_dead_02", anchor, environment.flora_layer)
	for anchor in [Vector2i(30, 16), Vector2i(34, 16), Vector2i(36, 16),
					Vector2i(44, -12), Vector2i(48, -12), Vector2i(50, -12)]:
		environment._place("Corrupted_Environment", "Structures", "broken_statue_01", anchor, environment.props_layer)
	for anchor in [Vector2i(32, 18), Vector2i(34, 18), Vector2i(46, -12), Vector2i(50, -16)]:
		environment._place("Corrupted_Environment", "Vegetation", "corruption_growth_03", anchor, environment.flora_layer)
	for anchor in [Vector2i(26, 18), Vector2i(42, -14), Vector2i(52, -16), Vector2i(56, 6)]:
		environment._place("Corrupted_Environment", "Effects", "purple_glow_soft", anchor, environment.effects_layer, 1)
	for anchor in [Vector2i(24, 8), Vector2i(40, 4), Vector2i(52, 4)]:
		environment._place("Corrupted_Environment", "Effects", "dark_fog_low", anchor, environment.effects_layer, 1)
	for anchor in [Vector2i(18, 0), Vector2i(30, 8), Vector2i(46, 4), Vector2i(58, 4)]:
		environment._place("Pathways", "Borders", "border_post_01", anchor + Vector2i(0, -2), environment.props_layer)
		environment._place("Pathways", "Borders", "border_chain_post", anchor + Vector2i(0, 2), environment.props_layer)
