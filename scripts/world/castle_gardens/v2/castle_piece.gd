class_name CastlePiece
extends Node2D
## Base class for every Castle Asset Pack v0.2 piece scene.
##
## The pack freezes one contract for all assets (see
## assets/castle_pack_v02/docs/SPEC.md):
##   * the pivot is the centre of the object's footprint ON THE GROUND,
##   * Sprite2D uses centered = false with offset = -pivot so the node origin
##     is the pivot (see manifest "sprite2d_offset_if_centered_false"),
##   * the footprint is expressed in cells (W along +X, D along +Y).
##
## This class only carries that metadata so the world builder can place a piece
## on the isometric grid and derive its collision footprint. It never bakes or
## flattens any art: every asset stays an individual, editable PNG.

@export var piece_id: String = ""
@export var footprint_cells: Vector2i = Vector2i(1, 1)


## Offset (in world pixels) between the anchor cell centre and the centre of
## this piece's footprint. Mirrors IsoMath's isometric projection:
##   +X goes screen right-down, +Y goes screen left-down.
func footprint_center_offset() -> Vector2:
	var w := float(footprint_cells.x - 1) * 0.5
	var d := float(footprint_cells.y - 1) * 0.5
	return Vector2((w - d) * 32.0, (w + d) * 16.0)


## World position of the footprint centre for a piece anchored at `anchor_cell`.
func footprint_center_world(anchor_cell: Vector2) -> Vector2:
	return IsoMath.grid_to_world(anchor_cell.x + float(footprint_cells.x - 1) * 0.5, anchor_cell.y + float(footprint_cells.y - 1) * 0.5)


## Grid cells covered by this piece when anchored at `anchor_cell`.
func covered_cells(anchor_cell: Vector2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for i in footprint_cells.x:
		for j in footprint_cells.y:
			result.append(Vector2i(anchor_cell.x + i, anchor_cell.y + j))
	return result
