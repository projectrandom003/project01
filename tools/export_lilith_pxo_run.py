from __future__ import annotations
import hashlib, json, re, shutil, zipfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path.home() / "Downloads"
ASSET = ROOT / "assets" / "characters" / "lilith"
SOURCE = ASSET / "source" / "directional_run_pxo"
EXPORT = ASSET / "source_run_png"
FILES = {
    "south": "southrun lilith.pxo",
    "south-east": "south-eastrunlilith.pxo",
    "east": "eastrun lilith.pxo",
    "north-east": "north-eastrun lilith.pxo",
    "north": "northrunlilith.pxo",
    "north-west": "north-westrun lilith.pxo",
    "west": "westrunlilith.pxo",
    "south-west": "south-westrunlilith.pxo",
}
CELL=(96,128); SRC_FRAMES=17; SRC_FPS=6.0; GAME_FRAMES=16; GAME_FPS=16.0

def sha(p):
    h=hashlib.sha256()
    with p.open("rb") as f:
        for b in iter(lambda:f.read(1024*1024),b""): h.update(b)
    return h.hexdigest()

def vec(s, pattern):
    m=re.fullmatch(pattern,s)
    if not m: raise ValueError(f"unsupported PXO vector: {s!r}")
    return tuple(map(int,m.groups()))

def load(path):
    digest=sha(path)
    with zipfile.ZipFile(path) as z:
        meta=json.loads(z.read("data.json"))
        if len(meta["frames"]) != SRC_FRAMES: raise ValueError(f"{path.name}: expected 17 frames, got {len(meta['frames'])}")
        fps=float(meta["fps"])
        if fps != SRC_FPS: raise ValueError(f"{path.name}: expected 6 FPS, got {fps}")
        size=(int(meta["size_x"]),int(meta["size_y"]))
        frames=[]
        for i,fr in enumerate(meta["frames"],1):
            if len(fr["cels"]) != 1: raise ValueError(f"{path.name}: frame {i} has {len(fr['cels'])} cels")
            cel=fr["cels"][0]
            w,h=vec(cel["image_size"],r"Vector2i\((\d+),\s*(\d+)\)")
            ox,oy=vec(cel["offset"],r"\((-?\d+),\s*(-?\d+)\)")
            raw=z.read(f"image_data/frames/{i}/layer_1")
            if len(raw)!=w*h*4: raise ValueError(f"{path.name}: frame {i} RGBA size mismatch")
            layer=Image.frombytes("RGBA",(w,h),raw)
            canvas=Image.new("RGBA",size,(0,0,0,0)); canvas.alpha_composite(layer,(ox,oy))
            bbox=canvas.getchannel("A").getbbox()
            if bbox is None: raise ValueError(f"{path.name}: frame {i} is transparent")
            sprite=canvas.crop(bbox)
            scale=min(1.0,CELL[0]/sprite.width,CELL[1]/sprite.height)
            if scale<1:
                sprite=sprite.resize((max(1,round(sprite.width*scale)),max(1,round(sprite.height*scale))),Image.Resampling.NEAREST)
            cell=Image.new("RGBA",CELL,(0,0,0,0))
            cell.alpha_composite(sprite,((CELL[0]-sprite.width)//2,CELL[1]-sprite.height))
            frames.append(cell)
    if sha(path)!=digest: raise RuntimeError(f"source changed: {path}")
    return frames,digest

def main():
    missing=[str(DOWNLOADS/name) for name in FILES.values() if not (DOWNLOADS/name).is_file()]
    if missing: raise FileNotFoundError("Missing source PXO files: "+", ".join(missing))
    if SOURCE.exists() or EXPORT.exists(): raise FileExistsError("Refusing to overwrite existing source/export folders")
    SOURCE.mkdir(parents=True); EXPORT.mkdir(parents=True)
    (SOURCE/".gdignore").write_text("# Original PixelLab PXO run projects; retained read-only.\n",encoding="utf-8")
    atlas=Image.new("RGBA",(GAME_FRAMES*CELL[0],8*CELL[1]),(0,0,0,0))
    indices=[round(i*(SRC_FRAMES-1)/(GAME_FRAMES-1)) for i in range(GAME_FRAMES)]
    manifest={"character":"lilith","state":"run","source_format":"PixelLab .pxo","source_frames":SRC_FRAMES,"source_fps":SRC_FPS,"game_frames":GAME_FRAMES,"game_fps":GAME_FPS,"loop":True,"cell_size":list(CELL),"direction_order":list(FILES),"sampled_source_frame_indices":indices,"directions":[]}
    for row,(direction,filename) in enumerate(FILES.items()):
        src=DOWNLOADS/filename; shutil.copy2(src,SOURCE/(direction+".pxo"))
        frames,digest=load(src)
        strip=Image.new("RGBA",(SRC_FRAMES*CELL[0],CELL[1]),(0,0,0,0))
        for i,frame in enumerate(frames): strip.alpha_composite(frame,(i*CELL[0],0))
        strip.save(EXPORT/(direction+".png"),optimize=True)
        for col,idx in enumerate(indices): atlas.alpha_composite(frames[idx],(col*CELL[0],row*CELL[1]))
        manifest["directions"].append({"direction":direction,"source_file":filename,"source_sha256":digest,"source_frame_count":len(frames),"source_fps":SRC_FPS,"export_png":f"source_run_png/{direction}.png","strip_size":list(strip.size)})
    out=ASSET/"run_sheet.png"; atlas.save(out,optimize=True)
    alpha=atlas.getchannel("A")
    checks=[]
    for row in range(8):
        for col in range(GAME_FRAMES):
            b=alpha.crop((col*CELL[0],row*CELL[1],(col+1)*CELL[0],(row+1)*CELL[1])).getbbox()
            checks.append(b is not None and b[3]==CELL[1])
    if atlas.size!=(1536,1024) or not all(checks): raise RuntimeError(f"Atlas validation failed: {atlas.size}, cells={sum(checks)}/128")
    manifest["atlas"]="run_sheet.png"; manifest["atlas_size"]=list(atlas.size); manifest["validated_cells"]=sum(checks)
    (EXPORT/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n",encoding="utf-8")
    print("LILITH RUN EXPORT COMPLETE")
    print("8 directions x 17 source frames; exported strips are 1632x128 RGBA")
    print("Runtime atlas: 1536x1024 RGBA, 8 directions x 16 frames")
    print("Directions: "+", ".join(FILES))
    print("All 128 runtime cells bottom-aligned and non-empty")
    print("Original PXO projects copied read-only; source hashes verified")

if __name__=="__main__": main()
