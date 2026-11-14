class_name EquipmentAttachmentOffset
extends Resource
## Character-specific mount transform adjustment for one slot and facing.
## direction_index -1 applies to all eight facings.

@export_enum("BackEquipment", "HairAccessory", "LeftHandEquipment", "RightHandEquipment", "ChestAccessory")
var slot_name: String = "RightHandEquipment"
@export_range(-1, 7, 1) var direction_index: int = -1
@export var position_offset: Vector2 = Vector2.ZERO
@export var z_index: int = 0
@export var override_z_index: bool = false
