# Boss Presentation Node System

## Purpose

A reusable, presentation-only node system for Project Fantasy boss encounters. It is deliberately isolated from the existing combat implementation until integration is reviewed.

**Authority boundary:** CombatEngine continues to own action selection, phase thresholds, targeting, damage, status effects, and resolution. These nodes only display positions and cues supplied by the combat layer.

## Scene architecture

`res://scenes/combat/presentation/boss_presentation_rig.tscn`

```text
BossPresentationRig (Control)
├── WorldEffects (Node2D)
│   ├── BossTelegraph (instances, transient)
│   │   ├── Glyph (Node2D)
│   │   │   └── Artwork (Node2D)
│   │   │       ├── ElderStyle (Node2D: root rings and radial marks)
│   │   │       └── MatronStyle (Node2D: flower rings and petals)
│   │   └── AnimationPlayer
│   └── BossImpact (instances, transient)
│       ├── Glyph (Node2D)
│       │   └── Artwork (Node2D)
│       │       ├── ElderStyle (Node2D: root burst)
│       │       └── MatronStyle (Node2D: bloom burst)
│       └── AnimationPlayer
└── PhaseCue (Control)
    ├── Veil (ColorRect)
    ├── PhaseTitle (Label)
    └── AnimationPlayer
```

The geometry is authored as Line2D/Polygon2D nodes. Elder Hollow selects the concentric root/radial-mark glyph; Fallen Matron selects a floral petal glyph. Their profiles also supply distinct colors and scales. AnimationPlayer owns the expansion, rotation, and fade timing. There is no runtime vector-art construction and no external texture dependency.

## Data profiles

- `resources/combat/presentation/default_boss.tres`
- `resources/combat/presentation/elder_hollow.tres`
- `resources/combat/presentation/fallen_matron.tres`

Each Resource configures the visual style (roots or bloom), telegraph tint/scale, impact tint/scale, and phase cue tint/title. Boss identity is selected by the rig; no combat definitions or existing enemy data are changed.

## Public presentation API

- `show_target_telegraph(position, boss_id, duration)`
- `show_target_telegraphs(positions, boss_id, duration)`
- `play_impact(position, boss_id, strength)`
- `play_multi_target_strike(positions, boss_id, windup_seconds)`
- `show_phase_transition(boss_id, phase_number, optional_message)`
- `clear_transients()`

Signals:
- `telegraph_spawned(position, boss_id)`
- `impact_spawned(position, boss_id)`
- `phase_change_started(boss_id, phase_number, message)`
- `phase_change_finished`
- `multi_target_sequence_finished(boss_id, target_count)`

The multi-target method creates one warning at each supplied target position, waits for the windup, creates an impact at every target, then emits a completion signal. It does not apply damage or alter combatant state. Clearing the rig invalidates any pending sequence.

## Integration seam (not yet wired)

The intended next integration is additive:

1. Instance `BossPresentationRig` as a full-rect child of the existing Battlefield scene. Its `WorldEffects` coordinates match the Battlefield local coordinate space.
2. In the existing action-event handler, resolve **all** `target_uids` to live BattlefieldActor positions. For AoE/boss-wide actions, pass those positions to `play_multi_target_strike`; do not reduce the event to only the first UID.
3. Keep existing actor choreography for the attacker. Do not let the rig call CombatEngine or infer damage.
4. In the phase-event handler, identify the actual boss `def_id` and call `show_phase_transition` with that boss ID and phase number. This replaces the current Matron-only presentation dispatch at the integration point, not the CombatEngine phase logic.
5. Preserve the existing Matron cinematic until parity is proven. Its unique Verdict sequence can remain a boss-specific authored presentation scene and use the shared telegraph/impact primitives incrementally.

**Not changed in this prototype:** `battlefield.gd`, `battlefield_actor.gd`, `combat_screen.gd`, `battlefield.tscn`, `CombatEngine`, tests/test_runner.gd, existing boss art, or combat data.

## Verification

Run:

```powershell
& 'C:\Users\quoth\Desktop\Godot_v4.7.2-stable_win64.exe' --headless --path 'C:\Users\quoth\Documents\Default Project\project-fantasy' --scene 'res://tools/verify_boss_presentation_nodes.tscn'
```

Expected focused output: `[boss-presentation] OK — 14 passed, 0 failed.`

A standalone visual preview is available at `res://tools/preview_boss_presentation_nodes.tscn`.

## Limitations

This is a tested isolated prototype, not yet part of live combat. It proves authored scene composition, boss-specific root/floral glyph selection, AnimationPlayer timing, per-boss Resource profiles, multi-target presentation sequencing, phase cues for both named bosses, and cancellation/cleanup. The existing Battlefield/CombatScreen integration remains the next shared-file change and must be coordinated with the integration owner.
