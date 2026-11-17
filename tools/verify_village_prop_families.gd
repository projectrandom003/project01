extends SceneTree
## Regression check: every prop kind authored in the canonical village scene
## resolves to real, distinct procedural art (no silent flower fallback).

var _checks := 0
var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var kinds: Array[String] = ["bench", "crate"]
	var flower := ProceduralArt.prop_texture("flower", 0)
	for kind in kinds:
		_check(GreenwardStyle.prop_kinds().has(kind), "style authority lists prop kind: " + kind)
		_check(GreenwardStyle.variant_count(kind) >= 2, kind + " has deterministic variants")
		_check(not GreenwardStyle.prop_palette(kind).is_empty(), kind + " has a real palette")
		var tex := ProceduralArt.prop_texture(kind, 0)
		_check(tex != null, kind + " resolves to a texture")
		if tex != null and flower != null:
			_check(tex.get_width() != flower.get_width() or tex.get_height() != flower.get_height() or tex.get_image().get_data() != flower.get_image().get_data(), kind + " art is not the generic flower fallback")
		var variant := ProceduralArt.prop_texture(kind, 1)
		_check(variant != null, kind + " variant 1 resolves")
		if variant != null and tex != null:
			_check(variant.get_image().get_data() != tex.get_image().get_data(), kind + " variant 1 is visually distinct")
	print("[village_prop_families] %s — %d checks, %d failures" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures])
	quit(0 if _failures == 0 else 1)

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("[village_prop_families] FAIL: " + label)
