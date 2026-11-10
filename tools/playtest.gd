extends SceneTree
## Emulated playtests: simulated players with distinct skill and decision styles
## play complete runs through the real physics, scoring, shop and boss rules.
##
##   Godot --headless --path . --script res://tools/playtest.gd -- <persona> <runs> <seed0> <out.jsonl>
##
## Each run writes one JSON line: outcome, cue, purchases, per-table results,
## fouls and so on. tools/playtest_report.mjs aggregates them.

const PERSONAS := {
	"novice": {"aim": 1.0, "pow_noise": 0.12, "look": false, "tries": 0, "sloppy": 0.35, "shop": "random", "reroll": false},
	"casual": {"aim": 0.6, "pow_noise": 0.08, "look": true, "tries": 2, "sloppy": 0.1, "shop": "cheap", "reroll": false},
	"builder": {"aim": 0.4, "pow_noise": 0.06, "look": true, "tries": 4, "sloppy": 0.0, "shop": "synergy", "reroll": true},
	"saver": {"aim": 0.4, "pow_noise": 0.06, "look": true, "tries": 4, "sloppy": 0.0, "shop": "economy", "reroll": false},
	"gambler": {"aim": 0.5, "pow_noise": 0.07, "look": true, "tries": 4, "sloppy": 0.0, "shop": "risk", "reroll": true, "greedy": true},
	"expert": {"aim": 0.2, "pow_noise": 0.04, "look": true, "tries": 5, "sloppy": 0.0, "shop": "value", "reroll": true},
}

## Rough power estimate per perk for value-driven shoppers (3 strong .. 1 weak).
const TIER := {
	"golden": 3, "echo": 3, "supernova": 3, "glasscannon": 3, "heat": 3, "streak": 3, "catalyst": 3, "collector": 3,
	"geometry": 3, "rhythm": 3, "chain": 3, "kick": 2, "multi": 2, "fusion": 2, "bank": 2, "prime": 2, "stripes": 2,
	"even": 2, "side": 2, "corner": 2, "venture": 2, "hothand": 2, "rotation": 2, "moneyball": 2, "minimalist": 2,
	"comeback": 2, "precision": 2, "migration": 3, "chalk": 2, "jaws": 2, "afterburner": 2, "boomerang": 2,
	"featherweight": 2, "stun": 2, "insurance": 2,
}

var P: Dictionary
var persona := ""
var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	persona = a[0] if a.size() > 0 else "casual"
	var runs := int(a[1]) if a.size() > 1 else 5
	var seed0 := int(a[2]) if a.size() > 2 else 1
	var out_path := a[3] if a.size() > 3 else "user://playtest.jsonl"
	P = PERSONAS[persona]
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	var t0 := Time.get_ticks_msec()
	for r in runs:
		var rec := play_run(seed0 + r)
		f.store_line(JSON.stringify(rec))
		f.flush()
		print("%s run %d: cleared %d (%s) cue=%s perks=%s" % [persona, r + 1, rec.cleared, "WIN" if rec.won else "died T%d %s" % [rec.died_at + 1, rec.died_anomaly], rec.cue, rec.final_perks])
	f.close()
	print("PLAYTEST DONE %s %d runs in %ds" % [persona, runs, (Time.get_ticks_msec() - t0) / 1000])
	quit()


## ---------------------------------------------------------------- run loop
func play_run(s: int) -> Dictionary:
	rng.seed = s * 7919 + persona.hash()
	var cues := Catalog.CUES.keys()
	var cue: String = cues[rng.randi_range(0, cues.size() - 1)]
	var run := RunState.new()
	run.start(s, cue)
	var rec := {
		"persona": persona, "seed": s, "cue": cue, "won": false, "cleared": 0, "died_at": -1, "died_anomaly": "",
		"tables": [], "purchases": [], "sold": [], "rerolls": 0, "fouls": {},
		"shots": 0, "pots": 0, "final_perks": [], "money_end": 0, "best_shot": 0, "best_heat": 0, "bounties": 0,
	}
	while true:
		run.begin_table()
		var t := run.current()
		var res := play_table(run, rec)
		rec.tables.append({"i": run.table_index, "lab": t.lab, "anomaly": t.anomaly, "target": run.target(),
			"score": run.score, "shots": run.shots_taken, "won": res, "chalk_left": run.chalk, "perks": run.perks.duplicate()})
		if not res:
			rec.died_at = run.table_index
			rec.died_anomaly = t.anomaly
			break
		run.payout()
		rec.cleared += 1
		if run.table_index >= run.plan.size() - 1:
			rec.won = true
			break
		shop(run, rec)
		run.advance_table()
	rec.final_perks = run.perks.duplicate()
	rec.money_end = run.money
	rec.best_shot = run.best_shot
	rec.best_heat = run.best_heat
	return rec


func play_table(run: RunState, rec: Dictionary) -> bool:
	var layout := run.build_layout()
	var sim := new_rack(run, layout)
	var is_break := true
	var guard := 0
	for id in run.items.duplicate():
		if id != "handchalk" and run.use_state_item(id):
			run.items.erase(id)
	if run.table_mods.get("wide", false):
		layout = run.build_layout()
		sim.layout = layout
	while guard < 250:
		guard += 1
		var ci := sim.index_of(0)
		if sim.alive[ci] == 0:
			place_cue(sim, run, false)
		var shot := choose_shot(sim, run, is_break)
		var dir: Vector2 = (shot.dir as Vector2).rotated(deg_to_rad(rng.randfn(0.0, P.aim)))
		var pw: float = clampf(shot.power * (1.0 + rng.randfn(0.0, P.pow_noise)), 0.05, 1.0)
		var ctx := run.shot_ctx(pw, sim, is_break)
		var start := {}
		for i in sim.count():
			if sim.alive[i] == 1:
				start[sim.num[i]] = sim.pos[i]
		sim.strike(dir, AutoPlayer.speed(pw) * run.power_mult(is_break), shot.get("follow", 0.0), 0.0)
		sim.settle()
		ctx["events"] = sim.events
		ctx["start_pos"] = start
		ctx["rng"] = run.rng
		ctx["cue_end"] = sim.pos[ci]
		var res := Scorer.score(ctx)
		rec.shots += 1
		rec.pots += res.potted.size() if res.scored else 0
		if not res.scored:
			rec.fouls[res.foul] = rec.fouls.get(res.foul, 0) + 1
		var out := run.apply_shot(res, is_break, sim.object_balls_left(), sim.alive[ci] == 1)
		if out.has("bounty"):
			rec.bounties += 1
		is_break = false
		if run.chalk == 1 and run.items.has("handchalk") and not out.over and not out.cleared:
			run.use_state_item("handchalk")
			run.items.erase("handchalk")
		if out.cleared:
			return true
		if out.over:
			return false
		if out.has("layout_changed"):
			layout = run.build_layout()
			sim.layout = layout
			run.apply_physics(sim)
		if out.rack_cleared:
			sim = new_rack(run, layout)
			is_break = true
	return false


func new_rack(run: RunState, layout: TableLayout) -> PoolSim:
	var s := PoolSim.new(layout)
	s.add_ball(0, Rack.HEAD)
	var r := RandomNumberGenerator.new()
	r.seed = run.rack_seed()
	Rack.build(s, r, run.ball_set)
	run.apply_physics(s)
	return s


## ---------------------------------------------------------------- shooting
func choose_shot(sim: PoolSim, run: RunState, is_break: bool) -> Dictionary:
	var ci := sim.index_of(0)
	if is_break:
		var p := 1.0 if persona != "novice" else rng.randf_range(0.7, 1.0)
		var tgt := Rack.FOOT
		if run.current().anomaly == "rotation":
			for i in sim.count():
				if sim.num[i] == 1:
					tgt = sim.pos[i]
		return {"dir": (tgt - sim.pos[ci]).normalized(), "power": p}
	if not P.look:
		return novice_shot(sim, run)
	if P.get("greedy", false):
		return greedy_shot(sim, run)
	var shot := AutoPlayer.choose(sim, run, P.tries)
	if rng.randf() < P.sloppy:
		var c := AutoPlayer.candidates(sim, run)
		if c.size() > 1:
			var pick: Dictionary = c[rng.randi_range(0, mini(3, c.size() - 1))]
			shot = {"dir": pick.dir, "power": shot.power}
	return shot


## A newcomer: goes for whatever looks easiest (sometimes not even that) and
## judges power by eye from the distance.
func novice_shot(sim: PoolSim, run: RunState) -> Dictionary:
	var c := AutoPlayer.candidates(sim, run)
	var ci := sim.index_of(0)
	if c.is_empty():
		return AutoPlayer.safety_shot(sim, run)
	var pick: Dictionary = c[0]
	if rng.randf() < P.sloppy:
		pick = c[rng.randi_range(0, mini(3, c.size() - 1))]
	var obj: int = pick.obj
	var pk: Vector2 = sim.layout.pockets[pick.pocket].pos
	var dist := sim.pos[ci].distance_to(sim.pos[obj]) + sim.pos[obj].distance_to(pk)
	return {"dir": pick.dir, "power": clampf(0.22 + dist / 1500.0, 0.2, 0.95)}


## A gambler chases the biggest number on the table, not the safest pot.
func greedy_shot(sim: PoolSim, run: RunState) -> Dictionary:
	var c := AutoPlayer.candidates(sim, run)
	var ci := sim.index_of(0)
	if c.is_empty():
		return AutoPlayer.safety_shot(sim, run)
	var best := {}
	var best_v := -1.0
	for j in mini(P.tries + 2, c.size()):
		for pw in [0.45, 0.8]:
			var s := sim.clone()
			s.strike(c[j].dir, AutoPlayer.speed(pw), 0.0, 0.0)
			s.settle()
			var ctx := run.shot_ctx(pw, sim, false)
			ctx["events"] = s.events
			ctx["cue_end"] = s.pos[ci]
			var r := Scorer.score(ctx)
			if not r.scored:
				continue
			var v: float = r.total * pow(c[j].ease, 0.3)
			if v > best_v:
				best_v = v
				best = {"dir": c[j].dir, "power": pw}
	if best.is_empty():
		return {"dir": c[0].dir, "power": 0.55}
	return best


func nearest_ball(sim: PoolSim, ci: int) -> Dictionary:
	var nb := -1
	var nd := 1.0e9
	for i in sim.count():
		if sim.alive[i] == 1 and sim.num[i] != 0:
			var d := sim.pos[i].distance_to(sim.pos[ci])
			if d < nd:
				nd = d
				nb = i
	if nb < 0:
		return {"dir": Vector2.RIGHT, "power": 0.4}
	return {"dir": (sim.pos[nb] - sim.pos[ci]).normalized(), "power": 0.5}


func place_cue(sim: PoolSim, run: RunState, head_only: bool) -> void:
	var ci := sim.index_of(0)
	var p := Rack.HEAD
	if persona == "novice":
		for t in 40:
			var q := Vector2(rng.randf_range(40, 960), rng.randf_range(40, 460))
			if sim.is_clear_spot(q, ci):
				p = q
				break
	else:
		p = AutoPlayer.place_spot(sim, run, rng, head_only)
	sim.alive[ci] = 1
	sim.pos[ci] = p
	sim.vel[ci] = Vector2.ZERO


## ---------------------------------------------------------------- shopping
func shop(run: RunState, rec: Dictionary) -> void:
	run.roll_shop()
	var rerolls := 0
	for pass_i in 4:
		var bought := false
		var best_i := -1
		var best_v := 0.0
		for i in run.shop.size():
			var it: Dictionary = run.shop[i]
			if it.sold or run.money < it.cost:
				continue
			var v := item_value(run, it)
			if v > best_v:
				best_v = v
				best_i = i
		if best_i >= 0:
			var it: Dictionary = run.shop[best_i]
			if it.type == "perk" and run.perks.size() >= RunState.MAX_PERKS:
				var worst := worst_perk(run)
				if worst >= 0 and best_v > perk_value(run, run.perks[worst]) + 1.5:
					rec.sold.append(run.perks[worst])
					run.sell_perk(worst)
				else:
					best_i = -1
		if best_i >= 0 and run.buy(best_i) == "":
			var it2: Dictionary = run.shop[best_i]
			rec.purchases.append({"t": run.table_index, "type": it2.type, "id": it2.id})
			bought = true
		if not bought:
			var can_reroll: bool = P.reroll and rerolls < 2 and run.money >= run.reroll_cost + 5
			if persona == "saver" and run.perks.has("interest"):
				can_reroll = can_reroll and run.money - run.reroll_cost >= 15
			if can_reroll and run.perks.size() < RunState.MAX_PERKS:
				run.reroll()
				rerolls += 1
				rec.rerolls += 1
			else:
				break


func item_value(run: RunState, it: Dictionary) -> float:
	match it.type:
		"item":
			return 1.6 if RunState.STATE_ITEMS.has(it.id) and run.items.size() < run.item_slots() else 0.0
		"perk":
			if run.perks.size() >= RunState.MAX_PERKS and P.shop in ["random", "cheap"]:
				return 0.0
			return perk_value(run, it.id)
		"imbue":
			match P.shop:
				"random":
					return rng.randf() * 2.5
				"economy":
					return 2.0 if it.id == "gold" else 0.5
				"risk":
					return 2.5 if it.id == "glass" else 1.0
				_:
					return 2.0 if it.id in ["vein", "heavy", "ember"] else 1.0
	return 0.0


func perk_value(run: RunState, id: String) -> float:
	var f: Dictionary = Catalog.PERKS[id]
	var tier: float = TIER.get(id, 1)
	var fam: String = f.get("fam", "utility")
	match P.shop:
		"random":
			return rng.randf() * 4.0
		"cheap":
			return 6.0 - f.cost * 0.6 + tier * 0.5
		"synergy":
			var same := 0
			for o in run.perks:
				if Catalog.PERKS[o].get("fam", "") == fam:
					same += 1
			return tier + same * 1.6 + (0.8 if fam == "streak" or fam == "pocket" else 0.0)
		"economy":
			var early := run.table_index < 4
			return tier + (3.0 if fam == "money" and early else 0.0) - (0.5 if run.money < 10 and not early else 0.0)
		"risk":
			return tier + (3.0 if fam == "risk" else 0.0) + (1.0 if f.r == 2 else 0.0)
		_:
			return tier * 1.4 + f.r * 0.6
	return tier


func worst_perk(run: RunState) -> int:
	var w := -1
	var wv := 1.0e9
	for i in run.perks.size():
		var v := perk_value(run, run.perks[i])
		if v < wv:
			wv = v
			w = i
	return w
