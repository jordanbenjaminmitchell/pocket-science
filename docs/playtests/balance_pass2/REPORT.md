# Balance pass 2: headless physics playtests

108 completed bot runs. These use real table physics, scorer and run state; the bot's aiming, shopping and Catalyst placement are heuristics. Its Catalyst lookahead can preview the full noisy shot, which gives it more information than a human would usually have. Small groups and late tables have wide uncertainty.

These physics batches started before the latest uncommitted game edits. The current scoring probe was rerun separately; the physics results describe the earlier snapshot and are directional for the current working tree.

## Runs by batch

| Batch | Runs | Wins | Average tables cleared | Pots per shot | Catalyst uses per run |
|---|---:|---:|---:|---:|---:|
| builder_control | 6 | 0% | 5.5 | 0.74 | 9.2 |
| builder_focal | 6 | 0% | 5.2 | 0.74 | 11.2 |
| builder_goldenratio | 6 | 17% | 5.2 | 0.72 | 8.2 |
| builder_nudge | 6 | 33% | 6.3 | 0.76 | 7.3 |
| builder_off | 12 | 0% | 3.2 | 0.59 | 0.0 |
| builder_on | 12 | 0% | 4.6 | 0.68 | 6.6 |
| builder_pocketcover | 6 | 33% | 6.8 | 0.82 | 10.0 |
| builder_polish | 6 | 0% | 4.5 | 0.68 | 5.0 |
| casual_on | 12 | 0% | 2.8 | 0.62 | 2.9 |
| expert_off | 12 | 0% | 3.6 | 0.69 | 0.0 |
| expert_on | 12 | 33% | 6.1 | 0.76 | 6.1 |
| novice_on | 12 | 0% | 1.9 | 0.50 | 2.1 |

## Free starting Catalyst experiments

Same-seed controls use the builder bot with ordinary shop access. These grants are free, so differences measure opportunity and run impact rather than purchase value. Small matched groups are noisy.

| Grant | Matched runs | Mean table difference | Uses | Tested shots | Actionable shots |
|---|---:|---:|---:|---:|---:|
| focal | 6 | -0.3 | 32 | 80 | 38 |
| goldenratio | 6 | -0.3 | 15 | 153 | 18 |
| nudge | 6 | +0.8 | 11 | 168 | 12 |
| pocketcover | 6 | +1.3 | 12 | 189 | 15 |
| polish | 6 | -1.0 | 3 | 155 | 4 |

## Table scores

The clear percentage is conditional on reaching that table. Lost score is the average share of target reached on failed attempts.

| Table | Target | Attempts | Cleared | Median score / target | Lost score / target | Average shots | Average pots |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | 50 | 48 | 92% | 1.22× | 0.56× | 3.1 | — |
| 2 | 120 | 44 | 93% | 1.23× | 0.56× | 4.5 | — |
| 3 | 215 | 41 | 78% | 1.21× | 0.54× | 5.7 | — |
| 4 | 270 | 32 | 81% | 1.09× | 0.43× | 5.5 | — |
| 5 | 390 | 26 | 54% | 1.02× | 0.62× | 7.1 | — |
| 6 | 510 | 14 | 64% | 1.04× | 0.55× | 8.1 | — |
| 7 | 650 | 9 | 89% | 1.16× | 0.22× | 4.9 | — |
| 8 | 840 | 8 | 75% | 1.09× | 0.83× | 8.2 | — |
| 9 | 1060 | 6 | 67% | 1.07× | 0.19× | 9.2 | — |

## Clear rates by skill and table

| Batch | T1 | T2 | T3 | T4 | T5 | T6 | T7 | T8 | T9 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| builder_on | 100% | 100% | 100% | 92% | 36% | 50% | 50% | 100% | 0% |
| casual_on | 83% | 90% | 78% | 71% | 40% | 0% | — | — | — |
| expert_on | 100% | 92% | 91% | 90% | 89% | 88% | 100% | 71% | 80% |
| novice_on | 83% | 90% | 33% | 33% | 0% | — | — | — | — |

## Boards with at least three attempts

34 distinct board IDs were attempted in Catalyst-on baseline runs.

| Board ID | Attempts | Cleared | Median score / target |
|---|---:|---:|---:|
| foucault | 3 | 33% | 0.74× |
| magnet | 4 | 50% | 0.84× |
| lshell | 11 | 45% | 0.84× |
| final | 6 | 67% | 1.07× |
| elements | 26 | 54% | 1.02× |
| lorentz | 4 | 75% | 1.32× |
| smoke | 4 | 100% | 1.04× |
| galton | 7 | 71% | 1.13× |
| hypotenuse | 7 | 71% | 1.06× |
| closing | 3 | 67% | 1.00× |
| cramped | 7 | 86% | 1.20× |
| parlor | 4 | 100% | 1.07× |
| membrane | 21 | 86% | 1.23× |
| venturi | 10 | 70% | 1.09× |
| mobius | 3 | 100% | 1.05× |
| blackice | 3 | 100% | 1.15× |
| local | 48 | 92% | 1.22× |
| drift | 7 | 100% | 1.27× |
| spring_st | 11 | 100% | 1.34× |
| posts | 4 | 100% | 1.21× |
| erbridge | 8 | 88% | 1.47× |
| benzene | 7 | 100% | 1.27× |
| maxwell | 4 | 100% | 1.63× |
| whisper | 3 | 100% | 1.81× |

## Catalyst activity

Includes cue kit uses. A zero use count does not show that a tool is weak unless the bot owned and considered it often.

| Catalyst ID | Bought | Uses |
|---|---:|---:|
| focal | 3 | 24 |
| goldenratio | 6 | 23 |
| ghostchalk | 7 | 20 |
| reflection | 8 | 13 |
| nudge | 7 | 12 |
| tidal | 9 | 12 |
| newton | 10 | 10 |
| blast | 9 | 9 |
| secondstrike | 3 | 9 |
| swap | 4 | 8 |
| leadweight | 10 | 7 |
| momentum | 3 | 7 |
| gravitypebble | 1 | 6 |
| hookes | 8 | 6 |
| portal | 4 | 6 |
| post | 4 | 6 |
| trapdoor | 1 | 6 |
| centremass | 6 | 5 |
| pocketcover | 3 | 4 |
| damping | 4 | 3 |
| englishdial | 4 | 3 |
| blink | 7 | 2 |
| darkenergy | 6 | 2 |
| polish | 15 | 2 |
| rewind | 1 | 2 |
| spotter | 2 | 2 |
| wall | 4 | 2 |
| freezeframe | 5 | 1 |
| absolutezero | 6 | 0 |
| pythagoras | 2 | 0 |
