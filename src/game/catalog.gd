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
	"odd": {"name": "Odd Balls", "r": 0, "cost": 4, "fam": "number", "desc": "Odd-numbered balls are worth +15.", "fx": {"when": "odd", "value": 15}},
	"even": {"name": "Even Money", "r": 0, "cost": 4, "fam": "number", "desc": "Even-numbered balls add +0.5 Chain as they sink.", "fx": {"when": "even", "chain": 0.5}},
	"stripes": {"name": "Stripes", "r": 0, "cost": 5, "fam": "stripe", "desc": "Striped balls pay ×1.5.", "fx": {"when": "stripe", "x": 1.5}},
	"solids": {"name": "Solids", "r": 0, "cost": 5, "fam": "solid", "desc": "Solid balls are worth +25.", "fx": {"when": "solid", "value": 25}},
	"corner": {"name": "Corner Man", "r": 0, "cost": 4, "fam": "pocket", "desc": "Corner pockets add +0.5 Chain as the ball sinks.", "fx": {"when": "corner", "chain": 0.5}},
	"side": {"name": "Side Door", "r": 0, "cost": 5, "fam": "pocket", "desc": "Side pockets pay ×2.", "fx": {"when": "side", "x": 2.0}},
	"lever": {"name": "Long Game", "r": 0, "cost": 5, "fam": "utility", "desc": "Long sinks (the ball travels 450+) pay ×1.5.", "fx": {"when": "long", "x": 1.5}},
	"chalk": {"name": "Spare Chalk", "r": 0, "cost": 5, "fam": "utility", "desc": "+1 Chalk on every table."},
	"jaws": {"name": "Wide Jaws", "r": 0, "cost": 6, "fam": "pocket", "desc": "Pockets are 12% wider."},
	"lens": {"name": "Long Lens", "r": 0, "cost": 4, "fam": "utility", "desc": "The guideline continues past the first cushion and shows the cue ball's full path."},
	"bank": {"name": "Bank Manager", "r": 1, "cost": 6, "fam": "bank", "desc": "Bank sinks add +1 Chain per cushion."},
	"kick": {"name": "Kick Drum", "r": 1, "cost": 6, "fam": "cue", "desc": "Kick shots (cue hits a cushion first) pay ×2 on every sink.", "fx": {"when": "kick", "x": 2.0}},
	"chain": {"name": "Daisy Chain", "r": 1, "cost": 7, "fam": "combo", "desc": "Combination sinks pay ×2.", "fx": {"when": "combo", "x": 2.0}},
	"multi": {"name": "Cluster", "r": 1, "cost": 6, "fam": "combo", "desc": "Every ball after the first in a shot adds +1 Chain as it sinks.", "fx": {"when": "extra", "chain": 1.0}},
	"streak": {"name": "Stoker", "r": 1, "cost": 7, "fam": "streak", "desc": "Shots that sink 2+ balls add +1 extra Heat."},
	"heat": {"name": "Scorcher", "r": 1, "cost": 6, "fam": "pocket", "desc": "The hot pocket pays ×3 instead of ×2, and balls there are worth +20.", "fx": {"when": "hot", "value": 20}},
	"power": {"name": "Power Stroke", "r": 1, "cost": 5, "fam": "cue", "desc": "Shots at 85%+ power start with +1 Chain."},
	"finesse": {"name": "Soft Touch", "r": 1, "cost": 6, "fam": "cue", "desc": "Shots at 35% power or less pay ×2.", "fx": {"when": "soft", "x": 2.0}},
	"prime": {"name": "Prime Cut", "r": 1, "cost": 6, "fam": "number", "desc": "Balls 2, 3, 5, 7, 11 and 13 pay ×1.5.", "fx": {"when": "prime", "x": 1.5}},
	"eight": {"name": "Behind the 8", "r": 1, "cost": 6, "fam": "eight", "desc": "The 8 stops costing you points, pays like any other ball, and pays $3.", "fx": {"when": "eight", "money": 3}},
	"darkhorse": {"name": "Dark Horse", "r": 2, "cost": 9, "fam": "eight", "desc": "The 8 pays ×8 when it sinks. You still lose points if it sinks early.", "fx": {"when": "eight", "x": 8.0}},
	"hushmoney": {"name": "Hush Money", "r": 0, "cost": 4, "fam": "eight", "desc": "Sinking the 8 early costs $3 instead of points."},
	"kissblack": {"name": "Kiss the Black", "r": 1, "cost": 6, "fam": "eight", "desc": "Every time a ball touches the 8, add +0.75 Chain."},
	"steerclear": {"name": "Steer Clear", "r": 0, "cost": 5, "fam": "eight", "desc": "If no ball touches the 8 during a shot, each sink adds +0.75 Chain.", "fx": {"when": "no_eight_touch", "chain": 0.75}},
	"lastcall": {"name": "Last Call", "r": 1, "cost": 6, "fam": "eight", "desc": "If the 8 is the last ball on the table, it pays ×5 and $5.", "fx": {"when": "last_eight", "x": 5.0, "money": 5}},
	"eightcount": {"name": "Eight Count", "r": 1, "cost": 6, "fam": "eight", "desc": "Every 8th ball you sink in a run pays ×3.", "fx": {"when": "eight_count", "x": 3.0}},
	"trouble": {"name": "Trouble Maker", "r": 2, "cost": 7, "fam": "eight", "desc": "When the 8 sinks early, gain +3 Heat. You still lose the points."},
	"solidgold": {"name": "Solid Gold", "r": 1, "cost": 6, "fam": "solid", "desc": "Each solid you sink pays $1.", "fx": {"when": "solid", "money": 1}},
	"bedrock": {"name": "Bedrock", "r": 1, "cost": 8, "fam": "solid", "desc": "Shots that sink only solids add +1 Heat."},
	"steadyrun": {"name": "Steady Run", "r": 1, "cost": 6, "fam": "solid", "desc": "Each solid sunk in a row on this table makes solids worth +8 more (max +64). A stripe resets it."},
	"solidsonly": {"name": "Solids Only", "r": 2, "cost": 9, "fam": "solid", "desc": "Solids pay ×2, but stripes pay ×0.5."},
	"lastsolid": {"name": "Last Solid", "r": 2, "cost": 8, "fam": "solid", "desc": "The last solid on the table pays ×7.", "fx": {"when": "last_solid", "x": 7.0}},
	"racing": {"name": "Racing Stripe", "r": 1, "cost": 6, "fam": "stripe", "desc": "Stripes sunk at 60% power or more pay ×2.", "fx": {"when": "stripe_hard", "x": 2.0}},
	"luckystripe": {"name": "Lucky Stripe", "r": 1, "cost": 6, "fam": "stripe", "desc": "Each stripe you sink has a 1 in 3 chance to pay ×3 and $2."},
	"tiger": {"name": "Tiger Stripes", "r": 1, "cost": 7, "fam": "stripe", "desc": "Each stripe sunk in a row on this table adds +0.25 Chain to the next (max +2). A solid resets it."},
	"stripesonly": {"name": "Stripes Only", "r": 2, "cost": 9, "fam": "stripe", "desc": "Stripes pay ×2, but solids pay ×0.5."},
	"laststripe": {"name": "Last Stripe", "r": 2, "cost": 8, "fam": "stripe", "desc": "The last stripe on the table pays ×7.", "fx": {"when": "last_stripe", "x": 7.0}},
	"gold": {"name": "Gold Rail", "r": 1, "cost": 7, "fam": "money", "desc": "Each sink pays $1 (max $3 per shot)."},
	"entropy": {"name": "Long Night", "r": 1, "cost": 6, "fam": "streak", "desc": "Shots start with +0.25 Chain for every shot already taken on this table (max +3)."},
	"catalyst": {"name": "Snowball", "r": 2, "cost": 8, "fam": "risk", "desc": "Every ball you sink makes all balls worth +0.5 for the rest of the run."},
	"golden": {"name": "First Blood", "r": 2, "cost": 8, "fam": "risk", "desc": "The first sink of every shot pays ×1.6.", "fx": {"when": "first", "x": 1.6}},
	"supernova": {"name": "Clean Sweep", "r": 2, "cost": 9, "fam": "combo", "desc": "Shots that sink 3 or more balls pay ×2 on every sink.", "fx": {"when": "triple", "x": 2.0}},
	"fusion": {"name": "Same Pocket", "r": 2, "cost": 8, "fam": "combo", "desc": "A second ball into the same pocket in one shot pays ×3.", "fx": {"when": "repeat_pocket", "x": 3.0}},
	"magnet": {"name": "Magnetic Pockets", "r": 2, "cost": 9, "fam": "pocket", "desc": "Pockets gently pull nearby moving balls in."},
	"insurance": {"name": "Insurance", "r": 2, "cost": 7, "fam": "utility", "desc": "The first 2 misses or scratches on each table cost no Chalk."},
	"oracle": {"name": "Second Sight", "r": 2, "cost": 10, "fam": "utility", "desc": "Before each shot, see exactly what it will score, counting every ball it knocks in."},
	"ricochet": {"name": "Ricochet", "r": 1, "cost": 6, "fam": "bank", "desc": "Every cushion a ball touches adds +0.25 extra Chain."},
	"cushion": {"name": "Soft Rails", "r": 0, "cost": 4, "fam": "bank", "desc": "Bank sinks are worth +20.", "fx": {"when": "bank", "value": 20}},
	"geometry": {"name": "Geometry", "r": 2, "cost": 8, "fam": "bank", "desc": "Bank sinks pay ×1.5.", "fx": {"when": "bank", "x": 1.5}},
	"tracer": {"name": "Tracer", "r": 0, "cost": 4, "fam": "bank", "desc": "Every cushion the cue ball touches after contact adds +0.25 Chain."},
	"boomerang": {"name": "Boomerang", "r": 1, "cost": 6, "fam": "cue", "desc": "If the cue ball finishes within 120 of where it started, every sink pays ×2.", "fx": {"when": "boomerang", "x": 2.0}},
	"precision": {"name": "Clean Stroke", "r": 1, "cost": 6, "fam": "cue", "desc": "Clean sinks (straight from the cue ball, no cushions) add +1 Chain.", "fx": {"when": "clean", "chain": 1.0}},
	"stun": {"name": "Stun Master", "r": 1, "cost": 6, "fam": "cue", "desc": "The cue ball loses 60% of its speed when it first hits a ball. Far fewer scratches."},
	"afterburner": {"name": "Break Artist", "r": 0, "cost": 5, "fam": "cue", "desc": "Break shots start with +3 Chain."},
	"domino": {"name": "Domino", "r": 0, "cost": 5, "fam": "combo", "desc": "Combination sinks are worth +30.", "fx": {"when": "combo", "value": 30}},
	"rhythm": {"name": "Rhythm", "r": 0, "cost": 5, "fam": "streak", "desc": "Every third shot on a table pays ×2.", "fx": {"when": "third", "x": 2.0}},
	"hothand": {"name": "Hot Hand", "r": 1, "cost": 6, "fam": "streak", "desc": "At Heat 3 or more, every ball is worth +20.", "fx": {"when": "heat3", "value": 20}},
	"comeback": {"name": "Last Chalk", "r": 1, "cost": 6, "fam": "streak", "desc": "On your last Chalk, every sink pays ×2.", "fx": {"when": "last_chalk", "x": 2.0}},
	"collector": {"name": "Grand Tour", "r": 2, "cost": 8, "fam": "pocket", "desc": "Shots start with +0.5 Chain for every different pocket used on this table."},
	"migration": {"name": "Stay Hot", "r": 1, "cost": 6, "fam": "pocket", "desc": "The hot pocket only moves after a shot that does not score."},
	"lowball": {"name": "Low Ball", "r": 0, "cost": 4, "fam": "solid", "desc": "Solid balls add +0.5 Chain as they sink.", "fx": {"when": "solid", "chain": 0.5}},
	"highball": {"name": "High Roller", "r": 0, "cost": 4, "fam": "stripe", "desc": "Striped balls are worth +20.", "fx": {"when": "stripe", "value": 20}},
	"fibonacci": {"name": "Lucky Numbers", "r": 1, "cost": 6, "fam": "number", "desc": "Balls 1, 2, 3, 5, 8 and 13 add +0.5 Chain as they sink.", "fx": {"when": "fib", "chain": 0.5}},
	"rotation": {"name": "Rotation", "r": 1, "cost": 6, "fam": "number", "desc": "Sinking the lowest-numbered ball on the table pays ×1.5.", "fx": {"when": "lowest", "x": 1.5}},
	"moneyball": {"name": "Money Ball", "r": 1, "cost": 7, "fam": "number", "desc": "Sinking the highest-numbered ball on the table pays ×2 and $2.", "fx": {"when": "highest", "x": 2.0, "money": 2}},
	"thrift": {"name": "Thrift", "r": 0, "cost": 4, "fam": "money", "desc": "Clear a table with 2+ Chalk left: +$5."},
	"venture": {"name": "Deep Pockets", "r": 1, "cost": 6, "fam": "money", "desc": "Shots start with +0.25 Chain for every $5 you hold (max +1.5)."},
	"hunter": {"name": "Side Hustle", "r": 0, "cost": 4, "fam": "money", "desc": "Side bets pay double."},
	"coupon": {"name": "Regular Customer", "r": 0, "cost": 3, "fam": "money", "desc": "Rerolls in the Pro Shop start at $1."},
	"overflow": {"name": "Overflow", "r": 1, "cost": 5, "fam": "money", "desc": "Points over a table's target carry into the next table (up to 25% of its target)."},
	"glasscannon": {"name": "All In", "r": 2, "cost": 8, "fam": "risk", "desc": "Every sink pays ×2, but misses and scratches cost 2 Chalk.", "fx": {"when": "any", "x": 2.0}},
	"minimalist": {"name": "Travel Light", "r": 2, "cost": 7, "fam": "risk", "desc": "Every sink pays ×1.25 for each empty Perk slot."},
	"echo": {"name": "Double Take", "r": 2, "cost": 9, "fam": "risk", "desc": "The first sink of every shot pays out twice."},
	"featherweight": {"name": "Featherweight", "r": 1, "cost": 6, "fam": "physics", "desc": "Object balls are 25% lighter: they fly further when struck."},
	"heavyhit": {"name": "Heavy Hitter", "r": 1, "cost": 6, "fam": "physics", "desc": "The cue ball is 30% heavier, so it drives balls further."},
	"liverails": {"name": "Live Rails", "r": 0, "cost": 5, "fam": "physics", "desc": "Cushions are 10% livelier."},
	"slowcloth": {"name": "Slow Cloth", "r": 0, "cost": 4, "fam": "physics", "desc": "Thicker cloth: balls stop 25% sooner, for tighter position."},
	"backspin": {"name": "Backspin Wax", "r": 1, "cost": 6, "fam": "physics", "desc": "Draw and follow are 50% stronger."},
	"bigbreak": {"name": "Big Break", "r": 0, "cost": 5, "fam": "physics", "desc": "Break shots hit 25% harder."},
	"longarm": {"name": "Long Arm", "r": 1, "cost": 6, "fam": "physics", "desc": "Full power hits 15% harder."},
	"masse": {"name": "Massé Master", "r": 1, "cost": 6, "fam": "cue", "desc": "English bends the cue ball twice as much off cushions."},
	"followthru": {"name": "Follow Through", "r": 0, "cost": 5, "fam": "cue", "desc": "Shots hit with follow add +0.5 Chain to every sink.", "fx": {"when": "follow_shot", "chain": 0.5}},
	"drawartist": {"name": "Draw Artist", "r": 1, "cost": 6, "fam": "cue", "desc": "Shots hit with draw pay ×1.5.", "fx": {"when": "draw_shot", "x": 1.5}},
	"thinrack": {"name": "Thin Rack", "r": 1, "cost": 6, "fam": "clear", "desc": "Every ball removed from your set makes all balls worth +6."},
	"missing": {"name": "Missing Piece", "r": 1, "cost": 7, "fam": "clear", "desc": "Shots start with +0.5 Chain for each ball removed from your set (max +3)."},
	"cleanhouse": {"name": "Clean House", "r": 0, "cost": 3, "fam": "clear", "desc": "Removing a ball in the Pro Shop is free."},
	"packrat": {"name": "Pack Rat", "r": 0, "cost": 4, "fam": "gear", "desc": "+1 Tool slot and +1 Consumable slot."},
	"quartermaster": {"name": "Quartermaster", "r": 0, "cost": 4, "fam": "gear", "desc": "Items cost $1 less."},
	"tinkerer": {"name": "Tinkerer", "r": 1, "cost": 6, "fam": "gear", "desc": "Start every table with a random Consumable, if you have room."},
	"enchanter": {"name": "Enchanter", "r": 0, "cost": 4, "fam": "imbue", "desc": "Imbues cost $2 less."},
	"secondcoat": {"name": "Second Coat", "r": 1, "cost": 7, "fam": "imbue", "desc": "Imbued balls pay ×1.5."},
	"goldrush": {"name": "Gold Rush", "r": 1, "cost": 6, "fam": "special", "desc": "Special balls pay ×2."},
	"menagerie": {"name": "Menagerie", "r": 1, "cost": 6, "fam": "special", "desc": "Shots start with +0.25 Chain for each special ball in your set."},
	"alchemy": {"name": "Alchemy", "r": 2, "cost": 8, "fam": "special", "desc": "After each table, one plain ball in your set (never the 8) turns into a random special ball."},
	"stillness": {"name": "Stillness", "r": 1, "cost": 6, "fam": "pause", "desc": "Every time you pause a shot, it gains +0.5 Chain (max +2 a shot)."},
	"quickhands": {"name": "Quick Hands", "r": 0, "cost": 4, "fam": "pause", "desc": "The first mid-shot Consumable you use on each table is not used up."},
	"afterimage": {"name": "Afterimage", "r": 1, "cost": 6, "fam": "pause", "desc": "Second Strike and Blink each add +1 Chain to the shot."},
	"overclock": {"name": "Overclock", "r": 2, "cost": 8, "fam": "pause", "desc": "Your Tools get two charges on every table."},
	"velvet": {"name": "Velvet Cloth", "r": 0, "cost": 5, "fam": "physics", "desc": "30% less cloth friction: balls roll further."},
}

## Usable items, the Hustler's Kit: pool-hall props that each bend one rule of the
## table. "kind": a tool stays all run with one charge per table; a consumable is
## used once. "when": setup (aiming), pause (a shot is paused), after (the balls
## have stopped after a shot) or any.
const ITEMS := {
	"calledshot": {"name": "Called Shot", "kind": "consumable", "when": "setup", "cost": 4, "desc": "Pick a ball and a pocket. If that ball sinks there on your next shot, it pays ×3."},
	"trapdoor": {"name": "Trapdoor", "kind": "consumable", "when": "setup", "cost": 5, "desc": "Open a seventh pocket anywhere along a cushion for your next shot."},
	"ghostchalk": {"name": "Ghost Chalk", "kind": "consumable", "when": "setup", "cost": 4, "desc": "Pick a ball. Your next shot passes straight through it."},
	"swap": {"name": "Swap", "kind": "tool", "when": "setup", "cost": 7, "desc": "Swap the places of two balls (not the cue ball)."},
	"polish": {"name": "Polish", "kind": "consumable", "when": "setup", "cost": 3, "desc": "Pick a ball. On your next shot it glides with no cloth friction until it first hits something."},
	"leadweight": {"name": "Lead Weight", "kind": "tool", "when": "setup", "cost": 6, "desc": "Pick a ball. On your next shot it is four times as heavy."},
	"spotter": {"name": "Spotter", "kind": "consumable", "when": "setup", "cost": 4, "desc": "Bring a ball you sank on this table back to the foot spot. Never the 8."},
	"pocketcover": {"name": "Pocket Cover", "kind": "tool", "when": "setup", "cost": 7, "desc": "Cover a pocket for the rest of this table. The pocket opposite opens 30% wider."},
	"secondstrike": {"name": "Second Strike", "kind": "tool", "when": "pause", "cost": 7, "desc": "While a shot is paused, hit the cue ball again."},
	"wall": {"name": "Pop-up Wall", "kind": "consumable", "when": "pause", "cost": 4, "desc": "While a shot is paused, raise a short wall for the rest of the shot."},
	"blink": {"name": "Blink", "kind": "consumable", "when": "pause", "cost": 4, "desc": "While a shot is paused, move the cue ball anywhere. It keeps its speed and direction."},
	"freezeframe": {"name": "Freeze Frame", "kind": "consumable", "when": "pause", "cost": 4, "desc": "While a shot is paused, stop one ball dead. It holds still like a post for the rest of the shot."},
	"nudge": {"name": "Nudge", "kind": "tool", "when": "pause", "cost": 6, "desc": "While a shot is paused, push one ball a short way in any direction."},
	"englishdial": {"name": "English Dial", "kind": "consumable", "when": "pause", "cost": 3, "desc": "While a shot is paused, put the spin you have set onto the rolling cue ball."},
	"gravitypebble": {"name": "Gravity Pebble", "kind": "consumable", "when": "pause", "cost": 4, "desc": "While a shot is paused, place a small well that bends rolling balls for the rest of the shot."},
	"rewind": {"name": "Rewind", "kind": "tool", "when": "after", "cost": 9, "desc": "Undo your last shot entirely: balls, score, Heat and Chalk."},
	"slip": {"name": "Insurance Slip", "kind": "consumable", "when": "after", "cost": 3, "desc": "If your last shot cost Chalk, get it back."},
	"triangle": {"name": "Triangle", "kind": "consumable", "when": "after", "cost": 4, "desc": "Re-rack every ball still on the table and break again."},
	"ballinhand": {"name": "Ball in Hand", "kind": "consumable", "when": "after", "cost": 3, "desc": "Pick up the cue ball and place it anywhere."},
	"post": {"name": "Post", "kind": "consumable", "when": "any", "cost": 4, "desc": "Place a bumper anywhere on this table."},
	"portal": {"name": "Portal Pair", "kind": "consumable", "when": "any", "cost": 5, "desc": "Place two linked portals. A ball rolling into one comes out of the other at the same speed."},
}

const WHEN_NAMES := {"setup": "Set-up · while aiming", "pause": "Mid-shot · while paused", "after": "Aftermath · after a shot", "any": "Any time"}
const WHEN_COLORS := {"setup": Color(0.45, 0.7, 1.0), "pause": Color(0.45, 0.95, 0.75), "after": Color(1.0, 0.72, 0.35), "any": Color(0.85, 0.85, 0.9)}


## Imbues live on one numbered ball for the rest of the run.
const IMBUES := {
	"spark": {"name": "Spark", "cost": 4, "color": Color(0.3, 1.0, 0.85), "desc": "+1 Chain every time this ball is struck."},
	"gold": {"name": "Gilded", "cost": 4, "color": Color(1.0, 0.82, 0.3), "desc": "Pays $2 when sunk."},
	"heavy": {"name": "Weighted", "cost": 3, "color": Color(0.75, 0.78, 0.85), "desc": "Worth +40 when sunk."},
	"glass": {"name": "Hairline", "cost": 5, "color": Color(0.7, 0.85, 1.0), "desc": "Pays ×3 when sunk, but 1 in 4 times the coating cracks off."},
	"ember": {"name": "Kindled", "cost": 5, "color": Color(1.0, 0.45, 0.2), "desc": "+1 Heat when sunk."},
	"vein": {"name": "Vein", "cost": 5, "color": Color(1.0, 0.55, 0.95), "desc": "+1 Chain as this ball sinks, and it is worth +20."},
	"lucky": {"name": "Lucky", "cost": 4, "color": Color(0.35, 0.95, 0.5), "desc": "1 in 3 chance to pay ×4 when sunk."},
	"frosted": {"name": "Frosted", "cost": 4, "color": Color(0.7, 0.92, 1.0), "desc": "When it sinks, your next miss on this table keeps your Heat."},
	"magnetic": {"name": "Magnetic", "cost": 5, "color": Color(1.0, 0.35, 0.35), "desc": "Pockets pull this ball in."},
	"charged": {"name": "Charged", "cost": 4, "color": Color(1.0, 1.0, 0.45), "desc": "+0.5 Chain every time this ball touches a cushion."},
	"prismatic": {"name": "Resonant", "cost": 4, "color": Color(0.95, 0.6, 1.0), "desc": "Every ball it touches in a shot adds +0.25 Chain."},
	"hollow": {"name": "Hollow", "cost": 3, "color": Color(0.85, 0.85, 0.75), "desc": "Half the weight: it flies further when struck."},
	"leaded": {"name": "Leaded", "cost": 4, "color": Color(0.5, 0.55, 0.65), "desc": "Twice as heavy, and worth +30."},
	"bounty": {"name": "Bounty", "cost": 4, "color": Color(0.6, 1.0, 0.4), "desc": "Pays $1 for every point of Heat when it sinks."},
	"starry": {"name": "Starry", "cost": 5, "color": Color(1.0, 0.85, 0.55), "desc": "Every ball after it in the same shot gets +0.5 Chain."},
	"twin": {"name": "Twin", "cost": 4, "color": Color(0.5, 0.65, 1.0), "desc": "This ball's value counts twice."},
}

## Special balls you can add to your set. They rack with the numbered balls and
## count as neither solids nor stripes unless they say so. Each has its own
## finish ("pattern" in the ball shader), colours and emblem.
const BALL_TYPES := {
	"gold": {"name": "Gold", "cost": 6, "value": 30, "color": Color(1.0, 0.78, 0.2), "accent": Color(1.0, 0.96, 0.62), "pattern": 1, "motif": "t 0 0 34 $", "desc": "Worth 30, and pays $1 for every cushion it touched before sinking."},
	"void": {"name": "Void", "cost": 7, "value": 0, "color": Color(0.12, 0.03, 0.2), "accent": Color(0.62, 0.25, 1.0), "pattern": 2, "motif": "c 0 0 26;c 0 0 14;C 0 0 5", "desc": "Worth nothing itself, but every other ball in the same shot pays ×2."},
	"glass": {"name": "Glass", "cost": 6, "value": 20, "color": Color(0.7, 0.9, 1.0), "accent": Color(1.0, 1.0, 1.0), "pattern": 3, "motif": "o 0 -30 22 -8 0 30 -22 -8 0 -30", "desc": "Pays ×3 if it sinks, but anything that hits it hard shatters it, and it leaves your set."},
	"iron": {"name": "Iron", "cost": 5, "value": 45, "color": Color(0.45, 0.47, 0.52), "accent": Color(0.78, 0.8, 0.85), "pattern": 1, "motif": "P -26 -14 26 -14 18 0 10 0 14 18 -14 18 -10 0 -18 0", "desc": "Twice as heavy. Worth 45."},
	"feather": {"name": "Feather", "cost": 4, "value": 25, "color": Color(0.95, 0.95, 0.98), "accent": Color(0.55, 0.7, 1.0), "pattern": 4, "motif": "l -24 26 22 -22;o -14 16 -12 -10 18 -24 8 6 -14 16", "desc": "A quarter the weight: it barely moves other balls, and adds +0.5 Chain as it sinks."},
	"ember": {"name": "Kindled", "cost": 5, "value": 22, "color": Color(0.9, 0.3, 0.05), "accent": Color(1.0, 0.8, 0.2), "pattern": 5, "motif": "P 0 -32 14 -10 18 8 8 26 -8 26 -18 8 -12 -6 -6 4", "desc": "The pocket it sinks into becomes the hot pocket."},
	"frost": {"name": "Frost", "cost": 5, "value": 22, "color": Color(0.55, 0.85, 1.0), "accent": Color(1.0, 1.0, 1.0), "pattern": 6, "motif": "l 0 -30 0 30;l -26 -15 26 15;l -26 15 26 -15", "desc": "Any ball that touches it stops dead."},
	"magnet": {"name": "Magnet", "cost": 5, "value": 20, "color": Color(0.85, 0.15, 0.15), "accent": Color(0.2, 0.35, 0.95), "pattern": 7, "motif": "a 0 -4 20 0 180;l -20 -4 -20 -26;l 20 -4 20 -26", "desc": "Pulls nearby rolling balls towards itself."},
	"prism": {"name": "Prism", "cost": 5, "value": 22, "color": Color(0.9, 0.5, 0.9), "accent": Color(0.4, 0.95, 0.9), "pattern": 8, "motif": "o 0 -28 26 18 -26 18 0 -28", "desc": "Counts as both a solid and a stripe."},
	"wild": {"name": "Wild", "cost": 5, "value": 0, "color": Color(0.45, 0.1, 0.6), "accent": Color(1.0, 0.85, 0.2), "pattern": 9, "motif": "P 0 -32 8 -8 32 -8 12 6 20 30 0 14 -20 30 -12 6 -32 -8 -8 -8 0 -32", "desc": "Copies the number of the last ball you sank, and counts as that number."},
	"clock": {"name": "Clock", "cost": 5, "value": 10, "color": Color(0.1, 0.6, 0.6), "accent": Color(0.9, 1.0, 1.0), "pattern": 6, "motif": "c 0 0 26;l 0 0 0 -18;l 0 0 12 6", "desc": "Worth 10, plus 6 for every shot already taken on this table."},
	"coin": {"name": "Coin", "cost": 4, "value": 18, "color": Color(0.95, 0.75, 0.2), "accent": Color(0.65, 0.45, 0.1), "pattern": 7, "motif": "c 0 0 26;c 0 0 17", "desc": "Pays $1 every time the cue ball hits it in a scoring shot."},
	"bomb": {"name": "Bomb", "cost": 6, "value": 20, "color": Color(0.12, 0.12, 0.14), "accent": Color(1.0, 0.3, 0.2), "pattern": 4, "motif": "C 0 6 20;l 10 -12 20 -26;C 22 -28 4", "desc": "When it sinks, the nearest ball (never the 8) sinks with it."},
	"seed": {"name": "Seed", "cost": 4, "value": 20, "color": Color(0.35, 0.7, 0.25), "accent": Color(0.85, 1.0, 0.5), "pattern": 0, "motif": "l 0 30 0 -6;o 0 -6 -18 -24 -2 -20 0 -6;o 0 -6 18 -24 2 -20 0 -6", "desc": "Worth 20, and 10 more every time you sink it this run."},
	"clover": {"name": "Clover", "cost": 5, "value": 20, "color": Color(0.15, 0.62, 0.3), "accent": Color(0.7, 1.0, 0.7), "pattern": 4, "motif": "C -10 -10 10;C 10 -10 10;C -10 10 10;C 10 10 10;l 0 10 8 30", "desc": "No shot it is part of can cost Chalk."},
	"star": {"name": "Star", "cost": 5, "value": 20, "color": Color(0.98, 0.95, 0.75), "accent": Color(1.0, 0.82, 0.1), "pattern": 5, "motif": "o 0 -32 8 -8 32 -8 12 6 20 30 0 14 -20 30 -12 6 -32 -8 -8 -8 0 -32", "desc": "Comes off cushions with no loss of speed, and adds +1 Chain as it sinks."},
	"heart": {"name": "Heart", "cost": 6, "value": 20, "color": Color(1.0, 0.4, 0.6), "accent": Color(1.0, 0.82, 0.9), "pattern": 0, "motif": "P 0 28 -26 2 -26 -14 -14 -24 0 -12 14 -24 26 -14 26 2", "desc": "If it is the last ball on the table when it sinks, +1 Chalk."},
	"dice": {"name": "Dice", "cost": 4, "value": 0, "color": Color(0.96, 0.96, 0.96), "accent": Color(0.15, 0.15, 0.2), "pattern": 0, "motif": "C -14 -14 5;C 14 -14 5;C 0 0 5;C -14 14 5;C 14 14 5", "desc": "Shows a new number from 1 to 15 every shot, and counts as that number."},
	"moon": {"name": "Moon", "cost": 5, "value": 24, "color": Color(0.75, 0.78, 0.86), "accent": Color(0.3, 0.32, 0.46), "pattern": 7, "motif": "a 0 0 24 60 300;a 12 0 20 100 260", "desc": "Corner pockets reject it. Pays ×2 in a side pocket."},
	"sun": {"name": "Sun", "cost": 5, "value": 24, "color": Color(1.0, 0.6, 0.1), "accent": Color(1.0, 0.92, 0.35), "pattern": 5, "motif": "C 0 0 12;l 0 -30 0 -20;l 0 20 0 30;l -30 0 -20 0;l 20 0 30 0;l -21 -21 -14 -14;l 14 14 21 21;l -21 21 -14 14;l 14 -14 21 -21", "desc": "Side pockets reject it. Pays ×2 in a corner pocket."},
	"anchor": {"name": "Anchor", "cost": 6, "value": 70, "color": Color(0.1, 0.18, 0.4), "accent": Color(0.6, 0.7, 0.9), "pattern": 1, "motif": "l 0 -24 0 26;c 0 -29 5;a 0 4 22 20 160;l -12 -14 12 -14", "desc": "Only the cue ball can move it: other balls bounce off it like a post. Worth 70."},
	"eraser": {"name": "Eraser", "cost": 3, "value": 10, "color": Color(1.0, 0.55, 0.6), "accent": Color(0.4, 0.5, 1.0), "pattern": 9, "motif": "o -26 8 6 -24 26 -4 -6 28 -26 8;l -10 -8 10 12", "desc": "When it sinks it pays $4, and both it and the last ball it touched leave your set (never the 8)."},
	"echo": {"name": "Echo", "cost": 6, "value": 20, "color": Color(0.55, 0.3, 0.85), "accent": Color(0.9, 0.8, 1.0), "pattern": 6, "motif": "C -14 0 7;a -14 0 20 -50 50;a -14 0 32 -40 40", "desc": "The first time it sinks on a table, it comes back to the foot spot."},
	"comet": {"name": "Comet", "cost": 5, "value": 28, "color": Color(0.2, 0.5, 1.0), "accent": Color(0.9, 0.95, 1.0), "pattern": 9, "motif": "C 14 -14 10;l 4 -4 -30 30;l 8 4 -20 30;l -4 -8 -30 20", "desc": "Feels no cloth friction until it first hits a cushion."},
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
	"optic": {"name": "Optic Cue", "desc": "Starts with Long Lens: see banks and the full cue-ball path. $2.", "money": 2, "perks": ["lens"], "chalk": 0,
		"shaft": Color(0.8, 0.86, 0.9), "butt": Color(0.1, 0.25, 0.4), "accent": Color(0.4, 0.85, 1.0)},
	"hotrod": {"name": "Hot Rod", "desc": "Starts with Scorcher (hot pocket ×3), but every table has 1 less Chalk. $4.", "money": 4, "perks": ["heat"], "chalk": -1,
		"shaft": Color(0.85, 0.7, 0.5), "butt": Color(0.6, 0.12, 0.05), "accent": Color(1.0, 0.55, 0.1)},
	"momentum": {"name": "Momentum Cue", "desc": "Starts with Stoker: multi-sink shots build extra Heat. $4.", "money": 4, "perks": ["streak"], "chalk": 0,
		"shaft": Color(0.88, 0.78, 0.6), "butt": Color(0.12, 0.12, 0.14), "accent": Color(0.6, 1.0, 0.5)},
	"gilded": {"name": "Gilded Cue", "desc": "Starts rich: $12 and Deep Pockets.", "money": 12, "perks": ["venture"], "chalk": 0,
		"shaft": Color(0.92, 0.82, 0.55), "butt": Color(0.45, 0.32, 0.08), "accent": Color(1.0, 0.85, 0.3)},
	"breaker": {"name": "Break Cue", "desc": "Starts with Break Artist (break shots +3 Chain). $3.", "money": 3, "perks": ["afterburner"], "chalk": 0,
		"shaft": Color(0.75, 0.75, 0.78), "butt": Color(0.5, 0.1, 0.5), "accent": Color(0.85, 0.5, 1.0)},
	"banker": {"name": "Banker's Cue", "desc": "Starts with Thrift and $8.", "money": 8, "perks": ["thrift"], "chalk": 0,
		"shaft": Color(0.9, 0.85, 0.7), "butt": Color(0.1, 0.3, 0.15), "accent": Color(0.75, 0.9, 0.3)},
	"thermal": {"name": "Thermal Cue", "desc": "Starts with Stay Hot: the hot pocket only moves after a shot that does not score. $3.", "money": 3, "perks": ["migration"], "chalk": 0,
		"shaft": Color(0.9, 0.75, 0.55), "butt": Color(0.75, 0.3, 0.05), "accent": Color(1.0, 0.7, 0.2)},
	"angle": {"name": "Angle Cue", "desc": "Starts with Bank Manager (banks +1 Chain per cushion). $2.", "money": 2, "perks": ["bank"], "chalk": 0,
		"shaft": Color(0.8, 0.85, 0.8), "butt": Color(0.1, 0.4, 0.3), "accent": Color(0.35, 0.8, 0.5)},
	"engineer": {"name": "Engineer's Cue", "desc": "Starts with Backspin Wax: draw and follow 50% stronger. $3.", "money": 3, "perks": ["backspin"], "chalk": 0,
		"shaft": Color(0.82, 0.8, 0.74), "butt": Color(0.2, 0.22, 0.26), "accent": Color(1.0, 0.62, 0.2)},
	"gearhead": {"name": "Gear Cue", "desc": "Starts with Pack Rat, a Second Strike and a Post. $2.", "money": 2, "perks": ["packrat"], "chalk": 0, "items": ["post"], "tools": ["secondstrike"],
		"shaft": Color(0.78, 0.82, 0.86), "butt": Color(0.12, 0.3, 0.42), "accent": Color(0.4, 0.85, 1.0)},
	"lean": {"name": "Lean Cue", "desc": "Starts with Thin Rack, and the 1 and 2 are already out of your set. $3.", "money": 3, "perks": ["thinrack"], "chalk": 0, "remove": [1, 2],
		"shaft": Color(0.9, 0.86, 0.78), "butt": Color(0.36, 0.3, 0.24), "accent": Color(0.95, 0.95, 0.9)},
	"black": {"name": "Black Cue", "desc": "Starts with Behind the 8: the 8 costs nothing and pays $3. $3.", "money": 3, "perks": ["eight"], "chalk": 0,
		"shaft": Color(0.3, 0.3, 0.32), "butt": Color(0.05, 0.05, 0.06), "accent": Color(0.82, 0.8, 0.98)},
	"alchemist": {"name": "Alchemist's Cue", "desc": "Starts with a Gold ball in your set and Gold Rush: special balls pay ×2. $3.", "money": 3, "perks": ["goldrush"], "chalk": 0, "add": ["gold"],
		"shaft": Color(0.95, 0.86, 0.6), "butt": Color(0.4, 0.2, 0.5), "accent": Color(1.0, 0.8, 0.3)},
	"glass": {"name": "Glass Cue", "desc": "Starts with All In (every sink ×2, misses cost 2 Chalk). 1 less Chalk. $4.", "money": 4, "perks": ["glasscannon"], "chalk": -1,
		"shaft": Color(0.85, 0.92, 1.0), "butt": Color(0.55, 0.7, 0.9), "accent": Color(1.0, 0.35, 0.65)},
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
	"local": {"name": "The Local", "tier": 0, "lab": "standard", "anomaly": "", "desc": "Your home table. The house forgives your first miss."},
	"frozen": {"name": "Frozen Lake", "tier": 1, "lab": "cryo", "anomaly": "", "desc": "Slick cloth, long rolls. On this table, every cushion a ball touches adds +0.5 Chain."},
	"spring_st": {"name": "Spring Street", "tier": 1, "lab": "spring", "anomaly": "sealed", "desc": "Lively rails, side pockets boarded up. On this table, bank sinks pay ×2."},
	"drift": {"name": "The Drift", "tier": 1, "lab": "current", "anomaly": "", "desc": "Rolling balls drift right. Every sink adds +1 Chain."},
	"slate": {"name": "Old Slate", "tier": 1, "lab": "dense", "anomaly": "", "desc": "Heavy cloth stops balls fast. Every ball is worth +15."},
	"cramped": {"name": "The Back Room", "tier": 1, "lab": "standard", "anomaly": "tight", "desc": "Pockets 12% narrower, but every sink pays ×1.5."},
	"parlor": {"name": "Pinball Parlor", "tier": 2, "lab": "pinball", "anomaly": "", "desc": "Four bumpers. On this table, every bumper hit adds +1 Chain."},
	"posts": {"name": "Twin Posts", "tier": 2, "lab": "cyclotron", "anomaly": "", "desc": "Two bumpers guard the middle. On this table, every bumper hit adds +1 Chain."},
	"sinkhole": {"name": "The Sinkhole", "tier": 2, "lab": "gravity", "anomaly": "", "desc": "The centre pulls moving balls in. Chain starts at 2."},
	"hump": {"name": "The Hump", "tier": 2, "lab": "repulsor", "anomaly": "", "desc": "A rise in the cloth pushes balls away. On this table, bank sinks pay ×2."},
	"nineball": {"name": "Rotation Night", "tier": 2, "lab": "standard", "anomaly": "rotation", "desc": "Hit the lowest ball first or the shot scores nothing. Legal sinks add +1 Heat."},
	"magnet": {"name": "The Magnet Room", "tier": 2, "lab": "magnetlab", "anomaly": "", "desc": "Pockets pull balls in, but every ball is worth 5 less."},
	"smoke": {"name": "The Smoke Room", "tier": 2, "lab": "dense", "anomaly": "nospin", "desc": "Stale air and a dead tip: the cue ball takes no spin here. Every sink pays ×1.5."},
	"blackice": {"name": "Black Ice", "tier": 3, "lab": "cryo", "anomaly": "blackice", "desc": "Almost no friction and lively cushions. Every sink adds +0.5 Chain."},
	"tilted": {"name": "The Tilted Table", "tier": 3, "lab": "standard", "anomaly": "tilt", "desc": "The table slopes, and a dotted line shows where balls will really roll. Every sink pays ×1.5."},
	"two": {"name": "Two Pockets", "tier": 3, "lab": "spring", "anomaly": "onepocket", "desc": "Only the hot pocket and its diagonal opposite score, and sinks there pay ×2."},
	"closing": {"name": "Closing Time", "tier": 3, "lab": "standard", "anomaly": "shrink", "desc": "Every pocket narrows after each shot. Heat builds twice as fast."},
	"iron": {"name": "The Iron Rack", "tier": 3, "lab": "dense", "anomaly": "lead", "desc": "Object balls are 60% heavier. Every ball is worth +20."},
	"lights": {"name": "Lights Out", "tier": 3, "lab": "current", "anomaly": "blind", "desc": "With the lights out, no pocket runs hot. Every sink pays ×1.5."},
	"hustler": {"name": "The Hustler", "tier": 3, "lab": "magnetlab", "anomaly": "heavycue", "desc": "A heavy cue ball, and the house skims 15% of every sink."},
	"elements": {"name": "The Element Table", "tier": 9, "lab": "element", "anomaly": "elements", "desc": "Each corner pocket holds an element. Sink them in the right order to fuse multipliers. A miss clears the mix."},
	"final": {"name": "The Grand Final", "tier": 9, "lab": "final", "anomaly": "cursed8", "desc": "The 8 goes last. Sink it early and lose a Chalk; sink it last for ×5."},
}

## Element Table: corners hold an element and side pockets copy your last one.
const POCKET_ELEMENTS := ["fire", "wild", "water", "earth", "wild", "air"]
const ELEMENTS := {
	"fire": {"name": "Fire", "color": Color(1.0, 0.45, 0.15)}, "water": {"name": "Water", "color": Color(0.3, 0.6, 1.0)},
	"earth": {"name": "Earth", "color": Color(0.6, 0.85, 0.35)}, "air": {"name": "Air", "color": Color(0.85, 0.9, 1.0)},
	"wild": {"name": "Copy", "color": Color(0.9, 0.75, 1.0)},
}
const COMPOUNDS := {"fire+water": "Steam", "earth+fire": "Lava", "air+fire": "Blaze", "earth+water": "Clay", "air+water": "Storm", "air+earth": "Dust"}

## Per-table side goals. Each table rolls one; completing it pays immediately.
const BOUNTIES := {
	"bank": {"name": "Sink a bank shot", "reward": 3},
	"combo": {"name": "Sink a combination", "reward": 3},
	"double": {"name": "Sink 2+ balls in one shot", "reward": 3},
	"triple": {"name": "Sink 3+ balls in one shot", "reward": 5},
	"kick": {"name": "Sink off a kick shot", "reward": 5},
	"hot": {"name": "Sink into the hot pocket", "reward": 2},
	"heat4": {"name": "Reach Heat 4", "reward": 4},
	"big": {"name": "Score 150+ in one shot", "reward": 4},
	"side": {"name": "Sink into a side pocket", "reward": 2},
	"eight": {"name": "Sink the 8 as the last ball", "reward": 6},
	"bank2": {"name": "Sink a 2-cushion bank", "reward": 6},
	"big300": {"name": "Score 300+ in one shot", "reward": 5},
	"big600": {"name": "Score 600+ in one shot", "reward": 7},
	"heat3": {"name": "Reach Heat 3", "reward": 2},
	"heat6": {"name": "Reach Heat 6", "reward": 7},
	"corner": {"name": "Sink into a corner pocket", "reward": 1},
	"hot2": {"name": "Sink 2 balls into the hot pocket", "reward": 7},
	"quad": {"name": "Sink 4+ balls in one shot", "reward": 8},
	"stripe": {"name": "Sink a striped ball", "reward": 2},
	"solid": {"name": "Sink a solid ball", "reward": 1},
	"soft": {"name": "Sink with a soft shot (35% or less)", "reward": 3},
	"hard": {"name": "Sink with a power shot (85%+)", "reward": 3},
	"breakpot": {"name": "Sink a ball on the break", "reward": 3},
	"chain5": {"name": "Reach Chain 5 on a shot", "reward": 4},
	"chain8": {"name": "Reach Chain 8 on a shot", "reward": 6},
}

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
	{"target": 40, "boss": "local"},
	{"target": 95, "tier": 1},
	{"target": 180, "tier": 1},
	{"target": 270, "tier": 2},
	{"target": 380, "boss": "elements"},
	{"target": 480, "tier": 2},
	{"target": 590, "tier": 3},
	{"target": 760, "tier": 3},
	{"target": 960, "boss": "final"},
]


const FAMILY_NAMES := {
	"bank": "Banks & cushions", "cue": "Cue control", "combo": "Combos & clusters", "streak": "Streaks",
	"pocket": "Pockets", "number": "Ball numbers", "solid": "Solids", "stripe": "Stripes", "eight": "The 8-ball", "clear": "Clearing your set", "gear": "Gear", "imbue": "Imbues", "special": "Special balls", "pause": "Pausing", "money": "Economy", "risk": "Risk & scaling",
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


static func ball_points(n: int) -> int:
	var k := kind_of(n)
	if k == "dice" or k == "wild":
		return 10 + int(faces.get(n, 0))
	return int(BALL_TYPES[k].value) if k != "" else 10 + n


static func is_stripe(n: int) -> bool:
	return n >= 9 and n <= 15


static func ball_color(n: int) -> Color:
	var k := kind_of(n)
	return BALL_TYPES[k].color if k != "" else BALL_COLORS.get(n, Color.WHITE)


static func rarity_name(r: int) -> String:
	return ["Common", "Uncommon", "Rare"][r]


static func rarity_color(r: int) -> Color:
	return [Color(0.55, 0.75, 0.95), Color(0.45, 0.9, 0.55), Color(1.0, 0.55, 0.3)][r]
