# Choosing your next table: ideas that aren't a Slay the Spire map

Today a run is a fixed plan of nine tables, and the Pro Shop names the next one. The open question is whether you should get a say in which board comes next. These ideas avoid a branching node map. Each one ties the choice to something Pocket Science already has: science, pool halls, Heat, side bets or the shop.

## The ideas

| # | Idea | How it works | Why it fits | Cost to build |
|---|---|---|---|---|
| 1 | **Experiment proposals** | After the shop, two "grant proposals" are offered for the next table. Each is a board plus a deal: "Kepler Orbit, target +20%, pays $8" or "Superfluid, target −10%, pays $3". You sign one. | It reads as running a lab, not walking a map. The choice is about risk and reward, so it isn't only a board preference. | Small: two cards in the shop and a target and payout modifier |
| 2 | **Hypothesis and result** | Before the next table, you predict which of two boards you'll beat by more. Both are shown, and you play the one you named. If you clear it with overkill, the hypothesis is "confirmed" for a bonus (+1 Chalk or a free reroll). | It turns picking into a bet on yourself, which echoes side bets. | Small to medium |
| 3 | **The pool hall circuit** | A run is three halls of three tables. Each hall has a theme: shapes, Sharks or fields. At the start of each hall, you choose which hall comes next. The tables inside a hall are fixed. | It's three big decisions instead of nine small ones, and you can always see what's coming. Halls also make good music and art groupings. | Medium: the plan becomes three blocks |
| 4 | **Draft the tour** | At the start of the run, you see 12 boards and remove three. The rest are ordered by difficulty. | All the strategy happens up front, so play between tables stays quick. It suits players who plan builds. | Small |
| 5 | **Heat decides** | You don't pick. How you clear a table steers the next one: a big overkill sends you to a harder board with a richer shop, and a narrow clear sends you to a gentler board. | It's invisible and rewards good play with challenge. Nothing is copied. | Small, but it removes the choice from the player |
| 6 | **Elements pull boards** | The Elements you hold make related boards more likely to come up. Magnets draw Kepler Orbit and Lorentz Field; Heat cards draw Event Horizon. The shop shows "Your Elements are drawing: ..." | The build shapes the run, so there's no extra menu. | Small: a weighting on the table draw |

## Recommendation

**1 (Experiment proposals), with a pinch of 6.**

- **One screen, one decision, no map.** You already visit the shop between tables.
- **It's a real trade-off.** You choose an easier board with less money, or a harder one with more. A board you'd love for your build can still be a bad deal.
- **It's on theme.** Proposals, grants and targets sound like a lab.
- **It builds on what's there.** It reuses the shop's "Next table" row (which now shows a board picture) and `RunState.plan`. Pick the second proposal by weighting the draw towards boards your Elements like (idea 6).
- **It isn't a branching map.** Nothing about it copies Slay the Spire's structure.

**Open details to decide:**
- How far apart the two deals should be. A starting point: ±15% target and ±$3 to $5 payout.
- Whether the fixed boss tables (the Clockwork Table at table 5 and the final) skip the choice.
- Whether a Catalyst or Element could reveal a third proposal.

Tell me which idea you like, or mix them, and I'll build it.
