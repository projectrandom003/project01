class_name DayNight
extends CanvasModulate
## Slow day/night cycle driven by a single keyframed colour ramp. Emits phase
## changes so ambient particles, fog, lighting and (later) NPC schedules can
## react.
##
## Phase 3: the tint COLOURS are sourced from GreenwardStyle.phase(name).tint
## (the single source of truth) rather than inline literals, but the phase names,
## keyframe times, smooth interpolation and every public API are unchanged. The
## `color` key in PHASES is retained only as a defensive legacy fallback.

signal phase_changed(phase_name: String)

const PHASES := [
	{ "at": 0.00, "name": "Midnight", "color": Color(0.34, 0.40, 0.62) },
	{ "at": 0.22, "name": "Dawn", "color": Color(0.82, 0.70, 0.72) },
	{ "at": 0.32, "name": "Morning", "color": Color(1.00, 0.97, 0.91) },
	{ "at": 0.50, "name": "Noon", "color": Color(1.00, 1.00, 1.00) },
	{ "at": 0.68, "name": "Afternoon", "color": Color(1.00, 0.95, 0.86) },
	{ "at": 0.78, "name": "Dusk", "color": Color(0.94, 0.68, 0.58) },
	{ "at": 0.88, "name": "Nightfall", "color": Color(0.50, 0.48, 0.70) },
	{ "at": 1.00, "name": "Midnight", "color": Color(0.34, 0.40, 0.62) },
]

@export var day_length_seconds: float = 480.0
@export var start_time: float = 0.34

var time_of_day: float = 0.34
var _phase_name: String = ""


func _ready() -> void:
	time_of_day = start_time
	_apply()


func _process(delta: float) -> void:
	time_of_day = fmod(time_of_day + delta / maxf(1.0, day_length_seconds), 1.0)
	_apply()


func _apply() -> void:
	color = sample_color(time_of_day)
	var phase := phase_at(time_of_day)
	if phase != _phase_name:
		_phase_name = phase
		phase_changed.emit(phase)


func is_night() -> bool:
	return time_of_day < 0.24 or time_of_day > 0.82


static func sample_color(time: float) -> Color:
	var t_time := clampf(time, 0.0, 1.0)
	for index in PHASES.size() - 1:
		var a: Dictionary = PHASES[index]
		var b: Dictionary = PHASES[index + 1]
		if t_time >= float(a.at) and t_time <= float(b.at):
			var span := maxf(0.0001, float(b.at) - float(a.at))
			var t := (t_time - float(a.at)) / span
			var color_a := _phase_tint(str(a.get("name", "Day")))
			var color_b := _phase_tint(str(b.get("name", "Day")))
			return color_a.lerp(color_b, t)
	return _phase_tint(str(PHASES[0].get("name", "Day")))


## Resolve a phase's tint from GreenwardStyle.phase(name).tint (authoritative),
## falling back to the legacy inline PHASES color only if that ever fails. Kept
## headless-safe: GreenwardStyle.phase() is pure data, no nodes / SceneTree.
static func _phase_tint(name: String) -> Color:
	var data := GreenwardStyle.phase(name)
	var tint: Variant = data.get("tint", null)
	if tint is Color:
		return tint
	for entry in PHASES:
		if str(entry.get("name", "")) == name:
			var c: Variant = entry.get("color", Color.WHITE)
			if c is Color:
				return c
	return Color.WHITE


static func phase_at(time: float) -> String:
	var phase_name := str(PHASES[0].get("name", "Day"))
	for entry in PHASES:
		if time >= float(entry.get("at", 0.0)):
			phase_name = str(entry.get("name", phase_name))
	return phase_name
