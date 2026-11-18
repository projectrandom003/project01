class_name GameScreen
extends Node
## Top-level controller for the playable slice.
##
## It owns the world and the UI layers, and is the only place that decides when
## the world is allowed to simulate. World content talks through EventBus; the
## HUD emits intent. That keeps NPCs, monsters, combat and menus decoupled.

signal exit_to_menu

var world: Node2D
var world_host: Node2D
var world_session: GameWorldSessionComponent
var overlay_router: GameOverlayRouterComponent
var combat_router: GameCombatRouterComponent
var input_router: GameInputRouterComponent
var runtime_component: GameRuntimeComponent
var quest_navigation_component: GameQuestNavigationComponent
var ui_layer: CanvasLayer
var hud: HUD
var dialogue: DialogueBox

## Single shared quest navigation resolver owned by GameScreen and injected into
## HUD (and later consumers). Do not instantiate separate resolvers per consumer.
var quest_resolver: QuestNavigationResolver

var active_overlay: OverlayScreen = null
var active_combat: CombatScreen = null

var current_region_id: String = "greenward"


func _ready() -> void:
	add_to_group("game_screen")
	world_host = get_node_or_null("WorldHost") as Node2D
	world_session = get_node_or_null("WorldSession") as GameWorldSessionComponent
	runtime_component = get_node_or_null("Runtime") as GameRuntimeComponent
	quest_navigation_component = get_node_or_null("QuestNavigation") as GameQuestNavigationComponent
	quest_resolver = quest_navigation_component.resolver if quest_navigation_component != null else null
	overlay_router = get_node_or_null("OverlayRouter") as GameOverlayRouterComponent
	combat_router = get_node_or_null("CombatRouter") as GameCombatRouterComponent
	input_router = get_node_or_null("InputRouter") as GameInputRouterComponent
	if world_host == null or world_session == null or runtime_component == null or quest_navigation_component == null or quest_resolver == null or overlay_router == null or combat_router == null or input_router == null:
		push_error("GameScreen scene is missing a required authored composition child")
		return
	runtime_component.bind(self)
	_build_world(GameState.session_domain.player_region, "")
	AudioDirector.play_exploration_theme()
	_build_ui()
	overlay_router.overlay_closed.connect(_on_overlay_closed)
	overlay_router.main_menu_requested.connect(_return_to_title)
	overlay_router.reset_requested.connect(_reset_journey)
	overlay_router.navigate_requested.connect(_on_pause_navigation)
	combat_router.combat_closed.connect(_on_combat_closed)
	input_router.bind(self)
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
	if world_session != null:
		world_session.persist_current_world_state()
	TouchInput.release()
	if EventBus.encounter_requested.is_connected(_on_encounter_requested):
		EventBus.encounter_requested.disconnect(_on_encounter_requested)
	if EventBus.dialogue_requested.is_connected(_on_dialogue_requested):
		EventBus.dialogue_requested.disconnect(_on_dialogue_requested)
	if EventBus.shop_requested.is_connected(_on_shop_requested):
		EventBus.shop_requested.disconnect(_on_shop_requested)
	if EventBus.region_change_requested.is_connected(_on_region_change_requested):
		EventBus.region_change_requested.disconnect(_on_region_change_requested)


func _process(delta: float) -> void:
	if runtime_component != null:
		runtime_component.tick(delta)


func _unhandled_input(event: InputEvent) -> void:
	if input_router != null:
		input_router.handle_unhandled_input(event)

func _notification(what: int) -> void:
	if input_router != null:
		input_router.handle_notification(what)

func _build_world(region_id: String = "", entry_point: String = "") -> void:
	world = world_session.build_world(region_id, entry_point) if world_session != null else null
	current_region_id = world_session.current_region_id if world_session != null else "greenward"


func _resolve_region_id(region_id: String) -> String:
	return world_session.resolve_region_id(region_id) if world_session != null else region_id


func _build_ui() -> void:
	ui_layer = get_node_or_null("UI") as CanvasLayer
	if ui_layer == null:
		push_error("GameScreen requires its authored UI CanvasLayer")
		return
	hud = ui_layer.get_node_or_null("HUD") as HUD
	dialogue = ui_layer.get_node_or_null("Dialogue") as DialogueBox
	if hud == null or dialogue == null:
		push_error("GameScreen UI scene is missing HUD or Dialogue")
		return
	hud.set_quest_resolver(quest_resolver)
	dialogue.closed.connect(_on_dialogue_closed)
	hud.screen_requested.connect(open_screen)
	hud.menu_requested.connect(_open_pause_menu)
	hud.return_to_title_requested.connect(_return_to_title)
	hud.interact_requested.connect(_interact)
	hud.switch_avatar_requested.connect(_switch_avatar)

func _connect_signals() -> void:
	EventBus.encounter_requested.connect(_on_encounter_requested)
	EventBus.dialogue_requested.connect(_on_dialogue_requested)
	EventBus.shop_requested.connect(_on_shop_requested)
	if not EventBus.region_change_requested.is_connected(_on_region_change_requested):
		EventBus.region_change_requested.connect(_on_region_change_requested)


# ----------------------------------------------------------- region transitions

func _on_region_change_requested(target_region_id: String, entry_point: String) -> void:
	if world_session == null:
		return
	var result := world_session.transition_to(target_region_id, entry_point)
	if not bool(result.get("ok", false)):
		EventBus.toast_requested.emit(str(result.get("reason", "Could not travel there.")))
		return
	world = world_session.world
	current_region_id = world_session.current_region_id
	_set_world_active(true)
	EventBus.toast_requested.emit("Arrived in " + str(result.get("display_name", current_region_id)))


# ------------------------------------------------------------------- helpers

func _is_busy() -> bool:
	return input_router.is_busy() if input_router != null else false

func _set_world_active(active: bool) -> void:
	if world_session != null:
		world_session.set_world_active(active)


func _interact() -> void:
	if input_router != null:
		input_router.interact()

func _switch_avatar() -> void:
	if input_router != null:
		input_router.switch_avatar()

func _on_dialogue_requested(dialogue_id: String) -> void:
	if _is_busy():
		return
	_set_world_active(false)
	dialogue.open(dialogue_id)


func _on_dialogue_closed(_dialogue_id: String) -> void:
	if not _is_busy():
		_set_world_active(true)


func _on_shop_requested() -> void:
	# DialogueBox emits while the conversation is closing; defer until its
	# visibility flag is cleared so the single-overlay lock is released.
	call_deferred("open_screen", "shop")


# -------------------------------------------------------------------- combat

func _on_encounter_requested(group_id: String, source: Node) -> void:
	if _is_busy() or combat_router == null:
		# The monster already marked itself engaged; let it return to roaming.
		if source != null and is_instance_valid(source) and "engaged" in source:
			source.engaged = false
		return
	if not combat_router.start_encounter(group_id):
		return
	active_combat = combat_router.active_combat
	_set_world_active(false)


func _on_combat_closed() -> void:
	active_combat = null
	if not _is_busy():
		_set_world_active(true)


# ------------------------------------------------------------------- screens

func open_screen(screen_id: String) -> void:
	if _is_busy() or active_combat != null or overlay_router == null:
		return
	if not overlay_router.open_screen(screen_id):
		return
	active_overlay = overlay_router.active_overlay
	_set_world_active(false)
	EventBus.screen_changed.emit(screen_id)


func _on_overlay_closed() -> void:
	active_overlay = null
	EventBus.screen_changed.emit("world")
	if not _is_busy():
		_set_world_active(true)


func _open_pause_menu() -> void:
	if _is_busy() or active_combat != null or overlay_router == null:
		return
	if not overlay_router.open_pause_menu():
		return
	active_overlay = overlay_router.active_overlay
	_set_world_active(false)
	EventBus.screen_changed.emit("pause")


func _on_pause_navigation(screen_id: String) -> void:
	# Close the pause overlay first; defer opening the destination until the
	# closed signal has released GameScreen's single-overlay lock.
	if active_overlay != null and is_instance_valid(active_overlay):
		active_overlay.close_screen()
	call_deferred("open_screen", screen_id)


func _return_to_title() -> void:
	_persist_current_world_state()
	TouchInput.release()
	exit_to_menu.emit()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


## Keep the in-memory world and disk save in sync before leaving gameplay.
func _persist_current_world_state() -> void:
	if world_session != null:
		world_session.persist_current_world_state()


func _reset_journey() -> void:
	GameState.reset_progress()
	get_tree().reload_current_scene()
