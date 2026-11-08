extends SceneTree
## Balance bot: plays complete runs headless using the real sim, scorer and
## RunState rules, with Gaussian aim error to model a human.
## Godot --headless --path . --script res://tools/bot.gd -- <runs> <aim_sigma_deg> [seed0] [shop 0/1]

var aim_sigma := 0.8
var rng := RandomNumberGenerator.new()
var shop_on := true


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var runs := int(a[0]) if a.size() > 0 else 4
	aim_sigma = float(a[1]) if a.size() > 1 else 0.8
	var seed0 := int(a[2]) if a.size() > 2 else 1
	shop_on = (a[3] != "0") if a.size() > 3 else true
	var reached := {}
	var t0 := Time.get_ticks_msec()
	for r in runs:
		var res := play_run(seed0 + r)
		reached[res] = reached.get(res, 0) + 1
	var keys := reached.keys()
	keys.sort()
	print("BOT sigma=%.2f shop=%s runs=%d  tables cleared histogram: %s  (%d s)" % [aim_sigma, shop_on, runs, str(keys.map(func(k): return "%d:%d" % [k, reached[k]])), (Time.get_ticks_msec() - t0) / 1000])
	quit()


func play_run(s: int) -> int:
	rng.seed = s * 7919
	var run := RunState.new()
	run.start(s)
	var line := "run %d:" % s
	while true:
		run.begin_table()
		var t := run.current()
		var r := play_table(run)
		line += " T%d[%s/%s %d/%d sh%d]" % [run.table_index + 1, t.lab.substr(0, 4), t.anomaly.substr(0, 4), run.score, run.target(), run.shots_taken]
		if not r:
			print(line, "  perks=", run.perks)
			return run.table_index
		run.payout()
		if run.table_index >= run.plan.size() - 1:
			print(line, "  WIN perks=", run.perks)
			return run.plan.size()
		if shop_on:
			shop(run)
		run.advance_table()
	return 0


func shop(run: RunState) -> void:
	run.roll_shop()
	var pref := ["golden", "supernova", "streak", "heat", "multi", "catalyst", "bank", "fusion", "prime", "stripes", "even", "chalk", "jaws", "solids", "odd", "corner", "elastic", "entropy", "side", "insurance", "chain"]
	for loop in 3:
		var bought := false
		for p in pref:
			for i in run.shop.size():
				var it: Dictionary = run.shop[i]
				if it.type == "perk" and it.id == p and not it.sold and run.money >= it.cost and run.perks.size() < 5:
					run.buy(i)
					bought = true
		for i in run.shop.size():
			var it: Dictionary = run.shop[i]
			if it.type == "imbue" and not it.sold and run.money >= it.cost + 4 and it.id in ["neon", "heavy"]:
				run.buy(i)
		if not bought and run.money >= run.reroll_cost + 7 and run.perks.size() < 5:
			run.reroll()
		else:
			break


func make_sim(run: RunState, layout: TableLayout) -> PoolSim:
	var s := PoolSim.new(layout)
	match run.current().lab:
		"cryo":
			s.roll_decel = 90.0
			s.drag = 0.05
		"spring":
			s.rail_e = 0.92
		"gravity":
			s.well_pos = Vector2(TableLayout.W * 0.5, TableLayout.H * 0.5)
			s.well_strength = 1.0
	if run.perks.has("magnet"):
		s.pocket_pull = 1.0
	return s


func new_rack(run: RunState, layout: TableLayout) -> PoolSim:
	var s := make_sim(run, layout)
	s.add_ball(0, Rack.HEAD)
	var r := RandomNumberGenerator.new()
	r.seed = run.rng.randi()
	Rack.build(s, run.current().rack, r)
	if run.current().anomaly == "lead":
		for i in s.count():
			if s.num[i] != 0:
				s.mass[i] = 1.6
	return s


func speed(p: float) -> float:
	return AutoPlayer.speed(p)


func ctx_for(run: RunState, pw: float) -> Dictionary:
	return AutoPlayer.ctx_for(run, pw)


func candidates(sim: PoolSim, run: RunState) -> Array:
	return AutoPlayer.candidates(sim, run)


func choose(sim: PoolSim, run: RunState) -> Dictionary:
	return AutoPlayer.choose(sim, run)


func place_cue(sim: PoolSim, run: RunState) -> void:
	var p := AutoPlayer.place_spot(sim, run, rng)
	sim.alive[0] = 1
	sim.pos[0] = p
	sim.vel[0] = Vector2.ZERO


func play_table(run: RunState) -> bool:
	var layout := TableLayout.new().build(run.pocket_scale(), run.closed_pockets())
	if run.current().lab == "cyclotron":
		layout.add_bumper(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.27), 20.0)
		layout.add_bumper(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.73), 20.0)
	var sim := new_rack(run, layout)
	var is_break := true
	var guard := 0
	while guard < 200:
		guard += 1
		var shot := {}
		if is_break:
			shot = {"dir": (Rack.FOOT - sim.pos[0]).normalized(), "power": 1.0}
		else:
			if sim.alive[0] == 0:
				place_cue(sim, run)
			shot = choose(sim, run)
		var start := {}
		for i in sim.count():
			if sim.alive[i] == 1:
				start[sim.num[i]] = sim.pos[i]
		var noisy: Vector2 = shot.dir.rotated(deg_to_rad(rng.randfn(0.0, aim_sigma)))
		var pw: float = clampf(shot.power * (1.0 + rng.randfn(0.0, 0.05)), 0.05, 1.0)
		var ctx := ctx_for(run, pw)
		sim.strike(noisy, speed(pw), 0.0, 0.0)
		sim.settle()
		ctx["events"] = sim.events
		ctx["start_pos"] = start
		ctx["rng"] = run.rng
		var res := Scorer.score(ctx)
		if OS.has_environment("BOTDEBUG"):
			print("  shot brk=%s pw=%.2f foul=%s pots=%s total=%d chalk=%d" % [is_break, pw, res.foul, str(res.potted), res.total, run.chalk])
		var out := run.apply_shot(res, is_break, sim.object_balls_left(), sim.alive[0] == 1)
		is_break = false
		if out.cleared:
			return true
		if out.over:
			return false
		if out.rack_cleared:
			sim = new_rack(run, layout)
			is_break = true
	return false
