class_name CastleExpansionPortalComponent
extends Node
## Connects the Royal Gardens to the Gothic Castle through the region graph.

const PORTAL_SCENE: PackedScene = preload("res://scenes/world/region_portal.tscn")

func _ready() -> void:
	var region: Dictionary = ContentDB.get_region("castle_royal_gardens")
	var entries: Dictionary = region.get("entry_points", {})
	if not entries.has("boss_path"):
		return
	var connection: Dictionary = {}
	for c in region.get("connections", []):
		var data: Dictionary = c
		if str(data.get("to", "")) == "gothic_castle_boss_zone":
			connection = data
			break
	if connection.is_empty():
		return
	var portal := PORTAL_SCENE.instantiate() as RegionPortal
	if portal == null:
		return
	portal.setup("castle_royal_gardens", connection)
	var grid: Array = entries["boss_path"]
	portal.position = IsoMath.grid_to_world(float(grid[0]), float(grid[1]))
	var props := _props_layer()
	if props == null:
		return
	props.add_child(portal)

func _props_layer() -> Node2D:
	var root := get_parent() as Node2D
	if root == null:
		push_error("Castle expansion portal requires its authored composition root.")
		return null
	var layer := root.get_node_or_null("ExpansionProps") as Node2D
	if layer == null:
		push_error("Castle expansion is missing its authored ExpansionProps layer.")
	return layer
