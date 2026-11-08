extends SceneTree
## Quit mid-table, relaunch, Continue: every ball, the score and chalk must match.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func _initialize() -> void:
	call_deferred("_go")


func _go() -> void:
	create_timer(120.0).timeout.connect(func(): quit(2))
	RunState.clear_save()
	var g: Node = load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g._new_run()
	g.run.plan[0].target = 100000   # stay mid-table
	var shots := 0
	var guard := 0
	while shots < 4 and guard < 20000:
		guard += 1
		if g.state == g.S.AIM:
			var shot: Dictionary
			if g.is_break:
				shot = {"dir": (Rack.FOOT - g.sim.pos[g._cue_index()]).normalized(), "power": 1.0}
			else:
				shot = AutoPlayer.choose(g.sim, g.run, 3)
			g.aim_dir = shot.dir
			g._shoot(shot.power)
			shots += 1
		elif g.state == g.S.PLACE:
			g.view.place_pos = AutoPlayer.place_spot(g.sim, g.run, RandomNumberGenerator.new())
			g.view.place_ok = true
			g._place_cue()
		elif g.state == g.S.SHOP or g.state == g.S.OVER:
			break
		g.fast = true
		await process_frame
	while g.state != g.S.AIM and g.state != g.S.PLACE and g.state != g.S.SHOP and guard < 40000:
		guard += 1
		g.fast = true
		await process_frame
	var before := {"score": g.run.score, "chalk": g.run.chalk, "heat": g.run.heat, "hot": g.run.hot_pocket,
		"money": g.run.money, "state": g.state, "pos": g.sim.pos.duplicate(), "alive": g.sim.alive.duplicate(),
		"next": g.run.rng.randi()}
	print("  played %d shots; score %d chalk %d state %d" % [shots, before.score, before.chalk, before.state])
	g.queue_free()
	await process_frame
	var h: Node = load("res://main.tscn").instantiate()
	root.add_child(h)
	await process_frame
	check(RunState.has_save(), "save exists after quitting mid-table")
	h._continue_run()
	await process_frame
	check(h.run.score == before.score and h.run.chalk == before.chalk and h.run.heat == before.heat, "score/chalk/streak restored")
	check(h.run.hot_pocket == before.hot and h.run.money == before.money, "hot pocket and money restored")
	check(h.sim.pos == before.pos and h.sim.alive == before.alive, "every ball in the same place")
	check(h.state == before.state, "same state (%d vs %d)" % [h.state, before.state])
	check(h.run.rng.randi() == before.next, "run RNG continues identically")
	# Shop: clear the table, quit in the shop, continue into the same shop.
	h.run.score = h.run.target()
	h._table_cleared()
	var guard2 := 0
	while h.state != h.S.SHOP and guard2 < 2000:
		guard2 += 1
		await process_frame
	var offers: Array = h.run.shop.map(func(it): return it.id)
	var money_shop: int = h.run.money
	h.queue_free()
	await process_frame
	var k: Node = load("res://main.tscn").instantiate()
	root.add_child(k)
	await process_frame
	k._continue_run()
	await process_frame
	check(k.state == k.S.SHOP, "continue reopens the shop")
	check(k.run.shop.map(func(it): return it.id) == offers and k.run.money == money_shop, "same offers and money in the shop")
	k._next_table()
	await process_frame
	check(k.state == k.S.AIM and k.run.table_index == 1, "leaving the restored shop starts table 2")
	RunState.clear_save()
	print("continue tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
