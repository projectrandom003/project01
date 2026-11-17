class_name ItemAcquisitionNotification
extends PanelContainer

@onready var label_node: Label = get_node_or_null("Label")

func show_message(message: String, kind: String = "info") -> void:
	if label_node:
		label_node.text = message
		var color := UITheme.TEAL
		if kind == "warning":
			color = UITheme.GOLD
		elif kind == "error":
			color = UITheme.DANGER
		elif kind == "success":
			color = UITheme.GREEN
		label_node.add_theme_color_override("font_color", color)
	visible = not message.is_empty()
	EventBus.toast_requested.emit(message)
