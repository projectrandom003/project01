class_name KaelCinematicPresentationComponent
extends Node
## Owns still artwork, narration display and restrained crossfades only.

signal presentation_finished

var _artwork: TextureRect
var _caption: Label
var _fade_overlay: ColorRect
var _timeline_progress: ColorRect

func bind(owner: Control) -> bool:
	_artwork = owner.get_node_or_null("Artwork") as TextureRect
	_caption = owner.get_node_or_null("Caption") as Label
	_fade_overlay = owner.get_node_or_null("CinematicFade") as ColorRect
	_timeline_progress = owner.get_node_or_null("TimelineTrack/TimelineProgress") as ColorRect
	if _artwork == null or _caption == null or _fade_overlay == null or _timeline_progress == null:
		push_error("[KaelPresentation] Authored artwork, caption, fade or timeline node is missing.")
		return false
	owner.resized.connect(_update_artwork_pivot)
	_update_artwork_pivot()
	return true

func show_shot(index: int, shot: Dictionary, total: int) -> void:
	var texture_path := str(shot.get("image", ""))
	var texture := load(texture_path) as Texture2D
	if texture == null:
		push_error("[KaelPresentation] Could not load image: " + texture_path)
		return
	_artwork.texture = texture
	_artwork.modulate.a = 0.0
	_artwork.scale = Vector2.ONE
	_artwork.position = Vector2.ZERO
	_caption.text = str(shot.get("caption", ""))
	_caption.modulate.a = 0.0
	_timeline_progress.anchor_right = float(index) / float(maxi(total, 1))
	_update_artwork_pivot()
	var fade := create_tween()
	fade.tween_property(_artwork, "modulate:a", 1.0, 0.4)
	fade.parallel().tween_property(_caption, "modulate:a", 1.0, 0.4).set_delay(0.06)

func update_progress(progress: float) -> void:
	_timeline_progress.anchor_right = clampf(progress, 0.0, 1.0)

func crossfade_out() -> void:
	var fade := create_tween()
	fade.tween_property(_artwork, "modulate:a", 0.0, 0.3)
	fade.parallel().tween_property(_caption, "modulate:a", 0.0, 0.25)
	await fade.finished
	presentation_finished.emit()

func finish_to_black() -> void:
	var fade := create_tween()
	fade.tween_property(_fade_overlay, "color:a", 1.0, 0.85)
	await fade.finished
	presentation_finished.emit()

func _update_artwork_pivot() -> void:
	if _artwork != null:
		_artwork.pivot_offset = _artwork.size * 0.5
