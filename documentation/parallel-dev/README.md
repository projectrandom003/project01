# REVERIE — Parallel Development Protocol

This folder coordinates Claude, OpenCode, and ChatGPT on the same Godot project.

## Project facts
- Engine: Godot 4.7.2, GDScript, 2D isometric.
- Project root: this repository root.
- Current branch: main.
- Architecture: node-first and scene-driven. Use reusable scenes/nodes for visual, spatial, animated, interactive, collision, and lifecycle-based systems. Keep GDScript for logic, state, calculations, AI, persistence, and orchestration.
- Preserve existing game content, public APIs, save compatibility, and art direction.

## Critical current state
The working tree is already dirty before parallel work. It contains ongoing player/world/combat scene migrations, new scene files, art imports, backups, and diagnostics. These are intentional in-progress changes, not disposable clutter. Do not reset, clean, checkout, stash, reformat broadly, or overwrite files outside your task ownership.

The player movement/spawn bug remains unresolved: the player spawns around (0, 256) but a physics synchronization resets its transform toward (0, 0) shortly after entering the actual Game -> GameScreen -> GreenwardWorld hierarchy. Do not claim movement is fixed unless reproduced and tested in the real game scene.

## Coordination rules
1. Read your assigned task file before editing.
2. Only edit files explicitly listed in your task's ownership section. New files are allowed only inside your assigned area.
3. Do not edit shared/core files, project.godot, autoloads, GameScreen, GreenwardWorld, Player, InputSetup, EventBus, GameState, ContentDB, or combat systems unless your task explicitly grants permission.
4. Do not change another agent's files. If you discover a dependency outside your scope, document it and ask the lead before editing.
5. Do not delete files, backups, imported assets, or existing tests.
6. Do not commit, push, merge, stash, reset, or switch branches. Do not stage changes.
7. Avoid broad formatting or unrelated cleanup.
8. Add or update focused tests for your work where practical. Run the relevant test and Godot headless editor import if available.
9. At completion, update your task report with exact files changed, design decisions, tests run and results, known issues, and any manual verification still needed.
10. If a task cannot be completed safely within scope, stop and report the blocker rather than expanding scope.

## Integration contract
- Prefer authored scene children and PackedScene instances over creating visible UI trees entirely in code.
- Runtime code should bind/configure authored nodes, not duplicate them.
- Keep compatibility fallbacks only where existing tests or direct-instantiation callers require them.
- Signals should communicate intent; avoid tight coupling between unrelated screens.
- Keep layout responsive and consistent with the existing dark-fantasy visual language.
- No placeholder buttons that do nothing.

## Handoff
When finished, write the result in your assigned task file under "Completion report". Do not modify STATUS.md; ChatGPT maintains the integration status.
