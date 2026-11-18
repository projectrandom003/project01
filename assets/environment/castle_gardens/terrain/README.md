# Royal Garden Modular Terrain and Flora

## Isometric terrain atlases

All three atlases are 128Ã—128 PNGs, split into sixteen 32Ã—32 art regions.

- `royal_garden_ground_atlas_32x32.png` â€” grass ground and natural variations
- `royal_garden_paths_water_atlas_32x32.png` â€” stone paving, edging and water details
- `royal_garden_vegetation_atlas_32x32.png` â€” flower clusters, lavender, shrubs, hedge segments and topiary

The logical world grid remains isometric at 64Ã—32, matching `IsoMath`. The atlas art stays 32Ã—32; the generated isometric TileSets use a 64Ã—32 logical cell and a 32Ã—32 texture region with a 16 px horizontal texture origin.

## Isometric TileSets

- `royal_garden_ground_isometric_tileset.tres`
- `royal_garden_paths_water_isometric_tileset.tres`
- `royal_garden_vegetation_isometric_tileset.tres`

The TileSet layout is Diamond Down. A geometry validator confirms that the TileMapLayer coordinate deltas match `IsoMath.grid_to_world`:
- grid +X â†’ screen (+32, +16)
- grid +Y â†’ screen (-32, +16)

## Baked editor-authored TileMapLayer scene

`scenes/world/castle_gardens/components/royal_garden_isometric_layers_baked.tscn`

Eight independently editable TileMapLayer nodes:
1. BaseGround â€” 2,929 ground cells
2. GroundVariation â€” intentionally empty until subtle authored variants are ready
3. Paths â€” editor-baked 133-cell promenade, pool connector and forecourt
4. Water â€” 12 editor-baked pond cells; the live Water component remains separate
5. FlowerDetails â€” six marker-driven flower placements
6. Hedges
7. Vegetation
8. Foreground

The bake uses the existing authored bounds, `CastleLayout.covers_screen_rect`, and random seed 9001. The resulting scene stores its cell placements, so the runtime does not need to regenerate these tile cells.

The live Royal Gardens scene is intentionally unchanged at this stage. The baked tilemap is a validated integration candidate, not yet a replacement for the live terrain renderer.

## Modular tree props

Three reusable multi-cell trees are available in `assets/environment/castle_gardens/trees`:
- Blossom tree â€” 96Ã—128 px
- Broadleaf tree â€” 96Ã—128 px
- Evergreen tree â€” 96Ã—128 px

Each tree scene has a foot-anchored Sprite2D, Y-sorted root and trunk collision. `royal_garden_tree_preview.tscn` arranges all three variants for editor inspection.

## Validation

- `validate_royal_garden_isometric_layers.gd`
- `validate_royal_garden_baked_layers.gd`
- `validate_royal_garden_tree_scenes.gd`
- `validate_royal_garden_tree_preview.gd`

The full project test runner completed with 2,536 passed and 0 failed.

## Live-world migration seam

The live `Terrain` composition now mounts the baked TileMapLayer scene as `TilemapCandidate`. It remains hidden by default, so the playable map continues to use its legacy terrain renderer. This keeps the candidate available in the editor without changing current visuals, collisions, pathways, water, or save behavior.

To opt into the baked renderer for visual QA, set `Terrain/Configuration` metadata `use_baked_tilemap = true`. The terrain component then hides the legacy `Ground` and `GrassDetails` renderers and shows the baked TileMapLayer scene. Set it back to `false` to restore the legacy renderer. This is a reversible QA switch, not a claim that the final live-world migration has been approved.


## Courtyard composition pass (reference-inspired)

The editor preview now includes a separate `RoyalGardenCourtyardDecorations` composition with eight independently editable Node2D groups: Fountains, Seating, Lighting, Flowerbeds, FloweringShrubs, HedgeBorders, and Trees. It instances existing Royal Gardens pack props and the three authored tree variants: two tiered fountains, four stone benches, six warm gold lanterns, eight flower patches, six flowering shrubs, four hedge sections, and ten trees.

The baked path mask was narrowed to a single central royal promenade, two short diagonal approaches to the reflecting pools, and the compact castle forecourt. The previous broad cross-garden avenues were removed from the preview bake. GroundVariation remains empty to avoid high-contrast square speckles; the BaseGround atlas carries the natural grass texture. The live playable map is still untouched; this remains an editor preview for visual review.

The reference-inspired preview also adds a dedicated Architecture group with a castle entrance, a centered south gate, fourteen south-wall modules, and eighteen side-wall modules. The preview validator now checks all eight prop groups and their composition counts. The separate live map remains unchanged pending in-game visual approval.

## Courtyard refinement pass

The main promenade is now three cells wide and reaches the south gate. A single cross-courtyard connector links both reflecting-pool approaches; the previous wide cross-garden paving has not returned. The side enclosure extends to the authored map edges, and the south wall is centered around the gate opening. The preview has 10 trees and 34 architecture instances. The preview and baked-layer validators pass; the live playable world remains unchanged.

