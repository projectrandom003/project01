extends Node2D
## Reusable impact flourish. It is presentation-only and never applies damage.

signal completed

@onready var _glyph: Node2D = $Glyph
@onready var _elder_style: Node2D = $Glyph/Artwork/ElderStyle
@onready var _matron_style: Node2D = $Glyph/Artwork/MatronStyle
@onready var _animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	_animation_player.animation_finished.connect(_on_animation_finished)


func play(profile: Resource, strength: float = 1.0) -> void:
	if profile != null:
		modulate = profile.get("impact_color")
		_glyph.scale = Vector2.ONE * float(profile.get("impact_scale")) * clampf(strength, 0.35, 2.0)
		var visual_style := str(profile.get("visual_style"))
		_elder_style.visible = visual_style != "bloom"
		_matron_style.visible = visual_style == "bloom"
	_animation_player.play("impact")


func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name != &"impact":
		return
	completed.emit()
	queue_free()
