class_name PowerMeter
extends Control
## Vertical power bar. Fills green -> amber -> red.

var power := 0.0
var font: Font


func _ready() -> void:
	custom_minimum_size = Vector2(34, 120)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_power(p: float) -> void:
	if p != power:
		power = p
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2(8, 0), Vector2(size.x - 16, size.y - 16))
	draw_rect(r, Color(0.05, 0.06, 0.08), true)
	var h := r.size.y * power
	var col := Color(0.3, 0.9, 0.5).lerp(Color(1.0, 0.75, 0.2), clampf(power * 1.6, 0, 1))
	if power > 0.8:
		col = col.lerp(Color(1.0, 0.3, 0.2), (power - 0.8) * 5.0)
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - h), Vector2(r.size.x, h)), col, true)
	for i in range(1, 4):
		var y := r.position.y + r.size.y * i / 4.0
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(1, 1, 1, 0.15), 1.0)
	draw_rect(r, Color(0.6, 0.5, 0.3), false, 1.5)
	if font:
		var t := "%d%%" % int(round(power * 100))
		var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, Vector2(size.x * 0.5 - w * 0.5, size.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.85, 0.9))
