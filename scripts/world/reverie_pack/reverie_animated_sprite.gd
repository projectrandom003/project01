extends Sprite2D
## Looping horizontal sprite-sheet player for REVERIE pack animation strips.
## Only the frame index changes; the underlying PNG stays a single editable file.

@export_range(1.0, 60.0, 0.5) var frames_per_second: float = 12.0
@export var loop: bool = true

var _elapsed: float = 0.0


func _ready() -> void:
	if hframes <= 1:
		set_process(false)
		return
	set_process(true)


func _process(delta: float) -> void:
	if hframes <= 1:
		return
	_elapsed += delta
	var next := int(_elapsed * frames_per_second)
	if loop:
		next = next % hframes
	else:
		next = mini(next, hframes - 1)
	if next != frame:
		frame = next
