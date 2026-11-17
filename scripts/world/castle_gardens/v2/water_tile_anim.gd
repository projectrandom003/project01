extends Sprite2D
## Four-frame water loop for the v0.2 256x32 strip.
## Each tile advances continuously with a small deterministic phase offset,
## so the pond reads as flowing water rather than a frozen synchronized sheet.
@export_range(0.5, 12.0, 0.5) var frames_per_second: float = 6.0
@export_range(0, 3, 1) var phase_offset: int = 0
var _frame_accumulator: float = 0.0
var _loop_frame: int = 0

func _ready() -> void:
	hframes = 4
	vframes = 1
	_loop_frame = 0
	frame = posmod(phase_offset, hframes)
	set_process(true)

func _process(delta: float) -> void:
	if frames_per_second <= 0.0 or hframes < 2:
		return
	_frame_accumulator += delta
	var frame_duration := 1.0 / frames_per_second
	while _frame_accumulator >= frame_duration:
		_frame_accumulator -= frame_duration
		_loop_frame = (_loop_frame + 1) % hframes
		frame = (_loop_frame + phase_offset) % hframes
