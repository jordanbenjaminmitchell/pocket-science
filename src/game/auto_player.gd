class_name AutoPlayer
extends RefCounted
## A competent pool AI built on the real sim: enumerates clear pots, tests the
## best few with lookahead simulations and picks the highest expected score.
## Used by the balance bot, the end-to-end tests and the title-screen demo.


static func speed(p: float) -> float:
	return 90.0 + pow(p, 1.35) * (2250.0 - 90.0)


static func ctx_for(run: RunState, pw: float, sim: PoolSim = null, is_break: bool = false) -> Dictionary:
	if sim != null:
		return run.shot_ctx(pw, sim, is_break)
	return {"perks": run.perks, "imbues": run.imbues, "hot_pocket": run.hot_pocket, "lab": run.current().lab,
		"boss": run.current().id, "element_mix": run.element_mix,
		"anomaly": run.current().anomaly, "heat": run.heat, "power": pw, "shots_taken": run.shots_taken,
		"catalyst": run.catalyst, "chalk": run.chalk, "money": run.money, "target": run.target(),
		"empty_slots": RunState.MAX_PERKS - run.perks.size(), "pockets_used": run.pockets_used}


static func candidates(sim: PoolSim, run: RunState) -> Array:
	var out: Array = []
	var ci := sim.index_of(0)
	var cue := sim.pos[ci]
	var anomaly: String = run.current().anomaly
	var lowest := 99
	for i in sim.count():
		if sim.alive[i] == 1 and sim.num[i] != 0:
			lowest = mini(lowest, sim.num[i])
	for i in sim.count():
		if sim.alive[i] == 0 or sim.num[i] == 0:
			continue
		if anomaly == "rotation" and sim.num[i] != lowest:
			continue
		if sim.num[i] == 8 and sim.object_balls_left() > 1 and (anomaly == "cursed8" or not run.wants_eight()):
			continue
		for k in sim.layout.pockets.size():
			var pk: Dictionary = sim.layout.pockets[k]
			if pk.closed:
				continue
			if anomaly == "onepocket" and k != run.hot_pocket and k != 5 - run.hot_pocket:
				continue
			var aim_pt: Vector2 = pk.pos - (pk.dir as Vector2) * 6.0
			var od := (aim_pt - sim.pos[i]).normalized()
			var ghost := sim.pos[i] - od * TableLayout.R * 2.0
			var d := (ghost - cue).normalized()
			var cut := absf(d.angle_to(od))
			if cut > deg_to_rad(72):
				continue
			var h := sim.cast(cue, d, ci)
			if h.kind != "ball" or h.hit != i:
				continue
			var h2 := sim.cast(sim.pos[i], od, i)
			if h2.kind != "pocket" or h2.hit != k:
				continue
			var dist := cue.distance_to(ghost) + sim.pos[i].distance_to(pk.pos)
			var ease := cos(cut) * 600.0 / (300.0 + dist)
			var val := Catalog.ball_points(sim.num[i]) * (2.0 if k == run.hot_pocket else 1.0)
			out.append({"dir": d, "ease": ease, "score": ease * (1.0 + val / 60.0), "obj": i, "pocket": k})
	out.sort_custom(func(a, b): return a.score > b.score)
	return out


static func choose(sim: PoolSim, run: RunState, tries: int = 5) -> Dictionary:
	var ci := sim.index_of(0)
	var c := candidates(sim, run)
	var best := {}
	var best_v := -1.0
	for j in mini(tries, c.size()):
		for pw in [0.35, 0.55, 0.8]:
			var s := sim.clone()
			s.strike(c[j].dir, speed(pw), 0.0, 0.0)
			s.settle()
			var pots := 0
			var scratch := false
			for e in s.events:
				if e.type == "pocket":
					if e.a == 0:
						scratch = true
					else:
						pots += 1
			if scratch or pots == 0:
				continue
			var ctx_check := ctx_for(run, pw, sim)
			ctx_check["events"] = s.events
			if not Scorer.score(ctx_check).scored:
				continue
			var ctx := ctx_for(run, pw, sim)
			ctx["events"] = s.events
			ctx["cue_end"] = s.pos[ci]
			var r := Scorer.score(ctx)
			# Prefer shots that leave another pot available (position play).
			var follow_up := 1.0 if candidates(s, run).size() > 0 else 0.6
			var v: float = (r.total - int(r.penalty)) * c[j].ease * follow_up
			if v > best_v:
				best_v = v
				best = {"dir": c[j].dir, "power": pw}
	if best.is_empty():
		if c.size() > 0:
			return {"dir": c[0].dir, "power": 0.55}
		return safety_shot(sim, run)
	return best


## No pot available: make legal contact with a ball the rules allow (the lowest
## ball under Rotation, never the 8 under Cursed 8), preferring a clear path.
static func safety_shot(sim: PoolSim, run: RunState) -> Dictionary:
	var ci := sim.index_of(0)
	var anomaly: String = run.current().anomaly
	var lowest := 99
	for i in sim.count():
		if sim.alive[i] == 1 and sim.num[i] != 0:
			lowest = mini(lowest, sim.num[i])
	var options: Array = []
	for i in sim.count():
		if sim.alive[i] == 0 or sim.num[i] == 0:
			continue
		if anomaly == "rotation" and sim.num[i] != lowest:
			continue
		if anomaly == "cursed8" and sim.num[i] == 8 and sim.object_balls_left() > 1:
			continue
		options.append(i)
	options.sort_custom(func(a, b): return sim.pos[a].distance_to(sim.pos[ci]) < sim.pos[b].distance_to(sim.pos[ci]))
	for i in options:
		var d := (sim.pos[i] - sim.pos[ci]).normalized()
		var h := sim.cast(sim.pos[ci], d, ci)
		if h.kind == "ball" and h.hit == i:
			return {"dir": d, "power": 0.5}
	if options.size() > 0:
		return {"dir": (sim.pos[options[0]] - sim.pos[ci]).normalized(), "power": 0.5}
	return {"dir": Vector2.RIGHT, "power": 0.4}


static func place_spot(sim: PoolSim, run: RunState, rng: RandomNumberGenerator, head_only: bool = false) -> Vector2:
	var ci := sim.index_of(0)
	var old_alive := sim.alive[ci]
	var old := sim.pos[ci]
	sim.alive[ci] = 1
	var best := Rack.HEAD
	var best_e := -1.0
	for t in 24:
		var p := Vector2(rng.randf_range(40, Rack.HEAD.x if head_only else 960), rng.randf_range(40, 460))
		if not sim.is_clear_spot(p, ci):
			continue
		sim.pos[ci] = p
		var c := candidates(sim, run)
		if c.size() > 0 and c[0].ease > best_e:
			best_e = c[0].ease
			best = p
	sim.pos[ci] = old
	sim.alive[ci] = old_alive
	return best
