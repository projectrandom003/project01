class_name GameRuntimeComponent
extends Node
## Owns low-frequency world-info HUD refresh and suspended-world recovery.

var screen: GameScreen
var _hud_accumulator: float = 0.0


func bind(owner_screen: GameScreen) -> void:
	screen = owner_screen


func tick(delta: float) -> void:
	if screen == null:
		return
	_hud_accumulator += delta
	if _hud_accumulator < 0.2:
		return
	_hud_accumulator = 0.0
	if screen.world == null or not is_instance_valid(screen.world):
		return
	if screen.hud != null:
		var area_name := str(screen.world.call("current_area_name")) if screen.world.has_method("current_area_name") else screen.current_region_id.capitalize()
		var phase := str(screen.world.call("day_phase")) if screen.world.has_method("day_phase") else "day"
		screen.hud.set_world_info(area_name, phase)
	# Safety net: recover from a suspended state after all blocking UI is gone.
	if screen.active_combat != null and not is_instance_valid(screen.active_combat):
		screen.active_combat = null
	if screen.active_overlay != null and not is_instance_valid(screen.active_overlay):
		screen.active_overlay = null
	if screen.world.process_mode == Node.PROCESS_MODE_DISABLED and not screen._is_busy():
		screen._set_world_active(true)
