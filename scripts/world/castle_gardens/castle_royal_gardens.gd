class_name CastleRoyalGardens
extends Node2D
## Compact, fully explorable Castle & Royal Gardens map (standalone scene).
## Separate from Greenward village; preserves all existing worlds/assets.

const PLAYER_SCENE: PackedScene = preload("res://scenes/characters/player.tscn")
const NPC_SCENE: PackedScene = preload("res://scenes/world/world_npc.tscn")

@onready var entities: Node2D = $Entities
@onready var spawn_points: Node2D = $MapSpawnPoints
@onready var npc_placement: Node2D = $NPCPlacement

var region_id: String = "castle_royal_gardens"
var player: Player
var npcs: Array = []
var monsters: Array = []


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


func _build_ground() -> void:
	var ground := get_node_or_null("Terrain/Ground") as Node2D
	if ground == null:
		return
	var grass_tex := load("res://assets/environment/castle_gardens/grass_tile.png") as Texture2D
	if grass_tex == null:
		return
	# Compact isometric-style diamond grid covering explorable area
	for gy in range(0, 14):
		for gx in range(0, 18):
			var pos := Vector2(180 + gx * 56 + (gy % 2) * 28, 140 + gy * 28)
			var s := Sprite2D.new()
			s.texture = grass_tex
			s.centered = true
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = pos
			ground.add_child(s)


func _configure_castle() -> void:
	var exterior := get_node_or_null("CastleExterior")
	if exterior != null and exterior.has_method("build_default"):
		exterior.call("build_default", Vector2.ZERO)
	var entrance := get_node_or_null("CastleEntrance")
	if entrance != null and entrance.has_method("build_default"):
		entrance.call("build_default", Vector2.ZERO)


func _configure_gardens() -> void:
	var garden := get_node_or_null("RoyalGarden")
	if garden != null and garden.has_method("build_symmetrical"):
		garden.call("build_symmetrical", Vector2.ZERO)
	var fountain := get_node_or_null("GardenFountain")
	# GardenFountain scene/script self-builds in _ready; ensure visible
	if fountain != null:
		fountain.visible = true


func _configure_paths() -> void:
	var paths := get_node_or_null("StonePathways")
	if paths == null:
		return
	var path_tex := load("res://assets/environment/castle_gardens/path_tile.png") as Texture2D
	# Central axis from player spawn up to castle entrance
	var points: Array[Vector2] = []
	for i in range(0, 13):
		points.append(Vector2(640, 620 - i * 34))
	# Horizontal garden cross paths
	for x in [-168, -112, -56, 0, 56, 112, 168]:
		points.append(Vector2(640 + x, 416))
		points.append(Vector2(640 + x, 484))
	# Side approaches to fountain plaza
	for i in range(0, 4):
		points.append(Vector2(472 - i * 28, 450 + i * 10))
		points.append(Vector2(808 + i * 28, 450 + i * 10))
	# Bridge approaches
	for i in range(0, 3):
		points.append(Vector2(520 - i * 20, 520))
		points.append(Vector2(760 + i * 20, 520))
	# De-duplicate roughly
	var seen := {}
	for p in points:
		var key := "%d_%d" % [int(round(p.x / 8.0)), int(round(p.y / 8.0))]
		if seen.has(key):
			continue
		seen[key] = true
		_add_path_sprite(paths, path_tex, p)

func _add_path_sprite(parent: Node2D, tex: Texture2D, pos: Vector2) -> void:
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = true
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = pos
	parent.add_child(s)


func _configure_hedges() -> void:
	var hedges := get_node_or_null("GardenHedges")
	if hedges == null or not hedges.has_method("add_hedge"):
		return
	# Symmetrical hedge borders forming garden rooms/corridors
	var y_rows := [300, 380, 460]
	for y in y_rows:
		for x in [380, 900]:
			hedges.call("add_hedge", Vector2(x, y), true)
	for x in [460, 540, 740, 820]:
		hedges.call("add_hedge", Vector2(x, 300), true)
		hedges.call("add_hedge", Vector2(x, 460), true)
	# Entrance framing hedges
	for p in [Vector2(520, 250), Vector2(760, 250), Vector2(480, 300), Vector2(800, 300)]:
		hedges.call("add_hedge", p, true)


func _configure_water_and_bridges() -> void:
	var wf := get_node_or_null("WaterFeatures")
	if wf == null:
		return
	# Symmetrical ponds/canals
	if wf.has_method("add_pond"):
		wf.call("add_pond", Vector2(430, 540))
		wf.call("add_pond", Vector2(850, 540))
	# Small side water features near castle walls
	if wf.has_method("add_waterfall"):
		wf.call("add_waterfall", Vector2(360, 240))
		wf.call("add_waterfall", Vector2(920, 240))
	# Bridges crossing water approach areas
	if wf.has_method("add_bridge"):
		wf.call("add_bridge", Vector2(430, 500))
		wf.call("add_bridge", Vector2(850, 500))


func _configure_decor() -> void:
	var decor := get_node_or_null("DecorativeProps")
	if decor == null:
		return
	# Benches along paths (symmetrical)
	if decor.has_method("add_bench"):
		decor.call("add_bench", Vector2(560, 420), false)
		decor.call("add_bench", Vector2(720, 420), true)
		decor.call("add_bench", Vector2(560, 500), false)
		decor.call("add_bench", Vector2(720, 500), true)
	# Lanterns lining central path and entrance
	if decor.has_method("add_lantern"):
		for p in [Vector2(600, 560), Vector2(680, 560), Vector2(600, 480), Vector2(680, 480), Vector2(600, 400), Vector2(680, 400), Vector2(600, 280), Vector2(680, 280)]:
			decor.call("add_lantern", p)
	# Urns/plants accents
	if decor.has_method("add_urn"):
		for p in [Vector2(500, 360), Vector2(780, 360), Vector2(500, 440), Vector2(780, 440)]:
			decor.call("add_urn", p)


func _process(_delta: float) -> void:
	if player != null and is_instance_valid(player):
		GameState.set_player_position(player.global_position)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	player.name = "Player"
	var spawn := _get_spawn_position("PlayerSpawn")
	player.position = spawn
	entities.add_child(player)
	player.global_position = to_global(spawn)
	if player.has_method("reset_physics_interpolation"):
		player.reset_physics_interpolation()
	GameState.set_player_position(player.position)


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
