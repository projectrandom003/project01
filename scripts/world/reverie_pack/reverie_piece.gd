class_name ReveriePiece
extends Node2D
## Base class for every reusable piece scene generated from the delivered
## REVERIE asset pack (v1.0). The pack contract is identical to Castle Pack v0.2:
## the pivot is the centre of the footprint ON THE GROUND, Sprite2D uses
## centered=false with offset=-pivot, and a WxD footprint covers W*D grid cells.
##
## Keeping the metadata on the node means a designer can move / rotate / replace
## any individual piece without flattening the environment.

@export var asset_id: String = ""
@export var footprint_cells: Vector2i = Vector2i(1, 1)


func footprint_center_offset() -> Vector2:
	## Offset from the anchor cell centre to the footprint centre (world pixels).
	var w := float(footprint_cells.x - 1) * 0.5
	var d := float(footprint_cells.y - 1) * 0.5
	return Vector2((w - d) * 32.0, (w + d) * 16.0)


func footprint_center_world(anchor: Vector2) -> Vector2:
	return IsoMath.grid_to_world(anchor.x + float(footprint_cells.x - 1) * 0.5,
			anchor.y + float(footprint_cells.y - 1) * 0.5)


func covered_cells(anchor: Vector2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in footprint_cells.x:
		for j in footprint_cells.y:
			cells.append(Vector2i(int(anchor.x) + i, int(anchor.y) + j))
	return cells
