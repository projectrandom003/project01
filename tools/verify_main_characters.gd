extends SceneTree
## Verifies the two main protagonists' imported art and JSON definitions.
##
## Run with:
##   godot --headless --path . --script res://tools/verify_main_characters.gd
##
## Exits 0 when both reference sheets load as Texture2D and both definitions
## parse into CharacterDef, 1 otherwise. Read-only: creates no files.

func _initialize() -> void:
	var report: Dictionary = MainCharacterRoster.report()
	print(JSON.stringify(report, "  "))

	var ok := true
	for character_id in MainCharacterRoster.ids():
		var definition := MainCharacterRoster.get_definition(character_id)
		if definition == null:
			printerr("[main] definition failed to parse: " + character_id)
			ok = false
			continue
		var texture := MainCharacterRoster.reference_texture(character_id)
		if texture == null:
			printerr("[main] reference sheet is not a loadable Texture2D: " + character_id)
			ok = false
			continue
		print("[main] %s (%s) sheet=%dx%d element=%s skills=%s" % [
			character_id,
			definition.display_name,
			texture.get_width(),
			texture.get_height(),
			definition.element,
			str(definition.skills),
		])

	var profile_paths := [
		"res://resources/characters/main/lilith.tres",
		"res://resources/characters/main/gerald.tres",
	]
	for profile_path in profile_paths:
		var loaded: Resource = load(profile_path)
		if loaded == null or not (loaded is MainCharacterProfile):
			printerr("[main] profile resource failed to load: " + profile_path)
			ok = false
			continue
		var profile := loaded as MainCharacterProfile
		if profile.reference_sheet == null:
			printerr("[main] profile has no reference_sheet texture: " + profile_path)
			ok = false
			continue
		print("[main] profile %s -> %s (%dx%d)" % [
			profile_path,
			profile.character_id,
			profile.reference_sheet.get_width(),
			profile.reference_sheet.get_height(),
		])

	print("[main] %s" % ("OK" if ok else "FAILED"))
	quit(0 if ok else 1)
