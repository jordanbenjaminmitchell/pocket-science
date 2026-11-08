extends SceneTree
## New Reagents, Isotopes, Bounties, Cues and Labs do what their text says.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func _initialize() -> void:
	call_deferred("_go")


func pot(n: int, k: int, rails: int = 0) -> Dictionary:
	return {"type": "pocket", "a": n, "pocket": k, "rails": rails, "at": Vector2.ZERO}


func score(events: Array, extra: Dictionary = {}) -> Dictionary:
	var c := {"formulas": [], "isotopes": {}, "hot_pocket": -1, "lab": "standard", "streak": 0, "power": 0.5, "events": events}
	c.merge(extra, true)
	return Scorer.score(c)


func fresh(anomaly: String = "", lab: String = "standard") -> RunState:
	var r := RunState.new()
	r.start(21)
	r.plan[0].anomaly = anomaly
	r.plan[0].boss = anomaly != ""
	r.plan[0].lab = lab
	r.begin_table()
	return r


func miss() -> Dictionary:
	return {"scored": false, "foul": "Miss", "total": 0, "money": 0, "catalyst_gain": 0.0, "potted": [], "shattered": [], "lines": []}


func hit(potted: Array = [1], total: int = 20, extra: Dictionary = {}) -> Dictionary:
	var d := {"scored": true, "foul": "", "total": total, "money": 0, "catalyst_gain": 0.0, "potted": potted, "shattered": [], "lines": [], "chips": 10.0, "mult": 1.0}
	d.merge(extra, true)
	return d


func _go() -> void:
	create_timer(120.0).timeout.connect(func(): quit(2))
	var h5 := [{"type": "ball", "a": 0, "b": 5}, pot(5, 0)]
	print("counts")
	check(Catalog.REAGENTS.size() == 15, "15 reagents")
	check(Catalog.ISOTOPES.size() == 8, "8 isotopes")
	check(Catalog.BOUNTIES.size() == 25, "25 bounties")
	check(Catalog.CUES.size() == 10, "10 cues")
	check(Catalog.LABS.size() == 10, "10 labs")
	print("reagents")
	var r := fresh()
	var c0 := r.chalk
	r.use_instant("second")
	r.apply_shot(miss(), false, 5, true)
	check(r.chalk == c0, "second chance absorbs a miss")
	r.apply_shot(miss(), false, 5, true)
	check(r.chalk == c0 - 1, "and only one")
	r = fresh()
	r.streak = 1
	r.use_instant("adrenaline")
	check(r.streak == 4, "adrenaline +3 streak")
	var m0 := r.money
	r.use_instant("grant")
	check(r.money == m0 + 5, "grant +$5")
	r.use_instant("overcharge")
	check(r.shot_ctx(0.5, _sim(), false).overcharge, "overcharge reaches the scorer")
	check(score(h5, {"overcharge": true}).chips == 30, "overcharge x2 chips")
	check(score(h5, {"called": 0}).mult == 3 and score(h5, {"called": 2}).mult == 1, "call shot x3 only on the called pocket")
	r.called_pocket = 3
	r.apply_shot(hit(), false, 5, true)
	check(r.called_pocket == -1 and not r.overcharge, "one-shot effects clear after the shot")
	r = fresh()
	var s0 := r.pocket_scale()
	r.use_instant("wideopen")
	check(is_equal_approx(r.pocket_scale(), s0 * 1.25), "wide open widens pockets")
	var o := r.apply_shot(hit(), false, 5, true)
	check(o.has("layout_changed") and is_equal_approx(r.pocket_scale(), s0), "wide open lasts one shot")
	r = fresh()
	var s := _sim()
	r.use_instant("magnetize")
	r.apply_physics(s)
	check(s.pocket_pull > 0.0, "magnetize pulls")
	r.apply_shot(hit(), false, 5, true)
	r.apply_physics(s)
	check(s.pocket_pull == 0.0, "magnetize ends and physics reset")
	r = fresh()
	var old := r.bounty
	r.bounty_done = true
	r.use_instant("contract")
	check(r.bounty != old and not r.bounty_done and r.bounty_mult == 2, "contract swaps and doubles")
	var sc := _sim()
	var before := sc.pos.duplicate()
	r.scatter(sc)
	var moved := false
	var clear := true
	for i in range(1, sc.count()):
		moved = moved or sc.pos[i] != before[i]
		clear = clear and sc.is_clear_spot(sc.pos[i], i)
	check(moved and clear and sc.pos[0] == before[0], "scatter moves object balls to clear spots only")
	print("isotopes")
	check(score(h5, {"isotopes": {5: "radium"}}).mult == 11, "radium +10")
	check(score(h5, {"isotopes": {5: "radium"}, "radium": {"5": 2}}).mult == 7, "radium decays")
	check(score(h5, {"isotopes": {5: "radium"}, "radium": {"5": 40}}).mult == 3, "radium floor +2")
	var pr := score(h5, {"isotopes": {5: "prismatic"}})
	check(pr.chips == 35 and pr.mult == 3, "prismatic")
	check(score(h5, {"isotopes": {5: "resonant"}}).chips == 30, "resonant doubles the ball's chips")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var lucky := 0
	for i in 3000:
		if score(h5, {"isotopes": {5: "lucky"}, "rng": rng}).mult == 3:
			lucky += 1
	check(lucky > 850 and lucky < 1150, "lucky fires about 1 in 3 (%d/3000)" % lucky)
	var rd := fresh()
	rd.apply_shot(hit([5], 20, {"radium_used": [5]}), false, 5, true)
	check(int(rd.radium["5"]) == 1, "radium decay persists through the run")
	print("bounties")
	var cases := {
		"big300": hit([1], 300), "big600": hit([1], 600), "quad": hit([1, 2, 3, 4]), "stripe": hit([11]), "solid": hit([3]),
		"soft": hit([1], 20, {"power": 0.3}), "hard": hit([1], 20, {"power": 0.9}), "breakpot": hit([1], 20, {"is_break": true}),
		"mult10": hit([1], 20, {"mult": 12.0}), "chips100": hit([1], 20, {"chips": 140.0}),
		"bank2": hit([1], 20, {"lines": [{"label": "Bank ×2", "kind": "mult", "pocket": 0}]}),
		"corner": hit([1], 20, {"lines": [{"label": "1-ball", "kind": "chips", "pocket": 2}]}),
		"hot2": hit([1, 2], 20, {"lines": [{"label": "Hot pocket", "kind": "xmult", "pocket": 0}, {"label": "Hot pocket", "kind": "xmult", "pocket": 0}]}),
	}
	for id in cases:
		var b := fresh()
		b.bounty = id
		check(b.bounty_met(cases[id], -1), "bounty %s triggers" % id)
		var nope := fresh()
		nope.bounty = id
		check(not nope.bounty_met(hit([8], 10, {"power": 0.5}), -1), "bounty %s stays off for a plain pot" % id)
	var st := fresh()
	st.bounty = "streak6"
	st.streak = 5
	check(st.bounty_met(hit(), -1), "streak bounty counts this shot")
	var gold := fresh("fog")
	gold.bounty = "solid"
	var plain := fresh()
	plain.bounty = "solid"
	check(gold.bounty_reward() == plain.bounty_reward() * 2, "boss tables pay gold bounties")
	print("labs")
	check(score(h5, {"lab": "current"}).mult == 3, "the current +2 mult")
	check(score(h5, {"lab": "magnetlab"}).chips == 10, "magnet lab -5 chips")
	check(score(h5, {"lab": "dense"}).chips == 30, "neutron cloth +15 chips")
	check(score([{"type": "ball", "a": 0, "b": 5}, {"type": "bumper", "a": 5}, pot(5, 0)], {"lab": "pinball"}).chips == 21, "pinball +6 per bumper")
	check(score([{"type": "ball", "a": 0, "b": 5}, pot(5, 0, 1)], {"lab": "repulsor"}).mult == 3, "repulsor banks +1 extra")
	var pb := fresh("", "pinball")
	check(pb.build_layout().bumpers.size() == 4, "pinball has four bumpers")
	for lab in Catalog.LABS:
		var l := fresh("", lab)
		var ps := PoolSim.new(l.build_layout())
		ps.add_ball(0, Rack.HEAD)
		var rr := RandomNumberGenerator.new()
		rr.seed = 3
		Rack.build(ps, "fifteen", rr)
		l.apply_physics(ps)
		var clear_rack := true
		for i in ps.count():
			for bp in ps.layout.bumpers:
				clear_rack = clear_rack and ps.pos[i].distance_to(bp.pos) > bp.r + TableLayout.R
		check(clear_rack, "%s: no bumper overlaps the rack" % lab)
		ps.strike((Rack.FOOT - Rack.HEAD).normalized(), 2250.0, 0.0, 0.0)
		ps.settle()
		check(not ps.moving(), "%s: a full break settles (%.1fs)" % [lab, ps.time])
	var twice := fresh("", "dense")
	twice.formulas.assign(["velvet"])
	var t1 := _sim()
	twice.apply_physics(t1)
	var d1 := t1.roll_decel
	twice.apply_physics(t1)
	check(t1.roll_decel == d1, "re-applying physics never compounds")
	print("cues and milestones")
	for id in Catalog.CUES:
		var cr := RunState.new()
		cr.start(4, id)
		cr.begin_table()
		for f in cr.formulas:
			check(Catalog.FORMULAS.has(f), "%s starts with a real formula" % id)
		check(cr.chalk >= 4, "%s has playable chalk" % id)
	var m := Meta.new()
	for id in Catalog.CUES:
		if id != "maple":
			check(m.cue_hint(id) != "", "%s has an unlock route" % id)
	check(not m.cue_unlocked("banker"), "banker starts locked")
	var mr := fresh()
	mr.money = 31
	check(m.on_shot(hit(), mr).has("rich"), "holding $30 unlocks the Banker's Cue")
	for i in 10:
		m.on_shot(hit([1], 20, {"lines": [{"label": "Bank ×1"}]}), fresh())
	check(m.cue_unlocked("angle"), "10 banks unlocks the Angle Cue")
	for lab in Catalog.LABS:
		check(Catalog.LAB_ART.has(lab), "%s has table art" % lab)
	for mood in Catalog.LABS.keys() + ["title", "boss", "shop", "endless", "victory"]:
		check(ResourceLoader.exists("res://assets/music/%s.mp3" % Sfx.TRACKS.get(mood, "missing")), "%s has its music" % mood)
	print("stakes")
	var sk := []
	for lvl in Catalog.STAKES.size():
		var q := RunState.new()
		q.start(77, "maple", lvl)
		q.begin_table()
		q.roll_shop()
		sk.append({"t": q.target(), "c": q.chalk, "p": q.pocket_scale(), "cost": q.shop[0].cost})
	check(sk[1].t > sk[0].t and sk[1].c == sk[0].c, "stake 1 raises targets only")
	check(sk[2].c == sk[1].c - 1, "stake 2 removes a chalk")
	check(sk[3].cost == sk[2].cost + 1, "stake 3 raises prices")
	check(sk[4].p < sk[3].p, "stake 4 narrows pockets")
	check(sk[5].t > sk[4].t, "stake 5 raises targets again")
	var rl := RunState.new()
	rl.start(77, "maple", 3)
	rl.roll_shop()
	var costs: Array = rl.shop.map(func(x): return x.cost)
	rl.money = 100
	var kept: Array = rl.shop.filter(func(x): return x.type != "formula").map(func(x): return x.cost)
	rl.reroll()
	check(rl.shop.filter(func(x): return x.type != "formula").map(func(x): return x.cost) == kept, "rerolling never double-charges kept offers")
	var fm := RunState.new()
	fm.start(1)
	fm.roll_shop()
	var fid: String = fm.shop[0].id
	var base: int = fm.shop[0].cost
	var fs3 := RunState.new()
	fs3.start(1, "maple", 3)
	fs3.roll_shop()
	check(fs3.shop[0].id == fid and fs3.shop[0].cost == base + 1, "stake price applies once")
	var mw := Meta.new()
	check(mw.max_stake == 0, "starts at stake 0")
	mw.on_win(0)
	check(mw.max_stake == 1, "a win opens the next stake")
	mw.on_win(0)
	check(mw.max_stake == 1, "winning a lower stake does not skip ahead")
	for i in 10:
		mw.on_win(mw.max_stake)
	check(mw.max_stake == Catalog.STAKES.size() - 1, "ladder stops at the top")
	print("endless")
	var en := RunState.new()
	en.start(9)
	en.table_index = en.plan.size() - 1
	var last := en.target()
	en.advance_table()
	var tgs := [en.target()]
	var cur1: Dictionary = en.current()
	check(en.endless and tgs[0] > last and not cur1.boss, "endless starts harder than the final table")
	en.advance_table()
	check(en.current().boss and en.current().anomaly != "", "every second endless table is a boss")
	check(en.target() > tgs[0], "targets keep climbing")
	var c_now := en.max_chalk()
	en.table_index += 8
	check(en.max_chalk() < c_now and en.max_chalk() >= 2, "endless wears chalk down to a floor of 2 (%d)" % en.max_chalk())
	for i in 30:
		en.advance_table()
		en.begin_table()
		check(Catalog.LABS.has(en.current().lab), "endless table %d valid" % i) if not Catalog.LABS.has(en.current().lab) else null
	print("content tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)


func _sim() -> PoolSim:
	var s := PoolSim.new(TableLayout.new().build())
	s.add_ball(0, Vector2(250, 250))
	s.add_ball(1, Vector2(500, 200))
	s.add_ball(2, Vector2(700, 300))
	return s
