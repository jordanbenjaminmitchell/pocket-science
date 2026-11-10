class_name TableLayout
extends RefCounted
## Geometry of a 2:1 pool table in "table units" (playfield is W x H, cushion
## noses sit exactly on the playfield edge). Pockets are capture circles placed
## just outside the mouth; jaws are angled segments that funnel balls in.

const W := 1000.0
const H := 500.0
const R := 14.0

var pocket_scale := 1.0
var closed_pockets: Array[int] = []
## Each segment: {a: Vector2, b: Vector2, n: Vector2 (unit normal toward play side)}
var segments: Array[Dictionary] = []
## Each pocket: {pos: Vector2, r: float, side: bool, mouth: Vector2, dir: Vector2}
var pockets: Array[Dictionary] = []
## Round bumpers: {pos: Vector2, r: float}
var bumpers: Array[Dictionary] = []
## Linked pairs {a, b}: a ball entering one end leaves the other at the same speed.
var portals: Array[Dictionary] = []
const PORTAL_R := 16.0
const BUMPER_R := 18.0


func build(scale: float = 1.0, closed: Array[int] = []) -> TableLayout:
	pocket_scale = scale
	closed_pockets = closed
	segments.clear()
	pockets.clear()
	var cm := 41.0 * scale   # corner mouth: distance from the corner where the rail nose ends
	var sh := 29.0 * scale   # side pocket half-width
	var jl := 25.0           # jaw length
	var mid := W * 0.5
	var centre := Vector2(mid, H * 0.5)

	# Pocket order: 0 TL, 1 TM, 2 TR, 3 BL, 4 BM, 5 BR
	var corners := [Vector2(0, 0), Vector2(W, 0), Vector2(0, H), Vector2(W, H)]
	_add_pocket(Vector2(0, 0) + Vector2(-8, -8), 29.0 * scale, false, Vector2(1, 1).normalized())
	_add_pocket(Vector2(mid, -14), 27.5 * scale, true, Vector2(0, 1))
	_add_pocket(Vector2(W, 0) + Vector2(8, -8), 29.0 * scale, false, Vector2(-1, 1).normalized())
	_add_pocket(Vector2(0, H) + Vector2(-8, 8), 29.0 * scale, false, Vector2(1, -1).normalized())
	_add_pocket(Vector2(mid, H + 14), 27.5 * scale, true, Vector2(0, -1))
	_add_pocket(Vector2(W, H) + Vector2(8, 8), 29.0 * scale, false, Vector2(-1, -1).normalized())

	# Long rails (top y=0, bottom y=H), split by side pockets.
	for y in [0.0, H]:
		var out := -1.0 if y == 0.0 else 1.0
		var top_index := 1 if y == 0.0 else 4
		var side_closed := closed_pockets.has(top_index)
		var left_corner_closed := closed_pockets.has(0 if y == 0.0 else 3)
		var right_corner_closed := closed_pockets.has(2 if y == 0.0 else 5)
		var x0 := 0.0 if left_corner_closed else cm
		var x1 := W if right_corner_closed else W - cm
		if side_closed:
			_add_seg(Vector2(x0, y), Vector2(x1, y), centre)
		else:
			_add_seg(Vector2(x0, y), Vector2(mid - sh, y), centre)
			_add_seg(Vector2(mid + sh, y), Vector2(x1, y), centre)
			var sp := Vector2(mid, y + out * 6.0)
			pockets[top_index]["mouth"] = PackedVector2Array([Vector2(mid - sh, y), Vector2(mid - sh + 5.0, y + out * jl), Vector2(mid + sh - 5.0, y + out * jl), Vector2(mid + sh, y)])
			_add_seg(Vector2(mid - sh, y), Vector2(mid - sh + 5.0, y + out * jl), sp)
			_add_seg(Vector2(mid + sh, y), Vector2(mid + sh - 5.0, y + out * jl), sp)
	# Short rails (left x=0, right x=W).
	for x in [0.0, W]:
		var top_closed := closed_pockets.has(0 if x == 0.0 else 2)
		var bot_closed := closed_pockets.has(3 if x == 0.0 else 5)
		var y0 := 0.0 if top_closed else cm
		var y1 := H if bot_closed else H - cm
		_add_seg(Vector2(x, y0), Vector2(x, y1), centre)
	# Corner jaws.
	var corner_ids := [0, 2, 3, 5]
	for k in 4:
		if closed_pockets.has(corner_ids[k]):
			continue
		var c: Vector2 = corners[k]
		var sx := 1.0 if c.x == 0.0 else -1.0
		var sy := 1.0 if c.y == 0.0 else -1.0
		var a1 := c + Vector2(sx * cm, 0)
		var a2 := c + Vector2(0, sy * cm)
		var back := Vector2(-sx, -sy) * jl
		_add_seg(a1, a1 + back, c)
		_add_seg(a2, a2 + back, c)
		pockets[corner_ids[k]]["mouth"] = PackedVector2Array([a1, a1 + back, a2 + back, a2])
	return self


func _add_pocket(p: Vector2, r: float, side: bool, dir: Vector2) -> void:
	var index := pockets.size()
	pockets.append({"pos": p, "r": r, "side": side, "dir": dir, "closed": closed_pockets.has(index)})


func _add_seg(a: Vector2, b: Vector2, toward: Vector2) -> void:
	var t := (b - a).normalized()
	var n := Vector2(-t.y, t.x)
	if n.dot(toward - a) < 0.0:
		n = -n
	segments.append({"a": a, "b": b, "n": n})


func add_bumper(p: Vector2, r: float) -> void:
	bumpers.append({"pos": p, "r": r})


func pocket_count() -> int:
	return pockets.size()


static func pocket_name(i: int) -> String:
	return ["top-left corner", "top side", "top-right corner", "bottom-left corner", "bottom side", "bottom-right corner"][i]
