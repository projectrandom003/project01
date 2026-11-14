extends Node2D
## Reusable warning marker. Its visible timing and motion are authored in AnimationPlayer.

signal completed

@onready var _glyph: Node2D = $Glyph
@onready var _elder_style: Node2D = $Glyph/Artwork/ElderStyle
@onready var _matron_style: Node2D = $Glyph/Artwork/MatronStyle
@onready var _animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	_animation_player.animation_finished.connect(_on_animation_finished)


func play(profile: Resource, duration: float = 0.42) -> void:
	if profile != null:
		modulate = profile.get("telegraph_color")
		_glyph.scale = Vector2.ONE * float(profile.get("telegraph_scale"))
		var visual_style := str(profile.get("visual_style"))
		_elder_style.visible = visual_style != "bloom"
		_matron_style.visible = visual_style == "bloom"
	var animation := _animation_player.get_animation("warning")
	_animation_player.speed_scale = animation.length / maxf(0.12, duration)
	_animation_player.play("warning")


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name != &"warning":
		return
	completed.emit()
	queue_free()
