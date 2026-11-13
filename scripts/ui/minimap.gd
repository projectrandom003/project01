class_name Minimap
extends Control
## Compact live minimap showing terrain, player, NPCs, bosses and quest markers.

const MAP_SIZE := 224
const TILE_PX := 4.0
const VIEW_RADIUS := 26

var _collapsed: bool = false
var _expand_button: Button
var _collapse_button: Button
var _canvas: Control
var _world: Node = null
var _update_timer: float = 0.0

var _player_grid: Vector2 = Vector2.ZERO
var _player_facing: float = 0.0
var _npc_markers: Array = []
var _boss_markers: Array = []
var _interactable_markers: Array = []
var _quest_marker: Vector2 = Vector2.ZERO
var _has_quest_marker: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(MAP_SIZE, MAP_SIZE)
	size = Vector2(MAP_SIZE, MAP_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var panel := UIFactory.panel(Color("#0a0f1a"), UITheme.BORDER_SOFT, 8, 1, 4)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	_canvas.draw.connect(_on_draw)

	_expand_button = UIFactory.small_button("Map")
	_expand_button.custom_minimum_size = Vector2(40, 20)
	_expand_button.position = Vector2(MAP_SIZE - 44, 4)
	_expand_button.pressed.connect(func() -> void: _request_full_map())
	add_child(_expand_button)

	_collapse_button = UIFactory.small_button("-")
	_collapse_button.custom_minimum_size = Vector2(20, 20)
	_collapse_button.position = Vector2(MAP_SIZE - 68, 4)
	_collapse_button.pressed.connect(func() -> void: _toggle_collapse())
	add_child(_collapse_button)

	_find_world()


func _find_world() -> void:
	if is_inside_tree():
		_world = get_tree().get_first_node_in_group("world")


func _process(delta: float) -> void:
	if _collapsed:
		return
	_update_timer += delta
	if _update_timer < 0.1:
		return
	_update_timer = 0.0

	if _world == null or not is_instance_valid(_world):
		_find_world()

	var player := get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player):
		_player_grid = IsoMath.world_to_grid(player.global_position)
		if player.velocity.length_squared() > 1.0:
			_player_facing = player.velocity.angle()

	_update_markers()
	_canvas.queue_redraw()


func _update_markers() -> void:
	_npc_markers.clear()
	_boss_markers.clear()
	_interactable_markers.clear()
	_has_quest_marker = false

	if _world == null:
		return

	for npc in _world.npcs:
		if is_instance_valid(npc):
			var grid := IsoMath.world_to_grid(npc.global_position)
			var quest_status := GameState.quest_marker_for_npc(str(npc.npc_id))
			var marker_color := Color(0.4, 0.7, 1.0)
			if quest_status == "available":
				marker_color = Color("#f0c45d")
			elif quest_status == "ready":
				marker_color = Color("#83e39b")
			_npc_markers.append({"pos": grid, "color": marker_color, "quest": quest_status})

	for mon in _world.monsters:
		if is_instance_valid(mon) and mon.enabled and not mon.defeated:
			var grid := IsoMath.world_to_grid(mon.global_position)
			var is_boss := false
			if "is_boss" in mon:
				is_boss = mon.is_boss
			if is_boss:
				_boss_markers.append({"pos": grid, "color": Color(1.0, 0.3, 0.3)})
			else:
				_npc_markers.append({"pos": grid, "color": Color(0.9, 0.5, 0.2)})

	# Nearby gatherables, lore stones and shrines are shown separately from NPCs.
	for node in get_tree().get_nodes_in_group("interactables"):
		if not is_instance_valid(node) or not node.visible:
			continue
		var grid := IsoMath.world_to_grid(node.global_position)
		var kind := str(node.get("prop_kind")) if "prop_kind" in node else "interactable"
		_interactable_markers.append({"pos": grid, "kind": kind})

	var tracked := GameState.tracked_quest()
	if not tracked.is_empty() and GameState.quest_state(tracked) == "active":
		var definition: Dictionary = ContentDB.get_quest(tracked)
		if str(definition.get("region", "greenward")) == GameState.player_region:
			# Match the HUD compass and world beacon: follow the actual living
			# quest target when one exists, not only its authored spawn centre.
			_quest_marker = IsoMath.world_to_grid(GameState.quest_target_position(tracked))
			_has_quest_marker = true


func _on_draw() -> void:
	if _collapsed:
		return

	var center := Vector2(MAP_SIZE * 0.5, MAP_SIZE * 0.5)
	var player_pos := _player_grid

	# Draw terrain
	for dy in range(-VIEW_RADIUS, VIEW_RADIUS + 1):
		for dx in range(-VIEW_RADIUS, VIEW_RADIUS + 1):
			var grid_pos := player_pos + Vector2(dx, dy)
			var world_pos := IsoMath.grid_to_world(grid_pos.x, grid_pos.y)
			var is_water := false
			if _world != null and is_instance_valid(_world) and _world.has_method("is_water_world"):
				is_water = bool(_world.is_water_world(world_pos))
			var px := center.x + dx * TILE_PX
			var py := center.y + dy * TILE_PX
			# Subtle deterministic terrain variation prevents the map from reading
			# as a flat blank field while keeping the player and markers legible.
			var tile_seed := absi(int(grid_pos.x) * 73856093 ^ int(grid_pos.y) * 19349663)
			var variation := float(tile_seed % 9) * 0.018
			var color := Color(0.075 + variation, 0.13 + variation, 0.085 + variation * 0.55) if not is_water else Color(0.025, 0.105 + variation, 0.19 + variation)
			var tile_rect := Rect2(px - TILE_PX * 0.5, py - TILE_PX * 0.5, TILE_PX, TILE_PX)
			_canvas.draw_rect(tile_rect, color)
			# Highlight shorelines so lakes and rivers have a readable edge.
			if not is_water and _world != null and is_instance_valid(_world) and _world.has_method("is_water_world"):
				var near_water := false
				for water_offset in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
					var adjacent_world := IsoMath.grid_to_world(grid_pos.x + water_offset.x, grid_pos.y + water_offset.y)
					if bool(_world.is_water_world(adjacent_world)):
						near_water = true
						break
				if near_water:
					_canvas.draw_rect(tile_rect, Color(0.30, 0.64, 0.68, 0.45), false, 0.65)

	# Draw POIs
	var region: Dictionary = {}
	if GameState.player_region != "":
		region = ContentDB.get_region(GameState.player_region)
	var pois: Array = region.get("pois", [])
	for poi in pois:
		if typeof(poi) != TYPE_DICTIONARY:
			continue
		var grid: Variant = poi.get("grid", null)
		if typeof(grid) != TYPE_ARRAY or (grid as Array).size() != 2:
			continue
		var g: Array = grid
		var poi_grid := Vector2(float(g[0]), float(g[1]))
		var offset := poi_grid - player_pos
		if abs(offset.x) > VIEW_RADIUS or abs(offset.y) > VIEW_RADIUS:
			continue
		var px := center.x + offset.x * TILE_PX
		var py := center.y + offset.y * TILE_PX
		var poi_type := str(poi.get("type", ""))
		var poi_color := Color("#e7c36b")
		var poi_center := Vector2(px, py)
		match poi_type:
			"boss":
				poi_color = Color("#ff6878")
				_canvas.draw_colored_polygon(PackedVector2Array([poi_center + Vector2(0, -5), poi_center + Vector2(5, 0), poi_center + Vector2(0, 5), poi_center + Vector2(-5, 0)]), poi_color)
			"village":
				poi_color = Color("#f0d27c")
				_canvas.draw_circle(poi_center, 4.0, poi_color)
				_canvas.draw_circle(poi_center, 2.0, Color("#59452d"))
			"ruin", "dungeon":
				poi_color = Color("#bd91f5")
				_canvas.draw_rect(Rect2(poi_center - Vector2(3.5, 3.5), Vector2(7, 7)), poi_color)
			_:
				_canvas.draw_circle(poi_center, 3.0, poi_color)
		_canvas.draw_arc(poi_center, 6.0, 0.0, TAU, 16, Color(poi_color.r, poi_color.g, poi_color.b, 0.55), 1.0)

	# Draw NPCs. Quest givers / turn-ins are larger and use distinct colors,
	# so the player can identify who needs attention without opening the map.
	for marker in _npc_markers:
		var offset: Vector2 = marker.pos - player_pos
		if abs(offset.x) > VIEW_RADIUS or abs(offset.y) > VIEW_RADIUS:
			continue
		var px := center.x + offset.x * TILE_PX
		var py := center.y + offset.y * TILE_PX
		var quest_status := str(marker.get("quest", ""))
		if quest_status == "available" or quest_status == "ready":
			var p := Vector2(px, py)
			_canvas.draw_circle(p, 4.5, Color(marker.color.r, marker.color.g, marker.color.b, 0.22))
			_canvas.draw_colored_polygon(PackedVector2Array([
				p + Vector2(0, -3.5), p + Vector2(3.5, 0),
				p + Vector2(0, 3.5), p + Vector2(-3.5, 0)
			]), marker.color)
		else:
			_canvas.draw_circle(Vector2(px, py), 2.0, marker.color)

	# Draw bosses
	for marker in _boss_markers:
		var offset: Vector2 = marker.pos - player_pos
		if abs(offset.x) > VIEW_RADIUS or abs(offset.y) > VIEW_RADIUS:
			continue
		var px := center.x + offset.x * TILE_PX
		var py := center.y + offset.y * TILE_PX
		_canvas.draw_circle(Vector2(px, py), 3.0, marker.color)
		_canvas.draw_arc(Vector2(px, py), 5.0, 0, TAU, 12, marker.color, 1.0)

	# Exploration objects use a distinct cyan diamond so they are not confused
	# with combatants or quest-giver markers.
	for marker in _interactable_markers:
		var offset: Vector2 = marker.pos - player_pos
		if abs(offset.x) > VIEW_RADIUS or abs(offset.y) > VIEW_RADIUS:
			continue
		var point := center + offset * TILE_PX
		var marker_color := Color("#79e6d5")
		var kind := str(marker.get("kind", ""))
		if kind.contains("crystal"):
			marker_color = Color("#bd91ff")
		elif kind.contains("berry") or kind.contains("herb") or kind.contains("bloom"):
			marker_color = Color("#91e6a2")
		elif kind.contains("shrine"):
			marker_color = Color("#f0d27c")
		_canvas.draw_circle(point, 4.5, Color(marker_color.r, marker_color.g, marker_color.b, 0.18))
		_canvas.draw_colored_polygon(PackedVector2Array([
			point + Vector2(0, -3.2), point + Vector2(3.2, 0),
			point + Vector2(0, 3.2), point + Vector2(-3.2, 0)
		]), marker_color)

	# Draw quest marker. If it is outside the visible radius, pin a clear
	# directional arrow to the nearest map edge instead of making the objective
	# disappear (one of the main causes of players getting lost).
	if _has_quest_marker:
		var offset := _quest_marker - player_pos
		if abs(offset.x) <= VIEW_RADIUS and abs(offset.y) <= VIEW_RADIUS:
			var px := center.x + offset.x * TILE_PX
			var py := center.y + offset.y * TILE_PX
			var marker_center := Vector2(px, py)
			var pulse := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.004)
			_canvas.draw_circle(marker_center, 7.0 + pulse * 3.0, Color(1.0, 0.78, 0.12, 0.10 + pulse * 0.10))
			_canvas.draw_arc(marker_center, 8.0 + pulse * 3.0, 0.0, TAU, 24, Color(1.0, 0.84, 0.25, 0.55 + pulse * 0.30), 1.2)
			var pts := PackedVector2Array([
				Vector2(px, py - 5),
				Vector2(px + 4, py),
				Vector2(px, py + 5),
				Vector2(px - 4, py),
			])
			_canvas.draw_colored_polygon(pts, Color(1.0, 0.90, 0.38))
		else:
			var direction := Vector2(offset.x, offset.y)
			if direction.length_squared() > 0.001:
				direction = direction.normalized()
				var edge_distance := float(VIEW_RADIUS) * TILE_PX - 12.0
				var edge := center + direction * edge_distance
				var side := Vector2(-direction.y, direction.x)
				var tip := edge + direction * 8.0
				var arrow_points := PackedVector2Array([
					tip,
					edge - direction * 7.0 + side * 5.5,
					edge - direction * 7.0 - side * 5.5
				])
				_canvas.draw_circle(edge, 8.0, Color(1.0, 0.78, 0.12, 0.16))
				_canvas.draw_colored_polygon(arrow_points, Color(1.0, 0.82, 0.16))

	# Draw player at the center. The bright triangular pointer shows facing;
	# the surrounding ring makes the current location easy to spot at a glance.
	var player_color := Color(0.3, 0.8, 1.0)
	_canvas.draw_circle(center, 6.0, Color(player_color.r, player_color.g, player_color.b, 0.18))
	_canvas.draw_circle(center, 3.5, player_color)
	var facing := Vector2(cos(_player_facing), sin(_player_facing))
	var facing_side := Vector2(-facing.y, facing.x)
	var player_tip := center + facing * 10.0
	var player_points := PackedVector2Array([
		player_tip,
		center - facing * 4.0 + facing_side * 4.0,
		center - facing * 4.0 - facing_side * 4.0
	])
	_canvas.draw_colored_polygon(player_points, Color.WHITE)

	# Compact compass and legend make symbols understandable instead of
	# leaving the player to guess what each dot represents.
	var font := ThemeDB.fallback_font
	_canvas.draw_string(font, Vector2(center.x - 3.0, 12.0), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#dce8df"))
	_canvas.draw_line(center + Vector2(0, -15), center + Vector2(0, -9), Color("#dce8df", 0.8), 1.0)
	_canvas.draw_rect(Rect2(3, MAP_SIZE - 19, MAP_SIZE - 6, 16), Color(0.015, 0.025, 0.04, 0.88))
	_canvas.draw_circle(Vector2(10, MAP_SIZE - 11), 2.5, Color("#69c9ed"))
	_canvas.draw_string(font, Vector2(15, MAP_SIZE - 8), "You", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#e5edf5"))
	_canvas.draw_circle(Vector2(43, MAP_SIZE - 11), 2.5, Color("#83e39b"))
	_canvas.draw_string(font, Vector2(48, MAP_SIZE - 8), "NPC", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#e5edf5"))
	_canvas.draw_colored_polygon(PackedVector2Array([Vector2(78, MAP_SIZE - 14), Vector2(81, MAP_SIZE - 11), Vector2(78, MAP_SIZE - 8), Vector2(75, MAP_SIZE - 11)]), Color("#ff6878"))
	_canvas.draw_string(font, Vector2(84, MAP_SIZE - 8), "Boss", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#e5edf5"))
	_canvas.draw_circle(Vector2(117, MAP_SIZE - 11), 2.5, Color("#f0d27c"))
	_canvas.draw_string(font, Vector2(122, MAP_SIZE - 8), "POI", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#e5edf5"))

	# Border
	_canvas.draw_rect(Rect2(0, 0, MAP_SIZE, MAP_SIZE), Color(0.42, 0.58, 0.66, 0.9), false, 1.0)


func _toggle_collapse() -> void:
	_collapsed = not _collapsed
	if _collapsed:
		custom_minimum_size = Vector2(60, 24)
		size = Vector2(60, 24)
		_canvas.visible = false
		_expand_button.visible = false
		_collapse_button.text = "+"
	else:
		custom_minimum_size = Vector2(MAP_SIZE, MAP_SIZE)
		size = Vector2(MAP_SIZE, MAP_SIZE)
		_canvas.visible = true
		_expand_button.visible = true
		_collapse_button.text = "-"
	_find_world()


func _request_full_map() -> void:
	var tree := get_tree()
	if tree:
		var game_screen = tree.get_first_node_in_group("game_screen")
		if game_screen and game_screen.has_method("open_screen"):
			game_screen.open_screen("map")