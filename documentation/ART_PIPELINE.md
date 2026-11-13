# Art and Audio Pipeline

The vertical slice deliberately ships **zero third-party visual assets**. Everything is generated in code so the project can be developed, tested and shared without licensing ambiguity. This document explains what exists, how to replace it, and the production specs to target.

---

## 1. Current placeholder pipeline

| Layer | Implementation | Replacement seam |
| --- | --- | --- |
| Terrain | `ChunkBuilder` + `terrain.gdshader`; one `MultiMesh` per chunk; diamond discard, grain, edge bevel, moisture/elevation blend, beach band, shoreline foam. A NEW `detail` `MultiMesh` ground-cover layer is parented as a child of `terrain` (one extra draw call per chunk, `detail.gdshader`) | Shader/material or tile atlas inside `ChunkBuilder`; keep the detail layer batched |
| Water | Second `MultiMesh` + `water.gdshader`; stylised reflections/glints, depth shading and animated shore foam, plus a meandering noise-derived RIVER ribbon | Same `MultiMesh` layer with a water atlas or animated material |
| Props | `ProceduralArt.prop_texture(kind, variant=0)` draws **57 prop kinds** (47 Phase-3 + 6 Phase-4 building/landmark + 4 new Phase-5 kinds: `birch_grove`, `moon_lantern`, `stone_path`, `village_gate`) with deterministic, visually distinct `variant`s into cached `ImageTexture`s; `prop_kinds()` / `variant_count()` enumerate them | Return a real `Texture2D` from `prop_texture(kind, variant)` |
| Characters (core, Phase 3) | `CharacterAnimator` (8 states × 8 directions) → `ActorFrameSource` seam → `ProceduralActorFrames` (TEMPORARY placeholder frames) → `ActorVisual` | Subclass `ActorFrameSource` (e.g. `SpriteFramesActorSource`) and register it via `ActorVisual.set_frame_source()` |
| Characters (Phase 4 CAST + demo) | ADDITIVE 9th state `CAST = 8` (`ALL_STATES` stays 8), `SpriteFramesActorSource` (`from_disk()` / `validate_sheets()`) and `DemoCharacterFrames` (ONE TEMPORARY in-memory procedural demo character wired to the player) | `SpriteFramesActorSource.from_disk(<id>)` → `ActorVisual.set_frame_source()` (see §14) |
| Art asset contract (Phase 4) | `scripts/art/asset_manifest.gd` (`AssetManifest`) — 8 asset classes with exact specs; `status_report()` = **FINAL 0 / TEMPORARY 8 / MISSING 8** | Drop real files at the recorded `res://assets/...` paths (see `assets/README.md`, `assets/ASSET_STATUS.md`, §14) |
| Second region (Phase 4) | `moonpetal_hollow` — cooler violet/silver biome, `load_radius 1`, region-specific `environment` (fog/tint/weather), 6 new landmark prop kinds | Painted biome tilesets / props via the same per-class seams |
| Background preparation (Phase 4) | `ChunkPreparer` — main-thread FRAME-SLICED chunk preparation (at most one chunk/frame), **NO threads** | Real threaded generation remains future work |
| Portraits | `PortraitView` draws a stylised bust from palette, race and element | Replace `_draw()` with a `TextureRect`/atlas lookup |
| Atmosphere | `GreenwardStyle.phase()` lighting/fog presets → `DayNight` tint + `fog.gdshader` quad + `WeatherDirector` (CLEAR/MIST/RAIN/POLLEN_BLOOM); pollen/firefly/rain particles; region-specific fog/tint/weather bias from `region.environment` | Baked lighting, authored fog/weather VFX |
| VFX / shaders | `fog.gdshader` (UV+TIME veil), `detail.gdshader` (per-instance-COLOR ground cover), improved `water.gdshader` / `wind_sway.gdshader` | Authored material/particle sheets |
| Title backdrop | `MainBackdrop` animated procedural glade with drifting firefly/pollen motes, aligned to the shared palette | Swap for a painted key art layer |
| UI | `UITheme` style boxes and `UIFactory` controls | 9-slice panels, icons and font assets |
| Audio | **None** | `AudioStreamPlayer` buses and event hooks |
| Character art pipeline (Phase 5) | `scripts/art/character_art_pipeline.gd` (`CharacterArtPipeline`) — 10 asset kinds with exact specs; `sheet_layout()` 9×8, `animation_names()` 72, `validate_asset()`, `import_settings()`, `replacement_seams()`; `assets/CHARACTER_ART_PIPELINE.md` | FUTURE external art drops into the recorded `res://assets/...` paths (see §15) |
| Character specs + prompts (Phase 5) | `scripts/art/character_art_spec.gd` (`CharacterArtSpec`) — 12 authored specs + generation prompts; `assets/CHARACTER_SPECS.md`, 12 × `assets/characters/<id>/SPEC.md`, `assets/GENERATION_PROMPTS.md` | FUTURE external generation; specs are PREPARATION, not finished art (see §15) |
| Character asset registry (Phase 5) | `scripts/art/character_asset_registry.gd` (`CharacterAssetRegistry`) — disk-computed FINAL/TEMPORARY/MISSING; `assets/ASSET_PRODUCTION_MANIFEST.md` | FINAL only when a real file exists on disk AND validates; never hardcode FINAL (see §15) |
| Portraits (Phase 5 real-portrait seam) | `PortraitView.portrait_texture` / `set_portrait_texture()` / `portrait_report()` via `scripts/art/portrait_asset_source.gd` (`PortraitAssetSource`) — null-safe lookup + guarded procedural fallback | `PortraitAssetSource.texture_for(<id>)` (see §15) |
| World visual standards (Phase 5) | `scripts/world/world_visual_standards.gd` (`WorldVisualStandards`) — 6 categories, `region_tint()`, `validate()`; `GreenwardWorld.apply_visual_standards()` / `visual_standards_report()` | Per-category painted art via existing seams (see §15) |

The important rule: **keep the public APIs stable** (`ProceduralArt.prop_texture(kind, variant)`, `PortraitView.setup_character()`, `ActorVisual.setup()` and `ActorVisual.set_frame_source()`), so gameplay and UI code do not change when art arrives. See §13 (Phase 3 snapshot) and §14 (Phase 4 snapshot); **§15 is the CURRENT authoritative Phase 5 character art pipeline and the exact asset status for BOTH registries**.

---

## 2. Visual direction

> **Canonical style guide.** [`VISUAL_STYLE.md`](VISUAL_STYLE.md) is the CANONICAL
> art-direction document for Phase 3. `scripts/world/visual_style.gd`
> (`class_name GreenwardStyle`) is the **single source of truth for the art
> direction in code** — grouped palettes (`SKY/CANOPY/UNDERGROWTH/WATER/STONE/
> TIMBER/MAGIC/LIGHT/ACCENTS/UI/ELEMENTS`), `phase(name)` lighting/fog presets,
> `SPRITE_SPECS`, `prop_palette()`, `element_color()` and the performance caps.
> When the guide and the code disagree, `GreenwardStyle` is the implementation
> truth. Keep the palette keys below aligned with it.

**Phase 4 reaffirmation.** `VISUAL_STYLE.md` is still the CANONICAL art-direction
guide and `GreenwardStyle` is still the single source of truth for the art
direction in code (now including `CAST_SPEC`). The Phase 4 real art asset
pipeline (§14) targets these exact palettes and sprite specs and does NOT
replace them — it only defines how real files drop into the existing seams.

Original anime-fantasy, painterly but readable at small sizes.

- **Palette:** deep indigo night, mossy green, warm gold, teal spirit-light, violet arcane, ember orange.
- **Shape language:** soft rounded silhouettes for allies; sharper, asymmetric shapes for corrupted enemies; glowing accents for elements.
- **Readability first:** the player must identify allies, enemies, interactables and elements at a glance on a 5-inch screen.
- **No text baked into art.** All labels and numbers are UI text.
- **No copyrighted reference traces.** Concept art must be original; do not copy existing anime/game characters.

### Palette keys

Character and enemy data already carry a palette dictionary:

```json
{
  "skin": "#f3d7c0",
  "hair": "#4a3020",
  "primary": "#3f5a6b",
  "secondary": "#c9a45a",
  "accent": "#7fe3e0"
}
```

Use these keys for portraits, world actors, UI accents and battle cards so a character reads consistently everywhere.

---

## 3. Isometric world specs

### Tiles

| Property | Target |
| --- | --- |
| Projection | 2:1 isometric diamond |
| Logical tile | 64 × 32 px |
| Master export | 128 × 64 px (2×) |
| Bleed/padding | 4 px transparent around the diamond |
| Format | PNG or WebP, lossless, sRGB |
| Filter | Linear for painted tiles; nearest only for pixel-art style |
| Anchor | Tile centre for terrain; bottom-centre for props/actors |

The terrain shader currently discards fragments outside the diamond:

```glsl
float diamond = abs(p.x) + abs(p.y);
if (diamond > 1.0) discard;
```

If you replace terrain with a painted atlas, either keep a diamond mask in the shader or author tiles with transparent corners. Do not ship square tiles with visible corners.

### Props

| Property | Target |
| --- | --- |
| Canvas | 64 × 64 to 256 × 256 px |
| Anchor | Bottom-centre (base of the object) |
| Y-sort origin | Ground contact point |
| Pivot | `(0.5, 1.0)` |
| Format | PNG with alpha |
| Wind | Foliage uses `wind_sway.gdshader`; keep UV origin at the base |

`ProceduralArt.prop_kinds()` (sourced from `GreenwardStyle.prop_kinds()`) now
returns **57 prop kinds** — 47 Phase-3 kinds (the original 12 plus 35 new),
6 new Phase-4 building/landmark kinds and 4 new Phase-5 kinds — grouped by
family:

- **Original 12:** `glade_tree`, `ancient_tree`, `rock`, `flower`, `mushroom`,
  `crystal`, `bush`, `hut`, `lantern`, `waypoint`, `ruin_pillar`, `fence`.
- **Trees (5):** `willow_tree`, `birch_tree`, `pine_tree`, `blossom_tree`,
  `dead_tree`.
- **Ground cover (9):** `fern`, `tall_grass`, `reeds`, `lily_pad`, `moss_rock`,
  `pebble`, `flower_cluster`, `berry_bush`, `glow_mushroom`.
- **Structures (10):** `cottage`, `wooden_bridge`, `stone_bridge`, `dock`,
  `well`, `shrine`, `ruin_arch`, `signpost`, `barrel`, `cart`.
- **Magical (4):** `spirit_bloom`, `rune_stone`, `crystal_cluster`,
  `wisp_lantern`.
- **Water (3):** `waterfall`, `river_rock`, `foam_ripple`.
- **Ambient wildlife (4):** `butterfly`, `moth`, `bird`, `firefly_sprite`.
- **Phase 4 buildings / landmarks (6):** `watchtower`, `market_stall`,
  `stone_wall`, `gazebo`, `banner_post`, `moon_shrine` — each with distinct
  variants, drawn by the same `ProceduralArt.prop_texture(kind, variant)`
  function (4 are placed at Greenward landmarks).
- **Phase 5 (4):** `birch_grove`, `moon_lantern`, `stone_path`, `village_gate` —
  cool Moonpetal Hollow (silver-birch/moonlit) and Greenward village-approach
  silhouettes, each with distinct variants via the same `prop_texture()`.
  `ContentValidator.PROP_TYPES` and `GreenwardStyle.prop_kinds()` now list all
  **57 kinds**; `GreenwardStyle.coherence_report() == []`.

Every kind is drawn by `ProceduralArt.prop_texture(kind, variant = 0)`;
`variant` selects a **deterministic, visually distinct** silhouette / leaf
cluster / petal arrangement / hue (never just a flat tint), and
`ProceduralArt.variant_count(kind)` (`GreenwardStyle.variant_count(kind)`)
reports how many exist — ≥2 for trees, flowers and structures. Textures are
cached by `(kind, variant)` and generated once, never per frame.

**Ground-cover `detail` layer.** `ChunkBuilder.build()` now also returns an
optional `detail` key: a single `MultiMeshInstance2D` ground-cover layer drawn
with `detail.gdshader` (per-instance `COLOR` tint), parented as a **child of
`terrain`** so it is freed with the chunk. It is **ONE extra draw call per
chunk**, not per-tile sprites; density is capped by `GreenwardStyle.DETAIL_DENSITY`
(and halved on mobile). The returned `coord/terrain/water/props` keys are
unchanged. Add new kinds by extending `_build_prop()` / the resource map and
registering them in `GreenwardStyle.ALL_PROP_KINDS`.

### Characters and monsters

| Property | Target |
| --- | --- |
| World sprite canvas | 96 × 128 px (small), 128 × 192 px (elite/boss) |
| Anchor | Bottom-centre `(0.5, 1.0)` |
| Directions | 8: `DOWN … DOWN_LEFT` (`CharacterAnimator.Direction`) |
| States | 8 core: `IDLE, WALK, RUN, INTERACT, ATTACK, DAMAGE, VICTORY, DEFEAT` (+ Phase 4 ADDITIVE `CAST = 8`; see below) |
| Format | PNG sprite sheet or individual frames; `SpriteFrames` resource |
| Outline | 1–2 px dark `INK` outline at 1× for readability |

**Directional movement is the DIRECTION axis, not a 9th state.** The Phase 3
model is **8 states × 8 directions** (64 `(state, direction)` pairs) driven by
ONE `CharacterAnimator` state machine; any state can be rendered in any
direction, with `WALK`/`RUN` showing it most visibly. Left/right flip alone is
enough for the placeholder slice, but production authors every state for all
8 directions. Phase 4 keeps this 8-core-state model intact and adds a genuine
ADDITIVE 9th state `CAST = 8` (a real one-shot state, distinct from the
DIRECTION axis described here) — see the next subsection.

Authoritative per-state timing (from `CharacterAnimator.STATE_FRAMES /
STATE_FPS / STATE_LOOPING`, mirrored by `GreenwardStyle.SPRITE_SPECS`):

| State | Frames | fps | Loop |
| --- | --- | --- | --- |
| IDLE | 5 | 9 | loop |
| WALK | 7 | 12 | loop |
| RUN | 7 | 14 | loop |
| INTERACT | 6 | 12 | one-shot |
| ATTACK | 6 | 15 | one-shot |
| DAMAGE | 2 | 12 | one-shot |
| VICTORY | 8 | 12 | one-shot |
| DEFEAT | 6 | 10 | one-shot |

Looping states (`IDLE`/`WALK`/`RUN`) wrap; the other five are one-shots that
return to locomotion/idle on completion. Priority is
`DEFEAT > VICTORY > DAMAGE > ATTACK > INTERACT > RUN > WALK > IDLE`.
The **EXACT final-art replacement specification** lives in
`ActorFrameSource.REPLACEMENT_SPEC` and is returned by `ActorFrameSource.specs()`
/ `ProceduralActorFrames.specs()`; real painted sheets plug in through
`ActorVisual.set_frame_source()` (see §1 and §11). `ProceduralActorFrames` and
`ProceduralArt.character_frame()` are explicitly TEMPORARY placeholder frames.

#### Phase 4 — additive 9-state model (8 core + CAST)

Phase 4 adds an **ADDITIVE 9th state** `CAST = 8` to `CharacterAnimator`
**without** changing the Phase-3 contract:

- `ALL_STATES` stays **8** and all Phase-3 timing arrays (`STATE_FRAMES` /
  `STATE_FPS` / `STATE_LOOPING` / `STATE_PRIORITY`) are unchanged — the timing
  table above remains the authoritative spec for the 8 core states.
- CAST has its OWN spec: `CAST_STATE = 8`, `CAST_FRAMES = 7`, `CAST_FPS = 12`,
  `CAST_LOOPING = false` (one-shot), `CAST_PRIORITY = 5` (ATTACK tier);
  `GreenwardStyle.CAST_SPEC` mirrors it. A distinct CAST pose is supplied by
  `ProceduralArt.character_frame(state = 8, ...)`.
- `EXTENDED_STATES` = 9, `EXTENDED_STATE_NAMES`, `LOCOMOTION_STATES`
  (IDLE/WALK/RUN), `RETURN_STATES` (one-shots return to a context state; DEFEAT
  holds), `frame_count_for/fps_for/looping_for/priority_for`, `transition_to`,
  `can_transition`, `finish_and_return`, `play_cast`, `cast_active`,
  `previous_state` and the `transitioned` signal drive state transitions.
- `ActorFrameSource` gained `cast_frame`/`cast_frame_count`/`cast_fps`/
  `validate_sheets`/`extended_specs`; `ProceduralActorFrames` implements them.
- `ActorVisual.play_cast()` + a CAST aura render it. All 8 directions still
  apply (8-direction idle/walk/run + attack/cast/damage/victory/defeat/
  interaction).
- **Sprite-sheet naming** (`SpriteFramesActorSource`): one animation per
  `"<state>_<dir>"` (e.g. `walk_2`, `attack_0`) plus the additive set
  `"cast_<dir>"` (e.g. `cast_0`); `validate_sheets()` checks 9 × 8 animations,
  correct frame counts, non-null 96 × 128 frames and loop flags. Real sheets
  plug in via `SpriteFramesActorSource.from_disk(<id>)` →
  `ActorVisual.set_frame_source()` (see §14).

Keep the feet on the same baseline across frames. The world positions actors by their ground point; drifting baselines cause visible foot-sliding.

### Battle unit cards

Current `CombatUnitCard` uses portraits and bars. Production art needs:

- Bust portrait, transparent or card-friendly background.
- Element badge.
- Rarity frame variants (common → mythic).
- Status icon set: burn, poison, regen, stun, shield, blind, atk up/down, def up/down, spd up/down.
- Optional attack/hit VFX sheets.

---

## 4. Portraits

| Use | Export size |
| --- | --- |
| Master | 1024 × 1280 px |
| Collection / summon | 512 × 640 px |
| Battle card | 256 × 320 px |
| HUD / list | 128 × 160 px |

Guidelines:

- Head and shoulders, eyes in the upper third.
- Consistent lighting direction (upper-left key light).
- Transparent background or a simple element-tinted backdrop.
- Keep the silhouette readable at 96 × 96.
- Avoid thin linework that disappears on mobile.
- Provide a neutral expression and at least one alternate for bond/story scenes.

`PortraitView.setup_character(definition)` should become a texture lookup keyed by character ID and rarity. Keep the procedural fallback for missing art so content never crashes.

---

## 5. UI art

- **Panels:** 9-slice, 2× export, 24–32 px corner radius at 1×.
- **Buttons:** normal / hover / pressed / disabled / focus states.
- **Icons:** 32 × 32 and 64 × 64 px, single-colour or duotone, consistent stroke weight.
- **Currency icons:** gold, gems, crystals, guild tokens, ancient coins, event tokens.
- **Element icons:** fire, wind, earth, water, light, dark, neutral.
- **Rarity frames:** common, rare, epic, legendary, mythic.
- **Safe areas:** keep critical UI inside the central 90% for notches and rounded corners.

Use `UITheme` for colours and `UIFactory` for layout. Do not bake layout into background images.

### Fonts

The slice uses Godot’s default font. Production needs:

- A licensed display font for headings.
- A highly legible UI font with CJK/Cyrillic/Arabic coverage or per-locale fallbacks.
- Dynamic font sizes and MSDF enabled for scaling.
- Record the license and source in `THIRD_PARTY_NOTICES.md` before committing.

---

## 6. VFX and shaders

Existing shaders:

| Shader | Purpose | Notes |
| --- | --- | --- |
| `terrain.gdshader` | Diamond mask, grain, edge bevel | Uses instance `COLOR` for tint |
| `water.gdshader` | Stylised reflections/glints, depth shading, pulsing shore foam | Animated via `TIME`; uses instance `COLOR` for shallow→deep tint |
| `wind_sway.gdshader` | Cheap, base-anchored foliage sway | `sway_strength`, `sway_speed` uniforms; per-instance world-space phase + secondary shimmer |
| `fog.gdshader` | Atmospheric UV+TIME fog veil | `fog_color` / `density` uniforms; noise-free, no texture lookups; disabled on the mobile tier |
| `detail.gdshader` | Per-instance-COLOR ground-cover mask | ONE `MultiMesh` draw call per chunk; soft rounded alpha mask, no texture lookups |

Phase 3 also ships a **partial** rain VFX: `WeatherDirector` describes CLEAR /
MIST / RAIN / POLLEN_BLOOM *moods*, but the only implemented rain effect is ONE
lightweight, capped CPU particle emitter (disabled on mobile) — there is **no
precipitation physics, splashes or accumulation**. Weather is an architecture,
not a simulation. Day/night tint, fog density and particle counts are driven by
`GreenwardStyle.phase()` and `WeatherDirector.params()`.

Production VFX targets:

- Element hit bursts (fire, wind, earth, water, light, dark).
- Slash/impact/crit/miss indicators.
- Heal and shield glows.
- Status application loops.
- Boss phase transition flash.
- Summon portal and rarity reveal.
- UI transitions: panel open/close, toast, rarity shine.

Budget: particle counts and overdraw must be measured on the lowest target device. Prefer flipbooks or simple shader quads over large particle systems for mobile.

**Phase 4 note.** No new `.gdshader` files were added in Phase 4 — the CAST aura is a procedural glow and the 6 new prop kinds (`watchtower`, `market_stall`, `stone_wall`, `gazebo`, `banner_post`, `moon_shrine`) are painted by `ProceduralArt.prop_texture(kind, variant)` (see §3). Real painted VFX sheets are one of the 8 `AssetManifest` classes (`skill_effects`, 192 × 192, 6 frames); import settings are in §10 and §14.

---

## 7. Audio pipeline (not implemented)

There is no audio in the slice. When audio is added:

- Buses: `Master`, `Music`, `SFX`, `Voice`, `UI`.
- Music: looping exploration themes per region, battle theme, boss theme, title theme.
- Ambience: forest day/night, water, village, cave.
- SFX: footsteps, UI clicks, summon, rarity reveal, skills, hits, crits, deaths, victory, defeat.
- Voice: optional barks or story lines; keep localization and file size in mind.
- Format: Ogg Vorbis for music/voice, WAV or Ogg for short SFX.
- Loudness: normalise to a consistent target; provide sliders and mute.
- Licensing: every track must have a written license or be original.

Hook points already exist conceptually through `EventBus` (`battle_finished`, `quest_updated`, `toast_requested`, etc.). Add an `AudioDirector` that listens to events rather than hard-coding sounds into combat or UI.

---

## 8. Mobile budgets

Initial targets for a mid-range Android device at 720p:

| Budget | Target |
| --- | --- |
| Frame rate | 60 fps target, 30 fps floor |
| Draw calls | < 150 in the world |
| Terrain/water | 1 draw call per layer per chunk |
| Visible props | < 250 |
| Active particles | < 300 |
| Texture memory | < 256 MB |
| APK/AAB size | < 150 MB initial download |
| UI overdraw | Keep full-screen translucent layers to 2 or fewer |

Techniques:

- MultiMesh for repeated terrain/water.
- Atlas props and UI icons.
- Avoid per-frame `Image` generation; `ProceduralArt` caches textures.
- Pool damage numbers and VFX.
- Use `CanvasItem.visible` and process disabling for off-screen actors.
- Profile on device, not just desktop.

### Implemented Phase 3 caps

These are the caps actually enforced in code today (from `GreenwardStyle` and
`ChunkBuilder`), **on top of** the aspirational targets above:

| Cap | Implemented value |
| --- | --- |
| `MAX_PROPS_PER_CHUNK` | **48** desktop / **~26** mobile (`MOBILE_PROP_FACTOR = 0.55`) |
| `MAX_PARTICLES` | **300** (pollen / fireflies / rain) |
| `DETAIL_DENSITY` | **0.22** (halved on mobile by `MOBILE_DETAIL_FACTOR = 0.5`) |
| Fog quad | **disabled on the mobile tier** (`GreenwardStyle.performance_tier()`) |
| Rain VFX | **disabled on the mobile tier** (single capped emitter on desktop) |
| Animated props | off-screen `set_active()` visibility/process gating; world caps the count |

> **Honest caveat — no device profiling.** `GreenwardStyle.performance_tier()`
> is a coarse `OS.get_name()` hint only (Android/iOS/Web → `mobile`), NOT a
> measured frame-time budget. These caps and the "Targets" table above are
> guidance, not measured frame times. Headless CI uses a dummy renderer, so full
> shader compilation on a real device is not exercised. Device profiling remains
> future work (see `ARCHITECTURE.md` §10).

**Phase 4 — background chunk preparation (NO threads).** `ChunkPreparer` adds
main-thread **FRAME-SLICED** background chunk preparation — a pure, bounded LRU
that prepares at most ONE chunk per frame plus a bounded prefetch ring, feeding
`_load_chunk` with a synchronous fallback. Generation stays on the MAIN THREAD
because Godot 4 `MultiMesh` / `Image` / `ShaderMaterial` and all scene-tree
operations are **not thread-safe**; there is **no threading**. All Phase 3 caps
above still apply, and a headless shutdown-leak fix now reports ZERO leaked
RIDs. No device profiling has been performed.

---

## 9. Naming and folder conventions

```text
assets/
├─ characters/
│  ├─ mira_sol/
│  │  ├─ portrait_512.png
│  │  ├─ portrait_256.png
│  │  ├─ world_sheet.png
│  │  └─ battle_bust.png
│  └─ ...
├─ enemies/
├─ props/
├─ tiles/
├─ ui/
│  ├─ panels/
│  ├─ icons/
│  └─ frames/
├─ vfx/
├─ audio/
│  ├─ music/
│  ├─ sfx/
│  └─ voice/
└─ fonts/
```

Rules:

- Lowercase snake_case file names.
- Character folders use the content ID (`mira_sol`), not the display name.
- Do not overwrite source masters with exports; keep masters outside the Godot project or in a `source/` folder excluded from export.
- Record every third-party asset in `THIRD_PARTY_NOTICES.md` with author, source URL, license and modifications.
- Shaders use `<effect>.gdshader` (e.g. `fog.gdshader`, `detail.gdshader`, `water.gdshader`, `wind_sway.gdshader`).

Phase 3 adds these code files — all `lower_snake_case`, consistent with the
convention above:

- `scripts/world/visual_style.gd` (`GreenwardStyle`), `character_animator.gd`,
  `actor_frame_source.gd`, `procedural_actor_frames.gd`, `weather_director.gd`,
  `animated_prop.gd`, `interactive_prop.gd`.
- `resources/shaders/fog.gdshader`, `resources/shaders/detail.gdshader`.
- `documentation/VISUAL_STYLE.md` — the canonical visual style guide.

These are the single-source palette / animation / weather / shader seams that
real art plugs into; do not scatter inline hex literals or new frame sources
outside them.

Phase 4 adds these `lower_snake_case` code / asset files, consistent with the
convention above:

- `scripts/art/asset_manifest.gd` (`AssetManifest`),
  `scripts/art/sprite_frames_actor_source.gd` (`SpriteFramesActorSource`),
  `scripts/art/demo_character_frames.gd` (`DemoCharacterFrames`) — the real art
  asset pipeline.
- `scripts/world/region_graph.gd` (`RegionGraph`), `region_portal.gd`
  (`RegionPortal`), `chunk_preparer.gd` (`ChunkPreparer`) — two-region world,
  gate portals and frame-sliced background preparation.
- `assets/README.md` (workflow), `assets/ASSET_STATUS.md` (exact status table),
  and the `assets/<class>/<content_id>/` folder contract — all
  `lower_snake_case`, one content-id folder per subject, e.g.
  `assets/characters/mira_sol/world_sheet.png`. See §14 for the full per-class
  path / dimension / import table.

---

## 10. Import settings

### Painted sprites/tiles

- Filter: linear.
- Mipmaps: on for world art viewed at variable zoom.
- Compression: VRAM compressed where platform supports it; lossless for UI.
- Fix alpha border: on for atlased sprites.

### Pixel-art style

- Filter: nearest.
- Mipmaps: off.
- Compression: lossless.
- Snap 2D transforms to pixel.

### Portraits

- Filter: linear.
- Mipmaps: on if displayed smaller than master.
- Keep aspect ratio; never stretch.

### Audio

- Music: loop enabled, Ogg Vorbis.
- SFX: no loop, mono where positional.
- Normalize before import.

### Phase 4 — real painted assets (per class)

`AssetManifest.import_settings(<id>)` is authoritative for the 8 real-asset
classes; the general rules above are the intent. In practice: **Linear** filter
throughout; **mipmaps ON** for world art (`character_sprites`,
`environment_tilesets`, `buildings`, `vegetation`, `monster_sprites`) and OFF for
`character_portraits`, `skill_effects`, `ui_illustrations`; **VRAM compression
where supported (lossless for UI)**; **Fix Alpha Border ON** for atlases /
tilesets / cutout sprites and OFF for portraits / UI illustrations. Every file
is flattened, transparent **RGBA8** PNG or WebP (sRGB). See §14 for the exact
per-class table and `assets/README.md` §4. **No real asset files exist yet** —
these are import targets, not imported art.

---

## 11. Replacement checklist

When swapping placeholder art for production art:

1. Keep the existing public API (`prop_texture(kind, variant)`, `setup_character`, `ActorVisual.setup`) — and register real sprite sheets through `ActorVisual.set_frame_source()` with an `ActorFrameSource` subclass (see `ActorFrameSource.REPLACEMENT_SPEC` / `specs()`), NOT by editing gameplay code.
2. Verify anchor points and foot baselines in the world.
3. Check readability at 720p and on a phone-sized viewport.
4. Check element/rarity colour consistency with `UITheme` and `GreenwardStyle` (see `VISUAL_STYLE.md`, the CANONICAL style guide).
5. Profile draw calls and texture memory (no device profiling has been performed yet).
6. Add license/source records for every third-party file.
7. Update screenshots and the README if the look changes materially.
8. Keep a procedural fallback for missing assets — `ProceduralActorFrames` / `ProceduralArt.character_frame()` are explicitly TEMPORARY placeholder frames.
9. Check `AssetManifest.status_report()` / `assets/ASSET_STATUS.md` before claiming a class is FINAL; every one is currently TEMPORARY + MISSING.

**Phase 4 concrete workflow (real sprite sheets).** Build/drop a real
`res://assets/characters/<id>/world_sheet.tres` (or a `.png` sliced into a
`SpriteFrames`) per `AssetManifest` / `assets/README.md`, then call
`ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>))`.
`from_disk()` never crashes — on a missing/invalid file `has_frames()` is false,
`is_temporary()` stays true and the procedural fallback remains; validate with
`validate_sheets()` before swapping. `status_report()` only moves a class from
TEMPORARY/MISSING to FINAL when the real file exists on disk. Every other class
replaces its own procedural painter / seam listed in
`AssetManifest.replacement_seams()` — no gameplay code changes.

---

## 12. What not to do

- Do not import copyrighted anime/game art, logos, fonts, music or voice clips.
- Do not bake UI text into images.
- Do not ship square terrain tiles with visible corners.
- Do not use a different palette per screen for the same character.
- Do not rely on colour alone for element/rarity; pair it with a shape or icon.
- Do not add large particle effects without a mobile performance check.
- Do not commit source masters into the exported game folder.

---

## 13. Asset status — final vs placeholder (Phase 3 snapshot)

> **This section is the Phase 3 snapshot**, kept for continuity; it remains
> accurate for what Phase 3 shipped. The Phase 4 real art asset pipeline (the 8
> `AssetManifest` classes, **FINAL 0 / TEMPORARY 8 / MISSING 8**) is in **§14
> (the Phase 4 snapshot)** below. The CURRENT, authoritative **Phase 5**
> character art pipeline (10 kinds, 12 specs, the disk-computed
> `CharacterAssetRegistry` and the exact asset status for BOTH registries) is in
> **§15**.

**ZERO assets are final. Every asset shipped in Phase 3 is procedural placeholder
art generated in code at runtime.** There are no final painted sprites, sprite
sheets, textures, portraits, VFX flipbooks or imported art of any kind, and **no
audio exists** (no music, ambience, SFX or voice). `ProceduralActorFrames` and
`ProceduralArt.character_frame()` are explicitly TEMPORARY;
`ActorVisual.set_frame_source()` / an `ActorFrameSource` subclass is the seam
real art plugs into. See `VISUAL_STYLE.md` for the target look and §1/§11 above
for the production specs.

| Asset class | Status | Exact replacement seam |
| --- | --- | --- |
| Terrain tiles | **Placeholder (procedural)** | `terrain.gdshader` / tile atlas inside `ChunkBuilder` |
| Water | **Placeholder (procedural)** | `water.gdshader` material / animated water atlas |
| Ground cover (`detail` layer) | **Placeholder (procedural)** | `detail.gdshader` / authored tufts in the same `MultiMesh` |
| Props (53 kinds + variants; 47 in the Phase 3 snapshot) | **Placeholder (procedural)** | `ProceduralArt.prop_texture(kind, variant)` → real `Texture2D` |
| Character world sprites (8 states × 8 directions) | **Placeholder (procedural, TEMPORARY)** | `ActorVisual.set_frame_source()` + `ActorFrameSource` subclass (see `REPLACEMENT_SPEC`) |
| Portraits | **Placeholder (procedural)** | `PortraitView.setup_character()` → `TextureRect`/atlas lookup |
| Title backdrop | **Placeholder (procedural)** | Painted key art layer in `MainBackdrop` |
| UI panels / icons / fonts | **Placeholder (procedural)** | `UITheme` / `UIFactory` → 9-slice, icon and font assets |
| VFX / particle sheets | **Placeholder (procedural)** | Authored flipbooks over the existing shader/particle hooks |
| Fog / weather VFX | **Placeholder (procedural, partial rain only)** | `fog.gdshader` + `WeatherDirector` → authored fog/weather VFX |
| Audio | **None — not implemented** | `AudioStreamPlayer` buses + `EventBus`-driven `AudioDirector` |

No device profiling has been performed; the mobile tier is a coarse platform
hint only. Local JSON save, gacha/currency/inventory/rewards are
NON-AUTHORITATIVE (client-side) until Phase 12. There is no multiplayer,
backend, server authority, accounts, trading or PvP.

---

## 14. Phase 4 real art asset pipeline (Phase 4 snapshot)

> **This is the Phase 4 snapshot** — accurate for what Phase 4 shipped (the 8
> `AssetManifest` classes and their exact **FINAL 0 / TEMPORARY 8 / MISSING 8**
> status, which is unchanged and still valid today). The CURRENT, authoritative
> **Phase 5** character art pipeline — 10 asset kinds, 12 authored specs, the
> disk-computed `CharacterAssetRegistry`, and the exact asset status for BOTH
> registries (including **FINAL 0 / TEMPORARY 120 / MISSING 120**) — is in
> **§15** below.

Phase 4 shipped a **real art asset pipeline** — a machine-readable contract for
dropping painted assets into the game — but **no final artwork**. The contract
lives in `scripts/art/asset_manifest.gd` (`AssetManifest`:
`ASSET_CLASSES`, `CLASS_SPECS`, `entries()`, `asset_spec()`,
`import_settings()`, `expected_path()`, `check_disk()`, `status_report()`,
`validate_sheet_specs()`, `replacement_seams()`), with the production source
`scripts/art/sprite_frames_actor_source.gd` (`SpriteFramesActorSource`:
`from_disk()`, `validate_sheets()`) and **ONE** clearly-marked TEMPORARY
demonstration character `scripts/art/demo_character_frames.gd`
(`DemoCharacterFrames`, an in-memory procedurally-generated `SpriteFrames`
wired to the player). Workflow and the exact per-class status table are in
[`assets/README.md`](../assets/README.md) and
[`assets/ASSET_STATUS.md`](../assets/ASSET_STATUS.md).

### EXACT ASSET STATUS (from `AssetManifest.status_report()`)

> **FINAL 0 / TEMPORARY 8 / MISSING 8.**
> `counts.final == 0`, `counts.temporary == 8`, `counts.missing == 8`,
> `total == 8`. **TEMPORARY** means every asset class has a present procedural
> fallback that is rendering right now; **MISSING** means every expected final
> asset FILE is absent on disk. `check_disk()` returns `false` for all 8.
> The ONLY image file tracked by `AssetManifest` is `icon.svg`. For the 8
> `AssetManifest` classes there are **ZERO final painted assets**,
> **no audio**, **no real sprite sheets / PNG textures on disk**. (Lilith's
> character art lives outside these 8 classes — see §15.)

State plainly:

- **ZERO assets are final.** All shipped art is **runtime procedural
  placeholder**. No final painted sprites, tilesets, portraits, buildings,
  vegetation, monster sheets, VFX flipbooks or UI illustrations exist.
- **No audio** of any kind exists (no music, ambience, SFX or voice).
- **No fake painted art was fabricated from polygons and labelled finished.**
  The 6 new Phase 4 prop kinds and the CAST pose are procedural placeholders,
  not final art.
- The **ONE demonstration character** uses a **TEMPORARY in-memory
  procedurally-generated `SpriteFrames`** (`DemoCharacterFrames`,
  `loaded_from_disk == false`, `is_temporary() == true`) — it is **NOT final
  art**.
- No device profiling, no threads (`ChunkPreparer` is main-thread frame-sliced),
  only TWO regions, no multiplayer/backend/server authority (see §13).

### The 8 asset classes — exact contract

Every class is **flattened, transparent RGBA8 PNG / WebP (sRGB)** — alpha
cutouts, NEVER opaque. Import uses **Linear** filter; mipmaps ON for world art
and OFF for portraits / VFX / UI illustrations; VRAM compression where
supported (lossless for UI); Fix Alpha Border ON for atlases / tilesets.
`SpriteFramesActorSource` animation names are `<state>_<dir>` plus `cast_<dir>`
(9 × 8 animations for character/monster sheets).

| # | Class id | Dimensions | Alpha / format | Anchor | Animation frame layout | Import settings | Naming (expected `res://` path) | Exact replacement seam |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `character_sprites` | 96 × 128 | transparent RGBA8 | bottom-centre (0.5, 1.0), feet on one baseline | 8-frame sheets; 8 direction rows × per-state columns, 0-based | Linear, mipmaps On, VRAM (lossless UI), Fix Alpha Border On | `assets/characters/<id>/world_sheet.png` or `<id>_<state>_<dir>.png` | `ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>))` → `scripts/world/actor_frame_source.gd` + `scripts/art/sprite_frames_actor_source.gd` |
| 2 | `character_portraits` | 256 × 384 | transparent RGBA8 | top-centre (0.5, 0.0), bust crop | single static frame | Linear, mipmaps Off, Lossless (UI), Fix Alpha Border Off | `assets/portraits/<id>/portrait.png` | `scripts/ui/portrait_view.gd` (`PortraitView`) / ContentDB portrait lookup |
| 3 | `environment_tilesets` | 512 × 512 | transparent RGBA8 | tile grid top-left (0.0, 0.0), 16 × 16 px cells | static tile atlas, 16 × 16 cells | Linear, mipmaps On, VRAM, Fix Alpha Border On | `assets/tilesets/<biome>_terrain.png` | `scripts/world/chunk_builder.gd` terrain MultiMesh + `procedural_art.gd prop_texture()` |
| 4 | `buildings` | 256 × 256 | transparent RGBA8 | bottom-centre (0.5, 1.0), Y-sort at ground | single static frame per variant | Linear, mipmaps On, VRAM, Fix Alpha Border On | `assets/buildings/<id>/building.png` | `scripts/world/procedural_art.gd` `_build_prop()` / `_paint_kind()` + `GreenwardStyle.prop_palette()` |
| 5 | `vegetation` | 128 × 160 | transparent RGBA8 | bottom-centre (0.5, 1.0), trunk base on ground line | single static frame per variant | Linear, mipmaps On, VRAM, Fix Alpha Border On | `assets/vegetation/<id>/plant.png` | `scripts/world/procedural_art.gd` tree / fern / flower painters + `GreenwardStyle.prop_palette()` |
| 6 | `monster_sprites` | 96 × 128 (boss 128 × 192) | transparent RGBA8 | bottom-centre (0.5, 1.0) | 8-frame sheets; 8 direction rows × per-state columns | Linear, mipmaps On, VRAM, Fix Alpha Border On | `assets/monsters/<id>/world_sheet.png` | `ActorVisual` (`Kind.MONSTER`) via `scripts/world/actor_frame_source.gd` + `SpriteFramesActorSource` |
| 7 | `skill_effects` | 192 × 192 | transparent RGBA8 (additive) | centre (0.5, 0.5) | 1 row × 6 frame columns, 0-based | Linear, mipmaps Off, Lossless, Fix Alpha Border On | `assets/vfx/<id>/effect.png` | `scripts/combat/combat_engine.gd` VFX hooks / `procedural_art.gd soft_glow()` |
| 8 | `ui_illustrations` | 640 × 360 | transparent RGBA8 | centre (0.5, 0.5) | single static frame | Linear, mipmaps Off, Lossless (UI), Fix Alpha Border Off | `assets/ui/<id>/illustration.png` | `scripts/ui/main_backdrop.gd` + `scripts/ui/ui_theme.gd` |

`AssetManifest.validate_sheet_specs(sheet)` rejects wrong dimensions, a missing
anchor, a non-transparent background, a bad frame count or an invalid format;
`SpriteFramesActorSource.validate_sheets()` rejects a missing/wrong 9 × 8
animation set. `AssetManifest.replacement_seams()` records the exact seam per
class; `from_disk()` never crashes and keeps the procedural fallback when a
file is missing. When real art lands, record licences in
`THIRD_PARTY_NOTICES.md` — currently there are **no third-party assets and no
audio**.

---

## 15. Phase 5 character art pipeline (CURRENT authoritative)

> **This is the CURRENT, authoritative Phase 5 status.** It supersedes §13
> (Phase 3 snapshot) and §14 (Phase 4 snapshot) for the character-art production
> pipeline and the exact asset status. Phase 5 shipped a *production contract +
> authored specs + preparation for future external art*, **not finished artwork**.
> Everything in this section is data/contract (pure GDScript), headless-safe, and
> creates NO image/binary art file.

### 15.1 EXACT ASSET STATUS (both registries, disk-computed, NEVER hardcoded FINAL)

- `AssetManifest.status_report()` — the **8 asset CLASSES** from Phase 4:
  **FINAL 0 / TEMPORARY 8 / MISSING 8**. `AssetManifest.check_disk()` returns
  `false` for all 8.
- `CharacterAssetRegistry.report()` — **12 characters × 10 kinds = 120 expected
  assets**: **FINAL 0 / TEMPORARY 120 / MISSING 120**.
  `CharacterAssetRegistry.check_disk()` returns `false` for all 120.

Both registries compute status from disk; an asset is marked **FINAL only if a
real finished file exists on disk AND passes validation**
(`validate_finished_asset()` returns `[]`) — FINAL is **NEVER hardcoded**.
TEMPORARY means a procedural fallback is present and rendering; MISSING means
the final file is absent (orthogonal to the fallback).

State plainly:

- **Lilith is the ONE final playable character; the 12 collectibles are still ZERO final assets.** All shipped visuals for the 12 collectible characters are **runtime procedural
  placeholder** art. **No audio** exists. **No final artwork was fabricated from
  polygons / random shapes and labelled finished.**
  - **Exception — Lilith.** `assets/characters/lilith/` holds a real, imported
    art set extracted from the supplied **Project Fantasy concept sheet**
    (`Downloads/little sister`) by `tools/extract_lilith_sheet.py` ->
    `tools/build_lilith_sheet.py` -> `tools/build_lilith_static.py`: the
    sheet's own Idle / Walk / Attack / Cast / Hurt / Death strips and its
    Front / Right / Back / Left views, re-laid out as
    8 directions x 9 states = **72 animations / 432 frames** (`world_sheet.tres`),
    a 256x384 `portrait.png`, a 128x192 `combat_sprite.png` and a 1024x2048
    `full_body_illustration.png`. It is tracked by
    `MainCharacterRoster.world_art_ready()` / `asset_status()` and by
    `tools/verify_lilith_avatar.tscn`, **not** by the 12-character registries
    above (which intentionally stay FINAL 0).
- The ONE demonstration character uses a **TEMPORARY in-memory procedural
  `SpriteFrames`** (`DemoCharacterFrames`, `loaded_from_disk == false`;
  `ActorVisual.using_temporary_art == true`) — it is NOT final art.
- The 12 `CharacterArtSpec` specs and `assets/GENERATION_PROMPTS.md` are
  **PREPARATION for a FUTURE external generation round**, not finished artwork.
- **NO visual testing** was performed: all verification is `--headless` with
  Godot's dummy renderer; `_draw()` output, auras, borders, tints, silhouettes and
  tween pops are compile/build-safe and structurally asserted but were **NOT
  visually inspected on screen** — no shader compilation / appearance
  verification, no device profiling. Only TWO regions; no threads; no
  multiplayer/backend/server authority (see `ARCHITECTURE.md` §12).

### 15.2 The 10 asset kinds — exact contract

`CharacterArtPipeline` (`scripts/art/character_art_pipeline.gd`) defines TEN
stable asset kinds. **Every kind is flattened, transparent RGBA8 PNG / WebP
(sRGB) — alpha cutouts, NEVER opaque** — with `lower_snake_case` naming in a
content-id folder. Import keys: **WORLD** = Linear filter, mipmaps On, VRAM
compressed where supported (lossless for UI), Fix Alpha Border On; **UI** =
Linear, mipmaps Off, Lossless (UI), Fix Alpha Border Off; **VFX** = Linear,
mipmaps Off, Lossless, Fix Alpha Border On.

| # | Kind id | Dimensions (px) | Anchor | Frame layout | Import | Naming (expected path) | Replacement seam |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `full_body_illustration` | 1024 × 2048 | bottom-centre (0.5, 1.0), feet on ONE baseline, ~6-head | single static frame; master 1024×2048 | UI | `<id>/full_body_illustration.png` | `main_backdrop.gd` key-art + `collection_screen.gd` / `gacha_screen.gd` big art |
| 2 | `character_portrait` | 256 × 384 (master 1024 × 1280) | top-centre (0.5, 0.0) bust crop, eyes upper third | single static frame | UI | `<id>/portrait.png` | `PortraitView` → `PortraitAssetSource.texture_for(<id>)` (procedural fallback) |
| 3 | `combat_sprite` | 128 × 192 | bottom-centre (0.5, 1.0) | single static frame | WORLD | `<id>/combat_sprite.png` | `unit_card.gd` + `combat_screen.gd` battle unit art |
| 4 | `movement_sheet` | 96 × 128 frames | bottom-centre, feet on ONE baseline | 8 direction rows × per-state columns (idle 5 / walk 7 / run 7); atlases 480 / 672 / 672 × 1024; sliced `<id>/movement_sheet.tres`; `idle_<dir>` / `walk_<dir>` / `run_<dir>` | WORLD | `<id>/movement_sheet.tres` | `ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>))` |
| 5 | `attack_sheet` | 96 × 128 frames | bottom-centre | attack 6 / interact 6 / damage 2 one-shots; atlases 576 / 576 / 192 × 1024; `<id>/attack_sheet.tres` | WORLD | `<id>/attack_sheet.tres` | same `from_disk()` seam |
| 6 | `cast_sheet` | 96 × 128 frames | bottom-centre | cast 7 @ 12 fps one-shot; atlas 672 × 1024; `<id>/cast_sheet.tres`; `cast_<dir>` | WORLD | `<id>/cast_sheet.tres` | `ActorVisual.play_cast()` / `SpriteFramesActorSource.cast_frame()` via `from_disk()` |
| 7 | `skill_vfx` | 192 × 192 frames | centre (0.5, 0.5) | 1 row × 6 columns, additive; atlas 1152 × 192 | VFX | `assets/vfx/<skill_id>/effect.png` | `combat_engine.gd` VFX hooks / `procedural_art.gd soft_glow()` |
| 8 | `ultimate_vfx` | 192 × 192 frames | centre (0.5, 0.5) | 1 row × 6 columns, additive; atlas 1152 × 192 | VFX | `assets/vfx/<ultimate_id>/effect.png` | `combat_engine.gd` VFX hooks / `procedural_art.gd soft_glow()` |
| 9 | `victory_sheet` | 96 × 128 frames | bottom-centre | victory 8 @ 12 fps one-shot; atlas 768 × 1024; `<id>/victory_sheet.tres` | WORLD | `<id>/victory_sheet.tres` | same `from_disk()` seam |
| 10 | `defeat_sheet` | 96 × 128 frames | bottom-centre | defeat 6 @ 10 fps one-shot (holds last frame); atlas 576 × 1024; `<id>/defeat_sheet.tres` | WORLD | `<id>/defeat_sheet.tres` | same `from_disk()` seam |

Helpers: `CharacterArtPipeline.spec(kind)`, `import_settings(kind)`,
`validate_asset(kind, candidate)` (rejects wrong dimensions/anchor/transparency/
frames/format/naming), `replacement_seams()`, `sheet_layout()`,
`animation_names()` (72), `naming_examples()`, `summary()`, `example_candidate()`,
`self_check()`. `assets/CHARACTER_ART_PIPELINE.md` is the companion doc.

### 15.3 Sheet contract — 9 states × 8 directions = 72 animations

`CharacterArtPipeline.sheet_layout()` and `CharacterArtSpec.required_animations()`
both describe ONE `<state>_<dir>` animation per (state, direction):

- **9 states** (8 core + additive CAST): `idle`, `walk`, `run`, `interact`,
  `attack`, `damage`, `victory`, `defeat`, `cast`.
- **8 directions** (0-based row order): `down`, `down_right`, `right`,
  `up_right`, `up`, `up_left`, `left`, `down_left`.
- **9 × 8 = 72 animations**, sliced into `SpriteFrames` `.tres` files with
  speed = `fps` and loop = the loop flag; `cast_<dir>` is included.

Authoritative per-state timing (from `CharacterAnimator` / `STATE_SPECS`):

| State | Frames | fps | Loop |
| --- | --- | --- | --- |
| idle | 5 | 9 | loop |
| walk | 7 | 12 | loop |
| run | 7 | 14 | loop |
| interact | 6 | 12 | one-shot |
| attack | 6 | 15 | one-shot |
| damage | 2 | 12 | one-shot |
| victory | 8 | 12 | one-shot |
| defeat | 6 | 10 | one-shot |
| cast (additive 9th) | 7 | 12 | one-shot |

`SpriteFramesActorSource.register_character()` / `validation_report()` /
`animation_names()` / `registration_report()` and
`ActorVisual.configure_character()` / `character_art_report()` wire all 72;
`WorldNPC` and `RoamingMonster` call `configure_character()`. **No real sheets
exist**, so `ProceduralActorFrames` REMAINS the active fallback.

### 15.4 The 12 character specs

`CharacterArtSpec` (`scripts/art/character_art_spec.gd`) holds ONE authored spec
per id. Identity fields are **verbatim from `characters.json`** (gameplay data
UNCHANGED); descriptive fields (appearance, hair, outfit, accessories, weapon,
personality, visual theme, pose, motif, expression, tier note) and detailed
generation prompts are authored art direction. Rarity spread: **1 mythic, 3
legendary, 4 epic, 3 rare, 1 common**; Legendary/Mythic carry a distinct premium
visual tier. Full text: `assets/CHARACTER_SPECS.md` and
**`assets/characters/<id>/SPEC.md`** (one file per id).

| id | Name | Race | Element | Rarity | Visual theme |
| --- | --- | --- | --- | --- | --- |
| `lyra_vey` | Lyra Vey | Elf | wind | epic | Mint-and-emerald wind warden |
| `bramble` | Bramble | Beastkin | earth | rare | Earthy bark-and-moss bruiser |
| `seraphine` | Seraphine Ael | Angel | light | legendary | Ivory-and-gold dawn angel |
| `nyx` | Nyx Vaelora | Demon | dark | legendary | Hollow-moon violet queen |
| `coralyn` | Coralyn Tide | Mermaid | water | epic | Lagoon-and-coral tide singer |
| `ignis` | Ignis Karroth | Dragonkin | fire | mythic | Charred-crown dragonkin |
| `mira_sol` | Mira Sol | Human | light | common | Humble steel-and-dawn squire |
| `thistle` | Thistle | Spirit | wind | rare | Warm wishlight wisp |
| `vespera` | Vespera Noct | Vampire | dark | epic | White-mourning vampire assassin |
| `arachnia` | Arachnia Silk | Monster Girl | dark | epic | Quiet-web weaver |
| `terra` | Terra Rootheart | Ancient | earth | legendary | Mountain-that-remembers |
| `kael` | Kael Ashford | Human | fire | rare | Bannerless ember sellsword |

`CharacterArtSpec.validate_specs()` returns `[]` (12 unique specs, all required
fields non-empty, identity consistent, 72 animations, 9 states, premium tier
described). `identity_table()`, `all()`, `for_id(id)`, `to_dict()`,
`prompt_for(kind)` and `required_animations()` are the read/promote API.

### 15.5 Generation-prompt workflow (FUTURE external art)

`assets/GENERATION_PROMPTS.md` ships a **global style anchor** (shared
~6-head heroic proportions, upper-left key light, 1–2 px dark ink outline,
cel-shaded painterly rendering, transparent RGBA8, shared `GreenwardStyle`
palette language, no copyrighted reference traces), **12 per-character prompts**
(full-body / portrait / sheet / VFX via `CharacterArtSpec.prompt_for(kind)`) and
**exact output specs** matching §15.2 / §15.3. These are **for a FUTURE external
generation/illustration round** — this phase produced NO artwork.

`assets/ASSET_PRODUCTION_MANIFEST.md` (from
`CharacterAssetRegistry.production_manifest()`) lists all 120 (character × kind)
rows with expected `res://` paths and status. To promote a spec to FINAL: drop a
real file at the recorded path; it becomes FINAL only when
`validate_finished_asset()` returns `[]` (correct dimensions, loadable RGBA8
Texture2D / SpriteFrames, transparent corners, the required 9×8 animations) —
FINAL is NEVER hardcoded. Until then MISSING (final) / TEMPORARY (procedural
fallback).
