# Node-Based Village Components

This isolated reusable library does not modify or replace GreenwardWorld and is
not wired into live gameplay.

## Composition root

`scenes/environment/village/village_environment.tscn` provides explicit layers:
GroundDetails, PathNetwork, Buildings, TreeGroups, Furniture, NPCs, Landmarks,
Lighting, and Ambient. Depth-sensitive layers use Y-sort.

## Authored placement

Use `village_anchor.tscn` as a Marker2D in an authored layout scene. Set its
role and PackedScene in the Inspector. Anchor positions are fixed by the scene.
The layout seed selects a repeatable variant/flip; it never scatters or moves
major buildings and trees.

Roles route instances into their corresponding layer. Decorative vegetation
falls back to GroundDetails.

## Footpaths

`village_path.tscn` is a reusable Line2D component with separate edge, surface,
and highlight nodes. Configure its points and width from an authored layout.
It is visual-only and intentionally does not create collision or navigation.
The integration owner should connect it to the project's existing walkability
and navigation model if required.

## Integration boundary

OpenCode owns all live GreenwardWorld and ChunkBuilder integration. These
components are not referenced by either shared script. Preserve NPC dialogue,
quest contracts, world streaming, save data, and collision ownership.

## Node-first constraints

- Reusable scenes and Inspector-authored anchors before scripts.
- No per-grass-blade nodes; keep tiny ground detail batched.
- One shared Y-sort parent per depth-sensitive layer.
- Seeds affect decorative variants only.
- No duplicate village controller or parallel navigation system.
