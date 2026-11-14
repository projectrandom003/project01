class_name SummonSigil
extends Control
## Editor-authored summoning glyph. Scripts animate reusable scene nodes only.

var elapsed := 0.0
var glow := Color("#b58cff")

@onready var glyph: Node2D = $Glyph
@onready var rings: Array[Line2D] = [
	$Glyph/Ring0, $Glyph/Ring1, $Glyph/Ring2
]
@onready var spokes: Array[Line2D] = [
	$Glyph/Spoke0, $Glyph/Spoke1, $Glyph/Spoke2, $Glyph/Spoke3,
	$Glyph/Spoke4, $Glyph/Spoke5, $Glyph/Spoke6, $Glyph/Spoke7
]
@onready var sparks: Array[Polygon2D] = [
	$Glyph/Spark0, $Glyph/Spark1, $Glyph/Spark2, $Glyph/Spark3,
	$Glyph/Spark4, $Glyph/Spark5, $Glyph/Spark6, $Glyph/Spark7
]
@onready var core: Polygon2D = $Glyph/Core


func _process(delta: float) -> void:
	elapsed += delta
	var center := size * 0.5
	glyph.position = center
	var radius := minf(size.x, size.y) * (0.20 + 0.12 * clampf(elapsed / 1.8, 0.0, 1.0))
	var pulse := 1.0 + 0.045 * sin(elapsed * 5.0)
	for i in range(rings.size()):
		var ring := rings[i]
		var direction := 0.18 if i % 2 == 0 else -0.14
		var ring_radius := radius * (0.66 + float(i) * 0.22) * pulse
		ring.scale = Vector2.ONE * ring_radius
		ring.rotation = elapsed * direction
		ring.default_color = Color(glow.r, glow.g, glow.b, 0.42 - float(i) * 0.08)
	for i in range(spokes.size()):
		var angle := TAU * float(i) / 8.0 + elapsed * 0.22
		spokes[i].position = Vector2.ZERO
		spokes[i].rotation = angle
		spokes[i].scale = Vector2(radius, radius)
		spokes[i].default_color = Color(glow.r, glow.g, glow.b, 0.45)
		var outer := Vector2(cos(angle), sin(angle)) * radius * 1.08
		sparks[i].position = outer
		var spark_size := 3.0 + 1.5 * sin(elapsed * 4.0 + float(i))
		sparks[i].scale = Vector2.ONE * spark_size
	core.scale = Vector2.ONE * (12.0 + 5.0 * sin(elapsed * 6.0))
	core.color = Color(glow.r, glow.g, glow.b, 0.75)
