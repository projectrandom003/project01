extends SceneTree

const VILLAGE_SCENE: PackedScene = preload("res://scenes/world/village/GreenwardVillage.tscn")
const DISTRICTS := [
	"EntranceDistrict",
	"CentralSquareDistrict",
	"CivicDistrict",
	"MarketDistrict",
	"ResidentialDistrict",
	"ShrineRiversideDistrict",
]

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var village := VILLAGE_SCENE.instantiate() as Node2D
	root.add_child(village)
	await process_frame
	var network := village.get_node_or_null("PathNetwork") as Node2D
	_check(network != null, "path network exists")
	var path_count := 0
	for district_name in DISTRICTS:
		var district := network.get_node_or_null(district_name) as Node2D if network != null else null
		_check(district != null, "district node exists: " + district_name)
		if district == null:
			continue
		_check(str(district.get_meta("district_id", "")) != "", "district has stable id: " + district_name)
		for child in district.get_children():
			if child is VillagePathSegment:
				path_count += 1
				_check((child as VillagePathSegment).traversable, "path remains traversable: " + child.name)
				_check(not (child as VillagePathSegment).path_id.is_empty(), "path has stable id: " + child.name)
	_check(path_count == 8, "all eight authored route segments are assigned to a district")
	var plaza := village.get_node_or_null("PathNetwork/CentralSquareDistrict/CentralSquare/Visual/Surface") as Polygon2D
	_check(plaza != null and plaza.polygon.size() == 6, "central plaza is a six-sided open node-authored surface")
	print("[greenward_district_layout] %s — %d checks, %d failures, %d paths" % ["PASS" if failures == 0 else "FAIL", checks, failures, path_count])
	quit(0 if failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("[greenward_district_layout] FAIL: " + label)
