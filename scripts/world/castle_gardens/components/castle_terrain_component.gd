class_name CastleTerrainComponent
extends Node
## Owns deterministic isometric ground generation and the reversible
## editor-authored TileMapLayer migration seam.

const GROUND_TILE_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/castle_terrain_tile.tscn")
const TERRAIN_DIAMOND_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/castle_terrain_diamond.tscn")

var world: CastleRoyalGardens


func bind(owner_world: CastleRoyalGardens) -> void:
	world = owner_world


func build() -> void:
	if world == null:
		return
	var terrain := world.get_node_or_null("Terrain") as Node2D
	var ground := world.get_node_or_null("Terrain/Ground") as Node2D
	var grass_details := world.get_node_or_null("Terrain/GrassDetails") as Node2D
	var config := world.get_node_or_null("Terrain/Configuration") as Node2D
	var tilemap_candidate := world.get_node_or_null("Terrain/TilemapCandidate") as Node2D
	if terrain == null or ground == null or grass_details == null or config == null:
		push_error("CastleTerrainComponent requires authored Terrain, Ground, GrassDetails and Configuration nodes.")
		return

	# The baked TileMapLayer scene is mounted in the live composition but stays
	# opt-in until visual QA approves the renderer swap. This keeps a one-flag,
	# reversible migration path and preserves legacy nodes/contracts.
	var use_baked_tilemap := bool(config.get_meta("use_baked_tilemap", false))
	if tilemap_candidate != null:
		tilemap_candidate.visible = use_baked_tilemap
	ground.visible = not use_baked_tilemap
	grass_details.visible = not use_baked_tilemap
	if use_baked_tilemap:
		return

	var min_value: Variant = config.get_meta("ground_min", null)
	var max_value: Variant = config.get_meta("ground_max", null)
	if not (min_value is Vector2i) or not (max_value is Vector2i):
		push_error("Castle terrain configuration requires Vector2i ground_min and ground_max metadata.")
		return
	var ground_min: Vector2i = min_value
	var ground_max: Vector2i = max_value
	var tile_width := float(config.get_meta("tile_width", 64.0))
	var tile_height := float(config.get_meta("tile_height", 32.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(config.get_meta("random_seed", 9001))
	var grass_textures: Array[Texture2D] = []
	var texture_paths: Variant = config.get_meta("grass_texture_paths", PackedStringArray())
	for texture_path in texture_paths:
		var texture := load(str(texture_path)) as Texture2D
		if texture != null:
			grass_textures.append(texture)
	for gy in range(ground_min.y, ground_max.y + 1):
		for gx in range(ground_min.x, ground_max.x + 1):
			if not CastleLayout.covers_screen_rect(gx, gy):
				continue
			var kind := "water" if CastleLayout.is_pond(gx, gy) else "grass"
			var tile_texture: Texture2D = null
			if not grass_textures.is_empty():
				tile_texture = grass_textures[rng.randi_range(0, grass_textures.size() - 1)]
			if tile_texture != null:
				var tile := GROUND_TILE_SCENE.instantiate() as Node2D
				var sprite := tile.get_node("Sprite") as Sprite2D
				sprite.texture = tile_texture
				tile.position = IsoMath.grid_to_world(float(gx), float(gy))
				ground.add_child(tile)
			else:
				var fallback := Color(0.34, 0.52, 0.33, 1.0)
				if kind == "water":
					fallback = Color(0.30, 0.56, 0.69, 0.95)
				add_iso_tile(ground, gx, gy, fallback, 0, tile_width, tile_height)
	for detail_marker in config.get_children():
		if not (detail_marker is Marker2D):
			continue
		var grid_value: Variant = detail_marker.get_meta("grid_position", null)
		if not (grid_value is Vector2):
			push_error("Terrain detail marker %s is missing its Vector2 grid_position." % detail_marker.name)
			continue
		var point: Vector2 = IsoMath.grid_to_world(grid_value.x, grid_value.y)
		add_diamond(grass_details, point + Vector2(0, 2), 22, 10, Color(0.18, 0.32, 0.20, 0.18), 0)


func add_diamond(parent: Node, center: Vector2, width: float, height: float, tint: Color, depth: int = 0) -> Polygon2D:
	var diamond := TERRAIN_DIAMOND_SCENE.instantiate() as Node2D
	var poly := diamond.get_node("Polygon") as Polygon2D
	diamond.position = center
	poly.polygon = PackedVector2Array([
		Vector2(0, -height * 0.5), Vector2(width * 0.5, 0),
		Vector2(0, height * 0.5), Vector2(-width * 0.5, 0),
	])
	poly.color = tint
	poly.z_index = depth
	parent.add_child(diamond)
	return poly


func add_iso_tile(parent: Node, gx: int, gy: int, tint: Color, depth: int = -20, width: float = 64.0, height: float = 32.0) -> void:
	add_diamond(parent, IsoMath.grid_to_world(float(gx), float(gy)), width, height, tint, depth)
