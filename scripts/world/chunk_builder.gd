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

const PATH_WIDTH := 1.0

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
		GreenwardStyle.UNDERGROWTH.dark,
		GreenwardStyle.UNDERGROWTH.mid,
		GreenwardStyle.UNDERGROWTH.light,
		GreenwardStyle.CANOPY.moss,
		GreenwardStyle.CANOPY.bright,
		GreenwardStyle.ACCENTS.petal,
		GreenwardStyle.ACCENTS.petal_alt,
		GreenwardStyle.STONE.moss,
	]

	# Density / caps from the single source of truth; lower on the mobile tier.
	var tier := GreenwardStyle.performance_tier()
	var prop_cap := GreenwardStyle.MAX_PROPS_PER_CHUNK
	var detail_density := GreenwardStyle.DETAIL_DENSITY
	var spawn_chance := 0.16
	if tier == "mobile":
		prop_cap = int(GreenwardStyle.MAX_PROPS_PER_CHUNK * GreenwardStyle.MOBILE_PROP_FACTOR)
		detail_density *= GreenwardStyle.MOBILE_DETAIL_FACTOR
		spawn_chance = 0.11

	var origin_grid := IsoMath.chunk_origin_grid(coord, chunk_size)
	var paths := _path_segments(region)
	var clearings := _clearings(region)
	var boss_zones := _boss_zones(region)
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
			var zone_id := ""
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
			var elev_t := clampf((elevation_value + 0.3) / 0.9, 0.0, 1.0)
			var damp_t := clampf((moisture_value + 0.35) / 1.1, 0.0, 1.0)
			# Blend adjacent biome palette colours continuously from the moisture
			# field. Avoid per-tile palette roulette: it created a checkerboard
			# that fought the painterly ground shader and made the map look tiled.
			var palette_pos := damp_t * float(maxi(0, grass_colors.size() - 1))
			var palette_a := clampi(int(floor(palette_pos)), 0, grass_colors.size() - 1)
			var palette_b := mini(palette_a + 1, grass_colors.size() - 1)
			var tile_color := Color(str(grass_colors[palette_a])).lerp(
				Color(str(grass_colors[palette_b])), palette_pos - floor(palette_pos)
			)
			# Low ground stays cool and moss-rich; exposed ridges pick up dry leaf litter.
			tile_color = tile_color.lerp(GreenwardStyle.CANOPY.deep, (1.0 - damp_t) * 0.10)
			tile_color = tile_color.lerp(dry_highland, elev_t * 0.11)
			tile_color = tile_color.lightened(rng.randf_range(-0.012, 0.012))
			# Boss territories tint their surrounding ground and bias local props,
			# so they read as distinct biomes long before the arena clearing.
			for zone in boss_zones:
				var zone_distance := Vector2(gx, gy).distance_to(zone.center)
				if zone_distance < zone.radius:
					var influence: float = float(pow(1.0 - zone_distance / float(zone.get("radius", 1.0)), 1.35)) * float(zone.get("strength", 0.0))
					tile_color = tile_color.lerp(zone.color, influence)
					if zone_distance < zone.radius * 0.82:
						zone_id = str(zone.id)

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
			if not in_clearing and not near_path and rng.randf() < detail_density * (0.72 + damp_t * 0.48):
				var detail_roll := rng.randf()
				var dc: Color = detail_palette[0] if detail_roll < 0.18 else detail_palette[1] if detail_roll < 0.38 else detail_palette[2] if detail_roll < 0.60 else detail_palette[rng.randi_range(3, detail_palette.size() - 1)]
				var j := Vector2(rng.randf_range(-0.42, 0.42), rng.randf_range(-0.42, 0.42))
				var dcenter := IsoMath.grid_to_world(gx + j.x, gy + j.y)
				var dsize := rng.randf_range(11.0, 19.0) * (0.88 + damp_t * 0.18)
				_push_detail(detail_transforms, detail_instance_colors, dcenter, dsize, dc, 0.82)

			# ---- Props (capped, varied, deterministic) ----
			if in_clearing or near_path:
				continue
			if props.size() >= prop_cap:
				continue
			if rng.randf() > spawn_chance:
				continue
			var base_type := _choose_prop(prop_weights, total_weight, elevation_value, rng)
			if zone_id == "elder" and rng.randf() < 0.30:
				base_type = "ancient_tree" if rng.randf() < 0.58 else "bush"
			elif zone_id == "matron" and rng.randf() < 0.34:
				var estate_roll := rng.randf()
				base_type = "flower" if estate_roll < 0.58 else "crystal" if estate_roll < 0.78 else "mushroom"
			if base_type.is_empty():
				continue
			var resolved := _resolve_prop(base_type, rng, valid_kinds, elevation_value, moisture_value)
			var jitter := Vector2(rng.randf_range(-0.32, 0.32), rng.randf_range(-0.32, 0.32))
			var prop_scale := rng.randf_range(0.82, 1.18)
			if resolved.kind in ["glade_tree", "ancient_tree", "willow_tree", "birch_tree", "pine_tree", "blossom_tree", "dead_tree"]:
				prop_scale = rng.randf_range(0.62, 1.05)
			elif resolved.kind in ["flower", "flower_cluster", "spirit_bloom", "glow_mushroom"]:
				prop_scale = rng.randf_range(0.82, 1.78)
			elif resolved.kind in ["rock", "moss_rock", "river_rock", "pebble", "crystal_cluster"]:
				prop_scale = rng.randf_range(0.72, 1.28)
			props.append(_prop_entry(
				resolved.kind, resolved.variant,
				IsoMath.grid_to_world(gx + jitter.x, gy + jitter.y),
				prop_scale, rng.randf() < 0.5, false
			))

			# Natural tree clusters: forest density forms in groves instead of a uniform scatter.
			var is_tree_base := base_type in ["glade_tree", "ancient_tree", "birch_tree", "willow_tree", "pine_tree", "blossom_tree"]
			if is_tree_base and props.size() < prop_cap:
				var cluster_roll := rng.randf()
				var companion_count := 2 if cluster_roll < 0.04 else 1 if cluster_roll < 0.22 else 0
				for companion in companion_count:
					if props.size() >= prop_cap:
						break
					var tree := _resolve_prop(base_type, rng, valid_kinds, elevation_value, moisture_value)
					var angle := rng.randf_range(0.0, TAU)
					var radius := rng.randf_range(0.72, 1.55)
					var offset := Vector2(cos(angle), sin(angle)) * radius
					props.append(_prop_entry(tree.kind, tree.variant,
						IsoMath.grid_to_world(gx + offset.x, gy + offset.y),
						rng.randf_range(0.55, 0.76), rng.randf() < 0.5, false))
				# Ferns, mushrooms and berry shrubs tuck into the shadow around trunks.
				if rng.randf() < 0.58 and props.size() < prop_cap:
					var gc_base := "glow_mushroom" if moisture_value > 0.30 and rng.randf() < 0.42 else "fern" if rng.randf() < 0.72 else "berry_bush"
					var gc := _resolve_prop(gc_base, rng, valid_kinds, elevation_value, moisture_value)
					props.append(_prop_entry(gc.kind, gc.variant,
						IsoMath.grid_to_world(gx + rng.randf_range(-0.72, 0.72), gy + rng.randf_range(-0.72, 0.72)),
						rng.randf_range(0.62, 0.88), rng.randf() < 0.5, true))

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
	# Trails connect meaningful destinations only. NPCs and tiny POIs do not
	# generate separate spokes; each route meanders like a worn woodland track.
	var spawn_grid: Array = region.get("spawn_grid", [8, 8])
	var village := Vector2(float(spawn_grid[0]), float(spawn_grid[1]))
	var segments: Array = []
	for poi in region.get("pois", []):
		var poi_type := str(poi.get("type", ""))
		if poi_type not in ["boss", "ruin", "dungeon", "landmark", "shrine"]:
			continue
		var grid: Array = poi.get("grid", [0, 0])
		if grid.size() != 2:
			continue
		var destination := Vector2(float(grid[0]), float(grid[1]))
		var direction := destination - village
		if direction.length_squared() < 0.01:
			continue
		var perpendicular := direction.normalized().orthogonal()
		var phase := float(absi(str(poi.get("id", "")).hash()) % 997) / 997.0 * TAU
		var previous := village
		for step in range(1, 7):
			var t := float(step) / 6.0
			var broad_curve := sin(t * PI) * sin(t * TAU * 1.15 + phase) * 1.15
			var small_wander := sin(t * TAU * 2.2 + phase * 0.7) * 0.28
			var point := village.lerp(destination, t) + perpendicular * (broad_curve + small_wander)
			# The final segment must terminate exactly on the POI; a residual
			# lateral wobble here leaves the trail visibly short of its destination.
			if step == 6:
				point = destination
			segments.append([previous, point])
			previous = point

	# Also connect the village to region portals, so the main travel corridor
	# is visible and readable before players reach the distant boss branches.
	var entry_points: Dictionary = region.get("entry_points", {})
	for connection in region.get("connections", []):
		var via := str(connection.get("via", ""))
		var portal_grid: Variant = entry_points.get(via, [])
		if typeof(portal_grid) != TYPE_ARRAY or portal_grid.size() != 2:
			continue
		var portal_destination := Vector2(float(portal_grid[0]), float(portal_grid[1]))
		var portal_direction := portal_destination - village
		if portal_direction.length_squared() < 0.01:
			continue
		var portal_perpendicular := portal_direction.normalized().orthogonal()
		var portal_previous := village
		var portal_phase := float(absi(via.hash()) % 997) / 997.0 * TAU
		for step in range(1, 7):
			var t := float(step) / 6.0
			var curve := sin(t * PI) * sin(t * TAU * 1.1 + portal_phase) * 0.65
			var point := village.lerp(portal_destination, t) + portal_perpendicular * curve
			if step == 6:
				point = portal_destination
			segments.append([portal_previous, point])
			portal_previous = point
	return segments


static func _clearings(region: Dictionary) -> Array:
	var result: Array = []
	var radius := float(region.get("clearing_radius", 4.0))
	for poi in region.get("pois", []):
		var grid: Array = poi.get("grid", [0, 0])
		var poi_radius := radius
		if str(poi.get("type", "")) in ["boss", "ruin", "dungeon"]:
			poi_radius = maxf(2.2, radius * 0.55)
		result.append({ "center": Vector2(float(grid[0]), float(grid[1])), "radius": poi_radius })
	return result


static func _boss_zones(region: Dictionary) -> Array:
	# The First Tree and Withered Estate have distinct ground palettes and
	# local prop ecology, fading naturally into the surrounding Greenward.
	var result: Array = []
	for poi in region.get("pois", []):
		var poi_id := str(poi.get("id", ""))
		if poi_id not in ["elder_hollow", "withered_estate"]:
			continue
		var grid: Array = poi.get("grid", [0, 0])
		var center := Vector2(float(grid[0]), float(grid[1]))
		if poi_id == "elder_hollow":
			result.append({
				"id": "elder", "center": center, "radius": 28.0,
				"strength": 0.34, "color": Color("#4f704b")
			})
		else:
			result.append({
				"id": "matron", "center": center, "radius": 28.0,
				"strength": 0.38, "color": Color("#70536d")
			})
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
