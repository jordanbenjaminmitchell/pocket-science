extends SceneTree
## Usable items, the new Physics, cue, clearing, gear and Imbue Perks, the ball
## set, and portals that the physics and the prediction line both respect.

var failures := 0


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func pot(n: int, k: int = 0) -> Dictionary:
	return {"type": "pocket", "a": n, "pocket": k, "rails": 0, "at": Vector2.ZERO}


func score(events: Array, extra: Dictionary = {}) -> Dictionary:
	var c := {"perks": [], "imbues": {}, "hot_pocket": -1, "boss": "local", "lab": "standard", "anomaly": "", "heat": 0,
		"power": 0.5, "shots_taken": 0, "events": events, "target": 1000, "objects": 10}
	c.merge(extra, true)
	return Scorer.score(c)


func _initialize() -> void:
	var h5 := [{"type": "ball", "a": 0, "b": 5}, pot(5)]
	print("content")
	check(Catalog.ITEMS.size() == 21, "21 items in the Kit (%d)" % Catalog.ITEMS.size())
	for id in Catalog.ITEMS:
		check(IconArt.MOTIFS.has(id), "%s has an icon" % id) if not IconArt.MOTIFS.has(id) else null
		check(["setup", "pause", "after", "any"].has(Catalog.ITEMS[id].when) and ["tool", "consumable"].has(Catalog.ITEMS[id].kind), "%s says when it is used and what kind it is" % id)
	var motifs := {}
	for id in Catalog.PERKS.keys() + Catalog.ITEMS.keys():
		var m: String = IconArt.MOTIFS.get(id, "")
		check(m != "" and not motifs.has(m), "%s has its own icon" % id) if m == "" or motifs.has(m) else null
		motifs[m] = true
	var phys := Catalog.PERKS.keys().filter(func(k): return Catalog.PERKS[k].fam == "physics").size()
	check(phys >= 8, "8 Physics Perks (%d)" % phys)
	check(Catalog.CUES.size() >= 14, "14 starting cues (%d)" % Catalog.CUES.size())

	print("perks")
	check(score(h5, {"perks": ["thinrack"], "removed": 2}).total == 27, "Thin Rack: +6 per removed ball")
	check(score(h5, {"perks": ["missing"], "removed": 2}).total == 30, "Missing Piece: Chain per removed ball")
	check(score(h5, {"perks": ["followthru"], "follow": 0.6}).total == 22, "Follow Through pays with follow")
	check(score(h5, {"perks": ["drawartist"], "follow": -0.6}).total == 22, "Draw Artist pays with draw")
	check(score(h5, {"perks": ["drawartist"], "follow": 0.0}).total == 15, "and only with draw")
	check(score(h5, {"perks": ["secondcoat"], "imbues": {5: "heavy"}}).total == 82, "Second Coat ×1.5 on imbued balls")
	check(score(h5, {"boost": 2.0}).total == 30, "Double Down doubles the shot")
	check(score(h5, {"all_hot": true, "hot_pocket": 3}).total == 30, "Spotlight makes every pocket hot")
	var run := RunState.new()
	run.start(5)
	run.begin_table()
	var base := PoolSim.new(run.build_layout())
	run.apply_physics(base)
	run.perks.assign(["backspin", "masse", "slowcloth", "liverails", "heavyhit", "longarm", "bigbreak"])
	var s := PoolSim.new(run.build_layout())
	s.add_ball(0, Vector2(100, 100))
	run.apply_physics(s)
	check(s.spin_power == 1.5 and s.side_power == 2.0, "Backspin Wax and Massé Master change the physics")
	check(s.roll_decel > base.roll_decel and s.rail_e > base.rail_e, "Slow Cloth and Live Rails change the cloth")
	check(is_equal_approx(s.mass[0], 1.3), "Heavy Hitter makes the cue ball heavier")
	check(is_equal_approx(run.power_mult(false), 1.15) and is_equal_approx(run.power_mult(true), 1.4375), "Long Arm and Big Break hit harder")

	print("items")
	run.perks.clear()
	run.begin_table()
	check(not run.use_state_item("slip"), "an Insurance Slip needs a shot that cost Chalk")
	var miss := {"scored": false, "foul": "Miss", "total": 0, "money": 0, "catalyst_gain": 0.0, "potted": [], "shattered": [], "lines": []}
	run.apply_shot(miss, false, 9, true)
	run.apply_shot(miss, false, 9, true)
	var chalk_now := run.chalk
	check(run.last_chalk_lost and run.use_state_item("slip") and run.chalk == chalk_now + 1, "the Slip gives the Chalk back")
	check(not run.use_state_item("slip"), "only once")
	run.money = 50
	run.shop = [{"type": "item", "id": "rewind", "cost": 9, "sold": false}]
	check(run.buy(0) == "" and run.tools.has("rewind") and int(run.tool_charges.rewind) == 1, "Tools go in Tool slots with one charge")
	check(run.spend("rewind") and not run.spend("rewind"), "one charge per table")
	run.begin_table()
	check(int(run.tool_charges.rewind) == 1, "and it comes back on the next table")
	run.perks.assign(["overclock"])
	run.begin_table()
	check(int(run.tool_charges.rewind) == 2, "Overclock gives Tools two charges")
	run.perks.clear()
	run.items.assign(["wall", "blink", "portal"])
	run.shop = [{"type": "item", "id": "slip", "cost": 3, "sold": false}]
	check(run.buy(0) != "", "Consumable slots are limited")
	run.perks.assign(["packrat"])
	check(run.buy(0) == "" and run.items.size() == 4 and run.tool_slots() == 3, "Pack Rat adds a slot of each kind")
	run.perks.assign(["quartermaster", "enchanter"])
	check(run.item_cost("portal") == 4 and run.imbue_cost("glass") == 3, "Quartermaster and Enchanter cut prices")
	run.perks.clear()
	run.table_mods.covered.append(0)
	var covered := run.build_layout()
	var plain := TableLayout.new().build(run.pocket_scale(), [])
	check(covered.pockets[0].closed and covered.pockets[5].r > plain.pockets[5].r * 1.25, "Pocket Cover closes one pocket and widens the opposite")
	var c5 := [{"type": "ball", "a": 0, "b": 5}, pot(5, 2)]
	check(score(c5, {"called": {"ball": 5, "pocket": 2}}).total == 45, "a Called Shot that comes off pays ×3")
	check(score(c5, {"called": {"ball": 5, "pocket": 3}}).total == 15, "a wrong call pays nothing extra")

	print("ball set")
	var lean := RunState.new()
	lean.start(9, "lean")
	check(lean.ball_set.size() == 13 and not lean.ball_set.has(1) and lean.removed_count() == 2, "the Lean Cue starts without the 1 and 2")
	var rs := PoolSim.new(TableLayout.new().build(1.0, []))
	var rr := RandomNumberGenerator.new()
	rr.seed = 3
	Rack.build(rs, rr, lean.ball_set)
	check(rs.count() == 13 and rs.num[4] == 8, "a smaller set racks with the 8 in the middle")
	var big := range(1, 22)
	var bs := PoolSim.new(TableLayout.new().build(1.0, []))
	Rack.build(bs, rr, big)
	var overlap := false
	for i in bs.count():
		for j in range(i + 1, bs.count()):
			overlap = overlap or bs.pos[i].distance_to(bs.pos[j]) < TableLayout.R * 2.0 - 0.5
	check(bs.count() == 21 and not overlap and Array(bs.pos).reduce(func(a, p): return maxf(a, p.x), 0.0) < TableLayout.W - TableLayout.R, "a 21-ball set fits on the table")

	print("portals")
	var lay := TableLayout.new().build(1.0, [])
	lay.portals.append({"a": Vector2(300, 250), "b": Vector2(700, 120)})
	var ps := PoolSim.new(lay)
	var bi := ps.add_ball(3, Vector2(200, 250))
	ps.vel[bi] = Vector2(300, 0)
	var crossed := false
	for k in 600:
		ps.step(PoolSim.STEP)
		if ps.pos[bi].distance_to(Vector2(700, 120)) < TableLayout.PORTAL_R + 2.0:
			crossed = true
			break
	check(crossed and ps.vel[bi].x > 0.0 and absf(ps.vel[bi].y) < 0.01, "a ball comes out of the other portal moving the same way")
	var guide_sim := PoolSim.new(lay)
	guide_sim.add_ball(0, Vector2(200, 250))
	guide_sim.add_ball(5, Vector2(800, 120))
	var g: Dictionary = TableView.compute_guide(guide_sim, Vector2.RIGHT, 0.0, 0.0, false)
	check(g.has("ghost") and g.get("obj_number", -1) == 5 and not (g.aim_gaps as Array).is_empty(), "the prediction line follows the cue ball through a portal")
	var clone := guide_sim.clone()
	clone.strike(Vector2.RIGHT, 600.0, 0.0, 0.0)
	var hit_five := false
	for k in 1200:
		clone.step(PoolSim.STEP)
		for e in clone.events:
			hit_five = hit_five or (e.type == "ball" and (e.a == 5 or e.b == 5))
		if hit_five:
			break
	check(hit_five, "and the real shot does hit that ball")
	var tl := RunState.new()
	tl.start(2)
	tl.begin_table()
	tl.table_mods.bumpers.append([500.0, 250.0])
	tl.table_mods.portals.append([200.0, 100.0, 800.0, 400.0])
	var built := tl.build_layout()
	check(built.bumpers.size() == 1 and built.portals.size() == 1, "placed bumpers and portals become part of the table")
	var saved := tl.to_dict()
	var back := RunState.new()
	check(JSON.parse_string(JSON.stringify(saved)) != null, "the table with its gear saves")
	print("items tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
