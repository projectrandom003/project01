class_name GameScreen
extends Node
## Top-level controller for the playable slice.
##
## It owns the world and the UI layers, and is the only place that decides when
## the world is allowed to simulate. World content talks through EventBus; the
## HUD emits intent. That keeps NPCs, monsters, combat and menus decoupled.

signal exit_to_menu

const GREENWARD_WORLD_SCENE: PackedScene = preload("res://scenes/world/greenward_world.tscn")
const GAME_UI_SCENE: PackedScene = preload("res://scenes/ui/game_ui.tscn")
const COMBAT_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/combat_screen.tscn")
const GACHA_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/gacha_screen.tscn")
const COLLECTION_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/collection_screen.tscn")
const INVENTORY_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/inventory_screen.tscn")
const QUEST_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/quest_screen.tscn")
const MAP_SCREEN_SCENE: PackedScene = preload("res://scenes/ui/map_screen.tscn")
const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/pause_menu.tscn")

var world: GreenwardWorld
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
	if world != null and is_instance_valid(world) and world.player != null:
		GameState.set_region_position(current_region_id, world.player.position)
		GameState.set_player_position(world.player.position)
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
		hud.set_world_info(world.current_area_name(), world.day_phase())
	# Safety net: recover from any stuck suspended state.
	if active_combat != null and not is_instance_valid(active_combat):
		active_combat = null
	if active_overlay != null and not is_instance_valid(active_overlay):
		active_overlay = null
	if world.process_mode == Node.PROCESS_MODE_DISABLED and not _is_busy():
		_set_world_active(true)


func _unhandled_input(event: InputEvent) -> void:
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
	elif event.is_action_pressed("open_inventory"):
		open_screen("inventory")
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

func _build_world(region_id: String = "greenward", entry_point: String = "") -> void:
	# Defensive fallback for an unknown / empty saved region id.
	var rid := region_id
	if rid.is_empty() or not ContentDB.regions.has(rid):
		rid = "greenward"
	current_region_id = rid
	world = GREENWARD_WORLD_SCENE.instantiate() as GreenwardWorld
	world.region_id = rid
	world.entry_point = entry_point
	world.name = "World_" + rid
	add_child(world)


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
	if world == null or not is_instance_valid(world) or world.player == null:
		return

	# Validate with a pure RegionGraph built from the shipped content.
	var graph := RegionGraph.new(ContentDB.regions)
	if not graph.has_region(target_region_id):
		EventBus.toast_requested.emit("Unknown destination: " + target_region_id)
		return
	var conn_id := ""
	for entry in graph.connections_from(current_region_id):
		if typeof(entry) == TYPE_DICTIONARY and str(entry.get("to", "")) == target_region_id:
			conn_id = str(entry.get("id", ""))
			break
	if conn_id.is_empty():
		EventBus.toast_requested.emit("No route to " + graph.region_name(target_region_id))
		return
	var resolved := graph.resolve_transition(current_region_id, conn_id)
	if not bool(resolved.get("valid", false)):
		EventBus.toast_requested.emit("Route unavailable: " + str(resolved.get("error", "")))
		return

	_changing_region = true
	# Remember where the player stood in the CURRENT region, then switch.
	GameState.set_region_position(current_region_id, world.player.position)
	GameState.set_player_region(target_region_id)
	var old_world := world
	world = null
	old_world.queue_free()
	_build_world(target_region_id, entry_point)
	_set_world_active(true)
	EventBus.toast_requested.emit("Arrived in " + graph.region_name(target_region_id))
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
	if world.player != null and is_instance_valid(world.player):
		world.player.input_enabled = active
	TouchInput.release()


func _interact() -> void:
	if world == null or world.player == null:
		return
	if not world.player.input_enabled:
		return
	world.player.try_interact()


func _switch_avatar() -> void:
	if world == null or world.player == null:
		return
	if not world.player.input_enabled:
		return
	world.player.cycle_avatar()


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
	if world != null and is_instance_valid(world) and world.player != null:
		GameState.set_region_position(current_region_id, world.player.position)
		GameState.set_player_position(world.player.position)
	GameState.save_now()
	TouchInput.release()
	exit_to_menu.emit()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _reset_journey() -> void:
	GameState.reset_progress()
	get_tree().reload_current_scene()
