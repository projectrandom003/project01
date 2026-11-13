#!/usr/bin/env python3
"""Extract a protagonist's sprite frames from their concept sheet.

The concept sheets are the authoritative design AND contain finished
animation strips (Idle, Walk, Attack, Cast, Hurt, Death) plus four character
views (Front, Right, Back, Left).

This tool cuts those frames out of the sheet and keys the dark panel
background into a real alpha channel, writing one PNG per frame into
`assets/characters/<id>/source/` (a `.gdignore` folder, so Godot does not
import the intermediates). `tools/build_character_sheet.py` then assembles
them into the game's 8-direction x 9-state SpriteFrames.

Run:  python tools/extract_character_sheet.py [character_id]
"""

from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from character_sheet_config import SHEETS, VIEW_NAMES, output_folder, sheet_path  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Threshold used to find "bright" (character) pixels. The sheet background is
# a flat dark navy (<= ~45 luminance); the artwork is far brighter.
KEY_LUMA = 46
# Alpha ramp: a pixel is fully opaque once it is this far from the panel bg.
ALPHA_SPAN = 22.0

# The character views are laid out left-to-right on each sheet; their names
# come from character_sheet_config.VIEW_NAMES.


def load_sheet(path: str) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGB")).astype(np.int16)


def panel_bg(arr: np.ndarray, region) -> np.ndarray:
    """Median colour of the darkest pixels in the region == panel background."""
    x0, y0, x1, y1 = region
    sub = arr[y0:y1, x0:x1].reshape(-1, 3)
    luma = sub.max(axis=1)
    dark = sub[luma <= np.percentile(luma, 40)]
    return np.median(dark, axis=0)


def strip_borders(arr: np.ndarray, region) -> list[int]:
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
        best = run = 0
        for v in bright[i]:
            run = run + 1 if v else 0
            if run > best:
                best = run
        if best > 0.78 * width:
            rows.append(y0 + i)
    return rows


def key_out(rgb: np.ndarray, bg: np.ndarray) -> np.ndarray:
    """Turn the dark panel background into a clean alpha channel.

    alpha ramps with the colour distance so the soft spirit glow keeps its
    soft edge while solid artwork stays fully opaque.
    """
    diff = np.abs(rgb.astype(np.int16) - bg.reshape(1, 1, 3)).max(axis=2)
    alpha = np.clip((diff.astype(np.float32) - 6.0) / ALPHA_SPAN, 0.0, 1.0)
    alpha = np.where(alpha < 0.10, 0.0, alpha)
    return np.dstack([np.clip(rgb, 0, 255).astype(np.uint8),
                      (alpha * 255.0).astype(np.uint8)])


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


def tight_box(arr: np.ndarray, x0: int, x1: int, y0: int, y1: int):
    """Tight bounding box of the artwork inside one frame's slot."""
    sub = arr[y0:y1, x0:x1]
    mask = sub.max(axis=2) > KEY_LUMA
    if not mask.any():
        return None
    m = Image.fromarray((mask * 255).astype(np.uint8), "L")
    m = m.filter(ImageFilter.MinFilter(3))
    solid = np.asarray(m) > 0
    rows = np.nonzero(solid.any(axis=1))[0]
    cols = np.nonzero(solid.any(axis=0))[0]
    if rows.size == 0 or cols.size == 0:
        return None
    return (x0 + int(cols[0]), y0 + int(rows[0]),
            x0 + int(cols[-1]), y0 + int(rows[-1]))


def fill_enclosed_holes(alpha: np.ndarray, max_area: int = 6000):
    """Fill small DARK pockets that are fully enclosed by opaque pixels.

    Used on isometric character views: the sheet draws them standing on a
    floor tile. The character's own dark parts (coat, boots, straps) key out
    as semi-transparent pockets enclosed by the opaque art around them, so
    they are filled back in.

    Returns (new_alpha, protected_mask): the protected mask marks the pixels
    that were FILLED, i.e. character detail, so the floor key can skip them.
    """
    h, w = alpha.shape
    solid = alpha > 128
    seen = np.zeros((h, w), dtype=bool)
    stack = []
    for x in range(w):
        for y in (0, h - 1):
            if not solid[y, x] and not seen[y, x]:
                seen[y, x] = True
                stack.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if not solid[y, x] and not seen[y, x]:
                seen[y, x] = True
                stack.append((y, x))
    while stack:
        cy, cx = stack.pop()
        for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
            if 0 <= ny < h and 0 <= nx < w and not solid[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True
                stack.append((ny, nx))
    enclosed = ~seen & ~solid
    out = alpha.copy()
    out[enclosed] = 255.0
    protected = enclosed & (alpha < 128)
    return out, protected


def remove_floor(img: Image.Image, rule, protected: np.ndarray) -> Image.Image:
    """Key out the flat isometric floor tiles a character view is drawn on.

    The floor is a checkerboard of dim, near-neutral tiles. A tile pixel is
    recognised by being darker than `max_luma` and almost colourless. The
    character's own dark parts were restored by the hole fill and are marked
    as protected, so they survive the key.
    """
    if not rule:
        return img
    a = np.asarray(img).astype(np.float32).copy()
    rgb = a[..., :3]
    luma = rgb.max(axis=2)
    saturation = luma - rgb.min(axis=2)
    drop = (luma <= float(rule.get("max_luma", 95))) \
        & (saturation <= float(rule.get("max_saturation", 25))) \
        & (a[..., 3] > 0) & (~protected)
    a[..., 3] = np.where(drop, 0.0, a[..., 3])
    return Image.fromarray(a.astype(np.uint8), "RGBA")


def clean_views(img: Image.Image, rule) -> Image.Image:
    """Restore the character's dark detail, then key out the floor tile."""
    a = np.asarray(img).astype(np.uint8).copy()
    filled, protected = fill_enclosed_holes(a[..., 3].astype(np.float32))
    a[..., 3] = filled.astype(np.uint8)
    out = remove_floor(Image.fromarray(a, "RGBA"), rule, protected)
    return trim(out)


def extract(arr: np.ndarray, name: str, region, frames, count: int,
            out_dir: str, floor_key=None) -> list[str]:
    x0, y0, x1, y1 = region
    bg = panel_bg(arr, region)
    work = arr.copy()
    for by in strip_borders(arr, region):
        for dy in (-1, 0, 1):
            if y0 <= by + dy < y1:
                work[by + dy, x0:x1] = bg.reshape(1, 3)
    os.makedirs(out_dir, exist_ok=True)
    if frames == "slot":
        # evenly spaced frames across the region
        span = (x1 - x0) / float(count)
        frames = [(int(round(x0 + i * span)), int(round(x0 + (i + 1) * span)))
                  for i in range(count)]
    paths = []
    for i, frame in enumerate(frames):
        fx0, fx1 = frame[0], frame[1]
        fy0 = frame[2] if len(frame) > 2 else y0
        box = tight_box(work, fx0, fx1, fy0, y1)
        if box is None:
            print("  %s frame %d: EMPTY" % (name, i))
            continue
        bx0, by0, bx1, by1 = box
        crop = work[by0:by1 + 1, bx0:bx1 + 1]
        img = Image.fromarray(key_out(crop, bg), "RGBA")
        if floor_key:
            # clean BEFORE trimming: the character's boots sit at the bottom
            # edge of the crop and would otherwise count as border-connected
            img = clean_views(img, floor_key)
        else:
            img = trim(img)
        path = os.path.join(out_dir, "%s_%d.png" % (name, i))
        img.save(path)
        paths.append(path)
        print("  %s frame %d: box=%s size=%s" % (name, i, box, img.size))
    return paths


def main() -> None:
    character_id = sys.argv[1] if len(sys.argv) > 1 else "lilith"
    cfg = SHEETS[character_id]
    path = sheet_path(character_id)
    if not os.path.isfile(path):
        raise SystemExit("concept sheet not found: %s" % path)
    arr = load_sheet(path)
    out = os.path.join(ROOT, "assets", "characters", output_folder(character_id), "source")
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, ".gdignore"), "w", encoding="utf-8") as fh:
        fh.write("# Build intermediates for tools/build_character_sheet.py\n")

    manifest = {}
    for name, spec in cfg["strips"].items():
        print("[extract] %s" % name)
        manifest[name] = extract(arr, name, spec["region"], spec["frames"],
                                 spec["count"], out)
    print("[extract] views")
    manifest["views"] = extract(arr, "views", cfg["views"]["region"],
                                cfg["views"]["frames"], cfg["views"]["count"], out,
                                cfg.get("floor_key"))
    for i, view in enumerate(VIEW_NAMES[character_id]):
        src = manifest.get("views", [])
        if i < len(src):
            dst = os.path.join(out, "view_%s.png" % view)
            Image.open(src[i]).save(dst)
            print("  view %s <- %s" % (view, os.path.basename(src[i])))

    with open(os.path.join(out, "manifest.json"), "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=2)
    print("[extract] done -> %s" % out)


if __name__ == "__main__":
    main()
