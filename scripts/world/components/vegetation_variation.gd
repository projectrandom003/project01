class_name VegetationVariation
extends Resource
## Configurable variation data for reusable vegetation scenes/components.

@export var kind: String = "tree"
@export var variant: int = 0
@export_range(0.1, 4.0, 0.01) var scale: float = 1.0
@export var flip_h: bool = false
@export var tint: Color = Color.WHITE
@export var wind_enabled: bool = true
@export_range(0.0, 0.2, 0.005) var wind_sway_amount: float = 0.03
@export var shadow_enabled: bool = true
@export var seasonal_offset: float = 0.0
@export var metadata: Dictionary = {}
