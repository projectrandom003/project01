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
