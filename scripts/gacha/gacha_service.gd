class_name GachaService
extends RefCounted
## Pure, deterministic summon logic. Given a banner, an RNG and a pity state,
## it returns results and the next pity state. No scene or currency access —
## this exact class can be lifted into an authoritative server module later.
##
## Rates, pity thresholds and featured characters are all data-driven
## (resources/data/banners.json) and displayed verbatim in the summon UI.

const RARITY_ORDER := ["common", "rare", "epic", "legendary", "mythic"]
const RARITY_RANK := {"common": 0, "rare": 1, "epic": 2, "legendary": 3, "mythic": 4}


static func empty_pity() -> Dictionary:
	return { "legendary": 0, "featured": 0, "epic_streak": 0 }


static func pull(banner: Dictionary, rng: RandomNumberGenerator, pity: Dictionary, count: int) -> Dictionary:
	var state := empty_pity()
	state.merge(pity, true)
	var rates: Dictionary = banner.get("rates", {})
	var featured: Array = banner.get("featured", [])
	var featured_rate := float(banner.get("featured_rate", 0.5))
	var hard_pity := int(banner.get("hard_pity", 70))
	var featured_pity := int(banner.get("featured_pity", 140))

	var results: Array = []
	var best_rank := -1

	for index in count:
		state.legendary += 1
		state.featured += 1
		state.epic_streak += 1

		var rarity := "common"
		if state.legendary >= hard_pity:
			rarity = "legendary"
		else:
			rarity = _roll_rarity(rates, rng)

		var pick := _pick_character(banner, rarity, featured, featured_rate, state, featured_pity, rng)
		var is_featured: bool = pick.featured

		if RARITY_RANK.get(rarity, 0) >= RARITY_RANK["legendary"]:
			state.legendary = 0
		if RARITY_RANK.get(rarity, 0) >= RARITY_RANK["epic"]:
			state.epic_streak = 0
		if is_featured:
			state.featured = 0

		best_rank = maxi(best_rank, int(RARITY_RANK.get(rarity, 0)))
		results.append({
			"character_id": pick.character_id,
			"rarity": rarity,
			"featured": is_featured,
			"index": index,
		})

	# Ten-pull floor: at least one Epic or better.
	if count >= 10 and bool(banner.get("ten_pull_epic_guarantee", false)) and best_rank < RARITY_RANK["epic"]:
		var guaranteed := _pick_character(banner, "epic", featured, featured_rate, state, featured_pity, rng)
		results[results.size() - 1] = {
			"character_id": guaranteed.character_id,
			"rarity": "epic",
			"featured": guaranteed.featured,
			"index": results.size() - 1,
			"guaranteed": true,
		}
		state.epic_streak = 0

	return { "results": results, "pity": state }


static func _roll_rarity(rates: Dictionary, rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	var cumulative := 0.0
	for rarity in RARITY_ORDER:
		cumulative += float(rates.get(rarity, 0.0))
		if roll < cumulative:
			return rarity
	return "common"


static func _pick_character(
	banner: Dictionary,
	rarity: String,
	featured: Array,
	featured_rate: float,
	state: Dictionary,
	featured_pity: int,
	rng: RandomNumberGenerator
) -> Dictionary:
	var pool: Dictionary = banner.get("pool", {})
	var candidates: Array = pool.get(rarity, [])
	if candidates.is_empty():
		candidates = _fallback_pool(pool)
	if candidates.is_empty():
		return { "character_id": "", "featured": false }

	# Featured rate-up only applies to characters of the rolled rarity.
	var matching_featured: Array = []
	for character_id in featured:
		var character: CharacterDef = ContentDB.get_character(character_id)
		if character != null and character.rarity == rarity:
			matching_featured.append(character_id)

	if not matching_featured.is_empty():
		var force_featured: bool = int(state.featured) >= featured_pity
		if force_featured or rng.randf() < featured_rate:
			return {
				"character_id": str(matching_featured[rng.randi_range(0, matching_featured.size() - 1)]),
				"featured": true,
			}

	return {
		"character_id": str(candidates[rng.randi_range(0, candidates.size() - 1)]),
		"featured": false,
	}


static func _fallback_pool(pool: Dictionary) -> Array:
	for rarity in RARITY_ORDER:
		if pool.has(rarity) and not pool[rarity].is_empty():
			return pool[rarity]
	return []
