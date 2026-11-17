class_name WorldDayNightPresentationComponent
extends Node
## Coordinates phase changes with world atmosphere, village lighting and prop activity.

var world: GreenwardWorld


func configure(owner: GreenwardWorld) -> void:
	world = owner


func bind_day_night(controller: DayNight) -> void:
	if controller != null and not controller.phase_changed.is_connected(_on_phase_changed):
		controller.phase_changed.connect(_on_phase_changed)


func on_phase_changed(phase_name: String) -> void:
	_on_phase_changed(phase_name)


func _on_phase_changed(phase_name: String) -> void:
	if world == null:
		return
	world._apply_atmosphere()
	apply_village_day_phase(phase_name)
	if phase_name != world._last_area_name:
		world._last_area_name = phase_name


func apply_village_day_phase(phase_name: String = "") -> void:
	if world == null:
		return
	var village := world.get_node_or_null("Village")
	if village == null or not village.has_method("apply_day_phase"):
		return
	var phase_name_resolved := phase_name if not phase_name.is_empty() else day_phase()
	var phase := GreenwardStyle.phase(phase_name_resolved)
	var is_night := bool(phase.get("fireflies", false)) or world.day_night != null and world.day_night.is_night()
	var light_energy := float(phase.get("light_energy", 0.5))
	var multiplier := lerpf(0.55, 1.55, clampf(light_energy, 0.0, 1.2))
	if is_night:
		multiplier = maxf(multiplier, 1.15)
	village.apply_day_phase(is_night, multiplier)


func day_phase() -> String:
	return world.day_night.phase_at(world.day_night.time_of_day) if world != null and world.day_night != null else "Day"


func gate_animated_props() -> void:
	if world == null or world.player == null or world._animated_props.is_empty():
		return
	var player_position := world.player.position
	for animated_prop in world._animated_props:
		if is_instance_valid(animated_prop):
			animated_prop.set_active(player_position.distance_to(animated_prop.position) < world.ANIM_VISIBLE_RANGE)
