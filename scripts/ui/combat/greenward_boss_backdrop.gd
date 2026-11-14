extends Control
## Greenward boss arena authored from editable Polygon2D, Line2D and ColorRect
## nodes. Only atmospheric transforms and the heart pulse are animated.

var arena_id: String = "corrupted_treant"
var _clock := 0.0
var _arena: Node2D
var _mists: Array[ColorRect] = []
var _fireflies: Array[Polygon2D] = []
var _heart_glow: Polygon2D
var _heart_core: Polygon2D
var _heart_point: Polygon2D
var _stones: Array[Line2D] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena = $Arena
	_heart_glow = $Arena/GuardianTree/HeartGlow
	_heart_core = $Arena/GuardianTree/HeartCore
	_heart_point = $Arena/GuardianTree/HeartPoint
	for i in range(8):
		_mists.append(get_node("Atmosphere/Mist%d" % i))
	for i in range(22):
		_fireflies.append(get_node("Atmosphere/Firefly%d" % i))
	_stones = [$Arena/Clearing/StoneRing0, $Arena/Clearing/StoneRing1]
	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout()


func _process(delta: float) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_clock += delta
	var elder := arena_id == "elder_hollow"
	var glow := Color("#d4f59a") if elder else Color("#8ee07a")
	var pulse := 1.0 + 0.12 * sin(_clock * (1.7 if elder else 1.2))
	_heart_glow.scale = Vector2.ONE * (33.0 * pulse)
	_heart_core.scale = Vector2.ONE * (16.0 * pulse)
	_heart_point.scale = Vector2.ONE * 7.0
	_heart_glow.color = Color(glow.r, glow.g, glow.b, 0.10)
	_heart_core.color = Color(glow.r, glow.g, glow.b, 0.28)
	_heart_point.color = glow
	for i in range(_mists.size()):
		var mist := _mists[i]
		mist.position.y = 600.0 * (0.12 + float(i) * 0.075)
		var c := mist.color
		c.a = 0.035 + 0.02 * sin(_clock * 0.55 + float(i) * 0.7)
		mist.color = c
	for i in range(_fireflies.size()):
		var x := fposmod(float(i) * 91.0 + sin(_clock * 0.4 + float(i)) * 20.0, 1000.0)
		var y := fposmod(float(i) * 47.0 - _clock * (5.0 + float(i % 3) * 2.0), 600.0)
		var mote := _fireflies[i]
		mote.position = Vector2(x, y)
		var c := mote.color
		c.a = 0.35 + 0.15 * sin(_clock + float(i))
		mote.color = c


func _layout() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_arena.scale = size / Vector2(1000.0, 600.0)
	$Atmosphere.scale = size / Vector2(1000.0, 600.0)
	$Arena/GuardianTree/HeartGlow.position = Vector2(750, 234)
	$Arena/GuardianTree/HeartCore.position = Vector2(750, 234)
	$Arena/GuardianTree/HeartPoint.position = Vector2(750, 234)
	$Arena/Clearing.position = Vector2(500, 498)
	for i in range(_stones.size()):
		_stones[i].scale = Vector2.ONE * (72.0 + float(i) * 30.0)
