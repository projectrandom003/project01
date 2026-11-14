extends Control
## Scene-authored ambient beam, summoning circles, motes and petals.

@onready var beam: ColorRect = $Beam
@onready var rings: Node2D = $Rings
@onready var motes_layer: Node2D = $Motes
@onready var petals_layer: Node2D = $Petals
var elapsed := 0.0
var _mote_positions: Array[Vector3] = []
var _petal_positions: Array[Vector3] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 712903
	for i in range(motes_layer.get_child_count()):
		_mote_positions.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.35, 1.0)))
	for i in range(petals_layer.get_child_count()):
		_petal_positions.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.5, 1.3)))
	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout()


func _layout() -> void:
	beam.position = Vector2(size.x * 0.445, size.y * 0.20)
	beam.size = Vector2(size.x * 0.11, size.y * 0.62)
	beam.color.a = 0.035
	rings.position = Vector2(size.x * 0.5, size.y * 0.72)
	for i in range(rings.get_child_count()):
		var ring := rings.get_child(i) as Line2D
		var radius := minf(size.x * 0.27, size.y * 0.34) * (0.72 + i * 0.15)
		ring.scale = Vector2.ONE * radius
		ring.default_color = Color(0.78, 0.56, 1.0, 0.08)
	motes_layer.position = Vector2.ZERO
	petals_layer.position = Vector2.ZERO


func _process(delta: float) -> void:
	elapsed += delta
	var pulse := 0.5 + 0.5 * sin(elapsed * 1.35)
	beam.color.a = 0.035 + pulse * 0.065
	for i in range(rings.get_child_count()):
		var ring := rings.get_child(i) as Line2D
		ring.rotation = elapsed * (0.12 if i % 2 == 0 else -0.09)
		ring.default_color.a = 0.08 + pulse * 0.08
	for i in range(_mote_positions.size()):
		var p := _mote_positions[i]
		p.y -= delta * (10.0 + p.z * 17.0) / maxf(size.y, 1.0)
		p.x += sin(elapsed * 0.7 + i * 1.7) * delta * 9.0 / maxf(size.x, 1.0)
		if p.y < -0.02:
			p.y = 1.01
		_mote_positions[i] = p
		var node := motes_layer.get_child(i) as Polygon2D
		node.position = Vector2(p.x * size.x, p.y * size.y)
		node.scale = Vector2.ONE * (1.0 + p.z * 1.5)
		var c := Color(0.86, 0.72, 1.0, 0.18 + 0.35 * (0.5 + 0.5 * sin(elapsed * 2.2 + i)))
		node.color = c
	for i in range(_petal_positions.size()):
		var p := _petal_positions[i]
		p.y -= delta * (16.0 + p.z * 22.0) / maxf(size.y, 1.0)
		p.x += sin(elapsed * 1.4 + i) * delta * 28.0 / maxf(size.x, 1.0)
		if p.y < -0.03:
			p.y = 1.03
			p.x = fposmod(p.x + 1.0, 1.0)
		_petal_positions[i] = p
		var node := petals_layer.get_child(i) as Polygon2D
		node.position = Vector2(p.x * size.x, p.y * size.y)
		node.rotation = sin(elapsed * 1.6 + i * 2.0) * 0.8
