# Lilith — Main Protagonist (`lilith`)

> **Status: REFERENCE SHEET ONLY.** The design reference sheet is imported and
> usable as a `Texture2D`. No cut-out portrait, sprite sheet or combat asset
> exists yet. This character is a **starting party member**: recruited by
> default, registered in ContentDB and saved with the player's roster. They are
> not in the gacha pool. The twelve collectible placeholder characters are
> otherwise unchanged.

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

## Design brief (from the supplied reference sheet)

- White-haired, blue-eyed ghost girl who died at age 13.
- Original design preserved exactly; no replacement or generated artwork.
- Palette (used only for procedural fallback / UI tinting):

| role | hex |
| --- | --- |
| `hair` | `#f2f5fa` |
| `primary` | `#6f8fbf` |
| `secondary` | `#b9d4e8` |
| `accent` | `#7fd4ff` |
| `skin` | `#e8eef7` |

## Files in this folder

| file | status | notes |
| --- | --- | --- |
| `reference_sheet.png` | **present** | 1536x1024 RGB PNG, byte-identical copy of the supplied art. Design reference, not a cut-out. |
| `portrait.png` | **missing** | Future 256x384 RGBA8 transparent cut-out. Drop it here to activate the real portrait seam. |

## Provisional kit (reuses existing, validated content)

The protagonists have no bespoke skills yet. Their kit reuses existing skills so
that **no combat data or balance is changed**:

- `frost_bind`, `tidal_caress`, ultimate `abyssal_hymn`
- passive `small_miracles` (displayed as "Thirteen Winters")

Replace these with dedicated skills in a later content round.

## How to view in Godot

1. Open the project in the Godot editor.
2. FileSystem dock → `res://assets/characters/main/little_sister/`.
3. Double-click `reference_sheet.png` (or click it and open the Import tab).
4. Open `res://resources/characters/main/lilith.tres` to inspect the
   `MainCharacterProfile` resource and its texture slot.
