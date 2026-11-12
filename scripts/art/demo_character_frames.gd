class_name DemoCharacterFrames
extends SpriteFramesActorSource
## TEMPORARY DEMONSTRATION SHEET -- procedurally generated, NOT final art;
## replace with painted world_sheet.png.
##
## ONE fully integrated demonstration character (wired to the player in
## scripts/player/player.gd). Builds an IN-MEMORY SpriteFrames covering ALL 9
## states (8 core + additive CAST) x 8 directions at the authoritative frame
## counts/fps/loop, from ProceduralArt.character_frame() cached textures.
## This proves the whole SpriteFramesActorSource path works end-to-end while
## ZERO final painted assets exist.
##
## CLEARLY MARKED TEMPORARY:
##  * is_temporary() == true
##  * source_label() contains "temporary" / "demo" / "placeholder"
##  * loaded_from_disk == false (there is NO real sheet on disk)
##  * validate_sheets() == [] (all 9x8 animations present and correct)
##
## Generation is bounded/lazy: ProceduralArt caches textures, so build_from_
## textures() allocates NO per-frame resources -- it just wires cached frames.

func _init(p_character_id: String = "player", p_palette: Dictionary = {}) -> void:
	# The base _init() is intentionally NOT auto-called (GDScript calls only the
	# most-derived _init). Set the inherited state directly; inherited member
	# initializers already provide safe defaults for everything else.
	character_id = p_character_id
	loaded_from_disk = false
	missing_reason = ""
	sheet_path = ""
	var pal: Dictionary = p_palette
	if pal.is_empty():
		pal = _hero_palette()
	build_from_textures(pal)
	# The SpriteFrames now owns all 432 frames directly. Drop the shared static
	# character-frame cache so those ImageTextures are the sheet's alone (they
	# free cleanly with the node at scene teardown). No functional change: a
	# later character_frame() call just regenerates + re-caches deterministically.
	ProceduralArt.clear_frame_cache()


## Always TEMPORARY -- this is a procedural demonstration, never final art.
func is_temporary() -> bool:
	return true


func source_label() -> String:
	return "demo-temporary-placeholder-spriteframes"


## Stable hero palette (the same literals the player passes to visual.setup()).
## Used only when _init is called with an empty palette (e.g. a headless probe).
static func _hero_palette() -> Dictionary:
	return {
		"hair": "#5a3a2a",
		"primary": "#2f4a6b",
		"secondary": "#c9a45a",
		"accent": "#7fe3e0",
		"skin": "#f0cbb0",
	}
