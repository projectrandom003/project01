extends Control
## Authored full-screen phase transition. AnimationPlayer owns the fade timing.

signal finished

@onready var _veil: ColorRect = $Veil
@onready var _title: Label = $PhaseTitle
@onready var _animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_animation_player.animation_finished.connect(_on_animation_finished)
	visible = false


func play_cue(message: String, accent_color: Color, duration: float = 1.35) -> void:
	_title.text = message
	_title.add_theme_color_override("font_color", accent_color)
	_veil.color = Color(0.012, 0.004, 0.024, 0.0)
	_title.modulate = Color(1.0, 1.0, 1.0, 0.0)
	visible = true
	var animation := _animation_player.get_animation("phase_change")
	_animation_player.speed_scale = animation.length / maxf(0.2, duration)
	_animation_player.play("phase_change")


func cancel_cue() -> void:
	_animation_player.stop()
	visible = false


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name != &"phase_change":
		return
	visible = false
	finished.emit()
