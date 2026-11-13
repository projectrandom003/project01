class_name MainBackdrop
extends Control
## Animated moonlit Greenward scene for the title experience.
## All scenery is original procedural art; character designs are layered above
## this background from their registered playable sprite sheets.

var _time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 2.0 or h <= 2.0:
		return
	# Crimson eclipse sky with a deep violet horizon.
	for i in range(64):
		var t := float(i) / 63.0
		var c := Color("#080813").lerp(Color("#21172a"), t)
		if t > 0.62:
			c = c.lerp(Color("#542b3b"), (t - 0.62) / 0.38 * 0.48)
		draw_rect(Rect2(0, h * t, w, h / 63.0 + 1.0), c)
	# Blood moon and layered crimson halo.
	var moon := Vector2(w * 0.76, h * 0.22)
	var moon_r := minf(w, h) * 0.115
	draw_circle(moon, moon_r * 2.0, Color(0.92, 0.18, 0.29, 0.045))
	draw_circle(moon, moon_r * 1.45, Color(0.92, 0.18, 0.29, 0.09))
	draw_circle(moon, moon_r, Color("#c95c68"))
	draw_circle(moon + Vector2(moon_r * 0.28, -moon_r * 0.08), moon_r * 0.88, Color("#261522"))
	draw_arc(moon, moon_r * 1.18, _time * 0.035, _time * 0.035 + TAU * 0.82, 96, Color(1.0, 0.55, 0.58, 0.28), 2.0)
	# Distant mountains and the broken silhouette of the old capital.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, h * 0.60), Vector2(w * 0.12, h * 0.46), Vector2(w * 0.25, h * 0.55),
		Vector2(w * 0.39, h * 0.43), Vector2(w * 0.56, h * 0.56), Vector2(w * 0.70, h * 0.45),
		Vector2(w * 0.88, h * 0.54), Vector2(w, h * 0.47), Vector2(w, h * 0.79), Vector2(0, h * 0.79)
	]), Color("#10101d"))
	var city_y := h * 0.70
	for i in range(17):
		var cx := w * (0.39 + float(i) * 0.036)
		var cw := 18.0 + float(i % 3) * 9.0
		var ch := h * (0.12 + float((i * 7) % 5) * 0.035)
		draw_rect(Rect2(cx, city_y - ch, cw, ch), Color("#100e1b"))
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 5, city_y - ch), Vector2(cx + cw * 0.5, city_y - ch - 17), Vector2(cx + cw + 5, city_y - ch)]), Color("#17101f"))
		if i % 4 == 0:
			draw_rect(Rect2(cx + cw * 0.48, city_y - ch * 0.72, 3, 8), Color(1.0, 0.28, 0.34, 0.75))
	# A few warm village windows in the far left distance.
	for i in range(7):
		var x := w * (0.035 + float(i) * 0.048)
		var base := h * (0.72 + float(i % 3) * 0.012)
		var bw := 25.0 + float(i % 2) * 9.0
		var bh := 35.0 + float((i * 3) % 4) * 8.0
		draw_rect(Rect2(x, base - bh, bw, bh), Color("#111925"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 4, base - bh), Vector2(x + bw * 0.5, base - bh - 16),
			Vector2(x + bw + 4, base - bh)
		]), Color("#1b2030"))
		if i % 2 == 0:
			draw_rect(Rect2(x + bw * 0.56, base - bh * 0.62, 4, 7), Color(1.0, 0.72, 0.42, 0.72))
	# Ancient First Tree dominates the right skyline.
	var tx := w * 0.79
	var trunk_sway := sin(_time * 0.18) * 3.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(tx - w * 0.075, h), Vector2(tx - w * 0.055, h * 0.62),
		Vector2(tx - w * 0.035, h * 0.37), Vector2(tx - w * 0.026, h * 0.18),
		Vector2(tx + w * 0.005, h * 0.14), Vector2(tx + w * 0.035, h * 0.30),
		Vector2(tx + w * 0.052, h * 0.62), Vector2(tx + w * 0.09, h)
	]), Color("#111a1c"))
	for i in range(9):
		var start := Vector2(tx + (float(i) - 4.0) * 11.0, h * (0.43 + float(i % 3) * 0.035))
		var end := Vector2(tx + (float(i) - 4.0) * w * 0.105 + trunk_sway, h * (0.04 + float(i % 2) * 0.12))
		draw_line(start, end, Color("#111a1c"), 10.0 - float(i % 3) * 1.5)
		if i % 2 == 0:
			draw_line(end, end + Vector2(-16 if i < 4 else 16, -18), Color("#111a1c"), 4.0)
	# Root fingers spread across the forest floor.
	for i in range(6):
		var root_x := tx + (float(i) - 2.5) * 26.0
		draw_line(Vector2(tx, h * 0.79), Vector2(root_x, h * (0.94 + float(i % 2) * 0.025)), Color("#1b2924"), 7.0)
	# Broken stone arch and fallen pillars in the mid-ground.
	var ax := w * 0.40
	var base_y := h * 0.76
	draw_line(Vector2(ax - 76, base_y), Vector2(ax - 76, h * 0.48), Color("#242638"), 13.0)
	draw_line(Vector2(ax + 76, base_y), Vector2(ax + 76, h * 0.51), Color("#242638"), 13.0)
	draw_arc(Vector2(ax, h * 0.55), 76.0, PI, TAU * 0.97, 42, Color("#303044"), 12.0, true)
	draw_line(Vector2(ax - 76, h * 0.48), Vector2(ax - 91, h * 0.43), Color("#303044"), 9.0)
	draw_line(Vector2(ax + 76, h * 0.51), Vector2(ax + 91, h * 0.47), Color("#303044"), 9.0)
	draw_rect(Rect2(ax - 90, base_y - 4, 28, 8), Color("#343247"))
	draw_rect(Rect2(ax + 61, base_y - 4, 28, 8), Color("#343247"))
	# Stone path leads from the foreground toward the First Tree.
	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.30, h), Vector2(w * 0.45, h * 0.73),
		Vector2(w * 0.62, h * 0.72), Vector2(w * 0.78, h)
	]), Color("#202433"))
	for i in range(7):
		var y := h * (0.78 + float(i) * 0.034)
		var half := w * (0.055 + float(i) * 0.014)
		draw_line(Vector2(w * 0.55 - half, y), Vector2(w * 0.55 + half, y), Color(0.55, 0.55, 0.68, 0.16), 1.2)
	# A broken, softly glowing seal beneath the First Tree.
	var seal := Vector2(w * 0.69, h * 0.79)
	var pulse := 1.0 + 0.045 * sin(_time * 1.6)
	for radius in [h * 0.075, h * 0.11]:
		draw_arc(seal, radius * pulse, 0.12, PI * 1.84, 72, Color(0.62, 0.75, 0.88, 0.30), 2.0)
	for i in range(8):
		var a := TAU * float(i) / 8.0 + _time * 0.025
		var p1 := seal + Vector2(cos(a), sin(a)) * h * 0.045
		var p2 := seal + Vector2(cos(a), sin(a)) * h * 0.11
		draw_line(p1, p2, Color(0.68, 0.78, 0.95, 0.18), 1.0)
	# Foreground tree silhouettes frame the composition.
	for i in range(15):
		var x := float(i) / 14.0 * w
		if x > w * 0.30 and x < w * 0.52:
			continue
		var height := h * (0.12 + float((i * 7) % 5) * 0.025)
		var sway := sin(_time * 0.35 + float(i)) * 2.0
		draw_line(Vector2(x, h), Vector2(x + sway, h - height), Color("#0b121b"), 6.0)
		draw_circle(Vector2(x + sway, h - height), 20.0 + float(i % 3) * 5.0, Color("#0b121b"))
	# Slow fog sheets drift across the path.
	for i in range(5):
		var fx := fposmod(float(i) * w * 0.27 + _time * (7.0 + float(i) * 2.0), w + 220.0) - 110.0
		var fy := h * (0.73 + float(i % 3) * 0.045)
		draw_circle(Vector2(fx, fy), 70.0 + float(i % 2) * 25.0, Color(0.60, 0.67, 0.79, 0.025))
	# Fireflies and pale petals.
	for i in range(38):
		var x := fposmod(float(i) * 103.0 + sin(_time * 0.26 + float(i)) * 24.0, w)
		var y := fposmod(float(i) * 59.0 - _time * (4.0 + float(i % 4) * 1.6), h)
		var alpha := 0.18 + 0.17 * sin(_time * 1.4 + float(i))
		var color := Color("#d6e7ae") if i % 3 != 0 else Color("#c7b2ef")
		draw_circle(Vector2(x, y), 1.5 + float(i % 2), Color(color.r, color.g, color.b, alpha))
	# Drifting crimson petals and ember motes.
	for i in range(34):
		var px := fposmod(float(i) * 127.0 + sin(_time * 0.32 + i) * 34.0, w)
		var py := fposmod(float(i) * 71.0 - _time * (10.0 + float(i % 4) * 2.0), h)
		var petal := Vector2(4.0 + float(i % 3), 2.0 + float(i % 2))
		draw_set_transform(Vector2(px, py), _time * 0.3 + float(i))
		draw_colored_polygon(PackedVector2Array([Vector2(-petal.x, 0), Vector2(0, -petal.y), Vector2(petal.x, 0), Vector2(0, petal.y)]), Color(0.78, 0.13, 0.25, 0.48))
		draw_set_transform(Vector2.ZERO)
	# Bottom vignette leaves a quiet dark band for menu metadata.
	draw_rect(Rect2(0, h * 0.93, w, h * 0.07), Color(0.025, 0.018, 0.035, 0.54))
