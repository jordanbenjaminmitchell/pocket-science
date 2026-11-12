# Card art: periodic-table tiles

The art for every Pro Shop card and side bet. Each card is drawn as a periodic-table tile: a big symbol, the card's name, its headline effect and what it acts on. Each symbol has its own lettering effect, and some cards add small moving particles. Side bets are different on purpose: portrait playing cards (`BetCard`) with a picture, the full wording with this table's real numbers, the stake and the payout.

Perks that name ball numbers (Prime Cut, Lucky Numbers, Odd Balls, Even Money, Low Ball, High Roller) float those balls beside the symbol, and `TileArt.balls_for("perk", id)` lists the balls any Perk works on. Hovering a Perk you own rings those balls on the table.

**Status:** all 189 tiles are done; see [NEEDED.md](NEEDED.md) for every symbol, the symbol rules, the particle effects and the one optional code job left (cue tiles). The Pro Shop already shows the Perk, Imbue, special ball and item tiles.

## In this folder

| File | What it is |
| --- | --- |
| `perk-tiles-1.png` … `perk-tiles-5.png` | Every Perk tile at 2× size, 20 per sheet |
| `imbue-tiles-1.png` | Every Imbue tile, on balls 0–15 in turn (0: before you choose the ball) |
| `ball-tiles-1.png`, `ball-tiles-2.png` | Every special ball tile |
| `item-tiles-1.png`, `item-tiles-2.png` | Every Hustler's Kit item tile |
| `bet-cards-1.png`, `bet-cards-2.png` | Every side bet as a playing card (example numbers: stake $8, target 215), then the card back and the taken, won and passed states |
| `code/tile_art.gd` | Copy of `src/ui/tile_art.gd`: tile data (`TILES`), layout, every lettering effect, the pattern shader and the particle layer |
| `code/bet_card.gd` | Copy of `src/ui/bet_card.gd`: the side bet playing card (`BetCard`), which works out each table's real numbers |
| `code/tile_preview.gd` | Copy of `tools/tile_preview.gd`: renders the preview sheets |
| `code/test_tiles.gd` | Copy of `tests/test_tiles.gd`: checks every card has a tile, symbols and effects are unique, and stats and names fit |

The files in `code/` are **copies made on 2026-11-12**. The game uses the originals at the paths above, so edit those. The `.gdignore` file here keeps Godot from loading anything in this folder; otherwise the duplicate `TileArt` class would clash with the real one.

## What the code needs from the game

- `Catalog` (`src/game/catalog.gd`): names, rarities, families, side bet tiers, ball colours, and the Imbue, ball and item lists
- `IconArt` (`src/ui/icon_art.gd`): the small top-right icons and the family colours
- `Fx` (`src/ui/fx.gd`): `Fx.minimal_particles` turns the particles off
- Fonts: `assets/fonts/ChakraPetch-SemiBold.ttf` and `ChakraPetch-Regular.ttf`

## Rendering the sheets again

Run from the project folder. The preview opens a window, so don't use `--headless`.

```bash
PS_TILE_SET=all PS_TILE_ZOOM=2 godot --path . --script res://tools/tile_preview.gd -- docs/card-art/tiles.png
```

`PS_TILE_SET` takes `perks`, `imbues`, `balls`, `items`, `betcards` or `all`; `PS_TILE_ONLY=ball:void,item:post` renders only the listed cards. Without `PS_TILE_SET`, the tool renders the five sample cards as full shop cards.
