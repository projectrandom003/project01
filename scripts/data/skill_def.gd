class_name SkillDef
extends RefCounted
## Data-driven skill definition shared by characters, monsters and bosses.

var id: String = ""
var display_name: String = ""
var description: String = ""
var element: String = "neutral"
var kind: String = "damage"          # damage | heal | shield | buff | debuff
var power: float = 0.0
var target: String = "single_enemy"
var statuses: Array = []
var cleanse: bool = false
var lifesteal: float = 0.0
var crit_bonus: float = 0.0
var energy_gain: float = 20.0
var ultimate: bool = false


static func from_dict(skill_id: String, data: Dictionary) -> SkillDef:
	var def := SkillDef.new()
	def.id = skill_id
	def.display_name = str(data.get("name", skill_id))
	def.description = str(data.get("description", ""))
	def.element = str(data.get("element", "neutral"))
	def.kind = str(data.get("kind", "damage"))
	def.power = float(data.get("power", 0.0))
	def.target = str(data.get("target", "single_enemy"))
	def.statuses = data.get("statuses", [])
	def.cleanse = bool(data.get("cleanse", false))
	def.lifesteal = float(data.get("lifesteal", 0.0))
	def.crit_bonus = float(data.get("crit_bonus", 0.0))
	def.energy_gain = float(data.get("energy_gain", 20.0))
	def.ultimate = bool(data.get("ultimate", false))
	return def


func targets_enemies() -> bool:
	return target.ends_with("enemies") or target == "single_enemy"


func targets_allies() -> bool:
	return target.ends_with("allies") or target == "single_ally" or target == "self"
