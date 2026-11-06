extends SceneTree
## Scoring rules and run persistence.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func _initialize() -> void:
	print("scoring")
	var base := {"formulas": [], "isotopes": {}, "hot_pocket": -1, "lab": "standard", "streak": 0, "power": 0.5, "shots_taken": 0}
	var c := base.duplicate()
	c.events = [{"type": "ball", "a": 0, "b": 5}, {"type": "pocket", "a": 5, "pocket": 0, "rails": 0, "at": Vector2.ZERO}]
	var r := Scorer.score(c)
	check(r.scored and r.chips == 15 and r.mult == 1 and r.total == 15, "simple pot 5-ball = 15 x 1 (%s x %s)" % [r.chips, r.mult])
	c.hot_pocket = 0
	c.streak = 3
	r = Scorer.score(c)
	check(r.total == 15 * 8, "streak 3 (+3) then hot x2 = 15 x 8 (%d)" % r.total)
	c = base.duplicate()
	c.events = [{"type": "ball", "a": 0, "b": 2}, {"type": "ball", "a": 2, "b": 9}, {"type": "pocket", "a": 9, "pocket": 1, "rails": 2, "at": Vector2.ZERO}, {"type": "pocket", "a": 2, "pocket": 1, "rails": 0, "at": Vector2.ZERO}]
	c.formulas = ["fusion", "bank"]
	r = Scorer.score(c)
	# 9: 19 chips, bank 2 rails x3 = +6, combo +2 ; 2: 12 chips, cluster +1 ; fusion x3
	check(r.chips == 31 and is_equal_approx(r.mult, (1 + 6 + 2 + 1) * 3.0), "combo + bank + cluster + fusion (%s x %s)" % [r.chips, r.mult])
	c = base.duplicate()
	c.events = [{"type": "ball", "a": 0, "b": 3}, {"type": "pocket", "a": 0, "pocket": 2, "rails": 0, "at": Vector2.ZERO}, {"type": "pocket", "a": 3, "pocket": 4, "rails": 0, "at": Vector2.ZERO}]
	r = Scorer.score(c)
	check(not r.scored and r.foul == "Scratch", "scratch voids the shot")
	c.events = []
	r = Scorer.score(c)
	check(r.foul == "No contact", "no contact foul")
	c.events = [{"type": "rail", "a": 0}, {"type": "ball", "a": 0, "b": 8}, {"type": "pocket", "a": 8, "pocket": 3, "rails": 0, "at": Vector2.ZERO}]
	r = Scorer.score(c)
	check(r.total == 18 * 6, "kick (+2) then black 8 (x2) = 18 x 6 (%d)" % r.total)

	print("run rules")
	var run := RunState.new()
	run.start(99)
	run.begin_table()
	check(run.chalk == 4, "4 chalk to start")
	var miss := {"scored": false, "foul": "Miss", "total": 0, "money": 0, "catalyst_gain": 0.0, "potted": [], "shattered": []}
	var o := run.apply_shot(miss, true, 9, true)
	check(run.chalk == 4 and not o.chalk_lost, "dry break is free")
	o = run.apply_shot(miss, false, 9, true)
	check(run.chalk == 3 and o.chalk_lost, "miss costs chalk")
	var hit := {"scored": true, "foul": "", "total": 30, "money": 1, "catalyst_gain": 0.0, "potted": [1], "shattered": []}
	o = run.apply_shot(hit, false, 0, true)
	check(o.rack_cleared and run.chalk == 4 and run.streak == 1, "clearing the rack refunds chalk")
	run.score = run.target() - 1
	o = run.apply_shot(hit, false, 5, true)
	check(o.cleared, "reaching the target clears the table")

	print("persistence")
	run.formulas.assign(["golden", "bank"])
	run.isotopes[7] = "neon"
	run.money = 17
	run.table_index = 2
	run.save()
	var r2 := RunState.new()
	check(r2.load_save(), "save loads")
	check(r2.formulas == run.formulas and r2.isotopes.get(7, "") == "neon" and r2.money == 17 and r2.table_index == 2, "fields round-trip")
	check(r2.rng.randi() == run.rng.randi(), "rng state round-trips")
	check(r2.plan.size() == run.plan.size() and r2.current().target == run.current().target, "plan round-trips")
	RunState.clear_save()
	check(not RunState.has_save(), "save cleared")
	print("rules tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
