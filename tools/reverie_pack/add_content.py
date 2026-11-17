"""Add the Royal Gardens expansion / Gothic Castle boss-zone content data.

Idempotent: re-running updates the same IDs in place. Backs up each JSON once.
"""
import json
import shutil
from pathlib import Path

DATA = Path('resources/data')


def load(name):
    return json.loads((DATA / name).read_text(encoding='utf-8'))


def save(name, data):
    path = DATA / name
    if not path.with_suffix('.json.pre_reverie_expansion.bak').exists():
        shutil.copyfile(path, path.with_suffix('.json.pre_reverie_expansion.bak'))
    path.write_text(json.dumps(data, indent=1, ensure_ascii=False) + '\n', encoding='utf-8')
    print('updated', name)


# ------------------------------------------------------------------ regions --
regions = load('regions.json')
regions['castle_royal_gardens'].setdefault('entry_points', {})['boss_path'] = [32, 16]
castle_pois = regions['castle_royal_gardens'].setdefault('pois', [])
if not any(p.get('id') == 'boss_path_gate' for p in castle_pois):
    castle_pois.append({'id': 'boss_path_gate', 'name': 'Royal Road Gate',
                        'grid': [32, 16], 'type': 'landmark'})
castle_conn = regions['castle_royal_gardens'].setdefault('connections', [])
if not any(c.get('id') == 'boss_path_gate' for c in castle_conn):
    castle_conn.append({'id': 'boss_path_gate', 'to': 'gothic_castle_boss_zone',
                        'via': 'boss_path', 'entry': 'royal_gate', 'kind': 'gate',
                        'label': 'Road to the Gothic Castle'})

regions['gothic_castle_boss_zone'] = {
    'name': 'Gothic Castle & Baltoria Arena',
    'subtitle': 'A corrupted royal road ending at the Hollow Sovereign\'s throne',
    'chunk_size': 16, 'tile_width': 64, 'tile_height': 32, 'load_radius': 1,
    'noise_seed': 424242, 'spawn_grid': [0, 0], 'clearing_radius': 7,
    'world_origin': [8192.0, 0.0],
    'biome': {
        'water_level': -0.4, 'deep_water_level': -0.52,
        'grass_colors': ['#243e44', '#3a5c55', '#4a6d5e', '#5e516e', '#3c3052'],
        'path_color': '#8d839c', 'water_shallow': '#5e5288', 'water_deep': '#241d40',
    },
    'props': [
        {'type': 'dead_tree', 'weight': 4, 'min_elevation': -0.1},
        {'type': 'ruin_pillar', 'weight': 3, 'min_elevation': -0.1},
        {'type': 'crystal', 'weight': 2, 'min_elevation': -0.1},
        {'type': 'flower', 'weight': 1, 'min_elevation': -0.1},
    ],
    'pois': [
        {'id': 'royal_gate', 'name': 'Royal Road Gate', 'grid': [0, 0], 'type': 'landmark'},
        {'id': 'road_warden', 'name': 'Road Warden Elowen', 'grid': [2, 2], 'type': 'npc'},
        {'id': 'blossom_hollow', 'name': 'Blossom Hollow', 'grid': [18, -10], 'type': 'landmark'},
        {'id': 'withered_grove', 'name': 'Withered Grove', 'grid': [38, 18], 'type': 'ruin'},
        {'id': 'fallen_aqueduct', 'name': 'Fallen Aqueduct', 'grid': [52, -14], 'type': 'ruin'},
        {'id': 'gothic_castle', 'name': 'The Sealed Gothic Castle', 'grid': [22, -12], 'type': 'landmark'},
        {'id': 'blight_warden', 'name': 'Warden Corvin', 'grid': [30, 14], 'type': 'npc'},
        {'id': 'arena_gatekeeper', 'name': 'Gatekeeper Sable', 'grid': [58, 2], 'type': 'npc'},
        {'id': 'arena_gate', 'name': 'Arena Gate', 'grid': [60, 4], 'type': 'boss'},
        {'id': 'baltoria_throne', 'name': 'Throne of Baltoria', 'grid': [63, 4], 'type': 'boss'},
    ],
    'spawns': [
        {'group': 'royal_road_ambush', 'grid': [12, 0], 'radius': 2, 'count': 1},
        {'group': 'withered_grove_pack', 'grid': [38, 18], 'radius': 2, 'count': 1},
        {'group': 'fallen_aqueduct_sentinels', 'grid': [52, -14], 'radius': 2, 'count': 1},
        {'group': 'baltoria_encounter', 'grid': [63, 4], 'radius': 1, 'count': 1},
    ],
    'environment': {
        'zone': 'gothic_ruins', 'weather_bias': ['mist', 'clear'],
        'fog_density': 0.34, 'ambient_tint': '#b9a2ff', 'ambient_music': '',
    },
    'entry_points': {'royal_gate': [0, 0], 'arena_gate': [60, 4]},
    'connections': [
        {'id': 'royal_gardens_return', 'to': 'castle_royal_gardens',
         'via': 'royal_gate', 'entry': 'boss_path', 'kind': 'gate',
         'label': 'Return to the Royal Gardens'},
    ],
    'standalone': True,
    'map_bounds': {'min': [-400, -320], 'max': [3200, 1600]},
}
save('regions.json', regions)

# ------------------------------------------------------------------- items --
items = load('items.json')
items.update({
    'gothic_shard': {'name': 'Gothic Shard', 'category': 'material', 'rarity': 'rare',
                     'description': 'A splinter of the sealed castle masonry, humming with violet light.',
                     'color': '#b49cff'},
    'blight_resin': {'name': 'Blight Resin', 'category': 'material', 'rarity': 'rare',
                     'description': 'Bitter amber wept by corrupted trees. Reagent for wardens of the road.',
                     'color': '#c060d8'},
    'royal_seal': {'name': 'Royal Seal', 'category': 'material', 'rarity': 'epic',
                   'description': 'A gold seal bearing the royal gardens crest, still warm to the touch.',
                   'color': '#e8be5c'},
})
save('items.json', items)

# ------------------------------------------------------------------ enemies --
enemies = load('enemies.json')
enemies.update({
    'gothic_sentinel': {
        'name': 'Gothic Sentinel', 'element': 'dark', 'rarity': 'epic', 'role': 'Elite',
        'base': {'hp': 420, 'atk': 24, 'def': 18, 'spd': 13, 'crit': 0.1, 'crit_dmg': 1.5},
        'skills': ['shadow_lash', 'shield_bash', 'hollow_wail'],
        'lore': 'Stone armour animated by the castle seal, still guarding a road nobody walks.',
        'palette': {'primary': '#3a3558', 'secondary': '#8f96c4', 'accent': '#c4a2ff'},
    },
    'blight_wisp': {
        'name': 'Blight Wisp', 'element': 'dark', 'rarity': 'rare',
        'base': {'hp': 180, 'atk': 16, 'def': 8, 'spd': 19, 'crit': 0.14},
        'skills': ['corruption_bolt', 'lunar_wisp'],
        'lore': 'A drifting mote of the corruption that creeps along the royal road.',
        'palette': {'primary': '#3c2058', 'secondary': '#9b5fd0', 'accent': '#e0b0ff'},
    },
    'baltoria': {
        'name': 'Baltoria, the Hollow Sovereign', 'element': 'dark', 'rarity': 'mythic',
        'role': 'Boss',
        'base': {'hp': 1800, 'atk': 38, 'def': 24, 'spd': 17, 'crit': 0.16, 'crit_dmg': 1.9},
        'skills': ['corruption_bolt', 'shadow_lash', 'soul_drain', 'hollow_wail'],
        'ultimate': 'matron_verdict',
        'phases': [
            {'hp_below': 0.66, 'message': 'Baltoria rises: "The garden was always mine."',
             'status': {'id': 'atk_up', 'turns': 99, 'potency': 0.28}},
            {'hp_below': 0.33, 'message': 'The throne cracks. Violet light floods the arena.',
             'status': {'id': 'spd_up', 'turns': 99, 'potency': 0.35}},
        ],
        'lore': 'The sovereign who claimed the ruined castle and turned its gardens to ash.',
        'palette': {'hair': '#d8cbe8', 'skin': '#c8b4d8', 'primary': '#26143c',
                    'secondary': '#7c4a9c', 'accent': '#e08cff'},
    },
})
save('enemies.json', enemies)

# ------------------------------------------------------------- enemy groups --
groups = load('enemy_groups.json')
groups.update({
    'royal_road_ambush': {
        'name': 'Roadside Ambush', 'region': 'gothic_castle_boss_zone', 'level': 4,
        'enemies': ['mossling', 'mossling', 'glade_wisp'],
        'rewards': {'gold': 120, 'xp': 180, 'crystals': 25, 'items': {'glade_sap': 2}},
        'quest_kills': {'mossling': 2},
        'drops': [{'item': 'glade_sap', 'chance': 0.6, 'min': 1, 'max': 2}],
    },
    'withered_grove_pack': {
        'name': 'Warden of the Withered Grove', 'region': 'gothic_castle_boss_zone', 'level': 5,
        'enemies': ['thornhound', 'thornhound', 'blight_wisp'],
        'rewards': {'gold': 180, 'xp': 260, 'crystals': 35, 'items': {'blight_resin': 2}},
        'quest_kills': {'thornhound': 2, 'blight_wisp': 1},
        'drops': [{'item': 'blight_resin', 'chance': 0.55, 'min': 1, 'max': 2}],
    },
    'fallen_aqueduct_sentinels': {
        'name': 'Aqueduct Sentinels', 'region': 'gothic_castle_boss_zone', 'level': 6,
        'enemies': ['gothic_sentinel', 'gothic_sentinel', 'blight_wisp'],
        'rewards': {'gold': 260, 'xp': 360, 'crystals': 50, 'items': {'gothic_shard': 2}},
        'quest_kills': {'gothic_sentinel': 2},
        'drops': [{'item': 'gothic_shard', 'chance': 0.5, 'min': 1, 'max': 2}],
    },
    'baltoria_encounter': {
        'name': 'Baltoria, the Hollow Sovereign', 'region': 'gothic_castle_boss_zone',
        'level': 10, 'boss': True, 'enemies': ['baltoria'],
        'rewards': {'gold': 2000, 'xp': 3000, 'crystals': 400,
                    'items': {'ancient_coins': 5, 'gothic_shard': 4}},
        'quest_kills': {'baltoria': 1},
    },
})
save('enemy_groups.json', groups)

# ------------------------------------------------------------------- quests --
quests = load('quests.json')
quests.update({
    'royal_road_supplies': {
        'name': 'Supplies for the Royal Road', 'region': 'gothic_castle_boss_zone',
        'summary': 'Warden Elowen needs the road cleared before the caravans can pass.',
        'steps': [
            {'type': 'talk', 'target': 'road_warden', 'grid': [2, 2], 'text': 'Speak with Warden Elowen'},
            {'type': 'kill', 'target': 'mossling', 'count': 2, 'grid': [12, 0], 'text': 'Clear two mosslings from the road'},
            {'type': 'talk', 'target': 'road_warden', 'grid': [2, 2], 'text': 'Report back to Warden Elowen'},
        ],
        'rewards': {'gold': 400, 'xp': 300, 'crystals': 60,
                    'items': {'glade_sap': 3, 'royal_seal': 1}},
    },
    'blight_purification': {
        'name': 'The Blight at the Grove', 'region': 'gothic_castle_boss_zone',
        'requires': 'royal_road_supplies',
        'summary': 'Corvin cannot open the castle road while the withered grote festers.',
        'steps': [
            {'type': 'talk', 'target': 'blight_warden', 'grid': [30, 14], 'text': 'Speak with Warden Corvin'},
            {'type': 'kill', 'target': 'thornhound', 'count': 2, 'grid': [38, 18], 'text': 'Drive off the thornhounds'},
            {'type': 'talk', 'target': 'blight_warden', 'grid': [30, 14], 'text': 'Report back to Warden Corvin'},
        ],
        'rewards': {'gold': 600, 'xp': 500, 'crystals': 90, 'items': {'blight_resin': 3}},
    },
    'baltoria_summoning': {
        'name': 'The Hollow Sovereign', 'region': 'gothic_castle_boss_zone',
        'requires': 'blight_purification',
        'summary': 'Break the seal at the arena and face Baltoria on the throne.',
        'steps': [
            {'type': 'talk', 'target': 'arena_gatekeeper', 'grid': [58, 2], 'text': 'Speak with Gatekeeper Sable'},
            {'type': 'kill', 'target': 'baltoria', 'count': 1, 'grid': [63, 4], 'text': 'Defeat Baltoria'},
            {'type': 'talk', 'target': 'arena_gatekeeper', 'grid': [58, 2], 'text': 'Return to Sable with the news'},
        ],
        'rewards': {'gold': 2500, 'xp': 3500, 'crystals': 500,
                    'items': {'ancient_coins': 6, 'gothic_shard': 5}},
    },
})
save('quests.json', quests)

# ----------------------------------------------------------------- dialogue --
dialogue = load('dialogue.json')


def warden_dialogue(dialogue_id, speaker, quest_id, intro, progress, after, palette):
    return {
        'start': 'greet',
        'start_rules': [
            {'if': 'quest_ready:%s' % quest_id, 'node': 'turnin'},
            {'if': 'quest_state:%s:active' % quest_id, 'node': 'active'},
            {'if': 'quest_state:%s:complete' % quest_id, 'node': 'after'},
        ],
        'nodes': {
            'greet': {'speaker': speaker, 'portrait': palette, 'text': intro,
                      'choices': [{'text': 'I can help.', 'next': 'accepted',
                                   'action': 'start_quest:%s' % quest_id},
                                  {'text': 'Another time.', 'next': ''}]},
            'accepted': {'speaker': speaker, 'portrait': palette,
                         'text': 'The road ahead will tell you what needs doing. Return when it is quiet.',
                         'choices': [{'text': 'Understood.', 'next': ''}]},
            'active': {'speaker': speaker, 'portrait': palette, 'text': progress,
                       'choices': [{'text': 'I am on it.', 'next': ''}]},
            'turnin': {'speaker': speaker, 'portrait': palette, 'text': 'You made the road safe. Take this, and go onward.',
                       'choices': [{'text': 'Thank you.', 'next': 'done',
                                    'action': 'complete_quest:%s' % quest_id}]},
            'done': {'speaker': speaker, 'portrait': palette,
                     'text': 'The castle gate stands ahead. May you not need what waits inside.',
                     'choices': [{'text': 'Farewell.', 'next': ''}]},
            'after': {'speaker': speaker, 'portrait': palette, 'text': after,
                      'choices': [{'text': 'Farewell.', 'next': ''}]},
        },
    }


PAL = {'hair': '#d8c0a0', 'primary': '#4c5a70', 'secondary': '#c8a860',
       'accent': '#9df5cf', 'skin': '#e8c8a8'}
dialogue.update({
    'road_warden': warden_dialogue('road_warden', 'Road Warden Elowen',
                                   'royal_road_supplies',
                                   'The royal road is overrun. Clear the mosslings before the next caravan arrives.',
                                   'The mosslings still block the road. Two will be enough.',
                                   'The road is quiet now, but corruption gathers further east.', PAL),
    'blight_warden': warden_dialogue('blight_warden', 'Warden Corvin',
                                     'blight_purification',
                                     'Thornhounds have claimed the grove. Drive them off and I can break the blight seal.',
                                     'The thornhounds still roam the grove. Two must fall.',
                                     'The grove breathes again. Speak to Sable at the arena gate.', PAL),
    'arena_gatekeeper': {
        'start': 'locked',
        'start_rules': [
            {'if': 'quest_state:baltoria_summoning:complete', 'node': 'victory'},
            {'if': 'quest_ready:baltoria_summoning', 'node': 'turnin'},
            {'if': 'quest_state:baltoria_summoning:active', 'node': 'active'},
            {'if': 'quest_state:blight_purification:complete', 'node': 'greet'},
        ],
        'nodes': {
            'locked': {'speaker': 'Gatekeeper Sable', 'portrait': PAL,
                       'text': 'The arena seal holds. Clear the withered grove and return when the castle road is open.',
                       'choices': [{'text': 'I will return.', 'next': ''}]},
            'greet': {'speaker': 'Gatekeeper Sable', 'portrait': PAL,
                      'text': 'The seal is yours to break. Beyond it waits Baltoria. Few return from that throne.',
                      'choices': [
                          {'text': 'Break the seal. I will face Baltoria.', 'next': 'accepted',
                           'action': 'start_quest:baltoria_summoning'},
                          {'text': 'Not yet.', 'next': ''},
                      ]},
            'accepted': {'speaker': 'Gatekeeper Sable', 'portrait': PAL,
                         'text': 'The seal is broken. The sovereign has noticed you.',
                         'choices': [{'text': 'Then let it come.', 'next': '',
                                      'action': 'set_flag:baltoria_seal_broken:true'}]},
            'active': {'speaker': 'Gatekeeper Sable', 'portrait': PAL,
                       'text': 'Baltoria waits on the throne. Strike when you are ready.',
                       'choices': [{'text': 'I will.', 'next': ''}]},
            'turnin': {'speaker': 'Gatekeeper Sable', 'portrait': PAL,
                       'text': 'The throne is silent. Reverie owes you a debt.',
                       'choices': [{'text': 'It is done.', 'next': 'victory',
                                    'action': 'complete_quest:baltoria_summoning'}]},
            'victory': {'speaker': 'Gatekeeper Sable', 'portrait': PAL,
                        'text': 'The castle will keep its secrets a little longer. Travel well.',
                        'choices': [{'text': 'Farewell.', 'next': ''}]},
        },
    },
})
save('dialogue.json', dialogue)
print('content data complete')



