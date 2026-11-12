# Elements: names, reworks and ideas (2026-11-12)

Every Element now has a two-word name, the element and a noun, such as **Hydrogen Balloon** or **Lead Anchor**. The tile still shows the real symbol (H, Pb) and the atomic number. Each tile also has a short description of what the card does across its bottom row, such as "Object balls 30% lighter".

Fourteen Elements were **reworked**, and one gained a physical effect, to change the physics, or to trigger on a pause, a scratch or the break, instead of adding points. They are marked **Reworked** below, and the full list of changes is under [What changed in the game](#what-changed-in-the-game). The [ideas section](#more-physics-ideas-not-built) lists further reworks that need new simulation features.

## All 100

| Z | Name | Card id | What it does now |
|---|---|---|---|
| 1 | Hydrogen Balloon | `featherweight` | **Reworked.** Object balls are 30% lighter (was 25%), so they float further when struck. Now Hydrogen, swapped with Beryllium |
| 2 | Helium Fusion | `fusion` | A second ball into the same pocket in one shot scores ×3 |
| 3 | Lithium Cell | `lowball` | **Reworked.** Balls 1, 2 and 3 are charged: they lose no speed off cushions. Was balls 1–3 +45 |
| 4 | Beryllium Avalanche | `catalyst` | Every ball you sink makes all balls worth +0.75 for the rest of the run. Now Beryllium, swapped with Hydrogen |
| 5 | Boron Cluster | `multi` | Every ball after the first in a shot adds +1 Chain |
| 6 | Carbon Core | `eight` | The 8 costs nothing, scores like any ball and pays $3 |
| 7 | Nitrogen Tyres | `liverails` | Cushions are 10% livelier |
| 8 | Oxygen Octet | `darkhorse` | The 8 scores ×8 |
| 9 | Fluorine Flare | `odd` | Odd balls are worth +20 |
| 10 | Neon Sign | `steerclear` | If nothing touches the 8, each sink adds +0.75 Chain |
| 11 | Sodium Cushion | `cushion` | Bank sinks are worth +30 |
| 12 | Magnesium Torch | `heat` | The hot pocket scores ×3, and balls there are worth +30 |
| 13 | Aluminium Ore | `bedrock` | Shots that sink only solids add +1 Heat |
| 14 | Silicon Wafer | `solids` | Solids are worth +35 |
| 15 | Phosphorus Match | `streak` | Shots that sink 2+ balls add +1 Heat |
| 16 | Sulfur Chain | `chain` | Combinations score ×2 |
| 17 | Chlorine Clean | `precision` | Clean sinks add +1 Chain |
| 18 | Argon Shield | `insurance` | The first 2 misses on each table cost no Chalk |
| 19 | Potassium Kick | `kick` | Kick shots score ×2 |
| 20 | Calcium Chalk | `chalk` | +1 Chalk on every table |
| 21 | Scandium Hustle | `hunter` | Side bets you win pay double |
| 22 | Titanium Jaws | `jaws` | Pockets are 12% wider |
| 23 | Vanadium Velvet | `velvet` | 30% less cloth friction |
| 24 | Chromium Stripes | `stripes` | Stripes score ×1.5 |
| 25 | Manganese Swerve | `masse` | English bends the cue ball twice as much |
| 26 | Iron Fist | `golden` | The first sink of every shot scores ×2 |
| 27 | Cobalt Glaze | `secondcoat` | Isotope balls score ×1.5 |
| 28 | Nickel Supernova | `supernova` | Shots that sink 3+ score ×2 |
| 29 | Copper Penny | `gold` | Each sink pays $1, up to $3 a shot |
| 30 | Zinc Coupon | `quartermaster` | Catalysts cost $1 less |
| 31 | Gallium Glide | `collector` | **Reworked.** The cue ball rolls 30% further. Was +0.5 Chain for every pocket used |
| 32 | Germanium Angles | `geometry` | Bank sinks ×1.5 for every cushion |
| 33 | Arsenic Mutation | `alchemy` | After each table, a plain ball becomes a random special ball |
| 34 | Selenium Lens | `lens` | Long sinks add +1 Chain |
| 35 | Bromine Boomerang | `boomerang` | If the cue ball comes home, every sink ×2 |
| 36 | Krypton Tally | `eightcount` | Every 8th ball you sink scores ×3 |
| 37 | Rubidium Rush | `racing` | **Reworked.** Stripes are 30% lighter and roll 25% further. Was stripes at 60%+ power ×2 |
| 38 | Strontium Firework | `side` | Side pockets score ×2 |
| 39 | Yttrium Ladder | `steadyrun` | Solids in a row are worth +12 more each |
| 40 | Zirconium Gem | `stripesonly` | Stripes ×2, solids ×0.5 |
| 41 | Niobium Menagerie | `menagerie` | +0.25 Chain for each special ball you own |
| 42 | Molybdenum Shaft | `longarm` | Full power hits 15% harder |
| 43 | Technetium Gap | `missing` | +0.5 Chain for each ball removed from your set |
| 44 | Ruthenium Nugget | `goldrush` | Special balls score ×2 |
| 45 | Rhodium Rhythm | `rhythm` | Every third shot scores ×2 |
| 46 | Palladium Vault | `venture` | +0.25 Chain for every $5 you hold |
| 47 | Silver Tongue | `hushmoney` | An early 8 costs $3 instead of points. Family is now Economy (was The 8-ball) |
| 48 | Cadmium Chill | `coupon` | At Heat 0, every sink ×2 |
| 49 | Indium Touch | `finesse` | Soft shots score ×2 |
| 50 | Tin Toolbox | `tinkerer` | A Catalyst gets one extra use each table |
| 51 | Antimony Kohl | `kissblack` | Every touch on the 8 adds +0.75 Chain |
| 52 | Tellurium Eye | `oracle` | See exactly what each shot will score |
| 53 | Iodine Swab | `cleanhouse` | Removing a ball is free |
| 54 | Xenon Flash | `stillness` | **Reworked.** Once a table, the first time you pause, every rolling ball speeds up by 30%. Was +0.5 Chain a pause |
| 55 | Caesium Clock | `overclock` | Catalysts get two uses a table |
| 56 | Barium Spin | `backspin` | Draw and follow 50% stronger |
| 57 | Lanthanum Lantern | `comeback` | On your last Chalk, every sink ×2 |
| 58 | Cerium Flint | `thrift` | Clear a table with 2+ Chalk left: +$5 |
| 59 | Praseodymium Twin | `rotation` | The lowest ball scores as the highest |
| 60 | Neodymium Magnet | `elastic` | **Reworked.** The cue ball is magnetic: as it rolls past, it tugs nearby balls towards it. Was +0.25 Chain a hit, and named Neodymium Speaker |
| 61 | Promethium Prime | `prime` | Prime balls score ×2 |
| 62 | Samarium Simmer | `entropy` | Below Heat 3, +1 Chain |
| 63 | Europium Double | `echo` | The first sink of every shot counts twice |
| 64 | Gadolinium Pull | `magnet` | Pockets pull nearby balls in |
| 65 | Terbium Tiger | `tiger` | Stripes in a row build Chain |
| 66 | Dysprosium Domino | `domino` | **Reworked.** Ball-to-ball hits lose no speed, so every combination carries. Was combinations +30 |
| 67 | Holmium Magnet | `hothand` | **Reworked.** At Heat 3+, pockets pull nearby rolling balls in. Was +30 at Heat 3+ |
| 68 | Erbium Laser | `even` | Even balls add +0.75 Chain |
| 69 | Thulium Thinning | `thinrack` | Every removed ball makes all balls +12 |
| 70 | Ytterbium Draw | `drawartist` | Draw shots score ×1.5 |
| 71 | Lutetium Luck | `luckystripe` | Stripes: 1 in 3 score ×3 and pay $2 |
| 72 | Hafnium Rod | `migration` | On fire, a miss costs only 1 Heat |
| 73 | Tantalum Plate | `solidsonly` | Solids ×3, stripes ×0.5 |
| 74 | Tungsten Core | `lever` | **Reworked.** Stripes weigh 140% and lose no speed off cushions. Was long sinks ×1.5 |
| 75 | Rhenium Ricochet | `ricochet` | Every cushion a ball touches adds +0.25 Chain |
| 76 | Osmium Cue | `heavyhit` | The cue ball is 30% heavier |
| 77 | Iridium Flame | `minimalist` | On fire, every sink ×2 |
| 78 | Platinum Rail | `bank` | Bank sinks add +1 Chain per cushion |
| 79 | Gold Bar | `solidgold` | Each solid pays $1 |
| 80 | Mercury Messenger | `quickhands` | The first Catalyst each table is free |
| 81 | Thallium Felt | `slowcloth` | Balls stop 25% sooner |
| 82 | Lead Anchor | `laststripe` | **Reworked.** The 8 weighs 300% and rattles out of the pockets until it is the last ball, so it can't go in early. Was the last stripe ×5 |
| 83 | Bismuth Crystal | `lastsolid` | The last solid scores ×8 |
| 84 | Polonium Halo | `lastcall` | **Added to.** When the 8 is the last ball, the pockets pull it in; sinking it still scores ×5 and pays $5 |
| 85 | Astatine Edge | `glasscannon` | Every sink ×2, but misses cost 2 Chalk |
| 86 | Radon Burst | `bigbreak` | Breaks hit 25% harder |
| 87 | Francium Fizz | `followthru` | **Reworked.** Scratch while sinking 2+ balls and the shot still scores, with no Chalk lost. Was follow shots +0.5 Chain |
| 88 | Radium Trail | `tracer` | Cue ball cushions after contact add +0.25 Chain |
| 89 | Actinium Ray | `highball` | Balls 13–15 score ×2.5 |
| 90 | Thorium Stopper | `stun` | The cue ball loses 60% of its speed at its first hit |
| 91 | Protactinium Pack | `packrat` | +1 Catalyst slot |
| 92 | Uranium Reactor | `power` | **Reworked.** At 85%+ power, the first ball the cue ball hits flies off 20% faster. Was +1 Chain at 85%+ |
| 93 | Neptunium Tide | `overflow` | Points over the target carry over (up to 25%) |
| 94 | Plutonium Pit | `trouble` | An early 8 gives +3 Heat |
| 95 | Americium Beacon | `afterimage` | Impulse and Superposition add +1 Chain |
| 96 | Curium Corner | `corner` | Corner pockets add +0.5 Chain |
| 97 | Berkelium Break | `afterburner` | **Reworked.** Place the cue ball anywhere on the table for the break. Was breaks +3 Chain |
| 98 | Californium Jackpot | `moneyball` | Ball numbers count ×3 |
| 99 | Einsteinium Lab | `enchanter` | Isotopes cost $2 less |
| 100 | Fermium Spiral | `fibonacci` | Fibonacci balls are worth +35 |

## What changed in the game

The changes to rules, rarity, cost or family, all in `src/game/catalog.gd` unless noted:

- **Hydrogen and Beryllium swapped cards.** `featherweight` is now Hydrogen (Z 1), so Hydrogen is the floaty one. `catalyst` is now Beryllium (Z 4). The symbols on the tiles swapped too.
- **Hydrogen Balloon** makes object balls 30% lighter instead of 25%.
- **Lead Anchor** (`laststripe`): the 8 weighs 300% and rattles out of pockets until it is the last ball, so there are no early 8s. It no longer scores the last stripe ×5. Its family changed from Stripes to The 8-ball, its rarity from Rare to Uncommon, and its cost from $8 to $6.
- **Holmium Magnet** (`hothand`): at Heat 3+, pockets pull nearby rolling balls in. It no longer gives +30 at Heat 3. Its "Now:" line in the game reads "ON, pockets pull".
- **Tungsten Core** (`lever`): stripes weigh 140% and lose no speed off cushions. It no longer scores long sinks ×1.5. Its family changed from Utility to Stripes.
- **Rubidium Rush** (`racing`): stripes are 30% lighter and roll 25% further. It no longer scores stripes at 60%+ power ×2.
- **Dysprosium Domino** (`domino`): ball-to-ball hits keep all their speed. It no longer gives combinations +30. Its family changed from Combos to Physics, its rarity from Common to Uncommon, and its cost from $5 to $6.
- **Gallium Glide** (`collector`): the cue ball rolls 30% further. It no longer gives +0.5 Chain per pocket used. Its family changed from Pockets to Cue control, its rarity from Rare to Uncommon, and its cost from $8 to $6. Its scoring was removed from `scorer.gd`, and its "Now:" line from `main.gd`.
- **Xenon Flash** (`stillness`): once a table, the first pause speeds every rolling ball up by 30%, with a banner. It no longer adds Chain on each pause.
- **Francium Fizz** (`followthru`): a scratch with 2+ other balls sunk still scores and costs no Chalk. It no longer pays for follow shots. Its family changed from Cue control to Risk, its rarity from Common to Uncommon, and its cost from $5 to $6.
- **Berkelium Break** (`afterburner`): the break, and a scratch on the break, let you place the cue ball anywhere, not just behind the line. It no longer adds +3 Chain on the break.
- **Neodymium Magnet** (`elastic`): was Neodymium Speaker. The rolling cue ball tugs nearby object balls towards it (`PoolSim.cue_magnet`). It no longer adds Chain on hits. Its rarity changed from Common to Uncommon and its cost from $4 to $6.
- **Lithium Cell** (`lowball`): balls 1–3 lose no speed off cushions. They are no longer worth +45.
- **Uranium Reactor** (`power`): at 85%+ power, the first ball struck leaves 20% faster (`PoolSim.first_boost`, set when the shot is struck, and in the prediction too). It no longer adds +1 Chain.
- **Polonium Halo** (`lastcall`): keeps its ×5 and $5, and now the pockets also pull the 8 in when it is the last ball.
- **Weights are shown as percentages** everywhere: Lead Anchor 300%, Mass Shift 400%, Leaded and the Iron ball 200%, Hollow 50%, the Feather ball 25%.
- **Silver Tongue** moved from The 8-ball family to Economy. This keeps eight Elements in the 8-ball family now that Lead Anchor has joined it.
- **The simulation** (`src/sim/pool_sim.gd`) has two new settings:
  - A per-ball `grip`, the cloth friction for each ball. Rubidium and Gallium use it, and so does the shot prediction.
  - An `anchor8` flag: pockets turn the 8 away while other balls remain.
  
  Tungsten uses the existing per-ball `bounce`. `apply_physics` in `run_state.gd` now sets `ball_e` on every call, for Dysprosium.
- **Cue descriptions** use the full new names, for example "Starts with Magnesium Torch".
- **Tests** were updated for the new behaviour (`test_sim`, `test_eight_and_suits`, `test_tiles`), with new checks for every reworked card.

## More ideas (not built)

Elements stay **passive**: nothing to press. They can still react to moments in a shot, as the reworks above do. Good triggers:

- **Once a table, on the first pause:** like Xenon Flash.
- **On a scratch:** like Francium Fizz.
- **On the break:** like Berkelium Break.
- **When something happens:** the 8 being the last ball, Heat reaching 3, or a ball touching the 8.

Each idea below needs something new in the simulation, so none of them are built yet.

| Element | Idea | Needs |
|---|---|---|
| Fluorine Flare | Odd balls push each other apart before they touch | A short-range repulsion between chosen balls |
| Mercury Messenger | A slick puddle on the cloth where balls lose no speed | Friction zones (also useful for Snell's Law) |
| Sodium Cushion | Soft cushions: balls come off 20% slower and settle by the rail | Per-cushion liveliness, as Hooke's Law already does for one segment |
| Xenon Flash | Pausing freezes every object ball for half a second | A timed freeze when a shot is resumed |
| Krypton Tally | The guide line also shows the 8's path after any hit | A guide-line feature, not physics |
| Helium Fusion | Two balls that meet in a pocket's jaws both drop | Pocket capture by contact |
| Silicon Wafer | Solids slide flat and ignore spin passed on by the cue ball | Per-ball spin transfer |
