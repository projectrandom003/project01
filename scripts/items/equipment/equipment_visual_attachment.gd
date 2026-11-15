class_name EquipmentVisualAttachment
extends RefCounted
## Bridges equipped game-state items to M19 visual equipment controllers/resources.

static func sync_character_visuals(character_node: Node, uid: String) -> void:
	if character_node == null:
		return
	var controller := character_node.get_node_or_null("DirectionalEquipment/EquipmentController")
	if controller == null:
		controller = character_node.get_node_or_null("EquipmentController")
	# Authoritative ownership/stats stay in GameState/CharacterInstance.
	# Visual presentation resources/configs are handled by existing M19 controllers;
	# this adapter is the integration point for item->visual mapping as resources become available.
	if controller != null and controller.has_method("refresh_from_game_state"):
		controller.call("refresh_from_game_state", uid)


static func slot_to_attachment(slot_name: String) -> StringName:
	match slot_name:
		"weapon": return &"RightHandEquipment"
		"armor": return &"ChestAccessory"
		"accessory": return &"BackEquipment"
		_: return &""
