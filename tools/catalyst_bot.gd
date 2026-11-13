class_name CatalystBot
extends RefCounted
## Bounded Catalyst lookahead for headless playtests. A plan is tested against
## the exact same noisy shot without a Catalyst before a charge is committed.

const SUPPORTED := ["focal", "pocketcover", "polish", "ghostchalk", "leadweight",
	"nudge", "secondstrike", "goldenratio", "freezeframe", "tidal",
	"newton", "reflection", "damping", "momentum", "absolutezero",
	"gravitypebble", "darkenergy", "blast", "blink", "swap",
	"post", "portal", "wall", "trapdoor", "hookes", "pythagoras", "centremass", "englishdial",
	"spotter", "rewind"]
const PAUSE_TIME := 0.32


static func choose(sim: PoolSim, run: RunState, dir: Vector2, power: float, is_break: bool, stats: Dictionary = {}) -> Dictionary:
	var available: Array = run.tools.duplicate()
	if run.cue_kit() != "" and not available.has(run.cue_kit()):
		available.append(run.cue_kit())
	available = available.filter(func(id): return SUPPORTED.has(id) and int(run.tool_charges.get(id, 0)) > 0)
	if available.is_empty():
		return {}
	var shot := {"dir": dir, "power": power}
	var base := _trial(sim, run, shot, is_break, {})
	var best := {}
	var best_gain := maxf(10.0, run.target() * 0.04)
	var first_pot := -1
	if base.result.scored and not base.result.get("pocket_list", []).is_empty():
		first_pot = int(base.result.pocket_list[0])
	var obj := _target_ball(sim, run)
	for id in available:
		var plans: Array = []
		var best_id_gain := -INF
		match id:
			"focal", "pocketcover", "tidal":
				var pockets := [first_pot] if first_pot >= 0 else [run.hot_pocket, _nearest_pocket(sim, obj)]
				for k in pockets:
					if int(k) >= 0 and int(k) < sim.layout.pockets.size() and not sim.layout.pockets[k].closed:
						plans.append({"id": id, "pocket": k})
			"polish", "ghostchalk", "leadweight":
				if obj >= 0:
					plans.append({"id": id, "ball": obj})
				if id == "polish":
					plans.append({"id": id, "phase": "pause"})
			"nudge", "goldenratio", "freezeframe", "newton", "reflection", "damping", "momentum", "absolutezero", "gravitypebble", "darkenergy", "blast", "blink":
				plans.append({"id": id})
			"secondstrike":
				plans.append({"id": id, "dir": dir, "power": power})
			"swap":
				if obj >= 0:
					for i in sim.count():
						if i != obj and sim.alive[i] == 1 and sim.num[i] != 0:
							plans.append({"id": id, "ball": obj, "other": i})
							break
			"post", "portal":
				if obj >= 0:
					var to_pocket := _nearest_pocket(sim, obj)
					if to_pocket >= 0:
						var toward: Vector2 = (sim.layout.pockets[to_pocket].pos - sim.pos[obj]).normalized()
						var side: Vector2 = toward.orthogonal()
						var spot: Vector2 = sim.pos[obj] + toward * 85.0 + side * 45.0
						if _spot_clear(sim, spot, TableLayout.BUMPER_R if id == "post" else TableLayout.PORTAL_R):
							if id == "post":
								plans.append({"id": id, "spot": spot})
							else:
								var ci := sim.index_of(0)
								var entry: Vector2 = sim.pos[ci] + dir * 100.0
								if _spot_clear(sim, entry, TableLayout.PORTAL_R) and entry.distance_to(spot) > 70.0:
									plans.append({"id": id, "entry": entry, "spot": spot})
			"wall":
				plans.append({"id": id})
			"trapdoor":
				if obj >= 0:
					var pick := _cushion_pick(sim, sim.pos[obj])
					if not pick.is_empty():
						pick["id"] = id
						plans.append(pick)
			"hookes":
				if obj >= 0:
					var pick := _cushion_pick(sim, sim.pos[obj])
					if not pick.is_empty():
						pick["id"] = id
						plans.append(pick)
			"pythagoras":
				var tri: Array = []
				for i in sim.count():
					if sim.alive[i] == 1 and sim.num[i] != 0:
						tri.append(i)
						if tri.size() == 3: break
				if tri.size() == 3:
					plans.append({"id": id, "balls": tri})
			"centremass":
				plans.append({"id": id})
			"englishdial":
				plans.append({"id": id, "follow": 0.6})
				plans.append({"id": id, "follow": -0.6})
		for plan in plans:
			var trial := _trial(sim, run, shot, is_break, plan)
			var gain: float = trial.value - base.value
			best_id_gain = maxf(best_id_gain, gain)
			if gain > best_gain:
				best_gain = gain
				best = plan
		var seen: Dictionary = stats.get(id, {"available": 0, "tested": 0, "positive": 0, "actionable": 0, "gain_sum": 0.0})
		seen.available += 1
		if not plans.is_empty():
			seen.tested += 1
			seen.positive += int(best_id_gain > 0.0)
			seen.actionable += int(best_id_gain > maxf(10.0, run.target() * 0.04))
			seen.gain_sum += best_id_gain
		stats[id] = seen
	return best


## Conservation is an investment in a later shot, so a one-shot trial undervalues it.
static func maybe_spotter(sim: PoolSim, run: RunState) -> bool:
	if int(run.tool_charges.get("spotter", 0)) <= 0 or sim.object_balls_left() > 3 or run.score >= run.target():
		return false
	var best := -1
	var value := -1
	for i in sim.count():
		if sim.alive[i] == 0 and sim.num[i] != 0 and sim.num[i] != 8:
			var points := Catalog.ball_points(sim.num[i])
			if points > value:
				value = points
				best = i
	if best < 0 or run.target() - run.score < value:
		return false
	var spot := Rack.FOOT
	var tries := 0
	while not sim.is_clear_spot(spot, best) and tries < 40:
		spot = Rack.FOOT + Vector2(-TableLayout.R * 2.2 * (tries / 6 + 1), 0).rotated(tries * TAU / 6.0)
		tries += 1
	if not sim.is_clear_spot(spot, best):
		return false
	sim.alive[best] = 1
	sim.pos[best] = spot
	sim.vel[best] = Vector2.ZERO
	return run.spend("spotter")


static func should_rewind(result: Dictionary, run: RunState, is_break: bool) -> bool:
	if int(run.tool_charges.get("rewind", 0)) <= 0 or result.scored:
		return false
	return result.foul == "Scratch" or (not is_break and run.chalk <= 3)


static func _target_ball(sim: PoolSim, run: RunState) -> int:
	var c := AutoPlayer.candidates(sim, run)
	if not c.is_empty():
		return int(c[0].obj)
	var ci := sim.index_of(0)
	var best := -1
	var distance := INF
	for i in sim.count():
		if sim.alive[i] == 1 and sim.num[i] != 0:
			var d := sim.pos[i].distance_squared_to(sim.pos[ci])
			if d < distance:
				distance = d
				best = i
	return best


static func _nearest_pocket(sim: PoolSim, ball: int) -> int:
	if ball < 0:
		return -1
	var best := -1
	var distance := INF
	for k in sim.layout.pockets.size():
		var pk: Dictionary = sim.layout.pockets[k]
		if pk.closed:
			continue
		var d := sim.pos[ball].distance_squared_to(pk.pos)
		if d < distance:
			distance = d
			best = k
	return best


static func _spot_clear(sim: PoolSim, p: Vector2, radius: float) -> bool:
	if not sim.layout.contains(p, radius + 4.0):
		return false
	for pk in sim.layout.pockets:
		if (pk.pos as Vector2).distance_to(p) < float(pk.r) + radius + 12.0:
			return false
	for i in sim.count():
		if sim.alive[i] == 1 and sim.pos[i].distance_to(p) < TableLayout.R + radius + 3.0:
			return false
	for bp in sim.layout.bumpers:
		if (bp.pos as Vector2).distance_to(p) < float(bp.r) + radius + 6.0:
			return false
	return true


static func _cushion_pick(sim: PoolSim, p: Vector2) -> Dictionary:
	var best := {}
	var distance := INF
	for i in sim.layout.segments.size():
		var sg: Dictionary = sim.layout.segments[i]
		if sg.get("board", false):
			continue
		var a: Vector2 = sg.a
		var b: Vector2 = sg.b
		var ab := b - a
		if ab.length() < 100.0:
			continue
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.2, 0.8)
		var spot := a + ab * t
		var near_pocket := false
		for pk in sim.layout.pockets:
			if (pk.pos as Vector2).distance_to(spot) < 90.0:
				near_pocket = true
				break
		if near_pocket:
			continue
		var d := p.distance_squared_to(spot)
		if d < distance:
			distance = d
			best = {"spot": spot, "normal": sg.n, "segment": i}
	return best


static func _trial(sim: PoolSim, run: RunState, shot: Dictionary, is_break: bool, plan: Dictionary) -> Dictionary:
	var copy := sim.clone()
	var ctx := run.shot_ctx(float(shot.power), sim, is_break)
	var rng := RandomNumberGenerator.new()
	rng.seed = run.seed_value * 10007 + run.table_index * 97 + run.shots_taken
	ctx["rng"] = rng
	if not plan.is_empty():
		apply_setup(copy, run, plan)
		if plan.id == "focal":
			ctx["hot_pocket"] = plan.pocket
		ctx["item_shot"] = true
	copy.strike(shot.dir, AutoPlayer.speed(float(shot.power)) * run.power_mult(is_break), 0.0, 0.0)
	if is_pause(plan):
		advance_to_pause(copy)
		apply_pause(copy, plan)
	copy.settle()
	ctx["events"] = copy.events
	ctx["cue_end"] = copy.pos[copy.index_of(0)]
	var result := Scorer.score(ctx)
	var value := float(result.total - int(result.get("penalty", 0))) if result.scored else -float(run.target()) * 0.25
	if result.scratch:
		value -= run.target() * 0.15
	return {"value": value, "result": result}


static func is_pause(plan: Dictionary) -> bool:
	return not plan.is_empty() and (plan.get("phase", "") == "pause" or plan.id in ["nudge", "secondstrike", "goldenratio", "freezeframe", "tidal", "newton", "reflection", "damping", "momentum", "absolutezero", "gravitypebble", "darkenergy", "blast", "blink", "wall", "centremass", "englishdial"])


static func advance_to_pause(sim: PoolSim) -> void:
	for _i in int(PAUSE_TIME / PoolSim.STEP):
		if not sim.moving():
			break
		sim.step(PoolSim.STEP)


static func apply_setup(sim: PoolSim, run: RunState, plan: Dictionary, commit: bool = false) -> void:
	if plan.is_empty():
		return
	match String(plan.id):
		"pocketcover":
			# The live game overlays a second mouth twice as wide for this shot.
			sim.layout = run.build_layout()
			var wide: Dictionary = sim.layout.pockets[int(plan.pocket)].duplicate(true)
			wide.r *= 2.0
			wide["temp"] = true
			sim.layout.pockets.append(wide)
		"polish":
			if plan.get("phase", "") != "pause":
				sim.glide[int(plan.ball)] = 1
		"ghostchalk":
			sim.ghost = int(plan.ball)
		"leadweight":
			sim.mass[int(plan.ball)] *= 4.0
		"swap":
			var a := int(plan.ball)
			var b := int(plan.other)
			var p := sim.pos[a]
			sim.pos[a] = sim.pos[b]
			sim.pos[b] = p
		"post":
			if commit:
				run.table_mods.bumpers.append([plan.spot.x, plan.spot.y])
				sim.layout = run.build_layout()
			else:
				sim.layout = run.build_layout()
				sim.layout.add_bumper(plan.spot, TableLayout.BUMPER_R)
		"portal":
			if commit:
				run.table_mods.portals.append([plan.entry.x, plan.entry.y, plan.spot.x, plan.spot.y])
				sim.layout = run.build_layout()
			else:
				sim.layout = run.build_layout()
				sim.layout.portals.append({"a": plan.entry, "b": plan.spot})
		"trapdoor":
			sim.layout = run.build_layout()
			var c: Vector2 = plan.spot
			var n: Vector2 = plan.normal
			sim.layout.pockets.append({"pos": c - n * 6.0, "r": 26.0, "side": true, "dir": -n, "closed": false, "temp": true})
		"wall":
			sim.layout = run.build_layout()
		"hookes":
			var n: Vector2 = plan.normal
			for si in sim.layout.segments.size():
				var sg: Dictionary = sim.layout.segments[si]
				if (sg.n as Vector2).dot(n) > 0.99:
					sim.seg_e[si] = 1.0
		"pythagoras":
			sim.layout = run.build_layout()
			var balls: Array = plan.balls
			for k in 3:
				var a: Vector2 = sim.pos[int(balls[k])]
				var b: Vector2 = sim.pos[int(balls[(k + 1) % 3])]
				if a.distance_to(b) <= TableLayout.R * 3.0:
					continue
				var d: Vector2 = (b - a).normalized()
				var x: Vector2 = a + d * TableLayout.R * 1.4
				var y: Vector2 = b - d * TableLayout.R * 1.4
				var n: Vector2 = (y - x).orthogonal().normalized()
				sim.layout.segments.append({"a": x, "b": y, "n": n})
				sim.layout.segments.append({"a": y, "b": x, "n": -n})
		_:
			pass


static func apply_pause(sim: PoolSim, plan: Dictionary) -> void:
	if not is_pause(plan):
		return
	var ci := sim.index_of(0)
	var ball := -1
	var speed := 0.0
	for i in sim.count():
		if sim.alive[i] == 1 and sim.num[i] != 0 and sim.vel[i].length() > speed:
			ball = i
			speed = sim.vel[i].length()
	match String(plan.id):
		"nudge":
			if ball >= 0:
				var k := _nearest_pocket(sim, ball)
				if k >= 0:
					sim.vel[ball] += (sim.layout.pockets[k].pos - sim.pos[ball]).normalized() * 260.0
		"secondstrike":
			if ci >= 0 and sim.alive[ci] == 1:
				sim.vel[ci] = (plan.dir as Vector2) * AutoPlayer.speed(float(plan.power))
				sim.spin[ci] = Vector2.ZERO
		"goldenratio":
			if ball >= 0:
				sim.vel[ball] *= 1.618
		"polish":
			if ball >= 0:
				sim.glide[ball] = 1
		"freezeframe":
			if ball >= 0:
				sim.vel[ball] = Vector2.ZERO
				sim.spin[ball] = Vector2.ZERO
				sim.pinned[ball] = 1
		"tidal":
			if int(plan.pocket) < sim.layout.pockets.size():
				sim.extra_wells.append([sim.layout.pockets[int(plan.pocket)].pos, 1.4])
		"newton":
			if ball >= 0 and ci >= 0:
				sim.vel[ball] = sim.vel[ci]
				sim.vel[ci] = Vector2.ZERO
				sim.spin[ci] = Vector2.ZERO
		"reflection":
			if ball >= 0:
				sim.vel[ball] = -sim.vel[ball]
				sim.spin[ball] = -sim.spin[ball]
		"damping":
			if ball >= 0:
				sim.vel[ball] *= 0.5
				sim.spin[ball] *= 0.5
		"momentum":
			if ball >= 0 and ci >= 0:
				var v := sim.vel[ball]
				sim.vel[ball] = sim.vel[ci]
				sim.vel[ci] = v
		"absolutezero":
			for i in sim.count():
				if sim.alive[i] == 1:
					sim.vel[i] = Vector2.ZERO
					sim.spin[i] = Vector2.ZERO
		"gravitypebble", "darkenergy":
			if ball >= 0:
				var k := _nearest_pocket(sim, ball)
				if k >= 0:
					var toward: Vector2 = (sim.layout.pockets[k].pos - sim.pos[ball]).normalized()
					var p: Vector2 = sim.pos[ball] - toward * 70.0 if plan.id == "darkenergy" else sim.layout.pockets[k].pos
					sim.extra_wells.append([p, -1.0 if plan.id == "darkenergy" else 1.0])
		"blast":
			if ball >= 0:
				var p := sim.pos[ball]
				for i in sim.count():
					if sim.alive[i] == 1:
						var d := sim.pos[i] - p
						var dl := d.length()
						if dl < 200.0 and dl > 1.0:
							sim.vel[i] += d / dl * 460.0 * (1.0 - dl / 200.0)
		"blink":
			if ci >= 0 and sim.alive[ci] == 1 and ball >= 0:
				var to: Vector2 = sim.vel[ball].normalized()
				var p := sim.pos[ball] - to * 85.0
				if sim.is_clear_spot(p, ci):
					sim.pos[ci] = p
		"wall":
			if ball >= 0:
				var a: Vector2 = sim.pos[ball] + Vector2(-65.0, 45.0)
				var b: Vector2 = sim.pos[ball] + Vector2(65.0, 45.0)
				if not sim.layout.contains(a, TableLayout.R) or not sim.layout.contains(b, TableLayout.R):
					return
				for i in sim.count():
					if sim.alive[i] == 1 and sim.pos[i].distance_to(Geometry2D.get_closest_point_to_segment(sim.pos[i], a, b)) < TableLayout.R * 1.2:
						return
				var n: Vector2 = (b - a).orthogonal().normalized()
				sim.layout.segments.append({"a": a, "b": b, "n": n})
				sim.layout.segments.append({"a": b, "b": a, "n": -n})
		"centremass":
			var balls: Array = []
			for i in sim.count():
				if sim.alive[i] == 1 and sim.num[i] != 0 and sim.vel[i].length() > 4.0:
					balls.append(i)
					if balls.size() == 3: break
			if balls.size() >= 2:
				var mid := Vector2.ZERO
				for i in balls: mid += sim.pos[i]
				mid /= float(balls.size())
				for i in balls:
					var to: Vector2 = mid - sim.pos[i]
					if to.length() > 1.0:
						sim.vel[i] = to.normalized() * maxf(sim.vel[i].length(), 220.0)
		"englishdial":
			if ci >= 0 and sim.alive[ci] == 1 and sim.vel[ci].length() > 1.0:
				sim.spin[ci] = sim.vel[ci].normalized() * float(plan.follow) * sim.vel[ci].length() * 0.62 * sim.spin_power
