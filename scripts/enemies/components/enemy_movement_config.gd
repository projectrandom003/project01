class_name EnemyMovementConfig
extends Resource

@export var move_speed: float = 26.0
@export var roam_radius: float = 70.0
@export var roam_interval_min: float = 2.0
@export var roam_interval_max: float = 5.0
@export var chase_speed_multiplier: float = 1.0
@export var retreat_speed_multiplier: float = 1.0
@export var follow_enabled: bool = false
@export var navigation_enabled: bool = false
@export var position_correction_enabled: bool = true
@export var idle_enabled: bool = true
@export var patrol_enabled: bool = true
@export var chase_enabled: bool = true
@export var return_enabled: bool = true
