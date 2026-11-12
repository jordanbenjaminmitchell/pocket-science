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
var cue_damp := 1.0          # fraction of speed the cue keeps at its first contact (Stun Master)
var tilt := Vector2.ZERO     # constant acceleration on moving balls (Tilted Table)
var spin_power := 1.0        # strength of draw and follow (Backspin Wax)
var side_power := 1.0        # how much english bends off cushions (Massé Master)
var portal_lock := PackedInt32Array()   # the portal end a ball just came out of
var pull := PackedFloat64Array()        # per-ball pocket pull (Magnetic Imbue)
var bounce := PackedFloat64Array()      # per-ball cushion liveliness; 0 = the table's own (Star balls)
var cue_magnet := 0.0                   # Neodymium Magnet: the rolling cue ball tugs nearby object balls
var first_boost := 1.0                  # Uranium Reactor: the first ball the cue hits leaves this much faster
var anchor8 := false                    # Lead Anchor: the 8 rattles out of pockets while other balls remain
var grip := PackedFloat64Array()        # per-ball cloth friction, 1 = the table's own (Rubidium Rush, Gallium Glide)
const GLASS_BREAK := 700.0              # impact speed that shatters a Glass ball
# One-shot effects from items, cleared by clear_shot_flags() after each shot.
var ghost := -1                         # Ghost Chalk: nothing collides with this ball
var glide := PackedByteArray()          # Polish: no cloth friction until the first hit
var pinned := PackedByteArray()         # Freeze Frame: held still like a post
var extra_wells: Array = []             # Gravity Pebbles: [position, strength]
var seg_e := {}                         # Hooke's Law: cushion segment -> bounce for this shot
var volatile := {}                      # Volatile Imbue: ball number -> true; explodes when first touched
const MAGNET_REACH := 150.0


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
	s.cue_damp = cue_damp
	s.tilt = tilt
	s.spin_power = spin_power
	s.side_power = side_power
	s.portal_lock = portal_lock.duplicate()
	s.pull = pull.duplicate()
	s.bounce = bounce.duplicate()
	s.grip = grip.duplicate()
	s.anchor8 = anchor8
	s.cue_magnet = cue_magnet
	s.first_boost = first_boost
	s.ghost = ghost
	s.glide = glide.duplicate()
	s.pinned = pinned.duplicate()
	s.extra_wells = extra_wells.duplicate(true)
	s.volatile = volatile.duplicate()
	s.seg_e = seg_e.duplicate()
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
	portal_lock.append(-1)
	pull.append(0.0)
	bounce.append(0.0)
	grip.append(1.0)
	glide.append(0)
	pinned.append(0)
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


## How far ball i will still roll on the cloth if nothing interferes, or -1 if
## that cannot be told. Exact integral of the deceleration in _forces.
func stop_distance(i: int) -> float:
	if frictionless or roll_decel <= 0.0 or spin[i] != Vector2.ZERO or (_kind(i) == "comet" and rails[i] == 0) or glide[i] == 1 or not extra_wells.is_empty():
		return -1.0
	var v := vel[i].length()
	var g: float = grip[i] if i < grip.size() else 1.0
	var rd := roll_decel * g
	var dg := drag * g
	if dg < 0.001:
		return v * v / (2.0 * rd)
	return v / dg - rd / (dg * dg) * log(1.0 + dg * v / rd)


## Roll per second the ball shows beyond its travel: pending draw or follow after
## contact, and the tip's spin before the cue ball has reached anything.
func visual_extra_roll(i: int) -> Vector2:
	var extra := spin[i]
	if num[i] == 0 and not cue_contacted and follow != 0.0:
		extra += vel[i] * follow * 1.4
	return extra


## Radians about the vertical per radian rolled. Right english turns clockwise.
func visual_twist(i: int) -> float:
	return -side[i] * 0.7


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
				if alive[j] == 0 or i == ghost or j == ghost:
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
			# Entering a pocket mouth is an exact event too, so a ball cannot
			# clip a jaw later in the same step after it has already dropped.
			for k in layout.pockets.size():
				var pk: Dictionary = layout.pockets[k]
				if pk.closed:
					continue
				var t := _toi_circle(pk.pos - pos[i], -vi, pk.r)
				if t < best_t:
					best_t = t
					kind = 5
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
			5:
				if _rejects(bi, bj):
					_reject(bi, bj)
				else:
					_pot(bi, bj)
			_:
				break
	if remaining > 0.0:
		_advance(remaining)
	time += dt
	_forces(dt)
	_pockets()
	_portals()


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
	# Anchor: only the cue ball can move it; anything else bounces off it.
	if _kind(i) == "anchor" and not cue_j:
		mi = 1.0e6
	if pinned[i] == 1:
		mi = 1.0e6
	if pinned[j] == 1:
		mj = 1.0e6
	glide[i] = 0
	glide[j] = 0
	if _kind(j) == "anchor" and not cue_i:
		mj = 1.0e6
	var jimp := (1.0 + ball_e) * rel / (1.0 / mi + 1.0 / mj)
	vel[i] -= nrm * (jimp / mi)
	vel[j] += nrm * (jimp / mj)
	if (cue_i or cue_j) and not cue_contacted:
		cue_contacted = true
		var c := i if cue_i else j
		spin[c] = pre_dir * follow * pre_speed * 0.62 * spin_power
		if cue_damp < 1.0:
			vel[c] *= cue_damp
			spin[c] *= cue_damp
		if first_boost != 1.0:
			vel[j if cue_i else i] *= first_boost
	events.append({"t": time, "type": "ball", "a": num[i], "b": num[j], "speed": rel})
	for pnd in [i, j]:
		if pinned[pnd] == 1:
			vel[pnd] = Vector2.ZERO
	# Frost stops dead whatever touches it; Glass shatters if struck hard.
	if _kind(i) == "frost":
		vel[j] = Vector2.ZERO
		spin[j] = Vector2.ZERO
	if _kind(j) == "frost":
		vel[i] = Vector2.ZERO
		spin[i] = Vector2.ZERO
	# Volatile: the first touch blows the ball up; scoring counts it as a sink.
	for g in [i, j]:
		if volatile.has(num[g]) and alive[g] == 1:
			volatile.erase(num[g])
			alive[g] = 0
			vel[g] = Vector2.ZERO
			spin[g] = Vector2.ZERO
			events.append({"t": time, "type": "shatter", "a": num[g], "at": pos[g], "exploded": true})
	for g in [i, j]:
		if _kind(g) == "glass" and rel > GLASS_BREAK and alive[g] == 1:
			alive[g] = 0
			vel[g] = Vector2.ZERO
			spin[g] = Vector2.ZERO
			events.append({"t": time, "type": "shatter", "a": num[g], "at": pos[g]})


func _resolve_wall(i: int, nrm: Vector2, _seg: int) -> void:
	var vn := vel[i].dot(nrm)
	if vn >= 0.0:
		return
	var tangent := Vector2(-nrm.y, nrm.x)
	glide[i] = 0
	vel[i] -= nrm * vn * (1.0 + float(seg_e.get(_seg, rail_e_of(i))))
	vel[i] -= tangent * vel[i].dot(tangent) * 0.04
	if side[i] != 0.0:
		vel[i] += tangent * side[i] * -vn * 0.32 * side_power
		side[i] *= 0.45
	# Follow/draw that has not yet been transferred bends off the cushion too.
	spin[i] *= 0.5
	rails[i] += 1
	events.append({"t": time, "type": "rail", "a": num[i], "speed": -vn, "at": pos[i]})


func _resolve_bumper(i: int, k: int) -> void:
	var bp: Dictionary = layout.bumpers[k]
	var nrm: Vector2 = (pos[i] - bp.pos).normalized()
	var vn := vel[i].dot(nrm)
	if vn >= 0.0:
		return
	vel[i] -= nrm * vn * (1.0 + bumper_e)
	events.append({"t": time, "type": "bumper", "a": num[i], "speed": -vn})


func _forces(dt: float) -> void:
	var magnets: Array = []
	for i in pos.size():
		if alive[i] == 1 and num[i] > 15 and _kind(i) == "magnet":
			magnets.append(i)
	# Neodymium Magnet: while the cue ball rolls, it tugs object balls near it.
	var cue_at := Vector2.INF
	if cue_magnet > 0.0:
		var ci := index_of(0)
		if ci >= 0 and alive[ci] == 1 and vel[ci].length_squared() > 2500.0:
			cue_at = pos[ci]
	for i in pos.size():
		if alive[i] == 0:
			continue
		var v := vel[i]
		if cue_at != Vector2.INF and num[i] != 0 and pinned[i] == 0:
			var cd := cue_at - pos[i]
			var cl := cd.length()
			if cl < MAGNET_REACH and cl > R * 2.0:
				v += cd / cl * 3200.0 * cue_magnet * (1.0 - cl / MAGNET_REACH) * dt
		if spin[i] != Vector2.ZERO:
			var dv := spin[i] * minf(1.0, dt * 7.0)
			v += dv
			spin[i] -= dv
			if spin[i].length_squared() < 4.0:
				v += spin[i]
				spin[i] = Vector2.ZERO
		if v == Vector2.ZERO:
			continue
		if tilt != Vector2.ZERO:
			v += tilt * dt
		for mg in magnets:
			if mg != i:
				var md: Vector2 = pos[mg] - pos[i]
				var ml := md.length()
				if ml < MAGNET_REACH and ml > R * 2.0:
					v += md / ml * 2600.0 * (1.0 - ml / MAGNET_REACH) * dt
		if well_strength != 0.0:
			var d := well_pos - pos[i]
			var dist := maxf(d.length(), 40.0)
			v += d / dist * (well_strength * 9000.0 / dist) * dt
		var pp := maxf(pocket_pull, pull[i])
		if pp > 0.0:
			for p in layout.pockets:
				if p.closed:
					continue
				var d: Vector2 = p.pos - pos[i]
				var dl := d.length()
				if dl < 110.0:
					v += d / dl * pp * (110.0 - dl) * 9.0 * dt
		for w in extra_wells:
			var wd: Vector2 = w[0] - pos[i]
			var wl := maxf(wd.length(), 30.0)
			if wl < 260.0:
				v += wd / wl * (float(w[1]) * 9000.0 / wl) * dt
		if not frictionless and glide[i] == 0 and not (_kind(i) == "comet" and rails[i] == 0):
			var sp := v.length()
			var ns := sp - (roll_decel + drag * sp) * dt * (grip[i] if i < grip.size() else 1.0)
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
				if _rejects(i, k):
					_reject(i, k)
				else:
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


func clear_shot_flags() -> void:
	ghost = -1
	seg_e = {}
	glide.fill(0)
	pinned.fill(0)
	extra_wells.clear()


func _kind(i: int) -> String:
	return Catalog.kind_of(num[i]) if num[i] > 15 else ""


func rail_e_of(i: int) -> float:
	return bounce[i] if i < bounce.size() and bounce[i] > 0.0 else rail_e


## Moon balls bounce off corner pockets, Sun balls off side pockets.
func _rejects(i: int, k: int) -> bool:
	var kind := _kind(i)
	var side_pocket := k == 1 or k == 4
	if anchor8 and num[i] == 8 and object_balls_left() > 1:
		return true
	return (kind == "moon" and not side_pocket) or (kind == "sun" and side_pocket)


func _reject(i: int, k: int) -> void:
	var n: Vector2 = (pos[i] - layout.pockets[k].pos).normalized()
	var vn := vel[i].dot(n)
	if vn < 0.0:
		vel[i] -= n * vn * 1.6
	pos[i] = layout.pockets[k].pos + n * (layout.pockets[k].r + 0.05)
	events.append({"t": time, "type": "rail", "a": num[i], "speed": -vn, "at": pos[i]})


## Portal end e: pair e / 2, end e % 2.
func portal_end(e: int) -> Vector2:
	var pt: Dictionary = layout.portals[e / 2]
	return pt.a if e % 2 == 0 else pt.b


## Where a ball that touched portal end e at point p comes out.
func portal_exit(e: int, p: Vector2) -> Vector2:
	return portal_end(e ^ 1) + (p - portal_end(e))


func _portals() -> void:
	if layout.portals.is_empty():
		return
	for i in pos.size():
		if alive[i] == 0:
			continue
		if portal_lock[i] >= 0:
			if pos[i].distance_to(portal_end(portal_lock[i])) > TableLayout.PORTAL_R + 1.0:
				portal_lock[i] = -1
			continue
		if vel[i] == Vector2.ZERO:
			continue
		for e in layout.portals.size() * 2:
			if pos[i].distance_to(portal_end(e)) < TableLayout.PORTAL_R:
				var dest := portal_exit(e, pos[i])
				if is_clear_spot(dest, i):
					pos[i] = dest
					portal_lock[i] = e ^ 1
					events.append({"t": time, "type": "portal", "a": num[i]})
				break


func _pot(i: int, k: int) -> void:
	alive[i] = 0
	var speed := vel[i].length()
	vel[i] = Vector2.ZERO
	spin[i] = Vector2.ZERO
	events.append({"t": time, "type": "pocket", "a": num[i], "pocket": k, "rails": rails[i], "speed": speed, "at": pos[i]})
	if Catalog.kind_of(num[i]) == "bomb":
		# The nearest ball goes down with it, never the cue ball or the 8.
		var best := -1
		var bd := INF
		for j in pos.size():
			if alive[j] == 1 and num[j] != 0 and num[j] != 8:
				var dd := pos[j].distance_squared_to(pos[i])
				if dd < bd:
					bd = dd
					best = j
		if best >= 0:
			_pot(best, k)


## ---------------------------------------------------------------- guideline casts
## Sweep a single ball (centre p, unit direction d) through the *static* table.
## Returns {t, kind: "ball"/"rail"/"bumper"/"pocket"/"none", hit (ball index),
## normal, point}. `ignore` is a ball index to skip (the moving ball itself).
func cast(p: Vector2, d: Vector2, ignore: int, max_len: float = 3000.0, ignore2: int = -1, use_portals: bool = true) -> Dictionary:
	var best_t := max_len
	var res := {"kind": "none", "hit": -1, "normal": Vector2.ZERO}
	for j in pos.size():
		if j == ignore or j == ignore2 or alive[j] == 0 or j == ghost or (ignore >= 0 and ignore == ghost):
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
			if ignore >= 0 and _rejects(ignore, k):
				res = {"kind": "rail", "hit": -1, "normal": (p + d * t - pk.pos).normalized()}
			else:
				res = {"kind": "pocket", "hit": k, "normal": Vector2.ZERO}
	if use_portals:
		for k in layout.portals.size() * 2:
			var t := _toi_circle(portal_end(k) - p, -d, TableLayout.PORTAL_R)
			if t < best_t:
				best_t = t
				res = {"kind": "portal", "hit": k, "normal": Vector2.ZERO}
	res["t"] = best_t
	res["point"] = p + d * best_t
	return res


func is_clear_spot(p: Vector2, ignore: int = -1) -> bool:
	if not layout.contains(p, R):
		return false
	for j in pos.size():
		if j != ignore and alive[j] == 1 and pos[j].distance_to(p) < R * 2.05:
			return false
	for bp in layout.bumpers:
		if bp.pos.distance_to(p) < bp.r + R * 1.05:
			return false
	return true
