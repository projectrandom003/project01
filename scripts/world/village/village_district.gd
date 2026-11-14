@tool
class_name VillageDistrict
extends Node2D
## Reusable district container for the authored Greenward village.
## Keeps path pieces grouped while exposing a stable navigation anchor to maps,
## quest markers and future district-specific content.

@export var district_id: StringName = &""
@export var display_name: String = ""
@export_node_path("Marker2D") var navigation_anchor: NodePath = ^"NavigationAnchor"

func get_navigation_position() -> Vector2:
	var marker := get_node_or_null(navigation_anchor) as Marker2D
	return marker.global_position if marker != null else global_position
