extends SceneTree
## Keyboard rebinding, gamepad play, menu navigation, pause and accessibility.

var failures := 0
var g: Node


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func _initialize() -> void:
	call_deferred("_go")


func _key(k: int) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.pressed = true
	root.push_input(e)


func _pad(b: int) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	e.pressed = true
	root.push_input(e)


func _stick(axis: int, v: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = v
	root.push_input(e)


func _tap(p: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = p
	e.global_position = p
	root.push_input(e)


func _tap_move(p: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p
	e.global_position = p
	root.push_input(e)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _go() -> void:
	create_timer(120.0).timeout.connect(func(): quit(2))
	root.size = Vector2i(1600, 900)
	g = load("res://main.tscn").instantiate()
	root.add_child(g)
	await _frames(2)
	print("rebinding")
	var s: GameSettings = g.settings
	check(s.keys.shoot == KEY_SPACE and s.action_for(KEY_W) == "spin_up", "default bindings")
	s.bind("shoot", KEY_B)
	check(s.keys.shoot == KEY_B, "rebind works")
	s.bind("shoot", KEY_W)
	check(s.keys.shoot == KEY_W and s.keys.spin_up == KEY_B, "duplicate keys swap instead of clashing")
	s.save_file()
	var s2 := GameSettings.new()
	s2.load_file()
	check(s2.keys.shoot == KEY_W, "bindings persist")
	s.reset_keys()
	g.controls_back = g._show_title
	g._show_controls()
	await _frames(2)
	g.rebinding = "fine"
	_key(KEY_G)
	await _frames(2)
	check(s.keys.fine == KEY_G and g.rebinding == "", "the Controls screen captures a key press")
	s.reset_keys()
	s.save_file()
	print("keyboard play")
	g._new_run()
	await _frames(2)
	g.run.plan[0].target = 1000000
	s.bind("shoot", KEY_B)
	var p0: float = g.power
	_key(KEY_UP)
	await _frames(1)
	check(g.power > p0 or p0 >= 1.0, "power key works")
	_key(KEY_SPACE)
	await _frames(1)
	check(g.state == g.S.AIM, "old shoot key no longer fires")
	_key(KEY_B)
	await _frames(1)
	check(g.state == g.S.STRIKE or g.state == g.S.ROLL, "rebound key fires")
	s.reset_keys()
	await _settle()
	print("gamepad")
	g._new_run()
	await _frames(2)
	g.run.plan[0].target = 1000000
	var a0: Vector2 = g.aim_dir
	_stick(JOY_AXIS_LEFT_X, 1.0)
	await _frames(10)
	check(g.aim_dir.angle_to(a0) != 0.0 and g.pad_active, "left stick aims")
	_stick(JOY_AXIS_LEFT_X, 0.0)
	var pw: float = g.power
	_stick(JOY_AXIS_RIGHT_Y, 1.0)
	await _frames(10)
	check(g.power < pw, "right stick sets power")
	_stick(JOY_AXIS_RIGHT_Y, 0.0)
	_pad(JOY_BUTTON_DPAD_UP)
	await _frames(1)
	check(g.follow > 0.0, "D-pad sets spin")
	_pad(JOY_BUTTON_X)
	await _frames(1)
	check(g.follow == 0.0, "X resets spin")
	_pad(JOY_BUTTON_Y)
	await _frames(1)
	check(g.info_open, "Y opens run info")
	g._close_run_info()
	await _frames(1)
	_pad(JOY_BUTTON_START)
	await _frames(1)
	check(g.paused, "Start pauses")
	g._resume()
	await _frames(1)
	_pad(JOY_BUTTON_A)
	await _frames(1)
	check(g.state == g.S.STRIKE or g.state == g.S.ROLL, "A shoots")
	await _settle()
	print("menus")
	g.pad_active = false
	g._show_title()
	await _frames(3)
	check(root.gui_get_focus_owner() == null, "no focus ring for mouse users")
	_key(KEY_DOWN)
	await _frames(1)
	check(root.gui_get_focus_owner() is Button, "arrow key starts menu navigation")
	var first: Control = root.gui_get_focus_owner()
	_key(KEY_DOWN)
	await _frames(1)
	check(root.gui_get_focus_owner() != first, "arrow moves between buttons")
	g.nav_active = false
	print("pause")
	g._new_run()
	await _frames(2)
	g.run.plan[0].target = 1000000
	g._shoot(1.0)
	await _frames(12)
	check(g.state == g.S.ROLL, "ball is rolling")
	g._show_pause()
	var t0: float = g.sim.time
	await _frames(20)
	check(g.sim.time == t0 and g.paused, "pause freezes the simulation mid-shot")
	g._resume()
	await _frames(5)
	check(g.sim.time > t0, "resume continues")
	await _settle()
	g._show_shop([["Table cleared", 3]])
	await _frames(2)
	g._show_pause()
	await _frames(2)
	check(g.paused, "can pause from the shop")
	g._resume()
	await _frames(2)
	check(not g.paused and g.state == g.S.SHOP and g.overlay.get_child_count() > 0, "resume returns to the shop")
	print("shop safety")
	g._new_run()
	await _frames(2)
	g.run.perks.assign(["bank", "odd"])
	g._show_shop([["Table cleared", 3]])
	await _frames(2)
	var mny: int = g.run.money
	g._sell_click("bank")
	check(g.run.perks.has("bank") and g.run.money == mny and g.sell_armed == "bank", "first click only arms the sale")
	g._sell_click("odd")
	check(g.run.perks.has("odd") and g.sell_armed == "odd", "arming another card does not sell the first")
	g._sell_click("odd")
	check(not g.run.perks.has("odd") and g.run.money > mny and g.run.perks.has("bank"), "second click sells only that card")
	print("ball in hand")
	g._new_run()
	await _frames(2)
	var ci: int = g._cue_index()
	g.sim.alive[ci] = 0
	g._begin_place(true)
	g.mouse_pos = g.view.base_position + Vector2(900, 250) * g.TABLE_SCALE
	await _frames(2)
	check(g.view.place_pos.x <= Rack.HEAD.x, "scratch on the break: behind the head string")
	g._begin_place(false)
	g.mouse_pos = g.view.base_position + Vector2(500, 250) * g.TABLE_SCALE
	await _frames(2)
	check(g.view.place_pos.x > Rack.HEAD.x, "other scratches: anywhere")
	check(g.sim.alive[ci] == 0, "pot hints do not disturb the table")
	print("touch")
	s.reset()
	s.touch_mode = true
	g._apply_settings()
	g._new_run()
	await _frames(2)
	g.run.plan[0].target = 1000000
	check(g.touch_box.visible and g.menu_btn.visible and not g.lbl_hint.visible, "touch controls appear")
	var cue_scr: Vector2 = g.view.base_position + g.sim.pos[g._cue_index()] * g.TABLE_SCALE
	var before_aim: Vector2 = g.aim_dir
	_tap_move(cue_scr + Vector2(0, -200))
	await _frames(2)
	check(g.aim_dir == before_aim, "no aim change without a finger down")
	_tap(cue_scr + Vector2(0, -200), true)
	await _frames(2)
	check(g.aim_dir.y < -0.9, "finger aims the shot (%s)" % g.aim_dir)
	_tap(cue_scr + Vector2(0, -200), false)
	await _frames(2)
	check(g.state == g.S.AIM and not g.dragging, "lifting the finger does not shoot")
	var locked: Vector2 = g.aim_dir
	_tap_move(cue_scr + Vector2(200, 0))
	await _frames(2)
	check(g.aim_dir == locked, "aim stays put after lifting")
	g.power_slider.value = 0.42
	check(is_equal_approx(g.power, 0.42), "slider sets power")
	var a2: Vector2 = g.aim_dir
	g._step_aim(1.0)   # what a tap of the touch arrow button does
	var moved_deg: float = rad_to_deg(absf(g.aim_dir.angle_to(a2)))
	check(absf(moved_deg - 1.0) < 0.01, "a tap of a nudge button turns exactly 1 degree (%.2f deg)" % moved_deg)
	var ci2: int = g._cue_index()
	g.sim.alive[ci2] = 0
	g._begin_place(false)
	var drop_at: Vector2 = g.view.base_position + Vector2(500, 120) * g.TABLE_SCALE
	_tap(drop_at + Vector2(90, 90), true)
	await _frames(2)
	check(g.state == g.S.PLACE, "ghost ball waits while the finger is down")
	_tap_move(drop_at)
	await _frames(2)
	_tap(drop_at, false)
	await _frames(2)
	check(g.state == g.S.AIM and g.sim.alive[ci2] == 1 and g.sim.pos[ci2].distance_to(Vector2(500, 120)) < 2.0, "lifting places the cue ball where the finger was")
	g.sim.alive[ci2] = 0
	_tap(drop_at, true)
	g._begin_place(false)
	_tap(drop_at + Vector2(40, 0), false)
	await _frames(2)
	check(g.state == g.S.PLACE, "a stale finger-lift cannot place the ball")
	g.sim.alive[ci2] = 1
	g.state = g.S.AIM
	g.view.placing = false
	g.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _frames(1)
	check(g.paused, "Android back opens the menu")
	g.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await _frames(1)
	check(not g.paused, "Android back closes it again")
	# Hints are visible on phones, in touch words.
	g._hint("Ball in hand: gold lines show the sinks on from here. Click to place.")
	check(g.touch_hint.visible and g.touch_hint.text.ends_with("Drag, then lift to place."), "hints show on touch screens, worded for a finger")
	check(not g._touch_words("Called Shot: click the ball you're calling. Right-click or Esc to cancel.").contains("lick"), "no mouse words left in a touch hint")
	g.is_break = true
	await _frames(1)
	check(g.touch_place.visible, "a Move cue ball button on the break")
	g.is_break = false
	await _frames(1)
	check(not g.touch_place.visible, "and only on the break")
	# Item picks get a CANCEL button.
	g._begin_pick("portal", "spot")
	await _frames(1)
	check(g.touch_shoot.text == "CANCEL", "picking with an item turns SHOOT into CANCEL")
	g.touch_shoot.pressed.emit()
	await _frames(1)
	check(g.state == g.S.AIM, "and CANCEL backs out")
	# A long press on a special ball explains it; a passing finger does not.
	var kb: int = -1
	for k in g.sim.count():
		if g.sim.alive[k] == 1 and g.sim.num[k] != 0 and g.sim.num[k] != 8:
			kb = k
			break
	g.run.imbues[g.sim.num[kb]] = "glass"
	var kb_scr: Vector2 = g.view.base_position + g.sim.pos[kb] * g.TABLE_SCALE
	_tap(kb_scr, true)
	await _frames(2)
	check(not g.hover_shown, "a finger passing over a ball shows nothing")
	g.finger_still = 1.0
	await _frames(2)
	check(g.hover_shown, "holding a finger on an imbued ball explains it")
	_tap(kb_scr, false)
	await _frames(2)
	check(not g.hover_shown, "and lifting hides it")
	g.run.imbues.erase(g.sim.num[kb])
	g.power_slider.value = 0.6
	await _frames(1)
	g._shoot(g.power)
	await _frames(2)
	check(g.state == g.S.STRIKE or g.state == g.S.ROLL, "shoot fires")
	await _settle()
	s.large_text = true
	g._apply_settings()
	g.run.plan[g.run.table_index].anomaly = "onepocket"
	g.run.plan[g.run.table_index].boss = true
	g.run.bounty = "bank2"
	g._refresh_hud()
	g.left_panel.size = Vector2.ZERO
	await _frames(3)
	var lpr: Rect2 = g.left_panel.get_global_rect()
	check(lpr.end.y <= 892.0 and lpr.end.x <= 352.0, "touch side panel fits with large text on a boss table (%s)" % lpr)
	s.reset()
	g._apply_settings()
	print("accessibility")
	s.colorblind = true
	s.number_tags = true
	s.large_text = true
	s.frame_cap = 2
	g._apply_settings()
	check(g.view.colorblind and g.view.number_tags and Engine.max_fps == 60, "options reach the game")
	check(g.view._pot_color() != g.view._edge_color(), "pot and rattle colours differ")
	var lb: Label = g._label("x", 13)
	check(lb.get_theme_font_size("font_size") == 15, "larger text applies")
	Engine.max_fps = 0
	for name in ["settings", "controls", "title", "shop"]:
		match name:
			"settings":
				g._show_settings(g._show_title)
			"controls":
				g._show_controls()
			"title":
				g._show_title()
			"shop":
				g._new_run()
				g._show_shop([["Table cleared", 3]])
		await _frames(4)
		for p in g.overlay.get_children():
			if p is PanelContainer:
				var r: Rect2 = p.get_global_rect()
				check(r.position.y >= 0 and r.end.y <= 900.5, "%s fits with larger text (%s)" % [name, r])
	s.reset()
	g._apply_settings()
	print("input tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)


func _settle() -> void:
	var n := 0
	while g.state != g.S.AIM and g.state != g.S.PLACE and n < 6000:
		n += 1
		g.fast = true
		await process_frame
