#!/usr/bin/env python3
"""Build a protagonist's static art assets from their concept sheet.

Source: their Project Fantasy concept sheet in ~/Downloads.

  portrait.png                 256x384   head-and-shoulders bust, cropped from
                                         the sheet's large main illustration
  combat_sprite.png            128x192   full-body pose from the character's
                                         Front view
  full_body_illustration.png  1024x2048  full-body key art

The large main illustration sits on a painted scene rather than a flat panel,
so its background cannot be colour-keyed. Instead the character's bright
pixels are masked out and the small DARK pockets enclosed by the silhouette
(choker, eye outlines, boot) are filled back in.

Run:  python tools/build_character_static.py [character_id]
"""

from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from character_sheet_config import SHEETS, VIEW_NAMES, output_folder, sheet_path  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_sheet(path: str) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGB")).astype(np.int16)


def components(mask: np.ndarray):
    """Label connected components of a boolean mask (4-neighbour)."""
    h, w = mask.shape
    lab = np.zeros((h, w), dtype=np.int32)
    sizes = {}
    cur = 0
    for y in range(h):
        for x in range(w):
            if not mask[y, x] or lab[y, x]:
                continue
            cur += 1
            stack = [(y, x)]
            lab[y, x] = cur
            n = 0
            while stack:
                cy, cx = stack.pop()
                n += 1
                for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
                    if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not lab[ny, nx]:
                        lab[ny, nx] = cur
                        stack.append((ny, nx))
            sizes[cur] = n
    return lab, sizes


def transparent_corners(img: Image.Image, size) -> Image.Image:
    img = img.convert("RGBA").resize(size, Image.LANCZOS)
    px = img.load()
    for x, y in ((0, 0), (size[0] - 1, 0), (0, size[1] - 1), (size[0] - 1, size[1] - 1)):
        px[x, y] = (0, 0, 0, 0)
    return img


def build_portrait(arr: np.ndarray, box, size) -> Image.Image:
    x0, y0, x1, y1 = box
    crop = arr[y0:y1, x0:x1]
    luma = crop.max(axis=2).astype(np.float32)
    alpha = np.clip((luma - 78.0) / 42.0, 0.0, 1.0)
    solid = alpha > 0.5
    lab, sizes = components(~solid)
    outside = lab == 0
    for key, count in sizes.items():
        if key and count < 4000 and not outside[lab == key].all():
            alpha[lab == key] = 1.0
    rgba = np.dstack([np.clip(crop, 0, 255).astype(np.uint8),
                      (alpha * 255.0).astype(np.uint8)])
    img = Image.fromarray(rgba, "RGBA")
    bbox = img.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
    if bbox:
        img = img.crop(bbox)
    return transparent_corners(img, size)


def _trim_body(img: Image.Image) -> Image.Image:
    a = np.asarray(img)
    alpha = a[..., 3]
    rows = np.nonzero((alpha > 90).sum(axis=1) > 3)[0]
    cols = np.nonzero((alpha > 90).sum(axis=0) > 3)[0]
    if rows.size == 0 or cols.size == 0:
        return img
    return img.crop((int(cols[0]), int(rows[0]),
                     int(cols[-1]) + 1, int(rows[-1]) + 1))


def build_combat_sprite(src_dir: str, size, view: str) -> Image.Image:
    """Full-body pose from the character's first view, on the combat canvas."""
    front = _trim_body(Image.open(os.path.join(src_dir, "view_%s.png" % view)).convert("RGBA"))
    w, h = front.size
    factor = min((size[0] - 8.0) / w, (size[1] - 16.0) / h)
    front = front.resize((int(w * factor), int(h * factor)), Image.LANCZOS)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(front, ((size[0] - front.width) // 2,
                                   size[1] - 2 - front.height))
    return canvas


def build_full_body(src_dir: str, size, view: str) -> Image.Image:
    """Full-body key art: the character's first view, upscaled and sharpened."""
    front = _trim_body(Image.open(os.path.join(src_dir, "view_%s.png" % view)).convert("RGBA"))
    # 900x1900 inside the 1024x2048 canvas
    bw = int(round(900.0 * size[0] / 1024.0))
    bh = int(round(1900.0 * size[1] / 2048.0))
    big = front.resize((bw, bh), Image.LANCZOS)
    big = big.filter(ImageFilter.UnsharpMask(radius=6, percent=110, threshold=2))
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    canvas.alpha_composite(big, ((size[0] - bw) // 2, size[1] - 28 - bh))
    return canvas


def main() -> None:
    character_id = sys.argv[1] if len(sys.argv) > 1 else "lilith"
    cfg = SHEETS[character_id]
    out_dir = os.path.join(ROOT, "assets", "characters", output_folder(character_id))
    src_dir = os.path.join(out_dir, "source")
    arr = load_sheet(sheet_path(character_id))
    view = VIEW_NAMES[character_id][0]

    portrait = build_portrait(arr, cfg["portrait"]["box"], cfg["portrait"]["size"])
    portrait.save(os.path.join(out_dir, "portrait.png"))
    print("[static] portrait.png %dx%d" % portrait.size)

    # some characters share their folder with the collectible-asset registry,
    # which owns <kind>.png names there; those get a sub-folder instead
    static_dir = os.path.join(out_dir, cfg.get("static_folder", ""))
    if cfg.get("static_folder"):
        os.makedirs(static_dir, exist_ok=True)

    combat = build_combat_sprite(src_dir, cfg["combat"]["size"], view)
    combat.save(os.path.join(static_dir, "combat_sprite.png"))
    print("[static] combat_sprite.png %dx%d" % combat.size)

    full = build_full_body(src_dir, cfg["full_body"]["size"], view)
    full.save(os.path.join(static_dir, "full_body_illustration.png"))
    print("[static] full_body_illustration.png %dx%d" % full.size)


if __name__ == "__main__":
    main()
