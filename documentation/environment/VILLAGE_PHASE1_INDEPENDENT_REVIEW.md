# Village Phase 1 — Independent Integration Review

Scope: read-only review of OpenCode's canonical scaffold under
`scenes/world/village`, `scripts/world/village`, and
`resources/data/village/greenward_village_layout.tres`. No canonical files
were modified by this review.

## Runtime verification

`tools/verify_village_phase1_scaffold.gd` instantiates the canonical
VillageEnvironment and reusable scenes, checks the hierarchy and Y-sort flags,
loads the Greenward layout Resource, verifies stable seeded RNG behavior, and
exercises the reusable light's day/night phase behavior.

Latest result: **29 checks passed, 0 failures** (Godot 4.7.2 headless).

## Integration issues to resolve before live composition

### 1. Shared Y-sort across logical groups

Buildings, TreeGroups, Vegetation, Furniture, NPCs, and InteractiveLocations
currently have separate Y-sorted parent nodes. Godot sorts children within each
Y-sort context; it does not interleave grandchildren from separate contexts.
A tall tree/building canopy can therefore render over or under an NPC/furniture
object incorrectly when their depth bases cross.

Recommended integration shape:
- Keep logical folders/layers for organization and authoring.
- Put every depth-sensitive actor/prop instance under one shared Y-sort parent
  in the live world, or use a single shared depth-sorted object container with
  logical groups represented by node groups/metadata rather than nested
  Y-sort parents.
- Keep non-depth layers (ground, path underlay, lighting, screen-space ambient)
  outside that shared sortable container.
- Validate player-vs-tree, NPC-vs-tree, NPC-vs-building, and furniture-vs-player
  overlap in the actual camera view.

### 2. Path scene is currently a structural shell

`VillagePathSegment.tscn` contains Polygon2D and Line2D children, but the
Polygon2D has no authored polygon points and the script only stores connectivity
metadata. The segment is not yet a visible road and does not create navigation
or collision. Phase 2 should supply authored geometry or a reusable path
resource and verify continuous joins at bends/intersections.

Avoid one node per ground tile. Prefer a small number of authored continuous
segments or batched ground geometry.

### 3. Layout Resource is not yet consumed by the composition root

`VillageEnvironment.layout_config` is exported, but the current coordinator
only emits `village_ready` and forwards light phase values. This is a good
small-coordinator boundary; Phase 2/3 should define explicit consumers for
named anchors, path connectivity, tree groups and decorative variation rather
than adding procedural construction to the root.

### 4. Light texture and visual tuning remain pending

`VillageLightSource` correctly separates a PointLight2D from its optional
visible source node and supports phase energy. The scene currently has no
assigned light texture. The light can be enabled and have energy but still
needs a soft radial texture, calibrated scale/energy, and tested interaction
with CanvasModulate, fog, weather, and any occluders before it looks finished.

### 5. Traversability metadata is not navigation

The `traversable` flag and `connects` metadata are useful authoring data but
do not themselves update collision, navigation, or player movement. Integration
must preserve existing world walkability and navigation ownership.

## Ownership boundary

OpenCode remains the sole owner of live GreenwardWorld, ChunkBuilder, canonical
village scenes/scripts/resources, and their integration. This review and its
verification script are additive only. The separate `scenes/environment/village`
prototype created in the parallel workstream is not wired into gameplay and
should not be merged as a second village architecture.
