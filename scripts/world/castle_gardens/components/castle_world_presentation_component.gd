class_name CastleWorldPresentationComponent
extends Node
## Builds compatibility reports for HUD, diagnostics and world tooling.

var world: CastleRoyalGardens

func bind(owner_world: CastleRoyalGardens) -> void:
	world = owner_world

func visual_standards_report() -> Dictionary:
	if world == null:
		return {}
	return {
		"region_id": world.region_id,
		"standards_valid": WorldVisualStandards.validate().is_empty(),
		"applied_categories": [],
		"region_tint": WorldVisualStandards.region_tint(world.region_id),
		"categories": WorldVisualStandards.categories(),
		"summary": WorldVisualStandards.summary(),
		"applied": world._visual_standards_applied,
		"cached_valid": world._visual_standards_valid,
		"cached_summary": not world._visual_standards_summary.is_empty(),
		"final_assets": 0,
		"note": "Royal Gardens uses authored/modular isometric presentation; Gothic Castle is a separate region.",
	}

func visual_style_report() -> Dictionary:
	if world == null:
		return {}
	var player_art: Dictionary = {}
	if world.player != null and is_instance_valid(world.player) and "visual" in world.player and world.player.visual != null and world.player.visual.has_method("character_art_report"):
		player_art = world.player.visual.character_art_report()
	var weather := world.weather
	return {
		"phase": world.day_phase(),
		"weather_state": weather.current_state if weather != null else 0,
		"weather_state_name": WeatherDirector.state_name(weather.current_state) if weather != null else "clear",
		"weather_intensity": weather.intensity if weather != null else 0.0,
		"performance_tier": 1,
		"prop_kind_counts": {},
		"prop_total": 0,
		"cached_textures": 0,
		"chunks_loaded": world.loaded_chunks.size(),
		"animated_props": 0,
		"interactive_props": 0,
		"light_count": 0,
		"fog_enabled": false,
		"rain_amount": 0,
		"particle_cap": 0,
		"prop_cap": 0,
		"region_id": world.region_id,
		"region_name": world.current_area_name(),
		"zone": "castle_gardens",
		"entry_points": ContentDB.get_region(world.region_id).get("entry_points", {}),
		"connections": ContentDB.get_region(world.region_id).get("connections", []),
		"world_origin": ContentDB.get_region(world.region_id).get("world_origin", [0, 0]),
		"portals": 0,
		"prepared_chunks": {"pending": 0, "cached": 0, "capacity": 0},
		"visual_standards": visual_standards_report(),
		"visual_standards_valid": world._visual_standards_valid,
		"character_art": player_art,
		"prop_kind_total": 0,
	}