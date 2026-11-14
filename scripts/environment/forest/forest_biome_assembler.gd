class_name ForestBiomeAssembler
extends RefCounted
## Deterministic scene-based biome scatter. No global RNG, no per-tile nodes,
## no changes to ChunkBuilder. Seed should include world seed + chunk coordinates.

static func populate(environment: ModularForestEnvironment, profile: ForestBiomeProfile,
		bounds: Rect2, seed_value: int) -> Dictionary:
	if environment == null or profile == null or bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return {"trees": 0, "understory": 0, "ambient": 0}
	var rng := RandomNumberGenerator.new()
	rng.seed = _stable_seed(profile.biome_id, seed_value)
	var inset := Vector2(
		minf(profile.bounds_inset.x, bounds.size.x * 0.45),
		minf(profile.bounds_inset.y, bounds.size.y * 0.45)
	)
	var usable := Rect2(bounds.position + inset, bounds.size - inset * 2.0)
	var tree_positions: Array[Vector2] = _scatter(environment, profile.tree_scenes,
		profile.tree_count, usable, profile.tree_min_spacing, rng, "forest_trees")
	var understory_positions: Array[Vector2] = _scatter(environment, profile.understory_scenes,
		profile.understory_count, usable, profile.understory_min_spacing, rng, "forest_understory")
	var ambient_count := _scatter_ambient(environment, profile.ambient_scenes,
		profile.ambient_count, usable, rng)
	return {
		"trees": tree_positions.size(),
		"understory": understory_positions.size(),
		"ambient": ambient_count,
		"tree_positions": tree_positions,
		"understory_positions": understory_positions
	}


static func _scatter(environment: ModularForestEnvironment, scenes: Array[PackedScene],
		requested_count: int, bounds: Rect2, min_spacing: float,
		rng: RandomNumberGenerator, group_name: String) -> Array[Vector2]:
	var placed: Array[Vector2] = []
	if scenes.is_empty() or requested_count <= 0:
		return placed
	var attempts := requested_count * 18
	while placed.size() < requested_count and attempts > 0:
		attempts -= 1
		var point := Vector2(
			rng.randf_range(bounds.position.x, bounds.end.x),
			rng.randf_range(bounds.position.y, bounds.end.y)
		)
		var valid := true
		for existing in placed:
			if point.distance_to(existing) < min_spacing:
				valid = false
				break
		if not valid:
			continue
		var scene: PackedScene = scenes[rng.randi_range(0, scenes.size() - 1)]
		var instance := environment.add_family_scene(scene, point, [group_name])
		if instance != null:
			placed.append(point)
	return placed


static func _scatter_ambient(environment: ModularForestEnvironment, scenes: Array[PackedScene],
		requested_count: int, bounds: Rect2, rng: RandomNumberGenerator) -> int:
	if scenes.is_empty() or requested_count <= 0:
		return 0
	var created := 0
	for index in requested_count:
		var scene: PackedScene = scenes[rng.randi_range(0, scenes.size() - 1)]
		var instance := scene.instantiate() as Node2D
		if instance == null:
			continue
		environment.ambient.add_child(instance)
		instance.position = Vector2(
			rng.randf_range(bounds.position.x, bounds.end.x),
			rng.randf_range(bounds.position.y, bounds.end.y)
		)
		instance.add_to_group("forest_ambient")
		instance.add_to_group("forest_biome_" + String(environment.get_meta("active_biome", "unknown")))
		created += 1
	return created


static func _stable_seed(biome_id: StringName, seed_value: int) -> int:
	return absi(seed_value ^ String(StringName(biome_id)).hash())
