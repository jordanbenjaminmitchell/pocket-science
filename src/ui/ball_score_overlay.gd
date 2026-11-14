class_name BallScoreOverlay
extends Control
## Compact 1x-pocket values with leaders back to the balls. All coordinates are
## in the game canvas, and labels are placed above their balls without overlap.

const BADGE_H := 23.0
const GAP := 4.0
const ROW_STEP := 27.0

var font: Font
var entries: Array = []
var placed: Array = []


func set_entries(next: Array, bounds: Rect2) -> void:
	entries = next
	placed = place(next, bounds, font)
	queue_redraw()


static func place(next: Array, bounds: Rect2, label_font: Font) -> Array:
	var order := next.duplicate()
	order.sort_custom(func(a, b):
		return a.anchor.y < b.anchor.y if not is_equal_approx(a.anchor.y, b.anchor.y) else a.anchor.x < b.anchor.x)
	var out: Array = []
	for e in order:
		var w := maxf(40.0, label_font.get_string_size(String(e.text), HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 16.0)
		var shifts: Array[float] = [0.0]
		for step in range(1, ceili(bounds.size.x / 30.0) + 1):
			shifts.append(-step * 30.0)
			shifts.append(step * 30.0)
		var chosen := Rect2()
		var found := false
		for row in 14:
			if found:
				break
			for shift in shifts:
				var x: float = clampf(e.anchor.x - w * 0.5 + shift, bounds.position.x, bounds.end.x - w)
				var y: float = e.anchor.y - 43.0 - row * ROW_STEP
				var rect := Rect2(x, y, w, BADGE_H)
				if rect.position.y < bounds.position.y or rect.end.y > e.anchor.y - 13.0:
					continue
				var clear := true
				for used in out:
					if rect.grow(GAP).intersects(used.rect):
						clear = false
						break
				if clear:
					for other in next:
						if rect.grow(2.0).intersects(Rect2(other.anchor - Vector2(13, 13), Vector2(26, 26))):
							clear = false
							break
				if clear:
					chosen = rect
					found = true
					break
		if found:
			out.append({"rect": chosen, "anchor": e.anchor, "text": e.text, "color": e.color, "number": e.number})
	return out


func _draw() -> void:
	if font == null:
		return
	for e in placed:
		var r: Rect2 = e.rect
		var a: Vector2 = e.anchor
		var stem := Vector2(clampf(a.x, r.position.x + 5.0, r.end.x - 5.0), r.end.y)
		draw_line(stem, a - Vector2(0, 11), Color(e.color, 0.85), 1.4, true)
	for e in placed:
		var r: Rect2 = e.rect
		draw_rect(r, Color(0.04, 0.06, 0.09, 0.94))
		draw_rect(r, Color(e.color, 0.95), false, 1.6)
		var txt := String(e.text)
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(font, Vector2(r.position.x + (r.size.x - tw) * 0.5, r.position.y + 17.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
