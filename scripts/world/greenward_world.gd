class_name GreenwardWorld
extends Node2D
## The playable Greenward slice: streamed isometric terrain, a village hub,
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

const DEFAULT_REGION_ID := "greenward"
var region_id: String = DEFAULT_REGION_ID
var entry_point: String = ""
const SAVE_POSITION_INTERVAL := 1.0

# Atmosphere / performance caps (bounded; sourced from GreenwardStyle where
# meaningful). No unbounded node spawning anywhere below.
const FOG_SIZE := Vector2(2600.0, 1700.0)
const ANIM_VISIBLE_RANGE := 1200.0
const MAX_INTERACTIVE_PROPS := 8
const MAX_ANIMATED_PROPS := 40
const MAX_LIGHTS := 20
const ATMO_INTERVAL := 0.25
const GENERIC_PROP_CAP := 24

# Cheap, zone-specific ambient tints (derived from the nearest POI at runtime).
const ZONE_TINTS := {
	"village": "#ffd9a0",
	"ruin": "#7fe3e0",
	"grove": "#b48adf",
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

var _save_accumulator: float = 0.0
var _atmo_accumulator: float = 0.0
var _last_area_name: String = ""
var _last_phase: String = ""

var _animated_props: Array = []
var _interactive_props: Array = []
var _lights: Array = []
var _prop_kind_counts: Dictionary = {}
var _bridge_positions: Array = []
var _bridge_radius: float = 40.0
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
	chunk_size = int(region.get("chunk_size", 16))
	streamer = ChunkStreamer.new(chunk_size, int(region.get("load_radius", 1)))
	_preparer = ChunkPreparer.new()

	# Preserved _ready() order for Greenward: materials -> layers -> noise ->
	# day/night -> spawn_player -> village/river/landmarks -> monsters ->
	# ambient/weather/fog -> wildlife/interactives -> streaming -> world_ready.
	_setup_materials()
	_setup_layers()
	_setup_noise()
	_setup_day_night()
	_spawn_player()
	if region_id == DEFAULT_REGION_ID:
		_build_village()          # includes _build_river()
		_build_landmarks()
		_build_extra_landmarks()  # PART 4: extra recognisable landmarks
		_build_paths()            # PART 4: readable routes
	else:
		_build_generic_region()   # data-driven builder for other regions
	_spawn_monsters()
	_setup_ambient()
	_setup_weather()
	_setup_fog()
	if region_id == DEFAULT_REGION_ID:
		_setup_wildlife()
		_setup_interactive_props()
		_build_extra_interactive_and_animated()  # PART 4
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
	EventBus.world_ready.emit()


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var grid := IsoMath.world_to_grid(player.position)
	var center := streamer.center_chunk(grid)
	if center != current_center:
		current_center = center
		_update_streaming(grid)

	if ambient != null:
		ambient.global_position = player.position
	if fireflies != null:
		fireflies.global_position = player.position
	if rain != null:
		rain.global_position = player.position + Vector2(0, -420)
	if fog_quad != null:
		fog_quad.global_position = player.position

	if weather != null:
		weather.tick(delta)

	_save_accumulator += delta
	if _save_accumulator >= SAVE_POSITION_INTERVAL:
		_save_accumulator = 0.0
		GameState.set_player_position(player.position)
		GameState.set_region_position(region_id, player.position)

	_atmo_accumulator += delta
	if _atmo_accumulator >= ATMO_INTERVAL:
		_atmo_accumulator = 0.0
		_apply_atmosphere()

	_gate_animated_props()

	# PART 5: at most ONE prepared chunk per frame (main-thread, frame-sliced).
	_prepare_one_chunk(grid)


# --------------------------------------------------------------- base setup

func _setup_materials() -> void:
	terrain_material = ShaderMaterial.new()
	terrain_material.shader = load("res://resources/shaders/terrain.gdshader")
	water_material = ShaderMaterial.new()
	water_material.shader = load("res://resources/shaders/water.gdshader")
	wind_material = ShaderMaterial.new()
	wind_material.shader = load("res://resources/shaders/wind_sway.gdshader")


func _setup_layers() -> void:
	terrain_layer = Node2D.new()
	terrain_layer.name = "Terrain"
	terrain_layer.z_index = -10
	add_child(terrain_layer)

	entities = Node2D.new()
	entities.name = "Entities"
	entities.y_sort_enabled = true
	add_child(entities)


func _setup_noise() -> void:
	elevation = FastNoiseLite.new()
	elevation.seed = int(region.get("noise_seed", 1337))
	elevation.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	elevation.frequency = 0.032
	elevation.fractal_octaves = 3

	moisture = FastNoiseLite.new()
	moisture.seed = int(region.get("noise_seed", 1337)) + 91
	moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	moisture.frequency = 0.055
	moisture.fractal_octaves = 2


func _setup_day_night() -> void:
	day_night = DayNight.new()
	day_night.day_length_seconds = 600.0
	add_child(day_night)
	day_night.phase_changed.connect(_on_phase_changed)


func _spawn_player() -> void:
	player = Player.new()
	player.name = "Player"
	var placed := false

	# 1) A travel entry point wins (the destination region's entry_points id).
	if not entry_point.is_empty():
		var eps: Variant = region.get("entry_points", {})
		if typeof(eps) == TYPE_DICTIONARY and eps.has(entry_point):
			var g: Variant = eps[entry_point]
			if typeof(g) == TYPE_ARRAY and g.size() == 2:
				player.position = IsoMath.grid_to_world(float(g[0]), float(g[1]))
				placed = true

	# 2) Otherwise resume this region's own saved position.
	if not placed and GameState.player_region == region_id and GameState.has_region_position(region_id):
		player.position = GameState.region_position(region_id)
		placed = true

	# 3) Legacy single-slot position only applies to the DEFAULT (Greenward) region.
	if not placed and GameState.has_player_position and GameState.player_position.length_squared() > 0.0 and region_id == DEFAULT_REGION_ID:
		player.position = GameState.player_position
		placed = true

	# 4) Fall back to the region's spawn_grid.
	if not placed:
		var spawn: Array = region.get("spawn_grid", [8, 8])
		player.position = IsoMath.grid_to_world(float(spawn[0]), float(spawn[1]))

	entities.add_child(player)
	GameState.set_player_position(player.position)


# --------------------------------------------------------------- streaming

func _update_streaming(player_grid: Vector2) -> void:
	var needed: Array = streamer.needed_chunks(player_grid)
	var needed_set: Dictionary = {}
	for coord in needed:
		needed_set[coord] = true

	for coord in loaded_chunks.keys():
		if not needed_set.has(coord):
			_unload_chunk(coord)

	for coord in needed:
		if not loaded_chunks.has(coord):
			_load_chunk(coord)


func _load_chunk(coord: Vector2i) -> void:
	var data: Dictionary
	if _preparer != null and _preparer.has_prepared(coord):
		# Frame-sliced background preparation already built this chunk. Take it
		# (removes it from the cache + LRU) and stop the world tracking its nodes.
		data = _preparer.take(coord)
		_prepared_nodes.erase(coord)
	else:
		# Synchronous fallback keeps loaded_chunks populated IMMEDIATELY on the
		# first frame (and for any never-prefetched coord) — tests stay green.
		data = ChunkBuilder.build(
			coord, region, elevation, moisture, terrain_material, water_material
		)
	# `data.detail` (the ground-cover MultiMeshInstance2D) is ALREADY parented
	# as a child of `data.terrain` by ChunkBuilder. DO NOT re-add or re-parent it:
	# parenting `data.terrain` here renders it (one draw call) and frees it with
	# the terrain on chunk unload (no orphan node leaks).
	terrain_layer.add_child(data.terrain)
	if data.water != null:
		data.water.z_index = 1
		terrain_layer.add_child(data.water)

	# Water is traversable but slows movement. No collision bodies are created;
	# water detection uses is_water_world() for speed reduction and visual effects.

	var prop_nodes: Array = []
	for entry in data.props:
		var variant := int(entry.get("variant", 0))
		var scale_value := float(entry.scale)
		if bool(entry.get("detail", false)):
			scale_value *= 0.88
		var sprite := _make_prop_sprite(str(entry.type), entry.position, scale_value, bool(entry.flip), variant)
		if sprite != null:
			entities.add_child(sprite)  # props stay y-sorted in `entities`
			prop_nodes.append(sprite)

	loaded_chunks[coord] = {
		"terrain": data.terrain,
		"water": data.water,
		"props": prop_nodes,
	}


func _unload_chunk(coord: Vector2i) -> void:
	var data: Dictionary = loaded_chunks[coord]
	for key in ["terrain", "water"]:
		var node: Node = data.get(key, null)
		if node != null and is_instance_valid(node):
			node.queue_free()
	for prop in data.get("props", []):
		if is_instance_valid(prop):
			prop.queue_free()
	loaded_chunks.erase(coord)


# --------------------------------------------------------------- water / walkability
func is_water_world(world_pos: Vector2) -> bool:
	if elevation == null:
		return false
	var grid := IsoMath.world_to_grid(world_pos)
	var elev := elevation.get_noise_2d(grid.x, grid.y)
	var wl := get_water_level()
	return elev < wl

func is_walkable(world_pos: Vector2) -> bool:
	if not is_water_world(world_pos):
		return true
	return is_near_bridge(world_pos)

func is_near_bridge(world_pos: Vector2) -> bool:
	for bp in _bridge_positions:
		if world_pos.distance_to(bp) <= _bridge_radius:
			return true
	return false

func world_to_grid(world_pos) -> Vector2:
	return IsoMath.world_to_grid(world_pos)

func get_water_level() -> float:
	var biome: Variant = region.get("biome", {})
	if typeof(biome) != TYPE_DICTIONARY:
		biome = {}
	return float(biome.get("water_level", -0.22))

func get_bridge_positions() -> Array:
	return _bridge_positions

func get_bridge_radius() -> float:
	return _bridge_radius


# ---------------------------------- main-thread chunk preparation (PART 5)
# NO THREADS: MultiMesh / Image / ShaderMaterial creation and every scene-tree
# operation are NOT thread-safe in Godot 4. Chunk generation is therefore kept
# on the MAIN THREAD and FRAME-SLICED — at most ONE chunk is built per frame in
# _process. ChunkPreparer is the deterministic, bounded LRU scheduling cache.

func _prepare_one_chunk(player_grid: Vector2) -> void:
	if _preparer == null:
		return
	# Bounded prefetch ring just OUTSIDE the loaded ring.
	var ring: Array = []
	var center := streamer.center_chunk(player_grid)
	var outer := streamer.radius + 1
	for y in range(-outer, outer + 1):
		for x in range(-outer, outer + 1):
			if absi(x) <= streamer.radius and absi(y) <= streamer.radius:
				continue
			var c := center + Vector2i(x, y)
			if not loaded_chunks.has(c):
				ring.append(c)
	_preparer.request_many(ring)

	var coord := _preparer.next_pending()
	if coord == ChunkPreparer.EMPTY_COORD:
		return
	if loaded_chunks.has(coord) or _preparer.has_prepared(coord):
		return
	# ONE build per frame; store the result in the preparer's bounded cache.
	var chunk_data := ChunkBuilder.build(
		coord, region, elevation, moisture, terrain_material, water_material
	)
	_preparer.store(coord, chunk_data)
	_prepared_nodes[coord] = chunk_data
	_reconcile_prepared_cache()


func _reconcile_prepared_cache() -> void:
	# The WORLD owns the prepared data's nodes. On LRU eviction (or take) the
	# preparer no longer references them; free anything NOT parented to the tree.
	if _prepared_nodes.is_empty():
		return
	var stale: Array = []
	for coord in _prepared_nodes.keys():
		if not _preparer.has_prepared(coord):
			stale.append(coord)
	for coord in stale:
		var data: Dictionary = _prepared_nodes[coord]
		_free_chunk_data(data)
		_prepared_nodes.erase(coord)


func _free_chunk_data(data: Dictionary) -> void:
	# `detail` is ALREADY a child of `terrain`; freeing terrain frees it. Only
	# terrain + water are standalone nodes. `props` is plain Dictionary data
	# (the world turns those into Sprite2D nodes only when a chunk is loaded).
	var terrain: Node = data.get("terrain", null)
	if terrain != null and is_instance_valid(terrain) and not terrain.is_inside_tree():
		terrain.free()
	var water: Node = data.get("water", null)
	if water != null and is_instance_valid(water) and not water.is_inside_tree():
		water.free()


func _clear_prepared() -> void:
	if _preparer == null:
		return
	for coord in _prepared_nodes.keys():
		_free_chunk_data(_prepared_nodes[coord])
	_prepared_nodes.clear()
	_preparer.clear()


func _exit_tree() -> void:
	# Free any prepared-but-never-used chunk nodes (they are NOT in the scene
	# tree, so the tree will not free them for us). Avoids ObjectDB leaks.
	_clear_prepared()


func _make_prop_sprite(type: String, world_position: Vector2, scale_value: float, flip: bool, variant: int = 0) -> Sprite2D:
	var texture := ProceduralArt.prop_texture(type, variant)
	if texture == null:
		return null
	_record_texture(type, variant)
	_bump_prop_count(type)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height() + 6.0)
	sprite.position = world_position
	sprite.scale = Vector2.ONE * scale_value
	sprite.flip_h = flip
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if type in FOLIAGE_KINDS:
		sprite.material = wind_material
	return sprite


func _add_prop(type: String, grid_position: Vector2, scale_value: float = 1.0, flip: bool = false, variant: int = 0) -> Sprite2D:
	if "bridge" in type or type == "wooden_bridge" or type == "stone_bridge":
		_bridge_positions.append(IsoMath.grid_to_world(grid_position.x, grid_position.y))
	var sprite := _make_prop_sprite(type, IsoMath.grid_to_world(grid_position.x, grid_position.y), scale_value, flip, variant)
	if sprite != null:
		entities.add_child(sprite)
	return sprite


func _add_light(grid_position: Vector2, color: Color, energy: float, light_scale: float) -> void:
	if _lights.size() >= MAX_LIGHTS:
		return
	var light := PointLight2D.new()
	light.texture = ProceduralArt.soft_glow(color, 128)
	light.color = color
	light.energy = energy
	light.texture_scale = light_scale
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.position = IsoMath.grid_to_world(grid_position.x, grid_position.y) + Vector2(0, -36)
	entities.add_child(light)
	_lights.append({ "light": light, "energy": energy, "color": color })
	_record_glow(color)


func _record_texture(kind: String, variant: int) -> void:
	_texture_keys["prop:%s|%d" % [kind, variant]] = true


func _record_glow(color: Color) -> void:
	_texture_keys["glow:%s" % color.to_html()] = true


func _bump_prop_count(kind: String) -> void:
	_prop_kind_counts[kind] = int(_prop_kind_counts.get(kind, 0)) + 1


# --------------------------------------------------------------- village hub

func _build_village() -> void:
	# Varied buildings around the spawn clearing (huts + cottages).
	var huts := [
		{ "grid": Vector2(5, 5), "scale": 1.0, "flip": false, "variant": 0 },
		{ "grid": Vector2(11, 6), "scale": 0.92, "flip": true, "variant": 1 },
		{ "grid": Vector2(6, 11), "scale": 0.95, "flip": false, "variant": 0 },
		{ "grid": Vector2(10, 11), "scale": 1.05, "flip": true, "variant": 1 },
	]
	for hut in huts:
		_add_prop("hut", hut.grid, hut.scale, hut.flip, hut.variant)

	var cottages := [
		{ "grid": Vector2(4.2, 8.4), "scale": 0.9, "flip": false, "variant": 1 },
		{ "grid": Vector2(12.2, 9.2), "scale": 0.95, "flip": true, "variant": 2 },
		{ "grid": Vector2(8.5, 12.4), "scale": 0.85, "flip": false, "variant": 0 },
	]
	for c in cottages:
		_add_prop("cottage", c.grid, c.scale, c.flip, c.variant)

	# Village fixtures: well, shrine, signposts, barrels, a cart.
	_add_prop("well", Vector2(8, 5.2), 1.0, false, 1)
	_add_prop("shrine", Vector2(4.5, 11.5), 0.9, false, 0)
	_add_prop("signpost", Vector2(9.5, 5.0), 1.0, false, 1)
	_add_prop("signpost", Vector2(4.0, 9.6), 0.9, true, 0)
	_add_prop("barrel", Vector2(6.2, 5.0), 0.9, false, 0)
	_add_prop("barrel", Vector2(10.6, 11.8), 0.85, true, 1)
	_add_prop("cart", Vector2(11.4, 10.2), 0.9, false, 0)

	# Phase-4 detailed landmark buildings around the village green. _add_light()
	# self-caps at MAX_LIGHTS, so these additions respect all existing caps.
	_add_prop("market_stall", Vector2(7.4, 6.4), 0.95, false, 0)
	_add_prop("gazebo", Vector2(12.6, 11.6), 0.9, false, 1)
	_add_light(Vector2(7.4, 6.4), GreenwardStyle.LIGHT.warm_lantern, 0.9, 2.0)

	# A proper run of warm lanterns with PointLight2D glows (GreenwardStyle).
	var lanterns := [
		Vector2(7, 6), Vector2(10, 7), Vector2(6, 9), Vector2(9, 10),
		Vector2(5.4, 7.0), Vector2(11.2, 7.6), Vector2(8.0, 11.2),
		Vector2(6.6, 4.4), Vector2(9.4, 4.6),
	]
	for index in lanterns.size():
		_add_prop("lantern", lanterns[index], 1.0, index % 2 == 0, index % 2)
		if index % 2 == 0:
			_add_light(lanterns[index], GreenwardStyle.LIGHT.warm_lantern, 1.15, 2.2)

	# Wisp lanterns (warm/violet magic).
	var wisps := [Vector2(7.4, 9.2), Vector2(9.6, 8.6), Vector2(5.0, 10.4)]
	for index in wisps.size():
		_add_prop("wisp_lantern", wisps[index], 0.95, index % 2 == 0, index % 2)
		if index == 0:
			_add_light(wisps[index], GreenwardStyle.MAGIC.violet_light, 0.9, 2.0)

	# Waypoint (cool teal).
	_add_prop("waypoint", Vector2(10, 8), 1.0, false, 0)
	_add_light(Vector2(10, 8), GreenwardStyle.MAGIC.teal, 1.3, 3.0)

	# Fences.
	var fences := [
		Vector2(4, 4), Vector2(4.9, 4), Vector2(12, 5), Vector2(12.9, 5),
		Vector2(4, 12), Vector2(4.9, 12), Vector2(11.9, 12),
		Vector2(3.4, 6.5), Vector2(3.4, 7.4), Vector2(12.8, 9.6),
	]
	for index in fences.size():
		_add_prop("fence", fences[index], 1.0, index % 2 == 0, index % 2)

	# Flower clusters / ferns / bushes / ground cover.
	var greenery := [
		["bush", Vector2(5.5, 7.5), 0.9], ["bush", Vector2(10.6, 10.4), 0.85],
		["flower_cluster", Vector2(7.6, 8.7), 1.0], ["flower_cluster", Vector2(9.1, 6.8), 0.9],
		["fern", Vector2(6.4, 8.2), 0.9], ["fern", Vector2(11.0, 8.4), 0.85],
		["berry_bush", Vector2(5.2, 9.4), 0.9], ["berry_bush", Vector2(10.2, 6.2), 0.85],
		["flower_cluster", Vector2(8.2, 6.4), 0.8], ["tall_grass", Vector2(7.0, 10.8), 0.9],
		["fern", Vector2(9.6, 11.4), 0.8], ["glow_mushroom", Vector2(6.8, 6.2), 0.9],
	]
	for index in greenery.size():
		var g: Array = greenery[index]
		_add_prop(str(g[0]), g[1], float(g[2]), index % 2 == 0, index % 3)

	# Coherent decorative river line + bridges (waterfalls/foam are animated).
	_build_river()

	# The three quest/dialogue NPCs: EXACT ids + dialogue ids + positions.
	_spawn_npc("elder_maelin", "Elder Maelin", "elder_maelin", Vector2(6, 7), {
		"hair": "#d8d8c0", "primary": "#4a5a3a", "secondary": "#c9a45a",
		"accent": "#9df5cf", "skin": "#e8c8a8",
	}, "Elf", "Village Elder")
	_spawn_npc("merchant_sera", "Sera Quill", "merchant_sera", Vector2(10, 7), {
		"hair": "#c96f3a", "primary": "#5a3a2a", "secondary": "#e8c27a",
		"accent": "#ffd27a", "skin": "#e8b890",
	}, "Human", "Traveling Merchant")
	_spawn_npc("wanderer_pip", "Pip", "wanderer_pip", Vector2(7, 10), {
		"hair": "#f2e2a8", "primary": "#3f5a6b", "secondary": "#8fd9c4",
		"accent": "#ffeaa0", "skin": "#f6e3cf",
	}, "Beastkin", "Wandering Scout")


func _spawn_npc(npc_id: String, display_name: String, dialogue_id: String, grid: Vector2, palette: Dictionary, race: String, role: String = "") -> void:
	var npc := WorldNPC.new()
	npc.role = role  # public presentation var (setup() signature is unchanged)
	npc.setup(npc_id, display_name, dialogue_id, palette, race)
	npc.position = IsoMath.grid_to_world(grid.x, grid.y)
	entities.add_child(npc)
	npcs.append(npc)


# --------------------------------------------------------------- river line

func _build_river() -> void:
	# A coherent decorative river line just south of the village. (The terrain
	# water ribbon in ChunkBuilder is far to the south; these are readable
	# set-dressing props placed along a gentle meander near the hub.)
	var water_props := [
		["river_rock", Vector2(3.5, 13.4), 0.9], ["river_rock", Vector2(5.0, 13.8), 1.0],
		["river_rock", Vector2(7.0, 14.1), 0.85], ["river_rock", Vector2(11.0, 14.3), 1.0],
		["river_rock", Vector2(13.2, 14.0), 0.9],
		["reeds", Vector2(4.2, 12.9), 0.9], ["reeds", Vector2(6.2, 13.2), 1.0],
		["reeds", Vector2(12.2, 13.6), 0.9], ["lily_pad", Vector2(8.4, 13.9), 0.9],
		["lily_pad", Vector2(10.2, 14.2), 0.85], ["lily_pad", Vector2(5.6, 14.4), 0.8],
	]
	for index in water_props.size():
		var wp: Array = water_props[index]
		_add_prop(str(wp[0]), wp[1], float(wp[2]), index % 2 == 0, index % 2)

	# Animated waterfalls (flicker) + foam ripples (pulse).
	var waterfalls := [Vector2(3.0, 13.0), Vector2(14.0, 13.6)]
	for index in waterfalls.size():
		_add_animated_prop("waterfall", waterfalls[index], 1.0, false, AnimatedProp.MOTION_FLICKER, 0)
	var foams := [
		Vector2(4.6, 13.6), Vector2(6.6, 14.0), Vector2(8.8, 14.2),
		Vector2(10.8, 14.1), Vector2(12.6, 13.9),
	]
	for index in foams.size():
		_add_animated_prop("foam_ripple", foams[index], 1.0, index % 2 == 0, AnimatedProp.MOTION_PULSE, 0)

	# Two crossings: wooden + stone bridges.
	_add_prop("wooden_bridge", Vector2(8.8, 13.5), 1.0, false, 0)
	_add_prop("stone_bridge", Vector2(12.4, 13.8), 0.9, false, 1)
	_add_light(Vector2(3.0, 13.0), GreenwardStyle.WATER.glint, 0.7, 1.8)


func _add_animated_prop(kind: String, grid_position: Vector2, scale_value: float, flip: bool, motion: int, variant: int = 0) -> AnimatedProp:
	if _animated_props.size() >= MAX_ANIMATED_PROPS:
		return null
	var ap := AnimatedProp.new()
	ap.setup(kind, IsoMath.grid_to_world(grid_position.x, grid_position.y), scale_value, flip, motion, variant)
	entities.add_child(ap)
	_animated_props.append(ap)
	_record_texture(kind, variant)
	_bump_prop_count(kind)
	return ap


# --------------------------------------------------------------- landmarks

func _build_landmarks() -> void:
	# ---- The Listening Stones (cool teal ruin) ----
	var ruin_center := Vector2(2, 20)
	var offsets := [Vector2(-1.4, 0), Vector2(1.4, 0), Vector2(0, -1.4), Vector2(0, 1.4)]
	for index in offsets.size():
		_add_prop("ruin_pillar", ruin_center + offsets[index], 0.9 + 0.1 * (index % 2), index % 2 == 0, index % 2)
	_add_prop("ruin_arch", ruin_center + Vector2(0, -2.2), 1.0, false, 0)
	_add_prop("rune_stone", ruin_center + Vector2(-2.0, 1.0), 0.9, false, 1)
	_add_prop("rune_stone", ruin_center + Vector2(2.0, 1.2), 0.85, true, 0)
	_add_prop("crystal_cluster", ruin_center + Vector2(0, 0.2), 1.2, false, 1)
	_add_prop("spirit_bloom", ruin_center + Vector2(-1.2, -1.4), 0.9, false, 2)
	_add_prop("glow_mushroom", ruin_center + Vector2(1.4, -1.2), 0.9, true, 1)
	_add_prop("wisp_lantern", ruin_center + Vector2(2.0, -0.6), 0.9, false, 0)
	_add_light(ruin_center, GreenwardStyle.MAGIC.teal, 1.4, 2.6)
	_add_light(ruin_center + Vector2(0, -2.2), GreenwardStyle.LIGHT.magic, 1.0, 2.0)

	# ---- The Hollowed Grove (dead trees, darker/corrupted violet palette) ----
	var grove_center := Vector2(26, 16)
	var grove_offsets := [
		Vector2(-2.6, -0.8), Vector2(2.6, -0.8), Vector2(-2.2, 1.8),
		Vector2(2.2, 1.8), Vector2(0, -2.8), Vector2(0, 2.8),
	]
	for index in grove_offsets.size():
		_add_prop("dead_tree", grove_center + grove_offsets[index], 0.85, index % 2 == 0, index % 2)
	_add_prop("crystal_cluster", grove_center + Vector2(-1.5, 0.5), 1.0, true, 2)
	_add_prop("crystal_cluster", grove_center + Vector2(1.5, 0.5), 0.9, false, 1)
	_add_prop("rune_stone", grove_center + Vector2(0, -1.8), 0.95, false, 1)
	_add_prop("glow_mushroom", grove_center + Vector2(-2.0, 1.4), 0.9, false, 1)
	_add_prop("glow_mushroom", grove_center + Vector2(2.0, 1.2), 0.85, true, 0)
	_add_prop("spirit_bloom", grove_center + Vector2(0.8, 1.6), 0.9, false, 1)
	_add_light(grove_center, GreenwardStyle.MAGIC.violet, 1.2, 2.8)
	_add_light(grove_center + Vector2(-1.5, 0.5), GreenwardStyle.MAGIC.violet_light, 0.9, 1.8)

	# ---- NEW: Moonpetal Shrine (magical wisp glade) ----
	var glade := Vector2(18, 5)
	var glade_trees := [
		["birch_tree", Vector2(16.0, 3.6)], ["blossom_tree", Vector2(20.0, 3.8)],
		["willow_tree", Vector2(17.0, 6.6)], ["pine_tree", Vector2(19.6, 6.4)],
	]
	for index in glade_trees.size():
		_add_prop(str(glade_trees[index][0]), glade_trees[index][1], 0.9, index % 2 == 0, index % 3)
	_add_prop("shrine", glade, 1.0, false, 1)
	_add_prop("spirit_bloom", glade + Vector2(-1.4, 0.6), 1.0, false, 0)
	_add_prop("spirit_bloom", glade + Vector2(1.4, 0.8), 0.9, true, 2)
	_add_prop("glow_mushroom", glade + Vector2(-1.0, 1.4), 0.9, false, 1)
	_add_prop("glow_mushroom", glade + Vector2(1.0, 1.6), 0.85, true, 0)
	_add_prop("crystal_cluster", glade + Vector2(0, -1.6), 1.0, false, 0)
	_add_prop("wisp_lantern", glade + Vector2(-1.8, -0.4), 0.9, false, 1)
	_add_prop("wisp_lantern", glade + Vector2(1.8, -0.2), 0.9, true, 0)
	_add_light(glade, GreenwardStyle.MAGIC.teal, 1.2, 2.6)
	_add_light(glade + Vector2(0, -1.6), GreenwardStyle.MAGIC.violet_light, 0.9, 1.8)
	_add_light(glade + Vector2(-1.8, -0.4), GreenwardStyle.LIGHT.warm_lantern, 0.8, 1.6)

	# Phase-4 detailed landmarks: a watchtower over the Listening Stones and a
	# moon shrine beside the Moonpetal glade. Lights self-cap at MAX_LIGHTS.
	_add_prop("watchtower", ruin_center + Vector2(-3.2, -1.8), 0.9, false, 0)
	_add_prop("moon_shrine", glade + Vector2(2.8, -0.6), 0.9, false, 0)
	_add_light(ruin_center + Vector2(-3.2, -1.8), GreenwardStyle.LIGHT.warm_lantern, 0.8, 1.8)
	_add_light(glade + Vector2(2.8, -0.6), GreenwardStyle.LIGHT.cool_moon, 1.0, 2.2)


# ------------------------------- PART 4: extra Greenward landmarks / routes
# All use EXISTING prop kinds and GreenwardStyle colours. Bounded by the MAX_*
# caps; interaction props never mutate GameState.

func _build_extra_landmarks() -> void:
	# 1) Hilltop watch — a recognisable ruin silhouette above the eastern rise.
	var watch := Vector2(30, 6)
	_add_prop("ruin_arch", watch, 1.1, false, 1)
	_add_prop("ruin_pillar", watch + Vector2(-1.6, 0.4), 0.9, false, 0)
	_add_prop("ruin_pillar", watch + Vector2(1.6, 0.4), 0.9, true, 1)
	_add_prop("crystal_cluster", watch + Vector2(0, 1.4), 1.1, false, 2)
	_add_prop("wisp_lantern", watch + Vector2(-1.2, -1.2), 0.9, false, 0)
	_add_prop("wisp_lantern", watch + Vector2(1.2, -1.2), 0.9, true, 1)
	_add_light(watch, GreenwardStyle.MAGIC.teal, 1.3, 2.6)
	_add_light(watch + Vector2(0, 1.4), GreenwardStyle.MAGIC.violet_light, 0.8, 1.8)
	if _interactive_props.size() < MAX_INTERACTIVE_PROPS:
		_add_interactive_prop("rune_stone", watch + Vector2(0, 2.2), "Hilltop Dial", "It points to a road the maps have forgotten.", 1)

	# 2) Market row — a readable cart/barrel/signpost/well composition near the hub.
	var market := Vector2(13, 8)
	_add_prop("cart", market, 1.0, false, 0)
	_add_prop("barrel", market + Vector2(-1.0, 0.6), 0.9, false, 0)
	_add_prop("barrel", market + Vector2(0.9, 0.8), 0.85, true, 1)
	_add_prop("signpost", market + Vector2(0.2, -1.0), 0.95, false, 1)
	_add_prop("well", market + Vector2(1.8, 0.2), 0.9, false, 1)
	_add_light(market, GreenwardStyle.LIGHT.warm_lantern, 1.0, 2.0)
	if _interactive_props.size() < MAX_INTERACTIVE_PROPS:
		_add_interactive_prop("signpost", market + Vector2(1.6, -1.0), "Trader's Sign", "Arrows scratch toward every corner of the glade.", 0)

	# 3) Lakeside composition — a dock + wooden bridge by the decorative river.
	var lakeside := Vector2(6.4, 15.0)
	_add_prop("dock", lakeside, 1.0, false, 0)
	_add_prop("wooden_bridge", lakeside + Vector2(2.0, 0.4), 0.95, false, 1)
	_add_prop("river_rock", lakeside + Vector2(-1.4, 0.6), 0.9, false, 0)
	_add_prop("reeds", lakeside + Vector2(1.2, 1.2), 0.9, false, 1)
	_add_light(lakeside, GreenwardStyle.WATER.glint, 0.9, 1.8)
	if _interactive_props.size() < MAX_INTERACTIVE_PROPS:
		_add_interactive_prop("dock", lakeside + Vector2(0.2, -1.0), "Old Mooring", "The rope is worn smooth by a hundred quiet departures.", 0)

	# PART 5 (World Presentation): a recognisable village-gate approach built
	# from the new silhouette kinds. Consistent with WorldVisualStandards (warm
	# lights, bottom-centre anchors, GreenwardStyle colours). ZERO final assets.
	_build_greenward_gate_composition()


func _build_paths() -> void:
	# Data-driven, readable marker runs from the village to the two landmarks.
	var routes := [
		[Vector2(8, 8), Vector2(2, 20)],   # village -> The Listening Stones
		[Vector2(8, 8), Vector2(26, 16)],  # village -> The Hollowed Grove
	]
	var way_kinds := ["signpost", "lantern", "stone_bridge", "wisp_lantern"]
	for r in routes.size():
		var a: Vector2 = routes[r][0]
		var b: Vector2 = routes[r][1]
		var perp := (b - a).normalized().orthogonal() * 0.8
		for i in 6:
			var t := float(i + 1) / 7.0
			var grid := a.lerp(b, t) + perp
			var kind := str(way_kinds[(r + i) % way_kinds.size()])
			_add_prop(kind, grid, 0.9, i % 2 == 0, i % 2)
			if i % 3 == 1:
				_add_light(grid, GreenwardStyle.LIGHT.warm_lantern, 0.7, 1.6)
	# AnimatedProp used SPARINGLY: two foam ripples near the river crossing.
	_add_animated_prop("foam_ripple", Vector2(7.0, 12.4), 0.9, false, AnimatedProp.MOTION_PULSE, 0)
	_add_animated_prop("foam_ripple", Vector2(9.4, 12.8), 0.9, true, AnimatedProp.MOTION_PULSE, 0)


func _build_extra_interactive_and_animated() -> void:
	# 1–2 more interactive locations (guarded by MAX_INTERACTIVE_PROPS).
	if _interactive_props.size() < MAX_INTERACTIVE_PROPS:
		_add_interactive_prop("wisp_lantern", Vector2(19.4, 4.0), "Shrine Wisp", "It leans toward the moonpetal bloom.", 1)
	if _interactive_props.size() < MAX_INTERACTIVE_PROPS:
		_add_interactive_prop("crystal_cluster", Vector2(27.2, 15.2), "Grove Shard", "Cold to the touch, and faintly singing.", 0)
	# A couple more AnimatedProps (waterfall / foam / wildlife), capped internally.
	_add_animated_prop("waterfall", Vector2(13.8, 13.4), 0.9, false, AnimatedProp.MOTION_FLICKER, 0)
	_add_animated_prop("foam_ripple", Vector2(5.2, 13.9), 0.9, false, AnimatedProp.MOTION_PULSE, 0)
	_add_animated_prop("butterfly", Vector2(9.0, 9.0), 0.85, true, AnimatedProp.MOTION_DRIFT, 0)


# ------------------------------- data-driven generic region (non-Greenward)

func _build_generic_region() -> void:
	# SMALL, bounded, data-driven builder for the second region. Uses ONLY
	# existing prop kinds (no new art kinds) and the region's ambient tint.
	var env := _environment()
	var tint := Color(str(env.get("ambient_tint", "#7fe3e0")))
	# PART 5 (World Presentation): a DISTINCT silver-birch / moonlit gate
	# composition for Moonpetal Hollow, with cool lights from this region's
	# ambient_tint. ZERO final assets — all procedural placeholder art.
	if region_id == "moonpetal_hollow":
		_build_moonpetal_hollow_composition(tint)
	var pois: Variant = region.get("pois", [])
	if typeof(pois) != TYPE_ARRAY:
		pois = []
	var cluster_kinds := [
		"birch_tree", "moss_rock", "fern", "flower_cluster",
		"glow_mushroom", "reeds", "crystal_cluster", "wisp_lantern",
	]
	var offsets := [
		Vector2(-1.2, 0), Vector2(1.2, 0), Vector2(0, -1.2),
		Vector2(0, 1.2), Vector2(-0.9, -0.9), Vector2(0.9, 0.9),
	]
	var prop_count := 0
	var poi_index := 0
	for poi in pois:
		if typeof(poi) != TYPE_DICTIONARY:
			continue
		var grid: Variant = poi.get("grid", [0, 0])
		if typeof(grid) != TYPE_ARRAY or grid.size() != 2:
			continue
		var center := Vector2(float(grid[0]), float(grid[1]))
		for j in offsets.size():
			if prop_count >= GENERIC_PROP_CAP:
				break
			var kind := str(cluster_kinds[(poi_index + j) % cluster_kinds.size()])
			_add_prop(kind, center + offsets[j], 0.85, j % 2 == 0, j % 3)
			prop_count += 1
		if poi_index < 2:
			_add_animated_prop("foam_ripple", center + Vector2(0.6, 0.8), 0.9, false, AnimatedProp.MOTION_PULSE, 0)
		_add_light(center, tint, 1.1, 2.4)
		poi_index += 1

	# 1–2 InteractiveProps (bounded, non-destructive lore) + a little wildlife.
	var interactives := [
		["rune_stone", "Moonlit Rune", "The vale keeps its own quiet counsel."],
		["spirit_bloom", "Silver Bloom", "It opens only under a borrowed moon."],
	]
	for index in interactives.size():
		if _interactive_props.size() >= MAX_INTERACTIVE_PROPS:
			break
		var e: Array = interactives[index]
		var anchor := Vector2(8.0, 8.0) + Vector2(float(index) * 2.0, 0.0)
		_add_interactive_prop(str(e[0]), anchor, str(e[1]), str(e[2]), index % 2)
	_add_animated_prop("moth", Vector2(9, 7), 0.85, false, AnimatedProp.MOTION_DRIFT, 0)
	_add_animated_prop("firefly_sprite", Vector2(7, 9), 0.85, true, AnimatedProp.MOTION_DRIFT, 0)


func _spawn_region_portals() -> void:
	# Data-driven for BOTH regions. Greenward's single connection places one
	# gate at its `via` entry point (moonpetal_path -> [30, 8]).
	var conns: Variant = region.get("connections", [])
	if typeof(conns) != TYPE_ARRAY:
		return
	var eps: Variant = region.get("entry_points", {})
	var eps_dict: Dictionary = eps if typeof(eps) == TYPE_DICTIONARY else {}
	for conn in conns:
		if typeof(conn) != TYPE_DICTIONARY:
			continue
		var via := str(conn.get("via", ""))
		var grid: Variant = eps_dict.get(via, null)
		if typeof(grid) != TYPE_ARRAY or grid.size() != 2:
			continue
		var portal := RegionPortal.new()
		portal.setup(region_id, conn)
		portal.position = IsoMath.grid_to_world(float(grid[0]), float(grid[1]))
		entities.add_child(portal)
		_portals.append(portal)


func _environment() -> Dictionary:
	var env: Variant = region.get("environment", {})
	return env if typeof(env) == TYPE_DICTIONARY else {}


func _weather_state_from_name(state_name: String) -> int:
	match state_name:
		"mist": return WeatherDirector.MIST
		"rain": return WeatherDirector.RAIN
		"pollen_bloom": return WeatherDirector.POLLEN_BLOOM
		_: return WeatherDirector.CLEAR


func current_zone() -> String:
	# Cheap, mobile-aware zone derivation from the nearest POI. Zone colour is
	# applied to fog / particles / lights in _apply_atmosphere (prop MIX itself
	# is handled data-driven by ChunkBuilder's elevation/moisture variation and
	# the POI prop clusters, so no chunk rebuild is needed at runtime).
	if player == null:
		return "wilderness"
	var best := ""
	var best_distance := 360.0
	for poi in region.get("pois", []):
		var grid: Array = poi.get("grid", [0, 0])
		var pos := IsoMath.grid_to_world(float(grid[0]), float(grid[1]))
		var d := player.position.distance_to(pos)
		if d < best_distance:
			best_distance = d
			best = _zone_for_poi(str(poi.get("type", "")), str(poi.get("name", "")))
	return best if not best.is_empty() else "wilderness"


func _zone_for_poi(poi_type: String, poi_name: String) -> String:
	match poi_type:
		"village": return "village"
		"boss": return "grove"
		"ruin": return "ruin"
		"shrine": return "shrine"
		"landmark": return "river"
		_:
			var n := poi_name.to_lower()
			if "pool" in n or "river" in n or "water" in n:
				return "river"
			return "grove"


func region_display_name() -> String:
	return str(region.get("name", "Greenward"))


func region_graph() -> RegionGraph:
	return RegionGraph.new(ContentDB.regions)


# --------------------------------------------------------------- monsters

func _spawn_monsters() -> void:
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
			var monster := RoamingMonster.new()
			monster.spawn_index = spawn_index  # deterministic per-spawn variety
			monster.setup(group_id, IsoMath.grid_to_world(grid_position.x, grid_position.y), enemy_def, is_boss)
			entities.add_child(monster)
			monsters.append(monster)
			spawn_index += 1


# --------------------------------------------------------------- ambient

func _setup_ambient() -> void:
	ambient = CPUParticles2D.new()
	ambient.name = "PollenMotes"
	ambient.texture = ProceduralArt.soft_glow(Color(1.0, 0.95, 0.72), 32)
	ambient.amount = 26
	ambient.lifetime = 10.0
	ambient.preprocess = 4.0
	ambient.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ambient.emission_rect_extents = Vector2(760, 440)
	ambient.direction = Vector2(0.25, -1.0)
	ambient.spread = 42.0
	ambient.gravity = Vector2(0, -5)
	ambient.initial_velocity_min = 6.0
	ambient.initial_velocity_max = 16.0
	ambient.scale_amount_min = 0.10
	ambient.scale_amount_max = 0.32
	ambient.color = Color(1.0, 0.95, 0.72, 0.5)
	ambient.z_index = 30
	add_child(ambient)

	fireflies = CPUParticles2D.new()
	fireflies.name = "Fireflies"
	fireflies.texture = ProceduralArt.soft_glow(Color(0.65, 1.0, 0.9), 32)
	fireflies.amount = 16
	fireflies.lifetime = 7.0
	fireflies.preprocess = 3.0
	fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fireflies.emission_rect_extents = Vector2(680, 380)
	fireflies.direction = Vector2(0, -1)
	fireflies.spread = 180.0
	fireflies.gravity = Vector2(0, 0)
	fireflies.initial_velocity_min = 2.0
	fireflies.initial_velocity_max = 8.0
	fireflies.scale_amount_min = 0.12
	fireflies.scale_amount_max = 0.34
	fireflies.color = Color(0.65, 1.0, 0.9, 0.7)
	fireflies.z_index = 31
	fireflies.emitting = day_night.is_night()
	add_child(fireflies)

	# LIGHT RAIN hook: one cheap downward CPU particle emitter, capped by
	# GreenwardStyle.MAX_PARTICLES and disabled on the mobile tier. NO real
	# precipitation physics, no collisions, no splashes — a seam only.
	rain = CPUParticles2D.new()
	rain.name = "Rain"
	rain.texture = ProceduralArt.soft_glow(GreenwardStyle.WATER.glint, 16)
	# CPUParticles2D.amount must be >= 1; emission is gated via `emitting`.
	rain.amount = 1
	rain.lifetime = 1.6
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(760, 40)
	rain.direction = Vector2(0.15, 1.0)
	rain.spread = 6.0
	rain.gravity = Vector2(20, 420)
	rain.initial_velocity_min = 260.0
	rain.initial_velocity_max = 340.0
	rain.scale_amount_min = 0.05
	rain.scale_amount_max = 0.12
	rain.color = Color(0.72, 0.88, 0.95, 0.45)
	rain.z_index = 29
	rain.emitting = false
	add_child(rain)


func _setup_weather() -> void:
	weather = WeatherDirector.new(int(region.get("noise_seed", 1337)) + 505)
	# Seed the initial weather state from the region's optional bias (e.g. a
	# misty vale). Greenward's bias is "clear" -> the default state, unchanged.
	var bias: Variant = _environment().get("weather_bias", [])
	if typeof(bias) == TYPE_ARRAY:
		var bias_list: Array = bias
		if not bias_list.is_empty():
			weather.set_state(_weather_state_from_name(str(bias_list[0])))


func _setup_fog() -> void:
	fog_material = ShaderMaterial.new()
	fog_material.shader = load("res://resources/shaders/fog.gdshader")
	fog_material.set_shader_parameter("fog_color", Color(0.8, 0.88, 0.95, 1.0))
	fog_material.set_shader_parameter("density", 0.08)

	# World-space fog quad that follows the player. It lives on the world's
	# canvas layer (default 0) with z_index 20 — BELOW the ambient particles
	# (30/31) and, because the HUD is on CanvasLayer layer 10, it can NEVER
	# cover the HUD/UI. A Sprite2D is not a Control, so it is mouse-transparent.
	fog_quad = Sprite2D.new()
	fog_quad.name = "Fog"
	fog_quad.texture = ProceduralArt.white_pixel()  # 2x2 white; shader ignores it
	fog_quad.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	fog_quad.centered = true
	fog_quad.scale = FOG_SIZE / 2.0
	fog_quad.z_index = 20
	fog_quad.material = fog_material
	fog_quad.position = player.position if player != null else Vector2.ZERO
	add_child(fog_quad)
	# Cheap / disabled on the mobile tier.
	fog_quad.visible = GreenwardStyle.performance_tier() != "mobile"


func _setup_wildlife() -> void:
	var tier := GreenwardStyle.performance_tier()
	var cap := int(GreenwardStyle.MAX_PARTICLES * 0.05)  # 15 on desktop
	if tier == "mobile":
		cap = int(cap * GreenwardStyle.MOBILE_PROP_FACTOR)
	cap = clampi(cap, 0, MAX_ANIMATED_PROPS)
	var kinds := ["butterfly", "moth", "bird", "firefly_sprite"]
	# Cluster centres: village, Listening Stones, Moonpetal Shrine, Hollowed Grove.
	var centres := [Vector2(8, 8), Vector2(2, 20), Vector2(18, 5), Vector2(26, 16)]
	for index in cap:
		var centre: Vector2 = centres[index % centres.size()]
		var jx := sin(float(index) * 12.9898) * 3.2
		var jy := cos(float(index) * 7.233) * 2.6
		var grid := centre + Vector2(jx, jy)
		var kind := str(kinds[index % kinds.size()])
		_add_animated_prop(kind, grid, 0.85, index % 2 == 0, AnimatedProp.MOTION_DRIFT, 0)


func _setup_interactive_props() -> void:
	# Non-destructive lore / herb / lantern / shrine / crystal interactables.
	# They NEVER grant currency/items and NEVER mutate GameState.
	var entries := [
		["rune_stone", Vector2(2, 21.6), "Weathered Rune", "The stones remember a song the forest forgot.", 1],
		["berry_bush", Vector2(5.0, 9.0), "Moonpetal Herbs", "Silver leaves stir though there is no wind.", 1],
		["wisp_lantern", Vector2(18, 3.6), "Wisp Lantern", "A patient light, waiting to be noticed.", 1],
		["shrine", Vector2(11.3, 12.2), "Glade Shrine", "A small offering to the green.", 1],
		["crystal_cluster", Vector2(24.4, 16.4), "Hollowed Crystal", "It hums with a hollow, borrowed warmth.", 2],
	]
	for index in entries.size():
		if _interactive_props.size() >= MAX_INTERACTIVE_PROPS:
			break
		var e: Array = entries[index]
		_add_interactive_prop(str(e[0]), e[1], str(e[2]), str(e[3]), int(e[4]))


func _add_interactive_prop(kind: String, grid_position: Vector2, display_name: String, lore: String, variant: int = 0) -> void:
	var prop := InteractiveProp.new()
	prop.setup(kind, IsoMath.grid_to_world(grid_position.x, grid_position.y), display_name, lore, variant)
	entities.add_child(prop)
	_interactive_props.append(prop)
	_record_texture(kind, variant)
	_bump_prop_count(kind)


# --------------------------------------------------------------- atmosphere

func _gate_animated_props() -> void:
	if player == null or _animated_props.is_empty():
		return
	var pp := player.position
	for ap in _animated_props:
		if is_instance_valid(ap):
			ap.set_active(pp.distance_to(ap.position) < ANIM_VISIBLE_RANGE)


func _apply_atmosphere() -> void:
	var phase := GreenwardStyle.phase(day_phase())
	var wp := weather.params() if weather != null else {}
	var mobile := GreenwardStyle.performance_tier() == "mobile"
	var cap := GreenwardStyle.MAX_PARTICLES

	# Environment + nearest-POI zone tints (cheap, mobile-aware). GreenwardStyle
	# coherence_report() is untouched — these are runtime blends, not palette edits.
	var env := _environment()
	var env_fog := float(env.get("fog_density", 0.0))
	var env_tint := Color(str(env.get("ambient_tint", "#ffffff")))
	var zone_col := Color(str(ZONE_TINTS.get(current_zone(), "#ffffff")))

	# Fog quad: colour/density from the phase + weather + environment; cheap + low on mobile.
	if fog_material != null:
		var base_density := float(phase.get("fog_density", 0.10))
		var wfog := float(wp.get("fog_density", 0.0))
		var density := clampf(base_density + wfog + env_fog * 0.25, 0.0, 0.6)
		if mobile:
			density *= 0.3
		var fog_col: Color = phase.get("fog", Color(0.8, 0.88, 0.95, 1.0))
		fog_col = fog_col.lerp(zone_col, 0.08)
		# PART 5: persistent, gentle region-tint blend from WorldVisualStandards.
		if _visual_standards_applied:
			fog_col = fog_col.lerp(_visual_standards_tint, 0.06)
		fog_material.set_shader_parameter("fog_color", Color(fog_col.r, fog_col.g, fog_col.b, 1.0))
		fog_material.set_shader_parameter("density", density)

	# Warm/cool point lights: energy (and a subtle tint) from the phase palette.
	var te := float(phase.get("light_energy", 1.0))
	var tint: Color = phase.get("tint", Color.WHITE)
	for entry in _lights:
		var l: PointLight2D = entry.light
		if not is_instance_valid(l):
			continue
		l.energy = float(entry.energy) * (0.55 + te * 0.7)
		var c: Color = entry.color
		l.color = c.lerp(tint, 0.10).lerp(env_tint, 0.06).lerp(zone_col, 0.05)

	# Pollen motes: amount/colour from phase + weather + MAX_PARTICLES.
	if ambient != null:
		var pollen_scale := float(wp.get("particle_scale", 1.0))
		var pollen_amount := int(cap * 0.09 * pollen_scale)
		if bool(phase.get("fireflies", false)):
			pollen_amount = int(pollen_amount * 0.55)
		if mobile:
			pollen_amount = int(pollen_amount * 0.5)
		# CPUParticles2D.amount must be >= 1; `emitting` gates the visible count.
		ambient.amount = maxi(1, clampi(pollen_amount, 0, cap))
		ambient.emitting = pollen_amount > 0
		var pollen_col := GreenwardStyle.ACCENTS.petal_alt
		var wtint: Variant = wp.get("tint", null)
		if wtint is Color:
			pollen_col = pollen_col.lerp(wtint, 0.25)
		pollen_col = pollen_col.lerp(env_tint, 0.10).lerp(zone_col, 0.12)
		# PART 5: keep the region tint on the ambient particles each frame.
		if _visual_standards_applied:
			pollen_col = pollen_col.lerp(_visual_standards_tint, 0.08)
		ambient.color = Color(pollen_col.r, pollen_col.g, pollen_col.b, 0.5)

	# Fireflies: gate by the phase's `fireflies` flag; cap by MAX_PARTICLES.
	if fireflies != null:
		var night := bool(phase.get("fireflies", false))
		var ff_amount := int(cap * 0.06) if night else 0
		if mobile:
			ff_amount = int(ff_amount * 0.5)
		fireflies.amount = maxi(1, clampi(ff_amount, 0, cap))
		fireflies.emitting = night and ff_amount > 0
		var ff := GreenwardStyle.ACCENTS.firefly
		fireflies.color = Color(ff.r, ff.g, ff.b, 0.7)

	_apply_rain(wp)


## Lightweight RAIN hook. There is NO real weather simulation: a single cheap
## downward CPU particle emitter, capped and DISABLED on the mobile tier. This is
## only the seam for a real rain VFX layer later.
func _apply_rain(wp: Dictionary) -> void:
	if rain == null:
		return
	var mobile := GreenwardStyle.performance_tier() == "mobile"
	var desired := int(wp.get("rain_amount", 0))
	if mobile:
		desired = 0
	desired = clampi(desired, 0, GreenwardStyle.MAX_PARTICLES)
	# CPUParticles2D.amount must be >= 1; `emitting` gates the visible count.
	rain.amount = maxi(1, desired)
	rain.emitting = desired > 0
	var rcol := GreenwardStyle.WATER.glint
	rain.color = Color(rcol.r, rcol.g, rcol.b, 0.45)


func _on_phase_changed(phase_name: String) -> void:
	_apply_atmosphere()
	if phase_name != _last_area_name:
		_last_area_name = phase_name


func current_area_name() -> String:
	var fallback := region_display_name()
	if player == null:
		return fallback
	var best := fallback
	var best_distance := 280.0
	for poi in region.get("pois", []):
		var grid: Array = poi.get("grid", [0, 0])
		var position := IsoMath.grid_to_world(float(grid[0]), float(grid[1]))
		var distance := player.position.distance_to(position)
		if distance < best_distance:
			best_distance = distance
			best = str(poi.get("name", best))
	return best


func day_phase() -> String:
	return day_night.phase_at(day_night.time_of_day) if day_night != null else "Day"


## Cheap, honest snapshot of the active visual state (for tests / reporting).
func visual_style_report() -> Dictionary:
	var prop_total := 0
	for key in _prop_kind_counts.keys():
		prop_total += int(_prop_kind_counts[key])
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
		"character_art": {
			"temporary": true,
			"source": "ProceduralActorFrames / ActorVisual (procedural placeholder)",
			"canvas": [GreenwardStyle.SPRITE_SPECS.world_width, GreenwardStyle.SPRITE_SPECS.world_height],
			"anchor": GreenwardStyle.SPRITE_SPECS.anchor,
			"outline_px": GreenwardStyle.SPRITE_SPECS.outline_px,
		},
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
	_visual_standards_valid = WorldVisualStandards.validate().is_empty()
	_visual_standards_applied = true
	_visual_standards_tint = WorldVisualStandards.region_tint(region_id)
	_visual_standards_summary = WorldVisualStandards.summary()
	# Seed the fog colour with the region tint where it is safe. The periodic
	# _apply_atmosphere() blends the stored tint in on every frame thereafter.
	if fog_material != null:
		var seeded: Color = Color(0.8, 0.88, 0.95, 1.0).lerp(_visual_standards_tint, 0.10)
		fog_material.set_shader_parameter("fog_color", seeded)


## Compact, non-empty snapshot of the WorldVisualStandards contract as applied
## to this world. Uses categories(), standard(c), region_tint(), validate() and
## summary(). Pure data / headless-safe; covers player / npc / monster /
## building / vegetation / environment_object scales & anchors by REPORT.
func visual_standards_report() -> Dictionary:
	var cats: Array[String] = WorldVisualStandards.categories()
	var applied: Array = []
	for c in cats:
		var s: Dictionary = WorldVisualStandards.standard(c)
		applied.append({
			"category": c,
			"canvas": [int(s.get("canvas_width", 0)), int(s.get("canvas_height", 0))],
			"anchor": s.get("anchor_vector", Vector2(0.5, 1.0)),
			"outline_px": int(s.get("outline_px", 0)),
			"palette_group": str(s.get("palette_group", "")),
		})
	return {
		"region_id": region_id,
		"standards_valid": WorldVisualStandards.validate().is_empty(),
		"applied_categories": applied,
		"region_tint": WorldVisualStandards.region_tint(region_id),
		"categories": cats,
		"summary": WorldVisualStandards.summary(),
		"applied": _visual_standards_applied,
		"cached_valid": _visual_standards_valid,
		"cached_summary": not _visual_standards_summary.is_empty(),
		"final_assets": 0,
		"note": "Compositional/standards improvements only — ZERO final assets; all art is procedural placeholder.",
	}


## A recognisable Greenward village-gate approach built from the new
## village_gate / stone_path silhouettes plus market_stall / watchtower /
## banner_post, with WARM lights. Consistent with WorldVisualStandards:
## bottom-centre anchors (via _add_prop), GreenwardStyle colours and the
## building / vegetation / environment_object categories. SMALL + bounded.
func _build_greenward_gate_composition() -> void:
	var gate := Vector2(8, 3.6)
	_add_prop("village_gate", gate, 1.0, false, 0)
	for i in 3:
		_add_prop("stone_path", Vector2(8, 4.4 + i * 0.8), 0.95, false, i % 2)
	_add_prop("banner_post", Vector2(6.2, 4.2), 0.9, false, 0)
	_add_prop("banner_post", Vector2(9.8, 4.2), 0.9, true, 1)
	_add_prop("market_stall", Vector2(5.0, 6.0), 0.9, false, 1)
	_add_prop("watchtower", Vector2(11.6, 4.6), 0.85, false, 2)
	# Warm lights (self-capped at MAX_LIGHTS — safe, no cap changes).
	_add_light(gate, GreenwardStyle.LIGHT.warm_lantern, 1.0, 2.2)
	_add_light(Vector2(5.0, 6.0), GreenwardStyle.LIGHT.warm_lantern, 0.8, 1.8)


## A DISTINCT silver-birch / moonlit composition for Moonpetal Hollow. Uses
## birch_grove, moon_lantern, stone_path, village_gate, moon_shrine, gazebo,
## spirit_bloom, crystal_cluster and wisp_lantern, with COOL lights derived
## from region["environment"]["ambient_tint"]. SMALL + bounded; respects caps.
func _build_moonpetal_hollow_composition(cool_tint: Color) -> void:
	var gate := Vector2(6, 4.4)
	_add_prop("village_gate", gate, 0.95, false, 1)
	for i in 3:
		_add_prop("stone_path", Vector2(6, 5.2 + i * 0.8), 0.95, false, i % 2)
	_add_prop("birch_grove", Vector2(3.4, 8.2), 0.9, false, 0)
	_add_prop("birch_grove", Vector2(9.2, 8.4), 0.9, true, 2)
	_add_prop("moon_lantern", Vector2(4.4, 6.2), 0.95, false, 0)
	_add_prop("moon_lantern", Vector2(8.0, 6.2), 0.95, true, 1)
	_add_prop("moon_shrine", Vector2(6, 9.4), 0.95, false, 1)
	_add_prop("gazebo", Vector2(10.6, 10.2), 0.9, false, 1)
	_add_prop("spirit_bloom", Vector2(4.8, 9.6), 0.9, false, 0)
	_add_prop("spirit_bloom", Vector2(9.0, 10.6), 0.85, true, 2)
	_add_prop("crystal_cluster", Vector2(7.6, 10.4), 0.9, false, 1)
	_add_prop("wisp_lantern", Vector2(11.2, 8.0), 0.9, false, 0)
	# Cool lights from the region's ambient_tint (+ cool-moon accents).
	_add_light(Vector2(6, 6), cool_tint, 1.2, 2.6)
	_add_light(Vector2(6, 9.4), cool_tint, 1.0, 2.2)
	_add_light(Vector2(4.4, 6.2), GreenwardStyle.LIGHT.cool_moon, 0.9, 1.8)
	_add_light(Vector2(8.0, 6.2), GreenwardStyle.LIGHT.cool_moon, 0.9, 1.8)
