class_name BallNode
extends Node2D
## One rendered ball: soft contact shadow, shader-lit rolling sphere, and the
## number printed on whichever number disc currently faces the camera.

const SHADER := preload("res://src/view/shaders/ball.gdshader")
const PAD := 1.18
## The two poses a ball can come to rest in: a number disc facing the viewer, its
## digit upright and the stripe level. Each ball has a number on both sides.
const REST_BASIS := Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0))
const REST_FLIPPED := Basis(Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0))
## The ball always turns exactly as far as it rolls. Past these turns per frame the
## print blurs out (fully by BLUR_FULL), before the eye could read it as turning backwards.
const BLUR_START := 0.35
const BLUR_FULL := 1.1
## Over its last stretch a ball eases into a rest pose: how much of each radian
## rolled may go to correction, and how many radians from the stop that starts.
const STEER_GAIN := 0.75
const STEER_GAIN_LATE := 2.2
const STEER_RANGE := 5.5
## Any correction left at the stop is finished gently: longer the bigger it is.
const REST_EASE_TIME := 0.16
const REST_EASE_PER_RADIAN := 0.22
## Digits are rasterised this much larger and scaled down, so they stay smooth
## when the table is scaled up on a big or high-density screen.
const DIGIT_SUPERSAMPLE := 2.5

var number := 0
var radius := TableLayout.R
var basis := REST_BASIS
var quad: ColorRect
var mat: ShaderMaterial
var label_node: Node2D
var font: Font
var glow := Color(0, 0, 0, 0)
var sinking := false
var fade := 1.0
var vel := Vector2.ZERO
var shown_settled := 1.0
var rest_tween: Tween
var emblem := ""          # Exotic balls show this motif instead of a number
var emblem_ink := Color.BLACK
var aura: Node2D               # Imbued balls: ring and orbiting spark, drawn over the ball
var aura_t := 0.0
var spin_blur := 0.0
## A themed particle effect around the ball ("" for none): set by its Imbue, or by
## its special type. Drawn from aura_t alone, so it costs no particle arrays.
var fx_style := ""
var fx_color := Color.WHITE

## Imbue -> particle style. Each Imbue also glows in its own colour.
const IMBUE_FX := {
	"spark": "spark", "gold": "glint", "heavy": "sink", "glass": "glint", "ember": "ember",
	"vein": "rise", "lucky": "rise", "frosted": "frost", "magnetic": "field", "charged": "spark",
	"prismatic": "rainbow", "hollow": "hollow", "leaded": "sink", "bounty": "glint", "starry": "stars", "twin": "echo",
	"volatile": "spark", "jinxed": "void", "pawned": "glint", "mirror": "echo",
}
## Exotic ball type -> particle style.
const FX_SIZE := 1.6
const BALL_FX := {
	"void": "void", "frost": "frost", "ember": "ember", "star": "stars", "sun": "rays", "gold": "glint",
	"magnet": "field", "glass": "glint", "bomb": "spark", "heart": "rise", "clover": "rise", "prism": "rainbow",
}


func setup(n: int, f: Font, rng: RandomNumberGenerator) -> void:
	number = n
	font = f
	quad = ColorRect.new()
	var half := radius * PAD
	quad.size = Vector2(half, half) * 2.0
	quad.position = -Vector2(half, half)
	quad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("base_color", Catalog.ball_color(n))
	mat.set_shader_parameter("stripe", 1.0 if Catalog.is_stripe(n) else 0.0)
	var kind := Catalog.kind_of(n)
	if kind != "":
		var bt: Dictionary = Catalog.BALL_TYPES[kind]
		mat.set_shader_parameter("pattern", int(bt.pattern))
		mat.set_shader_parameter("accent_color", bt.accent)
		emblem = bt.motif
		if BALL_FX.has(kind):
			fx_style = BALL_FX[kind]
			fx_color = bt.color if (bt.color as Color).get_luminance() > 0.25 else bt.accent
		var c: Color = bt.color
		emblem_ink = c.darkened(0.2) if c.get_luminance() < 0.7 else (bt.accent as Color).darkened(0.25)
	mat.set_shader_parameter("is_cue", 1.0 if n == 0 else 0.0)
	mat.set_shader_parameter("radius_uv", 1.0 / PAD)
	mat.set_shader_parameter("disc_alpha", 0.0)   # starts at rest, with the upright number
	quad.material = mat
	add_child(quad)
	label_node = Node2D.new()
	label_node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	label_node.draw.connect(_draw_number)
	add_child(label_node)
	aura = Node2D.new()
	aura.draw.connect(_draw_aura)
	add_child(aura)
	basis = REST_FLIPPED if rng.randi() % 2 == 0 else REST_BASIS
	_push()


func set_glow(c: Color, style: String = "") -> void:
	glow = c
	mat.set_shader_parameter("glow_color", c)
	if style != "":
		fx_style = style
		fx_color = Color(c, 1.0)
	elif c.a <= 0.0 and not BALL_FX.has(Catalog.kind_of(number)):
		fx_style = ""
	set_process(c.a > 0.0 or fx_style != "")
	queue_redraw()
	if aura:
		aura.queue_redraw()


func _process(delta: float) -> void:
	aura_t += delta
	aura.queue_redraw()
	if glow.a > 0.0:
		queue_redraw()   # the soft halo pulses


## An Imbue is unmissable: a bright ring in its colour, a soft pulse and a spark
## that circles the ball, so imbued balls read at a glance even across the table.
func _draw_aura() -> void:
	if fade <= 0.05:
		return
	if not Fx.minimal_particles and fx_style != "":
		_draw_fx()
	if glow.a <= 0.0:
		return
	var pulse := 0.5 + 0.5 * sin(aura_t * 3.2)
	var r := radius * 1.18
	aura.draw_arc(Vector2.ZERO, r + 2.0 + pulse * 2.0, 0, TAU, 40, Color(glow, 0.25 * fade), 4.0, true)
	aura.draw_arc(Vector2.ZERO, r, 0, TAU, 40, Color(glow, 0.95 * fade), 2.2, true)
	if Fx.minimal_particles:
		return   # the ring alone marks the Imbue; no orbiting sparks
	var ang := aura_t * 2.4
	var sp := Vector2(cos(ang), sin(ang)) * r
	aura.draw_circle(sp, 3.2, Color(glow.lightened(0.4), fade))
	aura.draw_circle(sp, 1.6, Color(1, 1, 1, fade))
	var sp2 := Vector2(cos(ang + PI), sin(ang + PI)) * r
	aura.draw_circle(sp2, 2.0, Color(glow, 0.7 * fade))


## Move to a new table position, rolling the sphere by the distance travelled.
## `stop_in` is the distance left before the ball stops (negative if unknown).
## `extra` is roll with no matching travel (draw and follow biting the cloth), and
## `twist` is rotation about the vertical axis in radians (side english).
func roll_to(p: Vector2, stop_in: float = -1.0, extra: Vector2 = Vector2.ZERO, twist: float = 0.0) -> void:
	var d := p - position
	position = p
	var rolled := d + extra
	var turn := rolled.length() / radius
	if turn <= 0.0001 and twist == 0.0:
		return
	if turn > 0.0001:
		# View space: X right, Y up (screen y flipped), Z toward the camera.
		var axis := Vector3(rolled.y, rolled.x, 0.0).normalized()
		basis = Basis(axis, turn) * basis
		if stop_in >= 0.0 and number != 0:
			_steer_to_rest(axis, stop_in / radius, d.length() / radius)
	if twist != 0.0:
		basis = Basis(Vector3(0, 0, 1), twist) * basis
	basis = basis.orthonormalized()
	_set_blur(smoothstep(BLUR_START, BLUR_FULL, turn))
	_push()


func _set_blur(b: float) -> void:
	if absf(b - spin_blur) > 0.01 or (b == 0.0 and spin_blur != 0.0):
		spin_blur = b
		mat.set_shader_parameter("blur", b)


## Bends the roll toward the pose that, rolled the remaining distance, lands on a
## rest pose. Correction is paid for out of real travel, so a ball never turns
## unless it is moving.
func _steer_to_rest(axis: Vector3, turns_left: float, travelled: float) -> void:
	if turns_left > STEER_RANGE:
		return
	var back := Basis(axis, -turns_left)
	var now := Quaternion(basis)
	var a := Quaternion(back * REST_BASIS)
	var b := Quaternion(back * REST_FLIPPED)
	var want := a if now.angle_to(a) <= now.angle_to(b) else b
	var off := now.angle_to(want)
	if off > 0.0001:
		# A cushion can cut the roll short, so a late, large error is allowed to work harder.
		var gain := clampf(off / maxf(turns_left, 0.05), STEER_GAIN, STEER_GAIN_LATE)
		basis = Basis(now.slerp(want, minf(1.0, gain * travelled / off)))


func nearest_rest() -> Basis:
	var now := Quaternion(basis)
	return REST_BASIS if now.angle_to(Quaternion(REST_BASIS)) <= now.angle_to(Quaternion(REST_FLIPPED)) else REST_FLIPPED


func _push() -> void:
	_push_orientation()
	label_node.queue_redraw()


func _push_orientation() -> void:
	mat.set_shader_parameter("orient", basis)


func _draw() -> void:
	if fade <= 0.01:
		return
	# Motion streak for fast balls.
	var sp := vel.length()
	if sp > 700.0 and not sinking:
		var back := -vel / sp
		var n := int(clampf((sp - 700.0) / 300.0, 1.0, 4.0))
		var col := Catalog.ball_color(number) if number != 0 else Color(1, 1, 1)
		for k in n:
			var off2 := back * (k + 1) * 6.0 * clampf(sp / 1500.0, 0.5, 1.5)
			draw_circle(off2, radius * (0.9 - k * 0.12), Color(col, 0.12 - k * 0.025))
	# An Imbue's soft glow in its own colour, under the ball.
	if glow.a > 0.0 and not sinking:
		var pulse := 0.5 + 0.5 * sin(aura_t * 2.6)
		for k in 4:
			draw_circle(Vector2.ZERO, radius * (1.75 - k * 0.15 + pulse * 0.08), Color(glow, (0.05 + k * 0.025) * fade), true, -1.0, true)
	# Contact shadow, offset away from the lamp.
	var off := Vector2(3.0, 4.5)
	for i in 5:
		var r := radius * (1.25 - i * 0.07)
		draw_circle(off, r, Color(0, 0, 0, 0.09 * fade))
	draw_circle(Vector2(0.6, 1.2), radius * 0.92, Color(0, 0, 0, 0.25 * fade))


## Call when the speed changes. A moving ball shows only what is printed on it.
## Once stopped it finishes any small correction and shows its upright number.
## The themed particles, all worked out from aura_t: frost drifting off, embers
## rising, a void pulling motes in, sparks crackling, stars twinkling...
func _draw_fx() -> void:
	var t := aura_t
	var r := radius
	var c := fx_color
	var a0 := fade
	var u := FX_SIZE   # particles big and bold enough to read across the table
	match fx_style:
		"frost":
			for i in 6:
				var ph := fmod(t * 0.3 + i / 6.0, 1.0)
				var ang := i * TAU / 6.0 + t * 0.15 + ph * 0.6
				var p := Vector2(cos(ang), sin(ang)) * r * (1.05 + ph * 0.95)
				var sz := 2.6 * u * (1.0 - ph * 0.4)
				var col := Color(0.88, 0.97, 1.0, (1.0 - ph) * 0.95 * a0)
				for k in 3:
					var d := Vector2(cos(k * PI / 3.0 + t), sin(k * PI / 3.0 + t)) * sz
					aura.draw_line(p - d, p + d, col, 1.1 * u, true)
		"ember":
			for i in 7:
				var ph := fmod(t * 0.55 + i / 7.0, 1.0)
				var p := Vector2(sin(i * 2.1 + t * 1.4) * r * 0.75, -r * (0.4 + ph * 1.7))
				aura.draw_circle(p, 1.8 * u * (1.0 - ph * 0.6), Color(Color(1.0, 0.45, 0.1).lerp(Color(1.0, 0.9, 0.4), ph), (1.0 - ph) * a0), true, -1.0, true)
		"void":
			aura.draw_circle(Vector2.ZERO, r * 1.45, Color(0.12, 0.02, 0.2, 0.28 * a0), true, -1.0, true)
			for i in 9:
				var ph := fmod(t * 0.45 + i / 9.0, 1.0)
				var ang := i * TAU / 9.0 - ph * 2.8 + t * 0.25
				var p := Vector2(cos(ang), sin(ang)) * r * (2.2 - ph * 1.15)
				aura.draw_circle(p, (0.8 + ph * 1.6) * u, Color(0.55, 0.25, 0.85, ph * 0.9 * a0), true, -1.0, true)
		"spark":
			for i in 3:
				var tick := floorf(t * 9.0) + i * 17.0
				var ang := fmod(sin(tick * 12.9898) * 43758.5453, TAU)
				var dir := Vector2(cos(ang), sin(ang))
				var p0 := dir * r * 1.05
				var mid := p0 + dir * r * 0.3 + dir.orthogonal() * r * 0.18
				aura.draw_polyline(PackedVector2Array([p0, mid, p0 + dir * r * 0.6]), Color(c.lightened(0.5), 0.95 * a0), 1.4 * u, true)
		"stars":
			for i in 5:
				var ang := i * TAU / 5.0 + 0.4 + t * 0.1
				var p := Vector2(cos(ang), sin(ang)) * r * (1.4 + 0.12 * sin(i * 2.0))
				var s := 3.2 * u * (0.35 + 0.65 * maxf(0.0, sin(t * 2.6 + i * 1.9)))
				_star(p, s, Color(1.0, 0.95, 0.75, a0))
		"glint":
			for i in 3:
				var ang := i * TAU / 3.0 + 0.9
				var p := Vector2(cos(ang), sin(ang)) * r * 1.25
				var s := 3.0 * u * maxf(0.0, sin(t * 2.2 + i * 2.1))
				_star(p, s, Color(c.lightened(0.4), a0))
		"field":
			var pulse := 0.5 + 0.5 * sin(t * 3.0)
			for side in [-1.0, 1.0]:
				for k in 2:
					aura.draw_arc(Vector2(side * r * 0.2, 0), r * (1.35 + k * 0.3 + pulse * 0.1), -0.7 + (0.0 if side > 0 else PI), 0.7 + (0.0 if side > 0 else PI), 12, Color(c, (0.55 - k * 0.2) * a0), 1.3 * u, true)
		"rise":
			for i in 5:
				var ph := fmod(t * 0.35 + i / 5.0, 1.0)
				var p := Vector2(sin(i * 1.7 + t) * r * 0.6, -r * (0.6 + ph * 1.3))
				aura.draw_circle(p, 1.5 * u * (1.0 - ph * 0.5), Color(c, (1.0 - ph) * 0.85 * a0), true, -1.0, true)
		"sink":
			for i in 4:
				var ph := fmod(t * 0.3 + i / 4.0, 1.0)
				var p := Vector2((i - 1.5) * r * 0.45, r * (0.7 + ph * 1.0))
				aura.draw_circle(p, 1.6 * u, Color(c, (1.0 - ph) * 0.8 * a0), true, -1.0, true)
		"rainbow":
			for i in 6:
				var ang := i * TAU / 6.0 + t * 0.9
				aura.draw_circle(Vector2(cos(ang), sin(ang)) * r * 1.4, 1.7 * u, Color.from_hsv(fmod(i / 6.0 + t * 0.2, 1.0), 0.55, 1.0, 0.9 * a0), true, -1.0, true)
		"hollow":
			var ph := fmod(t * 0.5, 1.0)
			aura.draw_arc(Vector2.ZERO, r * (1.9 - ph * 0.85), 0, TAU, 28, Color(c, ph * 0.7 * a0), 1.2, true)
		"echo":
			var off := Vector2(cos(t * 1.6), sin(t * 1.6)) * r * 0.35
			aura.draw_arc(off, r * 1.12, 0, TAU, 28, Color(c, 0.5 * a0), 1.6, true)
		"rays":
			for i in 8:
				var ang := i * TAU / 8.0 + t * 0.4
				var dir := Vector2(cos(ang), sin(ang))
				var l := r * (0.35 + 0.15 * sin(t * 3.0 + i))
				aura.draw_line(dir * r * 1.2, dir * (r * 1.2 + l), Color(1.0, 0.85, 0.35, 0.85 * a0), 1.6 * u, true)


## A small four-pointed sparkle.
func _star(p: Vector2, s: float, col: Color) -> void:
	if s <= 0.2:
		return
	aura.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.28, -s * 0.28), p + Vector2(s, 0), p + Vector2(s * 0.28, s * 0.28),
		p + Vector2(0, s), p + Vector2(-s * 0.28, s * 0.28), p + Vector2(-s, 0), p + Vector2(-s * 0.28, -s * 0.28)]), col)


func refresh_label() -> void:
	if number == 0:
		return
	if vel != Vector2.ZERO:
		if rest_tween != null:
			rest_tween.kill()
			rest_tween = null
		_set_settled(0.0)
	elif shown_settled < 1.0 and rest_tween == null:
		_ease_to_rest()
	if vel == Vector2.ZERO:
		_set_blur(0.0)


func _set_settled(s: float) -> void:
	if s != shown_settled:
		shown_settled = s
		mat.set_shader_parameter("disc_alpha", 1.0 - s)
		label_node.queue_redraw()


func _ease_to_rest() -> void:
	var from := Quaternion(basis)
	var to := Quaternion(nearest_rest())
	var start := shown_settled
	if not is_inside_tree():
		basis = Basis(to)
		_push()
		_set_settled(1.0)
		return
	rest_tween = create_tween()
	rest_tween.tween_method(func(t: float):
		basis = Basis(from.slerp(to, t))
		_push_orientation()
		_set_settled(lerpf(start, 1.0, t)), 0.0, 1.0, REST_EASE_TIME + REST_EASE_PER_RADIAN * from.angle_to(to)).set_trans(Tween.TRANS_SINE)
	rest_tween.tween_callback(func(): rest_tween = null)


func _digit_size() -> int:
	var shown: int = int(Catalog.faces.get(number, 0)) if number > 15 else number
	return int(round(radius * (1.2 if shown < 10 else 0.86)))


## While moving, the number is printed on the sphere and turns with it. At rest it
## sits upright on a centred white disc, so every ball can be read while aiming.
func _draw_number() -> void:
	if number == 0 or fade <= 0.05:
		return
	var settled := shown_settled
	# Dice and Wild balls show the number they currently count as.
	var shown: int = int(Catalog.faces.get(number, 0)) if number > 15 else number
	var use_emblem := emblem != "" and shown == 0
	if settled > 0.0:
		var a2 := fade * settled
		var txt2 := str(shown)
		var fs2 := _digit_size()
		label_node.draw_circle(Vector2.ZERO, radius * (0.62 if number < 10 else 0.68), Color(0.97, 0.96, 0.9, a2))
		if use_emblem:
			IconArt.paint(label_node, emblem, Vector2.ZERO, radius * 0.5 / 34.0, Color(emblem_ink, a2), Color(0.97, 0.96, 0.9, a2), font, maxf(1.0, radius * 0.08))
			if settled >= 1.0:
				return
		var big2 := int(fs2 * DIGIT_SUPERSAMPLE)
		var w2 := font.get_string_size(txt2, HORIZONTAL_ALIGNMENT_LEFT, -1, big2).x
		label_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE / DIGIT_SUPERSAMPLE)
		label_node.draw_string(font, Vector2(-w2 * 0.5, big2 * 0.36), txt2, HORIZONTAL_ALIGNMENT_LEFT, -1, big2, Color(0.05, 0.05, 0.05, a2))
		label_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if settled >= 1.0:
		return
	for s in [1.0, -1.0]:
		var a: Vector3 = basis * Vector3(s, 0, 0)
		if a.z <= 0.2:
			continue
		var c := Vector2(a.x, -a.y) * radius
		var up: Vector3 = basis * Vector3(0, 0, 1)   # same way up on both sides, so a 9 never reads as a 6
		var angle := atan2(up.x, up.y)
		var facing := clampf(a.z, 0.0, 1.0)
		var fs := int(_digit_size() * DIGIT_SUPERSAMPLE)
		var txt := str(shown)
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var col := Color(0.08, 0.08, 0.08, fade * smoothstep(0.2, 0.45, a.z) * (1.0 - settled) * (1.0 - spin_blur))
		# Foreshorten along the direction the disc is tipping away.
		var radial := Vector2(a.x, -a.y)
		var squash := 1.0
		if radial.length() > 0.01:
			var along := absf(cos(radial.angle() - angle))
			squash = lerpf(1.0, facing, along)
		var shrink := Vector2(squash, lerpf(facing, 1.0, absf(cos(radial.angle() - angle)))) if radial.length() > 0.01 else Vector2.ONE
		if use_emblem:
			label_node.draw_set_transform(c, angle, shrink)
			IconArt.paint(label_node, emblem, Vector2.ZERO, radius * 0.42 / 34.0, Color(emblem_ink, col.a), Color(0.97, 0.96, 0.9, col.a), font, maxf(1.0, radius * 0.07))
			continue
		label_node.draw_set_transform(c, angle, shrink / DIGIT_SUPERSAMPLE)
		label_node.draw_string(font, Vector2(-w * 0.5, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	label_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func set_fade(f: float) -> void:
	fade = f
	mat.set_shader_parameter("fade", f)
	queue_redraw()
	label_node.queue_redraw()
