extends SceneTree
## CI content validation entry point.
##
## Run with:
##   godot --headless --path . --script res://tools/validate_content.gd
##
## Exits 0 when every JSON file passes ContentValidator, 1 otherwise. The same
## validator runs at boot in ContentDB, so CI and the game cannot disagree.

func _initialize() -> void:
	var report: Dictionary = ContentValidator.validate_all("res://resources/data/")
	var errors: Array = report.get("errors", [])
	var parsed: Dictionary = report.get("data", {})
	if errors.is_empty():
		print("[validate] OK — %d content files parsed and validated." % parsed.size())
		quit(0)
		return
	for error in errors:
		printerr("[validate] " + str(error))
	print("[validate] FAILED — %d error(s) in %d valid file(s)." % [errors.size(), parsed.size()])
	quit(1)
