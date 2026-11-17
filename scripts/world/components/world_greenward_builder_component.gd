class_name WorldGreenwardBuilderComponent
extends Node
## Compatibility facade. Dedicated child nodes own river, landmark, route and
## interaction composition so each responsibility can be edited and tested alone.

var world: GreenwardWorld
@export var composition_data: GreenwardCompositionData
@onready var river_builder: WorldGreenwardRiverComponent = get_node_or_null("RiverBuilder") as WorldGreenwardRiverComponent
@onready var landmark_builder: WorldGreenwardLandmarkComponent = get_node_or_null("LandmarkBuilder") as WorldGreenwardLandmarkComponent
@onready var route_builder: WorldGreenwardRouteComponent = get_node_or_null("RouteBuilder") as WorldGreenwardRouteComponent
@onready var interaction_builder: WorldGreenwardInteractionComponent = get_node_or_null("InteractionBuilder") as WorldGreenwardInteractionComponent

func configure(owner_world: GreenwardWorld) -> void:
    world = owner_world
    if composition_data == null:
        push_error("WorldGreenwardBuilderComponent requires GreenwardCompositionData")
        return
    var errors := composition_data.validate()
    if not errors.is_empty():
        push_error("Invalid Greenward composition data: " + "; ".join(errors))
    for component in [river_builder, landmark_builder, route_builder, interaction_builder]:
        if component == null:
            push_error("GreenwardBuilder is missing a dedicated composition child node")
        else:
            component.configure(world, composition_data)

func _anchor(anchor_name: String, fallback: Vector2) -> Vector2:
    if composition_data == null:
        return fallback
    var value: Variant = composition_data.anchors.get(anchor_name, fallback)
    return value if typeof(value) == TYPE_VECTOR2 else fallback

func build_village() -> void:
    if world == null or composition_data == null:
        return
    build_river()
    for npc in composition_data.village_npcs:
        world.spawn_npc(
            str(npc.get("npc_id", "")),
            str(npc.get("display_name", "")),
            str(npc.get("dialogue_id", "")),
            npc.get("grid", Vector2.ZERO),
            npc.get("palette", {}),
            str(npc.get("race", "Human")),
            str(npc.get("role", ""))
        )

func build_river() -> void:
    if river_builder != null:
        river_builder.build_river()

func build_landmarks() -> void:
    if landmark_builder != null:
        landmark_builder.build_landmarks()

func build_extra_landmarks() -> void:
    if landmark_builder != null:
        landmark_builder.build_extra_landmarks()

func build_elder_hollow_territory() -> void:
    if landmark_builder != null:
        landmark_builder.build_elder_hollow_territory()

func build_fallen_matron_territory() -> void:
    if landmark_builder != null:
        landmark_builder.build_fallen_matron_territory()

func build_paths() -> void:
    if route_builder != null:
        route_builder.build_paths()

func build_extra_interactive_and_animated() -> void:
    if interaction_builder != null:
        interaction_builder.build_extra_interactive_and_animated()

func build_greenward_gate_composition() -> void:
    if landmark_builder != null:
        landmark_builder.build_greenward_gate_composition()
