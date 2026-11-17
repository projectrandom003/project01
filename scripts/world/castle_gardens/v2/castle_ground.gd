class_name CastleGround
extends Node2D
## Paints the Castle & Royal Gardens ground with Castle Asset Pack v0.2 terrain.
##
## The pack ships seamless 64x32 isometric tiles (grass_01..03, path_cobble_01
## and the four grass/path transition tiles). They sit on exactly the same
## diamond lattice the rest of the project uses (IsoMath: 64x32 cells), so the
## ground, the props, the minimap and the region POI grid all agree.
##
## Every tile stays an individual PNG and its own node, so a designer can still
## select and retile any part of the ground.

const TILE_W := 64.0
const TILE_H := 32.0
const TILE_SCENE: PackedScene = preload("res://scenes/world/castle_gardens/components/castle_terrain_tile.tscn")

const GRASS_1 := "res://assets/castle_pack_v02/environment/terrain/grass_01.png"
const GRASS_2 := "res://assets/castle_pack_v02/environment/terrain/grass_02.png"
const GRASS_3 := "res://assets/castle_pack_v02/environment/terrain/grass_03.png"
const COBBLE := "res://assets/castle_pack_v02/environment/terrain/path_cobble_01.png"
const EDGE_NE := "res://assets/castle_pack_v02/environment/terrain/grass_path_edge_ne.png"
const EDGE_SE := "res://assets/castle_pack_v02/environment/terrain/grass_path_edge_se.png"
const EDGE_SW := "res://assets/castle_pack_v02/environment/terrain/grass_path_edge_sw.png"
const EDGE_NW := "res://assets/castle_pack_v02/environment/terrain/grass_path_edge_nw.png"

var _rng := RandomNumberGenerator.new()
var _textures: Dictionary = {}


func _ready() -> void:
	_rng.seed = 9001
	_load_textures()
	build()


func _load_textures() -> void:
	for path in [GRASS_1, GRASS_2, GRASS_3, COBBLE, EDGE_NE, EDGE_SE, EDGE_SW, EDGE_NW]:
		var tex := load(path) as Texture2D
		if tex != null:
			_textures[path] = tex


## Builds one Sprite2D per cell that contributes to the authored screen rect.
func build() -> void:
	for child in get_children():
		child.queue_free()
	for gy in range(CastleLayout.GRID_MIN.y, CastleLayout.GRID_MAX.y + 1):
		for gx in range(CastleLayout.GRID_MIN.x, CastleLayout.GRID_MAX.x + 1):
			if not CastleLayout.covers_screen_rect(gx, gy):
				continue
			_add_tile(gx, gy)


func _add_tile(gx: int, gy: int) -> void:
	var path := _texture_for(gx, gy)
	if path.is_empty():
		return
	var tex: Texture2D = _textures.get(path, null)
	if tex == null:
		return
	var tile := TILE_SCENE.instantiate() as Node2D
	var sprite := tile.get_node("Sprite") as Sprite2D
	sprite.texture = tex
	sprite.centered = false
	# The pack pivot is the tile centre; with centered = false the offset is
	# -pivot so the diamond sits exactly on the cell origin.
	sprite.offset = Vector2(-TILE_W * 0.5, -TILE_H * 0.5)
	tile.position = IsoMath.grid_to_world(float(gx), float(gy))
	sprite.z_index = -20
	tile.name = "Tile_%d_%d" % [gx, gy]
	add_child(tile)


## Chooses the tile for a cell: cobble on the promenade/axis, a grass variant
## on open lawn, and the authored transition tile where lawn meets stone.
func _texture_for(gx: int, gy: int) -> String:
	if CastleLayout.is_path(gx, gy):
		return COBBLE
	var variant := GRASS_1
	var roll := _rng.randi_range(0, 2)
	if roll == 1:
		variant = GRASS_2
	elif roll == 2:
		variant = GRASS_3
	# Transition tiles show the path bleeding onto the lawn edge, so they belong
	# on the lawn cell that touches a single stone neighbour.
	# Screen directions: +gx = down-right (SE), +gy = down-left (SW).
	var path_neighbours := 0
	var edge := ""
	if CastleLayout.is_path(gx, gy - 1):
		path_neighbours += 1
		edge = EDGE_NE
	if CastleLayout.is_path(gx + 1, gy):
		path_neighbours += 1
		edge = EDGE_SE
	if CastleLayout.is_path(gx, gy + 1):
		path_neighbours += 1
		edge = EDGE_SW
	if CastleLayout.is_path(gx - 1, gy):
		path_neighbours += 1
		edge = EDGE_NW
	if path_neighbours == 1:
		return edge
	return variant
