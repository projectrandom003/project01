class_name SummonResultCard
extends PanelContainer

var premium: bool = false
var _portrait: PortraitView
var _name_label: Label
var _rarity_label: Label
var _tier_label: Label
var _status_label: Label

func setup(roll: Dictionary) -> void:
	var character_id := str(roll.get("character_id", ""))
	var definition: CharacterDef = ContentDB.get_character(character_id)
	var rarity := str(roll.get("rarity", "common"))
	var color := UITheme.rarity_color(rarity)
	premium = UITheme.is_premium_rarity(rarity)
	var effect := UITheme.rarity_effect(rarity)
	var glow: Color = effect.get("glow", UITheme.GOLD_BRIGHT)
	var card_bg := Color("#0d1526")
	var card_border := color
	var border_width := 2
	if premium:
		card_bg = card_bg.lerp(Color(glow.r, glow.g, glow.b, 1.0), 0.10)
		card_border = Color(glow.r, glow.g, glow.b, 0.95)
		border_width = int(effect.get("border_width", 3))
	add_theme_stylebox_override("panel", UITheme.style(card_bg, card_border, 10, border_width, 8))
	_portrait = get_node("Content/Portrait") as PortraitView
	_name_label = get_node("Content/Name") as Label
	_rarity_label = get_node("Content/Rarity") as Label
	_tier_label = get_node("Content/Tier") as Label
	_status_label = get_node("Content/Status") as Label
	if definition != null:
		_portrait.setup_character(definition)
	else:
		_portrait.setup({}, "Human", "neutral", rarity, 0)
	_name_label.text = definition.display_name if definition != null else character_id
	_rarity_label.text = rarity.capitalize()
	_rarity_label.add_theme_color_override("font_color", color)
	_tier_label.visible = premium
	if premium:
		_tier_label.text = "✦ " + UITheme.rarity_tier_label(rarity) + " ✦"
		_tier_label.add_theme_color_override("font_color", glow)
	# Keep every meaningful result tag visible. The old mutually-exclusive
	# chain hid NEW / awakening / guaranteed whenever a unit was featured.
	var tags: Array[String] = []
	var status_color := UITheme.TEXT_DIM
	if bool(roll.get("featured", false)):
		tags.append("FEATURED")
		status_color = UITheme.GOLD
	if bool(roll.get("is_new", false)):
		tags.append("NEW")
		if not bool(roll.get("featured", false)):
			status_color = UITheme.GREEN
	elif int(roll.get("awakening_gain", 0)) > 0:
		tags.append("AWAKENING +%d" % int(roll.get("awakening_gain", 0)))
		if not bool(roll.get("featured", false)):
			status_color = UITheme.TEAL
	if bool(roll.get("guaranteed", false)):
		tags.append("GUARANTEED")
		if tags.size() == 1:
			status_color = UITheme.VIOLET
	_status_label.text = " · ".join(tags)
	_status_label.visible = not tags.is_empty()
	_status_label.add_theme_color_override("font_color", status_color)
