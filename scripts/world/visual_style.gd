class_name GreenwardStyle
extends RefCounted
## GreenwardStyle â€” the single source of truth for PROJECT FANTASY's visual world.
##
## Every colour, day-phase light setting, sprite spec, prop palette and density
## cap lives here so procedural_art.gd, chunk_builder.gd, the shaders and the
## character/animation pipeline all read from one coherent palette. Reading from
## here (instead of scattering hex literals) is what keeps the placeholder art
## visually consistent across terrain, props, water, characters and UI.
##
## IMPORTANT: everything shipped today is PROCEDURAL PLACEHOLDER ART. There are
## no final painted assets. See documentation/VISUAL_STYLE.md for the art
## direction and documentation/ART_PIPELINE.md for the replacement workflow.

# ------------------------------------------------------------------ palette
# Sky / dawn / dusk / night gradients -----------------------------------------
const SKY := {
	"dawn_top": Color("#3a4a7a"),
	"dawn_bottom": Color("#f0b89a"),
	"day_top": Color("#4a86c8"),
	"day_bottom": Color("#bfe0f0"),
	"golden_top": Color("#5a6ea0"),
	"golden_bottom": Color("#ffcf87"),
	"dusk_top": Color("#3d3a6b"),
	"dusk_bottom": Color("#e8886a"),
	"nightfall_top": Color("#1c2250"),
	"nightfall_bottom": Color("#4a4070"),
	"night_top": Color("#0a1030"),
	"night_bottom": Color("#2a3566"),
}

# Canopy greens (deep -> rim) and undergrowth greens -------------------------
const CANOPY := {
	"deep": Color("#1f3428"),
	"mid": Color("#35563a"),
	"light": Color("#52784c"),
	"rim": Color("#a5c98a"),
	"pine": Color("#263f35"),
	"moss": Color("#536f45"),
	"bright": Color("#8da96a"),
	"autumn": Color("#c9a45a"),
	"blossom": Color("#ffc2d6"),
	"birch": Color("#e8e4d0"),
}
const UNDERGROWTH := {
	"dark": Color("#29432f"),
	"mid": Color("#3e6240"),
	"light": Color("#58774a"),
	"grass": Color("#476d42"),
	"grass_alt": Color("#52794a"),
	"dry": Color("#8b7958"),
	"reeds": Color("#75895b"),
	"lily": Color("#416f55"),
}

# Water: shallow / deep / foam / reflection / shore --------------------------
const WATER := {
	"shallow": Color("#3f8f96"),
	"deep": Color("#1f5568"),
	"foam": Color("#d9f5ef"),
	"reflection": Color("#bfe8e6"),
	"shore": Color("#cbb98a"),
	"glint": Color("#eafbff"),
	"waterfall": Color("#9fd8dd"),
}

# Stone: light / mid / dark / moss --------------------------------------------
const STONE := {
	"light": Color("#8a8776"),
	"mid": Color("#62645a"),
	"dark": Color("#4a4a44"),
	"moss": Color("#6f8f5a"),
	"moss_dark": Color("#5d7a4a"),
	"rune": Color("#7fe3e0"),
	"wet": Color("#3a4a50"),
}

# Timber: light / mid / dark --------------------------------------------------
const TIMBER := {
	"light": Color("#6b4c33"),
	"mid": Color("#5a4030"),
	"dark": Color("#3a2a1c"),
	"plank": Color("#4a3524"),
	"warm": Color("#8a6440"),
	"thatch": Color("#b89257"),
}

# Magic: teal / gold / violet / ember -----------------------------------------
const MAGIC := {
	"teal": Color("#7fe3e0"),
	"gold": Color("#ffcf6a"),
	"violet": Color("#b78bff"),
	"ember": Color("#ff8a5c"),
	"teal_deep": Color("#2a8f9f"),
	"teal_light": Color("#c9fffb"),
	"violet_light": Color("#e0c8ff"),
}

# Light: warm lantern vs cool moon --------------------------------------------
const LIGHT := {
	"warm_lantern": Color("#ffcf6a"),
	"warm_glow": Color(1.0, 0.8, 0.45),
	"cool_moon": Color("#9fc0ff"),
	"moon_glow": Color(0.6, 0.75, 1.0),
	"magic": Color("#9df5cf"),
}

# Accents: petals, berries, runes, wildlife -----------------------------------
const ACCENTS := {
	"petal": Color("#ffb3c7"),
	"petal_alt": Color("#ffe9a3"),
	"petal_violet": Color("#c9a0ff"),
	"berry": Color("#c0405a"),
	"rune": Color("#9df5cf"),
	"rune_gold": Color("#ffe6a8"),
	"ember_spark": Color("#ffb060"),
	"glow_mushroom": Color("#8fe3c0"),
	"mushroom_cap": Color("#b05a5a"),
	"butterfly": Color("#ffd27a"),
	"moth": Color("#d8c8a0"),
	"bird": Color("#6fa8d8"),
	"firefly": Color(0.65, 1.0, 0.9),
}

# UI-coordination colours (kept in step with UITheme.gd) ---------------------
const UI := {
	"bg": Color("#080b16"),
	"panel": Color("#121a2e"),
	"text": Color("#e9eef9"),
	"gold": Color("#e8c27a"),
	"teal": Color("#7fe3e0"),
	"green": Color("#8fe3a0"),
	"violet": Color("#b78bff"),
	"danger": Color("#ff7a8a"),
}

# Element colours, aligned with UITheme.ELEMENT for cross-screen coherence ----
const ELEMENTS := {
	"neutral": Color("#9aa8c2"),
	"fire": Color("#ff8a5c"),
	"wind": Color("#8fe3a0"),
	"earth": Color("#c9a86a"),
	"water": Color("#6fc8ff"),
	"light": Color("#ffe6a8"),
	"dark": Color("#b78bff"),
}

# Shared dark ink used for 1â€“2px readability outlines ------------------------
const INK := Color("#161a24")

# ------------------------------------------------------------------ day phases
# Every entry MUST carry the eight keys below. Names cover the Doc's canonical
# set ("Dawn","Day","Golden Hour","Dusk","Nightfall","Midnight") AND the exact
# phase strings emitted by scripts/world/day_night.gd (Morning/Noon/Afternoon).
const REQUIRED_PHASE_KEYS: Array[String] = [
	"tint", "ambient", "light_energy", "fog", "fog_density", "fireflies",
	"sky_top", "sky_bottom",
]
const REQUIRED_PHASES: Array[String] = [
	"Dawn", "Day", "Golden Hour", "Dusk", "Nightfall", "Midnight",
	"Morning", "Noon", "Afternoon",
]

const PHASES := {
	"Midnight": {
		"tint": Color(0.34, 0.40, 0.62), "ambient": 0.32, "light_energy": 0.45,
		"fog": Color(0.12, 0.16, 0.30), "fog_density": 0.35, "fireflies": true,
		"sky_top": Color("#0a1030"), "sky_bottom": Color("#2a3566"),
	},
	"Dawn": {
		"tint": Color(0.82, 0.70, 0.72), "ambient": 0.62, "light_energy": 0.80,
		"fog": Color(0.70, 0.60, 0.65), "fog_density": 0.22, "fireflies": false,
		"sky_top": Color("#3a4a7a"), "sky_bottom": Color("#f0b89a"),
	},
	"Morning": {
		"tint": Color(1.00, 0.97, 0.91), "ambient": 0.90, "light_energy": 0.50,
		"fog": Color(0.85, 0.88, 0.90), "fog_density": 0.12, "fireflies": false,
		"sky_top": Color("#4a86c8"), "sky_bottom": Color("#bfe0f0"),
	},
	"Noon": {
		"tint": Color(1.00, 1.00, 1.00), "ambient": 1.00, "light_energy": 0.30,
		"fog": Color(0.80, 0.88, 0.95), "fog_density": 0.08, "fireflies": false,
		"sky_top": Color("#4a86c8"), "sky_bottom": Color("#bfe0f0"),
	},
	"Day": {
		"tint": Color(1.00, 1.00, 1.00), "ambient": 1.00, "light_energy": 0.30,
		"fog": Color(0.80, 0.88, 0.95), "fog_density": 0.08, "fireflies": false,
		"sky_top": Color("#4a86c8"), "sky_bottom": Color("#bfe0f0"),
	},
	"Afternoon": {
		"tint": Color(1.00, 0.95, 0.86), "ambient": 0.95, "light_energy": 0.40,
		"fog": Color(0.90, 0.85, 0.80), "fog_density": 0.10, "fireflies": false,
		"sky_top": Color("#5a6ea0"), "sky_bottom": Color("#ffcf87"),
	},
	"Golden Hour": {
		"tint": Color(1.00, 0.85, 0.62), "ambient": 0.80, "light_energy": 0.70,
		"fog": Color(0.95, 0.75, 0.55), "fog_density": 0.18, "fireflies": false,
		"sky_top": Color("#5a6ea0"), "sky_bottom": Color("#ffcf87"),
	},
	"Dusk": {
		"tint": Color(0.94, 0.68, 0.58), "ambient": 0.60, "light_energy": 0.90,
		"fog": Color(0.60, 0.45, 0.50), "fog_density": 0.25, "fireflies": true,
		"sky_top": Color("#3d3a6b"), "sky_bottom": Color("#e8886a"),
	},
	"Nightfall": {
		"tint": Color(0.50, 0.48, 0.70), "ambient": 0.42, "light_energy": 0.70,
		"fog": Color(0.20, 0.20, 0.38), "fog_density": 0.30, "fireflies": true,
		"sky_top": Color("#1c2250"), "sky_bottom": Color("#4a4070"),
	},
}

# ------------------------------------------------------------------ sprite specs
# World 96x128, boss 128x192, bottom-centre anchor, 1â€“2px outline. `fps`,
# `frames` and `loop` are keyed by state name; `frame_counts` / `fps_values` /
# `loop_flags` are parallel arrays indexed by the state ints (0..7) so either
# lookup style works for the animation pipeline.
#
# TIMING RECONCILED (Phase 3 / Step 4): every value below is the authoritative
# CharacterAnimator.STATE_FRAMES / STATE_FPS / STATE_LOOPING, in state order
# IDLE(0) WALK(1) RUN(2) INTERACT(3) ATTACK(4) DAMAGE(5) VICTORY(6) DEFEAT(7):
#   frames 5,64,64,6,6,2,8,6   fps 9,60,64,12,15,12,12,10
#   loop   true,true,true,false,false,false,false,false
# The animator, ActorFrameSource, ProceduralActorFrames and these specs MUST stay
# in lockstep; do not edit one without the others.
const SPRITE_SPECS := {
	"world_width": 96,
	"world_height": 128,
	"boss_width": 128,
	"boss_height": 192,
	"anchor": Vector2(0.5, 1.0),
	"outline_px": 2,
	"state_count": 8,
	"direction_count": 8,
	"state_names": ["IDLE", "WALK", "RUN", "INTERACT", "ATTACK", "DAMAGE", "VICTORY", "DEFEAT"],
	"direction_names": ["DOWN", "DOWN_RIGHT", "RIGHT", "UP_RIGHT", "UP", "UP_LEFT", "LEFT", "DOWN_LEFT"],
	"fps": {
		"IDLE": 9, "WALK": 12, "RUN": 14, "INTERACT": 12,
		"ATTACK": 15, "DAMAGE": 12, "VICTORY": 12, "DEFEAT": 10,
	},
	"frames": {
		"IDLE": 5, "WALK": 64, "RUN": 64, "INTERACT": 6,
		"ATTACK": 6, "DAMAGE": 2, "VICTORY": 8, "DEFEAT": 6,
	},
	"loop": {
		"IDLE": true, "WALK": true, "RUN": true, "INTERACT": false,
		"ATTACK": false, "DAMAGE": false, "VICTORY": false, "DEFEAT": false,
	},
	"frame_counts": [5, 7, 7, 6, 6, 2, 8, 6],
	"fps_values": [9, 12, 14, 12, 15, 12, 12, 10],
	"loop_flags": [true, true, true, false, false, false, false, false],
}

# Phase-4 ADDITIVE CAST state spec. SEPARATE from SPRITE_SPECS: the frozen
# timing arrays above MUST stay exactly 8 entries (asserted by the Phase-3
# tests). CAST is the 9th animation state with its own timing, held here.
const CAST_SPEC := {
	"name": "cast",
	"frames": 7,
	"fps": 12.0,
	"loop": false,
}

# ------------------------------------------------------------------ perf caps
const MAX_PROPS_PER_CHUNK := 58
const MAX_PARTICLES := 300
const DETAIL_DENSITY := 0.43
const MOBILE_PROP_FACTOR := 0.55
const MOBILE_DETAIL_FACTOR := 0.5

# ------------------------------------------------------------------ prop kinds
# Canonical list of every prop kind ProceduralArt can paint. Grouped by role.
const ALL_PROP_KINDS: Array[String] = [
	# original 12
	"glade_tree", "ancient_tree", "rock", "flower", "mushroom", "crystal",
	"bush", "hut", "lantern", "waypoint", "ruin_pillar", "fence",
	# trees
	"willow_tree", "birch_tree", "pine_tree", "blossom_tree", "dead_tree",
	# ground
	"fern", "tall_grass", "reeds", "lily_pad", "moss_rock", "pebble",
	"flower_cluster", "berry_bush", "glow_mushroom",
	# structures
	"cottage", "wooden_bridge", "stone_bridge", "dock", "well", "shrine",
	"ruin_arch", "signpost", "barrel", "cart",
	# magical
	"spirit_bloom", "rune_stone", "crystal_cluster", "wisp_lantern",
	# water
	"waterfall", "river_rock", "foam_ripple",
	# wildlife / ambient
	"butterfly", "moth", "bird", "firefly_sprite",
	# Phase-4 detailed landmark/building silhouettes (6 new kinds)
	"watchtower", "market_stall", "stone_wall", "gazebo", "banner_post", "moon_shrine",
	# PART 5: cool Moonpetal Hollow + village-approach silhouettes (4 new kinds)
	"birch_grove", "moon_lantern", "stone_path", "village_gate",
]

# Role tag drives prop_palette() assembly and variant geometry decisions.
const KIND_CATEGORY := {
	"glade_tree": "tree", "ancient_tree": "tree", "willow_tree": "tree",
	"birch_tree": "tree", "pine_tree": "tree", "blossom_tree": "tree",
	"dead_tree": "tree",
	"flower": "flower", "flower_cluster": "flower", "spirit_bloom": "flower",
	"berry_bush": "flower", "fern": "ground", "tall_grass": "ground",
	"reeds": "ground", "lily_pad": "ground", "glow_mushroom": "ground",
	"mushroom": "ground", "bush": "ground",
	"rock": "simple", "moss_rock": "simple", "pebble": "simple",
	"crystal": "magical", "crystal_cluster": "magical", "rune_stone": "magical",
	"wisp_lantern": "magical", "lantern": "magical",
	"hut": "structure", "cottage": "structure", "wooden_bridge": "structure",
	"stone_bridge": "structure", "dock": "structure", "well": "structure",
	"shrine": "structure", "ruin_arch": "structure", "signpost": "structure",
	"barrel": "structure", "cart": "structure", "waypoint": "structure",
	"ruin_pillar": "structure", "fence": "structure",
	"waterfall": "water", "river_rock": "water", "foam_ripple": "water",
	"butterfly": "wildlife", "moth": "wildlife", "bird": "wildlife",
	"firefly_sprite": "wildlife",
	"watchtower": "structure", "market_stall": "structure",
	"stone_wall": "structure", "gazebo": "structure",
	"banner_post": "structure", "moon_shrine": "structure",
	"birch_grove": "tree", "moon_lantern": "magical",
	"stone_path": "ground", "village_gate": "structure",
}

# >=2 for trees / flowers / structures; 1 for simple props.
const VARIANT_COUNTS := {
	"glade_tree": 3, "ancient_tree": 2, "willow_tree": 3, "birch_tree": 3,
	"pine_tree": 3, "blossom_tree": 3, "dead_tree": 2,
	"rock": 1, "moss_rock": 1, "pebble": 1,
	"flower": 3, "flower_cluster": 3, "spirit_bloom": 3, "berry_bush": 2,
	"fern": 2, "tall_grass": 2, "reeds": 2, "lily_pad": 2,
	"glow_mushroom": 2, "mushroom": 2, "bush": 2,
	"hut": 2, "cottage": 3, "wooden_bridge": 2, "stone_bridge": 2,
	"dock": 2, "well": 2, "shrine": 2, "ruin_arch": 2, "signpost": 2,
	"barrel": 2, "cart": 2, "waypoint": 2, "ruin_pillar": 2, "fence": 2,
	"crystal": 3, "crystal_cluster": 3, "rune_stone": 2, "wisp_lantern": 2,
	"lantern": 2,
	"waterfall": 1, "river_rock": 1, "foam_ripple": 1,
	"butterfly": 1, "moth": 1, "bird": 1, "firefly_sprite": 1,
	"watchtower": 3, "market_stall": 2, "stone_wall": 2,
	"gazebo": 2, "banner_post": 2, "moon_shrine": 3,
	"birch_grove": 3, "moon_lantern": 2, "stone_path": 2, "village_gate": 3,
}

# ------------------------------------------------------------------ public API

## Full lighting/fog/sky description for a named day phase. Unknown names fall
## back to "Day" (and common case/alias variants are normalised).
static func phase(phase_name: String) -> Dictionary:
	if PHASES.has(phase_name):
		var found: Dictionary = PHASES[phase_name]
		return found.duplicate(true)
	var key := phase_name.strip_edges().to_lower()
	var alias: String = ""
	match key:
		"midnight": alias = "Midnight"
		"dawn": alias = "Dawn"
		"morning": alias = "Morning"
		"noon", "day", "midday": alias = "Day"
		"afternoon": alias = "Afternoon"
		"golden hour", "golden_hour", "goldenhour": alias = "Golden Hour"
		"dusk": alias = "Dusk"
		"nightfall": alias = "Nightfall"
		_: alias = "Day"
	var result: Dictionary = PHASES[alias]
	return result.duplicate(true)


## Named colours appropriate to a prop kind. Every supported kind returns a
## non-empty dictionary; unknown kinds fall back to a generic foliage palette.
static func prop_palette(kind: String) -> Dictionary:
	var category := str(KIND_CATEGORY.get(kind, "simple"))
	var palette: Dictionary = {}
	match category:
		"tree":
			palette = {
				"trunk": TIMBER.dark, "trunk_light": TIMBER.light,
				"canopy_deep": CANOPY.deep, "canopy_mid": CANOPY.mid,
				"canopy_light": CANOPY.light, "rim": CANOPY.rim,
				"moss": CANOPY.moss,
			}
			match kind:
				"pine_tree":
					palette["canopy_deep"] = CANOPY.pine
					palette["canopy_light"] = CANOPY.moss
				"birch_tree":
					palette["trunk"] = STONE.light
					palette["trunk_light"] = CANOPY.birch
				"blossom_tree":
					palette["canopy_mid"] = CANOPY.blossom
					palette["petal"] = ACCENTS.petal
				"willow_tree":
					palette["canopy_light"] = CANOPY.bright
				"dead_tree":
					palette["canopy_deep"] = STONE.dark
					palette["canopy_mid"] = STONE.mid
					palette["canopy_light"] = STONE.light
				"ancient_tree":
					palette["rune"] = MAGIC.teal
				"birch_grove":
					# PART 5: pale silver-birch cluster for Moonpetal Hollow.
					palette["trunk"] = CANOPY.birch
					palette["trunk_light"] = STONE.light
					palette["canopy_deep"] = CANOPY.moss
					palette["canopy_mid"] = CANOPY.light
					palette["canopy_light"] = CANOPY.birch
					palette["rim"] = LIGHT.cool_moon
					palette["moss"] = CANOPY.moss
		"flower":
			palette = {
				"stem": UNDERGROWTH.mid, "leaf": UNDERGROWTH.light,
				"petal": ACCENTS.petal, "petal_alt": ACCENTS.petal_alt,
				"center": ACCENTS.petal_alt, "berry": ACCENTS.berry,
			}
			match kind:
				"spirit_bloom":
					palette["petal"] = MAGIC.teal_light
					palette["center"] = MAGIC.teal
					palette["glow"] = LIGHT.magic
				"berry_bush":
					palette["leaf"] = CANOPY.mid
					palette["berry"] = ACCENTS.berry
		"ground":
			palette = {
				"dark": UNDERGROWTH.dark, "mid": UNDERGROWTH.mid,
				"light": UNDERGROWTH.light, "cap_a": CANOPY.mid,
				"cap_b": CANOPY.light,
			}
			match kind:
				"glow_mushroom":
					palette["cap_a"] = ACCENTS.glow_mushroom
					palette["glow"] = LIGHT.magic
				"mushroom":
					palette["cap_a"] = ACCENTS.mushroom_cap
				"reeds":
					palette["light"] = UNDERGROWTH.reeds
				"lily_pad":
					palette["mid"] = UNDERGROWTH.lily
				"stone_path":
					# PART 5: cool cobble path tile (moss between the stones).
					palette["dark"] = STONE.dark
					palette["mid"] = STONE.mid
					palette["light"] = STONE.light
					palette["cap_a"] = STONE.light
					palette["cap_b"] = STONE.moss
					palette["moss"] = STONE.moss
					palette["wet"] = STONE.wet
		"structure":
			palette = {
				"wood": TIMBER.light, "wood_mid": TIMBER.mid,
				"wood_dark": TIMBER.dark, "roof": TIMBER.plank,
				"stone": STONE.mid, "stone_light": STONE.light,
				"moss": CANOPY.moss, "warm": LIGHT.warm_lantern,
			}
			match kind:
				"well", "stone_bridge", "ruin_arch", "shrine", "ruin_pillar", "waypoint":
					palette["wood"] = STONE.mid
					palette["wood_mid"] = STONE.dark
				"cottage":
					palette["roof"] = TIMBER.thatch
				"watchtower":
					palette["roof"] = TIMBER.thatch
					palette["wood"] = TIMBER.mid
					palette["stone"] = STONE.dark
					palette["warm"] = LIGHT.warm_lantern
				"market_stall":
					palette["roof"] = TIMBER.thatch
					palette["warm"] = LIGHT.warm_lantern
				"stone_wall":
					palette["wood"] = STONE.mid
					palette["wood_dark"] = STONE.dark
					palette["roof"] = STONE.dark
					palette["stone"] = STONE.light
					palette["stone_light"] = STONE.mid
					palette["moss"] = CANOPY.moss
				"gazebo":
					palette["roof"] = CANOPY.light
					palette["wood"] = TIMBER.light
					palette["warm"] = LIGHT.warm_lantern
				"banner_post":
					palette["wood_dark"] = TIMBER.dark
					palette["warm"] = MAGIC.gold
				"moon_shrine":
					palette["stone"] = STONE.light
					palette["stone_light"] = CANOPY.birch
					palette["warm"] = LIGHT.cool_moon
					palette["core"] = MAGIC.teal
					palette["glow"] = LIGHT.moon_glow
				"village_gate":
					# PART 5: warm timber + stone gate with a hanging banner.
					palette["roof"] = TIMBER.thatch
					palette["warm"] = LIGHT.warm_lantern
					palette["stone"] = STONE.dark
					palette["banner"] = MAGIC.gold
				"wisp_lantern", "lantern":
					palette["warm"] = LIGHT.warm_lantern
		"magical":
			palette = {
				"core": MAGIC.teal, "light": MAGIC.teal_light,
				"deep": MAGIC.teal_deep, "glow": MAGIC.teal,
				"gold": MAGIC.gold, "rune": ACCENTS.rune,
			}
			match kind:
				"rune_stone":
					palette["core"] = STONE.mid
					palette["light"] = STONE.light
				"wisp_lantern":
					palette["core"] = LIGHT.warm_lantern
				"moon_lantern":
					# PART 5: cool silver-violet fixture for Moonpetal Hollow.
					palette["core"] = LIGHT.cool_moon
					palette["light"] = MAGIC.violet_light
					palette["deep"] = MAGIC.violet
					palette["glow"] = LIGHT.moon_glow
					palette["gold"] = MAGIC.violet_light
					palette["rune"] = LIGHT.cool_moon
					palette["metal"] = STONE.light
		"water":
			palette = {
				"shallow": WATER.shallow, "deep": WATER.deep,
				"foam": WATER.foam, "glint": WATER.glint,
				"stone": STONE.wet, "reflection": WATER.reflection,
			}
		"wildlife":
			palette = {
				"body": ACCENTS.butterfly, "wing": ACCENTS.butterfly,
				"accent": ACCENTS.petal, "glow": LIGHT.magic,
			}
			match kind:
				"moth":
					palette["wing"] = ACCENTS.moth
				"bird":
					palette["body"] = ACCENTS.bird
					palette["wing"] = ACCENTS.bird
				"firefly_sprite":
					palette["body"] = ACCENTS.firefly
					palette["glow"] = ACCENTS.firefly
		_:
			palette = {
				"dark": STONE.dark, "mid": STONE.mid, "light": STONE.light,
				"moss": STONE.moss, "grass": UNDERGROWTH.mid,
			}
	palette["outline"] = INK
	palette["accent"] = MAGIC.teal
	return palette


## Element -> colour (used by actors, VFX and UI badges for consistency).
static func element_color(element: String) -> Color:
	return ELEMENTS.get(element.strip_edges().to_lower(), ELEMENTS["neutral"])


## Every supported prop kind (typed copy).
static func prop_kinds() -> Array[String]:
	var result: Array[String] = []
	for kind in ALL_PROP_KINDS:
		result.append(kind)
	return result


## Number of distinct deterministic variants for a kind (>=2 for complex props).
static func variant_count(kind: String) -> int:
	return int(VARIANT_COUNTS.get(kind, 1))


## Flat array of every named Color in the style, for coherence tests.
static func all_colors() -> Array:
	var colors: Array = []
	for group in [SKY, CANOPY, UNDERGROWTH, WATER, STONE, TIMBER, MAGIC,
			LIGHT, ACCENTS, UI, ELEMENTS]:
		var dict: Dictionary = group
		for key in dict.keys():
			colors.append(dict[key])
	colors.append(INK)
	for phase_name in PHASES.keys():
		var entry: Dictionary = PHASES[phase_name]
		for key in ["tint", "fog", "sky_top", "sky_bottom"]:
			colors.append(entry[key])
	return colors


## Returns [] when the palette is internally consistent, otherwise a list of
## human-readable problems. Used by coherence tests and as a self-check.
static func coherence_report() -> Array[String]:
	var problems: Array[String] = []
	var groups := {
		"SKY": SKY, "CANOPY": CANOPY, "UNDERGROWTH": UNDERGROWTH,
		"WATER": WATER, "STONE": STONE, "TIMBER": TIMBER, "MAGIC": MAGIC,
		"LIGHT": LIGHT, "ACCENTS": ACCENTS, "UI": UI, "ELEMENTS": ELEMENTS,
	}
	for group_name in groups.keys():
		var group: Dictionary = groups[group_name]
		if group.is_empty():
			problems.append("Palette group %s is empty" % group_name)
		for key in group.keys():
			var value: Variant = group[key]
			if typeof(value) != TYPE_COLOR:
				problems.append("%s.%s is not a Color" % [group_name, str(key)])
			else:
				var c: Color = value
				if not _finite_color(c):
					problems.append("%s.%s has non-finite/out-of-range components" % [group_name, str(key)])

	# Required-distinct roles must not collapse into one colour.
	var distinct_pairs := [
		["WATER.shallow", WATER.shallow, WATER.deep],
		["CANOPY.deep/mid", CANOPY.deep, CANOPY.mid],
		["CANOPY.mid/light", CANOPY.mid, CANOPY.light],
		["MAGIC.teal/gold", MAGIC.teal, MAGIC.gold],
		["MAGIC.teal/violet", MAGIC.teal, MAGIC.violet],
		["MAGIC.gold/ember", MAGIC.gold, MAGIC.ember],
		["TIMBER.light/dark", TIMBER.light, TIMBER.dark],
		["STONE.light/dark", STONE.light, STONE.dark],
		["LIGHT.warm/cool", LIGHT.warm_lantern, LIGHT.cool_moon],
	]
	for pair in distinct_pairs:
		var color_a: Color = pair[1]
		var color_b: Color = pair[2]
		if color_a.is_equal_approx(color_b):
			problems.append("%s colours should be distinct but are equal" % str(pair[0]))

	# Every prop kind must have a palette, a variant count and a category.
	for kind in ALL_PROP_KINDS:
		if prop_palette(kind).is_empty():
			problems.append("prop_palette('%s') is empty" % kind)
		if variant_count(kind) < 1:
			problems.append("variant_count('%s') < 1" % kind)
		if not KIND_CATEGORY.has(kind):
			problems.append("KIND_CATEGORY missing '%s'" % kind)
		if not VARIANT_COUNTS.has(kind):
			problems.append("VARIANT_COUNTS missing '%s'" % kind)
	# Complex roles must expose >=2 variants.
	for kind in ALL_PROP_KINDS:
		var category := str(KIND_CATEGORY.get(kind, "simple"))
		if category in ["tree", "flower", "structure"] and variant_count(kind) < 2:
			problems.append("'%s' (%s) must have >=2 variants" % [kind, category])

	# Every required phase must expose every required key with sane types.
	for phase_name in REQUIRED_PHASES:
		var entry := phase(phase_name)
		for key in REQUIRED_PHASE_KEYS:
			if not entry.has(key):
				problems.append("phase('%s') missing key '%s'" % [phase_name, key])
		if typeof(entry.get("tint")) != TYPE_COLOR:
			problems.append("phase('%s').tint is not a Color" % phase_name)
		if typeof(entry.get("fireflies")) != TYPE_BOOL:
			problems.append("phase('%s').fireflies is not a bool" % phase_name)

	# Sprite specs sanity.
	if SPRITE_SPECS.world_width != 96 or SPRITE_SPECS.world_height != 128:
		problems.append("SPRITE_SPECS world size must be 96x128")
	if SPRITE_SPECS.boss_width != 128 or SPRITE_SPECS.boss_height != 192:
		problems.append("SPRITE_SPECS boss size must be 128x192")
	return problems


## "mobile" or "desktop". This is a coarse platform hint, NOT device profiling.
static func performance_tier() -> String:
	var os_name := OS.get_name()
	if os_name == "Android" or os_name == "iOS" or os_name == "Web":
		return "mobile"
	return "desktop"


static func _finite_color(c: Color) -> bool:
	for component in [c.r, c.g, c.b, c.a]:
		var value: float = component
		if is_nan(value) or is_inf(value) or value < -0.001 or value > 1.001:
			return false
	return true
