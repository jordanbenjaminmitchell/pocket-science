# Emulated playtest report

220 complete runs by 6 simulated player types, played through the real physics, scoring, shop and boss rules (tools/playtest.gd). Generated 2026-11-08.

Personas: **novice** (1.0° aim error, picks the easiest-looking pot, judges power by eye, random shopping), **casual** (0.6°, light lookahead, cheap shopping), **builder** (0.4°, synergy families, rerolls), **saver** (0.4°, economy first), **gambler** (0.5°, chases the biggest score, risk formulas), **expert** (0.2°, full lookahead, value shopping).

## 1. How each kind of player does

| Player | Runs | Win rate | Avg tables cleared | Median | Pot rate | Shots / table | Best shot (avg) | Bounties / run |
|---|---|---|---|---|---|---|---|---|
| novice | 40 | 0% | 2.0 | 2 | 43% balls/shot | 5.6 | 408 | 0.8 |
| casual | 30 | 7% | 4.2 | 5 | 57% balls/shot | 5.0 | 4962 | 2.1 |
| builder | 30 | 10% | 4.6 | 4 | 63% balls/shot | 5.4 | 1430 | 1.7 |
| saver | 30 | 10% | 4.9 | 5 | 64% balls/shot | 4.7 | 2012 | 2.3 |
| gambler | 30 | 0% | 4.1 | 5 | 55% balls/shot | 4.8 | 2155 | 1.5 |
| expert | 60 | 18% | 5.8 | 6 | 70% balls/shot | 5.2 | 2960 | 2.7 |

## 2. Where runs end (table reached)

| Player | T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | Win |
|---|---|---|---|---|---|---|---|---|---|---|
| novice | 9 | 11 | 11 | 1 | 2 | 2 | 1 | 2 | 1 | 0 |
| casual | 2 | 3 | 6 | 2 | 1 | 6 | 3 | 5 |  | 2 |
| builder | 1 | 3 | 8 | 3 | 1 | 1 | 2 | 2 | 6 | 3 |
| saver |  | 2 | 5 | 3 | 4 | 2 | 5 | 4 | 2 | 3 |
| gambler | 1 | 2 | 7 | 1 | 4 | 7 | 3 | 4 | 1 | 0 |
| expert |  | 4 | 7 | 2 | 3 | 10 | 6 | 8 | 9 | 11 |

## 3. Table difficulty (all players)

| Table | Target | Attempts | Cleared | Avg score / target when cleared | Avg score / target when lost |
|---|---|---|---|---|---|
| 1 | 60 | 220 | 94% | 1.9× | 0.7× |
| 2 | 160 | 207 | 88% | 2.2× | 0.5× |
| 3 | 340 | 182 | 76% | 5.0× | 0.5× |
| 4 | 550 | 138 | 91% | 2.2× | 0.6× |
| 5 | 800 | 126 | 88% | 1.9× | 0.6× |
| 6 | 1150 | 111 | 75% | 1.5× | 0.5× |
| 7 | 1500 | 83 | 76% | 1.7× | 0.6× |
| 8 | 2000 | 63 | 60% | 1.9× | 0.6× |
| 9 | 2800 | 38 | 50% | 1.9× | 0.6× |

## 4. Boss lethality

| Boss | Attempts | Lost there | Death rate |
|---|---|---|---|
| rotation | 20 | 12 | 60% |
| onepocket | 23 | 12 | 52% |
| taxman | 16 | 6 | 38% |
| tight | 32 | 11 | 34% |
| shrink | 21 | 7 | 33% |
| lead | 16 | 5 | 31% |
| cold | 24 | 7 | 29% |
| dry | 26 | 7 | 27% |
| cursed8 | 18 | 4 | 22% |
| tilt | 24 | 5 | 21% |
| sealed | 30 | 6 | 20% |
| blind | 23 | 4 | 17% |
| fog | 20 | 3 | 15% |
| heavycue | 30 | 2 | 7% |
| blackice | 8 | 0 | 0% |

## 5. Lab difficulty (non-boss tables)

| Lab | Attempts | Death rate |
|---|---|---|
| standard | 349 | 13% |
| cryo | 140 | 6% |
| spring | 88 | 14% |
| cyclotron | 138 | 15% |
| gravity | 122 | 19% |

## 6. Starting cues

| Cue | Runs | Win rate | Avg tables cleared |
|---|---|---|---|
| momentum | 38 | 5% | 4.3 |
| hotrod | 42 | 10% | 4.4 |
| gilded | 49 | 10% | 5.1 |
| optic | 45 | 7% | 4.2 |
| maple | 46 | 11% | 3.9 |

## 7. Formulas

Overall average tables cleared: **4.4**. "Lift" is the average tables cleared by runs that owned the formula, minus that overall average. It's a correlation, not proof: good players also buy more, so read it together with the sample size.

### Most bought

| Formula | Bought | Runs owning | Lift |
|---|---|---|---|
| Rhythm | 45 | 45 | +0.9 |
| Coupon Book | 36 | 36 | -0.1 |
| Corner Theorem | 31 | 31 | +1.8 |
| Stay Hot | 29 | 29 | +1.3 |
| Bounty Hunter | 29 | 29 | +0.9 |
| Even Hypothesis | 27 | 27 | +0.8 |
| Momentum | 27 | 65 | +0.6 |
| Thrift | 26 | 26 | -0.2 |
| Stripe Theory | 25 | 25 | +0.8 |
| Side Effect | 24 | 24 | +1.1 |
| Heat Sink | 24 | 66 | +0.7 |
| Wide Jaws | 23 | 23 | +1.3 |

### Strongest by lift (owned by 6+ runs)

| Formula | Runs owning | Lift |
|---|---|---|
| Catalyst | 15 | +2.9 |
| Sacred Geometry | 16 | +2.9 |
| Causality Insurance | 11 | +2.7 |
| Domino Effect | 6 | +2.4 |
| Pocket Collector | 7 | +2.3 |
| Golden Ratio | 10 | +2.3 |
| Prime Directive | 10 | +2.2 |
| Precision | 11 | +2.1 |
| Fibonacci | 7 | +2.0 |
| Odd Hypothesis | 8 | +2.0 |

### Weakest by lift (owned by 6+ runs)

| Formula | Runs owning | Lift |
|---|---|---|
| Overflow | 14 | -1.0 |
| Thrift | 26 | -0.2 |
| Long Lens | 55 | -0.1 |
| Coupon Book | 36 | -0.1 |
| Minimalist | 6 | -0.1 |
| Velvet Cloth | 10 | 0.0 |
| High Roller | 22 | 0.1 |
| Spare Chalk | 17 | 0.2 |
| Cushion Theory | 14 | 0.3 |
| Money Ball | 11 | 0.3 |

**Never bought (1):** Laplace's Demon

## 8. Fouls and reagents

Of 5982 shots: Miss 37%, Scratch 5%, Wrong ball first 1%, Wrong pocket 0%, No contact 0%.

Reagents used: hotswap ×49, hand ×28, spare ×94, bluechalk ×108, forecast ×10.
