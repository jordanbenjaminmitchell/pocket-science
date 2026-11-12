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
	var locked := m.locked_perks()
	check(locked.size() >= 30 and Catalog.PERKS.size() - locked.size() >= 25, "fresh profile: starter Elements available, the rest locked (%d locked)" % locked.size())
	check(m.cue_unlocked("maple") and not m.cue_unlocked("posts") and not m.cue_unlocked("gilded"), "fresh profile: only Classic Maple")
	for id in locked:
		check(Catalog.PERKS.has(id), "locked id %s exists" % id) if not Catalog.PERKS.has(id) else null
	# Shop never offers locked perks.
	var run := RunState.new()
	run.start(11)
	run.locked = locked
	var leaked := 0
	for i in 200:
		run.roll_shop()
		for it in run.shop:
			if it.type == "perk" and locked.has(it.id):
				leaked += 1
	check(leaked == 0, "shop never offers locked Elements (200 rolls)")
	# Milestones.
	run.begin_table()
	var bank_shot := {"scored": true, "potted": [3], "total": 40, "lines": [], "banks": 1}
	var got := m.on_shot(bank_shot, run)
	check(got == ["bank"] and not m.locked_perks().has("precision"), "a bank pot unlocks Angles")
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
	check(locked_buttons == Catalog.CUES.size() - 1, "cue select shows every other cue locked (%d)" % locked_buttons)
	g._new_run()
	check(g.run.locked.size() == 41, "a new run uses the profile's locks (%d)" % g.run.locked.size())
	# Restore whatever profile existed.
	var fw := FileAccess.open(Meta.PATH, FileAccess.WRITE)
	fw.store_string(keep)
	fw.close()
	RunState.clear_save()
	print("developer mode")
	var dm := Meta.new()
	check(not dm.locked_perks().is_empty() and not dm.cue_unlocked("black") and dm.handicap_cap() == 0 and dm.is_intro(), "a new profile starts with things locked")
	dm.dev_mode = true
	check(dm.locked_perks().is_empty() and dm.cue_unlocked("black") and dm.handicap_cap() == Catalog.HANDICAPS.size() - 1 and not dm.is_intro(), "Developer mode opens every Element, cue and difficulty and skips the introduction")
	dm.dev_mode = false
	check(not dm.locked_perks().is_empty(), "and turning it off locks them again (nothing was earned)")
	print("logo")
	var logo := LogoArt.new()
	root.add_child(logo)
	logo.t = 0.0
	var all_still := true
	for k in 6:
		all_still = all_still and logo.phase_of(k) == 0.0
	check(all_still, "the electrons start where the icon shows them")
	logo.t = 10.0
	var phases := {}
	for k in 6:
		phases[snappedf(logo.phase_of(k), 0.001)] = true
	check(phases.size() == 6, "they set off one after another, so no two are in step")
	var p0 := logo.phase_of(0)
	logo.t = 11.0
	check(is_equal_approx(logo.phase_of(0) - p0, LogoArt.SPEED), "and all move at the same speed")
	logo.queue_free()
	print("meta tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)


func _find_text(n: Node, t: String) -> int:
	var k := 0
	if n is Button and (n as Button).text == t:
		k += 1
	for ch in n.get_children():
		k += _find_text(ch, t)
	return k
