extends Node2D
## Pocket Science — game controller.
## States: TITLE -> AIM <-> PLACE/PICK -> STRIKE -> ROLL -> TALLY -> (AIM | CLEAR -> SHOP | OVER)

enum S { TITLE, AIM, PLACE, PICK, STRIKE, ROLL, TALLY, CLEAR, SHOP, OVER }

const TABLE_ORIGIN := Vector2(445, 99)
const TABLE_SCALE := 1.05
const MAX_SPEED := 2250.0
const MIN_SPEED := 90.0
const DRAG_FULL := 230.0

var F_REG: Font = preload("res://assets/fonts/ChakraPetch-Regular.ttf")
var F_SEMI: Font = preload("res://assets/fonts/ChakraPetch-SemiBold.ttf")
var F_PIX: Font = preload("res://assets/fonts/Silkscreen-Regular.ttf")
var F_PIXB: Font = preload("res://assets/fonts/Silkscreen-Bold.ttf")

var state := S.TITLE
var run := RunState.new()
var layout: TableLayout
var sim: PoolSim
var view: TableView
var sfx: Sfx
var vis_rng := RandomNumberGenerator.new()

# Aiming
var aim_dir := Vector2.RIGHT
var power := 0.55
var follow := 0.0
var side := 0.0
var dragging := false
var drag_origin := Vector2.ZERO
var drag_power := 0.0
var guide_dirty := true
var forecast_dirty := true
var forecast_timer := 0.0
var is_break := true
var place_head_only := false
var fine_aim := false

# Shot in flight
var shot_power := 0.0
var start_pos := {}
var ev_index := 0
var strike_t := 0.0
var fast := false
var last_click_t := -1.0

# Tally
var result := {}
var tally_i := 0
var tally_timer := 0.0
var tally_phase := 0
var shown_chips := 0.0
var shown_mult := 1.0
var shown_score := 0.0
var score_from := 0.0
var score_to := 0.0
var score_t := 1.0

# UI
var ui: CanvasLayer
var root: Control
var lbl_round: Label
var lbl_lab: Label
var lbl_rule: Label
var lbl_boss: Label
var lbl_target: Label
var lbl_score: Label
var score_bar: ProgressBar
var lbl_chips: Label
var lbl_mult: Label
var lbl_line: Label
var lbl_money: Label
var lbl_streak: Label
var chalk_pips: ChalkPips
var spin_w: SpinWidget
var power_w: PowerMeter
var lbl_hint: Label
var lbl_status: Label
var formula_row: HBoxContainer
var reagent_row: HBoxContainer
var overlay: Control
var selected_formula := -1
var banner: Label
var banner_t := 0.0
var flags_label: Label
var log_label: Label
var left_panel: Control
var lbl_bounty: Label
var tray: BallTray
var bottom_bar: Control
var shot_log: Array[String] = []


func _ready() -> void:
	randomize()
	vis_rng.seed = 4242
	sfx = Sfx.new()
	add_child(sfx)
	view = TableView.new()
	view.base_position = TABLE_ORIGIN
	view.home_position = TABLE_ORIGIN
	view.base_scale = TABLE_SCALE
	view.position = TABLE_ORIGIN
	view.scale = Vector2(TABLE_SCALE, TABLE_SCALE)
	add_child(view)
	_build_ui()
	_load_settings()
	_show_title()


## ================================================================ table setup
func _setup_table() -> void:
	var t := run.current()
	layout = TableLayout.new().build(run.pocket_scale(), run.closed_pockets())
	var lab: String = t.lab
	if lab == "cyclotron":
		layout.add_bumper(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.27), 20.0)
		layout.add_bumper(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.73), 20.0)
	view.setup(layout, F_SEMI, F_PIXB)
	view.set_felt(Catalog.LABS[lab].felt)
	_new_rack(t.rack)
	shot_log.clear()
	if log_label:
		log_label.text = ""
	if state != S.TITLE:
		if run.endless:
			sfx.play_music("endless")
		elif t.anomaly != "":
			sfx.play_music("boss")
		else:
			sfx.play_music(lab)
	view.hot_mult = 3 if run.formulas.has("heat") else 2
	view.hot_pocket = run.hot_pocket
	_refresh_hud()


func _make_sim() -> PoolSim:
	var s := PoolSim.new(layout)
	var t := run.current()
	match t.lab:
		"cryo":
			s.roll_decel = 90.0
			s.drag = 0.05
		"spring":
			s.rail_e = 0.92
		"gravity":
			s.well_pos = Vector2(TableLayout.W * 0.5, TableLayout.H * 0.5)
			s.well_strength = 1.0
	if run.formulas.has("magnet"):
		s.pocket_pull = 1.0
	return s


func _new_rack(kind: String) -> void:
	sim = _make_sim()
	sim.add_ball(0, Rack.HEAD)
	var r := RandomNumberGenerator.new()
	r.seed = run.rng.randi()
	Rack.build(sim, kind, r)
	if run.current().anomaly == "lead":
		for i in sim.count():
			if sim.num[i] != 0:
				sim.mass[i] = 1.6
	view.sync_balls(sim, vis_rng, run.isotopes)
	is_break = true
	aim_dir = (Rack.FOOT - Rack.HEAD).normalized()
	power = 0.85
	guide_dirty = true
	forecast_dirty = true


func _cue_index() -> int:
	if sim == null:
		return 0
	var i := sim.index_of(0)
	return i if i >= 0 else 0


## ================================================================ main loop
var paused := false


func _process(delta: float) -> void:
	if paused:
		return
	match state:
		S.TITLE:
			_update_demo(delta)
			view.cue_colors = Catalog.CUES.maple
		S.AIM:
			_update_aim(delta)
		S.PLACE:
			_update_place()
		S.PICK:
			_update_pick()
		S.STRIKE:
			_update_strike(delta)
		S.ROLL:
			_update_roll(delta)
		S.TALLY:
			_update_tally(delta)
	if score_t < 1.0:
		score_t = minf(1.0, score_t + delta * 1.8)
		var e := 1.0 - pow(1.0 - score_t, 3.0)
		shown_score = lerpf(score_from, score_to, e)
		_set_score_label()
	if banner_t > 0.0:
		banner_t -= delta
		var a := clampf(banner_t * 2.0, 0.0, 1.0)
		banner.modulate.a = a
		var s := 1.0 + maxf(0.0, banner_t - 1.6) * 0.6
		banner.scale = Vector2(s, s)
		if banner_t <= 0.0:
			banner.visible = false
	var cue_i := _cue_index()
	view.cue_visible = (state == S.AIM or state == S.STRIKE) and sim != null and sim.alive[cue_i] == 1
	if sim:
		view.cue_pos = sim.pos[cue_i]


var mouse_pos := Vector2(800, 400)


func _input(e: InputEvent) -> void:
	if e is InputEventMouse:
		mouse_pos = e.position


func _mouse_table() -> Vector2:
	return (mouse_pos - view.base_position) / TABLE_SCALE


func _update_aim(delta: float) -> void:
	var ci := _cue_index()
	var m := _mouse_table()
	if dragging:
		var pull := (drag_origin - m).dot(aim_dir)
		drag_power = clampf(pull / (DRAG_FULL * settings.pull), 0.0, 1.0)
		view.cue_pull = drag_power * 90.0
		power_w.set_power(drag_power)
	else:
		if not fine_aim and _mouse_over_table() and m.distance_to(sim.pos[ci]) > 4.0:
			var nd := (m - sim.pos[ci]).normalized()
			if nd.angle_to(aim_dir) != 0.0:
				aim_dir = nd
				guide_dirty = true
		var rot := 0.0
		var spd := (0.06 if Input.is_key_pressed(KEY_SHIFT) else 0.6) * settings.aim_speed
		if Input.is_key_pressed(KEY_LEFT):
			rot -= spd
		if Input.is_key_pressed(KEY_RIGHT):
			rot += spd
		if rot != 0.0:
			aim_dir = aim_dir.rotated(deg_to_rad(rot) * delta * 30.0)
			guide_dirty = true
		view.cue_pull = power * 18.0
		power_w.set_power(power)
	view.cue_dir = aim_dir
	_update_coach()
	if guide_dirty:
		guide_dirty = false
		forecast_dirty = true
		forecast_timer = 0.09
		var fog: bool = run.current().anomaly == "fog"
		view.guide = TableView.compute_guide(sim, aim_dir, follow, side, run.formulas.has("lens"), fog)
		view.show_guide = true
		_update_preview()
	if forecast_dirty and (run.forecast or run.formulas.has("oracle")):
		forecast_timer -= delta
		if forecast_timer <= 0.0:
			forecast_dirty = false
			_compute_forecast()
	elif fc_sim != null:
		_step_forecast()
	elif not (run.forecast or run.formulas.has("oracle")):
		view.forecast_paths = []


var coaching := false
var coach_seen_pot := false


func _update_coach() -> void:
	if not coaching:
		view.coach_text = ""
		return
	var cue: Vector2 = sim.pos[_cue_index()]
	if run.shots_taken == 0:
		view.coach_text = "Press on the table, drag BACK and release to shoot.\nFurther = harder. Break the rack!"
	elif view.guide.get("obj_pot", false) or view.guide.get("obj2_pot", false):
		coach_seen_pot = true
		view.coach_text = "GOLD line = that ball is going in.\nThe tag on the pocket shows the points."
	elif not coach_seen_pot:
		view.coach_text = "Swing your aim until a line turns GOLD.\nThe ring shows where the cue ball hits."
	elif run.streak >= 1:
		view.coach_text = "Streak! Each scoring shot in a row adds +1 Mult.\nThe glowing pocket gives ×2."
	else:
		view.coach_text = ""
	view.coach_pos = cue + Vector2(0, 50 if cue.y < TableLayout.H * 0.6 else -110)


func _mouse_over_table() -> bool:
	var m := _mouse_table()
	return m.x > -90 and m.y > -90 and m.x < TableLayout.W + 90 and m.y < TableLayout.H + 90


func _current_power() -> float:
	return drag_power if dragging else power


func _shot_ctx() -> Dictionary:
	return {
		"formulas": run.formulas, "isotopes": run.isotopes, "hot_pocket": run.hot_pocket,
		"lab": run.current().lab, "streak": run.streak, "power": _current_power(),
		"shots_taken": run.shots_taken, "catalyst": run.catalyst, "bluechalk": run.bluechalk,
	}


func _update_preview() -> void:
	view.preview_text = ""
	view.preview_pocket = -1
	var g := view.guide
	var ball := -1
	var pocket := -1
	var rails := 0
	var combo_by := 0
	if g.get("obj_pot", false):
		ball = sim.num[g.obj_index]
		pocket = g.obj_pocket
		rails = g.get("obj_rails", 0)
	elif g.get("obj2_pot", false):
		ball = sim.num[g.obj2_index]
		pocket = g.obj2_pocket
		combo_by = sim.num[g.obj_index]
	if ball < 0:
		return
	var ev: Array = []
	for i in g.get("rails_before", 0):
		ev.append({"type": "rail", "a": 0})
	if combo_by != 0:
		ev.append({"type": "ball", "a": 0, "b": combo_by})
		ev.append({"type": "ball", "a": combo_by, "b": ball})
	else:
		ev.append({"type": "ball", "a": 0, "b": ball})
	ev.append({"type": "pocket", "a": ball, "pocket": pocket, "rails": rails, "at": Vector2.ZERO})
	var ctx := _shot_ctx()
	ctx["events"] = ev
	var r := Scorer.score(ctx)
	if r.scored:
		view.preview_text = "%s × %s = %d" % [_fmt(r.chips), _fmt(r.mult), r.total]
		view.preview_pocket = pocket


var fc_sim: PoolSim
var fc_paths := {}
var fc_steps := 0
var fc_limit := 12.0


## Starts an incremental forecast; _step_forecast advances it within a frame budget.
func _compute_forecast() -> void:
	fc_sim = sim.clone()
	fc_sim.strike(aim_dir, _speed(_current_power()), follow, side)
	fc_limit = 1.5 if run.formulas.has("oracle") and not run.forecast else 12.0
	fc_paths = {}
	fc_steps = 0
	_step_forecast()


func _step_forecast() -> void:
	if fc_sim == null:
		return
	var t0 := Time.get_ticks_usec()
	while fc_sim.moving() and fc_sim.time < fc_limit and Time.get_ticks_usec() - t0 < 5000:
		fc_sim.step(PoolSim.STEP)
		fc_steps += 1
		if fc_steps % 3 == 0:
			for i in fc_sim.count():
				if fc_sim.alive[i] == 1 and fc_sim.vel[i] != Vector2.ZERO:
					if not fc_paths.has(i):
						fc_paths[i] = PackedVector2Array([sim.pos[i]])
					fc_paths[i].append(fc_sim.pos[i])
	var out: Array = []
	for i in fc_paths:
		var c := Catalog.ball_color(fc_sim.num[i])
		if fc_sim.num[i] == 0:
			c = Color(1, 1, 1)
		var done := not fc_sim.moving() or fc_sim.time >= fc_limit
		out.append({"points": fc_paths[i], "color": c.lightened(0.25), "end": done and fc_sim.alive[i] == 1, "potted": fc_sim.alive[i] == 0})
	view.forecast_paths = out
	if not fc_sim.moving() or fc_sim.time >= fc_limit:
		fc_sim = null


func _speed(p: float) -> float:
	return MIN_SPEED + pow(p, 1.35) * (MAX_SPEED - MIN_SPEED)


func _update_place() -> void:
	var m := _mouse_table()
	var ci := _cue_index()
	m.x = clampf(m.x, TableLayout.R, (Rack.HEAD.x if place_head_only else TableLayout.W - TableLayout.R))
	m.y = clampf(m.y, TableLayout.R, TableLayout.H - TableLayout.R)
	view.placing = true
	view.head_only = place_head_only
	view.place_pos = m
	view.place_ok = sim.is_clear_spot(m, ci)
	view.show_guide = false


func _update_pick() -> void:
	var m := _mouse_table()
	var best := -1
	var bd := 1.0e9
	for k in layout.pockets.size():
		if layout.pockets[k].closed:
			continue
		var d := m.distance_to(layout.pockets[k].pos)
		if d < bd:
			bd = d
			best = k
	view.hover_pocket = best if bd < 160.0 else -1


func _shoot(p: float) -> void:
	if p < 0.02:
		return
	shot_power = p
	strike_t = 0.0
	state = S.STRIKE
	view.show_guide = false
	view.coach_text = ""
	view.forecast_paths = []
	fc_sim = null
	view.preview_text = ""


func _update_strike(delta: float) -> void:
	strike_t += delta
	var pull0 := shot_power * 90.0
	var k := strike_t / 0.09
	view.cue_pull = lerpf(pull0, -6.0, clampf(k, 0.0, 1.0))
	if k >= 1.0:
		_begin_roll()


func _begin_roll() -> void:
	sim_accum = 0.0
	start_pos.clear()
	for i in sim.count():
		if sim.alive[i] == 1:
			start_pos[sim.num[i]] = sim.pos[i]
	sim.strike(aim_dir, _speed(shot_power), follow, side)
	sfx.play("cue", 0.4 + shot_power * 0.8, 0.9 + randf() * 0.2)
	if shot_power > 0.8:
		view.add_shake(3.0 * shot_power)
	ev_index = 0
	fast = false
	state = S.ROLL
	lbl_hint.text = "Click or press Space to fast-forward."


var sim_accum := 0.0


## Fixed-step accumulator: converts real frame time into whole 1/240 s physics
## steps, carrying the remainder, so ball speed is identical at any refresh rate.
## Long frames are clamped (0.1 s) so a hitch cannot trigger a catch-up spiral.
func _sim_steps(delta: float, speed: float = 1.0) -> int:
	sim_accum += minf(delta, 0.1) * speed
	var steps := int(floor(sim_accum / PoolSim.STEP + 1.0e-6))
	sim_accum -= steps * PoolSim.STEP
	return steps


func _update_roll(delta: float) -> void:
	var steps := _sim_steps(delta, 4.0 if fast else 1.0)
	for i in steps:
		sim.step(PoolSim.STEP)
		_consume_events()
		if not sim.moving():
			break
	view.update_balls(sim)
	if run.streak >= 3 and sim.alive[_cue_index()] == 1:
		var cv := sim.vel[_cue_index()]
		if cv.length() > 120.0:
			var heat := clampf((run.streak - 2) / 5.0, 0.2, 1.0)
			view.trail(sim.pos[_cue_index()], Color(1.0, 0.55 - heat * 0.3, 0.1).lerp(Color(0.4, 0.8, 1.0), 0.0), heat)
	if not sim.moving() or sim.time > 30.0:
		if sim.time > 30.0:
			for i in sim.count():
				sim.vel[i] = Vector2.ZERO
				sim.spin[i] = Vector2.ZERO
		_settled()


var demo_timer := 1.5
var demo_rng := RandomNumberGenerator.new()
var demo := false


## Title-screen attract mode: the AutoPlayer runs racks behind the menu.
func _update_demo(delta: float) -> void:
	if sim == null:
		return
	demo = true
	if sim.moving():
		for i in _sim_steps(delta):
			sim.step(PoolSim.STEP)
			_consume_events()
		view.update_balls(sim)
		return
	demo_timer -= delta
	if demo_timer > 0.0:
		return
	demo_timer = 1.4
	var ci := _cue_index()
	if sim.object_balls_left() == 0:
		_new_rack("nine")
		return
	if sim.alive[ci] == 0:
		var p := AutoPlayer.place_spot(sim, run, demo_rng)
		sim.alive[ci] = 1
		sim.pos[ci] = p
		view.ball_nodes[ci].visible = true
		view.ball_nodes[ci].set_fade(1.0)
		view.ball_nodes[ci].roll_to(p)
		return
	var shot := {}
	if is_break:
		shot = {"dir": (Rack.FOOT - sim.pos[ci]).normalized().rotated(demo_rng.randf_range(-0.01, 0.01)), "power": 1.0}
		is_break = false
	else:
		shot = AutoPlayer.choose(sim, run, 3)
	sim.strike((shot.dir as Vector2).rotated(deg_to_rad(demo_rng.randfn(0.0, 0.25))), _speed(shot.power), 0.0, 0.0)
	ev_index = 0
	sfx.play("cue", 0.25)


func _consume_events() -> void:
	while ev_index < sim.events.size():
		var e: Dictionary = sim.events[ev_index]
		ev_index += 1
		match e.type:
			"ball":
				var v := clampf(e.speed / 1600.0, 0.05, 1.0) * (0.3 if demo else 1.0)
				if e.speed > 900.0 and not demo:
					var ia := sim.index_of(e.a)
					var ib := sim.index_of(e.b)
					view.spark((sim.pos[ia] + sim.pos[ib]) * 0.5, clampf(e.speed / 2000.0, 0.3, 1.0))
				sfx.play("click" if v > 0.25 else "click_soft", v, 0.9 + randf() * 0.25)
			"rail":
				var v := clampf(e.speed / 1800.0, 0.03, 0.9)
				sfx.play("rail", v, 0.9 + randf() * 0.2)
			"bumper":
				sfx.play("bumper", 0.7)
				var bi := sim.index_of(e.a)
				view.burst(sim.pos[bi], Color(0.3, 1, 1), 10, 160)
			"pocket":
				var idx := sim.index_of(e.a)
				view.update_balls(sim)
				var b: BallNode = view.ball_nodes[idx]
				b.visible = true
				b.position = e.at
				view.sink(idx, e.pocket)
				_refresh_tray()
				var pp: Vector2 = layout.pockets[e.pocket].pos
				sfx.play("pocket", clampf(0.5 + e.speed / 2000.0, 0.4, 1.0), 0.95 + randf() * 0.1)
				if demo:
					continue
				if e.a == 0:
					view.popup(pp + Vector2(0, -30), "SCRATCH", Color(1, 0.35, 0.3), 26, 1.4)
					sfx.play("bad", 0.7)
				else:
					var c := Catalog.ball_color(e.a)
					view.burst(pp, c.lightened(0.3), 22, 260)
					view.ring(pp, Color(1, 0.9, 0.5), 50)
					view.popup(pp + _inward(e.pocket) * 50.0, "+%d" % Catalog.ball_points(e.a), Color(0.45, 0.85, 1.0), 24)
					if e.pocket == run.hot_pocket:
						view.ring(pp, Color(1, 0.5, 0.1), 80)
						view.add_shake(4.0)
					view.add_shake(1.5)


func _inward(k: int) -> Vector2:
	return layout.pockets[k].dir


## ================================================================ tally
func _settled() -> void:
	view.update_balls(sim)
	var ctx := _shot_ctx()
	ctx["power"] = shot_power
	ctx["events"] = sim.events
	ctx["start_pos"] = start_pos
	ctx["rng"] = run.rng
	result = Scorer.score(ctx)
	tally_i = 0
	tally_timer = 0.25
	tally_phase = 0
	shown_chips = 0.0
	shown_mult = 1.0
	state = S.TALLY
	lbl_hint.text = ""
	if not result.scored:
		var free_break: bool = is_break and result.foul == "Miss"
		var insured := run.formulas.has("insurance")
		var msg: String = result.foul
		if free_break:
			msg = "Dry break - no penalty"
		elif insured:
			msg += " - insured"
		else:
			msg += " - lose 1 chalk"
		lbl_line.text = msg
		_flash_banner(result.foul.to_upper(), Color(1, 0.4, 0.35) if not free_break else Color(0.8, 0.85, 0.9), 1.0)
		if not free_break:
			sfx.play("bad", 0.8)
		tally_phase = 2
		tally_timer = 0.9
	else:
		_set_chips_mult(0.0, 1.0)


func _update_tally(delta: float) -> void:
	tally_timer -= delta * (3.0 if fast else 1.0)
	if tally_timer > 0.0:
		return
	if tally_phase == 0:
		var lines: Array = result.lines
		if tally_i < lines.size():
			var l: Dictionary = lines[tally_i]
			_apply_tally_line(l, tally_i)
			tally_i += 1
			tally_timer = clampf(0.5 / maxf(1.0, lines.size() * 0.5), 0.08, 0.22)
		else:
			tally_phase = 1
			tally_timer = 0.55
			var total: int = result.total
			lbl_line.text = "%s × %s = %d" % [_fmt(result.chips), _fmt(result.mult), total]
			sfx.play("score", 0.8, 1.0 + minf(0.5, total / 4000.0))
			var mid := Vector2(TableLayout.W * 0.5, TableLayout.H * 0.5)
			var size := int(clampf(30.0 + sqrt(total) * 0.9, 30.0, 80.0))
			view.popup(mid, "+%d" % total, Color(1.0, 0.85, 0.35), size, 1.6)
			view.add_shake(clampf(total / 120.0, 1.0, 9.0))
			view.punch(clampf(total / 20000.0, 0.008, 0.03))
			_animate_score(run.score, run.score + total)
	elif tally_phase == 1:
		tally_phase = 2
		tally_timer = 0.05
	else:
		_after_shot()


func _apply_tally_line(l: Dictionary, i: int) -> void:
	_set_chips_mult(l.chips_after, l.mult_after)
	var p := Vector2(TableLayout.W * 0.5, TableLayout.H * 0.4)
	if l.pocket >= 0:
		p = layout.pockets[l.pocket].pos + _inward(l.pocket) * 80.0
	p += Vector2(randf_range(-20, 20), randf_range(-10, 10))
	var txt := ""
	var col := Color.WHITE
	match l.kind:
		"chips":
			txt = "+%s Chips" % _fmt(l.value)
			col = Color(0.45, 0.85, 1.0)
			sfx.play("tick", 0.6, pow(1.059, i))
		"mult":
			txt = "+%s Mult" % _fmt(l.value)
			col = Color(1.0, 0.6, 0.25)
			sfx.play("mult", 0.6, pow(1.059, i))
		"xmult":
			txt = "×%s Mult" % _fmt(l.value)
			col = Color(1.0, 0.35, 0.45)
			sfx.play("xmult", 0.8, 1.0)
			view.add_shake(2.5)
			view.punch(0.012)
			_pulse(lbl_mult)
		"xchips":
			txt = "×%s Chips" % _fmt(l.value)
			col = Color(0.3, 0.7, 1.0)
			sfx.play("xmult", 0.7, 1.3)
			_pulse(lbl_chips)
		"money":
			txt = "+$%d" % int(l.value)
			col = Color(1.0, 0.85, 0.3)
			sfx.play("coin", 0.6)
	lbl_line.text = "%s  %s" % [l.label, txt]
	view.popup(p, txt, col, 18, 0.9)


func _after_shot() -> void:
	var was_break := is_break
	is_break = false
	var out := run.apply_shot(result, was_break, sim.object_balls_left(), sim.alive[_cue_index()] == 1)
	_log_shot(was_break, out)
	if out.has("bounty"):
		sfx.play("coin", 1.0, 1.1)
		_flash_banner("BOUNTY!  +$%d" % Catalog.BOUNTIES[out.bounty].reward, Color(1.0, 0.85, 0.35), 1.3)
		view.burst(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.5), Color(1.0, 0.85, 0.35), 40, 300)
	for n in result.shattered:
		view.popup(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.6), "Glass %d-ball shattered!" % n, Color(0.7, 0.85, 1.0), 20, 1.5)
		view.refresh_glows(sim, run.isotopes)
	_animate_score(shown_score, run.score)
	if out.cleared:
		_table_cleared()
		return
	if out.over:
		_refresh_hud()
		_game_over()
		return
	view.hot_pocket = run.hot_pocket
	if out.rack_cleared:
		_flash_banner("RACK CLEARED  +1 CHALK", Color(0.5, 1.0, 0.7), 1.6)
		sfx.play("clear", 0.6)
		_new_rack(run.current().rack)
		_enter_aim()
	elif out.ball_in_hand:
		_begin_place(false)
	else:
		_enter_aim()
	_refresh_hud()
	_save_progress()


func _enter_aim() -> void:
	state = S.AIM
	view.placing = false
	guide_dirty = true
	if is_break:
		lbl_hint.text = "Break! Drag back from the cue ball and release. H: move the cue ball behind the line."
	else:
		lbl_hint.text = "Aim with the mouse. Drag back to set power and release to shoot. Wheel/Space also work."
	_refresh_hud()


func _begin_place(head_only: bool) -> void:
	state = S.PLACE
	place_head_only = head_only
	view.show_guide = false
	lbl_hint.text = "Ball in hand: click a clear spot to place the cue ball."
	_refresh_hud()


func _place_cue() -> void:
	if not view.place_ok:
		sfx.play("bad", 0.4)
		return
	var ci := _cue_index()
	sim.alive[ci] = 1
	sim.pos[ci] = view.place_pos
	sim.vel[ci] = Vector2.ZERO
	sim.spin[ci] = Vector2.ZERO
	var b: BallNode = view.ball_nodes[ci]
	b.visible = true
	b.set_fade(1.0)
	b.roll_to(view.place_pos)
	view.placing = false
	sfx.play("click_soft", 0.5)
	_enter_aim()


## ================================================================ table end
func _table_cleared() -> void:
	state = S.CLEAR
	sfx.play("clear", 1.0)
	_flash_banner("TABLE CLEARED!", Color(1.0, 0.85, 0.35), 2.2)
	view.add_shake(6.0)
	for k in layout.pockets.size():
		view.burst(layout.pockets[k].pos, Color(1, 0.85, 0.4), 30, 320)
	view.confetti()
	var final: bool = run.table_index == run.plan.size() - 1
	var rows := run.payout()
	_refresh_hud()
	await get_tree().create_timer(1.6).timeout
	if state != S.CLEAR:
		return
	if final and not run.endless:
		_show_victory(rows)
	else:
		_show_shop(rows)


func _game_over() -> void:
	state = S.OVER
	RunState.clear_save()
	sfx.play("bad", 1.0, 0.7)
	_flash_banner("OUT OF CHALK", Color(1, 0.35, 0.3), 2.0)
	await get_tree().create_timer(1.4).timeout
	if state != S.OVER:
		return
	_show_game_over()


## ================================================================ input
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if paused:
			if e.keycode == KEY_ESCAPE:
				_resume()
			return
		_key(e.keycode)
		return
	if paused:
		return
	if e is InputEventMouseButton:
		_mouse_button(e)


func _key(k: int) -> void:
	if k == KEY_ESCAPE:
		if state == S.PICK:
			state = S.AIM
			view.pocket_pick = false
			_enter_aim()
		elif state != S.TITLE:
			_show_pause()
		return
	match state:
		S.AIM:
			match k:
				KEY_SPACE, KEY_ENTER:
					_shoot(power)
				KEY_UP:
					power = clampf(power + 0.05, 0.02, 1.0)
				KEY_DOWN:
					power = clampf(power - 0.05, 0.02, 1.0)
				KEY_W:
					spin_w.set_spin(follow + 0.25, side)
				KEY_S:
					spin_w.set_spin(follow - 0.25, side)
				KEY_A:
					spin_w.set_spin(follow, side - 0.25)
				KEY_D:
					spin_w.set_spin(follow, side + 0.25)
				KEY_H:
					if is_break:
						_begin_place(true)
				KEY_F:
					fine_aim = not fine_aim
					lbl_hint.text = "Fine aim ON: use Left/Right (Shift = finer). F to release." if fine_aim else "Fine aim off."
				KEY_1:
					_use_reagent(0)
				KEY_2:
					_use_reagent(1)
		S.ROLL, S.TALLY:
			if k == KEY_SPACE or k == KEY_ENTER:
				fast = true


func _mouse_button(e: InputEventMouseButton) -> void:
	match state:
		S.AIM:
			if e.button_index == MOUSE_BUTTON_LEFT:
				if e.pressed and _mouse_over_table():
					dragging = true
					drag_origin = _mouse_table()
					drag_power = 0.0
				elif not e.pressed and dragging:
					dragging = false
					if drag_power > 0.03:
						power = drag_power
						_shoot(drag_power)
					drag_power = 0.0
			elif e.button_index == MOUSE_BUTTON_RIGHT and e.pressed and dragging:
				dragging = false
				drag_power = 0.0
			elif e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
				power = clampf(power + 0.03, 0.02, 1.0)
				forecast_dirty = true
			elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
				power = clampf(power - 0.03, 0.02, 1.0)
				forecast_dirty = true
		S.PLACE:
			if e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
				_place_cue()
		S.PICK:
			if e.button_index == MOUSE_BUTTON_LEFT and e.pressed and view.hover_pocket >= 0:
				run.hot_pocket = view.hover_pocket
				view.hot_pocket = run.hot_pocket
				view.pocket_pick = false
				sfx.play("xmult", 0.6)
				_enter_aim()
		S.ROLL, S.TALLY:
			if e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
				fast = true


func _on_spin(f: float, s: float) -> void:
	follow = f
	side = s
	guide_dirty = true


func _use_reagent(i: int) -> void:
	if state != S.AIM or i >= run.reagents.size():
		return
	var id: String = run.reagents[i]
	match id:
		"bluechalk":
			if run.bluechalk:
				return
			run.bluechalk = true
			_flash_banner("BLUE CHALK: ×2 NEXT SHOT", Color(0.4, 0.7, 1.0), 1.2)
		"hand":
			_begin_place(false)
		"spare":
			run.chalk += 1
			_flash_banner("+1 CHALK", Color(0.4, 0.7, 1.0), 1.0)
		"forecast":
			if run.forecast:
				return
			run.forecast = true
			forecast_dirty = true
			forecast_timer = 0.0
		"hotswap":
			state = S.PICK
			view.pocket_pick = true
			lbl_hint.text = "Click a pocket to make it the hot pocket. Esc cancels."
	run.reagents.remove_at(i)
	sfx.play("coin", 0.5, 1.2)
	guide_dirty = true
	_refresh_hud()


## ================================================================ UI construction
func _style(bg: Color, border: Color = Color(0, 0, 0, 0), bw: int = 0, radius: int = 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


func _label(text: String, size: int, color: Color = Color.WHITE, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", font if font else F_SEMI)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, cb: Callable, accent: Color = Color(0.85, 0.65, 0.3)) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", F_SEMI)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_stylebox_override("normal", _style(Color(0.11, 0.1, 0.09), accent.darkened(0.3), 2, 8))
	b.add_theme_stylebox_override("hover", _style(Color(0.2, 0.16, 0.11), accent, 2, 8))
	b.add_theme_stylebox_override("pressed", _style(Color(0.3, 0.22, 0.12), accent.lightened(0.2), 2, 8))
	b.add_theme_stylebox_override("disabled", _style(Color(0.08, 0.08, 0.08), Color(0.25, 0.25, 0.25), 2, 8))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.45, 0.45))
	b.pressed.connect(func():
		sfx.play("ui", 0.8)
		cb.call())
	b.mouse_entered.connect(func(): sfx.play("ui", 0.25, 1.5))
	return b


func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)

	# ---------------- left panel
	var left := PanelContainer.new()
	left_panel = left
	left.position = Vector2(14, 14)
	left.size = Vector2(330, 872)
	left.add_theme_stylebox_override("panel", _style(Color(0.075, 0.07, 0.075, 1.0), Color(0.55, 0.42, 0.22), 2, 14))
	root.add_child(left)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 8)
	left.add_child(lv)
	var title := _label("POCKET SCIENCE", 22, Color(0.95, 0.78, 0.4), F_PIXB)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(title)
	lbl_round = _label("Table 1 / 9", 16, Color(0.7, 0.75, 0.8))
	lbl_round.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(lbl_round)

	var labbox := PanelContainer.new()
	labbox.add_theme_stylebox_override("panel", _style(Color(0.12, 0.13, 0.15), Color(0.25, 0.3, 0.35), 1, 8))
	lv.add_child(labbox)
	var labv := VBoxContainer.new()
	labbox.add_child(labv)
	lbl_lab = _label("Standard Felt", 20, Color(0.6, 1.0, 0.85))
	labv.add_child(lbl_lab)
	lbl_rule = _label("", 13, Color(0.75, 0.78, 0.8), F_REG)
	lbl_rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_rule.custom_minimum_size = Vector2(290, 0)
	labv.add_child(lbl_rule)
	lbl_bounty = _label("", 14, Color(1.0, 0.85, 0.35))
	labv.add_child(lbl_bounty)
	lbl_boss = _label("", 14, Color(1.0, 0.45, 0.4))
	lbl_boss.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_boss.custom_minimum_size = Vector2(290, 0)
	labv.add_child(lbl_boss)

	var tbox := PanelContainer.new()
	tbox.add_theme_stylebox_override("panel", _style(Color(0.12, 0.1, 0.08), Color(0.5, 0.38, 0.2), 1, 8))
	lv.add_child(tbox)
	var tv := VBoxContainer.new()
	tbox.add_child(tv)
	var th := HBoxContainer.new()
	tv.add_child(th)
	th.add_child(_label("TARGET", 14, Color(0.8, 0.7, 0.55)))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	th.add_child(sp)
	lbl_target = _label("150", 22, Color(1.0, 0.85, 0.45), F_PIXB)
	th.add_child(lbl_target)
	lbl_score = _label("0", 44, Color.WHITE, F_PIXB)
	lbl_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tv.add_child(lbl_score)
	score_bar = ProgressBar.new()
	score_bar.show_percentage = false
	score_bar.custom_minimum_size = Vector2(0, 12)
	score_bar.add_theme_stylebox_override("background", _style(Color(0.05, 0.05, 0.05), Color(0, 0, 0, 0), 0, 6))
	var fill := _style(Color(1.0, 0.75, 0.3), Color(0, 0, 0, 0), 0, 6)
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	score_bar.add_theme_stylebox_override("fill", fill)
	tv.add_child(score_bar)

	var cm := HBoxContainer.new()
	cm.add_theme_constant_override("separation", 6)
	lv.add_child(cm)
	var cbox := PanelContainer.new()
	cbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cbox.add_theme_stylebox_override("panel", _style(Color(0.08, 0.3, 0.5), Color(0.3, 0.7, 1.0), 2, 8))
	cm.add_child(cbox)
	lbl_chips = _label("0", 30, Color.WHITE, F_PIXB)
	lbl_chips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_chips.pivot_offset = Vector2(60, 20)
	cbox.add_child(lbl_chips)
	var x := _label("×", 30, Color(0.9, 0.9, 0.9))
	cm.add_child(x)
	var mbox := PanelContainer.new()
	mbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mbox.add_theme_stylebox_override("panel", _style(Color(0.55, 0.2, 0.08), Color(1.0, 0.55, 0.25), 2, 8))
	cm.add_child(mbox)
	lbl_mult = _label("1", 30, Color.WHITE, F_PIXB)
	lbl_mult.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_mult.pivot_offset = Vector2(60, 20)
	mbox.add_child(lbl_mult)
	lbl_line = _label("Pot balls to score Chips × Mult", 14, Color(0.85, 0.85, 0.85))
	lbl_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_line.custom_minimum_size = Vector2(290, 40)
	lv.add_child(lbl_line)

	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 10)
	lv.add_child(stats)
	stats.add_child(_label("CHALK", 13, Color(0.6, 0.7, 0.85)))
	chalk_pips = ChalkPips.new()
	stats.add_child(chalk_pips)
	stats.add_child(_label("STREAK", 13, Color(0.6, 0.7, 0.85)))
	lbl_streak = _label("0", 20, Color(1.0, 0.6, 0.25), F_PIXB)
	stats.add_child(lbl_streak)
	stats.add_child(_label("MONEY", 13, Color(0.6, 0.7, 0.85)))
	lbl_money = _label("$4", 22, Color(1.0, 0.85, 0.3), F_PIXB)
	stats.add_child(lbl_money)
	flags_label = _label("", 13, Color(0.5, 0.8, 1.0))
	flags_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flags_label.custom_minimum_size = Vector2(290, 0)
	lv.add_child(flags_label)
	tray = BallTray.new()
	tray.font = F_SEMI
	lv.add_child(tray)
	lv.add_child(_label("RECENT SHOTS", 12, Color(0.5, 0.5, 0.55)))
	log_label = _label("", 13, Color(0.8, 0.82, 0.85), F_REG)
	log_label.custom_minimum_size = Vector2(290, 70)
	lv.add_child(log_label)

	var ctrl := HBoxContainer.new()
	ctrl.alignment = BoxContainer.ALIGNMENT_CENTER
	ctrl.add_theme_constant_override("separation", 14)
	lv.add_child(ctrl)
	spin_w = SpinWidget.new()
	spin_w.font = F_SEMI
	spin_w.custom_minimum_size = Vector2(130, 130)
	spin_w.changed.connect(_on_spin)
	ctrl.add_child(spin_w)
	power_w = PowerMeter.new()
	power_w.font = F_SEMI
	power_w.custom_minimum_size = Vector2(40, 130)
	ctrl.add_child(power_w)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(filler)
	lbl_hint = _label("", 13, Color(0.7, 0.72, 0.75), F_REG)
	lbl_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_hint.custom_minimum_size = Vector2(290, 50)
	lv.add_child(lbl_hint)

	# ---------------- bottom bar: formulas + reagents
	var bottom := HBoxContainer.new()
	bottom_bar = bottom
	bottom.position = Vector2(360, 712)
	bottom.size = Vector2(1226, 174)
	bottom.add_theme_constant_override("separation", 14)
	root.add_child(bottom)
	var fpanel := PanelContainer.new()
	fpanel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fpanel.add_theme_stylebox_override("panel", _style(Color(0.075, 0.07, 0.075, 1.0), Color(0.35, 0.3, 0.25), 1, 12))
	bottom.add_child(fpanel)
	var fv := VBoxContainer.new()
	fpanel.add_child(fv)
	fv.add_child(_label("FORMULAS  (passive - stack them!)", 12, Color(0.6, 0.6, 0.6)))
	formula_row = HBoxContainer.new()
	formula_row.add_theme_constant_override("separation", 8)
	fv.add_child(formula_row)
	var rpanel := PanelContainer.new()
	rpanel.custom_minimum_size = Vector2(300, 0)
	rpanel.add_theme_stylebox_override("panel", _style(Color(0.075, 0.07, 0.075, 1.0), Color(0.3, 0.35, 0.45), 1, 12))
	bottom.add_child(rpanel)
	var rv := VBoxContainer.new()
	rpanel.add_child(rv)
	rv.add_child(_label("REAGENTS  (click or 1/2 to use)", 12, Color(0.6, 0.6, 0.6)))
	reagent_row = HBoxContainer.new()
	reagent_row.add_theme_constant_override("separation", 8)
	rv.add_child(reagent_row)

	# ---------------- banner + overlay
	banner = _label("", 34, Color.WHITE, F_PIXB)
	var bsb := _style(Color(0.02, 0.02, 0.03, 0.72), Color(1, 1, 1, 0.12), 1, 12)
	bsb.content_margin_top = 10
	bsb.content_margin_bottom = 10
	banner.add_theme_stylebox_override("normal", bsb)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.position = Vector2(545, 150)
	banner.size = Vector2(850, 70)
	banner.pivot_offset = Vector2(425, 35)
	banner.add_theme_constant_override("outline_size", 12)
	banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	banner.visible = false
	root.add_child(banner)
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)


func _flash_banner(text: String, c: Color, t: float) -> void:
	banner.text = text
	banner.add_theme_color_override("font_color", c)
	banner.visible = true
	banner.modulate.a = 1.0
	banner_t = t + 0.4


func _pulse(l: Label) -> void:
	var tw := create_tween()
	l.scale = Vector2(1.35, 1.35)
	tw.tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _fmt(v: float) -> String:
	if absf(v - round(v)) < 0.01:
		return str(int(round(v)))
	return "%.1f" % v


func _set_chips_mult(c: float, m: float) -> void:
	if int(c) != int(shown_chips):
		_pulse(lbl_chips)
	if absf(m - shown_mult) > 0.001:
		_pulse(lbl_mult)
	shown_chips = c
	shown_mult = m
	lbl_chips.text = _fmt(c)
	lbl_mult.text = _fmt(m)


func _animate_score(from: float, to: float) -> void:
	score_from = from
	score_to = to
	score_t = 0.0


func _set_score_label() -> void:
	lbl_score.text = str(int(round(shown_score)))
	score_bar.max_value = run.target()
	score_bar.value = minf(shown_score, run.target())


func _refresh_hud() -> void:
	var t := run.current()
	var total := run.plan.size()
	if run.endless:
		lbl_round.text = "Endless table %d" % (run.table_index + 1)
	else:
		lbl_round.text = "Table %d / %d%s" % [run.table_index + 1, total, "  ·  BOSS" if t.get("boss", false) else ""]
	lbl_lab.text = Catalog.LABS[t.lab].name
	lbl_rule.text = Catalog.LABS[t.lab].desc
	if t.anomaly != "":
		var an: Dictionary = Catalog.ANOMALIES[t.anomaly]
		lbl_boss.text = "ANOMALY: %s - %s" % [an.name, an.desc]
		lbl_boss.visible = true
	else:
		lbl_boss.visible = false
	lbl_target.text = str(run.target())
	if run.bounty != "":
		var bt: Dictionary = Catalog.BOUNTIES[run.bounty]
		lbl_bounty.text = ("✔ " if run.bounty_done else "★ ") + "Bounty: %s  +$%d" % [bt.name, bt.reward]
		lbl_bounty.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6) if run.bounty_done else Color(1.0, 0.85, 0.35))
	chalk_pips.set_count(run.chalk, run.max_chalk())
	var per := 2.0 if run.formulas.has("streak") else 1.0
	lbl_streak.text = "%d  (+%s Mult)" % [run.streak, _fmt(run.streak * per)] if run.streak > 0 else "0"
	lbl_money.text = "$%d" % run.money
	var flags: Array[String] = []
	if run.bluechalk:
		flags.append("Blue Chalk ready: ×2 Mult")
	if run.forecast:
		flags.append("Forecast active")
	if run.formulas.has("catalyst"):
		flags.append("Catalyst: +%s Mult" % _fmt(run.catalyst))
	if run.hot_pocket >= 0:
		flags.append("Hot pocket: %s (×%d)" % [TableLayout.pocket_name(run.hot_pocket), 3 if run.formulas.has("heat") else 2])
	flags_label.text = "\n".join(flags)
	_refresh_tray()
	if score_t >= 1.0:
		shown_score = run.score
		_set_score_label()
	_rebuild_cards()


func _refresh_tray() -> void:
	if sim == null or tray == null:
		return
	var rack: Array = []
	var down := {}
	for i in sim.count():
		var n: int = sim.num[i]
		if n == 0:
			continue
		rack.append(n)
		if sim.alive[i] == 0:
			down[n] = true
	rack.sort()
	tray.set_state(rack, down, run.isotopes)


func _rebuild_cards() -> void:
	for c in formula_row.get_children():
		c.queue_free()
	for c in reagent_row.get_children():
		c.queue_free()
	for i in RunState.MAX_FORMULAS:
		if i < run.formulas.size():
			formula_row.add_child(_formula_card(run.formulas[i], i))
		else:
			var empty := PanelContainer.new()
			empty.custom_minimum_size = Vector2(170, 132)
			empty.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0.2), Color(1, 1, 1, 0.08), 1, 10))
			formula_row.add_child(empty)
	for i in RunState.MAX_REAGENTS:
		if i < run.reagents.size():
			reagent_row.add_child(_reagent_card(run.reagents[i], i))
		else:
			var empty := PanelContainer.new()
			empty.custom_minimum_size = Vector2(134, 132)
			empty.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0.2), Color(1, 1, 1, 0.08), 1, 10))
			reagent_row.add_child(empty)


func _card_shell(accent: Color, w: float, h: float) -> Array:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(w, h)
	p.add_theme_stylebox_override("panel", _style(Color(0.13, 0.12, 0.13), accent, 2, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	return [p, v]


func _formula_card(id: String, slot: int) -> Control:
	var f: Dictionary = Catalog.FORMULAS[id]
	var accent := Catalog.rarity_color(f.r)
	var sh := _card_shell(accent, 170, 132)
	var p: PanelContainer = sh[0]
	var v: VBoxContainer = sh[1]
	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(hb)
	hb.add_child(_label(f.icon, 20, accent))
	var name_l := _label(f.name, 14, Color.WHITE)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.custom_minimum_size = Vector2(118, 0)
	hb.add_child(name_l)
	var d := _label(f.desc, 11, Color(0.78, 0.8, 0.82), F_REG)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(146, 0)
	if state != S.SHOP:
		v.add_child(d)
	else:
		v.add_child(_label(Catalog.rarity_name(f.r), 11, accent))
	if id == "catalyst":
		v.add_child(_label("Now: +%s Mult" % _fmt(run.catalyst), 12, accent))
	p.tooltip_text = "%s (%s)\n%s" % [f.name, Catalog.rarity_name(f.r), f.desc]
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	if state == S.SHOP:
		var b := _button("Sell $%d" % run.sell_value(id), func():
			run.sell_formula(slot)
			sfx.play("coin", 0.7, 0.8)
			_refresh_shop()
			_refresh_hud(), Color(0.9, 0.4, 0.3))
		b.add_theme_font_size_override("font_size", 13)
		v.add_child(b)
	return p


func _reagent_card(id: String, slot: int) -> Control:
	var r: Dictionary = Catalog.REAGENTS[id]
	var accent := Color(0.4, 0.65, 1.0)
	var sh := _card_shell(accent, 134, 132)
	var p: PanelContainer = sh[0]
	var v: VBoxContainer = sh[1]
	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(hb)
	hb.add_child(_label(r.icon, 18, accent))
	var n := _label(r.name, 14, Color.WHITE)
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.custom_minimum_size = Vector2(84, 0)
	hb.add_child(n)
	var d := _label(r.desc, 11, Color(0.78, 0.8, 0.82), F_REG)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(110, 0)
	v.add_child(d)
	v.add_child(_label("[%d] Use" % (slot + 1), 12, accent))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.tooltip_text = r.desc
	p.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_use_reagent(slot))
	return p


## ================================================================ overlays
func _clear_overlay() -> void:
	for c in overlay.get_children():
		c.queue_free()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _dim(alpha: float = 0.72) -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(0.02, 0.02, 0.03, alpha)
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(d)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	return d


func _center_panel(w: float, h: float, accent: Color = Color(0.85, 0.65, 0.3), at: Vector2 = Vector2(-1, -1)) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(Color(0.08, 0.075, 0.08, 0.98), accent, 2, 16))
	p.custom_minimum_size = Vector2(w, 0)
	p.size = Vector2(w, 0)
	p.position = at if at.x >= 0 else Vector2((1600 - w) * 0.5, (900 - h) * 0.5)
	if at.x < 0:
		p.resized.connect(func(): p.position.y = maxf(10.0, (900.0 - p.size.y) * 0.5))
	overlay.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	# Wrapping labels with no width would measure one word per line and balloon
	# the panel; give them the panel's inner width once the content is built.
	(func():
		_fix_wrap_widths(v, w - 32.0)
		if is_instance_valid(p):
			p.size = Vector2(w, 0)).call_deferred()
	return v


func _fix_wrap_widths(n: Node, width: float) -> void:
	if not is_instance_valid(n):
		return
	for c in n.get_children():
		if c is Label and (c as Label).autowrap_mode != TextServer.AUTOWRAP_OFF and (c as Label).custom_minimum_size.x <= 0.0:
			(c as Label).custom_minimum_size.x = width
		elif c is Container and not (c is HBoxContainer) and not (c is GridContainer):
			_fix_wrap_widths(c, width)


func _hud_visible(on: bool) -> void:
	var a := 1.0 if on else 0.0
	for c in [left_panel, bottom_bar]:
		var tw := create_tween()
		tw.tween_property(c, "modulate:a", a, 0.35)


func _show_title() -> void:
	state = S.TITLE
	demo_timer = 1.2
	sfx.play_music("title")
	_hud_visible(false)
	_clear_overlay()
	# A static rack on the standard table behind the title.
	run.start(randi())
	_setup_table()
	view.show_guide = false
	_dim(0.35)
	var v := _center_panel(560, 560)
	var t := _label("POCKET SCIENCE", 52, Color(0.98, 0.8, 0.4), F_PIXB)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := _label("A pool roguelite. Pot balls, stack multipliers, beat the target.", 17, Color(0.8, 0.85, 0.9), F_REG)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 20)
	v.add_child(sp)
	if RunState.has_save():
		var c := _button("Continue run", _continue_run, Color(0.4, 0.9, 0.6))
		c.custom_minimum_size = Vector2(0, 54)
		c.add_theme_font_size_override("font_size", 24)
		v.add_child(c)
	var b := _button("New Run", _show_cue_select)
	b.custom_minimum_size = Vector2(0, 54)
	b.add_theme_font_size_override("font_size", 24)
	v.add_child(b)
	v.add_child(_button("How to Play", _show_help))
	v.add_child(_button("Settings", func(): _show_settings(_show_title)))
	v.add_child(_button("Quit", func(): get_tree().quit()))
	var best := _load_best()
	if best.tables > 0 or best.shot > 0:
		var bl := _label("Best run: %d tables cleared  ·  best shot %d  ·  best streak %d" % [best.tables, best.shot, best.streak], 15, Color(1.0, 0.85, 0.45), F_REG)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(bl)
	var foot := _label("Real pool physics · exact guideline · %d Formulas · 9 tables + endless" % Catalog.FORMULAS.size(), 13, Color(0.55, 0.55, 0.6), F_REG)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(foot)


var chosen_cue := "maple"


func _show_cue_select() -> void:
	_clear_overlay()
	_dim(0.6)
	var v := _center_panel(1100, 420)
	v.add_child(_label("CHOOSE YOUR CUE", 30, Color(0.98, 0.8, 0.4), F_PIXB))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	for id in Catalog.CUES:
		var c: Dictionary = Catalog.CUES[id]
		var sh := _card_shell(c.accent, 200, 260)
		var p: PanelContainer = sh[0]
		var cv: VBoxContainer = sh[1]
		var stick := Control.new()
		stick.custom_minimum_size = Vector2(0, 40)
		stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stick.draw.connect(func():
			var y := 20.0
			var x0 := 6.0
			var x1 := stick.size.x - 6.0
			var mid := lerpf(x0, x1, 0.45)
			stick.draw_colored_polygon(PackedVector2Array([Vector2(x0, y - 2), Vector2(mid, y - 3.5), Vector2(mid, y + 3.5), Vector2(x0, y + 2)]), c.shaft)
			stick.draw_colored_polygon(PackedVector2Array([Vector2(mid, y - 3.5), Vector2(x1, y - 6), Vector2(x1, y + 6), Vector2(mid, y + 3.5)]), c.butt)
			stick.draw_rect(Rect2(Vector2(mid - 2, y - 4), Vector2(4, 8)), c.accent)
			stick.draw_rect(Rect2(Vector2(x0 - 3, y - 2), Vector2(4, 4)), Color(0.25, 0.5, 0.85)))
		cv.add_child(stick)
		var n := _label(c.name, 20, Color.WHITE)
		cv.add_child(n)
		var d := _label(c.desc, 14, Color(0.8, 0.82, 0.85), F_REG)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(176, 0)
		d.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cv.add_child(d)
		var pick := _button("Choose", func():
			chosen_cue = id
			_new_run(), c.accent)
		cv.add_child(pick)
		row.add_child(p)
	v.add_child(_button("Back", _show_title))


func _new_run() -> void:
	demo = false
	_hud_visible(true)
	_clear_overlay()
	run.start(randi(), chosen_cue)
	view.cue_colors = Catalog.CUES.get(chosen_cue, Catalog.CUES.maple)
	run.begin_table()
	_setup_table()
	_save_progress()
	spin_w.set_spin(0, 0)
	_animate_score(0, 0)
	shown_score = 0
	_set_chips_mult(0, 1)
	lbl_line.text = "Pot balls to score Chips × Mult"
	coaching = _load_best().tables == 0
	coach_seen_pot = false
	_enter_aim()
	_flash_banner("TABLE 1  ·  TARGET %d" % run.target(), Color(1, 0.85, 0.4), 1.6)


func _show_help() -> void:
	_clear_overlay()
	_dim(0.8)
	var v := _center_panel(900, 700)
	v.add_child(_label("HOW TO PLAY", 30, Color(0.98, 0.8, 0.4), F_PIXB))
	var txt := """[b]Shoot:[/b] Aim with the mouse. Press on the table and drag BACK from the cue ball to set power, then release. (Or use the wheel/Up/Down for power and Space to shoot.) Left/Right fine-tune your aim, and Shift makes it finer.
[b]Guideline:[/b] The white line shows the cue ball's path, and the ring is where it will touch the object ball. The [color=#ffd060]gold line[/color] means that ball is heading into a pocket, and the tag on the pocket shows what the pot is worth. The blue dashes show where the cue ball goes after contact, including spin.
[b]Spin:[/b] Click the big cue ball (W/S/A/D). Hitting it high gives follow and low gives draw; the sides add english off the cushions.

[b]Score:[/b] Every pot adds [color=#70d0ff]Chips[/color] (10 + the ball's number). Bonuses add [color=#ff9a40]Mult[/color]. Your shot is worth Chips × Mult, where all +Mult bonuses are added first and then every ×Mult multiplies.
Mult bonuses: streak (+1 per consecutive scoring shot), bank pots (+1 per cushion), combinations (+2), extra balls in one shot (+1 each), kick shots (+2). The [color=#ff8a30]hot pocket[/color] gives ×2. The black 8 also gives ×2.

[b]Chalk:[/b] As in real pool, you keep shooting while you pot. A miss, a scratch or no contact costs 1 chalk. A dry break is free. Run out of chalk before reaching the target and the run is over. Clearing the whole rack gives +1 chalk and a fresh rack.

[b]Between tables:[/b] Spend money in the Lab Supply on Formulas (passive rules that stack), Reagents (one-use tricks) and Isotopes (permanently enhance one numbered ball). Leftover chalk pays $1 each.

Every third table is a boss with an Anomaly. Clear all 9 tables to win, then keep going in endless mode."""
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.text = txt
	rt.custom_minimum_size = Vector2(860, 540)
	rt.add_theme_font_override("normal_font", F_REG)
	rt.add_theme_font_override("bold_font", F_SEMI)
	rt.add_theme_font_size_override("normal_font_size", 16)
	rt.add_theme_font_size_override("bold_font_size", 16)
	v.add_child(rt)
	v.add_child(_button("Back", func():
		if state == S.TITLE:
			_show_title()
		elif paused:
			_show_pause_again()
		else:
			_clear_overlay()))


func _show_pause_again() -> void:
	paused = false
	_show_pause()


func _resume() -> void:
	paused = false
	_clear_overlay()


func _show_pause() -> void:
	if state == S.SHOP or state == S.OVER or state == S.CLEAR:
		return
	paused = true
	_clear_overlay()
	_dim(0.6)
	var v := _center_panel(420, 380)
	v.add_child(_label("PAUSED", 30, Color(0.98, 0.8, 0.4), F_PIXB))
	v.add_child(_button("Resume", _resume))
	v.add_child(_button("How to Play", _show_help))
	v.add_child(_button("Settings", func(): _show_settings(_show_pause_again)))
	v.add_child(_button("Save & quit to title", func():
		paused = false
		_show_title(), Color(0.6, 0.75, 0.9)))
	v.add_child(_button("Abandon run", func():
		paused = false
		RunState.clear_save()
		_show_title(), Color(0.9, 0.4, 0.3)))
	v.add_child(_button("Quit game", func(): get_tree().quit(), Color(0.9, 0.4, 0.3)))


## ---------------------------------------------------------------- shop
var payout_rows: Array = []


func _show_shop(rows: Array) -> void:
	payout_rows = rows
	state = S.SHOP
	sfx.play_music("shop")
	run.roll_shop()
	_refresh_shop()
	_refresh_hud()


## Persists the run exactly where the player is: mid-table (every ball) or in the shop.
func _save_progress() -> void:
	if state == S.SHOP:
		run.phase = "shop"
		run.shop_payout = payout_rows
	else:
		run.phase = "table"
		var balls: Array = []
		for i in sim.count():
			balls.append({"n": sim.num[i], "x": sim.pos[i].x, "y": sim.pos[i].y, "alive": sim.alive[i], "m": sim.mass[i]})
		run.table_snapshot = {"balls": balls, "is_break": is_break, "log": shot_log}
	run.save()


func _refresh_shop() -> void:
	_save_progress()
	_clear_overlay()
	var d := _dim(0.6)
	d.set_anchors_preset(Control.PRESET_TOP_LEFT)
	d.position = Vector2(352, 0)
	d.size = Vector2(1248, 706)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := _center_panel(1040, 600, Color(0.85, 0.65, 0.3), Vector2(450, 70))
	var head := HBoxContainer.new()
	v.add_child(head)
	head.add_child(_label("LAB SUPPLY", 30, Color(0.98, 0.8, 0.4), F_PIXB))
	var spc := Control.new()
	spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spc)
	head.add_child(_label("$%d" % run.money, 30, Color(1.0, 0.85, 0.3), F_PIXB))
	if not payout_rows.is_empty():
		var parts: Array[String] = []
		for r in payout_rows:
			parts.append("%s +$%d" % [r[0], r[1]])
		v.add_child(_label("Payout:  " + "   ·   ".join(parts), 15, Color(0.8, 0.85, 0.7), F_REG))
	var nxt := run.table_index + 1
	var np: Dictionary = run.plan[mini(nxt, run.plan.size() - 1)] if nxt < run.plan.size() else {}
	if not np.is_empty():
		var s := "Next: Table %d - %s - target %d" % [nxt + 1, Catalog.LABS[np.lab].name, np.target]
		if np.anomaly != "":
			s += "  ·  BOSS: %s (%s)" % [Catalog.ANOMALIES[np.anomaly].name, Catalog.ANOMALIES[np.anomaly].desc]
		v.add_child(_label(s, 15, Color(1.0, 0.6, 0.5) if np.anomaly != "" else Color(0.6, 0.9, 1.0), F_REG))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	for i in run.shop.size():
		row.add_child(_offer_card(i))
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	v.add_child(bar)
	var rr := _button("Reroll formulas ($%d)" % run.reroll_cost, func():
		if run.reroll():
			sfx.play("coin", 0.6, 0.9)
			_refresh_shop()
			_refresh_hud()
		else:
			sfx.play("bad", 0.4))
	rr.disabled = run.money < run.reroll_cost
	bar.add_child(rr)
	var spc2 := Control.new()
	spc2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spc2)
	var go := _button("Next table  ▶", _next_table, Color(0.4, 0.9, 0.6))
	go.custom_minimum_size = Vector2(220, 50)
	go.add_theme_font_size_override("font_size", 22)
	bar.add_child(go)
	v.add_child(_label("Tip: you can sell a Formula from the bar below for half its price.", 13, Color(0.55, 0.55, 0.6), F_REG))


func _offer_card(i: int) -> Control:
	var item: Dictionary = run.shop[i]
	var accent := Color(0.6, 0.6, 0.6)
	var title := ""
	var desc := ""
	var kind := ""
	var icon := ""
	match item.type:
		"formula":
			var f: Dictionary = Catalog.FORMULAS[item.id]
			accent = Catalog.rarity_color(f.r)
			title = f.name
			desc = f.desc
			kind = "Formula · " + Catalog.rarity_name(f.r)
			icon = f.icon
		"reagent":
			var r: Dictionary = Catalog.REAGENTS[item.id]
			accent = Color(0.4, 0.65, 1.0)
			title = r.name
			desc = r.desc
			kind = "Reagent · single use"
			icon = r.icon
		"isotope":
			var iso: Dictionary = Catalog.ISOTOPES[item.id]
			accent = iso.color
			title = "%s %d-ball" % [iso.name, item.ball]
			desc = iso.desc + " Lasts the whole run."
			kind = "Isotope"
			icon = "●"
			if run.isotopes.has(item.ball):
				desc += " (Replaces %s.)" % Catalog.ISOTOPES[run.isotopes[item.ball]].name
	var sh := _card_shell(accent, 188, 330)
	var p: PanelContainer = sh[0]
	var v: VBoxContainer = sh[1]
	if item.type == "isotope":
		v.add_child(_ball_icon(item.ball, iso_color(item.id)))
	else:
		var ic := _label(icon, 40, accent)
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(ic)
	var t := _label(title, 18, Color.WHITE)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(164, 0)
	v.add_child(t)
	v.add_child(_label(kind, 12, accent))
	var d := _label(desc, 13, Color(0.8, 0.82, 0.85), F_REG)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(164, 0)
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(d)
	var b := _button("SOLD" if item.sold else "Buy $%d" % item.cost, func():
		var err := run.buy(i)
		if err == "":
			sfx.play("coin", 0.9)
			if item.type == "isotope":
				view.refresh_glows(sim, run.isotopes)
			_refresh_shop()
			_refresh_hud()
		else:
			sfx.play("bad", 0.4)
			_flash_banner(err.to_upper(), Color(1, 0.5, 0.4), 1.0))
	b.disabled = item.sold or run.money < item.cost
	v.add_child(b)
	if item.sold:
		p.modulate = Color(1, 1, 1, 0.45)
	return p


func _continue_run() -> void:
	demo = false
	_hud_visible(true)
	_clear_overlay()
	if not run.load_save():
		_new_run()
		return
	view.cue_colors = Catalog.CUES.get(run.cue, Catalog.CUES.maple)
	# Building the table draws a rack from the run RNG; keep the saved stream intact.
	var rng_state := run.rng.state
	_setup_table()
	run.rng.state = rng_state
	spin_w.set_spin(0, 0)
	_set_chips_mult(0, 1)
	lbl_line.text = "Pot balls to score Chips × Mult"
	if run.phase == "shop":
		payout_rows = run.shop_payout
		state = S.SHOP
		sfx.play_music("shop")
		_refresh_shop()
		_refresh_hud()
		return
	_restore_snapshot(run.table_snapshot)
	shown_score = run.score
	_animate_score(run.score, run.score)
	view.hot_pocket = run.hot_pocket
	_refresh_hud()
	var ci := _cue_index()
	if sim.alive[ci] == 0:
		_begin_place(false)
	else:
		_enter_aim()
	_flash_banner("TABLE %d  ·  %d / %d" % [run.table_index + 1, run.score, run.target()], Color(1, 0.85, 0.4), 1.6)


func _restore_snapshot(snap: Dictionary) -> void:
	var balls: Array = snap.get("balls", [])
	if balls.is_empty():
		return
	sim = _make_sim()
	for b in balls:
		var i := sim.add_ball(int(b.n), Vector2(float(b.x), float(b.y)), float(b.get("m", 1.0)))
		sim.alive[i] = int(b.get("alive", 1))
	if sim.index_of(0) < 0:
		sim.add_ball(0, Rack.HEAD)
		sim.alive[sim.index_of(0)] = 0
	view.sync_balls(sim, vis_rng, run.isotopes)
	is_break = bool(snap.get("is_break", false))
	shot_log.assign(snap.get("log", []))
	log_label.text = "
".join(shot_log)
	guide_dirty = true


func _load_best() -> Dictionary:
	var c := ConfigFile.new()
	c.load("user://settings.cfg")
	return {"tables": int(c.get_value("best", "tables", 0)), "shot": int(c.get_value("best", "shot", 0)), "streak": int(c.get_value("best", "streak", 0))}


func _record_best() -> void:
	var c := ConfigFile.new()
	c.load("user://settings.cfg")
	c.set_value("best", "tables", maxi(int(c.get_value("best", "tables", 0)), run.tables_cleared))
	c.set_value("best", "shot", maxi(int(c.get_value("best", "shot", 0)), run.best_shot))
	c.set_value("best", "streak", maxi(int(c.get_value("best", "streak", 0)), run.best_streak))
	c.save("user://settings.cfg")


var settings := GameSettings.new()


func _save_settings() -> void:
	settings.save_file()


func _load_settings() -> void:
	settings.load_file()
	_apply_settings()


## Pushes every preference into the running game.
func _apply_settings() -> void:
	sfx.volume = settings.master * settings.sfx
	sfx.set_music_volume(settings.master * settings.music)
	view.shake_scale = settings.shake
	view.reduced_motion = settings.reduced_motion
	if DisplayServer.get_name() != "headless":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED)


func _show_settings(back: Callable) -> void:
	var was_paused := paused
	paused = false
	_clear_overlay()
	paused = was_paused
	_dim(0.75)
	var v := _center_panel(640, 640)
	v.add_child(_label("SETTINGS", 30, Color(0.98, 0.8, 0.4), F_PIXB))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	_setting_slider(grid, "Master volume", "master", 0.0, 1.0, func(x): return "%d%%" % int(round(x * 100)))
	_setting_slider(grid, "Music", "music", 0.0, 1.0, func(x): return "%d%%" % int(round(x * 100)))
	_setting_slider(grid, "Sound effects", "sfx", 0.0, 1.0, func(x): return "%d%%" % int(round(x * 100)))
	_setting_slider(grid, "Screen shake", "shake", 0.0, 1.5, func(x): return "%d%%" % int(round(x * 100)))
	_setting_slider(grid, "Pull-back for full power", "pull", 0.6, 1.6, func(x): return "%d px" % int(round(DRAG_FULL * x * TABLE_SCALE)))
	_setting_slider(grid, "Keyboard aim speed", "aim_speed", 0.25, 3.0, func(x): return "%.2fx" % x)
	_setting_toggle(grid, "Fullscreen", "fullscreen")
	_setting_toggle(grid, "VSync", "vsync")
	_setting_toggle(grid, "Reduced motion (no shake, zoom or confetti)", "reduced_motion")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var reset := _button("Defaults", func():
		settings.reset()
		_apply_settings()
		_save_settings()
		_show_settings(back), Color(0.6, 0.75, 0.9))
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(reset)
	var wipe := _button("Erase all progress…", func(): _confirm_wipe(back), Color(0.9, 0.4, 0.3))
	wipe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(wipe)
	var done := _button("Back", func():
		_save_settings()
		back.call(), Color(0.4, 0.9, 0.6))
	done.custom_minimum_size = Vector2(0, 48)
	v.add_child(done)


func _setting_slider(grid: GridContainer, title: String, key: String, lo: float, hi: float, fmt: Callable) -> void:
	var l := _label(title, 16, Color(0.85, 0.87, 0.9), F_REG)
	grid.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = float(settings.get(key))
	s.custom_minimum_size = Vector2(240, 24)
	s.name = "slider_" + key
	grid.add_child(s)
	var val := _label(fmt.call(s.value), 15, Color(1.0, 0.85, 0.45), F_SEMI)
	val.custom_minimum_size = Vector2(70, 0)
	grid.add_child(val)
	s.value_changed.connect(func(x: float):
		settings.set(key, x)
		val.text = fmt.call(x)
		_apply_settings()
		if key == "sfx" or key == "master":
			sfx.play("click", 0.6))
	s.drag_ended.connect(func(_changed: bool): _save_settings())


func _setting_toggle(grid: GridContainer, title: String, key: String) -> void:
	grid.add_child(_label(title, 16, Color(0.85, 0.87, 0.9), F_REG))
	var c := CheckButton.new()
	c.button_pressed = bool(settings.get(key))
	c.name = "toggle_" + key
	grid.add_child(c)
	grid.add_child(Control.new())
	c.toggled.connect(func(on: bool):
		settings.set(key, on)
		_apply_settings()
		_save_settings()
		sfx.play("ui", 0.8))


func _confirm_wipe(back: Callable) -> void:
	_clear_overlay()
	_dim(0.8)
	var v := _center_panel(520, 260, Color(0.9, 0.35, 0.3))
	v.add_child(_label("ERASE ALL PROGRESS?", 26, Color(1, 0.45, 0.4), F_PIXB))
	var t := _label("This deletes your saved run and personal bests. Settings are kept. It cannot be undone.", 16, Color(0.85, 0.85, 0.85), F_REG)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(480, 0)
	v.add_child(t)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var no := _button("Cancel", func(): _show_settings(back))
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(no)
	var yes := _button("Erase", func():
		RunState.clear_save()
		var c := ConfigFile.new()
		c.load(GameSettings.PATH)
		if c.has_section("best"):
			c.erase_section("best")
		c.save(GameSettings.PATH)
		paused = false
		_show_title(), Color(0.9, 0.4, 0.3))
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(yes)


func _next_table() -> void:
	coaching = false
	view.coach_text = ""
	_clear_overlay()
	run.advance_table()
	run.begin_table()
	_setup_table()
	_save_progress()
	_animate_score(0, 0)
	shown_score = 0
	_set_chips_mult(0, 1)
	lbl_line.text = "Pot balls to score Chips × Mult"
	_enter_aim()
	var t := run.current()
	var msg := "TABLE %d  ·  TARGET %d" % [run.table_index + 1, run.target()]
	if t.anomaly != "":
		msg = "BOSS: %s" % Catalog.ANOMALIES[t.anomaly].name.to_upper()
	_flash_banner(msg, Color(1, 0.5, 0.4) if t.anomaly != "" else Color(1, 0.85, 0.4), 1.8)


func _show_game_over() -> void:
	RunState.clear_save()
	_record_best()
	_clear_overlay()
	_dim(0.7)
	var v := _center_panel(560, 460, Color(0.9, 0.35, 0.3))
	v.add_child(_label("EXPERIMENT FAILED", 36, Color(1, 0.45, 0.4), F_PIXB))
	v.add_child(_label("Reached table %d. Score %d / %d" % [run.table_index + 1, run.score, run.target()], 18, Color(0.9, 0.9, 0.9), F_REG))
	v.add_child(_label("Tables cleared: %d\nBalls potted: %d\nBest shot: %d\nBest streak: %d" % [run.tables_cleared, run.total_pots, run.best_shot, run.best_streak], 17, Color(0.8, 0.82, 0.85), F_REG))
	var b := _button("New Run", _new_run)
	b.custom_minimum_size = Vector2(0, 50)
	v.add_child(b)
	v.add_child(_button("Title", _show_title))


func _show_victory(rows: Array) -> void:
	_record_best()
	_clear_overlay()
	_dim(0.6)
	var v := _center_panel(620, 470, Color(1.0, 0.85, 0.35))
	v.add_child(_label("ALL TRIALS CLEARED!", 36, Color(1.0, 0.85, 0.4), F_PIXB))
	v.add_child(_label("You beat all 9 tables of Pocket Science.", 18, Color(0.9, 0.9, 0.9), F_REG))
	v.add_child(_label("Balls potted: %d\nBest shot: %d\nBest streak: %d" % [run.total_pots, run.best_shot, run.best_streak], 17, Color(0.8, 0.82, 0.85), F_REG))
	var b := _button("Keep going (Endless)", func(): _show_shop(rows), Color(0.4, 0.9, 0.6))
	b.custom_minimum_size = Vector2(0, 50)
	v.add_child(b)
	v.add_child(_button("New Run", _new_run))


func iso_color(id: String) -> Color:
	return Catalog.ISOTOPES[id].color


## A small drawn pool ball with its number, used for isotope offers.
func _ball_icon(n: int, ring: Color) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 52)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var p := Vector2(c.size.x * 0.5, 26)
		c.draw_circle(p, 25, Color(ring, 0.35))
		c.draw_circle(p, 20, Catalog.ball_color(n) if not Catalog.is_stripe(n) else Color(0.95, 0.93, 0.88))
		if Catalog.is_stripe(n):
			c.draw_rect(Rect2(p + Vector2(-17, -10), Vector2(34, 20)), Catalog.ball_color(n))
		c.draw_circle(p, 9, Color(0.97, 0.95, 0.9))
		var t := str(n)
		var w := F_SEMI.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		c.draw_string(F_SEMI, p + Vector2(-w * 0.5, 5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.05, 0.05, 0.05))
		c.draw_circle(p + Vector2(-7, -8), 4, Color(1, 1, 1, 0.4)))
	return c


func _log_shot(was_break: bool, out: Dictionary) -> void:
	var line := ""
	if result.scored:
		var tags: Array[String] = []
		tags.append("%d ball%s" % [result.potted.size(), "" if result.potted.size() == 1 else "s"])
		for l in result.lines:
			if l.label.begins_with("Bank") and not tags.has("bank"):
				tags.append("bank")
			elif l.label == "Combination" and not tags.has("combo"):
				tags.append("combo")
			elif l.label == "Hot pocket" and not tags.has("hot"):
				tags.append("hot")
			elif l.label == "Kick shot":
				tags.append("kick")
		line = "+%d   %s" % [result.total, ", ".join(tags)]
	else:
		line = "%s%s" % [result.foul, "  -1 chalk" if out.chalk_lost else ""]
		if was_break and result.foul == "Miss":
			line = "Dry break"
	shot_log.push_front(line)
	if shot_log.size() > 4:
		shot_log.resize(4)
	log_label.text = "
".join(shot_log)
