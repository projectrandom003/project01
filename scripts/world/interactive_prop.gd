class_name InteractiveProp
extends Interactable
## Interactive environmental prop: lore objects are inspect-only, while
## explicitly configured gathering nodes grant one-time, save-persistent rewards.
## Every successful interaction emits a local signal; visual art is procedural.
## This keeps exploration rewards isolated from quest and combat state
## untouched. Visual is a ProceduralArt Sprite2D plus a soft highlight ring that
## brightens when the player is near. All art is procedural placeholder.
##
## The exact EventBus signal used is `toast_requested(message: String)` (verified
## in scripts/core/event_bus.gd). If a build ever drops it, interact() still emits
## the local `activated` signal and simply does nothing else gameplay-affecting.

## Local, non-gameplay signal emitted on a successful interact.
signal activated(prop: InteractiveProp)

const HIGHLIGHT_RADIUS := 156.0

var prop_kind: String = "rune_stone"
var variant: int = 0
var display_name: String = "Ancient Stone"
var lore: String = ""
var toast_on_interact: bool = true
var collectible_id: String = ""
var collectible_rewards: Dictionary = {}
var collectible_label: String = ""
var _sprite: Sprite2D
var _highlight: float = 0.0
var _player: Node2D


## `p_position` is a world-space position. Called before or after add_child() —
## both are safe.
func setup(p_kind: String, p_position: Vector2, p_name: String, p_lore: String, p_variant: int = 0) -> void:
	prop_kind = p_kind
	variant = p_variant
	display_name = p_name
	lore = p_lore
	prompt = "Examine"
	interaction_radius = 74.0
	position = p_position
	_build_visual()


func configure_collectible(p_id: String, p_rewards: Dictionary, p_label: String = "Collected") -> void:
	collectible_id = p_id
	collectible_rewards = p_rewards.duplicate(true)
	collectible_label = p_label
	prompt = "Gather"


func _ready() -> void:
	super._ready()  # adds this node to the "interactables" group
	if not collectible_id.is_empty() and bool(GameState.flags.get("collectible:" + collectible_id, false)):
		enabled = false
		visible = false
		set_process(false)
		return
	if _sprite == null:
		_build_visual()  # safe fallback for a bare InteractiveProp.new()
	set_process(true)


func _build_visual() -> void:
	if _sprite != null:
		return
	var tex := ProceduralArt.prop_texture(prop_kind, variant)
	if tex == null:
		tex = ProceduralArt.white_pixel()
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = tex
	_sprite.centered = false
	_sprite.offset = Vector2(-float(tex.get_width()) * 0.5, -float(tex.get_height()) + 6.0)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(_sprite)


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") if is_inside_tree() else null
	var target := 0.0
	if _player != null and is_instance_valid(_player):
		var d := global_position.distance_to(_player.global_position)
		if d < HIGHLIGHT_RADIUS:
			target = 1.0 - d / HIGHLIGHT_RADIUS
	if absf(target - _highlight) > 0.01:
		_highlight = move_toward(_highlight, target, delta * 3.0)
		if _sprite != null:
			var boost := 1.0 + _highlight * 0.35
			_sprite.modulate = Color(boost, boost, boost, 1.0)
		queue_redraw()


func _draw() -> void:
	if _highlight <= 0.0:
		return
	var c := GreenwardStyle.MAGIC.teal
	var alpha := _highlight * 0.62
	draw_circle(Vector2(0, -3), 26.0, Color(c.r, c.g, c.b, alpha * 0.08))
	draw_arc(Vector2(0, 0), 22.0 + _highlight * 3.0, 0.0, TAU, 32, Color(c.r, c.g, c.b, alpha), 2.2)
	draw_arc(Vector2(0, 0), 30.0 + _highlight * 5.0, 0.0, TAU, 32, Color(c.r, c.g, c.b, alpha * 0.48), 1.6)


## Lore props remain flavour-only. Configured gathering props grant their
## explicit one-time rewards and persist the claim flag in the existing save.
func interact() -> void:
	if not can_interact():
		return
	activated.emit(self)
	if not collectible_id.is_empty():
		var flag_key := "collectible:" + collectible_id
		if bool(GameState.flags.get(flag_key, false)):
			enabled = false
			visible = false
			set_process(false)
			return
		GameState.flags[flag_key] = true
		GameState.grant_reward_items(collectible_rewards)
		GameState.queue_save()
		enabled = false
		visible = false
		set_process(false)
		var reward_names: Array[String] = []
		for item_id in collectible_rewards.keys():
			var item: Dictionary = ContentDB.get_item(str(item_id))
			reward_names.append("%s ×%d" % [str(item.get("name", item_id)), int(collectible_rewards[item_id])])
		var reward_text := ", ".join(reward_names)
		EventBus.toast_requested.emit("%s — %s" % [collectible_label, reward_text])
		return
	if toast_on_interact:
		var message := display_name
		if not lore.is_empty():
			message = "%s — %s" % [display_name, lore]
		EventBus.toast_requested.emit(message)
