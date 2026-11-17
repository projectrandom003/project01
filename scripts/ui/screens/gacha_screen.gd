class_name GachaScreen
extends OverlayScreen
## Summon screen. Rates, pools, pity thresholds and costs are read verbatim from
## resources/data/banners.json. The pull itself is handled by GachaService.
##
## OFFLINE NOTE: this vertical slice rolls on the client. Phase 12 moves the RNG
## and ownership grant behind the authoritative server boundary.

const FEATURED_BANNER_ART_FRAME_SCENE: PackedScene = preload("res://scenes/ui/components/featured_banner_art_frame.tscn")
const FEATURED_BANNER_ARTWORK_SCENE: PackedScene = preload("res://scenes/ui/components/featured_banner_artwork.tscn")
const PORTRAIT_VIEW_SCENE: PackedScene = preload("res://scenes/ui/components/portrait_view.tscn")
const GACHA_LAYOUT_SCENE: PackedScene = preload("res://scenes/ui/components/gacha_screen_layout.tscn")
const SUMMON_REVEAL_SCENE: PackedScene = preload("res://scenes/ui/components/summon_reveal_overlay.tscn")
const SUMMON_RESULTS_SCENE: PackedScene = preload("res://scenes/ui/components/summon_results_overlay.tscn")
const SUMMON_RESULT_CARD_SCENE: PackedScene = preload("res://scenes/ui/components/summon_result_card.tscn")
const RARITY_RATE_ROW_SCENE: PackedScene = preload("res://scenes/ui/components/rarity_rate_row.tscn")
const CHAMBER_ATMOSPHERE_SCENE: PackedScene = preload("res://scenes/ui/components/summoning_chamber_atmosphere.tscn")

var _tabs: HBoxContainer
var _main: HBoxContainer
var _selected_banner: String = ""
var _results_layer: Control
var _summon_busy: bool = false

# Summon presentation state. Featured portrait assets are resolved by the
# banner content component; missing optional portraits retain the safe fallback.
var _featured_id: String = ""
var _featured_premium: bool = false
var _reveal_animations: int = 0
var _result_cards: int = 0
var _banner_content: GachaBannerContentComponent
var _summon_flow: GachaSummonFlowComponent


func _ready() -> void:
	_banner_content = get_node_or_null("BannerContent") as GachaBannerContentComponent
	_summon_flow = get_node_or_null("SummonFlow") as GachaSummonFlowComponent
	if _banner_content == null or _summon_flow == null:
		push_error("GachaScreen requires authored BannerContent and SummonFlow components.")
		return
	_banner_content.bind(self)
	_summon_flow.bind(self)
	super._ready()
	var atmosphere := get_node_or_null("SummoningChamberAtmosphere") as Control
	if atmosphere == null:
		push_error("GachaScreen requires its authored SummoningChamberAtmosphere scene.")
		return
	atmosphere.z_index = -1
	# OverlayScreen normally dims the whole scene and places an opaque glass
	# panel over it. Summoning is a full-scene destination: soften that dimmer
	# and turn the shell panel into translucent glass so the chamber is visible.
	var shell_dim := get_node_or_null("OverlayShell/Dim") as ColorRect
	if shell_dim != null:
		shell_dim.color = Color(0.01, 0.012, 0.035, 0.24)
	var shell_panel := get_node_or_null("OverlayShell/Margin/Panel") as PanelContainer
	if shell_panel != null:
		var glass := StyleBoxFlat.new()
		glass.bg_color = Color(0.025, 0.018, 0.055, 0.58)
		glass.border_color = Color(0.72, 0.56, 0.91, 0.52)
		glass.set_border_width_all(1)
		glass.set_corner_radius_all(16)
		glass.content_margin_left = 18
		glass.content_margin_right = 18
		glass.content_margin_top = 18
		glass.content_margin_bottom = 18
		shell_panel.add_theme_stylebox_override("panel", glass)
	# Summoning chamber key art is an authored TextureRect in gacha_screen.tscn.
	# Keep the node in the editor; runtime logic only controls its availability.
	var backdrop := get_node_or_null("SummoningChamberIllustration") as TextureRect
	if backdrop != null:
		backdrop.visible = backdrop.texture != null






func _init() -> void:
	screen_title = "Summon"
	screen_subtitle = "Call a new bond into the glade"


func _input(event: InputEvent) -> void:
	# The summon overlay owns Escape even while a tab, button or scroll area has focus.
	if _closing or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("open_menu"):
		close_screen()
		var viewport := get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()


func _build_content() -> void:
	var layout := GACHA_LAYOUT_SCENE.instantiate() as VBoxContainer
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(layout)
	_tabs = layout.get_node("BannerTabs") as HBoxContainer
	_main = layout.get_node("Main") as HBoxContainer


func _refresh() -> void:
	if _tabs == null:
		return
	if _selected_banner.is_empty() or not ContentDB.banners.has(_selected_banner):
		var keys := ContentDB.banners.keys()
		_selected_banner = str(keys[0]) if not keys.is_empty() else ""
	UIFactory.clear(_tabs)
	# Keep the exit control and both banner tabs adjacent. An expanding spacer
	# here pushed the tabs beyond the viewport on compact layouts, making the
	# second summon page appear missing or unresponsive.
	var return_button := UIFactory.button("RETURN TO GAME  ✕")
	return_button.name = "ReturnToGameButton"
	return_button.custom_minimum_size = Vector2(150, 40)
	return_button.tooltip_text = "Close the summon screen and return to your journey"
	return_button.pressed.connect(close_screen)
	_tabs.add_child(return_button)
	for banner_id in ContentDB.banners.keys():
		var banner: Dictionary = ContentDB.banners[banner_id]
		var button := UIFactory.button(str(banner.get("name", banner_id)), str(banner_id) == _selected_banner)
		button.custom_minimum_size = Vector2(160, 40)
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.pressed.connect(func() -> void: _select_banner(str(banner_id)))
		_tabs.add_child(button)
	_rebuild_main()


func _select_banner(banner_id: String) -> void:
	_selected_banner = banner_id
	_refresh()


func _rebuild_main() -> void:
	_banner_content.rebuild_main()

func _featured_skill_panel(definition: CharacterDef) -> Control:
	return _banner_content.featured_skill_panel(definition)

func _add_scarlet_requiem_banner_template(parent: VBoxContainer, banner: Dictionary, featured_def: CharacterDef, featured_glow: Color) -> void:
	_banner_content.add_scarlet_requiem_banner_template(parent, banner, featured_def, featured_glow)

func _pity_row(title: String, value: int, maximum: int, caption: String, color: Color) -> VBoxContainer:
	return _banner_content.pity_row(title, value, maximum, caption, color)

func _pull(count: int) -> void:
	if _summon_busy:
		return
	_summon_busy = true
	# Lock both pull controls immediately. A second click during the reveal must
	# never spend another batch or race the result overlay.
	for button in _main.find_children("*", "Button", true, false):
		(button as Button).disabled = true
	await _summon_flow.pull(count)
	if not is_instance_valid(self) or not is_inside_tree():
		return
	_summon_busy = false
	_refresh()

func _play_summon_reveal(results: Array) -> void:
	if _summon_flow != null:
		await _summon_flow.play_summon_reveal(results)

func _show_results(results: Array) -> void:
	if _summon_flow != null:
		_summon_flow.show_results(results)

func presentation_report() -> Dictionary:
	return {
		"screen": "summon",
		"featured_id": _featured_id,
		"featured_premium": _featured_premium,
		"rarity_effects_enabled": true,
		"reveal_animations": _reveal_animations,
		"result_cards": _result_cards,
	}
