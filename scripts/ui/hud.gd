class_name HUD
extends Control
## Always-on heads-up display: location, currencies, party, quest tracker,
## interaction prompt, touch controls and the main navigation buttons.
##
## The HUD is presentation only. It emits intent signals; GameScreen decides
## what to open and when to pause the world.

signal screen_requested(screen_id: String)
signal menu_requested
signal interact_requested
signal switch_avatar_requested

var joystick: TouchJoystick
var _area_label: Label
var _phase_label: Label
var _quest_label: Label
var _currency_box: HBoxContainer
var _party_box: VBoxContainer
var _prompt_panel: PanelContainer
var _prompt_label: Label
var _toast_box: VBoxContainer
var _touch_interact: Button
var _touch_switch: Button
var _hint_label: Label
var _minimap: Minimap

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
	_bind_authored_ui()

	EventBus.currency_changed.connect(refresh_currency)
	EventBus.party_changed.connect(refresh_party)
	EventBus.roster_changed.connect(refresh_party)
	EventBus.quest_updated.connect(_on_quest_updated)
	EventBus.toast_requested.connect(show_toast)

	refresh_currency()
	refresh_party()
	refresh_quest()


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
	if _currency_box == null:
		return
	UIFactory.clear(_currency_box)
	_currency_box.add_child(UIFactory.chip("Gold  " + UIFactory.number(GameState.currency("gold")), UITheme.GOLD))
	_currency_box.add_child(UIFactory.chip("Crystals  " + UIFactory.number(GameState.currency("crystals")), UITheme.TEAL))
	if GameState.currency("gems") > 0:
		_currency_box.add_child(UIFactory.chip("Gems  " + UIFactory.number(GameState.currency("gems")), UITheme.VIOLET))


func refresh_party() -> void:
	if _party_box == null:
		return
	UIFactory.clear(_party_box)
	var instances := GameState.party_instances()
	if instances.is_empty():
		_party_box.add_child(UIFactory.label("No party formed", 13, UITheme.TEXT_FAINT))
		return
	for instance in instances:
		var definition: CharacterDef = ContentDB.get_character(instance.char_id)
		if definition == null:
			continue
		var row := UIFactory.hbox(8)
		var portrait := PortraitView.new()
		portrait.custom_minimum_size = Vector2(42, 42)
		portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		portrait.setup_character(definition)
		row.add_child(portrait)
		var text := UIFactory.vbox(1)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(UIFactory.label(definition.display_name, 13, UITheme.TEXT))
		text.add_child(UIFactory.label(
			"Lv %d  ·  %s" % [instance.level, definition.role],
			11,
			UITheme.TEXT_DIM
		))
		row.add_child(text)
		var element_dot := ColorRect.new()
		element_dot.color = UITheme.element_color(definition.element)
		element_dot.custom_minimum_size = Vector2(6, 6)
		element_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(element_dot)
		_party_box.add_child(row)


func refresh_quest() -> void:
	if _quest_label == null:
		return
	var tracked := GameState.tracked_quest()
	if tracked.is_empty():
		_quest_label.visible = false
		return
	var definition: Dictionary = ContentDB.get_quest(tracked)
	if definition.is_empty():
		_quest_label.visible = false
		return
	var state := GameState.quest_state(tracked)
	var step: Dictionary = GameState.quest_step(tracked)
	if state == "complete":
		_quest_label.text = "◆  %s — Complete" % str(definition.get("name", tracked))
		_quest_label.visible = true
		return
	if state == "not_started":
		var available_text := "Available · " + str(step.get("text", "Quest available"))
		_quest_label.text = "◆  %s — %s" % [str(definition.get("name", tracked)), available_text]
		_quest_label.visible = true
		return

	var resolver: QuestNavigationResolver = quest_resolver if quest_resolver != null else QuestNavigationResolver.shared()
	var resolved: Dictionary = resolver.get_resolved_target()
	var step_text := str(resolved.get("step_text", step.get("text", "")))
	var suffix := ""
	if str(resolved.get("status", "")) == QuestNavigationResolver.STATUS_UNREACHABLE:
		suffix = "  · Unreachable"
	elif not bool(resolved.get("same_frame", false)):
		# Cross-region: travel guidance to next connection only (no fake distance/arrow).
		var next_hop: Dictionary = resolved.get("next_hop", {})
		var route: Array = resolved.get("route", [])
		if not route.is_empty() and not next_hop.is_empty():
			var hop_to := str(next_hop.get("to", str(resolved.get("target_region_id", ""))))
			var hop_label := str(next_hop.get("label", ""))
			var travel := hop_label if not hop_label.is_empty() else ("Travel to %s" % hop_to)
			suffix = "  · %s" % travel
		else:
			suffix = "  · Travel to %s" % str(resolved.get("target_region_id", "destination"))
	else:
		# Same-region objective: meaningful local distance and direction.
		var dist_val: Variant = resolved.get("distance", null)
		if dist_val != null:
			var dist := float(dist_val)
			if dist > 1.0:
				var dir_val: Variant = resolved.get("direction", Vector2.ZERO)
				var arrow := _quest_arrow(dir_val if typeof(dir_val) == TYPE_VECTOR2 else Vector2.ZERO)
				suffix = "  (%s %.0f tiles)" % [arrow, dist / IsoMath.TILE_W]
	_quest_label.text = "◆  %s — %s%s" % [str(definition.get("name", tracked)), step_text, suffix]
	_quest_label.visible = true


func _quest_arrow(dir: Variant = null) -> String:
	# Returns a coarse 8-direction arrow toward the given/resolved direction.
	if dir == null or typeof(dir) != TYPE_VECTOR2:
		dir = Vector2.ZERO
	if (dir as Vector2).length_squared() < 0.0001:
		return "•"
	var angle := (dir as Vector2).angle()
	if angle < 0.0:
		angle += TAU
	var sector := int(round(angle / (PI * 0.25))) % 8
	var arrows := ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"]
	return arrows[sector]


func show_toast(message: String) -> void:
	if _toast_box == null:
		return
	while _toasts.size() >= 3:
		var oldest: Control = _toasts.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	var panel := UIFactory.panel(Color("#141c30"), Color(UITheme.GOLD.r, UITheme.GOLD.g, UITheme.GOLD.b, 0.55), 10, 1, 10, true)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var text := UIFactory.wrapped(message, 13, UITheme.TEXT)
	text.custom_minimum_size = Vector2(320, 0)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(text)
	_toast_box.add_child(panel)
	_toasts.append(panel)
	panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.tween_interval(3.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func() -> void:
		if is_instance_valid(panel):
			_toasts.erase(panel)
			panel.queue_free()
	)


func _on_quest_updated(_quest_id: String) -> void:
	refresh_quest()


# ----------------------------------------------------------- authored bindings

func _bind_authored_ui() -> void:
	_area_label = get_node("TopBar/TopRow/LocationInfo/AreaLabel") as Label
	_phase_label = get_node("TopBar/TopRow/LocationInfo/PhaseLabel") as Label
	_quest_label = get_node("TopBar/TopRow/LocationInfo/QuestLabel") as Label
	_currency_box = get_node("TopBar/TopRow/CurrencyBox") as HBoxContainer
	_party_box = get_node("PartyPanel/PartyContent/PartyBox") as VBoxContainer
	_minimap = get_node("Minimap") as Minimap
	_prompt_panel = get_node("PromptCenter/PromptPanel") as PanelContainer
	_prompt_label = get_node("PromptCenter/PromptPanel/PromptLabel") as Label
	_toast_box = get_node("ToastBox") as VBoxContainer
	joystick = get_node("Joystick") as TouchJoystick
	_touch_interact = get_node("TouchInteractButton") as Button
	_touch_switch = get_node("TouchSwitchButton") as Button
	_hint_label = get_node("HintLabel") as Label

	_minimap.quest_resolver = quest_resolver
	get_node("ActionStack/SummonButton").pressed.connect(func() -> void: screen_requested.emit("gacha"))
	get_node("ActionStack/RosterButton").pressed.connect(func() -> void: screen_requested.emit("collection"))
	get_node("ActionStack/InventoryButton").pressed.connect(func() -> void: screen_requested.emit("inventory"))
	get_node("ActionStack/QuestsButton").pressed.connect(func() -> void: screen_requested.emit("quests"))
	get_node("ActionStack/MapButton").pressed.connect(func() -> void: screen_requested.emit("map"))
	get_node("ActionStack/MenuButton").pressed.connect(func() -> void: menu_requested.emit())
	_touch_interact.pressed.connect(func() -> void: interact_requested.emit())
	_touch_switch.pressed.connect(func() -> void: switch_avatar_requested.emit())

	joystick.visible = TouchInput.using_touch
	_touch_switch.visible = TouchInput.using_touch
	_touch_interact.visible = false
