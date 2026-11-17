class_name CollectionRosterComponent
extends Node
## Owns collection filtering, card creation, card styling and selection.

var screen: CollectionScreen


func bind(owner_screen: CollectionScreen) -> void:
	screen = owner_screen

func set_filter(value: String) -> void:
	screen._filter = value
	rebuild_grid()


func rebuild_grid() -> void:
	if screen._grid == null:
		return
	screen._premium_count = 0
	UIFactory.clear(screen._grid)
	screen._cards.clear()
	var instances: Array = []
	for instance in GameState.roster_domain.roster:
		if screen._filter == "party" and not GameState.roster_domain.party.has(instance.uid):
			continue
		instances.append(instance)
	instances.sort_custom(func(a, b) -> bool:
		var def_a: CharacterDef = ContentDB.get_character(a.char_id)
		var def_b: CharacterDef = ContentDB.get_character(b.char_id)
		var rank_a: int = int(GachaService.RARITY_RANK.get(def_a.rarity, 0)) if def_a != null else 0
		var rank_b: int = int(GachaService.RARITY_RANK.get(def_b.rarity, 0)) if def_b != null else 0
		if rank_a == rank_b:
			return a.char_id < b.char_id
		return rank_a > rank_b
	)
	if instances.is_empty():
		screen._grid.add_child(UIFactory.label("No characters match this filter.", 13, UITheme.TEXT_DIM))
		screen._show_detail("")
		return
	if screen._selected_uid.is_empty() or not has_uid(instances, screen._selected_uid):
		screen._selected_uid = instances[0].uid
	for instance in instances:
		screen._grid.add_child(make_card(instance))
	screen._show_detail(screen._selected_uid)


func has_uid(instances: Array, uid: String) -> bool:
	for instance in instances:
		if instance.uid == uid:
			return true
	return false


func make_card(instance: CharacterInstance) -> PanelContainer:
	var definition: CharacterDef = ContentDB.get_character(instance.char_id)
	var rarity := definition.rarity if definition != null else "common"
	var effect := UITheme.rarity_effect(rarity)
	var premium := UITheme.is_premium_rarity(rarity)
	var glow: Color = effect.get("glow", UITheme.GOLD_BRIGHT)
	var tier_text := UITheme.rarity_tier_label(rarity) if premium else ""
	var card := CollectionScreen.ROSTER_CARD_SCENE.instantiate() as RosterCharacterCard
	card.setup(instance.uid, definition, instance.level, GameState.roster_domain.party.has(instance.uid), premium, glow, tier_text)
	card.set_meta("premium", premium)
	card.set_meta("rarity", rarity)
	if premium:
		screen._premium_count += 1
	var uid := instance.uid
	card.selected.connect(select)
	card.mouse_entered.connect(func() -> void:
		if screen._selected_uid != uid:
			card.add_theme_stylebox_override("panel", UITheme.style(Color("#17233c"), UITheme.GOLD, 10, 1, 8))
	)
	card.mouse_exited.connect(func() -> void: style_card(card, uid))
	screen._cards[uid] = card
	style_card(card, uid)
	return card


func style_card(card: PanelContainer, uid: String) -> void:
	var instance := screen._find_instance(uid)
	if instance == null:
		return
	var definition: CharacterDef = ContentDB.get_character(instance.char_id)
	var border := UITheme.rarity_color(definition.rarity) if definition != null else UITheme.BORDER_SOFT
	if uid != screen._selected_uid:
		border = Color(border.r, border.g, border.b, 0.35)
	var width := 2 if uid == screen._selected_uid else 1
	var bg := Color("#111a2d") if uid != screen._selected_uid else Color("#1a2947")
	# Extend (do not replace) the resting style for premium rarities: a wider,
	# glow-tinted border and brighter background. Non-premium remains identical.
	if definition != null and UITheme.is_premium_rarity(definition.rarity):
		var effect := UITheme.rarity_effect(definition.rarity)
		var glow: Color = effect.get("glow", UITheme.GOLD_BRIGHT)
		width = int(effect.get("border_width", 3))
		bg = Color("#1a2947") if uid == screen._selected_uid else Color("#16203a")
		border = border.lerp(Color(glow.r, glow.g, glow.b, border.a), 0.40)
	card.add_theme_stylebox_override("panel", UITheme.style(
		bg,
		border,
		10,
		width,
		8
	))


func select(uid: String) -> void:
	screen._selected_uid = uid
	for card_uid in screen._cards.keys():
		style_card(screen._cards[card_uid], str(card_uid))
	screen._show_detail(uid)


