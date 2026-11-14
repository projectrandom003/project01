class_name VillageEnvironment
extends Node2D
## Node-first village root. Composes authored/reusable child scenes and groups.
## Does not procedurally construct the entire village; children are authored in
## scene or configured via Resources and seeded anchors.

signal village_ready

@export var layout_config: Resource

@onready var ground: Node2D = $Ground
@onready var path_network: Node2D = $PathNetwork
@onready var depth_sort: Node2D = $DepthSort
@onready var lighting: Node2D = $Lighting
@onready var ambient_effects: Node2D = $AmbientEffects
@onready var logic: Node = get_node_or_null("Logic")
@onready var building_slots_root: Node2D = get_node_or_null("Logic/BuildingSlots") as Node2D
@onready var npc_areas_root: Node2D = get_node_or_null("Logic/NPCAreas") as Node2D
@onready var tree_group_defs_root: Node2D = get_node_or_null("Logic/TreeGroupDefs") as Node2D

# Backward-compatible aliases (logical groups; sortable visuals live in depth_sort)
@onready var buildings: Node2D = building_slots_root if building_slots_root != null else depth_sort
@onready var tree_groups: Node2D = tree_group_defs_root if tree_group_defs_root != null else depth_sort
@onready var vegetation: Node2D = depth_sort
@onready var furniture: Node2D = depth_sort
@onready var npcs: Node2D = npc_areas_root if npc_areas_root != null else depth_sort
@onready var interactive_locations: Node2D = depth_sort

var _shared_depth_parent: Node2D = null

func get_depth_sort_parent() -> Node2D:
	return _shared_depth_parent if _shared_depth_parent != null and is_instance_valid(_shared_depth_parent) else depth_sort

func set_shared_depth_parent(parent: Node2D) -> void:
	_shared_depth_parent = parent
	# Rehome any existing sortable village visuals into the shared parent (preserve world pos).
	if _shared_depth_parent != null and is_instance_valid(_shared_depth_parent):
		_rehome_depth_children(depth_sort, _shared_depth_parent)

func _rehome_depth_children(from_node: Node2D, to_node: Node2D) -> void:
	if from_node == null or to_node == null or from_node == to_node:
		return
	for child in from_node.get_children().duplicate():
		if not (child is Node2D):
			continue
		var n := child as Node2D
		var gp := n.global_position
		from_node.remove_child(n)
		to_node.add_child(n)
		n.global_position = gp

const FOREST_TREE_SCENE: PackedScene = preload("res://scenes/world/forest_tree.tscn")

func _ready() -> void:
	_populate_tree_groups()
	village_ready.emit()

func repopulate_tree_groups() -> void:
	_clear_generated_trees()
	_populate_tree_groups()

func _clear_generated_trees() -> void:
	if not is_inside_tree():
		return
	# Trees are placed as direct children of the shared depth-sort parent for correct
	# interleaving; they are tagged with village metadata for safe cleanup.
	var parent := get_depth_sort_parent()
	if parent == null:
		return
	for child in parent.get_children().duplicate():
		if child.has_meta("village_tree_group"):
			child.free()

func _populate_tree_groups() -> void:
	if layout_config == null:
		return
	if not layout_config is VillageLayoutConfig:
		return
	var cfg := layout_config as VillageLayoutConfig
	var defs: Array = cfg.tree_groups
	var depth_parent := get_depth_sort_parent()
	if depth_parent == null:
		return
	for def_v in defs:
		if typeof(def_v) != TYPE_DICTIONARY:
			continue
		var def: Dictionary = def_v
		var group_name := str(def.get("name", ""))
		# deterministic variation stream per group (stable across launches)
		var rng := cfg.stable_rng("trees:" + group_name)
		var trees: Array = def.get("trees", [])
		for t_v in trees:
			if typeof(t_v) != TYPE_DICTIONARY:
				continue
			var t: Dictionary = t_v
			var kind := str(t.get("kind", "glade_tree"))
			var base_world := _vec2_from(t.get("world", Vector2.ZERO))
			var scale_base := float(t.get("scale", 1.0))
			var variant_base := int(t.get("variant", 0))
			var flip_base := bool(t.get("flip", false))
			var allow_variation := bool(t.get("vary", true))
			# controlled variation only (small jitter/scale/variant within authored constraints)
			var jitter := Vector2.ZERO
			var scale_v := scale_base
			var variant_v := variant_base
			var flip_v := flip_base
			if allow_variation:
				jitter = Vector2(rng.randf_range(-6.0, 6.0), rng.randf_range(-4.0, 4.0))
				scale_v = clampf(scale_base * rng.randf_range(0.95, 1.06), 0.7, 1.4)
				if kind == "glade_tree":
					variant_v = rng.randi_range(0, maxi(0, GreenwardStyle.variant_count("glade_tree") - 1))
				else:
					variant_v = variant_base + (rng.randi_range(0, 1) if GreenwardStyle.variant_count(kind) > 1 else 0)
					variant_v = clampi(variant_v, 0, maxi(0, GreenwardStyle.variant_count(kind) - 1))
				flip_v = flip_base if not bool(t.get("vary_flip", true)) else (rng.randf() < 0.5)
			var pos := base_world + jitter
			if not _position_allowed(pos, cfg):
				continue
			var inst := FOREST_TREE_SCENE.instantiate()
			# Tag for category/cleanup while remaining a direct child of the shared Y-sort parent.
			inst.set_meta("village_tree_group", group_name)
			inst.set_meta("village_sort_category", "tree")
			depth_parent.add_child(inst)
			# Authored coordinates are world-space; preserve rendered world placement.
			# Exclusion checks stay in world space.
			if inst is Node2D:
				(inst as Node2D).global_position = pos
			else:
				inst.position = depth_parent.to_local(pos)
			if inst.has_method("setup"):
				inst.setup(kind, variant_v, flip_v, scale_v, null)

func _position_allowed(world_pos: Vector2, cfg: VillageLayoutConfig) -> bool:
	for z_v in cfg.exclusion_zones:
		if typeof(z_v) != TYPE_DICTIONARY:
			continue
		var z: Dictionary = z_v
		var ztype := str(z.get("type", "circle"))
		var center := _vec2_from(z.get("center", Vector2.ZERO))
		if ztype == "circle":
			if world_pos.distance_to(center) <= float(z.get("radius", 0.0)):
				return false
		elif ztype == "rect":
			var size := _vec2_from(z.get("size", Vector2.ZERO))
			var half := size * 0.5
			if absf(world_pos.x - center.x) <= half.x and absf(world_pos.y - center.y) <= half.y:
				return false
	return true

func _vec2_from(v: Variant) -> Vector2:
	if v is Vector2:
		return v
	if typeof(v) == TYPE_ARRAY and (v as Array).size() >= 2:
		return Vector2(float(v[0]), float(v[1]))
	if typeof(v) == TYPE_DICTIONARY:
		var d: Dictionary = v
		return Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))
	return Vector2.ZERO

func get_group_node(group_name: String) -> Node2D:
	match group_name:
		"Buildings": return buildings
		"TreeGroups": return tree_groups
		"Vegetation": return vegetation
		"Furniture": return furniture
		"NPCs": return npcs
		"InteractiveLocations": return interactive_locations
		"Lighting": return lighting
		"AmbientEffects": return ambient_effects
		"DepthSort": return depth_sort
	var direct := get_node_or_null(group_name) as Node2D
	if direct != null:
		return direct
	if logic != null:
		return logic.get_node_or_null(group_name) as Node2D
	return null

## Resolve an authored district by its stable StringName ID.
func get_district(district_id: StringName) -> VillageDistrict:
	if path_network == null:
		return null
	for district in path_network.get_children():
		if district is VillageDistrict and (district as VillageDistrict).district_id == district_id:
			return district as VillageDistrict
	return null

## Navigation target for maps/quests; returns this village's local fallback when missing.
func get_district_navigation_position(district_id: StringName) -> Vector2:
	var district := get_district(district_id)
	return district.get_navigation_position() if district != null else global_position

func get_district_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	if path_network == null:
		return ids
	for district in path_network.get_children():
		if district is VillageDistrict:
			ids.append((district as VillageDistrict).district_id)
	return ids

func apply_day_phase(is_night: bool, phase_multiplier: float) -> void:
	for child in lighting.get_children():
		if child.has_method("set_phase_energy"):
			child.set_phase_energy(phase_multiplier, is_night)
