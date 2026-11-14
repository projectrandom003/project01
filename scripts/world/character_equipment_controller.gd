class_name CharacterEquipmentController
extends Node
## Applies item visual Resources to the authored directional attachment mounts.
## This is presentation only; inventory ownership and equipment stats stay elsewhere.

const DIRECTION_NAMES: Array[StringName] = [
	&"Down", &"DownRight", &"Right", &"UpRight",
	&"Up", &"UpLeft", &"Left", &"DownLeft",
]
const SLOT_NAMES: Array[StringName] = [
	&"BackEquipment", &"HairAccessory", &"LeftHandEquipment",
	&"RightHandEquipment", &"ChestAccessory",
]
const BASE_SLOT_POSITIONS := {
	&"BackEquipment": Vector2(0, -56),
	&"HairAccessory": Vector2(0, -112),
	&"LeftHandEquipment": Vector2(-14, -54),
	&"RightHandEquipment": Vector2(14, -54),
	&"ChestAccessory": Vector2(0, -64),
}
const BASE_SLOT_Z := {
	&"BackEquipment": -1,
	&"HairAccessory": 1,
	&"LeftHandEquipment": 1,
	&"RightHandEquipment": 1,
	&"ChestAccessory": 1,
}

@export var default_loadout: CharacterEquipmentLoadout

@onready var direction_root: DirectionalEquipmentLayers = get_parent() as DirectionalEquipmentLayers


func _ready() -> void:
	if default_loadout != null:
		call_deferred("apply_loadout", default_loadout)


func equip_slot(slot_name: StringName, definition: EquipmentDefinition, direction: int = -1) -> bool:
	if not SLOT_NAMES.has(slot_name):
		push_warning("Unknown character equipment slot: %s" % String(slot_name))
		return false
	var targets: Array[int] = []
	if direction < 0:
		for index in DIRECTION_NAMES.size():
			targets.append(index)
	elif direction < DIRECTION_NAMES.size():
		targets.append(direction)
	else:
		return false
	var success := true
	for index in targets:
		var mount := _find_mount(index, slot_name)
		if mount == null:
			success = false
			continue
		if definition == null:
			mount.clear_equipment()
		else:
			mount.equip(definition)
	return success


func clear_slot(slot_name: StringName, direction: int = -1) -> bool:
	return equip_slot(slot_name, null, direction)


func clear_all() -> void:
	for slot_name in SLOT_NAMES:
		clear_slot(slot_name)


func apply_loadout(loadout: CharacterEquipmentLoadout) -> bool:
	if loadout == null:
		return false
	clear_all()
	_reset_attachment_offsets()
	var definitions := loadout.get_slot_definitions()
	var success := true
	for slot_name in definitions:
		var definition: EquipmentDefinition = definitions[slot_name]
		if definition != null and not equip_slot(slot_name, definition):
			success = false
	for directional_entry in loadout.directional_overrides:
		if directional_entry == null:
			continue
		var slot_name: StringName = directional_entry.get("slot_name")
		var definition: EquipmentDefinition = directional_entry.get("definition")
		var direction_index: int = directional_entry.get("direction_index")
		if definition == null:
			continue
		if not equip_slot(slot_name, definition, direction_index):
			success = false
	for attachment_entry in loadout.attachment_offsets:
		if attachment_entry == null:
			continue
		var slot_name: StringName = StringName(attachment_entry.get("slot_name"))
		var direction_index: int = int(attachment_entry.get("direction_index"))
		var position_offset: Vector2 = attachment_entry.get("position_offset")
		var override_z: bool = bool(attachment_entry.get("override_z_index"))
		var z_value: int = int(attachment_entry.get("z_index"))
		if not SLOT_NAMES.has(slot_name):
			success = false
			continue
		var targets: Array[int] = []
		if direction_index < 0:
			for index in DIRECTION_NAMES.size():
				targets.append(index)
		elif direction_index < DIRECTION_NAMES.size():
			targets.append(direction_index)
		else:
			success = false
			continue
		for index in targets:
			var anchor := _find_slot_anchor(index, slot_name)
			if anchor == null:
				success = false
				continue
			anchor.position = BASE_SLOT_POSITIONS[slot_name] + position_offset
			if override_z:
				anchor.z_index = z_value
	return success


func _reset_attachment_offsets() -> void:
	for direction in DIRECTION_NAMES.size():
		for slot_name in SLOT_NAMES:
			var anchor := _find_slot_anchor(direction, slot_name)
			if anchor == null:
				continue
			anchor.position = BASE_SLOT_POSITIONS[slot_name]
			anchor.z_index = BASE_SLOT_Z[slot_name]


func _find_slot_anchor(direction: int, slot_name: StringName) -> Node2D:
	if direction_root == null:
		return null
	var path := NodePath("%s/Slots/%s" % [String(DIRECTION_NAMES[direction]), String(slot_name)])
	return direction_root.get_node_or_null(path) as Node2D


func get_mount(slot_name: StringName, direction: int) -> EquipmentMount:
	if not SLOT_NAMES.has(slot_name) or direction < 0 or direction >= DIRECTION_NAMES.size():
		return null
	return _find_mount(direction, slot_name)


func _find_mount(direction: int, slot_name: StringName) -> EquipmentMount:
	if direction_root == null:
		return null
	var path := NodePath("%s/Slots/%s/Mount" % [String(DIRECTION_NAMES[direction]), String(slot_name)])
	return direction_root.get_node_or_null(path) as EquipmentMount
