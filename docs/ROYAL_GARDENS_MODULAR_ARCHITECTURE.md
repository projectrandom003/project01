

# Royal Gardens Castle Collection — Modular Production Notes

## Scene catalogue

### Primary structural modules
- `reverie_royal_wall_x.tscn`: reusable illustrated wall segment with ground-footprint collision.
- `reverie_royal_wall_y.tscn`: rotated illustrated wall run with matching footprint collision.
- `reverie_royal_corner.tscn`: illustrated corner-tower module with footprint collision.
- `reverie_royal_gatehouse.tscn`: illustrated ornate gate sprite with a separate ground footprint.
- `reverie_royal_battlement.tscn`: illustrated wall crown segment with footprint collision.
- `reverie_royal_keep.tscn`: main illustrated palace facade with a ground-footprint collision.
- `reverie_royal_tower.tscn`: repeatable illustrated tower sprite with footprint collision.

### Garden assemblies
- `castle_flora_assembly.tscn`: blossom trees, wisteria, cypress, rose arches, gazebo, flower pedestals and individual flowering shrub/hedge sprites.
- `castle_props_assembly.tscn`: benches, guardian statues and royal banners.
- `castle_water_assembly.tscn`: illustrated angel fountain and water-zone markers.
- `reverie_royal_gardens_castle_collection.tscn`: composed palace facade, flank towers, illustrated wall modules, corner towers and ornate gate.

## Asset source and preparation
- Original downloaded collection is preserved under `assets/reverie_custom/royal_gardens/`, organized by the original asset categories.
- Cleaned, individually cropped runtime sprites are under `assets/reverie_custom/royal_gardens/production/`.
- Production crops preserve native pixel dimensions and alpha; no upscaling or resampling is applied during crop preparation.
- Atlas captions, neighboring sprite fragments and separator lines are excluded from the production crops where identified.
- Keep the original source sheets intact. If a crop needs refinement, regenerate it from the original source rather than repeatedly editing the production PNG.

## Coordinate and composition rules
- Keep the existing 64×32 isometric world convention: one grid step is 64×32 screen pixels.
- Place architectural sprites by their ground-contact origin; offset tall artwork upward without moving its collision footprint.
- X-axis wall runs advance down-right; Y-axis wall runs advance down-left.
- Keep the gate passage visually and physically clear.
- Wall, tower and keep collisions use ground-footprint polygons, not full visible silhouettes, so tall roof pixels do not block movement.
- Keep reusable parts as independent PackedScenes; assemblies should instance them rather than duplicate scene geometry.

## Art direction
- Use the downloaded illustrated sprites as the visible artwork: moonstone/ivory stone, blue-violet roofs, antique rose-gold trim, deep violet recesses, pink/wisteria blossoms and restrained warm window light.
- Do not add generic Polygon2D/Line2D shapes, colored rectangles or geometric placeholder buildings as visible architecture or garden decoration.
- Code remains appropriate for scene assembly, y-sorting, collision, interaction, navigation and subtle non-art runtime effects.
- Do not stretch sprites to fit a space. Prefer correct source variants and proportional scaling.

## Runtime collision notes
- Wall, tower and keep scenes own their ground-footprint collision polygons.
- Gatehouse collision must not obstruct the central passage.
- Decorative trees, shrubs, benches, statues, arches and gazebo are visual props; add collision only where gameplay requires it.
- Verify collision layer 1 against the player body's configured collision mask in the target map before release.

## Asset-first conversion pass (2026-11-17)
- Imported the user's downloaded `Reverie_Royal_Gardens_Individual_Sprites.zip` into `assets/reverie_custom/royal_gardens/`.
- Prepared a production sprite set from the palace, tower, gate, wall, corner tower, trees, shrubs, rose arch, gazebo, fountain and flower pedestal source images.
- Replaced visible keep, tower, gatehouse, wall, corner and battlement geometry with illustrated sprite artwork. Collision remains separate and footprint-based.
- Rebuilt the active castle composition around one palace facade, two flank towers, illustrated wall sections, corner towers and the grand ornate gate.
- Expanded flora with individual pink/purple/white shrubs and rose hedge sprites around the formal parterres.
- Replaced the earlier polygon-heavy flora/prop/water assembly artwork with the downloaded custom sprites.
- Godot 4.7.2 reimported the new production PNGs. The actual `castle_royal_gardens.tscn` loaded headlessly with exit code 0 after cleanup of scene-file contamination.
- Remaining QA: inspect the live scene at gameplay zoom, refine exact sprite scale/ground anchors and y-sort order, check gate passage and player collision, then run the full regression suite. A successful headless load is not proof of visual perfection.

## Production rule
The active Royal Gardens must remain asset-first. Do not reintroduce generic geometric artwork as a shortcut. Add missing visual assets as purpose-made sprites, then instance them through modular scenes.


## Courtyard composition pass (2026-11-17)
- Added the imported blue royal and lotus fountain sprites as the west/east water features, retaining the angel-tiered fountain as the central garden landmark.
- Replaced the placeholder prop arrangement with the dedicated gothic archway, royal banner, lantern post, robed guardian statue, ornate stone bench and flower bench sprites.
- Repositioned the new props into paired entrance and garden groupings with clear central circulation.
- Updated the full preview scene to instance the same custom castle, flora, props, water and pathway assemblies as the production art set.
- Reimported all eight newly prepared PNGs through Godot 4.7.2.
- Verified the full preview scene loads and the asset-first castle garden smoke test passes.
- Remaining: visual QA at gameplay camera zoom, refine positions and collisions, and replace/extend path coverage only with matching authored path artwork.


## Garden circulation and legacy preview cleanup (2026-11-17)
- Removed the repeated `path_cobble_01.png` sprite strip from `castle_pathways.tscn`; it was a separate non-custom texture and created a narrow, visually disconnected promenade.
- Retained the dedicated Royal Garden path/water atlas and its isometric TileMapLayer as the approved source for garden circulation artwork.
- Expanded formal rose parterres with paired hedge borders and pink, purple and white flowering shrub groupings using the bespoke extracted sprites.
- Expanded water landmarks to the custom blue royal fountain, lotus fountain and angel-tiered fountain sprites.
- Updated props with the custom gothic archways, banners, lantern posts, guardian statues and seating sprites.
- Replaced the legacy `royal_garden_environment_preview.tscn` polygon-decoration preview with the full asset-first preview assembly, preventing the older generic Polygon2D courtyard artwork from remaining the preview target.
- Verified the actual `castle_royal_gardens.tscn`, full preview and asset-first smoke test in Godot 4.7.2; all completed with exit code 0 / PASS.
- Remaining visual QA requires an editor/gameplay screenshot to confirm final path coverage, scale, sorting and collision behavior.


## Follow-up visual repair pass (2026-11-17)
- Replaced the repeated rectangular rose hedge-block sprite references in the formal parterres with the dedicated round rose shrub artwork to remove the hard black-backed box appearance.
- Removed horizontal atlas separator rows from the purple, violet and white flower-shrub production crops; verified the cleaned individual PNGs visually.
- Rebuilt the empty Paths TileMapLayer as a three-tile-wide ceremonial promenade with a widened entrance apron, using only the dedicated Royal Gardens stone-path atlas (65 cells, atlas row 0).
- Added a focused Godot validation script checking all path cells use the approved atlas and that the flora assembly no longer references the rectangular hedge-block sprite.
- Godot 4.7.2 asset reimport completed with exit code 0; focused path/flora QA passed; full castle garden asset-first smoke test passed.
- Collision red overlays are editor collision visualization, not runtime art; do not delete gameplay collision shapes to hide editor overlays.

- Added a symmetric promenade planting border: eight individually illustrated rose, white-flower and violet shrub sprites, placed outside the three-tile stone walkway with matching west/east offsets.
- Verified the full garden component smoke test after the additional sprite placements (Godot 4.7.2, exit code 0).


## Composition cleanup pass (2026-11-17)
- Audited the production PNG sprite set for alpha transparency; the inspected palace, gate, rose arch and shrub artwork uses transparent backgrounds. The red/orange shapes visible in the editor screenshot are collision debug overlays, not opaque image backplates.
- Replaced the three-lane promenade tile placement with one centered run of 22 authored isometric stone-path tiles.
- Reduced entrance crowding by redistributing the two side fountains, central fountain, guardian statues, gazebo and seating into a more open, symmetrical garden sequence.
- Verified the asset-first castle garden component smoke test in Godot 4.7.2 (exit code 0).


## Water layout cleanup (2026-11-17)
- Reorganized the 12 loose water atlas tiles into two contiguous 3x2 isometric pond footprints.
- Removed the old placements near the castle approach and aligned the new pond centers to the west/east fountain sprite centers (world positions 352,688 and 928,688).
- Kept the approved custom water tileset and preserved the existing WaterZones gameplay markers.
- Added a focused Godot validation script; confirmed exactly 12 water tiles, all from atlas source 0 / tile (0,2), grouped into the two intended footprints. Godot 4.7.2 QA passed.

## Reference composition pass (2026-11-18)
- Replaced the runtime StonePathways placement script with a reusable static road-surface scene. The scene contains six static Polygon2D cobblestone ribbons using the seamless custom `royal_cobble_ribbon_96.png` texture with pixel-space UVs and enabled texture repetition: the central grand promenade, mirrored west/east fountain loops, a grand fountain parterre loop and two connecting paths.
- castle_pathways.tscn and the legacy stone_pathways.tscn now instance the same static road assembly; no runtime path-cell painting is used.
- Enlarged the modular royal castle assembly to 1.30x and its keep to 1.22x while retaining the established entrance alignment.
- Extended the existing custom fence atlas assembly with a front perimeter fence, a central ornate gate sprite, decorative gateposts and outer side fence runs. Added eighteen additional individually placed flower-shrub sprites around the lower and outer garden loops.
- Replaced preview-only generated lighting and camera scripts with authored scene nodes. The fountain and promenade glows are static PointLight2D nodes using a GradientTexture2D subresource.
- Replaced the gameplay garden light's generated radial image with a static GradientTexture2D resource in castle_garden_light.tscn; the lighting component now instances the authored light scene without creating a texture at runtime.
- Godot 4.7.2 smoke tests passed for both castle_royal_gardens.tscn and reverie_royal_gardens_full_preview.tscn; baked isometric terrain validation remained PASS.
- GitHub publishing was not part of this pass.
- Kept the original 133-cell baked Paths layer hidden as a preserved legacy reference. The six-ribbon road assembly now supplies the complete central promenade and garden branches in both the live map and the preview, avoiding dependence on the intentionally hidden TilemapCandidate terrain instance.


- Reframed the full-scene preview camera to position (640, 620) at 0.44 zoom for a balanced castle-to-garden review composition.
- Re-captured the live Godot preview and visually checked the full castle-to-garden layout; the continuous textured branches now join the central promenade and frame the fountain courts, with the gate, flowering parterres and perimeter fence retained.
- Re-ran the production castle scene smoke test, full preview scene smoke test and baked isometric layer validation in Godot 4.7.2. All passed; baked scene reports 2,929 ground cells, 44 variations, 133 path cells, 12 water cells, 6 flower cells and 8 layers.

- Completed the decorative perimeter with north-corner fence runs, continuous outer side sections and an enlarged front entrance gate; the existing perimeter collision remains intact.
- Set the road ribbon half-width to 42 world units after live visual comparison; this keeps the central route and side courts clearly readable while retaining the custom cobblestone detail.

- Reframed the full-scene preview camera to position (640, 720) at 0.32 zoom so the castle, gate, three fountains, side garden loops and lower parterre read together in a single overview.
- Final Godot 4.7.2 QA: production castle scene load PASS; full preview scene load PASS; baked isometric terrain PASS (2,929 ground cells, 44 variations, 133 preserved legacy path cells, 12 water cells, 6 flower cells, 8 layers); static road/flora/atmosphere QA PASS (6 ribbons, 38 fountain-bed sprites, 5 preview lights, ambient petals enabled).
- The central promenade and five branching garden ribbons are all authored from the same seamless custom cobblestone texture and shared by the production map and preview scene.

## Garden finish pass (2026-11-18)
- Added a reusable `castle_road_edge_transitions.tscn` module: 45 individually placed cells from the existing hand-painted isometric ground atlas, layered between grass and custom cobblestone ribbons.
- Added `castle_pathside_planting.tscn` with 16 individually positioned pink, white, violet and rose shrub sprites to strengthen the side-loop edges.
- Added `castle_upper_parterre_planting.tscn` with eight custom shrub sprites to fill the upper castle garden shoulders symmetrically.
- Refined the west/east fountain loops and central parterre road centerlines with additional hand-authored control points for softer curves; the resulting six road ribbons remain static scene geometry using the custom cobblestone texture.
- Shifted the full preview ambient palette toward a cooler twilight violet and restored the overview camera to 0.32 zoom for whole-garden review.
- Godot 4.7.2 QA passed for the production castle, full preview and static asset checks: 6 custom road ribbons, 45 hand-painted edge transition cells, 38 fountain flowerbed sprites, 16 pathside sprites, 8 upper-parterre sprites and 5 preview lights.
- Final overview camera framing is position (800, 800) at 0.32 zoom, keeping the upper castle and lower entrance in the review composition.

## Outer cloister finish pass (2026-11-18)
- Added `castle_outer_cloister_niches.tscn` as a reusable paired west/east garden assembly, using the custom illustrated wall segment, banner wall, spire tower, flower bench, lantern post and flowering shrub assets.
- The paired niches add eight architectural sprites and eight garden/furnishing sprites, framing the outer courts without blocking the central gate or promenade.
- Added two low-energy warm lantern glows to the full-scene preview at the west/east cloister lantern positions; the fountain and promenade lighting remains unchanged.
- Extended static asset QA to verify both cloister architecture groups and the two added preview lights.

## Northern castle approach pass (2026-11-18)
- Added `castle_north_approach_courts.tscn`, a paired west/east ceremonial approach assembly using the existing custom tower module, ornate wall segment, royal banners, lantern posts, guardian statues and flowering shrubs.
- Each court is a separate y-sorted subassembly with seven purpose-built illustrated sprites; the central cobblestone promenade remains unobstructed.
- Added two subtle warm approach lantern glows to the preview lighting scene, bringing the authored preview lights to nine.
- Extended the static garden QA to verify both approach courts and their complete seven-sprite assemblies.
- Added `NorthCastleThresholdApron` as a hand-authored, rounded static Polygon2D plaza using the same seamless custom cobblestone texture and UV mapping as the existing road assembly; it widens the central promenade into a ceremonial threshold immediately before the gate.
- Increased the paired north approach spire, wall, banner and lantern sprite scales for stronger visual hierarchy while preserving left/right mirroring and keeping the central passage open.
- Added paired `OuterGardenSeatingAlcoves` at the west/east outer garden edges. Each uses the custom flower bench, rose hedge block, distinct flowering shrubs and a lantern post; both are separate y-sorted assemblies.
- Added two low-energy warm bench lantern glows to the preview lighting rig and extended static QA to verify all ten seating sprites and both light anchors.
- Added `SouthOuterCloisterExtensions`, a paired west/east lower perimeter architecture pass using the existing wall segment and banner-wall art, with rose and white flowering accents. Mirrored placement extends the cloister rhythm down the garden sides without changing the central promenade.

- Restored the six authored static cobblestone ribbons from the dedicated road-authoring scene: central promenade, west/east fountain loops, grand fountain parterre loop, and west/east parterre connectors. Each ribbon retains its explicit polygon UVs and the approved custom cobblestone texture; the assembly sits at z=-28 so the terrain and road-edge layer ordering remains deliberate.
- Corrected the playable world's PathwayTiles parent z-index to 10. The road assembly's effective z becomes -18, just above the generated grass Terrain at -20; previously the child road layer could be sorted behind the production terrain even though the isolated preview showed it correctly.
- Added tools/qa_royal_garden_road_ribbons.gd. It loads the playable world, verifies all six Polygon2D ribbons, confirms authored UV/texture assignments, and checks that the effective road z-order is above terrain.
- Validation: playable world scene load, full preview scene load, baked isometric layer validation, and the new playable road-ribbon QA all pass in Godot 4.7.2. New QA reports six ribbons and effective road z=-18 above terrain z=-20.

- Refined the road hierarchy once more: the central promenade now begins at the castle threshold instead of running behind the keep, and a dedicated NorthCastleThresholdApron widens the arrival court. The six garden ribbons plus the threshold apron are seven individually named Polygon2D nodes, all using the authored UV mapping and custom cobblestone texture.
- Updated the road QA contract to require the seventh apron node. The enrichment suite now passes again with 7 road modules, 38 fountain-bed sprites, 11 preview lights, 45 hand-painted edge cells, and all existing pathside/upper-parterre/cloister/court/seating assemblies present.
- Final road QA confirms seven Polygon2D modules, matching polygon/UV counts, the custom cobblestone asset, and playable effective z=-18 above terrain z=-20.

## Thorough reference-composition refinement (2026-11-18)
- Corrected the shared road/terrain draw order. The hand-painted transition tilemap now renders at absolute z=-19, between terrain (-20 in the playable world / -30 in the preview) and the cobblestone ribbons (-18 effective z in both). The preview PathwaySystem is aligned to z=10 so its road assembly matches the playable PathwayTiles ordering.
- Re-authored the west and east fountain walkways as open U-shaped ribbons rather than closed self-intersecting loops. They now curve around the side fountains and open toward the central promenade.
- Added width hierarchy to the static road modules: central avenue 96px, side fountain loops 68px, central fountain court 84px, parterre connectors 64px, lower gate walks 60px, and castle threshold apron 100px. All surfaces continue to use the custom royal_cobble_ribbon_96.png artwork and authored UVs.
- Added two lower curved garden walks that connect the south parterre connectors to the new side entrances, bringing the static road assembly to nine named Polygon2D modules.
- Added a modular castle_side_gate_arches.tscn using the custom gothic_archway artwork. Opened two matching gaps in the front perimeter fence, removed the four obstructing rail segments, and placed mirrored side arches at the new openings.
- Increased the north and outer side fence rail segment scale to 1.9 so adjacent 32x32 custom fence pieces meet continuously instead of leaving visible gaps. The front fence retains its close-spaced rails and central ornate gate.
- Enlarged the castle collection to 1.4x, the keep to 1.30x, and the gatehouse to 0.98x while keeping the keep centered and adjusting the gatehouse position to preserve the entrance alignment.
- Hid the central rose gazebo from the shared garden composition so it no longer blocks the promenade to the main gate; the lower benches and the main entrance remain.
- Added six existing custom blossom/wisteria trees in a mirrored outer woodland frame to soften the grass margins around the perimeter.
- Reframed the full-scene preview camera to position (990, 800) and zoom 0.36. This is a preview-only framing change; it does not alter the gameplay camera.
- Added/updated QA for open fountain ribbons, nine road modules, road/edge/terrain ordering in both preview and playable scenes, castle scale, side-gate arches, hidden central gazebo, and six outer woodland trees.
- Godot 4.7.2 validation passed: production scene and full preview scene load; static asset QA, road ribbon QA, render-layer QA, castle/fence QA, and baked isometric layer validation all pass. Baked terrain remains ground=2929, variations=44, paths=133, water=12, flowers=6, layers=8, iso_projection=matched.
- Latest visual review: artifacts/qa/royal_gardens_final_woodland_review_20261118.png. GitHub publishing was not part of this pass.
