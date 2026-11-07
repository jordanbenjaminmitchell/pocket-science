# Emulated playtest report

190 complete runs by 6 simulated player types, played through the real physics, scoring, shop and boss rules (tools/playtest.gd). Generated 2026-11-07.

Personas: **novice** (1.0° aim error, picks the easiest-looking pot, judges power by eye, random shopping), **casual** (0.6°, light lookahead, cheap shopping), **builder** (0.4°, synergy families, rerolls), **saver** (0.4°, economy first), **gambler** (0.5°, chases the biggest score, risk formulas), **expert** (0.2°, full lookahead, value shopping).

## 1. How each kind of player does

| Player | Runs | Win rate | Avg tables cleared | Median | Pot rate | Shots / table | Best shot (avg) | Bounties / run |
|---|---|---|---|---|---|---|---|---|
| novice | 40 | 0% | 1.6 | 1 | 43% balls/shot | 6.1 | 269 | 0.8 |
| casual | 30 | 3% | 3.2 | 2 | 57% balls/shot | 5.3 | 3517 | 1.6 |
| builder | 30 | 0% | 3.6 | 4 | 62% balls/shot | 5.6 | 1015 | 1.9 |
| saver | 30 | 7% | 4.7 | 5 | 58% balls/shot | 6.5 | 2274 | 2.2 |
| gambler | 30 | 0% | 3.0 | 2 | 53% balls/shot | 5.6 | 3670 | 1.0 |
| expert | 30 | 33% | 6.8 | 7 | 69% balls/shot | 6.4 | 2758 | 3.2 |

## 2. Where runs end (table reached)

| Player | T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | Win |
|---|---|---|---|---|---|---|---|---|---|---|
| novice | 13 | 10 | 11 | 1 | 3 |  |  | 1 | 1 | 0 |
| casual | 3 | 6 | 8 | 4 | 1 | 1 | 1 | 3 | 2 | 1 |
| builder | 4 | 4 | 4 | 3 | 3 | 4 | 3 | 2 | 3 | 0 |
| saver |  | 3 | 2 | 2 | 8 | 5 | 5 | 1 | 2 | 2 |
| gambler | 3 | 3 | 11 | 3 | 2 | 4 | 1 | 3 |  | 0 |
| expert |  |  | 1 |  | 3 | 4 | 7 | 3 | 2 | 10 |

## 3. Table difficulty (all players)

| Table | Target | Attempts | Cleared | Avg score / target when cleared | Avg score / target when lost |
|---|---|---|---|---|---|
| 1 | 80 | 190 | 88% | 1.8× | 0.7× |
| 2 | 190 | 167 | 84% | 2.0× | 0.6× |
| 3 | 340 | 141 | 74% | 4.2× | 0.5× |
| 4 | 550 | 104 | 88% | 2.5× | 0.7× |
| 5 | 800 | 91 | 78% | 1.7× | 0.5× |
| 6 | 1150 | 71 | 75% | 1.6× | 0.4× |
| 7 | 1700 | 53 | 68% | 3.2× | 0.6× |
| 8 | 2500 | 36 | 64% | 1.5× | 0.6× |
| 9 | 3600 | 23 | 57% | 1.5× | 0.5× |

## 4. Boss lethality

| Boss | Attempts | Lost there | Death rate |
|---|---|---|---|
| onepocket | 13 | 7 | 54% |
| blind | 15 | 7 | 47% |
| tight | 25 | 10 | 40% |
| taxman | 17 | 6 | 35% |
| cold | 13 | 4 | 31% |
| lead | 10 | 3 | 30% |
| dry | 17 | 5 | 29% |
| sealed | 21 | 6 | 29% |
| rotation | 15 | 4 | 27% |
| shrink | 16 | 4 | 25% |
| fog | 16 | 4 | 25% |
| cursed8 | 14 | 3 | 21% |
| tilt | 15 | 1 | 7% |
| heavycue | 23 | 1 | 4% |
| blackice | 5 | 0 | 0% |

## 5. Lab difficulty (non-boss tables)

| Lab | Attempts | Death rate |
|---|---|---|
| standard | 280 | 18% |
| spring | 61 | 23% |
| cryo | 113 | 9% |
| cyclotron | 105 | 15% |
| gravity | 82 | 27% |

## 6. Starting cues

| Cue | Runs | Win rate | Avg tables cleared |
|---|---|---|---|
| momentum | 33 | 0% | 3.8 |
| hotrod | 34 | 15% | 4.4 |
| gilded | 43 | 9% | 3.9 |
| optic | 42 | 7% | 3.5 |
| maple | 38 | 3% | 2.8 |

## 7. Formulas

Overall average tables cleared: **3.7**. "Lift" is the average tables cleared by runs that owned the formula, minus that overall average. It's a correlation, not proof: good players also buy more, so read it together with the sample size.

### Most bought

| Formula | Bought | Runs owning | Lift |
|---|---|---|---|
| Rhythm | 42 | 42 | +1.2 |
| Coupon Book | 27 | 27 | +0.5 |
| Thrift | 23 | 23 | +0.3 |
| Bounty Hunter | 23 | 23 | +0.9 |
| Even Hypothesis | 22 | 22 | +1.2 |
| Corner Theorem | 20 | 20 | +1.0 |
| Stay Hot | 20 | 20 | +2.0 |
| Stripe Theory | 19 | 19 | -0.2 |
| Side Effect | 19 | 19 | +1.4 |
| Wide Jaws | 19 | 19 | +1.8 |
| Heat Sink | 18 | 52 | +1.1 |
| Spare Chalk | 16 | 16 | +1.3 |

### Strongest by lift (owned by 6+ runs)

| Formula | Runs owning | Lift |
|---|---|---|
| Causality Insurance | 6 | +5.3 |
| Sacred Geometry | 9 | +3.5 |
| Precision | 6 | +3.5 |
| Supernova | 9 | +3.3 |
| Echo Chamber | 7 | +3.2 |
| Glass Cannon | 7 | +3.0 |
| Catalyst | 10 | +2.3 |
| Gold Standard | 7 | +2.0 |
| Stay Hot | 20 | +2.0 |
| Hot Hand | 13 | +2.0 |

### Weakest by lift (owned by 6+ runs)

| Formula | Runs owning | Lift |
|---|---|---|
| High Roller | 14 | -0.6 |
| Overflow | 11 | -0.6 |
| Tracer Round | 15 | -0.4 |
| Long Lens | 49 | -0.3 |
| Stripe Theory | 19 | -0.2 |
| Afterburner | 11 | -0.1 |
| Compound Interest | 56 | 0.3 |
| Thrift | 23 | 0.3 |
| Cluster Theory | 6 | 0.5 |
| Coupon Book | 27 | 0.5 |

**Never bought (1):** Laplace's Demon

## 8. Fouls and reagents

Of 5260 shots: Miss 39%, Scratch 5%, No contact 0%, Wrong pocket 1%, Wrong ball first 1%.

Reagents used: spare ×59, bluechalk ×95, hotswap ×34, hand ×11, forecast ×4.
