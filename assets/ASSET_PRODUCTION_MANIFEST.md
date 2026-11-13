# PROJECT FANTASY — Asset Production Manifest (Part 6)

> **Three final playable characters (Gerald, Lilith, Kael).** All shipped visuals for the other
> collectible characters are RUNTIME PROCEDURAL PLACEHOLDER art.
> This manifest tracks EVERY expected character asset as FINAL / TEMPORARY / MISSING, computed
> from disk by `scripts/art/character_asset_registry.gd` (`CharacterAssetRegistry`). It is a contract,
> not a gallery: no collectible-character image/binary art file was created in this phase.
> The separate Fallen Matron boss illustration set is documented in `ASSET_STATUS.md` and is not
> part of this character-asset registry.

## The rule (never hardcode FINAL)

> **An asset may be marked FINAL only if a real finished file exists on disk AND passes**
> **`CharacterAssetRegistry.validate_finished_asset(char_id, kind)` (returns `[]`). Never hardcode FINAL.**
> Status is computed from `check_disk()` + validation. MISSING means the final file is absent;
> TEMPORARY means a procedural fallback is present and rendering (orthogonal to MISSING).

Rule string: `an asset may be marked FINAL only if a real finished file exists on disk AND passes validate_finished_asset(); never hardcoded`

## Honest current counts (from `CharacterAssetRegistry.report()`)

| bucket | count | meaning |
| --- | --- | --- |
| **FINAL** | **0** | no character asset ships a real validated file |
| **TEMPORARY** | **120** | every (character x kind) has a present procedural fallback |
| **MISSING** | **120** | every expected final file is absent on disk |
| total entries | 120 | 12 characters x 10 kinds |

`counts.final == 0`. `CharacterAssetRegistry.check_disk()` returns `false` for all 120 expected paths;
`AssetManifest.check_disk()` also stays `false` for all 8 original classes (its `status_report()` is
unchanged at FINAL 0 / TEMPORARY 8 / MISSING 8).

## Per-character rows

Every row: `FINAL` only via the rule above; today all are **MISSING (final) / TEMPORARY (procedural fallback)**.

### `lyra_vey`

| kind | expected path | final file on disk | status |
| --- | --- | --- | --- |
| `full_body_illustration` | `res://assets/characters/lyra_vey/full_body_illustration.png` | false | missing |
| `character_portrait` | `res://assets/characters/lyra_vey/character_portrait.png` | false | missing |
| `combat_sprite` | `res://assets/characters/lyra_vey/combat_sprite.png` | false | missing |
| `movement_sheet` | `res://assets/characters/lyra_vey/movement_sheet.tres` | false | missing |
| `attack_sheet` | `res://assets/characters/lyra_vey/attack_sheet.tres` | false | missing |
| `cast_sheet` | `res://assets/characters/lyra_vey/cast_sheet.tres` | false | missing |
| `skill_vfx` | `res://assets/characters/lyra_vey/skill_vfx.png` | false | missing |
| `ultimate_vfx` | `res://assets/characters/lyra_vey/ultimate_vfx.png` | false | missing |
| `victory_sheet` | `res://assets/characters/lyra_vey/victory_sheet.tres` | false | missing |
| `defeat_sheet` | `res://assets/characters/lyra_vey/defeat_sheet.tres` | false | missing |

### `bramble`

| kind | expected path | final file on disk | status |
| --- | --- | --- | --- |
| `full_body_illustration` | `res://assets/characters/bramble/full_body_illustration.png` | false | missing |
| `character_portrait` | `res://assets/characters/bramble/character_portrait.png` | false | missing |
| `combat_sprite` | `res://assets/characters/bramble/combat_sprite.png` | false | missing |
| `movement_sheet` | `res://assets/characters/bramble/movement_sheet.tres` | false | missing |
| `attack_sheet` | `res://assets/characters/bramble/attack_sheet.tres` | false | missing |
| `cast_sheet` | `res://assets/characters/bramble/cast_sheet.tres` | false | missing |
| `skill_vfx` | `res://assets/characters/bramble/skill_vfx.png` | false | missing |
| `ultimate_vfx` | `res://assets/characters/bramble/ultimate_vfx.png` | false | missing |
| `victory_sheet` | `res://assets/characters/bramble/victory_sheet.tres` | false | missing |
| `defeat_sheet` | `res://assets/characters/bramble/defeat_sheet.tres` | false | missing |

### `seraphine`

| kind | expected path | final file on disk | status |
| --- | --- | --- | --- |
| `full_body_illustration` | `res://assets/characters/seraphine/full_body_illustration.png` | false | missing |
| `character_portrait` | `res://assets/characters/seraphine/character_portrait.png` | false | missing |
| `combat_sprite` | `res://assets/characters/seraphine/combat_sprite.png` | false | missing |
| `movement_sheet` | `res://assets/characters/seraphine/movement_sheet.tres` | false | missing |
| `attack_sheet` | `res://assets/characters/seraphine/attack_sheet.tres` | false | missing |
| `cast_sheet` | `res://assets/characters/seraphine/cast_sheet.tres` | false | missing |
| `skill_vfx` | `res://assets/characters/seraphine/skill_vfx.png` | false | missing |
| `ultimate_vfx` | `res://assets/characters/seraphine/ultimate_vfx.png` | false | missing |
| `victory_sheet` | `res://assets/characters/seraphine/victory_sheet.tres` | false | missing |
| `defeat_sheet` | `res://assets/characters/seraphine/defeat_sheet.tres` | false | missing |

### `nyx`

| kind | expected path | final file on disk | status |
| --- | --- | --- | --- |
| `full_body_illustration` | `res://assets/characters/nyx/full_body_illustration.png` | false | missing |
| `character_portrait` | `res://assets/characters/nyx/character_portrait.png` | false | missing |
| `combat_sprite` | `res://assets/characters/nyx/combat_sprite.png` | false | missing |
| `movement_sheet` | `res://assets/characters/nyx/movement_sheet.tres` | false | missing |
| `attack_sheet` | `res://assets/characters/nyx/attack_sheet.tres` | false | missing |
| `cast_sheet` | `res://assets/characters/nyx/cast_sheet.tres` | false | missing |
| `skill_vfx` | `res://assets/characters/nyx/skill_vfx.png` | false | missing |
| `ultimate_vfx` | `res://assets/characters/nyx/ultimate_vfx.png` | false | missing |
| `victory_sheet` | `res://assets/characters/nyx/victory_sheet.tres` | false | missing |
| `defeat_sheet` | `res://assets/characters/nyx/defeat_sheet.tres` | false | missing |

### `coralyn`

| kind | expected path | final file on disk | status |
| --- | --- | --- | --- |
| `full_body_illustration` | `res://assets/characters/coralyn/full_body_illustration.png` | false | missing |
| `character_portrait` | `res://assets/characters/coralyn/character_portrait.png` | false | missing |
| `combat_sprite` | `res://assets/characters/coralyn/combat_sprite.png` | false | missing |
| `movement_sheet` | `res://assets/characters/coralyn/movement_sheet.tres` | false | missing |
| `attack_sheet` | `res://assets/characters/coralyn/attack_sheet.tres` | false | missing |
| `cast_sheet` | `res://assets/characters/coralyn/cast_sheet.tres` | false | missing |
| `skill_vfx` | `res://assets/characters/coralyn/skill_vfx.png` | false | missing |
| `ultimate_vfx` | `res://assets/characters/coralyn/ultimate_vfx.png` | false | missing |
| `victory_sheet` | `res://assets/characters/coralyn/victory_sheet.tres` | false | missing |
| `defeat_sheet` | `res://assets/characters/coralyn/defeat_sheet.tres` | false | missing |

### `ignis`

| kind | expected path | final file on disk | status |
| --- | --- | --- | --- |
| `full_body_illustration` | `res://assets/characters/ignis/full_body_illustration.png` | false | missing |
| `character_portrait` | `res://assets/characters/ignis/character_portrait.png` | false | missing |
| `combat_sprite` | `res://assets/characters/ignis/combat_sprite.png` | false | missing |
| `movement_sheet` | `res://assets/characters/ignis/movement_sheet.tres` | false | missing |
| `attack_sheet` | `res://assets/characters/ignis/attack_sheet.tres` | false | missing |
| `cast_sheet` | `res://assets/characters/ignis/cast_sheet.tres` | false | missing |
| `skill_vfx` | `res://assets/characters/ignis/skill_vfx.png` | false | missing |
| `ultimate_vfx` | `res://assets/characters/ignis/ultimate_vfx.png` | false | missing |
| `victory_sheet` | `res://assets/characters/ignis/victory_sheet.tres` | false | missing |
| `defeat_sheet` | `res://assets/characters/ignis/defeat_sheet.tres` | false | missing |

### `mira_sol`

| kind | expected path | final file on disk | status |
| --- | --- | --- | --- |
| `full_body_illustration` | `res://assets/characters/mira_sol/full_body_illustration.png` | false | missing |
| `character_portrait` | `res://assets/characters/mira_sol/character_portrait.png` | false | missing |
| `combat_sprite` | `res://assets/characters/mira_sol/combat_sprite.png` | false | missing |
| `movement_sheet` | `res://assets/characters/mira_sol/movement_sheet.tres` | false | missing |
| `attack_sheet` | `res://assets/characters/mira_sol/attack_sheet.tres` | false | missing |
| `cast_sheet` | `res://assets/characters/mira_sol/cast_sheet.tres` | false | missing |
| `skill_vfx` | `res://assets/characters/mira_sol/skill_vfx.png` | false | missing |
| `ultimate_vfx` | `res://assets/characters/mira_sol/ultimate_vfx.png` | false | missing |
| `victory_sheet` | `res://assets/characters/mira_sol/victory_sheet.tres` | false | missing |
| `defeat_sheet` | `res://assets/characters/mira_sol/defeat_sheet.tres` | false | missing |

### `thistle`

| kind | expected path | final file on disk | status |
| --- | --- | --- | --- |
| `full_body_illustration` | `res://assets/characters/thistle/full_body_illustration.png` | false | missing |
| `character_portrait` | `res://assets/characters/thistle/character_portrait.png` | false | missing |
| `combat_sprite` | `res://assets/characters/thistle/combat_sprite.png` | false | missing |
| `movement_sheet` | `res://assets/characters/thistle/movement_sheet.tres` | false | missing |
| `attack_sheet` | `res://assets/characters/thistle/attack_sheet.tres` | false | missing |
| `cast_sheet` | `res://assets/characters/thistle/cast_sheet.tres` | false | missing |
| `skill_vfx` | `res://assets/characters/thistle/skill_vfx.png` | false | missing |
| `ultimate_vfx` | `res://assets/characters/thistle/ultimate_vfx.png` | false | missing |
| `victory_sheet` | `res://assets/characters/thistle/victory_sheet.tres` | false | missing |
| `defeat_sheet` | `res://assets/characters/thistle/defeat_sheet.tres` | false | missing |

### `vespera`

| kind | expected path | final file on disk | status |
| --- | --- | --- | --- |
| `full_body_illustration` | `res://assets/characters/vespera/full_body_illustration.png` | false | missing |
| `character_portrait` | `res://assets/characters/vespera/character_portrait.png` | false | missing |
| `combat_sprite` | `res://assets/characters/vespera/combat_sprite.png` | false | missing |
| `movement_sheet` | `res://assets/characters/vespera/movement_sheet.tres` | false | missing |
| `attack_sheet` | `res://assets/characters/vespera/attack_sheet.tres` | false | missing |
| `cast_sheet` | `res://assets/characters/vespera/cast_sheet.tres` | false | missing |
| `skill_vfx` | `res://assets/characters/vespera/skill_vfx.png` | false | missing |
| `ultimate_vfx` | `res://assets/characters/vespera/ultimate_vfx.png` | false | missing |
| `victory_sheet` | `res://assets/characters/vespera/victory_sheet.tres` | false | missing |
| `defeat_sheet` | `res://assets/characters/vespera/defeat_sheet.tres` | false | missing |

### `arachnia`

| kind | expected path | final file on disk | status |
| --- | --- | --- | --- |
| `full_body_illustration` | `res://assets/characters/arachnia/full_body_illustration.png` | false | missing |
| `character_portrait` | `res://assets/characters/arachnia/character_portrait.png` | false | missing |
| `combat_sprite` | `res://assets/characters/arachnia/combat_sprite.png` | false | missing |
| `movement_sheet` | `res://assets/characters/arachnia/movement_sheet.tres` | false | missing |
| `attack_sheet` | `res://assets/characters/arachnia/attack_sheet.tres` | false | missing |
| `cast_sheet` | `res://assets/characters/arachnia/cast_sheet.tres` | false | missing |
| `skill_vfx` | `res://assets/characters/arachnia/skill_vfx.png` | false | missing |
| `ultimate_vfx` | `res://assets/characters/arachnia/ultimate_vfx.png` | false | missing |
| `victory_sheet` | `res://assets/characters/arachnia/victory_sheet.tres` | false | missing |
| `defeat_sheet` | `res://assets/characters/arachnia/defeat_sheet.tres` | false | missing |

### `terra`

| kind | expected path | final file on disk | status |
| --- | --- | --- | --- |
| `full_body_illustration` | `res://assets/characters/terra/full_body_illustration.png` | false | missing |
| `character_portrait` | `res://assets/characters/terra/character_portrait.png` | false | missing |
| `combat_sprite` | `res://assets/characters/terra/combat_sprite.png` | false | missing |
| `movement_sheet` | `res://assets/characters/terra/movement_sheet.tres` | false | missing |
| `attack_sheet` | `res://assets/characters/terra/attack_sheet.tres` | false | missing |
| `cast_sheet` | `res://assets/characters/terra/cast_sheet.tres` | false | missing |
| `skill_vfx` | `res://assets/characters/terra/skill_vfx.png` | false | missing |
| `ultimate_vfx` | `res://assets/characters/terra/ultimate_vfx.png` | false | missing |
| `victory_sheet` | `res://assets/characters/terra/victory_sheet.tres` | false | missing |
| `defeat_sheet` | `res://assets/characters/terra/defeat_sheet.tres` | false | missing |

### `kael`

| kind | expected path | final file on disk | status |
| --- | --- | --- | --- |
| `full_body_illustration` | `res://assets/characters/kael/full_body_illustration.png` | false | missing |
| `character_portrait` | `res://assets/characters/kael/character_portrait.png` | false | missing |
| `combat_sprite` | `res://assets/characters/kael/combat_sprite.png` | false | missing |
| `movement_sheet` | `res://assets/characters/kael/movement_sheet.tres` | false | missing |
| `attack_sheet` | `res://assets/characters/kael/attack_sheet.tres` | false | missing |
| `cast_sheet` | `res://assets/characters/kael/cast_sheet.tres` | false | missing |
| `skill_vfx` | `res://assets/characters/kael/skill_vfx.png` | false | missing |
| `ultimate_vfx` | `res://assets/characters/kael/ultimate_vfx.png` | false | missing |
| `victory_sheet` | `res://assets/characters/kael/victory_sheet.tres` | false | missing |
| `defeat_sheet` | `res://assets/characters/kael/defeat_sheet.tres` | false | missing |

## Exact replacement seams

- `full_body_illustration`: scripts/ui/main_backdrop.gd key-art layer + collection/summon screen big art (scripts/ui/screens/collection_screen.gd, gacha_screen.gd)
- `character_portrait`: scripts/ui/portrait_view.gd (PortraitView.setup_character / _draw) -> PortraitAssetSource.texture_for(<id>) with procedural fallback
- `combat_sprite`: scripts/ui/combat/unit_card.gd + scripts/ui/screens/combat_screen.gd battle unit art
- `movement_sheet`: ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd
- `attack_sheet`: ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd
- `cast_sheet`: ActorVisual.play_cast() / SpriteFramesActorSource.cast_frame() via ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>))
- `skill_vfx`: scripts/combat/combat_engine.gd VFX hooks / scripts/world/procedural_art.gd soft_glow()
- `ultimate_vfx`: scripts/combat/combat_engine.gd VFX hooks / scripts/world/procedural_art.gd soft_glow()
- `victory_sheet`: ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd
- `defeat_sheet`: ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd

- Portraits: `scripts/ui/portrait_view.gd (PortraitView.setup_character / _draw) -> PortraitAssetSource.texture_for(<id>, "hud") with a procedural fallback on null`
- World standards contract: `scripts/world/world_visual_standards.gd` (`WorldVisualStandards.validate() == []`), 6 categories (player, npc, monster, building, vegetation, environment_object).

## Honest status of this phase

- **FINAL 0** — no real finished asset file exists; none was created here.
- No `.png`/`.webp`/`.jpg`/`.tres`/`.res`/`.svg`/`.import` art file was created; no final artwork was fabricated from polygons.
- `AssetManifest.status_report()` remains FINAL 0 / TEMPORARY 8 / MISSING 8; `check_disk()` false for all 8.
- All shipped visuals remain procedural placeholder (TEMPORARY). No visual testing (headless dummy renderer); no audio.
- Validation: `godot --headless --path . --script res://tools/validate_content.gd` and `res://tests/test_runner.tscn` (1374 passed).
