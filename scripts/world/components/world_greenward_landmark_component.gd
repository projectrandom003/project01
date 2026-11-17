class_name WorldGreenwardLandmarkComponent
extends Node
## Dedicated child node for one Greenward composition responsibility.

var world: GreenwardWorld
var composition_data: GreenwardCompositionData

func configure(owner_world: GreenwardWorld, data: GreenwardCompositionData) -> void:
	world = owner_world
	composition_data = data

func _anchor(anchor_name: String, fallback: Vector2) -> Vector2:
	if composition_data == null:
		return fallback
	var value: Variant = composition_data.anchors.get(anchor_name, fallback)
	return value if typeof(value) == TYPE_VECTOR2 else fallback

func build_landmarks() -> void:
	# ---- The Listening Stones (cool teal ruin) ----
	var ruin_center := _anchor("listening_stones", Vector2(2, 20))
	var offsets := [Vector2(-1.4, 0), Vector2(1.4, 0), Vector2(0, -1.4), Vector2(0, 1.4)]
	for index in offsets.size():
		world.add_prop("ruin_pillar", ruin_center + offsets[index], 0.9 + 0.1 * (index % 2), index % 2 == 0, index % 2)
	world.add_prop("ruin_arch", ruin_center + Vector2(0, -2.2), 1.0, false, 0)
	world.add_prop("rune_stone", ruin_center + Vector2(-2.0, 1.0), 0.9, false, 1)
	world.add_prop("rune_stone", ruin_center + Vector2(2.0, 1.2), 0.85, true, 0)
	world.add_prop("crystal_cluster", ruin_center + Vector2(0, 0.2), 1.2, false, 1)
	world.add_prop("spirit_bloom", ruin_center + Vector2(-1.2, -1.4), 0.9, false, 2)
	world.add_prop("glow_mushroom", ruin_center + Vector2(1.4, -1.2), 0.9, true, 1)
	world.add_prop("wisp_lantern", ruin_center + Vector2(2.0, -0.6), 0.9, false, 0)
	world.add_light(ruin_center, GreenwardStyle.MAGIC.teal, 1.4, 2.6)
	world.add_light(ruin_center + Vector2(0, -2.2), GreenwardStyle.LIGHT.magic, 1.0, 2.0)

	# ---- The Hollowed Grove (dead trees, darker/corrupted violet palette) ----
	var grove_center := _anchor("hollowed_grove", Vector2(26, 16))
	var grove_offsets := [
		Vector2(-2.6, -0.8), Vector2(2.6, -0.8), Vector2(-2.2, 1.8),
		Vector2(2.2, 1.8), Vector2(0, -2.8), Vector2(0, 2.8),
	]
	for index in grove_offsets.size():
		world.add_prop("dead_tree", grove_center + grove_offsets[index], 0.85, index % 2 == 0, index % 2)
	world.add_prop("crystal_cluster", grove_center + Vector2(-1.5, 0.5), 1.0, true, 2)
	world.add_prop("crystal_cluster", grove_center + Vector2(1.5, 0.5), 0.9, false, 1)
	world.add_prop("rune_stone", grove_center + Vector2(0, -1.8), 0.95, false, 1)
	world.add_prop("glow_mushroom", grove_center + Vector2(-2.0, 1.4), 0.9, false, 1)
	world.add_prop("glow_mushroom", grove_center + Vector2(2.0, 1.2), 0.85, true, 0)
	world.add_prop("spirit_bloom", grove_center + Vector2(0.8, 1.6), 0.9, false, 1)
	world.add_light(grove_center, GreenwardStyle.MAGIC.violet, 1.2, 2.8)
	world.add_light(grove_center + Vector2(-1.5, 0.5), GreenwardStyle.MAGIC.violet_light, 0.9, 1.8)

	# ---- NEW: Moonpetal Shrine (magical wisp glade) ----
	var glade := _anchor("moonpetal_glade", Vector2(18, 5))
	var glade_trees := [
		["birch_tree", glade + Vector2(-2.0, -1.4)], ["blossom_tree", glade + Vector2(2.0, -1.2)],
		["willow_tree", glade + Vector2(-1.0, 1.6)], ["pine_tree", glade + Vector2(1.6, 1.4)],
	]
	for index in glade_trees.size():
		world.add_prop(str(glade_trees[index][0]), glade_trees[index][1], 0.9, index % 2 == 0, index % 3)
	world.add_prop("shrine", glade, 1.0, false, 1)
	world.add_prop("spirit_bloom", glade + Vector2(-1.4, 0.6), 1.0, false, 0)
	world.add_prop("spirit_bloom", glade + Vector2(1.4, 0.8), 0.9, true, 2)
	world.add_prop("glow_mushroom", glade + Vector2(-1.0, 1.4), 0.9, false, 1)
	world.add_prop("glow_mushroom", glade + Vector2(1.0, 1.6), 0.85, true, 0)
	world.add_prop("crystal_cluster", glade + Vector2(0, -1.6), 1.0, false, 0)
	world.add_prop("wisp_lantern", glade + Vector2(-1.8, -0.4), 0.9, false, 1)
	world.add_prop("wisp_lantern", glade + Vector2(1.8, -0.2), 0.9, true, 0)
	world.add_light(glade, GreenwardStyle.MAGIC.teal, 1.2, 2.6)
	world.add_light(glade + Vector2(0, -1.6), GreenwardStyle.MAGIC.violet_light, 0.9, 1.8)
	world.add_light(glade + Vector2(-1.8, -0.4), GreenwardStyle.LIGHT.warm_lantern, 0.8, 1.6)

	# Phase-4 detailed landmarks: a watchtower over the Listening Stones and a
	# moon shrine beside the Moonpetal glade. Lights self-cap at MAX_LIGHTS.
	world.add_prop("watchtower", ruin_center + Vector2(-3.2, -1.8), 0.9, false, 0)
	world.add_prop("moon_shrine", glade + Vector2(2.8, -0.6), 0.9, false, 0)
	world.add_light(ruin_center + Vector2(-3.2, -1.8), GreenwardStyle.LIGHT.warm_lantern, 0.8, 1.8)
	world.add_light(glade + Vector2(2.8, -0.6), GreenwardStyle.LIGHT.cool_moon, 1.0, 2.2)


# ------------------------------- PART 4: extra Greenward landmarks / routes
# All use EXISTING prop kinds and GreenwardStyle colours. Bounded by the MAX_*
# caps; interaction props never mutate GameState.

func build_extra_landmarks() -> void:
	# 1) Hilltop watch — a recognisable ruin silhouette above the eastern rise.
	var watch := _anchor("hilltop_watch", Vector2(30, 6))
	world.add_prop("ruin_arch", watch, 1.1, false, 1)
	world.add_prop("ruin_pillar", watch + Vector2(-1.6, 0.4), 0.9, false, 0)
	world.add_prop("ruin_pillar", watch + Vector2(1.6, 0.4), 0.9, true, 1)
	world.add_prop("crystal_cluster", watch + Vector2(0, 1.4), 1.1, false, 2)
	world.add_prop("wisp_lantern", watch + Vector2(-1.2, -1.2), 0.9, false, 0)
	world.add_prop("wisp_lantern", watch + Vector2(1.2, -1.2), 0.9, true, 1)
	world.add_light(watch, GreenwardStyle.MAGIC.teal, 1.3, 2.6)
	world.add_light(watch + Vector2(0, 1.4), GreenwardStyle.MAGIC.violet_light, 0.8, 1.8)
	if world.can_add_interactive_prop():
		world.add_interactive_prop("rune_stone", _anchor("hilltop_dial", Vector2(48, 18)), "Hilltop Dial", "It points to a road the maps have forgotten.", 1)

	# 2) Market row — a readable cart/barrel/signpost/well composition near the hub.
	var market := _anchor("market_row", Vector2(13, 8))
	world.add_prop("cart", market, 1.0, false, 0)
	world.add_prop("barrel", market + Vector2(-1.0, 0.6), 0.9, false, 0)
	world.add_prop("barrel", market + Vector2(0.9, 0.8), 0.85, true, 1)
	world.add_prop("signpost", market + Vector2(0.2, -1.0), 0.95, false, 1)
	world.add_prop("well", market + Vector2(1.8, 0.2), 0.9, false, 1)
	world.add_light(market, GreenwardStyle.LIGHT.warm_lantern, 1.0, 2.0)
	if world.can_add_interactive_prop():
		world.add_interactive_prop("signpost", _anchor("traders_sign", Vector2(-10, -22)), "Trader's Sign", "Arrows scratch toward every corner of the glade.", 0)

	# 3) Lakeside composition — a dock + wooden bridge by the decorative river.
	var lakeside := _anchor("lakeside", Vector2(6.4, 15.0))
	world.add_prop("dock", lakeside, 1.0, false, 0)
	world.add_prop("wooden_bridge", lakeside + Vector2(2.0, 0.4), 0.95, false, 1)
	world.add_prop("river_rock", lakeside + Vector2(-1.4, 0.6), 0.9, false, 0)
	world.add_prop("reeds", lakeside + Vector2(1.2, 1.2), 0.9, false, 1)
	world.add_light(lakeside, GreenwardStyle.WATER.glint, 0.9, 1.8)
	if world.can_add_interactive_prop():
		world.add_interactive_prop("dock", _anchor("old_mooring", Vector2(16, 52)), "Old Mooring", "The rope is worn smooth by a hundred quiet departures.", 0)

	# PART 5 (World Presentation): a recognisable village-gate approach built
	# from the new silhouette kinds. Consistent with WorldVisualStandards (warm
	# lights, bottom-centre anchors, GreenwardStyle colours). ZERO final assets.
	build_greenward_gate_composition()
	build_elder_hollow_territory()
	build_fallen_matron_territory()

func build_elder_hollow_territory() -> void:
	# Remote ancient-tree sanctuary at the north-western edge of Greenward.
	# The ring of colossal roots and old growth makes this a distinct boss biome.
	var c := _anchor("elder_hollow", Vector2(-88, 76))
	var trees := [
		["ancient_tree", c + Vector2(-7, -4), 1.34], ["willow_tree", c + Vector2(7, -5), 1.18],
		["dead_tree", c + Vector2(-9, 6), 1.22], ["ancient_tree", c + Vector2(9, 8), 1.30],
		["pine_tree", c + Vector2(0, -11), 1.16], ["birch_tree", c + Vector2(-13, 1), 0.98],
		["willow_tree", c + Vector2(13, 1), 1.08],
	]
	for i in trees.size():
		var e: Array = trees[i]
		world.add_prop(str(e[0]), e[1], float(e[2]), i % 2 == 0, i % 3)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var pos := c + Vector2(cos(a) * 7.0, sin(a) * 5.0)
		world.add_prop("moss_rock" if i % 2 == 0 else "rune_stone", pos, 0.88 + float(i % 3) * 0.12, i % 2 == 0, i % 3)
	world.add_prop("spirit_bloom", c + Vector2(-2.2, 2.0), 1.35, false, 2)
	world.add_prop("spirit_bloom", c + Vector2(2.4, 1.8), 1.18, true, 1)
	world.add_prop("glow_mushroom", c + Vector2(-4.0, 3.0), 1.2, false, 1)
	world.add_prop("glow_mushroom", c + Vector2(4.0, 3.2), 1.05, true, 0)
	world.add_prop("crystal_cluster", c + Vector2(0, -3.0), 1.18, false, 2)
	world.add_light(c, GreenwardStyle.MAGIC.teal, 1.45, 3.2)
	world.add_light(c + Vector2(0, -3.0), GreenwardStyle.MAGIC.violet_light, 1.0, 2.3)

func build_fallen_matron_territory() -> void:
	# Remote Withered Estate in the south-east: ruined conservatory, rose
	# thorns, broken stonework and pale blooms. Kept separate from the First Tree.
	var c := _anchor("withered_estate", Vector2(116, 78))
	var trees := [
		["dead_tree", c + Vector2(-10, -8), 1.25], ["blossom_tree", c + Vector2(10, -8), 1.28],
		["willow_tree", c + Vector2(-13, 5), 1.16], ["dead_tree", c + Vector2(13, 7), 1.32],
		["birch_tree", c + Vector2(-1, -12), 1.08], ["blossom_tree", c + Vector2(3, 13), 1.18],
	]
	for i in trees.size():
		var e: Array = trees[i]
		world.add_prop(str(e[0]), e[1], float(e[2]), i % 2 == 0, i % 3)
	world.add_prop("ruin_arch", c + Vector2(0, -4.0), 1.42, false, 2)
	world.add_prop("ruin_pillar", c + Vector2(-5.0, -1.0), 1.22, false, 1)
	world.add_prop("ruin_pillar", c + Vector2(5.0, -0.6), 1.12, true, 0)
	world.add_prop("shrine", c, 1.18, false, 2)
	world.add_prop("crystal_cluster", c + Vector2(-2.4, 2.0), 1.22, false, 2)
	world.add_prop("crystal_cluster", c + Vector2(2.4, 2.2), 1.10, true, 1)
	world.add_prop("flower_cluster", c + Vector2(-6.0, 4.0), 1.52, false, 2)
	world.add_prop("flower_cluster", c + Vector2(6.0, 4.2), 1.42, true, 1)
	world.add_prop("spirit_bloom", c + Vector2(0, 5.0), 1.35, false, 2)
	world.add_light(c, GreenwardStyle.MAGIC.violet, 1.55, 3.4)
	world.add_light(c + Vector2(0, -4.0), GreenwardStyle.MAGIC.violet_light, 1.1, 2.4)

func build_greenward_gate_composition() -> void:
	var gate := _anchor("village_gate", Vector2(8, 3.6))
	world.add_prop("village_gate", gate, 1.0, false, 0)
	for i in 3:
		world.add_prop("stone_path", gate + Vector2(0, 0.8 + i * 0.8), 0.95, false, i % 2)
	world.add_prop("banner_post", gate + Vector2(-1.8, 0.6), 0.9, false, 0)
	world.add_prop("banner_post", gate + Vector2(1.8, 0.6), 0.9, true, 1)
	world.add_prop("market_stall", gate + Vector2(-3.0, 2.4), 0.9, false, 1)
	world.add_prop("watchtower", gate + Vector2(3.6, 1.0), 0.85, false, 2)
	# Warm lights (self-capped at MAX_LIGHTS — safe, no cap changes).
	world.add_light(gate, GreenwardStyle.LIGHT.warm_lantern, 1.0, 2.2)
	world.add_light(gate + Vector2(-3.0, 2.4), GreenwardStyle.LIGHT.warm_lantern, 0.8, 1.8)


## A DISTINCT silver-birch / moonlit composition for Moonpetal Hollow. Uses
## birch_grove, moon_lantern, stone_path, village_gate, moon_shrine, gazebo,
## spirit_bloom, crystal_cluster and wisp_lantern, with COOL lights derived
## from region["environment"]["ambient_tint"]. SMALL + bounded; respects caps.
