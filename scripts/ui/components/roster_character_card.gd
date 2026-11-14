class_name RosterCharacterCard
extends PanelContainer

signal selected(uid: String)

var _uid: String = ""
var _portrait: PortraitView
var _name_label: Label
var _subtitle_label: Label
var _tier_label: Label
var _party_badge: Label


func setup(
	uid: String,
	definition: CharacterDef,
	level: int,
	in_party: bool,
	premium: bool,
	glow: Color,
	tier_text: String
) -> void:
	_uid = uid
	_portrait = get_node("Content/PortraitSlot/Portrait") as PortraitView
	_name_label = get_node("Content/Name") as Label
	_subtitle_label = get_node("Content/Subtitle") as Label
	_tier_label = get_node("Content/Tier") as Label
	_party_badge = get_node("Content/PartyBadge") as Label
	if definition != null:
		_portrait.setup_character(definition)
		_name_label.text = definition.display_name
		_subtitle_label.text = "Lv %d · %s" % [level, definition.rarity.capitalize()]
	else:
		_name_label.text = uid
		_subtitle_label.text = "Lv %d · ?" % level
	_tier_label.text = "✦ " + tier_text
	_tier_label.visible = premium and not tier_text.is_empty()
	_tier_label.add_theme_color_override("font_color", glow)
	_party_badge.visible = in_party
	custom_minimum_size = Vector2(126, 174)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit(_uid)
		accept_event()
