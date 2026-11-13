extends Node
const EXPECTED := {
	"willow_tree": "res://assets/environment/greenward/willow_tree.svg",
	"birch_tree": "res://assets/environment/moonpetal/silver_birch.svg",
	"pine_tree": "res://assets/environment/greenward/pine_tree.svg",
	"blossom_tree": "res://assets/environment/greenward/blossom_tree.svg",
	"dead_tree": "res://assets/environment/greenward/dead_tree.svg",
	"bush": "res://assets/environment/greenward/forest_shrub.svg",
	"spirit_bloom": "res://assets/environment/moonpetal/spirit_bloom.svg",
	"moon_lantern": "res://assets/environment/moonpetal/moon_lantern.svg",
	"ancient_tree": "res://assets/environment/greenward/ancient_oak.svg",
	"moss_rock": "res://assets/environment/greenward/moss_rock.svg",
	"cottage": "res://assets/environment/greenward/woodland_cottage.svg",
	"fern": "res://assets/environment/greenward/fern.svg",
	"flower_cluster": "res://assets/environment/greenward/wildflower_patch.svg",
	"stone_bridge": "res://assets/environment/greenward/stone_bridge.svg",
}
func _ready() -> void:
	call_deferred("_run")
func _run() -> void:
	var failures := 0
	for kind in EXPECTED:
		var path := str(EXPECTED[kind])
		var direct := load(path) as Texture2D
		var routed := ProceduralArt.prop_texture(kind, 0)
		var ok := direct != null and routed != null and direct == routed
		if ok:
			print("[environment-art] PASS ", kind, " ", routed.get_width(), "x", routed.get_height())
		else:
			failures += 1
			printerr("[environment-art] FAIL ", kind, " path=", path, " direct=", direct, " routed=", routed)
	# Verify stable cache identity, including nonzero variants.
	var first := ProceduralArt.prop_texture("willow_tree", 1)
	var second := ProceduralArt.prop_texture("willow_tree", 1)
	if first == second:
		print("[environment-art] PASS authored texture cache")
	else:
		failures += 1
		printerr("[environment-art] FAIL authored texture cache")
	print("[environment-art] ", "OK" if failures == 0 else "FAILED: %d" % failures)
	get_tree().quit(1 if failures > 0 else 0)
