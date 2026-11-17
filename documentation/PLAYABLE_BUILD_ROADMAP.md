# Project Fantasy â€” Playable Build Priorities

This backlog is ordered around player-visible improvements in the actual main game (`scenes/main.tscn` â†’ `scenes/game.tscn`), not standalone previews.

## P0 â€” Core playable reliability
- [x] Automated main-game route verification: explicit Interact opens the live CombatScreen with both teams, authored Battlefield actors, action HUD, turn-order display and a populated presentation report (2026-11-17; 2,244 full-suite checks pass). Manual visual inspection is still outstanding.
- [x] Remove proximity-triggered random monster combat. Monsters now roam passively; only explicit Interact (E / controller A / touch Interact) starts combat.
- [x] Add a runtime regression test proving proximity does not start combat and explicit Interact does.
- [x] Tune character movement separately for world and battle: per-avatar acceleration, deceleration, turn resistance and speed (Gerald heavier, Lilith lighter, Kael baseline); battle lunges now reconcile attackers and targets to authored home slots instead of accumulating positional drift. Deterministic movement-profile assertions and the full regression suite pass (2026-11-17; 2,248 checks). Manual visual foot-contact and in-game choreography review remains outstanding.

## P1 â€” World and boss spaces
- [ ] Produce and import finished Greenward environment background / terrain assets.
- [ ] Produce and import finished Moonpetal Hollow assets with a distinct cool spectral palette and silhouettes.
- [ ] Replace procedural placeholder buildings, trees, foliage, rocks, paths and landmarks with a coherent licensed/original asset set.
- [x] Integrate the Gothic Castle boss region behind the Royal Gardens restoration gate; the Royal Road portal remains inspectable but refuses travel until `garden_shadows` is complete. Baltoria's throne encounter remains sealed until `baltoria_summoning` is active and the player has advanced past the gatekeeper dialogue to the defeat objective. Both gates preserve explicit Interact and use the existing authored arena region/entry points (2026-11-17; 2,261 full-suite checks pass).
- [x] Keep boss encounters stationary at their authored arena positions; boss actors no longer run the roaming behavior and can only be reached through the normal explicit-interaction radius. Regression coverage verifies stationary positioning, out-of-range separation and explicit challenge input (2026-11-17; 2,261 full-suite checks pass).

## P2 â€” Combat presentation and abilities
- [ ] Create authored skill animation/VFX assets per skill and element.
- [ ] Add per-character attack/cast/hit/recovery timing and target-specific impact points.
- [ ] Complete each skill's data: target rules, damage/heal formula, scaling, cost, cooldown/turn effects, status effects, element interactions, animation/VFX key, description and AI tags. Partial data pass (2026-11-17): all 46 definitions carry scaling, animation/VFX keys, cooldown metadata and AI tags; `SkillDef` loads them and combat events expose presentation keys. Damage resolution and AI estimates now honor `atk`, `def`, `hp` or `spd` scaling, including the corresponding effective stat buffs/debuffs. Combatants now track per-skill cooldowns; the engine rejects cooling-down actions, enemy AI avoids them, and the HUD disables them with a remaining-turn label. Target availability is validated before resource/cooldown consumption, so invalid target rules cannot spend energy or start a cooldown; a regression test covers this atomicity. No live skill currently has a positive cooldown value, so per-skill cooldown balancing/data assignment, cost/turn effects and final art assets remain outstanding.
- [ ] Verify attacks and damage in the playable battle screen.

## P3 â€” Narrative and identity
- [ ] Write and integrate the main story arc for Gerald and Lilith, with Kael's role and region progression.
- [ ] Add quest/dialogue chapters and boss unlock prerequisites.
- [x] Replace and import the Project Fantasy app/game icon (original SVG backed up).
- [ ] Design and integrate a matching title-screen mark.

## Latest verified regression
- 2026-11-17 skill cooldown + scaling integration: **2,512 passed, 0 failed** in a fresh isolated Godot 4.7.2 QA clone (`project-fantasy-qa-cooldowns-20261117`). The clone uses a dedicated custom user-data directory to prevent concurrent editor/test processes from colliding with the player's save. No script/parse/test errors were found. Content validation also passed: 9 content files plus main characters; 15 characters, 46 skills, 11 enemies and 17 items loaded. Cooldown enforcement is implemented and tested, but all current skill definitions still have cooldown 0 until per-skill balance values are authored. Skill animation/VFX metadata remains a presentation hook, not finished art production.

## Art direction constraints
- Preserve canonical designs for Kael, Lilith, Gerald and the Fallen Matron.
- Environment art should be authored as actual imported game assets, not screenshots or mockups.
- No asset is considered integrated until it is in the project, imported by Godot, referenced by the playable scene, and visually checked in-game.


### Environment-authorship audit (2026-11-17)
- Added ProceduralArt.authored_environment_report() to compare every canonical prop kind against the authored SVG registry and separate imported assets, procedural fallbacks and invalid/missing registered paths.
- Regression coverage verifies all 14 registered SVG paths resolve and every prop kind is classified. Current catalogue coverage: 14 authored kinds; remaining kinds continue to use procedural fallback. This is an audit/integration safeguard, not completion of the outstanding environment-art deliverable.
- Isolated Godot 4.7.2 QA clone: 2,517 passed, 0 failed. No script, parse or test errors. Full log archived at artifacts/qa/environment_authorship_audit_regression_2026-11-17.log.


### Existing-map repair (2026-11-17)
- Fixed the Royal Gardens gate guard nameplate collision visible in the captured map review: the two guards now have distinct West/East Gate names and their authored grid positions are separated by 250 world units rather than 64. Their Marker2D positions were aligned to the same projected world positions.
- Added regression coverage for the distinct names and minimum projected separation.
- Fresh isolated Godot 4.7.2 regression: 2,520 passed, 0 failed. Full log: artifacts/qa/existing_garden_npc_nameplate_fix_2026-11-17.log. Manual in-game visual recheck remains pending.





### Existing UI/map repairs (2026-11-17)
- Royal Gardens gate guards now have distinct West/East names and are spaced far enough apart to prevent overlapping world nameplates; the placement markers match their grid positions.
- Minimap marker filtering prevents NPCs and roaming monsters from appearing a second time as generic interactables. The minimap collapsed state is now a 60x28 chip with its restore button moved inside the hitbox; expanding restores the original button position and 224x224 map.
- Regression checks also verify the two requested summon banners, independent summon close controls, and hard-pity behavior.
- Fresh isolated Godot 4.7.2 suite: **2,529 passed, 0 failed**. No script, parse or test errors. Log: artifacts/qa/existing_ui_repair_regression_2026-11-17.log.





- Follow-up HUD polish: the six in-game navigation buttons now use a consistent gothic glass treatment with role-specific restrained accents, icon labels, readable uppercase text and clear hover/pressed/focus states. 
- The summon menu now exposes exactly two featured tabs: Vesper Noct and Scarlet Requiem. Vesper's banner data was preserved; Scarlet retains its own supplied portrait and banner template. The summon chamber backdrop and Return to Game close control remain in place.
- Startup smoke checks: scenes/main.tscn and scenes/game.tscn both exited 0 with no script/parse/engine errors. Logs archived in artifacts/qa/.


