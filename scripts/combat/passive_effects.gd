class_name PassiveEffects
extends RefCounted
## Shared constants and helpers for character passives.
##
## Passives are declared in characters.json as `passive.id`. The combat engine
## owns the actual hooks; this class keeps the supported IDs and tuning values in
## one place so validation, tests and gameplay cannot drift apart.

const SUPPORTED_IDS := [
	"whisperstep",
	"rooted",
	"dawnkeeper",
	"hollow_crown",
	"tidecall",
	"ashen_wake",
	"hold_the_line",
	"small_miracles",
	"sanguine_waltz",
	"patient_weaver",
	"deep_roots",
	"nothing_to_lose",
]

const DEBUFF_IDS := [
	"burn",
	"poison",
	"stun",
	"blind",
	"atk_down",
	"def_down",
	"spd_down",
]

# Whisperstep: allies gain 8% speed while the owner is alive.
const WHISPERSTEP_SPEED := 1.08
# Rooted: 10% less damage while below half health.
const ROOTED_REDUCTION := 0.90
# Hold the Line: other allies take 6% less damage while the owner is alive.
const HOLD_THE_LINE_REDUCTION := 0.94
# Deep Roots: 15% defense. Knockback does not exist in the turn-based slice.
const DEEP_ROOTS_DEFENSE := 1.15
# Nothing to Lose: 12% more damage below 40% health.
const NOTHING_TO_LOSE_DAMAGE := 1.12
# Hollow Crown: dark skills deal 15% more damage to debuffed enemies.
const HOLLOW_CROWN_DAMAGE := 1.15
# Patient Weaver: stunned enemies take 20% more damage from the owner.
const PATIENT_WEAVER_DAMAGE := 1.20
# Ashen Wake: critical hits apply a 2-turn burn.
const ASHEN_WAKE_BURN_TURNS := 2
const ASHEN_WAKE_BURN_POTENCY := 0.05
# Tidecall: healing skills also grant an 8% max-HP shield.
const TIDECALL_SHIELD := 0.08
# Sanguine Waltz: heal for 20% of damage dealt.
const SANGUINE_WALTZ_LIFESTEAL := 0.20
# Small Miracles: grant the team 10 energy at battle start.
const SMALL_MIRACLES_ENERGY := 10.0
# Dawnkeeper: the first healing skill each battle refunds 20 energy to the caster.
const DAWNKEEPER_ENERGY := 20.0
# Rooted activates below this HP ratio.
const ROOTED_THRESHOLD := 0.5
# Nothing to Lose activates below this HP ratio.
const NOTHING_TO_LOSE_THRESHOLD := 0.4


static func is_supported(passive_id: String) -> bool:
	return SUPPORTED_IDS.has(passive_id)


static func is_debuff(status_id: String) -> bool:
	return DEBUFF_IDS.has(status_id)
