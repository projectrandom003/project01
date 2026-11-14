class_name ForestTree
extends Node2D
## Reusable forest tree prototype (node-first). Uses existing glade_tree artwork
## split into always-visible trunk/shadow and a canopy that can fade via
## AnimationPlayer when the player is underneath (Area2D + signals).

signal canopy_fade_requested
signal canopy_restore_requested

@export var prop_kind: String = "glade_tree"
@export var variant: int = 0
@export var wind_enabled: bool = true

@onready var shadow_sprite: Sprite2D = $Shadow
@onready var trunk_sprite: Sprite2D = $Trunk
@onready var canopy_sprite: Sprite2D = $Canopy
@onready var occlusion_area: Area2D = $OcclusionArea
@onready var anim: AnimationPlayer = $AnimationPlayer

var _occluders: int = 0


func _ready() -> void:
	if not occlusion_area.body_entered.is_connected(_on_body_entered):
		occlusion_area.body_entered.connect(_on_body_entered)
	if not occlusion_area.body_exited.is_connected(_on_body_exited):
		occlusion_area.body_exited.connect(_on_body_exited)
	_apply_art()


func setup(kind: String, v: int, flip_h: bool = false, p_scale: float = 1.0, wind_mat: Material = null) -> void:
	prop_kind = kind
	variant = v
	scale = Vector2.ONE * p_scale
	if is_node_ready():
		_apply_art(wind_mat)
	else:
		# store for ready; material applied in _apply_art
		set_meta("_wind_mat", wind_mat)
		set_meta("_flip", flip_h)
	_apply_flip_and_wind(flip_h, wind_mat)

func apply_variation(vres: Resource) -> void:
	if vres == null:
		return
	if "kind" in vres and String(vres.kind) != "": prop_kind = String(vres.kind)
	if "variant" in vres: variant = int(vres.variant)
	if "scale" in vres: scale = Vector2.ONE * float(vres.scale)
	if "wind_enabled" in vres: wind_enabled = bool(vres.wind_enabled)
	var flip_h := bool(vres.flip_h) if "flip_h" in vres else bool(get_meta("_flip", false))
	var wind_mat: Material = get_meta("_wind_mat", null) if has_meta("_wind_mat") else null
	if is_node_ready():
		_apply_art(wind_mat)
	_apply_flip_and_wind(flip_h, wind_mat)
	if shadow_sprite != null and "shadow_enabled" in vres:
		shadow_sprite.visible = bool(vres.shadow_enabled)


func _apply_flip_and_wind(flip_h: bool, wind_mat: Material) -> void:
	for s in [shadow_sprite, trunk_sprite, canopy_sprite]:
		if s:
			s.flip_h = flip_h
	if wind_enabled and wind_mat != null and canopy_sprite:
		canopy_sprite.material = wind_mat
	# keep trunk/shadow stable (no sway) so they remain readable


func _apply_art(wind_mat: Material = null) -> void:
	var tex := ProceduralArt.prop_texture(prop_kind, variant)
	if tex == null:
		return
	var img: Image = tex.get_image()
	if img == null:
		# fallback: show full art on canopy only
		canopy_sprite.texture = tex
		trunk_sprite.texture = null
		shadow_sprite.texture = null
		_configure_layout(tex)
		return
	var w := img.get_width()
	var h := img.get_height()
	# Split existing glade_tree artwork: trunk+shadow remain visible, canopy fades.
	# Heuristic split around upper trunk/crown join for non-ancient tree art.
	var split_y := int(float(h) * 0.58)
	var trunk_img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	trunk_img.fill(Color(0, 0, 0, 0))
	var canopy_img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	canopy_img.fill(Color(0, 0, 0, 0))
	for y in h:
		for x in w:
			var col := img.get_pixel(x, y)
			if y >= split_y:
				trunk_img.set_pixel(x, y, col)
			else:
				canopy_img.set_pixel(x, y, col)
	var trunk_tex := ImageTexture.create_from_image(trunk_img)
	var canopy_tex := ImageTexture.create_from_image(canopy_img)
	trunk_sprite.texture = trunk_tex
	shadow_sprite.texture = null # shadow baked into trunk/lower art for this prototype
	canopy_sprite.texture = canopy_tex
	_configure_layout(tex)
	var flip_h := bool(get_meta("_flip", false))
	var wm: Material = wind_mat
	if wm == null and has_meta("_wind_mat"):
		wm = get_meta("_wind_mat")
	_apply_flip_and_wind(flip_h, wm)


func _configure_layout(tex: Texture2D) -> void:
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	var off := Vector2(-w * 0.5, -h + 6.0)
	for s in [shadow_sprite, trunk_sprite, canopy_sprite]:
		if s == null:
			continue
		s.centered = false
		s.offset = off
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Detect the player's GROUND ANCHOR beneath the canopy, not the
	# canopy pixels themselves. Player collision bodies sit around y=-22..0;
	# the old box at -0.55h floated far above them, so canopy_fade never fired
	# and foreground trees completely hid the player in the live village.
	if occlusion_area:
		var shape_node := occlusion_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape_node and shape_node.shape is RectangleShape2D:
			var rect := shape_node.shape as RectangleShape2D
			rect.size = Vector2(w * 0.72, maxf(32.0, h * 0.26))
			shape_node.position = Vector2(0, -h * 0.08)


func _on_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	_occluders += 1
	if _occluders == 1:
		canopy_fade_requested.emit()
		if anim and anim.has_animation("canopy_fade"):
			anim.play("canopy_fade")


func _on_body_exited(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	_occluders = maxi(0, _occluders - 1)
	if _occluders == 0:
		canopy_restore_requested.emit()
		if anim and anim.has_animation("canopy_restore"):
			anim.play("canopy_restore")
