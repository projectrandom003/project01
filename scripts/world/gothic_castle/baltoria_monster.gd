extends RoamingMonster
## Baltoria's world avatar: the arena seal keeps the boss untouchable until the
## player has accepted the "baltoria_summoning" quest from Gatekeeper Sable.
## Combat, rewards, respawn and AI are inherited from the existing enemy system.

func can_interact() -> bool:
	if not super.can_interact():
		return false
	if GameState.quest_domain.quest_state("baltoria_summoning") != "active":
		prompt = "The seal holds — speak with Gatekeeper Sable"
		return false
	prompt = "Challenge Baltoria"
	return true


func interact() -> void:
	if not can_interact():
		EventBus.toast_requested.emit("The arena seal still holds. Speak with Gatekeeper Sable.")
		return
	super.interact()
