class_name ChalkPips
extends Control
## Little blue chalk cubes: one per remaining miss.

var count := 3
var max_count := 3
var flash := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(140, 30)
	mouse_filter = Control.MOUSE_FILTER_PASS   # hover for the Chalk tooltip


func set_count(c: int, m: int) -> void:
	if c < count:
		flash = 1.0
	count = c
	max_count = maxi(m, c)
	queue_redraw()


func _process(delta: float) -> void:
	if flash > 0.0:
		flash = maxf(0.0, flash - delta * 2.0)
		queue_redraw()


func _draw() -> void:
	# Up to 12 cubes: they close up when there are more than fit.
	var step := minf(30.0, 250.0 / maxf(1.0, max_count))
	var side := minf(22.0, step - 4.0)
	for i in max_count:
		var x := i * step
		var r := Rect2(Vector2(x, 4 + (22.0 - side) * 0.5), Vector2(side, side))
		if i < count:
			draw_rect(r, Color(0.2, 0.45, 0.85), true)
			draw_rect(Rect2(r.position, Vector2(side, side * 0.32)), Color(0.4, 0.65, 1.0), true)
			draw_rect(r, Color(0.08, 0.2, 0.45), false, 1.5)
		else:
			var c := Color(1, 0.3, 0.25, flash) if i == count else Color(1, 1, 1, 0.12)
			draw_rect(r, c, false, 1.5)
