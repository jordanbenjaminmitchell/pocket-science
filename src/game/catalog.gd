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
	"elastic": {"name": "Neodymium Boulder", "z": 60, "r": 1, "cost": 6, "fam": "physics", "desc": "The cue ball is 90% bigger, just small enough to fit a pocket, and twice as heavy."},
	"odd": {"name": "Fluorine Flare", "z": 9, "r": 0, "cost": 4, "fam": "number", "desc": "Odd-numbered balls are worth +2× their number (the 1 gets +2, the 9 gets +18).", "fx": {"when": "odd", "per_num": 2}},
	"even": {"name": "Erbium Laser", "z": 68, "r": 0, "cost": 4, "fam": "number", "desc": "Even-numbered balls add +0.75 Chain as they sink.", "fx": {"when": "even", "chain": 0.75}},
	"stripes": {"name": "Chromium Stripes", "z": 24, "r": 0, "cost": 5, "fam": "stripe", "desc": "Striped balls score ×1.5.", "fx": {"when": "stripe", "x": 1.5}},
	"solids": {"name": "Silicon Wafer", "z": 14, "r": 0, "cost": 5, "fam": "solid", "desc": "Solid balls are worth +3× their number (the 1 gets +3, the 7 gets +21).", "fx": {"when": "solid", "per_num": 3}},
	"corner": {"name": "Curium Corner", "z": 96, "r": 0, "cost": 4, "fam": "pocket", "desc": "Corner pockets add +0.5 Chain as the ball sinks.", "fx": {"when": "corner", "chain": 0.5}},
	"side": {"name": "Strontium Firework", "z": 38, "r": 0, "cost": 5, "fam": "pocket", "desc": "Side pockets score ×2, and the hot pocket is never a side pocket.", "fx": {"when": "side", "x": 2.0}},
	"lever": {"name": "Tungsten Core", "z": 74, "r": 0, "cost": 5, "fam": "stripe", "desc": "Stripes weigh 140% and lose no speed off cushions: they plough on through other balls."},
	"chalk": {"name": "Calcium Chalk", "z": 20, "r": 0, "cost": 5, "fam": "utility", "min_table": 3, "desc": "Clearing a table gives +1 extra Chalk."},
	"jaws": {"name": "Titanium Jaws", "z": 22, "r": 0, "cost": 6, "fam": "pocket", "desc": "Pockets are 20% wider."},
	"lens": {"name": "Selenium Lens", "z": 34, "r": 0, "cost": 4, "fam": "utility", "desc": "A sink where the sunk ball rolled at least 1.1 m (almost half the table) adds +1 Chain.", "fx": {"when": "long", "chain": 1.0}},
	"bank": {"name": "Platinum Rail", "z": 78, "r": 1, "cost": 6, "fam": "bank", "desc": "Bank sinks add +1 Chain per cushion."},
	"kick": {"name": "Potassium Kick", "z": 19, "r": 1, "cost": 6, "fam": "cue", "desc": "Once per table: the first kick shot (cue hits a cushion first) that sinks scores ×2 on every sink.", "fx": {"when": "kick", "x": 2.0, "once": true}},
	"chain": {"name": "Sulfur Reagent", "z": 16, "r": 1, "cost": 7, "fam": "gear", "desc": "On a shot where you used a Catalyst, every sink is worth +10, and clearing the table on that shot pays $1 per table number.", "fx": {"when": "item_shot", "value": 10}},
	"multi": {"name": "Boron Cluster", "z": 5, "r": 1, "cost": 6, "fam": "combo", "desc": "Every ball after the first in a shot adds +1 Chain as it sinks.", "fx": {"when": "extra", "chain": 1.0}},
	"streak": {"name": "Phosphorus Match", "z": 15, "r": 1, "cost": 7, "fam": "streak", "desc": "Shots that sink 2+ balls add +1 extra Heat."},
	"heat": {"name": "Magnesium Torch", "z": 12, "r": 1, "cost": 6, "fam": "pocket", "desc": "The hot pocket scores ×3 instead of ×2."},
	"power": {"name": "Uranium Reactor", "z": 92, "r": 1, "cost": 5, "fam": "cue", "desc": "At 85%+ power, the first ball the cue ball hits flies off 20% faster: a chain reaction."},
	"finesse": {"name": "Indium Touch", "z": 49, "r": 1, "cost": 6, "fam": "cue", "desc": "Shots at 35% power or less score ×2.", "fx": {"when": "soft", "x": 2.0}},
	"prime": {"name": "Promethium Prime", "z": 61, "r": 1, "cost": 6, "fam": "number", "desc": "Prime balls (2, 3, 5, 7, 11, 13 and up) score ×2. With no prime on the table, the next prime joins your rack.", "fx": {"when": "prime", "x": 2.0}},
	"eight": {"name": "Carbon Core", "z": 6, "r": 1, "cost": 6, "fam": "eight", "desc": "The 8 stops costing you points, scores like any other ball, and pays $3.", "fx": {"when": "eight", "money": 3}},
	"darkhorse": {"name": "Oxygen Octet", "z": 8, "r": 2, "cost": 9, "fam": "eight", "desc": "The 8 scores ×8 when it sinks. You still lose points if it sinks early.", "fx": {"when": "eight", "x": 8.0}},
	"hushmoney": {"name": "Silver Tongue", "z": 47, "r": 0, "cost": 4, "fam": "money", "desc": "Sinking the 8 early pays you $3 and costs no points. It is still a foul."},
	"kissblack": {"name": "Antimony Kohl", "z": 51, "r": 1, "cost": 6, "fam": "eight", "desc": "If the cue ball hits the 8 first (not on the break) and the shot sinks a ball, every sink scores ×2.", "fx": {"when": "kiss8", "x": 2.0}},
	"steerclear": {"name": "Neon Sign", "z": 10, "r": 0, "cost": 5, "fam": "eight", "desc": "If no ball touches the 8 during a shot, each sink adds +0.5 Chain.", "fx": {"when": "no_eight_touch", "chain": 0.5}},
	"lastcall": {"name": "Polonium Halo", "z": 84, "r": 1, "cost": 6, "fam": "eight", "desc": "If the 8 is the only ball left, the pockets pull it in, and sinking it scores ×5 and pays $5.", "fx": {"when": "last_eight", "x": 5.0, "money": 5}},
	"eightcount": {"name": "Krypton Tally", "z": 36, "r": 1, "cost": 6, "fam": "eight", "desc": "Every 8th ball you sink in a run scores ×3.", "fx": {"when": "eight_count", "x": 3.0}},
	"trouble": {"name": "Plutonium Pit", "z": 94, "r": 2, "cost": 7, "fam": "eight", "desc": "When the 8 sinks early, gain +3 Heat. You still lose the points."},
	"solidgold": {"name": "Gold Bar", "z": 79, "r": 1, "cost": 6, "fam": "solid", "desc": "Each solid you sink pays $1.", "fx": {"when": "solid", "money": 1}},
	"bedrock": {"name": "Aluminium Ore", "z": 13, "r": 1, "cost": 8, "fam": "solid", "desc": "Shots that sink only solids add +1 Heat for each solid sunk."},
	"steadyrun": {"name": "Yttrium Ladder", "z": 39, "r": 1, "cost": 6, "fam": "solid", "desc": "Each solid sunk in a row makes solids worth +12 more (max +96). A stripe, or a new table, resets it."},
	"solidsonly": {"name": "Tantalum Plate", "z": 73, "r": 2, "cost": 9, "fam": "solid", "desc": "Solids score ×3, but stripes score ×0.5."},
	"lastsolid": {"name": "Bismuth Crystal", "z": 83, "r": 2, "cost": 8, "fam": "solid", "desc": "When you sink the only solid left on the table, it scores ×8.", "fx": {"when": "last_solid", "x": 8.0}},
	"racing": {"name": "Rubidium Rocket", "z": 37, "r": 1, "cost": 6, "fam": "stripe", "desc": "Stripes are 30% lighter and roll 25% further."},
	"luckystripe": {"name": "Lutetium Luck", "z": 71, "r": 1, "cost": 6, "fam": "stripe", "desc": "Each stripe you sink has a 1 in 3 chance to score ×3 and pay $2."},
	"tiger": {"name": "Terbium Tiger", "z": 65, "r": 1, "cost": 7, "fam": "stripe", "desc": "Each stripe sunk in a row on this table adds +0.25 Chain to the next (max +2). A solid resets it."},
	"stripesonly": {"name": "Zirconium Gem", "z": 40, "r": 2, "cost": 9, "fam": "stripe", "desc": "Stripes score ×2, but solids score ×0.5."},
	"laststripe": {"name": "Lead Anchor", "z": 82, "r": 1, "cost": 6, "fam": "eight", "desc": "The 8 weighs 300%, and it rattles out of the pockets until it is the last ball: no more early 8s."},
	"gold": {"name": "Copper Penny", "z": 29, "r": 1, "cost": 7, "fam": "money", "desc": "Each sink pays $1 (max $3 per shot)."},
	"entropy": {"name": "Samarium Simmer", "z": 62, "r": 1, "cost": 6, "fam": "heat", "desc": "Below Heat 3, shots start with +1 Chain."},
	"catalyst": {"name": "Beryllium Avalanche", "z": 4, "r": 2, "cost": 8, "fam": "risk", "desc": "Every ball you sink gives 2 random balls in your rack +4 for the rest of the run."},
	"golden": {"name": "Iron Fist", "z": 26, "r": 2, "cost": 8, "fam": "risk", "desc": "Once per table: your first sink scores ×3.", "fx": {"when": "first", "x": 3.0, "once": true}},
	"supernova": {"name": "Nickel Supernova", "z": 28, "r": 2, "cost": 9, "fam": "combo", "desc": "Shots that sink 3 or more balls score ×2 on every sink.", "fx": {"when": "triple", "x": 2.0}},
	"fusion": {"name": "Helium Fusion", "z": 2, "r": 1, "cost": 6, "fam": "combo", "desc": "Sink a ball into the same pocket as your last sink (this shot or your last one) and it scores ×2.", "fx": {"when": "repeat_pocket", "x": 2.0}},
	"magnet": {"name": "Gadolinium Pull", "z": 64, "r": 2, "cost": 9, "fam": "pocket", "desc": "Pockets gently pull nearby moving balls in."},
	"insurance": {"name": "Argon Shield", "z": 18, "r": 2, "cost": 7, "fam": "utility", "desc": "The first 2 misses or scratches on each table cost no Chalk."},
	"oracle": {"name": "Tellurium Supply", "z": 52, "r": 2, "cost": 10, "fam": "gear", "desc": "At the start of each table, get a random Catalyst for that table only, if you have a free Catalyst slot."},
	"ricochet": {"name": "Rhenium Ricochet", "z": 75, "r": 1, "cost": 6, "fam": "bank", "desc": "Every cushion a ball touches adds +0.25 extra Chain."},
	"cushion": {"name": "Sodium Cushion", "z": 11, "r": 0, "cost": 4, "fam": "bank", "desc": "Bank sinks are worth +30.", "fx": {"when": "bank", "value": 30}},
	"geometry": {"name": "Germanium Angles", "z": 32, "r": 2, "cost": 8, "fam": "bank", "desc": "Once per table: your first bank sink scores ×1.5 for every cushion it touched (×2.25 off two)."},
	"tracer": {"name": "Radium Trail", "z": 88, "r": 0, "cost": 4, "fam": "bank", "desc": "Every cushion the cue ball touches after contact adds +0.25 Chain."},
	"boomerang": {"name": "Bromine Boomerang", "z": 35, "r": 1, "cost": 6, "fam": "cue", "desc": "If the cue ball stops within 30 cm of where you struck it, every sink scores ×2.", "fx": {"when": "boomerang", "x": 2.0}},
	"precision": {"name": "Chlorine Clean", "z": 17, "r": 1, "cost": 6, "fam": "cue", "desc": "Clean sinks (straight from the cue ball, no cushions) add +1 Chain.", "fx": {"when": "clean", "chain": 1.0}},
	"stun": {"name": "Thorium Stopper", "z": 90, "r": 1, "cost": 6, "fam": "cue", "desc": "The cue ball loses 60% of its speed when it first hits a ball. Far fewer scratches."},
	"afterburner": {"name": "Berkelium Break", "z": 97, "r": 0, "cost": 5, "fam": "cue", "desc": "Place the cue ball anywhere on the table for the break."},
	"domino": {"name": "Dysprosium Domino", "z": 66, "r": 1, "cost": 6, "fam": "physics", "desc": "Balls lose no speed when they hit each other, so a hit passes its full speed down a line of balls."},
	"rhythm": {"name": "Rhodium Rhythm", "z": 45, "r": 0, "cost": 5, "fam": "streak", "desc": "Every third shot on a table scores ×2.", "fx": {"when": "third", "x": 2.0}},
	"hothand": {"name": "Holmium Magnet", "z": 67, "r": 1, "cost": 6, "fam": "heat", "desc": "At Heat 3 or more, pockets pull nearby rolling balls in."},
	"comeback": {"name": "Lanthanum Lantern", "z": 57, "r": 1, "cost": 6, "fam": "streak", "desc": "On your last Chalk, every sink scores ×2.", "fx": {"when": "last_chalk", "x": 2.0}},
	"collector": {"name": "Gallium Glide", "z": 31, "r": 1, "cost": 6, "fam": "cue", "desc": "The cue ball rolls 50% further on the cloth."},
	"migration": {"name": "Hafnium Rod", "z": 72, "r": 1, "cost": 6, "fam": "heat", "desc": "While Heat is 4 or more, a miss only costs 1 Heat instead of half."},
	"lowball": {"name": "Lithium Cell", "z": 3, "r": 0, "cost": 4, "fam": "solid", "desc": "Your 3 lowest-value balls are charged: they lose no speed off cushions, and each pays $1 when it sinks."},
	"highball": {"name": "Actinium Ray", "z": 89, "r": 0, "cost": 4, "fam": "stripe", "needs_balls": [13, 14, 15], "desc": "Balls 13, 14 and 15 score ×2.5.", "fx": {"when": "high3", "x": 2.5}},
	"fibonacci": {"name": "Fermium Spiral", "z": 100, "r": 1, "cost": 6, "fam": "number", "desc": "Sink every Fibonacci ball in your rack (1, 2, 3, 5, 8, then 13 and up) this run and the next Fibonacci ball joins your rack for good; then start again."},
	"rotation": {"name": "Praseodymium Twin", "z": 59, "r": 1, "cost": 6, "fam": "number", "desc": "The lowest-numbered ball on the table scores as if it were the highest-numbered one."},
	"moneyball": {"name": "Californium Jackpot", "z": 98, "r": 1, "cost": 6, "fam": "number", "desc": "Every ball's number counts ×3 instead of ×2."},
	"thrift": {"name": "Cerium Flint", "z": 58, "r": 0, "cost": 4, "fam": "money", "desc": "Clear a table with 3+ Chalk left: +$5."},
	"venture": {"name": "Palladium Vault", "z": 46, "r": 1, "cost": 6, "fam": "money", "desc": "Shots start with +0.25 Chain for every $5 you hold (max +1.5)."},
	"hunter": {"name": "Scandium Hustle", "z": 21, "r": 0, "cost": 4, "fam": "money", "desc": "Side bets you win pay double."},
	"coupon": {"name": "Cadmium Chill", "z": 48, "r": 0, "cost": 4, "fam": "heat", "desc": "At Heat 0, every sink scores ×2.", "fx": {"when": "cold", "x": 2.0}},
	"overflow": {"name": "Neptunium Tide", "z": 93, "r": 1, "cost": 5, "fam": "utility", "desc": "Points you score over a table's target carry into the next table's score (up to 25% of the next target)."},
	"glasscannon": {"name": "Astatine Edge", "z": 85, "r": 2, "cost": 8, "fam": "risk", "desc": "Every sink scores ×2, but every miss and foul costs 1 more Chalk.", "fx": {"when": "any", "x": 2.0}},
	"minimalist": {"name": "Iridium Flame", "z": 77, "r": 2, "cost": 8, "fam": "heat", "desc": "While On fire (Heat 5+), every sink scores ×2.", "fx": {"when": "on_fire", "x": 2.0}},
	"echo": {"name": "Europium Echo", "z": 63, "r": 2, "cost": 9, "fam": "imbue", "desc": "When a ball with an Isotope sinks, its Isotope echoes onto a random ball on the table that has none, until the table ends."},
	"featherweight": {"name": "Hydrogen Balloon", "z": 1, "r": 2, "cost": 8, "fam": "physics", "desc": "The cue ball floats: if it would drop into a pocket, it bobs back out instead. No more pocket scratches."},
	"heavyhit": {"name": "Osmium Cue", "z": 76, "r": 1, "cost": 6, "fam": "physics", "desc": "The cue ball is 30% heavier, so it drives balls further."},
	"liverails": {"name": "Nitrogen Tyres", "z": 7, "r": 0, "cost": 5, "fam": "physics", "desc": "The cue ball comes off every cushion 15% faster than it hit it."},
	"slowcloth": {"name": "Thallium Felt", "z": 81, "r": 0, "cost": 4, "fam": "physics", "desc": "Thick nap: the cue ball stops 35% sooner for tight position, while object balls roll 25% further."},
	"backspin": {"name": "Barium Spin", "z": 56, "r": 1, "cost": 6, "fam": "physics", "desc": "Draw and follow are twice as strong."},
	"bigbreak": {"name": "Radon Burst", "z": 86, "r": 0, "cost": 5, "fam": "physics", "desc": "Break shots hit 25% harder."},
	"longarm": {"name": "Molybdenum Shaft", "z": 42, "r": 1, "cost": 6, "fam": "physics", "desc": "Full power hits 30% harder."},
	"masse": {"name": "Manganese Swerve", "z": 25, "r": 1, "cost": 6, "fam": "cue", "desc": "Side spin bends the cue ball twice as much off cushions."},
	"followthru": {"name": "Francium Fizz", "z": 87, "r": 1, "cost": 6, "fam": "risk", "desc": "Scratch while sinking 2 or more balls and the shot still scores, with no Chalk lost."},
	"drawartist": {"name": "Ytterbium Twin", "z": 70, "r": 1, "cost": 6, "fam": "cue", "desc": "After your first shot on each table, a second cue ball appears. Click a cue ball to choose which one you shoot."},
	"thinrack": {"name": "Thulium Thinning", "z": 69, "r": 1, "cost": 6, "fam": "clear", "desc": "Every ball removed from your rack makes all balls worth +1."},
	"missing": {"name": "Technetium Gap", "z": 43, "r": 1, "cost": 7, "fam": "clear", "desc": "Shots start with +0.5 Chain for each ball you have removed from your rack (max +3)."},
	"cleanhouse": {"name": "Iodine Swab", "z": 53, "r": 0, "cost": 3, "fam": "clear", "desc": "Removing a ball in the Pro Shop is free."},
	"packrat": {"name": "Protactinium Pack", "z": 91, "r": 0, "cost": 4, "fam": "gear", "desc": "+3 Catalyst slots."},
	"quartermaster": {"name": "Zinc Coupon", "z": 30, "r": 0, "cost": 4, "fam": "gear", "desc": "Catalysts cost $2 less."},
	"tinkerer": {"name": "Tin Toolbox", "z": 50, "r": 1, "cost": 6, "fam": "gear", "desc": "Every table, a random Catalyst you hold gets one extra use."},
	"enchanter": {"name": "Einsteinium Lab", "z": 99, "r": 0, "cost": 4, "fam": "imbue", "desc": "Isotopes cost $2 less."},
	"secondcoat": {"name": "Cobalt Glaze", "z": 27, "r": 1, "cost": 7, "fam": "imbue", "desc": "Isotope balls score ×1.5."},
	"goldrush": {"name": "Ruthenium Nugget", "z": 44, "r": 1, "cost": 6, "fam": "special", "desc": "Exotic balls score ×1.5."},
	"menagerie": {"name": "Niobium Menagerie", "z": 41, "r": 1, "cost": 6, "fam": "special", "desc": "Shots start with +0.25 Chain for each Exotic ball in your rack."},
	"alchemy": {"name": "Arsenic Mutation", "z": 33, "r": 2, "cost": 8, "fam": "special", "desc": "After each table, one plain ball in your rack (never the 8) turns into a random Exotic ball."},
	"stillness": {"name": "Xenon Flash", "z": 54, "r": 1, "cost": 6, "fam": "pause", "desc": "Once a table, the first time you pause a shot, every rolling ball speeds up by 30%."},
	"quickhands": {"name": "Mercury Messenger", "z": 80, "r": 0, "cost": 4, "fam": "pause", "desc": "The first Catalyst you use on each table doesn't spend a use."},
	"afterimage": {"name": "Americium Beacon", "z": 95, "r": 1, "cost": 6, "fam": "gear", "desc": "The first Catalyst you use on each table also gives that shot +2 Chain and +1 Heat."},
	"overclock": {"name": "Caesium Clock", "z": 55, "r": 2, "cost": 8, "fam": "pause", "desc": "Your Catalysts get two uses on every table."},
	"velvet": {"name": "Vanadium Velvet", "z": 23, "r": 0, "cost": 5, "fam": "physics", "desc": "30% less cloth friction: balls roll further."},
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
	"polish": {"name": "Zero Friction", "kind": "tool", "when": "any", "cost": 5, "desc": "For this shot the cloth has 70% less friction: every ball rolls much further."},
	"gravitypebble": {"name": "Gravity Well", "kind": "tool", "when": "pause", "cost": 6, "desc": "Place a small well that bends rolling balls for the rest of the shot."},
	"portal": {"name": "Wormhole", "kind": "tool", "when": "any", "cost": 7, "desc": "Place two linked portals for this table. A ball rolling into one comes out of the other at the same speed."},
	"wall": {"name": "Force Field", "kind": "tool", "when": "pause", "cost": 5, "desc": "Raise a short wall for the rest of the shot."},
	"post": {"name": "Fixed Point", "kind": "tool", "when": "any", "cost": 5, "desc": "Place a post anywhere for the rest of this table."},
	"englishdial": {"name": "Spin Transfer", "kind": "tool", "when": "pause", "cost": 5, "desc": "Put the spin you have set onto the rolling cue ball."},
	"swap": {"name": "Entanglement", "kind": "tool", "when": "any", "cost": 6, "desc": "Two balls swap places, each keeping its own motion."},
	"nudge": {"name": "Vector", "kind": "tool", "when": "pause", "cost": 5, "desc": "Push a rolling ball a short way in any direction."},
	"leadweight": {"name": "Mass Shift", "kind": "tool", "when": "any", "cost": 5, "desc": "Pick a ball: it weighs 400% for the rest of the shot."},
	"pocketcover": {"name": "Event Horizon", "kind": "tool", "when": "any", "cost": 6, "desc": "Pick a pocket: it swallows from twice as wide for the rest of the shot."},
	"trapdoor": {"name": "Black Hole", "kind": "tool", "when": "any", "cost": 6, "desc": "Open a pocket anywhere along a cushion for the rest of the shot."},
	"rewind": {"name": "Time Reversal", "kind": "tool", "when": "pause", "cost": 9, "desc": "Undo this shot while it rolls, and take it again."},
	"spotter": {"name": "Conservation", "kind": "tool", "when": "any", "cost": 5, "desc": "Bring a ball you sank on this table back to the foot spot. Never the 8."},
	"pythagoras": {"name": "Pythagorean Triple", "kind": "tool", "when": "any", "cost": 7, "desc": "Pick three balls: force-field walls join them into a triangle for the rest of the shot."},
	"newton": {"name": "Newton's Cradle", "kind": "tool", "when": "pause", "cost": 6, "desc": "Pick a ball: the cue ball stops dead and that ball takes all its momentum."},
	"reflection": {"name": "Reflection", "kind": "tool", "when": "pause", "cost": 5, "desc": "Pick a rolling ball: it turns round and heads straight back."},
	"goldenratio": {"name": "Golden Ratio", "kind": "tool", "when": "pause", "cost": 5, "desc": "Pick a rolling ball: its speed is multiplied by 1.618, and if it sinks this shot it scores ×1.618."},
	"centremass": {"name": "Centre of Mass", "kind": "tool", "when": "pause", "cost": 6, "desc": "Pick two to four balls: they all head for the point between them."},
	"hookes": {"name": "Hooke's Law", "kind": "tool", "when": "any", "cost": 5, "desc": "Pick a cushion: for the rest of the shot, anything bouncing off it keeps all its speed."},
	"damping": {"name": "Damping", "kind": "tool", "when": "pause", "cost": 4, "desc": "The cue ball drops to a quarter of its speed, wherever it is heading."},
	"momentum": {"name": "Momentum Exchange", "kind": "tool", "when": "pause", "cost": 6, "desc": "Pick a ball: it and the cue ball swap speeds and directions."},
	"darkenergy": {"name": "Dark Energy", "kind": "tool", "when": "pause", "cost": 5, "desc": "Place a point that pushes rolling balls away for the rest of the shot."},
	"blast": {"name": "Supernova", "kind": "tool", "when": "pause", "cost": 6, "desc": "Place a blast: every ball near it is flung outwards."},
	"absolutezero": {"name": "Absolute Zero", "kind": "tool", "when": "pause", "cost": 5, "desc": "Every ball stops dead. Any ball stopped at the lip of a pocket drops in (never the 8 or the cue ball)."},
	"focal": {"name": "Focal Point", "kind": "tool", "when": "any", "cost": 5, "desc": "Pick a pocket: it becomes the hot pocket."},
	"tidal": {"name": "Tidal Pull", "kind": "tool", "when": "pause", "cost": 5, "desc": "Pick a pocket: for the rest of the shot it pulls rolling balls towards it."},
}

const WHEN_NAMES := {"setup": "Set-up · while aiming", "pause": "While paused", "after": "Aftermath · after a shot", "any": "Aiming or paused"}
const WHEN_COLORS := {"setup": Color(0.45, 0.7, 1.0), "pause": Color(0.45, 0.95, 0.75), "after": Color(1.0, 0.72, 0.35), "any": Color(0.85, 0.85, 0.9)}
const CATALYST_COLOR := Color(0.65, 0.79, 0.88) # desaturated steel blue, distinct from the Elements' saturated spectrum
const SIDE_BET_COLOR := Color(0.66, 0.39, 0.2) # warm brown on every side-bet card
const ISOTOPE_FRAME_COLOR := Color(0.68, 0.7, 0.78) # neutral frame lets the ball's glow carry its identity
const EXOTIC_FRAME_COLOR := Color(0.56, 0.6, 0.64) # neutral frame lets the Exotic ball carry its identity


## Imbues live on one numbered ball for the rest of the run.
const IMBUES := {
	"spark": {"name": "Spark", "cost": 4, "color": Color(0.3, 1.0, 0.85), "desc": "+1 Chain every time it is struck. Struck 3 or more times in one shot, it overloads and arcs onto the last ball it hit."},
	"gold": {"name": "Gilded", "cost": 4, "color": Color(1.0, 0.82, 0.3), "desc": "Pays $1 when sunk, plus $1 for every table in a row you have sunk it (up to $5). A table where it stays up resets the streak."},
	"heavy": {"name": "Weighted", "cost": 3, "color": Color(0.75, 0.78, 0.85), "desc": "Worth 10 + 3 × its number, and the number counts one more time with every sink (×4, ×5...). Any miss drops it back to ×3."},
	"glass": {"name": "Hairline", "cost": 5, "color": Color(0.7, 0.85, 1.0), "desc": "Scores ×3 when sunk, but the coating may crack off: 1 in 4 the first time, 2 in 4 the next, then 3 in 4."},
	"ember": {"name": "Kindled", "cost": 5, "color": Color(1.0, 0.45, 0.2), "desc": "+2 Heat when sunk. But while it is still on the table, a miss wipes your Heat to 0 instead of halving it."},
	"vein": {"name": "Vein", "cost": 5, "color": Color(1.0, 0.55, 0.95), "desc": "Worth +20 when sunk, and it spreads onto the ball that knocked it in (if that ball has no Isotope)."},
	"lucky": {"name": "Lucky", "cost": 4, "color": Color(0.35, 0.95, 0.5), "desc": "1 in 2 chance to score ×2 when sunk. If it misses, Lucky jumps to another ball with no Isotope and the next win scores ×3, then ×4, and so on."},
	"volatile": {"name": "Volatile", "cost": 4, "color": Color(1.0, 0.62, 0.0), "desc": "The first time anything hits this ball it explodes: it counts as sunk (points and Heat), but it leaves your rack for good."},
	"jinxed": {"name": "Jinxed", "cost": 3, "color": Color(0.55, 0.3, 0.9), "desc": "Scores ×4 when sunk, but sinking it halves your Heat."},
	"mirror": {"name": "Mirror", "cost": 4, "color": Color(0.8, 0.95, 0.95), "desc": "Scores what the ball that hit it is worth instead of its own value: a low ball struck by the 15 scores like the 15."},
	"pawned": {"name": "Pawned", "cost": 2, "color": Color(0.85, 0.7, 0.45), "desc": "Pays $4 when sunk instead of any points."},
	"frosted": {"name": "Frosted", "cost": 4, "color": Color(0.7, 0.92, 1.0), "desc": "When it sinks, your next miss on this table keeps your Heat."},
	"magnetic": {"name": "Magnetic", "cost": 5, "color": Color(1.0, 0.35, 0.35), "desc": "Pockets pull this ball in."},
	"charged": {"name": "Charged", "cost": 4, "color": Color(1.0, 1.0, 0.45), "desc": "+0.5 Chain every time this ball touches a cushion."},
	"prismatic": {"name": "Resonant", "cost": 4, "color": Color(0.95, 0.6, 1.0), "desc": "Every ball it touches in a shot adds +0.25 Chain."},
	"hollow": {"name": "Hollow", "cost": 3, "color": Color(0.85, 0.85, 0.75), "desc": "50% weight: it flies further when struck."},
	"leaded": {"name": "Leaded", "cost": 4, "color": Color(0.5, 0.55, 0.65), "desc": "200% weight, and worth +45."},
	"bounty": {"name": "Bounty", "cost": 4, "color": Color(0.6, 1.0, 0.4), "desc": "Pays $1 for every point of Heat when it sinks, then cashes out 2 Heat."},
	"starry": {"name": "Starry", "cost": 5, "color": Color(1.0, 0.85, 0.55), "desc": "Every ball after it in the same shot gets +0.5 Chain."},
	"twin": {"name": "Twin", "cost": 4, "color": Color(0.5, 0.65, 1.0), "desc": "Its value counts twice. Then it hops to its colour twin (the 3 and the 11, the 1 and the 9...), if that one is free."},
	"recurring": {"name": "Recurring", "cost": 5, "color": Color(0.45, 1.0, 0.75), "desc": "Every time it sinks it is worth +4 more for the rest of the run, and it comes straight back: it takes the place of a random other ball on the table, which leaves unscored."},
	"slick": {"name": "Slick", "cost": 3, "color": Color(0.6, 0.95, 1.0), "desc": "Rolls 65% further on the cloth, and is worth +10."},
	"rubber": {"name": "Rubber", "cost": 4, "color": Color(0.95, 0.4, 0.3), "desc": "Loses no speed off cushions, and is worth +5 for every cushion it touched before it sank."},
	"tithed": {"name": "Tithed", "cost": 4, "color": Color(0.95, 0.85, 0.5), "desc": "When it sinks, pays $1 for every other ball still on the table (up to $5)."},
	"catalytic": {"name": "Catalytic", "cost": 5, "color": Color(0.5, 0.9, 1.0), "desc": "When it sinks, one Catalyst you have used this table recharges."},
	"chalked": {"name": "Chalked", "cost": 6, "color": Color(0.45, 0.65, 1.0), "desc": "The first time it sinks on a table, +1 Chalk."},
	"excited": {"name": "Excited", "cost": 3, "color": Color(1.0, 0.7, 0.35), "desc": "If the cue ball hits it first and it sinks, +1 Heat."},
	"radiant": {"name": "Radiant", "cost": 5, "color": Color(1.0, 0.95, 0.5), "desc": "While it is on the table at the start of a shot, every other ball that sinks is worth +5."},
	"polarized": {"name": "Polarized", "cost": 3, "color": Color(0.75, 0.55, 1.0), "desc": "Scores ×3 in the hot pocket, but only ×0.5 anywhere else."},
	"isolated": {"name": "Isolated", "cost": 4, "color": Color(0.7, 0.75, 0.8), "desc": "Scores ×2.5 if it is the last solid (or the last stripe) on the table when it sinks."},
}

## Exotic balls you can add to your rack. They rack with the numbered balls and
## count as neither solids nor stripes unless they say so. Each has its own
## finish ("pattern" in the ball shader), colours and emblem.
const BALL_TYPES := {
	"gold": {"name": "Gold", "cost": 6, "value": 45, "color": Color(1.0, 0.78, 0.2), "accent": Color(1.0, 0.96, 0.62), "pattern": 1, "motif": "t 0 0 34 $", "desc": "Worth 45, and pays $1 for every cushion it touched before sinking."},
	"void": {"name": "Void", "cost": 7, "value": 0, "color": Color(0.12, 0.03, 0.2), "accent": Color(0.62, 0.25, 1.0), "pattern": 2, "motif": "c 0 0 26;c 0 0 14;C 0 0 5", "desc": "Worth nothing itself, but every other ball in the same shot scores ×2."},
	"glass": {"name": "Glass", "cost": 6, "value": 30, "color": Color(0.7, 0.9, 1.0), "accent": Color(1.0, 1.0, 1.0), "pattern": 3, "motif": "o 0 -30 22 -8 0 30 -22 -8 0 -30", "desc": "Scores ×3 if it sinks, but anything that hits it hard shatters it, and it leaves your rack."},
	"iron": {"name": "Iron", "cost": 5, "value": 70, "color": Color(0.45, 0.47, 0.52), "accent": Color(0.78, 0.8, 0.85), "pattern": 1, "motif": "P -26 -14 26 -14 18 0 10 0 14 18 -14 18 -10 0 -18 0", "desc": "200% weight. Worth 70."},
	"feather": {"name": "Feather", "cost": 4, "value": 40, "color": Color(0.95, 0.95, 0.98), "accent": Color(0.55, 0.7, 1.0), "pattern": 4, "motif": "l -24 26 22 -22;o -14 16 -12 -10 18 -24 8 6 -14 16", "desc": "25% weight: it barely moves other balls, and adds +0.5 Chain as it sinks."},
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
	"eraser": {"name": "Eraser", "cost": 3, "value": 15, "color": Color(1.0, 0.55, 0.6), "accent": Color(0.4, 0.5, 1.0), "pattern": 9, "motif": "o -26 8 6 -24 26 -4 -6 28 -26 8;l -10 -8 10 12", "desc": "When it sinks it pays $4, and both it and the last ball it touched leave your rack (never the 8)."},
	"echo": {"name": "Echo", "cost": 6, "value": 30, "color": Color(0.55, 0.3, 0.85), "accent": Color(0.9, 0.8, 1.0), "pattern": 6, "motif": "C -14 0 7;a -14 0 20 -50 50;a -14 0 32 -40 40", "desc": "The first time it sinks on a table, it comes back to the foot spot."},
	"phantom": {"name": "Phantom", "cost": 5, "value": 40, "color": Color(0.75, 0.8, 0.95), "accent": Color(1.0, 1.0, 1.0), "pattern": 3, "motif": "P -18 22 -18 -6 -12 -18 0 -24 12 -18 18 -6 18 22 10 14 4 22 -4 14 -10 22;C -7 -6 3;C 7 -6 3", "desc": "Other object balls pass straight through it: only the cue ball can hit it. Worth 40."},
	"spring": {"name": "Spring", "cost": 5, "value": 30, "color": Color(0.35, 0.85, 0.45), "accent": Color(0.95, 1.0, 0.7), "pattern": 6, "motif": "o -22 -20 22 -12 -22 -4 22 4 -22 12 22 20", "desc": "Balls bounce off it 50% faster than they hit it."},
	"piggy": {"name": "Piggy Bank", "cost": 4, "value": 10, "color": Color(1.0, 0.6, 0.7), "accent": Color(1.0, 0.9, 0.5), "pattern": 0, "motif": "c 0 4 20;P -6 -16 6 -16 6 -12 -6 -12;C 12 0 3", "desc": "Worth 10, and when it sinks it pays $1 for every shot already taken on this table (up to $6)."},
	"jackpot": {"name": "Jackpot", "cost": 5, "value": 20, "color": Color(0.85, 0.12, 0.2), "accent": Color(1.0, 0.85, 0.2), "pattern": 5, "motif": "o -14 -18 14 -18 -2 22;l -8 2 8 2", "desc": "When it sinks, 1 in 6 chance to pay $10; otherwise it pays $1."},
	"pinball": {"name": "Pinball", "cost": 5, "value": 20, "color": Color(0.85, 0.85, 0.9), "accent": Color(1.0, 0.3, 0.8), "pattern": 1, "motif": "c 0 0 22;C 0 0 6;l -22 0 -30 0;l 22 0 30 0", "desc": "Worth 20, plus 10 for every cushion it touched before it sank."},
	"fuse": {"name": "Fuse", "cost": 5, "value": 30, "color": Color(0.25, 0.25, 0.28), "accent": Color(1.0, 0.55, 0.15), "pattern": 4, "motif": "C 0 6 16;o 8 -8 14 -18 22 -20;C 24 -22 4", "desc": "When it sinks, +1 Heat for every ball that sank before it in the same shot."},
	"numeral": {"name": "Numeral", "hidden": true, "cost": 0, "value": 0, "color": Color(0.32, 0.2, 0.55), "accent": Color(1.0, 0.85, 0.4), "pattern": 0, "motif": "", "desc": "A numbered ball past 15."},
	"comet": {"name": "Comet", "cost": 5, "value": 40, "color": Color(0.2, 0.5, 1.0), "accent": Color(0.9, 0.95, 1.0), "pattern": 9, "motif": "C 14 -14 10;l 4 -4 -30 30;l 8 4 -20 30;l -4 -8 -30 20", "desc": "Feels no cloth friction until it first hits a cushion."},
}

## Which special type each ball number above 15 is, for this run. RunState keeps
## it in step, so every view and rule can look an Exotic ball up by number.
static var kinds := {}
## Dice and Wild balls: the number each one currently shows.
static var faces := {}


static func kind_of(n: int) -> String:
	return kinds.get(n, "") if n > 15 else ""


static func is_solid(n: int) -> bool:
	return n >= 1 and n <= 7


static func ball_label(n: int) -> String:
	var k := kind_of(n)
	if k == "numeral":
		return "%d-ball" % int(faces.get(n, n))
	return BALL_TYPES[k].name + " ball" if k != "" else "%d-ball" % n


## Starting cues: each run begins by choosing one. "shaft"/"butt"/"accent" colour the stick.
const CUES := {
	"maple": {"name": "Classic Maple", "desc": "A plain cue. $7.", "money": 7, "perks": [], "chalk": 0,
		"shaft": Color(0.86, 0.72, 0.5), "butt": Color(0.32, 0.14, 0.07), "accent": Color(0.9, 0.85, 0.7)},
	"hotrod": {"name": "Hot Rod", "desc": "Carries Focal Point, and your 1-ball is Kindled. 1 less Chalk. $4.", "money": 4, "perks": [], "chalk": -1, "tools": ["focal"], "imbue": [[1, "ember"]],
		"shaft": Color(0.85, 0.7, 0.5), "butt": Color(0.6, 0.12, 0.05), "accent": Color(1.0, 0.55, 0.1)},
	"gilded": {"name": "Gilded Cue", "desc": "Carries Conservation, and your 3-ball is Gilded. $6.", "money": 6, "perks": [], "chalk": 0, "tools": ["spotter"], "imbue": [[3, "gold"]],
		"shaft": Color(0.92, 0.82, 0.55), "butt": Color(0.45, 0.32, 0.08), "accent": Color(1.0, 0.85, 0.3)},
	"gearhead": {"name": "Gear Cue", "desc": "Carries Golden Ratio, and holds 2 extra Catalysts. $3.", "money": 3, "perks": [], "chalk": 0, "tools": ["goldenratio"], "rules": {"slots": 2},
		"shaft": Color(0.78, 0.82, 0.86), "butt": Color(0.12, 0.3, 0.42), "accent": Color(0.4, 0.85, 1.0)},
	"lean": {"name": "Lean Cue", "desc": "Carries Quantum Tunnel. Your rack starts without the 1 and 2. $4.", "money": 4, "perks": [], "chalk": 0, "remove": [1, 2], "tools": ["ghostchalk"],
		"shaft": Color(0.9, 0.86, 0.78), "butt": Color(0.36, 0.3, 0.24), "accent": Color(0.95, 0.95, 0.9)},
	"black": {"name": "Black Cue", "desc": "Carries Reflection. Sinking the 8 early costs nothing. $3.", "money": 3, "perks": [], "chalk": 0, "tools": ["reflection"], "rules": {"safe8": true},
		"shaft": Color(0.3, 0.3, 0.32), "butt": Color(0.05, 0.05, 0.06), "accent": Color(0.82, 0.8, 0.98)},
	"alchemist": {"name": "Alchemist's Cue", "desc": "Carries Entanglement, and starts with a Gold ball. $3.", "money": 3, "perks": [], "chalk": 0, "add": ["gold"], "tools": ["swap"],
		"shaft": Color(0.95, 0.86, 0.6), "butt": Color(0.4, 0.2, 0.5), "accent": Color(1.0, 0.8, 0.3)},
	"glass": {"name": "Glass Cue", "desc": "Carries Inertia, and starts with a Glass ball. $4.", "money": 4, "perks": [], "chalk": 0, "add": ["glass"], "tools": ["freezeframe"],
		"shaft": Color(0.85, 0.92, 1.0), "butt": Color(0.55, 0.7, 0.9), "accent": Color(1.0, 0.35, 0.65)},
	"numbers": {"name": "Number Theory Cue", "desc": "Starts with Promethium Prime and Fermium Spiral, but holds only 4 Elements. $2.", "money": 2, "perks": ["prime", "fibonacci"], "chalk": 0, "rules": {"max_perks": 4},
		"shaft": Color(0.88, 0.84, 0.95), "butt": Color(0.2, 0.15, 0.4), "accent": Color(0.75, 0.6, 1.0)},
	# Object cues: each carries one placeable object, 4 uses every table, and one twist that plays with it.
	"posts": {"name": "Post Cue", "desc": "Carries 4 Fixed Points every table, and starts with a Spring ball. $2.", "money": 2, "perks": [], "chalk": 0, "kit": "post", "add": ["spring"],
		"shaft": Color(0.9, 0.78, 0.55), "butt": Color(0.5, 0.2, 0.1), "accent": Color(1.0, 0.6, 0.3)},
	"portals": {"name": "Portal Cue", "desc": "Carries 4 Wormholes every table. Every portal trip adds +1 Chain. $2.", "money": 2, "perks": [], "chalk": 0, "kit": "portal", "rules": {"portal_chain": true},
		"shaft": Color(0.7, 0.75, 0.95), "butt": Color(0.25, 0.15, 0.5), "accent": Color(0.7, 0.4, 1.0)},
	"walls": {"name": "Wall Cue", "desc": "Carries 4 Force Fields every table, and your 4-ball is Rubber. $2.", "money": 2, "perks": [], "chalk": 0, "kit": "wall", "imbue": [[4, "rubber"]],
		"shaft": Color(0.8, 0.8, 0.78), "butt": Color(0.3, 0.32, 0.35), "accent": Color(0.6, 0.9, 0.7)},
	"trapdoors": {"name": "Trapdoor Cue", "desc": "Carries 4 Black Holes every table, and your 6-ball is Magnetic. $2.", "money": 2, "perks": [], "chalk": 0, "kit": "trapdoor", "imbue": [[6, "magnetic"]],
		"shaft": Color(0.72, 0.6, 0.45), "butt": Color(0.2, 0.12, 0.06), "accent": Color(0.95, 0.75, 0.35)},
	"gravity": {"name": "Gravity Cue", "desc": "Carries 4 Gravity Wells every table, and starts with a Comet ball. $2.", "money": 2, "perks": [], "chalk": 0, "kit": "gravitypebble", "add": ["comet"],
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
	"spring_st": {"name": "Capacitor", "tier": 1, "lab": "spring", "anomaly": "", "desc": "Lively rails. A ball off the top rail charges the bottom one, and the next ball off the charged rail flies off faster. On this table, bank sinks score ×2."},
	"drift": {"name": "Coriolis", "tier": 1, "lab": "standard", "anomaly": "", "desc": "A turntable spins in the middle and curves every ball that rolls across it. Every sink adds +1 Chain."},
	"cramped": {"name": "Faraday Cage", "tier": 1, "lab": "standard", "anomaly": "", "desc": "A Card Sharp sits in a corner pocket, guarded by two posts, and blocks it. Hit it twice to knock it out and open the pocket. Every sink scores ×1.5."},
	"parlor": {"name": "Pinball Parlor", "tier": 2, "lab": "pinball", "anomaly": "", "desc": "Four bumpers. On this table, every bumper hit adds +1 Chain."},
	"posts": {"name": "Harmonic Oscillator", "tier": 2, "lab": "cyclotron", "anomaly": "", "desc": "Two posts on springs slide back and forth, one step after every shot. Every post hit adds +1 Chain."},
	"sinkhole": {"name": "Event Horizon", "tier": 2, "lab": "gravity", "anomaly": "", "desc": "A gravity well in the centre pulls moving balls in. Chain starts at 2."},
	"magnet": {"name": "Kepler Orbit", "tier": 2, "lab": "magnetlab", "anomaly": "", "desc": "Every pocket pulls passing balls into orbit and then in, but every ball is worth 10 less."},
	"smoke": {"name": "Lotka–Volterra", "tier": 2, "lab": "standard", "anomaly": "", "desc": "A Pool Shark circles the balls and swallows one every 3 shots. If it survives 4 shots, a second one arrives. Hit a Shark 3 times to knock it out. Every sink scores ×1.5."},
	"blackice": {"name": "Superfluid", "tier": 3, "lab": "cryo", "anomaly": "blackice", "desc": "Almost no friction and lively cushions. Every sink adds +0.5 Chain."},
	"tilted": {"name": "Snell's Law", "tier": 3, "lab": "standard", "anomaly": "", "desc": "Half the table is air and half is glass. A ball crossing the line bends like light, and leaving the glass at a shallow angle it bounces back inside. Every sink scores ×1.5."},
	"two": {"name": "Quantum Pockets", "tier": 3, "lab": "spring", "anomaly": "onepocket", "desc": "Only the hot pocket and its entangled twin, diagonally opposite, score, and sinks there score ×2."},
	"closing": {"name": "Radioactive Decay", "tier": 3, "lab": "standard", "anomaly": "shrink", "desc": "The pockets decay: every pocket narrows after each shot. Heat builds twice as fast."},
	"gulf": {"name": "Gulf Stream", "tier": 2, "lab": "standard", "anomaly": "", "desc": "A current runs across the middle of the table and carries rolling balls to the right. Every sink adds +0.5 Chain."},
	"foucault": {"name": "Foucault's Pendulum", "tier": 3, "lab": "standard", "anomaly": "", "desc": "A heavy bob swings across the middle, and its swing turns a little every shot. A Hammerhead charges across the table between shots. Hitting the bob adds +1 Chain; knock the Hammerhead out with 3 hits."},
	"venturi": {"name": "Venturi", "tier": 1, "lab": "standard", "anomaly": "", "desc": "Two angled rails squeeze the middle into a narrow throat, and a ball rushed through it comes out faster. Long sinks score ×2."},
	"erbridge": {"name": "Einstein–Rosen Bridge", "tier": 1, "lab": "standard", "anomaly": "", "desc": "Two linked portals: a ball rolling into one comes out of the other at the same speed. Every portal trip adds +1 Chain."},
	"membrane": {"name": "Semipermeable Membrane", "tier": 1, "lab": "standard", "anomaly": "", "desc": "A membrane across the table lets balls through left to right only; from the right it bounces them back. Every sink scores ×1.5."},
	"galton": {"name": "Galton Board", "tier": 1, "lab": "standard", "anomaly": "", "shape": "galton", "desc": "Rows of pegs, set like a bean machine, scatter balls as they pass. Every peg hit adds +0.5 Chain."},
	"parabolic": {"name": "Parabolic Mirror", "tier": 2, "lab": "standard", "anomaly": "", "shape": "parabolic", "desc": "The right end is a parabola: a ball rolling straight at it bounces to the focus, where a pocket sits. Sinks in the focus pocket score ×2."},
	"whisper": {"name": "Whispering Gallery", "tier": 2, "lab": "standard", "anomaly": "", "shape": "whisper", "desc": "An elliptical table. A ball sent through one focus always rolls to the other, where a pocket sits. Sinks in the focus pocket score ×3."},
	"sierpinski": {"name": "Sierpinski Triangle", "tier": 2, "lab": "standard", "anomaly": "", "shape": "sierpinski", "desc": "A triangular table with three triangular islands to bank around. Bank sinks score ×2."},
	"mobius": {"name": "Möbius Strip", "tier": 2, "lab": "standard", "anomaly": "", "desc": "Gaps in the left rail lead out of gaps in the right rail, upside down. Every trip through adds +1 Chain."},
	"maxwell": {"name": "Maxwell's Demon", "tier": 2, "lab": "standard", "anomaly": "", "desc": "A wall splits the table. At its gate the Demon lets fast balls through left to right and slow balls back right to left. Every sink scores ×1.5."},
	"lorentz": {"name": "Lorentz Field", "tier": 2, "lab": "standard", "anomaly": "", "desc": "Inside the marked field, solids (+) curve one way and stripes (−) curve the other; the cue ball and the 8 roll straight. Every sink adds +0.5 Chain."},
	"spiral": {"name": "Golden Spiral", "tier": 2, "lab": "standard", "anomaly": "", "shape": "spiral", "desc": "A spiral rail winds into a drain on the cloth; a ball caught on the arm rides it in. Sinks in the drain score ×2."},
	"meissner": {"name": "Meissner Effect", "tier": 2, "lab": "standard", "anomaly": "", "desc": "Four superconducting posts push balls away before they touch, so balls curve round them. Clean sinks score ×2."},
	"chain": {"name": "Chain Reaction", "tier": 3, "lab": "standard", "anomaly": "", "shape": "benzene", "desc": "Every sink sends a shock ring out of its pocket that shoves nearby balls away. Set off chains. Every sink adds +0.5 Chain."},
	"tesla": {"name": "Tesla Coil", "tier": 3, "lab": "standard", "anomaly": "", "shape": "benzene", "desc": "Every third shot the coil fires and pushes every ball outwards; the aiming line shows the pulse. Sinks on a coil shot score ×2."},
	"tectonic": {"name": "Tectonic Plates", "tier": 3, "lab": "standard", "anomaly": "", "desc": "Two fault ridges slide past each other one step after every shot. Bank sinks score ×1.5."},
	"lattice": {"name": "Crystal Lattice", "tier": 3, "lab": "standard", "anomaly": "", "shape": "lattice", "desc": "A rhombus table with a grid of small posts, like atoms in a crystal. Every post hit adds +0.25 Chain."},
	"stellated": {"name": "Stellated Star", "tier": 3, "lab": "standard", "anomaly": "", "shape": "stellated", "desc": "A six-pointed star with a pocket at every point. The inner corners make wild banks. Bank sinks score ×2."},
	"lever": {"name": "The Lever", "tier": 3, "lab": "standard", "anomaly": "", "shape": "lever", "desc": "A see-saw rail on a fulcrum tips towards whichever end a ball hit last shot. Every sink scores ×1.5."},
	"escape": {"name": "Escape Velocity", "tier": 3, "lab": "standard", "anomaly": "", "shape": "escape", "desc": "Two gravity wells slingshot balls round them; get the speed right to escape or orbit in. Every sink adds +1 Chain."},
	"life": {"name": "Game of Life", "tier": 2, "lab": "standard", "anomaly": "", "desc": "Live cells are posts. After every shot they follow Conway's rules: the faint marks show which cells are born and which die next. Every cell hit adds +0.5 Chain."},
	"cat": {"name": "Schrödinger's Cat", "tier": 2, "lab": "standard", "anomaly": "", "desc": "A cat sleeps in a corner pocket and blocks it. Hit it and it moves to another corner; it also wanders every third shot. Sinks in the pocket opposite the cat score ×2."},
	"elements": {"name": "The Clockwork Table", "tier": 9, "lab": "element", "anomaly": "elements", "desc": "The pockets are numbered 1 to 6, clockwise. Sink into the next one in order to tick the clock: ticks in a row score ×1.5, ×2, ×2.5 and on. Any other pocket stops the clock. A Sweeper wall turns one hour round the middle after every shot."},
	"final": {"name": "Apex Predator", "tier": 9, "lab": "final", "anomaly": "cursed8", "desc": "The Great White swallows a ball every 2 shots; hit it 8 times to knock it out. At half health the Loan Shark (takes 15% of every sink) and the Leech (clamps onto a ball) join. The 8 goes last: early costs 2 Chalk, last scores ×5."},
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
	"parabolic": {"verts": [Vector2(0, 0), Vector2(760, 0), Vector2(816, 31), Vector2(865, 62), Vector2(906, 94), Vector2(940, 125), Vector2(966, 156), Vector2(985, 188), Vector2(996, 219), Vector2(1000, 250), Vector2(996, 281), Vector2(985, 312), Vector2(966, 344), Vector2(940, 375), Vector2(906, 406), Vector2(865, 438), Vector2(816, 469), Vector2(760, 500), Vector2(0, 500)],
		"pockets": [{"v": 0}, {"e": 0, "t": 0.5}, {"v": 1}, {"v": 18}, {"e": 17, "t": 0.5}, {"p": Vector2(935, 250)}], "foot": Vector2(560, 250)},
	"whisper": {"verts": [Vector2(1000, 250), Vector2(983, 315), Vector2(933, 375), Vector2(854, 427), Vector2(750, 467), Vector2(629, 491), Vector2(500, 500), Vector2(371, 491), Vector2(250, 467), Vector2(146, 427), Vector2(67, 375), Vector2(17, 315), Vector2(0, 250), Vector2(17, 185), Vector2(67, 125), Vector2(146, 73), Vector2(250, 33), Vector2(371, 9), Vector2(500, 0), Vector2(629, 9), Vector2(750, 33), Vector2(854, 73), Vector2(933, 125), Vector2(983, 185)],
		"pockets": [{"v": 15}, {"v": 18}, {"v": 21}, {"v": 9}, {"v": 6}, {"p": Vector2(933, 250)}], "foot": Vector2(640, 250)},
	"sierpinski": {"verts": [Vector2(0, 0), Vector2(1000, 250), Vector2(0, 500)],
		"pockets": [{"v": 0}, {"e": 0, "t": 0.5}, {"v": 1}, {"v": 2}, {"e": 1, "t": 0.5}, {"e": 2, "t": 0.5}], "foot": Vector2(560, 250)},
	"galton": {"verts": [Vector2(300, 0), Vector2(700, 0), Vector2(1000, 500), Vector2(0, 500)],
		"pockets": [{"v": 0}, {"e": 0, "t": 0.5}, {"v": 1}, {"v": 3}, {"e": 2, "t": 0.5}, {"v": 2}], "foot": Vector2(690, 340)},
	"spiral": {"verts": [Vector2(0, 0), Vector2(1000, 0), Vector2(1000, 500), Vector2(0, 500)],
		"pockets": [{"v": 0}, {"e": 0, "t": 0.5}, {"v": 1}, {"v": 3}, {"p": Vector2(500, 385)}, {"v": 2}], "foot": Vector2(750, 250)},
	"lattice": {"verts": [Vector2(150, 0), Vector2(1000, 0), Vector2(850, 500), Vector2(0, 500)],
		"pockets": [{"v": 0}, {"e": 0, "t": 0.5}, {"v": 1}, {"v": 3}, {"e": 2, "t": 0.5}, {"v": 2}], "foot": Vector2(760, 250)},
	"stellated": {"verts": [Vector2(1000, 250), Vector2(749, 322), Vector2(750, 451), Vector2(500, 394), Vector2(250, 451), Vector2(251, 322), Vector2(0, 250), Vector2(251, 178), Vector2(250, 49), Vector2(500, 106), Vector2(750, 49), Vector2(749, 178)],
		"pockets": [{"v": 8}, {"v": 10}, {"v": 0}, {"v": 6}, {"v": 4}, {"v": 2}], "foot": Vector2(600, 250)},
	"lever": {"verts": [Vector2(0, 0), Vector2(1000, 0), Vector2(850, 500), Vector2(150, 500)],
		"pockets": [{"v": 0}, {"e": 0, "t": 0.5}, {"v": 1}, {"v": 3}, {"e": 2, "t": 0.5}, {"v": 2}], "foot": Vector2(740, 230)},
	"escape": {"verts": [Vector2(1000, 250), Vector2(962, 346), Vector2(854, 427), Vector2(691, 481), Vector2(500, 500), Vector2(309, 481), Vector2(146, 427), Vector2(38, 346), Vector2(0, 250), Vector2(38, 154), Vector2(146, 73), Vector2(309, 19), Vector2(500, 0), Vector2(691, 19), Vector2(854, 73), Vector2(962, 154)],
		"pockets": [{"v": 10}, {"v": 12}, {"v": 14}, {"v": 6}, {"v": 4}, {"v": 2}], "foot": Vector2(660, 250)},
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
	"clean": {"name": "Sink a ball straight in, with no cushions or other balls", "tier": 0, "terms": ["clean"]},
	"topthree": {"name": "Sink the 13, 14 or 15", "tier": 0, "terms": []},
	"mixed": {"name": "Sink a solid and a stripe in one shot", "tier": 1, "terms": ["solid", "stripe"]},
	"twopockets": {"name": "Sink balls into 2 different pockets in one shot", "tier": 1, "terms": []},
	"bank3": {"name": "Sink a ball off 3 cushions", "tier": 2, "terms": ["bank"]},
	"chain10": {"name": "Reach Chain 10 in one shot", "tier": 2, "terms": ["chain"]},
	"money5": {"name": "Earn $5 or more in one shot", "tier": 2, "terms": ["pay"]},
}
const BET_TIERS := ["Easy", "Medium", "Hard"]
## The stake for each table (endless keeps the last).
const BET_STAKES := [4, 4, 8, 8, 12, 12, 16, 16, 20]


## Handicaps: optional difficulty, each level including every rule before it.
const HANDICAPS := [
	{"name": "Scratch Player", "desc": "The game as designed."},
	{"name": "Worn Cloth", "desc": "Table targets are 15% higher."},
	{"name": "Short Chalk", "desc": "Start with 1 less Chalk."},
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
	"pocket": "Pockets", "number": "Ball numbers", "solid": "Solids", "stripe": "Stripes", "eight": "The 8-ball", "clear": "Clearing your rack", "gear": "Gear", "imbue": "Isotopes", "special": "Exotic balls", "pause": "Pausing", "money": "Economy", "risk": "Risk & scaling",
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
## and the Weighted Imbue). Exotic balls have their own value.
const NUMBER_WEIGHT := 2


static func ball_points(n: int, weight: int = NUMBER_WEIGHT) -> int:
	var k := kind_of(n)
	if k == "dice" or k == "wild" or k == "numeral":
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


## Atomic-number rainbow: 1 is red, 100 is violet, with no hue wrap back to red.
static func element_color(z: int) -> Color:
	return Color.from_hsv(0.76 * (clampi(z, 1, 100) - 1) / 99.0, 0.82, 0.96)


## Discoveries: one optional goal on every board, paid once per table.
##   ko       knock out a Shark              bumpers3  3+ post hits in a scoring shot
##   portal   sink after a portal trip       focus     sink in the pocket on the cloth
##   bank     sink a bank shot               bank2     sink off 2+ cushions
##   double   sink 2+ balls in one shot      triple    sink 3+ balls in one shot
##   heat4    reach Heat 4                   cathit    hit the cat and sink in the same shot
const DISCOVERY_KINDS := {
	"ko": "Knock out a Shark", "bumpers3": "Hit 3 posts in a shot that sinks a ball", "portal": "Sink a ball in a shot that uses a portal",
	"focus": "Sink a ball in the pocket out on the cloth", "bank": "Sink a bank shot", "bank2": "Sink a ball off 2 cushions",
	"double": "Sink 2 balls in one shot", "triple": "Sink 3 balls in one shot", "heat4": "Reach Heat 4",
	"cathit": "Hit the cat and sink a ball in the same shot",
}
const DISCOVERIES := {
	"smoke": "ko", "cramped": "ko", "foucault": "ko", "final": "ko",
	"erbridge": "portal", "mobius": "portal",
	"parlor": "bumpers3", "posts": "bumpers3", "galton": "bumpers3", "lattice": "bumpers3", "life": "bumpers3", "meissner": "bumpers3",
	"parabolic": "focus", "whisper": "focus", "spiral": "focus",
	"spring_st": "bank", "venturi": "bank", "hypotenuse": "bank", "benzene": "bank", "pentagon": "bank", "lshell": "bank",
	"sierpinski": "bank2", "stellated": "bank2", "tectonic": "bank2", "tilted": "bank",
	"chain": "triple", "tesla": "triple", "closing": "heat4", "blackice": "heat4", "cat": "cathit",
}


## The board's Discovery: {kind, text, money, chalk}. Boards not listed ask for a double.
static func discovery(board_id: String) -> Dictionary:
	var kind: String = DISCOVERIES.get(board_id, "double")
	var hard: bool = kind in ["ko", "triple", "bank2"]
	return {"kind": kind, "text": DISCOVERY_KINDS[kind], "money": 4 if hard else 3, "chalk": 1 if board_id == "final" else 0}
