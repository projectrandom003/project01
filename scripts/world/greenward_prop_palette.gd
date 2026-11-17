class_name GreenwardPropPalette
extends RefCounted
## Pure prop-kind palette assembly, split from the world-wide visual standards registry.

static func palette(kind: String) -> Dictionary:
	var category := str(GreenwardStyle.KIND_CATEGORY.get(kind, "simple"))
	var palette: Dictionary = {}
	match category:
		"tree":
			palette = _tree_palette(kind)
		"flower":
			palette = _flower_palette(kind)
		"ground":
			palette = _ground_palette(kind)
		"structure":
			palette = _structure_palette(kind)
		"magical":
			palette = _magical_palette(kind)
		"water":
			palette = _water_palette(kind)
		"wildlife":
			palette = _wildlife_palette(kind)
		_:
			palette = _fallback_palette()

	palette["outline"] = GreenwardStyle.INK
	palette["accent"] = GreenwardStyle.MAGIC.teal
	return palette


static func _tree_palette(kind: String) -> Dictionary:
	var palette: Dictionary = {
		"trunk": GreenwardStyle.TIMBER.dark, "trunk_light": GreenwardStyle.TIMBER.light,
		"canopy_deep": GreenwardStyle.CANOPY.deep, "canopy_mid": GreenwardStyle.CANOPY.mid,
		"canopy_light": GreenwardStyle.CANOPY.light, "rim": GreenwardStyle.CANOPY.rim,
		"moss": GreenwardStyle.CANOPY.moss,
	}
	match kind:
		"pine_tree":
			palette["canopy_deep"] = GreenwardStyle.CANOPY.pine
			palette["canopy_light"] = GreenwardStyle.CANOPY.moss
		"birch_tree":
			palette["trunk"] = GreenwardStyle.STONE.light
			palette["trunk_light"] = GreenwardStyle.CANOPY.birch
		"blossom_tree":
			palette["canopy_mid"] = GreenwardStyle.CANOPY.blossom
			palette["petal"] = GreenwardStyle.ACCENTS.petal
		"willow_tree":
			palette["canopy_light"] = GreenwardStyle.CANOPY.bright
		"dead_tree":
			palette["canopy_deep"] = GreenwardStyle.STONE.dark
			palette["canopy_mid"] = GreenwardStyle.STONE.mid
			palette["canopy_light"] = GreenwardStyle.STONE.light
		"ancient_tree":
			palette["rune"] = GreenwardStyle.MAGIC.teal
		"birch_grove":
			# PART 5: pale silver-birch cluster for Moonpetal Hollow.
			palette["trunk"] = GreenwardStyle.CANOPY.birch
			palette["trunk_light"] = GreenwardStyle.STONE.light
			palette["canopy_deep"] = GreenwardStyle.CANOPY.moss
			palette["canopy_mid"] = GreenwardStyle.CANOPY.light
			palette["canopy_light"] = GreenwardStyle.CANOPY.birch
			palette["rim"] = GreenwardStyle.LIGHT.cool_moon
			palette["moss"] = GreenwardStyle.CANOPY.moss
	return palette


static func _flower_palette(kind: String) -> Dictionary:
	var palette: Dictionary = {
		"stem": GreenwardStyle.UNDERGROWTH.mid, "leaf": GreenwardStyle.UNDERGROWTH.light,
		"petal": GreenwardStyle.ACCENTS.petal, "petal_alt": GreenwardStyle.ACCENTS.petal_alt,
		"center": GreenwardStyle.ACCENTS.petal_alt, "berry": GreenwardStyle.ACCENTS.berry,
	}
	match kind:
		"spirit_bloom":
			palette["petal"] = GreenwardStyle.MAGIC.teal_light
			palette["center"] = GreenwardStyle.MAGIC.teal
			palette["glow"] = GreenwardStyle.LIGHT.magic
		"berry_bush":
			palette["leaf"] = GreenwardStyle.CANOPY.mid
			palette["berry"] = GreenwardStyle.ACCENTS.berry
	return palette


static func _ground_palette(kind: String) -> Dictionary:
	var palette: Dictionary = {
		"dark": GreenwardStyle.UNDERGROWTH.dark, "mid": GreenwardStyle.UNDERGROWTH.mid,
		"light": GreenwardStyle.UNDERGROWTH.light, "cap_a": GreenwardStyle.CANOPY.mid,
		"cap_b": GreenwardStyle.CANOPY.light,
	}
	match kind:
		"glow_mushroom":
			palette["cap_a"] = GreenwardStyle.ACCENTS.glow_mushroom
			palette["glow"] = GreenwardStyle.LIGHT.magic
		"mushroom":
			palette["cap_a"] = GreenwardStyle.ACCENTS.mushroom_cap
		"reeds":
			palette["light"] = GreenwardStyle.UNDERGROWTH.reeds
		"lily_pad":
			palette["mid"] = GreenwardStyle.UNDERGROWTH.lily
		"stone_path":
			# PART 5: cool cobble path tile (moss between the stones).
			palette["dark"] = GreenwardStyle.STONE.dark
			palette["mid"] = GreenwardStyle.STONE.mid
			palette["light"] = GreenwardStyle.STONE.light
			palette["cap_a"] = GreenwardStyle.STONE.light
			palette["cap_b"] = GreenwardStyle.STONE.moss
			palette["moss"] = GreenwardStyle.STONE.moss
			palette["wet"] = GreenwardStyle.STONE.wet
	return palette


static func _structure_palette(kind: String) -> Dictionary:
	var palette: Dictionary = {
		"wood": GreenwardStyle.TIMBER.light, "wood_mid": GreenwardStyle.TIMBER.mid,
		"wood_dark": GreenwardStyle.TIMBER.dark, "roof": GreenwardStyle.TIMBER.plank,
		"stone": GreenwardStyle.STONE.mid, "stone_light": GreenwardStyle.STONE.light,
		"moss": GreenwardStyle.CANOPY.moss, "warm": GreenwardStyle.LIGHT.warm_lantern,
	}
	match kind:
		"well", "stone_bridge", "ruin_arch", "shrine", "ruin_pillar", "waypoint":
			palette["wood"] = GreenwardStyle.STONE.mid
			palette["wood_mid"] = GreenwardStyle.STONE.dark
		"cottage":
			palette["roof"] = GreenwardStyle.TIMBER.thatch
		"watchtower":
			palette["roof"] = GreenwardStyle.TIMBER.thatch
			palette["wood"] = GreenwardStyle.TIMBER.mid
			palette["stone"] = GreenwardStyle.STONE.dark
			palette["warm"] = GreenwardStyle.LIGHT.warm_lantern
		"market_stall":
			palette["roof"] = GreenwardStyle.TIMBER.thatch
			palette["warm"] = GreenwardStyle.LIGHT.warm_lantern
		"stone_wall":
			palette["wood"] = GreenwardStyle.STONE.mid
			palette["wood_dark"] = GreenwardStyle.STONE.dark
			palette["roof"] = GreenwardStyle.STONE.dark
			palette["stone"] = GreenwardStyle.STONE.light
			palette["stone_light"] = GreenwardStyle.STONE.mid
			palette["moss"] = GreenwardStyle.CANOPY.moss
		"gazebo":
			palette["roof"] = GreenwardStyle.CANOPY.light
			palette["wood"] = GreenwardStyle.TIMBER.light
			palette["warm"] = GreenwardStyle.LIGHT.warm_lantern
		"banner_post":
			palette["wood_dark"] = GreenwardStyle.TIMBER.dark
			palette["warm"] = GreenwardStyle.MAGIC.gold
		"moon_shrine":
			palette["stone"] = GreenwardStyle.STONE.light
			palette["stone_light"] = GreenwardStyle.CANOPY.birch
			palette["warm"] = GreenwardStyle.LIGHT.cool_moon
			palette["core"] = GreenwardStyle.MAGIC.teal
			palette["glow"] = GreenwardStyle.LIGHT.moon_glow
		"village_gate":
			# PART 5: warm timber + stone gate with a hanging banner.
			palette["roof"] = GreenwardStyle.TIMBER.thatch
			palette["warm"] = GreenwardStyle.LIGHT.warm_lantern
			palette["stone"] = GreenwardStyle.STONE.dark
			palette["banner"] = GreenwardStyle.MAGIC.gold
		"bench":
			# Village seating: keep the shared timber palette, glow softly at night.
			palette["warm"] = GreenwardStyle.LIGHT.warm_lantern
		"crate":
			# Packed market/goods crate: plank-toned faces, dark framing.
			palette["wood"] = GreenwardStyle.TIMBER.plank
			palette["stone"] = GreenwardStyle.TIMBER.dark
		"wisp_lantern", "lantern":
			palette["warm"] = GreenwardStyle.LIGHT.warm_lantern
	return palette


static func _magical_palette(kind: String) -> Dictionary:
	var palette: Dictionary = {
		"core": GreenwardStyle.MAGIC.teal, "light": GreenwardStyle.MAGIC.teal_light,
		"deep": GreenwardStyle.MAGIC.teal_deep, "glow": GreenwardStyle.MAGIC.teal,
		"gold": GreenwardStyle.MAGIC.gold, "rune": GreenwardStyle.ACCENTS.rune,
	}
	match kind:
		"rune_stone":
			palette["core"] = GreenwardStyle.STONE.mid
			palette["light"] = GreenwardStyle.STONE.light
		"wisp_lantern":
			palette["core"] = GreenwardStyle.LIGHT.warm_lantern
		"moon_lantern":
			# PART 5: cool silver-violet fixture for Moonpetal Hollow.
			palette["core"] = GreenwardStyle.LIGHT.cool_moon
			palette["light"] = GreenwardStyle.MAGIC.violet_light
			palette["deep"] = GreenwardStyle.MAGIC.violet
			palette["glow"] = GreenwardStyle.LIGHT.moon_glow
			palette["gold"] = GreenwardStyle.MAGIC.violet_light
			palette["rune"] = GreenwardStyle.LIGHT.cool_moon
			palette["metal"] = GreenwardStyle.STONE.light
	return palette


static func _water_palette(kind: String) -> Dictionary:
	var palette: Dictionary = {
		"shallow": GreenwardStyle.WATER.shallow, "deep": GreenwardStyle.WATER.deep,
		"foam": GreenwardStyle.WATER.foam, "glint": GreenwardStyle.WATER.glint,
		"stone": GreenwardStyle.STONE.wet, "reflection": GreenwardStyle.WATER.reflection,
	}
	return palette


static func _wildlife_palette(kind: String) -> Dictionary:
	var palette: Dictionary = {
		"body": GreenwardStyle.ACCENTS.butterfly, "wing": GreenwardStyle.ACCENTS.butterfly,
		"accent": GreenwardStyle.ACCENTS.petal, "glow": GreenwardStyle.LIGHT.magic,
	}
	match kind:
		"moth":
			palette["wing"] = GreenwardStyle.ACCENTS.moth
		"bird":
			palette["body"] = GreenwardStyle.ACCENTS.bird
			palette["wing"] = GreenwardStyle.ACCENTS.bird
		"firefly_sprite":
			palette["body"] = GreenwardStyle.ACCENTS.firefly
			palette["glow"] = GreenwardStyle.ACCENTS.firefly
	return palette


static func _fallback_palette() -> Dictionary:
	var palette: Dictionary = {
		"dark": GreenwardStyle.STONE.dark, "mid": GreenwardStyle.STONE.mid, "light": GreenwardStyle.STONE.light,
		"moss": GreenwardStyle.STONE.moss, "grass": GreenwardStyle.UNDERGROWTH.mid,
	}
	return palette
