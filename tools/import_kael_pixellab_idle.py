#!/usr/bin/env python3
"""Install Kael's PixelLab still direction poses as Reverie's idle atlas.

The supplied 17-frame front strip reads as locomotion, so the idle atlas uses
the eight still direction views for all rows and repeats each pose for the
runtime's 5-frame idle loop. Source references are preserved in a .gdignore
folder and are never modified.
"""
from __future__ import annotations
import hashlib
import json
import shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path.home() / "Downloads"
ASSET = ROOT / "assets" / "characters" / "kael_avatar"
SOURCE = ASSET / "source_idle_png"
DIR_REF = DOWNLOADS / "pixellab-character-5e8a5e75-directions.png"
IDLE_REF = DOWNLOADS / "pixellab-character-5e8a5e75-sheet.png"
DIR_SOURCE = SOURCE / "pixellab_directions.png"
IDLE_SOURCE = SOURCE / "pixellab_idle_17.png"
CELL_W, CELL_H = 96, 128
DIRECTIONS = ("down", "down_right", "right", "up_right",
              "up", "up_left", "left", "down_left")
IDLE_FRAMES = 5


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def fit_bottom_center(frame: Image.Image) -> Image.Image:
    frame = frame.convert("RGBA")
    bbox = frame.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("reference frame is fully transparent")
    sprite = frame.crop(bbox)
    scale = min(1.0, CELL_W / sprite.width, CELL_H / sprite.height)
    if scale < 1.0:
        size = (max(1, round(sprite.width * scale)),
                max(1, round(sprite.height * scale)))
        sprite = sprite.resize(size, Image.Resampling.NEAREST)
    cell = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    cell.alpha_composite(sprite, ((CELL_W - sprite.width) // 2,
                                  CELL_H - sprite.height))
    return cell


def source_paths() -> tuple[Path, Path]:
    if SOURCE.exists():
        if not DIR_SOURCE.is_file() or not IDLE_SOURCE.is_file():
            raise FileNotFoundError(f"incomplete source archive: {SOURCE}")
        return DIR_SOURCE, IDLE_SOURCE
    if not DIR_REF.is_file() or not IDLE_REF.is_file():
        raise FileNotFoundError("Both supplied PixelLab reference PNGs must exist in Downloads")
    SOURCE.mkdir(parents=True)
    shutil.copy2(DIR_REF, DIR_SOURCE)
    shutil.copy2(IDLE_REF, IDLE_SOURCE)
    (SOURCE / ".gdignore").write_text(
        "# Original PixelLab inputs; source art kept out of runtime imports.\n",
        encoding="utf-8")
    return DIR_SOURCE, IDLE_SOURCE


def main() -> None:
    directions_path, idle_path = source_paths()
    source_hashes = {p.name: sha(p) for p in (directions_path, idle_path)}
    directions = Image.open(directions_path).convert("RGBA")
    idle_strip = Image.open(idle_path).convert("RGBA")
    if directions.size != (1024, 128):
        raise ValueError(f"directions sheet is {directions.size}, expected 1024x128 (8x128)")
    if idle_strip.size != (2788, 164):
        raise ValueError(f"idle strip is {idle_strip.size}, expected 2788x164 (17x164)")
    if directions.getchannel("A").getextrema()[0] != 0:
        raise ValueError("direction sheet has no transparent pixels")
    if idle_strip.getchannel("A").getextrema()[0] != 0:
        raise ValueError("idle strip has no transparent pixels")

    direction_cells = []
    for i in range(8):
        raw = directions.crop((i * 128, 0, (i + 1) * 128, 128))
        direction_cells.append(fit_bottom_center(raw))

    atlas = Image.new("RGBA", (IDLE_FRAMES * CELL_W, 8 * CELL_H),
                      (0, 0, 0, 0))
    for row, cell in enumerate(direction_cells):
        for col in range(IDLE_FRAMES):
            atlas.alpha_composite(cell, (col * CELL_W, row * CELL_H))
    out_path = ASSET / "idle_sheet.png"
    atlas.save(out_path, optimize=True)

    if sha(directions_path) != source_hashes[directions_path.name] or sha(idle_path) != source_hashes[idle_path.name]:
        raise RuntimeError("source reference changed during import")
    alpha = atlas.getchannel("A")
    anchors_ok = all(
        (lambda b: b is not None and b[3] == CELL_H)(
            alpha.crop((c * CELL_W, r * CELL_H,
                        (c + 1) * CELL_W, (r + 1) * CELL_H)).getbbox())
        for r in range(8) for c in range(IDLE_FRAMES))
    if atlas.size != (480, 1024) or not anchors_ok:
        raise RuntimeError(f"atlas/anchor validation failed: {atlas.size}, {anchors_ok}")

    manifest = {
        "character": "kael",
        "asset": "idle_sheet.png",
        "asset_size": list(atlas.size),
        "frame_size": [CELL_W, CELL_H],
        "directions": list(DIRECTIONS),
        "idle_frames": IDLE_FRAMES,
        "idle_fps": 9,
        "looping": True,
        "pose_source": "eight still direction views",
        "animation_strip_usage": "retained for reference only; not used because it reads as walking",
        "repeated_pose_frames": "each directional idle pose repeated 5x",
        "anchor": "bottom-centre, alpha bounds end at each cell's bottom edge",
        "source_files": {
            "directions": {"file": "source_idle_png/pixellab_directions.png",
                           "size": [1024, 128], "sha256": source_hashes[DIR_SOURCE.name]},
            "idle_strip": {"file": "source_idle_png/pixellab_idle_17.png",
                           "size": [2788, 164], "frames": 17,
                           "sha256": source_hashes[IDLE_SOURCE.name]},
        },
    }
    (SOURCE / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n",
                                          encoding="utf-8")
    print("[Kael idle] eight PixelLab direction poses installed")
    print("[Kael idle] front row is the still front-facing pose (no walking frames)")
    print("[Kael idle] atlas: 480x1024 RGBA, 8 directions x 5 frames @ 9 FPS")
    print("[Kael idle] all 40 cells transparent, nonempty, bottom-centre aligned")
    print("[Kael idle] the supplied 17-frame strip is archived but intentionally unused")


if __name__ == "__main__":
    main()
