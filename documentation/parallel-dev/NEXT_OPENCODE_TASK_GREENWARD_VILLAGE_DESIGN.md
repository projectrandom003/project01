# OpenCode — Priority assignment: redesign and finish Greenward Village

## Objective

Own the next major environment-design pass: make Greenward feel like a beautiful, memorable, lived-in fantasy village that players enjoy exploring. This is a real in-game environment task, not just a concept document or isolated prototype. Work in the canonical live world/village architecture and deliver a playable, visually inspected result.

The user explicitly wants work focused on village design.

## Inspect first — preserve the existing project

Read the canonical live implementation and its history before editing:
- `scenes/world/greenward_world.tscn`, `scripts/world/greenward_world.gd`, `scenes/world/village/GreenwardVillage.tscn`
- `scripts/world/village/`, `resources/data/village/greenward_village_layout.tres`
- `documentation/environment/NODE_BASED_VILLAGE_COMPONENTS.md`
- `documentation/environment/VILLAGE_PHASE1_INDEPENDENT_REVIEW.md`
- existing village/forest verification tools and recent captures.

There are two village-related architectures in the repository. The canonical live implementation is `scenes/world/village` and its integration with `GreenwardWorld` / `ChunkBuilder`. The separate `scenes/environment/village` library is an isolated prototype and must NOT become a second live village or be wired in as a competing controller. Reuse a component from it only if there is a clear reason and no duplicated architecture.

Preserve every existing uncommitted change. Do not reset, clean, revert, overwrite backups, or remove user assets. Keep the Fallen Matron / Withered Estate and Elder Hollow / ancient sanctuary as separate remote destinations well outside the village footprint. Do not pull either boss territory into the settlement or merge the two remote zones together.

## Art direction

Build a warm, welcoming woodland settlement with a distinct visual identity:
- Cozy handcrafted fantasy village, organic asymmetry, natural materials, readable silhouettes, soft warm lantern light, lush green canopy and small magical details.
- The main square should be the clear social heart, with a memorable focal landmark (well, fountain, ancient tree, statue or another fitting focal point selected from existing art capabilities).
- Establish a legible village entrance and a path network that naturally guides the player through the square to each district.
- Give the market a recognizable cluster and visual rhythm; keep merchant stalls, signs, crates, carts and warm lights grouped coherently.
- Give homes a residential lane with yards, fences, gardens, wood piles, benches, laundry or other grounded lived-in details where supported by existing assets.
- Make the elder/civic area quieter and distinct from the busy market.
- Give the shrine/river edge a calm, slightly magical atmosphere and a readable route connection.
- Use trees, hedges, rocks, flowers and small props to frame spaces, create sightlines and prevent the village from looking like buildings randomly scattered on a flat green plane.
- Avoid clutter: preserve navigable corridors, clear entrances, readable NPC approach space and boss/quest marker visibility.

This is an art-direction brief, not permission to invent unavailable final character art. Prefer the project's real existing assets and cohesive reusable prop scenes. Clearly identify any remaining placeholder art.

## Required design work

1. **Create a coherent authored master layout.** Treat the player camera view and the actual walkable space as the source of truth. Review the current positions and overlaps. Improve spatial composition, building orientation/spacing, landmarks, paths and transitions. Avoid random scatter for major buildings.
2. **Make the path network look finished.** Replace empty/unfinished path geometry with continuous, well-joined road surfaces and edges through bends/intersections. Keep paths readable in the isometric view. Connect to existing walkability/navigation/collision ownership; visual Line2D/Polygon2D alone is not functional navigation.
3. **Resolve depth sorting correctly.** Logical folders may remain for authoring, but depth-sensitive actors, buildings, furniture and trees must interleave under the canonical shared Y-sort strategy. Do not leave separate nested Y-sort contexts that cause canopies to draw over actors at the wrong depth. Preserve the existing player/NPC ground-contact sort origins.
4. **Add tasteful life and detail.** Use reusable scenes/nodes for signposts, fences, benches, lamps, barrels, market goods, garden beds, wells, bridges, etc. Batch tiny ground detail; never spawn one Node2D per grass blade or pebble. Keep counts bounded for performance.
5. **Lighting and atmosphere.** Add/assign soft light textures where appropriate, tune lantern energy/range against CanvasModulate/day-night, and ensure the village still reads clearly at day and night. Ambient effects should be subtle and not obscure navigation or characters.
6. **NPC and interaction composition.** Preserve existing NPC IDs, dialogue, quests, spawn ownership and interaction behavior. Place NPCs in believable spots with enough approach space; ensure labels, prompts and destination markers remain readable.
7. **Remote-zone separation.** Verify the village footprint and the two distant territories remain geographically distinct. Maintain clear routes/transition points to Elder Hollow and the Fallen Matron's Withered Estate; no visual spillover or accidental village props in their boss arenas.
8. **Node-first implementation.** Prefer reusable PackedScenes, authored scene placement, exported properties and Resources. Keep scripts as small coordinators. Do not create a new parallel village controller or duplicate world streaming, navigation, save, weather or day/night systems.

## Visual review and testing — mandatory

- Create/update a dedicated village preview or capture flow that uses the actual canonical live village scene and real assets.
- Run it in the Godot renderer at the actual game camera scale. Save before/after captures and inspect them, not just headless scene trees.
- Inspect at least: full village overview, entrance, central square, market, residential lane, civic/elder area, shrine/river edge, day and night, player/NPC crossing in front of and behind trees/buildings, and both remote-zone approaches.
- Run existing canonical village, modular village (if still applicable), modular forest, depth sorting, player movement, quest navigation and relevant world tests. Distinguish structural tests from actual visual inspection.
- Verify path connectivity and player traversability in-game, not merely metadata.
- Check for parse/runtime errors and git diff. Report exact commands, exit codes, pass/fail counts and capture paths.

## Definition of done

Greenward reads as one cohesive, attractive, memorable village from the live gameplay camera; districts are distinct and connected; paths are continuous and traversable; buildings/trees/NPCs depth-sort correctly; lighting works across day/night; the layout remains performant and node-based; existing quests/dialogue/save/world behavior is preserved; and the two remote boss zones remain separate and far away.

Do not call the work finished if only the scaffold is present, paths are still blank shells, or only headless structural checks pass.

## Final report

Include the design decisions, district layout, exact files changed, reusable nodes/scenes added, how navigation and depth sorting were integrated, remote-zone distance/separation checks, all test results, and inspected capture paths. List remaining placeholder art and unfinished polish honestly.
