extends SceneTree
## Draws every app icon from one vector scene (works with --headless):
## Godot --headless --path . --script res://tools/make_icon.gd
##
## The scene uses Android's adaptive icon grid: 108 units across, of which a
## launcher mask shows the middle 72 and only a radius of 33 is always safe.

const C := 54.0
const ORBIT_RX := 31.0
const ORBIT_RY := 12.5
const ORBIT_ANGLES := [0.0, 60.0, -60.0]
const BALL_R := 19.0
## Per orbit: where its ball sits (degrees around the ellipse) and its colours.
const ELECTRONS := [
	[198.0, "#ffffff", "#e6dfca"],
	[160.0, "#ff5a4f", "#a3121b"],
	[20.0, "#4fa8ff", "#1147a8"],
]


func _initialize() -> void:
	var failed := 0
	failed += _save(_render(_felt(true) + _art(), "18 18 72 72", 512), "res://assets/icon.png")
	failed += _save(_render(_art(), "0 0 108 108", 432), "res://assets/icon/foreground.png")
	failed += _save(_render(_felt(false), "0 0 108 108", 432), "res://assets/icon/background.png")
	failed += _save(_to_alpha(_render(_mono(), "0 0 108 108", 432)), "res://assets/icon/monochrome.png")
	print("ICON DONE, failures: ", failed)
	quit(1 if failed > 0 else 0)


func _render(body: String, view: String, px: int) -> Image:
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="%s">%s%s</svg>' % [px, px, view, _defs(), body]
	var img := Image.new()
	img.load_svg_from_string(svg, 1.0)
	img.convert(Image.FORMAT_RGBA8)
	return img


func _save(img: Image, path: String) -> int:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	return 1 if img.is_empty() or img.save_png(path) != OK else 0


func _defs() -> String:
	var defs := """<defs>
	<radialGradient id="felt" gradientUnits="userSpaceOnUse" cx="54" cy="44" r="58">
		<stop offset="0" stop-color="#27b67c"/><stop offset="0.55" stop-color="#128259"/><stop offset="1" stop-color="#07493a"/>
	</radialGradient>
	<radialGradient id="ball" gradientUnits="userSpaceOnUse" cx="47" cy="45" r="30">
		<stop offset="0" stop-color="#55556a"/><stop offset="0.4" stop-color="#1b1b24"/><stop offset="1" stop-color="#040406"/>
	</radialGradient>
	<radialGradient id="rim" gradientUnits="userSpaceOnUse" cx="50" cy="50" r="24.5">
		<stop offset="0.76" stop-color="#7fb6e6" stop-opacity="0"/><stop offset="1" stop-color="#7fb6e6" stop-opacity="0.7"/>
	</radialGradient>
	<radialGradient id="shine" cx="0.5" cy="0.5" r="0.5">
		<stop offset="0" stop-color="#ffffff" stop-opacity="0.85"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
	</radialGradient>
	<radialGradient id="drop" gradientUnits="userSpaceOnUse" cx="56" cy="59" r="24">
		<stop offset="0.7" stop-color="#02241b" stop-opacity="0.65"/><stop offset="1" stop-color="#02241b" stop-opacity="0"/>
	</radialGradient>"""
	for i in ELECTRONS.size():
		var p := _electron_pos(i)
		defs += """
	<radialGradient id="e%d" gradientUnits="userSpaceOnUse" cx="%.2f" cy="%.2f" r="7.5">
		<stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/>
	</radialGradient>""" % [i, p.x - 1.5, p.y - 1.8, ELECTRONS[i][1], ELECTRONS[i][2]]
	return defs + "</defs>"


func _felt(rounded: bool) -> String:
	return '<rect x="18" y="18" width="72" height="72" rx="15" fill="url(#felt)"/>' if rounded \
		else '<rect width="108" height="108" fill="url(#felt)"/>'


func _electron_pos(i: int) -> Vector2:
	var t := deg_to_rad(float(ELECTRONS[i][0]))
	return Vector2(C, C) + Vector2(ORBIT_RX * cos(t), ORBIT_RY * sin(t)).rotated(deg_to_rad(ORBIT_ANGLES[i]))


func _orbit(stroke: String, width: float, extra := "") -> String:
	var out := ""
	for a in ORBIT_ANGLES:
		out += '<ellipse cx="54" cy="54" rx="%.1f" ry="%.1f" transform="rotate(%.1f 54 54)" fill="none" stroke="%s" stroke-width="%.2f" %s/>' % [ORBIT_RX, ORBIT_RY, a, stroke, width, extra]
	return out


func _eight(stroke: String) -> String:
	var body := '<ellipse cx="54" cy="%.2f" rx="%.2f" ry="%.2f" fill="none" stroke="%s" stroke-width="2.0"/>'
	return body % [50.55, 2.75, 2.55, stroke] + body % [57.0, 3.35, 3.1, stroke]


func _art() -> String:
	var out := _orbit("#02281e", 5.4, 'stroke-opacity="0.6"')
	out += _orbit("#f7bf45", 3.3)
	out += _orbit("#ffe9ad", 0.9)
	out += '<circle cx="56" cy="59" r="24" fill="url(#drop)"/>'
	out += '<circle cx="54" cy="54" r="%.1f" fill="url(#ball)"/>' % BALL_R
	out += '<circle cx="54" cy="54" r="%.1f" fill="url(#rim)"/>' % BALL_R
	out += '<circle cx="54" cy="54" r="9.7" fill="#fff8e8"/>'
	out += _eight("#101016")
	out += '<ellipse cx="45.5" cy="43.5" rx="6.8" ry="3.9" transform="rotate(-38 45.5 43.5)" fill="url(#shine)"/>'
	for i in ELECTRONS.size():
		var p := _electron_pos(i)
		out += '<circle cx="%.2f" cy="%.2f" r="5.6" fill="#02241b" fill-opacity="0.55"/>' % [p.x + 0.4, p.y + 0.8]
		out += '<circle cx="%.2f" cy="%.2f" r="4.8" fill="url(#e%d)"/>' % [p.x, p.y, i]
		out += '<circle cx="%.2f" cy="%.2f" r="1.2" fill="#ffffff" fill-opacity="0.9"/>' % [p.x - 1.5, p.y - 1.7]
	return out


## Android 13 tints this one to match the wallpaper: shape only, drawn as
## white on black, then the brightness becomes the transparency.
func _mono() -> String:
	var out := '<rect width="108" height="108" fill="#000000"/>'
	out += _orbit("#ffffff", 3.3)
	out += '<circle cx="54" cy="54" r="%.1f" fill="#000000"/>' % (BALL_R + 2.0)
	out += '<circle cx="54" cy="54" r="%.1f" fill="#ffffff"/>' % BALL_R
	out += '<circle cx="54" cy="54" r="9.7" fill="#000000"/>'
	out += _eight("#ffffff")
	for i in ELECTRONS.size():
		var p := _electron_pos(i)
		out += '<circle cx="%.2f" cy="%.2f" r="6.6" fill="#000000"/>' % [p.x, p.y]
		out += '<circle cx="%.2f" cy="%.2f" r="4.8" fill="#ffffff"/>' % [p.x, p.y]
	return out


func _to_alpha(img: Image) -> Image:
	for y in img.get_height():
		for x in img.get_width():
			img.set_pixel(x, y, Color(1, 1, 1, img.get_pixel(x, y).r))
	return img
