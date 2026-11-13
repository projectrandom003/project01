# Gerald — Main Protagonist (`gerald`)

> **Status: FINAL PLAYABLE ART.** Gerald is a protagonist with a complete
> set: 8 directions x 9 states = 72 animations, a 256x384 bust portrait, a
> 128x192 combat sprite and a 1024x2048 full-body key illustration, extracted
> from this concept sheet (`The Guardian_`).

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
| playable | true (starting party member) |

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
| `portrait.png` | **n/a** | His final art lives in `res://assets/characters/gerald/` (portrait, world sheet, combat sprite, full-body illustration). |

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
