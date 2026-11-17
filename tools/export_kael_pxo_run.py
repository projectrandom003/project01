#!/usr/bin/env python3
"""Export Kael's eight Pixelorama run projects into Reverie's RUN atlas.

PXO sources are read-only. Per-direction transparent PNG strips preserve all
17 source frames at 6 FPS. The integrated atlas adapts them to Reverie's
16-frame RUN contract and aligns each frame to a bottom-centre 96x128 cell.
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
DIRECTIONAL = ASSET / "source_run_png"
SOURCE_FILES = {
    "south": "southrun.pxo",
    "south-east": "south-eastrun.pxo",
    "east": "eastrun.pxo",
    "north-east": "north-eastrun.pxo",
    "north": "northrun.pxo",
    "north-west": "north-west (run).pxo",
    "west": "westrun.pxo",
    "south-west": "south-westrun.pxo",
}
DIRECTIONS = tuple(SOURCE_FILES)
CELL = (96, 128)
SOURCE_FRAMES = 17
SOURCE_FPS = 6.0
GAME_FRAMES = 16
GAME_FPS = 16.0


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def pair(value: str, pattern: str) -> tuple[int, int]:
    m = re.fullmatch(pattern, value)
    if not m:
        raise ValueError(f"unsupported PXO vector: {value!r}")
    return int(m.group(1)), int(m.group(2))


def load_frames(path: Path) -> tuple[list[Image.Image], str]:
    digest = sha(path)
    with zipfile.ZipFile(path) as z:
        meta = json.loads(z.read("data.json"))
        if len(meta["frames"]) != SOURCE_FRAMES:
            raise ValueError(f"{path.name}: expected {SOURCE_FRAMES} frames, got {len(meta['frames'])}")
        if float(meta["fps"]) != SOURCE_FPS:
            raise ValueError(f"{path.name}: expected {SOURCE_FPS} FPS, got {meta['fps']}")
        canvas_size = (int(meta["size_x"]), int(meta["size_y"]))
        out = []
        for i, frame in enumerate(meta["frames"], 1):
            if len(frame["cels"]) != 1:
                raise ValueError(f"{path.name}: frame {i} has multiple cels")
            cel = frame["cels"][0]
            w, h = pair(cel["image_size"], r"Vector2i\((\d+),\s*(\d+)\)")
            ox, oy = pair(cel["offset"], r"\((-?\d+),\s*(-?\d+)\)")
            raw = z.read(f"image_data/frames/{i}/layer_1")
            if len(raw) != w * h * 4:
                raise ValueError(f"{path.name} frame {i}: invalid RGBA byte count")
            layer = Image.frombytes("RGBA", (w, h), raw)
            canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
            canvas.alpha_composite(layer, (ox, oy))
            bbox = canvas.getchannel("A").getbbox()
            if bbox is None:
                raise ValueError(f"{path.name} frame {i}: fully transparent")
            sprite = canvas.crop(bbox)
            scale = min(1.0, CELL[0] / sprite.width, CELL[1] / sprite.height)
            if scale < 1.0:
                sprite = sprite.resize((max(1, round(sprite.width * scale)),
                                        max(1, round(sprite.height * scale))),
                                       Image.Resampling.NEAREST)
            cell = Image.new("RGBA", CELL, (0, 0, 0, 0))
            cell.alpha_composite(sprite, ((CELL[0] - sprite.width) // 2,
                                          CELL[1] - sprite.height))
            out.append(cell)
    if sha(path) != digest:
        raise RuntimeError(f"source unexpectedly changed: {path}")
    return out, digest


def main() -> None:
    if DIRECTIONAL.exists():
        raise FileExistsError(f"refusing to overwrite export folder: {DIRECTIONAL}")
    DIRECTIONAL.mkdir(parents=True)
    atlas = Image.new("RGBA", (GAME_FRAMES * CELL[0],
                               len(DIRECTIONS) * CELL[1]), (0, 0, 0, 0))
    indices = [round(i * (SOURCE_FRAMES - 1) / (GAME_FRAMES - 1))
               for i in range(GAME_FRAMES)]
    report = {
        "character": "kael",
        "state": "run",
        "source": "Pixelorama .pxo",
        "source_frames": SOURCE_FRAMES,
        "source_fps": SOURCE_FPS,
        "cell_size": list(CELL),
        "game_frames": GAME_FRAMES,
        "game_fps": GAME_FPS,
        "game_loop": True,
        "game_sample_indices": indices,
        "direction_order": list(DIRECTIONS),
        "directions": [],
    }
    for row, direction in enumerate(DIRECTIONS):
        path = DOWNLOADS / SOURCE_FILES[direction]
        if not path.is_file():
            raise FileNotFoundError(path)
        frames, digest = load_frames(path)
        strip = Image.new("RGBA", (SOURCE_FRAMES * CELL[0], CELL[1]),
                          (0, 0, 0, 0))
        for i, frame in enumerate(frames):
            strip.alpha_composite(frame, (i * CELL[0], 0))
        strip.save(DIRECTIONAL / f"{direction}.png", optimize=True)
        for col, src_i in enumerate(indices):
            atlas.alpha_composite(frames[src_i], (col * CELL[0], row * CELL[1]))
        report["directions"].append({
            "direction": direction,
            "source_file": str(path),
            "source_sha256_unchanged": digest,
            "source_frames": len(frames),
            "source_fps": SOURCE_FPS,
            "png": f"source_run_png/{direction}.png",
            "png_size": list(strip.size),
            "anchor": "bottom-centre in each 96x128 cell",
        })
    atlas_path = ASSET / "run_sheet.png"
    atlas.save(atlas_path, optimize=True)
    alpha = atlas.getchannel("A")
    anchors_ok = all(
        (lambda b: b is not None and b[3] == CELL[1])(
            alpha.crop((c * CELL[0], r * CELL[1],
                        (c + 1) * CELL[0], (r + 1) * CELL[1])).getbbox())
        for r in range(len(DIRECTIONS)) for c in range(GAME_FRAMES))
    if atlas.size != (1536, 1024) or not anchors_ok:
        raise RuntimeError(f"atlas/anchor validation failed: {atlas.size}, {anchors_ok}")
    report["game_atlas"] = "run_sheet.png"
    report["game_atlas_size"] = list(atlas.size)
    report["all_cells_bottom_anchored"] = anchors_ok
    (DIRECTIONAL / "manifest.json").write_text(json.dumps(report, indent=2) + "\n",
                                               encoding="utf-8")
    print("[Kael run] exported 8 directions")
    for item in report["directions"]:
        print(f"[Kael run] {item['direction']}: 17 frames @ 6 FPS -> "
              f"{item['png_size'][0]}x{item['png_size'][1]} transparent PNG")
    print("[Kael run] game atlas: 1536x1024 RGBA, 8 rows x 16 columns")
    print("[Kael run] runtime timing: 16 FPS; every one of 128 cells bottom-centre aligned")
    print("[Kael run] source hashes verified unchanged")


if __name__ == "__main__":
    main()
