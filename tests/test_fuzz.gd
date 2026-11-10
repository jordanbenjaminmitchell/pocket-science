extends SceneTree
## Physics fuzz: random racks, labs and shots (with spin). After every shot the
## table must settle in time with no NaNs, no overlaps and no ball escaping.
## FUZZ_SHOTS env var raises the count for long soak runs (default 400).

var failures := 0


func _initialize() -> void:
	var n := int(OS.get_environment("FUZZ_SHOTS")) if OS.has_environment("FUZZ_SHOTS") else 400
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	var labs := ["standard", "cryo", "cyclotron", "spring", "gravity"]
	var stats := {"timeouts": 0, "nan": 0, "overlap": 0, "escaped": 0, "in_jaws": 0, "max_time": 0.0, "pots": 0}
	var bad: Array = []
	var shots := 0
	var t0 := Time.get_ticks_msec()
	while shots < n:
		var lab: String = labs[rng.randi_range(0, labs.size() - 1)]
		var scale := rng.randf_range(0.85, 1.25)
		var closed: Array[int] = []
		if rng.randf() < 0.15:
			closed.assign([1, 4])
		var layout := TableLayout.new().build(scale, closed)
		if lab == "cyclotron":
			layout.add_bumper(Vector2(500, 135), 20.0)
			layout.add_bumper(Vector2(500, 365), 20.0)
		var s := PoolSim.new(layout)
		match lab:
			"cryo":
				s.roll_decel = 90.0
				s.drag = 0.05
			"spring":
				s.rail_e = 0.92
			"gravity":
				s.well_pos = Vector2(500, 250)
				s.well_strength = 1.0
		if rng.randf() < 0.2:
			s.pocket_pull = 1.0
		if rng.randf() < 0.15:
			s.cue_damp = 0.4
		if rng.randf() < 0.15:
			s.tilt = Vector2(0, 55.0 * (1.0 if rng.randf() < 0.5 else -1.0))
		if rng.randf() < 0.1:
			s.roll_decel = 45.0
			s.drag = 0.03
			s.rail_e = 0.9
		s.add_ball(0, Rack.HEAD + Vector2(rng.randf_range(-100, 0), rng.randf_range(-150, 150)))
		Rack.build(s, rng)
		var mass_mode := rng.randi_range(0, 4)
		for i in s.count():
			if mass_mode == 1 and s.num[i] != 0:
				s.mass[i] = 1.6
			elif mass_mode == 2 and s.num[i] == 0:
				s.mass[i] = 1.6
			elif mass_mode == 3 and s.num[i] != 0:
				s.mass[i] = 0.75
		# Several shots per rack so later shots meet scattered, rail-hugging balls.
		for k in 6:
			var ci := s.index_of(0)
			if s.alive[ci] == 0:
				var placed := false
				for tries in 50:
					var p := Vector2(rng.randf_range(20, 980), rng.randf_range(20, 480))
					if s.is_clear_spot(p, ci):
						s.alive[ci] = 1
						s.pos[ci] = p
						placed = true
						break
				if not placed:
					break
			var dir := Vector2.RIGHT.rotated(rng.randf() * TAU)
			if rng.randf() < 0.5:
				# Aim at a real ball half the time.
				var targets: Array = []
				for i in s.count():
					if s.alive[i] == 1 and s.num[i] != 0:
						targets.append(i)
				if targets.is_empty():
					break
				var tgt: int = targets[rng.randi_range(0, targets.size() - 1)]
				dir = (s.pos[tgt] - s.pos[ci]).normalized().rotated(rng.randf_range(-0.3, 0.3))
			var speed := rng.randf_range(80.0, 2250.0) * (1.0 if rng.randf() < 0.8 else 1.25)
			s.strike(dir, speed, rng.randf_range(-1, 1), rng.randf_range(-1, 1))
			var ws := Time.get_ticks_msec()
			s.settle(30.0)
			shots += 1
			if OS.has_environment("FUZZ_VERBOSE"):
				print("shot %d lab %s speed %.0f sim %.1fs wall %d ms moving=%s" % [shots, lab, speed, s.time, Time.get_ticks_msec() - ws, s.moving()])
			stats.max_time = maxf(stats.max_time, s.time)
			var problem := ""
			if s.moving():
				stats.timeouts += 1
				problem = "timeout"
			for i in s.count():
				if s.alive[i] == 0:
					continue
				var p := s.pos[i]
				if is_nan(p.x) or is_nan(p.y) or is_nan(s.vel[i].x):
					stats.nan += 1
					problem = "nan"
				var outside := p.x < TableLayout.R - 0.5 or p.y < TableLayout.R - 0.5 or p.x > TableLayout.W - TableLayout.R + 0.5 or p.y > TableLayout.H - TableLayout.R + 0.5
				if outside:
					# Hanging in a pocket throat is legal; anywhere else is an escape.
					var near_pocket := false
					for pk in layout.pockets:
						if not pk.closed and p.distance_to(pk.pos) < pk.r + TableLayout.R * 2.5:
							near_pocket = true
					if near_pocket:
						stats.in_jaws += 1
					else:
						stats.escaped += 1
						problem = "escaped %s" % p
				for j in range(i + 1, s.count()):
					if s.alive[j] == 1 and p.distance_to(s.pos[j]) < TableLayout.R * 2.0 - 0.5:
						stats.overlap += 1
						problem = "overlap %d-%d" % [s.num[i], s.num[j]]
			for e in s.events:
				if e.type == "pocket":
					stats.pots += 1
			if problem != "" and bad.size() < 10:
				bad.append("%s (lab %s shot %d)" % [problem, lab, shots])
			if s.object_balls_left() == 0:
				break
	var secs := (Time.get_ticks_msec() - t0) / 1000.0
	print("fuzz: %d shots in %.1fs  pots=%d  max settle %.1fs  hanging-in-jaws=%d" % [shots, secs, stats.pots, stats.max_time, stats.in_jaws])
	for b in bad:
		print("  problem: ", b)
	for k in ["timeouts", "nan", "overlap", "escaped"]:
		var ok: bool = stats[k] == 0
		print("  ", "ok  " if ok else "FAIL ", "%s: %d" % [k, stats[k]])
		if not ok:
			failures += 1
	print("fuzz tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
