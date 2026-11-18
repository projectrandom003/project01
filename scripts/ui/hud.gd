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
var _responsive_layout_component: HUDResponsiveLayoutComponent
var _navigation_component: HUDNavigationComponent
var _prompt_component: HUDPromptComponent

## Shared quest navigation resolver injected by the owner (GameScreen).
## A single instance must be reused across consumers; HUD must not create its own.
var quest_resolver: QuestNavigationResolver = null

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
	_responsive_layout_component = get_node_or_null("ResponsiveLayout") as HUDResponsiveLayoutComponent
	_navigation_component = get_node_or_null("Navigation") as HUDNavigationComponent
	_prompt_component = get_node_or_null("Prompt") as HUDPromptComponent
	if _currency_component == null or _party_component == null or _quest_component == null or _toast_component == null or _responsive_layout_component == null or _navigation_component == null or _prompt_component == null:
		push_error("HUD requires its authored presentation, responsive-layout, navigation and prompt component children.")
		return false
	_currency_component.bind(self)
	_party_component.bind(self)
	_quest_component.bind(self)
	_toast_component.bind(self)
	_responsive_layout_component.bind(self)
	_navigation_component.bind(self)
	_prompt_component.bind(self)
	_navigation_component.configure()
	return true

func _apply_responsive_layout(viewport_size: Vector2 = Vector2.ZERO) -> void:
	if _responsive_layout_component != null:
		_responsive_layout_component.apply(viewport_size)


func set_quest_resolver(resolver: QuestNavigationResolver) -> void:
	quest_resolver = resolver
	if _minimap != null:
		_minimap.quest_resolver = resolver
	refresh_quest()


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
