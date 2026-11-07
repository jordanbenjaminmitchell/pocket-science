# Emulated playtest report

190 complete runs by 6 simulated player types, played through the real physics, scoring, shop and boss rules (tools/playtest.gd). Generated 2026-11-07.

Personas: **novice** (1.0° aim error, picks the easiest-looking pot, judges power by eye, random shopping), **casual** (0.6°, light lookahead, cheap shopping), **builder** (0.4°, synergy families, rerolls), **saver** (0.4°, economy first), **gambler** (0.5°, chases the biggest score, risk formulas), **expert** (0.2°, full lookahead, value shopping).

## 1. How each kind of player does

| Player | Runs | Win rate | Avg tables cleared | Median | Pot rate | Shots / table | Best shot (avg) | Bounties / run |
|---|---|---|---|---|---|---|---|---|
| novice | 40 | 0% | 1.9 | 2 | 42% balls/shot | 5.4 | 571 | 0.7 |
| casual | 30 | 0% | 3.9 | 4 | 57% balls/shot | 5.3 | 3662 | 2.0 |
| builder | 30 | 7% | 4.4 | 4 | 64% balls/shot | 5.3 | 2193 | 1.8 |
| saver | 30 | 10% | 4.8 | 5 | 64% balls/shot | 4.8 | 1774 | 2.2 |
| gambler | 30 | 0% | 4.0 | 5 | 56% balls/shot | 4.9 | 4607 | 1.4 |
| expert | 30 | 13% | 6.0 | 6 | 70% balls/shot | 5.5 | 2002 | 2.9 |

## 2. Where runs end (table reached)

| Player | T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 | Win |
|---|---|---|---|---|---|---|---|---|---|---|
| novice | 9 | 11 | 10 | 3 | 3 | 2 |  | 1 | 1 | 0 |
| casual | 2 | 4 | 5 | 4 | 1 | 5 | 2 | 6 | 1 | 0 |
| builder | 1 | 3 | 8 | 3 | 1 | 3 | 1 | 3 | 5 | 2 |
| saver |  | 2 | 6 | 2 | 5 | 2 | 5 | 2 | 3 | 3 |
| gambler | 1 | 2 | 8 | 2 | 2 | 9 | 1 | 4 | 1 | 0 |
| expert |  | 1 | 2 | 1 | 2 | 6 | 4 | 6 | 4 | 4 |

## 3. Table difficulty (all players)

| Table | Target | Attempts | Cleared | Avg score / target when cleared | Avg score / target when lost |
|---|---|---|---|---|---|
| 1 | 60 | 190 | 93% | 1.9× | 0.7× |
| 2 | 160 | 177 | 87% | 2.3× | 0.5× |
| 3 | 340 | 154 | 75% | 4.0× | 0.5× |
| 4 | 550 | 115 | 87% | 2.6× | 0.5× |
| 5 | 800 | 100 | 86% | 1.7× | 0.6× |
| 6 | 1150 | 86 | 69% | 1.7× | 0.5× |
| 7 | 1700 | 59 | 78% | 2.6× | 0.6× |
| 8 | 2500 | 46 | 52% | 1.2× | 0.6× |
| 9 | 3600 | 24 | 38% | 1.8× | 0.6× |

## 4. Boss lethality

| Boss | Attempts | Lost there | Death rate |
|---|---|---|---|
| onepocket | 19 | 12 | 63% |
| rotation | 13 | 6 | 46% |
| tight | 29 | 13 | 45% |
| taxman | 17 | 7 | 41% |
| cursed8 | 14 | 5 | 36% |
| blind | 15 | 5 | 33% |
| cold | 16 | 5 | 31% |
| sealed | 23 | 7 | 30% |
| shrink | 18 | 5 | 28% |
| lead | 12 | 3 | 25% |
| fog | 20 | 5 | 25% |
| dry | 21 | 5 | 24% |
| heavycue | 24 | 3 | 13% |
| tilt | 18 | 0 | 0% |
| blackice | 5 | 0 | 0% |

## 5. Lab difficulty (non-boss tables)

| Lab | Attempts | Death rate |
|---|---|---|
| standard | 292 | 14% |
| cryo | 128 | 11% |
| spring | 62 | 13% |
| cyclotron | 114 | 10% |
| gravity | 91 | 27% |

## 6. Starting cues

| Cue | Runs | Win rate | Avg tables cleared |
|---|---|---|---|
| momentum | 33 | 0% | 3.7 |
| hotrod | 34 | 6% | 4.2 |
| gilded | 43 | 5% | 5.0 |
| optic | 42 | 7% | 3.9 |
| maple | 38 | 5% | 3.3 |

## 7. Formulas

Overall average tables cleared: **4.1**. "Lift" is the average tables cleared by runs that owned the formula, minus that overall average. It's a correlation, not proof: good players also buy more, so read it together with the sample size.

### Most bought

| Formula | Bought | Runs owning | Lift |
|---|---|---|---|
| Rhythm | 38 | 38 | +1.2 |
| Coupon Book | 31 | 31 | +0.3 |
| Stay Hot | 28 | 28 | +1.6 |
| Bounty Hunter | 25 | 25 | +0.7 |
| Thrift | 24 | 24 | -0.3 |
| Even Hypothesis | 23 | 23 | +1.3 |
| Solid State | 21 | 21 | +1.3 |
| Afterburner | 21 | 21 | +0.4 |
| Corner Theorem | 20 | 20 | +0.6 |
| Wide Jaws | 20 | 20 | +0.4 |
| Heat Sink | 19 | 53 | +0.8 |
| High Roller | 19 | 19 | -0.5 |

### Strongest by lift (owned by 6+ runs)

| Formula | Runs owning | Lift |
|---|---|---|
| Precision | 13 | +2.6 |
| Catalyst | 12 | +2.6 |
| Fibonacci | 6 | +2.6 |
| Sacred Geometry | 9 | +2.4 |
| Chain Reaction | 14 | +2.2 |
| Causality Insurance | 8 | +1.9 |
| Low Ball | 14 | +1.9 |
| Prime Directive | 10 | +1.8 |
| Supernova | 6 | +1.8 |
| Minimalist | 8 | +1.7 |

### Weakest by lift (owned by 6+ runs)

| Formula | Runs owning | Lift |
|---|---|---|
| Overflow | 11 | -1.4 |
| High Roller | 19 | -0.5 |
| Thrift | 24 | -0.3 |
| Long Lens | 52 | -0.1 |
| Momentum | 49 | 0.1 |
| Coupon Book | 31 | 0.3 |
| Stun Master | 9 | 0.3 |
| Stripe Theory | 16 | 0.4 |
| Afterburner | 21 | 0.4 |
| Wide Jaws | 20 | 0.4 |

**Never bought (1):** Laplace's Demon

## 8. Fouls and reagents

Of 4940 shots: Miss 39%, Scratch 5%, Wrong ball first 0%, Wrong pocket 1%, No contact 0%.

Reagents used: spare ×81, hotswap ×38, hand ×20, bluechalk ×94, forecast ×9.
