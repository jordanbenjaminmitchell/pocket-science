# Table art

This folder holds preview sheets for the science boards' art. Everything is drawn in code by `BoardArt` in [src/view/board_art.gd](../../src/view/board_art.gd). The boards themselves are listed in [docs/TABLES_SCIENCE.md](../TABLES_SCIENCE.md).

| File | What it shows |
|---|---|
| `decals-1.png`, `decals-2.png` | All 40 boards, each with its felt colour, rail and decal (drawn brighter here than in the game so the line work can be checked) |
| `sharks.png` | The six Sharks, each swimming, hit and knocked out |
| `moving-parts.png` | Sweeper, pendulum bob, shuttle post, turntable, conveyor, Maxwell's Demon, see-saw and charged rail |
| `rails.png` | The six rail materials |
| `code/` | Copies of `board_art.gd` and `tools/board_preview.gd` (made 2026-11-12; edit the originals) |

## In the game

- The table already draws each board's own decal: `TableView.set_lab(lab, board)` picks `BoardArt.DECALS[board]` when the board has one.
- The Sharks, moving parts, felts and rail materials are ready for the boards when they are built.
- Each piece is a static function that draws onto any `CanvasItem`, so the table view can call it from its own `_draw`. For example, `BoardArt.draw_shark(ci, "hammer", pos, heading, 110.0, "hit", t)`.

## Rendering again

The preview opens a window, so don't use `--headless`:

```bash
godot --path . --script res://tools/board_preview.gd -- docs/table-art
```
