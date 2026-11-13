# Project Fantasy — Playable Build Priorities

This backlog is ordered around player-visible improvements in the actual main game (`scenes/main.tscn` → `scenes/game.tscn`), not standalone previews.

## P0 — Core playable reliability
- [ ] Verify every combat UI / battle presentation change through the main game route, not only `tools/preview_fallen_matron_battle.tscn`.
- [x] Remove proximity-triggered random monster combat. Monsters now roam passively; only explicit Interact (E / controller A / touch Interact) starts combat.
- [x] Add a runtime regression test proving proximity does not start combat and explicit Interact does.
- [ ] Tune character movement separately for world and battle: acceleration/deceleration, directional transitions, sprite foot contact, per-character weight, battle approach/return paths.

## P1 — World and boss spaces
- [ ] Produce and import finished Greenward environment background / terrain assets.
- [ ] Produce and import finished Moonpetal Hollow assets with a distinct cool spectral palette and silhouettes.
- [ ] Replace procedural placeholder buildings, trees, foliage, rocks, paths and landmarks with a coherent licensed/original asset set.
- [ ] Create dedicated boss arenas with region gates / portal transitions. Boss interaction is only enabled after entering the corresponding arena zone.
- [ ] Keep bosses stationary inside their arena; do not place boss encounters as ordinary roaming mobs.

## P2 — Combat presentation and abilities
- [ ] Create authored skill animation/VFX assets per skill and element.
- [ ] Add per-character attack/cast/hit/recovery timing and target-specific impact points.
- [ ] Complete each skill's data: target rules, damage/heal formula, scaling, cost, cooldown/turn effects, status effects, element interactions, animation/VFX key, description and AI tags.
- [ ] Verify attacks and damage in the playable battle screen.

## P3 — Narrative and identity
- [ ] Write and integrate the main story arc for Gerald and Lilith, with Kael's role and region progression.
- [ ] Add quest/dialogue chapters and boss unlock prerequisites.
- [x] Replace and import the Project Fantasy app/game icon (original SVG backed up).
- [ ] Design and integrate a matching title-screen mark.

## Art direction constraints
- Preserve canonical designs for Kael, Lilith, Gerald and the Fallen Matron.
- Environment art should be authored as actual imported game assets, not screenshots or mockups.
- No asset is considered integrated until it is in the project, imported by Godot, referenced by the playable scene, and visually checked in-game.
