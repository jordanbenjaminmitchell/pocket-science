extends SceneTree
## Physics must advance at real-time speed regardless of display refresh rate.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func _initialize() -> void:
	call_deferred("_go")


func _go() -> void:
	var g: Node = load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	for hz in [30.0, 60.0, 75.0, 120.0, 144.0, 165.0, 240.0, 360.0]:
		g.sim_accum = 0.0
		var total := 0
		var frames := int(hz * 2.0)   # two seconds of real time
		for f in frames:
			total += g._sim_steps(1.0 / hz)
		check(absi(total - 480) <= 1, "%d Hz -> %d steps in 2 s (want 480)" % [int(hz), total])
	g.sim_accum = 0.0
	var fast := 0
	for f in 60:
		fast += g._sim_steps(1.0 / 60.0, 4.0)
	check(absi(fast - 960) <= 1, "fast-forward is exactly 4x (%d)" % fast)
	g.sim_accum = 0.0
	var hitch: int = g._sim_steps(2.0)
	check(hitch == 24, "a 2 s hitch is clamped to 0.1 s (%d steps)" % hitch)
	print("timing tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
