class_name GothicCastleEnvironmentComponent
extends Node
## Compatibility facade and shared asset factory for the Gothic Castle world.
## Ground, castle architecture, boss arena, route dressing and bounds are
## separately authored child nodes with one focused responsibility.

const PIECE_ROOT := "res://scenes/world/reverie_pack/%s/%s/%s.tscn"
const TEX_ROOT := "res://assets/reverie_pack_v01/%s/%s/%s.png"

var world: GothicCastleBossZone
var ground_layer: Node2D
var path_layer: Node2D
var castle_layer: Node2D
var arena_layer: Node2D
var flora_layer: Node2D
var props_layer: Node2D
var effects_layer: Node2D
var _textures: Dictionary = {}
var _pieces: Dictionary = {}
var _water_cells: Dictionary = {}

@onready var ground_builder: GothicGroundBuilderComponent = $GroundBuilder
@onready var architecture_builder: GothicCastleArchitectureComponent = $ArchitectureBuilder
@onready var arena_builder: GothicBossArenaBuilderComponent = $ArenaBuilder
@onready var route_decoration: GothicRouteDecorationComponent = $RouteDecoration
@onready var bounds_builder: GothicWorldBoundsComponent = $BoundsBuilder

func build(owner_world: GothicCastleBossZone) -> void:
	world = owner_world
	ground_layer = world.ground_layer
	path_layer = world.path_layer
	castle_layer = world.castle_layer
	arena_layer = world.arena_layer
	flora_layer = world.flora_layer
	props_layer = world.props_layer
	effects_layer = world.effects_layer
	_water_cells = world._water_cells
	for layer in [ground_layer, path_layer, castle_layer, arena_layer, flora_layer, props_layer, effects_layer]:
		if layer == null:
			continue
		for child in layer.get_children():
			child.free()
	for component in [ground_builder, architecture_builder, arena_builder, route_decoration, bounds_builder]:
		component.configure(self)
	ground_builder._build_ground()
	architecture_builder._build_bridge_and_stairs()
	architecture_builder._build_castle()
	arena_builder._build_arena()
	route_decoration._decorate_route()
	bounds_builder._build_bounds()

func _texture(category: String, subfolder: String, asset_id: String) -> Texture2D:
	var key := "%s/%s/%s" % [category, subfolder, asset_id]
	if _textures.has(key):
		return _textures[key] as Texture2D
	var path := TEX_ROOT % [category, subfolder, asset_id]
	var tex := load(path) as Texture2D
	_textures[key] = tex
	return tex

func _piece(category: String, subfolder: String, asset_id: String) -> PackedScene:
	var key := "%s/%s/%s" % [category, subfolder, asset_id]
	if _pieces.has(key):
		return _pieces[key] as PackedScene
	var path := PIECE_ROOT % [category, subfolder, asset_id]
	var scene := load(path) as PackedScene
	_pieces[key] = scene
	return scene

func _add_tile(category: String, subfolder: String, asset_id: String, cell: Vector2i, z: int = -20) -> Sprite2D:
	var tex := _texture(category, subfolder, asset_id)
	if tex == null:
		return null
	var sprite := Sprite2D.new()
	sprite.name = "Tile_%d_%d_%s" % [cell.x, cell.y, asset_id]
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.offset = Vector2(-32, -16)
	sprite.position = IsoMath.grid_to_world(float(cell.x), float(cell.y))
	sprite.z_index = z
	ground_layer.add_child(sprite)
	return sprite

func _place(category: String, subfolder: String, asset_id: String, anchor: Vector2i,
		parent: Node2D, z: int = 0) -> ReveriePiece:
	var scene := _piece(category, subfolder, asset_id)
	if scene == null:
		return null
	var piece := scene.instantiate() as ReveriePiece
	if piece == null:
		return null
	piece.name = "%s_%d_%d" % [asset_id, anchor.x, anchor.y]
	piece.position = piece.footprint_center_world(Vector2(anchor))
	piece.z_index = z
	parent.add_child(piece)
	return piece

func _inside_castle(cell: Vector2i) -> bool:
	var c := ReverieRouteData.CASTLE_CENTER
	return cell.x >= c.x - 5 and cell.x <= c.x + 5 and cell.y >= c.y - 3 and cell.y <= c.y + 3

func _is_bridge_water(cell: Vector2i) -> bool:
	## Narrow channel crossing on the Fallen Aqueduct branch.
	var b := ReverieRouteData.BRANCH_AQUEDUCT[2]
	return cell.x >= b.x - 4 and cell.x <= b.x - 2 and cell.y >= b.y - 2 and cell.y <= b.y + 2
