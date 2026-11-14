class_name LaunchForestBackdrop
extends Control
## Scene-authored launch forest illustration and ambient effects.

const ART_PATH := "res://assets/ui/backgrounds/launch_forest_background.svg"
@onready var effects: Node2D = $Effects
@onready var shafts: Array[Polygon2D] = [
	$Effects/Moonshaft0, $Effects/Moonshaft1, $Effects/Moonshaft2, $Effects/Moonshaft3
]
@onready var mists: Array[Polygon2D] = [
	$Effects/Mist0, $Effects/Mist1, $Effects/Mist2, $Effects/Mist3
]
@onready var seal: Line2D = $Effects/GladeSeal
var _time := 0.0
var _particles: Array[Vector3] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := load(ART_PATH) as Texture2D
	if art != null:
		$Background.texture = art
	for i in range(46):
		var x := fposmod(float(i) * 173.0 + 29.0, 1920.0)
		var y := fposmod(float(i) * 97.0 + 41.0, 1080.0)
		_particles.append(Vector3(x, y, 0.8 + float(i % 5) * 0.45))
	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout()


func _layout() -> void:
	effects.scale = size / Vector2(1920.0, 1080.0)
	effects.position = Vector2.ZERO


func _process(delta: float) -> void:
	_time += delta
	for i in range(shafts.size()):
		var drift := sin(_time * 0.16 + float(i) * 1.7) * 48.0
		shafts[i].position.x = drift
		var alpha := 0.025 + 0.012 * sin(_time * 0.7 + float(i))
		var color := Color(0.72, 0.88, 0.76, alpha)
		shafts[i].color = color
	for i in range(mists.size()):
		var mist := mists[i]
		mist.position.x = fposmod(_time * (8.0 + float(i) * 3.0) + float(i) * 1920.0 * 0.31, 2180.0) - 130.0
		mist.position.y = sin(_time * 0.22 + float(i)) * 9.0
	for i in range(_particles.size()):
		var p: Vector3 = _particles[i]
		var x := fposmod(p.x + sin(_time * 0.24 + float(i)) * 22.0, 1920.0)
		var y := fposmod(p.y - _time * (5.0 + p.z * 2.0), 1080.0)
		var pulse := 0.45 + 0.55 * sin(_time * (1.1 + p.z * 0.12) + float(i) * 0.8)
		var node := effects.get_node("Firefly%d" % i) as Polygon2D
		node.position = Vector2(x, y)
		node.scale = Vector2.ONE * (2.0 + p.z * 0.65)
		var color := Color("#d9efb6") if i % 3 != 0 else Color("#c4dfff")
		node.color = Color(color.r, color.g, color.b, 0.12 + pulse * 0.34)
		if i % 4 == 0:
			var petal := effects.get_node("Petal%d" % i) as Line2D
			petal.position = Vector2(x, y)
			petal.rotation = sin(_time * 1.6 + i * 2.0) * 0.8
	var seal_pulse := 1.0 + sin(_time * 1.1) * 0.055
	seal.scale = Vector2.ONE * seal_pulse
	seal.rotation = _time * 0.10
