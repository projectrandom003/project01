class_name BattlefieldImpactEffectsComponent
extends Control
## Owns transient impact particles and floating combat-number presentation.

var battlefield: Battlefield


func bind(owner: Battlefield) -> void:
	battlefield = owner
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## A floating damage / heal number above an actor.
func spawn_damage_number(actor: BattlefieldActor, text: String, color: Color,
		delay: float = 0.0) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var label := preload("res://scenes/ui/combat/components/floating_combat_number.tscn").instantiate() as Label
	label.text = text
	label.add_theme_font_size_override("font_size", Battlefield.DAMAGE_FONT)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.05, 0.95))
	label.add_theme_constant_override("outline_size", 6)
	label.z_index = 60
	battlefield._stage.add_child(label)
	var start: Vector2 = actor.position + Vector2(-28.0, -74.0 * actor.visual.visual_scale)
	label.position = start
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(label, "position:y", start.y - 54.0, 0.85) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.85).set_delay(0.25)
	if text.contains("!"):
		label.scale = Vector2(1.5, 1.5)
		tween.tween_property(label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC)
	tween.chain().tween_callback(label.queue_free)


## The elemental burst at the impact point.
func spawn_elemental_burst(pos: Vector2, element: String) -> void:
	var color := UITheme.element_color(element)
	if color == UITheme.TEXT_DIM:
		color = Color(0.85, 0.85, 0.9)
	var particles := preload("res://scenes/ui/combat/components/elemental_burst.tscn").instantiate() as CPUParticles2D
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.color = color
	particles.z_index = 35
	particles.position = pos
	add_child(particles)
	particles.finished.connect(particles.queue_free)
	particles.emitting = true

