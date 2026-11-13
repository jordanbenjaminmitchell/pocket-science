extends SceneTree
## Clockwork must show the full physics forecast instead of a geometric pot claim.

var failures := 0

func check(ok: bool, message: String) -> void:
	print("  ", "ok  " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func _initialize() -> void:
	call_deferred("_go")

func _go() -> void:
	var game: Node = load("res://main.tscn").instantiate()
	root.add_child(game)
	for i in 3:
		await process_frame
	game._new_run()
	game.run.table_index = 4
	game.run.begin_table()
	game._setup_table()
	game._enter_aim()
	check(game.run.current().id == "elements", "Clockwork table is active")
	check(game.view.forecast_authoritative and game._show_paths(), "Clockwork uses physics paths as its visible prediction")
	game.aim_dir = (Rack.FOOT - game.sim.pos[0]).normalized()
	game.power = 0.55
	var truth: PoolSim = game.sim.clone()
	truth.first_boost = game.run.first_boost(game._current_power())
	truth.strike(game.aim_dir, game._speed(game._current_power()) * game.run.power_mult(game.is_break), game._shot_follow(), game._shot_side())
	truth.settle()
	game._compute_forecast()
	check(game.fc_limit == 30.0, "Clockwork forecasts through the full shot")
	var frames := 0
	while game.fc_sim != null and frames < 600:
		await process_frame
		frames += 1
	check(game.fc_sim == null and not game.view.forecast_paths.is_empty(), "Clockwork completes and draws its forecast")
	var cue := truth.index_of(0)
	if truth.alive[cue] == 1 and game.fc_paths.has(cue):
		var points: PackedVector2Array = game.fc_paths[cue]
		check(points[points.size() - 1].distance_to(truth.pos[cue]) < 1.0, "forecast cue path ends where the real simulation does")
	print("clockwork prediction tests: %d failures" % failures)
	quit(1 if failures else 0)
