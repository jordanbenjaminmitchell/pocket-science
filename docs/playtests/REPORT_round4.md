# Emulated playtest report

190 complete runs by 6 simulated player types, played through the real physics, scoring, shop and boss rules (tools/playtest.gd). Generated 2026-11-07.

Personas: **novice** (1.0° aim error, picks the easiest-looking pot, judges power by eye, random shopping), **casual** (0.6°, light lookahead, cheap shopping), **builder** (0.4°, synergy families, rerolls), **saver** (0.4°, economy first), **gambler** (0.5°, chases the biggest score, risk formulas), **expert** (0.2°, full lookahead, value shopping).

## 1. How each kind of player does

| Player | Runs | Win rate | Avg tables cleared | Median | Pot rate | Shots / table | Best shot (avg) | Bounties / run |
|---|---|---|---|---|---|---|---|---|
| novice | 40 | 0% | 1.9 | 2 | 42% balls/shot | 5.6 | 385 | 0.7 |
| casual | 30 | 7% | 4.1 | 5 | 57% balls/shot | 5.0 | 3857 | 2.0 |
| builder | 30 | 0% | 4.3 | 4 | 63% balls/shot | 5.2 | 1361 | 1.5 |
| saver | 30 | 10% | 4.9 | 5 | 63% balls/shot | 4.6 | 2043 | 2.2 |
| gambler | 30 | 0% | 4.1 | 4 | 55% balls/shot | 4.8 | 2140 | 1.4 |
| expert | 30 | 7% | 5.6 | 6 | 68% balls/shot | 5.4 | 2333 | 2.8 |

## 2. Where runs end (table reached)

| Player | T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | Win |
|---|---|---|---|---|---|---|---|---|---|---|
| novice | 9 | 11 | 12 | 1 | 2 | 3 |  | 1 | 1 | 0 |
| casual | 2 | 3 | 6 | 3 | 1 | 5 | 3 | 5 |  | 2 |
| builder | 1 | 3 | 8 | 3 | 1 | 3 | 2 | 3 | 6 | 0 |
| saver |  | 2 | 5 | 3 | 4 | 3 | 5 | 2 | 3 | 3 |
| gambler | 1 | 2 | 8 | 1 | 4 | 7 | 1 | 4 | 2 | 0 |
| expert |  | 1 | 3 | 1 | 3 | 6 | 3 | 7 | 4 | 2 |

## 3. Table difficulty (all players)

| Table | Target | Attempts | Cleared | Avg score / target when cleared | Avg score / target when lost |
|---|---|---|---|---|---|
| 1 | 60 | 190 | 93% | 1.9× | 0.7× |
| 2 | 160 | 177 | 88% | 2.3× | 0.5× |
| 3 | 340 | 155 | 73% | 4.6× | 0.5× |
| 4 | 550 | 113 | 89% | 2.3× | 0.6× |
| 5 | 800 | 101 | 85% | 1.8× | 0.6× |
| 6 | 1150 | 86 | 69% | 1.5× | 0.4× |
| 7 | 1500 | 59 | 76% | 1.4× | 0.5× |
| 8 | 2200 | 45 | 51% | 1.7× | 0.6× |
| 9 | 3200 | 23 | 30% | 1.6× | 0.5× |

## 4. Boss lethality

| Boss | Attempts | Lost there | Death rate |
|---|---|---|---|
| onepocket | 22 | 18 | 82% |
| rotation | 15 | 9 | 60% |
| taxman | 16 | 7 | 44% |
| shrink | 17 | 6 | 35% |
| tight | 25 | 8 | 32% |
| cold | 16 | 5 | 31% |
| lead | 13 | 4 | 31% |
| sealed | 23 | 7 | 30% |
| dry | 21 | 5 | 24% |
| blind | 17 | 4 | 24% |
| tilt | 18 | 4 | 22% |
| cursed8 | 14 | 3 | 21% |
| fog | 18 | 3 | 17% |
| heavycue | 24 | 2 | 8% |
| blackice | 5 | 0 | 0% |

## 5. Lab difficulty (non-boss tables)

| Lab | Attempts | Death rate |
|---|---|---|
| standard | 293 | 14% |
| cryo | 119 | 8% |
| spring | 66 | 17% |
| cyclotron | 113 | 16% |
| gravity | 94 | 18% |

## 6. Starting cues

| Cue | Runs | Win rate | Avg tables cleared |
|---|---|---|---|
| momentum | 33 | 3% | 3.9 |
| hotrod | 34 | 3% | 4.0 |
| gilded | 43 | 5% | 4.8 |
| optic | 42 | 2% | 3.9 |
| maple | 38 | 5% | 3.4 |

## 7. Formulas

Overall average tables cleared: **4.0**. "Lift" is the average tables cleared by runs that owned the formula, minus that overall average. It's a correlation, not proof: good players also buy more, so read it together with the sample size.

### Most bought

| Formula | Bought | Runs owning | Lift |
|---|---|---|---|
| Rhythm | 36 | 36 | +0.7 |
| Coupon Book | 34 | 34 | +0.5 |
| Bounty Hunter | 27 | 27 | +0.9 |
| Thrift | 25 | 25 | -0.2 |
| Even Hypothesis | 24 | 24 | +0.9 |
| Corner Theorem | 21 | 21 | +1.7 |
| Stay Hot | 21 | 21 | +1.3 |
| High Roller | 21 | 21 | -0.0 |
| Solid State | 19 | 19 | +1.0 |
| Side Effect | 19 | 19 | +1.0 |
| Momentum | 19 | 52 | +0.4 |
| Wide Jaws | 18 | 18 | +0.9 |

### Strongest by lift (owned by 6+ runs)

| Formula | Runs owning | Lift |
|---|---|---|
| Sacred Geometry | 11 | +3.0 |
| Domino Effect | 6 | +2.8 |
| Catalyst | 11 | +2.8 |
| Precision | 11 | +2.5 |
| Prime Directive | 10 | +2.4 |
| Supernova | 8 | +2.2 |
| Causality Insurance | 8 | +2.0 |
| Fibonacci | 6 | +2.0 |
| Chain Reaction | 15 | +1.9 |
| Odd Hypothesis | 6 | +1.8 |

### Weakest by lift (owned by 6+ runs)

| Formula | Runs owning | Lift |
|---|---|---|
| Overflow | 14 | -0.5 |
| Thrift | 25 | -0.2 |
| Stun Master | 10 | -0.1 |
| High Roller | 21 | -0.0 |
| Long Lens | 52 | 0.0 |
| Money Ball | 9 | 0.2 |
| Glass Cannon | 7 | 0.3 |
| Kick Drum | 10 | 0.3 |
| Velvet Cloth | 10 | 0.3 |
| Momentum | 52 | 0.4 |

**Never bought (1):** Laplace's Demon

## 8. Fouls and reagents

Of 4837 shots: Miss 39%, Scratch 5%, Wrong ball first 0%, Wrong pocket 1%, No contact 0%.

Reagents used: hotswap ×33, hand ×22, spare ×84, bluechalk ×87, forecast ×9.
