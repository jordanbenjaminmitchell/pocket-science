class_name RunState
extends RefCounted
## Everything that persists across a run: money, formulas, reagents, isotopes,
## the table sequence and the shop.

const MAX_FORMULAS := 5
const MAX_REAGENTS := 2
const BASE_CHALK := 5

var seed_value := 0
var cue := "maple"
var rng := RandomNumberGenerator.new()
var table_index := 0
var money := 4
var formulas: Array[String] = []
var reagents: Array[String] = []
var isotopes := {}         # ball number -> isotope id
var catalyst := 0.0
var plan: Array[Dictionary] = []   # one entry per table: {target, rack, boss, lab, anomaly}
var shop: Array[Dictionary] = []
var reroll_cost := 2
var endless := false

# Per-table state
var score := 0
var chalk := 3
var streak := 0
var best_streak := 0
var shots_taken := 0
var hot_pocket := 0
var racks_cleared := 0
var bluechalk := false
var bounty := ""
var bounty_done := false
var forecast := false
var pockets_used: Array = []
var shrink_steps := 0
var insured_used := 0

# Run stats
var total_pots := 0
var best_shot := 0
var tables_cleared := 0


func start(s: int, cue_id: String = "maple") -> void:
	seed_value = s
	rng.seed = s
	cue = cue_id
	var c: Dictionary = Catalog.CUES.get(cue, Catalog.CUES.maple)
	table_index = 0
	money = c.money
	formulas.clear()
	formulas.assign(c.formulas)
	reagents.assign(c.reagents)
	isotopes.clear()
	catalyst = 0.0
	total_pots = 0
	best_shot = 0
	tables_cleared = 0
	endless = false
	_build_plan()


func _build_plan() -> void:
	plan.clear()
	var labs := ["standard", "cryo", "cyclotron", "spring", "gravity"]
	var bosses := Catalog.ANOMALIES.keys()
	for i in range(bosses.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = bosses[i]
		bosses[i] = bosses[j]
		bosses[j] = tmp
	var b := 0
	for i in Catalog.TABLES.size():
		var t: Dictionary = Catalog.TABLES[i].duplicate()
		if i == 0:
			t.lab = "standard"
		else:
			t.lab = labs[rng.randi_range(0, labs.size() - 1)]
		if t.get("boss", false):
			t.anomaly = bosses[b % bosses.size()]
			b += 1
		else:
			t.anomaly = ""
		plan.append(t)


func current() -> Dictionary:
	if table_index < plan.size():
		return plan[table_index]
	# Endless: keep scaling.
	var extra := table_index - plan.size() + 1
	var labs := ["standard", "cryo", "cyclotron", "spring", "gravity"]
	var bosses := Catalog.ANOMALIES.keys()
	return {
		"target": int(4500 * pow(1.6, extra)), "rack": "fifteen",
		"boss": extra % 3 == 0, "lab": labs[extra % labs.size()],
		"anomaly": bosses[extra % bosses.size()] if extra % 3 == 0 else "",
	}


func begin_table() -> void:
	score = 0
	streak = 0
	shots_taken = 0
	racks_cleared = 0
	bluechalk = false
	forecast = false
	chalk = max_chalk()
	pockets_used = []
	shrink_steps = 0
	insured_used = 0
	roll_hot_pocket(-1)
	var keys := Catalog.BOUNTIES.keys()
	bounty = keys[rng.randi_range(0, keys.size() - 1)]
	bounty_done = false


func max_chalk() -> int:
	var c := BASE_CHALK + (1 if formulas.has("chalk") else 0)
	c += int(Catalog.CUES.get(cue, Catalog.CUES.maple).chalk)
	if current().anomaly == "dry":
		c -= 1
	return maxi(c, 1)


func bounty_met(res: Dictionary, hot: int) -> bool:
	var labels: Array = res.lines.map(func(l): return l.label)
	match bounty:
		"bank":
			return labels.any(func(l): return l.begins_with("Bank"))
		"combo":
			return labels.has("Combination")
		"double":
			return res.potted.size() >= 2
		"triple":
			return res.potted.size() >= 3
		"kick":
			return labels.has("Kick shot")
		"hot":
			return labels.has("Hot pocket")
		"streak4":
			return streak + 1 >= 4
		"big":
			return res.total >= 150
		"side":
			return res.lines.any(func(l): return l.pocket == 1 or l.pocket == 4)
		"eight":
			return res.potted.has(8)
	return false


func roll_hot_pocket(avoid: int) -> void:
	if current().anomaly == "cold":
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
	return current().target


func pocket_scale() -> float:
	var s := 1.08
	if formulas.has("jaws"):
		s *= 1.12
	if current().anomaly == "tight":
		s *= 0.85
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
	return Catalog.LABS[t.lab].name


## Called after a table is cleared. Returns a breakdown of the payout.
func payout() -> Array:
	var rows: Array = []
	var base := 3 + (2 if current().get("boss", false) else 0)
	rows.append(["Table cleared", base])
	if chalk > 0:
		rows.append(["Unused chalk ×%d" % chalk, chalk])
	if formulas.has("interest"):
		var i := mini(money / 5, 5)
		if i > 0:
			rows.append(["Compound interest", i])
	if formulas.has("thrift") and chalk >= 2:
		rows.append(["Thrift", 3])
	if formulas.has("overflow") and target() > 0:
		var over := int(floor((score - target()) / (target() * 0.2)))
		if over > 0:
			rows.append(["Overflow", mini(over, 6)])
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
func roll_shop() -> void:
	reroll_cost = 1 if formulas.has("coupon") else 2
	shop.clear()
	for i in 3:
		var f := _random_formula()
		if f != "":
			shop.append({"type": "formula", "id": f, "cost": Catalog.FORMULAS[f].cost, "sold": false})
	for i in 2:
		if rng.randf() < 0.55:
			var keys := Catalog.REAGENTS.keys()
			var r: String = keys[rng.randi_range(0, keys.size() - 1)]
			shop.append({"type": "reagent", "id": r, "cost": Catalog.REAGENTS[r].cost, "sold": false})
		else:
			var keys := Catalog.ISOTOPES.keys()
			var iso: String = keys[rng.randi_range(0, keys.size() - 1)]
			var ball := rng.randi_range(1, 15)
			if current_rack_max() < 15:
				ball = rng.randi_range(1, current_rack_max())
			shop.append({"type": "isotope", "id": iso, "ball": ball, "cost": Catalog.ISOTOPES[iso].cost, "sold": false})


func current_rack_max() -> int:
	var nxt := table_index + 1
	var rack: String = plan[mini(nxt, plan.size() - 1)].rack
	return {"six": 6, "nine": 9, "ten": 10}.get(rack, 15)


func _random_formula() -> String:
	var pool: Array = []
	for id in Catalog.FORMULAS:
		if formulas.has(id):
			continue
		var already := false
		for s in shop:
			if s.type == "formula" and s.id == id:
				already = true
		if already:
			continue
		var r: int = Catalog.FORMULAS[id].r
		var w: int = [10, 5, 2][r]
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
		if s.type != "formula":
			kept.append(s)
	shop = kept
	for i in 3:
		var f := _random_formula()
		if f != "":
			var item := {"type": "formula", "id": f, "cost": Catalog.FORMULAS[f].cost, "sold": false}
			shop.append(item)
	# Formulas first in display order.
	shop.sort_custom(func(a, b): return (a.type == "formula") and not (b.type == "formula"))
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
		"formula":
			if formulas.size() >= MAX_FORMULAS:
				return "Formula slots full - sell one first"
			formulas.append(item.id)
		"reagent":
			if reagents.size() >= MAX_REAGENTS:
				return "Reagent slots full"
			reagents.append(item.id)
		"isotope":
			isotopes[item.ball] = item.id
	money -= item.cost
	item.sold = true
	return ""


func sell_formula(i: int) -> int:
	if i < 0 or i >= formulas.size():
		return 0
	var id := formulas[i]
	var v := maxi(1, int(Catalog.FORMULAS[id].cost / 2))
	formulas.remove_at(i)
	money += v
	return v


func sell_value(id: String) -> int:
	return maxi(1, int(Catalog.FORMULAS[id].cost / 2))


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
			money += int(Catalog.BOUNTIES[bounty].reward) * (2 if formulas.has("hunter") else 1)
			out["bounty"] = bounty
		score += res.total
		streak += 1
		best_streak = maxi(best_streak, streak)
		money += res.money
		catalyst += res.catalyst_gain
		total_pots += res.potted.size()
		best_shot = maxi(best_shot, res.total)
		for n in res.shattered:
			isotopes.erase(n)
		for k in res.get("pocket_list", []):
			if not pockets_used.has(k):
				pockets_used.append(k)
	else:
		var free_break: bool = was_break and res.foul == "Miss"
		var soft: bool = res.foul == "Wrong pocket"   # One Pocket: scores nothing but costs no chalk
		var insured: bool = formulas.has("insurance") and insured_used < 2
		if insured and not free_break and not soft:
			insured_used += 1
		if not free_break and not soft and not insured:
			chalk -= 2 if formulas.has("glasscannon") else 1
			out.chalk_lost = true
		streak = 0
	if current().anomaly == "shrink":
		shrink_steps += 1
		out["layout_changed"] = true
	bluechalk = false
	forecast = false
	if score >= target():
		out.cleared = true
		return out
	if chalk <= 0:
		out.over = true
		return out
	if not (res.scored and formulas.has("migration")):
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
	return layout


## Applies lab, formula and anomaly physics. Call after the balls are racked.
func apply_physics(s: PoolSim) -> void:
	var t := current()
	match t.lab:
		"cryo":
			s.roll_decel = 90.0
			s.drag = 0.05
		"spring":
			s.rail_e = 0.92
		"gravity":
			s.well_pos = Vector2(TableLayout.W * 0.5, TableLayout.H * 0.5)
			s.well_strength = 1.0
	if formulas.has("velvet"):
		s.roll_decel *= 0.7
		s.drag *= 0.7
	if formulas.has("magnet"):
		s.pocket_pull = 1.0
	if formulas.has("stun"):
		s.cue_damp = 0.4
	match t.anomaly:
		"blackice":
			s.roll_decel = 45.0
			s.drag = 0.03
			s.rail_e = 0.9
		"tilt":
			s.tilt = Vector2(0, 55.0 if (seed_value + table_index) % 2 == 0 else -55.0)
	for i in s.count():
		var m := 1.0
		if s.num[i] == 0:
			if t.anomaly == "heavycue":
				m = 1.6
		else:
			if t.anomaly == "lead":
				m = 1.6
			if formulas.has("featherweight"):
				m *= 0.75
		s.mass[i] = m


## Everything the scorer needs to know about the shot about to be taken.
func shot_ctx(power: float, s: PoolSim, is_break: bool) -> Dictionary:
	var lowest := -1
	var highest := -1
	for i in s.count():
		if s.alive[i] == 1 and s.num[i] != 0:
			var n: int = s.num[i]
			if lowest < 0 or n < lowest:
				lowest = n
			if n > highest:
				highest = n
	var ci := s.index_of(0)
	return {
		"formulas": formulas, "isotopes": isotopes, "hot_pocket": hot_pocket, "lab": current().lab,
		"anomaly": current().anomaly, "streak": streak, "power": power, "shots_taken": shots_taken,
		"catalyst": catalyst, "bluechalk": bluechalk, "is_break": is_break, "chalk": chalk,
		"money": money, "empty_slots": MAX_FORMULAS - formulas.size(), "pockets_used": pockets_used,
		"lowest": lowest, "highest": highest,
		"cue_start": s.pos[ci] if ci >= 0 else Vector2.ZERO,
	}


## ---------------------------------------------------------------- persistence
## Save format v2. A save records where the player is ("table" mid-play, or
## "shop" between tables) so quitting never costs progress. Writes go to a temp
## file that replaces the save atomically; the previous save is kept as a
## backup and used if the main file is ever unreadable.
const SAVE_PATH := "user://pocket_science_run.json"
const SAVE_VERSION := 2

var phase := "table"            # "table" or "shop"
var table_snapshot := {}        # balls + is_break, supplied by the game controller
var shop_payout: Array = []


func to_dict() -> Dictionary:
	var iso := {}
	for k in isotopes:
		iso[str(k)] = isotopes[k]
	var d := {
		"v": SAVE_VERSION, "seed": seed_value, "cue": cue, "rng_state": str(rng.state), "table_index": table_index,
		"money": money, "formulas": formulas, "reagents": reagents, "isotopes": iso,
		"catalyst": catalyst, "plan": plan, "endless": endless, "total_pots": total_pots,
		"best_shot": best_shot, "tables_cleared": tables_cleared, "best_streak": best_streak,
		"phase": phase,
	}
	if phase == "table":
		d["table"] = {
			"score": score, "chalk": chalk, "streak": streak, "shots_taken": shots_taken,
			"hot_pocket": hot_pocket, "racks_cleared": racks_cleared, "bluechalk": bluechalk,
			"forecast": forecast, "bounty": bounty, "bounty_done": bounty_done,
			"pockets_used": pockets_used, "shrink_steps": shrink_steps, "insured_used": insured_used,
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
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_PATH + ".bak")


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
	if v < 1 or v > SAVE_VERSION:
		return false
	for k in ["seed", "rng_state", "table_index", "money", "formulas", "reagents", "isotopes", "plan"]:
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
	formulas.assign((d.formulas as Array).filter(func(x): return Catalog.FORMULAS.has(x)))
	reagents.assign((d.reagents as Array).filter(func(x): return Catalog.REAGENTS.has(x)))
	isotopes.clear()
	for k in d.isotopes:
		if Catalog.ISOTOPES.has(d.isotopes[k]):
			isotopes[int(k)] = d.isotopes[k]
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
	best_streak = int(d.get("best_streak", 0))
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
		streak = int(t.get("streak", 0))
		shots_taken = int(t.get("shots_taken", 0))
		hot_pocket = int(t.get("hot_pocket", hot_pocket))
		racks_cleared = int(t.get("racks_cleared", 0))
		bluechalk = bool(t.get("bluechalk", false))
		forecast = bool(t.get("forecast", false))
		var b := str(t.get("bounty", bounty))
		if Catalog.BOUNTIES.has(b):
			bounty = b
		bounty_done = bool(t.get("bounty_done", false))
		pockets_used = (t.get("pockets_used", []) as Array).map(func(x): return int(x))
		shrink_steps = int(t.get("shrink_steps", 0))
		insured_used = int(t.get("insured_used", 0))
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
