class_name CastleRoyalGardens
extends Node2D
## Composition root and compatibility facade for Castle & Royal Gardens.
## Stateful responsibilities live in authored child components; layout data,
## art factories and deterministic rules remain lightweight resources.

@onready var entities: Node2D = $Entities
@onready var spawn_points: Node2D = $MapSpawnPoints
@onready var npc_placement: Node2D = $NPCPlacement

var terrain_component: CastleTerrainComponent
var lighting_component: CastleLightingComponent
var npc_spawner_component: CastleNPCSpawnerComponent
var player_spawner_component: CastlePlayerSpawnerComponent
var runtime_component: CastleWorldRuntimeComponent
var presentation_component: CastleWorldPresentationComponent
var water_component: CastleWaterComponent

const QUEST_MARKER_SCENE: PackedScene = preload("res://scenes/world/quest_destination_marker.tscn")

var region_id := "castle_royal_gardens"
var region: Dictionary = {}
var entity_spawner: WorldEntitySpawnerComponent
var entry_point := ""
var player: Player
var npcs: Array = []
var monsters: Array = []
var loaded_chunks: Dictionary = {}
var weather: WeatherDirector
var day_night: DayNight
var _visual_standards_applied := true
var _visual_standards_valid := true
var _visual_standards_summary := "castle_royal_gardens"

func _ready() -> void:
	add_to_group("world")
	add_to_group("castle_royal_gardens")
	weather = WeatherDirector.new()
	day_night = get_node_or_null("DayNight") as DayNight
	terrain_component = _require_component("TerrainBuilder", CastleTerrainComponent) as CastleTerrainComponent
	lighting_component = _require_component("LightingBuilder", CastleLightingComponent) as CastleLightingComponent
	npc_spawner_component = _require_component("NPCSpawner", CastleNPCSpawnerComponent) as CastleNPCSpawnerComponent
	player_spawner_component = _require_component("PlayerSpawner", CastlePlayerSpawnerComponent) as CastlePlayerSpawnerComponent
	runtime_component = _require_component("WorldRuntime", CastleWorldRuntimeComponent) as CastleWorldRuntimeComponent
	presentation_component = _require_component("Presentation", CastleWorldPresentationComponent) as CastleWorldPresentationComponent
	water_component = _require_component("Water", CastleWaterComponent) as CastleWaterComponent
	if terrain_component == null or lighting_component == null or npc_spawner_component == null or player_spawner_component == null or runtime_component == null or presentation_component == null or water_component == null:
		push_error("CastleRoyalGardens is missing one or more authored world components.")
		return
	region = ContentDB.get_region(region_id)
	entity_spawner = get_node_or_null("EntitySpawner") as WorldEntitySpawnerComponent
	if region.is_empty() or entity_spawner == null:
		push_error("CastleRoyalGardens requires region data and its authored EntitySpawner component.")
		return
	entity_spawner.configure(self)
	terrain_component.bind(self)
	lighting_component.bind(self)
	npc_spawner_component.bind(self)
	player_spawner_component.bind(self)
	runtime_component.bind(self)
	presentation_component.bind(self)
	_build_environment()
	player = player_spawner_component.spawn_player()
	if player == null:
		push_error("CastleRoyalGardens failed to spawn its player.")
		return
	_spawn_npcs_from_markers()
	monsters = entity_spawner.spawn_monsters()
	var quest_marker := QUEST_MARKER_SCENE.instantiate() as QuestDestinationMarker
	quest_marker.name = "QuestDestinationMarker"
	entities.add_child(quest_marker)
	EventBus.world_ready.emit()

func _require_component(node_name: String, expected_type: Variant) -> Node:
	var component := get_node_or_null(node_name)
	if component == null or not is_instance_of(component, expected_type):
		push_error("CastleRoyalGardens requires authored %s (%s)." % [node_name, expected_type])
		return null
	return component

func _build_environment() -> void:
	_build_iso_ground()
	_configure_lighting_and_effects()
	_configure_bounds()

func _build_iso_ground() -> void:
	terrain_component.build()

func _configure_lighting_and_effects() -> void:
	lighting_component.build()

func _spawn_npcs_from_markers() -> void:
	npc_spawner_component.spawn_from_markers()

func _configure_bounds() -> void:
	var bounds := get_node_or_null("Bounds") as StaticBody2D
	if bounds == null:
		push_error("CastleRoyalGardens requires its authored Bounds collider.")
		return

func get_spawn_position(marker_name: String) -> Vector2:
	var marker := spawn_points.get_node_or_null(marker_name) as Node2D if spawn_points != null else null
	if marker != null:
		return marker.position
	return IsoMath.grid_to_world(29.38, 9.38)

func get_spawn_points() -> Array[Node2D]:
	var result: Array[Node2D] = []
	if spawn_points != null:
		for child in spawn_points.get_children():
			if child is Node2D:
				result.append(child as Node2D)
	return result

func get_npc_placement_points() -> Array[Node2D]:
	var result: Array[Node2D] = []
	if npc_placement != null:
		for child in npc_placement.get_children():
			if child is Node2D:
				result.append(child as Node2D)
	return result

func current_area_name() -> String:
	return "Royal Gardens"

func day_phase() -> String:
	return "day"

func get_world_npcs() -> Array:
	return npcs

func get_world_monsters() -> Array:
	return monsters

func is_water_world(pos: Vector2) -> bool:
	return water_component.is_water_world(pos) if water_component != null else false

func visual_standards_report() -> Dictionary:
	return presentation_component.visual_standards_report() if presentation_component != null else {}

func visual_style_report() -> Dictionary:
	return presentation_component.visual_style_report() if presentation_component != null else {}
