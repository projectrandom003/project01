class_name FeaturedSummonStage
extends Control
## Editor-authored ritual frame. Runtime logic animates scene nodes only.

var accent := Color("#b58cff")
var elapsed := 0.0

@onready var ritual: Node2D = $Ritual
@onready var aura: Polygon2D = $Ritual/Aura
@onready var rings: Array[Line2D] = [
	$Ritual/Ring0, $Ritual/Ring1, $Ritual/Ring2, $Ritual/Ring3
]
@onready var rays: Array[Line2D] = [
	$Ritual/Ray0, $Ritual/Ray1, $Ritual/Ray2, $Ritual/Ray3,
	$Ritual/Ray4, $Ritual/Ray5, $Ritual/Ray6, $Ritual/Ray7,
	$Ritual/Ray8, $Ritual/Ray9, $Ritual/Ray10, $Ritual/Ray11
]
@onready var gems: Array[Polygon2D] = [
	$Ritual/Gem0, $Ritual/Gem1, $Ritual/Gem2, $Ritual/Gem3,
	$Ritual/Gem4, $Ritual/Gem5, $Ritual/Gem6, $Ritual/Gem7,
	$Ritual/Gem8, $Ritual/Gem9, $Ritual/Gem10, $Ritual/Gem11
]
@onready var dais: Node2D = $Dais
@onready var dais_fill: Polygon2D = $Dais/Fill
@onready var dais_edge: Line2D = $Dais/Edge


func _process(delta: float) -> void:
	elapsed += delta
	var center := size * Vector2(0.5, 0.53)
	var radius := minf(size.x * 0.43, size.y * 0.46)
	var pulse := 1.0 + sin(elapsed * 1.35) * 0.018
	ritual.position = center
	aura.scale = Vector2.ONE * radius * 0.94
	aura.color = Color(accent.r, accent.g, accent.b, 0.035)
	for i in range(rings.size()):
		var ring_radius := radius * (0.43 + float(i) * 0.145) * pulse
		rings[i].scale = Vector2.ONE * ring_radius
		rings[i].rotation = elapsed * (0.035 if i % 2 == 0 else -0.025)
		rings[i].default_color = Color(accent.r, accent.g, accent.b, 0.30 - float(i) * 0.045)
	for i in range(rays.size()):
		var angle := TAU * float(i) / 12.0 + elapsed * 0.025
		rays[i].rotation = angle
		rays[i].scale = Vector2(radius, radius)
		rays[i].default_color = Color(accent.r, accent.g, accent.b, 0.34)
		gems[i].position = Vector2.RIGHT.rotated(angle) * radius * 0.72
		gems[i].scale = Vector2.ONE * (3.0 if i % 3 == 0 else 2.0)
	dais.position = Vector2(size.x * 0.5, size.y * 0.89)
	dais.scale = Vector2(size.x * 0.34, 18.0)
	dais_fill.color = Color(0.13, 0.12, 0.22, 0.88)
	dais_edge.default_color = Color(accent.r, accent.g, accent.b, 0.52)
