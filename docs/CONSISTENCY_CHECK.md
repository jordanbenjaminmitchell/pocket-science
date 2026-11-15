# Consistency check (2026-11-15)

Checked 891 player-facing texts: every Element, Catalyst, Isotope, Exotic ball, cue, board, side bet, discovery, glossary entry and card stat, plus the UI strings in `src/`. The rules checked are the game's own words, numbers matching between card and description, names, prices and the docs.

The main checks are now a test, `tests/test_wording.gd`, so new content can't drift again. It fails on old words (pot, drop, perk, imbue, item, special ball, consumable), on two things sharing a name, on an Element whose name or card symbol doesn't match its atomic number, and on a cue whose description doesn't name its money, Catalyst or ball.

## Fixed

| What | Before | Now |
|---|---|---|
| Absolute Zero (Catalyst) | "…at the lip of a pocket drops in" | "…sinks" (card: "Stop; lips sink") |
| Hydrogen Balloon (Element) | "if it would drop into a pocket" | "if it would sink, it bobs back out of the pocket" |
| Damping (Catalyst) | "The cue ball drops to a quarter of its speed" | "slows to a quarter" |
| Weighted Isotope | "Any miss drops it back to ×3" | "resets it to ×3" |
| Two things called **Event Horizon** | the Catalyst `pocketcover` and the board `sinkhole` | the board is now **Accretion Disc** (its art and music keep their files) |
| Glossary: Element | "A passive item that sits in one of your six slots." | "A rule named for a real chemical element that stays with you all run, in one of your six slots." |
| First-shop tip for Catalysts | "Items. Tools keep a charge every table; Consumables are used once…" (there are no consumables any more) | "Catalysts. Each one recharges every table…" plus what grey ones do |
| Pause hints (3 places) | "use an item", "Items in your bar" | "use a Catalyst", "Catalysts in your Hustler's Kit" |
| Achievement | "Use 5 items in total" | "Use 5 Catalysts in total" |
| Card stats said "rail", descriptions said "cushion" | 5 cards | all say "cushion" (Charged Isotope says "a bank", to fit 17 letters) |
| README | 16 Isotopes, 23 Catalysts, "Value: 10 plus the ball's number" | 30, 30, "10 + 2 × the ball's number" |
| Exotic balls (1.49) | 23 of 30 didn't say their worth; values 0–105 with no rule | all say "Worth…"; base 30 |

## Checked and fine

- All 100 Elements are named for the element of their atomic number, each number is used once, and every card shows the right symbol.
- No other names clash across Elements, Catalysts, Isotopes, Exotic balls, cues and boards.
- "Pay" is only used for money and "score" only for points: side bets "pay double" in money.
- Every cue's description names its starting money, Catalyst and ball.
- The README's Chalk rules match the code: 6 to start, at most 12, a miss costs 1, a scratch or early 8 costs 2, a cleared table gives 1.
- Card stats that look different from the description are rounding or words for numbers ("×1.6" for 1.618, "2 to 4" for "two to four"), not errors.

## For you to decide (not changed)

1. **Three Elements cost $2 more than the rest of their rarity:**
   - Titanium Jaws: common, $6 (most commons are $4).
   - Aluminium Ore: uncommon, $8 (most are $6).
   - Tellurium Supply: rare, $10 (most are $8).

   Jaws (every pocket 20% wider) and Supply (a free Catalyst every table) are strong enough to justify it. Aluminium Ore is the odd one, and $6 looks right for it.
2. **The Accretion Disc board doesn't do what the science plan says.** `docs/TABLES_SCIENCE.md` describes a black hole that grows each shot and scores ×2 into it but costs Heat. The game has a fixed gravity well with "Chain starts at 2". Either update the board, or update the doc to match.
3. **`docs/TABLES_SCIENCE.md` lists 40 boards; the game has 42.** Game of Life and Schrödinger's Cat are missing from the doc, and one row is still titled "Black Ice → Superfluid".
4. **Price spread:** Catalysts mostly cost $5–6 (one $4, one $9), Isotopes $3–5, Exotic balls $4–6. That's sensible. The outliers are worth a look in the playtest, not a change by math alone.
