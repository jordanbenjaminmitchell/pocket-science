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
- [ ] **P1 — Clean shutdown.** Fix the ObjectDB/RID leak warnings at exit.
- [ ] **P1 — Pause.** Make pause work from every state, including STRIKE, TALLY, the shop and table-clear, and make sure no tween or timer fires while paused.
- [ ] **P1 — Startup hitch.** Sound synthesis (~4 s of samples) runs on the main thread at launch. Pre-bake the sounds or move synthesis to a thread.

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
- [ ] **P1 — Pocket behaviour.** Add a distinct "rattle" outcome: jaw bounces with sound and a small shake. Also tune corner versus side pocket acceptance separately.
- [ ] **P1 — Ball-in-hand rules.**
  - Decide and implement: behind the head string after a scratch on the break, anywhere otherwise.
  - Show the guideline while placing.
- [ ] **P2 — Optional advanced shots:** masse/curve and jump. Only if they fit the game, possibly as Formulas.
- [ ] **P2 — Cross-platform determinism check.** Verify identical results on Windows, Mac and Linux (needed for seeded and daily runs).

## 3. Aiming, controls and input

- [x] **P0 — Input settings, part 1.** Done 2026-11-07: keyboard fine-aim speed and pull-back distance for full power (`tests/test_settings.gd`).
- [ ] **P0 — Input settings, part 2:**
  - invert drag direction
  - "click to shoot" alternative scheme (set power first, click to fire)
- [ ] **P1 — Full gamepad support.** Covers aim, fine aim, power (trigger pull-back), spin (right stick), reagents, shop navigation and menus. Also Steam Deck layout.
- [ ] **P1 — Keyboard navigation** for every menu and the shop (focus states are currently invisible).
- [ ] **P1 — Key rebinding.**
- [ ] **P2 — Aim zoom / camera:** hold to magnify around the contact point for thin cuts.
- [ ] **P2 — Touch controls** (future mobile or tablet port).

## 4. Scoring, economy and balance

- [ ] **P0 — Human balance playtests.** Run at least 30 full runs and record:
  - win rate per cue
  - where runs die
  - average money per table
  - most-bought and never-bought items
- [ ] **P0 — Re-tune targets for humans.** Current targets are tuned from the bot only (0.25° aim error wins about 25%).
- [ ] **P1 — Formula outliers.** Re-check:
  - Catalyst (unbounded growth)
  - Laplace's Demon (forecast may trivialise play)
  - Supernova / Fusion / Chain stacking
  - Elastic Collision (capped at 12; verify on 15-ball breaks)
- [ ] **P1 — Formula ordering.** Decide whether slot order matters, as in Balatro. If yes, add drag-to-reorder and order-dependent ×Mult; if no, explain the fixed "+ then ×" rule in the UI.
- [ ] **P1 — Endless mode scaling.** Endless targets currently grow by ×1.6 per table. Endless needs its own escalation (harder anomalies, stacked anomalies).
- [ ] **P1 — Difficulty ladder.** Add stakes/ascension levels unlocked by winning, e.g.:
  - less chalk
  - tighter pockets
  - higher targets
  - pricier shop
- [ ] **P2 — Boss rewards.** Bosses could drop a guaranteed rare or let you choose one of 3.

## 5. Content (needs creating)

- [ ] **P0 — More Formulas: 31 → about 60.** Build them in synergy families so builds feel different:
  - banks / cushions
  - combos / chain
  - streak / momentum
  - pocket-specific
  - ball-number (odd/even/prime/stripes)
  - economy
  - risk/reward (e.g. "×4 Mult, but misses cost 2 chalk")
  - physics-changers
  
  Use the 135 v21 tricks and the "Next 50" doc as an idea pool. Pick by fun and do not port blindly.
- [ ] **P0 — More Anomalies (bosses): 6 → about 15**, so bosses rarely repeat. Ideas:
  - moving hot pocket mid-shot
  - one pocket only
  - "no repeats" (each pocket scores once)
  - double friction
  - mirror table
  - timed shots
  - invisible 8
- [ ] **P1 — More Labs: 5 → about 10**, each with its own physics rule and cloth look. v21 ideas: portals, conveyor/current, magnet fields, narrow table, split circuit.
- [ ] **P1 — More Reagents: 5 → about 15.** Ideas: re-rack, swap two balls, freeze a ball, extra cue ball, guide-everything for one shot, "call shot" ×3.
- [ ] **P1 — More Isotopes: 4 → about 8.** Ideas: radioactive (+Mult that decays), magnetic, ghost (passes through the cue once), bouncy, split.
- [ ] **P1 — More Bounties: 10 → about 25**, plus harder "gold bounties" on boss tables.
- [ ] **P1 — More Cues: 5 → about 10**, unlocked through play (see §6).
- [ ] **P2 — Rack variants:** 7-ball, 10-ball, 15-ball with a "money ball" rule, special racks on bosses.

## 6. Meta-progression

- [ ] **P0 — Unlock system.** Cues, Formulas and Labs unlock by playing (e.g. "win with Optic Cue", "pot 3 balls in one shot"). Start new players with a curated subset.
- [ ] **P1 — Collection / compendium screen:** every Formula, Reagent, Isotope, Lab and Anomaly, with locked/unlocked state and unlock hints.
- [ ] **P1 — Run history and stats:** per-run summaries, lifetime stats, best shots, favourite formulas.
- [ ] **P1 — Seeded runs UI.** Seeds already exist in code; add entry and display.
- [ ] **P1 — Daily challenge:** a fixed seed per day with a local best score.
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
- [ ] **P1 — Settings, remaining:** windowed resolution choice, frame cap, guideline options (colour palette, length), text size.
- [ ] **P1 — Shop revamp:**
  - hover-to-inspect with synergies highlighted ("works with your Bank formula")
  - sell confirmation
  - "can't afford" feedback
  - reroll animation
  - card flip-in
- [ ] **P1 — Tally presentation:**
  - chips/mult boxes animate in sequence alongside the table popups
  - a big "×" moment
  - score counter overflow effects for huge shots
  - skip/fast-forward indicator
- [ ] **P1 — Tutorial.** Expand the coach into a short guided first table covering break, gold line, streak, hot pocket and the shop, so it no longer depends only on the help text.
- [ ] **P1 — Layout fixes:**
  - the banner can still cover balls
  - the left-panel gap below the tray
  - card text overflow in shop mode
  - the hot pocket ×2 label position on corner pockets
- [ ] **P1 — Resolution and aspect ratios:** support 16:10, ultrawide, 4K, and test at 1280×720.
- [ ] **P2 — Localization pipeline.** Move all strings into translation files (currently inline in `catalog.gd` and `main.gd`).

## 8. Visual art (currently procedural placeholders)

- [ ] **P0 — Formula / Reagent / Isotope card art.** Cards currently use Unicode glyphs; each needs an illustrated icon in one consistent style.
- [ ] **P0 — Title logo and key art.**
- [ ] **P1 — Table art per Lab:**
  - unique rail materials (wood, chrome, lab-metal)
  - cloth textures
  - pocket hardware
  - lab-themed decals
- [ ] **P1 — Room/background environment** around the table (lab setting, overhead lamp, ambient light) instead of a flat dark backdrop.
- [ ] **P1 — Ball polish:**
  - real number decals (font on the sphere instead of 2D text over it)
  - better isotope visuals
  - pocket drop animation through the net or tray
- [ ] **P1 — Cue polish:**
  - cue model per starting cue with more detail
  - cue strike follow-through
  - chalking animation between shots
- [ ] **P1 — Effects pass:**
  - unified particle style
  - hot pocket flame
  - streak "on fire" evolution
  - boss intro sequence
  - table-clear celebration
  - screen transitions
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
- [ ] **P1 — Mixing pass:**
  - music ducking during the tally
  - limit simultaneous clicks on breaks
  - consistent loudness across tracks
- [ ] **P1 — Music coverage:** a dedicated track for every Lab, the shop, bosses and victory, with seamless loop points (check the MP3 loop gaps).
- [ ] **P2 — Ambient room tone, and crowd/announcer stingers** for big shots.

## 10. Code health and tech

- [ ] **P0 — Desktop builds.** Install Godot export templates and set up export presets for Windows (and Mac/Linux if targeted). Currently the game runs only through the bundled editor binary.
- [ ] **P1 — Split `main.gd`** (about 1,850 lines) into controller, HUD, shop, screens, tally and input modules.
- [ ] **P1 — Data-drive content.** Move Formula effects out of the big `if` chain in `scorer.gd` into per-formula hook definitions, so adding 30 more stays manageable.
- [ ] **P1 — CI.** Run `run_tests.sh`, the guideline trust test and a short bot balance check on every commit.
- [ ] **P1 — Performance pass:**
  - profile breaks with 15 balls plus effects
  - forecast budgeting on slow machines
  - particle caps
- [ ] **P2 — Replay system.** The sim is deterministic: record shots and replay best shots or share seeds.

## 11. Accessibility

- [ ] **P1 — Colour-blind support:**
  - alternative guideline colours (gold/orange/white/blue)
  - patterned hot-pocket indicator
  - ball identification beyond colour
- [ ] **P1 — Other options:**
  - reduced-motion mode (no shake/punch/confetti)
  - adjustable text size
  - hold-free input options
  - subtitle-style captions for audio cues (e.g. "rattle")
- [ ] **P2 — Slower-tally and auto-fast-forward options.**

## 12. Licensing housekeeping (in-game)

- [ ] **P0 — Credits screen** covering fonts (Chakra Petch, Silkscreen — include their OFL licences), the Godot licence notice, and the music (original Pocket Science score).
- [ ] **P1 — Content audit.** Confirm every name and asset is original and shipped licence files are present.

---

### Suggested order
1. **P0 bugs and feel:** §1, plus the §2 feel pass.
2. **Human playtests:** §4.
3. **Content expansion with unlocks:** §5 and §6.
4. **UI and art pass:** §7 and §8.
5. **Audio:** §9.
6. **Builds and housekeeping:** §10–12.
