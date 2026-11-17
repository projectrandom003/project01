class_name QuestScreen
extends OverlayScreen
## Quest journal: active, available and completed stories with step-by-step
## progress and a tracked quest shown on the HUD.

const QUEST_LAYOUT_SCENE: PackedScene = preload("res://scenes/ui/components/quest_screen_layout.tscn")
const QUEST_CARD_SCENE: PackedScene = preload("res://scenes/ui/components/quest_list_card.tscn")
const QUEST_OBJECTIVE_ROW_SCENE: PackedScene = preload("res://scenes/ui/components/quest_objective_row.tscn")

var _list: VBoxContainer
var _detail: VBoxContainer
var _detail_title: Label
var _detail_chips: HBoxContainer
var _detail_summary: Label
var _objectives: VBoxContainer
var _reward_chips: HBoxContainer
var _reward_items: VBoxContainer
var _detail_actions: HBoxContainer
var _selected_quest: String = ""
var _cards: Dictionary = {}


func _init() -> void:
	screen_title = "Quest Journal"
	screen_subtitle = "The stories Greenward is still trying to tell"


func _build_content() -> void:
	var layout := QUEST_LAYOUT_SCENE.instantiate() as HBoxContainer
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(layout)
	_list = layout.get_node("QuestListPanel/ListScroll/QuestList") as VBoxContainer
	_detail = layout.get_node("DetailPanel/DetailScroll/DetailContent") as VBoxContainer
	_detail_title = _detail.get_node("Title") as Label
	_detail_chips = _detail.get_node("StatusChips") as HBoxContainer
	_detail_summary = _detail.get_node("Summary") as Label
	_objectives = _detail.get_node("Objectives") as VBoxContainer
	_reward_chips = _detail.get_node("RewardChips") as HBoxContainer
	_reward_items = _detail.get_node("RewardItems") as VBoxContainer
	_detail_actions = _detail.get_node("Actions") as HBoxContainer


func _refresh() -> void:
	_rebuild_list()


func _rebuild_list() -> void:
	if _list == null:
		return
	UIFactory.clear(_list)
	_cards.clear()
	var quest_ids: Array = ContentDB.quests.keys()
	quest_ids.sort_custom(func(a, b) -> bool:
		var state_a := GameState.quest_domain.quest_state(a)
		var state_b := GameState.quest_domain.quest_state(b)
		var order := {"active": 0, "not_started": 1, "complete": 2}
		var rank_a := int(order.get(state_a, 3))
		var rank_b := int(order.get(state_b, 3))
		if rank_a == rank_b:
			return str(a) < str(b)
		return rank_a < rank_b
	)
	if quest_ids.is_empty():
		_list.add_child(UIFactory.label("No quests configured.", 13, UITheme.TEXT_DIM))
		_show_detail("")
		return
	if _selected_quest.is_empty() or not quest_ids.has(_selected_quest):
		_selected_quest = str(quest_ids[0])
	for quest_id in quest_ids:
		_list.add_child(_make_card(str(quest_id)))
	_show_detail(_selected_quest)


func _make_card(quest_id: String) -> PanelContainer:
	var quest: Dictionary = ContentDB.get_quest(quest_id)
	var state := GameState.quest_domain.quest_state(quest_id)
	var state_color := UITheme.GOLD if state == "active" else (UITheme.GREEN if state == "complete" else UITheme.TEXT_DIM)
	var step: Dictionary = GameState.quest_domain.quest_step(quest_id)
	var step_text := str(step.get("text", "Complete" if state == "complete" else "Speak with the quest giver"))
	var tracked := str(GameState.quest_domain.flags.get("tracked_quest", "")) == quest_id
	var card := QUEST_CARD_SCENE.instantiate() as QuestListCard
	card.setup(quest_id, str(quest.get("name", quest_id)), state.replace("_", " ").capitalize(), state_color, step_text, tracked)
	card.selected.connect(func(selected_id: String) -> void:
		_selected_quest = selected_id
		_rebuild_list()
		_show_detail(selected_id)
	)
	_cards[quest_id] = card
	if quest_id == _selected_quest:
		card.add_theme_stylebox_override("panel", UITheme.style(Color("#1a2947"), state_color, 10, 2, 10))
	return card


func _show_detail(quest_id: String) -> void:
	UIFactory.clear(_detail_chips)
	UIFactory.clear(_objectives)
	UIFactory.clear(_reward_chips)
	UIFactory.clear(_reward_items)
	UIFactory.clear(_detail_actions)
	_detail.visible = true
	if quest_id.is_empty():
		_detail_title.text = "No quest selected."
		_detail_title.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		_detail_chips.visible = false
		_detail_summary.visible = false
		_objectives.visible = false
		_reward_chips.visible = false
		_reward_items.visible = false
		_detail_actions.visible = false
		return
	var quest: Dictionary = ContentDB.get_quest(quest_id)
	if quest.is_empty():
		_detail_title.text = "Unknown quest."
		_detail_title.add_theme_color_override("font_color", UITheme.DANGER)
		_detail_chips.visible = false
		_detail_summary.visible = false
		_objectives.visible = false
		_reward_chips.visible = false
		_reward_items.visible = false
		_detail_actions.visible = false
		return

	var state := GameState.quest_domain.quest_state(quest_id)
	var state_color := UITheme.GOLD if state == "active" else (UITheme.GREEN if state == "complete" else UITheme.TEXT_DIM)
	_detail_title.text = str(quest.get("name", quest_id))
	_detail_title.add_theme_color_override("font_color", UITheme.TEXT)
	_detail_chips.visible = true
	_detail_summary.visible = true
	_objectives.visible = true
	_reward_chips.visible = true
	_reward_items.visible = true
	_detail_actions.visible = true
	_detail_chips.add_child(UIFactory.chip(state.replace("_", " ").capitalize(), state_color))
	_detail_chips.add_child(UIFactory.chip(str(quest.get("region", "greenward")).capitalize(), UITheme.TEAL))
	_detail_summary.text = str(quest.get("summary", ""))

	var steps: Array = quest.get("steps", [])
	var current := GameState.quest_domain.quest_step_index(quest_id)
	for index in steps.size():
		var step: Dictionary = steps[index]
		var done := state == "complete" or index < current
		var active := state == "active" and index == current
		var marker := "✓" if done else ("◆" if active else "○")
		var color := UITheme.GREEN if done else (UITheme.GOLD if active else UITheme.TEXT_FAINT)
		var objective_text := str(step.get("text", "Objective"))
		if str(step.get("type", "")) == "kill":
			var entry: Dictionary = GameState.quest_domain.quests.get(quest_id, {})
			var progress := int(entry.get("progress", 0)) if active else (int(step.get("count", 1)) if done else 0)
			objective_text += "  (%d/%d)" % [progress, int(step.get("count", 1))]
		var row := QUEST_OBJECTIVE_ROW_SCENE.instantiate() as QuestObjectiveRow
		row.setup(marker, objective_text, color if (done or active) else UITheme.TEXT_DIM)
		_objectives.add_child(row)

	var rewards: Dictionary = quest.get("rewards", {})
	if int(rewards.get("gold", 0)) > 0:
		_reward_chips.add_child(UIFactory.chip("%s Gold" % UIFactory.number(int(rewards.gold)), UITheme.GOLD))
	if int(rewards.get("crystals", 0)) > 0:
		_reward_chips.add_child(UIFactory.chip("%s Crystals" % UIFactory.number(int(rewards.crystals)), UITheme.TEAL))
	if int(rewards.get("xp", 0)) > 0:
		_reward_chips.add_child(UIFactory.chip("%s XP" % UIFactory.number(int(rewards.xp)), UITheme.GREEN))
	for item_id in rewards.get("items", {}).keys():
		var item: Dictionary = ContentDB.get_item(str(item_id))
		_reward_items.add_child(UIFactory.label(
			"• %s ×%d — %s" % [str(item.get("name", item_id)), int(rewards["items"][item_id]), str(item.get("description", ""))],
			11,
			UITheme.TEXT_DIM
		))

	var tracked := str(GameState.quest_domain.flags.get("tracked_quest", "")) == quest_id
	var track_button := UIFactory.button("Untrack" if tracked else "Track on HUD", not tracked)
	track_button.pressed.connect(func() -> void:
		if tracked:
			GameState.quest_domain.untrack_quest()
		else:
			GameState.quest_domain.set_tracked_quest(quest_id)
		_rebuild_list()
		_show_detail(quest_id)
	)
	_detail_actions.add_child(track_button)
	if state == "not_started":
		var requires := str(quest.get("requires", ""))
		if not requires.is_empty() and GameState.quest_domain.quest_state(requires) != "complete":
			_detail_actions.add_child(UIFactory.wrapped(
				"Complete \"%s\" first." % str(ContentDB.get_quest(requires).get("name", requires)),
				11,
				UITheme.TEXT_FAINT
			))
		else:
			var first_step: Dictionary = steps[0] if not steps.is_empty() else {}
			var giver_id := str(first_step.get("target", ""))
			var giver_name := giver_id.replace("_", " ").capitalize()
			match giver_id:
				"elder_maelin":
					giver_name = "Elder Maelin"
				"merchant_sera":
					giver_name = "Sera Quill"
				"wanderer_pip":
					giver_name = "Pip"
			_detail_actions.add_child(UIFactory.wrapped("Speak with %s to begin." % giver_name, 11, UITheme.TEXT_FAINT))
	elif state == "active" and GameState.quest_domain.quest_ready(quest_id):
		_detail_actions.add_child(UIFactory.wrapped("Ready to turn in. Return to the quest giver.", 11, UITheme.GREEN))
