class_name RarityRateRow
extends HBoxContainer

func setup(rarity: String, rate_text: String, color: Color) -> void:
	var dot := get_node("Dot") as ColorRect
	dot.color = color
	var name_label := get_node("RarityName") as Label
	name_label.text = rarity.capitalize()
	name_label.add_theme_color_override("font_color", color)
	var rate_label := get_node("RateValue") as Label
	rate_label.text = rate_text
	rate_label.add_theme_color_override("font_color", UITheme.TEXT)
