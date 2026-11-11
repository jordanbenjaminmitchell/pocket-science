extends SceneTree
## Draws every app icon from one vector scene (works with --headless):
## Godot --headless --path . --script res://tools/make_icon.gd
##
## The scene uses Android's adaptive icon grid: 108 units across, of which a
## launcher mask shows the middle 72 and only a radius of 33 is always safe.
##
## The mark is a carbon atom: a small 8-ball nucleus inside three long, thin
## orbits 60 degrees apart, and 6 electrons, the 1- to 5-balls and the cue ball, two on each
## orbit. Every electron sits at the same point along its own orbit, so the six
## are evenly spaced around the nucleus.
##
## For previews, set PS_ICON_OUT to a folder to write there instead of assets/.

const C := 54.0
const ORBIT_RX := 32.0
const ORBIT_RY := 12.0
const ORBIT_ANGLES := [15.0, 75.0, 135.0]
## Where each electron sits along its orbit, in degrees from the orbit's tip, as
## [one side, the other] per orbit. Staggered so no two pairs line up in parallel;
## every electron stays 18+ units from the others and clear of the 8-ball.
## LogoArt.START_AT must match.
const ELECTRON_AT := [[20.0, 215.0], [325.0, 160.0], [50.0, 190.0]]
const BALL_R := 11.5
const ELECTRON_R := 5.0
## Ball colours by number: light and dark.
const BALL_COLOURS := {
	1: ["#ffd84a", "#a87a04"], 2: ["#4f8ff0", "#0f2f80"], 3: ["#ff4f45", "#8a0f12"],
	4: ["#9a5ae0", "#3a1470"], 5: ["#ff9a3c", "#a43e00"], 6: ["#ffffff", "#d6cfb8"],
}
## The sixth electron is the cue ball: plain white, no number.
const CUE := 6
## Number glyphs as stroked paths, 7 units tall, centred on 0,0.
const DIGITS := {
	1: "M-1.4,-2.3 L0,-3.5 L0,3.5",
	2: "M-2,-1.8 C-2,-3.8 2.1,-3.8 2.1,-1.6 C2.1,0 -2,1.6 -2,3.5 L2.2,3.5",
	3: "M-2,-3.5 L2,-3.5 L-0.3,-0.6 C2.6,-0.8 2.6,3.6 -0.1,3.6 C-1.2,3.6 -1.9,3.1 -2.2,2.6",
	4: "M1.1,3.5 L1.1,-3.5 L-2.3,1.5 L2.4,1.5",
	5: "M2,-3.5 L-1.6,-3.5 L-2,-0.1 C0.8,-1.5 2.5,-0.2 2.3,1.6 C2.1,3.7 -0.9,4.1 -2.2,2.8",
}

var out_dir := "res://assets"
## PS_ICON_STYLE: "3d" (the game icon, and the default: shaded balls with tube rings
## that wrap in front of the 8-ball as well as behind it), "flat" (everything flat,
## solid colours with outlines) or "classic" (shaded balls on flat rings).
var style := "3d"
## [position, number, light colour, dark colour], numbered clockwise from the top.
var ELECTRONS := []


func _initialize() -> void:
	var spots := []
	for o in ORBIT_ANGLES.size():
		var a: float = ORBIT_ANGLES[o]
		for side in 2:
			var t := deg_to_rad(ELECTRON_AT[o][side])
			spots.append(Vector2(C, C) + Vector2(ORBIT_RX * cos(t), ORBIT_RY * sin(t)).rotated(deg_to_rad(a)))
	spots.sort_custom(func(p, q): return fposmod((p - Vector2(C, C)).angle() + PI * 0.5, TAU) < fposmod((q - Vector2(C, C)).angle() + PI * 0.5, TAU))
	for i in spots.size():
		ELECTRONS.append([spots[i], i + 1, BALL_COLOURS[i + 1][0], BALL_COLOURS[i + 1][1]])
	if OS.get_environment("PS_ICON_OUT") != "":
		out_dir = OS.get_environment("PS_ICON_OUT")
	if OS.get_environment("PS_ICON_STYLE") != "":
		style = OS.get_environment("PS_ICON_STYLE")
	var failed := 0
	failed += _save(_render(_felt(true) + _art(), "18 18 72 72", 512), out_dir + "/icon.png")
	failed += _save(_render(_art(), "0 0 108 108", 432), out_dir + "/icon/foreground.png")
	failed += _save(_render(_felt(false), "0 0 108 108", 432), out_dir + "/icon/background.png")
	failed += _save(_to_alpha(_render(_mono(), "0 0 108 108", 432)), out_dir + "/icon/monochrome.png")
	print("ICON DONE, failures: ", failed)
	quit(1 if failed > 0 else 0)


func _render(body: String, view: String, px: int) -> Image:
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="%s">%s%s</svg>' % [px, px, view, _defs(), body]
	var img := Image.new()
	img.load_svg_from_string(svg, 1.0)
	img.convert(Image.FORMAT_RGBA8)
	return img


func _save(img: Image, path: String) -> int:
	var abs_path := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	return 1 if img.is_empty() or img.save_png(abs_path) != OK else 0


## Scale from the original 19-unit 8-ball, so the 8 and its shine keep their proportions.
func _s() -> float:
	return BALL_R / 19.0


func _defs() -> String:
	var s := _s()
	var defs := """<defs>
	<radialGradient id="felt" gradientUnits="userSpaceOnUse" cx="54" cy="44" r="58">
		<stop offset="0" stop-color="#27b67c"/><stop offset="0.55" stop-color="#128259"/><stop offset="1" stop-color="#07493a"/>
	</radialGradient>
	<radialGradient id="ball" gradientUnits="userSpaceOnUse" cx="%.2f" cy="%.2f" r="%.2f">
		<stop offset="0" stop-color="#55556a"/><stop offset="0.4" stop-color="#1b1b24"/><stop offset="1" stop-color="#040406"/>
	</radialGradient>
	<radialGradient id="rim" gradientUnits="userSpaceOnUse" cx="%.2f" cy="%.2f" r="%.2f">
		<stop offset="0.76" stop-color="#7fb6e6" stop-opacity="0"/><stop offset="1" stop-color="#7fb6e6" stop-opacity="0.7"/>
	</radialGradient>
	<radialGradient id="shine" cx="0.5" cy="0.5" r="0.5">
		<stop offset="0" stop-color="#ffffff" stop-opacity="0.85"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
	</radialGradient>
	<radialGradient id="drop" gradientUnits="userSpaceOnUse" cx="%.2f" cy="%.2f" r="%.2f">
		<stop offset="0.7" stop-color="#02241b" stop-opacity="0.65"/><stop offset="1" stop-color="#02241b" stop-opacity="0"/>
	</radialGradient>""" % [C - 7.0 * s, C - 9.0 * s, 30.0 * s, C - 4.0 * s, C - 4.0 * s, 24.5 * s, C + 2.0 * s, C + 5.0 * s, 24.0 * s]
	for i in ELECTRONS.size():
		var p := _electron_pos(i)
		defs += """
	<radialGradient id="e%d" gradientUnits="userSpaceOnUse" cx="%.2f" cy="%.2f" r="%.2f">
		<stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/>
	</radialGradient>""" % [i, p.x - 1.6, p.y - 1.9, ELECTRON_R * 1.6, ELECTRONS[i][2], ELECTRONS[i][3]]
	# 3D rings: gold lit from the top left, darker towards the bottom right.
	defs += """
	<linearGradient id="tube" gradientUnits="userSpaceOnUse" x1="22" y1="22" x2="86" y2="86">
		<stop offset="0" stop-color="#ffe49a"/><stop offset="0.45" stop-color="#f2b232"/><stop offset="1" stop-color="#a5650c"/>
	</linearGradient>"""
	return defs + "</defs>"


func _felt(rounded: bool) -> String:
	var fill := "#13905f" if style == "flat" else "url(#felt)"
	return ('<rect x="18" y="18" width="72" height="72" rx="15" fill="%s"/>' if rounded \
		else '<rect width="108" height="108" fill="%s"/>') % fill


## The near half of every orbit, drawn again after the 8-ball so the rings wrap round it.
func _orbit_front(stroke: String, width: float, extra := "") -> String:
	var out := ""
	for a in ORBIT_ANGLES:
		out += '<path d="M %.2f 0 A %.2f %.2f 0 0 1 %.2f 0" transform="translate(54 54) rotate(%.1f)" fill="none" stroke="%s" stroke-width="%.2f" stroke-linecap="round" %s/>' % [ORBIT_RX, ORBIT_RX, ORBIT_RY, -ORBIT_RX, a, stroke, width, extra]
	return out


## Shaded tube rings: a soft shadow on the felt, a dark edge, the lit gold body and a thin highlight.
func _tubes(front: bool) -> String:
	var f := func(st: String, w: float, extra := "") -> String: return _orbit_front(st, w, extra) if front else _orbit(st, w, extra)
	var out := ""
	if not front:
		out += '<g transform="translate(0.9 1.6)">' + _orbit("#02241b", 5.0, 'stroke-opacity="0.45"') + '</g>'
	out += f.call("#6b3f05", 4.6)
	out += f.call("url(#tube)", 3.4)
	out += '<g transform="translate(-0.35 -0.55)">' + f.call("#fff6d8", 0.8, 'stroke-opacity="0.85"') + '</g>'
	return out


## Everything flat: solid fills and one outline colour, no gradients, shine or shadows.
func _art_flat() -> String:
	var ink := "#0b2a20"
	var out := _orbit(ink, 5.0)
	out += _orbit("#f5b83a", 3.2)
	out += '<circle cx="54" cy="54" r="%.2f" fill="#15151c" stroke="%s" stroke-width="1.6"/>' % [BALL_R, ink]
	out += '<circle cx="54" cy="54" r="%.2f" fill="#fff8e8"/>' % (9.7 * _s())
	out += _eight("#15151c")
	for i in ELECTRONS.size():
		var p := _electron_pos(i)
		out += '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="%s" stroke="%s" stroke-width="1.3"/>' % [p.x, p.y, ELECTRON_R, ELECTRONS[i][2], ink]
		if ELECTRONS[i][1] != CUE:
			out += '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="#fff8e8"/>' % [p.x, p.y, ELECTRON_R * 0.56]
			out += _digit(ELECTRONS[i][1], p, "#15151c")
	return out


## Everything 3D: the shaded balls of the game icon, with tube rings around the 8-ball.
func _art_3d() -> String:
	var out := _tubes(false)
	out += _nucleus()
	out += _tubes(true)
	out += _electrons()
	return out


## Where electron i sits (worked out in _initialize).
func _electron_pos(i: int) -> Vector2:
	return ELECTRONS[i][0]


func _orbit(stroke: String, width: float, extra := "") -> String:
	var out := ""
	for a in ORBIT_ANGLES:
		out += '<ellipse cx="54" cy="54" rx="%.1f" ry="%.1f" transform="rotate(%.1f 54 54)" fill="none" stroke="%s" stroke-width="%.2f" %s/>' % [ORBIT_RX, ORBIT_RY, a, stroke, width, extra]
	return out


func _eight(stroke: String) -> String:
	var s := _s()
	var body := '<ellipse cx="54" cy="%.2f" rx="%.2f" ry="%.2f" fill="none" stroke="%s" stroke-width="%.2f"/>'
	return body % [C - 3.45 * s, 2.75 * s, 2.55 * s, stroke, 2.0 * s] + body % [C + 3.0 * s, 3.35 * s, 3.1 * s, stroke, 2.0 * s]


func _digit(n: int, p: Vector2, stroke: String) -> String:
	if not DIGITS.has(n):
		return ""
	var k := ELECTRON_R * 0.072
	return '<path d="%s" transform="translate(%.2f %.2f) scale(%.3f)" fill="none" stroke="%s" stroke-width="%.2f" stroke-linecap="round" stroke-linejoin="round"/>' % [DIGITS[n], p.x, p.y, k, stroke, 1.25]


func _nucleus() -> String:
	var s := _s()
	var out := '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="url(#drop)"/>' % [C + 2.0 * s, C + 5.0 * s, 24.0 * s]
	out += '<circle cx="54" cy="54" r="%.2f" fill="url(#ball)"/>' % BALL_R
	out += '<circle cx="54" cy="54" r="%.2f" fill="url(#rim)"/>' % BALL_R
	out += '<circle cx="54" cy="54" r="%.2f" fill="#fff8e8"/>' % (9.7 * s)
	out += _eight("#101016")
	var sh := Vector2(C - 8.5 * s, C - 10.5 * s)
	out += '<ellipse cx="%.2f" cy="%.2f" rx="%.2f" ry="%.2f" transform="rotate(-38 %.2f %.2f)" fill="url(#shine)"/>' % [sh.x, sh.y, 6.8 * s, 3.9 * s, sh.x, sh.y]
	return out


func _art() -> String:
	if style == "flat":
		return _art_flat()
	if style == "3d":
		return _art_3d()
	var out := _orbit("#02281e", 5.4, 'stroke-opacity="0.6"')
	out += _orbit("#f7bf45", 3.3)
	out += _orbit("#ffe9ad", 0.9)
	out += _nucleus()
	out += _electrons()
	return out


func _electrons() -> String:
	var out := ""
	for i in ELECTRONS.size():
		var p := _electron_pos(i)
		out += '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="#02241b" fill-opacity="0.6"/>' % [p.x + 0.5, p.y + 0.9, ELECTRON_R + 0.8]
		out += '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="url(#e%d)"/>' % [p.x, p.y, ELECTRON_R, i]
		if ELECTRONS[i][1] != CUE:
			out += '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="#fff8e8"/>' % [p.x, p.y, ELECTRON_R * 0.56]
			out += _digit(ELECTRONS[i][1], p, "#101016")
		out += '<ellipse cx="%.2f" cy="%.2f" rx="1.5" ry="0.8" transform="rotate(-38 %.2f %.2f)" fill="#ffffff" fill-opacity="0.75"/>' % [p.x - 2.4, p.y - 2.9, p.x - 2.4, p.y - 2.9]
	return out


## Android 13 tints this one to match the wallpaper: shape only, drawn as
## white on black, then the brightness becomes the transparency.
func _mono() -> String:
	var out := '<rect width="108" height="108" fill="#000000"/>'
	out += _orbit("#ffffff", 3.3)
	out += '<circle cx="54" cy="54" r="%.2f" fill="#000000"/>' % (BALL_R + 2.0)
	out += '<circle cx="54" cy="54" r="%.2f" fill="#ffffff"/>' % BALL_R
	out += '<circle cx="54" cy="54" r="%.2f" fill="#000000"/>' % (9.7 * _s())
	out += _eight("#ffffff")
	for i in ELECTRONS.size():
		var p := _electron_pos(i)
		out += '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="#000000"/>' % [p.x, p.y, ELECTRON_R + 1.8]
		out += '<circle cx="%.2f" cy="%.2f" r="%.2f" fill="#ffffff"/>' % [p.x, p.y, ELECTRON_R]
		out += _digit(ELECTRONS[i][1], p, "#000000")
	return out


func _to_alpha(img: Image) -> Image:
	for y in img.get_height():
		for x in img.get_width():
			img.set_pixel(x, y, Color(1, 1, 1, img.get_pixel(x, y).r))
	return img
