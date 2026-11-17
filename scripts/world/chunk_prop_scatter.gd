class_name ChunkPropScatter
extends RefCounted
## Pure deterministic prop selection and placement record construction.

const BASE_TO_KINDS := {
	"glade_tree": ["willow_tree", "birch_tree", "pine_tree", "blossom_tree", "glade_tree"],
	"ancient_tree": ["dead_tree", "ancient_tree"],
	"rock": ["moss_rock", "pebble", "river_rock", "rock"],
	"flower": ["flower_cluster", "spirit_bloom", "flower"],
	"mushroom": ["glow_mushroom", "mushroom"],
	"crystal": ["crystal_cluster", "rune_stone", "crystal"],
	"bush": ["berry_bush", "bush"],
	"hut": ["cottage", "hut"],
	"lantern": ["wisp_lantern", "lantern"],
	"waypoint": ["shrine", "ruin_arch", "waypoint"],
	"ruin_pillar": ["rune_stone", "ruin_pillar"],
	"fence": ["signpost", "fence"],
}

static func resolve_prop(base_type: String, rng: RandomNumberGenerator, valid_kinds: Dictionary, elevation_value: float = 0.0, moisture_value: float = 0.0) -> Dictionary:
	var candidates: Array = BASE_TO_KINDS.get(base_type, [base_type])
	# Forest variation: bias the prop mix by elevation / moisture so different
	# parts of the forest look different — denser pines/birches on high ground,
	# reeds/lily pads in wet lowland. Purely reorders/weights the candidate list;
	# NO extra RNG calls, so determinism and caps are preserved.
	if base_type == "glade_tree":
		if elevation_value > 0.18:
			candidates = ["pine_tree", "birch_tree", "willow_tree", "glade_tree"]
		elif moisture_value > 0.28:
			candidates = ["willow_tree", "birch_tree", "glade_tree"]
	elif base_type == "flower" and moisture_value > 0.30:
		candidates = ["lily_pad", "reeds", "flower_cluster", "spirit_bloom", "flower"]
	elif base_type == "bush" and moisture_value > 0.30:
		candidates = ["reeds", "fern", "berry_bush", "bush"]
	var filtered: Array = []
	for candidate in candidates:
		if valid_kinds.has(str(candidate)):
			filtered.append(str(candidate))
	if filtered.is_empty():
		filtered = [base_type] if valid_kinds.has(base_type) else ["flower"]
	var kind := str(filtered[rng.randi() % filtered.size()])
	var vcount := maxi(1, GreenwardStyle.variant_count(kind))
	return { "kind": kind, "variant": rng.randi() % vcount }

static func prop_entry(kind: String, variant: int, world_position: Vector2, scale_value: float, flip: bool, is_detail: bool) -> Dictionary:
	return {
		"type": kind,
		"position": world_position,
		"scale": scale_value,
		"flip": flip,
		"layer": "prop",
		"variant": variant,
		"detail": is_detail,
	}

static func choose_prop(weights: Array, total_weight: float, elevation_value: float, rng: RandomNumberGenerator) -> String:
	if total_weight <= 0.0:
		return ""
	var roll := rng.randf() * total_weight
	var cumulative := 0.0
	for entry in weights:
		cumulative += float(entry.get("weight", 0.0))
		if roll <= cumulative:
			if elevation_value < float(entry.get("min_elevation", -2.0)):
				return ""
			return str(entry.get("type", ""))
	return ""

