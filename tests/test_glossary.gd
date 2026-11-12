extends SceneTree
## Every game term has a one-sentence definition and opens from real game text.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func _initialize() -> void:
	call_deferred("_go")


func _go() -> void:
	for t in Glossary.TERMS:
		var s := Glossary.sentence(t)
		check(s.ends_with(".") and s.count(". ") == 0 and s.length() <= 110, "%s is one short sentence" % t)
	for w in Glossary.WORDS:
		check(Glossary.TERMS.has(Glossary.WORDS[w]), "%s opens a real term" % w)
	for needed in ["bank", "pay", "sink", "chain"]:
		check(Glossary.TERMS.has(needed), "%s is defined" % needed)
	var linked := Glossary.link("Bank sinks pay ×2 and bank sinks add Chain.")
	check(linked.count("[url=bank]") == 1, "a term links only once per text")
	check(linked.contains("[url=sink]") and linked.contains("[url=pay]") and linked.contains("[url=chain]"), "several terms link in one sentence")
	check(linked.contains("]Bank[/color]"), "the original wording and capitals are kept")
	check(Glossary.link("Spotted the deposit") == "Spotted the deposit", "words are only matched whole")
	for id in Catalog.PERKS:
		var plain := Catalog.PERKS[id].desc as String
		var bb := Glossary.link(plain)
		var check_label := RichTextLabel.new()
		check_label.bbcode_enabled = true
		check_label.text = bb
		check(check_label.get_parsed_text() == plain, "%s reads the same with links" % id) if check_label.get_parsed_text() != plain else null
		check_label.free()

	var g: Node = load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	g._new_run()
	g.run.perks.assign(["bank"])
	g._rebuild_cards()
	await process_frame
	var txt := _find_rich(g.perk_row)
	check(txt != null and txt.text.contains("[url=bank]"), "Element cards carry term links")
	txt.meta_clicked.emit("bank")
	check(g.term_tip.panel.visible and g.term_tip.heading.text == "Bank", "tapping a term opens its popup")
	check(g.term_tip.body.text == Glossary.sentence("bank"), "and shows its definition")
	var tap := InputEventMouseButton.new()
	tap.pressed = true
	tap.button_index = MOUSE_BUTTON_LEFT
	g.term_tip._input(tap)
	check(not g.term_tip.panel.visible, "the next tap closes it")
	g.term_tip.show_term("chain", Vector2(5000, -50))
	await process_frame
	var r: Rect2 = g.term_tip.panel.get_rect()
	var view: Vector2 = g.term_tip.panel.get_viewport_rect().size
	check(r.position.x >= 0.0 and r.end.x <= view.x and r.position.y >= 0.0 and r.end.y <= view.y, "the popup stays on screen")
	g.term_tip.time_left = 0.01
	await process_frame
	await process_frame
	check(not g.term_tip.panel.visible, "and closes by itself")
	print("glossary tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)


func _find_rich(n: Node) -> RichTextLabel:
	for c in n.get_children():
		if c is RichTextLabel:
			return c
		var deep := _find_rich(c)
		if deep != null:
			return deep
	return null
