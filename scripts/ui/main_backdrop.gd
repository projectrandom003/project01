class_name MainBackdrop
extends Control
## Animated moonlit Greenward scene for the title experience.
## Authored scene nodes provide the editable static composition; animation and
## environment movement remain in GDScript. Responsive layout is recomputed from
## current control size so the original composition/quality is preserved.

var _time: float = 0.0
var _gradient_texture: GradientTexture2D
var _built_static_for_size := Vector2.ZERO

var _sky_gradient: ColorRect
var _moon_layer: Node2D
var _halo_outer: Polygon2D
var _halo_inner: Polygon2D
var _blood_moon: Polygon2D
var _moon_shadow: Polygon2D
var _moon_arc: Line2D
var _distant_mountains: Polygon2D
var _city_layer: Node2D
var _village_layer: Node2D
var _first_tree: Node2D
var _tree_trunk: Polygon2D
var _tree_branches: Node2D
var _tree_roots: Node2D
var _stone_arch: Node2D
var _left_pillar: Line2D
var _right_pillar: Line2D
var _arch_curve: Line2D
var _left_break: Line2D
var _right_break: Line2D
var _left_base: ColorRect
var _right_base: ColorRect
var _stone_path: Node2D
var _path_surface: Polygon2D
var _path_lines: Node2D
var _magical_seal: Node2D
var _outer_ring: Line2D
var _inner_ring: Line2D
var _seal_spokes: Node2D
var _foreground_trees: Node2D
var _fog_layer: Node2D
var _fireflies_layer: Node2D
var _petals_layer: Node2D
var _overlay_draw: Node2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_scene_nodes()
	set_process(true)
	resized.connect(_on_resized)
	_setup_sky_gradient()
	_ensure_repeated_nodes()
	_rebuild_layout()
	_update_animation(0.0)

func _ensure_scene_nodes() -> void:
	# Prefer authored scene nodes; build minimal hierarchy when instantiated via script (.new()).
	_sky_gradient = _ensure_child_control(self, "SkyGradient", "ColorRect") as ColorRect
	_sky_gradient.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sky_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky_gradient.color = Color(0.0313726, 0.0313726, 0.0745098, 1)
	_moon_layer = _ensure_child_node2d(self, "MoonLayer")
	_halo_outer = _ensure_child_node2d(_moon_layer, "HaloOuter", "Polygon2D") as Polygon2D
	_halo_inner = _ensure_child_node2d(_moon_layer, "HaloInner", "Polygon2D") as Polygon2D
	_blood_moon = _ensure_child_node2d(_moon_layer, "BloodMoon", "Polygon2D") as Polygon2D
	_moon_shadow = _ensure_child_node2d(_moon_layer, "MoonShadow", "Polygon2D") as Polygon2D
	_moon_arc = _ensure_child_node2d(_moon_layer, "MoonArc", "Line2D") as Line2D
	_distant_mountains = _ensure_child_node2d(self, "DistantMountains", "Polygon2D") as Polygon2D
	_city_layer = _ensure_child_node2d(self, "CityLayer")
	_village_layer = _ensure_child_node2d(self, "VillageLayer")
	_first_tree = _ensure_child_node2d(self, "FirstTree")
	_tree_trunk = _ensure_child_node2d(_first_tree, "Trunk", "Polygon2D") as Polygon2D
	_tree_branches = _ensure_child_node2d(_first_tree, "Branches")
	_tree_roots = _ensure_child_node2d(_first_tree, "Roots")
	_stone_arch = _ensure_child_node2d(self, "StoneArch")
	_left_pillar = _ensure_child_node2d(_stone_arch, "LeftPillar", "Line2D") as Line2D
	_right_pillar = _ensure_child_node2d(_stone_arch, "RightPillar", "Line2D") as Line2D
	_arch_curve = _ensure_child_node2d(_stone_arch, "ArchCurve", "Line2D") as Line2D
	_left_break = _ensure_child_node2d(_stone_arch, "LeftBreak", "Line2D") as Line2D
	_right_break = _ensure_child_node2d(_stone_arch, "RightBreak", "Line2D") as Line2D
	_left_base = _ensure_child_control(_stone_arch, "LeftBase", "ColorRect") as ColorRect
	_right_base = _ensure_child_control(_stone_arch, "RightBase", "ColorRect") as ColorRect
	_stone_path = _ensure_child_node2d(self, "StonePath")
	_path_surface = _ensure_child_node2d(_stone_path, "PathSurface", "Polygon2D") as Polygon2D
	_path_lines = _ensure_child_node2d(_stone_path, "PathLines")
	_magical_seal = _ensure_child_node2d(self, "MagicalSeal")
	_outer_ring = _ensure_child_node2d(_magical_seal, "OuterRing", "Line2D") as Line2D
	_inner_ring = _ensure_child_node2d(_magical_seal, "InnerRing", "Line2D") as Line2D
	_seal_spokes = _ensure_child_node2d(_magical_seal, "Spokes")
	_foreground_trees = _ensure_child_node2d(self, "ForegroundTrees")
	var atmosphere := _ensure_child_node2d(self, "Atmosphere")
	_fog_layer = _ensure_child_node2d(atmosphere, "FogLayer")
	_fireflies_layer = _ensure_child_node2d(atmosphere, "FirefliesLayer")
	_petals_layer = _ensure_child_node2d(atmosphere, "PetalsLayer")
	_overlay_draw = _ensure_child_node2d(atmosphere, "OverlayDraw")
	var vignette := _ensure_child_control(self, "BottomVignette", "ColorRect") as ColorRect
	vignette.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	vignette.anchor_top = 0.93
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.color = Color(0.025, 0.018, 0.035, 0.54)

func _create_typed_node(type_name: String) -> Node:
	match type_name:
		"Node2D":
			return Node2D.new()
		"Polygon2D":
			return Polygon2D.new()
		"Line2D":
			return Line2D.new()
		"ColorRect":
			return ColorRect.new()
		"TextureRect":
			return TextureRect.new()
		_:
			return Node2D.new()

func _ensure_child_node2d(parent: Node, node_name: String, type_name: String = "Node2D") -> Node2D:
	var existing := parent.get_node_or_null(node_name)
	if existing == null:
		existing = _create_typed_node(type_name)
		existing.name = node_name
		parent.add_child(existing)
	return existing as Node2D

func _ensure_child_control(parent: Node, node_name: String, type_name: String = "Control") -> Control:
	var existing := parent.get_node_or_null(node_name)
	if existing == null:
		existing = _create_typed_node(type_name)
		existing.name = node_name
		parent.add_child(existing)
	return existing as Control

func _on_resized() -> void:
	_rebuild_layout()

func _process(delta: float) -> void:
	_time += delta
	_update_animation(delta)

func _setup_sky_gradient() -> void:
	# Authored node (ColorRect base) + gradient texture for the multi-stop sky.
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color("#080813"), Color("#21172a"), Color("#542b3b")])
	grad.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	_gradient_texture = GradientTexture2D.new()
	_gradient_texture.gradient = grad
	_gradient_texture.fill_from = Vector2(0, 0)
	_gradient_texture.fill_to = Vector2(0, 1)
	# Use a TextureRect overlay for the gradient while keeping SkyGradient as authored base.
	var tex_rect := get_node_or_null("SkyGradientTexture") as TextureRect
	if tex_rect == null:
		tex_rect = TextureRect.new()
		tex_rect.name = "SkyGradientTexture"
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex_rect.texture = _gradient_texture
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(tex_rect)
		if _sky_gradient != null and _sky_gradient.get_parent() == self:
			move_child(tex_rect, _sky_gradient.get_index() + 1)
	else:
		tex_rect.texture = _gradient_texture

func _ensure_repeated_nodes() -> void:
	_ensure_children(_city_layer, "CityBuilding", 17)
	_ensure_children(_village_layer, "VillageHouse", 7)
	_ensure_children(_tree_branches, "Branch", 9)
	_ensure_children(_tree_roots, "Root", 6)
	_ensure_children(_path_lines, "PathLine", 7)
	_ensure_children(_seal_spokes, "Spoke", 8)
	_ensure_children(_foreground_trees, "ForegroundTree", 12) # visible subset after gap
	_ensure_children(_fog_layer, "FogPuff", 5)
	_ensure_children(_fireflies_layer, "Firefly", 38)
	_ensure_children(_petals_layer, "Petal", 34)

func _ensure_children(parent: Node, base_name: String, count: int) -> void:
	if parent == null:
		return
	while parent.get_child_count() < count:
		var n := Node2D.new()
		n.name = "%s%d" % [base_name, parent.get_child_count()]
		parent.add_child(n)
	# Add specific child shapes for authored/editable composition.
	for i in parent.get_child_count():
		var n := parent.get_child(i)
		if not (n is Node2D):
			continue
		if parent == _city_layer and n.get_child_count() == 0:
			var body := ColorRect.new(); body.name = "Body"; body.mouse_filter = Control.MOUSE_FILTER_IGNORE; n.add_child(body)
			var roof := Polygon2D.new(); roof.name = "Roof"; n.add_child(roof)
			var win := ColorRect.new(); win.name = "Window"; win.mouse_filter = Control.MOUSE_FILTER_IGNORE; n.add_child(win)
		elif parent == _village_layer and n.get_child_count() == 0:
			var body := ColorRect.new(); body.name = "Body"; body.mouse_filter = Control.MOUSE_FILTER_IGNORE; n.add_child(body)
			var roof := Polygon2D.new(); roof.name = "Roof"; n.add_child(roof)
			var win := ColorRect.new(); win.name = "Window"; win.mouse_filter = Control.MOUSE_FILTER_IGNORE; n.add_child(win)
		elif parent == _tree_branches and n.get_child_count() == 0:
			var l := Line2D.new(); l.name = "Main"; n.add_child(l)
			var t := Line2D.new(); t.name = "Twig"; n.add_child(t)
		elif parent == _tree_roots and n.get_child_count() == 0:
			var l := Line2D.new(); l.name = "Line"; n.add_child(l)
		elif parent == _path_lines and n.get_child_count() == 0:
			var l := Line2D.new(); l.name = "Line"; n.add_child(l)
		elif parent == _seal_spokes and n.get_child_count() == 0:
			var l := Line2D.new(); l.name = "Line"; n.add_child(l)
		elif parent == _foreground_trees and n.get_child_count() == 0:
			var trunk := Line2D.new(); trunk.name = "Trunk"; n.add_child(trunk)
			var canopy := Polygon2D.new(); canopy.name = "Canopy"; n.add_child(canopy)
		elif parent == _fog_layer and n.get_child_count() == 0:
			var p := Polygon2D.new(); p.name = "Puff"; n.add_child(p)
		elif parent == _fireflies_layer and n.get_child_count() == 0:
			var p := Polygon2D.new(); p.name = "Glow"; n.add_child(p)
		elif parent == _petals_layer and n.get_child_count() == 0:
			var p := Polygon2D.new(); p.name = "PetalShape"; n.add_child(p)

func _rebuild_layout() -> void:
	var w := size.x
	var h := size.y
	if w <= 2.0 or h <= 2.0:
		return
	if _built_static_for_size == size and _city_layer.get_child_count() > 0:
		_update_animation(0.0)
		return
	_built_static_for_size = size

	# Moon (static base geometry; arc animated)
	var moon := Vector2(w * 0.76, h * 0.22)
	var moon_r := minf(w, h) * 0.115
	_halo_outer.polygon = _circle_poly(moon, moon_r * 2.0, 48)
	_halo_inner.polygon = _circle_poly(moon, moon_r * 1.45, 48)
	_blood_moon.polygon = _circle_poly(moon, moon_r, 48)
	_moon_shadow.polygon = _circle_poly(moon + Vector2(moon_r * 0.28, -moon_r * 0.08), moon_r * 0.88, 48)
	_moon_arc.width = 2.0
	_moon_arc.default_color = Color(1.0, 0.55, 0.58, 0.28)

	# Distant mountains
	_distant_mountains.polygon = PackedVector2Array([
		Vector2(0, h * 0.60), Vector2(w * 0.12, h * 0.46), Vector2(w * 0.25, h * 0.55),
		Vector2(w * 0.39, h * 0.43), Vector2(w * 0.56, h * 0.56), Vector2(w * 0.70, h * 0.45),
		Vector2(w * 0.88, h * 0.54), Vector2(w, h * 0.47), Vector2(w, h * 0.79), Vector2(0, h * 0.79)
	])

	# Ruined city silhouette
	var city_y := h * 0.70
	for i in _city_layer.get_child_count():
		var n := _city_layer.get_child(i) as Node2D
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
	for i in _village_layer.get_child_count():
		var n := _village_layer.get_child(i) as Node2D
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

	# First Tree trunk/branches/roots (branches/roots animated positions updated in _update_animation)
	var tx := w * 0.79
	_tree_trunk.polygon = PackedVector2Array([
		Vector2(tx - w * 0.075, h), Vector2(tx - w * 0.055, h * 0.62),
		Vector2(tx - w * 0.035, h * 0.37), Vector2(tx - w * 0.026, h * 0.18),
		Vector2(tx + w * 0.005, h * 0.14), Vector2(tx + w * 0.035, h * 0.30),
		Vector2(tx + w * 0.052, h * 0.62), Vector2(tx + w * 0.09, h)
	])
	for i in _tree_branches.get_child_count():
		var n := _tree_branches.get_child(i) as Node2D
		if n == null: continue
		var main := n.get_node_or_null("Main") as Line2D
		var twig := n.get_node_or_null("Twig") as Line2D
		if main: main.width = 10.0 - float(i % 3) * 1.5; main.default_color = Color("#111a1c")
		if twig: twig.width = 4.0; twig.default_color = Color("#111a1c")
	for i in _tree_roots.get_child_count():
		var n := _tree_roots.get_child(i) as Node2D
		var line := n.get_node_or_null("Line") as Line2D if n else null
		if line: line.width = 7.0; line.default_color = Color("#1b2924")

	# Stone arch
	var ax := w * 0.40
	var base_y := h * 0.76
	_left_pillar.points = PackedVector2Array([Vector2(ax - 76, base_y), Vector2(ax - 76, h * 0.48)])
	_right_pillar.points = PackedVector2Array([Vector2(ax + 76, base_y), Vector2(ax + 76, h * 0.51)])
	_arch_curve.points = _arc_points(Vector2(ax, h * 0.55), 76.0, PI, TAU * 0.97, 42)
	_left_break.points = PackedVector2Array([Vector2(ax - 76, h * 0.48), Vector2(ax - 91, h * 0.43)])
	_right_break.points = PackedVector2Array([Vector2(ax + 76, h * 0.51), Vector2(ax + 91, h * 0.47)])
	_left_base.position = Vector2(ax - 90, base_y - 4); _left_base.size = Vector2(28, 8)
	_right_base.position = Vector2(ax + 61, base_y - 4); _right_base.size = Vector2(28, 8)

	# Stone path
	_path_surface.polygon = PackedVector2Array([
		Vector2(w * 0.30, h), Vector2(w * 0.45, h * 0.73),
		Vector2(w * 0.62, h * 0.72), Vector2(w * 0.78, h)
	])
	for i in _path_lines.get_child_count():
		var n := _path_lines.get_child(i) as Node2D
		var line := n.get_node_or_null("Line") as Line2D if n else null
		if line == null: continue
		var y := h * (0.78 + float(i) * 0.034)
		var half := w * (0.055 + float(i) * 0.014)
		line.points = PackedVector2Array([Vector2(w * 0.55 - half, y), Vector2(w * 0.55 + half, y)])
		line.width = 1.2
		line.default_color = Color(0.55, 0.55, 0.68, 0.16)

	# Magical seal rings static base radii/colors; spokes animated
	_outer_ring.default_color = Color(0.62, 0.75, 0.88, 0.30)
	_inner_ring.default_color = Color(0.62, 0.75, 0.88, 0.30)
	for i in _seal_spokes.get_child_count():
		var n := _seal_spokes.get_child(i) as Node2D
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
		if vis_idx >= _foreground_trees.get_child_count():
			break
		var n := _foreground_trees.get_child(vis_idx) as Node2D
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
	for j in range(vis_idx, _foreground_trees.get_child_count()):
		var n := _foreground_trees.get_child(j)
		if n is CanvasItem: (n as CanvasItem).visible = false

	_update_animation(0.0)

func _update_animation(delta: float) -> void:
	var w := size.x
	var h := size.y
	if w <= 2.0 or h <= 2.0:
		return
	# Moon arc rotates slowly
	var moon := Vector2(w * 0.76, h * 0.22)
	var moon_r := minf(w, h) * 0.115
	_moon_arc.points = _arc_points(moon, moon_r * 1.18, _time * 0.035, _time * 0.035 + TAU * 0.82, 96)

	# First tree sway (branches and subtle trunk unaffected except branch ends)
	var tx := w * 0.79
	var trunk_sway := sin(_time * 0.18) * 3.0
	for i in _tree_branches.get_child_count():
		var n := _tree_branches.get_child(i) as Node2D
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
	for i in _tree_roots.get_child_count():
		var n := _tree_roots.get_child(i) as Node2D
		var line := n.get_node_or_null("Line") as Line2D if n else null
		if line == null: continue
		var root_x := tx + (float(i) - 2.5) * 26.0
		line.points = PackedVector2Array([Vector2(tx, h * 0.79), Vector2(root_x, h * (0.94 + float(i % 2) * 0.025))])

	# Magical seal pulse and spoke rotation
	var seal := Vector2(w * 0.69, h * 0.79)
	var pulse := 1.0 + 0.045 * sin(_time * 1.6)
	_outer_ring.points = _arc_points(seal, h * 0.075 * pulse, 0.12, PI * 1.84, 72)
	_inner_ring.points = _arc_points(seal, h * 0.11 * pulse, 0.12, PI * 1.84, 72)
	for i in _seal_spokes.get_child_count():
		var n := _seal_spokes.get_child(i) as Node2D
		var line := n.get_node_or_null("Line") as Line2D if n else null
		if line == null: continue
		var a := TAU * float(i) / 8.0 + _time * 0.025
		var p1 := seal + Vector2(cos(a), sin(a)) * h * 0.045
		var p2 := seal + Vector2(cos(a), sin(a)) * h * 0.11
		line.points = PackedVector2Array([p1, p2])

	# Foreground trees sway
	for i in _foreground_trees.get_child_count():
		var n := _foreground_trees.get_child(i) as Node2D
		if n == null or not n.visible: continue
		var x := float(n.get_meta("base_x", 0.0))
		var th := float(n.get_meta("height", h * 0.12))
		var cr := float(n.get_meta("canopy_r", 20.0))
		var sway := sin(_time * 0.35 + float(i)) * 2.0
		var trunk := n.get_node_or_null("Trunk") as Line2D
		var canopy := n.get_node_or_null("Canopy") as Polygon2D
		if trunk:
			trunk.points = PackedVector2Array([Vector2(x, h), Vector2(x + sway, h - th)])
		if canopy:
			canopy.polygon = _circle_poly(Vector2(x + sway, h - th), cr, 18)

	# Fog drift
	for i in _fog_layer.get_child_count():
		var n := _fog_layer.get_child(i) as Node2D
		var p := n.get_node_or_null("Puff") as Polygon2D if n else null
		if p == null: continue
		var fx := fposmod(float(i) * w * 0.27 + _time * (7.0 + float(i) * 2.0), w + 220.0) - 110.0
		var fy := h * (0.73 + float(i % 3) * 0.045)
		var r := 70.0 + float(i % 2) * 25.0
		p.polygon = _circle_poly(Vector2(fx, fy), r, 20)
		p.color = Color(0.60, 0.67, 0.79, 0.025)

	# Fireflies
	for i in _fireflies_layer.get_child_count():
		var n := _fireflies_layer.get_child(i) as Node2D
		var p := n.get_node_or_null("Glow") as Polygon2D if n else null
		if p == null: continue
		var fx := fposmod(float(i) * 103.0 + sin(_time * 0.26 + float(i)) * 24.0, w)
		var fy := fposmod(float(i) * 59.0 - _time * (4.0 + float(i % 4) * 1.6), h)
		var alpha := 0.18 + 0.17 * sin(_time * 1.4 + float(i))
		var c := Color("#d6e7ae") if i % 3 != 0 else Color("#c7b2ef")
		var r := 1.5 + float(i % 2)
		p.polygon = _circle_poly(Vector2(fx, fy), r, 10)
		p.color = Color(c.r, c.g, c.b, alpha)

	# Petals
	for i in _petals_layer.get_child_count():
		var n := _petals_layer.get_child(i) as Node2D
		var p := n.get_node_or_null("PetalShape") as Polygon2D if n else null
		if p == null: continue
		var px := fposmod(float(i) * 127.0 + sin(_time * 0.32 + i) * 34.0, w)
		var py := fposmod(float(i) * 71.0 - _time * (10.0 + float(i % 4) * 2.0), h)
		var petal := Vector2(4.0 + float(i % 3), 2.0 + float(i % 2))
		var rot := _time * 0.3 + float(i)
		p.position = Vector2(px, py)
		p.rotation = rot
		p.polygon = PackedVector2Array([Vector2(-petal.x, 0), Vector2(0, -petal.y), Vector2(petal.x, 0), Vector2(0, petal.y)])
		p.color = Color(0.78, 0.13, 0.25, 0.48)

func _circle_poly(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts

func _arc_points(center: Vector2, radius: float, a0: float, a1: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var a := lerpf(a0, a1, t)
		pts.append(center + Vector2(cos(a), sin(a)) * radius)
	return pts
