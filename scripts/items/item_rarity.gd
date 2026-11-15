class_name ItemRarity
extends RefCounted

const ORDER := ["common", "uncommon", "rare", "epic", "legendary", "special", "mythic"]

static func normalize(rarity: String) -> String:
	var r := str(rarity).to_lower()
	if r.is_empty():
		return "common"
	return r


static func color(rarity: String) -> Color:
	var r := normalize(rarity)
	if UITheme.RARITY.has(r):
		return UITheme.rarity_color(r)
	return Color("#9aa8c2")


static func label(rarity: String) -> String:
	return normalize(rarity).capitalize()


static func is_premium(rarity: String) -> bool:
	var r := normalize(rarity)
	return r in ["legendary", "mythic", "special"]
