extends Node
## Samples the centerlines of authored village routes against real world collision bodies.

const VILLAGE_SCENE: PackedScene = preload("res://scenes/world/village/GreenwardVillage.tscn")
const ROUTES := {
	"entrance": {"node": "PathNetwork/EntranceDistrict/EntranceGatePath", "from": Vector2(115, 256), "to": Vector2(320, 256), "step": 20.0},
	"central_square": {"node": "PathNetwork/CentralSquareDistrict/CentralSquare", "from": Vector2(-110, 285), "to": Vector2(75, 285), "step": 20.0},
	"elder": {"node": "PathNetwork/CivicDistrict/ToElderPath", "from": Vector2(-110, 218), "to": Vector2(-25, 218), "step": 15.0},
	"market": {"node": "PathNetwork/MarketDistrict/ToMarketPath", "from": Vector2(35, 300), "to": Vector2(160, 300), "step": 15.0},
	"shrine": {"node": "PathNetwork/ShrineRiversideDistrict/ToShrinePath", "from": Vector2(-250, 270), "to": Vector2(-75, 270), "step": 15.0},
	"riverside": {"node": "PathNetwork/ShrineRiversideDistrict/ToRiversidePath", "from": Vector2(-275, 308), "to": Vector2(-145, 308), "step": 15.0},
	"residential_north": {"node": "PathNetwork/ResidentialDistrict/ResidentialNorthPath", "from": Vector2(-105, 175), "to": Vector2(155, 175), "step": 20.0},
	"residential_south": {"node": "PathNetwork/ResidentialDistrict/ResidentialSouthPath", "from": Vector2(-175, 300), "to": Vector2(85, 300), "step": 20.0},
}
var checks := 0
var failures := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var village := VILLAGE_SCENE.instantiate()
	add_child(village)
	await get_tree().physics_frame
	var circle := CircleShape2D.new()
	circle.radius = 7.0
	var space := (village as Node2D).get_world_2d().direct_space_state
	for route_id in ROUTES:
		var route: Dictionary = ROUTES[route_id]
		var path_node := village.get_node_or_null(str(route["node"])) as Node2D
		_check(path_node != null, route_id + " route exists")
		if path_node == null:
			continue
		var start: Vector2 = route["from"]
		var finish: Vector2 = route["to"]
		var span := finish - start
		var count := mini(4, maxi(1, ceili(span.length() / float(route["step"]))))
		for i in range(count + 1):
			var point := start.lerp(finish, float(i) / float(count))
			var query := PhysicsShapeQueryParameters2D.new()
			query.shape = circle
			query.transform = Transform2D(0.0, point)
			query.collision_mask = 1
			query.collide_with_bodies = true
			query.collide_with_areas = false
			var hits := space.intersect_shape(query, 8)
			var hit_names: Array[String] = []
			for hit in hits:
				var collider := hit.get("collider") as Node
				hit_names.append(collider.get_path() if collider != null else "unknown")
			_check(hits.is_empty(), route_id + " walking centerline clear at " + str(point) + " blockers=" + ",".join(hit_names))
	print("[village_route_clearance] %s — %d samples, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	village.queue_free()
	await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[village_route_clearance] " + label)
