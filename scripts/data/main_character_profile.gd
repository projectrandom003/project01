class_name MainCharacterProfile
extends Resource
## Editor-visible handle for one main protagonist.
##
## A .tres of this type lives in res://resources/characters/main/ and points at
## the imported reference sheet, so the artwork can be inspected in Godot's
## inspector without loading the game. Stats, skills and lore stay in
## res://resources/data/main_characters.json (read through MainCharacterRoster),
## which keeps the data-driven architecture intact.

@export var character_id: String = ""
@export var asset_folder: String = ""
@export var reference_sheet: Texture2D
@export var portrait_target: String = ""
@export_multiline var note: String = ""


## CharacterDef from the shared JSON definition (null when unknown).
func definition() -> CharacterDef:
	return MainCharacterRoster.get_definition(character_id)


func display_name() -> String:
	var def := definition()
	return def.display_name if def != null else character_id


## A future 256x384 cut-out portrait, or null while only the sheet exists.
func portrait_texture() -> Texture2D:
	return MainCharacterRoster.portrait_texture(character_id)
