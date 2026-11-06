extends SceneTree
## Renders real frames of the game for visual QA (run WITHOUT --headless):
## Godot --path . --script res://tools/capture.gd -- <scenario> <out.png>

var game: Node


func _initialize() -> void:
	call_deferred("_go")


func _go() -> void:
	var args := OS.get_cmdline_user_args()
	var scenario := args[0] if args.size() > 0 else "aim"
	var out := args[1] if args.size() > 1 else "res://tools/shot.png"
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await _frames(5)
	match scenario:
		"title":
			await _frames(200)
		"cues":
			game._show_cue_select()
			await _frames(4)
		"pot", "potfx":
			game._new_run()
			game.run.formulas.append_array(["bank", "lens"])
			game.run.streak = 2
			var s: PoolSim = game.sim
			s.strike((Rack.FOOT - s.pos[0]).normalized(), 2250.0, 0.0, 0.0)
			s.settle()
			game.is_break = false
			game.view.update_balls(s)
			var c := AutoPlayer.candidates(s, game.run)
			if c.size() > 0:
				game.aim_dir = c[0].dir
			game.fine_aim = true
			game.guide_dirty = true
			game.power = 0.6
			game._refresh_hud()
			await _frames(6)
			if scenario == "potfx":
				game._shoot(0.6)
				await _frames(75)
		"aim", "cut", "roll", "tally", "shop":
			game._new_run()
			await _frames(3)
			if scenario != "aim":
				game.run.formulas.append_array(["bank", "prime", "lens"])
				game.run.money = 23
				game._refresh_hud()
				# Set up a cut shot on a ball near the cue.
				var s: PoolSim = game.sim
				s.pos[0] = Vector2(420, 330)
				game.view.update_balls(s)
				var obj := s.index_of(1)
				var pocket: Vector2 = s.layout.pockets[2].pos
				var od := (pocket - s.pos[obj]).normalized()
				var ghost := s.pos[obj] - od * TableLayout.R * 2.0
				game.aim_dir = (ghost - s.pos[0]).normalized()
				game.is_break = false
				game.fine_aim = true
				game.guide_dirty = true
			await _frames(4)
			if scenario == "roll" or scenario == "tally":
				game._shoot(0.75)
				await _frames(40 if scenario == "roll" else 160)
			if scenario == "shop":
				game.run.payout()
				game._show_shop([["Table cleared", 3], ["Unused chalk ×2", 2]])
				await _frames(4)
	await _frames(3)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out)
	print("CAPTURED ", out, " ", img.get_size())
	quit(0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame
