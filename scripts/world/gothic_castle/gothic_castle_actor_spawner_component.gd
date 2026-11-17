class_name GothicCastleActorSpawnerComponent
extends Node
## Owns player, NPC, encounter, gathering and portal instantiation for this region.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")
const NPC_SCENE: PackedScene = preload("res://scenes/world/world_npc.tscn")
const MONSTER_SCENE: PackedScene = preload("res://scenes/world/roaming_monster.tscn")
const BOSS_MONSTER_SCENE: PackedScene = preload("res://scenes/world/gothic_castle/baltoria_monster.tscn")
const PORTAL_SCENE: PackedScene = preload("res://scenes/world/region_portal.tscn")
const GATHER_SCENE: PackedScene = preload("res://scenes/world/interactive_prop.tscn")

var entities: Node2D
var region_id: String
var entry_point: String
var player: Player
var npcs: Array = []
var monsters: Array = []

func build(world: GothicCastleBossZone) -> void:
	entities = world.entities
	region_id = world.region_id
	entry_point = world.entry_point
	npcs = world.npcs
	monsters = world.monsters
	_spawn_player()
	_spawn_npcs()
	_spawn_monsters()
	_spawn_gather_nodes()
	_spawn_portals()
func _spawn_player() -> void:
	var spawn := ReverieRouteData.ORIGIN
	var region: Dictionary = ContentDB.get_region(region_id)
	var entry: Dictionary = region.get("entry_points", {})
	if entry.has(entry_point):
		var grid: Array = entry[entry_point]
		spawn = IsoMath.grid_to_world(float(grid[0]), float(grid[1]))
	elif GameState.session_domain.has_region_position(region_id):
		spawn = GameState.session_domain.region_position(region_id)
	player = PLAYER_SCENE.instantiate() as Player
	entities.add_child(player)
	player.global_position = entities.to_global(spawn)
	player.restore_facing(GameState.session_domain.player_facing)


func _spawn_npcs() -> void:
	var palettes := {
		"gold": {"hair": "#d8c0a0", "primary": "#4c5a70", "secondary": "#c8a860", "accent": "#9df5cf", "skin": "#e8c8a8"},
		"violet": {"hair": "#b9a8d0", "primary": "#3c3052", "secondary": "#8a6cae", "accent": "#c060d8", "skin": "#d8c0b0"},
		"silver": {"hair": "#c8c8d8", "primary": "#3a4058", "secondary": "#aab4cc", "accent": "#e08cff", "skin": "#d8c8b8"},
	}
	for data in ReverieRouteData.NPCS:
		var d: Dictionary = data
		var npc := NPC_SCENE.instantiate() as WorldNPC
		if npc == null:
			continue
		npc.role = str(d.get("npc_id", "guardian")).capitalize()
		npc.setup(str(d["npc_id"]), str(d["name"]), str(d["dialogue"]),
				palettes.get(str(d.get("palette", "gold")), {}), str(d.get("race", "Human")))
		npc.position = IsoMath.grid_to_world(float((d["grid"] as Vector2i).x), float((d["grid"] as Vector2i).y))
		entities.add_child(npc)
		npcs.append(npc)


func _spawn_monsters() -> void:
	var region: Dictionary = ContentDB.get_region(region_id)
	var spawns: Array = region.get("spawns", [])
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242 + 77
	for spawn in spawns:
		var s: Dictionary = spawn
		var group_id := str(s.get("group", ""))
		var group: Dictionary = ContentDB.get_enemy_group(group_id)
		if group.is_empty():
			continue
		var enemies: Array = group.get("enemies", [])
		if enemies.is_empty():
			continue
		var enemy_def = ContentDB.get_enemy(str(enemies[0]))
		if enemy_def == null:
			continue
		var is_boss := bool(group.get("boss", false))
		for i in int(s.get("count", 1)):
			var grid: Array = s.get("grid", [0, 0])
			var radius := float(s.get("radius", 1))
			var cell := Vector2(float(grid[0]) + rng.randf_range(-radius, radius),
					float(grid[1]) + rng.randf_range(-radius, radius))
			var monster := (BOSS_MONSTER_SCENE.instantiate() if is_boss else MONSTER_SCENE.instantiate()) as RoamingMonster
			if monster == null:
				continue
			monster.setup(group_id, IsoMath.grid_to_world(cell.x, cell.y), enemy_def, is_boss)
			entities.add_child(monster)
			monsters.append(monster)


func _spawn_gather_nodes() -> void:
	for data in ReverieRouteData.GATHER_NODES:
		var d: Dictionary = data
		var prop := GATHER_SCENE.instantiate() as InteractiveProp
		if prop == null:
			continue
		var cell: Vector2i = d["grid"]
		prop.setup("rune_stone", IsoMath.grid_to_world(float(cell.x), float(cell.y)),
				str(d["label"]), "A trace of the old royal road.", 1)
		prop.configure_collectible(str(d["id"]), d["items"], str(d["label"]))
		prop.toast_on_interact = true
		entities.add_child(prop)


func _spawn_portals() -> void:
	var region: Dictionary = ContentDB.get_region(region_id)
	var entries: Dictionary = region.get("entry_points", {})
	for connection in region.get("connections", []):
		var c: Dictionary = connection
		var via := str(c.get("via", ""))
		if not entries.has(via):
			continue
		var grid: Array = entries[via]
		var portal := PORTAL_SCENE.instantiate() as RegionPortal
		if portal == null:
			continue
		portal.setup(region_id, c)
		portal.position = IsoMath.grid_to_world(float(grid[0]), float(grid[1]))
		entities.add_child(portal)


