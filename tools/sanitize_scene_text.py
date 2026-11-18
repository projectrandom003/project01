from pathlib import Path
root=Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy\scenes\world\castle_gardens\components")
fixed=[]
for f in root.rglob("*.tscn"):
    s=f.read_text(encoding="utf-8-sig")
    lines=[line for line in s.splitlines() if "[executed on device:" not in line and not line.startswith("[Reading ")]
    while lines and not lines[0].strip(): lines.pop(0)
    out="\n".join(lines).rstrip()+"\n"
    if out!=s:
        f.write_text(out,encoding="utf-8")
        fixed.append(str(f.relative_to(root)))
print("Sanitized",len(fixed),"scene files")
for f in fixed: print(f)
