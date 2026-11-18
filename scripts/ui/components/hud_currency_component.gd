class_name HUDCurrencyComponent
extends Node
## Owns the HUD's wallet/currency chip presentation.

var hud: HUD

func bind(owner: HUD) -> void:
	hud = owner

func refresh_currency() -> void:
	if hud == null or hud._currency_box == null:
		return
	UIFactory.clear(hud._currency_box)
	add_currency_chip("Gold  " + UIFactory.number(GameState.inventory_domain.currency("gold")), UITheme.GOLD)
	add_currency_chip("Crystals  " + UIFactory.number(GameState.inventory_domain.currency("crystals")), UITheme.TEAL)
	if GameState.inventory_domain.currency("ancient_coins") > 0:
		add_currency_chip("Ancient Coins  " + UIFactory.number(GameState.inventory_domain.currency("ancient_coins")), Color("#d9ff9f"))
	if GameState.inventory_domain.currency("gems") > 0:
		add_currency_chip("Gems  " + UIFactory.number(GameState.inventory_domain.currency("gems")), UITheme.VIOLET)

func add_currency_chip(value_text: String, tint: Color) -> void:
	if hud == null:
		return
	var chip := HUD.CURRENCY_CHIP_SCENE.instantiate() as PanelContainer
	(chip.get_node("Content/Dot") as ColorRect).color = tint
	var value_label := chip.get_node("Content/ValueLabel") as Label
	value_label.text = value_text
	value_label.add_theme_color_override("font_color", tint)
	var style := chip.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = Color(tint.r, tint.g, tint.b, 0.10)
	style.border_color = Color(tint.r, tint.g, tint.b, 0.45)
	chip.add_theme_stylebox_override("panel", style)
	hud._currency_box.add_child(chip)
