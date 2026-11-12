class_name WorldVisualStandards
extends RefCounted
## WORLD VISUAL STANDARDS — Part 6 of PROJECT FANTASY Phase 5 (FOUNDATION).
##
## "This is a STANDARD/CONTRACT, not final art; all shipped visuals remain
## procedural placeholder." ZERO final assets exist: every sprite, prop, tile
## and backdrop is generated in code at runtime (ProceduralArt / ActorVisual /
## PortraitView / ChunkBuilder shaders). This file records the consistent visual
## contract that FUTURE painted art must satisfy so every category reads as one
## coherent game. It does NOT create or fabricate any art file.
##
## PURE / headless: plain data + GreenwardStyle palette lookups. NO nodes, NO
## SceneTree, NO autoloads, NO generated textures. Deterministic and defensive.

# ------------------------------------------------------------------ constants
# The six world-visual categories.
const CATEGORIES: Array[String] = [
	"player", "npc", "monster", "building", "vegetation", "environment_object",
]

# Valid GreenwardStyle palette group names (single source of truth for colour).
const VALID_PALETTE_GROUPS: Array[String] = [
	"SKY", "CANOPY", "UNDERGROWTH", "WATER", "STONE", "TIMBER",
	"MAGIC", "LIGHT", "ACCENTS", "UI", "ELEMENTS",
]

# Keys every category standard MUST carry (validate() enforces completeness).
const REQUIRED_KEYS: Array[String] = [
	"category", "canvas_width", "canvas_height", "anchor", "outline_px",
	"palette_group", "z_index", "y_sort", "batching_rule", "fallback", "notes",
]

# World-entity categories that must share the bottom-centre anchor / foot rule.
const GROUND_ENTITIES: Array[String] = [
	"player", "npc", "monster", "building", "vegetation",
]

# One coherent standard per category: canvas size, anchor, outline px, palette
# group (from GreenwardStyle), z-index / y-sort, batching rule, fallback, notes.
const STANDARDS: Dictionary = {
	"player": {
		"category": "player",
		"canvas_width": 96, "canvas_height": 128,
		"boss_canvas_width": 128, "boss_canvas_height": 192,
		"anchor": "bottom-centre (0.5, 1.0); feet on ONE identical baseline; Y-sort at the ground point",
		"anchor_vector": Vector2(0.5, 1.0),
		"outline_px": 2,
		"palette_group": "ELEMENTS",
		"palette_groups": ["ELEMENTS", "ACCENTS"],
		"z_index": 10,
		"y_sort": "Y-sorted at the feet ground point; above props, below the HUD",
		"batching_rule": "one SpriteFrames ActorFrameSource per character; cached frames, never per-frame Image generation; no MultiMesh for the player",
		"fallback": "ProceduralActorFrames / ActorVisual procedural placeholder (TEMPORARY); a painted sheet swaps in via ActorVisual.set_frame_source()",
		"notes": "~6-head heroic proportions, soft rounded ally silhouette, 1-2 px dark INK outline, upper-left key light, element-tinted accent from palette. Character palette {hair,primary,secondary,accent,skin} is the identity source.",
	},
	"npc": {
		"category": "npc",
		"canvas_width": 96, "canvas_height": 128,
		"boss_canvas_width": 96, "boss_canvas_height": 128,
		"anchor": "bottom-centre (0.5, 1.0); feet on ONE baseline; Y-sort at the ground point",
		"anchor_vector": Vector2(0.5, 1.0),
		"outline_px": 2,
		"palette_group": "TIMBER",
		"palette_groups": ["TIMBER", "CANOPY", "ACCENTS"],
		"z_index": 8,
		"y_sort": "Y-sorted at the feet ground point; interleaved with other actors",
		"batching_rule": "one cached frame set per NPC id; off-screen actors gate _process/visibility; no per-frame allocation",
		"fallback": "ActorVisual procedural placeholder (TEMPORARY); world_npc.gd / procedural_art.gd",
		"notes": "Village-folk palette (warm TIMBER + CANOPY greens), friendly rounded silhouette, same shared outline/lighting as the player so allies read at a glance.",
	},
	"monster": {
		"category": "monster",
		"canvas_width": 96, "canvas_height": 128,
		"boss_canvas_width": 128, "boss_canvas_height": 192,
		"anchor": "bottom-centre (0.5, 1.0); feet on ONE baseline; Y-sort at the ground point",
		"anchor_vector": Vector2(0.5, 1.0),
		"outline_px": 2,
		"palette_group": "MAGIC",
		"palette_groups": ["MAGIC", "ACCENTS", "ELEMENTS"],
		"z_index": 9,
		"y_sort": "Y-sorted at the feet ground point; hostile silhouette reads above terrain",
		"batching_rule": "one SpriteFrames ActorFrameSource per monster id (Kind.MONSTER via actor_frame_source.gd); cached frames",
		"fallback": "ActorVisual (Kind.MONSTER) procedural placeholder (TEMPORARY); roaming_monster.gd",
		"notes": "Sharper, asymmetric silhouette for corrupted enemies, glowing MAGIC/element accents, 1-2 px dark INK outline. Boss uses the 128x192 elite canvas.",
	},
	"building": {
		"category": "building",
		"canvas_width": 256, "canvas_height": 256,
		"boss_canvas_width": 256, "boss_canvas_height": 256,
		"anchor": "bottom-centre (0.5, 1.0); base on the ground line; Y-sort at ground contact",
		"anchor_vector": Vector2(0.5, 1.0),
		"outline_px": 2,
		"palette_group": "STONE",
		"palette_groups": ["TIMBER", "STONE", "LIGHT", "MAGIC"],
		"z_index": 4,
		"y_sort": "Y-sorted at the ground contact point; large structures sort behind actors",
		"batching_rule": "ProceduralArt.prop_texture(kind, variant) cached by (kind, variant); repeated shells can share a MultiMesh; one draw call target per layer",
		"fallback": "procedural_art.gd _build_prop() / _paint_kind() (TEMPORARY); GreenwardStyle.prop_palette()",
		"notes": "Warm TIMBER planks + cool STONE, mossy tops, warm lantern windows. Variants are deterministic and visually distinct (>=2 for structures), never a flat tint.",
	},
	"vegetation": {
		"category": "vegetation",
		"canvas_width": 128, "canvas_height": 160,
		"boss_canvas_width": 128, "boss_canvas_height": 160,
		"anchor": "bottom-centre (0.5, 1.0); trunk base on the ground line",
		"anchor_vector": Vector2(0.5, 1.0),
		"outline_px": 2,
		"palette_group": "CANOPY",
		"palette_groups": ["CANOPY", "UNDERGROWTH", "MAGIC"],
		"z_index": 3,
		"y_sort": "Y-sorted at the trunk base; foliage uses base-anchored wind_sway.gdshader UV origin",
		"batching_rule": "MultiMesh ground-cover detail layer (one extra draw call per chunk); canopy props via cached prop_texture(); density capped by DETAIL_DENSITY",
		"fallback": "GreenwardStyle.prop_palette() + procedural_art.gd tree / fern / flower painters (TEMPORARY)",
		"notes": "Layered CANOPY/UNDERGROWTH greens with cool rim highlights, rounded soft silhouettes, base-anchored wind sway, 1-2 px outline.",
	},
	"environment_object": {
		"category": "environment_object",
		"canvas_width": 128, "canvas_height": 160,
		"boss_canvas_width": 256, "boss_canvas_height": 256,
		"anchor": "bottom-centre (0.5, 1.0) for props; tile-centre (0.0, 0.0) grid origin for terrain",
		"anchor_vector": Vector2(0.5, 1.0),
		"outline_px": 1,
		"palette_group": "UNDERGROWTH",
		"palette_groups": ["STONE", "WATER", "UNDERGROWTH", "SKY"],
		"z_index": 0,
		"y_sort": "below all actors; terrain/water/detail are separate MultiMesh layers per chunk, sorted by layer not per-tile",
		"batching_rule": "ChunkBuilder MultiMesh terrain + water + detail; ONE draw call per layer per chunk; NO per-tile sprites",
		"fallback": "terrain.gdshader / water.gdshader / detail.gdshader + procedural_art.gd (TEMPORARY)",
		"notes": "2:1 iso diamond tiles with transparent corners (never square visible corners); STONE/WATER/UNDERGROWTH palette; day-phase lighting and fog from GreenwardStyle.phase().",
	},
}

# ------------------------------------------------------------------ public API

## Fresh typed copy of the six categories.
static func categories() -> Array[String]:
	var out: Array[String] = []
	for c in CATEGORIES:
		out.append(c)
	return out


## Deep copy of one category standard, or {} for an unknown category.
static func standard(category: String) -> Dictionary:
	if STANDARDS.has(category):
		return (STANDARDS[category] as Dictionary).duplicate(true)
	return {}


## Greenward emerald vs moonpetal_hollow silver-violet region tint. Colours are
## built from GreenwardStyle palette groups (deterministic, finite, distinct).
## Unknown regions fall back to the greenward emerald tint.
static func region_tint(region_id: String) -> Color:
	var key := region_id.strip_edges().to_lower()
	if key == "moonpetal_hollow" or key == "moonpetal" or key == "moonpetal_vale":
		var cool: Color = GreenwardStyle.LIGHT["cool_moon"]
		var violet: Color = GreenwardStyle.MAGIC["violet"]
		return cool.lerp(violet, 0.35)
	var canopy: Color = GreenwardStyle.CANOPY["light"]
	var teal: Color = GreenwardStyle.MAGIC["teal"]
	return canopy.lerp(teal, 0.35)


## [] when all six categories have complete, coherent standards; precise errors
## otherwise. Checks completeness, valid palette groups, outline bounds, shared
## anchors for ground entities and distinct region tints.
static func validate() -> Array[String]:
	var errors: Array[String] = []
	# uniqueness + count
	var seen: Dictionary = {}
	for c in CATEGORIES:
		if seen.has(c):
			errors.append("duplicate category '%s' in CATEGORIES" % c)
		seen[c] = true
	if CATEGORIES.size() != 6:
		errors.append("expected 6 categories, found %d" % CATEGORIES.size())
	if STANDARDS.size() != CATEGORIES.size():
		errors.append("STANDARDS has %d entries, expected %d" % [STANDARDS.size(), CATEGORIES.size()])
	for c in CATEGORIES:
		if not STANDARDS.has(c):
			errors.append("STANDARDS missing category '%s'" % c)
			continue
		var s: Dictionary = STANDARDS[c]
		for key in REQUIRED_KEYS:
			if not s.has(key):
				errors.append("category '%s' missing key '%s'" % [c, key])
				continue
			var v: Variant = s[key]
			if typeof(v) == TYPE_STRING and str(v).strip_edges().is_empty():
				errors.append("category '%s' key '%s' is empty" % [c, key])
			elif (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and int(v) <= 0 and key != "z_index":
				errors.append("category '%s' key '%s' must be positive" % [c, key])
		# palette group must be a real GreenwardStyle group
		if not VALID_PALETTE_GROUPS.has(str(s.get("palette_group", ""))):
			errors.append("category '%s' palette_group '%s' is not a GreenwardStyle group" % [c, str(s.get("palette_group", ""))])
		for g in (s.get("palette_groups", []) as Array):
			if not VALID_PALETTE_GROUPS.has(str(g)):
				errors.append("category '%s' palette_groups contains invalid group '%s'" % [c, str(g)])
		# outline bounds 1-2 px
		var outline := int(s.get("outline_px", 0))
		if outline < 1 or outline > 2:
			errors.append("category '%s' outline_px %d must be 1-2 px" % [c, outline])
		# canvas sanity
		if int(s.get("canvas_width", 0)) <= 0 or int(s.get("canvas_height", 0)) <= 0:
			errors.append("category '%s' canvas dimensions must be positive" % c)
	# coherence: ground entities share the bottom-centre anchor vector.
	var ref: Vector2 = (STANDARDS["player"] as Dictionary).get("anchor_vector", Vector2.ZERO) as Vector2
	for c in GROUND_ENTITIES:
		if not STANDARDS.has(c):
			continue
		var av: Vector2 = (STANDARDS[c] as Dictionary).get("anchor_vector", Vector2.ZERO) as Vector2
		if not av.is_equal_approx(ref):
			errors.append("category '%s' anchor_vector %s does not match the shared bottom-centre anchor %s" % [c, str(av), str(ref)])
	# region tints must be finite and distinct
	var g := region_tint("greenward")
	var m := region_tint("moonpetal_hollow")
	if g.is_equal_approx(m):
		errors.append("greenward and moonpetal_hollow region tints must be distinct")
	for t in [g, m]:
		for comp in [t.r, t.g, t.b, t.a]:
			if is_nan(comp) or is_inf(comp):
				errors.append("region_tint produced a non-finite Color")
				break
	return errors


## Compact machine-readable summary of the whole standard.
static func summary() -> Dictionary:
	var canvases: Dictionary = {}
	var outlines: Dictionary = {}
	for c in CATEGORIES:
		var s: Dictionary = STANDARDS[c]
		canvases[c] = [int(s["canvas_width"]), int(s["canvas_height"])]
		outlines[c] = int(s["outline_px"])
	return {
		"category_count": CATEGORIES.size(),
		"categories": categories(),
		"canvas_sizes": canvases,
		"outline_px": outlines,
		"shared_anchor": Vector2(0.5, 1.0),
		"outline_range": [1, 2],
		"palette_groups": VALID_PALETTE_GROUPS.duplicate(),
		"region_tints": {
			"greenward": region_tint("greenward"),
			"moonpetal_hollow": region_tint("moonpetal_hollow"),
		},
		"validation_errors": validate(),
		"note": "This is a STANDARD/CONTRACT, not final art; all shipped visuals remain procedural placeholder. ZERO final assets exist.",
	}


## How to APPLY the standard (per-category notes + shared rules). Guidance for a
## future art/production round; it changes NO rendering behaviour today.
static func apply_notes() -> Dictionary:
	var per_category: Dictionary = {}
	for c in CATEGORIES:
		per_category[c] = str((STANDARDS[c] as Dictionary).get("notes", ""))
	return {
		"shared_rules": [
			"Read every colour from GreenwardStyle (no stray inline hex in new art code).",
			"Keep a 1-2 px dark INK outline and a consistent upper-left key light at 1x.",
			"World actors keep feet on ONE identical baseline; anchor bottom-centre (0.5, 1.0), Y-sort at the ground point.",
			"Transparent RGBA8 PNG/WebP (sRGB); Linear filter; mipmaps ON for world art, OFF for UI/VFX; fix alpha border ON for atlases.",
			"No baked UI text, no copyrighted reference traces, no colour-only element coding (pair colour with a shape/icon).",
			"Keep the procedural fallback for missing assets so content never crashes.",
			"One draw call per terrain/water/detail layer; cache prop textures by (kind, variant); no per-frame Image generation.",
		],
		"per_category": per_category,
		"replacement_seams": {
			"player": "ActorVisual.set_frame_source(SpriteFramesActorSource.from_disk(<id>))",
			"npc": "ActorVisual (Kind.NPC) / world_npc.gd frame source",
			"monster": "ActorVisual (Kind.MONSTER) via actor_frame_source.gd + SpriteFramesActorSource",
			"building": "procedural_art.gd _build_prop() / _paint_kind() + GreenwardStyle.prop_palette()",
			"vegetation": "procedural_art.gd foliage painters + GreenwardStyle.prop_palette()",
			"environment_object": "chunk_builder.gd terrain MultiMesh + procedural_art.gd prop_texture()",
		},
		"note": "This is a STANDARD/CONTRACT, not final art; all shipped visuals remain procedural placeholder.",
	}
