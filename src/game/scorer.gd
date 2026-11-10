class_name Scorer
extends RefCounted
## Chain Reaction scoring. A shot's event log is walked in the order things
## really happened: contacts grow the Chain, and each ball pays out at the Chain
## it had at the moment it dropped.
##
##     pot = value × Chain × Heat multiplier × any pot multipliers

const HEAT_STEP := 0.5
const AFTER_POT := 0.5   # each ball that drops lifts the next one in the same shot
const EIGHT_FOUL := "The 8 dropped"


static func heat_mult(heat: int) -> float:
	return 1.0 + HEAT_STEP * heat


## Chain at the start of a shot, before any contact.
static func start_chain(ctx: Dictionary) -> float:
	var perks: Array = ctx.get("perks", [])
	var c := 1.0
	if ctx.get("boss", "") == "sinkhole":
		c = 2.0
	if perks.has("power") and float(ctx.get("power", 0.5)) >= 0.85:
		c += 1.0
	if perks.has("afterburner") and ctx.get("is_break", false):
		c += 3.0
	if perks.has("entropy"):
		c += minf(3.0, 0.25 * int(ctx.get("shots_taken", 0)))
	if perks.has("collector"):
		c += 0.5 * (ctx.get("pockets_used", []) as Array).size()
	if perks.has("venture"):
		c += minf(1.5, 0.25 * int(int(ctx.get("money", 0)) / 5))
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
			if e.a != 0 and e.b != 0 and perks.has("elastic"):
				add += 0.25
			if (e.a == 8 or e.b == 8) and perks.has("kissblack"):
				add += 0.75
			for n in [e.a, e.b]:
				if imbues.get(n, "") == "spark":
					add += 1.0
		"rail":
			if e.a != 0:
				if perks.has("ricochet"):
					add += 0.25
				if boss == "frozen":
					add += 0.5
			elif contacted and perks.has("tracer"):
				add += 0.25
		"bumper":
			if boss == "parlor" or boss == "posts":
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
	for e in events:
		match e.type:
			"ball":
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
				if e.a == 0:
					scratch = true
				else:
					pots.append(e)

	var out := {
		"lines": [], "total": 0, "money": 0, "chain": 1.0, "heat_gain": 0,
		"potted": pots.map(func(p): return p.a), "scratch": scratch, "foul": "", "scored": false,
		"first_contact": first_contact, "shattered": [], "catalyst_gain": 0.0,
		"power": ctx.get("power", 0.5), "is_break": ctx.get("is_break", false),
		"banks": 0, "max_rails": 0, "combos": 0, "kick": kick, "hot_pots": 0, "pocket_list": [],
		"element_mix": ctx.get("element_mix", []),
		"penalty": 0, "eight_fine": 0, "last_eight": false,
		"solid_run": int(ctx.get("solid_run", 0)), "stripe_run": int(ctx.get("stripe_run", 0)),
	}
	# The 8 is an obstacle while other balls remain. The break is luck, so it is let off.
	var left_after := int(ctx.get("objects", 99)) - pots.size()
	var eight_early: bool = pots.any(func(p): return p.a == 8) and left_after > 0 and not ctx.get("is_break", false) and anomaly != "cursed8"
	if eight_early:
		_charge_eight(ctx, out)
	if scratch:
		out.foul = "Scratch"
		return out
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
	if perks.has("eight"):
		return
	if perks.has("hushmoney"):
		out.eight_fine = 3
	else:
		out.penalty = int(ceil(float(ctx.get("target", 0)) * Catalog.EIGHT_PENALTY))


## Second pass: replay the shot in order, paying each ball as it drops.
static func _pay(ctx: Dictionary, events: Array, pots: Array, toucher: Dictionary, kick: bool, left_after: int, eight_early: bool, out: Dictionary) -> Dictionary:
	var perks: Array = ctx.get("perks", [])
	var imbues: Dictionary = ctx.get("imbues", {})
	var boss: String = ctx.get("boss", "")
	var rng: RandomNumberGenerator = ctx.get("rng", null)
	var hot: int = ctx.get("hot_pocket", -1)
	var heat: int = ctx.get("heat", 0)
	var hm := heat_mult(heat)
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
	var remaining: Array = (ctx.get("on_table", []) as Array).duplicate()
	var solid_run := int(out.solid_run)
	var stripe_run := int(out.stripe_run)
	var stirred := false
	var boomerang: bool = ctx.has("cue_start") and ctx.has("cue_end") and (ctx.cue_start as Vector2).distance_to(ctx.cue_end) <= 120.0
	for e in events:
		if e.type == "ball":
			contacted = contacted or e.a == 0 or e.b == 0
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
			if not (perks.has("eight") or perks.has("darkhorse")):
				continue
		var facts := {
			"any": true, "odd": n % 2 == 1, "even": n % 2 == 0, "stripe": n >= 9, "solid": n <= 7,
			"corner": not (k == 1 or k == 4), "side": k == 1 or k == 4, "hot": k == hot, "eight": n == 8,
			"bank": rails > 0, "combo": by != 0, "clean": rails == 0 and by == 0 and not kick,
			"first": idx == 0, "extra": idx >= 1, "kick": kick, "triple": pots.size() >= 3,
			"repeat_pocket": seen_pocket.has(k), "soft": float(ctx.get("power", 0.5)) <= 0.35,
			"prime": Catalog.PRIMES.has(n), "fib": [1, 2, 3, 5, 8, 13].has(n),
			"lowest": n == int(ctx.get("lowest", -1)), "highest": n == int(ctx.get("highest", -1)),
			"heat3": heat >= 3, "last_chalk": int(ctx.get("chalk", 99)) == 1, "third": int(ctx.get("shots_taken", 0)) % 3 == 2,
			"boomerang": boomerang, "long": _long_pot(ctx, n, e),
			"last_eight": n == 8 and left_after == 0, "no_eight_touch": not toucher.has(8),
			"eight_count": (int(ctx.get("total_pots", 0)) + idx + 1) % 8 == 0,
			"stripe_hard": n >= 9 and float(ctx.get("power", 0.5)) >= 0.6,
			"last_solid": n <= 7 and not ctx.get("on_table", []).is_empty() and not remaining.any(func(b): return b <= 7),
			"last_stripe": n >= 9 and not ctx.get("on_table", []).is_empty() and not remaining.any(func(b): return b >= 9),
		}
		if facts.last_eight:
			out.last_eight = true
		var value := float(Catalog.ball_points(n)) + float(ctx.get("catalyst", 0.0))
		var pre_chain := 0.0
		var x := 1.0
		var tags: Array = []
		for id in perks:
			var fx: Dictionary = Catalog.PERKS[id].get("fx", {})
			if fx.is_empty() or not facts.get(fx.when, false):
				continue
			value += float(fx.get("value", 0))
			pre_chain += float(fx.get("chain", 0.0))
			x *= float(fx.get("x", 1.0))
			money += int(fx.get("money", 0))
			tags.append(Catalog.PERKS[id].name)
		# Built-in shot types.
		if rails > 0:
			if perks.has("bank"):
				pre_chain += float(rails)
				tags.append("Bank")
			out.banks += 1
			out.max_rails = maxi(out.max_rails, rails)
		if by != 0:
			out.combos += 1
		if k == hot:
			x *= 3.0 if perks.has("heat") else 2.0
			tags.append("Hot pocket")
			out.hot_pots += 1
		if n <= 7:
			if perks.has("steadyrun"):
				value += 8.0 * mini(solid_run, 8)
			if perks.has("solidsonly"):
				x *= 2.0
			if perks.has("stripesonly"):
				x *= 0.5
			solid_run += 1
			stripe_run = 0
		elif n >= 9:
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
		if perks.has("minimalist"):
			x *= pow(1.25, int(ctx.get("empty_slots", 0)))
		if perks.has("gold") and gold_paid < 3:
			gold_paid += 1
			money += 1
		# Imbues.
		match imbues.get(n, ""):
			"gold":
				money += 2
			"heavy":
				value += 40.0
			"glass":
				x *= 3.0
				if rng != null and rng.randf() < 0.25:
					out.shattered.append(n)
			"ember":
				out.heat_gain += 1
			"vein":
				pre_chain += 1.0
				value += 20.0
			"lucky":
				if rng != null and rng.randf() < 1.0 / 3.0:
					x *= 4.0
					tags.append("Lucky")
			"twin":
				value += float(Catalog.ball_points(n))
		# The table's own rule.
		match boss:
			"drift":
				pre_chain += 1.0
			"blackice":
				pre_chain += 0.5
			"slate":
				value += 15.0
			"iron":
				value += 20.0
			"magnet":
				value -= 5.0
			"cramped", "smoke", "tilted", "lights":
				x *= 1.5
			"two":
				x *= 2.0
			"spring_st", "hump":
				if rails > 0:
					x *= 2.0
			"hustler":
				x *= 0.85
			"final":
				if n == 8 and left_after == 0:
					x *= 5.0
					tags.append("The Last 8")
			"elements":
				var fused := _fuse(mix, Catalog.POCKET_ELEMENTS[k])
				x *= fused.x
				if fused.label != "":
					tags.append(fused.label)
				out.heat_gain += fused.heat
		chain += pre_chain
		var pts := value * chain * hm * x
		if idx == 0 and perks.has("echo"):
			pts *= 2.0
			tags.append("Double Take")
		var pays := int(floor(pts))
		total += pays
		out.lines.append({
			"label": "%d-ball" % n, "kind": "pot", "ball": n, "pocket": k, "value": value, "chain": chain,
			"heat": hm, "x": x, "points": pays, "tags": tags,
		})
		chain += AFTER_POT
		seen_pocket[k] = true
		out.pocket_list.append(k)
		idx += 1
	if idx == 0 and not stirred:
		out.foul = EIGHT_FOUL
		return out
	out.solid_run = solid_run
	out.stripe_run = stripe_run
	if perks.has("bedrock") and idx > 0 and pots.all(func(p): return p.a <= 7):
		out.heat_gain += 1
	if perks.has("streak") and pots.size() >= 2:
		out.heat_gain += 1
	if boss == "nineball" or boss == "closing":
		out.heat_gain += 1
	if perks.has("catalyst"):
		out.catalyst_gain = 0.5 * pots.size()
	out.chain = chain
	out.money = money
	out.total = int(total)
	out.element_mix = mix
	out.scored = true
	return out


static func _long_pot(ctx: Dictionary, n: int, e: Dictionary) -> bool:
	var starts: Dictionary = ctx.get("start_pos", {})
	return starts.has(n) and (starts[n] as Vector2).distance_to(e.get("at", Vector2.ZERO)) >= 450.0


## Element Table: the new element fuses with the last one or two in the mix.
static func _fuse(mix: Array, el: String) -> Dictionary:
	var out := {"x": 1.0, "label": "", "heat": 0}
	var now := el
	if now == "wild":
		now = mix[mix.size() - 1] if not mix.is_empty() else ""
	if now == "":
		return out
	if not mix.is_empty():
		var last: String = mix[mix.size() - 1]
		if last == now:
			out.x = 2.0
			out.label = "Pure " + Catalog.ELEMENTS[now].name
		else:
			var pair := [last, now]
			pair.sort()
			out.x = 3.0
			out.heat = 1
			out.label = Catalog.COMPOUNDS.get("%s+%s" % [pair[0], pair[1]], "Compound")
			if mix.size() >= 2 and mix[mix.size() - 2] != last and mix[mix.size() - 2] != now:
				out.x = 6.0
				out.label = "Perfect Mix"
	mix.append(now)
	while mix.size() > 2:
		mix.remove_at(0)
	return out


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
