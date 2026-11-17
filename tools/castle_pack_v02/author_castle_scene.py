"""Author the Castle & Royal Gardens v0.2 world scene.

One-off authoring helper for the Castle Asset Pack v0.2 integration. It places
every pack piece on the project's isometric lattice (IsoMath, 64x32 cells),
checks that nothing overlaps a wall / path / pond, and writes an editable Godot
scene with one instanced child per piece.

Run from the project root:
    python tools/castle_pack_v02/author_castle_scene.py
"""
import json
from pathlib import Path

ROOT = Path('.')
MANIFEST = json.load(open('assets/castle_pack_v02/docs/manifest.json', encoding='utf-8'))

TILE_W, TILE_H = 64, 32

V02 = 'res://scenes/world/castle_gardens/v02/'
ARCH = V02 + 'architecture/'
FLORA = V02 + 'flora/'
PROPS = V02 + 'props/'
WATER = V02 + 'water/'
EFFECTS = V02 + 'effects/'
TERRAIN = V02 + 'terrain/'

# --------------------------------------------------------------- geometry ----


def grid_to_world(gx, gy):
    """IsoMath.grid_to_world for the 64x32 lattice."""
    return ((gx - gy) * (TILE_W // 2), (gx + gy) * (TILE_H // 2))


def footprint_center(anchor, w, d):
    """World position of the centre of a WxD footprint anchored at `anchor`."""
    gx, gy = grid_to_world(*anchor)
    return (gx + 16 * (w - d), gy + 8 * (w + d - 2))


def cells_of(anchor, w, d):
    return [(anchor[0] + i, anchor[1] + j) for i in range(w) for j in range(d)]


# ------------------------------------------------------------------ rules ----
SPINE_DIFF = 20           # screen-vertical avenue (screen x = 640)
CROSS_SUMS = (26, 31)     # screen-horizontal garden axes
CASTLE_X = (12, 22)       # castle enclosure, grid X range
CASTLE_Y = (-9, -1)       # castle enclosure, grid Y range
POND_CELLS = (
    [(23, 10), (24, 10), (25, 10), (23, 11), (24, 11), (25, 11)],
    [(29, 3), (30, 3), (31, 3), (29, 4), (30, 4), (31, 4)],
)
FOUNTAIN_CELLS = [(20, 0), (21, 0), (20, 1), (21, 1)]

# (scene, node name, anchor cell, footprint w, d, group)
LAYOUT = [
    # --- castle enclosure ---------------------------------------------------
    (ARCH + 'castle_tower.tscn', 'TowerNorthWest', (12, -9), 2, 2, 'Castle'),
    (ARCH + 'castle_tower.tscn', 'TowerNorthEast', (22, -9), 2, 2, 'Castle'),
    (ARCH + 'castle_tower.tscn', 'TowerSouthWest', (12, -2), 2, 2, 'Castle'),
    (ARCH + 'castle_tower.tscn', 'TowerSouthEast', (21, -2), 2, 2, 'Castle'),
    (ARCH + 'castle_wall_x.tscn', 'WallNorthA', (14, -8), 2, 1, 'Castle'),
    (ARCH + 'castle_wall_x.tscn', 'WallNorthB', (16, -8), 2, 1, 'Castle'),
    (ARCH + 'castle_wall_x.tscn', 'WallNorthC', (18, -8), 2, 1, 'Castle'),
    (ARCH + 'castle_wall_x.tscn', 'WallNorthD', (20, -8), 2, 1, 'Castle'),
    (ARCH + 'castle_wall_y.tscn', 'WallWestA', (12, -7), 1, 2, 'Castle'),
    (ARCH + 'castle_wall_y.tscn', 'WallWestB', (12, -5), 1, 2, 'Castle'),
    (ARCH + 'castle_wall_y.tscn', 'WallWestC', (12, -3), 1, 2, 'Castle'),
    (ARCH + 'castle_wall_y.tscn', 'WallEastA', (22, -7), 1, 2, 'Castle'),
    (ARCH + 'castle_wall_y.tscn', 'WallEastB', (22, -5), 1, 2, 'Castle'),
    (ARCH + 'castle_wall_y.tscn', 'WallEastC', (22, -3), 1, 2, 'Castle'),
    (ARCH + 'castle_wall_x.tscn', 'WallSouthA', (14, -1), 2, 1, 'Castle'),
    (ARCH + 'castle_wall_x.tssn', 'WallSouthB', (16, -1), 2, 1, 'Castle'),
    (ARCH + 'castle_gate_arch.tscn', 'Gatehouse', (18, -1), 3, 1, 'Castle'),
    (ARCH + 'castle_stairs.tscn', 'GrandStair', (19, 0), 4, 2, 'Castle'),
    # --- water ---------------------------------------------------------------
    (WATER + 'fountain_tiered.tscn', 'Fountain', (20, 0), 2, 2, 'Water'),
    # --- flora ---------------------------------------------------------------
    (FLORA + 'tree_oak_01.tscn', 'OakWestA', (16, 4), 1, 1, 'Flora'),
    (FLORA + 'tree_oak_01.tscn', 'OakWestB', (17, 7), 1, 1, 'Flora'),
    (FLORA + 'tree_oak_01.tscn', 'OakWestC', (18, 10), 1, 1, 'Flora'),
    (FLORA + 'tree_oak_01.tscn', 'OakWestD', (22, 5), 1, 1, 'Flora'),
    (FLORA + 'tree_oak_01.tscn', 'OakEastA', (25, 7), 1, 1, 'Flora'),
    (FLORA + 'tree_oak_01.tscn', 'OakEastB', (26, 10), 1, 1, 'Flora'),
    (FLORA + 'tree_oak_01.tscn', 'OakNorthA', (10, 3), 1, 1, 'Flora'),
    (FLORA + 'tree_oak_01.tscn', 'OakNorthB', (9, 6), 1, 1, 'Flora'),
    (FLORA + 'tree_blossom_01.tscn', 'BlossomWestA', (21, 4), 1, 1, 'Flora'),
    (FLORA + 'tree_blossom_01.tscn', 'BlossomWestB', (23, 6), 1, 1, 'Flora'),
    (FLORA + 'tree_blossom_01.tscn', 'BlossomEastA', (25, 4), 1, 1, 'Flora'),
    (FLORA + 'tree_blossom_01.tscn', 'BlossomEastB', (27, 8), 1, 1, 'Flora'),
    (FLORA + 'hedge_x.tscn', 'HedgeWestA', (17, 3), 2, 1, 'Flora'),
    (FLORA + 'hedge_x.tscn', 'HedgeWestB', (19, 5), 2, 1, 'Flora'),
    (FLORA + 'hedge_x.tscn', 'HedgeEastA', (23, 4), 2, 1, 'Flora'),
    (FLORA + 'hedge_x.tscn', 'HedgeEastB', (25, 9), 2, 1, 'Flora'),
    (FLORA + 'hedge_y.tscn', 'HedgeWestC', (16, 6), 1, 2, 'Flora'),
    (FLORA + 'hedge_y.tscn', 'HedgeEastC', (26, 6), 1, 2, 'Flora'),
    (FLORA + 'bush_round_01.tscn', 'BushWestA', (18, 6), 1, 1, 'Flora'),
    (FLORA + 'bush_round_01.tscn', 'BushWestB', (20, 9), 1, 1, 'Flora'),
    (FLORA + 'bush_round_01.tscn', 'BushEastA', (24, 8), 1, 1, 'Flora'),
    (FLORA + 'bush_round_01.tscn', 'BushEastB', (22, 3), 1, 1, 'Flora'),
    (FLORA + 'flower_bed_01.tscn', 'BedWestA', (18, 4), 1, 1, 'Flora'),
    (FLORA + 'flower_bed_01.tscn', 'BedWestB', (20, 8), 1, 1, 'Flora'),
    (FLORA + 'flower_bed_01.tscn', 'BedEastA', (24, 5), 1, 1, 'Flora'),
    (FLORA + 'flower_bed_01.tscn', 'BedEastB', (27, 4), 1, 1, 'Flora'),
    # --- props ---------------------------------------------------------------
    (PROPS + 'stone_bench.tscn', 'BenchWestA', (18, 5), 2, 1, 'Props'),
    (PROPS + 'stone_bench.tscn', 'BenchWestB', (20, 6), 2, 1, 'Props'),
    (PROPS + 'stone_bench.tscn', 'BenchEastA', (24, 3), 2, 1, 'Props'),
    (PROPS + 'stone_bench.tscn', 'BenchEastB', (26, 7), 2, 1, 'Props'),
    (PROPS + 'lantern_post_gold.tscn', 'LanternGoldA', (17, 0), 1, 1, 'Props'),
    (PROPS + 'lantern_post_gold.tscn', 'LanternGoldB', (21, 0), 1, 1, 'Props'),
    (PROPS + 'lantern_post_gold.tscn', 'LanternGoldC', (17, 2), 1, 1, 'Props'),
    (PROPS + 'lantern_post_gold.tscn', 'LanternGoldD', (22, 1), 1, 1, 'Props'),
    (PROPS + 'lantern_post_gold.tscn', 'LanternGoldE', (19, 4), 1, 1, 'Props'),
    (PROPS + 'lantern_post_gold.tscn', 'LanternGoldF', (24, 9), 1, 1, 'Props'),
    (PROPS + 'lantern_post_arcane.tscn', 'LanternArcaneA', (21, 6), 1, 1, 'Props'),
    (PROPS + 'lantern_post_arcane.tscn', 'LanternArcaneB', (28, 2), 1, 1, 'Props'),
    (PROPS + 'lantern_post_arcane.tscn', 'LanternArcaneC', (26, 3), 1, 1, 'Props'),
    (PROPS + 'guardian_statue.tscn', 'StatueWest', (16, 0), 1, 1, 'Props'),
    (PROPS + 'guardian_statue.tscn', 'StatueEast', (21, -1), 1, 1, 'Props'),
]

# Static markers (screen positions already on the lattice).
NPC_MARKERS = [
    ('GuardLeft', (17, 0)),
    ('GuardRight', (21, 0)),
    ('Gardener', (20, 8)),
    ('Visitor', (28, 0)),
]
SPAWN_MARKERS = [
    ('PlayerSpawn', (640, 620)),
    ('GardenEntrySpawn', (640, 520)),
]

POND_TILE_SCENE = WATER + 'water_tile_anim.tscn'
MOTE_SCENE = EFFECTS + 'magic_motes.tscn'
SHAFT_SCENE = EFFECTS + 'light_shaft.tscn'
GROUND_SCENE = TERRAIN + 'castle_ground.tscn'


# --------------------------------------------------------------- validation ---


def is_path_cell(cell):
    gx, gy = cell
    diff = gx - gy
    total = gx + gy
    if diff == SPINE_DIFF and 18 <= total <= 38:
        return True
    if total in CROSS_SUMS and 12 <= diff <= 26:
        return True
    # Castle courtyard is paved.
    if 13 <= gx <= 21 and -7 <= gy <= -2:
        return True
    # Fountain plaza.
    if 18 <= diff <= 22 and 19 <= total <= 23:
        return True
    return False


def is_pond_cell(cell):
    return cell in POND_CELLS[0] or cell in POND_CELLS[1]


def in_castle(cell):
    gx, gy = cell
    return CASTLE_X[0] <= gx <= CASTLE_X[1] and CASTLE_Y[0] <= gy <= CASTLE_Y[1]


def validate():
    problems = []
    claimed = {}
    for scene, name, anchor, w, d, group in LAYOUT:
        for cell in cells_of(anchor, w, d):
            if cell in claimed:
                problems.append('%s overlaps %s at %s' % (name, claimed[cell], cell))
            claimed[cell] = name
            if is_path_cell(cell) and group != 'Castle':
                problems.append('%s sits on a path at %s' % (name, cell))
            if is_pond_cell(cell):
                problems.append('%s sits in a pond at %s' % (name, cell))
    for cell in POND_CELLS[0] + POND_CELLS[1]:
        if cell in claimed:
            problems.append('pond cell %s is claimed by %s' % (cell, claimed[cell]))
    for cell in FOUNTAIN_CELLS:
        if cell in claimed and 'Fountain' not in claimed[cell]:
            problems.append('fountain cell %s is claimed by %s' % (cell, claimed[cell]))
    for scene, name, anchor, w, d, group in LAYOUT:
        if group == 'Castle' and not in_castle(anchor):
            problems.append('%s is outside the castle enclosure' % name)
    return problems


# ------------------------------------------------------------------ output ---


def scene_paths():
    paths = []
    for entry in LAYOUT:
        if entry[0] not in paths:
            paths.append(entry[0])
    for extra in (GROUND_SCENE, POND_TILE_SCENE, MOTE_SCENE, SHAFT_SCENE):
        if extra not in paths:
            paths.append(extra)
    return paths


def build_scene():
    paths = scene_paths()
    ids = {p: '%d_scene' % (i + 2) for i, p in enumerate(paths)}
    lines = ['[gd_scene load_steps=%d format=3]' % (len(paths) + 2), '']
    lines.append('[ext_resource type="Script" path="res://scripts/world/castle_gardens/castle_royal_gardens.gd" id="1_script"]')
    for p in paths:
        lines.append('[ext_resource type="PackedScene" path="%s" id="%s"]' % (p, ids[p]))
    lines.append('')
    lines.append('[node name="CastleRoyalGardens" type="Node2D"]')
    lines.append('y_sort_enabled = true')
    lines.append('script = ExtResource("1_script")')
    lines.append('')

    def group(name, comment):
        lines.append('[node name="%s" type="Node2D" parent="."]' % name)
        lines.append('y_sort_enabled = true')
        lines.append('')
        if comment:
            lines.append('')

    lines.append('[node name="Terrain" type="Node2D" parent="."]')
    lines.append('z_index = -20')
    lines.append('')
    lines.append('[node name="Ground" parent="Terrain" instance=ExtResource("%s")]' % ids[GROUND_SCENE])
    lines.append('')

    group('Castle', '')
    for scene, name, anchor, w, d, grp in LAYOUT:
        if grp != 'Castle':
            continue
        x, y = footprint_center(anchor, w, d)
        lines.append('[node name="%s" parent="Castle" instance=ExtResource("%s")]' % (name, ids[scene]))
        lines.append('position = Vector2(%g, %g)' % (x, y))
        lines.append('')

    group('Water', '')
    for scene, name, anchor, w, d, grp in LAYOUT:
        if grp != 'Water':
            continue
        x, y = footprint_center(anchor, w, d)
        lines.append('[node name="%s" parent="Water" instance=ExtResource("%s")]' % (name, ids[scene]))
        lines.append('position = Vector2(%g, %g)' % (x, y))
        lines.append('')
    for side, cells in enumerate(POND_CELLS):
        for i, cell in enumerate(cells):
            x, y = grid_to_world(*cell)
            lines.append('[node name="Pond%sTile%d" parent="Water" instance=ExtResource("%s")]'
                         % ('Left' if side == 0 else 'Right', i, ids[POND_TILE_SCENE]))
            lines.append('position = Vector2(%g, %g)' % (x, y))
            lines.append('')

    group('Flora', '')
    for scene, name, anchor, w, d, grp in LAYOUT:
        if grp != 'Flora':
            continue
        x, y = footprint_center(anchor, w, d)
        lines.append('[node name="%s" parent="Flora" instance=ExtResource("%s")]' % (name, ids[scene]))
        lines.append('position = Vector2(%g, %g)' % (x, y))
        lines.append('')

    group('Props', '')
    for scene, name, anchor, w, d, grp in LAYOUT:
        if grp != 'Props':
            continue
        x, y = footprint_center(anchor, w, d)
        lines.append('[node name="%s" parent="Props" instance=ExtResource("%s")]' % (name, ids[scene]))
        lines.append('position = Vector2(%g, %g)' % (x, y))
        lines.append('')

    group('Effects', '')
    for i, cell in enumerate([(21, 5), (26, 8)]):
        x, y = grid_to_world(*cell)
        lines.append('[node name="Motes%d" parent="Effects" instance=ExtResource("%s")]' % (i, ids[MOTE_SCENE]))
        lines.append('position = Vector2(%g, %g)' % (x, y))
        lines.append('')
    for i, cell in enumerate([(17, -1), (23, -4)]):
        x, y = grid_to_world(*cell)
        lines.append('[node name="LightShaft%d" parent="Effects" instance=ExtResource("%s")]' % (i, ids[SHAFT_SCENE]))
        lines.append('position = Vector2(%g, %g)' % (x, y))
        lines.append('')

    lines.append('[node name="Entities" type="Node2D" parent="."]')
    lines.append('y_sort_enabled = true')
    lines.append('')

    lines.append('[node name="NPCPlacement" type="Node2D" parent="."]')
    lines.append('')
    for name, cell in NPC_MARKERS:
        x, y = grid_to_world(*cell)
        lines.append('[node name="%s" type="Marker2D" parent="NPCPlacement"]' % name)
        lines.append('position = Vector2(%g, %g)' % (x, y))
        lines.append('')

    lines.append('[node name="MapSpawnPoints" type="Node2D" parent="."]')
    lines.append('')
    for name, pos in SPAWN_MARKERS:
        lines.append('[node name="%s" type="Marker2D" parent="MapSpawnPoints"]' % name)
        lines.append('position = Vector2(%g, %g)' % pos)
        lines.append('')

    lines.append('[node name="Bounds" type="StaticBody2D" parent="."]')
    lines.append('')
    lines.append('[node name="Left" type="CollisionShape2D" parent="Bounds"]')
    lines.append('position = Vector2(48, 400)')
    lines.append('')
    lines.append('[node name="Right" type="CollisionShape2D" parent="Bounds"]')
    lines.append('position = Vector2(1232, 400)')
    lines.append('')
    lines.append('[node name="Top" type="CollisionShape2D" parent="Bounds"]')
    lines.append('position = Vector2(640, 48)')
    lines.append('')
    lines.append('[node name="Bottom" type="CollisionShape2D" parent="Bounds"]')
    lines.append('position = Vector2(640, 752)')
    lines.append('')
    return lines


if __name__ == '__main__':
    problems = validate()
    if problems:
        print('LAYOUT PROBLEMS:')
        for p in problems:
            print('  -', p)
    else:
        print('layout ok')
    lines = build_scene()
    out = ROOT / 'scenes/world/castle_royal_gardens.tscn'
    out.write_text('\n'.join(lines) + '\n', encoding='utf-8', newline='\n')
    print('wrote', out)
