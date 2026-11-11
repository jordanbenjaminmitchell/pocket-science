class_name TermTip
extends CanvasLayer
## The small popup that defines a game term. Hover opens it on a PC; on a phone a
## tap opens it, and the next tap anywhere or a few seconds' wait closes it.

const WIDTH := 330.0
const SHOW_TIME := 6.0

var panel: PanelContainer
var heading: Label
var body: Label
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
	body = Label.new()
	body.add_theme_font_override("font", body_font)
	body.add_theme_font_size_override("font_size", 16)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(WIDTH, 0)
	v.add_child(body)


func show_term(term: String, at: Vector2) -> void:
	show_text(Glossary.title(term), Glossary.sentence(term), at)


## Any heading and text, for things that are not glossary terms (a special ball).
func show_text(title: String, text: String, at: Vector2) -> void:
	heading.text = title
	body.text = text
	panel.visible = true
	panel.reset_size()
	var screen := panel.get_viewport_rect().size
	var s := panel.get_combined_minimum_size()
	var p := at + Vector2(14, -s.y - 14)
	if p.y < 8.0:
		p.y = at.y + 24.0
	panel.position = Vector2(clampf(p.x, 8.0, screen.x - s.x - 8.0), clampf(p.y, 8.0, screen.y - s.y - 8.0))
	time_left = SHOW_TIME


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
