class_name QuestObjectiveRow
extends HBoxContainer

func setup(marker: String, objective_text: String, color: Color) -> void:
	var marker_label := get_node("Marker") as Label
	var objective_label := get_node("ObjectiveText") as Label
	marker_label.text = marker
	marker_label.add_theme_color_override("font_color", color)
	objective_label.text = objective_text
	objective_label.add_theme_color_override("font_color", color)
