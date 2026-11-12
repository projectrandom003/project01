# PROJECT FANTASY — Art Asset Pipeline (`assets/`)

> **Honest status:** This build ships **ZERO final painted assets for the 12 collectible characters** and **no audio**.
> Everything you see for them is procedural placeholder art generated at runtime. This
> folder is the *contract* for dropping in real art, not a gallery of finished
> work. See [`ASSET_STATUS.md`](ASSET_STATUS.md) for the per-class status table.
>
> **Exception:** `assets/characters/lilith/` holds final imported playable art for
> Lilith (72 world animations, portrait, combat sprite, full-body illustration).
> See [`characters/main/little_sister/SPEC.md`](characters/main/little_sister/SPEC.md).
>
> Authoritative docs: [`../documentation/ART_PIPELINE.md`](../documentation/ART_PIPELINE.md)
> and [`../documentation/VISUAL_STYLE.md`](../documentation/VISUAL_STYLE.md).
> Machine-readable contract: [`../scripts/art/asset_manifest.gd`](../scripts/art/asset_manifest.gd)
> (`AssetManifest.entries()` / `status_report()` / `validate_sheet_specs()`).

## The eight asset classes

| id | class | frame size | anchor | frames | expected path |
|----|-------|-----------|--------|--------|---------------|
| `character_sprites` | painted anime character sprites | 96 × 128 | bottom-centre (0.5, 1.0) | 8 | `res://assets/characters/<id>/world_sheet.png` |
| `character_portraits` | character portraits | 256 × 384 | top-centre (0.5, 0.0) | 1 | `res://assets/portraits/<id>/portrait.png` |
| `environment_tilesets` | environment tilesets | 512 × 512 | tile grid top-left | 1 | `res://assets/tilesets/<biome>_terrain.png` |
| `buildings` | buildings | 256 × 256 | bottom-centre (0.5, 1.0) | 1 | `res://assets/buildings/<id>/building.png` |
| `vegetation` | vegetation | 128 × 160 | bottom-centre (0.5, 1.0) | 1 | `res://assets/vegetation/<id>/plant.png` |
| `monster_sprites` | monster sprites | 96 × 128 (boss 128 × 192) | bottom-centre (0.5, 1.0) | 8 | `res://assets/monsters/<id>/world_sheet.png` |
| `skill_effects` | skill effects | 192 × 192 | centre (0.5, 0.5) | 6 | `res://assets/vfx/<id>/effect.png` |
| `ui_illustrations` | UI illustrations | 640 × 360 | centre (0.5, 0.5) | 1 | `res://assets/ui/<id>/illustration.png` |

Full per-class specs (import settings, naming, seam) live in
`AssetManifest.asset_spec(<id>)` / `AssetManifest.import_settings(<id>)`.

## 1. Source master → export

* Keep an editable **source master** (`.kra`, `.psd`, `.ase`, `.blend`, vector)
  outside `res://` (e.g. `art_source/`). Never edit exported sheets directly.
* Export **flattened, transparent RGBA8 PNG or WebP** (sRGB) into `assets/`.
* All world actors keep feet on **one identical foot baseline** (no foot-sliding)
  and an anchor of **bottom-centre (0.5, 1.0)**, Y-sorted at the ground point.
* Allowed colour direction is the GreenwardStyle palette (see VISUAL_STYLE.md);
  keep a 1–2 px dark readability outline at 1× scale.

## 2. Naming convention

* **`lower_snake_case`** everywhere. One **content-id folder** per subject:
  `assets/characters/mira_sol/world_sheet.png`.
* Character/monster sheet: `<id>/world_sheet.png`; per-state variant
  `<id>_<state>_<dir>.png` is also accepted.
* Other classes: `<content_id>/portrait.png`, `/building.png`, `/plant.png`,
  `/effect.png`, `/illustration.png`, `<biome>_terrain.png`.
* State ids (integer contract): `0 idle, 1 walk, 2 run, 3 interact,
  4 attack, 5 damage, 6 victory, 7 defeat, 8 cast` (CAST is Phase-4 additive).
  Direction ids: `0 down, 1 down_right, 2 right, 3 up_right, 4 up,
  5 up_left, 6 left, 7 down_left`.

## 3. Sheet layout (animated classes)

* **8 direction rows × `<frames>` columns**, 0-based frame index left→right.
  Row 0 = DOWN … row 7 = DOWN_LEFT. One row per direction so the feet stay on
  the same baseline.
* Authoritative per-state frame counts / fps / loop:
  `IDLE 5@9 loop, WALK 7@12 loop, RUN 7@14 loop, INTERACT 6@12 one-shot,
  ATTACK 6@15 one-shot, DAMAGE 2@12 one-shot, VICTORY 8@12 one-shot,
  DEFEAT 6@10 one-shot, CAST 7@12 one-shot`. These are
  `CharacterAnimator.STATE_FRAMES / STATE_FPS / STATE_LOOPING` + `CAST_*`.
* Slice the atlas into a Godot **`SpriteFrames`** resource (.tres): one animation
  per `"<state_name>_<dir_index>"` (e.g. `walk_2`, `cast_0`), `speed = fps`,
  `loop = loop-flag`. See `SpriteFramesActorSource.validate_sheets()` for the
  exact validation contract (9 × 8 animations, correct frame counts, non-null
  96 × 128 frames, correct loop flags).

## 4. Import settings (per class)

Apply in Godot's Import dock (`.import` files are generated, do not hand-edit):

| class | filter | mipmaps | compression | fix alpha border |
|-------|--------|---------|-------------|------------------|
| character_sprites | Linear | On | VRAM-compressed (lossless for UI) | On |
| character_portraits | Linear | Off | Lossless | Off |
| environment_tilesets | Linear | On | VRAM-compressed | On |
| buildings | Linear | On | VRAM-compressed | On |
| vegetation | Linear | On | VRAM-compressed | On |
| monster_sprites | Linear | On | VRAM-compressed | On |
| skill_effects | Linear | Off | Lossless | On |
| ui_illustrations | Linear | Off | Lossless (UI) | Off |

`AssetManifest.import_settings(<id>)` returns these dicts verbatim.

## 5. Register a real source (the replacement seam)

Character / monster sprites plug in through **`SpriteFramesActorSource`**:

```gdscript
# Build/drop a real .tres at res://assets/characters/<id>/world_sheet.tres, then:
var source := SpriteFramesActorSource.from_disk("mira_sol")
if source.has_frames() and source.validate_sheets().is_empty():
    actor_visual.set_frame_source(source)   # is_temporary() becomes false
```

* `from_disk()` tries `world_sheet.tres` then `world_sheet.png` and **never
  crashes** — on failure `has_frames()` is false, `is_temporary()` true,
  `frame()` returns null and `missing_reason` explains why.
* Every other class replaces its **procedural painter / seam** listed in
  `AssetManifest.replacement_seams()` (e.g. `procedural_art.gd _build_prop()` for
  buildings/vegetation, `portrait_view.gd` for portraits, `chunk_builder.gd`
  for tilesets, `ui/main_backdrop.gd` for UI illustrations). No gameplay code
  changes.

## 6. Fallback rule (never break the build)

If `has_frames()` is false, `frame()` returns null, or a
`(state, direction, index)` is missing, `ActorVisual` **keeps the procedural
placeholder** (`ProceduralActorFrames` / `procedural_art.gd`). `is_temporary()`
stays true until a real source is registered, and
`player.visual.using_temporary_art` stays true while the temporary demo sheet is
active. Content must NEVER crash on a missing asset.

## 7. The temporary demonstration character

`DemoCharacterFrames` builds an in-memory `SpriteFrames` for the player from
`ProceduralArt.character_frame()` cached textures. It is **TEMPORARY
procedural art, NOT final art** — `is_temporary() == true`, `loaded_from_disk ==
false`, `validate_sheets() == []`. Replace it with a painted `world_sheet.png`
via `SpriteFramesActorSource.from_disk()`.

## 8. Licensing

Third-party or commissioned art must be recorded in **`THIRD_PARTY_NOTICES.md`**
at the repository root with source, author, licence and attribution. Do not
commit any asset whose licence is unclear. This build contains **no third-party
assets** and **no audio files**; all placeholder art is generated in-code and
owned by the project.
