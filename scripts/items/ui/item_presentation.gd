class_name ItemPresentation
extends RefCounted

const RARITY_COLORS := {
	"common": Color("#8f98ad"),
	"uncommon": Color("#5dbb7a"),
	"rare": Color("#4aa3ff"),
	"epic": Color("#b06cff"),
	"legendary": Color("#ffb347"),
	"mythic": Color("#ff6fae"),
	"special": Color("#7fe3e0"),
}

static func rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(str(rarity).to_lower(), RARITY_COLORS["common"])


static func item_color(item_data: Dictionary) -> Color:
	var c := str(item_data.get("color", ""))
	if c.begins_with("#"):
		return Color(c)
	return rarity_color(str(item_data.get("rarity", "common")))


static func item_letter(item_data: Dictionary, fallback: String = "?") -> String:
	var name := str(item_data.get("name", fallback))
	return name.substr(0, 1).to_upper() if not name.is_empty() else fallback


static func format_count_text(count: int, equipped_count: int = 0) -> String:
	if count <= 0 and equipped_count > 0:
		return "Equipped"
	if equipped_count > 0:
		return "×%s  •  E%d" % [UIFactory.number(count), equipped_count]
	return "×%s" % UIFactory.number(count)
