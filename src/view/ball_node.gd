class_name BallNode
extends Node2D
## One rendered ball: soft contact shadow, shader-lit rolling sphere, and the
## number printed on whichever number disc currently faces the camera.

const SHADER := preload("res://src/view/shaders/ball.gdshader")
const PAD := 1.18

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
	mat.set_shader_parameter("orient", basis)
	label_node.queue_redraw()


func _draw() -> void:
	if fade <= 0.01:
		return
	# Contact shadow, offset away from the lamp.
	var off := Vector2(3.0, 4.5)
	for i in 5:
		var r := radius * (1.25 - i * 0.07)
		draw_circle(off, r, Color(0, 0, 0, 0.09 * fade))
	draw_circle(Vector2(0.6, 1.2), radius * 0.92, Color(0, 0, 0, 0.25 * fade))


func _draw_number() -> void:
	if number == 0 or fade <= 0.05:
		return
	for s in [1.0, -1.0]:
		var a: Vector3 = basis * Vector3(s, 0, 0)
		if a.z <= 0.25:
			continue
		var c := Vector2(a.x, -a.y) * radius * 0.98
		var facing := clampf((a.z - 0.25) / 0.75, 0.0, 1.0)
		var fs := int(round(radius * 0.92 * (0.55 + 0.45 * facing)))
		var txt := str(number)
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		var col := Color(0.08, 0.08, 0.08, fade * (0.35 + 0.65 * facing))
		label_node.draw_string(font, c + Vector2(-w * 0.5, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func set_fade(f: float) -> void:
	fade = f
	mat.set_shader_parameter("fade", f)
	queue_redraw()
	label_node.queue_redraw()
