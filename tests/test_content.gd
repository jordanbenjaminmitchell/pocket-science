extends SceneTree
## New Reagents, Imbues, Bounties, Cues and Labs do what their text says.

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
	var c := {"perks": [], "imbues": {}, "hot_pocket": -1, "lab": "standard", "streak": 0, "power": 0.5, "events": events}
	c.merge(extra, true)
	return Scorer.score(c)


func fresh(anomaly: String = "", lab: String = "standard") -> RunState:
	var r := RunState.new()
	r.start(21)
	r.plan[0].anomaly = anomaly
	r.plan[0].boss = anomaly != ""
	r.plan[0].lab = lab
	r.plan[0].id = "frozen"
	r.begin_table()
	return r


func miss() -> Dictionary:
	return {"scored": false, "foul": "Miss", "total": 0, "money": 0, "catalyst_gain": 0.0, "potted": [], "shattered": [], "lines": []}


func hit(potted: Array = [1], total: int = 20, extra: Dictionary = {}) -> Dictionary:
	var d := {"scored": true, "foul": "", "total": total, "money": 0, "catalyst_gain": 0.0, "potted": potted, "shattered": [], "lines": [], "chain": 1.0, "banks": 0, "max_rails": 0, "combos": 0, "kick": false, "hot_pots": 0, "pocket_list": [], "power": 0.5}
	d.merge(extra, true)
	return d


func _go() -> void:
	create_timer(120.0).timeout.connect(func(): quit(2))
	var h5 := [{"type": "ball", "a": 0, "b": 5}, pot(5, 0)]
	print("counts")
	check(Catalog.IMBUES.size() >= 16, "16 imbues")
	check(Catalog.BOUNTIES.size() == 23, "23 side bets")
	check(Catalog.CUES.size() >= 13, "13 or more cues")
	check(["posts", "portals", "walls", "trapdoors", "gravity"].all(func(c): return Catalog.CUES.has(c) and Catalog.CUES[c].has("kit")), "an object cue for each placeable object")
	check(Catalog.BOSSES.size() >= 20, "at least 20 boss tables")
	for id in Catalog.BOSSES:
		check(Catalog.LABS.has(Catalog.BOSSES[id].lab), "%s uses a known lab" % id)
	print("imbues")
	check(score(h5, {"imbues": {5: "heavy"}}).total == 25, "Weighted: the number counts ×3 to start")
	check(score(h5, {"imbues": {5: "heavy"}, "imbue_level": {5: 5}}).total == 35, "and ×5 after two sinks")
	check(score(h5, {"imbues": {5: "gold"}}).money == 1, "Gilded pays $1")
	check(score(h5, {"imbues": {5: "gold"}, "imbue_level": {5: 3}}).money == 4, "plus $1 per table in a row")
	check(score(h5, {"imbues": {5: "twin"}}).total == 40, "twin doubles the value")
	check(score(h5, {"imbues": {5: "vein"}}).total == 40, "Vein adds +20")
	var vs2 := score([{"type": "ball", "a": 0, "b": 3}, {"type": "ball", "a": 3, "b": 5}, pot(5, 0)], {"imbues": {5: "vein"}})
	check((vs2.vein_spread as Array).has(3), "and spreads to the ball that knocked it in")
	var mir := score([{"type": "ball", "a": 0, "b": 15}, {"type": "ball", "a": 15, "b": 5}, pot(5, 0)], {"imbues": {5: "mirror"}})
	check(mir.total == 40, "Mirror pays what the ball that hit it is worth (%d)" % mir.total)
	check(score(h5, {"imbues": {5: "glass"}}).total == 60, "glass ×3")
	check(score(h5, {"imbues": {5: "ember"}}).heat_gain == 2, "Kindled adds 2 Heat")
	check(score([{"type": "ball", "a": 0, "b": 3}], {"imbues": {5: "ember"}, "on_table": [3, 5]}).kindled_live, "and a miss with it on the table is flagged")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var lucky := 0
	for i in 3000:
		if score(h5, {"imbues": {5: "lucky"}, "rng": rng}).total == 40:
			lucky += 1
	check(lucky > 1350 and lucky < 1650, "Lucky pays ×2 about 1 in 2 (%d/3000)" % lucky)
	var climbed := 0
	for i in 400:
		if score(h5, {"imbues": {5: "lucky"}, "lucky_mult": {5: 3}, "rng": rng}).total == 60:
			climbed += 1
	check(climbed > 150 and climbed < 250, "after misses it pays ×3 (%d/400)" % climbed)
	var jx := score(h5, {"imbues": {5: "jinxed"}})
	check(jx.total == 80 and jx.jinxed, "Jinxed pays ×4 and flags the Heat cost")
	var pw := score(h5, {"imbues": {5: "pawned"}})
	check(pw.total == 0 and pw.money == 4, "Pawned pays $4 instead of points")
	var boom := score([{"type": "ball", "a": 0, "b": 5}, {"type": "shatter", "a": 5, "at": Vector2.ZERO, "exploded": true}], {"imbues": {5: "volatile"}})
	check(boom.scored and boom.total == 20 and (boom.potted as Array).has(5) and (boom.lost_balls as Array).has(5), "an exploded Volatile ball counts as sunk and leaves the set")
	print("bounties")
	var cases := {
		"quarter": hit([1], 30), "half": hit([1], 30), "triple": hit([1, 2, 3]), "stripe": hit([11]), "solid": hit([3]),
		"soft": hit([1], 20, {"power": 0.3}), "hard": hit([1], 20, {"power": 0.9}), "breakpot": hit([1], 20, {"is_break": true}),
		"chain5": hit([1], 20, {"chain": 6.0}), "chain7": hit([1], 20, {"chain": 7.5}),
		"bank2": hit([1], 20, {"banks": 1, "max_rails": 2}),
		"corner": hit([1], 20, {"pocket_list": [2]}),
		"hot2": hit([1, 2], 20, {"hot_pots": 2}),
	}
	for id in cases:
		var b := fresh()
		b.bounty = id
		check(b.bounty_met(cases[id], -1), "bounty %s triggers" % id)
		var nope := fresh()
		nope.bounty = id
		check(not nope.bounty_met(hit([8], 5, {"power": 0.5}), -1), "bounty %s stays off for a plain pot" % id)
	var st := fresh()
	st.bounty = "heat5"
	st.heat = 4
	check(st.bounty_met(hit(), -1), "streak bounty counts this shot")
	print("labs")
	var pb := fresh("", "pinball")
	check(pb.build_layout().bumpers.size() == 4, "pinball has four bumpers")
	for lab in Catalog.LABS:
		var l := fresh("", lab)
		var ps := PoolSim.new(l.build_layout())
		ps.add_ball(0, Rack.HEAD)
		var rr := RandomNumberGenerator.new()
		rr.seed = 3
		Rack.build(ps, rr)
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
	twice.perks.assign(["velvet"])
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
		for f in cr.perks:
			check(Catalog.PERKS.has(f), "%s starts with a real perk" % id)
		check(cr.chalk >= 4, "%s has playable chalk" % id)
	var m := Meta.new()
	for id in Catalog.CUES:
		if id != "maple":
			check(m.cue_hint(id) != "", "%s has an unlock route" % id)
	check(not m.cue_unlocked("portals"), "the Portal Cue starts locked")
	var mr := fresh()
	mr.money = 31
	check(m.on_shot(hit(), mr).has("rich"), "holding $30 unlocks the Banker's Cue")
	for i in 10:
		m.on_shot(hit([1], 20, {"banks": 1}), fresh())
	check(m.cue_unlocked("angle"), "10 banks unlocks the Angle Cue")
	for lab in Catalog.LABS:
		check(Catalog.LAB_ART.has(lab), "%s has table art" % lab)
	var board_tracks := {}
	for mood in Catalog.BOSSES.keys() + ["title", "shop", "endless", "victory"]:
		check(ResourceLoader.exists("res://assets/music/%s" % Sfx.TRACKS.get(mood, "missing")), "%s has its music" % mood)
		if Catalog.BOSSES.has(mood):
			board_tracks[Sfx.TRACKS.get(mood, "")] = true
	check(board_tracks.size() == Catalog.BOSSES.size(), "every table has its own soundtrack")
	print("stakes")
	var sk := []
	for lvl in Catalog.HANDICAPS.size():
		var q := RunState.new()
		q.start(77, "maple", lvl)
		q.begin_table()
		q.roll_shop()
		sk.append({"t": q.target(), "c": q.chalk, "p": q.pocket_scale(), "cost": q.shop[0].cost})
	check(sk[1].t > sk[0].t and sk[1].c == sk[0].c, "handicap 1 raises targets only")
	check(sk[2].c == sk[1].c - 1, "handicap 2 removes a chalk")
	check(sk[3].cost == sk[2].cost + 1, "handicap 3 raises prices")
	check(sk[4].p < sk[3].p, "handicap 4 narrows pockets")
	check(sk[5].t > sk[4].t, "handicap 5 raises targets again")
	var rl := RunState.new()
	rl.start(77, "maple", 3)
	rl.roll_shop()
	var costs: Array = rl.shop.map(func(x): return x.cost)
	rl.money = 100
	var kept: Array = rl.shop.filter(func(x): return x.type != "perk").map(func(x): return x.cost)
	rl.reroll()
	check(rl.shop.filter(func(x): return x.type != "perk").map(func(x): return x.cost) == kept, "rerolling never double-charges kept offers")
	var fm := RunState.new()
	fm.start(1)
	fm.roll_shop()
	var fid: String = fm.shop[0].id
	var base: int = fm.shop[0].cost
	var fs3 := RunState.new()
	fs3.start(1, "maple", 3)
	fs3.roll_shop()
	check(fs3.shop[0].id == fid and fs3.shop[0].cost == base + 1, "handicap price applies once")
	var mw := Meta.new()
	check(mw.max_handicap == 0, "starts at handicap 0")
	mw.on_win(0)
	check(mw.max_handicap == 1, "a win opens the next handicap")
	mw.on_win(0)
	check(mw.max_handicap == 1, "winning a lower handicap does not skip ahead")
	for i in 10:
		mw.on_win(mw.max_handicap)
	check(mw.max_handicap == Catalog.HANDICAPS.size() - 1, "ladder stops at the top")
	print("endless")
	var en := RunState.new()
	en.start(9)
	en.table_index = en.plan.size() - 1
	var last := en.target()
	en.advance_table()
	var tgs := [en.target()]
	var cur1: Dictionary = en.current()
	check(en.endless and tgs[0] > last and Catalog.BOSSES.has(cur1.id), "endless starts harder than the final table")
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
