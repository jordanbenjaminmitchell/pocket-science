extends SceneTree
## Renders the board art (src/view/board_art.gd) into preview sheets (run WITHOUT --headless):
## Godot --path . --script res://tools/board_preview.gd -- docs/table-art
## Writes decals-1.png and decals-2.png (20 boards each), sharks.png, moving-parts.png and rails.png.

var font: Font = preload("res://assets/fonts/ChakraPetch-SemiBold.ttf")


func _initialize() -> void:
	call_deferred("_go")


func _sheet(size: Vector2i, painter: Callable) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = size
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_2d = Viewport.MSAA_4X
	root.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.09, 0.1)
	bg.size = Vector2(size)
	vp.add_child(bg)
	var canvas := Control.new()
	canvas.size = Vector2(size)
	canvas.draw.connect(func(): painter.call(canvas))
	vp.add_child(canvas)
	return vp


func _save(vp: SubViewport, path: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("CAPTURED ", path)
	vp.queue_free()


func _label(ci: CanvasItem, txt: String, pos: Vector2, fs := 14, col := Color(0.85, 0.87, 0.9)) -> void:
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	ci.draw_string(font, pos - Vector2(w * 0.5, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _go() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "res://docs/table-art"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	# Decals: each board as a little table (2:1), felt, rail and its decal at 6%,
	# plus the same decal brighter beside it so the drawing can be checked.
	var ids: Array = BoardArt.BOARD_NAMES.keys()
	for page in 2:
		var chunk := ids.slice(page * 20, page * 20 + 20)
		var vp := _sheet(Vector2i(4 * 330 + 20, 5 * 200 + 20), func(ci: CanvasItem):
			for i in chunk.size():
				var id: String = chunk[i]
				var o := Vector2(20 + (i % 4) * 330, 20 + (i / 4) * 200)
				var rail := Rect2(o, Vector2(300, 150))
				var mat: String = BoardArt.RAILS.get(id, "")
				var strips := [Rect2(o, Vector2(300, 12)), Rect2(o + Vector2(0, 138), Vector2(300, 12)), Rect2(o + Vector2(0, 12), Vector2(12, 126)), Rect2(o + Vector2(288, 12), Vector2(12, 126))]
				for st: Rect2 in strips:
					if mat != "":
						BoardArt.draw_rail(ci, st, mat)
					else:
						ci.draw_rect(st, Color(0.3, 0.15, 0.07))
				var felt := rail.grow(-12)
				ci.draw_rect(felt, BoardArt.FELTS.get(id, Color(0.06, 0.42, 0.28)))
				var d: String = BoardArt.DECALS[id]
				if d != "":
					IconArt.paint(ci, d, felt.get_center(), 1.2, Color(1, 1, 1, 0.22), Color(0, 0, 0, 0), font, 2.0)
				_label(ci, "%s" % BoardArt.BOARD_NAMES[id], o + Vector2(150, 172), 14))
		await _save(vp, out.path_join("decals-%d.png" % (page + 1)))
	# Sharks: each kind, normal, hit and knocked out.
	var vp2 := _sheet(Vector2i(3 * 260 + 40, 6 * 170 + 30), func(ci: CanvasItem):
		var states := ["normal", "hit", "ko"]
		for r in BoardArt.SHARKS.size():
			var kind: String = BoardArt.SHARKS[r]
			for c in 3:
				var o := Vector2(40 + c * 260, 30 + r * 170)
				ci.draw_rect(Rect2(o, Vector2(240, 150)), Color(0.06, 0.38, 0.26))
				BoardArt.draw_shark(ci, kind, o + Vector2(115, 82), -0.25, 150.0 if kind == "white" else 110.0, states[c], 0.6 + c, 0.62, int(BoardFeatures.SHARKS[kind].hp))
				_label(ci, "%s, %s" % [BoardArt.SHARK_NAMES[kind], ["swimming", "hit", "knocked out"][c]], o + Vector2(120, 146), 13))
	await _save(vp2, out.path_join("sharks.png"))
	# Moving parts.
	var vp3 := _sheet(Vector2i(4 * 300 + 40, 2 * 260 + 40), func(ci: CanvasItem):
		var names := ["Clockwork Sweeper", "Pendulum bob", "Shuttle post", "Coriolis turntable", "Gulf Stream conveyor", "Maxwell's Demon", "The Lever's see-saw", "Charged rail"]
		for i in 8:
			var o := Vector2(40 + (i % 4) * 300, 30 + (i / 4) * 260)
			ci.draw_rect(Rect2(o, Vector2(280, 220)), Color(0.06, 0.38, 0.26))
			var c := o + Vector2(140, 110)
			match i:
				0: BoardArt.draw_sweeper(ci, c, -0.6, 95.0, 1.0)
				1: BoardArt.draw_pendulum(ci, c + Vector2(-50, -60), c + Vector2(30, 20), 26.0)
				2: BoardArt.draw_shuttle(ci, c + Vector2(-100, 0), c + Vector2(100, 0), 0.35)
				3: BoardArt.draw_turntable(ci, c, 90.0, 0.4)
				4: BoardArt.draw_conveyor(ci, Rect2(o + Vector2(10, 80), Vector2(260, 60)), Vector2.RIGHT, 0.3)
				5: BoardArt.draw_demon(ci, c + Vector2(30, 0), 0.7, 0.5)
				6: BoardArt.draw_seesaw(ci, c + Vector2(0, 20), 200.0, -0.18)
				7: BoardArt.draw_charged_rail(ci, o + Vector2(20, 110), o + Vector2(260, 110), 0.9, 0.35)
			_label(ci, names[i], o + Vector2(140, 214), 14))
	await _save(vp3, out.path_join("moving-parts.png"))
	# Rail materials.
	var vp4 := _sheet(Vector2i(2 * 420 + 40, 3 * 120 + 30), func(ci: CanvasItem):
		for i in BoardArt.RAIL_MATERIALS.size():
			var o := Vector2(20 + (i % 2) * 420, 20 + (i / 2) * 120)
			BoardArt.draw_rail(ci, Rect2(o, Vector2(400, 40)), BoardArt.RAIL_MATERIALS[i], 0.8)
			ci.draw_rect(Rect2(o + Vector2(0, 40), Vector2(400, 30)), Color(0.06, 0.38, 0.26))
			_label(ci, String(BoardArt.RAIL_MATERIALS[i]).replace("_", " ").capitalize(), o + Vector2(200, 95), 14))
	await _save(vp4, out.path_join("rails.png"))
	quit()
