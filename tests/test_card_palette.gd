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
	print("card palette tests: %d failures" % failures)
	quit(1 if failures else 0)
