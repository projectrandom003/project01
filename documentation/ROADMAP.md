# Roadmap

A 20-phase path from the playable offline slice to a live, server-authoritative anime-fantasy MMORPG.

Status legend: **Complete** · **Next** · **Planned** · **Post-launch**

> The ordering is deliberate: prove the core loop offline, harden content and tools, then build social/online features only after the authoritative backend exists. Do not ship client-authoritative gacha, currency, trading or PvP at any phase.

---

## Phase 1 — Foundation and vertical slice · **Complete**

**Goal:** a runnable, testable Greenward slice.

Delivered:

- Godot 4.7 project, GL Compatibility renderer, responsive 16:9.
- Data-driven content: 12 characters, 36 skills, 6 enemies, 5 enemy groups, 14 items, 2 banners, 2 quests, 3 dialogues, 1 region.
- Streamed isometric world with 16×16 chunks, radius 2, MultiMesh terrain/water, props, village, NPCs, roaming monsters, day/night.
- Player controller with keyboard, gamepad and touch input.
- Dialogue, quests, turn-based combat, gacha, collection, inventory, pause, title screen.
- Local versioned JSON save with autosave and corruption backup.
- 236 headless assertions; full game-scene smoke test.
- Architecture, roadmap, backend, art, testing and content docs.

Exit criteria met:

- `godot --headless --path . res://tests/test_runner.tscn` passes.
- The title scene and game scene load headless without runtime errors.
- A new player can walk, talk, accept a quest, fight, win rewards, summon, equip and save.

Known slice limits are listed in `README.md` and `ARCHITECTURE.md`.

---

## Phase 2 — Content pipeline and validation tools · **Complete**

**Goal:** make content authoring safe and fast before adding volume.

Shipped (implemented and locally verified):

- [x] Strict JSON validation via `scripts/core/content_validator.gd` (`ContentValidator`) across all 9 content files — required fields, types, enum values, duplicate IDs/keys, cross-file references (skills, items, enemies, enemy groups, characters, banners, quests, dialogue, regions), invalid rarity values, and missing skills/items or invalid reward references. Errors are `file → path: message`.
- [x] The same validator runs in `ContentDB` at boot, so the game and CI cannot disagree.
- [x] `tools/validate_content.gd` CI entry point (`godot --headless --path . --script res://tools/validate_content.gd`): `[validate] OK — 9 content files parsed and validated.` and exit `0` on success, `1` on failure.
- [x] Mechanical character passives: `passive: { "id", "name", "text" }` with 12 supported ids, applied in `CombatEngine` via `unit_speed` / `unit_defense` / `outgoing_multiplier` / `incoming_multiplier`, plus battle-start energy, a one-time heal energy refund, burn-on-crit, shield-on-heal and lifesteal. *Honest caveat:* `dawnkeeper` is a one-time 20-energy refund on the first healing skill each battle, because the combat model has no skill energy cost.
- [x] Equipment `element` resonance: the first elemental equipped item (weapon first) sets the resonance element; a matching skill deals +8% (`EQUIPMENT_RESONANCE`) plus an extra +4% (`EQUIPMENT_ATTUNEMENT`) when it also matches the wielder's own element. Other stats remain additive.
- [x] Quest `requires` enforced by `GameState.start_quest()`.
- [x] Reward payloads may name wallet currencies; `GameState.grant_reward_items()` routes `currency` entries to `add_currency()` and other items to `add_item()`.
- [x] `.github/workflows/ci.yml`: a GitHub Actions pipeline (Godot **4.7.2** Linux headless/editor) that imports, validates content, runs the automated test suite, runs a game-scene smoke test, and performs an `--export-pack "Linux/X11"` smoke build via `export_presets.cfg`, uploading the `.pck` as an artifact.
- [x] The 236-test Phase 1 baseline is preserved; Phase 2 adds coverage on top. See `TESTING.md` for the exact current total.

**Verified locally:** the full automated test suite, the `tools/validate_content.gd` validator, the headless game-scene smoke test, and the `--export-pack` smoke build. **Honest caveat:** the GitHub Actions workflow itself is configured but has **not** yet been executed on GitHub — configured and locally verified only.

**Still belongs to later phases (not Phase 2 gaps):** server-authoritative state and accounts (Phase 12), trading, marketplace and PvP (Phases 9 and 13), real production art/audio replacing procedural placeholders, multiplayer, and any playable regions beyond the two shipped by the end of Phase 4 (a second region was later added in Phase 4 — see the Phase 4 section). Standalone JSON schema files, editor hot-reload, a seed-based world preview and an automated content report were part of the original Phase 2 wish list but were not shipped and remain future tooling work.

**Exit:** a designer can add a character, banner and encounter without touching GDScript, and CI rejects broken references.

> **Phase 5 is verified; Phase 6 progression work is now in progress.** Phase 2 is signed off locally (test suite, validator, smoke tests, export pack); Phases 3, 4 and 5 are complete. Phase 6 currently has persistent gathering rewards and encounter bonus-drop routing; its full equipment/crafting and long-term progression scope remains unfinished. The GitHub Actions pipeline is configured but has not yet been executed on GitHub.

---

## Phase 3 — Visual world and player presentation · **Complete**

**Goal:** make the single playable region (Greenward) look and feel like a coherent
anime-fantasy world, and give the player character a real animation architecture —
**not** to add regions. This phase was explicitly re-scoped to visual quality per
the Phase 3 directive ("Do not start additional continents").

Shipped (implemented and verified locally):

- [x] **Art direction / single source of truth:** `documentation/VISUAL_STYLE.md` (CANONICAL visual style guide) and `scripts/world/visual_style.gd` (`GreenwardStyle`) — grouped palettes (SKY/CANOPY/UNDERGROWTH/WATER/STONE/TIMBER/MAGIC/LIGHT/ACCENTS/UI/ELEMENTS), `phase(name)` lighting/fog presets (Dawn, Day, Golden Hour, Dusk, Nightfall, Midnight + Morning/Noon/Afternoon), `prop_palette(kind)`, `element_color()`, `prop_kinds()`, `variant_count()`, `SPRITE_SPECS`, `all_colors()`, `coherence_report()`, `performance_tier()` and the performance caps.
- [x] **47 prop kinds + deterministic variants:** `ProceduralArt.prop_texture(kind, variant)` — 12 original + 35 new (5 tree varieties, ground cover, structures, magical, water, ambient wildlife), each with visually distinct deterministic `variant`s; `prop_kinds()` / `variant_count()`; `clear_cache()`.
- [x] **Detailed environment:** `ChunkBuilder` richer terrain (moisture+elevation blend, beach band, shoreline foam, varied paths), a meandering noise-derived RIVER ribbon, and a NEW `detail` `MultiMesh` ground-cover layer (ONE extra draw call per chunk, child of `terrain`); improved `water.gdshader` (reflections/glints/shore foam/depth) and `wind_sway.gdshader` (secondary shimmer, per-instance phase); new `fog.gdshader` and `detail.gdshader`. The `build()` signature and `coord/terrain/water/props` keys are preserved.
- [x] **Buildings, ruins, bridges, waterfalls and 5 visually distinct locations:** `GreenwardWorld` wires a richer village (huts/cottages/well/shrine/wisp lanterns), a decorative river with waterfalls and wooden + stone bridges, the Listening Stones ruins, the Hollowed Grove (distinct corrupted palette), and the NEW Moonpetal Shrine glade, plus ambient wildlife and non-destructive `InteractiveProp`s.
- [x] **Lighting, day/night, fog and weather architecture:** `DayNight` tint sourced from `GreenwardStyle.phase()`, an atmospheric `fog.gdshader` quad layered below the HUD, phase-driven lighting, and `WeatherDirector` (CLEAR/MIST/RAIN/POLLEN_BLOOM) with deterministic transitions, intensity ramp, `params()` and mobile caps. *Honest:* weather is an architecture, not a simulation — rain is one lightweight capped CPU emitter (disabled on mobile), no precipitation physics/splashes/accumulation/snow.
- [x] **Particles and ambient life:** phase-driven pollen motes, fireflies, ambient wildlife (butterflies/moths/birds), `AnimatedProp` (bob/sway/pulse/flicker/drift with off-screen gating) and drifting `MainBackdrop` motes aligned to the shared palette.
- [x] **Player animation architecture:** `CharacterAnimator` (pure `RefCounted` 8 states × 8 directions — IDLE/WALK/RUN/INTERACT/ATTACK/DAMAGE/VICTORY/DEFEAT × DOWN … DOWN_LEFT — with priority, looping vs one-shot, tick/frame timing, snapshot/from_snapshot), `ActorFrameSource` (STABLE sprite interface with the EXACT final-art `REPLACEMENT_SPEC` / `specs()`), `ProceduralActorFrames` and `ProceduralArt.character_frame()` (clearly-marked TEMPORARY placeholder frames), and the `ActorVisual.set_frame_source()` seam. "Directional movement" is the DIRECTION axis, **not** a 9th state. `Player`, `WorldNPC` and `RoamingMonster` drive 8-direction WALK/RUN/IDLE, interaction, role subtitles, interaction rings, gentle idle, per-spawn palette/size/silhouette variety and roaming/alert animation.
- [x] **Performance caps with preserved streaming:** still ONE `MultiMesh` draw call per terrain/water/detail layer per chunk; no per-tile sprites; `MAX_PROPS_PER_CHUNK = 48` (~26 mobile), `MAX_PARTICLES = 300`, `DETAIL_DENSITY = 0.22`, cached textures, off-screen animated-prop gating, fog/rain disabled on mobile. Chunk streaming, `_update_streaming` diffing, `IsoMath` / `ChunkStreamer` behaviour preserved. *Honest:* `performance_tier()` is a coarse `OS.get_name()` hint — no device profiling; headless uses a dummy renderer.
- [x] **550-test suite:** 8 new Phase 3 test groups (203 checks) — visual style, character animator, actor frame source, procedural variety, chunk visual quality, weather director, animated/interactive props, world visual integration — on top of the preserved 236 Phase 1 + 111 Phase 2 checks. `550 passed, 0 failed`.

**Verified locally:** all 6 verification commands exit `0` (editor import, `tools/validate_content.gd` → `[validate] OK — 9 content files parsed and validated.`, the test suite → `550 passed, 0 failed`, title smoke `--quit-after 180`, game smoke `--quit-after 240`, and `--export-pack "Linux/X11"` → a non-empty `.pck` smoke build). No exact byte size is documented here; the smoke build is verified by the non-empty `.pck` it produces. **Honest caveats:** the GitHub Actions workflow in `.github/workflows/ci.yml` is configured and locally verified but has **NOT** been executed on GitHub Actions; **no device profiling** was performed (headless uses a dummy renderer). Content is unchanged (12 characters, 36 skills, 6 enemies, 14 items, 2 banners, 2 quests, 3 dialogue scenes, 1 playable region — Greenward). All shipped art is **procedural placeholder** (zero final assets); no audio exists.

> **Re-scope note.** The ORIGINAL Phase 3 "world expansion / additional regions / traversal" goal ("more than one place worth exploring") was **NOT implemented by design** — the Phase 3 directive explicitly re-scoped the phase to visual world and player presentation and said "Do not start additional continents." The following items are therefore **DEFERRED to later phases**, not shipped: a region graph and seamless/gate-based transitions, additional regions/continents with distinct biomes, threaded/cached chunk generation, height/elevation variation + cliffs + water traversal rules, fast-travel waypoints / map screen / fog-of-war, mounts or traversal abilities, interactable variety expansion (chests, gathering nodes, destructibles), spawn directors with respawn timers/population caps, and world audio ambience hooks. See the "Deferred from Phase 3" note under Phase 4. Only Greenward is playable; NO new regions were added.

**Exit:** a coherent, readable, performant visual world and a testable character-animation architecture over the preserved Greenward slice; `550 passed, 0 failed` and a clean `--export-pack "Linux/X11"` smoke build.

---

## Phase 4 — World expansion, real art pipeline and character animation · **Complete**

**Goal:** expand the world to a small two-region graph, define a REAL art asset pipeline (with an honest placeholder-only status), and extend character animation — **not** the narrative/quest/dialogue framework the original Phase 4 heading described (see the **Re-scope note** below).

Shipped (implemented and verified locally):

- [x] **Part 1 — Real art asset pipeline:** `scripts/art/asset_manifest.gd` (`AssetManifest`: 8 asset classes with exact dimensions, transparent RGBA8, anchors, animation frame layouts, import settings, naming and replacement seams; `status_report()`, `check_disk()`, `validate_sheet_specs()`, `replacement_seams()`), `scripts/art/sprite_frames_actor_source.gd` (`SpriteFramesActorSource`: production `SpriteFrames`-based source with `from_disk()`, `validate_sheets()`, graceful missing-asset fallback), `scripts/art/demo_character_frames.gd` (`DemoCharacterFrames`: ONE fully integrated, clearly-marked TEMPORARY in-memory procedural demonstration character wired to the player, all 9 states × 8 directions), plus `assets/README.md` (workflow) and `assets/ASSET_STATUS.md` (exact status table). Eight classes: character sprites 96×128 (8-frame sheets, bottom-centre), portraits 256×384, environment tilesets 512×512, buildings 256×256, vegetation 128×160, monster sprites 96×128 (boss 128×192), skill effects 192×192 (6 frames), UI illustrations 640×360. Import: Linear filter, mipmaps on for world art, VRAM compression where supported (lossless for UI), Fix Alpha Border on atlases; `lower_snake_case`, content-id folders. **NO final artwork was fabricated from polygons and labelled finished.**
- [x] **Part 2 — Character animation (additive CAST):** `CharacterAnimator` gained an ADDITIVE 9th state `CAST = 8` while keeping `ALL_STATES` at 8 and all Phase-3 timing arrays unchanged (separate `CAST_STATE/CAST_FRAMES=7/CAST_FPS=12/CAST_LOOPING/CAST_PRIORITY`, `EXTENDED_STATES` 9, `EXTENDED_STATE_NAMES`, `LOCOMOTION_STATES`, `RETURN_STATES`, `frame_count_for/fps_for/looping_for/priority_for`, `transition_to`, `can_transition`, `finish_and_return`, `play_cast`, `cast_active`, `previous_state`, `transitioned` signal). `ActorFrameSource` gained `cast_frame/cast_frame_count/cast_fps/validate_sheets/extended_specs`; `ProceduralActorFrames` implements them; `ProceduralArt.character_frame` supports state 8 with a distinct CAST pose; `GreenwardStyle.CAST_SPEC`; `ActorVisual.play_cast()` + CAST aura; 8-direction idle/walk/run + attack/cast/damage/victory/defeat/interaction. Sprite-sheet support via `SpriteFramesActorSource` with animation names `<state>_<dir>` and `cast_<dir>`. ONE demonstration character wired into the player.
- [x] **Part 3 — World expansion (exactly TWO regions):** `resources/data/regions.json` now has TWO regions — `greenward` + `moonpetal_hollow` (a small silver-birch moonlit vale). NO additional continents. Each region has `world_origin` (logical world coordinates), `environment` (zone, weather_bias, fog_density, ambient_tint, ambient_music), `entry_points` and `connections` (id/to/via/entry/kind/label). `scripts/world/region_graph.gd` (`RegionGraph`: region_ids/has_region/definition/region_name/entry_points/entry_grid/connections_from/connection/can_travel/resolve_transition/world_origin/local_to_world_position/world_to_local_position/world_position_of_grid/region_at_world_position/spawn_grid/spawns/environment/load_radius/validate/summary/static validate_definitions). `ContentValidator` extended: `PROP_TYPES` now all 53 kinds, strict checks for the new optional region fields + connections (missing target region, self-loop, dangling via/entry, duplicate ids, invalid kind/label, bad world_origin/environment/entry_points), plus `static validate_region_graph(regions)` (BFS unreachable-region check). `EventBus.region_change_requested(target_region_id, entry_point)`; `scripts/world/region_portal.gd` (interactable gate). `GameScreen` rebuilds the world on a validated region change and saves per-region position; `GameState` gained `player_region`, `region_positions`, `set_player_region`, `set_region_position`, `region_position`, `has_region_position` and TWO new save keys (`region`, `region_positions`), fully backwards compatible (old saves load with greenward). `GreenwardWorld` is region-parameterized (`region_id`, `entry_point`), keeps ALL Greenward-specific builders for greenward, and adds a data-driven `_build_generic_region()` + portals for other regions. `ChunkStreamer`/`IsoMath` UNCHANGED; streaming compatibility preserved (each region keeps its own local grid↔world projection; world_origin is a logical map/travel space). Bidirectional connection.
- [x] **Part 4 — Environment quality:** 6 NEW detailed prop kinds (`watchtower`, `market_stall`, `stone_wall`, `gazebo`, `banner_post`, `moon_shrine`) with distinct variants → `ProceduralArt.prop_kinds()` now 53; 4 placed at Greenward landmarks. More recognisable landmarks, better paths (per-instance cobble colour + width variation in `ChunkBuilder`), forest variation biased by elevation/moisture, rivers/waterfalls, ruins, interactive locations, and distinct environmental zones (`GreenwardWorld.current_zone()`). Region-specific fog density, ambient tint and weather bias applied to atmosphere. `moonpetal_hollow` has its own cooler violet/silver biome, noise_seed 24601, load_radius 1, 2 pois, 2 spawns and one gate back to Greenward.
- [x] **Part 5 — Performance (NO threads):** `scripts/world/chunk_preparer.gd` (`ChunkPreparer`: pure, bounded LRU, frame-sliced background preparation of at most ONE chunk per frame, prefetch of a bounded ring outside the loaded ring, prepared data used by `_load_chunk` when ready with synchronous fallback). **NO THREADS** — `MultiMesh`/`Image`/`ShaderMaterial` and scene-tree operations are not thread-safe in Godot 4. `ChunkStreamer` preserved unchanged. One MultiMesh draw call per terrain/water/detail layer per chunk, capped props/particles, cached textures, off-screen gating, fog/rain disabled on mobile. Also fixed a headless shutdown-leak regression (a self-referencing static method forming a GDScript reference cycle + static caches pinning RIDs) so the smoke tests now report **ZERO leaked RIDs**.
- [x] **Part 6 — Testing:** 11 new Phase 4 test groups (404 checks): region definitions, region graph transitions, invalid connections, region save state, asset manifest, asset loading fallbacks, animation sheet validation, animation transitions, chunk preparer, world region integration, procedural art phase 4. All 550 prior tests preserved. **954-test suite: `954 passed, 0 failed`** (236 Phase 1 + 111 Phase 2 + 203 Phase 3 + 404 Phase 4). Content unchanged: 12 characters, 36 skills, 6 enemies, 14 items, 2 banners, 2 quests, 3 dialogue scenes. **ZERO final assets** (FINAL 0 / TEMPORARY 8 / MISSING 8), **no audio**, exactly TWO regions.

**Verified locally:** all 6 verification commands exit `0` (editor import, `tools/validate_content.gd` → `[validate] OK — 9 content files parsed and validated.`, the test suite → `954 passed, 0 failed`, title smoke `--quit-after 180`, game smoke `--quit-after 240`, and `--export-pack "Linux/X11"` → a non-empty `.pck` smoke build), with **ZERO errors/warnings/leaked RIDs** after the Phase 4 shutdown-leak fix. No exact byte size is documented here; the smoke build is verified by the non-empty `.pck` it produces. **Honest caveats:** GitHub Actions has **NOT** been executed (`.github/workflows/ci.yml` is configured and locally verified only); **no device profiling** was performed (headless uses a dummy renderer, so shader compilation and visual appearance are not verified); **ZERO final assets** (all shipped art is runtime procedural placeholder, no audio); **no threads**; only TWO regions; region transitions are validated and wired but cannot be interactively playtested headlessly.

> **Re-scope note.** The ORIGINAL Phase 4 heading ("Narrative, quests and dialogue systems") was **NOT implemented by design**. The Phase 4 DIRECTIVE re-scoped this phase to **world expansion, real art pipeline and character animation**; the narrative work below is **DEFERRED to later phases** (see the "Deferred from Phase 4" note under Phase 5): a dialogue graph format with branches/conditions/flags/voiced-line hooks; quest types (talk, kill, collect, visit, escort, defend, craft, daily, weekly), quest chains, prerequisites, auto-start and abandonment rules; a cutscene/camera sequence tool; codex, character stories and bond episodes; localization-ready string keys for every line; and narrative QA (unreachable-branch and missing-key detection). None of these were shipped in Phase 4.

> **Deferred from Phase 3 (partially shipped in Phase 4).** The world-expansion items dropped by the Phase 3 re-scope are now **PARTIALLY SHIPPED** in Phase 4: a region graph and gate-based transitions, a second region with a distinct biome, logical world coordinates and connections, region-specific spawns and environment, streaming compatibility, and bounded background chunk preparation. **STILL FUTURE WORK:** true threaded generation, elevation/cliffs and water traversal rules, fast-travel waypoints + map screen + fog-of-war, mounts/traversal abilities, interactable variety expansion (chests, gathering nodes, destructibles), spawn directors with respawn timers/population caps, and world audio ambience. Exactly TWO regions exist; there are no six empty continents, no seamless zone streaming, and no fast-travel/map/fog-of-war.

**Exit:** a validated two-region world with per-region saves, a real (honest, placeholder-only) art asset pipeline, an additive CAST animation extension, a bounded main-thread chunk preparer and a `954 passed, 0 failed` suite — with **ZERO final assets**.

---

## Phase 5 — Character art and visual production · **Complete**

**Goal:** define and wire a complete *production* character-art pipeline and a coherent anime-fantasy visual presentation, with an honest placeholder-only status — **not** the combat depth the original Phase 5 heading described (see the **Re-scope note** below). This phase ships *specifications and preparation for future external art*, **not finished artwork**.

Shipped (implemented and verified locally):

- [x] **Part 1 — Character art pipeline.** `scripts/art/character_art_pipeline.gd` (`CharacterArtPipeline`): TEN asset kinds with exact dimensions, anchors, transparent RGBA8, frame layout, import settings, `lower_snake_case` naming and replacement seams — `full_body_illustration` 1024×2048, `character_portrait` 1024×1280 master → 256×384 export, `combat_sprite` 128×192, the five 96×128 sprite sheets (`movement_sheet`, `attack_sheet`, `cast_sheet`, `victory_sheet`, `defeat_sheet`, 8 direction rows × per-state columns), and `skill_vfx` / `ultimate_vfx` 192×192 / 6 frames. `sheet_layout()` (9 states × 8 directions), `animation_names()` (72), `validate_asset()`, `import_settings()`, `replacement_seams()`. `assets/CHARACTER_ART_PIPELINE.md`.
- [x] **Part 2 — First 12 character specs.** `scripts/art/character_art_spec.gd` (`CharacterArtSpec`): ONE authored spec per id (`lyra_vey`, `bramble`, `seraphine`, `nyx`, `coralyn`, `ignis`, `mira_sol`, `thistle`, `vespera`, `arachnia`, `terra`, `kael`) with name/id, race, element, rarity, role, physical appearance, hair style/colour, outfit, accessories, weapon, personality, visual theme, animation/portrait requirements and detailed generation prompts. Identity fields are verbatim from `characters.json` (1 mythic `ignis`; 3 legendary `seraphine` / `nyx` / `terra`; 4 epic; 3 rare; 1 common); Legendary/Mythic carry a distinct premium visual tier. **Gameplay data unchanged.** `assets/CHARACTER_SPECS.md` + 12 × `assets/characters/<id>/SPEC.md`.
- [x] **Part 3 — Character presentation.** `UITheme.RARITY_EFFECTS` + `rarity_effect` / `is_premium_rarity` / `rarity_glow` / `rarity_tier_label` (distinct Legendary/Mythic glow/border/aura/frame). `PortraitView` gained a real-portrait seam (`portrait_texture`, `set_portrait_texture`, `portrait_report`) via `PortraitAssetSource`, a guarded procedural fallback and a deterministic premium rarity aura + inner frame. `CollectionScreen` premium card borders/tier labels, `visual_theme` line, premium flourish, larger premium portrait, `presentation_report()`. `GachaScreen` rarity-tinted featured backdrop, `visual_theme` line, premium result cards, reveal scale-pop + "Best:" flourish, `presentation_report()`. `CombatScreen` ultimate `GOLD_BRIGHT` styling, element tint, skill legibility, ultimate name banner, `skill_presentation_report()`. `UnitCard` premium border.
- [x] **Part 4 — Sprite integration.** `SpriteFramesActorSource` gained `register_character()`, `validation_report()`, `animation_names()`, `registration_report()`; all 9 states (8 core + additive CAST) × 8 directions = 72 animations. `ActorVisual.configure_character()` / `character_art_report()`; `WorldNPC` / `RoamingMonster` call it. `ProceduralActorFrames` REMAINS the fallback (no real sheets exist). The Phase-4 `from_disk()` leak fix is preserved (ZERO leaked RIDs); the player demo wiring is untouched (`using_temporary_art == true`).
- [x] **Part 5 — World presentation.** `scripts/world/world_visual_standards.gd` (`WorldVisualStandards`): 6 categories (player / npc / monster / building / vegetation / environment_object) with canvas, anchor, outline, palette group, z-index, batching and fallback; `region_tint()` emerald vs silver-violet; `validate()`. `GreenwardWorld.apply_visual_standards()` / `visual_standards_report()` + 4 new `visual_style_report()` keys. Distinct bounded Moonpetal Hollow silver-birch/moonlit composition and a Greenward village-gate composition. 4 NEW prop kinds (`birch_grove`, `moon_lantern`, `stone_path`, `village_gate`) with distinct variants → **57 prop kinds** total; `GreenwardStyle.coherence_report() == []`; `ContentValidator.PROP_TYPES` 57.
- [x] **Part 6 — Asset management.** `scripts/art/character_asset_registry.gd` (`CharacterAssetRegistry`: disk-computed status, `validate_finished_asset()`, `report()`, `production_manifest()`, `replacement_seams()`), `scripts/art/portrait_asset_source.gd` (`PortraitAssetSource`: null-safe texture lookup), `assets/ASSET_PRODUCTION_MANIFEST.md` (FINAL only if a real file exists AND validates; never hardcode FINAL), `assets/GENERATION_PROMPTS.md` (global style anchor + 12 per-character prompts + exact output specs for FUTURE external generation), `assets/CHARACTER_SPECS.md`.
- [x] **Part 7 — Testing.** 9 new Phase 5 test groups (420 checks): character art pipeline, character art specs, character asset registry, character portrait loading, sprite sheet registration, missing asset fallbacks, gacha presentation, world visual standards, asset status honesty. All 954 prior tests are preserved → **`1374 passed, 0 failed`** (236 + 111 + 203 + 404 + 420).
- [x] **Part 8 — Documentation.** `ROADMAP.md`, `ARCHITECTURE.md`, `ART_PIPELINE.md`, `VISUAL_STYLE.md`, `CONTENT_GUIDE.md`, `TESTING.md` and `README.md` updated to the Phase 5 verified state.

**Verified locally:** all 6 verification commands exit `0` (editor import, `tools/validate_content.gd` → `[validate] OK — 9 content files parsed and validated.`, the test suite → `1374 passed, 0 failed`, title smoke `--quit-after 180`, game smoke `--quit-after 240`, and `--export-pack "Linux/X11"` → a non-empty `.pck` smoke build), with **ZERO errors/warnings/leaked RIDs**. No exact byte size is documented here; the smoke build is verified by the non-empty `.pck` it produces. Content unchanged: 12 characters, 36 skills, 6 enemies, 14 items, 2 banners, 2 quests, 3 dialogue scenes, exactly TWO regions. **Honest caveats:** **ZERO final assets** (`AssetManifest.status_report()` = FINAL 0 / TEMPORARY 8 / MISSING 8 and `CharacterAssetRegistry.report()` = FINAL 0 / TEMPORARY 120 / MISSING 120 — see the exact status in `ART_PIPELINE.md` §15 / `README.md`); all shipped art is runtime procedural placeholder and the 12 specs + prompts are PREPARATION for future external art; **NO visual testing** was performed (all verification is `--headless` with Godot's dummy renderer — `_draw()` output, auras, borders, tints, silhouettes and tween pops are compile/build-safe and structurally asserted but were NOT visually inspected on screen; no shader compilation / appearance verification, no device profiling); **no audio**; no threads; only TWO regions; GitHub Actions has **NOT** been executed (CI configured and locally verified only); no multiplayer/backend/server authority (client-side gacha/currency/inventory/rewards and local JSON save are NON-AUTHORITATIVE until Phase 12).

**Exit:** a complete, honest character-art production pipeline and coherent presentation over the preserved two-region slice — `1374 passed, 0 failed`, a clean `--export-pack "Linux/X11"` smoke build, and **ZERO final assets** (all art procedural placeholder).

> **Re-scope note.** The ORIGINAL Phase 5 goal ("Combat depth and encounter design") was **NOT implemented by design** — the Phase 5 DIRECTIVE re-scoped this phase to **character art and visual production**. Those combat items are **DEFERRED to later phases**, not shipped: more skill kinds (multi-hit, execute, counter, taunt, dispel, reflect, cleanse, revive); status stacking rules, immunity windows and resistance stats; enemy telegraphs, interrupt windows and break gauges; boss phase scripting and add waves; encounter modifiers (weather, terrain, elemental zones); battle speed, skip animations, auto-repeat and offline sweep for farmed content; damage-formula tuning with a simulation harness; and a battle replay format shared with the future server. The Phase-4-deferred narrative items also **REMAIN deferred** (dialogue graph with branches/conditions/flags/voiced-line hooks; quest types/chains/prerequisites; cutscene/camera sequence tool; codex, character stories and bond episodes; localization-ready string keys; narrative QA). See the "Deferred from Phase 5" note under Phase 6.

> **Deferred from Phase 4.** The original Phase 4 narrative/quest/dialogue scope was **NOT implemented by design** (see the Phase 4 "Re-scope note"). The following items are DEFERRED to later phases, **not shipped**: a dialogue graph format with branches, conditions, flags and voiced-line hooks; quest types (talk, kill, collect, visit, escort, defend, craft, daily, weekly), quest chains, prerequisites, auto-start and abandonment rules; a cutscene/camera sequence tool; codex, character stories and bond episodes; localization-ready string keys for every line; and narrative QA (unreachable-branch and missing-key detection). Phase 5 did not implement these either — it is now **Complete** and verified locally, and is NOT "Planned" or gated behind Phase 4 verification.

---

## Phase 6 — Progression, equipment and crafting · **In progress**

**Goal:** long-term character growth without pay-to-win.

Implemented in this phase so far:
- [x] Persistent Greenward gathering nodes grant materials once; claimed state is stored in the existing save flags and remains collected after world recreation.
- [x] Encounter bonus-drop tables support chance and amount ranges; the victory preview and claim share the same precomputed reward payload.

Implemented in the current progression pass:
- [x] Weapon, armor and accessory slots remain functional with stat comparison before equipping.
- [x] Gear enhancement to +5; each level increases that item's stat bonuses by 8%, with per-character/per-slot save data.
- [x] Enhancement consumes Gold and Glade Sap; equipped gear remains visible in inventory for management.
- [x] Species-specific procedural combat silhouettes for Mossling and Moonpetal Sprite, plus subtle elemental ground sigils for enemies and larger boss sigils.
- [x] Enemy action telegraphs: chosen enemy skill announced before execution, enemy intent label shown, threatened party highlighted during a reaction window.
- [x] Two additional one-time Greenward gathering locations: Shrine Wisp (Moonpetal) and Grove Shard (Glade Sap).

Still to build:
- Set bonuses and stat rerolling.
- Crafting recipes, crafting UI and material conversion.
- Talent trees or skill nodes per character.
- Character ascension/awakening content beyond the slice.
- Account-level progression and collection milestones.
- Resource sinks and catch-up mechanics.
- Economy simulation and faucet/sink dashboards.

**Current verification:** `1484 passed, 0 failed`; focused boss, avatar, arena,
map, menu, opening, quest and turn-timeline verifiers pass; content validation
passes; the Linux/X11 export pack builds successfully (31.5 MB). This confirms
headless build/runtime safety, not rendered visual quality or device frame rate.

**Exit:** a 30-day progression curve is modeled, tested and does not require gacha to progress the main story.

> **Deferred from Phase 5.** The original Phase 5 "Combat depth and encounter design" goal was **NOT implemented by design** — the Phase 5 DIRECTIVE re-scoped the phase to character art and visual production. Its combat items are DEFERRED to later phases (see the Phase 5 "Re-scope note"): more skill kinds; status stacking/immunity/resistance; enemy telegraphs, interrupt windows and break gauges; boss phase scripting and add waves; encounter modifiers; battle speed, skip animations, auto-repeat and offline sweep; a damage-formula simulation harness; and a battle replay format shared with the future server. The Phase-4-deferred narrative items (dialogue graph, quest types/chains, cutscene tool, codex/bond episodes, localization keys, narrative QA) also remain deferred. None of these are part of Phase 6's scope. Phase 6 is now **In progress** after Phase 5 verification.

---

## Phase 7 — Social foundation · **Planned**

**Goal:** players can find each other before competitive systems.

- Account and character identity.
- Friends, recent players, block list.
- Presence, status and privacy settings.
- Chat channels: world, region, party, guild, direct; rate limits and moderation hooks.
- Player profiles and collection showcase.
- Mail with attachments and expiry.
- Report/ignore flows.

**Exit:** friends and chat work across sessions with moderation and abuse controls.

---

## Phase 8 — Guilds · **Planned**

**Goal:** persistent group identity.

- Guild creation, ranks, permissions, invitations and applications.
- Guild bank with audit log.
- Guild levels, missions and weekly goals.
- Guild hall or shared space.
- Guild chat and announcements.
- Name uniqueness, moderation and disband rules.

**Exit:** a guild can be created, staffed, leveled and audited without manual support intervention.

---

## Phase 9 — PvP arena · **Planned**

**Goal:** competitive play that is server-validated.

- Asynchronous arena defense teams.
- Real-time or turn-based live arena with server-owned turn validation.
- Matchmaking by rating and roster strength.
- Seasons, ranks, rewards and decay.
- Anti-collusion and win-trading detection.
- Replay viewer from validated event streams.

**Exit:** no client can alter turn order, damage, energy or rewards; rating integrity holds under load tests.

---

## Phase 10 — Co-op dungeons and raids · **Planned**

**Goal:** group PvE with authoritative encounters.

- Party matchmaking and lobby.
- Server-run encounter state for 2–8 players.
- Shared cooldowns, loot rules and need/greed/personal loot.
- Raid phases, mechanics and checkpoints.
- Disconnect/reconnect and AFK handling.
- Difficulty tiers and weekly lockouts.

**Exit:** a full dungeon run survives disconnects and cannot be completed by a modified client.

---

## Phase 11 — Live events, seasons and battle pass · **Planned**

**Goal:** a repeatable content cadence.

- Seasonal calendar and event scheduling service.
- Event currencies, shops and limited quests.
- Battle pass or free-track progression (legal review required).
- Login campaigns, mail rewards and comeback events.
- Content gating and feature flags.
- Live ops dashboard and rollback plan.

**Exit:** a season can be scheduled, run and closed without a client patch.

---

## Phase 12 — Authoritative backend and accounts · **Planned**

**Goal:** move every consequential decision behind the server.

This is the hard boundary. Nothing before this phase is safe for a live economy.

- Account service: registration, login, sessions, device/account linking, recovery.
- Player service: profile, roster, party, inventory, quests, pity, position checkpoints.
- Content service: signed content manifests and version pinning.
- Gacha service: server RNG, pity, ownership grant, audit log.
- Reward service: quest, battle and event grants with idempotency keys.
- Battle service: server-owned combat state and validation.
- Save migration from local JSON to server rows.
- Rate limiting, request signing and replay protection.
- Observability: metrics, tracing, structured logs.

**Exit:** a modified client cannot grant itself currency, characters, items, pity progress or battle rewards. Local save becomes a cache, not authority.

See `BACKEND.md` and `backend/schemas/schema.sql`.

---

## Phase 13 — Economy, trading and marketplace · **Planned**

**Goal:** player-to-player economy with fraud controls.

- Trading with confirmation, cooldowns and audit trail.
- Auction house / marketplace with taxes and price bands.
- Bind-on-pickup and bind-on-equip rules.
- Duplication and RMT detection.
- Currency faucet/sink monitoring and inflation controls.
- Purchase restoration and customer support tooling.
- Platform-compliant premium currency only after legal/store review.

**Exit:** trades are atomic, auditable, reversible by support policy, and resistant to duplication.

---

## Phase 14 — Mobile, console and accessibility polish · **Planned**

**Goal:** ship-quality feel across devices.

- Device profiles and quality presets.
- Touch layout editor, safe-area support, notches and foldables.
- Controller remapping and glyph switching.
- Text scaling, color-blind palettes, reduced motion, screen shake toggle.
- Subtitles, captions and audio sliders.
- Battery/thermal-aware frame pacing.
- Install size, patch size and asset streaming budgets.
- Store SDK integration behind platform abstractions.

**Exit:** certified builds on target mobile devices and at least one console, with accessibility review passed.

---

## Phase 15 — Localization and content moderation · **Planned**

**Goal:** global-ready text and safe social spaces.

- String tables and locale fallback.
- Translation pipeline with context and screenshots.
- Font coverage for CJK, Cyrillic, Arabic and accented Latin.
- Right-to-left layout audit.
- Chat filters, report queues, mute/ban tools and appeals.
- Age rating and regional content compliance.

**Exit:** at least five locales ship with no hard-coded UI strings; moderation SLAs are defined.

---

## Phase 16 — Analytics, telemetry and experimentation · **Planned**

**Goal:** make decisions from evidence.

- Privacy-respecting event taxonomy.
- Funnel: install → tutorial → first summon → first boss → day 7.
- Economy dashboards: sources, sinks, balances, gacha distribution.
- Combat analytics: win rates, turn counts, skill usage.
- Crash and performance reporting.
- Remote config and A/B tests with guardrails.
- Data retention and deletion workflows.

**Exit:** live ops can answer “where do new players stop?” and “is this banner rate healthy?” without ad-hoc queries.

---

## Phase 17 — Security, anti-cheat and compliance · **Planned**

**Goal:** protect players and the business.

- Threat model and abuse-case review.
- Server-side validation for every reward, purchase and trade.
- Device attestation where platform-allowed.
- Secrets management, key rotation and least-privilege IAM.
- Penetration test and dependency scanning.
- Privacy policy, terms, data export/delete, age gates.
- Purchase fraud, chargeback and refund workflows.
- Incident response and rollback runbooks.

**Exit:** external penetration test has no critical/high findings; compliance review signs off.

---

## Phase 18 — Scale, sharding and live operations · **Planned**

**Goal:** operate reliably as concurrency grows.

- Stateless gateways and horizontally scaled services.
- Database read replicas, partitioning and archival.
- Redis caching and distributed locks.
- Queue/backpressure for rewards, mail and trades.
- Regional deployment and latency routing.
- Load tests at target concurrency with headroom.
- Blue/green deploys, canaries and migrations.
- On-call, SLOs, error budgets and game-day drills.

**Exit:** load test at 2× launch forecast with p95 latency inside budget; rollback rehearsed.

---

## Phase 19 — Closed beta, open beta and launch · **Planned**

**Goal:** validate the full game with real players.

- Closed beta with telemetry and feedback loops.
- Balance passes from live data.
- Store pages, screenshots, trailers and press kit.
- Age ratings, privacy labels and platform submissions.
- Launch calendar, maintenance windows and compensation policy.
- Customer support knowledge base and macros.
- Launch-day war room and rollback criteria.

**Exit:** platform approvals, launch checklist signed, support staffing ready.

---

## Phase 20 — Post-launch live service · **Post-launch**

**Goal:** sustain the world.

- Six-week content cadence with seasonal story arcs.
- New regions, characters, banners, bosses and events.
- Community contests, creator program and fan-art policy.
- Roadmap communication and retrospective cadence.
- Power-creep and economy health reviews.
- Archival of old seasons and returning-player catch-up.
- Long-term save/content migration strategy.

**Exit:** defined live-service KPIs, content pipeline velocity and retention targets are met for two consecutive seasons.

---

## Cross-cutting principles

1. **Server authority before economy.** No trading, PvP or premium currency before Phase 12/13/17 controls exist.
2. **Data over code.** New content should not require engine changes.
3. **Test the rules, smoke the scenes.** Pure classes get deterministic unit tests; scenes get headless instantiation and manual QA.
4. **Mobile is a first-class target.** Budgets are set before content volume grows.
5. **Original IP only.** Every asset and name must be traceable to original work or a licensed source.
6. **Document limitations.** A known gap is acceptable; a hidden gap is not.
