extends SceneTree
## The shop footer stays reachable and dense score labels remain legible.

var failures := 0

func check(ok: bool, message: String) -> void:
	print("  ", "ok  " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func _initialize() -> void:
	call_deferred("_go")

func _go() -> void:
	var g: Node = load("res://main.tscn").instantiate()
	root.add_child(g)
	for i in 3:
		await process_frame
	g._new_run()
	for i in 3:
		await process_frame
	var base_value: int = g._ball_one_x_value(1)
	g.run.hot_pocket = 0
	check(g._ball_one_x_value(1) == base_value, "1× value excludes the hot-pocket multiplier")
	g.run.heat = 3
	check(g._ball_one_x_value(1) > base_value, "1× value includes current Heat")
	g.run.hot_pocket = -1
	g.run.heat = 0
	g._toggle_ball_values()
	g._update_ball_values(1.0)
	var live := 0
	for i in g.sim.count():
		if g.sim.alive[i] == 1 and g.sim.num[i] != 0:
			live += 1
	check(g.score_values_layer.visible and g.score_values_layer.placed.size() == live, "all live object balls receive a 1× score label")
	var dense: Array = []
	for n in 15:
		dense.append({"anchor": Vector2(900 + (n % 5) * 3, 400 + int(n / 5) * 3), "number": n + 1, "text": "+%d" % (20 + n), "color": Color.WHITE})
	var badges := BallScoreOverlay.place(dense, Rect2(352, 0, 1248, 706), g.F_NUM)
	var clear := badges.size() == dense.size()
	for i in badges.size():
		clear = clear and badges[i].rect.end.y < badges[i].anchor.y
		for j in range(i + 1, badges.size()):
			clear = clear and not badges[i].rect.intersects(badges[j].rect)
	check(clear, "crowded balls get distinct labels above them")
	for e in dense:
		e.anchor = Vector2(386 + (e.number % 5) * 3, 95 + int(e.number / 5) * 3)
	var edge_badges := BallScoreOverlay.place(dense, Rect2(352, 0, 1248, 706), g.F_NUM)
	check(edge_badges.size() == dense.size(), "crowded balls near the top edge keep every label")
	for wide in [false, true]:
		g.run.intro = true
		g.run.table_index = 0
		g.settings.screen_layout = 1 if wide else 0
		g.debug_window = Vector2i(2400, 1080) if wide else Vector2i(1600, 900)
		g._apply_screen_layout()
		g._show_shop([["Table cleared", 4]])
		for i in 3:
			await process_frame
		var panels: Array = g.overlay.get_children().filter(func(c): return c is PanelContainer and not c.is_queued_for_deletion())
		var panel: PanelContainer = panels.back() if not panels.is_empty() else null
		if panel == null:
			failures += 1
			continue
		var go: Button = panel.find_child("next_table_button", true, false)
		var scroll: ScrollContainer = panel.find_child("shop_scroll", true, false)
		var remove_buttons: Array = panel.find_children("*", "Button", true, false).filter(func(b): return b.text.begins_with("Remove a ball"))
		check(g.run.shop.size() == 9 and remove_buttons.size() == 1 and remove_buttons[0].visible, "%s shop shows nine offers and ball removal" % ("wide" if wide else "classic"))
		check(panel.get_global_rect().end.y <= g.fit.view.y - 8 and go.get_global_rect().end.y <= g.fit.view.y - 8, "%s shop and Next table fit the canvas" % ("wide" if wide else "classic"))
		var long_content := Control.new()
		long_content.custom_minimum_size.y = 900
		scroll.get_child(0).add_child(long_content)
		for i in 3:
			await process_frame
		check(scroll.get_v_scroll_bar().max_value > scroll.size.y and go.get_global_rect().end.y <= g.fit.view.y - 8, "%s long shop content scrolls without hiding Next table" % ("wide" if wide else "classic"))
	print("shop and values tests: %d failures" % failures)
	quit(1 if failures else 0)
