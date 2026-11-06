extends SceneTree
## Break / travel statistics for physics tuning.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var decel := float(args[0]) if args.size() > 0 else 230.0
	var drag := float(args[1]) if args.size() > 1 else 0.2
	var speed := float(args[2]) if args.size() > 2 else 2400.0
	var pots := 0
	var t := 0.0
	var spread := 0.0
	var scratches := 0
	var N := 30
	for k in N:
		var rng := RandomNumberGenerator.new()
		rng.seed = k
		var s := PoolSim.new(TableLayout.new().build())
		s.roll_decel = decel
		s.drag = drag
		s.ball_e = float(args[3]) if args.size() > 3 else 0.94
		s.rail_e = float(args[4]) if args.size() > 4 else 0.78
		s.add_ball(0, Rack.HEAD + Vector2(0, rng.randf_range(-60, 60)))
		Rack.build(s, "nine" if k % 2 == 0 else "fifteen", rng)
		var dir := (Rack.FOOT - s.pos[0]).normalized().rotated(rng.randf_range(-0.01, 0.01))
		s.strike(dir, speed, 0.0, 0.0)
		s.settle()
		t += s.time
		for e in s.events:
			if e.type == "pocket":
				if e.a == 0:
					scratches += 1
				else:
					pots += 1
		var c := Vector2.ZERO
		var n := 0
		for i in s.count():
			if s.alive[i] == 1 and s.num[i] != 0:
				c += s.pos[i]
				n += 1
		var sd := 0.0
		if n > 0:
			c /= n
			for i in s.count():
				if s.alive[i] == 1 and s.num[i] != 0:
					sd += s.pos[i].distance_to(c)
			sd /= n
		spread += sd
	var s2 := PoolSim.new(TableLayout.new().build())
	s2.roll_decel = decel
	s2.drag = drag
	print("decel %.0f drag %.2f speed %.0f: pots/break %.2f scratch %d/%d time %.1fs spread %.0f" % [decel, drag, speed, pots / float(N), scratches, N, t / N, spread / N])
	for p in [0.25, 0.5, 0.75, 1.0]:
		var v := 90.0 + pow(p, 1.35) * (speed - 90.0)
		var sp := v
		var d := 0.0
		while sp > 4.0:
			var ns := sp - (decel + drag * sp) / 240.0
			d += (sp + maxf(ns, 0.0)) * 0.5 / 240.0
			sp = ns
		print("  power %.2f -> %.0f units (%.1f table lengths)" % [p, d, d / 1000.0])
	quit()
