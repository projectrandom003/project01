extends Node
## Focused validation for the remote boss territories, continuous paths,
## distributed interactables and quest target coordinates.

func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var region: Dictionary = ContentDB.get_region("greenward")
	var elder := _poi_grid(region, "elder_hollow")
	var matron := _poi_grid(region, "withered_estate")
	if elder.distance_to(matron) < 150.0:
		failures.append("Elder Hollow and Fallen Matron territories are not far enough apart.")
	if elder.distance_to(Vector2(8, 8)) < 100.0 or matron.distance_to(Vector2(8, 8)) < 100.0:
		failures.append("A boss territory is still too close to the village.")
	var elder_spawn := _spawn_grid(region, "elder_hollow")
	var matron_spawn := _spawn_grid(region, "fallen_matron_encounter")
	if elder_spawn.distance_to(elder) > 0.01:
		failures.append("Elder Hollow encounter spawn does not match its zone centre.")
	if matron_spawn.distance_to(matron) > 0.01:
		failures.append("Fallen Matron encounter spawn does not match the Withered Estate centre.")

	var zones := ChunkBuilder._boss_zones(region)
	if zones.size() != 2:
		failures.append("Elder Hollow and Withered Estate do not have separate biome zones.")
	if not ChunkBuilder._valid_kinds().has("bush"):
		failures.append("Greenward's added shrub variation is not a valid prop kind.")

	var paths := ChunkBuilder._path_segments(region)
	if paths.size() < 30:
		failures.append("The woodland route network does not connect all major POIs and the region portal.")
	if not _route_reaches(paths, elder) or not _route_reaches(paths, matron):
		failures.append("A boss territory is missing a continuous path from the village.")
	if not _route_reaches(paths, Vector2(30, 8)):
		failures.append("The village-to-Moonpetal portal route is missing.")

	var elder_quest: Dictionary = ContentDB.get_quest("elder_memory")
	var matron_quest: Dictionary = ContentDB.get_quest("matron_bloom")
	var elder_step: Dictionary = elder_quest.get("steps", [])[0]
	var matron_step: Dictionary = matron_quest.get("steps", [])[0]
	if Vector2(elder_step.get("grid", [0, 0])[0], elder_step.get("grid", [0, 0])[1]).distance_to(elder) > 0.01:
		failures.append("Elder Hollow quest objective does not point to the new sanctuary.")
	if Vector2(matron_step.get("grid", [0, 0])[0], matron_step.get("grid", [0, 0])[1]).distance_to(matron) > 0.01:
		failures.append("Fallen Matron quest objective does not point to the Withered Estate.")

	# Exercise the real Greenward interactable builder without starting a world
	# scene or touching the player's save.
	var world := GreenwardWorld.new()
	world.region_id = "greenward"
	world.region = region
	world.entities = Node2D.new()
	world.add_child(world.entities)
	world._setup_interactive_props()
	if world._interactive_props.size() < 16:
		failures.append("Greenward does not create enough distributed interactables.")
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	for prop in world._interactive_props:
		min_pos.x = minf(min_pos.x, prop.position.x)
		min_pos.y = minf(min_pos.y, prop.position.y)
		max_pos.x = maxf(max_pos.x, prop.position.x)
		max_pos.y = maxf(max_pos.y, prop.position.y)
	if max_pos.distance_to(min_pos) < 5000.0:
		failures.append("Interactables are still concentrated in one small area.")
	world.free()

	if failures.is_empty():
		print("[world-redesign] OK — remote boss zones, route network, objective coordinates and distributed interactables.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error("[world-redesign] " + failure)
		get_tree().quit(1)


func _poi_grid(region: Dictionary, wanted_id: String) -> Vector2:
	for poi in region.get("pois", []):
		if str(poi.get("id", "")) == wanted_id:
			var g: Array = poi.get("grid", [0, 0])
			return Vector2(float(g[0]), float(g[1]))
	return Vector2.ZERO


func _spawn_grid(region: Dictionary, wanted_group: String) -> Vector2:
	for spawn in region.get("spawns", []):
		if str(spawn.get("group", "")) == wanted_group:
			var g: Array = spawn.get("grid", [0, 0])
			return Vector2(float(g[0]), float(g[1]))
	return Vector2.ZERO


func _route_reaches(paths: Array, destination: Vector2) -> bool:
	for segment in paths:
		if segment[1].distance_to(destination) < 0.01:
			return true
	return false
