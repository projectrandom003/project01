class_name ProceduralCharacterArt
extends RefCounted
## Dedicated renderer for temporary procedural character animation frames.
## Prop painting and shared pixel primitives remain owned by ProceduralArt.

static func _ellipse(image: Image, center: Vector2, radius: Vector2, color: Color, grain: float = 0.0) -> void:
	ProceduralArt._ellipse(image, center, radius, color, grain)

static func _polygon(image: Image, points: Array, color: Color) -> void:
	ProceduralArt._polygon(image, points, color)

static func _line(image: Image, from: Vector2, to: Vector2, width: float, color: Color) -> void:
	ProceduralArt._line(image, from, to, width, color)

static func _as_color(value: Variant, fallback: Color) -> Color:
	return ProceduralArt._as_color(value, fallback)

static func _frame_signature(state: int, direction: int, frame_index: int) -> int:
	return ProceduralArt._frame_signature(state, direction, frame_index)

static func _grain(x: int, y: int) -> float:
	return ProceduralArt._grain(x, y)

# Offset-aware wrappers keep whole-figure bob/recoil choreography local.
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


static func draw_frame(image: Image, palette: Dictionary, state: int, direction: int, frame_index: int) -> void:
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
