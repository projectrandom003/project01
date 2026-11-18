extends Node
## Central music owner. Track selection stays explicit; scenes request a musical role.
const BUS_LAYOUT: AudioBusLayout = preload("res://resources/audio/reverie_audio_bus_layout.tres")
const TRACKS := {
	"main_theme": "res://assets/audio/music/crown_of_ash_and_rose.mp3",
	"title_screen": "res://assets/audio/music/the_frozen_kingdom.mp3",
	"exploration": "res://assets/audio/music/the_frozen_kingdom.mp3",
	"kael_prologue": "res://assets/audio/music/fading_into_the_void.mp3",
}

@onready var _player: AudioStreamPlayer = $MusicPlayer
var _current_track_id := ""
var _fade_tween: Tween

func _ready() -> void:
	# Install the authored bus layout before any screen can adjust volume.
	AudioServer.set_bus_layout(BUS_LAYOUT)
	_player.bus = "Music"

func play_main_theme(fade_duration: float = 1.8) -> bool:
	return play_track("main_theme", fade_duration)

func play_title_theme(fade_duration: float = 1.8) -> bool:
	return play_track("title_screen", fade_duration)

func play_kael_prologue(fade_duration: float = 1.5) -> bool:
	return play_track("kael_prologue", fade_duration)

func play_exploration_theme(fade_duration: float = 2.2) -> bool:
	return play_track("exploration", fade_duration)

## Call this only from Ravienne/Cassie story scenes, not the Gerald/Lilith prologue.
func play_track(track_id: String, fade_duration: float = 1.8) -> bool:
	if not TRACKS.has(track_id):
		push_warning("[AudioDirector] Unknown music track: " + track_id)
		return false
	if _current_track_id == track_id and _player.playing:
		return true
	var path: String = TRACKS[track_id]
	if not ResourceLoader.exists(path):
		push_warning("[AudioDirector] Music file is not installed yet: " + path)
		return false
	if _fade_tween != null and _fade_tween.is_running():
		_fade_tween.kill()
	var duration := maxf(fade_duration, 0.05)
	if _player.playing:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_player, "volume_db", -48.0, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_fade_tween.tween_callback(_start_track.bind(track_id, duration * 0.5))
	else:
		_start_track(track_id, duration)
	return true

func stop_music(fade_duration: float = 1.0) -> void:
	if not _player.playing:
		_current_track_id = ""
		return
	if _fade_tween != null and _fade_tween.is_running():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_player, "volume_db", -48.0, maxf(fade_duration, 0.05))
	_fade_tween.tween_callback(_stop_player)

func _start_track(track_id: String, fade_duration: float) -> void:
	var stream := load(TRACKS[track_id]) as AudioStream
	if stream == null:
		push_warning("[AudioDirector] Could not load music track: " + TRACKS[track_id])
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	_player.stop()
	_player.stream = stream
	_player.volume_db = -48.0
	_player.play()
	_current_track_id = track_id
	_fade_tween = create_tween()
	_fade_tween.tween_property(_player, "volume_db", -5.0, maxf(fade_duration, 0.05)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _stop_player() -> void:
	_player.stop()
	_current_track_id = ""
