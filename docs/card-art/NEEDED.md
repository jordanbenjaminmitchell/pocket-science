# Card art and Element rework: handoff

**All art from the 2026-11-12 brief is done.** That covers the Element tiles (atomic numbers, group colours, element looks, new names and short descriptions), the 23 temporary symbols, the Catalyst tiles, special balls drawn as balls, the starting cue tiles, the side bet cards, the table art and the music. Everything is drawn in code:

- Tiles: `TileArt` in [src/ui/tile_art.gd](../../src/ui/tile_art.gd)
- Side bet cards: `BetCard` in [src/ui/bet_card.gd](../../src/ui/bet_card.gd)
- Table art: `BoardArt` in [src/view/board_art.gd](../../src/view/board_art.gd)

The Element names and the Elements whose rules changed are in [docs/ELEMENTS_REWORK.md](../ELEMENTS_REWORK.md).

## For the coding chat: read this first (2026-11-12)

**Status, 2026-11-13:**
- Version 1.40 is released on GitHub with the Windows zip and the APK.
- A full check on master passed: all 25 test suites, all six simulated players (`FULL=1 ./tools/ci.sh`) and both builds.
- **Music is complete.** All 26 boards in the game and all 40 planned boards have a track. Every `Sfx.TRACKS` entry points to a file that exists (47 board tracks, plus the title, shop, endless and victory tracks). No new music is needed for the planned boards. If a board gets a different id from the one in `Sfx.TRACKS`, rename the entry.
- **Your next job** is building the Sharks and moving parts. See "Next job for the coding chat" below. Their art is finished and waiting in `BoardArt`.

The art chat also changed game code, and everything is merged on master: commits `8a39668` and `6473061`. All 25 test suites pass. **None of the rule changes have been played yet.** [docs/ELEMENTS_REWORK.md](../ELEMENTS_REWORK.md) lists every Element with its old and new rules.

### Rules that changed (Elements)

The user asked for Elements that change the physics or trigger on a moment rather than add points. Elements stay passive: nothing to press.

| Element (id) | Now | Was |
|---|---|---|
| Hydrogen Balloon (`featherweight`) | Object balls at 70% weight | 75%. It took Hydrogen (Z 1) from `catalyst`, which is now Beryllium (Z 4) |
| Lead Anchor (`laststripe`) | The 8 weighs 300% and pockets reject it while other balls remain | Last stripe ×5 |
| Holmium Magnet (`hothand`) | At Heat 3+, pockets pull rolling balls | +30 at Heat 3+ |
| Tungsten Core (`lever`) | Stripes weigh 140% and lose no speed off cushions | Long sinks ×1.5 |
| Rubidium Rush (`racing`) | Stripes weigh 70% and have 80% grip | Stripes at 60%+ power ×2 |
| Dysprosium Domino (`domino`) | Ball-to-ball restitution 1.0 | Combinations +30 |
| Gallium Glide (`collector`) | Cue ball at 70% grip (rolls further) | +0.5 Chain per pocket used |
| Xenon Flash (`stillness`) | First pause each table: every rolling ball ×1.3 speed | +0.5 Chain a pause |
| Francium Fizz (`followthru`) | A scratch with 2+ balls sunk still scores, with no Chalk lost | Follow shots +0.5 Chain |
| Berkelium Break (`afterburner`) | Ball in hand anywhere for the break, and after a break scratch | Break +3 Chain |
| Neodymium Magnet (`elastic`) | The rolling cue ball tugs nearby object balls | +0.25 Chain a hit (was Neodymium Speaker) |
| Lithium Cell (`lowball`) | Balls 1–3 lose no speed off cushions | Balls 1–3 +45 |
| Uranium Reactor (`power`) | At 85%+ power, the first ball struck leaves 20% faster | +1 Chain at 85%+ |
| Polonium Halo (`lastcall`) | Also: pockets pull the 8 when it is the last ball | ×5 and $5 only (still has those) |

All 100 Elements were also renamed "element + noun" (for example Hydrogen Balloon, Iron Fist), and the cue descriptions use the new names. Rarity, cost and family changes are listed in ELEMENTS_REWORK.md. Two keep the family counts the tests expect: Silver Tongue moved to Economy, and Tungsten Core to Stripes.

### Where the code changed

- **`src/sim/pool_sim.gd`:** new settings. All of them are copied by `clone()`, so the shot prediction matches.
  - `grip`: per-ball cloth friction, also used in `stop_distance`.
  - `anchor8`: in `_rejects`, pockets turn the 8 away while other balls remain.
  - `cue_magnet`: in `_forces`, before the resting-ball check, so resting balls get tugged.
  - `first_boost`: applied at the cue's first contact.
- **`src/game/run_state.gd`:** `apply_physics` sets all of the Element physics. It now resets `ball_e` on every call.
  - Lithium and Tungsten use `bounce`. Polonium's pull is checked after each shot, so it switches on when the 8 is alone.
  - New `first_boost(power)` for Uranium.
  - New `flash_used`, reset in `begin_table` and **not saved**, so reloading mid-table gives Xenon's flash again.
- **`src/game/scorer.gd`:** removed the Chain bonuses for Gallium (`collector`), Uranium (`power`), Neodymium (`elastic`) and Berkelium (`afterburner`).
  - A scratch is no longer a foul when Francium is held and 2+ balls went in. The result carries `scratch_saved`.
  - New helper `perks_of(ctx)`.
- **`src/main.gd`:**
  - Xenon Flash runs in `_hold`, with a banner.
  - Berkelium: every `_begin_place(true)` is now `_begin_place(not run.perks.has("afterburner"))`. So is the break-scratch call.
  - Uranium: `sim.first_boost` and `fc_sim.first_boost` are set just before each strike.
  - The "Now:" lines for Gallium (removed) and Holmium were updated.
  - `view.set_lab(lab, board_id)`.
- **`src/view/table_view.gd`:** `set_lab(id, board := "")` draws the board's own decal from `BoardArt.DECALS` when it has one.
- **`src/audio/sfx.gd`:** `TRACKS` covers all 47 boards. 13 files were renamed (black-ice.ogg is now superfluid.ogg, and so on) and 21 are new.
  - The new boards use ids that are only guesses: `venturi`, `erbridge`, `parabolic`, `whisper`, `membrane`, `sierpinski`, `mobius`, `maxwell`, `chain`, `lorentz`, `foucault`, `galton`, `spiral`, `tesla`, `gulf`, `meissner`, `tectonic`, `lattice`, `stellated`, `lever`, `escape`.
  - Rename them in `TRACKS` and `BoardArt` if your `BOSSES` ids differ.
- **`src/ui/icon_art.gd`:** new icons for the reworked Elements.
- **Tests updated:** `test_sim`, `test_eight_and_suits`, `test_scoring`, `test_items` and `test_tiles`, with new checks for each rework.

### Please check

- **Balance:** about 14 Elements lost their points for physics. Number, stripe and combo builds have less raw scoring now.
- **Feel in play:**
  - Is the magnet's tug (`cue_magnet`, strength 3200, reach 150) too strong or too weak?
  - Is Xenon's ×1.3 too much?
  - Does Lead Anchor's rattle-out look right in the table view? It uses the Moon and Sun ball reject path.
- **Flaky test:** `test_input` "ball is rolling" failed once on its own, even without these changes. It passes in full runs.

### Art wired in for 1.40

- **`ThumbArt`** (`src/ui/thumb_art.gd`): small pictures that match the cards.
  - Element badges: atomic number and symbol in the element's colour, framed in its group colour.
  - Isotope balls, special balls, starting cues, and boards seen from above (shape, felt, pockets, decal).
- **HUD:** your Element cards show the Element badge instead of the old icon.
- **Pro Shop:** the next table's board appears beside its description.
- **Collection:** every tab now has pictures. Isotopes, Cues and Tables had none before. The Items tab says Catalyst.
- **Table:** a board uses its own decal, felt and textured rail only when it is the board the art was drawn for (`BoardArt.same_board`: the names must match). The old boards that share an id with a planned science board keep their lab art until they are renamed.
  - Light felts are skipped, so the cue ball stays visible.
  - Shaped boards fill their frame in the rail material's flat colour (`BoardArt.RAIL_BASE`).
  - Benzene Ring has chrome rails and Golden Pentagon has gilded ones.

### Changes after 1.40 (2026-11-13, art chat)

- **Tap to aim (touch, Point aim):**
  - A tap now points the shot at once, through `_point_at_finger()` in `main.gd`. Before, a tap that pressed and lifted within one frame never reached the aim update.
  - New test: "a quick tap aims the shot".
- **Sinking animation:** its tween now belongs to the ball (`TableView.sink`). It no longer errors when the rack is rebuilt mid-drop.
- **Side bets:**
  - The stake is capped at your money when the bet is dealt (`RunState.bet_cap`, which is saved).
  - With less than $2 (`RunState.MIN_BET`) there is no side bet that table: `bounty` is `""`, `bet_open()` is false and the panel hides.
- **Chalk lasts the whole run.** This is the user's design:
  - Start with 6 (`BASE_CHALK`). Hot Rod, Glass Cue and the Short Chalk handicap start with 1 less.
  - +1 for each cleared table (`advance_table`), +1 more with Calcium Chalk.
  - +1 for a cleared rack.
  - Never above 12 (`MAX_CHALK`).
  - A miss costs 1. A scratch, or the 8 going in early, costs 2. The scorer flags an early 8 with `eight_early`, and Carbon Core makes it free.
  - Astatine Edge adds 1 to every foul.
  - The endless Chalk wear-down was removed.
  - The Chalk pips show a tooltip and close up to fit 12.
  - The card, glossary, help and README text was updated.
  - **Interpretation to confirm with the user:** "use 1 on each shot" was read as each *missed* shot. Shots that sink still keep you shooting for free.
- **Balance review:** [docs/BALANCE_REVIEW.md](../BALANCE_REVIEW.md) has every tunable number in tables, each row with "Your note" and "Done" columns. It is generated by `tools/balance_doc.gd`. The user will mark it up; act on their notes and tick Done.

### Boards rework and Element fixes (2026-11-13, coding chat, NOT TESTED YET)

The user asked for no tests or CI until they say so. Everything below is written but has not been run. Run `./run_tests.sh` and `FULL=1 ./tools/ci.sh` first when testing is allowed.

- **Balance review, editable in Claude:** https://claude.ai/artifact/UBeJUAEVm52yp1xrEBUBN3
  - It is built from `docs/balance_data.json`, which `tools/balance_doc.gd` writes alongside `docs/BALANCE_REVIEW.md`.
  - Notes live in the artifact's db, collection `notes`, with the row key as the doc id (for example `elements-featherweight`). The user writes `note`; reply with `reply` and `status` ("done" or "doing").
  - When the data changes, regenerate it and republish the page. The notes stay in the db.
- **Element rules that changed (flag to user):**
  - **Hydrogen** (`featherweight`): the cue ball floats. If it would drop into a pocket it bobs back out (`PoolSim.cue_float`), so pocket scratches never happen. The old "object balls 30% lighter" rule is gone.
  - **Helium** (`fusion`): a sink into the same pocket as your last sink scores ×2. "Last sink" can be earlier in this shot or your previous sink (`RunState.last_pocket`, saved).
  - **Lithium** (`lowball`): your 3 lowest-value balls (never the 8, `RunState.lithium_balls()`) lose no speed off cushions, and each pays $1 when it sinks. On hover they glow.
- **Sharks and moving parts are built**, in the new `BoardFeatures` class ([src/game/board_features.gd](../../src/game/board_features.gd)).
  - State lives in `RunState.board` and is saved with the table.
  - Sharks are still bumpers during a shot and move between shots, in `board_turn`, which runs after `apply_shot` in main, playtest and bot. The `bumper` event now carries `k`.
  - Fields work during the shot, in `PoolSim._forces`: `spin_zone` (Coriolis) and `flow_zone` (Gulf Stream). The prediction clone copies them.
  - `charged_y` is the Capacitor's charged rail. `no_drop` marks the Leech's ball.
  - Shark knock-outs pay $3 (`KO_PAY`).
- **Boards now (`Catalog.BOSSES`):**
  - Reworked: `spring_st` Capacitor, `drift` Coriolis, `cramped` Faraday Cage (Card Sharp), `posts` Harmonic Oscillator (shuttle posts), `smoke` Lotka–Volterra (Pool Shark), `final` Apex Predator (Great White, then the Loan Shark and Leech), `elements` The Clockwork Table (adds the Sweeper).
  - New: `gulf` Gulf Stream (tier 2), `foucault` Foucault's Pendulum (tier 3: a stepping bob plus a Hammerhead).
  - Renamed to their science names, with the same rules: `sinkhole` Event Horizon, `magnet` Kepler Orbit, `blackice` Superfluid, `tilted` Snell's Law, `two` Quantum Pockets, `closing` Radioactive Decay. Every board's art now switches on through `same_board`.
  - **Retired:** `frozen`, `slate`, `hump`, `nineball`, `iron` (the board, not the Iron ball), `lights`, `hustler`. Their scorer rules and tests were removed. Their music files are still in `Sfx.TRACKS`, unused.
- **Not built yet:** Maxwell's Demon (`maxwell`) and The Lever (`lever`). The art exists for both. Foucault's table is a rectangle, not an octagon. Sharks don't yet avoid a fresh rack after a rack clear.
- **Next, in the user's order:**
  1. Apply the user's balance notes from the artifact.
  2. Path choice: "Experiment proposals", each tying together a board, a side bet and one of about 20 small rewards, with a full racked-board preview. See [docs/PATH_CHOICE_BRAINSTORM.md](../PATH_CHOICE_BRAINSTORM.md).
  3. Implement it, then test.

### Sharks and moving parts: original brief (now built, kept for reference)

The art for every Shark and moving part is finished, in `BoardArt` ([src/view/board_art.gd](../../src/view/board_art.gd)), with sheets in [docs/table-art/](../table-art/). None of it is in the game yet, because the boards that use it don't exist. The user asked for this to go to you rather than being built in the art chat.

**Rules to keep** (from [docs/TABLES_SCIENCE.md](../TABLES_SCIENCE.md)):
- The prediction line tells the truth.
- Moving things follow fixed patterns in shot time.
- Sharks are solid.
- Pausing freezes everything.

**Suggested approach.** It keeps the prediction exact and reuses what's already there:

1. **Sharks are bumpers that move between shots.**
   - During a shot a Shark is a still, solid circle, like the round bumpers in `TableLayout.bumpers`. `PoolSim` already collides with those exactly (kind 4 in `step`), and `cast` already sees them, so the prediction stays exact for free.
   - After each shot, move it to its next spot, using the run's seeded random numbers so it is deterministic.
   - Give each bumper entry a `shark` field (its kind, health and state).
   - Add the bumper's index `k` to the `"bumper"` event in `_resolve_bumper`, so the scorer and run state know which Shark was hit.
2. **Damage.**
   - Every ball that hits a Shark takes one point off its health (or only hits above some speed, if that plays better).
   - At 0 the Shark is knocked out. Leave it on the table, drawn in the knocked-out state, but remove its bumper so it is no longer solid.
   - Draw it with `BoardArt.draw_shark(ci, kind, pos, heading, size, state, t, health)`. The state is `"normal"`, `"hit"` (show this for about 0.3 s after a hit) or `"ko"`.
3. **What each Shark does**, all after a shot unless noted:

| Shark | Board | Behaviour |
|---|---|---|
| Pool Shark | Lotka–Volterra (rework of `smoke`) | Circles the nearest object ball. Every 3 shots it swallows that ball: it leaves the table and scores nothing. If it survives 4 shots, a second Pool Shark appears. 3 hits to knock out |
| Card Sharp | Faraday Cage (rework of `cramped`) | Sits in the mouth of the best pocket (the hot pocket), inside a ring of posts, and blocks it. Knock it out (2 hits) to open the pocket |
| Hammerhead | Foucault's Pendulum (new, `foucault`) | Between shots it charges along a straight line across the table, then turns. Solid while it waits |
| Loan Shark | Apex Predator (rework of `final`) | Joins at the Great White's half health. Skims 15% of every sink while alive, which takes over The Hustler's rule |
| Leech | Apex Predator | Joins at half health. Clamps onto a ball, making that ball 300% weight and unable to drop until the Leech is hit off (1 hit) |
| Great White | Apex Predator (final boss) | 8 hits. Swallows a ball every 2 shots. Its health bar is part of the drawing |

4. **Moving parts.** Pick per board:
   - **Step between shots**, like Sharks. This is the simplest option and keeps the prediction exact. Use it for:
     - **Clockwork Sweeper** (`elements`): a wall segment that turns one clock step per shot. Draw it with `draw_sweeper`.
     - **Shuttle posts** (Harmonic Oscillator, rework of `posts`): the two bumpers slide one step along their slot each shot. Draw them with `draw_shuttle`.
     - **Hammerhead** (above).
   - **Fields during the shot.** These are forces in `_forces` on a fixed pattern, which the prediction clone already runs:
     - **Coriolis turntable** (rework of `drift`): a tangential push inside a disc. Draw it with `draw_turntable`.
     - **Gulf Stream conveyor** (new, `gulf`): a constant push inside a strip. Draw it with `draw_conveyor`.
     - **Foucault pendulum bob:** a moving solid circle whose position is a function of `sim.time`. The bumper collision would need its position at time t, so this is the hardest one. It could start as a still bob that steps between shots.
   - **Special geometry:**
     - **Maxwell's Demon** (new, `maxwell`): a gate segment that lets only balls above a speed through, one way. Draw it with `draw_demon`.
     - **The Lever** (new, `lever`): a see-saw segment that tips towards whichever end a ball hits, stepping between shots. Draw it with `draw_seesaw`.
     - **Capacitor** (rework of `spring_st`): a marked rail segment. A hit charges the opposite rail, and the next ball off it gets a boost (use `seg_e`, as Hooke's Law does). Draw it with `draw_charged_rail`.
5. **Saving.** Shark positions, health and step counters must go into the table save (`run.table_snapshot` and `table_mods`). Otherwise reloading mid-table resets them.
6. **Renames.** When a board is reworked, give it its science name in `Catalog.BOSSES`. `BoardArt.same_board(id)` then switches on its decal, felt and rail automatically, because it compares names. The music files and `Sfx.TRACKS` entries already exist under the board ids listed above; rename them if you choose different ids.
7. **Tests to add:**
   - A Shark is solid in both `step` and `cast`.
   - Hits lower its health, and at 0 it is knocked out and no longer solid.
   - The swallow timing.
   - Its state survives a save and load.
   - The prediction matches the real shot on each moving-part board.

### Wiring still open (optional)

- Cue tiles on the cue-select screen: `TileArt.new().setup("cue", id)`.

## Preview sheets (2× size)

| Sheet | What it shows |
|---|---|
| `perk-tiles-1.png` … `perk-tiles-5.png` | Every Element |
| `imbue-tiles-1.png` | Every Isotope, on balls 0–15 in turn |
| `ball-tiles-1.png`, `ball-tiles-2.png` | Every special ball |
| `item-tiles-1.png`, `item-tiles-2.png` | Every Catalyst |
| `cue-tiles-1.png` | Every starting cue |
| `bet-cards-1.png`, `bet-cards-2.png` | Every side bet card, then the back and the taken, won and passed states |
| [../table-art/](../table-art/) | Board decals, Sharks, moving parts and rail materials |

## What each brief item became

1. **Atomic numbers:** each Element tile leads with its atomic number on a chip coloured by its periodic-table group.
2. **Group colours:** ten group colours (`TileArt.GROUP_COLORS`), from alkali metals to actinides.
3. **Element looks:** every Element's letters are coloured like the element itself (`TileArt.ELEMENT_LOOK`):
   - Metals are polished and tinted to the real metal: copper, cobalt blue, caesium gold, osmium blue.
   - Gases glow like discharge tubes: neon red-orange, argon violet, xenon blue.
   - Liquids (mercury, bromine, gallium) drip.
   - Radioactive elements glow and give off particles.
   - Bismuth has a rainbow sheen. Gold keeps its gold ingot.

   Each card's own effect (the picture of what it does) stays, now drawn in the element's colours.
4. **Names:** every Element is now "element + noun", such as Hydrogen Balloon or Lead Anchor. The tile shows the real symbol.
5. **What it does:** every Element tile has a few-word description across the bottom row. The family moved up beside the rarity.
6. **Enchanter and Alchemy:** these now read **Einsteinium Lab** and **Arsenic Mutation**, so nothing sounds like magic.
7. **Element swaps:** Hydrogen and Beryllium swapped cards, so Hydrogen is the floaty one. Nothing else moved.
8. **Temporary symbols:** all replaced (tables below). Special balls show a picture of the ball, not letters, so they need no symbol.
9. **Catalysts:**
   - The tile says CATALYST, when it can be used, and "every table".
   - 17 renamed cards have new symbols.
   - Black Hole, Event Horizon and Force Field have new pictures.
   - The six new Catalysts have their own art.
   - The four removed items' art is gone.
10. **Cues:** the 13 starting cues have tiles, a picture of the cue and the object it carries. The cue-select screen still draws its own cards.
11. **Sheets:** all sheets are rendered again with the new words.

## Symbol rules

- A one-word name takes its first letter. If that is taken, it takes the first two letters. If those clash, it takes the first letter and the next consonant.
- A longer name takes the initials of its first two words. Case-only differences count as different symbols (CM and Cm).
- **No card may use a symbol an Element shows** (every real symbol from H to Fm). The tile test checks this. Symbols of elements above 100 (Cn, Rf) are allowed.
- Exhausted names fall back to initials. Inertia is **It** (In and Ir are Elements), and Conservation is **Cn** as the brief asked, now that the Coin ball has no symbol.

## Isotopes

| Isotope | Id | Symbol | Bottom line |
|---|---|---|---|
| Vein | `vein` | **Ve** | +20, spreads |
| Spark | `spark` | **Sk** | +1 Chain a hit |
| Gilded | `gold` | **G** | $1, +$1 a table |
| Weighted | `heavy` | **We** | Number ×3, ×4… |
| Hairline | `glass` | **Ha** | ×3, may crack |
| Kindled | `ember` | **Ki** | +2 Heat |
| Lucky | `lucky` | **L** | 1 in 2: ×2 |
| Volatile | `volatile` | **Vo** | Explodes on hit |
| Jinxed | `jinxed` | **J** | ×4, halves Heat |
| Mirror | `mirror` | **M** | Copies its hitter |
| Pawned | `pawned` | **Pw** | $4, no points |
| Frosted | `frosted` | **Ft** | Next miss safe |
| Magnetic | `magnetic` | **Ma** | Pockets pull it |
| Charged | `charged` | **Ch** | +0.5 Chain a rail |
| Resonant | `prismatic` | **R** | +0.25 a touch |
| Hollow | `hollow` | **Hl** | Half weight |
| Leaded | `leaded` | **Le** | ×2 weight, +45 |
| Bounty | `bounty` | **Bo** | $1 per Heat |
| Starry | `starry` | **Sy** | +0.5 to the rest |
| Twin | `twin` | **Tw** | Counts twice |

## Catalysts

| Catalyst | Id | Symbol | Bottom line |
|---|---|---|---|
| Impulse | `secondstrike` | **Im** | Hit again |
| Black Hole | `trapdoor` | **BH** | +1 pocket |
| Centre of Mass | `centremass` | **CM** | Pull together |
| Quantum Tunnel | `ghostchalk` | **QT** | Pass through |
| Entanglement | `swap` | **En** | Swap two balls |
| Zero Friction | `polish` | **ZF** | Glides free |
| Mass Shift | `leadweight` | **MS** | ×4 weight |
| Conservation | `spotter` | **Cn** | Respot a ball |
| Event Horizon | `pocketcover` | **EH** | ×2 wide |
| Force Field | `wall` | **FF** | Raise a wall |
| Superposition | `blink` | **Sp** | Move the cue |
| Inertia | `freezeframe` | **It** | Stop one dead |
| Vector | `nudge` | **Vc** | Push one ball |
| Spin Transfer | `englishdial` | **ST** | Add your spin |
| Gravity Well | `gravitypebble` | **GW** | Bends balls |
| Time Reversal | `rewind` | **TR** | Retake shot |
| Reflection | `reflection` | **Rf** | Turn back |
| Pythagorean Triple | `pythagoras` | **PT** | Triangle walls |
| Newton's Cradle | `newton` | **NC** | Take momentum |
| Fixed Point | `post` | **FP** | Place a post |
| Wormhole | `portal` | **Wh** | Linked portals |
| Golden Ratio | `goldenratio` | **GR** | Speed ×1.618 |
| Hooke's Law | `hookes` | **HL** | No speed lost |

## Table art

All of this is in [src/view/board_art.gd](../../src/view/board_art.gd), with sheets in [../table-art/](../table-art/):

- **Decals for all 40 boards** (`BoardArt.DECALS`). The table now draws the board's own decal when it has one (`TableView.set_lab(lab, board)`).
- **Felt colours** (`BoardArt.FELTS`), and which boards get a **textured rail** (`BoardArt.RAILS`).
- **Six Sharks** (`draw_shark`), each swimming, hit or knocked out. The Great White carries its health bar.
- **Eight moving parts:** the Sweeper, pendulum bob, shuttle post, turntable, conveyor, Maxwell's Demon, see-saw and charged rail.
- **Six rail materials** (`draw_rail`): chrome, copper, black glass, marble, gilded and obsidian.

The Sharks, moving parts, felts and rails are ready for the boards when they are built. Only the decals are shown in the game today.

## Music

- **21 new tracks** for the new boards, from the same generator ([tools/compose_score.py](../../tools/compose_score.py)).
- **13 tracks renamed** to their science boards, by title and file: Superfluid, Harmonic Oscillator, Event Horizon, Kepler Orbit, Lotka–Volterra, Faraday Cage, Capacitor, Coriolis, Snell's Law, Quantum Pockets, Radioactive Decay, Apex Predator and The Clockwork Table.
- **Smaller files:** every track is now a 32-bar loop (about 1:40) at Vorbis quality 0. The 47 tracks take 39 MB; the old 29 took 67 MB.
- `PS_BARS=64` and `--quality 2.5` bring back the long form.
- `Sfx.TRACKS` maps every board id to its file, including the boards not built yet.
- **Retired tracks are kept** (Frozen Lake, Old Slate, The Hump, Rotation Night, The Iron Rack, Lights Out, The Hustler), because those tables are still in the game.

## Rendering the sheets again

Run from the project folder; the preview opens a window, so don't use `--headless`.

```bash
PS_TILE_SET=perks PS_TILE_ZOOM=2 godot --path . --script res://tools/tile_preview.gd -- docs/card-art/perk-tiles.png
PS_TILE_SET=betcards PS_TILE_ZOOM=2 godot --path . --script res://tools/tile_preview.gd -- docs/card-art/bet-cards.png
godot --path . --script res://tools/board_preview.gd -- docs/table-art
```

`PS_TILE_SET` takes `perks`, `imbues`, `balls`, `items`, `cues`, `betcards` (the playing cards), `bets` (the old bet tiles) or `all`. `PS_TILE_ONLY=ball:void,item:post` renders only those cards.
