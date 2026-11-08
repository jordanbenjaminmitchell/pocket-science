# Pocket Science — real-pool roguelite (Godot 4.7 revamp)

**Pot balls. Stack multipliers. Beat the target.**

This is a ground-up rebuild of Pocket Science in Godot. It plays like real pool: a 2:1 table with six pockets, numbered balls, a cue stick and a clear, exact guideline. On top of that sits a Chips × Mult scoring roguelite. Earlier HTML versions (v12–v21) were used as design reference only; no code was merged from them.

## Play

- **Double-click `Play Pocket Science.cmd`.** It uses the bundled Godot 4.7.2 runtime in `runtime/`.
- Or open `project.godot` in Godot 4.7.2 and press **F5**.

### Install a build

- **Windows:** unzip `PocketScience-Windows.zip` anywhere and run `PocketScience.exe`.
- **Android:** copy `PocketScience.apk` to the phone, open it and allow installs from that app when asked. Needs Android 7 or newer on a 64-bit device. The APK is signed with a local debug key, which is fine for your own devices but not for the Play Store.

### Make a build

```bash
./build_windows.sh      # export/windows/
./build_android.sh      # export/android/PocketScience.apk
./tools/ci.sh           # every test suite, every persona, then both builds
```

Both builds need the Godot 4.7.2 export templates. Android also needs the Android SDK and a debug keystore.

## How a run works

1. **Choose a cue.** Each of the 10 cues gives a different start, and more unlock through milestones.
2. **Each table has a target score.** You keep shooting while you pot, as in real pool. A miss, scratch or no-contact costs one **Chalk**; a dry break is free. When Chalk runs out before you reach the target, the run is over.
3. **Clear the rack** for +1 Chalk and a fresh rack.
4. **Lab Supply** opens between tables, where you can buy:
   - **Formulas**: 60 passive rules in synergy families (banks, cue control, combos, streaks, pockets, ball numbers, economy, risk, physics). 5 slots; sell for half.
   - **Reagents**: one-use tricks, 2 slots.
   - **Isotopes**: permanently enhance one numbered ball.
5. **The run has 9 tables.** Every third table is a boss with an **Anomaly**. After table 9 you can continue in endless mode.

### Scoring

Each shot scores **Chips × Mult**:

- **Chips:** each potted ball gives 10 + its number.
- **+Mult bonuses** (added first):
  - streak: +1 per consecutive scoring shot
  - bank pots: +1 per cushion
  - combinations: +2
  - extra balls in one shot: +1 each
  - kick shots: +2
  - formulas and isotopes
- **×Mult multipliers** (applied after the bonuses):
  - the glowing **hot pocket**: ×2
  - the black 8: ×2
  - Golden Ratio, Supernova, Fusion, Blue Chalk, …

While you aim, a tag on the rail shows exactly what the pot is worth. The guideline colours mean:
- **Gold:** that ball goes in cleanly, including off one cushion. `tests/test_guide_trust.gd` checks this: 200/200 gold lines pot unless another moving ball gets in the way or the shot lacks pace.
- **Orange:** the path is borderline and could rattle on a jaw.
- **White:** the ball is not going in.
- **Blue dashes:** the cue ball's path after contact, including follow, draw and english.

### Extras
- **Cues:** 10 in all, such as Classic Maple, Optic (Long Lens), Hot Rod (hot pocket ×3, one less chalk), Momentum (+2 Mult per streak step) and Gilded ($12 and interest).
- **Bounty:** every table has a side goal, such as "Sink a bank shot +$3", which pays immediately.
- **Ball tray:** the side panel shows which balls are still up and which are down, plus their isotopes.
- **Coach:** first-time players get on-table hints until they clear their first table.
- **Saves:** runs save at the start of each table (title → Continue). Personal bests are shown on the title screen.

## Controls

| Action | Input |
| --- | --- |
| Aim | Mouse. Left/Right fine-tunes, Shift makes it finer. F toggles fine-aim (mouse stops steering). |
| Shoot | Press on the table, drag **back**, release. Or wheel/Up/Down for power and Space to shoot. |
| Spin | Click the cue-ball widget, or W/S (follow/draw) and A/D (english). Right-click resets. |
| Reagents | Click the card, or press 1 / 2 |
| Move cue on break | H |
| Fast-forward | Click or Space while balls roll or during the tally |
| Pause | Esc |

## Labs and anomalies

**Labs (10):** each has its own rule, cloth, rail and emblem. Examples:
- **Cryo Felt:** low friction, +1 Mult per pot.
- **Cyclotron:** spring bumpers, +10 Chips per bumper hit.
- **Spring Rails:** lively cushions, extra Mult for banks.
- **Gravity Well:** a central pull bends moving balls.

The in-game Collection lists them all.

**Boss anomalies (15):** Tight Pockets, Sealed Sides, Lead Rack, Fog, Dry Chalk, Cold Pockets, Shrinking Pockets, One Pocket, Rotation Rules, Heavy Cue Ball, Black Ice, The Taxman, Blind Pockets, Tilted Table, Cursed 8.

## Project layout

```
src/sim/       PoolSim (event-ordered deterministic physics), TableLayout, Rack
src/game/      Catalog (all content), Scorer, RunState (rules + save), AutoPlayer (AI)
src/view/      TableView (table, guideline, cue, FX), BallNode + shaders (rolling lit balls, felt)
src/ui/        Spin widget, power meter, chalk pips
src/audio/     Sfx: synthesized effects + soundtrack crossfades
src/main.gd    Game controller: states, input, HUD, tally, shop, screens
assets/music/  Original Pocket Science soundtrack (from the v21 project)
tests/         Headless suites: physics, rules/persistence, end-to-end flow (incl. real mouse input)
tools/         playtest.gd (six emulated player personas), playtest_report.mjs (balance report),
               bot.gd (quick balance runs), capture.gd (real rendered screenshots), tune.gd (physics tuning)
docs/playtests REPORT.md plus earlier rounds: emulated playtest results that drove the balance
```

### Why the guideline is exact

The guideline is accurate because of how `PoolSim` handles contacts. It doesn't move balls and then look for overlaps. Instead, it finds the **earliest time of impact** across all balls, cushions, jaw knuckles and bumpers, moves every ball to that instant, resolves the contact and repeats. So an object ball always leaves along the line of centres, which is exactly what the ghost-ball guideline draws. `tests/test_sim.gd` checks the error is below 0.002 rad (in practice it is about 0.00002).

## Verify

```bash
./run_tests.sh                       # all headless suites (physics, rules, flow)
godot --headless --path . --script res://tools/playtest.gd -- expert 30 1000 out.jsonl   # one persona, 30 runs
node tools/playtest_report.mjs                                                          # aggregate docs/playtests/*.jsonl
godot --path . --script res://tools/capture.gd -- pot shots/pot.png          # real rendered frame
```

The bot plays complete runs with the real physics and rules, adding Gaussian aim error. At 0.3° error it typically clears 1–4 tables and occasionally wins a run. Humans also have position play and spin, so expect a fair but real challenge.
