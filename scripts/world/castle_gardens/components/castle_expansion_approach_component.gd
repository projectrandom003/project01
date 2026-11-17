class_name CastleExpansionApproachComponent
extends Node
## Builds the ceremonial approach from scene-authored placement markers.
## Asset identity, target layer and grid position live in the placements scene.

const PIECE_ROOT := "res://scenes/world/reverie_pack/%s/%s/%s.tscn"
var _pieces: Dictionary = {}


func _ready() -> void:
	_build_expansion()


func _piece(category: String, subfolder: String, asset_id: String) -> PackedScene:
	var key := "%s/%s/%s" % [category, subfolder, asset_id]
	if _pieces.has(key):
		return _pieces[key] as PackedScene
	var scene := load(PIECE_ROOT % [category, subfolder, asset_id]) as PackedScene
	_pieces[key] = scene
	return scene


func _place(parent: Node2D, category: String, subfolder: String, asset_id: String, cell: Vector2i) -> Node2D:
	var scene := _piece(category, subfolder, asset_id)
	if scene == null:
		push_error("Castle approach could not load %s/%s/%s." % [category, subfolder, asset_id])
		return null
	var piece := scene.instantiate() as Node2D
	if piece == null:
		push_error("Castle approach asset %s is not a Node2D scene." % asset_id)
		return null
	piece.name = "%s_%d_%d" % [asset_id, cell.x, cell.y]
	var modular := piece as ReveriePiece
	piece.position = modular.footprint_center_world(Vector2(cell)) if modular != null else IsoMath.grid_to_world(float(cell.x), float(cell.y))
	parent.add_child(piece)
	return piece


func _layer(name: String) -> Node2D:
	var root := get_parent() as Node2D
	if root == null:
		push_error("Castle expansion approach requires its authored composition root.")
		return null
	var node := root.get_node_or_null(name) as Node2D
	if node == null:
		push_error("Castle expansion scene is missing its authored %s layer." % name)
	return node


func _build_expansion() -> void:
	var placements := get_parent().get_node_or_null("ApproachPlacements") as Node2D if get_parent() != null else null
	if placements == null:
		push_error("Castle expansion requires the authored ApproachPlacements scene.")
		return
	var layers := {
		"ExpansionGround": _layer("ExpansionGround"),
		"ExpansionFlora": _layer("ExpansionFlora"),
		"ExpansionProps": _layer("ExpansionProps"),
	}
	for marker in placements.get_children():
		if not (marker is Marker2D) or str(marker.get_meta("placement_type", "asset")) != "asset":
			continue
		var target_name := str(marker.get_meta("target_layer", ""))
		var target := layers.get(target_name) as Node2D
		var category := str(marker.get_meta("category", ""))
		var subfolder := str(marker.get_meta("subfolder", ""))
		var asset_id := str(marker.get_meta("asset_id", ""))
		var grid_value: Variant = marker.get_meta("grid_position", null)
		if target == null or category.is_empty() or subfolder.is_empty() or asset_id.is_empty() or not (grid_value is Vector2):
			push_error("Castle approach placement %s has incomplete authored metadata." % marker.name)
			continue
		_place(target, category, subfolder, asset_id, Vector2i(grid_value))
