from pathlib import Path
p=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\scenes\world\castle_gardens\components\castle_pathways.tscn")
s=p.read_text(encoding="utf-8")
extra=["Vector2i(24, 17)","Vector2i(22, 17)","Vector2i(20, 16)","Vector2i(19, 14)",
       "Vector2i(37, 8)","Vector2i(36, 7)","Vector2i(35, 5)","Vector2i(34, 3)",
       "Vector2i(22, 8)","Vector2i(21, 8)","Vector2i(20, 9)","Vector2i(19, 9)",
       "Vector2i(26, 4)","Vector2i(27, 3)","Vector2i(28, 2)","Vector2i(28, 1)"]
line=next(x for x in s.splitlines() if x.startswith("branch_cells = "))
if "Vector2i(24, 17)" not in line:
    line=line[:-1]+", "+", ".join(extra)+"]"
    s=s.replace(next(x for x in s.splitlines() if x.startswith("branch_cells = ")),line)
    p.write_text(s,encoding="utf-8")
cam=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\scenes\world\castle_gardens\components\reverie_royal_gardens_full_preview.tscn")
s=cam.read_text(encoding="utf-8").replace("position = Vector2(640, 620)\nzoom = Vector2(0.58, 0.58)","position = Vector2(760, 620)\nzoom = Vector2(0.48, 0.48)")
cam.write_text(s,encoding="utf-8")
print("PATH_NETWORK_EXPANDED",len(extra),"NEW_CELLS")
print("PREVIEW_FRAMING_REBALANCED")
