class_name PortraitView
extends Control
## Original procedural character portrait. This is placeholder art, drawn from
## the same palette data the world actors use, so every character is visually
## distinct without shipping third-party images. The public API stays stable
## when final painted portraits arrive.
##
## Phase 5 presentation seam: ZERO final painted portraits exist. For every one
## of the 12 characters PortraitAssetSource.texture_for(<id>, "hud") returns
## null, so the procedural fallback below is the ACTIVE rendering path. When a
## real validated portrait is dropped at the expected path, portrait_texture is
## used instead and the procedural base is skipped — but the sigil / rarity
## frame / dim overlays are ALWAYS drawn on top. No image/binary art file is
## created here.

var palette: Dictionary = {}
var race: String = "Human"
var element: String = "neutral"
var rarity: String = "common"
var seed_value: int = 0
var dim: bool = false
var selected: bool = false
var show_frame: bool = true

# Real-portrait seam. ZERO final portraits exist today, so portrait_texture is
# null for all characters and the procedural fallback stays active.
var character_id: String = ""
var portrait_texture: Texture2D = null
var show_rarity_effect: bool = true

var _time: float = 0.0
var _hair: Color = Color("#4a3020")
var _skin: Color = Color("#f3d7c0")
var _primary: Color = Color("#3f5a6b")
var _secondary: Color = Color("#c9a45a")
var _accent: Color = Color("#7fe3e0")


func _ready() -> void:
	# Preserve dimensions assigned by the parent before this node enters the
	# tree. The old unconditional 96x96 reset silently shrank featured summon
	# portraits and result-card portraits to HUD-icon size.
	if custom_minimum_size.x <= 0.0 or custom_minimum_size.y <= 0.0:
		custom_minimum_size = Vector2(96, 96)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_process(true)


func setup(
	p_palette: Dictionary,
	p_race: String = "Human",
	p_element: String = "neutral",
	p_rarity: String = "common",
	p_seed: int = 0
) -> void:
	# Raw palette path is always the procedural fallback (no real portrait).
	character_id = ""
	portrait_texture = null
	palette = p_palette
	race = p_race
	element = p_element
	rarity = p_rarity
	seed_value = p_seed
	_hair = Color(str(palette.get("hair", "#4a3020")))
	_skin = Color(str(palette.get("skin", "#f3d7c0")))
	_primary = Color(str(palette.get("primary", "#3f5a6b")))
	_secondary = Color(str(palette.get("secondary", "#c9a45a")))
	_accent = Color(str(palette.get("accent", "#7fe3e0")))
	queue_redraw()


func setup_character(definition: CharacterDef, p_rarity: String = "") -> void:
	if definition == null:
		return
	setup(
		definition.palette,
		definition.race,
		definition.element,
		p_rarity if not p_rarity.is_empty() else definition.rarity,
		definition.portrait_seed
	)
	# setup() clears these, so set them AFTER the call. A character's FINAL
	# portrait (the protagonists) is looked up through its registered
	# playable-art path first; the twelve collectible characters have none, so
	# PortraitAssetSource returns null and the procedural fallback stays the
	# active rendering path for them.
	character_id = definition.id
	portrait_texture = MainCharacterRoster.portrait_texture(definition.id)
	if portrait_texture == null:
		portrait_texture = PortraitAssetSource.texture_for(definition.id, "hud")


## Inject a real validated painted portrait (the future seam). When null, the
## procedural fallback is restored.
func set_portrait_texture(tex: Texture2D) -> void:
	portrait_texture = tex
	queue_redraw()


## Honest report of the active rendering path. ZERO final portraits today means
## has_texture == false, texture_source == "none" and fallback_active == true.
func portrait_report() -> Dictionary:
	return {
		"character_id": character_id,
		"has_texture": portrait_texture != null,
		"texture_source": "disk" if portrait_texture != null else "none",
		"fallback_active": portrait_texture == null,
		"rarity": rarity,
		"premium": UITheme.is_premium_rarity(rarity),
		"show_rarity_effect": show_rarity_effect,
	}


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 2.0 or h <= 2.0:
		return
	var unit := minf(w, h)
	var center := Vector2(w * 0.5, h * 0.56)
	var head_radius := unit * 0.155
	var head_center := Vector2(w * 0.5, h * 0.43)

	# Additive premium aura drawn BEFORE the base (behind everything).
	_draw_rarity_aura(w, h, unit)

	# ZERO final portraits: portrait_texture == null for all 12 characters, so
	# the procedural BASE is the active rendering path. A real validated texture
	# replaces only the base; the overlays below ALWAYS run either way.
	if portrait_texture == null:
		_draw_procedural_base(w, h, unit)
	else:
		draw_texture_rect(portrait_texture, Rect2(Vector2.ZERO, size), false)

	# Painted portraits already contain their own species details; only the
	# procedural fallback needs the extra race ornament drawn over the base.
	if portrait_texture == null:
		_draw_race_details(w, h, head_center, head_radius)

	# Element sigil (unchanged).
	var sigil_center := Vector2(w * 0.82, h * 0.18)
	var sigil_color := UITheme.element_color(element)
	draw_circle(sigil_center, unit * 0.075, Color(0.02, 0.03, 0.06, 0.82))
	draw_arc(sigil_center, unit * 0.075, 0, TAU, 18, Color(sigil_color.r, sigil_color.g, sigil_color.b, 0.85), 1.5)
	draw_colored_polygon(PackedVector2Array([
		sigil_center + Vector2(0, -unit * 0.040),
		sigil_center + Vector2(unit * 0.034, 0),
		sigil_center + Vector2(0, unit * 0.040),
		sigil_center + Vector2(-unit * 0.034, 0),
	]), sigil_color)

	if show_frame:
		var frame_color := UITheme.rarity_color(rarity)
		var thickness := 3.0 if selected else 2.0
		draw_rect(Rect2(Vector2.ZERO, size), Color(frame_color.r, frame_color.g, frame_color.b, 0.95), false, thickness)
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(0, 0, 0, 0.35), false, 1.0)
		draw_line(Vector2(w * 0.08, h * 0.94), Vector2(w * 0.92, h * 0.94), Color(frame_color.r, frame_color.g, frame_color.b, 0.35), 1.0)

	# Premium rarity: an extra inner accent frame AFTER the existing frame.
	if show_frame and show_rarity_effect and UITheme.is_premium_rarity(rarity):
		var frame_effect := UITheme.rarity_effect(rarity)
		var frame_glow: Color = frame_effect.get("glow", UITheme.GOLD_BRIGHT)
		draw_rect(Rect2(Vector2(6, 6), size - Vector2(12, 12)), Color(frame_glow.r, frame_glow.g, frame_glow.b, 0.30), false, 1.0)

	if dim:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.05, 0.62))


## Cheap, deterministic premium aura (a handful of draw calls). Only legendary /
## mythic draw it, and only when show_rarity_effect is enabled. Uses _time gently.
func _draw_rarity_aura(w: float, h: float, unit: float) -> void:
	if not show_rarity_effect or not UITheme.is_premium_rarity(rarity):
		return
	var effect := UITheme.rarity_effect(rarity)
	var glow: Color = effect.get("glow", UITheme.GOLD_BRIGHT)
	var aura := clampf(float(effect.get("aura", 0.0)), 0.0, 1.0)
	var pulse := 0.85 + 0.15 * sin(_time * 1.1)
	var c := Vector2(w * 0.5, h * 0.44)
	for i in 3:
		var radius := unit * (0.52 - float(i) * 0.08)
		var alpha := aura * 0.16 * pulse / (float(i) + 1.0)
		draw_circle(c, radius, Color(glow.r, glow.g, glow.b, alpha))
	draw_rect(Rect2(0.0, h * 0.05, w, h * 0.015), Color(glow.r, glow.g, glow.b, aura * 0.22 * pulse))
	draw_rect(Rect2(0.0, h * 0.935, w, h * 0.015), Color(glow.r, glow.g, glow.b, aura * 0.22 * pulse))


## Procedural BASE (backdrop + body/head/hair/eyes), verbatim from the original
## _draw(). Guarded behind `if portrait_texture == null` by the caller so real
## art can replace it while every overlay above still runs. No drawing code here
## was changed — only relocated.
func _draw_procedural_base(w: float, h: float, unit: float) -> void:
	# Layered backdrop: deep indigo to the character's own colour.
	for index in 18:
		var t := float(index) / 17.0
		var color := UITheme.BG_SOFT.lerp(_primary.darkened(0.55), t * 0.9)
		color.a = 1.0
		draw_rect(Rect2(0, h * t, w, h / 17.0 + 1.0), color)
	draw_circle(Vector2(w * 0.5, h * 0.42), unit * 0.48, Color(_accent.r, _accent.g, _accent.b, 0.06))
	draw_circle(Vector2(w * 0.5, h * 0.42), unit * 0.30, Color(_accent.r, _accent.g, _accent.b, 0.05))

	# Distant foliage / stained-glass arcs.
	for index in 4:
		var angle := -PI * 0.86 + float(index) * PI * 0.24 + sin(_time * 0.3 + index) * 0.02
		var radius := unit * (0.56 + 0.04 * (index % 2))
		var origin := Vector2(w * 0.5, h * 0.52)
		draw_arc(origin, radius, angle, angle + PI * 0.12, 10, Color(_accent.r, _accent.g, _accent.b, 0.10), 2.0)

	# Shoulders and cape.
	var shoulder_y := h * 0.78
	var neck_y := h * 0.55
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.12, h * 1.02),
		Vector2(w * 0.20, shoulder_y),
		Vector2(w * 0.38, h * 0.66),
		Vector2(w * 0.62, h * 0.66),
		Vector2(w * 0.80, shoulder_y),
		Vector2(w * 0.88, h * 1.02),
	]), _primary.darkened(0.18))
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.30, h * 0.68),
		Vector2(w * 0.50, h * 0.60),
		Vector2(w * 0.70, h * 0.68),
		Vector2(w * 0.58, h * 1.02),
		Vector2(w * 0.42, h * 1.02),
	]), _primary.lightened(0.05))
	draw_rect(Rect2(w * 0.42, h * 0.74, w * 0.16, h * 0.04), _secondary)

	# Neck and head.
	draw_rect(Rect2(w * 0.45, h * 0.53, w * 0.10, h * 0.10), _skin.darkened(0.06))
	var head_radius := unit * 0.155
	var head_center := Vector2(w * 0.5, h * 0.43)
	draw_circle(head_center, head_radius * 1.08, _hair.darkened(0.28))
	draw_circle(head_center, head_radius, _skin)

	# Hair silhouette with a deterministic parting. Each piece is convex so the
	# renderer never has to triangulate a self-intersecting fringe.
	var part := (float(seed_value % 7) - 3.0) * 0.018
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * (0.32 + part), h * 0.44),
		Vector2(w * 0.34, h * 0.28),
		Vector2(w * 0.50, h * 0.22),
		Vector2(w * 0.68, h * 0.28),
		Vector2(w * (0.70 + part), h * 0.44),
	]), _hair)
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.34, h * 0.30),
		Vector2(w * 0.46, h * 0.32),
		Vector2(w * 0.38, h * 0.41),
	]), _hair)
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.46, h * 0.32),
		Vector2(w * 0.58, h * 0.32),
		Vector2(w * 0.50, h * 0.42),
	]), _hair)
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.58, h * 0.32),
		Vector2(w * 0.68, h * 0.30),
		Vector2(w * 0.63, h * 0.41),
	]), _hair)
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.38, h * 0.30),
		Vector2(w * 0.50, h * 0.26),
		Vector2(w * 0.62, h * 0.30),
		Vector2(w * 0.50, h * 0.34),
	]), _hair.lightened(0.10))

	# Eyes.
	var eye_y := h * 0.445
	var eye_dx := unit * 0.052
	draw_circle(Vector2(w * 0.5 - eye_dx, eye_y), unit * 0.021, Color("#1b2233"))
	draw_circle(Vector2(w * 0.5 + eye_dx, eye_y), unit * 0.021, Color("#1b2233"))
	draw_circle(Vector2(w * 0.5 - eye_dx + unit * 0.006, eye_y - unit * 0.005), unit * 0.008, _accent)
	draw_circle(Vector2(w * 0.5 + eye_dx + unit * 0.006, eye_y - unit * 0.005), unit * 0.008, _accent)
	draw_line(
		Vector2(w * 0.5 - unit * 0.018, h * 0.505),
		Vector2(w * 0.5 + unit * 0.018, h * 0.505),
		_secondary.darkened(0.15),
		1.2
	)


func _draw_race_details(w: float, h: float, head_center: Vector2, head_radius: float) -> void:
	match race:
		"Elf":
			draw_colored_polygon(PackedVector2Array([
				head_center + Vector2(-head_radius * 0.85, -head_radius * 0.10),
				head_center + Vector2(-head_radius * 1.65, -head_radius * 0.55),
				head_center + Vector2(-head_radius * 0.70, head_radius * 0.35),
			]), _skin)
			draw_colored_polygon(PackedVector2Array([
				head_center + Vector2(head_radius * 0.85, -head_radius * 0.10),
				head_center + Vector2(head_radius * 1.65, -head_radius * 0.55),
				head_center + Vector2(head_radius * 0.70, head_radius * 0.35),
			]), _skin)
		"Beastkin":
			draw_colored_polygon(PackedVector2Array([
				head_center + Vector2(-head_radius * 0.75, -head_radius * 0.70),
				head_center + Vector2(-head_radius * 1.05, -head_radius * 1.75),
				head_center + Vector2(-head_radius * 0.18, -head_radius * 0.85),
			]), _hair)
			draw_colored_polygon(PackedVector2Array([
				head_center + Vector2(head_radius * 0.75, -head_radius * 0.70),
				head_center + Vector2(head_radius * 1.05, -head_radius * 1.75),
				head_center + Vector2(head_radius * 0.18, -head_radius * 0.85),
			]), _hair)
		"Demon":
			draw_colored_polygon(PackedVector2Array([
				head_center + Vector2(-head_radius * 0.70, -head_radius * 0.80),
				head_center + Vector2(-head_radius * 1.05, -head_radius * 1.70),
				head_center + Vector2(-head_radius * 0.24, -head_radius * 0.88),
			]), _secondary)
			draw_colored_polygon(PackedVector2Array([
				head_center + Vector2(head_radius * 0.70, -head_radius * 0.80),
				head_center + Vector2(head_radius * 1.05, -head_radius * 1.70),
				head_center + Vector2(head_radius * 0.24, -head_radius * 0.88),
			]), _secondary)
		"Angel":
			draw_arc(head_center + Vector2(0, -head_radius * 1.30), head_radius * 0.60, PI * 0.12, PI * 0.88, 16, Color(1.0, 0.92, 0.6, 0.9), 2.0)
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.22, h * 0.72),
				Vector2(w * 0.04, h * 0.56),
				Vector2(w * 0.18, h * 0.92),
			]), Color(1.0, 0.98, 0.9, 0.22))
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.78, h * 0.72),
				Vector2(w * 0.96, h * 0.56),
				Vector2(w * 0.82, h * 0.92),
			]), Color(1.0, 0.98, 0.9, 0.22))
		"Vampire":
			draw_line(head_center + Vector2(-head_radius * 0.45, head_radius * 0.10), head_center + Vector2(head_radius * 0.45, head_radius * 0.10), _secondary, 1.4)
			draw_colored_polygon(PackedVector2Array([
				head_center + Vector2(-head_radius * 0.18, head_radius * 0.34),
				head_center + Vector2(-head_radius * 0.10, head_radius * 0.55),
				head_center + Vector2(-head_radius * 0.02, head_radius * 0.34),
			]), Color("#fff4f8"))
			draw_colored_polygon(PackedVector2Array([
				head_center + Vector2(head_radius * 0.02, head_radius * 0.34),
				head_center + Vector2(head_radius * 0.10, head_radius * 0.55),
				head_center + Vector2(head_radius * 0.18, head_radius * 0.34),
			]), Color("#fff4f8"))
		"Spirit":
			draw_circle(head_center, head_radius * 1.45, Color(_accent.r, _accent.g, _accent.b, 0.10))
			draw_circle(head_center + Vector2(-head_radius * 1.0, -head_radius * 1.1), 2.0, _accent)
			draw_circle(head_center + Vector2(head_radius * 1.1, -head_radius * 1.35), 1.4, _accent)
		"Ancient":
			draw_line(head_center + Vector2(-head_radius * 0.9, -head_radius * 0.3), head_center + Vector2(-head_radius * 1.5, head_radius * 0.1), _secondary, 2.0)
			draw_line(head_center + Vector2(head_radius * 0.9, -head_radius * 0.3), head_center + Vector2(head_radius * 1.5, head_radius * 0.1), _secondary, 2.0)
			draw_line(head_center + Vector2(-head_radius * 0.2, -head_radius * 0.6), head_center + Vector2(head_radius * 0.1, -head_radius * 0.2), _accent, 1.0)
		"Mermaid":
			draw_circle(head_center + Vector2(0, -head_radius * 1.15), 2.2, _accent)
			draw_line(head_center + Vector2(-head_radius * 0.55, head_radius * 0.15), head_center + Vector2(head_radius * 0.55, head_radius * 0.15), _accent, 1.2)
		"Monster Girl":
			for index in 3:
				var angle := -PI * 0.78 + index * 0.18
				draw_line(
					head_center + Vector2(cos(angle), sin(angle)) * head_radius * 0.8,
					head_center + Vector2(cos(angle), sin(angle)) * head_radius * 1.35,
					_secondary,
					1.4
				)
		"Dragonkin":
			draw_colored_polygon(PackedVector2Array([
				head_center + Vector2(-head_radius * 0.65, -head_radius * 0.82),
				head_center + Vector2(-head_radius * 0.95, -head_radius * 1.55),
				head_center + Vector2(-head_radius * 0.18, -head_radius * 0.90),
			]), _secondary)
			draw_colored_polygon(PackedVector2Array([
				head_center + Vector2(head_radius * 0.65, -head_radius * 0.82),
				head_center + Vector2(head_radius * 0.95, -head_radius * 1.55),
				head_center + Vector2(head_radius * 0.18, -head_radius * 0.90),
			]), _secondary)
