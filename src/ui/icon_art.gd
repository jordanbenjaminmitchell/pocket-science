class_name IconArt
extends Control
## Vector medallion icons for Perks and Reagents, in one consistent style.
##
## Each motif is a tiny drawing script in a -50..50 space, ops separated by ";":
##   c x y r          ring          C x y r        filled circle
##   l x1 y1 x2 y2    line          o x y x y ...  polyline
##   P x y x y ...    filled shape  a x y r s e    arc (degrees)
##   t x y size text  centred text (digits and $ + only)

const FLAME := "P 0 -32 14 -10 18 8 8 26 -8 26 -18 8 -12 -6 -6 4"
const STAR := "0 -32 8 -8 32 -8 12 6 20 30 0 14 -20 30 -12 6 -32 -8 -8 -8 0 -32"
const CUBE := "P -20 -8 8 -8 8 20 -20 20;o -20 -8 -8 -20 20 -20 8 -8;o 20 -20 20 8 8 20"

const MOTIFS := {
	"elastic": "C -18 8 13;C 18 8 13;l 0 -6 0 -28;l -10 -8 -20 -24;l 10 -8 20 -24",
	"odd": "c 0 0 29;t 0 0 25 1 3",
	"even": "c 0 0 29;t 0 0 25 2 4",
	"stripes": "c 0 0 29;P -26 -11 26 -11 26 11 -26 11",
	"solids": "C 0 0 29",
	"corner": "o -30 30 -30 -30 30 -30;C -13 -13 10",
	"side": "l -34 -22 -9 -22;l 9 -22 34 -22;C 0 -22 8;l 0 -8 0 26;o -9 17 0 27 9 17",
	"lever": "l -34 20 34 -18;P -8 26 8 26 0 8;C 28 -26 6",
	"chalk": CUBE + ";t -6 7 14 +",
	"jaws": "a 0 0 20 215 325;a 0 0 20 35 145;o -36 0 -26 -8;o -36 0 -26 8;l -36 0 -24 0;o 36 0 26 -8;o 36 0 26 8;l 36 0 24 0",
	"lens": "c -7 -7 21;l 9 9 30 30;l -7 -18 -7 4;l -18 -7 4 -7",
	"interest": "o -30 22 -10 2 4 13 28 -18;P 32 -24 14 -20 28 -6",
	"bank": "l -36 -28 36 -28;o -30 28 0 -27 30 28;P 30 28 18 20 32 14",
	"kick": "P -4 -32 14 -32 2 -6 16 -6 -12 32 -2 4 -14 4",
	"chain": "c -14 0 14;c 14 0 14",
	"multi": "C 0 -15 11;C -15 12 11;C 15 12 11",
	"streak": "o -28 -20 -10 0 -28 20;o -8 -20 10 0 -8 20;o 12 -20 30 0 12 20",
	"heat": FLAME,
	"power": "a 0 10 30 180 360;l 0 10 19 -14;C 0 10 6;l -34 10 34 10",
	"finesse": "o -34 6 -22 -10 -10 6 2 -10 14 6 26 -10 34 0",
	"prime": "c 0 0 29;t 0 0 34 7",
	"eight": "C 0 0 30;K 0 0 14;T 0 0 21 8",
	"gold": "c 0 0 28;c 0 0 22;t 0 0 28 $",
	"entropy": "C -20 -18 5;C 10 -25 6;C 25 -4 4;C -6 2 6;C -26 14 4;C 17 20 6;C -3 26 4",
	"catalyst": "o -8 -30 -8 -6 -26 26 26 26 8 -6 8 -30;l -13 -30 13 -30;P -18 12 18 12 26 26 -26 26",
	"golden": "a 7 0 9 180 360;a 2 0 14 0 180;a 11 0 23 180 360;a -2 0 32 0 120",
	"supernova": "P " + STAR,
	"fusion": "c -12 0 18;c 12 0 18;C 0 0 7",
	"magnet": "a 0 4 21 0 180;l -21 4 -21 -26;l 21 4 21 -26;l -30 -26 -12 -26;l 12 -26 30 -26",
	"insurance": "o 0 -32 27 -21 27 6 0 32 -27 6 -27 -21 0 -32;o -13 0 -3 12 14 -11",
	"oracle": "o -34 0 -15 -19 15 -19 34 0 15 19 -15 19 -34 0;C 0 0 10",
	"ricochet": "o -32 28 -11 -26 11 28 32 -26;P 34 -32 22 -20 36 -14",
	"cushion": "P -34 -9 34 -9 34 9 -34 9;l -34 -20 34 -20;l -34 20 34 20",
	"geometry": "o 0 -31 27 16 -27 16 0 -31;c 0 1 13",
	"tracer": "a 0 0 25 40 330;P 26 -22 30 -4 12 -10;C 0 0 7",
	"boomerang": "o -28 -26 20 0 -28 26;o -20 -26 28 0 -20 26",
	"precision": "c 0 0 24;l 0 -34 0 -14;l 0 14 0 34;l -34 0 -14 0;l 14 0 34 0;C 0 0 5",
	"stun": "c 0 0 30;P -12 -12 12 -12 12 12 -12 12",
	"afterburner": "P 34 0 6 -18 6 18;P 6 -8 -12 -8 -12 8 6 8;l -18 -13 -32 -13;l -20 0 -36 0;l -18 13 -32 13",
	"domino": "o -17 -32 17 -32 17 32 -17 32 -17 -32;l -17 0 17 0;C 0 -16 6;C -8 8 4;C 8 24 4",
	"rhythm": "C -13 22 9;C 15 15 9;l -5 22 -5 -25;l 23 15 23 -32;l -5 -25 23 -32;l -5 -14 23 -21",
	"hothand": FLAME + ";K 0 11 9",
	"comeback": "l 0 28 0 -24;o -19 -6 0 -28 19 -6;l -28 32 28 32",
	"collector": "o 0 -32 28 -16 28 16 0 32 -28 16 -28 -16 0 -32;C 0 -19 4;C 17 -9 4;C 17 9 4;C 0 19 4;C -17 9 4;C -17 -9 4",
	"migration": "c 0 0 16;c 0 0 29;C 0 0 7;l 0 -36 0 -29;l 0 29 0 36",
	"lowball": "c 0 0 29;t 0 0 34 1",
	"highball": "c 0 0 29;t 0 0 25 8+",
	"fibonacci": "o -30 -18 2 -18 2 14 -30 14 -30 -18;o 2 -18 20 -18 20 0 2 0;o 20 -18 30 -18 30 -8 20 -8",
	"rotation": "a 0 0 26 50 330;P 18 -28 32 -14 12 -10;t 0 0 25 1",
	"moneyball": "c 0 0 29;t -1 0 28 9;l 18 -32 18 -18;l 11 -25 25 -25",
	"thrift": "P -24 16 24 16 24 28 -24 28;P -24 0 24 0 24 12 -24 12;P -24 -16 24 -16 24 -4 -24 -4;C 0 -28 7",
	"venture": "l -28 28 24 -24;o 0 -28 28 -28 28 0",
	"hunter": "o " + STAR,
	"coupon": "o -32 -17 32 -17 32 17 -32 17 -32 -17;l 10 -17 10 -7;l 10 -3 10 3;l 10 7 10 17;C -11 0 7",
	"overflow": "o -23 -6 -17 30 17 30 23 -6;o -32 -18 -16 -28 0 -18 16 -28 32 -18;l -22 8 22 8",
	"glasscannon": "o 0 -32 26 -7 0 32 -26 -7 0 -32;l -26 -7 26 -7;l -9 -7 0 32;l 9 -7 0 32",
	"minimalist": "o -24 -24 24 -24 24 24 -24 24 -24 -24",
	"echo": "C -24 0 6;a -24 0 18 -70 70;a -24 0 34 -60 60;a -24 0 50 -45 45",
	"featherweight": "l -30 30 24 -26;o -18 18 -14 -14 28 -30 14 14 -18 18",
	"velvet": "o -34 -14 -20 -24 -6 -14 8 -24 20 -14 34 -24;o -34 6 -20 -4 -6 6 8 -4 20 6 34 -4;o -34 26 -20 16 -6 26 8 16 20 26 34 16",
	# Reagents
	"bluechalk": CUBE,
	"hand": "c 0 10 19;l 0 -34 0 -14;o -10 -24 0 -12 10 -24",
	"spare": CUBE + ";l 22 18 34 18;l 28 12 28 24",
	"forecast": "C -30 24 5;C -19 8 5;C -6 -6 5;C 9 -16 5;C 25 -21 5",
	"scatter": "C 0 0 7;l 0 -14 0 -32;l 0 14 0 32;l -14 0 -32 0;l 14 0 32 0;l -11 -11 -24 -24;l 11 -11 24 -24;l -11 11 -24 24;l 11 11 24 24",
	"freshrack": "o 0 -30 30 22 -30 22 0 -30;C 0 -8 6;C -9 9 6;C 9 9 6",
	"second": "a 0 0 26 300 600;P -4 -34 -4 -18 14 -26;t 0 1 24 2",
	"callshot": "C 0 8 16;K 0 8 10;l 0 -34 0 -14;o -10 -24 0 -12 10 -24",
	"adrenaline": "o -34 4 -18 4 -10 -22 2 26 12 4 34 4",
	"grant": "c 0 0 26;t 0 0 26 $;l 28 -30 28 -14;l 20 -22 36 -22",
	"wideopen": "a 0 0 12 0 360;o -32 0 -20 -8;o -32 0 -20 8;l -32 0 -17 0;o 32 0 20 -8;o 32 0 20 8;l 32 0 17 0",
	"magnetize": "a 0 -2 21 0 180;l -21 -2 -21 -24;l 21 -2 21 -24;C -28 28 3;C 0 32 3;C 28 28 3",
	"overcharge": "P -2 -34 16 -34 4 -8 18 -8 -14 34 -4 4 -16 4;t 24 22 19 2",
	"contract": "o -24 -32 24 -32 24 32 -24 32 -24 -32;l -14 -18 14 -18;l -14 -6 14 -6;o -12 16 -4 24 14 6",
	"hotswap": "P 0 -34 9 -20 12 -8 6 2 -6 2 -12 -8 -8 -18 -4 -12;l -26 18 26 18;o 17 10 27 18 17 26;o -17 10 -27 18 -17 26",
}

const FAMILY_COLORS := {
	"bank": Color(0.35, 0.8, 0.5), "cue": Color(0.45, 0.75, 1.0), "combo": Color(0.85, 0.5, 1.0),
	"streak": Color(1.0, 0.55, 0.25), "pocket": Color(1.0, 0.4, 0.4), "number": Color(1.0, 0.85, 0.35),
	"money": Color(0.75, 0.9, 0.3), "risk": Color(1.0, 0.35, 0.65), "physics": Color(0.4, 0.9, 0.9),
	"utility": Color(0.75, 0.78, 0.85), "reagent": Color(0.4, 0.65, 1.0),
}

var motif := ""
var tint := Color.WHITE
var font: Font


func setup(id: String, f: Font, px: float) -> IconArt:
	motif = MOTIFS.get(id, "")
	font = f
	var fam: String = Catalog.PERKS[id].get("fam", "utility") if Catalog.PERKS.has(id) else "reagent"
	tint = FAMILY_COLORS.get(fam, Color.WHITE)
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self


func _draw() -> void:
	var side := minf(size.x, size.y)
	var c := size * 0.5
	var u := side / 100.0
	var dark := Color(0.09, 0.09, 0.11)
	draw_circle(c, 49.0 * u, tint.darkened(0.55))
	draw_circle(c, 45.0 * u, dark)
	draw_arc(c, 47.0 * u, 0.0, TAU, 48, tint, maxf(1.5, 2.5 * u), true)
	paint(self, motif, c, u, tint, dark, font, maxf(1.5, 3.4 * u))


## Draws a motif onto any canvas item (card medallions, table decals).
static func paint(ci: CanvasItem, script: String, c: Vector2, u: float, tint: Color, dark: Color, f: Font, w: float) -> void:
	for op: String in script.split(";", false):
		var a := op.strip_edges().split(" ", false)
		if a.is_empty():
			continue
		var v: Array[float] = []
		var kind: String = a[0]
		if kind == "t" or kind == "T":
			if a.size() < 5:
				continue
			var fs := int(round(float(a[3]) * u))
			var txt := " ".join(a.slice(4))
			var tw := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var pos := c + Vector2(float(a[1]), float(a[2])) * u + Vector2(-tw * 0.5, fs * 0.36)
			ci.draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tint if kind == "t" else Color.WHITE)
			continue
		for i in range(1, a.size()):
			v.append(float(a[i]))
		var pts := PackedVector2Array()
		for i in range(0, v.size() - 1, 2):
			pts.append(c + Vector2(v[i], v[i + 1]) * u)
		match kind:
			"c":
				ci.draw_arc(c + Vector2(v[0], v[1]) * u, v[2] * u, 0.0, TAU, 40, tint, w, true)
			"C":
				ci.draw_circle(c + Vector2(v[0], v[1]) * u, v[2] * u, tint)
			"K":
				ci.draw_circle(c + Vector2(v[0], v[1]) * u, v[2] * u, dark)
			"l", "o":
				ci.draw_polyline(pts, tint, w, true)
			"P":
				ci.draw_colored_polygon(pts, tint)
			"a":
				ci.draw_arc(c + Vector2(v[0], v[1]) * u, v[2] * u, deg_to_rad(v[3]), deg_to_rad(v[4]), 28, tint, w, true)
