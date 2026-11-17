class_name MainBackdrop
extends Control
## Title-screen host. Presentation, responsive geometry and ambient animation
## are owned by the authored MainBackdropPresentationComponent child.

var presentation: MainBackdropPresentationComponent


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	presentation = get_node_or_null("Presentation") as MainBackdropPresentationComponent
	if presentation == null:
		push_error("MainBackdrop requires its authored Presentation component.")
		return
	presentation.bind(self)
	presentation.build()

func _rebuild_layout() -> void:
	if presentation != null:
		presentation._rebuild_layout()


func _update_animation(delta: float) -> void:
	if presentation != null:
		presentation._update_animation(delta)
