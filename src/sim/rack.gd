class_name Rack
extends RefCounted
## Builds standard racks on a PoolSim. Foot spot sits three-quarters down the table.

const FOOT := Vector2(TableLayout.W * 0.75, TableLayout.H * 0.5)
const HEAD := Vector2(TableLayout.W * 0.25, TableLayout.H * 0.5)


static func _slot(row: int, col: int) -> Vector2:
	var gap := TableLayout.R * 2.0 + 0.35
	return FOOT + Vector2(row * gap * 0.8660254, (col - row * 0.5) * gap)


const MAX_BALLS := 21   # six rows of triangle


## Racks a ball set in a triangle: the 1 at the apex when present, the 8 in the
## middle, the rest shuffled. Sets larger than 15 add a sixth row.
static func build(sim: PoolSim, rng: RandomNumberGenerator, balls: Array = []) -> void:
	var slots: Array[Vector2] = []
	for r in 6:
		for c in r + 1:
			slots.append(_slot(r, c))
	var order := order_for(balls if not balls.is_empty() else range(1, 16), rng)
	for k in mini(slots.size(), order.size()):
		# A hair of jitter keeps breaks from being perfectly symmetric.
		var j := Vector2(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.12, 0.12))
		sim.add_ball(order[k], slots[k] + j)


static func order_for(balls: Array, rng: RandomNumberGenerator) -> Array:
	var rest: Array = _shuffled(balls.filter(func(n): return n != 1 and n != 8), rng)
	if balls.has(1):
		rest.insert(0, 1)
	if balls.has(8):
		rest.insert(mini(4, rest.size()), 8)
	return rest


static func _shuffled(a: Array, rng: RandomNumberGenerator) -> Array:
	var b := a.duplicate()
	for i in range(b.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = b[i]
		b[i] = b[j]
		b[j] = t
	return b
