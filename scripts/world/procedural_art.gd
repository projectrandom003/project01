class_name ProceduralArt
extends RefCounted
## Original, code-generated placeholder art. Everything here is drawn from
## scratch at runtime so the project has zero third-party assets.
##
## This is intentionally a placeholder pipeline: final art will replace these
## textures through the same prop_texture() / soft_glow() interfaces. Sizes and
## naming are stable so real sprites can be dropped in without scene rewrites.
##
## COLOUR AUTHORITY: every NEW painter sources its colours from GreenwardStyle
## (the single source of truth). The original twelve painters keep their inline
## hex literals so that `variant 0` reproduces the shipped look exactly.
##
## character_frame() below produces CLEARLY MARKED TEMPORARY PLACEHOLDER frames
## for the character animation pipeline. They are NOT final sprite-sheet art:
## they are simple coherent humanoid poses that differ per state/direction/frame
## so downstream animation code has real, distinct frames to loop. Replace them
## with painted sheets via the ART_PIPELINE.md workflow.

# Caches are static: generated once per (kind, variant) / (palette, pose) and
# reused. clear_cache() resets everything (handy for tests / hot reload).
static var _prop_cache: Dictionary = {}
static var _glow_cache: Dictionary = {}
static var _frame_cache: Dictionary = {}
static var _white: Texture2D

# First authored Greenward environment sprites. These are real imported SVG
# assets, not runtime polygon painters. The procedural painters remain as a
# graceful fallback for every not-yet-replaced prop kind.
const AUTHORED_ENVIRONMENT := {
	"willow_tree": "res://assets/environment/greenward/willow_tree.svg",
	"birch_tree": "res://assets/environment/moonpetal/silver_birch.svg",
	"pine_tree": "res://assets/environment/greenward/pine_tree.svg",
	"blossom_tree": "res://assets/environment/greenward/blossom_tree.svg",
	"dead_tree": "res://assets/environment/greenward/dead_tree.svg",
	"bush": "res://assets/environment/greenward/forest_shrub.svg",
	"spirit_bloom": "res://assets/environment/moonpetal/spirit_bloom.svg",
	"moon_lantern": "res://assets/environment/moonpetal/moon_lantern.svg",
	"ancient_tree": "res://assets/environment/greenward/ancient_oak.svg",
	"moss_rock": "res://assets/environment/greenward/moss_rock.svg",
	"cottage": "res://assets/environment/greenward/woodland_cottage.svg",
	"fern": "res://assets/environment/greenward/fern.svg",
	"flower_cluster": "res://assets/environment/greenward/wildflower_patch.svg",
	"stone_bridge": "res://assets/environment/greenward/stone_bridge.svg",
}


# ------------------------------------------------------------------ public API

## Return a cached prop texture. `variant` selects a deterministic, visually
## distinct silhouette/petal-arrangement/hue variation; variant 0 is the base
## look. The cache key includes the variant. Unknown kinds fall back gracefully.
static func prop_texture(kind: String, variant: int = 0) -> Texture2D:
	var key := "%s|%d" % [kind, variant]
	if _prop_cache.has(key):
		return _prop_cache[key]
	# Authored SVGs are loaded directly by Godot's SVG importer. Keep variants
	# on the same hand-painted silhouette until dedicated variant art exists.
	if AUTHORED_ENVIRONMENT.has(kind):
		var authored_path := str(AUTHORED_ENVIRONMENT[kind])
		if ResourceLoader.exists(authored_path):
			var authored := load(authored_path) as Texture2D
			if authored != null:
				if variant <= 0:
					_prop_cache[key] = authored
					return authored
				# Authored SVGs still honour the existing deterministic variant
				# contract: clone the imported pixels, then add the same kind-aware
				# hue/geometry accents used by procedural props.
				var authored_image := authored.get_image()
				if authored_image != null:
					var varied_image := authored_image.duplicate()
					_apply_variant(varied_image, kind, variant)
					var varied_texture := ImageTexture.create_from_image(varied_image)
					_prop_cache[key] = varied_texture
					return varied_texture
	var image: Image = _build_prop(kind, variant)
	var texture := ImageTexture.create_from_image(image)
	_prop_cache[key] = texture
	return texture


## Unchanged signature/semantics: cached radial soft glow (used for lights).
static func soft_glow(color: Color = Color.WHITE, size: int = 64) -> Texture2D:
	var key := "%s_%d" % [color.to_html(), size]
	if _glow_cache.has(key):
		return _glow_cache[key]
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(size, size) * 0.5
	var radius := size * 0.5
	for y in size:
		for x in size:
			var distance := Vector2(x + 0.5, y + 0.5).distance_to(center) / radius
			var alpha := clampf(1.0 - distance, 0.0, 1.0)
			alpha = alpha * alpha * alpha
			if alpha > 0.003:
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha * color.a))
	var texture := ImageTexture.create_from_image(image)
	_glow_cache[key] = texture
	return texture


## Unchanged signature/semantics: a tiny cached opaque white texture.
static func white_pixel() -> Texture2D:
	if _white == null:
		var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(image)
	return _white


## Every supported prop kind (sourced from the shared style authority).
static func prop_kinds() -> Array[String]:
	return GreenwardStyle.prop_kinds()


## Audits authored sprites against the canonical prop catalogue. Missing kinds
## are explicit and continue using the procedural fallback pipeline.
static func authored_environment_report() -> Dictionary:
	var authored: Array[String] = []
	var fallback: Array[String] = []
	var invalid: Array[String] = []
	for kind in GreenwardStyle.prop_kinds():
		if not AUTHORED_ENVIRONMENT.has(kind):
			fallback.append(kind)
			continue
		var asset_path := str(AUTHORED_ENVIRONMENT[kind])
		if ResourceLoader.exists(asset_path):
			authored.append(kind)
		else:
			invalid.append("%s:%s" % [kind, asset_path])
	return {"authored": authored, "procedural_fallback": fallback, "invalid_assets": invalid,
		"total_kinds": GreenwardStyle.prop_kinds().size(), "authored_count": authored.size(),
		"fallback_count": fallback.size()}


## Number of distinct deterministic variants for a kind (>=2 for complex props).
static func variant_count(kind: String) -> int:
	return GreenwardStyle.variant_count(kind)


## TEMPORARY PLACEHOLDER character frame. Returns a cached, non-null RGBA8
## ImageTexture sized exactly GreenwardStyle.SPRITE_SPECS.world_width x
## world_height (96 x 128). The cache is keyed by (palette-hash, state,
## direction, frame_index); frames for different states/directions/frame_index
## genuinely differ in pixel content. Generated once, never per-frame.
## State ints: 0 IDLE, 1 WALK, 2 RUN, 3 INTERACT, 4 ATTACK, 5 DAMAGE,
##             6 VICTORY, 7 DEFEAT, 8 CAST (Phase-4 additive state). The CAST
##             branch adds a raised-arms pose + magic glow; the deterministic
##             signature already makes EVERY (state,direction,index) distinct,
##             so state 8 is non-null, cached and distinct even without it.
##             States 0-7 keep their original pixels byte-for-byte.
## Direction ints: 0 DOWN, 1 DOWN_RIGHT, 2 RIGHT, 3 UP_RIGHT, 4 UP,
##                 5 UP_LEFT, 6 LEFT, 7 DOWN_LEFT.
static func character_frame(palette: Dictionary, state: int, direction: int, frame_index: int) -> Texture2D:
	var key := "%d|%d|%d|%d" % [_palette_hash(palette), state, direction, frame_index]
	if _frame_cache.has(key):
		return _frame_cache[key]
	var width: int = GreenwardStyle.SPRITE_SPECS.world_width
	var height: int = GreenwardStyle.SPRITE_SPECS.world_height
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	ProceduralCharacterArt.draw_frame(image, palette, state, direction, frame_index)
	var texture := ImageTexture.create_from_image(image)
	_frame_cache[key] = texture
	return texture


## Drop every cached texture (props, glows, frames) and the white pixel.
static func clear_cache() -> void:
	_prop_cache.clear()
	_glow_cache.clear()
	_frame_cache.clear()
	_white = null


## Drop ONLY the static character-frame cache, leaving prop/glow caches intact.
## Used after an in-memory SpriteFrames has taken ownership of its frames, so
## the shared static cache no longer pins those ImageTextures (avoids headless
## dummy-renderer "leaked RID" reports at process shutdown). A later
## character_frame() call simply regenerates + re-caches as before.
static func clear_frame_cache() -> void:
	_frame_cache.clear()


## Explicit SHUTDOWN cleanup: release EVERY static cache reference (props,
## glows, character frames and the white pixel) at SceneTree teardown, BEFORE
## the headless dummy RenderingServer is finalized. GDScript static state lives
## on the script resource, which is freed only during global cleanup -- AFTER
## the renderer -- so any ImageTexture still pinned by a static dictionary would
## otherwise report a leaked DummyTexture RID at exit. Calling this from a node's
## _exit_tree() drops those references while the RenderingServer is still alive,
## so each cached texture frees its RID cleanly. All caches are lazy, so any
## later call in the same process simply regenerates deterministically.
static func clear_all_caches() -> void:
	clear_cache()


# ------------------------------------------------------------- build dispatch

static func _build_prop(kind: String, variant: int) -> Image:
	var image: Image = _paint_kind(kind)
	if variant > 0:
		_apply_variant(image, kind, variant)
	return image


static func _paint_kind(kind: String) -> Image:
	return ProceduralArtPropPainters.paint_kind(kind)


static func _new_image(width: int, height: int) -> Image:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return image


static func _blend_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	var destination := image.get_pixel(x, y)
	var alpha := color.a
	var out_alpha := alpha + destination.a * (1.0 - alpha)
	if out_alpha <= 0.001:
		return
	var red := (color.r * alpha + destination.r * destination.a * (1.0 - alpha)) / out_alpha
	var green := (color.g * alpha + destination.g * destination.a * (1.0 - alpha)) / out_alpha
	var blue := (color.b * alpha + destination.b * destination.a * (1.0 - alpha)) / out_alpha
	image.set_pixel(x, y, Color(red, green, blue, out_alpha))


static func _grain(x: int, y: int) -> float:
	var value := (x * 73856093) ^ (y * 19349663)
	return float(value & 255) / 255.0


static func _ellipse(image: Image, center: Vector2, radius: Vector2, color: Color, grain: float = 0.0) -> void:
	var min_x := maxi(0, int(center.x - radius.x) - 1)
	var max_x := mini(image.get_width() - 1, int(center.x + radius.x) + 1)
	var min_y := maxi(0, int(center.y - radius.y) - 1)
	var max_y := mini(image.get_height() - 1, int(center.y + radius.y) + 1)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var dx := (x + 0.5 - center.x) / maxf(0.001, radius.x)
			var dy := (y + 0.5 - center.y) / maxf(0.001, radius.y)
			if dx * dx + dy * dy <= 1.0:
				var pixel := color
				if grain > 0.0:
					var shift := (_grain(x, y) - 0.5) * grain
					pixel = Color(
						clampf(color.r + shift, 0.0, 1.0),
						clampf(color.g + shift, 0.0, 1.0),
						clampf(color.b + shift, 0.0, 1.0),
						color.a
					)
				_blend_pixel(image, x, y, pixel)


static func _polygon(image: Image, points: Array, color: Color) -> void:
	if points.size() < 3:
		return
	var min_y := 999999.0
	var max_y := -999999.0
	for point in points:
		min_y = minf(min_y, point.y)
		max_y = maxf(max_y, point.y)
	var start_y := maxi(0, int(floor(min_y)))
	var end_y := mini(image.get_height() - 1, int(ceil(max_y)))
	for y in range(start_y, end_y + 1):
		var nodes: Array = []
		var scan_y := float(y) + 0.5
		for index in points.size():
			var a: Vector2 = points[index]
			var b: Vector2 = points[(index + 1) % points.size()]
			if (a.y < scan_y and b.y >= scan_y) or (b.y < scan_y and a.y >= scan_y):
				var t := (scan_y - a.y) / (b.y - a.y)
				nodes.append(a.x + t * (b.x - a.x))
		nodes.sort()
		var pair := 0
		while pair + 1 < nodes.size():
			var left := maxi(0, int(ceil(nodes[pair] - 0.5)))
			var right := mini(image.get_width() - 1, int(floor(nodes[pair + 1] - 0.5)))
			for x in range(left, right + 1):
				_blend_pixel(image, x, y, color)
			pair += 2


static func _line(image: Image, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	var length := from.distance_to(to)
	var steps := maxi(1, int(length))
	for step in steps + 1:
		var point := from.lerp(to, float(step) / float(steps))
		_ellipse(image, point, Vector2(width, width), color)


static func _pc(palette: Dictionary, key: String) -> Color:
	var value: Variant = palette.get(key, GreenwardStyle.MAGIC.teal)
	if typeof(value) == TYPE_COLOR:
		return value
	return GreenwardStyle.MAGIC.teal


static func _shadow(image: Image, cx: float, by: float, rx: float, alpha: float = 0.25) -> void:
	_ellipse(image, Vector2(cx, by), Vector2(rx, rx * 0.32), Color(0.02, 0.05, 0.03, alpha))


static func _palette_hash(palette: Dictionary) -> int:
	var keys: Array = palette.keys()
	keys.sort()
	var text := ""
	for key in keys:
		text += "%s=%s;" % [str(key), var_to_str(palette[key])]
	return text.hash()


static func _frame_signature(state: int, direction: int, frame_index: int) -> int:
	return absi(("%d:%d:%d" % [state, direction, frame_index]).hash())


static func _as_color(value: Variant, fallback: Color) -> Color:
	if value == null:
		return fallback
	if typeof(value) == TYPE_COLOR:
		return value
	if typeof(value) == TYPE_STRING:
		var text: String = value
		if text.begins_with("#"):
			return Color(text)
	return fallback


static func _srand(seed: int, index: int) -> float:
	return _grain(seed + index * 131, seed * 7 + index * 977)


static func _hue_rotate(c: Color, amount: float) -> Color:
	# Self-contained RGB->HSV->RGB hue rotation (no reliance on optional
	# Color accessors), fully deterministic and alpha-preserving.
	var maxc := maxf(c.r, maxf(c.g, c.b))
	var minc := minf(c.r, minf(c.g, c.b))
	var delta := maxc - minc
	var h := 0.0
	if delta > 0.00001:
		if is_equal_approx(maxc, c.r):
			h = fmod((c.g - c.b) / delta, 6.0)
		elif is_equal_approx(maxc, c.g):
			h = (c.b - c.r) / delta + 2.0
		else:
			h = (c.r - c.g) / delta + 4.0
		h /= 6.0
		if h < 0.0:
			h += 1.0
	h = fmod(h + amount + 1.0, 1.0)
	var s := 0.0 if maxc <= 0.00001 else delta / maxc
	return _hsv_to_rgb(h, s, maxc, c.a)


static func _hsv_to_rgb(h: float, s: float, v: float, a: float) -> Color:
	var i := int(floor(h * 6.0))
	var f := h * 6.0 - float(i)
	var p := v * (1.0 - s)
	var q := v * (1.0 - f * s)
	var t := v * (1.0 - (1.0 - f) * s)
	match i % 6:
		0: return Color(v, t, p, a)
		1: return Color(q, v, p, a)
		2: return Color(p, v, t, a)
		3: return Color(p, q, v, a)
		4: return Color(t, p, v, a)
		_: return Color(v, p, q, a)
	return Color(v, p, q, a)


# --------------------------------------------------------------- variant engine
# Variants are DETERMINISTIC and VISUALLY DISTINCT: a subtle hue rotation plus
# genuinely different geometry (canopy clusters, petal arrangement, fronds,
# roof detail, sparkles) — never just a flat tint. No global RNG is used.

static func _apply_variant(image: Image, kind: String, variant: int) -> void:
	if variant <= 0:
		return
	var seed := absi(("%s#%d" % [kind, variant]).hash())
	var fseed := float(seed % 100000) / 100000.0
	var hue_amount := float(variant) * 0.02 + fseed * 0.05 - 0.025
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a <= 0.01:
				continue
			image.set_pixel(x, y, _hue_rotate(c, hue_amount))
	var p := GreenwardStyle.prop_palette(kind)
	var category := str(GreenwardStyle.KIND_CATEGORY.get(kind, "simple"))
	var cx := image.get_width() * 0.5
	var h := float(image.get_height())
	match category:
		"tree": _variant_tree(image, p, seed, cx, h)
		"flower": _variant_flower(image, p, seed, cx, h)
		"ground": _variant_ground(image, p, seed, cx, h)
		"structure": _variant_structure(image, p, seed, cx, h)
		"magical": _variant_magical(image, p, seed, cx, h)
		"water": _variant_water(image, p, seed, cx, h)
		_: _variant_sparkles(image, p, seed, cx, h)


static func _variant_tree(image: Image, p: Dictionary, seed: int, cx: float, h: float) -> void:
	# Variants add small leaf facets to the existing crown. Do not stamp more
	# circular canopy blobs: that was the source of the repeated lollipop look.
	var deep := _pc(p, "canopy_deep")
	var light := _pc(p, "canopy_light")
	var rim := _pc(p, "rim")
	for i in range(9):
		var px := cx + (_srand(seed, 10 + i) * 2.0 - 1.0) * image.get_width() * 0.29
		var py := h * 0.27 + (_srand(seed, 20 + i) * 2.0 - 1.0) * h * 0.105
		var length := 4.0 + _srand(seed, 30 + i) * 4.0
		var lean := (_srand(seed, 40 + i) * 2.0 - 1.0) * 3.0
		var leaf_color := light if i % 3 == 0 else deep
		_line(image, Vector2(px - length * 0.5, py + 1.0),
			Vector2(px + length * 0.5 + lean, py - 2.0), 1.2, leaf_color)
	# One restrained edge glint differentiates the silhouette without looking emissive.
	if seed % 3 == 0:
		_ellipse(image, Vector2(cx + image.get_width() * 0.18, h * 0.19), Vector2(2.0, 2.0), rim, 0.12)


static func _variant_flower(image: Image, p: Dictionary, seed: int, cx: float, h: float) -> void:
	var petal := _pc(p, "petal")
	var alt := _pc(p, "petal_alt")
	var center := _pc(p, "center")
	var count := 2 + int(_srand(seed, 1) * 3.0)
	for i in count:
		var px := cx + (_srand(seed, 10 + i) * 2.0 - 1.0) * image.get_width() * 0.4
		var py := h * 0.30 + (_srand(seed, 20 + i) * 2.0 - 1.0) * h * 0.28
		var col := petal if i % 2 == 0 else alt
		var spin := _srand(seed, 50 + i) * 0.6
		for a in 5:
			var ang := TAU * float(a) / 5.0 + spin
			_ellipse(image, Vector2(px, py) + Vector2.RIGHT.rotated(ang) * 3.2, Vector2(2.4, 2.4), col)
		_ellipse(image, Vector2(px, py), Vector2(1.8, 1.8), center)


static func _variant_ground(image: Image, p: Dictionary, seed: int, cx: float, h: float) -> void:
	var light := _pc(p, "light")
	var mid := _pc(p, "mid")
	for i in 3:
		var px := cx + (_srand(seed, 10 + i) * 2.0 - 1.0) * image.get_width() * 0.42
		var length := h * 0.30 + _srand(seed, 20 + i) * h * 0.25
		var sway := (_srand(seed, 30 + i) * 2.0 - 1.0) * 8.0
		_line(image, Vector2(px, h * 0.9), Vector2(px + sway, h * 0.9 - length), 1.6,
			light if i % 2 == 0 else mid)


static func _variant_structure(image: Image, p: Dictionary, seed: int, cx: float, h: float) -> void:
	var wood := _pc(p, "wood_dark")
	var warm := _pc(p, "warm")
	var moss := _pc(p, "moss")
	var bx := cx + (_srand(seed, 1) * 2.0 - 1.0) * image.get_width() * 0.3
	_polygon(image, [
		Vector2(bx - 5, h * 0.18), Vector2(bx - 5, h * 0.05),
		Vector2(bx + 3, h * 0.05), Vector2(bx + 3, h * 0.18),
	], wood)
	for i in 3:
		var py := h * 0.50 + i * 6.0
		_line(image, Vector2(cx - image.get_width() * 0.30, py),
			Vector2(cx + image.get_width() * 0.30, py), 1.0, wood)
	_ellipse(image, Vector2(bx, h * 0.05), Vector2(6.0, 3.0), warm)
	_ellipse(image, Vector2(cx - image.get_width() * 0.28, h * 0.55), Vector2(7.0, 3.0), moss)


static func _variant_magical(image: Image, p: Dictionary, seed: int, cx: float, h: float) -> void:
	var glow := _pc(p, "glow")
	var light := _pc(p, "light")
	var gold := _pc(p, "gold")
	_ellipse(image, Vector2(cx, h * 0.5),
		Vector2(image.get_width() * 0.30, h * 0.35), Color(glow.r, glow.g, glow.b, 0.08))
	for i in 5:
		var px := cx + (_srand(seed, 10 + i) * 2.0 - 1.0) * image.get_width() * 0.42
		var py := h * 0.20 + _srand(seed, 20 + i) * h * 0.60
		var r := 1.6 + _srand(seed, 30 + i) * 1.6
		_ellipse(image, Vector2(px, py), Vector2(r, r), gold if i % 2 == 0 else light)


static func _variant_water(image: Image, p: Dictionary, seed: int, cx: float, h: float) -> void:
	var foam := _pc(p, "foam")
	var glint := _pc(p, "glint")
	for i in 4:
		var py := h * 0.30 + _srand(seed, 10 + i) * h * 0.60
		_line(image, Vector2(cx - image.get_width() * 0.35, py),
			Vector2(cx + image.get_width() * 0.35, py + 3.0), 1.0,
			foam if i % 2 == 0 else glint)


static func _variant_sparkles(image: Image, p: Dictionary, seed: int, cx: float, h: float) -> void:
	var accent := _pc(p, "accent")
	for i in 4:
		var px := cx + (_srand(seed, 10 + i) * 2.0 - 1.0) * image.get_width() * 0.40
		var py := h * 0.25 + _srand(seed, 20 + i) * h * 0.60
		_ellipse(image, Vector2(px, py), Vector2(1.4, 1.4), accent)


# ---------------------------------------------------------- original painters
# Kept verbatim so variant 0 is byte-for-byte the shipped placeholder look.

