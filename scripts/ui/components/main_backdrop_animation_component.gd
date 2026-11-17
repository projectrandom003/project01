class_name MainBackdropAnimationComponent
extends Node
## Owns ambient moon, tree, seal, fog, firefly and petal motion.

var presentation: MainBackdropPresentationComponent

func bind(owner: MainBackdropPresentationComponent) -> void:
	presentation = owner

func update_animation(delta: float) -> void:
	var w := presentation.backdrop.size.x
	var h := presentation.backdrop.size.y
	if w <= 2.0 or h <= 2.0:
		return
	# Moon arc rotates slowly
	var moon := Vector2(w * 0.76, h * 0.22)
	var moon_r := minf(w, h) * 0.115
	presentation._moon_arc.points = presentation._arc_points(moon, moon_r * 1.18, presentation._time * 0.035, presentation._time * 0.035 + TAU * 0.82, 96)

	# First tree sway (branches and subtle trunk unaffected except branch ends)
	var tx := w * 0.79
	var trunk_sway := sin(presentation._time * 0.18) * 3.0
	for i in presentation._tree_branches.get_child_count():
		var n := presentation._tree_branches.get_child(i) as Node2D
		if n == null: continue
		var start := Vector2(tx + (float(i) - 4.0) * 11.0, h * (0.43 + float(i % 3) * 0.035))
		var end := Vector2(tx + (float(i) - 4.0) * w * 0.105 + trunk_sway, h * (0.04 + float(i % 2) * 0.12))
		var main := n.get_node_or_null("Main") as Line2D
		var twig := n.get_node_or_null("Twig") as Line2D
		if main:
			main.points = PackedVector2Array([start, end])
		if twig:
			twig.visible = (i % 2 == 0)
			if twig.visible:
				twig.points = PackedVector2Array([end, end + Vector2(-16 if i < 4 else 16, -18)])
	for i in presentation._tree_roots.get_child_count():
		var n := presentation._tree_roots.get_child(i) as Node2D
		var line := n.get_node_or_null("Line") as Line2D if n else null
		if line == null: continue
		var root_x := tx + (float(i) - 2.5) * 26.0
		line.points = PackedVector2Array([Vector2(tx, h * 0.79), Vector2(root_x, h * (0.94 + float(i % 2) * 0.025))])

	# Magical seal pulse and spoke rotation
	var seal := Vector2(w * 0.69, h * 0.79)
	var pulse := 1.0 + 0.045 * sin(presentation._time * 1.6)
	presentation._outer_ring.points = presentation._arc_points(seal, h * 0.075 * pulse, 0.12, PI * 1.84, 72)
	presentation._inner_ring.points = presentation._arc_points(seal, h * 0.11 * pulse, 0.12, PI * 1.84, 72)
	for i in presentation._seal_spokes.get_child_count():
		var n := presentation._seal_spokes.get_child(i) as Node2D
		var line := n.get_node_or_null("Line") as Line2D if n else null
		if line == null: continue
		var a := TAU * float(i) / 8.0 + presentation._time * 0.025
		var p1 := seal + Vector2(cos(a), sin(a)) * h * 0.045
		var p2 := seal + Vector2(cos(a), sin(a)) * h * 0.11
		line.points = PackedVector2Array([p1, p2])

	# Foreground trees sway
	for i in presentation._foreground_trees.get_child_count():
		var n := presentation._foreground_trees.get_child(i) as Node2D
		if n == null or not n.visible: continue
		var x := float(n.get_meta("base_x", 0.0))
		var th := float(n.get_meta("height", h * 0.12))
		var cr := float(n.get_meta("canopy_r", 20.0))
		var sway := sin(presentation._time * 0.35 + float(i)) * 2.0
		var trunk := n.get_node_or_null("Trunk") as Line2D
		var canopy := n.get_node_or_null("Canopy") as Polygon2D
		if trunk:
			trunk.points = PackedVector2Array([Vector2(x, h), Vector2(x + sway, h - th)])
		if canopy:
			canopy.polygon = presentation._circle_poly(Vector2(x + sway, h - th), cr, 18)

	# Fog drift
	for i in presentation._fog_layer.get_child_count():
		var n := presentation._fog_layer.get_child(i) as Node2D
		var p := n.get_node_or_null("Puff") as Polygon2D if n else null
		if p == null: continue
		var fx := fposmod(float(i) * w * 0.27 + presentation._time * (7.0 + float(i) * 2.0), w + 220.0) - 110.0
		var fy := h * (0.73 + float(i % 3) * 0.045)
		var r := 70.0 + float(i % 2) * 25.0
		p.polygon = presentation._circle_poly(Vector2(fx, fy), r, 20)
		p.color = Color(0.60, 0.67, 0.79, 0.025)

	# Fireflies
	for i in presentation._fireflies_layer.get_child_count():
		var n := presentation._fireflies_layer.get_child(i) as Node2D
		var p := n.get_node_or_null("Glow") as Polygon2D if n else null
		if p == null: continue
		var fx := fposmod(float(i) * 103.0 + sin(presentation._time * 0.26 + float(i)) * 24.0, w)
		var fy := fposmod(float(i) * 59.0 - presentation._time * (4.0 + float(i % 4) * 1.6), h)
		var alpha := 0.18 + 0.17 * sin(presentation._time * 1.4 + float(i))
		var c := Color("#d6e7ae") if i % 3 != 0 else Color("#c7b2ef")
		var r := 1.5 + float(i % 2)
		p.polygon = presentation._circle_poly(Vector2(fx, fy), r, 10)
		p.color = Color(c.r, c.g, c.b, alpha)

	# Petals
	for i in presentation._petals_layer.get_child_count():
		var n := presentation._petals_layer.get_child(i) as Node2D
		var p := n.get_node_or_null("PetalShape") as Polygon2D if n else null
		if p == null: continue
		var px := fposmod(float(i) * 127.0 + sin(presentation._time * 0.32 + i) * 34.0, w)
		var py := fposmod(float(i) * 71.0 - presentation._time * (10.0 + float(i % 4) * 2.0), h)
		var petal := Vector2(4.0 + float(i % 3), 2.0 + float(i % 2))
		var rot := presentation._time * 0.3 + float(i)
		p.position = Vector2(px, py)
		p.rotation = rot
		p.polygon = PackedVector2Array([Vector2(-petal.x, 0), Vector2(0, -petal.y), Vector2(petal.x, 0), Vector2(0, petal.y)])
		p.color = Color(0.78, 0.13, 0.25, 0.48)

