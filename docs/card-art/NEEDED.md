# Card art: status

**All art from the 2026-11-12 brief is done.** That covers the Element tiles (atomic numbers, group colours, element looks, new names and short descriptions), the 23 temporary symbols, the Catalyst tiles, special balls drawn as balls, the starting cue tiles, the side bet cards, the table art and the music. Everything is drawn in code:

- Tiles: `TileArt` in [src/ui/tile_art.gd](../../src/ui/tile_art.gd)
- Side bet cards: `BetCard` in [src/ui/bet_card.gd](../../src/ui/bet_card.gd)
- Table art: `BoardArt` in [src/view/board_art.gd](../../src/view/board_art.gd)

The Element names and the Elements whose rules changed are in [docs/ELEMENTS_REWORK.md](../ELEMENTS_REWORK.md).

## Preview sheets (2× size)

| Sheet | What it shows |
|---|---|
| `perk-tiles-1.png` … `perk-tiles-5.png` | Every Element |
| `imbue-tiles-1.png` | Every Isotope, on balls 0–15 in turn |
| `ball-tiles-1.png`, `ball-tiles-2.png` | Every special ball |
| `item-tiles-1.png`, `item-tiles-2.png` | Every Catalyst |
| `cue-tiles-1.png` | Every starting cue |
| `bet-cards-1.png`, `bet-cards-2.png` | Every side bet card, then the back and the taken, won and passed states |
| [../table-art/](../table-art/) | Board decals, Sharks, moving parts and rail materials |

## What each brief item became

1. **Atomic numbers:** each Element tile leads with its atomic number on a chip coloured by its periodic-table group.
2. **Group colours:** ten group colours (`TileArt.GROUP_COLORS`), from alkali metals to actinides.
3. **Element looks:** every Element's letters are coloured like the element itself (`TileArt.ELEMENT_LOOK`):
   - Metals are polished and tinted to the real metal: copper, cobalt blue, caesium gold, osmium blue.
   - Gases glow like discharge tubes: neon red-orange, argon violet, xenon blue.
   - Liquids (mercury, bromine, gallium) drip.
   - Radioactive elements glow and give off particles.
   - Bismuth has a rainbow sheen. Gold keeps its gold ingot.

   Each card's own effect (the picture of what it does) stays, now drawn in the element's colours.
4. **Names:** every Element is now "element + noun", such as Hydrogen Balloon or Lead Anchor. The tile shows the real symbol.
5. **What it does:** every Element tile has a few-word description across the bottom row. The family moved up beside the rarity.
6. **Enchanter and Alchemy:** these now read **Einsteinium Lab** and **Arsenic Mutation**, so nothing sounds like magic.
7. **Element swaps:** Hydrogen and Beryllium swapped cards, so Hydrogen is the floaty one. Nothing else moved.
8. **Temporary symbols:** all replaced (tables below). Special balls show a picture of the ball, not letters, so they need no symbol.
9. **Catalysts:**
   - The tile says CATALYST, when it can be used, and "every table".
   - 17 renamed cards have new symbols.
   - Black Hole, Event Horizon and Force Field have new pictures.
   - The six new Catalysts have their own art.
   - The four removed items' art is gone.
10. **Cues:** the 13 starting cues have tiles, a picture of the cue and the object it carries. The cue-select screen still draws its own cards.
11. **Sheets:** all sheets are rendered again with the new words.

## Symbol rules

- A one-word name takes its first letter. If that is taken, it takes the first two letters. If those clash, it takes the first letter and the next consonant.
- A longer name takes the initials of its first two words. Case-only differences count as different symbols (CM and Cm).
- **No card may use a symbol an Element shows** (every real symbol from H to Fm). The tile test checks this. Symbols of elements above 100 (Cn, Rf) are allowed.
- Exhausted names fall back to initials. Inertia is **It** (In and Ir are Elements), and Conservation is **Cn** as the brief asked, now that the Coin ball has no symbol.

## Isotopes

| Isotope | Id | Symbol | Bottom line |
|---|---|---|---|
| Vein | `vein` | **Ve** | +20, spreads |
| Spark | `spark` | **Sk** | +1 Chain a hit |
| Gilded | `gold` | **G** | $1, +$1 a table |
| Weighted | `heavy` | **We** | Number ×3, ×4… |
| Hairline | `glass` | **Ha** | ×3, may crack |
| Kindled | `ember` | **Ki** | +2 Heat |
| Lucky | `lucky` | **L** | 1 in 2: ×2 |
| Volatile | `volatile` | **Vo** | Explodes on hit |
| Jinxed | `jinxed` | **J** | ×4, halves Heat |
| Mirror | `mirror` | **M** | Copies its hitter |
| Pawned | `pawned` | **Pw** | $4, no points |
| Frosted | `frosted` | **Ft** | Next miss safe |
| Magnetic | `magnetic` | **Ma** | Pockets pull it |
| Charged | `charged` | **Ch** | +0.5 Chain a rail |
| Resonant | `prismatic` | **R** | +0.25 a touch |
| Hollow | `hollow` | **Hl** | Half weight |
| Leaded | `leaded` | **Le** | ×2 weight, +45 |
| Bounty | `bounty` | **Bo** | $1 per Heat |
| Starry | `starry` | **Sy** | +0.5 to the rest |
| Twin | `twin` | **Tw** | Counts twice |

## Catalysts

| Catalyst | Id | Symbol | Bottom line |
|---|---|---|---|
| Impulse | `secondstrike` | **Im** | Hit again |
| Black Hole | `trapdoor` | **BH** | +1 pocket |
| Centre of Mass | `centremass` | **CM** | Pull together |
| Quantum Tunnel | `ghostchalk` | **QT** | Pass through |
| Entanglement | `swap` | **En** | Swap two balls |
| Zero Friction | `polish` | **ZF** | Glides free |
| Mass Shift | `leadweight` | **MS** | ×4 weight |
| Conservation | `spotter` | **Cn** | Respot a ball |
| Event Horizon | `pocketcover` | **EH** | ×2 wide |
| Force Field | `wall` | **FF** | Raise a wall |
| Superposition | `blink` | **Sp** | Move the cue |
| Inertia | `freezeframe` | **It** | Stop one dead |
| Vector | `nudge` | **Vc** | Push one ball |
| Spin Transfer | `englishdial` | **ST** | Add your spin |
| Gravity Well | `gravitypebble` | **GW** | Bends balls |
| Time Reversal | `rewind` | **TR** | Retake shot |
| Reflection | `reflection` | **Rf** | Turn back |
| Pythagorean Triple | `pythagoras` | **PT** | Triangle walls |
| Newton's Cradle | `newton` | **NC** | Take momentum |
| Fixed Point | `post` | **FP** | Place a post |
| Wormhole | `portal` | **Wh** | Linked portals |
| Golden Ratio | `goldenratio` | **GR** | Speed ×1.618 |
| Hooke's Law | `hookes` | **HL** | No speed lost |

## Table art

All of this is in [src/view/board_art.gd](../../src/view/board_art.gd), with sheets in [../table-art/](../table-art/):

- **Decals for all 40 boards** (`BoardArt.DECALS`). The table now draws the board's own decal when it has one (`TableView.set_lab(lab, board)`).
- **Felt colours** (`BoardArt.FELTS`), and which boards get a **textured rail** (`BoardArt.RAILS`).
- **Six Sharks** (`draw_shark`), each swimming, hit or knocked out. The Great White carries its health bar.
- **Eight moving parts:** the Sweeper, pendulum bob, shuttle post, turntable, conveyor, Maxwell's Demon, see-saw and charged rail.
- **Six rail materials** (`draw_rail`): chrome, copper, black glass, marble, gilded and obsidian.

The Sharks, moving parts, felts and rails are ready for the boards when they are built. Only the decals are shown in the game today.

## Music

- **21 new tracks** for the new boards, from the same generator ([tools/compose_score.py](../../tools/compose_score.py)).
- **13 tracks renamed** to their science boards, by title and file: Superfluid, Harmonic Oscillator, Event Horizon, Kepler Orbit, Lotka–Volterra, Faraday Cage, Capacitor, Coriolis, Snell's Law, Quantum Pockets, Radioactive Decay, Apex Predator and The Clockwork Table.
- **Smaller files:** every track is now a 32-bar loop (about 1:40) at Vorbis quality 0. The 47 tracks take 39 MB; the old 29 took 67 MB.
- `PS_BARS=64` and `--quality 2.5` bring back the long form.
- `Sfx.TRACKS` maps every board id to its file, including the boards not built yet.
- **Retired tracks are kept** (Frozen Lake, Old Slate, The Hump, Rotation Night, The Iron Rack, Lights Out, The Hustler), because those tables are still in the game.

## Still to do (code, not art)

- Show `BoardArt`'s Sharks, moving parts, felts and rails when those boards are built.
- If you want, show the cue tiles on the cue-select screen. `TileArt.new().setup("cue", id)` returns one.

## Rendering the sheets again

Run from the project folder; the preview opens a window, so don't use `--headless`.

```bash
PS_TILE_SET=perks PS_TILE_ZOOM=2 godot --path . --script res://tools/tile_preview.gd -- docs/card-art/perk-tiles.png
PS_TILE_SET=betcards PS_TILE_ZOOM=2 godot --path . --script res://tools/tile_preview.gd -- docs/card-art/bet-cards.png
godot --path . --script res://tools/board_preview.gd -- docs/table-art
```

`PS_TILE_SET` takes `perks`, `imbues`, `balls`, `items`, `cues`, `betcards` (the playing cards), `bets` (the old bet tiles) or `all`. `PS_TILE_ONLY=ball:void,item:post` renders only those cards.
