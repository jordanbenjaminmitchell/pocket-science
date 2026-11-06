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
	Rack.build(s, "fifteen", rng)
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
	Rack.build(s2, "fifteen", rng2)
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
