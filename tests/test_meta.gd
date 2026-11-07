extends SceneTree
## Unlock progression: fresh pool, milestone triggers, shop respects locks, persistence.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func _initialize() -> void:
	call_deferred("_go")


func _go() -> void:
	create_timer(60.0).timeout.connect(func(): quit(2))
	var keep := FileAccess.get_file_as_string(Meta.PATH)
	var c := ConfigFile.new()
	c.load(Meta.PATH)
	if c.has_section("meta"):
		c.erase_section("meta")
	c.save(Meta.PATH)
	var m := Meta.new()
	m.load_file()
	var locked := m.locked_formulas()
	check(locked.size() == 32 and Catalog.FORMULAS.size() - locked.size() == 28, "fresh profile: 28 formulas available, 32 locked")
	check(m.cue_unlocked("maple") and not m.cue_unlocked("optic") and not m.cue_unlocked("gilded"), "fresh profile: only Classic Maple")
	for id in locked:
		check(Catalog.FORMULAS.has(id), "locked id %s exists" % id) if not Catalog.FORMULAS.has(id) else null
	# Shop never offers locked formulas.
	var run := RunState.new()
	run.start(11)
	run.locked = locked
	var leaked := 0
	for i in 200:
		run.roll_shop()
		for it in run.shop:
			if it.type == "formula" and locked.has(it.id):
				leaked += 1
	check(leaked == 0, "shop never offers locked formulas (200 rolls)")
	# Milestones.
	run.begin_table()
	var bank_shot := {"scored": true, "potted": [3], "total": 40, "lines": [{"label": "Bank ×1"}]}
	var got := m.on_shot(bank_shot, run)
	check(got == ["bank"] and not m.locked_formulas().has("precision"), "a bank pot unlocks Angles")
	check(m.on_shot(bank_shot, run).is_empty(), "milestones are earned once")
	var big := {"scored": true, "potted": [1, 2, 3], "total": 1200, "lines": []}
	got = m.on_shot(big, run)
	check(got.has("triple") and got.has("big"), "3-ball 1200-point shot unlocks Hat Trick and Big Number")
	run.plan[0].anomaly = "fog"
	run.plan[0].lab = "cryo"
	got = m.on_table_cleared(run)
	check(got.has("first_clear") and got.has("boss") and got.has("lab"), "clearing a cryo boss table unlocks three milestones")
	check(m.cue_unlocked("optic") and m.cue_unlocked("hotrod") and not m.cue_unlocked("gilded"), "cues unlock from milestones")
	check(m.on_win() == ["win"], "winning unlocks Pocket Scientist")
	# Persistence.
	var m2 := Meta.new()
	m2.load_file()
	check(m2.earned.size() == m.earned.size() and m2.lifetime_pots == m.lifetime_pots, "progress persists")
	check(Meta.reward_text("boss").contains("Hot Rod") and Meta.reward_text("boss").contains("Ricochet"), "reward text names the unlocks")
	# Game wiring: a fresh profile shows Optic locked in cue select.
	c.load(Meta.PATH)
	c.erase_section("meta")
	c.save(Meta.PATH)
	var g: Node = load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g._show_cue_select()
	await process_frame
	var locked_buttons := _find_text(g.overlay, "Locked")
	check(locked_buttons == 4, "cue select shows 4 locked cues (%d)" % locked_buttons)
	g._new_run()
	check(g.run.locked.size() == 32, "a new run uses the profile's locks")
	# Restore whatever profile existed.
	var fw := FileAccess.open(Meta.PATH, FileAccess.WRITE)
	fw.store_string(keep)
	fw.close()
	RunState.clear_save()
	print("meta tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)


func _find_text(n: Node, t: String) -> int:
	var k := 0
	if n is Button and (n as Button).text == t:
		k += 1
	for ch in n.get_children():
		k += _find_text(ch, t)
	return k
