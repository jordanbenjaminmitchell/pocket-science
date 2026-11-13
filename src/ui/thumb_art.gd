class_name ThumbArt
extends Control
## Small square pictures for lists and the HUD, matching the card art:
##
##   perk   the Element's tile in miniature: atomic number, its symbol in the
##          element's own colour, framed in its periodic-table group colour
##   imbue  a ball glowing in the Isotope's colour, with its symbol
##   ball   the Exotic ball itself
##   cue    the starting cue, lying across, with the object it carries
##   table  the board seen from above: its shape, felt, rails, pockets and decal
##
## ThumbArt.new().setup("perk", "fusion", 34) is a drop-in for IconArt.setup().

const F_SEMI: Font = preload("res://assets/fonts/ChakraPetch-SemiBold.ttf")

var kind := ""
var id := ""
var px := 40.0


func setup(k: String, i: String, size_px: float) -> ThumbArt:
	kind = k
	id = i
	px = size_px
	custom_minimum_size = Vector2(px * (1.6 if k == "table" else 1.0), px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


## The kind a Almanac or HUD icon id belongs to: "ball_gold" -> ["ball", "gold"].
static func split(icon: String) -> Array:
	if icon.begins_with("ball_"):
		return ["ball", icon.substr(5)]
	for k in ["perk", "imbue", "cue", "table"]:
		if icon.begins_with(k + ":"):
			return [k, icon.substr(k.length() + 1)]
	return ["", icon]


func _draw() -> void:
	match kind:
		"perk": _draw_element()
		"imbue": _draw_isotope()
		"ball": _draw_ball(Vector2(px, px) * 0.5, px * 0.4, Catalog.BALL_TYPES[id])
		"cue": _draw_cue()
		"table": _draw_table()


func _box(col: Color, border: Color, radius: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = border
	sb.set_border_width_all(maxi(1, roundi(px / 26.0)))
	sb.set_corner_radius_all(roundi(radius))
	draw_style_box(sb, Rect2(Vector2.ZERO, custom_minimum_size))


func _text_c(txt: String, c: Vector2, fs: int, col: Color) -> void:
	var w := F_SEMI.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(F_SEMI, c + Vector2(-w * 0.5, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _draw_element() -> void:
	var f: Dictionary = Catalog.PERKS[id]
	var z := int(f.get("z", 0))
	var tint: Color = IconArt.FAMILY_COLORS.get(f.get("fam", "utility"), Color.WHITE)
	var group: Color = TileArt.GROUP_COLORS[TileArt.element_group(z)]
	_box(tint.darkened(0.8), group, px * 0.16)
	var look: Array = TileArt.ELEMENT_LOOK.get(z, [])
	var light: Color = look[1] if look.size() > 1 else TileArt.PAPER
	if z == 79:
		light = Color(1.0, 0.82, 0.32)
	var sym: String = TileArt.TILES.get("perk:" + id, {}).get("sym", "?")
	var fs := roundi(px * (0.5 if sym.length() > 1 else 0.6))
	var c := Vector2(px * 0.5, px * 0.58)
	if not look.is_empty() and look[0] in ["gas", "radio"]:
		for k in 3:
			draw_string_outline(F_SEMI, c + Vector2(-F_SEMI.get_string_size(sym, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * 0.5, fs * 0.36), sym, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, roundi(px * (0.16 - 0.05 * k)), Color(light, 0.12 + 0.1 * k))
	_text_c(sym, c + Vector2(px * 0.02, px * 0.03), fs, Color(0, 0, 0, 0.45))
	_text_c(sym, c, fs, light.lerp(Color.WHITE, 0.35))
	if px >= 30:
		var zf := maxi(8, roundi(px * 0.22))
		draw_string(F_SEMI, Vector2(px * 0.1, px * 0.1 + zf * 0.8), str(z), HORIZONTAL_ALIGNMENT_LEFT, -1, zf, group)


func _draw_isotope() -> void:
	var r: Dictionary = Catalog.IMBUES[id]
	var col: Color = r.color
	var c := Vector2(px, px) * 0.5
	for k in 4:
		draw_circle(c, px * (0.48 - k * 0.04), Color(col, 0.08 + 0.05 * k), true, -1.0, true)
	draw_circle(c, px * 0.33, Color(0.96, 0.95, 0.9), true, -1.0, true)
	draw_arc(c, px * 0.33, 0, TAU, 32, col, maxf(1.5, px * 0.06), true)
	draw_arc(c, px * 0.42, -0.6, 1.2, 16, Color(col.lightened(0.3), 0.9), maxf(1.0, px * 0.035), true)
	draw_circle(c + Vector2.from_angle(1.2) * px * 0.42, px * 0.05, col.lightened(0.4), true, -1.0, true)
	var sym: String = TileArt.TILES.get("imbue:" + id, {}).get("sym", "")
	_text_c(sym, c, roundi(px * (0.3 if sym.length() > 1 else 0.36)), col.darkened(0.45))


func _draw_ball(c: Vector2, rad: float, bt: Dictionary) -> void:
	var col: Color = bt.color
	var acc: Color = bt.accent
	draw_circle(c + Vector2(rad * 0.1, rad * 0.14), rad, Color(0, 0, 0, 0.35), true, -1.0, true)
	draw_circle(c, rad, col, true, -1.0, true)
	if int(bt.get("pattern", 0)) % 2 == 1:
		draw_rect(Rect2(c + Vector2(-rad * 0.86, -rad * 0.36), Vector2(rad * 1.72, rad * 0.72)), Color(acc, 0.8))
	draw_circle(c, rad * 0.56, Color(0.97, 0.96, 0.9), true, -1.0, true)
	var ink: Color = col.darkened(0.2) if col.get_luminance() < 0.7 else acc.darkened(0.25)
	IconArt.paint(self, bt.motif, c, rad * 0.42 / 34.0, ink, Color(0.97, 0.96, 0.9), F_SEMI, maxf(1.0, rad * 0.08))
	draw_circle(c + Vector2(-rad * 0.42, -rad * 0.45), rad * 0.18, Color(1, 1, 1, 0.6), true, -1.0, true)
	draw_arc(c, rad, 0, TAU, 32, Color(0, 0, 0, 0.35), 1.0, true)


func _draw_cue() -> void:
	var cue: Dictionary = Catalog.CUES[id]
	_box(Color(0.1, 0.1, 0.11), Color(cue.accent, 0.8), px * 0.16)
	var a := Vector2(px * 0.12, px * 0.86)
	var b := Vector2(px * 0.82, px * 0.2)
	var d := (b - a).normalized()
	var n := d.orthogonal()
	var w := px * 0.05
	var seg := func(f0: float, f1: float, w0: float, w1: float, col: Color) -> void:
		var p0 := a.lerp(b, f0)
		var p1 := a.lerp(b, f1)
		draw_colored_polygon(PackedVector2Array([p0 + n * w0, p1 + n * w1, p1 - n * w1, p0 - n * w0]), col)
	seg.call(0.0, 0.42, w, w * 0.8, cue.butt)
	seg.call(0.4, 0.44, w * 0.85, w * 0.8, cue.accent)
	seg.call(0.44, 0.96, w * 0.8, w * 0.4, cue.shaft)
	seg.call(0.96, 1.0, w * 0.4, w * 0.4, Color(0.3, 0.55, 0.95))
	draw_circle(b + d * px * 0.09, px * 0.07, Color(0.97, 0.96, 0.92), true, -1.0, true)
	var kit: String = cue.get("kit", "")
	if kit != "":
		IconArt.paint(self, IconArt.motif_for(kit), Vector2(px * 0.3, px * 0.3), px * 0.0055, cue.accent, Color(0.1, 0.1, 0.12), F_SEMI, maxf(1.0, px * 0.035))


func _draw_table() -> void:
	var size := custom_minimum_size
	var boss: Dictionary = Catalog.BOSSES[id]
	var art: Dictionary = Catalog.LAB_ART.get(boss.lab, Catalog.LAB_ART.standard)
	var felt: Color = Catalog.LABS[boss.lab].felt
	var rail: Color = art.rail
	if BoardArt.same_board(id):
		felt = BoardArt.FELTS.get(id, felt)
	# The frame and the playfield, scaled from the 1000 x 500 table.
	var pad := size.y * 0.1
	var field := Rect2(Vector2(pad, pad), size - Vector2(pad, pad) * 2.0)
	var sc := Vector2(field.size.x / TableLayout.W, field.size.y / TableLayout.H)
	var to_px := func(p: Vector2) -> Vector2:
		return field.position + p * sc
	var shape: Dictionary = Catalog.SHAPES.get(boss.get("shape", ""), {})
	var verts := PackedVector2Array()
	if shape.is_empty():
		for p in [Vector2(0, 0), Vector2(TableLayout.W, 0), Vector2(TableLayout.W, TableLayout.H), Vector2(0, TableLayout.H)]:
			verts.append(to_px.call(p))
	else:
		for p: Vector2 in shape.verts:
			verts.append(to_px.call(p))
	var outer := PackedVector2Array()
	var grown: Array = Geometry2D.offset_polygon(verts, pad * 0.8)
	outer = grown[0] if not grown.is_empty() else verts
	draw_colored_polygon(outer, rail)
	draw_polyline(outer + PackedVector2Array([outer[0]]), rail.lightened(0.3), 1.0, true)
	draw_colored_polygon(verts, felt)
	var decal: String = BoardArt.DECALS.get(id, "") if BoardArt.same_board(id) else String(art.decal)
	if decal != "":
		IconArt.paint(self, decal, field.get_center(), field.size.y / 110.0, Color(1, 1, 1, 0.3), Color(0, 0, 0, 0), F_SEMI, 1.0)
	# Pockets.
	var pockets: Array = []
	if shape.is_empty():
		for p in [Vector2(0, 0), Vector2(TableLayout.W * 0.5, 0), Vector2(TableLayout.W, 0), Vector2(0, TableLayout.H), Vector2(TableLayout.W * 0.5, TableLayout.H), Vector2(TableLayout.W, TableLayout.H)]:
			pockets.append(to_px.call(p))
	else:
		var sv: Array = shape.verts
		for pk: Dictionary in shape.pockets:
			if pk.has("p"):
				pockets.append(to_px.call(pk.p))
			elif pk.has("v"):
				pockets.append(to_px.call(sv[int(pk.v)]))
			else:
				var e := int(pk.e)
				pockets.append(to_px.call((sv[e] as Vector2).lerp(sv[(e + 1) % sv.size()], float(pk.t))))
	for p: Vector2 in pockets:
		draw_circle(p, maxf(2.0, size.y * 0.075), Color(0.02, 0.02, 0.03), true, -1.0, true)
