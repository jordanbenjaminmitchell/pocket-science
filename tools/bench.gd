extends SceneTree
func _initialize() -> void:
	var s := PoolSim.new(TableLayout.new().build())
	s.add_ball(0, Vector2(300, 260))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	Rack.build(s, rng)
	for lens in [false, true]:
		for fol in [0.0, 0.8, -0.8]:
			var t0 := Time.get_ticks_usec()
			var n := 50
			for i in n:
				TableView.compute_guide(s, Vector2(1, 0.02 + i * 0.001).normalized(), fol, 0.0, lens)
			print("guide lens=%s follow=%.1f: %.2f ms" % [lens, fol, (Time.get_ticks_usec() - t0) / 1000.0 / n])
	var t1 := Time.get_ticks_usec()
	var c := s.clone()
	c.strike(Vector2(1, 0.01), 2250, 0, 0)
	c.settle()
	print("full forecast settle: %.1f ms" % ((Time.get_ticks_usec() - t1) / 1000.0))
	quit()
