# Testing

The slice has an automated headless suite plus a manual QA checklist. The automated suite covers rules, data integrity and scene instantiation; it does **not** judge visuals, audio, feel or device performance.

---

## 1. Automated suite

Run:

```powershell
godot --headless --path . res://tests/test_runner.tscn
```

Expected:

```text
==================================================
PROJECT FANTASY TESTS: 1484 passed, 0 failed
==================================================
```

The **236-test Phase 1 baseline is preserved**. Phase 5 closed at 1374 checks; subsequent integration work added protagonist-art runtime reporting, persistent exploration rewards, monster bonus-drop validation, exact reward preview/claim consistency, gear enhancement/save tests and enemy silhouette rendering hooks. The current suite is **1484 passed, 0 failed**; 1374 and 1478 are historical checkpoints, not the current total. Separate scene verifiers additionally exercise all three playable avatar sheets, the Fallen Matron phases and Verdict cinematic, map UI, arenas, menus, quests and turn timeline. Exit code is `0` on success, `1` on failure. `push_error` is used for failures, so CI logs show the failing assertion and its backtrace. `TESTING.md` is the single place the exact current total is documented.

### Content validator (standalone)

```powershell
godot --headless --path . --script res://tools/validate_content.gd
```

`tools/validate_content.gd` runs the same `ContentValidator` used at boot and in the tests. It exits `0` with `[validate] OK — 9 content files parsed and validated.`, or `1` with a list of errors. It needs no running scene.

### Save safety

`tests/test_runner.gd` snapshots:

- `GameState` via `_to_dict().duplicate(true)`.
- The raw local save file (if it exists).
- The `loaded_from_save` flag.

It stops autosave timers, runs tests, then restores the state and the raw save file. This lets tests call `GameState.new_game()`, `save_now()` and `load_save()` without erasing a real journey.

If a test crashes before restore, the save may be left in the test state. Keep a backup before running the suite on a save you care about.

### Coverage

| Area | Assertions |
| --- | --- |
| Content | JSON loads, no validation errors, character/skill/enemy/item/banner/quest references, rate sums, boss flags |
| Iso math | Grid ↔ world round trips, negative/fractional coordinates, chunk flooring, origin, segment distance |
| Streaming math | Radius-2 ring size, centre-first ordering, uniqueness, inside/outside checks, radius-0 |
| Gacha | Ten-pull count, real character IDs, ten-pull Epic floor, hard pity, featured pity, counter resets |
| Combat | Player/enemy construction, full deterministic battle, victory, event stream, element table, boss flag |
| State | New game defaults, currency add/spend/overspend, item stack/remove/over-remove, duplicates/awakening, party cap, quest flow, rewards, save round-trip |
| UI/scenes | Every overlay builds content, title menu builds, combat screen starts an engine, full game scene creates world/HUD/player |
| Exploration rewards | Gathering nodes grant the configured items once, persist claim flags through save-data round-trip, and stay hidden after world recreation |
| Bonus drops | Drop item/chance/amount references validate; precomputed victory rewards are exactly the same payload previewed and granted |
| Playable avatar reporting | The assembled world reports Kael's disk-backed 72-animation sheet instead of a stale procedural-placeholder status |
| Passives (multipliers) | All 12 supported ids; whisperstep team speed/turn order, rooted HP threshold, deep_roots defense, hold_the_line (different living ally, dead-holder control), hollow_crown (dark vs debuff), nothing_to_lose HP threshold, patient_weaver (stun) — via `CombatEngine` helpers |
| Passives (battle hooks) | small_miracles battle-start energy, dawnkeeper one-time heal refund (second heal does **not** refund), tidecall heal shield, ashen_wake burn on crit (+ no-crit control), sanguine_waltz 20% lifesteal — driven through real `CombatEngine.execute()` turns |
| Equipment | Additive stats from real items, weapon-first `equipment_element` derivation, resonance ×1.08 / attunement ×1.04 / neutral ×1.0; +1 enhancement costs exactly 180 Gold + 1 Glade Sap, adds 8% item stats and serializes per character/slot |
| Enemy presentation | Distinct procedural Mossling and Moonpetal Sprite silhouettes with animated fern mantle / wing motion; elemental ground sigils on ordinary monsters and larger bosses; enemy intent labels and threatened-party markers before enemy actions |
| Exploration presentation | Shrine Wisp and Grove Shard are additional one-time persistent gathering points, using the existing Moonpetal and Glade Sap inventory rewards |
| Strict validator | Malformed JSON, duplicate keys, missing skill/enemy/character/item references, invalid banner configs (rates, rarity, `hard_pity`, featured-out-of-pool, bad cost currency), valid documents pass, `validate_all()` parses 9 files |
| Quest prerequisites | `start_quest()` blocks `hollow_roots` until `glade_whisper` is complete, rejects a nonexistent `requires`, a no-`requires` quest still starts |
| Reward validation | Quest/enemy-group reward item references, `grant_reward_items()` currency → wallet vs material → inventory routing |

### Phase 3 coverage (8 new test groups, 203 checks)

Phase 3 adds **8 new test groups** in `tests/test_runner.gd` (203 checks). All
347 prior tests (236 Phase 1 + 111 Phase 2) are preserved:

| Group | Test function | Covers |
| --- | --- | --- |
| Visual style | `_test_visual_style()` | `GreenwardStyle` palette groups, `phase()` coverage, `SPRITE_SPECS`, `coherence_report()`, performance caps |
| Character animator | `_test_character_animator()` | pure 8 states × 8 directions, priority, looping vs one-shot, `tick()`/frame timing, `snapshot()`/`from_snapshot()` |
| Actor frame source | `_test_actor_frame_source()` | `REPLACEMENT_SPEC` / `specs()` contract, temporary-placeholder flags, graceful fallback |
| Procedural variety | `_test_procedural_variety()` | 47 prop kinds, deterministic distinct `variant`s, cached `character_frame()` placeholders |
| Chunk visual quality | `_test_chunk_visual_quality()` | river ribbon, `detail` ground-cover layer, richer terrain, preserved `build()` keys |
| Weather director | `_test_weather_director()` | CLEAR/MIST/RAIN/POLLEN_BLOOM deterministic transitions, intensity ramp, `params()`, mobile caps |
| Animated / interactive props | `_test_animated_and_interactive_props()` | bob/sway/pulse motion, off-screen `set_active()` gating, non-destructive `InteractiveProp` interact |
| World visual integration | `_test_world_visual_integration()` | `visual_style_report()`, 5 locations, fog/lighting/particles, prop variety |

"Directional movement" is the DIRECTION axis (8 values), **not a 9th state** —
the animator tests exercise this explicitly. Phase 4 adds a genuine ADDITIVE
9th state `CAST = 8` (a real one-shot, not a direction); `ALL_STATES` stays 8.
Headless mode does not render, so shader visual output is still not verified
(see §5).

### Phase 4 coverage (11 new test groups, 404 checks)

Phase 4 adds **11 new test groups** in `tests/test_runner.gd` (404 checks).
All 550 prior tests (236 Phase 1 + 111 Phase 2 + 203 Phase 3) are preserved:

| Group | Test function | Covers |
| --- | --- | --- |
| Region definitions | `_test_region_definitions()` | `regions.json` has exactly TWO complete region defs; new `world_origin`/`environment`/`entry_points`/`connections` fields; 53 `PROP_TYPES` |
| Region graph transitions | `_test_region_graph_transitions()` | `RegionGraph` ids/definition/entry_points/connections/`can_travel`/`resolve_transition`; world↔local projection; `validate_definitions`; BFS reachability |
| Invalid connections | `_test_invalid_connections()` | validator rejects a missing target region, self-loop, dangling `via`/`entry`, duplicate ids, invalid `kind`/`label`, bad `world_origin`/`environment`/`entry_points` |
| Region save state | `_test_region_save_state()` | `GameState.player_region`, `region_positions`, `set_player_region`/`set_region_position`/`region_position`/`has_region_position`; two save keys; old saves load into greenward |
| Asset manifest | `_test_asset_manifest()` | 8 asset classes with exact dimensions/import/seams; `status_report()` = FINAL 0 / TEMPORARY 8 / MISSING 8; `check_disk()` false for 8; `validate_sheet_specs()`; `replacement_seams()` |
| Asset loading fallbacks | `_test_asset_loading_fallbacks()` | `SpriteFramesActorSource.from_disk()` never crashes; `is_temporary()`/`has_frames()`/`missing_reason`; graceful procedural fallback |
| Animation sheet validation | `_test_animation_sheet_validation()` | `validate_sheets()` — 9 × 8 animations, frame counts, non-null 96 × 128 frames, loop flags; `DemoCharacterFrames` TEMPORARY in-memory sheet |
| Animation transitions | `_test_animation_transitions()` | ADDITIVE `CAST = 8` (`ALL_STATES` stays 8), `EXTENDED_STATES` 9, `frame_count_for`/`fps_for`/`looping_for`/`priority_for`, `transition_to`, `can_transition`, `finish_and_return`, `play_cast`, `cast_active`, `previous_state`, `transitioned` |
| Chunk preparer | `_test_chunk_preparer()` | pure bounded LRU, frame-sliced one-chunk-per-frame queue, bounded prefetch, `store`/`take`/`has_prepared`; NO threads |
| World region integration | `_test_world_region_integration()` | `GreenwardWorld` region-parameterization, data-driven second region, portals, `EventBus.region_change_requested`, per-region zone/spawn |
| Procedural art phase 4 | `_test_procedural_art_phase4()` | 53 prop kinds (6 new), distinct CAST pose (state 8), `GreenwardStyle.CAST_SPEC` |

> **Note — registry scope and headless limits.** The generic `AssetManifest`
> still reports **FINAL 0 / TEMPORARY 8 / MISSING 8** and the collectible
> `CharacterAssetRegistry` reports **FINAL 0 / TEMPORARY 120 / MISSING 120**.
> Those registries do not count the separate final playable art sets for
> Gerald, Lilith and Kael, or the Fallen Matron's three phase cutouts; see
> `assets/ASSET_STATUS.md`. **No audio** exists. **NO full visual QA** was
> performed in this automated run: headless checks validate structure and
> runtime safety, not rendered appearance, animation feel, shader output or
> device frame times.

### Phase 5 coverage (9 new test groups, 420 checks)

Phase 5 adds **9 new test groups** in `tests/test_runner.gd` (420 checks). All
954 prior tests (236 Phase 1 + 111 Phase 2 + 203 Phase 3 + 404 Phase 4) are
preserved, bringing the suite to **`1374 passed, 0 failed`**:

| Group | Test function | Covers |
| --- | --- | --- |
| Character art pipeline | `_test_character_art_pipeline()` | 10 asset kinds with exact dimensions/anchors/import/seams, `sheet_layout()` 9×8, `animation_names()` 72, `validate_asset()`, `self_check()` |
| Character art specs | `_test_character_art_specs()` | 12 specs, identity verbatim from `characters.json`, premium Legendary/Mythic tier, detailed generation prompts |
| Character asset registry | `_test_character_asset_registry()` | disk-computed FINAL/TEMPORARY/MISSING, 120 entries (12 × 10), `validate_finished_asset()`, `production_manifest()` |
| Character portrait loading | `_test_character_portrait_loading()` | `PortraitView` real-portrait seam + guarded procedural fallback |
| Sprite sheet registration | `_test_sprite_sheet_registration()` | `register_character()` / `validation_report()` / `registration_report()`, 72 animations (9 states × 8 directions), `ActorVisual.configure_character()` |
| Missing asset fallbacks | `_test_missing_asset_fallbacks()` | procedural fallback stays active; no real sheets; no crashes |
| Gacha presentation | `_test_gacha_presentation()` | rarity effects, premium result cards, `presentation_report()` |
| World visual standards | `_test_world_visual_standards()` | 6 categories, `region_tint()`, `validate()`, 57 prop kinds, `visual_standards_report()` |
| Asset status honesty | `_test_asset_status_honesty()` | ZERO final assets; both registries report FINAL 0; FINAL never hardcoded |

### Current integration additions (post-Phase 5)

The Phase 5 count above is a historical checkpoint. The current suite is
**1478 passed, 0 failed** and adds regression coverage for:
- The three playable protagonists' imported art and the assembled player's live
  art report (the generic art registries remain separate from these avatar sets).
- One-time gathering rewards, inventory grants, save-data round trips and
  re-instantiation hiding already-collected nodes.
- Enemy bonus-drop references and identical reward payloads between the victory
  preview and the actual claim.
- The Moonpetal Sprite preserving its own species visual rather than inheriting
  a randomized common-monster silhouette.

Focused scene verifiers (run individually after editor import):
- `verify_boss_actors.tscn` — boss visuals, Matron phase thresholds, Verdict
  impact pillars, signal timing and temporary VFX cleanup.
- `verify_character_avatars.tscn` — Gerald, Lilith and Kael, 72 animations
  each, frame dimensions, facing and avatar cycling.
- `verify_battlefield_arenas.tscn`, `verify_map_ui.tscn`,
  `verify_loading_ui.tscn`, `verify_menu_ui.tscn`,
  `verify_opening_cinematic.tscn`, `verify_opening_ui.tscn`,
  `verify_pause_menu.tscn`, `verify_quest_flow.tscn` and
  `verify_turn_timeline.tscn` cover their corresponding runtime surfaces.

### Adding a test

1. Add a `_test_*` function in `tests/test_runner.gd`.
2. Call it from `_run()`.
3. Use `check(condition, "label", "detail")`.
4. Use `near(a, b, epsilon)` for floats.
5. Keep tests deterministic: seed RNGs, avoid wall-clock/time-of-day assumptions.
6. If a test mutates `GameState`, remember the runner restores the snapshot at the end.

### Continuous integration

The repository ships a real GitHub Actions pipeline at `.github/workflows/ci.yml` (job `verify` on `ubuntu-latest`), triggered on every push, pull request and `workflow_dispatch`:

1. **Checkout** — `actions/checkout@v4`.
2. **Install Godot 4.7.2** — downloads `Godot_v4.7.2-stable_linux.x86_64.zip` from the official GitHub release, plus the Linux runtime libraries, and installs the headless editor binary as `godot`.
3. **Import project** — `godot --headless --path . --editor --quit`.
4. **Validate content JSON** — `godot --headless --path . --script res://tools/validate_content.gd`.
5. **Run automated test suite** — `godot --headless --path . res://tests/test_runner.tscn`.
6. **Smoke test game scene** — `godot --headless --path . res://scenes/game.tscn --quit-after 240`.
7. **Export pack smoke build** — `godot --headless --path . --export-pack "Linux/X11" build/project-fantasy.pck`, then `test -s` confirms a non-empty file.
8. **Upload artifact** — `actions/upload-artifact@v4` publishes `project-fantasy-smoke-pck`.

The editor import step must run before any class-cache-dependent operation. `--check-only` on individual scripts reports autoload identifiers as missing outside a running tree; that is expected, not a real failure. Prefer the test runner and scene smoke tests for real validation.

The Linux asset name was verified against the GitHub releases API for tag `4.7.2-stable`, and all `res://` paths used by the workflow exist in the repository. **GitHub Actions itself was not executed locally** — this is a documentation of the checked-in workflow, not a claim of a green CI run.

---

## 2. Smoke tests

Title scene:

```powershell
godot --headless --path . --quit-after 180
```

Game scene:

```powershell
godot --headless --path . res://scenes/game.tscn --quit-after 240
```

Expected: content loads, save loads or a new journey is created, no runtime errors.

The game-scene smoke test exercises:

- Content load and validation.
- Save load/new game.
- World bootstrap and chunk streaming.
- Procedural art generation.
- Shader compilation (headless still validates shader code).
- HUD, dialogue and overlay construction.
- Player and camera setup.

---

## 3. Manual QA checklist

Run on desktop and at least one touch device before calling a milestone done.

### Boot and title

- [ ] Game opens to the title screen at 16:9.
- [ ] Title, feature summary and starter portraits are readable.
- [ ] Begin Journey / Continue Journey text matches save state.
- [ ] Reset Journey requires two presses and actually resets.
- [ ] Quit exits cleanly.
- [ ] No console errors or warnings on boot.

### Movement and world

- [ ] WASD, arrows and left stick move the player.
- [ ] Shift sprints; release returns to walk speed.
- [ ] Camera follows smoothly and zoom limits work.
- [ ] Touch joystick appears on touch and moves the player.
- [ ] Terrain, water, props and actors y-sort correctly.
- [ ] Chunks load near the player and unload behind.
- [ ] No visible seams or holes at chunk borders.
- [ ] Day/night changes colour and fireflies appear at night.
- [ ] Frame rate is stable while walking through the village and forest.

### Interaction and dialogue

- [ ] Interact prompt appears near NPCs and the waypoint.
- [ ] E / Space / south button opens dialogue.
- [ ] Dialogue choices advance, close and apply actions.
- [ ] Elder Maelin starts *The Glade's Whisper*.
- [ ] Quest state changes are reflected in the quest screen.
- [ ] Closing dialogue restores world control.
- [ ] No input leaks through to movement while dialogue is open.

### Quests

- [ ] Quest screen lists active quests and steps.
- [ ] Killing the required mosslings advances progress.
- [ ] Returning to Elder Maelin shows the turn-in branch.
- [ ] Completing the quest grants gold, crystals, Moonpetal and the bow.
- [ ] The second quest starts after the first is complete.
- [ ] Quest state survives save/load.

### Combat

- [ ] Touching a roaming monster starts a battle.
- [ ] Enemy and party cards show correct names, elements and HP.
- [ ] Turn order preview matches actual turns.
- [ ] Skill buttons disable when not the player's turn or not enough energy.
- [ ] Single-target skills enter targeting mode and can be cancelled.
- [ ] Damage, heal, shield, status, crit and miss events appear.
- [ ] Ultimate becomes usable at full energy and consumes it.
- [ ] Auto mode plays the party automatically.
- [ ] Speed toggle changes pacing.
- [ ] Retreat asks for confirmation.
- [ ] Victory grants rewards and closes the battle.
- [ ] Defeat closes the battle without granting rewards.
- [ ] World control returns after battle.

### Gacha and collection

- [ ] Summon screen shows both banners and their rates.
- [ ] Single and ten-pull costs match the data.
- [ ] Insufficient crystals blocks the pull with a clear message.
- [ ] Pull animation/reveal shows rarity and featured status.
- [ ] New characters are added to the roster.
- [ ] Duplicates show awakening progress.
- [ ] Pity counters update and persist.
- [ ] Collection screen filters/sorts correctly.
- [ ] Character detail shows stats, skills, lore and equipment.
- [ ] Party changes persist and affect combat.

### Inventory and equipment

- [ ] Currencies and materials display correct counts.
- [ ] Equipment can be equipped and unequipped.
- [ ] Equipping replaces and returns the previous item.
- [ ] Stats update on the character sheet.
- [ ] Inventory changes persist after save/load.

### Pause, save and reset

- [ ] Esc / Start opens pause.
- [ ] Save Now reports success.
- [ ] Return to Title saves position and state.
- [ ] Reset Journey requires confirmation and starts a new game.
- [ ] Quit from pause saves and exits.
- [ ] Relaunching resumes position, roster, party, inventory and quests.

### Touch and mobile

- [ ] Safe areas are respected on notched devices.
- [ ] Buttons are large enough to tap reliably.
- [ ] Joystick and action buttons do not overlap critical UI.
- [ ] Text is readable at phone size.
- [ ] No hover-only interactions.
- [ ] Orientation stays landscape.
- [ ] App pause/resume does not corrupt state.

### Performance and stability

- [ ] No memory growth after 10 minutes of walking and fighting.
- [ ] No crash after opening/closing every screen repeatedly.
- [ ] No crash after 20 battles.
- [ ] Chunk streaming does not hitch visibly on target hardware.
- [ ] Save file is valid JSON after a crash/kill.
- [ ] Corrupt save falls back safely and creates a backup.

---

## 4. What the automated suite cannot catch

- Visual layout, contrast, clipping or readability.
- Animation feel, timing and game feel.
- Audio mix or missing audio.
- Touch ergonomics.
- Device-specific performance, thermal throttling or battery.
- Save corruption caused by OS-level file issues.
- Network behaviour (no network code exists).
- Exploits in a client-authoritative build (expected until Phase 12).

Manual QA and device profiling are mandatory before any public build.

---

## 5. Known test limitations

- Headless mode does not render, so shader visual output is not verified.
- `--check-only` on a single script reports autoload names as missing; use the test scene instead.
- The suite assumes the project’s default content files. If you intentionally remove content, update the count assertions.
- The test runner restores state in-process; a hard crash can skip restoration.
- The full game-scene test runs only a few frames, so long-running streaming and AI are not stressed.
- Combat is tested for completion and event shape, not for balance or fun.
- **Full visual QA and device profiling remain outstanding.** The automated checks use Godot's headless renderer and cannot judge composition, animation feel, shader output, touch ergonomics, frame pacing or thermal behavior. The generic asset registries still report FINAL 0 (8 generic classes and 120 collectible-character slots); the separate Gerald, Lilith and Kael playable art sets and Fallen Matron phase cutouts are documented in `assets/ASSET_STATUS.md`. No audio exists; the remaining collectible roster, NPCs, ordinary monsters and environment props still rely on procedural placeholders.
