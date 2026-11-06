class_name RunState
extends RefCounted
## Everything that persists across a run: money, formulas, reagents, isotopes,
## the table sequence and the shop.

const MAX_FORMULAS := 5
const MAX_REAGENTS := 2
const BASE_CHALK := 4

var seed_value := 0
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
var forecast := false

# Run stats
var total_pots := 0
var best_shot := 0
var tables_cleared := 0


func start(s: int) -> void:
	seed_value = s
	rng.seed = s
	table_index = 0
	money = 4
	formulas.clear()
	reagents = ["bluechalk"]
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
	chalk = BASE_CHALK + (1 if formulas.has("chalk") else 0)
	if current().anomaly == "dry":
		chalk -= 1
	roll_hot_pocket(-1)


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
	reroll_cost = 2
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
		score += res.total
		streak += 1
		best_streak = maxi(best_streak, streak)
		money += res.money
		catalyst += res.catalyst_gain
		total_pots += res.potted.size()
		best_shot = maxi(best_shot, res.total)
		for n in res.shattered:
			isotopes.erase(n)
	else:
		var free_break: bool = was_break and res.foul == "Miss"
		if not free_break and not formulas.has("insurance"):
			chalk -= 1
			out.chalk_lost = true
		streak = 0
	bluechalk = false
	forecast = false
	if score >= target():
		out.cleared = true
		return out
	if chalk <= 0:
		out.over = true
		return out
	roll_hot_pocket(hot_pocket)
	if balls_left == 0:
		racks_cleared += 1
		chalk += 1
		out.rack_cleared = true
	return out


## ---------------------------------------------------------------- persistence
const SAVE_PATH := "user://pocket_science_run.json"


func to_dict() -> Dictionary:
	var iso := {}
	for k in isotopes:
		iso[str(k)] = isotopes[k]
	return {
		"v": 1, "seed": seed_value, "rng_state": str(rng.state), "table_index": table_index,
		"money": money, "formulas": formulas, "reagents": reagents, "isotopes": iso,
		"catalyst": catalyst, "plan": plan, "endless": endless, "total_pots": total_pots,
		"best_shot": best_shot, "tables_cleared": tables_cleared, "best_streak": best_streak,
	}


func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(to_dict()))


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func load_save() -> bool:
	if not has_save():
		return false
	var txt := FileAccess.get_file_as_string(SAVE_PATH)
	var d = JSON.parse_string(txt)
	if typeof(d) != TYPE_DICTIONARY or int(d.get("v", 0)) != 1:
		return false
	seed_value = int(d.seed)
	rng.seed = seed_value
	rng.state = int(d.rng_state)
	table_index = int(d.table_index)
	money = int(d.money)
	formulas.assign(d.formulas)
	reagents.assign(d.reagents)
	isotopes.clear()
	for k in d.isotopes:
		isotopes[int(k)] = d.isotopes[k]
	catalyst = float(d.catalyst)
	plan.clear()
	for t in d.plan:
		var td: Dictionary = t
		td.target = int(td.target)
		plan.append(td)
	endless = bool(d.endless)
	total_pots = int(d.total_pots)
	best_shot = int(d.best_shot)
	tables_cleared = int(d.tables_cleared)
	best_streak = int(d.get("best_streak", 0))
	return true
