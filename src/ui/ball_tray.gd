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
	queue_redraw()


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
			draw_arc(c, r + 3.0, 0, TAU, 24, Color(Catalog.IMBUES[iso].color, a), 2.0)
		elif n == 8:
			draw_arc(c, r + 1.5, 0, TAU, 24, Color(1.0, 0.38, 0.32, a), 1.6)   # the ball to avoid
		if Catalog.is_stripe(n):
			draw_circle(c, r, Color(0.95, 0.93, 0.88, a))
			draw_rect(Rect2(c + Vector2(-r * 0.92, -r * 0.5), Vector2(r * 1.84, r)), Color(base, a))
		else:
			draw_circle(c, r, Color(base, a))
		draw_circle(c, r * 0.48, Color(0.97, 0.95, 0.9, a))
		if font:
			var t := str(n)
			var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			draw_string(font, c + Vector2(-w * 0.5, 3.5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.05, 0.05, 0.05, a))
		draw_circle(c + Vector2(-r * 0.35, -r * 0.4), r * 0.22, Color(1, 1, 1, 0.35 * a))
		if down:
			draw_line(c + Vector2(-r * 0.6, -r * 0.6), c + Vector2(r * 0.6, r * 0.6), Color(1, 0.85, 0.3, 0.5), 1.5)
