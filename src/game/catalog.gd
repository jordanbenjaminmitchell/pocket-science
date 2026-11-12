class_name Catalog
extends RefCounted
## All authored content: Perks, Imbues, Cues and the boss tables.

const BALL_COLORS := {
	0: Color(0.96, 0.95, 0.9),
	1: Color(0.98, 0.78, 0.1), 2: Color(0.1, 0.28, 0.85), 3: Color(0.88, 0.12, 0.12),
	4: Color(0.42, 0.16, 0.62), 5: Color(1.0, 0.45, 0.05), 6: Color(0.05, 0.55, 0.25),
	7: Color(0.55, 0.12, 0.1), 8: Color(0.06, 0.06, 0.07),
	9: Color(0.98, 0.78, 0.1), 10: Color(0.1, 0.28, 0.85), 11: Color(0.88, 0.12, 0.12),
	12: Color(0.42, 0.16, 0.62), 13: Color(1.0, 0.45, 0.05), 14: Color(0.05, 0.55, 0.25),
	15: Color(0.55, 0.12, 0.1),
}

const PRIMES := [2, 3, 5, 7, 11, 13]
## Dropping the 8 while other balls remain costs this share of the table's target.
const EIGHT_PENALTY := 0.15

## Perks: passive, held in six slots. "fx" is read by Scorer: when a pot meets
## "when", it gains "value" (points), "chain" (before paying) or "x" (a multiplier),
## and pays "money". "r": rarity 0 common, 1 uncommon, 2 rare.
const PERKS := {
	"elastic": {"name": "Loud Table", "r": 0, "cost": 4, "fam": "combo", "desc": "Every ball-to-ball hit adds +0.25 extra Chain."},
	"odd": {"name": "Odd Balls", "r": 0, "cost": 4, "fam": "number", "desc": "Odd-numbered balls are worth +20.", "fx": {"when": "odd", "value": 20}},
	"even": {"name": "Even Money", "r": 0, "cost": 4, "fam": "number", "desc": "Even-numbered balls add +0.75 Chain as they sink.", "fx": {"when": "even", "chain": 0.75}},
	"stripes": {"name": "Stripes", "r": 0, "cost": 5, "fam": "stripe", "desc": "Striped balls score ×1.5.", "fx": {"when": "stripe", "x": 1.5}},
	"solids": {"name": "Solids", "r": 0, "cost": 5, "fam": "solid", "desc": "Solid balls are worth +35.", "fx": {"when": "solid", "value": 35}},
	"corner": {"name": "Corner Man", "r": 0, "cost": 4, "fam": "pocket", "desc": "Corner pockets add +0.5 Chain as the ball sinks.", "fx": {"when": "corner", "chain": 0.5}},
	"side": {"name": "Side Door", "r": 0, "cost": 5, "fam": "pocket", "desc": "Side pockets score ×2.", "fx": {"when": "side", "x": 2.0}},
	"lever": {"name": "Long Game", "r": 0, "cost": 5, "fam": "utility", "desc": "Long sinks (the ball travels 450+) score ×1.5.", "fx": {"when": "long", "x": 1.5}},
	"chalk": {"name": "Spare Chalk", "r": 0, "cost": 5, "fam": "utility", "desc": "+1 Chalk on every table."},
	"jaws": {"name": "Wide Jaws", "r": 0, "cost": 6, "fam": "pocket", "desc": "Pockets are 12% wider."},
	"lens": {"name": "Long Lens", "r": 0, "cost": 4, "fam": "utility", "desc": "Long sinks (the ball travels 450+) add +1 Chain.", "fx": {"when": "long", "chain": 1.0}},
	"bank": {"name": "Bank Manager", "r": 1, "cost": 6, "fam": "bank", "desc": "Bank sinks add +1 Chain per cushion."},
	"kick": {"name": "Kick Drum", "r": 1, "cost": 6, "fam": "cue", "desc": "Kick shots (cue hits a cushion first) score ×2 on every sink.", "fx": {"when": "kick", "x": 2.0}},
	"chain": {"name": "Daisy Chain", "r": 1, "cost": 7, "fam": "combo", "desc": "Combination sinks score ×2.", "fx": {"when": "combo", "x": 2.0}},
	"multi": {"name": "Cluster", "r": 1, "cost": 6, "fam": "combo", "desc": "Every ball after the first in a shot adds +1 Chain as it sinks.", "fx": {"when": "extra", "chain": 1.0}},
	"streak": {"name": "Stoker", "r": 1, "cost": 7, "fam": "streak", "desc": "Shots that sink 2+ balls add +1 extra Heat."},
	"heat": {"name": "Scorcher", "r": 1, "cost": 6, "fam": "pocket", "desc": "The hot pocket scores ×3 instead of ×2, and balls there are worth +30.", "fx": {"when": "hot", "value": 30}},
	"power": {"name": "Power Stroke", "r": 1, "cost": 5, "fam": "cue", "desc": "Shots at 85%+ power start with +1 Chain."},
	"finesse": {"name": "Soft Touch", "r": 1, "cost": 6, "fam": "cue", "desc": "Shots at 35% power or less score ×2.", "fx": {"when": "soft", "x": 2.0}},
	"prime": {"name": "Prime Cut", "r": 1, "cost": 6, "fam": "number", "desc": "Balls 2, 3, 5, 7, 11 and 13 score ×2.", "fx": {"when": "prime", "x": 2.0}},
	"eight": {"name": "Behind the 8", "r": 1, "cost": 6, "fam": "eight", "desc": "The 8 stops costing you points, scores like any other ball, and pays $3.", "fx": {"when": "eight", "money": 3}},
	"darkhorse": {"name": "Dark Horse", "r": 2, "cost": 9, "fam": "eight", "desc": "The 8 scores ×8 when it sinks. You still lose points if it sinks early.", "fx": {"when": "eight", "x": 8.0}},
	"hushmoney": {"name": "Hush Money", "r": 0, "cost": 4, "fam": "eight", "desc": "Sinking the 8 early costs $3 instead of points."},
	"kissblack": {"name": "Kiss the Black", "r": 1, "cost": 6, "fam": "eight", "desc": "Every time a ball touches the 8, add +0.75 Chain."},
	"steerclear": {"name": "Steer Clear", "r": 0, "cost": 5, "fam": "eight", "desc": "If no ball touches the 8 during a shot, each sink adds +0.75 Chain.", "fx": {"when": "no_eight_touch", "chain": 0.75}},
	"lastcall": {"name": "Last Call", "r": 1, "cost": 6, "fam": "eight", "desc": "If the 8 is the only ball left on the table when you sink it, it scores ×5 and pays $5.", "fx": {"when": "last_eight", "x": 5.0, "money": 5}},
	"eightcount": {"name": "Eight Count", "r": 1, "cost": 6, "fam": "eight", "desc": "Every 8th ball you sink in a run scores ×3.", "fx": {"when": "eight_count", "x": 3.0}},
	"trouble": {"name": "Trouble Maker", "r": 2, "cost": 7, "fam": "eight", "desc": "When the 8 sinks early, gain +3 Heat. You still lose the points."},
	"solidgold": {"name": "Solid Gold", "r": 1, "cost": 6, "fam": "solid", "desc": "Each solid you sink pays $1.", "fx": {"when": "solid", "money": 1}},
	"bedrock": {"name": "Bedrock", "r": 1, "cost": 8, "fam": "solid", "desc": "Shots that sink only solids add +1 Heat."},
	"steadyrun": {"name": "Steady Run", "r": 1, "cost": 6, "fam": "solid", "desc": "Each solid sunk in a row on this table makes solids worth +12 more (max +96). A stripe resets it."},
	"solidsonly": {"name": "Solids Only", "r": 2, "cost": 9, "fam": "solid", "desc": "Solids score ×3, but stripes score ×0.5."},
	"lastsolid": {"name": "Last Solid", "r": 2, "cost": 8, "fam": "solid", "desc": "When you sink the only solid left on the table, it scores ×8.", "fx": {"when": "last_solid", "x": 8.0}},
	"racing": {"name": "Racing Stripe", "r": 1, "cost": 6, "fam": "stripe", "desc": "Stripes sunk at 60% power or more score ×2.", "fx": {"when": "stripe_hard", "x": 2.0}},
	"luckystripe": {"name": "Lucky Stripe", "r": 1, "cost": 6, "fam": "stripe", "desc": "Each stripe you sink has a 1 in 3 chance to score ×3 and pay $2."},
	"tiger": {"name": "Tiger Stripes", "r": 1, "cost": 7, "fam": "stripe", "desc": "Each stripe sunk in a row on this table adds +0.25 Chain to the next (max +2). A solid resets it."},
	"stripesonly": {"name": "Stripes Only", "r": 2, "cost": 9, "fam": "stripe", "desc": "Stripes score ×2, but solids score ×0.5."},
	"laststripe": {"name": "Last Stripe", "r": 2, "cost": 8, "fam": "stripe", "desc": "When you sink the only stripe left on the table, it scores ×5.", "fx": {"when": "last_stripe", "x": 5.0}},
	"gold": {"name": "Gold Rail", "r": 1, "cost": 7, "fam": "money", "desc": "Each sink pays $1 (max $3 per shot)."},
	"entropy": {"name": "Simmer", "r": 1, "cost": 6, "fam": "heat", "desc": "Below Heat 3, shots start with +1 Chain."},
	"catalyst": {"name": "Snowball", "r": 2, "cost": 8, "fam": "risk", "desc": "Every ball you sink makes all balls worth +0.75 for the rest of the run."},
	"golden": {"name": "First Blood", "r": 2, "cost": 8, "fam": "risk", "desc": "The first sink of every shot scores ×2.", "fx": {"when": "first", "x": 2.0}},
	"supernova": {"name": "Clean Sweep", "r": 2, "cost": 9, "fam": "combo", "desc": "Shots that sink 3 or more balls score ×2 on every sink.", "fx": {"when": "triple", "x": 2.0}},
	"fusion": {"name": "Same Pocket", "r": 2, "cost": 8, "fam": "combo", "desc": "A second ball into the same pocket in one shot scores ×3.", "fx": {"when": "repeat_pocket", "x": 3.0}},
	"magnet": {"name": "Magnetic Pockets", "r": 2, "cost": 9, "fam": "pocket", "desc": "Pockets gently pull nearby moving balls in."},
	"insurance": {"name": "Insurance", "r": 2, "cost": 7, "fam": "utility", "desc": "The first 2 misses or scratches on each table cost no Chalk."},
	"oracle": {"name": "Second Sight", "r": 2, "cost": 10, "fam": "utility", "desc": "Before each shot, see exactly what it will score, counting every ball it knocks in."},
	"ricochet": {"name": "Ricochet", "r": 1, "cost": 6, "fam": "bank", "desc": "Every cushion a ball touches adds +0.25 extra Chain."},
	"cushion": {"name": "Soft Rails", "r": 0, "cost": 4, "fam": "bank", "desc": "Bank sinks are worth +30.", "fx": {"when": "bank", "value": 30}},
	"geometry": {"name": "Geometry", "r": 2, "cost": 8, "fam": "bank", "desc": "Bank sinks score ×1.5 for every cushion the ball touched (×2.25 off two)."},
	"tracer": {"name": "Tracer", "r": 0, "cost": 4, "fam": "bank", "desc": "Every cushion the cue ball touches after contact adds +0.25 Chain."},
	"boomerang": {"name": "Boomerang", "r": 1, "cost": 6, "fam": "cue", "desc": "If the cue ball finishes within 120 of where it started, every sink scores ×2.", "fx": {"when": "boomerang", "x": 2.0}},
	"precision": {"name": "Clean Stroke", "r": 1, "cost": 6, "fam": "cue", "desc": "Clean sinks (straight from the cue ball, no cushions) add +1 Chain.", "fx": {"when": "clean", "chain": 1.0}},
	"stun": {"name": "Stun Master", "r": 1, "cost": 6, "fam": "cue", "desc": "The cue ball loses 60% of its speed when it first hits a ball. Far fewer scratches."},
	"afterburner": {"name": "Break Artist", "r": 0, "cost": 5, "fam": "cue", "desc": "Break shots start with +3 Chain."},
	"domino": {"name": "Domino", "r": 0, "cost": 5, "fam": "combo", "desc": "Combination sinks are worth +30.", "fx": {"when": "combo", "value": 30}},
	"rhythm": {"name": "Rhythm", "r": 0, "cost": 5, "fam": "streak", "desc": "Every third shot on a table scores ×2.", "fx": {"when": "third", "x": 2.0}},
	"hothand": {"name": "Hot Hand", "r": 1, "cost": 6, "fam": "heat", "desc": "At Heat 3 or more, every ball is worth +30.", "fx": {"when": "heat3", "value": 30}},
	"comeback": {"name": "Last Chalk", "r": 1, "cost": 6, "fam": "streak", "desc": "On your last Chalk, every sink scores ×2.", "fx": {"when": "last_chalk", "x": 2.0}},
	"collector": {"name": "Grand Tour", "r": 2, "cost": 8, "fam": "pocket", "desc": "Shots start with +0.5 Chain for every different pocket used on this table."},
	"migration": {"name": "Stay Hot", "r": 1, "cost": 6, "fam": "heat", "desc": "While On fire (Heat 5+), a miss only costs 1 Heat instead of half."},
	"lowball": {"name": "Low Ball", "r": 0, "cost": 4, "fam": "solid", "desc": "Balls 1, 2 and 3 are worth +45.", "fx": {"when": "low3", "value": 45}},
	"highball": {"name": "High Roller", "r": 0, "cost": 4, "fam": "stripe", "desc": "Balls 13, 14 and 15 score ×2.5.", "fx": {"when": "high3", "x": 2.5}},
	"fibonacci": {"name": "Lucky Numbers", "r": 1, "cost": 6, "fam": "number", "desc": "Fibonacci balls (1, 2, 3, 5, 8 and 13) are worth +35.", "fx": {"when": "fib", "value": 35}},
	"rotation": {"name": "Rotation", "r": 1, "cost": 6, "fam": "number", "desc": "The lowest-numbered ball on the table scores as if it were the highest-numbered one."},
	"moneyball": {"name": "Big Numbers", "r": 1, "cost": 6, "fam": "number", "desc": "Every ball's number counts ×3 instead of ×2."},
	"thrift": {"name": "Thrift", "r": 0, "cost": 4, "fam": "money", "desc": "Clear a table with 2+ Chalk left: +$5."},
	"venture": {"name": "Deep Pockets", "r": 1, "cost": 6, "fam": "money", "desc": "Shots start with +0.25 Chain for every $5 you hold (max +1.5)."},
	"hunter": {"name": "Side Hustle", "r": 0, "cost": 4, "fam": "money", "desc": "Side bets you win pay double."},
	"coupon": {"name": "Cold Start", "r": 0, "cost": 4, "fam": "heat", "desc": "At Heat 0, every sink scores ×2.", "fx": {"when": "cold", "x": 2.0}},
	"overflow": {"name": "Overflow", "r": 1, "cost": 5, "fam": "money", "desc": "Points over a table's target carry into the next table (up to 25% of its target)."},
	"glasscannon": {"name": "All In", "r": 2, "cost": 8, "fam": "risk", "desc": "Every sink scores ×2, but misses and scratches cost 2 Chalk.", "fx": {"when": "any", "x": 2.0}},
	"minimalist": {"name": "Inferno", "r": 2, "cost": 8, "fam": "heat", "desc": "While On fire (Heat 5+), every sink scores ×2.", "fx": {"when": "on_fire", "x": 2.0}},
	"echo": {"name": "Double Take", "r": 2, "cost": 9, "fam": "risk", "desc": "The first sink of every shot scores twice."},
	"featherweight": {"name": "Featherweight", "r": 1, "cost": 6, "fam": "physics", "desc": "Object balls are 25% lighter: they fly further when struck."},
	"heavyhit": {"name": "Heavy Hitter", "r": 1, "cost": 6, "fam": "physics", "desc": "The cue ball is 30% heavier, so it drives balls further."},
	"liverails": {"name": "Live Rails", "r": 0, "cost": 5, "fam": "physics", "desc": "Cushions are 10% livelier."},
	"slowcloth": {"name": "Slow Cloth", "r": 0, "cost": 4, "fam": "physics", "desc": "Thicker cloth: balls stop 25% sooner, for tighter position."},
	"backspin": {"name": "Backspin Wax", "r": 1, "cost": 6, "fam": "physics", "desc": "Draw and follow are 50% stronger."},
	"bigbreak": {"name": "Big Break", "r": 0, "cost": 5, "fam": "physics", "desc": "Break shots hit 25% harder."},
	"longarm": {"name": "Long Arm", "r": 1, "cost": 6, "fam": "physics", "desc": "Full power hits 15% harder."},
	"masse": {"name": "Massé Master", "r": 1, "cost": 6, "fam": "cue", "desc": "English bends the cue ball twice as much off cushions."},
	"followthru": {"name": "Follow Through", "r": 0, "cost": 5, "fam": "cue", "desc": "Shots hit with follow add +0.5 Chain to every sink.", "fx": {"when": "follow_shot", "chain": 0.5}},
	"drawartist": {"name": "Draw Artist", "r": 1, "cost": 6, "fam": "cue", "desc": "Shots hit with draw score ×1.5.", "fx": {"when": "draw_shot", "x": 1.5}},
	"thinrack": {"name": "Thin Rack", "r": 1, "cost": 6, "fam": "clear", "desc": "Every ball removed from your set makes all balls worth +12."},
	"missing": {"name": "Missing Piece", "r": 1, "cost": 7, "fam": "clear", "desc": "Shots start with +0.5 Chain for each ball removed from your set (max +3)."},
	"cleanhouse": {"name": "Clean House", "r": 0, "cost": 3, "fam": "clear", "desc": "Removing a ball in the Pro Shop is free."},
	"packrat": {"name": "Pack Rat", "r": 0, "cost": 4, "fam": "gear", "desc": "+1 Catalyst slot."},
	"quartermaster": {"name": "Quartermaster", "r": 0, "cost": 4, "fam": "gear", "desc": "Catalysts cost $1 less."},
	"tinkerer": {"name": "Tinkerer", "r": 1, "cost": 6, "fam": "gear", "desc": "Every table, a random Catalyst you hold gets one extra use."},
	"enchanter": {"name": "Enchanter", "r": 0, "cost": 4, "fam": "imbue", "desc": "Isotopes cost $2 less."},
	"secondcoat": {"name": "Second Coat", "r": 1, "cost": 7, "fam": "imbue", "desc": "Isotope balls score ×1.5."},
	"goldrush": {"name": "Gold Rush", "r": 1, "cost": 6, "fam": "special", "desc": "Special balls score ×2."},
	"menagerie": {"name": "Menagerie", "r": 1, "cost": 6, "fam": "special", "desc": "Shots start with +0.25 Chain for each special ball in your set."},
	"alchemy": {"name": "Alchemy", "r": 2, "cost": 8, "fam": "special", "desc": "After each table, one plain ball in your set (never the 8) turns into a random special ball."},
	"stillness": {"name": "Stillness", "r": 1, "cost": 6, "fam": "pause", "desc": "Every time you pause a shot, it gains +0.5 Chain (max +2 a shot)."},
	"quickhands": {"name": "Quick Hands", "r": 0, "cost": 4, "fam": "pause", "desc": "The first Catalyst you use on each table doesn't spend a use."},
	"afterimage": {"name": "Afterimage", "r": 1, "cost": 6, "fam": "pause", "desc": "Impulse and Superposition each add +1 Chain to the shot."},
	"overclock": {"name": "Overclock", "r": 2, "cost": 8, "fam": "pause", "desc": "Your Catalysts get two uses on every table."},
	"velvet": {"name": "Velvet Cloth", "r": 0, "cost": 5, "fam": "physics", "desc": "30% less cloth friction: balls roll further."},
}

## Usable items, the Hustler's Kit: pool-hall props that each bend one rule of the
## table. "kind": a tool stays all run with one charge per table; a consumable is
## used once. "when": setup (aiming), pause (a shot is paused), after (the balls
## have stopped after a shot) or any.
const ITEMS := {
	# Catalysts: every one recharges each table, and every one changes the board.
	# "when": "pause" = while a shot is paused; "any" = while aiming or paused.
	"secondstrike": {"name": "Impulse", "kind": "tool", "when": "pause", "cost": 7, "desc": "While a shot is paused, hit the cue ball again."},
	"blink": {"name": "Superposition", "kind": "tool", "when": "pause", "cost": 6, "desc": "While a shot is paused, move the cue ball anywhere. It keeps its speed and direction."},
	"ghostchalk": {"name": "Quantum Tunnel", "kind": "tool", "when": "any", "cost": 5, "desc": "Pick a ball: this shot it passes straight through other balls."},
	"freezeframe": {"name": "Inertia", "kind": "tool", "when": "pause", "cost": 5, "desc": "Stop a ball dead. It holds still like a post for the rest of the shot."},
	"polish": {"name": "Zero Friction", "kind": "tool", "when": "any", "cost": 5, "desc": "Pick a ball: it glides with no cloth friction until it first hits something."},
	"gravitypebble": {"name": "Gravity Well", "kind": "tool", "when": "pause", "cost": 6, "desc": "Place a small well that bends rolling balls for the rest of the shot."},
	"portal": {"name": "Wormhole", "kind": "tool", "when": "any", "cost": 7, "desc": "Place two linked portals for this table. A ball rolling into one comes out of the other at the same speed."},
	"wall": {"name": "Force Field", "kind": "tool", "when": "pause", "cost": 5, "desc": "Raise a short wall for the rest of the shot."},
	"post": {"name": "Fixed Point", "kind": "tool", "when": "any", "cost": 5, "desc": "Place a post anywhere for the rest of this table."},
	"englishdial": {"name": "Spin Transfer", "kind": "tool", "when": "pause", "cost": 5, "desc": "Put the spin you have set onto the rolling cue ball."},
	"swap": {"name": "Entanglement", "kind": "tool", "when": "any", "cost": 6, "desc": "Two balls swap places, each keeping its own motion."},
	"nudge": {"name": "Vector", "kind": "tool", "when": "pause", "cost": 5, "desc": "Push a rolling ball a short way in any direction."},
	"leadweight": {"name": "Mass Shift", "kind": "tool", "when": "any", "cost": 5, "desc": "Pick a ball: it is four times as heavy for the rest of the shot."},
	"pocketcover": {"name": "Event Horizon", "kind": "tool", "when": "any", "cost": 6, "desc": "Pick a pocket: it swallows from twice as wide for the rest of the shot."},
	"trapdoor": {"name": "Black Hole", "kind": "tool", "when": "any", "cost": 6, "desc": "Open a pocket anywhere along a cushion for the rest of the shot."},
	"rewind": {"name": "Time Reversal", "kind": "tool", "when": "pause", "cost": 9, "desc": "Undo this shot while it rolls, and take it again."},
	"spotter": {"name": "Conservation", "kind": "tool", "when": "any", "cost": 5, "desc": "Bring a ball you sank on this table back to the foot spot. Never the 8."},
	"pythagoras": {"name": "Pythagorean Triple", "kind": "tool", "when": "any", "cost": 7, "desc": "Pick three balls: force-field walls join them into a triangle for the rest of the shot."},
	"newton": {"name": "Newton's Cradle", "kind": "tool", "when": "pause", "cost": 6, "desc": "Pick a ball: the cue ball stops dead and that ball takes all its momentum."},
	"reflection": {"name": "Reflection", "kind": "tool", "when": "pause", "cost": 5, "desc": "Pick a rolling ball: it turns round and heads straight back."},
	"goldenratio": {"name": "Golden Ratio", "kind": "tool", "when": "pause", "cost": 5, "desc": "Pick a rolling ball: its speed is multiplied by 1.618."},
	"centremass": {"name": "Centre of Mass", "kind": "tool", "when": "pause", "cost": 6, "desc": "Pick two to four balls: they all head for the point between them."},
	"hookes": {"name": "Hooke's Law", "kind": "tool", "when": "any", "cost": 5, "desc": "Pick a cushion: for the rest of the shot, anything bouncing off it keeps all its speed."},
}

const WHEN_NAMES := {"setup": "Set-up · while aiming", "pause": "While paused", "after": "Aftermath · after a shot", "any": "Aiming or paused"}
const WHEN_COLORS := {"setup": Color(0.45, 0.7, 1.0), "pause": Color(0.45, 0.95, 0.75), "after": Color(1.0, 0.72, 0.35), "any": Color(0.85, 0.85, 0.9)}


## Imbues live on one numbered ball for the rest of the run.
const IMBUES := {
	"spark": {"name": "Spark", "cost": 4, "color": Color(0.3, 1.0, 0.85), "desc": "+1 Chain every time it is struck. Struck 3 or more times in one shot, it overloads and arcs onto the last ball it hit."},
	"gold": {"name": "Gilded", "cost": 4, "color": Color(1.0, 0.82, 0.3), "desc": "Pays $1 when sunk, plus $1 for every table in a row you have sunk it (up to $5). A table where it stays up resets the streak."},
	"heavy": {"name": "Weighted", "cost": 3, "color": Color(0.75, 0.78, 0.85), "desc": "Worth 10 + 3 × its number, and the number counts one more time with every sink (×4, ×5...). Any miss drops it back to ×3."},
	"glass": {"name": "Hairline", "cost": 5, "color": Color(0.7, 0.85, 1.0), "desc": "Scores ×3 when sunk, but the coating may crack off: 1 in 4 the first time, 2 in 4 the next, then 3 in 4."},
	"ember": {"name": "Kindled", "cost": 5, "color": Color(1.0, 0.45, 0.2), "desc": "+2 Heat when sunk. But while it is still on the table, a miss wipes your Heat to 0 instead of halving it."},
	"vein": {"name": "Vein", "cost": 5, "color": Color(1.0, 0.55, 0.95), "desc": "Worth +20 when sunk, and it spreads onto the ball that knocked it in (if that ball has no Isotope)."},
	"lucky": {"name": "Lucky", "cost": 4, "color": Color(0.35, 0.95, 0.5), "desc": "1 in 2 chance to score ×2 when sunk. If it misses, Lucky jumps to another ball with no Isotope and the next win scores ×3, then ×4, and so on."},
	"volatile": {"name": "Volatile", "cost": 4, "color": Color(1.0, 0.62, 0.0), "desc": "The first time anything hits this ball it explodes: it counts as sunk (points and Heat), but it leaves your set for good."},
	"jinxed": {"name": "Jinxed", "cost": 3, "color": Color(0.55, 0.3, 0.9), "desc": "Scores ×4 when sunk, but sinking it halves your Heat."},
	"mirror": {"name": "Mirror", "cost": 4, "color": Color(0.8, 0.95, 0.95), "desc": "Scores what the ball that hit it is worth instead of its own value: a low ball struck by the 15 scores like the 15."},
	"pawned": {"name": "Pawned", "cost": 2, "color": Color(0.85, 0.7, 0.45), "desc": "Pays $4 when sunk instead of any points."},
	"frosted": {"name": "Frosted", "cost": 4, "color": Color(0.7, 0.92, 1.0), "desc": "When it sinks, your next miss on this table keeps your Heat."},
	"magnetic": {"name": "Magnetic", "cost": 5, "color": Color(1.0, 0.35, 0.35), "desc": "Pockets pull this ball in."},
	"charged": {"name": "Charged", "cost": 4, "color": Color(1.0, 1.0, 0.45), "desc": "+0.5 Chain every time this ball touches a cushion."},
	"prismatic": {"name": "Resonant", "cost": 4, "color": Color(0.95, 0.6, 1.0), "desc": "Every ball it touches in a shot adds +0.25 Chain."},
	"hollow": {"name": "Hollow", "cost": 3, "color": Color(0.85, 0.85, 0.75), "desc": "Half the weight: it flies further when struck."},
	"leaded": {"name": "Leaded", "cost": 4, "color": Color(0.5, 0.55, 0.65), "desc": "Twice as heavy, and worth +45."},
	"bounty": {"name": "Bounty", "cost": 4, "color": Color(0.6, 1.0, 0.4), "desc": "Pays $1 for every point of Heat when it sinks, then cashes out 2 Heat."},
	"starry": {"name": "Starry", "cost": 5, "color": Color(1.0, 0.85, 0.55), "desc": "Every ball after it in the same shot gets +0.5 Chain."},
	"twin": {"name": "Twin", "cost": 4, "color": Color(0.5, 0.65, 1.0), "desc": "Its value counts twice. Then it hops to its colour twin (the 3 and the 11, the 1 and the 9...), if that one is free."},
}

## Special balls you can add to your set. They rack with the numbered balls and
## count as neither solids nor stripes unless they say so. Each has its own
## finish ("pattern" in the ball shader), colours and emblem.
const BALL_TYPES := {
	"gold": {"name": "Gold", "cost": 6, "value": 45, "color": Color(1.0, 0.78, 0.2), "accent": Color(1.0, 0.96, 0.62), "pattern": 1, "motif": "t 0 0 34 $", "desc": "Worth 45, and pays $1 for every cushion it touched before sinking."},
	"void": {"name": "Void", "cost": 7, "value": 0, "color": Color(0.12, 0.03, 0.2), "accent": Color(0.62, 0.25, 1.0), "pattern": 2, "motif": "c 0 0 26;c 0 0 14;C 0 0 5", "desc": "Worth nothing itself, but every other ball in the same shot scores ×2."},
	"glass": {"name": "Glass", "cost": 6, "value": 30, "color": Color(0.7, 0.9, 1.0), "accent": Color(1.0, 1.0, 1.0), "pattern": 3, "motif": "o 0 -30 22 -8 0 30 -22 -8 0 -30", "desc": "Scores ×3 if it sinks, but anything that hits it hard shatters it, and it leaves your set."},
	"iron": {"name": "Iron", "cost": 5, "value": 70, "color": Color(0.45, 0.47, 0.52), "accent": Color(0.78, 0.8, 0.85), "pattern": 1, "motif": "P -26 -14 26 -14 18 0 10 0 14 18 -14 18 -10 0 -18 0", "desc": "Twice as heavy. Worth 70."},
	"feather": {"name": "Feather", "cost": 4, "value": 40, "color": Color(0.95, 0.95, 0.98), "accent": Color(0.55, 0.7, 1.0), "pattern": 4, "motif": "l -24 26 22 -22;o -14 16 -12 -10 18 -24 8 6 -14 16", "desc": "A quarter the weight: it barely moves other balls, and adds +0.5 Chain as it sinks."},
	"ember": {"name": "Ember", "cost": 5, "value": 35, "color": Color(0.9, 0.3, 0.05), "accent": Color(1.0, 0.8, 0.2), "pattern": 5, "motif": "P 0 -32 14 -10 18 8 8 26 -8 26 -18 8 -12 -6 -6 4", "desc": "The pocket it sinks into becomes the hot pocket."},
	"frost": {"name": "Frost", "cost": 5, "value": 35, "color": Color(0.55, 0.85, 1.0), "accent": Color(1.0, 1.0, 1.0), "pattern": 6, "motif": "l 0 -30 0 30;l -26 -15 26 15;l -26 15 26 -15", "desc": "Any ball that touches it stops dead."},
	"magnet": {"name": "Magnet", "cost": 5, "value": 30, "color": Color(0.85, 0.15, 0.15), "accent": Color(0.2, 0.35, 0.95), "pattern": 7, "motif": "a 0 -4 20 0 180;l -20 -4 -20 -26;l 20 -4 20 -26", "desc": "Pulls nearby rolling balls towards itself."},
	"prism": {"name": "Prism", "cost": 5, "value": 35, "color": Color(0.9, 0.5, 0.9), "accent": Color(0.4, 0.95, 0.9), "pattern": 8, "motif": "o 0 -28 26 18 -26 18 0 -28", "desc": "Counts as both a solid and a stripe."},
	"wild": {"name": "Wild", "cost": 5, "value": 0, "color": Color(0.45, 0.1, 0.6), "accent": Color(1.0, 0.85, 0.2), "pattern": 9, "motif": "P 0 -32 8 -8 32 -8 12 6 20 30 0 14 -20 30 -12 6 -32 -8 -8 -8 0 -32", "desc": "Copies the number of the last ball you sank, and counts as that number."},
	"clock": {"name": "Clock", "cost": 5, "value": 15, "color": Color(0.1, 0.6, 0.6), "accent": Color(0.9, 1.0, 1.0), "pattern": 6, "motif": "c 0 0 26;l 0 0 0 -18;l 0 0 12 6", "desc": "Worth 15, plus 9 for every shot already taken on this table."},
	"coin": {"name": "Coin", "cost": 4, "value": 30, "color": Color(0.95, 0.75, 0.2), "accent": Color(0.65, 0.45, 0.1), "pattern": 7, "motif": "c 0 0 26;c 0 0 17", "desc": "Pays $1 every time the cue ball hits it in a scoring shot."},
	"bomb": {"name": "Bomb", "cost": 6, "value": 30, "color": Color(0.12, 0.12, 0.14), "accent": Color(1.0, 0.3, 0.2), "pattern": 4, "motif": "C 0 6 20;l 10 -12 20 -26;C 22 -28 4", "desc": "When it sinks, the nearest ball (never the 8) sinks with it."},
	"seed": {"name": "Seed", "cost": 4, "value": 30, "color": Color(0.35, 0.7, 0.25), "accent": Color(0.85, 1.0, 0.5), "pattern": 0, "motif": "l 0 30 0 -6;o 0 -6 -18 -24 -2 -20 0 -6;o 0 -6 18 -24 2 -20 0 -6", "desc": "Worth 30, and 15 more every time you sink it this run."},
	"clover": {"name": "Clover", "cost": 5, "value": 30, "color": Color(0.15, 0.62, 0.3), "accent": Color(0.7, 1.0, 0.7), "pattern": 4, "motif": "C -10 -10 10;C 10 -10 10;C -10 10 10;C 10 10 10;l 0 10 8 30", "desc": "No shot it is part of can cost Chalk."},
	"star": {"name": "Star", "cost": 5, "value": 30, "color": Color(0.98, 0.95, 0.75), "accent": Color(1.0, 0.82, 0.1), "pattern": 5, "motif": "o 0 -32 8 -8 32 -8 12 6 20 30 0 14 -20 30 -12 6 -32 -8 -8 -8 0 -32", "desc": "Comes off cushions with no loss of speed, and adds +1 Chain as it sinks."},
	"heart": {"name": "Heart", "cost": 6, "value": 30, "color": Color(1.0, 0.4, 0.6), "accent": Color(1.0, 0.82, 0.9), "pattern": 0, "motif": "P 0 28 -26 2 -26 -14 -14 -24 0 -12 14 -24 26 -14 26 2", "desc": "If it is the only ball left on the table when you sink it, +1 Chalk."},
	"dice": {"name": "Dice", "cost": 4, "value": 0, "color": Color(0.96, 0.96, 0.96), "accent": Color(0.15, 0.15, 0.2), "pattern": 0, "motif": "C -14 -14 5;C 14 -14 5;C 0 0 5;C -14 14 5;C 14 14 5", "desc": "Shows a new number from 1 to 15 every shot, and counts as that number."},
	"moon": {"name": "Moon", "cost": 5, "value": 35, "color": Color(0.75, 0.78, 0.86), "accent": Color(0.3, 0.32, 0.46), "pattern": 7, "motif": "a 0 0 24 60 300;a 12 0 20 100 260", "desc": "Corner pockets reject it. Scores ×2 in a side pocket."},
	"sun": {"name": "Sun", "cost": 5, "value": 35, "color": Color(1.0, 0.6, 0.1), "accent": Color(1.0, 0.92, 0.35), "pattern": 5, "motif": "C 0 0 12;l 0 -30 0 -20;l 0 20 0 30;l -30 0 -20 0;l 20 0 30 0;l -21 -21 -14 -14;l 14 14 21 21;l -21 21 -14 14;l 14 -14 21 -21", "desc": "Side pockets reject it. Scores ×2 in a corner pocket."},
	"anchor": {"name": "Anchor", "cost": 6, "value": 105, "color": Color(0.1, 0.18, 0.4), "accent": Color(0.6, 0.7, 0.9), "pattern": 1, "motif": "l 0 -24 0 26;c 0 -29 5;a 0 4 22 20 160;l -12 -14 12 -14", "desc": "Only the cue ball can move it: other balls bounce off it like a post. Worth 105."},
	"eraser": {"name": "Eraser", "cost": 3, "value": 15, "color": Color(1.0, 0.55, 0.6), "accent": Color(0.4, 0.5, 1.0), "pattern": 9, "motif": "o -26 8 6 -24 26 -4 -6 28 -26 8;l -10 -8 10 12", "desc": "When it sinks it pays $4, and both it and the last ball it touched leave your set (never the 8)."},
	"echo": {"name": "Echo", "cost": 6, "value": 30, "color": Color(0.55, 0.3, 0.85), "accent": Color(0.9, 0.8, 1.0), "pattern": 6, "motif": "C -14 0 7;a -14 0 20 -50 50;a -14 0 32 -40 40", "desc": "The first time it sinks on a table, it comes back to the foot spot."},
	"comet": {"name": "Comet", "cost": 5, "value": 40, "color": Color(0.2, 0.5, 1.0), "accent": Color(0.9, 0.95, 1.0), "pattern": 9, "motif": "C 14 -14 10;l 4 -4 -30 30;l 8 4 -20 30;l -4 -8 -30 20", "desc": "Feels no cloth friction until it first hits a cushion."},
}

## Which special type each ball number above 15 is, for this run. RunState keeps
## it in step, so every view and rule can look a special ball up by number.
static var kinds := {}
## Dice and Wild balls: the number each one currently shows.
static var faces := {}


static func kind_of(n: int) -> String:
	return kinds.get(n, "") if n > 15 else ""


static func is_solid(n: int) -> bool:
	return n >= 1 and n <= 7


static func ball_label(n: int) -> String:
	var k := kind_of(n)
	return BALL_TYPES[k].name + " ball" if k != "" else "%d-ball" % n


## Starting cues: each run begins by choosing one. "shaft"/"butt"/"accent" colour the stick.
const CUES := {
	"maple": {"name": "Classic Maple", "desc": "The all-rounder. $6 to start.", "money": 6, "perks": [], "chalk": 0,
		"shaft": Color(0.86, 0.72, 0.5), "butt": Color(0.32, 0.14, 0.07), "accent": Color(0.9, 0.85, 0.7)},
	"hotrod": {"name": "Hot Rod", "desc": "Starts with Scorcher (hot pocket ×3), but every table has 1 less Chalk. $4.", "money": 4, "perks": ["heat"], "chalk": -1,
		"shaft": Color(0.85, 0.7, 0.5), "butt": Color(0.6, 0.12, 0.05), "accent": Color(1.0, 0.55, 0.1)},
	"gilded": {"name": "Gilded Cue", "desc": "Starts rich: $12 and Deep Pockets.", "money": 12, "perks": ["venture"], "chalk": 0,
		"shaft": Color(0.92, 0.82, 0.55), "butt": Color(0.45, 0.32, 0.08), "accent": Color(1.0, 0.85, 0.3)},
	"gearhead": {"name": "Gear Cue", "desc": "Starts with Pack Rat, Impulse and Fixed Point. $2.", "money": 2, "perks": ["packrat"], "chalk": 0, "tools": ["secondstrike", "post"],
		"shaft": Color(0.78, 0.82, 0.86), "butt": Color(0.12, 0.3, 0.42), "accent": Color(0.4, 0.85, 1.0)},
	"lean": {"name": "Lean Cue", "desc": "Starts with Thin Rack, and the 1 and 2 are already out of your set. $3.", "money": 3, "perks": ["thinrack"], "chalk": 0, "remove": [1, 2],
		"shaft": Color(0.9, 0.86, 0.78), "butt": Color(0.36, 0.3, 0.24), "accent": Color(0.95, 0.95, 0.9)},
	"black": {"name": "Black Cue", "desc": "Starts with Behind the 8: the 8 costs nothing and pays $3. $3.", "money": 3, "perks": ["eight"], "chalk": 0,
		"shaft": Color(0.3, 0.3, 0.32), "butt": Color(0.05, 0.05, 0.06), "accent": Color(0.82, 0.8, 0.98)},
	"alchemist": {"name": "Alchemist's Cue", "desc": "Starts with a Gold ball in your set, and Gold Rush: special balls score ×2. $3.", "money": 3, "perks": ["goldrush"], "chalk": 0, "add": ["gold"],
		"shaft": Color(0.95, 0.86, 0.6), "butt": Color(0.4, 0.2, 0.5), "accent": Color(1.0, 0.8, 0.3)},
	"glass": {"name": "Glass Cue", "desc": "Starts with All In (every sink ×2, misses cost 2 Chalk). 1 less Chalk. $4.", "money": 4, "perks": ["glasscannon"], "chalk": -1,
		"shaft": Color(0.85, 0.92, 1.0), "butt": Color(0.55, 0.7, 0.9), "accent": Color(1.0, 0.35, 0.65)},
	# Object cues: each carries one placeable object, 4 uses every table, and a Perk that plays with it.
	"posts": {"name": "Post Cue", "desc": "Carries 4 Fixed Points every table, and starts with Kick Drum: bounce the cue off a post first for ×2. $2.", "money": 2, "perks": ["kick"], "chalk": 0, "kit": "post",
		"shaft": Color(0.9, 0.78, 0.55), "butt": Color(0.5, 0.2, 0.1), "accent": Color(1.0, 0.6, 0.3)},
	"portals": {"name": "Portal Cue", "desc": "Carries 4 Wormholes every table, and starts with Boomerang: send the cue ball home for ×2. $2.", "money": 2, "perks": ["boomerang"], "chalk": 0, "kit": "portal",
		"shaft": Color(0.7, 0.75, 0.95), "butt": Color(0.25, 0.15, 0.5), "accent": Color(0.7, 0.4, 1.0)},
	"walls": {"name": "Wall Cue", "desc": "Carries 4 Force Fields every table, and starts with Bank Manager: banks off your walls build Chain. $2.", "money": 2, "perks": ["bank"], "chalk": 0, "kit": "wall",
		"shaft": Color(0.8, 0.8, 0.78), "butt": Color(0.3, 0.32, 0.35), "accent": Color(0.6, 0.9, 0.7)},
	"trapdoors": {"name": "Trapdoor Cue", "desc": "Carries 4 Black Holes every table, and starts with Soft Rails: bank sinks are worth +30. $2.", "money": 2, "perks": ["cushion"], "chalk": 0, "kit": "trapdoor",
		"shaft": Color(0.72, 0.6, 0.45), "butt": Color(0.2, 0.12, 0.06), "accent": Color(0.95, 0.75, 0.35)},
	"gravity": {"name": "Gravity Cue", "desc": "Carries 4 Gravity Wells every table, and starts with Magnetic Pockets: bend balls home. $2.", "money": 2, "perks": ["magnet"], "chalk": 0, "kit": "gravitypebble",
		"shaft": Color(0.6, 0.65, 0.75), "butt": Color(0.08, 0.08, 0.15), "accent": Color(0.45, 0.6, 1.0)},
}

## Physics and cloth for each table. Rules live on BOSSES.
const LABS := {
	"standard": {"felt": Color(0.06, 0.42, 0.28)}, "cryo": {"felt": Color(0.12, 0.42, 0.55)},
	"cyclotron": {"felt": Color(0.3, 0.2, 0.48)}, "spring": {"felt": Color(0.5, 0.14, 0.16)},
	"gravity": {"felt": Color(0.09, 0.2, 0.42)}, "current": {"felt": Color(0.05, 0.36, 0.42)},
	"magnetlab": {"felt": Color(0.42, 0.13, 0.32)}, "dense": {"felt": Color(0.2, 0.26, 0.13)},
	"pinball": {"felt": Color(0.42, 0.26, 0.07)}, "repulsor": {"felt": Color(0.12, 0.13, 0.38)},
	"element": {"felt": Color(0.24, 0.2, 0.3)}, "final": {"felt": Color(0.1, 0.1, 0.12)},
}

## Table dressing per lab: rail wood, inlay colour and a faint cloth emblem.
const LAB_ART := {
	"standard": {"rail": Color(0.30, 0.15, 0.07), "trim": Color(0.92, 0.9, 0.82), "decal": ""},
	"cryo": {"rail": Color(0.23, 0.29, 0.36), "trim": Color(0.72, 0.92, 1.0), "decal": "l 0 -40 0 40;l -35 -20 35 20;l -35 20 35 -20;o -8 -32 0 -24 8 -32;o -8 32 0 24 8 32"},
	"cyclotron": {"rail": Color(0.2, 0.15, 0.32), "trim": Color(0.75, 0.6, 1.0), "decal": "c 0 0 16;c 0 0 30;a 0 0 44 20 160;a 0 0 44 200 340"},
	"spring": {"rail": Color(0.36, 0.12, 0.1), "trim": Color(1.0, 0.75, 0.5), "decal": "o -44 0 -32 -24 -18 24 -4 -24 10 24 24 -24 36 24 46 0"},
	"gravity": {"rail": Color(0.11, 0.13, 0.27), "trim": Color(0.6, 0.72, 1.0), "decal": "c 0 0 10;c 0 0 22;c 0 0 36;c 0 0 48"},
	"current": {"rail": Color(0.13, 0.27, 0.3), "trim": Color(0.55, 0.95, 0.95), "decal": "o -44 -18 -14 -18;o -24 -30 -10 -18 -24 -6;o -12 18 20 18;o 8 6 22 18 8 30;o 18 -18 44 -18"},
	"magnetlab": {"rail": Color(0.3, 0.1, 0.22), "trim": Color(1.0, 0.6, 0.8), "decal": "a 0 4 30 0 180;l -30 4 -30 -34;l 30 4 30 -34"},
	"dense": {"rail": Color(0.2, 0.22, 0.12), "trim": Color(0.8, 0.85, 0.5), "decal": "l -40 -30 40 -30;l -40 -10 40 -10;l -40 10 40 10;l -40 30 40 30"},
	"pinball": {"rail": Color(0.38, 0.22, 0.05), "trim": Color(1.0, 0.85, 0.35), "decal": "o 0 -44 12 -14 44 -14 18 8 28 40 0 20 -28 40 -18 8 -44 -14 -12 -14 0 -44"},
	"element": {"rail": Color(0.2, 0.15, 0.26), "trim": Color(0.95, 0.8, 1.0), "decal": "c 0 -30 14;c -30 22 14;c 30 22 14;l 0 -16 -20 12;l 0 -16 20 12;l -16 22 16 22"},
	"final": {"rail": Color(0.08, 0.08, 0.1), "trim": Color(1.0, 0.82, 0.35), "decal": "c 0 0 44;c 0 -12 13;c 0 14 16"},
	"repulsor": {"rail": Color(0.12, 0.12, 0.3), "trim": Color(0.65, 0.65, 1.0), "decal": "c 0 0 12;l 0 -20 0 -44;l 0 20 0 44;l -20 0 -44 0;l 20 0 44 0;o -8 -36 0 -46 8 -36;o -8 36 0 46 8 36;o -36 -8 -46 0 -36 8;o 36 -8 46 0 36 8"},
}

## Every table is a boss. "tier" picks where it can appear; "lab" sets physics
## and art; "anomaly" names a special rule in RunState and Scorer.
const BOSSES := {
	"hypotenuse": {"name": "The Hypotenuse", "tier": 1, "lab": "standard", "anomaly": "", "shape": "hypotenuse", "desc": "A right-angled triangle: three corner pockets and one in the middle of each side. Every bank is a new angle."},
	"benzene": {"name": "Benzene Ring", "tier": 1, "lab": "standard", "anomaly": "", "shape": "benzene", "desc": "A hexagon with a pocket in every corner. Six angled rails to bank off."},
	"pentagon": {"name": "Golden Pentagon", "tier": 2, "lab": "standard", "anomaly": "", "shape": "pentagon", "desc": "A pentagon in golden-ratio proportions: five corner pockets and one in the long bottom rail."},
	"lshell": {"name": "The L-Shell", "tier": 2, "lab": "standard", "anomaly": "", "shape": "lshell", "desc": "An L-shaped table. The inside corner turns every bank into a new puzzle."},
	"local": {"name": "The Local", "tier": 0, "lab": "standard", "anomaly": "", "desc": "Your home table. The house forgives your first miss."},
	"frozen": {"name": "Frozen Lake", "tier": 1, "lab": "cryo", "anomaly": "", "desc": "Slick cloth, long rolls. On this table, every cushion a ball touches adds +0.5 Chain."},
	"spring_st": {"name": "Spring Street", "tier": 1, "lab": "spring", "anomaly": "sealed", "desc": "Lively rails, side pockets boarded up. On this table, bank sinks score ×2."},
	"drift": {"name": "The Drift", "tier": 1, "lab": "current", "anomaly": "", "desc": "Rolling balls drift right. Every sink adds +1 Chain."},
	"slate": {"name": "Old Slate", "tier": 1, "lab": "dense", "anomaly": "", "desc": "Heavy cloth stops balls fast. Every ball is worth +25."},
	"cramped": {"name": "The Back Room", "tier": 1, "lab": "standard", "anomaly": "tight", "desc": "Pockets 12% narrower, but every sink scores ×1.5."},
	"parlor": {"name": "Pinball Parlor", "tier": 2, "lab": "pinball", "anomaly": "", "desc": "Four bumpers. On this table, every bumper hit adds +1 Chain."},
	"posts": {"name": "Twin Posts", "tier": 2, "lab": "cyclotron", "anomaly": "", "desc": "Two bumpers guard the middle. On this table, every bumper hit adds +1 Chain."},
	"sinkhole": {"name": "The Sinkhole", "tier": 2, "lab": "gravity", "anomaly": "", "desc": "The centre pulls moving balls in. Chain starts at 2."},
	"hump": {"name": "The Hump", "tier": 2, "lab": "repulsor", "anomaly": "", "desc": "A rise in the cloth pushes balls away. On this table, bank sinks score ×2."},
	"nineball": {"name": "Rotation Night", "tier": 2, "lab": "standard", "anomaly": "rotation", "desc": "Hit the lowest ball first or the shot scores nothing. Legal sinks add +1 Heat."},
	"magnet": {"name": "The Magnet Room", "tier": 2, "lab": "magnetlab", "anomaly": "", "desc": "Pockets pull balls in, but every ball is worth 10 less."},
	"smoke": {"name": "The Smoke Room", "tier": 2, "lab": "dense", "anomaly": "nospin", "desc": "Stale air and a dead tip: the cue ball takes no spin here. Every sink scores ×1.5."},
	"blackice": {"name": "Black Ice", "tier": 3, "lab": "cryo", "anomaly": "blackice", "desc": "Almost no friction and lively cushions. Every sink adds +0.5 Chain."},
	"tilted": {"name": "The Tilted Table", "tier": 3, "lab": "standard", "anomaly": "tilt", "desc": "The table slopes, and a dotted line shows where balls will really roll. Every sink scores ×1.5."},
	"two": {"name": "Two Pockets", "tier": 3, "lab": "spring", "anomaly": "onepocket", "desc": "Only the hot pocket and its diagonal opposite score, and sinks there score ×2."},
	"closing": {"name": "Closing Time", "tier": 3, "lab": "standard", "anomaly": "shrink", "desc": "Every pocket narrows after each shot. Heat builds twice as fast."},
	"iron": {"name": "The Iron Rack", "tier": 3, "lab": "dense", "anomaly": "lead", "desc": "Object balls are 60% heavier. Every ball is worth +30."},
	"lights": {"name": "Lights Out", "tier": 3, "lab": "current", "anomaly": "blind", "desc": "With the lights out, no pocket runs hot. Every sink scores ×1.5."},
	"hustler": {"name": "The Hustler", "tier": 3, "lab": "magnetlab", "anomaly": "heavycue", "desc": "A heavy cue ball, and the house skims 15% of every sink."},
	"elements": {"name": "The Clockwork Table", "tier": 9, "lab": "element", "anomaly": "elements", "desc": "The pockets are numbered 1 to 6, clockwise. Sink into the next one in order to tick the clock: ticks in a row score ×1.5, ×2, ×2.5 and on. Any other pocket stops the clock."},
	"final": {"name": "The Grand Final", "tier": 9, "lab": "final", "anomaly": "cursed8", "desc": "The 8 goes last. Sink it early and lose a Chalk; sink it last for ×5."},
}

## Shaped tables: polygon corners in the 1000 x 500 frame, the six pockets in
## order ({"v": corner} or {"e": edge, "t": how far along}), and the rack's apex.
const SHAPES := {
	"hypotenuse": {"verts": [Vector2(0, 0), Vector2(1000, 500), Vector2(0, 500)],
		"pockets": [{"v": 0}, {"e": 2, "t": 0.5}, {"v": 1}, {"v": 2}, {"e": 1, "t": 0.5}, {"e": 0, "t": 0.5}], "foot": Vector2(470, 400)},
	"benzene": {"verts": [Vector2(150, 0), Vector2(850, 0), Vector2(1000, 250), Vector2(850, 500), Vector2(150, 500), Vector2(0, 250)],
		"pockets": [{"v": 0}, {"v": 1}, {"v": 2}, {"v": 3}, {"v": 4}, {"v": 5}], "foot": Vector2(700, 250)},
	"pentagon": {"verts": [Vector2(500, 0), Vector2(1000, 190), Vector2(810, 500), Vector2(190, 500), Vector2(0, 190)],
		"pockets": [{"v": 0}, {"v": 1}, {"v": 2}, {"e": 2, "t": 0.5}, {"v": 3}, {"v": 4}], "foot": Vector2(640, 280)},
	"lshell": {"verts": [Vector2(0, 0), Vector2(420, 0), Vector2(420, 170), Vector2(1000, 170), Vector2(1000, 500), Vector2(0, 500)],
		"pockets": [{"v": 0}, {"v": 1}, {"v": 3}, {"v": 5}, {"e": 4, "t": 0.5}, {"v": 4}], "foot": Vector2(720, 330)},
}

## Clockwork Table: the pockets in clock order (top-left, top, top-right, then round).
const CLOCK_ORDER := [0, 1, 2, 5, 4, 3]
const COMPOUNDS := {"fire+water": "Steam", "earth+fire": "Lava", "air+fire": "Blaze", "earth+water": "Clay", "air+water": "Storm", "air+earth": "Dust"}

## Side bets: one is dealt face down each table. You can bet the table's stake
## blind, pay half the stake to peek first, or pass. "tier" 0 easy, 1 medium,
## 2 hard sets the payout; "terms" are explained on the bet card.
const BOUNTIES := {
	"solid": {"name": "Sink a solid ball", "tier": 0, "terms": ["solid"]},
	"stripe": {"name": "Sink a striped ball", "tier": 0, "terms": ["stripe"]},
	"corner": {"name": "Sink a ball into a corner pocket", "tier": 0, "terms": []},
	"side": {"name": "Sink a ball into a side pocket", "tier": 0, "terms": []},
	"hot": {"name": "Sink a ball into the hot pocket", "tier": 0, "terms": ["hot"]},
	"breakpot": {"name": "Sink a ball on the break", "tier": 0, "terms": ["break"]},
	"hard": {"name": "Sink a ball with a power shot (85%+)", "tier": 0, "terms": []},
	"soft": {"name": "Sink a ball with a soft shot (35% or less)", "tier": 0, "terms": []},
	"heat3": {"name": "Reach Heat 3", "tier": 0, "terms": ["heat"]},
	"double": {"name": "Sink 2 or more balls in one shot", "tier": 1, "terms": []},
	"bank": {"name": "Sink a bank shot", "tier": 1, "terms": ["bank"]},
	"combo": {"name": "Sink a combination", "tier": 1, "terms": ["combination"]},
	"kick": {"name": "Sink a ball off a kick shot", "tier": 1, "terms": ["kick"]},
	"heat4": {"name": "Reach Heat 4", "tier": 1, "terms": ["heat"]},
	"chain5": {"name": "Reach Chain 5 in one shot", "tier": 1, "terms": ["chain"]},
	"quarter": {"name": "Score a quarter of this table's target in one shot", "tier": 1, "terms": ["target"]},
	"triple": {"name": "Sink 3 or more balls in one shot", "tier": 2, "terms": []},
	"bank2": {"name": "Sink a ball off 2 cushions", "tier": 2, "terms": ["bank"]},
	"heat5": {"name": "Reach Heat 5", "tier": 2, "terms": ["heat"]},
	"chain7": {"name": "Reach Chain 7 in one shot", "tier": 2, "terms": ["chain"]},
	"half": {"name": "Score half of this table's target in one shot", "tier": 2, "terms": ["target"]},
	"hot2": {"name": "Sink 2 balls into the hot pocket in one shot", "tier": 2, "terms": ["hot"]},
	"eight": {"name": "Sink the 8 when it is the only ball left", "tier": 2, "terms": ["eight"]},
}
const BET_TIERS := ["Easy", "Medium", "Hard"]
## The stake for each table (endless keeps the last).
const BET_STAKES := [4, 4, 8, 8, 12, 12, 16, 16, 20]


## Handicaps: optional difficulty, each level including every rule before it.
const HANDICAPS := [
	{"name": "Scratch Player", "desc": "The game as designed."},
	{"name": "Worn Cloth", "desc": "Table targets are 15% higher."},
	{"name": "Short Chalk", "desc": "1 less Chalk on every table."},
	{"name": "Dear Prices", "desc": "Everything in the Pro Shop costs $1 more."},
	{"name": "Narrow Jaws", "desc": "Pockets are 5% narrower."},
	{"name": "Hall of Fame", "desc": "Table targets are 30% higher again."},
]

## The nine-table tour. "boss" fixes a table; otherwise one is drawn from "tier".
const TABLES := [
	{"target": 50, "boss": "local"},
	{"target": 120, "tier": 1},
	{"target": 215, "tier": 1},
	{"target": 270, "tier": 2},
	{"target": 390, "boss": "elements"},
	{"target": 510, "tier": 2},
	{"target": 650, "tier": 3},
	{"target": 840, "tier": 3},
	{"target": 1060, "boss": "final"},
]


const FAMILY_NAMES := {
	"bank": "Banks & cushions", "cue": "Cue control", "combo": "Combos & clusters", "streak": "Streaks", "heat": "Heat",
	"pocket": "Pockets", "number": "Ball numbers", "solid": "Solids", "stripe": "Stripes", "eight": "The 8-ball", "clear": "Clearing your set", "gear": "Gear", "imbue": "Isotopes", "special": "Special balls", "pause": "Pausing", "money": "Economy", "risk": "Risk & scaling",
	"physics": "Physics", "utility": "Utility",
}


static func family_name(id: String) -> String:
	return FAMILY_NAMES.get(PERKS[id].get("fam", "utility"), "Utility")


## Owned perks that share a family with id (for synergy hints).
static func synergies(id: String, owned: Array) -> Array:
	var fam: String = PERKS[id].get("fam", "")
	if fam == "" or fam == "utility":
		return []
	return owned.filter(func(o): return o != id and PERKS[o].get("fam", "") == fam)


## A ball's value: 10 plus its number times the weight (2, raised by Big Numbers
## and the Weighted Imbue). Special balls have their own value.
const NUMBER_WEIGHT := 2


static func ball_points(n: int, weight: int = NUMBER_WEIGHT) -> int:
	var k := kind_of(n)
	if k == "dice" or k == "wild":
		return 10 + weight * int(faces.get(n, 0))
	return int(BALL_TYPES[k].value) if k != "" else 10 + weight * n


static func is_stripe(n: int) -> bool:
	return n >= 9 and n <= 15


static func ball_color(n: int) -> Color:
	var k := kind_of(n)
	return BALL_TYPES[k].color if k != "" else BALL_COLORS.get(n, Color.WHITE)


static func rarity_name(r: int) -> String:
	return ["Common", "Uncommon", "Rare"][r]


static func rarity_color(r: int) -> Color:
	return [Color(0.55, 0.75, 0.95), Color(0.45, 0.9, 0.55), Color(1.0, 0.55, 0.3)][r]
