# Reverie — bespoke Royal Gardens sprites

These PNGs are individual crops from the custom **REVERIE — Royal Gardens · Castle Collection** sheet made in our earlier design work. They are not generic assets.

## Import
1. Extract this folder into `res://assets/reverie_custom/`.
2. In Godot, select the PNG textures and set filtering to Nearest for pixel-art use.
3. Keep texture compression lossless. Do not resize the source PNGs.
4. Use the manifest to identify each sprite and its source rectangle.

## Extraction notes
The sheet was manually divided into 42 named sprite files. Transparent sheet-background pixels were removed using edge-connected background removal. A few neighboring elements or thin sheet dividers may remain in some crops; inspect the sprite before using it. The original source sheet is included for exact reference.

## Project art rule
Use only these bespoke Reverie sprites and further sprites cut from the other custom Reverie sheets. Do not add generic placeholder or stock assets. Code may assemble sprites and provide collision, sorting, and interaction, but must not draw replacement artwork.
