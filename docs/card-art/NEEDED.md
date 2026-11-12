# Card art: status

**Every card has art.** That is 189 tiles: all 100 Elements, 20 Isotopes, 24 special balls, 21 Hustler's Kit items, 23 side bets and the face-down card back. Every tile is drawn in code by `TileArt` in [src/ui/tile_art.gd](../../src/ui/tile_art.gd); the data is the `TILES` table at the top. Preview sheets of every tile, at twice their real size, are in this folder (`perk-tiles-*.png`, `imbue-tiles-1.png`, `ball-tiles-*.png`, `item-tiles-*.png`, `bet-cards-*.png`).

[tests/test_tiles.gd](../../tests/test_tiles.gd) checks that every card has a tile, that no two cards share a symbol or a lettering effect, that every effect is drawn, and that each stat and name fits its tile.

## Still to do (code, not art)

- **Side bets are shown as cards in the game.** The side panel shows `BetCard.from_run(run)` at half size beside the Bet / Peek / Pass buttons; resting on it (or tapping it) shows it full size.
- **Starting cues have no tiles** (optional in the brief). The cue-select screen draws its own 150-wide cards with the cue stick, so tiles would need that screen reworked first.

## Elements are real elements (2026-11-12)

Every Element (the passive cards, once called Perks) is now a **real chemical element**, numbered 1 to 100: all of hydrogen through fermium, with each element used once. The game shows the element's name, and its tile uses the **real chemical symbol**. Each element was picked so its chemistry, history or symbol echoes what the card does (Carbon is the 8-ball's Element, because the game's mark is a carbon atom with the 8-ball as its nucleus).

**For the art instance: brainstorm and update freely.** You're another instance of the same assistant, so trust your judgement: if a better element fits a card, swap it (keep each element used once, all at 100 or below, and tell me so the game's names change too). Please:

1. **Put the real symbol on every Element tile** (already set in `TILES`) and **show the atomic number** in the top-left corner, as on a real periodic table. The number is in `Catalog.PERKS[id].z`.
2. **Redo each Element's lettering effect and colours to suit its element:** neon glows, mercury looks liquid, sodium is soft, uranium glows green, gold is gold and so on. The current effects were made for the old names.
3. **Consider periodic-table colour coding** by element group (alkali metals, noble gases, lanthanides and so on) as a second accent beside the family colour.
4. **Fix the temporary symbols below.** Every real symbol from H to Fm now belongs to an Element, so other cards can't use any real chemical symbol.
5. The old **"Existing tiles to re-letter"** list is superseded for Elements (they use their real symbols now). It still applies to Isotopes, balls and Catalysts.

| Z | Element | Symbol | Card id | Old name | Why it fits |
|---|---|---|---|---|---|
| 1 | Hydrogen | H | `perk:catalyst` | Snowball | Builds everything else, one by one |
| 2 | Helium | He | `perk:fusion` | Same Pocket | What fusion makes |
| 3 | Lithium | Li | `perk:lowball` | Low Ball | Atomic number 3, for balls 1 to 3 |
| 4 | Beryllium | Be | `perk:featherweight` | Featherweight | One of the lightest metals |
| 5 | Boron | B | `perk:multi` | Cluster | Boron forms clusters |
| 6 | Carbon | C | `perk:eight` | Behind the 8 | The game's mark is a carbon atom with the 8-ball as its nucleus: the 8's own Element |
| 7 | Nitrogen | N | `perk:liverails` | Live Rails | What makes tyres bounce: lively rails |
| 8 | Oxygen | O | `perk:darkhorse` | Dark Horse | Atomic number 8, for the 8 that scores ×8 |
| 9 | Fluorine | F | `perk:odd` | Odd Balls | An odd atomic number, and the oddest, most reactive element |
| 10 | Neon | Ne | `perk:steerclear` | Steer Clear | A noble gas: it steers clear of every reaction |
| 11 | Sodium | Na | `perk:cushion` | Soft Rails | So soft you can cut it with a knife |
| 12 | Magnesium | Mg | `perk:heat` | Scorcher | Burns blindingly hot |
| 13 | Aluminium | Al | `perk:bedrock` | Bedrock | The most common metal in the Earth's crust |
| 14 | Silicon | Si | `perk:solids` | Solids | The element of solid rock |
| 15 | Phosphorus | P | `perk:streak` | Stoker | Match heads: it stokes the fire |
| 16 | Sulfur | S | `perk:chain` | Daisy Chain | Sulfur links into chains and rings |
| 17 | Chlorine | Cl | `perk:precision` | Clean Stroke | Clean |
| 18 | Argon | Ar | `perk:insurance` | Insurance | An inert shield gas: nothing gets through |
| 19 | Potassium | K | `perk:kick` | Kick Drum | K, the Kick |
| 20 | Calcium | Ca | `perk:chalk` | Spare Chalk | Chalk is calcium carbonate |
| 21 | Scandium | Sc | `perk:hunter` | Side Hustle | Sc, the side scam |
| 22 | Titanium | Ti | `perk:jaws` | Wide Jaws | Titanium jaws |
| 23 | Vanadium | V | `perk:velvet` | Velvet Cloth | V, velvet |
| 24 | Chromium | Cr | `perk:stripes` | Stripes | Chrome stripes |
| 25 | Manganese | Mn | `perk:masse` | Massé Master | Ma-ssé |
| 26 | Iron | Fe | `perk:golden` | First Blood | First blood: iron is what makes blood red |
| 27 | Cobalt | Co | `perk:secondcoat` | Second Coat | Cobalt blue: the classic second coat of glaze |
| 28 | Nickel | Ni | `perk:supernova` | Clean Sweep | Supernovas forge nickel |
| 29 | Copper | Cu | `perk:gold` | Gold Rail | Rails are wired in copper, and copper is coin |
| 30 | Zinc | Zn | `perk:quartermaster` | Quartermaster | Pennies are zinc: it saves you money |
| 31 | Gallium | Ga | `perk:collector` | Grand Tour | Named after Gaul: a grand tour of France |
| 32 | Germanium | Ge | `perk:geometry` | Geometry | Ge, for geometry |
| 33 | Arsenic | As | `perk:alchemy` | Alchemy | The alchemists' favourite |
| 34 | Selenium | Se | `perk:lens` | Long Lens | Light-sensitive: the first camera sensors |
| 35 | Bromine | Br | `perk:boomerang` | Boomerang | Br, it comes back |
| 36 | Krypton | Kr | `perk:eightcount` | Eight Count | A full shell of 8 outer electrons |
| 37 | Rubidium | Rb | `perk:racing` | Racing Stripe | Reacts in a flash: built for speed |
| 38 | Strontium | Sr | `perk:side` | Side Door | A side-street element, named after a village |
| 39 | Yttrium | Y | `perk:steadyrun` | Steady Run | Steadies alloys at high heat |
| 40 | Zirconium | Zr | `perk:stripesonly` | Stripes Only | Zr, the zebra of the table |
| 41 | Niobium | Nb | `perk:menagerie` | Menagerie | Named after Niobe, mother of a whole menagerie |
| 42 | Molybdenum | Mo | `perk:longarm` | Long Arm | Gives steel its long reach |
| 43 | Technetium | Tc | `perk:missing` | Missing Piece | The famous gap: the missing element in Mendeleev's table |
| 44 | Ruthenium | Ru | `perk:goldrush` | Gold Rush | Ru, the Rush |
| 45 | Rhodium | Rh | `perk:rhythm` | Rhythm | Rh, Rhythm |
| 46 | Palladium | Pd | `perk:venture` | Deep Pockets | Pd, Pockets Deep |
| 47 | Silver | Ag | `perk:hushmoney` | Hush Money | Hush money is paid in silver |
| 48 | Cadmium | Cd | `perk:coupon` | Cold Start | Cd, Cold start |
| 49 | Indium | In | `perk:finesse` | Soft Touch | So soft it squeaks: the soft touch |
| 50 | Tin | Sn | `perk:tinkerer` | Tinkerer | The tinker's metal |
| 51 | Antimony | Sb | `perk:kissblack` | Kiss the Black | Antimony made kohl, the black for kissing lips and eyes |
| 52 | Tellurium | Te | `perk:oracle` | Second Sight | Te, it tells you the score |
| 53 | Iodine | I | `perk:cleanhouse` | Clean House | Disinfects: a clean house |
| 54 | Xenon | Xe | `perk:stillness` | Stillness | Inert and still |
| 55 | Caesium | Cs | `perk:overclock` | Overclock | Caesium sets the atomic clock |
| 56 | Barium | Ba | `perk:backspin` | Backspin Wax | Ba-ck spin |
| 57 | Lanthanum | La | `perk:comeback` | Last Chalk | La, the Last chalk |
| 58 | Cerium | Ce | `perk:thrift` | Thrift | The cheapest rare earth |
| 59 | Praseodymium | Pr | `perk:rotation` | Rotation | Pr: the lowest ball gets promoted |
| 60 | Neodymium | Nd | `perk:elastic` | Loud Table | The magnets in every loudspeaker: a Loud Table |
| 61 | Promethium | Pm | `perk:prime` | Prime Cut | Atomic number 61 is a prime |
| 62 | Samarium | Sm | `perk:entropy` | Simmer | Sm, Simmer |
| 63 | Europium | Eu | `perk:echo` | Double Take | Glows in euro notes so they show twice |
| 64 | Gadolinium | Gd | `perk:magnet` | Magnetic Pockets | Strongly magnetic |
| 65 | Terbium | Tb | `perk:tiger` | Tiger Stripes | Its green glow streaks like a stripe |
| 66 | Dysprosium | Dy | `perk:domino` | Domino | Its name means hard to get at: knocked in by another ball |
| 67 | Holmium | Ho | `perk:hothand` | Hot Hand | Ho, Hot Hand |
| 68 | Erbium | Er | `perk:even` | Even Money | E-ven, with an even atomic number |
| 69 | Thulium | Tm | `perk:thinrack` | Thin Rack | Thin and rare |
| 70 | Ytterbium | Yb | `perk:drawartist` | Draw Artist | Drawn from one quarry with three other elements |
| 71 | Lutetium | Lu | `perk:luckystripe` | Lucky Stripe | Lu-cky |
| 72 | Hafnium | Hf | `perk:migration` | Stay Hot | Holds up at extreme heat |
| 73 | Tantalum | Ta | `perk:solidsonly` | Solids Only | So stubbornly solid and inert it is used in implants |
| 74 | Tungsten | W | `perk:lever` | Long Game | Long, thin filaments |
| 75 | Rhenium | Re | `perk:ricochet` | Ricochet | Re-bound |
| 76 | Osmium | Os | `perk:heavyhit` | Heavy Hitter | The densest element there is |
| 77 | Iridium | Ir | `perk:minimalist` | Inferno | Ir, Inferno: made in the heart of dying stars |
| 78 | Platinum | Pt | `perk:bank` | Bank Manager | A platinum account |
| 79 | Gold | Au | `perk:solidgold` | Solid Gold | Solid gold |
| 80 | Mercury | Hg | `perk:quickhands` | Quick Hands | Quicksilver |
| 81 | Thallium | Tl | `perk:slowcloth` | Slow Cloth | Heavy and slow |
| 82 | Lead | Pb | `perk:laststripe` | Last Stripe | Where radioactive decay ends: the last stop |
| 83 | Bismuth | Bi | `perk:lastsolid` | Last Solid | The heaviest element with a stable form |
| 84 | Polonium | Po | `perk:lastcall` | Last Call | A poisoned last drink: last call |
| 85 | Astatine | At | `perk:glasscannon` | All In | The rarest natural element: all in |
| 86 | Radon | Rn | `perk:bigbreak` | Big Break | Breaks apart in a big way |
| 87 | Francium | Fr | `perk:followthru` | Follow Through | Fr, follow through |
| 88 | Radium | Ra | `perk:tracer` | Tracer | It glows: a tracer |
| 89 | Actinium | Ac | `perk:highball` | High Roller | A high atomic number, for balls 13 to 15 |
| 90 | Thorium | Th | `perk:stun` | Stun Master | Thor's hammer stuns |
| 91 | Protactinium | Pa | `perk:packrat` | Pack Rat | Pa, Pack rat |
| 92 | Uranium | U | `perk:power` | Power Stroke | Power |
| 93 | Neptunium | Np | `perk:overflow` | Overflow | Neptune's waters overflow |
| 94 | Plutonium | Pu | `perk:trouble` | Trouble Maker | Nothing but trouble |
| 95 | Americium | Am | `perk:afterimage` | Afterimage | Its glow lingers |
| 96 | Curium | Cm | `perk:corner` | Corner Man | Cm, the Corner Man |
| 97 | Berkelium | Bk | `perk:afterburner` | Break Artist | Bk, the break |
| 98 | Californium | Cf | `perk:moneyball` | Big Numbers | The biggest number in the set |
| 99 | Einsteinium | Es | `perk:enchanter` | Enchanter | Isotopes are Einstein's business |
| 100 | Fermium | Fm | `perk:fibonacci` | Lucky Numbers | For the numbers game |

**Temporary symbols to replace** (these non-Element cards clashed with a real element symbol):

| Card | Temporary symbol |
|---|---|
| `imbue:vein` | Vx |
| `ball:gold` | Gx |
| `imbue:heavy` | Hx |
| `imbue:glass` | Gq |
| `imbue:ember` | Ex |
| `imbue:pawned` | Px |
| `imbue:frosted` | Fx |
| `imbue:charged` | Cx |
| `imbue:prismatic` | Rq |
| `imbue:hollow` | Hq |
| `imbue:leaded` | Lx |
| `ball:iron` | Ix |
| `ball:magnet` | Mx |
| `ball:prism` | Pq |
| `ball:clock` | Cq |
| `ball:star` | Sx |
| `ball:heart` | Hj |
| `ball:moon` | Mq |
| `ball:eraser` | Eq |
| `ball:comet` | Cj |
| `item:centremass` | Cz |
| `item:englishdial` | Tx |
| `item:reflection` | Rx |

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

## Tables: art and music needed (the 40 science boards)

The full list of boards, with each one's felt, rails and decal, is in [docs/TABLES_SCIENCE.md](../TABLES_SCIENCE.md).

**Built so far:** The Hypotenuse (triangle), Benzene Ring (hexagon), Golden Pentagon and The L-Shell. Each has its shape and its own track. The others are still to come.

### Art

1. **A decal for every board:** 40 faint line drawings that sit on the felt (a hexagon ring, a² + b² = c², a parabola and its focus, a Möbius loop and so on; see the "Decal" column). Keep them simple, single-colour and low contrast, because the game draws them at about 6% opacity.
2. **Sharks**, as sprites seen from above, with a "hit" flash and a knocked-out state:
   - **Pool Shark:** grey, circles a ball.
   - **Card Sharp:** wears a visor and holds cards; sits in a pocket mouth.
   - **Loan Shark:** pinstripe suit, with a $ on its fin.
   - **Hammerhead:** charges in a line.
   - **Leech:** small; clamps onto a ball.
   - **Great White:** final boss, with a health bar.
3. **Moving parts:** the Clockwork **Sweeper** (a clock hand), the **pendulum bob** (Foucault), sliding **shuttle posts**, a **turntable** (Coriolis), a **conveyor** strip (Gulf Stream), **Maxwell's Demon** at its gate, a **see-saw rail** (The Lever) and a **charged rail** glow (Capacitor).
4. **Rail materials:** most boards change only their colours, but a few want a texture: brushed chrome, copper pipe, black glass, marble, gilded and obsidian.

### Music: tracks still to make

Every board has its own loop, made by `tools/compose_score.py` (no samples; melodies come from maths sequences). There are 26 tracks now.

- **Already have a track:** The Local, Pinball Parlor, The Clockwork Table (was the Element Table), The Hypotenuse, Benzene Ring, Golden Pentagon, The L-Shell.
- **Reworked boards keep their old track** (rename the file and title): Superfluid ← Black Ice, Harmonic Oscillator ← Twin Posts, Event Horizon ← The Sinkhole, Kepler Orbit ← The Magnet Room, Lotka–Volterra ← The Smoke Room, Faraday Cage ← The Back Room, Capacitor ← Spring Street, Coriolis ← The Drift, Snell's Law ← The Tilted Table, Quantum Pockets ← Two Pockets, Radioactive Decay ← Closing Time, Apex Predator ← The Grand Final.
- **New tracks needed (21):** Venturi, Einstein–Rosen Bridge, Parabolic Mirror, Whispering Gallery, Semipermeable Membrane, Sierpinski Triangle, Möbius Strip, Maxwell's Demon, Chain Reaction, Lorentz Field, Foucault's Pendulum, Galton Board, Golden Spiral, Tesla Coil, Gulf Stream, Meissner Effect, Tectonic Plates, Crystal Lattice, Stellated Star, The Lever, Escape Velocity.
- **Retired tracks** (their boards are going), which can be deleted or reused: Frozen Lake, Old Slate, The Hump, Rotation Night, The Iron Rack, Lights Out, The Hustler.

To add one, copy an entry in `BOARDS` in `tools/compose_score.py`, give it a new title, sequence, key, mode and tempo, then run `py -3.12 tools/compose_score.py <board id>`. Then add the file to `TRACKS` in `src/audio/sfx.gd`.

### Music: making the tracks smaller

The tracks are the biggest part of the app: about 67 MB now, and about 100 MB at 40 boards. Each is a 3–4 minute stereo Ogg Vorbis at quality 2.5 (about 2.6 MB).

1. **Lower the quality** (biggest win, hardly audible on a phone): render at quality 0 instead of 2.5, about 64 kbps and roughly 40% smaller.
   `py -3.12 tools/compose_score.py --quality 0`
2. **Re-encode the existing files without re-rendering** (needs ffmpeg). This makes `-small.ogg` copies; check them, then replace the originals.
   ```bash
   for f in assets/music/boards/*.ogg; do ffmpeg -y -i "$f" -c:a libvorbis -q:a 0 "${f%.ogg}-small.ogg"; done
   ```
3. **Shorter loops:** 32 bars instead of 64 halves every file. The song form is in the script's header (intro, groove, build, drop and so on); drop the second groove, build and drop.
4. **Mono** (`-ac 1` in the ffmpeg line) halves it again, at the cost of stereo width. Only worth it if the size is still too big after steps 1–3.

Quality 0 plus 32-bar loops would bring 40 tracks to about 30 MB in all.

## Symbol rules

**Elements now use their real chemical symbols** (see above). These rules apply to every other card, which must also avoid every real symbol from H to Fm.

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
