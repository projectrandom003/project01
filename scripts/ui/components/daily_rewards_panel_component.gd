class_name DailyRewardsPanelComponent
extends PanelContainer
## Presents the seven-day reward cycle and delegates claims to GameState.

@onready var cycle_label: Label = $Body/CycleLabel
@onready var reward_list: VBoxContainer = $Body/RewardList
@onready var claim_button: Button = $Body/ClaimButton
@onready var close_button: Button = $Body/CloseButton


func _ready() -> void:
	add_theme_stylebox_override("panel", UITheme.style(Color("#111522"), Color("#9b8059"), 12, 2, 18))
	claim_button.pressed.connect(_claim)
	close_button.pressed.connect(queue_free)
	_refresh()


func _refresh() -> void:
	UIFactory.clear(reward_list)
	var status := GameState.daily_reward_status()
	var current_day := int(status.get("day", 1))
	var last_claimed := int(GameState.daily_rewards.get("last_claimed_day", 0))
	cycle_label.text = "DAY %d OF 7" % current_day
	for index in range(GameRewardDomainComponent.DAILY_REWARDS.size()):
		var day := index + 1
		var reward: Dictionary = GameRewardDomainComponent.DAILY_REWARDS[index]
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 42)
		var accent := Color("#c5a66a") if day == 7 else Color("#58647d")
		row.add_theme_stylebox_override("panel", UITheme.style(Color("#1a2030"), accent, 7, 1, 8))
		reward_list.add_child(row)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		row.add_child(line)
		var day_label := UIFactory.label("DAY %d" % day, 13, UITheme.GOLD_BRIGHT)
		day_label.custom_minimum_size.x = 78
		line.add_child(day_label)
		var reward_label := UIFactory.label(_reward_text(reward), 13, UITheme.TEXT)
		reward_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(reward_label)
		var state_text := "CLAIMED" if day < current_day or (day == last_claimed and not bool(status.can_claim)) else ("TODAY" if day == current_day else ("GRAND GIFT" if day == 7 else ""))
		var state_label := UIFactory.label(state_text, 11, UITheme.GOLD if day == current_day else UITheme.TEXT_DIM)
		line.add_child(state_label)
	claim_button.disabled = not bool(status.get("can_claim", false))
	claim_button.text = "CLAIM TODAY'S REWARD" if not claim_button.disabled else "ALREADY CLAIMED TODAY"


func _reward_text(reward: Dictionary) -> String:
	var parts: PackedStringArray = []
	if reward.has("gold"):
		parts.append("%d Gold" % int(reward.gold))
	if reward.has("crystals"):
		parts.append("%d Crystals" % int(reward.crystals))
	if reward.has("ancient_coins"):
		parts.append("%d Ancient Coins" % int(reward.ancient_coins))
	for item_id in reward.get("items", {}):
		var item: Dictionary = ContentDB.get_item(str(item_id))
		parts.append("%d %s" % [int(reward.items[item_id]), str(item.get("name", item_id))])
	return " + ".join(parts)


func _claim() -> void:
	var result := GameState.claim_daily_reward()
	if bool(result.get("ok", false)):
		EventBus.toast_requested.emit("Daily reward claimed!")
	else:
		EventBus.toast_requested.emit(str(result.get("reason", "Unable to claim reward.")))
	_refresh()
