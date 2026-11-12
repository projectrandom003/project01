# Kael Ashford — Character Art Spec (`kael`)

> **SPECIFICATION ONLY — no final artwork exists for this character. Status: MISSING (final) / TEMPORARY (procedural fallback).**
>
> ZERO final assets exist. Every shipped visual is RUNTIME PROCEDURAL PLACEHOLDER art generated in code.
> This document is a CONTRACT/SPECIFICATION for FUTURE external image generation. **No final artwork
> was generated or fabricated in this phase**, and no image/binary file exists at any path below.
> See `assets/CHARACTER_ART_PIPELINE.md`, `assets/GENERATION_PROMPTS.md`, `assets/ASSET_PRODUCTION_MANIFEST.md`.

## 1. Identity (verbatim from `resources/data/characters.json`)

| field | value |
| --- | --- |
| id | `kael` |
| display_name | Kael Ashford |
| title | Blade Without a Banner |
| race | Human |
| element | fire |
| rarity | rare |
| role | Damage |

These identity fields are reproduced exactly so that
`CharacterArtSpec.for_id("kael").race == ContentDB.get_character("kael").race` (and the other five fields) hold.

## 2. Palette (exact from `characters.json`)

| role | hex |
| --- | --- |
| `hair` | `#4a3020` |
| `primary` | `#5a3a2a` |
| `secondary` | `#c96f3a` |
| `accent` | `#ffcf6a` |
| `skin` | `#e8b890` |

- **hair_color:** `#4a3020 (dark umber-brown)`

## 3. Authored art direction (consistent shared anime-fantasy style)

- **physical_appearance:** Lean, scarred human sellsword with a weathered face, a crooked nose, one sun-bleached eyebrow and the relaxed, ready stance of someone who has fought too many pointless wars.
- **hair_style:** Short, rough dark-umber hair singed at the tips, with a jagged old burn along one side.
- **hair_color:** #4a3020 (dark umber-brown)
- **outfit:** Worn leather-brown brigandine with burnt-rust wraps, mismatched scavenged pauldrons, a blank tabard with the banner emblem burned away and travel-worn boots.
- **accessories:** A charred banner-ribbon kept as a belt tie, a coin pouch and a small unmarked token for the one person he fights for free.
- **weapon:** A plain, well-used longsword with ember-gold etching along the fuller, its hilt wrapped in scorched leather.
- **personality:** Wry, pragmatic and privately loyal; he fights for anyone with coin, and for exactly one person without it.
- **visual_theme:** Bannerless ember sellsword; charred-banner, ash and ember motifs, an ember-gold accent, a sharp pragmatic silhouette (unadorned RARE tier).
- **visual tier:** standard (no premium ornamentation).

Shared direction (all 12): ~6-head heroic proportions, upper-left key light, a 1-2 px dark ink outline,
cel-shaded painterly rendering, transparent RGBA8 backgrounds and element-motif accents; original
characters only, no copyrighted references.

## 4. Exact asset file list for this character

All expected FINAL files live under `res://assets/characters/kael/`. **NONE exist yet** (MISSING);
the procedural fallback is TEMPORARY and rendering. Sheet kinds are sliced `SpriteFrames` `.tres`.

| kind | expected file (MISSING) | dims (px) | anchor | frames | import |
| --- | --- | --- | --- | --- | --- |
| `full_body_illustration` | `res://assets/characters/kael/full_body_illustration.png` | 1024x2048 | bottom-centre (0.5, 1.0), feet on ONE baseline, ~6-head heroic proportions | 1 | Linear, mipmaps false, fix-alpha false |
| `character_portrait` | `res://assets/characters/kael/character_portrait.png` | 256x384 | top-centre (0.5, 0.0) bust crop from the top; eyes in the upper third | 1 | Linear, mipmaps false, fix-alpha false |
| `combat_sprite` | `res://assets/characters/kael/combat_sprite.png` | 128x192 | bottom-centre (0.5, 1.0), feet on ONE baseline | 1 | Linear, mipmaps true, fix-alpha true |
| `movement_sheet` | `res://assets/characters/kael/movement_sheet.tres` | 96x128 | bottom-centre (0.5, 1.0), feet on ONE identical baseline across every frame/state/direction | 24 | Linear, mipmaps true, fix-alpha true |
| `attack_sheet` | `res://assets/characters/kael/attack_sheet.tres` | 96x128 | bottom-centre (0.5, 1.0), feet on ONE identical baseline | 24 | Linear, mipmaps true, fix-alpha true |
| `cast_sheet` | `res://assets/characters/kael/cast_sheet.tres` | 96x128 | bottom-centre (0.5, 1.0), feet on ONE identical baseline | 8 | Linear, mipmaps true, fix-alpha true |
| `skill_vfx` | `res://assets/characters/kael/skill_vfx.png` | 192x192 | centre (0.5, 0.5) | 6 | Linear, mipmaps false, fix-alpha true |
| `ultimate_vfx` | `res://assets/characters/kael/ultimate_vfx.png` | 192x192 | centre (0.5, 0.5) | 6 | Linear, mipmaps false, fix-alpha true |
| `victory_sheet` | `res://assets/characters/kael/victory_sheet.tres` | 96x128 | bottom-centre (0.5, 1.0), feet on ONE identical baseline | 8 | Linear, mipmaps true, fix-alpha true |
| `defeat_sheet` | `res://assets/characters/kael/defeat_sheet.tres` | 96x128 | bottom-centre (0.5, 1.0), feet on ONE identical baseline | 8 | Linear, mipmaps true, fix-alpha true |

World frames are 96x128 (boss 128x192), bottom-centre `(0.5, 1.0)`, feet on ONE baseline.
Naming: `lower_snake_case` content-id folder; `<id>/<kind>.png` or `<id>/<kind>.tres`.

## 5. Animation requirements

- **Required states (9):** idle, walk, run, interact, attack, damage, victory, defeat, cast
- **Directions (8):** down, down_right, right, up_right, up, up_left, left, down_left (locomotion and every state authored for all 8)
- **Animations (72 required):** all `<state>_<dir>` names, including `cast_<dir>` (see `CharacterArtPipeline.animation_names()`).
- **8-direction locomotion:** `locomotion_8_directions = true`.

| state | frames | fps | loop |
| --- | --- | --- | --- |
| idle | 5 | 9.0 | true |
| walk | 7 | 12.0 | true |
| run | 7 | 14.0 | true |
| interact | 6 | 12.0 | false |
| attack | 6 | 15.0 | false |
| damage | 2 | 12.0 | false |
| victory | 8 | 12.0 | false |
| defeat | 6 | 10.0 | false |
| cast | 7 | 12.0 | false |

- **Feet on ONE identical baseline** across every frame/state/direction; anchor bottom-centre `(0.5, 1.0)`, 96x128 px frames.
- **Skill VFX ids:** ember_lance, rally_cry
- **Ultimate VFX ids:** blazing_charge

## 6. Portrait requirements

| property | requirement |
| --- | --- |
| master | 1024x1280 px |
| export (validated) | 256x384 px |
| crop | top-centre (0.5, 0.0) bust crop, head and shoulders, eyes in the upper third |
| expression set | neutral, a dry, lopsided smirk |
| background | transparent RGBA8 (alpha cutout); a subtle element-tinted vignette is allowed, never an opaque backdrop |
| rarity frame | rare frame; standard frame |
| lighting | upper-left key light, consistent across all 12 characters |
| outline | 1-2 px dark ink outline |

## 7. Generation prompts (detailed, ready-to-use for FUTURE external generation)

These prompts are PREPARATION for a future external illustration round; nothing was generated here.
Each begins from the shared GLOBAL STYLE ANCHOR (see `assets/GENERATION_PROMPTS.md`).

### 7.1 Full-body illustration

```text
Original anime-fantasy character illustration, ~6-head heroic proportions (not chibi, not realistic 8-head), soft cel-shaded painterly rendering, a 1-2 px dark ink outline for readability, a consistent upper-left key light with a cool rim light, transparent RGBA8 background (alpha cutout, no opaque backdrop, no baked ground shadow), no text, no logos, no copyrighted characters or reference traces. Shared GreenwardStyle palette language: deep indigo night, mossy emerald green, warm gold, teal spirit-light, violet arcane and ember accents. Feet on ONE baseline for full-body and world sprites.

SUBJECT: full-body illustration of Kael Ashford (Blade Without a Banner) - Blade Without a Banner. Race: Human; Element: fire; Rarity: rare; Role: Damage.
APPEARANCE: Lean, scarred human sellsword with a weathered face, a crooked nose, one sun-bleached eyebrow and the relaxed, ready stance of someone who has fought too many pointless wars. Hair: #4a3020 (dark umber-brown), Short, rough dark-umber hair singed at the tips, with a jagged old burn along one side.. Outfit: Worn leather-brown brigandine with burnt-rust wraps, mismatched scavenged pauldrons, a blank tabard with the banner emblem burned away and travel-worn boots. Accessories: A charred banner-ribbon kept as a belt tie, a coin pouch and a small unmarked token for the one person he fights for free. Weapon: A plain, well-used longsword with ember-gold etching along the fuller, its hilt wrapped in scorched leather..
POSE AND MOTIF: Casual ready stance, sword resting on the shoulder, a scorched banner ribbon trailing from the belt, a few ember sparks at his feet. Motif: a burnt banner, drifting ash and a single stubborn ember. Palette: hair #4a3020, primary #5a3a2a, secondary #c96f3a, accent #ffcf6a, skin #e8b890. Visual theme: Bannerless ember sellsword; charred-banner, ash and ember motifs, an ember-gold accent, a sharp pragmatic silhouette (unadorned RARE tier)..
OUTPUT SPEC: full-body master 1024x2048 px, full height head-to-toe, feet on ONE baseline, transparent RGBA8 sRGB, upper-left key light, 1-2 px dark ink outline, no baked text or backdrop.
```

### 7.2 Portrait

```text
Original anime-fantasy character illustration, ~6-head heroic proportions (not chibi, not realistic 8-head), soft cel-shaded painterly rendering, a 1-2 px dark ink outline for readability, a consistent upper-left key light with a cool rim light, transparent RGBA8 background (alpha cutout, no opaque backdrop, no baked ground shadow), no text, no logos, no copyrighted characters or reference traces. Shared GreenwardStyle palette language: deep indigo night, mossy emerald green, warm gold, teal spirit-light, violet arcane and ember accents. Feet on ONE baseline for full-body and world sprites.

SUBJECT: bust portrait of Kael Ashford (Blade Without a Banner), Blade Without a Banner. Head-and-shoulders top-centre crop (0.5, 0.0), eyes in the upper third, a calm neutral expression plus one alternate (a dry, lopsided smirk). Hair: #4a3020 (dark umber-brown), Short, rough dark-umber hair singed at the tips, with a jagged old burn along one side.. Palette: hair #4a3020, primary #5a3a2a, secondary #c96f3a, accent #ffcf6a, skin #e8b890. Visual theme: Bannerless ember sellsword; charred-banner, ash and ember motifs, an ember-gold accent, a sharp pragmatic silhouette (unadorned RARE tier).. Rarity frame: rare tier.
OUTPUT SPEC: master 1024x1280 px, export 256x384 px top-centre bust crop, transparent RGBA8 sRGB, upper-left key light, 1-2 px dark ink outline, no baked text, silhouette readable at 96x96.
```

### 7.3 Sprite sheet

```text
Original anime-fantasy character illustration, ~6-head heroic proportions (not chibi, not realistic 8-head), soft cel-shaded painterly rendering, a 1-2 px dark ink outline for readability, a consistent upper-left key light with a cool rim light, transparent RGBA8 background (alpha cutout, no opaque backdrop, no baked ground shadow), no text, no logos, no copyrighted characters or reference traces. Shared GreenwardStyle palette language: deep indigo night, mossy emerald green, warm gold, teal spirit-light, violet arcane and ember accents. Feet on ONE baseline for full-body and world sprites.

SUBJECT: 8-direction world sprite sheet for Kael Ashford (Blade Without a Banner), Damage. 96x128 px frames, bottom-centre anchor (0.5, 1.0), feet on ONE identical baseline across every frame/state/direction, 1-2 px dark ink outline, transparent RGBA8. Palette: hair #4a3020, primary #5a3a2a, secondary #c96f3a, accent #ffcf6a, skin #e8b890. Visual theme: Bannerless ember sellsword; charred-banner, ash and ember motifs, an ember-gold accent, a sharp pragmatic silhouette (unadorned RARE tier)..
LAYOUT: per-state atlas = <frames> columns x 8 direction rows (row 0 DOWN ... row 7 DOWN_LEFT), 0-based columns; states idle 5 frames @ 9 fps loop, walk 7 @ 12 loop, run 7 @ 14 loop, interact 6 @ 12, attack 6 @ 15, damage 2 @ 12, victory 8 @ 12, defeat 6 @ 10, cast 7 @ 12 (all one-shots unless noted). Slice into a SpriteFrames .tres with animations <state>_<dir> and cast_<dir>, speed = fps, loop = loop flag.
OUTPUT SPEC: transparent RGBA8 PNG atlas(es) sliced to a SpriteFrames .tres, 96x128 frames, Linear filter + mipmaps on, feet on ONE baseline, no baked text.
```

### 7.4 Skill / Ultimate VFX

```text
Original anime-fantasy character illustration, ~6-head heroic proportions (not chibi, not realistic 8-head), soft cel-shaded painterly rendering, a 1-2 px dark ink outline for readability, a consistent upper-left key light with a cool rim light, transparent RGBA8 background (alpha cutout, no opaque backdrop, no baked ground shadow), no text, no logos, no copyrighted characters or reference traces. Shared GreenwardStyle palette language: deep indigo night, mossy emerald green, warm gold, teal spirit-light, violet arcane and ember accents. Feet on ONE baseline for full-body and world sprites.

SUBJECT: skill/ultimate VFX flipbook for Kael Ashford - skill ids [ember_lance, rally_cry], ultimate id [blazing_charge], element fire, motif Bannerless ember sellsword; charred-banner, ash and ember motifs, an ember-gold accent, a sharp pragmatic silhouette (unadorned RARE tier).. 192x192 px frames, 6 frames, centre anchor (0.5, 0.5), 1 row x 6 columns (atlas 1152x192), transparent RGBA8 additive glow, element-coloured accents, no baked text.
OUTPUT SPEC: transparent RGBA8 PNG flipbook, 192x192 frames, Linear filter + mipmaps off + Lossless, additive alpha, sliced into 6-frame animations.
```

## 8. Exact output specifications

- **Format:** flattened transparent **RGBA8 PNG / WebP (sRGB)**, alpha cutouts, NEVER opaque; no baked text.
- **Full-body master:** 1024x2048; **portrait master:** 1024x1280 -> **export:** 256x384 top-centre bust crop; **combat sprite:** 128x192.
- **World frame:** 96x128 (boss 128x192); **VFX:** 192x192 x 6 frames; **sheet per state:** `<frames>*96` wide x `8*128` tall, 8 direction rows x frames columns, 0-based.
- **Import:** Linear filter; mipmaps ON for world art, OFF for UI/portrait/VFX; VRAM where supported (lossless UI); Fix Alpha Border ON for atlases/cutouts, OFF for portraits.
- **Slice:** into a `SpriteFrames` `.tres` with animations `<state>_<dir>` (and `cast_<dir>`), speed = fps, loop = loop flag (9 x 8 = 72 animations).
- **Validation command:** `godot --headless --path . --script res://tools/validate_content.gd` plus `godot --headless --path . res://tests/test_runner.tscn` (must stay 1374 passed).
- **Seams:** `ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>))`, `PortraitAssetSource.texture_for(<id>)`, `combat_engine.gd` VFX hooks.

**Status: MISSING (final) / TEMPORARY (procedural fallback).** No final artwork exists for this character.
