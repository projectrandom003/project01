class_name CastleWaterComponent
extends Node2D
## Owns the authored pond zones used by water queries and world interactions.


func is_water_world(world_position: Vector2) -> bool:
	var grid_position := IsoMath.world_to_grid(world_position)
	var zones := get_node_or_null("WaterZones") as Node2D
	if zones == null:
		push_error("CastleWaterComponent requires authored WaterZones.")
		return false
	for marker in zones.get_children():
		if not (marker is Marker2D):
			continue
		var grid_value: Variant = marker.get_meta("grid_position", null)
		var radius := float(marker.get_meta("radius", 0.0))
		if grid_value is Vector2 and radius > 0.0 and grid_position.distance_to(grid_value) < radius:
			return true
	return false
