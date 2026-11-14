class_name QuestDestinationMarker
extends Node2D
## World-space quest beacon. Its position follows the exact live quest target
## when a matching monster exists, otherwise the authored objective coordinate.
## The beacon becomes brighter, larger and more animated as the player approaches.

var _time := 0.0
var _distance := INF


func _ready() -> void:
	z_index = 35
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	var quest_id := GameState.tracked_quest()
	if quest_id.is_empty():
		visible = false
		return
	var definition := ContentDB.get_quest(quest_id)
	if definition.is_empty() or GameState.quest_state(quest_id) == "complete":
		visible = false
		return
	var world := get_parent().get_parent()
	if world is GreenwardWorld:
		if str(definition.get("region", "greenward")) != (world as GreenwardWorld).region_id:
			visible = false
			return
	var target_position := GameState.quest_target_position(quest_id)
	var game_screen := get_tree().get_first_node_in_group("game_screen")
	if game_screen != null and game_screen.get("quest_resolver") is QuestNavigationResolver:
		var resolver := game_screen.get("quest_resolver") as QuestNavigationResolver
		var player_node := get_tree().get_first_node_in_group("player")
		var resolver_player_position: Vector2 = player_node.global_position if player_node is Node2D else GameState._find_player_position()
		var resolved := resolver.get_resolved_target((world as GreenwardWorld).region_id if world is GreenwardWorld else GameState.player_region, resolver_player_position)
		if not bool(resolved.get("valid", false)) or not bool(resolved.get("same_frame", false)):
			visible = false
			return
		var resolved_position: Variant = resolved.get("target_local_pos", null)
		if typeof(resolved_position) == TYPE_VECTOR2:
			target_position = resolved_position as Vector2
	global_position = target_position
	var marker_player := get_tree().get_first_node_in_group("player")
	var marker_player_position: Vector2 = marker_player.global_position if marker_player is Node2D else GameState._find_player_position()
	_distance = marker_player_position.distance_to(global_position)
	visible = true
	queue_redraw()


func _draw() -> void:
	var proximity := 1.0 - clampf(_distance / 420.0, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(_time * (2.2 + proximity * 2.5))
	var strength := 0.18 + proximity * 0.72
	var color := Color("#7fe3e0").lerp(Color("#e4fff0"), proximity * 0.72)
	var ring_radius := 18.0 + pulse * 5.0 + proximity * 9.0
	# Soft ground halo and concentric locator rings.
	draw_circle(Vector2(0, -2), ring_radius + 13.0, Color(color.r, color.g, color.b, strength * 0.07))
	draw_arc(Vector2(0, -2), ring_radius, 0.0, TAU, 48, Color(color.r, color.g, color.b, strength * 0.72), 2.0 + proximity)
	draw_arc(Vector2(0, -2), ring_radius + 7.0 + pulse * 2.0, 0.0, TAU, 48, Color(color.r, color.g, color.b, strength * 0.28), 1.2)
	# Vertical beacon, brightest near the objective.
	draw_line(Vector2(0, -10), Vector2(0, -104 - pulse * 8.0), Color(color.r, color.g, color.b, strength * 0.20), 8.0 + proximity * 5.0)
	draw_line(Vector2(0, -12), Vector2(0, -102), Color(color.r, color.g, color.b, strength * 0.72), 1.8)
	# Floating diamond target glyph.
	var y := -108.0 - pulse * 5.0
	var s := 8.0 + proximity * 4.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, y - s), Vector2(s * 0.68, y), Vector2(0, y + s), Vector2(-s * 0.68, y)
	]), Color(color.r, color.g, color.b, strength))
	draw_circle(Vector2(0, y), 2.5 + proximity * 2.0, Color(1.0, 1.0, 1.0, strength))
	# Four orbiting sparks intensify at close range.
	for i in 4:
		var a := _time * (0.7 + proximity) + TAU * float(i) / 4.0
		var point := Vector2(cos(a) * (ring_radius + 5.0), -2.0 + sin(a) * (ring_radius * 0.55))
		draw_circle(point, 1.8 + proximity * 1.5, Color(color.r, color.g, color.b, strength * 0.9))
