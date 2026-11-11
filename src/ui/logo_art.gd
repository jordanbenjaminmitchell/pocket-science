class_name LogoArt
extends Control
## The Pocket Science mark, matching the app icon (tools/make_icon.gd): a carbon
## atom on a little pool table. The 8-ball is the nucleus inside three long,
## thin orbits 60 degrees apart, and the 1- to 5-balls and the cue ball are its 6 electrons, two
## per orbit. They start at staggered points along their orbits, as on the icon, then
## set off one after another in ball order and settle at one shared speed, so they
## stay out of step with each other but always on their track.
## Electrons on the far half of an orbit pass behind the 8-ball.
## With a font set it also draws the wordmark beside the table.

## In icon units (the icon's orbits are 32 wide on a 108 grid).
const ORBIT_RX := 32.0
const ORBIT_RY := 12.0
const ORBITS := [15.0, 75.0, 135.0]
## Each electron's starting point along its orbit in degrees, [orbit][side]; the same
## as the app icon (tools/make_icon.gd ELECTRON_AT), staggered so the pairs never line up.
const START_AT := [[20.0, 215.0], [325.0, 160.0], [50.0, 190.0]]
const NUCLEUS_R := 11.5
const ELECTRON_R := 5.0
## The sixth electron is the cue ball rather than the 6-ball.
const CUE := 6
## Table width over height.
const TABLE_ASPECT := 1.75
## Orbit speed in radians a second, the gap between electrons setting off, and how
## long each takes to get up to speed.
const SPEED := 0.6
const START_GAP := 0.45
const RAMP := 0.6

var font: Font
var t := 0.0
var animate := true
## Ball number for each [orbit, side] slot, numbered clockwise from the top.
var _numbers := []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var slots := []
	for k in 6:
		slots.append([k, _local(k, 0.0)])
	slots.sort_custom(func(p, q): return fposmod(p[1].angle() + PI * 0.5, TAU) < fposmod(q[1].angle() + PI * 0.5, TAU))
	_numbers.resize(6)
	for i in slots.size():
		_numbers[slots[i][0]] = i + 1


func _process(delta: float) -> void:
	if animate:
		t += delta
		queue_redraw()


## How far electron k has travelled: the 1-ball sets off first, each next ball
## START_GAP seconds later, easing up to SPEED over RAMP seconds.
func phase_of(k: int) -> float:
	var s := t - START_GAP * (int(_numbers[k]) - 1) if _numbers.size() == 6 else t
	if s <= 0.0:
		return 0.0
	if s < RAMP:
		return SPEED * s * s / (2.0 * RAMP)
	return SPEED * (s - RAMP * 0.5)


## Electron k's offset from the nucleus in icon units, and its orbit parameter.
## k / 2 picks the orbit, k % 2 the side.
func _param(k: int, phase: float) -> float:
	return deg_to_rad(START_AT[k / 2][k % 2]) + phase


func _local(k: int, phase: float) -> Vector2:
	var th := _param(k, phase)
	return Vector2(ORBIT_RX * cos(th), ORBIT_RY * sin(th)).rotated(deg_to_rad(ORBITS[k / 2]))


func _orbit(c: Vector2, u: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 97:
		var th := TAU * i / 96.0
		pts.append(c + Vector2(cos(th) * ORBIT_RX, sin(th) * ORBIT_RY).rotated(rot) * u)
	return pts


func _draw() -> void:
	var h := size.y
	var tw := h * TABLE_ASPECT
	var origin := Vector2.ZERO if font else Vector2((size.x - tw) * 0.5, 0.0)
	var c := origin + Vector2(tw, h) * 0.5
	_table(Rect2(origin, Vector2(tw, h)))
	var rail := h * 0.085
	# The tallest orbit just fits the felt.
	var u := (h * 0.5 - rail - h * 0.03) / (ORBIT_RX * 0.98)
	var gold := Color(0.98, 0.8, 0.4)
	for rot: float in ORBITS:
		var pts := _orbit(c, u, deg_to_rad(rot))
		draw_polyline(pts, Color(0.01, 0.16, 0.11, 0.6), maxf(2.5, 4.4 * u), true)
		draw_polyline(pts, gold, maxf(1.5, 2.6 * u), true)
	var num_font: Font = ThemeDB.fallback_font   # the wordmark is pixel art, numbers stay smooth
	# Far electrons first, then the 8-ball, then near ones.
	for k in 6:
		if sin(_param(k, phase_of(k))) < 0.0:
			_electron(num_font, c + _local(k, phase_of(k)) * u, u, _numbers[k])
	_eight_ball(num_font, c, NUCLEUS_R * u)
	for k in 6:
		if sin(_param(k, phase_of(k))) >= 0.0:
			_electron(num_font, c + _local(k, phase_of(k)) * u, u, _numbers[k])
	if font == null:
		return
	# Wordmark, sized to fit beside the table.
	var x := origin.x + tw + h * 0.1
	var big := int(h * 0.36)
	var widest := font.get_string_size("SCIENCE", HORIZONTAL_ALIGNMENT_LEFT, -1, big).x
	if widest > size.x - x:
		big = int(big * (size.x - x) / widest)
	for row in [["POCKET", h * 0.5 - big * 0.12, gold], ["SCIENCE", h * 0.5 + big * 0.98, Color(0.45, 0.85, 1.0)]]:
		draw_string(font, Vector2(x + 3, row[1] + 4), row[0], HORIZONTAL_ALIGNMENT_LEFT, -1, big, Color(0, 0, 0, 0.6))
		draw_string(font, Vector2(x, row[1]), row[0], HORIZONTAL_ALIGNMENT_LEFT, -1, big, row[2])


## Wood rails, cushions, felt and six pockets.
func _table(r: Rect2) -> void:
	var h := r.size.y
	var rail := h * 0.085
	draw_rect(r, Color(0.3, 0.16, 0.07))
	draw_rect(r.grow(-h * 0.012), Color(0.42, 0.23, 0.1), false, maxf(1.0, h * 0.01))
	var felt := r.grow(-rail)
	draw_rect(felt, Color(0.05, 0.36, 0.24))
	draw_rect(felt.grow(-h * 0.06), Color(0.07, 0.45, 0.3))
	draw_rect(felt, Color(0.03, 0.26, 0.17), false, maxf(1.5, h * 0.022))
	var pr := h * 0.062
	for p in [felt.position, Vector2(felt.end.x, felt.position.y), felt.end, Vector2(felt.position.x, felt.end.y),
			Vector2(felt.get_center().x, felt.position.y - pr * 0.25), Vector2(felt.get_center().x, felt.end.y + pr * 0.25)]:
		draw_circle(p, pr * 1.2, Color(0.2, 0.1, 0.04))
		draw_circle(p, pr, Color(0.02, 0.02, 0.02))


func _eight_ball(f: Font, c: Vector2, r: float) -> void:
	draw_circle(c + Vector2(r * 0.12, r * 0.25), r * 1.15, Color(0.0, 0.12, 0.08, 0.45))
	draw_circle(c, r, Color(0.05, 0.05, 0.07))
	draw_arc(c, r, 0.0, TAU, 48, Color(0.3, 0.3, 0.36), maxf(1.0, r * 0.06), true)
	draw_circle(c + Vector2(-r * 0.36, -r * 0.42), r * 0.2, Color(1, 1, 1, 0.3))
	draw_circle(c, r * 0.5, Color(0.97, 0.95, 0.9))
	_number(f, c, "8", int(r * 0.8))


func _electron(f: Font, e: Vector2, u: float, n: int) -> void:
	var er := ELECTRON_R * u
	draw_circle(e + Vector2(0.5, 0.9) * u, er + 0.8 * u, Color(0.01, 0.14, 0.1, 0.6))
	if n == CUE:
		draw_circle(e, er, Color(0.97, 0.95, 0.9))
	else:
		draw_circle(e, er, Catalog.ball_color(n))
		draw_circle(e, er * 0.56, Color(0.97, 0.95, 0.9))
		_number(f, e, str(n), int(er * 0.95))
	draw_circle(e + Vector2(-2.4, -2.9) * u, 0.9 * u, Color(1, 1, 1, 0.75))


func _number(f: Font, at: Vector2, txt: String, fs: int) -> void:
	if fs < 4:
		return
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(f, at + Vector2(-w * 0.5, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.06, 0.06, 0.08))
