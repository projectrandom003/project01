class_name CharacterDef
extends RefCounted
## Immutable definition of a collectible character, parsed from data.
## Instances (levels, awakening, equipment) live in CharacterInstance.

var id: String = ""
var display_name: String = ""
var title: String = ""
var race: String = ""
var element: String = ""
var rarity: String = ""
var role: String = ""
var base: Dictionary = {}
var skills: Array = []
var ultimate: String = ""
var passive_id: String = ""
var passive_name: String = ""
var passive_text: String = ""
var lore: String = ""
var palette: Dictionary = {}
var portrait_seed: int = 0


static func from_dict(character_id: String, data: Dictionary) -> CharacterDef:
	var def := CharacterDef.new()
	def.id = character_id
	def.display_name = str(data.get("name", character_id))
	def.title = str(data.get("title", ""))
	def.race = str(data.get("race", "Unknown"))
	def.element = str(data.get("element", "neutral"))
	def.rarity = str(data.get("rarity", "common"))
	def.role = str(data.get("role", "Adventurer"))
	def.base = data.get("base", {})
	def.skills = data.get("skills", [])
	def.ultimate = str(data.get("ultimate", ""))
	var passive: Dictionary = data.get("passive", {})
	def.passive_id = str(passive.get("id", ""))
	def.passive_name = str(passive.get("name", ""))
	def.passive_text = str(passive.get("text", ""))
	def.lore = str(data.get("lore", ""))
	def.palette = data.get("palette", {})
	def.portrait_seed = int(data.get("portrait_seed", 0))
	return def


func stat(stat_name: String) -> float:
	return float(base.get(stat_name, 0.0))


func color_of(key: String, fallback: String = "#ffffff") -> Color:
	return Color(str(palette.get(key, fallback)))
