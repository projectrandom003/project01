#!/usr/bin/env python3
"""Generate Lilith's 2D isometric character art.

This is an ORIGINAL vector-style illustration built from Lilith's documented
design brief (white hair, blue eyes, spirit aura, blue-grey dress). It does not
crop or trace the supplied reference sheet; it is reproducible placeholder-to-
production art so the playable-character pipeline has real disk assets.

Outputs (all RGBA8 PNG, transparent background):
  assets/characters/lilith/portrait.png                 256x384
  assets/characters/lilith/combat_sprite.png            128x192
  assets/characters/lilith/full_body_illustration.png   1024x2048
  assets/characters/lilith/<state>.png                  frames*96 x 8*128
  assets/characters/lilith/preview/*.png / *.gif        human inspection only

Run:  python tools/generate_lilith_art.py
"""

from __future__ import annotations

import math
import os
from PIL import Image, ImageDraw

# ------------------------------------------------------------------ constants

S = 4                      # supersampling factor for world frames
FRAME_W, FRAME_H = 96, 128
WORLD_SCALE = 1.18         # match the ~95 px placeholder silhouette on 128 px
ROWS = 8                   # direction rows: down .. down_left
FPS = {
    "idle": 9, "walk": 12, "run": 14, "interact": 12, "attack": 15,
    "damage": 12, "victory": 12, "defeat": 10, "cast": 12,
}
FRAMES = {
    "idle": 5, "walk": 7, "run": 7, "interact": 6, "attack": 6,
    "damage": 2, "victory": 8, "defeat": 6, "cast": 7,
}
LOOP = {
    "idle": True, "walk": True, "run": True, "interact": False,
    "attack": False, "damage": False, "victory": False, "defeat": False,
    "cast": False,
}
STATES = ["idle", "walk", "run", "interact", "attack", "damage",
          "victory", "defeat", "cast"]

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "characters", "lilith")
PREVIEW = os.path.join(OUT, "preview")

# ------------------------------------------------------------------- palette
# Read off the supplied concept sheet ("little sister"): the five swatches
# printed beside the character are white / pale blue-grey / light blue /
# medium blue / dark navy. The dress is WHITE (not blue); the dark navy is
# used for the bows, choker and thigh-highs; the bright cyan is the spirit
# glow and her eye colour.
OUTLINE = (26, 36, 60, 255)
HAIR = (244, 247, 252, 255)
HAIR_LIGHT = (255, 255, 255, 255)
HAIR_SHADE = (200, 212, 231, 255)
HAIR_DEEP = (151, 170, 199, 255)
SKIN = (243, 233, 236, 255)
SKIN_SHADE = (216, 203, 212, 255)
SKIN_LINE = (164, 146, 158, 255)
EYE_DARK = (34, 62, 106, 255)
EYE_BLUE = (72, 156, 219, 255)
IRIS = (124, 214, 250, 255)
IRIS_LIGHT = (216, 247, 255, 255)
DRESS = (237, 241, 248, 255)
DRESS_LIGHT = (252, 253, 255, 255)
DRESS_SHADE = (203, 214, 231, 255)
TRIM = (186, 205, 227, 255)
ACCENT = (127, 212, 255, 255)
ACCENT_DEEP = (56, 138, 199, 255)
NAVY = (43, 58, 92, 255)
NAVY_DEEP = (26, 36, 60, 255)
BOOT = (29, 39, 62, 255)
WHITE = (255, 255, 255, 255)
BLUSH = (233, 172, 192, 110)
SHADOW = (12, 20, 38, 64)


def rgba(c, a):
    return (c[0], c[1], c[2], a)


# ------------------------------------------------------------------- drawing

class Pen:
    """A tiny vector pen with three composited layers.

    Pillow's ImageDraw only alpha-BLENDS when the target image is RGB; on an
    RGBA target it REPLACES pixels (alpha included). So translucent shapes are
    drawn onto dedicated overlay canvases and composited with
    Image.alpha_composite at the end:
        under  -> shadow, spirit aura, spectral tail (behind the character)
        main   -> the opaque character
        over   -> blush, wisps, sparkles, spell flashes (in front)
    """

    def __init__(self, w: int, h: int, ss: int = S):
        self.w, self.h, self.ss = w, h, ss
        size = (w * ss, h * ss)
        self._layers = {
            "under": Image.new("RGBA", size, (0, 0, 0, 0)),
            "main": Image.new("RGBA", size, (0, 0, 0, 0)),
            "over": Image.new("RGBA", size, (0, 0, 0, 0)),
        }
        self._draws = {k: ImageDraw.Draw(v, "RGBA") for k, v in self._layers.items()}
        self._target = "main"

    # -- layer routing -----------------------------------------------------
    def layer(self, name: str) -> None:
        self._target = name if name in self._layers else "main"

    def _d(self):
        return self._draws[self._target]

    def _p(self, pts):
        s = self.ss
        return [(x * s, y * s) for x, y in pts]

    def poly(self, pts, fill, outline=None, ow=1.0):
        p = self._p(pts)
        if len(p) < 3:
            return
        d = self._d()
        d.polygon(p, fill=fill)
        if outline is not None and ow > 0:
            d.line(p + [p[0]], fill=outline,
                   width=max(1, round(ow * self.ss)), joint="curve")

    def ell(self, cx, cy, rx, ry, fill, outline=None, ow=1.0):
        s = self.ss
        box = [(cx - rx) * s, (cy - ry) * s, (cx + rx) * s, (cy + ry) * s]
        d = self._d()
        d.ellipse(box, fill=fill)
        if outline is not None and ow > 0:
            d.ellipse(box, outline=outline,
                      width=max(1, round(ow * self.ss)))

    def line(self, pts, fill, w, cap=True):
        s = self.ss
        p = [(x * s, y * s) for x, y in pts]
        d = self._d()
        d.line(p, fill=fill, width=max(1, round(w * s)), joint="curve")
        if cap:
            r = max(1.0, w * s * 0.5)
            for x, y in (p[0], p[-1]):
                d.ellipse([x - r, y - r, x + r, y + r], fill=fill)

    def arc(self, cx, cy, rx, ry, a0, a1, fill, w):
        s = self.ss
        self._d().arc([(cx - rx) * s, (cy - ry) * s,
                       (cx + rx) * s, (cy + ry) * s],
                      a0, a1, fill=fill, width=max(1, round(w * s)))

    def star(self, cx, cy, r, fill):
        pts = [(cx, cy - r), (cx + r * 0.28, cy - r * 0.28),
               (cx + r, cy), (cx + r * 0.28, cy + r * 0.28),
               (cx, cy + r), (cx - r * 0.28, cy + r * 0.28),
               (cx - r, cy), (cx - r * 0.28, cy - r * 0.28)]
        self.poly(pts, fill)

    # -- global fade (defeat / dissolve) ------------------------------------
    def fade(self, factor: float) -> None:
        if factor >= 0.999:
            return
        f = max(0.0, min(1.0, factor))
        for layer in self._layers.values():
            alpha = layer.getchannel("A").point(lambda v: int(v * f))
            layer.putalpha(alpha)

    def finish(self) -> Image.Image:
        img = Image.alpha_composite(self._layers["under"], self._layers["main"])
        img = Image.alpha_composite(img, self._layers["over"])
        return img.resize((self.w, self.h), Image.LANCZOS)


class XPen:
    """Translate/scale a local character space into a Pen's pixel space."""

    def __init__(self, pen: Pen, ox: float, oy: float, k: float):
        self.pen, self.ox, self.oy, self.k = pen, ox, oy, k
        ## Line-weight multiplier: 1.0 for 96px world frames, lower for the
        ## large key illustration so the ink does not turn into slabs.
        self.ow = 1.0
        ## Spirit-aura multiplier; shrunk for the big key illustration so the
        ## glow stays inside the canvas instead of being clipped.
        self.aura = 1.0

    def _p(self, pts):
        return [(self.ox + x * self.k, self.oy + y * self.k) for x, y in pts]

    def poly(self, pts, fill, outline=None, ow=1.0):
        self.pen.poly(self._p(pts), fill, outline, ow * self.k * self.ow)

    def ell(self, cx, cy, rx, ry, fill, outline=None, ow=1.0):
        self.pen.ell(self.ox + cx * self.k, self.oy + cy * self.k,
                     rx * self.k, ry * self.k, fill, outline, ow * self.k * self.ow)

    def line(self, pts, fill, w, cap=True):
        self.pen.line(self._p(pts), fill, w * self.k, cap)

    def arc(self, cx, cy, rx, ry, a0, a1, fill, w):
        self.pen.arc(self.ox + cx * self.k, self.oy + cy * self.k,
                     rx * self.k, ry * self.k, a0, a1, fill, w * self.k)

    def star(self, cx, cy, r, fill):
        self.pen.star(self.ox + cx * self.k, self.oy + cy * self.k,
                      r * self.k, fill)

    # -- layer routing -----------------------------------------------------
    def layer(self, name: str) -> "XPen":
        self.pen.layer(name)
        return self

    def fade(self, factor: float) -> None:
        self.pen.fade(factor)


# ------------------------------------------------------------- pose function

def pose_for(state: str, i: int, n: int) -> dict:
    t = i / float(n)
    ph = 2.0 * math.pi * t
    p = {
        "bob": 0.0, "sway": 0.0, "lean": 0.0, "stride": 0.0,
        "arm": 0.0, "arm_raise": 0.0, "reach": 0.0, "hair": 0.0,
        "head_tilt": 0.0, "kneel": 0.0, "alpha": 1.0, "orb": 0.0,
        "slash": 0.0, "sparkle": 0.0, "flash": 0.0, "blink": False,
        "wisp": t,
    }
    if state == "idle":
        p["bob"] = math.sin(ph) * 1.2
        p["hair"] = math.sin(ph + 0.9) * 1.5
        p["arm"] = math.sin(ph + 1.1) * 0.7
        p["head_tilt"] = math.sin(ph + 0.4) * 0.8
        p["blink"] = i == 3
    elif state == "walk":
        p["stride"] = math.sin(ph) * 6.0
        p["bob"] = abs(math.sin(ph)) * 1.7
        p["arm"] = -math.sin(ph) * 4.6
        p["hair"] = math.sin(ph - 0.7) * 1.8
        p["lean"] = 1.0
        p["head_tilt"] = math.sin(ph) * 0.7
    elif state == "run":
        p["stride"] = math.sin(ph) * 9.0
        p["bob"] = abs(math.sin(ph)) * 2.6
        p["arm"] = -math.sin(ph) * 7.5
        p["hair"] = math.sin(ph - 0.9) * 3.0
        p["lean"] = 2.6
        p["head_tilt"] = math.sin(ph) * 1.2
    elif state == "interact":
        reach = math.sin(math.pi * min(1.0, t * 1.1))
        p["reach"] = reach
        p["arm"] = 2.0 * reach
        p["bob"] = -1.0 * reach
        p["sparkle"] = reach
        p["head_tilt"] = 1.5 * reach
        p["hair"] = math.sin(ph) * 1.0
    elif state == "attack":
        # A six-beat spirit blast: wind-up, charge, release, full extension,
        # dissipate, recover. Every beat must differ from its neighbours.
        if i == 0:
            p["arm"] = -6.0
            p["lean"] = -2.0
            p["head_tilt"] = -2.4
            p["hair"] = -2.0
            p["bob"] = -0.6
        elif i == 1:
            p["arm"] = 2.5
            p["lean"] = -0.6
            p["slash"] = 0.30
            p["reach"] = 0.20
            p["hair"] = 0.4
            p["bob"] = 0.4
        elif i == 2:
            p["arm"] = 6.0
            p["lean"] = 1.6
            p["slash"] = 0.80
            p["reach"] = 0.55
            p["hair"] = 1.4
            p["bob"] = -0.8
        elif i == 3:
            p["arm"] = 9.5
            p["lean"] = 3.2
            p["slash"] = 1.0
            p["reach"] = 1.0
            p["hair"] = 2.8
            p["bob"] = -1.6
            p["sparkle"] = 0.55
        elif i == 4:
            p["arm"] = 5.0
            p["lean"] = 1.4
            p["slash"] = 0.55
            p["reach"] = 0.45
            p["hair"] = 1.2
            p["bob"] = -0.4
        else:
            p["arm"] = 1.2
            p["lean"] = 0.3
            p["slash"] = 0.14
            p["hair"] = 0.4
    elif state == "damage":
        p["sway"] = -3.0 if i == 0 else -1.2
        p["lean"] = -2.5
        p["head_tilt"] = -4.0 if i == 0 else -2.0
        p["hair"] = -3.0
        p["flash"] = 0.40 if i == 0 else 0.18
        p["blink"] = True
    elif state == "victory":
        p["bob"] = math.sin(math.pi * t) * 7.0
        p["arm_raise"] = 1.0
        p["arm"] = math.sin(ph * 2.0) * 2.0
        p["hair"] = math.sin(ph * 2.0 + 0.6) * 2.4
        p["sparkle"] = 0.6 + 0.4 * math.sin(ph * 2.0)
        p["head_tilt"] = -2.0
    elif state == "defeat":
        p["kneel"] = min(1.0, t * 1.45)
        p["alpha"] = max(0.35, 1.0 - t * 0.62)
        p["head_tilt"] = 10.0 * p["kneel"]
        p["hair"] = -1.5
        p["arm"] = -1.0
        p["bob"] = 1.5 * p["kneel"]
        p["blink"] = True
    elif state == "cast":
        grow = min(1.0, t * 1.35)
        p["orb"] = grow
        p["reach"] = 0.55 + 0.45 * grow
        p["arm"] = 1.5
        p["bob"] = -1.6 * grow
        p["hair"] = math.sin(ph * 2.0) * 2.0 - 1.0 * grow
        p["sparkle"] = 0.35 * grow
    return p


# --------------------------------------------------------------- character

# Direction -> (screen side factor, depth factor). Rows 5-7 mirror 3-1.
_DIRS = [(0.0, 1.0), (0.55, 0.55), (1.0, 0.0), (0.55, -0.55), (0.0, -1.0)]

# Chibi skeleton, in local units (feet at y = 0, up is negative).
HEAD_R = 13.6
HEAD_CY = -61.0
CHIN_Y = HEAD_CY + HEAD_R * 0.92      # -48.5
NECK_Y = -46.0
SH_Y = -43.0                          # shoulder line
HIP_Y = -31.0                         # waist
HEM_Y = -18.0                         # skirt hem
ANKLE_Y = -3.2
SOCK_Y = -21.0                        # top of the navy thigh-high


def _ruffle(xp, cx, y, half_w, tier_h, color, outline=None, ow=0.8, lobes=5):
    """A scalloped ruffle tier (white lace edge)."""
    pts = [(cx - half_w, y)]
    for i in range(lobes):
        x0 = cx - half_w + 2.0 * half_w * (i / float(lobes))
        x1 = cx - half_w + 2.0 * half_w * ((i + 1) / float(lobes))
        pts.append((x0, y + tier_h))
        pts.append((x1, y + tier_h * 0.22))
    pts.append((cx + half_w, y))
    xp.poly(pts, color, outline, ow)


def _torn_hem(xp, cx, y, half_w, drop, color, outline=None, ow=0.8, points=6):
    """A ragged, torn hem: the sheet shows her dress frayed at the bottom."""
    pts = [(cx - half_w, y)]
    for i in range(points):
        x0 = cx - half_w + 2.0 * half_w * (i / float(points))
        x1 = cx - half_w + 2.0 * half_w * ((i + 1) / float(points))
        depth = drop * (0.55 if i % 2 == 0 else 1.0)
        pts.append((x0, y + depth))
        pts.append(((x0 + x1) * 0.5, y + depth * 0.25))
    pts.append((cx + half_w, y))
    xp.poly(pts, color, outline, ow)


def _lobes(xp, lobes, fill, outline=None, grow=1.0):
    """Draw a rounded organic mass from overlapping ellipses.

    The outline is a slightly enlarged copy drawn BEHIND the fill, so the
    union silhouette is inked while the internal seams stay hidden.
    """
    if outline is not None:
        for (lx, ly, lrx, lry) in lobes:
            xp.ell(lx, ly, lrx + grow, lry + grow, outline)
    for (lx, ly, lrx, lry) in lobes:
        xp.ell(lx, ly, lrx, lry, fill)


def _skull_bow(xp, x, y, s, alpha_fn):
    """The signature black bow + skull hair ornament."""
    navy = alpha_fn(NAVY)
    ink = alpha_fn(OUTLINE)
    xp.poly([(x - 6.6 * s, y), (x - 1.6 * s, y - 3.4 * s), (x - 1.6 * s, y + 3.4 * s)],
            navy, ink, 0.8)
    xp.poly([(x + 6.6 * s, y), (x + 1.6 * s, y - 3.4 * s), (x + 1.6 * s, y + 3.4 * s)],
            navy, ink, 0.8)
    xp.ell(x, y, 2.7 * s, 3.0 * s, alpha_fn(WHITE), ink, 0.7)
    xp.ell(x - 1.0 * s, y - 0.5 * s, 0.8 * s, 0.9 * s, navy)
    xp.ell(x + 1.0 * s, y - 0.5 * s, 0.8 * s, 0.9 * s, navy)
    xp.line([(x - 0.7 * s, y + 1.5 * s), (x + 0.7 * s, y + 1.5 * s)], navy, 0.6 * s)


def _mini_ghost(xp, x, y, s, alpha_fn):
    """One of the little blue souls that orbit her."""
    body = alpha_fn(ACCENT)
    dark = alpha_fn(NAVY_DEEP)
    xp.ell(x, y, 2.5 * s, 3.1 * s, body)
    xp.poly([(x - 2.3 * s, y + 0.6 * s), (x, y + 4.6 * s), (x + 2.3 * s, y + 0.6 * s)], body)
    xp.ell(x - 0.9 * s, y - 0.2 * s, 0.5 * s, 0.7 * s, dark)
    xp.ell(x + 0.9 * s, y - 0.2 * s, 0.5 * s, 0.7 * s, dark)


def draw_character(xp: XPen, direction: int, pose: dict) -> None:
    """Draw one chibi Lilith frame in local space (0,0 = feet centre).

    Modelled on the supplied concept sheet: white voluminous side-ponytail
    with a black skull bow, big cyan anime eyes, a white frilly torn dress
    with a navy chest bow and gem choker, navy thigh-highs and a blue
    spectral aura with orbiting soul wisps.
    """
    sx, dz = _DIRS[direction]
    front = dz > -0.55
    back = dz < -0.55
    profile = abs(sx) > 0.92
    bw = 1.0 - 0.16 * abs(sx)
    alpha = pose["alpha"]
    by = -pose["bob"]
    cx = pose["sway"]
    kneel = pose["kneel"]
    upper = kneel * 5.0
    lean = pose["lean"] * 0.45
    hs = pose["hair"]

    def A(c):
        # Opaque: the pose-wide fade is applied once, globally, at the end.
        return (c[0], c[1], c[2], 255)

    # ---------------------------------------------------------- ground shadow
    xp.layer("under")
    for r, a in ((12.0, 26), (8.0, 34), (4.8, 46)):
        xp.ell(cx, 0.4, r, r * 0.20, (10, 18, 36, a))

    # ------------------------------------------------------------- spirit aura
    au = xp.aura
    xp.ell(cx + sx * 2.0, by - 34.0, 25.0 * au, 33.0 * au,
           (ACCENT[0], ACCENT[1], ACCENT[2], 20))
    xp.ell(cx + sx * 2.0, by - 36.0, 17.0 * au, 24.0 * au,
           (ACCENT[0], ACCENT[1], ACCENT[2], 16))
    # spectral tail under the hem
    xp.poly([
        (cx - 9.0, by - 14.0), (cx + 9.0, by - 14.0),
        (cx + 5.0, by - 3.0), (cx, by + 2.0), (cx - 5.0, by - 3.0),
    ], (ACCENT[0], ACCENT[1], ACCENT[2], 60))
    xp.layer("main")

    # ---------------------------------------------------------- head position
    hcx = cx + sx * 3.0 + pose["head_tilt"] * 0.30
    hcy = by + HEAD_CY + upper + pose["head_tilt"] * 0.12

    # ponytail anchor: behind the head in profile, screen-right from the front,
    # screen-left from behind (same head, opposite side).
    if profile:
        pony_base = (hcx - sx * 10.5, hcy - 9.5)
        pony_tip = (hcx - sx * 27.0, hcy + 15.0)
    elif back:
        pony_base = (hcx - 8.5, hcy - 10.5)
        pony_tip = (hcx - 25.0, hcy + 14.0)
    else:
        pony_base = (hcx + 8.5, hcy - 10.5)
        pony_tip = (hcx + 26.0, hcy + 13.0)
    pdir = 1.0 if pony_tip[0] >= pony_base[0] else -1.0

    # ------------------------------------------------------------ back hair mass
    # ONE continuous rounded mass: the cap, the side falls and the swept
    # ponytail all share a single inked silhouette.
    hair_lobes = [
        (hcx, hcy - 4.0, 15.0, 13.0),
        (hcx - 9.5, hcy + 8.0, 7.5, 12.0),
        (hcx + 9.5, hcy + 8.0, 7.5, 12.0),
        (hcx - 10.5, hcy + 22.0, 6.0, 10.0),
        (hcx + 10.5, hcy + 22.0, 6.0, 10.0),
        (hcx - 8.5, hcy + 33.0, 5.0, 7.5),
        (hcx + 8.5, hcy + 33.0, 5.0, 7.5),
    ]
    for (ox, oy, rx, ry) in [(1.0, -4.0, 6.6, 6.0),
                             (6.0, -8.0, 6.2, 5.6),
                             (11.0, -4.0, 5.6, 5.6),
                             (14.0, 4.0, 5.0, 6.0),
                             (14.0, 13.0, 4.2, 5.6),
                             (12.0, 21.0, 3.4, 4.4)]:
        hair_lobes.append((pony_base[0] + pdir * ox,
                           pony_base[1] + oy + hs * (0.6 + 0.08 * ox), rx, ry))
    _lobes(xp, hair_lobes, A(HAIR), A(OUTLINE), 1.0)
    # strand shading inside the mass
    _lobes(xp, [
        (hcx - 3.0, hcy + 2.0, 3.0, 10.0),
        (hcx + 4.0, hcy + 6.0, 3.0, 9.0),
        (hcx - 5.0, hcy + 26.0, 2.6, 5.0),
        (pony_base[0] + pdir * 5.0, pony_base[1] - 4.0, 2.8, 2.6),
        (pony_base[0] + pdir * 11.0, pony_base[1] + 1.0, 2.4, 2.8),
    ], A(HAIR_DEEP))

    # ------------------------------------------------------------------- legs
    lx = 3.6 * bw
    stride = pose["stride"]
    sx_stride = stride * (0.40 + 0.60 * abs(sx))
    lift1 = max(0.0, stride) * 0.45
    lift2 = max(0.0, -stride) * 0.45
    leg_top = by - 24.0 + upper
    ankle = by + ANKLE_Y
    far = -1.0 if sx >= 0.0 else 1.0
    for side, lift in ((far, lift1), (-far, lift2)):
        hip_x = cx + side * lx
        foot_x = hip_x + (sx_stride if side > 0 else -sx_stride)
        # bare thigh
        xp.line([(hip_x, leg_top), (foot_x * 0.72 + hip_x * 0.28,
                                     by + SOCK_Y + 1.0 + upper * 0.6)],
                A(SKIN_SHADE if side != -far else SKIN), 4.0 * bw)
        # navy thigh-high
        sock_top = by + SOCK_Y + 1.0 + upper * 0.6
        xp.line([(foot_x * 0.72 + hip_x * 0.28, sock_top), (foot_x, ankle - lift)],
                A(NAVY if side == -far else NAVY_DEEP), 4.2 * bw)
        # small bow at the sock top
        bx = foot_x * 0.72 + hip_x * 0.28
        xp.poly([(bx - 2.0, sock_top - 0.4), (bx - 0.4, sock_top - 2.0),
                 (bx - 0.4, sock_top + 1.2)], A(NAVY))
        xp.poly([(bx + 2.0, sock_top - 0.4), (bx + 0.4, sock_top - 2.0),
                 (bx + 0.4, sock_top + 1.2)], A(NAVY))
        # shoe
        xp.ell(foot_x, ankle - lift + 0.4, 3.8, 2.2, A(BOOT), A(OUTLINE), 0.8)
        xp.ell(foot_x, ankle - lift - 0.2, 2.2, 1.1, A(NAVY_DEEP))
    if kneel > 0.2:
        xp.ell(cx, by - 4.0, 10.0, 3.6, A(DRESS_SHADE), A(OUTLINE), 0.8)

    # ------------------------------------------------------------------ torso
    sh_y = by + SH_Y + upper
    hip_y = by + HIP_Y + upper * 0.4
    sh_w = 8.8 * bw
    lean_x = lean
    # white bodice
    xp.poly([
        (cx - sh_w + lean_x, sh_y), (cx + sh_w + lean_x, sh_y),
        (cx + 7.6 * bw, hip_y), (cx - 7.6 * bw, hip_y),
    ], A(DRESS), A(OUTLINE), 1.0)
    xp.poly([
        (cx - 3.0 + lean_x, sh_y + 1.0), (cx + 3.6 + lean_x, sh_y + 1.0),
        (cx + 2.8, hip_y - 1.0), (cx - 2.8, hip_y - 1.0),
    ], A(DRESS_LIGHT))
    # navy chest bow
    bow_x = cx + sx * 1.6 + lean_x
    bow_y = sh_y + 3.4
    xp.poly([(bow_x - 4.6, bow_y), (bow_x - 1.2, bow_y - 2.6),
             (bow_x - 1.2, bow_y + 2.6)], A(NAVY), A(OUTLINE), 0.7)
    xp.poly([(bow_x + 4.6, bow_y), (bow_x + 1.2, bow_y - 2.6),
             (bow_x + 1.2, bow_y + 2.6)], A(NAVY), A(OUTLINE), 0.7)
    xp.ell(bow_x, bow_y, 1.5, 1.7, A(NAVY_DEEP), A(OUTLINE), 0.6)

    # ------------------------------------------------------------------- skirt
    hem_y = by + HEM_Y
    hem_w = 13.8 * bw
    hem_cx = cx + sx * 2.4
    xp.poly([(cx - 7.2 * bw, hip_y - 2.0), (cx + 7.2 * bw, hip_y - 2.0),
             (hem_cx + hem_w, hem_y), (hem_cx - hem_w, hem_y)],
            A(DRESS), A(OUTLINE), 1.0)
    # shadowed underside
    xp.poly([(cx + (5.0 if sx >= 0 else -5.0) * bw, hip_y - 2.0),
             (hem_cx + (hem_w * 0.92 if sx >= 0 else -hem_w * 0.92), hem_y - 0.6),
             (hem_cx + (hem_w * 0.45 if sx >= 0 else -hem_w * 0.45), hem_y - 0.6),
             (cx + (1.8 if sx >= 0 else -1.8), hip_y - 2.0)], A(DRESS_SHADE))
    # lace ruffle tier above the hem
    _ruffle(xp, hem_cx, hem_y - 4.4, hem_w * 0.94, 2.4, A(TRIM), A(OUTLINE), 0.6)
    # torn, frayed bottom edge
    _torn_hem(xp, hem_cx, hem_y - 2.0, hem_w, 4.6, A(DRESS), A(OUTLINE), 0.8, 6)
    # waist ruffle
    _ruffle(xp, cx, hip_y - 3.0, 7.6 * bw, 2.0, A(DRESS_LIGHT), A(OUTLINE), 0.6)

    # ------------------------------------------------------------------- arms
    arm = pose["arm"]
    raise_y = pose["arm_raise"] * 21.0
    reach = pose["reach"]

    def arm_points(side):
        shoulder = (cx + side * 8.8 * bw + lean_x, sh_y + 2.2)
        if reach > 0.01 and side * sx >= 0:
            hand = (cx + sx * (15.0 + 3.0 * reach) + side * 1.5,
                    by - 36.0 - 2.0 * reach + upper * 0.5)
        else:
            hand = (cx + side * (11.6 * bw) + side * arm * 0.35,
                    by - 26.0 - raise_y + upper * 0.5)
        elbow = ((shoulder[0] + hand[0]) * 0.5 + side * 1.6,
                 (shoulder[1] + hand[1]) * 0.5 + 1.4)
        return shoulder, elbow, hand

    far_side = -1.0 if sx >= 0.0 else 1.0
    sh, el, hd = arm_points(far_side)
    xp.line([sh, el], A(DRESS_SHADE), 4.4)
    xp.line([el, hd], A(SKIN_SHADE), 3.1)
    xp.ell(hd[0], hd[1], 1.9, 1.9, A(SKIN_SHADE))
    xp.ell(sh[0], sh[1] + 0.8, 4.6, 3.8, A(DRESS_SHADE), A(OUTLINE), 0.8)

    near_side = 1.0 if sx >= 0.0 else -1.0
    sh, el, hd = arm_points(near_side)
    xp.line([sh, el], A(DRESS), 4.6)
    xp.line([el, hd], A(SKIN), 3.2)
    xp.ell(hd[0], hd[1], 2.0, 2.0, A(SKIN), A(OUTLINE), 0.6)
    # puffed white sleeve with a lace cuff
    xp.ell(sh[0], sh[1] + 0.8, 4.8, 4.0, A(DRESS), A(OUTLINE), 0.8)
    xp.ell(sh[0], sh[1] + 2.4, 3.4, 1.5, A(TRIM))

    # ------------------------------------------------------------------- neck
    xp.line([(cx + lean_x * 0.6, by + CHIN_Y - 1.0), (cx + lean_x, by + NECK_Y)],
            A(SKIN_SHADE), 4.2)
    # navy choker with a cyan gem
    xp.poly([(cx - 3.4 + lean_x, by + NECK_Y - 0.6),
             (cx + 3.4 + lean_x, by + NECK_Y - 0.6),
             (cx + 3.0 + lean_x, by + NECK_Y + 2.4),
             (cx - 3.0 + lean_x, by + NECK_Y + 2.4)], A(NAVY), A(OUTLINE), 0.6)
    xp.ell(cx + lean_x, by + NECK_Y + 3.2, 1.3, 1.7, A(ACCENT), A(OUTLINE), 0.5)
    xp.ell(cx + lean_x - 0.4, by + NECK_Y + 2.8, 0.45, 0.6, A(WHITE))

    # ------------------------------------------------------------------- head
    if not profile:
        xp.ell(hcx - HEAD_R * 0.97, hcy + 1.4, 2.1, 3.1, A(SKIN_SHADE))
        xp.ell(hcx + HEAD_R * 0.97, hcy + 1.4, 2.1, 3.1, A(SKIN_SHADE))
    xp.ell(hcx, hcy, HEAD_R, HEAD_R * 1.05, A(SKIN), A(OUTLINE), 1.0)
    xp.ell(hcx + sx * 4.2, hcy + 3.2, HEAD_R * 0.55, HEAD_R * 0.55, A(SKIN_SHADE))

    # ------------------------------------------------------------------- face
    if front:
        eye_y = hcy + 0.6
        if profile:
            eyes = [(sx * 5.6, 1.05)]
        else:
            eye_dx = 5.0 + sx * 1.4
            eyes = [(-eye_dx, 1.0), (eye_dx, 1.0)]
        for ex, es in eyes:
            ecx = hcx + ex
            if pose["blink"]:
                xp.line([(ecx - 3.0, eye_y), (ecx + 3.0, eye_y)], A(EYE_DARK), 1.5)
            else:
                xp.ell(ecx, eye_y, 3.3 * es, 4.6, A(EYE_DARK))
                xp.ell(ecx, eye_y + 0.5, 2.6 * es, 3.8, A(EYE_BLUE))
                xp.ell(ecx, eye_y + 1.0, 1.9 * es, 3.0, A(IRIS))
                xp.ell(ecx, eye_y + 1.6, 1.1 * es, 1.8, A(IRIS_LIGHT))
                xp.ell(ecx - 1.0 * es, eye_y - 1.6, 1.0 * es, 1.35, A(WHITE))
                xp.ell(ecx + 1.1 * es, eye_y + 2.4, 0.7 * es, 0.85, A(WHITE))
            # upper lash
            xp.line([(ecx - 3.4 * es, eye_y - 3.6), (ecx + 3.4 * es, eye_y - 3.0)],
                    A(EYE_DARK), 1.2)
            xp.line([(ecx - 2.4 * es, eye_y - 6.4), (ecx + 2.4 * es, eye_y - 6.9)],
                    A(HAIR_DEEP), 0.9)
        # small mouth + nose
        xp.ell(hcx + sx * 1.8, hcy + 5.0, 0.7, 0.7, A(SKIN_LINE))
        if not profile:
            xp.line([(hcx - 1.6, hcy + 7.8), (hcx + 1.6, hcy + 7.8)],
                    A(SKIN_LINE), 0.85)
        if not pose["blink"]:
            xp.layer("over")
            xp.ell(hcx - 6.6, hcy + 5.4, 2.4, 1.2, BLUSH)
            xp.ell(hcx + 6.6, hcy + 5.4, 2.4, 1.2, BLUSH)
            xp.layer("main")

    # ---------------------------------------------------------------- front hair
    bangs = [
        (hcx - 13.4, hcy - 1.0), (hcx - 14.2, hcy - 8.0), (hcx - 10.0, hcy - 13.2),
        (hcx - 3.4, hcy - 11.2), (hcx - 5.6, hcy - 4.6), (hcx + 0.4, hcy - 10.2),
        (hcx + 3.0, hcy - 13.6), (hcx + 9.0, hcy - 12.2), (hcx + 13.2, hcy - 7.6),
        (hcx + 12.0, hcy - 0.6), (hcx + 8.2, hcy - 4.0), (hcx + 3.6, hcy - 2.4),
        (hcx - 0.8, hcy - 4.2), (hcx - 5.2, hcy - 2.6), (hcx - 9.4, hcy - 4.4),
    ]
    xp.poly(bangs, A(HAIR), A(OUTLINE), 0.9)
    xp.poly([(hcx - 8.4, hcy - 10.2), (hcx - 2.6, hcy - 11.0),
             (hcx + 1.2, hcy - 8.0), (hcx - 4.8, hcy - 7.4)], A(HAIR_LIGHT))
    # side locks framing the face
    for side in (-1.0, 1.0):
        lock = [
            (hcx + side * 12.4, hcy - 7.0),
            (hcx + side * 14.6, hcy + 2.0),
            (hcx + side * 13.6, hcy + 15.0),
            (hcx + side * 10.4, hcy + 21.0),
            (hcx + side * 8.4, hcy + 12.0),
            (hcx + side * 9.2, hcy + 0.5),
        ]
        xp.poly(lock, A(HAIR), A(OUTLINE), 0.8)
        xp.poly([(hcx + side * 12.0, hcy - 3.6),
                 (hcx + side * 13.0, hcy + 8.0),
                 (hcx + side * 11.2, hcy + 13.0),
                 (hcx + side * 10.6, hcy + 2.4)], A(HAIR_SHADE))

    # --------------------------------------------------- skull-bow hair ornament
    _skull_bow(xp, pony_base[0] - pdir * 2.5, pony_base[1] - 2.0, 1.25, A)

    # ------------------------------------------------------------- spell effects
    xp.layer("over")
    if pose["orb"] > 0.01:
        orb = pose["orb"]
        ox = cx + sx * 14.0 + 3.0
        oy = by - 40.0 + upper * 0.5
        xp.ell(ox, oy, 4.0 + 4.0 * orb, 4.0 + 4.0 * orb,
               (ACCENT[0], ACCENT[1], ACCENT[2], 40))
        xp.ell(ox, oy, 2.2 + 2.8 * orb, 2.2 + 2.8 * orb,
               (ACCENT[0], ACCENT[1], ACCENT[2], 190))
        xp.ell(ox, oy, 1.0 + 1.2 * orb, 1.0 + 1.2 * orb,
               (WHITE[0], WHITE[1], WHITE[2], 240))
        for ring in range(2):
            rr = (6.0 + 5.0 * ring) * (0.6 + 0.4 * orb)
            xp.arc(ox, oy, rr, rr, ring * 60 + orb * 200,
                   ring * 60 + 250 + orb * 200,
                   (ACCENT[0], ACCENT[1], ACCENT[2], 120), 1.0)

    if pose["slash"] > 0.01:
        sl = pose["slash"]
        ox = cx + sx * 16.0 + 2.0
        oy = by - 38.0
        for j in range(2):
            rr = 13.0 + j * 3.0
            xp.arc(ox, oy, rr, rr * 0.72, -70 + 20 * j, 60 + 10 * j,
                   (ACCENT[0], ACCENT[1], ACCENT[2], int((200 - 60 * j) * sl)),
                   2.4 - j * 0.7)
            xp.arc(ox, oy, rr - 2.0, rr * 0.66, -60 + 20 * j, 55 + 10 * j,
                   (WHITE[0], WHITE[1], WHITE[2], int(170 * sl)), 0.9)
        # a little soul blob flying out of the blast
        gx = ox + sx * 8.0
        _mini_ghost(xp, gx, oy - 1.0, 1.1, A)

    # ------------------------------------------------------------- ghost wisps
    wisp_ph = pose["wisp"]
    for idx in range(2):
        ang = wisp_ph * math.tau + idx * 2.4
        wx = cx + (1.0 if idx == 0 else -1.0) * (13.0 + idx * 2.0) + math.cos(ang) * 2.0
        wy = by - 44.0 - idx * 13.0 + math.sin(ang * 1.3) * 3.0
        _mini_ghost(xp, wx, wy, 1.0 - idx * 0.18, A)

    # ---------------------------------------------------------------- sparkles
    if pose["sparkle"] > 0.05:
        sp = pose["sparkle"]
        for idx in range(4):
            ang = idx * 1.7 + wisp_ph * 1.2
            rad = 16.0 + (idx % 2) * 7.0
            sx2 = cx + math.cos(ang) * rad
            sy2 = by - 44.0 + math.sin(ang) * rad * 0.7
            xp.star(sx2, sy2, (2.2 + (idx % 2)) * sp,
                    (ACCENT[0], ACCENT[1], ACCENT[2], int(210 * sp)))
    xp.layer("main")

    # ------------------------------------------------------------------- flash
    if pose["flash"] > 0.01:
        xp.layer("over")
        xp.ell(cx, by - 40.0, 18.0, 30.0,
               (255, 120, 140, int(110 * pose["flash"])))
        xp.layer("main")

    # ------------------------------------------------------ global pose fade
    if alpha < 0.999:
        xp.fade(alpha)


# ------------------------------------------------------------ world frames

def render_world_frame(direction: int, state: str, i: int, n: int) -> Image.Image:
    pen = Pen(FRAME_W, FRAME_H, S)
    pose = pose_for(state, i, n)
    if direction <= 4:
        draw_character(XPen(pen, 48.0, 119.0, WORLD_SCALE), direction, pose)
        return pen.finish()
    # mirror the right-facing diagonal for the left-facing diagonal
    pen2 = Pen(FRAME_W, FRAME_H, S)
    draw_character(XPen(pen2, 48.0, 119.0, WORLD_SCALE), 8 - direction, pose)
    return pen2.finish().transpose(Image.FLIP_LEFT_RIGHT)


def build_state_atlas(state: str) -> Image.Image:
    n = FRAMES[state]
    atlas = Image.new("RGBA", (n * FRAME_W, ROWS * FRAME_H), (0, 0, 0, 0))
    for d in range(ROWS):
        for i in range(n):
            frame = render_world_frame(d, state, i, n)
            atlas.paste(frame, (i * FRAME_W, d * FRAME_H), frame)
    return atlas


# ------------------------------------------------------------ large artwork

def draw_portrait() -> Image.Image:
    """256x384 RGBA8 bust portrait (drawn at 4x).

    Matches the concept sheet's bust: white side-ponytail with the black
    skull bow, big cyan anime eyes, white frilled dress with the navy chest
    bow and the gem choker.
    """
    pen = Pen(256, 384, S)
    cx = 122.0
    hcx, hcy = cx, 168.0

    # spirit aura (behind everything)
    pen.layer("under")
    for r, a in ((148, 20), (118, 25), (90, 30)):
        pen.ell(cx, 196, r, r, (ACCENT[0], ACCENT[1], ACCENT[2], a))
    pen.layer("main")

    # ------------------------------------------------------- back hair + ponytail
    back = [
        (hcx - 46, hcy + 22), (hcx - 62, hcy - 14), (hcx - 52, hcy - 48),
        (hcx - 20, hcy - 66), (hcx + 16, hcy - 66), (hcx + 48, hcy - 48),
        (hcx + 60, hcy - 10), (hcx + 54, hcy + 30), (hcx + 66, hcy + 96),
        (hcx + 74, hcy + 168), (hcx + 48, hcy + 216), (hcx + 26, hcy + 180),
        (hcx + 8, hcy + 216), (hcx - 10, hcy + 176), (hcx - 32, hcy + 214),
        (hcx - 56, hcy + 168), (hcx - 64, hcy + 84), (hcx - 58, hcy + 40),
    ]
    pen.poly(back, HAIR_SHADE, OUTLINE, 2.0)
    for off, col, w in ((-26, HAIR_DEEP, 2.2), (-8, HAIR_SHADE, 2.6),
                        (14, HAIR_DEEP, 2.2), (34, HAIR_SHADE, 2.6)):
        pen.line([(hcx + off * 0.6, hcy - 40), (hcx + off, hcy + 30),
                  (hcx + off * 1.2, hcy + 120), (hcx + off * 1.3, hcy + 190)],
                 col, w)

    # the big swept ponytail (screen-right, as in the sheet)
    _lobes(pen, [
        (hcx + 50, hcy - 56, 20, 18),
        (hcx + 62, hcy - 58, 20, 18),
        (hcx + 74, hcy - 54, 19, 17),
        (hcx + 86, hcy - 44, 17, 16),
        (hcx + 96, hcy - 30, 15, 15),
        (hcx + 104, hcy - 12, 13, 14),
        (hcx + 110, hcy + 8, 11, 12),
        (hcx + 110, hcy + 28, 9, 10),
        (hcx + 104, hcy + 44, 7, 8),
    ], HAIR, OUTLINE, 2.0)
    _lobes(pen, [
        (hcx + 62, hcy - 50, 8, 7),
        (hcx + 80, hcy - 42, 7, 8),
        (hcx + 98, hcy - 24, 6, 8),
        (hcx + 108, hcy + 4, 5, 6),
    ], HAIR_LIGHT)

    # ------------------------------------------------------ shoulders / dress
    pen.poly([(cx - 118, 384), (cx - 102, 330), (cx - 66, 300),
              (cx - 26, 286), (cx + 26, 286), (cx + 66, 300),
              (cx + 102, 330), (cx + 118, 384)], DRESS, OUTLINE, 2.2)
    pen.poly([(cx - 58, 308), (cx - 22, 292), (cx + 22, 292),
              (cx + 58, 308), (cx + 44, 384), (cx - 44, 384)], DRESS_LIGHT)
    # white lace collar
    pen.poly([(cx - 34, 290), (cx, 314), (cx + 34, 290), (cx + 25, 284),
              (cx, 302), (cx - 25, 284)], TRIM, OUTLINE, 1.4)
    # navy chest bow
    pen.poly([(cx - 34, 330), (cx - 8, 314), (cx - 8, 346)], NAVY, OUTLINE, 1.4)
    pen.poly([(cx + 34, 330), (cx + 8, 314), (cx + 8, 346)], NAVY, OUTLINE, 1.4)
    pen.ell(cx, 330, 7, 8, NAVY_DEEP, OUTLINE, 1.2)

    # ----------------------------------------------------------------- neck
    pen.poly([(cx - 22, 248), (cx + 22, 248), (cx + 28, 292),
              (cx - 28, 292)], SKIN_SHADE)
    pen.poly([(cx - 15, 248), (cx + 15, 248), (cx + 19, 282),
              (cx - 19, 282)], SKIN)
    # navy choker + cyan gem
    pen.poly([(cx - 20, 260), (cx + 20, 260), (cx + 18, 270),
              (cx - 18, 270)], NAVY, OUTLINE, 1.4)
    pen.ell(cx, 280, 6.5, 8.5, ACCENT, OUTLINE, 1.2)
    pen.ell(cx - 2.2, 277, 2.2, 2.8, WHITE)

    # ------------------------------------------------------------------ head
    pen.ell(hcx, hcy, 66, 78, SKIN, OUTLINE, 2.0)
    pen.ell(hcx + 34, hcy + 20, 27, 41, SKIN_SHADE)
    pen.ell(hcx - 66, hcy + 12, 10, 16, SKIN_SHADE, OUTLINE, 1.2)
    pen.ell(hcx + 66, hcy + 12, 10, 16, SKIN_SHADE, OUTLINE, 1.2)

    # ------------------------------------------------------------------ eyes
    eye_y = hcy + 6
    for side in (-1, 1):
        ex = hcx + side * 28
        pen.ell(ex, eye_y, 19, 26, EYE_DARK)
        pen.ell(ex, eye_y + 3, 15, 21, EYE_BLUE)
        pen.ell(ex, eye_y + 6, 11, 17, IRIS)
        pen.ell(ex, eye_y + 9, 7, 11, IRIS_LIGHT)
        pen.ell(ex, eye_y + 8, 4.4, 7.0, EYE_DARK)
        pen.ell(ex - 5, eye_y - 8, 5.0, 6.2, WHITE)
        pen.ell(ex + 5, eye_y + 12, 2.8, 2.8, WHITE)
        pen.line([(ex - 22, eye_y - 20), (ex + 22, eye_y - 25)], EYE_DARK, 3.4)
        pen.line([(ex + side * 18, eye_y - 22), (ex + side * 25, eye_y - 30)],
                 EYE_DARK, 2.6)
        pen.line([(ex - 16, eye_y - 40), (ex + 16, eye_y - 43)], HAIR_DEEP, 2.2)

    # nose + mouth
    pen.ell(hcx + 1, hcy + 42, 2.2, 1.8, SKIN_LINE)
    pen.line([(hcx - 9, hcy + 62), (hcx + 9, hcy + 62)], (176, 120, 140, 235), 2.4)
    pen.line([(hcx - 4, hcy + 66), (hcx + 4, hcy + 66)], (176, 120, 140, 150), 1.4)
    pen.layer("over")
    for side in (-1, 1):
        pen.ell(hcx + side * 46, hcy + 36, 14, 6, BLUSH)
    pen.layer("main")

    # ------------------------------------------------------------------ bangs
    bangs = [
        (hcx - 70, hcy + 6), (hcx - 72, hcy - 34), (hcx - 48, hcy - 66),
        (hcx - 10, hcy - 78), (hcx + 30, hcy - 72), (hcx + 64, hcy - 46),
        (hcx + 72, hcy - 6), (hcx + 58, hcy + 10),
        # four fringe tips of varying length
        (hcx + 44, hcy - 26), (hcx + 24, hcy - 4), (hcx + 2, hcy - 34),
        (hcx - 22, hcy - 10), (hcx - 44, hcy - 30), (hcx - 58, hcy + 2),
    ]
    pen.poly(bangs, HAIR, OUTLINE, 2.0)
    pen.poly([(hcx - 44, hcy - 54), (hcx - 14, hcy - 68), (hcx + 6, hcy - 50),
              (hcx - 20, hcy - 40)], HAIR_LIGHT)
    pen.poly([(hcx + 18, hcy - 62), (hcx + 44, hcy - 56), (hcx + 54, hcy - 38),
              (hcx + 30, hcy - 44)], HAIR_LIGHT)
    # side locks framing the face
    for side in (-1, 1):
        pen.poly([(hcx + side * 62, hcy - 34), (hcx + side * 78, hcy + 6),
                  (hcx + side * 82, hcy + 66), (hcx + side * 74, hcy + 108),
                  (hcx + side * 64, hcy + 128), (hcx + side * 57, hcy + 100),
                  (hcx + side * 55, hcy + 60), (hcx + side * 51, hcy + 10)],
                 HAIR, OUTLINE, 2.0)
        pen.line([(hcx + side * 68, hcy + 4), (hcx + side * 74, hcy + 56),
                  (hcx + side * 66, hcy + 106)], HAIR_SHADE, 3.2)

    # ------------------------------------------------------- black skull bow
    bx, byy = hcx + 44, hcy - 56
    pen.poly([(bx - 30, byy), (bx - 7, byy - 16), (bx - 7, byy + 16)], NAVY, OUTLINE, 2.0)
    pen.poly([(bx + 30, byy), (bx + 7, byy - 16), (bx + 7, byy + 16)], NAVY, OUTLINE, 2.0)
    pen.ell(bx, byy, 13, 14, WHITE, OUTLINE, 1.6)
    pen.ell(bx - 5, byy - 2, 4.2, 4.6, NAVY_DEEP)
    pen.ell(bx + 5, byy - 2, 4.2, 4.6, NAVY_DEEP)
    pen.line([(bx - 3.4, byy + 7), (bx + 3.4, byy + 7)], NAVY_DEEP, 2.4)
    pen.line([(bx - 4, byy + 11), (bx + 4, byy + 11)], NAVY_DEEP, 1.8)

    # ------------------------------------------------------- soul wisps + motes
    pen.layer("over")
    for gx, gy, gs in ((30, 116, 13), (228, 92, 11), (206, 268, 9), (44, 300, 8)):
        pen.ell(gx, gy, gs, gs * 1.25, (ACCENT[0], ACCENT[1], ACCENT[2], 225))
        pen.poly([(gx - gs * 0.9, gy + gs * 0.3), (gx, gy + gs * 2.0),
                  (gx + gs * 0.9, gy + gs * 0.3)], (ACCENT[0], ACCENT[1], ACCENT[2], 225))
        pen.ell(gx - gs * 0.35, gy - gs * 0.1, gs * 0.2, gs * 0.26, NAVY_DEEP)
        pen.ell(gx + gs * 0.35, gy - gs * 0.1, gs * 0.2, gs * 0.26, NAVY_DEEP)
    for mx, my, mr in ((28, 60, 2.4), (232, 176, 2.2), (18, 240, 2.0)):
        pen.star(mx, my, mr, (ACCENT[0], ACCENT[1], ACCENT[2], 190))
    pen.layer("main")

    img = pen.finish()
    # force transparent corners (validation requires them)
    px_data = img.load()
    for x, y in ((0, 0), (255, 0), (0, 383), (255, 383)):
        px_data[x, y] = (0, 0, 0, 0)
    return img


def draw_combat_sprite() -> Image.Image:
    """128x192 dynamic casting pose (bottom-centre anchor)."""
    pen = Pen(128, 192, S)
    pose = pose_for("cast", 5, 7)
    pose["bob"] = 0.0
    xp = XPen(pen, 64.0, 186.0, 1.85)
    xp.ow = 0.75
    draw_character(xp, 1, pose)
    img = pen.finish()
    return img


def draw_full_body() -> Image.Image:
    """1024x2048 standing key illustration (bottom-centre anchor)."""
    pen = Pen(1024, 2048, 1)
    pose = pose_for("idle", 1, 5)
    pose["sparkle"] = 0.8
    pose["wisp"] = 0.35
    xp = XPen(pen, 460.0, 1960.0, 21.0)
    xp.ow = 0.44
    xp.aura = 0.85
    draw_character(xp, 1, pose)
    return pen.finish()


# ---------------------------------------------------------------- previews

def build_preview(atlas_by_state: dict) -> None:
    os.makedirs(PREVIEW, exist_ok=True)
    # contact sheet: one row per state, down-direction frames at 2x
    cols = max(FRAMES[s] for s in STATES)
    scale = 2
    sheet = Image.new("RGBA", (cols * FRAME_W * scale, len(STATES) * FRAME_H * scale),
                      (18, 24, 40, 255))
    for row, state in enumerate(STATES):
        atlas = atlas_by_state[state]
        n = FRAMES[state]
        for i in range(n):
            frame = atlas.crop((i * FRAME_W, 0, (i + 1) * FRAME_W, FRAME_H))
            frame = frame.resize((FRAME_W * scale, FRAME_H * scale), Image.LANCZOS)
            sheet.alpha_composite(frame, (i * FRAME_W * scale, row * FRAME_H * scale))
    sheet.save(os.path.join(PREVIEW, "preview_sheet.png"))

    # animated GIF per state (down direction)
    for state in STATES:
        atlas = atlas_by_state[state]
        n = FRAMES[state]
        frames = []
        for i in range(n):
            frame = atlas.crop((i * FRAME_W, 0, (i + 1) * FRAME_W, FRAME_H))
            frame = frame.resize((FRAME_W * 2, FRAME_H * 2), Image.LANCZOS)
            bg = Image.new("RGBA", frame.size, (18, 24, 40, 255))
            bg.alpha_composite(frame)
            frames.append(bg.convert("P", palette=Image.ADAPTIVE, colors=128))
        delay = int(round(1000.0 / FPS[state]))
        frames[0].save(os.path.join(PREVIEW, state + ".gif"), save_all=True,
                       append_images=frames[1:], duration=delay,
                       loop=0 if LOOP[state] else 1, disposal=2)


# --------------------------------------------------------------------- main

def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(PREVIEW, exist_ok=True)

    atlases = {}
    for state in STATES:
        atlas = build_state_atlas(state)
        atlas.save(os.path.join(OUT, state + "_sheet.png"))
        atlases[state] = atlas
        print("wrote %s_sheet.png  %dx%d" % (state, atlas.width, atlas.height))

    portrait = draw_portrait()
    portrait.save(os.path.join(OUT, "portrait.png"))
    print("wrote portrait.png  %dx%d" % portrait.size)

    combat = draw_combat_sprite()
    combat.save(os.path.join(OUT, "combat_sprite.png"))
    print("wrote combat_sprite.png  %dx%d" % combat.size)

    full = draw_full_body()
    full.save(os.path.join(OUT, "full_body_illustration.png"))
    print("wrote full_body_illustration.png  %dx%d" % full.size)

    build_preview(atlases)
    print("wrote previews to %s" % PREVIEW)


if __name__ == "__main__":
    main()
