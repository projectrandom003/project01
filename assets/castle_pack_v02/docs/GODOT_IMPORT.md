# Godot 4.x import recommendations
Project Settings: Rendering > Textures > Default Texture Filter = Nearest; Display > Window > Stretch mode = canvas_items (or viewport) with integer scale; Rendering > 2D > Snap 2D Transforms to Pixel = on.
Per-texture import: Compress Mode = Lossless; Mipmaps = off; Filter = Nearest; Repeat = Disabled; Fix Alpha Border = on.
TileMapLayer: TileSet tile_shape = Isometric, tile_layout = Diamond Down, tile_size = 64x32. Terrain PNGs (64x32) go in an atlas; water_tile_anim = 4-column animated tile @ 6 fps.
Y-sort: enable y_sort_enabled on the parent Node2D of all objects; Sprite2D centered=false with offset = manifest `sprite2d_offset_if_centered_false` so node origin == pivot.
Collision: use footprint diamond (W*32 x D*16 at ground) as StaticBody2D CollisionPolygon2D, never the full sprite.
Lights: PointLight2D with glow_warm/glow_cyan textures at (0,-46) on lanterns; or Sprite2D blend_mode=Add. Light shaft: Add blend.
Sprite sheets: Sprite2D hframes = manifest `frames[0]`, or SpriteFrames from the sheet using `frame_size`.
Roofs/doors: attach as child Sprite2D of tower/wall at the anchor noted in the manifest.

## v0.2 notes
- Drop-in replacement: every filename, manifest ID, image size, pivot, frame layout and footprint is identical to v0.1, so existing TileSets, scenes and offsets keep working. Re-import textures only.
- Terrain patterns (grass, cobble, water) are periodic on the 1-cell lattice, so tiles join seamlessly in a TileMapLayer without extra setup.
- Foliage uses a dark-teal outline (#0C1A26); keep Nearest filtering and Lossless compression.
- Fountain emitter for fountain_spray_anim is unchanged at (0,-85) from the fountain pivot.
- `manifest.json` gained `revision` and `status` ("regenerated" | "unchanged") fields per asset; all other fields are unchanged.
