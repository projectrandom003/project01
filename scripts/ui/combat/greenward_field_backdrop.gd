extends Control
## Greenward field combat background. Static art and ambient layers are authored
## in the scene; this script only animates the fog and firefly node transforms.

var _time := 0.0
var _mist_nodes: Array[ColorRect] = []
var _fireflies: Array[Polygon2D] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mist_nodes = [
		$Mist0, $Mist1, $Mist2, $Mist3
	]
	_fireflies = [
		$Fireflies/Firefly0, $Fireflies/Firefly1, $Fireflies/Firefly2,
		$Fireflies/Firefly3, $Fireflies/Firefly4, $Fireflies/Firefly5,
		$Fireflies/Firefly6, $Fireflies/Firefly7, $Fireflies/Firefly8,
		$Fireflies/Firefly9, $Fireflies/Firefly10, $Fireflies/Firefly11,
		$Fireflies/Firefly12, $Fireflies/Firefly13, $Fireflies/Firefly14,
		$Fireflies/Firefly15, $Fireflies/Firefly16, $Fireflies/Firefly17,
		$Fireflies/Firefly18, $Fireflies/Firefly19
	]
	_layout_ambient()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout_ambient()


func _process(delta: float) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_time += delta
	for i in range(_mist_nodes.size()):
		var mist := _mist_nodes[i]
		mist.position.x = sin(_time * 0.22 + float(i)) * 22.0 - 90.0
		var mist_color := mist.color
		mist_color.a = 0.028 + 0.009 * sin(_time * 0.55 + float(i))
		mist.color = mist_color
	for i in range(_fireflies.size()):
		var firefly := _fireflies[i]
		var x := fposmod(float(i) * 97.0 + sin(_time * 0.4 + float(i)) * 26.0, size.x)
		var y := fposmod(float(i) * 51.0 - _time * (4.0 + float(i % 3)), size.y * 0.78)
		firefly.position = Vector2(x, y)
		var flicker := 0.28 + 0.16 * sin(_time + float(i))
		var firefly_color := firefly.color
		firefly_color.a = flicker
		firefly.color = firefly_color
		firefly.scale = Vector2.ONE * (1.5 if i % 3 else 2.0)


func _layout_ambient() -> void:
	if _mist_nodes.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return
	for i in range(_mist_nodes.size()):
		var mist := _mist_nodes[i]
		mist.position = Vector2(-90.0, size.y * (0.66 + float(i) * 0.065))
		mist.size = Vector2(size.x + 180.0, size.y * 0.035)
