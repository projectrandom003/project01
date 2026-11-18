class_name MinimapMarkerComponent
extends Node
## Owns live world-marker collection for the minimap. Rendering remains in Minimap.

var active_world: Node = null
var npc_markers: Array = []
var boss_markers: Array = []
var interactable_markers: Array = []
var quest_marker: Vector2 = Vector2.ZERO
var has_quest_marker: bool = false
var minimap: Minimap
var _update_timer: float = 0.0


func bind(owner: Minimap) -> void:
	minimap = owner


func _process(delta: float) -> void:
	if minimap == null or minimap._collapsed:
		return
	_update_timer += delta
	if _update_timer < 0.1:
		return
	_update_timer = 0.0
	if minimap._world == null or not is_instance_valid(minimap._world):
		minimap._find_world()
	var player := get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player):
		minimap._player_grid = IsoMath.world_to_grid(player.global_position)
		if "velocity" in player and player.velocity.length_squared() > 1.0:
			minimap._player_facing = player.velocity.angle()
	minimap._update_markers()
	if minimap._canvas != null:
		minimap._canvas.queue_redraw()


## NPCs and roaming monsters have dedicated marker layers; avoid drawing them
## again as generic gatherables from the shared interactables group.
static func should_render_interactable_marker(node: Node) -> bool:
	return node != null and is_instance_valid(node) and not node.is_in_group("world_minimap_npcs") and not node.is_in_group("world_minimap_monsters")


func update_markers(owner: Minimap, current_world: Node, resolver: QuestNavigationResolver) -> void:
	active_world = current_world
	npc_markers.clear()
	boss_markers.clear()
	interactable_markers.clear()
	has_quest_marker = false
	quest_marker = Vector2.ZERO

	if active_world == null or not is_instance_valid(active_world):
		return

	# Worlds publish marker-capable nodes through shared scene-tree groups.
	# This keeps the minimap independent of world-specific array properties.
	for npc in owner.get_tree().get_nodes_in_group("world_minimap_npcs"):
		if not active_world.is_ancestor_of(npc):
			continue
		if is_instance_valid(npc):
			var grid := IsoMath.world_to_grid(npc.global_position)
			var quest_status := GameState.quest_domain.quest_marker_for_npc(str(npc.npc_id))
			var marker_color := Color(0.4, 0.7, 1.0)
			if quest_status == "available":
				marker_color = Color("#f0c45d")
			elif quest_status == "ready":
				marker_color = Color("#83e39b")
			npc_markers.append({"pos": grid, "color": marker_color, "quest": quest_status})

	for monster in owner.get_tree().get_nodes_in_group("world_minimap_monsters"):
		if not active_world.is_ancestor_of(monster):
			continue
		if is_instance_valid(monster) and monster.enabled and not monster.defeated:
			var grid := IsoMath.world_to_grid(monster.global_position)
			var is_boss := false
			if "is_boss" in monster:
				is_boss = monster.is_boss
			if is_boss:
				boss_markers.append({"pos": grid, "color": Color(1.0, 0.3, 0.3)})
			else:
				npc_markers.append({"pos": grid, "color": Color(0.9, 0.5, 0.2)})

	# Nearby gatherables, lore stones and shrines are separate from NPCs.
	for node in owner.get_tree().get_nodes_in_group("interactables"):
		if not is_instance_valid(node) or not active_world.is_ancestor_of(node):
			continue
		if not should_render_interactable_marker(node) or not node.visible:
			continue
		var grid := IsoMath.world_to_grid(node.global_position)
		var kind := str(node.get("prop_kind")) if "prop_kind" in node else "interactable"
		interactable_markers.append({"pos": grid, "kind": kind})

	var tracked := GameState.quest_domain.tracked_quest()
	if not tracked.is_empty() and GameState.quest_domain.quest_state(tracked) == "active":
		var active_resolver := resolver
		if active_resolver == null:
			var game_screen := owner.get_tree().get_first_node_in_group("game_screen")
			if game_screen != null and game_screen.get("quest_resolver") is QuestNavigationResolver:
				active_resolver = game_screen.get("quest_resolver") as QuestNavigationResolver
		if active_resolver != null:
			var player := owner.get_tree().get_first_node_in_group("player")
			var player_pos: Vector2 = player.global_position if player is Node2D else Vector2.ZERO
			var resolved := active_resolver.get_resolved_target(GameState.session_domain.player_region, player_pos)
			# Never draw a false local arrow for another region or an invalid target.
			if bool(resolved.get("valid", false)) and bool(resolved.get("same_frame", false)):
				var target_pos: Variant = resolved.get("target_local_pos", null)
				if typeof(target_pos) == TYPE_VECTOR2:
					quest_marker = IsoMath.world_to_grid(target_pos as Vector2)
					has_quest_marker = true

