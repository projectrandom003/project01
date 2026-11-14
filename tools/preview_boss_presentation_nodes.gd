extends Control
## Standalone visual preview for the reusable boss presentation nodes.
## No CombatEngine, combatants, or save state are created or modified.

@onready var _rig: Control = $BossPresentationRig
@onready var _status: Label = $Status


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("_play_preview")


func _play_preview() -> void:
	_status.text = "ELDER HOLLOW — MULTI-TARGET WARNING"
	var elder_targets: Array = [
		Vector2(270, 390),
		Vector2(500, 420),
		Vector2(730, 390)
	]
	_rig.call("play_multi_target_strike", elder_targets, "elder_hollow", 0.72)
	await get_tree().create_timer(1.25).timeout
	if not is_inside_tree():
		return

	_status.text = "ELDER HOLLOW — PHASE TRANSITION"
	_rig.call("show_phase_transition", "elder_hollow", 2)
	await get_tree().create_timer(1.75).timeout
	if not is_inside_tree():
		return

	_status.text = "FALLEN MATRON — MULTI-TARGET WARNING"
	var matron_targets: Array = [
		Vector2(340, 410),
		Vector2(650, 410)
	]
	_rig.call("play_multi_target_strike", matron_targets, "fallen_matron", 0.58)
	await get_tree().create_timer(1.1).timeout
	if not is_inside_tree():
		return

	_status.text = "FALLEN MATRON — PHASE TRANSITION"
	_rig.call("show_phase_transition", "fallen_matron", 3)
	await get_tree().create_timer(1.75).timeout
	if is_inside_tree():
		_status.text = "PREVIEW COMPLETE — run again to replay"
