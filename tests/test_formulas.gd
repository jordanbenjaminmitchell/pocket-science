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
	check(run_case(["stripes"], hit12).mult == 4, "stripes +3 mult")
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
	check(run_case([], hit5, {"streak": 2}).mult == 3 and run_case(["streak"], hit5, {"streak": 2}).mult == 5, "momentum doubles streak")
	check(run_case([], hit5, {"hot_pocket": 0}).mult == 2 and run_case(["heat"], hit5, {"hot_pocket": 0}).mult == 3, "heat sink x3")
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
	check(run.chalk == 5, "spare chalk +1")
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
	check(ins.chalk == 4, "insurance keeps chalk")
	for id in Catalog.FORMULAS:
		check(Catalog.FORMULAS[id].has("desc") and Catalog.FORMULAS[id].cost > 0, "formula %s well-formed" % id)
	print("formula tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
