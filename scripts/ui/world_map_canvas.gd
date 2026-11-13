extends Control
## Schematic region map with POIs, current player position and tracked objective.
## Uses authored region coordinates; it does not invent roads or navigable paths.

var _region: Dictionary = {}
var _player_grid: Vector2 = Vector2.ZERO
var _quest_grid: Vector2 = Vector2.ZERO
var _has_player := false
var _has_quest := false
var _player_facing := Vector2.RIGHT

func _ready() -> void:
	custom_minimum_size = Vector2(480, 340)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(func() -> void: queue_redraw())
	refresh_map()

func refresh_map() -> void:
	_region = ContentDB.get_region(GameState.player_region)
	var player := get_tree().get_first_node_in_group("player")
	_has_player = player is Node2D or GameState.has_player_position
	if player is Node2D:
		_player_grid = IsoMath.world_to_grid((player as Node2D).global_position)
	elif _has_player:
		_player_grid = IsoMath.world_to_grid(GameState.player_position)
	var tracked := GameState.tracked_quest()
	_has_quest = not tracked.is_empty() and GameState.quest_state(tracked) == "active"
	if _has_quest:
		var definition: Dictionary = ContentDB.get_quest(tracked)
		_has_quest = str(definition.get("region", "greenward")) == GameState.player_region
		if _has_quest:
			# Use the same live target as the HUD compass and in-world beacon.
			# Kill objectives follow the nearest living matching monster.
			_quest_grid = IsoMath.world_to_grid(GameState.quest_target_position(tracked))
	if player is Node2D and "velocity" in player and player.velocity.length_squared() > 1.0:
		_player_facing = player.velocity.normalized()
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 40.0 or h < 40.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#09131b"))
	draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Color("#101e25"), false, 2.0)
	var bounds := Rect2(Vector2(18, 18), size - Vector2(36, 36))
	# Fit the entire authored region instead of clipping distant objectives
	# to an arbitrary 40x32 frame. Include every POI plus the live player and
	# active objective so the map always shows the true destination.
	var min_x := 8.0
	var min_y := 8.0
	var max_x := 8.0
	var max_y := 8.0
	for poi in _region.get("pois", []):
		if typeof(poi) != TYPE_DICTIONARY:
			continue
		var grid: Array = poi.get("grid", [])
		if grid.size() != 2:
			continue
		min_x = minf(min_x, float(grid[0]))
		min_y = minf(min_y, float(grid[1]))
		max_x = maxf(max_x, float(grid[0]))
		max_y = maxf(max_y, float(grid[1]))
	if _has_player:
		min_x = minf(min_x, _player_grid.x)
		min_y = minf(min_y, _player_grid.y)
		max_x = maxf(max_x, _player_grid.x)
		max_y = maxf(max_y, _player_grid.y)
	if _has_quest:
		min_x = minf(min_x, _quest_grid.x)
		min_y = minf(min_y, _quest_grid.y)
		max_x = maxf(max_x, _quest_grid.x)
		max_y = maxf(max_y, _quest_grid.y)
	min_x -= 8.0
	min_y -= 8.0
	max_x += 8.0
	max_y += 8.0
	var scale_x := bounds.size.x / maxf(1.0, max_x - min_x)
	var scale_y := bounds.size.y / maxf(1.0, max_y - min_y)
	var scale_value := minf(scale_x, scale_y)
	var used := Vector2((max_x - min_x) * scale_value, (max_y - min_y) * scale_value)
	# Offset the origin by the minimum grid coordinate so existing world-to-map
	# drawing expressions remain consistent for negative and positive regions.
	var origin := bounds.position + (bounds.size - used) * 0.5 - Vector2(min_x, min_y) * scale_value
	var biome: Dictionary = _region.get("biome", {})
	var land_color := Color(str((biome.get("grass_colors", ["#314d3d"]) as Array)[0]))
	var path_color := Color(str(biome.get("path_color", "#8a7a55")))
	var water_color := Color(str(biome.get("water_deep", "#1f5568")))
	# Rebuild the same deterministic terrain used by ChunkBuilder.
	# This makes the map's river, elevation and routes agree with the playable world.
	var elevation := FastNoiseLite.new()
	elevation.seed = int(_region.get("noise_seed", 1337))
	elevation.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	elevation.frequency = 0.032
	elevation.fractal_octaves = 3
	var moisture := FastNoiseLite.new()
	moisture.seed = int(_region.get("noise_seed", 1337)) + 91
	moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	moisture.frequency = 0.055
	moisture.fractal_octaves = 2
	var colors: Array = biome.get("grass_colors", ["#4f7a46"])
	var water_level := float(biome.get("water_level", -0.22))
	var river_base := 30.0
	var river_meander := 0.16
	var river_amplitude := 6.0
	var river_noise_amp := 5.0
	var river_half_width := 1.2
	var authored_paths := ChunkBuilder._path_segments(_region)
	# Cap background terrain sampling so a full-world view stays lightweight.
	# POIs, paths, player and objective markers are still drawn at exact positions.
	var area_tiles := maxf(1.0, (max_x - min_x) * (max_y - min_y))
	var map_step := maxi(1, int(ceil(sqrt(area_tiles / 6000.0))))
	var map_cell_size := scale_value * float(map_step)
	for gy in range(int(floor(min_y)), int(ceil(max_y)) + 1, map_step):
		for gx in range(int(floor(min_x)), int(ceil(max_x)) + 1, map_step):
			var elev := elevation.get_noise_2d(gx, gy)
			var wet := moisture.get_noise_2d(gx, gy)
			var river_center := river_base + sin(float(gx) * river_meander) * river_amplitude + elevation.get_noise_2d(float(gx) * 0.6 + 91.0, 317.0) * river_noise_amp
			var river_distance := absf(float(gy) - river_center)
			var water := elev < water_level or river_distance <= river_half_width
			var tile_color: Color
			if water:
				var depth := clampf((water_level - elev) / 0.14, 0.0, 1.0)
				tile_color = water_color.darkened(depth * 0.18)
				if river_distance > river_half_width and river_distance < river_half_width + 0.7:
					tile_color = tile_color.lightened(0.24)
			else:
				var ci := absi(int(round(wet * 20.0))) % colors.size()
				tile_color = Color(str(colors[ci]))
				var high := clampf((elev + 0.3) / 0.9, 0.0, 1.0)
				tile_color = tile_color.lerp(Color("#9b956b"), high * 0.16)
				if elev - water_level < 0.12:
					tile_color = tile_color.lerp(Color("#b5ad79"), 0.32)
				if ChunkBuilder._near_path(Vector2(gx, gy), authored_paths):
					tile_color = path_color.lightened(wet * 0.05)
			var cell := Rect2(origin.x + float(gx) * scale_value, origin.y + float(gy) * scale_value, map_cell_size + 0.35, map_cell_size + 0.35)
			draw_rect(cell, tile_color)
			# Small clustered canopy glyphs on wetter forest ground (not scattered dots).
			if not water and wet > 0.12 and elev > -0.05 and absi(gx * 31 + gy * 17 + int(_region.get("noise_seed", 1))) % 11 == 0 and not ChunkBuilder._near_path(Vector2(gx, gy), authored_paths):
				var tree_base := Vector2(cell.position.x + scale_value * 0.52, cell.position.y + scale_value * 0.68)
				var tree_color := land_color.darkened(0.42)
				draw_colored_polygon(PackedVector2Array([tree_base + Vector2(0, -scale_value * 0.65), tree_base + Vector2(-scale_value * 0.34, scale_value * 0.12), tree_base + Vector2(scale_value * 0.34, scale_value * 0.12)]), tree_color)
				draw_colored_polygon(PackedVector2Array([tree_base + Vector2(0, -scale_value * 0.35), tree_base + Vector2(-scale_value * 0.42, scale_value * 0.28), tree_base + Vector2(scale_value * 0.42, scale_value * 0.28)]), tree_color.lightened(0.08))
	# Soft map border; real landmarks and routes remain the foreground layer.
	var font := ThemeDB.fallback_font
	# Authored POIs and their labels.
	for poi in _region.get("pois", []):
		if typeof(poi) != TYPE_DICTIONARY:
			continue
		var grid: Array = poi.get("grid", [])
		if grid.size() != 2:
			continue
		var point := origin + Vector2(float(grid[0]), float(grid[1])) * scale_value
		var kind := str(poi.get("type", "landmark"))
		var color := Color("#d8bb73")
		if kind == "boss":
			color = Color("#df6871")
		elif kind == "ruin":
			color = Color("#78c6c4")
		elif kind == "dungeon":
			color = Color("#b28ad9")
		elif kind == "npc":
			color = Color("#75c8ef")
		draw_circle(point, 7.0, Color(color.r, color.g, color.b, 0.18))
		draw_circle(point, 3.8, color)
		draw_string(font, point + Vector2(9, 4), str(poi.get("name", "Landmark")), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#e2e8df"))
	# Live exploration objects (gathering nodes, shrines and lore props).
	# These are read from the same interactables used by the world interaction
	# system, so the map never invents a collectible location.
	for node in get_tree().get_nodes_in_group("interactables"):
		if not is_instance_valid(node) or not node.visible:
			continue
		var grid_pos := IsoMath.world_to_grid(node.global_position)
		var point := origin + Vector2(clampf(grid_pos.x, min_x, max_x), clampf(grid_pos.y, min_y, max_y)) * scale_value
		var kind := str(node.get("prop_kind")) if "prop_kind" in node else "interactable"
		var marker_color := Color("#79e6d5")
		if kind.contains("crystal"):
			marker_color = Color("#b88cff")
		elif kind.contains("herb") or kind.contains("flower"):
			marker_color = Color("#9df5a8")
		draw_circle(point, 6.0, Color(marker_color.r, marker_color.g, marker_color.b, 0.18))
		draw_colored_polygon(PackedVector2Array([
			point + Vector2(0, -4), point + Vector2(4, 0),
			point + Vector2(0, 4), point + Vector2(-4, 0)
		]), marker_color)

	# Tracked objective line and marker.
	if _has_quest and _has_player:
		var player_point := origin + Vector2(clampf(_player_grid.x, min_x, max_x), clampf(_player_grid.y, min_y, max_y)) * scale_value
		var quest_point := origin + Vector2(clampf(_quest_grid.x, min_x, max_x), clampf(_quest_grid.y, min_y, max_y)) * scale_value
		draw_line(player_point, quest_point, Color(1.0, 0.78, 0.2, 0.62), 2.0)
		draw_circle(quest_point, 9.0, Color(1.0, 0.78, 0.2, 0.18))
		draw_colored_polygon(PackedVector2Array([
			quest_point + Vector2(0, -6), quest_point + Vector2(5, 0),
			quest_point + Vector2(0, 6), quest_point + Vector2(-5, 0)
		]), Color("#ffd65c"))
	# Current player location and heading.
	if _has_player:
		var clamped_grid := Vector2(clampf(_player_grid.x, min_x, max_x), clampf(_player_grid.y, min_y, max_y))
		var player_point := origin + clamped_grid * scale_value
		draw_circle(player_point, 12.0, Color(0.25, 0.8, 1.0, 0.16))
		if clamped_grid.distance_to(_player_grid) > 0.5:
			draw_arc(player_point, 10.0, 0.0, TAU, 32, Color("#8be6ff"), 2.0)
		draw_circle(player_point, 5.0, Color("#55d7ff"))
		var facing := _player_facing.normalized()
		var side := Vector2(-facing.y, facing.x)
		draw_colored_polygon(PackedVector2Array([
			player_point + facing * 11.0,
			player_point - facing * 5.0 + side * 4.0,
			player_point - facing * 5.0 - side * 4.0
		]), Color.WHITE)
	# Compact legend.
	draw_circle(Vector2(22, h - 13), 3.0, Color("#55d7ff"))
	draw_string(font, Vector2(31, h - 9), "You", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#d9e5e0"))
	draw_circle(Vector2(78, h - 13), 3.0, Color("#df6871"))
	draw_string(font, Vector2(87, h - 9), "Boss", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#d9e5e0"))
	draw_colored_polygon(PackedVector2Array([Vector2(142, h - 17), Vector2(146, h - 13), Vector2(142, h - 9), Vector2(138, h - 13)]), Color("#ffd65c"))
	draw_string(font, Vector2(152, h - 9), "Objective", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#d9e5e0"))
	draw_circle(Vector2(226, h - 13), 3.0, Color("#75c8ef"))
	draw_string(font, Vector2(235, h - 9), "NPC", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#d9e5e0"))
