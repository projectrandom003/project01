class_name VillageLightSource
extends Node2D
## Reusable localized village light (node-first). Wraps a PointLight2D and
## optional visible source; tuned for cohesive warm/cool lighting.

signal light_toggled(enabled: bool)

@export var base_energy: float = 0.9
@export var light_color: Color = Color("#ffcf6a")
@export var texture_scale: float = 1.8
@export var night_only: bool = false
@export var enabled: bool = true:
	set(value):
		enabled = value
		_apply()
		light_toggled.emit(enabled)

@onready var _light: PointLight2D = $PointLight2D
@onready var _source: Node2D = get_node_or_null("Source")

func _ready() -> void:
	_apply()

func _apply() -> void:
	if _light == null:
		return
	if _light.texture == null:
		# Warm/cool PointLight2D needs a texture to illuminate nearby surfaces.
		_light.texture = ProceduralArt.soft_glow(Color.WHITE, 128)
	_light.color = light_color
	_light.texture_scale = texture_scale
	_light.energy = base_energy if enabled else 0.0
	_light.enabled = enabled
	if _source != null:
		_source.visible = enabled

func set_phase_energy(phase_multiplier: float, is_night: bool) -> void:
	var active := enabled and (is_night or not night_only)
	if _light != null:
		_light.enabled = active
		_light.energy = base_energy * phase_multiplier if active else 0.0
	if _source != null:
		_source.visible = active
