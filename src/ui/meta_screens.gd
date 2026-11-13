class_name MetaScreens
extends RefCounted
## Collection and Records screens. Built on the game controller's UI helpers.

const TABS := ["Elements", "Items", "Balls", "Isotopes", "Cues", "Tables"]

var g: Node
var tab := "Elements"


func _init(game: Node) -> void:
	g = game


func show_collection() -> void:
	g._clear_overlay()
	g._dim(0.88)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", g._style(Color(0.08, 0.075, 0.08, 0.99), Color(0.5, 0.7, 0.9), 2, 16))
	p.position = Vector2(40.0 + g.fit.frame_x, 30.0)
	p.size = Vector2(1520, 840)
	g.overlay.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	head.add_child(g._label("COLLECTION", 30, Color(0.98, 0.8, 0.4), g.F_PIXB))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(g._label(g.meta.progress(), 17, Color(0.6, 0.85, 1.0), g.F_REG))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	v.add_child(tabs)
	for t in TABS:
		var b: Button = g._button(t, func():
			tab = t
			show_collection(), Color(0.98, 0.8, 0.4) if t == tab else Color(0.4, 0.45, 0.55))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(b)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	sc.add_child(grid)
	for row in _rows():
		grid.add_child(_entry(row))
	v.add_child(g._button("Back", g._show_title, Color(0.4, 0.9, 0.6)))


## Each row: {icon, title, sub, desc, color, hint (locked if non-empty)}
func _rows() -> Array:
	var rows: Array = []
	match tab:
		"Elements":
			for id in Catalog.PERKS:
				var f: Dictionary = Catalog.PERKS[id]
				var locked: bool = g.meta.locked_perks().has(id)
				rows.append({"icon": "perk:" + id, "title": f.name, "sub": "%s · %s · $%d" % [Catalog.rarity_name(f.r), Catalog.family_name(id), f.cost],
					"desc": f.desc, "color": Catalog.rarity_color(f.r), "hint": g.meta.perk_hint(id) if locked else ""})
		"Items":
			for id in Catalog.ITEMS:
				var it: Dictionary = Catalog.ITEMS[id]
				rows.append({"icon": id, "title": it.name, "sub": "Catalyst · %s · $%d" % [Catalog.WHEN_NAMES[it.when], it.cost], "desc": it.desc, "color": Catalog.WHEN_COLORS[it.when], "hint": ""})
		"Balls":
			for id in Catalog.BALL_TYPES:
				var bt: Dictionary = Catalog.BALL_TYPES[id]
				rows.append({"icon": "ball_" + id, "title": bt.name + " ball", "sub": "Exotic ball · $%d" % bt.cost, "desc": bt.desc, "color": bt.color if (bt.color as Color).get_luminance() > 0.3 else bt.accent, "hint": ""})
		"Isotopes":
			for id in Catalog.IMBUES:
				var r: Dictionary = Catalog.IMBUES[id]
				rows.append({"icon": "imbue:" + id, "title": r.name, "sub": "Ball Isotope · $%d" % r.cost, "desc": r.desc, "color": r.color, "hint": ""})
		"Cues":
			for id in Catalog.CUES:
				var r: Dictionary = Catalog.CUES[id]
				rows.append({"icon": "cue:" + id, "title": r.name, "sub": "Starting cue", "desc": r.desc, "color": r.accent, "hint": g.meta.cue_hint(id) if not g.meta.cue_unlocked(id) else ""})
		"Tables":
			for id in Catalog.BOSSES:
				var r: Dictionary = Catalog.BOSSES[id]
				rows.append({"icon": "table:" + id, "title": r.name, "sub": "Boss table", "desc": r.desc, "color": Color(1.0, 0.7, 0.5), "hint": ""})
	return rows


func _entry(r: Dictionary) -> Control:
	var locked: bool = r.hint != ""
	var col: Color = r.color if not locked else Color(0.45, 0.45, 0.5)
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(478, 104)
	p.add_theme_stylebox_override("panel", g._style(Color(0.13, 0.12, 0.13), col, 1, 10))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	p.add_child(hb)
	if r.icon != "":
		var parts := ThumbArt.split(r.icon)
		var ic: Control = ThumbArt.new().setup(parts[0], parts[1], 37.0 if parts[0] == "table" else 60.0) if parts[0] != "" else IconArt.new().setup(r.icon, g.F_SEMI, 60)
		if locked:
			ic.modulate = Color(0.45, 0.45, 0.5)
		hb.add_child(ic)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(v)
	v.add_child(g._label(r.title if not locked else "???", 17, Color.WHITE if not locked else Color(0.6, 0.6, 0.65)))
	v.add_child(g._label(r.sub, 12, col))
	var body: String = r.desc if not locked else "Locked - " + r.hint
	var d: RichTextLabel = g._term_text(Glossary.link(body), 13, Color(0.8, 0.82, 0.85) if not locked else Color(1.0, 0.8, 0.45), 380.0)
	v.add_child(d)
	return p


func show_records() -> void:
	g._clear_overlay()
	g._dim(0.88)
	var v: VBoxContainer = g._center_panel(1200, 720, Color(1.0, 0.85, 0.35))
	v.add_child(g._label("RECORDS", 30, Color(0.98, 0.8, 0.4), g.F_PIXB))
	var rec: Records = g.records
	var l := rec.lifetime()
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 30)
	v.add_child(cols)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(400, 0)
	cols.add_child(left)
	left.add_child(g._label("LIFETIME", 16, Color(0.6, 0.8, 1.0)))
	var win_rate := "%d%%" % int(round(100.0 * l.wins / l.runs)) if l.runs > 0 else "-"
	left.add_child(g._label("Runs played: %d\nWins: %d  (%s)\nTables cleared: %d\nBalls sunk: %d\nBest shot: %d\nBest Heat: %d\nDeepest run: %d tables" % [l.runs, l.wins, win_rate, l.tables, l.pots, l.best_shot, l.best_heat, l.best_tables], 17, Color(0.85, 0.87, 0.9), g.F_REG))
	left.add_child(g._label("FAVOURITE ELEMENTS", 16, Color(0.6, 0.8, 1.0)))
	var favs := rec.favourites()
	if favs.is_empty():
		left.add_child(g._label("Finish a run to see these.", 15, Color(0.6, 0.6, 0.65), g.F_REG))
	for f in favs:
		var row := HBoxContainer.new()
		row.add_child(IconArt.new().setup(f[0], g.F_SEMI, 30))
		row.add_child(g._label("  %s  ×%d" % [Catalog.PERKS[f[0]].name, f[1]], 16, Color(0.85, 0.87, 0.9), g.F_REG))
		left.add_child(row)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	right.add_child(g._label("RECENT RUNS", 16, Color(0.6, 0.8, 1.0)))
	if rec.entries.is_empty():
		right.add_child(g._label("No finished runs yet.", 15, Color(0.6, 0.6, 0.65), g.F_REG))
	var recent: Array = rec.entries.slice(maxi(0, rec.entries.size() - 14))
	recent.reverse()
	for e in recent:
		var cue_name: String = Catalog.CUES.get(e.cue, Catalog.CUES.maple).name
		var tag := "WIN" if e.won else "%d tables" % int(e.tables)
		var extra := "  ·  Daily" if e.get("daily", "") != "" else ""
		right.add_child(g._label("%s  ·  %s  ·  %s  ·  score %d  ·  best %d%s" % [e.date, tag, cue_name, int(e.score), int(e.best_shot), extra], 15, Color(1.0, 0.85, 0.45) if e.won else Color(0.82, 0.84, 0.87), g.F_REG))
	v.add_child(g._button("Back", g._show_title, Color(0.4, 0.9, 0.6)))
