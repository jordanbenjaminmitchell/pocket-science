class_name TableView
extends Node2D
## Draws the pool table in table units (the node's transform maps to screen).
## Layers, bottom to top: wood rails (this node), felt, cushions/pockets,
## balls, guideline overlay, cue stick, effects.

const FELT_SHADER := preload("res://src/view/shaders/felt.gdshader")
const W := TableLayout.W
const H := TableLayout.H
const R := TableLayout.R
const RAIL := 64.0
const CUSHION := 20.0

var layout: TableLayout
var felt_color := Color(0.06, 0.42, 0.28)
var font: Font
var font_bold: Font
var felt: ColorRect
var felt_mat: ShaderMaterial
var cushions: Node2D
var balls_layer: Node2D
var overlay: Node2D
var cue_layer: Node2D
var fx_layer: Node2D
var ball_nodes := {}   # ball index -> BallNode

# Aim / guideline state, fed by Main.
var show_guide := false
var guide := {}
var forecast_paths: Array = []
var forecast_text := ""        # Second Sight's preview of the whole shot
var plan_marker := Vector2.INF   # where a planned pause will happen
var plan_hover := Vector2.INF    # where the cursor would plan one
var temp_walls: Array = []       # Pop-up Walls for this shot: [a, b]
var strike_line: Array = []      # Second Strike aim: [from, to]
var hold_text := ""
var call_ball := -1           # Called Shot: the ball and pocket called
var call_pocket := -1
var ghost_ball := -1          # Ghost Chalk
var pebbles: Array = []       # Gravity Pebbles this shot
var sink_tags: Array = []     # [pocket, text]: the score of every predicted sink
var heat_level := 0           # FireFx tier: the table burns from On fire up
var hot_pocket := -1
var clock_on := false            # Clockwork Table: number the pockets and mark the next
var clock_pos := 0
var clock_streak := 0
var second_pocket := -1   # Quantum Pockets board: also scores, shown with a cooler ring
var hot_mult := 2
var preview_text := ""
var preview_pocket := -1
var cue_visible := false
var cue_colors: Dictionary = {}
var colorblind := false
var number_tags := false
var place_hints: Array = []   # [[ball pos, pocket pos], ...] pots available from the ball-in-hand spot
var place_radius := 0.0       # 0 = a ball; otherwise the size of the thing being placed
var coach_text := ""
var coach_pos := Vector2.ZERO
var cue_pos := Vector2.ZERO
var cue_dir := Vector2.RIGHT
var cue_pull := 0.0
var placing := false
var place_pos := Vector2.ZERO
var place_ok := true
var head_only := false
var time := 0.0
## Ball numbers to ring with light: the balls a hovered Perk works on.
var spotlight: Array = []
## The board's Sharks and moving parts (RunState.board), drawn from BoardArt.
var board := {}
var board_id := ""
var shark_flash := {}   # Shark index -> seconds of "hit" flash left
var hover_pocket := -1
var pocket_pick := false

# Effects
var particles: Array = []
var popups: Array = []
var rings: Array = []
var shake := 0.0
var base_position := Vector2.ZERO


func setup(l: TableLayout, f: Font, fb: Font) -> void:
	layout = l
	font = f
	font_bold = fb
	if felt == null:
		felt = ColorRect.new()
		felt.size = Vector2(W, H)
		felt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		felt_mat = ShaderMaterial.new()
		felt_mat.shader = FELT_SHADER
		felt_mat.set_shader_parameter("size", Vector2(W, H))
		felt.material = felt_mat
		add_child(felt)
		cushions = _layer(_draw_cushions)
		balls_layer = Node2D.new()
		add_child(balls_layer)
		overlay = _layer(_draw_overlay)
		cue_layer = _layer(_draw_cue)
		fx_layer = _layer(_draw_fx)
	set_felt(felt_color)
	queue_redraw()
	cushions.queue_redraw()


func _layer(cb: Callable) -> Node2D:
	var n := Node2D.new()
	n.draw.connect(cb)
	add_child(n)
	return n


var rail_color := Color(0.30, 0.15, 0.07)
var trim_color := Color(0.92, 0.9, 0.82)
var decal := ""
var rail_material := ""   # a textured rail from BoardArt (chrome, gilded...), or "" for wood
var flash_col := Color(0, 0, 0, 0)
var flash_t := 0.0


## The table's cloth art: the lab's rail colours, and the board's own decal
## (BoardArt.DECALS) when it has one, else the lab's.
func set_lab(id: String, board := "") -> void:
	var art: Dictionary = Catalog.LAB_ART.get(id, Catalog.LAB_ART.standard)
	rail_color = art.rail
	trim_color = art.trim
	var own := BoardArt.same_board(board)
	decal = BoardArt.DECALS[board] if own and BoardArt.DECALS.get(board, "") != "" else art.decal
	rail_material = BoardArt.RAILS.get(board, "") if own else ""
	if rail_material != "":
		rail_color = BoardArt.RAIL_BASE[rail_material]
	if own:
		set_felt(BoardArt.felt_for(board, felt_color))
	queue_redraw()
	cushions.queue_redraw()


## Fades the table in from a colour (new tables, boss arrivals).
func flash(c: Color, seconds: float = 0.4) -> void:
	if reduced_motion:
		return
	flash_col = c
	flash_t = seconds


func set_felt(c: Color) -> void:
	felt_color = c
	felt_mat.set_shader_parameter("felt", c)
	queue_redraw()
	if cushions:
		cushions.queue_redraw()


## ---------------------------------------------------------------- balls
func sync_balls(sim: PoolSim, rng: RandomNumberGenerator, imbues: Dictionary) -> void:
	for k in ball_nodes:
		ball_nodes[k].queue_free()
	ball_nodes.clear()
	for i in sim.count():
		var b := BallNode.new()
		balls_layer.add_child(b)
		b.position = sim.pos[i]
		b.setup(sim.num[i], font_bold, rng)
		ball_nodes[i] = b
		if sim.alive[i] == 0:
			b.visible = false
	refresh_glows(sim, imbues)


func refresh_glows(sim: PoolSim, imbues: Dictionary) -> void:
	for i in ball_nodes:
		var n: int = sim.num[i]
		var iso: String = imbues.get(n, "")
		if iso != "":
			var c: Color = Catalog.IMBUES[iso].color
			c.a = 0.95
			ball_nodes[i].set_glow(c, BallNode.IMBUE_FX.get(iso, ""))
		else:
			ball_nodes[i].set_glow(Color(0, 0, 0, 0))


var last_sim_time := 0.0


func update_balls(sim: PoolSim) -> void:
	var dt := clampf(sim.time - last_sim_time, 0.0, 0.1)
	last_sim_time = sim.time
	for i in ball_nodes:
		var b: BallNode = ball_nodes[i]
		if b.sinking:
			continue
		if sim.alive[i] == 1:
			if not b.visible:
				b.visible = true
				b.set_fade(1.0)
			var extra := sim.visual_extra_roll(i) * dt
			if b.position != sim.pos[i] or extra != Vector2.ZERO:
				var travelled: float = b.position.distance_to(sim.pos[i])
				b.roll_to(sim.pos[i], sim.stop_distance(i), extra, sim.visual_twist(i) * travelled / b.radius)
			if b.vel != sim.vel[i]:
				b.vel = sim.vel[i]
				b.refresh_label()
				b.queue_redraw()
		elif b.visible:
			b.visible = false


## The board's fields, under the balls: Coriolis's turntable, the Gulf Stream's
## current and the Capacitor's charged rail.
func _draw_board_fields(c: CanvasItem) -> void:
	match board_id:
		"drift":
			BoardArt.draw_turntable(c, Vector2(W * 0.5, H * 0.5), 130.0, time * 0.9)
		"gulf":
			BoardArt.draw_conveyor(c, Rect2(0, H * 0.38, W, H * 0.24), Vector2.RIGHT, time)
		"spring_st":
			BoardArt.draw_charged_rail(c, Vector2(40, 0), Vector2(W - 40, 0), 0.35, time)
			if BoardFeatures.charged(board):
				BoardArt.draw_charged_rail(c, Vector2(40, H), Vector2(W - 40, H), 1.0, time)
		"venturi":
			BoardArt.draw_conveyor(c, Rect2(560, 205, 90, 90), Vector2.RIGHT, time * 1.6)
		"lorentz":
			_draw_lorentz(c)
		"meissner":
			for p: Vector2 in BoardFeatures.MEISSNER_POSTS:
				for k in 3:
					var rr := 24.0 + fmod(time * 30.0 + k * 16.0, 48.0)
					c.draw_arc(p, rr, 0, TAU, 40, Color(0.6, 0.85, 1.0, 0.28 * (1.0 - (rr - 24.0) / 48.0)), 2.0, true)
		"escape":
			for p: Vector2 in BoardFeatures.ESCAPE_WELLS:
				_draw_well(c, p, 1.0)
		"tesla":
			_draw_coil(c, Vector2(W * 0.5, H * 0.5), BoardFeatures.coil_on(board))
		"parabolic", "whisper", "spiral":
			var fk := 4 if board_id == "spiral" else 5
			if fk < layout.pockets.size():
				var fp: Vector2 = layout.pockets[fk].pos
				var pulse := 0.5 + 0.5 * sin(time * 3.0)
				c.draw_arc(fp, 38.0 + pulse * 4.0, 0, TAU, 48, Color(1.0, 0.85, 0.4, 0.55), 2.5, true)
				if board_id == "whisper":
					# The other focus, which every shot through it is aimed from.
					var other := Vector2(W - fp.x, fp.y)
					c.draw_arc(other, 10.0, 0, TAU, 24, Color(1.0, 0.85, 0.4, 0.7), 2.0, true)
					c.draw_line(other + Vector2(-6, 0), other + Vector2(6, 0), Color(1.0, 0.85, 0.4, 0.7), 1.5)
					c.draw_line(other + Vector2(0, -6), other + Vector2(0, 6), Color(1.0, 0.85, 0.4, 0.7), 1.5)
	_draw_board_walls(c)


## The board's own walls: rails, ridges, islands and the spiral arm as raised
## wooden rails; the membrane as a living wall; the Demon at his gate.
func _draw_board_walls(c: CanvasItem) -> void:
	if layout == null:
		return
	var rail := Color(0.42, 0.3, 0.2)
	match board_id:
		"tectonic":
			rail = Color(0.36, 0.3, 0.27)
		"sierpinski":
			rail = Color(0.88, 0.88, 0.86)
		"spiral":
			rail = Color(0.72, 0.52, 0.22)
		"venturi":
			rail = Color(0.72, 0.42, 0.24)
	var done := {}
	for seg in layout.segments:
		if not seg.has("board"):
			continue
		var a: Vector2 = seg.a
		var b: Vector2 = seg.b
		var key := "%d,%d,%d,%d" % [mini(int(a.x), int(b.x)), mini(int(a.y), int(b.y)), maxi(int(a.x), int(b.x)), maxi(int(a.y), int(b.y))]
		if seg.has("membrane"):
			_draw_membrane(c, a, b)
			continue
		if seg.has("fast") or seg.has("slow"):
			if not done.has("gate"):
				done["gate"] = true
				var mid := (a + b) * 0.5
				c.draw_line(a, b, Color(0.9, 0.85, 0.35, 0.35), 3.0)
				BoardArt.draw_demon(c, mid, 0.5 + 0.5 * sin(time * 2.0), time)
			continue
		if done.has(key) or board_id == "elements" or board_id == "lever":
			continue   # the Sweeper and the Lever have their own drawings
		done[key] = true
		c.draw_line(a + Vector2(3, 5), b + Vector2(3, 5), Color(0, 0, 0, 0.3), 10.0, true)
		c.draw_line(a, b, rail, 9.0, true)
		c.draw_line(a, b, rail.lightened(0.35), 3.0, true)
		c.draw_circle(a, 4.5, rail.lightened(0.15), true, -1.0, true)
		c.draw_circle(b, 4.5, rail.lightened(0.15), true, -1.0, true)
	if board_id == "lever":
		var ends := BoardFeatures.lever_ends(board)
		var mid: Vector2 = ((ends[0] as Vector2) + (ends[1] as Vector2)) * 0.5
		BoardArt.draw_seesaw(c, mid, BoardFeatures.LEVER_HALF * 2.0, ((ends[1] as Vector2) - (ends[0] as Vector2)).angle())


## Semipermeable Membrane: a soft, rippling cell wall with arrows showing the
## way balls may pass.
func _draw_membrane(c: CanvasItem, a: Vector2, b: Vector2) -> void:
	var col := Color(0.45, 0.95, 0.75)
	var pts := PackedVector2Array()
	var n := (b - a).orthogonal().normalized()
	for i in 41:
		var f := i / 40.0
		pts.append(a.lerp(b, f) + n * sin(f * 30.0 + time * 3.0) * 3.0)
	c.draw_polyline(pts, Color(col, 0.25), 9.0, true)
	c.draw_polyline(pts, Color(col, 0.85), 2.0, true)
	for k in 5:
		var p := a.lerp(b, (k + 0.5) / 5.0) + Vector2(fmod(time * 20.0, 24.0) - 12.0, 0)
		c.draw_colored_polygon(PackedVector2Array([p + Vector2(8, 0), p + Vector2(-4, -6), p + Vector2(-4, 6)]), Color(col, 0.7))


## Lorentz Field: a marked zone of field lines coming out of the cloth.
func _draw_lorentz(c: CanvasItem) -> void:
	var r: Rect2 = BoardFeatures.LORENTZ_RECT
	var col := Color(0.35, 0.65, 1.0)
	c.draw_rect(r, Color(col, 0.06))
	c.draw_rect(r, Color(col, 0.5), false, 2.0)
	var y := r.position.y + 28.0
	var row := 0
	while y < r.end.y - 10.0:
		var x := r.position.x + (28.0 if row % 2 == 0 else 52.0)
		while x < r.end.x - 10.0:
			var a := 0.35 + 0.25 * sin(time * 2.0 + x * 0.05 + y * 0.03)
			c.draw_arc(Vector2(x, y), 5.0, 0, TAU, 14, Color(col, a), 1.5, true)
			c.draw_circle(Vector2(x, y), 1.6, Color(col, a + 0.2), true, -1.0, true)
			x += 48.0
		y += 42.0
		row += 1


## A gravity well: rings spiralling in.
func _draw_well(c: CanvasItem, p: Vector2, strength: float) -> void:
	for k in 5:
		var rr := 14.0 + fmod(80.0 - time * 24.0 + k * 16.0, 80.0)
		c.draw_arc(p, rr, time * 0.8 + k, time * 0.8 + k + PI * 1.5, 32, Color(0.75, 0.6, 1.0, 0.3 * strength * (1.0 - rr / 94.0)), 2.0, true)
	c.draw_circle(p, 9.0, Color(0.05, 0.02, 0.1, 0.85), true, -1.0, true)
	c.draw_arc(p, 11.0, 0, TAU, 24, Color(0.85, 0.7, 1.0, 0.7), 1.5, true)


## Tesla Coil: copper windings in the middle; lightning when it will fire this shot.
func _draw_coil(c: CanvasItem, p: Vector2, live: bool) -> void:
	for k in 4:
		c.draw_arc(p, 10.0 + k * 6.0, 0, TAU, 32, Color(0.8, 0.5, 0.25, 0.75), 2.5, true)
	c.draw_circle(p, 7.0, Color(0.9, 0.9, 1.0) if live else Color(0.4, 0.4, 0.45), true, -1.0, true)
	if not live:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(time * 12.0)
	for k in 6:
		var a := TAU * k / 6.0 + rng.randf() * 0.4
		var pts := PackedVector2Array([p])
		var q := p
		for s in 6:
			q += Vector2.from_angle(a + rng.randf_range(-0.6, 0.6)) * 18.0
			pts.append(q)
		c.draw_polyline(pts, Color(0.7, 0.8, 1.0, 0.8), 2.0, true)
	for k in 3:
		var rr := 40.0 + fmod(time * 120.0 + k * 60.0, 180.0)
		c.draw_arc(p, rr, 0, TAU, 64, Color(0.6, 0.75, 1.0, 0.35 * (1.0 - rr / 220.0)), 2.0, true)


## The board's Sharks, the pendulum bob, the Sweeper and the Leech, over the balls.
func _draw_board_pieces(c: CanvasItem) -> void:
	if board.is_empty():
		return
	var sharks: Array = board.get("sharks", [])
	for i in sharks.size():
		var sh: Dictionary = sharks[i]
		var kind := String(sh.kind)
		if kind == "leech":
			if not sh.ko:
				var n := int(board.get("leech_ball", -1))
				for bi in ball_nodes:
					var bn: BallNode = ball_nodes[bi]
					if is_instance_valid(bn) and bn.number == n and bn.visible:
						BoardArt.draw_shark(c, "leech", bn.position + Vector2(0, -bn.radius - 4), -0.4, 34.0, "normal", time)
			continue
		var state := "ko" if sh.ko else ("hit" if float(shark_flash.get(i, 0.0)) > 0.0 else "normal")
		var r := float(BoardFeatures.SHARKS[kind].r)
		BoardArt.draw_shark(c, kind, BoardFeatures.shark_pos(sh), float(sh.heading), r * 4.2, state, time, float(sh.hp) / maxf(1.0, float(sh.max)), int(sh.max))
	match board_id:
		"elements":
			BoardArt.draw_sweeper(c, Vector2(W * 0.5, H * 0.5), BoardFeatures.sweep_angle(board), BoardFeatures.SWEEP_LEN, time)
		"foucault":
			BoardArt.draw_pendulum(c, Vector2(W * 0.5, H * 0.5), BoardFeatures.bob_pos(board), BoardFeatures.BOB_R, time)


## Animate a ball dropping into pocket k.
func sink(i: int, k: int) -> void:
	var b: BallNode = ball_nodes.get(i)
	if b == null:
		return
	b.sinking = true
	var target: Vector2 = layout.pockets[k].pos
	# The tween belongs to the ball, so it stops if the ball is freed mid-drop
	# (a cleared rack is re-racked while its last ball is still falling).
	var tw := b.create_tween()
	tw.set_parallel(true)
	tw.tween_method(func(p: Vector2): b.roll_to(p), b.position, target, 0.14)
	tw.tween_property(b, "scale", Vector2(0.62, 0.62), 0.22)
	tw.tween_method(func(f: float): b.set_fade(f), 1.0, 0.0, 0.26).set_delay(0.06)
	tw.chain().tween_callback(func():
		b.visible = false
		b.sinking = false
		b.scale = Vector2.ONE
		b.set_fade(1.0))


func ball_screen(i: int) -> Vector2:
	var b: BallNode = ball_nodes.get(i)
	return b.position if b else Vector2.ZERO


## ---------------------------------------------------------------- frame update
func _process(delta: float) -> void:
	time += delta
	if shake > 0.0:
		shake = maxf(0.0, shake - delta * 30.0)
		position = base_position + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	else:
		position = base_position
	for p in particles:
		p.life -= delta
		p.pos += p.vel * delta
		p.vel *= 1.0 - minf(1.0, delta * p.get("drag", 3.0))
	particles = particles.filter(func(p): return p.life > 0.0)
	for p in popups:
		p.life -= delta
		p.pos.y -= delta * 38.0
	popups = popups.filter(func(p): return p.life > 0.0)
	for k in shark_flash.keys():
		shark_flash[k] = float(shark_flash[k]) - delta
		if float(shark_flash[k]) <= 0.0:
			shark_flash.erase(k)
	for r in rings:
		r.life -= delta
	rings = rings.filter(func(r): return r.life > 0.0)
	# Embers rising from the hot pocket.
	if hot_pocket >= 0 and not reduced_motion and not Fx.minimal_particles and hot_pocket < layout.pockets.size() and randf() < delta * 22.0:
		var hp: Dictionary = layout.pockets[hot_pocket]
		var a := randf() * TAU
		particles.append({"pos": (hp.pos as Vector2) + Vector2(cos(a), sin(a)) * randf_range(10, hp.r), "vel": (hp.dir as Vector2) * randf_range(15, 45) + Vector2(randf_range(-10, 10), randf_range(-10, 10)),
			"life": randf_range(0.5, 1.1), "max": 1.1, "color": Color(1.0, randf_range(0.4, 0.75), 0.15), "size": randf_range(1.2, 2.4), "drag": 0.5})
	if particles.size() > 700:
		particles = particles.slice(particles.size() - 700)
	if flash_t > 0.0:
		flash_t = maxf(0.0, flash_t - delta)
	cushions.queue_redraw()
	overlay.queue_redraw()
	cue_layer.queue_redraw()
	fx_layer.queue_redraw()


var punch_tw: Tween


## Brief zoom pulse around the table centre for big moments.
func punch(amount: float) -> void:
	if reduced_motion:
		return
	if punch_tw and punch_tw.is_valid():
		punch_tw.kill()
	var base := Vector2(base_scale, base_scale)
	var centre_screen := base_position + Vector2(W, H) * 0.5 * base_scale
	var s := base_scale * (1.0 + amount)
	scale = Vector2(s, s)
	base_position = centre_screen - Vector2(W, H) * 0.5 * s
	punch_tw = create_tween()
	punch_tw.set_parallel(true)
	punch_tw.tween_property(self, "scale", base, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	punch_tw.tween_property(self, "base_position", home_position, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


var base_scale := 1.0
var home_position := Vector2.ZERO


func spark(p: Vector2, strength: float) -> void:
	if Fx.minimal_particles:
		return
	var n := int(4 + strength * 10)
	for i in n:
		var a := randf() * TAU
		particles.append({"pos": p, "vel": Vector2(cos(a), sin(a)) * randf_range(60, 200) * strength, "life": randf_range(0.12, 0.3), "max": 0.3, "color": Color(1, 0.95, 0.8), "size": randf_range(1.0, 2.0)})


var shake_scale := 1.0
var reduced_motion := false


func add_shake(a: float) -> void:
	a *= 0.0 if reduced_motion else shake_scale
	shake = minf(10.0, shake + a)


func burst(p: Vector2, c: Color, n: int = 18, speed: float = 220.0) -> void:
	if Fx.minimal_particles:
		n = mini(n, 3)   # a few specks still mark where the ball went
	for i in n:
		var a := randf() * TAU
		var s := randf_range(0.3, 1.0) * speed
		particles.append({"pos": p, "vel": Vector2(cos(a), sin(a)) * s, "life": randf_range(0.35, 0.8), "max": 0.8, "color": c, "size": randf_range(1.5, 4.0)})


func trail(p: Vector2, c: Color, heat: float) -> void:
	if Fx.minimal_particles:
		return
	for i in int(1 + heat * 2):
		var a := randf() * TAU
		particles.append({"pos": p + Vector2(cos(a), sin(a)) * randf_range(0, R * 0.6), "vel": Vector2(cos(a), sin(a)) * 20.0, "life": 0.35 + heat * 0.25, "max": 0.6, "color": c, "size": 2.5 + heat * 3.0})


## Celebration: coloured paper falling across the table.
func confetti() -> void:
	if reduced_motion or Fx.minimal_particles:
		return
	var cols := [Color(1, 0.8, 0.3), Color(0.3, 0.8, 1), Color(1, 0.4, 0.5), Color(0.5, 1, 0.6), Color(0.8, 0.5, 1)]
	for i in 160:
		particles.append({"pos": Vector2(randf_range(0, W), randf_range(-80, -10)), "vel": Vector2(randf_range(-60, 60), randf_range(250, 520)), "life": randf_range(1.2, 2.2), "max": 2.2, "color": cols[i % cols.size()], "size": randf_range(2.5, 4.5), "drag": 0.0})


func popup(p: Vector2, text: String, c: Color, size: int = 22, life: float = 1.1) -> void:
	popups.append({"pos": p, "text": text, "color": c, "size": size, "life": life, "max": life})


func ring(p: Vector2, c: Color, r: float = 40.0) -> void:
	rings.append({"pos": p, "color": c, "r": r, "life": 0.5, "max": 0.5})


## ---------------------------------------------------------------- table drawing
func _draw() -> void:
	var outer := Rect2(-RAIL - CUSHION, -RAIL - CUSHION, W + 2 * (RAIL + CUSHION), H + 2 * (RAIL + CUSHION))
	# Floor shadow.
	for i in 6:
		var g := 10.0 + i * 9.0
		draw_rect(outer.grow(g * 0.6).grow_individual(0, 0, 0, g * 0.4), Color(0, 0, 0, 0.07), true)
	# Wood rail with layered bevel.
	var wood := rail_color
	draw_rect(outer, wood.darkened(0.45), true)
	# Rounded bevel: bands from dark outer edge to a lit crown.
	for i in 10:
		var t := i / 9.0
		var col := wood.darkened(0.35 - t * 0.35).lightened(sin(t * PI) * 0.1)
		draw_rect(outer.grow(-2.0 - i * 2.2), col, true)
	# Lacquer highlight along the top edge of each rail.
	draw_line(outer.position + Vector2(10, 9), Vector2(outer.end.x - 10, outer.position.y + 9), Color(1, 0.9, 0.75, 0.12), 3.0)
	draw_line(outer.position + Vector2(9, 10), Vector2(outer.position.x + 9, outer.end.y - 10), Color(1, 0.9, 0.75, 0.08), 3.0)
	# Grain.
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 70:
		var horizontal := i < 46
		var c := Color(0.12, 0.05, 0.02, rng.randf_range(0.05, 0.16))
		if horizontal:
			var y := rng.randf_range(outer.position.y + 4, outer.end.y - 4)
			if y > -CUSHION - 2 and y < H + CUSHION + 2:
				continue
			var x0 := rng.randf_range(outer.position.x, outer.end.x - 200)
			draw_line(Vector2(x0, y), Vector2(x0 + rng.randf_range(120, 600), y + rng.randf_range(-1.5, 1.5)), c, rng.randf_range(0.6, 2.0))
		else:
			var x := rng.randf_range(outer.position.x + 4, outer.end.x - 4)
			if x > -CUSHION - 2 and x < W + CUSHION + 2:
				continue
			var y0 := rng.randf_range(outer.position.y, outer.end.y - 150)
			draw_line(Vector2(x, y0), Vector2(x + rng.randf_range(-1.5, 1.5), y0 + rng.randf_range(100, 400)), c, rng.randf_range(0.6, 2.0))
	var inner := Rect2(-CUSHION, -CUSHION, W + 2 * CUSHION, H + 2 * CUSHION)
	if rail_material != "":
		# A textured rail: four strips over the wood, between the edge and the lip.
		var t := inner.position.y - 6.0 - outer.position.y
		for r in [Rect2(outer.position, Vector2(outer.size.x, t)), Rect2(Vector2(outer.position.x, inner.end.y + 6.0), Vector2(outer.size.x, t)),
				Rect2(Vector2(outer.position.x, outer.position.y + t), Vector2(t, outer.size.y - 2.0 * t)), Rect2(Vector2(inner.end.x + 6.0, outer.position.y + t), Vector2(t, outer.size.y - 2.0 * t))]:
			BoardArt.draw_rail(self, r, rail_material)
	# Highlight lip on the inner edge of the wood.
	draw_rect(inner.grow(6), rail_color.lightened(0.3), false, 3.0)
	draw_rect(inner.grow(2), Color(0.08, 0.04, 0.02), false, 3.0)
	# Cushion rubber base.
	draw_rect(inner, felt_color.darkened(0.38), true)
	# Diamonds (sights).
	var dy := -CUSHION - RAIL * 0.5
	for i in range(1, 8):
		if i == 4:
			continue
		var x := W * i / 8.0
		_diamond(Vector2(x, dy))
		_diamond(Vector2(x, H - dy))
	for i in range(1, 4):
		var y := H * i / 4.0
		_diamond(Vector2(dy, y))
		_diamond(Vector2(W - dy, y))


func _diamond(p: Vector2) -> void:
	var s := 5.5
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.7, 0), p + Vector2(0, s), p + Vector2(-s * 0.7, 0)]), trim_color)
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.7, 0), p + Vector2(0, 0)]), Color(1, 1, 1, 0.5))


func _draw_cushions() -> void:
	var c := cushions
	if decal != "":
		IconArt.paint(c, decal, Vector2(W * 0.5, H * 0.5), 4.6, Color(1, 1, 1, 0.06), Color(0, 0, 0, 0), font_bold, 7.0)
	# Cushion nose shading: a light lip right at the playfield edge.
	var lip := felt_color.lightened(0.18)
	var dark := felt_color.darkened(0.55)
	var shaped := not layout.shape.is_empty()
	if shaped:
		# A shaped table: wood covers the frame outside the playfield.
		var frame := PackedVector2Array([Vector2(-CUSHION, -CUSHION), Vector2(W + CUSHION, -CUSHION), Vector2(W + CUSHION, H + CUSHION), Vector2(-CUSHION, H + CUSHION)])
		var grown: PackedVector2Array = Geometry2D.offset_polygon(layout.shape, CUSHION)[0]
		for piece in Geometry2D.clip_polygons(frame, grown):
			if not Geometry2D.is_polygon_clockwise(piece):
				c.draw_colored_polygon(piece, rail_color.darkened(0.15))
		c.draw_polyline(grown + PackedVector2Array([grown[0]]), rail_color.lightened(0.3), 3.0, true)
	for seg in layout.segments:
		var a: Vector2 = seg.a
		var b: Vector2 = seg.b
		var n: Vector2 = seg.n
		if seg.has("board"):
			continue   # the board's own walls, gates and membranes: _draw_board_walls
		var is_rail := absf(n.x) < 0.01 or absf(n.y) < 0.01
		if (is_rail and (a.x == b.x or a.y == b.y)) or (shaped and a.distance_to(b) > 28.0):
			var poly := PackedVector2Array([a, b, b - n * CUSHION, a - n * CUSHION])
			c.draw_colored_polygon(poly, felt_color.darkened(0.22))
			c.draw_line(a - n * CUSHION, b - n * CUSHION, dark, 2.0)
			c.draw_line(a + n * 1.0, b + n * 1.0, lip, 2.0)
		else:
			c.draw_line(a, b, lip.darkened(0.2), 2.0)
	# Pockets.
	for k in layout.pockets.size():
		var pk: Dictionary = layout.pockets[k]
		var p: Vector2 = pk.pos
		var r: float = pk.r
		if pk.closed:
			# Brass cap over a closed pocket.
			c.draw_circle(p, r + 4, Color(0.55, 0.42, 0.18))
			c.draw_circle(p, r - 2, Color(0.35, 0.26, 0.1))
			c.draw_line(p + Vector2(-r * 0.5, -r * 0.5), p + Vector2(r * 0.5, r * 0.5), Color(0.2, 0.15, 0.05), 3)
			c.draw_line(p + Vector2(-r * 0.5, r * 0.5), p + Vector2(r * 0.5, -r * 0.5), Color(0.2, 0.15, 0.05), 3)
			continue
		var dir: Vector2 = pk.dir
		# Leather liner wrapped onto the rail.
		c.draw_circle(p - dir * 6.0, r + 13.0, Color(0.11, 0.07, 0.05))
		c.draw_circle(p - dir * 6.0, r + 9.0, Color(0.2, 0.13, 0.08))
		c.draw_arc(p - dir * 6.0, r + 11.0, 0, TAU, 40, Color(0.3, 0.2, 0.12, 0.6), 1.5)
		# Throat between the jaws, shading darker toward the hole.
		if pk.has("mouth"):
			var m: PackedVector2Array = pk.mouth
			c.draw_colored_polygon(m, Color(0.05, 0.05, 0.05))
			var inner := PackedVector2Array()
			for q in m:
				inner.append(q.lerp(p, 0.35))
			c.draw_colored_polygon(inner, Color(0.015, 0.015, 0.015))
			# Rubber facing on the jaws.
			c.draw_line(m[0], m[1], felt_color.darkened(0.3), 4.0)
			c.draw_line(m[3], m[2], felt_color.darkened(0.3), 4.0)
		c.draw_circle(p, r + 3.0, Color(0.02, 0.02, 0.02))
		c.draw_circle(p + dir * 3.0, r - 2.0, Color(0, 0, 0))
		# Net/inner rim hint.
		c.draw_arc(p + dir * 2.0, r - 4.0, 0, TAU, 40, Color(1, 1, 1, 0.04), 2.0)
		if k == hot_pocket:
			var pulse := 0.5 + 0.5 * sin(time * 5.0)
			var hc := Color(1.0, 0.55, 0.15)
			for i in 4:
				c.draw_arc(p, r + 6.0 + i * 3.0 + pulse * 3.0, 0, TAU, 40, Color(hc, 0.5 - i * 0.11), 2.5)
			var txt := "×%d" % hot_mult
			var fs := 18
			var w := font_bold.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var lp := p + dir * -46.0
			c.draw_string(font_bold, lp + Vector2(-w * 0.5, 6), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, hc)
		if clock_on and Catalog.CLOCK_ORDER.has(k):
			var order: int = Catalog.CLOCK_ORDER.find(k)
			var nxt: bool = order == clock_pos
			var cc := Color(1.0, 0.85, 0.4) if nxt else Color(0.75, 0.8, 0.9, 0.8)
			if nxt:
				var pulse3 := 0.5 + 0.5 * sin(time * 4.0)
				for i in 3:
					c.draw_arc(p, r + 6.0 + i * 3.0 + pulse3 * 3.0, 0, TAU, 40, Color(cc, 0.55 - i * 0.15), 2.5)
			var ct := str(order + 1) if not nxt else "%d · NEXT ×%s" % [order + 1, str(1.0 + 0.5 * (clock_streak + 1)).rstrip("0").rstrip(".")]
			var cw := font_bold.get_string_size(ct, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			c.draw_string(font_bold, p + dir * -50.0 + Vector2(-cw * 0.5, 6), ct, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, cc)
		if k == second_pocket:
			var pulse2 := 0.5 + 0.5 * sin(time * 5.0 + PI)
			for i in 3:
				c.draw_arc(p, r + 6.0 + i * 3.0 + pulse2 * 2.0, 0, TAU, 40, Color(0.4, 0.85, 1.0, 0.45 - i * 0.12), 2.0)
			var t2 := "scores"
			var w2 := font_bold.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			c.draw_string(font_bold, p + dir * -46.0 + Vector2(-w2 * 0.5, 5), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.9, 1.0))
		if pocket_pick and k == hover_pocket:
			c.draw_arc(p, r + 10.0, 0, TAU, 40, Color(1, 1, 1, 0.9), 3.0)
	# Spots.
	c.draw_circle(Rack.FOOT, 2.5, Color(1, 1, 1, 0.35))
	c.draw_circle(Rack.HEAD, 2.5, Color(1, 1, 1, 0.35))
	if head_only and placing:
		c.draw_line(Vector2(Rack.HEAD.x, 0), Vector2(Rack.HEAD.x, H), Color(1, 1, 1, 0.18), 2.0)
	_draw_board_fields(c)
	for bp in layout.bumpers:
		var p: Vector2 = bp.pos
		var r: float = bp.r
		if bp.has("shark") or bp.has("bob") or bp.has("fulcrum"):
			continue   # drawn by _draw_board_pieces / _draw_board_fields
		c.draw_circle(p + Vector2(3, 5), r + 2, Color(0, 0, 0, 0.3))
		c.draw_circle(p, r, Color(0.65, 0.5, 0.2))
		c.draw_circle(p, r - 4, Color(0.25, 0.85, 0.85))
		c.draw_circle(p, r - 9, Color(0.1, 0.3, 0.35))
		c.draw_circle(p + Vector2(-r * 0.3, -r * 0.35), r * 0.22, Color(1, 1, 1, 0.35))
	for k in layout.portals.size() * 2:
		var pt: Dictionary = layout.portals[k / 2]
		var pp: Vector2 = pt.a if k % 2 == 0 else pt.b
		var pc := Color(0.6, 0.4, 1.0) if k % 2 == 0 else Color(0.3, 0.85, 1.0)
		var pr := TableLayout.PORTAL_R
		c.draw_circle(pp, pr + 5.0, Color(pc, 0.22))
		c.draw_circle(pp, pr, Color(0.04, 0.03, 0.1))
		c.draw_arc(pp, pr, 0, TAU, 36, pc, 3.0, true)
		c.draw_arc(pp, pr * 0.55, 0, TAU, 24, Color(pc, 0.7), 2.0, true)


## ---------------------------------------------------------------- guideline
func _draw_overlay() -> void:
	var o := overlay
	_draw_board_pieces(o)
	if not spotlight.is_empty():
		var beat := 0.5 + 0.5 * sin(time * 5.0)
		for i in ball_nodes:
			var bn: BallNode = ball_nodes[i]
			if is_instance_valid(bn) and bn.visible and not bn.sinking and spotlight.has(bn.number):
				var r := bn.radius
				for k in 3:
					o.draw_arc(bn.position, r + 3.0 + k * 2.5 + beat * 2.0, 0, TAU, 40, Color(1.0, 0.9, 0.45, 0.5 - k * 0.14), 2.4, true)
				o.draw_arc(bn.position, r + 1.5, 0, TAU, 40, Color(1.0, 0.97, 0.8, 0.95), 1.6, true)
	if heat_level >= 3:
		# On fire: every pocket burns. Dead stroke: blue-white cores and the rim smoulders.
		for pk in layout.pockets:
			var pp: Vector2 = pk.pos
			var fh := 56.0 if heat_level >= 4 else 44.0
			FireFx.paint(o, Rect2(pp.x - 20.0, pp.y - fh + 4.0, 40.0, fh), heat_level, time + pp.x * 0.01, 3.0, 0.9)
		if heat_level >= 4:
			var glow := 0.25 + 0.12 * sin(time * 3.0)
			o.draw_rect(Rect2(-RAIL * 0.5, -RAIL * 0.5, W + RAIL, H + RAIL), Color(1.0, 0.45, 0.12, glow), false, 6.0)
	for path in forecast_paths:
		var pts: PackedVector2Array = path.points
		var col: Color = path.color
		var halo: Color = path.get("halo", Color(0, 0, 0))
		if pts.size() >= 2:
			# One continuous antialiased stroke, fading towards where the ball ends.
			var cols := PackedColorArray()
			var halos := PackedColorArray()
			for i in pts.size():
				var a := 1.0 - 0.55 * float(i) / float(pts.size() - 1)
				cols.append(Color(col, 0.9 * a))
				halos.append(Color(halo, 0.35 * a))
			o.draw_polyline_colors(pts, halos, 5.0, true)
			o.draw_polyline_colors(pts, cols, 2.4, true)
		if pts.size() > 0:
			var endp := pts[pts.size() - 1]
			if path.get("end", false):
				o.draw_arc(endp, R, 0, TAU, 24, Color(col, 0.85), 2.0)
			elif path.get("potted", false):
				o.draw_circle(endp, 5.0, Color(1.0, 0.85, 0.3, 0.9))
	if placing:
		var col := Color(1, 1, 1, 0.55) if place_ok else Color(1, 0.3, 0.3, 0.6)
		var prr := place_radius if place_radius > 0.0 else R
		o.draw_circle(place_pos, prr, Color(1, 1, 1, 0.25 if place_ok else 0.1))
		o.draw_arc(place_pos, prr, 0, TAU, 32, col, 2.0)
		o.draw_arc(place_pos, prr + 6 + sin(time * 6.0) * 2.0, 0, TAU, 32, Color(col, 0.35), 1.5)
		for h in place_hints:
			o.draw_line(h[0], h[1], Color(_pot_color(), 0.55), 2.0)
			o.draw_arc(h[0], R + 3.0, 0, TAU, 24, Color(_pot_color(), 0.8), 2.0)
	if call_ball >= 0 and ball_nodes.has(call_ball) and call_pocket >= 0 and call_pocket < layout.pockets.size():
		var cbp: Vector2 = ball_nodes[call_ball].position
		var cpp: Vector2 = layout.pockets[call_pocket].pos
		o.draw_arc(cbp, R + 5.0, 0, TAU, 32, Color(1.0, 0.85, 0.35), 2.5, true)
		_dashed(o, cbp, cpp, Color(1.0, 0.85, 0.35, 0.5), 1.5, 8.0)
		_txt(o, cpp + (Vector2(W, H) * 0.5 - cpp).normalized() * 46.0, "CALLED ×3", Color(1.0, 0.85, 0.35), 13)
	if ghost_ball >= 0 and ball_nodes.has(ghost_ball):
		var gp: Vector2 = ball_nodes[ghost_ball].position
		for k in 12:
			o.draw_arc(gp, R + 4.0, k * TAU / 12.0, k * TAU / 12.0 + 0.3, 4, Color(0.85, 0.9, 1.0, 0.85), 2.0, true)
	for pb in pebbles:
		for k in 3:
			o.draw_arc(pb, 14.0 + k * 12.0, 0, TAU, 32, Color(0.7, 0.6, 1.0, 0.5 - k * 0.12), 2.0, true)
		o.draw_circle(pb, 6.0, Color(0.55, 0.45, 1.0))
	for w in temp_walls:
		o.draw_line(w[0], w[1], Color(0.3, 0.9, 1.0, 0.35), 12.0, true)
		o.draw_line(w[0], w[1], Color(0.75, 0.97, 1.0), 5.0, true)
	if strike_line.size() == 2:
		_dashed(o, strike_line[0], strike_line[1], Color(1.0, 0.85, 0.4), 3.0, 10.0)
		_arrow(o, strike_line[0].lerp(strike_line[1], 0.9), strike_line[1], Color(1.0, 0.85, 0.4))
	if plan_hover != Vector2.INF:
		o.draw_arc(plan_hover, R + 5.0, 0, TAU, 32, Color(0.55, 0.95, 0.85, 0.7), 2.0, true)
	if plan_marker != Vector2.INF:
		o.draw_arc(plan_marker, R + 6.0 + sin(time * 5.0) * 1.5, 0, TAU, 32, Color(0.55, 0.95, 0.85), 3.0, true)
		_txt(o, plan_marker + Vector2(0, -R - 18.0), "PAUSE", Color(0.55, 0.95, 0.85), 13)
	if hold_text != "":
		var hw := font_bold.get_string_size(hold_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var hr := Rect2(Vector2(W * 0.5 - hw * 0.5 - 12, H - 44), Vector2(hw + 24, 32))
		o.draw_rect(hr, Color(0.03, 0.08, 0.08, 0.85), true)
		o.draw_rect(hr, Color(0.55, 0.95, 0.85), false, 2.0)
		_txt(o, hr.get_center(), hold_text, Color(0.75, 1.0, 0.92), 18)
	var stack := {}
	for tag in sink_tags:
		var k: int = tag[0]
		if k < 0 or k >= layout.pockets.size():
			continue
		var n: int = stack.get(k, 0)
		stack[k] = n + 1
		var pk: Dictionary = layout.pockets[k]
		var tp: Vector2 = (pk.pos as Vector2) - (pk.dir as Vector2) * (64.0 + 22.0 * n)
		var tw := font_bold.get_string_size(tag[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var tr := Rect2(tp + Vector2(-tw * 0.5 - 6, -11), Vector2(tw + 12, 20))
		o.draw_rect(tr, Color(0.04, 0.06, 0.1, 0.85), true)
		o.draw_rect(tr, Color(0.55, 0.85, 1.0, 0.8), false, 1.5)
		o.draw_string(font_bold, tp + Vector2(-tw * 0.5, 5), tag[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.75, 0.92, 1.0))
	if not show_guide or guide.is_empty():
		return
	if forecast_text != "":
		var ftw := font_bold.get_string_size(forecast_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		var fr := Rect2(Vector2(W * 0.5 - ftw * 0.5 - 12, 10), Vector2(ftw + 24, 34))
		o.draw_rect(fr, Color(0.05, 0.05, 0.08, 0.85), true)
		o.draw_rect(fr, Color(0.8, 0.7, 1.0, 0.9), false, 2.0)
		_txt(o, fr.get_center(), forecast_text, Color(0.92, 0.86, 1.0), 20)
	var glow := Color(1, 1, 1, 0.12)
	var line := Color(1, 1, 1, 0.92)
	var aim: PackedVector2Array = guide.aim
	var gaps: Array = guide.get("aim_gaps", [])
	for i in aim.size() - 1:
		if gaps.has(i):
			continue
		o.draw_line(aim[i], aim[i + 1], glow, 7.0)
		o.draw_line(aim[i], aim[i + 1], line, 2.0)
	if guide.has("scratch"):
		var sp: Vector2 = guide.scratch
		o.draw_arc(sp, R, 0, TAU, 32, Color(1, 0.3, 0.25), 2.5)
		_txt(o, sp + Vector2(0, -24), "SCRATCH", Color(1, 0.35, 0.3), 14)
	if guide.has("ghost"):
		var g: Vector2 = guide.ghost
		o.draw_circle(g, R, Color(1, 1, 1, 0.13))
		o.draw_arc(g, R, 0, TAU, 40, Color(1, 1, 1, 0.95), 2.0)
	if guide.has("obj"):
		var op: PackedVector2Array = guide.obj
		var pot: bool = guide.get("obj_pot", false)
		var edge: bool = guide.get("obj_edge", false)
		_draw_ball_line(o, op, guide.get("obj_number", 1), pot, edge, false)
	if guide.has("obj2"):
		var op2: PackedVector2Array = guide.obj2
		var pot2: bool = guide.get("obj2_pot", false)
		_draw_ball_line(o, op2, guide.get("obj2_number", 1), pot2, guide.get("obj2_edge", false), true)
	if guide.has("cue"):
		var cp: PackedVector2Array = guide.cue
		for i in cp.size() - 1:
			_dashed(o, cp[i], cp[i + 1], Color(0.55, 0.8, 1.0, 0.75), 1.6, 7.0)
	if preview_text != "" and preview_pocket >= 0:
		var pk: Dictionary = layout.pockets[preview_pocket]
		var p: Vector2 = pk.pos
		var dir: Vector2 = pk.dir
		# Sit the value tag out on the rail, beyond the pocket.
		var lp := p - dir * 34.0
		if pk.side:
			lp = p - dir * 26.0
		var fs := 17
		var w := font_bold.get_string_size(preview_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		lp.x = clampf(lp.x, -RAIL + w * 0.5, W + RAIL - w * 0.5)
		var rect := Rect2(lp + Vector2(-w * 0.5 - 8, -15), Vector2(w + 16, 24))
		o.draw_rect(rect, Color(0.05, 0.05, 0.08, 0.8), true)
		o.draw_rect(rect, Color(1.0, 0.82, 0.3, 0.8), false, 1.5)
		o.draw_string(font_bold, lp + Vector2(-w * 0.5, 4), preview_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.45, 0.4) if preview_text.begins_with("-") else Color(1.0, 0.9, 0.55))


## A struck ball's path, drawn in that ball's own colour. A pale casing keeps dark
## colours readable on any cloth; stripes get a white core. Pots are bold and end
## in a gold ring, rattles are dashed, so shape never depends on colour alone.
func _draw_ball_line(o: CanvasItem, pts: PackedVector2Array, n: int, pot: bool, edge: bool, combo: bool) -> void:
	var c := Catalog.ball_color(n)
	if colorblind:
		c = _edge_color() if edge else (_pot_color() if pot else Color(0.75, 0.95, 1.0))
	var w := 5.0 if pot else 3.0
	for i in pts.size() - 1:
		if edge or combo:
			_dashed(o, pts[i], pts[i + 1], Color(1, 1, 1, 0.7), w + 2.0, 12.0)
			_dashed(o, pts[i], pts[i + 1], c, w, 12.0)
		else:
			o.draw_line(pts[i], pts[i + 1], Color(1, 1, 1, 0.6), w + 2.5)
			o.draw_line(pts[i], pts[i + 1], c, w)
			if Catalog.is_stripe(n):
				o.draw_line(pts[i], pts[i + 1], Color(1, 1, 1, 0.9), 1.3)
	if pts.size() >= 2:
		var tip := pts[pts.size() - 1]
		_arrow(o, pts[pts.size() - 2], tip, _pot_color() if pot else c)
		if pot:
			o.draw_arc(tip, R + 7.0, 0, TAU, 32, _pot_color(), 3.5)


func _pot_color() -> Color:
	return Color(0.94, 0.89, 0.26) if colorblind else Color(1.0, 0.82, 0.3)


func _edge_color() -> Color:
	return Color(0.0, 0.62, 0.9) if colorblind else Color(1.0, 0.5, 0.2)


func _txt(n: CanvasItem, p: Vector2, s: String, c: Color, fs: int) -> void:
	var w := font_bold.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	n.draw_string(font_bold, p + Vector2(-w * 0.5, fs * 0.35), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)


func _arrow(n: CanvasItem, a: Vector2, b: Vector2, c: Color) -> void:
	var d := (b - a).normalized()
	if d == Vector2.ZERO:
		return
	var s := Vector2(-d.y, d.x)
	n.draw_colored_polygon(PackedVector2Array([b + d * 2.0, b - d * 10.0 + s * 5.5, b - d * 10.0 - s * 5.5]), c)


func _dashed(n: CanvasItem, a: Vector2, b: Vector2, c: Color, w: float, dash: float) -> void:
	var l := a.distance_to(b)
	if l < 0.5:
		return
	var d := (b - a) / l
	var t := 0.0
	while t < l:
		n.draw_line(a + d * t, a + d * minf(t + dash * 0.6, l), c, w)
		t += dash


## ---------------------------------------------------------------- cue stick
func _draw_cue() -> void:
	if not cue_visible:
		return
	var c := cue_layer
	var d := cue_dir.normalized()
	var s := Vector2(-d.y, d.x)
	var gap := R + 4.0 + cue_pull
	var tip := cue_pos - d * gap
	var length := 560.0
	var butt := tip - d * length
	var tip_w := 3.2
	var butt_w := 7.5
	# Shadow on the cloth.
	var so := Vector2(10, 16)
	c.draw_colored_polygon(PackedVector2Array([tip + so + s * tip_w, tip + so - s * tip_w, butt + so - s * butt_w, butt + so + s * butt_w]), Color(0, 0, 0, 0.22))
	var shaft: Color = cue_colors.get("shaft", Color(0.86, 0.72, 0.5))
	var buttc: Color = cue_colors.get("butt", Color(0.32, 0.14, 0.07))
	var accent: Color = cue_colors.get("accent", Color(0.82, 0.78, 0.7))
	var segs := [
		[0.0, 0.012, Color(0.25, 0.5, 0.85)],     # chalked tip
		[0.012, 0.035, Color(0.95, 0.93, 0.86)],  # ferrule
		[0.035, 0.58, shaft],                     # shaft
		[0.58, 0.6, accent],                      # joint ring
		[0.6, 0.78, buttc],                       # forearm
		[0.78, 0.93, Color(0.07, 0.07, 0.08)],    # wrap
		[0.93, 1.0, buttc],                       # butt sleeve
	]
	for sg in segs:
		var a := tip - d * length * float(sg[0])
		var b := tip - d * length * float(sg[1])
		var wa := lerpf(tip_w, butt_w, float(sg[0]))
		var wb := lerpf(tip_w, butt_w, float(sg[1]))
		c.draw_colored_polygon(PackedVector2Array([a + s * wa, a - s * wa, b - s * wb, b + s * wb]), sg[2])
	# Forearm points (inlay).
	for k in 4:
		var a := tip - d * length * 0.6
		var b := tip - d * length * (0.66 + k * 0.025)
		var w0 := lerpf(tip_w, butt_w, 0.6)
		c.draw_colored_polygon(PackedVector2Array([a + s * w0 * 0.9, a - s * w0 * 0.9, b]), Color(accent, 0.85) if k % 2 == 0 else Color(0.1, 0.35, 0.4, 0.9))
	# Specular stripe along the stick.
	c.draw_line(tip + s * tip_w * 0.4, butt + s * butt_w * 0.4, Color(1, 1, 1, 0.22), 1.4)


## ---------------------------------------------------------------- effects
func _draw_fx() -> void:
	var f := fx_layer
	if flash_t > 0.0:
		f.draw_rect(Rect2(-RAIL - CUSHION, -RAIL - CUSHION, W + 2 * (RAIL + CUSHION), H + 2 * (RAIL + CUSHION)), Color(flash_col, clampf(flash_t / 0.4, 0.0, 1.0)), true)
	if number_tags:
		for i in ball_nodes:
			var b: BallNode = ball_nodes[i]
			if b.visible and b.number != 0 and not b.sinking:
				f.draw_circle(b.position, 8.5, Color(0.98, 0.97, 0.92))
				_txt(f, b.position + Vector2(0, 0), str(b.number), Color(0.05, 0.05, 0.05), 12)
	_draw_coach(f)
	for r in rings:
		var t: float = 1.0 - r.life / r.max
		f.draw_arc(r.pos, r.r * (0.4 + t), 0, TAU, 40, Color(r.color, 1.0 - t), 3.0)
	for p in particles:
		var a: float = clampf(p.life / p.max, 0.0, 1.0)
		f.draw_circle(p.pos, p.size * a + 0.5, Color(p.color, a))
	for p in popups:
		var a: float = clampf(p.life / p.max * 2.0, 0.0, 1.0)
		var grow: float = 1.0 + maxf(0.0, (p.life / p.max) - 0.8) * 2.0
		var fs := int(p.size * grow)
		var w := font_bold.get_string_size(p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos: Vector2 = p.pos + Vector2(-w * 0.5, 0)
		f.draw_string_outline(font_bold, pos, p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0, 0, 0, a * 0.8))
		f.draw_string(font_bold, pos, p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(p.color, a))


## ---------------------------------------------------------------- guideline maths
## A pot is "clean" when parallel paths offset either side also reach the
## same pocket: borderline paths that could clip a jaw are shown as edges.
static func _clean_pot(sim: PoolSim, from: Vector2, d: Vector2, ignore: int, pocket: int) -> bool:
	var perp := Vector2(-d.y, d.x) * 1.6
	for off in [perp, -perp]:
		var h := sim.cast(from + off, d, ignore, 1400.0)
		if h.kind != "pocket" or h.hit != pocket:
			return false
	return true


## Builds the aiming guide from the static table: cue path (with up to two
## cushion reflections), ghost ball, object-ball line (and one combination
## follow-on), and the cue ball's curved post-contact path.
static func compute_guide(sim: PoolSim, aim: Vector2, follow: float, side: float, lens: bool) -> Dictionary:
	var g := {}
	var ci := sim.index_of(0)
	if ci < 0 or sim.alive[ci] == 0:
		return g
	var p := sim.pos[ci]
	var d := aim.normalized()
	var pts := PackedVector2Array([p])
	var bounces := 3 if lens else 2
	var hit := {}
	var gaps: Array = []
	var through_portal := false
	var bounce := 0
	for guard in 10:
		hit = sim.cast(p, d, ci, 3000.0, -1, not through_portal)
		pts.append(hit.point)
		if hit.kind == "portal":
			# Jump to the other end: no line is drawn across the gap.
			gaps.append(pts.size() - 1)
			p = sim.portal_exit(hit.hit, hit.point)
			pts.append(p)
			through_portal = true
			continue
		if hit.kind != "rail":
			break
		if bounce == bounces:
			break
		bounce += 1
		# Same response as PoolSim._resolve_wall for a unit-speed ball.
		var n: Vector2 = hit.normal
		var vn := d.dot(n)
		var v := d - n * vn * (1.0 + sim.rail_e)
		var t := Vector2(-n.y, n.x)
		v -= t * v.dot(t) * 0.04
		if side != 0.0 and bounce == 1:
			v += t * side * -vn * 0.32 * sim.side_power
		d = v.normalized()
		p = hit.point
	g["aim"] = pts
	g["aim_gaps"] = gaps
	g["first"] = hit.kind
	if hit.kind == "pocket":
		g["scratch"] = hit.point
		return g
	if hit.kind != "ball":
		return g
	var contact: Vector2 = hit.point
	var obj: int = hit.hit
	var n: Vector2 = hit.normal
	g["ghost"] = contact
	g["obj_index"] = obj
	g["obj_number"] = sim.num[obj]
	g["rails_before"] = pts.size() - 2
	# Object ball line.
	var op := PackedVector2Array([sim.pos[obj]])
	var od := n
	var oh := {}
	var obj_rails := 0
	var reach := 2 if lens else 1
	for b in reach + 1:
		oh = sim.cast(op[op.size() - 1], od, obj, 1400.0)
		op.append(oh.point)
		if oh.kind == "rail" and b < reach:
			# Identical cushion response to PoolSim._resolve_wall.
			var rn: Vector2 = oh.normal
			var v := od - rn * od.dot(rn) * (1.0 + sim.rail_e_of(obj))
			var rt := Vector2(-rn.y, rn.x)
			v -= rt * v.dot(rt) * 0.04
			od = v.normalized()
			obj_rails += 1
			continue
		break
	g["obj"] = op
	var pot_clean: bool = oh.kind == "pocket" and _clean_pot(sim, op[op.size() - 2], od, obj, oh.hit)
	g["obj_pot"] = pot_clean
	g["obj_edge"] = oh.kind == "pocket" and not pot_clean
	g["obj_pocket"] = oh.hit if pot_clean else -1
	g["obj_rails"] = obj_rails
	if oh.kind == "ball":
		# Combination: show where the second ball would go.
		var b2: int = oh.hit
		var n2: Vector2 = oh.normal
		var p2 := PackedVector2Array([sim.pos[b2]])
		var h2 := sim.cast(sim.pos[b2], n2, b2, 1400.0)
		p2.append(h2.point)
		g["obj2"] = p2
		var clean2: bool = h2.kind == "pocket" and _clean_pot(sim, sim.pos[b2], n2, b2, h2.hit)
		g["obj2_pot"] = clean2
		g["obj2_edge"] = h2.kind == "pocket" and not clean2
		g["obj2_pocket"] = h2.hit if clean2 else -1
		g["obj2_index"] = b2
		g["obj2_number"] = sim.num[b2]
	# Cue ball after contact: tangent line plus follow/draw curve.
	var e := sim.ball_e
	var vin := d * 1000.0
	# Impulse share for unequal masses (heavy cue, lead rack, featherweight).
	var mc := sim.mass[ci]
	var mo := sim.mass[obj]
	var vc := vin - n * vin.dot(n) * (1.0 + e) * mo / (mc + mo)
	var spin := d * follow * 1000.0 * 0.62 * sim.spin_power
	if sim.cue_damp < 1.0:
		vc *= sim.cue_damp
		spin *= sim.cue_damp
	var cp := PackedVector2Array([contact])
	var cpos := contact
	var max_len := 900.0 if lens else 150.0
	var travelled := 0.0
	var dt := 1.0 / 120.0
	for i in 160:
		var dv := spin * minf(1.0, dt * 7.0)
		vc += dv
		spin -= dv
		var sp := vc.length()
		if sp < 1.0:
			break
		var step_len := sp * dt
		# The struck ball moves away along the line of centres, so ignore it.
		var ch := sim.cast(cpos, vc / sp, ci, step_len, obj)
		cpos = ch.point
		cp.append(cpos)
		travelled += cpos.distance_to(cp[cp.size() - 2])
		if ch.kind != "none" or travelled >= max_len:
			if ch.kind == "pocket":
				g["scratch"] = cpos
			break
	g["cue"] = cp
	return g


func _draw_coach(o: CanvasItem) -> void:
	if coach_text == "":
		return
	var a := 0.75 + 0.25 * sin(time * 4.0)
	var fs := 18
	var lines := coach_text.split(String.chr(10))
	var wmax := 0.0
	for l in lines:
		wmax = maxf(wmax, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var h := lines.size() * 23.0 + 14.0
	var cp := coach_pos
	cp.x = clampf(cp.x, wmax * 0.5 + 10, W - wmax * 0.5 - 10)
	cp.y = clampf(cp.y, 10, H - h - 10)
	var rect := Rect2(cp + Vector2(-wmax * 0.5 - 10, 0), Vector2(wmax + 20, h))
	o.draw_rect(rect, Color(0.06, 0.16, 0.28, 0.96), true)
	o.draw_rect(rect, Color(0.5, 0.85, 1.0, a), false, 2.0)
	for i in lines.size():
		var lw := font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		o.draw_string(font, cp + Vector2(-lw * 0.5, 25 + i * 23), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, a))
