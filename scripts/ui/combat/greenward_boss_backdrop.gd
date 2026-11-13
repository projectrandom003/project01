extends Control
## Ancient Greenward boss arena for the Hollowed Guardian and Elder Hollow.
## Presentation-only; the battle engine and encounter data remain untouched.
var arena_id: String = "corrupted_treant"
var _clock: float = 0.0
var _redraw_accumulator: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	_clock += delta
	_redraw_accumulator += delta
	# The backdrop is presentation-only; 30 Hz is ample for drifting fog,
	# fireflies and slow ritual pulses, and avoids a full-scene redraw at 60+ Hz.
	if _redraw_accumulator >= (1.0 / 30.0):
		_redraw_accumulator = fmod(_redraw_accumulator, 1.0 / 30.0)
		queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var elder := arena_id == "elder_hollow"
	var deep := Color("#07120f") if not elder else Color("#090f0b")
	var mid := Color("#15291b") if not elder else Color("#1d2918")
	var glow := Color("#8ee07a") if not elder else Color("#d4f59a")
	draw_rect(Rect2(Vector2.ZERO, size), deep)
	# Mist bands behind the clearing.
	for i in range(8):
		var y := h * (0.12 + float(i) * 0.075)
		var alpha := 0.035 + 0.02 * sin(_clock * 0.55 + float(i) * 0.7)
		draw_rect(Rect2(0, y, w, h * 0.08), Color(mid.r, mid.g, mid.b, alpha))
	# Distant forest silhouettes, deliberately spaced to keep the arena readable.
	for i in range(9):
		var x := w * (float(i) + 0.5) / 9.0
		var height := h * (0.25 + 0.09 * absf(sin(float(i) * 1.7)))
		draw_rect(Rect2(x - 5, h * 0.42 - height * 0.35, 10, height), Color("#101d16"))
		for branch in range(3):
			var by := h * 0.40 - height * (0.25 + float(branch) * 0.18)
			draw_line(Vector2(x, by), Vector2(x - 26 - branch * 5, by - 24), Color("#1e3826"), 5.0)
			draw_line(Vector2(x, by), Vector2(x + 25 + branch * 4, by - 21), Color("#1e3826"), 5.0)
	# Irregular overlapping canopy silhouettes. Avoid the repeated circular
	# "bubble forest" look: each crown has its own uneven, branch-led outline.
	for i in range(8):
		var x := w * (float(i) + 0.5) / 8.0
		var cy := h * (0.23 + 0.035 * sin(float(i) * 1.8))
		var rx := w * (0.075 + 0.012 * float(i % 3))
		var shade := Color("#172a1c") if i % 2 == 0 else Color("#203522")
		var crown := PackedVector2Array()
		for point in range(16):
			var angle := TAU * float(point) / 16.0
			var irregularity := 1.0 + 0.11 * sin(float(point) * 2.7 + float(i) * 1.9) + 0.055 * cos(float(point) * 4.1 - float(i))
			var crown_point := Vector2(cos(angle) * rx * irregularity, sin(angle) * rx * 0.55 * irregularity)
			crown.append(Vector2(x, cy) + crown_point)
		draw_colored_polygon(crown, shade)
		# Broken leaf shelves and thin branch highlights give the crown structure.
		for shelf in range(4):
			var sx := x - rx * 0.72 + float(shelf) * rx * 0.46
			var sy := cy + rx * (0.05 + 0.13 * sin(float(shelf) * 1.8 + float(i)))
			var shelf_points := PackedVector2Array([
				Vector2(sx - rx * 0.22, sy + 3.0),
				Vector2(sx - rx * 0.12, sy - rx * 0.12),
				Vector2(sx + rx * 0.08, sy - rx * 0.18),
				Vector2(sx + rx * 0.25, sy + 1.0),
				Vector2(sx + rx * 0.12, sy + rx * 0.12)
			])
			draw_colored_polygon(shelf_points, shade.lightened(0.10 + 0.025 * float(shelf)))
		# Hanging root-vines break the skyline and give the canopy vertical depth.
		for vine in range(3):
			var vx := x - rx * 0.55 + float(vine) * rx * 0.48
			var drop := h * (0.10 + 0.07 * absf(sin(float(i + vine) * 2.1)))
			var sway := sin(_clock * 0.45 + float(i + vine)) * 3.0
			draw_line(Vector2(vx, cy + rx * 0.25), Vector2(vx + sway, cy + drop), Color("#29442b", 0.78), 2.0)
	# Broken standing stones frame the ritual ground and create a readable arena silhouette.
	for i in range(3):
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := w * (0.10 + float(i) * 0.16) if side < 0.0 else w * (0.90 - float(i) * 0.12)
		var base := h * (0.77 - float(i % 2) * 0.035)
		var height := h * (0.18 + float(i % 3) * 0.035)
		var stone := PackedVector2Array([
			Vector2(x - 13.0, base), Vector2(x - 11.0, base - height * 0.72),
			Vector2(x - 3.0, base - height), Vector2(x + 12.0, base - height * 0.82),
			Vector2(x + 14.0, base)
		])
		draw_colored_polygon(stone, Color("#263b2c"))
		draw_line(Vector2(x - 4.0, base - height * 0.82), Vector2(x + 3.0, base - height * 0.32), Color("#62744a", 0.45), 1.5)
		draw_circle(Vector2(x, base - height * 0.62), 4.0, Color(glow.r, glow.g, glow.b, 0.16))
	# The enormous guardian tree anchors the background.
	var trunk_x := w * 0.76
	var trunk_top := h * 0.08
	draw_colored_polygon(PackedVector2Array([
		Vector2(trunk_x - w * 0.075, h * 0.68),
		Vector2(trunk_x - w * 0.055, h * 0.30),
		Vector2(trunk_x - w * 0.025, trunk_top),
		Vector2(trunk_x + w * 0.015, h * 0.12),
		Vector2(trunk_x + w * 0.07, h * 0.68)
	]), Color("#263b28") if not elder else Color("#34412a"))
	for i in range(7):
		var start := Vector2(trunk_x + (float(i) - 3.0) * 10.0, h * (0.30 + float(i % 3) * 0.045))
		var end := Vector2(trunk_x + (float(i) - 3.0) * w * 0.12, h * (0.05 + float(i % 2) * 0.08))
		draw_line(start, end, Color("#344b30"), 8.0 if i % 2 == 0 else 5.0)
	# Hollow in the trunk: the boss's heart pulses in response to the battle.
	var heart := Vector2(trunk_x, h * 0.39)
	var pulse := 1.0 + 0.12 * sin(_clock * (1.7 if elder else 1.2))
	draw_circle(heart, h * 0.055 * pulse, Color(glow.r, glow.g, glow.b, 0.10))
	draw_circle(heart, h * 0.027 * pulse, Color(glow.r, glow.g, glow.b, 0.28))
	draw_circle(heart, h * 0.012, glow)
	# Foreground roots form a natural arena boundary, not a cluttered prop field.
	for i in range(6):
		var x := w * (0.08 + float(i) * 0.17)
		var lift := h * (0.04 + 0.025 * absf(sin(float(i) * 2.2)))
		draw_line(Vector2(x, h * 0.77), Vector2(x + 42, h * 0.77 - lift), Color("#3b4a2b"), 7.0)
		draw_line(Vector2(x + 42, h * 0.77 - lift), Vector2(x + 92, h * 0.82), Color("#3b4a2b"), 5.0)
	# Cracked stone ring in the clearing.
	var center := Vector2(w * 0.50, h * 0.83)
	for radius in [h * 0.12, h * 0.17]:
		draw_arc(center, radius, PI * 1.05, PI * 1.95, 72, Color(0.55, 0.67, 0.48, 0.28), 2.0)
	for i in range(10):
		var a := TAU * float(i) / 10.0
		var p := center + Vector2(cos(a) * h * 0.145, sin(a) * h * 0.145)
		draw_line(p, p + Vector2(cos(a + 0.25), sin(a + 0.25)) * 12.0, Color("#64734b"), 1.5)
	# A few fireflies and falling leaves animate the otherwise quiet clearing.
	for i in range(22):
		var x := fposmod(float(i) * 91.0 + sin(_clock * 0.4 + float(i)) * 20.0, w)
		var y := fposmod(float(i) * 47.0 - _clock * (5.0 + float(i % 3) * 2.0), h)
		draw_circle(Vector2(x, y), 1.4 + float(i % 2), Color(glow.r, glow.g, glow.b, 0.35 + 0.15 * sin(_clock + float(i))))
	# Soft floor vignette helps the combatants read against the arena.
	draw_rect(Rect2(0, h * 0.69, w, h * 0.31), Color(0.015, 0.025, 0.018, 0.48))
