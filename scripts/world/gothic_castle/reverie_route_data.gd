class_name ReverieRouteData
extends RefCounted
## Shared, testable layout contract for the Royal Road and Baltoria arena.
##
## All points are IsoMath grid cells: world = ((gx - gy) * 32, (gx + gy) * 16).
## The world builder, minimap data, quest navigation and automated tests all
## read this single source of truth, so routes cannot drift apart.

const ORIGIN := Vector2(640, 360)

## Main route, in order. Consecutive waypoints are connected by straight
## runs along +X or -Y so every tile is a cardinal isometric step.
const MAIN_WAYPOINTS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(14, 0), Vector2i(14, 8), Vector2i(30, 8),
	Vector2i(30, -4), Vector2i(46, -4), Vector2i(46, 4), Vector2i(60, 4),
]

## Optional branches: each starts on the main route and ends at a POI.
const BRANCH_BLOSSOM: Array[Vector2i] = [Vector2i(8, 0), Vector2i(8, -10), Vector2i(18, -10)]
const BRANCH_WITHERED: Array[Vector2i] = [Vector2i(26, 8), Vector2i(26, 18), Vector2i(38, 18)]
const BRANCH_AQUEDUCT: Array[Vector2i] = [Vector2i(38, -4), Vector2i(38, -14), Vector2i(52, -14)]

const BRANCHES: Dictionary = {
	"blossom_hollow": BRANCH_BLOSSOM,
	"withered_grove": BRANCH_WITHERED,
	"fallen_aqueduct": BRANCH_AQUEDUCT,
}

## Grid bounds of the authored ground sheet.
const GRID_MIN := Vector2i(-9, -20)
const GRID_MAX := Vector2i(72, 24)

## Castle landmark (sealed, inaccessible) and boss arena.
const CASTLE_CENTER := Vector2i(22, -12)
const ARENA_CENTER := Vector2i(60, 4)
const ARENA_RADIUS := 9

## Points that grant a one-time exploration XP reward (flag key -> grid, xp).
const DISCOVERIES: Array = [
	{"flag": "discovered_blossom_hollow", "grid": Vector2i(18, -10), "xp": 80, "name": "Blossom Hollow"},
	{"flag": "discovered_withered_grove", "grid": Vector2i(38, 18), "xp": 120, "name": "Withered Grove"},
	{"flag": "discovered_fallen_aqueduct", "grid": Vector2i(52, -14), "xp": 160, "name": "Fallen Aqueduct"},
	{"flag": "discovered_gothic_castle", "grid": Vector2i(22, -12), "xp": 200, "name": "Gothic Castle"},
	{"flag": "discovered_arena_gate", "grid": Vector2i(58, 2), "xp": 260, "name": "Baltoria's Arena"},
]

## Material gathering nodes and hidden treasures (id, grid, rewards, label, hidden).
const GATHER_NODES: Array = [
	{"id": "road_herbs", "grid": Vector2i(4, -2), "items": {"glade_sap": 1}, "label": "Roadside Herbs", "hidden": false},
	{"id": "blossom_petals", "grid": Vector2i(14, -8), "items": {"royal_seal": 1}, "label": "Blossom Petals", "hidden": true},
	{"id": "grove_resin", "grid": Vector2i(32, 14), "items": {"blight_resin": 1}, "label": "Blight Resin", "hidden": false},
	{"id": "grove_cache", "grid": Vector2i(36, 17), "items": {"ancient_coins": 2, "blight_resin": 2}, "label": "Hidden Warden Cache", "hidden": true},
	{"id": "aqueduct_shard", "grid": Vector2i(44, -12), "items": {"gothic_shard": 1}, "label": "Masonry Shard", "hidden": false},
	{"id": "aqueduct_cache", "grid": Vector2i(50, -13), "items": {"gothic_shard": 2, "ancient_coins": 2}, "label": "Sealed Reliquary", "hidden": true},
	{"id": "arena_cinder", "grid": Vector2i(56, 8), "items": {"gothic_shard": 1}, "label": "Arena Cinder", "hidden": false},
]

## The three world NPCs (marker name, npc id, display name, dialogue, grid, palette key).
const NPCS: Array = [
	{"marker": "RoadWarden", "npc_id": "road_warden", "name": "Road Warden Elowen",
	 "dialogue": "road_warden", "grid": Vector2i(2, 2), "race": "Elf", "palette": "gold"},
	{"marker": "BlightWarden", "npc_id": "blight_warden", "name": "Warden Corvin",
	 "dialogue": "blight_warden", "grid": Vector2i(30, 14), "race": "Human", "palette": "violet"},
	{"marker": "ArenaGatekeeper", "npc_id": "arena_gatekeeper", "name": "Gatekeeper Sable",
	 "dialogue": "arena_gatekeeper", "grid": Vector2i(58, 2), "race": "Human", "palette": "silver"},
]


## Expands a waypoint polyline into every individual grid cell it covers.
static func cells_of(points: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for i in range(points.size() - 1):
		var a: Vector2i = points[i]
		var b: Vector2i = points[i + 1]
		var dx: int = signi(b.x - a.x)
		var dy: int = signi(b.y - a.y)
		var steps: int = maxi(absi(b.x - a.x), absi(b.y - a.y))
		for s in range(steps + 1):
			var cell := Vector2i(a.x + dx * s, a.y + dy * s)
			if not cells.has(cell):
				cells.append(cell)
	return cells


static func main_cells() -> Array[Vector2i]:
	return cells_of(MAIN_WAYPOINTS)


static func all_path_cells() -> Dictionary:
	var result := {}
	for cell in main_cells():
		result[cell] = "main"
	for branch_name in BRANCHES:
		for cell in cells_of(BRANCHES[branch_name]):
			if not result.has(cell):
				result[cell] = str(branch_name)
	return result


## Progress along the main route, 0.0 at the gate and 1.0 at the arena.
## Used to blend royal grass into corrupted stone gradually.
static func progress_at(cell: Vector2i) -> float:
	var path := main_cells()
	var best_index := 0
	var best_dist := 1e9
	for i in range(path.size()):
		var d := Vector2(path[i]).distance_to(Vector2(cell))
		if d < best_dist:
			best_dist = d
			best_index = i
	return float(best_index) / maxf(1.0, float(path.size() - 1))


static func in_arena(cell: Vector2i) -> bool:
	return Vector2(cell).distance_to(Vector2(ARENA_CENTER)) <= float(ARENA_RADIUS)


static func castle_wall_cells() -> Array[Vector2i]:
	## Closed rectangle of wall cells; the castle is a sealed landmark.
	var cells: Array[Vector2i] = []
	var c := CASTLE_CENTER
	for x in range(c.x - 6, c.x + 7):
		cells.append(Vector2i(x, c.y - 4))
		cells.append(Vector2i(x, c.y + 4))
	for y in range(c.y - 3, c.y + 4):
		cells.append(Vector2i(c.x - 6, y))
		cells.append(Vector2i(c.x + 6, y))
	return cells
