class_name ElementTable
extends RefCounted
## Elemental wheel: Fire > Wind > Earth > Water > Fire. Light and Dark are
## mutual weaknesses. Multipliers are data-independent and shared by all combat.

const ADVANTAGE := 1.5
const DISADVANTAGE := 0.75
const BEATS := {
	"fire": "wind",
	"wind": "earth",
	"earth": "water",
	"water": "fire",
}


static func multiplier(attacker: String, defender: String) -> float:
	if attacker == "neutral" or defender == "neutral":
		return 1.0
	if attacker == defender:
		return 1.0
	if (attacker == "light" and defender == "dark") or (attacker == "dark" and defender == "light"):
		return ADVANTAGE
	if str(BEATS.get(attacker, "")) == defender:
		return ADVANTAGE
	if str(BEATS.get(defender, "")) == attacker:
		return DISADVANTAGE
	return 1.0


static func label(multiplier_value: float) -> String:
	if multiplier_value > 1.01:
		return "Advantage"
	if multiplier_value < 0.99:
		return "Resisted"
	return "Neutral"
