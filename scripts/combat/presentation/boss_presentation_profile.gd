extends Resource
## Visual-only configuration for a boss encounter. Combat rules remain in CombatEngine.

@export_enum("roots", "bloom") var visual_style: String = "roots"
@export var telegraph_color: Color = Color(0.62, 0.88, 0.58, 1.0)
@export_range(0.5, 2.0, 0.05) var telegraph_scale: float = 1.0
@export var impact_color: Color = Color(0.82, 0.96, 0.72, 1.0)
@export_range(0.5, 2.0, 0.05) var impact_scale: float = 1.0
@export var phase_color: Color = Color(0.76, 0.94, 0.66, 1.0)
@export var phase_title: String = "THE ENCOUNTER CHANGES"
