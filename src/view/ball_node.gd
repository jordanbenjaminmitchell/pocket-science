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
## Above this much turn per frame the eye reads a spinning ball as turning backwards.
const MAX_TURN_PER_FRAME := 0.85
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
var emblem := ""          # special balls show this motif instead of a number
var emblem_ink := Color.BLACK


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
	basis = REST_FLIPPED if rng.randi() % 2 == 0 else REST_BASIS
	_push()


func set_glow(c: Color) -> void:
	glow = c
	mat.set_shader_parameter("glow_color", c)


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
		basis = Basis(axis, minf(turn, MAX_TURN_PER_FRAME)) * basis
		if stop_in >= 0.0 and number != 0:
			_steer_to_rest(axis, stop_in / radius, d.length() / radius)
	if twist != 0.0:
		basis = Basis(Vector3(0, 0, 1), twist) * basis
	basis = basis.orthonormalized()
	_push()


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
	# Contact shadow, offset away from the lamp.
	var off := Vector2(3.0, 4.5)
	for i in 5:
		var r := radius * (1.25 - i * 0.07)
		draw_circle(off, r, Color(0, 0, 0, 0.09 * fade))
	draw_circle(Vector2(0.6, 1.2), radius * 0.92, Color(0, 0, 0, 0.25 * fade))


## Call when the speed changes. A moving ball shows only what is printed on it.
## Once stopped it finishes any small correction and shows its upright number.
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
		var col := Color(0.08, 0.08, 0.08, fade * smoothstep(0.2, 0.45, a.z) * (1.0 - settled))
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
