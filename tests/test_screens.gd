extends SceneTree
## Every overlay screen must lay out on-screen: panels inside 1600x900 and the
## first label visible. Guards against panels ballooning or drifting off-screen.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func _initialize() -> void:
	call_deferred("_go")


func _panels(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is PanelContainer:
			out.append(c)
		else:
			_panels(c, out)


func _go() -> void:
	create_timer(90.0).timeout.connect(func(): quit(2))
	root.size = Vector2i(1600, 900)
	var g: Node = load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	var screens := {
		"title": func(): g._show_title(),
		"cue select": func(): g._show_cue_select(),
		"help": func(): g._show_help(),
		"settings": func(): g._show_settings(g._show_title),
		"pause": func():
			g._new_run()
			g._show_pause(),
		"shop": func():
			g.paused = false
			g._clear_overlay()
			g._show_shop([["Table cleared", 3]]),
		"run info": func():
			g._clear_overlay()
			g.paused = false
			g.state = g.S.AIM
			g.run.formulas.assign(["golden", "bank", "catalyst", "heat", "streak"])
			g.run.reagents.assign(["bluechalk", "forecast"])
			g.run.isotopes = {3: "neon", 11: "glass"}
			g._show_run_info(),
		"game over": func():
			g._close_run_info()
			g._show_game_over(),
		"victory": func(): g._show_victory([["Table cleared", 5]]),
	}
	for name in screens:
		screens[name].call()
		for i in 4:
			await process_frame
		var panels: Array = []
		_panels(g.overlay, panels)
		var top: Array = panels.filter(func(p): return p.get_parent() == g.overlay)
		check(top.size() >= 1, "%s shows a panel" % name)
		for p in top:
			var r: Rect2 = p.get_global_rect()
			var inside := r.position.x >= 0 and r.position.y >= 0 and r.end.x <= 1600.5 and r.end.y <= 900.5
			check(inside and r.size.y > 80, "%s panel on-screen %s" % [name, r])
	# The HUD side panel must fit on screen with a full build (5 formulas, streak, flags).
	g._clear_overlay()
	g.paused = false
	g.run.bluechalk = true
	g.run.forecast = true
	g.run.streak = 4
	g._refresh_hud()
	for i in 3:
		await process_frame
	var lp: Rect2 = g.left_panel.get_global_rect()
	check(lp.end.y <= 890.0, "side panel fits on screen (bottom %.0f)" % lp.end.y)
	var hint_bottom: float = g.lbl_hint.get_global_rect().end.y
	check(hint_bottom <= 890.0, "hint text visible (bottom %.0f)" % hint_bottom)
	# Tab toggles run info from aim and returns to aim.
	g._clear_overlay()
	g.paused = false
	g.info_open = false
	g.state = g.S.AIM
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	root.push_input(tab)
	await process_frame
	check(g.info_open and g.paused, "Tab opens run info and pauses")
	root.push_input(tab)
	await process_frame
	check(not g.info_open and not g.paused and g.state == g.S.AIM, "Tab closes run info back to aim")
	RunState.clear_save()
	print("screens tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
