extends SceneTree
## End-to-end: drives the real main scene with the AutoPlayer through table
## clears, the shop, a purchase, reagents and a forced game over.

var failures := 0
var g: Node


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func _initialize() -> void:
	call_deferred("_go")


func _go() -> void:
	create_timer(150.0).timeout.connect(func():
		print("WATCHDOG timeout")
		quit(2))
	g = load("res://main.tscn").instantiate()
	root.add_child(g)
	await _frames(30)
	check(g.state == g.S.TITLE, "starts on title (demo running)")
	g._new_run()
	await _frames(2)
	check(g.state == g.S.AIM, "new run enters aim")
	# Make table 1 easy to clear quickly and verify the clear/shop path.
	var cleared := await _play_until(func(): return g.state == g.S.SHOP or g.state == g.S.OVER, 60)
	check(cleared, "table resolves (state %s)" % g.state)
	if g.state == g.S.OVER:
		print("  (lost table 1 - restarting with generous chalk)")
		g._new_run()
		g.run.chalk = 30
		await _play_until(func(): return g.state == g.S.SHOP, 80)
	check(g.state == g.S.SHOP, "reached shop")
	g.run.money = 50
	var bought := false
	for i in g.run.shop.size():
		if g.run.shop[i].type == "formula":
			bought = g.run.buy(i) == ""
			break
	check(bought and g.run.formulas.size() == 1, "bought a formula")
	g._refresh_shop()
	g._next_table()
	await _frames(2)
	check(g.state == g.S.AIM and g.run.table_index == 1, "next table starts")
	# Reagents
	g.run.reagents.assign(["bluechalk", "forecast"])
	g._refresh_hud()
	g._use_reagent(1)
	await _frames(12)
	check(g.run.forecast and g.view.forecast_paths.size() > 0, "forecast draws paths (%d)" % g.view.forecast_paths.size())
	g._use_reagent(0)
	check(g.run.bluechalk, "blue chalk armed")
	# Force a game over: one chalk left, shoot into nothing.
	await _play_until(func(): return g.state == g.S.AIM, 10)
	g.run.chalk = 1
	g.run.score = 0
	var ci: int = g._cue_index()
	g.aim_dir = Vector2(0, -1) if g.sim.pos[ci].y > 250 else Vector2(0, 1)
	# Find a direction that touches nothing so it is a guaranteed foul.
	for k in 72:
		var d := Vector2.RIGHT.rotated(k * TAU / 72.0)
		var h: Dictionary = g.sim.cast(g.sim.pos[ci], d, ci)
		if h.kind == "rail":
			var p2: Vector2 = h.point
			var ok := true
			g.aim_dir = d
			break
	g._shoot(0.08)
	await _play_until(func(): return g.state == g.S.OVER, 20)
	check(g.state == g.S.OVER, "chalk out -> game over (state %s)" % g.state)
	await _frames(100)
	check(g.overlay.get_child_count() > 0, "game over screen shown")
	print("flow tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Plays shots with the AutoPlayer until cond() is true or max_shots elapse.
func _play_until(cond: Callable, max_shots: int) -> bool:
	var shots := 0
	var guard := 0
	while not cond.call() and guard < 20000:
		guard += 1
		match g.state:
			g.S.AIM:
				if shots >= max_shots:
					return cond.call()
				shots += 1
				var shot: Dictionary
				if g.is_break:
					shot = {"dir": (Rack.FOOT - g.sim.pos[g._cue_index()]).normalized(), "power": 1.0}
				else:
					shot = AutoPlayer.choose(g.sim, g.run, 3)
				g.aim_dir = shot.dir
				g.power = shot.power
				g._shoot(shot.power)
				g.fast = true
			g.S.PLACE:
				var p := AutoPlayer.place_spot(g.sim, g.run, RandomNumberGenerator.new())
				g.view.place_pos = p
				g.view.place_ok = true
				g._place_cue()
			g.S.ROLL, g.S.TALLY:
				g.fast = true
		await process_frame
	return cond.call()
