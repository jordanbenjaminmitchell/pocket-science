extends SceneTree
## Card art tiles: every Pro Shop card and side bet has one, symbols follow the
## rules in docs/card-art/NEEDED.md and are never repeated, every lettering
## effect is its own and is drawn, and the headline effect fits its corner.

var failures := 0
const BUILT_IN := ["door", "mirror", "gold", "echo", "drop"]


func check(c: bool, m: String) -> void:
	if not c:
		print("  FAIL ", m)
		failures += 1


func _initialize() -> void:
	call_deferred("_go")


func _is_upper(c: String) -> bool:
	return c != c.to_lower() and c == c.to_upper()


func _go() -> void:
	print("tiles")
	var every := {"perk": Catalog.PERKS, "imbue": Catalog.IMBUES, "ball": Catalog.BALL_TYPES, "item": Catalog.ITEMS, "bet": Catalog.BOUNTIES}
	for kind in every:
		for id in every[kind]:
			check(TileArt.has_tile(kind, id), "%s:%s has a tile" % [kind, id])
	check(TileArt.has_tile("bet", "back"), "face-down side bets have a card back")
	var syms := {}
	var letters := {}
	for key: String in TileArt.TILES:
		var t: Dictionary = TileArt.TILES[key]
		var kind := key.get_slice(":", 0)
		var id := key.get_slice(":", 1)
		check(every.has(kind) and ((every[kind] as Dictionary).has(id) or key == "bet:back"), "%s is a real card" % key)
		var sym: String = t.sym
		if kind == "bet":
			check(sym == "", "%s shows a picture, not letters" % key)
		else:
			# A capital, then nothing, a lower-case letter, a second capital or a digit (S2, B8).
			var shaped := sym.length() >= 1 and sym.length() <= 2 and _is_upper(sym[0])
			check(shaped, "%s symbol %s is one or two letters, starting with a capital" % [key, sym])
			check(not syms.has(sym), "%s symbol %s is not also %s's" % [key, sym, syms.get(sym, "")])
			syms[sym] = key
		var r: String = t.get("letter", "")
		check(r != "" and not letters.has(r), "%s has its own lettering effect (%s)" % [key, r])
		letters[r] = key
		var l := TileArt.Lettering.new(sym, r, Color.WHITE, 46, 74.0, TileArt.PAPER)
		check(BUILT_IN.has(r) or l.has_method("_r_" + r), "%s effect %s is drawn" % [key, r])
		l.free()
		var stat: String = t.stat
		check(stat.length() <= 17, "%s stat \"%s\" is short" % [key, stat])
		for b in ([0, 7, 12] if kind == "imbue" else [0]):
			var tile := TileArt.new().setup(kind, id, b)
			var on := tile._acts_on()
			var on_w := TileArt.F_REG.get_string_size(on.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			var fs := TileArt.stat_size(stat, on_w)
			var stat_w := TileArt.F_SEMI.get_string_size(stat, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			check(stat_w + on_w <= TileArt.SIZE.x - 26, "%s stat \"%s\" fits beside %s" % [key, stat, on])
			check(on != "", "%s says what it acts on" % key)
			var name_w := TileArt.F_SEMI.get_string_size(tile._name(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			check(name_w <= TileArt.SIZE.x - 12, "%s name \"%s\" fits the tile" % [key, tile._name()])
			tile.free()
	var probe := TileArt.new().setup("imbue", "spark", 0)
	check(probe._name() == "Spark Isotope" and probe._acts_on() == "Any ball", "an Isotope before its ball is chosen says so")
	probe.free()
	# Side bets as playing cards: real numbers in the wording, and everything fits.
	check(BetCard.bet_text("quarter", 215) == "Score 54 points in one shot", "a quarter of 215 is worked out as 54 points")
	check(BetCard.bet_text("half", 215) == "Score 108 points in one shot", "half of 215 is worked out as 108 points")
	check(BetCard.bet_text("bank", 215) == Catalog.BOUNTIES.bank.name, "other bets keep their full wording")
	for target in [50, 215, 1060, 1585]:
		for b in ["quarter", "half"]:
			var need := int(BetCard.bet_text(b, target).get_slice(" ", 1))
			var share := 0.25 if b == "quarter" else 0.5
			check(need >= target * share and need - 1 < target * share, "%s at target %d asks for exactly enough (%d)" % [b, target, need])
	for b in Catalog.BOUNTIES:
		for target in [50, 1585]:
			var txt := BetCard.bet_text(b, target)
			var note := BetCard.bet_note(b, target)
			var tw := BetCard.SIZE.x - 28.0
			var room := 52.0 if note == "" else 36.0
			check(TileArt.F_SEMI.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, tw, 11).y <= room, "bet %s wording fits its card" % b)
			check(note == "" or TileArt.F_REG.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x <= tw, "bet %s note fits on one line" % b)
		for st in ["back", "open", "taken", "won", "passed"]:
			var card := BetCard.new().setup(b, st, {"stake": 20, "reward": 100, "max_reward": 100, "target": 1060})
			check(card.face_up == (st != "back"), "bet %s %s shows the right side" % [b, st])
			card.free()
	var bc := BetCard.new().setup("bank", "open", {"stake": 8, "reward": 28})
	check(bc._multiple() == "2.5×", "a bet card shows the real multiple (2.5×)")
	bc.free()
	# The balls a Perk singles out match the scoring rules.
	check(TileArt.balls_for("perk", "prime") == Catalog.PRIMES, "Prime Cut's balls are the primes")
	check(TileArt.balls_for("perk", "fibonacci") == [1, 2, 3, 5, 8, 13], "Lucky Numbers' balls are the Fibonacci numbers")
	check(TileArt.balls_for("perk", "side").is_empty(), "an Element for any ball singles none out")
	for id in TileArt.FLOAT_NUMBERS:
		var nums := TileArt.balls_for("perk", id)
		check(nums.size() >= 1 and nums.size() <= 8, "%s floats 1-8 numbers on its tile" % id)
		for n in nums:
			check(str(n) in str(Catalog.PERKS[id].desc) or id in ["odd", "even"], "%s: ball %d is named in its card text" % [id, n])
	print("  %d tiles, %d symbols" % [TileArt.TILES.size(), syms.size()])
	print("tile tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
