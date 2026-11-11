extends SceneTree
## Your ball set: removing balls (never the 8), special ball types with their own
## rules and looks, the new Imbues, and the Perks built on them.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func pot(n: int, k: int = 0, at: Vector2 = Vector2.ZERO) -> Dictionary:
	return {"type": "pocket", "a": n, "pocket": k, "rails": 0, "at": at}


func hit(a: int, b: int) -> Dictionary:
	return {"type": "ball", "a": a, "b": b}


func score(events: Array, extra: Dictionary = {}) -> Dictionary:
	var c := {"perks": [], "imbues": {}, "hot_pocket": -1, "boss": "local", "lab": "standard", "anomaly": "", "heat": 0,
		"power": 0.5, "shots_taken": 0, "events": events, "target": 1000, "objects": 10}
	c.merge(extra, true)
	return Scorer.score(c)


func _sim(layout: TableLayout, balls: Array) -> PoolSim:
	var s := PoolSim.new(layout)
	for b in balls:
		var i := s.add_ball(b[0], b[1])
		s.vel[i] = b[2]
	return s


func _initialize() -> void:
	print("content")
	check(Catalog.BALL_TYPES.size() >= 24, "24 special ball types (%d)" % Catalog.BALL_TYPES.size())
	check(Catalog.IMBUES.size() >= 16, "16 Imbues (%d)" % Catalog.IMBUES.size())
	check(Catalog.PERKS.size() >= 96, "96 Perks before the pause set (%d)" % Catalog.PERKS.size())
	var looks := {}
	for id in Catalog.BALL_TYPES:
		var bt: Dictionary = Catalog.BALL_TYPES[id]
		var look := "%s|%s|%d|%s" % [bt.color, bt.accent, bt.pattern, bt.motif]
		check(not looks.has(look), "%s looks unique" % id)
		looks[look] = true
		check(bt.motif != "" and int(bt.pattern) >= 0 and int(bt.pattern) <= 9, "%s has an emblem and finish" % id)
	var iso_cols := {}
	for id in Catalog.IMBUES:
		check(not iso_cols.has(Catalog.IMBUES[id].color), "%s Imbue has its own colour" % id)
		iso_cols[Catalog.IMBUES[id].color] = true

	print("the ball set")
	var run := RunState.new()
	run.start(4)
	check(run.ball_set == range(1, 16), "a run starts with balls 1-15")
	run.money = 20
	check(not run.remove_ball(8), "the 8 can never be removed")
	check(run.buy_removal(3) == "" and not run.ball_set.has(3) and run.money == 17, "removing a ball costs $3")
	check(run.removal_cost() == 4, "each removal costs $1 more")
	run.perks.assign(["cleanhouse"])
	check(run.removal_cost() == 0, "Clean House makes it free")
	var g := run.add_special("gold")
	check(g == 16 and run.ball_set.has(16) and Catalog.kind_of(16) == "gold", "a special ball joins the set as 16")
	check(Catalog.ball_points(16) == 45 and Catalog.ball_label(16) == "Gold ball", "special balls have their own value and name")
	check(not Catalog.is_stripe(16) and not Catalog.is_solid(16), "special balls are neither solids nor stripes")
	var saved: Dictionary = run.to_dict()
	check(saved.ball_kinds.has("16") and (saved.ball_set as Array).has(16), "special balls are saved with the run")
	run.shop = [{"type": "ball", "id": "star", "cost": 5, "sold": false}]
	run.money = 10
	check(run.buy(0) == "" and run.ball_kinds.values().has("star"), "a special ball can be bought")
	var alch := RunState.new()
	alch.start(6, "alchemist")
	check(alch.ball_kinds.values() == ["gold"] and alch.perks.has("goldrush"), "the Alchemist's Cue starts with a Gold ball")

	print("special balls score")
	Catalog.kinds = {16: "gold", 17: "void", 18: "echo", 19: "star", 20: "moon", 21: "wild", 22: "eraser", 23: "dice", 24: "ember", 25: "clover", 26: "heart"}
	Catalog.faces = {21: 7, 23: 12}
	var gp := pot(16)
	gp["rails"] = 2
	var r := score([hit(0, 16), gp])
	check(r.total == 45 and r.money == 2, "Gold pays $1 for each cushion it touched")
	check(score([hit(0, 17), pot(17), pot(5, 2)]).total == 60, "Void doubles the rest of the shot")
	check(score([hit(0, 18), pot(18)]).total == 30, "Echo pays once; it comes back instead")
	check(score([hit(0, 19), pot(19)]).total == 60, "Star adds Chain")
	check(score([hit(0, 20), pot(20, 1)]).total == 70, "Moon pays ×2 in a side pocket")
	check(score([hit(0, 21), pot(21)], {"perks": ["odd"]}).total == 49, "Wild counts as the number it copied (7, odd)")
	check(score([hit(0, 23), pot(23)]).total == 34, "Dice is worth 10 plus twice the number it shows")
	r = score([hit(0, 5), hit(5, 22), pot(22)])
	check(r.money == 4 and (r.lost_balls as Array).has(22) and (r.lost_balls as Array).has(5), "Eraser takes itself and the last ball it touched out of the set")
	check(not (score([hit(0, 8), hit(8, 22), pot(22)]).lost_balls as Array).has(8), "but never the 8")
	check(score([hit(0, 24), pot(24, 3)]).new_hot == 3, "Ember makes its pocket the hot pocket")
	r = score([hit(0, 25)])
	check(not r.scored and r.safe, "a shot Clover is part of cannot cost Chalk")
	check(score([hit(0, 26), pot(26)], {"objects": 1}).heart and not score([hit(0, 26), pot(26)]).heart, "Heart gives Chalk only as the last ball")
	check(score([hit(0, 16), gp], {"perks": ["goldrush"]}).total == 90, "Gold Rush doubles special balls")
	check(score([hit(0, 5), pot(5)], {"perks": ["menagerie"], "specials": 4}).total == 40, "Menagerie: Chain per special ball")
	check(score([hit(0, 5), pot(5), pot(3, 2)], {"imbues": {5: "starry"}}).total == 52, "Starry lifts the balls after it")
	check(score([hit(0, 5), pot(5)], {"imbues": {5: "prismatic"}}).total == 25, "Resonant adds Chain for each ball it touches")
	check(score([hit(0, 5), pot(5)], {"imbues": {5: "bounty"}, "heat": 3}).money == 3, "Bounty pays $1 per Heat")
	check(score([hit(0, 5), {"type": "rail", "a": 5}, pot(5)], {"imbues": {5: "charged"}}).total == 30, "Charged adds Chain off cushions")
	Catalog.faces = {}

	print("special balls in the physics")
	var phys := RunState.new()
	phys.start(2)
	phys.begin_table()
	Catalog.kinds = {16: "anchor", 17: "magnet", 18: "glass", 19: "frost", 20: "moon", 21: "comet", 22: "star"}
	var lay := phys.build_layout()
	var a1 := _sim(lay, [[5, Vector2(300, 250), Vector2(500, 0)], [16, Vector2(380, 250), Vector2.ZERO]])
	a1.settle()
	check(a1.pos[1].distance_to(Vector2(380, 250)) < 0.01, "Anchor does not move when another ball hits it")
	var a2 := _sim(lay, [[0, Vector2(300, 250), Vector2(500, 0)], [16, Vector2(380, 250), Vector2.ZERO]])
	a2.settle()
	check(a2.pos[1].distance_to(Vector2(380, 250)) > 5.0, "but the cue ball can move it")
	var mg := _sim(lay, [[5, Vector2(250, 300), Vector2(400, 0)], [17, Vector2(500, 210), Vector2.ZERO]])
	var plain := _sim(lay, [[5, Vector2(250, 300), Vector2(400, 0)], [3, Vector2(500, 210), Vector2.ZERO]])
	for k in 180:
		mg.step(PoolSim.STEP)
		plain.step(PoolSim.STEP)
	check(mg.pos[0].y < plain.pos[0].y - 3.0, "Magnet pulls a passing ball towards itself")
	var gl := _sim(lay, [[0, Vector2(300, 250), Vector2(1600, 0)], [18, Vector2(360, 250), Vector2.ZERO]])
	gl.settle()
	check(gl.alive[1] == 0 and gl.events.any(func(e): return e.type == "shatter"), "Glass shatters when hit hard")
	var gs := _sim(lay, [[0, Vector2(300, 250), Vector2(300, 0)], [18, Vector2(360, 250), Vector2.ZERO]])
	gs.settle()
	check(not gs.events.any(func(e): return e.type == "shatter"), "but survives a gentle touch")
	var fr := _sim(lay, [[0, Vector2(300, 250), Vector2(600, 0)], [19, Vector2(360, 250), Vector2.ZERO]])
	fr.settle()
	check(fr.pos[0].x < 340.0, "a ball that touches Frost stops dead")
	var pk: Vector2 = lay.pockets[0].pos
	var into := (pk - Vector2(500, 250)).normalized()
	var mo := _sim(lay, [[20, pk - into * 60.0, into * 400.0]])
	mo.settle()
	check(mo.alive[0] == 1, "a corner pocket rejects the Moon")
	var co := _sim(lay, [[21, Vector2(200, 250), Vector2(0, 160)]])
	var nb := _sim(lay, [[4, Vector2(200, 250), Vector2(0, 160)]])
	co.settle()
	nb.settle()
	check(co.pos[0].distance_to(Vector2(200, 250)) > nb.pos[0].distance_to(Vector2(200, 250)) + 40.0, "Comet glides with no cloth friction until a cushion")
	var st := _sim(lay, [[22, Vector2(300, 120), Vector2(0, -500)]])
	phys.apply_physics(st)
	var fl := _sim(lay, [[4, Vector2(300, 120), Vector2(0, -500)]])
	phys.apply_physics(fl)
	for k in 120:
		st.step(PoolSim.STEP)
		fl.step(PoolSim.STEP)
	check(st.vel[0].length() > fl.vel[0].length() + 20.0, "Star comes off a cushion faster")
	var ec := RunState.new()
	ec.start(3)
	ec.begin_table()
	Catalog.kinds = {16: "echo"}
	var es := _sim(lay, [[16, Vector2(80, 80), Vector2.ZERO]])
	es.alive[0] = 0
	check(ec.respot_echo({"potted": [16]}, es) == [16] and es.alive[0] == 1, "Echo comes back to the foot spot")
	es.alive[0] = 0
	check(ec.respot_echo({"potted": [16]}, es).is_empty(), "but only once a table")
	Catalog.kinds = {}
	print("balls tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
