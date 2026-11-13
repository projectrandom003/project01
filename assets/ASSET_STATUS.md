


## Boss overworld silhouette pass — 2026-11-13

- Replaced the shared Elder Hollow / Corrupted Treant placeholder with two distinct hand-drawn animated silhouettes in `scripts/world/actor_visual.gd`.
- Elder Hollow now has a taller tapered trunk-robe, angular hollow bark mask, layered leaf crown, hanging root-beard, branch-cloak arms, lantern-heart and drifting motes.
- Corrupted Treant now has a much broader and taller guardian silhouette, split roots, heavy branch arms, broken antler canopy, separated foliage clumps, bark fissures, violet corruption veins and a flower-like chest core. These are procedural vector-style drawings, not painted sprite sheets.
- Focused `verify_boss_actors.tscn` passed after the change (exit code 0). Live visual inspection is still pending.


## Quest tracking fix + playable Windows build — 2026-11-13

- Fixed tracked quest selection notifications: switching and untracking now refresh both HUD and journal listeners immediately.
- Starting a new quest now makes it the active tracked objective rather than leaving an older quest pinned.
- HUD now displays explicitly tracked available quests as well as active quests.
- Quest distance and bearing now read the live in-world Player node position; the previous implementation only used the last saved position, so compass direction/distance could remain frozen while walking.
- Quest destination fallback now uses the quest's own region spawn instead of always assuming Greenward.
- Verification: `verify_quest_flow.tscn` passed, including selected-quest, switching, live-position, direction and available-quest HUD checks. Full suite: 1,485 passed, 0 failed. Boss actor, arena routing and all 14 authored environment asset checks passed.
- Exported Windows Desktop build successfully. Self-contained executable copied to the user's Desktop as `Project Fantasy Playable.exe` (143,766,632 bytes); exported executable completed a headless startup/quit smoke test with exit code 0.
- Boss appearances are improved procedural in-game silhouettes wired to the supplied design direction; dedicated painted animated boss atlases remain a separate art-production task. Live screenshot visual QA has not yet been completed.


## Greenward zone, path and quest-navigation redesign — 2026-11-13

- Moved the Elder Hollow / First Tree POI and encounter spawn to grid `(-88, 76)`, creating a remote ancient-tree sanctuary distinct from the village and the other boss areas.
- Moved the Withered Estate / Fallen Matron POI and encounter spawn to grid `(116, 78)`, a separate south-eastern ruined conservatory territory. Both are now over 100 grid units from the village and over 200 grid units apart.
- Added separate zone atmospheres and bespoke prop compositions: Elder Hollow uses ancient/willow/dead trees, a root-and-rune ring, spirit blooms, mushrooms and teal/violet heart lights; the Matron estate uses dead/blossom trees, ruined arch and pillars, crystals, pale flowers and violet lights.
- Updated the matching boss quest coordinates. Kill-objective navigation now resolves the nearest live matching roaming monster instead of pointing only at the encounter's authored centre. HUD direction/distance uses this live position and displays tile distance.
- Added `QuestDestinationMarker`: a world-space pulsing beacon with a ground ring, vertical light column, diamond glyph and orbiting sparks; glow intensity rises as the player approaches.
- Added a connected trail network from the village to the Listening Stones, Hollowed Grove, First Tree and Withered Estate. Trail segments now terminate exactly at their POIs; trail width was tuned to 1.0 grid units.
- Increased Greenward primary interactable placements to 17 distributed anchors, plus landmark/secondary placements (22 total under the current cap of 28). Expanded wildlife centres to include both remote boss territories.
- Increased foliage/ground-cover variation: lower tree share, higher flower/mushroom/bush share, variable tree scale 0.68–1.22, flower scale 0.72–1.72, smaller/less frequent companion trees, and a wider mix of rocks, shrubs and ground cover.
- Focused world-layout verification passed (boss separation, village distance, spawn/POI/quest coordinate agreement, four connected POI routes and distributed interactables). Quest-flow verification passed, including live boss-target following and visible beacon positioning. Full regression suite: 1,485 passed, 0 failed.
- Windows Desktop export rebuilt and copied to `C:\\Users\\quoth\\Desktop\\Project Fantasy Playable.exe` (143,545,952 bytes). Exported executable completed a headless startup/quit smoke test with exit code 0.
- Live in-game screenshot QA captured at `C:\\Users\\quoth\\Desktop\\ProjectFantasy_World_QA_Final.png`; it verifies the new chunk foliage and path rendering at the Greenward starting area. Remote boss-zone art is structurally verified but has not yet had a dedicated close-up visual capture.


## Greenward exploration distribution pass — 2026-11-13

- Spread Greenward's collectible/lore interactables into distinct exploration directions instead of clustering them around the village and existing landmarks: Weathered Rune (-18,28), Moonpetal Herbs (34,24), Wisp Lantern (20,38), Glade Shrine (-28,-12), Hollowed Crystal (42,-8), Hilltop Dial (48,18), Trader's Sign (-10,-22), Old Mooring (16,52), Shrine Wisp (34,-28), and Grove Shard (-36,8).
- Raised the bounded interactive-object cap from 8 to 12 so all ten authored locations can spawn; previously the last two were silently omitted.
- Repositioned nine regular monster packs to outlying forest sectors while keeping the three named boss encounters anchored to their boss arenas. Ambient wildlife centres now cover the new exploration sectors too.
- Reduced per-chunk prop cap from 64 to 42 and default prop spawn chance from 0.155 to 0.115 (mobile 0.085), easing the dense visual clutter without removing the forest canopy.
- Regression suite after this pass: 1,485 passed, 0 failed. Windows export completed and replaced the Desktop playable executable (143,766,712 bytes). Headless startup smoke test completed with exit code 0.


## Launch-screen art, animation and duplicate-character fix — 2026-11-13

- Added original 1920×1080 illustrated launch artwork at `assets/ui/backgrounds/launch_forest_background.svg`: moonlit First Tree, layered forest ridges, ruined observatory arch, winding glade path, roots, foreground ferns and atmospheric glow.
- Added `LaunchForestBackdrop`, shared by title, opening prologue and loading screens. It animates drifting mist, moving moonbeams, fireflies/petals and a gently pulsing glade seal.
- Fixed the duplicate Gerald/Lilith during first-time loading: `OpeningCinematic.finished` previously launched LoadingScreen without removing the intro node, so both character layers remained visible. `main.gd` now hides and queues the prologue for deletion before the loading screen is added.
- Rebuilt the prologue composition around only Gerald and Lilith, removing the old extra light-marker motif that visually competed with the character sprites. Loading continues to show one copy of each actual party member.
- Loading screen shade reduced to reveal more background detail.
- Live viewport screenshots inspected at 1280×720 for title, opening prologue and loading. Loading screenshot confirms three party members exactly once; prologue confirms Gerald and Lilith exactly once. All three screens render the same illustrated background with animation.
- Verification: launch transition test passed, including title/prologue/loading background checks, two-character prologue, cleanup before loading, exactly three loading party visuals and successful destination scene load. Full regression suite: 1,485 passed, 0 failed.
- Windows Desktop export completed and copied to Desktop as `Project Fantasy Playable.exe` (143,538,400 bytes). Windows Application Control blocked launching the exported executable from both the build folder and Desktop, so exported-binary smoke testing could not complete on this machine. Godot runtime previews and the full headless regression suite passed.
