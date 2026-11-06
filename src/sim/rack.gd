class_name Rack
extends RefCounted
## Builds standard racks on a PoolSim. Foot spot sits three-quarters down the table.

const FOOT := Vector2(TableLayout.W * 0.75, TableLayout.H * 0.5)
const HEAD := Vector2(TableLayout.W * 0.25, TableLayout.H * 0.5)


static func _slot(row: int, col: int) -> Vector2:
	var gap := TableLayout.R * 2.0 + 0.35
	return FOOT + Vector2(row * gap * 0.8660254, (col - row * 0.5) * gap)


## kind: "nine" (diamond 1-9), "fifteen" (triangle 1-15), "six" (small triangle 1-6),
## "ten" (triangle 1-10). Returns the ball numbers racked.
static func build(sim: PoolSim, kind: String, rng: RandomNumberGenerator, balls: Array = []) -> void:
	var slots: Array[Vector2] = []
	var order: Array = []
	match kind:
		"six":
			for r in 3:
				for c in r + 1:
					slots.append(_slot(r, c))
			order = _shuffled([2, 3, 4, 5, 6], rng)
			order.insert(0, 1)
		"nine":
			var shape := [[0, 0], [1, 0], [1, 1], [2, 0], [2, 1], [2, 2], [3, 1], [3, 2], [4, 2]]
			for s in shape:
				slots.append(_slot(s[0], s[1]))
			order = _shuffled([2, 3, 4, 5, 6, 7, 8], rng)
			order.insert(0, 1)
			order.insert(4, 9)
		"ten":
			for r in 4:
				for c in r + 1:
					slots.append(_slot(r, c))
			order = _shuffled([2, 3, 4, 5, 6, 7, 8, 9], rng)
			order.insert(0, 1)
			order.insert(4, 10)
		_:
			for r in 5:
				for c in r + 1:
					slots.append(_slot(r, c))
			var rest := _shuffled([2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15], rng)
			order = rest
			order.insert(0, 1)
			order.insert(4, 8)
	if not balls.is_empty():
		order = balls
	for k in mini(slots.size(), order.size()):
		# A hair of jitter keeps breaks from being perfectly symmetric.
		var j := Vector2(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.12, 0.12))
		sim.add_ball(order[k], slots[k] + j)


static func _shuffled(a: Array, rng: RandomNumberGenerator) -> Array:
	var b := a.duplicate()
	for i in range(b.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = b[i]
		b[i] = b[j]
		b[j] = t
	return b
