#!/usr/bin/env python3
"""Assemble a protagonist's playable 8-direction x 9-state sprite sheets.

Source: the frames extracted from their concept sheet by
`tools/extract_character_sheet.py` (real finished artwork, not redrawn).

The game needs 9 states x 8 directions with fixed frame counts (the contract
lives in `CharacterAnimator`). The sheet provides 4 character views
(Front / Right / Back / Left) plus front-facing Idle, Walk, Attack, Cast, Hurt
and Death strips.

Mapping:
  * Rows 0/1/7 (down, down-right, down-left) use the FRONT animation frames.
    The two diagonals are the same artwork sheared around the feet, which is
    how an isometric 3/4 turn reads.
  * Row 2 (right) uses the RIGHT view, row 6 (left) the LEFT view.
  * Rows 3/4/5 (up-right, up, up-left) use the BACK view (the diagonals
    sheared the same way).
  * The non-animated rows inherit the motion measured from the front row of
    the same state, so every direction still bobs and sways in sync.

The sheet draws its strips at different scales, and every frame has a trailing
effect below the feet, so each frame is measured for its real body
(hair top -> ground line) and re-scaled / re-grounded to one common size.

Outputs (RGBA8 PNG, transparent background):
  assets/characters/<id>/<state>_sheet.png   frames*96 wide x 8*128 tall

Run:  python tools/build_character_sheet.py [character_id]
"""

from __future__ import annotations

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from character_sheet_config import ROWS, SHEETS, STATE_PLAN, VIEW_NAMES, output_folder  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CELL_W, CELL_H = 96, 128
FEET_Y = 119            # where the character's feet sit inside the cell
BODY_H = 100            # character height in pixels
SHEAR = 0.17            # horizontal shear for the 3/4 (diagonal) rows

STATE_FRAMES = {
    "idle": 5, "walk": 7, "run": 7, "interact": 6, "attack": 6,
    "damage": 2, "victory": 8, "defeat": 6, "cast": 7,
}


# ------------------------------------------------------------------ measuring

def alpha_of(img: Image.Image) -> np.ndarray:
    return np.asarray(img.getchannel("A")).astype(np.float32)


def hair_top(img: Image.Image, thr: int = 150) -> int:
    rows = np.nonzero(alpha_of(img).max(axis=1) > thr)[0]
    return int(rows[0]) if rows.size else 0


def ground_row(img: Image.Image) -> int:
    """Bottom of the character's solid silhouette.

    The trailing effect below the feet changes length per frame, so the
    ground reference is the last row that still carries a real amount of the
    character's ink, not the last non-transparent pixel.
    """
    al = alpha_of(img)
    counts = (al > 90).sum(axis=1)
    if counts.size == 0:
        return img.height - 1
    peak = int(counts.max())
    threshold = max(3, peak // 4)
    rows = np.nonzero(counts >= threshold)[0]
    if rows.size:
        return int(rows[-1])
    rows = np.nonzero(counts > 0)[0]
    return int(rows[-1]) if rows.size else img.height - 1


def body_height(img: Image.Image) -> int:
    return max(1, ground_row(img) - hair_top(img))


# ------------------------------------------------------------------ helpers

def rescale(img: Image.Image, factor: float) -> Image.Image:
    w, h = img.size
    return img.resize((max(1, int(round(w * factor))),
                       max(1, int(round(h * factor)))), Image.LANCZOS)


def shear_image(img: Image.Image, k: float, pivot_y: int) -> Image.Image:
    """Horizontal shear around the feet: the top of the sprite slides sideways.

    The canvas is WIDENED so nothing is cut off; the sprite simply leans.
    """
    if abs(k) < 1e-6:
        return img
    w, h = img.size
    a = np.asarray(img).astype(np.float32)
    reach = int(math.ceil(abs(k) * max(pivot_y, h - pivot_y))) + 2
    pad = reach + 2
    out_w = w + 2 * pad
    out = np.zeros((h, out_w, 4), dtype=np.float32)
    for y in range(h):
        s = k * (y - pivot_y)
        # dest = src + s + pad  ->  src = dest - s - pad
        xs = np.arange(out_w, dtype=np.float32) - s - pad
        xi = np.floor(xs).astype(np.int32)
        frac = (xs - xi)[:, None]
        valid = (xi >= 0) & (xi < w - 1)
        xc = np.clip(xi, 0, w - 2)
        mixed = a[y, xc] * (1.0 - frac) + a[y, xc + 1] * frac
        out[y] = np.where(valid[:, None], mixed, 0.0)
    return Image.fromarray(out.astype(np.uint8), "RGBA")


def offset(img: Image.Image, dx: int = 0, dy: int = 0) -> Image.Image:
    """Translate a sprite, EXPANDING the canvas so nothing is clipped."""
    w, h = img.size
    ox = max(0, -dx)
    oy = max(0, -dy)
    out = Image.new("RGBA", (w + abs(dx), h + abs(dy)), (0, 0, 0, 0))
    # NOTE: paste() with an RGBA mask squares the alpha, so alpha_composite
    # (proper Porter-Duff) is used instead.
    out.alpha_composite(img, (ox, oy))
    return out


def fade(img: Image.Image, factor: float) -> Image.Image:
    a = (alpha_of(img) * max(0.0, min(1.0, factor))).astype(np.uint8)
    out = img.copy()
    out.putalpha(Image.fromarray(a, "L"))
    return out


def blend(a: Image.Image, b: Image.Image, t: float) -> Image.Image:
    """Frame blend, canvases aligned on their bottom edge."""
    w = max(a.width, b.width)
    h = max(a.height, b.height)
    ca = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cb = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ca.alpha_composite(a, (0, h - a.height))
    cb.alpha_composite(b, (0, h - b.height))
    return Image.blend(ca, cb, max(0.0, min(1.0, t)))


def resample(frames: list[Image.Image], n: int) -> list[Image.Image]:
    """Resample a cyclic frame list to n frames, blending between neighbours."""
    if len(frames) == n:
        return list(frames)
    out = []
    m = len(frames)
    for i in range(n):
        pos = (i * m / float(n)) % m
        i0 = int(math.floor(pos)) % m
        i1 = (i0 + 1) % m
        out.append(blend(frames[i0], frames[i1], pos - math.floor(pos)))
    return out


def sparkle(img: Image.Image, x: int, y: int, r: int,
            colour=(255, 176, 64)) -> Image.Image:
    out = img.copy()
    d = ImageDraw.Draw(out)
    pts = [(x, y - r), (x + r * 0.28, y - r * 0.28), (x + r, y),
           (x + r * 0.28, y + r * 0.28), (x, y + r), (x - r * 0.28, y + r * 0.28),
           (x - r, y), (x - r * 0.28, y - r * 0.28)]
    d.polygon(pts, fill=colour + (235,))
    return out


# ------------------------------------------------------------------- source

def load_strips(character_id: str) -> tuple[dict, dict]:
    src = os.path.join(ROOT, "assets", "characters", output_folder(character_id), "source")
    strips = {}
    for name in ("idle", "walk", "run", "attack", "skill", "cast", "hurt", "death"):
        paths = sorted(f for f in os.listdir(src)
                       if f.startswith(name + "_") and f.endswith(".png")
                       and f.count("_") == 1)
        strips[name] = [Image.open(os.path.join(src, p)).convert("RGBA") for p in paths]
    views = {v: Image.open(os.path.join(src, "view_%s.png" % v)).convert("RGBA")
             for v in VIEW_NAMES[character_id]}
    return strips, views


def set_scale(frames: list[Image.Image], ref: float) -> float:
    """Factor that brings this source set to the common body height."""
    hs = sorted(body_height(f) for f in frames)
    if not hs:
        return 1.0
    median = hs[len(hs) // 2]
    return (ref / float(median)) if median else 1.0


def ground(img: Image.Image, feet_y: int = FEET_Y,
           anchor_x: int = CELL_W // 2) -> Image.Image:
    """Scale already applied: put the sprite in the cell with its feet down."""
    cell = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    a = alpha_of(img)
    cols = a.sum(axis=0)
    nz = np.nonzero(cols > 300)[0]
    if nz.size == 0:
        return cell
    cx = int((nz[0] + nz[-1]) * 0.5)
    dx = int(round(anchor_x - cx))
    dy = int(round(feet_y - ground_row(img)))
    cell.alpha_composite(img, (dx, dy))
    return cell


# -------------------------------------------------------------- state frames

def build_state_frames(strips: dict, state: str, cfg: dict,
                      plan: dict) -> list[Image.Image]:
    """Front-facing animation frames for one state (before direction mapping)."""
    strip, mode = plan[state]
    src = strips[strip]
    n = STATE_FRAMES[state]
    if mode == "resample":
        raw = resample(src, n)
    elif mode == "lean":
        raw = resample(src, n)
    elif mode == "first3":
        raw = resample(src[:3], n)
    elif mode == "first2":
        raw = list(src[:n])
    elif mode == "hop":
        hop = [0, -2, -5, -9, -11, -5, -2, 0]
        raw = []
        for i, dy in enumerate(hop):
            base = src[min(i % len(src), len(src) - 1)]
            raw.append(_sparkle_frame(offset(base, 0, dy), i, cfg))
    elif mode == "dissolve":
        raw = list(src)
        fades = list(cfg.get("defeat_fades", [0.5, 0.25]))
        i = 0
        while len(raw) < n:
            raw.append(fade(src[-1], fades[i % len(fades)]))
            i += 1
        raw = raw[:n]
    else:
        raise ValueError(mode)

    out = []
    for img in raw:
        if mode == "lean":
            img = shear_image(img, 0.09, ground_row(img))
        out.append(img)
    return out


def _sparkle_frame(img: Image.Image, index: int, cfg: dict) -> Image.Image:
    if index in (3, 4, 5):
        a = alpha_of(img)
        nz = np.nonzero(a.max(axis=0) > 150)[0]
        if nz.size:
            x = int((nz[0] + nz[-1]) * 0.5)
            top = int(np.nonzero(a.max(axis=1) > 150)[0][0])
            colour = cfg.get("sparkle_colour", (255, 176, 64))
            img = sparkle(img, x - 15, top + 10, 4, colour)
            img = sparkle(img, x + 14, top + 22, 3, colour)
    return img


# ------------------------------------------------------------------- assembly

def motion_of(frames: list[Image.Image]) -> list[tuple[int, int]]:
    """Per-frame (dx, dy) of the body centroid, relative to the state's mean."""
    pts = []
    for f in frames:
        a = alpha_of(f)
        nz = np.nonzero(a.max(axis=0) > 150)[0]
        rows = np.nonzero(a.max(axis=1) > 150)[0]
        if nz.size == 0 or rows.size == 0:
            pts.append(None)
            continue
        pts.append(((nz[0] + nz[-1]) * 0.5, (rows[0] + rows[-1]) * 0.5))
    valid = [p for p in pts if p]
    if not valid:
        return [(0, 0)] * len(frames)
    mx = sum(p[0] for p in valid) / len(valid)
    my = sum(p[1] for p in valid) / len(valid)
    return [(0, 0) if p is None else (int(round(p[0] - mx)), int(round(p[1] - my)))
            for p in pts]


def build_sheet(state: str, front: list[Image.Image], views: dict,
                scale: float, rows: list, character_id: str = "") -> Image.Image:
    n = STATE_FRAMES[state]
    motion = motion_of(front)
    atlas = Image.new("RGBA", (n * CELL_W, 8 * CELL_H), (0, 0, 0, 0))
    for row in range(8):
        plan = rows[row]
        source = plan["source"]
        k = float(plan.get("shear", 0.0))
        mirror = bool(plan.get("mirror", False))
        for i in range(n):
            if source == "front":
                sprite = rescale(front[i], scale)
            else:
                sprite = rescale(views[source], scale)
                dx, dy = motion[i % len(motion)]
                phase = 2.0 * math.pi * i / max(1, n)
                # the profile/back rows share one base drawing, so give each
                # frame a gentle hover: a breathing scale plus a one-pixel
                # sway. No two frames can end up identical.
                sway = int(round(1.5 * math.sin(phase)))
                breath = 1.0 + 0.035 * math.sin(phase) \
                    + 0.015 * (1.0 if i % 2 else -1.0)
                sprite = offset(sprite, dx + sway, dy)
                sprite = rescale(sprite, breath)
            if mirror:
                sprite = sprite.transpose(Image.FLIP_LEFT_RIGHT)
            if k:
                sprite = shear_image(sprite, k, ground_row(sprite))
            cell = ground(sprite)
            if character_id == "lilith" and state in ("walk", "run"):
                # Lilith travels as a spirit: animate a buoyant hover cycle,
                # not a footfall. Transform the complete cut-out around its
                # visual centre so the spectral tail rises and falls with her.
                phase = 2.0 * math.pi * i / max(1, n)
                amplitude = 3.6 if state == "run" else 2.7
                bob = int(round(math.sin(phase) * amplitude))
                sway = int(round(math.sin(phase + math.pi / 2.0) * (1.8 if state == "run" else 1.2)))
                angle = math.sin(phase) * (3.2 if state == "run" else 2.2)
                factor = 1.0 + math.sin(phase + math.pi / 2.0) * (0.022 if state == "run" else 0.016)
                cell = cell.rotate(angle, resample=Image.Resampling.BICUBIC,
                                   center=(CELL_W // 2, CELL_H // 2), expand=False)
                if abs(factor - 1.0) > 0.001:
                    scaled = cell.resize((int(CELL_W * factor), int(CELL_H * factor)),
                                         Image.Resampling.LANCZOS)
                    fitted = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
                    fitted.alpha_composite(scaled, ((CELL_W - scaled.width) // 2,
                                                    (CELL_H - scaled.height) // 2))
                    cell = fitted
                floated = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
                floated.alpha_composite(cell, (sway, bob))
                cell = floated
            atlas.paste(cell, (i * CELL_W, row * CELL_H), cell)
    return atlas


def write_previews(out_dir: str) -> None:
    """Contact sheet + animated GIFs for human review."""
    prev = os.path.join(out_dir, "preview")
    os.makedirs(prev, exist_ok=True)
    max_frames = max(STATE_FRAMES.values())
    scale = 2
    sheet = Image.new("RGBA", (max_frames * CELL_W * scale, len(STATE_FRAMES) * CELL_H * scale),
                      (16, 22, 38, 255))
    for row, state in enumerate(STATE_FRAMES):
        atlas = Image.open(os.path.join(out_dir, "%s_sheet.png" % state)).convert("RGBA")
        n = STATE_FRAMES[state]
        for i in range(n):
            frame = atlas.crop((i * CELL_W, 0, (i + 1) * CELL_W, CELL_H))
            frame = frame.resize((CELL_W * scale, CELL_H * scale), Image.LANCZOS)
            sheet.alpha_composite(frame, (i * CELL_W * scale, row * CELL_H * scale))
        frames = [atlas.crop((i * CELL_W, 0, (i + 1) * CELL_W, CELL_H)).convert("RGBA")
                  for i in range(n)]
        frames = [f.convert("P", palette=Image.ADAPTIVE) for f in frames]
        frames[0].save(os.path.join(prev, "%s.gif" % state), save_all=True,
                       append_images=frames[1:], duration=int(1000 / 12.0), loop=True)
    sheet.convert("RGB").save(os.path.join(prev, "preview_sheet.png"))
    atlas = Image.open(os.path.join(out_dir, "idle_sheet.png")).convert("RGBA")
    atlas.crop((0, 0, 5 * CELL_W, 8 * CELL_H)).save(
        os.path.join(prev, "sheet_directions.png"))
    print("[sheet] previews written")


def main() -> None:
    character_id = sys.argv[1] if len(sys.argv) > 1 else "lilith"
    cfg = SHEETS[character_id]
    out_dir = os.path.join(ROOT, "assets", "characters", output_folder(character_id))
    strips, views = load_strips(character_id)
    # One common body height for every source: the idle strip is the
    # reference, every other set is brought to it, then all of them are
    # scaled down to the in-game size.
    ref = sorted(body_height(f) for f in strips["idle"])[len(strips["idle"]) // 2]
    norm = {name: [rescale(f, set_scale(strips[name], ref)) for f in strips[name]]
            for name in strips}
    norm_views = {v: rescale(views[v], set_scale([views[v]], ref)) for v in views}
    scale = BODY_H / float(ref)
    print("[sheet] %s: reference body %d px -> scale %.4f" % (character_id, ref, scale))

    for state in STATE_FRAMES:
        front = build_state_frames(norm, state, cfg, STATE_PLAN[character_id])
        atlas = build_sheet(state, front, norm_views, scale, ROWS[character_id], character_id)
        path = os.path.join(out_dir, "%s_sheet.png" % state)
        atlas.save(path)
        print("[sheet] wrote %s_sheet.png %dx%d" % (state, atlas.width, atlas.height))

    write_previews(out_dir)


if __name__ == "__main__":
    main()
