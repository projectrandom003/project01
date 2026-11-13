# PROJECT FANTASY — Visual Style Guide (Phase 3)

> **Canonical art-direction deliverable.** This document defines *how the world
> should look* and is the single narrative companion to the machine-readable
> palette in `scripts/world/visual_style.gd` (class `GreenwardStyle`). When the
> two disagree, `GreenwardStyle` is the implementation truth; this guide is the
> intent.

> ### ⚠️ Most world and roster art still uses procedural placeholders
> The three playable protagonists (Gerald, Lilith and Kael) now have final
> imported avatar sheets, portraits and combat art; the Fallen Matron has three
> original phase cutouts. Environment props, generic NPCs, ordinary monsters
> and the 12 collectible roster assets still use procedural art. This guide
> remains the canonical palette and visual-language target for those systems.
> **No device profiling has been performed** — mobile/desktop tiers remain
> coarse platform hints only. See [ART_PIPELINE.md](ART_PIPELINE.md) and
> `assets/ASSET_STATUS.md` for the current asset inventory.

---

## 0. Direction in one paragraph

Original **anime-fantasy**, painterly but readable at small sizes. A lush,
enchanted temperate woodland (Greenward) built from soft rounded silhouettes,
deep mossy greens and warm gold, punctuated by cool teal spirit-light, violet
arcane and ember magic. Warm light (lanterns, sun) plays against cool light
(moon, magic, water) so the player can always read time-of-day and safe vs
magical spaces. Readability first: allies, enemies, interactables and elements
must be identifiable at a glance on a 5-inch screen. No text is baked into art;
no copyrighted reference traces.

---

## 1. Colour palette

All hex swatches below are the exact values in `GreenwardStyle`. Grouped by
role. `GreenwardStyle.all_colors()` returns every one of these as `Color`
objects for coherence tests; `GreenwardStyle.coherence_report()` verifies the
groups are present, valid and internally distinct.

### 1.1 Sky / dawn / dusk / night (`GreenwardStyle.SKY`)

| Role | Hex | Notes |
| --- | --- | --- |
| Dawn top | `#3a4a7a` | cool indigo above a warm horizon |
| Dawn bottom | `#f0b89a` | peach horizon |
| Day top | `#4a86c8` | clear blue |
| Day bottom | `#bfe0f0` | hazy pale blue |
| Golden-hour top | `#5a6ea0` | deepening blue |
| Golden-hour bottom | `#ffcf87` | amber horizon |
| Dusk top | `#3d3a6b` | violet |
| Dusk bottom | `#e8886a` | coral |
| Nightfall top | `#1c2250` | deep blue |
| Nightfall bottom | `#4a4070` | violet horizon |
| Night top | `#0a1030` | near-black indigo |
| Night bottom | `#2a3566` | moonlit blue |

### 1.2 Canopy & undergrowth greens (`CANOPY`, `UNDERGROWTH`)

| Role | Hex | Notes |
| --- | --- | --- |
| Canopy deep | `#24402b` | shadowed leaf mass |
| Canopy mid | `#3f6b3f` | body of foliage |
| Canopy light | `#5d8f52` | sunlit leaves |
| Canopy rim / spirit rim | `#9df5cf` | cool rim highlight |
| Pine | `#2f5234` | conifer mass |
| Moss / canopy moss | `#4f7a46` | mid moss |
| Bright | `#8fbf6a` | fresh growth |
| Autumn | `#c9a45a` | dry/autumn accent |
| Blossom | `#ffc2d6` | sakura canopy |
| Birch bark | `#e8e4d0` | pale banded trunk |
| Undergrowth dark | `#2f5234` | deep grass shadow |
| Undergrowth mid | `#4f7a46` | |
| Undergrowth light | `#5d8f52` | |
| Grass A / B | `#568449` / `#5c8c4f` | terrain instance tints |
| Dry highland | `#8a7a55` | dry/elevated tint + path base |
| Reeds | `#7f9a55` | |
| Lily | `#4f8a54` | |

### 1.3 Water (`WATER`)

| Role | Hex | Notes |
| --- | --- | --- |
| Shallow | `#3f8f96` | shoreline depth tint |
| Deep | `#1f5568` | deep channel tint |
| Foam | `#d9f5ef` | shore/edge foam |
| Reflection | `#bfe8e6` | sky reflection highlights |
| Shore / sand | `#cbb98a` | beach band |
| Glint | `#eafbff` | specular sparkle |
| Waterfall | `#9fd8dd` | falling-water streak |

### 1.4 Stone (`STONE`) & timber (`TIMBER`)

| Role | Hex | Notes |
| --- | --- | --- |
| Stone light | `#8a8776` | lit face |
| Stone mid | `#62645a` | body |
| Stone dark | `#4a4a44` | shadow |
| Stone moss | `#6f8f5a` | mossy top |
| Stone moss-dark | `#5d7a4a` | |
| Stone rune | `#7fe3e0` | engraved glow |
| Wet stone | `#3a4a50` | river rock |
| Timber light | `#6b4c33` | lit plank |
| Timber mid | `#5a4030` | |
| Timber dark | `#3a2a1c` | shadow / trim |
| Plank / roof | `#4a3524` | |
| Warm timber | `#8a6440` | |
| Thatch | `#b89257` | cottage roof |

### 1.5 Magic (`MAGIC`), light (`LIGHT`), accents (`ACCENTS`), UI (`UI`)

| Group | Key | Hex |
| --- | --- | --- |
| Magic | teal | `#7fe3e0` |
| Magic | gold | `#ffcf6a` |
| Magic | violet | `#b78bff` |
| Magic | ember | `#ff8a5c` |
| Magic | teal-deep | `#2a8f9f` |
| Magic | teal-light | `#c9fffb` |
| Magic | violet-light | `#e0c8ff` |
| Light | warm lantern | `#ffcf6a` |
| Light | warm glow | `rgb(1.0, 0.8, 0.45)` |
| Light | cool moon | `#9fc0ff` |
| Light | moon glow | `rgb(0.6, 0.75, 1.0)` |
| Light | magic | `#9df5cf` |
| Accent | petal | `#ffb3c7` |
| Accent | petal-alt | `#ffe9a3` |
| Accent | petal-violet | `#c9a0ff` |
| Accent | berry | `#c0405a` |
| Accent | rune | `#9df5cf` |
| Accent | rune-gold | `#ffe6a8` |
| Accent | ember-spark | `#ffb060` |
| Accent | glow-mushroom | `#8fe3c0` |
| Accent | mushroom-cap | `#b05a5a` |
| Accent | butterfly | `#ffd27a` |
| Accent | moth | `#d8c8a0` |
| Accent | bird | `#6fa8d8` |
| Accent | firefly | `rgb(0.65, 1.0, 0.9)` |
| UI | bg / panel / text | `#080b16` / `#121a2e` / `#e9eef9` |
| UI | gold / teal / green / violet / danger | `#e8c27a` / `#7fe3e0` / `#8fe3a0` / `#b78bff` / `#ff7a8a` |

`GreenwardStyle.INK = #161a24` is the shared dark readability outline.
`GreenwardStyle.ELEMENTS` mirrors `UITheme.ELEMENT` (fire `#ff8a5c`,
wind `#8fe3a0`, earth `#c9a86a`, water `#6fc8ff`, light `#ffe6a8`,
dark `#b78bff`, neutral `#9aa8c2`) so `element_color()` agrees across world,
portraits, VFX and UI badges.

---

## 2. Lighting

Lighting is driven by `GreenwardStyle.phase(name)`, which returns
`tint` (a `CanvasModulate`-style colour), `ambient`, `light_energy`, `fog`,
`fog_density`, `fireflies`, `sky_top` and `sky_bottom` for every named phase.
The exact phase strings emitted by `scripts/world/day_night.gd` are covered
(Midnight, Dawn, Morning, Noon, Afternoon, Dusk, Nightfall), plus the canonical
names Dawn / Day / Golden Hour / Dusk / Nightfall / Midnight. Unknown names
fall back to `Day`.

| Phase | Tint (rgb) | Ambient | Light energy | Fireflies | Fog |
| --- | --- | --- | --- | --- | --- |
| Midnight | `0.34, 0.40, 0.62` | 0.32 | 0.45 (moon) | yes | cool dense `0.12,0.16,0.30` |
| Dawn | `0.82, 0.70, 0.72` | 0.62 | 0.80 | no | pink mist |
| Morning | `1.00, 0.97, 0.91` | 0.90 | 0.50 | no | light |
| Noon / Day | `1.00, 1.00, 1.00` | 1.00 | 0.30 | no | minimal |
| Afternoon | `1.00, 0.95, 0.86` | 0.95 | 0.40 | no | light warm |
| Golden Hour | `1.00, 0.85, 0.62` | 0.80 | 0.70 | no | warm amber |
| Dusk | `0.94, 0.68, 0.58` | 0.60 | 0.90 (lanterns) | yes | warm coral |
| Nightfall | `0.50, 0.48, 0.70` | 0.42 | 0.70 | yes | violet blue |

**Warm-vs-cool contrast is the core rule.**
- **Warm** = lanterns (`LIGHT.warm_lantern #ffcf6a`), sun/golden-hour, hearth
  windows, fireflies' glow, ember/gold magic. Signals *safety, village, day*.
- **Cool** = moon (`LIGHT.cool_moon #9fc0ff`), teal spirit-light
  (`MAGIC.teal #7fe3e0`), water reflections, violet arcane. Signals *magic,
  night, the unknown*.
- Point lights use `ProceduralArt.soft_glow()` (additive). Village lanterns are
  warm (`1.0, 0.78, 0.45`), the waypoint/ruin crystals are cool teal. Fog uses
  `fog.gdshader` with `fog_color`/`density` uniforms; `fireflies` gates the
  night particle emitter.

---

## 3. Environment materials

| Material | Look | Implementation |
| --- | --- | --- |
| **Terrain diamond** | 2:1 iso diamond, hand-painted bevel, per-tile grain, moisture + elevation grass blend, sandy beach band, foam shoreline, varied paths | `terrain.gdshader` on one `MultiMesh` per chunk; per-instance `COLOR` carries the tint |
| **Water** | Stylised sky reflections, moving glints, depth shading, pulsing shore foam | `water.gdshader`, animated via `TIME`, depth from per-instance `COLOR` |
| **Stone** | cool greys with mossy tops and teal runes | `STONE` palette; rocks, ruins, bridges, rune stones |
| **Timber** | warm planks, dark trim, thatch roofs | `TIMBER` palette; huts, cottages, docks, carts, fences |
| **Foliage** | layered canopy ellipses, base-anchored wind sway, rim highlights | `CANOPY`/`UNDERGROWTH`; `wind_sway.gdshader` (vertex-only, per-instance world-space phase + secondary shimmer) |
| **Magical crystal** | translucent teal shards with bright cores and soft glow | `MAGIC`; `soft_glow()` lights |
| **Ground cover** | tiny tufts/petals/pebbles/lily pads | single `MultiMesh` `detail` layer + `detail.gdshader` (soft rounded alpha mask) |

Shaders are deliberately cheap (few `sin`/`pow`, no texture lookups,
mobile-safe). Terrain, water and detail are each **one draw call per chunk**.
`fog.gdshader` is a noise-free, UV+TIME full-screen veil.

---

## 4. Character proportions

- **Head:body ratio ≈ 5.5–6 heads tall** (stylised, slightly heroic — not
  chibi, not realistic 8-head). The placeholder `character_frame` humanoid
  uses a ~90 px figure with a ~17 px head (≈5.3–5.6 heads) on a 96×128 canvas.
- **Soft, rounded silhouettes for allies; sharper asymmetric shapes for
  corrupted enemies** (matches `ActorVisual` / `PortraitView`).
- **Foot baseline rule:** feet sit on a fixed ground line (`y ≈ 120` on the
  world canvas). All frames, all states, all directions keep the feet on this
  same baseline — drifting baselines cause visible foot-sliding. The world
  positions actors by their ground point, so the sprite anchor is
  bottom-centre `(0.5, 1.0)`.
- **Outline:** 1–2 px dark `INK` outline for readability at 1×.
- Character colour comes from a data palette dictionary
  `{ hair, primary, secondary, accent, skin }`; `character_frame()` and
  `ActorVisual` read the same keys so a character reads consistently
  everywhere. `GreenwardStyle.element_color()` adds element-tinted accents.

---

## 5. Sprite dimensions

| Asset | Size (px) | Anchor |
| --- | --- | --- |
| World character (small) | **96 × 128** | bottom-centre `(0.5, 1.0)` |
| Boss / elite | **128 × 192** | bottom-centre |
| Props | **64–256** (canvas per kind) | bottom-centre, ground contact |
| Portraits (master → HUD) | 1024×1280 → 128×160 | eyes upper third |
| Logical tile | **64 × 32** | tile centre (terrain) |
| Master tile export | **128 × 64** (2×) | 4 px transparent bleed |
| UI icons | 32×32 / 64×64 | — |

`GreenwardStyle.SPRITE_SPECS` is the machine-readable source:
`world_width 96`, `world_height 128`, `boss_width 128`, `boss_height 192`,
`anchor Vector2(0.5, 1.0)`, `outline_px 2`, plus `fps`/`frames`/`loop` per
state (and parallel int-indexed arrays `frame_counts`, `fps_values`,
`loop_flags`).

---

## 6. Animation conventions

**8 states** (ints): `0 IDLE, 1 WALK, 2 RUN, 3 INTERACT, 4 ATTACK, 5 DAMAGE,
6 VICTORY, 7 DEFEAT`. **8 directions** (ints): `0 DOWN, 1 DOWN_RIGHT,
2 RIGHT, 3 UP_RIGHT, 4 UP, 5 UP_LEFT, 6 LEFT, 7 DOWN_LEFT`.

| State | Frames | fps | Loop | Priority / notes |
| --- | --- | --- | --- | --- |
| IDLE | 5 | 9 | loop | default, subtle breathing bob |
| WALK | 7 | 12 | loop | locomotion, leg/arm swing |
| RUN | 7 | 14 | loop | bigger swing + forward lean |
| INTERACT | 6 | 12 | one-shot | reaching arm + glow |
| ATTACK | 6 | 15 | one-shot | slash arc |
| DAMAGE | 2 | 12 | one-shot | high interrupt priority; recoil + flash |
| VICTORY | 8 | 12 | one-shot | arms raised, sparkles |
| DEFEAT | 6 | 10 | one-shot | non-looping, crouched; holds last frame |

(These fps/frame/loop values are the authoritative ones in
`CharacterAnimator.STATE_FPS / STATE_FRAMES / STATE_LOOPING`; `SPRITE_SPECS`
mirrors them so the animator, frame source and art spec never disagree.)

### Phase 4 — additive CAST (9th state)

The 8-core-state timing table above stays authoritative. Phase 4 added an
**ADDITIVE 9th state** `CAST = 8` to `CharacterAnimator` **without** changing
that model: `ALL_STATES` stays 8 and all Phase-3 timing arrays are unchanged.
CAST has its OWN spec, mirrored by `GreenwardStyle.CAST_SPEC`:

| State | Frames | fps | Loop | Priority / notes |
| --- | --- | --- | --- | --- |
| CAST (8, additive 9th state) | 7 | 12 | one-shot | ATTACK tier (5); returns to IDLE via `RETURN_STATES`; distinct CAST pose + `ActorVisual` CAST aura |

Extras: `EXTENDED_STATES` = 9, `EXTENDED_STATE_NAMES`, `LOCOMOTION_STATES`,
`RETURN_STATES`, `frame_count_for/fps_for/looping_for/priority_for`,
`transition_to`, `can_transition`, `finish_and_return`, `play_cast`,
`cast_active`, `previous_state`, `transitioned` signal. `ActorFrameSource`
gained `cast_frame/cast_frame_count/cast_fps/validate_sheets/extended_specs`;
`ProceduralActorFrames` implements them. `ProceduralArt.character_frame()`
supports state 8 with a distinct pose; `SpriteFramesActorSource` sheet
animations are named `<state>_<dir>` plus `cast_<dir>` (9 × 8 animations).
This is genuinely additive: as Phase 3 noted, "directional movement" is the
DIRECTION axis, NOT a 9th state — CAST is a real one-shot state, not a
direction. See §12 for the full Phase 4 status.

**Conventions:**
- **Foot-baseline rule** applies to every frame of every state.
- **Loop vs one-shot:** locomotion/idle loop; `INTERACT/ATTACK/DAMAGE/VICTORY/
  DEFEAT` are one-shot and return to a context state on completion.
- **Transition / priority:** `DEFEAT` > `VICTORY` > `DAMAGE` > `ATTACK` >
  `INTERACT` > `RUN` > `WALK` > `IDLE` (matches `CharacterAnimator.STATE_PRIORITY`).
  Higher priority interrupts lower; a lower-priority request cannot interrupt a
  higher-priority unfinished one-shot; looping states never lock. One-shots
  finish (or are interrupted only by a strictly higher priority state) before
  returning to locomotion/idle. Never cut a one-shot mid-pose into a
  lower-priority loop.
- **Direction handling:** up-ish directions (3/4/5) show the back of the head
  (no eyes); left-ish (5/6/7) mirror features; diagonals (1/3/5/7) use a 3/4
  view. A dark `INK` outline stays on every direction for readability.
- `ProceduralArt.character_frame(palette, state, direction, frame_index)`
  returns a **cached, non-null RGBA8 `ImageTexture`** (96×128) per
  (palette-hash, state, direction, frame_index). These are **clearly marked
  TEMPORARY PLACEHOLDER frames** — simple coherent humanoid poses that
  genuinely differ per state/direction/frame so the animation pipeline has
  real loops to drive. Generation happens once, never per-frame. Replace with
  painted sheets via ART_PIPELINE.md.

---

## 7. Asset naming

- `lower_snake_case`, ASCII only. Character folders use the **content ID**
  (`mira_sol`), not the display name.
- Prop kinds are stable lowercase IDs (e.g. `willow_tree`, `flower_cluster`,
  `rune_stone`, `crystal_cluster`) and are exactly the strings in
  `GreenwardStyle.prop_kinds()` / `ProceduralArt.prop_kinds()`.
- Frame files: `<character>_<state>_<direction>_<frame>.png`; sheets:
  `<character>_<state>_<direction>.png`.
- Tiles: `tile_<biome>_<variant>.png`; shaders: `<effect>.gdshader`.
- Variants are appended `__v<n>` where a real asset needs multiple silhouettes
  (the procedural `prop_texture(kind, variant)` already distinguishes them).
- Keep source masters outside the export; never overwrite a master with an
  export. Record every third-party file in `THIRD_PARTY_NOTICES.md`.

---

## 8. Import settings

| Asset class | Filter | Mipmaps | Compression | Alpha |
| --- | --- | --- | --- | --- |
| Painted world sprites / tiles | Linear | On (variable zoom) | VRAM (platform) / lossless UI | Fix alpha border on atlases |
| Pixel-art style | Nearest | Off | Lossless | Off |
| Portraits | Linear | On if shown < master | Lossless | Keep aspect, never stretch |
| Procedural `ImageTexture` (current) | Linear | Off | None (RGBA8 in-memory) | Straight alpha, premultiply-free |
| UI / 9-slice | Linear | Off | Lossless | Fix alpha border |

- Current procedural textures are `Image.FORMAT_RGBA8`, `Texture2D`, cached;
  `ProceduralArt.clear_cache()` resets them. `white_pixel()` is a 2×2 opaque
  fallback.
- Terrain shaders discard fragments outside the iso diamond; never ship square
  tiles with visible corners.
- Audio (none yet): Ogg Vorbis music/voice, WAV/Ogg SFX, normalised.

---

## 9. Coherence rules

These are the non-negotiable rules that keep the placeholder art looking like
one game. `GreenwardStyle.coherence_report()` enforces the machine-checkable
subset and returns `[]` when the palette is internally consistent.

1. **Single source of truth.** Every colour used by new painters, shaders and
   chunk tinting comes from `GreenwardStyle` — no stray inline hex in new art
   code. (Original twelve prop painters keep inline literals so `variant 0`
   reproduces the shipped look exactly.)
2. **Named, grouped, distinct.** Colours live in named groups (sky, canopy,
   undergrowth, water, stone, timber, magic, light, accent, UI); roles that
   must differ (shallow vs deep water, canopy deep/mid/light, teal vs gold vs
   violet vs ember, warm lantern vs cool moon, light vs dark stone/timber) must
   not collapse to the same value.
3. **Valid `Color`s.** Every entry in `all_colors()` is a finite `Color` with
   components in `[0,1]`.
4. **Phase coverage.** `phase()` returns all eight required keys for every
   canonical name AND every `day_night.gd` phase string, with sensible types
   (`tint`/`fog`/`sky_*` are `Color`, `fireflies` is `bool`).
5. **Prop coverage.** Every `prop_kinds()` entry has a non-empty
   `prop_palette()`, a `variant_count >= 1` (≥2 for trees/flowers/structures),
   and a category tag.
6. **Cross-screen palette.** `element_color()` matches `UITheme.ELEMENT` and
   `UI`/`ACCENTS` agree with `UITheme` so a character's element reads the same
   in world, portrait, VFX and UI.
7. **Sprite contract.** World frames are exactly 96×128 RGBA8, boss 128×192,
   bottom-centre anchor, 1–2 px `INK` outline, fixed foot baseline.
8. **Determinism.** Same `(coord, region)` → identical chunk output; variants
   are deterministic and visually distinct (different silhouette / leaf
   cluster / petal arrangement / hue, never just a flat tint). No global RNG.
9. **Performance caps.** Prop count is capped by
   `GreenwardStyle.MAX_PROPS_PER_CHUNK` (lowered on the `mobile` tier via
   `performance_tier()`); particles by `MAX_PARTICLES`; ground cover by
   `DETAIL_DENSITY`. One draw call per terrain/water/detail layer.
10. **Readability first, no baked text, no copyrighted traces, no colour-only
    element coding** (pair colour with a shape/icon).

---

## 10. What exists today vs. the target (honest status)

| Area | Today (placeholder) | Target |
| --- | --- | --- |
| Terrain / water / detail / fog | Procedural `MultiMesh` + shaders | Painted tile atlases + authored materials |
| Props | 57 procedurally drawn kinds (47 Phase-3 + 6 Phase-4 + 4 Phase-5: `birch_grove`, `moon_lantern`, `stone_path`, `village_gate`) with deterministic variants | Painted prop sheets (64–256 px) |
| Characters | `ActorVisual` primitives + `character_frame()` placeholder frames | Painted sprite sheets, `AnimatedSprite2D` |
| Portraits | `PortraitView` procedural bust | Painted busts |
| UI / VFX | `UITheme` styleboxes, `soft_glow` | 9-slice panels, icon/VFX sheets |
| Audio | None | Licensed Ogg/WAV |
| Lighting | `CanvasModulate` tint + point lights + fog shader | Baked/gradient lighting |
| Profiling | **None** (coarse platform tier only) | On-device draw-call / memory profiling |

Replacement workflow, export sizes, mobile budgets and the "what not to do"
checklist are in [ART_PIPELINE.md](ART_PIPELINE.md). The public APIs to keep
stable are `ProceduralArt.prop_texture(kind, variant)`, `soft_glow()`,
`character_frame()`, `ActorVisual.setup()` and `PortraitView.setup_character()`.

---

## 11. Phase 3 implementation status

> **This section is the Phase 3 snapshot** — accurate for what Phase 3 shipped
> (one region, 47 prop kinds, no CAST). For the Phase 4 snapshot (exactly TWO
> regions, 53 prop kinds, additive CAST, the real art asset pipeline), see **§12**
> below; the **CURRENT Phase 5 status is §13**.

- **This document is the CANONICAL visual style guide** for Phase 3. The
  machine-readable companion that IMPLEMENTS it in code is
  `scripts/world/visual_style.gd` (`class_name GreenwardStyle`) — the **single
  source of truth** for grouped palettes, `phase(name)` lighting/fog presets,
  `prop_palette(kind)`, `element_color()`, `prop_kinds()`, `variant_count()`,
  `SPRITE_SPECS`, `all_colors()`, `coherence_report()`, `performance_tier()` and
  the caps (`MAX_PROPS_PER_CHUNK = 48`, `MAX_PARTICLES = 300`,
  `DETAIL_DENSITY = 0.22`). When this guide and the code disagree,
  `GreenwardStyle` is the implementation truth. The animation timing in §6
  matches `CharacterAnimator`'s authoritative `STATE_FRAMES` / `STATE_FPS` /
  `STATE_LOOPING`.

Shipped Phase 3 systems (all wired into `GreenwardWorld`):

- `GreenwardStyle` + this `VISUAL_STYLE.md` (art direction / palette authority).
- `ProceduralArt` now paints **47 prop kinds** with deterministic `variant`s via
  `prop_texture(kind, variant)`, cached with variant keys.
- `ChunkBuilder`: richer terrain (moisture+elevation blend, beach band,
  shoreline foam), a meandering noise-derived RIVER ribbon, and a new `detail`
  `MultiMesh` ground-cover layer (one extra draw call, child of `terrain`).
- Shaders: `fog.gdshader` (UV+TIME atmospheric veil, quad layered BELOW the
  HUD), `detail.gdshader`, improved `water.gdshader` (reflections/glints/foam/
  depth) and `wind_sway.gdshader` (per-instance phase + secondary shimmer).
- `CharacterAnimator` (8 states × 8 directions — **"directional movement" is
  the DIRECTION axis, NOT a 9th state**), `ActorFrameSource` (stable replacement
  interface + `REPLACEMENT_SPEC`), `ProceduralActorFrames` (TEMPORARY
  placeholder), and the `ActorVisual.set_frame_source()` seam.
- `WeatherDirector` (CLEAR/MIST/RAIN/POLLEN_BLOOM architecture, deterministic
  transitions, intensity ramp, mobile caps), `AnimatedProp` (bob/sway/pulse/
  flicker/drift with off-screen gating), `InteractiveProp` (non-destructive
  highlight/toast; does NOT mutate `GameState`).
- `DayNight` tint sourced from `GreenwardStyle.phase()`; `MainBackdrop` aligned
  to the shared palette with drifting motes; phase-driven lighting, fog,
  pollen/fireflies/rain, ambient wildlife and **5 visually distinct locations**
  (village hub, Listening Stones ruins, Hollowed Grove, Moonpetal Shrine glade,
  the decorative river with waterfalls and wooden + stone bridges).
- Performance: one `MultiMesh` draw call per terrain/water/detail layer per
  chunk, capped props (48/chunk, ~26 mobile), capped particles (≤300), cached
  textures, off-screen animated-prop gating, fog and rain disabled on mobile.
  Chunk streaming, `_update_streaming` diffing, `IsoMath` / `ChunkStreamer`
  behaviour are all preserved.

**Which assets are final vs placeholder: ZERO assets are final.** Every sprite,
tile, prop, portrait, frame and VFX shipped in Phase 3 is **procedural
placeholder art** generated in code at runtime. There are no final painted
sprites, sprite sheets, textures, portraits, VFX or imported art, and **no audio
of any kind**. `ProceduralActorFrames` / `ProceduralArt.character_frame()` are
explicitly TEMPORARY; real art plugs in via `ActorVisual.set_frame_source()` with
an `ActorFrameSource` subclass. No device profiling has been performed (the
mobile tier is a coarse `OS.get_name()` hint), weather is an architecture not a
simulation (rain is one capped emitter, disabled on mobile), and only Greenward
is playable — no additional regions were added. See [ART_PIPELINE.md](ART_PIPELINE.md)
for the replacement workflow.

---

## 12. Phase 4 implementation status

> **This is the Phase 4 snapshot; §11 above is the Phase 3 snapshot. For the
> CURRENT status see §13 (Phase 5 implementation status) below.** Phase 4
> re-scoped to world expansion, a real art asset pipeline and character
> animation — it did NOT implement the narrative systems. `VISUAL_STYLE.md`
> remains the CANONICAL art-direction guide and `GreenwardStyle` remains the
> single source of truth in code (now including `CAST_SPEC`); see
> [ART_PIPELINE.md §14](ART_PIPELINE.md) for the full 8-class asset contract and
> [ART_PIPELINE.md §15](ART_PIPELINE.md) for the current Phase 5 contract.

Shipped in Phase 4 (on top of the preserved Phase 3 guide):

- **Additive CAST animation.** `CharacterAnimator` gained an ADDITIVE 9th
  state `CAST = 8` while `ALL_STATES` stays 8 and all Phase-3 timing arrays
  are unchanged — see the separate CAST spec in §6. `GreenwardStyle.CAST_SPEC`
  (7 frames @ 12 fps, one-shot, ATTACK tier), `EXTENDED_STATES` = 9,
  `RETURN_STATES`, `play_cast()` / `cast_active()`, `transitioned`,
  `SpriteFramesActorSource` (`<state>_<dir>` + `cast_<dir>` sheet naming),
  `ActorVisual.play_cast()` + CAST aura, and `ProceduralArt.character_frame()`
  state 8 with a distinct pose. All 8 directions still apply.
- **53 prop kinds.** Six new detailed building/landmark kinds — `watchtower`,
  `market_stall`, `stone_wall`, `gazebo`, `banner_post`, `moon_shrine` (4 placed
  at Greenward landmarks) — bring `ProceduralArt.prop_kinds()` /
  `GreenwardStyle.prop_kinds()` / `ContentValidator.PROP_TYPES` from 47 to
  **53**, each with distinct variants via `prop_texture(kind, variant)`.
  Better paths, elevation/moisture-biased forest variation and distinct
  environmental zones (`GreenwardWorld.current_zone()`) were added.
- **Exactly TWO regions.** `regions.json` now has `greenward` +
  `moonpetal_hollow` (a small silver-birch moonlit vale). `moonpetal_hollow`
  has its own **cooler violet/silver biome palette** (`biome.grass_colors`
  `#6b7a9c / #7d8bb0 / #5a6a8c / #909dba`, `path_color #8a86a8`,
  `water_shallow #4a6fa5`, `water_deep #28335e`), `noise_seed 24601`,
  `load_radius 1`, 2 pois and 2 spawns. A `RegionGraph` (`region_graph.gd`),
  `world_origin` logical world coordinates, `entry_points`, bidirectional
  `connections` (via/entry/kind/label) and `RegionPortal` gates drive travel;
  `GameState` keeps per-region saves (`region`, `region_positions`).
  `ChunkStreamer` / `IsoMath` are unchanged.
- **Region-specific environment / fog / weather.** Each region declares
  `environment` (`zone`, `weather_bias`, `fog_density`, `ambient_tint`,
  `ambient_music`) — `greenward` is `temperate_forest` (`fog_density 0.18`,
  teal `#7fe3e0` tint), `moonpetal_hollow` is `moonlit_vale`
  (`fog_density 0.32`, cool `#9db4ff` tint) — applied to atmosphere so the
  two regions read differently. `ambient_music` is an empty hook; **no audio
  exists**.
- **Real art asset pipeline (placeholder-only).** `AssetManifest`
  (`scripts/art/asset_manifest.gd`), `SpriteFramesActorSource` and
  `DemoCharacterFrames` define the 8 asset classes and the replacement seams
  (see [ART_PIPELINE.md §14](ART_PIPELINE.md)). Frame-sliced main-thread
  background chunk preparation (`ChunkPreparer`) with **NO threads**.

**Exact asset status (from `AssetManifest.status_report()`): FINAL 0 / TEMPORARY 8 / MISSING 8.** `check_disk()` is `false` for all 8; the only image
file in the project is `icon.svg`. **ZERO final painted assets**, **no audio**,
**no real sprite sheets / PNG textures on disk**; all shipped art is runtime
procedural placeholder. The ONE demonstration character uses a **TEMPORARY
in-memory procedurally-generated `SpriteFrames`** (`DemoCharacterFrames`), NOT
final art. No fake painted art was fabricated from polygons.

**Honest limitations:** **no device profiling** (the `mobile` tier is a coarse
`OS.get_name()` hint; headless uses a dummy renderer, so shader compilation and
visual appearance are not verified); **no threads** (chunk preparation is
main-thread frame-sliced); weather is an architecture, not a simulation (one
capped rain emitter, disabled on mobile); **only TWO regions** with no
elevation/cliffs/water traversal rules, no seamless zone streaming, no fast
travel / map / fog-of-war, no mounts, no spawn directors and no world audio
ambience; region transitions are validated and wired but cannot be
interactively playtested headlessly; `greenward`'s village/NPC/landmark layout
remains partly HARDCODED (the second region is data-driven); there is **no
multiplayer, backend, server authority, accounts, trading or PvP** (local JSON
save and gacha/currency/inventory/rewards are client-side NON-AUTHORITATIVE
until Phase 12); CI (`.github/workflows/ci.yml`) is configured and locally
verified but has NOT been executed on GitHub Actions; all art/lore is original,
the project is not a git repo and all changes are local uncommitted files.

---

## 13. Phase 5 implementation status

> **This is the CURRENT status** (§11 = Phase 3 snapshot, §12 = Phase 4 snapshot).
> Phase 5 re-scoped to **character art and visual production** — it built the
> production pipeline, authored 12 character specs and wired a coherent
> presentation layer, but produced **NO finished artwork**. `VISUAL_STYLE.md`
> remains the CANONICAL art-direction guide and `GreenwardStyle` remains the
> single source of truth in code. See [ART_PIPELINE.md §15](ART_PIPELINE.md) for
> the full 10-kind contract, the 12-spec table and the exact asset status.

### Consistent anime-fantasy character art direction

All 12 characters share ONE art direction via `CharacterArtSpec.STYLE_ANCHOR` /
`assets/GENERATION_PROMPTS.md`: ~6-head heroic proportions (not chibi, not
realistic 8-head), a consistent upper-left key light with a cool rim light,
a 1–2 px dark `INK` outline, cel-shaded painterly rendering, transparent RGBA8
backgrounds, feet on ONE baseline, the shared `GreenwardStyle` palette language
(deep indigo night, mossy emerald, warm gold, teal spirit-light, violet arcane,
ember accents), no baked text and no copyrighted reference traces. Each character
adds distinct per-character motifs (wind ribbons/leaves, bramble roots, sunburst
halo, hollow-moon eclipse, tide ribbons, cinder crown, plain gate/shield,
wishlight lantern, black roses, spider silk, cliff strata, charred banner) so the
12 read as one game yet stay individually recognisable.

### Legendary / Mythic premium tier

`UITheme.RARITY_EFFECTS` + `rarity_effect` / `is_premium_rarity` / `rarity_glow`
/ `rarity_tier_label` give Legendary/Mythic a distinct glow, border, aura and
frame. `PortraitView` draws a deterministic premium aura + inner frame,
`CollectionScreen` premium card borders / tier labels / flourish / larger
portrait, `GachaScreen` a rarity-tinted featured backdrop / premium result cards
/ reveal scale-pop + "Best:" flourish, and `UnitCard` a premium border. The ONE
mythic (`ignis`) and 3 legendary (`seraphine`, `nyx`, `terra`) specs carry
explicit premium `tier_note`s (ornate halo/crown, persistent aura, engraved
frame). **These are code-driven `_draw()`/tween/theme effects** — see the
"no visual testing" caveat below.

### The 12 specs, real-portrait seam and sprite registration

- **12 authored specs** (`CharacterArtSpec`, `assets/CHARACTER_SPECS.md` +
  `assets/characters/<id>/SPEC.md`): `lyra_vey`, `bramble`, `seraphine`, `nyx`,
  `coralyn`, `ignis`, `mira_sol`, `thistle`, `vespera`, `arachnia`, `terra`,
  `kael`. Identity verbatim from `characters.json` (gameplay data UNCHANGED);
  1 mythic / 3 legendary / 4 epic / 3 rare / 1 common. Specs + prompts are
  **PREPARATION for future external art, not finished artwork**.
- **Real-portrait seam.** `PortraitView.portrait_texture` /
  `set_portrait_texture()` / `portrait_report()` via `PortraitAssetSource`
  (null-safe `texture_for(<id>)`), with a GUARDED procedural `_draw()` fallback.
  ZERO final portraits exist, so `portrait_texture == null` for all 12 and the
  fallback renders.
- **Sprite-sheet registration (9 × 8).**
  `SpriteFramesActorSource.register_character()` / `validation_report()` /
  `animation_names()` / `registration_report()` cover all 9 states (8 core +
  additive CAST) × 8 directions = **72 animations**;
  `ActorVisual.configure_character()` / `character_art_report()` are called by
  `WorldNPC` / `RoamingMonster`. `ProceduralActorFrames` REMAINS the active
  fallback (no real sheets on disk); the §6 timing table (8 core + additive
  CAST) is the authoritative spec.

### World visual standards and 57 prop kinds

`WorldVisualStandards` (`scripts/world/world_visual_standards.gd`) defines **6
categories** (player / npc / monster / building / vegetation /
environment_object) with canvas, anchor, outline, palette group, z-index,
batching and fallback; `region_tint()` gives Greenward an emerald tint and
Moonpetal Hollow a silver-violet tint; `validate()` returns `[]`.
`GreenwardWorld.apply_visual_standards()` / `visual_standards_report()` + 4 new
`visual_style_report()` keys. Distinct bounded Moonpetal Hollow silver-birch /
moonlit composition and a Greenward village-gate composition. 4 NEW prop kinds
(`birch_grove`, `moon_lantern`, `stone_path`, `village_gate`) bring the total to
**57 prop kinds** (`ContentValidator.PROP_TYPES`,
`GreenwardStyle.coherence_report() == []`).

### EXACT ASSET STATUS (ZERO final) and honest limitations

> **FINAL 0 / TEMPORARY 8 / MISSING 8** (`AssetManifest.status_report()`, 8 asset
> classes; `check_disk()` false for all 8) and **FINAL 0 / TEMPORARY 120 /
> MISSING 120** (`CharacterAssetRegistry.report()`, 12 characters × 10 kinds =
> 120; `check_disk()` false for all 120). Both are disk-computed; FINAL is NEVER
> hardcoded.

- **ZERO final assets.** All shipped art is runtime procedural placeholder; no
  `.png/.webp/.jpg/.tres/.res` art files anywhere, the only image is `icon.svg`;
  the ONE demonstration character is a TEMPORARY in-memory procedural
  `SpriteFrames` (`DemoCharacterFrames`, `loaded_from_disk == false`). No fake
  painted art was fabricated from polygons. **No audio** exists.
- **NO visual testing was performed.** All verification is `--headless` with
  Godot's dummy renderer: `_draw()` output, auras, borders, tints, silhouettes
  and tween pops are compile/build-safe and structurally asserted but were NOT
  visually inspected on screen; no shader compilation / appearance verification
  and **no device profiling**.
- No threads (chunk preparation is main-thread frame-sliced); weather is an
  architecture, not a simulation; exactly TWO regions with no elevation/cliffs/
  water traversal rules, no fast-travel/map/fog-of-war, no mounts, no spawn
  directors, no world audio ambience; `greenward`'s village layout is partly
  hardcoded; no multiplayer/backend/server authority (client-side
  gacha/currency/inventory/rewards and local JSON save NON-AUTHORITATIVE until
  Phase 12); CI (`.github/workflows/ci.yml`) is configured and locally verified
  but has NOT been executed on GitHub Actions; all art/lore is original, the
  project is not a git repo and all files are local uncommitted files.
- `1374 passed, 0 failed` (236 + 111 + 203 + 404 + 420); all 6 verification
  commands exit `0` with ZERO errors/warnings/leaked RIDs; a non-empty
  `--export-pack "Linux/X11"` `.pck` smoke build. See `TESTING.md`.
