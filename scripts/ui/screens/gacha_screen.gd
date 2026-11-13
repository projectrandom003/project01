class_name GachaScreen
extends OverlayScreen
## Summon screen. Rates, pools, pity thresholds and costs are read verbatim from
## resources/data/banners.json. The pull itself is handled by GachaService.
##
## OFFLINE NOTE: this vertical slice rolls on the client. Phase 12 moves the RNG
## and ownership grant behind the authoritative server boundary.

var _tabs: HBoxContainer
var _main: HBoxContainer
var _selected_banner: String = ""
var _results_layer: Control

# Phase 5 presentation state. ZERO final portraits exist; featured / result
# PortraitViews here all render the procedural fallback.
var _featured_id: String = ""
var _featured_premium: bool = false
var _reveal_animations: int = 0
var _result_cards: int = 0


class ChamberAtmosphere extends Control:
	var elapsed := 0.0
	var motes: Array[Vector3] = []
	var petals: Array[Vector3] = []

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rng := RandomNumberGenerator.new()
		rng.seed = 712903
		for i in range(64):
			motes.append(Vector3(rng.randf_range(0.0, 1280.0), rng.randf_range(0.0, 720.0), rng.randf_range(0.35, 1.0)))
		for i in range(14):
			petals.append(Vector3(rng.randf_range(0.0, 1280.0), rng.randf_range(0.0, 720.0), rng.randf_range(0.5, 1.3)))

	func _process(delta: float) -> void:
		elapsed += delta
		for i in range(motes.size()):
			var mote: Vector3 = motes[i]
			mote.y -= delta * (10.0 + mote.z * 17.0)
			mote.x += sin(elapsed * 0.7 + i * 1.7) * delta * 9.0
			if mote.y < -8.0:
				mote.y = 728.0
			motes[i] = mote
		for i in range(petals.size()):
			var petal: Vector3 = petals[i]
			petal.y -= delta * (16.0 + petal.z * 22.0)
			petal.x += sin(elapsed * 1.4 + i) * delta * 28.0
			if petal.y < -20.0:
				petal.y = 740.0
				petal.x = fposmod(petal.x + 1280.0, 1280.0)
			petals[i] = petal
		queue_redraw()

	func _draw() -> void:
		var center := Vector2(size.x * 0.5, size.y * 0.72)
		var pulse := 0.5 + 0.5 * sin(elapsed * 1.35)
		var beam_alpha := 0.035 + pulse * 0.065
		draw_rect(Rect2(Vector2(center.x - size.x * 0.055, size.y * 0.20), Vector2(size.x * 0.11, size.y * 0.62)), Color(0.73, 0.42, 1.0, beam_alpha), true)
		for ring in range(3):
			var radius := minf(size.x * 0.27, size.y * 0.34) * (0.72 + ring * 0.15)
			var start := elapsed * (0.12 if ring % 2 == 0 else -0.09)
			draw_arc(center, radius, start, start + TAU * 0.88, 96, Color(0.78, 0.56, 1.0, 0.08 + pulse * 0.08), 1.5)
		for i in range(motes.size()):
			var mote: Vector3 = motes[i]
			var alpha := 0.18 + 0.35 * (0.5 + 0.5 * sin(elapsed * 2.2 + i))
			draw_circle(Vector2(mote.x / 1280.0 * size.x, mote.y / 720.0 * size.y), 1.0 + mote.z * 1.5, Color(0.86, 0.72, 1.0, alpha))
		for i in range(petals.size()):
			var petal: Vector3 = petals[i]
			var pos := Vector2(petal.x / 1280.0 * size.x, petal.y / 720.0 * size.y)
			var angle := sin(elapsed * 1.6 + i * 2.0) * 0.8
			var shape := PackedVector2Array([pos + Vector2(-4, 0).rotated(angle), pos + Vector2(0, -2).rotated(angle), pos + Vector2(5, 0).rotated(angle), pos + Vector2(0, 3).rotated(angle)])
			draw_colored_polygon(shape, Color(0.78, 0.22, 0.48, 0.42))


func _ready() -> void:
	super._ready()
	var art_path := "res://assets/ui/backgrounds/summoning_chamber_background.svg"
	if ResourceLoader.exists(art_path):
		var backdrop := TextureRect.new()
		backdrop.name = "SummoningChamberIllustration"
		backdrop.texture = load(art_path) as Texture2D
		backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIFactory.set_full_rect(backdrop)
		add_child(backdrop)
		move_child(backdrop, 0)
	var atmosphere := ChamberAtmosphere.new()
	atmosphere.name = "AnimatedSummoningAtmosphere"
	UIFactory.set_full_rect(atmosphere)
	atmosphere.z_index = 1
	add_child(atmosphere)

class SummonSigil extends Control:
	var elapsed := 0.0
	var glow := Color("#b58cff")
	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * (0.20 + 0.12 * clampf(elapsed / 1.8, 0.0, 1.0))
		var pulse := 1.0 + 0.045 * sin(elapsed * 5.0)
		for ring in range(3):
			var r := radius * (0.66 + float(ring) * 0.22) * pulse
			draw_arc(center, r, elapsed * (0.18 if ring % 2 == 0 else -0.14), elapsed * (0.18 if ring % 2 == 0 else -0.14) + TAU * 0.88, 96, Color(glow.r, glow.g, glow.b, 0.42 - float(ring) * 0.08), 2.0)
		for i in range(8):
			var angle := TAU * float(i) / 8.0 + elapsed * 0.22
			var inner := center + Vector2(cos(angle), sin(angle)) * radius * 0.62
			var outer := center + Vector2(cos(angle), sin(angle)) * radius * 1.08
			draw_line(inner, outer, Color(glow.r, glow.g, glow.b, 0.45), 2.0)
			draw_circle(outer, 3.0 + 1.5 * sin(elapsed * 4.0 + i), Color("#fff0c8"))
		draw_circle(center, 12.0 + 5.0 * sin(elapsed * 6.0), Color(glow.r, glow.g, glow.b, 0.75))



class FeaturedStage extends Control:
	var accent := Color("#b58cff")
	var elapsed := 0.0

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()

	func _draw() -> void:
		var c := size * Vector2(0.5, 0.53)
		var radius := minf(size.x * 0.43, size.y * 0.46)
		var pulse := 1.0 + sin(elapsed * 1.35) * 0.018
		draw_circle(c, radius * 0.94, Color(accent.r, accent.g, accent.b, 0.035))
		for ring in range(4):
			var r := radius * (0.43 + ring * 0.145) * pulse
			draw_arc(c, r, elapsed * (0.035 if ring % 2 == 0 else -0.025), elapsed * (0.035 if ring % 2 == 0 else -0.025) + TAU * 0.91, 96, Color(accent.r, accent.g, accent.b, 0.30 - ring * 0.045), 1.4)
		for i in range(12):
			var a := TAU * float(i) / 12.0 + elapsed * 0.025
			var inner := c + Vector2.RIGHT.rotated(a) * radius * 0.48
			var outer := c + Vector2.RIGHT.rotated(a) * radius * 0.72
			draw_line(inner, outer, Color(accent.r, accent.g, accent.b, 0.34), 1.2)
			draw_circle(outer, 2.0 if i % 3 else 3.0, Color("#f4dfb1", 0.78))
		# A shallow ritual dais gives the portrait a deliberate visual anchor.
		var floor_y := size.y * 0.89
		draw_colored_polygon(PackedVector2Array([
			Vector2(size.x * 0.16, floor_y), Vector2(size.x * 0.5, floor_y - 18),
			Vector2(size.x * 0.84, floor_y), Vector2(size.x * 0.5, floor_y + 18)
		]), Color(0.13, 0.12, 0.22, 0.88))
		draw_polyline(PackedVector2Array([
			Vector2(size.x * 0.16, floor_y), Vector2(size.x * 0.5, floor_y - 18),
			Vector2(size.x * 0.84, floor_y), Vector2(size.x * 0.5, floor_y + 18),
			Vector2(size.x * 0.16, floor_y)
		]), Color(accent.r, accent.g, accent.b, 0.52), 1.5)


func _init() -> void:
	screen_title = "Summon"
	screen_subtitle = "Call a new bond into the glade"


func _build_content() -> void:
	var note := UIFactory.panel(Color("#161326"), Color(UITheme.VIOLET.r, UITheme.VIOLET.g, UITheme.VIOLET.b, 0.35), 8, 1, 8)
	note.add_child(UIFactory.wrapped(
		"Offline vertical slice: summon results, pity and ownership are generated locally. "
		+ "They are not authoritative and will move to the server in Phase 12.",
		11,
		UITheme.TEXT_DIM
	))
	content.add_child(note)

	_tabs = UIFactory.hbox(8)
	content.add_child(_tabs)

	_main = UIFactory.hbox(16)
	_main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_main)


func _refresh() -> void:
	if _tabs == null:
		return
	if _selected_banner.is_empty() or not ContentDB.banners.has(_selected_banner):
		var keys := ContentDB.banners.keys()
		_selected_banner = str(keys[0]) if not keys.is_empty() else ""
	UIFactory.clear(_tabs)
	for banner_id in ContentDB.banners.keys():
		var banner: Dictionary = ContentDB.banners[banner_id]
		var button := UIFactory.button(str(banner.get("name", banner_id)), str(banner_id) == _selected_banner)
		button.custom_minimum_size = Vector2(220, 38)
		button.pressed.connect(func() -> void: _select_banner(str(banner_id)))
		_tabs.add_child(button)
	_rebuild_main()


func _select_banner(banner_id: String) -> void:
	_selected_banner = banner_id
	_refresh()


func _rebuild_main() -> void:
	UIFactory.clear(_main)
	_featured_id = ""
	_featured_premium = false
	var banner: Dictionary = ContentDB.get_banner(_selected_banner)
	if banner.is_empty():
		_main.add_child(UIFactory.label("No summon banners are configured.", 13, UITheme.DANGER))
		return

	# ---------------------------------------------------------------- banner art
	var art_panel := UIFactory.panel(Color("#0a0f1c"), Color(UITheme.GOLD.r, UITheme.GOLD.g, UITheme.GOLD.b, 0.28), 14, 1, 16)
	art_panel.custom_minimum_size = Vector2(390, 0)
	_main.add_child(art_panel)
	var art := UIFactory.vbox(8)
	art_panel.add_child(art)

	var featured: Array = banner.get("featured", [])
	var featured_id := str(featured[0]) if not featured.is_empty() else ""
	var featured_def: CharacterDef = ContentDB.get_character(featured_id)
	var featured_rarity := featured_def.rarity if featured_def != null else "legendary"
	_featured_id = featured_id
	_featured_premium = UITheme.is_premium_rarity(featured_rarity)
	# Rarity-tinted feature stage. The stage is a real sized composition layer,
	# not a tiny icon sitting in an oversized empty panel.
	var featured_effect := UITheme.rarity_effect(featured_rarity)
	var featured_glow: Color = featured_effect.get("glow", UITheme.GOLD_BRIGHT)
	var featured_aura := clampf(float(featured_effect.get("aura", 0.0)), 0.0, 1.0)
	var portrait_backdrop := UIFactory.panel(
		Color("#090d1a").lerp(Color(featured_glow.r, featured_glow.g, featured_glow.b, 1.0), 0.06 + featured_aura * 0.12),
		Color(featured_glow.r, featured_glow.g, featured_glow.b, 0.42 + featured_aura * 0.38),
		14,
		2 if _featured_premium else 1,
		8
	)
	var stage_layer := Control.new()
	stage_layer.custom_minimum_size = Vector2(0, 330)
	stage_layer.clip_contents = true
	portrait_backdrop.add_child(stage_layer)
	var stage := FeaturedStage.new()
	stage.accent = featured_glow
	UIFactory.set_full_rect(stage)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_layer.add_child(stage)
	var portrait_center := CenterContainer.new()
	UIFactory.set_full_rect(portrait_center)
	portrait_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_layer.add_child(portrait_center)
	var portrait := PortraitView.new()
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

	var banner_name := UIFactory.heading(str(banner.get("name", _selected_banner)), 24, UITheme.GOLD_BRIGHT)
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

	# visual_theme line from the art-spec contract (guard null / unknown id).
	if featured_def != null:
		var art_spec := CharacterArtSpec.for_id(featured_def.id) as RefCounted
		if art_spec != null:
			var theme_text := str(art_spec.get("visual_theme"))
			if not theme_text.is_empty():
				var theme_line := UIFactory.wrapped("ART THEME · " + theme_text, 10, UITheme.TEXT_FAINT)
				theme_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				art.add_child(theme_line)

	if featured_def != null:
		art.add_child(_featured_skill_panel(featured_def))

	# --------------------------------------------------------------- info column
	var info := UIFactory.vbox(10)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main.add_child(info)

	var wallet := UIFactory.hbox(8)
	wallet.add_child(UIFactory.chip("Crystals  " + UIFactory.number(GameState.currency("crystals")), UITheme.TEAL))
	wallet.add_child(UIFactory.chip("Gold  " + UIFactory.number(GameState.currency("gold")), UITheme.GOLD))
	info.add_child(wallet)

	var rates_panel := UIFactory.panel(Color("#0e1628"), UITheme.BORDER_SOFT, 10, 1, 12)
	var rates_box := UIFactory.vbox(5)
	rates_box.add_child(UIFactory.label("APPEARANCE RATES", 10, UITheme.TEXT_FAINT))
	var rates: Dictionary = banner.get("rates", {})
	for rarity in GachaService.RARITY_ORDER:
		var row := UIFactory.hbox(8)
		var color := UITheme.rarity_color(rarity)
		var dot := ColorRect.new()
		dot.color = color
		dot.custom_minimum_size = Vector2(8, 8)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(dot)
		row.add_child(UIFactory.label(rarity.capitalize(), 12, color))
		row.add_child(UIFactory.spacer())
		row.add_child(UIFactory.label(UIFactory.percent(float(rates.get(rarity, 0.0))), 12, UITheme.TEXT))
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

	var pity: Dictionary = GameState.pity.get(_selected_banner, GachaService.empty_pity())
	var hard_pity := maxi(1, int(banner.get("hard_pity", 70)))
	var featured_pity := maxi(1, int(banner.get("featured_pity", 140)))
	var legendary_count := int(pity.get("legendary", 0))
	var featured_count := int(pity.get("featured", 0))
	var pity_panel := UIFactory.panel(Color("#0e1628"), UITheme.BORDER_SOFT, 10, 1, 12)
	var pity_box := UIFactory.vbox(6)
	pity_box.add_child(UIFactory.label("PITY PROGRESS", 10, UITheme.TEXT_FAINT))
	pity_box.add_child(_pity_row(
		"Legendary guarantee",
		legendary_count,
		hard_pity,
		"%d more pulls" % maxi(0, hard_pity - legendary_count),
		UITheme.GOLD
	))
	pity_box.add_child(_pity_row(
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
	single.disabled = GameState.currency(currency_id) < single_cost
	single.pressed.connect(func() -> void: _pull(1))
	buttons.add_child(single)
	var ten := UIFactory.button("Summon ×10 — %s %s" % [UIFactory.number(ten_cost), currency_name], true)
	ten.custom_minimum_size = Vector2(0, 48)
	ten.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ten.disabled = GameState.currency(currency_id) < ten_cost
	ten.pressed.connect(func() -> void: _pull(10))
	buttons.add_child(ten)
	info.add_child(buttons)


func _featured_skill_panel(definition: CharacterDef) -> Control:
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


func _pity_row(title: String, value: int, maximum: int, caption: String, color: Color) -> VBoxContainer:
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


func _pull(count: int) -> void:
	var result := GameState.pull_banner(_selected_banner, count)
	if not bool(result.get("ok", false)):
		EventBus.toast_requested.emit(str(result.get("error", "Summon failed.")))
		return
	var rolls: Array = result.get("results", [])
	await _play_summon_reveal(rolls)
	_show_results(rolls)
	_refresh()


func _play_summon_reveal(results: Array) -> void:
	if _results_layer != null and is_instance_valid(_results_layer):
		_results_layer.queue_free()
	_results_layer = Control.new()
	_results_layer.name = "SummonReveal"
	_results_layer.z_index = 80
	UIFactory.set_full_rect(_results_layer)
	_results_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_results_layer)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.008, 0.035, 0.94)
	UIFactory.set_full_rect(shade)
	_results_layer.add_child(shade)
	var sigil := SummonSigil.new()
	sigil.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	sigil.custom_minimum_size = Vector2(560, 460)
	sigil.position -= sigil.custom_minimum_size * 0.5
	var best_rank := 0
	for roll in results:
		best_rank = maxi(best_rank, int(GachaService.RARITY_RANK.get(str(roll.get("rarity", "common")), 0)))
	if best_rank >= int(GachaService.RARITY_RANK.get("legendary", 4)):
		sigil.glow = Color("#ffd47a")
	elif best_rank >= int(GachaService.RARITY_RANK.get("epic", 2)):
		sigil.glow = Color("#c18cff")
	else:
		sigil.glow = Color("#78c9e8")
	_results_layer.add_child(sigil)
	var title := UIFactory.heading("SUMMONING", 28, UITheme.GOLD_BRIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.2
	title.anchor_right = 0.8
	title.anchor_top = 0.18
	title.anchor_bottom = 0.27
	_results_layer.add_child(title)
	var subtitle := UIFactory.label("Ancient bonds answer the call…", 14, UITheme.TEXT_DIM)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.anchor_left = 0.2
	subtitle.anchor_right = 0.8
	subtitle.anchor_top = 0.78
	subtitle.anchor_bottom = 0.86
	_results_layer.add_child(subtitle)
	await get_tree().create_timer(2.15).timeout
	if is_instance_valid(_results_layer):
		_results_layer.queue_free()
	_results_layer = null


func _show_results(results: Array) -> void:
	_reveal_animations = 0
	_result_cards = results.size()
	if _results_layer != null and is_instance_valid(_results_layer):
		_results_layer.queue_free()
	_results_layer = Control.new()
	UIFactory.set_full_rect(_results_layer)
	_results_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_results_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.82)
	UIFactory.set_full_rect(dim)
	_results_layer.add_child(dim)

	var center := CenterContainer.new()
	UIFactory.set_full_rect(center)
	_results_layer.add_child(center)

	var panel := UIFactory.panel(Color("#0b1120"), Color(UITheme.GOLD.r, UITheme.GOLD.g, UITheme.GOLD.b, 0.45), 16, 1, 20, true)
	panel.custom_minimum_size = Vector2(minf(1120, 1180), 0)
	center.add_child(panel)
	var box := UIFactory.vbox(12)
	panel.add_child(box)

	var header := UIFactory.hbox(10)
	header.add_child(UIFactory.heading("Summon Results", 24, UITheme.GOLD_BRIGHT))
	header.add_child(UIFactory.spacer())
	var best_rank := -1
	for roll in results:
		best_rank = maxi(best_rank, int(GachaService.RARITY_RANK.get(str(roll.get("rarity", "common")), 0)))
	var best_name := "Common"
	for rarity in GachaService.RARITY_ORDER:
		if int(GachaService.RARITY_RANK.get(rarity, 0)) == best_rank:
			best_name = rarity.capitalize()
	header.add_child(UIFactory.chip("Best: " + best_name, UITheme.rarity_color(best_name.to_lower())))
	# Premium "Best:" flourish when the top rarity is legendary / mythic.
	if UITheme.is_premium_rarity(best_name.to_lower()):
		var best_effect := UITheme.rarity_effect(best_name.to_lower())
		var best_glow: Color = best_effect.get("glow", UITheme.GOLD_BRIGHT)
		var best_flourish := UIFactory.label("✦ " + UITheme.rarity_tier_label(best_name.to_lower()) + " ✦", 13, best_glow)
		header.add_child(best_flourish)
	box.add_child(header)
	box.add_child(UIFactory.separator())

	var grid := UIFactory.grid(mini(5, maxi(1, results.size())), 10)
	box.add_child(grid)
	for index in results.size():
		var roll: Dictionary = results[index]
		var card := _result_card(roll)
		grid.add_child(card)
		card.modulate = Color(1, 1, 1, 0)
		var is_premium := bool(card.get_meta("premium", false))
		var tween := create_tween()
		if is_premium:
			# Longer stagger + a subtle scale pop for legendary / mythic reveals.
			tween.tween_interval(index * 0.09)
			tween.tween_property(card, "modulate:a", 1.0, 0.16)
			card.pivot_offset = card.custom_minimum_size * 0.5
			card.scale = Vector2(0.9, 0.9)
			tween.tween_property(card, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_reveal_animations += 1
		else:
			# Existing staggered fade-in, unchanged.
			tween.tween_interval(index * 0.055)
			tween.tween_property(card, "modulate:a", 1.0, 0.16)

	var footer := UIFactory.hbox(10)
	footer.add_child(UIFactory.wrapped(
		"Duplicates raise Awakening. This result is already saved locally.",
		11,
		UITheme.TEXT_FAINT
	))
	footer.add_child(UIFactory.spacer())
	var again := UIFactory.button("Summon Again", false)
	again.pressed.connect(func() -> void:
		if _results_layer != null:
			_results_layer.queue_free()
			_results_layer = null
		_pull(10 if results.size() >= 10 else 1)
	)
	footer.add_child(again)
	var close := UIFactory.button("Continue", true)
	close.custom_minimum_size = Vector2(140, 40)
	close.pressed.connect(func() -> void:
		if _results_layer != null:
			_results_layer.queue_free()
			_results_layer = null
	)
	footer.add_child(close)
	box.add_child(footer)


func _result_card(roll: Dictionary) -> PanelContainer:
	var character_id := str(roll.get("character_id", ""))
	var definition: CharacterDef = ContentDB.get_character(character_id)
	var rarity := str(roll.get("rarity", "common"))
	var color := UITheme.rarity_color(rarity)
	var premium := UITheme.is_premium_rarity(rarity)
	var effect := UITheme.rarity_effect(rarity)
	var glow: Color = effect.get("glow", UITheme.GOLD_BRIGHT)
	# Premium cards get a wider, glow-tinted border + brighter background.
	var card_bg := Color("#0d1526")
	var card_border := color
	var card_width := 2
	if premium:
		card_bg = Color("#0d1526").lerp(Color(glow.r, glow.g, glow.b, 1.0), 0.10)
		card_border = Color(glow.r, glow.g, glow.b, 0.95)
		card_width = int(effect.get("border_width", 3))
	var card := UIFactory.panel(card_bg, card_border, 10, card_width, 8)
	card.set_meta("premium", premium)
	card.custom_minimum_size = Vector2(172, 238)
	var box := UIFactory.vbox(4)
	card.add_child(box)
	var portrait := PortraitView.new()
	portrait.custom_minimum_size = Vector2(150, 150)
	if definition != null:
		portrait.setup_character(definition)
	else:
		portrait.setup({}, "Human", "neutral", rarity, 0)
	box.add_child(portrait)
	var name_label := UIFactory.label(definition.display_name if definition != null else character_id, 13, UITheme.TEXT)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(name_label)
	var rarity_label := UIFactory.label(rarity.capitalize(), 10, color)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(rarity_label)
	# Premium tier flourish label ("LEGENDARY" / "MYTHIC").
	if premium:
		var tier_label := UIFactory.label("✦ " + UITheme.rarity_tier_label(rarity) + " ✦", 9, glow)
		tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(tier_label)
	if bool(roll.get("featured", false)):
		var featured_label := UIFactory.label("FEATURED", 9, UITheme.GOLD)
		featured_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(featured_label)
	elif bool(roll.get("is_new", false)):
		var new_label := UIFactory.label("NEW", 9, UITheme.GREEN)
		new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(new_label)
	elif int(roll.get("awakening_gain", 0)) > 0:
		var dupe_label := UIFactory.label("AWAKENING +1", 9, UITheme.TEAL)
		dupe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(dupe_label)
	elif bool(roll.get("guaranteed", false)):
		var guaranteed_label := UIFactory.label("GUARANTEED", 9, UITheme.VIOLET)
		guaranteed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(guaranteed_label)
	return card


## Additive presentation report (Phase 5). ZERO final portraits exist; featured
## and result PortraitViews all render the procedural fallback.
func presentation_report() -> Dictionary:
	return {
		"screen": "summon",
		"featured_id": _featured_id,
		"featured_premium": _featured_premium,
		"rarity_effects_enabled": true,
		"reveal_animations": _reveal_animations,
		"result_cards": _result_cards,
	}
