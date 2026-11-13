# PROJECT FANTASY

An original anime-fantasy MMORPG vertical slice built with **Godot 4.7** and **GDScript**.

The playable milestone is **Greenward**, a streamed isometric forest region (Phase 4 adds a small second region, **Moonpetal Hollow**): walk a village hub, talk to NPCs, accept quests, fight roaming monsters in turn-based battles, summon new characters, manage a party, and save your journey locally.

> **Status: offline vertical slice + Phase 5 (character art and visual production).** This is a real, runnable game slice, not a mock-up. **Phase 2** added strict JSON validation, mechanical character passives, equipment resonance, enforced quest prerequisites and a CI/export pipeline; **Phase 3** added a single-source art direction (`GreenwardStyle` + `VISUAL_STYLE.md`), 47 prop kinds, richer terrain/river/bridges/waterfalls, 5 visually distinct locations, fog/lighting/weather architecture, animated & interactive props and an 8-state × 8-direction animation architecture; **Phase 4** added exactly TWO regions with a `RegionGraph`, validated transitions and per-region saves, a REAL art asset pipeline (`AssetManifest` + `SpriteFramesActorSource`) with an honest placeholder-only status, an ADDITIVE 9th `CAST` animation state with sprite-sheet support and ONE TEMPORARY procedural demonstration character, 6 new prop kinds (53 at that checkpoint) and bounded frame-sliced background chunk preparation (NO threads). **Phase 5** re-scoped to **character art and visual production**: a 10-kind production art pipeline (`CharacterArtPipeline`), 12 complete authored character specs (`CharacterArtSpec` + `assets/characters/<id>/SPEC.md` + generation prompts), premium Legendary/Mythic rarity presentation, a real-portrait seam with procedural fallback, 9 states × 8 directions sprite-sheet registration (72 animations), `WorldVisualStandards` (6 categories) and 4 new prop kinds (**57 total**) — on top of a **`1374 passed, 0 failed`** suite (all 954 prior tests preserved). **Phase 6** produced the FIRST final playable character art: **Lilith** now has a complete set (8 directions × 9 states = 72 animations, 256×384 portrait, combat sprite, full-body illustration) extracted from the supplied Project Fantasy concept sheet by `tools/extract_lilith_sheet.py` / `tools/build_lilith_sheet.py` / `tools/build_lilith_static.py` and imported through the existing `SpriteFramesActorSource` / `PortraitAssetSource` seams. **The 12 collectible characters remain procedural placeholder art** and their specs + prompts are PREPARATION for future external art. Multiplayer, accounts, trading, PvP and server-authoritative progression are **not implemented** yet. **All art is intentionally procedural placeholder art** except Lilith's final playable set (no audio). **NO visual testing** was performed (all verification is `--headless` with Godot's dummy renderer). See [Limitations](#limitations).

---

## Quick start

Requirements:

- Godot **4.7.x** (standard build, GL Compatibility renderer)
- Windows, Linux, macOS, or a connected Android/iOS device for export testing

Run from the editor:

1. Open `project.godot` in Godot 4.7.
2. Press **F5**.

Run from a terminal:

```powershell
godot --path .
```

Headless smoke test:

```powershell
godot --headless --path . --quit-after 240
```

Validate content (the same strict validator `ContentDB` runs at boot):

```powershell
godot --headless --path . --script res://tools/validate_content.gd
```

A clean run prints `[validate] OK — 9 content files parsed and validated.` and exits `0`; broken references exit `1`.

Headless test suite:

```powershell
godot --headless --path . res://tests/test_runner.tscn
```

Export pack smoke build (after a one-time editor import; see CI):

```powershell
godot --headless --path . --export-pack "Linux/X11" build/project-fantasy.pck
```

Expected test output: `0 failed` and exit code `0`; the current total is **1374 passed, 0 failed** (236 Phase 1 baseline + 111 Phase 2 + 203 Phase 3 + 404 Phase 4 + 420 Phase 5), with all 954 prior tests preserved. `236` is the Phase 1 baseline and `347` / `550` / `954` are past checkpoints; `1374` is the ONLY current total. See [Testing](documentation/TESTING.md) for the exact current total, breakdown and commands.

The runner snapshots and restores the local save, so tests do not destroy a real journey.

---

## Controls

| Action | Keyboard / gamepad | Touch |
| --- | --- | --- |
| Move | WASD / arrow keys / left stick | Virtual joystick |
| Sprint | Shift / right trigger | Joystick pushed to the edge |
| Interact | E / Space / south button | Interact button |
| Roster | C | HUD button |
| Summon | G | HUD button |
| Inventory | I | HUD button |
| Quests | Q | HUD button |
| Pause | Esc / Start | Menu button |

All input actions are registered at runtime in `scripts/core/input_setup.gd`, so bindings live in readable code instead of opaque `project.godot` event blobs.

---

## What is implemented

### World and traversal

- Isometric 16×16-tile chunk streaming with a configurable load radius — **preserved** in Phase 3 and 4 (`_update_streaming` diffing, `IsoMath` / `ChunkStreamer` behaviour unchanged).
- **Exactly TWO regions** (`greenward` + `moonpetal_hollow`) with a `RegionGraph`, validated gate transitions, `RegionPortal`s and per-region saves (`region`, `region_positions`); each region keeps its own local grid↔world projection.
- MultiMesh terrain, water AND a new `detail` ground-cover layer (one draw call per layer per chunk; `detail` is parented as a child of `terrain`).
- **57 prop kinds** (47 Phase-3 + 6 Phase-4 building/landmark + 4 new Phase-5 kinds: `birch_grove`, `moon_lantern`, `stone_path`, `village_gate`) with deterministic, visually distinct `variant`s via `ProceduralArt.prop_texture(kind, variant)`.
- Richer terrain (moisture/elevation blend, beach band, shoreline foam), a meandering noise-derived RIVER ribbon with waterfalls and wooden + stone bridges.
- **5 visually distinct locations**: the village hub, Listening Stones ruins, the Hollowed Grove (corrupted palette), the Moonpetal Shrine glade, and the decorative river.
- Atmospheric `fog.gdshader` veil (layered below the HUD), `GreenwardStyle.phase()`-driven day/night lighting and `WeatherDirector` weather architecture (CLEAR/MIST/RAIN/POLLEN_BLOOM).
- Phase-driven lighting, fireflies, pollen motes, ambient wildlife (butterflies/moths/birds), animated props (bob/sway/pulse/flicker/drift) and non-destructive interactive props (highlight + toast; no `GameState` mutation).
- **8-state × 8-direction character animation (+ ADDITIVE 9th `CAST` state)** (`CharacterAnimator` + `ActorFrameSource`), sprite-sheet support via `SpriteFramesActorSource` and an `ActorVisual.set_frame_source()` seam for real painted sprites; current frames (including the ONE TEMPORARY procedural demo character) are clearly-marked placeholders.
- Procedurally generated props, village huts, waypoint, NPCs and roaming monsters; Y-sorted actors and props, camera smoothing, zoom limits.
- Mobile caps (48 props/chunk, ~26 mobile; ≤300 particles; fog/rain disabled on mobile), cached textures and off-screen animated-prop gating.
- Keyboard, gamepad and touch input; automatic touch UI.

### Narrative and quests

- Data-driven dialogue for Elder Maelin, Sera Quill and Pip.
- Two chained story quests: *The Glade's Whisper* and *What Sleeps Beneath*.
- Talk, kill and turn-in steps; quest rewards include currency, materials and equipment.
- Quest state, step and progress persist in the save.

### Turn-based combat

- Pure `CombatEngine` (`RefCounted`) with no scene dependencies.
- Speed-based turn order, basic skills, ultimates, energy, status effects, shields, healing, cleansing, lifesteal, crits and misses.
- Fire → Wind → Earth → Water → Fire elemental wheel, plus Light ↔ Dark.
- Deterministic seeded RNG for reproducible tests.
- Boss phases and elite/boss flags.
- Player and enemy AI both drive the same engine.
- Battle rewards are applied through `GameState`.

### Collection, gacha and progression

- 12 original characters across common → mythic rarities.
- 36 skills, including ultimates.
- Two banners with explicit rates, hard pity, featured pity and a ten-pull Epic floor.
- Duplicate characters convert into awakening progress.
- Party of up to 4; collection bonus from unique ownership.
- Levels, XP, ascension, awakening, bond, equipment slots and stat scaling.
- Inventory with currencies, materials and equipment.
- Local JSON save with atomic replacement, autosave, backup-on-corruption and version field.

### UI

- Responsive 16:9 layout built from code via `UITheme` and `UIFactory`.
- Title screen, HUD, dialogue box, pause menu.
- Summon, collection, inventory and quest screens.
- Combat overlay with unit cards, turn order, skill list, targeting, log, auto mode, speed toggle, victory/defeat panel and retreat confirmation.
- Touch joystick and touch action buttons.

### Engineering

- Data-driven content: characters, skills, enemies, enemy groups, items, banners, quests, dialogue and regions are JSON.
- Pure gameplay classes (`GachaService`, `CombatEngine`, `CombatAI`, `CombatFactory`, `ChunkStreamer`, `IsoMath`) suitable for headless tests and future server reuse.
- 236 headless assertions (Phase 1 baseline) covering content integrity, math, gacha, combat, state, save and UI/scene instantiation — the Phase 1 baseline is preserved and Phases 2–5 add coverage on top (8 Phase 3 + 11 Phase 4 + 9 Phase 5 test groups). **236 is the Phase 1 baseline, not the current total**; see [Testing](documentation/TESTING.md) for the exact current total (**1374 passed, 0 failed**) and the 236 + 111 + 203 + 404 + 420 breakdown.
- No copyrighted assets, names, music or characters.

---

## Phase 2 — Content Pipeline, Validation & CI

Phase 2 hardens content authoring before adding volume. It is implemented on top of the Phase 1 baseline and verified locally (with one honesty caveat about GitHub Actions, noted below).

### Strict content validation

- `scripts/core/content_validator.gd` (`ContentValidator`) strictly validates all **9** JSON content files: required fields and types, enum values (rarities, elements, categories, slots, statuses), duplicate IDs/keys, cross-file references (skills, items, enemies, enemy groups, characters, banners, quests, dialogue, regions), invalid rarity values, missing skills/items and invalid reward references. Errors are reported as `file → path: message`.
- `ContentDB` runs the same validator at boot, so the game and CI cannot disagree.
- `tools/validate_content.gd` is the CI entry point: `godot --headless --path . --script res://tools/validate_content.gd` prints `[validate] OK — 9 content files parsed and validated.` and exits `0` on success, `1` on failure.

### Mechanical character passives

Each character declares `passive: { "id", "name", "text" }`; the 12 supported ids are `whisperstep`, `rooted`, `dawnkeeper`, `hollow_crown`, `tidecall`, `ashen_wake`, `hold_the_line`, `small_miracles`, `sanguine_waltz`, `patient_weaver`, `deep_roots` and `nothing_to_lose`. They are applied in `CombatEngine` through `unit_speed` / `unit_defense` / `outgoing_multiplier` / `incoming_multiplier`, plus battle-start energy (`small_miracles`), a one-time heal energy refund (`dawnkeeper`), burn-on-crit (`ashen_wake`), shield-on-heal (`tidecall`) and lifesteal (`sanguine_waltz`).

> **Honest caveat:** *Dawnkeeper* is a one-time **20-energy refund on the first healing skill each battle**, because the current combat model has no skill energy cost. It is not a discount on an energy cost.

### Equipment element resonance

The first elemental equipped item (weapon first) sets the wielder's resonance element. A skill matching that element deals **+8%** damage (`EQUIPMENT_RESONANCE`); when the equipped element also matches the wielder's own element there is an extra **+4%** (`EQUIPMENT_ATTUNEMENT`). Other equipment stats remain additive.

### Quest prerequisites and reward routing

- Quest `requires` is enforced by `GameState.start_quest()` — a quest will not start until its prerequisite is `complete`.
- Reward payloads may name wallet currencies: `GameState.grant_reward_items()` routes `currency`-category entries to `add_currency()` and other items to `add_item()`. The validator checks that reward references resolve.

### CI and export smoke build

`.github/workflows/ci.yml` defines a GitHub Actions job that downloads the Godot **4.7.2** Linux headless/editor build, imports the project, validates content, runs the automated test suite, runs a game-scene smoke test, and performs an `--export-pack "Linux/X11"` smoke build via `export_presets.cfg`, uploading the `.pck` as an artifact.

> **Honest caveat:** this pipeline has **not** actually been run on GitHub Actions; it is configured and locally verified only.

---

## Phase 3 — Visual world and player presentation

Phase 3 was explicitly re-scoped to **visual quality**; it did NOT add regions,
continents or traversal systems (those are deferred). It is implemented and
verified locally on top of the Phase 1 + Phase 2 baseline.

### Art direction (single source of truth)

- `scripts/world/visual_style.gd` (`GreenwardStyle`) is the single source of truth for the art direction: grouped palettes (SKY/CANOPY/UNDERGROWTH/WATER/STONE/TIMBER/MAGIC/LIGHT/ACCENTS/UI/ELEMENTS), `phase(name)` lighting/fog presets, `prop_palette(kind)`, `element_color()`, `SPRITE_SPECS`, `coherence_report()`, `performance_tier()` and caps.
- [Visual style guide](documentation/VISUAL_STYLE.md) is the CANONICAL style guide; `GreenwardStyle` implements it in code. All art and lore are original.

### Environment and detail

- `ProceduralArt` now paints **47 prop kinds** (12 original + 35 new: 5 tree varieties, ground cover, structures, magical, water, ambient wildlife) with deterministic, visually distinct `variant`s via `prop_texture(kind, variant)`; `prop_kinds()` / `variant_count()` enumerate them.
- `ChunkBuilder` adds moisture/elevation terrain blending, a beach band, shoreline foam, a meandering noise-derived RIVER ribbon, and a NEW `detail` `MultiMesh` ground-cover layer (ONE extra draw call per chunk, child of `terrain`, `detail.gdshader`). The `build()` signature and `coord/terrain/water/props` return keys are preserved.
- `water.gdshader` (reflections/glints, shore foam, depth shading) and `wind_sway.gdshader` (secondary shimmer, per-instance phase) improved; `fog.gdshader` and `detail.gdshader` added.
- `GreenwardWorld` wires 5 visually distinct locations (village hub, Listening Stones, Hollowed Grove, Moonpetal Shrine glade, the decorative river with waterfalls + wooden & stone bridges), ambient wildlife, and non-destructive interactive props.

### Lighting, atmosphere and weather

- Day/night tint sourced from `GreenwardStyle.phase()`; an atmospheric `fog.gdshader` quad layered below the HUD; phase-driven lighting, fireflies and pollen motes.
- `WeatherDirector` is a pure weather **ARCHITECTURE** (CLEAR/MIST/RAIN/POLLEN_BLOOM) with deterministic transitions, intensity ramp, `params()` and mobile caps. **Rain VFX is one lightweight capped CPU emitter (disabled on mobile); weather is NOT a simulation** — no precipitation physics, splashes, accumulation or snow.

### Player animation architecture

- `CharacterAnimator` is a pure `RefCounted` state machine: **8 states** (IDLE/WALK/RUN/INTERACT/ATTACK/DAMAGE/VICTORY/DEFEAT) × **8 directions** (DOWN … DOWN_LEFT), with priority, looping vs one-shot, tick/frame timing and snapshot/from_snapshot. **"Directional movement" is the DIRECTION axis, not a 9th state.** (Phase 4 later adds a genuine ADDITIVE 9th `CAST` state while keeping `ALL_STATES` at 8 — see the Phase 4 section below.)
- `ActorFrameSource` (`REPLACEMENT_SPEC` / `specs()`) is the STABLE sprite/animation interface with the EXACT final-art replacement specification; `ProceduralActorFrames` / `ProceduralArt.character_frame()` are **clearly-marked TEMPORARY placeholder frames**. Real painted sheets plug in via `ActorVisual.set_frame_source()` — no gameplay changes. `ActorVisual`, `Player`, `WorldNPC` and `RoamingMonster` drive all 9 requested behaviours, 8-direction poses and backward-compatible `walking`/`facing`.

### Performance

Still one `MultiMesh` draw call per terrain/water/detail layer per chunk; no per-tile sprites. Capped props (`MAX_PROPS_PER_CHUNK = 48`, ~26 mobile), capped particles (`MAX_PARTICLES = 300`), `DETAIL_DENSITY = 0.22`, cached textures with `(kind, variant)` keys, off-screen animated-prop gating, fog disabled on mobile, rain disabled on mobile. Chunk streaming, `_update_streaming` diffing and `IsoMath`/`ChunkStreamer` behaviour are preserved. **`GreenwardStyle.performance_tier()` is a coarse `OS.get_name()` hint only — no device profiling was performed**; headless CI uses a dummy renderer.

### Testing

8 new Phase 3 test groups (visual style, character animator, actor frame source, procedural variety, chunk visual quality, weather director, animated/interactive props, world visual integration) add 203 checks. Suite at the Phase 3 checkpoint: **550 passed, 0 failed** = 236 Phase 1 + 111 Phase 2 + 203 Phase 3 (a past checkpoint; the current total is **1374 passed, 0 failed** — see the Phase 5 section / [Testing](documentation/TESTING.md)).

> **Asset status: ONE final playable character (Lilith); the 12 collectibles are still placeholders.** Lilith's world sheet, portrait, combat sprite and full-body illustration are final imported art under `assets/characters/lilith/` (see `assets/characters/main/little_sister/SPEC.md`). Everything else shipped in Phase 3-5 is **procedural placeholder art** generated in code at runtime — no final painted sprites, sprite sheets, textures, portraits or VFX for the 12 collectible characters — and **no audio** of any kind exists. `ProceduralActorFrames` / `ProceduralArt.character_frame()` are explicitly TEMPORARY; real art plugs in via `ActorVisual.set_frame_source()` / an `ActorFrameSource` subclass. See [Art pipeline](documentation/ART_PIPELINE.md).

---

## Phase 4 — World expansion, real art pipeline and character animation

Phase 4 was explicitly re-scoped to **world expansion, a real art asset
pipeline and character animation** — it did **NOT** implement the original
narrative/quest/dialogue framework (that work is deferred; see
[ROADMAP](documentation/ROADMAP.md)). It is implemented and verified locally
on top of the Phase 1 + 2 + 3 baseline. **Zero final assets were produced** —
this phase built the *pipeline* and honest status, not finished artwork.

### Two regions and region graph

- `resources/data/regions.json` now has **exactly TWO regions**: `greenward`
  and `moonpetal_hollow` (a small silver-birch moonlit vale with a cooler
  violet/silver biome, `noise_seed 24601`, `load_radius 1`). No additional
  continents.
- Each region adds `world_origin` (logical world coordinates), `environment`
  (`zone`, `weather_bias`, `fog_density`, `ambient_tint`, `ambient_music`),
  `entry_points` and `connections` (id/to/via/entry/kind/label); `via` is the
  source entry point, `entry` the destination entry point, with bidirectional
  links.
- `scripts/world/region_graph.gd` (`RegionGraph`) plus
  `ContentValidator.validate_region_graph()` (BFS reachability) and strict
  connection checks; `scripts/world/region_portal.gd` gates emit
  `EventBus.region_change_requested`; `GameScreen` rebuilds the world on a
  validated change; `GameState` gained `player_region`, `region_positions` and
  two save keys (`region`, `region_positions`), fully backwards compatible
  (old saves load into greenward).
- `GreenwardWorld` is region-parameterized (`region_id`, `entry_point`):
  greenward keeps its hardcoded builders, `moonpetal_hollow` is data-driven via
  `_build_generic_region()`. `ChunkStreamer` / `IsoMath` are unchanged.
  Region transitions are validated and wired but **cannot be interactively
  playtested headlessly**.

### Real art asset pipeline (placeholder-only)

- `scripts/art/asset_manifest.gd` (`AssetManifest`) records 8 asset classes
  with exact dimensions, transparent RGBA8, anchors, animation frame layouts,
  import settings, naming and replacement seams; `status_report()`,
  `check_disk()`, `validate_sheet_specs()`, `replacement_seams()`.
- `scripts/art/sprite_frames_actor_source.gd` (`SpriteFramesActorSource`) —
  production `SpriteFrames`-based source with `from_disk()` and
  `validate_sheets()` and a graceful missing-asset fallback; animation names
  `<state>_<dir>` + `cast_<dir>`.
- `scripts/art/demo_character_frames.gd` (`DemoCharacterFrames`) — **ONE**
  fully integrated, clearly-marked TEMPORARY in-memory procedurally-generated
  `SpriteFrames` demonstration character wired to the player (NOT final art).
- `assets/README.md` (workflow) and `assets/ASSET_STATUS.md` (exact status
  table). Real sheets plug in via
  `ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>))`.

> **Exact asset status (from `AssetManifest.status_report()`): FINAL 0 / TEMPORARY 8 / MISSING 8.** `check_disk()` is `false` for all 8; the only
> image file in the project is `icon.svg`. **ZERO final painted assets**,
> **no audio**, **no real sprite sheets / PNG textures on disk**; all shipped
> art is runtime procedural placeholder and the demo sheet is TEMPORARY
> procedural frames. No fake painted art was fabricated from polygons. See
> [Art pipeline](documentation/ART_PIPELINE.md) §14.

### CAST additive animation

- `CharacterAnimator` gained an ADDITIVE 9th state `CAST = 8` while
  `ALL_STATES` stays 8 and all Phase-3 timing arrays are unchanged (separate
  `CAST_STATE/CAST_FRAMES=7/CAST_FPS=12/CAST_LOOPING/CAST_PRIORITY`,
  `EXTENDED_STATES` 9, `LOCOMOTION_STATES`, `RETURN_STATES`,
  `frame_count_for/fps_for/looping_for/priority_for`, `transition_to`,
  `can_transition`, `finish_and_return`, `play_cast`, `cast_active`,
  `previous_state`, `transitioned` signal).
- `ActorFrameSource` / `ProceduralActorFrames` gained CAST accessors;
  `ProceduralArt.character_frame()` supports state 8 with a distinct CAST
  pose; `GreenwardStyle.CAST_SPEC`; `ActorVisual.play_cast()` + CAST aura;
  8-direction idle/walk/run + attack/cast/damage/victory/defeat/interaction.

### Environment quality, props and background preparation

- **6 new prop kinds** (`watchtower`, `market_stall`, `stone_wall`, `gazebo`,
  `banner_post`, `moon_shrine`) with distinct variants →
  `ProceduralArt.prop_kinds()` / `ContentValidator.PROP_TYPES` now **53**; 4
  placed at Greenward landmarks. Better paths (per-instance cobble colour +
  width variation), elevation/moisture-biased forest variation, distinct
  environmental zones (`current_zone()`) and region-specific fog/tint/weather.
- `scripts/world/chunk_preparer.gd` (`ChunkPreparer`) — pure, bounded LRU,
  main-thread **FRAME-SLICED** background preparation of at most ONE chunk per
  frame plus a bounded prefetch ring, feeding `_load_chunk` with a synchronous
  fallback. **NO THREADS** (Godot 4 `MultiMesh`/`Image`/`ShaderMaterial` and
  scene-tree operations are not thread-safe); `ChunkStreamer` unchanged. A
  shutdown-leak fix brings headless smoke tests to **ZERO leaked RIDs**.

### Testing and verification

- **11 new Phase 4 test groups (404 checks)** brought the suite to
  **954 passed, 0 failed** = 236 Phase 1 + 111 Phase 2 + 203 Phase 3 + 404
  Phase 4; all 550 prior tests preserved. **954 is the Phase 4 checkpoint, not
  the current total** — Phase 5 brings it to **1374 passed, 0 failed**. See
  [Testing](documentation/TESTING.md).
- All 6 verification commands exit `0` (editor import, content validator →
  `[validate] OK — 9 content files parsed and validated.`, test suite, title
  smoke `--quit-after 180`, game smoke `--quit-after 240`, and
  `--export-pack "Linux/X11"` → a non-empty `.pck` smoke build), with ZERO
  errors/warnings/leaked RIDs. No exact byte size is documented here; the smoke
  build is verified by the non-empty `.pck` it produces.

> **Asset status: ZERO assets are final.** Everything shipped in Phase 4 is
> **procedural placeholder art** — no final painted sprites, sprite sheets,
> textures, portraits or VFX — and **no audio** exists. The ONE demonstration
> character is a TEMPORARY in-memory procedural sheet, NOT final art. No device
> profiling was performed (headless uses a dummy renderer); CI is configured but
> not run on GitHub; there is no threading, only TWO regions, and no
> multiplayer/backend.

---

## Phase 5 — Character art and visual production

Phase 5 was re-scoped to **character art and visual production** — it did NOT
implement the original "Combat depth and encounter design" heading (that work is
deferred; see [ROADMAP](documentation/ROADMAP.md)). It builds the *production
pipeline and authored specifications* for future external art on top of the
preserved Phase 1–4 baseline. **Zero final assets were produced** — all art is
still runtime procedural placeholder and the 12 specs + prompts are
PREPARATION, not finished artwork.

### Production character art pipeline (10 kinds)

- `scripts/art/character_art_pipeline.gd` (`CharacterArtPipeline`) defines TEN
  asset kinds with exact dimensions, anchors, transparent RGBA8, frame layout,
  import settings, `lower_snake_case` naming and replacement seams:
  `full_body_illustration` 1024×2048, `character_portrait` 1024×1280 master →
  256×384 export, `combat_sprite` 128×192, five 96×128 sprite sheets
  (`movement_sheet` / `attack_sheet` / `cast_sheet` / `victory_sheet` /
  `defeat_sheet`, 8 direction rows × per-state columns) and `skill_vfx` /
  `ultimate_vfx` 192×192 / 6 frames. `sheet_layout()` (9 states × 8 directions),
  `animation_names()` (72), `validate_asset()`, `import_settings()`,
  `replacement_seams()`. `assets/CHARACTER_ART_PIPELINE.md`.

### All 12 characters READY for artwork (specs complete, ZERO final assets)

- `scripts/art/character_art_spec.gd` (`CharacterArtSpec`) holds ONE authored
  spec per id (`lyra_vey`, `bramble`, `seraphine`, `nyx`, `coralyn`, `ignis`,
  `mira_sol`, `thistle`, `vespera`, `arachnia`, `terra`, `kael`) with name/id,
  race, element, rarity, role, appearance, hair, outfit, accessories, weapon,
  personality, visual theme, animation/portrait requirements and detailed
  generation prompts. Identity fields are verbatim from `characters.json`
  (gameplay data UNCHANGED); 1 mythic / 3 legendary / 4 epic / 3 rare / 1 common;
  Legendary/Mythic get a distinct premium visual tier.
  `assets/CHARACTER_SPECS.md` + 12 × `assets/characters/<id>/SPEC.md` +
  `assets/GENERATION_PROMPTS.md` (global style anchor + 12 prompts + exact output
  specs for FUTURE external generation). **These specs are complete and the
  characters are READY for artwork — but ZERO final assets exist.**

### Character presentation

- `UITheme.RARITY_EFFECTS` + `rarity_effect` / `is_premium_rarity` /
  `rarity_glow` / `rarity_tier_label` — distinct Legendary/Mythic glow/border/
  aura/frame. `PortraitView` real-portrait seam (`portrait_texture`,
  `set_portrait_texture`, `portrait_report`) via `PortraitAssetSource` with a
  guarded procedural fallback + deterministic premium aura/inner frame.
  `CollectionScreen` premium borders/tier labels, `visual_theme` line, flourish,
  larger premium portrait, `presentation_report()`. `GachaScreen` rarity-tinted
  featured backdrop, `visual_theme` line, premium result cards, reveal scale-pop
  + "Best:" flourish, `presentation_report()`. `CombatScreen` ultimate gold
  styling, element tint, skill legibility, ultimate name banner,
  `skill_presentation_report()`. `UnitCard` premium border.

### Sprite-sheet registration (9 × 8) with procedural fallback

- `SpriteFramesActorSource.register_character()` / `validation_report()` /
  `animation_names()` / `registration_report()`; all 9 states (8 core + additive
  CAST) × 8 directions = **72 animations**. `ActorVisual.configure_character()` /
  `character_art_report()`; `WorldNPC` / `RoamingMonster` call it.
  `ProceduralActorFrames` REMAINS the active fallback (no real sheets exist); the
  Phase-4 `from_disk()` leak fix is preserved (ZERO leaked RIDs); player demo
  untouched (`using_temporary_art == true`).

### World visual standards and 57 prop kinds

- `scripts/world/world_visual_standards.gd` (`WorldVisualStandards`) — 6
  categories (player / npc / monster / building / vegetation /
  environment_object) with canvas, anchor, outline, palette group, z-index,
  batching and fallback; `region_tint()` emerald vs silver-violet; `validate()`.
  `GreenwardWorld.apply_visual_standards()` / `visual_standards_report()` + 4 new
  `visual_style_report()` keys; distinct bounded Moonpetal Hollow
  silver-birch / moonlit and Greenward village-gate compositions. 4 NEW prop
  kinds (`birch_grove`, `moon_lantern`, `stone_path`, `village_gate`) →
  **57 prop kinds** total; `GreenwardStyle.coherence_report() == []`;
  `ContentValidator.PROP_TYPES` 57.

### Asset production manifest (exact FINAL/TEMPORARY/MISSING)

> **FINAL 0 / TEMPORARY 8 / MISSING 8** (`AssetManifest.status_report()`, 8 asset
> classes; `check_disk()` false for all 8) and **FINAL 0 / TEMPORARY 120 /
> MISSING 120** (`CharacterAssetRegistry.report()`, 12 characters × 10 kinds =
> 120; `check_disk()` false for all 120). Both are disk-computed and FINAL is
> NEVER hardcoded; `assets/ASSET_PRODUCTION_MANIFEST.md` lists all 120 rows.
> **ZERO final assets** exist — no `.png/.webp/.jpg/.tres/.res` art files
> anywhere, the only image is `icon.svg`; the ONE demonstration character is a
> TEMPORARY in-memory procedural `SpriteFrames` (`DemoCharacterFrames`,
> `loaded_from_disk == false`). **No audio** exists.

### Testing and verification

- **9 new Phase 5 test groups (420 checks)** bring the suite to
  **`1374 passed, 0 failed`** = 236 Phase 1 + 111 Phase 2 + 203 Phase 3 + 404
  Phase 4 + 420 Phase 5; all 954 prior tests preserved. See
  [Testing](documentation/TESTING.md).
- All 6 verification commands exit `0` (editor import, content validator →
  `[validate] OK — 9 content files parsed and validated.`, test suite, title
  smoke `--quit-after 180`, game smoke `--quit-after 240`, and
  `--export-pack "Linux/X11"` → a non-empty `.pck` smoke build), with ZERO
  errors/warnings/leaked RIDs. No exact byte size is documented here.

> **Asset status: ONE final playable character (Lilith); the 12 collectibles are still placeholders.** Lilith's final art (72 world animations, portrait, combat sprite, full-body illustration) lives in `assets/characters/lilith/`. Everything else shipped in Phase 5 is
> **procedural placeholder art** — no final painted sprites, sprite sheets,
> textures, portraits or VFX for the 12 collectible characters — and **no audio** exists. **NO visual testing** was
> performed (all verification is `--headless` with Godot's dummy renderer;
> `_draw()` output, auras, borders, tints, silhouettes and tween pops were NOT
> visually inspected on screen); there is no device profiling, no threads, only
> TWO regions, and no multiplayer/backend. CI is configured but not run on
> GitHub Actions.

---

## Content at a glance

| Content | Count |
| --- | --- |
| Playable regions | 2 (Greenward, Moonpetal Hollow) |
| Characters | 12 |
| Skills | 36 |
| Enemy types | 6 |
| Enemy groups | 5 |
| Summon banners | 2 |
| Story quests | 2 |
| Dialogue scenes | 3 |
| Items / currencies | 14 |
| Party size | 4 |
| Combat units per side | 1–6 |

Rarity spread: common, rare, epic, legendary, mythic. Elements: fire, wind, earth, water, light, dark, neutral.

---

## Project layout

```text
project-fantasy/
├─ project.godot
├─ icon.svg
├─ .gitignore                   # Godot cache, exports, temp files
├─ scenes/
│  ├─ main.tscn                 # title / entry scene
│  └─ game.tscn                 # playable world + UI
├─ scripts/
│  ├─ core/                     # EventBus, input, content DB + validator, save, game state
│  ├─ data/                     # CharacterDef, SkillDef
│  ├─ collection/               # CharacterInstance
│  ├─ gacha/                    # pure summon logic
│  ├─ combat/                   # pure engine, AI, combatant, factory, elements, passives
│  ├─ world/                    # streaming, chunks, art, actors, day/night, regions
│  │  ├─ visual_style.gd        # GreenwardStyle — palette/phases/caps (single source)
│  │  ├─ character_animator.gd  # 8 core states (+ additive CAST) x 8 directions
│  │  ├─ actor_frame_source.gd  # stable sprite seam + REPLACEMENT_SPEC
│  │  ├─ procedural_actor_frames.gd  # TEMPORARY placeholder frame source
│  │  ├─ region_graph.gd        # two-region graph, world coords, connections
│  │  ├─ region_portal.gd       # interactable gate → region_change_requested
│  │  ├─ chunk_preparer.gd      # bounded LRU, frame-sliced background prep (NO threads)
│  │  ├─ weather_director.gd    # weather architecture (CLEAR/MIST/RAIN/POLLEN_BLOOM)
│  │  ├─ animated_prop.gd       # cheap data-driven animated prop
│  │  ├─ interactive_prop.gd    # non-destructive interactive prop
│  │  └─ world_visual_standards.gd  # WorldVisualStandards — 6 categories, region tints (Phase 5)
│  ├─ art/                       # real art asset pipeline (Phase 4) + Phase 5 character art
│  │  ├─ asset_manifest.gd      # 8 asset classes; FINAL 0 / TEMPORARY 8 / MISSING 8
│  │  ├─ sprite_frames_actor_source.gd  # SpriteFrames sheets via from_disk()
│  │  ├─ demo_character_frames.gd  # ONE TEMPORARY procedural demo character
│  │  ├─ character_art_pipeline.gd   # CharacterArtPipeline — 10 asset kinds + exact specs (P5)
│  │  ├─ character_art_spec.gd       # CharacterArtSpec — 12 specs + generation prompts (P5)
│  │  ├─ character_asset_registry.gd # disk-computed FINAL 0 / TEMPORARY 120 / MISSING 120 (P5)
│  │  └─ portrait_asset_source.gd    # PortraitAssetSource — null-safe texture lookup (P5)
│  ├─ player/                   # player controller, touch state
│  ├─ ui/                       # theme, factory, HUD, dialogue, overlays
│  │  ├─ combat/                # unit card
│  │  └─ screens/               # summon, collection, inventory, quests, pause, combat
│  └─ game/                     # main entry and game-screen controller
├─ resources/
│  ├─ data/                     # all JSON content
│  └─ shaders/                  # terrain, water, wind sway, fog, detail
│     ├─ fog.gdshader           # cheap UV+TIME atmospheric fog
│     └─ detail.gdshader        # per-instance-COLOR ground cover
├─ assets/                      # real-art drop-in contract (NO final files on disk)
│  ├─ README.md                 # workflow + per-class specs
│  ├─ ASSET_STATUS.md           # exact FINAL/TEMPORARY/MISSING status table (Phase 4)
│  ├─ CHARACTER_ART_PIPELINE.md # 10 character-art asset kinds + exact specs (Phase 5)
│  ├─ CHARACTER_SPECS.md        # 12 authored character specs (Phase 5)
│  ├─ GENERATION_PROMPTS.md     # global style anchor + 12 prompts + output specs (Phase 5)
│  ├─ ASSET_PRODUCTION_MANIFEST.md  # disk-computed 120-row FINAL/TEMPORARY/MISSING (Phase 5)
│  ├─ characters/<id>/SPEC.md   # 12 per-character art specs (Phase 5)
│  └─ <class>/<content_id>/     # e.g. characters/mira_sol/world_sheet.png
├─ tests/
│  └─ test_runner.tscn/.gd      # headless suite
├─ tools/
│  └─ validate_content.gd       # CI content validation entry point
├─ .github/
│  └─ workflows/ci.yml          # GitHub Actions pipeline
├─ export_presets.cfg            # Linux/X11 export smoke build
├─ documentation/
│  ├─ ARCHITECTURE.md
│  ├─ ROADMAP.md
│  ├─ BACKEND.md
│  ├─ ART_PIPELINE.md        # replacement workflow + §14 Phase 4 / §15 Phase 5 status
│  ├─ VISUAL_STYLE.md         # canonical visual style guide (+ §12 Phase 4 / §13 Phase 5 status)
│  ├─ TESTING.md
│  └─ CONTENT_GUIDE.md
└─ backend/
   └─ schemas/schema.sql        # proposed PostgreSQL schema
```

---

## Save data

The slice saves to `user://project_fantasy_save.json` (on Windows this is under `%APPDATA%\Godot\app_userdata\Project Fantasy\`).

Saved fields include profile, roster, party, inventory, quests, pity counters, flags, player position and save version.

**The save is local and non-authoritative.** It can be edited by the player. It is suitable only for the offline slice and will be replaced by server-owned state in Phase 12. See `documentation/BACKEND.md`.

---

## Limitations

Honest list of what is **not** in this build:

- **No multiplayer.** No accounts, login, friends, chat, guilds, co-op, PvP, trading or marketplace.
- **No server.** Gacha rolls, currency changes, inventory and rewards are computed on the client.
- **No audio.** No music, ambience, SFX or voice.
- **One final playable character; the rest is placeholder art.** Lilith has final imported playable art (`assets/characters/lilith/`), but the 12 collectible characters, terrain, props and UI still use procedural shapes, not final painted assets.
- **11 of 12 collectibles are placeholder; no audio.** `AssetManifest.status_report()` is **FINAL 0 / TEMPORARY 8 / MISSING 8** and `CharacterAssetRegistry.report()` is **FINAL 0 / TEMPORARY 120 / MISSING 120** (12 × 10); both are disk-computed and FINAL is NEVER hardcoded. Lilith's final art is intentionally tracked outside those 12-character registries (see `assets/characters/main/little_sister/SPEC.md`); every other asset is **procedural placeholder** — no final painted sprites, sprite sheets, PNG textures, portraits or VFX on disk — and **no audio** of any kind exists. The 12 `CharacterArtSpec` specs + generation prompts are **PREPARATION for future external art, not finished artwork**. The ONE demonstration character is a TEMPORARY in-memory procedural `SpriteFrames` (`DemoCharacterFrames`, NOT final art); real art plugs in via `SpriteFramesActorSource.from_disk()` / `register_character()` → `ActorVisual.configure_character()`. See [Art pipeline](documentation/ART_PIPELINE.md) §15 and `assets/ASSET_PRODUCTION_MANIFEST.md`.
- **NO visual testing was performed.** All verification is `--headless` with Godot's dummy renderer; `_draw()` output, auras, borders, tints, silhouettes and tween pops are compile/build-safe and structurally asserted but were **NOT visually inspected on screen** — no shader compilation / appearance verification, no device profiling. The Phase 5 premium rarity glows, borders, tints and reveal pops are code-driven and were never viewed on a real display.
- **Weather is an architecture, not a simulation.** `WeatherDirector` drives moods; rain is one lightweight capped CPU emitter (disabled on mobile) with no precipitation physics, splashes, accumulation or snow.
- **No device profiling.** `GreenwardStyle.performance_tier()` is a coarse `OS.get_name()` hint only; mobile budgets are guidance, not measured frame times. Headless CI uses a dummy renderer, so full shader compilation is not exercised.
- **No threads.** `ChunkPreparer` is main-thread FRAME-SLICED background preparation (at most one chunk per frame) with a synchronous fallback — NOT threaded, and no pre-baked cache. Fog/river/beach bands are procedural approximations and there is no occlusion culling beyond the chunk ring.
- **Only TWO regions.** `greenward` + `moonpetal_hollow` (a small silver-birch moonlit vale); no six empty continents, no seamless zone streaming, no elevation/cliffs/water traversal rules, no fast-travel / map / fog-of-war, no mounts, no spawn directors/respawn timers and no world audio ambience. Region transitions are validated and wired but **cannot be interactively playtested headlessly**.
- **Greenward's layout is partly hardcoded.** Its village/NPC/landmark composition is hardcoded; `moonpetal_hollow` is fully data-driven. Adding more regions still needs content and tests (see [Content guide](documentation/CONTENT_GUIDE.md) §12).
- **No live events, seasons, mail, battle pass or shop.**
- **No localization or accessibility settings** beyond responsive layout and large touch targets.
- **No analytics, crash reporting or telemetry.**
- **No performance profiling on target mobile hardware** yet. Budgets and guidance exist in `documentation/ART_PIPELINE.md`.
- **No anti-cheat or tamper resistance.**
- **CI is configured, not yet proven on GitHub Actions.** The workflow in `.github/workflows/ci.yml` and its steps (content validation, tests, game-scene smoke test, export pack) are verified locally, but the pipeline has not actually been executed on GitHub.
- **Combat depth is a vertical slice**, not final balance. Numbers are data-driven and expected to change.
- **No final legal/compliance review** for app-store launch, privacy policy, age ratings or in-app purchases.

---

## Documentation

- [Architecture](documentation/ARCHITECTURE.md) — runtime layers, data flow, streaming, combat and gacha design.
- [Roadmap](documentation/ROADMAP.md) — 20-phase plan from vertical slice to live service.
- [Backend and database](documentation/BACKEND.md) — recommended server stack, authority boundaries and schema.
- [Art pipeline](documentation/ART_PIPELINE.md) — replacing placeholders with production assets.
- [Visual style guide](documentation/VISUAL_STYLE.md) — canonical art direction, palettes, animation and sprite specs (Phase 3 guide + §12 Phase 4 + §13 Phase 5 status).
- [Testing](documentation/TESTING.md) — automated suite and manual QA checklist.
- [Content guide](documentation/CONTENT_GUIDE.md) — adding characters, skills, enemies, banners and quests.

---

## Originality and licensing

All characters, names, locations, factions, dialogue, UI text and procedural art in this repository are original work created for PROJECT FANTASY. No third-party copyrighted characters, music, textures, fonts or game data are included.

Godot Engine is used under the MIT license. Any future third-party asset must be recorded with its license and source before being committed.
