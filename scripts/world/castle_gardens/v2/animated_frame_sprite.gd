extends Sprite2D
## Drives a horizontal sprite-sheet (hframes) as a looping animation.
##
## Used for the Castle Asset Pack v0.2 animated strips:
##   * water_tile_anim.png  (4 frames, 6 fps)
##   * fountain_spray_anim.png (6 frames, 10 fps)
##   * magic_mote_anim.png (8 frames, 12 fps)
##
## The sheet stays a single editable PNG; only the frame index animates.

@export_range(1.0, 60.0, 0.5) var frames_per_second: float = 10.0
@export var autoplay: bool = true

var _elapsed: float = 0.0


func _ready() -> void:
	if hframes <= 1:
		set_process(false)
		return
	set_process(autoplay)


func _process(delta: float) -> void:
	if hframes <= 1:
		return
	_elapsed += delta
	var frame := int(_elapsed * frames_per_second) % hframes
	if frame != self.frame:
		self.frame = frame
