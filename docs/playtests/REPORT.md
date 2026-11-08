# Emulated playtest report

220 complete runs by 6 simulated player types, played through the real physics, scoring, shop and boss rules (tools/playtest.gd). Generated 2026-11-08.

Personas: **novice** (1.0° aim error, picks the easiest-looking pot, judges power by eye, random shopping), **casual** (0.6°, light lookahead, cheap shopping), **builder** (0.4°, synergy families, rerolls), **saver** (0.4°, economy first), **gambler** (0.5°, chases the biggest score, risk formulas), **expert** (0.2°, full lookahead, value shopping).

## 1. How each kind of player does

| Player | Runs | Win rate | Avg tables cleared | Median | Pot rate | Shots / table | Best shot (avg) | Bounties / run |
|---|---|---|---|---|---|---|---|---|
| novice | 40 | 3% | 2.3 | 2 | 46% balls/shot | 5.1 | 964 | 0.7 |
| casual | 30 | 0% | 3.2 | 3 | 53% balls/shot | 4.3 | 1427 | 1.5 |
| builder | 30 | 10% | 3.8 | 3 | 59% balls/shot | 4.7 | 1349 | 1.9 |
| saver | 30 | 3% | 4.5 | 4 | 60% balls/shot | 5.0 | 1355 | 1.9 |
| gambler | 30 | 13% | 4.1 | 3 | 59% balls/shot | 4.5 | 3921 | 1.8 |
| expert | 60 | 20% | 5.8 | 5 | 70% balls/shot | 4.7 | 2408 | 2.8 |

## 2. Where runs end (table reached)

| Player | T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | Win |
|---|---|---|---|---|---|---|---|---|---|---|
| novice | 12 | 7 | 6 | 5 | 3 | 2 | 2 | 1 | 1 | 1 |
| casual | 4 | 2 | 9 | 2 | 5 | 3 | 2 | 1 | 2 | 0 |
| builder | 1 | 4 | 7 | 4 | 2 | 6 | 2 | 1 |  | 3 |
| saver |  | 3 | 5 | 2 | 7 | 5 | 1 | 1 | 5 | 1 |
| gambler | 2 | 4 | 4 | 6 | 1 | 2 | 6 | 1 |  | 4 |
| expert |  | 1 | 9 | 3 | 4 | 14 | 4 | 4 | 9 | 12 |

## 3. Table difficulty (all players)

| Table | Target | Attempts | Cleared | Avg score / target when cleared | Avg score / target when lost |
|---|---|---|---|---|---|
| 1 | 60 | 220 | 91% | 2.9× | 0.3× |
| 2 | 160 | 201 | 90% | 2.3× | 0.5× |
| 3 | 340 | 180 | 78% | 3.5× | 0.5× |
| 4 | 550 | 140 | 84% | 2.7× | 0.5× |
| 5 | 800 | 118 | 81% | 1.9× | 0.6× |
| 6 | 1150 | 96 | 67% | 2.4× | 0.4× |
| 7 | 1500 | 64 | 73% | 1.6× | 0.5× |
| 8 | 2000 | 47 | 81% | 1.4× | 0.6× |
| 9 | 2800 | 38 | 55% | 1.6× | 0.5× |

## 4. Boss lethality

| Boss | Attempts | Lost there | Death rate |
|---|---|---|---|
| onepocket | 18 | 10 | 56% |
| rotation | 17 | 8 | 47% |
| cursed8 | 23 | 10 | 43% |
| lead | 18 | 7 | 39% |
| blind | 19 | 7 | 37% |
| sealed | 29 | 10 | 34% |
| taxman | 22 | 6 | 27% |
| tilt | 19 | 5 | 26% |
| fog | 20 | 5 | 25% |
| tight | 33 | 8 | 24% |
| dry | 22 | 5 | 23% |
| shrink | 15 | 3 | 20% |
| cold | 23 | 4 | 17% |
| heavycue | 25 | 1 | 4% |
| blackice | 11 | 0 | 0% |

## 5. Lab difficulty (non-boss tables)

| Lab | Attempts | Death rate |
|---|---|---|
| standard | 273 | 12% |
| current | 68 | 19% |
| spring | 34 | 9% |
| magnetlab | 42 | 14% |
| pinball | 53 | 21% |
| dense | 55 | 16% |
| repulsor | 52 | 13% |
| cryo | 80 | 8% |
| gravity | 57 | 21% |
| cyclotron | 76 | 14% |

## 6. Starting cues

| Cue | Runs | Win rate | Avg tables cleared |
|---|---|---|---|
| angle | 18 | 17% | 4.6 |
| hotrod | 23 | 0% | 3.6 |
| glass | 31 | 16% | 3.4 |
| optic | 26 | 8% | 3.9 |
| maple | 16 | 6% | 3.9 |
| breaker | 30 | 10% | 4.3 |
| thermal | 19 | 0% | 4.6 |
| momentum | 20 | 20% | 5.5 |
| banker | 19 | 5% | 3.6 |
| gilded | 18 | 11% | 4.2 |

## 7. Formulas

Overall average tables cleared: **4.1**. "Lift" is the average tables cleared by runs that owned the formula, minus that overall average. It's a correlation, not proof: good players also buy more, so read it together with the sample size.

### Most bought

| Formula | Bought | Runs owning | Lift |
|---|---|---|---|
| Even Hypothesis | 46 | 46 | +0.9 |
| Rhythm | 42 | 42 | +1.0 |
| Corner Theorem | 33 | 33 | +1.3 |
| Bounty Hunter | 28 | 28 | -0.0 |
| Chain Reaction | 27 | 27 | +1.6 |
| Heat Sink | 27 | 50 | +0.6 |
| Afterburner | 26 | 56 | +0.6 |
| Spare Chalk | 25 | 25 | +0.0 |
| Side Effect | 24 | 24 | +1.2 |
| Wide Jaws | 22 | 22 | +0.6 |
| Featherweight | 22 | 22 | +1.8 |
| Thrift | 21 | 40 | -0.2 |

### Strongest by lift (owned by 6+ runs)

| Formula | Runs owning | Lift |
|---|---|---|
| Pocket Collector | 10 | +3.5 |
| Supernova | 8 | +3.4 |
| Precision | 11 | +3.0 |
| Echo Chamber | 6 | +2.6 |
| Elastic Collision | 12 | +2.2 |
| Catalyst | 8 | +2.1 |
| Ricochet | 8 | +2.1 |
| Golden Ratio | 7 | +2.0 |
| Venture Capital | 13 | +2.0 |
| Featherweight | 22 | +1.8 |

### Weakest by lift (owned by 6+ runs)

| Formula | Runs owning | Lift |
|---|---|---|
| Finesse | 7 | -0.5 |
| Coupon Book | 20 | -0.5 |
| Fibonacci | 6 | -0.4 |
| Long Lens | 36 | -0.4 |
| Glass Cannon | 37 | -0.3 |
| Lever Arm | 17 | -0.2 |
| Thrift | 40 | -0.2 |
| Bounty Hunter | 28 | -0.0 |
| Spare Chalk | 25 | 0.0 |
| Tracer Round | 9 | 0.2 |

**Never bought (0):** none

## 8. Fouls and reagents

Of 5187 shots: Miss 38%, Scratch 5%, No contact 1%, Wrong ball first 1%, Wrong pocket 0%, Cursed 8 0%.

Reagents used: callshot ×6, magnetize ×10, bluechalk ×61, spare ×46, overcharge ×9, wideopen ×9, adrenaline ×10, hotswap ×16, grant ×5, second ×13, scatter ×18, hand ×6, contract ×5, forecast ×1.
