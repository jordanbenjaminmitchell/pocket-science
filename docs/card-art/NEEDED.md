# Card art: status

**Every card has art.** That is 189 tiles: all 100 Elements, 20 Isotopes, 24 special balls, 21 Hustler's Kit items, 23 side bets and the face-down card back. Every tile is drawn in code by `TileArt` in [src/ui/tile_art.gd](../../src/ui/tile_art.gd); the data is the `TILES` table at the top. Preview sheets of every tile, at twice their real size, are in this folder (`perk-tiles-*.png`, `imbue-tiles-1.png`, `ball-tiles-*.png`, `item-tiles-*.png`, `bet-cards-*.png`).

[tests/test_tiles.gd](../../tests/test_tiles.gd) checks that every card has a tile, that no two cards share a symbol or a lettering effect, that every effect is drawn, and that each stat and name fits its tile.

## Still to do (code, not art)

- **Side bets are shown as cards in the game.** The side panel shows `BetCard.from_run(run)` at half size beside the Bet / Peek / Pass buttons; resting on it (or tapping it) shows it full size.
- **Starting cues have no tiles** (optional in the brief). The cue-select screen draws its own 150-wide cards with the cue stick, so tiles would need that screen reworked first.

## Art changes from the latest passes (2026-11-12)

1. **New names: Perks are now Elements, Imbues are now Isotopes.** The tile code already prints the new words (the header says ELEMENT or ISOTOPE, and loose Isotopes read "Spark Isotope"), but every preview sheet (`perk-tiles-*.png`, `imbue-tiles-1.png`) still shows the old words. **Re-render all the sheets.**
2. **Two tile stats changed with the rename:** Enchanter now reads "Isotopes −$2" and Second Coat "Isotope ×1.5". Check they still fit and read well.
3. **Two Element names now sound like magic** next to the science names: **Enchanter** (Isotopes cost $2 less, lettering effect "enchant") and **Alchemy** (turns a plain ball special). Consider science names and lettering, for example **Enchanter → Isotope Lab** and **Alchemy → Transmutation**. (The game names would change to match; tell me which you pick.)
4. **The Element Table is now the Clockwork Table.** No tile shows it, but if tables get art later, it's pockets numbered 1 to 6 like a clock face, not fire, water, earth and air.
5. **Cues changed.** Seven plain cues are gone and five object cues are new (Post, Portal, Wall, Trapdoor, Gravity). The cue list above is current, for the optional cue tiles.
6. **Catalysts:** see the section below. Every item becomes a Catalyst; most keep their tile with a new name, a few are new.
7. **Possible later:** if the table rework in `docs/TABLES_BRAINSTORM.md` goes ahead, Sharks (enemies) and moving objects will need art.

## Catalysts: the Hustler's Kit rework (art flags)

Items become **Catalysts**: every one recharges each table (none are used up), you hold up to **5**, and you use them while a shot is paused. Every Catalyst changes the board: it moves balls, bends paths or adds or removes obstacles. None of them just add points.

**Renamed: keep the tile, change the name and symbol** (the ID stays the same)

| Old item | New Catalyst | Symbol | What it does now | Art note |
|---|---|---|---|---|
| Second Strike | **Impulse** | Im | Hit the cue ball again | Same picture works |
| Blink | **Superposition** | Sp | Move the cue ball anywhere; it keeps its speed and direction | Same |
| Ghost Chalk | **Quantum Tunnel** | QT | Pick a ball: it passes straight through other balls this shot | Same idea, new name |
| Freeze Frame | **Inertia** | In | Stop a ball dead; it holds like a post | Same |
| Polish | **Zero Friction** | ZF | Pick a ball: it glides with no cloth friction | Same |
| Gravity Pebble | **Gravity Well** | GW | Drop a well that bends rolling balls | Same |
| Portal Pair | **Wormhole** | Wh | Two linked portals for the rest of the shot | Same |
| Pop-up Wall | **Force Field** | FF | Raise a short wall | Glowing barrier instead of a wall |
| Post | **Fixed Point** | FP | Place a post (bumper) | Same |
| English Dial | **Spin Transfer** | ST | Put your set spin onto the rolling cue ball | Same |
| Swap | **Entanglement** | En | Two balls swap places, keeping their motion | Same, with an entangled-pair look |
| Nudge | **Vector** | Vc | Push a ball a short way in any direction | Add an arrow |
| Lead Weight | **Mass Shift** | MS | Pick a ball: four times as heavy for the shot | Same |
| Pocket Cover | **Event Horizon** | EH | Pick a pocket: it swallows twice as wide this shot | **New picture:** a pocket with a dark halo |
| Trapdoor | **Black Hole** | BH | Open a pocket anywhere along a cushion this shot | Hole in a cushion with a dark swirl |
| Rewind | **Time Reversal** | TR | Undo this shot mid-roll and take it again | Same |
| Spotter | **Conservation** | Cn | Bring back a ball sunk this shot to the foot spot | Same |

**New Catalysts: new tiles needed**

| Catalyst | Symbol | What it does | Picture idea |
|---|---|---|---|
| **Pythagorean Triple** | PT | Pick three balls: three force-field walls join them into a triangle for the rest of the shot | Right triangle (3-4-5) of glowing lines between three balls |
| **Newton's Cradle** | NC | Pick a ball: the cue ball stops dead and that ball takes all its momentum | Hanging balls of a cradle |
| **Reflection** | Rf | Pick a ball: it reverses direction | A ball and its mirror image with a U-turn arrow |
| **Golden Ratio** | GR | Pick a ball: its speed ×1.618 | Golden spiral |
| **Centre of Mass** | CM | Pick two to four balls: they all head towards the point between them | Balls with arrows meeting at a centre dot |
| **Hooke's Law** | HL | Pick a cushion: anything that bounces off it keeps all its speed | A spring in a cushion |

**Removed: their tiles are no longer needed:** Called Shot, Insurance Slip, Triangle, Ball in Hand. They only scored points, or did what another Catalyst now does.

**Object cues keep their objects,** now under the new names: Post Cue → Fixed Point, Portal Cue → Wormhole, Wall Cue → Force Field, Trapdoor Cue → Black Hole, Gravity Cue → Gravity Well.

**Elements that mention items** get new wording (no art change, but the tile stat may change): Pack Rat (+1 Catalyst slot), Quartermaster (Catalysts cost $1 less), Tinkerer (+1 charge on a random Catalyst each table), Quick Hands (the first Catalyst each table is free), Afterimage (Impulse and Superposition add Chain), Overclock (Catalysts get two charges).

## Symbol rules

The symbols follow the rules this file set out: a real element only where it genuinely fits (**Au** Gold ball, **Fe** Iron ball, **Pb** Leaded), otherwise the initials of the first two words (**FT** Follow Through), or a one-word name's first letter and then its first two (**B** Boomerang, **Bl** Blink). Later clashes take the first letter plus the next consonant.

All 91 re-letterings from the earlier list are in, with two changes where that list clashed with a tile it did not include:

- **Stillness is SL**, not St: **St** already belongs to Stripes, and every other pair from Stillness was taken.
- **Snowball is Sb**, not Sw, so Swap can have the natural **Sw**.

Lucky Numbers' stat now says **Fibonacci +35**, matching its new card text. The Vein Isotope now spreads instead of adding Chain, so the mirror lettering moved to the new **Mirror** Isotope, and Vein's letter grows branching veins.

## Isotopes

An Isotope offered before you choose its ball shows a question-mark ball, **Any ball**, and the name "*Spark Isotope*". Once a ball is chosen (or a new 11–15 arrives imbued), the tile shows that ball.

| Card | ID | Symbol | Stat | Lettering |
|---|---|---|---|---|
| Vein | `imbue:vein` | **V** | +20, spreads | veins branching out of the letter (particles) |
| Spark | `imbue:spark` | **Sk** | +1 Chain a hit | crackling with arcs of electricity (particles) |
| Gilded | `imbue:gold` | **G** | $1, +$1 a table | gold leaf laid over half the letter, flakes drifting off (particles) |
| Weighted | `imbue:heavy` | **W** | Number ×3, ×4… | squashed under a weight marked ×3, with ×4 and ×5 waiting |
| Hairline | `imbue:glass` | **H** | ×3, may crack | a glossy coat with a fine crack through it |
| Kindled | `imbue:ember` | **K** | +2 Heat | kindling crossed under the letter, catching light (particles) |
| Lucky | `imbue:lucky` | **L** | 1 in 2: ×2 | inside a lucky horseshoe, ends up (particles) |
| Volatile | `imbue:volatile` | **Vo** | Explodes on hit | shaking in front of a blast (particles) |
| Jinxed | `imbue:jinxed` | **J** | ×4, halves Heat | tilted under its own rain cloud (particles) |
| Mirror | `imbue:mirror` | **M** | Copies its hitter | a faint reflection below, as on a polished surface |
| Pawned | `imbue:pawned` | **P** | $4, no points | under the pawnbroker's three gold balls |
| Frosted | `imbue:frosted` | **Fr** | Next miss safe | iced like a cake, snow along the tops (particles) |
| Magnetic | `imbue:magnetic` | **Ma** | Pockets pull it | split red and blue like a magnet, field lines round it |
| Charged | `imbue:charged` | **Cr** | +0.5 Chain a rail | inside a battery, a bolt at the terminal (particles) |
| Resonant | `imbue:prismatic` | **Rn** | +0.25 a touch | rings of vibration rippling out (particles) |
| Hollow | `imbue:hollow` | **Ho** | Half weight | an empty shell floating over its shadow |
| Leaded | `imbue:leaded` | **Pb** | ×2 weight, +45 | cast deep in solid lead |
| Bounty | `imbue:bounty` | **Bo** | $1 per Heat | on a wanted poster |
| Starry | `imbue:starry` | **Sy** | +0.5 to the rest | a night sky, stars trailing after it (particles) |
| Twin | `imbue:twin` | **Tw** | Counts twice | a solid ball and its striped twin hopping over the letters |

## Special balls

| Card | ID | Symbol | Stat | On | Lettering |
|---|---|---|---|---|---|
| Gold | `ball:gold` | **Au** | 45 pts | Cushions | gold with a glint sweeping across |
| Void | `ball:void` | **Vd** | Others ×2 | Same shot | a black hole swirling round it (particles) |
| Glass | `ball:glass` | **Gl** | ×3, shatters | Hard hits | clear glass with a bright reflection (particles) |
| Iron | `ball:iron` | **Fe** | Worth 70 | Double weight | brushed steel on a riveted plate |
| Feather | `ball:feather` | **Fh** | +0.5 Chain | ¼ weight | in front of a quill feather |
| Ember | `ball:ember` | **Eb** | Hot pocket | Its pocket | a glowing coal (particles) |
| Frost | `ball:frost` | **Fs** | Stops balls dead | Touch | frozen in a block of ice (particles) |
| Magnet | `ball:magnet` | **Mg** | Pulls balls | Nearby balls | a horseshoe magnet pulling balls in |
| Prism | `ball:prism` | **Pm** | Solid + stripe | Both sets | white light splitting into a rainbow |
| Wild | `ball:wild` | **Wi** | Copies a number | Last sunk | any number at all floating behind it |
| Clock | `ball:clock` | **Cl** | 15, +9 a shot | Shots taken | on a clock face, the second hand ticking (particles) |
| Coin | `ball:coin` | **Cn** | $1 a cue hit | Cue ball | struck on a coin with a milled edge (particles) |
| Bomb | `ball:bomb` | **Bm** | Takes one down | Nearest ball | in front of a bomb with its fuse lit (particles) |
| Seed | `ball:seed` | **Sd** | 30, +15 a sink | Whole run | a sprout coming up beside it |
| Clover | `ball:clover` | **Cv** | No Chalk lost | Its shots | in front of a four-leaf clover |
| Star | `ball:star` | **Sr** | +1 Chain | Cushions | in front of a star (particles) |
| Heart | `ball:heart` | **He** | +1 Chalk | Last ball | in front of a heart (particles) |
| Dice | `ball:dice` | **Di** | 1–15 each shot | Its number | beside a tumbling die |
| Moon | `ball:moon` | **Mo** | ×2 in a side | Side pockets | cratered, under a crescent moon |
| Sun | `ball:sun` | **Su** | ×2 in a corner | Corners | rays blazing out from behind |
| Anchor | `ball:anchor` | **An** | Worth 105 | Cue ball only | in front of a ship's anchor |
| Eraser | `ball:eraser` | **Er** | $4, erases two | Last touched | being rubbed out by an eraser (particles) |
| Echo | `ball:echo` | **Eh** | Comes back once | Foot spot | looping back round to the foot spot |
| Comet | `ball:comet` | **Co** | No friction | Till a cushion | a comet tail streaming behind (particles) |

## Items (the Hustler's Kit)

| Card | ID | Symbol | Stat | On | Lettering |
|---|---|---|---|---|---|
| Second Strike | `item:secondstrike` | **S2** | Hit again | Cue ball | faded copies trailing behind, like a second hit |
| Trapdoor | `item:trapdoor` | **Tr** | +1 pocket | Cushion | the end slips down, as if through a trapdoor |
| Called Shot | `item:calledshot` | **Cd** | ×3 if called | Ball + pocket | a dashed call into a ringed pocket |
| Ghost Chalk | `item:ghostchalk` | **GC** | Pass through | One ball | a ghost the ball passes straight through (particles) |
| Swap | `item:swap` | **Sw** | Swap two balls | Two balls | two arrows trading places |
| Polish | `item:polish` | **Pl** | Glides free | One ball | buffed to a mirror shine (particles) |
| Lead Weight | `item:leadweight` | **LW** | ×4 weight | One ball | stamped on a lead weight |
| Spotter | `item:spotter` | **Sp** | Respot a ball | Foot spot | a ball dropping back onto the foot spot |
| Pocket Cover | `item:pocketcover` | **Pv** | Opposite +30% | Pockets | one pocket lidded, the other opening wide |
| Pop-up Wall | `item:wall` | **PW** | Raise a wall | This shot | a brick wall rising from below |
| Blink | `item:blink` | **Bl** | Move the cue | Cue ball | vanishing from one spot and appearing at another (particles) |
| Freeze Frame | `item:freezeframe` | **FF** | Stop one dead | One ball | caught on a strip of film |
| Nudge | `item:nudge` | **N** | Push one ball | One ball | pushed a little way along |
| English Dial | `item:englishdial` | **ED** | Add your spin | Cue ball | in front of a spin dial |
| Gravity Pebble | `item:gravitypebble` | **GP** | Bends balls | This shot | the cloth bent into a gravity well (particles) |
| Rewind | `item:rewind` | **Re** | Undo a shot | Last shot | rewind arrows, running backwards |
| Insurance Slip | `item:slip` | **IS** | Chalk back | Last shot | printed on a stamped slip |
| Triangle | `item:triangle` | **Tn** | Re-rack | All balls | inside a triangle rack |
| Ball in Hand | `item:ballinhand` | **BH** | Place the cue | Cue ball | the cue ball lifted, its new spot marked |
| Post | `item:post` | **Po** | Place a bumper | This table | a ball bouncing off a bumper post |
| Portal Pair | `item:portal` | **PP** | Linked portals | Rolling balls | between a blue portal and an orange one (particles) |

## Ball numbers on Element tiles

Elements that name ball numbers float those balls either side of the symbol: Odd Balls, Even Money, Prime Cut, Lucky Numbers, Low Ball and High Roller. `TileArt.balls_for("perk", id)` lists the balls any Element works on (also the solid, stripe and 8-ball Elements). In the game, resting the pointer on an Element you own rings those balls on the table with light (`TableView.spotlight`).

## Side bets

Side bets are **playing cards**, not periodic tiles: `BetCard` in [src/ui/bet_card.gd](../../src/ui/bet_card.gd), portrait (180×252) with an ivory face. Each face shows, with nothing upside down and nothing covering the wording:

- **Top left:** what the bet wins as a multiple of the stake, worked out from the real payout (so 2.5× on later tables), and one to three pips for the tier.
- **Top middle:** SIDE BET and the tier. The frame colour also gives the tier (Easy green, Medium amber, Hard red).
- **Top right:** the chip slot. It is an empty dashed ring until you bet, then a chip carrying your stake.
- **Picture:** the bet's own picture, in a dark window.
- **Wording:** the bet's full text. Bets that depend on the table say the real number: with a target of 215, "a quarter of the target" reads "Score 54 points in one shot", with "A quarter of the 215 target" under it.
- **Bottom:** the stake and what the bet pays back, in dollars. The labels change with the state: Riding / Pays, Staked / Paid, Passed / Would pay.

The **card back** is violet: a lattice of little atoms, a question mark at the heart of an atom with circling electrons, the stake and the most the bet could pay. A won card turns gold with sparkles round the frame; a passed card is dimmed. The moving parts stop while `Fx.minimal_particles` is on.

The periodic-tile versions below still exist in `TILES` (their `letter` is the picture the card uses), but the game should show `BetCard`.

| Bet | ID | Tile title | Stat | On |
|---|---|---|---|---|
| Sink a solid ball | `bet:solid` | Any solid | Wins 1× stake | Balls |
| Sink a striped ball | `bet:stripe` | Any stripe | Wins 1× stake | Balls |
| Sink a ball into a corner pocket | `bet:corner` | Corner pocket | Wins 1× stake | Pockets |
| Sink a ball into a side pocket | `bet:side` | Side pocket | Wins 1× stake | Pockets |
| Sink a ball into the hot pocket | `bet:hot` | Hot pocket | Wins 1× stake | Pockets |
| Sink a ball on the break | `bet:breakpot` | Sink on the break | Wins 1× stake | The break |
| Sink a ball with a power shot (85%+) | `bet:hard` | Power sink, 85%+ | Wins 1× stake | Power |
| Sink a ball with a soft shot (35% or less) | `bet:soft` | Soft sink, 35% or less | Wins 1× stake | Power |
| Reach Heat 3 | `bet:heat3` | Reach Heat 3 | Wins 1× stake | Heat |
| Sink 2 or more balls in one shot | `bet:double` | Two in one shot | Wins 2× stake | One shot |
| Sink a bank shot | `bet:bank` | Bank shot | Wins 2× stake | Cushions |
| Sink a combination | `bet:combo` | Combination | Wins 2× stake | One shot |
| Sink a ball off a kick shot | `bet:kick` | Kick shot | Wins 2× stake | Cushions |
| Reach Heat 4 | `bet:heat4` | Reach Heat 4 | Wins 2× stake | Heat |
| Reach Chain 5 in one shot | `bet:chain5` | Chain 5 in one shot | Wins 2× stake | Chain |
| Score a quarter of this table's target in one shot | `bet:quarter` | Quarter of the target | Wins 2× stake | One shot |
| Sink 3 or more balls in one shot | `bet:triple` | Three in one shot | Wins 3× stake | One shot |
| Sink a ball off 2 cushions | `bet:bank2` | Two-cushion bank | Wins 3× stake | Cushions |
| Reach Heat 5 | `bet:heat5` | Reach Heat 5 | Wins 3× stake | Heat |
| Reach Chain 7 in one shot | `bet:chain7` | Chain 7 in one shot | Wins 3× stake | Chain |
| Score half of this table's target in one shot | `bet:half` | Half the target | Wins 3× stake | One shot |
| Sink 2 balls into the hot pocket in one shot | `bet:hot2` | Two in the hot pocket | Wins 3× stake | One shot |
| Sink the 8 when it is the only ball left | `bet:eight` | Last-ball 8 | Wins 3× stake | The 8-ball |
| (card back) | `bet:back` | Side bet | Bet, peek or pass | This table |

## Particle effects

Cards marked *(particles)* above have small moving particles: sparks, embers, snow, rain, swirling motes, twinkles and so on. Elements with particles: Clean House, Cold Start, Gold Rush, Inferno, Simmer, Stoker.

They are drawn by `TileArt.Motes`, a layer over the lettering that calls the effect's `_p_<name>` method each frame. It draws nothing while `Fx.minimal_particles` is on (**Particles: minimum** or **Reduced motion**), and the tile is complete without them. The Gold ball's glint is a shader on the letters, not a particle.

## Rendering the sheets again

Run from the project folder (it opens a window, so no `--headless`):

```bash
PS_TILE_SET=imbues PS_TILE_ZOOM=2 godot --path . --script res://tools/tile_preview.gd -- docs/card-art/imbue-tiles.png
```

`PS_TILE_SET` takes `perks`, `imbues`, `balls`, `items`, `betcards` (the playing cards), `bets` (the old tiles) or `all`. `PS_TILE_ONLY=ball:void,item:post` renders only those cards.
