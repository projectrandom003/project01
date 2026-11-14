# Node-Based Forest Architecture

## Status

Isolated reusable scene library created on 2026-11-14. Not connected to
GreenwardWorld or ChunkBuilder. Integration is deliberately deferred until
the player movement regression is diagnosed and passes in the real world.

Headless verification: `tools/verify_modular_forest.gd` — **62 checks passed**
on Godot 4.7.2. This validates scene/resource loading, procedural texture
assignment, authored collision nodes, AnimationPlayer playback, cleanup and
deterministic biome scatter. It is not a visual sign-off or live-world test.

## Scene hierarchy

```text
ForestEnvironment (Node2D)
├── Ground
├── GroundDetails
├── WorldObjects (single shared Y-sort parent)
│   ├── ForestTree instances
│   ├── Vegetation / shrubs / flowers / mushrooms
│   ├── ForestObstacle / rocks / fallen logs / stumps / roots
│   └── Interactable / landmark instances
└── Ambient
    └── Fireflies and other lightweight animated effects
```

All depth-sensitive objects are siblings under WorldObjects. Category
membership is expressed through groups rather than separate nested Y-sort
containers: nested category containers would sort as whole groups and could
break player/tree/rock overlap.

## Reusable scene families

- `forest_prop.tscn`: replaceable visual node with explicit Visual and Shadow
  children. Uses the existing ProceduralArt API.
- `forest_vegetation.tscn`: prop scene with authored AnimationPlayer sway.
- `forest_willow_tree.tscn`, `forest_birch_tree.tscn`,
  `forest_pine_tree.tscn`, `forest_blossom_tree.tscn`,
  `forest_dead_tree.tscn`: typed variants of the existing ForestTree scene;
  canopy occlusion and tree behavior remain shared.
- `forest_shrub.tscn`, `forest_berry_bush.tscn`,
  `forest_flower_patch.tscn`, `forest_spirit_bloom.tscn`,
  `forest_mushroom_patch.tscn`, `forest_fern_patch.tscn`,
  `forest_reed_patch.tscn`, `forest_crystal_cluster.tscn`,
  `forest_rune_stone.tscn`: typed prop-family scenes reusing the same visual
  component contract and authored/procedural art pipeline.
- `forest_obstacle.tscn`: visual prop plus independent StaticBody2D and
  CollisionShape2D. Collision dimensions are separate from art bounds.
- `forest_rock.tscn`, `forest_fallen_log.tscn`, `forest_stump.tscn`,
  `forest_root_cluster.tscn`: obstacle/landmark variants. Fallen log, stump
  and root cluster use authored Polygon2D/Line2D shapes and independent physics.
- `forest_firefly.tscn`: separate ambient actor with an AnimationPlayer-driven
  hover and pulse.

## Composition API

`ModularForestEnvironment` exposes:

- `add_ground_chunk(...)` for authored or generated ground chunk scenes.
- `add_ground_detail(...)` for batched detail nodes such as MultiMesh layers.
- `add_prop(...)` for decorative props and vegetation.
- `add_obstacle(...)` for collision-bearing rocks and similar objects.
- `add_tree(...)` for any supported tree kind using the shared ForestTree.
- `add_fallen_log(...)`, `add_stump(...)`, `add_root_cluster(...)`.
- `add_firefly(...)` for ambient animated actors.
- `add_family_scene(...)` for any other authored reusable scene.
- `clear_generated()` for clearing generated chunk content without deleting
  permanent layer roots.

All positions are local to the ForestEnvironment root. Callers remain responsible
for converting isometric grid coordinates with the existing IsoMath API.
Category tags use groups such as `forest_vegetation`, `forest_trees`,
`forest_obstacles`, `forest_ambient`.

## Data-driven biome profiles

`ForestBiomeProfile` is a Resource containing reusable PackedScenes and counts,
spacing, and bounds insets. Two starter profiles are authored:

- `resources/environment/forest/greenward_forest.tres`: willow, pine, blossom
  and dead trees with shrubs, berries, wildflowers, ferns, mushrooms and fireflies.
- `resources/environment/forest/moonpetal_hollow.tres`: silver birch, blossom
  and dead trees with spirit blooms, glow mushrooms, crystals, rune stones,
  ferns and fireflies.

`ForestBiomeAssembler.populate(environment, profile, bounds, seed)` scatters
these scenes using a local RandomNumberGenerator seeded from biome ID + caller
seed. Same biome, bounds and seed produce the same placements. Caller should
include world seed and chunk coordinates in seed_value. It returns placed counts
and tree/understory positions. This assembler is separate from chunk streaming;
it does not alter the existing deterministic chunk builder.

## Performance rules

- Trees, collision-bearing props, interactive objects and animated set dressing
  are individual reusable scenes.
- Dense non-interactive grass blades, leaf litter and tiny ground flecks should
  remain MultiMesh or chunk-batched data.
- Chunk streaming owns lifetime; unloading a chunk frees its environment root.
- Never create one Node2D per tile or per blade of grass.
- Keep physics shapes simple and independent of transparent sprite bounds.
- All depth-sensitive object roots share one Y-sort parent.
- Keep biome scatter counts bounded and tune them against actual frame time.

## Integration plan (not yet performed)

1. Verify movement in an isolated player scene.
2. Verify movement in the current Greenward runtime.
3. Build one forest test chunk with this library beside the existing chunk.
4. Compare visual quality, physics, Y-sort, node count and frame time.
5. Integrate behind a per-chunk migration flag.
6. Migrate one prop family at a time; preserve deterministic generation and
   chunk streaming before removing legacy prop rendering.

## Deliberately untouched

- `scripts/world/chunk_builder.gd`
- `scripts/world/greenward_world.gd`
- `scripts/player/player.gd`
- Existing quest navigation, combat, save and streaming APIs.

## Environmental behavior layer (2026-11-14)

- `forest_wind_controller.gd` owns one shared ShaderMaterial for the forest.
  Tree canopies and vegetation sprites receive the same material; trunk and
  shadow layers stay stable. A slow gust envelope changes sway strength/speed
  without creating per-leaf nodes.
- `ModularForestEnvironment.set_time_of_day(0..1)` drives the ambient layer.
  Fireflies dim and pause through daylight, then brighten and resume at dusk /
  night. The same night-activity envelope drives magical plant accents:
  spirit blooms, glow mushrooms, crystals and rune stones.
- `forest_preview.tscn` is an isolated testbed. Keys 1/2/3 jump to day/dusk/night,
  Space pauses the slow cycle, and Up/Down adjust wind intensity.
- The preview and environmental behaviors remain separate from GreenwardWorld,
  DayNight and chunk streaming. No live-world integration was performed.
- Headless verification now covers shared wind material assignment, firefly
  day/night activation, magical glow fade/restore and the existing biome/
  composition contracts: `tools/verify_modular_forest.gd` — **71 checks passed**.
- GUI visual review remains pending; automated verification does not certify
  that the forest composition is visually polished at gameplay camera scale.
