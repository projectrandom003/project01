class_name OpeningCinematic
extends Control
## Composition root: connects authored cinematic nodes without owning their internal behavior.

signal finished

@onready var sequence_component: KaelCinematicSequenceComponent = $Sequence
@onready var presentation_component: KaelCinematicPresentationComponent = $Presentation
@onready var playback_component: KaelCinematicPlaybackComponent = $Playback
@onready var input_component: KaelCinematicInputComponent = $Input
@onready var audio_component: KaelCinematicAudioComponent = $Audio

var _transitioning := false
var _done := false

func _ready() -> void:
	UIFactory.set_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITheme.build()
	if not presentation_component.bind(self) or not input_component.bind(self):
		return
	if not sequence_component.load_sequence():
		return
	playback_component.advance_requested.connect(_advance)
	playback_component.shot_changed.connect(presentation_component.show_shot)
	playback_component.progress_changed.connect(presentation_component.update_progress)
	playback_component.sequence_completed.connect(_finish)
	input_component.advance_requested.connect(playback_component.request_advance)
	input_component.auto_play_changed.connect(playback_component.set_auto_play)
	input_component.skip_requested.connect(_finish)
	audio_component.begin()
	playback_component.configure(sequence_component.shots)

func _advance() -> void:
	if _transitioning or _done:
		return
	_transitioning = true
	await presentation_component.crossfade_out()
	if _done:
		return
	playback_component.move_next()
	_transitioning = false

func _finish() -> void:
	if _done:
		return
	_done = true
	await presentation_component.finish_to_black()
	audio_component.stop()
	finished.emit()
