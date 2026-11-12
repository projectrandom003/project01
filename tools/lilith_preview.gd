extends Control
## In-engine visual review scene for Lilith's playable art.
##
## Open with:
##   godot --path . res://tools/lilith_preview.tscn
##
## It renders the REAL runtime resources (world_sheet.tres + portrait.png +
## combat_sprite.png + full_body_illustration.png) into a scrollable grid:
##   - left: portrait, combat sprite and full-body illustration
##   - right: every state x every direction (first frame), and the down-direction
##     frame strip for each state
##
## Read-only. Useful for eyeballing the generated art and checking that the
## direction rows / animation poses read correctly at game scale.

const FRAME_W := 96
const FRAME_H := 128
const CELL := 120
const DIRECTION_LABELS := [
	"down", "down_right", "right", "up_right",
	"up", "up_left", "left", "down_left",
]


func _ready() -> void:
	theme = UITheme.build()
	var background := ColorRect.new()
	background.color = Color(0.07, 0.09, 0.15)
	UIFactory.set_full_rect(background)
	add_child(background)

	var scroll := ScrollContainer.new()
	UIFactory.set_full_rect(scroll)
	add_child(scroll)

	var root := VBoxContainer.new()
	root.custom_minimum_size = Vector2(2200, 1400)
	scroll.add_child(root)
	root.add_child(UIFactory.label("LILITH — playable art preview", 22, Color(0.9, 0.95, 1.0)))
	root.add_child(UIFactory.label(
		"world_sheet.tres: %d animations  ·  portrait.png: %dx%d  ·  combat_sprite.png: 128x192"
		% [MainCharacterRoster.world_sheet("lilith").get_animation_names().size(),
			MainCharacterRoster.PORTRAIT_W, MainCharacterRoster.PORTRAIT_H], 12, UITheme.TEXT_FAINT))

	_add_static_art(root)
	_add_direction_grid(root)
	_add_frame_strips(root)


func _add_static_art(root: VBoxContainer) -> void:
	var row := UIFactory.hbox(24)
	row.add_child(UIFactory.label("PORTRAIT", 12, UITheme.TEXT_FAINT))
	var portrait_path := MainCharacterRoster.portrait_path("lilith")
	if ResourceLoader.exists(portrait_path):
		var portrait := TextureRect.new()
		portrait.texture = load(portrait_path)
		portrait.custom_minimum_size = Vector2(256, 384)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(portrait)
	row.add_child(UIFactory.spacer())

	row.add_child(UIFactory.label("COMBAT", 12, UITheme.TEXT_FAINT))
	var combat_path := MainCharacterRoster.combat_sprite_path("lilith")
	if ResourceLoader.exists(combat_path):
		var combat := TextureRect.new()
		combat.texture = load(combat_path)
		combat.custom_minimum_size = Vector2(192, 288)
		combat.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(combat)
	row.add_child(UIFactory.spacer())

	row.add_child(UIFactory.label("FULL BODY", 12, UITheme.TEXT_FAINT))
	var full_path := MainCharacterRoster.full_body_path("lilith")
	if ResourceLoader.exists(full_path):
		var full := TextureRect.new()
		full.texture = load(full_path)
		full.custom_minimum_size = Vector2(256, 512)
		full.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(full)
	root.add_child(row)


func _add_direction_grid(root: VBoxContainer) -> void:
	root.add_child(UIFactory.label("FIRST FRAME PER STATE x DIRECTION", 14, Color(0.9, 0.95, 1.0)))
	var sheet: SpriteFrames = MainCharacterRoster.world_sheet("lilith")
	if sheet == null:
		root.add_child(UIFactory.label("world_sheet.tres did not load", 12, UITheme.TEXT_FAINT))
		return
	for raw_state in CharacterAnimator.EXTENDED_STATES:
		var state := int(raw_state)
		var state_name := CharacterAnimator.state_name(state)
		var row := UIFactory.hbox(8)
		row.add_child(UIFactory.label("%-8s" % state_name, 12, UITheme.TEXT_FAINT))
		for raw_dir in CharacterAnimator.ALL_DIRECTIONS:
			var dir := int(raw_dir)
			var cell := VBoxContainer.new()
			cell.custom_minimum_size = Vector2(CELL, CELL + 22)
			var tex := sheet.get_frame_texture(StringName("%s_%d" % [state_name, dir]), 0)
			if tex != null:
				var view := TextureRect.new()
				view.texture = tex
				view.custom_minimum_size = Vector2(CELL, CELL)
				view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				cell.add_child(view)
			cell.add_child(UIFactory.label(DIRECTION_LABELS[dir], 9, UITheme.TEXT_FAINT))
			row.add_child(cell)
		root.add_child(row)


func _add_frame_strips(root: VBoxContainer) -> void:
	root.add_child(UIFactory.label("DOWN-DIRECTION FRAME STRIPS", 14, Color(0.9, 0.95, 1.0)))
	var sheet: SpriteFrames = MainCharacterRoster.world_sheet("lilith")
	if sheet == null:
		return
	for raw_state in CharacterAnimator.EXTENDED_STATES:
		var state := int(raw_state)
		var state_name := CharacterAnimator.state_name(state)
		var row := UIFactory.hbox(4)
		row.add_child(UIFactory.label("%-8s" % state_name, 12, UITheme.TEXT_FAINT))
		var anim := StringName("%s_0" % state_name)
		for i in sheet.get_frame_count(anim):
			var tex := sheet.get_frame_texture(anim, i)
			if tex == null:
				continue
			var view := TextureRect.new()
			view.texture = tex
			view.custom_minimum_size = Vector2(72, 96)
			view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(view)
		root.add_child(row)
