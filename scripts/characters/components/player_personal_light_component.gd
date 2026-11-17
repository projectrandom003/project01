class_name PlayerPersonalLightComponent
extends PointLight2D
## Owns the player's local light response to the active world day phase.

const UPDATE_INTERVAL := 0.25

var _accumulator: float = 0.0


func _process(delta: float) -> void:
	_accumulator += delta
	if _accumulator < UPDATE_INTERVAL:
		return
	_accumulator = 0.0
	var phase_name := _find_phase()
	var phase_data := GreenwardStyle.phase(phase_name)
	var ambient := float(phase_data.get("ambient", 1.0))
	energy = clampf(0.35 + (1.0 - ambient) * 0.9, 0.35, 1.2)


func _find_phase() -> String:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("day_phase"):
			return str(node.call("day_phase"))
		node = node.get_parent()
	return "Day"
