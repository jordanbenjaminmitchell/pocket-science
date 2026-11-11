class_name AimDial
extends Control
## A touch strip for very fine aiming: drag along it and the shot turns a tiny
## amount (DEG_PER_PX degrees per pixel), so a thumb can line up a cut precisely
## without ever covering the table. Tick marks slide with the drag as feedback.

signal turned(degrees: float)

const DEG_PER_PX := 0.05

var offset := 0.0     # how far the ticks have slid, in pixels
var font: Font
var _held := false


func _ready() -> void:
	custom_minimum_size = Vector2(0, 46)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_held = e.pressed
		queue_redraw()
		accept_event()
	elif e is InputEventMouseMotion and _held:
		drag(e.relative.x)
		accept_event()


## Turns the aim by a horizontal drag of dx pixels (right turns clockwise).
func drag(dx: float) -> void:
	if dx == 0.0:
		return
	offset += dx
	turned.emit(dx * DEG_PER_PX)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.06, 0.08, 0.1) if not _held else Color(0.08, 0.13, 0.16), true)
	draw_rect(r, Color(0.45, 0.7, 0.9, 0.8), false, 1.5)
	var gap := 12.0
	var start := fposmod(offset, gap)
	var x := start
	while x < size.x:
		var major := (int(floor((x - offset) / gap)) % 5) == 0
		var h := size.y * (0.5 if major else 0.28)
		draw_line(Vector2(x, (size.y - h) * 0.5), Vector2(x, (size.y + h) * 0.5), Color(0.6, 0.8, 0.95, 0.75 if major else 0.4), 1.5)
		x += gap
	draw_line(Vector2(size.x * 0.5, 2), Vector2(size.x * 0.5, size.y - 2), Color(1.0, 0.85, 0.4), 2.0)
	if font:
		var t := "◀ FINE AIM ▶"
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, Vector2((size.x - w) * 0.5, 13), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.9, 0.95, 0.85))
