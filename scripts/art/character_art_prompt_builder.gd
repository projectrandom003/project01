class_name CharacterArtPromptBuilder
extends RefCounted
## Pure prompt composition for character art specifications.
## Keeps authored identity/spec data separate from generation-language assembly.

const STYLE_ANCHOR := "Original anime-fantasy character illustration, ~6-head heroic proportions (not chibi, not realistic 8-head), soft cel-shaded painterly rendering, a 1-2 px dark ink outline for readability, a consistent upper-left key light with a cool rim light, transparent RGBA8 background (alpha cutout, no opaque backdrop, no baked ground shadow), no text, no logos, no copyrighted characters or reference traces. Shared GreenwardStyle palette language: deep indigo night, mossy emerald green, warm gold, teal spirit-light, violet arcane and ember accents. Feet on ONE baseline for full-body and world sprites."


static func palette_line(data: Dictionary) -> String:
	var palette: Dictionary = data.get("palette", {})
	return "hair %s, primary %s, secondary %s, accent %s, skin %s" % [
		str(palette.get("hair", "")), str(palette.get("primary", "")), str(palette.get("secondary", "")),
		str(palette.get("accent", "")), str(palette.get("skin", "")),
	]


static func full_body_prompt(data: Dictionary) -> String:
	var tier := str(data.get("tier_note", ""))
	var tier_line := ("\nPREMIUM TIER: " + tier) if not tier.is_empty() else ""
	var palette: Dictionary = data.get("palette", {})
	var hair_hex := str(palette.get("hair", ""))
	return "%s\n\nSUBJECT: full-body illustration of %s (%s) - %s. Race: %s; Element: %s; Rarity: %s; Role: %s.\nAPPEARANCE: %s Hair: %s (%s), %s. Outfit: %s Accessories: %s Weapon: %s.\nPOSE AND MOTIF: %s Motif: %s. Palette: %s. Visual theme: %s.%s\nOUTPUT SPEC: full-body master 1024x2048 px, full height head-to-toe, feet on ONE baseline, transparent RGBA8 sRGB, upper-left key light, 1-2 px dark ink outline, no baked text or backdrop." % [
		STYLE_ANCHOR,
		str(data.get("display_name", "")), str(data.get("title", "")), str(data.get("title", "")),
		str(data.get("race", "")), str(data.get("element", "")), str(data.get("rarity", "")), str(data.get("role", "")),
		str(data.get("physical_appearance", "")), hair_hex, str(data.get("hair_color_name", "")), str(data.get("hair_style", "")),
		str(data.get("outfit", "")), str(data.get("accessories", "")), str(data.get("weapon", "")),
		str(data.get("pose", "")), str(data.get("motif", "")), palette_line(data), str(data.get("visual_theme", "")), tier_line,
	]


static func portrait_prompt(data: Dictionary) -> String:
	var tier := str(data.get("tier_note", ""))
	var tier_line := (" Premium frame: " + tier) if not tier.is_empty() else ""
	var palette: Dictionary = data.get("palette", {})
	var hair_hex := str(palette.get("hair", ""))
	return "%s\n\nSUBJECT: bust portrait of %s (%s), %s. Head-and-shoulders top-centre crop (0.5, 0.0), eyes in the upper third, a calm neutral expression plus one alternate (%s). Hair: %s (%s), %s. Palette: %s. Visual theme: %s. Rarity frame: %s tier.%s\nOUTPUT SPEC: master 1024x1280 px, export 256x384 px top-centre bust crop, transparent RGBA8 sRGB, upper-left key light, 1-2 px dark ink outline, no baked text, silhouette readable at 96x96." % [
		STYLE_ANCHOR,
		str(data.get("display_name", "")), str(data.get("title", "")), str(data.get("title", "")),
		str(data.get("expression", "")), hair_hex, str(data.get("hair_color_name", "")), str(data.get("hair_style", "")),
		palette_line(data), str(data.get("visual_theme", "")), str(data.get("rarity", "")), tier_line,
	]


static func sheet_prompt(data: Dictionary) -> String:
	return "%s\n\nSUBJECT: 8-direction world sprite sheet for %s (%s), %s. 96x128 px frames, bottom-centre anchor (0.5, 1.0), feet on ONE identical baseline across every frame/state/direction, 1-2 px dark ink outline, transparent RGBA8. Palette: %s. Visual theme: %s.\nLAYOUT: per-state atlas = <frames> columns x 8 direction rows (row 0 DOWN ... row 7 DOWN_LEFT), 0-based columns; states idle 5 frames @ 9 fps loop, walk 16 @ 12 loop, run 16 @ 16 loop, interact 6 @ 12, attack 6 @ 15, damage 2 @ 12, victory 8 @ 12, defeat 6 @ 10, cast 7 @ 12 (all one-shots unless noted). Slice into a SpriteFrames .tres with animations <state>_<dir> and cast_<dir>, speed = fps, loop = loop flag.\nOUTPUT SPEC: transparent RGBA8 PNG atlas(es) sliced to a SpriteFrames .tres, 96x128 frames, Linear filter + mipmaps on, feet on ONE baseline, no baked text." % [
		STYLE_ANCHOR,
		str(data.get("display_name", "")), str(data.get("title", "")), str(data.get("role", "")),
		palette_line(data), str(data.get("visual_theme", "")),
	]


static func vfx_prompt(data: Dictionary) -> String:
	var skill_ids: Array = data.get("skills", [])
	var skills_text := ""
	for index in skill_ids.size():
		if index > 0:
			skills_text += ", "
		skills_text += str(skill_ids[index])
	return "%s\n\nSUBJECT: skill/ultimate VFX flipbook for %s - skill ids [%s], ultimate id [%s], element %s, motif %s. 192x192 px frames, 6 frames, centre anchor (0.5, 0.5), 1 row x 6 columns (atlas 1152x192), transparent RGBA8 additive glow, element-coloured accents, no baked text.\nOUTPUT SPEC: transparent RGBA8 PNG flipbook, 192x192 frames, Linear filter + mipmaps off + Lossless, additive alpha, sliced into 6-frame animations." % [
		STYLE_ANCHOR, str(data.get("display_name", "")), skills_text, str(data.get("ultimate", "")),
		str(data.get("element", "")), str(data.get("visual_theme", "")),
	]
