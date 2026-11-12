class_name ChunkBuilder
extends RefCounted
## Builds one streamed world chunk: a MultiMesh terrain layer, an animated water
## layer, a deterministic list of props, and an optional single-MultiMesh ground
## cover ("detail") layer. No nodes are added to the tree here; the world decides
## what to parent and when to free it.
##
## One draw call per layer: terrain, water and detail are each a single
## MultiMeshInstance2D. Everything is derived deterministically from (coord,
## region, noise); no global RNG is used.

const PATH_WIDTH := 1.35

# Meandering river channel (a connected ribbon derived from elevation noise).
const RIVER_BASE := 30.0
const RIVER_MEANDER := 0.16
const RIVER_AMPLITUDE := 6.0
const RIVER_NOISE_AMP := 5.0
const RIVER_HALF_WIDTH := 1.2

# Shoreline / beach bands above the water line.
const BEACH_BAND := 0.12
const FOAM_BAND := 0.04

# Maps a base prop type from region["props"] to several distinct new kinds, so
# the world never repeats a single texture everywhere. All targets are valid
# GreenwardStyle.prop_kinds() entries.
const BASE_TO_KINDS := {
	"glade_tree": ["willow_tree", "birch_tree", "pine_tree", "blossom_tree", "glade_tree"],
	"ancient_tree": ["dead_tree", "ancient_tree"],
	"rock": ["moss_rock", "pebble", "river_rock", "rock"],
	"flower": ["flower_cluster", "spirit_bloom", "flower"],
	"mushroom": ["glow_mushroom", "mushroom"],
	"crystal": ["crystal_cluster", "rune_stone", "crystal"],
	"bush": ["berry_bush", "bush"],
	"hut": ["cottage", "hut"],
	"lantern": ["wisp_lantern", "lantern"],
	"waypoint": ["shrine", "ruin_arch", "waypoint"],
	"ruin_pillar": ["rune_stone", "ruin_pillar"],
	"fence": ["signpost", "fence"],
}

static var _detail_material: ShaderMaterial
static var _valid_kind_set: Dictionary = {}


static func build(
	coord: Vector2i,
	region: Dictionary,
	elevation: FastNoiseLite,
	moisture: FastNoiseLite,
	terrain_material: ShaderMaterial,
	water_material: ShaderMaterial
) -> Dictionary:
	var chunk_size := int(region.get("chunk_size", 16))
	var biome: Dictionary = region.get("biome", {})
	var grass_colors: Array = biome.get("grass_colors", ["#4f7a46"])
	var path_color := Color(str(biome.get("path_color", "#8a7a55")))
	var water_shallow := Color(str(biome.get("water_shallow", "#3f8f96")))
	var water_deep := Color(str(biome.get("water_deep", "#1f5568")))
	var water_level := float(biome.get("water_level", -0.22))
	var deep_level := float(biome.get("deep_water_level", -0.34))

	# Style-authority colours for shoreline, foam and ground cover.
	var shore_color := GreenwardStyle.WATER.shore
	var foam_color := GreenwardStyle.WATER.foam
	var dry_highland := GreenwardStyle.UNDERGROWTH.dry
	var detail_palette := [
		GreenwardStyle.UNDERGROWTH.light,
		GreenwardStyle.UNDERGROWTH.grass_alt,
		GreenwardStyle.ACCENTS.petal,
		GreenwardStyle.ACCENTS.petal_alt,
		GreenwardStyle.STONE.mid,
		GreenwardStyle.UNDERGROWTH.lily,
		GreenwardStyle.WATER.foam,
	]

	# Density / caps from the single source of truth; lower on the mobile tier.
	var tier := GreenwardStyle.performance_tier()
	var prop_cap := GreenwardStyle.MAX_PROPS_PER_CHUNK
	var detail_density := GreenwardStyle.DETAIL_DENSITY
	var spawn_chance := 0.135
	if tier == "mobile":
		prop_cap = int(GreenwardStyle.MAX_PROPS_PER_CHUNK * GreenwardStyle.MOBILE_PROP_FACTOR)
		detail_density *= GreenwardStyle.MOBILE_DETAIL_FACTOR
		spawn_chance = 0.08

	var origin_grid := IsoMath.chunk_origin_grid(coord, chunk_size)
	var paths := _path_segments(region)
	var clearings := _clearings(region)
	var valid_kinds := _valid_kinds()

	var terrain_transforms: Array = []
	var terrain_colors: Array = []
	var water_transforms: Array = []
	var water_colors: Array = []
	var water_tiles: Array = []
	var detail_transforms: Array = []
	var detail_instance_colors: Array = []
	var props: Array = []

	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_for(coord, int(region.get("noise_seed", 1)))
	var prop_weights: Array = region.get("props", [])
	var total_weight := 0.0
	for entry in prop_weights:
		total_weight += float(entry.get("weight", 0.0))

	for oy in chunk_size:
		for ox in chunk_size:
			var gx := origin_grid.x + ox
			var gy := origin_grid.y + oy
			var elevation_value := elevation.get_noise_2d(gx, gy)
			var moisture_value := moisture.get_noise_2d(gx, gy)
			var center := IsoMath.grid_to_world(gx, gy)
			var transform := Transform2D(0.0, Vector2(IsoMath.TILE_W * 1.02, IsoMath.TILE_H * 1.02), 0.0, center)

			# Meandering, connected river ribbon.
			var river_dist := absf(float(gy) - _river_center(float(gx), elevation))
			var in_river := river_dist <= RIVER_HALF_WIDTH
			var is_water := elevation_value < water_level or in_river

			if is_water:
				var depth := clampf((water_level - elevation_value) / maxf(0.001, water_level - deep_level), 0.0, 1.0)
				terrain_transforms.append(transform)
				terrain_colors.append(water_deep.darkened(0.15 + depth * 0.25))
				var wcolor := water_shallow.lerp(water_deep, depth)
				if depth < 0.25:
					wcolor = wcolor.lerp(foam_color, (0.25 - depth) * 0.45) # shoreline foam in the shallows
				water_transforms.append(transform)
				water_colors.append(wcolor * Color(1, 1, 1, 0.86))
				water_tiles.append(center)
				# A few lily pads / foam flecks near the river banks (detail layer).
				if river_dist <= RIVER_HALF_WIDTH + 1.0 and rng.randf() < detail_density * 0.5:
					var wc: Color = detail_palette[5] if rng.randf() < 0.5 else detail_palette[6]
					var wsize := rng.randf_range(8.0, 13.0)
					_push_detail(detail_transforms, detail_instance_colors, center, wsize, wc, 0.8)
				continue

			# ---- Land tile colour: blend grass by BOTH moisture and elevation ----
			var tint_index := absi(int(round(moisture_value * 20.0))) % grass_colors.size()
			var tile_color := Color(str(grass_colors[tint_index]))
			var elev_t := clampf((elevation_value + 0.3) / 0.9, 0.0, 1.0)
			tile_color = tile_color.lerp(dry_highland, elev_t * 0.16) # drier/lighter highland
			tile_color = tile_color.lightened(rng.randf_range(-0.04, 0.05)) # subtle per-tile variation

			# Path variation: not one flat colour; varies with moisture/elevation/grain.
			# A subtle cobble / stepping-stone tint is added PER-INSTANCE (COLOR
			# only) via a deterministic per-tile hash — NO extra draw calls, and
			# NO RNG state consumed (so rebuilds stay byte-for-byte identical).
			if _near_path(Vector2(gx, gy), paths):
				var path_var := path_color.lightened(moisture_value * 0.06 + (rng.randf() - 0.5) * 0.06)
				var th := _tile_hash(int(round(gx)), int(round(gy)))
				if th > 0.72:
					path_var = path_var.lerp(GreenwardStyle.STONE.mid, 0.28)  # exposed cobble
				elif th < 0.16:
					path_var = path_var.lightened(0.10)                        # pale stepping stone
				else:
					path_var = path_var.darkened(th * 0.06)
				tile_color = path_var.lerp(tile_color, 0.15 + 0.10 * elev_t)

			# Shoreline / beach band + foam tint on land tiles near water.
			var above := elevation_value - water_level
			var shore_factor := 0.0
			if above < BEACH_BAND:
				shore_factor = 1.0 - clampf(above / BEACH_BAND, 0.0, 1.0)
			if river_dist <= RIVER_HALF_WIDTH + 1.2 and river_dist > RIVER_HALF_WIDTH:
				shore_factor = maxf(shore_factor, 0.6) # river bank
			if shore_factor > 0.0:
				tile_color = tile_color.lerp(shore_color, shore_factor * 0.7)
				if above < FOAM_BAND or (river_dist <= RIVER_HALF_WIDTH + 0.4):
					tile_color = tile_color.lerp(foam_color, 0.25 * shore_factor)

			terrain_transforms.append(transform)
			terrain_colors.append(tile_color)

			var in_clearing := _in_clearing(Vector2(gx, gy), clearings)
			var near_path := _near_path(Vector2(gx, gy), paths)

			# ---- Detail layer: one MultiMesh for all ground cover ----
			if not in_clearing and not near_path and rng.randf() < detail_density:
				var dc: Color = detail_palette[rng.randi() % detail_palette.size()]
				var j := Vector2(rng.randf_range(-0.35, 0.35), rng.randf_range(-0.35, 0.35))
				var dcenter := IsoMath.grid_to_world(gx + j.x, gy + j.y)
				var dsize := rng.randf_range(9.0, 16.0)
				_push_detail(detail_transforms, detail_instance_colors, dcenter, dsize, dc, 0.85)

			# ---- Props (capped, varied, deterministic) ----
			if in_clearing or near_path:
				continue
			if props.size() >= prop_cap:
				continue
			if rng.randf() > spawn_chance:
				continue
			var base_type := _choose_prop(prop_weights, total_weight, elevation_value, rng)
			if base_type.is_empty():
				continue
			var resolved := _resolve_prop(base_type, rng, valid_kinds, elevation_value, moisture_value)
			var jitter := Vector2(rng.randf_range(-0.32, 0.32), rng.randf_range(-0.32, 0.32))
			props.append(_prop_entry(
				resolved.kind, resolved.variant,
				IsoMath.grid_to_world(gx + jitter.x, gy + jitter.y),
				rng.randf_range(0.85, 1.15), rng.randf() < 0.5, false
			))

			# Occasional companion ground cover around trees for extra density.
			if base_type == "glade_tree" and rng.randf() < 0.4 and props.size() < prop_cap:
				var gc_base := "flower" if rng.randf() < 0.6 else "bush"
				var gc := _resolve_prop(gc_base, rng, valid_kinds, elevation_value, moisture_value)
				props.append(_prop_entry(
					gc.kind, gc.variant,
					IsoMath.grid_to_world(gx + rng.randf_range(-0.7, 0.7), gy + rng.randf_range(-0.7, 0.7)),
					rng.randf_range(0.7, 1.0), rng.randf() < 0.5, true
				))

	var terrain_node := _make_multimesh(terrain_transforms, terrain_colors, terrain_material)
	var water_node: MultiMeshInstance2D = null
	if not water_transforms.is_empty():
		water_node = _make_multimesh(water_transforms, water_colors, water_material)
	var detail_node: MultiMeshInstance2D = null
	if not detail_transforms.is_empty():
		detail_node = _make_multimesh(detail_transforms, detail_instance_colors, _detail_material_cached())
		# greenward_world.gd only parents `terrain`/`water`/`props` and ignores
		# the optional `detail` key. Parenting detail to terrain means it is
		# rendered (one extra draw call) AND freed with terrain on chunk unload,
		# so no orphan node leaks. Integrators should NOT re-add data.detail to
		# the tree — it is already a child of data.terrain.
		if detail_node != null:
			terrain_node.add_child(detail_node)

	return {
		"coord": coord,
		"terrain": terrain_node,
		"water": water_node,
		"props": props,
		"water_tiles": water_tiles,
		"detail": detail_node,
	}


# ------------------------------------------------------------------ new helpers

static func _river_center(gx: float, elevation: FastNoiseLite) -> float:
	# Smooth global centerline (continuous across chunk borders) plus a
	# noise-derived wobble: deterministic, meandering, connected ribbon.
	return RIVER_BASE \
		+ sin(gx * RIVER_MEANDER) * RIVER_AMPLITUDE \
		+ elevation.get_noise_2d(gx * 0.6 + 91.0, 317.0) * RIVER_NOISE_AMP


static func _valid_kinds() -> Dictionary:
	if _valid_kind_set.is_empty():
		for kind in GreenwardStyle.prop_kinds():
			_valid_kind_set[kind] = true
	return _valid_kind_set


static func _detail_material_cached() -> ShaderMaterial:
	if _detail_material == null:
		var material := ShaderMaterial.new()
		material.shader = load("res://resources/shaders/detail.gdshader")
		_detail_material = material
	return _detail_material


static func _push_detail(transforms: Array, colors: Array, center: Vector2, size: float, color: Color, alpha: float) -> void:
	transforms.append(Transform2D(0.0, Vector2(size, size * 0.7), 0.0, center))
	colors.append(Color(color.r, color.g, color.b, alpha))


static func _resolve_prop(base_type: String, rng: RandomNumberGenerator, valid_kinds: Dictionary, elevation_value: float = 0.0, moisture_value: float = 0.0) -> Dictionary:
	var candidates: Array = BASE_TO_KINDS.get(base_type, [base_type])
	# Forest variation: bias the prop mix by elevation / moisture so different
	# parts of the forest look different — denser pines/birches on high ground,
	# reeds/lily pads in wet lowland. Purely reorders/weights the candidate list;
	# NO extra RNG calls, so determinism and caps are preserved.
	if base_type == "glade_tree":
		if elevation_value > 0.18:
			candidates = ["pine_tree", "birch_tree", "willow_tree", "glade_tree"]
		elif moisture_value > 0.28:
			candidates = ["willow_tree", "birch_tree", "glade_tree"]
	elif base_type == "flower" and moisture_value > 0.30:
		candidates = ["lily_pad", "reeds", "flower_cluster", "spirit_bloom", "flower"]
	elif base_type == "bush" and moisture_value > 0.30:
		candidates = ["reeds", "fern", "berry_bush", "bush"]
	var filtered: Array = []
	for candidate in candidates:
		if valid_kinds.has(str(candidate)):
			filtered.append(str(candidate))
	if filtered.is_empty():
		filtered = [base_type] if valid_kinds.has(base_type) else ["flower"]
	var kind := str(filtered[rng.randi() % filtered.size()])
	var vcount := maxi(1, GreenwardStyle.variant_count(kind))
	return { "kind": kind, "variant": rng.randi() % vcount }


static func _prop_entry(kind: String, variant: int, world_position: Vector2, scale_value: float, flip: bool, is_detail: bool) -> Dictionary:
	return {
		"type": kind,
		"position": world_position,
		"scale": scale_value,
		"flip": flip,
		"layer": "prop",
		"variant": variant,
		"detail": is_detail,
	}


# --------------------------------------------------------------- preserved API

static func _make_multimesh(transforms: Array, colors: Array, material: ShaderMaterial) -> MultiMeshInstance2D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	multimesh.mesh = quad
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform_2d(index, transforms[index])
		multimesh.set_instance_color(index, colors[index])
	var node := MultiMeshInstance2D.new()
	node.multimesh = multimesh
	node.material = material
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return node


static func _choose_prop(weights: Array, total_weight: float, elevation_value: float, rng: RandomNumberGenerator) -> String:
	if total_weight <= 0.0:
		return ""
	var roll := rng.randf() * total_weight
	var cumulative := 0.0
	for entry in weights:
		cumulative += float(entry.get("weight", 0.0))
		if roll <= cumulative:
			if elevation_value < float(entry.get("min_elevation", -2.0)):
				return ""
			return str(entry.get("type", ""))
	return ""


static func _seed_for(coord: Vector2i, region_seed: int) -> int:
	var value := region_seed * 1000003
	value += coord.x * 73856093
	value += coord.y * 19349663
	return absi(value)


static func _path_segments(region: Dictionary) -> Array:
	var points: Dictionary = {}
	for poi in region.get("pois", []):
		var grid: Array = poi.get("grid", [0, 0])
		points[str(poi.get("id", ""))] = Vector2(float(grid[0]), float(grid[1]))
	var village: Vector2 = points.get("glade_village", Vector2(8, 8))
	var segments: Array = []
	for poi_id in points.keys():
		if poi_id == "glade_village":
			continue
		segments.append([village, points[poi_id]])
	return segments


static func _clearings(region: Dictionary) -> Array:
	var result: Array = []
	var radius := float(region.get("clearing_radius", 4.0))
	for poi in region.get("pois", []):
		var grid: Array = poi.get("grid", [0, 0])
		var poi_radius := radius
		if str(poi.get("type", "")) == "boss" or str(poi.get("type", "")) == "ruin":
			poi_radius = maxf(2.2, radius * 0.55)
		result.append({ "center": Vector2(float(grid[0]), float(grid[1])), "radius": poi_radius })
	return result


static func _in_clearing(grid: Vector2, clearings: Array) -> bool:
	for clearing in clearings:
		if grid.distance_to(clearing.center) <= float(clearing.radius):
			return true
	return false


static func _near_path(grid: Vector2, paths: Array) -> bool:
	# Path width varies slightly with a deterministic per-tile hash (no RNG),
	# so routes read as hand-laid rather than a uniform ribbon.
	var width := PATH_WIDTH + (_tile_hash(int(round(grid.x)), int(round(grid.y))) - 0.5) * 0.5
	for segment in paths:
		if IsoMath.distance_to_segment(grid, segment[0], segment[1]) <= width:
			return true
	return false


static func _tile_hash(gx: int, gy: int) -> float:
	# Deterministic integer hash in [0, 1); pure (no RNG, no state). Bounded to
	# avoid int64 overflow: reduce the XOR first, then use a small multiplier.
	var n := absi((gx * 73856093) ^ (gy * 19349663)) % 2147483647
	n = (n * 48271) % 2147483647
	return float(n) / 2147483647.0
