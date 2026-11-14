class_name EquipmentDirectionalOverride
extends Resource
## One facing-specific visual override for a character equipment slot.

@export_enum("BackEquipment", "HairAccessory", "LeftHandEquipment", "RightHandEquipment", "ChestAccessory")
var slot_name: String = "RightHandEquipment"
@export_range(0, 7, 1) var direction_index: int = 0
@export var definition: EquipmentDefinition
