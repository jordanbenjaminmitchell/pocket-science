class_name Catalog
extends RefCounted
## All authored content: Formulas (passive upgrades), Reagents (one-shot
## consumables), Isotopes (per-ball enhancements), Labs and Anomalies (bosses).

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

## Formulas. "r": rarity 0 common, 1 uncommon, 2 rare.
const FORMULAS := {
	"elastic": {"name": "Elastic Collision", "r": 0, "cost": 4, "fam": "combo", "desc": "+4 Chips for every ball-to-ball collision in a scoring shot (max 12)."},
	"odd": {"name": "Odd Hypothesis", "r": 0, "cost": 4, "fam": "number", "desc": "Odd-numbered balls give +15 Chips."},
	"even": {"name": "Even Hypothesis", "r": 0, "cost": 4, "fam": "number", "desc": "Even-numbered balls give +2 Mult."},
	"stripes": {"name": "Stripe Theory", "r": 0, "cost": 5, "fam": "number", "desc": "Striped balls (9-15) give +4 Mult."},
	"solids": {"name": "Solid State", "r": 0, "cost": 5, "fam": "number", "desc": "Solid balls (1-7) give +25 Chips."},
	"corner": {"name": "Corner Theorem", "r": 0, "cost": 4, "fam": "pocket", "desc": "Pots in corner pockets give +2 Mult."},
	"side": {"name": "Side Effect", "r": 0, "cost": 5, "fam": "pocket", "desc": "Pots in side pockets give +5 Mult."},
	"lever": {"name": "Lever Arm", "r": 0, "cost": 5, "fam": "utility", "desc": "Long pots (ball travels 450+ to the pocket) give +4 Mult."},
	"chalk": {"name": "Spare Chalk", "r": 0, "cost": 5, "fam": "utility", "desc": "+1 Chalk on every table."},
	"jaws": {"name": "Wide Jaws", "r": 0, "cost": 6, "fam": "pocket", "desc": "Pockets are 12% wider."},
	"lens": {"name": "Long Lens", "r": 0, "cost": 4, "fam": "utility", "desc": "The guideline continues past the first cushion and shows the cue ball's full path to its next contact."},
	"interest": {"name": "Compound Interest", "r": 0, "cost": 5, "fam": "money", "desc": "After a table, earn $1 for every $5 you hold (max $5)."},
	"bank": {"name": "Angle of Incidence", "r": 1, "cost": 6, "fam": "bank", "desc": "Bank pots give +3 Mult per cushion instead of +1."},
	"kick": {"name": "Kick Drum", "r": 1, "cost": 6, "fam": "cue", "desc": "Kick shots (cue hits a cushion first) that pot: ×2 Mult."},
	"chain": {"name": "Chain Reaction", "r": 1, "cost": 7, "fam": "combo", "desc": "Combination pots (object ball into object ball) give ×2 Mult."},
	"multi": {"name": "Cluster Theory", "r": 1, "cost": 6, "fam": "combo", "desc": "Every extra ball potted in one shot gives +3 Mult instead of +1."},
	"streak": {"name": "Momentum", "r": 1, "cost": 7, "fam": "streak", "desc": "Your streak gives +3 Mult per step instead of +1."},
	"heat": {"name": "Heat Sink", "r": 1, "cost": 6, "fam": "pocket", "desc": "The hot pocket gives ×3 Mult instead of ×2, and +20 Chips."},
	"power": {"name": "Kinetic Energy", "r": 1, "cost": 5, "fam": "cue", "desc": "Shots at 85%+ power that pot give +5 Mult."},
	"finesse": {"name": "Finesse", "r": 1, "cost": 6, "fam": "cue", "desc": "Shots at 35% power or less that pot give ×2 Chips."},
	"prime": {"name": "Prime Directive", "r": 1, "cost": 6, "fam": "number", "desc": "Prime balls (2, 3, 5, 7, 11, 13) give +4 Mult."},
	"eight": {"name": "Black Hole", "r": 1, "cost": 6, "fam": "number", "desc": "The 8-ball gives ×3 instead of ×2, and pays $3."},
	"gold": {"name": "Gold Standard", "r": 1, "cost": 7, "fam": "money", "desc": "Each pot pays $1 (max $3 per shot)."},
	"entropy": {"name": "Entropy", "r": 1, "cost": 6, "fam": "streak", "desc": "+1 Mult for every shot already taken on this table."},
	"catalyst": {"name": "Catalyst", "r": 2, "cost": 8, "fam": "risk", "desc": "Gains +0.25 Mult permanently for every ball you pot."},
	"golden": {"name": "Golden Ratio", "r": 2, "cost": 8, "fam": "risk", "desc": "The first pot of every shot gives ×1.6 Mult."},
	"supernova": {"name": "Supernova", "r": 2, "cost": 9, "fam": "combo", "desc": "Shots that pot 3 or more balls: ×3 Mult."},
	"fusion": {"name": "Fusion", "r": 2, "cost": 8, "fam": "combo", "desc": "Two or more balls into the same pocket in one shot: ×3 Mult."},
	"magnet": {"name": "Magnetic Pockets", "r": 2, "cost": 9, "fam": "pocket", "desc": "Pockets gently pull nearby moving balls in."},
	"insurance": {"name": "Causality Insurance", "r": 2, "cost": 7, "fam": "utility", "desc": "The first 2 misses or scratches on each table cost no Chalk. Your streak still resets."},
	"oracle": {"name": "Laplace's Demon", "r": 2, "cost": 10, "fam": "utility", "desc": "See the real path of every ball for the first 1.5 seconds of each shot."},
	# ---- Cushions & banks
	"ricochet": {"name": "Ricochet", "r": 1, "cost": 6, "fam": "bank", "desc": "+2 Chips for every cushion any ball touches in a scoring shot (max 15)."},
	"cushion": {"name": "Cushion Theory", "r": 0, "cost": 4, "fam": "bank", "desc": "Bank pots give +20 Chips."},
	"geometry": {"name": "Sacred Geometry", "r": 2, "cost": 8, "fam": "bank", "desc": "Each bank pot gives ×1.5 Mult."},
	"tracer": {"name": "Tracer Round", "r": 0, "cost": 4, "fam": "bank", "desc": "+2 Mult for each cushion the cue ball touches after hitting a ball (max 3 cushions)."},
	# ---- Cue ball control
	"boomerang": {"name": "Boomerang", "r": 1, "cost": 6, "fam": "cue", "desc": "If the cue ball finishes within 120 of where it started, ×2 Mult."},
	"precision": {"name": "Precision", "r": 1, "cost": 6, "fam": "cue", "desc": "Clean pots (straight from the cue ball, no cushions) give +5 Mult."},
	"stun": {"name": "Stun Master", "r": 1, "cost": 6, "fam": "cue", "desc": "The cue ball loses 60% of its speed when it first hits a ball. Far fewer scratches."},
	"afterburner": {"name": "Afterburner", "r": 0, "cost": 5, "fam": "cue", "desc": "Break shots that pot give ×3 Mult."},
	# ---- Combinations
	"domino": {"name": "Domino Effect", "r": 0, "cost": 5, "fam": "combo", "desc": "Combination pots give +30 Chips."},
	# ---- Streaks
	"rhythm": {"name": "Rhythm", "r": 0, "cost": 5, "fam": "streak", "desc": "Every third scoring shot in a row gives ×2 Mult."},
	"hothand": {"name": "Hot Hand", "r": 1, "cost": 6, "fam": "streak", "desc": "With a streak of 3 or more, every pot gives +20 Chips."},
	"comeback": {"name": "Comeback", "r": 1, "cost": 6, "fam": "streak", "desc": "When you are down to your last Chalk, ×2 Mult."},
	# ---- Pockets
	"collector": {"name": "Pocket Collector", "r": 2, "cost": 8, "fam": "pocket", "desc": "+2 Mult for every different pocket you have potted into this table."},
	"migration": {"name": "Stay Hot", "r": 1, "cost": 6, "fam": "pocket", "desc": "The hot pocket only moves after a shot that does not score."},
	# ---- Ball numbers
	"lowball": {"name": "Low Ball", "r": 0, "cost": 4, "fam": "number", "desc": "Balls 1, 2 and 3 give +4 Mult."},
	"highball": {"name": "High Roller", "r": 0, "cost": 4, "fam": "number", "desc": "Balls 8 and above give +35 Chips."},
	"fibonacci": {"name": "Fibonacci", "r": 1, "cost": 6, "fam": "number", "desc": "Balls 1, 2, 3, 5, 8 and 13 give +3 Mult."},
	"rotation": {"name": "Rotation", "r": 1, "cost": 6, "fam": "number", "desc": "Potting the lowest-numbered ball on the table gives ×1.5 Mult."},
	"moneyball": {"name": "Money Ball", "r": 1, "cost": 7, "fam": "number", "desc": "Potting the highest-numbered ball on the table gives ×2 Mult and $2."},
	# ---- Economy
	"thrift": {"name": "Thrift", "r": 0, "cost": 4, "fam": "money", "desc": "Clear a table with 2+ Chalk left: +$5."},
	"venture": {"name": "Venture Capital", "r": 1, "cost": 6, "fam": "money", "desc": "+1 Mult for every $5 you hold (max +6)."},
	"hunter": {"name": "Bounty Hunter", "r": 0, "cost": 4, "fam": "money", "desc": "Bounties pay double."},
	"coupon": {"name": "Coupon Book", "r": 0, "cost": 3, "fam": "money", "desc": "Rerolls in the Lab Supply start at $1."},
	"overflow": {"name": "Overflow", "r": 1, "cost": 5, "fam": "money", "desc": "Points scored over a table's target carry into the next table (up to 25% of its target)."},
	# ---- Risk & build-around
	"glasscannon": {"name": "Glass Cannon", "r": 2, "cost": 8, "fam": "risk", "desc": "×3 Mult on every scoring shot, but misses and scratches cost 2 Chalk."},
	"minimalist": {"name": "Minimalist", "r": 2, "cost": 7, "fam": "risk", "desc": "×1.5 Mult for every empty Formula slot."},
	"echo": {"name": "Echo Chamber", "r": 2, "cost": 9, "fam": "risk", "desc": "The first ×Mult of every shot triggers twice."},
	# ---- Physics
	"featherweight": {"name": "Featherweight", "r": 1, "cost": 6, "fam": "physics", "desc": "Object balls are 25% lighter: they fly further when struck."},
	"velvet": {"name": "Velvet Cloth", "r": 0, "cost": 5, "fam": "physics", "desc": "30% less cloth friction: balls roll further."},
}

## Reagents: single-use, held in two slots, used before a shot.
const REAGENTS := {
	"bluechalk": {"name": "Blue Chalk", "cost": 3, "desc": "Your next shot gets ×2 Mult."},
	"hand": {"name": "Ball in Hand", "cost": 3, "desc": "Pick up the cue ball and place it anywhere."},
	"spare": {"name": "Chalk Cube", "cost": 3, "desc": "+1 Chalk on this table."},
	"forecast": {"name": "Forecast", "cost": 3, "desc": "See every ball's full real path for your next shot."},
	"hotswap": {"name": "Hot Swap", "cost": 2, "desc": "Move the hot pocket to the pocket you click."},
	"scatter": {"name": "Scatter", "cost": 3, "desc": "Blast every object ball to a new clear spot on the table."},
	"freshrack": {"name": "Fresh Rack", "cost": 4, "desc": "Replace the table with a new rack and take a free break."},
	"second": {"name": "Second Chance", "cost": 3, "desc": "Your next miss or scratch on this table costs no Chalk."},
	"callshot": {"name": "Call Shot", "cost": 3, "desc": "Click a pocket. Pots there on your next shot give ×3 Mult."},
	"adrenaline": {"name": "Adrenaline", "cost": 3, "desc": "+3 to your current streak."},
	"grant": {"name": "Research Grant", "cost": 2, "desc": "Gain $5 right now."},
	"wideopen": {"name": "Wide Open", "cost": 3, "desc": "Pockets are 25% wider for your next shot."},
	"magnetize": {"name": "Magnetize", "cost": 3, "desc": "Pockets pull moving balls in during your next shot."},
	"overcharge": {"name": "Overcharge", "cost": 3, "desc": "Your next shot gets ×2 Chips."},
	"contract": {"name": "Bounty Contract", "cost": 2, "desc": "Swap this table's Bounty for a new one, paying double."},
}

## Isotopes enhance a specific ball number for the rest of the run.
const ISOTOPES := {
	"neon": {"name": "Neon", "cost": 4, "color": Color(0.3, 1.0, 0.85), "desc": "+4 Mult when this ball is potted."},
	"gold": {"name": "Gilded", "cost": 4, "color": Color(1.0, 0.82, 0.3), "desc": "+$2 when this ball is potted."},
	"heavy": {"name": "Tungsten", "cost": 3, "color": Color(0.75, 0.78, 0.85), "desc": "+40 Chips when this ball is potted."},
	"glass": {"name": "Glass", "cost": 5, "color": Color(0.7, 0.85, 1.0), "desc": "×2 Mult when potted, but 1 in 4 chance it shatters (enhancement lost)."},
	"radium": {"name": "Radium", "cost": 5, "color": Color(0.55, 1.0, 0.25), "desc": "+10 Mult when potted, decaying by 2 each time (minimum +2)."},
	"prismatic": {"name": "Prismatic", "cost": 5, "color": Color(1.0, 0.55, 0.95), "desc": "+20 Chips and +2 Mult when potted."},
	"lucky": {"name": "Lucky", "cost": 4, "color": Color(0.35, 0.95, 0.5), "desc": "1 in 3 chance of ×3 Mult when potted."},
	"resonant": {"name": "Resonant", "cost": 4, "color": Color(0.5, 0.65, 1.0), "desc": "This ball's Chips count twice."},
}

## Starting cues: each run begins by choosing one. "shaft"/"butt"/"accent" colour the stick.
const CUES := {
	"maple": {"name": "Classic Maple", "desc": "The all-rounder. $4 and a Blue Chalk to start.", "money": 4, "formulas": [], "reagents": ["bluechalk"], "chalk": 0,
		"shaft": Color(0.86, 0.72, 0.5), "butt": Color(0.32, 0.14, 0.07), "accent": Color(0.9, 0.85, 0.7)},
	"optic": {"name": "Optic Cue", "desc": "Starts with Long Lens: see banks and the full cue-ball path. $2.", "money": 2, "formulas": ["lens"], "reagents": [], "chalk": 0,
		"shaft": Color(0.8, 0.86, 0.9), "butt": Color(0.1, 0.25, 0.4), "accent": Color(0.4, 0.85, 1.0)},
	"hotrod": {"name": "Hot Rod", "desc": "Starts with Heat Sink (hot pocket ×3), but every table has 1 less Chalk. $4.", "money": 4, "formulas": ["heat"], "reagents": [], "chalk": -1,
		"shaft": Color(0.85, 0.7, 0.5), "butt": Color(0.6, 0.12, 0.05), "accent": Color(1.0, 0.55, 0.1)},
	"momentum": {"name": "Momentum Cue", "desc": "Starts with Momentum (+3 Mult per streak step). Run-outs explode. $4.", "money": 4, "formulas": ["streak"], "reagents": [], "chalk": 0,
		"shaft": Color(0.88, 0.78, 0.6), "butt": Color(0.12, 0.12, 0.14), "accent": Color(0.6, 1.0, 0.5)},
	"gilded": {"name": "Gilded Cue", "desc": "Starts rich: $12 and Compound Interest. No chalk cube.", "money": 12, "formulas": ["interest"], "reagents": [], "chalk": 0,
		"shaft": Color(0.92, 0.82, 0.55), "butt": Color(0.45, 0.32, 0.08), "accent": Color(1.0, 0.85, 0.3)},
	"breaker": {"name": "Break Cue", "desc": "Starts with Afterburner (break pots ×3 Mult). $3.", "money": 3, "formulas": ["afterburner"], "reagents": [], "chalk": 0,
		"shaft": Color(0.75, 0.75, 0.78), "butt": Color(0.5, 0.1, 0.5), "accent": Color(0.85, 0.5, 1.0)},
	"banker": {"name": "Banker's Cue", "desc": "Starts with Thrift and $8.", "money": 8, "formulas": ["thrift"], "reagents": [], "chalk": 0,
		"shaft": Color(0.9, 0.85, 0.7), "butt": Color(0.1, 0.3, 0.15), "accent": Color(0.75, 0.9, 0.3)},
	"thermal": {"name": "Thermal Cue", "desc": "Starts with Stay Hot: the hot pocket only moves after a shot that does not score. $3.", "money": 3, "formulas": ["migration"], "reagents": [], "chalk": 0,
		"shaft": Color(0.9, 0.75, 0.55), "butt": Color(0.75, 0.3, 0.05), "accent": Color(1.0, 0.7, 0.2)},
	"angle": {"name": "Angle Cue", "desc": "Starts with Angle of Incidence (banks +3 Mult per cushion). $2.", "money": 2, "formulas": ["bank"], "reagents": [], "chalk": 0,
		"shaft": Color(0.8, 0.85, 0.8), "butt": Color(0.1, 0.4, 0.3), "accent": Color(0.35, 0.8, 0.5)},
	"glass": {"name": "Glass Cue", "desc": "Starts with Glass Cannon (×3 Mult, misses cost 2 Chalk). 1 less Chalk. $4.", "money": 4, "formulas": ["glasscannon"], "reagents": [], "chalk": -1,
		"shaft": Color(0.85, 0.92, 1.0), "butt": Color(0.55, 0.7, 0.9), "accent": Color(1.0, 0.35, 0.65)},
}

## Labs set the table physics and cloth. "felt" is the cloth colour.
const LABS := {
	"standard": {"name": "Standard Felt", "felt": Color(0.06, 0.42, 0.28), "desc": "A clean, fast cloth. Pure pool."},
	"cryo": {"name": "Cryo Felt", "felt": Color(0.12, 0.42, 0.55), "desc": "Low friction: balls roll much further. All pots +1 Mult."},
	"cyclotron": {"name": "Cyclotron", "felt": Color(0.3, 0.2, 0.48), "desc": "A spring bumper sits mid-table. +10 Chips per bumper hit in a scoring shot."},
	"spring": {"name": "Spring Rails", "felt": Color(0.5, 0.14, 0.16), "desc": "Lively cushions. Bank pots give +1 extra Mult per cushion."},
	"gravity": {"name": "Gravity Well", "felt": Color(0.09, 0.2, 0.42), "desc": "A well at the centre bends moving balls toward it."},
	"current": {"name": "The Current", "felt": Color(0.05, 0.36, 0.42), "desc": "Moving balls drift toward the right rail. All pots +2 Mult."},
	"magnetlab": {"name": "Magnet Lab", "felt": Color(0.42, 0.13, 0.32), "desc": "Pockets pull moving balls in. Every pot gives 5 fewer Chips."},
	"dense": {"name": "Neutron Cloth", "felt": Color(0.2, 0.26, 0.13), "desc": "Heavy cloth stops balls quickly. All pots +15 Chips."},
	"pinball": {"name": "Pinball Lab", "felt": Color(0.42, 0.26, 0.07), "desc": "Four spring bumpers. +6 Chips per bumper hit in a scoring shot."},
	"repulsor": {"name": "Repulsor", "felt": Color(0.12, 0.13, 0.38), "desc": "The centre pushes moving balls away. Bank pots give +1 extra Mult per cushion."},
}

## Anomalies are boss rules on every third table.
const ANOMALIES := {
	"tight": {"name": "Tight Pockets", "desc": "Pockets are 12% narrower."},
	"sealed": {"name": "Sealed Sides", "desc": "Both side pockets are closed."},
	"lead": {"name": "Lead Rack", "desc": "Object balls are 60% heavier."},
	"fog": {"name": "Fog", "desc": "The guideline stops at the ghost ball."},
	"dry": {"name": "Dry Chalk", "desc": "You start with 1 less Chalk."},
	"cold": {"name": "Cold Pockets", "desc": "There is no hot pocket."},
	"shrink": {"name": "Shrinking Pockets", "desc": "Every pocket narrows by 3% after each shot (down to 75%)."},
	"onepocket": {"name": "Two Pockets", "desc": "Only the hot pocket and the pocket diagonally opposite it score. Pots elsewhere score nothing (no Chalk lost)."},
	"rotation": {"name": "Rotation Rules", "desc": "Hit the lowest-numbered ball first, or the shot scores nothing and your streak resets (no Chalk lost)."},
	"heavycue": {"name": "Heavy Cue Ball", "desc": "The cue ball is twice as heavy: it follows through and scratches more."},
	"blackice": {"name": "Black Ice", "desc": "Almost no friction and lively cushions. Control is everything."},
	"taxman": {"name": "The Taxman", "desc": "Every scoring shot loses 15% of its Chips."},
	"blind": {"name": "Blind Pockets", "desc": "The guideline never turns gold and pots show no value tag."},
	"tilt": {"name": "Tilted Table", "desc": "The table slopes: moving balls drift toward one long rail. The guideline ignores the tilt."},
	"cursed8": {"name": "Cursed 8", "desc": "Potting the 8-ball scores nothing, breaks your streak and costs 1 Chalk."},
}

## Per-table side goals. Each table rolls one; completing it pays immediately.
const BOUNTIES := {
	"bank": {"name": "Sink a bank shot", "reward": 3},
	"combo": {"name": "Pot a combination", "reward": 3},
	"double": {"name": "Pot 2+ balls in one shot", "reward": 3},
	"triple": {"name": "Pot 3+ balls in one shot", "reward": 5},
	"kick": {"name": "Pot off a kick shot", "reward": 5},
	"hot": {"name": "Pot into the hot pocket", "reward": 2},
	"streak4": {"name": "Reach a streak of 4", "reward": 4},
	"big": {"name": "Score 150+ in one shot", "reward": 4},
	"side": {"name": "Pot into a side pocket", "reward": 2},
	"eight": {"name": "Pot the 8-ball", "reward": 3},
	"bank2": {"name": "Sink a 2-cushion bank", "reward": 6},
	"big300": {"name": "Score 300+ in one shot", "reward": 5},
	"big600": {"name": "Score 600+ in one shot", "reward": 7},
	"streak3": {"name": "Reach a streak of 3", "reward": 2},
	"streak6": {"name": "Reach a streak of 6", "reward": 7},
	"corner": {"name": "Pot into a corner pocket", "reward": 1},
	"hot2": {"name": "Pot 2 balls into the hot pocket", "reward": 7},
	"quad": {"name": "Pot 4+ balls in one shot", "reward": 8},
	"stripe": {"name": "Pot a striped ball", "reward": 2},
	"solid": {"name": "Pot a solid ball", "reward": 1},
	"soft": {"name": "Pot with a soft shot (35% power or less)", "reward": 3},
	"hard": {"name": "Pot with a power shot (85% or more)", "reward": 3},
	"breakpot": {"name": "Pot a ball on the break", "reward": 3},
	"mult10": {"name": "Reach 10 Mult on a shot", "reward": 4},
	"chips100": {"name": "Reach 100 Chips on a shot", "reward": 5},
}

## Difficulty ladder. Each Stake includes every rule before it.
const STAKES := [
	{"name": "Standard", "desc": "The game as designed."},
	{"name": "Scuffed Cloth", "desc": "Table targets are 15% higher."},
	{"name": "Chalk Shortage", "desc": "1 less Chalk on every table."},
	{"name": "Tight Budget", "desc": "Everything in the Lab Supply costs $1 more."},
	{"name": "Narrow Jaws", "desc": "Pockets are 5% narrower."},
	{"name": "High Stakes", "desc": "Table targets are 30% higher again."},
]

const TABLES := [
	{"target": 60, "rack": "nine"},
	{"target": 160, "rack": "nine"},
	{"target": 340, "rack": "nine", "boss": true},
	{"target": 550, "rack": "ten"},
	{"target": 800, "rack": "ten"},
	{"target": 1150, "rack": "fifteen", "boss": true},
	{"target": 1500, "rack": "fifteen"},
	{"target": 2000, "rack": "fifteen"},
	{"target": 2800, "rack": "fifteen", "boss": true},
]


const FAMILY_NAMES := {
	"bank": "Banks & cushions", "cue": "Cue control", "combo": "Combos & clusters", "streak": "Streaks",
	"pocket": "Pockets", "number": "Ball numbers", "money": "Economy", "risk": "Risk & scaling",
	"physics": "Physics", "utility": "Utility",
}


static func family_name(id: String) -> String:
	return FAMILY_NAMES.get(FORMULAS[id].get("fam", "utility"), "Utility")


## Owned formulas that share a family with id (for synergy hints).
static func synergies(id: String, owned: Array) -> Array:
	var fam: String = FORMULAS[id].get("fam", "")
	if fam == "" or fam == "utility":
		return []
	return owned.filter(func(o): return o != id and FORMULAS[o].get("fam", "") == fam)


static func ball_points(n: int) -> int:
	return 10 + n


static func is_stripe(n: int) -> bool:
	return n >= 9


static func ball_color(n: int) -> Color:
	return BALL_COLORS.get(n, Color.WHITE)


static func rarity_name(r: int) -> String:
	return ["Common", "Uncommon", "Rare"][r]


static func rarity_color(r: int) -> Color:
	return [Color(0.55, 0.75, 0.95), Color(0.45, 0.9, 0.55), Color(1.0, 0.55, 0.3)][r]
