class_name VillagePlacementAnchor
extends Marker2D
## Authored placement marker. Seed affects decorative variants, never anchor position.

@export var anchor_id: StringName
@export_enum("building", "tree", "furniture", "vegetation", "npc", "landmark") var anchor_role: String = "vegetation"
@export var scene_to_place: PackedScene
@export var prop_kind_override: StringName
@export_range(0.25, 2.5, 0.05) var placement_scale: float = 1.0
@export_range(0, 32) var variant_min: int = 0
@export_range(0, 32) var variant_max: int = 3
@export var flip_allowed: bool = true

func resolve_variant(seed_value: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, anchor_id, anchor_role])
	return rng.randi_range(mini(variant_min, variant_max), maxi(variant_min, variant_max))

func instantiate_placed(seed_value: int) -> Node2D:
	if scene_to_place == null:
		return null
	var instance := scene_to_place.instantiate() as Node2D
	if instance == null:
		return null
	instance.position = position
	instance.scale = Vector2.ONE * placement_scale
	if instance is ModularForestProp:
		var prop := instance as ModularForestProp
		if not prop_kind_override.is_empty():
			prop.prop_kind = String(prop_kind_override)
		prop.variant = resolve_variant(seed_value)
		prop.flip_h = flip_allowed and (resolve_variant(seed_value + 1) % 2 == 1)
	return instance
