# Scoring balance probe

Run from the project root on Windows:

```powershell
& .\runtime\GodotConsole.exe --headless --path . --script res://tools/score_balance.gd -- 300 1.0
```

Arguments are **runs per skill/build pair** and **target multiplier**. The default is 300 runs and the current target values. Each row reports the percentage of full runs won, average tables cleared, and for each table `table:clear percentage/average score among attempts that reached it`. Reuse of the same seeds across builds supports paired comparisons.

The probe synthesizes event logs and calls `Scorer.score()` and `RunState.apply_shot()`. Thus it exercises current ball values, element and isotope effects, Heat, Chain, table scoring rules, Chalk, and rack refreshes without running physics or an aiming bot. It deliberately makes **no** claim to predict real player win rates. In particular it does not simulate the shop, board geometry, blockers and sharks, ball position, or catalyst placement. Scheduled acquisitions are counterfactual builds that isolate what extra scoring power a player would need; some may be hard to assemble in a real run.

Across the 300 seeded strong-engine runs, all **40/40 board IDs** were attempted at least once. Each run still uses only nine boards. The board ID reaches the scorer, so its direct score rule applies when the synthetic event satisfies it. The shot generator does not reproduce board-specific contacts or geometry: bumpers, portals, posts, focus pockets, narrow jaws, moving hazards, and similar features may change both pot rate and Chain in real play. In particular, it can undercount Chain on contact-heavy boards and overestimate potting on difficult shapes.

## Shot assumptions

| Skill label | First-table chance of a pot | Drop per later table | Extra ball after a pot | Scratch chance per shot |
|---|---:|---:|---:|---:|
| hard | 46% | 2.5 points | 11% | 5.5% |
| middle | 58% | 2.5 points | 16% | 4% |
| strong | 70% | 2.5 points | 22% | 2.5% |

For example, `strong` reaches a 50% pot chance on table 9. Pots target a random remaining ball, usually saving the 8 until the end. Pockets are random; 12% of pots are banks. Misses usually contact an object ball. A rack resets when all balls are gone. The model stops after 35 shots on a table. These assumptions should be calibrated against current run telemetry before changing game numbers.

## Builds

Cards are granted before tables 2–7, bypassing shop chance and cost.

| Build | Contents |
|---|---|
| plain | Starting 1–10 balls, no acquisitions |
| scattered | Odd, Cushion, Chalk, Rhythm, Side, Highball; later a Feather ball and Gilded 3 |
| value | Odd, Solids, Fibonacci, Moneyball, Thinning, Highball; removes 1 and 2 |
| engine | Side, Heat, Even, Prime, Glass Cannon, Menagerie; removes 1 and 2, adds Iron and Anchor, imbues 5, 7, 9, and 10 |
| engine_no_* | Same engine with one of the three ball upgrades omitted |

The focused engine combines a pocket multiplier, Heat and Chain support, number multipliers, exotics, and imbues. It is a stress test for the intended endgame, not a recommended shop path.

## Initial reading (300 seeds, current targets)

| Skill | Plain | Scattered | Value | Engine | No imbues | No exotics | No removals |
|---|---:|---:|---:|---:|---:|---:|---:|
| hard | 0% | 0% | 0% | 0% | 0% | 0% | 0% |
| middle | 0% | 0% | 0% | 1% | 0% | 0% | 0% |
| strong | 0% | 5% | 1% | 20% | 11% | 14% | 16% |

These numbers show that all three ball upgrades help the focused build under the stated assumptions. They do not yet establish that each is *required* in real play. Table 5 is the steepest cutoff for plain and scattered builds in this probe; later high-scoring tables are only reached by a selected group of surviving runs. Avoid increasing all targets uniformly based on this output alone. First calibrate the pot and scratch rates by table, then adjust individual targets and repeat the same seeded comparison.
