class_name LogoArt
extends Control
## The Pocket Science mark: a black 8-ball as the nucleus of an atom, with three
## electron orbits. With a font set it also draws the wordmark beside it.

var font: Font
var t := 0.0
var animate := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if animate:
		t += delta
		queue_redraw()


func _orbit(c: Vector2, a: float, b: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 65:
		var th := TAU * i / 64.0
		pts.append(c + Vector2(cos(th) * a, sin(th) * b).rotated(rot))
	return pts


func _draw() -> void:
	var h := size.y
	var r := h * 0.27
	var c := Vector2(h * 0.5, h * 0.5) if font else size * 0.5
	var gold := Color(0.98, 0.8, 0.4)
	var a := h * 0.47
	var b := h * 0.17
	var orbits := [0.0, PI / 3.0, -PI / 3.0]
	for rot: float in orbits:
		draw_polyline(_orbit(c, a, b, rot), Color(gold, 0.85), maxf(1.5, h * 0.018), true)
	# 8-ball nucleus.
	draw_circle(c, r, Color(0.05, 0.05, 0.07))
	draw_arc(c, r, 0.0, TAU, 48, Color(0.3, 0.3, 0.36), maxf(1.0, h * 0.01), true)
	draw_circle(c + Vector2(-r * 0.36, -r * 0.42), r * 0.2, Color(1, 1, 1, 0.3))
	draw_circle(c, r * 0.5, Color(0.97, 0.95, 0.9))
	var num_font: Font = font if font else ThemeDB.fallback_font
	var fs := int(r * 0.8)
	var w := num_font.get_string_size("8", HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(num_font, c + Vector2(-w * 0.5, fs * 0.36), "8", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.06, 0.06, 0.08))
	# Electrons.
	for k in orbits.size():
		var th: float = t * (1.3 + k * 0.25) + k * 2.1
		var e := c + Vector2(cos(th) * a, sin(th) * b).rotated(orbits[k])
		draw_circle(e, h * 0.04, Color(0.45, 0.85, 1.0))
	if font == null:
		return
	var x := h * 1.08
	var big := int(h * 0.36)
	for row in [["POCKET", h * 0.46, gold], ["SCIENCE", h * 0.86, Color(0.45, 0.85, 1.0)]]:
		draw_string(font, Vector2(x + 3, row[1] + 4), row[0], HORIZONTAL_ALIGNMENT_LEFT, -1, big, Color(0, 0, 0, 0.6))
		draw_string(font, Vector2(x, row[1]), row[0], HORIZONTAL_ALIGNMENT_LEFT, -1, big, row[2])
