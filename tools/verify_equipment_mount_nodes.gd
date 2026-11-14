extends SceneTree
## Focused headless checks for data-driven equipment mount presentation.

var failures: Array[String] = []
const EQUIPMENT_MOUNT_SCRIPT = preload("res://scripts/world/equipment_mount.gd")
const EQUIPMENT_DEFINITION_SCRIPT = preload("res://scripts/world/equipment_definition.gd")


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		printerr("FAIL: " + label)


func _run() -> void:
	var scene := load("res://scenes/characters/equipment/equipment_mount.tscn") as PackedScene
	_check(scene != null, "equipment mount scene loads")
	if scene == null:
		_finish()
		return
	var mount: Node = scene.instantiate()
	root.add_child(mount)
	await process_frame
	_check(mount.get_node("Visual") is Sprite2D, "mount exposes its Sprite2D visual node")
	_check(not (mount.get_node("Visual") as Sprite2D).visible, "empty mount starts hidden")

	var definition = EQUIPMENT_DEFINITION_SCRIPT.new()
	definition.equipment_id = &"test_blade"
	definition.display_name = "Test Blade"
	definition.sprite_offset = Vector2(3, -7)
	definition.sprite_scale = Vector2(1.2, 0.8)
	definition.sprite_z_index = 2
	definition.flip_h = true
	mount.equip(definition)
	await process_frame
	var visual := mount.get_node("Visual") as Sprite2D
	_check(mount.equipped_definition == definition, "definition assigned to mount")
	_check(visual.position == Vector2(3, -7), "offset comes from definition")
	_check(visual.scale == Vector2(1.2, 0.8), "scale comes from definition")
	_check(visual.z_index == 2 and visual.flip_h, "depth and flip come from definition")
	_check(not visual.visible, "missing texture never displays a placeholder")

	mount.clear_equipment()
	_check(mount.equipped_definition == null, "clear releases definition")
	_check(visual.texture == null and not visual.visible, "clear resets visual safely")
	mount.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("verify_equipment_mount_nodes: OK")
		quit(0)
	else:
		printerr("verify_equipment_mount_nodes: FAILED (%d)" % failures.size())
		quit(1)
