class_name WorldWaterBridgeComponent
extends Node2D
## Owns streamed water-surface presentation and bridge traversal registration.

var navigation: WorldNavigationComponent


func configure(navigation_component: WorldNavigationComponent) -> void:
	navigation = navigation_component


func attach_water_surface(surface: Node2D) -> bool:
	if surface == null or not is_instance_valid(surface):
		return false
	if surface.get_parent() != null:
		surface.get_parent().remove_child(surface)
	surface.z_index = -1
	add_child(surface)
	return true


func register_bridge(grid_position: Vector2) -> void:
	if navigation != null:
		navigation.add_bridge_position(grid_position)


func set_water_enabled(value: bool) -> void:
	visible = value
