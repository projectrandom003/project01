# Character Node Integration — Directional Equipment and Character Effects

## Reusable equipment mounts

Added `scenes/characters/equipment/equipment_mount.tscn`. Each attachment socket contains:
- `Visual` (Sprite2D): equipment artwork surface.
- `AnimationPlayer`: future item-specific animation tracks.
- `Effects` (Node2D): optional glow, trails or particles.

Five sockets are authored per facing: BackEquipment, HairAccessory, LeftHandEquipment, RightHandEquipment and ChestAccessory.

## Directional equipment architecture

Added `scenes/characters/components/directional_equipment/directional_equipment_layers.tscn` and `scripts/world/directional_equipment_layers.gd`.

Eight authored groups follow CharacterAnimator's exact direction order: Down, DownRight, Right, UpRight, Up, UpLeft, Left, DownLeft. Each group owns its own five sockets and mounts. The selector exposes `set_direction()` and `get_active_layer()`, keeps exactly one direction visible, and mirrors the live ActorVisual CharacterAnimator direction.

The three playable authoring rigs (Gerald, Lilith and Kael) use this directional hierarchy. The live `ActorVisual` scene also instances it. It does not own or replace animation playback.

## Character-specific node effects

Added a reusable `CharacterEffectsController` and authored radial-gradient Sprite2D effects:
- Kael: warm ember aura, enabled for the live player avatar.
- Lilith: cool spectral glow, enabled in Lilith's preview rig and for any live ActorVisual configured as Lilith.

The controller only switches node visibility based on the parent character id. It does not modify the established character renderer or animation state machine.

## Live integration scope

- The existing `FrameSprite`, `SpriteFramesActorSource`, CharacterAnimator, AnimationPlayer locomotion tracks and renderer script remain in place.
- Player and NPC ActorVisual instances receive the same directional equipment sockets and effect nodes.
- No changes to player.gd, actor_visual.gd, CharacterAnimator, collision, movement, combat, save contracts, or character sprite-sheet assets.
- Equipment Visual nodes intentionally have no textures assigned yet; equipment art and item animations remain future work.
- Character-specific effects are simple authored node layers; visual tuning still needs review in the running game.

## Roster comparison scene

`scenes/characters/playable_roster_preview.tscn` places Gerald, Lilith and Kael at a shared ground baseline with labels and a camera. Open this scene in Godot to inspect scale, silhouettes and feet alignment.

## Verification

Latest node verifier: 139 checks passed, 0 failures. It loads all three character rigs, roster preview, live ActorVisual and Player; checks all five sockets in all eight direction groups; verifies direction selection and live CharacterAnimator synchronization; and verifies Kael/Lilith effect visibility, including the Player's Kael aura.

Main-character authoring verification also passed. The separate `verify_character_avatars.gd` script currently fails to compile in this headless invocation because it references the autoload `ContentDB` without project autoload context; this does not affect the dedicated playable-character verifier.

The tests are headless runtime checks, not a full visual sign-off. The Kael ember aura is wired into the live player and should be visible after a fresh game launch. Lilith's spectral aura is wired into her preview and live ActorVisual configuration. Socket offsets and effect strength still need visual review in the actual renderer.

## Data-driven equipment mount foundation

Added `scripts/world/equipment_definition.gd` (`EquipmentDefinition`) as a Resource for item visual data: equipment id/name, texture, sprite offset/scale, z-index, centering, horizontal flip, modulation and enabled state.

Added `scripts/world/equipment_mount.gd` (`EquipmentMount`) to the existing `EquipmentMount.tscn`. It applies a definition to the existing Sprite2D node, safely hides entries without artwork, and supports clearing or hiding the mounted visual. AnimationPlayer and Effects remain separate authored child nodes; the mount does not own inventory, stats, or animation state.

Focused verifier: `tools/verify_equipment_mount_nodes.gd` — 10 checks passed. No equipment artwork was invented or assigned; mounts remain visually empty until approved item textures are supplied.

## Directional equipment loadout presentation

Added `scripts/world/character_equipment_controller.gd` (`CharacterEquipmentController`) as a child component of `DirectionalEquipmentLayers`.

The controller applies an `EquipmentDefinition` to a named attachment slot across all eight facings, or to one explicit facing for direction-specific artwork. It supports per-facing overrides, clearing one slot/facing, clearing all slots, and safe rejection of invalid slot names or direction indices. This is presentation-only: it does not own inventory, equipment stats, persistence, or combat calculations.

Focused verifier: `tools/verify_character_equipment_controller.gd` — 11 checks passed. Existing `tools/verify_playable_character_nodes.gd` remains green at 139 checks. Equipment mounts still have no assigned textures; this work establishes the data-to-node pipeline without inventing art.

## Character-specific equipment loadout Resources

Added `EquipmentDirectionalOverride` and `CharacterEquipmentLoadout` Resources. A loadout defines the five authored equipment slots and optional per-direction overrides (0–7). `CharacterEquipmentController.apply_loadout()` clears the previous presentation state, applies base slot definitions to all eight facings, then applies directional overrides.

Created empty identity resources:
- `resources/characters/equipment/gerald_loadout.tres`
- `resources/characters/equipment/lilith_loadout.tres`
- `resources/characters/equipment/kael_loadout.tres`

These intentionally contain no invented equipment art. They are authoring-ready character-specific loadout assets and can be populated when approved equipment textures exist.

Focused verifier: `tools/verify_character_equipment_controller.gd` — 17 checks passed, including loadout application, all-facing base assignments, direction override precedence, and all three identity resources.
