class_name MainMenuNavigationComponent
extends Node
## Owns button-to-feature routing for the main hub. Emits intent; does not own the screen.

signal play_requested
signal world_requested
signal summon_requested
signal inventory_requested
signal settings_requested
signal mail_requested
signal events_requested
signal calendar_requested
signal gifts_requested
signal achievements_requested
signal messages_requested
signal characters_requested
signal combat_requested
signal castle_requested
signal resources_requested
signal crystals_requested
signal gold_requested

var menu: Control

func bind(owner: Control) -> void:
	menu = owner
	_connect("StoryButton", play_requested.emit, "ReferenceInterface/BottomNavigation")
	_connect("WorldButton", world_requested.emit, "ReferenceInterface/BottomNavigation")
	_connect("SummonButton", summon_requested.emit, "ReferenceInterface/BottomNavigation")
	_connect("InventoryButton", inventory_requested.emit, "ReferenceInterface/BottomNavigation")
	_connect("FeaturedBannerOne", summon_requested.emit, "ReferenceInterface/FeaturedBanners")
	_connect("FeaturedBannerTwo", summon_requested.emit, "ReferenceInterface/FeaturedBanners")
	_connect("SettingsShortcut", settings_requested.emit)
	_connect("MailButton", mail_requested.emit)
	_connect("EventsButton", events_requested.emit, "ReferenceInterface/LeftRail")
	_connect("CalendarButton", calendar_requested.emit, "ReferenceInterface/LeftRail")
	_connect("GiftsButton", gifts_requested.emit, "ReferenceInterface/LeftRail")
	_connect("AchievementsButton", achievements_requested.emit, "ReferenceInterface/LeftRail")
	_connect("CommunicationButton", messages_requested.emit, "ReferenceInterface/BottomNavigation")
	_connect("CharactersButton", characters_requested.emit, "ReferenceInterface/BottomNavigation")
	_connect("CombatButton", combat_requested.emit, "ReferenceInterface/BottomNavigation")
	_connect("CastleButton", castle_requested.emit, "ReferenceInterface/BottomNavigation")
	_connect("ResourcesButton", resources_requested.emit, "ReferenceInterface/BottomNavigation")
	_connect("PremiumCurrency", crystals_requested.emit, "ReferenceInterface/CurrencyBar")
	_connect("GoldCurrency", gold_requested.emit, "ReferenceInterface/CurrencyBar")
	_connect("ResourceCurrency", resources_requested.emit, "ReferenceInterface/CurrencyBar")

func _connect(node_name: String, callback: Callable, parent_path := "ReferenceInterface") -> void:
	var parent := menu.get_node_or_null(parent_path)
	if parent == null:
		return
	var button := parent.get_node_or_null(node_name) as Button
	if button != null and not button.pressed.is_connected(callback):
		button.pressed.connect(callback)
