# Parallel development status

Last updated: 2026-11-14

## Baseline
- Branch: main
- Working tree: already contains significant uncommitted in-progress work before agents start.
- No commits or pushes authorized.
- Existing player movement/spawn transform bug is unresolved.
- Recent node/scene migration: player, Greenward world layers, NPC/monster/prop/portal/marker entities, game UI/screen scenes, battlefield, battlefield actors, and combat backdrops.
- Latest verified checks from prior work: headless editor import passed; arena, boss actor, Kael combat VFX, combat presentation, turn timeline tests passed; main game headless startup exited 0 with two invalid saved-spawn warnings. These are baseline results, not proof of current agent changes.

## Assignments
| Agent | Scope | Status |
|---|---|---|
| ChatGPT | Player transform/physics investigation, integration and review | In progress |
| Claude | Quest navigation and destination clarity | Ready |
| OpenCode | Inventory UI node/scene architecture | Ready |

## Change log
- 2026-11-14: Created parallel development protocol and isolated task ownership.

## Integration notes
- Do not merge by copying whole project folders over the active project.
- Do not reset or clean the working tree.
- Agents share one active project directory only if they are connected to the same machine/path. If using separate clones, deliver a patch or exact changed files and let ChatGPT integrate selectively.
- Update this file only by the lead integrator.


## Current integration checkpoint — 2026-11-17

- Node-architecture migration ledger is structurally complete; stateful actor, world, UI, routing, combat-presentation and persistent-domain responsibilities are scene/component owned. Pure algorithms and immutable catalogs remain non-Node by design.
- Latest isolated Godot 4.7.2 verbose regression: **2,238 passed, 0 failed**. No GDScript/parse/engine errors or ObjectDB/RID/resource cleanup diagnostics; only the expected malformed-save recovery warning. Log: `artifacts/qa/enemy_roaming_behavior_regression_2026-11-17.log`.
- Current scene ownership work includes the Greenward River/Landmark/Route/Interaction child hierarchy and Minimap `MarkerData` child. The current regression suite covers their ownership/binding contracts.
- Partial live QA now covers Royal Gardens movement/camera-follow, avatar cycling, NPC dialogue, inventory layout, Quest Journal and summon-banner presentation; full visual QA remains incomplete.
- Remaining hands-on QA: sustained player movement and camera-follow, NPC interaction, combat choreography, and inventory/quest/gacha overlays. No full device performance profile is claimed.
- This integration pass updated migration/testing/architecture documentation and preserved the verbose test log; it did not alter gameplay source code or live save data.

## Live QA and lifecycle follow-up — 2026-11-17

- Combat engine/resolver ownership cycle removed with `WeakRef`; owner-release regression checks pass.
- Inventory split and shared overlay shell sizing corrected; layout/full-height invariants are tested.
- Live visual checks pass for movement/camera-follow, avatar cycling, NPC dialogue, inventory, Quest Journal and the three summon banners.
- Latest isolated verbose suite: **2,238 passed, 0 failed**; zero ObjectDB/RID/resource leaks. Only the expected malformed-save recovery warning remains.
- Full log: `artifacts/qa/enemy_roaming_behavior_regression_2026-11-17.log`.
- Remaining QA: combat choreography, complete quest/gacha interactions, premium effects and device profiling.