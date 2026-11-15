class_name EnemyDetectionConfig
extends Resource

@export var detection_enabled: bool = false
@export var detection_radius: float = 96.0
@export var aggro_radius: float = 96.0
@export var lose_aggro_radius: float = 140.0
@export var line_of_sight_required: bool = false
@export var engage_on_detection: bool = false
@export var return_home_on_aggro_loss: bool = true
