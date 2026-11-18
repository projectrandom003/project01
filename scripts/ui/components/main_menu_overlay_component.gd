class_name MainMenuOverlayComponent
extends Node
## Owns overlay instantiation and lightweight feature panels for hub shortcuts.

const SUMMON_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/gacha_screen.tscn")
const INVENTORY_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/inventory_screen.tscn")
const WORLD_MAP_SCENE: PackedScene = preload("res://scenes/ui/map_screen.tscn")
const DAILY_REWARDS_SCENE: PackedScene = preload("res://scenes/ui/components/daily_rewards_panel.tscn")
var menu: Control

func bind(owner: Control) -> void:
	menu = owner

func open_summon() -> void:
	open_scene(SUMMON_SCREEN_SCENE, "SummonOverlay")

func open_inventory() -> void:
	open_scene(INVENTORY_SCREEN_SCENE, "InventoryOverlay")

func open_world_map() -> void:
	open_scene(WORLD_MAP_SCENE, "WorldMapOverlay")

func open_daily_rewards() -> void:
	open_scene(DAILY_REWARDS_SCENE, "DailyRewardsOverlay")

func open_settings() -> void:
	open_path("res://scenes/ui/settings_screen.tscn", "SettingsOverlay")

func open_characters() -> void:
	open_path("res://scenes/ui/collection_screen.tscn", "CharactersOverlay")

func open_scene(scene: PackedScene, overlay_name: String) -> void:
	if menu.has_node(overlay_name):
		return
	var screen := scene.instantiate() as Control
	if screen == null:
		push_error("[MainMenuOverlay] Could not instantiate %s." % overlay_name)
		return
	screen.name = overlay_name
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.z_index = 20
	menu.add_child(screen)
	if screen.has_signal("closed"):
		screen.closed.connect(func() -> void:
			if is_instance_valid(screen):
				screen.queue_free()
		)

func open_path(path: String, overlay_name: String) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		show_notice(overlay_name.replace("Overlay", ""), "This section is currently unavailable.")
		return
	open_scene(packed, overlay_name)

func show_notice(title_text: String, message: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = title_text
	dialog.dialog_text = message
	menu.add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()
