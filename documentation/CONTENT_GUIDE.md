# Content Guide

Everything in PROJECT FANTASY that a designer would tune lives in `resources/data/*.json`. Gameplay code reads those files at boot through the `ContentDB` autoload; no content is compiled into scripts.

> **Rule:** if a number, name, line of dialogue or drop table is likely to change during balancing, it belongs in JSON — not in GDScript.

This guide documents the current schema, the exact runtime behaviour behind each field, and the workflow for adding content safely.

---

## 1. Files at a glance

| File | Shape | Loaded as | What it defines |
| --- | --- | --- | --- |
| `characters.json` | dictionary keyed by `character_id` | `CharacterDef` objects | Playable characters, stats, kits, palettes |
| `skills.json` | dictionary keyed by `skill_id` | `SkillDef` objects | Active skills, ultimates, enemy abilities |
| `enemies.json` | dictionary keyed by `enemy_id` | dictionaries | Enemy stats, kits, boss phases |
| `enemy_groups.json` | dictionary keyed by `group_id` | dictionaries | Encounter composition, rewards, boss flags |
| `items.json` | dictionary keyed by `item_id` | dictionaries | Currencies, materials, equipment |
| `banners.json` | dictionary keyed by `banner_id` | dictionaries | Summon pools, rates, pity, costs |
| `quests.json` | dictionary keyed by `quest_id` | dictionaries | Quest steps, prerequisites, rewards |
| `dialogue.json` | dictionary keyed by `dialogue_id` | dictionaries | NPC conversation graphs |
| `regions.json` | dictionary keyed by `region_id` | dictionaries | World generation, props, POIs, spawns; Phase 4 adds `world_origin`, `environment`, `entry_points`, `connections` (exactly TWO regions) |

All files are UTF-8 JSON objects at the top level. Keys are the stable IDs used everywhere else: saves, quests, banners, spawn tables and dialogue actions all reference these strings.

### Conventions

- IDs are `snake_case` and never change once shipped. Renaming an ID breaks saves, quests and references.
- Display text may contain any Unicode, but keep the files UTF-8 without BOM.
- No comments in JSON. Put explanations in this guide or in a `description`/`lore` field.
- Unknown extra fields are ignored by the loaders, so you can add authoring metadata without breaking the game.
- Arrays are ordered. The first enemy in a group is the one used for the roaming-monster visual; skill order is the order shown in combat.

---

## 2. Boot validation

`ContentDB` loads every file in `_ready()` and delegates validation to the strict, data-only `ContentValidator` (`scripts/core/content_validator.gd`). It scans all nine JSON files, appends human-readable problems to `validation_errors`, and prints one `push_error` per problem; a non-empty array fails the test suite. The *same* validator runs at boot, in the headless test suite and in CI through `tools/validate_content.gd`, so the three can never disagree. Errors are formatted `file → path: message`.

### What the strict validator checks

- **Structure and parsing:** every file exists, is valid JSON, is a top-level object, and has **no duplicate keys**. `_scan_duplicate_keys()` walks the raw text, so two identical IDs are caught even though `JSON.parse_string` would silently keep only the last. Duplicate-ID errors look like `characters.json → (root): duplicate key 'lyra_vey'`.
- **Required fields and types:** every document's required fields exist with the correct type (`_require`, `_require_int`, `_require_number`, `_require_enum`, `_require_bool`). Godot's JSON parser returns *all* numbers as floats, so integer fields accept integral floats but reject `1.5`.
- **Enums:** `element` (7 values), `rarity` (`common` / `rare` / `epic` / `legendary` / `mythic`), skill `kind` and `target`, status `id`, item `category`, equipment `slot` / `stat`, quest step `type`, banner `type`, prop `type`, and quest states.
- **Reference integrity:** character `skills` / `ultimate` → skills; enemy `skills` / `ultimate` → skills; enemy-group `enemies` → enemies and `region` → regions; banner `pool` / `featured` → characters and `cost.currency` → a currency item; quest `region` / `requires` / `steps[].target` → regions / quests / dialogues or enemies; quest and enemy-group `rewards.items` → items; dialogue `start` / `next` / rule `node` / actions (`add_item`, `add_currency`, `start_quest`, `complete_quest`, …); region `spawns[].group` → enemy groups.
- **Ranges and invariants:** stats and `crit` (0–1), status `chance` / `turns` / `potency`, `power > 0` for damage/heal/shield skills, buff skills must apply a status, banner `rates` between 0 and 1 and summing to 1.0 (±0.02), positive integers for `hard_pity` / `featured_pity` / `level` / counts, `featured_pity >= hard_pity`, ten-pull cost ≤ ten singles, equipment `stats` keys from the supported set.
- **Phase 4 region checks:** strict validation of the new optional region fields `world_origin` (exactly two numbers), `environment` (`zone`, `weather_bias` from `clear/mist/rain/pollen_bloom`, `fog_density`, `ambient_tint`, `ambient_music`), `entry_points` (named grid pairs) and `connections` — missing target region, self-loop, dangling `via`/`entry`, duplicate connection ids, invalid `kind`/`label` and cross-region reference integrity — plus `static validate_region_graph(regions)`, a BFS unreachable-region check. `PROP_TYPES` now lists all **57** prop kinds (12 original + 35 Phase-3 + 6 Phase-4 building/landmark + 4 Phase-5: `birch_grove`, `moon_lantern`, `stone_path`, `village_gate`), so unknown `props[].type` values are rejected.

### Running the validator standalone

```powershell
godot --headless --path . --script res://tools/validate_content.gd
```

It exits `0` and prints `[validate] OK — 9 content files parsed and validated.` on success, or exits `1` and lists every error. It needs no running scene, so it is the fastest check after any content edit. Use the checklist in section 13 before committing.

---

## 3. Editing workflow

1. Edit the JSON file.
2. Run the game or the headless smoke test and watch the console:
   ```powershell
   godot --headless --path . --quit-after 120
   ```
   A clean boot prints `[ContentDB] Loaded 12 characters, 36 skills, 6 enemies, 14 items.`
3. Run the suite:
   ```powershell
   godot --headless --path . res://tests/test_runner.tscn
   ```
4. If you changed a save-relevant ID or structure, also test with an existing save and with a deleted save.

For a fast, scene-free strict check after any edit, run the standalone validator from section 2:

```powershell
godot --headless --path . --script res://tools/validate_content.gd
```

For quick iteration, Godot reloads scripts but **not** JSON already held in memory. Restart the running game after editing content.

---

## 4. Characters — `characters.json`

```json
"lyra_vey": {
  "name": "Lyra Vey",
  "title": "Warden of the Whispering Glade",
  "race": "Elf",
  "element": "wind",
  "rarity": "epic",
  "role": "Ranged Support",
  "base": { "hp": 980, "atk": 74, "def": 42, "spd": 62, "crit": 0.08 },
  "skills": ["gale_shot", "zephyr_blessing"],
  "ultimate": "tempest_dance",
  "passive": {
    "id": "whisperstep",
    "name": "Whisperstep",
    "text": "Allies gain 8% Speed while Lyra is alive."
  },
  "lore": "Last warden of a glade that no longer remembers her name...",
  "palette": {
    "hair": "#d8e8c8",
    "primary": "#2f6b4f",
    "secondary": "#c9a45a",
    "accent": "#9df5cf",
    "skin": "#f3d7c0"
  },
  "portrait_seed": 11
}
```

| Field | Type | Required | Runtime use |
| --- | --- | --- | --- |
| `name` | string | yes | Combat name, roster, dialogue-independent UI |
| `title` | string | no | Collection detail header |
| `race` | string | no | Portrait/actor silhouette selection |
| `element` | string | yes | Elemental multiplier in combat |
| `rarity` | string | yes | Banner pools, UI colour, validation |
| `role` | string | no | Display only |
| `base` | object | yes | `hp`, `atk`, `def`, `spd`, `crit` |
| `skills` | string array | yes | Active kit; convention is exactly two |
| `ultimate` | string | no | Third ability, unlocked by energy |
| `passive` | object | no | `id`, `name`, `text`; `id` must be a supported passive (see "Passives" below) |
| `lore` | string | no | Collection detail |
| `palette` | object | yes in practice | `hair`, `primary`, `secondary`, `accent`, `skin` |
| `portrait_seed` | integer | no | Stable procedural portrait variation |

### Stat scaling

Character instances scale at runtime in `CombatFactory`:

```text
power multiplier = (1 + 0.085 × (level − 1))
                 × (1 + 0.10 × ascension)
                 × (1 + 0.04 × awakening)
                 × collection bonus

hp/atk/def = base × power multiplier
spd        = base × (1 + 0.02 × (level − 1))
crit       = base crit (flat, not scaled)
```

Collection bonus is `1.0 + min(0.15, 0.01 × floor(unique_owned / 3))`. Equipment adds flat stats on top.

### Passives (Phase 2)

Every shipped character declares `passive.id`; the id must be one of the twelve supported values in `PassiveEffects.SUPPORTED_IDS` (`scripts/combat/passive_effects.gd`), otherwise boot validation rejects the file (`unknown passive '…'`). The combat engine owns the hooks; the collection screen shows `name` and `text`.

| `id` | Mechanical effect |
| --- | --- |
| `whisperstep` | +8% Speed for the whole team while the owner is alive (`unit_speed`, also affects turn order). |
| `rooted` | −10% incoming damage while the owner is below 50% HP (`incoming_multiplier`). |
| `deep_roots` | +15% Defense (`unit_defense`). Knockback does not exist in the turn-based slice. |
| `hold_the_line` | −6% incoming damage for a *different* living ally while the owner is alive (`incoming_multiplier`, holder is excluded from its own aura and a dead holder grants nothing). |
| `hollow_crown` | +15% damage with **dark** skills against a debuffed target (`outgoing_multiplier`). |
| `nothing_to_lose` | +12% outgoing damage while the owner is below 40% HP. |
| `patient_weaver` | +20% damage against a **stunned** target. |
| `small_miracles` | +10 energy to every team member at battle start (`_apply_battle_start_passives`, applied once). |
| `dawnkeeper` | One-time +20 energy refund on the owner's first healing skill each battle (`_dawnkeeper_used`). |
| `tidecall` | Healing also grants the target an 8% max-HP shield. |
| `ashen_wake` | Critical hits apply a 2-turn burn to the target. |
| `sanguine_waltz` | Heal for 20% of damage dealt (added on top of a skill's own `lifesteal`). |

**Honest implementation note — Dawnkeeper:** it is realised as a one-time 20-energy refund because the current combat model has no skill energy *cost* — normal skills *grant* energy and ultimates consume a full bar. The player-facing text ("the first healing skill each battle costs no turn energy") describes the intended design; the refund is the closest mechanical equivalent until per-skill energy costs exist.

Passive tuning values (multipliers, HP thresholds, shield/burn/lifesteal fractions) live as constants in `passive_effects.gd` so validation, tests and gameplay cannot drift apart. The engine exposes them through the public helpers `unit_speed`, `unit_defense`, `outgoing_multiplier` and `incoming_multiplier`.

### Adding a character

1. Add at least two active skills and one ultimate to `skills.json` first.
2. Add the character entry.
3. Add the ID to at least one banner pool in `banners.json`, otherwise it can never be summoned.
4. Give it a unique `portrait_seed` so procedural portraits differ.
5. Restart and confirm the boot count increased by one and validation is clean.
6. If the character should be owned from the start, add its id to `GameState.STARTING_CHARACTERS` (currently `gerald`, `lilith`, `kael`) — do not hardcode it in UI.

### Character art assets (Phase 5 — specifications, not artwork)

Phase 5 added ONE authored **art specification** per character id in
`scripts/art/character_art_spec.gd` (`CharacterArtSpec`), plus readable Markdown
companions:

- `assets/CHARACTER_SPECS.md` — all 12 specs in one table.
- `assets/characters/<id>/SPEC.md` — the full spec for one id (12 files, one per
  character: `lyra_vey`, `bramble`, `seraphine`, `nyx`, `coralyn`, `ignis`,
  `mira_sol`, `thistle`, `vespera`, `arachnia`, `terra`, `kael`).
- `assets/GENERATION_PROMPTS.md` — a shared global style anchor, 12 per-character
  prompts and exact output specs for a FUTURE external generation round.
- `assets/CHARACTER_ART_PIPELINE.md` and `assets/ASSET_PRODUCTION_MANIFEST.md` —
  the 10 asset kinds and the disk-computed FINAL/TEMPORARY/MISSING status.

**Identity and gameplay data are UNCHANGED** and still come from
`characters.json`. Each spec copies `name` / `race` / `element` / `rarity` /
`role` / `palette` / `skills` / `ultimate` **verbatim** from that JSON (a test
cross-checks them); the authored fields (physical appearance, hair style/colour,
outfit, accessories, weapon, personality, visual theme, pose, motif, expression,
tier note, generation prompts) are art direction only and do NOT alter combat,
stats or content. Rarity spread: 1 mythic (`ignis`), 3 legendary (`seraphine` /
`nyx` / `terra`), 4 epic, 3 rare, 1 common; Legendary/Mythic describe a distinct
premium visual tier. `CharacterArtSpec.validate_specs()` returns `[]`.

**These are PREPARATION for future external art, not finished artwork.** ZERO
final assets exist (see §16); no `.png/.webp/.jpg/.tres/.res` art file was
created and no audio exists. All shipped visuals remain runtime procedural
placeholder. **NO visual testing** was performed.

To read a spec: `CharacterArtSpec.for_id("lyra_vey")` → `.to_dict()` /
`.prompt_for("full_body"|"portrait"|"sheet"|"vfx")` /
`.required_animations()` (72). To **promote** an art asset to FINAL: drop a real,
validated file at the `res://assets/characters/<id>/<kind>` path recorded in
`assets/ASSET_PRODUCTION_MANIFEST.md`; `CharacterAssetRegistry` marks it FINAL
**only** when the file exists on disk AND
`validate_finished_asset(id, kind)` returns `[]` (correct dimensions, loadable
transparent RGBA8, the required 9×8 animations) — FINAL is NEVER hardcoded.
Until then it is MISSING (final) / TEMPORARY (procedural fallback). See
`documentation/ART_PIPELINE.md` §15.

---

## 5. Skills — `skills.json`

```json
"gale_shot": {
  "name": "Gale Shot",
  "description": "A wind-carved arrow that strikes a single foe. High critical chance.",
  "element": "wind",
  "kind": "damage",
  "power": 92,
  "target": "single_enemy",
  "crit_bonus": 0.12,
  "energy_gain": 22
}
```

| Field | Type | Default | Meaning |
| --- | --- | --- | --- |
| `name` | string | ID | Display name |
| `description` | string | `""` | Combat tooltip |
| `element` | string | `neutral` | `fire`, `wind`, `earth`, `water`, `light`, `dark`, `neutral` |
| `kind` | string | `damage` | `damage`, `heal`, `shield`, `buff` |
| `power` | number | `0` | Meaning depends on `kind` (below) |
| `target` | string | `single_enemy` | See targeting table |
| `statuses` | array | `[]` | Status applications |
| `cleanse` | boolean | `false` | Heal also removes debuffs |
| `lifesteal` | number | `0` | Fraction of damage healed to caster |
| `crit_bonus` | number | `0` | Added to caster crit chance for this skill |
| `energy_gain` | number | `20` | Energy gained by the caster on use |
| `ultimate` | boolean | `false` | Requires 100 energy; resets energy to 0 |

### `power` semantics

| `kind` | Formula |
| --- | --- |
| `damage` | `power × atk / (atk + def) × 1.6 × element × variance(0.95–1.05) × crit(1.6)` |
| `heal` | `target.max_hp × power / 100` |
| `shield` | `target.max_hp × power / 100` added to shield |
| `buff` | ignored; use `statuses` for the actual effect |

All damage is floored at 1 after rounding. Shields absorb damage before HP. Healing cannot exceed max HP.

### Targets

| `target` | Resolves to |
| --- | --- |
| `single_enemy` | Chosen living enemy, else first living enemy |
| `all_enemies` | Every living enemy |
| `single_ally` | Chosen living ally, else lowest-HP living ally |
| `all_allies` | Every living ally |
| `self` | The caster |

### Status effects

Each entry is `{ "id": ..., "chance": 0–1, "turns": int, "potency": number }`.

| `id` | Effect | `potency` meaning |
| --- | --- | --- |
| `burn` | Damage over time at turn start | fraction of max HP per turn |
| `poison` | Damage over time at turn start | fraction of max HP per turn |
| `regen` | Healing at turn start | fraction of max HP per turn |
| `stun` | Skips the actor's next turn | unused (set `1.0`) |
| `blind` | 30% chance to miss attacks | unused |
| `atk_up` / `atk_down` | Attack modifier | fraction, e.g. `0.25` = +25% |
| `def_up` / `def_down` | Defense modifier | fraction |
| `spd_up` / `spd_down` | Speed modifier (turn order) | fraction |
| `shield` | Adds `max_hp × potency` shield immediately | fraction of max HP |

Modifiers are additive and clamped: attack/speed `0.25–3.0×`, defense `0.2–3.0×`. Re-applying a status keeps the longer duration and stronger potency. `cleanse` removes all debuffs but preserves `atk_up`, `def_up`, `spd_up` and `regen`.

### Elements

```text
Fire → Wind → Earth → Water → Fire
Light ↔ Dark
```

Advantage is `1.5×`; disadvantage is `0.75×`; same element, neutral involvement, or unrelated pairs are `1.0×`.

### Energy and ultimates

- A normal skill grants its `energy_gain` to the caster.
- Dealing damage grants `+6` energy to the attacker and `+8` to the target.
- An ultimate needs `energy >= 100`, consumes all energy, and is offered only when ready.
- Enemy AI also evaluates ultimates and prefers them when available.

### Adding a skill

1. Add the entry with a unique ID.
2. Reference it from a character, enemy or both.
3. Keep `energy_gain` meaningful for non-ultimates; ultimates do not need it.
4. Run the suite — content validation will catch a missing reference.

---

## 6. Enemies — `enemies.json`

```json
"elder_hollow": {
  "name": "The Elder Hollow",
  "element": "earth",
  "rarity": "mythic",
  "role": "World Boss",
  "base": { "hp": 2400, "atk": 76, "def": 52, "spd": 22, "crit": 0.06 },
  "skills": ["root_crush", "hollow_wail", "bark_ward"],
  "ultimate": "hollow_verdict",
  "phases": [
    {
      "hp_below": 0.6,
      "message": "The Elder Hollow splits its bark...",
      "status": { "id": "atk_up", "turns": 99, "potency": 0.35 }
    }
  ],
  "lore": "...",
  "palette": { "primary": "#2f3a28", "secondary": "#8fbf6a", "accent": "#e8ffb0" }
}
```

Fields match character stats, with these differences:

- `phases` is optional and only fires when the unit is flagged as a boss/elite by its **group**.
- Each phase triggers once when HP ratio drops to or below `hp_below`; it applies `status` and emits `message`.
- `palette` drives the procedural monster visual. `hair`/`skin` are unused for monsters.
- Enemies may have any number of `skills`; the AI scores all of them plus the ultimate.

Enemy stat scaling by group level:

```text
hp/atk/def × (1 + 0.15 × (level − 1))
spd       × (1 + 0.02 × (level − 1))
```

Duplicate enemies in one group are renamed `A`, `B`, `C`, … automatically.

---

## 7. Enemy groups — `enemy_groups.json`

```json
"glade_mossling_pack": {
  "name": "Mossling Ambush",
  "region": "greenward",
  "level": 1,
  "enemies": ["mossling", "mossling", "glade_wisp"],
  "rewards": {
    "gold": 45,
    "xp": 60,
    "crystals": 10,
    "items": { "glade_sap": 1 }
  },
  "quest_kills": { "mossling": 2, "glade_wisp": 1 }
}
```

| Field | Meaning |
| --- | --- |
| `name` | Encounter label |
| `region` | Region ID; currently informational |
| `level` | Scales enemy stats and rewards |
| `enemies` | Ordered list of enemy IDs; duplicates allowed |
| `rewards.gold` / `crystals` / `xp` | Base rewards, multiplied by `1 + 0.12 × (level − 1)` |
| `rewards.items` | Item ID → count |
| `quest_kills` | Enemy ID → kills credited to active quests on victory |
| `elite` | Optional boolean; marks the enemy as boss-like for visuals/phases |
| `boss` | Optional boolean; same plus roaming-monster boss presentation |

Rewards are granted by `GameState.apply_battle_result()`, which also calls `record_kill()` for each `quest_kills` entry. Only victories grant rewards.

`elite` and `boss` both set `Combatant.is_boss`, which enables phases and the boss badge. They do not change stats by themselves; use `level` and `base` for that.

---

## 8. Items — `items.json`

```json
"gladewood_bow": {
  "name": "Gladewood Bow",
  "category": "equipment",
  "slot": "weapon",
  "rarity": "epic",
  "element": "wind",
  "stats": { "atk": 24, "spd": 4 },
  "description": "A living bow cut from a branch that agreed to be cut.",
  "color": "#8fbf6a"
}
```

| Field | Used by |
| --- | --- |
| `name` | UI |
| `category` | `currency`, `material` or `equipment` |
| `description` | Inventory detail |
| `rarity` | UI colour/label (optional) |
| `icon` / `color` | UI fallback icon and tint |
| `slot` | Equipment only: `weapon`, `armor`, `accessory` |
| `element` | Equipment only; drives elemental resonance (see "Equipment resonance" below) |
| `stats` | Equipment only: `hp`, `atk`, `def`, `spd`, `crit` |

### Currency routing

`GameState.grant_reward_items()` inspects `category`. Any item with `category: "currency"` is added to the wallet (`profile`) instead of the inventory. This means reward tables may mix currencies and materials freely:

```json
"rewards": { "gold": 500, "items": { "ancient_coins": 2, "dew_of_awakening": 1 } }
```

`gold` and `crystals` are also handled explicitly by quest and battle reward code, so both top-level fields and item entries work. Prefer top-level `gold`/`crystals` for clarity and `items` for everything else.

### Equipment

Equipping removes one copy from inventory and returns the previously equipped item to inventory. Equipment stats are applied **additively** in `CombatFactory._apply_equipment()` when the battle starts, so changes take effect on the next battle.

#### Equipment resonance

`CombatFactory` sets `Combatant.equipment_element` from the **first elemental equipped item**, checking the weapon slot first, then armor, then accessory; a missing or `neutral` element is ignored. `CombatEngine.outgoing_multiplier()` turns that into damage:

- **`EQUIPMENT_RESONANCE` (1.08, +8%)** when the skill's element equals `equipment_element`.
- **`EQUIPMENT_ATTUNEMENT` (1.04, +4%)** when `equipment_element` equals the wielder's own element.

The two bonuses stack: a fire character wielding a fire weapon and casting a fire skill gets ×1.08 × 1.04 = ×1.1232. No elemental equipment (or a fully mismatched element) gives ×1.0. In the shipped data the elemental equipment is `gladewood_bow` (wind weapon) and `sunfire_blade` (fire weapon).

### Adding an item

1. Choose a category and unique ID.
2. For equipment, set `slot` and `stats`.
3. Reference it from a quest, enemy group or shop (future).
4. Confirm it appears in the inventory screen with a readable name and description.

---

## 9. Banners — `banners.json`

```json
"glade_whispers": {
  "name": "Whispers of the Glade",
  "subtitle": "Standard summon — Greenward chapter",
  "type": "standard",
  "featured": ["lyra_vey"],
  "featured_rate": 0.5,
  "rates": { "common": 0.52, "rare": 0.30, "epic": 0.13, "legendary": 0.045, "mythic": 0.005 },
  "hard_pity": 70,
  "featured_pity": 140,
  "ten_pull_epic_guarantee": true,
  "cost": { "currency": "crystals", "single": 150, "ten": 1350 },
  "pool": {
    "common": ["mira_sol"],
    "rare": ["bramble", "thistle", "kael"],
    "epic": ["lyra_vey", "coralyn", "vespera", "arachnia"],
    "legendary": ["seraphine", "nyx", "terra"],
    "mythic": ["ignis"]
  }
}
```

| Field | Behaviour |
| --- | --- |
| `rates` | Per-pull rarity probabilities. Should sum to ~1.0; if the roll exceeds the cumulative total, the result falls back to `common`. |
| `featured` | Character IDs eligible for the rate-up |
| `featured_rate` | Chance that a matching-rarity pull becomes featured |
| `hard_pity` | Guarantees a legendary-or-better pull at this many pulls without one |
| `featured_pity` | Guarantees the featured character at this many pulls without one |
| `ten_pull_epic_guarantee` | Replaces the last result with an Epic-or-better if the ten-pull had none |
| `cost.currency` | Wallet currency ID |
| `cost.single` / `cost.ten` | Prices |
| `pool` | Rarity → character IDs |

Important details:

- The featured rate-up only applies when the rolled rarity matches the featured character's rarity. A featured mythic cannot appear from an epic roll.
- Hard pity counts pulls since the last legendary-or-better and resets on any legendary/mythic.
- Featured pity counts pulls since the last featured result and resets only on a featured result.
- Pity state is stored per banner ID in `GameState.pity` and saved.
- The ten-pull floor replaces the final result; it does not add an extra pull.
- Pity and rates are client-side in this build. They must move to the server before monetisation.

### Adding a banner

1. Ensure every character ID exists.
2. Make rates sum to 1.0 (the suite checks this within ±0.02).
3. Pick pity values and costs.
4. Restart and open the summon screen; rates and pity text are read directly from the data.
5. If the banner is limited-time, add availability fields only after the UI supports them — do not fake a timer.

---

## 10. Quests — `quests.json`

```json
"glade_whisper": {
  "name": "The Glade's Whisper",
  "region": "greenward",
  "summary": "Elder Maelin says the mosslings no longer sleep...",
  "steps": [
    { "type": "talk", "target": "elder_maelin", "text": "Hear Elder Maelin's request" },
    { "type": "kill", "target": "mossling", "count": 3, "text": "Calm corrupted mosslings" },
    { "type": "talk", "target": "elder_maelin", "text": "Return to Elder Maelin" }
  ],
  "rewards": {
    "gold": 300,
    "crystals": 120,
    "xp": 150,
    "items": { "moonpetal": 3, "gladewood_bow": 1 }
  }
}
```

| Field | Meaning |
| --- | --- |
| `name` | Quest log title |
| `region` | Region ID; informational |
| `summary` | Quest log body |
| `requires` | Optional prerequisite quest ID; `start_quest()` refuses to start until that quest is `complete`. The validator rejects a missing or self-referential `requires`. |
| `steps` | Ordered list of objectives |
| `steps[].type` | `talk` or `kill` |
| `steps[].target` | Dialogue ID (talk) or enemy ID (kill) |
| `steps[].count` | Required kills (kill steps) |
| `steps[].text` | Player-facing objective |
| `rewards.gold` / `crystals` | Wallet rewards |
| `rewards.xp` | Party XP reward |
| `rewards.items` | Item ID → count |

### Quest flow

- A quest starts through a dialogue action `start_quest:<quest_id>`. The dialogue ID is passed as the giver.
- If the first step is `talk` with `target` equal to the dialogue ID, that step is satisfied automatically by the conversation that grants the quest.
- Kill progress advances only for active quests whose current step matches the enemy ID.
- `quest_ready()` is true when the quest is active and the current step is the final `talk` step. That is what the dialogue condition `quest_ready:<id>` checks.
- Completing a quest through `complete_quest:<id>` grants rewards once and sets state to `complete`.
- `requires` is enforced by `GameState.start_quest()`: the named prerequisite quest must be in state `complete` before the quest starts (direct dialogue offers also route through `start_quest`, so the gate applies there too). Dialogues additionally use `quest_*` conditions to decide *which* line the NPC shows. `hollow_roots`, for example, requires `glade_whisper` to be complete.

### Adding a quest

1. Add the quest entry with at least one step and a reward block.
2. Add dialogue nodes that call `start_quest:<id>` and later `complete_quest:<id>`.
3. Add `start_rules` so the NPC says the right thing for `not_started`, `active`, `ready` and `complete`.
4. If the quest requires kills, make sure the enemy appears in an encounter's `quest_kills` map.
5. Run the quest through once from a fresh save.

---

## 11. Dialogue — `dialogue.json`

```json
"elder_maelin": {
  "start": "greet",
  "start_rules": [
    { "if": "quest_ready:glade_whisper", "node": "turnin_glade" },
    { "if": "quest_state:glade_whisper:active", "node": "in_progress" },
    { "if": "quest_state:glade_whisper:complete", "node": "after_glade" }
  ],
  "nodes": {
    "greet": {
      "speaker": "Elder Maelin",
      "portrait": {
        "hair": "#d8d8c0", "primary": "#4a5a3a", "secondary": "#c9a45a",
        "accent": "#9df5cf", "skin": "#e8c8a8"
      },
      "text": "You walked out of the mist like you were expected...",
      "choices": [
        { "text": "What troubles the glade?", "next": "quest_intro" },
        { "text": "I should go.", "next": "" }
      ]
    }
  }
}
```

### Structure

- `start` — fallback node ID.
- `start_rules` — evaluated top to bottom; the first true `if` selects `node`.
- `nodes` — map of node ID → node.
- A node has `speaker`, optional `portrait`, `text`, optional `choices`, and optional `next`.
- A choice has `text`, optional `next`, and optional `action`.
- Empty `next` closes the conversation. If `choices` is absent, the Continue button follows `next`.

### Conditions (`start_rules[].if`)

| Condition | True when |
| --- | --- |
| `quest_state:<id>:<state>` | Quest state equals `not_started`, `active` or `complete` |
| `quest_ready:<id>` | Active quest is on its final talk step |
| `quest_active:<id>` | Quest state is `active` |
| `quest_complete:<id>` | Quest state is `complete` |
| `has_character:<id>` | The roster owns that character |
| `level_at_least:<n>` | Profile level ≥ n |
| `""` | Always true |

Unknown condition types return `false`.

### Actions (`choices[].action`)

| Action | Effect |
| --- | --- |
| `start_quest:<id>` | Starts the quest, using the dialogue ID as giver |
| `complete_quest:<id>` | Grants rewards if the quest is ready |
| `add_item:<id>[:count]` | Adds an item |
| `add_currency:<id>:<amount>` | Adds wallet currency |
| `set_flag:<key>:<value>` | Writes a string flag to the save |
| `toast:<text>` | Emits a UI toast |

Unknown actions log a warning and do nothing. Actions run **before** navigation to `next`.

### Speaker portraits

The dialogue node supplies the palette. The portrait race is currently mapped in `DialogueBox._race_for_speaker()` for the three shipped speakers and defaults to Human. If you add a speaker with a different silhouette, add a mapping there — or move the race into the dialogue node in a later schema revision.

### Adding dialogue

1. Add a top-level dialogue ID matching what the NPC spawns with.
2. Define `start` and any `start_rules`.
3. Ensure every `next` and rule `node` exists — the strict validator (section 2) now checks dialogue links automatically and reports `references missing node '…'`.
4. Add the NPC to `_build_village()` in `greenward_world.gd` with the same dialogue ID.
5. Walk every branch once, including the close paths.

---

## 12. Regions — `regions.json`

```json
"greenward": {
  "name": "Greenward",
  "subtitle": "Enchanted forests and forgotten temples",
  "chunk_size": 16,
  "tile_width": 64,
  "tile_height": 32,
  "load_radius": 2,
  "noise_seed": 1337,
  "spawn_grid": [8, 8],
  "biome": {
    "water_level": -0.22,
    "deep_water_level": -0.34,
    "grass_colors": ["#4f7a46", "#568449", "#5c8c4f", "#4a7243"],
    "path_color": "#8a7a55",
    "water_shallow": "#3f8f96",
    "water_deep": "#1f5568"
  },
  "props": [
    { "type": "glade_tree", "weight": 0.5, "min_elevation": -0.1 },
    { "type": "rock", "weight": 0.18, "min_elevation": -0.05 }
  ],
  "clearing_radius": 4.5,
  "pois": [
    { "id": "glade_village", "name": "Whispering Glade", "grid": [8, 8], "type": "village" }
  ],
  "spawns": [
    { "group": "glade_mossling_pack", "grid": [4, 6], "radius": 3, "count": 2 }
  ],
  "world_origin": [0.0, 0.0],
  "environment": {
    "zone": "temperate_forest",
    "weather_bias": ["clear", "mist"],
    "fog_density": 0.18,
    "ambient_tint": "#7fe3e0",
    "ambient_music": ""
  },
  "entry_points": {
    "village": [8, 8],
    "moonpetal_path": [30, 8]
  },
  "connections": [
    {
      "id": "moonpetal_path",
      "to": "moonpetal_hollow",
      "via": "moonpetal_path",
      "entry": "hollow_gate",
      "kind": "gate",
      "label": "Moonpetal Path"
    }
  ]
}
```

A second, fully data-driven region `moonpetal_hollow` uses the same keys with
its own cooler violet/silver biome, `noise_seed 24601`, `load_radius 1`, 2 pois,
2 spawns and one reciprocal `greenward_gate` connection back to Greenward.

| Field | Meaning |
| --- | --- |
| `chunk_size` | Tiles per chunk edge (16) |
| `tile_width` / `tile_height` | Isometric tile footprint (64 × 32) |
| `load_radius` | Chunk ring radius kept loaded (2 = 5 × 5 chunks) |
| `noise_seed` | Deterministic terrain/prop seed |
| `spawn_grid` | Player start in grid coordinates |
| `biome.*` | Water thresholds and palette |
| `props[].type` | Prop visual key understood by `ProceduralArt` |
| `props[].weight` | Relative scatter weight |
| `props[].min_elevation` | Minimum noise elevation to place |
| `clearing_radius` | Radius kept clear around the village |
| `pois` | Points of interest for future map/UI use |
| `spawns` | Roaming encounter placement |
| `world_origin` | Logical world/map-space offset (two numbers); each region keeps its OWN local grid↔world projection — `IsoMath` / `ChunkStreamer` are unchanged |
| `environment` | `zone`, `weather_bias`, `fog_density`, `ambient_tint`, `ambient_music` (an empty hook — no audio exists); applied to atmosphere so regions read differently |
| `entry_points` | Named spawn/arrival grid coordinates |
| `connections` | Directed travel edges `{ id, to, via, entry, kind, label }`; every shipped link has a reciprocal edge (see "Connections and the region graph") |

Supported `props[].type` values are the **57 kinds** in `ContentValidator.PROP_TYPES` / `GreenwardStyle.prop_kinds()` — the original 12 (`glade_tree`, `ancient_tree`, `rock`, `flower`, `mushroom`, `bush`, `crystal`, `hut`, `waypoint`, `lantern`, `fence`, `ruin_pillar`), 35 Phase-3 kinds, 6 Phase-4 building/landmark kinds (`watchtower`, `market_stall`, `stone_wall`, `gazebo`, `banner_post`, `moon_shrine`) and 4 new Phase-5 kinds (`birch_grove`, `moon_lantern`, `stone_path`, `village_gate`).

### Two regions: what is still hardcoded

There are now **exactly TWO regions** in `regions.json`: `greenward` and
`moonpetal_hollow` (a small silver-birch moonlit vale). Both are bootstrapped
through the region-parameterized `GreenwardWorld`:

- `greenward` — the village layout, NPC placement and landmark composition
  remain **partly HARDCODED** in the Greenward-specific builders; spawns,
  biome, POIs and chunk settings are data-driven.
- `moonpetal_hollow` — **fully data-driven** via
  `GreenwardWorld._build_generic_region()` (a generic builder + `RegionPortal`
  gates), with its own cooler violet/silver biome, `noise_seed 24601`,
  `load_radius 1`, 2 pois and 2 spawns.

`GameScreen` rebuilds the world on a validated
`EventBus.region_change_requested(target_region_id, entry_point)` change and
`GameState` persists a position per region (`region`, `region_positions`) —
old saves load into `greenward`. Region transitions are validated and wired but
**cannot be interactively playtested headlessly**. There are no six empty
continents and no seamless zone streaming.

### Connections and the region graph

`connections` are directed travel edges, but every shipped link has a
reciprocal edge on the destination region (bidirectional travel). Each
connection is `{ "id", "to", "via", "entry", "kind", "label" }`:

- `to` — destination region id (must exist).
- `via` — the **SOURCE** region's `entry_points` id where the gate sits.
- `entry` — the **DESTINATION** region's `entry_points` id where the player
  arrives.
- `kind` — one of `gate`, `bridge`, `portal`, `path`; `label` — UI text.

`scripts/world/region_graph.gd` (`RegionGraph`) exposes
`region_ids/has_region/definition/region_name/entry_points/entry_grid/
connections_from/connection/can_travel/resolve_transition/world_origin/
local_to_world_position/world_to_local_position/world_position_of_grid/
region_at_world_position/spawn_grid/spawns/environment/load_radius/validate/
summary` and a static `validate_definitions`. `world_origin` is a LOGICAL
map/travel-space offset — each region keeps its own local grid↔world
projection and `ChunkStreamer` / `IsoMath` are unchanged. Boot validation runs
`ContentValidator.validate_region_graph(regions)` (a BFS unreachable-region
check) plus the strict per-field checks described in §2.

### Adding a region

1. Add a **COMPLETE** region definition — every top-level key in
   `regions.json` is validated as a region, so do **NOT** put top-level
   metadata beside the region ids. Include `world_origin`, `environment` and
   `entry_points`.
2. Add `entry_points` (named grid coordinates) for arrivals and departures.
3. Add **bidirectional** `connections` (a connection on the new region AND a
   reciprocal one on an existing region), with valid `to`/`via`/`entry`.
4. Run the validator (`godot --headless --path . --script res://tools/validate_content.gd`); it checks missing target regions, self-loops, dangling `via`/`entry`, duplicate ids, invalid `kind`/`label`, bad `world_origin`/`environment`/`entry_points`, and graph reachability.
5. Add `spawns` referencing **existing** enemy groups (see "Adding spawns").
6. Add tests for the new region / transitions (see `TESTING.md`).

### Adding spawns

1. Create the enemy group first.
2. Add a spawn entry with grid centre, radius and count.
3. Keep spawns inside the loaded area and away from the village clearing.
4. Test that the roaming monster uses the intended first-enemy visual.

---

## 13. Validation checklist

Before committing content:

- [ ] JSON parses (no trailing commas, no comments) and has no duplicate keys.
- [ ] `godot --headless --path . --script res://tools/validate_content.gd` exits 0 (`[validate] OK — 9 content files parsed and validated.`).
- [ ] New IDs are unique and `snake_case`.
- [ ] Every referenced skill, enemy, item, character, quest, dialogue and group exists.
- [ ] Elements use the supported set.
- [ ] Skill `kind` and `target` use supported values.
- [ ] Status IDs use the supported set; `potency` matches the intended meaning.
- [ ] Every character's `passive.id` is one of the 12 supported ids.
- [ ] Equipment `element` (if set) is a supported element; `stats` use supported keys.
- [ ] Banner rates sum to ~1.0; `hard_pity` / `featured_pity` are positive and `featured_pity >= hard_pity`; `featured` ids are in the pool.
- [ ] Quest `requires` (if set) names an existing quest that can be completed first.
- [ ] Quest kill targets appear in an encounter's `quest_kills`.
- [ ] Dialogue `next` and `start_rules[].node` targets exist.
- [ ] New NPC dialogue IDs match the spawn call.
- [ ] Reward `items` reference real item ids; currency entries have `category: "currency"` and route to the wallet.
- [ ] Boot log has no `[ContentDB]` errors.
- [ ] Region `connections` have valid `to` / `via` / `entry`, no self-loops or dangling entry points, and a reciprocal edge on the destination region; `validate_region_graph` (BFS reachability) passes.
- [ ] New region has `world_origin`, `environment` and `entry_points`; any new `props[].type` is in `PROP_TYPES` (57 supported kinds).
- [ ] Asset status is HONEST: `AssetManifest.status_report()` = **FINAL 0 / TEMPORARY 8 / MISSING 8** and `CharacterAssetRegistry.report()` = **FINAL 0 / TEMPORARY 120 / MISSING 120** (12 × 10), unless real validated asset files were added; FINAL is NEVER hardcoded (see `assets/ASSET_STATUS.md`, `assets/ASSET_PRODUCTION_MANIFEST.md`, ART_PIPELINE.md §15). **ZERO final assets** exist; no audio.
- [ ] `CharacterArtSpec.validate_specs()` returns `[]` — all 12 specs are present, unique, every required field is non-empty, identity fields are verbatim from `characters.json` (gameplay data UNCHANGED), 9 states / 72 animations and premium Legendary/Mythic tier described.
- [ ] All 12 `assets/characters/<id>/SPEC.md` files exist and match `CharacterArtSpec` identity; `assets/CHARACTER_SPECS.md` and `assets/GENERATION_PROMPTS.md` cover all 12; specs/prompts are PREPARATION for future external art, not finished artwork.
- [ ] `1374 passed, 0 failed` from the test suite (236 + 111 + 203 + 404 + 420; all 954 prior tests preserved).
- [ ] Manual pass: title → game → dialogue → quest → battle → reward → save/reload.

---

## 14. Balancing guidance

- Keep character `base` stats in the same order of magnitude as the shipped roster. A level-1 mythic should not one-shot a level-6 boss.
- Damage is roughly `power × 1.6 × atk/(atk+def)`. Doubling `power` roughly doubles damage; doubling `def` reduces incoming damage but with diminishing returns.
- Healing and shields are percentages of max HP, so they scale automatically with level and ascension.
- Enemy groups scale with `level`; use that before inflating base stats.
- Pity values are player-facing promises. Change them only with a clear design reason and update the summon screen text if it quotes numbers.
- Reward XP feeds both party characters and profile level. Profile level currently gates nothing except future content, so it is safe to tune later.

---

## 15. Versioning and saves

Content IDs are referenced by save data:

- roster `char_id`
- quest IDs and step indices
- banner pity keys
- inventory item IDs
- equipment slots/items
- flags

Removing or renaming an ID can orphan save entries. The loader drops unknown characters on load, but quests, inventory and pity are not migrated. When IDs must change, add a migration in `SaveService` or `GameState._load_from_dict()` and bump `SAVE_VERSION`.

Adding new content is safe: old saves simply do not have it.

---

## 16. Known gaps in the content layer

These are honest limitations of the current slice, not bugs to hide:

- **Exactly TWO regions** (`greenward` + `moonpetal_hollow`) are bootstrapped; `greenward`'s village/NPC/landmark layout is partly HARDCODED while the second region is fully data-driven. No additional continents, no elevation/cliffs/water traversal rules, no seamless zone streaming, no fast-travel/map/fog-of-war, no mounts, no spawn directors/respawn timers and no world audio ambience; region transitions are validated and wired but cannot be interactively playtested headlessly.
- **ZERO final assets; no audio.** All art is runtime procedural placeholder; `AssetManifest.status_report()` is **FINAL 0 / TEMPORARY 8 / MISSING 8** and `CharacterAssetRegistry.report()` is **FINAL 0 / TEMPORARY 120 / MISSING 120** (12 characters × 10 kinds). No `.png/.webp/.jpg/.tres/.res` art file exists anywhere, the only image is `icon.svg`, and the demo sheet is a TEMPORARY in-memory procedural `SpriteFrames`; no audio of any kind exists.
- **The 12 character specs + generation prompts are PREPARATION, not art.** `CharacterArtSpec` / `assets/characters/<id>/SPEC.md` / `assets/GENERATION_PROMPTS.md` describe a FUTURE external art round; identity/gameplay data still comes from `characters.json` (UNCHANGED). No finished artwork and no external generation were produced.
- **NO visual testing was performed.** All verification is `--headless` with Godot's dummy renderer; `_draw()` output, auras, borders, tints, silhouettes and tween pops are compile/build-safe and structurally asserted but were NOT visually inspected on screen; no shader compilation / appearance verification and no device profiling.
- **No threaded chunk generation.** `ChunkPreparer` is main-thread frame-sliced (NO threads); no device profiling has been performed (headless uses a dummy renderer).
- Enemy `region` fields are informational.
- Dialogue speaker race mapping is hardcoded for shipped speakers.
- Dawnkeeper's intended design ("the first heal each battle costs no turn energy") is approximated by a one-time 20-energy refund; there is no per-skill energy cost yet.
- No localization layer; strings are English-only.
- No live-content validation against a server; all content ships with the client. The local JSON save is **non-authoritative** until Phase 12 — there is no multiplayer, backend, or server authority in this build.

Phase 2 closed three earlier gaps: character passives are now applied in combat, `start_quest()` enforces `requires`, and equipment `element` drives resonance/attunement. When any remaining gap becomes real, update this guide and the relevant test in the same change.
