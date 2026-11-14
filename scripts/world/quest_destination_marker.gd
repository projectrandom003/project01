class_name QuestDestinationMarker
extends Node2D
## World-space quest beacon. Its visual hierarchy is authored in the scene;
## this script only resolves the live target and animates existing nodes.

var _time := 0.0
var _distance := INF

var _ground_halo: Polygon2D
var _outer_ring: Line2D
var _secondary_ring: Line2D
var _beacon_glow: Line2D
var _beacon_core: Line2D
var _target_glyph: Polygon2D
var _target_core: Polygon2D
var _sparks: Array[Polygon2D] = []


func _ready() -> void:
	_resolve_nodes()
	z_index = 35
	set_process(true)


func _resolve_nodes() -> void:
	_ground_halo = get_node_or_null("GroundHalo") as Polygon2D
	_outer_ring = get_node_or_null("OuterRing") as Line2D
	_secondary_ring = get_node_or_null("SecondaryRing") as Line2D
	_beacon_glow = get_node_or_null("BeaconGlow") as Line2D
	_beacon_core = get_node_or_null("BeaconCore") as Line2D
	_target_glyph = get_node_or_null("TargetGlyph") as Polygon2D
	_target_core = get_node_or_null("TargetCore") as Polygon2D
	_sparks.clear()
	var sparks_root := get_node_or_null("Sparks")
	if sparks_root != null:
		for child in sparks_root.get_children():
			if child is Polygon2D:
				_sparks.append(child as Polygon2D)


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
	_animate_nodes()


func _animate_nodes() -> void:
	if _ground_halo == null or _outer_ring == null or _secondary_ring == null or _beacon_glow == null or _beacon_core == null or _target_glyph == null or _target_core == null:
		return
	var proximity := 1.0 - clampf(_distance / 420.0, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(_time * (2.2 + proximity * 2.5))
	var strength := 0.18 + proximity * 0.72
	var color := Color("#7fe3e0").lerp(Color("#e4fff0"), proximity * 0.72)
	var ring_radius := 18.0 + pulse * 5.0 + proximity * 9.0

	_ground_halo.color = Color(color.r, color.g, color.b, strength * 0.07)
	_outer_ring.default_color = Color(color.r, color.g, color.b, strength * 0.72)
	_outer_ring.width = 2.0 + proximity
	_outer_ring.scale = Vector2.ONE * (ring_radius / 18.0)
	_secondary_ring.default_color = Color(color.r, color.g, color.b, strength * 0.28)
	_secondary_ring.scale = Vector2.ONE * ((ring_radius + 7.0 + pulse * 2.0) / 26.0)

	_beacon_glow.default_color = Color(color.r, color.g, color.b, strength * 0.20)
	_beacon_glow.width = 8.0 + proximity * 5.0
	_beacon_core.default_color = Color(color.r, color.g, color.b, strength * 0.72)
	_target_glyph.position.y = -108.0 - pulse * 5.0
	_target_glyph.color = Color(color.r, color.g, color.b, strength)
	_target_glyph.scale = Vector2.ONE * (1.0 + proximity * 0.30)
	_target_core.position.y = _target_glyph.position.y
	_target_core.scale = Vector2.ONE * (1.0 + proximity * 0.8)
	_target_core.color = Color(1.0, 1.0, 1.0, strength)

	for i in _sparks.size():
		var spark := _sparks[i]
		if spark == null:
			continue
		var angle := _time * (0.7 + proximity) + TAU * float(i) / 4.0
		var point := Vector2(cos(angle) * (ring_radius + 5.0), -2.0 + sin(angle) * (ring_radius * 0.55))
		spark.position = point
		spark.scale = Vector2.ONE * (0.8 + proximity * 0.55)
		spark.color = Color(color.r, color.g, color.b, strength * 0.9)
