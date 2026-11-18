class_name ActorAnimationRuntimeComponent
extends Node
## Owns the per-frame animation runtime cadence for one ActorVisual instance.
## CharacterAnimator remains a pure state machine; ActorVisual retains its public API.

var visual: ActorVisual


func bind(owner_visual: ActorVisual) -> void:
	visual = owner_visual


func _process(delta: float) -> void:
	if visual == null or not is_instance_valid(visual) or not visual.is_inside_tree():
		return
	visual.tick_animation(delta)
