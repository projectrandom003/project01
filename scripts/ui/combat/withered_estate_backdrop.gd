extends Control
## Static conservatory artwork is a TextureRect. Light shafts, fog ribbons,
## ground sigil and corruption motes are editable scene nodes animated here.

var _clock := 0.0
var _fog_phase := 0.0
var _beams: Array[Polygon2D] = []
var _fog: Array[Polygon2D] = []
var _rings: Array[Line2D] = []
var _motes: Array[Polygon2D] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beams = [$LightShafts/Beam0, $LightShafts/Beam1, $LightShafts/Beam2]
	_fog = [$FogLayers/Fog0, $FogLayers/Fog1, $FogLayers/Fog2]
	_rings = [$GroundSigil/Ring0, $GroundSigil/Ring1, $GroundSigil/Ring2]
	_motes = [
		$CorruptionMotes/Mote0, $CorruptionMotes/Mote1, $CorruptionMotes/Mote2,
		$CorruptionMotes/Mote3, $CorruptionMotes/Mote4, $CorruptionMotes/Mote5,
		$CorruptionMotes/Mote6, $CorruptionMotes/Mote7, $CorruptionMotes/Mote8,
		$CorruptionMotes/Mote9, $CorruptionMotes/Mote10, $CorruptionMotes/Mote11,
		$CorruptionMotes/Mote12, $CorruptionMotes/Mote13, $CorruptionMotes/Mote14,
		$CorruptionMotes/Mote15, $CorruptionMotes/Mote16, $CorruptionMotes/Mote17,
		$CorruptionMotes/Mote18, $CorruptionMotes/Mote19, $CorruptionMotes/Mote20,
		$CorruptionMotes/Mote21, $CorruptionMotes/Mote22, $CorruptionMotes/Mote23
	]
	_layout_layers()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout_layers()


func _process(delta: float) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_clock += delta
	_fog_phase = fposmod(_fog_phase + delta * 0.018, 1.0)
	var beam_alpha := 0.045 + 0.018 * sin(_clock * 0.42)
	for i in range(_beams.size()):
		var beam := _beams[i]
		beam.position.x = size.x * (0.22 + float(i) * 0.28) + sin(_clock * 0.11 + float(i)) * size.x * 0.018
		beam.scale = Vector2(size.x * (0.045 if i == 1 else 0.032), size.y)
		var beam_color := beam.color
		beam_color.a = beam_alpha
		beam.color = beam_color
	for i in range(_fog.size()):
		var layer := _fog[i]
		var drift := fposmod(_fog_phase * (0.65 + float(i) * 0.22) + float(i) * 0.31, 1.0)
		layer.position = Vector2(drift * size.x, size.y * (0.60 + float(i) * 0.105))
		layer.scale = Vector2(size.x * 0.44, size.y * 0.07)
		var fog_color := layer.color
		fog_color.a = 0.035 + 0.012 * sin(_clock * 0.55 + float(i))
		layer.color = fog_color
	var center := Vector2(size.x * 0.5, size.y * 0.79)
	var pulse := 1.0 + 0.035 * sin(_clock * 1.7)
	$GroundSigil.position = center
	for i in range(_rings.size()):
		_rings[i].scale = Vector2.ONE * size.y * (0.105 + float(i) * 0.04) * pulse
		_rings[i].rotation = _clock * 0.018
	for i in range(_motes.size()):
		var phase := float(i) * 1.73
		var x := fposmod(float(i) * 137.0 + sin(_clock * 0.35 + phase) * 24.0, size.x)
		var y := fposmod(float(i) * 71.0 - _clock * (5.0 + float(i % 4) * 1.7), size.y)
		_motes[i].position = Vector2(x, y)
		var flicker := 0.22 + (0.55 + 0.45 * sin(_clock * 2.2 + phase)) * 0.28
		var mote_color := _motes[i].color
		mote_color.a = flicker
		_motes[i].color = mote_color
		_motes[i].scale = Vector2.ONE * (1.2 + float(i % 3) * 0.65)


func _layout_layers() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	for i in range(_beams.size()):
		_beams[i].position.y = 0.0
	for i in range(_fog.size()):
		_fog[i].position.y = size.y * (0.60 + float(i) * 0.105)
