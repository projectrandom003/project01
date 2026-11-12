# Architecture

This document describes how the vertical slice is assembled today and which boundaries are intended to survive into the online game.

The guiding rule is simple:

> **Content is data. Rules are pure code. Nodes are presentation. The server will own consequences.**

---

## 1. Runtime layers

```text
┌──────────────────────────────────────────────────────────────┐
│ Entry scenes                                                 │
│  scenes/main.tscn  →  Main (title, scene switching)          │
│  scenes/game.tscn  →  GameScreen (world + UI ownership)      │
└──────────────────────────────┬───────────────────────────────┘
                               │
┌──────────────────────────────▼───────────────────────────────┐
│ Presentation                                                 │
│  HUD · DialogueBox · OverlayScreen subclasses · CombatScreen │
│  PortraitView · MainBackdrop · TouchJoystick                 │
└──────────────────────────────┬───────────────────────────────┘
                               │ intent + events
┌──────────────────────────────▼───────────────────────────────┐
│ Session facade                                               │
│  GameState: profile, roster, party, inventory, quests, pity  │
└──────────────────────────────┬───────────────────────────────┘
                               │ reads content / emits signals
┌──────────────────────────────▼───────────────────────────────┐
│ Pure rules                                                   │
│  GachaService · CombatEngine · CombatAI · CombatFactory      │
│  ElementTable · CharacterInstance · ChunkStreamer · IsoMath  │
└──────────────────────────────┬───────────────────────────────┘
                               │
┌──────────────────────────────▼───────────────────────────────┐
│ Content + persistence                                        │
│  ContentDB (JSON) · SaveService (local JSON)                 │
└──────────────────────────────────────────────────────────────┘
```

The world-side presentation layer (`GreenwardWorld`) is driven by a set of
Phase 3 visual systems that all read one shared palette: `GreenwardStyle`
(single source of truth), `CharacterAnimator` + `ActorFrameSource` (8-state ×
8-direction animation with a `set_frame_source()` seam), `WeatherDirector`
(weather architecture), `AnimatedProp` / `InteractiveProp`, an atmospheric
`fog.gdshader` quad, and a batched `detail` `MultiMesh` ground-cover layer.
Together they render 5 visually distinct locations over the preserved chunk
streaming. See §4 "Visual systems". Phase 4 layers a two-region world graph,
a real art asset pipeline (placeholder-only status), an additive CAST
animation state and a bounded frame-sliced chunk preparer on top of these
systems without changing `IsoMath` / `ChunkStreamer` (see §4 "Phase 4
systems"). Phase 5 layers a character-art production pipeline, 12 authored
character specs, disk-computed asset status, premium rarity UI effects, 72-
animation sprite registration and world visual standards on top of these systems
**without producing any final artwork** (see §4 "Phase 5 systems" and §8).

### Autoload order

`project.godot` registers autoloads in dependency order:

1. `EventBus` — global signals, no state.
2. `InputSetup` — registers keyboard/gamepad actions in code.
3. `TouchInput` — shared virtual-joystick vector and touch-button state.
4. `ContentDB` — loads and validates every JSON content file once.
5. `SaveService` — versioned local save read/write.
6. `GameState` — live session state and the gameplay facade.

`GameState` depends on `ContentDB` and `SaveService`, so it must load last.

---

## 2. Scene ownership

### `Main` (`scenes/main.tscn`)

Owns the title screen only. It builds `MainMenu`, connects `play_requested` / `quit_requested`, and switches to `res://scenes/game.tscn`. It deliberately does not own session state; `GameState` is an autoload.

### `GameScreen` (`scenes/game.tscn`)

The only node that decides whether the world may simulate. It:

- Creates a region-parameterized `GreenwardWorld` (`region_id`, `entry_point`) and a `CanvasLayer` UI.
- Creates HUD, dialogue, overlay root and combat root.
- Routes `EventBus.encounter_requested` and `EventBus.dialogue_requested`.
- Opens summon / collection / inventory / quest / pause overlays.
- Suspends the world while a menu, dialogue or battle is open.
- Saves player position and session state on exit.
- Rebuilds the world on a validated `EventBus.region_change_requested(target_region_id, entry_point)` region change and persists the per-region player position (`GameState.region_positions`).

World suspension uses:

```gdscript
world.process_mode = Node.PROCESS_MODE_DISABLED
world.player.input_enabled = false
TouchInput.release()
```

This is intentionally **not** `get_tree().paused`, because the UI must stay interactive while the world is frozen.

### `GreenwardWorld`

Owns streaming, village props, NPCs, roaming monsters, day/night and the player, plus the Phase 3 visual systems: `GreenwardStyle`-driven lighting/fog, `WeatherDirector` atmosphere, `AnimatedProp`/`InteractiveProp`, the `detail` ground-cover layer and 5 visually distinct locations. It is region-parameterized (`region_id`, `entry_point`): greenward keeps its hardcoded village/NPC/landmark builders, while `moonpetal_hollow` (and any other region) is built by a data-driven `_build_generic_region()` with `RegionPortal` gates; region-specific fog/tint/weather come from `region.environment` via `current_zone()`. It talks to the rest of the game through `EventBus`:

- NPC interaction → `dialogue_requested`
- Monster contact → `encounter_requested`
- Player movement → `player_moved`
- Day phase → `day_phase_changed`

No UI node is referenced from world code. `visual_style_report()` returns a cheap, honest snapshot of the active visual state (phase, weather, prop counts, caps, fog/rain flags) for tests and reporting. See §4 "Visual systems".

---

## 3. Data-driven content

All content lives in `resources/data/` and is loaded by `ContentDB`.

| File | Purpose |
| --- | --- |
| `characters.json` | Character identity, rarity, element, role, palette, base stats, skills, ultimate, portrait seed |
| `skills.json` | Damage/heal/shield/buff definitions, targeting, power, energy, statuses |
| `enemies.json` | Enemy identity, base stats, skills, boss phases |
| `enemy_groups.json` | Encounter composition, level, rewards, quest kill credit, elite/boss flags |
| `items.json` | Currencies, materials and equipment; equipment stats and slots |
| `banners.json` | Rates, pools, featured characters, pity thresholds, costs |
| `quests.json` | Steps, prerequisites, rewards |
| `dialogue.json` | Speakers, lines, conditions, quest hooks |
| `regions.json` | Biome palette, chunk settings, props, POIs, spawns |

`ContentDB._validate()` now delegates to `ContentValidator.validate_all()` — the same strict, data-only rules that `tools/validate_content.gd` runs in CI — so boot, tests and CI share one validator across all nine content files. It also enforces:

- Required fields and types, duplicate keys/IDs, valid rarity values, `element`/`kind`/`target`/status enums and numeric ranges.
- `passive.id` values against `PassiveEffects.SUPPORTED_IDS`.
- Dialogue link targets, quest step types, and reward/currency item references.

The original cross-reference checks still apply:

- Character skills and ultimates exist.
- Enemy skills and ultimates exist.
- Enemy-group enemies and reward items exist.
- Banner pools and featured characters exist.
- Quest reward items exist.
- Region spawns reference known enemy groups.

Validation failures are pushed as errors, which makes broken content obvious during startup and CI.

### Typed definitions

`CharacterDef` and `SkillDef` are immutable `RefCounted` wrappers over JSON. They provide typed accessors (`stat()`, skill fields) and keep UI/world code from passing raw dictionaries around. Enemies remain dictionaries because their shape is small and encounter-specific.

### Saved instances

`CharacterInstance` is the mutable, player-owned copy of a character: UID, level, XP, ascension, awakening, bond, duplicates and equipment. Definitions are never mutated.

This separation matters for the server: definitions are static content, instances are rows owned by an account.

---

## 4. World streaming

The world is a continuous 2D space. Grid coordinates exist only for terrain generation, chunking and authored placement.

`IsoMath` converts between grid and isometric world space:

```text
world.x = (gx - gy) * TILE_W / 2
world.y = (gx + gy) * TILE_H / 2
```

`TILE_W = 64`, `TILE_H = 32`.

`ChunkStreamer` is pure selection math:

- `chunk_size = 16` tiles (configurable per region).
- `load_radius = 2` chunks in Greenward.
- A radius-2 ring is 25 chunks.
- Chunks are sorted nearest-first so the player sees the local area before the edges.

`ChunkBuilder` builds one chunk without touching the scene tree:

- Terrain: one `MultiMesh` instance per non-water tile, tinted by moisture noise and path proximity.
- Water: a second `MultiMesh` layer for submerged tiles, animated by a shader.
- Props: deterministic list of type, position, scale, flip and palette.
- A seeded RNG per chunk makes the world reproducible from `region.noise_seed`.

`GreenwardWorld` decides what to add/free. Terrain and water use one draw call per layer per chunk; props are individual `Sprite2D` nodes so they can y-sort with actors.

### Why this scales

The streaming code does not know what a “region” is beyond a dictionary. Adding a new region means adding a JSON file and swapping the generator inputs, not rewriting the ring logic. Distant chunks are freed, so memory is bounded by the ring size rather than world size.

### Visual systems (Phase 3)

Phase 3 expanded the world's presentation without touching chunk streaming,
`IsoMath` / `ChunkStreamer` behaviour or `_update_streaming` diffing. All new
systems read colours from one authority:

- **Single-source palette.** `GreenwardStyle` (`scripts/world/visual_style.gd`)
  owns grouped palettes, `phase(name)` lighting/fog presets, `prop_palette()`,
  `element_color()`, `SPRITE_SPECS`, `coherence_report()` and the performance
  caps. `VISUAL_STYLE.md` is the canonical narrative style guide; when the two
  disagree, `GreenwardStyle` is the implementation truth.
- **47 prop kinds + variants.** `ProceduralArt.prop_texture(kind, variant)`
  draws 12 original + 35 new kinds, each with deterministic, visually distinct
  variants (cached by `(kind, variant)`). `ChunkBuilder` maps prop variety so
  the world does not repeat one texture; density is capped by `GreenwardStyle`.
- **Richer terrain + RIVER + `detail` layer.** `ChunkBuilder.build()` blends
  moisture/elevation, adds a beach band and shoreline foam, a meandering
  noise-derived river ribbon, and returns an optional `detail` `MultiMesh`
  ground-cover layer — **ONE extra draw call per chunk, parented as a child of
  `terrain`** (drawn with `detail.gdshader`, per-instance `COLOR`). The returned
  `coord/terrain/water/props` keys are preserved.
- **Atmosphere.** `fog.gdshader` draws a cheap UV+TIME veil on a full-screen
  quad layered **below the HUD** (z_index 20; HUD is on CanvasLayer layer 10).
  `DayNight` sources its tint from `GreenwardStyle.phase()`; `WeatherDirector`
  (CLEAR/MIST/RAIN/POLLEN_BLOOM) drives fog density, pollen/firefly/rain
  particles and lighting through `params()`.
- **Animation architecture.** `CharacterAnimator` is a pure 8-state ×
  8-direction state machine (**"directional movement" is the DIRECTION axis, not
  a 9th state**); `ActorFrameSource` is the stable sprite interface and
  `ActorVisual.set_frame_source()` is the seam where real painted sheets plug
  in. `ProceduralActorFrames` is explicitly TEMPORARY placeholder art.
- **Animated / interactive props.** `AnimatedProp` adds cheap data-driven
  bob/sway/pulse/flicker/drift with off-screen `set_active()` gating;
  `InteractiveProp` adds non-destructive highlight/toast interaction that does
  NOT mutate `GameState`.
- **Mobile caps.** `MAX_PROPS_PER_CHUNK = 48` (~26 mobile),
  `MAX_PARTICLES = 300`, `DETAIL_DENSITY = 0.22`, cached textures, off-screen
  animated-prop gating, and fog/rain **disabled on the mobile tier**.
  `GreenwardStyle.performance_tier()` is a coarse `OS.get_name()` hint, NOT a
  measured device profile.

Chunk streaming, the radius-2 ring, per-layer `MultiMesh` batching (one draw
call per terrain/water/detail layer per chunk) and `_update_streaming` diffing
were all preserved.

### Phase 4 systems (two regions, art pipeline, CAST, background preparation)

Phase 4 builds on the preserved Phase 3 streaming without changing `IsoMath`,
`ChunkStreamer` or `_update_streaming` diffing.

- **Two regions + region graph.** `resources/data/regions.json` now defines
  exactly TWO regions: `greenward` (the original slice) and `moonpetal_hollow`
  (a small silver-birch moonlit vale, cooler violet/silver biome,
  `noise_seed 24601`, `load_radius 1`). Each region adds `world_origin` (a
  LOGICAL world/map-space offset), `environment` (`zone`, `weather_bias`,
  `fog_density`, `ambient_tint`, `ambient_music`), `entry_points` and
  `connections` (`id/to/via/entry/kind/label`). `via` is the SOURCE region's
  entry point and `entry` is the DESTINATION region's entry point; connections
  are bidirectional. `scripts/world/region_graph.gd` (`RegionGraph`) exposes
  `region_ids/has_region/definition/region_name/entry_points/entry_grid/
  connections_from/connection/can_travel/resolve_transition/world_origin/
  local_to_world_position/world_to_local_position/world_position_of_grid/
  region_at_world_position/spawn_grid/spawns/environment/load_radius/validate/
  summary` plus a static `validate_definitions`.
  `ContentValidator.validate_region_graph(regions)` runs a BFS unreachable-
  region check, and strict per-region checks reject missing target regions,
  self-loops, dangling `via`/`entry`, duplicate ids, invalid kind/label and bad
  `world_origin`/`environment`/`entry_points` (`PROP_TYPES` covered 53 Phase-4
  prop kinds; Phase 5 adds 4 more → 57, see "Phase 5 systems" below).
- **Region switching + per-region saves.** `EventBus.region_change_requested
  (target_region_id, entry_point)` plus `scripts/world/region_portal.gd`
  (interactable gate) drive travel. `GameScreen` rebuilds the world on a
  validated region change; `GameState` gained `player_region`,
  `region_positions`, `set_player_region`, `set_region_position`,
  `region_position`, `has_region_position` and TWO save keys (`region`,
  `region_positions`), fully backwards compatible (old saves load into
  greenward). `GreenwardWorld` is region-parameterized (`region_id`,
  `entry_point`): greenward keeps ALL its specific builders, other regions use
  the data-driven `_build_generic_region()` + portals; `current_zone()` applies
  region-specific fog/tint/weather. Streaming compatibility is preserved —
  each region keeps its OWN local grid↔world projection; `world_origin` is a
  logical map/travel space, not a change to `IsoMath`.
- **Real art asset pipeline (placeholder-only).** `scripts/art/
  asset_manifest.gd` (`AssetManifest`) records, for EIGHT asset classes, the
  exact dimensions, transparent RGBA8, anchor, animation frame layout, import
  settings, naming and replacement seam (`status_report()`, `check_disk()`,
  `validate_sheet_specs()`, `replacement_seams()`). `scripts/art/
  sprite_frames_actor_source.gd` (`SpriteFramesActorSource`) is the production
  `SpriteFrames`-based source with `from_disk()` and `validate_sheets()` plus a
  graceful missing-asset fallback; animation names are `<state>_<dir>` plus
  `cast_<dir>`. `scripts/art/demo_character_frames.gd` (`DemoCharacterFrames`)
  builds ONE clearly-marked TEMPORARY in-memory procedural `SpriteFrames` for
  the player (NOT final art). Real sheets plug in via
  `ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>))`.
  `AssetManifest.status_report()` is **FINAL 0 / TEMPORARY 8 / MISSING 8**;
  `check_disk()` is false for all 8; `icon.svg` is the only image file. See
  `assets/README.md` / `assets/ASSET_STATUS.md`.
- **Additive CAST animation.** `CharacterAnimator` gained an ADDITIVE 9th state
  `CAST = 8` while keeping `ALL_STATES` at 8 and all Phase-3 timing arrays
  unchanged (separate `CAST_STATE/CAST_FRAMES=7/CAST_FPS=12/CAST_LOOPING/
  CAST_PRIORITY`, `EXTENDED_STATES` 9, `EXTENDED_STATE_NAMES`,
  `LOCOMOTION_STATES`, `RETURN_STATES`, `frame_count_for/fps_for/looping_for/
  priority_for`, `transition_to`, `can_transition`, `finish_and_return`,
  `play_cast`, `cast_active`, `previous_state`, `transitioned` signal).
  `ActorFrameSource` gained `cast_frame/cast_frame_count/cast_fps/
  validate_sheets/extended_specs`; `ProceduralActorFrames` implements them and
  `ProceduralArt.character_frame` supports state 8 with a distinct CAST pose;
  `GreenwardStyle.CAST_SPEC`; `ActorVisual.play_cast()` + CAST aura.
- **Frame-sliced background preparation (NO threads).**
  `scripts/world/chunk_preparer.gd` (`ChunkPreparer`) is a pure, bounded-LRU,
  frame-sliced queue that prepares at most ONE chunk per frame, prefetches a
  bounded ring outside the loaded ring, and feeds prepared data to
  `_load_chunk` (with a synchronous fallback). **NO THREADS**: `MultiMesh`,
  `Image`, `ShaderMaterial` and all scene-tree operations are NOT thread-safe
  in Godot 4, so generation stays on the MAIN THREAD, sliced across frames.
  `ChunkStreamer` is unchanged. A Phase 4 shutdown-leak fix (a self-referencing
  static method forming a GDScript reference cycle + static caches pinning
  RIDs) means the headless smoke tests now report **ZERO leaked RIDs**.

### Phase 5 systems (character art and visual production)

Phase 5 re-scoped to **character art and visual production**. It ships a
production pipeline, authored character specs and a coherent presentation layer
on top of the preserved systems — **no final artwork was created** and every
procedural fallback remains active. See `ART_PIPELINE.md` §15 for the CURRENT
authoritative asset contract and `assets/ASSET_PRODUCTION_MANIFEST.md` for the
disk-computed status.

- **Character art pipeline.** `scripts/art/character_art_pipeline.gd`
  (`CharacterArtPipeline`) defines TEN character-art asset kinds with exact
  dimensions, anchors, transparent RGBA8, frame layout, import settings,
  `lower_snake_case` naming and replacement seams: `full_body_illustration`
  1024×2048, `character_portrait` 1024×1280 master → 256×384 export,
  `combat_sprite` 128×192, five 96×128 sprite sheets (`movement_sheet`,
  `attack_sheet`, `cast_sheet`, `victory_sheet`, `defeat_sheet`), and
  `skill_vfx` / `ultimate_vfx` 192×192 / 6 frames. `sheet_layout()` (9 states ×
  8 directions), `animation_names()` (72), `validate_asset()`,
  `import_settings()`, `replacement_seams()`, `self_check()`.
  `assets/CHARACTER_ART_PIPELINE.md`.
- **12 character specs + generation prompts.**
  `scripts/art/character_art_spec.gd` (`CharacterArtSpec`) holds ONE authored
  spec per id for the first 12 characters, with identity fields verbatim from
  `characters.json` (UNCHANGED gameplay data), a shared `STYLE_ANCHOR`, a
  distinct premium visual tier for Legendary/Mythic, and detailed per-character
  generation prompts. `assets/CHARACTER_SPECS.md`, 12 ×
  `assets/characters/<id>/SPEC.md` and `assets/GENERATION_PROMPTS.md` (global
  style anchor + 12 prompts + exact output specs for FUTURE external generation).
  These are **preparation for future art, not finished artwork**.
- **Disk-computed asset status (NEVER hardcoded FINAL).**
  `scripts/art/character_asset_registry.gd` (`CharacterAssetRegistry`) computes
  status from disk: `report()`, `check_disk()`, `validate_finished_asset()`,
  `production_manifest()`, `replacement_seams()`.
  `scripts/art/portrait_asset_source.gd` (`PortraitAssetSource`) is a null-safe
  texture lookup. EXACT current status: `AssetManifest.status_report()` is
  **FINAL 0 / TEMPORARY 8 / MISSING 8** (`check_disk()` false for all 8) and
  `CharacterAssetRegistry.report()` is **FINAL 0 / TEMPORARY 120 / MISSING 120**
  (12 characters × 10 kinds = 120; `check_disk()` false for all 120). **ZERO
  final assets** exist — no `.png/.webp/.jpg/.tres/.res` art files anywhere, the
  only image is `icon.svg`; the ONE demonstration character is a TEMPORARY
  in-memory procedural `SpriteFrames` (`DemoCharacterFrames`,
  `loaded_from_disk == false`). No audio.
- **UI rarity effects.** `UITheme.RARITY_EFFECTS` plus
  `rarity_effect` / `is_premium_rarity` / `rarity_glow` / `rarity_tier_label`
  give Legendary/Mythic a distinct glow / border / aura / frame; `PortraitView`
  gained a real-portrait seam and `CollectionScreen` / `GachaScreen` /
  `CombatScreen` / `UnitCard` gained premium presentation (see §8).
- **Sprite registration.** `SpriteFramesActorSource.register_character()` /
  `validation_report()` / `animation_names()` / `registration_report()` cover all
  9 states × 8 directions = 72 animations; `ActorVisual.configure_character()` /
  `character_art_report()` are called by `WorldNPC` and `RoamingMonster`.
  `ProceduralActorFrames` REMAINS the fallback (no real sheets exist); the
  Phase-4 `from_disk()` leak fix is preserved (ZERO leaked RIDs); the player demo
  stays on temporary art (`using_temporary_art == true`).
- **World visual standards.** `scripts/world/world_visual_standards.gd`
  (`WorldVisualStandards`) defines 6 categories (player / npc / monster /
  building / vegetation / environment_object) with canvas, anchor, outline,
  palette group, z-index, batching and fallback, plus `region_tint()` (emerald vs
  silver-violet) and `validate()` (returns `[]`).
  `GreenwardWorld.apply_visual_standards()` / `visual_standards_report()` + 4 new
  `visual_style_report()` keys; distinct bounded Moonpetal Hollow
  (silver-birch / moonlit) and Greenward (village-gate) compositions; 4 NEW prop
  kinds (`birch_grove`, `moon_lantern`, `stone_path`, `village_gate`) bring the
  total to **57 prop kinds** (`ContentValidator.PROP_TYPES`,
  `GreenwardStyle.coherence_report() == []`).

Procedural fallbacks remain active everywhere: all shipped visuals are still
runtime procedural placeholder art, and **NO visual testing** was performed (all
verification is `--headless` with Godot's dummy renderer — `_draw()` output,
auras, borders, tints, silhouettes and tween pops are compile/build-safe and
structurally asserted but were NOT visually inspected on screen; no shader
compilation / appearance verification, no device profiling).

### Current limits

- **Exactly TWO regions** are defined (`greenward` + `moonpetal_hollow`); one region is loaded at a time. There are no six empty continents, no seamless zone streaming, no fast-travel/map/fog-of-war, no mounts, no spawn directors/respawn timers and no world audio ambience. Region transitions are validated and wired but **cannot be interactively playtested headlessly**.
- `greenward`'s village layout, NPC placement and landmark composition remain partly **HARDCODED**; `moonpetal_hollow` is fully data-driven via `_build_generic_region()`.
- Chunk generation is **main-thread frame-sliced, NOT threaded** (`ChunkPreparer` prepares at most one chunk per frame, with a synchronous fallback). True threaded generation remains FUTURE WORK; large radii or high prop density can still hitch on low-end mobile.
- Terrain and water are flat-shaded diamonds, not height-mapped meshes; there are **no elevation/cliffs or water traversal rules**; fog, river and beach bands are procedural approximations; there is no occlusion culling beyond the chunk ring.
- **One final playable character (Lilith); all other shipped art is procedural placeholder.** Lilith has a final imported art set under `assets/characters/lilith/` (72 world animations, portrait, combat sprite, full-body illustration) generated by `tools/generate_lilith_art.py`; see `assets/characters/main/little_sister/SPEC.md`. For the 12 collectible characters there are **ZERO final assets**: `AssetManifest.status_report()` is **FINAL 0 / TEMPORARY 8 / MISSING 8** and `CharacterAssetRegistry.report()` is **FINAL 0 / TEMPORARY 120 / MISSING 120** (12 × 10); the demo sheet is TEMPORARY in-memory procedural frames. **No audio** exists. **NO visual testing** was performed (headless dummy renderer; `_draw()` output, auras, borders, tints and silhouettes were NOT visually inspected).
- **No device profiling** has been performed; mobile budgets come from a coarse `OS.get_name()` hint, not measured frame times. Headless CI uses a dummy renderer, so shader compilation and visual appearance are not verified.
- **Weather is an architecture, not a simulation** — rain is a single capped CPU emitter (disabled on mobile); no precipitation physics, splashes, accumulation or snow.

---

## 5. Combat

### Pure engine

`CombatEngine` extends `RefCounted` and owns:

- Combatants and team assignment.
- Speed-sorted turn order.
- Round counter, current actor and turn advancement.
- Skill resolution, damage, healing, shields, status ticks and boss phases.
- An event stream consumed by the UI.

It has no `Node`, no `SceneTree`, no UI and no file access. `ContentDB` is the only autoload it reads, and that dependency is limited to skill definitions. Phase 2 passives and equipment resonance come from the `PassiveEffects` class (`class_name`, not an autoload) and `Combatant.equipment_element`, exposed through the public helpers `unit_speed`, `unit_defense`, `outgoing_multiplier` and `incoming_multiplier`.

### Event stream

`execute()` and `advance_turn()` return arrays of dictionaries such as:

```gdscript
{ "type": "action", "actor_name": "Mira Sol", "skill_name": "Shield Bash", ... }
{ "type": "damage", "target_name": "Mossling", "amount": 84, "crit": false, ... }
{ "type": "status", "target_name": "Mossling", "status": "burn", ... }
{ "type": "death", ... }
{ "type": "victory", ... }
```

`CombatScreen` only renders these events. It does not recalculate damage. That is the seam that lets a future server send validated events for the client to replay.

### Combatants

`Combatant` is pure data plus status math:

- HP, ATK, DEF, SPD, crit, energy, shield.
- Status list with `id`, `turns`, `potency`.
- Effective stat getters clamp buffs/debuffs.
- `take_damage()` applies shields first.
- `ultimate_ready()` gates ultimates on energy.

### Factory

`CombatFactory` is the only place that translates saved progression into combat stats:

- Character level, ascension, awakening and equipment.
- Collection bonus from unique ownership.
- Enemy level scaling from the group.
- Boss/elite flags and phases.

### AI

`CombatAI` scores candidate skills:

- Healing/shields gain value from missing ally HP.
- Damage values elemental advantage, estimated mitigation, target HP and finishing blows.
- Ultimates receive a large bonus when ready.
- Buffs avoid redundant statuses.

Both player and enemy units can use the same AI; the current combat screen lets the player choose, while “Auto” uses `CombatAI` for the party.

### Determinism

`CombatEngine.rng` is seeded in `setup()`. Tests run complete battles with fixed seeds. The client currently owns the RNG; Phase 12 moves the seed and action validation to the server.

---

## 6. Gacha and collection

`GachaService` is a pure static class:

```gdscript
var outcome := GachaService.pull(banner, rng, pity_state, count)
# → { "results": [...], "pity": {...} }
```

It reads only the banner dictionary, an RNG and pity state. It does not touch currency, inventory or nodes.

`GameState.pull_banner()` is the session facade:

1. Validate banner and count.
2. Spend the banner currency.
3. Call `GachaService.pull()`.
4. Grant ownership via `add_character()`.
5. Mark each roll as new / duplicate and record awakening gain.
6. Queue a save.

### Pity

Pity state per banner:

```json
{ "legendary": 0, "featured": 0, "epic_streak": 0 }
```

- `hard_pity` forces a legendary at the threshold.
- `featured_pity` forces the featured character when the rolled rarity matches.
- Ten-pulls can replace the last result with an Epic if no Epic+ was rolled.

### Duplicates

`add_character()` finds an existing instance by character ID:

- First copy creates an instance and auto-fills the party if there is room.
- Duplicates increment `dupes`; every second duplicate grants one awakening level up to 5.
- Duplicate copies do not create separate roster entries.

### Server migration

The pure service is intentionally reusable server-side. The server will own the RNG, banner state, pity counters and ownership grant. The client will send “pull banner X once” and receive a signed result, never a local roll.

---

## 7. Session state and save

`GameState` is the gameplay facade. UI and world code call it rather than mutating dictionaries directly.

Responsibilities:

- Profile and currencies.
- Roster and party (max 4).
- Inventory and equipment.
- Quest state, steps and progress.
- Pity counters.
- Flags.
- Player position.
- XP, level, ascension and collection bonus.
- Battle/quest reward application.
- Debounced and periodic saves.

`SaveService` writes plain JSON to `user://project_fantasy_save.json`:

- Writes to a `.tmp` file, then replaces the old file.
- Adds `version` and `saved_at`.
- Backs up a corrupt file and starts fresh.
- Warns when a save is from a newer version.

**This is not secure.** A player can edit the JSON. It exists so the offline slice can persist progress while the server boundary is designed. See `BACKEND.md`.

---

## 8. UI architecture

UI is built from code rather than hand-authored `.tscn` files. Reasons:

- Consistent responsive layout across 16:9 desktop and mobile.
- No scene-file merge conflicts.
- Easy to test by instantiating screens.
- Theme and spacing changes happen in one place.

### `UITheme`

Central palette, rarity colors, element colors, typography helpers and panel/button style boxes.

### `UIFactory`

Factory helpers:

- `vbox`, `hbox`, `grid`, `margin`, `spacer`, `separator`
- `label`, `heading`, `wrapped`, `chip`
- `button`, `small_button`, `panel`
- `set_full_rect`, `clear`, `number`

### `OverlayScreen`

Shared full-screen shell:

- Dimmed backdrop.
- Titled glass panel.
- Close button.
- Content `VBoxContainer`.
- `closed` signal, then `queue_free()`.

Subclasses implement `_build_content()` and `_refresh()`.

### HUD

Owns party portraits, currencies, area/day info, touch joystick and action buttons. Emits intent (`screen_requested`, `menu_requested`, `interact_requested`) instead of opening screens itself.

### CombatScreen

Owns battle presentation:

- Enemy and party unit cards.
- Turn order preview.
- Skill buttons with cost/energy state.
- Targeting mode.
- Log and floating result panel.
- Auto mode, speed toggle, retreat confirmation.
- Applies victory rewards through `GameState`, emits `closed`.

### Phase 5 character presentation (rarity effects, portrait seam, reports)

- **`UITheme` rarity effects.** `RARITY_EFFECTS` plus
  `rarity_effect()` / `is_premium_rarity()` / `rarity_glow()` /
  `rarity_tier_label()` give Legendary/Mythic a distinct glow, border, aura and
  frame. `UnitCard` draws a premium border for premium-rarity units.
- **`PortraitView` real-portrait seam.** `portrait_texture`,
  `set_portrait_texture()`, `portrait_report()` and
  `PortraitAssetSource.texture_for()` let a real validated portrait swap in.
  Because ZERO final portraits exist for the 12 collectible characters,
  `portrait_texture == null` for them and a GUARDED procedural fallback
  (`_draw()` bust) renders. Lilith is the exception: her 256x384
  `assets/characters/lilith/portrait.png` resolves through the same seam, so her
  fallback is inactive. A deterministic premium rarity aura + inner frame is
  drawn for Legendary/Mythic when `show_rarity_effect` is enabled.
- **Screen presentation reports.** `CollectionScreen.presentation_report()`,
  `GachaScreen.presentation_report()` and
  `CombatScreen.skill_presentation_report()` expose honest, testable snapshots.
  `CollectionScreen` adds premium card borders/tier labels, a `visual_theme` line
  from `CharacterArtSpec`, a premium flourish and a larger premium portrait;
  `GachaScreen` adds a rarity-tinted featured backdrop, a `visual_theme` line,
  premium result cards and a reveal scale-pop + "Best:" flourish;
  `CombatScreen` adds ultimate `GOLD_BRIGHT` styling, element tint, skill
  legibility and an ultimate name banner.
- **Honest caveat.** These are code-driven `_draw()` / tween / theme effects that
  are compile/build-safe and structurally asserted by tests, but **NO visual
  testing** was performed (headless dummy renderer); auras, borders, tints,
  silhouettes and tween pops were NOT visually inspected on screen. They imply
  NO real artwork.

### Input

Keyboard and gamepad actions are registered at runtime by `InputSetup`. Touch input is a shared autoload (`TouchInput`) plus `TouchJoystick`, so the HUD and player read the same vector without direct coupling.

---

## 9. Testing architecture

The test runner is a real scene (`tests/test_runner.tscn`) so autoloads exist exactly as they do in game.

Coverage:

- Content integrity and cross-references.
- Iso projection and chunk math.
- Gacha rates, pity, featured pity and ten-pull floor.
- Full deterministic battle to victory, event stream, element table, boss flags.
- GameState currencies, items, duplicates, party cap, quest flow, save round-trip.
- Instantiation of every overlay, title menu, combat screen and the full game scene.
- Phase 2 additions: passive multipliers, passive battle hooks, equipment bonuses/resonance, invalid JSON, duplicate keys, missing references, invalid banner configs, quest requirements, reward validation.
- Phase 3 additions — 8 new test groups: visual style (`GreenwardStyle` palettes/phases/`SPRITE_SPECS`/coherence), character animator (8×8 deterministic state machine, priority, one-shots, snapshots), actor frame source (`REPLACEMENT_SPEC` / `specs()` / fallback contract), procedural variety (47 kinds, deterministic variants, cached frames), chunk visual quality (river ribbon, `detail` layer, preserved `build()` keys), weather director (deterministic transitions, `params()`, mobile caps), animated/interactive props (motion, off-screen gating, non-destructive interact), and world visual integration (`visual_style_report()`, 5 locations, fog/lighting/particles).
- Phase 4 additions — 11 new test groups (404 checks): region definitions, region graph transitions, invalid connections, region save state, asset manifest, asset loading fallbacks, animation sheet validation, animation transitions, chunk preparer, world region integration, procedural art phase 4.
- Phase 5 additions — 9 new test groups (420 checks): character art pipeline (`CharacterArtPipeline` 10 kinds, 9×8 sheet contract, 72 animations, `validate_asset()`), character art specs (12 specs, identity vs `characters.json`, premium tier, prompts), character asset registry (disk-computed FINAL/TEMPORARY/MISSING, 120 entries), character portrait loading (`PortraitView` seam + fallback), sprite sheet registration (`register_character()` / 72 animations / `configure_character()`), missing asset fallbacks (procedural fallback stays active), gacha presentation (rarity effects + `presentation_report()`), world visual standards (6 categories, region tints, 57 props), and asset status honesty (ZERO final assets, both registries report FINAL 0).

The suite now reports **`1374 passed, 0 failed`** — 236 Phase 1 baseline + 111 Phase 2 checks + 203 Phase 3 checks + 404 Phase 4 checks + 420 Phase 5 checks. All 954 prior tests (236 + 111 + 203 + 404) are preserved; 347 (236 + 111), 550 (236 + 111 + 203) and 954 (236 + 111 + 203 + 404) are past checkpoints, not the current total. All 6 verification commands exit `0` (editor import, `tools/validate_content.gd` → `[validate] OK — 9 content files parsed and validated.`, the test suite, title smoke `--quit-after 180`, game smoke `--quit-after 240`, and `--export-pack "Linux/X11"` → a non-empty `.pck` smoke build), with ZERO errors/warnings/leaked RIDs. **NO visual testing** was performed (all headless with Godot's dummy renderer; `_draw()` output, auras, borders, tints, silhouettes and tween pops were NOT visually inspected). See `TESTING.md` for commands and the exact current total.

The runner snapshots both `GameState` and the raw save file, then restores them. This is why tests can call `new_game()` and `save_now()` without erasing a player’s journey.

See `TESTING.md` for commands and manual QA.

---

## 10. Performance notes

Current choices aimed at mobile:

- GL Compatibility renderer.
- MultiMesh terrain/water (one draw call per layer per chunk).
- 25-chunk ring at radius 2, not an open-world grid.
- Props are simple sprites, not 3D meshes.
- UI uses theme styles rather than per-widget textures.
- Pixel-snapped isometric math and nearest filtering for placeholder art.
- No per-frame allocation-heavy world queries; interactable scan is throttled by player physics.
- **Phase 3:** the `detail` ground-cover layer is batched into ONE extra `MultiMesh` draw call per chunk (child of `terrain`); procedural textures are cached with `(kind, variant)` keys and generated once, never per frame.
- **Phase 3:** prop/particle caps (`MAX_PROPS_PER_CHUNK = 48`, ~26 mobile; `MAX_PARTICLES = 300`; `DETAIL_DENSITY = 0.22`), off-screen `AnimatedProp` visibility/process gating, and fog/rain disabled on the mobile tier.
- **Phase 4:** `ChunkPreparer` adds bounded-LRU, main-thread FRAME-SLICED background preparation of at most ONE chunk per frame plus a bounded prefetch ring; prepared data is consumed by `_load_chunk` with a synchronous fallback. **NO THREADS** (Godot 4 `MultiMesh`/`Image`/`ShaderMaterial` + scene-tree operations are not thread-safe). A shutdown-leak fix brings headless smoke tests to ZERO leaked RIDs; one `MultiMesh` draw call per layer per chunk, capped props/particles, cached textures and off-screen gating are preserved. `ChunkStreamer` is unchanged.

Not yet done:

- Device profiling and frame-time budgets — **no device profiling has been performed**; the caps above are guidance from a coarse `OS.get_name()` hint, not measured frame times. Headless CI uses a dummy renderer, so full shader compilation on a real device is not exercised (shader compilation and visual appearance are not verified by the automated suite).
- True threaded chunk generation — Phase 4 added main-thread frame-sliced background preparation, but **NO threads**; threading is still future work.
- Texture atlases and sprite batching for props (real atlases replace procedural textures).
- Occlusion/culling beyond chunk ring.
- Object pooling for damage numbers and battle effects.
- Save compression or encryption.

---

## 11. Extension points

| Goal | Where to change |
| --- | --- |
| Add a character | `resources/data/characters.json`, add referenced skills |
| Add a skill | `resources/data/skills.json` |
| Add an enemy | `resources/data/enemies.json` |
| Add an encounter | `resources/data/enemy_groups.json`, reference from region spawns |
| Add a region | `resources/data/regions.json` (add a COMPLETE region def — every top-level key is validated as a region — plus `world_origin`/`environment`/`entry_points` and bidirectional `connections`) + `RegionGraph` validation (`validate_region_graph` BFS check); `GreenwardWorld._build_generic_region()` renders data-driven regions |
| Add a banner | `resources/data/banners.json` |
| Add a quest | `resources/data/quests.json`, hook steps in dialogue |
| Add an item | `resources/data/items.json` |
| Add a screen | Subclass `OverlayScreen`, register in `GameScreen.open_screen()` |
| Replace placeholder art | Keep `ProceduralArt` / `PortraitView` APIs, swap internals |
| Register real painted sprite sheets | Drop a real `world_sheet.tres` and call `ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>))` — no gameplay changes; specs/naming/import in `AssetManifest`, `assets/README.md`, `assets/ASSET_STATUS.md` |
| Register a real character sprite sheet (Phase 5) | `SpriteFramesActorSource.register_character(<id>)` / `from_disk()` → `ActorVisual.configure_character()`; 9 states × 8 directions = 72 animations; exact specs in `CharacterArtPipeline` (`assets/CHARACTER_ART_PIPELINE.md`) |
| Drop a real painted portrait (Phase 5) | `PortraitAssetSource.texture_for(<id>)` → `PortraitView.set_portrait_texture()`; the guarded procedural fallback stays; see `assets/ASSET_PRODUCTION_MANIFEST.md` |
| Author / promote a character art spec (Phase 5) | `CharacterArtSpec` (`assets/characters/<id>/SPEC.md`, `assets/CHARACTER_SPECS.md`, `assets/GENERATION_PROMPTS.md`); identity verbatim from `characters.json`, gameplay data unchanged; mark FINAL only when a real file exists AND `CharacterAssetRegistry.validate_finished_asset()` returns `[]` — FINAL is NEVER hardcoded |
| Add / tune weather | `WeatherDirector` states, `TRANSITIONS`, `STATE_INTENSITY`, `params()`; `GreenwardWorld` applies them to fog/particles/lights |
| Move gacha to server | Replace `GameState.pull_banner()` with an RPC; keep `GachaService` as reference implementation |
| Move combat to server | Send actions to server; replay returned events in `CombatScreen` |

---

## 12. Known architectural debt

- `ContentDB` is a global singleton; server-side reuse of pure classes still requires a content provider injection.
- `GameState` is a large facade. It is appropriate for a slice but should be split into `InventoryService`, `QuestService`, `ProgressionService` before online launch.
- `GameScreen` owns too many UI concerns; a screen router would be cleaner once there are more than a handful of menus.
- Some UI text is embedded in scripts; Phase 15 moves it to localization keys.
- Enemy definitions are dictionaries while characters are typed; unify if enemy behaviour grows.
- No event schema versioning yet. Add a version field before network event replay.
- Local save has no migration chain beyond the version field.
- **Lilith is the ONE final playable character; the 12 collectibles are still FINAL 0, and there is no audio.** `AssetManifest.status_report()` is **FINAL 0 / TEMPORARY 8 / MISSING 8** and `CharacterAssetRegistry.report()` is **FINAL 0 / TEMPORARY 120 / MISSING 120** (12 characters × 10 kinds; `check_disk()` false for all 120). Those registries intentionally track only the 12 collectibles; Lilith's final art (`assets/characters/lilith/`: 72 world animations, portrait, combat sprite, full-body illustration) is tracked separately via `MainCharacterRoster.world_art_ready()` / `asset_status()`. Every other character is runtime procedural placeholder; the demo sheet is a TEMPORARY in-memory procedural `SpriteFrames` (`DemoCharacterFrames`, `loaded_from_disk == false`), not final art. The 12 `CharacterArtSpec` specs + `assets/GENERATION_PROMPTS.md` are **preparation for future external art, not finished artwork**. Real art plugs in via `SpriteFramesActorSource.from_disk()` / `register_character()` / `ActorVisual.configure_character()` / `PortraitAssetSource`, and FINAL is NEVER hardcoded.
- **NO visual testing was performed.** All verification is `--headless` with Godot's dummy renderer: `_draw()` output, auras, borders, tints, silhouettes and tween pops are compile/build-safe and structurally asserted but were NOT visually inspected on screen; no shader compilation / appearance verification and no device profiling.
- **Only TWO regions.** `greenward`'s village/NPC/landmark layout is partly hardcoded (the second region is data-driven); there are no elevation/cliffs/water traversal rules, no fast-travel/map/fog-of-war, no mounts, no spawn directors/respawn timers and no world audio ambience. Region transitions are validated and wired but not interactively playtestable headlessly.
- **No server authority.** Gacha, currency, inventory, rewards and the local JSON save are client-side NON-AUTHORITATIVE until Phase 12; `BACKEND.md` and `backend/schemas/schema.sql` are design recommendations only. No multiplayer, backend, accounts, trading or PvP.
- **CI** (`.github/workflows/ci.yml`) is configured and locally verified but has **NOT** been executed on GitHub Actions; the project is not a git repo and all changes are local uncommitted files.
- No device profiling; mobile budgets are a coarse `OS.get_name()` hint, not measured frame times.
- `WeatherDirector` is an architecture, not a simulation (rain is a single capped emitter, disabled on mobile).

These are deliberate slice trade-offs, documented rather than hidden.
