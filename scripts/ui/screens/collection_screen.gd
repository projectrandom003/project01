class_name CollectionScreen
extends OverlayScreen

const CENTERED_PORTRAIT_SLOT_SCENE: PackedScene = preload("res://scenes/ui/components/centered_portrait_slot.tscn")
const ROSTER_CARD_SCENE: PackedScene = preload("res://scenes/ui/components/roster_character_card.tscn")
const COLLECTION_LAYOUT_SCENE: PackedScene = preload("res://scenes/ui/components/collection_screen_layout.tscn")
## Roster, party management, ascension and character detail.

var _grid: GridContainer
var _detail: VBoxContainer
var _cards: Dictionary = {}
var _selected_uid: String = ""
var _filter: String = "all"
var _ascend_armed: bool = false
var _ascend_armed_uid: String = ""

# Phase 5 presentation counters. ZERO final portraits exist; every PortraitView
# here still renders the procedural fallback. These track the additive rarity
# / art-spec presentation only.
var _premium_count: int = 0
var _visual_theme_lines: int = 0
var _roster_component: CollectionRosterComponent
var _detail_component: CollectionDetailComponent


func _ready() -> void:
	_roster_component = get_node_or_null("Roster") as CollectionRosterComponent
	_detail_component = get_node_or_null("Detail") as CollectionDetailComponent
	if _roster_component == null or _detail_component == null:
		push_error("CollectionScreen requires authored Roster and Detail component children.")
		return
	_roster_component.bind(self)
	_detail_component.bind(self)
	super._ready()

func _init() -> void:
	screen_title = "Roster"
	screen_subtitle = "Every bond you have made in Aetheria"


func _build_content() -> void:
	var layout := COLLECTION_LAYOUT_SCENE.instantiate() as HBoxContainer
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(layout)

	var filters := layout.get_node("Left/Filters") as HBoxContainer
	var all_button := filters.get_node("AllCharactersButton") as Button
	var party_button := filters.get_node("PartyOnlyButton") as Button
	for button in [all_button, party_button]:
		button.add_theme_stylebox_override("normal", UITheme.style(Color("#111a2d"), UITheme.BORDER_SOFT, 8, 1, 8))
	all_button.pressed.connect(func() -> void: _set_filter("all"))
	party_button.pressed.connect(func() -> void: _set_filter("party"))
	(filters.get_node("FilterHint") as Label).add_theme_color_override("font_color", UITheme.TEXT_FAINT)

	_grid = layout.get_node("Left/GridScroll/CharacterGrid") as GridContainer
	_detail = layout.get_node("DetailPanel/DetailScroll/DetailContent") as VBoxContainer
	_rebuild_grid()


func _set_filter(value: String) -> void:
	if _roster_component != null:
		_roster_component.set_filter(value)

func _rebuild_grid() -> void:
	if _roster_component != null:
		_roster_component.rebuild_grid()

func _has_uid(instances: Array, uid: String) -> bool:
	return _roster_component.has_uid(instances, uid)

func _make_card(instance: CharacterInstance) -> PanelContainer:
	return _roster_component.make_card(instance)

func _style_card(card: PanelContainer, uid: String) -> void:
	if _roster_component != null:
		_roster_component.style_card(card, uid)

func _select(uid: String) -> void:
	if _roster_component != null:
		_roster_component.select(uid)

func _show_detail(uid: String) -> void:
	if _detail_component != null:
		_detail_component.show_detail(uid)

func _stat_row(title: String, value: Variant) -> PanelContainer:
	return _detail_component.stat_row(title, value)

func _power_score(definition: CharacterDef, multiplier: float) -> float:
	return _detail_component.power_score(definition, multiplier)

func _toggle_party(uid: String) -> void:
	var next: Array = GameState.roster_domain.party.duplicate()
	if next.has(uid):
		next.erase(uid)
	else:
		next.append(uid)
	if GameState.roster_domain.set_party(next):
		EventBus.toast_requested.emit("Party updated.")
	else:
		EventBus.toast_requested.emit("That party change is not valid.")
	_rebuild_grid()
	_show_detail(uid)


func _ascend(uid: String) -> void:
	if _ascend_armed_uid != uid:
		_ascend_armed_uid = uid
		_ascend_armed = true
		_show_detail(uid)
		return
	_ascend_armed_uid = ""
	_ascend_armed = false
	if GameState.roster_domain.ascend(uid):
		EventBus.toast_requested.emit("Ascension successful.")
		_rebuild_grid()
		_show_detail(uid)
	else:
		EventBus.toast_requested.emit("Ascension failed.")
		_show_detail(uid)


func _awaken(uid: String) -> void:
	if GameState.roster_domain.awaken(uid):
		EventBus.toast_requested.emit("Awakening successful.")
		_rebuild_grid()
		_show_detail(uid)
	else:
		EventBus.toast_requested.emit("Could not awaken.")
		_show_detail(uid)


func _find_instance(uid: String) -> CharacterInstance:
	for instance in GameState.roster_domain.roster:
		if instance.uid == uid:
			return instance
	return null


func _refresh() -> void:
	_rebuild_grid()


## Additive presentation report (Phase 5). ZERO final portraits exist; every
## PortraitView counted here is the procedural fallback.
func presentation_report() -> Dictionary:
	return {
		"screen": "collection",
		"portrait_count": _count_portrait_views(self),
		"premium_count": _premium_count,
		"rarity_effects_enabled": true,
		"visual_theme_lines": _visual_theme_lines,
		"cards": _cards.size(),
	}


func _count_portrait_views(node: Node) -> int:
	var total := 0
	if node is PortraitView:
		total += 1
	for child in node.get_children():
		total += _count_portrait_views(child)
	return total
