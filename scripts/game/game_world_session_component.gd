class_name GameWorldSessionComponent
extends Node
## Composition root and compatibility facade for the active world session.
## Scene ownership is delegated to transition, activation and persistence nodes.

signal world_changed(world: Node2D, region_id: String)
signal region_arrived(region_id: String, display_name: String)

@export var world_host_path: NodePath = NodePath("../WorldHost")

const GREENWARD_WORLD_SCENE: PackedScene = preload("res://scenes/world/greenward_world.tscn")
const WORLD_SCENES := {
	"greenward": preload("res://scenes/world/greenward_world.tscn"),
	"moonpetal_hollow": preload("res://scenes/world/greenward_world.tscn"),
	"castle_royal_gardens": preload("res://scenes/world/castle_royal_gardens.tscn"),
	"gothic_castle_boss_zone": preload("res://scenes/world/gothic_castle_boss_zone.tscn"),
}
const DEFAULT_START_REGION := "castle_royal_gardens"

@onready var transition_component: GameWorldTransitionComponent = get_node_or_null("Transition") as GameWorldTransitionComponent
@onready var activation_component: GameWorldActivationComponent = get_node_or_null("Activation") as GameWorldActivationComponent
@onready var persistence_component: GameWorldPersistenceComponent = get_node_or_null("Persistence") as GameWorldPersistenceComponent

var world_host: Node2D
var world: Node2D
var current_region_id: String = "greenward"

func _ready() -> void:
	world_host = get_node_or_null(world_host_path) as Node2D
	if transition_component == null or activation_component == null or persistence_component == null:
		push_error("GameWorldSessionComponent requires authored Transition, Activation and Persistence children.")
		return
	transition_component.configure(self)
	activation_component.configure(self)
	persistence_component.configure(self)

func has_region_scene(region_id: String) -> bool:
	return WORLD_SCENES.has(region_id)

func build_world(region_id: String = "", entry_point: String = "") -> Node2D:
	if world_host == null:
		world_host = get_node_or_null(world_host_path) as Node2D
	if world_host == null:
		push_error("[GameWorldSession] WorldHost is missing.")
		return null
	# WorldHost is a single-world container. Clear every previous child before
	# instancing the destination so stale/queued worlds can never render beneath
	# the new region (e.g. Gothic Castle over Royal Gardens after Continue).
	for previous_world in world_host.get_children():
		world_host.remove_child(previous_world)
		previous_world.queue_free()
	world = null
	var resolved_id := region_id
	if resolved_id.is_empty():
		resolved_id = GameState.session_domain.active_world_id if not str(GameState.session_domain.active_world_id).is_empty() else GameState.session_domain.player_region
	resolved_id = resolve_region_id(resolved_id)
	current_region_id = resolved_id
	GameState.session_domain.set_player_region(resolved_id)
	var scene: PackedScene = WORLD_SCENES.get(resolved_id, GREENWARD_WORLD_SCENE)
	world = scene.instantiate() as Node2D
	if "region_id" in world:
		world.region_id = resolved_id
	if "entry_point" in world:
		world.entry_point = entry_point
	world.name = "World_" + resolved_id
	world_host.add_child(world)
	GameState.queue_save()
	world_changed.emit(world, current_region_id)
	return world

func resolve_region_id(region_id: String) -> String:
	var resolved := str(region_id)
	if resolved.is_empty():
		return "greenward" if WORLD_SCENES.has("greenward") else DEFAULT_START_REGION
	if WORLD_SCENES.has(resolved):
		return resolved
	if ContentDB.regions.has(resolved):
		return "greenward" if WORLD_SCENES.has("greenward") else DEFAULT_START_REGION
	return "greenward" if WORLD_SCENES.has("greenward") else DEFAULT_START_REGION

func transition_to(target_region_id: String, entry_point: String) -> Dictionary:
	return transition_component.transition_to(target_region_id, entry_point) if transition_component != null else {"ok": false, "reason": "Transition component is missing."}

func set_world_active(active: bool) -> void:
	if activation_component != null:
		activation_component.set_active(active)

func persist_current_world_state() -> void:
	if persistence_component != null:
		persistence_component.persist_current_world_state()
