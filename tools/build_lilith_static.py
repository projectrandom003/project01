#!/usr/bin/env python3
"""Build Lilith's static art assets from the supplied concept sheet.

Source: `Downloads/little sister` (the Project Fantasy concept sheet).

  portrait.png              256x384  head-and-shoulders bust, cropped from the
                                    sheet's large main illustration
  combat_sprite.png         128x192  full-body casting pose from the
                                    character's Front view
  full_body_illustration.png 1024x2048  full-body key art

The dark navy scene background is keyed out into a real alpha channel, the
same way `tools/extract_lilith_sheet.py` does for the sprite frames.

Run:  python tools/build_lilith_static.py
"""

from __future__ import annotations

import os

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEET_PATH = os.path.join(os.environ.get("USERPROFILE", os.path.expanduser("~")),
                          "Downloads", "little sister")
SRC = os.path.join(ROOT, "assets", "characters", "lilith", "source")
OUT = os.path.join(ROOT, "assets", "characters", "lilith")

KEY_LUMA = 46
ALPHA_SPAN = 22.0

# The large main illustration on the left of the sheet: her head, the skull
# bow and the chest bow. This is the only high-resolution artwork of her.
PORTRAIT_BOX = (70, 36, 350, 456)      # x0, y0, x1, y1
PORTRAIT_SIZE = (256, 384)


def load_sheet() -> np.ndarray:
    return np.asarray(Image.open(SHEET_PATH).convert("RGB")).astype(np.int16)


def key_out(rgb: np.ndarray, bg: np.ndarray) -> np.ndarray:
    diff = np.abs(rgb.astype(np.int16) - bg.reshape(1, 1, 3)).max(axis=2)
    alpha = np.clip((diff.astype(np.float32) - 6.0) / ALPHA_SPAN, 0.0, 1.0)
    alpha = np.where(alpha < 0.10, 0.0, alpha)
    return np.dstack([np.clip(rgb, 0, 255).astype(np.uint8),
                      (alpha * 255.0).astype(np.uint8)])


def local_bg(arr: np.ndarray, box: tuple[int, int, int, int]) -> np.ndarray:
    x0, y0, x1, y1 = box
    sub = arr[y0:y1, x0:x1].reshape(-1, 3)
    luma = sub.max(axis=1)
    dark = sub[luma <= np.percentile(luma, 22)]
    return np.median(dark, axis=0)


def drop_specks(img: Image.Image, min_pixels: int = 40) -> Image.Image:
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


def transparent_corners(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    img = img.convert("RGBA").resize(size, Image.LANCZOS)
    px = img.load()
    for x, y in ((0, 0), (size[0] - 1, 0), (0, size[1] - 1), (size[1] * 0 + size[0] - 1, size[1] - 1)):
        px[x, y] = (0, 0, 0, 0)
    return img


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


def build_portrait(arr: np.ndarray) -> Image.Image:
    """Bust portrait from the sheet's large main illustration.

    The big illustration sits on a painted graveyard scene rather than a flat
    panel, so the background cannot be colour-keyed. Instead the character's
    bright pixels are masked out and the small DARK pockets enclosed by her
    silhouette (choker, eye outlines, boot) are filled back in.
    """
    x0, y0, x1, y1 = PORTRAIT_BOX
    crop = arr[y0:y1, x0:x1]
    luma = crop.max(axis=2).astype(np.float32)
    alpha = np.clip((luma - 78.0) / 42.0, 0.0, 1.0)
    solid = alpha > 0.5
    lab, sizes = components(~solid)
    outside = lab == 0
    for key, size in sizes.items():
        if key and size < 4000 and not outside[lab == key].all():
            alpha[lab == key] = 1.0
    rgba = np.dstack([np.clip(crop, 0, 255).astype(np.uint8),
                      (alpha * 255.0).astype(np.uint8)])
    img = Image.fromarray(rgba, "RGBA")
    bbox = img.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
    if bbox:
        img = img.crop(bbox)
    return transparent_corners(img, PORTRAIT_SIZE)


def build_combat_sprite() -> Image.Image:
    """Full-body pose from the character's Front view, on the 128x192 canvas."""
    front = Image.open(os.path.join(SRC, "view_front.png")).convert("RGBA")
    a = np.asarray(front)
    alpha = a[..., 3]
    rows = np.nonzero((alpha > 90).sum(axis=1) > 3)[0]
    cols = np.nonzero((alpha > 90).sum(axis=0) > 3)[0]
    front = front.crop((int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1))
    w, h = front.size
    factor = min(120.0 / w, 176.0 / h)
    front = front.resize((int(w * factor), int(h * factor)), Image.LANCZOS)
    canvas = Image.new("RGBA", (128, 192), (0, 0, 0, 0))
    canvas.alpha_composite(front, ((128 - front.width) // 2, 190 - front.height))
    return canvas


def build_full_body() -> Image.Image:
    """Full-body key art: the Front view, upscaled and sharpened."""
    front = Image.open(os.path.join(SRC, "view_front.png")).convert("RGBA")
    a = np.asarray(front)
    alpha = a[..., 3]
    rows = np.nonzero((alpha > 90).sum(axis=1) > 3)[0]
    cols = np.nonzero((alpha > 90).sum(axis=0) > 3)[0]
    front = front.crop((int(cols[0]), int(rows[0]), int(cols[-1]) + 1, int(rows[-1]) + 1))
    big = front.resize((900, 1900), Image.LANCZOS)
    big = big.filter(ImageFilter.UnsharpMask(radius=6, percent=110, threshold=2))
    canvas = Image.new("RGBA", (1024, 2048), (0, 0, 0, 0))
    canvas.alpha_composite(big, ((1024 - big.width) // 2, 2020 - big.height))
    return canvas


def main() -> None:
    arr = load_sheet()
    portrait = build_portrait(arr)
    portrait.save(os.path.join(OUT, "portrait.png"))
    print("[static] portrait.png %dx%d" % portrait.size)

    combat = build_combat_sprite()
    combat.save(os.path.join(OUT, "combat_sprite.png"))
    print("[static] combat_sprite.png %dx%d" % combat.size)

    full = build_full_body()
    full.save(os.path.join(OUT, "full_body_illustration.png"))
    print("[static] full_body_illustration.png %dx%d" % full.size)


if __name__ == "__main__":
    main()
