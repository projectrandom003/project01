class_name MainBackdropPresentationComponent
extends Node
## Binds the authored title-backdrop composition and owns its responsive geometry and ambient animation.

var backdrop: MainBackdrop
var layout_component: MainBackdropLayoutComponent
var animation_component: MainBackdropAnimationComponent

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

func bind(owner_backdrop: MainBackdrop) -> void:
	backdrop = owner_backdrop


func build() -> void:
	if backdrop == null:
		return
	if not _ensure_scene_nodes():
		return
	layout_component = get_node_or_null("Layout") as MainBackdropLayoutComponent
	animation_component = get_node_or_null("Animation") as MainBackdropAnimationComponent
	if layout_component == null or animation_component == null:
		push_error("MainBackdropPresentationComponent requires authored Layout and Animation child components.")
		return
	layout_component.bind(self)
	animation_component.bind(self)
	set_process(true)
	backdrop.resized.connect(_on_resized)
	_setup_sky_gradient()
	_ensure_repeated_nodes()
	_rebuild_layout()
	_update_animation(0.0)

func _ensure_scene_nodes() -> bool:
	_sky_gradient = backdrop.get_node_or_null("SkyGradient") as ColorRect
	_moon_layer = backdrop.get_node_or_null("MoonLayer") as Node2D
	_halo_outer = backdrop.get_node_or_null("MoonLayer/HaloOuter") as Polygon2D
	_halo_inner = backdrop.get_node_or_null("MoonLayer/HaloInner") as Polygon2D
	_blood_moon = backdrop.get_node_or_null("MoonLayer/BloodMoon") as Polygon2D
	_moon_shadow = backdrop.get_node_or_null("MoonLayer/MoonShadow") as Polygon2D
	_moon_arc = backdrop.get_node_or_null("MoonLayer/MoonArc") as Line2D
	_distant_mountains = backdrop.get_node_or_null("DistantMountains") as Polygon2D
	_city_layer = backdrop.get_node_or_null("CityLayer") as Node2D
	_village_layer = backdrop.get_node_or_null("VillageLayer") as Node2D
	_first_tree = backdrop.get_node_or_null("FirstTree") as Node2D
	_tree_trunk = backdrop.get_node_or_null("FirstTree/Trunk") as Polygon2D
	_tree_branches = backdrop.get_node_or_null("FirstTree/Branches") as Node2D
	_tree_roots = backdrop.get_node_or_null("FirstTree/Roots") as Node2D
	_stone_arch = backdrop.get_node_or_null("StoneArch") as Node2D
	_left_pillar = backdrop.get_node_or_null("StoneArch/LeftPillar") as Line2D
	_right_pillar = backdrop.get_node_or_null("StoneArch/RightPillar") as Line2D
	_arch_curve = backdrop.get_node_or_null("StoneArch/ArchCurve") as Line2D
	_left_break = backdrop.get_node_or_null("StoneArch/LeftBreak") as Line2D
	_right_break = backdrop.get_node_or_null("StoneArch/RightBreak") as Line2D
	_left_base = backdrop.get_node_or_null("StoneArch/LeftBase") as ColorRect
	_right_base = backdrop.get_node_or_null("StoneArch/RightBase") as ColorRect
	_stone_path = backdrop.get_node_or_null("StonePath") as Node2D
	_path_surface = backdrop.get_node_or_null("StonePath/PathSurface") as Polygon2D
	_path_lines = backdrop.get_node_or_null("StonePath/PathLines") as Node2D
	_magical_seal = backdrop.get_node_or_null("MagicalSeal") as Node2D
	_outer_ring = backdrop.get_node_or_null("MagicalSeal/OuterRing") as Line2D
	_inner_ring = backdrop.get_node_or_null("MagicalSeal/InnerRing") as Line2D
	_seal_spokes = backdrop.get_node_or_null("MagicalSeal/Spokes") as Node2D
	_foreground_trees = backdrop.get_node_or_null("ForegroundTrees") as Node2D
	_fog_layer = backdrop.get_node_or_null("Atmosphere/FogLayer") as Node2D
	_fireflies_layer = backdrop.get_node_or_null("Atmosphere/FirefliesLayer") as Node2D
	_petals_layer = backdrop.get_node_or_null("Atmosphere/PetalsLayer") as Node2D
	_overlay_draw = backdrop.get_node_or_null("Atmosphere/OverlayDraw") as Node2D
	var required: Array[Node] = [
		_sky_gradient, _moon_layer, _halo_outer, _halo_inner, _blood_moon, _moon_shadow,
		_moon_arc, _distant_mountains, _city_layer, _village_layer, _first_tree, _tree_trunk,
		_tree_branches, _tree_roots, _stone_arch, _left_pillar, _right_pillar, _arch_curve,
		_left_break, _right_break, _left_base, _right_base, _stone_path, _path_surface,
		_path_lines, _magical_seal, _outer_ring, _inner_ring, _seal_spokes, _foreground_trees,
		_fog_layer, _fireflies_layer, _petals_layer, _overlay_draw
	]
	for node in required:
		if node == null:
			push_error("MainBackdrop is missing a required authored presentation node.")
			return false
	var vignette := backdrop.get_node_or_null("BottomVignette") as ColorRect
	var gradient_overlay := backdrop.get_node_or_null("SkyGradientTexture") as TextureRect
	if vignette == null or gradient_overlay == null:
		push_error("MainBackdrop is missing BottomVignette or SkyGradientTexture.")
		return false
	_sky_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return true

func _on_resized() -> void:
	_rebuild_layout()

func _process(delta: float) -> void:
	_time += delta
	_update_animation(delta)

func _setup_sky_gradient() -> void:
	var tex_rect := backdrop.get_node_or_null("SkyGradientTexture") as TextureRect
	if tex_rect == null:
		push_error("MainBackdrop requires authored SkyGradientTexture.")
		return
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color("#080813"), Color("#21172a"), Color("#542b3b")])
	grad.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	_gradient_texture = GradientTexture2D.new()
	_gradient_texture.gradient = grad
	_gradient_texture.fill_from = Vector2(0, 0)
	_gradient_texture.fill_to = Vector2(0, 1)
	tex_rect.texture = _gradient_texture
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

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
	if layout_component != null:
		layout_component.rebuild()


func _update_animation(delta: float) -> void:
	if animation_component != null:
		animation_component.update_animation(delta)


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
