# Fallen Matron — Art and Combat Integration

## Canonical design source

- Reference: `assets/enemies/fallen_matron/reference_sheet.png`
- Phase cutouts: `phase_1.png`, `phase_2.png`, `phase_3.png`
- Character: The Fallen Matron, Matron of the Withered Estate
- Lore height: approximately 230 cm (boss scale)
- Palette: pale skin, silver-ash hair, deep purple, black plum, ivory fabric, gold accents, corruption violet.
- Defining features: curled dark horns, long silver-lavender hair, purple eyes, black-plum sleeves, ivory layered gown, gold detailing, violet corruption growths.

The reference sheet is the canonical identity source. Do not replace her with a generic demon, armored monster, or a different face/costume.

## Current Godot integration

- Battlefield actor loads the three phase cutouts and changes them at the existing HP thresholds.
- Phase art is normalized to a consistent on-stage height.
- Turn-order portrait uses an AtlasTexture crop from the current phase image.
- Idle: continuous breathing, restrained sway and violet corruption motes.
- Attack: skill-specific windup and release choreography is dispatched for Corruption Bolt, Shadow Lash, Soul Drain and Matron's Verdict.
- Hurt: brief violet-white flash and recoil.
- Phase transition: cutout swap, scale transition and corruption burst.
- Death: tilt, fall, fade and particle residue.

These are transform/tween and VFX animations on the existing cutouts. They are not frame-by-frame hand-drawn sprite animations.

## Production animation sheet target

Use transparent PNG frames, one action per row, fixed canvas size and consistent ground pivot:

| Action | Frames | Notes |
|---|---:|---|
| Idle | 12 | breathing, hair and sleeve follow-through |
| Cast | 16 | hand rise, sigil formation, release |
| Attack A — Corruption Bolt | 16 | gather, orb release, recoil |
| Attack B — Shadow Lash | 16 | veil windup, tendril strike, settle |
| Hurt | 8 | impact, stagger, recovery |
| Recover | 8 | return to composed silhouette |
| Death | 16 | collapse, dissolve into violet motes |
| Phase transition | 24 | phase 1 → 2 → 3 corruption evolution |

Keep the same facial identity, horn silhouette, hair length, neckline, bow/brooch, sleeve shape, skirt silhouette and gold trim across every frame. Phase 2/3 may add corruption tendrils and violet glow but must preserve the recognizable base costume.

## Verification still required

- Visual inspection in the running 1280×720 battle scene.
- Confirm turn-order portrait crop for all three phases.
- Confirm each Matron attack targets the correct ally and each party attack impacts the Matron.
- Replace the tween-only cutout animation with production frame animations when the transparent frame atlas is authored and imported.
