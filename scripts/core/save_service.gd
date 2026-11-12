extends Node
## Versioned local save service.
##
## IMPORTANT: this is a local, non-authoritative save used while the game is
## offline/single-player. Phase 12 replaces it with server-owned state. The
## format is intentionally plain JSON so it can be migrated and inspected.

const SAVE_PATH := "user://project_fantasy_save.json"
const BACKUP_PATH := "user://project_fantasy_save.backup.json"
const SAVE_VERSION := 1


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_save() -> Dictionary:
	if not has_save():
		return {}
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[SaveService] Save file is corrupt; keeping a backup and starting fresh.")
		_backup_corrupt_file()
		return {}
	var data: Dictionary = parsed
	if int(data.get("version", 0)) > SAVE_VERSION:
		push_warning("[SaveService] Save is from a newer version; attempting best-effort load.")
	return data


func write_save(data: Dictionary) -> bool:
	data["version"] = SAVE_VERSION
	data["saved_at"] = Time.get_datetime_string_from_system()
	var text := JSON.stringify(data, "\t")
	var temp_path := SAVE_PATH + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveService] Could not open save file for writing.")
		return false
	file.store_string(text)
	file.close()

	# Replace atomically as far as the platform allows.
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path),
		ProjectSettings.globalize_path(SAVE_PATH)
	)
	if error != OK:
		push_error("[SaveService] Could not finalize save file (error %d)." % error)
		return false
	return true


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _backup_corrupt_file() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(
			ProjectSettings.globalize_path(SAVE_PATH),
			ProjectSettings.globalize_path(BACKUP_PATH)
		)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
