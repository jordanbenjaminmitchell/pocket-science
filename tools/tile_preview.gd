extends SceneTree
## Renders sample Pro Shop offer cards with periodic-tile art (run WITHOUT --headless):
## Godot --path . --script res://tools/tile_preview.gd -- <out.png>
## PS_TILE_ON=symbol puts the lettering effects on the big symbols instead of the names.

const SAMPLES := [
	["perk", "side", 0],
	["imbue", "vein", 7],
	["ball", "gold", 0],
	["item", "secondstrike", 0],
	["item", "trapdoor", 0],
]


func _initialize() -> void:
	call_deferred("_go")


func _style(bg: Color, border: Color, bw: int, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 12
	s.content_margin_bottom = 10
	return s


func _label(txt: String, fs: int, col: Color, f: Font) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(172, 0)
	return l


func _card(kind: String, id: String, ball: int) -> Control:
	var tile := TileArt.new().setup(kind, id, ball)
	var accent := tile.tint
	var desc := ""
	var cost := 0
	match kind:
		"perk":
			var f: Dictionary = Catalog.PERKS[id]
			accent = Catalog.rarity_color(f.r)
			desc = f.desc
			cost = f.cost
		"imbue":
			desc = Catalog.IMBUES[id].desc
			cost = Catalog.IMBUES[id].cost
		"ball":
			desc = Catalog.BALL_TYPES[id].desc
			cost = Catalog.BALL_TYPES[id].cost
		"item":
			var it: Dictionary = Catalog.ITEMS[id]
			desc = it.desc
			cost = it.cost
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(196, 0)
	p.add_theme_stylebox_override("panel", _style(Color(0.13, 0.12, 0.13), accent if kind == "perk" else Color(0.32, 0.32, 0.36), 2, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 5)
	p.add_child(v)
	v.add_child(tile)
	var d := _label(desc, 13, Color(0.8, 0.82, 0.85), TileArt.F_REG)
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(d)
	var b := Button.new()
	b.text = "Buy $%d" % cost
	b.add_theme_font_override("font", TileArt.F_SEMI)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_stylebox_override("normal", _style(Color(0.1, 0.1, 0.1), Color(0.85, 0.65, 0.3), 1, 6))
	v.add_child(b)
	return p


## PS_TILE_SET=perks (or imbues, balls, items, bets, all) renders every tile of
## that kind instead, 20 to a sheet, saving <out>-1.png, <out>-2.png and so on.
## PS_TILE_ONLY=a,b limits it to those ids (kind:id outside perks);
## PS_TILE_ZOOM=2 draws them twice the size for a close look. Imbues are shown
## on balls 1-15 in turn, the first before its ball is chosen.
func _perk_sheets(out: String) -> void:
	var set_name := OS.get_environment("PS_TILE_SET")
	var prefix := {"perks": "perk:", "imbues": "imbue:", "balls": "ball:", "items": "item:", "bets": "bet:", "cues": "cue:", "all": ""}.get(set_name, "perk:") as String
	var ids: Array = TileArt.TILES.keys().filter(func(k: String) -> bool: return k.begins_with(prefix))
	if OS.get_environment("PS_TILE_ONLY") != "":
		ids = Array(OS.get_environment("PS_TILE_ONLY").split(",")).map(func(k: String) -> String: return k if ":" in k else "perk:" + k)
	var per := 20
	var cols := 5
	var zoom := maxf(1.0, OS.get_environment("PS_TILE_ZOOM").to_float())
	var vp := SubViewport.new()
	vp.size = Vector2i(Vector2(cols * 184 + 12, 4 * 130 + 12) * zoom)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	for page in ceili(ids.size() / float(per)):
		for c in vp.get_children():
			c.free()
		var bg := ColorRect.new()
		bg.color = Color(0.09, 0.09, 0.1)
		bg.size = Vector2(vp.size)
		vp.add_child(bg)
		var chunk := ids.slice(page * per, page * per + per)
		for i in chunk.size():
			var key: String = chunk[i]
			var tile := TileArt.new().setup(key.get_slice(":", 0), key.get_slice(":", 1), (page * per + i) % 16)
			tile.position = Vector2(12 + (i % cols) * 184, 12 + (i / cols) * 130) * zoom
			tile.size = TileArt.SIZE
			tile.scale = Vector2(zoom, zoom)
			bg.add_child(tile)
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var path := out.get_basename() + "-%d.png" % (page + 1)
		vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
		print("CAPTURED ", path)
	quit()


## PS_TILE_SET=betcards renders every side bet as a playing card (BetCard), with
## example numbers for a table whose target is 215 and stake is $8, then the
## card in each of its other states. 15 to a sheet.
func _bet_sheets(out: String) -> void:
	var Card: GDScript = load("res://src/ui/bet_card.gd")
	var cards := []
	var stake := 8
	for b in Catalog.BOUNTIES:
		var tier := int(Catalog.BOUNTIES[b].tier)
		cards.append([b, "open", {"stake": stake, "reward": stake + stake * (1 + tier), "max_reward": stake * 4, "target": 215}, true])
	cards.append(["solid", "back", {"stake": stake, "max_reward": stake * 4}, false])
	cards.append(["bank2", "taken", {"stake": stake, "reward": stake * 4, "target": 215}, true])
	cards.append(["half", "won", {"stake": 16, "reward": 16 + 56, "target": 840}, true])
	cards.append(["combo", "passed", {"stake": stake, "reward": stake * 3, "target": 215}, true])
	cards.append(["solid", "passed", {"stake": stake, "max_reward": stake * 4}, false])
	if OS.get_environment("PS_TILE_ONLY") != "":
		var only := OS.get_environment("PS_TILE_ONLY").split(",")
		cards = cards.filter(func(c: Array) -> bool: return c[0] in only)
	var per := 15
	var cols := 5
	var zoom := maxf(1.0, OS.get_environment("PS_TILE_ZOOM").to_float())
	var vp := SubViewport.new()
	vp.size = Vector2i(Vector2(cols * 192 + 12, 3 * 264 + 12) * zoom)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	for page in ceili(cards.size() / float(per)):
		for c in vp.get_children():
			c.free()
		var bg := ColorRect.new()
		bg.color = Color(0.09, 0.09, 0.1)
		bg.size = Vector2(vp.size)
		vp.add_child(bg)
		var chunk := cards.slice(page * per, page * per + per)
		for i in chunk.size():
			var c: Array = chunk[i]
			var card: Control = Card.new().setup(c[0], c[1], c[2], c[3])
			card.position = Vector2(12 + (i % cols) * 192, 12 + (i / cols) * 264) * zoom
			card.scale = Vector2(zoom, zoom)
			bg.add_child(card)
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var path := out.get_basename() + "-%d.png" % (page + 1)
		vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
		print("CAPTURED ", path)
	quit()


func _go() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "res://tools/tiles.png"
	if OS.get_environment("PS_TILE_ON") != "":
		TileArt.effects_on = OS.get_environment("PS_TILE_ON")
	if OS.get_environment("PS_TILE_SET") == "betcards":
		await _bet_sheets(out)
		return
	if OS.get_environment("PS_TILE_SET") != "":
		await _perk_sheets(out)
		return
	# A fixed-size off-screen viewport, so the project's window stretch cannot scale it.
	var vp := SubViewport.new()
	vp.size = Vector2i(1100, 400)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.09, 0.1)
	bg.size = Vector2(vp.size)
	vp.add_child(bg)
	var row := HBoxContainer.new()
	row.position = Vector2(24, 24)
	row.add_theme_constant_override("separation", 14)
	bg.add_child(row)
	for s in SAMPLES:
		row.add_child(_card(s[0], s[1], s[2]))
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img = img.get_region(Rect2i(Vector2i.ZERO, Vector2i(row.size + Vector2(48, 48))))
	img.save_png(ProjectSettings.globalize_path(out))
	print("CAPTURED ", out)
	quit()
