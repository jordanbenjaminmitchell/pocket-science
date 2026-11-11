extends SceneTree
## Scoring rules and run persistence.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func _initialize() -> void:
	print("scoring")
	var base := {"perks": [], "imbues": {}, "hot_pocket": -1, "lab": "standard", "streak": 0, "power": 0.5, "shots_taken": 0}
	var c := base.duplicate()
	c.events = [{"type": "ball", "a": 0, "b": 5}, {"type": "pocket", "a": 5, "pocket": 0, "rails": 0, "at": Vector2.ZERO}]
	var r := Scorer.score(c)
	check(r.scored and r.total == 20, "simple pot 5-ball = 20")
	c.hot_pocket = 0
	c.heat = 3
	r = Scorer.score(c)
	check(r.total == 100, "Heat 3 (×2.5) then hot ×2 = 100 (%d)" % r.total)
	c = base.duplicate()
	c.events = [{"type": "ball", "a": 0, "b": 2}, {"type": "ball", "a": 2, "b": 9}, {"type": "pocket", "a": 9, "pocket": 1, "rails": 2, "at": Vector2.ZERO}, {"type": "pocket", "a": 2, "pocket": 1, "rails": 0, "at": Vector2.ZERO}]
	c.perks = ["fusion", "bank"]
	r = Scorer.score(c)
	check(r.scored and r.total > 0, "a combination bank with perks scores")
	c = base.duplicate()
	c.events = [{"type": "ball", "a": 0, "b": 3}, {"type": "pocket", "a": 0, "pocket": 2, "rails": 0, "at": Vector2.ZERO}, {"type": "pocket", "a": 3, "pocket": 4, "rails": 0, "at": Vector2.ZERO}]
	r = Scorer.score(c)
	check(not r.scored and r.foul == "Scratch", "scratch voids the shot")
	c.events = []
	r = Scorer.score(c)
	check(r.foul == "No contact", "no contact foul")
	c.events = [{"type": "rail", "a": 0}, {"type": "ball", "a": 0, "b": 8}, {"type": "pocket", "a": 8, "pocket": 3, "rails": 0, "at": Vector2.ZERO}]
	c["objects"] = 1
	r = Scorer.score(c)
	check(r.total == 26, "a kick earns nothing; a last 8 pays its plain value (%d)" % r.total)
	c.erase("objects")

	print("run rules")
	var run := RunState.new()
	run.start(99)
	run.begin_table()
	check(run.chalk == RunState.BASE_CHALK, "%d chalk to start" % RunState.BASE_CHALK)
	var miss := {"scored": false, "foul": "Miss", "total": 0, "money": 0, "catalyst_gain": 0.0, "potted": [], "shattered": []}
	var o := run.apply_shot(miss, true, 9, true)
	check(run.chalk == RunState.BASE_CHALK and not o.chalk_lost, "dry break is free")
	run.forgiven = true   # past The Local's one free miss
	o = run.apply_shot(miss, false, 9, true)
	check(run.chalk == RunState.BASE_CHALK - 1 and o.chalk_lost, "miss costs chalk")
	var hit := {"scored": true, "foul": "", "total": 30, "money": 1, "catalyst_gain": 0.0, "potted": [1], "shattered": [], "lines": []}
	o = run.apply_shot(hit, false, 0, true)
	check(o.rack_cleared and run.chalk == RunState.BASE_CHALK and run.heat == 1, "clearing the rack refunds chalk")
	run.score = run.target() - 1
	o = run.apply_shot(hit, false, 5, true)
	check(o.cleared, "reaching the target clears the table")

	var op := RunState.new()
	op.start(3)
	op.plan[0].anomaly = "onepocket"
	op.begin_table()
	var c0 := op.chalk
	var hot_fixed := op.hot_pocket
	var wp := op.apply_shot({"scored": false, "foul": "Wrong pocket", "total": 0, "money": 0, "catalyst_gain": 0.0, "potted": [4], "shattered": [], "lines": []}, false, 5, true)
	check(op.chalk == c0 and not wp.chalk_lost and op.heat == 0, "one pocket: wrong pocket costs no chalk but breaks the streak")
	var rot := RunState.new()
	rot.start(3)
	rot.plan[0].anomaly = "rotation"
	rot.begin_table()
	var rc0 := rot.chalk
	rot.apply_shot({"scored": false, "foul": "Wrong ball first", "total": 0, "money": 0, "catalyst_gain": 0.0, "potted": [], "shattered": [], "lines": []}, false, 5, true)
	check(rot.chalk == rc0, "rotation: wrong ball first costs no chalk")
	print("side bets")
	var b := RunState.new()
	b.start(3)
	b.begin_table()
	b.bounty = "double"
	b.money = 20
	check(b.bet_stake() == 4 and b.bet_open(), "the first table offers a $4 bet")
	check(b.peek_bet() and b.money == 18 and b.bet_peeked, "peeking costs half the stake")
	check(not b.peek_bet(), "and only once")
	check(b.take_bet() and b.money == 14 and b.bet_state == "taken", "betting pays the stake")
	var m0 := b.money
	var two := {"scored": true, "foul": "", "total": 40, "money": 0, "catalyst_gain": 0.0, "potted": [1, 2], "shattered": [], "lines": []}
	var ob := b.apply_shot(two, false, 5, true)
	check(ob.has("bounty") and b.money == m0 + 4 + 8 and b.bet_state == "won", "a won Medium bet returns the stake plus 2× it ($12)")
	ob = b.apply_shot(two, false, 3, true)
	check(not ob.has("bounty") and b.money == m0 + 12, "and pays only once")
	var nb := RunState.new()
	nb.start(3)
	nb.begin_table()
	nb.bounty = "double"
	nb.money = 20
	nb.apply_shot(two, false, 5, true)
	check(nb.money == 20 and not nb.bet_open() and nb.bet_state == "passed", "a bet not taken before the first shot pays nothing and closes")
	var lb := RunState.new()
	lb.start(3)
	lb.table_index = 6
	lb.begin_table()
	lb.bounty = "triple"
	check(lb.bet_stake() == 16 and is_equal_approx(lb.bet_multiple(), 4.0), "a Hard bet on table 7 pays 4× a $16 stake")
	lb.perks.assign(["hunter"])
	check(lb.bounty_reward() == 16 + 128, "Side Hustle doubles the winnings")
	print("persistence")
	run.perks.assign(["golden", "bank"])
	run.imbues[7] = "vein"
	run.money = 17
	run.table_index = 2
	run.save()
	var r2 := RunState.new()
	check(r2.load_save(), "save loads")
	check(r2.perks == run.perks and r2.imbues.get(7, "") == "vein" and r2.money == 17 and r2.table_index == 2, "fields round-trip")
	check(r2.rng.randi() == run.rng.randi(), "rng state round-trips")
	check(r2.plan.size() == run.plan.size() and r2.current().target == run.current().target, "plan round-trips")
	print("save v2: mid-table, shop, backup, corruption")
	var m := RunState.new()
	m.start(77)
	m.begin_table()
	m.score = 123
	m.chalk = 2
	m.heat = 3
	m.bounty = "combo"
	m.bounty_done = true
	m.phase = "table"
	m.table_snapshot = {"balls": [{"n": 0, "x": 100.0, "y": 200.0, "alive": 1, "m": 1.0}, {"n": 5, "x": 300.0, "y": 250.0, "alive": 0, "m": 1.0}], "is_break": false}
	m.save()
	var m2 := RunState.new()
	check(m2.load_save() and m2.phase == "table" and m2.score == 123 and m2.chalk == 2 and m2.heat == 3, "mid-table state restored")
	check(m2.bounty == "combo" and m2.bounty_done, "bounty restored")
	check((m2.table_snapshot.balls as Array).size() == 2 and int(m2.table_snapshot.balls[1].alive) == 0, "ball snapshot restored")
	check(m2.rng.randi() == m.rng.randi(), "rng stream identical after mid-table load")
	m.phase = "shop"
	m.roll_shop()
	m.shop_payout = [["Table cleared", 3]]
	m.save()
	var m3 := RunState.new()
	check(m3.load_save() and m3.phase == "shop" and m3.shop.size() == m.shop.size() and m3.shop[0].id == m.shop[0].id, "shop phase restored with same offers")
	# Corrupt the main file: the backup (previous save, mid-table) must load.
	var fw := FileAccess.open(RunState.SAVE_PATH, FileAccess.WRITE)
	fw.store_string("{ this is not json")
	fw.close()
	var m4 := RunState.new()
	check(m4.load_save() and m4.phase == "table" and m4.score == 123, "corrupt save falls back to backup")
	# v1 save still loads (start of table).
	var v1 := run.to_dict()
	v1.v = 1
	v1.erase("phase")
	v1.erase("table")
	RunState.clear_save()
	var fv := FileAccess.open(RunState.SAVE_PATH, FileAccess.WRITE)
	fv.store_string(JSON.stringify(v1))
	fv.close()
	var m5 := RunState.new()
	check(not m5.load_save(), "saves from the old scoring are not loaded")
	# Garbage everywhere: refuse cleanly.
	var fg := FileAccess.open(RunState.SAVE_PATH, FileAccess.WRITE)
	fg.store_string("[1, 2, 3]")
	fg.close()
	check(not RunState.new().load_save(), "unusable save is rejected, not crashed on")
	RunState.clear_save()
	check(not RunState.has_save(), "save cleared")
	print("rules tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
