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
	check(Catalog.ball_points(16) == 30 and Catalog.ball_label(16) == "Gold ball", "special balls have their own value and name")
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
	Catalog.kinds = {16: "gold", 17: "void", 18: "echo", 19: "star", 20: "moon", 21: "wild", 22: "eraser", 23: "dice"}
	var r := score([hit(0, 16), pot(16)])
	check(r.total == 30 and r.money == 2, "Gold: worth 30, pays $2")
	r = score([hit(0, 17), pot(17), pot(5, 2)])
	check(r.total == 45, "Void doubles the rest of the shot (%d)" % r.total)
	check(score([hit(0, 18), pot(18)]).total == 40, "Echo pays twice")
	check(score([hit(0, 19), pot(19)]).total == 40, "Star adds Chain")
	check(score([hit(0, 20), pot(20, 1)]).total == 48 and score([hit(0, 20), pot(20, 0)]).total == 24, "Moon pays ×2 in a side pocket only")
	check(score([hit(0, 21), pot(21)], {"perks": ["odd"]}).total == 35, "Wild counts as odd")
	r = score([hit(0, 22), pot(22)])
	check(r.money == 4 and (r.lost_balls as Array).has(22), "Eraser pays $4 and leaves the set")
	check(score([hit(0, 23), pot(23)]).total == 35, "Dice previews at its average")
	check(score([hit(0, 16), pot(16)], {"perks": ["goldrush"]}).total == 60, "Gold Rush doubles special balls")
	check(score([hit(0, 5), pot(5)], {"perks": ["menagerie"], "specials": 4}).total == 30, "Menagerie: Chain per special ball")
	check(score([hit(0, 5), pot(5)], {"imbues": {5: "starry"}}).total == 15 and score([hit(0, 5), pot(5), pot(3, 2)], {"imbues": {5: "starry"}}).total == 41, "Starry lifts the balls after it")
	check(score([hit(0, 5), pot(5)], {"imbues": {5: "prismatic"}, "perks": ["stripes"]}).total == 22, "Prismatic counts as a stripe")
	check(score([hit(0, 5), pot(5)], {"imbues": {5: "bounty"}, "heat": 3}).money == 3, "Bounty pays $1 per Heat")
	check(score([hit(0, 5), {"type": "rail", "a": 5}, pot(5)], {"imbues": {5: "charged"}}).total == 22, "Charged adds Chain off cushions")

	print("special balls in the physics")
	var phys := RunState.new()
	phys.start(2)
	phys.begin_table()
	Catalog.kinds = {16: "bomb", 17: "anchor", 18: "magnet"}
	var s := PoolSim.new(phys.build_layout())
	s.add_ball(0, Vector2(100, 250))
	s.add_ball(17, Vector2(300, 250))
	s.add_ball(18, Vector2(400, 250))
	phys.apply_physics(s)
	check(is_equal_approx(s.mass[1], 3.0) and s.pull[2] == 1.0, "Anchor is heavy and Magnet is pulled to pockets")
	var bs := PoolSim.new(phys.build_layout())
	bs.add_ball(0, Vector2(500, 250))
	var bomb := bs.add_ball(16, Vector2(60, 60))
	var near := bs.add_ball(5, Vector2(110, 60))
	bs.add_ball(8, Vector2(90, 95))
	bs.vel[bomb] = Vector2(-200, -200)
	bs.settle()
	check(bs.alive[bomb] == 0 and bs.alive[near] == 0, "a Bomb takes the nearest ball down with it")
	check(bs.alive[3] == 1, "but never the 8")
	Catalog.kinds = {}
	print("balls tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
