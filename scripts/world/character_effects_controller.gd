class_name CharacterEffectsController
extends Node2D
## Enables authored, character-specific node effects without taking ownership
## of animation or rendering. Resolves the parent identity once, then idles.

@onready var lilith_glow: Sprite2D = get_node_or_null("Aura/LilithSpectralGlow") as Sprite2D
@onready var kael_aura: Sprite2D = get_node_or_null("Aura/KaelEmberAura") as Sprite2D

var _last_character_id: String = ""


func _ready() -> void:
	_refresh_character_effects()


func _process(_delta: float) -> void:
	_refresh_character_effects()


func _refresh_character_effects() -> void:
	var owner := get_parent()
	if owner == null:
		return
	var character_id := ""
	var id_value: Variant = owner.get("character_id")
	if id_value is String:
		character_id = id_value
	if character_id.is_empty():
		character_id = String(owner.name).to_lower().replace("visual", "")
	if character_id == _last_character_id:
		return
	_last_character_id = character_id
	if lilith_glow != null:
		lilith_glow.visible = character_id == "lilith"
	if kael_aura != null:
		kael_aura.visible = character_id == "kael"
