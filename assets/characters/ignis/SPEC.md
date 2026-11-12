# Ignis Karroth — Character Art Spec (`ignis`)

> **SPECIFICATION ONLY — no final artwork exists for this character. Status: MISSING (final) / TEMPORARY (procedural fallback).**
>
> ZERO final assets exist. Every shipped visual is RUNTIME PROCEDURAL PLACEHOLDER art generated in code.
> This document is a CONTRACT/SPECIFICATION for FUTURE external image generation. **No final artwork
> was generated or fabricated in this phase**, and no image/binary file exists at any path below.
> See `assets/CHARACTER_ART_PIPELINE.md`, `assets/GENERATION_PROMPTS.md`, `assets/ASSET_PRODUCTION_MANIFEST.md`.

## 1. Identity (verbatim from `resources/data/characters.json`)

| field | value |
| --- | --- |
| id | `ignis` |
| display_name | Ignis Karroth |
| title | Crown of Cinders |
| race | Dragonkin |
| element | fire |
| rarity | mythic |
| role | Damage |

These identity fields are reproduced exactly so that
`CharacterArtSpec.for_id("ignis").race == ContentDB.get_character("ignis").race` (and the other five fields) hold.

## 2. Palette (exact from `characters.json`)

| role | hex |
| --- | --- |
| `hair` | `#ff7a3c` |
| `primary` | `#3a1414` |
| `secondary` | `#d9a441` |
| `accent` | `#ffb347` |
| `skin` | `#e8b28f` |

- **hair_color:** `#ff7a3c (ember orange)`

## 3. Authored art direction (consistent shared anime-fantasy style)

- **physical_appearance:** Powerful dragonkin with swept-back ember horns, scaled forearms and shoulders, a long heavy draconic tail, slit-pupil amber eyes and heat-shimmer rising from his skin.
- **hair_style:** Wild, flame-swept ember-orange hair that rises like living fire, streaked with molten-gold tips.
- **hair_color:** #ff7a3c (ember orange)
- **outfit:** Charred crimson-black armour with molten-gold filigree glowing in the seams, a tattered ash-cloak, scaled greaves and an open collar showing the cinder crown's brand.
- **accessories:** The Crown of Cinders (a floating ring of ever-burning embers above the brow), seared bracers and a belt of cooled slag medallions.
- **weapon:** A great molten greatsword of half-cooled slag, dripping embers and wreathed in flame.
- **personality:** Proud, unrepentant and smouldering; he carries the weight of a kingdom that burned itself to keep him warm and refuses to apologise for surviving.
- **visual_theme:** Charred-crown dragonkin; cinder, ash and molten-gold motifs, a roaring ember aura, asymmetric sharp silhouette, the most ornate premium MYTHIC tier.
- **visual tier (distinct):** MYTHIC TIER (highest, single Mythic character): a persistent roaring ember-and-ash aura, the elaborate floating Crown of Cinders, molten-gold glowing filigree across all armour seams, a layered ash-cloak, and the most ornate premium engraved obsidian-and-gold frame reserved for the Mythic tier.

Shared direction (all 12): ~6-head heroic proportions, upper-left key light, a 1-2 px dark ink outline,
cel-shaded painterly rendering, transparent RGBA8 backgrounds and element-motif accents; original
characters only, no copyrighted references.

## 4. Exact asset file list for this character

All expected FINAL files live under `res://assets/characters/ignis/`. **NONE exist yet** (MISSING);
the procedural fallback is TEMPORARY and rendering. Sheet kinds are sliced `SpriteFrames` `.tres`.

| kind | expected file (MISSING) | dims (px) | anchor | frames | import |
| --- | --- | --- | --- | --- | --- |
| `full_body_illustration` | `res://assets/characters/ignis/full_body_illustration.png` | 1024x2048 | bottom-centre (0.5, 1.0), feet on ONE baseline, ~6-head heroic proportions | 1 | Linear, mipmaps false, fix-alpha false |
| `character_portrait` | `res://assets/characters/ignis/character_portrait.png` | 256x384 | top-centre (0.5, 0.0) bust crop from the top; eyes in the upper third | 1 | Linear, mipmaps false, fix-alpha false |
| `combat_sprite` | `res://assets/characters/ignis/combat_sprite.png` | 128x192 | bottom-centre (0.5, 1.0), feet on ONE baseline | 1 | Linear, mipmaps true, fix-alpha true |
| `movement_sheet` | `res://assets/characters/ignis/movement_sheet.tres` | 96x128 | bottom-centre (0.5, 1.0), feet on ONE identical baseline across every frame/state/direction | 24 | Linear, mipmaps true, fix-alpha true |
| `attack_sheet` | `res://assets/characters/ignis/attack_sheet.tres` | 96x128 | bottom-centre (0.5, 1.0), feet on ONE identical baseline | 24 | Linear, mipmaps true, fix-alpha true |
| `cast_sheet` | `res://assets/characters/ignis/cast_sheet.tres` | 96x128 | bottom-centre (0.5, 1.0), feet on ONE identical baseline | 8 | Linear, mipmaps true, fix-alpha true |
| `skill_vfx` | `res://assets/characters/ignis/skill_vfx.png` | 192x192 | centre (0.5, 0.5) | 6 | Linear, mipmaps false, fix-alpha true |
| `ultimate_vfx` | `res://assets/characters/ignis/ultimate_vfx.png` | 192x192 | centre (0.5, 0.5) | 6 | Linear, mipmaps false, fix-alpha true |
| `victory_sheet` | `res://assets/characters/ignis/victory_sheet.tres` | 96x128 | bottom-centre (0.5, 1.0), feet on ONE identical baseline | 8 | Linear, mipmaps true, fix-alpha true |
| `defeat_sheet` | `res://assets/characters/ignis/defeat_sheet.tres` | 96x128 | bottom-centre (0.5, 1.0), feet on ONE identical baseline | 8 | Linear, mipmaps true, fix-alpha true |

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
- **Skill VFX ids:** ember_lance, cinder_veil
- **Ultimate VFX ids:** inferno_crown

## 6. Portrait requirements

| property | requirement |
| --- | --- |
| master | 1024x1280 px |
| export (validated) | 256x384 px |
| crop | top-centre (0.5, 0.0) bust crop, head and shoulders, eyes in the upper third |
| expression set | neutral, a defiant, unapologetic smirk |
| background | transparent RGBA8 (alpha cutout); a subtle element-tinted vignette is allowed, never an opaque backdrop |
| rarity frame | mythic frame; premium ornate frame for Legendary/Mythic tier |
| lighting | upper-left key light, consistent across all 12 characters |
| outline | 1-2 px dark ink outline |

## 7. Generation prompts (detailed, ready-to-use for FUTURE external generation)

These prompts are PREPARATION for a future external illustration round; nothing was generated here.
Each begins from the shared GLOBAL STYLE ANCHOR (see `assets/GENERATION_PROMPTS.md`).

### 7.1 Full-body illustration

```text
Original anime-fantasy character illustration, ~6-head heroic proportions (not chibi, not realistic 8-head), soft cel-shaded painterly rendering, a 1-2 px dark ink outline for readability, a consistent upper-left key light with a cool rim light, transparent RGBA8 background (alpha cutout, no opaque backdrop, no baked ground shadow), no text, no logos, no copyrighted characters or reference traces. Shared GreenwardStyle palette language: deep indigo night, mossy emerald green, warm gold, teal spirit-light, violet arcane and ember accents. Feet on ONE baseline for full-body and world sprites.

SUBJECT: full-body illustration of Ignis Karroth (Crown of Cinders) - Crown of Cinders. Race: Dragonkin; Element: fire; Rarity: mythic; Role: Damage.
APPEARANCE: Powerful dragonkin with swept-back ember horns, scaled forearms and shoulders, a long heavy draconic tail, slit-pupil amber eyes and heat-shimmer rising from his skin. Hair: #ff7a3c (ember orange), Wild, flame-swept ember-orange hair that rises like living fire, streaked with molten-gold tips.. Outfit: Charred crimson-black armour with molten-gold filigree glowing in the seams, a tattered ash-cloak, scaled greaves and an open collar showing the cinder crown's brand. Accessories: The Crown of Cinders (a floating ring of ever-burning embers above the brow), seared bracers and a belt of cooled slag medallions. Weapon: A great molten greatsword of half-cooled slag, dripping embers and wreathed in flame..
POSE AND MOTIF: Forward-leaning power stance, greatsword planted point-down wreathed in fire, cinder crown blazing, ash-cloak swept behind, heat-haze rising. Motif: a floating crown of cinders, drifting ash and rising flame tongues. Palette: hair #ff7a3c, primary #3a1414, secondary #d9a441, accent #ffb347, skin #e8b28f. Visual theme: Charred-crown dragonkin; cinder, ash and molten-gold motifs, a roaring ember aura, asymmetric sharp silhouette, the most ornate premium MYTHIC tier..
PREMIUM TIER: MYTHIC TIER (highest, single Mythic character): a persistent roaring ember-and-ash aura, the elaborate floating Crown of Cinders, molten-gold glowing filigree across all armour seams, a layered ash-cloak, and the most ornate premium engraved obsidian-and-gold frame reserved for the Mythic tier.
OUTPUT SPEC: full-body master 1024x2048 px, full height head-to-toe, feet on ONE baseline, transparent RGBA8 sRGB, upper-left key light, 1-2 px dark ink outline, no baked text or backdrop.
```

### 7.2 Portrait

```text
Original anime-fantasy character illustration, ~6-head heroic proportions (not chibi, not realistic 8-head), soft cel-shaded painterly rendering, a 1-2 px dark ink outline for readability, a consistent upper-left key light with a cool rim light, transparent RGBA8 background (alpha cutout, no opaque backdrop, no baked ground shadow), no text, no logos, no copyrighted characters or reference traces. Shared GreenwardStyle palette language: deep indigo night, mossy emerald green, warm gold, teal spirit-light, violet arcane and ember accents. Feet on ONE baseline for full-body and world sprites.

SUBJECT: bust portrait of Ignis Karroth (Crown of Cinders), Crown of Cinders. Head-and-shoulders top-centre crop (0.5, 0.0), eyes in the upper third, a calm neutral expression plus one alternate (a defiant, unapologetic smirk). Hair: #ff7a3c (ember orange), Wild, flame-swept ember-orange hair that rises like living fire, streaked with molten-gold tips.. Palette: hair #ff7a3c, primary #3a1414, secondary #d9a441, accent #ffb347, skin #e8b28f. Visual theme: Charred-crown dragonkin; cinder, ash and molten-gold motifs, a roaring ember aura, asymmetric sharp silhouette, the most ornate premium MYTHIC tier.. Rarity frame: mythic tier. Premium frame: MYTHIC TIER (highest, single Mythic character): a persistent roaring ember-and-ash aura, the elaborate floating Crown of Cinders, molten-gold glowing filigree across all armour seams, a layered ash-cloak, and the most ornate premium engraved obsidian-and-gold frame reserved for the Mythic tier.
OUTPUT SPEC: master 1024x1280 px, export 256x384 px top-centre bust crop, transparent RGBA8 sRGB, upper-left key light, 1-2 px dark ink outline, no baked text, silhouette readable at 96x96.
```

### 7.3 Sprite sheet

```text
Original anime-fantasy character illustration, ~6-head heroic proportions (not chibi, not realistic 8-head), soft cel-shaded painterly rendering, a 1-2 px dark ink outline for readability, a consistent upper-left key light with a cool rim light, transparent RGBA8 background (alpha cutout, no opaque backdrop, no baked ground shadow), no text, no logos, no copyrighted characters or reference traces. Shared GreenwardStyle palette language: deep indigo night, mossy emerald green, warm gold, teal spirit-light, violet arcane and ember accents. Feet on ONE baseline for full-body and world sprites.

SUBJECT: 8-direction world sprite sheet for Ignis Karroth (Crown of Cinders), Damage. 96x128 px frames, bottom-centre anchor (0.5, 1.0), feet on ONE identical baseline across every frame/state/direction, 1-2 px dark ink outline, transparent RGBA8. Palette: hair #ff7a3c, primary #3a1414, secondary #d9a441, accent #ffb347, skin #e8b28f. Visual theme: Charred-crown dragonkin; cinder, ash and molten-gold motifs, a roaring ember aura, asymmetric sharp silhouette, the most ornate premium MYTHIC tier..
LAYOUT: per-state atlas = <frames> columns x 8 direction rows (row 0 DOWN ... row 7 DOWN_LEFT), 0-based columns; states idle 5 frames @ 9 fps loop, walk 7 @ 12 loop, run 7 @ 14 loop, interact 6 @ 12, attack 6 @ 15, damage 2 @ 12, victory 8 @ 12, defeat 6 @ 10, cast 7 @ 12 (all one-shots unless noted). Slice into a SpriteFrames .tres with animations <state>_<dir> and cast_<dir>, speed = fps, loop = loop flag.
OUTPUT SPEC: transparent RGBA8 PNG atlas(es) sliced to a SpriteFrames .tres, 96x128 frames, Linear filter + mipmaps on, feet on ONE baseline, no baked text.
```

### 7.4 Skill / Ultimate VFX

```text
Original anime-fantasy character illustration, ~6-head heroic proportions (not chibi, not realistic 8-head), soft cel-shaded painterly rendering, a 1-2 px dark ink outline for readability, a consistent upper-left key light with a cool rim light, transparent RGBA8 background (alpha cutout, no opaque backdrop, no baked ground shadow), no text, no logos, no copyrighted characters or reference traces. Shared GreenwardStyle palette language: deep indigo night, mossy emerald green, warm gold, teal spirit-light, violet arcane and ember accents. Feet on ONE baseline for full-body and world sprites.

SUBJECT: skill/ultimate VFX flipbook for Ignis Karroth - skill ids [ember_lance, cinder_veil], ultimate id [inferno_crown], element fire, motif Charred-crown dragonkin; cinder, ash and molten-gold motifs, a roaring ember aura, asymmetric sharp silhouette, the most ornate premium MYTHIC tier.. 192x192 px frames, 6 frames, centre anchor (0.5, 0.5), 1 row x 6 columns (atlas 1152x192), transparent RGBA8 additive glow, element-coloured accents, no baked text.
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
