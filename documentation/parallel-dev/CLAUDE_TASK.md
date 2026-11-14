# Claude task — Quest navigation and destination clarity

## Goal
Improve the player's ability to understand the active quest, identify the next objective, and navigate toward it. Make the quest screen and its destination presentation clearer without changing quest progression rules or world spawning.

## Ownership — files you may edit
- `scripts/ui/screens/quest_screen.gd`
- `scenes/ui/quest_screen.tscn`
- `scripts/ui/quest_navigation.gd` (new, only if genuinely useful)
- `scenes/ui/quest_navigation.tscn` (new, only if genuinely useful)
- A focused test under `tools/` whose filename begins `verify_claude_quest_navigation` (new)

Do not edit any other file. In particular, do not edit `GameScreen`, `GreenwardWorld`, `Player`, `GameState`, `EventBus`, quest data/content, destination-marker world scripts, or project settings. If a required integration point is outside your ownership, report the proposed change rather than making it.

## Requirements
1. Inspect current quest screen, scene, quest data interfaces, and existing destination marker behavior before designing.
2. Preserve all existing quest acceptance/completion/progression behavior and save compatibility.
3. Make active quest, current objective, objective description, and destination easier to distinguish at a glance.
4. Make tracking state visually obvious. If the project already exposes a tracked quest, use that API; do not invent a second source of truth.
5. Provide a clear empty state when no quest is tracked/active.
6. Keep layout responsive and consistent with REVERIE's dark-fantasy UI.
7. All controls must work. Do not add decorative/inert buttons.
8. Prefer scene-authored nodes for reusable UI pieces. Keep logic in scripts.
9. Do not invent coordinates or destination names. Display only data provided by the existing quest system.
10. Avoid changing navigation/world behavior; this task is about presentation and safe UI-level integration.

## Validation
- Run a focused test if possible.
- Run Godot headless editor import if available.
- Inspect for parse errors and warnings introduced by your changes.
- Do not claim in-game visual verification unless you actually opened and inspected it.

## Completion report
Append your report below:
- Summary:
- Files changed:
- Existing APIs reused:
- Tests/commands run:
- Results:
- Known issues / integration requests:
- Manual verification still needed:
