class_name EquipmentLoadoutAdapter
extends RefCounted
## Bridges game-state equipment (item ids/stats) to M19 character visual loadouts.
## Avoids duplicate equipment systems by adapting existing controllers/resources.

static func get_character_loadout(character_id: String) -> CharacterEquipmentLoadout:
	# Presentation loadouts may exist as resources under character equipment paths in future;
	# current project primarily uses M19 visual controllers/resources separately.
	return null


static func apply_game_equipment_to_visual(character_equipment_controller: Node, uid: String) -> void:
	if character_equipment_controller == null:
		return
	# Hook point for integrating equipped item visuals with M19 CharacterEquipmentController.
	# Current equipment visuals are presentation resources/config-driven; game-state item ids
	# remain the authoritative ownership/equip/stat source.
	if character_equipment_controller.has_method("clear_all"):
		# Preserve existing authored/default presentation unless explicit mapping resources exist.
		pass
