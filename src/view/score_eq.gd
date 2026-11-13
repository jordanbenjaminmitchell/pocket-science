class_name ScoreEq
extends Control
## The score for one sunk ball, built on screen a piece at a time: the ball's value,
## then each bonus flying in from where it came from (the ball, a Perk card, the
## Chain or Heat meter, the hot pocket), each with a slightly higher note, then the
## total. Three pieces in, the screen starts to shake; from five it crackles with
## electricity inside a glowing aura.

signal piece_added(count: int)
signal finished

const STEP := 0.255         # seconds between pieces
const FLY := 0.33           # seconds a piece takes to fly in
const HOLD := 1.125         # how long the finished sum stays up
const FADE := 0.5
const GAP := 10.0
const F_BIG := 26
const F_CAP := 12

var font: Font
var cap_font: Font
var sfx: Node
var pieces: Array = []      # {text, cap, col, from, to, born}
var queue: Array = []
var anchor := Vector2.ZERO
var bounds := Rect2()       # keep the sum inside this area (the table), if set
var t := 0.0
var next_at := 0.0
var done_at := -1.0
var count := 0
var playing := false
var bolts: Array = []
var bolt_t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process(false)


## How long a sum with these steps takes before it is finished (for the tally).
static func duration(steps: Array) -> float:
	return (_order(steps).size() + 1) * STEP + FLY + HOLD * 0.6


## Value pieces first, then Chain bonuses, then the multipliers (Chain, Heat, the rest).
static func _order(steps: Array) -> Array:
	var out: Array = []
	for op in ["=", "+", "+c", "×"]:
		for st in steps:
			if st.op == op:
				out.append(st)
	return out


## Starts a new sum. `sources` maps a step's src ("ball", "perk:solids", "chain",
## "heat", "hot", "table", "item") to where its piece flies from, in this node's space.
func play(steps: Array, points: int, at: Vector2, sources: Dictionary, instant := false) -> void:
	pieces.clear()
	queue.clear()
	bolts.clear()
	anchor = at
	t = 0.0
	next_at = 0.0
	done_at = -1.0
	count = 0
	playing = true
	modulate.a = 1.0
	for st in _order(steps):
		queue.append(_piece_for(st, sources))
	queue.append({"text": "= %d" % points, "cap": "", "col": Color(1.0, 0.86, 0.35), "from": at, "final": true})
	if instant:
		while not queue.is_empty():
			_add(queue.pop_front(), true)
		done_at = 0.0
	set_process(true)
	queue_redraw()


func _piece_for(st: Dictionary, sources: Dictionary) -> Dictionary:
	var v: float = st.v
	var txt := ""
	var col := Color.WHITE
	match st.op:
		"=":
			txt = _num(v)
			col = Color(0.95, 0.95, 0.9)
		"+":
			txt = ("+" if v >= 0.0 else "−") + _num(absf(v))
			col = Color(0.45, 0.9, 1.0)
		"+c":
			txt = "+" + _num(v)
			col = Color(0.35, 1.0, 0.75)
		"×":
			txt = "×" + _num(v)
			col = Color(1.0, 0.55, 0.35) if st.src != "chain" and st.src != "heat" else (Color(0.35, 1.0, 0.75) if st.src == "chain" else Color(1.0, 0.6, 0.2))
	var cap: String = st.label
	if st.op == "+c":
		cap += " → Chain"
	var from: Vector2 = sources.get(st.src, sources.get("ball", anchor))
	return {"text": txt, "cap": cap, "col": col, "from": from}


static func _num(v: float) -> String:
	if absf(v - roundf(v)) < 0.01:
		return str(int(roundf(v)))
	return ("%.2f" % v).rstrip("0").rstrip(".")


func _add(pc: Dictionary, instant := false) -> void:
	pc["born"] = t - (FLY if instant else 0.0)
	pieces.append(pc)
	_layout()
	if instant:
		return
	count += 1
	if sfx:
		var final: bool = pc.get("final", false)
		var mult: bool = (pc.text as String).begins_with("×")
		sfx.play("score" if final else ("mult" if mult else "tick"), 0.75 if final else 0.6, pow(1.06, count - 1))
	piece_added.emit(count)


## Lays the pieces out in a row (two if long), centred on the anchor and kept on screen.
func _layout() -> void:
	var widths: Array = []
	var total := 0.0
	for pc in pieces:
		var w := maxf(font.get_string_size(pc.text, HORIZONTAL_ALIGNMENT_LEFT, -1, F_BIG + (8 if pc.get("final", false) else 0)).x, cap_font.get_string_size(pc.cap, HORIZONTAL_ALIGNMENT_LEFT, -1, F_CAP).x)
		widths.append(w)
		total += w + GAP
	var row_w := minf(total, 760.0)
	var x := anchor.x - row_w * 0.5
	var y := anchor.y
	var area := bounds if bounds.has_area() else Rect2(Vector2.ZERO, get_viewport_rect().size)
	x = clampf(x, area.position.x + 16.0, maxf(area.position.x + 16.0, area.end.x - row_w - 16.0))
	y = clampf(y, area.position.y + F_BIG + 20.0, maxf(area.position.y + F_BIG + 20.0, area.end.y - F_CAP - 40.0))
	var start_x := x
	for i in pieces.size():
		if x + widths[i] > start_x + 760.0:
			x = start_x
			y += F_BIG + F_CAP + 14.0
		pieces[i]["to"] = Vector2(x, y)
		pieces[i]["w"] = widths[i]
		x += widths[i] + GAP


func _process(delta: float) -> void:
	t += delta
	if playing and done_at < 0.0 and t >= next_at and not queue.is_empty():
		_add(queue.pop_front())
		next_at = t + STEP
		if queue.is_empty():
			done_at = t
	if done_at >= 0.0 and t > done_at + FLY + HOLD:
		modulate.a = clampf(1.0 - (t - done_at - FLY - HOLD) / FADE, 0.0, 1.0)
		if modulate.a <= 0.0:
			playing = false
			set_process(false)
			pieces.clear()
			finished.emit()
	bolt_t -= delta
	if count >= 5 and bolt_t <= 0.0:
		bolt_t = 0.05
		_new_bolts()
	queue_redraw()


## Fast-forward: show the whole sum at once.
func finish_now() -> void:
	while not queue.is_empty():
		_add(queue.pop_front(), true)
	if done_at < 0.0:
		done_at = t


func _panel_rect() -> Rect2:
	var r := Rect2()
	var first := true
	for pc in pieces:
		var p: Vector2 = pc.get("to", anchor)
		var box := Rect2(p - Vector2(0, F_BIG), Vector2(pc.get("w", 20.0), F_BIG + F_CAP + 10.0))
		r = box if first else r.merge(box)
		first = false
	return r.grow(14.0)


func _new_bolts() -> void:
	bolts.clear()
	if Fx.minimal_particles:
		return
	var r := _panel_rect()
	for k in 5:
		var side := randi() % 4
		var p := Vector2(randf_range(r.position.x, r.end.x), r.position.y if side == 0 else r.end.y) if side < 2 else Vector2(r.position.x if side == 2 else r.end.x, randf_range(r.position.y, r.end.y))
		var dir := (p - r.get_center()).normalized()
		var pts := PackedVector2Array([p])
		for s in 4:
			p += dir * randf_range(8, 16) + dir.orthogonal() * randf_range(-9, 9)
			pts.append(p)
		bolts.append(pts)


func _draw() -> void:
	if pieces.is_empty():
		return
	var r := _panel_rect()
	var heat := clampf((count - 2) / 4.0, 0.0, 1.0)
	# Aura: grows with the number of pieces; cyan to violet once it is crackling.
	if count >= 3:
		var pulse := 0.5 + 0.5 * sin(t * 9.0)
		var aura := Color(0.35, 0.85, 1.0).lerp(Color(0.8, 0.4, 1.0), heat)
		for k in 4:
			draw_rect(r.grow(4.0 + k * 5.0 + pulse * 3.0 * heat), Color(aura, (0.16 - k * 0.035) * (0.4 + heat)), false, 3.0)
	draw_rect(r, Color(0.04, 0.05, 0.08, 0.82), true)
	draw_rect(r, Color(1, 1, 1, 0.12 + 0.3 * heat), false, 1.5)
	for b in bolts:
		draw_polyline(b, Color(0.75, 0.95, 1.0, 0.9), 2.0, true)
		draw_polyline(b, Color(1, 1, 1, 0.9), 0.8, true)
	for pc in pieces:
		var a := clampf((t - float(pc.born)) / FLY, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - a, 3.0)
		var to: Vector2 = pc.get("to", anchor)
		var p: Vector2 = (pc.from as Vector2).lerp(to, e)
		var final: bool = pc.get("final", false)
		var fs := F_BIG + (8 if final else 0)
		var pop := 1.0 + (1.0 - a) * (0.6 if final else 0.3)
		var jitter := Vector2.ZERO
		if count >= 5 and not Fx.minimal_particles:
			jitter = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 1.2
		draw_set_transform(p + jitter + Vector2(pc.get("w", 0.0) * 0.5, -fs * 0.35), 0.0, Vector2.ONE * pop)
		var tw := font.get_string_size(pc.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string_outline(font, Vector2(-tw * 0.5, fs * 0.35), pc.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, 0.85 * a))
		draw_string(font, Vector2(-tw * 0.5, fs * 0.35), pc.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(pc.col, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if pc.cap != "" and a >= 1.0:
			var cw := cap_font.get_string_size(pc.cap, HORIZONTAL_ALIGNMENT_LEFT, -1, F_CAP).x
			draw_string(cap_font, to + Vector2((pc.get("w", 0.0) - cw) * 0.5, F_CAP + 6.0), pc.cap, HORIZONTAL_ALIGNMENT_LEFT, -1, F_CAP, Color(0.75, 0.8, 0.88))
