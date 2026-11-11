extends Node2D
## Pocket Science — game controller.
## States: TITLE -> AIM <-> PLACE -> STRIKE -> ROLL -> TALLY -> (AIM | CLEAR -> SHOP | OVER)

enum S { TITLE, AIM, PLACE, STRIKE, ROLL, TALLY, CLEAR, SHOP, OVER, PICK, HOLD }

const TABLE_ORIGIN := Vector2(445, 99)
const TABLE_SCALE := 1.05
const MAX_SPEED := 2250.0
const MIN_SPEED := 90.0
const DRAG_FULL := 230.0

var F_REG: Font = preload("res://assets/fonts/ChakraPetch-Regular.ttf")
var F_SEMI: Font = preload("res://assets/fonts/ChakraPetch-SemiBold.ttf")
var F_PIX: Font = preload("res://assets/fonts/Silkscreen-Regular.ttf")
var F_PIXB: Font = preload("res://assets/fonts/Silkscreen-Bold.ttf")
## Rounded and smooth: every score, price and ball number uses this, so headings can stay pixel art.
var F_NUM: Font = _number_font()

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
var live_chain := 1.0
var live_contacted := false
var shown_score := 0.0
var score_from := 0.0
var score_to := 0.0
var score_t := 1.0

# UI
var ui: CanvasLayer
var root: Control
var lbl_round: Label
var lbl_lab: Label
var lbl_rule: RichTextLabel
var item_bar: HFlowContainer
var touch_shoot: Button
var pick_item := ""
var pick_slot := -1
var pick_points: Array = []
var pick_return := 0            # the state a bumper or portal placement returns to
var hold_action := ""           # while paused: "strike", "wall" or "blink" waiting for a click
var hold_slot := ""
var wall_start := Vector2.INF
var plan_lock := false          # prediction frozen so the cursor can pick a pause point
var pause_at := -1.0            # sim time at which the running shot pauses itself
var auto_paused := false
var pauses := 0
var fc_times := {}              # forecast sample times per ball, for pause planning
var walls_up := false
var term_tip: TermTip
var lbl_boss: Label
var lbl_target: Label
var lbl_score: Label
var score_bar: ProgressBar
var lbl_chain: Label
var lbl_heat: Label
var lbl_line: Label
var lbl_money: Label
var chalk_pips: ChalkPips
var spin_w: SpinWidget
var power_w: PowerMeter
var lbl_hint: Label
var lbl_status: Label
var perk_row: BoxContainer
var room_rect: ColorRect
var fit := ScreenFit.classic()
var fit_key := ""
var debug_hole := -1.0   # capture tool: pretend the phone has this camera cutout
var debug_window := Vector2i.ZERO   # tests: pretend the window is this size
var overlay: Control
var selected_perk := -1
var banner: Label
var banner_t := 0.0
var flags_label: Label
var log_label: Label
var left_panel: Control
var lbl_bounty: RichTextLabel
var heat_fire: FireFx
var heat_title: Label
var bet_row: HBoxContainer
var tray: BallTray
var bottom_bar: Control
var shot_log: Array[String] = []


func _ready() -> void:
	randomize()
	vis_rng.seed = 4242
	sfx = Sfx.new()
	add_child(sfx)
	var room := ColorRect.new()
	room.size = Vector2(1600, 900)
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var room_mat := ShaderMaterial.new()
	room_mat.shader = preload("res://src/view/shaders/room.gdshader")
	room.material = room_mat
	add_child(room)
	room_rect = room
	view = TableView.new()
	view.base_position = TABLE_ORIGIN
	view.home_position = TABLE_ORIGIN
	view.base_scale = TABLE_SCALE
	view.position = TABLE_ORIGIN
	view.scale = Vector2(TABLE_SCALE, TABLE_SCALE)
	add_child(view)
	get_tree().quit_on_go_back = false   # the Android back button opens the menu instead
	_build_ui()
	_load_settings()
	get_window().size_changed.connect(_apply_screen_layout)
	left_panel.minimum_size_changed.connect(_size_hud, CONNECT_DEFERRED)
	# Android reports the camera cutout a moment after launch, and again on rotation.
	var fit_timer := Timer.new()
	fit_timer.wait_time = 1.0
	fit_timer.autostart = true
	fit_timer.timeout.connect(_apply_screen_layout)
	add_child(fit_timer)
	meta.load_file()
	records.load_file()
	screens = MetaScreens.new(self)
	_show_title()


## ================================================================ table setup
func _setup_table() -> void:
	var t := run.current()
	armed.clear()
	temp_pockets.clear()
	rewind_point = {}
	if spin_w:
		spin_w.modulate.a = 0.35 if t.anomaly == "nospin" else 1.0
	layout = run.build_layout()
	var lab: String = t.lab
	view.setup(layout, F_SEMI, F_NUM)
	view.set_felt(Catalog.LABS[lab].felt)
	view.set_lab(lab)
	_new_rack()
	shot_log.clear()
	if log_label:
		log_label.text = ""
	if state != S.TITLE:
		sfx.play_music("endless" if run.endless else str(t.id))
	view.hot_mult = 3 if run.perks.has("heat") else 2
	_sync_hot()
	_refresh_hud()


func _make_sim() -> PoolSim:
	return PoolSim.new(layout)


func _new_rack() -> void:
	sim = _make_sim()
	sim.add_ball(0, Rack.HEAD)
	var r := RandomNumberGenerator.new()
	r.seed = run.rack_seed()
	Rack.build(sim, r, run.ball_set)
	run.apply_physics(sim)
	view.sync_balls(sim, vis_rng, run.imbues)
	is_break = true
	aim_dir = (Rack.FOOT - Rack.HEAD).normalized()
	power = 0.85
	guide_dirty = true
	forecast_dirty = true


## ================================================================ side bets
## Dealt face down each table. Bet the stake blind, peek for half the stake,
## or pass; the first shot closes the betting.
func _refresh_bet() -> void:
	if lbl_bounty == null or run.bounty == "":
		return
	var bt: Dictionary = Catalog.BOUNTIES[run.bounty]
	var known: bool = run.bet_peeked or run.bet_state == "won" or run.bet_state == "passed" and run.shots_taken > 0
	var what: String = bt.name if known else "face down"
	var line := ""
	match run.bet_state:
		"offer":
			line = "Side bet (%s): stake $%d, a %s bet pays $%d" % [what, run.bet_stake(), Catalog.BET_TIERS[int(bt.tier)] if known else "hidden", run.bounty_reward()] if known else "Side bet, face down: stake $%d. Easy, Medium or Hard pays up to $%d." % [run.bet_stake(), run.bet_stake() + int(round(run.bet_stake() * (3.0 + 0.5 * mini(int(run.table_index / 3), 2))))]
		"taken":
			line = "Side bet (%s): $%d riding, pays $%d" % [what, run.bet_stake(), run.bounty_reward()]
		"won":
			line = "Side bet WON: %s" % bt.name
		_:
			line = "Side bet passed: it was \"%s\"" % bt.name if run.shots_taken > 0 else "Side bet passed"
	var bb := Glossary.link(line)
	if known:
		for term in bt.terms:
			bb += "\n[color=#9fb4c8]%s: %s[/color]" % [Glossary.title(term), Glossary.sentence(term)]
	lbl_bounty.text = bb
	lbl_bounty.add_theme_color_override("default_color", Color(0.5, 1.0, 0.6) if run.bet_state == "won" else Color(1.0, 0.85, 0.35))
	for c in bet_row.get_children():
		bet_row.remove_child(c)
		c.queue_free()
	bet_row.visible = run.bet_open() and state == S.AIM
	if not bet_row.visible:
		return
	var bet := _button("Bet $%d" % run.bet_stake(), func():
		if run.take_bet():
			sfx.play("coin", 0.8)
			_refresh_hud()
			_save_progress(), Color(1.0, 0.85, 0.35))
	bet.disabled = run.money < run.bet_stake()
	var peek := _button("Peek $%d" % (run.bet_stake() / 2), func():
		if run.peek_bet():
			sfx.play("coin", 0.5, 1.4)
			_refresh_hud()
			_save_progress(), Color(0.6, 0.8, 1.0))
	peek.disabled = run.bet_peeked or run.money < run.bet_stake() / 2
	var nope := _button("Pass", func():
		run.pass_bet()
		_refresh_hud(), Color(0.6, 0.62, 0.66))
	for b in [bet, peek, nope]:
		b.add_theme_font_size_override("font_size", 14)
		b.custom_minimum_size = Vector2(0, 40 if settings.touch_mode else 30)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bet_row.add_child(b)


## The first ball a player ever sinks gets its score broken down, step by step.
func _explain_first_score(l: Dictionary) -> void:
	if not meta.first_time("score_explained"):
		return
	var text := "%s: worth %s (10 + twice its number) × Chain %s (this shot: ×1, +0.5 per ball already sunk) × Heat %s (this table: +0.5× per scoring shot) = %d points." % [
		l.label, _fmt(l.value), _fmt(l.chain), _fmt(l.heat), int(l.points)]
	if float(l.x) != 1.0:
		text += " Bonuses such as the hot pocket or Perks multiplied it by %s." % _fmt(l.x)
	term_tip.show_text("How that ball scored", text, view.base_position + Vector2(TableLayout.W * 0.5, 60.0) * TABLE_SCALE, 12.0)


## ================================================================ ball info on hover
## Resting the pointer (or a thumb) on a special, imbued or 8-ball says what it does.
var hover_ball := -1
var hover_shown := false


func _update_ball_hover() -> void:
	var idx := -1
	var touch_ok: bool = not settings.touch_mode or (finger_down and finger_still >= LONG_PRESS)
	if touch_ok and sim != null and (state == S.AIM or state == S.PLACE or state == S.HOLD or state == S.PICK) and overlay.get_child_count() == 0 and not dragging:
		var m := _mouse_table()
		var bd := (TableLayout.R * 1.15) * (TableLayout.R * 1.15)
		for i in sim.count():
			if sim.alive[i] == 1 and sim.num[i] != 0:
				var d := sim.pos[i].distance_squared_to(m)
				if d < bd:
					bd = d
					idx = i
	if idx == hover_ball:
		return
	hover_ball = idx
	var info := _ball_info(sim.num[idx]) if idx >= 0 else []
	if info.is_empty():
		if hover_shown:
			term_tip.hide_tip()
			hover_shown = false
		return
	# Above the finger on a touch screen, so the thumb does not cover it.
	term_tip.show_text(info[0], info[1], mouse_pos - (Vector2(0, 70) if settings.touch_mode else Vector2.ZERO), TermTip.SHOW_TIME, info[2] if info.size() > 2 else "")
	hover_shown = true


## [title, text] for a ball worth explaining, or [] for a plain one.
func _ball_info(n: int) -> Array:
	var parts: Array = []
	var k := Catalog.kind_of(n)
	if k != "":
		parts.append(Catalog.BALL_TYPES[k].desc)
		if k == "dice" or k == "wild":
			parts.append("Right now it counts as the %d." % int(Catalog.faces.get(n, 0)))
	var iso: String = run.imbues.get(n, "") if run != null else ""
	if iso != "":
		parts.append("Imbued with %s: %s" % [Catalog.IMBUES[iso].name, Catalog.IMBUES[iso].desc])
	if n == 8:
		parts.append(Glossary.sentence("eight"))
	var pay := _ball_pay(n)
	parts.push_front(pay[0])
	return [Catalog.ball_label(n), " ".join(parts), pay[1]]


## What sinking this one ball on its own would pay right now: the plain points, and
## (in neon) what your Perks, Imbues and the hot pocket add on top.
func _ball_pay(n: int) -> Array:
	if run == null or sim == null:
		return ["", ""]
	var ctx := _shot_ctx()
	ctx["is_break"] = false
	var hot := int(ctx.get("hot_pocket", -1))
	var corner := 0
	for k in [0, 2, 3, 5]:
		if k != hot:
			corner = k
			break
	var ev := func(pk: int) -> Array:
		return [{"type": "ball", "a": 0, "b": n}, {"type": "pocket", "a": n, "pocket": pk, "rails": 0, "at": Vector2.ZERO}]
	var plain_ctx := ctx.duplicate()
	plain_ctx["perks"] = []
	plain_ctx["imbues"] = {}
	plain_ctx["events"] = ev.call(corner)
	var plain := Scorer.score(plain_ctx)
	ctx["events"] = ev.call(corner)
	var full := Scorer.score(ctx)
	if n == 8 and int(full.get("penalty", 0)) > 0:
		return ["Sinking it now costs %d points." % int(full.penalty), ""]
	var line := "Worth %d. Sunk on its own right now: %d points." % [Catalog.ball_points(n), int(plain.total)]
	var extra: Array = []
	var gain := int(full.total) - int(plain.total)
	if gain > 0:
		extra.append("+%d from your Perks and Imbues (%d in all)" % [gain, int(full.total)])
	if hot >= 0:
		ctx["events"] = ev.call(hot)
		var h := Scorer.score(ctx)
		if int(h.total) > int(full.total):
			extra.append("%d in the hot pocket" % int(h.total))
	if int(full.get("money", 0)) > 0:
		extra.append("+$%d" % int(full.money))
	return [line, " · ".join(extra)]


## ================================================================ the Hustler's Kit
## Tools (one charge per table) and consumables share one bar. Set-up items are
## "armed": their effect shows on the prediction at once, tapping them again
## takes them back, and they are only spent when you shoot.
var armed: Array = []            # [{id, undo: Callable}]
var temp_pockets: Array = []     # Trapdoors for the next shot
var rewind_point := {}
var pick_mode := ""              # "spot", "ball", "pocket", "cushion" or "direction"
var pick_ball := -1


func _refresh_items() -> void:
	if item_bar == null:
		return
	for c in item_bar.get_children():
		item_bar.remove_child(c)
		c.queue_free()
	for i in run.tool_slots():
		var id: String = run.tools[i] if i < run.tools.size() else ""
		item_bar.add_child(_item_button(id, true))
	for i in run.item_slots():
		var id: String = run.items[i] if i < run.items.size() else ""
		item_bar.add_child(_item_button(id, false))


func _item_button(id: String, tool: bool) -> Control:
	var b := Button.new()
	var sz := 46.0 if settings.touch_mode else 40.0
	b.custom_minimum_size = Vector2(sz, sz)
	b.focus_mode = Control.FOCUS_NONE
	if id == "":
		b.disabled = true
		b.add_theme_stylebox_override("disabled", _style(Color(0, 0, 0, 0.25), Color(1, 1, 1, 0.1 if not tool else 0.2), 1, 6 if tool else 10))
		b.tooltip_text = "Empty Tool slot" if tool else "Empty Consumable slot"
		return b
	var it: Dictionary = Catalog.ITEMS[id]
	var col: Color = Catalog.WHEN_COLORS[it.when]
	var is_armed := armed.any(func(a): return a.id == id)
	var charges := int(run.tool_charges.get(id, 0)) if tool else 1
	b.add_theme_stylebox_override("normal", _style(Color(0.2, 0.17, 0.08) if is_armed else Color(0.1, 0.12, 0.16), Color(1.0, 0.85, 0.35) if is_armed else Color(col, 0.6), 3 if is_armed else 2, 6 if tool else 10))
	b.add_theme_stylebox_override("hover", _style(Color(0.16, 0.2, 0.26), col, 2, 6 if tool else 10))
	b.add_theme_stylebox_override("pressed", _style(Color(0.2, 0.26, 0.32), col.lightened(0.3), 2, 6 if tool else 10))
	var ic := IconArt.new().setup(id, F_SEMI, sz - 10.0)
	ic.position = Vector2(5, 5)
	ic.size = Vector2(sz - 10.0, sz - 10.0)
	b.add_child(ic)
	if tool:
		var pip := _label(str(charges), 12, Color(1.0, 0.9, 0.5) if charges > 0 else Color(0.6, 0.6, 0.6), F_NUM)
		pip.position = Vector2(sz - 14.0, sz - 18.0)
		b.add_child(pip)
		if charges <= 0:
			b.modulate = Color(1, 1, 1, 0.45)
	b.tooltip_text = "%s (%s)\n%s\n%s" % [it.name, "Tool, one charge per table" if tool else "Consumable", Catalog.WHEN_NAMES[it.when], it.desc]
	b.pressed.connect(func(): _use(id))
	return b


## Can this item be used right now?
func _item_ready(id: String) -> String:
	var it: Dictionary = Catalog.ITEMS[id]
	if it.kind == "tool" and int(run.tool_charges.get(id, 0)) <= 0:
		return "NO CHARGE LEFT ON THIS TABLE"
	match it.when:
		"setup":
			return "" if state == S.AIM else "USE THIS WHILE AIMING"
		"pause":
			return "" if state == S.HOLD else "USE THIS WHILE A SHOT IS PAUSED"
		"after":
			if state != S.AIM:
				return "USE THIS AFTER A SHOT"
			if run.shots_taken == 0:
				return "NO SHOT TO WORK WITH YET"
			if id == "rewind" and rewind_point.is_empty():
				return "NOTHING TO REWIND"
			if id == "slip" and not run.last_chalk_lost:
				return "YOUR LAST SHOT DIDN'T COST CHALK"
			return ""
		_:
			return "" if state == S.AIM or state == S.HOLD else "USE THIS WHILE AIMING OR PAUSED"
	return ""


func _use(id: String) -> void:
	for a in armed:
		if a.id == id:
			_disarm(a)
			return
	var why := _item_ready(id)
	if why != "":
		_flash_banner(why, Color(0.6, 0.85, 1.0), 1.1)
		return
	match id:
		"calledshot", "ghostchalk", "polish", "leadweight", "swap", "freezeframe", "nudge":
			_begin_pick(id, "ball")
		"pocketcover":
			_begin_pick(id, "pocket")
		"trapdoor":
			_begin_pick(id, "cushion")
		"post", "portal", "gravitypebble":
			_begin_pick(id, "spot")
		"secondstrike":
			_begin_hold_action("strike", id)
		"wall":
			_begin_hold_action("wall", id)
		"blink":
			_begin_hold_action("blink", id)
		"englishdial":
			var ci := _cue_index()
			sim.side[ci] = _shot_side()
			sim.spin[ci] = sim.vel[ci].normalized() * _shot_follow() * sim.vel[ci].length() * 0.62 * sim.spin_power
			_spend(id)
			_hold(false)
		"spotter":
			_show_spotter()
		"rewind":
			_rewind()
		"slip":
			if run.use_state_item("slip"):
				_spend(id)
				_flash_banner("CHALK BACK", Color(0.5, 1.0, 0.7), 1.0)
		"triangle":
			_spend(id)
			_fresh_rack()
		"ballinhand":
			_spend(id)
			_begin_place(false)


func _spend(id: String) -> void:
	if run.spend(id):
		sfx.play("coin", 0.5, 1.3)
		_announce_unlocks(meta.on_item_used())
	_refresh_hud()
	_save_progress()


## Arms a set-up item: its effect is live now and it is spent when you shoot.
func _arm(id: String, undo: Callable) -> void:
	armed.append({"id": id, "undo": undo})
	sfx.play("click_soft", 0.7, 1.2)
	_hint("%s is ready for this shot. Right-click to take it back." % Catalog.ITEMS[id].name)
	guide_dirty = true
	_refresh_hud()


func _disarm(a: Dictionary) -> void:
	(a.undo as Callable).call()
	armed.erase(a)
	guide_dirty = true
	_refresh_hud()


## When the shot is struck, every armed item is spent.
func _spend_armed() -> void:
	for a in armed:
		run.spend(a.id)
	if not armed.is_empty():
		_announce_unlocks(meta.on_item_used())
	armed.clear()


func _apply_temp_pockets() -> void:
	layout = run.build_layout()
	for tp in temp_pockets:
		layout.pockets.append(tp)
	sim.layout = layout
	view.setup(layout, F_SEMI, F_NUM)
	view.set_felt(Catalog.LABS[run.current().lab].felt)
	view.set_lab(run.current().lab)
	guide_dirty = true


## Re-racks the balls still on the table and gives a fresh break.
func _fresh_rack() -> void:
	var left: Array = []
	for i in sim.count():
		if sim.num[i] != 0 and sim.alive[i] == 1:
			left.append(sim.num[i])
	sim = _make_sim()
	sim.add_ball(0, Rack.HEAD)
	var r := RandomNumberGenerator.new()
	r.seed = run.rack_seed() + 97 * run.shots_taken
	Rack.build(sim, r, left)
	run.apply_physics(sim)
	view.sync_balls(sim, vis_rng, run.imbues)
	is_break = true
	aim_dir = (Rack.FOOT - Rack.HEAD).normalized()
	_enter_aim()


## Spotter: choose a ball sunk on this table to bring back.
func _show_spotter() -> void:
	var sunk: Array = []
	for i in sim.count():
		if sim.alive[i] == 0 and sim.num[i] != 0 and sim.num[i] != 8:
			sunk.append(sim.num[i])
	if sunk.is_empty():
		_flash_banner("NOTHING SUNK ON THIS TABLE YET", Color(0.6, 0.85, 1.0), 1.1)
		return
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(Color(0.08, 0.075, 0.08, 0.99), Color(0.45, 0.7, 1.0), 2, 14))
	overlay.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	v.add_child(_label("SPOTTER - BRING ONE BACK", 24, Color(0.6, 0.8, 1.0), F_PIXB))
	var grid := GridContainer.new()
	grid.columns = 8
	v.add_child(grid)
	for n in sunk:
		var b := Button.new()
		b.custom_minimum_size = Vector2(58, 58)
		b.tooltip_text = Catalog.ball_label(n)
		var icon := _set_ball_icon(n)
		icon.position = Vector2(9, 9)
		b.add_child(icon)
		var num: int = n
		b.pressed.connect(func():
			_spot_back(num)
			p.queue_free())
		grid.add_child(b)
	v.add_child(_button("Cancel", func(): p.queue_free(), Color(0.6, 0.65, 0.7)))
	p.reset_size()
	p.position = ((fit.view - p.get_combined_minimum_size()) * 0.5).round()


func _spot_back(n: int) -> void:
	var i := sim.index_of(n)
	if i < 0 or sim.alive[i] == 1:
		return
	var spot := Rack.FOOT
	var tries := 0
	while not sim.is_clear_spot(spot, i) and tries < 40:
		spot = Rack.FOOT + Vector2(-TableLayout.R * 2.2 * (tries / 6 + 1), 0).rotated(tries * TAU / 6.0)
		tries += 1
	sim.alive[i] = 1
	sim.pos[i] = spot
	sim.vel[i] = Vector2.ZERO
	view.update_balls(sim)
	_spend("spotter")
	guide_dirty = true


## Rewind: the table, score, Heat and Chalk go back to just before the last shot.
func _rewind() -> void:
	var point := rewind_point
	if point.is_empty() or not run.load_dict(point):
		return
	rewind_point = {}
	run.locked = meta.locked_perks()
	layout = run.build_layout()
	view.setup(layout, F_SEMI, F_NUM)
	view.set_felt(Catalog.LABS[run.current().lab].felt)
	view.set_lab(run.current().lab)
	_restore_snapshot(run.table_snapshot)
	run.spend("rewind")
	shown_score = run.score
	_animate_score(run.score, run.score)
	_sync_hot()
	_flash_banner("REWOUND", Color(0.6, 0.85, 1.0), 1.0)
	sfx.play("resume", 0.7, 0.7)
	_enter_aim()
	_save_progress()


## The run as it stands, with every ball, so Rewind can bring it back.
func _capture_rewind_point() -> void:
	var balls: Array = []
	for i in sim.count():
		balls.append({"n": sim.num[i], "x": sim.pos[i].x, "y": sim.pos[i].y, "alive": sim.alive[i], "m": sim.mass[i]})
	run.table_snapshot = {"balls": balls, "is_break": is_break, "log": shot_log}
	run.phase = "table"
	rewind_point = JSON.parse_string(JSON.stringify(run.to_dict()))


## ---------------------------------------------------------------- picking a target
func _begin_pick(id: String, mode: String) -> void:
	pick_item = id
	pick_mode = mode
	pick_ball = -1
	pick_points = []
	pick_return = state
	state = S.PICK
	view.show_guide = false
	var what := {"ball": "Click a ball.", "pocket": "Click a pocket to cover.", "cushion": "Click a cushion where the Trapdoor opens.", "spot": "Click where it goes."}
	_hint("%s %s Right-click or Esc to cancel." % [Catalog.ITEMS[id].name, what.get(mode, "")])
	if id == "calledshot":
		_hint("Called Shot: click the ball you're calling. Right-click or Esc to cancel.")
	_refresh_hud()


func _pick_radius() -> float:
	match pick_item:
		"post":
			return TableLayout.BUMPER_R
		"portal":
			return TableLayout.PORTAL_R
		"gravitypebble":
			return 10.0
	return TableLayout.R


func _pick_ok(p: Vector2) -> bool:
	var r := _pick_radius()
	if p.x < r + 4 or p.y < r + 4 or p.x > TableLayout.W - r - 4 or p.y > TableLayout.H - r - 4:
		return false
	if pick_item == "gravitypebble":
		return true
	for pk in layout.pockets:
		if (pk.pos as Vector2).distance_to(p) < pk.r + r + 12.0:
			return false
	for i in sim.count():
		if sim.alive[i] == 1 and sim.pos[i].distance_to(p) < TableLayout.R + r + 3.0:
			return false
	for bp in layout.bumpers:
		if (bp.pos as Vector2).distance_to(p) < bp.r + r + 6.0:
			return false
	for q in pick_points:
		if (q as Vector2).distance_to(p) < r * 2.0 + 30.0:
			return false
	for pt in layout.portals:
		if (pt.a as Vector2).distance_to(p) < r * 2.0 + 6.0 or (pt.b as Vector2).distance_to(p) < r * 2.0 + 6.0:
			return false
	return true


func _hover_ball(m: Vector2) -> int:
	var best := -1
	var bd := (TableLayout.R * 1.8) * (TableLayout.R * 1.8)
	for i in sim.count():
		if sim.alive[i] == 0 or sim.num[i] == 0:
			continue
		if pick_item == "swap" and pick_ball == i:
			continue
		var d := sim.pos[i].distance_squared_to(m)
		if d < bd:
			bd = d
			best = i
	return best


func _hover_pocket(m: Vector2) -> int:
	var best := -1
	var bd := 50.0 * 50.0
	for k in layout.pockets.size():
		var pk: Dictionary = layout.pockets[k]
		if pk.closed or k >= 6:
			continue
		var d := (pk.pos as Vector2).distance_squared_to(m)
		if d < bd:
			bd = d
			best = k
	return best


## The nearest point on a cushion, kept clear of the real pockets.
func _cushion_point(m: Vector2) -> Vector2:
	var W := TableLayout.W
	var H := TableLayout.H
	var cands := [Vector2(clampf(m.x, 0, W), 0), Vector2(clampf(m.x, 0, W), H), Vector2(0, clampf(m.y, 0, H)), Vector2(W, clampf(m.y, 0, H))]
	var best: Vector2 = cands[0]
	for c in cands:
		if c.distance_to(m) < best.distance_to(m):
			best = c
	for pk in layout.pockets:
		if (pk.pos as Vector2).distance_to(best) < 90.0:
			return Vector2.INF
	return best


func _update_pick() -> void:
	_pad_cursor(get_process_delta_time())
	var m := _mouse_table()
	view.placing = true
	view.head_only = false
	view.place_hints = []
	view.show_guide = false
	match pick_mode:
		"spot":
			view.place_radius = _pick_radius()
			view.place_pos = m
			view.place_ok = _pick_ok(m)
		"ball":
			var b := _hover_ball(m)
			view.place_radius = TableLayout.R + 4.0
			view.place_pos = sim.pos[b] if b >= 0 else m
			view.place_ok = b >= 0
		"pocket":
			var k := _hover_pocket(m)
			view.place_radius = layout.pockets[k].r if k >= 0 else 20.0
			view.place_pos = layout.pockets[k].pos if k >= 0 else m
			view.place_ok = k >= 0
		"cushion":
			var c := _cushion_point(m)
			view.place_radius = 26.0
			view.place_pos = c if c != Vector2.INF else m
			view.place_ok = c != Vector2.INF
		"direction":
			view.place_radius = 6.0
			view.place_pos = m
			view.place_ok = m.distance_to(sim.pos[pick_ball]) > 6.0
			view.strike_line = [sim.pos[pick_ball], sim.pos[pick_ball] + (m - sim.pos[pick_ball]).normalized() * 70.0]


func _pick_click() -> void:
	if not view.place_ok:
		sfx.play("bad", 0.4)
		return
	var m := _mouse_table()
	var id := pick_item
	match pick_mode:
		"ball":
			var b := _hover_ball(m)
			_picked_ball(id, b)
		"pocket":
			var k := _hover_pocket(m)
			if id == "calledshot_pocket":
				var cb := pick_ball
				run.called = {"ball": sim.num[cb], "pocket": k}
				view.call_ball = cb
				view.call_pocket = k
				_end_pick()
				_arm("calledshot", func():
					run.called = {}
					view.call_ball = -1
					view.call_pocket = -1)
				return
			run.table_mods.covered.append(k)
			_spend(id)
			_end_pick()
			_apply_temp_pockets()
		"cushion":
			var c := _cushion_point(m)
			var n := Vector2.ZERO
			if c.y <= 0.0:
				n = Vector2(0, 1)
			elif c.y >= TableLayout.H:
				n = Vector2(0, -1)
			elif c.x <= 0.0:
				n = Vector2(1, 0)
			else:
				n = Vector2(-1, 0)
			var tp := {"pos": c - n * 6.0, "r": 26.0, "side": true, "dir": -n, "closed": false, "temp": true}
			temp_pockets.append(tp)
			_end_pick()
			_apply_temp_pockets()
			_arm(id, func():
				temp_pockets.erase(tp)
				_apply_temp_pockets())
		"spot":
			var p: Vector2 = view.place_pos
			pick_points.append(p)
			if id == "portal" and pick_points.size() < 2:
				_hint("Now click where the second portal goes.")
				sfx.play("click_soft", 0.6)
				return
			match id:
				"post":
					run.table_mods.bumpers.append([p.x, p.y])
				"portal":
					var a: Vector2 = pick_points[0]
					run.table_mods.portals.append([a.x, a.y, p.x, p.y])
				"gravitypebble":
					sim.extra_wells.append([p, 1.0])
					view.temp_walls = view.temp_walls   # keeps the overlay drawing
					view.pebbles.append(p)
			_spend(id)
			_end_pick()
			if id != "gravitypebble":
				_rebuild_layout()
		"direction":
			var d := (m - sim.pos[pick_ball]).normalized()
			sim.vel[pick_ball] += d * 260.0
			view.strike_line = []
			_spend(id)
			_end_pick()


func _picked_ball(id: String, b: int) -> void:
	match id:
		"calledshot":
			pick_item = "calledshot_pocket"
			pick_ball = b
			pick_mode = "pocket"
			_hint("Now click the pocket you're calling for the %s." % Catalog.ball_label(sim.num[b]))
		"ghostchalk":
			sim.ghost = b
			_end_pick()
			_arm(id, func(): sim.ghost = -1)
			view.ghost_ball = b
		"polish":
			sim.glide[b] = 1
			_end_pick()
			_arm(id, func(): sim.glide[b] = 0)
		"leadweight":
			sim.mass[b] *= 4.0
			_end_pick()
			_arm(id, func(): sim.mass[b] /= 4.0)
		"swap":
			if pick_ball < 0:
				pick_ball = b
				_hint("Swap: now click the ball to trade places with.")
				return
			var p := sim.pos[pick_ball]
			sim.pos[pick_ball] = sim.pos[b]
			sim.pos[b] = p
			view.ball_nodes[pick_ball].position = sim.pos[pick_ball]
			view.ball_nodes[b].position = sim.pos[b]
			_spend(id)
			_end_pick()
		"freezeframe":
			sim.vel[b] = Vector2.ZERO
			sim.spin[b] = Vector2.ZERO
			sim.pinned[b] = 1
			_spend(id)
			_end_pick()
		"nudge":
			pick_ball = b
			pick_mode = "direction"
			_hint("Nudge: click the direction to push it.")


func _cancel_pick() -> void:
	view.strike_line = []
	_end_pick()


func _end_pick() -> void:
	if pick_item == "calledshot_pocket":
		pass
	pick_item = ""
	pick_mode = ""
	pick_points = []
	view.place_radius = 0.0
	view.placing = false
	if pick_return == S.HOLD:
		_rebuild_layout()
		_hold(false)
	else:
		_enter_aim()


## The Pro Shop's removal service: pick a ball to take out of your set.
func _show_remove_picker() -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(Color(0.08, 0.075, 0.08, 0.99), Color(1.0, 0.55, 0.55), 2, 14))
	overlay.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	v.add_child(_label("REMOVE A BALL  ($%d)" % run.removal_cost(), 26, Color(1.0, 0.62, 0.55), F_PIXB))
	v.add_child(_label("It leaves your set for the rest of the run. The 8 always stays.", 14, Color(0.8, 0.82, 0.85), F_REG))
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	v.add_child(grid)
	for n in run.ball_set:
		var b := Button.new()
		b.custom_minimum_size = Vector2(58, 58)
		b.focus_mode = Control.FOCUS_ALL
		b.tooltip_text = Catalog.ball_label(n)
		b.add_theme_stylebox_override("normal", _style(Color(0.12, 0.12, 0.14), Color(1, 1, 1, 0.15), 1, 8))
		b.add_theme_stylebox_override("hover", _style(Color(0.22, 0.14, 0.14), Color(1.0, 0.55, 0.55), 2, 8))
		var icon := _set_ball_icon(n)
		icon.position = Vector2(9, 9)
		b.add_child(icon)
		if n == 8:
			b.disabled = true
			b.tooltip_text = "The 8 always stays"
		var num: int = n
		b.pressed.connect(func():
			var err := run.buy_removal(num)
			if err == "":
				sfx.play("coin", 0.7, 0.7)
				_refresh_shop()
				_refresh_hud()
			else:
				sfx.play("bad", 0.4)
				_flash_banner(err.to_upper(), Color(1, 0.5, 0.4), 1.0))
		grid.add_child(b)
	v.add_child(_button("Cancel", func(): p.queue_free(), Color(0.6, 0.65, 0.7)))
	p.reset_size()
	p.position = ((fit.view - p.get_combined_minimum_size()) * 0.5).round()


## First time a new kind of thing appears in the shop, a line explains it.
func _shop_intro_tip(v: VBoxContainer) -> void:
	var tip := ""
	if run.shop.any(func(it): return it.type == "item") and meta.first_time("items"):
		tip = "NEW: Items. Tools keep a charge every table; Consumables are used once. Blue ones work while aiming, green ones while a shot is paused (press P), amber ones after a shot."
	elif run.shop.any(func(it): return it.type == "ball") and meta.first_time("balls"):
		tip = "NEW: Special balls join your set and rack with the rest. You can also pay to remove a ball from your set (never the 8)."
	if tip != "":
		var l := _label(tip, 15, Color(0.6, 0.95, 0.8), F_REG)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(980, 0)
		v.add_child(l)


## Choosing which ball gets a loose Imbue. Balls already imbued, and the 8, can't.
func _show_imbue_picker(i: int) -> void:
	var item: Dictionary = run.shop[i]
	var iso: Dictionary = Catalog.IMBUES[item.id]
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(Color(0.08, 0.075, 0.08, 0.99), iso.color, 2, 14))
	overlay.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	v.add_child(_label("%s - CHOOSE A BALL  ($%d)" % [str(iso.name).to_upper(), item.cost], 24, iso.color, F_PIXB))
	var why := _label(iso.desc + " High balls are worth more; low balls sink sooner. Each ball holds one Imbue.", 14, Color(0.8, 0.82, 0.85), F_REG)
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	why.custom_minimum_size = Vector2(520, 0)
	v.add_child(why)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	v.add_child(grid)
	var ok: Array = run.imbue_targets()
	for n in run.ball_set:
		var b := Button.new()
		b.custom_minimum_size = Vector2(58, 58)
		b.tooltip_text = Catalog.ball_label(n) + ("" if ok.has(n) else (" - already imbued" if run.imbues.has(n) else " - not allowed"))
		var icon := _set_ball_icon(n)
		icon.position = Vector2(9, 9)
		b.add_child(icon)
		b.disabled = not ok.has(n)
		var num: int = n
		b.pressed.connect(func():
			var err := run.buy_imbue(i, num)
			if err == "":
				sfx.play("coin", 0.9)
				view.refresh_glows(sim, run.imbues)
				_refresh_shop()
				_refresh_hud()
			else:
				sfx.play("bad", 0.4)
				_flash_banner(err.to_upper(), Color(1, 0.5, 0.4), 1.0))
		grid.add_child(b)
	v.add_child(_button("Cancel", func(): p.queue_free(), Color(0.6, 0.65, 0.7)))
	p.reset_size()
	p.position = ((fit.view - p.get_combined_minimum_size()) * 0.5).round()


## A small flat drawing of any ball in the set, numbered or special.
func _set_ball_icon(n: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(40, 40)
	c.size = Vector2(40, 40)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var m := Vector2(20, 20)
		var col := Catalog.ball_color(n)
		if Catalog.is_stripe(n):
			c.draw_circle(m, 18, Color(0.95, 0.93, 0.88))
			c.draw_rect(Rect2(m + Vector2(-17, -9), Vector2(34, 18)), col)
		else:
			c.draw_circle(m, 18, col)
		c.draw_circle(m, 10, Color(0.97, 0.95, 0.9))
		var k := Catalog.kind_of(n)
		if k != "":
			IconArt.paint(c, Catalog.BALL_TYPES[k].motif, m, 0.27, col.darkened(0.3) if col.get_luminance() < 0.7 else (Catalog.BALL_TYPES[k].accent as Color).darkened(0.25), Color(0.97, 0.95, 0.9), F_SEMI, 1.3)
		else:
			var t := str(n)
			var w := F_NUM.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			c.draw_string(F_NUM, m + Vector2(-w * 0.5, 5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.05, 0.05, 0.05)))
	return c


## ================================================================ pausing a shot
## A shot can be paused while it rolls: by hand (P or the Pause button), by
## itself on the first hit (a setting), or at a point planned on the prediction.
## While paused the prediction shows exactly what will happen from here, and
## pause items can change it: hit the cue ball again, raise a wall, or blink it.
func _should_hold() -> bool:
	if pause_at >= 0.0 and sim.time >= pause_at:
		return true
	if settings.pause_on_hit and not auto_paused and sim.cue_contacted:
		auto_paused = true
		return true
	return false


## How loud the cloth should sound: the summed speed of everything rolling.
func _roll_level() -> float:
	if sim == null:
		return 0.0
	var total := 0.0
	for i in sim.count():
		if sim.alive[i] == 1:
			total += sim.vel[i].length()
	return clampf(total / 2600.0, 0.0, 1.0)


func _hold(count: bool = true) -> void:
	if count:
		pauses += 1
		sfx.play("pause", 0.6)
		pause_at = -1.0
		view.plan_marker = Vector2.INF
		if run.perks.has("stillness") and pauses <= 4:
			sim.events.append({"t": sim.time, "type": "boost", "chain": 0.5})
	state = S.HOLD
	hold_action = ""
	view.strike_line = []
	view.show_guide = false
	view.hold_text = _words("PAUSED - use an item, plan a pause (L), or press P to play on")
	_hint("Paused. Items in your bar work now. Click the table or press P to play on.")
	_compute_forecast_from_here()
	_refresh_hud()


func _compute_forecast_from_here() -> void:
	fc_sim = sim.clone()
	fc_sim.events = []
	fc_limit = 30.0
	fc_paths = {}
	fc_times = {}
	view.forecast_text = ""
	view.sink_tags = []
	_step_forecast()


func _update_hold() -> void:
	if fc_sim != null:
		_step_forecast()
	_update_plan_hover()
	var m := _mouse_table()
	var ci := _cue_index()
	match hold_action:
		"strike":
			if m.distance_to(sim.pos[ci]) > 4.0:
				view.strike_line = [sim.pos[ci], sim.pos[ci] + (m - sim.pos[ci]).normalized() * (60.0 + 260.0 * power)]
			power_w.set_power(power)
		"blink":
			view.placing = true
			view.place_radius = 0.0
			view.place_pos = m
			view.place_ok = sim.is_clear_spot(m, ci)
			view.place_hints = []
		"wall":
			if wall_start != Vector2.INF:
				view.temp_walls = view.temp_walls.slice(0, view.temp_walls.size() - (1 if _wall_preview else 0))
				view.temp_walls.append([wall_start, _wall_end(m)])
				_wall_preview = true


var _wall_preview := false


func _wall_end(m: Vector2) -> Vector2:
	var d := m - wall_start
	return wall_start + d.limit_length(WALL_MAX)


const WALL_MAX := 170.0


func _begin_hold_action(kind: String, slot: String) -> void:
	hold_action = kind
	hold_slot = slot
	wall_start = Vector2.INF
	_wall_preview = false
	match kind:
		"strike":
			view.hold_text = _words("SECOND STRIKE - aim with the mouse, set power with the wheel, click to hit")
		"wall":
			view.hold_text = _words("POP-UP WALL - click where it starts, then where it ends")
		"blink":
			view.hold_text = _words("BLINK - click where the cue ball reappears")


func _cancel_hold_action() -> void:
	if hold_action == "wall" and _wall_preview:
		view.temp_walls.pop_back()
	hold_action = ""
	view.strike_line = []
	view.placing = false
	_hold(false)


func _hold_click() -> void:
	var m := _mouse_table()
	var ci := _cue_index()
	match hold_action:
		"strike":
			if m.distance_to(sim.pos[ci]) < 4.0 or sim.alive[ci] == 0:
				return
			sim.vel[ci] = (m - sim.pos[ci]).normalized() * _speed(power) * run.power_mult(false)
			sim.spin[ci] = Vector2.ZERO
			sim.side[ci] = 0.0
			_after_hold_action(true)
			sfx.play("cue", 0.4 + power * 0.6)
		"blink":
			if sim.alive[ci] == 0 or not sim.is_clear_spot(m, ci):
				sfx.play("bad", 0.4)
				return
			sim.pos[ci] = m
			view.ball_nodes[ci].roll_to(m)
			view.placing = false
			_after_hold_action(true)
		"wall":
			if wall_start == Vector2.INF:
				wall_start = m
				return
			var b := _wall_end(m)
			if wall_start.distance_to(b) < 30.0:
				return
			_add_wall(wall_start, b)
			_after_hold_action(false)
		_:
			if view.plan_hover != Vector2.INF and plan_lock:
				_set_pause_point()
			_play_on()


## Two faces and the end points, exactly like a cushion, for the rest of the shot.
func _add_wall(a: Vector2, b: Vector2) -> void:
	var n := (b - a).orthogonal().normalized()
	sim.layout.segments.append({"a": a, "b": b, "n": n})
	sim.layout.segments.append({"a": b, "b": a, "n": -n})
	if not _wall_preview:
		view.temp_walls.append([a, b])
	_wall_preview = false
	walls_up = true
	sfx.play("wall", 0.7)


func _after_hold_action(cue_move: bool) -> void:
	if cue_move and run.perks.has("afterimage"):
		sim.events.append({"t": sim.time, "type": "boost", "chain": 1.0})
	_spend(hold_slot)
	hold_action = ""
	view.strike_line = []
	_hold(false)


func _play_on() -> void:
	if state != S.HOLD:
		return
	hold_action = ""
	view.hold_text = ""
	view.strike_line = []
	view.placing = false
	if not plan_lock:
		view.forecast_paths = []
		fc_complete = false
	plan_lock = false
	view.plan_hover = Vector2.INF
	fc_sim = null
	state = S.ROLL
	sfx.play("resume", 0.6)
	_hint("Click or press Space to fast-forward. P pauses.")


## Lock the prediction, then the cursor slides along the cue ball's predicted
## path; click to make the shot pause when it gets there.
func _toggle_plan() -> void:
	plan_lock = not plan_lock
	view.plan_hover = Vector2.INF
	fc_paths = {}   # never plan on a prediction left over from an earlier shot
	fc_times = {}
	if plan_lock:
		forecast_dirty = true
		forecast_timer = 0.0
		_hint("Prediction locked. Move along the cue ball's line and click to set a pause point. L unlocks.")
	else:
		_hint("Prediction unlocked.")
	guide_dirty = true


func _plan_path() -> Array:
	var ci := _cue_index()
	if not fc_paths.has(ci) or not fc_times.has(ci):
		return []
	return [fc_paths[ci], fc_times[ci]]


var plan_hover_t := -1.0


func _update_plan_hover() -> void:
	if not plan_lock:
		view.plan_hover = Vector2.INF
		return
	# Every moving ball's predicted line can carry a pause point, not just the cue ball's.
	var m := _mouse_table()
	var bd := 45.0 * 45.0
	var best_p := Vector2.INF
	var best_t := -1.0
	for bi in fc_paths:
		if not fc_times.has(bi):
			continue
		var pts: PackedVector2Array = fc_paths[bi]
		var ts: PackedFloat32Array = fc_times[bi]
		for i in mini(pts.size(), ts.size()):
			var d := pts[i].distance_squared_to(m)
			if d < bd:
				bd = d
				best_p = pts[i]
				best_t = ts[i]
	view.plan_hover = best_p
	plan_hover_t = best_t


func _set_pause_point() -> void:
	if plan_hover_t < 0.0 or view.plan_hover == Vector2.INF:
		sfx.play("bad", 0.3)
		return
	# Forecast times start at zero from the moment the prediction was made.
	pause_at = (sim.time if state == S.HOLD else 0.0) + maxf(plan_hover_t, PoolSim.STEP)
	view.plan_marker = view.plan_hover
	sfx.play("click_soft", 0.7)
	_hint("Pause point set. The shot will stop there. L unlocks the prediction.")


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
		S.HOLD:
			_update_hold()
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
	sfx.set_roll(_roll_level() if state == S.ROLL else 0.0)
	_update_ball_hover()
	if touch_shoot:
		var label := "SHOOT"
		if state == S.ROLL:
			label = "PAUSE"
		elif state == S.PICK or (state == S.HOLD and hold_action != ""):
			label = "CANCEL"
		elif state == S.HOLD:
			label = "PLAY ON"
		if state == S.AIM and shoot_hold >= 0.0:
			shoot_hold += delta
			var bars := int(clampf(shoot_hold / SHOOT_HOLD, 0.0, 1.0) * 5.0)
			label = "HOLD " + "▮".repeat(bars) + "▯".repeat(5 - bars)
			if shoot_hold >= SHOOT_HOLD:
				shoot_hold = -1.0
				shoot_fired = true
				_shoot(power)
		elif state == S.AIM:
			label = "HOLD TO SHOOT"
		if touch_shoot.text != label:
			touch_shoot.text = label
		touch_place.visible = state == S.AIM and is_break
	if finger_down:
		finger_still += delta
	var cue_i := _cue_index()
	view.cue_visible = (state == S.AIM or state == S.STRIKE) and sim != null and sim.alive[cue_i] == 1
	if sim:
		view.cue_pos = sim.pos[cue_i]


var mouse_pos := Vector2(800, 400)


func _input(e: InputEvent) -> void:
	if rebinding != "" and e is InputEventKey and e.pressed and not e.echo:
		if e.keycode != KEY_ESCAPE:
			settings.bind(rebinding, e.keycode)
			_save_settings()
		rebinding = ""
		get_viewport().set_input_as_handled()
		_show_controls()
		return
	if e is InputEventMouse:
		mouse_pos = e.position
		if e is InputEventMouseMotion:
			pad_active = false
			nav_active = false
			if finger_down and e.position.distance_to(finger_anchor) > 10.0:
				finger_anchor = e.position
				finger_still = 0.0
		elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			finger_down = e.pressed
			finger_anchor = e.position
			finger_still = 0.0
	if e is InputEventJoypadMotion:
		joy_axes[e.axis] = e.axis_value
	if e is InputEventJoypadButton and e.pressed:
		pad_active = true
		if not paused and overlay.get_child_count() == 0:
			_joy_button(e.button_index)
			get_viewport().set_input_as_handled()
			return
	# First arrow/D-pad press on a menu starts keyboard or gamepad navigation.
	for act in ["ui_down", "ui_up", "ui_left", "ui_right"]:
		if e.is_action_pressed(act) and overlay.get_child_count() > 0:
			nav_active = true
			if get_viewport().gui_get_focus_owner() == null and _focus_first(overlay):
				get_viewport().set_input_as_handled()
			break
	# Tab is also Godot UI focus navigation, so take it before the GUI does.
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_TAB:
		if info_open:
			_close_run_info()
			get_viewport().set_input_as_handled()
		elif not paused and (state == S.AIM or state == S.PLACE or state == S.SHOP):
			_show_run_info()
			get_viewport().set_input_as_handled()


func _mouse_table() -> Vector2:
	return (mouse_pos - view.base_position) / TABLE_SCALE


var last_aim_mouse := Vector2.INF
var aim_hold_t := 0.0
const AIM_HOLD := 0.25
const AIM_TAP := 0.25    # degrees per tap of an aim key or nudge button
const AIM_FINE := 0.05   # with Shift
const POWER_STEP := 0.05
var fc_power := -1.0


## Steps power to the next 5% mark up or down (42% goes to 45%, then 50%).
func _bump_power(dir: int) -> void:
	var steps := power / POWER_STEP
	var k := floorf(steps + 0.001) + 1.0 if dir > 0 else ceilf(steps - 0.001) - 1.0
	power = clampf(k * POWER_STEP, POWER_STEP, 1.0)
	forecast_dirty = true
	if power_w:
		power_w.set_power(power)
	if power_slider and power_slider.value != power:
		power_slider.set_value_no_signal(power)


func _step_aim(dir: float) -> void:
	if settings.smooth_arrows:
		return
	var deg := AIM_FINE if Input.is_key_pressed(KEY_SHIFT) else AIM_TAP
	aim_dir = aim_dir.rotated(deg_to_rad(deg * dir))
	guide_dirty = true


func _update_aim(delta: float) -> void:
	var ci := _cue_index()
	var m := _mouse_table()
	if dragging:
		var pull := (drag_origin - m).dot(aim_dir)
		if settings.invert_drag:
			pull = -pull
		drag_power = clampf(pull / (DRAG_FULL * settings.pull), 0.0, 1.0)
		view.cue_pull = drag_power * 90.0
		power_w.set_power(drag_power)
	else:
		var may_steer: bool = touch_aiming if settings.touch_mode else true
		var mouse_moved := m.distance_to(last_aim_mouse) > 0.5
		last_aim_mouse = m
		if settings.touch_mode and settings.fine_drag:
			# Fine aim: the finger can be anywhere. Moving it across the aim line turns
			# the shot a little that way, so the target stays in view and wobble is small.
			may_steer = false
			if touch_aiming and not plan_lock:
				if touch_last != Vector2.INF:
					var across := (m - touch_last).dot(aim_dir.orthogonal())
					if across != 0.0:
						aim_dir = aim_dir.rotated(across * FINE_DRAG)
						guide_dirty = true
				touch_last = m
			else:
				touch_last = Vector2.INF
		if (mouse_moved or settings.touch_mode) and not fine_aim and not plan_lock and not pad_active and may_steer and _mouse_over_table() and m.distance_to(sim.pos[ci]) > 4.0:
			var nd := (m - sim.pos[ci]).normalized()
			if nd.angle_to(aim_dir) != 0.0:
				aim_dir = nd
				guide_dirty = true
		var rot := 0.0
		var spd := (0.06 if Input.is_key_pressed(KEY_SHIFT) else 0.6) * settings.aim_speed
		# A tap turns exactly a quarter of a degree (0.05 with Shift); holding for a quarter of a
		# second sweeps smoothly. The Smooth arrows setting sweeps straight away.
		var held_l := Input.is_key_pressed(settings.keys.aim_left)
		var held_r := Input.is_key_pressed(settings.keys.aim_right)
		aim_hold_t = aim_hold_t + delta if (held_l or held_r or touch_rot != 0.0) else 0.0
		if aim_hold_t > AIM_HOLD or settings.smooth_arrows:
			if held_l:
				rot -= spd
			if held_r:
				rot += spd
			rot += touch_rot * 0.3
		if settings.touch_mode and power_slider.value != power:
			power_slider.set_value_no_signal(power)
		var jx := _joy(JOY_AXIS_LEFT_X)
		if jx != 0.0:
			pad_active = true
			var precise: bool = joy_axes.get(JOY_AXIS_TRIGGER_LEFT, 0.0) > 0.5
			rot += jx * absf(jx) * (0.25 if precise else 2.0) * settings.aim_speed
		var jy := _joy(JOY_AXIS_RIGHT_Y)
		if jy != 0.0:
			pad_active = true
			power = clampf(power - jy * delta * 0.8, 0.02, 1.0)
			forecast_dirty = true
		if rot != 0.0:
			aim_dir = aim_dir.rotated(deg_to_rad(rot) * delta * 30.0)
			guide_dirty = true
		view.cue_pull = power * 18.0
		power_w.set_power(power)
	# Any change of power, from the wheel, keys, slider or a drag, re-runs the prediction.
	var cp := _current_power()
	if absf(cp - fc_power) > 0.004:
		fc_power = cp
		forecast_dirty = true
		forecast_timer = minf(forecast_timer, 0.06)
	view.cue_dir = aim_dir
	_update_coach()
	if guide_dirty:
		guide_dirty = false
		forecast_dirty = true
		forecast_timer = 0.09
		view.guide = TableView.compute_guide(sim, aim_dir, _shot_follow(), _shot_side(), true)   # the full line, for every cue
		view.show_guide = true
		_update_preview()
	_update_plan_hover()
	if not _forecast_wanted():
		view.forecast_paths = []
		fc_complete = false
		view.forecast_text = ""
		view.sink_tags = []
		fc_sim = null
	elif forecast_dirty:
		forecast_timer -= delta
		if forecast_timer <= 0.0:
			forecast_dirty = false
			_compute_forecast()
	elif fc_sim != null:
		_step_forecast()


var coaching := false
var coach_seen_pot := false


func _update_coach() -> void:
	if not coaching:
		view.coach_text = ""
		return
	var cue: Vector2 = sim.pos[_cue_index()]
	if run.shots_taken == 0:
		view.coach_text = "Drag on the table to aim, fine-tune with the FINE AIM strip,\nset power, then HOLD SHOOT. Break the rack!" if settings.touch_mode else "Press on the table, drag BACK and release to shoot.\nFurther = harder. Break the rack!"
	elif view.guide.get("obj_pot", false) or view.guide.get("obj2_pot", false):
		coach_seen_pot = true
		view.coach_text = "A gold ring = that ball is going in.\nThe tag on the pocket shows the points."
	elif not coach_seen_pot:
		view.coach_text = "Swing your aim until a line ends in a gold ring.\nThe white ring shows where the cue ball hits."
	elif run.heat >= 1:
		view.coach_text = "Heat is building! Every scoring shot raises it.\nThe glowing pocket pays ×2."
	else:
		view.coach_text = ""
	view.coach_pos = cue + Vector2(0, 50 if cue.y < TableLayout.H * 0.6 else -110)


func _mouse_over_table() -> bool:
	var m := _mouse_table()
	return m.x > -90 and m.y > -90 and m.x < TableLayout.W + 90 and m.y < TableLayout.H + 90


func _current_power() -> float:
	return drag_power if dragging else power


func _shot_ctx() -> Dictionary:
	var c := run.shot_ctx(_current_power(), sim, is_break)
	c["follow"] = _shot_follow()
	c["side"] = _shot_side()
	return c


var pre_ctx := {}


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
	if r.eight_fine > 0:
		view.preview_text = "-$%d" % r.eight_fine
		view.preview_pocket = pocket
	elif r.scored or r.penalty > 0:
		view.preview_text = "%+d" % (r.total - r.penalty)
		view.preview_pocket = pocket


var fc_sim: PoolSim
var fc_paths := {}
const FORECAST_DOT_GAP := 7.0
var fc_complete := false       # a finished prediction is on screen
var fc_limit := 12.0


## Paths are drawn with the all-balls option and on tables that bend a ball's
## path, since a straight guideline alone would mislead there.
func _show_paths() -> bool:
	return state == S.HOLD or plan_lock or settings.guide_lines == 1 or sim.tilt != Vector2.ZERO or sim.well_strength != 0.0


func _forecast_wanted() -> bool:
	return _show_paths() or run.perks.has("oracle") or run.perks.has("lens")


## Starts an incremental forecast; _step_forecast advances it within a frame budget.
func _compute_forecast() -> void:
	fc_sim = sim.clone()
	fc_sim.strike(aim_dir, _speed(_current_power()) * run.power_mult(is_break), _shot_follow(), _shot_side())
	# Bent tables only need the opening curve; the full picture is the option or Perk.
	fc_limit = 30.0 if settings.guide_lines == 1 or plan_lock or run.perks.has("oracle") else 2.5
	fc_paths = {}
	fc_times = {}
	view.forecast_text = ""
	view.sink_tags = []
	_step_forecast()


func _step_forecast() -> void:
	if fc_sim == null:
		return
	var t0 := Time.get_ticks_usec()
	# Paused or planning, nothing else needs the frame, so the prediction gets most of it.
	var budget := 14000 if state == S.HOLD or plan_lock else 10000
	while fc_sim.moving() and fc_sim.time < fc_limit and Time.get_ticks_usec() - t0 < budget:
		fc_sim.step(PoolSim.STEP)
		for i in fc_sim.count():
			if fc_sim.alive[i] == 1 and fc_sim.vel[i] != Vector2.ZERO:
				if not fc_paths.has(i):
					fc_paths[i] = PackedVector2Array([sim.pos[i]])
					fc_times[i] = PackedFloat32Array([0.0])
				var last: Vector2 = fc_paths[i][fc_paths[i].size() - 1]
				if last.distance_squared_to(fc_sim.pos[i]) >= FORECAST_DOT_GAP * FORECAST_DOT_GAP:
					fc_paths[i].append(fc_sim.pos[i])
					fc_times[i].append(fc_sim.time)
	var done := not fc_sim.moving() or fc_sim.time >= fc_limit
	var out: Array = []
	if _show_paths():
		for i in fc_paths:
			var n: int = fc_sim.num[i]
			if done and fc_sim.alive[i] == 1:
				fc_paths[i].append(fc_sim.pos[i])
			var c := Color(1, 1, 1) if n == 0 else Catalog.ball_color(n)
			out.append({"points": fc_paths[i], "color": c if n == 8 else c.lightened(0.25), "halo": Color(1, 1, 1) if n == 8 else Color(0, 0, 0),
				"end": done and fc_sim.alive[i] == 1, "potted": fc_sim.alive[i] == 0})
	# The last finished prediction stays up while the next is worked out, so the
	# lines never shrink back to stubs while you aim; partial ones show only at first.
	if done or not fc_complete:
		view.forecast_paths = out
	if done:
		fc_complete = true
	if done:
		if run.perks.has("oracle"):
			_show_shot_forecast()
		if run.perks.has("lens"):
			_show_sink_tags()
		fc_sim = null


## Long Lens: a tag on every pocket a ball is predicted to sink into, with its pay.
func _show_sink_tags() -> void:
	var ctx := _shot_ctx()
	ctx["events"] = fc_sim.events
	ctx["cue_end"] = fc_sim.pos[fc_sim.index_of(0)]
	var r := Scorer.score(ctx)
	var tags: Array = []
	if r.scored:
		for l in r.lines:
			if l.get("kind", "") == "pot":
				tags.append([int(l.pocket), "+%d" % int(l.points)])
	view.sink_tags = tags


## Second Sight: score the simulated shot with the same rules the real one will use.
func _show_shot_forecast() -> void:
	var ctx := _shot_ctx()
	ctx["events"] = fc_sim.events
	ctx["cue_end"] = fc_sim.pos[fc_sim.index_of(0)]
	var r := Scorer.score(ctx)
	view.forecast_text = "This shot: %+d" % (r.total - r.penalty) if r.scored or r.penalty > 0 else "This shot: " + str(r.foul)


func _shot_follow() -> float:
	return 0.0 if run.current().anomaly == "nospin" else follow


func _shot_side() -> float:
	return 0.0 if run.current().anomaly == "nospin" else side


func _speed(p: float) -> float:
	return MIN_SPEED + pow(p, 1.35) * (MAX_SPEED - MIN_SPEED)


func _update_place() -> void:
	_pad_cursor(get_process_delta_time())
	var m := _mouse_table()
	var ci := _cue_index()
	m.x = clampf(m.x, TableLayout.R, (Rack.HEAD.x if place_head_only else TableLayout.W - TableLayout.R))
	m.y = clampf(m.y, TableLayout.R, TableLayout.H - TableLayout.R)
	view.placing = true
	view.head_only = place_head_only
	view.place_pos = m
	view.place_ok = sim.is_clear_spot(m, ci)
	view.show_guide = false
	if m != last_place:
		last_place = m
		view.place_hints = _pots_from(m) if view.place_ok else []


## Which pots would be on from a candidate cue-ball spot (ball in hand).
func _pots_from(p: Vector2) -> Array:
	var ci := _cue_index()
	var old_pos := sim.pos[ci]
	var old_alive := sim.alive[ci]
	sim.pos[ci] = p
	sim.alive[ci] = 1
	var out: Array = []
	var cands := AutoPlayer.candidates(sim, run)
	for c in cands.slice(0, 8):
		out.append([sim.pos[c.obj], layout.pockets[c.pocket].pos])
	sim.pos[ci] = old_pos
	sim.alive[ci] = old_alive
	return out


func _shoot(p: float) -> void:
	if p < 0.02:
		return
	shot_power = p
	strike_t = 0.0
	state = S.STRIKE
	view.show_guide = false
	view.coach_text = ""
	view.forecast_paths = []
	fc_complete = false
	view.forecast_text = ""
	view.sink_tags = []
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
	_spend_armed()
	_capture_rewind_point()
	sim_accum = 0.0
	pre_ctx = run.shot_ctx(shot_power, sim, is_break)
	pre_ctx["follow"] = _shot_follow()
	pre_ctx["side"] = _shot_side()
	start_pos.clear()
	for i in sim.count():
		if sim.alive[i] == 1:
			start_pos[sim.num[i]] = sim.pos[i]
	live_chain = Scorer.start_chain(pre_ctx)
	live_contacted = false
	_set_meters(live_chain, run.heat)
	sim.strike(aim_dir, _speed(shot_power) * run.power_mult(is_break), _shot_follow(), _shot_side())
	if run.shots_taken >= 1 and meta.first_time("pause"):
		_flash_banner("TIP: PRESS P (OR PAUSE) TO FREEZE A SHOT", Color(0.55, 0.95, 0.85), 2.6)
	sfx.play("cue", 0.4 + shot_power * 0.8, 0.9 + randf() * 0.2)
	if shot_power > 0.8:
		view.add_shake(3.0 * shot_power)
	ev_index = 0
	fast = false
	auto_paused = false
	pauses = 0
	view.plan_marker = view.plan_marker if pause_at >= 0.0 else Vector2.INF
	state = S.ROLL
	_hint("P (or the Pause button) pauses the shot. Click or Space to fast-forward.")


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
	var hold_now := false
	for i in steps:
		if _should_hold():
			hold_now = true
			break
		sim.step(PoolSim.STEP)
		_consume_events()
		if not sim.moving():
			break
	if not hold_now:
		hold_now = _should_hold()
	if hold_now and sim.moving():
		view.update_balls(sim)
		_hold()
		return
	view.update_balls(sim)
	if run.heat >= 3 and sim.alive[_cue_index()] == 1:
		var cv := sim.vel[_cue_index()]
		if cv.length() > 120.0:
			var heat := clampf((run.heat - 2) / 5.0, 0.2, 1.0)
			view.trail(sim.pos[_cue_index()], Color(1.0, 0.55 - heat * 0.3, 0.1).lerp(Color(0.78, 0.92, 1.0), 1.0 if run.heat >= 7 else 0.0), heat)
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
		_new_rack()
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
		if not demo:
			_grow_chain(e)
		match e.type:
			"portal":
				sfx.play("portal", 0.7)
			"ball":
				var v := clampf(e.speed / 1600.0, 0.05, 1.0) * (0.3 if demo else 1.0)
				if e.speed > 900.0 and not demo:
					var ia := sim.index_of(e.a)
					var ib := sim.index_of(e.b)
					view.spark((sim.pos[ia] + sim.pos[ib]) * 0.5, clampf(e.speed / 2000.0, 0.3, 1.0))
				sfx.play("click" if v > 0.25 else "click_soft", v, 0.9 + randf() * 0.25)
			"rail":
				var v := clampf(e.speed / 1800.0, 0.03, 0.9) * (0.3 if demo else 1.0)
				sfx.play("rail", v, 0.9 + randf() * 0.2)
				# A hard knock right at a pocket mouth is a rattle.
				if not demo and e.has("at") and e.speed > 260.0:
					for k in layout.pockets.size():
						if not layout.pockets[k].closed and (e.at as Vector2).distance_to(layout.pockets[k].pos) < 72.0:
							sfx.play("pocket", 0.35, 1.7)
							view.add_shake(1.5)
							view.popup(e.at, "rattle", Color(0.8, 0.85, 0.9), 15, 0.7)
							break
			"bumper":
				sfx.play("bumper", 0.7)
				var bi := sim.index_of(e.a)
				view.burst(sim.pos[bi], Color(0.3, 1, 1), 10, 160)
			"pocket":
				if not demo and e.a != 0 and FireFx.level_for(run.heat) >= 3:
					view.burst(e.at, Color(1.0, 0.55, 0.15) if run.heat < 7 else Color(0.75, 0.9, 1.0), 20, 240)
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
					if e.pocket == run.hot_pocket:
						view.ring(pp, Color(1, 0.5, 0.1), 80)
						view.add_shake(4.0)
					view.add_shake(1.5)


## Live Chain meter while the balls roll. The scorer remains the source of truth.
func _grow_chain(e: Dictionary) -> void:
	var before := live_chain
	if e.type == "ball" and (e.a == 0 or e.b == 0):
		live_contacted = true
	if e.type == "pocket":
		if e.a != 0:
			live_chain += Scorer.AFTER_POT
	else:
		live_chain += Scorer.chain_step(e, pre_ctx, live_contacted)
	if live_chain != before:
		_set_meters(live_chain, run.heat)


func _inward(k: int) -> Vector2:
	return layout.pockets[k].dir


## ================================================================ tally
func _settled() -> void:
	view.update_balls(sim)
	var ctx := pre_ctx.duplicate()
	ctx["events"] = sim.events
	ctx["cue_end"] = sim.pos[_cue_index()]
	ctx["start_pos"] = start_pos
	ctx["rng"] = run.rng
	result = Scorer.score(ctx)
	tally_i = 0
	tally_timer = 0.25
	tally_phase = 0
	state = S.TALLY
	sfx.duck(true)
	_hint("Click to skip the count.")
	if not result.scored:
		var free_break: bool = is_break and result.foul == "Miss"
		var insured: bool = run.perks.has("insurance") and run.insured_used < 2
		var msg: String = result.foul
		if result.foul == Scorer.EIGHT_FOUL:
			msg += " - lose %d points" % result.penalty if result.penalty > 0 else (" - pay $%d" % result.eight_fine if result.eight_fine > 0 else "")
		elif free_break:
			msg = "Dry break - no penalty"
		elif insured:
			msg += " - insured"
		elif run.current().id == "local" and not run.forgiven and result.foul != "Wrong pocket" and result.foul != "Wrong ball first":
			msg += " - the house lets this one go"
		else:
			msg += " - lose %d chalk" % (2 if run.perks.has("glasscannon") else 1)
		if result.foul != Scorer.EIGHT_FOUL and result.penalty > 0:
			msg += ", and %d points for the 8" % result.penalty
		lbl_line.text = msg
		_flash_banner(result.foul.to_upper(), Color(1, 0.4, 0.35) if not free_break else Color(0.8, 0.85, 0.9), 1.0)
		if not free_break:
			sfx.play("bad", 0.8)
		tally_phase = 2
		tally_timer = 0.9


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
			var penalty: int = result.penalty
			lbl_line.text = "Shot total: %d" % total
			if penalty > 0:
				lbl_line.text += "\nThe 8 sank: -%d" % penalty
				view.popup(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.38), "-%d" % penalty, Color(1.0, 0.4, 0.35), 34, 1.6)
				sfx.play("bad", 0.7)
			if result.money > 0:
				view.popup(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.62), "+$%d" % result.money, Color(1.0, 0.85, 0.3), 22, 1.2)
				sfx.play("coin", 0.6)
			sfx.play("score", 0.8, 1.0 + minf(0.5, total / 4000.0))
			var mid := Vector2(TableLayout.W * 0.5, TableLayout.H * 0.5)
			var size := int(clampf(30.0 + sqrt(total) * 0.9, 30.0, 80.0))
			view.popup(mid, "+%d" % total, Color(1.0, 0.85, 0.35), size, 1.6)
			view.add_shake(clampf(total / 120.0, 1.0, 9.0))
			view.punch(clampf(total / 20000.0, 0.008, 0.03))
			if total * 2 >= run.target():
				view.popup(mid + Vector2(0, 62), "HUGE SHOT!", Color(1.0, 0.5, 0.3), 30, 1.5)
				view.burst(mid, Color(1.0, 0.75, 0.3), 60, 420)
				sfx.play("clear", 0.45, 1.3)
			_animate_score(run.score, maxi(0, run.score + total - penalty))
	elif tally_phase == 1:
		tally_phase = 2
		tally_timer = 0.05
	else:
		_after_shot()


func _apply_tally_line(l: Dictionary, i: int) -> void:
	if i == 0:
		_explain_first_score(l)
	_set_meters(l.chain, run.heat)
	var p: Vector2 = layout.pockets[l.pocket].pos + _inward(l.pocket) * 80.0
	p += Vector2(randf_range(-20, 20), randf_range(-10, 10))
	var big: bool = float(l.x) > 1.0
	var col := Color(1.0, 0.45, 0.3) if big else Color(1.0, 0.85, 0.35)
	sfx.play("xmult" if big else "tick", 0.7, pow(1.059, i))
	if big:
		view.add_shake(2.5)
		view.punch(0.012)
	var sum := "%s × Chain %s × Heat %s" % [_fmt(l.value), _fmt(l.chain), _fmt(l.heat)]
	if big:
		sum += " × %s" % _fmt(l.x)
	lbl_line.text = "%s: %s = %d" % [l.label, sum, l.points]
	if not (l.tags as Array).is_empty():
		lbl_line.text += "\n" + ", ".join(l.tags)
	view.popup(p, "+%d" % l.points, col, 24, 1.0)


func _after_shot() -> void:
	sfx.duck(false)
	sim.clear_shot_flags()
	view.ghost_ball = -1
	view.call_ball = -1
	view.call_pocket = -1
	view.pebbles = []
	if not temp_pockets.is_empty():
		temp_pockets.clear()
		_apply_temp_pockets()
	pause_at = -1.0
	view.plan_marker = Vector2.INF
	if walls_up:
		walls_up = false
		view.temp_walls = []
		layout = run.build_layout()
		sim.layout = layout
	var was_break := is_break
	is_break = false
	var out := run.apply_shot(result, was_break, sim.object_balls_left(), sim.alive[_cue_index()] == 1)
	run.apply_physics(sim)   # one-shot items such as Magnet Charm wear off
	for n in run.respot_echo(result, sim):
		view.popup(Rack.FOOT + Vector2(0, -40), "Echo returns", Color(0.75, 0.6, 1.0), 20, 1.3)
	for b in view.ball_nodes.values():
		b.label_node.queue_redraw()   # Dice and Wild show their new numbers
	_log_shot(was_break, out)
	_announce_unlocks(meta.on_shot(result, run))
	if out.has("bounty"):
		sfx.play("coin", 1.0, 1.1)
		_flash_banner("SIDE BET WON!  +$%d" % run.bounty_reward(), Color(1.0, 0.85, 0.35), 1.3)
		_refresh_bet()
		view.burst(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.5), Color(1.0, 0.85, 0.35), 40, 300)
	for e in sim.events:
		if e.type == "shatter":
			view.burst(e.at, Color(0.75, 0.9, 1.0), 26, 260)
			sfx.play("bad", 0.5, 1.6)
	for n in result.get("lost_balls", []):
		view.popup(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.66), "%s left your set" % Catalog.ball_label(n), Color(1.0, 0.6, 0.6), 20, 1.5)
	if out.has("heart"):
		_flash_banner("+1 CHALK FROM THE HEART", Color(1.0, 0.5, 0.65), 1.2)
	for n in result.shattered:
		view.popup(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.6), "Glass %d-ball shattered!" % n, Color(0.7, 0.85, 1.0), 20, 1.5)
		view.refresh_glows(sim, run.imbues)
	_animate_score(shown_score, run.score)
	if out.cleared:
		_table_cleared()
		return
	if out.over:
		_refresh_hud()
		_game_over()
		return
	_sync_hot()
	if out.has("forgiven"):
		_flash_banner("THE HOUSE FORGIVES YOU", Color(0.6, 0.9, 1.0), 1.2)
	if out.has("layout_changed"):
		_rebuild_layout()
	if out.rack_cleared:
		_flash_banner("RACK CLEARED  +1 CHALK", Color(0.5, 1.0, 0.7), 1.6)
		sfx.play("clear", 0.6)
		_new_rack()
		_enter_aim()
	elif out.ball_in_hand:
		_begin_place(was_break)   # scratch on the break: behind the head string
	else:
		_enter_aim()
	_refresh_hud()
	_save_progress()


## Shrinking Pockets: rebuild pocket geometry between shots, keeping the balls.
func _rebuild_layout() -> void:
	layout = run.build_layout()
	sim.layout = layout
	run.apply_physics(sim)
	guide_dirty = true
	view.setup(layout, F_SEMI, F_NUM)
	view.set_felt(Catalog.LABS[run.current().lab].felt)
	view.set_lab(run.current().lab)
	view.burst(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.5), Color(1, 0.5, 0.4), 12, 120)


var rebinding := ""
var last_place := Vector2(-1, -1)
var chosen_handicap := 0


func _sync_hot() -> void:
	view.hot_pocket = run.hot_pocket
	view.second_pocket = 5 - run.hot_pocket if run.current().anomaly == "onepocket" and run.hot_pocket >= 0 else -1
	view.element_pockets = Catalog.POCKET_ELEMENTS if run.current().id == "elements" else []


func _enter_aim() -> void:
	state = S.AIM
	view.placing = false
	guide_dirty = true
	touch_aiming = false
	var how := "Drag %s and release to shoot." % ("forward" if settings.invert_drag else "back")
	if settings.click_shoot:
		how = "Set power with the wheel or Up/Down, then click to shoot."
	if settings.touch_mode:
		how = "Aim, set power, then hold SHOOT."
	if is_break:
		_hint("Break! %s H: move the cue ball behind the line." % how)
	else:
		_hint("Aim with the mouse. %s Space also shoots." % how)
	_refresh_hud()


func _begin_place(head_only: bool) -> void:
	touch_armed = false
	state = S.PLACE
	place_head_only = head_only
	view.show_guide = false
	last_place = Vector2(-1, -1)
	_hint("Ball in hand%s: gold lines show the sinks on from here. Click to place." % (" behind the line" if head_only else ""))
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
	_announce_unlocks(meta.on_table_cleared(run))
	if final and not run.endless:
		_announce_unlocks(meta.on_win(run.handicap))
	var rows := run.payout()
	_refresh_hud()
	await get_tree().create_timer(1.6).timeout
	while paused and state == S.CLEAR:
		await get_tree().process_frame
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
				_close_run_info()
			return
		_key(e.keycode)
		return
	if paused:
		return
	if e is InputEventMouseButton:
		_mouse_button(e)


func _key(k: int) -> void:
	if state == S.PICK and k == KEY_ESCAPE:
		_cancel_pick()
		return
	if state == S.HOLD and k == KEY_ESCAPE and hold_action != "":
		_cancel_hold_action()
		return
	if k == KEY_ESCAPE:
		if state != S.TITLE:
			_show_pause()
		return
	var action := settings.action_for(k)
	match state:
		S.AIM:
			match action:
				"aim_left":
					_step_aim(-1.0)
				"aim_right":
					_step_aim(1.0)
				"shoot":
					_shoot(power)
				"power_up":
					_bump_power(1)
				"power_down":
					_bump_power(-1)
				"spin_up":
					spin_w.set_spin(follow + 0.25, side)
				"spin_down":
					spin_w.set_spin(follow - 0.25, side)
				"spin_left":
					spin_w.set_spin(follow, side - 0.25)
				"spin_right":
					spin_w.set_spin(follow, side + 0.25)
				"place":
					if is_break:
						_begin_place(true)
				"fine":
					fine_aim = not fine_aim
					_hint("Fine aim ON: use your aim keys (Shift = finer). Toggle again to release." if fine_aim else "Fine aim off.")
			if k == KEY_ENTER:
				_shoot(power)
		S.ROLL, S.TALLY:
			if action == "shoot" or k == KEY_ENTER:
				fast = true
			elif action == "pause_shot" and state == S.ROLL:
				_hold()
		S.HOLD:
			if action == "pause_shot" or action == "shoot" or k == KEY_ENTER:
				_play_on()
			elif action == "plan":
				_toggle_plan()
			elif action == "power_up":
				_bump_power(1)
			elif action == "power_down":
				_bump_power(-1)
	if state == S.AIM and action == "plan":
		_toggle_plan()


## ---------------------------------------------------------------- gamepad
var joy_axes := {}
var pad_active := false
var nav_active := false


func _joy(axis: int) -> float:
	var v: float = joy_axes.get(axis, 0.0)
	return v if absf(v) > 0.15 else 0.0


func _joy_button(b: int) -> void:
	if b == JOY_BUTTON_START:
		_key(KEY_ESCAPE)
		return
	if b == JOY_BUTTON_Y and (state == S.AIM or state == S.PLACE or state == S.SHOP):
		_show_run_info()
		return
	match state:
		S.AIM:
			match b:
				JOY_BUTTON_A:
					_shoot(power)
				JOY_BUTTON_DPAD_UP:
					spin_w.set_spin(follow + 0.25, side)
				JOY_BUTTON_DPAD_DOWN:
					spin_w.set_spin(follow - 0.25, side)
				JOY_BUTTON_DPAD_LEFT:
					spin_w.set_spin(follow, side - 0.25)
				JOY_BUTTON_DPAD_RIGHT:
					spin_w.set_spin(follow, side + 0.25)
				JOY_BUTTON_X:
					spin_w.set_spin(0.0, 0.0)
				JOY_BUTTON_BACK:
					if is_break:
						_begin_place(true)
		S.PLACE:
			if b == JOY_BUTTON_A:
				_place_cue()
		S.ROLL, S.TALLY:
			if b == JOY_BUTTON_A:
				fast = true


## Left stick steers the cursor when placing the cue ball or choosing a pocket.
func _pad_cursor(delta: float) -> void:
	var stick := Vector2(_joy(JOY_AXIS_LEFT_X), _joy(JOY_AXIS_LEFT_Y))
	if stick != Vector2.ZERO:
		pad_active = true
		mouse_pos += stick * delta * 760.0
		mouse_pos = mouse_pos.clamp(Vector2.ZERO, fit.view)


func _focus_first(n: Node) -> bool:
	for c in n.get_children():
		if c is Button and not (c as Button).disabled and (c as Button).is_visible_in_tree():
			(c as Button).grab_focus()
			return true
		if _focus_first(c):
			return true
	return false


func _mouse_button(e: InputEventMouseButton) -> void:
	if plan_lock and state == S.AIM and e.button_index == MOUSE_BUTTON_LEFT and settings.touch_mode:
		if e.pressed and _mouse_over_table():
			touch_armed = true
		elif not e.pressed and touch_armed:
			touch_armed = false
			_update_plan_hover()
			_set_pause_point()
		return
	if plan_lock and state == S.AIM and e.button_index == MOUSE_BUTTON_LEFT and e.pressed and _mouse_over_table():
		_set_pause_point()
		return
	match state:
		S.AIM:
			if e.button_index == MOUSE_BUTTON_LEFT and settings.touch_mode:
				touch_aiming = e.pressed and _mouse_over_table()
			elif e.button_index == MOUSE_BUTTON_LEFT:
				if e.pressed and _mouse_over_table() and settings.click_shoot:
					_shoot(power)
				elif e.pressed and _mouse_over_table():
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
			elif e.button_index == MOUSE_BUTTON_RIGHT and e.pressed and not armed.is_empty():
				var last: Dictionary = armed[armed.size() - 1]
				_disarm(last)
				_hint("Took back %s." % Catalog.ITEMS[last.id].name)
				sfx.play("click_soft", 0.6, 0.8)
			elif e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
				power = clampf(power + 0.03, 0.02, 1.0)
				forecast_dirty = true
			elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
				power = clampf(power - 0.03, 0.02, 1.0)
				forecast_dirty = true
		S.PLACE:
			if e.button_index == MOUSE_BUTTON_LEFT and settings.touch_mode:
				# Touch has no hover: drag the ghost ball, lift to place it.
				if e.pressed:
					touch_armed = true
				elif touch_armed:
					touch_armed = false
					_update_place()
					_place_cue()
			elif e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
				_place_cue()
		S.HOLD:
			if e.button_index == MOUSE_BUTTON_LEFT and settings.touch_mode:
				# Touch: the preview follows the finger and the action happens on lift.
				# A wall starts where the finger lands and ends where it lifts.
				if e.pressed and _mouse_over_table():
					touch_armed = true
					if hold_action == "wall" and wall_start == Vector2.INF:
						_hold_click()
				elif not e.pressed and touch_armed:
					touch_armed = false
					_update_plan_hover()
					_hold_click()
			elif e.button_index == MOUSE_BUTTON_LEFT and e.pressed and _mouse_over_table():
				_hold_click()
			elif e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
				_cancel_hold_action()
			elif e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
				power = clampf(power + 0.03, 0.02, 1.0)
			elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
				power = clampf(power - 0.03, 0.02, 1.0)
		S.PICK:
			if e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
				_cancel_pick()
			elif e.button_index == MOUSE_BUTTON_LEFT and settings.touch_mode:
				if e.pressed:
					touch_armed = true
				elif touch_armed:
					touch_armed = false
					_update_pick()
					_pick_click()
			elif e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
				_pick_click()
		S.ROLL, S.TALLY:
			if e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
				fast = true


func _on_spin(f: float, s: float) -> void:
	follow = f
	side = s
	guide_dirty = true


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
	if settings.large_text and size <= 15:
		size += 2
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", font if font else F_SEMI)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Rich text with tappable terms. Pass text already run through Glossary.link.
static func _number_font() -> Font:
	var f := FontVariation.new()
	f.base_font = ThemeDB.fallback_font
	f.variation_embolden = 0.35
	return f


func _term_text(bbcode: String, size: int, color: Color, width: float, font: Font = null) -> RichTextLabel:
	if settings.large_text and size <= 15:
		size += 2
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.meta_underlined = false
	r.custom_minimum_size = Vector2(width, 0)
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	r.add_theme_font_override("normal_font", font if font else F_REG)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_color_override("default_color", color)
	r.meta_clicked.connect(func(m): term_tip.show_term(str(m), r.get_global_mouse_position()))
	r.meta_hover_started.connect(func(m): term_tip.show_term(str(m), r.get_global_mouse_position()))
	r.meta_hover_ended.connect(func(_m): term_tip.hide_tip())
	r.text = bbcode
	return r


## Makes a whole control, such as a HUD heading, open a term's popup.
func _make_term(c: Control, term: String) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.mouse_entered.connect(func(): term_tip.show_term(term, c.get_global_mouse_position()))
	c.mouse_exited.connect(func(): term_tip.hide_tip())
	c.gui_input.connect(func(e):
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
			term_tip.show_term.call_deferred(term, c.get_global_mouse_position()))


func _button(text: String, cb: Callable, accent: Color = Color(0.85, 0.65, 0.3)) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", F_SEMI)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_stylebox_override("normal", _style(Color(0.11, 0.1, 0.09), accent.darkened(0.3), 2, 8))
	b.add_theme_stylebox_override("hover", _style(Color(0.2, 0.16, 0.11), accent, 2, 8))
	b.add_theme_stylebox_override("pressed", _style(Color(0.3, 0.22, 0.12), accent.lightened(0.2), 2, 8))
	b.add_theme_stylebox_override("disabled", _style(Color(0.08, 0.08, 0.08), Color(0.25, 0.25, 0.25), 2, 8))
	b.add_theme_stylebox_override("focus", _style(Color(1, 1, 1, 0.06), Color(1.0, 1.0, 1.0, 0.95), 3, 8))
	b.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.45, 0.45))
	b.pressed.connect(func():
		sfx.play("ui", 0.8)
		cb.call())
	b.mouse_entered.connect(func(): sfx.play("ui", 0.25, 1.5))
	return b


var log_title: Label
var touch_box: VBoxContainer
var menu_btn: Button
var info_btn_ref: Button
var power_slider: HSlider
var touch_aiming := false
var touch_rot := 0.0
var touch_armed := false
var touch_hint: Label
var aim_dial: AimDial
var shoot_hold := -1.0       # seconds SHOOT has been held while aiming; -1 when not held
var shoot_fired := false     # the hold fired the shot, so the button's release does nothing
const SHOOT_HOLD := 0.35
var touch_aim_btn: Button
var touch_last := Vector2.INF   # finger position last frame, for Fine aim
const FINE_DRAG := 1.0 / 2400.0  # radians per table unit dragged across the aim line
var power_up_btn: Button
var touch_place: Button
# A finger held still on a ball shows what it does (a long press, since phones cannot hover).
var finger_down := false
var finger_anchor := Vector2.ZERO
var finger_still := 0.0
const LONG_PRESS := 0.45


## On-screen shot controls for phones and tablets.
func _build_touch_controls(parent: Control) -> void:
	touch_box = VBoxContainer.new()
	touch_box.add_theme_constant_override("separation", 6)
	touch_box.visible = false
	parent.add_child(touch_box)
	touch_hint = _label("", 14, Color(0.85, 0.9, 0.85), F_REG)
	touch_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	touch_hint.visible = false
	touch_box.add_child(touch_hint)
	power_slider = HSlider.new()
	power_slider.min_value = 0.02
	power_slider.max_value = 1.0
	power_slider.step = 0.01
	power_slider.custom_minimum_size = Vector2(0, 44)
	power_slider.focus_mode = Control.FOCUS_NONE
	power_slider.value_changed.connect(func(v: float):
		power = v
		forecast_dirty = true)
	aim_dial = AimDial.new()
	aim_dial.font = F_SEMI
	aim_dial.turned.connect(func(deg: float):
		if state == S.AIM and not plan_lock:
			aim_dir = aim_dir.rotated(deg_to_rad(deg))
			guide_dirty = true)
	touch_box.add_child(aim_dial)
	touch_box.add_child(power_slider)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	touch_box.add_child(row)
	for dir in [-1.0, 1.0]:
		var nudge := _button("<" if dir < 0 else ">", func(): pass, Color(0.6, 0.75, 0.9))
		nudge.custom_minimum_size = Vector2(66, 58)
		nudge.focus_mode = Control.FOCUS_NONE
		nudge.button_down.connect(func():
			touch_rot = dir
			_step_aim(dir))
		nudge.button_up.connect(func(): touch_rot = 0.0)
		row.add_child(nudge)
		if dir < 0:
			var shoot := _button("SHOOT", func():
				if shoot_fired:
					shoot_fired = false   # this release ends the hold that already shot
					return
				if state == S.AIM:
					return   # aiming: SHOOT must be held, so a stray tap cannot fire
				if state == S.PICK:
					_cancel_pick()
				elif state == S.HOLD and hold_action != "":
					_cancel_hold_action()
				elif state == S.AIM:
					_shoot(power)
				elif state == S.ROLL:
					_hold()
				elif state == S.HOLD:
					_play_on(), Color(0.4, 0.9, 0.6))
			shoot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			shoot.custom_minimum_size = Vector2(0, 58)
			shoot.focus_mode = Control.FOCUS_NONE
			shoot.add_theme_font_size_override("font_size", 24)
			row.add_child(shoot)
			touch_shoot = shoot
			shoot.button_down.connect(func():
				if state == S.AIM:
					shoot_hold = 0.0)
			shoot.button_up.connect(func():
				if state == S.AIM and shoot_hold >= 0.0 and not shoot_fired:
					_hint("Hold SHOOT to fire.")
				shoot_hold = -1.0)
	var plan := _button("PLAN A PAUSE", func():
		if state == S.AIM or state == S.HOLD:
			_toggle_plan(), Color(0.55, 0.95, 0.85))
	plan.custom_minimum_size = Vector2(0, 46)
	plan.focus_mode = Control.FOCUS_NONE
	touch_box.add_child(plan)
	touch_aim_btn = _button("", func():
		settings.fine_drag = not settings.fine_drag
		touch_last = Vector2.INF
		_sync_aim_btn()
		_save_settings()
		_hint("Fine aim: drag anywhere on the table to turn the shot a little." if settings.fine_drag else "Point aim: drag on the table and the shot points at your finger."), Color(0.6, 0.75, 0.9))
	touch_aim_btn.custom_minimum_size = Vector2(0, 46)
	touch_aim_btn.focus_mode = Control.FOCUS_NONE
	touch_box.add_child(touch_aim_btn)
	_sync_aim_btn()
	touch_place = _button("MOVE CUE BALL", func():
		if state == S.AIM and is_break:
			_begin_place(true), Color(0.9, 0.85, 0.5))
	touch_place.custom_minimum_size = Vector2(0, 46)
	touch_place.focus_mode = Control.FOCUS_NONE
	touch_place.visible = false
	touch_box.add_child(touch_place)


## Shows a hint. On touch screens it also appears above the shot controls, worded for a finger.
func _hint(t: String) -> void:
	lbl_hint.text = t
	if touch_hint:
		touch_hint.text = _touch_words(t)
		touch_hint.visible = settings.touch_mode and t != ""


## The words for whichever input this player uses.
func _words(t: String) -> String:
	return _touch_words(t) if settings.touch_mode else t


## Rewrites mouse and keyboard wording for touch screens.
static func _touch_words(t: String) -> String:
	var swaps := [
		[" Right-click or Esc to cancel.", " Tap CANCEL to back out."],
		["use an item, plan a pause (L), or press P to play on", "use an item, PLAN a pause, or tap PLAY ON"],
		["Click or press Space to fast-forward. P pauses.", "Tap the table to fast-forward, or PAUSE to stop the shot."],
		["P (or the Pause button) pauses the shot. Click or Space to fast-forward.", "PAUSE stops the shot. Tap the table to fast-forward."],
		["Click the table or press P to play on.", "Tap PLAY ON to carry on."],
		["Move along the cue ball's line and click to set a pause point. L unlocks.", "Slide along any ball's line and lift to set a pause point. PLAN unlocks."],
		[" L unlocks the prediction.", " PLAN unlocks the prediction."],
		[" H: move the cue ball behind the line.", " MOVE CUE BALL places it behind the line."],
		["Aim with the mouse.", "Drag on the table to aim."],
		[" Space also shoots.", ""],
		["Click to place.", "Drag, then lift to place."],
		["Click to skip the count.", "Tap to skip the count."],
		["aim with the mouse, set power with the wheel, click to hit", "drag to aim, set power with the slider, lift to hit"],
		["click where it starts, then where it ends", "drag from where it starts to where it ends"],
		["click where the cue ball reappears", "drag to where the cue ball reappears, then lift"],
		["Fine aim ON: use your aim keys (Shift = finer). Toggle again to release.", "Fine aim ON: use the < > buttons."],
	]
	for p in swaps:
		t = t.replace(p[0], p[1])
	return t.replace("Click", "Tap").replace("click", "tap")


func _sync_aim_btn() -> void:
	if touch_aim_btn:
		touch_aim_btn.text = "AIM: FINE (drag to turn)" if settings.fine_drag else "AIM: POINT (tap for fine)"


func _sync_touch_ui() -> void:
	var t := settings.touch_mode
	touch_box.visible = t
	log_title.visible = not t
	log_label.visible = not t
	lbl_hint.visible = not t
	menu_btn.visible = t
	info_btn_ref.text = "Run info" if t else "Run info [Tab]"
	_sync_aim_btn()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if paused:
			_close_run_info()
		else:
			_key(KEY_ESCAPE)


func _build_ui() -> void:
	term_tip = TermTip.new()
	add_child(term_tip)
	term_tip.setup(_style(Color(0.07, 0.09, 0.13, 0.97), Color(0.56, 0.85, 1.0), 2, 8), F_SEMI, F_REG)
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
	lv.add_theme_constant_override("separation", 5)
	left.add_child(lv)
	var round_row := HBoxContainer.new()
	lv.add_child(round_row)
	lbl_round = _label("Table 1 / 9", 16, Color(0.7, 0.75, 0.8))
	lbl_round.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	round_row.add_child(lbl_round)
	var info_btn := _button("Run info [Tab]", _show_run_info, Color(0.5, 0.7, 0.9))
	info_btn.add_theme_font_size_override("font_size", 12)
	info_btn.custom_minimum_size = Vector2(0, 26)
	info_btn.focus_mode = Control.FOCUS_NONE
	round_row.add_child(info_btn)
	info_btn_ref = info_btn
	menu_btn = _button("Menu", func(): _key(KEY_ESCAPE), Color(0.6, 0.75, 0.9))
	menu_btn.add_theme_font_size_override("font_size", 12)
	menu_btn.custom_minimum_size = Vector2(0, 26)
	menu_btn.focus_mode = Control.FOCUS_NONE
	menu_btn.visible = false
	round_row.add_child(menu_btn)

	var labbox := PanelContainer.new()
	labbox.add_theme_stylebox_override("panel", _style(Color(0.12, 0.13, 0.15), Color(0.25, 0.3, 0.35), 1, 8))
	lv.add_child(labbox)
	var labv := VBoxContainer.new()
	labbox.add_child(labv)
	lbl_lab = _label("Standard Felt", 20, Color(0.6, 1.0, 0.85))
	labv.add_child(lbl_lab)
	lbl_rule = _term_text("", 13, Color(0.75, 0.78, 0.8), 290.0)
	labv.add_child(lbl_rule)
	lbl_bounty = _term_text("", 13, Color(1.0, 0.85, 0.35), 290.0)
	labv.add_child(lbl_bounty)
	bet_row = HBoxContainer.new()
	bet_row.add_theme_constant_override("separation", 6)
	labv.add_child(bet_row)
	lbl_boss = _label("", 13, Color(1.0, 0.45, 0.4), F_REG)
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
	lbl_target = _label("150", 22, Color(1.0, 0.85, 0.45), F_NUM)
	th.add_child(lbl_target)
	lbl_score = _label("0", 38, Color.WHITE, F_NUM)
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

	lbl_chain = _meter(lv, "CHAIN", Color(0.2, 0.75, 0.6))
	lbl_heat = _meter(lv, "HEAT", Color(1.0, 0.5, 0.15))
	lbl_line = _label("Sink balls, stack Heat, avoid the 8.", 14, Color(0.85, 0.85, 0.85))
	lbl_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_line.custom_minimum_size = Vector2(290, 32)
	lv.add_child(lbl_line)

	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 10)
	lv.add_child(stats)
	var chalk_title := _label("CHALK", 13, Color(0.6, 0.7, 0.85))
	_make_term(chalk_title, "chalk")
	stats.add_child(chalk_title)
	chalk_pips = ChalkPips.new()
	stats.add_child(chalk_pips)
	stats.add_child(_label("MONEY", 13, Color(0.6, 0.7, 0.85)))
	lbl_money = _label("$4", 22, Color(1.0, 0.85, 0.3), F_NUM)
	stats.add_child(lbl_money)
	var gear_title := _label("ITEMS", 13, Color(0.6, 0.7, 0.85))
	stats.add_child(gear_title)
	item_bar = HFlowContainer.new()   # wraps onto a second row when the kit is full
	item_bar.add_theme_constant_override("h_separation", 5)
	item_bar.add_theme_constant_override("v_separation", 5)
	item_bar.custom_minimum_size = Vector2(220, 0)
	stats.add_child(item_bar)
	flags_label = _label("", 13, Color(0.5, 0.8, 1.0))
	flags_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flags_label.custom_minimum_size = Vector2(290, 0)
	lv.add_child(flags_label)
	tray = BallTray.new()
	tray.font = F_NUM
	lv.add_child(tray)
	log_title = _label("RECENT SHOTS", 12, Color(0.5, 0.5, 0.55))
	lv.add_child(log_title)
	log_label = _label("", 13, Color(0.8, 0.82, 0.85), F_REG)
	log_label.custom_minimum_size = Vector2(290, 52)
	lv.add_child(log_label)
	_build_touch_controls(lv)

	var ctrl := HBoxContainer.new()
	ctrl.alignment = BoxContainer.ALIGNMENT_CENTER
	ctrl.add_theme_constant_override("separation", 14)
	lv.add_child(ctrl)
	spin_w = SpinWidget.new()
	spin_w.font = F_SEMI
	spin_w.custom_minimum_size = Vector2(96, 96)
	spin_w.changed.connect(_on_spin)
	ctrl.add_child(spin_w)
	power_w = PowerMeter.new()
	power_w.font = F_SEMI
	power_w.custom_minimum_size = Vector2(40, 96)
	ctrl.add_child(power_w)
	var pbox := VBoxContainer.new()
	pbox.add_theme_constant_override("separation", 6)
	pbox.alignment = BoxContainer.ALIGNMENT_CENTER
	ctrl.add_child(pbox)
	for d in [1, -1]:
		var pb := _button("▲" if d > 0 else "▼", func():
			if state == S.AIM or state == S.HOLD:
				_bump_power(d), Color(0.5, 0.85, 0.55))
		pb.custom_minimum_size = Vector2(44, 44)
		pb.focus_mode = Control.FOCUS_NONE
		pb.tooltip_text = "Power %s 5%% (%s arrow)" % ["up" if d > 0 else "down", "Up" if d > 0 else "Down"]
		pbox.add_child(pb)
		if d > 0:
			power_up_btn = pb

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(filler)
	lbl_hint = _label("", 13, Color(0.7, 0.72, 0.75), F_REG)
	lbl_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_hint.custom_minimum_size = Vector2(290, 34)
	lv.add_child(lbl_hint)

	# ---------------- bottom bar: perks
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
	fv.add_child(_label("PERKS  (always active)", 12, Color(0.6, 0.6, 0.6)))
	perk_row = BoxContainer.new()
	perk_row.add_theme_constant_override("separation", 8)
	fv.add_child(perk_row)
	# ---------------- banner + overlay
	banner = _label("", 34, Color.WHITE, F_PIXB)
	var bsb := _style(Color(0.02, 0.02, 0.03, 0.72), Color(1, 1, 1, 0.12), 1, 12)
	bsb.content_margin_top = 10
	bsb.content_margin_bottom = 10
	banner.add_theme_stylebox_override("normal", bsb)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.position = Vector2(545, 636)   # over the bottom rail, clear of the balls
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


## A named readout on the side panel: label on the left, value on the right.
func _meter(parent: Control, title: String, accent: Color) -> Label:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _style(accent.darkened(0.78), accent.darkened(0.25), 1, 8))
	parent.add_child(box)
	var row := HBoxContainer.new()
	box.add_child(row)
	if title == "HEAT":
		heat_fire = FireFx.new()   # flames behind the numbers, growing with Heat
		box.add_child(heat_fire)
	var t := _label(title, 14, accent.lightened(0.25))
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(t)
	if title == "HEAT":
		heat_title = t
		heat_fire.modulate.a = 0.55   # the numbers stay readable over the flames
		t.add_theme_constant_override("outline_size", 5)
		t.add_theme_color_override("font_outline_color", Color(0.12, 0.04, 0.0))
	_make_term(box, title.to_lower())
	var v := _label("1", 24, Color.WHITE, F_NUM)
	if title == "HEAT":
		v.add_theme_constant_override("outline_size", 6)
		v.add_theme_color_override("font_outline_color", Color(0.12, 0.04, 0.0))
	row.add_child(v)
	return v


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


func _set_meters(chain: float, heat: int) -> void:
	lbl_chain.text = _fmt(chain)
	lbl_heat.text = "%d  (×%s)" % [heat, _fmt(Scorer.heat_mult(heat))]
	var lvl := FireFx.level_for(heat)
	if heat_fire:
		heat_fire.level = lvl
		heat_title.text = "HEAT" if lvl == 0 else "HEAT · " + FireFx.NAMES[lvl].to_upper()
	view.heat_level = lvl


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
		lbl_round.text = "%sTable %d / %d%s" % ["Daily · " if run.daily_key != "" else ("Handicap %d · " % run.handicap if run.handicap > 0 else ""), run.table_index + 1, total, ""]
	lbl_lab.text = Catalog.BOSSES[t.id].name
	lbl_rule.text = Glossary.link(Catalog.BOSSES[t.id].desc)
	lbl_rule.visible = true
	lbl_boss.visible = false
	lbl_target.text = str(run.target())
	if run.bounty != "":
		_refresh_bet()
	chalk_pips.set_count(run.chalk, run.max_chalk())
	if state != S.ROLL and state != S.TALLY:
		_set_meters(1.0, run.heat)
	lbl_money.text = "$%d" % run.money
	_refresh_items()
	var flags: Array[String] = []
	if run.current().id == "elements" and not run.element_mix.is_empty():
		flags.append("Mix: " + " + ".join(run.element_mix.map(func(el): return Catalog.ELEMENTS[el].name)))
	if run.perks.has("catalyst"):
		flags.append("Snowball: balls worth +%s" % _fmt(run.catalyst))
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
	tray.set_state(rack, down, run.imbues)


func _rebuild_cards() -> void:
	for c in perk_row.get_children():
		perk_row.remove_child(c)   # at once, so the old cards stop holding the row open
		c.queue_free()
	for i in RunState.MAX_PERKS:
		if i < run.perks.size():
			perk_row.add_child(_perk_card(run.perks[i], i))
		else:
			var empty := PanelContainer.new()
			empty.custom_minimum_size = fit.card
			empty.add_theme_stylebox_override("panel", _style(Color(0, 0, 0, 0.2), Color(1, 1, 1, 0.08), 1, 10))
			perk_row.add_child(empty)


func _card_shell(accent: Color, w: float, h: float) -> Array:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(w, h)
	p.add_theme_stylebox_override("panel", _style(Color(0.13, 0.12, 0.13), accent, 2, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(v)
	return [p, v]


func _perk_card(id: String, slot: int) -> Control:
	var f: Dictionary = Catalog.PERKS[id]
	var accent := Catalog.rarity_color(f.r)
	var card: Vector2 = fit.card
	var sh := _card_shell(accent, card.x, card.y)
	var p: PanelContainer = sh[0]
	var v: VBoxContainer = sh[1]
	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(hb)
	hb.add_child(IconArt.new().setup(id, F_SEMI, 34))
	var name_l := _label(f.name, 14, Color.WHITE)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.custom_minimum_size = Vector2(card.x - 66.0, 0)
	hb.add_child(name_l)
	var d := _term_text(Glossary.link(f.desc), 13 if settings.touch_mode else 11, Color(0.78, 0.8, 0.82), card.x - 24.0)
	if state != S.SHOP:
		v.add_child(d)
	else:
		v.add_child(_label(Catalog.rarity_name(f.r), 11, accent))
	var now := _perk_now(id)
	if now != "":
		v.add_child(_label("Now: " + now, 12, TermTip.NEON))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	if state == S.SHOP:
		var b := _button(("Really sell? $%d" if sell_armed == id else "Sell $%d") % run.sell_value(id), func(): _sell_click(id), Color(1.0, 0.75, 0.3) if sell_armed == id else Color(0.9, 0.4, 0.3))
		b.add_theme_font_size_override("font_size", 13)
		v.add_child(b)
	return p


## What a Perk whose effect grows, or switches on and off, is doing right now ("" if fixed).
func _perk_now(id: String) -> String:
	var c: Dictionary = _shot_ctx() if sim != null else {"heat": run.heat, "chalk": run.chalk, "shots_taken": run.shots_taken, "money": run.money,
		"pockets_used": run.pockets_used, "removed": run.removed_count(), "specials": run.ball_kinds.size(), "solid_run": run.solid_run, "stripe_run": run.stripe_run, "total_pots": run.total_pots}
	var heat := int(c.get("heat", 0))
	match id:
		"catalyst":
			return "+%s to every ball" % _fmt(run.catalyst)
		"steadyrun":
			return "+%d to solids" % (12 * mini(int(c.get("solid_run", 0)), 8))
		"tiger":
			return "+%s Chain on the next stripe" % _fmt(0.25 * mini(int(c.get("stripe_run", 0)), 8))
		"thinrack":
			return "+%d to every ball" % (12 * int(c.get("removed", 0)))
		"missing":
			return "+%s Chain a shot" % _fmt(minf(3.0, 0.5 * int(c.get("removed", 0))))
		"menagerie":
			return "+%s Chain a shot" % _fmt(0.25 * int(c.get("specials", 0)))
		"venture":
			return "+%s Chain a shot" % _fmt(minf(1.5, 0.25 * int(int(c.get("money", 0)) / 5)))
		"collector":
			return "+%s Chain a shot" % _fmt(0.5 * (c.get("pockets_used", []) as Array).size())
		"eightcount":
			var left := 8 - int(c.get("total_pots", 0)) % 8
			return "the next sink is the 8th" if left == 1 else "×3 in %d sinks" % left
		"rhythm":
			var k := int(c.get("shots_taken", 0)) % 3
			return "this shot pays ×2" if k == 2 else "×2 in %d shots" % (2 - k)
		"hothand":
			return "ON, +30 to every ball" if heat >= 3 else "off until Heat 3"
		"minimalist":
			return "ON, every sink ×2" if heat >= 5 else "off until Heat 5"
		"migration":
			return "ON, a miss costs 1 Heat" if heat >= 5 else "off until Heat 5"
		"coupon":
			return "ON, every sink ×2" if heat == 0 else "off until Heat drops to 0"
		"entropy":
			return "ON, +1 Chain" if heat < 3 else "off at Heat 3+"
		"comeback":
			return "ON, every sink ×2" if int(c.get("chalk", 9)) == 1 else "off until your last Chalk"
		"insurance":
			return "%d free miss%s left" % [maxi(0, 2 - run.insured_used), "" if 2 - run.insured_used == 1 else "es"]
		"overflow":
			return "+%d carried in" % run.carry if run.carry > 0 else ""
	return ""


var sell_armed := ""
var shop_anim := false


## Selling takes two clicks, so a stray click cannot throw away a build.
func _sell_click(id: String) -> void:
	if sell_armed != id:
		sell_armed = id
		_refresh_hud()
		return
	sell_armed = ""
	run.sell_perk(run.perks.find(id))
	sfx.play("coin", 0.7, 0.8)
	_refresh_shop()
	_refresh_hud()


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
	p.position = at if at.x >= 0 else Vector2((fit.view.x - w) * 0.5, (900 - h) * 0.5)
	if at.x < 0:
		p.resized.connect(func(): p.position = Vector2((fit.view.x - p.size.x) * 0.5, maxf(10.0, (900.0 - p.size.y) * 0.5)))
	overlay.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	if nav_active:
		(func(): _focus_first(overlay)).call_deferred()
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
	var logo := LogoArt.new()
	logo.font = F_PIXB
	logo.custom_minimum_size = Vector2(0, 150)
	v.add_child(logo)
	var s := _label("A pool roguelite. Sink balls, stack multipliers, beat the target.", 17, Color(0.8, 0.85, 0.9), F_REG)
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
	var key := Records.today_key()
	var day_best := records.daily_best(key)
	var day_txt := "Daily Challenge" if day_best.is_empty() else "Daily Challenge  (best today: %d tables, %d)" % [int(day_best.tables), int(day_best.score)]
	v.add_child(_button(day_txt, _start_daily, Color(0.5, 0.8, 1.0)))
	_menu_row(v, "How to Play", _show_help, "Settings", func(): _show_settings(_show_title))
	_menu_row(v, "Collection", func(): screens.show_collection(), "Records", func(): screens.show_records())
	_menu_row(v, "Credits", _show_credits, "Quit", func(): get_tree().quit())
	var prog := _label("Unlocks: " + meta.progress() + "  ·  %d / %d Perks" % [Catalog.PERKS.size() - meta.locked_perks().size(), Catalog.PERKS.size()], 14, Color(0.6, 0.85, 1.0), F_REG)
	prog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(prog)
	var best := _load_best()
	if best.tables > 0 or best.shot > 0:
		var bl := _label("Best run: %d tables cleared  ·  best shot %d  ·  best Heat %d" % [best.tables, best.shot, best.heat], 15, Color(1.0, 0.85, 0.45), F_REG)
		bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(bl)
	var foot := _label("Real pool physics · exact guideline · %d Perks · 9 boss tables + endless" % Catalog.PERKS.size(), 13, Color(0.55, 0.55, 0.6), F_REG)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(foot)


var chosen_cue := "maple"


func _show_cue_select() -> void:
	_clear_overlay()
	_dim(0.6)
	var v := _center_panel(1100, 480)
	v.add_child(_label("CHOOSE YOUR CUE", 30, Color(0.98, 0.8, 0.4), F_PIXB))
	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 10)
	v.add_child(seed_row)
	seed_row.add_child(_label("Seed (optional):", 15, Color(0.8, 0.82, 0.85), F_REG))
	seed_input = LineEdit.new()
	seed_input.placeholder_text = "leave blank for a random run"
	seed_input.custom_minimum_size = Vector2(300, 34)
	seed_input.name = "seed_input"
	seed_row.add_child(seed_input)
	if meta.handicap_cap() > 0:
		chosen_handicap = mini(chosen_handicap, meta.handicap_cap())
		var st: Dictionary = Catalog.HANDICAPS[chosen_handicap]
		var down := _button("<", func():
			chosen_handicap = maxi(0, chosen_handicap - 1)
			_show_cue_select())
		var up := _button(">", func():
			chosen_handicap = mini(meta.handicap_cap(), chosen_handicap + 1)
			_show_cue_select())
		down.disabled = chosen_handicap == 0
		up.disabled = chosen_handicap >= meta.handicap_cap()
		seed_row.add_child(down)
		seed_row.add_child(_label("Handicap %d: %s - %s" % [chosen_handicap, st.name, st.desc], 15, Color(1.0, 0.7, 0.45), F_SEMI))
		seed_row.add_child(up)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	for id in Catalog.CUES:
		var c: Dictionary = Catalog.CUES[id]
		var sh := _card_shell(c.accent, 150, 200)
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
		var n := _label(c.name, 16, Color.WHITE)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		n.custom_minimum_size = Vector2(126, 0)
		cv.add_child(n)
		var d := _label(c.desc, 12, Color(0.8, 0.82, 0.85), F_REG)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(126, 0)
		d.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cv.add_child(d)
		var pick := _button("Choose", func():
			chosen_cue = id
			pending_seed = _parse_seed(seed_input.text)
			_new_run(), c.accent)
		if not meta.cue_unlocked(id):
			pick.text = "Locked"
			pick.disabled = true
			p.modulate = Color(1, 1, 1, 0.55)
			var lk := _label("Locked: " + meta.cue_hint(id), 13, Color(1.0, 0.8, 0.45), F_SEMI)
			lk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lk.custom_minimum_size = Vector2(126, 0)
			cv.add_child(lk)
		cv.add_child(pick)
		if row.get_child_count() == 8:
			row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			v.add_child(row)
		row.add_child(p)
	v.add_child(_button("Back", _show_title))


var meta := Meta.new()
var records := Records.new()
var screens: MetaScreens
var pending_seed := -1
var pending_daily := ""
var seed_input: LineEdit


## Celebrates newly earned milestones: banner, sound and a line in the shot log.
func _announce_unlocks(ids: Array) -> void:
	if ids.is_empty():
		return
	var names: Array = ids.map(func(m): return Meta.MILESTONES[m].name)
	_flash_banner("UNLOCKED: " + ", ".join(names).to_upper(), Color(0.5, 0.9, 1.0), 2.2)
	sfx.play("clear", 0.7, 1.2)
	for m in ids:
		shot_log.push_front("New: " + Meta.reward_text(m))
	if shot_log.size() > 3:
		shot_log.resize(3)
	log_label.text = "
".join(shot_log)


func _menu_row(v: Control, a: String, fa: Callable, b: String, fb: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	for pair in [[a, fa], [b, fb]]:
		var btn := _button(pair[0], pair[1])
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(btn)


func _start_daily() -> void:
	pending_daily = Records.today_key()
	_new_run()


## Blank = random. Numbers are used as they are; words hash to a stable seed.
func _parse_seed(text: String) -> int:
	var t := text.strip_edges()
	if t == "":
		return -1
	if t.is_valid_int():
		return absi(t.to_int())
	return absi(t.hash())


func _new_run() -> void:
	demo = false
	_hud_visible(true)
	_clear_overlay()
	if pending_daily != "":
		chosen_cue = Records.daily_cue(pending_daily)
		pending_seed = Records.daily_seed(pending_daily)
	elif not meta.cue_unlocked(chosen_cue):
		chosen_cue = "maple"
	var handicap_now := 0 if pending_daily != "" else mini(chosen_handicap, meta.handicap_cap())
	run.start(pending_seed if pending_seed >= 0 else randi(), chosen_cue, handicap_now)
	run.daily_key = pending_daily
	# Dailies give everyone the full pool, so results are comparable.
	run.locked = [] if pending_daily != "" else meta.locked_perks()
	run.intro = pending_daily == "" and meta.is_intro()
	pending_seed = -1
	pending_daily = ""
	view.cue_colors = Catalog.CUES.get(chosen_cue, Catalog.CUES.maple)
	run.begin_table()
	_setup_table()
	_save_progress()
	spin_w.set_spin(0, 0)
	_animate_score(0, 0)
	shown_score = 0
	_set_meters(1.0, run.heat)
	lbl_line.text = "Sink balls, stack Heat, avoid the 8."
	coaching = _load_best().tables == 0
	coach_seen_pot = false
	_enter_aim()
	_flash_banner("%s  ·  TARGET %d" % [Catalog.BOSSES[run.current().id].name.to_upper(), run.target()], Color(1, 0.85, 0.4), 1.6)


func _show_help() -> void:
	_clear_overlay()
	_dim(0.8)
	var v := _center_panel(900, 700)
	v.add_child(_label("HOW TO PLAY", 30, Color(0.98, 0.8, 0.4), F_PIXB))
	var txt := """[b]Shoot:[/b] Aim with the mouse. Press on the table and drag BACK from the cue ball to set power, then release. (Or use the wheel/Up/Down for power and Space to shoot.) Left/Right fine-tune your aim, and Shift makes it finer.
[b]Guideline:[/b] The white line shows the cue ball's path, and the ring is where it will touch the object ball. After contact the line takes the colour of the ball you hit. A bold line ending in a [color=#ffd060]gold ring[/color] means that ball is going in, and the tag on the pocket shows what the sink is worth. Settings has a Prediction lines option that shows where every ball will land. The blue dashes show where the cue ball goes after contact, including spin.
[b]Spin:[/b] Click the big cue ball (W/S/A/D). Hitting it high gives follow and low gives draw; the sides add english off the cushions.

[b]Score:[/b] Each ball pays as it sinks: its [color=#ffd060]value[/color] (10 + twice its number) × [color=#60d0a0]Chain[/color] × [color=#ff9040]Heat[/color]. Bouncing off cushions and other balls earns nothing by itself.
[color=#60d0a0]Chain[/color] starts at 1 each shot and rises by 0.5 for every ball you sink in that shot, so the last ball of a big shot pays the most.
[color=#ff9040]Heat[/color] lasts all table. Every scoring shot adds 1, and each point of Heat adds ×0.5. A miss cuts your Heat in half.
The [color=#ff8a30]hot pocket[/color] pays ×2. The black 8 also pays ×2.

[b]The 8-ball:[/b] Avoid it. If the 8 sinks while other balls are still on the table, you lose 15% of the table's target, unless a Perk changes that. Once it is the only ball left on the table it is safe, and sinking it brings a fresh rack.

[b]Pausing a shot:[/b] While the balls roll, press [b]P[/b] (or tap [b]Pause[/b] on a phone) and everything freezes. The prediction then shows exactly where every ball goes from that moment. While paused you can use mid-shot items from your bar: [b]Second Strike[/b] (aim with the mouse, set power with the wheel or Up/Down, click to hit), [b]Pop-up Wall[/b] (click where it starts, then where it ends), [b]Blink[/b] (click where the cue ball reappears), and more. Right-click or Esc cancels an item. Press [b]P[/b] again, Space, Enter or click the table to play on.
[b]Planning a pause:[/b] Press [b]L[/b] (or [b]Plan a pause[/b]) to lock the prediction, move along the cue ball's line and click where the shot should stop by itself. Settings can also pause every shot the moment the cue ball first hits a ball.

[b]Chalk:[/b] As in real pool, you keep shooting while you sink. A miss, a scratch or no contact costs 1 chalk. A dry break is free. Run out of chalk before reaching the target and the run is over. Clearing the whole rack gives +1 chalk and a fresh rack.

[b]Between tables:[/b] Spend money in the Pro Shop on Perks (six slots, always active) and Imbues (upgrade one ball for the rest of the run; you choose which, and each ball holds one). Clearing a table pays $4, plus $1 for every 10% you score over the target (up to $10) and $1 for every shot under 10 you needed (up to $5).

Every table is its own boss with its own rule, and some reward bounces or bumpers. Clear all 9 tables to win, then keep going in endless mode."""
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
	if state == S.SHOP:
		_refresh_shop()


func _show_pause() -> void:
	if state == S.OVER:
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
	sell_armed = ""
	run.roll_shop()
	shop_anim = true
	_refresh_shop()
	shop_anim = false
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
	var zone: Rect2 = fit.table_zone
	d.position = zone.position
	d.size = zone.size
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := _center_panel(1040, 600, Color(0.85, 0.65, 0.3), Vector2(450, 8) + fit.table_offset)
	var head := HBoxContainer.new()
	v.add_child(head)
	head.add_child(_label("PRO SHOP", 30, Color(0.98, 0.8, 0.4), F_PIXB))
	var spc := Control.new()
	spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spc)
	head.add_child(_label("$%d" % run.money, 30, Color(1.0, 0.85, 0.3), F_NUM))
	if not payout_rows.is_empty():
		var parts: Array[String] = []
		for r in payout_rows:
			parts.append("%s +$%d" % [r[0], r[1]])
		v.add_child(_label("Payout:  " + "   ·   ".join(parts), 15, Color(0.8, 0.85, 0.7), F_REG))
	var nxt := run.table_index + 1
	var np: Dictionary = run.plan[mini(nxt, run.plan.size() - 1)] if nxt < run.plan.size() else {}
	if not np.is_empty():
		var s := "Next: Table %d - %s - target %d" % [nxt + 1, Catalog.BOSSES[np.id].name, np.target]
		s += "\n" + Catalog.BOSSES[np.id].desc
		var next_l := _label(s, 15, Color(1.0, 0.7, 0.5), F_REG)
		next_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(next_l)
	var row := GridContainer.new()
	row.columns = 5
	row.add_theme_constant_override("h_separation", 12)
	row.add_theme_constant_override("v_separation", 10)
	v.add_child(row)
	for i in run.shop.size():
		row.add_child(_offer_card(i))
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	v.add_child(bar)
	var rr := _button("Reroll perks ($%d)" % run.reroll_cost, func():
		if run.reroll():
			sfx.play("coin", 0.6, 0.9)
			shop_anim = true
			_refresh_shop()
			shop_anim = false
			_refresh_hud()
		else:
			sfx.play("bad", 0.4))
	rr.disabled = run.money < run.reroll_cost
	bar.add_child(rr)
	var rm := _button("Remove a ball ($%d)" % run.removal_cost(), _show_remove_picker, Color(1.0, 0.55, 0.55))
	rm.disabled = run.money < run.removal_cost() or run.ball_set.size() <= 2
	rm.visible = not (run.intro and run.table_index < 2)
	bar.add_child(rm)
	_shop_intro_tip(v)
	var spc2 := Control.new()
	spc2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spc2)
	var go := _button("Next table  >", _next_table, Color(0.4, 0.9, 0.6))
	go.custom_minimum_size = Vector2(220, 50)
	go.add_theme_font_size_override("font_size", 22)
	bar.add_child(go)
	var tip := "Tip: you can sell a Perk from the bar below for half its price."
	if _load_best().tables == 0:
		tip = "New here? Perks stay with you for the whole run. Cards glowing green work with Perks you own. Hover a greyed price if you can't afford it yet."
	v.add_child(_label(tip, 13, Color(0.55, 0.55, 0.6), F_REG))


func _offer_card(i: int) -> Control:
	var item: Dictionary = run.shop[i]
	var accent := Color(0.6, 0.6, 0.6)
	var title := ""
	var desc := ""
	var kind := ""
	var syn: Array = []
	match item.type:
		"perk":
			var f: Dictionary = Catalog.PERKS[item.id]
			accent = Catalog.rarity_color(f.r)
			title = f.name
			desc = f.desc
			kind = "%s · %s" % [Catalog.rarity_name(f.r), Catalog.family_name(item.id)]
			syn = Catalog.synergies(item.id, run.perks).map(func(o): return Catalog.PERKS[o].name)
		"imbue":
			var iso: Dictionary = Catalog.IMBUES[item.id]
			accent = iso.color
			if item.has("ball"):
				title = "%s %d-ball" % [iso.name, item.ball]
				desc = iso.desc + " Already on this ball, for the whole run."
				kind = "Imbued ball"
			else:
				title = "%s Imbue" % iso.name
				desc = iso.desc + " You choose the ball. Each ball holds one Imbue."
				kind = "Imbue · choose a ball"
		"ball":
			var bt: Dictionary = Catalog.BALL_TYPES[item.id]
			accent = bt.color if (bt.color as Color).get_luminance() > 0.3 else bt.accent
			title = "%s ball" % bt.name
			desc = bt.desc + " Joins your set for the rest of the run."
			kind = "New ball · set %d / %d" % [run.ball_set.size(), Rack.MAX_BALLS]
		"item":
			var itd: Dictionary = Catalog.ITEMS[item.id]
			accent = Color(0.45, 0.85, 1.0)
			title = itd.name
			desc = itd.desc
			kind = "%s · %s" % ["Tool, one charge per table" if itd.kind == "tool" else "Consumable", Catalog.WHEN_NAMES[itd.when]]
			accent = Catalog.WHEN_COLORS[itd.when]
	var sh := _card_shell(accent, 196, 214)
	var p: PanelContainer = sh[0]
	var v: VBoxContainer = sh[1]
	if TileArt.has_tile(item.type, item.id):
		# Card art: a periodic-table tile carries the symbol, name, headline effect and kind.
		var tile := TileArt.new().setup(item.type, item.id, int(item.get("ball", 0)))
		tile.tooltip_text = "%s\n%s" % [title, kind]
		v.add_child(tile)
		if item.type == "imbue" and not item.has("ball"):
			var pick := _label("You choose the ball", 12, accent)
			v.add_child(pick)
	else:
		if item.type == "imbue":
			v.add_child(_ball_icon(int(item.get("ball", 0)), iso_color(item.id)))
		else:
			var ic := CenterContainer.new()
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ic.add_child(IconArt.new().setup(("ball_" + item.id) if item.type == "ball" else item.id, F_SEMI, 40))
			v.add_child(ic)
		var t := _label(title, 18, Color.WHITE)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(172, 0)
		v.add_child(t)
		var kind_l := _label(kind, 12, accent)
		kind_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		kind_l.custom_minimum_size = Vector2(172, 0)
		v.add_child(kind_l)
	if not syn.is_empty():
		var sl := _label("+ Synergy: " + ", ".join(syn), 12, Color(0.5, 1.0, 0.6))
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sl.custom_minimum_size = Vector2(172, 0)
		v.add_child(sl)
		p.add_theme_stylebox_override("panel", _style(Color(0.1, 0.16, 0.11), Color(0.5, 1.0, 0.6), 3, 10))
	var d := _term_text(Glossary.link(desc), 13, Color(0.8, 0.82, 0.85), 172.0)
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(d)
	var b := _button("SOLD" if item.sold else "Buy $%d" % item.cost, func():
		if item.type == "imbue" and not item.has("ball"):
			_show_imbue_picker(i)
			return
		var err := run.buy(i)
		if err == "":
			sfx.play("coin", 0.9)
			if item.type == "imbue":
				view.refresh_glows(sim, run.imbues)
			_refresh_shop()
			_refresh_hud()
		else:
			sfx.play("bad", 0.4)
			_flash_banner(err.to_upper(), Color(1, 0.5, 0.4), 1.0))
	b.disabled = item.sold or run.money < item.cost
	v.add_child(b)
	if item.sold:
		p.modulate = Color(1, 1, 1, 0.45)
	elif shop_anim and not settings.reduced_motion:
		# Cards deal in one after another.
		p.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_interval(i * 0.07)
		tw.tween_property(p, "modulate:a", 1.0, 0.18)
		sfx.play("ui", 0.3, 1.0 + i * 0.12)
	return p


func _continue_run() -> void:
	demo = false
	_hud_visible(true)
	_clear_overlay()
	if not run.load_save():
		_new_run()
		return
	run.locked = meta.locked_perks()
	view.cue_colors = Catalog.CUES.get(run.cue, Catalog.CUES.maple)
	# Building the table draws a rack from the run RNG; keep the saved stream intact.
	var rng_state := run.rng.state
	_setup_table()
	run.rng.state = rng_state
	spin_w.set_spin(0, 0)
	_set_meters(1.0, run.heat)
	lbl_line.text = "Sink balls, stack Heat, avoid the 8."
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
	_sync_hot()
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
	run.apply_physics(sim)
	view.sync_balls(sim, vis_rng, run.imbues)
	is_break = bool(snap.get("is_break", false))
	shot_log.assign(snap.get("log", []))
	log_label.text = "
".join(shot_log)
	guide_dirty = true


func _load_best() -> Dictionary:
	var c := ConfigFile.new()
	c.load("user://settings.cfg")
	return {"tables": int(c.get_value("best", "tables", 0)), "shot": int(c.get_value("best", "shot", 0)), "heat": int(c.get_value("best", "streak", 0))}


func _record_best() -> void:
	var c := ConfigFile.new()
	c.load("user://settings.cfg")
	c.set_value("best", "tables", maxi(int(c.get_value("best", "tables", 0)), run.tables_cleared))
	c.set_value("best", "shot", maxi(int(c.get_value("best", "shot", 0)), run.best_shot))
	c.set_value("best", "streak", maxi(int(c.get_value("best", "streak", 0)), run.best_heat))
	c.save("user://settings.cfg")


var settings := GameSettings.new()
var applied_window := -1


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
	_sync_touch_ui()
	meta.dev_mode = settings.dev_mode
	view.colorblind = settings.colorblind
	guide_dirty = true
	view.number_tags = settings.number_tags
	Engine.max_fps = GameSettings.FRAME_CAPS[settings.frame_cap]
	_apply_screen_layout()
	if DisplayServer.get_name() != "headless" and not OS.has_feature("mobile"):
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)
		if not settings.fullscreen and applied_window != settings.window_size:
			if applied_window >= 0:
				DisplayServer.window_set_size(GameSettings.WINDOW_SIZES[settings.window_size])
			applied_window = settings.window_size
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED)


## How far a camera cutout intrudes from a short edge, in canvas units.
func _hole_inset() -> float:
	if debug_hole >= 0.0:
		return debug_hole
	if not OS.has_feature("mobile"):
		return 0.0
	var screen := Vector2(DisplayServer.screen_get_size())
	if screen.x <= screen.y:
		return 0.0   # still portrait during launch
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var px := maxf(safe.position.x, screen.x - safe.end.x)
	return clampf(px * ScreenFit.FRAME.y / screen.y, 0.0, 200.0)


## Applies the Classic or Wide arrangement. Runs often, and only acts on a change.
func _apply_screen_layout() -> void:
	var win := get_window()
	var win_size := debug_window if debug_window != Vector2i.ZERO else win.size
	var hole := _hole_inset()
	var key := "%s|%s|%.1f" % [settings.screen_layout, win_size, hole]
	if key == fit_key:
		return
	fit_key = key
	var was_x: float = fit.frame_x
	fit = ScreenFit.solve(Vector2(win_size), settings.screen_layout == 1, hole)
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND if fit.wide else Window.CONTENT_SCALE_ASPECT_KEEP
	room_rect.size = fit.view
	(room_rect.material as ShaderMaterial).set_shader_parameter("size", fit.view)
	var origin: Vector2 = TABLE_ORIGIN + fit.table_offset
	view.base_position = origin
	view.home_position = origin
	view.position = origin
	banner.position = Vector2(545, 636) + fit.table_offset
	# Anything already on screen (like the Settings page itself) stays centred.
	for c in overlay.get_children():
		if c is PanelContainer:
			c.position.x += fit.frame_x - was_x
	var text_w: float = fit.panel_size.x - 40.0
	for l in [lbl_rule, lbl_bounty, lbl_boss, lbl_line, flags_label, log_label, lbl_hint]:
		l.custom_minimum_size.x = text_w
	tray.custom_minimum_size.x = fit.panel_size.x - 34.0
	(left_panel.get_child(0) as VBoxContainer).add_theme_constant_override("separation", 3 if fit.wide else 5)
	perk_row.vertical = fit.perks_vertical
	_rebuild_cards()
	_size_hud()
	if not get_tree().process_frame.is_connected(_size_hud):
		get_tree().process_frame.connect(_size_hud, CONNECT_ONE_SHOT)


func _size_hud() -> void:
	left_panel.position = fit.panel_pos
	left_panel.size = fit.panel_size
	bottom_bar.position = fit.perks_pos
	bottom_bar.size = fit.perks_size
	_shrink_panel_to_fit()


## A long table rule can make the side panel taller than the screen; scale it to stay on.
func _shrink_panel_to_fit() -> void:
	var wanted := left_panel.get_combined_minimum_size().y
	var limit: float = fit.panel_size.y
	left_panel.scale = Vector2.ONE * minf(1.0, limit / maxf(wanted, 1.0))


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
	grid.add_theme_constant_override("v_separation", 5)
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
	_setting_toggle(grid, "Invert pull-back (push forward for power)", "invert_drag")
	_setting_toggle(grid, "Click to shoot (power from wheel / Up / Down)", "click_shoot")
	_setting_choice(grid, "Prediction lines", "guide_lines", GameSettings.GUIDE_LINES)
	_setting_toggle(grid, "Pause when the cue ball first hits", "pause_on_hit")
	_setting_toggle(grid, "Arrow keys sweep (no ¼° steps)", "smooth_arrows")
	_setting_toggle(grid, "Colour-blind guideline palette", "colorblind")
	_setting_toggle(grid, "Number tags on every ball", "number_tags")
	_setting_toggle(grid, "Larger small text", "large_text")
	_setting_toggle(grid, "Touch controls", "touch_mode")
	_setting_toggle(grid, "Touch: fine aim (drag turns the shot)", "fine_drag")
	_setting_toggle(grid, "Developer mode (unlock everything)", "dev_mode")
	_setting_choice(grid, "Frame cap", "frame_cap", GameSettings.FRAME_CAPS.map(func(f): return "Unlimited" if f == 0 else "%d FPS" % f))
	_setting_choice(grid, "Window size", "window_size", GameSettings.WINDOW_SIZES.map(func(w): return "%d × %d" % [w.x, w.y]))
	_setting_choice(grid, "Screen layout", "screen_layout", GameSettings.SCREEN_LAYOUTS)
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
	var ctrl_btn := _button("Controls…", func():
		controls_back = back
		_show_controls(), Color(0.6, 0.75, 0.9))
	ctrl_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(ctrl_btn)
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


func _setting_choice(grid: GridContainer, title: String, key: String, options: Array) -> void:
	grid.add_child(_label(title, 16, Color(0.85, 0.87, 0.9), F_REG))
	var o := OptionButton.new()
	for t in options:
		o.add_item(t)
	o.selected = int(settings.get(key))
	o.name = "choice_" + key
	grid.add_child(o)
	grid.add_child(Control.new())
	o.item_selected.connect(func(i: int):
		settings.set(key, i)
		_apply_settings()
		_save_settings())


var controls_back: Callable


func _show_controls() -> void:
	_clear_overlay()
	_dim(0.8)
	var v := _center_panel(640, 640)
	v.add_child(_label("CONTROLS", 30, Color(0.98, 0.8, 0.4), F_PIXB))
	v.add_child(_label("Mouse: aim, drag back to shoot. Gamepad: left stick aims (hold LT for precision), right stick power, A shoots, D-pad spin, Y run info, Start pause.", 13, Color(0.7, 0.75, 0.8), F_REG))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	for a in GameSettings.ACTIONS:
		grid.add_child(_label(GameSettings.ACTIONS[a][0], 16, Color(0.85, 0.87, 0.9), F_REG))
		var txt: String = "Press a key…" if rebinding == a else OS.get_keycode_string(settings.keys[a])
		var b := _button(txt, func():
			rebinding = a
			_show_controls(), Color(0.6, 0.75, 0.9))
		b.custom_minimum_size = Vector2(220, 34)
		b.name = "bind_" + a
		grid.add_child(b)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var d := _button("Reset keys", func():
		settings.reset_keys()
		_save_settings()
		_show_controls(), Color(0.6, 0.75, 0.9))
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(d)
	var bk := _button("Back", func(): _show_settings(controls_back), Color(0.4, 0.9, 0.6))
	bk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bk)


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
		if c.has_section("meta"):
			c.erase_section("meta")
		meta = Meta.new()
		records.entries = []
		records.save_file()
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
	# Overflow can start a table with carried-over points.
	shown_score = 0
	_animate_score(0, run.score)
	_set_meters(1.0, run.heat)
	lbl_line.text = "Overflow carried %d points" % run.score if run.score > 0 else "Sink balls, stack Heat, avoid the 8."
	_enter_aim()
	var t := run.current()
	view.flash(Color(0.55, 0.08, 0.05))
	sfx.play("bad", 0.7, 0.6)
	view.add_shake(5.0)
	_flash_banner(Catalog.BOSSES[t.id].name.to_upper(), Color(1, 0.7, 0.4), 1.8)


func _show_game_over() -> void:
	RunState.clear_save()
	_record_best()
	records.record(run, false)
	_clear_overlay()
	_dim(0.7)
	var v := _center_panel(560, 460, Color(0.9, 0.35, 0.3))
	v.add_child(_label("EXPERIMENT FAILED", 36, Color(1, 0.45, 0.4), F_PIXB))
	v.add_child(_label("Reached table %d. Score %d / %d" % [run.table_index + 1, run.score, run.target()], 18, Color(0.9, 0.9, 0.9), F_REG))
	v.add_child(_label("Tables cleared: %d\nBalls sunk: %d\nBest shot: %d\nBest Heat: %d\nSeed: %d" % [run.tables_cleared, run.total_pots, run.best_shot, run.best_heat, run.seed_value], 17, Color(0.8, 0.82, 0.85), F_REG))
	var b := _button("New Run", _new_run)
	b.custom_minimum_size = Vector2(0, 50)
	v.add_child(b)
	var again_seed := run.seed_value
	v.add_child(_button("Same seed again", func():
		pending_seed = again_seed
		_new_run(), Color(0.5, 0.8, 1.0)))
	v.add_child(_button("Title", _show_title))


func _show_victory(rows: Array) -> void:
	sfx.play_music("victory")
	_record_best()
	records.record(run, true)
	_clear_overlay()
	_dim(0.6)
	var v := _center_panel(620, 470, Color(1.0, 0.85, 0.35))
	v.add_child(_label("ALL TRIALS CLEARED!", 36, Color(1.0, 0.85, 0.4), F_PIXB))
	v.add_child(_label("You beat all 9 tables of Pocket Science.", 18, Color(0.9, 0.9, 0.9), F_REG))
	v.add_child(_label("Balls sunk: %d\nBest shot: %d\nBest Heat: %d" % [run.total_pots, run.best_shot, run.best_heat], 17, Color(0.8, 0.82, 0.85), F_REG))
	var b := _button("Keep going (Endless)", func(): _show_shop(rows), Color(0.4, 0.9, 0.6))
	b.custom_minimum_size = Vector2(0, 50)
	v.add_child(b)
	v.add_child(_button("New Run", _new_run))


func iso_color(id: String) -> Color:
	return Catalog.IMBUES[id].color


## A small drawn pool ball with its number, used for imbue offers.
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
	if shot_log.size() > 3:
		shot_log.resize(3)
	log_label.text = "
".join(shot_log)


## ================================================================ run info
var info_open := false


func _close_run_info() -> void:
	if not info_open:
		_resume()
		return
	info_open = false
	if state == S.SHOP:
		paused = false
		_refresh_shop()
	else:
		_resume()


## Everything about the current build in one place.
func _show_run_info() -> void:
	if not (state == S.AIM or state == S.PLACE or state == S.SHOP):
		return
	info_open = true
	paused = true
	_clear_overlay()
	_dim(0.82)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(Color(0.08, 0.075, 0.08, 0.99), Color(0.5, 0.7, 0.9), 2, 16))
	p.position = Vector2(40.0 + fit.frame_x, 30.0)
	p.size = Vector2(1520, 840)
	overlay.add_child(p)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	p.add_child(outer)
	var head := HBoxContainer.new()
	outer.add_child(head)
	head.add_child(_label("RUN INFO", 30, Color(0.98, 0.8, 0.4), F_PIXB))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var cue: Dictionary = Catalog.CUES.get(run.cue, Catalog.CUES.maple)
	head.add_child(_label("%s  ·  seed %d  ·  $%d" % [cue.name, run.seed_value, run.money], 17, Color(0.8, 0.85, 0.9), F_REG))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(cols)

	# Column 1: build
	var c1 := VBoxContainer.new()
	c1.custom_minimum_size = Vector2(560, 0)
	c1.add_theme_constant_override("separation", 6)
	cols.add_child(c1)
	c1.add_child(_label("PERKS  (%d / %d)" % [run.perks.size(), RunState.MAX_PERKS], 16, Color(0.6, 0.8, 1.0)))
	if run.perks.is_empty():
		c1.add_child(_label("None yet - buy them in the Pro Shop between tables.", 15, Color(0.6, 0.6, 0.65), F_REG))
	for id in run.perks:
		var fd: Dictionary = Catalog.PERKS[id]
		c1.add_child(_term_text("%s  (%s)  -  %s" % [fd.name, Catalog.rarity_name(fd.r), Glossary.link(fd.desc)], 15, Catalog.rarity_color(fd.r).lerp(Color.WHITE, 0.5), 560.0))
	if run.perks.has("catalyst"):
		c1.add_child(_label("Snowball: every ball is worth +%s." % _fmt(run.catalyst), 14, Color(1.0, 0.6, 0.3), F_REG))
	c1.add_child(_label("IMBUED BALLS", 16, Color(0.6, 0.8, 1.0)))
	if run.imbues.is_empty():
		c1.add_child(_label("None.", 15, Color(0.6, 0.6, 0.65), F_REG))
	var balls := run.imbues.keys()
	balls.sort()
	for n in balls:
		var iso: Dictionary = Catalog.IMBUES[run.imbues[n]]
		c1.add_child(_label("%d-ball: %s - %s" % [n, iso.name, iso.desc], 15, iso.color, F_REG))

	# Column 2: tables
	var c2 := VBoxContainer.new()
	c2.custom_minimum_size = Vector2(430, 0)
	c2.add_theme_constant_override("separation", 6)
	cols.add_child(c2)
	c2.add_child(_label("THE TRIALS", 16, Color(0.6, 0.8, 1.0)))
	for i in run.plan.size():
		var t: Dictionary = run.plan[i]
		var mark := "> " if i == run.table_index else ("Done: " if i < run.table_index else "   ")
		var txt := "%sTable %d  ·  %s  ·  target %d" % [mark, i + 1, Catalog.BOSSES[t.id].name, t.target]
		var col := Color(1.0, 0.85, 0.45) if i == run.table_index else (Color(0.5, 0.75, 0.55) if i < run.table_index else Color(0.8, 0.82, 0.85))
		c2.add_child(_label(txt, 15, col, F_REG))
		var bl := _label(Catalog.BOSSES[t.id].desc, 13, Color(1.0, 0.7, 0.5), F_REG)
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bl.custom_minimum_size = Vector2(400, 0)
		var indent := MarginContainer.new()
		indent.add_theme_constant_override("margin_left", 30)
		indent.add_child(bl)
		c2.add_child(indent)
	if run.endless:
		c2.add_child(_label("Endless: table %d (target %d)" % [run.table_index + 1, run.target()], 15, Color(1.0, 0.85, 0.45), F_REG))

	# Column 3: rules
	var c3 := VBoxContainer.new()
	c3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c3.add_theme_constant_override("separation", 6)
	cols.add_child(c3)
	c3.add_child(_label("SCORING", 16, Color(0.6, 0.8, 1.0)))
	var hot_x := 3 if run.perks.has("heat") else 2
	var rules := [
		"Each sink = value × Chain × Heat",
		"Value: 10 + ball number",
		"Chain: starts at 1, +0.5 per ball sunk this shot",
		"Heat: +1 per scoring shot, each point adds ×0.5, a miss halves it",
		"Bounces score nothing unless a Perk, Imbue or table says so",
		"Value: 10 + 2 × the ball's number (special balls have their own)",
		"Hot pocket ×%d, then Perks; the 8 costs 15%% of the target if it sinks early" % hot_x,
		"Miss / scratch / no contact: -1 chalk (dry break free)",
		"Clear the rack: +1 chalk and a new rack",
		"Clearing pays $4, +$1 per 10% over target, +$1 per shot under 10",
	]
	for r in rules:
		var l := _label("•  " + r, 14, Color(0.82, 0.84, 0.87), F_REG)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(400, 0)
		c3.add_child(l)
	c3.add_child(_label("STATS", 16, Color(0.6, 0.8, 1.0)))
	c3.add_child(_label("Tables cleared %d  ·  balls potted %d
Best shot %d  ·  best streak %d" % [run.tables_cleared, run.total_pots, run.best_shot, run.best_heat], 14, Color(0.82, 0.84, 0.87), F_REG))
	var close := _button("Close  [Tab / Esc]", _close_run_info, Color(0.5, 0.7, 0.9))
	close.custom_minimum_size = Vector2(0, 46)
	outer.add_child(close)


## ================================================================ credits
const LICENSE_FILES := [
	["Chakra Petch font (SIL OFL 1.1)", "res://licenses/chakrapetch-OFL.txt"],
	["Silkscreen font (SIL OFL 1.1)", "res://licenses/silkscreen-OFL.txt"],
	["Godot Engine (MIT)", "res://licenses/GODOT_LICENSE.txt"],
]


func _show_credits() -> void:
	_clear_overlay()
	_dim(0.8)
	var v := _center_panel(820, 640)
	v.add_child(_label("CREDITS", 30, Color(0.98, 0.8, 0.4), F_PIXB))
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.fit_content = true
	rt.custom_minimum_size = Vector2(780, 0)
	rt.add_theme_font_override("normal_font", F_REG)
	rt.add_theme_font_override("bold_font", F_SEMI)
	rt.add_theme_font_size_override("normal_font_size", 16)
	rt.add_theme_font_size_override("bold_font_size", 17)
	rt.text = """[b]Pocket Science[/b]
Game design and direction: Jordan Mitchell
Built in Godot 4.7

[b]Music[/b]
Original Pocket Science score, composed for the project (see licenses/MUSIC-NOTE.md)

[b]Sound effects[/b]
Synthesised in-engine

[b]Fonts[/b]
Chakra Petch - Copyright 2018 The Chakra Petch Project Authors, SIL Open Font License 1.1
Silkscreen - Copyright 2001 The Silkscreen Project Authors, SIL Open Font License 1.1

[b]Engine[/b]
Godot Engine - Copyright (c) 2014-present Godot Engine contributors, MIT License"""
	v.add_child(rt)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	for lic in LICENSE_FILES:
		var b := _button(lic[0], func(): _show_license(lic[0], lic[1]), Color(0.6, 0.75, 0.9))
		b.add_theme_font_size_override("font_size", 13)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	v.add_child(_button("Back", _show_title, Color(0.4, 0.9, 0.6)))


func _show_license(title: String, path: String) -> void:
	_clear_overlay()
	_dim(0.85)
	var v := _center_panel(900, 760)
	v.add_child(_label(title, 22, Color(0.98, 0.8, 0.4), F_SEMI))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(860, 600)
	v.add_child(sc)
	var txt := FileAccess.get_file_as_string(path)
	var l := _label(txt if txt != "" else "Licence file missing: " + path, 13, Color(0.82, 0.84, 0.87), F_REG)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(840, 0)
	sc.add_child(l)
	v.add_child(_button("Back", _show_credits, Color(0.4, 0.9, 0.6)))
