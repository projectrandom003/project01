class_name ActorSpriteComponent
extends Node
## Owns ActorVisual's frame-backed Sprite2D source, geometry and frame presentation.
## ActorVisual remains the public API and authoritative animation/data state.

var visual


func bind(owner_visual) -> void:
	visual = owner_visual


func set_frame_source(source: ActorFrameSource) -> void:
	if visual == null:
		return
	if source == null:
		visual._custom_source = false
		visual.frame_source = ProceduralActorFrames.new(visual.palette, visual.is_boss)
		visual.using_temporary_art = true
		visual._sprite_active = false
		hide_sprite()
		visual._queue_visual_redraw()
		return
	visual._custom_source = true
	visual.frame_source = source
	visual.using_temporary_art = source.is_temporary()
	visual._last_sprite_key = -1
	visual._sprite_active = source.has_frames()
	if visual._sprite_active:
		ensure_sprite()
		update_sprite_frame()
	else:
		hide_sprite()
		visual._queue_visual_redraw()


func configure_character(character_id: String) -> Dictionary:
	if visual == null:
		return {"character_id": character_id, "registered": false, "fallback_active": true}
	visual.character_id = character_id
	var source: ActorFrameSource = SpriteFramesActorSource.register_playable(character_id)
	var registered := false
	if source != null and source.has_frames() and source.validate_sheets().is_empty():
		set_frame_source(source)
		registered = true
	return {
		"character_id": character_id,
		"registered": registered,
		"fallback_active": not registered,
		"using_temporary_art": visual.using_temporary_art,
		"source": visual.frame_source.source_label() if visual.frame_source != null else "",
	}


func character_art_report() -> Dictionary:
	if visual == null:
		return {}
	var source: ActorFrameSource = visual.frame_source
	var has_frames := false
	var is_temporary := true
	var animation_count := 0
	var source_label := ""
	if source != null:
		has_frames = source.has_frames()
		is_temporary = source.is_temporary()
		source_label = source.source_label()
		if source.has_method("load_report"):
			var report: Variant = source.call("load_report")
			if report is Dictionary:
				animation_count = int((report as Dictionary).get("animation_count", 0))
	return {
		"character_id": visual.character_id,
		"frame_source": source_label,
		"using_temporary_art": visual.using_temporary_art,
		"has_frames": has_frames,
		"is_temporary": is_temporary,
		"animation_count": animation_count,
	}


func ensure_sprite() -> void:
	if visual == null or not visual.is_inside_tree():
		return
	if visual._sprite == null:
		visual._sprite = visual.get_node_or_null("FrameSprite") as Sprite2D
	if visual._sprite == null:
		visual._sprite = Sprite2D.new()
		visual._sprite.name = "FrameSprite"
		visual.add_child(visual._sprite)
	visual._sprite.centered = false
	visual._sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visual._sprite.visible = false


func hide_sprite() -> void:
	if visual != null and visual._sprite != null:
		visual._sprite.visible = false
	if visual != null:
		visual._last_sprite_key = -1


func mirrors_by_facing() -> bool:
	return visual == null or visual.frame_source == null or visual.frame_source.mirrors_by_facing()


func set_body_scale(value: float) -> void:
	if visual == null:
		return
	visual._base_visual_scale = clampf(value, 0.45, 4.5)
	visual.visual_scale = visual._base_visual_scale
	if visual._sprite != null and visual._sprite.texture != null:
		apply_sprite_geometry()
	visual._apply_effects_geometry()


func apply_sprite_geometry() -> void:
	if visual == null or visual._sprite == null or visual._sprite.texture == null:
		return
	var texture: Texture2D = visual._sprite.texture
	var anchor_value: Variant = GreenwardStyle.SPRITE_SPECS.get("anchor", Vector2(0.5, 1.0))
	var anchor: Vector2 = anchor_value if anchor_value is Vector2 else Vector2(0.5, 1.0)
	visual._sprite.centered = false
	visual._sprite.offset = Vector2(-float(texture.get_width()) * anchor.x, -float(texture.get_height()) * anchor.y)
	visual._sprite.scale = Vector2.ONE * visual.visual_scale
	visual._sprite.flip_h = visual.facing < 0.0 and mirrors_by_facing()


func update_sprite_frame() -> void:
	if visual == null or visual._sprite == null or visual.frame_source == null or not visual._sprite_active:
		return
	var key: int = (visual.animator.state << 16) | (visual.animator.direction << 8) | visual.animator.frame
	if key == visual._last_sprite_key and visual._sprite.visible:
		return
	var texture: Texture2D
	if visual.animator.state == CharacterAnimator.CAST_STATE:
		texture = visual.frame_source.cast_frame(visual.animator.direction, visual.animator.frame)
		if texture == null:
			texture = visual.frame_source.frame(visual.animator.state, visual.animator.direction, visual.animator.frame)
	else:
		texture = visual.frame_source.frame(visual.animator.state, visual.animator.direction, visual.animator.frame)
	if texture == null:
		visual._sprite_active = false
		hide_sprite()
		visual._queue_visual_redraw()
		return
	visual._last_sprite_key = key
	visual._sprite.texture = texture
	apply_sprite_geometry()
	visual._sprite.visible = true
	visual._queue_visual_redraw()
