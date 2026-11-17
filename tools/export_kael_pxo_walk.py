#!/usr/bin/env python3
"""Export Kael's eight Pixelorama walking projects into Reverie's walk atlas.

PXO inputs remain read-only. Each source cel is placed on its transparent
canvas, cropped to alpha, and bottom-centre aligned in a 96x128 game cell.
The standalone PNGs retain all 17 source frames at the PXO's 6 FPS. The game
atlas adapts them to Reverie's 16-frame WALK contract.
"""
from __future__ import annotations
import hashlib
import json
import re
import zipfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path.home() / "Downloads"
ASSET = ROOT / "assets" / "characters" / "kael_avatar"
DIRECTIONAL = ASSET / "source_walk_png"
DIRECTIONS = ("south", "south-east", "east", "north-east",
              "north", "north-west", "west", "south-west")
CELL = (96, 128)
SOURCE_FRAMES = 17
SOURCE_FPS = 6.0
GAME_FRAMES = 16
GAME_FPS = 12.0


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def size_pair(value: str) -> tuple[int, int]:
    m = re.fullmatch(r"Vector2i\((\d+),\s*(\d+)\)", value)
    if not m:
        raise ValueError(f"unsupported PXO image_size: {value!r}")
    return int(m.group(1)), int(m.group(2))


def offset_pair(value: str) -> tuple[int, int]:
    m = re.fullmatch(r"\((-?\d+),\s*(-?\d+)\)", value)
    if not m:
        raise ValueError(f"unsupported PXO offset: {value!r}")
    return int(m.group(1)), int(m.group(2))


def load_frames(path: Path) -> tuple[list[Image.Image], float, str]:
    before = sha(path)
    with zipfile.ZipFile(path) as z:
        meta = json.loads(z.read("data.json"))
        if len(meta["frames"]) != SOURCE_FRAMES:
            raise ValueError(f"{path.name}: expected 17 frames, got {len(meta['frames'])}")
        fps = float(meta["fps"])
        if fps != SOURCE_FPS:
            raise ValueError(f"{path.name}: expected 6 FPS, got {fps}")
        cw, ch = int(meta["size_x"]), int(meta["size_y"])
        out = []
        for i, frame in enumerate(meta["frames"], 1):
            if len(frame["cels"]) != 1:
                raise ValueError(f"{path.name}: frame {i} has multiple cels")
            cel = frame["cels"][0]
            w, h = size_pair(cel["image_size"])
            ox, oy = offset_pair(cel["offset"])
            raw = z.read(f"image_data/frames/{i}/layer_1")
            if len(raw) != w * h * 4:
                raise ValueError(f"{path.name} frame {i}: {len(raw)} bytes, expected RGBA {w*h*4}")
            layer = Image.frombytes("RGBA", (w, h), raw)
            canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
            canvas.alpha_composite(layer, (ox, oy))
            bbox = canvas.getchannel("A").getbbox()
            if bbox is None:
                raise ValueError(f"{path.name} frame {i}: fully transparent")
            sprite = canvas.crop(bbox)
            scale = min(1.0, CELL[0] / sprite.width, CELL[1] / sprite.height)
            if scale < 1.0:
                nw, nh = max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))
                sprite = sprite.resize((nw, nh), Image.Resampling.NEAREST)
            cell = Image.new("RGBA", CELL, (0, 0, 0, 0))
            cell.alpha_composite(sprite, ((CELL[0] - sprite.width) // 2,
                                          CELL[1] - sprite.height))
            out.append(cell)
    if sha(path) != before:
        raise RuntimeError(f"source unexpectedly changed: {path}")
    return out, fps, before


def main() -> None:
    if DIRECTIONAL.exists():
        raise FileExistsError(f"refusing to overwrite export folder: {DIRECTIONAL}")
    DIRECTIONAL.mkdir(parents=True)
    atlas = Image.new("RGBA", (GAME_FRAMES * CELL[0], len(DIRECTIONS) * CELL[1]),
                      (0, 0, 0, 0))
    report = {"character": "kael", "source": "Pixelorama .pxo",
              "source_frames": SOURCE_FRAMES, "source_fps": SOURCE_FPS,
              "export_cell": list(CELL), "game_state": "walk",
              "game_frames": GAME_FRAMES, "game_fps": GAME_FPS,
              "directions": []}
    for row, direction in enumerate(DIRECTIONS):
        path = DOWNLOADS / f"{direction}.pxo"
        if not path.is_file():
            raise FileNotFoundError(path)
        frames, fps, digest = load_frames(path)
        strip = Image.new("RGBA", (SOURCE_FRAMES * CELL[0], CELL[1]),
                          (0, 0, 0, 0))
        for i, frame in enumerate(frames):
            strip.alpha_composite(frame, (i * CELL[0], 0))
        strip.save(DIRECTIONAL / f"{direction}.png", optimize=True)

        # Select 16 evenly spaced samples from the complete 17-frame cycle,
        # retaining both endpoints and the source's loop closure.
        indices = [round(i * (SOURCE_FRAMES - 1) / (GAME_FRAMES - 1))
                   for i in range(GAME_FRAMES)]
        for col, src_i in enumerate(indices):
            atlas.alpha_composite(frames[src_i], (col * CELL[0], row * CELL[1]))
        report["directions"].append({
            "direction": direction, "source_file": str(path),
            "source_sha256_unchanged": digest, "source_canvas": "per-frame PXO canvas",
            "source_frames": len(frames), "source_fps": fps,
            "export": f"source_walk_png/{direction}.png",
            "export_size": list(strip.size), "game_sample_indices": indices,
            "foot_anchor": "bottom-centre in each 96x128 transparent cell",
        })
    atlas.save(ASSET / "walk_sheet.png", optimize=True)
    if atlas.size != (1536, 1024) or atlas.getchannel("A").getbbox() is None:
        raise RuntimeError(f"invalid game atlas: {atlas.size}")
    report["game_atlas"] = "walk_sheet.png"
    report["game_atlas_size"] = list(atlas.size)
    report["game_atlas_alpha_bbox"] = list(atlas.getchannel("A").getbbox())
    (DIRECTIONAL / "manifest.json").write_text(json.dumps(report, indent=2) + "\n",
                                               encoding="utf-8")
    print(f"[Kael PXO] exported {len(DIRECTIONS)} directions")
    for item in report["directions"]:
        print(f"[Kael PXO] {item['direction']}: 17 frames @ 6 FPS -> "
              f"{item['export_size'][0]}x{item['export_size'][1]} PNG; "
              f"16 game frames @ 12 FPS")
    print(f"[Kael PXO] walk_sheet.png: {atlas.width}x{atlas.height}, "
          "8 rows x 16 columns, transparent RGBA")
    print("[Kael PXO] source hashes verified unchanged")


if __name__ == "__main__":
    main()
