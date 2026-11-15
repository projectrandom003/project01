class_name CastleRoyalGardens
extends Node2D
## Polished, explorable Castle & Royal Gardens map (standalone scene).
## Separate from Greenward village; preserves all existing worlds/assets.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")
const NPC_SCENE: PackedScene = preload("res://scenes/world/world_npc.tscn")

@onready var entities: Node2D = $Entities
@onready var spawn_points: Node2D = $MapSpawnPoints
@onready var npc_placement: Node2D = $NPCPlacement

var region_id: String = "castle_royal_gardens"
var entry_point: String = ""
var player: Player
var npcs: Array = []
var monsters: Array = []
const SAVE_POSITION_INTERVAL := 1.0
var _save_accumulator: float = 0.0


func _ready() -> void:
	add_to_group("world")
	add_to_group("castle_royal_gardens")
	_build_environment()
	_spawn_player()
	_spawn_npcs_from_markers()
	EventBus.world_ready.emit()


func _build_environment() -> void:
	_build_ground()
	_configure_castle()
	_configure_gardens()
	_configure_paths()
	_configure_hedges()
	_configure_water_and_bridges()
	_configure_decor()
	_configure_lighting_and_effects()


func _build_ground() -> void:
	var ground := get_node_or_null("Terrain/Ground") as Node2D
	var grass_details := get_node_or_null("Terrain/GrassDetails") as Node2D
	var transitions := get_node_or_null("Terrain/TerrainTransitions") as Node2D
	if ground == null:
		return

	# Cohesive base terrain with natural variation (layered, intentional)
	var grass_tex := load("res://assets/environment/castle_gardens/grass_ground.png") as Texture2D
	if grass_tex != null:
		var base := TextureRect.new()
		base.texture = grass_tex
		base.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		base.stretch_mode = TextureRect.STRETCH_TILE
		base.position = Vector2(80, 80)
		base.size = Vector2(1120, 640)
		base.mouse_filter = Control.MOUSE_FILTER_IGNORE
		base.z_index = -2
		base.modulate = Color(0.97, 1.0, 0.95, 1.0)
		ground.add_child(base)
		# Broad variation patches to break repetition
		for patch in [
			{"rect": Rect2(120, 320, 260, 320), "color": Color(0.36, 0.5, 0.34, 0.10)},
			{"rect": Rect2(900, 300, 260, 340), "color": Color(0.42, 0.56, 0.38, 0.08)},
			{"rect": Rect2(360, 520, 560, 160), "color": Color(0.34, 0.46, 0.32, 0.07)},
			{"rect": Rect2(300, 220, 680, 90), "color": Color(0.44, 0.58, 0.4, 0.06)},
		]:
			var overlay := ColorRect.new()
			overlay.position = patch.rect.position
			overlay.size = patch.rect.size
			overlay.color = patch.color
			overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay.z_index = -2
			ground.add_child(overlay)

	# Castle forecourt / plaza stone flooring
	var stone_tex := load("res://assets/environment/castle_gardens/stone_floor.png") as Texture2D
	if stone_tex != null:
		var plaza := TextureRect.new()
		plaza.texture = stone_tex
		plaza.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		plaza.stretch_mode = TextureRect.STRETCH_TILE
		plaza.position = Vector2(420, 180)
		plaza.size = Vector2(440, 120)
		plaza.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plaza.z_index = -1
		ground.add_child(plaza)
		# soften edges and add subtle wear bands
		if transitions != null:
			for rect_data in [
				Rect2(Vector2(420, 292), Vector2(440, 12)),
				Rect2(Vector2(410, 180), Vector2(12, 120)),
				Rect2(Vector2(858, 180), Vector2(12, 120)),
				Rect2(Vector2(420, 170), Vector2(440, 12)),
			]:
				var edge := ColorRect.new()
				edge.position = rect_data.position
				edge.size = rect_data.size
				edge.color = Color(0.30, 0.38, 0.28, 0.28)
				edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
				transitions.add_child(edge)
			for band in [Rect2(450, 232, 380, 8), Rect2(480, 248, 320, 6)]:
				var wear := ColorRect.new()
				wear.position = band.position
				wear.size = band.size
				wear.color = Color(0.62, 0.58, 0.52, 0.10)
				wear.mouse_filter = Control.MOUSE_FILTER_IGNORE
				transitions.add_child(wear)

	# Grass/ground detail accents (intentional, varied)
	if grass_details != null:
		var flower_tex := load("res://assets/environment/castle_gardens/flower_bed_lush.png") as Texture2D
		var accent_colors := [Color(0.38, 0.54, 0.34, 0.20), Color(0.46, 0.62, 0.4, 0.16), Color(0.32, 0.48, 0.30, 0.18)]
		var idx := 0
		for p in [Vector2(220, 250), Vector2(1060, 250), Vector2(220, 620), Vector2(1060, 620), Vector2(640, 690), Vector2(320, 560), Vector2(960, 560), Vector2(180, 430), Vector2(1100, 430)]:
			var tuft := ColorRect.new()
			tuft.position = p - Vector2(22, 10)
			tuft.size = Vector2(44, 20)
			tuft.color = accent_colors[idx % accent_colors.size()]
			tuft.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grass_details.add_child(tuft)
			idx += 1
		if flower_tex != null:
			for p in [Vector2(260, 360), Vector2(1020, 360), Vector2(260, 520), Vector2(1020, 520), Vector2(300, 440), Vector2(980, 440)]:
				var s := Sprite2D.new()
				s.texture = flower_tex
				s.position = p
				s.centered = true
				s.scale = Vector2(0.8 + 0.08 * float(int(p.x) % 2), 0.82)
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				grass_details.add_child(s)


func _configure_castle() -> void:
	var castle := get_node_or_null("Castle") as Node2D
	var exterior := get_node_or_null("Castle/CastleExterior")
	var entrance := get_node_or_null("Castle/CastleEntrance")
	if castle == null:
		return
	# Build modular castle pieces via component scenes/scripts
	if exterior != null and exterior.has_method("build_default"):
		exterior.call("build_default", Vector2.ZERO)
	if entrance != null and entrance.has_method("build_default"):
		entrance.call("build_default", Vector2.ZERO)

	# Add additional towers/details for a richer silhouette
	var towers_node := get_node_or_null("Castle/Towers") as Node2D
	var tower_tex := load("res://assets/environment/castle_gardens/castle_tower.png") as Texture2D
	if towers_node != null and tower_tex != null:
		for data in [
			{"pos": Vector2(430, 175), "scale": Vector2(1.0, 1.0)},
			{"pos": Vector2(850, 175), "scale": Vector2(1.0, 1.0)},
			{"pos": Vector2(520, 160), "scale": Vector2(0.9, 0.95)},
			{"pos": Vector2(760, 160), "scale": Vector2(0.9, 0.95)},
		]:
			var t := Sprite2D.new()
			t.texture = tower_tex
			t.position = data.pos
			t.scale = data.scale
			t.centered = true
			t.offset = Vector2(0, -40)
			t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			towers_node.add_child(t)

	var walls_node := get_node_or_null("Castle/Walls") as Node2D
	var wall_tex := load("res://assets/environment/castle_gardens/castle_wall.png") as Texture2D
	if walls_node != null and wall_tex != null:
		for i in [-3, -2, 2, 3]:
			var w := Sprite2D.new()
			w.texture = wall_tex
			w.position = Vector2(640 + i * 78, 186)
			w.centered = true
			w.offset = Vector2(0, -18)
			w.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			walls_node.add_child(w)

	var decor_node := get_node_or_null("Castle/Decorations") as Node2D
	if decor_node != null:
		# banners/ornaments as simple intentional accents
		for p in [Vector2(565, 150), Vector2(715, 150)]:
			var banner := Polygon2D.new()
			banner.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(6, 26), Vector2(0, 20), Vector2(-6, 26)])
			banner.color = Color(0.55, 0.18, 0.26, 0.95)
			banner.position = p
			decor_node.add_child(banner)
			var trim := Line2D.new()
			trim.points = PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(6, 26), Vector2(0, 20), Vector2(-6, 26), Vector2(-6, 0)])
			trim.width = 1.0
			trim.default_color = Color(0.82, 0.70, 0.40, 0.9)
			trim.position = p
			decor_node.add_child(trim)


func _configure_gardens() -> void:
	var left_garden := get_node_or_null("RoyalGarden/LeftGarden")
	var right_garden := get_node_or_null("RoyalGarden/RightGarden") as Node2D
	var flower_beds := get_node_or_null("RoyalGarden/FlowerBeds") as Node2D
	var trees := get_node_or_null("RoyalGarden/Trees") as Node2D
	var props := get_node_or_null("RoyalGarden/GardenProps") as Node2D
	if left_garden != null and left_garden.has_method("build_symmetrical"):
		left_garden.call("build_symmetrical", Vector2.ZERO)

	# Mirror/right-side intentional accents
	if right_garden != null and flower_beds == null:
		pass

	var flower_tex := load("res://assets/environment/castle_gardens/flower_bed_lush.png") as Texture2D
	var tree_tex := load("res://assets/environment/castle_gardens/garden_tree.png") as Texture2D
	var urn_tex := load("res://assets/environment/castle_gardens/urn_planter.png") as Texture2D
	var origin := Vector2(640, 320)

	if flower_beds != null and flower_tex != null:
		var offsets := [Vector2(-220, 40), Vector2(220, 40), Vector2(-220, 140), Vector2(220, 140), Vector2(-140, 90), Vector2(140, 90)]
		for off in offsets:
			var s := Sprite2D.new()
			s.texture = flower_tex
			s.position = origin + off
			s.centered = true
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			flower_beds.add_child(s)

	if trees != null and tree_tex != null:
		for off in [Vector2(-300, 10), Vector2(300, 10), Vector2(-300, 180), Vector2(300, 180)]:
			var t := Sprite2D.new()
			t.texture = tree_tex
			t.position = origin + off
			t.centered = true
			t.offset = Vector2(0, -28)
			t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			trees.add_child(t)
			_add_static_circle(trees, origin + off + Vector2(0, 10), 10.0)

	if props != null and urn_tex != null:
		for off in [Vector2(-90, 10), Vector2(90, 10), Vector2(-90, 170), Vector2(90, 170), Vector2(-170, 170), Vector2(170, 170)]:
			var u := Sprite2D.new()
			u.texture = urn_tex
			u.position = origin + off
			u.centered = true
			u.offset = Vector2(0, -10)
			u.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			props.add_child(u)
			_add_static_circle(props, origin + off + Vector2(0, 2), 7.0)


func _configure_paths() -> void:
	var paths := get_node_or_null("Pathways") as Node2D
	if paths == null:
		return
	# Clear any previously generated path sprites to avoid duplicates on rebuild
	for child in paths.get_children():
		child.queue_free()
	var path_tex := load("res://assets/environment/castle_gardens/stone_path_tile.png") as Texture2D
	if path_tex == null:
		path_tex = load("res://assets/environment/castle_gardens/path_tile.png") as Texture2D
	if path_tex == null:
		return

	var points: Array[Vector2] = []
	# Main central promenade (wider, detailed)
	for y in range(240, 646, 26):
		for w in [-30, -10, 10, 30]:
			points.append(Vector2(640 + w, y))
	# Cross promenades / garden axes
	for x in range(410, 871, 26):
		for w in [-18, 0, 18]:
			points.append(Vector2(x, 410 + w))
			points.append(Vector2(x, 500 + w))
	# Plaza to fountain connectors and ring-like approach
	for y in range(320, 430, 22):
		points.append(Vector2(596, y))
		points.append(Vector2(684, y))
	for a in range(0, 360, 20):
		var rad := deg_to_rad(float(a))
		var px := 640.0 + cos(rad) * 42.0
		var py := 360.0 + sin(rad) * 22.0
		points.append(Vector2(px, py))
	# Side approaches
	for i in range(0, 8):
		points.append(Vector2(420 - i * 16, 430 + i * 9))
		points.append(Vector2(860 + i * 16, 430 + i * 9))
		points.append(Vector2(420 - i * 16, 520 - i * 5))
		points.append(Vector2(860 + i * 16, 520 - i * 5))

	var seen := {}
	var n := 0
	for p in points:
		var key := "%d_%d" % [int(round(p.x / 10.0)), int(round(p.y / 10.0))]
		if seen.has(key):
			continue
		seen[key] = true
		var s := Sprite2D.new()
		s.texture = path_tex
		s.position = p
		s.centered = true
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var base_scale := 0.5 if path_tex.get_width() >= 64 else 1.0
		var jitter := 0.96 + 0.08 * float(n % 3)
		s.scale = Vector2(base_scale * jitter, base_scale * (1.92 - jitter))
		s.modulate = Color(0.97 + 0.02 * float(n % 2), 0.98, 0.95, 1.0)
		paths.add_child(s)
		n += 1

	# Subtle edge darkening for stone pathway definition
	var edge_line := Line2D.new()
	edge_line.width = 2.0
	edge_line.default_color = Color(0.35, 0.32, 0.28, 0.18)
	edge_line.points = PackedVector2Array([Vector2(610, 240), Vector2(610, 640), Vector2(670, 640), Vector2(670, 240)])
	paths.add_child(edge_line)


func _configure_hedges() -> void:
	var hedges := get_node_or_null("RoyalGarden/GardenHedges")
	if hedges == null or not hedges.has_method("add_hedge"):
		return
	# Clear previous dynamic hedges except none authored
	for child in hedges.get_children():
		child.queue_free()
	# Symmetrical formal hedge layout
	for y in [305, 385, 470]:
		for x in [360, 920]:
			hedges.call("add_hedge", Vector2(x, y), true)
	for x in [440, 520, 760, 840]:
		hedges.call("add_hedge", Vector2(x, 305), true)
		hedges.call("add_hedge", Vector2(x, 470), true)
	for p in [Vector2(500, 250), Vector2(780, 250), Vector2(460, 290), Vector2(820, 290), Vector2(560, 470), Vector2(720, 470)]:
		hedges.call("add_hedge", p, true)


func _configure_water_and_bridges() -> void:
	var wf := get_node_or_null("WaterFeatures")
	if wf == null:
		return
	for child in wf.get_children():
		child.queue_free()

	# Larger symmetrical ponds
	_add_large_pond(wf, Vector2(430, 545))
	_add_large_pond(wf, Vector2(850, 545))

	# Waterfalls flanking castle approach
	if wf.has_method("add_waterfall"):
		wf.call("add_waterfall", Vector2(350, 230))
		wf.call("add_waterfall", Vector2(930, 230))

	# Bridges
	if wf.has_method("add_bridge"):
		wf.call("add_bridge", Vector2(430, 505))
		wf.call("add_bridge", Vector2(850, 505))

	# Simple animated water shimmer effects (lightweight)
	_add_water_shimmer(wf, Vector2(430, 545))
	_add_water_shimmer(wf, Vector2(850, 545))


func _add_large_pond(parent: Node2D, pos: Vector2) -> void:
	var tex := load("res://assets/environment/castle_gardens/pond_large.png") as Texture2D
	if tex == null and parent.has_method("add_pond"):
		parent.call("add_pond", pos)
		return
	var root := Node2D.new()
	root.position = pos
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = true
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.offset = Vector2(0, -2)
	root.add_child(s)
	var body := StaticBody2D.new()
	var col := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 14.0
	shape.height = 56.0
	col.shape = shape
	col.rotation = PI * 0.5
	col.position = Vector2(0, 4)
	body.add_child(col)
	root.add_child(body)
	parent.add_child(root)


func _add_water_shimmer(parent: Node2D, pos: Vector2) -> void:
	var ring := Line2D.new()
	ring.width = 1.5
	ring.default_color = Color(0.75, 0.92, 1.0, 0.35)
	ring.position = pos
	var pts := PackedVector2Array()
	for i in range(17):
		var a := TAU * float(i) / 16.0
		pts.append(Vector2(cos(a) * 26.0, sin(a) * 10.0))
	ring.points = pts
	parent.add_child(ring)
	var tw := create_tween().set_loops()
	tw.tween_property(ring, "modulate:a", 0.15, 1.4)
	tw.tween_property(ring, "modulate:a", 0.45, 1.4)


func _configure_decor() -> void:
	var decor := get_node_or_null("RoyalGarden/DecorativeProps")
	if decor == null:
		return
	for child in decor.get_children():
		child.queue_free()

	if decor.has_method("add_bench"):
		decor.call("add_bench", Vector2(560, 430), false)
		decor.call("add_bench", Vector2(720, 430), true)
		decor.call("add_bench", Vector2(560, 510), false)
		decor.call("add_bench", Vector2(720, 510), true)
	if decor.has_method("add_lantern"):
		for p in [Vector2(600, 580), Vector2(680, 580), Vector2(600, 500), Vector2(680, 500), Vector2(600, 420), Vector2(680, 420), Vector2(600, 340), Vector2(680, 340), Vector2(600, 270), Vector2(680, 270)]:
			decor.call("add_lantern", p)
	if decor.has_method("add_urn"):
		for p in [Vector2(500, 350), Vector2(780, 350), Vector2(500, 450), Vector2(780, 450), Vector2(640, 300), Vector2(640, 430)]:
			decor.call("add_urn", p)


func _configure_lighting_and_effects() -> void:
	var lighting := get_node_or_null("Lighting") as Node2D
	var effects := get_node_or_null("EnvironmentEffects") as Node2D
	if lighting != null:
		for child in lighting.get_children():
			child.queue_free()
		# Warm lantern glows and focal highlights
		for pos in [Vector2(600, 560), Vector2(680, 560), Vector2(600, 480), Vector2(680, 480), Vector2(600, 400), Vector2(680, 400), Vector2(600, 320), Vector2(680, 320), Vector2(600, 250), Vector2(680, 250)]:
			var light := PointLight2D.new()
			light.position = pos + Vector2(0, -18)
			light.color = Color(1.0, 0.88, 0.62, 0.75)
			light.energy = 0.45
			light.texture_scale = 0.85
			light.texture = _make_radial_light_texture()
			lighting.add_child(light)
		# Prominent fountain landmark glow
		var fountain_glow := PointLight2D.new()
		fountain_glow.position = Vector2(640, 338)
		fountain_glow.color = Color(0.75, 0.92, 1.0, 0.8)
		fountain_glow.energy = 0.7
		fountain_glow.texture_scale = 1.4
		fountain_glow.texture = _make_radial_light_texture()
		lighting.add_child(fountain_glow)
		# Soft castle-face shadowing/depth cue
		var castle_shadow := ColorRect.new()
		castle_shadow.position = Vector2(430, 120)
		castle_shadow.size = Vector2(420, 20)
		castle_shadow.color = Color(0.05, 0.05, 0.08, 0.10)
		castle_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lighting.add_child(castle_shadow)

	if effects != null:
		for child in effects.get_children():
			child.queue_free()
		# Subtle ambient particles (performant)
		var particles := CPUParticles2D.new()
		particles.position = Vector2(640, 360)
		particles.amount = 24
		particles.lifetime = 4.5
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = Vector2(420, 220)
		particles.direction = Vector2(0, -1)
		particles.gravity = Vector2(0, -3)
		particles.initial_velocity_min = 3.0
		particles.initial_velocity_max = 10.0
		particles.scale_amount_min = 0.5
		particles.scale_amount_max = 1.1
		particles.color = Color(1.0, 0.97, 0.88, 0.18)
		effects.add_child(particles)
		# Fountain sparkle accent to make it a prominent landmark
		var sparkles := CPUParticles2D.new()
		sparkles.position = Vector2(640, 340)
		sparkles.amount = 10
		sparkles.lifetime = 1.6
		sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		sparkles.emission_sphere_radius = 14.0
		sparkles.direction = Vector2(0, -1)
		sparkles.gravity = Vector2(0, 8)
		sparkles.initial_velocity_min = 6.0
		sparkles.initial_velocity_max = 16.0
		sparkles.scale_amount_min = 0.4
		sparkles.scale_amount_max = 0.9
		sparkles.color = Color(0.82, 0.95, 1.0, 0.55)
		effects.add_child(sparkles)


func _make_radial_light_texture() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var c := Vector2(32, 32)
	for y in range(64):
		for x in range(64):
			var d := Vector2(x, y).distance_to(c) / 32.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = pow(a, 2.2)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _add_static_circle(parent: Node2D, pos: Vector2, radius: float) -> void:
	var body := StaticBody2D.new()
	body.position = pos
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)


func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	GameState.set_player_position(player.position)
	GameState.set_region_position(region_id, player.position)
	_save_accumulator += delta
	if _save_accumulator >= SAVE_POSITION_INTERVAL:
		_save_accumulator = 0.0
		GameState.save_now()


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	player.name = "Player"
	var placed := false
	# 1) Explicit entry point for region/world transitions.
	if not entry_point.is_empty():
		var eps: Variant = ContentDB.get_region(region_id).get("entry_points", {})
		if typeof(eps) == TYPE_DICTIONARY and (eps as Dictionary).has(entry_point):
			var g: Variant = (eps as Dictionary)[entry_point]
			if typeof(g) == TYPE_ARRAY and (g as Array).size() == 2:
				var ga: Array = g
				player.position = IsoMath.grid_to_world(float(ga[0]), float(ga[1]))
				placed = true
	# 2) Resume this world's saved position.
	if not placed and GameState.player_region == region_id and GameState.has_region_position(region_id):
		var saved_position := GameState.region_position(region_id)
		if saved_position.length_squared() > 1.0:
			player.position = saved_position
			placed = true
	# 3) Legacy single-slot position fallback for this active world.
	if not placed and GameState.has_player_position and GameState.player_region == region_id:
		player.position = GameState.player_position
		placed = true
	if not placed:
		player.position = _get_spawn_position("PlayerSpawn")
	var resolved_spawn := player.position
	entities.add_child(player)
	player.global_position = entities.to_global(resolved_spawn)
	if player.has_method("reset_physics_interpolation"):
		player.reset_physics_interpolation()
	if player.has_method("restore_facing"):
		player.restore_facing(GameState.player_facing)
	GameState.set_player_region(region_id)
	GameState.set_player_position(player.position)
	GameState.set_region_position(region_id, player.position)


func _get_spawn_position(marker_name: String) -> Vector2:
	if spawn_points == null:
		return Vector2(640, 620)
	var marker := spawn_points.get_node_or_null(marker_name) as Node2D
	if marker != null:
		return marker.position
	for child in spawn_points.get_children():
		if child is Node2D:
			return (child as Node2D).position
	return Vector2(640, 620)


func _spawn_npcs_from_markers() -> void:
	if npc_placement == null:
		return
	for marker in npc_placement.get_children():
		if not (marker is Node2D):
			continue
		var m := marker as Node2D
		var dialogue_id := str(m.get_meta("dialogue_id", ""))
		if dialogue_id.is_empty():
			continue
		var npc_id := str(m.get_meta("npc_id", m.name))
		var display_name := str(m.get_meta("display_name", npc_id.capitalize()))
		var role := str(m.get_meta("role", "Royal Attendant"))
		var palette_val: Variant = m.get_meta("palette", {
			"hair": "#c9b07a", "primary": "#4a5a7a", "secondary": "#d0b070",
			"accent": "#7fe3e0", "skin": "#e8c8a8",
		})
		var palette: Dictionary = palette_val if typeof(palette_val) == TYPE_DICTIONARY else {}
		var race := str(m.get_meta("race", "Human"))
		var npc := NPC_SCENE.instantiate() as WorldNPC
		npc.role = role
		npc.setup(npc_id, display_name, dialogue_id, palette, race)
		npc.position = m.position
		entities.add_child(npc)
		npcs.append(npc)


func get_spawn_points() -> Array[Node2D]:
	var result: Array[Node2D] = []
	if spawn_points == null:
		return result
	for child in spawn_points.get_children():
		if child is Node2D:
			result.append(child as Node2D)
	return result


func get_npc_placement_points() -> Array[Node2D]:
	var result: Array[Node2D] = []
	if npc_placement == null:
		return result
	for child in npc_placement.get_children():
		if child is Node2D:
			result.append(child as Node2D)
	return result


func current_area_name() -> String:
	return "Castle Royal Gardens"


func day_phase() -> String:
	return "day"

# Reusable world interface for minimap/HUD/world consumers.
func get_world_npcs() -> Array:
	return npcs

func get_world_monsters() -> Array:
	return monsters

func is_water_world(_pos: Vector2) -> bool:
	# Castle gardens use authored water features, not procedural water terrain.
	return false
