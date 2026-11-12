# PROJECT FANTASY — First 12 Character Art Specs

> **ZERO final assets exist.** All shipped visuals are RUNTIME PROCEDURAL PLACEHOLDER art.
> This is a human-readable index of the 12 authored art SPECIFICATIONS (contracts), not a gallery.
> Machine-readable source: `scripts/art/character_art_spec.gd` (`CharacterArtSpec`).

## Character table

| id | name | race | element | rarity | role | visual theme | full spec |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `lyra_vey` | Lyra Vey | Elf | wind | epic | Ranged Support | Mint-and-emerald wind warden; drifting leaf and ribbon motifs, cool teal accent glow, soft rounded ally silhouette. | [`assets/characters/lyra_vey/SPEC.md`](characters/lyra_vey/SPEC.md) |
| `bramble` | Bramble | Beastkin | earth | rare | Bruiser | Earthy bark-and-moss bruiser; warm lantern-gold accents, rounded friendly silhouette, thorn and root motifs. | [`assets/characters/bramble/SPEC.md`](characters/bramble/SPEC.md) |
| `seraphine` | Seraphine Ael | Angel | light | legendary | Healer | Ivory-and-gold dawn angel; sunburst and halo motifs, a warm radiant aura, ornate premium LEGENDARY ornamentation, soft rounded ally silhouette. | [`assets/characters/seraphine/SPEC.md`](characters/seraphine/SPEC.md) |
| `nyx` | Nyx Vaelora | Demon | dark | legendary | Mage | Hollow-moon violet queen; eclipse, void-disc and thorned-crown motifs, rose-magenta arcane glow, sharp regal silhouette, ornate premium LEGENDARY ornamentation. | [`assets/characters/nyx/SPEC.md`](characters/nyx/SPEC.md) |
| `coralyn` | Coralyn Tide | Mermaid | water | epic | Healer | Lagoon-and-coral tide singer; wave, bubble and shell motifs, pale-aqua glow, fluid rounded ally silhouette. | [`assets/characters/coralyn/SPEC.md`](characters/coralyn/SPEC.md) |
| `ignis` | Ignis Karroth | Dragonkin | fire | mythic | Damage | Charred-crown dragonkin; cinder, ash and molten-gold motifs, a roaring ember aura, asymmetric sharp silhouette, the most ornate premium MYTHIC tier. | [`assets/characters/ignis/SPEC.md`](characters/ignis/SPEC.md) |
| `mira_sol` | Mira Sol | Human | light | common | Tank | Humble steel-and-dawn squire; plain gate-and-shield motifs, a pale dawn-gold accent, a simple honest rounded silhouette (ordinary COMMON tier, no ornamentation). | [`assets/characters/mira_sol/SPEC.md`](characters/mira_sol/SPEC.md) |
| `thistle` | Thistle | Spirit | wind | rare | Support | Warm wishlight wisp; lantern, dandelion-seed and paper-wish motifs, a soft mint-and-gold glow, a small rounded glowing silhouette. | [`assets/characters/thistle/SPEC.md`](characters/thistle/SPEC.md) |
| `vespera` | Vespera Noct | Vampire | dark | epic | Assassin | White-mourning vampire assassin; black-rose, candle and waltz motifs, a rose-pink accent, a sharp elegant silhouette and dark-plum lining. | [`assets/characters/vespera/SPEC.md`](characters/vespera/SPEC.md) |
| `arachnia` | Arachnia Silk | Monster Girl | dark | epic | Controller | Quiet-web weaver; spider-silk, tapestry-map and eight-strand motifs, a chartreuse glow against deep aubergine, an elegant asymmetric silhouette. | [`assets/characters/arachnia/SPEC.md`](characters/arachnia/SPEC.md) |
| `terra` | Terra Rootheart | Ancient | earth | legendary | Tank | Mountain-that-remembers; cliff-strata, standing-stone and deep-root motifs, pale moss-glow seams, a monumental rounded-rock silhouette, ornate premium LEGENDARY ornamentation. | [`assets/characters/terra/SPEC.md`](characters/terra/SPEC.md) |
| `kael` | Kael Ashford | Human | fire | rare | Damage | Bannerless ember sellsword; charred-banner, ash and ember motifs, an ember-gold accent, a sharp pragmatic silhouette (unadorned RARE tier). | [`assets/characters/kael/SPEC.md`](characters/kael/SPEC.md) |

## Rarity distribution

- Mythic (1): `ignis` — distinct highest premium tier (roaring ember aura, Crown of Cinders, ornate obsidian-gold frame).
- Legendary (3): `seraphine`, `nyx`, `terra` — extra ornamentation, a persistent aura motif, a premium engraved frame.
- Epic (4): `lyra_vey`, `coralyn`, `vespera`, `arachnia`.
- Rare (3): `bramble`, `thistle`, `kael`.
- Common (1): `mira_sol` — plain, unornamented standard tier.

## Shared art direction

One consistent original anime-fantasy direction across all 12: ~6-head heroic proportions, upper-left
key light, a 1-2 px dark ink outline, cel-shaded painterly rendering, transparent RGBA8 backgrounds,
and element-motif accents. Colours come from each character's `characters.json` palette and the
`GreenwardStyle` groups. Legendary/Mythic carry a distinct visual tier. No copyrighted characters,
logos or reference traces. Identity fields are verbatim from `resources/data/characters.json`; the
descriptive fields are authored from existing lore/title/role/palette and do NOT alter gameplay data.

## Pointer to each SPEC.md

- [`assets/characters/lyra_vey/SPEC.md`](characters/lyra_vey/SPEC.md) — full spec, asset file list, animation/portrait requirements, three detailed generation prompts, exact output specs.
- [`assets/characters/bramble/SPEC.md`](characters/bramble/SPEC.md) — full spec, asset file list, animation/portrait requirements, three detailed generation prompts, exact output specs.
- [`assets/characters/seraphine/SPEC.md`](characters/seraphine/SPEC.md) — full spec, asset file list, animation/portrait requirements, three detailed generation prompts, exact output specs.
- [`assets/characters/nyx/SPEC.md`](characters/nyx/SPEC.md) — full spec, asset file list, animation/portrait requirements, three detailed generation prompts, exact output specs.
- [`assets/characters/coralyn/SPEC.md`](characters/coralyn/SPEC.md) — full spec, asset file list, animation/portrait requirements, three detailed generation prompts, exact output specs.
- [`assets/characters/ignis/SPEC.md`](characters/ignis/SPEC.md) — full spec, asset file list, animation/portrait requirements, three detailed generation prompts, exact output specs.
- [`assets/characters/mira_sol/SPEC.md`](characters/mira_sol/SPEC.md) — full spec, asset file list, animation/portrait requirements, three detailed generation prompts, exact output specs.
- [`assets/characters/thistle/SPEC.md`](characters/thistle/SPEC.md) — full spec, asset file list, animation/portrait requirements, three detailed generation prompts, exact output specs.
- [`assets/characters/vespera/SPEC.md`](characters/vespera/SPEC.md) — full spec, asset file list, animation/portrait requirements, three detailed generation prompts, exact output specs.
- [`assets/characters/arachnia/SPEC.md`](characters/arachnia/SPEC.md) — full spec, asset file list, animation/portrait requirements, three detailed generation prompts, exact output specs.
- [`assets/characters/terra/SPEC.md`](characters/terra/SPEC.md) — full spec, asset file list, animation/portrait requirements, three detailed generation prompts, exact output specs.
- [`assets/characters/kael/SPEC.md`](characters/kael/SPEC.md) — full spec, asset file list, animation/portrait requirements, three detailed generation prompts, exact output specs.

**Status of every character: MISSING (final) / TEMPORARY (procedural fallback).** No final artwork was generated or fabricated in this phase.
