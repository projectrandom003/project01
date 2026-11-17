# Project Fantasy — Visual & Technical Spec v0.2 (Castle & Royal Gardens)

## Projection & grid
- 2:1 isometric (dimetric). Tile diamond = 64x32 px. 1 cell = 1 tile.
- Axes: +X = screen right-down, +Y = screen left-down. Visible faces: LEFT face (faces +Y), RIGHT face (faces +X).
- Footprint WxD cells -> image width (W+D)*32.

## Scale (monumental rule)
- Player reference: 40 px tall (1.25 tiles). Never ship the placeholder.
- Doors/arches >= 64-72 px. Garden walls/hedges 40 px. Curtain wall 128 px (3.2x). Gatehouse 160 px (4x). Tower shaft 192 px + roof ~116 px (~7.7x). Trees 128 px (3.2x).

## Lighting & outline
- Key light from top-left: top faces lightest, left faces mid, right faces darkest (~0.64x of left).
- 1 px external outline, color #090B1C, baked into every standalone object. Terrain tiles have no outline.
- No anti-aliasing on hard art; soft alpha only on effects (glows, shafts, shadows).
- Contact shadows are separate (shadow_blob_64), not baked.

## Palette
midnight #0E1228 / #161E42 / #222E60 · silver #C8D2E6 · gold #E8BE5C · magic cyan #5AE6F0
grass #243E44 #307052 #408C5C #68B268 · blossom #78386E #B05696 #E88CBE · stone (L) #6876A8 (R) #424E80 (top) #96A2C8

## Pivot convention
- Pivot = center of the object's footprint ON THE GROUND (pixel coords from top-left of the PNG).
- Exceptions: trees/lanterns/bushes = trunk/pole base; effects = emitter/center; doors = bottom corner touching wall.
- Pivot is the Y-sort origin. Manifest gives Sprite2D offsets for centered=true and false.

## Folders
assets/{environment/{terrain,architecture,flora,props,water},effects,characters,ui}  (world/ reserved for future chunk scenes)

## Naming
snake_case, `<thing>_<variant>_<NN|orientation>`; sheets end in `_anim`; PLACEHOLDER suffix = never ship.

## Rules honoured
No existing assets touched (fresh folder). No character identities invented. Individual assets only; the preview is a composite for review.

## v0.2 refinement rules (additions)
- Shading: 5-6 step hue-shifted ramps (cool shadows, warm highlights), ordered Bayer dithering, no random-noise shading.
- Foliage: layered clumps lit from top-left, lower-right shaded, selective dark-teal outline #0C1A26, sparse magical glints.
- Stone: varied ashlar blocks with bevels, plinth, corbel/machicolation cornices, lancet windows, gold string courses, moss near the base.
- Gothic arches are ogival (pointed): width = 2*hw, rise = 1.7*hw above the spring line.
- Terrain: patterns periodic on the 64x32 cell lattice for seamless tiling.
- Compatibility contract: sizes, pivots, footprints, frame layouts and filenames are frozen from v0.1.

## Known v0.2 limitations
- Procedural pixel art, not hand-painted anime quality; foliage clumps remain somewhat round.
- Missing: inner-corner grass/path transitions, pond shore rim, waterfall, bridge, alternate roofs, wind-sway foliage frames.
- Wall/tower tops are walkways without crenellation (merlons would require taller canvases, a breaking change).
- Doors are tuned for the LEFT face of wall_segment_x.
- fountain_spray_anim, glows, light shaft, motes, shadow blob, UI panel and the scale ruler were not refined in this pass.
