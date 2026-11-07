extends SceneTree
## Settings screen: controls change the live game and persist across launches.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func _initialize() -> void:
	call_deferred("_go")


func _find(n: Node, name: String) -> Node:
	if n.name == name:
		return n
	for c in n.get_children():
		var r := _find(c, name)
		if r:
			return r
	return null


func _go() -> void:
	create_timer(60.0).timeout.connect(func(): quit(2))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	# Old-format file (on/off audio) must migrate.
	var old := ConfigFile.new()
	old.set_value("audio", "sfx", 0.0)
	old.set_value("audio", "music", 0.3)
	old.set_value("best", "tables", 4)
	old.save(GameSettings.PATH)
	var g: Node = load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	check(g.settings.sfx == 0.0 and is_equal_approx(g.settings.music, 0.3), "old audio toggles migrate")
	g.settings.reset()
	g._apply_settings()
	g._show_settings(g._show_title)
	await process_frame
	var master: HSlider = _find(g.overlay, "slider_master")
	var pull: HSlider = _find(g.overlay, "slider_pull")
	var rm: CheckButton = _find(g.overlay, "toggle_reduced_motion")
	check(master != null and pull != null and rm != null, "settings controls exist")
	master.value = 0.5
	check(is_equal_approx(g.sfx.volume, 0.5 * 0.8), "master volume scales SFX (%.2f)" % g.sfx.volume)
	rm.button_pressed = true
	check(g.view.reduced_motion, "reduced motion applies to the table")
	g.view.shake = 0.0
	g.view.add_shake(5.0)
	check(g.view.shake == 0.0, "reduced motion suppresses shake")
	pull.value = 1.5
	g._save_settings()
	var fresh := GameSettings.new()
	fresh.load_file()
	check(is_equal_approx(fresh.master, 0.5) and fresh.reduced_motion and is_equal_approx(fresh.pull, 1.5), "settings persist")
	var c := ConfigFile.new()
	c.load(GameSettings.PATH)
	check(int(c.get_value("best", "tables", 0)) == 4, "personal bests untouched by settings save")
	# Longer pull-back means less power for the same drag.
	g._new_run()
	await process_frame
	check(g.DRAG_FULL * g.settings.pull > g.DRAG_FULL, "pull setting lengthens full-power drag")
	g.settings.reset()
	g._save_settings()
	print("settings tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
