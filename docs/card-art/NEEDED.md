# Card art still needed

All 100 Perk tiles are done. These cards still need art. Match the style of the existing tiles in `src/ui/tile_art.gd`: each card needs a **symbol** (1–2 letters, never the same as another card; see the symbol rules below), a short **stat** (the headline effect, about 16 characters at most), and a **lettering effect** for the symbol that hints at what the card does.

Existing tile keys look like `"imbue:vein"`, `"ball:gold"` and `"item:trapdoor"`. Use the ID column below in the same way.

## Symbol rules

1. **Use a real element symbol only when it genuinely fits the name.** Gold is **Au**, Iron is **Fe**, Silver would be **Ag**. The symbol should still make sense to someone who knows the element.
2. **Otherwise, for a name of two or more words, use the first letter of the first two words, both capitals.** Follow Through is **FT**, Called Shot is **CS**, Pop-up Wall is **PW**, Ball in Hand is **BH** (skip small words like "in", "of", "the").
3. **For a one-word name with no fitting element, use its first letter, or its first two letters if that letter is taken** (Blink is **B**, then **Bl** if B is taken).
4. **No two cards may share a symbol.** If two names give the same initials, the newer card uses the first letter of the first word plus the next consonant of the second (for example **Sd** instead of a second **SS**).

## Particle effects (optional, per card)

Many cards can have a small animated particle effect: embers for Heat cards, sparkles for Gold, frost for Frosted, bubbles for Simmer and so on. Keep each effect small and tied to what the card does.

**Rule:** every particle effect must check `Fx.minimal_particles` (in `src/ui/fx.gd`) and draw nothing when it is true. That switch is on when the player sets **Particles: minimum** or **Reduced motion** in Settings. The still tile art (symbol, lettering, stat) must look complete without the particles.

## Imbues: 19

| Name | ID | What it does |
|---|---|---|
| Spark | `imbue:spark` | +1 Chain every time it is struck. Struck 3 or more times in one shot, it overloads and arcs onto the last ball it hit. |
| Gilded | `imbue:gold` | Pays $1 when sunk, plus $1 for every table in a row you have sunk it (up to $5). A table where it stays up resets the streak. |
| Weighted | `imbue:heavy` | Worth 10 + 3 × its number, and the number counts one more time with every sink (×4, ×5...). Any miss drops it back to ×3. |
| Hairline | `imbue:glass` | Scores ×3 when sunk, but the coating may crack off: 1 in 4 the first time, 2 in 4 the next, then 3 in 4. |
| Kindled | `imbue:ember` | +2 Heat when sunk. But while it is still on the table, a miss wipes your Heat to 0 instead of halving it. |
| Lucky | `imbue:lucky` | 1 in 2 chance to score ×2 when sunk. If it misses, Lucky jumps to another ball with no Imbue and the next win scores ×3, then ×4, and so on. |
| Volatile | `imbue:volatile` | The first time anything hits this ball it explodes: it counts as sunk (points and Heat), but it leaves your set for good. |
| Jinxed | `imbue:jinxed` | Scores ×4 when sunk, but sinking it halves your Heat. |
| Mirror | `imbue:mirror` | Scores what the ball that hit it is worth instead of its own value: a low ball struck by the 15 scores like the 15. |
| Pawned | `imbue:pawned` | Pays $4 when sunk instead of any points. |
| Frosted | `imbue:frosted` | When it sinks, your next miss on this table keeps your Heat. |
| Magnetic | `imbue:magnetic` | Pockets pull this ball in. |
| Charged | `imbue:charged` | +0.5 Chain every time this ball touches a cushion. |
| Resonant | `imbue:prismatic` | Every ball it touches in a shot adds +0.25 Chain. |
| Hollow | `imbue:hollow` | Half the weight: it flies further when struck. |
| Leaded | `imbue:leaded` | Twice as heavy, and worth +45. |
| Bounty | `imbue:bounty` | Pays $1 for every point of Heat when it sinks, then cashes out 2 Heat. |
| Starry | `imbue:starry` | Every ball after it in the same shot gets +0.5 Chain. |
| Twin | `imbue:twin` | Its value counts twice. Then it hops to its colour twin (the 3 and the 11, the 1 and the 9...), if that one is free. |

## Special balls: 23

| Name | ID | What it does |
|---|---|---|
| Void | `ball:void` | Worth nothing itself, but every other ball in the same shot scores ×2. |
| Glass | `ball:glass` | Scores ×3 if it sinks, but anything that hits it hard shatters it, and it leaves your set. |
| Iron | `ball:iron` | Twice as heavy. Worth 70. |
| Feather | `ball:feather` | A quarter the weight: it barely moves other balls, and adds +0.5 Chain as it sinks. |
| Ember | `ball:ember` | The pocket it sinks into becomes the hot pocket. |
| Frost | `ball:frost` | Any ball that touches it stops dead. |
| Magnet | `ball:magnet` | Pulls nearby rolling balls towards itself. |
| Prism | `ball:prism` | Counts as both a solid and a stripe. |
| Wild | `ball:wild` | Copies the number of the last ball you sank, and counts as that number. |
| Clock | `ball:clock` | Worth 15, plus 9 for every shot already taken on this table. |
| Coin | `ball:coin` | Pays $1 every time the cue ball hits it in a scoring shot. |
| Bomb | `ball:bomb` | When it sinks, the nearest ball (never the 8) sinks with it. |
| Seed | `ball:seed` | Worth 30, and 15 more every time you sink it this run. |
| Clover | `ball:clover` | No shot it is part of can cost Chalk. |
| Star | `ball:star` | Comes off cushions with no loss of speed, and adds +1 Chain as it sinks. |
| Heart | `ball:heart` | If it is the only ball left on the table when you sink it, +1 Chalk. |
| Dice | `ball:dice` | Shows a new number from 1 to 15 every shot, and counts as that number. |
| Moon | `ball:moon` | Corner pockets reject it. Scores ×2 in a side pocket. |
| Sun | `ball:sun` | Side pockets reject it. Scores ×2 in a corner pocket. |
| Anchor | `ball:anchor` | Only the cue ball can move it: other balls bounce off it like a post. Worth 105. |
| Eraser | `ball:eraser` | When it sinks it pays $4, and both it and the last ball it touched leave your set (never the 8). |
| Echo | `ball:echo` | The first time it sinks on a table, it comes back to the foot spot. |
| Comet | `ball:comet` | Feels no cloth friction until it first hits a cushion. |

## Items (the Hustler's Kit): 19

| Name | ID | What it does |
|---|---|---|
| Called Shot | `item:calledshot` | Pick a ball and a pocket. If that ball sinks there on your next shot, it scores ×3. |
| Ghost Chalk | `item:ghostchalk` | Pick a ball. Your next shot passes straight through it. |
| Swap | `item:swap` | Swap the places of two balls (not the cue ball). |
| Polish | `item:polish` | Pick a ball. On your next shot it glides with no cloth friction until it first hits something. |
| Lead Weight | `item:leadweight` | Pick a ball. On your next shot it is four times as heavy. |
| Spotter | `item:spotter` | Bring a ball you sank on this table back to the foot spot. Never the 8. |
| Pocket Cover | `item:pocketcover` | Cover a pocket for the rest of this table. The pocket opposite opens 30% wider. |
| Pop-up Wall | `item:wall` | While a shot is paused, raise a short wall for the rest of the shot. |
| Blink | `item:blink` | While a shot is paused, move the cue ball anywhere. It keeps its speed and direction. |
| Freeze Frame | `item:freezeframe` | While a shot is paused, stop one ball dead. It holds still like a post for the rest of the shot. |
| Nudge | `item:nudge` | While a shot is paused, push one ball a short way in any direction. |
| English Dial | `item:englishdial` | While a shot is paused, put the spin you have set onto the rolling cue ball. |
| Gravity Pebble | `item:gravitypebble` | While a shot is paused, place a small well that bends rolling balls for the rest of the shot. |
| Rewind | `item:rewind` | Undo your last shot entirely: balls, score, Heat and Chalk. |
| Insurance Slip | `item:slip` | If your last shot cost Chalk, get it back. |
| Triangle | `item:triangle` | Re-rack every ball still on the table and break again. |
| Ball in Hand | `item:ballinhand` | Pick up the cue ball and place it anywhere. |
| Post | `item:post` | Place a bumper anywhere on this table. |
| Portal Pair | `item:portal` | Place two linked portals. A ball rolling into one comes out of the other at the same speed. |

## Side bets: 23

One card per side bet. The card is shown face down until you take or peek at the bet, so it also needs a shared **card back**. Tier colours suggested: Easy green, Medium amber, Hard red.

| Bet | ID | Tier |
|---|---|---|
| Sink a solid ball | `bet:solid` | Easy |
| Sink a striped ball | `bet:stripe` | Easy |
| Sink a ball into a corner pocket | `bet:corner` | Easy |
| Sink a ball into a side pocket | `bet:side` | Easy |
| Sink a ball into the hot pocket | `bet:hot` | Easy |
| Sink a ball on the break | `bet:breakpot` | Easy |
| Sink a ball with a power shot (85%+) | `bet:hard` | Easy |
| Sink a ball with a soft shot (35% or less) | `bet:soft` | Easy |
| Reach Heat 3 | `bet:heat3` | Easy |
| Sink 2 or more balls in one shot | `bet:double` | Medium |
| Sink a bank shot | `bet:bank` | Medium |
| Sink a combination | `bet:combo` | Medium |
| Sink a ball off a kick shot | `bet:kick` | Medium |
| Reach Heat 4 | `bet:heat4` | Medium |
| Reach Chain 5 in one shot | `bet:chain5` | Medium |
| Score a quarter of this table's target in one shot | `bet:quarter` | Medium |
| Sink 3 or more balls in one shot | `bet:triple` | Hard |
| Sink a ball off 2 cushions | `bet:bank2` | Hard |
| Reach Heat 5 | `bet:heat5` | Hard |
| Reach Chain 7 in one shot | `bet:chain7` | Hard |
| Score half of this table's target in one shot | `bet:half` | Hard |
| Sink 2 balls into the hot pocket in one shot | `bet:hot2` | Hard |
| Sink the 8 when it is the only ball left | `bet:eight` | Hard |
| (card back, shared by every face-down bet) | `bet:back` | - |

## Starting cues (optional: only if cues get cards on the cue-select screen): 15

| Name | ID | What it does |
|---|---|---|
| Classic Maple | `cue:maple` | The all-rounder. $6 to start. |
| Optic Cue | `cue:optic` | Starts with Long Lens: every predicted sink shows its points, and long sinks add Chain. $2. |
| Hot Rod | `cue:hotrod` | Starts with Scorcher (hot pocket ×3), but every table has 1 less Chalk. $4. |
| Momentum Cue | `cue:momentum` | Starts with Stoker: multi-sink shots build extra Heat. $4. |
| Gilded Cue | `cue:gilded` | Starts rich: $12 and Deep Pockets. |
| Break Cue | `cue:breaker` | Starts with Break Artist (break shots +3 Chain). $3. |
| Banker's Cue | `cue:banker` | Starts with Thrift and $8. |
| Thermal Cue | `cue:thermal` | Starts with Stay Hot: while On fire, a miss only costs 1 Heat. $3. |
| Angle Cue | `cue:angle` | Starts with Bank Manager (banks +1 Chain per cushion). $2. |
| Engineer's Cue | `cue:engineer` | Starts with Backspin Wax: draw and follow 50% stronger. $3. |
| Gear Cue | `cue:gearhead` | Starts with Pack Rat, a Second Strike and a Post. $2. |
| Lean Cue | `cue:lean` | Starts with Thin Rack, and the 1 and 2 are already out of your set. $3. |
| Black Cue | `cue:black` | Starts with Behind the 8: the 8 costs nothing and pays $3. $3. |
| Alchemist's Cue | `cue:alchemist` | Starts with a Gold ball in your set and Gold Rush: special balls score ×2. $3. |
| Glass Cue | `cue:glass` | Starts with All In (every sink ×2, misses cost 2 Chalk). 1 less Chalk. $4. |

**Total: 100 cards** (85 without the cues), including 23 side bets and their card back.
