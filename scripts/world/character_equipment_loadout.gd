class_name CharacterEquipmentLoadout
extends Resource
## Character presentation loadout. Contains no inventory, stats or save ownership.

@export var character_id: StringName = &""
@export var back_equipment: EquipmentDefinition
@export var hair_accessory: EquipmentDefinition
@export var left_hand_equipment: EquipmentDefinition
@export var right_hand_equipment: EquipmentDefinition
@export var chest_accessory: EquipmentDefinition
@export var directional_overrides: Array[EquipmentDirectionalOverride] = []
@export var attachment_offsets: Array[EquipmentAttachmentOffset] = []


func get_slot_definitions() -> Dictionary:
	return {
		&"BackEquipment": back_equipment,
		&"HairAccessory": hair_accessory,
		&"LeftHandEquipment": left_hand_equipment,
		&"RightHandEquipment": right_hand_equipment,
		&"ChestAccessory": chest_accessory,
	}
