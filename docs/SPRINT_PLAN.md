# Sprint plan: November 2026

Order agreed with Jordan: publish first, then **2 → 3 → 1 → 5 → 4**, then commit and release.
Every new Perk, item, ball type and Imbue gets its own icon now. Card art comes later.

## 0. Publish (done first)

- Public GitHub repo with a full README, and releases carrying the APK and the Windows zip.
- `tools/release.sh "notes"` bumps the version, runs every check, builds both, pushes and publishes, so a phone can update from the Releases page.
- Commits use a GitHub no-reply address, not a work email.

## 2. Perks to 100, and usable items

Perks are 76 now and go to **100**. The game is a roguelike, so breadth matters more than tight builds.

| Group | Now | Adds | After |
| --- | --- | --- | --- |
| Physics | 2 | Heavy Hitter, Live Rails, Slow Cloth, Backspin Wax, Big Break, Long Arm | 8 |
| Cue control | 7 | Masse Master, Follow Through, Draw Artist, Dead Centre | 11 |
| Clearing (new) | 0 | Thin Rack, Short Rack, Missing Piece, Clean House | 4 |
| Gear (new) | 0 | Pack Rat, Quartermaster, Tinkerer | 3 |
| Ball types (new) | 0 | Gold Rush, Menagerie, Alchemy | 3 |
| Imbues | 0 | Enchanter, Second Coat | 2 |
| Others | 67 | Two more across the existing families | 69 |

**Usable items** are a new shop category. You hold up to 3 and use one while aiming, on the current table:
Hand Chalk, Portal Pair, Bumper Kit, Ball in Hand, Fresh Rack, Double Down, Heat Pack, Magnet Charm, Wide Open and Rewind.
Portals and bumpers stay on that table, and the prediction line follows them exactly.

**More cues:** five more starting cues (10 → 15), each built around one of the new systems.

## 3. Your ball set: removal, new ball types, more Imbues

- A run now owns a **ball set**, starting with 1–15. The rack holds up to 21 (six rows), with the 8 always in the middle.
- **Removal:** a shop service that takes one ball out of your set for the run. Never the 8, never the cue ball.
- **24 new ball types** you can add to the set, each with its own look (finish, pattern and emblem): Gold, Void, Glass, Iron, Feather, Ember, Frost, Magnet, Prism, Wild, Clock, Coin, Bomb, Seed, Clover, Star, Heart, Dice, Moon, Sun, Anchor, Eraser, Echo and Comet.
- **Imbues** grow from 8 to 16.

## 1. Easier runs

Make runs easier: lower targets, gentler Chalk, more money early. The goal is for strong simulated players to win often and average players to reach the late tables. The simulated players will also learn the new items so the numbers stay honest.

## 5. Sound

Replace the synthesised clicks with layered, physically shaped sounds: ball-on-ball clicks by speed, cushion thuds, pocket drops and rattles, the cue tip and ball rolling. All made in code, so there are no licensing questions.

## 4. Phone pass

Bigger Perk card text and tap targets, a check that tapping a word opens its popup reliably, and a speed check of the all-balls preview on the Android emulator.
