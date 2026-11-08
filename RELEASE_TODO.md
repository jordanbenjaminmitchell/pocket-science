# Pocket Science — Release To-Do (game only)

What still needs to be **created** or **revamped** before a full 1.0 release. This list covers the game only: store page, marketing and trailer are out of scope.

**Priorities**
- **P0:** required to ship.
- **P1:** expected at launch.
- **P2:** nice to have / post-launch.

**Where things stand (2026-11-07):**
- **Systems built:** physics, guideline, scoring, run loop, shop, saves, music, headless tests and a balance bot.
- **Content:** 31 Formulas, 5 Reagents, 4 Isotopes, 5 Cues, 5 Labs, 6 Anomalies, 10 Bounties, 9 tables + endless, 10 music tracks.
- **Not done yet:** human playtesting.

---

## 1. Known bugs and must-fix issues

- [x] **P0 — Frame-rate-dependent physics speed.** Fixed 2026-11-07: a fixed-step accumulator (`_sim_steps`) drives both the shot and the title demo. `tests/test_timing.gd` checks 30–360 Hz, 4× fast-forward and hitch clamping.
- [ ] **P2 — Render interpolation above 240 Hz.** Above the 240 Hz physics rate, some frames advance no physics step, which may cause slight judder. Interpolate ball positions between steps.
- [x] **P0 — Mid-table save.** Done 2026-11-07: save format v2 saves after every shot (all balls, score, chalk, streak, hot pocket, bounty, shot log) and on every shop change. `tests/test_continue.gd` quits and continues both mid-table and in the shop.
- [x] **P0 — Save versioning and corruption handling.** Done 2026-11-07: atomic temp→rename writes, a `.bak` of the previous save used when the main file is unreadable, v1→v2 migration, and validation that drops unknown content ids. Covered in `tests/test_rules.gd`.
- [x] **P0 — Stuck-ball edge cases.** Done 2026-11-07: `tests/test_fuzz.gd` runs random racks, labs, spin, heavy balls, closed pockets and magnet pockets. A 3,000-shot soak gave 0 timeouts, NaNs, overlaps or escapes (max settle 8.1 s); 400 shots run in the normal suite (`FUZZ_SHOTS` raises it).
- [x] **P1 — Clean shutdown.** Done 2026-11-08: a real windowed exit reports no leaks; music streams are released on quit. Headless runs still warn, because the audio thread does not run there.
- [x] **P1 — Pause.** Done 2026-11-08: pauses from aiming, strike, rolling, tally, shop and table-clear (`tests/test_input.gd`).
- [x] **P1 — Startup hitch.** Measured 2026-11-08: sound setup takes 130 ms, so no change was needed.
## 2. Pool physics and feel

- [ ] **P0 — Human feel pass.** Tune:
  - aim sensitivity
  - drag distance for full power (`DRAG_FULL`)
  - power curve (`p^1.35`)
  - max speed
  - cloth friction
  - cushion restitution
  
  Get feedback from at least 5 people.
- [ ] **P1 — Real sliding → rolling transition** for the cue ball. Follow and draw are currently approximated by a "pending spin velocity". Model sliding friction properly so stun, follow and draw distances feel authentic.
- [ ] **P1 — English.** Add throw on cut shots (spin-induced throw) and more accurate side-spin off cushions. Then update the guideline so it still matches.
- [x] **P1 — Rattle feedback.** Done 2026-11-08: hard knocks at a pocket mouth play a rattle with a small shake. Separate corner/side acceptance tuning moved into the human feel pass.
- [x] **P1 — Ball-in-hand rules.** Done 2026-11-08: behind the head string after a scratch on the break, anywhere otherwise; gold lines show the pots available from the spot.
- [ ] **P2 — Optional advanced shots:** masse/curve and jump. Only if they fit the game, possibly as Formulas.
- [ ] **P2 — Cross-platform determinism check.** Verify identical results on Windows, Mac and Linux (needed for seeded and daily runs).

## 3. Aiming, controls and input

- [x] **P0 — Input settings, part 1.** Done 2026-11-07: keyboard fine-aim speed and pull-back distance for full power (`tests/test_settings.gd`).
- [x] **P0 — Input settings, part 2.** Done 2026-11-07: "Invert pull-back" and "Click to shoot" toggles; hints adapt. Checked with injected mouse input in `tests/test_settings.gd`.
- [x] **P1 — Gamepad.** Done 2026-11-08: aim, precision, power, spin, reagents, pocket picking, run info, pause and menus, tested with simulated input. Not yet tried on physical hardware or a Steam Deck.
- [x] **P1 — Keyboard navigation.** Done 2026-11-08: arrows and Enter drive every menu, with a visible focus ring for keyboard and gamepad users only.
- [x] **P1 — Key rebinding.** Done 2026-11-08: Settings → Controls; duplicates swap.
- [ ] **P2 — Aim zoom / camera:** hold to magnify around the contact point for thin cuts.
- [ ] **P2 — Touch controls** (future mobile or tablet port).

## 4. Scoring, economy and balance

- [ ] **P0 — Human balance playtests.** Run at least 30 full runs and record:
  - win rate per cue
  - where runs die
  - average money per table
  - most-bought and never-bought items
- [ ] **P0 — Re-tune targets for humans.** Current targets are tuned from the bot only (0.25° aim error wins about 25%).
- [x] **P1 — Formula outliers.** Re-checked 2026-11-08 over 220 simulated runs: every Formula gets bought and none dominates. Insurance and Elastic Collision were capped earlier. Further tuning needs human play.
- [x] **P1 — Formula ordering.** Decided 2026-11-08: slot order does not matter. The fixed rule, all + bonuses then all × multipliers, is stated in How to Play and Run Info.
- [x] **P1 — Endless escalation.** Done 2026-11-08: targets climb, every second table is a boss, Chalk wears down to a floor of 2.
- [x] **P1 — Difficulty ladder.** Done 2026-11-08: five Stakes above Standard, each unlocked by winning the one before.
- [ ] **P2 — Boss rewards.** Bosses could drop a guaranteed rare or let you choose one of 3.

## 5. Content (needs creating)

- [x] **P0 — More Formulas.** Done 2026-11-07: 60 Formulas in nine synergy families, each covered by `tests/test_formulas.gd`.
- [x] **P0 — More Anomalies.** Done 2026-11-07: 15 bosses, tested and tuned over emulated playtests.
- [x] **P1 — More Labs.** Done 2026-11-08: 10 labs, each with its own rule, cloth, rail and emblem.
- [x] **P1 — More Reagents.** Done 2026-11-08: 15.
- [x] **P1 — More Isotopes.** Done 2026-11-08: 8.
- [x] **P1 — More Bounties.** Done 2026-11-08: 25, and boss tables pay gold bounties worth double.
- [x] **P1 — More Cues.** Done 2026-11-08: 10, unlocked through 14 milestones.
- [ ] **P2 — Rack variants:** 7-ball, 10-ball, 15-ball with a "money ball" rule, special racks on bosses.

## 6. Meta-progression

- [x] **P0 — Unlock system.** Done 2026-11-07: 10 milestones unlock 4 Cues and 32 Formulas from a 28-Formula start (`src/game/meta.gd`, `tests/test_meta.gd`). Labs are not gated; that is a possible later addition.
- [x] **P1 — Collection screen.** Done 2026-11-08: every Formula, Reagent, Isotope, Cue, Lab and Boss, with unlock hints.
- [x] **P1 — Run history and stats.** Done 2026-11-08: Records screen with lifetime totals, favourite Formulas and recent runs.
- [x] **P1 — Seeded runs.** Done 2026-11-08: numbers or words; the same seed gives the same tables, racks and first shop offers.
- [x] **P1 — Daily challenge.** Done 2026-11-08: fixed seed, cue and full pool per day, with a local best.
- [ ] **P2 — In-game achievement list** (mirrors platform achievements later).

## 7. UI / UX revamp

- [x] **P0 — Run info screen.** Done 2026-11-07: Tab or the side-panel button opens it, and it pauses play. It shows formulas with full text, reagents, enhanced balls, the 9-table plan with bosses and progress, scoring rules adapted to your build, stats, cue and seed. `tests/test_screens.gd` checks layout and the Tab toggle, and now also asserts the side panel fits on screen with a full build.
- [x] **P0 — Settings screen.** Done 2026-11-07, from the title and pause menus:
  - master/music/SFX sliders
  - fullscreen and vsync
  - screen-shake amount
  - reduced motion
  - erase progress, with confirmation
  
  Settings persist and old audio toggles migrate. Covered by `tests/test_settings.gd`; on-screen layout of every overlay is checked by `tests/test_screens.gd`.
- [x] **P1 — Settings, remaining.** Done 2026-11-08: window size, frame cap, colour-blind palette, number tags, larger text.
- [x] **P1 — Shop revamp.** Done 2026-11-08: family and synergy highlights, two-step selling, cards dealt in, new-player tip.
- [x] **P1 — Tally presentation.** Done 2026-11-08: music ducks, huge-shot moment, skip prompt.
- [x] **P1 — Tutorial.** Done 2026-11-08: on-table coach for the break, gold line, streak and hot pocket, plus a first-shop tip.
- [x] **P1 — Layout fixes.** Done 2026-11-08: banner moved onto the bottom rail, side panel proven to fit every boss and bounty.
- [x] **P1 — Resolution and aspect ratios.** Done 2026-11-08: rendered at 1280×720, 1280×800 and ultrawide (letterboxed). 4K scales the same way but was not rendered, as this display cannot show it.
- [ ] **P2 — Localization pipeline.** Move all strings into translation files (currently inline in `catalog.gd` and `main.gd`).

## 8. Visual art (currently procedural placeholders)

- [x] **P0 — Card icons.** Done 2026-11-08: one consistent vector medallion per Formula and Reagent, coloured by family (`src/ui/icon_art.gd`); Isotopes use the ball itself. No system-font or emoji dependence.
- [ ] **P2 — Illustrated card art** by an artist, if the vector set is not enough for the final look.
- [x] **P0 — Title logo and app icon.** Done 2026-11-08: animated 8-ball atom mark and wordmark (`src/ui/logo_art.gd`), window icon `assets/icon.png`.
- [ ] **P1 — Key art** for the store and launcher.
- [x] **P1 — Table art per Lab.** Done 2026-11-08.
- [x] **P1 — Room background.** Done 2026-11-08: lamp-lit hex floor.
- [x] **P1 — Ball polish.** Done 2026-11-08: numbers sit on the sphere, turning and foreshortening with the roll.
- [ ] **P1 — Cue polish:**
  - cue model per starting cue with more detail
  - cue strike follow-through
  - chalking animation between shots
- [x] **P1 — Effects pass.** Done 2026-11-08: hot-pocket embers, boss arrival flash, table fades, celebrations, particle cap.
- [ ] **P2 — Cosmetic unlocks:** cloth colours, ball sets, cue skins.

## 9. Audio

- [ ] **P0 — Replace synthesized SFX with designed or recorded sounds:**
  - ball clicks (velocity layers)
  - cushion thuds
  - pocket drops with rattle and roll-down
  - cue strike
  - UI
  - tally ticks
  - ×Mult hits
  - coins
  - fanfare
- [x] **P1 — Mixing pass.** Done 2026-11-08: click limiting and music ducking; all 18 tracks measured within 0.3 LUFS. Needs a human ear for final levels.
- [x] **P1 — Music coverage.** Done 2026-11-08: a track for every lab, shop, bosses, endless and victory. Loop seams not yet checked by ear.
- [ ] **P2 — Ambient room tone, and crowd/announcer stingers** for big shots.

## 10. Code health and tech

- [x] **P0 — Windows build.** Done 2026-11-08: `./build_windows.sh` writes a standalone `export/windows/` (`PocketScience.exe` + `.pck`); launched and recorded from an empty folder. It uses the Godot runtime as the exe, so it is about 197 MB.
- [x] **P1 — Final-size builds.** Done 2026-11-08: official templates installed; `./build_windows.sh` and `./build_android.sh` make release builds.
- [x] **Android build.** Done 2026-11-08: touch controls, landscape, back button. Installed and played on a Pixel 8 emulator (finger aim and SHOOT confirmed). Not yet tried on a physical phone.
- [ ] **P1 — Windows exe icon.** The .exe file still shows Godot's icon; needs rcedit configured. The in-game window icon is correct.
- [ ] **P1 — Play Store signing.** The APK uses the local debug key, fine for sideloading. A store release needs a private keystore.
- [ ] **P1 — Split `main.gd`** (about 1,850 lines) into controller, HUD, shop, screens, tally and input modules.
- [ ] **P1 — Data-drive content.** Move Formula effects out of the big `if` chain in `scorer.gd` into per-formula hook definitions, so adding 30 more stays manageable.
- [x] **P1 — Automated checks.** Done 2026-11-08: `tools/ci.sh` runs every suite, every persona and the build. It runs locally, as the project has no remote server yet.
- [ ] **P1 — Performance pass:**
  - profile breaks with 15 balls plus effects
  - forecast budgeting on slow machines
  - particle caps
- [ ] **P2 — Replay system.** The sim is deterministic: record shots and replay best shots or share seeds.

## 11. Accessibility

- [x] **P1 — Colour-blind support.** Done 2026-11-08: safe palette, bold versus dashed guideline shapes, number tags, tray and ×2 labels.
- [x] **P1 — Other accessibility options.** Done 2026-11-08: reduced motion, larger text, click-to-shoot (no holding), on-table text for scratches and rattles.
- [ ] **P2 — Slower-tally and auto-fast-forward options.**

## 12. Licensing housekeeping (in-game)

- [x] **P0 — Credits screen.** Done 2026-11-07: Title → Credits, with an in-game viewer for the Chakra Petch and Silkscreen OFL texts and the Godot licence (`licenses/`).
- [x] **P0 — Ship the licence files.** Done 2026-11-08: included in the `.pck` (viewer in Credits) and copied beside the exe; confirmed inside the built pack.
- [x] **P1 — Content audit.** Done 2026-11-08: no third-party names in the code; fonts, engine and music licences ship with the game. Not a legal review.
