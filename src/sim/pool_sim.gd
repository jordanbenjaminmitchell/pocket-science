class_name PoolSim
extends RefCounted
## Deterministic, event-ordered pool physics.
##
## Each fixed step finds the earliest time of impact (ball-ball, ball-cushion,
## ball-knuckle, ball-bumper), advances everything to that instant, resolves it
## and repeats. Because contacts are resolved at the exact touching instant, the
## geometric guideline (ghost ball / line of centres) matches the real outcome.

const R := TableLayout.R
const STEP := 1.0 / 240.0
const STOP_SPEED := 4.0
const INF := 1.0e20

var layout: TableLayout
var pos := PackedVector2Array()
var vel := PackedVector2Array()
var num := PackedInt32Array()      # 0 = cue ball, 1..15 object balls
var alive := PackedByteArray()
var mass := PackedFloat64Array()
var spin := PackedVector2Array()   # pending follow/draw velocity (cue only)
var side := PackedFloat64Array()   # side english, consumed by cushions
var rails := PackedInt32Array()    # cushions touched this shot, per ball
var ball_e := 0.97
var rail_e := 0.8
var bumper_e := 1.05
var roll_decel := 170.0
var drag := 0.1
var frictionless := false
var well_pos := Vector2.ZERO
var well_strength := 0.0
var pocket_pull := 0.0
var time := 0.0
var events: Array[Dictionary] = []
var follow := 0.0
var cue_contacted := false


func _init(l: TableLayout = null) -> void:
	layout = l


func clone() -> PoolSim:
	var s := PoolSim.new(layout)
	s.pos = pos.duplicate()
	s.vel = vel.duplicate()
	s.num = num.duplicate()
	s.alive = alive.duplicate()
	s.mass = mass.duplicate()
	s.spin = spin.duplicate()
	s.side = side.duplicate()
	s.rails = rails.duplicate()
	s.ball_e = ball_e
	s.rail_e = rail_e
	s.bumper_e = bumper_e
	s.roll_decel = roll_decel
	s.drag = drag
	s.frictionless = frictionless
	s.well_pos = well_pos
	s.well_strength = well_strength
	s.pocket_pull = pocket_pull
	s.follow = follow
	s.cue_contacted = cue_contacted
	return s


func add_ball(number: int, p: Vector2, m: float = 1.0) -> int:
	pos.append(p)
	vel.append(Vector2.ZERO)
	num.append(number)
	alive.append(1)
	mass.append(m)
	spin.append(Vector2.ZERO)
	side.append(0.0)
	rails.append(0)
	return pos.size() - 1


func count() -> int:
	return pos.size()


func index_of(number: int) -> int:
	for i in pos.size():
		if num[i] == number:
			return i
	return -1


func object_balls_left() -> int:
	var c := 0
	for i in pos.size():
		if alive[i] == 1 and num[i] != 0:
			c += 1
	return c


func moving() -> bool:
	for i in pos.size():
		if alive[i] == 1 and (vel[i] != Vector2.ZERO or spin[i] != Vector2.ZERO):
			return true
	return false


func strike(dir: Vector2, speed: float, follow_amount: float, side_amount: float) -> void:
	var c := index_of(0)
	events.clear()
	time = 0.0
	for i in rails.size():
		rails[i] = 0
	cue_contacted = false
	follow = clampf(follow_amount, -1.0, 1.0)
	vel[c] = dir.normalized() * speed
	side[c] = clampf(side_amount, -1.0, 1.0)
	spin[c] = Vector2.ZERO


## Run until everything stops (or the time cap). Returns the event log.
func settle(max_time: float = 30.0) -> Array[Dictionary]:
	while moving() and time < max_time:
		step(STEP)
	return events


func step(dt: float) -> void:
	var remaining := dt
	var guard := 0
	while remaining > 1.0e-9 and guard < 48:
		guard += 1
		var best_t := remaining
		var kind := 0      # 0 none, 1 ball, 2 seg face, 3 point (knuckle), 4 bumper
		var bi := -1
		var bj := -1
		var bn := Vector2.ZERO
		var n := pos.size()
		for i in n:
			if alive[i] == 0:
				continue
			var vi := vel[i]
			var mv := vi != Vector2.ZERO
			for j in range(i + 1, n):
				if alive[j] == 0:
					continue
				if not mv and vel[j] == Vector2.ZERO:
					continue
				var t := _toi_circle(pos[j] - pos[i], vel[j] - vi, R * 2.0)
				if t < best_t:
					best_t = t
					kind = 1
					bi = i
					bj = j
			if not mv:
				continue
			for s in layout.segments.size():
				var seg: Dictionary = layout.segments[s]
				var nrm: Vector2 = seg.n
				var a: Vector2 = seg.a
				var b: Vector2 = seg.b
				var vn := vi.dot(nrm)
				if vn < 0.0:
					var d0 := (pos[i] - a).dot(nrm)
					if d0 > R * 0.25:
						var t := (d0 - R) / -vn
						if t < 0.0:
							t = 0.0
						if t < best_t:
							var q := pos[i] + vi * t
							var u := b - a
							var pr := (q - a).dot(u) / u.length_squared()
							if pr >= 0.0 and pr <= 1.0:
								best_t = t
								kind = 2
								bi = i
								bn = nrm
				for e in [a, b]:
					var t := _toi_circle(e - pos[i], -vi, R)
					if t < best_t:
						best_t = t
						kind = 3
						bi = i
						bj = s
						bn = e
			for k in layout.bumpers.size():
				var bp: Dictionary = layout.bumpers[k]
				var t := _toi_circle(bp.pos - pos[i], -vi, R + bp.r)
				if t < best_t:
					best_t = t
					kind = 4
					bi = i
					bj = k
		_advance(best_t)
		remaining -= best_t
		match kind:
			1:
				_resolve_balls(bi, bj)
			2:
				_resolve_wall(bi, bn, -1)
			3:
				var nn := (pos[bi] - bn).normalized()
				_resolve_wall(bi, nn, bj)
			4:
				_resolve_bumper(bi, bj)
			_:
				break
	if remaining > 0.0:
		_advance(remaining)
	time += dt
	_forces(dt)
	_pockets()


func _advance(t: float) -> void:
	if t <= 0.0:
		return
	for i in pos.size():
		if alive[i] == 1 and vel[i] != Vector2.ZERO:
			pos[i] += vel[i] * t


## Earliest t >= 0 where |p + v t| == dist, approaching only. p is relative position.
static func _toi_circle(p: Vector2, v: Vector2, dist: float) -> float:
	var b := p.dot(v)
	if b >= 0.0:
		return INF
	var a := v.length_squared()
	if a < 1.0e-12:
		return INF
	var c := p.length_squared() - dist * dist
	if c <= 0.0:
		return 0.0
	var disc := b * b - a * c
	if disc < 0.0:
		return INF
	return (-b - sqrt(disc)) / a


func _resolve_balls(i: int, j: int) -> void:
	var nrm := (pos[j] - pos[i]).normalized()
	var rel := (vel[i] - vel[j]).dot(nrm)
	if rel <= 0.0:
		return
	var cue_i := num[i] == 0
	var cue_j := num[j] == 0
	var pre_dir := Vector2.ZERO
	var pre_speed := 0.0
	if (cue_i or cue_j) and not cue_contacted:
		var c := i if cue_i else j
		pre_speed = vel[c].length()
		pre_dir = vel[c] / maxf(pre_speed, 0.001)
	var mi := mass[i]
	var mj := mass[j]
	var jimp := (1.0 + ball_e) * rel / (1.0 / mi + 1.0 / mj)
	vel[i] -= nrm * (jimp / mi)
	vel[j] += nrm * (jimp / mj)
	if (cue_i or cue_j) and not cue_contacted:
		cue_contacted = true
		var c := i if cue_i else j
		spin[c] = pre_dir * follow * pre_speed * 0.62
	events.append({"t": time, "type": "ball", "a": num[i], "b": num[j], "speed": rel})


func _resolve_wall(i: int, nrm: Vector2, _seg: int) -> void:
	var vn := vel[i].dot(nrm)
	if vn >= 0.0:
		return
	var tangent := Vector2(-nrm.y, nrm.x)
	vel[i] -= nrm * vn * (1.0 + rail_e)
	vel[i] -= tangent * vel[i].dot(tangent) * 0.04
	if side[i] != 0.0:
		vel[i] += tangent * side[i] * -vn * 0.32
		side[i] *= 0.45
	# Follow/draw that has not yet been transferred bends off the cushion too.
	spin[i] *= 0.5
	rails[i] += 1
	events.append({"t": time, "type": "rail", "a": num[i], "speed": -vn})


func _resolve_bumper(i: int, k: int) -> void:
	var bp: Dictionary = layout.bumpers[k]
	var nrm: Vector2 = (pos[i] - bp.pos).normalized()
	var vn := vel[i].dot(nrm)
	if vn >= 0.0:
		return
	vel[i] -= nrm * vn * (1.0 + bumper_e)
	events.append({"t": time, "type": "bumper", "a": num[i], "speed": -vn})


func _forces(dt: float) -> void:
	for i in pos.size():
		if alive[i] == 0:
			continue
		var v := vel[i]
		if spin[i] != Vector2.ZERO:
			var dv := spin[i] * minf(1.0, dt * 7.0)
			v += dv
			spin[i] -= dv
			if spin[i].length_squared() < 4.0:
				v += spin[i]
				spin[i] = Vector2.ZERO
		if v == Vector2.ZERO:
			continue
		if well_strength != 0.0:
			var d := well_pos - pos[i]
			var dist := maxf(d.length(), 40.0)
			v += d / dist * (well_strength * 9000.0 / dist) * dt
		if pocket_pull > 0.0:
			for p in layout.pockets:
				if p.closed:
					continue
				var d: Vector2 = p.pos - pos[i]
				var dl := d.length()
				if dl < 110.0:
					v += d / dl * pocket_pull * (110.0 - dl) * 9.0 * dt
		if not frictionless:
			var sp := v.length()
			var ns := sp - (roll_decel + drag * sp) * dt
			if ns <= STOP_SPEED and spin[i] == Vector2.ZERO:
				v = Vector2.ZERO
			elif ns <= 0.0:
				v = Vector2.ZERO
			else:
				v *= ns / sp
		vel[i] = v


func _pockets() -> void:
	for i in pos.size():
		if alive[i] == 0:
			continue
		var p := pos[i]
		for k in layout.pockets.size():
			var pk: Dictionary = layout.pockets[k]
			if pk.closed:
				continue
			if p.distance_squared_to(pk.pos) < pk.r * pk.r:
				_pot(i, k)
				break
		if alive[i] == 1 and (p.x < -50.0 or p.y < -50.0 or p.x > TableLayout.W + 50.0 or p.y > TableLayout.H + 50.0):
			var best := 0
			var bd := INF
			for k in layout.pockets.size():
				var d := p.distance_squared_to(layout.pockets[k].pos)
				if d < bd:
					bd = d
					best = k
			_pot(i, best)


func _pot(i: int, k: int) -> void:
	alive[i] = 0
	var speed := vel[i].length()
	vel[i] = Vector2.ZERO
	spin[i] = Vector2.ZERO
	events.append({"t": time, "type": "pocket", "a": num[i], "pocket": k, "rails": rails[i], "speed": speed, "at": pos[i]})


## ---------------------------------------------------------------- guideline casts
## Sweep a single ball (centre p, unit direction d) through the *static* table.
## Returns {t, kind: "ball"/"rail"/"bumper"/"pocket"/"none", hit (ball index),
## normal, point}. `ignore` is a ball index to skip (the moving ball itself).
func cast(p: Vector2, d: Vector2, ignore: int, max_len: float = 3000.0) -> Dictionary:
	var best_t := max_len
	var res := {"kind": "none", "hit": -1, "normal": Vector2.ZERO}
	for j in pos.size():
		if j == ignore or alive[j] == 0:
			continue
		var t := _toi_circle(pos[j] - p, -d, R * 2.0)
		if t < best_t:
			best_t = t
			res = {"kind": "ball", "hit": j, "normal": (pos[j] - (p + d * t)).normalized()}
	for seg in layout.segments:
		var nrm: Vector2 = seg.n
		var sa: Vector2 = seg.a
		var sb: Vector2 = seg.b
		var vn := d.dot(nrm)
		if vn < 0.0:
			var d0 := (p - sa).dot(nrm)
			if d0 > R * 0.25:
				var t := maxf((d0 - R) / -vn, 0.0)
				if t < best_t:
					var q := p + d * t
					var u: Vector2 = sb - sa
					var pr := (q - sa).dot(u) / u.length_squared()
					if pr >= 0.0 and pr <= 1.0:
						best_t = t
						res = {"kind": "rail", "hit": -1, "normal": nrm}
		for e: Vector2 in [sa, sb]:
			var t := _toi_circle(e - p, -d, R)
			if t < best_t:
				best_t = t
				res = {"kind": "rail", "hit": -1, "normal": (p + d * t - e).normalized()}
	for bp in layout.bumpers:
		var bpp: Vector2 = bp.pos
		var t := _toi_circle(bpp - p, -d, R + float(bp.r))
		if t < best_t:
			best_t = t
			res = {"kind": "bumper", "hit": -1, "normal": (p + d * t - bpp).normalized()}
	for k in layout.pockets.size():
		var pk: Dictionary = layout.pockets[k]
		if pk.closed:
			continue
		var t := _toi_circle(pk.pos - p, -d, pk.r)
		if t < best_t:
			best_t = t
			res = {"kind": "pocket", "hit": k, "normal": Vector2.ZERO}
	res["t"] = best_t
	res["point"] = p + d * best_t
	return res


func is_clear_spot(p: Vector2, ignore: int = -1) -> bool:
	if p.x < R or p.y < R or p.x > TableLayout.W - R or p.y > TableLayout.H - R:
		return false
	for j in pos.size():
		if j != ignore and alive[j] == 1 and pos[j].distance_to(p) < R * 2.05:
			return false
	for bp in layout.bumpers:
		if bp.pos.distance_to(p) < bp.r + R * 1.05:
			return false
	return true
