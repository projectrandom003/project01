extends Control

const PREVIEW_GROUP := "corrupted_treant"

func _ready() -> void:
	UIFactory.set_full_rect(self)
	var stage := Battlefield.new()
	stage.name = "BossArenaPreview"
	stage.arena_id = PREVIEW_GROUP
	UIFactory.set_full_rect(stage)
	add_child(stage)
	stage.setup(CombatFactory.player_units(), CombatFactory.enemy_units(PREVIEW_GROUP))
	var title := Label.new()
	title.text = "PROJECT FANTASY  /  THE HOLLOWED GUARDIAN"
	title.position = Vector2(28, 22)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#e8e4d5"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.z_index = 100
	add_child(title)
