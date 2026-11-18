class_name GameQuestNavigationComponent
extends Node
## Owns the live-target registry and cached quest-navigation state for one
## gameplay scene. The resolver remains a pure domain service; this Node gives
## its session lifetime an explicit authored owner.

var resolver: QuestNavigationResolver = QuestNavigationResolver.new()


func get_resolved_target(player_region: String = "", player_local_pos: Variant = null,
		graph: Object = null) -> Dictionary:
	return resolver.get_resolved_target(player_region, player_local_pos, graph)


func register_nav_target(target_id: String, provider: Dictionary) -> void:
	resolver.register_nav_target(target_id, provider)


func unregister_nav_target(target_id: String) -> void:
	resolver.unregister_nav_target(target_id)


func clear_registry() -> void:
	resolver.clear_registry()


func invalidate() -> void:
	resolver.invalidate()


func _exit_tree() -> void:
	# Drop scene-owned live providers before their world nodes are destroyed.
	resolver.clear_registry()
