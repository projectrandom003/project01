class_name MainMenu
extends Control
## Composition root. Presentation, routing and overlay ownership live in child nodes.

signal play_requested
signal quit_requested

@onready var navigation: MainMenuNavigationComponent = $Navigation
@onready var skin: MainMenuSkinComponent = $Skin
@onready var overlays: MainMenuOverlayComponent = $Overlays
@onready var ravienna_line: Label = $RaviennaDialogue/DialogueMargin/DialogueContent/RaviennaLine

var ravienna_lines: Array[String] = [
	"The night is young. Shall we see what secrets it keeps?",
	"Careful, darling. Not every shadow is as harmless as it looks.",
	"I was beginning to think you had forgotten me.",
	"Come closer. I have a little story for you.",
	"The roses are beautiful tonight… almost as beautiful as the danger.",
	"Stay a while. The world can wait for us.",
	"Do you hear that? The castle is whispering again.",
	"I wonder what fate has written for us this time."
]
var ravienna_line_index := 0

func _ready() -> void:
	UIFactory.set_full_rect(self)
	theme = UITheme.build()
	_cycle_ravienna_dialogue()
	_fit_ravienna_dialogue()
	navigation.bind(self)
	skin.bind(self)
	overlays.bind(self)
	navigation.play_requested.connect(play_requested.emit)
	navigation.world_requested.connect(overlays.open_world_map)
	navigation.summon_requested.connect(overlays.open_summon)
	navigation.inventory_requested.connect(overlays.open_inventory)
	navigation.settings_requested.connect(overlays.open_settings)
	navigation.characters_requested.connect(overlays.open_characters)
	navigation.mail_requested.connect(_show_mail)
	navigation.events_requested.connect(_show_events)
	navigation.calendar_requested.connect(_show_calendar)
	navigation.gifts_requested.connect(_show_gifts)
	navigation.achievements_requested.connect(_show_achievements)
	navigation.messages_requested.connect(_show_messages)
	navigation.combat_requested.connect(_show_combat)
	navigation.castle_requested.connect(_show_castle)
	navigation.resources_requested.connect(_show_resources)
	navigation.crystals_requested.connect(_show_crystals)
	navigation.gold_requested.connect(_show_gold)

func _cycle_ravienna_dialogue() -> void:
	while is_inside_tree():
		await get_tree().create_timer(10.0).timeout
		if not is_inside_tree():
			return
		ravienna_line_index = (ravienna_line_index + 1) % ravienna_lines.size()
		ravienna_line.text = ravienna_lines[ravienna_line_index]
		_fit_ravienna_dialogue()

func _fit_ravienna_dialogue() -> void:
	if ravienna_line == null:
		return
	var length := ravienna_line.text.length()
	var font_size := 17
	if length > 105:
		font_size = 12
	elif length > 85:
		font_size = 13
	elif length > 65:
		font_size = 14
	elif length > 48:
		font_size = 15
	ravienna_line.add_theme_font_size_override("font_size", font_size)
	ravienna_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ravienna_line.clip_text = false

func _show_mail() -> void:
	overlays.show_notice("Mail", "Your messages and rewards will appear here.")

func _show_events() -> void:
	overlays.show_notice("Events", "Limited-time events will appear here.")

func _show_calendar() -> void:
	overlays.open_daily_rewards()

func _show_gifts() -> void:
	overlays.show_notice("Gifts", "Claimable gifts will appear here.")

func _show_achievements() -> void:
	overlays.show_notice("Achievements", "Your milestones and rewards will appear here.")

func _show_messages() -> void:
	overlays.show_notice("Messages", "Your conversations will appear here.")

func _show_combat() -> void:
	overlays.show_notice("Combat", "Enter the Story to begin your next encounter.")

func _show_castle() -> void:
	overlays.show_notice("Castle", "Your castle and royal gardens are waiting in the world.")

func _show_resources() -> void:
	overlays.show_notice("Resources", "Your gathered materials and currencies are shown here.")

func _show_crystals() -> void:
	overlays.show_notice("Crystals", "Premium currency balance and offers.")

func _show_gold() -> void:
	overlays.show_notice("Gold", "Your gold balance and spending options.")

func _on_quit() -> void:
	quit_requested.emit()
