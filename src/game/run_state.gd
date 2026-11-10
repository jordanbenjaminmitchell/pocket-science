class_name RunState
extends RefCounted
## Everything that persists across a run: money, perks, imbues,
## the table sequence and the shop.

const MAX_PERKS := 6
const BASE_CHALK := 6

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
var items: Array[String] = []   # usable items held
var ball_set: Array = []        # the balls this run racks; starts as 1-15
var table_mods := {}            # this table only: placed bumpers and portals, wider pockets
var ball_kinds := {}            # special ball number (16+) -> type
var seed_growth := {}           # Seed balls: times sunk, keyed by number as a string
var removals := 0               # balls removed in the Pro Shop this run
var frost_shield := false       # this table: the next miss keeps Heat
var heart_used := false         # this table: a Heart ball has already given Chalk
var quick_used := false         # this table: Quick Hands has saved an item
var faces := {}                 # Dice and Wild balls: the number each shows
var last_sunk := 0              # Wild copies this
var echo_used := {}             # Echo balls that have already come back this table
var next_boost := 1.0           # Double Down
var next_all_hot := false       # Spotlight
var next_magnet := false        # Magnet Charm
const ITEM_SLOTS := 3
## Items the rules can apply on their own, with no aiming or placing.
const STATE_ITEMS := ["handchalk", "heatpack", "doubledown", "spotlight", "magnetcharm", "wideopen"]

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
	items.assign(c.get("items", []))
	ball_set = range(1, 16).filter(func(n): return not (c.get("remove", []) as Array).has(n))
	ball_kinds = {}
	seed_growth = {}
	removals = 0
	Catalog.kinds = ball_kinds
	for t in c.get("add", []):
		add_special(t)
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
	table_mods = {"bumpers": [], "portals": [], "wide": false}
	frost_shield = false
	heart_used = false
	quick_used = false
	echo_used = {}
	_roll_faces()
	if perks.has("overclock") and items.size() < item_slots():
		items.append("secondstrike")
	next_boost = 1.0
	next_all_hot = false
	next_magnet = false
	roll_hot_pocket(-1)
	var keys := Catalog.BOUNTIES.keys()
	bounty = keys[rng.randi_range(0, keys.size() - 1)]
	while hot_pocket < 0 and (bounty == "hot" or bounty == "hot2"):   # no hot pocket here to aim at
		bounty = keys[rng.randi_range(0, keys.size() - 1)]
	bounty_done = false
	if perks.has("tinkerer") and items.size() < item_slots():
		var ids := Catalog.ITEMS.keys()
		items.append(ids[rng.randi_range(0, ids.size() - 1)])


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
	if table_mods.get("wide", false):
		s *= 1.2
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


## Adds a special ball to the set and returns its number (16 and up).
func add_special(type: String) -> int:
	var num := 16
	while ball_kinds.has(num) or ball_set.has(num):
		num += 1
	ball_kinds[num] = type
	ball_set.append(num)
	Catalog.kinds = ball_kinds
	return num


## Takes a ball out of the set for the rest of the run. Never the 8.
func remove_ball(n: int) -> bool:
	if n == 8 or n == 0 or not ball_set.has(n):
		return false
	ball_set.erase(n)
	imbues.erase(n)
	ball_kinds.erase(n)
	Catalog.kinds = ball_kinds
	return true


## Dice show a fresh number every shot; Wild shows the last ball you sank.
func _roll_faces() -> void:
	faces = {}
	for n in ball_kinds:
		match ball_kinds[n]:
			"dice":
				faces[n] = rng.randi_range(1, 15)
			"wild":
				faces[n] = last_sunk
	Catalog.faces = faces


## Echo: the first time an Echo ball drops on a table it comes back to the foot spot.
func respot_echo(res: Dictionary, s: PoolSim) -> Array:
	var back: Array = []
	for n in res.get("potted", []):
		if Catalog.kind_of(int(n)) != "echo" or echo_used.has(n):
			continue
		var i := s.index_of(int(n))
		if i < 0 or s.alive[i] == 1:
			continue
		var spot := Rack.FOOT
		var tries := 0
		while not s.is_clear_spot(spot, i) and tries < 40:
			spot = Rack.FOOT + Vector2(-TableLayout.R * 2.2 * (tries / 6 + 1), 0).rotated(tries * TAU / 6.0)
			tries += 1
		s.alive[i] = 1
		s.pos[i] = spot
		s.vel[i] = Vector2.ZERO
		echo_used[n] = true
		back.append(n)
	return back


func removal_cost() -> int:
	return 0 if perks.has("cleanhouse") else 3 + removals


## The Pro Shop service: pay to take a ball out of your set.
func buy_removal(n: int) -> String:
	var cost := removal_cost()
	if money < cost:
		return "Not enough money"
	if not remove_ball(n):
		return "That ball can't be removed"
	money -= cost
	removals += 1
	return ""


func _kinds_out() -> Dictionary:
	var o := {}
	for k in ball_kinds:
		o[str(k)] = ball_kinds[k]
	return o


func item_slots() -> int:
	return ITEM_SLOTS + (2 if perks.has("packrat") else 0)


func item_cost(id: String) -> int:
	return maxi(1, int(Catalog.ITEMS[id].cost) - (1 if perks.has("quartermaster") else 0))


func imbue_cost(id: String) -> int:
	return maxi(1, int(Catalog.IMBUES[id].cost) - (2 if perks.has("enchanter") else 0))


## Numbered balls (1-15) no longer in your set.
func removed_count() -> int:
	return range(1, 16).filter(func(n): return not ball_set.has(n)).size()


## How hard a shot hits relative to its power setting.
func power_mult(is_break: bool) -> float:
	var m := 1.15 if perks.has("longarm") else 1.0
	if is_break and perks.has("bigbreak"):
		m *= 1.25
	return m


## Applies an item that needs no aiming or placing. Returns false for the others.
func use_state_item(id: String) -> bool:
	match id:
		"handchalk":
			chalk += 1
		"heatpack":
			heat += 2
			best_heat = maxi(best_heat, heat)
		"doubledown":
			next_boost = 2.0
		"spotlight":
			next_all_hot = true
		"magnetcharm":
			next_magnet = true
		"wideopen":
			table_mods["wide"] = true
		_:
			return false
	return true


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
	if perks.has("alchemy"):
		var plain: Array = ball_set.filter(func(n): return n >= 1 and n <= 15 and n != 8)
		if not plain.is_empty():
			var turned: int = plain[rng.randi_range(0, plain.size() - 1)]
			var types := Catalog.BALL_TYPES.keys()
			var bt: String = types[rng.randi_range(0, types.size() - 1)]
			remove_ball(turned)
			add_special(bt)
			rows.append(["Alchemy: the %d became %s" % [turned, Catalog.BALL_TYPES[bt].name], 0])
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
		shop.append({"type": "imbue", "id": iso, "ball": ball, "cost": imbue_cost(iso), "sold": false})
	if ball_set.size() < Rack.MAX_BALLS:
		var types := Catalog.BALL_TYPES.keys()
		var bt: String = types[rng.randi_range(0, types.size() - 1)]
		shop.append({"type": "ball", "id": bt, "cost": int(Catalog.BALL_TYPES[bt].cost), "sold": false})
	for i in 2:
		var ids := Catalog.ITEMS.keys()
		var it: String = ids[rng.randi_range(0, ids.size() - 1)]
		shop.append({"type": "item", "id": it, "cost": item_cost(it), "sold": false})


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
		"ball":
			if ball_set.size() >= Rack.MAX_BALLS:
				return "Your ball set is full"
			add_special(item.id)
		"item":
			if items.size() >= item_slots():
				return "Item slots full - use one first"
			items.append(item.id)
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
	if res.get("scored", false):
		for n in res.get("potted", []):
			if int(n) >= 1 and int(n) <= 15:
				last_sunk = int(n)
	_roll_faces()
	next_boost = 1.0   # one-shot items are spent whatever happened
	next_all_hot = false
	next_magnet = false
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
		if res.get("frost", false):
			frost_shield = true
		if res.get("heart", false) and not heart_used:
			heart_used = true
			chalk += 1
			out["heart"] = true
		for n in res.get("lost_balls", []):
			remove_ball(int(n))
		for n in res.get("grown", []):
			seed_growth[str(n)] = int(seed_growth.get(str(n), 0)) + 1
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
		if not free_break and not soft and not insured and not excused and not res.get("safe", false):
			chalk -= 2 if perks.has("glasscannon") else 1
			out.chalk_lost = true
		if frost_shield:
			frost_shield = false   # Frost: this miss keeps the Heat
		else:
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
	if int(res.get("new_hot", -1)) >= 0 and hot_pocket >= 0:
		hot_pocket = int(res.new_hot)   # Ember chose it
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
	for bp in table_mods.get("bumpers", []):
		layout.add_bumper(Vector2(bp[0], bp[1]), TableLayout.BUMPER_R)
	for pt in table_mods.get("portals", []):
		layout.portals.append({"a": Vector2(pt[0], pt[1]), "b": Vector2(pt[2], pt[3])})
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
	s.spin_power = 1.5 if perks.has("backspin") else 1.0
	s.side_power = 2.0 if perks.has("masse") else 1.0
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
	if perks.has("slowcloth"):
		s.roll_decel *= 1.3
		s.drag *= 1.3
	if perks.has("liverails"):
		s.rail_e = minf(0.95, s.rail_e * 1.1)
	if next_magnet:
		s.pocket_pull = 1.0
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
			if perks.has("heavyhit"):
				m *= 1.3
		else:
			if t.anomaly == "lead":
				m = 1.6
			if perks.has("featherweight"):
				m *= 0.75
			match Catalog.kind_of(s.num[i]):
				"iron":
					m *= 2.0
				"anchor":
					m *= 3.0
				"feather":
					m *= 0.25
			match imbues.get(s.num[i], ""):
				"hollow":
					m *= 0.5
				"leaded":
					m *= 2.0
		if i < s.pull.size():
			s.pull[i] = 1.0 if imbues.get(s.num[i], "") == "magnetic" else 0.0
			s.bounce[i] = 1.0 if Catalog.kind_of(s.num[i]) == "star" else 0.0
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
			if n <= 15 and (lowest < 0 or n < lowest):
				lowest = n
			if n > highest and n <= 15:
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
		"boost": next_boost, "all_hot": next_all_hot, "removed": removed_count(),
		"specials": ball_kinds.size(), "seed_growth": seed_growth,
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
		"handicap": handicap, "total_score": total_score, "items": items, "ball_set": ball_set,
		"ball_kinds": _kinds_out(), "seed_growth": seed_growth, "removals": removals,
	}
	if phase == "table":
		d["table"] = {
			"score": score, "chalk": chalk, "heat": heat, "shots_taken": shots_taken,
			"hot_pocket": hot_pocket, "racks_cleared": racks_cleared, "element_mix": element_mix,
			"forgiven": forgiven, "bounty": bounty, "bounty_done": bounty_done,
			"pockets_used": pockets_used, "shrink_steps": shrink_steps, "insured_used": insured_used,
				"solid_run": solid_run, "stripe_run": stripe_run, "mods": table_mods,
				"frost": frost_shield, "heart_used": heart_used,
				"boost": next_boost, "all_hot": next_all_hot, "magnet": next_magnet,
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
	items.assign((d.get("items", []) as Array).filter(func(x): return Catalog.ITEMS.has(x)))
	ball_set = (d.get("ball_set", range(1, 16)) as Array).map(func(x): return int(x))
	ball_kinds = {}
	var bk = d.get("ball_kinds", {})
	if typeof(bk) == TYPE_DICTIONARY:
		for k in bk:
			if Catalog.BALL_TYPES.has(bk[k]):
				ball_kinds[int(k)] = bk[k]
	Catalog.kinds = ball_kinds
	seed_growth = d.get("seed_growth", {}) if typeof(d.get("seed_growth", {})) == TYPE_DICTIONARY else {}
	removals = int(d.get("removals", 0))
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
		if typeof(t.get("mods")) == TYPE_DICTIONARY:
			table_mods = t.mods
		next_boost = float(t.get("boost", 1.0))
		next_all_hot = bool(t.get("all_hot", false))
		next_magnet = bool(t.get("magnet", false))
		frost_shield = bool(t.get("frost", false))
		heart_used = bool(t.get("heart_used", false))
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
