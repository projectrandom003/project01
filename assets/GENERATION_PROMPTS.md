# PROJECT FANTASY — Generation Prompts (FUTURE external generation)

> **These are PREPARATION prompts for FUTURE external image generation.**
> **NO final artwork was generated or fabricated for the 12 collectible characters.** All shipped
> visuals for them are runtime procedural placeholder art. The files below are text contracts only.
> (Lilith's playable art IS final and lives in `assets/characters/lilith/` — see
> `assets/characters/main/little_sister/SPEC.md`.)

## 1. GLOBAL STYLE ANCHOR (prepend to EVERY prompt)

```text
Original anime-fantasy character illustration, ~6-head heroic proportions (not chibi, not realistic 8-head), soft cel-shaded painterly rendering, a 1-2 px dark ink outline for readability, a consistent upper-left key light with a cool rim light, transparent RGBA8 background (alpha cutout, no opaque backdrop, no baked ground shadow), no text, no logos, no copyrighted characters or reference traces. Shared GreenwardStyle palette language: deep indigo night, mossy emerald green, warm gold, teal spirit-light, violet arcane and ember accents. Feet on ONE baseline for full-body and world sprites.
```

Shared rules: original anime-fantasy, no copyrighted characters/logos, ~6-head heroic proportions, upper-left
key light with cool rim light, 1-2 px dark ink outline, cel-shaded painterly rendering, transparent RGBA8
background (no opaque backdrop, no baked ground shadow or text), palette language from `GreenwardStyle`
(deep indigo, mossy emerald, warm gold, teal spirit-light, violet arcane, ember accents), feet on ONE baseline.

## 2. Per-character prompt blocks (12)

Each block gives SHORT full-body / portrait / sprite-sheet prompts. The fully detailed, ready-to-use prompts
(with the full global anchor expanded) live in each `assets/characters/<id>/SPEC.md` §7 and in
`CharacterArtSpec.to_dict()` / `prompt_for(kind)`.

### `lyra_vey` — Lyra Vey (Elf, wind, epic)

- **Full-body:** full-height illustration of Lyra Vey — Warden of the Whispering Glade, Elf wind. Tall, willowy elf with a quiet forward-leaning poise; long pointed ears, soft almond eyes the colour of new leaves, and a faint breeze that seems to tug at her clothes even in still air.. hair #d8e8c8, primary #2f6b4f, secondary #c9a45a, accent #9df5cf, skin #f3d7c0. Visual theme: Mint-and-emerald wind warden; drifting leaf and ribbon motifs, cool teal accent glow, soft rounded ally silhouette.. Full height head-to-toe, feet on ONE baseline, 1024x2048 master, transparent RGBA8.
- **Portrait:** top-centre bust crop of Lyra Vey, eyes in the upper third, a neutral expression plus a faint, knowing half-smile as the wind rises; hair #d8e8c8 (pale mint-sage), Long pale-sage hair swept into a loose half-braid with wind-tossed flyaway strands and a leaf-shaped clasp.; epic frame; master 1024x1280 -> export 256x384, transparent RGBA8.
- **Sprite sheet:** 8-direction 96x128 frames for Lyra Vey, bottom-centre anchor, feet on ONE baseline, states idle/walk/run/interact/attack/damage/victory/defeat/cast at their authoritative frame counts/fps; palette hair #d8e8c8, primary #2f6b4f, secondary #c9a45a, accent #9df5cf, skin #f3d7c0; slice to `<state>_<dir>` + `cast_<dir>` SpriteFrames.

### `bramble` — Bramble (Beastkin, earth, rare)

- **Full-body:** full-height illustration of Bramble — Thorn-Touched Wanderer, Beastkin earth. Stocky, sturdy beastkin with russet fox ears and a bushy tail, freckled cheeks, blunt honest features, calloused hands and a slight permanent squint from outdoor life.. hair #c96f3a, primary #5a4a2e, secondary #8fbf6a, accent #ffd27a, skin #f0c8a8. Visual theme: Earthy bark-and-moss bruiser; warm lantern-gold accents, rounded friendly silhouette, thorn and root motifs.. Full height head-to-toe, feet on ONE baseline, 1024x2048 master, transparent RGBA8.
- **Portrait:** top-centre bust crop of Bramble, eyes in the upper third, a neutral expression plus a sheepish, apologetic grin; hair #c96f3a (burnt copper), Short, shaggy copper hair with unruly tufts, a few leaves and twigs forever caught in it.; rare frame; master 1024x1280 -> export 256x384, transparent RGBA8.
- **Sprite sheet:** 8-direction 96x128 frames for Bramble, bottom-centre anchor, feet on ONE baseline, states idle/walk/run/interact/attack/damage/victory/defeat/cast at their authoritative frame counts/fps; palette hair #c96f3a, primary #5a4a2e, secondary #8fbf6a, accent #ffd27a, skin #f0c8a8; slice to `<state>_<dir>` + `cast_<dir>` SpriteFrames.

### `seraphine` — Seraphine Ael (Angel, light, legendary)

- **Full-body:** full-height illustration of Seraphine Ael — Dawn's Last Ember, Angel light. Graceful, luminous angel with a calm maternal gaze, faintly glowing skin, a small radiant warm halo above the head and six soft feathered wings folded behind her.. hair #fff2c4, primary #f2ead7, secondary #d9b45c, accent #ffe9a3, skin #f7ddc9. Visual theme: Ivory-and-gold dawn angel; sunburst and halo motifs, a warm radiant aura, ornate premium LEGENDARY ornamentation, soft rounded ally silhouette.. Full height head-to-toe, feet on ONE baseline, 1024x2048 master, transparent RGBA8.
- **Portrait:** top-centre bust crop of Seraphine Ael, eyes in the upper third, a neutral expression plus a tender, sorrowful smile; hair #fff2c4 (pale sun-gold), Long waves of pale sun-gold hair falling past the waist, crowned by a thin filigree halo-ring.; legendary frame; master 1024x1280 -> export 256x384, transparent RGBA8.
- **Sprite sheet:** 8-direction 96x128 frames for Seraphine Ael, bottom-centre anchor, feet on ONE baseline, states idle/walk/run/interact/attack/damage/victory/defeat/cast at their authoritative frame counts/fps; palette hair #fff2c4, primary #f2ead7, secondary #d9b45c, accent #ffe9a3, skin #f7ddc9; slice to `<state>_<dir>` + `cast_<dir>` SpriteFrames.

### `nyx` — Nyx Vaelora (Demon, dark, legendary)

- **Full-body:** full-height illustration of Nyx Vaelora — Queen of the Hollow Moon, Demon dark. Regal, tall demon queen with curling horns, luminous rose-magenta eyes, an absent reflection (mirrors behind her show nothing) and a calm, cold beauty.. hair #2a1533, primary #3b1f4e, secondary #a87bd4, accent #ff6fae, skin #e8cdd8. Visual theme: Hollow-moon violet queen; eclipse, void-disc and thorned-crown motifs, rose-magenta arcane glow, sharp regal silhouette, ornate premium LEGENDARY ornamentation.. Full height head-to-toe, feet on ONE baseline, 1024x2048 master, transparent RGBA8.
- **Portrait:** top-centre bust crop of Nyx Vaelora, eyes in the upper third, a neutral expression plus a cool, unreadable half-smile; hair #2a1533 (near-black aubergine), Very long near-black aubergine hair falling like ink, bound at the temples with amethyst horn-clasps.; legendary frame; master 1024x1280 -> export 256x384, transparent RGBA8.
- **Sprite sheet:** 8-direction 96x128 frames for Nyx Vaelora, bottom-centre anchor, feet on ONE baseline, states idle/walk/run/interact/attack/damage/victory/defeat/cast at their authoritative frame counts/fps; palette hair #2a1533, primary #3b1f4e, secondary #a87bd4, accent #ff6fae, skin #e8cdd8; slice to `<state>_<dir>` + `cast_<dir>` SpriteFrames.

### `coralyn` — Coralyn Tide (Mermaid, water, epic)

- **Full-body:** full-height illustration of Coralyn Tide — Song Beneath the Reef, Mermaid water. Lithe mermaid with a shimmering scaled tail (a flowing split fin-skirt on land), webbed fingertips, pearl-bright eyes and faint gill-lines at the neck.. hair #7fe3e0, primary #1f6f8f, secondary #ffb3c7, accent #b9f6ff, skin #f4d9cd. Visual theme: Lagoon-and-coral tide singer; wave, bubble and shell motifs, pale-aqua glow, fluid rounded ally silhouette.. Full height head-to-toe, feet on ONE baseline, 1024x2048 master, transparent RGBA8.
- **Portrait:** top-centre bust crop of Coralyn Tide, eyes in the upper third, a neutral expression plus a small, uncertain hum with wide eyes; hair #7fe3e0 (seafoam teal), Long seafoam-teal hair that floats as if in water, threaded with tiny shells and coral beads.; epic frame; master 1024x1280 -> export 256x384, transparent RGBA8.
- **Sprite sheet:** 8-direction 96x128 frames for Coralyn Tide, bottom-centre anchor, feet on ONE baseline, states idle/walk/run/interact/attack/damage/victory/defeat/cast at their authoritative frame counts/fps; palette hair #7fe3e0, primary #1f6f8f, secondary #ffb3c7, accent #b9f6ff, skin #f4d9cd; slice to `<state>_<dir>` + `cast_<dir>` SpriteFrames.

### `ignis` — Ignis Karroth (Dragonkin, fire, mythic)

- **Full-body:** full-height illustration of Ignis Karroth — Crown of Cinders, Dragonkin fire. Powerful dragonkin with swept-back ember horns, scaled forearms and shoulders, a long heavy draconic tail, slit-pupil amber eyes and heat-shimmer rising from his skin.. hair #ff7a3c, primary #3a1414, secondary #d9a441, accent #ffb347, skin #e8b28f. Visual theme: Charred-crown dragonkin; cinder, ash and molten-gold motifs, a roaring ember aura, asymmetric sharp silhouette, the most ornate premium MYTHIC tier.. Full height head-to-toe, feet on ONE baseline, 1024x2048 master, transparent RGBA8.
- **Portrait:** top-centre bust crop of Ignis Karroth, eyes in the upper third, a neutral expression plus a defiant, unapologetic smirk; hair #ff7a3c (ember orange), Wild, flame-swept ember-orange hair that rises like living fire, streaked with molten-gold tips.; mythic frame; master 1024x1280 -> export 256x384, transparent RGBA8.
- **Sprite sheet:** 8-direction 96x128 frames for Ignis Karroth, bottom-centre anchor, feet on ONE baseline, states idle/walk/run/interact/attack/damage/victory/defeat/cast at their authoritative frame counts/fps; palette hair #ff7a3c, primary #3a1414, secondary #d9a441, accent #ffb347, skin #e8b28f; slice to `<state>_<dir>` + `cast_<dir>` SpriteFrames.

### `mira_sol` — Mira Sol (Human, light, common)

- **Full-body:** full-height illustration of Mira Sol — Squire of the Golden Gate, Human light. Sturdy, earnest young human with a square jaw, a few faint freckles, steady grey-gold eyes and the upright posture of someone who still stands watch.. hair #e8c27a, primary #c9d2e0, secondary #d9b45c, accent #fff0b8, skin #f0cbb0. Visual theme: Humble steel-and-dawn squire; plain gate-and-shield motifs, a pale dawn-gold accent, a simple honest rounded silhouette (ordinary COMMON tier, no ornamentation).. Full height head-to-toe, feet on ONE baseline, 1024x2048 master, transparent RGBA8.
- **Portrait:** top-centre bust crop of Mira Sol, eyes in the upper third, a neutral expression plus a determined, steady gaze; hair #e8c27a (warm wheat-gold), Practical wheat-gold bob tucked under a squire's cap, with a short braid at one temple.; common frame; master 1024x1280 -> export 256x384, transparent RGBA8.
- **Sprite sheet:** 8-direction 96x128 frames for Mira Sol, bottom-centre anchor, feet on ONE baseline, states idle/walk/run/interact/attack/damage/victory/defeat/cast at their authoritative frame counts/fps; palette hair #e8c27a, primary #c9d2e0, secondary #d9b45c, accent #fff0b8, skin #f0cbb0; slice to `<state>_<dir>` + `cast_<dir>` SpriteFrames.

### `thistle` — Thistle (Spirit, wind, rare)

- **Full-body:** full-height illustration of Thistle — Lantern of Small Wishes, Spirit wind. Small, translucent wisp-spirit with a softly glowing slightly see-through body, tiny floating feet, a faint halo of warm lantern-light and edges that blur into motes.. hair #f2e2a8, primary #3f5a6b, secondary #8fd9c4, accent #ffeaa0, skin #f6e3cf. Visual theme: Warm wishlight wisp; lantern, dandelion-seed and paper-wish motifs, a soft mint-and-gold glow, a small rounded glowing silhouette.. Full height head-to-toe, feet on ONE baseline, 1024x2048 master, transparent RGBA8.
- **Portrait:** top-centre bust crop of Thistle, eyes in the upper third, a neutral expression plus a shy, hopeful smile; hair #f2e2a8 (pale wishlight gold), A cloud of pale wishlight-gold hair that drifts upward like dandelion fluff.; rare frame; master 1024x1280 -> export 256x384, transparent RGBA8.
- **Sprite sheet:** 8-direction 96x128 frames for Thistle, bottom-centre anchor, feet on ONE baseline, states idle/walk/run/interact/attack/damage/victory/defeat/cast at their authoritative frame counts/fps; palette hair #f2e2a8, primary #3f5a6b, secondary #8fd9c4, accent #ffeaa0, skin #f6e3cf; slice to `<state>_<dir>` + `cast_<dir>` SpriteFrames.

### `vespera` — Vespera Noct (Vampire, dark, epic)

- **Full-body:** full-height illustration of Vespera Noct — Velvet Requiem, Vampire dark. Elegant, pale vampire with crimson-lined eyes, delicate pointed canines just visible, an unhurried dancer's poise and an eerie stillness; dressed always in funeral white.. hair #d8d8e8, primary #2a1a2e, secondary #8f2f4f, accent #ff8fb3, skin #f0e0e0. Visual theme: White-mourning vampire assassin; black-rose, candle and waltz motifs, a rose-pink accent, a sharp elegant silhouette and dark-plum lining.. Full height head-to-toe, feet on ONE baseline, 1024x2048 master, transparent RGBA8.
- **Portrait:** top-centre bust crop of Vespera Noct, eyes in the upper third, a neutral expression plus a serene, faintly mourning smile; hair #d8d8e8 (moonlit silver-lilac), Long moonlit silver-lilac hair in a smooth low braid with a few loose face-framing strands.; epic frame; master 1024x1280 -> export 256x384, transparent RGBA8.
- **Sprite sheet:** 8-direction 96x128 frames for Vespera Noct, bottom-centre anchor, feet on ONE baseline, states idle/walk/run/interact/attack/damage/victory/defeat/cast at their authoritative frame counts/fps; palette hair #d8d8e8, primary #2a1a2e, secondary #8f2f4f, accent #ff8fb3, skin #f0e0e0; slice to `<state>_<dir>` + `cast_<dir>` SpriteFrames.

### `arachnia` — Arachnia Silk (Monster Girl, dark, epic)

- **Full-body:** full-height illustration of Arachnia Silk — Weaver of the Quiet Web, Monster Girl dark. Composed monster-girl with a human upper body and six slender spider legs arching from her back, four auxiliary eyes on the temples (closed to near-slits) and graceful many-jointed fingers.. hair #3a2a4a, primary #4a2f5a, secondary #b07fd4, accent #c8ff8f, skin #e8c8d8. Visual theme: Quiet-web weaver; spider-silk, tapestry-map and eight-strand motifs, a chartreuse glow against deep aubergine, an elegant asymmetric silhouette.. Full height head-to-toe, feet on ONE baseline, 1024x2048 master, transparent RGBA8.
- **Portrait:** top-centre bust crop of Arachnia Silk, eyes in the upper third, a neutral expression plus a patient, knowing look; hair #3a2a4a (dark mulberry), Sleek dark-mulberry hair wound into an intricate web-like updo pinned with silk threads.; epic frame; master 1024x1280 -> export 256x384, transparent RGBA8.
- **Sprite sheet:** 8-direction 96x128 frames for Arachnia Silk, bottom-centre anchor, feet on ONE baseline, states idle/walk/run/interact/attack/damage/victory/defeat/cast at their authoritative frame counts/fps; palette hair #3a2a4a, primary #4a2f5a, secondary #b07fd4, accent #c8ff8f, skin #e8c8d8; slice to `<state>_<dir>` + `cast_<dir>` SpriteFrames.

### `terra` — Terra Rootheart (Ancient, earth, legendary)

- **Full-body:** full-height illustration of Terra Rootheart — The Mountain That Remembers, Ancient earth. Immense, calm ancient whose body is part living stone - moss-veined forearms, a granite-like shoulder ridge, slow glacial movements and eyes like deep green mineral seams; she seems more landscape than person.. hair #6f8f5a, primary #4a4030, secondary #8fbf6a, accent #d9ff9f, skin #c9a88a. Visual theme: Mountain-that-remembers; cliff-strata, standing-stone and deep-root motifs, pale moss-glow seams, a monumental rounded-rock silhouette, ornate premium LEGENDARY ornamentation.. Full height head-to-toe, feet on ONE baseline, 1024x2048 master, transparent RGBA8.
- **Portrait:** top-centre bust crop of Terra Rootheart, eyes in the upper third, a neutral expression plus a slow, ancient, half-lidded calm; hair #6f8f5a (mossy stone-green), Long mossy stone-green hair like hanging lichen, threaded with small wildflowers and pebbles.; legendary frame; master 1024x1280 -> export 256x384, transparent RGBA8.
- **Sprite sheet:** 8-direction 96x128 frames for Terra Rootheart, bottom-centre anchor, feet on ONE baseline, states idle/walk/run/interact/attack/damage/victory/defeat/cast at their authoritative frame counts/fps; palette hair #6f8f5a, primary #4a4030, secondary #8fbf6a, accent #d9ff9f, skin #c9a88a; slice to `<state>_<dir>` + `cast_<dir>` SpriteFrames.

### `kael` — Kael Ashford (Human, fire, rare)

- **Full-body:** full-height illustration of Kael Ashford — Blade Without a Banner, Human fire. Lean, scarred human sellsword with a weathered face, a crooked nose, one sun-bleached eyebrow and the relaxed, ready stance of someone who has fought too many pointless wars.. hair #4a3020, primary #5a3a2a, secondary #c96f3a, accent #ffcf6a, skin #e8b890. Visual theme: Bannerless ember sellsword; charred-banner, ash and ember motifs, an ember-gold accent, a sharp pragmatic silhouette (unadorned RARE tier).. Full height head-to-toe, feet on ONE baseline, 1024x2048 master, transparent RGBA8.
- **Portrait:** top-centre bust crop of Kael Ashford, eyes in the upper third, a neutral expression plus a dry, lopsided smirk; hair #4a3020 (dark umber-brown), Short, rough dark-umber hair singed at the tips, with a jagged old burn along one side.; rare frame; master 1024x1280 -> export 256x384, transparent RGBA8.
- **Sprite sheet:** 8-direction 96x128 frames for Kael Ashford, bottom-centre anchor, feet on ONE baseline, states idle/walk/run/interact/attack/damage/victory/defeat/cast at their authoritative frame counts/fps; palette hair #4a3020, primary #5a3a2a, secondary #c96f3a, accent #ffcf6a, skin #e8b890; slice to `<state>_<dir>` + `cast_<dir>` SpriteFrames.

## 3. EXACT OUTPUT SPECIFICATIONS

| asset | dimensions | alpha / format | anchor | layout | naming |
| --- | --- | --- | --- | --- | --- |
| full-body master | 1024x2048 | transparent RGBA8 PNG/WebP sRGB | bottom-centre (0.5,1.0) | single frame | `<id>/full_body_illustration.png` |
| portrait master -> export | 1024x1280 -> 256x384 | transparent RGBA8 | top-centre (0.5,0.0) bust crop | single frame | `<id>/portrait.png` |
| combat sprite | 128x192 | transparent RGBA8 | bottom-centre | single frame | `<id>/combat_sprite.png` |
| world sheet (per state) | `<frames>*96` x `8*128` (1024 tall) | transparent RGBA8 | bottom-centre, ONE foot baseline | 8 direction rows x frames columns, 0-based | `<id>/<kind>.png` -> `<id>/<kind>.tres` |
| skill / ultimate VFX | 192x192 x 6 frames (atlas 1152x192) | transparent RGBA8 additive | centre (0.5,0.5) | 1 row x 6 columns | `vfx/<skill_id>/effect.png` |

- **Import settings:** Linear filter; mipmaps ON for world art, OFF for UI/portrait/VFX; VRAM compression where supported (lossless for UI); Fix Alpha Border ON for atlases/cutout sprites, OFF for portraits. Portrait keeps aspect ratio (never stretch).
- **Slice:** `SpriteFrames` `.tres`, animations `<state>_<dir>` and `cast_<dir>` (72 total), speed = fps, loop = loop flag.
- **Naming:** `lower_snake_case`, ASCII, one content-id folder per character; state ids 0..8, direction ids 0..7.
- **Validation command:** `godot --headless --path . --script res://tools/validate_content.gd` and `godot --headless --path . res://tests/test_runner.tscn`; `CharacterArtPipeline.validate_asset()` / `CharacterAssetRegistry.validate_finished_asset()` reject wrong dims/anchor/alpha/frames/format.

**NO final artwork was generated or fabricated in this phase.** All 12 characters remain MISSING (final) / TEMPORARY (procedural fallback).
