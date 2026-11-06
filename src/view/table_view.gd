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
var hot_pocket := -1
var hot_mult := 2
var preview_text := ""
var preview_pocket := -1
var cue_visible := false
var cue_colors: Dictionary = {}
var cue_pos := Vector2.ZERO
var cue_dir := Vector2.RIGHT
var cue_pull := 0.0
var placing := false
var place_pos := Vector2.ZERO
var place_ok := true
var head_only := false
var time := 0.0
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


func set_felt(c: Color) -> void:
	felt_color = c
	felt_mat.set_shader_parameter("felt", c)
	queue_redraw()
	if cushions:
		cushions.queue_redraw()


## ---------------------------------------------------------------- balls
func sync_balls(sim: PoolSim, rng: RandomNumberGenerator, isotopes: Dictionary) -> void:
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
	refresh_glows(sim, isotopes)


func refresh_glows(sim: PoolSim, isotopes: Dictionary) -> void:
	for i in ball_nodes:
		var n: int = sim.num[i]
		var iso: String = isotopes.get(n, "")
		if iso != "":
			var c: Color = Catalog.ISOTOPES[iso].color
			c.a = 0.95
			ball_nodes[i].set_glow(c)
		else:
			ball_nodes[i].set_glow(Color(0, 0, 0, 0))


func update_balls(sim: PoolSim) -> void:
	for i in ball_nodes:
		var b: BallNode = ball_nodes[i]
		if b.sinking:
			continue
		if sim.alive[i] == 1:
			if not b.visible:
				b.visible = true
				b.set_fade(1.0)
			if b.position != sim.pos[i]:
				b.roll_to(sim.pos[i])
		elif b.visible:
			b.visible = false


## Animate a ball dropping into pocket k.
func sink(i: int, k: int) -> void:
	var b: BallNode = ball_nodes.get(i)
	if b == null:
		return
	b.sinking = true
	var target: Vector2 = layout.pockets[k].pos
	var tw := create_tween()
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
	for r in rings:
		r.life -= delta
	rings = rings.filter(func(r): return r.life > 0.0)
	cushions.queue_redraw()
	overlay.queue_redraw()
	cue_layer.queue_redraw()
	fx_layer.queue_redraw()


func add_shake(a: float) -> void:
	shake = minf(10.0, shake + a)


func burst(p: Vector2, c: Color, n: int = 18, speed: float = 220.0) -> void:
	for i in n:
		var a := randf() * TAU
		var s := randf_range(0.3, 1.0) * speed
		particles.append({"pos": p, "vel": Vector2(cos(a), sin(a)) * s, "life": randf_range(0.35, 0.8), "max": 0.8, "color": c, "size": randf_range(1.5, 4.0)})


func trail(p: Vector2, c: Color, heat: float) -> void:
	for i in int(1 + heat * 2):
		var a := randf() * TAU
		particles.append({"pos": p + Vector2(cos(a), sin(a)) * randf_range(0, R * 0.6), "vel": Vector2(cos(a), sin(a)) * 20.0, "life": 0.35 + heat * 0.25, "max": 0.6, "color": c, "size": 2.5 + heat * 3.0})


## Celebration: coloured paper falling across the table.
func confetti() -> void:
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
	var wood := Color(0.30, 0.15, 0.07)
	draw_rect(outer, wood.darkened(0.35), true)
	draw_rect(outer.grow(-3), wood, true)
	draw_rect(outer.grow(-8), wood.lightened(0.06), true)
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
	# Highlight lip on the inner edge of the wood.
	var inner := Rect2(-CUSHION, -CUSHION, W + 2 * CUSHION, H + 2 * CUSHION)
	draw_rect(inner.grow(6), Color(0.45, 0.25, 0.12), false, 3.0)
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
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.7, 0), p + Vector2(0, s), p + Vector2(-s * 0.7, 0)]), Color(0.92, 0.9, 0.82))
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.7, 0), p + Vector2(0, 0)]), Color(1, 1, 1, 0.5))


func _draw_cushions() -> void:
	var c := cushions
	# Cushion nose shading: a light lip right at the playfield edge.
	var lip := felt_color.lightened(0.18)
	var dark := felt_color.darkened(0.55)
	for seg in layout.segments:
		var a: Vector2 = seg.a
		var b: Vector2 = seg.b
		var n: Vector2 = seg.n
		var is_rail := absf(n.x) < 0.01 or absf(n.y) < 0.01
		if is_rail and (a.x == b.x or a.y == b.y):
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
		c.draw_circle(p, r + 3.0, Color(0.02, 0.02, 0.02))
		c.draw_circle(p + dir * 3.0, r - 2.0, Color(0, 0, 0))
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
		if pocket_pick and k == hover_pocket:
			c.draw_arc(p, r + 10.0, 0, TAU, 40, Color(1, 1, 1, 0.9), 3.0)
	# Spots.
	c.draw_circle(Rack.FOOT, 2.5, Color(1, 1, 1, 0.35))
	c.draw_circle(Rack.HEAD, 2.5, Color(1, 1, 1, 0.35))
	if head_only and placing:
		c.draw_line(Vector2(Rack.HEAD.x, 0), Vector2(Rack.HEAD.x, H), Color(1, 1, 1, 0.18), 2.0)
	for bp in layout.bumpers:
		var p: Vector2 = bp.pos
		var r: float = bp.r
		c.draw_circle(p + Vector2(3, 5), r + 2, Color(0, 0, 0, 0.3))
		c.draw_circle(p, r, Color(0.65, 0.5, 0.2))
		c.draw_circle(p, r - 4, Color(0.25, 0.85, 0.85))
		c.draw_circle(p, r - 9, Color(0.1, 0.3, 0.35))
		c.draw_circle(p + Vector2(-r * 0.3, -r * 0.35), r * 0.22, Color(1, 1, 1, 0.35))


## ---------------------------------------------------------------- guideline
func _draw_overlay() -> void:
	var o := overlay
	for path in forecast_paths:
		var pts: PackedVector2Array = path.points
		var col: Color = path.color
		for i in range(0, pts.size(), 3):
			var a := 1.0 - float(i) / maxf(1.0, pts.size())
			o.draw_circle(pts[i], 1.8, Color(col, 0.25 + 0.55 * a))
		if pts.size() > 0 and path.get("end", false):
			o.draw_arc(pts[pts.size() - 1], R, 0, TAU, 24, Color(col, 0.7), 1.5)
	if placing:
		var col := Color(1, 1, 1, 0.55) if place_ok else Color(1, 0.3, 0.3, 0.6)
		o.draw_circle(place_pos, R, Color(1, 1, 1, 0.25 if place_ok else 0.1))
		o.draw_arc(place_pos, R, 0, TAU, 32, col, 2.0)
		o.draw_arc(place_pos, R + 6 + sin(time * 6.0) * 2.0, 0, TAU, 32, Color(col, 0.35), 1.5)
	if not show_guide or guide.is_empty():
		return
	var glow := Color(1, 1, 1, 0.12)
	var line := Color(1, 1, 1, 0.92)
	var aim: PackedVector2Array = guide.aim
	for i in aim.size() - 1:
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
		var oc := Color(1.0, 0.82, 0.3) if pot else Color(0.75, 0.95, 1.0)
		for i in op.size() - 1:
			o.draw_line(op[i], op[i + 1], Color(oc, 0.18), 8.0)
			o.draw_line(op[i], op[i + 1], oc, 2.5)
		if op.size() >= 2:
			_arrow(o, op[op.size() - 2], op[op.size() - 1], oc)
	if guide.has("obj2"):
		var op2: PackedVector2Array = guide.obj2
		var pot2: bool = guide.get("obj2_pot", false)
		var oc2 := Color(1.0, 0.82, 0.3) if pot2 else Color(0.75, 0.95, 1.0, 0.7)
		for i in op2.size() - 1:
			_dashed(o, op2[i], op2[i + 1], oc2, 2.0, 9.0)
		if op2.size() >= 2:
			_arrow(o, op2[op2.size() - 2], op2[op2.size() - 1], oc2)
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
		o.draw_string(font_bold, lp + Vector2(-w * 0.5, 4), preview_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.9, 0.55))


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
## Builds the aiming guide from the static table: cue path (with up to two
## cushion reflections), ghost ball, object-ball line (and one combination
## follow-on), and the cue ball's curved post-contact path.
static func compute_guide(sim: PoolSim, aim: Vector2, follow: float, side: float, lens: bool, fog: bool) -> Dictionary:
	var g := {}
	var ci := sim.index_of(0)
	if ci < 0 or sim.alive[ci] == 0:
		return g
	var p := sim.pos[ci]
	var d := aim.normalized()
	var pts := PackedVector2Array([p])
	var bounces := 3 if lens else 2
	var hit := {}
	for b in bounces + 1:
		hit = sim.cast(p, d, ci)
		pts.append(hit.point)
		if hit.kind != "rail":
			break
		if b == bounces:
			break
		# Same response as PoolSim._resolve_wall for a unit-speed ball.
		var n: Vector2 = hit.normal
		var vn := d.dot(n)
		var v := d - n * vn * (1.0 + sim.rail_e)
		var t := Vector2(-n.y, n.x)
		v -= t * v.dot(t) * 0.04
		if side != 0.0 and b == 0:
			v += t * side * -vn * 0.32
		d = v.normalized()
		p = hit.point
	g["aim"] = pts
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
	g["rails_before"] = pts.size() - 2
	if fog:
		return g
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
			var rn: Vector2 = oh.normal
			var v := od - rn * od.dot(rn) * (1.0 + sim.rail_e)
			od = v.normalized()
			obj_rails += 1
			continue
		break
	g["obj"] = op
	g["obj_pot"] = oh.kind == "pocket"
	g["obj_pocket"] = oh.hit if oh.kind == "pocket" else -1
	g["obj_rails"] = obj_rails
	if oh.kind == "ball":
		# Combination: show where the second ball would go.
		var b2: int = oh.hit
		var n2: Vector2 = oh.normal
		var p2 := PackedVector2Array([sim.pos[b2]])
		var h2 := sim.cast(sim.pos[b2], n2, b2, 1400.0)
		p2.append(h2.point)
		g["obj2"] = p2
		g["obj2_pot"] = h2.kind == "pocket"
		g["obj2_pocket"] = h2.hit if h2.kind == "pocket" else -1
		g["obj2_index"] = b2
	# Cue ball after contact: tangent line plus follow/draw curve.
	var e := sim.ball_e
	var vin := d * 1000.0
	var vc := vin - n * vin.dot(n) * (1.0 + e) * 0.5
	var spin := d * follow * 1000.0 * 0.62
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
