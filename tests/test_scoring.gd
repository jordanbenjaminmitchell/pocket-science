extends SceneTree
## The Chain and Heat rules: each ball pays value × Chain × Heat as it drops,
## and bounces earn nothing without a Perk, Imbue or table rule.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func pot(n: int, k: int, rails: int = 0) -> Dictionary:
	return {"type": "pocket", "a": n, "pocket": k, "rails": rails, "at": Vector2.ZERO}


func hit(a: int, b: int) -> Dictionary:
	return {"type": "ball", "a": a, "b": b}


func run_case(events: Array, extra: Dictionary = {}) -> Dictionary:
	var c := {"perks": [], "imbues": {}, "hot_pocket": -1, "boss": "local", "lab": "standard", "anomaly": "", "heat": 0, "power": 0.5, "shots_taken": 0, "events": events}
	c.merge(extra, true)
	return Scorer.score(c)


func _initialize() -> void:
	var h5 := [hit(0, 5), pot(5, 0)]
	var rail5 := {"type": "rail", "a": 5}
	print("base rules")
	check(run_case(h5).total == 15, "a plain 5-ball pays 15")
	check(run_case([hit(0, 5), rail5, rail5, pot(5, 0)]).total == 15, "cushions earn nothing by themselves")
	check(run_case([hit(0, 5), pot(5, 0, 2)]).total == 15, "a bank pot earns nothing extra by itself")
	check(run_case([hit(0, 3), hit(3, 5), pot(5, 0)]).total == 15, "a combination earns nothing extra by itself")
	check(run_case([{"type": "rail", "a": 0}, hit(0, 5), pot(5, 0)]).total == 15, "a kick earns nothing extra by itself")
	check(run_case([hit(0, 5), {"type": "bumper", "a": 5}, pot(5, 0)]).total == 15, "bumpers earn nothing by themselves")
	check(run_case([hit(0, 5), pot(5, 0), pot(3, 2)]).total == 34, "the second ball pays at Chain 1.5")
	check(run_case(h5, {"heat": 2}).total == 30, "Heat 2 multiplies by 2")
	check(run_case(h5, {"hot_pocket": 0}).total == 30, "hot pocket doubles")
	check(run_case([hit(0, 8), pot(8, 0)], {"objects": 1}).total == 18, "the 8 pays plainly when it is the last ball")
	print("items make bounces count")
	check(run_case([hit(0, 5), rail5, pot(5, 0)], {"perks": ["ricochet"]}).total == 18, "Ricochet: cushion adds Chain")
	check(run_case([hit(0, 3), hit(3, 5), pot(5, 0)], {"perks": ["elastic"]}).total == 18, "Loud Table: ball hit adds Chain")
	check(run_case([hit(0, 5), pot(5, 0, 2)], {"perks": ["bank"]}).total == 45, "Bank Manager: +1 Chain per cushion")
	check(run_case([hit(0, 5), pot(5, 0)], {"imbues": {5: "spark"}}).total == 30, "Spark: struck ball adds Chain")
	print("perks")
	check(run_case(h5, {"perks": ["odd"]}).total == 30, "Odd Balls +15")
	check(run_case(h5, {"perks": ["golden"]}).total == 24, "First Blood ×1.6")
	check(run_case(h5, {"perks": ["glasscannon"]}).total == 30, "All In ×2")
	check(run_case(h5, {"perks": ["echo"]}).total == 30, "Double Take pays twice")
	check(run_case(h5, {"perks": ["afterburner"], "is_break": true}).total == 60, "Break Artist starts at Chain 4")
	check(run_case(h5, {"perks": ["minimalist"], "empty_slots": 2}).total == 23, "Travel Light ×1.25 per empty slot")
	for id in Catalog.PERKS:
		var fx: Dictionary = Catalog.PERKS[id].get("fx", {})
		if not fx.is_empty():
			check(fx.has("when") and (fx.has("value") or fx.has("chain") or fx.has("x") or fx.has("money")), "%s fx is well formed" % id)
	print("table rules")
	check(run_case([hit(0, 5), rail5, pot(5, 0)], {"boss": "frozen"}).total == 22, "Frozen Lake pays for cushions")
	check(run_case([hit(0, 5), {"type": "bumper", "a": 5}, pot(5, 0)], {"boss": "parlor"}).total == 30, "Pinball Parlor pays for bumpers")
	check(run_case([hit(0, 5), pot(5, 0, 1)], {"boss": "spring_st"}).total == 30, "Spring Street pays for banks")
	check(run_case(h5, {"boss": "drift"}).total == 30, "The Drift adds Chain on pots")
	check(run_case(h5, {"boss": "hustler"}).total == 12, "The Hustler skims 15%")
	var early := run_case([hit(0, 8), pot(8, 0)], {"boss": "final", "anomaly": "cursed8", "objects": 5})
	check(not early.scored and early.foul == "The 8 went early", "the Final punishes an early 8")
	check(run_case([hit(0, 8), pot(8, 0)], {"boss": "final", "anomaly": "cursed8", "objects": 1}).total == 90, "the last 8 pays ×5")
	print("element table")
	var el := {"boss": "elements", "anomaly": "elements"}
	var two := run_case([hit(0, 5), pot(5, 0), pot(3, 2)], el)
	check(two.total == 73 and two.heat_gain == 1, "Fire then Water makes Steam ×3 (%d)" % two.total)
	check(run_case(h5, {"boss": "elements", "anomaly": "elements", "element_mix": ["fire"]}).total == 30, "same element is Pure ×2")
	check(run_case([hit(0, 5), pot(5, 2)], {"boss": "elements", "anomaly": "elements", "element_mix": ["air", "fire"]}).total == 90, "three different elements are a Perfect Mix ×6")
	check(run_case([hit(0, 5), pot(5, 1)], {"boss": "elements", "anomaly": "elements", "element_mix": ["water"]}).total == 30, "side pockets copy the last element")
	print("run structure")
	check(RunState.MAX_PERKS == 6, "six perk slots")
	var r := RunState.new()
	r.start(77)
	check(r.plan.size() == 9, "nine tables")
	check(r.plan[0].id == "local" and r.plan[4].id == "elements" and r.plan[8].id == "final", "fixed tables in place")
	var ids := {}
	for t in r.plan:
		check(Catalog.BOSSES.has(t.id) and Catalog.LABS.has(t.lab) and not ids.has(t.id), "%s is a valid, unique table" % t.id)
		ids[t.id] = true
	r.begin_table()
	var miss := {"scored": false, "foul": "Miss", "potted": [], "lines": []}
	r.heat = 5
	var chalk0 := r.chalk
	var a := r.apply_shot(miss, false, 5, true)
	check(r.heat == 2, "a miss halves Heat")
	check(r.chalk == chalk0 and a.has("forgiven"), "The Local forgives the first miss")
	r.apply_shot(miss, false, 5, true)
	check(r.chalk == chalk0 - 1, "the second miss costs Chalk")
	print("scoring tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
