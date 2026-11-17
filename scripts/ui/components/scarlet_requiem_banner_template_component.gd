class_name ScarletRequiemBannerTemplateComponent
extends Node
## Dedicated Scarlet Requiem showcase. Portrait and lore are stacked so the
## narrow artwork column never squeezes the character copy into a thin strip.

func build(parent: VBoxContainer, banner: Dictionary, featured_def: CharacterDef, _featured_glow: Color) -> void:
	var frame := UIFactory.panel(Color("#100710"), Color("#a33e5d"), 16, 2, 12, true)
	frame.custom_minimum_size = Vector2(0, 590)
	parent.add_child(frame)

	var stack := Control.new()
	stack.custom_minimum_size = Vector2(0, 566)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_child(stack)

	var bg := ColorRect.new()
	bg.color = Color("#160914")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack.add_child(bg)
	var wash := ColorRect.new()
	wash.color = Color(0.30, 0.035, 0.095, 0.24)
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack.add_child(wash)
	var top_rule := ColorRect.new()
	top_rule.color = Color("#b84c70")
	top_rule.anchor_left = 0.05
	top_rule.anchor_right = 0.95
	top_rule.anchor_top = 0.015
	top_rule.anchor_bottom = 0.021
	stack.add_child(top_rule)

	var content_root := UIFactory.vbox(7)
	content_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_root.offset_left = 12
	content_root.offset_top = 10
	content_root.offset_right = -12
	content_root.offset_bottom = -10
	stack.add_child(content_root)

	var header := UIFactory.hbox(6)
	content_root.add_child(header)
	header.add_child(UIFactory.chip("LIMITED", Color("#a83254")))
	header.add_child(UIFactory.spacer())
	header.add_child(UIFactory.chip("THE CRIMSON REAPER", Color("#7d2947")))

	var title := UIFactory.heading("Scarlet Requiem", 27, Color("#ffe5ec"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("#270711"))
	title.add_theme_constant_override("outline_size", 4)
	content_root.add_child(title)
	var subtitle := UIFactory.label(str(banner.get("subtitle", "Limited summon — The Crimson Reaper")), 12, Color("#e6b8c7"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_root.add_child(subtitle)

	var portrait_panel := UIFactory.panel(Color(0.12, 0.025, 0.065, 0.88), Color(0.72, 0.22, 0.39, 0.68), 12, 1, 7)
	portrait_panel.custom_minimum_size = Vector2(0, 316)
	content_root.add_child(portrait_panel)
	var portrait_column := UIFactory.vbox(4)
	portrait_column.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_panel.add_child(portrait_column)
	var portrait_center := CenterContainer.new()
	portrait_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_column.add_child(portrait_center)
	var portrait := GachaScreen.PORTRAIT_VIEW_SCENE.instantiate() as PortraitView
	portrait.custom_minimum_size = Vector2(220, 258)
	portrait.show_frame = false
	if featured_def != null:
		portrait.setup_character(featured_def)
		var summon_path := "res://assets/portraits/summon/%s.png" % featured_def.id
		if featured_def.id == "scarlet_requiem":
			summon_path = "res://assets/characters/scarlet_requiem/banner_portrait.jpg"
		if ResourceLoader.exists(summon_path):
			var texture := load(summon_path) as Texture2D
			if texture != null:
				portrait.set_portrait_texture(texture)
	else:
		portrait.setup({}, "Vampire", "dark", "epic", 0)
	portrait_center.add_child(portrait)
	if featured_def != null:
		var name_label := UIFactory.label(featured_def.display_name, 17, Color("#ffe0e9"))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		portrait_column.add_child(name_label)
		var title_label := UIFactory.label(featured_def.title, 11, Color("#d9a6b8"))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		portrait_column.add_child(title_label)

	var lore_panel := UIFactory.panel(Color(0.075, 0.018, 0.045, 0.94), Color(0.58, 0.20, 0.34, 0.58), 10, 1, 9)
	content_root.add_child(lore_panel)
	var lore_box := UIFactory.vbox(4)
	lore_panel.add_child(lore_box)
	lore_box.add_child(UIFactory.label("THE REQUIEM", 10, Color("#f08aaa")))
	if featured_def != null:
		lore_box.add_child(UIFactory.wrapped(featured_def.lore, 11, Color("#f0dce3")))
		if not featured_def.passive_text.is_empty():
			lore_box.add_child(UIFactory.wrapped(featured_def.passive_text, 10, Color("#d8b6c2")))
	var art_note := "The Crimson Reaper — beneath the blood moon."
	if featured_def != null:
		var art_spec: Variant = CharacterArtSpec.for_id(featured_def.id)
		if art_spec != null:
			var theme_text := str(art_spec.get("visual_theme")) if art_spec.has_method("get") else ""
			if theme_text.strip_edges() != "":
				art_note = "Theme: " + theme_text
	content_root.add_child(UIFactory.wrapped(art_note, 10, Color("#c99aaa")))

	var footer := UIFactory.hbox(6)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	if featured_def != null:
		footer.add_child(UIFactory.rarity_chip(featured_def.rarity))
		footer.add_child(UIFactory.element_chip(featured_def.element))
		footer.add_child(UIFactory.chip(featured_def.role, Color("#7d2947")))
	content_root.add_child(footer)