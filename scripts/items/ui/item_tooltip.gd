class_name ItemTooltip
extends PanelContainer

@onready var title_label: Label = get_node_or_null("VBox/Title")
@onready var body_label: Label = get_node_or_null("VBox/Body")
@onready var rarity_label: Label = get_node_or_null("VBox/Rarity")

func show_item(item_id: String) -> void:
	var item := ContentDB.get_item(item_id)
	if title_label:
		title_label.text = str(item.get("name", item_id))
	if body_label:
		body_label.text = str(item.get("description", ""))
	if rarity_label:
		var rarity := str(item.get("rarity", "common"))
		rarity_label.text = rarity.capitalize()
		if UITheme.RARITY.has(rarity):
			rarity_label.add_theme_color_override("font_color", UITheme.rarity_color(rarity))
		else:
			rarity_label.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	visible = not item.is_empty()
