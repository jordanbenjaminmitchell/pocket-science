extends SceneTree
## Renders the logo mark to assets/icon.png (run WITHOUT --headless).
func _initialize() -> void:
	call_deferred("_go")

func _go() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(256, 256)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var logo := LogoArt.new()
	logo.animate = false
	logo.size = Vector2(256, 256)
	logo.t = 0.9
	vp.add_child(logo)
	for i in 5:
		await process_frame
	print(vp.get_texture().get_image().save_png("res://assets/icon.png"))
	quit()
