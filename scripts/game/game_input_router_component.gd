class_name GameInputRouterComponent
extends Node
## Owns gameplay input routing, busy-state checks and player interaction commands.

var screen: GameScreen


func bind(owner_screen: GameScreen) -> void:
	screen = owner_screen


func is_busy() -> bool:
	return (
		(screen.dialogue != null and screen.dialogue.visible)
		or screen.active_combat != null
		or screen.active_overlay != null
	)


func handle_unhandled_input(event: InputEvent) -> void:
	if screen == null:
		return
	if event.is_action_pressed("open_inventory"):
		if screen.active_combat != null or (screen.dialogue != null and screen.dialogue.visible):
			return
		if screen.active_overlay != null:
			if is_instance_valid(screen.active_overlay) and screen.active_overlay is InventoryScreen:
				screen.active_overlay.close_screen()
			return
		screen.open_screen("inventory")
		screen.get_viewport().set_input_as_handled()
		return

	if is_busy():
		return
	if event.is_action_pressed("interact"):
		interact()
		screen.get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_menu"):
		screen._open_pause_menu()
		screen.get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_gacha"):
		screen.open_screen("gacha")
		screen.get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_collection"):
		screen.open_screen("collection")
		screen.get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_quests"):
		screen.open_screen("quests")
		screen.get_viewport().set_input_as_handled()


func handle_notification(what: int) -> void:
	if screen == null:
		return
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_busy():
			return
		screen._open_pause_menu()


func interact() -> void:
	if screen == null or screen.world == null:
		return
	var player = screen.world.get("player") if "player" in screen.world else null
	if player == null or not player.input_enabled:
		return
	player.try_interact()


func switch_avatar() -> void:
	if screen == null or screen.world == null:
		return
	var player = screen.world.get("player") if "player" in screen.world else null
	if player == null or not player.input_enabled:
		return
	if player.has_method("cycle_avatar"):
		player.cycle_avatar()
