class_name OpeningCinematic
extends Control
## Skippable story prologue with illustrated animated forest scenery.

signal finished

const DURATION := 10.0
const CAPTIONS := [
	"The forest had forgotten the sound of a promise.",
	"A brother kept watch. A sister remained between worlds.",
	"Far beneath the First Tree, something began to wake."
]

var _elapsed := 0.0
var _done := false
var _character_layer: Node2D
var _protagonists: Array[ActorVisual] = []
var _caption: Label
var _skip_button: Button
var _fade := 0.0
var _timeline_progress: ColorRect
var _fade_overlay: ColorRect

func _ready() -> void:
	UIFactory.set_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build()
	# Composition and layout are authored in opening_cinematic.tscn. Runtime
	# code only binds story data, animation and the skip action to those nodes.
	_character_layer = get_node("CharacterLayer") as Node2D
	_caption = get_node("Caption") as Label
	_skip_button = get_node("SkipButton") as Button
	_timeline_progress = get_node("TimelineTrack/TimelineProgress") as ColorRect
	_fade_overlay = get_node("CinematicFade") as ColorRect
	_skip_button.pressed.connect(_finish)
	_build_protagonists()
	_update_caption()
	resized.connect(_layout_protagonists)
	_layout_protagonists()

func _build_protagonists() -> void:
	# Gerald and Lilith are pre-authored ActorVisual nodes. Their definitions
	# provide character data; no runtime sprite/node construction is needed.
	for character_id in ["gerald", "lilith"]:
		var definition: CharacterDef = ContentDB.get_character(character_id)
		if definition == null:
			continue
		var visual := _character_layer.get_node_or_null("Prologue_" + character_id) as ActorVisual
		if visual == null:
			push_warning("OpeningCinematic is missing Prologue_" + character_id)
			continue
		visual.visual_scale = 2.7
		visual.facing = 1.0
		visual.setup(definition.palette, ActorVisual.Kind.HUMAN, definition.id, definition.race, definition.element)
		visual.configure_character(character_id)
		_protagonists.append(visual)

func _layout_protagonists() -> void:
	if _character_layer == null:
		return
	for i in range(_protagonists.size()):
		var visual := _protagonists[i]
		var approach := clampf(_elapsed / 3.2, 0.0, 1.0)
		var x := size.x * (0.36 + float(i) * 0.10)
		var y := size.y * (0.56 if i == 0 else 0.53)
		if i == 0:
			x = size.x * (0.33 + approach * 0.03)
			visual.walking = _elapsed < 3.2
		else:
			y += sin(_elapsed * 1.45) * 5.0
		visual.position = Vector2(x, y)

func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	_update_caption()
	_layout_protagonists()
	_fade = clampf((_elapsed - (DURATION - 0.8)) / 0.8, 0.0, 1.0)
	_timeline_progress.anchor_right = clampf(_elapsed / DURATION, 0.0, 1.0)
	var fade_color := _fade_overlay.color
	fade_color.a = _fade
	_fade_overlay.color = fade_color
	if _elapsed >= DURATION:
		_finish()

func _update_caption() -> void:
	var index := clampi(int(_elapsed / 3.2), 0, CAPTIONS.size() - 1)
	if _caption != null and _caption.text != CAPTIONS[index]:
		_caption.text = CAPTIONS[index]
		_caption.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_caption, "modulate:a", 1.0, 0.65)

func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
