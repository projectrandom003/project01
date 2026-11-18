class_name CastleLayout
extends RefCounted
## Shared layout data for the Castle & Royal Gardens (Castle Asset Pack v0.2).
##
## Everything is expressed in the project's isometric grid (IsoMath, 64x32
## cells). One grid means the ground tiles, the architecture pieces, the props,
## the collision footprints, the region POIs and the minimap all agree.
##
##   screen_x = (gx - gy) * 32   -> constant (gx - gy) is a screen-vertical line
##   screen_y = (gx + gy) * 16   -> constant (gx + gy) is a screen-horizontal line
##
## The screen-vertical spine (diff == SPINE_DIFF) runs from the castle gate
## down to the player spawn; the two cross axes are the garden avenues.

## Screen-space rect the ground covers (matches regions.json "map_bounds").
const SCREEN_MIN := Vector2(-480, -360)
const SCREEN_MAX := Vector2(1920, 1440)

## The screen-vertical spine: constant (gx - gy). Castle gate -> spawn.
const SPINE_DIFF := 20

## The screen-horizontal garden avenues: constant (gx + gy).
const CROSS_SUMS: Array[int] = [26, 27, 29, 30, 31, 32, 35, 36, 37]

## Castle enclosure in grid space (walls, towers, gatehouse, courtyard).
const CASTLE_X := Vector2i(12, 21)
const CASTLE_Y := Vector2i(-8, -1)

## Reflecting pond cells (grid), matching the authored POIs.
const POND_LEFT: Array[Vector2i] = [
	Vector2i(23, 10), Vector2i(24, 10), Vector2i(25, 10),
	Vector2i(23, 11), Vector2i(24, 11), Vector2i(25, 11),
]
const POND_RIGHT: Array[Vector2i] = [
	Vector2i(29, 3), Vector2i(30, 3), Vector2i(31, 3),
	Vector2i(29, 4), Vector2i(30, 4), Vector2i(31, 4),
]

## Fountain cells (grid) and the paved plaza around it.
const FOUNTAIN_CELLS: Array[Vector2i] = [
	Vector2i(21, 1), Vector2i(22, 1), Vector2i(21, 2), Vector2i(22, 2),
]

## Hand-authored lower-side bypass around the west reflecting pond. The original
## west approach stopped at the pond edge; these stepping-stone cells reconnect
## it to the southern cross-avenue without paving across the water footprint.
const WEST_POND_BYPASS: Array[Vector2i] = [
	Vector2i(23, 12), Vector2i(25, 12), Vector2i(26, 12), Vector2i(26, 11),
]

## Grid bounds that can contain the authored screen rect.
const GRID_MIN := Vector2i(-14, -35)
const GRID_MAX := Vector2i(65, 45)


## True when the grid cell is one of the two reflecting ponds.
static func is_pond(gx: int, gy: int) -> bool:
	var cell := Vector2i(gx, gy)
	for p in POND_LEFT:
		if p == cell:
			return true
	for p in POND_RIGHT:
		if p == cell:
			return true
	return false


## True when the grid cell is inside the castle enclosure.
static func in_castle(gx: int, gy: int) -> bool:
	return gx >= CASTLE_X.x and gx <= CASTLE_X.y and gy >= CASTLE_Y.x and gy <= CASTLE_Y.y


## True when the grid cell is walkable stone: the spine, the garden avenues, the
## castle courtyard and the fountain plaza.
static func is_path(gx: int, gy: int) -> bool:
	if is_pond(gx, gy):
		return false
	var cell := Vector2i(gx, gy)
	if WEST_POND_BYPASS.has(cell):
		return true
	var diff := gx - gy
	var total := gx + gy
	# The main royal promenade is deliberately broad enough for the player and
	# companions to pass the gate without being squeezed against the wall edges.
	if abs(diff - SPINE_DIFF) <= 1 and total >= -10 and total <= 38:
		return true
	# A single diagonal branch leaves the main promenade toward the west reflecting pond.
	# It stops before the shoreline; the pond cells themselves remain water.
	if total in [33, 34, 35] and diff >= 13 and diff < SPINE_DIFF:
		return true
	if total in CROSS_SUMS and diff >= 10 and diff <= 30:
		return true
	# Paired cross-sums create a continuous-width cobblestone avenue rather than
	# isolated diamond tips; the southern pair also skirts both pond shorelines.
	if total in [29, 30, 31, 35, 36, 37] and diff >= 10 and diff <= 30:
		return true
	# Castle courtyard floor.
	if gx >= CASTLE_X.x + 1 and gx <= CASTLE_X.y - 1 and gy >= CASTLE_Y.x + 1 and gy <= CASTLE_Y.y - 1:
		return true
	# Fountain plaza.
	if diff >= 18 and diff <= 23 and total >= 19 and total <= 26:
		return true
	return false


## True when the grid cell is grass (neither path nor pond).
static func is_grass(gx: int, gy: int) -> bool:
	return not is_path(gx, gy) and not is_pond(gx, gy)


## Ground tile kind for a grid cell: "grass", "path" or "water".
static func tile_kind(gx: int, gy: int) -> String:
	if is_pond(gx, gy):
		return "water"
	if is_path(gx, gy):
		return "path"
	return "grass"


## True when the tile diamond centred on this cell overlaps the authored
## screen rect, i.e. when the cell contributes visible ground.
static func covers_screen_rect(gx: int, gy: int) -> bool:
	var pos := IsoMath.grid_to_world(float(gx), float(gy))
	return pos.x + 32.0 >= SCREEN_MIN.x and pos.x - 32.0 <= SCREEN_MAX.x \
		and pos.y + 16.0 >= SCREEN_MIN.y and pos.y - 16.0 <= SCREEN_MAX.y
