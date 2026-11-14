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
	check(r.scored and r.total > 0, "a combination bank with Elements scores")
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
	# Chalk carries over: a scratch costs 2, a cleared table gives 1 back, never above 12.
	var ch := RunState.new()
	ch.start(7)
	ch.begin_table()
	ch.forgiven = true
	var c1 := ch.chalk
	var o2 := ch.apply_shot({"scored": false, "foul": "Scratch", "total": 0, "money": 0, "catalyst_gain": 0.0, "potted": [], "shattered": []}, false, 9, false)
	check(ch.chalk == c1 - 2 and int(o2.get("chalk_cost", 0)) == 2, "a scratch costs 2 Chalk")
	var c2 := ch.chalk
	ch.advance_table()
	ch.begin_table()
	check(ch.chalk == c2 + 1, "Chalk carries to the next table, plus 1 for clearing (%d)" % ch.chalk)
	ch.chalk = 12
	ch.advance_table()
	check(ch.chalk == 12, "never more than 12")
	var ca := RunState.new()
	ca.start(7)
	ca.perks.assign(["chalk"])
	ca.begin_table()
	var c3 := ca.chalk
	ca.advance_table()
	check(ca.chalk == c3 + 2, "Calcium Chalk: +1 extra for each clear")
	var hr := RunState.new()
	hr.start(7, "hotrod")
	hr.begin_table()
	check(hr.chalk == RunState.BASE_CHALK - 1, "Hot Rod starts with 1 less Chalk")
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
	b.discovery_done = true   # the board's Discovery pays separately; keep it out of the bet sums
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
	# Never a bet you can't afford.
	var poor := RunState.new()
	poor.start(3)
	poor.money = 3
	poor.begin_table()
	check(poor.bounty != "" and poor.bet_stake() == 3, "with $3, the $4 stake is cut to $3")
	check(poor.take_bet() and poor.money == 0, "and you can take it")
	var broke := RunState.new()
	broke.start(3)
	broke.money = 1
	broke.begin_table()
	check(broke.bounty == "" and not broke.take_bet() and broke.bounty_met({"potted": [1, 2]}, -1) == false, "with $1 there is no side bet")
	var saved := RunState.new()
	saved.start(3)
	saved.money = 3
	saved.begin_table()
	var copy := RunState.new()
	copy.load_dict(saved.to_dict())
	check(copy.bet_stake() == 3, "the capped stake survives a save")
	var nb := RunState.new()
	nb.start(3)
	nb.begin_table()
	nb.discovery_done = true
	nb.bounty = "double"
	nb.money = 20
	nb.apply_shot(two, false, 5, true)
	check(nb.money == 20 and not nb.bet_open() and nb.bet_state == "passed", "a bet not taken before the first shot pays nothing and closes")
	var lb := RunState.new()
	lb.start(3)
	lb.table_index = 6
	lb.money = 50
	lb.begin_table()
	lb.bounty = "triple"
	check(lb.bet_stake() == 16 and is_equal_approx(lb.bet_multiple(), 4.0), "a Hard bet on table 7 pays 4× a $16 stake")
	lb.perks.assign(["hunter"])
	check(lb.bounty_reward() == 16 + 128, "Side Hustle doubles the winnings")
	print("payout and Isotopes")
	var pr := RunState.new()
	pr.start(3)
	pr.begin_table()
	pr.score = int(pr.target() * 1.35)
	pr.shots_taken = 6
	var rows := pr.payout()
	var by := {}
	for row in rows:
		by[str(row[0]).split(":")[0]] = int(row[1])
	check(by.get("Table cleared", 0) == 4 and by.get("Overkill", 0) == 3 and by.get("Quick clear", 0) == 4, "clearing pays $4, $1 per 10%% over and $1 per shot under 10 (%s)" % str(by))
	var slow := RunState.new()
	slow.start(3)
	slow.begin_table()
	slow.score = slow.target()
	slow.shots_taken = 14
	check(slow.payout().size() == 1, "a slow, exact clear pays only the base")
	var im := RunState.new()
	im.start(3)
	im.money = 50
	im.shop = [{"type": "imbue", "id": "vein", "cost": 5, "sold": false}, {"type": "imbue", "id": "twin", "cost": 4, "sold": false}, {"type": "imbue", "id": "spark", "ball": 12, "cost": 4, "sold": false}]
	check(im.buy(0) != "", "a loose Isotope needs a ball chosen")
	check(im.buy_imbue(0, 9) == "" and im.imbues[9] == "vein", "you choose which ball gets it")
	check(im.buy_imbue(1, 9) != "", "a ball holds only one Isotope")
	check(im.buy_imbue(1, 8) != "", "never the 8")
	im.ball_set.append(12)
	check(im.buy(2) == "" and im.imbues[12] == "spark", "a pre-Isotope ball applies directly")
	var sr := RunState.new()
	sr.start(4)
	sr.roll_shop()
	var imb: Array = sr.shop.filter(func(it): return it.type == "imbue")
	check(imb.any(func(it): return not it.has("ball")) and imb.any(func(it): return it.has("ball") and int(it.ball) >= 11), "the shop offers a loose Isotope and an Isotope 11-15 ball")
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
	var dv := RunState.new()
	dv.start(3)
	dv.begin_table()
	var dm := dv.money
	var dout := dv.apply_shot({"scored": true, "foul": "", "total": 40, "money": 0, "catalyst_gain": 0.0, "potted": [1, 2], "shattered": [], "lines": []}, false, 5, true)
	check(String(dout.get("discovery", "")) != "" and dv.money == dm + 3 and dv.discovery_done, "a board's Discovery pays once when made")
	dv.apply_shot({"scored": true, "foul": "", "total": 40, "money": 0, "catalyst_gain": 0.0, "potted": [3, 4], "shattered": [], "lines": []}, false, 3, true)
	check(dv.money == dm + 3, "and not a second time")
	print("rules tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
