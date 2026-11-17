class_name GameOverlayRouterComponent
extends Node
## Owns creation and lifecycle of modal screens. Gameplay remains suspended by the session owner.

signal overlay_closed
signal main_menu_requested
signal reset_requested
signal navigate_requested(screen_id: String)

@export var overlay_root_path: NodePath = NodePath("../UI/Overlays")

const SCREEN_SCENES := {
	"gacha": preload("res://scenes/ui/gacha_screen.tscn"),
	"collection": preload("res://scenes/ui/collection_screen.tscn"),
	"inventory": preload("res://scenes/ui/inventory_screen.tscn"),
	"quests": preload("res://scenes/ui/quest_screen.tscn"),
	"map": preload("res://scenes/ui/map_screen.tscn"),
	"shop": preload("res://scenes/ui/shop_screen.tscn"),
}
const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/pause_menu.tscn")

var overlay_root: Control
var active_overlay: OverlayScreen


func _ready() -> void:
	overlay_root = get_node_or_null(overlay_root_path) as Control


func open_screen(screen_id: String) -> bool:
	if active_overlay != null and is_instance_valid(active_overlay):
		return false
	var scene: PackedScene = SCREEN_SCENES.get(screen_id)
	if scene == null and screen_id == "settings" and ResourceLoader.exists("res://scenes/ui/settings_screen.tscn"):
		scene = load("res://scenes/ui/settings_screen.tscn") as PackedScene
	if scene == null:
		push_warning("[GameOverlayRouter] Unknown or unavailable screen: " + screen_id)
		return false
	var screen := scene.instantiate() as OverlayScreen
	if screen == null:
		push_error("[GameOverlayRouter] Screen scene is not an OverlayScreen: " + screen_id)
		return false
	return _attach_overlay(screen, "Overlay_" + screen_id)


func open_pause_menu() -> bool:
	if active_overlay != null and is_instance_valid(active_overlay):
		return false
	var menu := PAUSE_MENU_SCENE.instantiate() as PauseMenu
	if menu == null:
		return false
	menu.main_menu_requested.connect(func() -> void: main_menu_requested.emit())
	menu.reset_requested.connect(func() -> void: reset_requested.emit())
	menu.navigate_requested.connect(func(screen_id: String) -> void:
		menu.close_screen()
		navigate_requested.emit(screen_id)
	)
	return _attach_overlay(menu, "PauseMenu")


func _attach_overlay(screen: OverlayScreen, node_name: String) -> bool:
	if overlay_root == null:
		overlay_root = get_node_or_null(overlay_root_path) as Control
	if overlay_root == null:
		push_error("[GameOverlayRouter] Overlay root is missing.")
		screen.free()
		return false
	active_overlay = screen
	screen.name = node_name
	screen.closed.connect(_on_overlay_closed)
	overlay_root.add_child(screen)
	return true


func _on_overlay_closed() -> void:
	active_overlay = null
	overlay_closed.emit()


func close_active() -> void:
	if active_overlay != null and is_instance_valid(active_overlay):
		active_overlay.close_screen()
