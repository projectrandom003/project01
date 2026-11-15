class_name GameScreen
extends Node
## Top-level controller for the playable slice.
##
## It owns the world and the UI layers, and is the only place that decides when
## the world is allowed to simulate. World content talks through EventBus; the
## HUD emits intent. That keeps NPCs, monsters, combat and menus decoupled.

signal exit_to_menu

const GREENWARD_WORLD_SCENE: PackedScene = preload("res://scenes/world/greenward_world.tscn")
const CASTLE_ROYAL_GARDENS_SCENE: PackedScene = preload("res://scenes/world/castle_royal_gardens.tscn")
const GAME_UI_SCENE: PackedScene = preload("res://scenes/ui/game_ui.tscn")
const COMBAT_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/combat_screen.tscn")
const GACHA_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/gacha_screen.tscn")
const COLLECTION_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/collection_screen.tscn")
const INVENTORY_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/inventory_screen.tscn")
const QUEST_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/quest_screen.tscn")
const MAP_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/map_screen.tscn")
const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/pause_menu.tscn")

const WORLD_SCENES := {
	"greenward": preload("res://scenes/world/greenward_world.tscn"),
	"moonpetal_hollow": preload("res://scenes/world/greenward_world.tscn"),
	"castle_royal_gardens": preload("res://scenes/world/castle_royal_gardens.tscn"),
}
const DEFAULT_START_REGION := "castle_royal_gardens"

var world: Node2D
var ui_layer: CanvasLayer
var hud: HUD
var dialogue: DialogueBox
var overlay_root: Control
var combat_root: Control

## Single shared quest navigation resolver owned by GameScreen and injected into
## HUD (and later consumers). Do not instantiate separate resolvers per consumer.
var quest_resolver: QuestNavigationResolver = QuestNavigationResolver.new()

var active_overlay: OverlayScreen = null
var active_combat: CombatScreen = null

var current_region_id: String = "greenward"
var _changing_region: bool = false
var _hud_accumulator: float = 0.0


func _ready() -> void:
	add_to_group("game_screen")
	_build_world(GameState.player_region, "")
	_build_ui()
	_connect_signals()
	_set_world_active(true)


func _exit_tree() -> void:
	# Explicit shutdown cleanup BEFORE the RenderingServer is finalized. GDScript
	# static state lives on the script resource, which is freed during global
	# cleanup AFTER the dummy renderer; any ImageTexture still pinned by a static
	# ProceduralArt cache would therefore leak a DummyTexture RID at exit. Drop
	# every cached texture reference now, while the renderer is still alive, so
	# they free cleanly. Caches are lazy, so this is also safe on a region change
	# / return-to-title (textures just regenerate on the next request).
	ProceduralArt.clear_all_caches()
	# ChunkBuilder caches one shared ShaderMaterial (and its detail.gdshader) in a
	# static var. That static reference would likewise outlive the dummy renderer,
	# leaking its DummyMaterial / DummyShader RID; release it at teardown too. It
	# is rebuilt lazily by _detail_material_cached() on the next build.
	ChunkBuilder._detail_material = null
	ChunkBuilder._valid_kind_set = {}
	if world != null and is_instance_valid(world):
		var player = world.get("player") if "player" in world else null
		if player != null:
			GameState.set_region_position(current_region_id, player.position)
			GameState.set_player_position(player.position)
		GameState.save_now()
	TouchInput.release()
	if EventBus.encounter_requested.is_connected(_on_encounter_requested):
		EventBus.encounter_requested.disconnect(_on_encounter_requested)
	if EventBus.dialogue_requested.is_connected(_on_dialogue_requested):
		EventBus.dialogue_requested.disconnect(_on_dialogue_requested)
	if EventBus.region_change_requested.is_connected(_on_region_change_requested):
		EventBus.region_change_requested.disconnect(_on_region_change_requested)


func _process(delta: float) -> void:
	_hud_accumulator += delta
	if _hud_accumulator < 0.2:
		return
	_hud_accumulator = 0.0
	if world == null or not is_instance_valid(world):
		return
	if hud != null:
		var area_name := str(world.call("current_area_name")) if world.has_method("current_area_name") else current_region_id.capitalize()
		var phase := str(world.call("day_phase")) if world.has_method("day_phase") else "day"
		hud.set_world_info(area_name, phase)
	# Safety net: recover from any stuck suspended state.
	if active_combat != null and not is_instance_valid(active_combat):
		active_combat = null
	if active_overlay != null and not is_instance_valid(active_overlay):
		active_overlay = null
	if world.process_mode == Node.PROCESS_MODE_DISABLED and not _is_busy():
		_set_world_active(true)


func _unhandled_input(event: InputEvent) -> void:
	# Toggle inventory even while it is the active overlay (same controller/interface).
	if event.is_action_pressed("open_inventory"):
		if active_combat != null or (dialogue != null and dialogue.visible):
			return
		if active_overlay != null:
			if is_instance_valid(active_overlay) and active_overlay is InventoryScreen:
				active_overlay.close_screen()
			return
		open_screen("inventory")
		get_viewport().set_input_as_handled()
		return

	if _is_busy():
		return
	if event.is_action_pressed("interact"):
		_interact()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_menu"):
		_open_pause_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_gacha"):
		open_screen("gacha")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_collection"):
		open_screen("collection")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_quests"):
		open_screen("quests")
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _is_busy():
			return
		_open_pause_menu()


# --------------------------------------------------------------------- setup

func _build_world(region_id: String = "", entry_point: String = "") -> void:
	var rid := region_id
	if rid.is_empty():
		rid = GameState.active_world_id if not str(GameState.active_world_id).is_empty() else GameState.player_region
	# Normal new journeys start in Castle & Royal Gardens through the real gameplay
	# flow, while preserving existing save-region behavior and Greenward as a
	# separate independently loadable world. Do not override an actual saved world.
	if not GameState.loaded_from_save and rid == "greenward" and entry_point.is_empty():
		rid = DEFAULT_START_REGION
	rid = _resolve_region_id(rid)
	current_region_id = rid
	GameState.set_player_region(rid)
	var scene: PackedScene = WORLD_SCENES.get(rid, GREENWARD_WORLD_SCENE)
	world = scene.instantiate() as Node2D
	if "region_id" in world:
		world.region_id = rid
	if "entry_point" in world:
		world.entry_point = entry_point
	world.name = "World_" + rid
	add_child(world)
	# Persist the resolved active world as soon as it is instantiated so Continue
	# can restore it even if the player exits before the next autosave tick.
	GameState.queue_save()


func _resolve_region_id(region_id: String) -> String:
	var rid := str(region_id)
	if rid.is_empty():
		# Legacy/empty saves default to Greenward; never guess Castle.
		return "greenward" if WORLD_SCENES.has("greenward") else DEFAULT_START_REGION
	if WORLD_SCENES.has(rid):
		return rid
	# Unknown but data-defined regions fall back to Greenward for compatibility.
	if ContentDB.regions.has(rid):
		return "greenward" if WORLD_SCENES.has("greenward") else DEFAULT_START_REGION
	return "greenward" if WORLD_SCENES.has("greenward") else DEFAULT_START_REGION


func _build_ui() -> void:
	# The top-level presentation hierarchy is authored in game_ui.tscn.
	# GameScreen retains orchestration/signals; the editor owns the node layout.
	ui_layer = GAME_UI_SCENE.instantiate() as CanvasLayer
	add_child(ui_layer)
	hud = ui_layer.get_node("HUD") as HUD
	dialogue = ui_layer.get_node("Dialogue") as DialogueBox
	overlay_root = ui_layer.get_node("Overlays") as Control
	combat_root = ui_layer.get_node("Combat") as Control
	if hud != null:
		hud.set_quest_resolver(quest_resolver)
	dialogue.closed.connect(_on_dialogue_closed)

	hud.screen_requested.connect(open_screen)
	hud.menu_requested.connect(_open_pause_menu)
	hud.interact_requested.connect(_interact)
	hud.switch_avatar_requested.connect(_switch_avatar)


func _connect_signals() -> void:
	EventBus.encounter_requested.connect(_on_encounter_requested)
	EventBus.dialogue_requested.connect(_on_dialogue_requested)
	if not EventBus.region_change_requested.is_connected(_on_region_change_requested):
		EventBus.region_change_requested.connect(_on_region_change_requested)


# ----------------------------------------------------------- region transitions

func _on_region_change_requested(target_region_id: String, entry_point: String) -> void:
	if _changing_region:
		return
	if world == null or not is_instance_valid(world):
		return
	var player = world.get("player") if "player" in world else null
	if player == null or not is_instance_valid(player):
		return

	var rid := _resolve_region_id(target_region_id)
	var can_transition := WORLD_SCENES.has(rid)
	var destination_name := rid

	# Validate graph-based routes when region data/connections exist; allow direct
	# node-based scene transitions for registered worlds without graph edges.
	var graph := RegionGraph.new(ContentDB.regions)
	if graph.has_region(current_region_id) and graph.has_region(rid):
		destination_name = graph.region_name(rid)
		for entry in graph.connections_from(current_region_id):
			if typeof(entry) == TYPE_DICTIONARY and str(entry.get("to", "")) == rid:
				can_transition = true
				break
	elif graph.has_region(rid):
		destination_name = graph.region_name(rid)

	if not can_transition:
		EventBus.toast_requested.emit("No route to " + destination_name)
		return

	_changing_region = true
	# Remember where the player stood in the CURRENT region, then switch.
	GameState.set_region_position(current_region_id, player.position)
	GameState.set_player_region(rid)
	GameState.save_now()
	var old_world := world
	world = null
	old_world.queue_free()
	_build_world(rid, entry_point)
	_set_world_active(true)
	GameState.save_now()
	EventBus.toast_requested.emit("Arrived in " + destination_name)
	_changing_region = false


# ------------------------------------------------------------------- helpers

func _is_busy() -> bool:
	return (
		(dialogue != null and dialogue.visible)
		or active_combat != null
		or active_overlay != null
	)


func _set_world_active(active: bool) -> void:
	if world == null or not is_instance_valid(world):
		return
	world.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	var player = world.get("player") if "player" in world else null
	if player != null and is_instance_valid(player):
		player.input_enabled = active
	TouchInput.release()


func _interact() -> void:
	if world == null:
		return
	var player = world.get("player") if "player" in world else null
	if player == null or not player.input_enabled:
		return
	player.try_interact()


func _switch_avatar() -> void:
	if world == null:
		return
	var player = world.get("player") if "player" in world else null
	if player == null or not player.input_enabled:
		return
	if player.has_method("cycle_avatar"):
		player.cycle_avatar()


# ------------------------------------------------------------------ dialogue

func _on_dialogue_requested(dialogue_id: String) -> void:
	if _is_busy():
		return
	_set_world_active(false)
	dialogue.open(dialogue_id)


func _on_dialogue_closed(_dialogue_id: String) -> void:
	if not _is_busy():
		_set_world_active(true)


# -------------------------------------------------------------------- combat

func _on_encounter_requested(group_id: String, source: Node) -> void:
	if _is_busy():
		# The monster already marked itself engaged; let it return to roaming.
		if source != null and is_instance_valid(source) and "engaged" in source:
			source.engaged = false
		return
	if group_id.is_empty():
		return
	_set_world_active(false)
	var combat := COMBAT_SCREEN_SCENE.instantiate() as CombatScreen
	combat.name = "Battle"
	combat.group_id = group_id
	active_combat = combat
	combat.closed.connect(_on_combat_closed)
	combat_root.add_child(combat)


func _on_combat_closed() -> void:
	active_combat = null
	TouchInput.release()
	if not _is_busy():
		_set_world_active(true)


# ------------------------------------------------------------------- screens

func open_screen(screen_id: String) -> void:
	if _is_busy() or active_combat != null:
		return
	var screen_scene: PackedScene
	match screen_id:
		"gacha":
			screen_scene = GACHA_SCREEN_SCENE
		"collection":
			screen_scene = COLLECTION_SCREEN_SCENE
		"inventory":
			screen_scene = INVENTORY_SCREEN_SCENE
		"quests":
			screen_scene = QUEST_SCREEN_SCENE
		"map":
			screen_scene = MAP_SCREEN_SCENE
		"settings":
			if ResourceLoader.exists("res://scenes/ui/settings_screen.tscn"):
				screen_scene = load("res://scenes/ui/settings_screen.tscn") as PackedScene
			else:
				push_warning("[GameScreen] Settings screen not available.")
				return
		_:
			push_warning("[GameScreen] Unknown screen: " + screen_id)
			return
	var screen := screen_scene.instantiate() as OverlayScreen
	active_overlay = screen
	screen.closed.connect(_on_overlay_closed)
	overlay_root.add_child(screen)
	_set_world_active(false)
	EventBus.screen_changed.emit(screen_id)


func _on_overlay_closed() -> void:
	active_overlay = null
	EventBus.screen_changed.emit("world")
	if not _is_busy():
		_set_world_active(true)


func _open_pause_menu() -> void:
	if _is_busy() or active_combat != null:
		return
	var menu := PAUSE_MENU_SCENE.instantiate() as PauseMenu
	active_overlay = menu
	menu.closed.connect(_on_overlay_closed)
	menu.main_menu_requested.connect(_return_to_title)
	menu.reset_requested.connect(_reset_journey)
	menu.navigate_requested.connect(_on_pause_navigation)
	overlay_root.add_child(menu)
	_set_world_active(false)
	EventBus.screen_changed.emit("pause")


func _on_pause_navigation(screen_id: String) -> void:
	# Close the pause overlay first; defer opening the destination until the
	# closed signal has released GameScreen's single-overlay lock.
	if active_overlay != null and is_instance_valid(active_overlay):
		active_overlay.close_screen()
	call_deferred("open_screen", screen_id)


func _return_to_title() -> void:
	if world != null and is_instance_valid(world):
		var player = world.get("player") if "player" in world else null
		if player != null:
			GameState.set_region_position(current_region_id, player.position)
			GameState.set_player_position(player.position)
			if player.has_method("get") and "facing_direction" in player:
				GameState.set_player_facing(player.facing_direction)
	GameState.save_now()
	TouchInput.release()
	exit_to_menu.emit()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _reset_journey() -> void:
	GameState.reset_progress()
	get_tree().reload_current_scene()
