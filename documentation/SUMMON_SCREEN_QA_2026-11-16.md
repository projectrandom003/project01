# Summon screen QA and fixes — 2026-11-16

## Findings corrected

- Featured characters were still present in the ordinary rarity pool. That made the displayed featured rate inaccurate (including a nominal 0% rate-up that could still return the featured unit). Featured units are now excluded from the off-banner candidate list; a featured-only rarity pool still resolves safely to its only valid unit.
- The 10-pull Epic floor replaced the last result without applying the featured-pity reset when that replacement was the featured unit. Pity state now reflects the replacement result.
- Repeated clicks during the reveal could trigger overlapping pulls and spend currency more than once. The screen now locks both summon buttons for the complete pull/reveal/result transition and rejects concurrent requests.
- The results "Summon Again" action bypassed the screen-level lock and could offer a pull the player could not afford. It now routes through the same guarded screen entry point, disables itself when funds are insufficient, and explains the shortfall in its tooltip.
- Result cards previously showed only one status. A featured duplicate could hide its NEW, awakening, or guaranteed status. Cards now retain all applicable tags.
- The banner art and details columns could overflow vertically on shorter viewports. Each column now has independent vertical scrolling.
- Result panels assumed a fixed 1120px width and five columns. Their width, column count, and portrait size now adapt to the viewport.

## Verification

- Godot 4.7.2 headless editor import: exit 0, no script/parse/engine errors.
- Runtime summon UI verification: 17 checks passed, 0 failed. Covers column scrolling, selected banner, pull controls, close control, duplicate-request guard, live currency spend, disabled controls during reveal, reveal completion, result-card count/tags, Continue behavior, and narrow-viewport results layout.
- Gacha logic verification: 6 checks passed, 0 failed. Covers off-banner exclusion at 0% rate-up, 50% featured-rate distribution, 10-pull floor, featured-pity reset after floor replacement, hard pity, and pity reset.
- Verification ran against an isolated QA clone with its own save-data directory. The player's existing save was not used or modified by these checks.

## Remaining visual-production limitation

The screen layout and summon mechanics are corrected, but this does not create missing bespoke character illustrations. The existing art pipeline still uses procedural portrait fallbacks for characters without approved summon portrait assets. That art-production gap is separate from the functional and layout fixes above and must not be represented as finished.

## Follow-up UI polish

- Replaced the summon screen's generic photographic backdrop with the authored `summoning_chamber_background.svg` scene art: gothic arches, moonlit violet palette, crystal focus and ritual dais. The existing animated chamber atmosphere remains layered over it.
- Added an explicit `RETURN TO GAME` action to the banner row, a `CLOSE` action during the reveal, and a separate `RETURN TO GAME` action on the results overlay. The results `Continue` action is now labelled `Back to Summon` so it cannot be mistaken for exiting the screen.
- Reduced banner-tab minimum widths so the close action remains usable on narrower desktop windows.
- Reworked the title-screen button grouping with a single translucent glass backing panel. The live controls remain positioned from the fitted artwork's source coordinates, while the backing masks the baked-in lettering beneath them and keeps the six actions visually grouped.
- Added regression assertions for the close controls on the summon page, reveal overlay and results overlay.

## Follow-up verification

- Godot 4.7.2 headless title-screen smoke test: exit 0.
- Godot 4.7.2 headless summon-screen smoke test: exit 0.
- Full project test runner: **1,920 passed, 0 failed** (exit 0).
- The suite emits the expected save-corruption warning from its deliberate recovery test; the suite completes successfully and restores its snapshot.
- Logs: `artifacts/qa/summon_menu_ui_final_tests.log`, `artifacts/qa/ui_visual_fix_title_smoke.log`, and `artifacts/qa/ui_visual_fix_gacha_smoke.log`.
