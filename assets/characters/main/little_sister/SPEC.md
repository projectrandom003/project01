# Lilith — Main Protagonist (`lilith`)

> **Status: FINAL PLAYABLE ART.** Lilith is the first protagonist with a
> complete, validated playable art set: 8-direction / 9-state world animation,
> a 256x384 HUD portrait, a combat sprite and a full-body illustration. She is a
> **starting party member**: recruited by default, registered in ContentDB and
> saved with the player's roster. She is not in the gacha pool. The twelve
> collectible placeholder characters are otherwise unchanged.

## Identity (`resources/data/main_characters.json`)

| field | value |
| --- | --- |
| id | `lilith` |
| display_name | Lilith |
| title | The Little Sister |
| race | Spirit |
| element | water |
| rarity | legendary |
| role | Ghost Support |
| main_character | true |
| playable | true (starting party member) |

## Design brief (read from the supplied concept sheet)

The supplied sheet is the source of truth for Lilith's look. The playable art
is **original vector-style work rendered from this brief** — the sheet is
**not** cropped, traced or reused as a texture.

- **"The Lost Girl"** — a cheerful ghost girl who died at 13. She is a
  *restless spirit*; her soul lingers in the mortal world.
- **Chibi proportions** (roughly 2.5 heads tall), big head, large anime eyes.
- **Hair:** voluminous white/silver. A long side-ponytail sweeps out from the
  crown; long side locks frame the face.
- **Signature accessory:** a **black bow with a white skull** pinning the
  ponytail at the top-right of her head.
- **Eyes:** large, bright cyan with white highlights.
- **Dress:** **white** (not blue) — a frilly, layered, *torn* dress with a lace
  ruffle at the hem and a ragged, frayed bottom edge.
- **Navy accents:** a navy **bow at the chest**, a navy **choker with a cyan
  teardrop gem**, and navy **thigh-highs** with small bows at the top.
- **Spirit effects:** a blue spectral aura and tail around the lower body,
  small blue "soul" wisps orbiting her, and a cyan flash when she is hit.
- Palette (the five swatches printed on the sheet, plus the accents):

| role | hex |
| --- | --- |
| `hair` | `#f4f7fc` |
| `dress` | `#edf1f8` |
| `trim` | `#bacde3` |
| `accent` (spirit cyan, eyes, gem) | `#7fd4ff` |
| `navy` (bows, choker, thigh-highs) | `#2b3a5c` |
| `skin` | `#f3e9ec` |

The `palette` block in `resources/data/main_characters.json` keeps the older
blue-grey hero palette; it is used only for the procedural fallback and UI
tinting, not for the final art.

## Files

| file | folder | status | notes |
| --- | --- | --- | --- |
| `reference_sheet.png` | `main/little_sister/` | **present** | 1536x1024 RGB PNG, byte-identical copy of the supplied art. Design reference only. |
| `portrait.png` | `characters/lilith/` | **final** | 256x384 RGBA8, transparent, head-and-shoulders bust. |
| `<state>_sheet.png` | `characters/lilith/` | **final** | Per-state world atlas, `<frames>*96` x `8*128`, 8 direction rows. |
| `world_sheet.tres` | `characters/lilith/` | **final** | Sliced `SpriteFrames`: 72 animations / 432 frames, runtime-validated. |
| `combat_sprite.png` | `characters/lilith/` | **final** | 128x192 RGBA8 single combat pose. |
| `full_body_illustration.png` | `characters/lilith/` | **final** | 1024x2048 RGBA8 key illustration. |
| `preview/` | `characters/lilith/` | generated | Contact sheet + per-state animated GIFs for review. |

### World animation contract

| state | frames | fps | loops |
| --- | --- | --- | --- |
| idle | 5 | 9 | yes |
| walk | 7 | 12 | yes |
| run | 7 | 14 | yes |
| interact | 6 | 12 | no |
| attack | 6 | 15 | no |
| damage | 2 | 12 | no |
| victory | 8 | 12 | no |
| defeat | 6 | 10 | no |
| cast | 7 | 12 | no |

Direction rows are ordered `down, down_right, right, up_right, up, up_left,
left, down_left`; rows 5/6/7 are exact horizontal mirrors of rows 3/2/1.

## Regeneration

`tools/generate_lilith_art.py` (Python + Pillow) renders every asset
deterministically from the brief above. It draws in three composited layers
(`under` / `main` / `over`) because Pillow's `ImageDraw` replaces pixels
instead of alpha-blending on an RGBA target. `tools/build_lilith_spriteframes.gd`
slices the per-state atlases into `world_sheet.tres` using the
`CharacterAnimator` contract, then round-trip validates it:

```powershell
python tools/generate_lilith_art.py
godot --headless --path . --script res://tools/build_lilith_spriteframes.gd
```

## In-game integration

- `PortraitAssetSource` resolves `res://assets/characters/lilith/portrait.png`,
  so HUD/combat portraits show the real art (procedural fallback inactive).
- `SpriteFramesActorSource.from_disk("lilith")` loads `world_sheet.tres`;
  `mirrors_by_facing()` is false so the 8 real directions are never
  double-mirrored.
- Press **Tab** (or the HUD **Switch** button / controller RB) to cycle the
  world avatar. `available_avatars()` only lists characters with a validated
  disk sheet, so the Wanderer demo avatar remains the default until other
  protagonists receive final art.

## Provisional kit (reuses existing, validated content)

The protagonists have no bespoke skills yet. Their kit reuses existing skills so
that **no combat data or balance is changed**:

- `frost_bind`, `tidal_caress`, ultimate `abyssal_hymn`
- passive `small_miracles` (displayed as "Thirteen Winters")

Replace these with dedicated skills in a later content round.

## How to view in Godot

1. Open the project in the Godot editor.
2. FileSystem dock → `res://assets/characters/lilith/`.
3. Open `res://resources/characters/main/lilith.tres` to inspect the
   `MainCharacterProfile` resource, its reference sheet and portrait target.
4. Open `preview_sheet.png` (or the per-state GIFs in `preview/`) to review the
   animation frames.
