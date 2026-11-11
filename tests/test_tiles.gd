extends SceneTree
## Pro Shop tile art: every perk has a tile, symbols and lettering effects are
## never repeated, and the headline effect fits beside what it acts on.

var failures := 0
const BUILT_IN := ["door", "mirror", "gold", "echo", "drop"]


func check(c: bool, m: String) -> void:
	if not c:
		print("  FAIL ", m)
		failures += 1


func _initialize() -> void:
	call_deferred("_go")


func _go() -> void:
	print("tiles")
	for id in Catalog.PERKS:
		check(TileArt.has_tile("perk", id), "perk %s has a tile" % id)
	var syms := {}
	var letters := {}
	for key: String in TileArt.TILES:
		var t: Dictionary = TileArt.TILES[key]
		var kind := key.get_slice(":", 0)
		var id := key.get_slice(":", 1)
		var known := {"perk": Catalog.PERKS, "imbue": Catalog.IMBUES, "ball": Catalog.BALL_TYPES, "item": Catalog.ITEMS}
		check(known.has(kind) and (known[kind] as Dictionary).has(id), "%s is a real card" % key)
		var sym: String = t.sym
		check(sym.length() >= 1 and sym.length() <= 2 and sym[0] == sym[0].to_upper() and (sym.length() == 1 or sym[1] == sym[1].to_lower()), "%s symbol %s is shaped like an element's" % [key, sym])
		check(not syms.has(sym), "%s symbol %s is not also %s's" % [key, sym, syms.get(sym, "")])
		syms[sym] = key
		var r: String = t.get("letter", "")
		check(r != "" and not letters.has(r), "%s has its own lettering effect (%s)" % [key, r])
		letters[r] = key
		var l := TileArt.Lettering.new(sym, r, Color.WHITE, 46, 74.0, TileArt.PAPER)
		check(BUILT_IN.has(r) or l.has_method("_r_" + r), "%s effect %s is drawn" % [key, r])
		l.free()
		var tile := TileArt.new().setup(kind, id, 7)
		var on_w := TileArt.F_REG.get_string_size(tile._acts_on().to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		var fs := TileArt.stat_size(t.stat, on_w)
		var stat_w := TileArt.F_SEMI.get_string_size(t.stat, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		check(stat_w + on_w <= TileArt.SIZE.x - 26, "%s stat \"%s\" fits beside %s" % [key, t.stat, tile._acts_on()])
		tile.free()
	print("  %d tiles, %d symbols" % [TileArt.TILES.size(), syms.size()])
	print("tile tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
