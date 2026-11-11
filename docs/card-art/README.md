# Card art: periodic-table tiles

The art for Pro Shop offer cards. Each card is drawn as a periodic-table tile: a big symbol (a real element's where one fits the name), the card's name, its headline effect, and what it acts on. Each symbol has its own lettering effect.

**Status:** all 100 perks are done. Imbues, special balls and items have one sample each (Vein, Gold, Second Strike, Trapdoor). The game doesn't show the tiles yet; `_offer_card` in `src/main.gd` still draws the old cards.

## In this folder

| File | What it is |
| --- | --- |
| `perk-tiles-1.png` … `perk-tiles-5.png` | Every perk tile at 2× size, 20 per sheet |
| `code/tile_art.gd` | Copy of `src/ui/tile_art.gd`: tile data (`TILES`), layout, all lettering effects and the pattern shader |
| `code/tile_preview.gd` | Copy of `tools/tile_preview.gd`: renders the preview sheets |
| `code/test_tiles.gd` | Copy of `tests/test_tiles.gd`: checks every perk has a tile, symbols and effects are unique, and stats fit |

The files in `code/` are **copies made on 2026-11-11**. The game uses the originals at the paths above, so edit those. The `.gdignore` file here keeps Godot from loading anything in this folder; otherwise the duplicate `TileArt` class would clash with the real one.

## What the code needs from the game

- `Catalog` (`src/game/catalog.gd`): perk names, rarities, families, and the imbue, ball and item lists
- `IconArt` (`src/ui/icon_art.gd`): the small top-right icons and the family colours
- Fonts: `assets/fonts/ChakraPetch-SemiBold.ttf` and `ChakraPetch-Regular.ttf`

## Rendering the sheets again

Run from the project folder. The preview opens a window, so don't use `--headless`.

```bash
PS_TILE_SET=perks PS_TILE_ZOOM=2 godot --path . --script res://tools/tile_preview.gd -- docs/card-art/perk-tiles.png
```

`PS_TILE_ONLY=side,velvet` renders only the listed perks. Without `PS_TILE_SET`, the tool renders the five sample cards as full shop cards.
