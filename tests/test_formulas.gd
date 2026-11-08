extends SceneTree
## Every scoring Formula changes the score exactly as its card says.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func pot(n: int, k: int, rails: int = 0, at := Vector2.ZERO) -> Dictionary:
	return {"type": "pocket", "a": n, "pocket": k, "rails": rails, "at": at}


func run_case(formulas: Array, events: Array, extra: Dictionary = {}) -> Dictionary:
	var c := {"formulas": formulas, "isotopes": {}, "hot_pocket": -1, "lab": "standard", "streak": 0, "power": 0.5, "shots_taken": 0, "events": events}
	c.merge(extra, true)
	return Scorer.score(c)


func _initialize() -> void:
	var hit5 := [{"type": "ball", "a": 0, "b": 5}, pot(5, 0)]          # 15 chips, corner
	var hit4side := [{"type": "ball", "a": 0, "b": 4}, pot(4, 1)]      # 14 chips, side
	var hit12 := [{"type": "ball", "a": 0, "b": 12}, pot(12, 2)]       # 22 chips stripe
	var base := run_case([], hit5)
	check(base.total == 15, "baseline 15")
	check(run_case(["odd"], hit5).chips == 30, "odd +15 chips")
	check(run_case(["even"], hit4side).mult == 3, "even +2 mult")
	check(run_case(["stripes"], hit12).mult == 5, "stripes +4 mult")
	check(run_case(["solids"], hit5).chips == 40, "solids +25 chips")
	check(run_case(["prime"], hit5).mult == 5, "prime +4 mult")
	check(run_case(["corner"], hit5).mult == 3, "corner +2 mult")
	check(run_case(["side"], hit4side).mult == 6, "side +5 mult")
	check(run_case(["lever"], [{"type": "ball", "a": 0, "b": 5}, pot(5, 0, 0, Vector2(0, 0))], {"start_pos": {5: Vector2(600, 0)}}).mult == 5, "lever +4 on long pot")
	check(run_case(["lever"], [{"type": "ball", "a": 0, "b": 5}, pot(5, 0, 0, Vector2(0, 0))], {"start_pos": {5: Vector2(100, 0)}}).mult == 1, "lever ignores short pot")
	check(run_case(["bank"], [{"type": "ball", "a": 0, "b": 5}, pot(5, 0, 2)]).mult == 7, "bank +3 per rail")
	check(run_case([], [{"type": "rail", "a": 0}, {"type": "ball", "a": 0, "b": 5}, pot(5, 0)]).mult == 3, "kick +2")
	check(run_case(["kick"], [{"type": "rail", "a": 0}, {"type": "ball", "a": 0, "b": 5}, pot(5, 0)]).mult == 6, "kick drum x2")
	var combo := [{"type": "ball", "a": 0, "b": 3}, {"type": "ball", "a": 3, "b": 5}, pot(5, 0)]
	check(run_case([], combo).mult == 3, "combination +2")
	check(run_case(["chain"], combo).mult == 6, "chain reaction x2")
	var two := [{"type": "ball", "a": 0, "b": 3}, {"type": "ball", "a": 3, "b": 5}, pot(5, 0), pot(3, 0)]
	check(run_case(["multi"], two).mult == 1 + 2 + 3, "cluster +3 per extra ball")
	check(run_case([], hit5, {"streak": 2}).mult == 3 and run_case(["streak"], hit5, {"streak": 2}).mult == 7, "momentum triples streak")
	check(run_case([], hit5, {"hot_pocket": 0}).mult == 2 and run_case(["heat"], hit5, {"hot_pocket": 0}).mult == 3 and run_case(["heat"], hit5, {"hot_pocket": 0}).chips == 35, "heat sink x3 and +20 chips")
	check(run_case(["power"], hit5, {"power": 0.9}).mult == 6 and run_case(["power"], hit5, {"power": 0.5}).mult == 1, "kinetic energy at 85%+")
	check(run_case(["finesse"], hit5, {"power": 0.3}).chips == 30, "finesse x2 chips")
	var eight := [{"type": "ball", "a": 0, "b": 8}, pot(8, 0)]
	var e3 := run_case(["eight"], eight)
	check(e3.mult == 3 and e3.money == 3, "black hole x3 and $3")
	var three := [{"type": "ball", "a": 0, "b": 1}, {"type": "ball", "a": 1, "b": 2}, {"type": "ball", "a": 2, "b": 3}, pot(1, 0), pot(2, 2), pot(3, 5)]
	check(run_case(["gold"], three + [pot(4, 3)]).money == 3, "gold standard capped at $3")
	check(run_case(["entropy"], hit5, {"shots_taken": 4}).mult == 5, "entropy +1 per shot taken")
	var cat := run_case(["catalyst"], hit5, {"catalyst": 1.5})
	check(cat.mult == 2.5 and cat.catalyst_gain == 0.25, "catalyst applies and grows")
	check(is_equal_approx(run_case(["golden"], hit5).mult, 1.6), "golden ratio x1.6")
	check(run_case(["supernova"], three).mult == (1 + 1 + 1 + 2 + 2) * 3, "supernova x3 on 3+ pots")
	check(run_case(["fusion"], [{"type": "ball", "a": 0, "b": 3}, {"type": "ball", "a": 3, "b": 5}, pot(5, 0), pot(3, 0)]).mult == (1 + 2 + 1) * 3, "fusion x3 same pocket")
	check(run_case(["elastic"], three).chips == 11 + 12 + 13 + 12, "elastic +4 per collision")
	check(run_case([], hit5, {"bluechalk": true}).mult == 2, "blue chalk x2")
	print("new formulas")
	var bank1 := [{"type": "ball", "a": 0, "b": 5}, {"type": "rail", "a": 5}, pot(5, 0, 1)]
	check(run_case(["cushion"], bank1).chips == 35, "cushion theory +20 chips on banks")
	check(is_equal_approx(run_case(["geometry"], bank1).mult, 2 * 1.5), "sacred geometry x1.5 per bank pot")
	var rails3 := [{"type": "ball", "a": 0, "b": 5}, {"type": "rail", "a": 0}, {"type": "rail", "a": 0}, {"type": "rail", "a": 5}, pot(5, 0)]
	check(run_case(["ricochet"], rails3).chips == 15 + 6, "ricochet +2 per cushion")
	check(run_case(["tracer"], rails3).mult == 5, "tracer +2 per cue cushion after contact")
	check(run_case(["boomerang"], hit5, {"cue_start": Vector2(100, 100), "cue_end": Vector2(150, 120)}).mult == 2, "boomerang x2 when cue returns")
	check(run_case(["boomerang"], hit5, {"cue_start": Vector2(100, 100), "cue_end": Vector2(600, 120)}).mult == 1, "boomerang ignores far finish")
	check(run_case(["precision"], hit5).mult == 6, "precision +5 on clean pot")
	check(run_case(["precision"], bank1).mult == 2, "precision skips banks")
	check(run_case(["afterburner"], hit5, {"is_break": true}).mult == 3 and run_case(["afterburner"], hit5).mult == 1, "afterburner x3 on break only")
	check(run_case(["domino"], combo).chips == 45, "domino +30 on combinations")
	check(run_case(["rhythm"], hit5, {"streak": 2}).mult == 3 * 2 and run_case(["rhythm"], hit5, {"streak": 1}).mult == 2, "rhythm x2 on every third")
	check(run_case(["hothand"], hit5, {"streak": 3}).chips == 35 and run_case(["hothand"], hit5, {"streak": 2}).chips == 15, "hot hand from streak 3")
	check(run_case(["comeback"], hit5, {"chalk": 1}).mult == 2 and run_case(["comeback"], hit5, {"chalk": 3}).mult == 1, "comeback on last chalk")
	check(run_case(["collector"], hit5, {"pockets_used": [2, 4]}).mult == 1 + 6, "collector +2 per distinct pocket")
	var low := [{"type": "ball", "a": 0, "b": 2}, pot(2, 0)]
	check(run_case(["lowball"], low).mult == 5, "low ball +4")
	check(run_case(["highball"], [{"type": "ball", "a": 0, "b": 14}, pot(14, 0)]).chips == 24 + 35 and run_case(["highball"], [{"type": "ball", "a": 0, "b": 8}, pot(8, 0)]).chips == 18 + 35, "high roller +35 for 8 and up")
	check(run_case(["fibonacci"], [{"type": "ball", "a": 0, "b": 13}, pot(13, 0)]).mult == 4, "fibonacci +3")
	check(is_equal_approx(run_case(["rotation"], low, {"lowest": 2}).mult, 1.5) and run_case(["rotation"], low, {"lowest": 1}).mult == 1, "rotation x1.5 on lowest ball")
	var mb := run_case(["moneyball"], hit5, {"highest": 5})
	check(mb.mult == 2 and mb.money == 2, "money ball x2 and $2 on highest")
	check(run_case(["venture"], hit5, {"money": 23}).mult == 5 and run_case(["venture"], hit5, {"money": 90}).mult == 7, "venture +1 per $5 capped at 6")
	check(run_case(["glasscannon"], hit5).mult == 3, "glass cannon x3")
	check(is_equal_approx(run_case(["minimalist"], hit5, {"empty_slots": 2}).mult, 2.25), "minimalist x1.5 per empty slot")
	check(run_case(["echo"], hit5, {"hot_pocket": 0}).mult == 4, "echo repeats first xMult")
	check(run_case(["echo"], hit5).mult == 1, "echo needs an xMult")
	print("boss scoring rules")
	check(run_case([], hit5, {"anomaly": "rotation", "lowest": 1}).foul == "Wrong ball first", "rotation boss: wrong ball first is a foul")
	check(run_case([], [{"type": "ball", "a": 0, "b": 1}, pot(1, 0)], {"anomaly": "rotation", "lowest": 1}).scored, "rotation boss: lowest first scores")
	check(run_case([], eight, {"anomaly": "cursed8"}).foul == "Cursed 8", "cursed 8 voids the shot")
	check(run_case([], hit5, {"anomaly": "onepocket", "hot_pocket": 3}).foul == "Wrong pocket", "one pocket: other pockets do not score")
	check(run_case([], hit5, {"anomaly": "onepocket", "hot_pocket": 0}).total == 30, "two pockets: hot pocket scores x2")
	check(run_case([], hit5, {"anomaly": "onepocket", "hot_pocket": 5}).total == 15, "two pockets: the diagonal opposite also scores")
	check(run_case([], hit5, {"anomaly": "taxman"}).total == 12, "taxman takes 15% of chips")
	print("labs and isotopes")
	check(run_case([], hit5, {"lab": "cryo"}).mult == 2, "cryo +1 mult")
	check(run_case([], [{"type": "ball", "a": 0, "b": 5}, pot(5, 0, 1)], {"lab": "spring"}).mult == 3, "spring rails bank +2")
	check(run_case([], [{"type": "ball", "a": 0, "b": 5}, {"type": "bumper", "a": 5}, pot(5, 0)], {"lab": "cyclotron"}).chips == 25, "cyclotron bumper +10")
	check(run_case([], hit5, {"isotopes": {5: "neon"}}).mult == 5, "neon +4")
	check(run_case([], hit5, {"isotopes": {5: "heavy"}}).chips == 55, "tungsten +40")
	check(run_case([], hit5, {"isotopes": {5: "gold"}}).money == 2, "gilded +$2")
	check(run_case([], hit5, {"isotopes": {5: "glass"}}).mult == 2, "glass x2")
	print("run-level formulas")
	var run := RunState.new()
	run.start(5)
	run.formulas.assign(["chalk", "jaws"])
	run.begin_table()
	check(run.chalk == 6, "spare chalk +1")
	check(is_equal_approx(run.pocket_scale(), 1.08 * 1.12), "wide jaws")
	run.formulas.assign(["interest"])
	run.money = 23
	var rows := run.payout()
	var got_interest := rows.any(func(r): return r[0] == "Compound interest" and r[1] == 4)
	check(got_interest, "interest $1 per $5")
	var ins := RunState.new()
	ins.start(5)
	ins.formulas.assign(["insurance"])
	ins.begin_table()
	ins.apply_shot({"scored": false, "foul": "Scratch", "total": 0, "money": 0, "catalyst_gain": 0.0, "potted": [], "shattered": []}, false, 5, false)
	check(ins.chalk == 5, "insurance keeps chalk")
	for k in 2:
		ins.apply_shot({"scored": false, "foul": "Miss", "total": 0, "money": 0, "catalyst_gain": 0.0, "potted": [], "shattered": [], "lines": []}, false, 5, true)
	check(ins.chalk == 4, "insurance covers only the first 2 per table (%d)" % ins.chalk)
	print("new run-level formulas")
	var th := RunState.new()
	th.start(8)
	th.formulas.assign(["thrift", "overflow"])
	th.begin_table()
	th.chalk = 3
	th.score = th.target() * 2
	var pr := th.payout()
	check(pr.any(func(r): return r[0] == "Thrift" and r[1] == 5), "thrift pays $5 with 2+ chalk")
	var next_t: int = th.plan[1].target
	check(th.carry == mini(th.score - th.target(), int(next_t * 0.25)), "overflow carries excess score (%d)" % th.carry)
	th.advance_table()
	th.begin_table()
	check(th.score == int(next_t * 0.25) and th.carry == 0, "next table starts with the carried score")
	var gc := RunState.new()
	gc.start(8)
	gc.formulas.assign(["glasscannon"])
	gc.begin_table()
	gc.apply_shot({"scored": false, "foul": "Miss", "total": 0, "money": 0, "catalyst_gain": 0.0, "potted": [], "shattered": [], "lines": []}, false, 5, true)
	check(gc.chalk == 3, "glass cannon misses cost 2 chalk")
	var mg := RunState.new()
	mg.start(8)
	mg.formulas.assign(["migration"])
	mg.begin_table()
	var hot0 := mg.hot_pocket
	mg.apply_shot({"scored": true, "foul": "", "total": 10, "money": 0, "catalyst_gain": 0.0, "potted": [1], "shattered": [], "lines": [], "pocket_list": [2]}, false, 5, true)
	check(mg.hot_pocket == hot0 and mg.pockets_used == [2], "stay hot keeps pocket on a scoring shot; pockets tracked")
	var cp := RunState.new()
	cp.start(8)
	cp.formulas.assign(["coupon"])
	cp.roll_shop()
	check(cp.reroll_cost == 1, "coupon book makes rerolls start at $1")
	var hb := RunState.new()
	hb.start(8)
	hb.formulas.assign(["hunter"])
	hb.begin_table()
	hb.bounty = "double"
	var m0 := hb.money
	hb.apply_shot({"scored": true, "foul": "", "total": 10, "money": 0, "catalyst_gain": 0.0, "potted": [1, 2], "shattered": [], "lines": []}, false, 5, true)
	check(hb.money == m0 + 6, "bounty hunter doubles bounties")
	check(Catalog.FORMULAS.size() == 60, "60 formulas (%d)" % Catalog.FORMULAS.size())
	check(Catalog.ANOMALIES.size() == 15, "15 bosses (%d)" % Catalog.ANOMALIES.size())
	for id in Catalog.FORMULAS.keys() + Catalog.REAGENTS.keys():
		check(IconArt.MOTIFS.has(id), "%s has an icon" % id)
	check(IconArt.MOTIFS.size() == Catalog.FORMULAS.size() + Catalog.REAGENTS.size(), "no orphan icons")
	check(Catalog.synergies("ricochet", ["bank", "odd", "geometry"]) == ["bank", "geometry"], "synergy finds same-family formulas")
	check(Catalog.synergies("lens", ["chalk", "insurance"]).is_empty(), "utility formulas never claim synergy")
	for id in Catalog.FORMULAS:
		check(Catalog.FORMULAS[id].has("fam") and Catalog.FAMILY_NAMES.has(Catalog.FORMULAS[id].fam), "formula %s has a known family" % id)
	for id in Catalog.FORMULAS:
		check(Catalog.FORMULAS[id].has("desc") and Catalog.FORMULAS[id].cost > 0, "formula %s well-formed" % id)
	print("formula tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
