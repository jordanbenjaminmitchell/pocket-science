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
	check(phys >= 8, "8 Physics Elements (%d)" % phys)
	check(Catalog.CUES.size() >= 13, "13 starting cues (%d)" % Catalog.CUES.size())

	print("perks")
	check(score(h5, {"perks": ["thinrack"], "removed": 2}).total == 44, "Thin Rack: +12 per removed ball")
	check(score(h5, {"perks": ["missing"], "removed": 2}).total == 40, "Missing Piece: Chain per removed ball")
	check(score(h5, {"perks": ["followthru"], "follow": 0.6}).total == 30, "Follow Through pays with follow")
	check(score(h5, {"perks": ["drawartist"], "follow": -0.6}).total == 30, "Draw Artist pays with draw")
	check(score(h5, {"perks": ["drawartist"], "follow": 0.0}).total == 20, "and only with draw")
	check(score(h5, {"perks": ["secondcoat"], "imbues": {5: "heavy"}}).total == 37, "Second Coat ×1.5 on Isotope balls")
	check(score(h5, {"boost": 2.0}).total == 40, "Double Down doubles the shot")
	check(score(h5, {"all_hot": true, "hot_pocket": 3}).total == 40, "Spotlight makes every pocket hot")
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
	check(score(c5, {"called": {"ball": 5, "pocket": 2}}).total == 60, "a Called Shot that comes off pays ×3")
	check(score(c5, {"called": {"ball": 5, "pocket": 3}}).total == 20, "a wrong call pays nothing extra")

	print("heat")
	var hot := RunState.new()
	hot.start(5)
	hot.begin_table()
	hot.heat = 6
	hot.apply_shot(miss, false, 9, true)
	check(hot.heat == 3, "a miss halves Heat")
	hot.perks.assign(["migration"])
	hot.heat = 6
	hot.apply_shot(miss, false, 9, true)
	check(hot.heat == 5, "Stay Hot: On fire, a miss only costs 1 Heat")
	hot.heat = 4
	hot.apply_shot(miss, false, 9, true)
	check(hot.heat == 2, "but below Heat 5 it still halves")

	print("lucky and volatile")
	var lk := RunState.new()
	lk.start(5)
	lk.begin_table()
	lk.imbues = {5: "lucky", 6: "glass"}
	var lmiss := {"scored": true, "foul": "", "total": 20, "money": 0, "catalyst_gain": 0.0, "potted": [5], "shattered": [], "lines": [], "lucky_misses": [5], "lucky_hits": []}
	var lo: Dictionary = lk.apply_shot(lmiss, false, 9, true)
	var to: int = lo.lucky_moves[0][1]
	check(not lk.imbues.has(5) and lk.imbues.get(to, "") == "lucky" and to != 6 and to != 8 and int(lk.lucky_mult[to]) == 3, "a Lucky miss jumps to a free ball at ×3")
	var lk2 := RunState.new()
	lk2.load_dict(JSON.parse_string(JSON.stringify(lk.to_dict())))
	check(int(lk2.lucky_mult.get(to, 0)) == 3, "and the climb is saved with the run")
	var jk := RunState.new()
	jk.start(5)
	jk.begin_table()
	jk.heat = 6
	jk.apply_shot({"scored": true, "foul": "", "total": 80, "money": 0, "catalyst_gain": 0.0, "potted": [5], "shattered": [], "lines": [], "jinxed": true}, false, 9, true)
	check(jk.heat == 3, "Jinxed halves Heat after the shot's gain (%d)" % jk.heat)
	var vs := RunState.new()
	vs.start(5)
	vs.begin_table()
	vs.imbues = {5: "volatile"}
	var vlay := vs.build_layout()
	var vsim := PoolSim.new(vlay)
	vsim.add_ball(0, Vector2(300, 250))
	vsim.add_ball(5, Vector2(380, 250))
	vs.apply_physics(vsim)
	vsim.vel[0] = Vector2(400, 0)
	vsim.settle()
	check(vsim.alive[1] == 0 and vsim.events.any(func(e): return e.type == "shatter" and e.get("exploded", false)), "a Volatile ball explodes when first hit")
	var vclone := PoolSim.new(vlay)
	vs.apply_physics(vclone)
	check(vclone.volatile.has(5), "and the prediction knows it will")

	print("Isotopes that move and grow")
	var im := RunState.new()
	im.start(5)
	im.begin_table()
	im.ball_set.append(11)
	im.imbues = {5: "heavy", 3: "twin", 7: "vein", 2: "gold"}
	var hitres := {"scored": true, "foul": "", "total": 20, "money": 0, "catalyst_gain": 0.0, "potted": [5], "shattered": [], "lines": [],
		"weighted_sunk": [5], "twin_hops": [3], "vein_spread": [4], "gilded_sunk": [2]}
	var io: Dictionary = im.apply_shot(hitres, false, 9, true)
	check(int(im.imbue_level[5]) == 4, "Weighted climbs to ×4 after a sink")
	check(im.imbues.get(11, "") == "twin" and not im.imbues.has(3), "Twin hops to its colour twin (3 to 11)")
	check(im.imbues.get(4, "") == "vein" and im.imbues.get(7, "") == "vein", "Vein spreads to the ball that knocked it in")
	check((io.imbue_moves as Array).size() >= 3, "and each move is announced")
	im.apply_shot(miss, false, 9, true)
	check(not im.imbue_level.has(5), "a miss drops Weighted back to ×3")
	check(int(im.imbue_level.get(2, 0)) == 1, "Gilded keeps its streak through the table")
	im.table_index += 1
	im.gilded_this_table = {}
	im.begin_table()
	check(int(im.imbue_level.get(2, 0)) == 0, "but a table without sinking it resets the streak")

	print("object cues")
	var pc := RunState.new()
	pc.start(5, "portals")
	pc.begin_table()
	check(pc.cue_kit() == "portal" and int(pc.tool_charges.portal) == 4 and pc.perks.has("boomerang"), "the Portal Cue carries 4 Portal Pairs and Boomerang")
	for k in 4:
		pc.spend("portal")
	check(not pc.spend("portal"), "4 uses a table")
	pc.begin_table()
	check(int(pc.tool_charges.portal) == 4, "and they come back every table")

	print("ball set")
	var lean := RunState.new()
	lean.start(9, "lean")
	check(lean.ball_set.size() == 8 and not lean.ball_set.has(1) and lean.removed_count() == 2, "the Lean Cue starts without the 1 and 2")
	var rs := PoolSim.new(TableLayout.new().build(1.0, []))
	var rr := RandomNumberGenerator.new()
	rr.seed = 3
	Rack.build(rs, rr, lean.ball_set)
	check(rs.count() == 8 and Array(rs.num).has(8), "a smaller set racks")
	var ten := PoolSim.new(TableLayout.new().build(1.0, []))
	Rack.build(ten, rr, range(1, 11))
	check(ten.count() == 10 and ten.num[4] == 8, "ten balls rack as one triangle with the 8 in the middle")
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
