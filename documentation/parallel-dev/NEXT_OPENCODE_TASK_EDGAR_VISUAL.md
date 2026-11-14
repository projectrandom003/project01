# OpenCode — Next task: finish Edgar as the actual authored character

## Why this is the next priority

The latest depth-sorting work is in good shape: the scene-based verifier passed 27/27 checks, and the existing renderer captures show the expected player/tree depth ordering. The movement verifier also completed with exit code 0 in the combined regression run.

The Edgar verifier currently passes 14 structural checks, but that does **not** prove Edgar looks like the reference design. The audit found no Edgar-named image asset anywhere under `assets/`, and `assets/characters/edgar/` is empty. The current dedicated scene uses the generic `ActorVisual` scene plus a palette and accessory markers. This is exactly the kind of generic stand-in the user rejected.

## Goal

Implement Edgar as the **actual distinctive character from the user's supplied Edgar reference design**, not a randomly generated/procedural generic NPC. Make him feel like a memorable, finished resident of Greenward and preserve the existing node-based architecture.

## Mandatory first step — recover the correct source design

1. Search the project, approved source-art folders, generated-image folders and recent project assets for the exact Edgar reference image the user supplied.
2. Inspect candidate images visually and compare them to the supplied design if it is available in the workspace.
3. Do not treat a filename, palette, accessory marker, or generic NPC preview as proof that the correct design was found.
4. If the exact reference cannot be recovered, stop before inventing a replacement. Report precisely what was searched and ask the user to reattach the Edgar reference. Do not silently substitute another design.
5. Preserve all existing uncommitted work. Do not reset, clean, revert, or overwrite unrelated files.

## Implementation (only after the correct design source is found)

- Build Edgar's visual as reusable Godot nodes/resources, consistent with the project's actor visual and sprite-animation architecture.
- Preserve the defining silhouette, hair, face, clothing, colors, glasses and coat-chain/accessories from the reference.
- Create/import only the animation views actually supported by the source art; do not fake missing views with unrelated character frames.
- Give him a dedicated world visual and matching dialogue portrait. Ensure the portrait and in-world sprite clearly depict the same character.
- Keep the existing stable NPC ID, dialogue key, Market Keeper role, interaction group/radius, introduction and market branches.
- Attach glasses and coat-chain through the existing node-based accessory mounts where appropriate; align them to the correct frames/directions rather than leaving empty markers.
- Make sure name/subtitle labels, interaction prompt and dialogue presentation do not obscure his face or important costume details.
- Avoid changing global player movement, Y-sort architecture, unrelated NPCs, combat, quest data or village layout.

## Verification required

1. Run `res://tools/verify_edgar_npc.tscn` and extend the verifier to check actual art resources, animation availability, portrait/world-art consistency and accessory mount setup — not just node names.
2. Add a dedicated Edgar visual preview/test scene that loads the production NPC scene and displays the important available directions/poses at a useful scale.
3. Run the preview in the actual Godot renderer and save captures. Inspect the captures manually for reference fidelity, clipping, incorrect layering, accessory alignment and label overlap.
4. Run the existing depth-sort verifier and player movement verifier to catch regressions.
5. Check the git diff and report every changed/added file. Do not claim visual completion if the correct reference source was unavailable or the captures were not inspected.

## Definition of done

Edgar is recognizably the exact supplied design in the game world and dialogue portrait; his identity, dialogue and Market Keeper interaction still work; accessories are correctly attached; node-based implementation is reusable; all relevant tests pass; and inspected renderer captures demonstrate the result.

## Final report format

- Reference source found: exact path and why it matches.
- Visual implementation: nodes/resources/animations/portrait.
- Tests: command, exit code and meaningful pass/fail counts.
- Captures: exact paths and what was visually inspected.
- Files changed.
- Remaining limitations or blocked items.
