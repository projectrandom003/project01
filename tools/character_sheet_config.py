#!/usr/bin/env python3
"""Per-character concept-sheet layouts for the Project Fantasy art pipeline.

Every protagonist sheet follows the same idea: a large main illustration on
the left, four character views (Front / Right / Back / Left) and animation
strips (Idle, Walk, Attack, Cast, Hurt, Death). This module records where
those pieces live on each sheet so the extraction / build tools can stay
character-agnostic.

Frame boxes are explicit x-ranges: the sheets do NOT space their frames
evenly (attack arcs and flame effects push them apart), so they were measured
once and are listed here.
"""

from __future__ import annotations

import os

# --------------------------------------------------------------- sheet source

SHEET_FILES = {
    "lilith": "little sister",
    "gerald": "The Guardian_",
    "kael": "Kael Isometric Character Sheet.png",
}

# The four character views, in the order they appear on each sheet.
VIEW_NAMES = {
    "lilith": ["front", "right", "back", "left"],
    "gerald": ["front", "right", "back", "left"],
    "kael": ["se", "sw", "ne", "nw"],
}

# Which sheet strip backs each in-game animation state, and how its frames are
# built. The game's own frame counts live in CharacterAnimator.
#   resample : resample the strip cyclically to the needed count
#   lean     : resample, then shear the sprite forward (used for RUN)
#   first3   : the strip's first three frames (a wind-up gesture)
#   first2   : the strip's first two frames
#   hop      : a victory hop with sparkles
#   dissolve : the death frames fading away
STATE_PLAN = {
    "lilith": {
        "idle": ("idle", "resample"),
        "walk": ("walk", "resample"),
        "run": ("walk", "lean"),
        "interact": ("attack", "first3"),
        "attack": ("attack", "resample"),
        "damage": ("hurt", "first2"),
        "victory": ("idle", "hop"),
        "defeat": ("death", "dissolve"),
        "cast": ("cast", "resample"),
    },
    "gerald": {
        "idle": ("idle", "resample"),
        "walk": ("walk", "resample"),
        "run": ("walk", "lean"),
        "interact": ("attack", "first3"),
        "attack": ("attack", "resample"),
        "damage": ("hurt", "first2"),
        "victory": ("idle", "hop"),
        "defeat": ("death", "dissolve"),
        "cast": ("cast", "resample"),
    },
    "kael": {
        "idle": ("idle", "resample"),
        "walk": ("walk", "resample"),
        "run": ("run", "resample"),
        "interact": ("attack", "first3"),
        "attack": ("attack", "resample"),
        "damage": ("hurt", "first2"),
        "victory": ("idle", "hop"),
        "defeat": ("death", "dissolve"),
        "cast": ("skill", "resample"),
    },
}

# The game's eight direction rows, in sheet order
# (down, down_right, right, up_right, up, up_left, left, down_left).
#   source : "front" = the animated strips, or one of the four sheet views
#   shear  : horizontal lean around the feet (an isometric 3/4 turn)
#   mirror : flip the sprite horizontally
ROWS = {
    "lilith": [
        {"source": "front", "shear": 0.0},
        {"source": "front", "shear": 0.17},
        {"source": "right", "shear": 0.0},
        {"source": "back", "shear": 0.17},
        {"source": "back", "shear": 0.0},
        {"source": "back", "shear": -0.17},
        {"source": "left", "shear": 0.0},
        {"source": "front", "shear": -0.17},
    ],
    "gerald": [
        {"source": "front", "shear": 0.0},
        {"source": "front", "shear": 0.17},
        {"source": "right", "shear": 0.0},
        {"source": "back", "shear": 0.17},
        {"source": "back", "shear": 0.0},
        {"source": "back", "shear": -0.17},
        {"source": "left", "shear": 0.0},
        {"source": "front", "shear": -0.17},
    ],
    # Kael is a true isometric sheet: the strips face SE, so the SE art drives
    # the camera-facing rows and the mirrored SE art drives down-left.
    "kael": [
        {"source": "front", "shear": 0.0},
        {"source": "front", "shear": 0.17},
        {"source": "front", "shear": 0.30},
        {"source": "ne", "shear": 0.0},
        {"source": "ne", "shear": -0.17},
        {"source": "nw", "shear": 0.0},
        {"source": "sw", "shear": 0.17},
        {"source": "front", "shear": -0.17, "mirror": True},
    ],
}

DOWNLOADS = os.path.join(os.environ.get("USERPROFILE", os.path.expanduser("~")),
                         "Downloads")


def sheet_path(character_id: str) -> str:
    return os.path.join(DOWNLOADS, SHEET_FILES[character_id])


def output_folder(character_id: str) -> str:
    """The assets/characters/<folder> a character's playable art is written to.

    Usually the character id itself. Kael is also one of the twelve
    collectible characters, whose folder is owned by the collectible asset
    registry, so his playable art gets its own folder.
    """
    return SHEETS[character_id].get("output_folder", character_id)


# ------------------------------------------------------------------- layouts
# strips[name] = dict(region=(x0, y0, x1, y1), count=N, frames=...)
#   region  : the strip's panel, used to estimate the panel background
#   count   : how many frames the strip holds
#   frames  : either the string "slot" (N evenly spaced slots across the
#             region) or an explicit list of (x0, x1[, y0]) per frame. The
#             explicit list is used where the sheet does NOT space its frames
#             evenly (attack arcs and flame effects push them apart); the
#             optional per-frame top bound skips the strip's TITLE text,
#             which sits at the panel's top-left.
# views     : the four character views, in sheet order
# portrait  : the crop taken from the sheet's large main illustration

SHEETS = {
    "lilith": {
        "strips": {
            "idle": dict(region=(655, 368, 950, 506), count=4, frames="slot"),
            "walk": dict(region=(990, 368, 1516, 506), count=8, frames="slot"),
            "attack": dict(region=(655, 556, 1432, 686), count=7, frames="slot"),
            "cast": dict(region=(648, 732, 962, 866), count=4, frames="slot"),
            "hurt": dict(region=(988, 732, 1172, 862), count=3, frames="slot"),
            "death": dict(region=(1218, 732, 1516, 864), count=4, frames="slot"),
        },
        "views": dict(region=(808, 52, 1330, 252), count=4, frames="slot"),
        "portrait": dict(box=(70, 36, 350, 456), size=(256, 384)),
        "combat": dict(size=(128, 192)),
        "full_body": dict(size=(1024, 2048)),
        "sparkle_colour": (150, 225, 255),
        "defeat_fades": [0.58, 0.34],
    },
    "gerald": {
        "strips": {
            "idle": dict(region=(445, 350, 755, 470), count=4, frames=[
                (445, 520, 358), (520, 607, 358), (607, 681, 358),
                (681, 755, 358)]),
            "walk": dict(region=(775, 350, 1345, 470), count=8, frames=[
                (775, 863, 358), (863, 935, 358), (935, 999, 358),
                (999, 1083, 358), (1083, 1142, 358), (1142, 1210, 358),
                (1210, 1282, 358), (1282, 1345, 358)]),
            "attack": dict(region=(445, 495, 1340, 600), count=7, frames=[
                (445, 545, 508), (545, 669, 500), (669, 784, 500),
                (784, 915, 500), (915, 1060, 500), (1060, 1221, 500),
                (1221, 1340, 500)]),
            "cast": dict(region=(425, 625, 900, 755), count=5, frames=[
                (425, 504, 638), (504, 590, 638), (590, 684, 620),
                (684, 772, 620), (772, 900, 620)]),
            "hurt": dict(region=(928, 625, 1155, 755), count=3, frames=[
                (928, 1017, 640), (1017, 1103, 618), (1103, 1155, 618)]),
            "death": dict(region=(1222, 625, 1515, 755), count=3, frames=[
                (1222, 1310, 640), (1310, 1413, 640), (1413, 1515, 618)]),
        },
        "views": dict(region=(740, 40, 1330, 290), count=4, frames=[
            (740, 916), (916, 1020), (1020, 1198), (1198, 1330)]),
        "portrait": dict(box=(100, 0, 360, 390), size=(256, 384)),
        "combat": dict(size=(128, 192)),
        "full_body": dict(size=(1024, 2048)),
        "sparkle_colour": (255, 176, 64),
        "defeat_fades": [0.62, 0.46, 0.32],
    },
    # Kael is a TRUE 2D ISOMETRIC sheet: four facings (SE / SW / NE / NW) and
    # single-facing animation strips. The strips face SE, so the SE art drives
    # the camera-facing rows and the mirrored SE art drives down-left.
    # Kael is ALSO one of the 12 collectible characters, and the
    # CharacterAssetRegistry owns res://assets/characters/kael/<kind>.png.
    # His playable art therefore lives in its own folder so the registry
    # keeps reporting the collectible placeholders as art-less (honest).
    "kael": {
        "output_folder": "kael_avatar",
        "strips": {
            "idle": dict(region=(330, 312, 690, 400), count=7, frames="slot"),
            "walk": dict(region=(710, 312, 1090, 400), count=8, frames="slot"),
            "run": dict(region=(1110, 312, 1525, 400), count=8, frames="slot"),
            "attack": dict(region=(330, 442, 820, 545), count=8, frames="slot"),
            "skill": dict(region=(850, 442, 1525, 545), count=12, frames="slot"),
            "hurt": dict(region=(360, 574, 800, 680), count=4, frames="slot"),
            "death": dict(region=(855, 574, 1525, 680), count=8, frames="slot"),
        },
        # the region stops short of the PIXEL DETAIL panel's red frame line
        "views": dict(region=(330, 95, 886, 248), count=4, frames="slot"),
        # The isometric views are drawn on a checkerboard floor: flat, dim,
        # near-neutral tiles. Any opaque pixel darker than `max_luma` and
        # almost colourless is tile, not character.
        "floor_key": {"max_luma": 95, "max_saturation": 25},
        "portrait": dict(box=(24, 0, 300, 380), size=(256, 384)),
        "combat": dict(size=(128, 192)),
        "full_body": dict(size=(1024, 2048)),
        "sparkle_colour": (255, 60, 90),
        "defeat_fades": [0.62, 0.46, 0.32],
    },
}
