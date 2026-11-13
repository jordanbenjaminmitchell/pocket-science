class_name TermTip
extends CanvasLayer
## The small popup that defines a game term. Hover opens it on a PC; on a phone a
## tap opens it, and the next tap anywhere or a few seconds' wait closes it.

const WIDTH := 330.0
const SHOW_TIME := 6.0

var panel: PanelContainer
var heading: Label
var body: Label
var bonus: Label
var top: Label              # a ball's points, big, above everything else
var boxes: VBoxContainer    # one coloured box per Isotope or bonus on a ball
var box_font: Font
var box_head: Font
const NEON := Color(0.3, 1.0, 0.72)
var time_left := 0.0


func setup(style: StyleBox, head_font: Font, body_font: Font) -> void:
	layer = 90
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.visible = false
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)
	heading = Label.new()
	heading.add_theme_font_override("font", head_font)
	heading.add_theme_font_size_override("font_size", 17)
	heading.add_theme_color_override("font_color", Color(0.56, 0.85, 1.0))
	v.add_child(heading)
	top = Label.new()
	top.add_theme_font_override("font", head_font)
	top.add_theme_font_size_override("font_size", 26)
	top.add_theme_color_override("font_color", NEON)
	top.visible = false
	v.add_child(top)
	box_font = body_font
	box_head = head_font
	body = Label.new()
	body.add_theme_font_override("font", body_font)
	body.add_theme_font_size_override("font_size", 16)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(WIDTH, 0)
	v.add_child(body)
	bonus = Label.new()
	bonus.add_theme_font_override("font", head_font)
	bonus.add_theme_font_size_override("font_size", 16)
	bonus.add_theme_color_override("font_color", NEON)
	bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bonus.custom_minimum_size = Vector2(WIDTH, 0)
	bonus.visible = false
	v.add_child(bonus)
	boxes = VBoxContainer.new()
	boxes.add_theme_constant_override("separation", 5)
	boxes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boxes.visible = false
	v.add_child(boxes)


func show_term(term: String, at: Vector2) -> void:
	show_text(Glossary.title(term), Glossary.sentence(term), at)


## Any heading and text, for things that are not glossary terms (an Exotic ball).
func show_text(title: String, text: String, at: Vector2, seconds: float = SHOW_TIME, extra: String = "") -> void:
	heading.text = title
	body.text = text
	body.visible = text != ""
	bonus.text = extra
	bonus.visible = extra != ""
	top.visible = false
	boxes.visible = false
	_place(at, seconds)


## A ball: its points big on top, a plain line or two, then one box per Isotope
## or bonus in that Isotope's colour, saying what it adds.
## `adds` is [{color: Color, title: String, text: String}].
func show_ball(title: String, points: String, points_color: Color, text: String, adds: Array, at: Vector2, seconds: float = SHOW_TIME) -> void:
	heading.text = title
	top.text = points
	top.visible = points != ""
	top.add_theme_color_override("font_color", points_color)
	body.text = text
	body.visible = text != ""
	bonus.visible = false
	for c in boxes.get_children():
		boxes.remove_child(c)
		c.queue_free()
	for a: Dictionary in adds:
		var col: Color = a.color
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(col.darkened(0.72), 0.95)
		sb.border_color = col
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 9
		sb.content_margin_right = 9
		sb.content_margin_top = 5
		sb.content_margin_bottom = 6
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", sb)
		pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", 0)
		pc.add_child(bv)
		var h := Label.new()
		h.text = String(a.title)
		h.add_theme_font_override("font", box_head)
		h.add_theme_font_size_override("font_size", 15)
		h.add_theme_color_override("font_color", col.lightened(0.35))
		bv.add_child(h)
		var t := Label.new()
		t.text = String(a.text)
		t.add_theme_font_override("font", box_font)
		t.add_theme_font_size_override("font_size", 14)
		t.add_theme_color_override("font_color", Color(0.93, 0.94, 0.95))
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(WIDTH - 22.0, 0)
		bv.add_child(t)
		boxes.add_child(pc)
	boxes.visible = not adds.is_empty()
	_place(at, seconds)


func _place(at: Vector2, seconds: float) -> void:
	panel.visible = true
	panel.reset_size()
	var screen := panel.get_viewport_rect().size
	var s := panel.get_combined_minimum_size()
	var p := at + Vector2(14, -s.y - 14)
	if p.y < 8.0:
		p.y = at.y + 24.0
	panel.position = Vector2(clampf(p.x, 8.0, screen.x - s.x - 8.0), clampf(p.y, 8.0, screen.y - s.y - 8.0))
	time_left = seconds


func hide_tip() -> void:
	panel.visible = false


func _process(delta: float) -> void:
	if panel.visible:
		time_left -= delta
		if time_left <= 0.0:
			hide_tip()


func _input(event: InputEvent) -> void:
	if panel.visible and ((event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed):
		hide_tip()
