class_name RoamingMonster
extends Interactable
## A visible world monster that roams, notices the player and starts a battle.
## It is intentionally NOT a fake battle: it requests a real encounter from the
## game controller, and stays defeated until it respawns.
##
## Phase 3 / Step 5: each spawn gets a DETERMINISTIC (group_id + spawn_index)
## palette tint, visual_scale variance, silhouette hint and a small prop accent,
## so a group of the same enemy reads as varied without touching any JSON. The
## animator is wired for roaming (WALK) / alert (RUN) / idle (IDLE). All gameplay
## behaviour (setup, _begin_encounter, EventBus.encounter_requested, walking,
## is_boss, visual_scale, battle_finished handling) is preserved.

const ANIM_IDLE := 0
const ANIM_WALK := 1
const ANIM_RUN := 2

var group_id: String = ""
var home_position: Vector2 = Vector2.ZERO
var roam_radius: float = 70.0
var move_speed: float = 26.0
var is_boss: bool = false
var engaged: bool = false
var defeated: bool = false
var respawn_seconds: float = 75.0
## Set by GreenwardWorld before setup(); drives deterministic per-spawn variety.
var spawn_index: int = 0
var _engagement_cooldown: float = 0.0
var _spawn_grace: float = 3.0

var visual: ActorVisual
var visual_definition: Dictionary = {}
var _roam_target: Vector2
var _roam_timer: float = 0.0
var _player: Node2D
var _name_label: Label


func setup(p_group_id: String, p_home: Vector2, p_enemy_def: Dictionary, p_boss: bool) -> void:
	group_id = p_group_id
	home_position = p_home
	position = p_home
	is_boss = p_boss
	prompt = "Challenge" if p_boss else "Fight"
	interaction_radius = 70.0
	visual_definition = p_enemy_def
	respawn_seconds = 120.0 if p_boss else 75.0
	move_speed = 14.0 if p_boss else 26.0


func _ready() -> void:
	super._ready()
	_roam_target = position

	# ---- deterministic per-spawn variety (group_id + spawn_index) ----
	var vseed := absi(("%s|%d" % [group_id, spawn_index]).hash())
	var tints: Array = [
		GreenwardStyle.MAGIC.teal, GreenwardStyle.MAGIC.violet,
		GreenwardStyle.ACCENTS.berry, GreenwardStyle.CANOPY.bright,
		GreenwardStyle.MAGIC.gold,
	]
	var tint: Color = tints[vseed % tints.size()]
	var tinted := _tint_palette(visual_definition.get("palette", {}), tint, 0.12 + float(vseed % 10) * 0.01)
	var scale_variance := 0.85 + float(vseed % 30) * 0.01  # 0.85 .. 1.14

	var enemy_name := str(visual_definition.get("name", "Monster"))
	var def_id := str(visual_definition.get("id", ""))
	var kind := ActorVisual.Kind.MONSTER
	if def_id == "glade_wisp":
		kind = ActorVisual.Kind.SPIRIT

	visual = ActorVisual.new()
	visual.setup(tinted, kind, def_id, "Monster", str(visual_definition.get("element", "neutral")))
	visual.is_boss = is_boss
	visual.visual_scale = (1.35 if is_boss else 1.0) * scale_variance
	# Vary silhouette where feasible via existing ActorVisual.Kind / def_id /
	# race values. Bosses keep their true def_id so the treant boss still draws.
	if not is_boss and def_id != "moonpetal_sprite":
		var silhouettes := ["mossling", "thornhound", "fae_marauder", "glade_wisp", "corrupted_treant"]
		visual.def_id = str(silhouettes[(vseed >> 3) % silhouettes.size()])
	add_child(visual)
	# PART 4: exercise the SpriteFramesActorSource registration seam for this
	# enemy definition id. No disk sheets exist, so the procedural fallback stays.
	visual.configure_character(def_id)
	_add_accent(vseed)

	_name_label = Label.new()
	_name_label.text = enemy_name
	_name_label.position = Vector2(-80, -100 if is_boss else -68)
	_name_label.size = Vector2(160, 22)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 12 if not is_boss else 15)
	_name_label.add_theme_color_override("font_color", GreenwardStyle.MAGIC.ember if not is_boss else GreenwardStyle.UI.gold)
	_name_label.add_theme_color_override("font_outline_color", GreenwardStyle.INK)
	_name_label.add_theme_constant_override("outline_size", 4)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

	EventBus.battle_finished.connect(_on_battle_finished)


static func _to_color(v: Variant) -> Color:
	if v is Color:
		return v
	if v is String and str(v).begins_with("#"):
		return Color(str(v))
	return Color("#4f6b3a")


func _tint_palette(p: Dictionary, tint: Color, amount: float) -> Dictionary:
	var out := {}
	for key in p.keys():
		out[key] = _to_color(p[key]).lerp(tint, amount)
	return out


## A tiny deterministic decorative prop accent near the monster's feet.
func _add_accent(vseed: int) -> void:
	if is_boss or (vseed % 3 == 0):
		return
	var kinds := ["crystal", "glow_mushroom", "rune_stone", "spirit_bloom", "mushroom", "pebble"]
	var kind := str(kinds[vseed % kinds.size()])
	var tex := ProceduralArt.prop_texture(kind, vseed % 2)
	if tex == null:
		return
	var s := Sprite2D.new()
	s.name = "Accent"
	s.texture = tex
	s.centered = false
	s.offset = Vector2(-float(tex.get_width()) * 0.5, -float(tex.get_height()) + 6.0)
	s.scale = Vector2.ONE * 0.4
	s.position = Vector2(14.0 * (1.0 if vseed % 2 == 0 else -1.0), 0.0)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(s)


func _process(delta: float) -> void:
	if defeated:
		return
	# Engagement cooldown: hold position, never engage, never chase.
	if _engagement_cooldown > 0.0:
		_engagement_cooldown -= delta
		if _engagement_cooldown < 0.0:
			_engagement_cooldown = 0.0
		visual.walking = false
		visual.play(ANIM_IDLE)
		return
	if engaged:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return
	# Monsters never initiate combat from proximity or chase the player.
	# They roam inside their home radius and remain passive until the player
	# approaches and explicitly presses E / the Interact button.
	_roam_timer -= delta
	if _roam_timer <= 0.0:
		_roam_timer = randf_range(2.0, 5.0)
		var found := false
		for _attempt in 8:
			var offset := Vector2(randf_range(-roam_radius, roam_radius), randf_range(-roam_radius, roam_radius))
			var candidate := home_position + offset
			if _target_walkable(candidate):
				_roam_target = candidate
				found = true
				break
		if not found:
			_roam_target = position
	if position.distance_to(_roam_target) > 4.0 and _target_walkable(_roam_target):
		var to_target := _roam_target - position
		position = position.move_toward(_roam_target, move_speed * delta)
		visual.walking = true
		visual.set_move_direction(to_target)
		visual.play(ANIM_WALK)
	else:
		visual.walking = false
		visual.play(ANIM_IDLE)


func interact() -> void:
	if not can_interact() or engaged or defeated or _engagement_cooldown > 0.0:
		return
	_begin_encounter()


func _begin_encounter() -> void:
	# This method is only reached by explicit Interactable.interact() (E / A).
	# Spawn grace must never block a deliberate player challenge.
	if engaged or defeated or _engagement_cooldown > 0.0:
		return
	engaged = true
	visual.walking = false
	EventBus.encounter_requested.emit(group_id, self)


func _on_battle_finished(result: Dictionary) -> void:
	if str(result.get("group_id", "")) != group_id:
		return
	if not engaged:
		return
	if bool(result.get("victory", false)):
		_defeat()
	else:
		engaged = false
		_engagement_cooldown = 8.0
		position = home_position
		_roam_target = home_position


func _defeat() -> void:
	engaged = false
	defeated = true
	enabled = false
	visible = false
	await get_tree().create_timer(respawn_seconds).timeout
	if not is_instance_valid(self):
		return
	defeated = false
	enabled = true
	visible = true
	position = home_position
	_roam_target = home_position
	_spawn_grace = 2.0
	_engagement_cooldown = 0.0


func _world() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group("world")


func _target_walkable(pos: Vector2) -> bool:
	var w := _world()
	if w == null or not is_instance_valid(w):
		return true
	if not w.has_method("is_walkable"):
		return true
	return bool(w.is_walkable(pos))
