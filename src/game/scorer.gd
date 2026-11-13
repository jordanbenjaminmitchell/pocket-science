class_name Scorer
extends RefCounted
## Chain Reaction scoring. A shot's event log is walked in the order things
## really happened: contacts grow the Chain, and each ball pays out at the Chain
## it had at the moment it dropped.
##
##     pot = value × Chain × Heat multiplier × any pot multipliers

const HEAT_STEP := 0.5
const AFTER_POT := 0.5   # each ball that drops lifts the next one in the same shot
const EIGHT_FOUL := "The 8 sank"


static func heat_mult(heat: int) -> float:
	return 1.0 + HEAT_STEP * heat


## Chain at the start of a shot, before any contact.
static func start_chain(ctx: Dictionary) -> float:
	var perks: Array = ctx.get("perks", [])
	var c := 1.0
	if ctx.get("boss", "") == "sinkhole":
		c = 2.0
	if perks.has("entropy") and int(ctx.get("heat", 0)) < 3:
		c += 1.0   # Simmer: a cool table still builds
	if perks.has("venture"):
		c += minf(1.5, 0.25 * int(int(ctx.get("money", 0)) / 5))
	if perks.has("menagerie"):
		c += 0.25 * int(ctx.get("specials", 0))
	if perks.has("missing"):
		c += minf(3.0, 0.5 * int(ctx.get("removed", 0)))
	if ctx.get("beacon", false):
		c += 2.0   # Americium Beacon
	return c


## How much one contact adds to the Chain. The base game never rewards bouncing:
## only an owned Perk or Imbue, or a table whose own rule says so, makes it count.
static func chain_step(e: Dictionary, ctx: Dictionary, contacted: bool) -> float:
	var perks: Array = ctx.get("perks", [])
	var imbues: Dictionary = ctx.get("imbues", {})
	var boss: String = ctx.get("boss", "")
	var add := 0.0
	match e.type:
		"ball":
			for n in [e.a, e.b]:
				if imbues.get(n, "") == "spark":
					add += 1.0
				if imbues.get(n, "") == "prismatic":
					add += 0.25
		"rail":
			if e.a != 0:
				if imbues.get(e.a, "") == "charged":
					add += 0.5
				if perks.has("ricochet"):
					add += 0.25
			elif contacted and perks.has("tracer"):
				add += 0.25
		"boost":
			add += float(e.get("chain", 0.0))
		"bumper":
			if boss == "parlor" or boss == "posts" or boss == "foucault":
				add += 1.0
			elif boss == "galton":
				add += 0.5
			elif boss == "lattice":
				add += 0.25
		"portal":
			if boss == "erbridge" or boss == "mobius" or ctx.get("portal_chain", false):
				add += 1.0
	return add


static func score(ctx: Dictionary) -> Dictionary:
	var events: Array = ctx.get("events", [])
	var hot: int = ctx.get("hot_pocket", -1)
	var anomaly: String = ctx.get("anomaly", "")

	# First pass: what kind of shot was it?
	var pots: Array = []
	var scratch := false
	var first_contact := -1
	var kick := false
	var toucher := {}
	var clover := false
	var shattered_balls: Array = []
	# A Volatile ball that exploded counts as sunk: follow its blast with a sink event.
	var blown: Array = []
	for e in events:
		blown.append(e)
		if e.type == "shatter" and e.get("exploded", false):
			blown.append({"type": "pocket", "a": e.a, "pocket": 6, "rails": 0, "at": e.at, "exploded": true})
	events = blown
	var spark_hits := {}
	var last_hit := {}
	for e in events:
		match e.type:
			"shatter":
				shattered_balls.append(e.a)
			"ball":
				for pair in [[e.a, e.b], [e.b, e.a]]:
					spark_hits[pair[0]] = int(spark_hits.get(pair[0], 0)) + 1
					last_hit[pair[0]] = pair[1]
				if Catalog.kind_of(e.a) == "clover" or Catalog.kind_of(e.b) == "clover":
					clover = true
				if first_contact < 0 and (e.a == 0 or e.b == 0):
					first_contact = e.b if e.a == 0 else e.a
				if not toucher.has(e.a):
					toucher[e.a] = e.b
				if not toucher.has(e.b):
					toucher[e.b] = e.a
			"rail", "bumper":
				if e.a == 0 and first_contact < 0:
					kick = true
			"pocket":
				if Catalog.kind_of(e.a) == "clover":
					clover = true
				if e.a == 0:
					scratch = true
				else:
					pots.append(e)

	var out := {
		"lines": [], "total": 0, "money": 0, "chain": 1.0, "heat_gain": 0,
		"potted": pots.map(func(p): return p.a), "scratch": scratch, "foul": "", "scored": false,
		"first_contact": first_contact, "shattered": [], "catalyst_gain": 0.0, "perk_used": [], "recur": [], "echo_src": [], "recharge": 0, "chalk_gain": 0, "cleans": 0,
		"power": ctx.get("power", 0.5), "is_break": ctx.get("is_break", false),
		"banks": 0, "max_rails": 0, "combos": 0, "kick": kick, "hot_pots": 0, "pocket_list": [],
		"element_mix": ctx.get("element_mix", []),
		"penalty": 0, "eight_fine": 0, "last_eight": false, "frost": false, "heart": false, "lost_balls": [], "grown": [], "safe": false, "new_hot": -1,
		"solid_run": int(ctx.get("solid_run", 0)), "stripe_run": int(ctx.get("stripe_run", 0)),
		"lucky_hits": [], "lucky_misses": [], "jinxed": false,
		"weighted_sunk": [], "hairline_sunk": [], "gilded_sunk": [], "spark_jumps": [], "vein_spread": [], "twin_hops": [],
		"bounty_cash": 0, "kindled_live": false,
	}
	var imbue_level: Dictionary = ctx.get("imbue_level", {})
	var imb0: Dictionary = ctx.get("imbues", {})
	# Spark: three strikes in one shot and it arcs onto the last ball it hit.
	for sn in spark_hits:
		if imb0.get(sn, "") == "spark" and int(spark_hits[sn]) >= 3 and int(last_hit.get(sn, 0)) > 0:
			out.spark_jumps.append([sn, int(last_hit[sn])])
	# Kindled: a miss while it is still on the table wipes the Heat.
	for kn in ctx.get("on_table", []):
		if imb0.get(kn, "") == "ember" and not pots.any(func(p): return p.a == kn):
			out.kindled_live = true
	out.safe = clover
	out.lost_balls.append_array(shattered_balls)
	# The 8 is an obstacle while other balls remain. The break is luck, so it is let off.
	var left_after := int(ctx.get("objects", 99)) - pots.size()
	var eight_early: bool = pots.any(func(p): return p.a == 8) and left_after > 0 and not ctx.get("is_break", false) and anomaly != "cursed8"
	if eight_early:
		out["eight_early"] = true   # costs 2 Chalk in RunState unless Carbon Core makes it safe
		_charge_eight(ctx, out)
	if scratch and not (perks_of(ctx).has("followthru") and pots.size() >= 2):
		out.foul = "Scratch"
		return out
	if scratch:
		out["scratch_saved"] = true   # Francium Fizz: two or more went in with the cue ball
	if first_contact < 0 and pots.is_empty():
		out.foul = "No contact"
		return out
	if anomaly == "rotation" and int(ctx.get("lowest", -1)) > 0 and first_contact != int(ctx.lowest):
		out.foul = "Wrong ball first"
		return out
	# The Grand Final's own rule: the 8 must go last or the shot is a foul.
	if anomaly == "cursed8" and pots.any(func(p): return p.a == 8) and left_after > 0:
		out.foul = "The 8 went early"
		return out
	if anomaly == "onepocket":
		pots = pots.filter(func(p): return p.pocket == hot or p.pocket == 5 - hot)
	if pots.is_empty():
		out.foul = "Wrong pocket" if anomaly == "onepocket" and not out.potted.is_empty() else "Miss"
		return out

	return _pay(ctx, events, pots, toucher, kick, left_after, eight_early, out)


static func _charge_eight(ctx: Dictionary, out: Dictionary) -> void:
	var perks: Array = ctx.get("perks", [])
	if perks.has("eight") or ctx.get("safe8", false):
		return
	if perks.has("hushmoney"):
		out.eight_fine = -3   # Silver Tongue: it pays you instead
	else:
		out.penalty = int(ceil(float(ctx.get("target", 0)) * Catalog.EIGHT_PENALTY))


## Second pass: replay the shot in order, paying each ball as it drops.
static func _pay(ctx: Dictionary, events: Array, pots: Array, toucher: Dictionary, kick: bool, left_after: int, eight_early: bool, out: Dictionary) -> Dictionary:
	var perks: Array = ctx.get("perks", [])
	var imbues: Dictionary = ctx.get("imbues", {})
	var imbue_level: Dictionary = ctx.get("imbue_level", {})
	var boss: String = ctx.get("boss", "")
	var rng: RandomNumberGenerator = ctx.get("rng", null)
	var hot: int = ctx.get("hot_pocket", -1)
	var heat: int = ctx.get("heat", 0)
	var hm := heat_mult(heat)
	var all_hot: bool = ctx.get("all_hot", false)
	var scoring := {}
	for p in pots:
		scoring[p] = true
	var chain := start_chain(ctx)
	var contacted := false
	var idx := 0
	var seen_pocket := {}
	var gold_paid := 0
	var total := 0.0
	var money := 0
	var mix: Array = (ctx.get("element_mix", []) as Array).duplicate()
	var clock_pos := int(ctx.get("clock_pos", 0))
	var clock_streak := int(ctx.get("clock_streak", 0))
	var remaining: Array = (ctx.get("on_table", []) as Array).duplicate()
	var solid_run := int(out.solid_run)
	var stripe_run := int(out.stripe_run)
	var stirred := false
	var void_shot: bool = pots.any(func(p): return Catalog.kind_of(p.a) == "void")
	var coin_hits := {}
	var last_touch := {}
	var used_before: Dictionary = ctx.get("perk_used", {})
	var radiant_on := false
	for b in ctx.get("on_table", []):
		if imbues.get(int(b), "") == "radiant":
			radiant_on = true
	out.perk_used = []
	var boomerang: bool = ctx.has("cue_start") and ctx.has("cue_end") and (ctx.cue_start as Vector2).distance_to(ctx.cue_end) <= 120.0
	for e in events:
		if e.type == "ball":
			contacted = contacted or e.a == 0 or e.b == 0
			if e.a == 0 or e.b == 0:
				var other: int = e.b if e.a == 0 else e.a
				coin_hits[other] = int(coin_hits.get(other, 0)) + 1
			last_touch[e.a] = e.b
			last_touch[e.b] = e.a
		if e.type != "pocket":
			chain += chain_step(e, ctx, contacted)
			continue
		if not scoring.has(e):
			continue
		var n: int = e.a
		var k: int = e.pocket
		var rails: int = mini(e.get("rails", 0), 3)
		var by: int = toucher.get(n, 0)
		remaining.erase(n)
		if n == 8 and eight_early:
			if perks.has("trouble"):
				out.heat_gain += 3
				stirred = true
			# An early 8 earns nothing unless a Perk says it does.
			if not (perks.has("eight") or perks.has("darkhorse") or ctx.get("safe8", false)):
				continue
		var kind := Catalog.kind_of(n)
		var prism: bool = kind == "prism"
		var face := int(Catalog.faces.get(n, 0))
		var solid: bool = Catalog.is_solid(n) or prism
		var stripe: bool = Catalog.is_stripe(n) or prism
		var odd: bool = (n <= 15 and n % 2 == 1) or (face > 0 and face % 2 == 1)
		var even: bool = (n <= 15 and n % 2 == 0) or (face > 0 and face % 2 == 0)
		var bonus_after := 0.0
		var facts := {
			"any": true, "odd": odd, "even": even, "stripe": stripe, "solid": solid,
			"corner": not (k == 1 or k == 4), "side": k == 1 or k == 4, "hot": k == hot or all_hot, "eight": n == 8,
			"bank": rails > 0, "combo": by != 0, "clean": rails == 0 and by == 0 and not kick,
			"first": idx == 0, "extra": idx >= 1, "kick": kick, "triple": pots.size() >= 3,
			"repeat_pocket": seen_pocket.has(k) or (seen_pocket.is_empty() and k == int(ctx.get("last_pocket", -1))), "soft": float(ctx.get("power", 0.5)) <= 0.35,
			"prime": Catalog.PRIMES.has(n) or RunState._is_prime(face), "fib": [1, 2, 3, 5, 8, 13].has(n) or [1, 2, 3, 5, 8, 13].has(face),
			"lowest": n == int(ctx.get("lowest", -1)), "highest": n == int(ctx.get("highest", -1)),
			"heat3": heat >= 3, "on_fire": heat >= 5, "cold": heat == 0,
			"low3": (n >= 1 and n <= 3) or (face >= 1 and face <= 3), "high3": (n >= 13 and n <= 15) or (face >= 13 and face <= 15), "last_chalk": int(ctx.get("chalk", 99)) == 1, "third": int(ctx.get("shots_taken", 0)) % 3 == 2,
			"boomerang": boomerang, "long": _long_pot(ctx, n, e), "item_shot": ctx.get("item_shot", false), "kiss8": int(out.get("first_contact", -1)) == 8 and not ctx.get("is_break", false),
			"follow_shot": float(ctx.get("follow", 0.0)) > 0.2, "draw_shot": float(ctx.get("follow", 0.0)) < -0.2,
			"last_eight": n == 8 and left_after == 0, "no_eight_touch": not toucher.has(8),
			"eight_count": (int(ctx.get("total_pots", 0)) + idx + 1) % 8 == 0,
			"stripe_hard": stripe and float(ctx.get("power", 0.5)) >= 0.6,
			"last_solid": solid and not ctx.get("on_table", []).is_empty() and not remaining.any(func(b): return Catalog.is_solid(b)),
			"last_stripe": stripe and not ctx.get("on_table", []).is_empty() and not remaining.any(func(b): return Catalog.is_stripe(b)),
		}
		if facts.last_eight:
			out.last_eight = true
		var tags: Array = []
		var weight := (3 if perks.has("moneyball") else Catalog.NUMBER_WEIGHT)
		if imbues.get(n, "") == "heavy":
			weight = int(imbue_level.get(n, imbue_level.get(str(n), 3)))   # Weighted climbs with every sink
		var value := float(Catalog.ball_points(n, weight)) + float(ctx.get("catalyst", 0.0))
		var avalanche := int((ctx.get("ball_bonus", {}) as Dictionary).get(n, 0))
		value += float(avalanche)
		# Every step of this ball's score, with where it came from, for the on-screen sum.
		var steps: Array = [{"op": "=", "v": float(Catalog.ball_points(n, weight)), "src": "ball", "label": Catalog.ball_label(n)}]
		if float(ctx.get("catalyst", 0.0)) > 0.0:
			steps.append({"op": "+", "v": float(ctx.catalyst), "src": "perk:catalyst", "label": "Snowball"})
		if avalanche > 0:
			steps.append({"op": "+", "v": float(avalanche), "src": "perk:catalyst", "label": "Avalanche"})
		# Rotation: the lowest ball on the table pays like the highest one.
		if perks.has("rotation") and facts.lowest and int(ctx.get("highest", -1)) > n:
			value += float(Catalog.ball_points(int(ctx.highest), weight) - Catalog.ball_points(n, weight))
			tags.append("Rotation")
			steps.append({"op": "+", "v": float(Catalog.ball_points(int(ctx.highest), weight) - Catalog.ball_points(n, weight)), "src": "perk:rotation", "label": "Rotation"})
		if perks.has("thinrack") and int(ctx.get("removed", 0)) > 0:
			value += 1.0 * int(ctx.get("removed", 0))
			steps.append({"op": "+", "v": 1.0 * int(ctx.get("removed", 0)), "src": "perk:thinrack", "label": "Thinning"})
		var pre_chain := 0.0
		var x := 1.0
		for id in perks:
			var fx: Dictionary = Catalog.PERKS[id].get("fx", {})
			if fx.is_empty() or not facts.get(fx.when, false):
				continue
			if fx.get("once", false):
				# Once per table, but every sink of the shot that spends it counts.
				if used_before.has(id):
					continue
				if not out.perk_used.has(id):
					out.perk_used.append(id)
			var per_num := float(fx.get("per_num", 0)) * float(face if face > 0 else n)
			value += per_num
			if per_num > 0.0:
				_step(steps, Catalog.PERKS[id].name, "perk:" + id, [0.0, 1.0, 0.0], per_num, 1.0, 0.0)
			value += float(fx.get("value", 0))
			pre_chain += float(fx.get("chain", 0.0))
			x *= float(fx.get("x", 1.0))
			money += int(fx.get("money", 0))
			tags.append(Catalog.PERKS[id].name)
			_step(steps, Catalog.PERKS[id].name, "perk:" + id, [0.0, 1.0, 0.0], float(fx.get("value", 0)), float(fx.get("x", 1.0)), float(fx.get("chain", 0.0)))
		# Built-in shot types.
		var snap := [value, x, pre_chain]
		if rails > 0:
			if perks.has("bank"):
				pre_chain += float(rails)
				tags.append("Bank")
			if perks.has("geometry") and (not used_before.has("geometry") or out.perk_used.has("geometry")):
				x *= pow(1.5, rails)
				tags.append("Geometry")
				if not out.perk_used.has("geometry"):
					out.perk_used.append("geometry")
			out.banks += 1
			out.max_rails = maxi(out.max_rails, rails)
			_step(steps, "Bank", "perk:" + ("geometry" if perks.has("geometry") else "bank"), snap, value, x, pre_chain)
			snap = [value, x, pre_chain]
		if by != 0:
			out.combos += 1
		if facts.clean:
			out.cleans += 1
		if k == hot or all_hot:
			x *= 3.0 if perks.has("heat") else 2.0
			tags.append("Hot pocket")
			out.hot_pots += 1
			_step(steps, "Hot pocket", "hot", snap, value, x, pre_chain)
			snap = [value, x, pre_chain]
		if solid:
			if perks.has("steadyrun"):
				value += 12.0 * mini(solid_run, 8)
			if perks.has("solidsonly"):
				x *= 3.0
			if perks.has("stripesonly"):
				x *= 0.5
			solid_run += 1
			stripe_run = 0
		elif stripe:
			if perks.has("tiger"):
				pre_chain += 0.25 * mini(stripe_run, 8)
			if perks.has("stripesonly"):
				x *= 2.0
			if perks.has("solidsonly"):
				x *= 0.5
			if perks.has("luckystripe") and rng != null and rng.randf() < 1.0 / 3.0:
				x *= 3.0
				money += 2
				tags.append("Lucky Stripe")
			stripe_run += 1
			solid_run = 0
		if perks.has("gold") and gold_paid < 3:
			gold_paid += 1
			money += 1
		var suit_src := ""
		for sp in ["steadyrun", "solidsonly", "stripesonly", "tiger", "luckystripe", "gold"]:
			if perks.has(sp) and suit_src == "":
				suit_src = sp
		_step(steps, Catalog.PERKS[suit_src].name if suit_src != "" else "Suits", "perk:" + suit_src, snap, value, x, pre_chain)
		snap = [value, x, pre_chain]
		# Imbues.
		if imbues.has(n):
			out.echo_src.append(n)   # Europium Echo spreads it
		if radiant_on and imbues.get(n, "") != "radiant":
			value += 5.0   # a Radiant ball on the table
		match imbues.get(n, ""):
			"recurring":
				out.recur.append(n)
			"slick":
				value += 10.0
			"rubber":
				value += 5.0 * int(e.get("rails", 0))
			"tithed":
				money += mini(5, remaining.size())
			"catalytic":
				out.recharge += 1
			"chalked":
				out.chalk_gain += 1
			"excited":
				if int(out.get("first_contact", -1)) == n:
					out.heat_gain += 1
			"polarized":
				x *= 3.0 if (k == hot or all_hot) else 0.5
			"isolated":
				if facts.last_solid or facts.last_stripe:
					x *= 2.5
			"gold":
				money += 1 + mini(int(imbue_level.get(n, imbue_level.get(str(n), 0))), 4)
				out.gilded_sunk.append(n)
			"heavy":
				out.weighted_sunk.append(n)   # its number already counted above
			"glass":
				x *= 3.0
				var cracks := int(imbue_level.get(n, imbue_level.get(str(n), 0)))
				if rng != null and rng.randf() < 0.25 * (1 + cracks):
					out.shattered.append(n)
				else:
					out.hairline_sunk.append(n)
			"ember":
				out.heat_gain += 2
			"vein":
				value += 20.0
				var by_ball := int(toucher.get(n, 0))
				if by_ball != 0 and by_ball != 8:
					out.vein_spread.append(by_ball)
			"mirror":
				if by != 0:
					value += float(Catalog.ball_points(by, weight) - Catalog.ball_points(n, weight))
					tags.append("Mirror")
			"lucky":
				if rng != null:
					var lm: Dictionary = ctx.get("lucky_mult", {})
					var mult := float(lm.get(n, lm.get(str(n), 2)))
					if rng.randf() < 0.5:
						x *= mult
						tags.append("Lucky ×%d" % int(mult))
						out.lucky_hits.append(n)
					else:
						out.lucky_misses.append(n)
			"jinxed":
				x *= 4.0
				out.jinxed = true
			"pawned":
				x = 0.0
				money += 4
			"twin":
				value += float(Catalog.ball_points(n, weight))
				out.twin_hops.append(n)
			"frosted":
				out.frost = true
			"leaded":
				value += 45.0
			"bounty":
				money += heat
				out.bounty_cash += 2
			"starry":
				bonus_after += 0.5
		if imbues.has(n):
			_step(steps, Catalog.IMBUES[imbues[n]].name, "ball", snap, value, x, pre_chain)
		snap = [value, x, pre_chain]
		# Exotic balls.
		match kind:
			"piggy":
				money += mini(6, int(ctx.get("shots_taken", 0)))
			"jackpot":
				if rng != null:
					money += 10 if rng.randf() < 1.0 / 6.0 else 1
			"pinball":
				value += 10.0 * int(e.get("rails", 0))
			"fuse":
				out.heat_gain += idx
			"gold":
				money += int(e.get("rails", 0))
			"glass":
				x *= 3.0
			"feather":
				pre_chain += 0.5
			"ember":
				out.new_hot = k
				tags.append("New hot pocket")
			"clock":
				value += 9.0 * int(ctx.get("shots_taken", 0))
			"coin":
				money += int(coin_hits.get(n, 0))
			"seed":
				value += 15.0 * int((ctx.get("seed_growth", {}) as Dictionary).get(str(n), 0))
				out.grown.append(n)
			"clover":
				if rng != null and rng.randf() < 0.25:
					x *= 5.0
					tags.append("Clover")
			"star":
				pre_chain += 1.0
			"heart":
				if left_after == 0:
					out.heart = true
			"moon":
				if k == 1 or k == 4:
					x *= 2.0
			"sun":
				if not (k == 1 or k == 4):
					x *= 2.0
			"eraser":
				money += 4
				out.lost_balls.append(n)
				var victim := int(last_touch.get(n, 0))
				if victim != 0 and victim != 8:
					out.lost_balls.append(victim)
		if void_shot and kind != "void":
			x *= 2.0
		if kind != "" and kind != "numeral" and perks.has("goldrush"):
			x *= 1.5
		_step(steps, Catalog.BALL_TYPES[kind].name if kind != "" else ("Void" if void_shot else "Special"), "ball", snap, value, x, pre_chain)
		snap = [value, x, pre_chain]
		if n == int(ctx.get("golden_ball", -1)):
			x *= 1.618
			tags.append("Golden Ratio")
		if ctx.get("loan", false):
			x *= 1.0 - BoardFeatures.SKIM   # the Loan Shark's cut
			tags.append("Loan Shark")
		# The table's own rule.
		match boss:
			"drift":
				pre_chain += 1.0
			"gulf", "lorentz", "chain":
				pre_chain += 0.5
			"escape":
				pre_chain += 1.0
			"venturi":
				if facts.long:
					x *= 2.0
			"membrane", "maxwell", "lever":
				x *= 1.5
			"parabolic", "spiral":
				if k == int(ctx.get("focus", -1)):
					x *= 2.0
					tags.append("Focus" if boss == "parabolic" else "Drain")
			"whisper":
				if k == int(ctx.get("focus", -1)):
					x *= 3.0
					tags.append("Focus")
			"sierpinski", "stellated":
				if rails > 0:
					x *= 2.0
			"tectonic":
				if rails > 0:
					x *= 1.5
			"meissner":
				if facts.clean:
					x *= 2.0
			"tesla":
				if ctx.get("coil", false):
					x *= 2.0
					tags.append("Coil")
			"blackice":
				pre_chain += 0.5
			"magnet":
				value -= 10.0
			"cramped", "smoke", "tilted":
				x *= 1.5
			"two":
				x *= 2.0
			"spring_st":
				if rails > 0:
					x *= 2.0
			"final":
				if n == 8 and left_after == 0:
					x *= 5.0
					tags.append("The Last 8")
			"elements":
				# Clockwork: the next pocket in clock order ticks the clock; ticks in a row climb.
				if k == int(Catalog.CLOCK_ORDER[clock_pos]):
					clock_streak += 1
					x *= 1.0 + 0.5 * clock_streak
					tags.append("Tick %d" % (clock_pos + 1))
					clock_pos = (clock_pos + 1) % Catalog.CLOCK_ORDER.size()
				elif k < 6:
					clock_streak = 0
		_step(steps, "Table rule", "table", snap, value, x, pre_chain)
		snap = [value, x, pre_chain]
		x *= float(ctx.get("boost", 1.0))
		_step(steps, "Double Down", "item", snap, value, x, pre_chain)
		snap = [value, x, pre_chain]
		var call: Dictionary = ctx.get("called", {})
		if not call.is_empty() and int(call.ball) == n and int(call.pocket) == k:
			x *= 3.0
			tags.append("Called")
			steps.append({"op": "×", "v": 3.0, "src": "item", "label": "Called Shot"})
		if perks.has("secondcoat") and imbues.has(n):
			x *= 1.5
			steps.append({"op": "×", "v": 1.5, "src": "perk:secondcoat", "label": "Second Coat"})
		chain += pre_chain
		if chain != 1.0:
			steps.append({"op": "×", "v": chain, "src": "chain", "label": "Chain"})
		if hm != 1.0:
			steps.append({"op": "×", "v": hm, "src": "heat", "label": "Heat"})
		var pts := value * chain * hm * x
		var pays := int(floor(pts))
		total += pays
		out.lines.append({
			"label": Catalog.ball_label(n), "kind": "pot", "ball": n, "pocket": k, "value": value, "chain": chain,
			"heat": hm, "x": x, "points": pays, "tags": tags, "steps": steps,
		})
		chain += AFTER_POT + bonus_after
		seen_pocket[k] = true
		if k < 6:
			out.pocket_list.append(k)
		idx += 1
	if idx == 0 and not stirred:
		out.foul = EIGHT_FOUL
		return out
	out.solid_run = solid_run
	out.stripe_run = stripe_run
	if perks.has("bedrock") and idx > 0 and pots.all(func(p): return Catalog.is_solid(p.a)):
		out.heat_gain += pots.size()   # Aluminium Ore: +1 Heat per solid
	if perks.has("streak") and pots.size() >= 2:
		out.heat_gain += 1
	if boss == "closing":
		out.heat_gain += 1
	out.chain = chain
	# Lithium Cell: each charged ball pays $1.
	var lith: Array = ctx.get("lithium", [])
	for p in pots:
		if lith.has(int(p.a)):
			money += 1
	out.money = money
	out.total = int(total)
	out.element_mix = mix
	out.clock_pos = clock_pos
	out.clock_streak = clock_streak
	out.scored = true
	return out


## Records what one source changed: a flat value ("+"), Chain before the sink
## ("+c") and a multiplier ("×"), comparing [value, x, pre_chain] before and after.
static func _step(steps: Array, label: String, src: String, before: Array, value: float, x: float, pre_chain: float) -> void:
	if absf(value - float(before[0])) > 0.001:
		steps.append({"op": "+", "v": value - float(before[0]), "src": src, "label": label})
	if absf(pre_chain - float(before[2])) > 0.001:
		steps.append({"op": "+c", "v": pre_chain - float(before[2]), "src": src, "label": label})
	if float(before[1]) != 0.0 and absf(x / float(before[1]) - 1.0) > 0.001:
		steps.append({"op": "×", "v": x / float(before[1]), "src": src, "label": label})


static func _long_pot(ctx: Dictionary, n: int, e: Dictionary) -> bool:
	var starts: Dictionary = ctx.get("start_pos", {})
	return starts.has(n) and (starts[n] as Vector2).distance_to(e.get("at", Vector2.ZERO)) >= 450.0


## Quick estimate used by the aiming preview: "if this ball drops in that pocket".
static func preview(ctx: Dictionary, ball: int, pocket: int, rails: int, combo_by: int) -> Dictionary:
	var c := ctx.duplicate()
	var ev: Array = []
	if combo_by != 0:
		ev.append({"type": "ball", "a": 0, "b": combo_by})
		ev.append({"type": "ball", "a": combo_by, "b": ball})
	else:
		ev.append({"type": "ball", "a": 0, "b": ball})
	ev.append({"type": "pocket", "a": ball, "pocket": pocket, "rails": rails, "at": Vector2.ZERO})
	c["events"] = ev
	c["rng"] = null
	c.erase("start_pos")
	return score(c)


## The Elements in play for a shot context.
static func perks_of(ctx: Dictionary) -> Array:
	return ctx.get("perks", [])
