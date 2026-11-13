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

func _ready() -> void:
	UIFactory.set_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := LaunchForestBackdrop.new()
	backdrop.name = "IllustratedForest"
	UIFactory.set_full_rect(backdrop)
	add_child(backdrop)
	var shade := ColorRect.new()
	shade.color = Color(0.008, 0.018, 0.028, 0.12)
	UIFactory.set_full_rect(shade)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_character_layer = Node2D.new()
	_character_layer.z_index = 2
	add_child(_character_layer)
	_build_protagonists()

	_caption = Label.new()
	_caption.z_index = 5
	_caption.anchor_left = 0.08
	_caption.anchor_right = 0.92
	_caption.anchor_top = 0.79
	_caption.anchor_bottom = 0.91
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("font_size", 25)
	_caption.add_theme_color_override("font_color", Color("#f0ead9"))
	_caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_caption.add_theme_constant_override("shadow_offset_x", 1)
	_caption.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_caption)

	_skip_button = UIFactory.button("Skip  ›", false)
	_skip_button.z_index = 5
	_skip_button.anchor_left = 0.86
	_skip_button.anchor_right = 0.97
	_skip_button.anchor_top = 0.035
	_skip_button.anchor_bottom = 0.10
	_skip_button.pressed.connect(_finish)
	add_child(_skip_button)
	_update_caption()
	resized.connect(_layout_protagonists)
	_layout_protagonists()

func _build_protagonists() -> void:
	# Only the two story leads belong in the prologue. The loading screen owns
	# its own party showcase and must never be visible at the same time.
	for character_id in ["gerald", "lilith"]:
		var definition: CharacterDef = ContentDB.get_character(character_id)
		if definition == null:
			continue
		var visual := ActorVisual.new()
		visual.name = "Prologue_" + character_id
		visual.visual_scale = 2.7
		visual.facing = 1.0
		visual.setup(definition.palette, ActorVisual.Kind.HUMAN, definition.id, definition.race, definition.element)
		visual.configure_character(character_id)
		_character_layer.add_child(visual)
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
	queue_redraw()
	if _elapsed >= DURATION:
		_finish()

func _update_caption() -> void:
	var index := clampi(int(_elapsed / 3.2), 0, CAPTIONS.size() - 1)
	if _caption != null and _caption.text != CAPTIONS[index]:
		_caption.text = CAPTIONS[index]
		_caption.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_caption, "modulate:a", 1.0, 0.65)

func _draw() -> void:
	# Fine gold timeline and a final cinematic fade; the scenery itself is now
	# supplied by the shared illustrated, animated background node.
	var progress := clampf(_elapsed / DURATION, 0.0, 1.0)
	draw_rect(Rect2(size.x * 0.12, size.y * 0.965, size.x * 0.76, 2.0), Color(0.85, 0.86, 0.72, 0.20))
	draw_rect(Rect2(size.x * 0.12, size.y * 0.965, size.x * 0.76 * progress, 2.0), Color("#e0c98e", 0.95))
	if _fade > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.015, 0.03, _fade))

func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
