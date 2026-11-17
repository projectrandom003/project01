class_name HUDQuestComponent
extends Node
## Owns the tracked-quest summary and local/cross-region navigation text.

var hud: HUD

func bind(owner: HUD) -> void:
	hud = owner

func refresh_quest() -> void:
	if hud == null or hud._quest_label == null:
		return
	var tracked := GameState.quest_domain.tracked_quest()
	if tracked.is_empty():
		hud._quest_label.visible = false
		return
	var definition: Dictionary = ContentDB.get_quest(tracked)
	if definition.is_empty():
		hud._quest_label.visible = false
		return
	var state := GameState.quest_domain.quest_state(tracked)
	var step: Dictionary = GameState.quest_domain.quest_step(tracked)
	if state == "complete":
		hud._quest_label.text = "◆  %s — Complete" % str(definition.get("name", tracked))
		hud._quest_label.visible = true
		return
	if state == "not_started":
		var available_text := "Available · " + str(step.get("text", "Quest available"))
		hud._quest_label.text = "◆  %s — %s" % [str(definition.get("name", tracked)), available_text]
		hud._quest_label.visible = true
		return
	var resolver: QuestNavigationResolver = hud.quest_resolver if hud.quest_resolver != null else QuestNavigationResolver.shared()
	var resolved: Dictionary = resolver.get_resolved_target()
	var step_text := str(resolved.get("step_text", step.get("text", "")))
	var suffix := ""
	if str(resolved.get("status", "")) == QuestNavigationResolver.STATUS_UNREACHABLE:
		suffix = "  · Unreachable"
	elif not bool(resolved.get("same_frame", false)):
		var next_hop: Dictionary = resolved.get("next_hop", {})
		var route: Array = resolved.get("route", [])
		if not route.is_empty() and not next_hop.is_empty():
			var hop_to := str(next_hop.get("to", str(resolved.get("target_region_id", ""))))
			var hop_label := str(next_hop.get("label", ""))
			var travel := hop_label if not hop_label.is_empty() else ("Travel to %s" % hop_to)
			suffix = "  · %s" % travel
		else:
			suffix = "  · Travel to %s" % str(resolved.get("target_region_id", "destination"))
	else:
		var distance_value: Variant = resolved.get("distance", null)
		if distance_value != null:
			var distance := float(distance_value)
			if distance > 1.0:
				var direction_value: Variant = resolved.get("direction", Vector2.ZERO)
				var arrow := quest_arrow(direction_value if typeof(direction_value) == TYPE_VECTOR2 else Vector2.ZERO)
				suffix = "  (%s %.0f tiles)" % [arrow, distance / IsoMath.TILE_W]
	hud._quest_label.text = "◆  %s — %s%s" % [str(definition.get("name", tracked)), step_text, suffix]
	hud._quest_label.visible = true

func quest_arrow(direction: Variant = null) -> String:
	if direction == null or typeof(direction) != TYPE_VECTOR2:
		direction = Vector2.ZERO
	if (direction as Vector2).length_squared() < 0.0001:
		return "•"
	var angle := (direction as Vector2).angle()
	if angle < 0.0:
		angle += TAU
	var sector := int(round(angle / (PI * 0.25))) % 8
	var arrows := ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"]
	return arrows[sector]
