class_name RunState
extends RefCounted
## Everything that persists across a run: money, perks, imbues,
## the table sequence and the shop.

const MAX_PERKS := 6
const BASE_CHALK := 5

var seed_value := 0
var cue := "maple"
var rng := RandomNumberGenerator.new()
var table_index := 0
var money := 4
var perks: Array[String] = []
var imbues := {}         # ball number -> imbue id
var catalyst := 0.0
var plan: Array[Dictionary] = []   # one entry per table: {target, rack, boss, lab, anomaly}
var shop: Array[Dictionary] = []
var reroll_cost := 2
var endless := false
var record_id := ""       # links this run to its Records entry
var daily_key := ""       # yyyymmdd when this is a daily challenge
var handicap := 0            # difficulty level
var total_score := 0
var locked: Array = []    # perks not yet unlocked (Meta); empty = everything available

# Per-table state
var score := 0
var chalk := 3
var heat := 0
var best_heat := 0
var shots_taken := 0
var hot_pocket := 0
var racks_cleared := 0
var bounty := ""
var bounty_done := false
var element_mix: Array = []   # Element Table: the last elements potted
var forgiven := false         # The Local: the free miss has been used
var pockets_used: Array = []
var shrink_steps := 0
var insured_used := 0
var carry := 0           # Overflow: score carried into the next table

# Run stats
var total_pots := 0
var best_shot := 0
var tables_cleared := 0


func start(s: int, cue_id: String = "maple", handicap_level: int = 0) -> void:
	handicap = clampi(handicap_level, 0, Catalog.HANDICAPS.size() - 1)
	record_id = ""
	daily_key = ""
	total_score = 0
	seed_value = s
	rng.seed = s
	cue = cue_id
	var c: Dictionary = Catalog.CUES.get(cue, Catalog.CUES.maple)
	table_index = 0
	money = c.money
	perks.clear()
	perks.assign(c.perks)
	imbues.clear()
	catalyst = 0.0
	total_pots = 0
	best_shot = 0
	tables_cleared = 0
	endless = false
	_build_plan()


func _build_plan() -> void:
	plan.clear()
	var used := {}
	for slot in Catalog.TABLES:
		var id: String = slot.get("boss", "")
		if id == "":
			var pool: Array = Catalog.BOSSES.keys().filter(func(k): return int(Catalog.BOSSES[k].tier) == int(slot.tier) and not used.has(k))
			id = pool[rng.randi_range(0, pool.size() - 1)]
		used[id] = true
		plan.append(_table_entry(id, int(slot.target)))


func _table_entry(id: String, tgt: int) -> Dictionary:
	var b: Dictionary = Catalog.BOSSES[id]
	return {"id": id, "target": tgt, "boss": true, "lab": b.lab, "anomaly": b.anomaly}


func current() -> Dictionary:
	if table_index < plan.size():
		return plan[table_index]
	# Endless: targets keep climbing while the tour loops through the hard tables.
	var extra := table_index - plan.size() + 1
	var ids: Array = Catalog.BOSSES.keys().filter(func(k): return int(Catalog.BOSSES[k].tier) >= 2 and int(Catalog.BOSSES[k].tier) < 9)
	return _table_entry(ids[(extra + seed_value) % ids.size()], int(plan[plan.size() - 1].target * pow(1.6, extra)))


func begin_table() -> void:
	score = carry
	carry = 0
	heat = 0
	shots_taken = 0
	racks_cleared = 0
	element_mix = []
	forgiven = false
	chalk = max_chalk()
	pockets_used = []
	shrink_steps = 0
	insured_used = 0
	solid_run = 0
	stripe_run = 0
	roll_hot_pocket(-1)
	var keys := Catalog.BOUNTIES.keys()
	bounty = keys[rng.randi_range(0, keys.size() - 1)]
	while hot_pocket < 0 and (bounty == "hot" or bounty == "hot2"):   # no hot pocket here to aim at
		bounty = keys[rng.randi_range(0, keys.size() - 1)]
	bounty_done = false


func max_chalk() -> int:
	var c := BASE_CHALK + (1 if perks.has("chalk") else 0)
	c += int(Catalog.CUES.get(cue, Catalog.CUES.maple).chalk)
	if handicap >= 2:
		c -= 1
	# Endless wears you down: one less Chalk every four tables past the last.
	if table_index >= plan.size():
		c -= int((table_index - plan.size() + 1) / 4)
		return maxi(c, 2)
	return maxi(c, 1)


func bounty_reward() -> int:
	return int(Catalog.BOUNTIES[bounty].reward) * (2 if perks.has("hunter") else 1)


func bounty_met(res: Dictionary, _hot: int) -> bool:
	var pots: Array = res.potted
	var heat_after: int = heat + 1 + int(res.get("heat_gain", 0))
	match bounty:
		"bank":
			return int(res.banks) > 0
		"bank2":
			return int(res.max_rails) >= 2
		"combo":
			return int(res.combos) > 0
		"kick":
			return res.kick
		"hot":
			return int(res.hot_pots) > 0
		"hot2":
			return int(res.hot_pots) >= 2
		"big":
			return res.total >= 150
		"big300":
			return res.total >= 300
		"big600":
			return res.total >= 600
		"double":
			return pots.size() >= 2
		"triple":
			return pots.size() >= 3
		"quad":
			return pots.size() >= 4
		"heat3":
			return heat_after >= 3
		"heat4":
			return heat_after >= 4
		"heat6":
			return heat_after >= 6
		"corner":
			return (res.pocket_list as Array).any(func(k): return k in [0, 2, 3, 5])
		"side":
			return (res.pocket_list as Array).any(func(k): return k == 1 or k == 4)
		"eight":
			return res.get("last_eight", false)
		"stripe":
			return pots.any(func(n): return n >= 9)
		"solid":
			return pots.any(func(n): return n <= 7)
		"soft":
			return res.get("power", 0.5) <= 0.35
		"hard":
			return res.get("power", 0.5) >= 0.85
		"breakpot":
			return res.get("is_break", false)
		"chain5":
			return float(res.chain) >= 5.0
		"chain8":
			return float(res.chain) >= 8.0
	return false


func roll_hot_pocket(avoid: int) -> void:
	if current().anomaly == "elements" or current().anomaly == "blind":
		hot_pocket = -1
		return
	var choices: Array = []
	for k in 6:
		if k == avoid:
			continue
		if current().anomaly == "sealed" and (k == 1 or k == 4):
			continue
		choices.append(k)
	hot_pocket = choices[rng.randi_range(0, choices.size() - 1)]


func target() -> int:
	var t := float(current().target)
	if handicap >= 1:
		t *= 1.15
	if handicap >= 5:
		t *= 1.3
	return int(round(t))


func pocket_scale() -> float:
	var s := 1.08
	if perks.has("jaws"):
		s *= 1.12
	if handicap >= 4:
		s *= 0.95
	if current().anomaly == "tight":
		s *= 0.88
	if current().anomaly == "shrink":
		s *= maxf(0.75, 1.0 - 0.03 * shrink_steps)
	return s


func closed_pockets() -> Array[int]:
	var c: Array[int] = []
	if current().anomaly == "sealed":
		c.append_array([1, 4])
	return c


func table_name() -> String:
	var t := current()
	return Catalog.BOSSES[t.id].name


## True if this build is happy to see the 8 go down early.
func wants_eight() -> bool:
	return perks.has("eight") or perks.has("darkhorse") or perks.has("trouble")


## Called after a table is cleared. Returns a breakdown of the payout.
func payout() -> Array:
	var rows: Array = []
	var base := 4
	rows.append(["Table cleared", base])
	if chalk > 0:
		rows.append(["Unused chalk ×%d" % chalk, chalk])
	if perks.has("thrift") and chalk >= 2:
		rows.append(["Thrift", 5])
	if perks.has("overflow"):
		var nxt := table_index + 1
		var next_target: int = plan[nxt].target if nxt < plan.size() else int(target() * 1.6)
		carry = mini(maxi(score - target(), 0), int(next_target * 0.25))
	var total := 0
	for r in rows:
		total += r[1]
	money += total
	tables_cleared += 1
	return rows


func advance_table() -> void:
	table_index += 1
	if table_index >= plan.size():
		endless = true


func is_final_cleared() -> bool:
	return table_index == plan.size() - 1


## ---------------------------------------------------------------- shop
## A rack depends only on seed, table and rack number, never on how you played,
## so a shared seed really does give everyone the same racks.
func rack_seed() -> int:
	return seed_value * 17 + table_index * 131 + racks_cleared * 7 + 1


func roll_shop() -> void:
	# Each table's first offers come from their own stream, so seeds stay comparable.
	var keep_state := rng.state
	rng.seed = seed_value * 31 + table_index * 1009 + 3
	_roll_shop_items()
	_apply_handicap_prices()
	rng.seed = seed_value
	rng.state = keep_state


func _apply_handicap_prices() -> void:
	if handicap < 3:
		return
	for item in shop:
		if not item.get("priced", false):
			item.cost = int(item.cost) + 1
			item["priced"] = true


func _roll_shop_items() -> void:
	reroll_cost = 1 if perks.has("coupon") else 2
	shop.clear()
	for i in 3:
		var f := _random_perk()
		if f != "":
			shop.append({"type": "perk", "id": f, "cost": Catalog.PERKS[f].cost, "sold": false})
	for i in 2:
		var keys := Catalog.IMBUES.keys()
		var iso: String = keys[rng.randi_range(0, keys.size() - 1)]
		var ball := rng.randi_range(1, 14)   # never offered on the 8, which you are avoiding
		if ball >= 8:
			ball += 1
		shop.append({"type": "imbue", "id": iso, "ball": ball, "cost": Catalog.IMBUES[iso].cost, "sold": false})


func _random_perk() -> String:
	var pool: Array = []
	for id in Catalog.PERKS:
		if perks.has(id) or locked.has(id):
			continue
		var already := false
		for s in shop:
			if s.type == "perk" and s.id == id:
				already = true
		if already:
			continue
		var r: int = Catalog.PERKS[id].r
		var w: int = [10, 5, 2][r]
		# Once you have started a build, the shop leans toward it.
		var fam: String = Catalog.PERKS[id].fam
		if BUILD_FAMILIES.has(fam) and perks.any(func(o): return Catalog.PERKS[o].fam == fam):
			w *= 3
		for k in w:
			pool.append(id)
	if pool.is_empty():
		return ""
	return pool[rng.randi_range(0, pool.size() - 1)]


func reroll() -> bool:
	if money < reroll_cost:
		return false
	money -= reroll_cost
	var cost := reroll_cost + 1
	var kept: Array[Dictionary] = []
	for s in shop:
		if s.type != "perk":
			kept.append(s)
	shop = kept
	for i in 3:
		var f := _random_perk()
		if f != "":
			var item := {"type": "perk", "id": f, "cost": Catalog.PERKS[f].cost, "sold": false}
			shop.append(item)
	_apply_handicap_prices()
	# Perks first in display order.
	shop.sort_custom(func(a, b): return (a.type == "perk") and not (b.type == "perk"))
	reroll_cost = cost
	return true


## Returns "" on success, or a reason it failed.
func buy(i: int) -> String:
	var item: Dictionary = shop[i]
	if item.sold:
		return "Sold out"
	if money < item.cost:
		return "Not enough money"
	match item.type:
		"perk":
			if perks.size() >= MAX_PERKS:
				return "Perk slots full - sell one first"
			perks.append(item.id)
		"imbue":
			imbues[item.ball] = item.id
	money -= item.cost
	item.sold = true
	return ""


func sell_perk(i: int) -> int:
	if i < 0 or i >= perks.size():
		return 0
	var id := perks[i]
	var v := maxi(1, int(Catalog.PERKS[id].cost / 2))
	perks.remove_at(i)
	money += v
	return v


func sell_value(id: String) -> int:
	return maxi(1, int(Catalog.PERKS[id].cost / 2))


## Applies a scored (or failed) shot to the table state. Shared by the game and
## the balance bot so both follow identical rules. Returns what happens next:
## {cleared, over, rack_cleared, ball_in_hand, chalk_lost}
func apply_shot(res: Dictionary, was_break: bool, balls_left: int, cue_on_table: bool) -> Dictionary:
	shots_taken += 1
	var out := {"cleared": false, "over": false, "rack_cleared": false, "ball_in_hand": not cue_on_table, "chalk_lost": false}
	if res.scored:
		var hot_before := hot_pocket
		if not bounty_done and bounty_met(res, hot_before):
			bounty_done = true
			money += bounty_reward()
			out["bounty"] = bounty
		score += res.total
		total_score += res.total
		heat += 1 + int(res.get("heat_gain", 0))
		best_heat = maxi(best_heat, heat)
		element_mix = res.get("element_mix", [])
		solid_run = int(res.get("solid_run", solid_run))
		stripe_run = int(res.get("stripe_run", stripe_run))
		money += res.money
		catalyst += res.catalyst_gain
		total_pots += res.potted.size()
		best_shot = maxi(best_shot, res.total)
		for n in res.shattered:
			imbues.erase(n)
		for k in res.get("pocket_list", []):
			if not pockets_used.has(k):
				pockets_used.append(k)
	else:
		var free_break: bool = was_break and res.foul == "Miss"
		# Boss "soft fouls": the shot scores nothing and the heat resets, but no chalk is lost.
		var soft: bool = res.foul == "Wrong pocket" or res.foul == "Wrong ball first" or res.foul == Scorer.EIGHT_FOUL
		var insured: bool = perks.has("insurance") and insured_used < 2
		var excused: bool = current().id == "local" and not forgiven and not free_break and not soft and not insured
		if excused:
			forgiven = true
			out["forgiven"] = true
		if not free_break and not soft and insured:
			insured_used += 1
		if not free_break and not soft and not insured and not excused:
			chalk -= 2 if perks.has("glasscannon") else 1
			out.chalk_lost = true
		heat = int(heat / 2.0)   # a miss cools the table but never wipes it out
		element_mix = []
	score = maxi(0, score - int(res.get("penalty", 0)))
	money = maxi(0, money - int(res.get("eight_fine", 0)))
	if current().anomaly == "shrink":
		shrink_steps += 1
		out["layout_changed"] = true
	if score >= target():
		out.cleared = true
		return out
	if chalk <= 0:
		out.over = true
		return out
	if not (res.scored and perks.has("migration")):
		roll_hot_pocket(hot_pocket)
	if balls_left == 0:
		racks_cleared += 1
		chalk += 1
		out.rack_cleared = true
	return out


## ---------------------------------------------------------------- table physics
## Single source of truth for how the current table plays, shared by the game,
## the bots and the tests.
func build_layout() -> TableLayout:
	var layout := TableLayout.new().build(pocket_scale(), closed_pockets())
	if current().lab == "cyclotron":
		layout.add_bumper(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.27), 20.0)
		layout.add_bumper(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.73), 20.0)
	elif current().lab == "pinball":
		for p in [Vector2(390, 125), Vector2(390, 375), Vector2(610, 125), Vector2(610, 375)]:
			layout.add_bumper(p, 18.0)
	return layout


## Applies lab, perk and anomaly physics. Call after the balls are racked.
func apply_physics(s: PoolSim) -> void:
	var t := current()
	# Absolute values, because this also runs mid-table after temporary effects.
	s.roll_decel = 170.0
	s.drag = 0.1
	s.rail_e = 0.8
	s.tilt = Vector2.ZERO
	s.well_strength = 0.0
	s.pocket_pull = 0.0
	s.cue_damp = 1.0
	match t.lab:
		"cryo":
			s.roll_decel = 90.0
			s.drag = 0.05
		"spring":
			s.rail_e = 0.92
		"gravity":
			s.well_pos = Vector2(TableLayout.W * 0.5, TableLayout.H * 0.5)
			s.well_strength = 1.0
		"repulsor":
			s.well_pos = Vector2(TableLayout.W * 0.5, TableLayout.H * 0.5)
			s.well_strength = -1.0
		"current":
			s.tilt = Vector2(70.0, 0.0)
		"magnetlab":
			s.pocket_pull = 1.0
		"dense":
			s.roll_decel = 290.0
			s.drag = 0.17
	if perks.has("velvet"):
		s.roll_decel *= 0.7
		s.drag *= 0.7
	if perks.has("magnet"):
		s.pocket_pull = 1.0
	if perks.has("stun"):
		s.cue_damp = 0.4
	match t.anomaly:
		"blackice":
			s.roll_decel = 45.0
			s.drag = 0.03
			s.rail_e = 0.9
		"tilt":
			s.tilt += Vector2(0, 90.0 if (seed_value + table_index) % 2 == 0 else -90.0)
	for i in s.count():
		var m := 1.0
		if s.num[i] == 0:
			if t.anomaly == "heavycue":
				m = 2.0
		else:
			if t.anomaly == "lead":
				m = 1.6
			if perks.has("featherweight"):
				m *= 0.75
		s.mass[i] = m


## Everything the scorer needs to know about the shot about to be taken.
func shot_ctx(power: float, s: PoolSim, is_break: bool) -> Dictionary:
	var lowest := -1
	var highest := -1
	var on_table: Array = []
	for i in s.count():
		if s.alive[i] == 1 and s.num[i] != 0:
			var n: int = s.num[i]
			on_table.append(n)
			if lowest < 0 or n < lowest:
				lowest = n
			if n > highest:
				highest = n
	var ci := s.index_of(0)
	return {
		"perks": perks, "imbues": imbues, "hot_pocket": hot_pocket, "boss": current().id, "lab": current().lab,
		"anomaly": current().anomaly, "heat": heat, "power": power, "shots_taken": shots_taken,
		"catalyst": catalyst, "is_break": is_break, "chalk": chalk, "objects": s.object_balls_left(),
		"money": money, "empty_slots": MAX_PERKS - perks.size(), "pockets_used": pockets_used,
		"lowest": lowest, "highest": highest, "element_mix": element_mix,
		"target": target(), "on_table": on_table, "total_pots": total_pots,
		"solid_run": solid_run, "stripe_run": stripe_run,
		"cue_start": s.pos[ci] if ci >= 0 else Vector2.ZERO,
	}


## ---------------------------------------------------------------- persistence
## Save format v2. A save records where the player is ("table" mid-play, or
## "shop" between tables) so quitting never costs progress. Writes go to a temp
## file that replaces the save atomically; the previous save is kept as a
## backup and used if the main file is ever unreadable.
const SAVE_PATH := "user://pocket_science_run.json"
const SAVE_VERSION := 4

const BUILD_FAMILIES := ["solid", "stripe", "eight"]
var solid_run := 0            # solids potted in a row on this table
var stripe_run := 0
var phase := "table"            # "table" or "shop"
var table_snapshot := {}        # balls + is_break, supplied by the game controller
var shop_payout: Array = []


func to_dict() -> Dictionary:
	var iso := {}
	for k in imbues:
		iso[str(k)] = imbues[k]
	var d := {
		"v": SAVE_VERSION, "seed": seed_value, "cue": cue, "rng_state": str(rng.state), "table_index": table_index,
		"money": money, "perks": perks, "imbues": iso,
		"catalyst": catalyst, "plan": plan, "endless": endless, "total_pots": total_pots,
		"best_shot": best_shot, "tables_cleared": tables_cleared, "best_heat": best_heat,
		"phase": phase, "carry": carry, "record_id": record_id, "daily_key": daily_key,
		"handicap": handicap, "total_score": total_score,
	}
	if phase == "table":
		d["table"] = {
			"score": score, "chalk": chalk, "heat": heat, "shots_taken": shots_taken,
			"hot_pocket": hot_pocket, "racks_cleared": racks_cleared, "element_mix": element_mix,
			"forgiven": forgiven, "bounty": bounty, "bounty_done": bounty_done,
			"pockets_used": pockets_used, "shrink_steps": shrink_steps, "insured_used": insured_used,
				"solid_run": solid_run, "stripe_run": stripe_run,
			"snapshot": table_snapshot,
		}
	else:
		d["shop"] = {"items": shop, "reroll_cost": reroll_cost, "payout": shop_payout}
	return d


func save() -> void:
	var tmp := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(to_dict()))
	f.close()
	var main_abs := ProjectSettings.globalize_path(SAVE_PATH)
	var bak_abs := ProjectSettings.globalize_path(SAVE_PATH + ".bak")
	if FileAccess.file_exists(SAVE_PATH):
		if FileAccess.file_exists(SAVE_PATH + ".bak"):
			DirAccess.remove_absolute(bak_abs)
		DirAccess.rename_absolute(main_abs, bak_abs)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), main_abs)


static func has_save() -> bool:
	# Only a save this version can load counts, so Continue never appears for a dead save.
	for p in [SAVE_PATH, SAVE_PATH + ".bak"]:
		if FileAccess.file_exists(p):
			var d = _read(p)
			if typeof(d) == TYPE_DICTIONARY and int(d.get("v", 0)) == SAVE_VERSION:
				return true
	return false


static func clear_save() -> void:
	for p in [SAVE_PATH, SAVE_PATH + ".bak", SAVE_PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


## Loads the save, falling back to the backup. Returns false if neither is usable.
func load_save() -> bool:
	for p in [SAVE_PATH, SAVE_PATH + ".bak"]:
		if FileAccess.file_exists(p) and _load_from(p):
			return true
	return false


static func _read(path: String) -> Variant:
	var txt := FileAccess.get_file_as_string(path)
	if txt == "":
		return null
	return JSON.parse_string(txt)


func _load_from(path: String) -> bool:
	var d = _read(path)
	if typeof(d) != TYPE_DICTIONARY:
		return false
	var v := int(d.get("v", 0))
	if v != SAVE_VERSION:   # older saves used retired rules and racks
		return false
	for k in ["seed", "rng_state", "table_index", "money", "perks", "imbues", "plan"]:
		if not d.has(k):
			return false
	if typeof(d.plan) != TYPE_ARRAY or (d.plan as Array).is_empty():
		return false
	seed_value = int(d.seed)
	cue = str(d.get("cue", "maple"))
	if not Catalog.CUES.has(cue):
		cue = "maple"
	rng.seed = seed_value
	rng.state = int(d.rng_state)
	table_index = int(d.table_index)
	money = int(d.money)
	perks.assign((d.perks as Array).filter(func(x): return Catalog.PERKS.has(x)))
	imbues.clear()
	for k in d.imbues:
		if Catalog.IMBUES.has(d.imbues[k]):
			imbues[int(k)] = d.imbues[k]
	catalyst = float(d.get("catalyst", 0.0))
	plan.clear()
	for t in d.plan:
		var td: Dictionary = t
		td.target = int(td.target)
		plan.append(td)
	endless = bool(d.get("endless", false))
	total_pots = int(d.get("total_pots", 0))
	best_shot = int(d.get("best_shot", 0))
	tables_cleared = int(d.get("tables_cleared", 0))
	best_heat = int(d.get("best_heat", 0))
	carry = int(d.get("carry", 0))
	record_id = str(d.get("record_id", ""))
	daily_key = str(d.get("daily_key", ""))
	handicap = int(d.get("handicap", 0))
	total_score = int(d.get("total_score", 0))
	# v1 saves only knew "start of table".
	phase = str(d.get("phase", "table"))
	table_snapshot = {}
	shop_payout = []
	if phase == "table" and d.has("table") and typeof(d.table) == TYPE_DICTIONARY:
		var t: Dictionary = d.table
		begin_table()
		rng.state = int(d.rng_state)   # begin_table consumed rng; restore the saved stream
		score = int(t.get("score", 0))
		chalk = int(t.get("chalk", chalk))
		heat = int(t.get("heat", 0))
		shots_taken = int(t.get("shots_taken", 0))
		hot_pocket = int(t.get("hot_pocket", hot_pocket))
		racks_cleared = int(t.get("racks_cleared", 0))
		element_mix = t.get("element_mix", [])
		forgiven = bool(t.get("forgiven", false))
		var b := str(t.get("bounty", bounty))
		if Catalog.BOUNTIES.has(b):
			bounty = b
		bounty_done = bool(t.get("bounty_done", false))
		pockets_used = (t.get("pockets_used", []) as Array).map(func(x): return int(x))
		shrink_steps = int(t.get("shrink_steps", 0))
		insured_used = int(t.get("insured_used", 0))
		solid_run = int(t.get("solid_run", 0))
		stripe_run = int(t.get("stripe_run", 0))
		if typeof(t.get("snapshot")) == TYPE_DICTIONARY:
			table_snapshot = t.snapshot
	elif phase == "shop" and d.has("shop") and typeof(d.shop) == TYPE_DICTIONARY:
		shop.clear()
		for it in d.shop.get("items", []):
			var item: Dictionary = it
			item.cost = int(item.cost)
			if item.has("ball"):
				item.ball = int(item.ball)
			shop.append(item)
		reroll_cost = int(d.shop.get("reroll_cost", 2))
		shop_payout = d.shop.get("payout", [])
	else:
		phase = "table"
		begin_table()
	return true
