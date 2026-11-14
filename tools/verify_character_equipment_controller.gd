extends SceneTree
## Verifies data-driven equipment assignment across the eight authored facings.

var failures: Array[String] = []
const DEFINITION = preload("res://scripts/world/equipment_definition.gd")


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: " + label)
	else:
		failures.append(label)
		printerr("FAIL: " + label)


func _run() -> void:
	var packed := load("res://scenes/characters/components/directional_equipment/directional_equipment_layers.tscn") as PackedScene
	_check(packed != null, "directional equipment scene loads")
	if packed == null:
		_finish()
		return
	var rig := packed.instantiate()
	root.add_child(rig)
	await process_frame
	var controller: Node = rig.get_node("EquipmentController")
	var definition = DEFINITION.new()
	definition.equipment_id = &"guardian_blade"
	definition.display_name = "Guardian Blade"
	definition.sprite_offset = Vector2(4, -8)
	_check(controller.call("equip_slot", &"RightHandEquipment", definition) == true, "equipment assigned to all eight facings")
	await process_frame
	var all_assigned := true
	for direction in 8:
		var mount: Node = controller.call("get_mount", &"RightHandEquipment", direction)
		if mount == null or mount.equipped_definition != definition:
			all_assigned = false
	_check(all_assigned, "all eight directional mounts share the item definition")

	var alternate = DEFINITION.new()
	alternate.equipment_id = &"alternate_blade"
	_check(controller.call("equip_slot", &"RightHandEquipment", alternate, 3) == true, "direction-specific override accepted")
	var overridden: Node = controller.call("get_mount", &"RightHandEquipment", 3)
	var untouched: Node = controller.call("get_mount", &"RightHandEquipment", 2)
	_check(overridden.equipped_definition == alternate, "selected facing receives override")
	_check(untouched.equipped_definition == definition, "other facings remain unchanged")
	_check(controller.call("clear_slot", &"RightHandEquipment", 3) == true, "single-facing slot can be cleared")
	_check(overridden.equipped_definition == null, "clear removes selected facing item")
	_check(controller.call("equip_slot", &"InvalidSlot", definition) == false, "unknown slot rejected safely")
	_check(controller.call("equip_slot", &"RightHandEquipment", definition, 8) == false, "invalid direction rejected safely")

	var loadout = load("res://resources/characters/equipment/gerald_loadout.tres")
	_check(loadout != null and loadout.character_id == &"gerald", "Gerald loadout resource loads with identity")
	var loadout_definition = DEFINITION.new()
	loadout_definition.equipment_id = &"gerald_guardian_blade"
	loadout.right_hand_equipment = loadout_definition
	var override_script = load("res://scripts/world/equipment_directional_override.gd")
	var directional_override = override_script.new()
	directional_override.slot_name = &"RightHandEquipment"
	directional_override.direction_index = 4
	var override_definition = DEFINITION.new()
	override_definition.equipment_id = &"gerald_back_view_blade"
	directional_override.definition = override_definition
	var overrides: Array[EquipmentDirectionalOverride] = [directional_override]
	loadout.directional_overrides = overrides
	_check(controller.call("apply_loadout", loadout) == true, "complete character loadout applies")
	_check(controller.call("get_mount", &"RightHandEquipment", 0).equipped_definition == loadout_definition, "base slot definition applies across facings")
	_check(controller.call("get_mount", &"RightHandEquipment", 4).equipped_definition == override_definition, "directional override applies after base slot")
	_check(controller.call("get_mount", &"RightHandEquipment", 3).equipped_definition == loadout_definition, "non-overridden facing retains base definition")
	var offset_script = load("res://scripts/world/equipment_attachment_offset.gd")
	var shared_offset = offset_script.new()
	shared_offset.slot_name = "RightHandEquipment"
	shared_offset.direction_index = -1
	shared_offset.position_offset = Vector2(5, -3)
	var down_only_offset = offset_script.new()
	down_only_offset.slot_name = "HairAccessory"
	down_only_offset.direction_index = 0
	down_only_offset.position_offset = Vector2(2, 6)
	var attachment_offsets: Array[EquipmentAttachmentOffset] = [shared_offset, down_only_offset]
	loadout.attachment_offsets = attachment_offsets
	_check(controller.call("apply_loadout", loadout) == true, "character attachment offsets apply")
	_check(controller.call("get_mount", &"RightHandEquipment", 0).get_parent().position == Vector2(19, -57), "shared slot offset applies to down-facing mount")
	_check(controller.call("get_mount", &"RightHandEquipment", 7).get_parent().position == Vector2(19, -57), "shared slot offset applies to down-left mount")
	_check(controller.call("get_mount", &"HairAccessory", 0).get_parent().position == Vector2(2, -106), "single-facing attachment offset applies")
	_check(controller.call("get_mount", &"HairAccessory", 1).get_parent().position == Vector2(0, -112), "other facing keeps base attachment position")
	var lilith_empty := load("res://resources/characters/equipment/lilith_loadout.tres")
	_check(controller.call("apply_loadout", lilith_empty) == true, "switching character loadout succeeds")
	_check(controller.call("get_mount", &"RightHandEquipment", 0).get_parent().position == Vector2(14, -54), "switching loadout resets previous character offsets")

	var lilith_loadout = load("res://resources/characters/equipment/lilith_loadout.tres")
	var kael_loadout = load("res://resources/characters/equipment/kael_loadout.tres")
	_check(lilith_loadout != null and lilith_loadout.character_id == &"lilith", "Lilith loadout resource exists")
	_check(kael_loadout != null and kael_loadout.character_id == &"kael", "Kael loadout resource exists")
	rig.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("verify_character_equipment_controller: OK")
		quit(0)
	else:
		printerr("verify_character_equipment_controller: FAILED (%d)" % failures.size())
		quit(1)
