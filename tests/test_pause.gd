extends SceneTree
## Pausing a shot mid-roll: planned pause points, a prediction that is exact from
## the paused moment, and the pause items that change the shot.

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


func _point_mouse(p: Vector2) -> void:
	g.mouse_pos = g.view.base_position + p * g.TABLE_SCALE


func _fresh_shot() -> void:
	g._new_run()
	await _until(func(): return g.state == g.S.AIM, 200)
	await _frames(3)
	g.coaching = false
	g.fine_aim = true
	g.aim_dir = (Rack.FOOT - g.sim.pos[0]).normalized()
	g.guide_dirty = true
	await _frames(2)


func _go() -> void:
	check(Catalog.PERKS.size() == 100, "100 Perks (%d)" % Catalog.PERKS.size())
	g = load("res://main.tscn").instantiate()
	root.add_child(g)
	await _frames(3)

	print("pause at a set time, and the prediction from there is exact")
	await _fresh_shot()
	g.pause_at = 0.35
	g._shoot(0.9)
	await _until(func(): return g.state == g.S.HOLD, 300)
	check(g.state == g.S.HOLD and g.sim.time >= 0.35 and g.sim.time < 0.4, "the shot pauses at the planned moment (%.3f)" % g.sim.time)
	check(g.sim.moving(), "with the balls still moving")
	await _until(func(): return g.fc_sim == null, 400)
	var paths: Array = g.view.forecast_paths
	check(paths.size() > 3, "the prediction from the paused moment shows every moving ball (%d)" % paths.size())
	var predicted := {}
	for i in g.fc_paths:
		predicted[i] = g.fc_paths[i][g.fc_paths[i].size() - 1]
	var truth: PoolSim = g.sim.clone()
	truth.settle()
	var worst := 0.0
	for i in predicted:
		if truth.alive[i] == 1:
			worst = maxf(worst, (predicted[i] as Vector2).distance_to(truth.pos[i]))
	check(worst < 0.5, "and every ball ends where it really will (%.3f off)" % worst)

	print("pause items")
	g.run.items.assign(["blink", "wall"])
	g.run.tools.assign(["secondstrike"])
	g.run.tool_charges = {"secondstrike": 1}
	g.run.perks.assign(["stillness", "afterimage", "quickhands"])
	var ci: int = g._cue_index()
	var target: Vector2 = g.sim.pos[ci] + Vector2(0, -200)
	g._use("secondstrike")
	check(g.hold_action == "strike", "Second Strike waits for an aim")
	_point_mouse(target)
	g.power = 0.5
	g._hold_click()
	var v: Vector2 = g.sim.vel[ci]
	check(v.length() > 100.0 and v.normalized().dot((target - g.sim.pos[ci]).normalized()) > 0.99, "Second Strike sends the cue ball where you aimed")
	check(int(g.run.tool_charges.secondstrike) == 0, "Second Strike spends its Tool charge")
	var blink_to := Vector2(150, 120)
	var speed_before: float = g.sim.vel[ci].length()
	g._use("blink")
	_point_mouse(blink_to)
	g._hold_click()
	check(g.sim.pos[ci].distance_to(blink_to) < 0.01 and absf(g.sim.vel[ci].length() - speed_before) < 0.01, "Blink moves the cue ball and keeps its speed")
	check(g.run.items.has("blink"), "Quick Hands keeps the first mid-shot Consumable")
	var segs: int = g.sim.layout.segments.size()
	g._use("wall")
	_point_mouse(Vector2(600, 100))
	g._hold_click()
	_point_mouse(Vector2(600, 260))
	g._hold_click()
	check(g.sim.layout.segments.size() == segs + 2 and g.view.temp_walls.size() == 1, "Pop-up Wall adds a real wall")
	check(not g.run.items.has("wall"), "and a second Consumable is used up")
	var boosts: Array = g.sim.events.filter(func(e): return e.type == "boost")
	check(boosts.size() >= 2, "Afterimage adds Chain for Second Strike and Blink (%d)" % boosts.size())
	g._play_on()
	check(g.state == g.S.ROLL, "play resumes")
	await _until(func(): return g.state == g.S.AIM or g.state == g.S.PLACE or g.state == g.S.SHOP or g.state == g.S.OVER, 4000)
	check(g.view.temp_walls.is_empty() and g.layout.segments.size() == segs, "the wall is gone after the shot")

	print("plan a pause on the prediction")
	await _fresh_shot()
	g.run.perks.clear()
	g._toggle_plan()
	g.forecast_timer = 0.0
	await _frames(2)
	await _until(func(): return g.fc_sim == null and g.fc_paths.has(0), 300)
	var cue_path: PackedVector2Array = g.fc_paths[0]
	var mid := cue_path[cue_path.size() / 3]
	_point_mouse(mid)
	g._update_plan_hover()
	g._set_pause_point()
	check(g.pause_at > 0.0 and g.view.plan_marker != Vector2.INF, "clicking the locked line sets a pause point")
	g._toggle_plan()
	g._shoot(0.85)
	await _until(func(): return g.state == g.S.HOLD, 400)
	check(g.state == g.S.HOLD and g.sim.pos[0].distance_to(mid) < 12.0, "the shot pauses where it was planned (%.1f away)" % g.sim.pos[0].distance_to(mid))
	g._play_on()
	await _until(func(): return g.state == g.S.AIM or g.state == g.S.PLACE or g.state == g.S.SHOP or g.state == g.S.OVER, 4000)

	print("pause on the first hit")
	await _fresh_shot()
	g.settings.pause_on_hit = true
	g._shoot(0.9)
	await _until(func(): return g.state == g.S.HOLD, 300)
	check(g.state == g.S.HOLD and g.sim.cue_contacted, "the setting pauses the moment the cue ball hits (state %d, contacted %s, pause_at %.2f, auto %s)" % [g.state, g.sim.cue_contacted, g.pause_at, g.auto_paused])
	g._play_on()
	await _until(func(): return g.state != g.S.ROLL and g.state != g.S.STRIKE and g.state != g.S.TALLY, 1500)
	check(g.state != g.S.HOLD, "and only once per shot")
	g.settings.pause_on_hit = false
	print("pause tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
