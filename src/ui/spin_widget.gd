class_name SpinWidget
extends Control
## Click/drag on the big cue ball to choose where the tip strikes it.
## Up = follow (topspin), down = draw (backspin), left/right = side english.

signal changed(follow: float, side: float)

var follow := 0.0
var side := 0.0
var dragging := false
var font: Font


func _ready() -> void:
	custom_minimum_size = Vector2(120, 120)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Spin: click above centre for follow, below for draw, sides for english. Right-click resets. Keys W/S/A/D."


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT:
			dragging = e.pressed
			if e.pressed:
				_set_from(e.position)
		elif e.button_index == MOUSE_BUTTON_RIGHT and e.pressed:
			set_spin(0.0, 0.0)
		accept_event()
	elif e is InputEventMouseMotion and dragging:
		_set_from(e.position)
		accept_event()


func _set_from(p: Vector2) -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 10.0
	var v := (p - c) / r
	if v.length() > 0.8:
		v = v.normalized() * 0.8
	set_spin(-v.y / 0.8, v.x / 0.8)


func set_spin(f: float, s: float) -> void:
	follow = clampf(f, -1.0, 1.0)
	side = clampf(s, -1.0, 1.0)
	queue_redraw()
	changed.emit(follow, side)


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 10.0
	draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
	draw_circle(c, r, Color(0.93, 0.92, 0.88))
	draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.35, Color(1, 1, 1, 0.5))
	draw_arc(c, r, 0, TAU, 48, Color(0.3, 0.3, 0.3), 1.5)
	draw_line(c - Vector2(r, 0), c + Vector2(r, 0), Color(0, 0, 0, 0.12), 1.0)
	draw_line(c - Vector2(0, r), c + Vector2(0, r), Color(0, 0, 0, 0.12), 1.0)
	draw_arc(c, r * 0.8, 0, TAU, 48, Color(0, 0, 0, 0.1), 1.0)
	var p := c + Vector2(side, -follow) * r * 0.8
	draw_circle(p, 8.0, Color(0.2, 0.45, 0.85))
	draw_arc(p, 8.0, 0, TAU, 24, Color(0.05, 0.15, 0.4), 2.0)
	if font:
		var label := "CENTRE"
		if absf(follow) > 0.15 or absf(side) > 0.15:
			var parts: Array[String] = []
			if follow > 0.15:
				parts.append("FOLLOW")
			elif follow < -0.15:
				parts.append("DRAW")
			if side > 0.15:
				parts.append("RIGHT")
			elif side < -0.15:
				parts.append("LEFT")
			label = " + ".join(parts)
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, Vector2(c.x - w * 0.5, size.y - 0.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.8, 0.85))
