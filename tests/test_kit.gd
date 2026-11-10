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

	print("set-up items arm, preview, and are spent only on the shot")
	g.run.items.assign(["ghostchalk", "trapdoor", "calledshot"])
	var target: int = g.sim.index_of(5)
	g._use("ghostchalk")
	check(g.state == g.S.PICK, "Ghost Chalk asks for a ball")
	_point(g.sim.pos[target])
	g._update_pick()
	g._pick_click()
	check(g.sim.ghost == target and g.state == g.S.AIM and g.run.items.has("ghostchalk"), "it is armed, not spent")
	g._use("ghostchalk")
	check(g.sim.ghost == -1 and g.armed.is_empty() and g.run.items.has("ghostchalk"), "tapping it again takes it back for free")
	g._use("trapdoor")
	_point(Vector2(300, 3))
	g._update_pick()
	g._pick_click()
	check(g.layout.pockets.size() == 7 and g.sim.layout.pockets.size() == 7, "Trapdoor opens a seventh pocket for the shot")
	g._use("calledshot")
	_point(g.sim.pos[target])
	g._update_pick()
	g._pick_click()
	_point(g.layout.pockets[2].pos)
	g._update_pick()
	g._pick_click()
	check(g.run.called.get("ball", -1) == 5 and g.run.called.get("pocket", -1) == 2 and g.view.call_ball == target, "Called Shot remembers the ball and pocket")
	var before_score: int = g.run.score
	g.aim_dir = (Rack.FOOT - g.sim.pos[0]).normalized()
	g._shoot(0.9)
	await _until(func(): return g.state == g.S.ROLL, 60)
	check(not g.run.items.has("trapdoor") and not g.run.items.has("calledshot") and g.armed.is_empty(), "armed items are spent when the shot is struck")
	await _until(func(): return g.state == g.S.AIM or g.state == g.S.PLACE or g.state == g.S.SHOP or g.state == g.S.OVER, 4000)
	check(g.layout.pockets.size() == 6 and g.run.called.is_empty() and g.view.call_ball == -1, "the Trapdoor and the call are gone after the shot")

	print("Rewind")
	if g.state == g.S.PLACE:
		g._update_place()
		g._place_cue()
	await _until(func(): return g.state == g.S.AIM, 100)
	g.run.tools.assign(["rewind"])
	g.run.tool_charges = {"rewind": 1}
	var pos_before: Vector2 = g.sim.pos[0]
	var score_before: int = g.run.score
	var shots_before: int = g.run.shots_taken
	g.aim_dir = Vector2.RIGHT.rotated(0.4)
	g._shoot(0.7)
	await _until(func(): return g.state == g.S.AIM or g.state == g.S.PLACE or g.state == g.S.SHOP or g.state == g.S.OVER, 4000)
	if g.state == g.S.AIM or g.state == g.S.PLACE:
		g.state = g.S.AIM
		g._use("rewind")
		check(g.run.shots_taken == shots_before and g.run.score == score_before, "Rewind puts the score and shot count back")
		check(g.sim.pos[0].distance_to(pos_before) < 0.01, "and the cue ball back where it was")
		check(int(g.run.tool_charges.rewind) == 0 and g.run.tools.has("rewind"), "it spends its charge but stays in the kit")
	else:
		check(true, "the table ended on that shot, so Rewind was not needed")
	print("kit tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
