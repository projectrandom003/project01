class_name MainBackdropLayoutComponent
extends Node
## Owns responsive static geometry for the title-screen backdrop.

var presentation: MainBackdropPresentationComponent

func bind(owner: MainBackdropPresentationComponent) -> void:
	presentation = owner

func rebuild() -> void:
	var w := presentation.backdrop.size.x
	var h := presentation.backdrop.size.y
	if w <= 2.0 or h <= 2.0:
		return
	if presentation._built_static_for_size == presentation.backdrop.size and presentation._city_layer.get_child_count() > 0:
		presentation._update_animation(0.0)
		return
	presentation._built_static_for_size = presentation.backdrop.size

	# Moon (static base geometry; arc animated)
	var moon := Vector2(w * 0.76, h * 0.22)
	var moon_r := minf(w, h) * 0.115
	presentation._halo_outer.polygon = presentation._circle_poly(moon, moon_r * 2.0, 48)
	presentation._halo_inner.polygon = presentation._circle_poly(moon, moon_r * 1.45, 48)
	presentation._blood_moon.polygon = presentation._circle_poly(moon, moon_r, 48)
	presentation._moon_shadow.polygon = presentation._circle_poly(moon + Vector2(moon_r * 0.28, -moon_r * 0.08), moon_r * 0.88, 48)
	presentation._moon_arc.width = 2.0
	presentation._moon_arc.default_color = Color(1.0, 0.55, 0.58, 0.28)

	# Distant mountains
	presentation._distant_mountains.polygon = PackedVector2Array([
		Vector2(0, h * 0.60), Vector2(w * 0.12, h * 0.46), Vector2(w * 0.25, h * 0.55),
		Vector2(w * 0.39, h * 0.43), Vector2(w * 0.56, h * 0.56), Vector2(w * 0.70, h * 0.45),
		Vector2(w * 0.88, h * 0.54), Vector2(w, h * 0.47), Vector2(w, h * 0.79), Vector2(0, h * 0.79)
	])

	# Ruined city silhouette
	var city_y := h * 0.70
	for i in presentation._city_layer.get_child_count():
		var n := presentation._city_layer.get_child(i) as Node2D
		if n == null: continue
		var cx := w * (0.39 + float(i) * 0.036)
		var cw := 18.0 + float(i % 3) * 9.0
		var ch := h * (0.12 + float((i * 7) % 5) * 0.035)
		var body := n.get_node_or_null("Body") as ColorRect
		var roof := n.get_node_or_null("Roof") as Polygon2D
		var win := n.get_node_or_null("Window") as ColorRect
		if body:
			body.position = Vector2(cx, city_y - ch); body.size = Vector2(cw, ch); body.color = Color("#100e1b")
		if roof:
			roof.polygon = PackedVector2Array([Vector2(cx - 5, city_y - ch), Vector2(cx + cw * 0.5, city_y - ch - 17), Vector2(cx + cw + 5, city_y - ch)])
			roof.color = Color("#17101f")
		if win:
			var show_win := (i % 4 == 0)
			win.visible = show_win
			if show_win:
				win.position = Vector2(cx + cw * 0.48, city_y - ch * 0.72); win.size = Vector2(3, 8); win.color = Color(1.0, 0.28, 0.34, 0.75)

	# Village windows/houses
	for i in presentation._village_layer.get_child_count():
		var n := presentation._village_layer.get_child(i) as Node2D
		if n == null: continue
		var x := w * (0.035 + float(i) * 0.048)
		var base := h * (0.72 + float(i % 3) * 0.012)
		var bw := 25.0 + float(i % 2) * 9.0
		var bh := 35.0 + float((i * 3) % 4) * 8.0
		var body := n.get_node_or_null("Body") as ColorRect
		var roof := n.get_node_or_null("Roof") as Polygon2D
		var win := n.get_node_or_null("Window") as ColorRect
		if body:
			body.position = Vector2(x, base - bh); body.size = Vector2(bw, bh); body.color = Color("#111925")
		if roof:
			roof.polygon = PackedVector2Array([Vector2(x - 4, base - bh), Vector2(x + bw * 0.5, base - bh - 16), Vector2(x + bw + 4, base - bh)])
			roof.color = Color("#1b2030")
		if win:
			var show_win := (i % 2 == 0)
			win.visible = show_win
			if show_win:
				win.position = Vector2(x + bw * 0.56, base - bh * 0.62); win.size = Vector2(4, 7); win.color = Color(1.0, 0.72, 0.42, 0.72)

	# First Tree trunk/branches/roots (branches/roots animated positions updated in presentation._update_animation)
	var tx := w * 0.79
	presentation._tree_trunk.polygon = PackedVector2Array([
		Vector2(tx - w * 0.075, h), Vector2(tx - w * 0.055, h * 0.62),
		Vector2(tx - w * 0.035, h * 0.37), Vector2(tx - w * 0.026, h * 0.18),
		Vector2(tx + w * 0.005, h * 0.14), Vector2(tx + w * 0.035, h * 0.30),
		Vector2(tx + w * 0.052, h * 0.62), Vector2(tx + w * 0.09, h)
	])
	for i in presentation._tree_branches.get_child_count():
		var n := presentation._tree_branches.get_child(i) as Node2D
		if n == null: continue
		var main := n.get_node_or_null("Main") as Line2D
		var twig := n.get_node_or_null("Twig") as Line2D
		if main: main.width = 10.0 - float(i % 3) * 1.5; main.default_color = Color("#111a1c")
		if twig: twig.width = 4.0; twig.default_color = Color("#111a1c")
	for i in presentation._tree_roots.get_child_count():
		var n := presentation._tree_roots.get_child(i) as Node2D
		var line := n.get_node_or_null("Line") as Line2D if n else null
		if line: line.width = 7.0; line.default_color = Color("#1b2924")

	# Stone arch
	var ax := w * 0.40
	var base_y := h * 0.76
	presentation._left_pillar.points = PackedVector2Array([Vector2(ax - 76, base_y), Vector2(ax - 76, h * 0.48)])
	presentation._right_pillar.points = PackedVector2Array([Vector2(ax + 76, base_y), Vector2(ax + 76, h * 0.51)])
	presentation._arch_curve.points = presentation._arc_points(Vector2(ax, h * 0.55), 76.0, PI, TAU * 0.97, 42)
	presentation._left_break.points = PackedVector2Array([Vector2(ax - 76, h * 0.48), Vector2(ax - 91, h * 0.43)])
	presentation._right_break.points = PackedVector2Array([Vector2(ax + 76, h * 0.51), Vector2(ax + 91, h * 0.47)])
	presentation._left_base.position = Vector2(ax - 90, base_y - 4); presentation._left_base.size = Vector2(28, 8)
	presentation._right_base.position = Vector2(ax + 61, base_y - 4); presentation._right_base.size = Vector2(28, 8)

	# Stone path
	presentation._path_surface.polygon = PackedVector2Array([
		Vector2(w * 0.30, h), Vector2(w * 0.45, h * 0.73),
		Vector2(w * 0.62, h * 0.72), Vector2(w * 0.78, h)
	])
	for i in presentation._path_lines.get_child_count():
		var n := presentation._path_lines.get_child(i) as Node2D
		var line := n.get_node_or_null("Line") as Line2D if n else null
		if line == null: continue
		var y := h * (0.78 + float(i) * 0.034)
		var half := w * (0.055 + float(i) * 0.014)
		line.points = PackedVector2Array([Vector2(w * 0.55 - half, y), Vector2(w * 0.55 + half, y)])
		line.width = 1.2
		line.default_color = Color(0.55, 0.55, 0.68, 0.16)

	# Magical seal rings static base radii/colors; spokes animated
	presentation._outer_ring.default_color = Color(0.62, 0.75, 0.88, 0.30)
	presentation._inner_ring.default_color = Color(0.62, 0.75, 0.88, 0.30)
	for i in presentation._seal_spokes.get_child_count():
		var n := presentation._seal_spokes.get_child(i) as Node2D
		var line := n.get_node_or_null("Line") as Line2D if n else null
		if line:
			line.width = 1.0
			line.default_color = Color(0.68, 0.78, 0.95, 0.18)

	# Foreground trees - keep visible set matching original gap
	var vis_idx := 0
	for i in 15:
		var x := float(i) / 14.0 * w
		if x > w * 0.30 and x < w * 0.52:
			continue
		if vis_idx >= presentation._foreground_trees.get_child_count():
			break
		var n := presentation._foreground_trees.get_child(vis_idx) as Node2D
		vis_idx += 1
		if n == null: continue
		n.set_meta("base_x", x)
		n.set_meta("height", h * (0.12 + float((i * 7) % 5) * 0.025))
		n.set_meta("canopy_r", 20.0 + float(i % 3) * 5.0)
		var trunk := n.get_node_or_null("Trunk") as Line2D
		var canopy := n.get_node_or_null("Canopy") as Polygon2D
		if trunk: trunk.width = 6.0; trunk.default_color = Color("#0b121b")
		if canopy: canopy.color = Color("#0b121b")
	# Hide extras if any
	for j in range(vis_idx, presentation._foreground_trees.get_child_count()):
		var n := presentation._foreground_trees.get_child(j)
		if n is CanvasItem: (n as CanvasItem).visible = false

	presentation._update_animation(0.0)

