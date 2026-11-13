# PROJECT FANTASY — Asset Status (`assets/`)

> **Three final playable characters (Gerald, Lilith, Kael); the other collectibles are ZERO final painted assets. There is also NO audio.**
> Every class below is served by a **procedural placeholder** that IS present and
> rendering right now (`TEMPORARY`), while the expected **final painted file is
> MISSING** from disk. These are two orthogonal facts: the fallback exists, the
> final art does not. Nothing in this table is a wish — it reflects reality.
> See [`README.md`](README.md), [`../documentation/ART_PIPELINE.md`](../documentation/ART_PIPELINE.md),
> [`../documentation/VISUAL_STYLE.md`](../documentation/VISUAL_STYLE.md), and the
> machine-readable [`../scripts/art/asset_manifest.gd`](../scripts/art/asset_manifest.gd).

## Honest counts (from `AssetManifest.status_report()`)

| bucket | count | meaning |
|--------|-------|---------|
| **FINAL** | **0** | no class ships a real painted asset |
| **TEMPORARY** | **8** | every class has a present procedural fallback |
| **MISSING** | **8** | every expected final file is absent on disk |
| total classes | 8 | — |

`counts.final == 0`, `counts.temporary == 8`, `counts.missing == 8`, `total == 8`.
`AssetManifest.check_disk()` returns `false` for all eight expected paths.

## Per-class status table

| # | class id | status (what renders) | final file on disk | expected final path | exact replacement seam |
|---|----------|-----------------------|--------------------|---------------------|------------------------|
| 1 | `character_sprites` | **TEMPORARY** (procedural fallback) / **MISSING** (final file absent) | MISSING | `res://assets/characters/player/world_sheet.png` | `ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>))` → `scripts/world/actor_frame_source.gd` + `scripts/art/sprite_frames_actor_source.gd` |
| 2 | `character_portraits` | **TEMPORARY** / **MISSING** | MISSING | `res://assets/portraits/player/portrait.png` | `scripts/ui/portrait_view.gd` (PortraitView) / ContentDB character portrait lookup |
| 3 | `environment_tilesets` | **TEMPORARY** / **MISSING** | MISSING | `res://assets/tilesets/greenward_terrain.png` | `scripts/world/chunk_builder.gd` terrain MultiMesh + `scripts/world/procedural_art.gd` `prop_texture()` |
| 4 | `buildings` | **TEMPORARY** / **MISSING** | MISSING | `res://assets/buildings/watchtower/building.png` | `scripts/world/procedural_art.gd` `_build_prop()`/`_paint_kind()` + `GreenwardStyle.prop_palette()` |
| 5 | `vegetation` | **TEMPORARY** / **MISSING** | MISSING | `res://assets/vegetation/willow_tree/plant.png` | `scripts/world/procedural_art.gd` tree/fern/flower painters via `_build_prop()` + `GreenwardStyle.prop_palette()` |
| 6 | `monster_sprites` | **TEMPORARY** / **MISSING** | MISSING | `res://assets/monsters/glade_wisp/world_sheet.png` | `ActorVisual` (`Kind.MONSTER`) via `scripts/world/actor_frame_source.gd` + `SpriteFramesActorSource` |
| 7 | `skill_effects` | **TEMPORARY** / **MISSING** | MISSING | `res://assets/vfx/wind_slash/effect.png` | `scripts/combat/combat_engine.gd` VFX hooks / `scripts/world/procedural_art.gd` `soft_glow()` |
| 8 | `ui_illustrations` | **TEMPORARY** / **MISSING** | MISSING | `res://assets/ui/title/illustration.png` | `scripts/ui/main_backdrop.gd` + `scripts/ui/ui_theme.gd` |

## What actually exists on disk

* `icon.svg` + `icon.svg.import` (the app icon) — the only image file tracked by `AssetManifest`.
* `assets/characters/gerald/`, `assets/characters/lilith/`,
  `assets/characters/kael_avatar/` — the protagonists' final playable art:
  `world_sheet.tres` (72 animations / 432 frames), `portrait.png` (256x384),
  `combat_sprite.png` (128x192), `full_body_illustration.png` (1024x2048) and
  the per-state `<state>_sheet.png` atlases. Tracked by
  `MainCharacterRoster`, NOT by `AssetManifest`.
* **No** `.png` / `.webp` / `.jpg` / `.tres` / sprite sheets / audio anywhere else.
* All prop textures, character frames, glows and lights are generated at runtime
  by `scripts/world/procedural_art.gd` / `procedural_actor_frames.gd`.
* `DemoCharacterFrames` builds an **in-memory, TEMPORARY procedural
  `SpriteFrames`** for the player — it is NOT a real painted sheet and
  `loaded_from_disk == false`.

## Notes

* No device profiling was performed; the build is validated with Godot's
  headless dummy renderer.
* The Phase-3 animation contract (8 states × 8 directions) is preserved; CAST is
  a strictly **additive 9th state**.
* When real art lands, record licences in `THIRD_PARTY_NOTICES.md`. Currently
  there are **no third-party assets and no audio**.
