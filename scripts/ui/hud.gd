class_name HUD
extends Control
## Always-on heads-up display: location, currencies, party, quest tracker,
## interaction prompt, touch controls and the main navigation buttons.
##
## The HUD is presentation only. It emits intent signals; GameScreen decides
## what to open and when to pause the world.

signal screen_requested(screen_id: String)
signal menu_requested
signal return_to_title_requested
signal interact_requested
signal switch_avatar_requested

const PARTY_ENTRY_SCENE: PackedScene = preload("res://scenes/ui/components/hud_party_entry.tscn")
const CURRENCY_CHIP_SCENE: PackedScene = preload("res://scenes/ui/components/currency_chip.tscn")

var joystick: TouchJoystick
var _area_label: Label
var _phase_label: Label
var _quest_label: Label
var _currency_box: HBoxContainer
var _party_box: VBoxContainer
var _party_empty_label: Label
var _prompt_panel: PanelContainer
var _prompt_label: Label
var _toast_box: VBoxContainer
var _touch_interact: Button
var _touch_switch: Button
var _hint_label: Label
var _minimap: Minimap
var _currency_component: HUDCurrencyComponent
var _party_component: HUDPartyComponent
var _quest_component: HUDQuestComponent
var _toast_component: HUDToastComponent

## Shared quest navigation resolver injected by the owner (GameScreen).
## A single instance must be reused across consumers; HUD must not create its own.
var quest_resolver: QuestNavigationResolver = null

var _prompt_timer: float = 0.0
var _refresh_timer: float = 0.0
var _last_prompt: String = ""
var _toasts: Array = []


func _ready() -> void:
	UIFactory.set_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.build()
	if not _bind_authored_ui():
		return
	if not _bind_components():
		return

	EventBus.currency_changed.connect(refresh_currency)
	EventBus.party_changed.connect(refresh_party)
	EventBus.roster_changed.connect(refresh_party)
	EventBus.quest_updated.connect(_on_quest_updated)
	EventBus.toast_requested.connect(show_toast)

	refresh_currency()
	refresh_party()
	refresh_quest()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()


func _bind_components() -> bool:
	_currency_component = get_node_or_null("Currency") as HUDCurrencyComponent
	_party_component = get_node_or_null("Party") as HUDPartyComponent
	_quest_component = get_node_or_null("Quest") as HUDQuestComponent
	_toast_component = get_node_or_null("Toast") as HUDToastComponent
	if _currency_component == null or _party_component == null or _quest_component == null or _toast_component == null:
		push_error("HUD requires authored Currency, Party, Quest and Toast component children.")
		return false
	_currency_component.bind(self)
	_party_component.bind(self)
	_quest_component.bind(self)
	_toast_component.bind(self)
	return true

func _apply_responsive_layout(viewport_size: Vector2 = Vector2.ZERO) -> void:
	if not is_inside_tree():
		return
	if viewport_size == Vector2.ZERO:
		viewport_size = get_viewport_rect().size
	var compact_portrait := viewport_size.x < 540.0 and viewport_size.y > viewport_size.x
	var party_panel := get_node_or_null("PartyPanel") as Control
	if party_panel != null:
		party_panel.visible = not compact_portrait
	if _hint_label != null:
		_hint_label.visible = not compact_portrait
	if _minimap != null:
		if compact_portrait:
			_minimap.offset_left = -188.0
			_minimap.offset_top = 90.0
			_minimap.offset_right = -18.0
			_minimap.offset_bottom = 260.0
		else:
			_minimap.offset_left = -244.0
			_minimap.offset_top = 90.0
			_minimap.offset_right = -20.0
			_minimap.offset_bottom = 314.0
	var prompt_center := get_node_or_null("PromptCenter") as Control
	if prompt_center != null:
		if compact_portrait:
			prompt_center.offset_top = -viewport_size.y * 0.62
			prompt_center.offset_bottom = -viewport_size.y * 0.54
		else:
			prompt_center.offset_top = -104.0
			prompt_center.offset_bottom = -34.0


func set_quest_resolver(resolver: QuestNavigationResolver) -> void:
	quest_resolver = resolver
	if _minimap != null:
		_minimap.quest_resolver = resolver
	refresh_quest()


func _process(delta: float) -> void:
	_prompt_timer += delta
	_refresh_timer += delta
	if _refresh_timer >= 0.5:
		_refresh_timer = 0.0
		refresh_quest()
	if _prompt_timer < 0.12:
		return
	_prompt_timer = 0.0
	var prompt := ""
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("current_prompt"):
		var text: String = player.current_prompt()
		if not text.is_empty():
			var target := "target"
			if player.nearby_interactable != null and "display_name" in player.nearby_interactable:
				target = str(player.nearby_interactable.display_name)
			prompt = "[E]  %s  %s" % [text, target]
	if prompt != _last_prompt:
		_last_prompt = prompt
		_prompt_label.text = prompt
		_prompt_panel.visible = not prompt.is_empty()
		if _touch_interact != null:
			_touch_interact.visible = TouchInput.using_touch and not prompt.is_empty()


func set_world_info(area_name: String, phase_name: String) -> void:
	if _area_label.text != area_name:
		_area_label.text = area_name
	if _phase_label.text != phase_name:
		_phase_label.text = phase_name


func refresh_currency() -> void:
	if _currency_component != null:
		_currency_component.refresh_currency()

func _add_currency_chip(value_text: String, tint: Color) -> void:
	if _currency_component != null:
		_currency_component.add_currency_chip(value_text, tint)

func refresh_party() -> void:
	if _party_component != null:
		_party_component.refresh_party()

func refresh_quest() -> void:
	if _quest_component != null:
		_quest_component.refresh_quest()

func _quest_arrow(dir: Variant = null) -> String:
	return _quest_component.quest_arrow(dir) if _quest_component != null else "•"

func show_toast(message: String) -> void:
	if _toast_component != null:
		_toast_component.show_toast(message)

func _on_quest_updated(_quest_id: String) -> void:
	refresh_quest()


func _confirm_return_to_title() -> void:
	var confirmation := ConfirmationDialog.new()
	confirmation.title = "Return to Main Menu?"
	confirmation.dialog_text = "Your current journey will be saved before returning to the title screen."
	confirmation.ok_button_text = "Save & Return"
	confirmation.cancel_button_text = "Stay in World"
	confirmation.confirmed.connect(func() -> void:
		return_to_title_requested.emit()
		confirmation.queue_free()
	)
	confirmation.canceled.connect(confirmation.queue_free)
	add_child(confirmation)
	confirmation.popup_centered()


func _style_navigation_button(button: Button, accent: Color, primary: bool = false) -> void:
	button.custom_minimum_size = Vector2(138.0, 40.0)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("#e9e5f0"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", accent.lightened(0.22))
	button.add_theme_color_override("font_disabled_color", UITheme.TEXT_FAINT)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_stylebox_override("normal", UITheme.style(Color("#090d19").lerp(accent, 0.055 if primary else 0.025), Color(accent.r, accent.g, accent.b, 0.68), 9, 1, 12, true))
	button.add_theme_stylebox_override("hover", UITheme.style(Color("#1a2034").lerp(accent, 0.12), accent.lightened(0.16), 9, 2, 12, true))
	button.add_theme_stylebox_override("pressed", UITheme.style(Color("#080b15").lerp(accent, 0.16), accent, 9, 2, 12))
	button.add_theme_stylebox_override("disabled", UITheme.style(Color("#0b0e18"), UITheme.BORDER_SOFT, 9, 1, 12))
	button.add_theme_stylebox_override("focus", UITheme.style(Color("#171b2b"), UITheme.GOLD_BRIGHT, 9, 2, 12, true))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


# ----------------------------------------------------------- authored bindings

func _bind_authored_ui() -> bool:
	_area_label = get_node_or_null("TopBar/TopRow/LocationInfo/AreaLabel") as Label
	_phase_label = get_node_or_null("TopBar/TopRow/LocationInfo/PhaseLabel") as Label
	_quest_label = get_node_or_null("TopBar/TopRow/LocationInfo/QuestLabel") as Label
	_currency_box = get_node_or_null("TopBar/TopRow/CurrencyBox") as HBoxContainer
	_party_box = get_node_or_null("PartyPanel/PartyContent/PartyBox") as VBoxContainer
	_party_empty_label = get_node_or_null("PartyPanel/PartyContent/PartyBox/NoPartyLabel") as Label
	_minimap = get_node_or_null("Minimap") as Minimap
	_prompt_panel = get_node_or_null("PromptCenter/PromptPanel") as PanelContainer
	_prompt_label = get_node_or_null("PromptCenter/PromptPanel/PromptLabel") as Label
	_toast_box = get_node_or_null("ToastBox") as VBoxContainer
	joystick = get_node_or_null("Joystick") as TouchJoystick
	_touch_interact = get_node_or_null("TouchInteractButton") as Button
	_touch_switch = get_node_or_null("TouchSwitchButton") as Button
	_hint_label = get_node_or_null("HintLabel") as Label

	if _quest_label == null:
		push_error("HUD requires its authored QuestLabel.")
		return false

	if _minimap != null:
		_minimap.quest_resolver = quest_resolver
	var summon_btn := get_node_or_null("ActionStack/SummonButton") as Button
	if summon_btn:
		summon_btn.text = "✦  SUMMON"
		_style_navigation_button(summon_btn, UITheme.GOLD_BRIGHT, true)
		summon_btn.pressed.connect(func() -> void: screen_requested.emit("gacha"))
	var roster_btn := get_node_or_null("ActionStack/RosterButton") as Button
	if roster_btn:
		roster_btn.text = "♜  ROSTER"
		_style_navigation_button(roster_btn, UITheme.VIOLET)
		roster_btn.pressed.connect(func() -> void: screen_requested.emit("collection"))
	var inv_btn := get_node_or_null("ActionStack/InventoryButton") as Button
	if inv_btn:
		inv_btn.text = "▤  INVENTORY"
		_style_navigation_button(inv_btn, UITheme.TEAL)
		inv_btn.pressed.connect(func() -> void: screen_requested.emit("inventory"))
	var quests_btn := get_node_or_null("ActionStack/QuestsButton") as Button
	if quests_btn:
		quests_btn.text = "✧  QUESTS"
		_style_navigation_button(quests_btn, UITheme.GOLD)
		quests_btn.pressed.connect(func() -> void: screen_requested.emit("quests"))
	var map_btn := get_node_or_null("ActionStack/MapButton") as Button
	if map_btn:
		map_btn.text = "⌖  WORLD MAP"
		_style_navigation_button(map_btn, UITheme.TEAL_DIM)
		map_btn.pressed.connect(func() -> void: screen_requested.emit("map"))
	var menu_btn := get_node_or_null("ActionStack/MenuButton") as Button
	if menu_btn:
		menu_btn.text = "☰  MENU"
		_style_navigation_button(menu_btn, UITheme.DANGER)
		menu_btn.pressed.connect(func() -> void: menu_requested.emit())
	var main_menu_btn := get_node_or_null("TopBar/TopRow/MainMenuButton") as Button
	if main_menu_btn:
		_style_navigation_button(main_menu_btn, UITheme.GOLD_BRIGHT, true)
		main_menu_btn.custom_minimum_size = Vector2(132, 42)
		main_menu_btn.tooltip_text = "Save your journey and return to the title screen"
		main_menu_btn.pressed.connect(_confirm_return_to_title)
	if _touch_interact:
		_touch_interact.pressed.connect(func() -> void: interact_requested.emit())
	if _touch_switch:
		_touch_switch.pressed.connect(func() -> void: switch_avatar_requested.emit())

	if joystick:
		joystick.visible = TouchInput.using_touch
	if _touch_switch:
		_touch_switch.visible = TouchInput.using_touch
	if _touch_interact:
		_touch_interact.visible = false
	return true
