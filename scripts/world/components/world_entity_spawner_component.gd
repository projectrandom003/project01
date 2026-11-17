class_name WorldEntitySpawnerComponent
extends Node2D
## Owns deterministic region entity placement and bounded ambient/interactable spawning.

const MONSTER_SCENE: PackedScene = preload("res://scenes/world/roaming_monster.tscn")
const NPC_SCENE: PackedScene = preload("res://scenes/world/world_npc.tscn")
const MAX_INTERACTIVE_PROPS := 28
const MAX_ANIMATED_PROPS := 40

var world: Node2D


func _ready() -> void:
	if get_parent() != null:
		world = get_parent() as Node2D


func configure(owner_world: Node2D) -> void:
	world = owner_world


func spawn_npc(npc_id: String, display_name: String, dialogue_id: String, grid: Vector2, palette: Dictionary, race: String, role: String = "") -> WorldNPC:
	if world == null:
		return null
	var npc := NPC_SCENE.instantiate() as WorldNPC
	npc.role = role
	npc.setup(npc_id, display_name, dialogue_id, palette, race)
	npc.position = IsoMath.grid_to_world(grid.x, grid.y)
	var entities: Node2D = world.get("entities")
	entities.add_child(npc)
	var spawned: Array = world.get("npcs")
	spawned.append(npc)
	return npc


func spawn_monsters() -> Array:
	if world == null:
		return []
	var region: Dictionary = world.get("region")
	var entities: Node2D = world.get("entities")
	var spawned: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = int(region.get("noise_seed", 1)) + 77
	var spawn_index := 0
	for spawn in region.get("spawns", []):
		var group_id := str(spawn.get("group", ""))
		var group: Dictionary = ContentDB.get_enemy_group(group_id)
		if group.is_empty():
			continue
		var enemy_ids: Array = group.get("enemies", [])
		if enemy_ids.is_empty():
			continue
		var enemy_def: Dictionary = ContentDB.get_enemy(str(enemy_ids[0]))
		var center_data: Array = spawn.get("grid", [0, 0])
		var center := Vector2(float(center_data[0]), float(center_data[1]))
		var radius := float(spawn.get("radius", 2.0))
		var count := int(spawn.get("count", 1))
		var is_boss := bool(group.get("boss", false))
		for index in count:
			var angle := rng.randf_range(0.0, TAU)
			var distance := rng.randf_range(0.2, radius)
			var grid_position := center + Vector2(cos(angle), sin(angle)) * distance
			var monster := MONSTER_SCENE.instantiate() as RoamingMonster
			monster.spawn_index = spawn_index
			monster.setup(group_id, IsoMath.grid_to_world(grid_position.x, grid_position.y), enemy_def, is_boss)
			monster.required_quest = str(spawn.get("requires_quest", ""))
			monster.required_quest_step = int(spawn.get("requires_quest_step", 0))
			entities.add_child(monster)
			spawned.append(monster)
			spawn_index += 1
	return spawned


func spawn_wildlife() -> void:
	if world == null:
		return
	var tier := GreenwardStyle.performance_tier()
	var cap := int(GreenwardStyle.MAX_PARTICLES * 0.05)
	if tier == "mobile":
		cap = int(cap * GreenwardStyle.MOBILE_PROP_FACTOR)
	cap = clampi(cap, 0, MAX_ANIMATED_PROPS)
	var kinds := ["butterfly", "moth", "bird", "firefly_sprite"]
	var centres := [
		Vector2(8, 8), Vector2(-18, 28), Vector2(34, 24), Vector2(20, 38),
		Vector2(-28, -12), Vector2(42, -8), Vector2(16, 52), Vector2(34, -28),
		Vector2(-88, 76), Vector2(116, 78)
	]
	for index in cap:
		var centre: Vector2 = centres[index % centres.size()]
		var jitter := Vector2(sin(float(index) * 12.9898) * 2.4, cos(float(index) * 7.233) * 2.0)
		world.call("_add_animated_prop", str(kinds[index % kinds.size()]), centre + jitter, 0.85, index % 2 == 0, AnimatedProp.MOTION_DRIFT, 0)


func spawn_interactive_props() -> void:
	if world == null:
		return
	var entries := [
		["rune_stone", Vector2(-18, 28), "Weathered Rune", "The stones remember a song the forest forgot.", 1],
		["berry_bush", Vector2(34, 24), "Moonpetal Herbs", "Silver leaves stir though there is no wind.", 1, {"moonpetal": 1}],
		["wisp_lantern", Vector2(20, 38), "Wisp Lantern", "A patient light, waiting to be noticed.", 1],
		["shrine", Vector2(-28, -12), "Glade Shrine", "A small offering to the green.", 1],
		["crystal_cluster", Vector2(42, -8), "Hollowed Crystal", "It hums with a hollow, borrowed warmth.", 2, {"glade_sap": 2}],
		["flower_cluster", Vector2(-45, 58), "Mosslight Flowers", "Tiny petals hold the last warmth of dusk.", 2, {"moonpetal": 2}],
		["berry_bush", Vector2(-22, 76), "Elderberry Bough", "The oldest roots shelter a rare harvest.", 2, {"glade_sap": 2}],
		["rune_stone", Vector2(-54, 12), "Wayfarer's Mark", "A worn marker points deeper into Greenward.", 0],
		["crystal_cluster", Vector2(54, 0), "Singing Shard", "A clear note rings inside the crystal.", 1, {"glade_sap": 1}],
		["spirit_bloom", Vector2(68, 45), "Lantern Bloom", "Its petals brighten when someone approaches.", 2, {"moonpetal": 2}],
		["glow_mushroom", Vector2(82, 100), "Duskwick Cap", "A soft blue light spills from its gills.", 1, {"glade_sap": 1}],
		["wisp_lantern", Vector2(12, 72), "Lost Wisp", "It has been waiting beside the old road.", 2],
		["flower_cluster", Vector2(38, -50), "Sunfall Posy", "Gold-edged flowers grow in the high clearing.", 1, {"moonpetal": 1}],
		["rune_stone", Vector2(-60, -24), "Broken Waystone", "The inscription names a path no longer on maps.", 2],
		["berry_bush", Vector2(72, -40), "Silverleaf Berries", "The fruit glimmers beneath the leaves.", 2, {"moonpetal": 2}],
		["crystal_cluster", Vector2(130, 45), "Estate Crystal", "Violet light moves beneath its glassy surface.", 2, {"glade_sap": 2}],
		["spirit_bloom", Vector2(-112, 92), "First Tree Petal", "A petal from the ancient sanctuary.", 2, {"moonpetal": 2}],
	]
	var existing: Array = world.get("_interactive_props")
	for index in entries.size():
		if existing.size() >= MAX_INTERACTIVE_PROPS:
			break
		var entry: Array = entries[index]
		world.call("_add_interactive_prop", str(entry[0]), entry[1], str(entry[2]), str(entry[3]), int(entry[4]), entry[5] if entry.size() > 5 else {})
