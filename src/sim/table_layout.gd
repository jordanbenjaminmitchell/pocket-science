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
## Shaped tables: the playfield polygon (empty for the standard rectangle), and
## where the rack's apex sits.
var shape := PackedVector2Array()
var foot := Vector2(W * 0.75, H * 0.5)
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


## A polygon table inside the W x H frame. `spots` lists six pockets in order:
## {"v": i} for a pocket in corner i, or {"e": i, "t": 0..1} for one along edge i
## (from vertex i to i + 1). A pocket in `closed` is boarded up.
func build_shape(verts: Array, spots: Array, scale: float = 1.0, closed: Array[int] = [], foot_at: Vector2 = Vector2(W * 0.75, H * 0.5)) -> TableLayout:
	pocket_scale = scale
	closed_pockets = closed
	segments.clear()
	pockets.clear()
	shape = PackedVector2Array(verts)
	foot = foot_at
	var n_v := verts.size()
	var cm := 41.0 * scale
	var sh := 29.0 * scale
	var jl := 25.0
	# Which way is inside: the sign of the polygon's area.
	var area := 0.0
	for i in n_v:
		var a0: Vector2 = verts[i]
		var b0: Vector2 = verts[(i + 1) % n_v]
		area += a0.x * b0.y - b0.x * a0.y
	var flip := -1.0 if area < 0.0 else 1.0
	var normals: Array = []
	for i in n_v:
		var t: Vector2 = ((verts[(i + 1) % n_v] as Vector2) - (verts[i] as Vector2)).normalized()
		normals.append(Vector2(-t.y, t.x) * flip)
	# Gaps cut out of each edge, as distances from its start.
	var cuts: Array = []
	for i in n_v:
		cuts.append([])
	for k in spots.size():
		var sp: Dictionary = spots[k]
		var open := not closed_pockets.has(k)
		if sp.has("v"):
			var vi: int = sp.v
			var v: Vector2 = verts[vi]
			var prev: Vector2 = verts[(vi - 1 + n_v) % n_v]
			var nxt: Vector2 = verts[(vi + 1) % n_v]
			var inward: Vector2 = ((normals[(vi - 1 + n_v) % n_v] as Vector2) + (normals[vi] as Vector2)).normalized()
			_add_pocket(v - inward * 11.0, 29.0 * scale, false, inward)
			if open:
				var len_prev := v.distance_to(prev)
				(cuts[(vi - 1 + n_v) % n_v] as Array).append([len_prev - cm, len_prev])
				(cuts[vi] as Array).append([0.0, cm])
				var ca := v + (prev - v).normalized() * cm
				var cb := v + (nxt - v).normalized() * cm
				var back := -inward * jl
				pockets[k]["mouth"] = PackedVector2Array([ca, ca + back, cb + back, cb])
				_add_seg(ca, ca + back, v)
				_add_seg(cb, cb + back, v)
		else:
			var ei: int = sp.e
			var a: Vector2 = verts[ei]
			var b: Vector2 = verts[(ei + 1) % n_v]
			var tan := (b - a).normalized()
			var n: Vector2 = normals[ei]
			var p := a + (b - a) * float(sp.t)
			_add_pocket(p - n * 14.0, 27.5 * scale, true, n)
			if open:
				var d := a.distance_to(p)
				(cuts[ei] as Array).append([d - sh, d + sh])
				var outp := p - n * 6.0
				pockets[k]["mouth"] = PackedVector2Array([p - tan * sh, p - tan * (sh - 5.0) - n * jl, p + tan * (sh - 5.0) - n * jl, p + tan * sh])
				_add_seg(p - tan * sh, p - tan * (sh - 5.0) - n * jl, outp)
				_add_seg(p + tan * sh, p + tan * (sh - 5.0) - n * jl, outp)
		pockets[k]["closed"] = not open
	# The cushions: each edge minus its gaps.
	for i in n_v:
		var a: Vector2 = verts[i]
		var b: Vector2 = verts[(i + 1) % n_v]
		var length := a.distance_to(b)
		var tan := (b - a) / length
		var gaps: Array = cuts[i]
		gaps.sort_custom(func(x, y): return x[0] < y[0])
		var at := 0.0
		for g in gaps:
			if float(g[0]) > at + 1.0:
				segments.append({"a": a + tan * at, "b": a + tan * float(g[0]), "n": normals[i]})
			at = maxf(at, float(g[1]))
		if at < length - 1.0:
			segments.append({"a": a + tan * at, "b": b, "n": normals[i]})
	return self


## True if p is on the playfield, at least `margin` inside any edge.
func contains(p: Vector2, margin: float = 0.0) -> bool:
	if shape.is_empty():
		return p.x >= margin and p.y >= margin and p.x <= W - margin and p.y <= H - margin
	if not Geometry2D.is_point_in_polygon(p, shape):
		return false
	for i in shape.size():
		var q := Geometry2D.get_closest_point_to_segment(p, shape[i], shape[(i + 1) % shape.size()])
		if q.distance_to(p) < margin:
			return false
	return true


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
