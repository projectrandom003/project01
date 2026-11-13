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
var _time: float = 0.0
var _quest_marker_state: String = ""


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

	visual = ActorVisual.new()
	visual.setup(palette, ActorVisual.Kind.HUMAN, npc_id, race, "neutral")
	add_child(visual)
	# PART 4: exercise the SpriteFramesActorSource registration seam. With no
	# disk sheets present this keeps the ProceduralActorFrames fallback active.
	visual.configure_character(npc_id)
	# Drive a gentle IDLE animator from the very first frame.
	visual.play(0)  # CharacterAnimator.State.IDLE == 0
	if visual.animator != null:
		visual.animator.speed_scale = 0.85

	# Name label (warm gold from GreenwardStyle).
	_name_label = Label.new()
	_name_label.text = display_name
	_name_label.position = Vector2(-70, -82)
	_name_label.size = Vector2(140, 22)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.add_theme_color_override("font_color", GreenwardStyle.UI.gold)
	_name_label.add_theme_color_override("font_outline_color", GreenwardStyle.INK)
	_name_label.add_theme_constant_override("outline_size", 4)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

	# Subtle role / title subtitle beneath the name.
	_subtitle_label = Label.new()
	_subtitle_label.text = role
	_subtitle_label.position = Vector2(-80, -62)
	_subtitle_label.size = Vector2(160, 16)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 9)
	var dim := GreenwardStyle.UI.text
	_subtitle_label.add_theme_color_override("font_color", Color(dim.r, dim.g, dim.b, 0.75))
	_subtitle_label.add_theme_color_override("font_outline_color", GreenwardStyle.INK)
	_subtitle_label.add_theme_constant_override("outline_size", 3)
	_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_subtitle_label)

	set_process(true)
	_refresh_quest_marker()
	if not EventBus.quest_updated.is_connected(_refresh_quest_marker):
		EventBus.quest_updated.connect(_refresh_quest_marker)


func _exit_tree() -> void:
	if EventBus.quest_updated.is_connected(_refresh_quest_marker):
		EventBus.quest_updated.disconnect(_refresh_quest_marker)


func _refresh_quest_marker(_quest_id: String = "") -> void:
	_quest_marker_state = GameState.quest_marker_for_npc(npc_id)
	queue_redraw()


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
	queue_redraw()


func _draw() -> void:
	# Soft interaction ring/plate under the NPC's feet; gently pulses.
	var c := GreenwardStyle.MAGIC.teal
	var pulse := 0.35 + 0.15 * sin(_time * 2.0)
	draw_arc(Vector2(0, 0), 16.0, 0.0, TAU, 24, Color(c.r, c.g, c.b, pulse * 0.5), 2.0)
	draw_arc(Vector2(0, 0), 22.0, 0.0, TAU, 24, Color(c.r, c.g, c.b, pulse * 0.22), 1.5)
	# Quest giver / turn-in marker floats above the NPC nameplate.
	if not _quest_marker_state.is_empty():
		var marker_color := Color("#e9c66d")
		var symbol := "!"
		match _quest_marker_state:
			"ready":
				marker_color = Color("#8ee0a0")
				symbol = "!"
			"active":
				marker_color = Color("#78c6e8")
				symbol = "·"
		var marker_pos := Vector2(0, -105)
		draw_circle(marker_pos, 10.0, Color(marker_color.r, marker_color.g, marker_color.b, 0.18))
		draw_circle(marker_pos, 6.0, marker_color)
		draw_string(ThemeDB.fallback_font, marker_pos + Vector2(-3.0, 4.0), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#14202a"))


func interact() -> void:
	if not can_interact():
		return
	if visual != null:
		visual.play_interact()
	EventBus.dialogue_requested.emit(dialogue_id)
