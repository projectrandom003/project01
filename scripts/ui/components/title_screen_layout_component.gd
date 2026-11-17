class_name TitleScreenLayoutComponent
extends Node
## Owns responsive positioning and hit-target geometry for the authored title artwork.

const BUTTON_NAMES := ["ContinueButton", "NewJourneyButton", "LoadGameButton", "SettingsButton", "ExtrasButton", "QuitGameButton"]
const BUTTON_CENTRES_Y := [440.0, 513.0, 580.0, 648.0, 714.0, 782.0]
var screen: Control

func bind(owner: Control) -> void:
	screen = owner
	screen.resized.connect(rebuild)
	rebuild()

func rebuild() -> void:
	if screen == null:
		return
	var artwork := screen.get_node_or_null("TitleArtwork") as TextureRect
	if artwork == null or artwork.texture == null or screen.size.x <= 0.0 or screen.size.y <= 0.0:
		return
	var source_size := artwork.texture.get_size()
	var scale_factor := minf(screen.size.x / source_size.x, screen.size.y / source_size.y)
	var draw_size := source_size * scale_factor
	var origin := (screen.size - draw_size) * 0.5
	artwork.set_anchors_preset(Control.PRESET_TOP_LEFT)
	artwork.position = origin
	artwork.size = draw_size
	artwork.stretch_mode = TextureRect.STRETCH_SCALE
	for index in BUTTON_NAMES.size():
		var button := screen.get_node_or_null(BUTTON_NAMES[index]) as Button
		if button == null:
			continue
		button.set_anchors_preset(Control.PRESET_TOP_LEFT)
		button.position = origin + Vector2(820.0, BUTTON_CENTRES_Y[index] - 29.0) * scale_factor
		button.size = Vector2(370.0, 58.0) * scale_factor
