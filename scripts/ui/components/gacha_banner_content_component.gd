class_name GachaBannerContentComponent
extends Node
## Owns the summon banner's featured-art, rates, pity and banner-detail presentation.

var screen: GachaScreen
var _scarlet_template: ScarletRequiemBannerTemplateComponent

func _ready() -> void:
	_scarlet_template = get_node_or_null("ScarletRequiemTemplate") as ScarletRequiemBannerTemplateComponent


func bind(owner_screen: GachaScreen) -> void:
	screen = owner_screen

func rebuild_main() -> void:
	UIFactory.clear(screen._main)
	screen._featured_id = ""
	screen._featured_premium = false
	var banner: Dictionary = ContentDB.get_banner(screen._selected_banner)
	if banner.is_empty():
		screen._main.add_child(UIFactory.label("No summon banners are configured.", 13, UITheme.DANGER))
		return

	# ---------------------------------------------------------------- banner art
	var art_scroll := ScrollContainer.new()
	art_scroll.custom_minimum_size = Vector2(390, 0)
	art_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen._main.add_child(art_scroll)
	var art_panel := UIFactory.panel(Color("#0a0f1c"), Color(UITheme.GOLD.r, UITheme.GOLD.g, UITheme.GOLD.b, 0.28), 14, 1, 16)
	art_panel.custom_minimum_size = Vector2(370, 0)
	art_scroll.add_child(art_panel)
	var art := UIFactory.vbox(8)
	art_panel.add_child(art)

	var featured: Array = banner.get("featured", [])
	var featured_id := str(featured[0]) if not featured.is_empty() else ""
	var featured_def: CharacterDef = ContentDB.get_character(featured_id)
	var featured_rarity := featured_def.rarity if featured_def != null else "legendary"
	screen._featured_id = featured_id
	screen._featured_premium = UITheme.is_premium_rarity(featured_rarity)
	# Use Nyx's supplied bespoke banner artwork when she is featured.
	# Scarlet Requiem is an independent featured character and banner.
	var featured_effect := UITheme.rarity_effect(featured_rarity)
	var featured_glow: Color = featured_effect.get("glow", UITheme.GOLD_BRIGHT)
	var featured_aura := clampf(float(featured_effect.get("aura", 0.0)), 0.0, 1.0)
	var nyx_banner_path := "res://assets/characters/nyx/Nyx_Vaelora_Hollow_Moon_Overture.png"
	var has_nyx_banner_art := featured_id == "nyx" and ResourceLoader.exists(nyx_banner_path)
	var is_scarlet_requiem := str(screen._selected_banner) == "scarlet_requiem" and featured_id == "scarlet_requiem"
	if has_nyx_banner_art:
		var banner_art := GachaScreen.FEATURED_BANNER_ARTWORK_SCENE.instantiate() as TextureRect
		banner_art.name = "NyxFeaturedBannerArtwork"
		banner_art.texture = load(nyx_banner_path) as Texture2D
		art.add_child(banner_art)
	elif is_scarlet_requiem:
		add_scarlet_requiem_banner_template(art, banner, featured_def, featured_glow)
	else:
		var portrait_backdrop := GachaScreen.FEATURED_BANNER_ART_FRAME_SCENE.instantiate() as PanelContainer
		portrait_backdrop.add_theme_stylebox_override(
			"panel",
			UITheme.style(
				Color("#090d1a").lerp(Color(featured_glow.r, featured_glow.g, featured_glow.b, 1.0), 0.06 + featured_aura * 0.12),
				Color(featured_glow.r, featured_glow.g, featured_glow.b, 0.42 + featured_aura * 0.38),
				14,
				2 if screen._featured_premium else 1,
				8
			)
		)
		var stage := portrait_backdrop.get_node("FrameContent/StageLayer/Stage") as FeaturedSummonStage
		stage.accent = featured_glow
		var portrait_center := portrait_backdrop.get_node("FrameContent/PortraitCenter") as CenterContainer
		var portrait := GachaScreen.PORTRAIT_VIEW_SCENE.instantiate() as PortraitView
		portrait.custom_minimum_size = Vector2(252, 292)
		portrait.show_frame = false
		if featured_def != null:
			portrait.setup_character(featured_def)
			var featured_portrait_path := "res://assets/portraits/summon/%s.png" % featured_def.id
			if ResourceLoader.exists(featured_portrait_path):
				var featured_texture := load(featured_portrait_path) as Texture2D
				if featured_texture != null:
					portrait.set_portrait_texture(featured_texture)
		else:
			portrait.setup({}, "Human", "neutral", "legendary", 0)
		portrait_center.add_child(portrait)
		art.add_child(portrait_backdrop)

	if not has_nyx_banner_art and not is_scarlet_requiem:
		var banner_name := UIFactory.heading(str(banner.get("name", screen._selected_banner)), 24, UITheme.GOLD_BRIGHT)
		banner_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		art.add_child(banner_name)
		var subtitle := UIFactory.label(str(banner.get("subtitle", "")), 12, UITheme.TEXT_DIM)
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		art.add_child(subtitle)
	var chips := UIFactory.hbox(6)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_child(UIFactory.chip(str(banner.get("type", "standard")).capitalize(), UITheme.VIOLET))
	if featured_def != null:
		chips.add_child(UIFactory.rarity_chip(featured_def.rarity))
	art.add_child(chips)
	if featured_def != null:
		var featured_label := UIFactory.label("Featured · " + featured_def.display_name, 13, UITheme.GOLD)
		featured_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		art.add_child(featured_label)

	if featured_def != null:
		art.add_child(featured_skill_panel(featured_def))

	# --------------------------------------------------------------- info column
	var info_scroll := ScrollContainer.new()
	info_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen._main.add_child(info_scroll)
	var info := UIFactory.vbox(10)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_scroll.add_child(info)

	var wallet := UIFactory.hbox(8)
	wallet.add_child(UIFactory.chip("Crystals  " + UIFactory.number(GameState.inventory_domain.currency("crystals")), UITheme.TEAL))
	wallet.add_child(UIFactory.chip("Gold  " + UIFactory.number(GameState.inventory_domain.currency("gold")), UITheme.GOLD))
	info.add_child(wallet)

	var scarlet_palette := is_scarlet_requiem
	var rates_panel := UIFactory.panel(
		Color("#180b16") if scarlet_palette else Color("#0e1628"),
		Color("#8f3b59") if scarlet_palette else UITheme.BORDER_SOFT,
		12, 1, 12
	)
	var rates_box := UIFactory.vbox(5)
	rates_box.add_child(UIFactory.label("APPEARANCE RATES", 10, UITheme.TEXT_FAINT))
	var rates: Dictionary = banner.get("rates", {})
	for rarity in GachaService.RARITY_ORDER:
		var color := UITheme.rarity_color(rarity)
		var row := GachaScreen.RARITY_RATE_ROW_SCENE.instantiate() as RarityRateRow
		row.setup(rarity, UIFactory.percent(float(rates.get(rarity, 0.0))), color)
		rates_box.add_child(row)
	var guarantee := UIFactory.wrapped(
		"10-pull guarantees at least one Epic or better. Featured rate-up: %s. "
		% UIFactory.percent(float(banner.get("featured_rate", 0.5)), 0)
		+ "Hard pity: %d pulls. Featured guarantee: %d pulls." % [
			int(banner.get("hard_pity", 70)), int(banner.get("featured_pity", 140))
		],
		11,
		UITheme.TEXT_FAINT
	)
	rates_box.add_child(guarantee)
	rates_panel.add_child(rates_box)
	info.add_child(rates_panel)

	var pity: Dictionary = GameState.reward_domain.pity.get(screen._selected_banner, GachaService.empty_pity())
	var hard_pity := maxi(1, int(banner.get("hard_pity", 70)))
	var featured_pity := maxi(1, int(banner.get("featured_pity", 140)))
	var legendary_count := int(pity.get("legendary", 0))
	var featured_count := int(pity.get("featured", 0))
	var pity_panel := UIFactory.panel(
		Color("#180b16") if scarlet_palette else Color("#0e1628"),
		Color("#8f3b59") if scarlet_palette else UITheme.BORDER_SOFT,
		12, 1, 12
	)
	var pity_box := UIFactory.vbox(6)
	pity_box.add_child(UIFactory.label("PITY PROGRESS", 10, UITheme.TEXT_FAINT))
	pity_box.add_child(pity_row(
		"Legendary guarantee",
		legendary_count,
		hard_pity,
		"%d more pulls" % maxi(0, hard_pity - legendary_count),
		UITheme.GOLD
	))
	pity_box.add_child(pity_row(
		"Featured guarantee",
		featured_count,
		featured_pity,
		"%d more pulls" % maxi(0, featured_pity - featured_count),
		UITheme.VIOLET
	))
	pity_panel.add_child(pity_box)
	info.add_child(pity_panel)

	info.add_child(UIFactory.spacer(true))
	var cost: Dictionary = banner.get("cost", {})
	var currency_id := str(cost.get("currency", "crystals"))
	var currency_name := str(ContentDB.get_item(currency_id).get("name", currency_id))
	var single_cost := int(cost.get("single", 0))
	var ten_cost := int(cost.get("ten", 0))
	var buttons := UIFactory.hbox(10)
	var single := UIFactory.button("Summon ×1 — %s %s" % [UIFactory.number(single_cost), currency_name])
	single.custom_minimum_size = Vector2(0, 48)
	single.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if scarlet_palette:
		style_scarlet_pull_button(single, false)
	single.disabled = GameState.inventory_domain.currency(currency_id) < single_cost
	single.pressed.connect(func() -> void: screen._pull(1))
	buttons.add_child(single)
	var ten := UIFactory.button("Summon ×10 — %s %s" % [UIFactory.number(ten_cost), currency_name], true)
	ten.custom_minimum_size = Vector2(0, 48)
	ten.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if scarlet_palette:
		style_scarlet_pull_button(ten, true)
	ten.disabled = GameState.inventory_domain.currency(currency_id) < ten_cost
	ten.pressed.connect(func() -> void: screen._pull(10))
	buttons.add_child(ten)
	info.add_child(buttons)



func style_scarlet_pull_button(button: Button, primary: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#70243f") if primary else Color("#351321")
	normal.border_color = Color("#e08aa5") if primary else Color("#a94a69")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(9)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#913453") if primary else Color("#512033")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color("#ffe8ef"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)


func featured_skill_panel(definition: CharacterDef) -> Control:
	var panel := UIFactory.panel(Color("#100d1c"), Color(UITheme.VIOLET.r, UITheme.VIOLET.g, UITheme.VIOLET.b, 0.42), 10, 1, 10)
	var box := UIFactory.vbox(6)
	box.add_child(UIFactory.label("SIGNATURE ARTS", 10, UITheme.TEXT_FAINT))
	var skill_ids: Array = definition.skills.duplicate()
	skill_ids.append(definition.ultimate)
	var labels := ["ACTIVE I", "ACTIVE II", "ULTIMATE"]
	for index in mini(3, skill_ids.size()):
		var skill_id := str(skill_ids[index])
		var skill: SkillDef = ContentDB.get_skill(skill_id)
		if skill == null:
			continue
		var entry := UIFactory.vbox(2)
		var header := UIFactory.hbox(6)
		var tier_color := UITheme.GOLD_BRIGHT if index == 2 else UITheme.VIOLET
		header.add_child(UIFactory.label(labels[index], 9, tier_color))
		header.add_child(UIFactory.spacer())
		header.add_child(UIFactory.label(skill.display_name, 12, UITheme.TEXT))
		entry.add_child(header)
		entry.add_child(UIFactory.wrapped(skill.description, 10, UITheme.TEXT_DIM))
		box.add_child(entry)
		if index < mini(3, skill_ids.size()) - 1:
			box.add_child(UIFactory.separator())
	panel.add_child(box)
	return panel



func add_scarlet_requiem_banner_template(parent: VBoxContainer, banner: Dictionary, featured_def: CharacterDef, featured_glow: Color) -> void:
	if _scarlet_template != null:
		_scarlet_template.build(parent, banner, featured_def, featured_glow)


func pity_row(title: String, value: int, maximum: int, caption: String, color: Color) -> VBoxContainer:
	var box := UIFactory.vbox(3)
	var header := UIFactory.hbox(8)
	header.add_child(UIFactory.label(title, 11, UITheme.TEXT_DIM))
	header.add_child(UIFactory.spacer())
	header.add_child(UIFactory.label(caption, 10, color))
	box.add_child(header)
	var bar := UIFactory.bar(color, 8)
	bar.max_value = maximum
	bar.value = clampi(value, 0, maximum)
	box.add_child(bar)
	return box
