class_name QuestScreen
extends OverlayScreen
## Quest journal: active, available and completed stories with step-by-step
## progress and a tracked quest shown on the HUD.

var _list: VBoxContainer
var _detail: VBoxContainer
var _selected_quest: String = ""
var _cards: Dictionary = {}


func _init() -> void:
	screen_title = "Quest Journal"
	screen_subtitle = "The stories Greenward is still trying to tell"


func _build_content() -> void:
	var split := UIFactory.hbox(14)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(split)

	var left := UIFactory.vbox(10)
	left.custom_minimum_size = Vector2(380, 0)
	split.add_child(left)
	left.add_child(UIFactory.label("QUESTS", 10, UITheme.TEXT_FAINT))
	var scroll := UIFactory.scroll()
	left.add_child(scroll)
	_list = UIFactory.vbox(8)
	scroll.add_child(_list)

	var detail_panel := UIFactory.panel(Color("#0a101d"), UITheme.BORDER_SOFT, 12, 1, 12)
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(detail_panel)
	var detail_scroll := UIFactory.scroll()
	detail_panel.add_child(detail_scroll)
	_detail = UIFactory.vbox(10)
	detail_scroll.add_child(_detail)


func _refresh() -> void:
	_rebuild_list()


func _rebuild_list() -> void:
	if _list == null:
		return
	UIFactory.clear(_list)
	_cards.clear()
	var quest_ids: Array = ContentDB.quests.keys()
	quest_ids.sort_custom(func(a, b) -> bool:
		var state_a := GameState.quest_state(a)
		var state_b := GameState.quest_state(b)
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
	var state := GameState.quest_state(quest_id)
	var state_color := UITheme.GOLD if state == "active" else (UITheme.GREEN if state == "complete" else UITheme.TEXT_DIM)
	var card := UIFactory.panel(Color("#111a2d"), UITheme.BORDER_SOFT, 10, 1, 10)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var box := UIFactory.vbox(4)
	card.add_child(box)
	var header := UIFactory.hbox(8)
	header.add_child(UIFactory.label(str(quest.get("name", quest_id)), 14, UITheme.TEXT))
	header.add_child(UIFactory.spacer())
	header.add_child(UIFactory.chip(state.replace("_", " ").capitalize(), state_color))
	box.add_child(header)
	var step: Dictionary = GameState.quest_step(quest_id)
	var step_text := str(step.get("text", "Complete" if state == "complete" else "Speak with the quest giver"))
	box.add_child(UIFactory.wrapped(step_text, 11, UITheme.TEXT_DIM))
	if str(GameState.flags.get("tracked_quest", "")) == quest_id:
		box.add_child(UIFactory.label("◆ TRACKED", 9, UITheme.GOLD))

	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_selected_quest = quest_id
			_rebuild_list()
			_show_detail(quest_id)
	)
	_cards[quest_id] = card
	if quest_id == _selected_quest:
		card.add_theme_stylebox_override("panel", UITheme.style(Color("#1a2947"), state_color, 10, 2, 10))
	return card


func _show_detail(quest_id: String) -> void:
	UIFactory.clear(_detail)
	if quest_id.is_empty():
		_detail.add_child(UIFactory.label("No quest selected.", 13, UITheme.TEXT_DIM))
		return
	var quest: Dictionary = ContentDB.get_quest(quest_id)
	if quest.is_empty():
		_detail.add_child(UIFactory.label("Unknown quest.", 13, UITheme.DANGER))
		return
	var state := GameState.quest_state(quest_id)
	var state_color := UITheme.GOLD if state == "active" else (UITheme.GREEN if state == "complete" else UITheme.TEXT_DIM)

	_detail.add_child(UIFactory.heading(str(quest.get("name", quest_id)), 24, UITheme.TEXT))
	var chips := UIFactory.hbox(6)
	chips.add_child(UIFactory.chip(state.replace("_", " ").capitalize(), state_color))
	chips.add_child(UIFactory.chip(str(quest.get("region", "greenward")).capitalize(), UITheme.TEAL))
	_detail.add_child(chips)
	_detail.add_child(UIFactory.wrapped(str(quest.get("summary", "")), 13, UITheme.TEXT_DIM))
	_detail.add_child(UIFactory.separator())

	_detail.add_child(UIFactory.label("OBJECTIVES", 10, UITheme.TEXT_FAINT))
	var steps: Array = quest.get("steps", [])
	var current := GameState.quest_step_index(quest_id)
	for index in steps.size():
		var step: Dictionary = steps[index]
		var done := state == "complete" or index < current
		var active := state == "active" and index == current
		var marker := "✓" if done else ("◆" if active else "○")
		var color := UITheme.GREEN if done else (UITheme.GOLD if active else UITheme.TEXT_FAINT)
		var row := UIFactory.hbox(8)
		row.add_child(UIFactory.label(marker, 14, color))
		var text := str(step.get("text", "Objective"))
		if str(step.get("type", "")) == "kill":
			var entry: Dictionary = GameState.quests.get(quest_id, {})
			var progress := int(entry.get("progress", 0)) if active else (int(step.get("count", 1)) if done else 0)
			text += "  (%d/%d)" % [progress, int(step.get("count", 1))]
		var label := UIFactory.wrapped(text, 12, color if (done or active) else UITheme.TEXT_DIM)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		_detail.add_child(row)

	_detail.add_child(UIFactory.separator())
	_detail.add_child(UIFactory.label("REWARDS", 10, UITheme.TEXT_FAINT))
	var rewards: Dictionary = quest.get("rewards", {})
	var reward_row := UIFactory.hbox(8)
	if int(rewards.get("gold", 0)) > 0:
		reward_row.add_child(UIFactory.chip("%s Gold" % UIFactory.number(int(rewards.gold)), UITheme.GOLD))
	if int(rewards.get("crystals", 0)) > 0:
		reward_row.add_child(UIFactory.chip("%s Crystals" % UIFactory.number(int(rewards.crystals)), UITheme.TEAL))
	if int(rewards.get("xp", 0)) > 0:
		reward_row.add_child(UIFactory.chip("%s XP" % UIFactory.number(int(rewards.xp)), UITheme.GREEN))
	_detail.add_child(reward_row)
	for item_id in rewards.get("items", {}).keys():
		var item: Dictionary = ContentDB.get_item(str(item_id))
		_detail.add_child(UIFactory.label(
			"• %s ×%d — %s" % [str(item.get("name", item_id)), int(rewards["items"][item_id]), str(item.get("description", ""))],
			11,
			UITheme.TEXT_DIM
		))

	_detail.add_child(UIFactory.separator())
	var actions := UIFactory.hbox(8)
	var tracked := str(GameState.flags.get("tracked_quest", "")) == quest_id
	var track_button := UIFactory.button("Untrack" if tracked else "Track on HUD", not tracked)
	track_button.pressed.connect(func() -> void:
		if tracked:
			GameState.untrack_quest()
		else:
			GameState.set_tracked_quest(quest_id)
		_rebuild_list()
		_show_detail(quest_id)
	)
	actions.add_child(track_button)
	if state == "not_started":
		var requires := str(quest.get("requires", ""))
		if not requires.is_empty() and GameState.quest_state(requires) != "complete":
			actions.add_child(UIFactory.wrapped(
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
			actions.add_child(UIFactory.wrapped("Speak with %s to begin." % giver_name, 11, UITheme.TEXT_FAINT))
	elif state == "active" and GameState.quest_ready(quest_id):
		actions.add_child(UIFactory.wrapped("Ready to turn in. Return to the quest giver.", 11, UITheme.GREEN))
	_detail.add_child(actions)
