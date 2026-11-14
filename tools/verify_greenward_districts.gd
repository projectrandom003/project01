extends Node
## Regression checks for Greenward's node-authored district and road structure.

const VILLAGE_SCENE: PackedScene = preload("res://scenes/world/village/GreenwardVillage.tscn")

var checks := 0
var failures := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var village := VILLAGE_SCENE.instantiate() as VillageEnvironment
	add_child(village)
	await get_tree().process_frame
	_check(village != null, "Greenward village scene instantiates")
	_check(village.layout_config is VillageLayoutConfig, "root retains its layout resource")
	_check(village.get_district_ids().size() == 6, "village exposes six scoped district IDs")
	_check(village.get_district(&"missing") == null, "unknown district lookup safely returns null")
	var expected := {
		"EntranceDistrict": [&"entrance", Vector2(230, 256), ["EntranceGatePath"]],
		"CentralSquareDistrict": [&"central_square", Vector2(0, 256), ["CentralSquare"]],
		"CivicDistrict": [&"civic", Vector2(-70, 218), ["ToElderPath"]],
		"MarketDistrict": [&"market", Vector2(150, 350), ["ToMarketPath"]],
		"ResidentialDistrict": [&"residential", Vector2(40, 188), ["ResidentialNorthPath", "ResidentialSouthPath"]],
		"ShrineRiversideDistrict": [&"shrine_riverside", Vector2(-145, 270), ["ToShrinePath", "ToRiversidePath"]]
	}
	for district_name in expected:
		var district := village.get_node_or_null("PathNetwork/" + district_name) as VillageDistrict
		_check(district != null, district_name + " is a typed VillageDistrict node")
		if district == null:
			continue
		var spec: Array = expected[district_name]
		_check(village.get_district(spec[0]) == district, district_name + " resolves through village API")
		_check(village.get_district_navigation_position(spec[0]).is_equal_approx(spec[1]), district_name + " navigation API returns its anchor")
		_check(district.district_id == spec[0], district_name + " has stable district id")
		_check(district.scene_file_path == "res://scenes/world/village/VillageDistrict.tscn", district_name + " is an instance of the reusable district scene")
		_check(district.get_node_or_null("NavigationAnchor") is Marker2D, district_name + " owns an authored Marker2D navigation anchor")
		_check(district.get_navigation_position().is_equal_approx(spec[1]), district_name + " exposes correct navigation anchor")
		for path_name in spec[2]:
			_check(district.get_node_or_null(path_name) is VillagePathSegment, path_name + " is grouped under its district")
	_check(village.get_depth_sort_parent() != null, "depth-sort parent remains available")
	_check(village.get_depth_sort_parent().get_child_count() > 0, "authored and generated village visuals populate")
	print("[greenward_districts] %s — %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	village.queue_free()
	await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("[greenward_districts] FAIL: " + label)
