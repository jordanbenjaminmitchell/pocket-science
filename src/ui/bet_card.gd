class_name BetCard
extends Control
## A side bet drawn as a playing card (portrait, ivory face), unlike the dark
## periodic tiles of the Pro Shop. The face shows everything about the bet:
##   top left    what it wins as a multiple of the stake, and one to three pips for the tier
##   top middle  SIDE BET and the tier (Easy, Medium, Hard)
##   top right   the chip slot: empty until you bet, then a chip with your stake
##   picture     the bet's picture (the b_<id> lettering recipes in TileArt)
##   text        the full wording, with this table's real numbers worked out
##   bottom      the stake and what the bet pays back, in dollars
## The back (face down) shows the stake and the most the bet could pay.
## Nothing is upside down and nothing ever covers the wording.
##
##   BetCard.new().setup("quarter", "open", {"stake": 8, "reward": 24, "target": 215})
##   BetCard.from_run(run)   # everything read from the RunState

const SIZE := Vector2(180, 252)
const F_SEMI: Font = TileArt.F_SEMI
const F_REG: Font = TileArt.F_REG
const PAPER := Color(0.975, 0.955, 0.9)
const PAPER_LOW := Color(0.93, 0.89, 0.8)
const INK := Color(0.13, 0.11, 0.1)
const INK_SOFT := Color(0.38, 0.34, 0.3)
const EDGE := Color(0.06, 0.06, 0.07)
const GOLD := Color(1.0, 0.82, 0.32)
const WINDOW := Rect2(11, 52, 158, 84)
const PICTURE_ZOOM := 1.3

var id := ""
var state := "open"    # back, open, taken, won, passed
var info := {}         # stake, reward, max_reward, target (all optional)
var tint := Color.WHITE
var face_up := true


## The card for the run's current side bet, in its current state, with this
## table's stake, payout and target. Face down until the bet is known.
static func from_run(run) -> BetCard:
	var known: bool = run.bet_peeked or run.bet_state == "taken" or run.bet_state == "won" or (run.bet_state == "passed" and run.shots_taken > 0)
	var st: String = {"taken": "taken", "won": "won", "passed": "passed"}.get(run.bet_state, "open")
	var stake: int = run.bet_stake()
	var top := stake + int(round(stake * (3.0 + 0.5 * mini(int(run.table_index / 3), 2))))
	var card := BetCard.new()
	card.setup(run.bounty, st, {"stake": stake, "reward": run.bounty_reward(), "max_reward": top, "target": run.target()}, known)
	return card


## The bet's full wording. Bets that depend on the table say the real number:
## with a target of 215, "quarter" reads "Score 54 points in one shot".
static func bet_text(bet: String, target := 0) -> String:
	if target > 0:
		match bet:
			"quarter": return "Score %d points in one shot" % ceili(target * 0.25)
			"half": return "Score %d points in one shot" % ceili(target * 0.5)
	return Catalog.BOUNTIES[bet].name


## The smaller line under the wording: where a worked-out number comes from.
static func bet_note(bet: String, target := 0) -> String:
	if target > 0:
		match bet:
			"quarter": return "A quarter of the %d target" % target
			"half": return "Half of the %d target" % target
	return ""


func setup(bet: String, st := "open", details := {}, known := true) -> BetCard:
	id = bet
	state = st
	info = details
	face_up = known and st != "back"
	tint = TileArt.BET_COLORS[int(Catalog.BOUNTIES[bet].tier)] if face_up else TileArt.BET_BACK
	custom_minimum_size = SIZE
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if face_up:
		# The picture, in a window of its own so nothing spills onto the wording.
		var clip := Control.new()
		clip.position = WINDOW.position + Vector2(2, 2)
		clip.size = WINDOW.size - Vector2(4, 4)
		clip.clip_contents = true
		clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(clip)
		var host := Control.new()
		host.size = TileArt.SIZE
		host.scale = Vector2(PICTURE_ZOOM, PICTURE_ZOOM)
		host.position = clip.size * 0.5 - Vector2(TileArt.SIZE.x * 0.5, 58.0) * PICTURE_ZOOM
		host.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip.add_child(host)
		host.add_child(TileArt.Lettering.new("", "b_" + bet, tint, 46, 74.0, TileArt.PAPER))
	add_child(Shine.new(self))
	if state == "passed":
		modulate = Color(0.62, 0.62, 0.66, 0.9)
	return self


# --- Numbers -------------------------------------------------------------------------

func _stake() -> int:
	return int(info.get("stake", 0))


func _reward() -> int:
	return int(info.get("reward", 0))


## What the bet wins as a multiple of the stake: "2×", "2.5×".
func _multiple() -> String:
	var m := 1.0 + int(Catalog.BOUNTIES[id].tier)
	if _stake() > 0 and _reward() > 0:
		m = float(_reward() - _stake()) / _stake()
	return ("%d×" % int(m)) if is_equal_approx(m, roundf(m)) else ("%.1f×" % m)


func _ink_tier() -> Color:
	var c := tint.darkened(0.52)
	c.s = minf(1.0, c.s * 1.25)
	return c


func _frame_col() -> Color:
	return GOLD if state == "won" else tint


# --- Drawing helpers -----------------------------------------------------------------

func _text(f: Font, txt: String, pos: Vector2, fs: int, col: Color, align := 0, spacing := 0.0) -> float:
	var w := 0.0
	for ch in txt:
		w += f.get_char_size(ch.unicode_at(0), fs).x + spacing
	w -= spacing
	var x := pos.x - (w * 0.5 if align == 0 else (w if align > 0 else 0.0))
	if spacing == 0.0:
		draw_string(f, Vector2(x, pos.y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	else:
		for ch in txt:
			draw_char(f, Vector2(x, pos.y), ch, fs, col)
			x += f.get_char_size(ch.unicode_at(0), fs).x + spacing
	return w


func _rr(r: Rect2, radius: int, col: Color, border := 0, border_col := Color.TRANSPARENT) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing_size = 0.6
	if border > 0:
		sb.set_border_width_all(border)
		sb.border_color = border_col
	draw_style_box(sb, r)


func _diamond(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.72, 0), c + Vector2(0, r), c + Vector2(-r * 0.72, 0)]), col)


## Fine engraved waves, as on a banknote.
func _guilloche(r: Rect2, col: Color, rows: int) -> void:
	for i in rows:
		var pts := PackedVector2Array()
		var y0 := lerpf(r.position.y, r.end.y, (i + 0.5) / rows)
		var x := r.position.x
		while x <= r.end.x:
			pts.append(Vector2(x, y0 + sin(x * 0.11 + i * 0.9) * 5.0 + sin(x * 0.047 - i * 0.5) * 4.0))
			x += 3.0
		draw_polyline(pts, col, 0.7, true)


func _rosette(c: Vector2, r: float, col: Color) -> void:
	for k in 4:
		var pts := PackedVector2Array()
		for j in 73:
			var a := TAU * j / 72.0
			pts.append(c + Vector2.from_angle(a) * (r + r * 0.28 * sin(a * 8.0 + k * PI * 0.25)))
		draw_polyline(pts, col, 0.7, true)
	draw_arc(c, r * 0.55, 0, TAU, 32, col, 0.7, true)


## Little corner brackets around a rectangle.
func _brackets(r: Rect2, l: float, col: Color, w: float) -> void:
	for sx in [0, 1]:
		for sy in [0, 1]:
			var p := Vector2(r.position.x + r.size.x * sx, r.position.y + r.size.y * sy)
			var dx := l if sx == 0 else -l
			var dy := l if sy == 0 else -l
			draw_polyline(PackedVector2Array([p + Vector2(dx, 0), p, p + Vector2(0, dy)]), col, w, true)


## The chip slot: a dashed ring until you bet, then a chip carrying the stake.
func _chip_slot(c: Vector2, r: float, placed: bool, on_dark: bool) -> void:
	if not placed:
		var col := Color(1, 1, 1, 0.4) if on_dark else Color(INK_SOFT, 0.55)
		for i in 14:
			var a := TAU * i / 14.0
			draw_arc(c, r - 1.5, a, a + TAU / 28.0, 4, col, 1.2, true)
		return
	var chip := GOLD if state == "won" else Color(0.86, 0.2, 0.22)
	draw_circle(c + Vector2(0, 1.5), r, Color(0, 0, 0, 0.28), true, -1.0, true)
	draw_circle(c, r, chip, true, -1.0, true)
	for i in 8:
		var a := TAU * i / 8.0 + 0.2
		draw_arc(c, r - 1.7, a - 0.16, a + 0.16, 5, Color(1, 1, 1, 0.92), 3.2, true)
	draw_circle(c, r * 0.66, chip.darkened(0.22), true, -1.0, true)
	draw_arc(c, r * 0.66, 0, TAU, 28, Color(1, 1, 1, 0.75), 1.0, true)
	var label := "$%d" % _stake() if _stake() > 0 else "BET"
	var fs := 11 if label.length() <= 3 else 10
	_text(F_SEMI, label, c + Vector2(0, fs * 0.36), fs, Color(0.1, 0.07, 0.03) if state == "won" else Color.WHITE)


## One labelled figure in the bottom row.
func _figure(cx: float, label: String, value: String, label_col: Color, value_col: Color) -> void:
	_text(F_SEMI, label, Vector2(cx, 219), 10, label_col, 0, 1.0)
	_text(F_SEMI, value, Vector2(cx, 240), 19 if value.length() <= 5 else 15, value_col)


func _frame() -> void:
	var f := _frame_col()
	_rr(Rect2(Vector2.ZERO, SIZE), 12, EDGE)
	_rr(Rect2(1.5, 1.5, SIZE.x - 3, SIZE.y - 3), 11, f.darkened(0.35), 0)
	_rr(Rect2(2.5, 2.5, SIZE.x - 5, SIZE.y - 5), 10, f)
	# A lighter top edge and darker bottom edge make the frame read as foil.
	draw_line(Vector2(14, 3.2), Vector2(SIZE.x - 14, 3.2), Color(1, 1, 1, 0.55), 1.0, true)
	draw_line(Vector2(14, SIZE.y - 3.2), Vector2(SIZE.x - 14, SIZE.y - 3.2), Color(0, 0, 0, 0.25), 1.0, true)


func _draw() -> void:
	_frame()
	if face_up:
		_draw_face()
	else:
		_draw_back()


func _draw_face() -> void:
	var w := SIZE.x
	var tier := int(Catalog.BOUNTIES[id].tier)
	var ink := _ink_tier()
	# Paper, a shade warmer towards the bottom, with engraving behind the lower half.
	_rr(Rect2(5.5, 5.5, w - 11, SIZE.y - 11), 8, PAPER)
	draw_polygon(PackedVector2Array([Vector2(6, 120), Vector2(w - 6, 120), Vector2(w - 6, SIZE.y - 13), Vector2(6, SIZE.y - 13)]),
		PackedColorArray([Color(PAPER_LOW, 0.0), Color(PAPER_LOW, 0.0), PAPER_LOW, PAPER_LOW]))
	_rr(Rect2(6, SIZE.y - 14, w - 12, 8.5), 0, PAPER_LOW)
	_rr(Rect2(5.5, SIZE.y - 22, w - 11, 16.5), 8, PAPER_LOW)
	_guilloche(Rect2(9, 144, w - 18, 96), Color(ink, 0.1), 9)
	_rosette(Vector2(w * 0.5, 228), 11, Color(ink, 0.22))
	_rr(Rect2(8, 8, w - 16, SIZE.y - 16), 6, Color.TRANSPARENT, 1, Color(ink, 0.35))

	# Top left: the payout multiple and the tier pips. Top middle: kind and tier.
	_text(F_SEMI, _multiple(), Vector2(14, 33), 26 if _multiple().length() <= 2 else 20, ink, -1)
	for i in tier + 1:
		_diamond(Vector2(18 + i * 9, 41.5), 3.6, ink)
	_text(F_SEMI, "SIDE BET", Vector2(w * 0.5 + 8, 24), 11, INK_SOFT, 0, 1.6)
	_text(F_SEMI, String(Catalog.BET_TIERS[tier]).to_upper(), Vector2(w * 0.5 + 8, 40), 13, ink, 0, 1.2)
	_chip_slot(Vector2(w - 26, 28), 14, state == "taken" or state == "won", false)

	# The picture window: a dark panel in the tier's colour, framed in foil.
	var win_bg := tint.darkened(0.82).lerp(tint, 0.07)
	_rr(WINDOW, 6, win_bg, 2, _frame_col().darkened(0.1))
	_rr(WINDOW.grow(-3), 4, Color.TRANSPARENT, 1, Color(1, 1, 1, 0.14))
	_brackets(WINDOW.grow(2.5), 7, Color(ink, 0.7), 1.0)

	# The full wording, centred in its own space; a note under it when a number was worked out.
	var txt := bet_text(id, int(info.get("target", 0)))
	var note := bet_note(id, int(info.get("target", 0)))
	var tw := w - 28.0
	var fs := 14
	while fs > 11 and F_SEMI.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, tw, fs).y > (52.0 if note == "" else 36.0):
		fs -= 1
	var th := F_SEMI.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, tw, fs).y
	var nh := 0.0 if note == "" else F_REG.get_multiline_string_size(note, HORIZONTAL_ALIGNMENT_CENTER, tw, 11).y + 2.0
	var y := 172.0 - (th + nh) * 0.5
	draw_multiline_string(F_SEMI, Vector2(14, y + F_SEMI.get_ascent(fs)), txt, HORIZONTAL_ALIGNMENT_CENTER, tw, fs, -1, INK)
	if note != "":
		draw_multiline_string(F_REG, Vector2(14, y + th + 2.0 + F_REG.get_ascent(11)), note, HORIZONTAL_ALIGNMENT_CENTER, tw, 11, -1, INK_SOFT)

	# Divider, then the stake and what the bet pays back.
	draw_line(Vector2(16, 204), Vector2(w * 0.5 - 9, 204), Color(ink, 0.45), 1.0, true)
	draw_line(Vector2(w * 0.5 + 9, 204), Vector2(w - 16, 204), Color(ink, 0.45), 1.0, true)
	_diamond(Vector2(w * 0.5, 204), 4.5, ink)
	var stake := "$%d" % _stake() if _stake() > 0 else "—"
	var pays := "$%d" % _reward() if _reward() > 0 else _multiple() + " stake"
	var won_ink := Color(0.62, 0.42, 0.02)
	match state:
		"taken":
			_figure(48, "RIDING", stake, INK_SOFT, INK)
			_figure(w - 48, "PAYS", pays, INK_SOFT, ink)
		"won":
			_figure(48, "STAKED", stake, INK_SOFT, INK)
			_figure(w - 48, "PAID", pays, won_ink, won_ink)
		"passed":
			_figure(48, "PASSED", stake, INK_SOFT, INK)
			_figure(w - 48, "WOULD PAY", pays, INK_SOFT, ink)
		_:
			_figure(48, "STAKE", stake, INK_SOFT, INK)
			_figure(w - 48, "PAYS", pays, INK_SOFT, ink)


func _draw_back() -> void:
	var w := SIZE.x
	var deep := tint.darkened(0.8)
	var light := tint.lerp(Color.WHITE, 0.6)
	_rr(Rect2(5.5, 5.5, w - 11, SIZE.y - 11), 8, deep)
	# A lattice of little atoms joined by bonds, filling the whole back.
	var area := Rect2(10, 50, w - 20, 150)
	var row := 0
	var y := area.position.y + 6
	while y < area.end.y - 2:
		var x := area.position.x + 6 + (8.0 if row % 2 else 0.0)
		while x < area.end.x - 3:
			var p := Vector2(x, y)
			if x + 16 < area.end.x - 3:
				draw_line(p + Vector2(3, 0), p + Vector2(13, 0), Color(tint, 0.16), 0.8, true)
			if y + 14 < area.end.y - 2:
				var q := p + Vector2(8.0 if row % 2 == 0 else -8.0, 14)
				if q.x > area.position.x + 3 and q.x < area.end.x - 3:
					draw_line(p.lerp(q, 0.22), p.lerp(q, 0.78), Color(tint, 0.16), 0.8, true)
			draw_arc(p, 2.6, 0, TAU, 12, Color(tint, 0.42), 0.9, true)
			draw_circle(p, 1.0, Color(tint, 0.5), true, -1.0, true)
			x += 16
		y += 14
		row += 1
	_rr(Rect2(8, 8, w - 16, SIZE.y - 16), 6, Color.TRANSPARENT, 1, Color(tint, 0.55))

	# Top: the unknown payout, kind and state, and the chip slot.
	_text(F_SEMI, "?×", Vector2(15, 37), 26, light, -1)
	_text(F_SEMI, "SIDE BET", Vector2(w * 0.5 + 8, 24), 11, light, 0, 1.6)
	_text(F_SEMI, "FACE DOWN", Vector2(w * 0.5 + 8, 40), 12, Color(tint, 0.95), 0, 1.0)
	_chip_slot(Vector2(w - 26, 28), 14, false, true)

	# The medallion: a question mark at the heart of an atom (the electrons are drawn by Shine).
	var c := _medal()
	draw_circle(c, 43, deep, true, -1.0, true)
	draw_arc(c, 43, 0, TAU, 64, tint, 2.0, true)
	draw_arc(c, 39, 0, TAU, 64, Color(tint, 0.35), 1.0, true)
	for k in 3:
		draw_set_transform(c, PI * k / 3.0 + PI / 6.0, Vector2(1, 0.36))
		draw_arc(Vector2.ZERO, 35, 0, TAU, 56, Color(tint, 0.5), 1.0, true)
	draw_set_transform(Vector2.ZERO)
	draw_circle(c, 17, deep, true, -1.0, true)
	_text(F_SEMI, "?", c + Vector2(0, 16), 46, TileArt.PAPER)

	# Bottom: the stake and the most this bet could pay.
	draw_line(Vector2(16, 204), Vector2(w * 0.5 - 9, 204), Color(tint, 0.5), 1.0, true)
	draw_line(Vector2(w * 0.5 + 9, 204), Vector2(w - 16, 204), Color(tint, 0.5), 1.0, true)
	_diamond(Vector2(w * 0.5, 204), 4.5, tint)
	var stake := "$%d" % _stake() if _stake() > 0 else "—"
	var top := int(info.get("max_reward", 0))
	_figure(48, "PASSED" if state == "passed" else "STAKE", stake, Color(light, 0.75), TileArt.PAPER)
	_figure(w - 48, "PAYS UP TO", "$%d" % top if top > 0 else "3× stake", Color(light, 0.75), tint.lerp(Color.WHITE, 0.25))


func _medal() -> Vector2:
	return Vector2(SIZE.x * 0.5, 124)


## Moving light over the card: electrons circling the back's question mark, a
## sheen crossing the picture, a pulse on a placed chip, sparkles on a win.
## With Fx.minimal_particles on, only the still electrons are drawn.
func _shine(ci: CanvasItem, t: float, still: bool) -> void:
	if not face_up:
		var c := _medal()
		for k in 3:
			var a := (1.7 if still else t) * (0.9 + k * 0.23) + k * 2.1
			var rot := PI * k / 3.0 + PI / 6.0
			var p := c + Vector2(cos(a) * 35.0, sin(a) * 35.0 * 0.36).rotated(rot)
			ci.draw_circle(p, 3.4, Color(tint, 0.35), true, -1.0, true)
			ci.draw_circle(p, 2.2, TileArt.PAPER, true, -1.0, true)
		return
	if still or state == "passed":
		return
	# A slanted sheen crosses the picture window every five seconds.
	var sweep := fposmod(t, 5.0) / 1.1
	if sweep < 1.0:
		var r := WINDOW.grow(-3)
		var x := lerpf(r.position.x - 30, r.end.x + 10, sweep)
		var a := PackedVector2Array()
		for p in [Vector2(x + 18, r.position.y), Vector2(x + 34, r.position.y), Vector2(x + 16, r.end.y), Vector2(x, r.end.y)]:
			a.append(Vector2(clampf(p.x, r.position.x, r.end.x), p.y))
		if a[1].x - a[0].x > 0.5 or a[2].x - a[3].x > 0.5:
			ci.draw_colored_polygon(a, Color(1, 1, 1, 0.1))
	if state == "taken" or state == "won":
		var c := Vector2(SIZE.x - 26, 28)
		var beat := fposmod(t * 0.7, 1.0)
		ci.draw_arc(c, 14 + beat * 5.0, 0, TAU, 32, Color(_frame_col().darkened(0.3), 0.5 * (1.0 - beat)), 1.4, true)
	if state == "won":
		# Sparkles travelling round the frame.
		var per := 2.0 * (SIZE.x + SIZE.y)
		for i in 7:
			var d := fposmod(t * 34.0 + i * per / 7.0, per)
			var p := Vector2(d, 3) if d < SIZE.x else (Vector2(SIZE.x - 3, d - SIZE.x) if d < SIZE.x + SIZE.y else (Vector2(per - SIZE.y - d, SIZE.y - 3) if d < 2 * SIZE.x + SIZE.y else Vector2(3, per - d)))
			var s := 3.0 + 2.5 * sin(t * 5.0 + i * 1.7)
			ci.draw_line(p - Vector2(s, 0), p + Vector2(s, 0), Color(1, 1, 0.9, 0.95), 1.2, true)
			ci.draw_line(p - Vector2(0, s), p + Vector2(0, s), Color(1, 1, 0.9, 0.95), 1.2, true)


class Shine extends Control:
	var card: BetCard
	var t := 0.4
	var shown := true

	func _init(c: BetCard) -> void:
		card = c
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(delta: float) -> void:
		var want := not Fx.minimal_particles
		if want != shown:
			shown = want
			queue_redraw()
		if want and is_visible_in_tree():
			t += delta
			queue_redraw()

	func _draw() -> void:
		card._shine(self, t, Fx.minimal_particles)
