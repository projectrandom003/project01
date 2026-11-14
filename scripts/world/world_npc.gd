class_name WorldNPC
extends Interactable
## A named, talkable world character. Dialogue content is fully data-driven.
##
## Phase 3 / Step 5 presentation: a role/title subtitle under the name label, a
## soft pulsing interaction ring/plate, GreenwardStyle label colours, a gentle
## IDLE animator, and an INTERACT one-shot when talked to. The dialogue flow is
## UNCHANGED: interact() still emits EventBus.dialogue_requested(dialogue_id).

var npc_id: String = ""
var display_name: String = ""
var dialogue_id: String = ""
var role: String = ""
var palette: Dictionary = {}
var race: String = "Human"
var visual: ActorVisual
var _name_label: Label
var _subtitle_label: Label
var _interaction_ring: Node2D
var _quest_marker: Node2D
var _quest_marker_glow: Polygon2D
var _quest_marker_core: Polygon2D
var _quest_marker_symbol: Label
var _time: float = 0.0
var _quest_marker_state: String = ""
var quest_marker_y: float = -105.0


func setup(p_id: String, p_name: String, p_dialogue: String, p_palette: Dictionary, p_race: String) -> void:
	npc_id = p_id
	display_name = p_name
	dialogue_id = p_dialogue
	palette = p_palette
	race = p_race
	prompt = "Talk"


func _ready() -> void:
	super._ready()  # adds to the "interactables" group
	interaction_radius = 92.0
	if role.is_empty():
		role = _derive_role()

	visual = get_node_or_null("ActorVisual") as ActorVisual
	if visual == null:
		visual = ActorVisual.new() # compatibility for direct test instantiation
		visual.name = "ActorVisual"
		add_child(visual)
	_interaction_ring = get_node_or_null("InteractionRing") as Node2D
	_quest_marker = get_node_or_null("QuestMarker") as Node2D
	if _quest_marker != null:
		_quest_marker.position = Vector2(0.0, quest_marker_y)
		_quest_marker_glow = _quest_marker.get_node_or_null("Glow") as Polygon2D
		_quest_marker_core = _quest_marker.get_node_or_null("Core") as Polygon2D
		_quest_marker_symbol = _quest_marker.get_node_or_null("Symbol") as Label
	visual.setup(palette, ActorVisual.Kind.HUMAN, npc_id, race, "neutral")
	# PART 4: exercise the SpriteFramesActorSource registration seam. With no
	# disk sheets present this keeps the ProceduralActorFrames fallback active.
	visual.configure_character(npc_id)
	# Drive a gentle IDLE animator from the very first frame.
	visual.play(0)  # CharacterAnimator.State.IDLE == 0
	if visual.animator != null:
		visual.animator.speed_scale = 0.85

	# Name label (warm gold from GreenwardStyle).
	_name_label = get_node_or_null("NameLabel") as Label
	if _name_label == null:
		_name_label = Label.new()
		_name_label.name = "NameLabel"
		_name_label.position = Vector2(-70, -82)
		_name_label.size = Vector2(140, 22)
		add_child(_name_label)
	_name_label.text = display_name
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", GreenwardStyle.UI.gold)
	_name_label.add_theme_color_override("font_outline_color", GreenwardStyle.INK)
	_name_label.add_theme_constant_override("outline_size", 4)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Subtle role / title subtitle beneath the name.
	_subtitle_label = get_node_or_null("SubtitleLabel") as Label
	if _subtitle_label == null:
		_subtitle_label = Label.new()
		_subtitle_label.name = "SubtitleLabel"
		_subtitle_label.position = Vector2(-80, -62)
		_subtitle_label.size = Vector2(160, 16)
		add_child(_subtitle_label)
	_subtitle_label.text = role
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 9)
	var dim := GreenwardStyle.UI.text
	_subtitle_label.add_theme_color_override("font_color", Color(dim.r, dim.g, dim.b, 0.75))
	_subtitle_label.add_theme_color_override("font_outline_color", GreenwardStyle.INK)
	_subtitle_label.add_theme_constant_override("outline_size", 3)
	_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	set_process(true)
	_refresh_quest_marker()
	if not EventBus.quest_updated.is_connected(_refresh_quest_marker):
		EventBus.quest_updated.connect(_refresh_quest_marker)


func _exit_tree() -> void:
	if EventBus.quest_updated.is_connected(_refresh_quest_marker):
		EventBus.quest_updated.disconnect(_refresh_quest_marker)


func _refresh_quest_marker(_quest_id: String = "") -> void:
	_quest_marker_state = GameState.quest_marker_for_npc(npc_id)
	if _quest_marker == null:
		return
	_quest_marker.visible = not _quest_marker_state.is_empty()
	if _quest_marker_state.is_empty():
		return
	var marker_color := Color("#e9c66d")
	var symbol := "!"
	match _quest_marker_state:
		"ready":
			marker_color = Color("#8ee0a0")
		"active":
			marker_color = Color("#78c6e8")
			symbol = "·"
	if _quest_marker_glow != null:
		_quest_marker_glow.color = Color(marker_color.r, marker_color.g, marker_color.b, 0.18)
	if _quest_marker_core != null:
		_quest_marker_core.color = marker_color
	if _quest_marker_symbol != null:
		_quest_marker_symbol.text = symbol


func _derive_role() -> String:
	match npc_id:
		"elder_maelin":
			return "Village Elder"
		"merchant_sera":
			return "Traveling Merchant"
		"wanderer_pip":
			return "Wandering Scout"
	match race:
		"Elf":
			return "Forestfolk"
		"Beastkin":
			return "Wanderer"
		_:
			return "Villager"


func _process(delta: float) -> void:
	_time += delta
	if _interaction_ring != null:
		var pulse := 1.0 + 0.035 * sin(_time * 2.0)
		_interaction_ring.scale = Vector2(pulse, pulse)
	if _quest_marker != null and _quest_marker.visible:
		var marker_pulse := 1.0 + 0.07 * sin(_time * 2.8)
		_quest_marker.scale = Vector2(marker_pulse, marker_pulse)


func interact() -> void:
	if not can_interact():
		return
	if visual != null:
		visual.play_interact()
	EventBus.dialogue_requested.emit(dialogue_id)
