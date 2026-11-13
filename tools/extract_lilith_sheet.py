#!/usr/bin/env python3
"""Extract Lilith's sprite frames from the supplied concept sheet.

The concept sheet ("little sister") is the authoritative design for the
character AND already contains finished animation strips (Idle, Walk, Attack,
Cast, Hurt, Death) plus four character views (Front, Right, Back, Left).

This tool cuts those frames out of the sheet and keys out the dark navy panel
background into a real alpha channel, writing one PNG per frame into
`assets/characters/lilith/source/` (a `.gdignore` folder, so Godot does not
import the intermediates). `tools/build_lilith_sheet.py` then assembles them
into the game's 8-direction x 9-state SpriteFrames.

Run:  python tools/extract_lilith_sheet.py
"""

from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEET_PATH = os.path.join(os.environ.get("USERPROFILE", os.path.expanduser("~")),
                          "Downloads", "little sister")
OUT = os.path.join(ROOT, "assets", "characters", "lilith", "source")

# Threshold used to find "bright" (character) pixels. The sheet background is
# a flat dark navy (~1,6,15); the artwork is far brighter.
KEY_LUMA = 46
# Alpha ramp: a pixel is fully opaque once it is this far from the panel bg.
ALPHA_SPAN = 22.0

# Strip definitions: name -> (x0, x1, y0, y1, frame_count).
# The x range is divided into `frame_count` equal slots; each slot is then
# tightened to the artwork it contains. The sheet frames are evenly spaced,
# so this is stable even when a spirit effect bridges two frames.
STRIPS = {
    "idle":   (655, 950, 368, 506, 4),
    "walk":   (990, 1516, 368, 506, 8),
    "attack": (655, 1432, 556, 686, 7),
    "cast":   (648, 962, 732, 866, 4),
    "hurt":   (988, 1172, 732, 862, 3),
    "death":  (1218, 1516, 732, 864, 4),
    "views":  (808, 1330, 52, 252, 4),
}
# The character views are labelled left-to-right on the sheet.
VIEW_NAMES = ["front", "right", "back", "left"]


def load_sheet() -> np.ndarray:
    return np.asarray(Image.open(SHEET_PATH).convert("RGB")).astype(np.int16)


def panel_bg(arr: np.ndarray, region: tuple[int, int, int, int]) -> np.ndarray:
    """Median colour of the darkest pixels in the region == panel background."""
    x0, y0, x1, y1 = region
    sub = arr[y0:y1, x0:x1].reshape(-1, 3)
    luma = sub.max(axis=1)
    dark = sub[luma <= np.percentile(luma, 40)]
    return np.median(dark, axis=0)


def strip_borders(arr: np.ndarray, region: tuple[int, int, int, int]) -> list[int]:
    """Rows that are a panel border line (to be ignored).

    A border line is one long CONTINUOUS bright run spanning the panel. The
    characters themselves also make wide rows, but their ink is broken into
    separate per-character runs, so the longest-run test tells them apart.
    """
    x0, y0, x1, y1 = region
    luma = arr[y0:y1, x0:x1].max(axis=2)
    bright = luma > KEY_LUMA
    width = x1 - x0
    rows = []
    for i in range(bright.shape[0]):
        line = bright[i]
        best = run = 0
        for v in line:
            run = run + 1 if v else 0
            if run > best:
                best = run
        if best > 0.78 * width:
            rows.append(y0 + i)
    return rows


def key_out(rgb: np.ndarray, bg: np.ndarray) -> np.ndarray:
    """Turn the dark panel background into a clean alpha channel.

    The background is a flat, very dark navy. alpha ramps with the colour
    distance so the soft blue spirit glow keeps its soft edge while solid
    artwork stays fully opaque.
    """
    diff = np.abs(rgb.astype(np.int16) - bg.reshape(1, 1, 3)).max(axis=2)
    alpha = np.clip((diff.astype(np.float32) - 6.0) / ALPHA_SPAN, 0.0, 1.0)
    alpha = np.where(alpha < 0.10, 0.0, alpha)
    return np.dstack([np.clip(rgb, 0, 255).astype(np.uint8),
                      (alpha * 255.0).astype(np.uint8)])


def tight_box(arr: np.ndarray, region: tuple[int, int, int, int]
              ) -> tuple[int, int, int, int] | None:
    """Tight bounding box of the artwork inside a slot."""
    x0, y0, x1, y1 = region
    sub = arr[y0:y1, x0:x1]
    mask = sub.max(axis=2) > KEY_LUMA
    if not mask.any():
        return None
    # erode away thin panel borders / flourishes before measuring
    m = Image.fromarray((mask * 255).astype(np.uint8), "L")
    m = m.filter(ImageFilter.MinFilter(3))
    solid = np.asarray(m) > 0
    rows = np.nonzero(solid.any(axis=1))[0]
    cols = np.nonzero(solid.any(axis=0))[0]
    if rows.size == 0 or cols.size == 0:
        return None
    return (x0 + int(cols[0]), y0 + int(rows[0]),
            x0 + int(cols[-1]), y0 + int(rows[-1]))


def drop_specks(img: Image.Image, min_pixels: int = 16) -> Image.Image:
    """Remove tiny detached blobs (panel flourishes, stray pixels)."""
    a = np.asarray(img).astype(np.uint8).copy()
    mask = a[..., 3] > 20
    h, w = mask.shape
    seen = np.zeros((h, w), dtype=bool)
    for y in range(h):
        for x in range(w):
            if not mask[y, x] or seen[y, x]:
                continue
            stack = [(y, x)]
            seen[y, x] = True
            blob = []
            while stack:
                cy, cx = stack.pop()
                blob.append((cy, cx))
                for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
                    if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        stack.append((ny, nx))
            if len(blob) < min_pixels:
                for by, bx in blob:
                    a[by, bx] = (0, 0, 0, 0)
    return Image.fromarray(a, "RGBA")


def trim(img: Image.Image) -> Image.Image:
    img = drop_specks(img)
    bbox = img.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
    return img.crop(bbox) if bbox else img


def extract(arr: np.ndarray, name: str, region, count: int, out_dir: str) -> list[str]:
    x0, x1, y0, y1 = region
    bg = panel_bg(arr, (x0, y0, x1, y1))
    # paint the decorative panel borders out with the background colour so
    # they can never be keyed as artwork
    work = arr.copy()
    for by in strip_borders(arr, (x0, y0, x1, y1)):
        for dy in (-1, 0, 1):
            if y0 <= by + dy < y1:
                work[by + dy, x0:x1] = bg.reshape(1, 3)
    os.makedirs(out_dir, exist_ok=True)
    paths = []
    span = (x1 - x0) / float(count)
    for i in range(count):
        sx0 = int(round(x0 + i * span))
        sx1 = int(round(x0 + (i + 1) * span))
        box = tight_box(work, (sx0, y0, sx1, y1))
        if box is None:
            print("  %s frame %d: EMPTY" % (name, i))
            continue
        bx0, by0, bx1, by1 = box
        crop = work[by0:by1 + 1, bx0:bx1 + 1]
        img = trim(Image.fromarray(key_out(crop, bg), "RGBA"))
        path = os.path.join(out_dir, "%s_%d.png" % (name, i))
        img.save(path)
        paths.append(path)
        print("  %s frame %d: box=%s size=%s" % (name, i, box, img.size))
    return paths


def main() -> None:
    if not os.path.isfile(SHEET_PATH):
        raise SystemExit("concept sheet not found: %s" % SHEET_PATH)
    arr = load_sheet()
    os.makedirs(OUT, exist_ok=True)
    # keep Godot from importing the intermediates
    with open(os.path.join(OUT, ".gdignore"), "w", encoding="utf-8") as fh:
        fh.write("# Build intermediates for tools/build_lilith_sheet.py\n")

    manifest = {}
    for name, (x0, x1, y0, y1, count) in STRIPS.items():
        print("[extract] %s (%d frames)" % (name, count))
        paths = extract(arr, name, (x0, x1, y0, y1), count, OUT)
        manifest[name] = paths
    for i, view in enumerate(VIEW_NAMES):
        src = manifest.get("views", [])
        if i < len(src):
            dst = os.path.join(OUT, "view_%s.png" % view)
            Image.open(src[i]).save(dst)
            print("  view %s <- %s" % (view, os.path.basename(src[i])))

    with open(os.path.join(OUT, "manifest.json"), "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=2)
    print("[extract] done -> %s" % OUT)


if __name__ == "__main__":
    main()
