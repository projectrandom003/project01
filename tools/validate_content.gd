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
	var errors: Array = report.get("errors", []).duplicate()
	var parsed: Dictionary = report.get("data", {})
	# The protagonists are merged into ContentDB from their own file. Validate
	# them with the characters.json rules without changing the 9-file count.
	var main_path := "res://resources/data/main_characters.json"
	if FileAccess.file_exists(main_path):
		var main_data: Variant = JSON.parse_string(FileAccess.get_file_as_string(main_path))
		if typeof(main_data) != TYPE_DICTIONARY:
			errors.append("main_characters.json: top-level JSON value must be an object")
		else:
			errors.append_array(ContentValidator.validate_document("characters.json", main_data, parsed))
	else:
		errors.append("main_characters.json: file is missing")
	if errors.is_empty():
		print("[validate] OK — %d content files + main characters parsed and validated." % parsed.size())
		quit(0)
		return
	for error in errors:
		printerr("[validate] " + str(error))
	print("[validate] FAILED — %d error(s) in %d valid file(s)." % [errors.size(), parsed.size()])
	quit(1)
