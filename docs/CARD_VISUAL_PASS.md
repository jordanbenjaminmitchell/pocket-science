# Card and ball visual pass — worktree handoff

Updated on 2026-11-13. At the user's request these changes were committed together with the ball pop-up, rack hover and cue card pop-up work, and released as 1.43.

## User direction

- Give Elements a consistent visual sequence. The user clarified on 2026-11-13: **"Rarity colors on cards."** Element card bodies, shop frames, owned-card frames, and collection rows now use rarity colors. The atomic-number chip keeps the red-to-violet 1–100 sequence as a secondary cue. Collection ordering remains its existing mixed order; grouping/sorting by rarity has not been requested explicitly.
- All side-bet cards should use the same brown.
- Catalysts should have one recognizable category color.
- Isotopes should show a ball outline/glow, and Exotic balls should show the ball itself, rather than periodic-table cards. Both need hover detail popups.

## Implemented locally

- `src/game/catalog.gd`: central category colors and `element_color(z)` mapping numbers 1–100 to distinct red-through-violet hues.
- `src/ui/tile_art.gd`, `src/ui/thumb_art.gd`, `src/ui/icon_art.gd`: Element card bodies and thumbnail frames use rarity colors; atomic-number chips and standalone Element icons use the atomic hue. Catalyst cards/icons use steel blue; all side-bet tiers use brown. Rarity names and the rarity-colored Element subline remain.
- `src/ui/meta_screens.gd`: Element collection rows use rarity colors. Isotope and Exotic row frames are neutral so the ball/glow remains the identifier.
- `src/main.gd`: shop and owned Element card frames use rarity colors; table-range marks use atomic hues. Catalyst offer/HUD accents use steel blue. Isotope offers show a glowing ball or glowing numbered ball, Exotic offers show their ball art, and both open ball-based detail on hover. Their offer layout still has a neutral panel for the name, description, price, and buy button; it has no periodic-table tile art.
- `tests/test_card_palette.gd`: focused checks for 100 ordered hues, uniform side-bet brown, ball visuals instead of tile art, and Isotope/Exotic hover popups.

## Verification

- `tests/test_card_palette.gd`: 0 failures.
- `tests/test_content.gd`: 0 failures.
- `tests/test_intro.gd`: 0 failures.
- `git diff --check`: clean.
- Visual captures were generated locally at `runtime/color_shop.png` and `runtime/isotope_popup.png` (ignored by Git). Headless Godot tests still print resource-leak warnings at shutdown despite passing assertions.

## Before publishing

Released in 1.43. The shop was checked in a capture at game resolution: Element cards and owned-card frames use rarity colours.

## Follow-up: shop fit and ball score toggle (2026-11-14)

Implemented after the 1.44 release and published in the 1.45 APK:

- `src/main.gd`: the Pro Shop uses a fixed 884-unit-high panel at Y=8, independent of the table's wide-screen vertical offset. The next-table description and offer cards scroll; the reroll/remove controls and **Next table** button stay visible at the bottom even with long descriptions. The score panel has a **1× VALUES / HIDE VALUES** toggle.
- `src/main.gd` and `src/ui/ball_score_overlay.gd`: while aiming, placing, picking, or holding a shot, each live object ball gets its solo-sink point value. It uses `Scorer.score()` with current Heat, Elements, Isotopes, ball effects, and table rule, while excluding hot/focus pocket multipliers. The unsafe 8 shows its penalty. Badges avoid one another and the balls, with leader lines to displaced badges. Values refresh four times per second; positions follow balls each frame.
- `tests/test_shop_values.gd`: checks ordinary 1× scoring, crowded and edge racks, and Classic/Wide shop fit with forced long content.
- Visual previews: `runtime/shop_layout_check.png` and `runtime/score_values_preview.png` (ignored by Git).

Verification: `tests/test_shop_values.gd`, `tests/test_screens.gd`, `tests/test_layout.gd`, and `tests/test_scoring.gd` pass with 0 failures; `git diff --check` is clean. Headless tests may print resource-leak warnings on exit.
