class_name FireFx
extends Control
## Chunky pixel flames rising from the bottom edge, in the game's pixel-art
## style. "level" follows the Heat tiers: 0 none, 1 Warm (embers), 2 In stroke
## (low flames), 3 On fire (tall flames), 4 Dead stroke (a blue-white core).

const NAMES := ["", "Warm", "In stroke", "On fire", "Dead stroke"]
const HEIGHTS := [0.0, 0.2, 0.55, 0.85, 1.0]

var level := 0
var t := 0.0


## Heat 1-2 Warm, 3-4 In stroke, 5-6 On fire, 7+ Dead stroke.
static func level_for(heat: int) -> int:
	if heat >= 7:
		return 4
	if heat >= 5:
		return 3
	if heat >= 3:
		return 2
	return 1 if heat >= 1 else 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if level > 0:
		t += delta
		queue_redraw()


func _draw() -> void:
	paint(self, Rect2(Vector2.ZERO, size), level, t)


## Draws flames into rect r on any canvas item, so the table can burn too. The
## fire is a row of tapered tongues that sway and flicker, built from square
## pixels so it matches the pixel-art headings.
static func paint(ci: CanvasItem, r: Rect2, lvl: int, time: float, px: float = 3.0, alpha: float = 1.0) -> void:
	if lvl <= 0:
		return
	var max_h: float = HEIGHTS[lvl] * r.size.y
	if lvl >= 2:
		var cols := int(r.size.x / px)
		var rows := int(max_h / px) + 1
		var n_t := maxi(1, int(r.size.x / 30.0))
		var tongues: Array = []
		for g in n_t:
			# Each tongue sways, breathes and leans on its own rhythm.
			var cx := (g + 0.5) / n_t * r.size.x + sin(time * 2.3 + g * 1.7) * 3.0
			var hw := minf(16.0, r.size.x * 0.5) + 3.0 * sin(time * 1.9 + g * 2.1)
			var th := max_h * (0.72 + 0.28 * (0.5 + 0.5 * sin(time * 5.3 + g * 2.9)))
			var lean := sin(time * 3.1 + g) * 0.25
			tongues.append([cx, hw, th, lean])
		for c in cols:
			var x := c * px + px * 0.5
			for k in rows:
				var y := k * px + px * 0.5
				var heat := 0.0
				for tg in tongues:
					var dy: float = y / tg[2]
					if dy >= 1.0:
						continue
					# A teardrop: wide at the base, narrowing to a point that leans.
					var width: float = tg[1] * pow(1.0 - dy, 0.75)
					var dx: float = absf(x - tg[0] - tg[3] * y) / maxf(width, 0.01)
					if dx < 1.0:
						heat = maxf(heat, 1.0 - maxf(dx, dy * 0.85))
				if heat <= 0.0:
					continue
				var col := _flame_color(heat, lvl)
				col.a *= clampf(heat * 2.2, 0.0, 1.0) * alpha
				ci.draw_rect(Rect2(r.position.x + c * px, r.end.y - (k + 1) * px, px - 0.5, px - 0.5), col)
	# Embers drift up at every level (none with Particles at Minimum).
	for e in (0 if Fx.minimal_particles else 2 + lvl * 2):
		var ph := fmod(time * (0.45 + 0.1 * lvl) + e * 0.37, 1.0)
		var ex := r.position.x + fmod(e * 53.0 + sin(time * 1.3 + e) * 9.0 + r.size.x, r.size.x)
		var ey := r.end.y - ph * r.size.y * 1.2
		var ember := Color(0.8, 0.92, 1.0) if lvl >= 4 and e % 2 == 0 else Color(1.0, 0.68, 0.2)
		ci.draw_rect(Rect2(ex, ey, px * 0.75, px * 0.75), Color(ember, (1.0 - ph) * alpha))


## "heat" runs from 1 at a flame's core to 0 at its edge.
static func _flame_color(heat: float, lvl: int) -> Color:
	if lvl >= 4:
		if heat > 0.6:
			return Color(0.88, 0.96, 1.0)
		if heat > 0.35:
			return Color(0.45, 0.72, 1.0)
		return Color(1.0, 0.5, 0.18)
	if heat > 0.62:
		return Color(1.0, 0.94, 0.55)
	if heat > 0.35:
		return Color(1.0, 0.6, 0.15)
	return Color(0.9, 0.24, 0.08)
