# PROJECT FANTASY — Character Art Pipeline (Part 1 contract)

> **ZERO final assets exist.** Every shipped visual is RUNTIME PROCEDURAL PLACEHOLDER art generated in code.
> This document and `scripts/art/character_art_pipeline.gd` (`CharacterArtPipeline`) are a pure CONTRACT /
> SPECIFICATION for FUTURE external generation. No image/binary art file was created in this phase.
> Authoritative docs: `documentation/ART_PIPELINE.md`, `documentation/VISUAL_STYLE.md`.

## 1. Authoritative values

| property | value |
| --- | --- |
| world actor frame | 96 x 128 px (boss/elite 128 x 192) |
| world anchor | bottom-centre `(0.5, 1.0)`, feet on ONE baseline, Y-sort at the ground point |
| full-body master | 1024 x 2048 px |
| portrait master -> export | 1024 x 1280 -> 256 x 384, top-centre bust crop `(0.5, 0.0)` |
| combat sprite | 128 x 192 px |
| skill / ultimate VFX | 192 x 192 px, 6 frames, centre anchor `(0.5, 0.5)`, 1 row x 6 columns |
| background | transparent RGBA8 PNG/WebP (sRGB), alpha cutouts, NEVER opaque |
| outline | 1-2 px dark `INK` at 1x; upper-left key light |
| directions | 8 (down, down_right, right, up_right, up, up_left, left, down_left), 0-based rows |

Per-state timing (from `CharacterAnimator`): **IDLE 5@9 loop, WALK 7@12 loop, RUN 7@14 loop,
INTERACT 6@12 one-shot, ATTACK 6@15 one-shot, DAMAGE 2@12 one-shot, VICTORY 8@12 one-shot,
DEFEAT 6@10 one-shot, CAST 7@12 one-shot**.

## 2. The ten asset kinds (exact specs)

| # | kind | dims (px) | anchor | frames | sheet layout | import | naming | seam |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `full_body_illustration` | 1024x2048 | bottom-centre (0.5, 1.0), feet on ONE baseline, ~6-head heroic proportions | 1 | single static frame; no atlas | { "filter": "Linear", "mipmaps": false, "compression": "Lossless (UI)", "fix_alpha_border": false } | lower_snake_case content-id folder; <id>/full_body_illustration.png | scripts/ui/main_backdrop.gd key-art layer + collection/summon screen big art (scripts/ui/screens/collection_screen.gd, gacha_screen.gd) |
| 2 | `character_portrait` | 256x384 | top-centre (0.5, 0.0) bust crop from the top; eyes in the upper third | 1 | single static frame; no atlas | { "filter": "Linear", "mipmaps": false, "compression": "Lossless (UI)", "fix_alpha_border": false } | lower_snake_case content-id folder; <id>/portrait.png (per assets/README.md also <id>/battle_bust.png, <id>/portrait_512.png) | scripts/ui/portrait_view.gd (PortraitView.setup_character / _draw) -> PortraitAssetSource.texture_for(<id>) with procedural fallback |
| 3 | `combat_sprite` | 128x192 | bottom-centre (0.5, 1.0), feet on ONE baseline | 1 | single static frame; no atlas | { "filter": "Linear", "mipmaps": true, "compression": "VRAM compressed where supported; lossless for UI", "fix_alpha_border": true } | lower_snake_case content-id folder; <id>/combat_sprite.png | scripts/ui/combat/unit_card.gd + scripts/ui/screens/combat_screen.gd battle unit art |
| 4 | `movement_sheet` | 96x128 | bottom-centre (0.5, 1.0), feet on ONE identical baseline across every frame/state/direction | 24 | per-state atlas = <frames>*96 wide x 8*128 tall; 8 direction rows (DOWN..DOWN_LEFT) x <frames> frame columns, 0-based columns; idle 480x1024, walk 672x1024, run 672x1024 | { "filter": "Linear", "mipmaps": true, "compression": "VRAM compressed where supported; lossless for UI", "fix_alpha_border": true } | lower_snake_case content-id folder; <id>/movement_sheet.png sliced to <id>/movement_sheet.tres; animations idle_<dir>, walk_<dir>, run_<dir> | ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd |
| 5 | `attack_sheet` | 96x128 | bottom-centre (0.5, 1.0), feet on ONE identical baseline | 24 | per-state atlas = <frames>*96 wide x 8*128 tall; attack 576x1024, interact 576x1024, damage 192x1024 | { "filter": "Linear", "mipmaps": true, "compression": "VRAM compressed where supported; lossless for UI", "fix_alpha_border": true } | lower_snake_case content-id folder; <id>/attack_sheet.png sliced to <id>/attack_sheet.tres; animations attack_<dir>, interact_<dir>, damage_<dir> | ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd |
| 6 | `cast_sheet` | 96x128 | bottom-centre (0.5, 1.0), feet on ONE identical baseline | 8 | single atlas 7*96 = 672 wide x 8*128 = 1024 tall; 8 direction rows x 7 columns, 0-based | { "filter": "Linear", "mipmaps": true, "compression": "VRAM compressed where supported; lossless for UI", "fix_alpha_border": true } | lower_snake_case content-id folder; <id>/cast_sheet.png sliced to <id>/cast_sheet.tres; animations cast_<dir> | ActorVisual.play_cast() / SpriteFramesActorSource.cast_frame() via ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) |
| 7 | `skill_vfx` | 192x192 | centre (0.5, 0.5) | 6 | 1 row x 6 frame columns, 0-based; atlas 1152x192 | { "filter": "Linear", "mipmaps": false, "compression": "Lossless", "fix_alpha_border": true } | lower_snake_case skill-id folder; assets/vfx/<skill_id>/effect.png (6 frames) | scripts/combat/combat_engine.gd VFX hooks / scripts/world/procedural_art.gd soft_glow() |
| 8 | `ultimate_vfx` | 192x192 | centre (0.5, 0.5) | 6 | 1 row x 6 frame columns, 0-based; atlas 1152x192 | { "filter": "Linear", "mipmaps": false, "compression": "Lossless", "fix_alpha_border": true } | lower_snake_case ultimate-id folder; assets/vfx/<ultimate_id>/effect.png (6 frames) | scripts/combat/combat_engine.gd VFX hooks / scripts/world/procedural_art.gd soft_glow() |
| 9 | `victory_sheet` | 96x128 | bottom-centre (0.5, 1.0), feet on ONE identical baseline | 8 | single atlas 8*96 = 768 wide x 8*128 = 1024 tall; 8 direction rows x 8 columns, 0-based | { "filter": "Linear", "mipmaps": true, "compression": "VRAM compressed where supported; lossless for UI", "fix_alpha_border": true } | lower_snake_case content-id folder; <id>/victory_sheet.png sliced to <id>/victory_sheet.tres; animations victory_<dir> | ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd |
| 10 | `defeat_sheet` | 96x128 | bottom-centre (0.5, 1.0), feet on ONE identical baseline | 8 | single atlas 6*96 = 576 wide x 8*128 = 1024 tall; 8 direction rows x 6 columns, 0-based | { "filter": "Linear", "mipmaps": true, "compression": "VRAM compressed where supported; lossless for UI", "fix_alpha_border": true } | lower_snake_case content-id folder; <id>/defeat_sheet.png sliced to <id>/defeat_sheet.tres; animations defeat_<dir> | ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd |

`character_portrait` has master 1024x1280 -> validated export 256x384; `full_body_illustration` master 1024x2048;
`combat_sprite` 128x192; both VFX kinds 192x192 x 6 frames. Sheet kinds are sliced `SpriteFrames` `.tres`.

## 3. Sheet layout (9 states x 8 directions)

- Per-state atlas = `<frames>*96` wide x `8*128` (1024) tall; 8 direction rows x `<frames>` columns, 0-based columns left->right.
- Row 0 = DOWN ... row 7 = DOWN_LEFT; feet on ONE identical baseline across every frame/state/direction.
- Slice into a `SpriteFrames` `.tres` with one animation per `<state_name>_<dir>` plus `cast_<dir>` (9 x 8 = **72** animations), speed = fps, loop = loop flag.
- State ownership: movement_sheet = idle/walk/run; attack_sheet = attack/interact/damage; cast_sheet = cast; victory_sheet = victory; defeat_sheet = defeat.

## 4. Import settings (per group)

| group | kinds | filter | mipmaps | compression | fix alpha border |
| --- | --- | --- | --- | --- | --- |
| world | combat/movement/attack/cast/victory/defeat sheets | Linear | ON | VRAM (lossless UI) | ON |
| UI | full_body_illustration, character_portrait | Linear | OFF | Lossless (UI) | OFF |
| VFX | skill_vfx, ultimate_vfx | Linear | OFF | Lossless | ON |

## 5. Replacement seams

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

## 6. `CharacterArtPipeline` public API

```gdscript
const ASSET_KINDS: Array[String]  # 10 kinds
const KIND_SPECS: Dictionary
static func kinds() -> Array[String]
static func spec(kind: String) -> Dictionary
static func import_settings(kind: String) -> Dictionary
static func sheet_layout() -> Dictionary            # states x directions x frame counts, 9x8
static func animation_names() -> Array[String]     # all <state>_<dir>, 72
static func validate_asset(kind, candidate) -> Array[String]  # [] when valid
static func naming_examples() -> Dictionary
static func summary() -> Dictionary
static func replacement_seams() -> Dictionary
static func example_candidate(kind) -> Dictionary   # extra helper
static func self_check() -> Array[String]           # extra helper; [] when coherent
```

PURE / headless: no nodes, no SceneTree, no autoloads, no file IO beyond optional existence checks;
deterministic and defensive (unknown kind -> clear error, never crashes).

## 7. Honest status & validation

- **FINAL 0.** No real finished file exists for any kind; `CharacterAssetRegistry.report()["counts"]["final"] == 0`.
- Validate content: `godot --headless --path . --script res://tools/validate_content.gd`.
- Tests: `godot --headless --path . res://tests/test_runner.tscn` (must stay 1374 passed, 0 failed).
- See also `scripts/art/character_art_spec.gd`, `character_asset_registry.gd`, `portrait_asset_source.gd`, `scripts/world/world_visual_standards.gd` and `assets/ASSET_PRODUCTION_MANIFEST.md`.
