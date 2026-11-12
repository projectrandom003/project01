# Gerald — Main Protagonist (`gerald`)

> **Status: REFERENCE SHEET ONLY.** The design reference sheet is imported and
> usable as a `Texture2D`. No cut-out portrait, sprite sheet or combat asset
> exists yet. This character is authored but **not recruited, not in the gacha
> pool, and not in any save**. The twelve collectible placeholder characters are
> unchanged.

## Identity (`resources/data/main_characters.json`)

| field | value |
| --- | --- |
| id | `gerald` |
| display_name | Gerald |
| title | The Flamebound Guardian |
| race | Human |
| element | fire |
| rarity | legendary |
| role | Armored Bruiser |
| main_character | true |
| playable | false (authored, not recruited) |

## Design brief (from the supplied reference sheet)

- Lilith's older brother: white-haired masked warrior in black armor with orange
  flame details.
- Original design preserved exactly; no replacement or generated artwork.
- Palette (used only for procedural fallback / UI tinting):

| role | hex |
| --- | --- |
| `hair` | `#eef1f6` |
| `primary` | `#1b1a1f` |
| `secondary` | `#e0702a` |
| `accent` | `#ff9a3c` |
| `skin` | `#d9c3b0` |

## Files in this folder

| file | status | notes |
| --- | --- | --- |
| `reference_sheet.png` | **present** | 1536x1024 RGB PNG, byte-identical copy of the supplied art. Design reference, not a cut-out. |
| `portrait.png` | **missing** | Future 256x384 RGBA8 transparent cut-out. Drop it here to activate the real portrait seam. |

## Provisional kit (reuses existing, validated content)

The protagonists have no bespoke skills yet. Their kit reuses existing skills so
that **no combat data or balance is changed**:

- `ember_lance`, `cinder_veil`, ultimate `blazing_charge`
- passive `nothing_to_lose` (displayed as "Oath of Ash")

Replace these with dedicated skills in a later content round.

## How to view in Godot

1. Open the project in the Godot editor.
2. FileSystem dock → `res://assets/characters/main/guardian/`.
3. Double-click `reference_sheet.png` (or click it and open the Import tab).
4. Open `res://resources/characters/main/gerald.tres` to inspect the
   `MainCharacterProfile` resource and its texture slot.
