extends SceneTree
## Classic and Wide screen layouts: geometry, and the running game following it.

var failures := 0

const PIXEL_8 := Vector2(2400, 1080)
const HOLE := 110.0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func _initialize() -> void:
	call_deferred("_go")


func _go() -> void:
	_geometry()
	await _in_game()
	print("layout tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)


func _geometry() -> void:
	var c := ScreenFit.solve(PIXEL_8, false, HOLE)
	check(not c.wide and c.table_offset == Vector2.ZERO, "Classic leaves the table where it was")

	var w := ScreenFit.solve(PIXEL_8, true, HOLE)
	check(w.wide and w.view == Vector2(2000, 900), "Wide on a Pixel 8 uses the whole 20:9 screen")
	var table := Rect2(ScreenFit.TABLE_BOX.position + w.table_offset, ScreenFit.TABLE_BOX.size)
	check(absf(table.get_center().x - 1000.0) <= 0.5, "table is centred across the screen")
	check(absf(table.get_center().y - 450.0) <= 0.5, "table is centred down the screen")
	check(w.panel_pos.x >= HOLE, "score panel clears a camera hole on the left")
	check(w.perks_pos.x + w.perks_size.x <= 2000.0 - HOLE + 0.5, "Elements clear a camera hole on the right")
	check(w.panel_pos.x + w.panel_size.x <= table.position.x, "score panel does not cover the table")
	check(w.perks_pos.x >= table.end.x, "Elements do not cover the table")

	check(not ScreenFit.solve(Vector2(1600, 900), true, 0.0).wide, "16:9 screens have nothing to widen")
	check(not ScreenFit.solve(Vector2(1600, 1000), true, 0.0).wide, "taller screens stay Classic")
	check(not ScreenFit.solve(Vector2(1900, 900), true, 200.0).wide, "too little room falls back to Classic")
	var ultra := ScreenFit.solve(Vector2(3440, 1440), true, 0.0)
	check(ultra.panel_size.x == ScreenFit.MAX_PANEL, "ultrawide panels stop growing")
	check(absf(ultra.panel_pos.x + ultra.panel_size.x + ScreenFit.GAP - (ScreenFit.TABLE_BOX.position.x + ultra.table_offset.x)) < 0.5, "ultrawide panels stay beside the table")


func _in_game() -> void:
	var g: Node = load("res://main.tscn").instantiate()
	g.debug_window = Vector2i(PIXEL_8)
	g.debug_hole = HOLE
	root.add_child(g)
	await process_frame
	g.settings.screen_layout = 1
	g._apply_settings()
	await process_frame
	await process_frame
	check(g.fit.wide, "the game switches to Wide")
	check(root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_EXPAND, "the bars are gone in Wide")
	check(g.room_rect.size == Vector2(2000, 900), "the room fills the wider screen")
	check(g.view.position == g.TABLE_ORIGIN + g.fit.table_offset, "the table moved")

	# A touch on the table must still land on the same table spot.
	g.mouse_pos = g.view.base_position + Vector2(300, 200) * g.TABLE_SCALE
	check(((g.mouse_pos - g.view.base_position) / g.TABLE_SCALE).is_equal_approx(Vector2(300, 200)), "touches map onto the moved table")

	g._new_run()
	g.run.perks.assign(["golden", "bank", "catalyst", "heat", "streak", "ricochet"])
	g._rebuild_cards()
	await process_frame
	await process_frame
	check(g.perk_row.get_child_count() == 6, "six Element slots in the column")
	check(g.perk_row.vertical, "Elements are stacked in Wide")
	var perks_bottom: float = g.bottom_bar.position.y + g.bottom_bar.size.y
	check(perks_bottom <= 900.0, "the Element column fits on screen (%.0f)" % perks_bottom)
	var panel_bottom: float = g.left_panel.position.y + g.left_panel.size.y * g.left_panel.scale.y
	check(panel_bottom <= 900.0, "the score panel fits on screen (%.0f)" % panel_bottom)

	g._show_settings(g._show_title)
	await process_frame
	await process_frame
	var settings_panel: Control = _first_panel(g.overlay)
	check(absf(settings_panel.position.x + settings_panel.size.x * 0.5 - 1000.0) <= 1.0, "pop-ups centre on the wider screen")

	g.settings.screen_layout = 0
	g._apply_settings()
	await process_frame
	await process_frame
	check(not g.fit.wide and root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP, "switching back restores Classic")
	check(g.view.position == g.TABLE_ORIGIN, "the table returns to its Classic spot")
	check(not g.perk_row.vertical, "Elements return to a row")
	check(g.bottom_bar.size == Vector2(1226, 174), "the Element bar shrinks back")
	check(absf(settings_panel.position.x + settings_panel.size.x * 0.5 - 800.0) <= 1.0, "an open pop-up follows the change")

	g.settings.screen_layout = 1
	g._save_settings()
	var fresh := GameSettings.new()
	fresh.load_file()
	check(fresh.screen_layout == 1, "the choice is saved")
	fresh.reset()
	check(fresh.screen_layout == 0, "Defaults resets it on desktop")
	g.settings.reset()
	g._save_settings()
	g.queue_free()
	await process_frame


func _first_panel(n: Node) -> Control:
	for c in n.get_children():
		if c is PanelContainer:
			return c
	return null
