class_name GameCombatRouterComponent
extends Node
## Owns battle-screen instantiation and teardown; combat rules remain in CombatEngine.

signal combat_closed

@export var combat_root_path: NodePath = NodePath("../UI/Combat")

const COMBAT_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/combat_screen.tscn")

var combat_root: Control
var active_combat: CombatScreen


func _ready() -> void:
	combat_root = get_node_or_null(combat_root_path) as Control


func start_encounter(group_id: String) -> bool:
	if group_id.is_empty() or (active_combat != null and is_instance_valid(active_combat)):
		return false
	if combat_root == null:
		combat_root = get_node_or_null(combat_root_path) as Control
	if combat_root == null:
		push_error("[GameCombatRouter] Combat root is missing.")
		return false
	var combat := COMBAT_SCREEN_SCENE.instantiate() as CombatScreen
	if combat == null:
		push_error("[GameCombatRouter] Combat scene failed to instantiate.")
		return false
	combat.name = "Battle"
	combat.group_id = group_id
	active_combat = combat
	combat.closed.connect(_on_combat_closed)
	combat_root.add_child(combat)
	return true


func _on_combat_closed() -> void:
	active_combat = null
	TouchInput.release()
	combat_closed.emit()


func close_active() -> void:
	if active_combat != null and is_instance_valid(active_combat):
		active_combat.close_screen()
