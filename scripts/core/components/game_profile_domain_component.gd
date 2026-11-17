class_name GameProfileDomainComponent
extends Node
## Owns the persistent player profile and its account-level progression.

const MAX_PROFILE_LEVEL := 60
var profile: Dictionary = {}


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	profile["xp"] = int(profile.get("xp", 0)) + amount
	var level := int(profile.get("level", 1))
	while level < MAX_PROFILE_LEVEL and int(profile.get("xp", 0)) >= 250 + (level - 1) * 180:
		profile["xp"] = int(profile.get("xp", 0)) - (250 + (level - 1) * 180)
		level += 1
	profile["level"] = level
	GameState.queue_save()
