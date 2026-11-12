class_name RegionPortal
extends Interactable
## A visible, interactable gate that REQUESTS a region transition through
## EventBus. It NEVER mutates GameState directly — GameScreen owns transitions,
## validates them with RegionGraph and rebuilds the world. Headless-safe: no
## per-frame work, no heavy processing, all art is procedural placeholder.

var region_id: String = ""
var connection_id: String = ""
var target_region: String = ""
var entry_point: String = ""
var portal_label: String = "Travel"
var target_region_name: String = ""

var _sprite: Sprite2D
var _light: PointLight2D
var _label: Label


func setup(p_region_id: String, p_connection: Dictionary) -> void:
	region_id = p_region_id
	connection_id = str(p_connection.get("id", ""))
	target_region = str(p_connection.get("to", ""))
	entry_point = str(p_connection.get("entry", ""))
	portal_label = str(p_connection.get("label", "Travel"))
	target_region_name = _lookup_region_name(target_region)


func _ready() -> void:
	super._ready()  # keeps this node in the "interactables" group
	interaction_radius = 110.0
	prompt = "Travel to " + portal_label
	if target_region_name.is_empty():
		target_region_name = _lookup_region_name(target_region)
	_build_visual()


func _build_visual() -> void:
	if _sprite != null:
		return
	var tex := ProceduralArt.prop_texture("waypoint", 1)
	if tex == null:
		tex = ProceduralArt.white_pixel()
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = tex
	_sprite.centered = false
	_sprite.offset = Vector2(-float(tex.get_width()) * 0.5, -float(tex.get_height()) + 6.0)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)

	# A soft additively-blended glow so the gate reads as a destination.
	_light = PointLight2D.new()
	_light.name = "Glow"
	_light.texture = ProceduralArt.soft_glow(GreenwardStyle.MAGIC.teal, 96)
	_light.color = GreenwardStyle.MAGIC.teal
	_light.energy = 1.0
	_light.texture_scale = 2.2
	_light.blend_mode = Light2D.BLEND_MODE_ADD
	_light.position = Vector2(0, -36)
	add_child(_light)

	_label = Label.new()
	_label.name = "Label"
	_label.text = portal_label
	_label.position = Vector2(-64, -96)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func interact() -> void:
	if not can_interact():
		return
	EventBus.region_change_requested.emit(target_region, entry_point)
	EventBus.toast_requested.emit("Travelling to " + target_region_name)


func _lookup_region_name(id: String) -> String:
	# Read-only, defensive lookup: fall back to the id if ContentDB is empty.
	var def: Dictionary = ContentDB.get_region(id)
	var name_value := str(def.get("name", ""))
	return name_value if not name_value.is_empty() else id
