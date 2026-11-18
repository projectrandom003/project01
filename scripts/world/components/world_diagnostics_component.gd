class_name WorldDiagnosticsComponent
extends Node
## Builds read-only world diagnostics reports; owns no gameplay state.

var world: GreenwardWorld


func configure(owner_world: GreenwardWorld) -> void:
	world = owner_world


func visual_style_report() -> Dictionary:
	if world == null:
		return {}
	var prop_total := 0
	for key in world._prop_kind_counts.keys():
		prop_total += int(world._prop_kind_counts[key])
	var player_art: Dictionary = {}
	if world.player != null and is_instance_valid(world.player) and world.player.visual != null:
		player_art = world.player.visual.character_art_report()
	return {
		"phase": world.day_phase(),
		"weather_state": world.weather.current_state if world.weather != null else WeatherDirector.CLEAR,
		"weather_state_name": WeatherDirector.state_name(world.weather.current_state) if world.weather != null else "clear",
		"weather_intensity": world.weather.intensity if world.weather != null else 0.0,
		"performance_tier": GreenwardStyle.performance_tier(),
		"prop_kind_counts": world._prop_kind_counts.duplicate(),
		"prop_total": prop_total,
		"cached_textures": world._texture_keys.size(),
		"chunks_loaded": world.loaded_chunks.size(),
		"animated_props": world._animated_props.size(),
		"interactive_props": world._interactive_props.size(),
		"light_count": world._lights.size(),
		"fog_enabled": world.fog_quad != null and world.fog_quad.visible,
		"rain_amount": world.rain.amount if world.rain != null else 0,
		"particle_cap": GreenwardStyle.MAX_PARTICLES,
		"prop_cap": GreenwardStyle.MAX_PROPS_PER_CHUNK,
		"region_id": world.region_id,
		"region_name": world.region_display_name(),
		"zone": world.current_zone(),
		"entry_points": world.region.get("entry_points", {}),
		"connections": world.region.get("connections", []),
		"world_origin": world.region.get("world_origin", [0, 0]),
		"portals": world._portals.size(),
		"prepared_chunks": world._preparer.stats() if world._preparer != null else { "pending": 0, "cached": 0, "capacity": 0 },
		"visual_standards": world.visual_standards_report(),
		"visual_standards_valid": world._visual_standards_valid,
		"character_art": player_art,
		"prop_kind_total": ProceduralArt.prop_kinds().size(),
	}
