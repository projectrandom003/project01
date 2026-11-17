class_name PlayerPresentationComponent
extends Node
## Owns player visual-node setup, water presentation and one-shot/event cues.

const HERO_PALETTE := {
	"hair": "#5a3a2a",
	"primary": "#2f4a6b",
	"secondary": "#c9a45a",
	"accent": "#7fe3e0",
	"skin": "#f0cbb0",
}

var actor: Node2D


func _ready() -> void:
	actor = get_parent() as Node2D
	if not EventBus.battle_finished.is_connected(_on_battle_finished):
		EventBus.battle_finished.connect(_on_battle_finished)
	if not EventBus.encounter_requested.is_connected(_on_encounter_requested):
		EventBus.encounter_requested.connect(_on_encounter_requested)


func _exit_tree() -> void:
	if EventBus.battle_finished.is_connected(_on_battle_finished):
		EventBus.battle_finished.disconnect(_on_battle_finished)
	if EventBus.encounter_requested.is_connected(_on_encounter_requested):
		EventBus.encounter_requested.disconnect(_on_encounter_requested)


func configure_visual_nodes() -> ActorVisual:
	if actor == null:
		push_error("PlayerPresentationComponent requires a Player parent")
		return null
	var visual := actor.get_node_or_null("ActorVisual") as ActorVisual
	var name_label := actor.get_node_or_null("NameLabel") as Label
	var glow := actor.get_node_or_null("PersonalGlow") as PlayerPersonalLightComponent
	var water_surface := actor.get_node_or_null("WaterSurface") as Sprite2D
	if visual == null or name_label == null or glow == null or water_surface == null:
		push_error("Player scene is missing an authored presentation child")
		return null
	visual.setup(HERO_PALETTE, ActorVisual.Kind.HUMAN, "player", "Human", "wind")
	name_label.text = str(GameState.profile_domain.profile.get("name", "Wanderer"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.86, 0.95, 1.0, 0.9))
	name_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.06, 0.9))
	name_label.add_theme_constant_override("outline_size", 4)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.texture = ProceduralArt.soft_glow(Color(1.0, 0.86, 0.88, 0.55), 128)
	glow.color = Color(1.0, 0.9, 0.72)
	glow.energy = 0.55
	glow.texture_scale = 2.6
	water_surface.texture = ProceduralArt.white_pixel()
	water_surface.visible = false
	return visual

func update_water_visual(in_water: bool) -> void:
	if actor == null:
		return
	var visual := actor.get_node_or_null("ActorVisual") as ActorVisual
	if visual != null:
		visual.position = Vector2(0, 44) if in_water else Vector2.ZERO
	var surface := actor.get_node_or_null("WaterSurface") as Sprite2D
	if surface != null:
		surface.visible = in_water


func restore_facing(facing: Vector2) -> Vector2:
	if facing.length_squared() < 0.0001:
		facing = Vector2(0.0, 1.0)
	facing = facing.normalized()
	var visual := actor.get_node_or_null("ActorVisual") as ActorVisual if actor != null else null
	if visual != null:
		if absf(facing.x) > 0.1:
			visual.facing = 1.0 if facing.x > 0.0 else -1.0
		visual.set_move_direction(facing)
		visual.play(0)
	GameState.session_domain.set_player_facing(facing)
	return facing


func play_damage() -> void:
	_play_visual_cue("hit")


func play_victory() -> void:
	_play_visual_cue("play_victory")


func play_defeat() -> void:
	_play_visual_cue("play_defeat")


func play_attack() -> void:
	_play_visual_cue("play_attack")


func play_cast() -> void:
	_play_visual_cue("play_cast")


func _play_visual_cue(method_name: String) -> void:
	if actor == null:
		return
	var visual := actor.get_node_or_null("ActorVisual") as ActorVisual
	if visual != null and visual.has_method(method_name):
		visual.call(method_name)


func _on_battle_finished(result: Dictionary) -> void:
	if bool(result.get("victory", false)):
		play_victory()
	else:
		play_defeat()


func _on_encounter_requested(_group_id: String, _source: Node) -> void:
	play_attack()
