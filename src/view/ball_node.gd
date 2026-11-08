class_name BallNode
extends Node2D
## One rendered ball: soft contact shadow, shader-lit rolling sphere, and the
## number printed on whichever number disc currently faces the camera.

const SHADER := preload("res://src/view/shaders/ball.gdshader")
const PAD := 1.18
## Number disc (+X) toward the viewer; stripe axis (+Z) straight up, so the band is level.
const REST_BASIS := Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0))

var number := 0
var radius := TableLayout.R
var basis := Basis()
var quad: ColorRect
var mat: ShaderMaterial
var label_node: Node2D
var font: Font
var glow := Color(0, 0, 0, 0)
var sinking := false
var fade := 1.0
var vel := Vector2.ZERO
var shown_settled := 1.0


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
	mat.set_shader_parameter("is_cue", 1.0 if n == 0 else 0.0)
	mat.set_shader_parameter("radius_uv", 1.0 / PAD)
	mat.set_shader_parameter("disc_alpha", 0.0)   # starts at rest, with the upright number
	quad.material = mat
	add_child(quad)
	label_node = Node2D.new()
	label_node.draw.connect(_draw_number)
	add_child(label_node)
	# Random starting orientation, but keep the number roughly visible at rest.
	basis = Basis(Vector3(0, 0, 1), rng.randf() * TAU) * Basis(Vector3(0, 1, 0), -PI * 0.5 + rng.randf_range(-0.5, 0.5))
	_push()


func set_glow(c: Color) -> void:
	glow = c
	mat.set_shader_parameter("glow_color", c)


## Move to a new table position, rolling the sphere by the distance travelled.
func roll_to(p: Vector2) -> void:
	var d := p - position
	position = p
	var dist := d.length()
	if dist > 0.0001:
		# View space: X right, Y up (screen y flipped), Z toward the camera.
		var v := Vector3(d.x, -d.y, 0.0)
		var axis := Vector3(-v.y, v.x, 0.0).normalized()
		basis = Basis(axis, dist / radius) * basis
		basis = basis.orthonormalized()
		_push()


func _push() -> void:
	_push_orientation()
	label_node.queue_redraw()


## A resting ball turns to show its number and any stripe squarely to the player.
func _push_orientation() -> void:
	mat.set_shader_parameter("orient", basis.slerp(REST_BASIS, shown_settled) if shown_settled > 0.0 else basis)


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


## 1 when the ball is at rest and easy to read, 0 when it is really moving.
func _settled_amount() -> float:
	return 1.0 - smoothstep(40.0, 180.0, vel.length())


## Call when the speed changes: swaps between the rolling and resting number.
func refresh_label() -> void:
	var s := _settled_amount()
	if s != shown_settled:
		shown_settled = s
		mat.set_shader_parameter("disc_alpha", 1.0 - s)
		_push_orientation()
		label_node.queue_redraw()


## While rolling, the number is printed on the sphere and turns with it. As the
## ball comes to rest it fades to an upright number on a centred white disc, so
## every ball can be read while aiming.
func _draw_number() -> void:
	if number == 0 or fade <= 0.05:
		return
	var settled := shown_settled
	if settled > 0.0:
		var a2 := fade * settled
		var txt2 := str(number)
		var fs2 := int(round(radius * (1.2 if number < 10 else 0.86)))
		label_node.draw_circle(Vector2.ZERO, radius * (0.62 if number < 10 else 0.68), Color(0.97, 0.96, 0.9, a2))
		var w2 := font.get_string_size(txt2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
		label_node.draw_string(font, Vector2(-w2 * 0.5, fs2 * 0.36), txt2, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color(0.05, 0.05, 0.05, a2))
	if settled >= 1.0:
		return
	for s in [1.0, -1.0]:
		var a: Vector3 = basis * Vector3(s, 0, 0)
		if a.z <= 0.2:
			continue
		var c := Vector2(a.x, -a.y) * radius
		var up: Vector3 = basis * Vector3(0, 0, s)
		var angle := atan2(up.x, up.y)
		var facing := clampf(a.z, 0.0, 1.0)
		var fs := int(round(radius * 1.05))
		var txt := str(number)
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var col := Color(0.08, 0.08, 0.08, fade * smoothstep(0.2, 0.45, a.z) * (1.0 - settled))
		# Foreshorten along the direction the disc is tipping away.
		var radial := Vector2(a.x, -a.y)
		var squash := 1.0
		if radial.length() > 0.01:
			var along := absf(cos(radial.angle() - angle))
			squash = lerpf(1.0, facing, along)
		label_node.draw_set_transform(c, angle, Vector2(squash, lerpf(facing, 1.0, absf(cos(radial.angle() - angle)))) if radial.length() > 0.01 else Vector2.ONE)
		label_node.draw_string(font, Vector2(-w * 0.5, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	label_node.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func set_fade(f: float) -> void:
	fade = f
	mat.set_shader_parameter("fade", f)
	queue_redraw()
	label_node.queue_redraw()
