extends SceneTree
## Headless physics checks: python-free, run with
## Godot_console --headless --path . --script res://tests/test_sim.gd

var failures := 0


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok  ", msg)
	else:
		failures += 1
		print("  FAIL ", msg)


func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	_test_straight_pot()
	_test_guideline_matches()
	_test_break()
	_test_rail()
	_test_boss_physics()
	print("sim tests: %d failures (%d ms)" % [failures, Time.get_ticks_msec() - t0])
	quit(1 if failures > 0 else 0)


func _sim() -> PoolSim:
	return PoolSim.new(TableLayout.new().build())


func _test_straight_pot() -> void:
	print("straight pot into top-right corner")
	var s := _sim()
	s.add_ball(0, Vector2(600, 250))
	var target := Vector2(850, 125)
	var pocket: Vector2 = s.layout.pockets[2].pos
	var dir := (pocket - target).normalized()
	s.add_ball(5, target)
	var ghost := target - dir * TableLayout.R * 2.0
	s.strike((ghost - s.pos[0]).normalized(), 1400.0, 0.0, 0.0)
	var ev := s.settle()
	var potted := ev.filter(func(e): return e.type == "pocket" and e.a == 5)
	check(potted.size() == 1, "5-ball potted")
	check(potted.size() == 1 and potted[0].pocket == 2, "into pocket 2")
	check(s.alive[0] == 1, "cue ball stays up")


func _test_guideline_matches() -> void:
	print("guideline object direction equals simulated direction")
	var s := _sim()
	s.add_ball(0, Vector2(300, 300))
	s.add_ball(3, Vector2(560, 210))
	var dir := Vector2(1, -0.29).normalized()
	var hit := s.cast(s.pos[0], dir, 0)
	check(hit.kind == "ball", "cast finds the 3-ball")
	var predicted: Vector2 = hit.normal
	var s2 := s.clone()
	s2.frictionless = true
	s2.strike(dir, 900.0, 0.0, 0.0)
	var obj := s2.index_of(3)
	while s2.vel[obj] == Vector2.ZERO and s2.time < 3.0:
		s2.step(PoolSim.STEP)
	var actual := s2.vel[obj].normalized()
	check(actual.angle_to(predicted) < 0.002, "angle error %.5f rad" % absf(actual.angle_to(predicted)))


func _test_break() -> void:
	print("full 15-ball break settles cleanly")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var s := _sim()
	s.add_ball(0, Rack.HEAD)
	Rack.build(s, rng)
	s.strike(Vector2(1, 0.004), 2400.0, 0.0, 0.0)
	var t0 := Time.get_ticks_msec()
	s.settle()
	var ms := Time.get_ticks_msec() - t0
	check(not s.moving(), "settled after %.1fs sim in %d ms" % [s.time, ms])
	var overlaps := 0
	var outside := 0
	for i in s.count():
		if s.alive[i] == 0:
			continue
		var p := s.pos[i]
		if p.x < TableLayout.R - 0.5 or p.y < TableLayout.R - 0.5 or p.x > TableLayout.W - TableLayout.R + 0.5 or p.y > TableLayout.H - TableLayout.R + 0.5:
			outside += 1
		for j in range(i + 1, s.count()):
			if s.alive[j] == 1 and s.pos[i].distance_to(s.pos[j]) < TableLayout.R * 2.0 - 0.5:
				overlaps += 1
	check(overlaps == 0, "no overlapping balls (%d)" % overlaps)
	check(outside == 0, "no balls outside the cushions (%d)" % outside)
	var pots := s.events.filter(func(e): return e.type == "pocket").size()
	print("  break potted %d, events %d" % [pots, s.events.size()])
	# determinism
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 7
	var s2 := _sim()
	s2.add_ball(0, Rack.HEAD)
	Rack.build(s2, rng2)
	s2.strike(Vector2(1, 0.004), 2400.0, 0.0, 0.0)
	s2.settle()
	check(s2.pos == s.pos, "deterministic replay")


func _test_rail() -> void:
	print("cushion bounce and travel distance")
	var s := _sim()
	s.add_ball(0, Vector2(400, 250))
	s.strike(Vector2(0, 1), 600.0, 0.0, 0.0)
	s.settle()
	check(s.events.any(func(e): return e.type == "rail"), "hit bottom rail")
	var s2 := _sim()
	s2.add_ball(0, Vector2(30, 250))
	s2.strike(Vector2(1, 0), 1300.0, 0.0, 0.0)
	s2.settle()
	print("  1300 speed shot travelled with %d rails, ended at %s" % [s2.rails[0], s2.pos[0]])


func _run_with(anomaly: String, perks: Array) -> RunState:
	var r := RunState.new()
	r.start(5)
	r.plan[0].anomaly = anomaly
	r.perks.assign(perks)
	r.begin_table()
	return r


func _test_boss_physics() -> void:
	print("boss and Element physics")
	var r := _run_with("shrink", [])
	var s0 := r.pocket_scale()
	for i in 20:
		r.apply_shot({"scored": false, "foul": "Miss", "total": 0, "money": 0, "catalyst_gain": 0.0, "potted": [], "shattered": [], "lines": []}, false, 5, true)
		r.chalk = 4
	check(r.pocket_scale() < s0 and is_equal_approx(r.pocket_scale(), s0 * 0.75), "shrinking pockets bottom out at 75%% (%.3f)" % r.pocket_scale())
	var layout := r.build_layout()
	check(layout.pockets[0].r < TableLayout.new().build(s0).pockets[0].r, "shrunk layout has smaller pockets")
	# Heavy cue: on a full hit the heavier cue ball keeps rolling forward.
	for case in [["", 0.0], ["heavycue", 1.0]]:
		var rr := _run_with(case[0], [])
		var s := PoolSim.new(TableLayout.new().build())
		s.add_ball(0, Vector2(300, 250))
		s.add_ball(1, Vector2(500, 250))
		rr.apply_physics(s)
		s.frictionless = true
		s.strike(Vector2.RIGHT, 1000.0, 0.0, 0.0)
		while s.vel[1] == Vector2.ZERO:
			s.step(PoolSim.STEP)
		var forward := s.vel[0].x
		if case[0] == "":
			check(absf(forward) < 20.0, "normal cue ball stops dead on a full hit (%.0f)" % forward)
		else:
			check(forward > 200.0, "heavy cue ball follows through (%.0f)" % forward)
	# Stun Master: the cue keeps only 40% at first contact.
	var st := _run_with("", ["stun"])
	var s2 := PoolSim.new(TableLayout.new().build())
	s2.add_ball(0, Vector2(300, 250))
	s2.add_ball(1, Vector2(500, 280))
	st.apply_physics(s2)
	s2.frictionless = true
	s2.strike((Vector2(500, 280) - Vector2(300, 250)).normalized().rotated(0.05), 1000.0, 0.0, 0.0)
	var pre := 0.0
	while s2.vel[1] == Vector2.ZERO:
		pre = s2.vel[0].length()
		s2.step(PoolSim.STEP)
	var plain := PoolSim.new(TableLayout.new().build())
	plain.add_ball(0, Vector2(300, 250))
	plain.add_ball(1, Vector2(500, 280))
	plain.frictionless = true
	plain.strike((Vector2(500, 280) - Vector2(300, 250)).normalized().rotated(0.05), 1000.0, 0.0, 0.0)
	while plain.vel[1] == Vector2.ZERO:
		plain.step(PoolSim.STEP)
	check(is_equal_approx(snappedf(s2.vel[0].length() / plain.vel[0].length(), 0.01), 0.4), "stun master keeps 40%% of cue speed (%.2f)" % (s2.vel[0].length() / plain.vel[0].length()))
	# Featherweight, velvet, black ice, tilt.
	var fw := _run_with("", ["featherweight", "velvet"])
	var s3 := PoolSim.new(TableLayout.new().build())
	s3.add_ball(0, Vector2(300, 250))
	s3.add_ball(4, Vector2(500, 250))
	fw.apply_physics(s3)
	check(is_equal_approx(s3.mass[1], 0.7) and is_equal_approx(s3.mass[0], 1.0), "Hydrogen Balloon lightens object balls only")
	# The reworked Elements: physics instead of points.
	var rw := _run_with("", ["laststripe", "lever", "racing", "collector", "domino"])
	var rws4 := PoolSim.new(TableLayout.new().build())
	for n in [0, 8, 12, 3]:
		rws4.add_ball(n, Vector2(200 + 60 * rws4.count(), 250))
	rw.apply_physics(rws4)
	check(is_equal_approx(rws4.mass[1], 3.0), "Lead Anchor: the 8 is three times as heavy")
	check(is_equal_approx(rws4.mass[2], 1.4 * 0.7) and is_equal_approx(rws4.grip[2], 0.8), "Tungsten Core and Rubidium Rush both act on stripes")
	check(is_equal_approx(rws4.mass[3], 1.0) and is_equal_approx(rws4.grip[3], 1.0), "and leave solids alone")
	check(is_equal_approx(rws4.grip[0], 0.7), "Gallium Glide: the cue ball rolls further")
	check(is_equal_approx(rws4.ball_e, 1.0), "Dysprosium Domino: hits lose no speed")
	check(rws4.anchor8 and rws4._rejects(1, 0), "Lead Anchor: the 8 rattles out while other balls remain")
	check(is_equal_approx(rws4.rail_e_of(2), 1.0) and not is_equal_approx(rws4.rail_e_of(3), 1.0), "Tungsten Core: stripes lose no speed off cushions")
	var rwslick := PoolSim.new(TableLayout.new().build())
	rwslick.add_ball(0, Vector2(200, 250))
	rwslick.vel[0] = Vector2(400, 0)
	var rwd1 := rwslick.stop_distance(0)
	rwslick.grip[0] = 0.7
	check(rwslick.stop_distance(0) > rwd1 * 1.3, "less grip, a longer roll in the prediction too")
	# Neodymium Magnet, Lithium Cell, Polonium Halo, Uranium Reactor.
	var ph := _run_with("", ["elastic", "lowball", "lastcall", "power"])
	var s6 := PoolSim.new(TableLayout.new().build())
	s6.add_ball(0, Vector2(200, 250))
	s6.add_ball(2, Vector2(600, 100))
	s6.add_ball(8, Vector2(700, 300))
	ph.apply_physics(s6)
	check(s6.cue_magnet > 0.0, "Neodymium Magnet: the cue ball is magnetic")
	check(is_equal_approx(s6.rail_e_of(1), 1.0), "Lithium Cell: balls 1-3 lose no speed off cushions")
	check(s6.pull[2] == 0.0, "Polonium Halo: no pull while other balls remain")
	s6.alive[1] = 0
	ph.apply_physics(s6)
	check(s6.pull[2] > 0.0, "and the pockets pull the 8 when it is the last ball")
	check(is_equal_approx(ph.first_boost(0.9), 1.2) and is_equal_approx(ph.first_boost(0.6), 1.0), "Uranium Reactor: only full-power shots")
	# The magnet tugs a resting ball as the cue rolls past.
	var mg := PoolSim.new(TableLayout.new().build())
	mg.add_ball(0, Vector2(200, 250))
	mg.add_ball(5, Vector2(500, 310))
	mg.cue_magnet = 1.0
	mg.strike(Vector2.RIGHT, 900.0, 0.0, 0.0)
	for k in 120:
		mg.step(PoolSim.STEP)
	check(mg.pos[1].y < 310.0, "Neodymium Magnet pulls a resting ball towards the passing cue ball")
	# The boost: the first ball struck at full power leaves faster.
	var b0 := PoolSim.new(TableLayout.new().build())
	b0.add_ball(0, Vector2(300, 250))
	b0.add_ball(4, Vector2(400, 250))
	var b1 := b0.clone()
	b1.first_boost = 1.2
	for bs in [b0, b1]:
		bs.strike(Vector2.RIGHT, 800.0, 0.0, 0.0)
		while bs.vel[1] == Vector2.ZERO:
			bs.step(PoolSim.STEP)
	check(b1.vel[1].length() > b0.vel[1].length() * 1.15, "Uranium Reactor: the struck ball flies off faster")
	var ho := _run_with("", ["hothand"])
	var rws5 := PoolSim.new(TableLayout.new().build())
	rws5.add_ball(0, Vector2(300, 250))
	ho.apply_physics(rws5)
	check(rws5.pocket_pull == 0.0, "Holmium Magnet is off below Heat 3")
	ho.heat = 3
	ho.apply_physics(rws5)
	check(rws5.pocket_pull > 0.0, "and pulls at Heat 3")
	check(s3.roll_decel < 170.0, "velvet cloth lowers friction")
	var bi := _run_with("blackice", [])
	var s4 := PoolSim.new(TableLayout.new().build())
	s4.add_ball(0, Vector2(300, 250))
	bi.apply_physics(s4)
	check(s4.roll_decel <= 45.0 and s4.rail_e >= 0.9, "black ice is slippery and lively")
	var tl := _run_with("tilt", [])
	var s5 := PoolSim.new(TableLayout.new().build())
	s5.add_ball(0, Vector2(300, 250))
	tl.apply_physics(s5)
	s5.strike(Vector2.RIGHT, 800.0, 0.0, 0.0)
	s5.settle()
	check(s5.tilt != Vector2.ZERO and absf(s5.pos[0].y - 250.0) > 30.0, "tilted table bends a straight roll (dy %.0f)" % (s5.pos[0].y - 250.0))
