"""Generate reusable modular Godot piece scenes for the delivered REVERIE pack.

One-off authoring helper. It reads assets/reverie_pack_v01/manifest.json and
writes one editable .tscn per asset under scenes/world/reverie_pack/. Every
sprite keeps the pack pivot and footprint; nothing is flattened.
"""
import json
from pathlib import Path

ROOT = Path('.')
MANIFEST = json.loads((ROOT / 'assets/reverie_pack_v01/manifest.json').read_text(encoding='utf-8'))
ASSETS = MANIFEST['assets']

PIECE_SCRIPT = 'res://scripts/world/reverie_pack/reverie_piece.gd'
ANIM_SCRIPT = 'res://scripts/world/reverie_pack/reverie_animated_sprite.gd'
SHADOW_TEX = 'res://assets/castle_pack_v02/effects/shadow_blob_64.png'
GLOW_WARM = 'res://assets/castle_pack_v02/effects/glow_warm.png'
GLOW_COLD = 'res://assets/castle_pack_v02/effects/glow_cyan.png'
GLOW_PURPLE = 'res://assets/reverie_pack_v01/Corrupted_Environment/Effects/purple_glow_soft.png'


def cell_corners(i, j):
    cx, cy = (i - j) * 32.0, (i + j) * 16.0
    return [(cx, cy - 16), (cx + 32, cy), (cx, cy + 16), (cx - 32, cy)]


def hull(points):
    pts = sorted(set(points))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower = []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    upper = []
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def footprint_shape(w, d):
    corners = []
    for i in range(w):
        for j in range(d):
            corners.extend(cell_corners(i, j))
    ox, oy = (w - d) * 16.0, (w + d - 2) * 8.0
    return [(round(x - ox, 1), round(y - oy, 1)) for x, y in hull(corners)]


def poly(points):
    # Godot's .tscn parser wants a flat float list, not Vector2 constructors.
    return 'PackedVector2Array(' + ', '.join(
        '%.1f, %.1f' % (float(x), float(y)) for x, y in points) + ')'


def pascal(asset_id):
    parts = asset_id.split('_')
    return ''.join(p[:1].upper() + p[1:] for p in parts)


COLLIDE_KEYWORDS = (
    'wall', 'tower', 'pillar', 'column', 'buttress', 'arch', 'fence', 'railing',
    'statue', 'brazier', 'altar', 'crystal', 'growth', 'urn', 'planter',
    'hedge', 'bush', 'ruined', 'broken', 'rubble', 'gate', 'facade',
)
TREE_KEYWORDS = ('tree_', 'topiary')
NO_COLLIDE = ('floor', 'tile', 'path_', 'grass', 'soil', 'cracked_stone', 'mossy',
              'decorative_floor', 'edge', 'bridge', 'stairs', 'banner', 'flag',
              'torc', 'torch', 'sconce', 'lantern', 'lamp_', 'ivy', 'flower',
              'motes', 'glow', 'shaft', 'fog', 'pool', 'veins', 'roots', 'spray',
              'window', 'door', 'gargoyle', 'ornament', 'hanging', 'candle',
              'sigil', 'bench', 'seat')


def light_for(asset_id):
    if any(k in asset_id for k in ('lamp_post_gold', 'torch_wall_warm', 'brazier_01',
                                    'wall_sconce', 'candle_stand_01', 'lantern_gothic')):
        return GLOW_WARM, (232, 190, 92, 255), 0.75
    if any(k in asset_id for k in ('lamp_post_arcane', 'torch_wall_cold')):
        return GLOW_COLD, (90, 230, 240, 255), 0.75
    if any(k in asset_id for k in ('brazier_boss', 'corrupted_brazier', 'dark_crystal')):
        return GLOW_PURPLE, (196, 110, 240, 255), 1.1
    return None


def build_scene(a):
    aid = a['id']
    cat, sub = a['category'], a['subfolder']
    frames = a['frames'][0]
    w, d = (int(v) for v in a['footprint_cells'].split('x'))
    is_tile = sub in ('Terrain', 'Ground', 'Flooring') or 'tile' in aid
    is_effect = sub == 'Effects'
    px, py = a['pivot_px']

    ext = [('Script', '1_script', PIECE_SCRIPT),
           ('Texture2D', '2_tex', 'res://assets/reverie_pack_v01/' + a['file'])]
    next_id = 3
    shadow = not (is_tile or is_effect or any(k in aid for k in ('banner', 'flag', 'window', 'door', 'ivy', 'motes', 'glow', 'shaft', 'fog')))
    if shadow:
        ext.append(('Texture2D', '%d_shadow' % next_id, SHADOW_TEX))
        shadow_id = next_id
        next_id += 1
    light = light_for(aid)
    if light:
        ext.append(('Texture2D', '%d_glow' % next_id, light[0]))
        glow_id = next_id
        next_id += 1
    if frames > 1:
        ext.append(('Script', '%d_anim' % next_id, ANIM_SCRIPT))
        anim_id = next_id
        next_id += 1

    makes_collision = (not is_tile and not is_effect and not any(k in aid for k in NO_COLLIDE)
                       and any(k in aid for k in COLLIDE_KEYWORDS))
    tree_collision = (not is_effect and any(k in aid for k in TREE_KEYWORDS)
                      and any(k in aid for k in ('tree_', 'topiary')))

    subs = []
    if makes_collision:
        subs.append(('ConvexPolygonShape2D', 'Shape_footprint',
                     'points = %s' % poly(footprint_shape(w, d))))
    elif tree_collision:
        subs.append(('CircleShape2D', 'Shape_trunk', 'radius = 9.0'))

    lines = ['[gd_scene load_steps=%d format=3]' % (len(ext) + len(subs) + 1), '']
    for kind, rid, path in ext:
        lines.append('[ext_resource type="%s" path="%s" id="%s"]' % (kind, path, rid))
    lines.append('')
    for kind, sid, body in subs:
        lines.append('[sub_resource type="%s" id="%s"]' % (kind, sid))
        lines.append(body)
        lines.append('')
    lines.append('[node name="%s" type="Node2D"]' % pascal(aid))
    lines.append('y_sort_enabled = %s' % ('false' if is_tile or is_effect else 'true'))
    lines.append('script = ExtResource("1_script")')
    lines.append('asset_id = "%s"' % aid)
    lines.append('footprint_cells = Vector2i(%d, %d)' % (w, d))
    lines.append('')
    if shadow:
        lines += ['[node name="ContactShadow" type="Sprite2D" parent="."]',
                  'texture_filter = 1', 'z_index = -1', 'centered = false',
                  'offset = Vector2(-32, -16)', 'modulate = Color(1, 1, 1, 0.32)',
                  'texture = ExtResource("%d_shadow")' % shadow_id, '']
    sprite_extra = []
    if frames > 1:
        sprite_extra += ['hframes = %d' % frames, 'vframes = 1']
        if aid == 'corruption_motes_anim':
            sprite_extra.append('script = ExtResource("%d_anim")' % anim_id)
    lines += ['[node name="Sprite" type="Sprite2D" parent="."]', 'texture_filter = 1',
              'centered = false', 'offset = Vector2(%d, %d)' % (px, py)]
    lines += sprite_extra
    lines.append('texture = ExtResource("2_tex")')
    lines.append('')
    if makes_collision or tree_collision:
        lines += ['[node name="Body" type="StaticBody2D" parent="."]',
                  'collision_layer = 1', 'collision_mask = 0', '',
                  '[node name="Footprint" type="CollisionShape2D" parent="Body"]',
                  'shape = SubResource("%s")' % ('Shape_footprint' if makes_collision else 'Shape_trunk'), '']
    if light:
        lines += ['[node name="Light" type="PointLight2D" parent="."]',
                  'position = Vector2(0, -40)',
                  'texture = ExtResource("%d_glow")' % glow_id,
                  'texture_scale = 0.8',
                  'energy = %g' % light[2],
                  'modulate = Color(%g, %g, %g, 1)' % (light[1][0] / 255, light[1][1] / 255, light[1][2] / 255), '']
    return lines


count = 0
for a in ASSETS:
    lines = build_scene(a)
    path = ROOT / ('scenes/world/reverie_pack/%s/%s/%s.tscn' % (a['category'], a['subfolder'], a['id']))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('\n'.join(lines) + '\n', encoding='utf-8', newline='\n')
    count += 1
print('generated', count, 'piece scenes')
