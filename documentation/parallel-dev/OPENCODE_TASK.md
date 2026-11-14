# OpenCode task — Inventory UI scene architecture

## Goal
Improve the inventory screen's node-first architecture and usability. Convert suitable repeated or visual UI structures into reusable, editor-visible scene nodes while preserving the current inventory behavior and data model.

## Ownership — files you may edit
- `scripts/ui/screens/inventory_screen.gd`
- `scenes/ui/inventory_screen.tscn`
- `scripts/ui/inventory_item_entry.gd` (new, only if genuinely useful)
- `scenes/ui/inventory_item_entry.tscn` (new, only if genuinely useful)
- A focused test under `tools/` whose filename begins `verify_opencode_inventory_nodes` (new)

Do not edit any other file. In particular, do not edit `GameScreen`, `GreenwardWorld`, `Player`, `GameState`, `EventBus`, item definitions/content, project settings, quest screens, or combat systems. If a required integration point is outside your ownership, report the proposed change rather than making it.

## Requirements
1. Inspect the current inventory screen, scene, item model/API and relevant existing UI patterns first.
2. Preserve inventory behavior: item counts, categories, selection, descriptions, use/equip actions, and signals.
3. Identify repeated item-card/entry UI that should become a reusable PackedScene with named child nodes. Only create a new scene if it meaningfully improves reuse/editor control.
4. The scene tree should be readable and configurable in the Godot editor. Avoid replacing one large script with a large custom abstraction.
5. Bind script logic to authored nodes; avoid duplicating authored children at runtime.
6. Maintain responsive layout and REVERIE's existing dark-fantasy visual style.
7. All buttons and interactions must work. Do not leave inert controls.
8. Do not invent item data or alter item balance/content.

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
