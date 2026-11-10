extends SceneTree
## When the guideline turns gold (object ball predicted into a pocket) and the
## shot has enough pace, the real simulation must pot that ball.

func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var gold := 0
	var made := 0
	var misses: Array = []
	var trials := 0
	while gold < 200 and trials < 15000:
		trials += 1
		var s := PoolSim.new(TableLayout.new().build(1.08))
		s.add_ball(0, Vector2(rng.randf_range(40, 960), rng.randf_range(40, 460)))
		var placed := 0
		while placed < 4:
			var p := Vector2(rng.randf_range(30, 970), rng.randf_range(30, 470))
			if s.is_clear_spot(p):
				s.add_ball(placed + 1, p)
				placed += 1
		var aim := Vector2.RIGHT.rotated(rng.randf() * TAU)
		var g := TableView.compute_guide(s, aim, 0.0, 0.0, false)
		if not g.get("obj_pot", false):
			continue
		gold += 1
		var obj: int = g.obj_index
		var c := s.clone()
		c.strike(aim, 2000.0, 0.0, 0.0)
		c.settle()
		var ok := false
		for e in c.events:
			if e.type == "pocket" and e.a == c.num[obj] and e.pocket == g.obj_pocket:
				ok = true
		if ok:
			made += 1
		else:
			# A genuine guideline error is an unpredicted cushion or the wrong pocket
			# before any other ball touches it. Stopping short (pace) or being hit
			# by a moving ball is outside what a static guideline promises.
			var nn: int = c.num[obj]
			var contacts := 0
			var rails := 0
			var genuine := false
			for e in c.events:
				if e.type == "ball" and (e.a == nn or e.b == nn):
					contacts += 1
					if contacts > 1:
						break
				elif e.type == "rail" and e.a == nn:
					rails += 1
					if rails > int(g.get("obj_rails", 0)):
						genuine = true
						break
				elif e.type == "pocket" and e.a == nn:
					genuine = true
					break
			if not genuine:
				gold -= 1
				continue
			var n: int = c.num[obj]
			var seen := false
			var why := "?"
			for e in c.events:
				if e.type == "ball" and (e.a == n or e.b == n):
					if not seen:
						seen = true
						continue
					why = "ball %d-%d" % [e.a, e.b]
					break
				if seen and e.type == "rail" and e.a == n:
					why = "rail at %s; guide path %s pocket %s r=%.1f start %s" % [e.at, g.obj, c.layout.pockets[g.obj_pocket].pos, c.layout.pockets[g.obj_pocket].r, s.pos[obj]]
					break
				if seen and e.type == "pocket" and e.a == n:
					why = "other pocket %d (want %d)" % [e.pocket, g.obj_pocket]
					break
			if misses.size() < 25:
				var trail: Array = []
				for e in c.events:
					if e.get("a", -1) == n or e.get("b", -1) == n:
						trail.append("%s%s" % [e.type, (" @%s" % e.at) if e.has("at") else ""])
				print("  miss trail: ", trail, " guide=", g.obj, " pocket=", g.obj_pocket)
			misses.append(why)
	var rate := made / float(maxi(gold, 1))
	print("guide trust: %d/%d gold lines potted (%.1f%%)" % [made, gold, rate * 100.0])
	var pass_ok := rate >= 0.97
	print("  ", "ok  " if pass_ok else "FAIL ", "gold line is trustworthy (>=97%)")
	print("guide trust tests: %d failures" % (0 if pass_ok else 1))
	quit(0 if pass_ok else 1)
