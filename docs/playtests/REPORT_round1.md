# Emulated playtest report

190 complete runs by 6 simulated player types, played through the real physics, scoring, shop and boss rules (tools/playtest.gd). Generated 2026-11-07.

Personas: **novice** (1.0° aim error, picks the easiest-looking pot, judges power by eye, random shopping), **casual** (0.6°, light lookahead, cheap shopping), **builder** (0.4°, synergy families, rerolls), **saver** (0.4°, economy first), **gambler** (0.5°, chases the biggest score, risk formulas), **expert** (0.2°, full lookahead, value shopping).

## 1. How each kind of player does

| Player | Runs | Win rate | Avg tables cleared | Median | Pot rate | Shots / table | Best shot (avg) | Bounties / run |
|---|---|---|---|---|---|---|---|---|
| novice | 40 | 0% | 1.5 | 1 | 43% balls/shot | 5.0 | 285 | 0.8 |
| casual | 30 | 3% | 1.6 | 1 | 50% balls/shot | 4.9 | 449 | 1.0 |
| builder | 30 | 0% | 2.6 | 2 | 60% balls/shot | 5.2 | 765 | 1.2 |
| saver | 30 | 7% | 3.1 | 3 | 50% balls/shot | 7.5 | 708 | 1.4 |
| gambler | 30 | 0% | 2.4 | 2 | 55% balls/shot | 5.2 | 863 | 1.1 |
| expert | 30 | 20% | 4.8 | 5 | 64% balls/shot | 6.6 | 1711 | 2.3 |

## 2. Where runs end (table reached)

| Player | T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | Win |
|---|---|---|---|---|---|---|---|---|---|---|
| novice | 16 | 11 | 5 | 2 | 1 | 3 | 1 | 1 |  | 0 |
| casual | 8 | 9 | 7 | 4 |  | 1 |  |  |  | 1 |
| builder | 7 | 4 | 5 | 2 | 5 | 4 | 2 | 1 |  | 0 |
| saver | 3 | 7 | 4 | 4 | 6 | 3 |  |  | 1 | 2 |
| gambler | 5 | 6 | 11 | 3 |  | 1 |  | 2 | 2 | 0 |
| expert | 2 | 3 | 3 | 3 | 4 | 3 | 3 | 2 | 1 | 6 |

## 3. Table difficulty (all players)

| Table | Target | Attempts | Cleared | Avg score / target when cleared | Avg score / target when lost |
|---|---|---|---|---|---|
| 1 | 80 | 190 | 78% | 1.7× | 0.5× |
| 2 | 190 | 149 | 73% | 1.9× | 0.5× |
| 3 | 340 | 109 | 68% | 1.6× | 0.4× |
| 4 | 550 | 74 | 76% | 2.6× | 0.5× |
| 5 | 800 | 56 | 71% | 1.3× | 0.6× |
| 6 | 1150 | 40 | 63% | 2.0× | 0.4× |
| 7 | 1700 | 25 | 76% | 1.3× | 0.5× |
| 8 | 2500 | 19 | 68% | 1.2× | 0.4× |
| 9 | 3600 | 13 | 69% | 1.3× | 0.3× |

## 4. Boss lethality

| Boss | Attempts | Lost there | Death rate |
|---|---|---|---|
| onepocket | 9 | 7 | 78% |
| rotation | 12 | 7 | 58% |
| taxman | 10 | 5 | 50% |
| shrink | 8 | 4 | 50% |
| blind | 9 | 4 | 44% |
| tight | 20 | 8 | 40% |
| lead | 9 | 3 | 33% |
| cursed8 | 11 | 3 | 27% |
| dry | 15 | 4 | 27% |
| cold | 8 | 2 | 25% |
| tilt | 10 | 2 | 20% |
| sealed | 11 | 2 | 18% |
| fog | 12 | 2 | 17% |
| heavycue | 14 | 1 | 7% |
| blackice | 4 | 0 | 0% |

## 5. Lab difficulty (non-boss tables)

| Lab | Attempts | Death rate |
|---|---|---|
| standard | 252 | 22% |
| spring | 46 | 28% |
| cryo | 74 | 18% |
| cyclotron | 76 | 28% |
| gravity | 65 | 37% |

## 6. Starting cues

| Cue | Runs | Win rate | Avg tables cleared |
|---|---|---|---|
| momentum | 33 | 3% | 2.3 |
| hotrod | 34 | 3% | 2.6 |
| gilded | 43 | 7% | 2.7 |
| optic | 42 | 5% | 3.0 |
| maple | 38 | 5% | 2.3 |

## 7. Formulas

Overall average tables cleared: **2.6**. "Lift" is the average tables cleared by runs that owned the formula, minus that overall average. It's a correlation, not proof: good players also buy more, so read it together with the sample size.

### Most bought

| Formula | Bought | Runs owning | Lift |
|---|---|---|---|
| Rhythm | 36 | 36 | +2.1 |
| Coupon Book | 20 | 20 | +1.0 |
| Corner Theorem | 19 | 19 | +1.3 |
| Even Hypothesis | 18 | 18 | +1.8 |
| Stay Hot | 16 | 16 | +1.6 |
| Spare Chalk | 15 | 15 | +2.1 |
| Side Effect | 14 | 14 | +1.5 |
| Comeback | 14 | 14 | +2.1 |
| Afterburner | 13 | 13 | +1.3 |
| High Roller | 13 | 13 | +0.1 |
| Thrift | 13 | 13 | +0.9 |
| Bounty Hunter | 12 | 12 | +0.2 |

### Strongest by lift (owned by 6+ runs)

| Formula | Runs owning | Lift |
|---|---|---|
| Echo Chamber | 7 | +3.8 |
| Sacred Geometry | 7 | +3.5 |
| Chain Reaction | 10 | +3.3 |
| Catalyst | 9 | +3.1 |
| Golden Ratio | 7 | +2.8 |
| Wide Jaws | 11 | +2.6 |
| Supernova | 7 | +2.5 |
| Solid State | 9 | +2.5 |
| Venture Capital | 9 | +2.4 |
| Odd Hypothesis | 11 | +2.3 |

### Weakest by lift (owned by 6+ runs)

| Formula | Runs owning | Lift |
|---|---|---|
| Momentum | 41 | 0.0 |
| High Roller | 13 | 0.1 |
| Compound Interest | 48 | 0.2 |
| Heat Sink | 45 | 0.2 |
| Kick Drum | 6 | 0.2 |
| Bounty Hunter | 12 | 0.2 |
| Cushion Theory | 7 | 0.3 |
| Stripe Theory | 11 | 0.3 |
| Long Lens | 50 | 0.5 |
| Lever Arm | 7 | 0.5 |

**Never bought (1):** Laplace's Demon

## 8. Fouls and reagents

Of 3972 shots: Miss 39%, Scratch 4%, No contact 0%, Wrong pocket 0%, Wrong ball first 6%.

Reagents used: spare ×46, bluechalk ×76, hotswap ×29, hand ×9, forecast ×4.
