class_name GothicGroundBuilderComponent
extends Node
## Authored Gothic Castle environment responsibility node.

var environment: GothicCastleEnvironmentComponent

func configure(owner: GothicCastleEnvironmentComponent) -> void:
	environment = owner

func _build_ground() -> void:
	var paths := ReverieRouteData.all_path_cells()
	for gy in range(ReverieRouteData.GRID_MIN.y, ReverieRouteData.GRID_MAX.y + 1):
		for gx in range(ReverieRouteData.GRID_MIN.x, ReverieRouteData.GRID_MAX.x + 1):
			var cell := Vector2i(gx, gy)
			var key := Vector2i(gx, gy)
			var progress := ReverieRouteData.progress_at(cell)
			var near_path := paths.has(cell)
			var in_arena := ReverieRouteData.in_arena(cell)
			var in_castle := environment._inside_castle(cell)
			var bridge_cell := environment._is_bridge_water(cell)
			if bridge_cell:
				environment._water_cells[key] = true
				environment._add_tile("Corrupted_Environment", "Effects", "corruption_pool_tile_01", cell, -19)
				continue
			if in_arena:
				var arena_tile := "arena_floor_dark_01"
				if (gx + gy) % 7 == 0:
					arena_tile = "arena_floor_rune_02"
				elif (gx * gy) % 11 == 0:
					arena_tile = "arena_floor_cracked_glow"
				environment._add_tile("Boss_Arena", "Flooring", arena_tile, cell)
				continue
			if near_path:
				var path_tile := "path_cobble_01"
				if progress > 0.78:
					path_tile = "path_ruined_02"
				elif progress > 0.48:
					path_tile = "path_corrupted_stone"
				elif (gx + gy) % 5 == 0:
					path_tile = "path_cobble_02"
				if absi((gx + gy) % 13) == 0:
					path_tile = "path_intersection"
				environment._add_tile("Pathways", "Ground", path_tile, cell)
				continue
			if in_castle:
				environment._add_tile("Pathways", "Ground", "gothic_courtyard_floor_01", cell)
				continue
			# Gothic Castle is a separate region, not a Royal Gardens overlay.
			# Its entire exterior uses weathered courtyard stone with corruption
			# spreading toward the arena; no Royal_Gardens terrain is instantiated.
			var courtyard_tile := "gothic_courtyard_floor_02" if (gx * 3 + gy * 5) % 4 == 0 else "gothic_courtyard_floor_01"
			if progress > 0.58 and (gx + gy) % 3 == 0:
				courtyard_tile = "path_corrupted_stone"
			environment._add_tile("Pathways", "Ground", courtyard_tile, cell)
