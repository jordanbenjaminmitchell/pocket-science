# Pocket Science

**A real-pool roguelike. Sink balls, avoid the 8, stack multipliers, beat the target.**

Pocket Science plays like real pool: six pockets, all 15 numbered balls, a cue stick and an exact prediction line. Most boards use a 2:1 table; four playable boards use triangle, hexagon, pentagon and L-shaped layouts. On top of that sits a roguelike run of nine boss tables, drawn from 26 boards, a Pro Shop of Elements and ball upgrades, and Chain and Heat scoring. Built in Godot 4.7.

## Download and play

Get the newest build from **[Releases](../../releases/latest)**.

- **Android phone:** download `PocketScience.apk` on the phone and open it. Allow installs from your browser if asked. Each new release installs over the last one and keeps your progress. Needs Android 7 or newer on a 64-bit phone.
- **Windows PC:** download `PocketScience-Windows.zip`, unzip it anywhere and run `PocketScience.exe`. Keep `PocketScience.pck` in the same folder.

The APK is signed with a personal key from the build PC, so it is for your own devices, not the Play Store.

## How a run works

1. **Choose a cue.** Each cue starts the run differently. More unlock as you play.
2. **Every table is a boss** with its own rule and a target score. As in real pool, you keep shooting while you sink. **Chalk** lasts the whole run: you start with 6, a miss costs 1, a scratch or an early 8 costs 2, and each table you clear gives 1 back (up to 12). When it runs out, the run ends.
3. **Avoid the 8.** Sinking the 8 while other balls are still up costs 15% of the table's target and 2 Chalk, unless an Element changes that. Once it is the last ball it is safe.
4. **The Pro Shop** opens between tables:
   - **Elements:** 100 passive rules for your six slots.
   - **Isotopes:** 16 lasting upgrades for one ball.
   - **Catalysts:** 23 reusable board-changing tools. Each normally has one charge per table and works while aiming or during a paused shot. Set-up effects appear in the prediction before you shoot.
   - **Exotic balls:** 24 types to add to your set.
   - **Removal:** take a ball out of your set, never the 8.
5. **Nine tables** make a run, including the Clockwork Table at table 5 and the Grand Final at table 9. After that, endless mode.

### Scoring

Each ball scores as it sinks: **value × Chain × Heat**.

- **Value:** 10 plus the ball's number.
- **Chain:** starts at 1 every shot and rises as balls sink, so the last ball of a big shot scores most.
- **Heat:** lasts the whole table, rises with every scoring shot and halves on a miss.
- **Hot pocket:** the glowing pocket scores ×2.

Bouncing off cushions or balls earns nothing by itself. Only an Element, an Isotope or a table's own rule makes contact count. Tap or hover any highlighted word in the game for a one-line definition.

### The prediction line

- **White line:** the cue ball's path, with a ring where it meets the object ball.
- **Coloured line:** after contact, the line takes the colour of the ball you hit. Bold with a **gold ring** means it is going in. Dashed means it may rattle.
- **Blue dashes:** where the cue ball goes after contact, including spin.
- **Settings → Prediction lines → All balls** simulates the whole shot and shows where every ball will land.

No table ever hides or bends the line. Tables that curve a ball's path draw the real curve as well.

## Pausing a shot

Press **P** (or the Pause button on a phone) while the balls roll and the shot freezes. While it's paused:

- The prediction shows exactly where every ball will go from that moment.
- Catalysts such as **Impulse**, **Force Field** and **Superposition** change the shot, and posts and portals can be placed too.
- Press **L** (Plan a pause) to lock the prediction, then slide along any ball's predicted line and click to make the shot pause itself when that ball gets there. This works while aiming as well.

Settings can also pause every shot automatically the moment the cue ball first hits a ball.

## Controls

| Action | PC | Phone |
| --- | --- | --- |
| Aim | Mouse; Left/Right to fine-tune, Shift for finer | Drag on the table |
| Shoot | Press on the table, drag back, release | Power slider, then Shoot |
| Spin | Click the cue-ball widget, or W/A/S/D | Tap the cue-ball widget |
| Move the cue ball on the break | H | Ball-in-hand button |
| Fast-forward | Click or Space while balls roll | Tap |
| Pause a shot / play on | P | Pause / Play on button |
| Lock the prediction to plan a pause | L | Plan a pause button |
| Pause | Esc | Back |

Gamepads work too. Every key can be rebound in Settings.

## Building it yourself

You need Godot 4.7.2 with export templates (bundled in `runtime/` on the build PC). Android also needs the Android SDK.

```bash
./run_tests.sh          # every headless test suite
./tools/ci.sh           # tests, an expert simulated player, then both builds (FULL=1 runs all six)
./build_windows.sh      # export/windows/
./build_android.sh      # export/android/PocketScience.apk
./tools/release.sh "What changed"   # bump version, check, build, push and publish a release
```

## Project layout

```
src/sim/      PoolSim: event-ordered, deterministic physics; table layout; racks
src/game/     Catalog (all content), Scorer, RunState (rules and saves), AutoPlayer (AI)
src/view/     Table view, guideline, cue, effects; rolling, lit ball shader
src/ui/       HUD widgets, glossary popups, screen layouts, icons
src/audio/    Sound effects and soundtrack
src/main.gd   Game controller: states, input, HUD, tally, shop, screens
tests/        Headless suites: physics, rules, saves, layout, end-to-end flow
tools/        Simulated players for balance, screenshot capture, icon and release scripts
docs/         Playtest reports and plans
```

### Why the prediction line is exact

`PoolSim` never moves balls and then looks for overlaps. It finds the earliest moment of impact between any balls, cushions, pocket jaws or bumpers, moves everything to that instant, resolves it and repeats. An object ball therefore always leaves along the line of centres, which is exactly what the guideline draws. The tests check that gold lines go in 200 times out of 200.

## Credits and licences

Game design and direction by Jordan Mitchell. Fonts are under the SIL Open Font License and the engine is MIT-licensed; see `licenses/`. The game's own code, art and music are © Jordan Mitchell, all rights reserved.
