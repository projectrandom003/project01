class_name ProceduralMonsterPainter
extends RefCounted
## Species-specific procedural drawing. Canvas draw ownership stays with the renderer.

var renderer: ActorProceduralRendererComponent
var visual: ActorVisual

func bind(owner_renderer: ActorProceduralRendererComponent, owner_visual: ActorVisual) -> void:
	renderer = owner_renderer
	visual = owner_visual

func paint(def_id: String) -> void:
	match def_id:
		"mossling": _paint_mossling()
		"moonpetal_sprite": _paint_moonpetal_sprite()
		"thornhound": _paint_hound()
		"corrupted_treant", "elder_hollow": _paint_treant()
		"fallen_matron": _paint_fallen_matron()
		_: _paint_blob()


func _paint_blob() -> void:
	var squash := sin(visual.anim_time * 2.6) * 1.5
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(-17, -3), Vector2(-19, -18 - squash), Vector2(-10, -30), Vector2(0, -33 - squash),
		Vector2(11, -29), Vector2(19, -17 - squash), Vector2(16, -3)
	]), visual._primary)
	renderer.draw_circle(Vector2(-6, -23), 5.0, Color(visual._secondary.r, visual._secondary.g, visual._secondary.b, 0.7))
	renderer.draw_circle(Vector2(6, -25), 6.0, Color(visual._secondary.r, visual._secondary.g, visual._secondary.b, 0.55))
	renderer.draw_circle(Vector2(-5, -17), 2.1, Color("#10131c"))
	renderer.draw_circle(Vector2(5, -17), 2.1, Color("#10131c"))
	renderer.draw_circle(Vector2(-4.4, -17.7), 0.7, Color("#d9ff9f"))
	renderer.draw_circle(Vector2(5.6, -17.7), 0.7, Color("#d9ff9f"))
	renderer.draw_circle(Vector2(0, -12), 1.0, Color(visual._accent.r, visual._accent.g, visual._accent.b, 0.7))
	for index in 4:
		var x := -12.0 + index * 8.0
		renderer.draw_line(Vector2(x, -30), Vector2(x + 2, -36 - (index % 2) * 3), Color("#5d8f52"), 1.8)


func _paint_mossling() -> void:
	var bob := sin(visual.anim_time * 2.7) * 1.8
	var blink := 0.65 + 0.35 * sin(visual.anim_time * 1.4)
	# Low, squat moss creature with a layered fern mantle and seed-like eyes.
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(-20, -4), Vector2(-22, -17 - bob), Vector2(-14, -29 - bob),
		Vector2(-5, -33 - bob), Vector2(8, -31 - bob), Vector2(20, -20 - bob),
		Vector2(18, -5), Vector2(8, 1), Vector2(-12, 1)
	]), visual._primary.darkened(0.12))
	renderer.draw_ellipse_shadow(Vector2(0, -16 - bob), Vector2(13, 12))
	for i in 5:
		var x := -16.0 + float(i) * 8.0
		var sway := sin(visual.anim_time * 2.0 + float(i) * 0.9) * 2.0
		renderer.draw_colored_polygon(PackedVector2Array([
			Vector2(x, -24 - bob), Vector2(x - 5 + sway, -35 - bob),
			Vector2(x + 1, -43 - bob - float(i % 2) * 3.0),
			Vector2(x + 6 + sway, -30 - bob)
		]), visual._secondary if i % 2 == 0 else visual._primary.lightened(0.18))
	# Tiny amber eyes and a softly glowing mouth mark.
	renderer.draw_circle(Vector2(-6, -19 - bob), 2.5, Color("#152017"))
	renderer.draw_circle(Vector2(6, -19 - bob), 2.5, Color("#152017"))
	renderer.draw_circle(Vector2(-5.5, -20 - bob), 0.9, Color(visual._accent.r, visual._accent.g, visual._accent.b, blink))
	renderer.draw_circle(Vector2(6.5, -20 - bob), 0.9, Color(visual._accent.r, visual._accent.g, visual._accent.b, blink))
	renderer.draw_arc(Vector2(0, -12 - bob), 3.0, 0.2, PI - 0.2, 8, visual._secondary, 1.2)
	renderer.draw_circle(Vector2(-13, -7), 3.0, visual._secondary.darkened(0.2))
	renderer.draw_circle(Vector2(13, -7), 3.0, visual._secondary.darkened(0.2))


func _paint_moonpetal_sprite() -> void:
	var bob := sin(visual.anim_time * 2.1) * 3.0
	var wing := sin(visual.anim_time * 9.0) * 5.0
	var center := Vector2(0, -31 + bob)
	# Four translucent moonpetal wings, flapping independently of the body.
	for side in [-1.0, 1.0]:
		var spread := 20.0 + wing * 0.45
		renderer.draw_colored_polygon(PackedVector2Array([
			center + Vector2(side * 5, -7),
			center + Vector2(side * (spread + 9), -22 - wing * 0.35),
			center + Vector2(side * (spread + 5), -2),
			center + Vector2(side * 7, 5)
		]), Color(visual._secondary.r, visual._secondary.g, visual._secondary.b, 0.62))
		renderer.draw_colored_polygon(PackedVector2Array([
			center + Vector2(side * 4, 0),
			center + Vector2(side * (spread + 7), 10 + wing * 0.3),
			center + Vector2(side * (spread - 1), 22),
			center + Vector2(side * 3, 8)
		]), Color(visual._accent.r, visual._accent.g, visual._accent.b, 0.42))
	# Pearl body and long luminous antennae.
	renderer.draw_circle(center, 16.0, Color(visual._accent.r, visual._accent.g, visual._accent.b, 0.10))
	renderer.draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -12), center + Vector2(8, -2),
		center + Vector2(5, 13), center + Vector2(0, 18),
		center + Vector2(-5, 13), center + Vector2(-8, -2)
	]), visual._primary.lightened(0.22))
	renderer.draw_circle(center + Vector2(0, -13), 6.5, visual._secondary.lightened(0.2))
	renderer.draw_circle(center + Vector2(-2.2, -14), 1.2, Color("#182333"))
	renderer.draw_circle(center + Vector2(2.2, -14), 1.2, Color("#182333"))
	renderer.draw_line(center + Vector2(-3, -18), center + Vector2(-8, -27), visual._accent, 1.3)
	renderer.draw_line(center + Vector2(3, -18), center + Vector2(8, -27), visual._accent, 1.3)
	renderer.draw_circle(center + Vector2(-8, -27), 2.0, Color("#f4d9ff"))
	renderer.draw_circle(center + Vector2(8, -27), 2.0, Color("#f4d9ff"))
	renderer.draw_circle(center + Vector2(0, 3), 3.2, Color("#f4d9ff", 0.8))


func _paint_hound() -> void:
	var stride := sin(visual.anim_time * 10.0) * 3.0 if visual._view_moving else 0.0
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -18), Vector2(-12, -27), Vector2(2, -29), Vector2(14, -23),
		Vector2(20, -15), Vector2(12, -8), Vector2(-12, -8), Vector2(-20, -12)
	]), visual._primary)
	renderer.draw_circle(Vector2(17, -24), 8.0, visual._primary.lightened(0.08))
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(12, -30), Vector2(13, -38), Vector2(18, -31)
	]), visual._secondary)
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(20, -30), Vector2(23, -37), Vector2(25, -28)
	]), visual._secondary)
	renderer.draw_circle(Vector2(20, -25), 1.8, Color("#1c2230"))
	renderer.draw_circle(Vector2(21, -25.5), 0.6, visual._accent)
	# Thorn spines
	for index in 5:
		var x := -12.0 + index * 6.0
		renderer.draw_line(Vector2(x, -28), Vector2(x + 2, -35), Color("#8fbf6a"), 1.4)
	# Legs
	renderer.draw_line(Vector2(-13, -9), Vector2(-15 + stride, 0), visual._primary.darkened(0.4), 3.0)
	renderer.draw_line(Vector2(-4, -9), Vector2(-2 - stride, 0), visual._primary.darkened(0.4), 3.0)
	renderer.draw_line(Vector2(9, -9), Vector2(11 + stride, 0), visual._primary.darkened(0.4), 3.0)
	renderer.draw_line(Vector2(16, -9), Vector2(18 - stride, 0), visual._primary.darkened(0.4), 3.0)


func _paint_treant() -> void:
	if visual.def_id == "elder_hollow":
		_paint_elder_hollow()
	else:
		_paint_corrupted_treant()


func _paint_elder_hollow() -> void:
	# A tall, watchful woodland oracle: a hollow bark mask beneath a layered
	# leaf mantle, hanging root-beard and a lantern-heart. Not a generic owl.
	var sway := sin(visual.anim_time * 0.72) * 2.0
	var pulse := 0.72 + 0.28 * sin(visual.anim_time * 1.8)
	renderer.draw_set_transform(Vector2.ZERO, 0.0, Vector2(visual.facing * visual.visual_scale * 1.48, visual.visual_scale * 1.48))
	# Wide root-feet and tapered trunk robe.
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(-27, 1), Vector2(-21, -24), Vector2(-18, -55), Vector2(-22, -88),
		Vector2(-15, -112), Vector2(0, -120), Vector2(17, -108), Vector2(21, -82),
		Vector2(16, -50), Vector2(26, -20), Vector2(31, 2), Vector2(12, -7),
		Vector2(0, -25), Vector2(-12, -7)
	]), Color("#465b43"))
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -7), Vector2(-5, -54), Vector2(-2, -96), Vector2(8, -62),
		Vector2(13, -8), Vector2(1, -20)
	]), Color("#71815a"))
	# Carved grain, old knots and moss seams.
	for i in range(5):
		var x := -17.0 + float(i) * 8.0
		renderer.draw_line(Vector2(x, -17), Vector2(x + sin(float(i)) * 3.0, -82 - float(i % 2) * 9.0), Color("#293d32"), 2.0)
	renderer.draw_arc(Vector2(-12, -69), 5.0, 0.2, 5.7, 16, Color("#a0a36a"), 1.4)
	renderer.draw_arc(Vector2(13, -47), 4.0, 0.0, TAU, 16, Color("#a0a36a"), 1.4)
	# Branch arms form a cloak-like silhouette, with twig fingers.
	renderer.draw_line(Vector2(-15, -91), Vector2(-35, -73 + sway), Color("#493f32"), 7.0)
	renderer.draw_line(Vector2(-35, -73 + sway), Vector2(-48, -49 + sway), Color("#493f32"), 4.0)
	renderer.draw_line(Vector2(-43, -59 + sway), Vector2(-53, -65 + sway), Color("#493f32"), 2.0)
	renderer.draw_line(Vector2(15, -91), Vector2(35, -73 - sway), Color("#493f32"), 7.0)
	renderer.draw_line(Vector2(35, -73 - sway), Vector2(48, -49 - sway), Color("#493f32"), 4.0)
	renderer.draw_line(Vector2(43, -59 - sway), Vector2(53, -65 - sway), Color("#493f32"), 2.0)
	# Face: angular hollow mask, not round eyes on a round head.
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(-16, -112), Vector2(-13, -132), Vector2(-5, -141),
		Vector2(8, -138), Vector2(17, -124), Vector2(13, -103),
		Vector2(3, -94), Vector2(-10, -99)
	]), Color("#202d27"))
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(-10, -119), Vector2(-5, -126), Vector2(-1, -115), Vector2(-8, -111)
	]), Color("#d7e8a8", 0.9))
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(10, -119), Vector2(5, -126), Vector2(1, -115), Vector2(8, -111)
	]), Color("#d7e8a8", 0.9))
	renderer.draw_circle(Vector2(-5, -119), 2.0, Color("#f2ffce"))
	renderer.draw_circle(Vector2(5, -119), 2.0, Color("#f2ffce"))
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(-3, -108), Vector2(0, -101), Vector2(3, -108), Vector2(0, -113)
	]), Color("#101a17"))
	# A layered crown of crooked branches and broad leaves.
	renderer.draw_line(Vector2(-12, -128), Vector2(-28, -151 + sway), Color("#403b2d"), 4.0)
	renderer.draw_line(Vector2(-28, -151 + sway), Vector2(-43, -160 + sway), Color("#403b2d"), 2.8)
	renderer.draw_line(Vector2(-27, -150 + sway), Vector2(-25, -169 + sway), Color("#403b2d"), 2.5)
	renderer.draw_line(Vector2(12, -128), Vector2(28, -151 - sway), Color("#403b2d"), 4.0)
	renderer.draw_line(Vector2(28, -151 - sway), Vector2(43, -160 - sway), Color("#403b2d"), 2.8)
	renderer.draw_line(Vector2(27, -150 - sway), Vector2(25, -169 - sway), Color("#403b2d"), 2.5)
	for i in range(9):
		var lx := -38.0 + float(i) * 9.0
		var ly := -153.0 - float(i % 3) * 7.0 + sway
		renderer.draw_colored_polygon(PackedVector2Array([
			Vector2(lx, ly), Vector2(lx + 5, ly - 13), Vector2(lx + 14, ly - 9), Vector2(lx + 9, ly + 1)
		]), Color("#5e8b4e") if i % 2 == 0 else Color("#8ca65b"))
	# Hanging root beard and moss tassels.
	for i in range(7):
		var x := -15.0 + float(i) * 5.0
		renderer.draw_line(Vector2(x, -99), Vector2(x + sin(visual.anim_time + float(i)) * 2.0, -74 - float(i % 3) * 5.0), Color("#8a7850"), 1.8)
	# Lantern-heart glows softly through a split in the bark.
	var heart := Color("#dfff9b")
	var heart_y := -65.0 + sin(visual.anim_time * 1.6) * 1.4
	renderer.draw_circle(Vector2(0, heart_y), 16.0, Color(0.72, 1.0, 0.48, 0.12 * pulse))
	renderer.draw_circle(Vector2(0, heart_y), 7.0, Color(0.78, 1.0, 0.55, 0.28 * pulse))
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(0, heart_y - 9), Vector2(6, heart_y - 1), Vector2(0, heart_y + 8), Vector2(-6, heart_y - 1)
	]), heart)
	# Rooted toes spread over the ground plane.
	renderer.draw_line(Vector2(-17, -5), Vector2(-38, 4), Color("#374a36"), 5.0)
	renderer.draw_line(Vector2(16, -5), Vector2(38, 4), Color("#374a36"), 5.0)
	for i in range(5):
		var a := visual.anim_time * 0.35 + TAU * float(i) / 5.0
		var mote := Vector2(cos(a) * 31.0, -78.0 + sin(a) * 34.0)
		renderer.draw_circle(mote, 1.8, Color(0.82, 1.0, 0.55, 0.52 * pulse))


func _paint_corrupted_treant() -> void:
	# Greenward's fallen guardian: a massive ancient trunk with asymmetric
	# branch antlers, layered foliage, thorn limbs and vivid violet blight.
	var sway := sin(visual.anim_time * 0.9) * 2.4
	var pulse := 0.7 + 0.3 * sin(visual.anim_time * 2.2)
	renderer.draw_set_transform(Vector2.ZERO, 0.0, Vector2(visual.facing * visual.visual_scale * 1.32, visual.visual_scale * 1.32))
	# Root mantle and broad trunk torso.
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(-36, 3), Vector2(-29, -30), Vector2(-25, -67), Vector2(-32, -98),
		Vector2(-20, -128), Vector2(-5, -145), Vector2(17, -139), Vector2(31, -112),
		Vector2(25, -76), Vector2(35, -36), Vector2(43, 3), Vector2(18, -8),
		Vector2(0, -28), Vector2(-17, -7)
	]), Color("#554334"))
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(-12, -8), Vector2(-9, -52), Vector2(-2, -104), Vector2(12, -65),
		Vector2(20, -5), Vector2(2, -27)
	]), Color("#826044"))
	# Massive split roots and branch-like arms.
	renderer.draw_line(Vector2(-23, -12), Vector2(-49, 9), Color("#4b382d"), 9.0)
	renderer.draw_line(Vector2(-49, 9), Vector2(-65, 5), Color("#4b382d"), 5.0)
	renderer.draw_line(Vector2(22, -12), Vector2(49, 8), Color("#4b382d"), 9.0)
	renderer.draw_line(Vector2(49, 8), Vector2(65, 4), Color("#4b382d"), 5.0)
	renderer.draw_line(Vector2(-22, -115), Vector2(-52, -90 + sway), Color("#49382c"), 10.0)
	renderer.draw_line(Vector2(-52, -90 + sway), Vector2(-70, -64 + sway), Color("#49382c"), 6.0)
	renderer.draw_line(Vector2(-52, -90 + sway), Vector2(-77, -94 + sway), Color("#49382c"), 4.0)
	renderer.draw_line(Vector2(22, -115), Vector2(52, -88 - sway), Color("#49382c"), 10.0)
	renderer.draw_line(Vector2(52, -88 - sway), Vector2(71, -58 - sway), Color("#49382c"), 6.0)
	renderer.draw_line(Vector2(52, -88 - sway), Vector2(80, -96 - sway), Color("#49382c"), 4.0)
	# Bark plates, knots and exposed root grain.
	for i in range(7):
		var x := -25.0 + float(i) * 8.0
		renderer.draw_line(Vector2(x, -23), Vector2(x + sin(float(i) * 1.7) * 4.0, -105 - float(i % 3) * 8.0), Color("#342a25"), 2.6)
	renderer.draw_arc(Vector2(-14, -77), 8.0, 0.2, 5.8, 18, Color("#aa8051"), 2.0)
	renderer.draw_arc(Vector2(18, -50), 6.0, 0.0, TAU, 18, Color("#aa8051"), 1.8)
	# Deep face cavity and blazing corruption core.
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(-19, -119), Vector2(-15, -143), Vector2(0, -153), Vector2(18, -139),
		Vector2(20, -116), Vector2(10, -101), Vector2(-9, -102)
	]), Color("#1a171c"))
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(-13, -129), Vector2(-4, -136), Vector2(-2, -122), Vector2(-13, -119)
	]), Color("#e85bd7"))
	renderer.draw_colored_polygon(PackedVector2Array([
		Vector2(13, -129), Vector2(4, -136), Vector2(2, -122), Vector2(13, -119)
	]), Color("#e85bd7"))
	renderer.draw_circle(Vector2(0, -110), 5.5, Color("#c638e7", 0.7 * pulse))
	# Huge antler crown, broken and uneven like a dead canopy.
	for side in [-1.0, 1.0]:
		var root := Vector2(side * 13.0, -143.0)
		var branch := Vector2(side * (49.0 + sway), -177.0)
		renderer.draw_line(root, branch, Color("#3e3029"), 7.0)
		renderer.draw_line(branch, Vector2(side * 78.0, -194.0 + sway), Color("#3e3029"), 4.0)
		renderer.draw_line(branch, Vector2(side * 70.0, -157.0 + sway), Color("#3e3029"), 3.5)
		renderer.draw_line(Vector2(side * 47.0, -177.0), Vector2(side * 43.0, -198.0), Color("#3e3029"), 3.0)
	# Leaf crown in broken clumps, not a smooth green blob.
	for i in range(11):
		var lx := -70.0 + float(i) * 14.0
		var ly := -179.0 - float(i % 3) * 7.0 + sin(visual.anim_time * 1.3 + float(i)) * 2.0
		renderer.draw_colored_polygon(PackedVector2Array([
			Vector2(lx, ly), Vector2(lx + 5, ly - 17), Vector2(lx + 16, ly - 13), Vector2(lx + 13, ly + 1)
		]), Color("#4f7139") if i % 2 == 0 else Color("#81994a"))
	# Purple corruption fissures and thorn growths.
	for i in range(6):
		var x := -21.0 + float(i) * 8.0
		renderer.draw_line(Vector2(x, -40), Vector2(x + sin(visual.anim_time * 1.6 + i) * 3.0, -103 - float(i % 2) * 11.0), Color(0.85, 0.22, 0.92, 0.82 * pulse), 2.3)
	for i in range(5):
		var x := -28.0 + float(i) * 14.0
		renderer.draw_colored_polygon(PackedVector2Array([
			Vector2(x, -56), Vector2(x + 5, -76), Vector2(x + 10, -55)
		]), Color("#6c365d"))
	# Bright flower-core embedded in the chest.
	var heart_y := -74.0 + sin(visual.anim_time * 2.0) * 1.8
	renderer.draw_circle(Vector2(0, heart_y), 18.0, Color(0.86, 0.16, 0.96, 0.16 * pulse))
	for i in range(6):
		var a := TAU * float(i) / 6.0 + visual.anim_time * 0.12
		var petal := Vector2(cos(a) * 9.0, heart_y + sin(a) * 9.0)
		renderer.draw_circle(petal, 4.2, Color("#d34df0", 0.9 * pulse))
	renderer.draw_circle(Vector2(0, heart_y), 4.5, Color("#fff0ff"))
	# Floating blight sparks around the silhouette.
	for i in range(8):
		var a := visual.anim_time * 0.42 + TAU * float(i) / 8.0
		var mote := Vector2(cos(a) * 82.0, -102.0 + sin(a) * 67.0)
		renderer.draw_circle(mote, 2.0, Color(0.95, 0.38, 1.0, 0.55 * pulse))


func _paint_fallen_matron() -> void:
	# Use the supplied painted Matron cutout in the overworld too. The former
	# vector stand-in was a generic low-detail figure and did not match her
	# authored horns, silver-lilac hair, lace gown or ornate costume.
	var pulse := 0.75 + 0.25 * sin(visual.anim_time * 2.1)
	renderer.draw_set_transform(Vector2.ZERO, 0.0, Vector2(visual.facing * visual.visual_scale, visual.visual_scale))
	# Grounded violet aura and painted full-body silhouette.
	renderer.draw_circle(Vector2(0, -60), 43.0, Color(0.56, 0.18, 0.82, 0.075 * pulse))
	renderer.draw_texture_rect(ActorVisual.FALLEN_MATRON_WORLD_TEXTURE, Rect2(-48, -137, 96, 132), false)
	# Small animated corruption motes frame the figure without obscuring it.
	for i in range(6):
		var angle := visual.anim_time * 0.65 + TAU * float(i) / 6.0
		var point := Vector2(cos(angle) * 43.0, -73.0 + sin(angle) * 29.0)
		renderer.draw_circle(point, 2.0, Color(0.82, 0.43, 1.0, 0.42 + 0.24 * pulse))
		renderer.draw_circle(point, 4.5, Color(0.72, 0.24, 1.0, 0.10 * pulse))
	return
