class_name CombatInputComponent
extends Node
## Owns Escape handling for manual target cancellation and retreat confirmation.

var screen: CombatScreen

func bind(owner_screen: CombatScreen) -> void:
	screen = owner_screen

func handle_unhandled_input(event: InputEvent) -> void:
	if screen == null or not event.is_action_pressed("ui_cancel"):
		return
	if screen._targeting_component != null and screen._targeting_component.is_targeting():
		screen._cancel_targeting()
	elif screen._result_layer == null and screen._confirm_layer == null and not screen._resolved:
		screen._confirm_retreat()
	screen.get_viewport().set_input_as_handled()
