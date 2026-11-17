class_name GreenwardCompositionData
extends Resource
## Validated data for Greenward's stable region-specific scene composition.
## Placement coordinates live here rather than in the world builder implementation.

@export var village_npcs: Array[Dictionary] = []
@export var river_props: Array[Dictionary] = []
@export var river_animated_props: Array[Dictionary] = []
@export var river_lights: Array[Dictionary] = []
@export var anchors: Dictionary = {}
@export var path_routes: Array[Dictionary] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for index in village_npcs.size():
		var npc := village_npcs[index]
		for field in ["npc_id", "display_name", "dialogue_id", "race"]:
			if str(npc.get(field, "")).is_empty():
				errors.append("village_npcs[%d] is missing %s" % [index, field])
		if typeof(npc.get("grid")) != TYPE_VECTOR2:
			errors.append("village_npcs[%d] grid must be Vector2" % index)
		if typeof(npc.get("palette")) != TYPE_DICTIONARY:
			errors.append("village_npcs[%d] palette must be Dictionary" % index)
	_validate_placements(river_props, "river_props", errors, false)
	_validate_placements(river_animated_props, "river_animated_props", errors, true)
	for index in river_lights.size():
		var light := river_lights[index]
		if typeof(light.get("grid")) != TYPE_VECTOR2:
			errors.append("river_lights[%d] grid must be Vector2" % index)
		if float(light.get("energy", -1.0)) < 0.0 or float(light.get("scale", 0.0)) <= 0.0:
			errors.append("river_lights[%d] requires non-negative energy and positive scale" % index)
	for anchor_name in anchors:
		if typeof(anchors[anchor_name]) != TYPE_VECTOR2:
			errors.append("anchor '%s' must be Vector2" % str(anchor_name))
	for index in path_routes.size():
		var route := path_routes[index]
		if typeof(route.get("from")) != TYPE_VECTOR2 or typeof(route.get("to")) != TYPE_VECTOR2:
			errors.append("path_routes[%d] requires Vector2 from/to endpoints" % index)
		if int(route.get("marker_count", 0)) <= 0:
			errors.append("path_routes[%d] marker_count must be positive" % index)
	return errors


func _validate_placements(entries: Array[Dictionary], label: String, errors: PackedStringArray, animated: bool) -> void:
	for index in entries.size():
		var entry := entries[index]
		if str(entry.get("kind", "")).is_empty():
			errors.append("%s[%d] is missing kind" % [label, index])
		if typeof(entry.get("grid")) != TYPE_VECTOR2:
			errors.append("%s[%d] grid must be Vector2" % [label, index])
		if float(entry.get("scale", 0.0)) <= 0.0 or int(entry.get("variant", -1)) < 0 or typeof(entry.get("flip")) != TYPE_BOOL:
			errors.append("%s[%d] requires positive scale, non-negative variant and boolean flip" % [label, index])
		var motion := int(entry.get("motion", -1))
		if animated and (motion < AnimatedProp.MOTION_NONE or motion > AnimatedProp.MOTION_DRIFT):
			errors.append("%s[%d] has an invalid motion id" % [label, index])
