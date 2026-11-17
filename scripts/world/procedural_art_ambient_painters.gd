class_name ProceduralArtAmbientPainters
extends RefCounted
## Magical, water and ambient wildlife raster painters.

static func paint_kind(kind: String) -> Image:
	match kind:
		"spirit_bloom": return _p_spirit_bloom()
		"rune_stone": return _p_rune_stone()
		"crystal_cluster": return _p_crystal_cluster()
		"wisp_lantern": return _p_wisp_lantern()
		"waterfall": return _p_waterfall()
		"river_rock": return _p_river_rock()
		"foam_ripple": return _p_foam_ripple()
		"butterfly": return _p_butterfly()
		"moth": return _p_moth()
		"bird": return _p_bird()
		"firefly_sprite": return _p_firefly_sprite()
		"moon_lantern": return _p_moon_lantern()
		_: return null


static func _p_spirit_bloom() -> Image:
	var p := GreenwardStyle.prop_palette("spirit_bloom")
	var image := ProceduralArt._new_image(44, 60)
	ProceduralArt._ellipse(image, Vector2(22, 30), Vector2(20, 24), Color(ProceduralArt._pc(p, "glow").r, ProceduralArt._pc(p, "glow").g, ProceduralArt._pc(p, "glow").b, 0.12))
	ProceduralArt._line(image, Vector2(22, 56), Vector2(22, 34), 1.4, ProceduralArt._pc(p, "stem"))
	var petal := ProceduralArt._pc(p, "petal")
	for a in 6:
		var ang := TAU * float(a) / 6.0
		ProceduralArt._ellipse(image, Vector2(22, 26) + Vector2.RIGHT.rotated(ang) * 7.0, Vector2(5.0, 7.0), petal)
	ProceduralArt._ellipse(image, Vector2(22, 26), Vector2(5.0, 5.0), ProceduralArt._pc(p, "center"))
	ProceduralArt._ellipse(image, Vector2(22, 26), Vector2(2.5, 2.5), Color(1, 1, 1, 0.8))
	for i in 4:
		ProceduralArt._ellipse(image, Vector2(10.0 + i * 8.0, 44.0 - (i % 2) * 6.0), Vector2(1.4, 1.4), ProceduralArt._pc(p, "glow"))
	return image

static func _p_rune_stone() -> Image:
	var p := GreenwardStyle.prop_palette("rune_stone")
	var image := ProceduralArt._new_image(56, 92)
	ProceduralArt._shadow(image, 28, 88, 22)
	ProceduralArt._polygon(image, [Vector2(14, 88), Vector2(16, 18), Vector2(30, 8), Vector2(42, 16), Vector2(44, 88)], ProceduralArt._pc(p, "core"))
	ProceduralArt._polygon(image, [Vector2(20, 86), Vector2(21, 20), Vector2(30, 14), Vector2(38, 20), Vector2(40, 86)], ProceduralArt._pc(p, "light"))
	var rune := ProceduralArt._pc(p, "rune")
	ProceduralArt._line(image, Vector2(28, 34), Vector2(28, 60), 1.6, rune)
	ProceduralArt._line(image, Vector2(22, 44), Vector2(34, 44), 1.6, rune)
	ProceduralArt._line(image, Vector2(22, 54), Vector2(34, 54), 1.6, rune)
	ProceduralArt._ellipse(image, Vector2(28, 30), Vector2(2.5, 2.5), rune)
	ProceduralArt._ellipse(image, Vector2(28, 50), Vector2(16, 26), Color(rune.r, rune.g, rune.b, 0.10))
	return image

static func _p_crystal_cluster() -> Image:
	var p := GreenwardStyle.prop_palette("crystal_cluster")
	var image := ProceduralArt._new_image(68, 84)
	ProceduralArt._ellipse(image, Vector2(34, 80), Vector2(26, 4), Color(0.3, 0.9, 0.9, 0.16))
	var shards := [
		[Vector2(34, 10), Vector2(46, 46), Vector2(38, 78), Vector2(28, 78), Vector2(22, 46)],
		[Vector2(16, 34), Vector2(24, 58), Vector2(18, 78), Vector2(10, 76), Vector2(8, 56)],
		[Vector2(52, 30), Vector2(60, 56), Vector2(54, 78), Vector2(46, 76), Vector2(44, 54)],
	]
	for i in shards.size():
		ProceduralArt._polygon(image, shards[i], ProceduralArt._pc(p, "deep"))
	ProceduralArt._polygon(image, [Vector2(34, 14), Vector2(41, 46), Vector2(34, 74), Vector2(28, 46)], ProceduralArt._pc(p, "core"))
	ProceduralArt._polygon(image, [Vector2(34, 18), Vector2(34, 70), Vector2(30, 46)], ProceduralArt._pc(p, "light"))
	ProceduralArt._ellipse(image, Vector2(34, 46), Vector2(24, 30), Color(0.4, 1.0, 0.95, 0.10))
	return image

static func _p_wisp_lantern() -> Image:
	var p := GreenwardStyle.prop_palette("wisp_lantern")
	var image := ProceduralArt._new_image(44, 88)
	var wood := GreenwardStyle.TIMBER.dark
	var warm := GreenwardStyle.LIGHT.warm_lantern
	ProceduralArt._shadow(image, 22, 84, 12, 0.20)
	ProceduralArt._polygon(image, [Vector2(19, 84), Vector2(20, 34), Vector2(24, 34), Vector2(25, 84)], wood)
	ProceduralArt._line(image, Vector2(22, 34), Vector2(22, 22), 1.6, wood)
	ProceduralArt._polygon(image, [Vector2(12, 34), Vector2(32, 34), Vector2(30, 52), Vector2(14, 52)], ProceduralArt._pc(p, "core"))
	ProceduralArt._ellipse(image, Vector2(22, 42), Vector2(14, 16), Color(1, 0.85, 0.5, 0.18))
	ProceduralArt._ellipse(image, Vector2(22, 42), Vector2(5, 7), warm)
	ProceduralArt._ellipse(image, Vector2(22, 40), Vector2(2.4, 3.2), Color(1, 1, 0.85, 0.9))
	for i in 3:
		ProceduralArt._ellipse(image, Vector2(10.0 + i * 12.0, 24.0 - (i % 2) * 5.0), Vector2(1.4, 1.4), ProceduralArt._pc(p, "glow"))
	return image


# --------------------------------------------------------------- new: water

static func _p_waterfall() -> Image:
	var p := GreenwardStyle.prop_palette("waterfall")
	var image := ProceduralArt._new_image(56, 100)
	ProceduralArt._polygon(image, [Vector2(6, 10), Vector2(50, 10), Vector2(46, 84), Vector2(10, 84)], ProceduralArt._pc(p, "deep"))
	for i in 6:
		var x := 12.0 + i * 7.0
		ProceduralArt._line(image, Vector2(x, 12), Vector2(x + sin(i) * 3.0, 82), 2.2, ProceduralArt._pc(p, "shallow") if i % 2 == 0 else ProceduralArt._pc(p, "reflection"))
		ProceduralArt._line(image, Vector2(x + 1, 12), Vector2(x + 1, 82), 0.8, ProceduralArt._pc(p, "glint"))
	ProceduralArt._ellipse(image, Vector2(28, 86), Vector2(26, 8), ProceduralArt._pc(p, "foam"))
	for i in 5:
		ProceduralArt._ellipse(image, Vector2(8.0 + i * 10.0, 84.0 + (i % 2) * 3.0), Vector2(4, 2), ProceduralArt._pc(p, "foam"))
	return image

static func _p_river_rock() -> Image:
	var p := GreenwardStyle.prop_palette("river_rock")
	var image := ProceduralArt._new_image(58, 42)
	ProceduralArt._ellipse(image, Vector2(29, 38), Vector2(24, 4), Color(0.05, 0.15, 0.18, 0.22))
	ProceduralArt._ellipse(image, Vector2(29, 26), Vector2(24, 15), ProceduralArt._pc(p, "stone"), 0.05)
	ProceduralArt._ellipse(image, Vector2(24, 20), Vector2(12, 6), ProceduralArt._pc(p, "shallow"))
	ProceduralArt._ellipse(image, Vector2(29, 36), Vector2(22, 3), ProceduralArt._pc(p, "foam"))
	return image

static func _p_foam_ripple() -> Image:
	var p := GreenwardStyle.prop_palette("foam_ripple")
	var image := ProceduralArt._new_image(50, 22)
	for ring in 3:
		var rx := 8.0 + ring * 7.0
		var ry := 3.0 + ring * 2.4
		var c := Color(ProceduralArt._pc(p, "foam").r, ProceduralArt._pc(p, "foam").g, ProceduralArt._pc(p, "foam").b, 0.7 - ring * 0.18)
		for seg in 20:
			var ang := TAU * float(seg) / 20.0
			ProceduralArt._ellipse(image, Vector2(25, 11) + Vector2(cos(ang) * rx, sin(ang) * ry), Vector2(1.6, 0.9), c)
	return image


# ------------------------------------------------------ new: wildlife/ambient

static func _p_butterfly() -> Image:
	var p := GreenwardStyle.prop_palette("butterfly")
	var image := ProceduralArt._new_image(34, 30)
	var wing := ProceduralArt._pc(p, "wing")
	var accent := ProceduralArt._pc(p, "accent")
	ProceduralArt._ellipse(image, Vector2(10, 12), Vector2(8, 9), wing)
	ProceduralArt._ellipse(image, Vector2(24, 12), Vector2(8, 9), wing)
	ProceduralArt._ellipse(image, Vector2(12, 20), Vector2(6, 6), accent)
	ProceduralArt._ellipse(image, Vector2(22, 20), Vector2(6, 6), accent)
	ProceduralArt._ellipse(image, Vector2(17, 15), Vector2(2, 9), ProceduralArt._pc(p, "body"))
	ProceduralArt._line(image, Vector2(16, 8), Vector2(12, 3), 0.8, ProceduralArt._pc(p, "body"))
	ProceduralArt._line(image, Vector2(18, 8), Vector2(22, 3), 0.8, ProceduralArt._pc(p, "body"))
	return image

static func _p_moth() -> Image:
	var p := GreenwardStyle.prop_palette("moth")
	var image := ProceduralArt._new_image(34, 30)
	var wing := ProceduralArt._pc(p, "wing")
	ProceduralArt._polygon(image, [Vector2(16, 14), Vector2(4, 6), Vector2(2, 16), Vector2(12, 22)], wing)
	ProceduralArt._polygon(image, [Vector2(18, 14), Vector2(30, 6), Vector2(32, 16), Vector2(22, 22)], wing)
	ProceduralArt._ellipse(image, Vector2(17, 16), Vector2(2.4, 9), ProceduralArt._pc(p, "body"))
	ProceduralArt._ellipse(image, Vector2(9, 12), Vector2(2, 2), ProceduralArt._pc(p, "accent"))
	ProceduralArt._ellipse(image, Vector2(25, 12), Vector2(2, 2), ProceduralArt._pc(p, "accent"))
	return image

static func _p_bird() -> Image:
	var p := GreenwardStyle.prop_palette("bird")
	var image := ProceduralArt._new_image(38, 26)
	var body := ProceduralArt._pc(p, "body")
	ProceduralArt._ellipse(image, Vector2(19, 15), Vector2(11, 6), body)
	ProceduralArt._polygon(image, [Vector2(19, 12), Vector2(6, 4), Vector2(14, 14)], body)
	ProceduralArt._polygon(image, [Vector2(19, 12), Vector2(32, 4), Vector2(24, 14)], body)
	ProceduralArt._ellipse(image, Vector2(28, 12), Vector2(4, 4), body)
	ProceduralArt._polygon(image, [Vector2(32, 12), Vector2(37, 13), Vector2(32, 14)], ProceduralArt._pc(p, "accent"))
	ProceduralArt._ellipse(image, Vector2(29, 11), Vector2(0.9, 0.9), GreenwardStyle.INK)
	return image

static func _p_firefly_sprite() -> Image:
	var p := GreenwardStyle.prop_palette("firefly_sprite")
	var glow := ProceduralArt._pc(p, "glow")
	var image := ProceduralArt._new_image(18, 18)
	ProceduralArt._ellipse(image, Vector2(9, 9), Vector2(8, 8), Color(glow.r, glow.g, glow.b, 0.16))
	ProceduralArt._ellipse(image, Vector2(9, 9), Vector2(3.2, 3.2), glow)
	ProceduralArt._ellipse(image, Vector2(9, 9), Vector2(1.4, 1.4), Color(1, 1, 1, 0.9))
	ProceduralArt._ellipse(image, Vector2(4, 6), Vector2(3, 1.6), Color(1, 1, 1, 0.35))
	ProceduralArt._ellipse(image, Vector2(14, 6), Vector2(3, 1.6), Color(1, 1, 1, 0.35))
	return image


# --------------------------------------------------- Phase-4 detailed landmarks
# Six genuinely distinct building/landmark silhouettes (NOT recolours). All
# colours come from GreenwardStyle palettes via prop_palette()/ProceduralArt._pc().

static func _p_moon_lantern() -> Image:
	var p := GreenwardStyle.prop_palette("moon_lantern")
	var image := ProceduralArt._new_image(52, 104)
	var by := 98.0
	ProceduralArt._shadow(image, 26, by, 14, 0.20)
	var metal := ProceduralArt._pc(p, "metal")
	var dark := GreenwardStyle.STONE.dark
	var glass := ProceduralArt._pc(p, "core")
	var glow := ProceduralArt._pc(p, "glow")
	var violet := ProceduralArt._pc(p, "deep")
	var light := ProceduralArt._pc(p, "light")
	ProceduralArt._polygon(image, [Vector2(23, by), Vector2(24, 30), Vector2(28, 30), Vector2(29, by)], metal)
	ProceduralArt._line(image, Vector2(26, 34), Vector2(26, 18), 1.6, dark)
	ProceduralArt._line(image, Vector2(26, 20), Vector2(14, 20), 1.6, dark)
	ProceduralArt._line(image, Vector2(14, 20), Vector2(14, 28), 1.4, dark)
	ProceduralArt._polygon(image, [Vector2(14, 30), Vector2(4, 46), Vector2(14, 62), Vector2(24, 46)], violet)
	ProceduralArt._polygon(image, [Vector2(14, 30), Vector2(24, 46), Vector2(14, 62)], metal)
	ProceduralArt._polygon(image, [Vector2(14, 34), Vector2(8, 46), Vector2(14, 58), Vector2(20, 46)], glass)
	ProceduralArt._ellipse(image, Vector2(14, 46), Vector2(9, 13), Color(glow.r, glow.g, glow.b, 0.16))
	ProceduralArt._ellipse(image, Vector2(14, 46), Vector2(3.2, 5.0), light)
	ProceduralArt._ellipse(image, Vector2(14, 45), Vector2(1.6, 2.4), Color(1, 1, 1, 0.9))
	ProceduralArt._polygon(image, [Vector2(9, 30), Vector2(14, 22), Vector2(19, 30)], metal)
	ProceduralArt._ellipse(image, Vector2(14, 22), Vector2(2.5, 2.5), light)
	for i in 3:
		ProceduralArt._ellipse(image, Vector2(4.0 + i * 16.0, 14.0 - (i % 2) * 6.0), Vector2(1.4, 1.4), glass)
	return image


## A low cobble path tile: staggered stones with moss creeping between them.
