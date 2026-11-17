class_name ProceduralArtPropPainters
extends RefCounted
## Stateless procedural prop painters; raster primitives and cache ownership live in ProceduralArt.

static func paint_kind(kind: String) -> Image:
	var image := ProceduralArtNaturePainters.paint_kind(kind)
	if image != null:
		return image
	image = ProceduralArtStructurePainters.paint_kind(kind)
	if image != null:
		return image
	image = ProceduralArtAmbientPainters.paint_kind(kind)
	if image != null:
		return image
	match kind:
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
		_: return _flower()


static func _tree(width: int, height: int, ancient: bool) -> Image:
	# Woodland trees use an irregular, branch-led silhouette instead of stacked
	# circular blobs. The silhouette is intentionally asymmetric so groves do
	# not read as repeated lollipops when viewed from the isometric camera.
	var image := ProceduralArt._new_image(width, height)
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

	ProceduralArt._ellipse(image, Vector2(cx, base_y), Vector2(width * 0.31, 6.0), shadow)

	# Exposed roots and a tapered, slightly leaning trunk.
	ProceduralArt._polygon(image, PackedVector2Array([
		Vector2(cx - width * 0.15, base_y), Vector2(cx - width * 0.075, base_y - 12.0),
		Vector2(cx - width * 0.045, trunk_top), Vector2(cx + width * 0.035, trunk_top - 2.0),
		Vector2(cx + width * 0.10, base_y - 10.0), Vector2(cx + width * 0.19, base_y),
		Vector2(cx + width * 0.055, base_y - 4.0), Vector2(cx - width * 0.04, base_y - 3.0)
	]), trunk_dark)
	ProceduralArt._polygon(image, PackedVector2Array([
		Vector2(cx - width * 0.015, base_y - 5.0), Vector2(cx + width * 0.005, trunk_top + 2.0),
		Vector2(cx + width * 0.04, trunk_top + 1.0), Vector2(cx + width * 0.065, base_y - 8.0)
	]), trunk_light)

	# Thick, visible limbs emerge from the trunk and disappear into the crown.
	var limb_width := 5.0 if ancient else 3.5
	ProceduralArt._line(image, Vector2(cx, trunk_top + 20.0), Vector2(cx - canopy_x * 0.72, canopy_y + canopy_h * 0.48), limb_width, trunk_dark)
	ProceduralArt._line(image, Vector2(cx + 2.0, trunk_top + 15.0), Vector2(cx + canopy_x * 0.70, canopy_y + canopy_h * 0.42), limb_width, trunk_dark)
	ProceduralArt._line(image, Vector2(cx, trunk_top + 4.0), Vector2(cx - canopy_x * 0.28, canopy_y - canopy_h * 0.35), limb_width * 0.72, trunk_dark)
	ProceduralArt._line(image, Vector2(cx + 1.0, trunk_top + 6.0), Vector2(cx + canopy_x * 0.34, canopy_y - canopy_h * 0.28), limb_width * 0.72, trunk_dark)

	# Scalloped but non-circular crown outline.
	var crown := PackedVector2Array()
	for i in range(20):
		var angle := TAU * float(i) / 20.0
		var irregular := 0.84 + 0.10 * sin(float(i) * 2.17) + 0.055 * cos(float(i) * 3.71)
		var x_radius := canopy_x * irregular
		var y_radius := canopy_h * (0.90 + 0.08 * sin(float(i) * 1.43))
		crown.append(Vector2(cx + cos(angle) * x_radius, canopy_y + sin(angle) * y_radius))
	ProceduralArt._polygon(image, crown, deep)

	# Offset crown masses create depth and a canopy that hangs over the trunk.
	ProceduralArt._polygon(image, PackedVector2Array([
		Vector2(cx - canopy_x * 0.94, canopy_y + canopy_h * 0.12),
		Vector2(cx - canopy_x * 0.79, canopy_y - canopy_h * 0.46),
		Vector2(cx - canopy_x * 0.34, canopy_y - canopy_h * 0.72),
		Vector2(cx + canopy_x * 0.12, canopy_y - canopy_h * 0.52),
		Vector2(cx + canopy_x * 0.28, canopy_y - canopy_h * 0.05),
		Vector2(cx - canopy_x * 0.10, canopy_y + canopy_h * 0.34),
		Vector2(cx - canopy_x * 0.60, canopy_y + canopy_h * 0.54)
	]), mid)
	ProceduralArt._polygon(image, PackedVector2Array([
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
		ProceduralArt._polygon(image, leaf, leaf_color)

	# A few hanging leaf tips break the lower edge of the crown.
	for i in range(7):
		var x := cx - canopy_x * 0.78 + float(i) * canopy_x * 0.25
		var y := canopy_y + canopy_h * (0.68 + 0.10 * sin(float(i) * 1.7))
		ProceduralArt._polygon(image, PackedVector2Array([
			Vector2(x - 3.0, y - 3.0), Vector2(x + 3.0, y - 2.0),
			Vector2(x + 1.0, y + 9.0 + float(i % 3) * 3.0), Vector2(x - 2.0, y + 5.0)
		]), mid)

	if ancient:
		# Old trees carry a restrained rune scar, not a glowing Christmas-light effect.
		for i in range(3):
			var y := trunk_top + 22.0 + float(i) * 16.0
			ProceduralArt._line(image, Vector2(cx + 1.0, y), Vector2(cx + 4.0, y - 5.0), 1.2, Color(0.36, 0.78, 0.62, 0.62))
		ProceduralArt._ellipse(image, Vector2(cx - canopy_x * 0.10, canopy_y + canopy_h * 0.10), Vector2(canopy_x * 0.10, canopy_h * 0.10), Color(0.35, 0.75, 0.58, 0.10))
	return image


static func _rock() -> Image:
	var image := ProceduralArt._new_image(64, 48)
	ProceduralArt._ellipse(image, Vector2(32, 42), Vector2(24, 5), Color(0.02, 0.05, 0.03, 0.25))
	ProceduralArt._polygon(image, [
		Vector2(8, 42), Vector2(14, 22), Vector2(28, 12), Vector2(48, 18), Vector2(58, 38), Vector2(50, 44),
	], Color("#4a4a44"))
	ProceduralArt._polygon(image, [
		Vector2(16, 38), Vector2(20, 24), Vector2(31, 16), Vector2(44, 22), Vector2(48, 34),
	], Color("#62645a"))
	ProceduralArt._polygon(image, [
		Vector2(22, 26), Vector2(31, 18), Vector2(38, 21), Vector2(30, 27),
	], Color("#8a8f7c"))
	# Broken facets and thin mineral seams stop the rock reading as a smooth blob.
	ProceduralArt._polygon(image, PackedVector2Array([
		Vector2(15, 34), Vector2(22, 27), Vector2(27, 31), Vector2(24, 39), Vector2(17, 40)
	]), Color("#3b403b"))
	ProceduralArt._line(image, Vector2(31, 18), Vector2(28, 29), 1.0, Color("#b1b49a", 0.55))
	ProceduralArt._line(image, Vector2(28, 29), Vector2(35, 35), 0.8, Color("#343a35", 0.8))
	ProceduralArt._line(image, Vector2(43, 23), Vector2(48, 31), 1.0, Color("#343a35", 0.65))
	ProceduralArt._ellipse(image, Vector2(24, 38), Vector2(3.0, 2.0), Color("#6f8f5a"))
	ProceduralArt._ellipse(image, Vector2(46, 36), Vector2(4.0, 2.5), Color("#5d7a4a"))
	ProceduralArt._line(image, Vector2(13, 38), Vector2(21, 34), 1.2, Color("#7f9560", 0.55))
	return image


static func _flower() -> Image:
	var image := ProceduralArt._new_image(24, 28)
	ProceduralArt._line(image, Vector2(12, 26), Vector2(12, 14), 1.2, Color("#4f7a46"))
	ProceduralArt._ellipse(image, Vector2(8, 24), Vector2(4.0, 2.0), Color("#5d8f52"))
	for angle in 5:
		var direction := Vector2.RIGHT.rotated(TAU * float(angle) / 5.0)
		ProceduralArt._ellipse(image, Vector2(12, 10) + direction * 3.4, Vector2(3.0, 3.0), Color("#ffe9a3"))
	ProceduralArt._ellipse(image, Vector2(12, 10), Vector2(2.0, 2.0), Color("#ffb3c7"))
	return image


static func _mushroom() -> Image:
	var image := ProceduralArt._new_image(28, 34)
	ProceduralArt._line(image, Vector2(14, 32), Vector2(14, 18), 3.0, Color("#e8dcc0"))
	ProceduralArt._ellipse(image, Vector2(14, 15), Vector2(11, 7), Color("#b05a5a"))
	ProceduralArt._ellipse(image, Vector2(10, 12), Vector2(2.0, 1.6), Color("#ffd9c0"))
	ProceduralArt._ellipse(image, Vector2(18, 16), Vector2(1.6, 1.2), Color("#ffd9c0"))
	ProceduralArt._ellipse(image, Vector2(15, 9), Vector2(1.4, 1.0), Color("#ffd9c0"))
	return image


static func _crystal() -> Image:
	var image := ProceduralArt._new_image(48, 72)
	ProceduralArt._ellipse(image, Vector2(24, 68), Vector2(15, 4), Color(0.3, 0.9, 0.9, 0.18))
	ProceduralArt._polygon(image, [
		Vector2(24, 4), Vector2(36, 34), Vector2(30, 66), Vector2(18, 66), Vector2(12, 34),
	], Color("#2a8f9f"))
	ProceduralArt._polygon(image, [
		Vector2(24, 4), Vector2(31, 34), Vector2(24, 64), Vector2(18, 34),
	], Color("#7fe3e0"))
	ProceduralArt._polygon(image, [
		Vector2(24, 10), Vector2(24, 56), Vector2(20, 34),
	], Color("#c9fffb"))
	ProceduralArt._ellipse(image, Vector2(24, 34), Vector2(20, 26), Color(0.4, 1.0, 0.95, 0.10))
	return image


static func _bush() -> Image:
	var image := ProceduralArt._new_image(64, 44)
	ProceduralArt._ellipse(image, Vector2(32, 40), Vector2(22, 4), Color(0.02, 0.05, 0.03, 0.22))
	ProceduralArt._ellipse(image, Vector2(22, 28), Vector2(16, 13), Color("#2f5234"))
	ProceduralArt._ellipse(image, Vector2(42, 28), Vector2(15, 12), Color("#2f5234"))
	ProceduralArt._ellipse(image, Vector2(32, 20), Vector2(17, 14), Color("#3f6b3f"))
	ProceduralArt._ellipse(image, Vector2(28, 16), Vector2(8, 6), Color("#5d8f52"))
	for index in 4:
		ProceduralArt._ellipse(image, Vector2(20 + index * 8, 26 + (index % 2) * 5), Vector2(1.6, 1.6), Color("#ffb3c7"))
	return image


static func _hut() -> Image:
	var width := 170
	var height := 150
	var image := ProceduralArt._new_image(width, height)
	var base_y := height - 8.0
	ProceduralArt._ellipse(image, Vector2(width * 0.5, base_y), Vector2(70, 8), Color(0.02, 0.05, 0.03, 0.28))
	ProceduralArt._polygon(image, [
		Vector2(28, base_y), Vector2(32, base_y - 22), Vector2(140, base_y - 22), Vector2(144, base_y),
	], Color("#5c5a50"))
	ProceduralArt._polygon(image, [
		Vector2(36, base_y - 20), Vector2(40, 62), Vector2(132, 62), Vector2(136, base_y - 20),
	], Color("#6b4c33"))
	for index in 6:
		var x := 44.0 + index * 14.0
		ProceduralArt._line(image, Vector2(x, base_y - 24), Vector2(x, 66), 1.0, Color("#4a3524"))
	ProceduralArt._polygon(image, [
		Vector2(74, base_y - 20), Vector2(76, 88), Vector2(96, 88), Vector2(98, base_y - 20),
	], Color("#3a2a1c"))
	ProceduralArt._ellipse(image, Vector2(92, 112), Vector2(1.8, 1.8), Color("#e8c27a"))
	ProceduralArt._polygon(image, [
		Vector2(108, 84), Vector2(110, 62), Vector2(126, 62), Vector2(128, 84),
	], Color("#ffcf6a"))
	ProceduralArt._ellipse(image, Vector2(118, 72), Vector2(20, 18), Color(1.0, 0.8, 0.4, 0.12))
	ProceduralArt._polygon(image, [
		Vector2(22, 66), Vector2(52, 22), Vector2(122, 22), Vector2(150, 66),
	], Color("#4a3524"))
	ProceduralArt._polygon(image, [
		Vector2(30, 60), Vector2(56, 28), Vector2(118, 28), Vector2(142, 60),
	], Color("#6b4c33"))
	for index in 5:
		ProceduralArt._line(image, Vector2(34 + index * 3, 58 - index * 6), Vector2(136 - index * 3, 58 - index * 6), 1.2, Color("#3a2a1c"))
	ProceduralArt._ellipse(image, Vector2(44, 70), Vector2(12, 4), Color("#4f7a46"))
	ProceduralArt._ellipse(image, Vector2(130, 66), Vector2(10, 3), Color("#4f7a46"))
	ProceduralArt._line(image, Vector2(132, 70), Vector2(134, 100), 1.4, Color("#3f6b3f"))
	ProceduralArt._ellipse(image, Vector2(124, 16), Vector2(8, 5), Color(0.8, 0.85, 0.9, 0.10))

	# Uneven thatch courses and small split ends stop the roof reading as a
	# perfectly clean polygon. Keep highlights muted so the village stays calm.
	for row in range(4):
		var y := 34.0 + float(row) * 7.0
		var inset := float(row) * 4.0
		ProceduralArt._line(image, Vector2(34.0 + inset, y), Vector2(138.0 - inset, y + 1.0), 1.0, Color("#8a6944", 0.48))
		for seam in range(5):
			var sx := 44.0 + float(seam) * 19.0 + float((row + seam) % 2) * 5.0
			if sx < 136.0 - inset:
				ProceduralArt._line(image, Vector2(sx, y - 2.0), Vector2(sx - 2.0, y + 4.0), 0.8, Color("#3a2a1c", 0.55))
	# Wall grain, weather stains and a few exposed foundation stones.
	for plank in range(5):
		var x := 48.0 + float(plank) * 18.0
		ProceduralArt._line(image, Vector2(x, 74), Vector2(x - 1.0, base_y - 26.0), 0.8, Color("#a47a4d", 0.30))
	for stone in range(7):
		var sx := 34.0 + float(stone) * 17.0
		ProceduralArt._line(image, Vector2(sx, base_y - 12.0), Vector2(sx + 7.0, base_y - 13.0), 1.2, Color("#8a8776", 0.55))
	ProceduralArt._ellipse(image, Vector2(39, 76), Vector2(5, 3), Color("#3f6b3f", 0.55))
	ProceduralArt._ellipse(image, Vector2(130, 68), Vector2(6, 2), Color("#3f6b3f", 0.48))

	# Small recessed shutters and a dark doorway establish a believable facade.
	for wx in [54.0, 126.0]:
		ProceduralArt._polygon(image, PackedVector2Array([
			Vector2(wx - 7.0, 99.0), Vector2(wx - 7.0, 85.0),
			Vector2(wx + 7.0, 85.0), Vector2(wx + 7.0, 99.0)
		]), Color("#35271e"))
		ProceduralArt._polygon(image, PackedVector2Array([
			Vector2(wx - 4.0, 96.0), Vector2(wx - 4.0, 88.0),
			Vector2(wx + 4.0, 88.0), Vector2(wx + 4.0, 96.0)
		]), Color("#c49a5e", 0.78))
		ProceduralArt._line(image, Vector2(wx, 88.0), Vector2(wx, 96.0), 1.0, Color("#493323"))
	ProceduralArt._polygon(image, PackedVector2Array([
		Vector2(74.0, 128.0), Vector2(74.0, 96.0), Vector2(100.0, 96.0),
		Vector2(100.0, 128.0)
	]), Color("#35271e"))
	ProceduralArt._polygon(image, PackedVector2Array([
		Vector2(78.0, 126.0), Vector2(78.0, 99.0), Vector2(96.0, 99.0),
		Vector2(96.0, 126.0)
	]), Color("#523a28"))
	ProceduralArt._ellipse(image, Vector2(92.0, 114.0), Vector2(1.6, 1.6), Color("#d9b16e"))
	# A few broken thatch strands and timber end-grain, kept low contrast.
	for row in range(4):
		var roof_y := 35.0 + float(row) * 7.0
		var inset := float(row) * 4.0
		ProceduralArt._line(image, Vector2(30.0 + inset, roof_y), Vector2(142.0 - inset, roof_y + 1.0), 1.0, Color("#a17b50", 0.38))
	for plank in range(4):
		var px := 48.0 + float(plank) * 22.0
		ProceduralArt._line(image, Vector2(px, 76.0), Vector2(px - 1.0, 119.0), 0.8, Color("#c0905b", 0.24))
	return image


static func _lantern() -> Image:
	var image := ProceduralArt._new_image(32, 80)
	ProceduralArt._ellipse(image, Vector2(16, 76), Vector2(10, 3), Color(0.02, 0.05, 0.03, 0.22))
	ProceduralArt._polygon(image, [Vector2(13, 76), Vector2(15, 26), Vector2(17, 26), Vector2(19, 76)], Color("#3a2a1c"))
	ProceduralArt._line(image, Vector2(16, 28), Vector2(26, 22), 2.0, Color("#3a2a1c"))
	ProceduralArt._ellipse(image, Vector2(26, 30), Vector2(6, 8), Color(1.0, 0.8, 0.45, 0.22))
	ProceduralArt._ellipse(image, Vector2(26, 30), Vector2(3.5, 5.0), Color("#ffcf6a"))
	ProceduralArt._ellipse(image, Vector2(26, 29), Vector2(1.8, 2.6), Color("#fff6d0"))
	return image


static func _waypoint() -> Image:
	var image := ProceduralArt._new_image(96, 120)
	var base_y := 114.0
	ProceduralArt._ellipse(image, Vector2(48, base_y), Vector2(40, 7), Color(0.02, 0.05, 0.03, 0.25))
	ProceduralArt._polygon(image, [Vector2(14, base_y), Vector2(18, 34), Vector2(30, 34), Vector2(32, base_y)], Color("#5c5a50"))
	ProceduralArt._polygon(image, [Vector2(64, base_y), Vector2(66, 34), Vector2(78, 34), Vector2(82, base_y)], Color("#5c5a50"))
	ProceduralArt._polygon(image, [Vector2(20, base_y), Vector2(22, 38), Vector2(26, 38), Vector2(28, base_y)], Color("#7a7868"))
	ProceduralArt._polygon(image, [Vector2(68, base_y), Vector2(70, 38), Vector2(74, 38), Vector2(76, base_y)], Color("#7a7868"))
	ProceduralArt._polygon(image, [
		Vector2(12, 38), Vector2(18, 22), Vector2(48, 12), Vector2(78, 22), Vector2(84, 38),
		Vector2(72, 38), Vector2(48, 26), Vector2(24, 38),
	], Color("#6b685a"))
	ProceduralArt._polygon(image, [
		Vector2(48, 34), Vector2(58, 54), Vector2(48, 78), Vector2(38, 54),
	], Color("#7fe3e0"))
	ProceduralArt._polygon(image, [Vector2(48, 38), Vector2(53, 54), Vector2(48, 72), Vector2(43, 54)], Color("#d9fffb"))
	ProceduralArt._ellipse(image, Vector2(48, 56), Vector2(26, 30), Color(0.4, 1.0, 0.95, 0.13))
	return image


static func _ruin_pillar() -> Image:
	var image := ProceduralArt._new_image(52, 100)
	ProceduralArt._ellipse(image, Vector2(26, 96), Vector2(20, 4), Color(0.02, 0.05, 0.03, 0.22))
	ProceduralArt._polygon(image, [Vector2(16, 96), Vector2(18, 18), Vector2(34, 18), Vector2(36, 96)], Color("#6b685a"))
	ProceduralArt._polygon(image, [Vector2(21, 94), Vector2(22, 22), Vector2(28, 22), Vector2(30, 94)], Color("#8a8776"))
	ProceduralArt._polygon(image, [Vector2(12, 20), Vector2(14, 8), Vector2(38, 8), Vector2(40, 20)], Color("#7a7868"))
	ProceduralArt._line(image, Vector2(24, 36), Vector2(24, 76), 1.2, Color(0.6, 1.0, 0.75, 0.35))
	ProceduralArt._ellipse(image, Vector2(26, 46), Vector2(3, 3), Color(0.6, 1.0, 0.75, 0.5))
	return image


static func _fence() -> Image:
	var image := ProceduralArt._new_image(64, 40)
	ProceduralArt._ellipse(image, Vector2(32, 36), Vector2(28, 3), Color(0.02, 0.05, 0.03, 0.18))
	for index in 3:
		var x := 8.0 + index * 22.0
		ProceduralArt._polygon(image, [Vector2(x, 36), Vector2(x + 2, 14), Vector2(x + 6, 14), Vector2(x + 8, 36)], Color("#5a4030"))
	ProceduralArt._line(image, Vector2(6, 22), Vector2(58, 22), 2.0, Color("#6b4c33"))
	ProceduralArt._line(image, Vector2(6, 30), Vector2(58, 30), 1.6, Color("#4a3524"))
	return image


# --------------------------------------------------------------- new: trees


