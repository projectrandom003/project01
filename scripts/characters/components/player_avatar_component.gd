class_name PlayerAvatarComponent
extends Node
## Owns party-avatar selection, art validation and visual configuration.

const AVATAR_HEIGHT_SCALE := {
	"kael": 1.0,
	"gerald": (0.75 * 183.0) / 128.0,
	"lilith": 130.0 / 183.0,
}

var actor: Node2D


func _ready() -> void:
	actor = get_parent() as Node2D


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("switch_avatar"):
		return
	if event is InputEventKey and event.echo:
		return
	if actor == null or not bool(actor.get("input_enabled")):
		return
	cycle_avatar()
	get_viewport().set_input_as_handled()


func available_avatars() -> Array[String]:
	var party_ids: Array[String] = []
	for instance in GameState.roster_domain.party_instances():
		var character_id := str(instance.char_id)
		if not character_id.is_empty() and not party_ids.has(character_id):
			party_ids.append(character_id)
	var ids: Array[String] = []
	for character_id in ["kael", "lilith", "gerald"]:
		if not party_ids.has(character_id):
			continue
		var source := SpriteFramesActorSource.from_playable(character_id)
		if source != null and source.has_frames() and source.validate_sheets().is_empty():
			ids.append(character_id)
	return ids


func cycle_avatar() -> String:
	if actor == null:
		return ""
	var ids := available_avatars()
	var current_id := str(actor.get("avatar_id"))
	if ids.size() <= 1:
		EventBus.toast_requested.emit("No other playable avatars in the party yet.")
		return current_id
	var index := ids.find(current_id)
	var next_id := ids[(index + 1) % ids.size()] if index >= 0 else ids[0]
	set_avatar(next_id)
	return str(actor.get("avatar_id"))


func set_avatar(character_id: String) -> bool:
	if actor == null or character_id.is_empty():
		return false
	var visual := actor.get("visual") as ActorVisual
	if visual == null:
		return false
	var definition := ContentDB.get_character(character_id)
	if definition == null or definition.id.is_empty():
		return false
	var kind := ActorVisual.Kind.HUMAN
	if definition.race == "Spirit":
		kind = ActorVisual.Kind.SPIRIT
	elif definition.race == "Monster":
		kind = ActorVisual.Kind.MONSTER
	visual.setup(definition.palette, kind, character_id, definition.race, definition.element)
	var report := visual.configure_character(character_id)
	if not bool(report.get("registered", false)):
		return false
	actor.set("avatar_id", character_id)
	visual.set_body_scale(float(AVATAR_HEIGHT_SCALE.get(character_id, 1.0)))
	var camera := actor.get_node_or_null("Camera2D") as PlayerCameraRig
	if camera != null:
		camera.set_avatar_id(character_id)
	var name_label := actor.get_node_or_null("NameLabel") as Label
	if name_label != null:
		name_label.text = definition.display_name
	EventBus.toast_requested.emit("Now playing as " + definition.display_name)
	return true
