class_name WorldAtmosphereRefreshComponent
extends Node
## Owns the low-frequency atmosphere refresh cadence for the active world.

const REFRESH_INTERVAL := 0.25

var world: GreenwardWorld
var _refresh_accumulator := 0.0


func configure(owner_world: GreenwardWorld) -> void:
	world = owner_world


func tick(delta: float) -> void:
	if world == null:
		return
	_refresh_accumulator += delta
	if _refresh_accumulator < REFRESH_INTERVAL:
		return
	_refresh_accumulator = 0.0
	world._apply_atmosphere()
