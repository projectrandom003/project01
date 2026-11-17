class_name GreenwardWorld
extends Node2D
## The playable Greenward slice: streamed square-grid top-down 3/4 terrain, a village hub,
## roaming monsters, NPCs, ambient life, weather, fog and a day/night cycle.
##
## Phase 3 (Visual World): all art is PROCEDURAL PLACEHOLDER. Lighting, fog,
## weather and particles are driven by GreenwardStyle (single source of truth),
## DayNight and WeatherDirector. Chunk streaming + per-layer MultiMesh batching
## are preserved: the optional `detail` MultiMesh ground-cover layer is ALREADY
## parented to `data.terrain` by ChunkBuilder and is intentionally NOT re-added
## or re-parented here. There is one MultiMesh draw call per terrain/water/detail
## layer; no per-tile Sprite2D is ever added.
##
## PART 5 (World Presentation): these are COMPOSITIONAL / STANDARDS improvements
## ONLY — ZERO final assets, all art is still PROCEDURAL PLACEHOLDER. The four
## new silhouettes (birch_grove / moon_lantern / stone_path / village_gate) and
## the two recognisable region compositions are procedural. WorldVisualStandards
## is applied through validation + reporting (apply_visual_standards /
## visual_standards_report); NO existing node is repositioned and NO public API
## or _ready() order is changed.

@export var presentation_config: Resource
@onready var terrain_transitions: Node2D = get_node_or_null("TerrainTransitions") as Node2D
@onready var water_and_bridges: WorldWaterBridgeComponent = get_node_or_null("WaterAndBridges") as WorldWaterBridgeComponent
@onready var navigation_component: WorldNavigationComponent = get_node_or_null("Navigation") as WorldNavigationComponent
@onready var player_spawn_component: WorldPlayerSpawnComponent = get_node_or_null("PlayerSpawn") as WorldPlayerSpawnComponent
@onready var entity_spawner: WorldEntitySpawnerComponent = get_node_or_null("Entities") as WorldEntitySpawnerComponent
@onready var weather_component: WorldWeatherComponent = get_node_or_null("Weather") as WorldWeatherComponent
@onready var effect_follow_component: WorldEffectFollowComponent = get_node_or_null("EffectFollow") as WorldEffectFollowComponent
@onready var fog_component: WorldFogComponent = get_node_or_null("FogPresentation") as WorldFogComponent
@onready var ambient_effects_component: WorldAmbientEffectsComponent = get_node_or_null("AmbientEffectsController") as WorldAmbientEffectsComponent
@onready var lighting_component: WorldLightingComponent = get_node_or_null("LocalizedLighting") as WorldLightingComponent
@onready var presentation_config_component: WorldPresentationConfigComponent = get_node_or_null("PresentationConfig") as WorldPresentationConfigComponent
@onready var chunk_streaming_component: WorldChunkStreamingComponent = get_node_or_null("ChunkStreaming") as WorldChunkStreamingComponent
@onready var chunk_lifecycle_component: WorldChunkLifecycleComponent = get_node_or_null("ChunkLifecycle") as WorldChunkLifecycleComponent
@onready var runtime_component: WorldRuntimeComponent = get_node_or_null("WorldRuntime") as WorldRuntimeComponent
@onready var resource_setup_component: WorldResourceSetupComponent = get_node_or_null("ResourceSetup") as WorldResourceSetupComponent
@onready var region_builder_component: WorldRegionBuilderComponent = get_node_or_null("RegionBuilder") as WorldRegionBuilderComponent
var greenward_builder_component: WorldGreenwardBuilderComponent
var region_context_component: WorldRegionContextComponent
var day_night_presentation_component: WorldDayNightPresentationComponent
var atmosphere_component: WorldAtmosphereComponent
var prop_factory_component: WorldPropFactoryComponent
var visual_standards_component: WorldVisualStandardsComponent
@onready var environment_presentation: Node2D = get_node_or_null("EnvironmentPresentation") as Node2D
@onready var localized_lights_root: Node2D = get_node_or_null("EnvironmentPresentation/LocalizedLights") as Node2D
@onready var water_presentation_root: Node2D = get_node_or_null("EnvironmentPresentation/WaterPresentation") as Node2D
@onready var ambient_sound_root: Node2D = get_node_or_null("EnvironmentPresentation/AmbientSound") as Node2D

const DEFAULT_REGION_ID := "greenward"
const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")
const NPC_SCENE: PackedScene = preload("res://scenes/world/world_npc.tscn")
const INTERACTIVE_PROP_SCENE: PackedScene = preload("res://scenes/world/interactive_prop.tscn")
const ANIMATED_PROP_SCENE: PackedScene = preload("res://scenes/world/animated_prop.tscn")
const REGION_PORTAL_SCENE: PackedScene = preload("res://scenes/world/region_portal.tscn")
const QUEST_MARKER_SCENE: PackedScene = preload("res://scenes/world/quest_destination_marker.tscn")
const GROUND_CHUNK_SCENE: PackedScene = preload("res://scenes/world/ground_chunk.tscn")
const FOREST_TREE_SCENE: PackedScene = preload("res://scenes/world/forest_tree.tscn")
const WORLD_PROP_SPRITE_SCENE: PackedScene = preload("res://scenes/world/components/world_prop_sprite.tscn")
const WORLD_POINT_LIGHT_SCENE: PackedScene = preload("res://scenes/world/components/world_point_light.tscn")
# Step 4 visual prototype: one representative Greenward chunk near the starting
# village, avoiding important NPCs, portals and quest locations.
const PROTOTYPE_GROUND_CHUNK := Vector2i(-1, 0)
var region_id: String = DEFAULT_REGION_ID
var entry_point: String = ""

# Atmosphere / performance caps (bounded; sourced from GreenwardStyle where
# meaningful). No unbounded node spawning anywhere below.
const FOG_SIZE := Vector2(2600.0, 1700.0)
const ANIM_VISIBLE_RANGE := 1200.0
const MAX_INTERACTIVE_PROPS := 28
const MAX_ANIMATED_PROPS := 40
const MAX_LIGHTS := 20
const GENERIC_PROP_CAP := 24

# Cheap, zone-specific ambient tints (derived from the nearest POI at runtime).
const ZONE_TINTS := {
	"village": "#ffd9a0",
	"ruin": "#7fe3e0",
	"grove": "#b48adf",
	"elder_sanctuary": "#a9e89a",
	"withered_estate": "#b78bff",
	"corrupted_grove": "#8c5bc9",
	"shrine": "#9df5cf",
	"river": "#6fc9e6",
	"wilderness": "#a8d0a0",
}

# Every foliage kind that receives the cheap base-anchored wind-sway shader.
# (trees, fern, tall_grass, reeds, berry_bush, flower_cluster, glow_mushroom,
#  spirit_bloom, lily_pad, willow/birch/pine/blossom/dead trees + originals)
const FOLIAGE_KINDS := [
	"glade_tree", "ancient_tree", "willow_tree", "birch_tree", "pine_tree",
	"blossom_tree", "dead_tree", "fern", "tall_grass", "reeds", "lily_pad",
	"berry_bush", "flower_cluster", "glow_mushroom", "spirit_bloom",
	"mushroom", "bush", "flower",
]

var region: Dictionary = {}
var chunk_size: int = 16
var streamer: ChunkStreamer
var elevation: FastNoiseLite
var moisture: FastNoiseLite
var terrain_layer: Node2D
var entities: Node2D
var day_night: DayNight
var player: Player
var ambient: CPUParticles2D
var fireflies: CPUParticles2D
var rain: CPUParticles2D
var weather: WeatherDirector

var terrain_material: ShaderMaterial
var water_material: ShaderMaterial
var wind_material: ShaderMaterial
var fog_material: ShaderMaterial
var fog_quad: Sprite2D

var loaded_chunks: Dictionary = {}
var current_center := Vector2i(99999, 99999)
var monsters: Array = []
var npcs: Array = []

var _last_area_name: String = ""
var _last_phase: String = ""

var _animated_props: Array = []
var _interactive_props: Array = []
var _lights: Array = []
var _prop_kind_counts: Dictionary = {}
var _texture_keys: Dictionary = {}

# PART 5 (World Presentation): cached visual-standards validation + region tint.
# Compositional/reporting only — ZERO final assets, procedural placeholder art.
var _visual_standards_valid: bool = false
var _visual_standards_applied: bool = false
var _visual_standards_tint: Color = Color.WHITE
var _visual_standards_summary: Dictionary = {}

# Region portals + main-thread frame-sliced chunk preparation (PART 5).
var _portals: Array = []
var _preparer: ChunkPreparer
var _prepared_nodes: Dictionary = {}  # Vector2i -> prepared chunk-data (world owns freeing)


func _ready() -> void:
	region = ContentDB.get_region(region_id)
	if region.is_empty():
		# Unknown / missing region id: fall back to Greenward gracefully.
		region = ContentDB.get_region(DEFAULT_REGION_ID)
		region_id = DEFAULT_REGION_ID
	if region.is_empty():
		push_error("[GreenwardWorld] Region data missing.")
		return
	greenward_builder_component = get_node_or_null("GreenwardBuilder") as WorldGreenwardBuilderComponent
	region_context_component = get_node_or_null("RegionContext") as WorldRegionContextComponent
	day_night_presentation_component = get_node_or_null("DayNightPresentation") as WorldDayNightPresentationComponent
	atmosphere_component = get_node_or_null("Atmosphere") as WorldAtmosphereComponent
	prop_factory_component = get_node_or_null("PropFactory") as WorldPropFactoryComponent
	visual_standards_component = get_node_or_null("VisualStandards") as WorldVisualStandardsComponent
	if navigation_component == null or chunk_streaming_component == null or chunk_lifecycle_component == null or region_builder_component == null or greenward_builder_component == null or region_context_component == null or day_night_presentation_component == null or atmosphere_component == null or prop_factory_component == null or visual_standards_component == null:
		push_error("GreenwardWorld scene is missing a required authored component")
		return
	if runtime_component == null:
		push_error("GreenwardWorld requires its authored WorldRuntime component")
		return
	runtime_component.configure(self)
	chunk_size = int(region.get("chunk_size", 16))
	chunk_streaming_component.configure(self, chunk_size, int(region.get("load_radius", 1)))
	streamer = chunk_streaming_component.streamer
	_preparer = chunk_streaming_component.preparer
	_prepared_nodes = chunk_streaming_component.prepared_nodes

	# Preserved _ready() order for Greenward: materials -> layers -> noise ->
	# day/night -> spawn_player -> village/river/landmarks -> monsters ->
	# ambient/weather/fog -> wildlife/interactives -> streaming -> world_ready.
	if resource_setup_component == null:
		push_error("GreenwardWorld requires its authored ResourceSetup component")
		return
	resource_setup_component.configure(self)
	resource_setup_component.setup_materials()
	_setup_layers()
	resource_setup_component.setup_noise()
	_setup_day_night()
	_integrate_village_depth_sort()
	_spawn_player()
	if region_id == DEFAULT_REGION_ID:
		_build_village()          # includes _build_river()
		_build_landmarks()
		_build_extra_landmarks()  # PART 4: extra recognisable landmarks
		_build_paths()            # PART 4: readable routes
	else:
		_build_generic_region()   # data-driven builder for other regions
		if region_id == "moonpetal_hollow":
			_spawn_npc("moonkeeper_liora", "Moonkeeper Liora", "moonkeeper_liora", Vector2(14.0, 10.0), {
				"hair": "#c9d5e8", "primary": "#4b5675", "secondary": "#b7c8e8",
				"accent": "#e6edff", "skin": "#ead8cf",
			}, "Fae", "Moonkeeper")
	_spawn_monsters()
	_setup_ambient()
	_setup_weather()
	_setup_fog()
	_setup_effect_follow_component()
	_setup_presentation_config()
	if region_id == DEFAULT_REGION_ID:
		_setup_wildlife()
		_setup_interactive_props()
		_build_extra_interactive_and_animated()  # PART 4
	var quest_marker := QUEST_MARKER_SCENE.instantiate() as QuestDestinationMarker
	quest_marker.name = "QuestDestinationMarker"
	entities.add_child(quest_marker)
	_spawn_region_portals()       # for BOTH regions (Greenward gate near [30,8])

	# PART 5: validate the visual STANDARD/CONTRACT once and apply the region
	# tint to ambient/fog. AFTER atmosphere setup, BEFORE streaming / world_ready.
	apply_visual_standards()

	add_to_group("world")
	add_to_group("greenward_world")

	var grid := IsoMath.world_to_grid(player.position)
	current_center = streamer.center_chunk(grid)
	_update_streaming(grid)
	_apply_atmosphere()
	_apply_village_day_phase(day_phase())
	EventBus.world_ready.emit()


func _process(delta: float) -> void:
	if runtime_component != null:
		runtime_component.tick(delta)

# --------------------------------------------------------------- base setup

func _setup_materials() -> void:
	if resource_setup_component != null:
		resource_setup_component.setup_materials()


func _setup_layers() -> void:
	terrain_layer = get_node_or_null("Terrain") as Node2D
	water_and_bridges = get_node_or_null("WaterAndBridges") as WorldWaterBridgeComponent
	entities = get_node_or_null("Entities") as Node2D
	entity_spawner = entities as WorldEntitySpawnerComponent
	if terrain_layer == null or water_and_bridges == null or entities == null or entity_spawner == null:
		push_error("GreenwardWorld scene is missing an authored terrain, water, or entity layer")
		return
	terrain_layer.z_index = -10
	water_and_bridges.z_index = -8
	water_and_bridges.configure(navigation_component)
	entities.y_sort_enabled = true
	entity_spawner.configure(self)
	chunk_lifecycle_component.configure(self)
	region_builder_component.configure(self)
	greenward_builder_component.configure(self)
	lighting_component.configure(entities, MAX_LIGHTS)
	_lights = lighting_component.lights
	region_context_component.configure(self)
	day_night_presentation_component.configure(self)
	atmosphere_component.configure(self)
	prop_factory_component.configure(self)
	visual_standards_component.configure(self)

func _integrate_village_depth_sort() -> void:
	# Share one world Y-sort container (Entities) so village-authored depth objects
	# (trees/building slots/visuals) interleave correctly with player, NPCs, and
	# runtime-spawned props. Ground/PathNetwork/Lighting/AmbientEffects remain in the
	# village scene layers and are not moved.
	if entities == null:
		return
	var village := get_node_or_null("Village")
	if village == null:
		return
	if village.has_method("set_shared_depth_parent"):
		village.set_shared_depth_parent(entities)


func _setup_noise() -> void:
	if resource_setup_component != null:
		resource_setup_component.setup_noise()


func _setup_day_night() -> void:
	day_night = get_node_or_null("DayNight") as DayNight
	if day_night == null:
		push_error("GreenwardWorld requires its authored DayNight node")
		return
	day_night.day_length_seconds = 600.0
	day_night_presentation_component.bind_day_night(day_night)

func _spawn_player() -> void:
	player = player_spawn_component.spawn_player()

# --------------------------------------------------------------- streaming

func _update_streaming(player_grid: Vector2) -> void:
	if chunk_streaming_component != null:
		chunk_streaming_component.update_streaming(player_grid)

func _load_chunk(coord: Vector2i) -> void:
	if chunk_lifecycle_component != null:
		chunk_lifecycle_component.load_chunk(coord)

func _unload_chunk(coord: Vector2i) -> void:
	if chunk_lifecycle_component != null:
		chunk_lifecycle_component.unload_chunk(coord)

func is_water_world(world_pos: Vector2) -> bool:
	return navigation_component.is_water_world(world_pos) if navigation_component != null else false


func is_walkable(world_pos: Vector2) -> bool:
	return navigation_component.is_walkable(world_pos) if navigation_component != null else true


func is_near_bridge(world_pos: Vector2) -> bool:
	return navigation_component.is_near_bridge(world_pos) if navigation_component != null else false


func world_to_grid(world_pos: Vector2) -> Vector2:
	return navigation_component.world_to_grid(world_pos) if navigation_component != null else IsoMath.world_to_grid(world_pos)


func get_water_level() -> float:
	return navigation_component.get_water_level() if navigation_component != null else -0.22


func get_bridge_positions() -> Array:
	return navigation_component.get_bridge_positions() if navigation_component != null else []


func get_bridge_radius() -> float:
	return navigation_component.get_bridge_radius() if navigation_component != null else WorldNavigationComponent.DEFAULT_BRIDGE_RADIUS


# ---------------------------------- main-thread chunk preparation (PART 5)
# NO THREADS: MultiMesh / Image / ShaderMaterial creation and every scene-tree
# operation are NOT thread-safe in Godot 4. Chunk generation is therefore kept
# on the MAIN THREAD and FRAME-SLICED — at most ONE chunk is built per frame in
# _process. ChunkPreparer is the deterministic, bounded LRU scheduling cache.

func _prepare_one_chunk(player_grid: Vector2) -> void:
	if chunk_streaming_component != null:
		chunk_streaming_component.prepare_one_chunk(player_grid)

func _reconcile_prepared_cache() -> void:
	if chunk_streaming_component != null:
		chunk_streaming_component.reconcile_prepared_cache()

func _free_chunk_data(data: Dictionary) -> void:
	if chunk_streaming_component != null:
		chunk_streaming_component.free_chunk_data(data)

func _clear_prepared() -> void:
	if chunk_streaming_component != null:
		chunk_streaming_component.clear_prepared()

func _exit_tree() -> void:
	# Free any prepared-but-never-used chunk nodes (they are NOT in the scene
	# tree, so the tree will not free them for us). Avoids ObjectDB leaks.
	_clear_prepared()


func _make_prop_sprite(type: String, world_position: Vector2, scale_value: float, flip: bool, variant: int = 0) -> Sprite2D:
	return prop_factory_component.make_prop_sprite(type, world_position, scale_value, flip, variant) if prop_factory_component != null else null

func _add_prop(type: String, grid_position: Vector2, scale_value: float = 1.0, flip: bool = false, variant: int = 0) -> Sprite2D:
	return prop_factory_component.add_prop(type, grid_position, scale_value, flip, variant) if prop_factory_component != null else null

func _add_light(grid_position: Vector2, color: Color, energy: float, light_scale: float) -> void:
	if prop_factory_component != null:
		prop_factory_component.add_light(grid_position, color, energy, light_scale)


## Typed composition API used by the region builder components.
func add_prop(kind: String, grid_position: Vector2, scale_value: float = 1.0, flip: bool = false, variant: int = 0) -> Sprite2D:
	return _add_prop(kind, grid_position, scale_value, flip, variant)


func add_light(grid_position: Vector2, color: Color, energy: float, light_scale: float) -> void:
	_add_light(grid_position, color, energy, light_scale)


func add_animated_prop(kind: String, grid_position: Vector2, scale_value: float, flip: bool, motion: int, variant: int = 0) -> AnimatedProp:
	return _add_animated_prop(kind, grid_position, scale_value, flip, motion, variant)


func add_interactive_prop(kind: String, grid_position: Vector2, display_name: String, lore: String, variant: int = 0, rewards: Dictionary = {}) -> void:
	_add_interactive_prop(kind, grid_position, display_name, lore, variant, rewards)


func spawn_npc(npc_id: String, display_name: String, dialogue_id: String, grid: Vector2, palette: Dictionary, race: String, role: String = "") -> void:
	_spawn_npc(npc_id, display_name, dialogue_id, grid, palette, race, role)


func environment_data() -> Dictionary:
	return _environment()


func can_add_interactive_prop() -> bool:
	return _interactive_props.size() < MAX_INTERACTIVE_PROPS


func register_portal(portal: RegionPortal) -> void:
	if portal != null and not _portals.has(portal):
		_portals.append(portal)

const VILLAGE_TREE_KINDS := {
	"glade_tree": true, "ancient_tree": true, "willow_tree": true, "birch_tree": true,
	"pine_tree": true, "blossom_tree": true, "dead_tree": true,
}


func _suppress_streamed_village_tree(kind: String, world_pos: Vector2) -> bool:
	if region_id != DEFAULT_REGION_ID:
		return false
	if not VILLAGE_TREE_KINDS.has(kind):
		return false
	# Authored village composition replaces streamed trees in the village design area
	# (center ~spawn 8,8 => (0,256), radius tuned to cover perimeter groups/clearing).
	var village_center := IsoMath.grid_to_world(8.0, 8.0)
	return world_pos.distance_to(village_center) <= 520.0

func _record_texture(kind: String, variant: int) -> void:
	if prop_factory_component != null:
		prop_factory_component.record_texture(kind, variant)

func _record_glow(color: Color) -> void:
	if prop_factory_component != null:
		prop_factory_component.record_glow(color)

func _bump_prop_count(kind: String) -> void:
	if prop_factory_component != null:
		prop_factory_component.bump_prop_count(kind)

func _build_village() -> void:
	if greenward_builder_component != null:
		greenward_builder_component.build_village()
		return


func _spawn_npc(npc_id: String, display_name: String, dialogue_id: String, grid: Vector2, palette: Dictionary, race: String, role: String = "") -> void:
	if entity_spawner != null:
		entity_spawner.spawn_npc(npc_id, display_name, dialogue_id, grid, palette, race, role)
		return


func _build_river() -> void:
	if greenward_builder_component != null:
		greenward_builder_component.build_river()
		return


func _add_animated_prop(kind: String, grid_position: Vector2, scale_value: float, flip: bool, motion: int, variant: int = 0) -> AnimatedProp:
	return prop_factory_component.add_animated_prop(kind, grid_position, scale_value, flip, motion, variant) if prop_factory_component != null else null

func _build_landmarks() -> void:
	if greenward_builder_component != null:
		greenward_builder_component.build_landmarks()
		return


func _build_extra_landmarks() -> void:
	if greenward_builder_component != null:
		greenward_builder_component.build_extra_landmarks()
		return


func _build_elder_hollow_territory() -> void:
	if greenward_builder_component != null:
		greenward_builder_component.build_elder_hollow_territory()
		return


func _build_fallen_matron_territory() -> void:
	if greenward_builder_component != null:
		greenward_builder_component.build_fallen_matron_territory()
		return


func _build_paths() -> void:
	if greenward_builder_component != null:
		greenward_builder_component.build_paths()
		return


func _build_extra_interactive_and_animated() -> void:
	if greenward_builder_component != null:
		greenward_builder_component.build_extra_interactive_and_animated()
		return


func _build_generic_region() -> void:
	if region_builder_component != null:
		region_builder_component.build_generic_region()
		return


func _spawn_region_portals() -> void:
	if region_builder_component != null:
		region_builder_component.spawn_region_portals()
		return


func _environment() -> Dictionary:
	return region_context_component.environment() if region_context_component != null else {}


func current_zone() -> String:
	return region_context_component.current_zone() if region_context_component != null else "wilderness"


func _zone_for_poi(poi_type: String, poi_name: String) -> String:
	return region_context_component.zone_for_poi(poi_type, poi_name) if region_context_component != null else "grove"


func region_display_name() -> String:
	return region_context_component.region_display_name() if region_context_component != null else str(region.get("name", "Greenward"))

func region_graph() -> RegionGraph:
	return RegionGraph.new(ContentDB.regions)


# --------------------------------------------------------------- monsters

func _spawn_monsters() -> void:
	monsters = entity_spawner.spawn_monsters() if entity_spawner != null else []


# --------------------------------------------------------------- ambient

func _setup_ambient() -> void:
	var effects := get_node_or_null("AmbientEffects") as Node2D
	if effects == null:
		push_error("GreenwardWorld requires its authored AmbientEffects scene")
		return
	ambient_effects_component.configure(effects, day_night.is_night())
	ambient = ambient_effects_component.ambient
	fireflies = ambient_effects_component.fireflies
	rain = ambient_effects_component.rain

func _setup_effect_follow_component() -> void:
	effect_follow_component.configure(ambient, fireflies, rain, fog_quad)

func _setup_weather() -> void:
	var config := presentation_config as EnvironmentPresentationConfig
	var presentation_bias: Array = config.weather_bias if config != null else []
	weather = weather_component.configure(region, presentation_bias)

func _setup_presentation_config() -> void:
	presentation_config_component.configure(
		presentation_config, day_night, ambient_effects_component,
		fog_component, lighting_component, water_and_bridges, ambient_sound_root
	)

func _setup_fog() -> void:
	fog_component.configure(
		player.position if player != null else Vector2.ZERO,
		FOG_SIZE,
		Color(0.8, 0.88, 0.95, 1.0),
		0.08,
		GreenwardStyle.performance_tier() != "mobile"
	)
	fog_material = fog_component.fog_material
	fog_quad = fog_component.quad

func _setup_wildlife() -> void:
	if entity_spawner != null:
		entity_spawner.spawn_wildlife()


func _setup_interactive_props() -> void:
	if entity_spawner != null:
		entity_spawner.spawn_interactive_props()


func _add_interactive_prop(kind: String, grid_position: Vector2, display_name: String, lore: String, variant: int = 0, rewards: Dictionary = {}) -> void:
	if prop_factory_component != null:
		prop_factory_component.add_interactive_prop(kind, grid_position, display_name, lore, variant, rewards)

func _gate_animated_props() -> void:
	if day_night_presentation_component != null:
		day_night_presentation_component.gate_animated_props()

func _apply_atmosphere() -> void:
	if atmosphere_component != null:
		atmosphere_component.apply_atmosphere()


func _apply_rain(wp: Dictionary) -> void:
	if atmosphere_component != null:
		atmosphere_component.apply_rain(wp)

func _on_phase_changed(phase_name: String) -> void:
	if day_night_presentation_component != null:
		day_night_presentation_component.on_phase_changed(phase_name)
	else:
		_apply_atmosphere()
		_apply_village_day_phase(phase_name)


func _apply_village_day_phase(phase_name: String = "") -> void:
	if day_night_presentation_component != null:
		day_night_presentation_component.apply_village_day_phase(phase_name)


func current_area_name() -> String:
	return region_context_component.current_area_name() if region_context_component != null else region_display_name()


func day_phase() -> String:
	return day_night_presentation_component.day_phase() if day_night_presentation_component != null else (day_night.phase_at(day_night.time_of_day) if day_night != null else "Day")

func visual_style_report() -> Dictionary:
	var prop_total := 0
	for key in _prop_kind_counts.keys():
		prop_total += int(_prop_kind_counts[key])
	var player_art: Dictionary = {}
	if player != null and is_instance_valid(player) and player.visual != null:
		player_art = player.visual.character_art_report()
	return {
		"phase": day_phase(),
		"weather_state": weather.current_state if weather != null else WeatherDirector.CLEAR,
		"weather_state_name": WeatherDirector.state_name(weather.current_state) if weather != null else "clear",
		"weather_intensity": weather.intensity if weather != null else 0.0,
		"performance_tier": GreenwardStyle.performance_tier(),
		"prop_kind_counts": _prop_kind_counts.duplicate(),
		"prop_total": prop_total,
		"cached_textures": _texture_keys.size(),
		"chunks_loaded": loaded_chunks.size(),
		"animated_props": _animated_props.size(),
		"interactive_props": _interactive_props.size(),
		"light_count": _lights.size(),
		"fog_enabled": fog_quad != null and fog_quad.visible,
		"rain_amount": rain.amount if rain != null else 0,
		"particle_cap": GreenwardStyle.MAX_PARTICLES,
		"prop_cap": GreenwardStyle.MAX_PROPS_PER_CHUNK,
		"region_id": region_id,
		"region_name": region_display_name(),
		"zone": current_zone(),
		"entry_points": region.get("entry_points", {}),
		"connections": region.get("connections", []),
		"world_origin": region.get("world_origin", [0, 0]),
		"portals": _portals.size(),
		"prepared_chunks": _preparer.stats() if _preparer != null else { "pending": 0, "cached": 0, "capacity": 0 },
		# ---- PART 5 (World Presentation): additive reporting keys ----
		"visual_standards": visual_standards_report(),
		"visual_standards_valid": _visual_standards_valid,
		"character_art": player_art,
		"prop_kind_total": ProceduralArt.prop_kinds().size(),
	}


# =============================================== PART 5: World Presentation
# COMPOSITIONAL / STANDARDS improvements ONLY — ZERO final assets, every visual
# is still a PROCEDURAL PLACEHOLDER. These functions ADD reporting/validation
# and two bounded prop compositions; they do NOT reposition existing nodes and
# do NOT change any public API or the _ready() order.

## Validate the WorldVisualStandards contract ONCE (cheap, pure data), apply the
## region tint to ambient/fog where safe, and store the result for reporting.
## This is validation + a gentle colour blend — NO node repositioning. Every
## node / ShaderMaterial access is guarded so _ready() can never be aborted.
func apply_visual_standards() -> void:
	if visual_standards_component != null:
		visual_standards_component.apply()

func visual_standards_report() -> Dictionary:
	return visual_standards_component.report() if visual_standards_component != null else {}

func _build_greenward_gate_composition() -> void:
	if greenward_builder_component != null:
		greenward_builder_component.build_greenward_gate_composition()
		return


