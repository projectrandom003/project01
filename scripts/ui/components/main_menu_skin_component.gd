class_name MainMenuSkinComponent
extends Node
## Applies the hub's independent burgundy, purple, silver and antique-gold skin.

var menu: Control

func bind(owner: Control) -> void:
	menu = owner
	apply_skin()

func apply_skin() -> void:
	var hub := menu.get_node_or_null("ReferenceInterface") as Control
	if hub == null:
		push_error("[MainMenuSkin] ReferenceInterface is missing.")
		return
	var panel_style := UITheme.style(Color("#291323"), Color("#b18a55"), 16, 2, 10, true)
	for node in hub.find_children("*", "Control", true, false):
		if node is PanelContainer:
			(node as PanelContainer).add_theme_stylebox_override("panel", panel_style)
		elif node is Button:
			var button := node as Button
			button.add_theme_font_size_override("font_size", 17)
			button.add_theme_color_override("font_color", Color("#eee7ef"))
			button.add_theme_color_override("font_hover_color", Color("#ffe6b7"))
			button.add_theme_color_override("font_pressed_color", Color("#d9c6d8"))
			button.add_theme_color_override("font_disabled_color", Color("#766879"))
			_style_button(button)

func _style_button(button: Button) -> void:
	# The downloaded sheet contains decorative icons, not full button panels.
	# Keep a legible gothic button plate and use each illustration as its icon.
	var normal := UITheme.style(Color("#241326"), Color("#b18a55"), 12, 2, 7, true)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	var hover := UITheme.style(Color("#49213d"), Color("#f0d39b"), 12, 2, 9, true)
	var pressed := UITheme.style(Color("#170d1d"), Color("#e7c38b"), 12, 2, 4)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", Color("#fff0df"))
	button.add_theme_color_override("font_hover_color", Color("#ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("#e5c7dc"))
	button.add_theme_color_override("font_outline_color", Color("#160b19"))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_constant_override("h_separation", 6)
	var artwork := _button_artwork_for(button.name)
	if not artwork.is_empty():
		var texture := load("res://assets/ui/buttons/%s.png" % artwork) as Texture2D
		if texture != null:
			button.icon = texture
			button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			button.expand_icon = false
			var is_bottom_nav := button.get_parent().name == "BottomNavigation"
			var is_rail := button.get_parent().name == "LeftRail"
			button.add_theme_constant_override("icon_max_width", 38 if is_bottom_nav else (30 if is_rail else 26))
			button.add_theme_constant_override("h_separation", 2)
			button.add_theme_font_size_override("font_size", 13 if is_bottom_nav else (12 if is_rail else 14))
			button.add_theme_constant_override("outline_size", 2)
	else:
		button.add_theme_font_size_override("font_size", 15)

func _button_artwork_for(button_name: String) -> String:
	var artwork := {
		"PremiumCurrency": "crystals_double",
		"GoldCurrency": "gold_coins",
		"ResourceCurrency": "resources_crystals",
		"MailButton": "messages_envelope",
		"SettingsShortcut": "settings_gear",
		"EventsButton": "events_calendar",
		"CalendarButton": "calendar_grid",
		"GiftsButton": "gifts_box",
		"AchievementsButton": "achievements_crown",
		"WorldButton": "world_compass",
		"CommunicationButton": "messages_envelope",
		"CharactersButton": "profile_portrait",
		"InventoryButton": "inventory_chest",
		"SummonButton": "crystals_single",
		"StoryButton": "story_book",
		"CombatButton": "combat_swords",
		"CastleButton": "castle_moon",
		"ResourcesButton": "resources_crystals"
	}
	return artwork.get(button_name, "")
