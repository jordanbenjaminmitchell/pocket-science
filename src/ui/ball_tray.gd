class_name BallTray
extends Control
## Shows every ball in the current rack: bright if still on the table, sunk
## into the tray if potted. Imbue-enhanced balls carry a coloured ring.

var balls: Array = []        # ball numbers in this rack
var potted := {}             # number -> true
var imbues := {}
var font: Font


func _ready() -> void:
	custom_minimum_size = Vector2(296, 58)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_state(rack: Array, down: Dictionary, iso: Dictionary) -> void:
	balls = rack
	potted = down
	imbues = iso
	# Grows a row at a time as the ball set grows past 16.
	custom_minimum_size.y = 6.0 + ceilf(maxf(1.0, rack.size()) / 8.0) * 26.0
	queue_redraw()


## The middle slice of a circle, |y| <= h * r: a stripe's band.
static func _band(c: Vector2, r: float, h: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var a0 := asin(h)
	for k in 13:
		var t := lerpf(-a0, a0, k / 12.0)
		pts.append(c + Vector2(cos(t), sin(t)) * r)
	for k in 13:
		var t := lerpf(PI - a0, PI + a0, k / 12.0)
		pts.append(c + Vector2(cos(t), sin(t)) * r)
	return pts


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.035, 0.03), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.2, 0.12), false, 1.5)
	var r := 11.0
	var per_row := 8
	for k in balls.size():
		var n: int = balls[k]
		var col := k % per_row
		var row := k / per_row
		var c := Vector2(18 + col * minf(36.0, (size.x - 36.0) / 7.0), 16 + row * 26)
		var down: bool = potted.has(n)
		var a := 0.28 if down else 1.0
		var base := Catalog.ball_color(n)
		var iso: String = imbues.get(n, "")
		if iso != "":
			draw_arc(c, r + 3.0, 0, TAU, 32, Color(Catalog.IMBUES[iso].color, a), 2.0, true)
		elif n == 8:
			draw_arc(c, r + 1.5, 0, TAU, 32, Color(1.0, 0.38, 0.32, a), 1.6, true)   # the ball to avoid
		var stripe := Catalog.is_stripe(n)
		if stripe:
			# White ball with a coloured band across the middle: big white caps top and
			# bottom, so a stripe never reads as a solid even at this size.
			draw_circle(c, r, Color(0.96, 0.94, 0.89, a), true, -1.0, true)
			draw_colored_polygon(_band(c, r, 0.5), Color(base, a))
		else:
			draw_circle(c, r, Color(base, a), true, -1.0, true)
		draw_arc(c, r, 0, TAU, 32, Color(0, 0, 0, 0.35 * a), 1.0, true)
		draw_circle(c, r * (0.4 if stripe else 0.48), Color(0.97, 0.95, 0.9, a), true, -1.0, true)
		if font:
			var t := str(n)
			var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			if n > 15:
				var bt: Dictionary = Catalog.BALL_TYPES.get(Catalog.kind_of(n), {})
				if not bt.is_empty():
					IconArt.paint(self, bt.motif, c, r * 0.4 / 34.0, Color((bt.color as Color).darkened(0.3), a), Color(0.97, 0.95, 0.9, a), font, 1.2)
			else:
				draw_string(font, c + Vector2(-w * 0.5, 3.5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.05, 0.05, 0.05, a))
		draw_circle(c + Vector2(-r * 0.35, -r * 0.4), r * 0.22, Color(1, 1, 1, 0.35 * a), true, -1.0, true)
		if down:
			draw_line(c + Vector2(-r * 0.6, -r * 0.6), c + Vector2(r * 0.6, r * 0.6), Color(1, 0.85, 0.3, 0.5), 1.5)
