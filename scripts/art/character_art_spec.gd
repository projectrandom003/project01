class_name CharacterArtSpec
extends RefCounted
## CHARACTER ART SPEC — Part 2 of PROJECT FANTASY Phase 5 (FOUNDATION).
##
## ZERO final assets exist. Every shipped visual is RUNTIME PROCEDURAL PLACEHOLDER
## art; this file is a pure CONTRACT/SPECIFICATION, not artwork. It holds ONE
## authored art spec per character id (the first 12 characters). Identity fields
## are derived verbatim from resources/data/characters.json so a test can cross-
## check `CharacterArtSpec.for_id(id).race == ContentDB.get_character(id).race`
## etc. Descriptive fields are authored here from each character's existing
## lore / title / role / palette and do NOT alter or replace gameplay data.
##
## ONE consistent anime-fantasy art direction is shared across all 12 (the
## STYLE_ANCHOR below): ~6-head heroic proportions, upper-left key light,
## 1-2 px dark ink outline, cel-shaded painterly rendering, transparent RGBA8
## backgrounds and element-motif accents. Legendary + Mythic characters carry a
## distinct visual tier (extra ornamentation, an aura motif, a premium frame).
## No copyrighted characters, logos or reference traces.
##
## PURE / headless: no nodes, no SceneTree, no autoloads, no file IO, no
## generated textures. Static factories construct instances via a RUNTIME
## load() of this script and type against the RefCounted base / untyped Variant;
## this avoids the GDScript global-class self-reference cycle that produces
## headless leaked-RID warnings (same technique as SpriteFramesActorSource).

# ------------------------------------------------------------------ constants
# The 12 first characters, in canonical order.
const CHARACTER_IDS: Array[String] = [
	"lyra_vey", "bramble", "seraphine", "nyx", "coralyn", "ignis",
	"mira_sol", "thistle", "vespera", "arachnia", "terra", "kael",
]

const VALID_RARITIES: Array[String] = ["common", "rare", "epic", "legendary", "mythic"]
const VALID_ELEMENTS: Array[String] = ["fire", "wind", "earth", "water", "light", "dark"]
const REQUIRED_FIELDS: Array[String] = [
	"id", "display_name", "title", "race", "element", "rarity", "role",
	"physical_appearance", "hair_style", "hair_color", "outfit", "accessories",
	"weapon", "personality", "visual_theme", "palette", "animation_requirements",
	"portrait_requirements", "generation_prompt", "portrait_prompt", "sheet_prompt",
]
const _SELF_PATH := "res://scripts/art/character_art_spec.gd"

# The SHARED global art-direction anchor, prepended to every generation prompt.
# Original anime-fantasy, no copyrighted characters/logos, consistent
# proportions/lighting/outline/palette language from GreenwardStyle, transparent
# background, upper-left key light.
const STYLE_ANCHOR := "Original anime-fantasy character illustration, ~6-head heroic proportions (not chibi, not realistic 8-head), soft cel-shaded painterly rendering, a 1-2 px dark ink outline for readability, a consistent upper-left key light with a cool rim light, transparent RGBA8 background (alpha cutout, no opaque backdrop, no baked ground shadow), no text, no logos, no copyrighted characters or reference traces. Shared GreenwardStyle palette language: deep indigo night, mossy emerald green, warm gold, teal spirit-light, violet arcane and ember accents. Feet on ONE baseline for full-body and world sprites."

# ------------------------------------------------------------------ authored specs
# ONE entry per character id. Identity + palette + skills/ultimate are EXACT
# copies of resources/data/characters.json; everything else is authored art
# direction consistent with the existing lore/title/role/palette.
const SPECS: Dictionary = {
	"lyra_vey": {
		"display_name": "Lyra Vey", "title": "Warden of the Whispering Glade",
		"race": "Elf", "element": "wind", "rarity": "epic", "role": "Ranged Support",
		"palette": {"hair": "#d8e8c8", "primary": "#2f6b4f", "secondary": "#c9a45a", "accent": "#9df5cf", "skin": "#f3d7c0"},
		"skills": ["gale_shot", "zephyr_blessing"], "ultimate": "tempest_dance",
		"hair_color_name": "pale mint-sage",
		"physical_appearance": "Tall, willowy elf with a quiet forward-leaning poise; long pointed ears, soft almond eyes the colour of new leaves, and a faint breeze that seems to tug at her clothes even in still air.",
		"hair_style": "Long pale-sage hair swept into a loose half-braid with wind-tossed flyaway strands and a leaf-shaped clasp.",
		"outfit": "Layered forest-green warden's cloak over a fitted gold-trimmed tunic, an asymmetrical leaf pauldron, knee-high travel boots and light leather bracers.",
		"accessories": "A braided vine circlet, small wind-chime charms at the belt, and a folded glade-map scarf.",
		"weapon": "A slender recurve longbow of pale wood strung with a shimmering mint-green wind-thread, plus a quiver of leaf-fletched arrows.",
		"personality": "Serene, watchful and gently sorrowful; she listens more than she speaks and treats the wind as an old, unreliable friend.",
		"visual_theme": "Mint-and-emerald wind warden; drifting leaf and ribbon motifs, cool teal accent glow, soft rounded ally silhouette.",
		"pose": "Standing three-quarter view, bow lowered, one hand lifted as if catching a breeze, cloak and hair streaming to the left.",
		"motif": "swirling wind ribbons and drifting leaves",
		"expression": "a faint, knowing half-smile as the wind rises",
		"tier_note": "",
	},
	"bramble": {
		"display_name": "Bramble", "title": "Thorn-Touched Wanderer",
		"race": "Beastkin", "element": "earth", "rarity": "rare", "role": "Bruiser",
		"palette": {"hair": "#c96f3a", "primary": "#5a4a2e", "secondary": "#8fbf6a", "accent": "#ffd27a", "skin": "#f0c8a8"},
		"skills": ["thorn_lash", "stone_bulwark"], "ultimate": "worldroot",
		"hair_color_name": "burnt copper",
		"physical_appearance": "Stocky, sturdy beastkin with russet fox ears and a bushy tail, freckled cheeks, blunt honest features, calloused hands and a slight permanent squint from outdoor life.",
		"hair_style": "Short, shaggy copper hair with unruly tufts, a few leaves and twigs forever caught in it.",
		"outfit": "Patchwork bark-brown travelling coat with leaf-green stitching, reinforced shoulder pads, a rope belt and sturdy wrapped boots.",
		"accessories": "A coil of hemp rope, a small carved wooden charm for the trees she apologises to, and a dented canteen.",
		"weapon": "A gnarled root-club bound with iron bands, sized like a tree limb.",
		"personality": "Gentle, apologetic and deceptively strong; she apologises to every tree she cuts and to every foe before she hits them.",
		"visual_theme": "Earthy bark-and-moss bruiser; warm lantern-gold accents, rounded friendly silhouette, thorn and root motifs.",
		"pose": "Wide, grounded stance, root-club resting on one shoulder, tail curled, a tiny sprout growing from her boot.",
		"motif": "twisting bramble roots and small green sprouts",
		"expression": "a sheepish, apologetic grin",
		"tier_note": "",
	},
	"seraphine": {
		"display_name": "Seraphine Ael", "title": "Dawn's Last Ember",
		"race": "Angel", "element": "light", "rarity": "legendary", "role": "Healer",
		"palette": {"hair": "#fff2c4", "primary": "#f2ead7", "secondary": "#d9b45c", "accent": "#ffe9a3", "skin": "#f7ddc9"},
		"skills": ["dawn_mend", "radiance"], "ultimate": "starfall",
		"hair_color_name": "pale sun-gold",
		"physical_appearance": "Graceful, luminous angel with a calm maternal gaze, faintly glowing skin, a small radiant warm halo above the head and six soft feathered wings folded behind her.",
		"hair_style": "Long waves of pale sun-gold hair falling past the waist, crowned by a thin filigree halo-ring.",
		"outfit": "Flowing ivory and gold robe with layered translucent oversleeves, an ornate gold sunburst breastplate clasp and gilded hem embroidery of tiny stars.",
		"accessories": "A suspended ember-lantern holding a single dying sun-spark, a gold sunburst diadem and delicate chained bracelets.",
		"weapon": "No blade - a slender gold censer-staff whose bowl cradles a warm living ember used to heal.",
		"personality": "Boundlessly warm, self-giving and quietly ancient; she gives away the last warmth she has without a second thought.",
		"visual_theme": "Ivory-and-gold dawn angel; sunburst and halo motifs, a warm radiant aura, ornate premium LEGENDARY ornamentation, soft rounded ally silhouette.",
		"pose": "Hovering slightly, hands cupped around a glowing ember, wings half-unfurled, warm light spilling downward.",
		"motif": "a dying sun's last ember, sunburst rays and falling gold motes",
		"expression": "a tender, sorrowful smile",
		"tier_note": "LEGENDARY TIER: ornate filigree halo, layered gold embroidery, a persistent warm aura of falling light motes, and a premium engraved sunburst frame.",
	},
	"nyx": {
		"display_name": "Nyx Vaelora", "title": "Queen of the Hollow Moon",
		"race": "Demon", "element": "dark", "rarity": "legendary", "role": "Mage",
		"palette": {"hair": "#2a1533", "primary": "#3b1f4e", "secondary": "#a87bd4", "accent": "#ff6fae", "skin": "#e8cdd8"},
		"skills": ["umbral_rend", "nightfall"], "ultimate": "eclipse_requiem",
		"hair_color_name": "near-black aubergine",
		"physical_appearance": "Regal, tall demon queen with curling horns, luminous rose-magenta eyes, an absent reflection (mirrors behind her show nothing) and a calm, cold beauty.",
		"hair_style": "Very long near-black aubergine hair falling like ink, bound at the temples with amethyst horn-clasps.",
		"outfit": "Deep-violet off-shoulder gown with an amethyst corset, a high collar, a trailing starfield cape and rose-magenta rune embroidery.",
		"accessories": "A hollow-moon crown (a ring with a black disc), floating shard earrings and a chained eclipse sigil at the throat.",
		"weapon": "A floating grimoire of blank black pages and a slender eclipse staff topped with a void-disc.",
		"personality": "Imperious, composed and quietly hollow; she traded her reflection for a throne and has never once looked back.",
		"visual_theme": "Hollow-moon violet queen; eclipse, void-disc and thorned-crown motifs, rose-magenta arcane glow, sharp regal silhouette, ornate premium LEGENDARY ornamentation.",
		"pose": "Seated-on-air three-quarter view, one hand raised holding a small black moon, cape and hair drifting as if underwater, no reflection below.",
		"motif": "a full black moon that is a hole in the sky, eclipse rings and drifting shadow petals",
		"expression": "a cool, unreadable half-smile",
		"tier_note": "LEGENDARY TIER: an ornate hollow-moon crown, a layered starfield cape, a persistent violet-black eclipse aura, and a premium engraved obsidian frame.",
	},
	"coralyn": {
		"display_name": "Coralyn Tide", "title": "Song Beneath the Reef",
		"race": "Mermaid", "element": "water", "rarity": "epic", "role": "Healer",
		"palette": {"hair": "#7fe3e0", "primary": "#1f6f8f", "secondary": "#ffb3c7", "accent": "#b9f6ff", "skin": "#f4d9cd"},
		"skills": ["tidal_caress", "frost_bind"], "ultimate": "abyssal_hymn",
		"hair_color_name": "seafoam teal",
		"physical_appearance": "Lithe mermaid with a shimmering scaled tail (a flowing split fin-skirt on land), webbed fingertips, pearl-bright eyes and faint gill-lines at the neck.",
		"hair_style": "Long seafoam-teal hair that floats as if in water, threaded with tiny shells and coral beads.",
		"outfit": "Deep lagoon-blue wrap bodice with coral-pink ribbon lacing, translucent fin-like overskirt panels and a pearl-scaled hip drape.",
		"accessories": "A conch pendant that hums, pearl hairpins and a bracelet of tide-marked beads.",
		"weapon": "A coral staff strung with floating droplets, or a conch that channels healing water.",
		"personality": "Soft-spoken, curious and easily startled; she hums an unknown name the tides whispered to steady her nerve.",
		"visual_theme": "Lagoon-and-coral tide singer; wave, bubble and shell motifs, pale-aqua glow, fluid rounded ally silhouette.",
		"pose": "Mid-turn as if underwater, one hand at her conch pendant, hair and fin-panels billowing, floating droplets around her.",
		"motif": "curling tide ribbons, rising bubbles and reef coral",
		"expression": "a small, uncertain hum with wide eyes",
		"tier_note": "",
	},
	"ignis": {
		"display_name": "Ignis Karroth", "title": "Crown of Cinders",
		"race": "Dragonkin", "element": "fire", "rarity": "mythic", "role": "Damage",
		"palette": {"hair": "#ff7a3c", "primary": "#3a1414", "secondary": "#d9a441", "accent": "#ffb347", "skin": "#e8b28f"},
		"skills": ["ember_lance", "cinder_veil"], "ultimate": "inferno_crown",
		"hair_color_name": "ember orange",
		"physical_appearance": "Powerful dragonkin with swept-back ember horns, scaled forearms and shoulders, a long heavy draconic tail, slit-pupil amber eyes and heat-shimmer rising from his skin.",
		"hair_style": "Wild, flame-swept ember-orange hair that rises like living fire, streaked with molten-gold tips.",
		"outfit": "Charred crimson-black armour with molten-gold filigree glowing in the seams, a tattered ash-cloak, scaled greaves and an open collar showing the cinder crown's brand.",
		"accessories": "The Crown of Cinders (a floating ring of ever-burning embers above the brow), seared bracers and a belt of cooled slag medallions.",
		"weapon": "A great molten greatsword of half-cooled slag, dripping embers and wreathed in flame.",
		"personality": "Proud, unrepentant and smouldering; he carries the weight of a kingdom that burned itself to keep him warm and refuses to apologise for surviving.",
		"visual_theme": "Charred-crown dragonkin; cinder, ash and molten-gold motifs, a roaring ember aura, asymmetric sharp silhouette, the most ornate premium MYTHIC tier.",
		"pose": "Forward-leaning power stance, greatsword planted point-down wreathed in fire, cinder crown blazing, ash-cloak swept behind, heat-haze rising.",
		"motif": "a floating crown of cinders, drifting ash and rising flame tongues",
		"expression": "a defiant, unapologetic smirk",
		"tier_note": "MYTHIC TIER (highest, single Mythic character): a persistent roaring ember-and-ash aura, the elaborate floating Crown of Cinders, molten-gold glowing filigree across all armour seams, a layered ash-cloak, and the most ornate premium engraved obsidian-and-gold frame reserved for the Mythic tier.",
	},
	"mira_sol": {
		"display_name": "Mira Sol", "title": "Squire of the Golden Gate",
		"race": "Human", "element": "light", "rarity": "common", "role": "Tank",
		"palette": {"hair": "#e8c27a", "primary": "#c9d2e0", "secondary": "#d9b45c", "accent": "#fff0b8", "skin": "#f0cbb0"},
		"skills": ["shield_bash", "rally_cry"], "ultimate": "aegis_dawn",
		"hair_color_name": "warm wheat-gold",
		"physical_appearance": "Sturdy, earnest young human with a square jaw, a few faint freckles, steady grey-gold eyes and the upright posture of someone who still stands watch.",
		"hair_style": "Practical wheat-gold bob tucked under a squire's cap, with a short braid at one temple.",
		"outfit": "Well-kept but unknighted steel-blue gambeson with brass buttons, a plain tabard bearing no crest, dented pauldrons and sturdy boots.",
		"accessories": "A blank shield with an empty crest-space, a worn oath-ribbon tied at the wrist and a small brass gate-key.",
		"weapon": "A broad kite shield and a short, honest sword - defensive gear, not a hero's blade.",
		"personality": "Dutiful, unglamorous and steadfast; she keeps an oath to a kingdom that ran out of knights before it ran out of wars.",
		"visual_theme": "Humble steel-and-dawn squire; plain gate-and-shield motifs, a pale dawn-gold accent, a simple honest rounded silhouette (ordinary COMMON tier, no ornamentation).",
		"pose": "Square, protective stance, shield raised and angled forward, sword held low, cloak still, feet planted.",
		"motif": "a plain gate arch, an unmarked shield and a thin dawn ray",
		"expression": "a determined, steady gaze",
		"tier_note": "",
	},
	"thistle": {
		"display_name": "Thistle", "title": "Lantern of Small Wishes",
		"race": "Spirit", "element": "wind", "rarity": "rare", "role": "Support",
		"palette": {"hair": "#f2e2a8", "primary": "#3f5a6b", "secondary": "#8fd9c4", "accent": "#ffeaa0", "skin": "#f6e3cf"},
		"skills": ["wishlight", "zephyr_blessing"], "ultimate": "thousand_lanterns",
		"hair_color_name": "pale wishlight gold",
		"physical_appearance": "Small, translucent wisp-spirit with a softly glowing slightly see-through body, tiny floating feet, a faint halo of warm lantern-light and edges that blur into motes.",
		"hair_style": "A cloud of pale wishlight-gold hair that drifts upward like dandelion fluff.",
		"outfit": "A simple dusky-blue hooded tunic with mint edging, a little satchel and a hem that fades into sparkles rather than cloth.",
		"accessories": "The Wish-Lantern - a small brass lantern full of glowing abandoned wishes - plus a chain of tiny paper wishes.",
		"weapon": "No weapon: the lantern itself, whose light grants small miracles.",
		"personality": "Timid, tender and hopeful; she collects abandoned wishes and lights them for anyone who has run out of hope.",
		"visual_theme": "Warm wishlight wisp; lantern, dandelion-seed and paper-wish motifs, a soft mint-and-gold glow, a small rounded glowing silhouette.",
		"pose": "Bobbing mid-air hugging the glowing lantern to her chest, a trail of tiny lit wishes spiralling upward.",
		"motif": "floating paper wishes, dandelion seeds and warm lantern motes",
		"expression": "a shy, hopeful smile",
		"tier_note": "",
	},
	"vespera": {
		"display_name": "Vespera Noct", "title": "Velvet Requiem",
		"race": "Vampire", "element": "dark", "rarity": "epic", "role": "Assassin",
		"palette": {"hair": "#d8d8e8", "primary": "#2a1a2e", "secondary": "#8f2f4f", "accent": "#ff8fb3", "skin": "#f0e0e0"},
		"skills": ["umbral_rend", "blood_waltz"], "ultimate": "crimson_eclipse",
		"hair_color_name": "moonlit silver-lilac",
		"physical_appearance": "Elegant, pale vampire with crimson-lined eyes, delicate pointed canines just visible, an unhurried dancer's poise and an eerie stillness; dressed always in funeral white.",
		"hair_style": "Long moonlit silver-lilac hair in a smooth low braid with a few loose face-framing strands.",
		"outfit": "A high-collared white mourning gown with deep-plum lining, a wine-crimson sash, lace gloves, a trailing veil and hidden blades in the seams.",
		"accessories": "A single white funeral glove, a black-rose brooch and a pocket watch stopped at the last candle's hour.",
		"weapon": "Twin slender rose-tinted stiletto daggers, ornate and near-invisible in the folds of her gown.",
		"personality": "Courteous, unhurried and faintly mournful; she never leaves a funeral before the last candle dies and always arrives dressed for one.",
		"visual_theme": "White-mourning vampire assassin; black-rose, candle and waltz motifs, a rose-pink accent, a sharp elegant silhouette and dark-plum lining.",
		"pose": "A mid-waltz turn, one dagger half-drawn and hidden in the skirt, veil and hair sweeping, a guttering candle at her feet.",
		"motif": "black roses, guttering candle flames and a slow crimson waltz arc",
		"expression": "a serene, faintly mourning smile",
		"tier_note": "",
	},
	"arachnia": {
		"display_name": "Arachnia Silk", "title": "Weaver of the Quiet Web",
		"race": "Monster Girl", "element": "dark", "rarity": "epic", "role": "Controller",
		"palette": {"hair": "#3a2a4a", "primary": "#4a2f5a", "secondary": "#b07fd4", "accent": "#c8ff8f", "skin": "#e8c8d8"},
		"skills": ["web_bind", "venom_bite"], "ultimate": "silk_dominion",
		"hair_color_name": "dark mulberry",
		"physical_appearance": "Composed monster-girl with a human upper body and six slender spider legs arching from her back, four auxiliary eyes on the temples (closed to near-slits) and graceful many-jointed fingers.",
		"hair_style": "Sleek dark-mulberry hair wound into an intricate web-like updo pinned with silk threads.",
		"outfit": "Deep-aubergine bodice with orchid-violet web-lace panels, a high collar and a skirt of layered silk strands.",
		"accessories": "A spool of glowing chartreuse silk at the hip, silver web charms and a half-finished tapestry map.",
		"weapon": "Glowing chartreuse silk threads from her fingertips, woven into binding webs, plus a slender silk-edged spindle.",
		"personality": "Patient, precise and private; she wove a tapestry of every road in Aetheria and deliberately hid the one that leads home.",
		"visual_theme": "Quiet-web weaver; spider-silk, tapestry-map and eight-strand motifs, a chartreuse glow against deep aubergine, an elegant asymmetric silhouette.",
		"pose": "Seated within a half-woven web, spider legs arched, fingertips drawing a glowing thread that becomes a road-map, calm and unhurried.",
		"motif": "glowing silk threads, an eight-strand web and a hidden winding road",
		"expression": "a patient, knowing look",
		"tier_note": "",
	},
	"terra": {
		"display_name": "Terra Rootheart", "title": "The Mountain That Remembers",
		"race": "Ancient", "element": "earth", "rarity": "legendary", "role": "Tank",
		"palette": {"hair": "#6f8f5a", "primary": "#4a4030", "secondary": "#8fbf6a", "accent": "#d9ff9f", "skin": "#c9a88a"},
		"skills": ["stone_bulwark", "thorn_lash"], "ultimate": "worldroot",
		"hair_color_name": "mossy stone-green",
		"physical_appearance": "Immense, calm ancient whose body is part living stone - moss-veined forearms, a granite-like shoulder ridge, slow glacial movements and eyes like deep green mineral seams; she seems more landscape than person.",
		"hair_style": "Long mossy stone-green hair like hanging lichen, threaded with small wildflowers and pebbles.",
		"outfit": "Weathered granite-brown drapery that reads as layered cliff strata, a lichen-green vine sash and slabs of rune-carved stone at the shoulders.",
		"accessories": "A crown of standing stones, embedded runes that glow pale moss-green and a necklace of river-worn boulders.",
		"weapon": "No conventional weapon - a colossal stone slab-shield that is part of her, and the ground itself that answers before she speaks.",
		"personality": "Immovably patient, slow to speak and ancient beyond memory; the ground answers before she does, and she still dreams in stone.",
		"visual_theme": "Mountain-that-remembers; cliff-strata, standing-stone and deep-root motifs, pale moss-glow seams, a monumental rounded-rock silhouette, ornate premium LEGENDARY ornamentation.",
		"pose": "Seated like a low mountain, hands resting on the earth, small stone ridges rising around her, roots and lichen trailing from her shoulders.",
		"motif": "layered cliff strata, standing stones and deep glowing roots",
		"expression": "a slow, ancient, half-lidded calm",
		"tier_note": "LEGENDARY TIER: an ornate crown of rune-lit standing stones, layered cliff-strata drapery, a persistent pale moss-green earth aura with floating pebbles, and a premium engraved stone-and-gold frame.",
	},
	"kael": {
		"display_name": "Kael Ashford", "title": "Blade Without a Banner",
		"race": "Human", "element": "fire", "rarity": "rare", "role": "Damage",
		"palette": {"hair": "#4a3020", "primary": "#5a3a2a", "secondary": "#c96f3a", "accent": "#ffcf6a", "skin": "#e8b890"},
		"skills": ["ember_lance", "rally_cry"], "ultimate": "blazing_charge",
		"hair_color_name": "dark umber-brown",
		"physical_appearance": "Lean, scarred human sellsword with a weathered face, a crooked nose, one sun-bleached eyebrow and the relaxed, ready stance of someone who has fought too many pointless wars.",
		"hair_style": "Short, rough dark-umber hair singed at the tips, with a jagged old burn along one side.",
		"outfit": "Worn leather-brown brigandine with burnt-rust wraps, mismatched scavenged pauldrons, a blank tabard with the banner emblem burned away and travel-worn boots.",
		"accessories": "A charred banner-ribbon kept as a belt tie, a coin pouch and a small unmarked token for the one person he fights for free.",
		"weapon": "A plain, well-used longsword with ember-gold etching along the fuller, its hilt wrapped in scorched leather.",
		"personality": "Wry, pragmatic and privately loyal; he fights for anyone with coin, and for exactly one person without it.",
		"visual_theme": "Bannerless ember sellsword; charred-banner, ash and ember motifs, an ember-gold accent, a sharp pragmatic silhouette (unadorned RARE tier).",
		"pose": "Casual ready stance, sword resting on the shoulder, a scorched banner ribbon trailing from the belt, a few ember sparks at his feet.",
		"motif": "a burnt banner, drifting ash and a single stubborn ember",
		"expression": "a dry, lopsided smirk",
		"tier_note": "",
	},
}

# ------------------------------------------------------------------ instance state
# All required fields are plain data (safe to snapshot / to_dict()).
var id: String = ""
var display_name: String = ""
var title: String = ""
var race: String = ""
var element: String = ""
var rarity: String = ""
var role: String = ""
var physical_appearance: String = ""
var hair_style: String = ""
var hair_color: String = ""
var outfit: String = ""
var accessories: String = ""
var weapon: String = ""
var personality: String = ""
var visual_theme: String = ""
var palette: Dictionary = {}
var animation_requirements: Dictionary = {}
var portrait_requirements: Dictionary = {}
var generation_prompt: String = ""
var portrait_prompt: String = ""
var sheet_prompt: String = ""
var skills: Array = []
var ultimate: String = ""
var tier_note: String = ""


func _init(data: Dictionary = {}) -> void:
	var d: Dictionary = data.duplicate(true)
	if d.is_empty():
		return
	id = str(d.get("id", ""))
	display_name = str(d.get("display_name", ""))
	title = str(d.get("title", ""))
	race = str(d.get("race", ""))
	element = str(d.get("element", ""))
	rarity = str(d.get("rarity", ""))
	role = str(d.get("role", ""))
	physical_appearance = str(d.get("physical_appearance", ""))
	hair_style = str(d.get("hair_style", ""))
	palette = (d.get("palette", {}) as Dictionary).duplicate(true)
	outfit = str(d.get("outfit", ""))
	accessories = str(d.get("accessories", ""))
	weapon = str(d.get("weapon", ""))
	personality = str(d.get("personality", ""))
	visual_theme = str(d.get("visual_theme", ""))
	skills = (d.get("skills", []) as Array).duplicate()
	ultimate = str(d.get("ultimate", ""))
	tier_note = str(d.get("tier_note", ""))
	hair_color = "%s (%s)" % [str(palette.get("hair", "#ffffff")), str(d.get("hair_color_name", ""))]
	animation_requirements = _animation_requirements(d)
	portrait_requirements = _portrait_requirements(d)
	generation_prompt = _full_body_prompt(d)
	portrait_prompt = _portrait_prompt(d)
	sheet_prompt = _sheet_prompt(d)


# ------------------------------------------------------------------ factories
# Construct via a RUNTIME load() + base/Variant typing (NOT this global class's
# name) to avoid the static self-reference cycle and headless leaked-RID warns.

## All 12 authored specs, in CHARACTER_IDS order. Returns an untyped Array of
## CharacterArtSpec instances (element access at call sites is dynamic).
static func all() -> Array:
	var out: Array = []
	for cid in CHARACTER_IDS:
		var entry: Dictionary = (SPECS[cid] as Dictionary).duplicate(true)
		entry["id"] = cid
		out.append(load(_SELF_PATH).new(entry))
	return out


## One spec for an id, or null for an unknown id (null-ish safe, never throws).
static func for_id(id: String):
	if not SPECS.has(id):
		return null
	var entry: Dictionary = (SPECS[id] as Dictionary).duplicate(true)
	entry["id"] = id
	return load(_SELF_PATH).new(entry)


## Fresh typed copy of the 12 stable character ids.
static func ids() -> Array[String]:
	var out: Array[String] = []
	for cid in CHARACTER_IDS:
		out.append(cid)
	return out


## [] when all 12 specs are present, unique, every required field is non-empty
## and identity fields are internally consistent; precise errors otherwise.
static func validate_specs() -> Array[String]:
	var errors: Array[String] = []
	# uniqueness + count
	var seen: Dictionary = {}
	for cid in CHARACTER_IDS:
		if seen.has(cid):
			errors.append("duplicate character id '%s' in CHARACTER_IDS" % cid)
		seen[cid] = true
	if CHARACTER_IDS.size() != 12:
		errors.append("expected 12 character ids, found %d" % CHARACTER_IDS.size())
	if SPECS.size() != CHARACTER_IDS.size():
		errors.append("SPECS has %d entries, expected %d" % [SPECS.size(), CHARACTER_IDS.size()])
	# per-character checks (built from a runtime load to stay cycle-free)
	for entry in all():
		var spec: RefCounted = entry as RefCounted
		var cid := str(spec.get("id"))
		if not SPECS.has(cid):
			errors.append("spec '%s' is not in SPECS" % cid)
		var dict := (spec.call("to_dict") as Dictionary)
		for field in REQUIRED_FIELDS:
			var v: Variant = dict.get(field, null)
			if v == null:
				errors.append("spec '%s' missing field '%s'" % [cid, field])
			elif (typeof(v) == TYPE_STRING) and str(v).strip_edges().is_empty():
				errors.append("spec '%s' field '%s' is empty" % [cid, field])
			elif (typeof(v) == TYPE_DICTIONARY) and (v as Dictionary).is_empty():
				errors.append("spec '%s' field '%s' is empty" % [cid, field])
		# identity consistency vs the frozen SPECS data
		var raw: Dictionary = SPECS.get(cid, {})
		if str(dict.get("display_name", "")) != str(raw.get("display_name", "")):
			errors.append("spec '%s' display_name inconsistent with SPECS" % cid)
		if str(dict.get("title", "")) != str(raw.get("title", "")):
			errors.append("spec '%s' title inconsistent with SPECS" % cid)
		if str(dict.get("race", "")) != str(raw.get("race", "")):
			errors.append("spec '%s' race inconsistent with SPECS" % cid)
		if str(dict.get("element", "")) != str(raw.get("element", "")):
			errors.append("spec '%s' element inconsistent with SPECS" % cid)
		if str(dict.get("rarity", "")) != str(raw.get("rarity", "")):
			errors.append("spec '%s' rarity inconsistent with SPECS" % cid)
		if str(dict.get("role", "")) != str(raw.get("role", "")):
			errors.append("spec '%s' role inconsistent with SPECS" % cid)
		if not VALID_RARITIES.has(str(dict.get("rarity", ""))):
			errors.append("spec '%s' rarity '%s' is not one of %s" % [cid, str(dict.get("rarity", "")), str(VALID_RARITIES)])
		if not VALID_ELEMENTS.has(str(dict.get("element", ""))):
			errors.append("spec '%s' element '%s' is not one of %s" % [cid, str(dict.get("element", "")), str(VALID_ELEMENTS)])
		var pal: Dictionary = dict.get("palette", {})
		for pk in ["hair", "primary", "secondary", "accent", "skin"]:
			var hex := str(pal.get(pk, ""))
			if hex.length() != 7 or not hex.begins_with("#"):
				errors.append("spec '%s' palette.%s is not a #rrggbb hex" % [cid, pk])
		# animation + portrait requirements integrity
		var anim: Dictionary = dict.get("animation_requirements", {})
		if (anim.get("animations", []) as Array).size() != 72:
			errors.append("spec '%s' animation_requirements must list 72 animations" % cid)
		if (anim.get("states", []) as Array).size() != 9:
			errors.append("spec '%s' animation_requirements must list 9 states" % cid)
		# legendary/mythic premium tier must be described
		var rar := str(dict.get("rarity", ""))
		if (rar == "legendary" or rar == "mythic") and str(dict.get("tier_note", "")).strip_edges().is_empty():
			errors.append("spec '%s' (%s) must describe a distinct visual tier" % [cid, rar])
	return errors


## id -> {name, race, element, rarity, title, role} (identity from SPECS).
static func identity_table() -> Dictionary:
	var out: Dictionary = {}
	for cid in CHARACTER_IDS:
		var d: Dictionary = SPECS[cid]
		out[cid] = {
			"name": str(d["display_name"]),
			"race": str(d["race"]),
			"element": str(d["element"]),
			"rarity": str(d["rarity"]),
			"title": str(d["title"]),
			"role": str(d["role"]),
		}
	return out


# ------------------------------------------------------------------ instance API

## Full spec as a plain Dictionary (fresh copy; all required fields present).
func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"title": title,
		"race": race,
		"element": element,
		"rarity": rarity,
		"role": role,
		"physical_appearance": physical_appearance,
		"hair_style": hair_style,
		"hair_color": hair_color,
		"outfit": outfit,
		"accessories": accessories,
		"weapon": weapon,
		"personality": personality,
		"visual_theme": visual_theme,
		"palette": palette.duplicate(true),
		"animation_requirements": animation_requirements.duplicate(true),
		"portrait_requirements": portrait_requirements.duplicate(true),
		"generation_prompt": generation_prompt,
		"portrait_prompt": portrait_prompt,
		"sheet_prompt": sheet_prompt,
		"skills": skills.duplicate(),
		"ultimate": ultimate,
		"tier_note": tier_note,
	}


## A detailed, ready-to-use generation prompt for one kind:
## "full_body" | "portrait" | "sheet" | "vfx". Unknown -> "" (never throws).
func prompt_for(kind: String) -> String:
	match kind:
		"full_body":
			return generation_prompt
		"portrait":
			return portrait_prompt
		"sheet":
			return sheet_prompt
		"vfx":
			return _vfx_prompt()
		_:
			return ""


## The 72 required <state>_<dir> animation names for this character.
func required_animations() -> Array[String]:
	var out: Array[String] = []
	for a in (animation_requirements.get("animations", []) as Array):
		out.append(str(a))
	return out


# ------------------------------------------------------------------ composition
# Detailed prompts are composed from the shared STYLE_ANCHOR + per-character
# authored fields, so all 12 stay consistent yet visually distinct.

static func _palette_line(d: Dictionary) -> String:
	var p: Dictionary = d.get("palette", {})
	return "hair %s, primary %s, secondary %s, accent %s, skin %s" % [
		str(p.get("hair", "")), str(p.get("primary", "")), str(p.get("secondary", "")),
		str(p.get("accent", "")), str(p.get("skin", "")),
	]


static func _full_body_prompt(d: Dictionary) -> String:
	var tier := str(d.get("tier_note", ""))
	var tier_line := ("\nPREMIUM TIER: " + tier) if not tier.is_empty() else ""
	var pal: Dictionary = d.get("palette", {})
	var hair_hex := str(pal.get("hair", ""))
	return "%s\n\nSUBJECT: full-body illustration of %s (%s) - %s. Race: %s; Element: %s; Rarity: %s; Role: %s.\nAPPEARANCE: %s Hair: %s (%s), %s. Outfit: %s Accessories: %s Weapon: %s.\nPOSE AND MOTIF: %s Motif: %s. Palette: %s. Visual theme: %s.%s\nOUTPUT SPEC: full-body master 1024x2048 px, full height head-to-toe, feet on ONE baseline, transparent RGBA8 sRGB, upper-left key light, 1-2 px dark ink outline, no baked text or backdrop." % [
		STYLE_ANCHOR,
		str(d.get("display_name", "")), str(d.get("title", "")), str(d.get("title", "")),
		str(d.get("race", "")), str(d.get("element", "")), str(d.get("rarity", "")), str(d.get("role", "")),
		str(d.get("physical_appearance", "")), hair_hex, str(d.get("hair_color_name", "")), str(d.get("hair_style", "")),
		str(d.get("outfit", "")), str(d.get("accessories", "")), str(d.get("weapon", "")),
		str(d.get("pose", "")), str(d.get("motif", "")), _palette_line(d), str(d.get("visual_theme", "")), tier_line,
	]


static func _portrait_prompt(d: Dictionary) -> String:
	var tier := str(d.get("tier_note", ""))
	var tier_line := (" Premium frame: " + tier) if not tier.is_empty() else ""
	var pal: Dictionary = d.get("palette", {})
	var hair_hex := str(pal.get("hair", ""))
	return "%s\n\nSUBJECT: bust portrait of %s (%s), %s. Head-and-shoulders top-centre crop (0.5, 0.0), eyes in the upper third, a calm neutral expression plus one alternate (%s). Hair: %s (%s), %s. Palette: %s. Visual theme: %s. Rarity frame: %s tier.%s\nOUTPUT SPEC: master 1024x1280 px, export 256x384 px top-centre bust crop, transparent RGBA8 sRGB, upper-left key light, 1-2 px dark ink outline, no baked text, silhouette readable at 96x96." % [
		STYLE_ANCHOR,
		str(d.get("display_name", "")), str(d.get("title", "")), str(d.get("title", "")),
		str(d.get("expression", "")), hair_hex, str(d.get("hair_color_name", "")), str(d.get("hair_style", "")),
		_palette_line(d), str(d.get("visual_theme", "")), str(d.get("rarity", "")), tier_line,
	]


static func _sheet_prompt(d: Dictionary) -> String:
	return "%s\n\nSUBJECT: 8-direction world sprite sheet for %s (%s), %s. 96x128 px frames, bottom-centre anchor (0.5, 1.0), feet on ONE identical baseline across every frame/state/direction, 1-2 px dark ink outline, transparent RGBA8. Palette: %s. Visual theme: %s.\nLAYOUT: per-state atlas = <frames> columns x 8 direction rows (row 0 DOWN ... row 7 DOWN_LEFT), 0-based columns; states idle 5 frames @ 9 fps loop, walk 64 @ 60 loop, run 64 @ 64 loop, interact 6 @ 12, attack 6 @ 15, damage 2 @ 12, victory 8 @ 12, defeat 6 @ 10, cast 7 @ 12 (all one-shots unless noted). Slice into a SpriteFrames .tres with animations <state>_<dir> and cast_<dir>, speed = fps, loop = loop flag.\nOUTPUT SPEC: transparent RGBA8 PNG atlas(es) sliced to a SpriteFrames .tres, 96x128 frames, Linear filter + mipmaps on, feet on ONE baseline, no baked text." % [
		STYLE_ANCHOR,
		str(d.get("display_name", "")), str(d.get("title", "")), str(d.get("role", "")),
		_palette_line(d), str(d.get("visual_theme", "")),
	]


func _vfx_prompt() -> String:
	var sk := ""
	for i in skills.size():
		if i > 0:
			sk += ", "
		sk += str(skills[i])
	return "%s\n\nSUBJECT: skill/ultimate VFX flipbook for %s - skill ids [%s], ultimate id [%s], element %s, motif %s. 192x192 px frames, 6 frames, centre anchor (0.5, 0.5), 1 row x 6 columns (atlas 1152x192), transparent RGBA8 additive glow, element-coloured accents, no baked text.\nOUTPUT SPEC: transparent RGBA8 PNG flipbook, 192x192 frames, Linear filter + mipmaps off + Lossless, additive alpha, sliced into 6-frame animations." % [
		STYLE_ANCHOR, display_name, sk, ultimate, element, visual_theme,
	]


static func _animation_requirements(d: Dictionary) -> Dictionary:
	var states: Array[String] = ["idle", "walk", "run", "interact", "attack", "damage", "victory", "defeat", "cast"]
	var frame_counts := {"idle": 5, "walk": 64, "run": 64, "interact": 6, "attack": 6, "damage": 2, "victory": 8, "defeat": 6, "cast": 7}
	var fps := {"idle": 9.0, "walk": 60.0, "run": 64.0, "interact": 12.0, "attack": 15.0, "damage": 12.0, "victory": 12.0, "defeat": 10.0, "cast": 12.0}
	var looping := {"idle": true, "walk": true, "run": true, "interact": false, "attack": false, "damage": false, "victory": false, "defeat": false, "cast": false}
	var anims: Array[String] = []
	for st in states:
		for dir in 8:
			anims.append("%s_%d" % [st, dir])
	return {
		"required_states": states.duplicate(),
		"states": states.duplicate(),
		"directions": 8,
		"direction_names": ["down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left"],
		"locomotion_8_directions": true,
		"animations": anims,
		"frame_counts": frame_counts,
		"fps": fps,
		"looping": looping,
		"skill_vfx_ids": (d.get("skills", []) as Array).duplicate(),
		"ultimate_vfx_ids": [str(d.get("ultimate", ""))],
	}


static func _portrait_requirements(d: Dictionary) -> Dictionary:
	var rar := str(d.get("rarity", "common"))
	var premium := (rar == "legendary" or rar == "mythic")
	return {
		"master_width": 1024, "master_height": 1280,
		"export_width": 256, "export_height": 384,
		"crop": "top-centre (0.5, 0.0) bust crop, head and shoulders, eyes in the upper third",
		"expression_set": ["neutral", str(d.get("expression", "alternate"))],
		"background_treatment": "transparent RGBA8 (alpha cutout); a subtle element-tinted vignette is allowed, never an opaque backdrop",
		"rarity_frame": "%s frame; %s" % [rar, "premium ornate frame for Legendary/Mythic tier" if premium else "standard frame"],
		"lighting": "upper-left key light, consistent across all 12 characters",
		"outline_px": "1-2 px dark ink outline",
	}
