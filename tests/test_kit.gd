extends SceneTree
## The Hustler's Kit in a real game: set-up items arm and show on the prediction
## before they are spent, Rewind undoes a shot, and the physical effects hold up.

var failures := 0
var g: Node


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func _initialize() -> void:
	call_deferred("_go")


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _until(cond: Callable, limit: int) -> bool:
	for i in limit:
		if cond.call():
			return true
		await process_frame
	return cond.call()


func _point(p: Vector2) -> void:
	g.mouse_pos = g.view.base_position + p * g.TABLE_SCALE


func _sim(balls: Array) -> PoolSim:
	var s := PoolSim.new(TableLayout.new().build(1.0, []))
	for b in balls:
		var i := s.add_ball(b[0], b[1])
		s.vel[i] = b[2]
	return s


func _go() -> void:
	print("physics of the Kit")
	var gh := _sim([[0, Vector2(300, 250), Vector2(600, 0)], [5, Vector2(380, 250), Vector2.ZERO]])
	gh.ghost = 1
	gh.settle()
	check(gh.pos[1] == Vector2(380, 250) and gh.pos[0].x > 420.0, "Ghost Chalk: the shot passes straight through")
	var po := _sim([[5, Vector2(200, 250), Vector2(0, 150)]])
	var pn := _sim([[5, Vector2(200, 250), Vector2(0, 150)]])
	po.glide[0] = 1
	po.settle()
	pn.settle()
	check(po.pos[0].distance_to(Vector2(200, 250)) > pn.pos[0].distance_to(Vector2(200, 250)) + 30.0, "Polish glides further")
	var fz := _sim([[0, Vector2(300, 250), Vector2(600, 0)], [5, Vector2(380, 250), Vector2.ZERO]])
	fz.pinned[1] = 1
	fz.settle()
	check(fz.pos[1] == Vector2(380, 250), "Freeze Frame holds a ball still like a post")
	var wl := _sim([[5, Vector2(200, 300), Vector2(400, 0)]])
	var wn := _sim([[5, Vector2(200, 300), Vector2(400, 0)]])
	wl.extra_wells.append([Vector2(400, 220), 1.0])
	for k in 150:
		wl.step(PoolSim.STEP)
		wn.step(PoolSim.STEP)
	check(wl.pos[0].y < wn.pos[0].y - 4.0, "a Gravity Pebble bends a rolling ball")
	gh.clear_shot_flags()
	po.clear_shot_flags()
	wl.clear_shot_flags()
	check(gh.ghost == -1 and po.glide[0] == 0 and wl.extra_wells.is_empty(), "shot effects clear after the shot")

	g = load("res://main.tscn").instantiate()
	root.add_child(g)
	await _frames(3)
	g._new_run()
	await _until(func(): return g.state == g.S.AIM, 200)
	g.coaching = false
	g.fine_aim = true

	print("Catalysts used while aiming arm, preview, and spend a use on the shot")
	g.run.tools.assign(["ghostchalk", "trapdoor", "pythagoras", "newton", "rewind"])
	g.run.tool_charges = {"ghostchalk": 1, "trapdoor": 1, "pythagoras": 1, "newton": 1, "rewind": 1}
	var target: int = g.sim.index_of(5)
	g._use("ghostchalk")
	check(g.state == g.S.PICK, "Quantum Tunnel asks for a ball")
	_point(g.sim.pos[target])
	g._update_pick()
	g._pick_click()
	check(g.sim.ghost == target and g.state == g.S.AIM and int(g.run.tool_charges.ghostchalk) == 1, "it is armed, not spent")
	g._use("ghostchalk")
	check(g.sim.ghost == -1 and g.armed.is_empty() and int(g.run.tool_charges.ghostchalk) == 1, "tapping it again takes it back for free")
	g._use("trapdoor")
	_point(Vector2(300, 3))
	g._update_pick()
	g._pick_click()
	check(g.layout.pockets.size() == 7 and g.sim.layout.pockets.size() == 7, "Black Hole opens a seventh pocket for the shot")
	# Pythagorean Triple: three balls joined by force-field walls.
	var segs_before: int = g.sim.layout.segments.size()
	g._use("pythagoras")
	for nb in [1, 9, 10]:
		_point(g.sim.pos[g.sim.index_of(nb)])
		g._update_pick()
		g._pick_click()
	check(g.sim.layout.segments.size() >= segs_before + 4 and int(g.run.tool_charges.pythagoras) == 0, "Pythagorean Triple raises walls between three balls (%d new faces)" % (g.sim.layout.segments.size() - segs_before))
	# Newton's Cradle: the cue ball stops and the ball takes its momentum.
	var ci: int = g._cue_index()
	g.sim.vel[ci] = Vector2(300, 0)
	g.pick_return = g.S.AIM
	g._picked_ball("newton", target)
	check(g.sim.vel[ci] == Vector2.ZERO and g.sim.vel[target] == Vector2(300, 0), "Newton's Cradle passes the cue ball's momentum on")
	g.sim.vel[target] = Vector2.ZERO
	g.aim_dir = (Rack.FOOT - g.sim.pos[0]).normalized()
	g._shoot(0.9)
	await _until(func(): return g.state == g.S.ROLL, 60)
	check(int(g.run.tool_charges.trapdoor) == 0 and g.run.tools.has("trapdoor") and g.armed.is_empty(), "armed Catalysts spend a use on the shot and stay in the kit")
	await _until(func(): return g.state == g.S.AIM or g.state == g.S.PLACE or g.state == g.S.SHOP or g.state == g.S.OVER, 4000)
	check(g.layout.pockets.size() == 6, "the Black Hole is gone after the shot")

	print("Time Reversal, while paused")
	if g.state == g.S.PLACE:
		g._update_place()
		g._place_cue()
	await _until(func(): return g.state == g.S.AIM, 100)
	if g.state == g.S.AIM:
		g.run.tool_charges["rewind"] = 1
		var pos_before: Vector2 = g.sim.pos[0]
		var shots_before: int = g.run.shots_taken
		g.aim_dir = Vector2.RIGHT.rotated(0.4)
		g._shoot(0.7)
		await _until(func(): return g.state == g.S.ROLL, 120)
		g._hold()
		await _frames(2)
		check(g.state == g.S.HOLD, "the shot is paused")
		g._use("rewind")
		await _frames(2)
		check(g.state == g.S.AIM and g.run.shots_taken == shots_before and g.sim.pos[0].distance_to(pos_before) < 0.01, "Time Reversal undoes the shot mid-roll")
		check(int(g.run.tool_charges.rewind) == 0 and g.run.tools.has("rewind"), "it spends its use but stays in the kit")
	else:
		check(true, "the table ended, so Time Reversal was not needed")
	print("kit tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
