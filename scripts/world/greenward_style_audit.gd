class_name GreenwardStyleAudit
extends RefCounted
## Read-only colour/spec consistency checks for the Greenward style registry.

## Flat array of every named Color in the style, for coherence tests.
static func all_colors() -> Array:
	var colors: Array = []
	for group in [GreenwardStyle.SKY, GreenwardStyle.CANOPY, GreenwardStyle.UNDERGROWTH, GreenwardStyle.WATER, GreenwardStyle.STONE, GreenwardStyle.TIMBER, GreenwardStyle.MAGIC,
			GreenwardStyle.LIGHT, GreenwardStyle.ACCENTS, GreenwardStyle.UI, GreenwardStyle.ELEMENTS]:
		var dict: Dictionary = group
		for key in dict.keys():
			colors.append(dict[key])
	colors.append(GreenwardStyle.INK)
	for phase_name in GreenwardStyle.PHASES.keys():
		var entry: Dictionary = GreenwardStyle.PHASES[phase_name]
		for key in ["tint", "fog", "sky_top", "sky_bottom"]:
			colors.append(entry[key])
	return colors


## Returns [] when the palette is internally consistent, otherwise a list of
## human-readable problems. Used by coherence tests and as a self-check.
static func coherence_report() -> Array[String]:
	var problems: Array[String] = []
	var groups := {
		"SKY": GreenwardStyle.SKY, "CANOPY": GreenwardStyle.CANOPY, "UNDERGROWTH": GreenwardStyle.UNDERGROWTH,
		"WATER": GreenwardStyle.WATER, "STONE": GreenwardStyle.STONE, "TIMBER": GreenwardStyle.TIMBER, "MAGIC": GreenwardStyle.MAGIC,
		"LIGHT": GreenwardStyle.LIGHT, "ACCENTS": GreenwardStyle.ACCENTS, "UI": GreenwardStyle.UI, "ELEMENTS": GreenwardStyle.ELEMENTS,
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
		["WATER.shallow", GreenwardStyle.WATER.shallow, GreenwardStyle.WATER.deep],
		["CANOPY.deep/mid", GreenwardStyle.CANOPY.deep, GreenwardStyle.CANOPY.mid],
		["CANOPY.mid/light", GreenwardStyle.CANOPY.mid, GreenwardStyle.CANOPY.light],
		["MAGIC.teal/gold", GreenwardStyle.MAGIC.teal, GreenwardStyle.MAGIC.gold],
		["MAGIC.teal/violet", GreenwardStyle.MAGIC.teal, GreenwardStyle.MAGIC.violet],
		["MAGIC.gold/ember", GreenwardStyle.MAGIC.gold, GreenwardStyle.MAGIC.ember],
		["TIMBER.light/dark", GreenwardStyle.TIMBER.light, GreenwardStyle.TIMBER.dark],
		["STONE.light/dark", GreenwardStyle.STONE.light, GreenwardStyle.STONE.dark],
		["LIGHT.warm/cool", GreenwardStyle.LIGHT.warm_lantern, GreenwardStyle.LIGHT.cool_moon],
	]
	for pair in distinct_pairs:
		var color_a: Color = pair[1]
		var color_b: Color = pair[2]
		if color_a.is_equal_approx(color_b):
			problems.append("%s colours should be distinct but are equal" % str(pair[0]))

	# Every prop kind must have a palette, a variant count and a category.
	for kind in GreenwardStyle.ALL_PROP_KINDS:
		if GreenwardStyle.prop_palette(kind).is_empty():
			problems.append("prop_palette('%s') is empty" % kind)
		if GreenwardStyle.variant_count(kind) < 1:
			problems.append("variant_count('%s') < 1" % kind)
		if not GreenwardStyle.KIND_CATEGORY.has(kind):
			problems.append("KIND_CATEGORY missing '%s'" % kind)
		if not GreenwardStyle.VARIANT_COUNTS.has(kind):
			problems.append("VARIANT_COUNTS missing '%s'" % kind)
	# Complex roles must expose >=2 variants.
	for kind in GreenwardStyle.ALL_PROP_KINDS:
		var category := str(GreenwardStyle.KIND_CATEGORY.get(kind, "simple"))
		if category in ["tree", "flower", "structure"] and GreenwardStyle.variant_count(kind) < 2:
			problems.append("'%s' (%s) must have >=2 variants" % [kind, category])

	# Every required phase must expose every required key with sane types.
	for phase_name in GreenwardStyle.REQUIRED_PHASES:
		var entry := GreenwardStyle.phase(phase_name)
		for key in GreenwardStyle.REQUIRED_PHASE_KEYS:
			if not entry.has(key):
				problems.append("phase('%s') missing key '%s'" % [phase_name, key])
		if typeof(entry.get("tint")) != TYPE_COLOR:
			problems.append("phase('%s').tint is not a Color" % phase_name)
		if typeof(entry.get("fireflies")) != TYPE_BOOL:
			problems.append("phase('%s').fireflies is not a bool" % phase_name)

	# Sprite specs sanity.
	if GreenwardStyle.SPRITE_SPECS.world_width != 96 or GreenwardStyle.SPRITE_SPECS.world_height != 128:
		problems.append("SPRITE_SPECS world size must be 96x128")
	if GreenwardStyle.SPRITE_SPECS.boss_width != 128 or GreenwardStyle.SPRITE_SPECS.boss_height != 192:
		problems.append("SPRITE_SPECS boss size must be 128x192")
	return problems


static func _finite_color(c: Color) -> bool:
	for component in [c.r, c.g, c.b, c.a]:
		var value: float = component
		if is_nan(value) or is_inf(value) or value < -0.001 or value > 1.001:
			return false
	return true
