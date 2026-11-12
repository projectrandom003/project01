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
# Values follow resources/data/main_characters.json palette, expanded into a
# small cel-shading ramp.
OUTLINE = (25, 32, 54, 255)
HAIR = (242, 245, 250, 255)
HAIR_LIGHT = (255, 255, 255, 255)
HAIR_SHADE = (201, 211, 230, 255)
HAIR_DEEP = (158, 174, 203, 255)
SKIN = (232, 238, 247, 255)
SKIN_SHADE = (205, 216, 234, 255)
SKIN_LINE = (150, 163, 190, 255)
EYE_DARK = (26, 38, 66, 255)
EYE_BLUE = (78, 150, 214, 255)
IRIS = (127, 212, 255, 255)
IRIS_LIGHT = (206, 244, 255, 255)
DRESS = (111, 143, 191, 255)
DRESS_LIGHT = (158, 187, 220, 255)
DRESS_DARK = (74, 100, 145, 255)
TRIM = (185, 212, 232, 255)
ACCENT = (127, 212, 255, 255)
ACCENT_DEEP = (62, 150, 205, 255)
NAVY = (42, 55, 84, 255)
BOOT = (36, 48, 74, 255)
WHITE = (252, 253, 255, 255)
BLUSH = (232, 182, 196, 120)
SHADOW = (12, 20, 38, 64)


def rgba(c, a):
    return (c[0], c[1], c[2], a)


# ------------------------------------------------------------------- drawing

class Pen:
    def __init__(self, w: int, h: int, ss: int = S):
        self.w, self.h, self.ss = w, h, ss
        self.img = Image.new("RGBA", (w * ss, h * ss), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.img, "RGBA")

    def _p(self, pts):
        s = self.ss
        return [(x * s, y * s) for x, y in pts]

    def poly(self, pts, fill, outline=None, ow=1.0):
        p = self._p(pts)
        if len(p) < 3:
            return
        self.d.polygon(p, fill=fill)
        if outline is not None and ow > 0:
            self.d.line(p + [p[0]], fill=outline,
                        width=max(1, round(ow * self.ss)), joint="curve")

    def ell(self, cx, cy, rx, ry, fill, outline=None, ow=1.0):
        s = self.ss
        box = [(cx - rx) * s, (cy - ry) * s, (cx + rx) * s, (cy + ry) * s]
        self.d.ellipse(box, fill=fill)
        if outline is not None and ow > 0:
            self.d.ellipse(box, outline=outline,
                           width=max(1, round(ow * self.ss)))

    def line(self, pts, fill, w, cap=True):
        s = self.ss
        p = [(x * s, y * s) for x, y in pts]
        self.d.line(p, fill=fill, width=max(1, round(w * s)), joint="curve")
        if cap:
            r = max(1.0, w * s * 0.5)
            for x, y in (p[0], p[-1]):
                self.d.ellipse([x - r, y - r, x + r, y + r], fill=fill)

    def arc(self, cx, cy, rx, ry, a0, a1, fill, w):
        s = self.ss
        self.d.arc([(cx - rx) * s, (cy - ry) * s,
                    (cx + rx) * s, (cy + ry) * s],
                   a0, a1, fill=fill, width=max(1, round(w * s)))

    def star(self, cx, cy, r, fill):
        pts = [(cx, cy - r), (cx + r * 0.28, cy - r * 0.28),
               (cx + r, cy), (cx + r * 0.28, cy + r * 0.28),
               (cx, cy + r), (cx - r * 0.28, cy + r * 0.28),
               (cx - r, cy), (cx - r * 0.28, cy - r * 0.28)]
        self.poly(pts, fill)

    def finish(self) -> Image.Image:
        return self.img.resize((self.w, self.h), Image.LANCZOS)


class XPen:
    """Translate/scale a local character space into a Pen's pixel space."""

    def __init__(self, pen: Pen, ox: float, oy: float, k: float):
        self.pen, self.ox, self.oy, self.k = pen, ox, oy, k

    def _p(self, pts):
        return [(self.ox + x * self.k, self.oy + y * self.k) for x, y in pts]

    def poly(self, pts, fill, outline=None, ow=1.0):
        self.pen.poly(self._p(pts), fill, outline, ow * self.k)

    def ell(self, cx, cy, rx, ry, fill, outline=None, ow=1.0):
        self.pen.ell(self.ox + cx * self.k, self.oy + cy * self.k,
                     rx * self.k, ry * self.k, fill, outline, ow * self.k)

    def line(self, pts, fill, w, cap=True):
        self.pen.line(self._p(pts), fill, w * self.k, cap)

    def arc(self, cx, cy, rx, ry, a0, a1, fill, w):
        self.pen.arc(self.ox + cx * self.k, self.oy + cy * self.k,
                     rx * self.k, ry * self.k, a0, a1, fill, w * self.k)

    def star(self, cx, cy, r, fill):
        self.pen.star(self.ox + cx * self.k, self.oy + cy * self.k,
                      r * self.k, fill)


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
        if i == 0:
            p["arm"] = -5.0
            p["lean"] = -1.5
            p["head_tilt"] = -2.0
            p["hair"] = -1.5
        elif i in (1, 2, 3, 4):
            p["arm"] = 7.0
            p["lean"] = 2.0
            p["slash"] = 1.0 if i in (2, 3, 4) else 0.55
            p["hair"] = 2.0
            p["bob"] = -0.8
        else:
            p["arm"] = 1.0
            p["hair"] = 0.5
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


def draw_character(xp: XPen, direction: int, pose: dict) -> None:
    """Draw one upright chibi Lilith frame in local space (0,0 = feet centre)."""
    sx, dz = _DIRS[direction]
    front = dz > -0.55
    profile = abs(sx) > 0.92
    bw = 1.0 - 0.20 * abs(sx)
    alpha = pose["alpha"]
    by = -pose["bob"]
    cx = pose["sway"]
    kneel = pose["kneel"]
    upper = kneel * 6.0
    lean = pose["lean"] * 0.45

    def A(c):
        return rgba(c, int(c[3] * alpha))

    # ---------------------------------------------------------- ground shadow
    for r, a in ((13.0, 24), (9.0, 32), (5.5, 44)):
        xp.ell(cx, 0.4, r, r * 0.20, (10, 18, 36, int(a * alpha)))

    # ------------------------------------------------------------- spirit aura
    xp.ell(cx + sx * 2.0, by - 40.0, 24.0, 31.0,
           (ACCENT[0], ACCENT[1], ACCENT[2], int(15 * alpha)))
    xp.ell(cx + sx * 2.0, by - 42.0, 17.0, 23.0,
           (ACCENT[0], ACCENT[1], ACCENT[2], int(11 * alpha)))

    # ---------------------------------------------------------- back hair mass
    hx = cx + sx * 2.0
    hs = pose["hair"]
    hair_pts = [
        (hx - 10.5, by - 58), (hx - 12.5, by - 66), (hx - 8.0, by - 72),
        (hx - 1.0, by - 74), (hx + 7.5, by - 72), (hx + 12.0, by - 65),
        (hx + 11.0, by - 56), (hx + 14.0 + hs, by - 40),
        (hx + 11.5 + hs, by - 28), (hx + 6.0 + hs, by - 33),
        (hx + 3.0 + hs, by - 26), (hx + 0.5, by - 34),
        (hx - 2.5 + hs, by - 26), (hx - 6.0 + hs, by - 33),
        (hx - 12.0 + hs, by - 28), (hx - 14.5 + hs, by - 40),
    ]
    xp.poly(hair_pts, A(HAIR_SHADE), A(OUTLINE), 1.0)
    inner = [
        (hx - 6.0, by - 60), (hx - 3.0, by - 48), (hx - 5.5 + hs, by - 31),
        (hx - 1.0, by - 39), (hx + 2.0, by - 30), (hx + 4.5, by - 44),
        (hx + 8.0, by - 58),
    ]
    xp.poly(inner, A(HAIR_DEEP))

    # ------------------------------------------------------------------- legs
    lx = 3.4 * bw
    stride = pose["stride"]
    sx_stride = stride * (0.40 + 0.60 * abs(sx))
    lift1 = max(0.0, stride) * 0.45
    lift2 = max(0.0, -stride) * 0.45
    leg_top = by - 21.0 + upper
    ankle = by - 4.0
    far = -1.0 if sx >= 0.0 else 1.0
    for side, lift in ((far, lift1), (-far, lift2)):
        hip_x = cx + side * lx
        foot_x = hip_x + (sx_stride if side > 0 else -sx_stride)
        xp.line([(hip_x, leg_top), (foot_x, ankle - lift)],
                A(SKIN_SHADE if not front else SKIN), 4.2 * bw)
        xp.line([(foot_x * 0.55 + hip_x * 0.45, (leg_top + ankle) * 0.5),
                 (foot_x, ankle - lift)], A(WHITE), 3.4 * bw)
        xp.ell(foot_x, ankle - lift + 0.4, 3.6, 2.1, A(BOOT), A(OUTLINE), 0.8)
    if kneel > 0.2:
        xp.ell(cx, by - 4.0, 10.0, 3.6, A(DRESS_DARK), A(OUTLINE), 0.8)

    # ------------------------------------------------------------------ torso
    sh_y = by - 47.0 + upper
    hip_y = by - 26.0 + upper * 0.4
    sh_w = 8.4 * bw
    lean_x = lean
    xp.poly([
        (cx - sh_w + lean_x, sh_y), (cx + sh_w + lean_x, sh_y),
        (cx + 7.4 * bw, hip_y), (cx - 7.4 * bw, hip_y),
    ], A(DRESS), A(OUTLINE), 1.0)
    xp.poly([
        (cx - 3.2 + lean_x, sh_y + 1.0), (cx + 3.4 + lean_x, sh_y + 1.0),
        (cx + 2.6, hip_y - 1.0), (cx - 2.6, hip_y - 1.0),
    ], A(DRESS_LIGHT))
    xp.poly([
        (cx - 6.0, hip_y - 3.4), (cx + 6.0, hip_y - 3.4),
        (cx + 5.4, hip_y - 1.0), (cx - 5.4, hip_y - 1.0),
    ], A(TRIM))
    bow_x = cx + sx * 2.0
    xp.poly([(bow_x - 4.0, hip_y - 4.0), (bow_x - 1.0, hip_y - 6.2),
             (bow_x - 1.0, hip_y - 1.6)], A(ACCENT))
    xp.poly([(bow_x + 4.0, hip_y - 4.0), (bow_x + 1.0, hip_y - 6.2),
             (bow_x + 1.0, hip_y - 1.6)], A(ACCENT))
    xp.ell(bow_x, hip_y - 4.0, 1.3, 1.6, A(ACCENT_DEEP))

    # ------------------------------------------------------------------- skirt
    hem_y = by - 17.0
    hem_w = 13.2 * bw
    hem_cx = cx + sx * 2.6
    scallop = 2.2
    hem = [
        (hem_cx - hem_w, hem_y),
        (hem_cx - hem_w * 0.62, hem_y + scallop),
        (hem_cx - hem_w * 0.22, hem_y - 0.4),
        (hem_cx + hem_w * 0.22, hem_y + scallop),
        (hem_cx + hem_w * 0.62, hem_y - 0.4),
        (hem_cx + hem_w, hem_y),
    ]
    xp.poly([(cx - 7.0 * bw, hip_y - 2.0), (cx + 7.0 * bw, hip_y - 2.0)] + hem,
            A(DRESS), A(OUTLINE), 1.0)
    xp.poly([(hem_cx - hem_w * 0.92, hem_y - 1.0),
             (hem_cx + hem_w * 0.92, hem_y - 1.0),
             (hem_cx + hem_w * 0.72, hem_y - 4.0),
             (hem_cx - hem_w * 0.72, hem_y - 4.0)], A(TRIM))
    xp.poly([(cx + (6.0 if sx >= 0 else -6.0) * bw, hip_y - 2.0),
             (hem_cx + (hem_w * 0.92 if sx >= 0 else -hem_w * 0.92), hem_y - 0.6),
             (hem_cx + (hem_w * 0.45 if sx >= 0 else -hem_w * 0.45), hem_y - 0.6),
             (cx + (2.0 if sx >= 0 else -2.0), hip_y - 2.0)], A(DRESS_DARK))

    # ------------------------------------------------------------------- arms
    arm = pose["arm"]
    raise_y = pose["arm_raise"] * 21.0
    reach = pose["reach"]

    def arm_points(side):
        shoulder = (cx + side * 8.6 * bw + lean_x, sh_y + 2.0)
        if reach > 0.01 and side * sx >= 0:
            hand = (cx + sx * (15.0 + 3.0 * reach) + side * 1.5,
                    by - 36.0 - 2.0 * reach + upper * 0.5)
        else:
            hand = (cx + side * (11.4 * bw) + side * arm * 0.35,
                    by - 27.0 - raise_y + upper * 0.5)
        elbow = ((shoulder[0] + hand[0]) * 0.5 + side * 1.6,
                 (shoulder[1] + hand[1]) * 0.5 + 1.2)
        return shoulder, elbow, hand

    far_side = -1.0 if sx >= 0.0 else 1.0
    sh, el, hd = arm_points(far_side)
    xp.line([sh, el], A(DRESS_DARK), 4.4)
    xp.line([el, hd], A(SKIN_SHADE), 3.1)
    xp.ell(hd[0], hd[1], 1.9, 1.9, A(SKIN_SHADE))

    near_side = 1.0 if sx >= 0.0 else -1.0
    sh, el, hd = arm_points(near_side)
    xp.line([sh, el], A(DRESS), 4.6)
    xp.line([el, hd], A(SKIN), 3.2)
    xp.ell(hd[0], hd[1], 2.0, 2.0, A(SKIN), A(OUTLINE), 0.6)
    xp.ell(sh[0], sh[1] + 0.6, 4.4, 3.6, A(DRESS_LIGHT), A(OUTLINE), 0.8)

    # ------------------------------------------------------------------- neck
    xp.line([(cx + lean_x * 0.6, sh_y - 1.0), (cx + lean_x, by - 53.0 + upper)],
            A(SKIN_SHADE), 4.0)
    xp.poly([(cx - 3.0 + lean_x, by - 51.0 + upper),
             (cx + 3.0 + lean_x, by - 51.0 + upper),
             (cx + 4.0 + lean_x, by - 46.0 + upper),
             (cx - 4.0 + lean_x, by - 46.0 + upper)], A(TRIM))

    # ------------------------------------------------------------------- head
    head_cy = by - 63.0 + upper + pose["head_tilt"] * 0.12
    head_cx = cx + sx * 3.0 + pose["head_tilt"] * 0.30
    r = 10.4
    if not profile:
        xp.ell(head_cx - r * 0.98, head_cy + 1.5, 2.0, 3.0, A(SKIN_SHADE))
        xp.ell(head_cx + r * 0.98, head_cy + 1.5, 2.0, 3.0, A(SKIN_SHADE))
    xp.ell(head_cx, head_cy, r, r * 1.04, A(SKIN), A(OUTLINE), 1.0)
    xp.ell(head_cx + sx * 4.0, head_cy + 3.0, r * 0.55, r * 0.55, A(SKIN_SHADE))

    # ------------------------------------------------------------------- face
    if front:
        eye_y = head_cy - 0.4
        if profile:
            eyes = [(sx * 5.2, 1.0)]
        else:
            eye_dx = 4.2 + sx * 1.6
            eyes = [(-eye_dx, 1.0), (eye_dx, 1.0)]
        for ex, es in eyes:
            ecx = head_cx + ex
            if pose["blink"]:
                xp.line([(ecx - 2.2, eye_y), (ecx + 2.2, eye_y)],
                        A(EYE_DARK), 1.3)
            else:
                xp.ell(ecx, eye_y, 2.5 * es, 3.4, A(EYE_DARK))
                xp.ell(ecx, eye_y + 0.4, 1.9 * es, 2.7, A(EYE_BLUE))
                xp.ell(ecx, eye_y + 0.8, 1.35 * es, 2.0, A(IRIS))
                xp.ell(ecx - 0.7 * es, eye_y - 1.2, 0.75 * es, 1.0, A(WHITE))
                xp.ell(ecx + 0.8 * es, eye_y + 1.6, 0.55 * es, 0.65, A(IRIS_LIGHT))
            xp.line([(ecx - 2.6 * es, eye_y - 2.9), (ecx + 2.6 * es, eye_y - 2.4)],
                    A(EYE_DARK), 0.9)
            xp.line([(ecx - 2.1 * es, eye_y - 5.0), (ecx + 2.1 * es, eye_y - 5.4)],
                    A(HAIR_DEEP), 0.8)
        xp.ell(head_cx + sx * 1.6, head_cy + 3.6, 0.65, 0.65, A(SKIN_LINE))
        if not profile:
            xp.line([(head_cx - 1.4, head_cy + 6.4), (head_cx + 1.4, head_cy + 6.4)],
                    A(SKIN_LINE), 0.75)
        if not pose["blink"]:
            xp.ell(head_cx - 5.4, head_cy + 4.6, 2.0, 1.1, BLUSH)
            xp.ell(head_cx + 5.4, head_cy + 4.6, 2.0, 1.1, BLUSH)

    # ---------------------------------------------------------------- front hair
    bangs = [
        (head_cx - 10.6, head_cy - 1.0), (head_cx - 11.2, head_cy - 7.0),
        (head_cx - 7.5, head_cy - 11.4), (head_cx - 2.4, head_cy - 9.8),
        (head_cx - 4.2, head_cy - 4.0), (head_cx + 0.4, head_cy - 8.6),
        (head_cx + 2.4, head_cy - 11.6), (head_cx + 7.6, head_cy - 10.4),
        (head_cx + 11.0, head_cy - 6.4), (head_cx + 10.0, head_cy - 0.6),
        (head_cx + 6.6, head_cy - 3.4), (head_cx + 3.0, head_cy - 2.2),
        (head_cx - 0.6, head_cy - 3.6), (head_cx - 4.4, head_cy - 2.4),
        (head_cx - 7.8, head_cy - 3.8),
    ]
    xp.poly(bangs, A(HAIR), A(OUTLINE), 0.9)
    xp.poly([(head_cx - 7.0, head_cy - 8.6), (head_cx - 2.0, head_cy - 9.4),
             (head_cx + 1.0, head_cy - 7.0), (head_cx - 4.0, head_cy - 6.6)],
            A(HAIR_LIGHT))
    for side in (-1.0, 1.0):
        lock = [
            (head_cx + side * 10.0, head_cy - 6.0),
            (head_cx + side * 12.0, head_cy + 2.0),
            (head_cx + side * 11.4, head_cy + 14.0),
            (head_cx + side * 8.6, head_cy + 19.0),
            (head_cx + side * 7.0, head_cy + 12.0),
            (head_cx + side * 7.6, head_cy + 1.0),
        ]
        xp.poly(lock, A(HAIR), A(OUTLINE), 0.8)
        xp.poly([(head_cx + side * 9.6, head_cy - 3.0),
                 (head_cx + side * 10.6, head_cy + 8.0),
                 (head_cx + side * 9.0, head_cy + 13.0),
                 (head_cx + side * 8.4, head_cy + 3.0)], A(HAIR_SHADE))
    xp.line([(head_cx - 1.0, head_cy - 10.6), (head_cx - 0.4, head_cy - 14.2),
             (head_cx + 2.2, head_cy - 15.0)], A(HAIR), 1.5)
    pin_x = head_cx + (7.4 if sx <= 0 else -7.4)
    pin_y = head_cy - 6.8
    for a in range(3):
        ang = math.pi * a / 3.0
        dx, dy = math.cos(ang) * 2.4, math.sin(ang) * 2.4
        xp.line([(pin_x - dx, pin_y - dy), (pin_x + dx, pin_y + dy)],
                A(ACCENT), 0.85)
    xp.ell(pin_x, pin_y, 0.8, 0.8, A(WHITE))

    # ------------------------------------------------------------- spell effects
    if pose["orb"] > 0.01:
        orb = pose["orb"]
        ox = cx + sx * 14.0 + 3.0
        oy = by - 40.0 + upper * 0.5
        xp.ell(ox, oy, 4.0 + 4.0 * orb, 4.0 + 4.0 * orb,
               (ACCENT[0], ACCENT[1], ACCENT[2], int(30 * orb * alpha)))
        xp.ell(ox, oy, 2.2 + 2.8 * orb, 2.2 + 2.8 * orb,
               (ACCENT[0], ACCENT[1], ACCENT[2], int(170 * orb * alpha)))
        xp.ell(ox, oy, 1.0 + 1.2 * orb, 1.0 + 1.2 * orb,
               (WHITE[0], WHITE[1], WHITE[2], int(230 * orb * alpha)))
        for ring in range(2):
            rr = (6.0 + 5.0 * ring) * (0.6 + 0.4 * orb)
            xp.arc(ox, oy, rr, rr, ring * 60 + orb * 200,
                   ring * 60 + 250 + orb * 200,
                   (ACCENT[0], ACCENT[1], ACCENT[2], int(90 * orb * alpha)), 1.0)

    if pose["slash"] > 0.01:
        sl = pose["slash"]
        ox = cx + sx * 16.0 + 2.0
        oy = by - 38.0
        for j in range(2):
            rr = 13.0 + j * 3.0
            xp.arc(ox, oy, rr, rr * 0.72, -70 + 20 * j, 60 + 10 * j,
                   (ACCENT[0], ACCENT[1], ACCENT[2], int((180 - 50 * j) * sl * alpha)),
                   2.4 - j * 0.7)
            xp.arc(ox, oy, rr - 2.0, rr * 0.66, -60 + 20 * j, 55 + 10 * j,
                   (WHITE[0], WHITE[1], WHITE[2], int(150 * sl * alpha)), 0.9)

    # ------------------------------------------------------------- ghost wisps
    wisp_ph = pose["wisp"]
    for idx in range(3):
        ang = wisp_ph * math.tau + idx * 2.1
        wx = cx + math.cos(ang) * (13.0 + idx * 2.0)
        wy = by - 30.0 - idx * 12.0 + math.sin(ang * 1.3) * 3.0
        wa = int((60 - idx * 12) * alpha)
        xp.ell(wx, wy, 1.5 - idx * 0.2, 2.2 - idx * 0.25,
               (ACCENT[0], ACCENT[1], ACCENT[2], wa))

    # ---------------------------------------------------------------- sparkles
    if pose["sparkle"] > 0.05:
        sp = pose["sparkle"]
        for idx in range(4):
            ang = idx * 1.7 + wisp_ph * 1.2
            rad = 16.0 + (idx % 2) * 7.0
            sx2 = cx + math.cos(ang) * rad
            sy2 = by - 44.0 + math.sin(ang) * rad * 0.7
            xp.star(sx2, sy2, (2.2 + (idx % 2)) * sp,
                    (ACCENT[0], ACCENT[1], ACCENT[2], int(200 * sp * alpha)))

    # ------------------------------------------------------------------- flash
    if pose["flash"] > 0.01:
        xp.ell(cx, by - 40.0, 18.0, 30.0,
               (255, 120, 140, int(90 * pose["flash"] * alpha)))


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
    """256x384 RGBA8 bust portrait (drawn at 4x)."""
    pen = Pen(256, 384, S)
    cx = 128.0
    # aura
    for r, a in ((150, 16), (120, 20), (92, 24)):
        pen.ell(cx, 190, r, r, (ACCENT[0], ACCENT[1], ACCENT[2], a))
    # back hair
    back = [
        (cx - 70, 128), (cx - 84, 100), (cx - 78, 62), (cx - 52, 38),
        (cx - 12, 30), (cx + 30, 34), (cx + 68, 56), (cx + 82, 92),
        (cx + 74, 150), (cx + 88, 236), (cx + 96, 340), (cx + 66, 384),
        (cx + 40, 352), (cx + 22, 384), (cx + 4, 344), (cx - 12, 384),
        (cx - 34, 346), (cx - 58, 384), (cx - 82, 330), (cx - 92, 230),
    ]
    pen.poly(back, HAIR_SHADE, OUTLINE, 2.0)
    # inner hair strands
    for off, col, w in ((-52, HAIR_DEEP, 2.0), (-20, HAIR_SHADE, 2.6),
                        (18, HAIR_DEEP, 2.0), (50, HAIR_SHADE, 2.6)):
        pen.line([(cx + off * 0.55, 90), (cx + off, 190), (cx + off * 1.25, 300),
                  (cx + off * 1.4, 360)], col, w)

    # shoulders / dress
    pen.poly([(cx - 112, 384), (cx - 96, 322), (cx - 62, 292),
              (cx - 24, 278), (cx + 24, 278), (cx + 62, 292),
              (cx + 96, 322), (cx + 112, 384)], DRESS, OUTLINE, 2.2)
    pen.poly([(cx - 54, 300), (cx - 20, 284), (cx + 20, 284),
              (cx + 54, 300), (cx + 40, 384), (cx - 40, 384)], DRESS_LIGHT)
    # collar trim
    pen.poly([(cx - 30, 284), (cx, 306), (cx + 30, 284), (cx + 22, 278),
              (cx, 294), (cx - 22, 278)], TRIM)
    pen.poly([(cx - 20, 312), (cx + 20, 312), (cx + 16, 326), (cx - 16, 326)],
             ACCENT)
    pen.ell(cx, 318, 5, 6, ACCENT_DEEP)

    # neck
    pen.poly([(cx - 20, 246), (cx + 20, 246), (cx + 26, 286),
              (cx - 26, 286)], SKIN_SHADE)
    pen.poly([(cx - 14, 246), (cx + 14, 246), (cx + 18, 276),
              (cx - 18, 276)], SKIN)

    # head
    pen.ell(cx, 156, 64, 76, SKIN, OUTLINE, 2.0)
    pen.ell(cx + 34, 176, 26, 40, SKIN_SHADE)
    # ears
    pen.ell(cx - 64, 168, 10, 16, SKIN_SHADE, OUTLINE, 1.2)
    pen.ell(cx + 64, 168, 10, 16, SKIN_SHADE, OUTLINE, 1.2)
    pen.ell(cx - 64, 168, 4, 8, SKIN_LINE)
    pen.ell(cx + 64, 168, 4, 8, SKIN_LINE)

    # eyes
    eye_y = 164
    for side in (-1, 1):
        ex = cx + side * 27
        pen.ell(ex, eye_y, 18, 22, EYE_DARK)
        pen.ell(ex, eye_y + 2, 14, 18, EYE_BLUE)
        pen.ell(ex, eye_y + 4, 10, 14, IRIS)
        pen.ell(ex, eye_y + 7, 7, 9, IRIS_LIGHT)
        pen.ell(ex, eye_y + 6, 4.2, 6.5, EYE_DARK)
        pen.ell(ex - 5, eye_y - 7, 4.6, 5.6, WHITE)
        pen.ell(ex + 5, eye_y + 10, 2.6, 2.6, WHITE)
        # lash line
        pen.line([(ex - 20, eye_y - 16), (ex + 20, eye_y - 20)], EYE_DARK, 3.2)
        pen.line([(ex + side * 16, eye_y - 18), (ex + side * 22, eye_y - 24)],
                 EYE_DARK, 2.4)
        # brow
        pen.line([(ex - 15, eye_y - 34), (ex + 15, eye_y - 37)], HAIR_DEEP, 2.0)

    # nose + mouth
    pen.ell(cx + 1, 204, 2.0, 1.6, SKIN_LINE)
    pen.line([(cx - 8, 224), (cx + 8, 224)], (170, 120, 140, 230), 2.2)
    pen.line([(cx - 4, 228), (cx + 4, 228)], (170, 120, 140, 150), 1.4)
    # blush
    for side in (-1, 1):
        pen.ell(cx + side * 42, 196, 13, 6, BLUSH)

    # bangs
    bangs = [
        (cx - 66, 148), (cx - 70, 100), (cx - 52, 70), (cx - 22, 56),
        (cx + 6, 60), (cx + 40, 52), (cx + 66, 74), (cx + 72, 112),
        (cx + 64, 146), (cx + 50, 108), (cx + 44, 138), (cx + 28, 100),
        (cx + 20, 132), (cx + 4, 96), (cx - 6, 136), (cx - 24, 98),
        (cx - 34, 142), (cx - 50, 100), (cx - 58, 140),
    ]
    pen.poly(bangs, HAIR, OUTLINE, 2.0)
    # bang highlights
    pen.poly([(cx - 46, 92), (cx - 22, 80), (cx - 4, 86), (cx - 26, 100)], HAIR_LIGHT)
    pen.poly([(cx + 18, 84), (cx + 40, 80), (cx + 52, 96), (cx + 30, 100)], HAIR_LIGHT)
    # side locks
    for side in (-1, 1):
        pen.poly([(cx + side * 62, 120), (cx + side * 78, 160),
                  (cx + side * 84, 240), (cx + side * 70, 300),
                  (cx + side * 54, 246), (cx + side * 52, 158)],
                 HAIR, OUTLINE, 2.0)
        pen.line([(cx + side * 68, 150), (cx + side * 76, 210),
                  (cx + side * 70, 276)], HAIR_SHADE, 3.0)
    # ahoge
    pen.line([(cx + 2, 56), (cx + 6, 26), (cx + 24, 16)], HAIR, 5.0)
    pen.line([(cx + 2, 56), (cx + 6, 26), (cx + 24, 16)], OUTLINE, 1.4)
    # snowflake hairpin
    px, py = cx + 52, 108
    for a in range(3):
        ang = math.pi * a / 3.0
        dx, dy = math.cos(ang) * 15, math.sin(ang) * 15
        pen.line([(px - dx, py - dy), (px + dx, py + dy)], ACCENT, 3.0)
        pen.ell(px + dx, py + dy, 2.4, 2.4, WHITE)
    pen.ell(px, py, 5.0, 5.0, WHITE)

    # snow motes
    for mx, my, mr in ((28, 60, 2.4), (222, 84, 3.0), (38, 300, 2.0),
                       (214, 330, 2.6), (18, 190, 1.8), (238, 210, 2.2)):
        pen.star(mx, my, mr, (ACCENT[0], ACCENT[1], ACCENT[2], 190))

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
    draw_character(XPen(pen, 64.0, 183.0, 1.28), 1, pose)
    img = pen.finish()
    return img


def draw_full_body() -> Image.Image:
    """1024x2048 standing key illustration (bottom-centre anchor)."""
    pen = Pen(1024, 2048, 1)
    pose = pose_for("idle", 1, 5)
    pose["sparkle"] = 0.8
    pose["wisp"] = 0.35
    draw_character(XPen(pen, 512.0, 1960.0, 24.0), 1, pose)
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
