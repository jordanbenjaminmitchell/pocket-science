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
	"elastic": {"name": "Elastic Collision", "r": 0, "cost": 4, "icon": "⚛", "desc": "+4 Chips for every ball-to-ball collision in a scoring shot."},
	"odd": {"name": "Odd Hypothesis", "r": 0, "cost": 4, "icon": "1", "desc": "Odd-numbered balls give +15 Chips."},
	"even": {"name": "Even Hypothesis", "r": 0, "cost": 4, "icon": "2", "desc": "Even-numbered balls give +2 Mult."},
	"stripes": {"name": "Stripe Theory", "r": 0, "cost": 5, "icon": "≡", "desc": "Striped balls (9-15) give +3 Mult."},
	"solids": {"name": "Solid State", "r": 0, "cost": 5, "icon": "●", "desc": "Solid balls (1-7) give +25 Chips."},
	"corner": {"name": "Corner Theorem", "r": 0, "cost": 4, "icon": "◸", "desc": "Pots in corner pockets give +2 Mult."},
	"side": {"name": "Side Effect", "r": 0, "cost": 5, "icon": "◫", "desc": "Pots in side pockets give +5 Mult."},
	"lever": {"name": "Lever Arm", "r": 0, "cost": 5, "icon": "↦", "desc": "Long pots (ball travels 450+ to the pocket) give +4 Mult."},
	"chalk": {"name": "Spare Chalk", "r": 0, "cost": 5, "icon": "▣", "desc": "+1 Chalk on every table."},
	"jaws": {"name": "Wide Jaws", "r": 0, "cost": 6, "icon": "◯", "desc": "Pockets are 12% wider."},
	"lens": {"name": "Long Lens", "r": 0, "cost": 4, "icon": "⌖", "desc": "The guideline continues past the first cushion and shows the cue ball's full path to its next contact."},
	"interest": {"name": "Compound Interest", "r": 0, "cost": 5, "icon": "$", "desc": "After a table, earn $1 for every $5 you hold (max $5)."},
	"bank": {"name": "Angle of Incidence", "r": 1, "cost": 6, "icon": "∠", "desc": "Bank pots give +3 Mult per cushion instead of +1."},
	"kick": {"name": "Kick Drum", "r": 1, "cost": 6, "icon": "↯", "desc": "Kick shots (cue hits a cushion first) that pot: ×2 Mult."},
	"chain": {"name": "Chain Reaction", "r": 1, "cost": 7, "icon": "∞", "desc": "Combination pots (object ball into object ball) give ×2 Mult."},
	"multi": {"name": "Cluster Theory", "r": 1, "cost": 6, "icon": "⁂", "desc": "Every extra ball potted in one shot gives +3 Mult instead of +1."},
	"streak": {"name": "Momentum", "r": 1, "cost": 7, "icon": "»", "desc": "Your streak gives +2 Mult per step instead of +1."},
	"heat": {"name": "Heat Sink", "r": 1, "cost": 6, "icon": "♨", "desc": "The hot pocket gives ×3 Mult instead of ×2."},
	"power": {"name": "Kinetic Energy", "r": 1, "cost": 5, "icon": "⚡", "desc": "Shots at 85%+ power that pot give +5 Mult."},
	"finesse": {"name": "Finesse", "r": 1, "cost": 6, "icon": "~", "desc": "Shots at 35% power or less that pot give ×2 Chips."},
	"prime": {"name": "Prime Directive", "r": 1, "cost": 6, "icon": "π", "desc": "Prime balls (2, 3, 5, 7, 11, 13) give +4 Mult."},
	"eight": {"name": "Black Hole", "r": 1, "cost": 6, "icon": "◉", "desc": "The 8-ball gives ×3 instead of ×2, and pays $3."},
	"gold": {"name": "Gold Standard", "r": 1, "cost": 7, "icon": "¤", "desc": "Each pot pays $1 (max $3 per shot)."},
	"entropy": {"name": "Entropy", "r": 1, "cost": 6, "icon": "∿", "desc": "+1 Mult for every shot already taken on this table."},
	"catalyst": {"name": "Catalyst", "r": 2, "cost": 8, "icon": "⚗", "desc": "Gains +0.25 Mult permanently for every ball you pot."},
	"golden": {"name": "Golden Ratio", "r": 2, "cost": 8, "icon": "φ", "desc": "The first pot of every shot gives ×1.6 Mult."},
	"supernova": {"name": "Supernova", "r": 2, "cost": 9, "icon": "✸", "desc": "Shots that pot 3 or more balls: ×3 Mult."},
	"fusion": {"name": "Fusion", "r": 2, "cost": 8, "icon": "⊕", "desc": "Two or more balls into the same pocket in one shot: ×3 Mult."},
	"magnet": {"name": "Magnetic Pockets", "r": 2, "cost": 9, "icon": "U", "desc": "Pockets gently pull nearby moving balls in."},
	"insurance": {"name": "Causality Insurance", "r": 2, "cost": 7, "icon": "☂", "desc": "Scratches and misses never cost Chalk. Your streak still resets."},
	"oracle": {"name": "Laplace's Demon", "r": 2, "cost": 10, "icon": "◎", "desc": "See the real path of every ball for the first 1.5 seconds of each shot."},
}

## Reagents: single-use, held in two slots, used before a shot.
const REAGENTS := {
	"bluechalk": {"name": "Blue Chalk", "cost": 3, "icon": "▲", "desc": "Your next shot gets ×2 Mult."},
	"hand": {"name": "Ball in Hand", "cost": 3, "icon": "✋", "desc": "Pick up the cue ball and place it anywhere."},
	"spare": {"name": "Chalk Cube", "cost": 3, "icon": "▣", "desc": "+1 Chalk on this table."},
	"forecast": {"name": "Forecast", "cost": 3, "icon": "◎", "desc": "See every ball's full real path for your next shot."},
	"hotswap": {"name": "Hot Swap", "cost": 2, "icon": "♨", "desc": "Move the hot pocket to the pocket you click."},
}

## Isotopes enhance a specific ball number for the rest of the run.
const ISOTOPES := {
	"neon": {"name": "Neon", "cost": 4, "color": Color(0.3, 1.0, 0.85), "desc": "+4 Mult when this ball is potted."},
	"gold": {"name": "Gilded", "cost": 4, "color": Color(1.0, 0.82, 0.3), "desc": "+$2 when this ball is potted."},
	"heavy": {"name": "Tungsten", "cost": 3, "color": Color(0.75, 0.78, 0.85), "desc": "+40 Chips when this ball is potted."},
	"glass": {"name": "Glass", "cost": 5, "color": Color(0.7, 0.85, 1.0), "desc": "×2 Mult when potted, but 1 in 4 chance it shatters (enhancement lost)."},
}

## Labs set the table physics and cloth. "felt" is the cloth colour.
const LABS := {
	"standard": {"name": "Standard Felt", "felt": Color(0.06, 0.42, 0.28), "desc": "A clean, fast cloth. Pure pool."},
	"cryo": {"name": "Cryo Felt", "felt": Color(0.12, 0.42, 0.55), "desc": "Low friction: balls roll much further. All pots +1 Mult."},
	"cyclotron": {"name": "Cyclotron", "felt": Color(0.3, 0.2, 0.48), "desc": "A spring bumper sits mid-table. +10 Chips per bumper hit in a scoring shot."},
	"spring": {"name": "Spring Rails", "felt": Color(0.5, 0.14, 0.16), "desc": "Lively cushions. Bank pots give +1 extra Mult per cushion."},
	"gravity": {"name": "Gravity Well", "felt": Color(0.09, 0.2, 0.42), "desc": "A well at the centre bends moving balls toward it."},
}

## Anomalies are boss rules on every third table.
const ANOMALIES := {
	"tight": {"name": "Tight Pockets", "desc": "Pockets are 15% narrower."},
	"sealed": {"name": "Sealed Sides", "desc": "Both side pockets are closed."},
	"lead": {"name": "Lead Rack", "desc": "Object balls are 60% heavier."},
	"fog": {"name": "Fog", "desc": "The guideline stops at the ghost ball."},
	"dry": {"name": "Dry Chalk", "desc": "You start with 1 less Chalk."},
	"cold": {"name": "Cold Pockets", "desc": "There is no hot pocket."},
}

const TABLES := [
	{"target": 100, "rack": "nine"},
	{"target": 220, "rack": "nine"},
	{"target": 340, "rack": "nine", "boss": true},
	{"target": 550, "rack": "ten"},
	{"target": 800, "rack": "ten"},
	{"target": 1150, "rack": "fifteen", "boss": true},
	{"target": 1700, "rack": "fifteen"},
	{"target": 2500, "rack": "fifteen"},
	{"target": 3600, "rack": "fifteen", "boss": true},
]


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
