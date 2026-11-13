# Balance review

Every number in Pocket Science that a balance pass might change, read from the game's data on 2026-11-13.

**How to use it:** write in the **Your note** column on any row, for example "cost 6 → 5", "too strong" or "cut". Leave the rest blank. Whoever makes the change ticks **Done** and notes what changed.

Regenerate it with `godot --headless --path . --script res://tools/balance_doc.gd`. That overwrites notes, so copy them first.

## Core rules

The numbers every run uses.

| Rule | Now | Where | Your note | Done |
|---|---|---|---|---|
| Chalk at the start of a run | 6 | `RunState.BASE_CHALK` |  |  |
| Most Chalk you can hold | 12 | `RunState.MAX_CHALK` |  |  |
| Chalk back for clearing a table | 1 | `RunState.advance_table` |  |  |
| Chalk back for clearing a rack | 1 | `RunState.apply_shot` |  |  |
| Chalk cost: a miss or no contact | 1 | `RunState.apply_shot` |  |  |
| Chalk cost: a scratch, or the 8 going in early | 2 | `RunState.apply_shot` |  |  |
| Points lost for an early 8 | 15% of the table's target | `Catalog.EIGHT_PENALTY` |  |  |
| Heat multiplier | ×(1 + 0.5 × Heat) | `Scorer.HEAT_STEP` |  |  |
| Chain added by each ball that sinks | +0.5 | `Scorer.AFTER_POT` |  |  |
| Ball value | 10 + 2 × its number | `Catalog.NUMBER_WEIGHT` |  |  |
| Balls at the start of a run | 1 to 10 | `RunState.START_BALLS` |  |  |
| Most balls in your rack | 15 | `RunState.MAX_SET` |  |  |
| Element slots | 6 | `RunState.MAX_PERKS` |  |  |
| Catalyst slots | 5 | `RunState.TOOL_SLOTS` |  |  |
| Uses of an object cue's object, each table | 4 | `RunState.CUE_KIT_USES` |  |  |

## Money

What you earn and what the shop's services cost.

| Rule | Now | Where | Your note | Done |
|---|---|---|---|---|
| Clearing a table | $4 | `RunState.payout` |  |  |
| Overkill: per 10% over the target | $1, up to $10 | `RunState.OVERKILL_MAX` |  |  |
| Quick clear: per shot under 10 | $1, up to $5 | `RunState.PAR_SHOTS`, `QUICK_MAX` |  |  |
| Reroll Elements | $2, then $1 more each reroll | `RunState.reroll_cost` |  |  |
| Remove a ball | $3, then $1 more each removal | `RunState.removal_cost` |  |  |
| Selling an Element | Half its cost (at least $1) | `RunState.sell_value` |  |  |

## The nine tables

Endless tables after the ninth raise the target ×1.6 each.

| Table | Target | Board | Side bet stake | Your note | Done |
|---|---|---|---|---|---|
| 1 | 50 | The Local | $4 |  |  |
| 2 | 120 | Any tier 1 board | $4 |  |  |
| 3 | 215 | Any tier 1 board | $8 |  |  |
| 4 | 270 | Any tier 2 board | $8 |  |  |
| 5 | 390 | The Clockwork Table | $12 |  |  |
| 6 | 510 | Any tier 2 board | $12 |  |  |
| 7 | 650 | Any tier 3 board | $16 |  |  |
| 8 | 840 | Any tier 3 board | $16 |  |  |
| 9 | 1060 | Apex Predator | $20 |  |  |

## Handicaps

Each level includes every rule before it.

| Level | Name | Rule | Your note | Done |
|---|---|---|---|---|
| 0 | Scratch Player | The game as designed. |  |  |
| 1 | Worn Cloth | Table targets are 15% higher. |  |  |
| 2 | Short Chalk | Start with 1 less Chalk. |  |  |
| 3 | Dear Prices | Everything in the Pro Shop costs $1 more. |  |  |
| 4 | Narrow Jaws | Pockets are 5% narrower. |  |  |
| 5 | Hall of Fame | Table targets are 30% higher again. |  |  |

## Boards

Tier 0 is the first table, tier 9 the fixed boss tables.

| Board | Id | Tier | Physics | Rule | Your note | Done |
|---|---|---|---|---|---|---|
| The Hypotenuse | `hypotenuse` | 1 | standard | A right-angled triangle: three corner pockets and one in the middle of each side. Every bank is a new angle. |  |  |
| Benzene Ring | `benzene` | 1 | standard | A hexagon with a pocket in every corner. Six angled rails to bank off. |  |  |
| Golden Pentagon | `pentagon` | 2 | standard | A pentagon in golden-ratio proportions: five corner pockets and one in the long bottom rail. |  |  |
| The L-Shell | `lshell` | 2 | standard | An L-shaped table. The inside corner turns every bank into a new puzzle. |  |  |
| The Local | `local` | 0 | standard | Your home table. The house forgives your first miss. |  |  |
| Capacitor | `spring_st` | 1 | spring | Lively rails. A ball off the top rail charges the bottom one, and the next ball off the charged rail flies off faster. On this table, bank sinks score ×2. |  |  |
| Coriolis | `drift` | 1 | standard | A turntable spins in the middle and curves every ball that rolls across it. Every sink adds +1 Chain. |  |  |
| Faraday Cage | `cramped` | 1 | standard | A Card Sharp sits in a corner pocket, guarded by two posts, and blocks it. Hit it twice to knock it out and open the pocket. Every sink scores ×1.5. |  |  |
| Pinball Parlor | `parlor` | 2 | pinball | Four bumpers. On this table, every bumper hit adds +1 Chain. |  |  |
| Harmonic Oscillator | `posts` | 2 | cyclotron | Two posts on springs slide back and forth, one step after every shot. Every post hit adds +1 Chain. |  |  |
| Event Horizon | `sinkhole` | 2 | gravity | A gravity well in the centre pulls moving balls in. Chain starts at 2. |  |  |
| Kepler Orbit | `magnet` | 2 | magnetlab | Every pocket pulls passing balls into orbit and then in, but every ball is worth 10 less. |  |  |
| Lotka–Volterra | `smoke` | 2 | standard | A Pool Shark circles the balls and swallows one every 3 shots. If it survives 4 shots, a second one arrives. Hit a Shark 3 times to knock it out. Every sink scores ×1.5. |  |  |
| Superfluid | `blackice` | 3 | cryo | Almost no friction and lively cushions. Every sink adds +0.5 Chain. |  |  |
| Snell's Law | `tilted` | 3 | standard | The table slopes and bends every ball's path, and a dotted line shows where balls will really roll. Every sink scores ×1.5. |  |  |
| Quantum Pockets | `two` | 3 | spring | Only the hot pocket and its entangled twin, diagonally opposite, score, and sinks there score ×2. |  |  |
| Radioactive Decay | `closing` | 3 | standard | The pockets decay: every pocket narrows after each shot. Heat builds twice as fast. |  |  |
| Gulf Stream | `gulf` | 2 | standard | A current runs across the middle of the table and carries rolling balls to the right. Every sink adds +0.5 Chain. |  |  |
| Foucault's Pendulum | `foucault` | 3 | standard | A heavy bob swings across the middle, and its swing turns a little every shot. A Hammerhead charges across the table between shots. Hitting the bob adds +1 Chain; knock the Hammerhead out with 3 hits. |  |  |
| Venturi | `venturi` | 1 | standard | Two angled rails squeeze the middle into a narrow throat, and a ball rushed through it comes out faster. Long sinks score ×2. |  |  |
| Einstein–Rosen Bridge | `erbridge` | 1 | standard | Two linked portals: a ball rolling into one comes out of the other at the same speed. Every portal trip adds +1 Chain. |  |  |
| Semipermeable Membrane | `membrane` | 1 | standard | A membrane across the table lets balls through left to right only; from the right it bounces them back. Every sink scores ×1.5. |  |  |
| Galton Board | `galton` | 1 | standard | Rows of pegs, set like a bean machine, scatter balls as they pass. Every peg hit adds +0.5 Chain. |  |  |
| Parabolic Mirror | `parabolic` | 2 | standard | The right end is a parabola: a ball rolling straight at it bounces to the focus, where a pocket sits. Sinks in the focus pocket score ×2. |  |  |
| Whispering Gallery | `whisper` | 2 | standard | An elliptical table. A ball sent through one focus always rolls to the other, where a pocket sits. Sinks in the focus pocket score ×3. |  |  |
| Sierpinski Triangle | `sierpinski` | 2 | standard | A triangular table with three triangular islands to bank around. Bank sinks score ×2. |  |  |
| Möbius Strip | `mobius` | 2 | standard | Gaps in the left rail lead out of gaps in the right rail, upside down. Every trip through adds +1 Chain. |  |  |
| Maxwell's Demon | `maxwell` | 2 | standard | A wall splits the table. At its gate the Demon lets fast balls through left to right and slow balls back right to left. Every sink scores ×1.5. |  |  |
| Lorentz Field | `lorentz` | 2 | standard | Inside the marked field, rolling balls curve sideways; fast balls curve less. Every sink adds +0.5 Chain. |  |  |
| Golden Spiral | `spiral` | 2 | standard | A spiral rail winds into a drain on the cloth; a ball caught on the arm rides it in. Sinks in the drain score ×2. |  |  |
| Meissner Effect | `meissner` | 2 | standard | Four superconducting posts push balls away before they touch, so balls curve round them. Clean sinks score ×2. |  |  |
| Chain Reaction | `chain` | 3 | standard | Every sink sends a shock ring out of its pocket that shoves nearby balls away. Set off chains. Every sink adds +0.5 Chain. |  |  |
| Tesla Coil | `tesla` | 3 | standard | Every third shot the coil fires and pushes every ball outwards; the aiming line shows the pulse. Sinks on a coil shot score ×2. |  |  |
| Tectonic Plates | `tectonic` | 3 | standard | Two fault ridges slide past each other one step after every shot. Bank sinks score ×1.5. |  |  |
| Crystal Lattice | `lattice` | 3 | standard | A rhombus table with a grid of small posts, like atoms in a crystal. Every post hit adds +0.25 Chain. |  |  |
| Stellated Star | `stellated` | 3 | standard | A six-pointed star with a pocket at every point. The inner corners make wild banks. Bank sinks score ×2. |  |  |
| The Lever | `lever` | 3 | standard | A see-saw rail on a fulcrum tips towards whichever end a ball hit last shot. Every sink scores ×1.5. |  |  |
| Escape Velocity | `escape` | 3 | standard | Two gravity wells slingshot balls round them; get the speed right to escape or orbit in. Every sink adds +1 Chain. |  |  |
| The Clockwork Table | `elements` | 9 | element | The pockets are numbered 1 to 6, clockwise. Sink into the next one in order to tick the clock: ticks in a row score ×1.5, ×2, ×2.5 and on. Any other pocket stops the clock. A Sweeper wall turns one hour round the middle after every shot. |  |  |
| Apex Predator | `final` | 9 | final | The Great White swallows a ball every 2 shots; hit it 8 times to knock it out. At half health the Loan Shark (takes 15% of every sink) and the Leech (clamps onto a ball) join. The 8 goes last: early costs 2 Chalk, last scores ×5. |  |  |

## Elements

All 100, by atomic number. Rarity sets how often a card is offered.

| Z | Element | Id | Rarity | Cost | Family | What it does | Your note | Done |
|---|---|---|---|---|---|---|---|---|
| 1 | Hydrogen Balloon | `featherweight` | Rare | $8 | Physics | The cue ball floats: if it would drop into a pocket, it bobs back out instead. No more pocket scratches. |  |  |
| 2 | Helium Fusion | `fusion` | Uncommon | $6 | Combos & clusters | Sink a ball into the same pocket as your last sink (this shot or your last one) and it scores ×2. |  |  |
| 3 | Lithium Cell | `lowball` | Common | $4 | Solids | Your 3 lowest-value balls are charged: they lose no speed off cushions, and each pays $1 when it sinks. |  |  |
| 4 | Beryllium Avalanche | `catalyst` | Rare | $8 | Risk & scaling | Every ball you sink gives 2 random balls in your rack +4 for the rest of the run. |  |  |
| 5 | Boron Cluster | `multi` | Uncommon | $6 | Combos & clusters | Every ball after the first in a shot adds +1 Chain as it sinks. |  |  |
| 6 | Carbon Core | `eight` | Uncommon | $6 | The 8-ball | The 8 stops costing you points, scores like any other ball, and pays $3. |  |  |
| 7 | Nitrogen Tyres | `liverails` | Common | $5 | Physics | The cue ball comes off every cushion 15% faster than it hit it. |  |  |
| 8 | Oxygen Octet | `darkhorse` | Rare | $9 | The 8-ball | The 8 scores ×8 when it sinks. You still lose points if it sinks early. |  |  |
| 9 | Fluorine Flare | `odd` | Common | $4 | Ball numbers | Odd-numbered balls are worth +2× their number (the 1 gets +2, the 9 gets +18). |  |  |
| 10 | Neon Sign | `steerclear` | Common | $5 | The 8-ball | If no ball touches the 8 during a shot, each sink adds +0.5 Chain. |  |  |
| 11 | Sodium Cushion | `cushion` | Common | $4 | Banks & cushions | Bank sinks are worth +30. |  |  |
| 12 | Magnesium Torch | `heat` | Uncommon | $6 | Pockets | The hot pocket scores ×3 instead of ×2. |  |  |
| 13 | Aluminium Ore | `bedrock` | Uncommon | $8 | Solids | Shots that sink only solids add +1 Heat for each solid sunk. |  |  |
| 14 | Silicon Wafer | `solids` | Common | $5 | Solids | Solid balls are worth +3× their number (the 1 gets +3, the 7 gets +21). |  |  |
| 15 | Phosphorus Match | `streak` | Uncommon | $7 | Streaks | Shots that sink 2+ balls add +1 extra Heat. |  |  |
| 16 | Sulfur Reagent | `chain` | Uncommon | $7 | Gear | On a shot where you used a Catalyst, every sink is worth +10, and clearing the table on that shot pays $1 per table number. |  |  |
| 17 | Chlorine Clean | `precision` | Uncommon | $6 | Cue control | Clean sinks (straight from the cue ball, no cushions) add +1 Chain. |  |  |
| 18 | Argon Shield | `insurance` | Rare | $7 | Utility | The first 2 misses or scratches on each table cost no Chalk. |  |  |
| 19 | Potassium Kick | `kick` | Uncommon | $6 | Cue control | Once per table: the first kick shot (cue hits a cushion first) that sinks scores ×2 on every sink. |  |  |
| 20 | Calcium Chalk | `chalk` | Common | $5 | Utility | Clearing a table gives +1 extra Chalk. |  |  |
| 21 | Scandium Hustle | `hunter` | Common | $4 | Economy | Side bets you win pay double. |  |  |
| 22 | Titanium Jaws | `jaws` | Common | $6 | Pockets | Pockets are 20% wider. |  |  |
| 23 | Vanadium Velvet | `velvet` | Common | $5 | Physics | 30% less cloth friction: balls roll further. |  |  |
| 24 | Chromium Stripes | `stripes` | Common | $5 | Stripes | Striped balls score ×1.5. |  |  |
| 25 | Manganese Swerve | `masse` | Uncommon | $6 | Cue control | Side spin bends the cue ball twice as much off cushions. |  |  |
| 26 | Iron Fist | `golden` | Rare | $8 | Risk & scaling | Once per table: your first sink scores ×3. |  |  |
| 27 | Cobalt Glaze | `secondcoat` | Uncommon | $7 | Isotopes | Isotope balls score ×1.5. |  |  |
| 28 | Nickel Supernova | `supernova` | Rare | $9 | Combos & clusters | Shots that sink 3 or more balls score ×2 on every sink. |  |  |
| 29 | Copper Penny | `gold` | Uncommon | $7 | Economy | Each sink pays $1 (max $3 per shot). |  |  |
| 30 | Zinc Coupon | `quartermaster` | Common | $4 | Gear | Catalysts cost $2 less. |  |  |
| 31 | Gallium Glide | `collector` | Uncommon | $6 | Cue control | The cue ball rolls 50% further on the cloth. |  |  |
| 32 | Germanium Angles | `geometry` | Rare | $8 | Banks & cushions | Once per table: your first bank sink scores ×1.5 for every cushion it touched (×2.25 off two). |  |  |
| 33 | Arsenic Mutation | `alchemy` | Rare | $8 | Exotic balls | After each table, one plain ball in your rack (never the 8) turns into a random Exotic ball. |  |  |
| 34 | Selenium Lens | `lens` | Common | $4 | Utility | A sink where the sunk ball rolled at least 1.1 m (almost half the table) adds +1 Chain. |  |  |
| 35 | Bromine Boomerang | `boomerang` | Uncommon | $6 | Cue control | If the cue ball stops within 30 cm of where you struck it, every sink scores ×2. |  |  |
| 36 | Krypton Tally | `eightcount` | Uncommon | $6 | The 8-ball | Every 8th ball you sink in a run scores ×3. |  |  |
| 37 | Rubidium Rocket | `racing` | Uncommon | $6 | Stripes | Stripes are 30% lighter and roll 25% further. |  |  |
| 38 | Strontium Firework | `side` | Common | $5 | Pockets | Side pockets score ×2, and the hot pocket is never a side pocket. |  |  |
| 39 | Yttrium Ladder | `steadyrun` | Uncommon | $6 | Solids | Each solid sunk in a row makes solids worth +12 more (max +96). A stripe, or a new table, resets it. |  |  |
| 40 | Zirconium Gem | `stripesonly` | Rare | $9 | Stripes | Stripes score ×2, but solids score ×0.5. |  |  |
| 41 | Niobium Menagerie | `menagerie` | Uncommon | $6 | Exotic balls | Shots start with +0.25 Chain for each Exotic ball in your rack. |  |  |
| 42 | Molybdenum Shaft | `longarm` | Uncommon | $6 | Physics | Full power hits 30% harder. |  |  |
| 43 | Technetium Gap | `missing` | Uncommon | $7 | Clearing your rack | Shots start with +0.5 Chain for each ball you have removed from your rack (max +3). |  |  |
| 44 | Ruthenium Nugget | `goldrush` | Uncommon | $6 | Exotic balls | Exotic balls score ×1.5. |  |  |
| 45 | Rhodium Rhythm | `rhythm` | Common | $5 | Streaks | Every third shot on a table scores ×2. |  |  |
| 46 | Palladium Vault | `venture` | Uncommon | $6 | Economy | Shots start with +0.25 Chain for every $5 you hold (max +1.5). |  |  |
| 47 | Silver Tongue | `hushmoney` | Common | $4 | Economy | Sinking the 8 early pays you $3 and costs no points. It is still a foul. |  |  |
| 48 | Cadmium Chill | `coupon` | Common | $4 | Heat | At Heat 0, every sink scores ×2. |  |  |
| 49 | Indium Touch | `finesse` | Uncommon | $6 | Cue control | Shots at 35% power or less score ×2. |  |  |
| 50 | Tin Toolbox | `tinkerer` | Uncommon | $6 | Gear | Every table, a random Catalyst you hold gets one extra use. |  |  |
| 51 | Antimony Kohl | `kissblack` | Uncommon | $6 | The 8-ball | If the cue ball hits the 8 first (not on the break) and the shot sinks a ball, every sink scores ×2. |  |  |
| 52 | Tellurium Supply | `oracle` | Rare | $10 | Gear | At the start of each table, get a random Catalyst for that table only, if you have a free Catalyst slot. |  |  |
| 53 | Iodine Swab | `cleanhouse` | Common | $3 | Clearing your rack | Removing a ball in the Pro Shop is free. |  |  |
| 54 | Xenon Flash | `stillness` | Uncommon | $6 | Pausing | Once a table, the first time you pause a shot, every rolling ball speeds up by 30%. |  |  |
| 55 | Caesium Clock | `overclock` | Rare | $8 | Pausing | Your Catalysts get two uses on every table. |  |  |
| 56 | Barium Spin | `backspin` | Uncommon | $6 | Physics | Draw and follow are twice as strong. |  |  |
| 57 | Lanthanum Lantern | `comeback` | Uncommon | $6 | Streaks | On your last Chalk, every sink scores ×2. |  |  |
| 58 | Cerium Flint | `thrift` | Common | $4 | Economy | Clear a table with 3+ Chalk left: +$5. |  |  |
| 59 | Praseodymium Twin | `rotation` | Uncommon | $6 | Ball numbers | The lowest-numbered ball on the table scores as if it were the highest-numbered one. |  |  |
| 60 | Neodymium Boulder | `elastic` | Uncommon | $6 | Physics | The cue ball is 90% bigger, just small enough to fit a pocket, and twice as heavy. |  |  |
| 61 | Promethium Prime | `prime` | Uncommon | $6 | Ball numbers | Prime balls (2, 3, 5, 7, 11, 13 and up) score ×2. When no prime ball is left on the table, the next prime ball rolls on and joins your rack for good. |  |  |
| 62 | Samarium Simmer | `entropy` | Uncommon | $6 | Heat | Below Heat 3, shots start with +1 Chain. |  |  |
| 63 | Europium Echo | `echo` | Rare | $9 | Isotopes | When a ball with an Isotope sinks, its Isotope echoes onto a random ball on the table that has none, until the table ends. |  |  |
| 64 | Gadolinium Pull | `magnet` | Rare | $9 | Pockets | Pockets gently pull nearby moving balls in. |  |  |
| 65 | Terbium Tiger | `tiger` | Uncommon | $7 | Stripes | Each stripe sunk in a row on this table adds +0.25 Chain to the next (max +2). A solid resets it. |  |  |
| 66 | Dysprosium Domino | `domino` | Uncommon | $6 | Physics | Balls lose no speed when they hit each other, so a hit passes its full speed down a line of balls. |  |  |
| 67 | Holmium Magnet | `hothand` | Uncommon | $6 | Heat | At Heat 3 or more, pockets pull nearby rolling balls in. |  |  |
| 68 | Erbium Laser | `even` | Common | $4 | Ball numbers | Even-numbered balls add +0.75 Chain as they sink. |  |  |
| 69 | Thulium Thinning | `thinrack` | Uncommon | $6 | Clearing your rack | Every ball removed from your rack makes all balls worth +1. |  |  |
| 70 | Ytterbium Twin | `drawartist` | Uncommon | $6 | Cue control | After your first shot on each table, a second cue ball appears. Click a cue ball to choose which one you shoot. |  |  |
| 71 | Lutetium Luck | `luckystripe` | Uncommon | $6 | Stripes | Each stripe you sink has a 1 in 3 chance to score ×3 and pay $2. |  |  |
| 72 | Hafnium Rod | `migration` | Uncommon | $6 | Heat | While Heat is 4 or more, a miss only costs 1 Heat instead of half. |  |  |
| 73 | Tantalum Plate | `solidsonly` | Rare | $9 | Solids | Solids score ×3, but stripes score ×0.5. |  |  |
| 74 | Tungsten Core | `lever` | Common | $5 | Stripes | Stripes weigh 140% and lose no speed off cushions: they plough on through other balls. |  |  |
| 75 | Rhenium Ricochet | `ricochet` | Uncommon | $6 | Banks & cushions | Every cushion a ball touches adds +0.25 extra Chain. |  |  |
| 76 | Osmium Cue | `heavyhit` | Uncommon | $6 | Physics | The cue ball is 30% heavier, so it drives balls further. |  |  |
| 77 | Iridium Flame | `minimalist` | Rare | $8 | Heat | While On fire (Heat 5+), every sink scores ×2. |  |  |
| 78 | Platinum Rail | `bank` | Uncommon | $6 | Banks & cushions | Bank sinks add +1 Chain per cushion. |  |  |
| 79 | Gold Bar | `solidgold` | Uncommon | $6 | Solids | Each solid you sink pays $1. |  |  |
| 80 | Mercury Messenger | `quickhands` | Common | $4 | Pausing | The first Catalyst you use on each table doesn't spend a use. |  |  |
| 81 | Thallium Felt | `slowcloth` | Common | $4 | Physics | Thick nap: the cue ball stops 35% sooner for tight position, while object balls roll 25% further. |  |  |
| 82 | Lead Anchor | `laststripe` | Uncommon | $6 | The 8-ball | The 8 weighs 300%, and it rattles out of the pockets until it is the last ball: no more early 8s. |  |  |
| 83 | Bismuth Crystal | `lastsolid` | Rare | $8 | Solids | When you sink the only solid left on the table, it scores ×8. |  |  |
| 84 | Polonium Halo | `lastcall` | Uncommon | $6 | The 8-ball | If the 8 is the only ball left, the pockets pull it in, and sinking it scores ×5 and pays $5. |  |  |
| 85 | Astatine Edge | `glasscannon` | Rare | $8 | Risk & scaling | Every sink scores ×2, but every miss and foul costs 1 more Chalk. |  |  |
| 86 | Radon Burst | `bigbreak` | Common | $5 | Physics | Break shots hit 25% harder. |  |  |
| 87 | Francium Fizz | `followthru` | Uncommon | $6 | Risk & scaling | Scratch while sinking 2 or more balls and the shot still scores, with no Chalk lost. |  |  |
| 88 | Radium Trail | `tracer` | Common | $4 | Banks & cushions | Every cushion the cue ball touches after contact adds +0.25 Chain. |  |  |
| 89 | Actinium Ray | `highball` | Common | $4 | Stripes | Balls 13, 14 and 15 score ×2.5. |  |  |
| 90 | Thorium Stopper | `stun` | Uncommon | $6 | Cue control | The cue ball loses 60% of its speed when it first hits a ball. Far fewer scratches. |  |  |
| 91 | Protactinium Pack | `packrat` | Common | $4 | Gear | +3 Catalyst slots. |  |  |
| 92 | Uranium Reactor | `power` | Uncommon | $5 | Cue control | At 85%+ power, the first ball the cue ball hits flies off 20% faster: a chain reaction. |  |  |
| 93 | Neptunium Tide | `overflow` | Uncommon | $5 | Utility | Points you score over a table's target carry into the next table's score (up to 25% of the next target). |  |  |
| 94 | Plutonium Pit | `trouble` | Rare | $7 | The 8-ball | When the 8 sinks early, gain +3 Heat. You still lose the points. |  |  |
| 95 | Americium Beacon | `afterimage` | Uncommon | $6 | Gear | The first Catalyst you use on each table also gives that shot +2 Chain and +1 Heat. |  |  |
| 96 | Curium Corner | `corner` | Common | $4 | Pockets | Corner pockets add +0.5 Chain as the ball sinks. |  |  |
| 97 | Berkelium Break | `afterburner` | Common | $5 | Cue control | Place the cue ball anywhere on the table for the break. |  |  |
| 98 | Californium Jackpot | `moneyball` | Uncommon | $6 | Ball numbers | Every ball's number counts ×3 instead of ×2. |  |  |
| 99 | Einsteinium Lab | `enchanter` | Common | $4 | Isotopes | Isotopes cost $2 less. |  |  |
| 100 | Fermium Spiral | `fibonacci` | Uncommon | $6 | Ball numbers | Sink every Fibonacci ball in your rack (1, 2, 3, 5, 8, then 13 and up) this run and the next Fibonacci ball joins your rack for good; then start again. |  |  |

## Isotopes

| Isotope | Id | Cost | What it does | Your note | Done |
|---|---|---|---|---|---|
| Spark | `spark` | $4 | +1 Chain every time it is struck. Struck 3 or more times in one shot, it overloads and arcs onto the last ball it hit. |  |  |
| Gilded | `gold` | $4 | Pays $1 when sunk, plus $1 for every table in a row you have sunk it (up to $5). A table where it stays up resets the streak. |  |  |
| Weighted | `heavy` | $3 | Worth 10 + 3 × its number, and the number counts one more time with every sink (×4, ×5...). Any miss drops it back to ×3. |  |  |
| Hairline | `glass` | $5 | Scores ×3 when sunk, but the coating may crack off: 1 in 4 the first time, 2 in 4 the next, then 3 in 4. |  |  |
| Kindled | `ember` | $5 | +2 Heat when sunk. But while it is still on the table, a miss wipes your Heat to 0 instead of halving it. |  |  |
| Vein | `vein` | $5 | Worth +20 when sunk, and it spreads onto the ball that knocked it in (if that ball has no Isotope). |  |  |
| Lucky | `lucky` | $4 | 1 in 2 chance to score ×2 when sunk. If it misses, Lucky jumps to another ball with no Isotope and the next win scores ×3, then ×4, and so on. |  |  |
| Volatile | `volatile` | $4 | The first time anything hits this ball it explodes: it counts as sunk (points and Heat), but it leaves your rack for good. |  |  |
| Jinxed | `jinxed` | $3 | Scores ×4 when sunk, but sinking it halves your Heat. |  |  |
| Mirror | `mirror` | $4 | Scores what the ball that hit it is worth instead of its own value: a low ball struck by the 15 scores like the 15. |  |  |
| Pawned | `pawned` | $2 | Pays $4 when sunk instead of any points. |  |  |
| Frosted | `frosted` | $4 | When it sinks, your next miss on this table keeps your Heat. |  |  |
| Magnetic | `magnetic` | $5 | Pockets pull this ball in. |  |  |
| Charged | `charged` | $4 | +0.5 Chain every time this ball touches a cushion. |  |  |
| Resonant | `prismatic` | $4 | Every ball it touches in a shot adds +0.25 Chain. |  |  |
| Hollow | `hollow` | $3 | 50% weight: it flies further when struck. |  |  |
| Leaded | `leaded` | $4 | 200% weight, and worth +45. |  |  |
| Bounty | `bounty` | $4 | Pays $1 for every point of Heat when it sinks, then cashes out 2 Heat. |  |  |
| Starry | `starry` | $5 | Every ball after it in the same shot gets +0.5 Chain. |  |  |
| Twin | `twin` | $4 | Its value counts twice. Then it hops to its colour twin (the 3 and the 11, the 1 and the 9...), if that one is free. |  |  |
| Recurring | `recurring` | $5 | Every time it sinks it is worth +4 more for the rest of the run, and it comes straight back: it takes the place of a random other ball on the table, which leaves unscored. |  |  |
| Slick | `slick` | $3 | Rolls 65% further on the cloth, and is worth +10. |  |  |
| Rubber | `rubber` | $4 | Loses no speed off cushions, and is worth +5 for every cushion it touched before it sank. |  |  |
| Tithed | `tithed` | $4 | When it sinks, pays $1 for every other ball still on the table (up to $5). |  |  |
| Catalytic | `catalytic` | $5 | When it sinks, one Catalyst you have used this table recharges. |  |  |
| Chalked | `chalked` | $6 | The first time it sinks on a table, +1 Chalk. |  |  |
| Excited | `excited` | $3 | If the cue ball hits it first and it sinks, +1 Heat. |  |  |
| Radiant | `radiant` | $5 | While it is on the table at the start of a shot, every other ball that sinks is worth +5. |  |  |
| Polarized | `polarized` | $3 | Scores ×3 in the hot pocket, but only ×0.5 anywhere else. |  |  |
| Isolated | `isolated` | $4 | Scores ×2.5 if it is the last solid (or the last stripe) on the table when it sinks. |  |  |

## Catalysts

Each recharges every table.

| Catalyst | Id | When | Cost | What it does | Your note | Done |
|---|---|---|---|---|---|---|
| Impulse | `secondstrike` | While paused | $7 | While a shot is paused, hit the cue ball again. |  |  |
| Superposition | `blink` | While paused | $6 | While a shot is paused, move the cue ball anywhere. It keeps its speed and direction. |  |  |
| Quantum Tunnel | `ghostchalk` | Aiming or paused | $5 | Pick a ball: this shot it passes straight through other balls. |  |  |
| Inertia | `freezeframe` | While paused | $5 | Stop a ball dead. It holds still like a post for the rest of the shot. |  |  |
| Zero Friction | `polish` | Aiming or paused | $5 | Pick a ball: it glides with no cloth friction until it first hits something. |  |  |
| Gravity Well | `gravitypebble` | While paused | $6 | Place a small well that bends rolling balls for the rest of the shot. |  |  |
| Wormhole | `portal` | Aiming or paused | $7 | Place two linked portals for this table. A ball rolling into one comes out of the other at the same speed. |  |  |
| Force Field | `wall` | While paused | $5 | Raise a short wall for the rest of the shot. |  |  |
| Fixed Point | `post` | Aiming or paused | $5 | Place a post anywhere for the rest of this table. |  |  |
| Spin Transfer | `englishdial` | While paused | $5 | Put the spin you have set onto the rolling cue ball. |  |  |
| Entanglement | `swap` | Aiming or paused | $6 | Two balls swap places, each keeping its own motion. |  |  |
| Vector | `nudge` | While paused | $5 | Push a rolling ball a short way in any direction. |  |  |
| Mass Shift | `leadweight` | Aiming or paused | $5 | Pick a ball: it weighs 400% for the rest of the shot. |  |  |
| Event Horizon | `pocketcover` | Aiming or paused | $6 | Pick a pocket: it swallows from twice as wide for the rest of the shot. |  |  |
| Black Hole | `trapdoor` | Aiming or paused | $6 | Open a pocket anywhere along a cushion for the rest of the shot. |  |  |
| Time Reversal | `rewind` | While paused | $9 | Undo this shot while it rolls, and take it again. |  |  |
| Conservation | `spotter` | Aiming or paused | $5 | Bring a ball you sank on this table back to the foot spot. Never the 8. |  |  |
| Pythagorean Triple | `pythagoras` | Aiming or paused | $7 | Pick three balls: force-field walls join them into a triangle for the rest of the shot. |  |  |
| Newton's Cradle | `newton` | While paused | $6 | Pick a ball: the cue ball stops dead and that ball takes all its momentum. |  |  |
| Reflection | `reflection` | While paused | $5 | Pick a rolling ball: it turns round and heads straight back. |  |  |
| Golden Ratio | `goldenratio` | While paused | $5 | Pick a rolling ball: its speed is multiplied by 1.618. |  |  |
| Centre of Mass | `centremass` | While paused | $6 | Pick two to four balls: they all head for the point between them. |  |  |
| Hooke's Law | `hookes` | Aiming or paused | $5 | Pick a cushion: for the rest of the shot, anything bouncing off it keeps all its speed. |  |  |
| Damping | `damping` | While paused | $4 | Pick a rolling ball: it slows to half its speed. |  |  |
| Momentum Exchange | `momentum` | While paused | $6 | Pick a ball: it and the cue ball swap speeds and directions. |  |  |
| Dark Energy | `darkenergy` | While paused | $5 | Place a point that pushes rolling balls away for the rest of the shot. |  |  |
| Supernova | `blast` | While paused | $6 | Place a blast: every ball near it is flung outwards. |  |  |
| Absolute Zero | `absolutezero` | While paused | $5 | Every ball on the table stops dead, right where it is. |  |  |
| Focal Point | `focal` | Aiming or paused | $5 | Pick a pocket: it becomes the hot pocket. |  |  |
| Tidal Pull | `tidal` | While paused | $5 | Pick a pocket: for the rest of the shot it pulls rolling balls towards it. |  |  |

## Exotic balls

| Ball | Id | Cost | Value | What it does | Your note | Done |
|---|---|---|---|---|---|---|
| Gold ball | `gold` | $6 | 45 | Worth 45, and pays $1 for every cushion it touched before sinking. |  |  |
| Void ball | `void` | $7 | 0 | Worth nothing itself, but every other ball in the same shot scores ×2. |  |  |
| Glass ball | `glass` | $6 | 30 | Scores ×3 if it sinks, but anything that hits it hard shatters it, and it leaves your rack. |  |  |
| Iron ball | `iron` | $5 | 70 | 200% weight. Worth 70. |  |  |
| Feather ball | `feather` | $4 | 40 | 25% weight: it barely moves other balls, and adds +0.5 Chain as it sinks. |  |  |
| Ember ball | `ember` | $5 | 35 | The pocket it sinks into becomes the hot pocket. |  |  |
| Frost ball | `frost` | $5 | 35 | Any ball that touches it stops dead. |  |  |
| Magnet ball | `magnet` | $5 | 30 | Pulls nearby rolling balls towards itself. |  |  |
| Prism ball | `prism` | $5 | 35 | Counts as both a solid and a stripe. |  |  |
| Wild ball | `wild` | $5 | 0 | Copies the number of the last ball you sank, and counts as that number. |  |  |
| Clock ball | `clock` | $5 | 15 | Worth 15, plus 9 for every shot already taken on this table. |  |  |
| Coin ball | `coin` | $4 | 30 | Pays $1 every time the cue ball hits it in a scoring shot. |  |  |
| Bomb ball | `bomb` | $6 | 30 | When it sinks, the nearest ball (never the 8) sinks with it. |  |  |
| Seed ball | `seed` | $4 | 30 | Worth 30, and 15 more every time you sink it this run. |  |  |
| Clover ball | `clover` | $5 | 30 | No shot it is part of can cost Chalk. |  |  |
| Star ball | `star` | $5 | 30 | Comes off cushions with no loss of speed, and adds +1 Chain as it sinks. |  |  |
| Heart ball | `heart` | $6 | 30 | If it is the only ball left on the table when you sink it, +1 Chalk. |  |  |
| Dice ball | `dice` | $4 | 0 | Shows a new number from 1 to 15 every shot, and counts as that number. |  |  |
| Moon ball | `moon` | $5 | 35 | Corner pockets reject it. Scores ×2 in a side pocket. |  |  |
| Sun ball | `sun` | $5 | 35 | Side pockets reject it. Scores ×2 in a corner pocket. |  |  |
| Anchor ball | `anchor` | $6 | 105 | Only the cue ball can move it: other balls bounce off it like a post. Worth 105. |  |  |
| Eraser ball | `eraser` | $3 | 15 | When it sinks it pays $4, and both it and the last ball it touched leave your rack (never the 8). |  |  |
| Echo ball | `echo` | $6 | 30 | The first time it sinks on a table, it comes back to the foot spot. |  |  |
| Phantom ball | `phantom` | $5 | 40 | Other object balls pass straight through it: only the cue ball can hit it. Worth 40. |  |  |
| Spring ball | `spring` | $5 | 30 | Balls bounce off it 50% faster than they hit it. |  |  |
| Piggy Bank ball | `piggy` | $4 | 10 | Worth 10, and when it sinks it pays $1 for every shot already taken on this table (up to $6). |  |  |
| Jackpot ball | `jackpot` | $5 | 20 | When it sinks, 1 in 6 chance to pay $10; otherwise it pays $1. |  |  |
| Pinball ball | `pinball` | $5 | 20 | Worth 20, plus 10 for every cushion it touched before it sank. |  |  |
| Fuse ball | `fuse` | $5 | 30 | When it sinks, +1 Heat for every ball that sank before it in the same shot. |  |  |
| Comet ball | `comet` | $5 | 40 | Feels no cloth friction until it first hits a cushion. |  |  |

## Starting cues

| Cue | Id | Money | Chalk | Starts with | Description | Your note | Done |
|---|---|---|---|---|---|---|---|
| Classic Maple | `maple` | $7 | 0 |  | A plain cue. $7. |  |  |
| Hot Rod | `hotrod` | $4 | -1 | Focal Point | Carries Focal Point, and your 1-ball is Kindled. 1 less Chalk. $4. |  |  |
| Gilded Cue | `gilded` | $6 | 0 | Conservation | Carries Conservation, and your 3-ball is Gilded. $6. |  |  |
| Gear Cue | `gearhead` | $3 | 0 | Golden Ratio | Carries Golden Ratio, and holds 2 extra Catalysts. $3. |  |  |
| Lean Cue | `lean` | $4 | 0 | Quantum Tunnel | Carries Quantum Tunnel. Your rack starts without the 1 and 2. $4. |  |  |
| Black Cue | `black` | $3 | 0 | Reflection | Carries Reflection. Sinking the 8 early costs nothing. $3. |  |  |
| Alchemist's Cue | `alchemist` | $3 | 0 | Entanglement | Carries Entanglement, and starts with a Gold ball. $3. |  |  |
| Glass Cue | `glass` | $4 | 0 | Inertia | Carries Inertia, and starts with a Glass ball. $4. |  |  |
| Number Theory Cue | `numbers` | $2 | 0 | Promethium Prime, Fermium Spiral | Starts with Promethium Prime and Fermium Spiral, but holds only 4 Elements. $2. |  |  |
| Post Cue | `posts` | $2 | 0 |  | Carries 4 Fixed Points every table, and starts with a Spring ball. $2. |  |  |
| Portal Cue | `portals` | $2 | 0 |  | Carries 4 Wormholes every table. Every portal trip adds +1 Chain. $2. |  |  |
| Wall Cue | `walls` | $2 | 0 |  | Carries 4 Force Fields every table, and your 4-ball is Rubber. $2. |  |  |
| Trapdoor Cue | `trapdoors` | $2 | 0 |  | Carries 4 Black Holes every table, and your 6-ball is Magnetic. $2. |  |  |
| Gravity Cue | `gravity` | $2 | 0 |  | Carries 4 Gravity Wells every table, and starts with a Comet ball. $2. |  |  |

## Side bets

Stakes are in the tables section above. The stake is capped at your money when the bet is dealt, and with less than $2 there is no bet. Peeking costs half the stake.

| Bet | Id | Tier | Wins | Your note | Done |
|---|---|---|---|---|---|
| Sink a solid ball | `solid` | Easy | 1× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink a striped ball | `stripe` | Easy | 1× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink a ball into a corner pocket | `corner` | Easy | 1× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink a ball into a side pocket | `side` | Easy | 1× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink a ball into the hot pocket | `hot` | Easy | 1× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink a ball on the break | `breakpot` | Easy | 1× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink a ball with a power shot (85%+) | `hard` | Easy | 1× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink a ball with a soft shot (35% or less) | `soft` | Easy | 1× (+0.5× every 3 tables, up to +1×) |  |  |
| Reach Heat 3 | `heat3` | Easy | 1× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink 2 or more balls in one shot | `double` | Medium | 2× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink a bank shot | `bank` | Medium | 2× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink a combination | `combo` | Medium | 2× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink a ball off a kick shot | `kick` | Medium | 2× (+0.5× every 3 tables, up to +1×) |  |  |
| Reach Heat 4 | `heat4` | Medium | 2× (+0.5× every 3 tables, up to +1×) |  |  |
| Reach Chain 5 in one shot | `chain5` | Medium | 2× (+0.5× every 3 tables, up to +1×) |  |  |
| Score a quarter of this table's target in one shot | `quarter` | Medium | 2× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink 3 or more balls in one shot | `triple` | Hard | 3× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink a ball off 2 cushions | `bank2` | Hard | 3× (+0.5× every 3 tables, up to +1×) |  |  |
| Reach Heat 5 | `heat5` | Hard | 3× (+0.5× every 3 tables, up to +1×) |  |  |
| Reach Chain 7 in one shot | `chain7` | Hard | 3× (+0.5× every 3 tables, up to +1×) |  |  |
| Score half of this table's target in one shot | `half` | Hard | 3× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink 2 balls into the hot pocket in one shot | `hot2` | Hard | 3× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink the 8 when it is the only ball left | `eight` | Hard | 3× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink a ball straight in, with no cushions or other balls | `clean` | Easy | 1× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink the 13, 14 or 15 | `topthree` | Easy | 1× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink a solid and a stripe in one shot | `mixed` | Medium | 2× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink balls into 2 different pockets in one shot | `twopockets` | Medium | 2× (+0.5× every 3 tables, up to +1×) |  |  |
| Sink a ball off 3 cushions | `bank3` | Hard | 3× (+0.5× every 3 tables, up to +1×) |  |  |
| Reach Chain 10 in one shot | `chain10` | Hard | 3× (+0.5× every 3 tables, up to +1×) |  |  |
| Earn $5 or more in one shot | `money5` | Hard | 3× (+0.5× every 3 tables, up to +1×) |  |  |

