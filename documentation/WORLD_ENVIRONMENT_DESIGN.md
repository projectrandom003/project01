# Project Fantasy — World Environment Art Direction

## Goal

Make the existing explorable world feel authored, atmospheric and memorable before adding more gameplay systems. This is a visual-quality pass over the current regions, not a content-expansion phase.

## Global visual language

- Dark-fantasy storybook realism: painterly shapes, believable natural silhouettes and restrained magical accents.
- Strong value hierarchy: readable ground plane, layered vegetation, recognizable landmarks and clear player routes.
- Avoid uniform scatter, repeated circles, straight spoke-like paths, flat green carpets and excessive glowing props.
- Use negative space deliberately around villages, shrines, encounter spaces and points of interest.
- Keep the player readable against the environment; foreground foliage must not obscure interaction targets or combat silhouettes.

## Greenward — The Whispering Glade

**Identity:** an ancient, overgrown woodland settlement where nature has reclaimed old stonework.

- Ground: deep moss, muted fern greens, damp soil, dry leaf litter on ridges and softly worn earth paths.
- Vegetation: dense irregular groves, mixed tree species, fern and berry undergrowth, occasional flowers rather than a uniform flower carpet.
- Architecture: weathered timber, moss-covered stone, hand-built bridges, small warm lanterns and a few strong village silhouettes.
- Landmarks: the Listening Stones should read as a deliberate ruin; the Hollowed Grove should feel corrupted and unnaturally quiet; the river should feel like a natural route through the map.
- Lighting: soft canopy shade, warm amber near habitation, cool teal only around old magic.

## Moonpetal Hollow

**Identity:** a quiet silver-birch vale under a cold, borrowed moon.

- Ground: slate-blue grass, muted silver stone, dark water and pale worn trails.
- Vegetation: silver birch groups, drooping willow shapes, sparse luminous flowers and low glimmering mushrooms near damp ground.
- Architecture: pale stone, moon shrines, restrained violet-metal accents and cool lantern light.
- Lighting: cool blue ambient fill, soft fog and small localized magical glows. Avoid flooding the whole scene with bright cyan.

## Environment layering

1. **Terrain base:** continuous moisture-blended biome color, broad moss/soil mottling and subtle flecks; avoid visible tile bevels.
2. **Ground cover:** individual blade/leaf silhouettes with varied scale and density.
3. **Midground props:** clustered vegetation, rocks, logs, reeds and low ruins.
4. **Tall silhouettes:** trees and architecture with species-specific profiles and clear bottom anchors.
5. **Atmosphere:** region-specific fog, time-of-day color, weather and restrained light pools.

## Implemented in the current environment pass

- Replaced the flat terrain tint with layered world-space mottling, damp moss patches, dry leaf variation and very soft directional light.
- Blended adjacent biome palette colours continuously from the moisture field and removed the dark tile-edge bevel so the ground reads as a more continuous forest floor.
- Reworked the main Greenward tree painter around a branch-led, irregular crown with exposed roots, asymmetrical leaf clusters and restrained ancient-tree runes; tree variants now add leaf facets rather than more circular canopy blobs.
- Added recessed windows, a readable framed entrance, varied thatch courses, exposed rafters and subtle weathering to the village hut and cottage painters.
- Rebuilt the willow silhouette with a curved trunk, lateral boughs and hanging leaf curtains; added more faceted stone, mineral seams, arch fractures and bridge blockwork.
- Deepened the Greenward boss arena with layered canopy masses, hanging roots and broken standing stones; the canopy silhouettes now use irregular branch-led polygons instead of repeated circular crowns.
- Disabled the unsupported 2D MSAA setting for the GLES3 compatibility renderer, removing an avoidable renderer warning and unused antialiasing request.
- Added ribbed columns, broken glass fragments and thorn growth to the Withered Estate arena.
- Throttled animated combat backdrops to 30 redraws per second; slow fog, motes and ritual pulses do not need a full redraw every rendered frame.
- Raised world locomotion playback modestly for Kael, Lilith and Gerald, driven by actual velocity so movement feels less stepped without changing the shared animation frame-count contract.
- Added a continuous in-between pose layer for frame-backed actors: Kael gets a lighter stride with stronger airborne lift, Gerald gets a heavier landing squash and restrained cloak sway, and Lilith gets a weightless hover rather than foot-plant motion.
- Added short directional turn anticipation through a subtle body lean, plus continuous idle breathing/hover motion; these are procedural transform poses between authored frames, not newly painted sprite frames.
- Applied lore-height ratios against Kael's 183 cm baseline: Gerald 200 cm (1.093x), Kael 183 cm (1.0x), Lilith 130 cm (0.710x). The sprite geometry remains bottom/hover anchored and collision hitboxes are intentionally unchanged.
- Removed redundant per-frame redraw requests from frame-backed actor sprites; redraws now follow actual frame changes or active visual overlays.
- Added idle breathing/sway and a stronger anticipation-snap-recoil attack for the Fallen Matron cutout; other bosses now have heavier attack, hit and defeat body reactions.
- Spread the three village NPCs farther apart and shifted the market stall away from the central gathering space to improve readability.
- Reduced default prop scatter and companion-tree frequency to give the village and trails more breathing room.
- Made water opaque at tile joins and moved its reflection pattern into world space to reduce the visible diamond grid.
- Added uneven thatch courses, wall grain and weathered foundation accents to the village hut painter.
- Softened the water reflections and moved the animation pattern into world space to avoid identical bright ripples repeating on every diamond.
- Reduced high-saturation flower/mushroom scatter and moved three roaming enemy groups away from the village green to restore breathing room.
- Replaced the circular ground-cover mask with a tuft/leaf silhouette.
- Increased forest-floor detail density while preserving one batched detail MultiMesh per chunk.
- Increased the prop budget and adjusted Greenward's biome colors and spawn weights toward woodland structure rather than open grassy scatter.
- Added deterministic companion-tree and understory clustering for Greenward and Moonpetal tree types.
- Narrowed paths and changed landmark routes from straight spokes to gently meandering trails; small NPC POIs no longer generate their own path spokes.
- Gave Moonpetal Hollow a deeper slate-blue ground and water palette, with stronger birch grouping and less flower saturation.

## Constraints

- Do not add new gameplay systems during this pass.
- Keep chunk generation deterministic and preserve the existing streaming API.
- Keep terrain, water and detail batched; no per-tile Sprite2D nodes.
- Respect mobile performance caps.
- Keep all art-status reporting honest: procedural work is still placeholder art, not final painted assets.

## Remaining visual work

- Replace procedural placeholders with authored, licensed environment art: terrain tiles, tree canopies, rocks, ruins, village buildings, bridges and water details.
- Review actual in-game screenshots at the target resolution; headless tests cannot judge visual quality.
- Tune prop density, overlap, z-order, shadows and lighting from real gameplay camera views.
- Give every major POI a unique silhouette and a distinct ground composition.
- Add restrained environmental animation only where it improves life: canopy sway, water movement, drifting pollen/fireflies and small ambient wildlife.
