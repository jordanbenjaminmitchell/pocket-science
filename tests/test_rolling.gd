extends SceneTree
## Balls must roll the way real balls do: turning only as they travel, the right
## way round, and with no jump when a shot starts or ends.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func make_ball(n: int) -> BallNode:
	var b := BallNode.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	b.setup(n, ThemeDB.fallback_font, rng)
	root.add_child(b)
	return b


func shown(b: BallNode) -> Basis:
	return b.mat.get_shader_parameter("orient")


func angle_between(a: Basis, b: Basis) -> float:
	return Quaternion(a.orthonormalized()).angle_to(Quaternion(b.orthonormalized()))


func _initialize() -> void:
	call_deferred("_go")


func _go() -> void:
	var r := TableLayout.R

	var b := make_ball(0)
	var top := b.basis.inverse() * Vector3(0, 0, 1)
	b.roll_to(Vector2(r * PI * 0.5 / 3.0, 0.0))
	b.roll_to(Vector2(r * PI * 0.5 * 2.0 / 3.0, 0.0))
	b.roll_to(Vector2(r * PI * 0.5, 0.0))
	check((b.basis * top).distance_to(Vector3(1, 0, 0)) < 0.01, "rolling right carries the top of the ball to the right")
	var before := b.basis
	b.roll_to(b.position)
	check(b.basis == before, "a ball that does not move does not turn")

	# Slow balls must really turn: this is what the old resting blend broke.
	var slow := make_ball(11)
	var start := shown(slow)
	slow.vel = Vector2(25.0, 0.0)
	slow.refresh_label()
	check(angle_between(shown(slow), start) < 0.0001, "a shot starting does not snap the ball to a new pose")
	slow.roll_to(Vector2(r * 0.5, 0.0))
	check(angle_between(shown(slow), start) > 0.4, "a slow ball turns as it travels (%.2f rad)" % angle_between(shown(slow), start))

	var fast := make_ball(3)
	var before_fast := fast.basis
	fast.vel = Vector2(2000.0, 0.0)
	fast.refresh_label()
	fast.roll_to(Vector2(r * 3.0, 0.0))
	check(angle_between(fast.basis, before_fast) <= BallNode.MAX_TURN_PER_FRAME + 0.001, "very fast balls do not strobe")

	var cue := make_ball(0)
	var plain := cue.basis
	cue.roll_to(Vector2(r, 0.0), -1.0, Vector2(-r * 0.5 - r, 0.0))
	var backward := (cue.basis * (plain.inverse() * Vector3(0, 0, 1))).x
	check(backward < -0.1, "draw makes the cue ball turn backwards while it travels forwards")
	var side := make_ball(0)
	var side_start := side.basis
	side.roll_to(Vector2.ZERO, -1.0, Vector2.ZERO, -0.5)
	check(angle_between(side.basis, side_start) > 0.4, "english spins the ball about the vertical")

	# A real shot on a real table, sampled at 60 frames a second.
	var worst := 0.0
	var layout := TableLayout.new()
	for speed in [240.0, 420.0, 700.0, 1300.0]:
		var sim := PoolSim.new(layout)
		var i := sim.add_ball(9, Vector2(120, 250))
		var ball := make_ball(9)
		ball.position = sim.pos[i]
		ball.basis = Basis(Vector3(1, 2, 3).normalized(), 2.1) * BallNode.REST_BASIS
		sim.vel[i] = Vector2(speed, 40.0)
		var frames := 0
		while sim.moving() and frames < 1200:
			for k in 4:
				sim.step(PoolSim.STEP)
			ball.roll_to(sim.pos[i], sim.stop_distance(i))
			frames += 1
		var off := angle_between(ball.basis, ball.nearest_rest())
		worst = maxf(worst, off)
		# The two fast shots hit a cushion near the end, so they finish with the ease below.
		if speed < 500.0:
			check(off < 0.35, "at %d the ball rolls into its resting pose (%.2f rad off)" % [speed, off])
		ball.vel = sim.vel[i]
		ball.shown_settled = 0.0
		ball.refresh_label()
		for f in 60:
			await process_frame
		check(angle_between(ball.basis, ball.nearest_rest()) < 0.001 and ball.shown_settled == 1.0, "and finishes upright and readable")
		ball.queue_free()

	var stripe := make_ball(12)
	var up: Vector3 = stripe.basis * Vector3(0, 0, 1)
	check(absf(up.y) > 0.999, "stripes start level")
	print("rolling tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
