class_name EnemyVisualComponent
extends Node

signal visual_setup_completed
signal visual_visibility_changed(visible_state: bool)

@export var actor_visual_path: NodePath
@export var name_label_path: NodePath
@export var accent_path: NodePath

var actor_visual: ActorVisual
var name_label: Label
var accent: Sprite2D


func _ready() -> void:
	resolve_nodes()


func resolve_nodes(root: Node = null) -> void:
	var owner_root := root
	if owner_root == null:
		owner_root = get_parent().get_parent() if get_parent() != null else null
	if owner_root == null:
		return
	# Exported paths are relative to this component, not the optional owner root.
	actor_visual = get_node_or_null(actor_visual_path) as ActorVisual if not actor_visual_path.is_empty() else owner_root.get_node_or_null("ActorVisual") as ActorVisual
	name_label = get_node_or_null(name_label_path) as Label if not name_label_path.is_empty() else owner_root.get_node_or_null("NameLabel") as Label
	accent = get_node_or_null(accent_path) as Sprite2D if not accent_path.is_empty() else owner_root.get_node_or_null("Accent") as Sprite2D


func configure_enemy(root: Node2D, definition: Dictionary, boss: bool, spawn_seed: int) -> ActorVisual:
	if root == null:
		return null
	resolve_nodes(root)
	var tint_options: Array[Color] = [
		GreenwardStyle.MAGIC.teal,
		GreenwardStyle.MAGIC.violet,
		GreenwardStyle.ACCENTS.berry,
		GreenwardStyle.CANOPY.bright,
		GreenwardStyle.MAGIC.gold,
	]
	var tint: Color = tint_options[spawn_seed % tint_options.size()]
	var palette: Dictionary = _tint_palette(definition.get("palette", {}), tint, 0.12 + float(spawn_seed % 10) * 0.01)
	var enemy_id := str(definition.get("id", ""))
	var kind := ActorVisual.Kind.SPIRIT if enemy_id == "glade_wisp" else ActorVisual.Kind.MONSTER
	if actor_visual == null:
		push_error("EnemyVisual requires its authored ActorVisual child scene.")
		return null
	actor_visual.setup(palette, kind, enemy_id, "Monster", str(definition.get("element", "neutral")))
	actor_visual.is_boss = boss
	actor_visual.visual_scale = (1.35 if boss else 1.0) * (0.85 + float(spawn_seed % 30) * 0.01)
	if not boss and enemy_id != "moonpetal_sprite":
		var silhouettes := ["mossling", "thornhound", "fae_marauder", "glade_wisp", "corrupted_treant"]
		actor_visual.def_id = str(silhouettes[(spawn_seed >> 3) % silhouettes.size()])
	actor_visual.configure_character(enemy_id)
	_configure_accent(root, boss, spawn_seed)
	_configure_name(root, str(definition.get("name", "Monster")), boss)
	emit_setup_completed()
	return actor_visual


func _configure_name(root: Node2D, enemy_name: String, boss: bool) -> void:
	if name_label == null:
		push_error("EnemyVisual requires its authored NameLabel.")
		return
	name_label.text = enemy_name
	name_label.position = Vector2(-80, -100 if boss else -68)
	name_label.size = Vector2(160, 22)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12 if not boss else 15)
	name_label.add_theme_color_override("font_color", GreenwardStyle.MAGIC.ember if not boss else GreenwardStyle.UI.gold)
	name_label.add_theme_color_override("font_outline_color", GreenwardStyle.INK)
	name_label.add_theme_constant_override("outline_size", 4)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _configure_accent(root: Node2D, boss: bool, spawn_seed: int) -> void:
	if accent == null:
		push_error("EnemyVisual requires its authored Accent sprite.")
		return
	accent.visible = false
	if boss or spawn_seed % 3 == 0:
		return
	var kinds := ["crystal", "glow_mushroom", "rune_stone", "spirit_bloom", "mushroom", "pebble"]
	var texture := ProceduralArt.prop_texture(str(kinds[spawn_seed % kinds.size()]), spawn_seed % 2)
	if texture == null:
		return
	accent.texture = texture
	accent.offset = Vector2(-float(texture.get_width()) * 0.5, -float(texture.get_height()) + 6.0)
	accent.scale = Vector2.ONE * 0.4
	accent.position = Vector2(14.0 * (1.0 if spawn_seed % 2 == 0 else -1.0), 0.0)
	accent.visible = true


func _tint_palette(source: Variant, tint: Color, amount: float) -> Dictionary:
	var result: Dictionary = {}
	if source is Dictionary:
		for key in (source as Dictionary).keys():
			result[key] = _to_color((source as Dictionary)[key]).lerp(tint, amount)
	return result


func _to_color(value: Variant) -> Color:
	if value is Color:
		return value
	if value is String and str(value).begins_with("#"):
		return Color(str(value))
	return Color("#4f6b3a")


func set_visible_state(value: bool) -> void:
	var parent := get_parent()
	if parent is CanvasItem:
		(parent as CanvasItem).visible = value
	visual_visibility_changed.emit(value)


func emit_setup_completed() -> void:
	visual_setup_completed.emit()
