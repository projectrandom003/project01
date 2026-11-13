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
	_draw_character_frame(image, palette, state, direction, frame_index)
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
	match kind:
		# ---- original twelve (variant 0 reproduces the shipped look) ----
		"glade_tree": return _tree(96, 128, false)
		"ancient_tree": return _tree(144, 196, true)
		"rock": return _rock()
		"flower": return _flower()
		"mushroom": return _mushroom()
		"crystal": return _crystal()
		"bush": return _bush()
		"hut": return _hut()
		"lantern": return _lantern()
		"waypoint": return _waypoint()
		"ruin_pillar": return _ruin_pillar()
		"fence": return _fence()
		# ---- new: trees ----
		"willow_tree": return _p_willow_tree()
		"birch_tree": return _p_birch_tree()
		"pine_tree": return _p_pine_tree()
		"blossom_tree": return _p_blossom_tree()
		"dead_tree": return _p_dead_tree()
		# ---- new: ground ----
		"fern": return _p_fern()
		"tall_grass": return _p_tall_grass()
		"reeds": return _p_reeds()
		"lily_pad": return _p_lily_pad()
		"moss_rock": return _p_moss_rock()
		"pebble": return _p_pebble()
		"flower_cluster": return _p_flower_cluster()
		"berry_bush": return _p_berry_bush()
		"glow_mushroom": return _p_glow_mushroom()
		# ---- new: structures ----
		"cottage": return _p_cottage()
		"wooden_bridge": return _p_wooden_bridge()
		"stone_bridge": return _p_stone_bridge()
		"dock": return _p_dock()
		"well": return _p_well()
		"shrine": return _p_shrine()
		"ruin_arch": return _p_ruin_arch()
		"signpost": return _p_signpost()
		"barrel": return _p_barrel()
		"cart": return _p_cart()
		# ---- Phase-4 detailed landmarks ----
		"watchtower": return _p_watchtower()
		"market_stall": return _p_market_stall()
		"stone_wall": return _p_stone_wall()
		"gazebo": return _p_gazebo()
		"banner_post": return _p_banner_post()
		"moon_shrine": return _p_moon_shrine()
		# ---- PART 5: Moonpetal Hollow + village-approach silhouettes ----
		"birch_grove": return _p_birch_grove()
		"moon_lantern": return _p_moon_lantern()
		"stone_path": return _p_stone_path()
		"village_gate": return _p_village_gate()
		# ---- new: magical ----
		"spirit_bloom": return _p_spirit_bloom()
		"rune_stone": return _p_rune_stone()
		"crystal_cluster": return _p_crystal_cluster()
		"wisp_lantern": return _p_wisp_lantern()
		# ---- new: water ----
		"waterfall": return _p_waterfall()
		"river_rock": return _p_river_rock()
		"foam_ripple": return _p_foam_ripple()
		# ---- new: wildlife / ambient ----
		"butterfly": return _p_butterfly()
		"moth": return _p_moth()
		"bird": return _p_bird()
		"firefly_sprite": return _p_firefly_sprite()
		_: return _flower()


# ------------------------------------------------------------------ helpers

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

static func _tree(width: int, height: int, ancient: bool) -> Image:
	# Woodland trees use an irregular, branch-led silhouette instead of stacked
	# circular blobs. The silhouette is intentionally asymmetric so groves do
	# not read as repeated lollipops when viewed from the isometric camera.
	var image := _new_image(width, height)
	var cx := width * 0.5
	var base_y := height - 6.0
	var canopy_y := height * (0.31 if ancient else 0.32)
	var canopy_x := width * (0.43 if ancient else 0.40)
	var canopy_h := height * (0.29 if ancient else 0.27)
	var trunk_top := height * (0.47 if ancient else 0.53)
	var trunk_dark := Color("#30291f") if ancient else Color("#3a2b20")
	var trunk_light := Color("#756044") if ancient else Color("#755337")
	var deep := Color("#1b3025") if ancient else Color("#20372a")
	var mid := Color("#304d35") if ancient else Color("#36583a")
	var light := Color("#4d7044") if ancient else Color("#527b49")
	var sunlit := Color("#78965a") if ancient else Color("#7d9b5c")
	var shadow := Color(0.015, 0.035, 0.025, 0.34)

	_ellipse(image, Vector2(cx, base_y), Vector2(width * 0.31, 6.0), shadow)

	# Exposed roots and a tapered, slightly leaning trunk.
	_polygon(image, PackedVector2Array([
		Vector2(cx - width * 0.15, base_y), Vector2(cx - width * 0.075, base_y - 12.0),
		Vector2(cx - width * 0.045, trunk_top), Vector2(cx + width * 0.035, trunk_top - 2.0),
		Vector2(cx + width * 0.10, base_y - 10.0), Vector2(cx + width * 0.19, base_y),
		Vector2(cx + width * 0.055, base_y - 4.0), Vector2(cx - width * 0.04, base_y - 3.0)
	]), trunk_dark)
	_polygon(image, PackedVector2Array([
		Vector2(cx - width * 0.015, base_y - 5.0), Vector2(cx + width * 0.005, trunk_top + 2.0),
		Vector2(cx + width * 0.04, trunk_top + 1.0), Vector2(cx + width * 0.065, base_y - 8.0)
	]), trunk_light)

	# Thick, visible limbs emerge from the trunk and disappear into the crown.
	var limb_width := 5.0 if ancient else 3.5
	_line(image, Vector2(cx, trunk_top + 20.0), Vector2(cx - canopy_x * 0.72, canopy_y + canopy_h * 0.48), limb_width, trunk_dark)
	_line(image, Vector2(cx + 2.0, trunk_top + 15.0), Vector2(cx + canopy_x * 0.70, canopy_y + canopy_h * 0.42), limb_width, trunk_dark)
	_line(image, Vector2(cx, trunk_top + 4.0), Vector2(cx - canopy_x * 0.28, canopy_y - canopy_h * 0.35), limb_width * 0.72, trunk_dark)
	_line(image, Vector2(cx + 1.0, trunk_top + 6.0), Vector2(cx + canopy_x * 0.34, canopy_y - canopy_h * 0.28), limb_width * 0.72, trunk_dark)

	# Scalloped but non-circular crown outline.
	var crown := PackedVector2Array()
	for i in range(20):
		var angle := TAU * float(i) / 20.0
		var irregular := 0.84 + 0.10 * sin(float(i) * 2.17) + 0.055 * cos(float(i) * 3.71)
		var x_radius := canopy_x * irregular
		var y_radius := canopy_h * (0.90 + 0.08 * sin(float(i) * 1.43))
		crown.append(Vector2(cx + cos(angle) * x_radius, canopy_y + sin(angle) * y_radius))
	_polygon(image, crown, deep)

	# Offset crown masses create depth and a canopy that hangs over the trunk.
	_polygon(image, PackedVector2Array([
		Vector2(cx - canopy_x * 0.94, canopy_y + canopy_h * 0.12),
		Vector2(cx - canopy_x * 0.79, canopy_y - canopy_h * 0.46),
		Vector2(cx - canopy_x * 0.34, canopy_y - canopy_h * 0.72),
		Vector2(cx + canopy_x * 0.12, canopy_y - canopy_h * 0.52),
		Vector2(cx + canopy_x * 0.28, canopy_y - canopy_h * 0.05),
		Vector2(cx - canopy_x * 0.10, canopy_y + canopy_h * 0.34),
		Vector2(cx - canopy_x * 0.60, canopy_y + canopy_h * 0.54)
	]), mid)
	_polygon(image, PackedVector2Array([
		Vector2(cx - canopy_x * 0.05, canopy_y - canopy_h * 0.46),
		Vector2(cx + canopy_x * 0.44, canopy_y - canopy_h * 0.76),
		Vector2(cx + canopy_x * 0.88, canopy_y - canopy_h * 0.28),
		Vector2(cx + canopy_x * 0.96, canopy_y + canopy_h * 0.24),
		Vector2(cx + canopy_x * 0.52, canopy_y + canopy_h * 0.58),
		Vector2(cx + canopy_x * 0.12, canopy_y + canopy_h * 0.20)
	]), mid)

	# Individual pointed leaf clusters catch the canopy light. Their placement
	# follows an offset spiral rather than a regular radial ring.
	for i in range(30):
		var angle := float(i) * 2.399
		var radius := sqrt(float(i) / 30.0)
		var center := Vector2(cx, canopy_y) + Vector2(cos(angle) * canopy_x * 0.78 * radius, sin(angle) * canopy_h * 0.76 * radius)
		var direction := Vector2(cos(angle + 0.55), sin(angle + 0.55) * 0.72)
		var tangent := Vector2(-direction.y, direction.x)
		var leaf_len := (width * 0.075) * (1.0 - radius * 0.25)
		var leaf_w := leaf_len * 0.34
		var leaf := PackedVector2Array([
			center - direction * leaf_len,
			center - tangent * leaf_w,
			center + direction * leaf_len * 0.78,
			center + tangent * leaf_w * 0.65
		])
		var leaf_color := sunlit if i % 7 == 0 else light if i % 3 == 0 else mid
		_polygon(image, leaf, leaf_color)

	# A few hanging leaf tips break the lower edge of the crown.
	for i in range(7):
		var x := cx - canopy_x * 0.78 + float(i) * canopy_x * 0.25
		var y := canopy_y + canopy_h * (0.68 + 0.10 * sin(float(i) * 1.7))
		_polygon(image, PackedVector2Array([
			Vector2(x - 3.0, y - 3.0), Vector2(x + 3.0, y - 2.0),
			Vector2(x + 1.0, y + 9.0 + float(i % 3) * 3.0), Vector2(x - 2.0, y + 5.0)
		]), mid)

	if ancient:
		# Old trees carry a restrained rune scar, not a glowing Christmas-light effect.
		for i in range(3):
			var y := trunk_top + 22.0 + float(i) * 16.0
			_line(image, Vector2(cx + 1.0, y), Vector2(cx + 4.0, y - 5.0), 1.2, Color(0.36, 0.78, 0.62, 0.62))
		_ellipse(image, Vector2(cx - canopy_x * 0.10, canopy_y + canopy_h * 0.10), Vector2(canopy_x * 0.10, canopy_h * 0.10), Color(0.35, 0.75, 0.58, 0.10))
	return image


static func _rock() -> Image:
	var image := _new_image(64, 48)
	_ellipse(image, Vector2(32, 42), Vector2(24, 5), Color(0.02, 0.05, 0.03, 0.25))
	_polygon(image, [
		Vector2(8, 42), Vector2(14, 22), Vector2(28, 12), Vector2(48, 18), Vector2(58, 38), Vector2(50, 44),
	], Color("#4a4a44"))
	_polygon(image, [
		Vector2(16, 38), Vector2(20, 24), Vector2(31, 16), Vector2(44, 22), Vector2(48, 34),
	], Color("#62645a"))
	_polygon(image, [
		Vector2(22, 26), Vector2(31, 18), Vector2(38, 21), Vector2(30, 27),
	], Color("#8a8f7c"))
	# Broken facets and thin mineral seams stop the rock reading as a smooth blob.
	_polygon(image, PackedVector2Array([
		Vector2(15, 34), Vector2(22, 27), Vector2(27, 31), Vector2(24, 39), Vector2(17, 40)
	]), Color("#3b403b"))
	_line(image, Vector2(31, 18), Vector2(28, 29), 1.0, Color("#b1b49a", 0.55))
	_line(image, Vector2(28, 29), Vector2(35, 35), 0.8, Color("#343a35", 0.8))
	_line(image, Vector2(43, 23), Vector2(48, 31), 1.0, Color("#343a35", 0.65))
	_ellipse(image, Vector2(24, 38), Vector2(3.0, 2.0), Color("#6f8f5a"))
	_ellipse(image, Vector2(46, 36), Vector2(4.0, 2.5), Color("#5d7a4a"))
	_line(image, Vector2(13, 38), Vector2(21, 34), 1.2, Color("#7f9560", 0.55))
	return image


static func _flower() -> Image:
	var image := _new_image(24, 28)
	_line(image, Vector2(12, 26), Vector2(12, 14), 1.2, Color("#4f7a46"))
	_ellipse(image, Vector2(8, 24), Vector2(4.0, 2.0), Color("#5d8f52"))
	for angle in 5:
		var direction := Vector2.RIGHT.rotated(TAU * float(angle) / 5.0)
		_ellipse(image, Vector2(12, 10) + direction * 3.4, Vector2(3.0, 3.0), Color("#ffe9a3"))
	_ellipse(image, Vector2(12, 10), Vector2(2.0, 2.0), Color("#ffb3c7"))
	return image


static func _mushroom() -> Image:
	var image := _new_image(28, 34)
	_line(image, Vector2(14, 32), Vector2(14, 18), 3.0, Color("#e8dcc0"))
	_ellipse(image, Vector2(14, 15), Vector2(11, 7), Color("#b05a5a"))
	_ellipse(image, Vector2(10, 12), Vector2(2.0, 1.6), Color("#ffd9c0"))
	_ellipse(image, Vector2(18, 16), Vector2(1.6, 1.2), Color("#ffd9c0"))
	_ellipse(image, Vector2(15, 9), Vector2(1.4, 1.0), Color("#ffd9c0"))
	return image


static func _crystal() -> Image:
	var image := _new_image(48, 72)
	_ellipse(image, Vector2(24, 68), Vector2(15, 4), Color(0.3, 0.9, 0.9, 0.18))
	_polygon(image, [
		Vector2(24, 4), Vector2(36, 34), Vector2(30, 66), Vector2(18, 66), Vector2(12, 34),
	], Color("#2a8f9f"))
	_polygon(image, [
		Vector2(24, 4), Vector2(31, 34), Vector2(24, 64), Vector2(18, 34),
	], Color("#7fe3e0"))
	_polygon(image, [
		Vector2(24, 10), Vector2(24, 56), Vector2(20, 34),
	], Color("#c9fffb"))
	_ellipse(image, Vector2(24, 34), Vector2(20, 26), Color(0.4, 1.0, 0.95, 0.10))
	return image


static func _bush() -> Image:
	var image := _new_image(64, 44)
	_ellipse(image, Vector2(32, 40), Vector2(22, 4), Color(0.02, 0.05, 0.03, 0.22))
	_ellipse(image, Vector2(22, 28), Vector2(16, 13), Color("#2f5234"))
	_ellipse(image, Vector2(42, 28), Vector2(15, 12), Color("#2f5234"))
	_ellipse(image, Vector2(32, 20), Vector2(17, 14), Color("#3f6b3f"))
	_ellipse(image, Vector2(28, 16), Vector2(8, 6), Color("#5d8f52"))
	for index in 4:
		_ellipse(image, Vector2(20 + index * 8, 26 + (index % 2) * 5), Vector2(1.6, 1.6), Color("#ffb3c7"))
	return image


static func _hut() -> Image:
	var width := 170
	var height := 150
	var image := _new_image(width, height)
	var base_y := height - 8.0
	_ellipse(image, Vector2(width * 0.5, base_y), Vector2(70, 8), Color(0.02, 0.05, 0.03, 0.28))
	_polygon(image, [
		Vector2(28, base_y), Vector2(32, base_y - 22), Vector2(140, base_y - 22), Vector2(144, base_y),
	], Color("#5c5a50"))
	_polygon(image, [
		Vector2(36, base_y - 20), Vector2(40, 62), Vector2(132, 62), Vector2(136, base_y - 20),
	], Color("#6b4c33"))
	for index in 6:
		var x := 44.0 + index * 14.0
		_line(image, Vector2(x, base_y - 24), Vector2(x, 66), 1.0, Color("#4a3524"))
	_polygon(image, [
		Vector2(74, base_y - 20), Vector2(76, 88), Vector2(96, 88), Vector2(98, base_y - 20),
	], Color("#3a2a1c"))
	_ellipse(image, Vector2(92, 112), Vector2(1.8, 1.8), Color("#e8c27a"))
	_polygon(image, [
		Vector2(108, 84), Vector2(110, 62), Vector2(126, 62), Vector2(128, 84),
	], Color("#ffcf6a"))
	_ellipse(image, Vector2(118, 72), Vector2(20, 18), Color(1.0, 0.8, 0.4, 0.12))
	_polygon(image, [
		Vector2(22, 66), Vector2(52, 22), Vector2(122, 22), Vector2(150, 66),
	], Color("#4a3524"))
	_polygon(image, [
		Vector2(30, 60), Vector2(56, 28), Vector2(118, 28), Vector2(142, 60),
	], Color("#6b4c33"))
	for index in 5:
		_line(image, Vector2(34 + index * 3, 58 - index * 6), Vector2(136 - index * 3, 58 - index * 6), 1.2, Color("#3a2a1c"))
	_ellipse(image, Vector2(44, 70), Vector2(12, 4), Color("#4f7a46"))
	_ellipse(image, Vector2(130, 66), Vector2(10, 3), Color("#4f7a46"))
	_line(image, Vector2(132, 70), Vector2(134, 100), 1.4, Color("#3f6b3f"))
	_ellipse(image, Vector2(124, 16), Vector2(8, 5), Color(0.8, 0.85, 0.9, 0.10))

	# Uneven thatch courses and small split ends stop the roof reading as a
	# perfectly clean polygon. Keep highlights muted so the village stays calm.
	for row in range(4):
		var y := 34.0 + float(row) * 7.0
		var inset := float(row) * 4.0
		_line(image, Vector2(34.0 + inset, y), Vector2(138.0 - inset, y + 1.0), 1.0, Color("#8a6944", 0.48))
		for seam in range(5):
			var sx := 44.0 + float(seam) * 19.0 + float((row + seam) % 2) * 5.0
			if sx < 136.0 - inset:
				_line(image, Vector2(sx, y - 2.0), Vector2(sx - 2.0, y + 4.0), 0.8, Color("#3a2a1c", 0.55))
	# Wall grain, weather stains and a few exposed foundation stones.
	for plank in range(5):
		var x := 48.0 + float(plank) * 18.0
		_line(image, Vector2(x, 74), Vector2(x - 1.0, base_y - 26.0), 0.8, Color("#a47a4d", 0.30))
	for stone in range(7):
		var sx := 34.0 + float(stone) * 17.0
		_line(image, Vector2(sx, base_y - 12.0), Vector2(sx + 7.0, base_y - 13.0), 1.2, Color("#8a8776", 0.55))
	_ellipse(image, Vector2(39, 76), Vector2(5, 3), Color("#3f6b3f", 0.55))
	_ellipse(image, Vector2(130, 68), Vector2(6, 2), Color("#3f6b3f", 0.48))

	# Small recessed shutters and a dark doorway establish a believable facade.
	for wx in [54.0, 126.0]:
		_polygon(image, PackedVector2Array([
			Vector2(wx - 7.0, 99.0), Vector2(wx - 7.0, 85.0),
			Vector2(wx + 7.0, 85.0), Vector2(wx + 7.0, 99.0)
		]), Color("#35271e"))
		_polygon(image, PackedVector2Array([
			Vector2(wx - 4.0, 96.0), Vector2(wx - 4.0, 88.0),
			Vector2(wx + 4.0, 88.0), Vector2(wx + 4.0, 96.0)
		]), Color("#c49a5e", 0.78))
		_line(image, Vector2(wx, 88.0), Vector2(wx, 96.0), 1.0, Color("#493323"))
	_polygon(image, PackedVector2Array([
		Vector2(74.0, 128.0), Vector2(74.0, 96.0), Vector2(100.0, 96.0),
		Vector2(100.0, 128.0)
	]), Color("#35271e"))
	_polygon(image, PackedVector2Array([
		Vector2(78.0, 126.0), Vector2(78.0, 99.0), Vector2(96.0, 99.0),
		Vector2(96.0, 126.0)
	]), Color("#523a28"))
	_ellipse(image, Vector2(92.0, 114.0), Vector2(1.6, 1.6), Color("#d9b16e"))
	# A few broken thatch strands and timber end-grain, kept low contrast.
	for row in range(4):
		var roof_y := 35.0 + float(row) * 7.0
		var inset := float(row) * 4.0
		_line(image, Vector2(30.0 + inset, roof_y), Vector2(142.0 - inset, roof_y + 1.0), 1.0, Color("#a17b50", 0.38))
	for plank in range(4):
		var px := 48.0 + float(plank) * 22.0
		_line(image, Vector2(px, 76.0), Vector2(px - 1.0, 119.0), 0.8, Color("#c0905b", 0.24))
	return image


static func _lantern() -> Image:
	var image := _new_image(32, 80)
	_ellipse(image, Vector2(16, 76), Vector2(10, 3), Color(0.02, 0.05, 0.03, 0.22))
	_polygon(image, [Vector2(13, 76), Vector2(15, 26), Vector2(17, 26), Vector2(19, 76)], Color("#3a2a1c"))
	_line(image, Vector2(16, 28), Vector2(26, 22), 2.0, Color("#3a2a1c"))
	_ellipse(image, Vector2(26, 30), Vector2(6, 8), Color(1.0, 0.8, 0.45, 0.22))
	_ellipse(image, Vector2(26, 30), Vector2(3.5, 5.0), Color("#ffcf6a"))
	_ellipse(image, Vector2(26, 29), Vector2(1.8, 2.6), Color("#fff6d0"))
	return image


static func _waypoint() -> Image:
	var image := _new_image(96, 120)
	var base_y := 114.0
	_ellipse(image, Vector2(48, base_y), Vector2(40, 7), Color(0.02, 0.05, 0.03, 0.25))
	_polygon(image, [Vector2(14, base_y), Vector2(18, 34), Vector2(30, 34), Vector2(32, base_y)], Color("#5c5a50"))
	_polygon(image, [Vector2(64, base_y), Vector2(66, 34), Vector2(78, 34), Vector2(82, base_y)], Color("#5c5a50"))
	_polygon(image, [Vector2(20, base_y), Vector2(22, 38), Vector2(26, 38), Vector2(28, base_y)], Color("#7a7868"))
	_polygon(image, [Vector2(68, base_y), Vector2(70, 38), Vector2(74, 38), Vector2(76, base_y)], Color("#7a7868"))
	_polygon(image, [
		Vector2(12, 38), Vector2(18, 22), Vector2(48, 12), Vector2(78, 22), Vector2(84, 38),
		Vector2(72, 38), Vector2(48, 26), Vector2(24, 38),
	], Color("#6b685a"))
	_polygon(image, [
		Vector2(48, 34), Vector2(58, 54), Vector2(48, 78), Vector2(38, 54),
	], Color("#7fe3e0"))
	_polygon(image, [Vector2(48, 38), Vector2(53, 54), Vector2(48, 72), Vector2(43, 54)], Color("#d9fffb"))
	_ellipse(image, Vector2(48, 56), Vector2(26, 30), Color(0.4, 1.0, 0.95, 0.13))
	return image


static func _ruin_pillar() -> Image:
	var image := _new_image(52, 100)
	_ellipse(image, Vector2(26, 96), Vector2(20, 4), Color(0.02, 0.05, 0.03, 0.22))
	_polygon(image, [Vector2(16, 96), Vector2(18, 18), Vector2(34, 18), Vector2(36, 96)], Color("#6b685a"))
	_polygon(image, [Vector2(21, 94), Vector2(22, 22), Vector2(28, 22), Vector2(30, 94)], Color("#8a8776"))
	_polygon(image, [Vector2(12, 20), Vector2(14, 8), Vector2(38, 8), Vector2(40, 20)], Color("#7a7868"))
	_line(image, Vector2(24, 36), Vector2(24, 76), 1.2, Color(0.6, 1.0, 0.75, 0.35))
	_ellipse(image, Vector2(26, 46), Vector2(3, 3), Color(0.6, 1.0, 0.75, 0.5))
	return image


static func _fence() -> Image:
	var image := _new_image(64, 40)
	_ellipse(image, Vector2(32, 36), Vector2(28, 3), Color(0.02, 0.05, 0.03, 0.18))
	for index in 3:
		var x := 8.0 + index * 22.0
		_polygon(image, [Vector2(x, 36), Vector2(x + 2, 14), Vector2(x + 6, 14), Vector2(x + 8, 36)], Color("#5a4030"))
	_line(image, Vector2(6, 22), Vector2(58, 22), 2.0, Color("#6b4c33"))
	_line(image, Vector2(6, 30), Vector2(58, 30), 1.6, Color("#4a3524"))
	return image


# --------------------------------------------------------------- new: trees

static func _p_willow_tree() -> Image:
	var p := GreenwardStyle.prop_palette("willow_tree")
	var image := _new_image(116, 164)
	var cx := 58.0
	var by := 156.0
	var deep := _pc(p, "canopy_deep")
	var mid := _pc(p, "canopy_mid")
	var light := _pc(p, "canopy_light")
	_shadow(image, cx, by, 38.0)
	# A curved trunk and long lateral boughs support the hanging crown.
	_polygon(image, PackedVector2Array([
		Vector2(49, by), Vector2(47, 92), Vector2(52, 62),
		Vector2(61, 60), Vector2(66, 94), Vector2(69, by)
	]), _pc(p, "trunk"))
	_line(image, Vector2(53, 148), Vector2(57, 68), 2.2, _pc(p, "trunk_light"))
	for branch in range(5):
		var side := -1.0 if branch % 2 == 0 else 1.0
		var start := Vector2(58.0 + side * 2.0, 78.0 + float(branch) * 4.0)
		var end := Vector2(58.0 + side * (26.0 + float(branch % 3) * 5.0), 40.0 + float(branch) * 5.0)
		_line(image, start, end, 3.0 if branch < 2 else 2.0, _pc(p, "trunk"))
	# Broad, uneven crown with scalloped edges; avoid a single circular canopy.
	_polygon(image, PackedVector2Array([
		Vector2(12, 54), Vector2(18, 30), Vector2(36, 18), Vector2(52, 22),
		Vector2(66, 12), Vector2(90, 22), Vector2(105, 43), Vector2(101, 68),
		Vector2(84, 78), Vector2(31, 78), Vector2(14, 68)
	]), deep)
	for cluster in [
		Vector2(29, 42), Vector2(48, 32), Vector2(72, 31), Vector2(91, 43),
		Vector2(38, 57), Vector2(77, 57)
	]:
		_ellipse(image, cluster, Vector2(17, 13), mid, 0.05)
	_ellipse(image, Vector2(43, 30), Vector2(13, 9), light, 0.05)
	_ellipse(image, Vector2(78, 29), Vector2(14, 9), light, 0.05)
	# Willow curtains are long, tapering leaf sprays with irregular lengths.
	for i in range(17):
		var x := 16.0 + float(i) * 5.2
		var root_y := 56.0 + 8.0 * absf((x - cx) / 58.0)
		var length := 34.0 + 22.0 * absf(sin(float(i) * 1.71))
		var sway := sin(float(i) * 1.37) * 5.0
		var tip := Vector2(x + sway, root_y + length)
		_line(image, Vector2(x, root_y), tip, 1.8, mid if i % 3 == 0 else light)
		for leaf in range(4):
			var t := 0.22 + float(leaf) * 0.18
			var point := Vector2(x, root_y).lerp(tip, t)
			var lean := -1.0 if (i + leaf) % 2 == 0 else 1.0
			_line(image, point, point + Vector2(lean * 4.0, 3.0), 1.1, light if leaf % 2 == 0 else mid)
	return image


static func _p_birch_tree() -> Image:
	var p := GreenwardStyle.prop_palette("birch_tree")
	var image := _new_image(76, 156)
	var cx := 38.0
	var by := 148.0
	_shadow(image, cx, by, 22.0)
	_polygon(image, [Vector2(cx - 6, by), Vector2(cx - 3, 30), Vector2(cx + 3, 30), Vector2(cx + 6, by)], _pc(p, "trunk"))
	for i in 6:
		var y := 44.0 + i * 16.0
		_line(image, Vector2(cx - 5, y), Vector2(cx + 1, y - 2), 1.4, _pc(p, "canopy_deep"))
	var deep := _pc(p, "canopy_deep")
	var light := _pc(p, "canopy_light")
	_ellipse(image, Vector2(cx - 10, 30), Vector2(22, 16), deep, 0.05)
	_ellipse(image, Vector2(cx + 12, 26), Vector2(20, 15), deep, 0.05)
	_ellipse(image, Vector2(cx, 18), Vector2(22, 16), _pc(p, "canopy_mid"), 0.05)
	_ellipse(image, Vector2(cx - 8, 12), Vector2(10, 7), light)
	return image


static func _p_pine_tree() -> Image:
	var p := GreenwardStyle.prop_palette("pine_tree")
	var image := _new_image(84, 156)
	var cx := 42.0
	var by := 148.0
	_shadow(image, cx, by, 24.0)
	_polygon(image, [Vector2(cx - 6, by), Vector2(cx - 4, 40), Vector2(cx + 4, 40), Vector2(cx + 6, by)], _pc(p, "trunk"))
	var deep := _pc(p, "canopy_deep")
	var mid := _pc(p, "canopy_mid")
	var light := _pc(p, "canopy_light")
	for tier in 4:
		var top_y := 12.0 + tier * 26.0
		var half := 12.0 + tier * 8.0
		_polygon(image, [
			Vector2(cx, top_y), Vector2(cx + half, top_y + 30), Vector2(cx - half, top_y + 30),
		], deep if tier % 2 == 0 else mid)
		_polygon(image, [
			Vector2(cx, top_y + 4), Vector2(cx + half * 0.6, top_y + 26), Vector2(cx, top_y + 26),
		], light)
	for tier in 4:
		var top_y := 12.0 + tier * 26.0
		_ellipse(image, Vector2(cx - (8.0 + tier * 4.0), top_y + 22), Vector2(4, 3), light)
	return image


static func _p_blossom_tree() -> Image:
	var p := GreenwardStyle.prop_palette("blossom_tree")
	var image := _new_image(112, 132)
	var cx := 56.0
	var by := 124.0
	_shadow(image, cx, by, 32.0)
	_polygon(image, [Vector2(cx - 8, by), Vector2(cx - 4, 62), Vector2(cx + 4, 62), Vector2(cx + 9, by)], _pc(p, "trunk"))
	_line(image, Vector2(cx, 78), Vector2(cx - 22, 56), 3.0, _pc(p, "trunk"))
	_line(image, Vector2(cx, 78), Vector2(cx + 22, 54), 3.0, _pc(p, "trunk"))
	var mid := _pc(p, "canopy_mid")
	var petal := _pc(p, "petal")
	_ellipse(image, Vector2(cx, 46), Vector2(44, 28), mid, 0.05)
	_ellipse(image, Vector2(cx - 28, 54), Vector2(20, 16), mid, 0.05)
	_ellipse(image, Vector2(cx + 28, 52), Vector2(20, 16), mid, 0.05)
	for i in 12:
		var ang := TAU * float(i) / 12.0
		var rx := cx + cos(ang) * 34.0
		var ry := 44.0 + sin(ang) * 20.0
		_ellipse(image, Vector2(rx, ry), Vector2(6.0, 5.0), petal)
		_ellipse(image, Vector2(rx, ry), Vector2(2.0, 2.0), GreenwardStyle.ACCENTS.petal_alt)
	return image


static func _p_dead_tree() -> Image:
	var p := GreenwardStyle.prop_palette("dead_tree")
	var image := _new_image(96, 140)
	var cx := 48.0
	var by := 132.0
	_shadow(image, cx, by, 26.0, 0.20)
	var trunk := _pc(p, "trunk")
	_polygon(image, [Vector2(cx - 7, by), Vector2(cx - 3, 40), Vector2(cx + 3, 40), Vector2(cx + 8, by)], trunk)
	var branches := [
		[Vector2(cx - 2, 62), Vector2(cx - 30, 30), 3.5],
		[Vector2(cx + 2, 58), Vector2(cx + 28, 26), 3.5],
		[Vector2(cx - 2, 48), Vector2(cx - 20, 18), 2.4],
		[Vector2(cx + 2, 46), Vector2(cx + 18, 14), 2.4],
		[Vector2(cx - 28, 32), Vector2(cx - 36, 18), 1.6],
		[Vector2(cx + 26, 28), Vector2(cx + 34, 12), 1.6],
	]
	for b in branches:
		_line(image, b[0], b[1], b[2], trunk)
	return image


# --------------------------------------------------------------- new: ground

static func _p_fern() -> Image:
	var p := GreenwardStyle.prop_palette("fern")
	var image := _new_image(52, 46)
	var cx := 26.0
	var by := 42.0
	var dark := _pc(p, "dark")
	var light := _pc(p, "light")
	for i in 5:
		var ang := -PI * 0.85 + float(i) * (PI * 0.7 / 4.0)
		var tip := Vector2(cx, by) + Vector2.UP.rotated(ang) * 30.0
		_line(image, Vector2(cx, by), tip, 1.2, dark)
		for j in 5:
			var t := (float(j) + 1.0) / 6.0
			var pos := Vector2(cx, by).lerp(tip, t)
			_ellipse(image, pos + Vector2(-3, -1), Vector2(3.0, 1.6), light)
			_ellipse(image, pos + Vector2(3, -1), Vector2(3.0, 1.6), light)
	return image


static func _p_tall_grass() -> Image:
	var p := GreenwardStyle.prop_palette("tall_grass")
	var image := _new_image(44, 52)
	var cx := 22.0
	var by := 48.0
	var mid := _pc(p, "mid")
	var light := _pc(p, "light")
	for i in 7:
		var x := cx - 16.0 + i * 5.0
		var sway := sin(i * 1.7) * 6.0
		var height := 26.0 + (i % 3) * 8.0
		_line(image, Vector2(x, by), Vector2(x + sway, by - height), 1.3, light if i % 2 == 0 else mid)
	return image


static func _p_reeds() -> Image:
	var p := GreenwardStyle.prop_palette("reeds")
	var image := _new_image(48, 68)
	var cx := 24.0
	var by := 64.0
	var mid := _pc(p, "mid")
	var light := _pc(p, "light")
	for i in 4:
		var x := 10.0 + i * 9.0
		var top := 12.0 + (i % 2) * 8.0
		_line(image, Vector2(x, by), Vector2(x + 2, top), 1.6, mid)
		_ellipse(image, Vector2(x + 2, top), Vector2(2.6, 7.0), light)
		_ellipse(image, Vector2(x + 2, top - 4), Vector2(1.4, 2.0), _pc(p, "cap_a"))
	return image


static func _p_lily_pad() -> Image:
	var p := GreenwardStyle.prop_palette("lily_pad")
	var image := _new_image(46, 26)
	_ellipse(image, Vector2(23, 15), Vector2(20, 9), _pc(p, "mid"), 0.04)
	_ellipse(image, Vector2(21, 13), Vector2(15, 6), _pc(p, "light"))
	for a in 5:
		var ang := TAU * float(a) / 5.0
		_ellipse(image, Vector2(30, 11) + Vector2.RIGHT.rotated(ang) * 3.0, Vector2(2.6, 2.6), GreenwardStyle.ACCENTS.petal)
	_ellipse(image, Vector2(30, 11), Vector2(1.8, 1.8), GreenwardStyle.ACCENTS.petal_alt)
	return image


static func _p_moss_rock() -> Image:
	var p := GreenwardStyle.prop_palette("moss_rock")
	var image := _new_image(64, 48)
	_ellipse(image, Vector2(32, 42), Vector2(24, 5), Color(0.02, 0.05, 0.03, 0.25))
	_polygon(image, [Vector2(8, 42), Vector2(14, 20), Vector2(30, 12), Vector2(50, 18), Vector2(58, 38), Vector2(50, 44)], _pc(p, "dark"))
	_polygon(image, [Vector2(16, 38), Vector2(20, 22), Vector2(31, 16), Vector2(44, 22), Vector2(48, 34)], _pc(p, "mid"))
	_ellipse(image, Vector2(26, 18), Vector2(14, 5), _pc(p, "moss"))
	_ellipse(image, Vector2(40, 20), Vector2(10, 4), _pc(p, "light"))
	_ellipse(image, Vector2(22, 30), Vector2(3, 2), _pc(p, "moss"))
	return image


static func _p_pebble() -> Image:
	var p := GreenwardStyle.prop_palette("pebble")
	var image := _new_image(26, 18)
	_ellipse(image, Vector2(13, 15), Vector2(11, 3), Color(0.02, 0.05, 0.03, 0.20))
	_ellipse(image, Vector2(13, 11), Vector2(11, 7), _pc(p, "mid"), 0.05)
	_ellipse(image, Vector2(11, 9), Vector2(5, 3), _pc(p, "light"))
	return image


static func _p_flower_cluster() -> Image:
	var p := GreenwardStyle.prop_palette("flower_cluster")
	var image := _new_image(44, 40)
	var stem := _pc(p, "stem")
	var petal := _pc(p, "petal")
	var alt := _pc(p, "petal_alt")
	var center := _pc(p, "center")
	var spots := [Vector2(12, 14), Vector2(30, 12), Vector2(22, 22), Vector2(16, 28), Vector2(34, 28)]
	for i in spots.size():
		_line(image, Vector2(spots[i].x, 38), spots[i], 1.1, stem)
		var col := petal if i % 2 == 0 else alt
		for a in 5:
			var ang := TAU * float(a) / 5.0
			_ellipse(image, spots[i] + Vector2.RIGHT.rotated(ang) * 3.2, Vector2(2.6, 2.6), col)
		_ellipse(image, spots[i], Vector2(1.8, 1.8), center)
	return image


static func _p_berry_bush() -> Image:
	var p := GreenwardStyle.prop_palette("berry_bush")
	var image := _new_image(64, 50)
	_shadow(image, 32, 46, 24)
	_ellipse(image, Vector2(22, 30), Vector2(16, 14), _pc(p, "leaf"), 0.05)
	_ellipse(image, Vector2(42, 30), Vector2(16, 14), _pc(p, "leaf"), 0.05)
	_ellipse(image, Vector2(32, 22), Vector2(18, 15), _pc(p, "leaf"), 0.05)
	for i in 7:
		var ang := TAU * float(i) / 7.0
		var pos := Vector2(32, 26) + Vector2.RIGHT.rotated(ang) * 14.0
		_ellipse(image, pos, Vector2(2.6, 2.6), _pc(p, "berry"))
		_ellipse(image, pos + Vector2(-0.8, -0.8), Vector2(0.9, 0.9), Color(1, 1, 1, 0.5))
	return image


static func _p_glow_mushroom() -> Image:
	var p := GreenwardStyle.prop_palette("glow_mushroom")
	var image := _new_image(38, 46)
	_ellipse(image, Vector2(19, 24), Vector2(16, 14), Color(0.4, 1.0, 0.8, 0.10))
	_line(image, Vector2(19, 42), Vector2(19, 24), 3.2, _pc(p, "light"))
	var cap := _pc(p, "cap_a")
	_ellipse(image, Vector2(19, 20), Vector2(13, 8), cap)
	_ellipse(image, Vector2(14, 17), Vector2(3, 2), Color(1, 1, 1, 0.6))
	_ellipse(image, Vector2(24, 18), Vector2(2.4, 1.8), Color(1, 1, 1, 0.6))
	_ellipse(image, Vector2(19, 13), Vector2(2, 1.6), Color(1, 1, 1, 0.6))
	_ellipse(image, Vector2(19, 22), Vector2(16, 12), Color(0.5, 1.0, 0.85, 0.12))
	return image


# ----------------------------------------------------------- new: structures

static func _p_cottage() -> Image:
	var p := GreenwardStyle.prop_palette("cottage")
	var image := _new_image(184, 162)
	var by := 152.0
	_shadow(image, 92, by, 78)
	_polygon(image, [Vector2(30, by), Vector2(34, by - 24), Vector2(150, by - 24), Vector2(154, by)], _pc(p, "stone"))
	_polygon(image, [Vector2(38, by - 22), Vector2(42, 66), Vector2(142, 66), Vector2(146, by - 22)], _pc(p, "wood"))
	for i in 7:
		var x := 46.0 + i * 14.0
		_line(image, Vector2(x, by - 26), Vector2(x, 70), 1.0, _pc(p, "wood_dark"))
	_polygon(image, [Vector2(80, by - 22), Vector2(82, 92), Vector2(104, 92), Vector2(106, by - 22)], _pc(p, "wood_dark"))
	_ellipse(image, Vector2(100, 120), Vector2(1.8, 1.8), _pc(p, "warm"))
	_polygon(image, [Vector2(116, 88), Vector2(118, 66), Vector2(136, 66), Vector2(138, 88)], _pc(p, "warm"))
	_ellipse(image, Vector2(127, 76), Vector2(20, 18), Color(1, 0.8, 0.4, 0.12))
	_polygon(image, [Vector2(24, 70), Vector2(56, 22), Vector2(128, 22), Vector2(160, 70)], _pc(p, "roof"))
	_polygon(image, [Vector2(32, 64), Vector2(60, 28), Vector2(124, 28), Vector2(152, 64)], _pc(p, "wood_mid"))
	for i in 5:
		_line(image, Vector2(36 + i * 3, 62 - i * 6), Vector2(148 - i * 3, 62 - i * 6), 1.2, _pc(p, "wood_dark"))
	_polygon(image, [Vector2(118, 22), Vector2(118, 6), Vector2(132, 6), Vector2(132, 24)], _pc(p, "wood_dark"))

	# Carved roof edge, exposed rafters and uneven thatch strands.
	for row in range(5):
		var roof_y := 34.0 + float(row) * 6.0
		var inset := float(row) * 4.5
		_line(image, Vector2(34.0 + inset, roof_y), Vector2(150.0 - inset, roof_y + 1.0), 1.1, Color("#b08a59", 0.42))
		for seam in range(6):
			var sx := 43.0 + float(seam) * 18.0 + float((row + seam) % 2) * 4.0
			if sx < 148.0 - inset:
				_line(image, Vector2(sx, roof_y - 2.0), Vector2(sx - 2.0, roof_y + 3.0), 0.8, _pc(p, "wood_dark"))
	# Recessed windows with timber lintels and a warm interior, not bright decals.
	for wx in [55.0, 126.0]:
		_polygon(image, PackedVector2Array([
			Vector2(wx - 8.0, 84.0), Vector2(wx - 8.0, 69.0),
			Vector2(wx + 8.0, 69.0), Vector2(wx + 8.0, 84.0)
		]), _pc(p, "wood_dark"))
		_polygon(image, PackedVector2Array([
			Vector2(wx - 5.0, 81.0), Vector2(wx - 5.0, 72.0),
			Vector2(wx + 5.0, 72.0), Vector2(wx + 5.0, 81.0)
		]), Color("#d9aa62", 0.82))
		_line(image, Vector2(wx, 72.0), Vector2(wx, 82.0), 1.0, _pc(p, "wood_dark"))
		_line(image, Vector2(wx - 7.0, 68.0), Vector2(wx + 7.0, 68.0), 2.0, _pc(p, "wood_dark"))
	# Door frame, step and diagonal plank grain make the entrance readable.
	_polygon(image, PackedVector2Array([
		Vector2(78.0, 130.0), Vector2(78.0, 94.0), Vector2(108.0, 94.0),
		Vector2(108.0, 130.0)
	]), _pc(p, "wood_dark"))
	_polygon(image, PackedVector2Array([
		Vector2(82.0, 128.0), Vector2(82.0, 97.0), Vector2(104.0, 97.0),
		Vector2(104.0, 128.0)
	]), _pc(p, "wood_mid"))
	_line(image, Vector2(93.0, 99.0), Vector2(93.0, 126.0), 0.9, _pc(p, "wood_dark"))
	_ellipse(image, Vector2(100.0, 115.0), Vector2(1.8, 1.8), _pc(p, "warm"))
	_polygon(image, PackedVector2Array([
		Vector2(74.0, 132.0), Vector2(112.0, 132.0), Vector2(116.0, 138.0), Vector2(70.0, 138.0)
	]), _pc(p, "stone"))
	# Moss grows in crevices rather than forming bright blobs on the walls.
	_ellipse(image, Vector2(48, 74), Vector2(12, 4), _pc(p, "moss"))
	_ellipse(image, Vector2(142, 136), Vector2(11, 3), Color(_pc(p, "moss").r, _pc(p, "moss").g, _pc(p, "moss").b, 0.55))
	_line(image, Vector2(45.0, 91.0), Vector2(67.0, 89.0), 0.8, Color("#d4a36a", 0.28))
	_line(image, Vector2(118.0, 104.0), Vector2(137.0, 102.0), 0.8, Color("#d4a36a", 0.24))
	return image


static func _p_wooden_bridge() -> Image:
	var p := GreenwardStyle.prop_palette("wooden_bridge")
	var image := _new_image(132, 60)
	var wood := _pc(p, "wood")
	var dark := _pc(p, "wood_dark")
	for i in 7:
		var x := 10.0 + i * 17.0
		_polygon(image, [Vector2(x, 40), Vector2(x + 2, 20), Vector2(x + 15, 18), Vector2(x + 14, 40)], wood)
		_line(image, Vector2(x + 1, 40), Vector2(x + 15, 39), 1.0, dark)
	_line(image, Vector2(8, 18), Vector2(124, 14), 2.5, dark)
	_line(image, Vector2(8, 44), Vector2(124, 42), 2.5, dark)
	for i in 5:
		var x := 12.0 + i * 26.0
		_line(image, Vector2(x, 44), Vector2(x, 16), 2.0, dark)
	return image


static func _p_stone_bridge() -> Image:
	var p := GreenwardStyle.prop_palette("stone_bridge")
	var image := _new_image(132, 68)
	var stone := _pc(p, "stone")
	var light := _pc(p, "stone_light")
	_polygon(image, [Vector2(10, 60), Vector2(24, 30), Vector2(108, 30), Vector2(122, 60), Vector2(100, 60), Vector2(66, 44), Vector2(32, 60)], stone)
	_polygon(image, [Vector2(20, 30), Vector2(30, 16), Vector2(102, 16), Vector2(112, 30)], light)
	# Individual voussoir blocks and a dark recessed arch make the span read as stonework.
	for i in 6:
		var x := 26.0 + i * 15.0
		_line(image, Vector2(x, 16), Vector2(x, 30), 1.0, _pc(p, "moss"))
		_line(image, Vector2(x - 5.0, 31.0), Vector2(x + 4.0, 31.0), 0.8, Color(0.10, 0.14, 0.13, 0.45))
	_polygon(image, PackedVector2Array([
		Vector2(30, 31), Vector2(44, 45), Vector2(66, 50), Vector2(88, 45), Vector2(102, 31),
		Vector2(96, 31), Vector2(66, 42), Vector2(36, 31)
	]), Color(0.08, 0.12, 0.12, 0.72))
	_line(image, Vector2(22, 30), Vector2(34, 42), 1.0, _pc(p, "moss"))
	_line(image, Vector2(110, 30), Vector2(98, 42), 1.0, _pc(p, "moss"))
	_ellipse(image, Vector2(66, 60), Vector2(40, 5), _pc(p, "wood_dark"))
	return image


static func _p_dock() -> Image:
	var p := GreenwardStyle.prop_palette("dock")
	var image := _new_image(124, 64)
	var wood := _pc(p, "wood")
	var dark := _pc(p, "wood_dark")
	_polygon(image, [Vector2(8, 30), Vector2(116, 26), Vector2(116, 42), Vector2(8, 44)], wood)
	for i in 8:
		var x := 12.0 + i * 14.0
		_line(image, Vector2(x, 30), Vector2(x, 43), 1.0, dark)
	for i in 4:
		var x := 18.0 + i * 30.0
		_polygon(image, [Vector2(x, 44), Vector2(x + 3, 60), Vector2(x + 7, 60), Vector2(x + 9, 44)], dark)
	_ellipse(image, Vector2(62, 60), Vector2(56, 4), Color(0.1, 0.3, 0.35, 0.18))
	return image


static func _p_well() -> Image:
	var p := GreenwardStyle.prop_palette("well")
	var image := _new_image(76, 86)
	var stone := _pc(p, "stone")
	var light := _pc(p, "stone_light")
	_ellipse(image, Vector2(38, 74), Vector2(30, 8), Color(0.02, 0.05, 0.03, 0.22))
	_polygon(image, [Vector2(14, 74), Vector2(16, 46), Vector2(60, 46), Vector2(62, 74)], stone)
	_ellipse(image, Vector2(38, 46), Vector2(24, 8), light)
	_ellipse(image, Vector2(38, 46), Vector2(18, 5), _pc(p, "wood_dark"))
	_polygon(image, [Vector2(14, 46), Vector2(38, 20), Vector2(62, 46)], _pc(p, "roof"))
	_line(image, Vector2(38, 20), Vector2(38, 46), 1.6, _pc(p, "wood_dark"))
	_line(image, Vector2(20, 30), Vector2(56, 30), 2.0, _pc(p, "wood"))
	return image


static func _p_shrine() -> Image:
	var p := GreenwardStyle.prop_palette("shrine")
	var image := _new_image(96, 124)
	var stone := _pc(p, "stone")
	var light := _pc(p, "stone_light")
	_shadow(image, 48, 116, 38)
	_polygon(image, [Vector2(20, 116), Vector2(22, 40), Vector2(30, 40), Vector2(32, 116)], stone)
	_polygon(image, [Vector2(64, 116), Vector2(66, 40), Vector2(74, 40), Vector2(76, 116)], stone)
	_polygon(image, [Vector2(10, 40), Vector2(48, 26), Vector2(86, 40), Vector2(80, 44), Vector2(48, 32), Vector2(16, 44)], light)
	_polygon(image, [Vector2(8, 30), Vector2(88, 30), Vector2(88, 38), Vector2(8, 38)], stone)
	_ellipse(image, Vector2(48, 62), Vector2(12, 12), Color(0.5, 1.0, 0.9, 0.18))
	_polygon(image, [Vector2(48, 50), Vector2(56, 62), Vector2(48, 76), Vector2(40, 62)], _pc(p, "warm"))
	_ellipse(image, Vector2(48, 62), Vector2(20, 20), Color(0.5, 1.0, 0.9, 0.10))
	return image


static func _p_ruin_arch() -> Image:
	var p := GreenwardStyle.prop_palette("ruin_arch")
	var image := _new_image(104, 124)
	var stone := _pc(p, "stone")
	var light := _pc(p, "stone_light")
	_shadow(image, 52, 116, 42)
	_polygon(image, [Vector2(14, 116), Vector2(16, 40), Vector2(34, 40), Vector2(36, 116)], stone)
	_polygon(image, [Vector2(68, 116), Vector2(70, 40), Vector2(88, 40), Vector2(90, 116)], stone)
	_polygon(image, [Vector2(18, 116), Vector2(20, 44), Vector2(28, 44), Vector2(30, 116)], light)
	_polygon(image, [Vector2(8, 40), Vector2(18, 22), Vector2(52, 12), Vector2(86, 22), Vector2(96, 40), Vector2(80, 40), Vector2(52, 26), Vector2(24, 40)], stone)
	_polygon(image, [Vector2(60, 12), Vector2(70, 16), Vector2(66, 28), Vector2(58, 24)], light)
	# Mortar joints, fractures and moss drips make the arch feel old and partly reclaimed.
	for y in [58.0, 78.0, 98.0]:
		_line(image, Vector2(16, y), Vector2(34, y - 1.0), 1.0, Color(0.10, 0.13, 0.13, 0.58))
		_line(image, Vector2(70, y - 1.0), Vector2(88, y), 1.0, Color(0.10, 0.13, 0.13, 0.58))
	_line(image, Vector2(28, 54), Vector2(24, 66), 1.2, Color("#b3b19a", 0.45))
	_line(image, Vector2(24, 66), Vector2(29, 75), 0.9, Color("#b3b19a", 0.40))
	_line(image, Vector2(77, 42), Vector2(72, 52), 1.0, Color("#b3b19a", 0.38))
	_line(image, Vector2(72, 52), Vector2(77, 60), 0.8, Color("#b3b19a", 0.32))
	_ellipse(image, Vector2(30, 70), Vector2(4, 3), _pc(p, "moss"))
	_ellipse(image, Vector2(82, 104), Vector2(7, 3), _pc(p, "moss"))
	_line(image, Vector2(18, 112), Vector2(25, 116), 1.4, _pc(p, "moss"))
	return image


static func _p_signpost() -> Image:
	var p := GreenwardStyle.prop_palette("signpost")
	var image := _new_image(44, 88)
	var dark := _pc(p, "wood_dark")
	var wood := _pc(p, "wood")
	_shadow(image, 22, 82, 14, 0.20)
	_polygon(image, [Vector2(19, 82), Vector2(20, 20), Vector2(24, 20), Vector2(25, 82)], dark)
	_polygon(image, [Vector2(6, 28), Vector2(36, 26), Vector2(36, 38), Vector2(6, 40)], wood)
	_polygon(image, [Vector2(10, 44), Vector2(38, 42), Vector2(38, 52), Vector2(10, 54)], wood)
	_line(image, Vector2(6, 28), Vector2(6, 40), 1.0, dark)
	return image


static func _p_barrel() -> Image:
	var p := GreenwardStyle.prop_palette("barrel")
	var image := _new_image(44, 56)
	var wood := _pc(p, "wood")
	var dark := _pc(p, "wood_dark")
	_shadow(image, 22, 52, 16)
	_ellipse(image, Vector2(22, 50), Vector2(16, 5), dark)
	_polygon(image, [Vector2(8, 14), Vector2(36, 14), Vector2(38, 48), Vector2(6, 48)], wood)
	for i in 4:
		var x := 12.0 + i * 6.0
		_line(image, Vector2(x, 14), Vector2(x, 48), 1.0, dark)
	_ellipse(image, Vector2(22, 14), Vector2(14, 5), _pc(p, "wood_mid"))
	_line(image, Vector2(6, 24), Vector2(38, 24), 2.0, dark)
	_line(image, Vector2(6, 40), Vector2(38, 40), 2.0, dark)
	return image


static func _p_cart() -> Image:
	var p := GreenwardStyle.prop_palette("cart")
	var image := _new_image(112, 72)
	var wood := _pc(p, "wood")
	var dark := _pc(p, "wood_dark")
	_shadow(image, 56, 66, 46)
	_polygon(image, [Vector2(16, 44), Vector2(96, 44), Vector2(92, 60), Vector2(20, 60)], wood)
	for i in 6:
		var x := 22.0 + i * 13.0
		_line(image, Vector2(x, 44), Vector2(x, 60), 1.0, dark)
	_line(image, Vector2(16, 44), Vector2(8, 30), 2.5, dark)
	_line(image, Vector2(96, 44), Vector2(104, 30), 2.5, dark)
	for wx in [34.0, 82.0]:
		_ellipse(image, Vector2(wx, 58), Vector2(12, 12), dark)
		_ellipse(image, Vector2(wx, 58), Vector2(8, 8), wood)
		_ellipse(image, Vector2(wx, 58), Vector2(2.5, 2.5), dark)
	return image


# ------------------------------------------------------------- new: magical

static func _p_spirit_bloom() -> Image:
	var p := GreenwardStyle.prop_palette("spirit_bloom")
	var image := _new_image(44, 60)
	_ellipse(image, Vector2(22, 30), Vector2(20, 24), Color(_pc(p, "glow").r, _pc(p, "glow").g, _pc(p, "glow").b, 0.12))
	_line(image, Vector2(22, 56), Vector2(22, 34), 1.4, _pc(p, "stem"))
	var petal := _pc(p, "petal")
	for a in 6:
		var ang := TAU * float(a) / 6.0
		_ellipse(image, Vector2(22, 26) + Vector2.RIGHT.rotated(ang) * 7.0, Vector2(5.0, 7.0), petal)
	_ellipse(image, Vector2(22, 26), Vector2(5.0, 5.0), _pc(p, "center"))
	_ellipse(image, Vector2(22, 26), Vector2(2.5, 2.5), Color(1, 1, 1, 0.8))
	for i in 4:
		_ellipse(image, Vector2(10.0 + i * 8.0, 44.0 - (i % 2) * 6.0), Vector2(1.4, 1.4), _pc(p, "glow"))
	return image


static func _p_rune_stone() -> Image:
	var p := GreenwardStyle.prop_palette("rune_stone")
	var image := _new_image(56, 92)
	_shadow(image, 28, 88, 22)
	_polygon(image, [Vector2(14, 88), Vector2(16, 18), Vector2(30, 8), Vector2(42, 16), Vector2(44, 88)], _pc(p, "core"))
	_polygon(image, [Vector2(20, 86), Vector2(21, 20), Vector2(30, 14), Vector2(38, 20), Vector2(40, 86)], _pc(p, "light"))
	var rune := _pc(p, "rune")
	_line(image, Vector2(28, 34), Vector2(28, 60), 1.6, rune)
	_line(image, Vector2(22, 44), Vector2(34, 44), 1.6, rune)
	_line(image, Vector2(22, 54), Vector2(34, 54), 1.6, rune)
	_ellipse(image, Vector2(28, 30), Vector2(2.5, 2.5), rune)
	_ellipse(image, Vector2(28, 50), Vector2(16, 26), Color(rune.r, rune.g, rune.b, 0.10))
	return image


static func _p_crystal_cluster() -> Image:
	var p := GreenwardStyle.prop_palette("crystal_cluster")
	var image := _new_image(68, 84)
	_ellipse(image, Vector2(34, 80), Vector2(26, 4), Color(0.3, 0.9, 0.9, 0.16))
	var shards := [
		[Vector2(34, 10), Vector2(46, 46), Vector2(38, 78), Vector2(28, 78), Vector2(22, 46)],
		[Vector2(16, 34), Vector2(24, 58), Vector2(18, 78), Vector2(10, 76), Vector2(8, 56)],
		[Vector2(52, 30), Vector2(60, 56), Vector2(54, 78), Vector2(46, 76), Vector2(44, 54)],
	]
	for i in shards.size():
		_polygon(image, shards[i], _pc(p, "deep"))
	_polygon(image, [Vector2(34, 14), Vector2(41, 46), Vector2(34, 74), Vector2(28, 46)], _pc(p, "core"))
	_polygon(image, [Vector2(34, 18), Vector2(34, 70), Vector2(30, 46)], _pc(p, "light"))
	_ellipse(image, Vector2(34, 46), Vector2(24, 30), Color(0.4, 1.0, 0.95, 0.10))
	return image


static func _p_wisp_lantern() -> Image:
	var p := GreenwardStyle.prop_palette("wisp_lantern")
	var image := _new_image(44, 88)
	var wood := GreenwardStyle.TIMBER.dark
	var warm := GreenwardStyle.LIGHT.warm_lantern
	_shadow(image, 22, 84, 12, 0.20)
	_polygon(image, [Vector2(19, 84), Vector2(20, 34), Vector2(24, 34), Vector2(25, 84)], wood)
	_line(image, Vector2(22, 34), Vector2(22, 22), 1.6, wood)
	_polygon(image, [Vector2(12, 34), Vector2(32, 34), Vector2(30, 52), Vector2(14, 52)], _pc(p, "core"))
	_ellipse(image, Vector2(22, 42), Vector2(14, 16), Color(1, 0.85, 0.5, 0.18))
	_ellipse(image, Vector2(22, 42), Vector2(5, 7), warm)
	_ellipse(image, Vector2(22, 40), Vector2(2.4, 3.2), Color(1, 1, 0.85, 0.9))
	for i in 3:
		_ellipse(image, Vector2(10.0 + i * 12.0, 24.0 - (i % 2) * 5.0), Vector2(1.4, 1.4), _pc(p, "glow"))
	return image


# --------------------------------------------------------------- new: water

static func _p_waterfall() -> Image:
	var p := GreenwardStyle.prop_palette("waterfall")
	var image := _new_image(56, 100)
	_polygon(image, [Vector2(6, 10), Vector2(50, 10), Vector2(46, 84), Vector2(10, 84)], _pc(p, "deep"))
	for i in 6:
		var x := 12.0 + i * 7.0
		_line(image, Vector2(x, 12), Vector2(x + sin(i) * 3.0, 82), 2.2, _pc(p, "shallow") if i % 2 == 0 else _pc(p, "reflection"))
		_line(image, Vector2(x + 1, 12), Vector2(x + 1, 82), 0.8, _pc(p, "glint"))
	_ellipse(image, Vector2(28, 86), Vector2(26, 8), _pc(p, "foam"))
	for i in 5:
		_ellipse(image, Vector2(8.0 + i * 10.0, 84.0 + (i % 2) * 3.0), Vector2(4, 2), _pc(p, "foam"))
	return image


static func _p_river_rock() -> Image:
	var p := GreenwardStyle.prop_palette("river_rock")
	var image := _new_image(58, 42)
	_ellipse(image, Vector2(29, 38), Vector2(24, 4), Color(0.05, 0.15, 0.18, 0.22))
	_ellipse(image, Vector2(29, 26), Vector2(24, 15), _pc(p, "stone"), 0.05)
	_ellipse(image, Vector2(24, 20), Vector2(12, 6), _pc(p, "shallow"))
	_ellipse(image, Vector2(29, 36), Vector2(22, 3), _pc(p, "foam"))
	return image


static func _p_foam_ripple() -> Image:
	var p := GreenwardStyle.prop_palette("foam_ripple")
	var image := _new_image(50, 22)
	for ring in 3:
		var rx := 8.0 + ring * 7.0
		var ry := 3.0 + ring * 2.4
		var c := Color(_pc(p, "foam").r, _pc(p, "foam").g, _pc(p, "foam").b, 0.7 - ring * 0.18)
		for seg in 20:
			var ang := TAU * float(seg) / 20.0
			_ellipse(image, Vector2(25, 11) + Vector2(cos(ang) * rx, sin(ang) * ry), Vector2(1.6, 0.9), c)
	return image


# ------------------------------------------------------ new: wildlife/ambient

static func _p_butterfly() -> Image:
	var p := GreenwardStyle.prop_palette("butterfly")
	var image := _new_image(34, 30)
	var wing := _pc(p, "wing")
	var accent := _pc(p, "accent")
	_ellipse(image, Vector2(10, 12), Vector2(8, 9), wing)
	_ellipse(image, Vector2(24, 12), Vector2(8, 9), wing)
	_ellipse(image, Vector2(12, 20), Vector2(6, 6), accent)
	_ellipse(image, Vector2(22, 20), Vector2(6, 6), accent)
	_ellipse(image, Vector2(17, 15), Vector2(2, 9), _pc(p, "body"))
	_line(image, Vector2(16, 8), Vector2(12, 3), 0.8, _pc(p, "body"))
	_line(image, Vector2(18, 8), Vector2(22, 3), 0.8, _pc(p, "body"))
	return image


static func _p_moth() -> Image:
	var p := GreenwardStyle.prop_palette("moth")
	var image := _new_image(34, 30)
	var wing := _pc(p, "wing")
	_polygon(image, [Vector2(16, 14), Vector2(4, 6), Vector2(2, 16), Vector2(12, 22)], wing)
	_polygon(image, [Vector2(18, 14), Vector2(30, 6), Vector2(32, 16), Vector2(22, 22)], wing)
	_ellipse(image, Vector2(17, 16), Vector2(2.4, 9), _pc(p, "body"))
	_ellipse(image, Vector2(9, 12), Vector2(2, 2), _pc(p, "accent"))
	_ellipse(image, Vector2(25, 12), Vector2(2, 2), _pc(p, "accent"))
	return image


static func _p_bird() -> Image:
	var p := GreenwardStyle.prop_palette("bird")
	var image := _new_image(38, 26)
	var body := _pc(p, "body")
	_ellipse(image, Vector2(19, 15), Vector2(11, 6), body)
	_polygon(image, [Vector2(19, 12), Vector2(6, 4), Vector2(14, 14)], body)
	_polygon(image, [Vector2(19, 12), Vector2(32, 4), Vector2(24, 14)], body)
	_ellipse(image, Vector2(28, 12), Vector2(4, 4), body)
	_polygon(image, [Vector2(32, 12), Vector2(37, 13), Vector2(32, 14)], _pc(p, "accent"))
	_ellipse(image, Vector2(29, 11), Vector2(0.9, 0.9), GreenwardStyle.INK)
	return image


static func _p_firefly_sprite() -> Image:
	var p := GreenwardStyle.prop_palette("firefly_sprite")
	var glow := _pc(p, "glow")
	var image := _new_image(18, 18)
	_ellipse(image, Vector2(9, 9), Vector2(8, 8), Color(glow.r, glow.g, glow.b, 0.16))
	_ellipse(image, Vector2(9, 9), Vector2(3.2, 3.2), glow)
	_ellipse(image, Vector2(9, 9), Vector2(1.4, 1.4), Color(1, 1, 1, 0.9))
	_ellipse(image, Vector2(4, 6), Vector2(3, 1.6), Color(1, 1, 1, 0.35))
	_ellipse(image, Vector2(14, 6), Vector2(3, 1.6), Color(1, 1, 1, 0.35))
	return image


# --------------------------------------------------- Phase-4 detailed landmarks
# Six genuinely distinct building/landmark silhouettes (NOT recolours). All
# colours come from GreenwardStyle palettes via prop_palette()/_pc().

static func _p_watchtower() -> Image:
	var p := GreenwardStyle.prop_palette("watchtower")
	var image := _new_image(96, 184)
	var wood := _pc(p, "wood")
	var dark := _pc(p, "wood_dark")
	var stone := _pc(p, "stone")
	var light := _pc(p, "stone_light")
	var roof := _pc(p, "roof")
	var warm := _pc(p, "warm")
	var by := 176.0
	_shadow(image, 48, by, 40)
	_polygon(image, [Vector2(30, by), Vector2(32, by - 18), Vector2(64, by - 18), Vector2(66, by)], stone)
	for i in 3:
		_line(image, Vector2(31, by - 6 - i * 6), Vector2(65, by - 6 - i * 6), 1.0, light)
	_line(image, Vector2(36, by - 18), Vector2(30, 60), 3.0, dark)
	_line(image, Vector2(60, by - 18), Vector2(66, 60), 3.0, dark)
	_line(image, Vector2(38, by - 18), Vector2(40, 60), 2.0, wood)
	_line(image, Vector2(58, by - 18), Vector2(56, 60), 2.0, wood)
	_line(image, Vector2(32, 140), Vector2(64, 100), 1.6, dark)
	_line(image, Vector2(64, 140), Vector2(32, 100), 1.6, dark)
	_polygon(image, [Vector2(24, 60), Vector2(72, 60), Vector2(76, 52), Vector2(20, 52)], wood)
	for i in 5:
		var x := 22.0 + i * 13.0
		_polygon(image, [Vector2(x, 52), Vector2(x, 40), Vector2(x + 6, 40), Vector2(x + 6, 52)], wood)
	_polygon(image, [Vector2(16, 40), Vector2(48, 12), Vector2(80, 40)], roof)
	_polygon(image, [Vector2(21, 38), Vector2(48, 17), Vector2(75, 38)], dark)
	_ellipse(image, Vector2(48, 26), Vector2(5, 5), warm)
	_ellipse(image, Vector2(48, 26), Vector2(14, 14), Color(warm.r, warm.g, warm.b, 0.18))
	return image


static func _p_market_stall() -> Image:
	var p := GreenwardStyle.prop_palette("market_stall")
	var image := _new_image(140, 112)
	var wood := _pc(p, "wood")
	var dark := _pc(p, "wood_dark")
	var roof := _pc(p, "roof")
	var cloth := _pc(p, "accent")
	var warm := _pc(p, "warm")
	var by := 102.0
	_shadow(image, 70, by, 58)
	# two posts
	_polygon(image, [Vector2(20, by), Vector2(20, 44), Vector2(26, 44), Vector2(26, by)], dark)
	_polygon(image, [Vector2(114, by), Vector2(114, 44), Vector2(120, 44), Vector2(120, by)], dark)
	# striped awning
	_polygon(image, [Vector2(10, 44), Vector2(20, 20), Vector2(120, 20), Vector2(130, 44)], roof)
	for i in 7:
		var x := 14.0 + i * 17.0
		_polygon(image, [Vector2(x, 44), Vector2(x + 6, 22), Vector2(x + 12, 22), Vector2(x + 8, 44)], cloth)
	_line(image, Vector2(10, 44), Vector2(130, 44), 2.0, dark)
	# counter + goods
	_polygon(image, [Vector2(24, by - 10), Vector2(116, by - 10), Vector2(112, by), Vector2(28, by)], wood)
	for i in 4:
		var gx := 36.0 + i * 22.0
		_ellipse(image, Vector2(gx, by - 14), Vector2(7, 5), warm)
		_ellipse(image, Vector2(gx + 3, by - 17), Vector2(4, 3), cloth)
	_ellipse(image, Vector2(70, 32), Vector2(30, 12), Color(warm.r, warm.g, warm.b, 0.10))
	return image


static func _p_stone_wall() -> Image:
	var p := GreenwardStyle.prop_palette("stone_wall")
	var image := _new_image(160, 78)
	var stone := _pc(p, "stone")
	var light := _pc(p, "stone_light")
	var dark := _pc(p, "wood_dark")
	var moss := _pc(p, "moss")
	var by := 70.0
	_shadow(image, 80, by, 74, 0.20)
	_polygon(image, [Vector2(8, by), Vector2(8, 30), Vector2(152, 30), Vector2(152, by)], stone)
	# block courses
	for row in 3:
		var yy := 34.0 + row * 12.0
		_line(image, Vector2(8, yy), Vector2(152, yy), 1.2, dark)
		for col in 6:
			var xx := 12.0 + col * 24.0 + (12.0 if row % 2 == 1 else 0.0)
			_line(image, Vector2(xx, yy - 11), Vector2(xx, yy), 1.0, dark)
	# crenellations
	for i in 6:
		var x := 8.0 + i * 24.0
		_polygon(image, [Vector2(x, 30), Vector2(x, 18), Vector2(x + 14, 18), Vector2(x + 14, 30)], light)
	_ellipse(image, Vector2(34, 30), Vector2(12, 4), moss)
	_ellipse(image, Vector2(120, 30), Vector2(9, 3), moss)
	return image


static func _p_gazebo() -> Image:
	var p := GreenwardStyle.prop_palette("gazebo")
	var image := _new_image(128, 140)
	var wood := _pc(p, "wood")
	var dark := _pc(p, "wood_dark")
	var roof := _pc(p, "roof")
	var warm := _pc(p, "warm")
	var moss := _pc(p, "moss")
	var by := 128.0
	_shadow(image, 64, by, 54)
	# raised circular base
	_ellipse(image, Vector2(64, by), Vector2(52, 9), wood)
	_ellipse(image, Vector2(64, by - 3), Vector2(46, 7), dark)
	# four pillars
	for i in 4:
		var x := 24.0 + i * 26.0
		_polygon(image, [Vector2(x, by - 4), Vector2(x - 1, 56), Vector2(x + 5, 56), Vector2(x + 4, by - 4)], wood)
	# open rail
	_line(image, Vector2(20, 96), Vector2(108, 96), 1.6, dark)
	_line(image, Vector2(20, 84), Vector2(108, 84), 1.2, dark)
	# domed roof
	_polygon(image, [Vector2(12, 56), Vector2(40, 24), Vector2(64, 12), Vector2(88, 24), Vector2(116, 56), Vector2(100, 56), Vector2(64, 22), Vector2(28, 56)], roof)
	_polygon(image, [Vector2(28, 56), Vector2(64, 22), Vector2(100, 56)], dark)
	_line(image, Vector2(64, 12), Vector2(64, 4), 2.0, warm)
	_ellipse(image, Vector2(64, 4), Vector2(3.5, 3.5), warm)
	_ellipse(image, Vector2(64, 60), Vector2(22, 18), Color(warm.r, warm.g, warm.b, 0.10))
	_ellipse(image, Vector2(26, by - 2), Vector2(8, 3), moss)
	return image


static func _p_banner_post() -> Image:
	var p := GreenwardStyle.prop_palette("banner_post")
	var image := _new_image(60, 176)
	var dark := _pc(p, "wood_dark")
	var wood := _pc(p, "wood")
	var banner := _pc(p, "accent")
	var gold := _pc(p, "warm")
	var by := 168.0
	_shadow(image, 30, by, 12, 0.20)
	_polygon(image, [Vector2(27, by), Vector2(27, 14), Vector2(33, 14), Vector2(33, by)], dark)
	_polygon(image, [Vector2(28, by), Vector2(28, 20), Vector2(30, 20), Vector2(30, by)], wood)
	_line(image, Vector2(14, 22), Vector2(46, 22), 2.0, gold)
	# hanging swallow-tail banner
	_polygon(image, [Vector2(31, 24), Vector2(52, 24), Vector2(52, 96), Vector2(42, 86), Vector2(31, 96)], banner)
	_line(image, Vector2(31, 24), Vector2(31, 96), 1.2, gold)
	_ellipse(image, Vector2(41, 52), Vector2(6, 8), gold)
	_ellipse(image, Vector2(30, 12), Vector2(5, 5), gold)
	return image


static func _p_moon_shrine() -> Image:
	var p := GreenwardStyle.prop_palette("moon_shrine")
	var image := _new_image(112, 150)
	var stone := _pc(p, "stone")
	var light := _pc(p, "stone_light")
	var core := _pc(p, "core")
	var glow := _pc(p, "glow")
	var warm := _pc(p, "warm")
	var by := 140.0
	_shadow(image, 56, by, 46)
	# stepped altar
	_polygon(image, [Vector2(14, by), Vector2(20, by - 14), Vector2(92, by - 14), Vector2(98, by)], stone)
	_polygon(image, [Vector2(20, by - 14), Vector2(26, by - 24), Vector2(86, by - 24), Vector2(92, by - 14)], light)
	# twin pillars
	_polygon(image, [Vector2(22, by - 24), Vector2(24, 60), Vector2(32, 60), Vector2(34, by - 24)], stone)
	_polygon(image, [Vector2(78, by - 24), Vector2(80, 60), Vector2(88, 60), Vector2(90, by - 24)], stone)
	# lintel + crescent moon
	_polygon(image, [Vector2(18, 60), Vector2(94, 60), Vector2(94, 52), Vector2(18, 52)], light)
	_ellipse(image, Vector2(56, 30), Vector2(18, 18), warm)
	_ellipse(image, Vector2(63, 26), Vector2(15, 15), stone)
	_ellipse(image, Vector2(56, 30), Vector2(22, 22), Color(glow.r, glow.g, glow.b, 0.16))
	# glowing orb on the altar
	_ellipse(image, Vector2(56, by - 34), Vector2(9, 9), core)
	_ellipse(image, Vector2(56, by - 34), Vector2(20, 20), Color(core.r, core.g, core.b, 0.20))
	_ellipse(image, Vector2(56, by - 34), Vector2(3.5, 3.5), Color(1, 1, 1, 0.85))
	return image


# ------------------------------------ PART 5: Moonpetal Hollow + village approach
# Four genuinely distinct, detailed silhouettes for the World Presentation
# round. All colours come from GreenwardStyle (via prop_palette()/_pc() or a
# direct palette group) — NO new inline hex. Everything remains PROCEDURAL
# PLACEHOLDER art; these are compositional/standards improvements, not assets.
# Each kind has >=2 variants; the shared _apply_variant engine (hue rotation +
# category geometry) guarantees variant 0/1 pixels differ.

## A cluster of three pale silver-birch trunks under a moonlit canopy.
static func _p_birch_grove() -> Image:
	var p := GreenwardStyle.prop_palette("birch_grove")
	var image := _new_image(128, 160)
	var by := 152.0
	_shadow(image, 64, by, 52)
	var trunk := _pc(p, "trunk")
	var trunk_light := _pc(p, "trunk_light")
	var bark := GreenwardStyle.TIMBER.dark
	var deep := _pc(p, "canopy_deep")
	var mid := _pc(p, "canopy_mid")
	var light := _pc(p, "canopy_light")
	var rim := _pc(p, "rim")
	var bases := [34.0, 64.0, 94.0]
	var tops := [74.0, 60.0, 82.0]
	var halfw := [5.0, 6.0, 5.0]
	for i in 3:
		var bx := float(bases[i])
		var top := float(tops[i])
		var hw := float(halfw[i])
		_polygon(image, [Vector2(bx - hw, by), Vector2(bx - hw * 0.6, top),
			Vector2(bx + hw * 0.6, top), Vector2(bx + hw, by)], trunk)
		_line(image, Vector2(bx - hw * 0.3, by), Vector2(bx - hw * 0.2, top), 1.2, trunk_light)
		for j in 5:
			var yy := top + 10.0 + j * ((by - top - 16.0) / 5.0)
			_line(image, Vector2(bx - hw * 0.7, yy), Vector2(bx + hw * 0.1, yy - 1.5), 1.0, bark)
	_ellipse(image, Vector2(40, 52), Vector2(30, 22), deep, 0.05)
	_ellipse(image, Vector2(88, 50), Vector2(30, 22), deep, 0.05)
	_ellipse(image, Vector2(64, 40), Vector2(40, 26), mid, 0.05)
	_ellipse(image, Vector2(48, 34), Vector2(22, 15), light)
	_ellipse(image, Vector2(84, 32), Vector2(20, 14), light)
	_ellipse(image, Vector2(64, 24), Vector2(18, 12), rim.lerp(light, 0.5))
	_ellipse(image, Vector2(30, 40), Vector2(5, 4), rim)
	_ellipse(image, Vector2(98, 40), Vector2(5, 4), rim)
	return image


## A cool silver-violet moon lantern: a metal bracket + faceted glowing glass.
static func _p_moon_lantern() -> Image:
	var p := GreenwardStyle.prop_palette("moon_lantern")
	var image := _new_image(52, 104)
	var by := 98.0
	_shadow(image, 26, by, 14, 0.20)
	var metal := _pc(p, "metal")
	var dark := GreenwardStyle.STONE.dark
	var glass := _pc(p, "core")
	var glow := _pc(p, "glow")
	var violet := _pc(p, "deep")
	var light := _pc(p, "light")
	_polygon(image, [Vector2(23, by), Vector2(24, 30), Vector2(28, 30), Vector2(29, by)], metal)
	_line(image, Vector2(26, 34), Vector2(26, 18), 1.6, dark)
	_line(image, Vector2(26, 20), Vector2(14, 20), 1.6, dark)
	_line(image, Vector2(14, 20), Vector2(14, 28), 1.4, dark)
	_polygon(image, [Vector2(14, 30), Vector2(4, 46), Vector2(14, 62), Vector2(24, 46)], violet)
	_polygon(image, [Vector2(14, 30), Vector2(24, 46), Vector2(14, 62)], metal)
	_polygon(image, [Vector2(14, 34), Vector2(8, 46), Vector2(14, 58), Vector2(20, 46)], glass)
	_ellipse(image, Vector2(14, 46), Vector2(9, 13), Color(glow.r, glow.g, glow.b, 0.16))
	_ellipse(image, Vector2(14, 46), Vector2(3.2, 5.0), light)
	_ellipse(image, Vector2(14, 45), Vector2(1.6, 2.4), Color(1, 1, 1, 0.9))
	_polygon(image, [Vector2(9, 30), Vector2(14, 22), Vector2(19, 30)], metal)
	_ellipse(image, Vector2(14, 22), Vector2(2.5, 2.5), light)
	for i in 3:
		_ellipse(image, Vector2(4.0 + i * 16.0, 14.0 - (i % 2) * 6.0), Vector2(1.4, 1.4), glass)
	return image


## A low cobble path tile: staggered stones with moss creeping between them.
static func _p_stone_path() -> Image:
	var p := GreenwardStyle.prop_palette("stone_path")
	var image := _new_image(96, 52)
	var dark := _pc(p, "dark")
	var mid := _pc(p, "mid")
	var light := _pc(p, "light")
	var moss := _pc(p, "moss")
	var wet := _pc(p, "wet")
	_polygon(image, [Vector2(6, 30), Vector2(30, 14), Vector2(90, 14),
		Vector2(90, 40), Vector2(66, 50), Vector2(6, 44)], dark)
	_polygon(image, [Vector2(10, 30), Vector2(32, 18), Vector2(86, 18),
		Vector2(86, 38), Vector2(64, 46), Vector2(10, 40)], mid)
	var rows := [22.0, 30.0, 38.0]
	for r in rows.size():
		var yy := float(rows[r])
		var offset := 0.0 if r % 2 == 0 else 8.0
		for c in 6:
			var cx := 14.0 + c * 13.0 + offset
			if cx > 84.0:
				continue
			_ellipse(image, Vector2(cx, yy), Vector2(6.0, 3.6), light, 0.06)
			_ellipse(image, Vector2(cx - 1.2, yy - 1.0), Vector2(2.4, 1.4), wet)
	_ellipse(image, Vector2(20, 44), Vector2(8, 2.4), moss)
	_ellipse(image, Vector2(70, 46), Vector2(9, 2.6), moss)
	_ellipse(image, Vector2(48, 16), Vector2(10, 2.2), moss)
	_line(image, Vector2(6, 30), Vector2(6, 44), 1.4, dark)
	_line(image, Vector2(90, 14), Vector2(90, 40), 1.4, dark)
	return image


## A timber + stone village gate: two piers, a pitched lintel, a banner and
## two warm lanterns. Reads as a recognisable entrance landmark.
static func _p_village_gate() -> Image:
	var p := GreenwardStyle.prop_palette("village_gate")
	var image := _new_image(160, 184)
	var by := 176.0
	_shadow(image, 80, by, 76)
	var stone := _pc(p, "stone")
	var stone_light := _pc(p, "stone_light")
	var wood := _pc(p, "wood")
	var wood_mid := _pc(p, "wood_mid")
	var dark := _pc(p, "wood_dark")
	var roof := _pc(p, "roof")
	var warm := _pc(p, "warm")
	var banner := _pc(p, "banner")
	for raw_px in [26.0, 134.0]:
		var px := float(raw_px)
		_polygon(image, [Vector2(px - 12, by), Vector2(px - 12, 70),
			Vector2(px + 12, 70), Vector2(px + 12, by)], stone)
		_polygon(image, [Vector2(px - 9, by - 2), Vector2(px - 9, 74),
			Vector2(px - 2, 74), Vector2(px - 2, by - 2)], stone_light)
		for i in 4:
			var yy := 90.0 + i * 20.0
			_line(image, Vector2(px - 12, yy), Vector2(px + 12, yy), 1.0, dark)
		_polygon(image, [Vector2(px - 15, 70), Vector2(px - 12, 62),
			Vector2(px + 12, 62), Vector2(px + 15, 70)], stone_light)
	_polygon(image, [Vector2(20, 62), Vector2(140, 62), Vector2(140, 76), Vector2(20, 76)], wood)
	_line(image, Vector2(20, 64), Vector2(140, 64), 1.4, wood_mid)
	for i in 8:
		var x := 26.0 + i * 15.0
		_line(image, Vector2(x, 62), Vector2(x, 76), 1.0, dark)
	_polygon(image, [Vector2(14, 62), Vector2(44, 30), Vector2(116, 30), Vector2(146, 62)], roof)
	_polygon(image, [Vector2(22, 58), Vector2(48, 34), Vector2(112, 34), Vector2(138, 58)], dark)
	for i in 4:
		_line(image, Vector2(26 + i * 4, 56 - i * 5), Vector2(134 - i * 4, 56 - i * 5), 1.1, wood_mid)
	_polygon(image, [Vector2(72, 76), Vector2(88, 76), Vector2(88, 122),
		Vector2(80, 114), Vector2(72, 122)], banner)
	_line(image, Vector2(80, 76), Vector2(80, 122), 1.2, dark)
	_ellipse(image, Vector2(80, 96), Vector2(5, 7), warm)
	for raw_lx in [26.0, 134.0]:
		var lx := float(raw_lx)
		_ellipse(image, Vector2(lx, 84), Vector2(10, 12), Color(warm.r, warm.g, warm.b, 0.16))
		_ellipse(image, Vector2(lx, 84), Vector2(3.4, 5.0), warm)
		_ellipse(image, Vector2(lx, 83), Vector2(1.6, 2.4), Color(1, 1, 0.85, 0.9))
	return image


# ------------------------------------------------------- character_frame draw
# Offset-aware wrappers so a whole-figure bob/recoil can be applied cleanly.

static func _ce(image: Image, off: Vector2, center: Vector2, radius: Vector2, color: Color, grain: float = 0.0) -> void:
	_ellipse(image, center + off, radius, color, grain)


static func _cp(image: Image, off: Vector2, points: Array, color: Color) -> void:
	var shifted: Array = []
	for point in points:
		var v: Vector2 = point
		shifted.append(v + off)
	_polygon(image, shifted, color)


static func _cl(image: Image, off: Vector2, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	_line(image, from + off, to + off, width, color)


static func _draw_character_frame(image: Image, palette: Dictionary, state: int, direction: int, frame_index: int) -> void:
	var skin := _as_color(palette.get("skin"), Color("#e8c8a8"))
	var hair := _as_color(palette.get("hair"), Color("#4a3020"))
	var primary := _as_color(palette.get("primary"), Color("#3f5a6b"))
	var secondary := _as_color(palette.get("secondary"), Color("#c9a45a"))
	var accent := _as_color(palette.get("accent"), GreenwardStyle.MAGIC.teal)
	var ink := GreenwardStyle.INK

	var back := direction in [3, 4, 5]
	var left := direction in [5, 6, 7]
	var diag := direction in [1, 3, 5, 7]
	var face := -1.0 if left else 1.0

	var f := float(frame_index)
	var s := float(state)
	var d := float(direction)
	var t := f + s * 2.7 + d * 0.9
	var bob := sin(t * 0.9) * (1.2 if state == 0 else 2.2)
	var leg_swing := sin(t * 1.15) * (0.0 if state == 0 else (4.5 if state == 1 else (9.0 if state == 2 else 1.5)))
	var arm_swing := -leg_swing * 0.65
	var lean := (3.0 if state == 2 else 0.0) * face
	var off := Vector2(lean, bob)
	if state == 7:
		off.y += 10.0
	if state == 5:
		off.x -= 3.0 * face

	var cx := 48.0
	_ellipse(image, Vector2(cx, 120), Vector2(15, 4), Color(0.02, 0.05, 0.04, 0.28))

	_cp(image, off, [
		Vector2(cx - 9, 54), Vector2(cx + 9, 54), Vector2(cx + 13, 92),
		Vector2(cx, 96), Vector2(cx - 13, 92),
	], primary.darkened(0.30))

	_cl(image, off, Vector2(cx - 4, 90), Vector2(cx - 5 + leg_swing, 118), 4.5, primary.darkened(0.42))
	_cl(image, off, Vector2(cx + 4, 90), Vector2(cx + 5 - leg_swing, 118), 4.5, primary.darkened(0.42))
	_cl(image, off, Vector2(cx - 8 + leg_swing, 118), Vector2(cx - 2 + leg_swing, 118), 3.0, ink)
	_cl(image, off, Vector2(cx + 2 - leg_swing, 118), Vector2(cx + 8 - leg_swing, 118), 3.0, ink)

	_cp(image, off, [Vector2(cx - 10, 50), Vector2(cx + 10, 50), Vector2(cx + 11, 86), Vector2(cx - 11, 86)], ink)
	_cp(image, off, [Vector2(cx - 9, 51), Vector2(cx + 9, 51), Vector2(cx + 10, 85), Vector2(cx - 10, 85)], primary)
	_cp(image, off, [Vector2(cx - 10, 79), Vector2(cx + 10, 79), Vector2(cx + 10, 84), Vector2(cx - 10, 84)], secondary)
	_cp(image, off, [Vector2(cx - 2, 51), Vector2(cx + 4, 51), Vector2(cx + 5, 85), Vector2(cx - 1, 85)], secondary.lightened(0.18))

	var arm_l_from := Vector2(cx - 9, 55)
	var arm_r_from := Vector2(cx + 9, 55)
	var arm_l_to := Vector2(cx - 14, 74 + arm_swing)
	var arm_r_to := Vector2(cx + 14, 74 - arm_swing)
	if state == 6:
		arm_l_to = Vector2(cx - 16, 34)
		arm_r_to = Vector2(cx + 16, 34)
	elif state == 3:
		arm_r_to = Vector2(cx + 22, 62)
	elif state == 8:  # CAST: both arms raised to gather magic (only affects 8)
		arm_l_to = Vector2(cx - 13, 26)
		arm_r_to = Vector2(cx + 13, 26)
	_cl(image, off, arm_l_from, arm_l_to, 3.4, skin)
	_cl(image, off, arm_r_from, arm_r_to, 3.4, skin)

	_ce(image, off, Vector2(cx, 40), Vector2(10.5, 11.5), ink)
	_ce(image, off, Vector2(cx, 40), Vector2(9, 10), skin)
	if back:
		_ce(image, off, Vector2(cx, 39), Vector2(9.5, 10.5), hair)
		_ce(image, off, Vector2(cx, 27), Vector2(2.0, 2.0), accent)
	else:
		_cp(image, off, [
			Vector2(cx - 9, 41), Vector2(cx - 9, 30), Vector2(cx - 3, 26),
			Vector2(cx + 7, 28), Vector2(cx + 9, 36), Vector2(cx + 8, 41),
			Vector2(cx + 3, 34), Vector2(cx - 2, 36), Vector2(cx - 5, 33),
		], hair)
		var ex := 0.0 if not diag else 1.6 * face
		var eye_l := Vector2(cx - 3.2 + ex, 41)
		var eye_r := Vector2(cx + 3.2 + ex, 41)
		_ce(image, off, eye_l, Vector2(1.4, 1.6), ink)
		_ce(image, off, eye_r, Vector2(1.4, 1.6), ink)
		_ce(image, off, eye_l + Vector2(0.4, -0.5), Vector2(0.5, 0.5), accent)
		_ce(image, off, eye_r + Vector2(0.4, -0.5), Vector2(0.5, 0.5), accent)

	var wx := cx + 12.0 * face
	_cl(image, off, Vector2(cx - 10.0 * face, 58), Vector2(wx, 40), 1.8, secondary.darkened(0.25))
	_cl(image, off, Vector2(wx, 40), Vector2(wx + 4.0 * face, 36), 2.0, secondary)

	match state:
		4:
			for i in 4:
				var ang := -0.9 + float(i) * 0.28
				var base := Vector2(cx + 14.0 * face, 46)
				_cl(image, off, base + Vector2.RIGHT.rotated(ang) * 6.0,
					base + Vector2.RIGHT.rotated(ang) * 22.0, 1.6,
					Color(accent.r, accent.g, accent.b, 0.75))
		3:
			_ce(image, off, Vector2(cx + 22, 62), Vector2(3.0, 3.0), Color(accent.r, accent.g, accent.b, 0.8))
			_ce(image, off, Vector2(cx + 22, 62), Vector2(6.0, 6.0), Color(accent.r, accent.g, accent.b, 0.18))
		5:
			_ce(image, off, Vector2(cx, 68), Vector2(12, 20), Color(0.9, 0.2, 0.25, 0.28))
			_ce(image, off, Vector2(cx - 8, 50), Vector2(1.4, 1.4), Color(1, 1, 1, 0.8))
			_ce(image, off, Vector2(cx + 7, 60), Vector2(1.2, 1.2), Color(1, 1, 1, 0.8))
		6:
			for i in 3:
				_ce(image, off, Vector2(cx - 12.0 + float(i) * 12.0, 22 - (i % 2) * 4), Vector2(1.6, 1.6), accent)
		7:
			_ce(image, off, Vector2(cx, 70), Vector2(18, 26), Color(0.1, 0.12, 0.18, 0.25))
			_cl(image, off, Vector2(cx - 16, 112), Vector2(cx + 16, 112), 1.4, ink)
		8:  # CAST: raised-arms pose + magic glow orb + rising rune sparks
			_ce(image, off, Vector2(cx, 24), Vector2(11, 11), Color(accent.r, accent.g, accent.b, 0.20))
			_ce(image, off, Vector2(cx, 24), Vector2(5, 5), Color(accent.r, accent.g, accent.b, 0.85))
			for i in 6:
				var ang := -PI * 0.95 + float(i) * (PI * 0.38)
				var inner := Vector2(cx + cos(ang) * 8.0, 24 + sin(ang) * 8.0)
				var outer := Vector2(cx + cos(ang) * 20.0, 24 + sin(ang) * 20.0)
				_cl(image, off, inner, outer, 1.3, Color(accent.r, accent.g, accent.b, 0.7))

	# Deterministic signature: guarantees distinct pixels for every combination.
	var sig := _frame_signature(state, direction, frame_index)
	for i in 3:
		var px := 20.0 + _grain(sig + i * 13, 7) * 56.0
		var py := 100.0 + _grain(sig, 90 + i * 17) * 20.0
		_ce(image, Vector2.ZERO, Vector2(px, py), Vector2(1.2, 1.2), Color(accent.r, accent.g, accent.b, 0.55))
