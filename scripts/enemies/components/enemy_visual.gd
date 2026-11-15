class_name EnemyVisualComponent
extends Node

signal visual_setup_completed
signal visual_visibility_changed(visible_state: bool)

@export var actor_visual_path: NodePath
@export var name_label_path: NodePath
@export var accent_path: NodePath

var actor_visual: Node = null
var name_label: Label = null
var accent: Node2D = null


func _ready() -> void:
	resolve_nodes()


func resolve_nodes(root: Node = null) -> void:
	var base := root if root != null else get_parent()
	if base == null:
		return
	actor_visual = base.get_node_or_null(actor_visual_path) if not actor_visual_path.is_empty() else base.get_node_or_null("ActorVisual")
	name_label = base.get_node_or_null(name_label_path) as Label if not name_label_path.is_empty() else base.get_node_or_null("NameLabel") as Label
	accent = base.get_node_or_null(accent_path) as Node2D if not accent_path.is_empty() else base.get_node_or_null("Accent") as Node2D


func set_visible_state(value: bool) -> void:
	var p := get_parent()
	if p is CanvasItem:
		(p as CanvasItem).visible = value
	visual_visibility_changed.emit(value)


func emit_setup_completed() -> void:
	visual_setup_completed.emit()
