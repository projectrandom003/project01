class_name MapScreen
extends OverlayScreen
## Functional world map: region name, player position, POIs, quest markers,
## and directional guidance to the tracked quest objective.

const MAP_CANVAS_SCENE: PackedScene = preload("res://scenes/ui/components/world_map_canvas.tscn")

var _info_box: VBoxContainer
var _map_canvas: Control


func _init() -> void:
	screen_title = "World Map"
	screen_subtitle = "Current region, points of interest, and quest objectives"


func _build_content() -> void:
	var split := UIFactory.hbox(14)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(split)

	# Left: map info
	var left := UIFactory.vbox(8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(left)

	var region: Dictionary = {}
	if GameState.player_region != "":
		region = ContentDB.get_region(GameState.player_region)
	var region_name := "Unknown"
	if not region.is_empty():
		region_name = str(region.get("name", GameState.player_region))
	left.add_child(UIFactory.heading(region_name, 18, UITheme.TEXT))
	_map_canvas = MAP_CANVAS_SCENE.instantiate() as Control
	_map_canvas.custom_minimum_size = Vector2(620, 460)
	_map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_map_canvas)

	# Use the live player node whenever the world is active; the saved
	# position is only a fallback for screens opened outside gameplay.
	var player_world := GameState.player_position
	var live_player := get_tree().get_first_node_in_group("player")
	if live_player is Node2D:
		player_world = (live_player as Node2D).global_position
	var player_grid := IsoMath.world_to_grid(player_world)
	left.add_child(UIFactory.label("Player: (%.0f, %.0f)" % [player_grid.x, player_grid.y], 12, UITheme.TEXT))

	# Right: info panel
	var right := UIFactory.vbox(10)
	right.custom_minimum_size = Vector2(280, 0)
	split.add_child(right)

	right.add_child(UIFactory.label("POINTS OF INTEREST", 10, UITheme.TEXT_FAINT))
	_info_box = UIFactory.vbox(4)
	right.add_child(_info_box)

	var pois: Array = region.get("pois", [])
	for poi in pois:
		if typeof(poi) != TYPE_DICTIONARY:
			continue
		var grid: Variant = poi.get("grid", null)
		if typeof(grid) != TYPE_ARRAY or (grid as Array).size() != 2:
			continue
		var g: Array = grid
		var poi_name := str(poi.get("name", poi.get("id", "POI")))
		var poi_pos := IsoMath.grid_to_world(float(g[0]), float(g[1]))
		var dist_to := player_world.distance_to(poi_pos)
		var label := "%s  (%.0f, %.0f)  — %.0f tiles" % [poi_name, float(g[0]), float(g[1]), dist_to / 16.0]
		_info_box.add_child(UIFactory.label(label, 11, UITheme.TEXT_DIM))

	if pois.is_empty():
		_info_box.add_child(UIFactory.label("No points of interest.", 11, UITheme.TEXT_DIM))

	# Tracked quest
	right.add_child(UIFactory.separator())
	right.add_child(UIFactory.label("TRACKED QUEST", 10, UITheme.TEXT_FAINT))
	var tracked := GameState.tracked_quest()
	if tracked.is_empty() or GameState.quest_state(tracked) != "active":
		right.add_child(UIFactory.label("No quest tracked. Track one from the Quests screen.", 12, UITheme.TEXT_DIM))
	else:
		var definition: Dictionary = ContentDB.get_quest(tracked)
		var step: Dictionary = GameState.quest_step(tracked)
		right.add_child(UIFactory.label(str(definition.get("name", tracked)), 13, UITheme.TEXT))
		var resolver: QuestNavigationResolver = QuestNavigationResolver.shared()
		var game_screen := get_tree().get_first_node_in_group("game_screen")
		if game_screen != null and game_screen.get("quest_resolver") is QuestNavigationResolver:
			resolver = game_screen.get("quest_resolver") as QuestNavigationResolver
		var resolved := resolver.get_resolved_target(GameState.player_region, player_world)
		var objective_text := str(resolved.get("step_text", step.get("text", "")))
		right.add_child(UIFactory.label(objective_text, 11, UITheme.TEXT_DIM))
		if not bool(resolved.get("valid", false)):
			right.add_child(UIFactory.label("Destination unavailable", 12, UITheme.TEXT_FAINT))
		elif not bool(resolved.get("same_frame", false)):
			var next_hop: Dictionary = resolved.get("next_hop", {})
			var route: Array = resolved.get("route", [])
			if not route.is_empty() and not next_hop.is_empty():
				var hop_label := str(next_hop.get("label", ""))
				if hop_label.is_empty():
					hop_label = "Travel to " + str(next_hop.get("to", resolved.get("target_region_id", "destination")))
				right.add_child(UIFactory.label("Next: " + hop_label, 12, UITheme.TEAL))
			else:
				right.add_child(UIFactory.label("No route to destination", 12, UITheme.TEXT_FAINT))
		elif str(resolved.get("status", "")) == QuestNavigationResolver.STATUS_UNREACHABLE:
			right.add_child(UIFactory.label("Destination unreachable", 12, UITheme.TEXT_FAINT))
		else:
			var distance_value: Variant = resolved.get("distance", null)
			var direction_value: Variant = resolved.get("direction", Vector2.ZERO)
			var arrow := _quest_arrow(direction_value)
			if distance_value != null:
				right.add_child(UIFactory.label("%s  %.0f tiles" % [arrow, float(distance_value) / IsoMath.TILE_W], 12, UITheme.TEAL))


func _refresh() -> void:
	if _map_canvas != null and _map_canvas.has_method("refresh_map"):
		_map_canvas.refresh_map()


func _quest_arrow(direction: Variant = null) -> String:
	var dir: Vector2 = direction if typeof(direction) == TYPE_VECTOR2 else GameState.direction_to_tracked()
	if dir.length_squared() < 0.0001:
		return "•"
	var angle := dir.angle()
	if angle < 0.0:
		angle += TAU
	var sector := int(round(angle / (PI * 0.25))) % 8
	var arrows := ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"]
	return arrows[sector]
