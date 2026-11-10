extends SceneTree
## The prediction line is never taken away, follows the struck ball's colour, and
## can show where every ball will land.

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


func _load_table(boss: String) -> void:
	g._new_run()
	var b: Dictionary = Catalog.BOSSES[boss]
	g.run.plan[0].id = boss
	g.run.plan[0].lab = b.lab
	g.run.plan[0].anomaly = b.anomaly
	g.run.begin_table()
	g._setup_table()
	g._enter_aim()
	await _frames(3)


func _aim_at(number: int) -> void:
	var s: PoolSim = g.sim
	s.pos[0] = Vector2(300, 250)
	var i := s.index_of(number)
	for k in s.count():
		if k != 0 and k != i:
			s.alive[k] = 0
	s.pos[i] = Vector2(600, 250)
	g.view.update_balls(s)
	g.fine_aim = true
	g.aim_dir = Vector2.RIGHT
	g.guide_dirty = true
	await _frames(3)


func _go() -> void:
	g = load("res://main.tscn").instantiate()
	root.add_child(g)
	await _frames(3)
	for boss in Catalog.BOSSES:
		await _load_table(boss)
		await _aim_at(5)
		var guide: Dictionary = g.view.guide
		check(guide.has("aim") and guide.has("ghost") and guide.has("obj") and guide.has("cue"), "%s shows the whole prediction line" % boss)
	var hides := ["guideline stops", "guideline ignores", "never turn gold", "show no value"]
	for boss in Catalog.BOSSES:
		for phrase in hides:
			check(not Catalog.BOSSES[boss].desc.contains(phrase), "%s does not hide the line" % boss) if Catalog.BOSSES[boss].desc.contains(phrase) else null

	await _load_table("local")
	await _aim_at(6)
	check(g.view.guide.obj_number == 6, "the line knows which ball it is following")
	g.settings.guide_lines = 0
	g.guide_dirty = true
	await _frames(3)
	check(g.view.forecast_paths.is_empty(), "Standard shows no extra lines")

	g.run.perks.clear()
	await _load_table("local")
	g.fine_aim = true
	g.settings.guide_lines = 1
	g.power = 0.8
	var s: PoolSim = g.sim
	g.aim_dir = (s.pos[s.index_of(1)] - s.pos[0]).normalized()
	g.guide_dirty = true
	await _frames(400)
	var paths: Array = g.view.forecast_paths
	check(paths.size() >= 4, "All balls draws a path for each ball that moves (%d)" % paths.size())
	check(paths.filter(func(p): return p.end or p.potted).size() == paths.size(), "and every path ends where the ball finishes")
	var clone: PoolSim = s.clone()
	clone.strike(g.aim_dir, g._speed(g._current_power()), 0.0, 0.0)
	clone.settle()
	var worst := 0.0
	var cue_path: Dictionary = {}
	for p in paths:
		if p.color == Color(1, 1, 1).lightened(0.25):
			cue_path = p
	if not cue_path.is_empty() and clone.alive[0] == 1:
		worst = (cue_path.points[cue_path.points.size() - 1] as Vector2).distance_to(clone.pos[0])
	check(not cue_path.is_empty() and worst < 1.0, "the predicted cue ball lands exactly where the shot will (%.2f off)" % worst)
	g.settings.guide_lines = 0
	g.guide_dirty = true
	await _frames(3)
	check(g.view.forecast_paths.is_empty(), "turning it off clears the lines")

	g.run.perks.assign(["oracle"])
	g.guide_dirty = true
	await _frames(400)
	check(g.view.forecast_text.begins_with("This shot:"), "Second Sight previews the shot (%s)" % g.view.forecast_text)
	check(g.view.forecast_paths.is_empty(), "without needing the extra lines")
	g.run.perks.clear()

	await _load_table("tilted")
	await _aim_at(5)
	await _frames(60)
	check(g.view.forecast_paths.size() > 0, "a sloped table draws the real curved path")

	await _load_table("smoke")
	g.follow = 1.0
	g.side = 0.5
	await _aim_at(5)
	check(g._shot_follow() == 0.0 and g._shot_side() == 0.0, "The Smoke Room allows no spin")
	await _load_table("lights")
	check(g.run.hot_pocket == -1, "Lights Out has no hot pocket")
	for k in 40:
		g.run.begin_table()
		check(g.run.bounty != "hot" and g.run.bounty != "hot2", "no hot-pocket side bet without a hot pocket") if g.run.bounty == "hot" or g.run.bounty == "hot2" else null

	var fresh := GameSettings.new()
	check(fresh.guide_lines == 1, "All balls is the default")
	print("guideline tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
