class_name KaelCinematicAudioComponent
extends Node
## Requests the Kael-only soundtrack; title-screen music is owned elsewhere.

func begin() -> void:
	AudioDirector.play_kael_prologue()

func stop() -> void:
	AudioDirector.stop_music(0.5)
