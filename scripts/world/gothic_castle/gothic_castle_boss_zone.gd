class_name GothicCastleBossZone
extends Node2D
## Playable Royal Road -> Gothic Castle -> Baltoria arena world.
##
## Every visible object is an individual, editable instance of a generated
## ReveriePack piece scene. The ground is per-cell Sprite2D tiles on the same
## IsoMath lattice used by the player, portals, collision and the minimap.
## Nothing here is a flattened background or a hardcoded gameplay shortcut.

@onready var entities: Node2D = $Entities
@onready var ground_layer: Node2D = $Terrain/Ground
@onready var path_layer: Node2D = $Terrain/Paths
@onready var castle_layer: Node2D = $Castle
@onready var arena_layer: Node2D = $Arena
@onready var flora_layer: Node2D = $Flora
@onready var props_layer: Node2D = $Props
@onready var effects_layer: Node2D = $Effects
@onready var environment_component: GothicCastleEnvironmentComponent = $Components/Environment
@onready var actor_spawner: GothicCastleActorSpawnerComponent = $Components/ActorSpawner
@onready var session_component: GothicCastleSessionComponent = $Components/Session

var region_id: String = "gothic_castle_boss_zone"
var entry_point: String = ""
var player: Player
var npcs: Array = []
var monsters: Array = []
var loaded_chunks: Dictionary = {}
var weather: WeatherDirector
var day_night: DayNight

var _water_cells: Dictionary = {}


func _ready() -> void:
	add_to_group("world")
	add_to_group("gothic_castle_boss_zone")
	weather = WeatherDirector.new()
	day_night = get_node_or_null("DayNight") as DayNight
	environment_component.build(self)
	actor_spawner.build(self)
	player = actor_spawner.player
	npcs = actor_spawner.npcs
	monsters = actor_spawner.monsters
	session_component.bind(self)
	EventBus.world_ready.emit()


# ------------------------------------------------------------ public API ----
func current_area_name() -> String:
	if player == null:
		return "Royal Road"
	var grid := IsoMath.world_to_grid(player.global_position)
	var best := "Royal Road"
	var best_dist := 3.5
	var region: Dictionary = ContentDB.get_region(region_id)
	for poi in region.get("pois", []):
		var p: Dictionary = poi
		var pg: Array = p.get("grid", [0, 0])
		var dist := Vector2(grid).distance_to(Vector2(float(pg[0]), float(pg[1])))
		if dist < best_dist:
			best_dist = dist
			best = str(p.get("name", best))
	return best


func day_phase() -> String:
	if day_night != null and day_night.has_method("is_night"):
		return "night" if day_night.call("is_night") else "day"
	return "day"


func is_water_world(world_pos: Vector2) -> bool:
	var grid := IsoMath.world_to_grid(world_pos)
	for key in _water_cells:
		var cell: Vector2i = key
		if Vector2(grid).distance_to(Vector2(cell)) < 2.5:
			return true
	return false


func get_spawn_points() -> Dictionary:
	return {"PlayerSpawn": ReverieRouteData.ORIGIN,
			"ArenaGate": IsoMath.grid_to_world(60.0, 4.0)}


func get_npc_placement_points() -> Dictionary:
	var result := {}
	for data in ReverieRouteData.NPCS:
		var d: Dictionary = data
		var cell: Vector2i = d["grid"]
		result[str(d["marker"])] = IsoMath.grid_to_world(float(cell.x), float(cell.y))
	return result


func get_world_npcs() -> Array:
	return npcs


func get_world_monsters() -> Array:
	return monsters


func visual_standards_report() -> Dictionary:
	return {
		"region": region_id,
		"tiles": ground_layer.get_child_count() if ground_layer != null else 0,
		"pieces": castle_layer.get_child_count() + arena_layer.get_child_count() if castle_layer != null else 0,
		"npcs": npcs.size(), "monsters": monsters.size(),
		"chunks_loaded": loaded_chunks.size(),
	}


func visual_style_report() -> Dictionary:
	return visual_standards_report()

