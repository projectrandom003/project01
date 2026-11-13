class_name UIFactory
extends RefCounted
## Small, boring helpers that keep every screen visually consistent.
## Screens never hard-code styleboxes or colours; they call these builders.

const T := preload("res://scripts/ui/ui_theme.gd")


static func panel(
	bg: Color = UITheme.PANEL,
	border: Color = UITheme.BORDER,
	radius: int = 12,
	border_width: int = 1,
	padding: int = 14,
	shadow: bool = false
) -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel", UITheme.style(bg, border, radius, border_width, padding, shadow))
	return node


static func label(
	text_value: String,
	font_size: int = 15,
	color: Color = UITheme.TEXT,
	align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> Label:
	var node := Label.new()
	node.text = text_value
	node.horizontal_alignment = align
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node


static func wrapped(
	text_value: String,
	font_size: int = 14,
	color: Color = UITheme.TEXT_DIM,
	min_height: float = 0.0
) -> Label:
	var node := label(text_value, font_size, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if min_height > 0.0:
		node.custom_minimum_size = Vector2(0, min_height)
	return node


static func heading(text_value: String, font_size: int = 24, color: Color = UITheme.TEXT) -> Label:
	var node := label(text_value, font_size, color)
	node.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.05, 0.85))
	node.add_theme_constant_override("outline_size", 4)
	return node


static func rich(
	text_value: String = "",
	font_size: int = 14,
	color: Color = UITheme.TEXT,
	min_height: float = 0.0
) -> RichTextLabel:
	var node := RichTextLabel.new()
	node.bbcode_enabled = true
	node.fit_content = true
	node.scroll_active = false
	node.text = text_value
	node.add_theme_font_size_override("normal_font_size", font_size)
	node.add_theme_font_size_override("bold_font_size", font_size)
	node.add_theme_color_override("default_color", color)
	if min_height > 0.0:
		node.custom_minimum_size = Vector2(0, min_height)
	return node


static func button(text_value: String, primary: bool = false, danger: bool = false) -> Button:
	var node := Button.new()
	node.text = text_value
	node.custom_minimum_size = Vector2(0, 40)
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_size_override("font_size", 15)
	if danger:
		node.add_theme_stylebox_override("normal", UITheme.style(Color("#2a1420"), Color("#6b2a3c"), 8, 1, 10))
		node.add_theme_stylebox_override("hover", UITheme.style(Color("#3a1a2a"), UITheme.DANGER, 8, 1, 10))
		node.add_theme_stylebox_override("pressed", UITheme.style(Color("#170b12"), Color("#ff8298"), 8, 2, 10))
		node.add_theme_stylebox_override("focus", UITheme.style(Color("#3a1a2a"), Color("#ffc2cc"), 8, 2, 10))
		node.add_theme_color_override("font_color", Color("#ffc2cc"))
	elif primary:
		node.add_theme_stylebox_override("normal", UITheme.style(Color("#2a2415"), UITheme.GOLD, 8, 1, 10))
		node.add_theme_stylebox_override("hover", UITheme.style(Color("#3a321d"), UITheme.GOLD_BRIGHT, 8, 1, 10))
		node.add_theme_stylebox_override("pressed", UITheme.style(Color("#1a1710"), UITheme.GOLD_BRIGHT, 8, 2, 10))
		node.add_theme_stylebox_override("focus", UITheme.style(Color("#3a321d"), Color("#fff0bd"), 8, 2, 10))
		node.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
	return node


static func small_button(text_value: String, color: Color = UITheme.TEXT_DIM) -> Button:
	var node := button(text_value)
	node.custom_minimum_size = Vector2(0, 30)
	node.add_theme_font_size_override("font_size", 12)
	node.add_theme_color_override("font_color", color)
	return node


static func bar(color: Color, height: int = 10) -> ProgressBar:
	var node := ProgressBar.new()
	node.show_percentage = false
	node.custom_minimum_size = Vector2(0, height)
	node.add_theme_stylebox_override("background", UITheme.style(Color("#080d18"), UITheme.BORDER_SOFT, 4, 1, 0))
	node.add_theme_stylebox_override("fill", UITheme.style(color, color, 4, 0, 0))
	return node


static func vbox(separation: int = 8) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	return node


static func hbox(separation: int = 8) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	return node


static func grid(columns: int = 4, separation: int = 10) -> GridContainer:
	var node := GridContainer.new()
	node.columns = columns
	node.add_theme_constant_override("h_separation", separation)
	node.add_theme_constant_override("v_separation", separation)
	return node


static func scroll() -> ScrollContainer:
	var node := ScrollContainer.new()
	node.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	node.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return node


static func margin(value: int) -> MarginContainer:
	var node := MarginContainer.new()
	node.add_theme_constant_override("margin_left", value)
	node.add_theme_constant_override("margin_right", value)
	node.add_theme_constant_override("margin_top", value)
	node.add_theme_constant_override("margin_bottom", value)
	return node


static func spacer(horizontal: bool = true) -> Control:
	var node := Control.new()
	if horizontal:
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func separator() -> HSeparator:
	return HSeparator.new()


static func chip(text_value: String, color: Color, bg: Color = Color(0, 0, 0, 0)) -> PanelContainer:
	var node := panel(bg if bg.a > 0.0 else Color(color.r, color.g, color.b, 0.10), Color(color.r, color.g, color.b, 0.45), 20, 1, 8)
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := hbox(6)
	var dot := ColorRect.new()
	dot.color = color
	dot.custom_minimum_size = Vector2(7, 7)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot)
	row.add_child(label(text_value, 12, color))
	node.add_child(row)
	return node


static func rarity_chip(rarity: String) -> PanelContainer:
	var color := UITheme.rarity_color(rarity)
	return chip(rarity.capitalize(), color)


static func element_chip(element: String) -> PanelContainer:
	var color := UITheme.element_color(element)
	return chip(element.capitalize(), color)


static func set_full_rect(node: Control) -> void:
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0


static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


static func number(value: int) -> String:
	var text := str(absi(value))
	var out := ""
	var count := 0
	for index in range(text.length() - 1, -1, -1):
		out = text[index] + out
		count += 1
		if count % 3 == 0 and index > 0:
			out = "," + out
	return ("-" if value < 0 else "") + out


static func percent(value: float, digits: int = 1) -> String:
	return ("%." + str(digits) + "f%%") % (value * 100.0)


static func status_text(unit: Combatant) -> String:
	if unit.statuses.is_empty():
		return ""
	var names: Array = []
	for status in unit.statuses:
		var status_id := str(status.get("id", ""))
		names.append(status_id.replace("_", " ").capitalize())
	return " · ".join(names)


static func class_icon_text(role: String) -> String:
	return role.substr(0, 1).to_upper()
