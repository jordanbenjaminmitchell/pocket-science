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
				if e.a == 0 and first_contact < 0:
					kick_rails += 1
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
		"shattered": [], "catalyst_gain": 0.0,
	}
	if scratch:
		out.foul = "Scratch"
		return out
	if first_contact < 0 and pots.is_empty():
		out.foul = "No contact"
		return out
	if pots.is_empty():
		out.foul = "Miss"
		return out

	var lines: Array = out.lines
	var streak: int = ctx.get("streak", 0)
	if streak > 0:
		var per := 2.0 if formulas.has("streak") else 1.0
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
		if lab == "cryo":
			lines.append(_l("Cryo Felt", "mult", 1, n, k))
		if formulas.has("odd") and n % 2 == 1:
			lines.append(_l("Odd Hypothesis", "chips", 15, n, k))
		if formulas.has("even") and n % 2 == 0:
			lines.append(_l("Even Hypothesis", "mult", 2, n, k))
		if formulas.has("stripes") and Catalog.is_stripe(n):
			lines.append(_l("Stripe Theory", "mult", 3, n, k))
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
		if rails > 0:
			var per_rail := 3 if formulas.has("bank") else 1
			if lab == "spring":
				per_rail += 1
			lines.append(_l("Bank ×%d" % rails, "mult", per_rail * rails, n, k))
		var by: int = toucher.get(n, 0)
		if by != 0:
			lines.append(_l("Combination", "mult", 2, n, k))
			if formulas.has("chain"):
				lines.append(_l("Chain Reaction", "xmult", 2, n, k))
		if idx >= 1:
			lines.append(_l("Cluster", "mult", 3 if formulas.has("multi") else 1, n, k))
		if k == hot:
			lines.append(_l("Hot pocket", "xmult", 3 if formulas.has("heat") else 2, n, k))
		if n == 8:
			lines.append(_l("Black 8", "xmult", 3 if formulas.has("eight") else 2, n, k))
			if formulas.has("eight"):
				lines.append(_l("Black Hole", "money", 3, n, k))
		if idx == 0 and formulas.has("golden"):
			lines.append(_l("Golden Ratio", "xmult", 1.6, n, k))
		if formulas.has("gold") and gold_paid < 3:
			gold_paid += 1
			lines.append(_l("Gold Standard", "money", 1, n, k))

	if kick_rails > 0:
		lines.append(_l("Kick shot", "mult", 2))
		if formulas.has("kick"):
			lines.append(_l("Kick Drum", "xmult", 2))
	if formulas.has("elastic") and collisions > 0:
		lines.append(_l("Elastic ×%d" % collisions, "chips", 4 * collisions))
	if lab == "cyclotron" and bumpers > 0:
		lines.append(_l("Bumper ×%d" % bumpers, "chips", 10 * bumpers))
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
	if ctx.get("bluechalk", false):
		lines.append(_l("Blue Chalk", "xmult", 2))

	# Additive bonuses first, then multipliers: Mult = (1 + bonuses) × multipliers.
	var additive: Array = lines.filter(func(l): return l.kind == "chips" or l.kind == "mult" or l.kind == "money")
	var multiplicative: Array = lines.filter(func(l): return l.kind == "xmult" or l.kind == "xchips")
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
