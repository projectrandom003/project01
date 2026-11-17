class_name CombatFeedbackComponent
extends Node
## Owns transient combat feedback: floating numbers, banners, battle log and shake.

var screen: Control
var battlefield: Battlefield
var log_label: RichTextLabel
var boss_bar: Control
var log_lines: Array[String] = []
var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0


func bind(owner_screen: Control, field: Battlefield, battle_log: RichTextLabel, boss_panel: Control) -> void:
	screen = owner_screen
	battlefield = field
	log_label = battle_log
	boss_bar = boss_panel
	_shake_timer = 0.0
	_shake_intensity = 0.0
	clear_log()


func clear_log() -> void:
	log_lines.clear()
	if log_label != null:
		log_label.text = ""


func float_text(actor: BattlefieldActor, text: String, color: Color, delay: float = 0.16) -> void:
	if battlefield == null or actor == null:
		return
	battlefield.spawn_damage_number(actor, text, color, delay)


func show_banner(text: String) -> void:
	if screen == null:
		return
	var banner := preload("res://scenes/ui/combat/components/battle_event_banner.tscn").instantiate() as Label
	banner.text = text
	banner.add_theme_font_size_override("font_size", 26)
	banner.add_theme_color_override("font_color", UITheme.GOLD_BRIGHT)
	banner.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.05, 0.95))
	banner.add_theme_constant_override("outline_size", 7)
	screen.add_child(banner)
	banner.modulate = Color(1, 1, 1, 0)
	var tween := screen.create_tween()
	tween.tween_property(banner, "modulate:a", 1.0, 0.25)
	tween.tween_interval(1.3)
	tween.tween_property(banner, "modulate:a", 0.0, 0.35)
	tween.tween_callback(banner.queue_free)


func log(line: String) -> void:
	log_lines.append(line)
	while log_lines.size() > 9:
		log_lines.pop_front()
	if log_label != null:
		log_label.text = "\n".join(log_lines)


func camera_shake(intensity: float, duration: float) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)
	_shake_timer = maxf(_shake_timer, duration)


func _process(delta: float) -> void:
	if _shake_timer <= 0.0:
		return
	_shake_timer -= delta
	var offset := Vector2(randf_range(-_shake_intensity, _shake_intensity), randf_range(-_shake_intensity, _shake_intensity))
	if boss_bar != null:
		boss_bar.position = offset
	if _shake_timer <= 0.0:
		_shake_intensity = 0.0
		if boss_bar != null:
			boss_bar.position = Vector2.ZERO
