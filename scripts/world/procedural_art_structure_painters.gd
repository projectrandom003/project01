class_name ProceduralArtStructurePainters
extends RefCounted
## Buildings, paths, bridges, furniture and landmark raster painters.

static func paint_kind(kind: String) -> Image:
	match kind:
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
		"bench": return _p_bench()
		"crate": return _p_crate()
		"watchtower": return _p_watchtower()
		"market_stall": return _p_market_stall()
		"stone_wall": return _p_stone_wall()
		"gazebo": return _p_gazebo()
		"banner_post": return _p_banner_post()
		"moon_shrine": return _p_moon_shrine()
		"stone_path": return _p_stone_path()
		"village_gate": return _p_village_gate()
		_: return null


static func _p_cottage() -> Image:
	var p := GreenwardStyle.prop_palette("cottage")
	var image := ProceduralArt._new_image(184, 162)
	var by := 152.0
	ProceduralArt._shadow(image, 92, by, 78)
	ProceduralArt._polygon(image, [Vector2(30, by), Vector2(34, by - 24), Vector2(150, by - 24), Vector2(154, by)], ProceduralArt._pc(p, "stone"))
	ProceduralArt._polygon(image, [Vector2(38, by - 22), Vector2(42, 66), Vector2(142, 66), Vector2(146, by - 22)], ProceduralArt._pc(p, "wood"))
	for i in 7:
		var x := 46.0 + i * 14.0
		ProceduralArt._line(image, Vector2(x, by - 26), Vector2(x, 70), 1.0, ProceduralArt._pc(p, "wood_dark"))
	ProceduralArt._polygon(image, [Vector2(80, by - 22), Vector2(82, 92), Vector2(104, 92), Vector2(106, by - 22)], ProceduralArt._pc(p, "wood_dark"))
	ProceduralArt._ellipse(image, Vector2(100, 120), Vector2(1.8, 1.8), ProceduralArt._pc(p, "warm"))
	ProceduralArt._polygon(image, [Vector2(116, 88), Vector2(118, 66), Vector2(136, 66), Vector2(138, 88)], ProceduralArt._pc(p, "warm"))
	ProceduralArt._ellipse(image, Vector2(127, 76), Vector2(20, 18), Color(1, 0.8, 0.4, 0.12))
	ProceduralArt._polygon(image, [Vector2(24, 70), Vector2(56, 22), Vector2(128, 22), Vector2(160, 70)], ProceduralArt._pc(p, "roof"))
	ProceduralArt._polygon(image, [Vector2(32, 64), Vector2(60, 28), Vector2(124, 28), Vector2(152, 64)], ProceduralArt._pc(p, "wood_mid"))
	for i in 5:
		ProceduralArt._line(image, Vector2(36 + i * 3, 62 - i * 6), Vector2(148 - i * 3, 62 - i * 6), 1.2, ProceduralArt._pc(p, "wood_dark"))
	ProceduralArt._polygon(image, [Vector2(118, 22), Vector2(118, 6), Vector2(132, 6), Vector2(132, 24)], ProceduralArt._pc(p, "wood_dark"))

	# Carved roof edge, exposed rafters and uneven thatch strands.
	for row in range(5):
		var roof_y := 34.0 + float(row) * 6.0
		var inset := float(row) * 4.5
		ProceduralArt._line(image, Vector2(34.0 + inset, roof_y), Vector2(150.0 - inset, roof_y + 1.0), 1.1, Color("#b08a59", 0.42))
		for seam in range(6):
			var sx := 43.0 + float(seam) * 18.0 + float((row + seam) % 2) * 4.0
			if sx < 148.0 - inset:
				ProceduralArt._line(image, Vector2(sx, roof_y - 2.0), Vector2(sx - 2.0, roof_y + 3.0), 0.8, ProceduralArt._pc(p, "wood_dark"))
	# Recessed windows with timber lintels and a warm interior, not bright decals.
	for wx in [55.0, 126.0]:
		ProceduralArt._polygon(image, PackedVector2Array([
			Vector2(wx - 8.0, 84.0), Vector2(wx - 8.0, 69.0),
			Vector2(wx + 8.0, 69.0), Vector2(wx + 8.0, 84.0)
		]), ProceduralArt._pc(p, "wood_dark"))
		ProceduralArt._polygon(image, PackedVector2Array([
			Vector2(wx - 5.0, 81.0), Vector2(wx - 5.0, 72.0),
			Vector2(wx + 5.0, 72.0), Vector2(wx + 5.0, 81.0)
		]), Color("#d9aa62", 0.82))
		ProceduralArt._line(image, Vector2(wx, 72.0), Vector2(wx, 82.0), 1.0, ProceduralArt._pc(p, "wood_dark"))
		ProceduralArt._line(image, Vector2(wx - 7.0, 68.0), Vector2(wx + 7.0, 68.0), 2.0, ProceduralArt._pc(p, "wood_dark"))
	# Door frame, step and diagonal plank grain make the entrance readable.
	ProceduralArt._polygon(image, PackedVector2Array([
		Vector2(78.0, 130.0), Vector2(78.0, 94.0), Vector2(108.0, 94.0),
		Vector2(108.0, 130.0)
	]), ProceduralArt._pc(p, "wood_dark"))
	ProceduralArt._polygon(image, PackedVector2Array([
		Vector2(82.0, 128.0), Vector2(82.0, 97.0), Vector2(104.0, 97.0),
		Vector2(104.0, 128.0)
	]), ProceduralArt._pc(p, "wood_mid"))
	ProceduralArt._line(image, Vector2(93.0, 99.0), Vector2(93.0, 126.0), 0.9, ProceduralArt._pc(p, "wood_dark"))
	ProceduralArt._ellipse(image, Vector2(100.0, 115.0), Vector2(1.8, 1.8), ProceduralArt._pc(p, "warm"))
	ProceduralArt._polygon(image, PackedVector2Array([
		Vector2(74.0, 132.0), Vector2(112.0, 132.0), Vector2(116.0, 138.0), Vector2(70.0, 138.0)
	]), ProceduralArt._pc(p, "stone"))
	# Moss grows in crevices rather than forming bright blobs on the walls.
	ProceduralArt._ellipse(image, Vector2(48, 74), Vector2(12, 4), ProceduralArt._pc(p, "moss"))
	ProceduralArt._ellipse(image, Vector2(142, 136), Vector2(11, 3), Color(ProceduralArt._pc(p, "moss").r, ProceduralArt._pc(p, "moss").g, ProceduralArt._pc(p, "moss").b, 0.55))
	ProceduralArt._line(image, Vector2(45.0, 91.0), Vector2(67.0, 89.0), 0.8, Color("#d4a36a", 0.28))
	ProceduralArt._line(image, Vector2(118.0, 104.0), Vector2(137.0, 102.0), 0.8, Color("#d4a36a", 0.24))
	return image

static func _p_wooden_bridge() -> Image:
	var p := GreenwardStyle.prop_palette("wooden_bridge")
	var image := ProceduralArt._new_image(132, 60)
	var wood := ProceduralArt._pc(p, "wood")
	var dark := ProceduralArt._pc(p, "wood_dark")
	for i in 7:
		var x := 10.0 + i * 17.0
		ProceduralArt._polygon(image, [Vector2(x, 40), Vector2(x + 2, 20), Vector2(x + 15, 18), Vector2(x + 14, 40)], wood)
		ProceduralArt._line(image, Vector2(x + 1, 40), Vector2(x + 15, 39), 1.0, dark)
	ProceduralArt._line(image, Vector2(8, 18), Vector2(124, 14), 2.5, dark)
	ProceduralArt._line(image, Vector2(8, 44), Vector2(124, 42), 2.5, dark)
	for i in 5:
		var x := 12.0 + i * 26.0
		ProceduralArt._line(image, Vector2(x, 44), Vector2(x, 16), 2.0, dark)
	return image

static func _p_stone_bridge() -> Image:
	var p := GreenwardStyle.prop_palette("stone_bridge")
	var image := ProceduralArt._new_image(132, 68)
	var stone := ProceduralArt._pc(p, "stone")
	var light := ProceduralArt._pc(p, "stone_light")
	ProceduralArt._polygon(image, [Vector2(10, 60), Vector2(24, 30), Vector2(108, 30), Vector2(122, 60), Vector2(100, 60), Vector2(66, 44), Vector2(32, 60)], stone)
	ProceduralArt._polygon(image, [Vector2(20, 30), Vector2(30, 16), Vector2(102, 16), Vector2(112, 30)], light)
	# Individual voussoir blocks and a dark recessed arch make the span read as stonework.
	for i in 6:
		var x := 26.0 + i * 15.0
		ProceduralArt._line(image, Vector2(x, 16), Vector2(x, 30), 1.0, ProceduralArt._pc(p, "moss"))
		ProceduralArt._line(image, Vector2(x - 5.0, 31.0), Vector2(x + 4.0, 31.0), 0.8, Color(0.10, 0.14, 0.13, 0.45))
	ProceduralArt._polygon(image, PackedVector2Array([
		Vector2(30, 31), Vector2(44, 45), Vector2(66, 50), Vector2(88, 45), Vector2(102, 31),
		Vector2(96, 31), Vector2(66, 42), Vector2(36, 31)
	]), Color(0.08, 0.12, 0.12, 0.72))
	ProceduralArt._line(image, Vector2(22, 30), Vector2(34, 42), 1.0, ProceduralArt._pc(p, "moss"))
	ProceduralArt._line(image, Vector2(110, 30), Vector2(98, 42), 1.0, ProceduralArt._pc(p, "moss"))
	ProceduralArt._ellipse(image, Vector2(66, 60), Vector2(40, 5), ProceduralArt._pc(p, "wood_dark"))
	return image

static func _p_dock() -> Image:
	var p := GreenwardStyle.prop_palette("dock")
	var image := ProceduralArt._new_image(124, 64)
	var wood := ProceduralArt._pc(p, "wood")
	var dark := ProceduralArt._pc(p, "wood_dark")
	ProceduralArt._polygon(image, [Vector2(8, 30), Vector2(116, 26), Vector2(116, 42), Vector2(8, 44)], wood)
	for i in 8:
		var x := 12.0 + i * 14.0
		ProceduralArt._line(image, Vector2(x, 30), Vector2(x, 43), 1.0, dark)
	for i in 4:
		var x := 18.0 + i * 30.0
		ProceduralArt._polygon(image, [Vector2(x, 44), Vector2(x + 3, 60), Vector2(x + 7, 60), Vector2(x + 9, 44)], dark)
	ProceduralArt._ellipse(image, Vector2(62, 60), Vector2(56, 4), Color(0.1, 0.3, 0.35, 0.18))
	return image

static func _p_well() -> Image:
	var p := GreenwardStyle.prop_palette("well")
	var image := ProceduralArt._new_image(76, 86)
	var stone := ProceduralArt._pc(p, "stone")
	var light := ProceduralArt._pc(p, "stone_light")
	ProceduralArt._ellipse(image, Vector2(38, 74), Vector2(30, 8), Color(0.02, 0.05, 0.03, 0.22))
	ProceduralArt._polygon(image, [Vector2(14, 74), Vector2(16, 46), Vector2(60, 46), Vector2(62, 74)], stone)
	ProceduralArt._ellipse(image, Vector2(38, 46), Vector2(24, 8), light)
	ProceduralArt._ellipse(image, Vector2(38, 46), Vector2(18, 5), ProceduralArt._pc(p, "wood_dark"))
	ProceduralArt._polygon(image, [Vector2(14, 46), Vector2(38, 20), Vector2(62, 46)], ProceduralArt._pc(p, "roof"))
	ProceduralArt._line(image, Vector2(38, 20), Vector2(38, 46), 1.6, ProceduralArt._pc(p, "wood_dark"))
	ProceduralArt._line(image, Vector2(20, 30), Vector2(56, 30), 2.0, ProceduralArt._pc(p, "wood"))
	return image

static func _p_shrine() -> Image:
	var p := GreenwardStyle.prop_palette("shrine")
	var image := ProceduralArt._new_image(96, 124)
	var stone := ProceduralArt._pc(p, "stone")
	var light := ProceduralArt._pc(p, "stone_light")
	ProceduralArt._shadow(image, 48, 116, 38)
	ProceduralArt._polygon(image, [Vector2(20, 116), Vector2(22, 40), Vector2(30, 40), Vector2(32, 116)], stone)
	ProceduralArt._polygon(image, [Vector2(64, 116), Vector2(66, 40), Vector2(74, 40), Vector2(76, 116)], stone)
	ProceduralArt._polygon(image, [Vector2(10, 40), Vector2(48, 26), Vector2(86, 40), Vector2(80, 44), Vector2(48, 32), Vector2(16, 44)], light)
	ProceduralArt._polygon(image, [Vector2(8, 30), Vector2(88, 30), Vector2(88, 38), Vector2(8, 38)], stone)
	ProceduralArt._ellipse(image, Vector2(48, 62), Vector2(12, 12), Color(0.5, 1.0, 0.9, 0.18))
	ProceduralArt._polygon(image, [Vector2(48, 50), Vector2(56, 62), Vector2(48, 76), Vector2(40, 62)], ProceduralArt._pc(p, "warm"))
	ProceduralArt._ellipse(image, Vector2(48, 62), Vector2(20, 20), Color(0.5, 1.0, 0.9, 0.10))
	return image

static func _p_ruin_arch() -> Image:
	var p := GreenwardStyle.prop_palette("ruin_arch")
	var image := ProceduralArt._new_image(104, 124)
	var stone := ProceduralArt._pc(p, "stone")
	var light := ProceduralArt._pc(p, "stone_light")
	ProceduralArt._shadow(image, 52, 116, 42)
	ProceduralArt._polygon(image, [Vector2(14, 116), Vector2(16, 40), Vector2(34, 40), Vector2(36, 116)], stone)
	ProceduralArt._polygon(image, [Vector2(68, 116), Vector2(70, 40), Vector2(88, 40), Vector2(90, 116)], stone)
	ProceduralArt._polygon(image, [Vector2(18, 116), Vector2(20, 44), Vector2(28, 44), Vector2(30, 116)], light)
	ProceduralArt._polygon(image, [Vector2(8, 40), Vector2(18, 22), Vector2(52, 12), Vector2(86, 22), Vector2(96, 40), Vector2(80, 40), Vector2(52, 26), Vector2(24, 40)], stone)
	ProceduralArt._polygon(image, [Vector2(60, 12), Vector2(70, 16), Vector2(66, 28), Vector2(58, 24)], light)
	# Mortar joints, fractures and moss drips make the arch feel old and partly reclaimed.
	for y in [58.0, 78.0, 98.0]:
		ProceduralArt._line(image, Vector2(16, y), Vector2(34, y - 1.0), 1.0, Color(0.10, 0.13, 0.13, 0.58))
		ProceduralArt._line(image, Vector2(70, y - 1.0), Vector2(88, y), 1.0, Color(0.10, 0.13, 0.13, 0.58))
	ProceduralArt._line(image, Vector2(28, 54), Vector2(24, 66), 1.2, Color("#b3b19a", 0.45))
	ProceduralArt._line(image, Vector2(24, 66), Vector2(29, 75), 0.9, Color("#b3b19a", 0.40))
	ProceduralArt._line(image, Vector2(77, 42), Vector2(72, 52), 1.0, Color("#b3b19a", 0.38))
	ProceduralArt._line(image, Vector2(72, 52), Vector2(77, 60), 0.8, Color("#b3b19a", 0.32))
	ProceduralArt._ellipse(image, Vector2(30, 70), Vector2(4, 3), ProceduralArt._pc(p, "moss"))
	ProceduralArt._ellipse(image, Vector2(82, 104), Vector2(7, 3), ProceduralArt._pc(p, "moss"))
	ProceduralArt._line(image, Vector2(18, 112), Vector2(25, 116), 1.4, ProceduralArt._pc(p, "moss"))
	return image

static func _p_signpost() -> Image:
	var p := GreenwardStyle.prop_palette("signpost")
	var image := ProceduralArt._new_image(44, 88)
	var dark := ProceduralArt._pc(p, "wood_dark")
	var wood := ProceduralArt._pc(p, "wood")
	ProceduralArt._shadow(image, 22, 82, 14, 0.20)
	ProceduralArt._polygon(image, [Vector2(19, 82), Vector2(20, 20), Vector2(24, 20), Vector2(25, 82)], dark)
	ProceduralArt._polygon(image, [Vector2(6, 28), Vector2(36, 26), Vector2(36, 38), Vector2(6, 40)], wood)
	ProceduralArt._polygon(image, [Vector2(10, 44), Vector2(38, 42), Vector2(38, 52), Vector2(10, 54)], wood)
	ProceduralArt._line(image, Vector2(6, 28), Vector2(6, 40), 1.0, dark)
	return image

static func _p_barrel() -> Image:
	var p := GreenwardStyle.prop_palette("barrel")
	var image := ProceduralArt._new_image(44, 56)
	var wood := ProceduralArt._pc(p, "wood")
	var dark := ProceduralArt._pc(p, "wood_dark")
	ProceduralArt._shadow(image, 22, 52, 16)
	ProceduralArt._ellipse(image, Vector2(22, 50), Vector2(16, 5), dark)
	ProceduralArt._polygon(image, [Vector2(8, 14), Vector2(36, 14), Vector2(38, 48), Vector2(6, 48)], wood)
	for i in 4:
		var x := 12.0 + i * 6.0
		ProceduralArt._line(image, Vector2(x, 14), Vector2(x, 48), 1.0, dark)
	ProceduralArt._ellipse(image, Vector2(22, 14), Vector2(14, 5), ProceduralArt._pc(p, "wood_mid"))
	ProceduralArt._line(image, Vector2(6, 24), Vector2(38, 24), 2.0, dark)
	ProceduralArt._line(image, Vector2(6, 40), Vector2(38, 40), 2.0, dark)
	return image

static func _p_cart() -> Image:
	var p := GreenwardStyle.prop_palette("cart")
	var image := ProceduralArt._new_image(112, 72)
	var wood := ProceduralArt._pc(p, "wood")
	var dark := ProceduralArt._pc(p, "wood_dark")
	ProceduralArt._shadow(image, 56, 66, 46)
	ProceduralArt._polygon(image, [Vector2(16, 44), Vector2(96, 44), Vector2(92, 60), Vector2(20, 60)], wood)
	for i in 6:
		var x := 22.0 + i * 13.0
		ProceduralArt._line(image, Vector2(x, 44), Vector2(x, 60), 1.0, dark)
	ProceduralArt._line(image, Vector2(16, 44), Vector2(8, 30), 2.5, dark)
	ProceduralArt._line(image, Vector2(96, 44), Vector2(104, 30), 2.5, dark)
	for wx in [34.0, 82.0]:
		ProceduralArt._ellipse(image, Vector2(wx, 58), Vector2(12, 12), dark)
		ProceduralArt._ellipse(image, Vector2(wx, 58), Vector2(8, 8), wood)
		ProceduralArt._ellipse(image, Vector2(wx, 58), Vector2(2.5, 2.5), dark)
	return image

static func _p_bench() -> Image:
	# Lived-in village seating: low isometric bench with a slatted backrest.
	var p := GreenwardStyle.prop_palette("bench")
	var image := ProceduralArt._new_image(80, 56)
	var wood := ProceduralArt._pc(p, "wood")
	var mid := ProceduralArt._pc(p, "wood_mid")
	var dark := ProceduralArt._pc(p, "wood_dark")
	ProceduralArt._shadow(image, 40, 52, 30, 0.22)
	# legs
	ProceduralArt._polygon(image, [Vector2(18, 34), Vector2(23, 34), Vector2(21, 50), Vector2(16, 50)], dark)
	ProceduralArt._polygon(image, [Vector2(58, 30), Vector2(63, 30), Vector2(65, 48), Vector2(60, 48)], dark)
	# seat planks (isometric skew)
	ProceduralArt._polygon(image, [Vector2(12, 30), Vector2(60, 26), Vector2(70, 32), Vector2(22, 37)], wood)
	ProceduralArt._line(image, Vector2(13, 34), Vector2(23, 41), 1.4, dark)
	ProceduralArt._line(image, Vector2(25, 32), Vector2(35, 39), 1.0, dark)
	# backrest posts + slats
	ProceduralArt._polygon(image, [Vector2(14, 30), Vector2(17, 8), Vector2(20, 8), Vector2(18, 30)], dark)
	ProceduralArt._polygon(image, [Vector2(60, 26), Vector2(63, 5), Vector2(66, 5), Vector2(64, 26)], dark)
	ProceduralArt._polygon(image, [Vector2(16, 12), Vector2(64, 8), Vector2(64, 15), Vector2(17, 19)], mid)
	ProceduralArt._line(image, Vector2(16, 15), Vector2(64, 11), 1.0, dark)
	ProceduralArt._ellipse(image, Vector2(26, 36), Vector2(4, 2), ProceduralArt._pc(p, "moss"))
	return image

static func _p_crate() -> Image:
	# Stackable market/goods crate with braced faces and a lit top rim.
	var p := GreenwardStyle.prop_palette("crate")
	var image := ProceduralArt._new_image(56, 58)
	var wood := ProceduralArt._pc(p, "wood")
	var mid := ProceduralArt._pc(p, "wood_mid")
	var dark := ProceduralArt._pc(p, "wood_dark")
	ProceduralArt._shadow(image, 28, 54, 22, 0.24)
	ProceduralArt._polygon(image, [Vector2(9, 20), Vector2(43, 18), Vector2(43, 50), Vector2(9, 52)], wood)
	ProceduralArt._polygon(image, [Vector2(43, 18), Vector2(50, 23), Vector2(50, 53), Vector2(43, 50)], dark)
	ProceduralArt._polygon(image, [Vector2(9, 20), Vector2(16, 13), Vector2(50, 15), Vector2(43, 18)], mid)
	ProceduralArt._line(image, Vector2(10, 22), Vector2(42, 48), 2.0, dark)
	ProceduralArt._line(image, Vector2(42, 20), Vector2(10, 50), 2.0, dark)
	ProceduralArt._line(image, Vector2(9, 35), Vector2(43, 33), 1.6, dark)
	ProceduralArt._ellipse(image, Vector2(20, 16), Vector2(3, 2), ProceduralArt._pc(p, "moss"))
	return image


# ------------------------------------------------------------- new: magical

static func _p_watchtower() -> Image:
	var p := GreenwardStyle.prop_palette("watchtower")
	var image := ProceduralArt._new_image(96, 184)
	var wood := ProceduralArt._pc(p, "wood")
	var dark := ProceduralArt._pc(p, "wood_dark")
	var stone := ProceduralArt._pc(p, "stone")
	var light := ProceduralArt._pc(p, "stone_light")
	var roof := ProceduralArt._pc(p, "roof")
	var warm := ProceduralArt._pc(p, "warm")
	var by := 176.0
	ProceduralArt._shadow(image, 48, by, 40)
	ProceduralArt._polygon(image, [Vector2(30, by), Vector2(32, by - 18), Vector2(64, by - 18), Vector2(66, by)], stone)
	for i in 3:
		ProceduralArt._line(image, Vector2(31, by - 6 - i * 6), Vector2(65, by - 6 - i * 6), 1.0, light)
	ProceduralArt._line(image, Vector2(36, by - 18), Vector2(30, 60), 3.0, dark)
	ProceduralArt._line(image, Vector2(60, by - 18), Vector2(66, 60), 3.0, dark)
	ProceduralArt._line(image, Vector2(38, by - 18), Vector2(40, 60), 2.0, wood)
	ProceduralArt._line(image, Vector2(58, by - 18), Vector2(56, 60), 2.0, wood)
	ProceduralArt._line(image, Vector2(32, 140), Vector2(64, 100), 1.6, dark)
	ProceduralArt._line(image, Vector2(64, 140), Vector2(32, 100), 1.6, dark)
	ProceduralArt._polygon(image, [Vector2(24, 60), Vector2(72, 60), Vector2(76, 52), Vector2(20, 52)], wood)
	for i in 5:
		var x := 22.0 + i * 13.0
		ProceduralArt._polygon(image, [Vector2(x, 52), Vector2(x, 40), Vector2(x + 6, 40), Vector2(x + 6, 52)], wood)
	ProceduralArt._polygon(image, [Vector2(16, 40), Vector2(48, 12), Vector2(80, 40)], roof)
	ProceduralArt._polygon(image, [Vector2(21, 38), Vector2(48, 17), Vector2(75, 38)], dark)
	ProceduralArt._ellipse(image, Vector2(48, 26), Vector2(5, 5), warm)
	ProceduralArt._ellipse(image, Vector2(48, 26), Vector2(14, 14), Color(warm.r, warm.g, warm.b, 0.18))
	return image

static func _p_market_stall() -> Image:
	var p := GreenwardStyle.prop_palette("market_stall")
	var image := ProceduralArt._new_image(140, 112)
	var wood := ProceduralArt._pc(p, "wood")
	var dark := ProceduralArt._pc(p, "wood_dark")
	var roof := ProceduralArt._pc(p, "roof")
	var cloth := ProceduralArt._pc(p, "accent")
	var warm := ProceduralArt._pc(p, "warm")
	var by := 102.0
	ProceduralArt._shadow(image, 70, by, 58)
	# two posts
	ProceduralArt._polygon(image, [Vector2(20, by), Vector2(20, 44), Vector2(26, 44), Vector2(26, by)], dark)
	ProceduralArt._polygon(image, [Vector2(114, by), Vector2(114, 44), Vector2(120, 44), Vector2(120, by)], dark)
	# striped awning
	ProceduralArt._polygon(image, [Vector2(10, 44), Vector2(20, 20), Vector2(120, 20), Vector2(130, 44)], roof)
	for i in 7:
		var x := 14.0 + i * 17.0
		ProceduralArt._polygon(image, [Vector2(x, 44), Vector2(x + 6, 22), Vector2(x + 12, 22), Vector2(x + 8, 44)], cloth)
	ProceduralArt._line(image, Vector2(10, 44), Vector2(130, 44), 2.0, dark)
	# counter + goods
	ProceduralArt._polygon(image, [Vector2(24, by - 10), Vector2(116, by - 10), Vector2(112, by), Vector2(28, by)], wood)
	for i in 4:
		var gx := 36.0 + i * 22.0
		ProceduralArt._ellipse(image, Vector2(gx, by - 14), Vector2(7, 5), warm)
		ProceduralArt._ellipse(image, Vector2(gx + 3, by - 17), Vector2(4, 3), cloth)
	ProceduralArt._ellipse(image, Vector2(70, 32), Vector2(30, 12), Color(warm.r, warm.g, warm.b, 0.10))
	return image

static func _p_stone_wall() -> Image:
	var p := GreenwardStyle.prop_palette("stone_wall")
	var image := ProceduralArt._new_image(160, 78)
	var stone := ProceduralArt._pc(p, "stone")
	var light := ProceduralArt._pc(p, "stone_light")
	var dark := ProceduralArt._pc(p, "wood_dark")
	var moss := ProceduralArt._pc(p, "moss")
	var by := 70.0
	ProceduralArt._shadow(image, 80, by, 74, 0.20)
	ProceduralArt._polygon(image, [Vector2(8, by), Vector2(8, 30), Vector2(152, 30), Vector2(152, by)], stone)
	# block courses
	for row in 3:
		var yy := 34.0 + row * 12.0
		ProceduralArt._line(image, Vector2(8, yy), Vector2(152, yy), 1.2, dark)
		for col in 6:
			var xx := 12.0 + col * 24.0 + (12.0 if row % 2 == 1 else 0.0)
			ProceduralArt._line(image, Vector2(xx, yy - 11), Vector2(xx, yy), 1.0, dark)
	# crenellations
	for i in 6:
		var x := 8.0 + i * 24.0
		ProceduralArt._polygon(image, [Vector2(x, 30), Vector2(x, 18), Vector2(x + 14, 18), Vector2(x + 14, 30)], light)
	ProceduralArt._ellipse(image, Vector2(34, 30), Vector2(12, 4), moss)
	ProceduralArt._ellipse(image, Vector2(120, 30), Vector2(9, 3), moss)
	return image

static func _p_gazebo() -> Image:
	var p := GreenwardStyle.prop_palette("gazebo")
	var image := ProceduralArt._new_image(128, 140)
	var wood := ProceduralArt._pc(p, "wood")
	var dark := ProceduralArt._pc(p, "wood_dark")
	var roof := ProceduralArt._pc(p, "roof")
	var warm := ProceduralArt._pc(p, "warm")
	var moss := ProceduralArt._pc(p, "moss")
	var by := 128.0
	ProceduralArt._shadow(image, 64, by, 54)
	# raised circular base
	ProceduralArt._ellipse(image, Vector2(64, by), Vector2(52, 9), wood)
	ProceduralArt._ellipse(image, Vector2(64, by - 3), Vector2(46, 7), dark)
	# four pillars
	for i in 4:
		var x := 24.0 + i * 26.0
		ProceduralArt._polygon(image, [Vector2(x, by - 4), Vector2(x - 1, 56), Vector2(x + 5, 56), Vector2(x + 4, by - 4)], wood)
	# open rail
	ProceduralArt._line(image, Vector2(20, 96), Vector2(108, 96), 1.6, dark)
	ProceduralArt._line(image, Vector2(20, 84), Vector2(108, 84), 1.2, dark)
	# domed roof
	ProceduralArt._polygon(image, [Vector2(12, 56), Vector2(40, 24), Vector2(64, 12), Vector2(88, 24), Vector2(116, 56), Vector2(100, 56), Vector2(64, 22), Vector2(28, 56)], roof)
	ProceduralArt._polygon(image, [Vector2(28, 56), Vector2(64, 22), Vector2(100, 56)], dark)
	ProceduralArt._line(image, Vector2(64, 12), Vector2(64, 4), 2.0, warm)
	ProceduralArt._ellipse(image, Vector2(64, 4), Vector2(3.5, 3.5), warm)
	ProceduralArt._ellipse(image, Vector2(64, 60), Vector2(22, 18), Color(warm.r, warm.g, warm.b, 0.10))
	ProceduralArt._ellipse(image, Vector2(26, by - 2), Vector2(8, 3), moss)
	return image

static func _p_banner_post() -> Image:
	var p := GreenwardStyle.prop_palette("banner_post")
	var image := ProceduralArt._new_image(60, 176)
	var dark := ProceduralArt._pc(p, "wood_dark")
	var wood := ProceduralArt._pc(p, "wood")
	var banner := ProceduralArt._pc(p, "accent")
	var gold := ProceduralArt._pc(p, "warm")
	var by := 168.0
	ProceduralArt._shadow(image, 30, by, 12, 0.20)
	ProceduralArt._polygon(image, [Vector2(27, by), Vector2(27, 14), Vector2(33, 14), Vector2(33, by)], dark)
	ProceduralArt._polygon(image, [Vector2(28, by), Vector2(28, 20), Vector2(30, 20), Vector2(30, by)], wood)
	ProceduralArt._line(image, Vector2(14, 22), Vector2(46, 22), 2.0, gold)
	# hanging swallow-tail banner
	ProceduralArt._polygon(image, [Vector2(31, 24), Vector2(52, 24), Vector2(52, 96), Vector2(42, 86), Vector2(31, 96)], banner)
	ProceduralArt._line(image, Vector2(31, 24), Vector2(31, 96), 1.2, gold)
	ProceduralArt._ellipse(image, Vector2(41, 52), Vector2(6, 8), gold)
	ProceduralArt._ellipse(image, Vector2(30, 12), Vector2(5, 5), gold)
	return image

static func _p_moon_shrine() -> Image:
	var p := GreenwardStyle.prop_palette("moon_shrine")
	var image := ProceduralArt._new_image(112, 150)
	var stone := ProceduralArt._pc(p, "stone")
	var light := ProceduralArt._pc(p, "stone_light")
	var core := ProceduralArt._pc(p, "core")
	var glow := ProceduralArt._pc(p, "glow")
	var warm := ProceduralArt._pc(p, "warm")
	var by := 140.0
	ProceduralArt._shadow(image, 56, by, 46)
	# stepped altar
	ProceduralArt._polygon(image, [Vector2(14, by), Vector2(20, by - 14), Vector2(92, by - 14), Vector2(98, by)], stone)
	ProceduralArt._polygon(image, [Vector2(20, by - 14), Vector2(26, by - 24), Vector2(86, by - 24), Vector2(92, by - 14)], light)
	# twin pillars
	ProceduralArt._polygon(image, [Vector2(22, by - 24), Vector2(24, 60), Vector2(32, 60), Vector2(34, by - 24)], stone)
	ProceduralArt._polygon(image, [Vector2(78, by - 24), Vector2(80, 60), Vector2(88, 60), Vector2(90, by - 24)], stone)
	# lintel + crescent moon
	ProceduralArt._polygon(image, [Vector2(18, 60), Vector2(94, 60), Vector2(94, 52), Vector2(18, 52)], light)
	ProceduralArt._ellipse(image, Vector2(56, 30), Vector2(18, 18), warm)
	ProceduralArt._ellipse(image, Vector2(63, 26), Vector2(15, 15), stone)
	ProceduralArt._ellipse(image, Vector2(56, 30), Vector2(22, 22), Color(glow.r, glow.g, glow.b, 0.16))
	# glowing orb on the altar
	ProceduralArt._ellipse(image, Vector2(56, by - 34), Vector2(9, 9), core)
	ProceduralArt._ellipse(image, Vector2(56, by - 34), Vector2(20, 20), Color(core.r, core.g, core.b, 0.20))
	ProceduralArt._ellipse(image, Vector2(56, by - 34), Vector2(3.5, 3.5), Color(1, 1, 1, 0.85))
	return image


# ------------------------------------ PART 5: Moonpetal Hollow + village approach
# Four genuinely distinct, detailed silhouettes for the World Presentation
# round. All colours come from GreenwardStyle (via prop_palette()/ProceduralArt._pc() or a
# direct palette group) — NO new inline hex. Everything remains PROCEDURAL
# PLACEHOLDER art; these are compositional/standards improvements, not assets.
# Each kind has >=2 variants; the shared _apply_variant engine (hue rotation +
# category geometry) guarantees variant 0/1 pixels differ.

## A cluster of three pale silver-birch trunks under a moonlit canopy.

static func _p_stone_path() -> Image:
	var p := GreenwardStyle.prop_palette("stone_path")
	var image := ProceduralArt._new_image(96, 52)
	var dark := ProceduralArt._pc(p, "dark")
	var mid := ProceduralArt._pc(p, "mid")
	var light := ProceduralArt._pc(p, "light")
	var moss := ProceduralArt._pc(p, "moss")
	var wet := ProceduralArt._pc(p, "wet")
	ProceduralArt._polygon(image, [Vector2(6, 30), Vector2(30, 14), Vector2(90, 14),
		Vector2(90, 40), Vector2(66, 50), Vector2(6, 44)], dark)
	ProceduralArt._polygon(image, [Vector2(10, 30), Vector2(32, 18), Vector2(86, 18),
		Vector2(86, 38), Vector2(64, 46), Vector2(10, 40)], mid)
	var rows := [22.0, 30.0, 38.0]
	for r in rows.size():
		var yy := float(rows[r])
		var offset := 0.0 if r % 2 == 0 else 8.0
		for c in 6:
			var cx := 14.0 + c * 13.0 + offset
			if cx > 84.0:
				continue
			ProceduralArt._ellipse(image, Vector2(cx, yy), Vector2(6.0, 3.6), light, 0.06)
			ProceduralArt._ellipse(image, Vector2(cx - 1.2, yy - 1.0), Vector2(2.4, 1.4), wet)
	ProceduralArt._ellipse(image, Vector2(20, 44), Vector2(8, 2.4), moss)
	ProceduralArt._ellipse(image, Vector2(70, 46), Vector2(9, 2.6), moss)
	ProceduralArt._ellipse(image, Vector2(48, 16), Vector2(10, 2.2), moss)
	ProceduralArt._line(image, Vector2(6, 30), Vector2(6, 44), 1.4, dark)
	ProceduralArt._line(image, Vector2(90, 14), Vector2(90, 40), 1.4, dark)
	return image


## A timber + stone village gate: two piers, a pitched lintel, a banner and
## two warm lanterns. Reads as a recognisable entrance landmark.

static func _p_village_gate() -> Image:
	var p := GreenwardStyle.prop_palette("village_gate")
	var image := ProceduralArt._new_image(160, 184)
	var by := 176.0
	ProceduralArt._shadow(image, 80, by, 76)
	var stone := ProceduralArt._pc(p, "stone")
	var stone_light := ProceduralArt._pc(p, "stone_light")
	var wood := ProceduralArt._pc(p, "wood")
	var wood_mid := ProceduralArt._pc(p, "wood_mid")
	var dark := ProceduralArt._pc(p, "wood_dark")
	var roof := ProceduralArt._pc(p, "roof")
	var warm := ProceduralArt._pc(p, "warm")
	var banner := ProceduralArt._pc(p, "banner")
	for raw_px in [26.0, 134.0]:
		var px := float(raw_px)
		ProceduralArt._polygon(image, [Vector2(px - 12, by), Vector2(px - 12, 70),
			Vector2(px + 12, 70), Vector2(px + 12, by)], stone)
		ProceduralArt._polygon(image, [Vector2(px - 9, by - 2), Vector2(px - 9, 74),
			Vector2(px - 2, 74), Vector2(px - 2, by - 2)], stone_light)
		for i in 4:
			var yy := 90.0 + i * 20.0
			ProceduralArt._line(image, Vector2(px - 12, yy), Vector2(px + 12, yy), 1.0, dark)
		ProceduralArt._polygon(image, [Vector2(px - 15, 70), Vector2(px - 12, 62),
			Vector2(px + 12, 62), Vector2(px + 15, 70)], stone_light)
	ProceduralArt._polygon(image, [Vector2(20, 62), Vector2(140, 62), Vector2(140, 76), Vector2(20, 76)], wood)
	ProceduralArt._line(image, Vector2(20, 64), Vector2(140, 64), 1.4, wood_mid)
	for i in 8:
		var x := 26.0 + i * 15.0
		ProceduralArt._line(image, Vector2(x, 62), Vector2(x, 76), 1.0, dark)
	ProceduralArt._polygon(image, [Vector2(14, 62), Vector2(44, 30), Vector2(116, 30), Vector2(146, 62)], roof)
	ProceduralArt._polygon(image, [Vector2(22, 58), Vector2(48, 34), Vector2(112, 34), Vector2(138, 58)], dark)
	for i in 4:
		ProceduralArt._line(image, Vector2(26 + i * 4, 56 - i * 5), Vector2(134 - i * 4, 56 - i * 5), 1.1, wood_mid)
	ProceduralArt._polygon(image, [Vector2(72, 76), Vector2(88, 76), Vector2(88, 122),
		Vector2(80, 114), Vector2(72, 122)], banner)
	ProceduralArt._line(image, Vector2(80, 76), Vector2(80, 122), 1.2, dark)
	ProceduralArt._ellipse(image, Vector2(80, 96), Vector2(5, 7), warm)
	for raw_lx in [26.0, 134.0]:
		var lx := float(raw_lx)
		ProceduralArt._ellipse(image, Vector2(lx, 84), Vector2(10, 12), Color(warm.r, warm.g, warm.b, 0.16))
		ProceduralArt._ellipse(image, Vector2(lx, 84), Vector2(3.4, 5.0), warm)
		ProceduralArt._ellipse(image, Vector2(lx, 83), Vector2(1.6, 2.4), Color(1, 1, 0.85, 0.9))
	return image


# ------------------------------------------------------- character_frame draw
# Offset-aware wrappers so a whole-figure bob/recoil can be applied cleanly.
