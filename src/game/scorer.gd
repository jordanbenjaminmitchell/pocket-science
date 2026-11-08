class_name Scorer
extends RefCounted
## Turns a shot's event log into a Chips × Mult result.
##
## Lines are applied strictly in order, so the tally animation can replay them
## one by one: "chips" adds Chips, "mult" adds Mult, "xmult" multiplies Mult,
## "xchips" multiplies Chips and "money" pays dollars.


static func score(ctx: Dictionary) -> Dictionary:
	var events: Array = ctx.get("events", [])
	var formulas: Array = ctx.get("formulas", [])
	var isotopes: Dictionary = ctx.get("isotopes", {})
	var hot: int = ctx.get("hot_pocket", -1)
	var lab: String = ctx.get("lab", "standard")
	var start_pos: Dictionary = ctx.get("start_pos", {})
	var rng: RandomNumberGenerator = ctx.get("rng", null)
	var anomaly: String = ctx.get("anomaly", "")
	var lowest: int = ctx.get("lowest", -1)
	var highest: int = ctx.get("highest", -1)
	var total_rails := 0
	var cue_rails_after := 0

	var pots: Array = []
	var scratch := false
	var first_contact := -1
	var kick_rails := 0
	var collisions := 0
	var bumpers := 0
	var toucher := {}   # ball -> first ball that touched it
	for e in events:
		match e.type:
			"ball":
				collisions += 1
				if first_contact < 0 and (e.a == 0 or e.b == 0):
					first_contact = e.b if e.a == 0 else e.a
				if not toucher.has(e.a):
					toucher[e.a] = e.b
				if not toucher.has(e.b):
					toucher[e.b] = e.a
			"rail":
				total_rails += 1
				if e.a == 0 and first_contact < 0:
					kick_rails += 1
				elif e.a == 0:
					cue_rails_after += 1
			"bumper":
				bumpers += 1
				if e.a == 0 and first_contact < 0:
					kick_rails += 1
			"pocket":
				if e.a == 0:
					scratch = true
				else:
					pots.append(e)

	var out := {
		"lines": [], "chips": 0.0, "mult": 1.0, "total": 0, "money": 0,
		"potted": pots.map(func(p): return p.a), "scratch": scratch,
		"foul": "", "scored": false, "first_contact": first_contact,
		"shattered": [], "catalyst_gain": 0.0, "power": ctx.get("power", 0.5), "is_break": ctx.get("is_break", false),
		"radium_used": [],
	}
	if scratch:
		out.foul = "Scratch"
		return out
	if first_contact < 0 and pots.is_empty():
		out.foul = "No contact"
		return out
	# Boss rules that decide whether a shot counts at all.
	if anomaly == "rotation" and lowest > 0 and first_contact != lowest:
		out.foul = "Wrong ball first"
		return out
	if anomaly == "cursed8" and pots.any(func(p): return p.a == 8):
		out.foul = "Cursed 8"
		return out
	if anomaly == "onepocket":
		# Two Pockets: only the hot pocket and its diagonal opposite (5 - hot) score.
		pots = pots.filter(func(p): return p.pocket == hot or p.pocket == 5 - hot)
	if pots.is_empty():
		out.foul = "Wrong pocket" if anomaly == "onepocket" and not out.potted.is_empty() else "Miss"
		return out

	var lines: Array = out.lines
	var streak: int = ctx.get("streak", 0)
	if streak > 0:
		var per := 3.0 if formulas.has("streak") else 1.0
		lines.append(_l("Streak %d" % streak, "mult", per * streak))

	var gold_paid := 0
	var per_pocket := {}
	for idx in pots.size():
		var p: Dictionary = pots[idx]
		var n: int = p.a
		var k: int = p.pocket
		per_pocket[k] = per_pocket.get(k, 0) + 1
		lines.append(_l("%d-ball" % n, "chips", Catalog.ball_points(n), n, k))
		var iso: String = isotopes.get(n, "")
		match iso:
			"heavy":
				lines.append(_l("Tungsten", "chips", 40, n, k))
			"neon":
				lines.append(_l("Neon", "mult", 4, n, k))
			"gold":
				lines.append(_l("Gilded", "money", 2, n, k))
			"glass":
				lines.append(_l("Glass", "xmult", 2, n, k))
				if rng != null and rng.randf() < 0.25:
					out.shattered.append(n)
			"radium":
				var uses: int = ctx.get("radium", {}).get(str(n), 0)
				lines.append(_l("Radium", "mult", maxi(2, 10 - 2 * uses), n, k))
				out.radium_used.append(n)
			"prismatic":
				lines.append(_l("Prismatic", "chips", 20, n, k))
				lines.append(_l("Prismatic", "mult", 2, n, k))
			"lucky":
				if rng != null and rng.randf() < 1.0 / 3.0:
					lines.append(_l("Lucky", "xmult", 3, n, k))
			"resonant":
				lines.append(_l("Resonant", "chips", Catalog.ball_points(n), n, k))
		if lab == "cryo":
			lines.append(_l("Cryo Felt", "mult", 1, n, k))
		elif lab == "current":
			lines.append(_l("The Current", "mult", 2, n, k))
		elif lab == "magnetlab":
			lines.append(_l("Magnet Lab", "chips", -5, n, k))
		elif lab == "dense":
			lines.append(_l("Neutron Cloth", "chips", 15, n, k))
		if k == int(ctx.get("called", -1)):
			lines.append(_l("Called shot", "xmult", 3, n, k))
		if formulas.has("odd") and n % 2 == 1:
			lines.append(_l("Odd Hypothesis", "chips", 15, n, k))
		if formulas.has("even") and n % 2 == 0:
			lines.append(_l("Even Hypothesis", "mult", 2, n, k))
		if formulas.has("stripes") and Catalog.is_stripe(n):
			lines.append(_l("Stripe Theory", "mult", 4, n, k))
		if formulas.has("solids") and n <= 7:
			lines.append(_l("Solid State", "chips", 25, n, k))
		if formulas.has("prime") and Catalog.PRIMES.has(n):
			lines.append(_l("Prime Directive", "mult", 4, n, k))
		var side_pocket := k == 1 or k == 4
		if formulas.has("corner") and not side_pocket:
			lines.append(_l("Corner Theorem", "mult", 2, n, k))
		if formulas.has("side") and side_pocket:
			lines.append(_l("Side Effect", "mult", 5, n, k))
		if formulas.has("lever") and start_pos.has(n):
			var at: Vector2 = p.get("at", Vector2.ZERO)
			if (start_pos[n] as Vector2).distance_to(at) >= 450.0:
				lines.append(_l("Lever Arm", "mult", 4, n, k))
		var rails: int = mini(p.get("rails", 0), 3)
		if rails > 0 and formulas.has("cushion"):
			lines.append(_l("Cushion Theory", "chips", 20, n, k))
		if rails > 0 and formulas.has("geometry"):
			lines.append(_l("Sacred Geometry", "xmult", 1.5, n, k))
		if rails > 0:
			var per_rail := 3 if formulas.has("bank") else 1
			if lab == "spring" or lab == "repulsor":
				per_rail += 1
			lines.append(_l("Bank ×%d" % rails, "mult", per_rail * rails, n, k))
		var by: int = toucher.get(n, 0)
		if formulas.has("precision") and rails == 0 and by == 0 and kick_rails == 0:
			lines.append(_l("Precision", "mult", 5, n, k))
		if by != 0 and formulas.has("domino"):
			lines.append(_l("Domino Effect", "chips", 30, n, k))
		if by != 0:
			lines.append(_l("Combination", "mult", 2, n, k))
			if formulas.has("chain"):
				lines.append(_l("Chain Reaction", "xmult", 2, n, k))
		if idx >= 1:
			lines.append(_l("Cluster", "mult", 3 if formulas.has("multi") else 1, n, k))
		if k == hot:
			lines.append(_l("Hot pocket", "xmult", 3 if formulas.has("heat") else 2, n, k))
			if formulas.has("heat"):
				lines.append(_l("Heat Sink", "chips", 20, n, k))
		if n == 8:
			lines.append(_l("Black 8", "xmult", 3 if formulas.has("eight") else 2, n, k))
			if formulas.has("eight"):
				lines.append(_l("Black Hole", "money", 3, n, k))
		if idx == 0 and formulas.has("golden"):
			lines.append(_l("Golden Ratio", "xmult", 1.6, n, k))
		if formulas.has("hothand") and streak >= 3:
			lines.append(_l("Hot Hand", "chips", 20, n, k))
		if formulas.has("lowball") and n <= 3:
			lines.append(_l("Low Ball", "mult", 4, n, k))
		if formulas.has("highball") and n >= 8:
			lines.append(_l("High Roller", "chips", 35, n, k))
		if formulas.has("fibonacci") and [1, 2, 3, 5, 8, 13].has(n):
			lines.append(_l("Fibonacci", "mult", 3, n, k))
		if formulas.has("rotation") and n == lowest:
			lines.append(_l("Rotation", "xmult", 1.5, n, k))
		if formulas.has("moneyball") and n == highest:
			lines.append(_l("Money Ball", "xmult", 2, n, k))
			lines.append(_l("Money Ball", "money", 2, n, k))
		if formulas.has("gold") and gold_paid < 3:
			gold_paid += 1
			lines.append(_l("Gold Standard", "money", 1, n, k))

	if kick_rails > 0:
		lines.append(_l("Kick shot", "mult", 2))
		if formulas.has("kick"):
			lines.append(_l("Kick Drum", "xmult", 2))
	if formulas.has("elastic") and collisions > 0:
		var counted := mini(collisions, 12)
		lines.append(_l("Elastic ×%d" % counted, "chips", 4 * counted))
	if (lab == "cyclotron" or lab == "pinball") and bumpers > 0:
		lines.append(_l("Bumper ×%d" % bumpers, "chips", (10 if lab == "cyclotron" else 6) * bumpers))
	var power: float = ctx.get("power", 0.5)
	if formulas.has("power") and power >= 0.85:
		lines.append(_l("Kinetic Energy", "mult", 5))
	if formulas.has("finesse") and power <= 0.35:
		lines.append(_l("Finesse", "xchips", 2))
	if formulas.has("entropy"):
		var shots: int = ctx.get("shots_taken", 0)
		if shots > 0:
			lines.append(_l("Entropy", "mult", shots))
	if formulas.has("catalyst"):
		var cat: float = ctx.get("catalyst", 0.0)
		if cat > 0.0:
			lines.append(_l("Catalyst", "mult", cat))
		out.catalyst_gain = 0.25 * pots.size()
	if formulas.has("supernova") and pots.size() >= 3:
		lines.append(_l("Supernova", "xmult", 3))
	if formulas.has("fusion"):
		for k in per_pocket:
			if per_pocket[k] >= 2:
				lines.append(_l("Fusion", "xmult", 3, -1, k))
				break
	if formulas.has("ricochet") and total_rails > 0:
		var rc := mini(total_rails, 15)
		lines.append(_l("Ricochet ×%d" % rc, "chips", 2 * rc))
	if formulas.has("tracer") and cue_rails_after > 0:
		lines.append(_l("Tracer Round", "mult", 2 * mini(cue_rails_after, 3)))
	if formulas.has("collector"):
		var used: Array = ctx.get("pockets_used", []).duplicate()
		for p in pots:
			if not used.has(p.pocket):
				used.append(p.pocket)
		lines.append(_l("Collector ×%d" % used.size(), "mult", 2 * used.size()))
	if formulas.has("venture"):
		var v := mini(int(ctx.get("money", 0)) / 5, 6)
		if v > 0:
			lines.append(_l("Venture Capital", "mult", v))
	if formulas.has("boomerang") and ctx.has("cue_start") and ctx.has("cue_end"):
		if (ctx.cue_start as Vector2).distance_to(ctx.cue_end) <= 120.0:
			lines.append(_l("Boomerang", "xmult", 2))
	if formulas.has("afterburner") and ctx.get("is_break", false):
		lines.append(_l("Afterburner", "xmult", 3))
	if formulas.has("rhythm") and (streak + 1) % 3 == 0:
		lines.append(_l("Rhythm", "xmult", 2))
	if formulas.has("comeback") and int(ctx.get("chalk", 99)) == 1:
		lines.append(_l("Comeback", "xmult", 2))
	if formulas.has("glasscannon"):
		lines.append(_l("Glass Cannon", "xmult", 3))
	if formulas.has("minimalist"):
		var empty: int = ctx.get("empty_slots", 0)
		if empty > 0:
			lines.append(_l("Minimalist ×%d" % empty, "xmult", pow(1.5, empty)))
	if ctx.get("bluechalk", false):
		lines.append(_l("Blue Chalk", "xmult", 2))
	if ctx.get("overcharge", false):
		lines.append(_l("Overcharge", "xchips", 2))
	if anomaly == "taxman":
		lines.append(_l("Taxman", "xchips", 0.85))

	# Additive bonuses first, then multipliers: Mult = (1 + bonuses) × multipliers.
	var additive: Array = lines.filter(func(l): return l.kind == "chips" or l.kind == "mult" or l.kind == "money")
	var multiplicative: Array = lines.filter(func(l): return l.kind == "xmult" or l.kind == "xchips")
	if formulas.has("echo"):
		for i in multiplicative.size():
			if multiplicative[i].kind == "xmult":
				var again: Dictionary = multiplicative[i].duplicate()
				again.label = "Echo: " + again.label
				multiplicative.insert(i + 1, again)
				break
	lines = additive + multiplicative
	out.lines = lines
	var chips := 0.0
	var mult := 1.0
	var money := 0
	for l in lines:
		match l.kind:
			"chips":
				chips += l.value
			"mult":
				mult += l.value
			"xmult":
				mult *= l.value
			"xchips":
				chips *= l.value
			"money":
				money += int(l.value)
		l["chips_after"] = chips
		l["mult_after"] = mult
	out["pocket_list"] = pots.map(func(p): return p.pocket)
	out.chips = chips
	out.mult = mult
	out.money = money
	out.total = int(floor(chips * mult))
	out.scored = true
	return out


static func _l(label: String, kind: String, value: float, ball: int = -1, pocket: int = -1) -> Dictionary:
	return {"label": label, "kind": kind, "value": value, "ball": ball, "pocket": pocket}


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
