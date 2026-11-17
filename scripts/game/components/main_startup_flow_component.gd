class_name MainStartupFlowComponent
extends Node
## Owns Title -> Loading -> Main Menu transitions and save/new-game decisions.
signal main_menu_ready(menu: MainMenu)
signal quit_requested
const TITLE_SCENE: PackedScene = preload("res://scenes/ui/title_screen.tscn")
const MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const LOADING_SCENE: PackedScene = preload("res://scenes/ui/loading_screen.tscn")
var host: Control
var title: TitleScreen
var loading: LoadingScreen

func bind(owner: Control) -> void:
	host = owner

func begin() -> void:
	title = TITLE_SCENE.instantiate() as TitleScreen
	if title == null:
		push_error("[StartupFlow] Title screen failed to instantiate.")
		return
	title.name = "TitleScreen"
	host.add_child(title)
	title.menu_requested.connect(_on_title_action)
	title.quit_requested.connect(quit_requested.emit)

func _on_title_action(action: String) -> void:
	if action == "new" and SaveService.has_save():
		var confirm := ConfirmationDialog.new()
		confirm.title = "Begin a New Journey?"
		confirm.dialog_text = "This will replace the existing save. Continue?"
		host.add_child(confirm)
		confirm.confirmed.connect(func() -> void:
			_prepare_new_journey()
			_load_menu()
			confirm.queue_free()
		)
		confirm.canceled.connect(confirm.queue_free)
		confirm.popup_centered()
		return
	if action == "new":
		_prepare_new_journey()
	elif action in ["continue", "load"] and SaveService.has_save():
		var data := SaveService.load_save()
		if not data.is_empty():
			GameState._load_from_dict(data)
		GameState.session_domain.loaded_from_save = true
	_load_menu()

func _prepare_new_journey() -> void:
	GameState.reset_progress()
	GameState.session_domain.set_player_region("castle_royal_gardens")
	GameState.session_domain.set_active_world("castle_royal_gardens")
	GameState.session_domain.has_player_position = false
	GameState.session_domain.region_positions.clear()
	GameState.session_domain.loaded_from_save = false
	GameState.save_now()

func _load_menu() -> void:
	if loading != null and is_instance_valid(loading):
		return
	loading = LOADING_SCENE.instantiate() as LoadingScreen
	if loading == null:
		push_error("[StartupFlow] Loading screen failed to instantiate.")
		return
	loading.name = "LoadingScreen"
	loading.target_scene_path = "res://scenes/ui/main_menu.tscn"
	loading.scene_loaded.connect(_on_menu_loaded)
	loading.load_failed.connect(_on_menu_load_failed)
	host.add_child(loading)

func _on_menu_loaded(packed: PackedScene) -> void:
	var menu := packed.instantiate() as MainMenu
	if menu == null:
		_on_menu_load_failed()
		return
	menu.name = "MainMenu"
	if title != null and is_instance_valid(title):
		title.queue_free()
		title = null
	if loading != null and is_instance_valid(loading):
		loading.queue_free()
		loading = null
	host.add_child(menu)
	main_menu_ready.emit(menu)

func _on_menu_load_failed() -> void:
	push_error("[StartupFlow] Main menu resource load failed; using direct scene fallback.")
	if loading != null and is_instance_valid(loading):
		loading.queue_free()
		loading = null
	if title != null and is_instance_valid(title):
		title.queue_free()
		title = null
	var menu := MENU_SCENE.instantiate() as MainMenu
	if menu != null:
		menu.name = "MainMenu"
		host.add_child(menu)
		main_menu_ready.emit(menu)
