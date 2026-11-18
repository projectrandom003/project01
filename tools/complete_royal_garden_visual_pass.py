from pathlib import Path
root = Path(r"C:\Users\quoth\Documents\Default Project\project-fantasy")
flora = root / "scenes/world/castle_gardens/components/castle_flora_assembly.tscn"
props = root / "scenes/world/castle_gardens/components/castle_props_assembly.tscn"
for p in (flora, props):
    backup = p.with_suffix(p.suffix + ".pre_completion_pass_20261118.bak")
    if not backup.exists():
        backup.write_bytes(p.read_bytes())

# Build irregular, layered planting pockets with the project's existing authored art.
flora_nodes = [
("OuterWestPink01","8_pink_shrub",(175,475),0.88),("OuterWestViolet01","13_violet_shrub",(225,520),0.82),
("OuterWestWhite01","11_white_shrub",(155,555),0.78),("OuterWestRose01","10_hedge",(265,555),0.84),
("OuterEastPink01","8_pink_shrub",(1105,475),0.9),("OuterEastViolet01","13_violet_shrub",(1055,520),0.82),
("OuterEastWhite01","11_white_shrub",(1125,555),0.78),("OuterEastRose01","10_hedge",(1015,555),0.84),
("NorthWestPink01","8_pink_shrub",(360,305),0.82),("NorthWestWhite01","11_white_shrub",(420,335),0.72),
("NorthEastViolet01","13_violet_shrub",(920,305),0.84),("NorthEastPink01","8_pink_shrub",(860,335),0.76),
("WestPathPink01","8_pink_shrub",(300,635),0.72),("WestPathWhite01","11_white_shrub",(280,780),0.78),
("WestPathViolet01","13_violet_shrub",(405,765),0.76),("EastPathPink01","8_pink_shrub",(980,635),0.72),
("EastPathWhite01","11_white_shrub",(1000,780),0.78),("EastPathViolet01","13_violet_shrub",(875,765),0.76),
("CentralWestPink02","8_pink_shrub",(445,980),0.72),("CentralWestWhite02","11_white_shrub",(390,1030),0.78),
("CentralEastViolet02","13_violet_shrub",(835,980),0.72),("CentralEastWhite02","11_white_shrub",(890,1030),0.78),
("SouthWestPink01","8_pink_shrub",(205,990),0.8),("SouthWestViolet01","13_violet_shrub",(255,1050),0.74),
("SouthEastPink01","8_pink_shrub",(1075,990),0.8),("SouthEastWhite01","11_white_shrub",(1025,1050),0.74),
("WestParterreHedge02","12_rose_hedge",(190,865),0.72),("WestParterreHedge03","12_rose_hedge",(315,925),0.62),
("EastParterreHedge02","12_rose_hedge",(1090,865),0.72),("EastParterreHedge03","12_rose_hedge",(965,925),0.62),
("WestWisteriaCanopy","2_wisteria",(150,310),0.78),("EastWisteriaCanopy","2_wisteria",(1130,310),0.8),
("WestBlossomCanopy02","1_pink",(155,840),0.72),("EastBlossomCanopy02","1_pink",(1125,840),0.74),
("NorthGardenWhiteTree","3_white",(500,175),0.66),("NorthGardenPinkTree","1_pink",(780,175),0.66),
("WestCypressAccent","4_cypress",(90,790),0.72),("EastCypressAccent","4_cypress",(1190,790),0.72),
]
def sprite(name, ext, pos, scale):
    return f'\n[node name="{name}" type="Sprite2D" parent="OuterGardenEnrichment"]\ntexture = ExtResource("{ext}")\nposition = Vector2({pos[0]}, {pos[1]})\nscale = Vector2({scale}, {scale})\n'
s = flora.read_text(encoding="utf-8")
if "[node name=\"OuterGardenEnrichment\"" not in s:
    s += '\n[node name="OuterGardenEnrichment" type="Node2D" parent="."]\ny_sort_enabled = true\n'
    s += "".join(sprite(*n) for n in flora_nodes)
    flora.write_text(s, encoding="utf-8")

# More practical landmarks along the promenade and side courts: lamps, seating, and statues.
props_nodes = [
("LanternWestPromenadeNorth",(485,590),False,0.82),("LanternEastPromenadeNorth",(795,590),True,0.82),
("LanternWestPromenadeSouth",(485,850),False,0.82),("LanternEastPromenadeSouth",(795,850),True,0.82),
("LanternWestOuterCourt",(235,700),False,0.78),("LanternEastOuterCourt",(1045,700),True,0.78),
("LanternWestSouthCourt",(330,1110),False,0.78),("LanternEastSouthCourt",(950,1110),True,0.78),
]
s = props.read_text(encoding="utf-8")
if "[node name=\"SecondaryGardenFurnishings\"" not in s:
    s += '\n[node name="SecondaryGardenFurnishings" type="Node2D" parent="."]\ny_sort_enabled = true\n'
    for name,pos,flip,scale in props_nodes:
        s += f'\n[node name="{name}" type="Sprite2D" parent="SecondaryGardenFurnishings"]\ntexture = ExtResource("4_lantern")\nposition = Vector2({pos[0]}, {pos[1]})\nscale = Vector2({scale}, {scale})\n'
        if flip: s += "flip_h = true\n"
    # Use benches and statues as dedicated nodes rather than lantern texture.
    for name,pos,flip,scale in [
        ("WestRestingBench",(270,455),False,0.84),("EastRestingBench",(1010,455),True,0.84),
        ("WestGardenBenchSouth",(470,1130),False,0.78),("EastGardenBenchSouth",(810,1130),True,0.78)]:
        s += f'\n[node name="{name}Seat" type="Sprite2D" parent="SecondaryGardenFurnishings"]\ntexture = ExtResource("1_bench")\nposition = Vector2({pos[0]}, {pos[1]})\nscale = Vector2({scale}, {scale})\n'
        if flip: s += "flip_h = true\n"
    for name,pos,flip in [("WestGuardianOuter",(175,700),False),("EastGuardianOuter",(1105,700),True)]:
        s += f'\n[node name="{name}Statue" type="Sprite2D" parent="SecondaryGardenFurnishings"]\ntexture = ExtResource("2_statue")\nposition = Vector2({pos[0]}, {pos[1]})\nscale = Vector2(0.78, 0.78)\n'
        if flip: s += "flip_h = true\n"
    props.write_text(s, encoding="utf-8")

print("FLORA_ADDED", len(flora_nodes), "AUTHORED_SPRITES")
print("PROPS_ADDED", len(props_nodes), "LANTERNS_AND_SEATING_AND_STATUES")

