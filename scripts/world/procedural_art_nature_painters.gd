class_name ProceduralArtNaturePainters
extends RefCounted
## Nature and ground-detail raster painters.

static func paint_kind(kind: String) -> Image:
	match kind:
		"willow_tree": return _p_willow_tree()
		"birch_tree": return _p_birch_tree()
		"pine_tree": return _p_pine_tree()
		"blossom_tree": return _p_blossom_tree()
		"dead_tree": return _p_dead_tree()
		"fern": return _p_fern()
		"tall_grass": return _p_tall_grass()
		"reeds": return _p_reeds()
		"lily_pad": return _p_lily_pad()
		"moss_rock": return _p_moss_rock()
		"pebble": return _p_pebble()
		"flower_cluster": return _p_flower_cluster()
		"berry_bush": return _p_berry_bush()
		"glow_mushroom": return _p_glow_mushroom()
		"birch_grove": return _p_birch_grove()
		_: return null


static func _p_willow_tree() -> Image:
	var p := GreenwardStyle.prop_palette("willow_tree")
	var image := ProceduralArt._new_image(116, 164)
	var cx := 58.0
	var by := 156.0
	var deep := ProceduralArt._pc(p, "canopy_deep")
	var mid := ProceduralArt._pc(p, "canopy_mid")
	var light := ProceduralArt._pc(p, "canopy_light")
	ProceduralArt._shadow(image, cx, by, 38.0)
	# A curved trunk and long lateral boughs support the hanging crown.
	ProceduralArt._polygon(image, PackedVector2Array([
		Vector2(49, by), Vector2(47, 92), Vector2(52, 62),
		Vector2(61, 60), Vector2(66, 94), Vector2(69, by)
	]), ProceduralArt._pc(p, "trunk"))
	ProceduralArt._line(image, Vector2(53, 148), Vector2(57, 68), 2.2, ProceduralArt._pc(p, "trunk_light"))
	for branch in range(5):
		var side := -1.0 if branch % 2 == 0 else 1.0
		var start := Vector2(58.0 + side * 2.0, 78.0 + float(branch) * 4.0)
		var end := Vector2(58.0 + side * (26.0 + float(branch % 3) * 5.0), 40.0 + float(branch) * 5.0)
		ProceduralArt._line(image, start, end, 3.0 if branch < 2 else 2.0, ProceduralArt._pc(p, "trunk"))
	# Broad, uneven crown with scalloped edges; avoid a single circular canopy.
	ProceduralArt._polygon(image, PackedVector2Array([
		Vector2(12, 54), Vector2(18, 30), Vector2(36, 18), Vector2(52, 22),
		Vector2(66, 12), Vector2(90, 22), Vector2(105, 43), Vector2(101, 68),
		Vector2(84, 78), Vector2(31, 78), Vector2(14, 68)
	]), deep)
	for cluster in [
		Vector2(29, 42), Vector2(48, 32), Vector2(72, 31), Vector2(91, 43),
		Vector2(38, 57), Vector2(77, 57)
	]:
		ProceduralArt._ellipse(image, cluster, Vector2(17, 13), mid, 0.05)
	ProceduralArt._ellipse(image, Vector2(43, 30), Vector2(13, 9), light, 0.05)
	ProceduralArt._ellipse(image, Vector2(78, 29), Vector2(14, 9), light, 0.05)
	# Willow curtains are long, tapering leaf sprays with irregular lengths.
	for i in range(17):
		var x := 16.0 + float(i) * 5.2
		var root_y := 56.0 + 8.0 * absf((x - cx) / 58.0)
		var length := 34.0 + 22.0 * absf(sin(float(i) * 1.71))
		var sway := sin(float(i) * 1.37) * 5.0
		var tip := Vector2(x + sway, root_y + length)
		ProceduralArt._line(image, Vector2(x, root_y), tip, 1.8, mid if i % 3 == 0 else light)
		for leaf in range(4):
			var t := 0.22 + float(leaf) * 0.18
			var point := Vector2(x, root_y).lerp(tip, t)
			var lean := -1.0 if (i + leaf) % 2 == 0 else 1.0
			ProceduralArt._line(image, point, point + Vector2(lean * 4.0, 3.0), 1.1, light if leaf % 2 == 0 else mid)
	return image

static func _p_birch_tree() -> Image:
	var p := GreenwardStyle.prop_palette("birch_tree")
	var image := ProceduralArt._new_image(76, 156)
	var cx := 38.0
	var by := 148.0
	ProceduralArt._shadow(image, cx, by, 22.0)
	ProceduralArt._polygon(image, [Vector2(cx - 6, by), Vector2(cx - 3, 30), Vector2(cx + 3, 30), Vector2(cx + 6, by)], ProceduralArt._pc(p, "trunk"))
	for i in 6:
		var y := 44.0 + i * 16.0
		ProceduralArt._line(image, Vector2(cx - 5, y), Vector2(cx + 1, y - 2), 1.4, ProceduralArt._pc(p, "canopy_deep"))
	var deep := ProceduralArt._pc(p, "canopy_deep")
	var light := ProceduralArt._pc(p, "canopy_light")
	ProceduralArt._ellipse(image, Vector2(cx - 10, 30), Vector2(22, 16), deep, 0.05)
	ProceduralArt._ellipse(image, Vector2(cx + 12, 26), Vector2(20, 15), deep, 0.05)
	ProceduralArt._ellipse(image, Vector2(cx, 18), Vector2(22, 16), ProceduralArt._pc(p, "canopy_mid"), 0.05)
	ProceduralArt._ellipse(image, Vector2(cx - 8, 12), Vector2(10, 7), light)
	return image

static func _p_pine_tree() -> Image:
	var p := GreenwardStyle.prop_palette("pine_tree")
	var image := ProceduralArt._new_image(84, 156)
	var cx := 42.0
	var by := 148.0
	ProceduralArt._shadow(image, cx, by, 24.0)
	ProceduralArt._polygon(image, [Vector2(cx - 6, by), Vector2(cx - 4, 40), Vector2(cx + 4, 40), Vector2(cx + 6, by)], ProceduralArt._pc(p, "trunk"))
	var deep := ProceduralArt._pc(p, "canopy_deep")
	var mid := ProceduralArt._pc(p, "canopy_mid")
	var light := ProceduralArt._pc(p, "canopy_light")
	for tier in 4:
		var top_y := 12.0 + tier * 26.0
		var half := 12.0 + tier * 8.0
		ProceduralArt._polygon(image, [
			Vector2(cx, top_y), Vector2(cx + half, top_y + 30), Vector2(cx - half, top_y + 30),
		], deep if tier % 2 == 0 else mid)
		ProceduralArt._polygon(image, [
			Vector2(cx, top_y + 4), Vector2(cx + half * 0.6, top_y + 26), Vector2(cx, top_y + 26),
		], light)
	for tier in 4:
		var top_y := 12.0 + tier * 26.0
		ProceduralArt._ellipse(image, Vector2(cx - (8.0 + tier * 4.0), top_y + 22), Vector2(4, 3), light)
	return image

static func _p_blossom_tree() -> Image:
	var p := GreenwardStyle.prop_palette("blossom_tree")
	var image := ProceduralArt._new_image(112, 132)
	var cx := 56.0
	var by := 124.0
	ProceduralArt._shadow(image, cx, by, 32.0)
	ProceduralArt._polygon(image, [Vector2(cx - 8, by), Vector2(cx - 4, 62), Vector2(cx + 4, 62), Vector2(cx + 9, by)], ProceduralArt._pc(p, "trunk"))
	ProceduralArt._line(image, Vector2(cx, 78), Vector2(cx - 22, 56), 3.0, ProceduralArt._pc(p, "trunk"))
	ProceduralArt._line(image, Vector2(cx, 78), Vector2(cx + 22, 54), 3.0, ProceduralArt._pc(p, "trunk"))
	var mid := ProceduralArt._pc(p, "canopy_mid")
	var petal := ProceduralArt._pc(p, "petal")
	ProceduralArt._ellipse(image, Vector2(cx, 46), Vector2(44, 28), mid, 0.05)
	ProceduralArt._ellipse(image, Vector2(cx - 28, 54), Vector2(20, 16), mid, 0.05)
	ProceduralArt._ellipse(image, Vector2(cx + 28, 52), Vector2(20, 16), mid, 0.05)
	for i in 12:
		var ang := TAU * float(i) / 12.0
		var rx := cx + cos(ang) * 34.0
		var ry := 44.0 + sin(ang) * 20.0
		ProceduralArt._ellipse(image, Vector2(rx, ry), Vector2(6.0, 5.0), petal)
		ProceduralArt._ellipse(image, Vector2(rx, ry), Vector2(2.0, 2.0), GreenwardStyle.ACCENTS.petal_alt)
	return image

static func _p_dead_tree() -> Image:
	var p := GreenwardStyle.prop_palette("dead_tree")
	var image := ProceduralArt._new_image(96, 140)
	var cx := 48.0
	var by := 132.0
	ProceduralArt._shadow(image, cx, by, 26.0, 0.20)
	var trunk := ProceduralArt._pc(p, "trunk")
	ProceduralArt._polygon(image, [Vector2(cx - 7, by), Vector2(cx - 3, 40), Vector2(cx + 3, 40), Vector2(cx + 8, by)], trunk)
	var branches := [
		[Vector2(cx - 2, 62), Vector2(cx - 30, 30), 3.5],
		[Vector2(cx + 2, 58), Vector2(cx + 28, 26), 3.5],
		[Vector2(cx - 2, 48), Vector2(cx - 20, 18), 2.4],
		[Vector2(cx + 2, 46), Vector2(cx + 18, 14), 2.4],
		[Vector2(cx - 28, 32), Vector2(cx - 36, 18), 1.6],
		[Vector2(cx + 26, 28), Vector2(cx + 34, 12), 1.6],
	]
	for b in branches:
		ProceduralArt._line(image, b[0], b[1], b[2], trunk)
	return image


# --------------------------------------------------------------- new: ground

static func _p_fern() -> Image:
	var p := GreenwardStyle.prop_palette("fern")
	var image := ProceduralArt._new_image(52, 46)
	var cx := 26.0
	var by := 42.0
	var dark := ProceduralArt._pc(p, "dark")
	var light := ProceduralArt._pc(p, "light")
	for i in 5:
		var ang := -PI * 0.85 + float(i) * (PI * 0.7 / 4.0)
		var tip := Vector2(cx, by) + Vector2.UP.rotated(ang) * 30.0
		ProceduralArt._line(image, Vector2(cx, by), tip, 1.2, dark)
		for j in 5:
			var t := (float(j) + 1.0) / 6.0
			var pos := Vector2(cx, by).lerp(tip, t)
			ProceduralArt._ellipse(image, pos + Vector2(-3, -1), Vector2(3.0, 1.6), light)
			ProceduralArt._ellipse(image, pos + Vector2(3, -1), Vector2(3.0, 1.6), light)
	return image

static func _p_tall_grass() -> Image:
	var p := GreenwardStyle.prop_palette("tall_grass")
	var image := ProceduralArt._new_image(44, 52)
	var cx := 22.0
	var by := 48.0
	var mid := ProceduralArt._pc(p, "mid")
	var light := ProceduralArt._pc(p, "light")
	for i in 7:
		var x := cx - 16.0 + i * 5.0
		var sway := sin(i * 1.7) * 6.0
		var height := 26.0 + (i % 3) * 8.0
		ProceduralArt._line(image, Vector2(x, by), Vector2(x + sway, by - height), 1.3, light if i % 2 == 0 else mid)
	return image

static func _p_reeds() -> Image:
	var p := GreenwardStyle.prop_palette("reeds")
	var image := ProceduralArt._new_image(48, 68)
	var cx := 24.0
	var by := 64.0
	var mid := ProceduralArt._pc(p, "mid")
	var light := ProceduralArt._pc(p, "light")
	for i in 4:
		var x := 10.0 + i * 9.0
		var top := 12.0 + (i % 2) * 8.0
		ProceduralArt._line(image, Vector2(x, by), Vector2(x + 2, top), 1.6, mid)
		ProceduralArt._ellipse(image, Vector2(x + 2, top), Vector2(2.6, 7.0), light)
		ProceduralArt._ellipse(image, Vector2(x + 2, top - 4), Vector2(1.4, 2.0), ProceduralArt._pc(p, "cap_a"))
	return image

static func _p_lily_pad() -> Image:
	var p := GreenwardStyle.prop_palette("lily_pad")
	var image := ProceduralArt._new_image(46, 26)
	ProceduralArt._ellipse(image, Vector2(23, 15), Vector2(20, 9), ProceduralArt._pc(p, "mid"), 0.04)
	ProceduralArt._ellipse(image, Vector2(21, 13), Vector2(15, 6), ProceduralArt._pc(p, "light"))
	for a in 5:
		var ang := TAU * float(a) / 5.0
		ProceduralArt._ellipse(image, Vector2(30, 11) + Vector2.RIGHT.rotated(ang) * 3.0, Vector2(2.6, 2.6), GreenwardStyle.ACCENTS.petal)
	ProceduralArt._ellipse(image, Vector2(30, 11), Vector2(1.8, 1.8), GreenwardStyle.ACCENTS.petal_alt)
	return image

static func _p_moss_rock() -> Image:
	var p := GreenwardStyle.prop_palette("moss_rock")
	var image := ProceduralArt._new_image(64, 48)
	ProceduralArt._ellipse(image, Vector2(32, 42), Vector2(24, 5), Color(0.02, 0.05, 0.03, 0.25))
	ProceduralArt._polygon(image, [Vector2(8, 42), Vector2(14, 20), Vector2(30, 12), Vector2(50, 18), Vector2(58, 38), Vector2(50, 44)], ProceduralArt._pc(p, "dark"))
	ProceduralArt._polygon(image, [Vector2(16, 38), Vector2(20, 22), Vector2(31, 16), Vector2(44, 22), Vector2(48, 34)], ProceduralArt._pc(p, "mid"))
	ProceduralArt._ellipse(image, Vector2(26, 18), Vector2(14, 5), ProceduralArt._pc(p, "moss"))
	ProceduralArt._ellipse(image, Vector2(40, 20), Vector2(10, 4), ProceduralArt._pc(p, "light"))
	ProceduralArt._ellipse(image, Vector2(22, 30), Vector2(3, 2), ProceduralArt._pc(p, "moss"))
	return image

static func _p_pebble() -> Image:
	var p := GreenwardStyle.prop_palette("pebble")
	var image := ProceduralArt._new_image(26, 18)
	ProceduralArt._ellipse(image, Vector2(13, 15), Vector2(11, 3), Color(0.02, 0.05, 0.03, 0.20))
	ProceduralArt._ellipse(image, Vector2(13, 11), Vector2(11, 7), ProceduralArt._pc(p, "mid"), 0.05)
	ProceduralArt._ellipse(image, Vector2(11, 9), Vector2(5, 3), ProceduralArt._pc(p, "light"))
	return image

static func _p_flower_cluster() -> Image:
	var p := GreenwardStyle.prop_palette("flower_cluster")
	var image := ProceduralArt._new_image(44, 40)
	var stem := ProceduralArt._pc(p, "stem")
	var petal := ProceduralArt._pc(p, "petal")
	var alt := ProceduralArt._pc(p, "petal_alt")
	var center := ProceduralArt._pc(p, "center")
	var spots := [Vector2(12, 14), Vector2(30, 12), Vector2(22, 22), Vector2(16, 28), Vector2(34, 28)]
	for i in spots.size():
		ProceduralArt._line(image, Vector2(spots[i].x, 38), spots[i], 1.1, stem)
		var col := petal if i % 2 == 0 else alt
		for a in 5:
			var ang := TAU * float(a) / 5.0
			ProceduralArt._ellipse(image, spots[i] + Vector2.RIGHT.rotated(ang) * 3.2, Vector2(2.6, 2.6), col)
		ProceduralArt._ellipse(image, spots[i], Vector2(1.8, 1.8), center)
	return image

static func _p_berry_bush() -> Image:
	var p := GreenwardStyle.prop_palette("berry_bush")
	var image := ProceduralArt._new_image(64, 50)
	ProceduralArt._shadow(image, 32, 46, 24)
	ProceduralArt._ellipse(image, Vector2(22, 30), Vector2(16, 14), ProceduralArt._pc(p, "leaf"), 0.05)
	ProceduralArt._ellipse(image, Vector2(42, 30), Vector2(16, 14), ProceduralArt._pc(p, "leaf"), 0.05)
	ProceduralArt._ellipse(image, Vector2(32, 22), Vector2(18, 15), ProceduralArt._pc(p, "leaf"), 0.05)
	for i in 7:
		var ang := TAU * float(i) / 7.0
		var pos := Vector2(32, 26) + Vector2.RIGHT.rotated(ang) * 14.0
		ProceduralArt._ellipse(image, pos, Vector2(2.6, 2.6), ProceduralArt._pc(p, "berry"))
		ProceduralArt._ellipse(image, pos + Vector2(-0.8, -0.8), Vector2(0.9, 0.9), Color(1, 1, 1, 0.5))
	return image

static func _p_glow_mushroom() -> Image:
	var p := GreenwardStyle.prop_palette("glow_mushroom")
	var image := ProceduralArt._new_image(38, 46)
	ProceduralArt._ellipse(image, Vector2(19, 24), Vector2(16, 14), Color(0.4, 1.0, 0.8, 0.10))
	ProceduralArt._line(image, Vector2(19, 42), Vector2(19, 24), 3.2, ProceduralArt._pc(p, "light"))
	var cap := ProceduralArt._pc(p, "cap_a")
	ProceduralArt._ellipse(image, Vector2(19, 20), Vector2(13, 8), cap)
	ProceduralArt._ellipse(image, Vector2(14, 17), Vector2(3, 2), Color(1, 1, 1, 0.6))
	ProceduralArt._ellipse(image, Vector2(24, 18), Vector2(2.4, 1.8), Color(1, 1, 1, 0.6))
	ProceduralArt._ellipse(image, Vector2(19, 13), Vector2(2, 1.6), Color(1, 1, 1, 0.6))
	ProceduralArt._ellipse(image, Vector2(19, 22), Vector2(16, 12), Color(0.5, 1.0, 0.85, 0.12))
	return image


# ----------------------------------------------------------- new: structures

static func _p_birch_grove() -> Image:
	var p := GreenwardStyle.prop_palette("birch_grove")
	var image := ProceduralArt._new_image(128, 160)
	var by := 152.0
	ProceduralArt._shadow(image, 64, by, 52)
	var trunk := ProceduralArt._pc(p, "trunk")
	var trunk_light := ProceduralArt._pc(p, "trunk_light")
	var bark := GreenwardStyle.TIMBER.dark
	var deep := ProceduralArt._pc(p, "canopy_deep")
	var mid := ProceduralArt._pc(p, "canopy_mid")
	var light := ProceduralArt._pc(p, "canopy_light")
	var rim := ProceduralArt._pc(p, "rim")
	var bases := [34.0, 64.0, 94.0]
	var tops := [74.0, 60.0, 82.0]
	var halfw := [5.0, 6.0, 5.0]
	for i in 3:
		var bx := float(bases[i])
		var top := float(tops[i])
		var hw := float(halfw[i])
		ProceduralArt._polygon(image, [Vector2(bx - hw, by), Vector2(bx - hw * 0.6, top),
			Vector2(bx + hw * 0.6, top), Vector2(bx + hw, by)], trunk)
		ProceduralArt._line(image, Vector2(bx - hw * 0.3, by), Vector2(bx - hw * 0.2, top), 1.2, trunk_light)
		for j in 5:
			var yy := top + 10.0 + j * ((by - top - 16.0) / 5.0)
			ProceduralArt._line(image, Vector2(bx - hw * 0.7, yy), Vector2(bx + hw * 0.1, yy - 1.5), 1.0, bark)
	ProceduralArt._ellipse(image, Vector2(40, 52), Vector2(30, 22), deep, 0.05)
	ProceduralArt._ellipse(image, Vector2(88, 50), Vector2(30, 22), deep, 0.05)
	ProceduralArt._ellipse(image, Vector2(64, 40), Vector2(40, 26), mid, 0.05)
	ProceduralArt._ellipse(image, Vector2(48, 34), Vector2(22, 15), light)
	ProceduralArt._ellipse(image, Vector2(84, 32), Vector2(20, 14), light)
	ProceduralArt._ellipse(image, Vector2(64, 24), Vector2(18, 12), rim.lerp(light, 0.5))
	ProceduralArt._ellipse(image, Vector2(30, 40), Vector2(5, 4), rim)
	ProceduralArt._ellipse(image, Vector2(98, 40), Vector2(5, 4), rim)
	return image


## A cool silver-violet moon lantern: a metal bracket + faceted glowing glass.
