extends SceneTree
## Seeds, dailies, run history and the Collection.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func _initialize() -> void:
	call_deferred("_go")


func _go() -> void:
	create_timer(120.0).timeout.connect(func(): quit(2))
	var g: Node = load("res://main.tscn").instantiate()
	root.add_child(g)
	await process_frame
	print("seeds")
	var seeds := [g._parse_seed(""), g._parse_seed(" 1234 "), g._parse_seed("hustler"), g._parse_seed("hustler")]
	check(seeds[0] == -1 and seeds[1] == 1234 and seeds[2] == seeds[3] and seeds[2] >= 0, "seed parsing: blank, number, stable word")
	var a: Array = _two_runs(555)
	check(a[0] == a[1], "same seed gives same bosses and labs")
	var b := _shop_ids(555, 2, 0)
	var c := _shop_ids(555, 2, 500)
	check(b == c, "shop offers do not depend on how the table was played")
	check(b != _shop_ids(556, 2, 0), "different seed gives different offers")
	var r1 := RunState.new()
	r1.start(90)
	var r2 := RunState.new()
	r2.start(90)
	r2.rng.randi()
	check(r1.rack_seed() == r2.rack_seed(), "rack depends on the seed, not the RNG position")
	g.pending_seed = 4242
	g._new_run()
	await process_frame
	check(g.run.seed_value == 4242 and g.pending_seed == -1, "typed seed starts the run once")
	g._new_run()
	check(g.run.seed_value != 4242, "next run is random again")
	print("daily")
	var key: String = Records.today_key()
	g._start_daily()
	await process_frame
	check(g.run.daily_key == key and g.run.seed_value == Records.daily_seed(key), "daily uses today's seed")
	check(g.run.cue == Records.daily_cue(key) and g.run.locked.is_empty(), "daily has a fixed cue and the full pool")
	check(g.lbl_round.text.begins_with("Daily"), "HUD shows it is a daily")
	check(Records.daily_seed("20261108") != Records.daily_seed("20261109"), "each day differs")
	print("history")
	g.records.entries = []
	g.run.total_score = 500
	g.run.tables_cleared = 3
	g.run.total_pots = 20
	g.run.best_shot = 200
	g.run.perks.assign(["golden", "bank"])
	g.records.record(g.run, false)
	check(g.records.entries.size() == 1 and g.records.daily_best(key).score == 500, "finished daily is recorded")
	g.run.tables_cleared = 5
	g.run.total_score = 900
	g.records.record(g.run, false)
	check(g.records.entries.size() == 1 and g.records.lifetime().tables == 5, "same run updates, never double-counts")
	var other := RunState.new()
	other.start(1)
	other.perks.assign(["bank"])
	other.tables_cleared = 9
	other.total_score = 7000
	g.records.record(other, true)
	var l: Dictionary = g.records.lifetime()
	check(l.runs == 2 and l.wins == 1 and l.tables == 14 and l.best_tables == 9, "lifetime totals")
	check(g.records.favourites()[0] == ["bank", 2], "favourites ranks by runs carried")
	var fresh := Records.new()
	fresh.load_file()
	check(fresh.entries.size() == 2, "history persists")
	var bad := FileAccess.open(Records.PATH, FileAccess.WRITE)
	bad.store_string("{broken")
	bad.close()
	fresh.load_file()
	check(fresh.entries.is_empty(), "damaged history is ignored, not fatal")
	print("collection")
	g.meta = Meta.new()
	g.screens.tab = "Elements"
	var rows: Array = g.screens._rows()
	check(rows.size() == Catalog.PERKS.size(), "all Elements listed")
	check(rows.filter(func(r): return r.hint != "").size() == g.meta.locked_perks().size(), "locked Elements show unlock hints")
	for t in MetaScreens.TABS:
		g.screens.tab = t
		check(g.screens._rows().size() > 0, "%s tab has entries" % t)
	print("records tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)


func _two_runs(s: int) -> Array:
	var out: Array = []
	for i in 2:
		var r := RunState.new()
		r.start(s)
		out.append(r.plan.map(func(t): return [t.lab, t.anomaly]))
	return out


func _shop_ids(s: int, table: int, burn: int) -> Array:
	var r := RunState.new()
	r.start(s)
	for i in burn:
		r.rng.randi()
	r.table_index = table
	r.roll_shop()
	return r.shop.map(func(x): return x.id)
