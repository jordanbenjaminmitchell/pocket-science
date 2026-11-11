extends SceneTree
## New players meet the game a piece at a time; pauses can be planned on any
## ball's line; Long Lens tags every predicted sink.

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


func _shop_at(table: int, intro: bool) -> Array:
	var r := RunState.new()
	r.start(11)
	r.intro = intro
	r.table_index = table
	r.roll_shop()
	return r.shop.map(func(it): return it.type)


func _go() -> void:
	print("gradual introduction")
	var m := Meta.new()
	check(m.is_intro(), "a new profile starts in the introduction")
	check(not _shop_at(0, true).has("item") and not _shop_at(0, true).has("ball"), "the first shop is Perks and Imbues only")
	check(_shop_at(1, true).has("item") and not _shop_at(1, true).has("ball"), "items arrive in the second shop")
	check(_shop_at(2, true).has("ball"), "special balls arrive in the third")
	check(_shop_at(0, false).has("item") and _shop_at(0, false).has("ball"), "after the introduction everything is there from the start")
	m.lifetime_tables = Meta.INTRO_TABLES
	check(not m.is_intro(), "clearing a few tables ends the introduction")
	m.seen_tips = []
	check(m.first_time("items") and not m.first_time("items"), "each tip shows once")

	g = load("res://main.tscn").instantiate()
	root.add_child(g)
	await _frames(3)
	g._new_run()
	await _until(func(): return g.state == g.S.AIM, 200)
	g.coaching = false
	g.fine_aim = true

	print("plan a pause on another ball's line")
	g.aim_dir = (Rack.FOOT - g.sim.pos[0]).normalized()
	g.power = 0.9
	g.guide_dirty = true
	g._toggle_plan()
	g.forecast_timer = 0.0
	await _frames(2)
	await _until(func(): return g.fc_sim == null and g.fc_paths.size() > 3, 400)
	var other := -1
	for bi in g.fc_paths:
		if bi != 0 and (g.fc_paths[bi] as PackedVector2Array).size() > 12:
			other = bi
			break
	check(other > 0, "the locked prediction has other balls' lines to pick from")
	if other > 0:
		var pts: PackedVector2Array = g.fc_paths[other]
		var spot := pts[pts.size() / 2]
		g.mouse_pos = g.view.base_position + spot * g.TABLE_SCALE
		g._update_plan_hover()
		g._set_pause_point()
		check(g.pause_at > 0.0 and g.view.plan_marker.distance_to(spot) < 1.0, "a pause point can sit on an object ball's line")
		g._toggle_plan()
		g._shoot(0.9)
		await _until(func(): return g.state == g.S.HOLD, 400)
		check(g.state == g.S.HOLD and g.sim.pos[other].distance_to(spot) < 12.0, "and the shot pauses with that ball there (%.1f away)" % g.sim.pos[other].distance_to(spot))
		g._play_on()
		await _until(func(): return g.state != g.S.ROLL and g.state != g.S.STRIKE and g.state != g.S.TALLY, 4000)

	print("Long Lens")
	g._new_run()
	await _until(func(): return g.state == g.S.AIM, 200)
	g.coaching = false
	g.fine_aim = true
	g.run.perks.assign(["lens"])
	var s: PoolSim = g.sim
	s.pos[0] = Vector2(420, 330)
	var obj := s.index_of(1)
	for k in s.count():
		if k != 0 and k != obj:
			s.alive[k] = 0
	s.pos[obj] = Vector2(640, 170)
	var pocket: Vector2 = s.layout.pockets[2].pos
	var od := (pocket - s.pos[obj]).normalized()
	g.aim_dir = ((s.pos[obj] - od * TableLayout.R * 2.0) - s.pos[0]).normalized()
	g.view.update_balls(s)
	g.is_break = false
	g.power = 0.6
	g.guide_dirty = true
	await _until(func(): return g.fc_sim == null and not g.view.sink_tags.is_empty(), 400)
	check(g.view.sink_tags.any(func(t): return t[0] == 2), "Long Lens tags the pocket a ball is predicted to sink into")
	print("ball info on hover")
	g._new_run()
	await _until(func(): return g.state == g.S.AIM, 200)
	g.coaching = false
	g.fine_aim = true
	g.run.imbues = {3: "vein"}
	var i3: int = g.sim.index_of(3)
	g.mouse_pos = g.view.base_position + g.sim.pos[i3] * g.TABLE_SCALE
	await _frames(2)
	check(g.term_tip.panel.visible and g.term_tip.heading.text == "3-ball" and g.term_tip.body.text.contains("Vein"), "hovering an imbued ball explains its Imbue")
	var i8: int = g.sim.index_of(8)
	g.mouse_pos = g.view.base_position + g.sim.pos[i8] * g.TABLE_SCALE
	await _frames(2)
	check(g.term_tip.panel.visible and g.term_tip.heading.text == "8-ball", "hovering the 8 explains it")
	var i5: int = g.sim.index_of(5)
	g.mouse_pos = g.view.base_position + g.sim.pos[i5] * g.TABLE_SCALE
	await _frames(2)
	check(not g.term_tip.panel.visible, "a plain ball shows nothing")
	print("intro tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
