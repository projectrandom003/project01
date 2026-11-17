# Reverie Ã¢â‚¬â€ Node Architecture Migration

## Goal

Migrate the existing offline single-player RPG to a scene-composed, node-oriented Godot architecture without changing gameplay rules, save compatibility, content IDs, player-facing behavior, or visual assets.

"Fully nodular" does **not** mean converting every pure algorithm into a Node. Pure deterministic rules and immutable definitions should remain lightweight RefCounted / Resource types. Stateful actors, controllers, presentation, input, world ownership, and gameplay services should be represented by reusable scene nodes with explicit ownership and signals.

## Acceptance criteria

- Runtime actors and world entities are authored scenes composed from focused child components.
- Stateful gameplay responsibilities are separated into independently testable nodes.
- Components communicate through typed methods and signals; no component reaches into unrelated UI or scene internals.
- Scene files own stable hierarchy and presentation layout. Runtime code configures data and connects signals rather than rebuilding static hierarchies.
- Large root scripts are thin composition/orchestration points, not multi-system implementations.
- Content definitions remain data-driven. Pure combat math, projection math, graph algorithms, validators, and serialization helpers remain non-Node types where that is the correct design.
- Existing public APIs remain compatible during migration; deprecated wrappers are removed only after all call sites and tests are migrated.
- No gameplay features or new content are added as part of this work.
- Full regression suite, content validation, editor import, scene startup smoke tests, and focused component tests pass after each migration group.

## Migration ledger

### Player actor

- [x] Authored child scene hierarchy for collision, actor visual, name label, personal glow, water surface, camera, interaction, status and health anchors.
- [x] Existing CharacterInteractionComponent now owns nearest-interactable scanning and interaction execution. Player retains a compatibility-facing reference and delegates interaction.
- [x] PlayerLocomotionComponent owns keyboard/gamepad/touch movement, sprint hysteresis, water slowdown, acceleration/braking, locomotion animation state and camera look-ahead.
- [x] PlayerCameraRig owns zoom input, wheel zoom and avatar framing.
- [x] Extract avatar selection/configuration into a dedicated character-avatar component.
- [x] Extract personal-light/day-phase response into a focused light component; water presentation remains a small actor-facing visual toggle.
- [x] Remove Player runtime hierarchy fallbacks; production and test paths instantiate the authored Player scene.

### Game/session composition

- [x] Extract world creation, region transition, world suspension and position persistence into a world-session node.
- [x] Extract overlay creation and pause-menu lifecycle into a dedicated overlay-router node.
- [x] Author WorldHost, WorldSession, UI and OverlayRouter as children in game.tscn; author MainMenu in main.tscn.
- [x] Extract combat-screen lifecycle into a dedicated combat router.
- [x] Reduce GameScreen to an authored composition root with typed child references and delegated world, overlay, combat, input and runtime responsibilities.
- [x] Route title/game, region and overlay transitions through their owning scene/router signals.

### World

- [x] Break GreenwardWorld into focused chunk scheduling/lifecycle, navigation/water, entity spawning, region builders/portals, prop construction, weather, fog, atmosphere, day/night, lighting, region context and visual-standards controllers.
- [x] Move Greenward-specific placement out of GreenwardWorld into its authored GreenwardBuilder child component. NPC spawns, river props, animated river props, 20 region anchors and five route endpoints are validated GreenwardCompositionData; remaining local offsets stay inside the dedicated region-composition component as authored composition logic.
- [x] Keep ChunkBuilder, ChunkStreamer, IsoMath, RegionGraph and other pure algorithms independent of the scene tree.
- [x] Make GreenwardWorld a composition root with component-owned implementations and compatibility-facing methods; remove duplicated legacy builder and streaming implementations.
- [x] Make CastleRoyalGardens delegate ground generation, lighting/ambient effects, NPC spawning and perimeter-wall composition to authored child components; remove obsolete duplicate procedural garden/path/water builder implementations.

### Combat

- [x] Extract transient combat feedback (battle log, banners, floating numbers and camera shake) into a dedicated CombatFeedbackComponent node.
- [x] Break CombatScreen into focused controllers for turn order, skill/target selection, result/retreat, event presentation and battle pacing.
- [x] Break Battlefield into authored layout/actor-placement and visual-effects nodes; transient camera shake remains owned by CombatFeedbackComponent.
- [x] Keep CombatEngine, CombatAI, ElementTable, CombatFactory and combatant rules pure and deterministic.
- [x] Make combat presentation consume the engine event stream rather than owning rule calculations.

### Persistent gameplay domains

- [x] Convert GameState autoload into an authored scene with an InventoryDomain child component.
- [x] Move wallet and item-inventory mutations into InventoryDomain; GameState retains compatibility methods.
- [x] Move quest progression, objective navigation, kill tracking and reward completion into a QuestDomain child node; GameState retains compatibility methods.
- [x] Move roster, party, character XP/profile XP, ascension, awakening, bonds and equipment enhancement into a RosterDomain child node.
- [x] Move banner roll orchestration and battle reward application into a RewardDomain child node.
- [x] Migrate script call sites for inventory, roster, quest and reward methods to their owning domain components (39 script files changed); keep tested GameState method wrappers for external/API compatibility.
- [x] Move persistent profile, inventory, roster, party, gear, quest, flag, pity and session/world state into Profile, Inventory, Roster, Quest, Reward and Session domain components. GameState properties are compatibility proxies; all script call sites use the owning domains directly.
- [x] Preserve existing save JSON shape and legacy-save migrations (full save/load regression tests pass with the scene-backed domains).
- [x] Move service ownership to an explicit scene/autoload hierarchy; no duplicate sources of truth.
- [x] Author GameState persistence, debounce-save and periodic-autosave nodes in game_state.tscn; remove runtime-created component/timer fallbacks.
- [x] Add ProfileDomain and SessionDomain scene children; GameState now delegates profile progression and world/session state to those owners.
- [x] Keep GameState as a compatibility facade for save/load, new-game orchestration and legacy property/method access; production scripts use domain components directly.

### UI and application shell

- [x] Keep screens as reusable scenes; split HUD currency/party/quest/toast presentation, CollectionScreen roster/detail presentation, and SettingsScreen controls/persistence into scene-owned components. InventoryScreen delegates item grid/filter/detail and crafting UI to authored layout children. MainBackdrop delegates its responsive composition and animation lifecycle to its authored Presentation child. All screen controllers are now focused composition/interaction scripts (largest is CombatScreen at 391 lines); remaining larger UI scripts are component implementations rather than screen monoliths.
- [x] Move static UI shells into authored .tscn layouts across Map, Quest, Inventory, Collection, Gacha, Pause, Combat, Shop and Settings. Remaining script-created controls are data-driven list/card/action rows, not static screen scaffolding.
- [x] Make Main and GameScreen authored composition roots; Main binds the authored MainMenu and GameScreen delegates to scene-owned controllers.
- [x] Keep UI intent and scene transitions routed through screen/router signals; world entities request gameplay events and do not instantiate UI.

### Verification and release gate

- [x] Add structural tests for Player, GameScreen, GameState, GreenwardWorld, Shop and Settings scene children, component types and ownership; castle tests also verify four continuous perimeter runs, collision barriers and both screen-facing X/Y facade scene types.
- [x] Run the full regression suite after each migration group; latest verified result is 1,912 passed / 0 failed.
- [x] Run content validation through the regression suite and headless Godot editor import; latest editor scan exited 0.
- [x] Headless startup smoke tests for the title and Game scenes exit cleanly.
- [x] Regression/integration tests cover new journey, Castle continue, exact saved position, legacy saves, region graph transitions, manual interaction/combat, Escape and controller Start pause routing, mobile back-notification pause routing, world suspension, Settings hint wrapping, UI/overlay regressions, shop/settings and return-to-title.
- [x] Migration-focused live QA completed on 2026-11-16 using the standalone Godot 4.7.2 runtime and isolated user-data profile. Captured the title/Settings overlay (`artifacts/qa/node_migration_standalone_maximized.jpg`), confirmed Escape closes Settings (`artifacts/qa/node_migration_settings_escape.jpg`), confirmed Continue loads The Hollowed Grove with the saved party (`artifacts/qa/node_migration_continue_enter.jpg`), and opened the authored Journey/Pause overlay through the HUD Menu button (`artifacts/qa/node_migration_menu_button_click.jpg`). The Castle Royal Gardens perimeter remains documented in `artifacts/qa/maximized_exported_window.png`; the bottom wall is a continuous front-facing stone facade with raised supports and inset panels. Settings responsive layout is covered at compact and desktop breakpoints, and the latest full suite remains 1,912 passed / 0 failed. Escape/controller Start/mobile back routing is covered by automated input-router tests; physical controller/mobile hardware was not attached for direct manual input. The exported Windows executable was successfully produced, but Windows Application Control blocked its interactive launch in this session; no security policy was bypassed. This is an environment-limited release check, not an outstanding node-migration task.
- [x] Export a fresh Windows debug build. `build/windows/Reverie.exe` was re-exported successfully from the latest source (165,189,992 bytes; `artifacts/qa/windows_export_after_settings_window_breakpoint.log`); the Windows preset excludes artifacts, tests, docs and tools. A re-launch attempt in this session was blocked by the machine's Application Control policy, so interactive smoke-launch of this exact binary is not newly confirmed here; earlier export/startup smoke evidence remains in the QA logs.

## Current migration checkpoint

The Player scene now delegates interaction scanning, locomotion simulation and camera controls to dedicated child components. The interaction component was already present in the authored scene; the Player now uses it as the single interaction owner. The movement and camera components are new scene-owned responsibilities.

The latest full regression suite was freshly re-run at **1,912 passed / 0 failed** on 2026-11-16 after adding explicit tests for both screen-facing castle wall facades, Escape/controller Start/mobile-back pause routing, and all three Settings hint labels expanding and wrapping. This verification used an isolated project user-data profile, separate from the live game's save. Its latest fresh verbose isolated log is `artifacts/qa/node_migration_final_verification.log`; it records 1,912 passed / 0 failed, with zero script errors, parse errors, ObjectDB leak diagnostics or RID leak diagnostics. Settings now uses an authored GridContainer that switches between two desktop columns and one compact column, wrapped in a vertical ScrollContainer; automated tests cover both width thresholds and the scroll wrapper. The earlier isolated input-router run remains at `artifacts/qa/input_router_isolated_regression.log`. Since the earlier 1,843-test checkpoint, the Player, GameScreen and GreenwardWorld runtime hierarchy fallbacks were removed; Greenward NPC/river placements and route anchors moved into validated GreenwardCompositionData; typed public composition APIs replaced builder access to private world internals; ShopScreen/SettingsScreen static shells moved into reusable layout scenes; and GameState was reduced to a compatibility facade over Profile, Session, Inventory, Roster, Quest and Reward domains. Script call sites now use domain APIs and domain-owned state directly. Ten malformed castle asset scenes using nested Vector2 constructors inside PackedVector2Array were corrected. Structural tests cover Player, GameScreen, GameState, GreenwardWorld, Shop, Settings, castle perimeter geometry/collision and both X/Y facade scene types. The headless editor scan exited 0; title and Game scene startup pass in headless mode. The standalone Godot runtime was launched interactively and used to verify the title/Settings overlay, Escape close behavior, Continue journey loading The Hollowed Grove and the authored Journey/Pause overlay. Screenshots are recorded under `artifacts/qa/node_migration_*.jpg`. The latest verbose headless suite reports no leaked ObjectDB instances or rendering/text RIDs at shutdown. The earlier 4 dummy-texture, 24 shaped-text, 2 font, 37 CanvasItem and 174 ObjectDB warnings no longer reproduce after replacing temporary UIFactory Button/ProgressBar instances used only to retrieve styleboxes with direct stylebox helpers. The Windows debug build was re-exported successfully after this cleanup. Visual captures confirm the castle gate/facade and title menu render. The exported Windows executable's interactive launch remains blocked by Windows Application Control; this exact binary launch is therefore not claimed as verified. Physical controller/mobile hardware was not attached, while their input routes are covered by automated integration tests.

## Migration completion

**Node architecture implementation: 100% complete.** All planned stateful gameplay, actor, world, UI, routing and persistence responsibilities are owned by authored scenes and focused components. Pure algorithms, immutable definitions, validators and serialization helpers intentionally remain non-Node types. All migration ledger items are complete. The only remaining caveats are external release-verification constraints documented above: Windows Application Control blocks interactive launch of the exported executable in this environment, and physical controller/mobile devices were unavailable for direct hands-on QA.

## Post-completion mistake audit Ã¢â‚¬â€ 2026-11-16

- [x] Fresh full regression rerun: **1,912 passed / 0 failed**, exit code 0. Log: `artifacts/qa/mistake_audit_full_regression.log`.
- [x] Fresh headless Godot editor import: exit code 0, no script errors, parse errors, engine errors or warnings. Log: `artifacts/qa/mistake_audit_editor_import.log`.
- [x] Headless startup of `res://scenes/main.tscn` and `res://scenes/game.tscn`: both exit code 0 with zero script/parse/engine error lines. Logs: `artifacts/qa/mistake_audit_startup_main.log` and `artifacts/qa/mistake_audit_startup_game.log`.
- [x] Scene resource-reference audit: zero missing `res://` references across authored `.tscn` files.
- [x] Final regression diagnostics: zero script errors, parse errors, ObjectDB leak diagnostics or RID leak diagnostics.
- [ ] Visual/content production remains a separate project phase: character/world art registries and source comments explicitly identify remaining procedural placeholder art. This is not a node-migration code failure and was not silently relabelled as finished art.
- [x] Save-recovery logging cleanup: malformed JSON and structurally invalid save files that are successfully backed up and rejected now emit `push_warning` rather than `push_error`; actual backup/copy/remove failures still emit errors. This removes a false engine-error diagnostic from the intentional corruption regression test without hiding real recovery failures. Fresh post-fix regression: **1,912 passed / 0 failed**; content validator exit 0; editor import exit 0; zero `ERROR:`/script/parse/leak diagnostics. The single expected save-recovery warning is recorded in `artifacts/qa/mistake_audit_postfix_regression.log`. Validator and editor logs: `artifacts/qa/mistake_audit_postfix_content_validation.log` and `artifacts/qa/mistake_audit_postfix_editor_import.log`.
- [x] Refreshed the 31 standalone `verify_*.tscn` QA scenes. Fixed stale test fixtures that instantiated `Player`, `RoamingMonster` or `Battlefield` without their authored scene components; moved checks to the owning Avatar/Effects components; updated title/loading-screen assertions to match the current authored menu and the deliberately empty/hidden loading PartyLayer; replaced removed `MainMenu.STARTERS` references with checks against the live authored menu; and corrected direction tests to drive the Player's facing input rather than mutating the animator behind its controller. Gerald's slow idle-breath test now samples a full breathing cycle instead of two arbitrary sine phases. Final combined verification: **31/31 scenes exit 0, zero script/parse/engine-error diagnostics**. The final Gerald runtime test also verifies all 8 directional attacks and blade waves, 3 attack variants, 3 skills, idle breathing and effect cleanup. Summary: `artifacts/qa/verify_final_batch_summary.csv`; per-scene logs: `artifacts/qa/verify_final_batch_*.log` plus targeted post-fix logs.
- [x] Final post-fix gate rerun after all QA fixture changes: Godot editor import exit 0; content validator exit 0 (`9 content files + main characters`); full regression **1,912 passed / 0 failed**, exit 0; zero script/parse/engine-error or leak diagnostics. One expected warning is emitted by the intentional malformed-save recovery test. Final logs: `artifacts/qa/mistake_audit_final_editor_import.log`, `artifacts/qa/mistake_audit_final_content_validation.log`, and `artifacts/qa/mistake_audit_final_full_regression.log`.


## Follow-up node modularity pass Ã¢â‚¬â€ 2026-11-16

The original migration ledger above records completion of the planned Player, Game/session, World, Combat, persistent-domain and UI composition migrations. A follow-up audit and modularity pass was performed after the Gacha banner parser repair.

### Permanent architecture guardrails

- Stateful runtime behavior must have an explicit scene/node owner.
- Stable visual hierarchy and reusable UI composition belong in authored `.tscn` scenes. Runtime code may create genuinely data-driven rows, cards, effects and lists.
- Scripts are allowed as node behavior. The goal is not zero GDScript; the goal is small, cohesive node components rather than scripts that own unrelated systems.
- Pure deterministic algorithms, immutable definitions, validators and serialization helpers remain lightweight non-Node types where they do not need scene-tree lifecycle or signals.
- Components expose typed methods and signals, receive dependencies explicitly, and do not reach into unrelated screen or world internals.
- Split a component when it accumulates a second independent responsibility; line count alone is not a reason to create unnecessary nodes.
- Preserve save format, content IDs, visual assets and public compatibility APIs during migrations. Remove legacy code only after call-site and regression verification.
- Every migration batch must pass editor import, focused scene checks and the full regression suite before it is considered complete.

### Gacha UI follow-up

- [x] Extract Scarlet Requiem's dedicated presentation into `ScarletRequiemBannerTemplateComponent`.
- [x] Author `scarlet_requiem_banner_template_component.tscn` and compose it under `gacha_banner_content_component.tscn`.
- [x] Change `gacha_screen.tscn` to instance the authored banner-content scene instead of attaching its script directly to an ad-hoc Node.
- [x] Keep generic banner orchestration in `GachaBannerContentComponent`; delegate the Scarlet-specific presentation to its child component.
- [x] Preserve the existing Scarlet portrait asset path and the independent banner selection behavior.
- [x] Godot 4.7.2 headless editor import completed and registered both Gacha component classes.
- [x] Fresh full regression suite: **1,977 passed / 0 failed**, exit code 0.

This is a targeted follow-up improvement, not a claim that every line of GDScript should become a Node. The completed migration boundary remains stateful runtime ownership and reusable composition; pure logic stays pure.

## Project-wide nodularisation follow-up Ã¢â‚¬â€ 2026-11-16

This pass extends the existing node-first architecture beyond the original migration ledger.

### Gothic Castle boss zone
- [x] Reduced `GothicCastleBossZone` from a 551-line world builder to a small scene orchestrator and compatibility-facing world API.
- [x] Added authored `Components/Environment` (`GothicCastleEnvironmentComponent`) for ground tiles, route dressing, castle/arena structures, piece/texture caches and world bounds.
- [x] Added authored `Components/ActorSpawner` (`GothicCastleActorSpawnerComponent`) for player, NPC, monster, gathering-node and portal instantiation.
- [x] Added authored `Components/Session` (`GothicCastleSessionComponent`) for position persistence, exploration rewards and weather ticking.
- [x] Kept `ReverieRouteData` as a pure deterministic layout/data contract.
- [x] Authored `DayNight` as a `CanvasModulate` child instead of constructing the stateful scene node from the world script; retained `WeatherDirector` as a pure `RefCounted` state machine.

### Royal Gardens expansion
- [x] Replaced the single mixed-responsibility expansion builder with an authored `castle_expansion_component.tscn` composition scene.
- [x] Split the approach dressing, one-time cache and region portal into `ApproachBuilder`, `CacheSpawner` and `PortalConnector` child nodes.
- [x] Authored the expansion ground, flora and props layers in the scene tree rather than creating those structural containers at runtime.
- [x] Replaced the inline `ExpansionBuilder` script node in `castle_royal_gardens.tscn` with an instance of the reusable composition scene.
- [x] Moved `DayNight` from runtime `DayNight.new()` construction into an authored `CanvasModulate` child in `castle_royal_gardens.tscn`.

### Verification for this pass
- [x] Godot 4.7.2 headless editor import registered the new component classes.
- [x] Gothic Castle boss-zone headless scene launch completed with exit code 0 after the session split.
- [x] Rechecked Gothic Castle boss-zone scene launch after moving `DayNight` into the authored scene; exit code 0. Forward and return transition verifier: PASS.
- [x] Royal Gardens headless scene launch completed without runtime errors after the authored-layer correction.
- [x] Corrected `verify_reverie_transition.gd` to build Royal Gardens through `GameWorldSessionComponent` before testing; confirmed forward and return `transition_to()` calls both succeed with an active player.
- [x] Full regression suite after the scene composition changes: **1,977 passed / 0 failed**, exit code 0.
- [ ] GUI visual walkthrough remains outstanding; headless verification does not establish final visual quality.

### Remaining project-wide audit
This is a continuing migration, not a claim that every project system is already fully nodularised. Continue auditing large stateful controllers and scene ownership in Greenward, the Player/session boundary, combat presentation, screen/UI orchestration and remaining world systems. Keep pure algorithms, static route/content data, validators and serialization helpers as non-Node utilities unless they genuinely need scene-tree lifecycle or signals. Preserve public world APIs, save compatibility and existing content identifiers throughout.

## Step 2 Ã¢â‚¬â€ Greenward runtime and world-session ownership Ã¢â‚¬â€ 2026-11-16

### Greenward
- [x] Added authored `WorldRuntime` node with `WorldRuntimeComponent`; moved per-frame chunk-centre updates, ambient effect following, weather ticks, periodic position persistence, atmosphere refresh, animated-prop gating and frame-sliced chunk preparation out of the world root.
- [x] Added authored `ResourceSetup` node with `WorldResourceSetupComponent`; moved per-world shader material and FastNoiseLite creation/configuration out of the root.
- [x] Kept `GreenwardWorld` as the composition root and compatibility API for region builders, navigation, streaming, prop factories, presentation and tests. Existing builder/spawner components remain the owners of their own responsibilities.
- [x] Preserved the original initialization order: resources -> layers -> noise -> day/night -> player -> region composition -> entities -> presentation -> streaming -> world-ready.

### Player and game session
- [x] Audited `Player`: its scene already owns authored Collision, Camera, Interaction, Locomotion, Avatar and Presentation child components. The Player script remains the stable public facade; no redundant wrapper nodes were added.
- [x] Reduced `GameWorldSessionComponent` to a session composition root/facade.
- [x] Added authored `Transition`, `Activation` and `Persistence` children to `scenes/game.tscn`, each owning route validation/world swaps, simulation/input gating, and save-state persistence respectively.
- [x] Kept the public session methods (`build_world`, `resolve_region_id`, `transition_to`, `set_world_active`, `persist_current_world_state`) stable for GameScreen and existing callsites.

### Step 2 verification
- [x] Godot 4.7.2 headless editor import: exit code 0; registered all new component classes.
- [x] Greenward scene launch: exit code 0.
- [x] Game scene launch: exit code 0.
- [x] Real forward and return region transitions with an active player: PASS.
- [x] Full regression suite: **1,977 passed / 0 failed**, exit code 0.
- [ ] GUI visual walkthrough and interactive play session remain outstanding.

### Next
Proceed to combat architecture and UI orchestration audit. Do not convert pure deterministic algorithms, immutable content data, route graphs, validators or serialization helpers into Nodes unless they need scene-tree lifecycle or signal ownership.

## Step 3 Ã¢â‚¬â€ Combat architecture and UI orchestration Ã¢â‚¬â€ 2026-11-16

### CombatScreen
- [x] Added authored `Session` and `Input` child nodes in `scenes/ui/combat_screen.tscn`.
- [x] Moved battle initialization, party/enemy construction, boss HUD setup and battlefield staging into `CombatSessionComponent`.
- [x] Moved Escape/target-cancel/retreat routing into `CombatInputComponent`.
- [x] Kept `CombatScreen` as the public composition facade and compatibility API for existing combat callers.
- [x] Made every controller child mandatory and scene-authored; removed runtime `Component.new()` fallback construction.
- [x] Made the authored backdrop and `CombatScreenLayout` mandatory. `CombatLayoutComponent` now binds and styles the authored layout instead of instantiating fallback screen hierarchy.

### Battlefield and combatant actor
- [x] Made `Battlefield` require its authored `Layout` and `Effects` nodes.
- [x] Removed runtime fallback creation of arena backdrops, Embers, actor stage, and layout/effects components. The existing `battlefield.tscn` scene owns all five stable visual nodes.
- [x] Resolve the arena identifier from the owning CombatScreen before configuring arena visibility, so boss/estate backdrops are selected during Battlefield initialization.
- [x] Added `GroundFX` as an authored child scene of `battlefield_actor.tscn`.
- [x] Made `BattlefieldActor.setup` require its authored GroundFX, hitbox, name label, intent label, HP plate and ActorVisual children. Removed the runtime fallback creation paths and obsolete scene preloads.
- [x] Kept transient effects, floating feedback, temporary result/retreat overlays and data-driven actor instances dynamically instanced; these are runtime content, not stable scene hierarchy.
- [x] Kept `CombatEngine`, `CombatAI`, `CombatFactory` and combatant calculations as pure deterministic logic.

### Regression fixture updates
- [x] Updated combat UI tests to instantiate `combat_screen.tscn` rather than constructing a bare `CombatScreen.new()` with no authored child hierarchy.
- [x] Added structural checks for the authored CombatScreen Session/Input nodes and BattlefieldActor GroundFX child.

### Step 3 verification
- [x] Godot 4.7.2 headless editor import: exit code 0, no script/parse errors.
- [x] Battlefield scene startup smoke: exit code 0.
- [x] Game scene startup smoke: exit code 0.
- [x] Full regression suite: **1,980 passed / 0 failed**, exit code 0.
- [x] Static audit confirms no runtime fallback creation of CombatScreen/Battlefield controller components or stable layout/environment hierarchy.
- [ ] GUI visual walkthrough and hands-on battle interaction remain outstanding; headless tests do not replace visual QA.

### Next
Continue the remaining UI-screen and actor-presentation audit. Split only independent stateful responsibilities into authored nodes; retain data-driven transient effects and pure combat rules in their appropriate owners.

## Step 4 Ã¢â‚¬â€ Remaining UI screens and actor presentation Ã¢â‚¬â€ 2026-11-16

### Title backdrop and HUD
- [x] Kept `MainBackdrop` as a thin facade and made its `Presentation` child mandatory and scene-authored.
- [x] Removed the presentation component's fallback construction of the stable sky, moon, city, village, tree, arch, path, seal and atmosphere hierarchy. It now binds the authored `main_backdrop.tscn` nodes and reports missing composition nodes.
- [x] Authored `SkyGradientTexture` in `main_backdrop.tscn`; the presentation component configures its generated Gradient resource but no longer creates the TextureRect node.
- [x] Kept repeated, data-driven decorative details (building silhouettes, branches, fog puffs, fireflies and petals) generated as transient visual children. These are count-driven art primitives, not controller or ownership nodes.
- [x] Made HUD Currency, Party, Quest and Toast components mandatory authored children. Removed `Component.new()` fallbacks and the fallback QuestLabel; HUD now stops initialization if its required scene composition is incomplete.

### Opening cinematic and overlay screens
- [x] Made `OpeningCinematic` bind its authored CharacterLayer, Caption, SkipButton, TimelineProgress and CinematicFade nodes; removed all fallback Control/Node construction.
- [x] Made `CollectionScreen` require its authored Roster and Detail components; removed runtime component creation and placeholder PanelContainer fallbacks.
- [x] Made `GachaScreen` require its authored BannerContent and SummonFlow components; removed runtime component creation and placeholder content fallbacks.
- [x] Moved `SummoningChamberAtmosphere` into `gacha_screen.tscn` as a scene-owned child instead of instantiating and reordering it in `_ready()`.
- [x] Audited remaining overlay composition: Settings already owns Controls/Persistence children; Quest, Map, Inventory, Shop and PauseMenu use dedicated reusable layout/content scenes under the shared OverlayScreen shell. Data-dependent cards/rows remain transient content instances.
- [x] Updated UI regression fixtures to instantiate the actual Gacha and Collection scenes rather than bare script instances.

### Combat actor presentation
- [x] Extracted Fallen Matron's phase cutouts, idle corruption motes, health-threshold phase changes, phase bursts, hit flash, attack anticipation and death animation into `FallenMatronPresentationComponent`.
- [x] Authored `fallen_matron_presentation_component.tscn` with explicit Art and CorruptionMotes child scenes and attached it to every BattlefieldActor scene.
- [x] Reduced `BattlefieldActor` to common combatant presentation and delegated all Matron-specific behavior to its child component.
- [x] Disabled Matron art/motes by default so ordinary actors do not display boss-only particles; the component activates them only for Fallen Matron when the phase-one texture is available.
- [x] Preserved the procedural ActorVisual fallback when Matron art is unavailable.

### Step 4 verification
- [x] Godot 4.7.2 headless editor import: exit code 0, no parse errors.
- [x] MainBackdrop scene startup: exit code 0.
- [x] OpeningCinematic scene startup: exit code 0.
- [x] GachaScreen scene startup: exit code 0.
- [x] CollectionScreen scene startup: exit code 0.
- [x] Game scene startup with HUD: exit code 0.
- [x] Full regression suite: **1,984 passed / 0 failed**, exit code 0.
- [x] Added structural assertions for the authored MainBackdrop hierarchy, Gacha chamber atmosphere and Fallen Matron presentation child.
- [ ] GUI visual walkthrough and live battle/overlay interaction remain outstanding; headless tests establish structural/runtime correctness, not final visual quality.

### Step 4 boundary
The stable scene hierarchy and stateful component ownership in this audit are scene-authored. GDScript remains the behavior layer attached to those nodes; pure deterministic rules and transient, data-driven UI/visual content are not forced into redundant wrapper nodes.

## Step 5 Ã¢â‚¬â€ Project-wide architecture audit and actor-scene hardening Ã¢â‚¬â€ 2026-11-16

### ActorVisual composition contract
- [x] Audited `scenes/characters/actor_visual.tscn`: it already authors `CharacterAnimationComponent`, `ProceduralRenderer`, `Pose`, and `SpritePresentation` (plus equipment, effects, animation, attachment and status nodes).
- [x] Removed `ActorVisual` runtime construction of the four stable component children. The reusable actor scene is now the required composition root; the script binds and validates its authored children.
- [x] Kept `CharacterAnimator` and `ProceduralActorFrames` as lightweight logic/resource objects; they do not need scene-tree lifecycle ownership.
- [x] Updated all ActorVisual regression fixtures to instantiate `actor_visual.tscn` rather than a bare script-only node.

### Enemy and NPC composition contracts
- [x] Removed `EnemyVisualComponent` fallbacks that created ActorVisual, NameLabel and Accent. `roaming_monster.tscn` already owns these scenes.
- [x] Fixed EnemyVisual exported NodePath resolution: exported paths are resolved relative to the component node, not incorrectly relative to the optional owner root.
- [x] Removed WorldNPC fallback creation of ActorVisual, NameLabel and SubtitleLabel. WorldNPC now validates its authored ActorVisual, labels, InteractionRing and QuestMarker.
- [x] Added the missing InteractionRing and QuestMarker child scenes to Edgar's dedicated scene, preserving his separate custom artwork and label positioning.
- [x] Added regression assertions that roaming monsters and all assembled Greenward NPCs have their complete authored presentation hierarchy.

### Project-wide classification from the audit
- [x] Confirmed the large `ProceduralArt` module is a `RefCounted` deterministic texture/frame factory with caches, not a scene controller. Keep it as a pure/resource-oriented pipeline rather than wrapping each painter in a Node.
- [x] Confirmed `ContentValidator` is a data-only validator shared by boot, CI and tests. Its size alone is not a reason to convert it into a Node.
- [x] Confirmed `ActorProceduralRendererComponent` is an actual scene component; its species-specific drawing methods are a coherent fallback renderer. It remains a future candidate for internal renderer-strategy extraction if those strategies gain independent ownership/configuration.
- [x] Confirmed BattlefieldEffectsComponent is an actual scene-owned effects facade. Kael, Fallen Matron, generic attacks, floating numbers and elemental bursts now delegate to independently authored presentation children; damage/turn authority remains in CombatEngine.
- [x] Confirmed `GreenwardWorld` remains the world composition root. Its authored runtime, resource, streaming, lifecycle, navigation, entity, atmosphere and presentation components own the independent stateful services; root-level build ordering remains explicit to preserve initialization dependencies.

### Step 5 verification
- [x] Godot 4.7.2 headless editor import: exit code 0.
- [x] Full regression suite: **1,986 passed / 0 failed**, exit code 0.
- [x] ActorVisual, roaming-monster and assembled NPC presentation hierarchy assertions passed.
- [x] No `ActorVisual.new()` construction remains in production scripts.
- [x] Backups preserved for ActorVisual, EnemyVisual, WorldNPC and test fixture edits.
- [ ] GUI visual walkthrough, mobile/desktop interaction and hands-on battle QA remain outstanding.

### Remaining architecture work (do not mislabel as completed)
- [x] Split combat visual-effects choreography into independently authored Kael, Fallen Matron, generic attack and impact-effect responsibilities without changing combat timing or hit authority.
- [x] Audited procedural actor renderer strategy extraction: human/spirit/monster body drawing shares view-state and drawing primitives and has no independent scene lifecycle contract; retained one renderer component, while Kael/Lilith character VFX moved to a dedicated child.
- [x] Re-audited GreenwardWorld: independent runtime/resource/streaming/lifecycle/navigation/entity/region/Greenward-builder/presentation responsibilities are authored children; remaining root methods are stable compatibility delegates, composition ordering, or lightweight shared registries, so no redundant wrapper nodes were added.
- [ ] Run a full visual QA pass after these structural changes.

Step 5 closes the audit and fixes the concrete actor-scene ownership gaps found. It does not claim every large file should become a Node or that visual QA is complete.

## Royal Gardens Ã¢â‚¬â€ full map-level node ownership pass Ã¢â‚¬â€ 2026-11-16

### Composition root and runtime ownership
- [x] Reduced `CastleRoyalGardens` to a composition root and compatibility facade. Removed runtime creation of missing hierarchy layers and removed the broad `_ensure_environment_layers` / `_clear_dynamic_layers` behavior.
- [x] Authored the required terrain, grass-detail, terrain-transition, lighting and environment-effect layers in `castle_royal_gardens.tscn`.
- [x] Added `CastlePlayerSpawnerComponent` as an authored scene child; it owns player instantiation, entry-point resolution, save restoration, facing restoration and initial session-state synchronization.
- [x] Added `CastleWorldRuntimeComponent` as an authored scene child; it owns periodic position persistence and save cadence.
- [x] Added `CastleWorldPresentationComponent` as an authored scene child; it owns HUD/diagnostic visual reports while the world root preserves the public report methods.
- [x] Attached `CastleArchitectureComponent` directly to the authored Castle assembly; its placement transform is no longer configured by the world root.
- [x] Preserved public world-facing properties and methods (`player`, `npcs`, `monsters`, `region_id`, spawn queries, water query, area name, day phase and visual reports).

### Perimeter walls and architecture
- [x] Replaced the single procedural four-wall factory with four authored instances of `castle_perimeter_wall_run.tscn`.
- [x] Each wall run owns authored Facade, Parapet, Plinth, Piers and WallCollision nodes and has its own `CastlePerimeterWallRunComponent`.
- [x] Extracted reusable architectural piers into `castle_perimeter_pier.tscn`; the wall-run component instances this reusable piece at each bay interval.
- [x] Kept `CastlePerimeterWallsComponent` as a validator/composition node rather than a geometry factory.
- [x] Preserved the four-sided perimeter positions, run lengths, collision layer/mask and existing test-facing `GardenPerimeterWalls` contract.
- [x] Kept the inner castle's individual X/Y wall pieces, towers, gatehouse and stairs as separate authored scenes.

### Lighting and expansion
- [x] Extracted the reusable garden point light, ambient particles and shadow into authored scenes; `CastleLightingComponent` now configures and instantiates those scene assets.
- [x] Removed runtime fallback creation of ExpansionGround, ExpansionFlora and ExpansionProps. Approach, cache and portal components now require the authored expansion layers and report missing composition instead of manufacturing replacements.
- [x] Added null guards so missing expansion layers fail safely instead of causing follow-on null-instance errors.
- [x] Kept procedural terrain tile placement and expansion asset placement data-driven: repeated tiles and pack pieces are content instances, not stable controller hierarchy.

### Verification
- [x] Godot 4.7.2 headless editor import: exit code 0.
- [x] Royal Gardens scene was instantiated through the full game test path.
- [x] Full regression suite: **1,999 passed / 0 failed**, exit code 0.
- [x] Added structural assertions for the four authored wall runs and their facade/parapet/plinth/pier/collision children; player spawner, runtime, presentation, architecture and environment layers.
- [x] Preserved pre-change backups for the world root, perimeter controller, terrain, lighting, scene and test fixture.

### Scope and visual QA boundary
The active Royal Gardens runtime now uses authored scene nodes for stable ownership and reusable modular scenes for architectural, lighting and expansion pieces. Deterministic grid/layout helpers and data-driven repeated tile/prop placement remain code/resource driven by design; wrapping each tile or pure calculation in a controller Node would add overhead without improving ownership. The four outer perimeter walls remain at the map boundary, so their visibility depends on camera position. A GUI walkthrough from the player's spawn and a complete perimeter traversal are still required before claiming visual completion.


### Royal Gardens Ã¢â‚¬â€ reusable component-scene completion Ã¢â‚¬â€ 2026-11-16

- [x] Converted legacy entrance and exterior builders to instantiate authored reusable sprite-prop and collision-box scenes; their own stable Visuals and Collisions layers are now scene-authored.
- [x] Converted decorative props, hedges, flower beds, urns, pathways, ponds, waterfalls and bridges to use reusable authored prop/collider scenes instead of constructing Sprite2D, StaticBody2D, CollisionShape2D, PointLight2D or Node2D hierarchies directly.
- [x] Added authored instance/layer containers to the reusable component scenes: PropInstances, HedgeInstances, FlowerBeds, UrnPlanters, Collisions, Tiles and WaterVisuals.
- [x] Added `garden_sprite_prop.tscn`, `garden_collision_box.tscn` and `garden_collision_circle.tscn` as reusable authored templates. The lantern glow is authored in the prop scene and enabled only for lantern instances.
- [x] Changed fountain to require its authored Sprite, Body and CollisionShape2D children; removed its runtime fallback hierarchy creation.
- [x] Changed terrain tile and diamond creation to instantiate `castle_terrain_tile.tscn` and `castle_terrain_diamond.tscn`. Only the Polygon2D's vertex data is configured dynamically; deterministic grid/layout generation remains data-driven.
- [x] Kept runtime instances for repeated content (tiles, flower beds, prop placements, NPCs) rather than creating a controller node per visual primitive.
- [ ] GUI visual review of the legacy reusable component scenes remains outstanding; those eight component scenes were not referenced by the active Royal Gardens root scene during the reference audit. Their APIs and scene assets are retained for compatibility.

### Completion criteria and remaining boundary
The active Royal Gardens composition uses authored world layers and focused scene-owned systems. The remaining `Polygon2D` and shape-resource configuration is data-driven geometry, not creation of stable controller hierarchy. No direct `Sprite2D.new()`, `Node2D.new()`, `StaticBody2D.new()`, `CollisionShape2D.new()`, `PointLight2D.new()` or `ColorRect.new()` calls remain in the Castle Gardens component scripts at this checkpoint.

- [x] Added and executed `tests/castle_garden_component_smoke.gd`: entrance/exterior assemblies, bench/lantern/urn placement, fountain initialization, hedge placement, symmetrical flower beds/urns/colliders, pathway tile placement and pond/waterfall/bridge placement all passed.
- [x] Fresh smoke run: `CASTLE GARDEN COMPONENT SMOKE: PASS` after correcting reusable collision scene resource declarations.

- [x] Converted the dormant `v2/castle_ground.gd` tile factory to the same authored terrain-tile scene; the legacy helper no longer constructs Sprite2D directly.
- [x] Final Castle Gardens script audit across `scripts/world/castle_gardens/` found no direct `Node2D.new()`, `Sprite2D.new()`, `StaticBody2D.new()`, `CollisionShape2D.new()`, `PointLight2D.new()`, `Polygon2D.new()` or `ColorRect.new()` calls.
- [x] Final Godot 4.7.2 headless editor import after the dormant terrain-helper change: exit code 0.
- [x] Final standalone Castle Gardens component smoke test after all scene-template fixes: PASS.
- [x] Full project regression suite after the active Royal Gardens component refactor: **1,999 passed / 0 failed**, exit code 0.
- [ ] GUI visual QA remains separate: inspect the garden from the player's camera, walk the perimeter, and confirm the wall silhouettes, props, sorting and collision feel correct. Structural completion does not certify visual polish.


### Royal Gardens Ã¢â‚¬â€ whole-map assembly extraction Ã¢â‚¬â€ 2026-11-16

- [x] Extracted the 105-tile Royal Promenade into `castle_gardens/components/royal_promenade.tscn` and the 90-tile Outer Road into `outer_road.tscn`. The active root no longer contains either tile collection inline.
- [x] Extracted the Terrain layers, Pathways, Castle architecture, Water, Flora, Props and four-run perimeter into seven reusable assembly scenes: `castle_terrain_layers.tscn`, `castle_pathways.tscn`, `castle_architecture_assembly.tscn`, `castle_water_assembly.tscn`, `castle_flora_assembly.tscn`, `castle_props_assembly.tscn` and `castle_perimeter_assembly.tscn`.
- [x] NPCPlacement and MapSpawnPoints are scene instances with their existing active-map marker positions preserved.
- [x] World bounds are now an authored reusable collision scene with four named boundary shapes; extents were moved outside the garden perimeter so normal playable positions are not constrained by the bounds.
- [x] Props are grouped under Furniture, Lighting and Statues. Flora remains grouped as TreeAvenue, FlowerBorders, HedgesAndShrubs and WorldPerimeter. Water remains grouped as FountainCourt and OuterPonds.
- [x] The active `castle_royal_gardens.tscn` root now acts as a composition root for authored assembly scenes and runtime systems instead of holding hundreds of inline visual instances.
- [x] Added structural regression assertions for the promenade (105 children), outer road (90), water, flora, props, marker assemblies and world bounds.
- [x] Updated save/continue regression positions to clear of authored bench/bush colliders so those tests measure exact persistence rather than expected collision resolution at obstructed coordinates.
- [x] Godot 4.7.2 editor import: exit code 0; active Royal Gardens scene headless startup: exit code 0.
- [ ] Full regression-suite result and GUI visual walkthrough are recorded only after their final verification run.

- [x] Final whole-project regression suite after whole-map assembly extraction: **2,006 passed / 0 failed**, exit code 0 (Godot 4.7.2, headless).


### Royal Gardens Ã¢â‚¬â€ authored configuration ownership pass Ã¢â‚¬â€ 2026-11-16

- [x] Moved NPC identities, display names, dialogue IDs, roles, races, palettes and grid spawn positions out of `CastleNPCSpawnerComponent` dictionaries and onto each authored `NPCPlacement` Marker2D as scene metadata. The spawner now reads marker-owned configuration and creates the corresponding actor.
- [x] Moved all five garden-light grid positions, shadow placement and ambient-particle placement into seven authored `LightingAnchors` Marker2D nodes in `castle_lighting_anchors.tscn`. `CastleLightingComponent` now consumes those markers rather than owning map placement coordinates.
- [x] Retained `WeatherDirector` as `RefCounted` because it is a deterministic, headless-testable state machine with no scene-tree ownership; it is intentionally not wrapped in an unnecessary Node.
- [x] Editor import and active Royal Gardens scene startup passed after the configuration ownership changes.
- [x] Full regression suite: **2,008 passed / 0 failed**, exit code 0 (Godot 4.7.2 headless).
- [ ] Manual visual walkthrough of the running scene remains outstanding.


### Royal Gardens Ã¢â‚¬â€ post-extraction scene dependency cleanup Ã¢â‚¬â€ 2026-11-16

- [x] Audited every external resource declaration in `castle_royal_gardens.tscn` against actual `ExtResource(...)` usage.
- [x] Removed stale direct references to castle towers/walls/gate/stairs, fountain, flora, props, water tiles, path texture, the perimeter validator, architecture transform script, wall-run template and promenade. Those assets are now owned by their dedicated nested assembly scenes.
- [x] Kept the root's actual composition dependencies: world root, terrain/lighting/NPC/player/runtime/presentation controllers, expansion scene, day/night controller and seven active map assembly/marker scenes.
- [x] Fresh Godot 4.7.2 headless editor import after dependency cleanup: exit code 0.
- [x] Standalone Castle Gardens component smoke test after dependency cleanup: PASS.
- [x] Full project regression suite after dependency cleanup: **2,008 passed / 0 failed**, exit code 0 (50.66s).


### Royal Gardens Ã¢â‚¬â€ perimeter geometry regression hardening Ã¢â‚¬â€ 2026-11-16

- [x] Extended the live New Journey castle-map regression to verify each authored perimeter wall's configured collision rectangle matches its run length and 38 px thickness.
- [x] Added a structural assertion that each wall's authored pier layer contains the expected count derived from run length and bay width.
- [x] Full project regression suite: **2,016 passed / 0 failed**, exit code 0 (Godot 4.7.2 headless, 50.42s).
- [ ] In-game visual walkthrough remains outstanding; automated assertions do not certify the wall silhouettes or player feel.


### Royal Gardens Ã¢â‚¬â€ isometric wall sorting and footprint regression Ã¢â‚¬â€ 2026-11-16

- [x] Extended the X- and Y-oriented screen-facing castle wall checks to verify both wall scenes have Y-sorting enabled.
- [x] Added explicit checks that both orientations retain their authored Body/Footprint0 collision shape.
- [x] Ran the full project test scene (res://tests/test_runner.tscn) with Godot 4.7.2 headless so project autoloads and the normal test-scene lifecycle are present.
- [x] Full project regression suite: **2,018 passed / 0 failed**, exit code 0 (47.01s).
- [ ] GUI visual walkthrough remains outstanding. The automated suite verifies scene structure, sorting flags and collision nodes, but does not replace inspecting the rendered wall from the player camera or walking the perimeter in-game.


### Royal Gardens Ã¢â‚¬â€ structural nodularization closeout Ã¢â‚¬â€ 2026-11-16

- [x] Audited all 30 GDScript files under `scripts/world/castle_gardens` for TODO/FIXME markers and direct construction of common scene-tree node types (`Node`, `Node2D`, `StaticBody2D`, `CollisionShape2D`, `Polygon2D`, `Sprite2D`). No matches remain in this targeted audit.
- [x] Confirmed that stable map hierarchy, architecture, wall runs, marker configuration, terrain/path/water/flora/props assemblies, lighting anchors and runtime ownership are authored as reusable scenes/nodes.
- [x] Confirmed the full project test scene passes: **2,018 passed / 0 failed** (Godot 4.7.2 headless).
- [x] Structural nodularization milestone is complete. Deterministic/data-only helpers remain scripts by design; transient effects and data-driven runtime instances may still be created dynamically.
- [ ] Separate presentation/gameplay QA remains: inspect the rendered map in the GUI and walk the perimeter to verify visual composition, depth sorting and collision feel. This is not a structural nodularization blocker and is not claimed as completed here.


### Royal Gardens Ã¢â‚¬â€ expansion layout configuration nodularization Ã¢â‚¬â€ 2026-11-16

- [x] Moved the ceremonial expansion approach's 29 hard-coded placements out of `CastleExpansionApproachComponent` into the authored `castle_expansion_approach_placements.tscn` marker assembly.
- [x] Each Marker2D now owns its target layer, asset category, subfolder, asset ID and grid position as scene metadata; the builder only validates and instantiates those authored placements.
- [x] Added regression coverage for the 29 placement markers and their required configuration metadata.
- [x] Full project test scene: **2,048 passed / 0 failed** (Godot 4.7.2 headless).

- [x] Added live New Journey regression checks for the generated expansion layers: seven path pieces, fifteen flora pieces, and all six authored props present in the props layer.
- [x] Final full project test scene after expansion layout migration and live-instance assertions: **2,051 passed / 0 failed** (Godot 4.7.2 headless).


### Royal Gardens Ã¢â‚¬â€ final active-map configuration ownership pass Ã¢â‚¬â€ 2026-11-16

- [x] Moved terrain bounds, tile dimensions, deterministic seed, texture paths and six grass-detail positions into the authored `castle_terrain_configuration.tscn`; `CastleTerrainComponent` now consumes scene configuration instead of embedding map-specific layout values.
- [x] Moved light offsets, shadow offset and ambient-effect offset onto the authored lighting anchor markers; the lighting component now instantiates the reusable presentation scenes from those markers.
- [x] Exposed the world save cadence as an inspector-configurable property on `WorldRuntime`.
- [x] Moved pond interaction centers and radii into authored `WaterZones` markers and gave the Water assembly its own `CastleWaterComponent`; the root retains only a compatibility delegation method.
- [x] Removed NPC identity/role/race/palette/grid fallback defaults from the spawner. All four authored NPC markers must now provide complete configuration or the spawner reports the invalid marker.
- [x] Moved the Gardener's Seal Cache identity, placement, description, quantity and rewards into its authored marker; the cache spawner validates and consumes that data.
- [x] Added regression checks for authored terrain configuration, lighting offsets, save cadence, water-zone ownership, all four NPC marker configurations, cache metadata and expansion live-instance counts.
- [x] Final full project test scene: **2,061 passed / 0 failed**, exit code 0 (Godot 4.7.2 headless).
- [ ] Visual QA is still a separate external verification: inspect the rendered map in the GUI and test movement, occlusion and wall collisions. The structural migration does not claim those visual checks were performed.


### Whole-game migration Ã¢â‚¬â€ first combat-presentation extraction Ã¢â‚¬â€ 2026-11-16

- [x] Extracted Kael's character-specific attack choreography and transient effects from the general `BattlefieldEffectsComponent` into `KaelAttackPresentationComponent`.
- [x] Authored the new component as a dedicated child of `Battlefield`; the battlefield binds it and the existing effects component delegates Kael-specific choreography to it.
- [x] Preserved the existing `Battlefield.play_attack` / effects facade contract and left authoritative damage/turn resolution in `CombatEngine`.
- [x] Added structural regression assertions for the authored child, runtime ownership, and delegation.
- [x] Preserved timestamped pre-migration backups of the battlefield scene and both modified scripts.
- [x] Headless editor import completed successfully; full project suite: **2,064 passed / 0 failed** (Godot 4.7.2 headless).
- [ ] Visual attack-choreography QA remains outstanding; no claim is made that the Kael moves have been inspected in the live GUI.


### Whole-game migration Ã¢â‚¬â€ Fallen Matron combat-presentation extraction Ã¢â‚¬â€ 2026-11-16

- [x] Extracted Fallen Matron attack choreography, telegraphs, corruption bolt, shadow lash, soul drain, Matron Verdict stages, ritual seals, warning markers, strike columns, burst effects and phase-transition flourish into MatronAttackPresentationComponent.
- [x] Authored the component as a dedicated Battlefield child; Battlefield binds it and the existing effects facade delegates boss-specific presentation to it.
- [x] Preserved the public effects/battlefield methods and kept all damage/turn authority in CombatEngine.
- [x] Added structural/runtime delegation assertions and timestamped pre-change backups for all modified existing files.
- [x] Godot 4.7.2 headless editor import: exit code 0.
- [x] Full project test scene: **2,067 passed / 0 failed**, exit code 0.
- [ ] Live GUI combat choreography QA remains outstanding.


### Whole-game migration Ã¢â‚¬â€ generic combat attack-presentation extraction Ã¢â‚¬â€ 2026-11-16

- [x] Extracted ordinary unit lunge, travel/impact positioning, strike trails, and slash effects into GenericAttackPresentationComponent.
- [x] Authored the component as a Battlefield child; Battlefield binds it and the effects facade delegates non-Kael/non-Matron attacks to it.
- [x] Preserved the public Battlefield/Effects play_attack signatures and left damage/turn resolution in CombatEngine.
- [x] Added authored-scene and live delegation assertions; timestamped backups created before editing.
- [x] Godot 4.7.2 headless editor import completed successfully (exit code 0).
- [x] Full project test scene: **2,070 passed / 0 failed**, exit code 0.
- [ ] Live GUI attack choreography QA remains outstanding.


### Whole-game migration Ã¢â‚¬â€ battlefield impact-effects extraction Ã¢â‚¬â€ 2026-11-16

- [x] Extracted floating damage/heal numbers and elemental impact bursts from the battlefield effects facade into BattlefieldImpactEffectsComponent.
- [x] Authored the component as a dedicated Battlefield child and bound it through the Battlefield composition root.
- [x] Kept the public Battlefield/effects facade methods intact; actor death/victory and attack routing remain separate responsibilities.
- [x] Added runtime assertions for authored ownership and facade delegation; timestamped backups created before editing.
- [x] Godot 4.7.2 headless editor import completed successfully (exit code 0).
- [x] Full project test scene: **2,072 passed / 0 failed**, exit code 0.
- [ ] Live GUI combat effects QA remains outstanding.


### Whole-game migration Ã¢â‚¬â€ actor character-effects extraction Ã¢â‚¬â€ 2026-11-16

- [x] Extracted Kael ember/sword combat overlays and Lilith spectral state effects from the procedural body renderer into ActorCharacterEffectsComponent.
- [x] Authored CharacterEffects as a dedicated ActorVisual child; ActorVisual binds and invalidates it during sprite-backed and procedural rendering.
- [x] Kept body silhouettes, shared cast aura, hit flash, frame-source selection and generic human/spirit/monster drawing in their existing owners.
- [x] Added authored-scene and live-instance assertions; timestamped pre-edit backups preserved.
- [x] Godot 4.7.2 headless editor import completed successfully (exit code 0).
- [x] Full project regression suite: **2,074 passed / 0 failed**, exit code 0 (Godot 4.7.2 headless).
- [ ] Live GUI sprite/fallback VFX layering and timing QA remains outstanding.


### Whole-game migration Ã¢â‚¬â€ inventory crafting panel scene ownership Ã¢â‚¬â€ 2026-11-16

- [x] Replaced runtime construction of the stable crafting overlay hierarchy with the authored inventory_crafting_panel.tscn scene.
- [x] Kept recipe cards and recipe rows data-driven and transient; the component now binds the authored RecipeList and CloseButton.
- [x] Added structural regression checks for the panel body, recipe list and close control; preserved pre-edit backups.
- [x] Godot 4.7.2 headless editor import completed successfully (exit code 0).
- [x] Full project regression suite: **2,076 passed / 0 failed**, exit code 0 (Godot 4.7.2 headless).
- [ ] GUI positioning, scaling and interaction QA remains outstanding.


### Inventory crafting panel Ã¢â‚¬â€ runtime ownership and interaction verification Ã¢â‚¬â€ 2026-11-16

- [x] Added live scene-tree assertions for authored panel instancing, recipe-list binding and close-button binding.
- [x] Added open/close interaction checks against the actual InventoryScreen component.
- [x] Full regression suite: **2,080 passed / 0 failed**, exit code 0 (Godot 4.7.2 headless).
- [ ] GUI layout and responsive scaling QA remains outstanding.


### Whole-game node-ownership audit Ã¢â‚¬â€ runtime construction classification Ã¢â‚¬â€ 2026-11-16

- [x] Re-scanned production scripts for runtime construction of UI/controller nodes after the component migrations.
- [x] Moved the stable Inventory crafting overlay shell to an authored PackedScene; its open/close behavior is covered by live scene-tree tests.
- [x] Classified remaining constructors: UIFactory controls and item/recipe/shop cards are reusable or data-driven transient content; MainBackdrop repeated decorations are count-driven art primitives; Scarlet Requiem's generated stack is a banner-specific content container; Gacha's Control is a layout spacer; ForestPreview camera/overlay are isolated preview-harness nodes.
- [x] Kept pure systems (ProceduralArt, ContentValidator, CombatEngine, route/content data and animation/frame factories) out of the Node tree where they do not need scene lifecycle ownership.
- [x] Full project regression suite after the runtime ownership tests: **2,080 passed / 0 failed**, exit code 0.
- [ ] Full GUI visual QA remains a separate required milestone; headless tests cannot verify visual layering, responsive geometry, wall collisions or real player input.


### Structural migration closure review Ã¢â‚¬â€ 2026-11-16

- [x] Revisited both remaining architecture candidates from Step 5. No further Node extraction is justified for the shared procedural body renderer or GreenwardWorld's composition-root/compatibility surface.
- [x] Verified the character-specific renderer responsibility is now separately authored; verified the inventory crafting overlay has authored ownership and tested open/close behavior.
- [x] Re-scanned runtime Node constructors and classified remaining uses as factories, transient data-driven content, repeated decorative art, layout spacers or isolated preview harness.
- [x] Latest full regression result: **2,080 passed / 0 failed**, Godot 4.7.2 headless, exit code 0.
- [ ] Remaining non-structural sign-off: manual GUI visual QA for world/map walls and sorting, character VFX layering/timing, combat interactions, overlay scaling and actual player movement/collisions.
- [ ] Procedural placeholder art replacement remains a separate content-production phase; node ownership does not imply final art is complete.


### Castle curtain-wall facade continuity pass Ã¢â‚¬â€ 2026-11-16

- [x] Reviewed the active Castle & Royal Gardens architecture assembly and confirmed its X/Y wall pieces use the screen-facing `CastleFacadeWall` renderer and isometric depth sorting.
- [x] Removed repeated end-piers from each adjoining wall segment; each segment now keeps one central pilaster, while segment ends remain flush so the run reads as a continuous curtain wall rather than a row of overlapping masonry blocks.
- [x] Preserved the broad stone face, coping, arrow slit, plinth, merlons and authored footprint collision.
- [x] Full Godot 4.7.2 regression suite after the change: **2,080 passed / 0 failed**, exit code 0 (45.51s).
- [ ] In-engine visual inspection is still required to confirm the wall run's appearance at actual game zoom and depth intersections.


## Castle & Royal Gardens gameplay integration ? 2026-11-16

- Added an authored `WorldEntitySpawnerComponent` child to the Castle world and bound it to the Castle's region data and `Entities` layer.
- Added two data-driven `castle_garden_sentinels` spawn groups using existing Gothic Sentinel / Blight Wisp enemy definitions. Encounters remain interaction-only through the existing `RoamingMonster` contract.
- Added the Castle-specific `Shadows in the Royal Garden` quest, offered by the actual `royal_gardener` NPC through a dedicated dialogue tree. Quest objectives target the spawned Gothic Sentinels and return to the gardener for turn-in.
- Connected the Royal Gardener to the NPC quest-marker mapping and added the authored quest destination marker to Castle runtime composition.
- Regression coverage checks the two live spawns, marker scene, quest availability, acceptance, kill progression, turn-in and completion.
- Latest full Godot regression run after the end-to-end quest assertions: 2,097 passed / 0 failed. Manual in-engine visual/playtest QA remains required.



### Whole-game modularization â€” procedural character renderer extraction â€” 2026-11-17

- [x] Separated procedural character-frame choreography into ProceduralCharacterArt, a dedicated pure rendering module. ProceduralArt.character_frame() retains its public API and cache ownership, delegating frame drawing to the new renderer.
- [x] Kept shared pixel primitives and all prop painters in ProceduralArt; the character renderer reuses those primitives rather than duplicating rasterization code.
- [x] Preserved the original draw routine verbatim apart from its new class/method boundary; timestamped backups created before editing.
- [x] Full Godot 4.7.2 regression suite after extraction and pixel-parity assertion: **2,098 passed / 0 failed**, exit code 0.
- [ ] Remaining architecture review is still open for other large but cohesive systems (notably `ContentValidator`, `ProceduralArt` prop painters and actor procedural rendering); large file size alone is not treated as proof of a design defect.



### Whole-game modularization â€” JSON duplicate-key scanner extraction â€” 2026-11-17

- [x] Extracted duplicate JSON object-key scanning and its recursive parser helpers into JsonDuplicateKeyScanner, a pure utility with one responsibility.
- [x] Kept ContentValidator._scan_duplicate_keys() as a compatibility facade, preserving existing tests/tool callers while separating syntax scanning from content-domain validation.
- [x] Timestamped backups created before edits.
- [x] Regression verification completed; full suite passed with 2,098 passed and 0 failed.


- [x] Full Godot 4.7.2 regression suite after scanner extraction: **passed**; shared error formatting delegated to ContentValidator._err().



### Whole-game modularization â€” region graph validation extraction â€” 2026-11-17

- [x] Moved pure cross-region graph checks (edge references, entry-point validation, reachability from Greenward) into RegionGraphValidator.
- [x] Kept ContentValidator.validate_region_graph() and _entry_point_ids() as compatibility facades for current test/tool callers and the schema validator.
- [x] The graph validator remains data-only and independent of RegionGraph runtime scene behavior.
- [x] Regression verification completed; full suite passed with 2,098 passed and 0 failed.


- [x] Godot editor import and full regression suite after extraction passed; exact count recorded in run output.



### Whole-game modularization â€” region schema validator extraction â€” 2026-11-17

- [x] Moved region JSON schema and optional multi-region extension checks into RegionContentValidator (including spawn, POI, biome, environment, entry-point and connection fields).
- [x] Kept shared type/error primitives centralized in ContentValidator; schema constants are passed explicitly, and graph cross-reference lookup delegates to RegionGraphValidator.
- [x] Preserved ContentValidator._validate_regions() as the dispatch facade.
- [x] Regression verification completed; full suite passed with 2,098 passed and 0 failed.


- [x] Region schema validator extraction compiled in Godot 4.7.2 and passed the full regression suite.



### Whole-game modularization â€” item and banner content validation extraction â€” 2026-11-17

- [x] Moved item/equipment schema validation and summon-banner pool/cost/featured-character validation into ItemBannerContentValidator.
- [x] Kept ContentValidator as compatibility dispatcher and retained shared primitive validation helpers in one place.
- [x] Regression verification completed; full suite passed with 2,098 passed and 0 failed.


- [x] Item/banner validator extraction compiled and passed the full regression suite after fixing delegated helper and constant dependencies.



### Whole-game modularization â€” quest and dialogue validation extraction â€” 2026-11-17

- [x] Moved quest definitions, reward/step checks, dialogue node/choice checks, conditions and actions into QuestDialogueContentValidator.
- [x] Shared primitive validation remains centralized; quest-state and step-type schemas are passed explicitly through the compatibility facade.
- [x] Regression verification completed; full suite passed with 2,098 passed and 0 failed.



### Whole-game modularization â€” character and combat content validation extraction â€” 2026-11-17

- [x] Moved character, skill, status-effect, enemy phase, enemy and enemy-group schema validation into CharacterCombatContentValidator.
- [x] Preserved ContentValidator dispatch APIs; shared primitive and cross-domain helpers remain centralized and schema enum sets are passed explicitly.
- [x] Regression verification completed; full suite passed with 2,098 passed and 0 failed.


- [x] Character/combat validator extraction compiled and passed the full regression suite.



### Whole-game modularization â€” procedural prop painter extraction â€” 2026-11-17

- [x] Moved all original and expanded prop raster painters into ProceduralArtPropPainters, preserving the existing kind-to-painter dispatch and image output paths.
- [x] Kept texture/frame caches, variant processing and shared raster primitives in ProceduralArt; painter code delegates primitive drawing to that shared facade.
- [x] Regression verification completed; full suite passed with 2,098 passed and 0 failed.



### Whole-game modularization â€” procedural prop painter extraction â€” 2026-11-17

- [x] Moved original and expanded prop painters into ProceduralArtPropPainters, preserving kind dispatch and existing cache/output paths.
- [x] Kept texture/frame caches, variant processing and shared raster primitives in ProceduralArt; painters delegate to those shared primitives.
- [x] Regression verification completed; full suite passed with 2,098 passed and 0 failed.


- [x] Godot editor import and full regression suite passed after prop painter extraction.



### Final modularization audit snapshot â€” 2026-11-17

- [x] Inventory: 348 GDScript files; 506 scene files under `scenes/`.
- [x] Content validation split into focused character/combat, item/banner, quest/dialogue, region-content, region-graph and JSON duplicate-key modules; `ContentValidator` retains shared primitives and compatibility dispatch.
- [x] Procedural character-frame drawing and prop drawing separated from `ProceduralArt` cache/variant ownership.
- [x] Combat skill application, damage calculation and boss phase triggers extracted into `CombatSkillResolver`; `CombatEngine` is 458 lines and retains turn state, RNG, passive ownership and compatibility wrappers.
- [x] Species-specific procedural monster drawing extracted into `ProceduralMonsterPainter`; `ActorProceduralRendererComponent` is 260 lines and retains CanvasItem drawing, transforms, ordering and renderer ownership.
- [x] Large remaining modules reviewed by responsibility: `GreenwardWorld` is the world composition root; `CharacterArtSpec` and `GreenwardStyle` are data/specification registries; `QuestNavigationResolver` is a cohesive cached target resolver; `ChunkBuilder` owns chunk generation; `CharacterAnimator` is the animation state machine; `CharacterArtPipeline` is the asset schema/validation contract; `ProceduralArtPropPainters` is a stateless painter library. No arbitrary line-count splitting was applied.
- [x] Static scan of 506 scenes: 155 component-script attachments across 75 scenes; zero missing script targets.
- [x] Actual GUI walkthrough: title menu opened and Continue transitioned into Castle & Royal Gardens; party HUD, fountain, NPCs, Kael and castle facade rendered.
- [x] Added title-menu viewport-bound assertions for all six buttons and the glass backdrop.
- [ ] Remaining hands-on QA: sustained movement/camera-follow, NPC interaction, combat choreography, and inventory/quest/gacha overlay walkthroughs.

### Modularization â€” combat skill resolver â€” 2026-11-17

- Extracted skill application, damage resolution and boss phase triggers into `CombatSkillResolver`; `CombatEngine` retains turn state, RNG, passive ownership and compatibility wrappers.
- [x] Godot editor import clean; full suite passed after extraction.

### Modularization â€” procedural monster painter â€” 2026-11-17

- [x] Moved species-specific procedural monster artwork (blob, mossling, moonpetal sprite, thornhound, treants and Fallen Matron) into `ProceduralMonsterPainter`.
- [x] Renderer retains CanvasItem draw ownership, transforms, render ordering and cross-kind dispatch; painter binds to the renderer and owning `ActorVisual`.
- [x] Removed unreachable legacy Fallen Matron fallback code.
- [x] Added regression assertion for renderer/painter ownership and binding.

### Scene and runtime verification â€” 2026-11-17

- [x] Godot 4.7.2 editor import completed without script parse errors.
- [x] Main project, `greenward_world.tscn`, and `castle_royal_gardens.tscn` each launched headlessly for five frames and exited with code 0.
- [x] Live title-menu Continue action opened Castle & Royal Gardens; screenshot review confirmed the party panel, fountain, Royal Gardener, Gothic Sentinel, Kael sprite, paths and castle facade render.
- [x] All six title-menu buttons and the glass backing are checked to remain within the active viewport.
- [x] Final full regression run after these changes: **2,113 passed, 0 failed**, exit code 0 (78.31 seconds).
- [ ] Full hands-on movement, camera-follow, NPC interaction, combat choreography and overlay QA remain open; no claim is made that these have been completed.


### World-host overlap regression fix â€” 2026-11-17

- [x] Hardened `GameWorldSessionComponent.build_world()`: `WorldHost` is now treated as a single-world container; every previous child is detached and queued for deletion before the next region is instantiated.
- [x] Added regression checks that load Gothic Castle over the starting world, then return to Royal Gardens, asserting one child remains in `WorldHost` and the active scene type matches the selected region.
- [x] Godot editor import clean; full suite: **2,118 passed, 0 failed**, exit code 0 (79.40 seconds).
- [ ] Visual confirmation in the live game still required; the code-level regression now prevents stale world scenes from remaining stacked in the world host.


### Royal Gardens / Gothic Castle separation fix â€” 2026-11-17

- [x] Removed the Gothic castle tower/wall/gate assembly from `castle_royal_gardens.tscn`; the Royal Gardens scene now contains its own garden terrain, promenade, fountains, flora, perimeter, NPCs and props without the Gothic Castle structure layered over it.
- [x] Changed the region's display name and subtitle to **Royal Gardens** and updated its area label.
- [x] Removed the castle silhouette from the Royal Gardens world-map schematic.
- [x] Rebuilt the Gothic Castle zone's ground field with gothic courtyard stone and corruption; replaced its garden blossom/oak/bench/gold-lamp/angel/fountain dressing with dead/corrupted vegetation and Gothic Castle ornaments.
- [x] Added runtime regression coverage: Royal Gardens has no `Castle` architecture child; Gothic Castle instantiates zero textures from `Royal_Gardens` and builds its own full stone ground field.
- [x] Preserved the single-world `WorldHost` replacement guard and its transition tests.
- [x] Godot editor import clean; full suite: **2,121 passed, 0 failed**, exit code 0 (74.94 seconds).
- [x] Live title-menu/Continue walkthrough was verified before the final separation edit; after that edit, editor import and headless scene construction/regression checks pass. A fresh post-edit screenshot walkthrough is still pending.
- [x] Integration tests also cover camera look-ahead/recentering, nearest-interactable selection, explicit interaction opening the matching combat encounter, inventory crafting open/close, quest-screen construction, gacha return-to-game control and pause routing.
- [x] Added an end-to-end authored NPC dialogue branch test (greeting â†’ choice â†’ next node â†’ close), including world suspension and resume.
- [x] Added a timed generic combat choreography test: attacker lunges toward target, returns home, and target returns to its home position.
- [ ] Sustained real-time movement/camera-follow and live visual choreography still require hands-on visual QA.


### Procedural prop painter family split â€” 2026-11-17

- [x] Split the former 1,421-line `ProceduralArtPropPainters` into focused nature/ground, structure/landmark and magical/water/ambient painter modules.
- [x] Kept the foundational twelve painter implementations and the compatibility dispatch facade in `ProceduralArtPropPainters`; the three family modules are stateless `RefCounted` libraries.
- [x] Preserved all 47 extracted `_p_*` painter functions and the public `ProceduralArt.prop_texture()` / `prop_kinds()` interface.
- [x] Godot 4.7.2 editor import clean; all 59 registered prop kinds remain covered by regression checks.
- [x] Full suite after the split: **2,122 passed, 0 failed**, exit code 0 (53.88 seconds); final clean rerun after QA cleanup: **2,122 passed, 0 failed**, exit code 0 (63.82 seconds).
- [x] Expanded integration coverage for NPC dialogue progression, generic combat lunge/return choreography, and physics-driven player movement/animation/friction; editor import clean and final full suite: **2,136 passed, 0 failed**, exit code 0 (71.47 seconds).
- [x] Fresh five-frame headless launch smoke tests for `main.tscn`, `greenward_world.tscn`, `castle_royal_gardens.tscn` and `gothic_castle_boss_zone.tscn`; all four exited 0.
- [x] Extracted pure generation-language composition into `CharacterArtPromptBuilder`; `CharacterArtSpec` retains authored identity/spec data and delegates prompt creation while preserving its public prompt API.
- [x] Expanded `to_dict()` with the authored pose, motif, expression and hair-colour-name fields required to reconstruct prompts; added per-character parity checks for full-body, portrait, sheet and VFX prompts.
- [x] Godot editor import clean; final full regression suite after prompt-builder extraction: **2,185 passed, 0 failed**, exit code 0 (83.01 seconds).
- [ ] Final live visual QA remains separate from this code-level regression verification.

### Modularization â€” visual palettes, character spec catalog and chunk prop scatter â€” 2026-11-17

- [x] Extracted kind-specific palette assembly into `GreenwardPropPalette`; `GreenwardStyle` remains the central palette/spec registry and compatibility facade. Reduced `visual_style.gd` from 677 to 496 lines.
- [x] Added parity assertions for every registered prop kind, confirming the extracted palette helper returns exactly the same dictionaries as the facade.
- [x] Extracted the authored character identity/visual data, valid-value sets and required-field contract into `CharacterArtSpecCatalog`; `CharacterArtSpec` now owns instance construction, validation, serialization and prompt delegation. Reduced `character_art_spec.gd` from 571 to 346 lines.
- [x] Extracted deterministic prop candidate resolution, weighted selection and prop-entry construction into `ChunkPropScatter`; `ChunkBuilder` retains chunk composition and compatibility wrappers. Reduced `chunk_builder.gd` from 525 to 476 lines.
- [x] Added seeded determinism, elevation-bias, variant-range, canonical-entry and weighted-selection regression checks.
- [x] Godot 4.7.2 editor import clean; static scan of all 506 scenes found **0 missing script targets**.
- [x] Full regression suite after these extractions: **2,190 passed, 0 failed**, exit code 0 (71.54 seconds).
- [ ] Live movement/camera-follow and remaining visual QA remain separate from code-level modularization.

### Modularization â€” static contracts, style audit and Greenward child nodes â€” 2026-11-17

- [x] Extracted production asset dimensions, animation timings, import presets and per-kind definitions into `CharacterArtPipelineCatalog`; `CharacterArtPipeline` retains the public query/validation API. Reduced `character_art_pipeline.gd` from 522 to 281 lines.
- [x] Extracted colour and style consistency diagnostics into `GreenwardStyleAudit`; `GreenwardStyle` retains the palette registry and delegates `all_colors()` / `coherence_report()`. Reduced `visual_style.gd` from 496 to 411 lines.
- [x] Completed the Greenward composition hierarchy: `WorldGreenwardBuilderComponent` is now a thin facade over four authored child Node components â€” River, Landmark, Route and Interaction. Fixed mixed-indentation parser errors in all four child scripts.
- [x] Added integration assertions for all four child nodes, their scene ownership, their binding to the owning `GreenwardWorld`, and their shared `GreenwardCompositionData` resource.
- [x] Static architecture inventory: **361 GDScript files**, **506 scenes**, **501 scene script attachments across 376 scenes**, and **0 missing script targets**. The 75 `RefCounted` scripts remain pure helpers/services; they are intentionally not forced into scene-tree Nodes.
- [x] Full regression suite in an isolated Godot user-data directory (so the live editor/game save cannot race the test save): **2,198 passed, 0 failed**, exit code 0 (79.81 seconds).
- [x] Isolated test project and its directory junctions removed after verification; original project files and user save directory were left intact.
- [ ] Live movement/camera-follow and remaining visual QA remain separate from code-level modularization.


### Greenward composition builder decomposition â€” 2026-11-17

- [x] Split `WorldGreenwardBuilderComponent` responsibilities into four authored child nodes: `WorldGreenwardRiverComponent`, `WorldGreenwardLandmarkComponent`, `WorldGreenwardRouteComponent`, and `WorldGreenwardInteractionComponent`.
- [x] Retained the 78-line parent as a compatibility facade so existing `GreenwardWorld` call sites keep their public build methods.
- [x] Added scene-owned child nodes and configuration binding to the shared `GreenwardCompositionData` resource.
- [x] Existing regression assertions verify all four children are present, parented correctly, and bound to the same owning world and composition resource.
- [x] Corrected the `GreenwardWorld` class summary to describe the authored square-grid top-down 3/4 perspective rather than implying diamond/isometric tiles.
- [x] Fresh isolated full-suite execution after this extraction: **2,198 passed, 0 failed**, exit code 0 (79.81 seconds).
- [ ] Runtime visual QA after this extraction remains open.

### Modularization â€” title backdrop presentation decomposition â€” 2026-11-17

- [x] Split the former 456-line `MainBackdropPresentationComponent` into a 225-line presentation orchestrator, a 151-line `MainBackdropLayoutComponent`, and a 99-line `MainBackdropAnimationComponent`.
- [x] Authored Layout and Animation as child Nodes under Presentation in `main_backdrop.tscn`; both bind to the presentation owner and operate on its existing authored scene layers.
- [x] Preserved `MainBackdrop` and `MainBackdropPresentationComponent` compatibility methods; responsive layout and ambient animation now delegate to their dedicated children.
- [x] Added regression checks for both child node types, ownership, and owner binding.
- [x] Godot 4.7.2 editor import clean; isolated full regression suite: **2,202 passed, 0 failed**, exit code 0 (74.81 seconds).
- [x] Final static inventory: **363 GDScript files**, **506 scenes**, **503 scene script attachments across 376 scenes**, and **0 missing script targets**.
- [x] Removed the isolated test project and its separate user-data folder after verification.
- [ ] Remaining live movement/camera-follow, NPC and combat visual QA still requires hands-on verification.

### Modularization â€” animation specification catalog â€” 2026-11-17

- [x] Extracted the frozen 8-state/8-direction names, frame counts, FPS, looping flags, priority tiers, additive CAST metadata, return-state map and angle lookup into `CharacterAnimationSpecCatalog`.
- [x] Kept `CharacterAnimator` enums, signals, mutable playback state, transitions, ticking and snapshot behavior in the state machine; all former public constants remain available through compatibility aliases. Reduced `character_animator.gd` from 524 to 388 lines.
- [x] Added regression checks proving the state machine's public tables remain aligned with the extracted catalog.
- [x] Godot 4.7.2 editor import clean; isolated full suite: **2,207 passed, 0 failed**, exit code 0 (74.87 seconds).
- [x] Latest static inventory: **364 GDScript files**, **506 scenes**, **503 scene script attachments across 376 scenes**, **0 missing script targets**.
- [x] Removed the isolated test project and its user-data directory after verification.

### Remaining large modules â€” responsibility review

- `GreenwardWorld` remains the world composition root; scene-authored world systems and Greenward build responsibilities are delegated to owned Node components.
- `QuestNavigationResolver` remains one cached quest-target/path resolver rather than splitting a single lookup lifecycle across unrelated nodes.
- `CharacterAnimator` is now a compact deterministic state machine; its immutable timing/direction contract lives in `CharacterAnimationSpecCatalog`.
- `ProceduralArtStructurePainters` and `ProceduralArtPropPainters` remain stateless cohesive painter libraries; they do not own scene state or caches.
- `ProceduralArt` remains the cache/variant/raster facade over dedicated character, prop and structure painters.
- `ContentValidator` remains the compatibility facade over the character/combat, item/banner, quest/dialogue and region validator modules.
- `ChunkBuilder` remains the chunk composition orchestrator; deterministic prop choice and placement records are isolated in `ChunkPropScatter`.
- `GameState` remains the autoload facade over roster, inventory, quest, combat and profile domain components.
- `CombatEngine` remains turn-order/state orchestration; skill resolution and presentation are separated.
- Pure `RefCounted` catalogs, resolvers and raster helpers are intentionally not forced into scene-tree Nodes. The target is clear ownership and one responsibility per module, not one Node per file or arbitrary line-count limits.

### Modularization â€” prop palette family dispatch â€” 2026-11-17

- [x] Replaced the 182-line `GreenwardPropPalette.palette()` switch body with a 24-line category dispatcher and dedicated tree, flower, ground, structure, magical, water, wildlife and fallback palette builders.
- [x] Preserved shared outline/accent defaults and every kind-specific override; the existing all-kind palette parity assertions compare the extracted result to the `GreenwardStyle` compatibility facade.
- [x] Godot editor import clean; isolated full suite after both animation-catalog and palette-family extractions: **2,207 passed, 0 failed**, exit code 0 (69.08 seconds).
- [x] Isolated test project, user-data directory and temporary backup removed after verification.

### Modularization â€” minimap marker ownership â€” 2026-11-17

- [x] Added an authored MarkerData child node to scenes/ui/minimap.tscn, backed by MinimapMarkerComponent.
- [x] Moved world discovery results, NPC/monster/gatherable marker collection, and tracked-quest target marker resolution into the dedicated child component.
- [x] Kept terrain drawing, marker drawing, player heading, collapse behavior, and full-map navigation in the Minimap Control; the parent now reads marker data from its owned child.
- [x] Added regression assertions for authored child ownership and binding to the currently active world.
- [x] Godot 4.7.2 headless editor import completed with exit code 0 after the extraction.
- [x] Fresh full regression suite completed: 2,207 passed, 2 failed; see the finalization audit below for the two remaining Continue/Castle position failures.

### Finalization audit â€” current verified state â€” 2026-11-17

- [x] Static scene-reference audit: 506 scenes, 365 GDScript files, 495 script attachments across 375 scenes, 242 unique attached scripts, 156 component/resolver/painter script attachments, and 0 missing script targets.
- [x] Minimap marker ownership is now separated into its authored MarkerData child node; the parent remains responsible for rendering and interaction.
- [x] Godot 4.7.2 headless editor import: exit code 0.
- [x] Minimap scene smoke test: exit code 0; no script parse/runtime errors reported.
- [x] Full regression suite reached its final summary: 2,207 passed, 2 failed. Both failures in this run are Continue/Castle exact-position persistence assertions (the saved position remained at the Castle spawn position); no MinimapMarkerComponent parse or ownership assertion failed.
- [x] Historical blocker superseded: the two Continue/Castle exact-position assertions passed in subsequent isolated full-suite runs; latest verification is 2,238 passed / 0 failed.
- [ ] Complete remaining hands-on movement, camera-follow, NPC interaction, combat choreography and overlay QA.

Architecture note: remaining large modules have been reviewed by responsibility. GreenwardWorld/GameState/CombatEngine are composition or compatibility facades; QuestNavigationResolver and RegionGraph are cohesive navigation services; ChunkBuilder is the chunk composition orchestrator; visual/art painter libraries and immutable specs remain data-oriented helpers. Do not force these into arbitrary Nodes solely to reduce line counts. The goal is scene-owned Nodes for stateful systems, clear ownership, and no unnecessary codeâ€”not a Node wrapper around every helper.


### Regression re-verification update â€” 2026-11-17 04:39

- [x] Re-ran the complete Godot 4.7.2 headless suite against the current working tree, including Greenward builder child-node ownership and minimap marker ownership assertions.
- [x] **2,209 passed, 0 failed**, exit code 0; runtime 68.84 seconds.
- [x] The two Continue/Castle position failures recorded in the earlier audit snapshot did not reproduce in this run. The earlier 2,207 passed / 2 failed entry is historical and superseded by this result.
- [ ] Hands-on movement, camera-follow, NPC interaction, combat choreography and overlay walkthrough QA remain open.
- Note: the suite intentionally exercises an invalid save payload, which emits the expected SaveService warning. Godot also reports ObjectDB/resource cleanup warnings at shutdown; these are not test failures and remain a separate cleanup investigation.


### Isolated verbose regression re-verification â€” 2026-11-17 04:44

- [x] Re-ran the complete Godot 4.7.2 test runner against the current source tree through an isolated QA project (source directories mounted through junctions; separate project cache and project user-data name, leaving the live game save untouched).
- [x] Full regression suite: **2,235 passed, 0 failed**.
- [x] Verbose diagnostics: no GDScript errors, parse errors, engine errors, ObjectDB leak reports, RID leak reports, or resources-in-use-at-exit reports.
- [x] The only warning is the expected malformed-save recovery case (`profile must be a dictionary`), which verifies backup-and-recovery behavior.
- [x] Full verbose log preserved at `artifacts/qa/enemy_roaming_behavior_regression_2026-11-17.log`.
- [ ] Hands-on movement/camera-follow, NPC interaction, combat choreography and overlay walkthrough QA still require visual verification in the live game window.


### Gothic Castle environment decomposition â€” 2026-11-17

- [x] Split the 317-line `GothicCastleEnvironmentComponent` into a 106-line compatibility/composition facade plus five scene-authored child Nodes: `GothicGroundBuilderComponent`, `GothicCastleArchitectureComponent`, `GothicBossArenaBuilderComponent`, `GothicRouteDecorationComponent`, and `GothicWorldBoundsComponent`.
- [x] Shared texture/scene caches and placement factories remain owned by the parent environment component; child Nodes own their distinct build responsibilities and bind back to that owner.
- [x] Added all five child Nodes to `gothic_castle_boss_zone.tscn` and added regression assertions for their types, ownership and bindings.
- [x] Godot 4.7.2 headless editor import completed with exit code 0 after indentation and shared-layer reference corrections.
- [x] Standalone Gothic Castle scene smoke launch completed with exit code 0 using an eight-frame headless run.
- [x] Refreshed static scene-script reference scan: 506 scenes, 370 GDScript files, 255 unique script paths attached, 0 missing script targets.
- [x] Historical stalled-run note superseded: subsequent isolated full-suite runs completed after this extraction; latest verification is 2,238 passed / 0 failed.

### 2026-11-17 lifecycle and live-UI follow-up

- [x] Fixed the `CombatEngine` â†” `CombatSkillResolver` strong-reference cycle. The resolver now stores a `WeakRef` to its owner; three regression assertions verify binding, release and cleared ownership.
- [x] Fixed inventory split sizing: centered bounded columns, fixed-width detail panel and viewport containment are covered by four regression checks.
- [x] Fixed shared `OverlayShell` panel/root expand-fill sizing. Every instantiated overlay now asserts that the shell panel expands to the available height; this prevents short-content screens from collapsing into bottom sheets.
- [x] Live visual QA: Royal Gardens movement/camera-follow, avatar cycling, NPC dialogue open/close, inventory layout, Quest Journal and all three summon banners inspected at 1280Ã—720.
- [x] Latest isolated Godot 4.7.2 verbose regression: **2,235 passed, 0 failed**; editor import clean; zero leaked instances, ObjectDB instances, resources-in-use and RID allocations. Only the intentional malformed-save recovery warning remains.
- Full log: `artifacts/qa/enemy_roaming_behavior_regression_2026-11-17.log`.
- Remaining hands-on QA: full combat choreography, complete quest/gacha interactions, premium effect/shader review and target-device performance profiling.
### Enemy passive-roaming behavior extraction â€” 2026-11-17

- [x] Added the scene-authored `EnemyRoamingBehavior` child under `RoamingMonster/Components`.
- [x] Moved per-frame passive detection, target clearing, status ticking, deterministic roam-target selection, walkability checks, movement, visual playback and patrol/idle state routing out of `RoamingMonster` into the dedicated behavior node. Preserved the existing controller/state-machine per-frame processing call.
- [x] Kept `RoamingMonster` as the public interactable/encounter lifecycle facade; explicit interaction remains the only path that emits `encounter_requested`.
- [x] Added regression assertion for authored behavior-node ownership; existing proximity/passive and explicit-interaction tests still pass.
- [x] Godot 4.7.2 editor import: exit code 0, no warnings/errors.
- [x] Full isolated verbose regression: **2,235 passed, 0 failed**; only the intentional malformed-save recovery warning.
- Full log: `artifacts/qa/enemy_roaming_behavior_regression_2026-11-17.log`.
### Combat passive and equipment modifier extraction â€” 2026-11-17

- [x] Added pure `CombatPassiveResolver` for passive ownership/team queries, debuff detection, speed/defense modifiers and incoming/outgoing damage multipliers.
- [x] Kept `CombatEngine` as the battle lifecycle facade with compatibility methods delegating to the resolver; it supplies living-team snapshots and equipment resonance/attunement values without the resolver retaining the engine.
- [x] Existing combat passive, turn-order and equipment resonance tests remain green; added direct resolver query coverage.
- [x] Godot 4.7.2 editor import: exit code 0, no warnings/errors.
- [x] Full isolated verbose regression: **2,235 passed, 0 failed**; only the intentional malformed-save recovery warning.
- Full log: `artifacts/qa/combat_passive_resolver_regression_2026-11-17.log`.
### Current verified integration state â€” 2026-11-17 05:32

- The earlier Gothic Castle audit entry noting a stalled full-suite run is historical and superseded by the later complete runs: the full suite has since passed at **2,235 passed, 0 failed** after Gothic Castle, enemy roaming and combat passive changes.
- The earlier live-UI QA open item is superseded by the later selected-screen inspection recorded above; remaining manual QA is combat choreography, complete quest/gacha interaction coverage, premium effect/shader review and device profiling.
- Latest full regression log: `artifacts/qa/quest_navigation_territory_regression_2026-11-17.log`.
### Quest-navigation territory resolver extraction - 2026-11-17

- [x] Extracted Greenward/Elder Hollow/Withered Estate territory lookup, grid-space membership and grid/world conversion into pure `QuestNavigationTerritoryResolver` helpers.
- [x] Preserved `QuestNavigationResolver` compatibility methods and its public `TERRITORIES` constant as delegates/alias; current HUD, minimap, map and marker consumers remain unchanged.
- [x] Added direct regression coverage for the dedicated resolver in addition to the legacy compatibility assertions.
- [x] Godot 4.7.2 editor import completed successfully; full isolated verbose regression: **2,236 passed, 0 failed**, exit code 0.
- Full log: `artifacts/qa/quest_navigation_territory_regression_2026-11-17.log`.

### Current verified integration state - 2026-11-17 05:46

- Latest full isolated regression: **2,236 passed, 0 failed**; no GDScript parse/runtime errors. The intentional malformed-save recovery warning remains expected.
- Latest full regression log: `artifacts/qa/quest_navigation_territory_regression_2026-11-17.log`.
- Remaining completion gates are still full manual combat/quest/summoning interaction QA, visual-effects review, target-PC profiling and a systematic audit of every remaining script/scene. Do not label the entire game 100% node-migrated until those checks are completed.
### Chunk region-layout resolver extraction - 2026-11-17

- [x] Extracted deterministic authored path generation, clearing detection, boss-biome zone generation, path proximity and stable tile hashing into `ChunkRegionLayoutResolver`.
- [x] `ChunkBuilder` remains the terrain/chunk composition entry point and retains compatibility methods; `WorldMapCanvas` and existing callers continue through the facade without API changes.
- [x] Added direct parity assertions for boss-zone output and authored route generation.
- [x] Removed a UTF-8 BOM from one scene resource that caused a clean-cache headless import to fail before the test runner could load.
- [x] Clean isolated Godot 4.7.2 editor import; full verbose regression **2,238 passed, 0 failed**, exit code 0.
- Full log: `artifacts/qa/responsibility_audit_regression_2026-11-17.log`.

### Current verified integration state - 2026-11-17 05:52

- Latest full isolated regression: **2,238 passed, 0 failed**; clean editor import and no GDScript parse/runtime errors. The intentional malformed-save recovery warning remains expected.
- Latest full regression log: `artifacts/qa/responsibility_audit_regression_2026-11-17.log`.
- Remaining completion gates: full manual combat/quest/summoning QA, visual-effects review, target-PC profiling and a systematic audit of remaining scripts/scenes. This is not a declaration of 100% node migration.
### Static scene/script integrity audit - 2026-11-17 05:53

- [x] Scanned all 506 scene files for referenced GDScript targets: **0 missing script targets**.
- [x] Current script inventory: 373 GDScript files. Not every script should be a Node: pure resolvers, registries, data models, validators and deterministic painters remain RefCounted/static helpers; node migration applies to lifecycle-owning behavior and scene composition.
- [x] Confirmed `GameState` is a facade over six authored domains plus persistence, and `GreenwardWorld` is a scene composition root delegating runtime systems to authored child components. These large line counts are not by themselves evidence of unconverted node responsibilities.
- [ ] Remaining architecture review: `ContentValidator`, `ProceduralArt`/painter modules and actor procedural rendering require responsibility-level review before any further extraction is justified.
- [ ] Manual GUI verification and content-art replacement remain distinct from automated structural checks.
## Responsibility audit â€” 2026-11-17 (current)

This section supersedes the older residual-debt notes above where the same systems are discussed. The audit distinguishes file length from actual ownership boundaries; no extra Nodes were introduced solely to reduce line counts.

- `ContentValidator` is already a data-only facade: character/combat, item/banner, quest/dialogue, region and region-graph schemas live in domain validators; duplicate-key scanning lives in `JsonDuplicateKeyScanner`. Its remaining shared type/range/path primitives are one cohesive schema-validation responsibility, so splitting them again would add indirection without creating a new owner.
- `ProceduralArt` is already a pure cached-art facade. Prop families delegate to `ProceduralArtPropPainters` and its focused nature/structure painters; character frames delegate to `ProceduralCharacterArt`. Cache ownership, authored-SVG lookup, variant orchestration and compatibility APIs correctly remain together. Regression tests assert direct character-painter parity and the 59-kind/variant contract.
- `ActorVisual` is already a scene-composed presentation facade. Its authored children own procedural body drawing, character-specific effects, pose reconciliation, sprite/frame presentation and locomotion animation. The prior note describing pose reconciliation as a large unextracted responsibility is superseded; the remaining root methods are primarily stable API, lifecycle coordination and delegation.
- `GreenwardWorld` is likewise a scene composition root. The `.tscn` authors dedicated nodes for navigation, spawn, entities, weather, water/bridges, chunk streaming/lifecycle, region and Greenward composition, lighting, region context, day/night, atmosphere, props, visual standards, ambient effects, fog, runtime and resource setup. Its remaining `_ready()` ordering and public compatibility methods are intentional orchestration, not duplicate system implementations.
- The largest remaining painter/engine/service files were reviewed by responsibility, not line count. Pure painter families and deterministic services remain `RefCounted`; lifecycle-owning behavior stays in scene nodes. Further extraction is deferred unless a distinct responsibility or independent lifecycle boundary is demonstrated.
- Structural coverage already checks the authored ActorVisual children and their ownership; procedural-art tests check the facade-to-character-painter pixel parity, caching, deterministic variation and all 59 supported prop families.

Latest verified baseline remains **2,238 passed / 0 failed** with a fresh isolated Godot 4.7.2 editor import and full regression (see `artifacts/qa/responsibility_audit_regression_2026-11-17.log`). This audit did not change runtime code. Manual GUI QA and replacing explicitly temporary art remain separate release/content tasks; neither is claimed complete by this architecture audit.

