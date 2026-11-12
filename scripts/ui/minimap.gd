class_name Minimap
extends Control
## Compact live minimap showing terrain, player, NPCs, bosses and quest markers.

const MAP_SIZE := 160
const TILE_PX := 3.0
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
		return

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
	_has_quest_marker = false

	if _world == null:
		return

	for npc in _world.npcs:
		if is_instance_valid(npc):
			var grid := IsoMath.world_to_grid(npc.global_position)
			_npc_markers.append({"pos": grid, "color": Color(0.4, 0.7, 1.0)})

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

	var tracked := GameState.tracked_quest()
	if not tracked.is_empty() and GameState.quest_state(tracked) == "active":
		_quest_marker = IsoMath.world_to_grid(GameState.quest_destination(tracked))
		_has_quest_marker = true


func _on_draw() -> void:
	if _collapsed or _world == null:
		return

	var center := Vector2(MAP_SIZE * 0.5, MAP_SIZE * 0.5)
	var player_pos := _player_grid

	# Draw terrain
	for dy in range(-VIEW_RADIUS, VIEW_RADIUS + 1):
		for dx in range(-VIEW_RADIUS, VIEW_RADIUS + 1):
			var grid_pos := player_pos + Vector2(dx, dy)
			var world_pos := IsoMath.grid_to_world(grid_pos.x, grid_pos.y)
			var is_water := false
			if _world.has_method("is_water_world"):
				is_water = bool(_world.is_water_world(world_pos))
			var px := center.x + dx * TILE_PX
			var py := center.y + dy * TILE_PX
			var color := Color(0.15, 0.2, 0.12) if not is_water else Color(0.1, 0.2, 0.35)
			_canvas.draw_rect(Rect2(px - TILE_PX * 0.5, py - TILE_PX * 0.5, TILE_PX, TILE_PX), color)

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
		_canvas.draw_circle(Vector2(px, py), 3.0, Color(0.8, 0.8, 0.3))

	# Draw NPCs
	for marker in _npc_markers:
		var offset: Vector2 = marker.pos - player_pos
		if abs(offset.x) > VIEW_RADIUS or abs(offset.y) > VIEW_RADIUS:
			continue
		var px := center.x + offset.x * TILE_PX
		var py := center.y + offset.y * TILE_PX
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

	# Draw quest marker
	if _has_quest_marker:
		var offset := _quest_marker - player_pos
		if abs(offset.x) <= VIEW_RADIUS and abs(offset.y) <= VIEW_RADIUS:
			var px := center.x + offset.x * TILE_PX
			var py := center.y + offset.y * TILE_PX
			var pts := PackedVector2Array([
				Vector2(px, py - 5),
				Vector2(px + 4, py),
				Vector2(px, py + 5),
				Vector2(px - 4, py),
			])
			_canvas.draw_colored_polygon(pts, Color(1.0, 0.85, 0.2))

	# Draw player (center, with facing arrow)
	var player_color := Color(0.3, 0.8, 1.0)
	_canvas.draw_circle(center, 4.0, player_color)
	var arrow_end := center + Vector2(cos(_player_facing), sin(_player_facing)) * 8.0
	_canvas.draw_line(center, arrow_end, Color(1.0, 1.0, 1.0), 2.0)

	# Border
	_canvas.draw_rect(Rect2(0, 0, MAP_SIZE, MAP_SIZE), Color(0.3, 0.3, 0.4, 0.8), false, 1.0)


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