class_name CharacterArtPipelineCatalog
extends RefCounted
## Static production asset contract: kinds, dimensions, timing, import rules and per-kind specs.
## Runtime validation and query behavior remain in CharacterArtPipeline.

# ------------------------------------------------------------------ constants
# The TEN production asset kinds (stable id list).
const ASSET_KINDS: Array[String] = [
	"full_body_illustration",
	"character_portrait",
	"combat_sprite",
	"movement_sheet",
	"attack_sheet",
	"cast_sheet",
	"skill_vfx",
	"ultimate_vfx",
	"victory_sheet",
	"defeat_sheet",
]

# Canonical dimensions / anchors (px). World actor frame 96x128; boss/elite
# 128x192; bottom-centre anchor, feet on ONE baseline. Portrait master
# 1024x1280 -> export 256x384 top-centre bust crop. Full-body master 1024x2048.
# Combat sprite 128x192. Skill/ultimate VFX 192x192, 6 frames, centre anchor.
const FRAME_W := 96
const FRAME_H := 128
const BOSS_W := 128
const BOSS_H := 192
const COMBAT_W := 128
const COMBAT_H := 192
const PORTRAIT_MASTER_W := 1024
const PORTRAIT_MASTER_H := 1280
const PORTRAIT_EXPORT_W := 256
const PORTRAIT_EXPORT_H := 384
const FULLBODY_MASTER_W := 1024
const FULLBODY_MASTER_H := 2048
const VFX_W := 192
const VFX_H := 192
const VFX_FRAMES := 6
const DIRECTION_COUNT := 8
const SHEET_HEIGHT := 1024  # 8 direction rows * 128 px
const FORMAT := "RGBA8 PNG / WebP, sRGB, transparent (alpha cutout, never opaque)"
const RGBA8_NOTE := "transparent RGBA8 background; alpha cutouts, NOT opaque; 0-based frame index"

# Per-state authoritative timing from CharacterAnimator (IDLE..DEFEAT) plus the
# additive CAST state. frames / fps / loop are the single source of truth shared
# with the sprite sheets that get sliced into a SpriteFrames .tres.
const STATE_SPECS: Dictionary = {
	"idle":     {"frames": 5, "fps": 9.0,  "loop": true},
	"walk":     {"frames": 16, "fps": 12.0, "loop": true},
	"run":      {"frames": 16, "fps": 16.0, "loop": true},
	"interact": {"frames": 6, "fps": 12.0, "loop": false},
	"attack":   {"frames": 6, "fps": 15.0, "loop": false},
	"damage":   {"frames": 2, "fps": 12.0, "loop": false},
	"victory":  {"frames": 8, "fps": 12.0, "loop": false},
	"defeat":   {"frames": 6, "fps": 10.0, "loop": false},
	"cast":     {"frames": 7, "fps": 12.0, "loop": false},
}

# 9 animatable states (8 core + additive CAST) in stable order.
const STATES: Array[String] = [
	"idle", "walk", "run", "interact", "attack", "damage", "victory", "defeat", "cast",
]
# 8 directions, 0-based row order (row 0 = DOWN ... row 7 = DOWN_LEFT).
const DIRECTION_NAMES: Array[String] = [
	"down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left",
]

# Which states each SHEET kind owns (all 9 states covered exactly once across
# movement/attack/cast/victory/defeat sheets).
const SHEET_STATES: Dictionary = {
	"movement_sheet": ["idle", "walk", "run"],
	"attack_sheet":   ["attack", "interact", "damage"],
	"cast_sheet":     ["cast"],
	"victory_sheet":  ["victory"],
	"defeat_sheet":   ["defeat"],
}

# Per-state sheet = <frames>*96 wide x 8*128 tall (1024). Column counts below
# are literally STATE_SPECS[state].frames.
const _IMPORT_WORLD := {
	"filter": "Linear", "mipmaps": true,
	"compression": "VRAM compressed where supported; lossless for UI",
	"fix_alpha_border": true,
}
const _IMPORT_UI := {
	"filter": "Linear", "mipmaps": false,
	"compression": "Lossless (UI)", "fix_alpha_border": false,
}
const _IMPORT_VFX := {
	"filter": "Linear", "mipmaps": false,
	"compression": "Lossless", "fix_alpha_border": true,
}

# One exact production spec per kind. Every kind records: dimensions, anchor,
# transparent-RGBA8 requirement, frame count, sheet layout (where applicable),
# import settings, naming convention, replacement seam and a short description.
# NOTE: `frames` for a SHEET kind is the number of <state>_<dir> animation clips
# (states x 8) in the sliced SpriteFrames; per-state column counts live in
# `frame_counts`. `sheet_width`/`sheet_height` describe the widest per-state PNG
# atlas for that kind (height is always 8*128 = 1024).
const KIND_SPECS: Dictionary = {
	"full_body_illustration": {
		"kind": "full_body_illustration",
		"description": "Full-height key illustration of the character (head to toe), used for splash / collection / summon reveal. Single static frame.",
		"width": 1024, "height": 2048,
		"master_width": 1024, "master_height": 2048,
		"anchor": "bottom-centre (0.5, 1.0), feet on ONE baseline, ~6-head heroic proportions",
		"anchor_vector": Vector2(0.5, 1.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 1, "frame_counts": {"full_body": 1},
		"sheet": false, "states": [],
		"sheet_layout": "single static frame; no atlas",
		"sheet_width": 0, "sheet_height": 0,
		"import": _IMPORT_UI,
		"naming": "lower_snake_case content-id folder; <id>/full_body_illustration.png",
		"seam": "scripts/ui/main_backdrop.gd key-art layer + collection/summon screen big art (scripts/ui/screens/collection_screen.gd, gacha_screen.gd)",
		"extension": "png",
	},
	"character_portrait": {
		"kind": "character_portrait",
		"description": "Head-and-shoulders bust portrait. Master 1024x1280 cropped/exported to 256x384, top-centre bust crop, eyes in upper third. Single static frame.",
		"width": 256, "height": 384,
		"master_width": 1024, "master_height": 1280,
		"anchor": "top-centre (0.5, 0.0) bust crop from the top; eyes in the upper third",
		"anchor_vector": Vector2(0.5, 0.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 1, "frame_counts": {"portrait": 1},
		"sheet": false, "states": [],
		"sheet_layout": "single static frame; no atlas",
		"sheet_width": 0, "sheet_height": 0,
		"import": _IMPORT_UI,
		"naming": "lower_snake_case content-id folder; <id>/portrait.png (per assets/README.md also <id>/battle_bust.png, <id>/portrait_512.png)",
		"seam": "scripts/ui/portrait_view.gd (PortraitView.setup_character / _draw) -> PortraitAssetSource.texture_for(<id>) with procedural fallback",
		"extension": "png",
	},
	"combat_sprite": {
		"kind": "combat_sprite",
		"description": "Single full combat pose used on battle unit cards / combat screen. 128x192 (elite/boss canvas), bottom-centre. Single static frame.",
		"width": 128, "height": 192,
		"master_width": 128, "master_height": 192,
		"anchor": "bottom-centre (0.5, 1.0), feet on ONE baseline",
		"anchor_vector": Vector2(0.5, 1.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 1, "frame_counts": {"combat": 1},
		"sheet": false, "states": [],
		"sheet_layout": "single static frame; no atlas",
		"sheet_width": 0, "sheet_height": 0,
		"import": _IMPORT_WORLD,
		"naming": "lower_snake_case content-id folder; <id>/combat_sprite.png",
		"seam": "scripts/ui/combat/unit_card.gd + scripts/ui/screens/combat_screen.gd battle unit art",
		"extension": "png",
	},
	"movement_sheet": {
		"kind": "movement_sheet",
		"description": "8-direction locomotion: IDLE / WALK / RUN, each authored for all 8 directions. Looping states.",
		"width": 96, "height": 128,
		"master_width": 0, "master_height": 0,
		"anchor": "bottom-centre (0.5, 1.0), feet on ONE identical baseline across every frame/state/direction",
		"anchor_vector": Vector2(0.5, 1.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 133, "frame_counts": {"idle": 5, "walk": 16, "run": 16},
		"sheet": true, "states": ["idle", "walk", "run"],
		"sheet_layout": "per-state atlas = <frames>*96 wide x 8*128 tall; 8 direction rows (DOWN..DOWN_LEFT) x <frames> frame columns, 0-based columns; idle 480x1024, walk 1536x1024, run 1536x1024",
		"sheet_width": 1536, "sheet_height": 1024,
		"import": _IMPORT_WORLD,
		"naming": "lower_snake_case content-id folder; <id>/movement_sheet.png sliced to <id>/movement_sheet.tres; animations idle_<dir>, walk_<dir>, run_<dir>",
		"seam": "ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd",
		"extension": "tres",
	},
	"attack_sheet": {
		"kind": "attack_sheet",
		"description": "Combat/action one-shots: ATTACK / INTERACT / DAMAGE, all 8 directions. One-shot states.",
		"width": 96, "height": 128,
		"master_width": 0, "master_height": 0,
		"anchor": "bottom-centre (0.5, 1.0), feet on ONE identical baseline",
		"anchor_vector": Vector2(0.5, 1.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 133, "frame_counts": {"attack": 6, "interact": 6, "damage": 2},
		"sheet": true, "states": ["attack", "interact", "damage"],
		"sheet_layout": "per-state atlas = <frames>*96 wide x 8*128 tall; attack 576x1024, interact 576x1024, damage 192x1024",
		"sheet_width": 576, "sheet_height": 1024,
		"import": _IMPORT_WORLD,
		"naming": "lower_snake_case content-id folder; <id>/attack_sheet.png sliced to <id>/attack_sheet.tres; animations attack_<dir>, interact_<dir>, damage_<dir>",
		"seam": "ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd",
		"extension": "tres",
	},
	"cast_sheet": {
		"kind": "cast_sheet",
		"description": "Additive 9th-state CAST one-shot (7 frames @ 12 fps), all 8 directions.",
		"width": 96, "height": 128,
		"master_width": 0, "master_height": 0,
		"anchor": "bottom-centre (0.5, 1.0), feet on ONE identical baseline",
		"anchor_vector": Vector2(0.5, 1.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 8, "frame_counts": {"cast": 7},
		"sheet": true, "states": ["cast"],
		"sheet_layout": "single atlas 7*96 = 672 wide x 8*128 = 1024 tall; 8 direction rows x 7 columns, 0-based",
		"sheet_width": 1536, "sheet_height": 1024,
		"import": _IMPORT_WORLD,
		"naming": "lower_snake_case content-id folder; <id>/cast_sheet.png sliced to <id>/cast_sheet.tres; animations cast_<dir>",
		"seam": "ActorVisual.play_cast() / SpriteFramesActorSource.cast_frame() via ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>))",
		"extension": "tres",
	},
	"skill_vfx": {
		"kind": "skill_vfx",
		"description": "Skill effects flipbook (per skill id), 192x192 frames, 6 frames, additive glow, centre anchor.",
		"width": 192, "height": 192,
		"master_width": 192, "master_height": 192,
		"anchor": "centre (0.5, 0.5)",
		"anchor_vector": Vector2(0.5, 0.5),
		"transparent": true, "format": FORMAT, "background": "transparent RGBA8 (additive); alpha cutouts, never opaque",
		"frames": 6, "frame_counts": {"skill": 6},
		"sheet": false, "states": [],
		"sheet_layout": "1 row x 6 frame columns, 0-based; atlas 1152x192",
		"sheet_width": 1152, "sheet_height": 192,
		"import": _IMPORT_VFX,
		"naming": "lower_snake_case skill-id folder; assets/vfx/<skill_id>/effect.png (6 frames)",
		"seam": "scripts/combat/combat_engine.gd VFX hooks / scripts/world/procedural_art.gd soft_glow()",
		"extension": "png",
	},
	"ultimate_vfx": {
		"kind": "ultimate_vfx",
		"description": "Ultimate effects flipbook (per ultimate id), 192x192 frames, 6 frames, additive glow, centre anchor.",
		"width": 192, "height": 192,
		"master_width": 192, "master_height": 192,
		"anchor": "centre (0.5, 0.5)",
		"anchor_vector": Vector2(0.5, 0.5),
		"transparent": true, "format": FORMAT, "background": "transparent RGBA8 (additive); alpha cutouts, never opaque",
		"frames": 6, "frame_counts": {"ultimate": 6},
		"sheet": false, "states": [],
		"sheet_layout": "1 row x 6 frame columns, 0-based; atlas 1152x192",
		"sheet_width": 1152, "sheet_height": 192,
		"import": _IMPORT_VFX,
		"naming": "lower_snake_case ultimate-id folder; assets/vfx/<ultimate_id>/effect.png (6 frames)",
		"seam": "scripts/combat/combat_engine.gd VFX hooks / scripts/world/procedural_art.gd soft_glow()",
		"extension": "png",
	},
	"victory_sheet": {
		"kind": "victory_sheet",
		"description": "VICTORY one-shot (8 frames @ 12 fps), all 8 directions.",
		"width": 96, "height": 128,
		"master_width": 0, "master_height": 0,
		"anchor": "bottom-centre (0.5, 1.0), feet on ONE identical baseline",
		"anchor_vector": Vector2(0.5, 1.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 8, "frame_counts": {"victory": 8},
		"sheet": true, "states": ["victory"],
		"sheet_layout": "single atlas 8*96 = 768 wide x 8*128 = 1024 tall; 8 direction rows x 8 columns, 0-based",
		"sheet_width": 768, "sheet_height": 1024,
		"import": _IMPORT_WORLD,
		"naming": "lower_snake_case content-id folder; <id>/victory_sheet.png sliced to <id>/victory_sheet.tres; animations victory_<dir>",
		"seam": "ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd",
		"extension": "tres",
	},
	"defeat_sheet": {
		"kind": "defeat_sheet",
		"description": "DEFEAT one-shot (6 frames @ 10 fps), all 8 directions; holds the last frame.",
		"width": 96, "height": 128,
		"master_width": 0, "master_height": 0,
		"anchor": "bottom-centre (0.5, 1.0), feet on ONE identical baseline",
		"anchor_vector": Vector2(0.5, 1.0),
		"transparent": true, "format": FORMAT, "background": RGBA8_NOTE,
		"frames": 8, "frame_counts": {"defeat": 6},
		"sheet": true, "states": ["defeat"],
		"sheet_layout": "single atlas 6*96 = 576 wide x 8*128 = 1024 tall; 8 direction rows x 6 columns, 0-based",
		"sheet_width": 576, "sheet_height": 1024,
		"import": _IMPORT_WORLD,
		"naming": "lower_snake_case content-id folder; <id>/defeat_sheet.png sliced to <id>/defeat_sheet.tres; animations defeat_<dir>",
		"seam": "ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>)) -> scripts/world/actor_frame_source.gd + scripts/art/sprite_frames_actor_source.gd",
		"extension": "tres",
	},
}

# ------------------------------------------------------------------ public API

## Fresh typed copy of the ten stable kind ids.
