class_name MapScreen
extends OverlayScreen
## Functional world map: region name, player position, POIs, quest markers,
## and directional guidance to the tracked quest objective.

var _info_box: VBoxContainer


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

	# Player position
	var player_grid := Vector2.ZERO
	if GameState.has_player_position:
		player_grid = IsoMath.world_to_grid(GameState.player_position)
	left.add_child(UIFactory.label("Player: (%.0f, %.0f)" % [player_grid.x, player_grid.y], 12, UITheme.TEXT))

	# Right: info panel
	var right := UIFactory.vbox(10)
	right.custom_minimum_size = Vector2(360, 0)
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
		var dist_to := 0.0
		if GameState.has_player_position:
			dist_to = GameState.player_position.distance_to(poi_pos)
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
		right.add_child(UIFactory.label(str(step.get("text", "")), 11, UITheme.TEXT_DIM))
		var dist := GameState.distance_to_tracked()
		var arrow := _quest_arrow()
		right.add_child(UIFactory.label("%s  %.0f tiles" % [arrow, dist / 16.0], 12, UITheme.TEAL))


func _quest_arrow() -> String:
	var dir := GameState.direction_to_tracked()
	if dir.length_squared() < 0.0001:
		return "•"
	var angle := dir.angle()
	if angle < 0.0:
		angle += TAU
	var sector := int(round(angle / (PI * 0.25))) % 8
	var arrows := ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"]
	return arrows[sector]
