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
	# Phone-like captures: PS_PHONE=1 uses touch UI and larger text, PS_HOLE sets the camera cutout.
	if OS.get_environment("PS_PHONE") == "1":
		game.settings.touch_mode = true
		game.settings.large_text = true
	if OS.get_environment("PS_HOLE") != "":
		game.debug_hole = float(OS.get_environment("PS_HOLE"))
	root.add_child(game)
	if OS.get_environment("PS_LAYOUT") == "wide":
		game.settings.screen_layout = 1
		game._apply_settings()
	await _frames(5)
	match scenario:
		"title":
			await _frames(200)
		"coach":
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://settings.cfg"))
			game._new_run()
			await _frames(140)
		"settings":
			game._show_settings(game._show_title)
			await _frames(4)
		"info":
			game._new_run()
			game.run.perks.assign(["golden", "bank", "catalyst", "heat", "streak"])
			game.run.imbues = {3: "vein", 11: "glass"}
			game.run.catalyst = 2.5
			game.run.table_index = 3
			await _frames(3)
			game._show_run_info()
			await _frames(4)
		"elements":
			game._new_run()
			game.run.perks.assign(["golden", "bank", "catalyst", "heat", "streak", "ricochet"])
			game.run.table_index = 4
			game.run.begin_table()
			game.run.element_mix = ["fire"]
			game.run.heat = 3
			game._setup_table()
			game._enter_aim()
			await _frames(70)
		"stripes":
			game._new_run()
			game.run.table_index = 7
			game.run.begin_table()
			game._setup_table()
			game._enter_aim()
			await _frames(40)
		"credits":
			game._show_credits()
			await _frames(4)
		"twopockets":
			game._new_run()
			game.run.plan[0].anomaly = "onepocket"
			game.run.begin_table()
			game._setup_table()
			game._enter_aim()
			await _frames(110)
		"icons":
			var bg := ColorRect.new()
			bg.color = Color(0.1, 0.1, 0.12)
			bg.position = Vector2.ZERO
			bg.size = Vector2(1600, 900)
			game.root.add_child(bg)
			var ids: Array = Catalog.PERKS.keys()
			for i in ids.size():
				var ic := IconArt.new().setup(ids[i], game.F_SEMI, 118)
				ic.position = Vector2(8 + (i % 12) * 132, 8 + int(i / 12) * 150)
				ic.size = Vector2(118, 118)
				game.root.add_child(ic)
			await _frames(4)
		"collection":
			game.screens.show_collection()
			await _frames(4)
		"records":
			for i in 6:
				var r := RunState.new()
				r.start(100 + i, Catalog.CUES.keys()[i % 5])
				r.tables_cleared = 2 + i
				r.total_score = 900 * (i + 1)
				r.best_shot = 150 * (i + 1)
				r.total_pots = 12 * (i + 1)
				r.best_heat = 2 + i
				r.perks.assign(["golden", "bank", "rhythm"].slice(0, 1 + i % 3))
				r.record_id = "t%d" % i
				if i == 3:
					r.daily_key = "20261108"
				game.records.record(r, i == 5)
			game.screens.show_records()
			await _frames(4)
		"lab":
			game._new_run()
			game.run.plan[0].lab = args[2]
			if args[3] != "-":
				game.run.plan[0].anomaly = args[3]
			game.run.begin_table()
			game._setup_table()
			game._enter_aim()
			args.resize(2)
			await _frames(120)
		"help":
			game._show_help()
			await _frames(4)
		"over":
			game._new_run()
			game.run.tables_cleared = 3
			game.run.best_shot = 412
			game._show_game_over()
			await _frames(4)
		"cues":
			game._show_cue_select()
			await _frames(4)
		"pot", "potfx", "forecast":
			game._new_run()
			game.run.perks.append_array(["bank", "lens"])
			game.run.heat = 2
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
			if scenario == "forecast":
				game.run.perks.assign(["oracle"])
				game.guide_dirty = true
				await _frames(40)
			if scenario == "potfx":
				game._shoot(0.6)
				await _frames(75)
		"aim", "cut", "roll", "tally", "shop":
			game._new_run()
			await _frames(3)
			if scenario != "aim":
				game.run.perks.append_array(["bank", "prime", "lens"])
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
				await _frames(8 if scenario == "roll" else 160)
			if scenario == "shop":
				game.run.payout()
				game._show_shop([["Table cleared", 3], ["Unused chalk ×2", 2]])
				game.run.shop[0] = {"type": "perk", "id": "ricochet", "cost": 6, "sold": false}
				game.run.shop[1] = {"type": "perk", "id": "geometry", "cost": 8, "sold": false}
				game._refresh_shop()
				await _frames(4)
	await _frames(3)
	var img := root.get_viewport().get_texture().get_image()
	if args.size() > 5:
		img = img.get_region(Rect2i(int(args[2]), int(args[3]), int(args[4]), int(args[5])))
		img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	img.save_png(out)
	print("CAPTURED ", out, " ", img.get_size())
	quit(0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame
