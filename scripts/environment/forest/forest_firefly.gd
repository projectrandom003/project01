class_name ModularForestFirefly
extends Node2D
## Ambient actor whose activity is driven by the forest's shared day/night state.

@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var activity: float = 1.0


func _ready() -> void:
	sprite.texture = ProceduralArt.prop_texture("firefly_sprite")
	if animation_player.has_animation("hover"):
		animation_player.play("hover")
	set_activity(activity)


func set_activity(value: float) -> void:
	activity = clampf(value, 0.0, 1.0)
	visible = activity > 0.025
	self_modulate = Color(1.0, 1.0, 1.0, activity)
	if animation_player == null:
		return
	if activity <= 0.025:
		animation_player.pause()
	else:
		if not animation_player.is_playing():
			animation_player.play("hover")
		animation_player.speed_scale = lerpf(0.35, 1.0, activity)
