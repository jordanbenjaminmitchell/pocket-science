class_name BoardFeatures
extends RefCounted
## Sharks and moving parts on the science boards. Everything here is plain data
## in RunState.board (so it saves with the table) plus static functions:
##
##   start(id, rng)          the board's opening state
##   bumpers(state)          solid circles for TableLayout: live Sharks, posts, the pendulum bob
##   walls(state)            free-standing two-sided walls: the Sweeper, ridges, islands, the Lever
##   segments(state)         one-way walls and the Demon's gates, as layout segments
##   portals(state)          linked portal pairs (Einstein–Rosen Bridge, Möbius Strip)
##   closed(state)           pockets a Card Sharp is sitting in
##   after_shot(...)         Sharks take hits, move, swallow balls and join; parts step on
##
## During a shot nothing here moves: a Shark is a still, solid bumper, so the
## prediction line is exact. Everything moves between shots, on a fixed
## pattern from the run's seed. Force fields (Coriolis, Gulf Stream) act during
## the shot through PoolSim and are set up in RunState.apply_physics.

const W := TableLayout.W
const H := TableLayout.H
const R := TableLayout.R

## Size (bumper radius), health and swallow rhythm for each Shark.
const SHARKS := {
	"pool": {"r": 24.0, "hp": 3, "every": 3},
	"sharp": {"r": 22.0, "hp": 2, "every": 0},
	"hammer": {"r": 26.0, "hp": 3, "every": 0},
	"loan": {"r": 22.0, "hp": 2, "every": 0},
	"leech": {"r": 0.0, "hp": 1, "every": 0},
	"white": {"r": 34.0, "hp": 8, "every": 2},
}
const KO_PAY := 3            # $ for knocking out a Shark
const SKIM := 0.15           # the Loan Shark's cut of every sink
const SWEEP_STEP := PI / 6.0 # the Clockwork Sweeper turns one clock hour per shot
const SWEEP_LEN := 170.0
const SHUTTLE_STEPS := 6     # Harmonic Oscillator: a full swing takes six shots
const BOB_R := 22.0
const HAMMER_ROUTE := [Vector2(220, 130), Vector2(780, 370), Vector2(780, 130), Vector2(220, 370)]
const DEMON_SPEED := 520.0   # Maxwell's Demon: the speed that splits fast from slow
const MEISSNER_POSTS := [Vector2(430, 140), Vector2(430, 360), Vector2(600, 110), Vector2(600, 390)]
const ESCAPE_WELLS := [Vector2(370, 170), Vector2(650, 330)]
const LORENTZ_RECT := Rect2(330, 110, 340, 280)
const LEVER_PIVOT := Vector2(500, 405)
const LEVER_HALF := 120.0
const SPIRAL_DRAIN := Vector2(500, 385)
const RIDGE_SLIDE := 180.0


static func has_features(id: String) -> bool:
	return id in ["smoke", "cramped", "final", "foucault", "elements", "posts", "spring_st", "venturi", "erbridge",
		"membrane", "galton", "sierpinski", "mobius", "maxwell", "spiral", "meissner", "tesla", "tectonic", "lattice", "lever"]


static func start(id: String, rng: RandomNumberGenerator, hot: int) -> Dictionary:
	var s := {"id": id, "shots": 0, "sharks": []}
	match id:
		"smoke":
			s.sharks.append(_shark("pool", Vector2(W * 0.62, H * 0.25)))
			s["spawned"] = false
		"cramped":
			# The Card Sharp sits in a corner pocket's mouth, guarded by two posts.
			var k: int = hot if hot in [0, 2, 3, 5] else [0, 2, 3, 5][rng.randi_range(0, 3)]
			s["blocked"] = k
			s.sharks.append(_shark("sharp", _mouth(k, 34.0)))
		"final":
			s.sharks.append(_shark("white", Vector2(W * 0.5, H * 0.22)))
			s["joined"] = false
			s["leech_ball"] = -1
		"foucault":
			s.sharks.append(_shark("hammer", HAMMER_ROUTE[0]))
			s["route"] = 0
			s["swing"] = PI * 0.5 # the pendulum's swing plane turns a little every shot
			s["bob"] = 1.0        # where the bob is along its swing, -1 to 1: it starts at the side, clear of the break
			s["bob_dir"] = -1.0
		"elements":
			s["sweep"] = 0
		"posts":
			s["shuttle"] = 0
		"spring_st":
			s["charged"] = false  # Capacitor: the bottom rail holds a charge
		"tectonic":
			s["slide"] = 0
		"lever":
			s["tilt"] = 1.0 if rng.randf() < 0.5 else -1.0
	return s


static func _shark(kind: String, p: Vector2) -> Dictionary:
	var d: Dictionary = SHARKS[kind]
	return {"kind": kind, "x": p.x, "y": p.y, "hp": int(d.hp), "max": int(d.hp), "ko": false, "heading": 0.0}


## Inside the mouth of corner pocket k, d units towards the table.
static func _mouth(k: int, d: float) -> Vector2:
	var corners := {0: Vector2(0, 0), 2: Vector2(W, 0), 3: Vector2(0, H), 5: Vector2(W, H)}
	var c: Vector2 = corners.get(k, Vector2(0, 0))
	return c + (Vector2(W, H) * 0.5 - c).normalized() * d


static func shark_pos(sh: Dictionary) -> Vector2:
	return Vector2(float(sh.x), float(sh.y))


## Solid circles for this table: {pos, r} plus "shark": index, "post" or "bob".
static func bumpers(s: Dictionary) -> Array:
	var out: Array = []
	var sharks: Array = s.get("sharks", [])
	for i in sharks.size():
		var sh: Dictionary = sharks[i]
		var r := float(SHARKS[sh.kind].r)
		if sh.ko or r <= 0.0:
			continue
		out.append({"pos": shark_pos(sh), "r": r, "shark": i})
	match String(s.get("id", "")):
		"cramped":
			var k := int(s.get("blocked", 0))
			var m := _mouth(k, 70.0)
			var n := (Vector2(W, H) * 0.5 - _mouth(k, 0.0)).normalized().orthogonal()
			for side in [-1.0, 1.0]:
				out.append({"pos": m + n * side * 46.0, "r": 14.0, "post": true})
		"posts":
			# Two posts on springs, swinging opposite ways along their slots.
			var f := shuttle_f(s)
			out.append({"pos": Vector2(W * 0.5 + f * 150.0, H * 0.27), "r": 20.0, "post": true})
			out.append({"pos": Vector2(W * 0.5 - f * 150.0, H * 0.73), "r": 20.0, "post": true})
		"foucault":
			out.append({"pos": bob_pos(s), "r": BOB_R, "bob": true})
		"galton":
			# Pegs in Pascal's-triangle rows above the break line, and a row below.
			for row in 3:
				for k in row + 1:
					out.append({"pos": Vector2(500.0 + (k - row * 0.5) * 64.0, 80.0 + row * 55.0), "r": 9.0, "post": true, "peg": true})
			for k in 3:
				out.append({"pos": Vector2(436.0 + k * 64.0, 400.0), "r": 9.0, "post": true, "peg": true})
		"meissner":
			for p: Vector2 in MEISSNER_POSTS:
				out.append({"pos": p, "r": 16.0, "post": true, "magnet": true})
		"lattice":
			for row in 4:
				var y: float = [120.0, 185.0, 315.0, 380.0][row]
				for col in 5:
					out.append({"pos": Vector2(380.0 + col * 70.0 + (35.0 if row % 2 == 1 else 0.0), y), "r": 8.0, "post": true, "atom": true})
		"lever":
			out.append({"pos": LEVER_PIVOT, "r": 9.0, "post": true, "fulcrum": true})
	return out


static func shuttle_f(s: Dictionary) -> float:
	return sin(TAU * float(s.get("shuttle", 0)) / SHUTTLE_STEPS)


static func bob_pos(s: Dictionary) -> Vector2:
	var plane := Vector2.from_angle(float(s.get("swing", 0.0)))
	return Vector2(W * 0.5, H * 0.5) + plane * float(s.get("bob", 0.0)) * 190.0


## Free-standing walls as [a, b]: the Sweeper, a clock hand from the centre.
static func walls(s: Dictionary) -> Array:
	match String(s.get("id", "")):
		"elements":
			var c := Vector2(W * 0.5, H * 0.5)
			var a := -PI * 0.5 + SWEEP_STEP * float(s.get("sweep", 0))
			return [[c + Vector2.from_angle(a) * 30.0, c + Vector2.from_angle(a) * SWEEP_LEN]]
		"venturi":
			# Two angled rails form the funnel's throat.
			return [[Vector2(420, 70), Vector2(565, 205)], [Vector2(420, 430), Vector2(565, 295)]]
		"sierpinski":
			var out: Array = []
			for tri: Array in sierpinski_islands():
				for i in 3:
					out.append([tri[i], tri[(i + 1) % 3]])
			return out
		"spiral":
			var pts := spiral_points()
			var out: Array = []
			for i in pts.size() - 1:
				out.append([pts[i], pts[i + 1]])
			return out
		"tectonic":
			var out: Array = []
			for r: Array in ridges(s):
				out.append(r)
			return out
		"maxwell":
			return [[Vector2(500, 55), Vector2(500, 195)], [Vector2(500, 305), Vector2(500, 445)]]
		"lever":
			return [lever_ends(s)]
	return []


## One-way walls: a layout segment with its play-side normal. A ball meets it only
## from the front. Maxwell's gates also carry "fast" or "slow" (see PoolSim._gate_open).
static func segments(s: Dictionary) -> Array:
	match String(s.get("id", "")):
		"membrane":
			return [{"a": Vector2(600, 40), "b": Vector2(600, 460), "n": Vector2(1, 0), "membrane": true}]
		"maxwell":
			return [{"a": Vector2(500, 195), "b": Vector2(500, 305), "n": Vector2(-1, 0), "fast": DEMON_SPEED},
				{"a": Vector2(500, 305), "b": Vector2(500, 195), "n": Vector2(1, 0), "slow": DEMON_SPEED}]
	return []


## Linked portal pairs as [a, b].
static func portals(s: Dictionary) -> Array:
	match String(s.get("id", "")):
		"erbridge":
			return [[Vector2(330, 110), Vector2(700, 390)]]
		"mobius":
			# Out of the left rail, in through the right one, upside down.
			return [[Vector2(18, 150), Vector2(982, 350)], [Vector2(18, 350), Vector2(982, 150)]]
	return []


## Sierpinski Triangle: three triangular islands.
static func sierpinski_islands() -> Array:
	var holes := [
		[Vector2(250, 62.5), Vector2(250, 187.5), Vector2(0, 125)],
		[Vector2(250, 437.5), Vector2(250, 312.5), Vector2(0, 375)],
		[Vector2(875, 218.75), Vector2(875, 281.25), Vector2(750, 250)],
	]
	var out: Array = []
	for h: Array in holes:
		var c: Vector2 = (h[0] + h[1] + h[2]) / 3.0
		var k := 0.55 if c.x < 500.0 else 0.75
		out.append([c + (h[0] - c) * k, c + (h[1] - c) * k, c + (h[2] - c) * k])
	return out


## Golden Spiral: the arm's points, from the outside in towards the drain.
static func spiral_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var b := log(2.0) / TAU   # the gap between turns halves every turn
	for i in 17:
		var th := TAU * i / 16.0
		pts.append(SPIRAL_DRAIN + Vector2.from_angle(PI + th) * 92.0 * exp(-b * th))
	return pts


## Tectonic Plates: two fault ridges sliding opposite ways.
static func ridges(s: Dictionary) -> Array:
	var off := sin(TAU * float(s.get("slide", 0)) / 6.0) * RIDGE_SLIDE
	return [[Vector2(420 + off, 170), Vector2(580 + off, 170)], [Vector2(420 - off, 330), Vector2(580 - off, 330)]]


## The Lever's see-saw rail, tipped down towards the end hit last.
static func lever_ends(s: Dictionary) -> Array:
	var a := float(s.get("tilt", 1.0)) * 0.3
	var d := Vector2.from_angle(a) * LEVER_HALF
	return [LEVER_PIVOT - d - Vector2(0, 12), LEVER_PIVOT + d - Vector2(0, 12)]


## Tesla Coil: does the coil fire on this shot? Every third shot.
static func coil_on(s: Dictionary) -> bool:
	return String(s.get("id", "")) == "tesla" and int(s.get("shots", 0)) % 3 == 2


static func sweep_angle(s: Dictionary) -> float:
	return -PI * 0.5 + SWEEP_STEP * float(s.get("sweep", 0))


## Pockets closed by a Card Sharp sitting in them.
static func closed(s: Dictionary) -> Array[int]:
	var c: Array[int] = []
	if String(s.get("id", "")) == "cramped":
		for sh: Dictionary in s.get("sharks", []):
			if sh.kind == "sharp" and not sh.ko:
				c.append(int(s.blocked))
	return c


static func loan_alive(s: Dictionary) -> bool:
	for sh: Dictionary in s.get("sharks", []):
		if sh.kind == "loan" and not sh.ko:
			return true
	return false


static func leech_ball(s: Dictionary) -> int:
	for sh: Dictionary in s.get("sharks", []):
		if sh.kind == "leech" and not sh.ko:
			return int(s.get("leech_ball", -1))
	return -1


## Capacitor: is the bottom rail charged for this shot?
static func charged(s: Dictionary) -> bool:
	return bool(s.get("charged", false))


## After a shot: damage, knock-outs, swallowing, new Sharks and the moving parts'
## next step. `bumper_index` maps a layout bumper index to its Shark (or -1).
## Returns {hits: [i], ko: [kind], swallowed: [n], joined: [kind], money: $, moved: bool}.
static func after_shot(s: Dictionary, sim: PoolSim, events: Array, rng: RandomNumberGenerator) -> Dictionary:
	var out := {"hits": [], "ko": [], "swallowed": [], "joined": [], "money": 0, "moved": false}
	if s.is_empty():
		return out
	s.shots = int(s.get("shots", 0)) + 1
	var sharks: Array = s.get("sharks", [])
	# Damage: every ball that hit a Shark this shot.
	for e: Dictionary in events:
		if e.type == "bumper" and e.has("k"):
			var bp: Dictionary = sim.layout.bumpers[int(e.k)] if int(e.k) < sim.layout.bumpers.size() else {}
			if bp.has("shark"):
				_hurt(sharks, int(bp.shark), out)
		elif e.type == "ball" and (e.a == 0 or e.b == 0):
			# The cue ball striking the leeched ball knocks the Leech off.
			var lb := leech_ball(s)
			if lb > 0 and (e.a == lb or e.b == lb):
				for i in sharks.size():
					if sharks[i].kind == "leech" and not sharks[i].ko:
						_hurt(sharks, i, out)
		elif e.type == "rail" and e.has("at") and String(s.id) == "spring_st":
			var y := (e.at as Vector2).y
			if y < 20.0:
				s.charged = true
			elif y > H - 20.0 and bool(s.get("charged", false)):
				s["spent"] = true
	if bool(s.get("spent", false)):
		s.charged = false
		s.erase("spent")
	for k in out.ko:
		out.money += KO_PAY
	# The Sharks act.
	for i in sharks.size():
		var sh: Dictionary = sharks[i]
		if sh.ko:
			continue
		var every := int(SHARKS[sh.kind].every)
		if every > 0 and int(s.shots) % every == 0:
			var n := _swallow(sh, sim)
			if n > 0:
				out.swallowed.append(n)
		match String(sh.kind):
			"pool", "white":
				_circle_ball(sh, sim, int(s.shots))
				out.moved = true
			"hammer":
				s.route = (int(s.route) + 1) % HAMMER_ROUTE.size()
				_charge(sh, HAMMER_ROUTE[int(s.route)], sim)
				out.moved = true
	# Newcomers.
	match String(s.id):
		"smoke":
			if not bool(s.get("spawned", false)) and int(s.shots) >= 4 and not sharks[0].ko:
				s.spawned = true
				var p := _clear_spot(sim, Vector2(W * 0.35, H * 0.75), 26.0)
				if p != Vector2.INF:
					sharks.append(_shark("pool", p))
					out.joined.append("pool")
					out.moved = true
		"final":
			var white: Dictionary = sharks[0]
			if not bool(s.get("joined", false)) and (white.ko or int(white.hp) * 2 <= int(white.max)):
				s.joined = true
				var p := _clear_spot(sim, Vector2(W * 0.2, H * 0.5), 24.0)
				if p != Vector2.INF:
					sharks.append(_shark("loan", p))
					out.joined.append("loan")
				var target := _leech_target(sim)
				if target > 0:
					s.leech_ball = target
					sharks.append(_shark("leech", Vector2.ZERO))
					out.joined.append("leech")
				out.moved = true
	# The moving parts step.
	match String(s.id):
		"elements":
			s.sweep = (int(s.get("sweep", 0)) + 1) % 12
			out.moved = true
		"posts":
			s.shuttle = (int(s.get("shuttle", 0)) + 1) % SHUTTLE_STEPS
			out.moved = true
		"foucault":
			s.bob = float(s.bob) + 0.5 * float(s.bob_dir)
			if absf(float(s.bob)) >= 1.0:
				s.bob = clampf(float(s.bob), -1.0, 1.0)
				s.bob_dir = -float(s.bob_dir)
			s.swing = float(s.swing) + 0.12
			if not _clear(sim, bob_pos(s), BOB_R):
				# Never land on a ball: hold the swing until the way is clear.
				s.bob = float(s.bob) - 0.5 * float(s.bob_dir)
			out.moved = true
		"spring_st":
			out.moved = true   # the charged rail's glow may change
		"tectonic":
			var was: Array = ridges(s)
			s.slide = (int(s.get("slide", 0)) + 1) % 6
			for r: Array in ridges(s):
				if not _wall_clear(sim, r[0], r[1]):
					s.slide = (int(s.slide) + 5) % 6   # a ball is in the way: hold still this time
					break
			out.moved = true
		"lever":
			var ends := lever_ends(s)
			for e: Dictionary in events:
				if e.type == "rail" and e.has("at"):
					var at: Vector2 = e.at
					var q := Geometry2D.get_closest_point_to_segment(at, ends[0], ends[1])
					if q.distance_to(at) < R + 6.0:
						s.tilt = 1.0 if at.x > LEVER_PIVOT.x else -1.0
			if not _wall_clear(sim, lever_ends(s)[0], lever_ends(s)[1]):
				s.tilt = -float(s.tilt)   # never tip onto a ball
			out.moved = true
		"tesla":
			out.moved = true   # the coil's charge glow changes
	return out


## No ball sits on the wall a-b.
static func _wall_clear(sim: PoolSim, a: Vector2, b: Vector2) -> bool:
	for i in sim.count():
		if sim.alive[i] == 1 and Geometry2D.get_closest_point_to_segment(sim.pos[i], a, b).distance_to(sim.pos[i]) < R + 3.0:
			return false
	return true


static func _hurt(sharks: Array, i: int, out: Dictionary) -> void:
	var sh: Dictionary = sharks[i]
	if sh.ko:
		return
	sh.hp = int(sh.hp) - 1
	if not out.hits.has(i):
		out.hits.append(i)
	if int(sh.hp) <= 0:
		sh.ko = true
		out.ko.append(String(sh.kind))


## Swallows the object ball nearest the Shark: never the 8, and never one of
## the last two balls, so a rack can always be finished.
static func _swallow(sh: Dictionary, sim: PoolSim) -> int:
	if sim.object_balls_left() <= 3:
		return -1
	var best := -1
	var bd := INF
	for i in sim.count():
		if sim.alive[i] == 1 and sim.num[i] != 0 and sim.num[i] != 8:
			var d := sim.pos[i].distance_to(shark_pos(sh))
			if d < bd:
				bd = d
				best = i
	if best < 0:
		return -1
	sim.alive[best] = 0
	sim.vel[best] = Vector2.ZERO
	return sim.num[best]


## Pool Shark and Great White: circle the nearest object ball, a quarter turn per shot.
static func _circle_ball(sh: Dictionary, sim: PoolSim, step: int) -> void:
	var r := float(SHARKS[sh.kind].r)
	var near := -1
	var bd := INF
	for i in sim.count():
		if sim.alive[i] == 1 and sim.num[i] != 0:
			var d := sim.pos[i].distance_to(shark_pos(sh))
			if d < bd:
				bd = d
				near = i
	if near < 0:
		return
	for tries in 4:
		var a := PI * 0.5 * float(step + tries)
		var p := sim.pos[near] + Vector2.from_angle(a) * (r + R + 26.0)
		if _clear(sim, p, r):
			sh.heading = (p - shark_pos(sh)).angle() if p != shark_pos(sh) else float(sh.heading)
			sh.x = p.x
			sh.y = p.y
			return


## The Hammerhead charges straight at its next waypoint, stopping short of any ball.
static func _charge(sh: Dictionary, to: Vector2, sim: PoolSim) -> void:
	var from := shark_pos(sh)
	var r := float(SHARKS[sh.kind].r)
	var best := from
	for k in range(1, 21):
		var p := from.lerp(to, k / 20.0)
		if not _clear(sim, p, r):
			break
		best = p
	sh.heading = (to - from).angle()
	sh.x = best.x
	sh.y = best.y


static func _clear(sim: PoolSim, p: Vector2, r: float) -> bool:
	if p.x < r + 10.0 or p.y < r + 10.0 or p.x > W - r - 10.0 or p.y > H - r - 10.0:
		return false
	for i in sim.count():
		if sim.alive[i] == 1 and sim.pos[i].distance_to(p) < r + R + 6.0:
			return false
	for pk in sim.layout.pockets:
		if (pk.pos as Vector2).distance_to(p) < r + 46.0:
			return false
	return true


static func _clear_spot(sim: PoolSim, near: Vector2, r: float) -> Vector2:
	for ring in 6:
		for k in 8:
			var p := near + Vector2.from_angle(TAU * k / 8.0) * ring * 40.0
			if _clear(sim, p, r):
				return p
	return Vector2.INF


static func _leech_target(sim: PoolSim) -> int:
	for i in sim.count():
		if sim.alive[i] == 1 and sim.num[i] != 0 and sim.num[i] != 8:
			return sim.num[i]
	return -1
