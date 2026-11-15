extends SceneTree
## Card categories keep their visual identity across shop offers and hover detail.

var failures := 0

func check(ok: bool, message: String) -> void:
	print("  ", "ok  " if ok else "FAIL ", message)
	if not ok:
		failures += 1

func has_type(node: Node, script: Script) -> bool:
	if node.get_script() == script:
		return true
	for child in node.get_children():
		if has_type(child, script):
			return true
	return false

func _text_of(node: Node) -> String:
	var t := ""
	if node is Label:
		t += (node as Label).text + "
"
	elif node is RichTextLabel:
		t += (node as RichTextLabel).get_parsed_text() + "
"
	for child in node.get_children():
		t += _text_of(child)
	return t

func _initialize() -> void:
	call_deferred("_go")

func _go() -> void:
	var z_seen := {}
	for id in Catalog.PERKS:
		z_seen[int(Catalog.PERKS[id].z)] = true
	check(z_seen.size() == 100, "Elements cover atomic numbers 1 through 100")
	var ordered := true
	for z in range(2, 101):
		ordered = ordered and Catalog.element_color(z).h > Catalog.element_color(z - 1).h
	check(ordered and Catalog.element_color(1).h < 0.01 and Catalog.element_color(100).h > 0.7, "Element hues rise smoothly from red to violet")
	var element_tile := TileArt.new().setup("perk", "ricochet")
	check(element_tile.tint == Catalog.rarity_color(int(Catalog.PERKS.ricochet.r)), "Element card body uses rarity color")
	element_tile.free()
	check(TileArt.BET_COLORS.all(func(c): return c == Catalog.SIDE_BET_COLOR), "every side-bet tier uses brown")
	var g: Node = load("res://main.tscn").instantiate()
	root.add_child(g)
	for i in 3:
		await process_frame
	g._new_run()
	g.run.shop.clear()
	g.run.shop.append({"type": "imbue", "id": "ember", "cost": 5, "sold": false})
	g.run.shop.append({"type": "ball", "id": "gold", "cost": 6, "sold": false})
	var isotope: Control = g._offer_card(0)
	var exotic: Control = g._offer_card(1)
	g.overlay.add_child(isotope)
	g.overlay.add_child(exotic)
	check(not has_type(isotope, TileArt) and has_type(isotope, ThumbArt), "Isotope offers show a glowing ball instead of a tile card")
	check(not has_type(exotic, TileArt) and has_type(exotic, ThumbArt), "Exotic offers show the ball instead of a tile card")
	isotope.mouse_entered.emit()
	check(g.card_tip != null and not has_type(g.card_tip, TileArt), "Isotope hover opens ball detail without a tile card")
	exotic.mouse_entered.emit()
	check(g.card_tip != null and not has_type(g.card_tip, TileArt), "Exotic hover opens ball detail without a tile card")
	g.run.shop.append({"type": "imbue", "id": "ember", "ball": 13, "adds": true, "cost": 6, "sold": false})
	var numbered: Control = g._offer_card(2)
	g.overlay.add_child(numbered)
	check(_text_of(exotic).contains("Worth 45"), "an Exotic ball's card says what it is worth")
	check(_text_of(numbered).contains("Worth %d" % Catalog.ball_points(13)), "a 13-ball with an Isotope says what it is worth")
	numbered.mouse_entered.emit()
	check(_text_of(g.card_tip).contains("worth %d" % Catalog.ball_points(13)), "and so does its pop-up")
	# Every Catalyst in the Hustler's Kit pops up what it does when a pointer or
	# thumb rests on it (tooltips never show on a phone).
	var missing: Array = []
	for id in Catalog.ITEMS:
		var kit: Control = g._item_button(id, true)
		g.item_bar.add_child(kit)
		g._hide_card_tip()
		kit.mouse_entered.emit()
		var said := _text_of(g.card_tip) if g.card_tip != null else ""
		if not (said.contains(String(Catalog.ITEMS[id].desc)) and said.contains(String(Catalog.WHEN_NAMES[Catalog.ITEMS[id].when]))):
			missing.append(id)
		kit.queue_free()
	check(missing.is_empty(), "every Catalyst in the kit shows what it does and when (%s)" % ", ".join(missing))
	var first_id: String = Catalog.ITEMS.keys()[0]
	g.run.tool_charges[first_id] = 1
	var held: Button = g._item_button(first_id, true)
	g.item_bar.add_child(held)
	g._hide_card_tip()
	held.set_meta("down_at", Time.get_ticks_msec() - 1000)
	held.pressed.emit()
	check(g.card_tip != null and int(g.run.tool_charges.get(first_id, 0)) == 1 and g.armed.is_empty(), "a long press on a Catalyst reads its card without using it")
	print("card palette tests: %d failures" % failures)
	quit(1 if failures else 0)
