class_name RunState
extends RefCounted
## Everything that persists across a run: money, perks, imbues,
## the table sequence and the shop.

const MAX_PERKS := 6
const BOULDER_R := 26.5   # the biggest cue ball that still drops through a pocket mouth
const BASE_CHALK := 6
## Chalk now travels with you from table to table: you start with BASE_CHALK,
## each cleared table adds one, and you can never hold more than MAX_CHALK.
const MAX_CHALK := 12

var seed_value := 0
var cue := "maple"
var rng := RandomNumberGenerator.new()
var table_index := 0
## Elements the player has switched off: they stay owned but do nothing until
## switched back on (useful for once-per-table cards).
var perks_off: Array = []
## Beryllium Avalanche: extra points per ball number for the rest of the run.
var ball_bonus := {}
## Once-per-table Elements already spent this table (id -> true).
var perk_used := {}
## Catalysts spent since the last shot (Sulfur Reagent).
var items_this_shot := 0
var beacon_used := false        # Americium Beacon: spent this table
var beacon_shot := false        # ... and this shot gets its bonus
var temp_tools: Array = []      # Tellurium Supply: Catalysts that leave when the table ends
var echo_imbues := {}           # Europium Echo: ball -> Isotope, until the table ends
var echo_pending: Array = []    # Isotopes that sank this shot, waiting to echo (ball numbers)
var recur_pending: Array = []   # Recurring balls that sank this shot, waiting to come back
var prime_spawned: Array = []   # Promethium Prime: primes brought on this table
var temp_numerals: Array = []   # big-number balls that are on the table for this table only
var fib_done: Array = []        # Fermium Spiral: Fibonacci numbers sunk since the last reward
var numerals := {}              # ball number -> the number it shows (big plain balls past 15)
var twin_spawned := false       # Ytterbium Twin: the second cue ball is out this table
var chalked_used := false       # Chalked Isotope: its Chalk this table is spent
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
var bet_cap := 0   # this table's stake, capped at what you could afford when it was dealt (0: not capped)
var bet_state := "offer"         # offer, taken, passed, won (the stake is lost if a taken bet is never won)
var bet_peeked := false
var element_mix: Array = []   # (old Element Table; kept so old saves load)
var clock_pos := 0            # Clockwork Table: which pocket is next (index into CLOCK_ORDER)
var clock_streak := 0         # Clockwork Table: ticks in a row
var forgiven := false         # The Local: the free miss has been used
var pockets_used: Array = []
var last_pocket := -1           # the pocket of your last sink (Helium Fusion)
var shrink_steps := 0
var flash_used := false   # Xenon Flash: used on this table
var insured_used := 0
var carry := 0           # Overflow: score carried into the next table
var items: Array[String] = []   # consumables held
var tools: Array[String] = []   # tools held all run
var tool_charges := {}          # this table: charges left per tool
var called := {}                # Called Shot for the next shot: {ball, pocket}
var last_chalk_lost := false    # the last shot cost Chalk (Insurance Slip)
var ball_set: Array = []        # the balls this run racks; starts as 1-15
var table_mods := {}            # this table only: placed bumpers and portals, wider pockets
var board := {}                 # this table's Sharks and moving parts (BoardFeatures)
var ball_kinds := {}            # Exotic ball number (16+) -> type
var seed_growth := {}           # Seed balls: times sunk, keyed by number as a string
var lucky_mult := {}            # Lucky Imbue: ball number -> what its next win pays (2, 3, 4...)
var imbue_level := {}           # Weighted level, Hairline cracks, Gilded streak: ball number -> count
var gilded_this_table := {}     # Gilded balls sunk on this table
var removals := 0               # balls removed in the Pro Shop this run
var removed_total := 0          # every ball that has left your set (Thin Rack, Missing Piece)
var frost_shield := false       # this table: the next miss keeps Heat
var heart_used := false         # this table: a Heart ball has already given Chalk
var quick_used := false         # this table: Quick Hands has saved an item
var faces := {}                 # Dice and Wild balls: the number each shows
var last_sunk := 0              # Wild copies this
var echo_used := {}             # Echo balls that have already come back this table
var intro := false              # a new player: items from the 2nd shop, Exotic balls from the 3rd
var next_boost := 1.0           # Double Down
var next_all_hot := false       # Spotlight
var next_magnet := false        # Magnet Charm
const ITEM_SLOTS := 0            # consumables
const PAR_SHOTS := 10
## A set never holds more than 15 balls: a new Exotic ball takes the place of one
## you choose, so every slot is a trade between a cheap ball and a better one.
const MAX_SET := 15
const START_BALLS := 10
const CUE_KIT_USES := 4
const QUICK_MAX := 5
const OVERKILL_MAX := 10
const TOOL_SLOTS := 5
## Items the rules can apply on their own, with no aiming or placing.
const STATE_ITEMS := ["slip"]

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
	tools.assign(c.get("tools", []))
	# A run starts with ten balls, 1 to 10 (one triangle); 11 to 15 come from the Pro Shop.
	ball_set = range(1, START_BALLS + 1).filter(func(n): return not (c.get("remove", []) as Array).has(n))
	removed_total = 0   # balls a cue starts without do not count as removed
	ball_kinds = {}
	seed_growth = {}
	lucky_mult = {}
	imbue_level = {}
	gilded_this_table = {}
	removals = 0
	Catalog.kinds = ball_kinds
	for t in c.get("add", []):
		add_special(t)
	# A cue that starts with an Exotic ball gives up the lowest plain ball for it.
	while ball_set.size() > MAX_SET:
		var low: Array = ball_set.filter(func(n): return n >= 1 and n <= 15 and n != 8)
		low.sort()
		remove_ball(low[0])
	imbues.clear()
	for pair: Array in c.get("imbue", []):
		if ball_set.has(int(pair[0])):
			imbues[int(pair[0])] = String(pair[1])   # the cue's own Isotope
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
	for n in imbues:
		if imbues[n] == "gold" and not gilded_this_table.has(n) and table_index > 0:
			imbue_level.erase(n)
	gilded_this_table = {}
	score = carry
	carry = 0
	heat = 0
	shots_taken = 0
	racks_cleared = 0
	element_mix = []
	clock_pos = 0
	clock_streak = 0
	forgiven = false
	if table_index == 0:
		chalk = start_chalk()   # Chalk carries over; only a new run starts fresh
	pockets_used = []
	perk_used = {}
	beacon_used = false
	beacon_shot = false
	twin_spawned = false
	_end_table_extras()
	_table_start_extras()
	shrink_steps = 0
	insured_used = 0
	flash_used = false
	solid_run = 0
	stripe_run = 0
	table_mods = {"bumpers": [], "portals": [], "covered": []}
	board = {}   # set once the hot pocket is known, below
	frost_shield = false
	heart_used = false
	quick_used = false
	echo_used = {}
	_roll_faces()
	called = {}
	last_chalk_lost = false
	tool_charges = {}
	for t in tools:
		tool_charges[t] = 2 if has_perk("overclock") else 1
	if cue_kit() != "":
		tool_charges[cue_kit()] = CUE_KIT_USES   # the cue's own object, 4 uses every table
	next_boost = 1.0
	next_all_hot = false
	next_magnet = false
	roll_hot_pocket(-1)
	if BoardFeatures.has_features(String(current().id)):
		var brng := RandomNumberGenerator.new()
		brng.seed = seed_value * 7 + table_index * 131 + 11
		board = BoardFeatures.start(String(current().id), brng, hot_pocket)
	var keys := Catalog.BOUNTIES.keys()
	bounty = keys[rng.randi_range(0, keys.size() - 1)]
	while hot_pocket < 0 and (bounty == "hot" or bounty == "hot2"):   # no hot pocket here to aim at
		bounty = keys[rng.randi_range(0, keys.size() - 1)]
	bounty_done = false
	# Never deal a bet you can't afford: the stake is capped at your money, and
	# with less than the smallest stake ($2) there is no side bet this table.
	var full_stake := int(Catalog.BET_STAKES[mini(table_index, Catalog.BET_STAKES.size() - 1)])
	bet_cap = mini(full_stake, money)
	if bet_cap < MIN_BET:
		bounty = ""   # bet_open() is false with no bounty
	bet_state = "offer"
	bet_peeked = false
	if has_perk("tinkerer") and not tools.is_empty():
		var lucky: String = tools[rng.randi_range(0, tools.size() - 1)]
		tool_charges[lucky] = int(tool_charges.get(lucky, 0)) + 1   # one extra use this table


## The most Chalk you can hold.
func max_chalk() -> int:
	return MAX_CHALK


## What a new run starts with: 6, less one for some cues and for the Short Chalk handicap.
func start_chalk() -> int:
	var c := BASE_CHALK + int(Catalog.CUES.get(cue, Catalog.CUES.maple).chalk)
	if handicap >= 2:
		c -= 1
		return maxi(c, 2)
	return maxi(c, 1)


const MIN_BET := 2


func bet_stake() -> int:
	var full := int(Catalog.BET_STAKES[mini(table_index, Catalog.BET_STAKES.size() - 1)])
	return mini(full, bet_cap) if bet_cap > 0 else full


## Winnings as a multiple of the stake: 1x/2x/3x by tier, +0.5x every three tables.
func bet_multiple() -> float:
	var tier := int(Catalog.BOUNTIES[bounty].tier)
	return 1.0 + tier + 0.5 * mini(int(table_index / 3), 2)


## What a winning bet pays back: the stake plus its winnings (doubled by Side Hustle).
func bounty_reward() -> int:
	var win := int(round(bet_stake() * bet_multiple()))
	return bet_stake() + win * (2 if has_perk("hunter") else 1)


func bet_open() -> bool:
	return bounty != "" and bet_state == "offer" and shots_taken == 0


func peek_bet() -> bool:
	if not bet_open() or bet_peeked or money < bet_stake() / 2:
		return false
	money -= bet_stake() / 2
	bet_peeked = true
	return true


func take_bet() -> bool:
	if not bet_open() or money < bet_stake():
		return false
	money -= bet_stake()
	bet_state = "taken"
	return true


func pass_bet() -> void:
	if bet_state == "offer":
		bet_state = "passed"


func bounty_met(res: Dictionary, _hot: int) -> bool:
	var pots: Array = res.potted
	var heat_after: int = heat + 1 + int(res.get("heat_gain", 0))
	match bounty:
		"bank":
			return int(res.get("banks", 0)) > 0
		"bank2":
			return int(res.get("max_rails", 0)) >= 2
		"combo":
			return int(res.get("combos", 0)) > 0
		"kick":
			return res.get("kick", false)
		"hot":
			return int(res.get("hot_pots", 0)) > 0
		"hot2":
			return int(res.get("hot_pots", 0)) >= 2
		"double":
			return pots.size() >= 2
		"triple":
			return pots.size() >= 3
		"heat3":
			return heat_after >= 3
		"heat4":
			return heat_after >= 4
		"heat5":
			return heat_after >= 5
		"corner":
			return (res.get("pocket_list", []) as Array).any(func(k): return k in [0, 2, 3, 5])
		"side":
			return (res.get("pocket_list", []) as Array).any(func(k): return k == 1 or k == 4)
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
			return float(res.get("chain", 1.0)) >= 5.0
		"chain7":
			return float(res.get("chain", 1.0)) >= 7.0
		"chain10":
			return float(res.get("chain", 1.0)) >= 10.0
		"clean":
			return int(res.get("cleans", 0)) > 0
		"topthree":
			return pots.any(func(n): return n >= 13 and n <= 15)
		"mixed":
			return pots.any(func(n): return n >= 1 and n <= 7) and pots.any(func(n): return n >= 9 and n <= 15)
		"twopockets":
			var ks := {}
			for k in res.get("pocket_list", []):
				ks[k] = true
			return ks.size() >= 2
		"bank3":
			return int(res.get("max_rails", 0)) >= 3
		"money5":
			return int(res.get("money", 0)) >= 5
		"quarter":
			return res.get("total", 0) >= target() * 0.25
		"half":
			return res.get("total", 0) >= target() * 0.5
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
		if has_perk("side") and (k == 1 or k == 4):
			continue   # Strontium Firework: never a side pocket
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
	if has_perk("jaws"):
		s *= 1.2
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
	for k in BoardFeatures.closed(board):
		if not c.has(k):
			c.append(k)
	return c


func table_name() -> String:
	var t := current()
	return Catalog.BOSSES[t.id].name


## Adds an Exotic ball to the set and returns its number (16 and up).
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
	removed_total += 1
	imbues.erase(n)
	imbue_level.erase(n)
	lucky_mult.erase(n)
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
			"numeral":
				faces[n] = int(numerals.get(n, n))
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


## Balls a loose Imbue can go on: in the set, not yet imbued, never the 8.
func imbue_targets() -> Array:
	return ball_set.filter(func(n): return n != 8 and not imbues.has(n))


## Buys a loose Imbue for the ball you chose.
func buy_imbue(i: int, n: int) -> String:
	var item: Dictionary = shop[i]
	if item.sold:
		return "Sold out"
	if money < item.cost:
		return "Not enough money"
	if not imbue_targets().has(n):
		return "That ball can't take an Isotope"
	imbues[n] = item.id
	money -= item.cost
	item.sold = true
	return ""


## Moves an Imbue from one ball to another, with its level, if the target is free.
func _move_imbue(from: int, to: int) -> bool:
	if to == from or to == 8 or not ball_set.has(to) or imbues.has(to) or not imbues.has(from):
		return false
	imbues[to] = imbues[from]
	imbues.erase(from)
	if imbue_level.has(from):
		imbue_level[to] = imbue_level[from]
		imbue_level.erase(from)
	return true


## After a scoring shot: Weighted and Hairline climb, Gilded keeps its streak,
## Spark arcs, Vein spreads and Twin hops. Returns lines for the table.
func _imbues_after(res: Dictionary) -> Array:
	var said: Array = []
	for n in res.get("weighted_sunk", []):
		imbue_level[n] = mini(int(imbue_level.get(n, 3)) + 1, 8)
		said.append("Weighted %d-ball: number now counts ×%d" % [n, imbue_level[n]])
	for n in res.get("hairline_sunk", []):
		imbue_level[n] = mini(int(imbue_level.get(n, 0)) + 1, 3)
	for n in res.get("gilded_sunk", []):
		imbue_level[n] = mini(int(imbue_level.get(n, 0)) + 1, 4)
		gilded_this_table[n] = true
	for j in res.get("spark_jumps", []):
		if _move_imbue(int(j[0]), int(j[1])):
			said.append("Spark overloaded: it arced to the %d-ball" % int(j[1]))
	for to in res.get("vein_spread", []):
		if int(to) != 8 and ball_set.has(int(to)) and not imbues.has(int(to)):
			imbues[int(to)] = "vein"
			said.append("Vein spread to the %d-ball" % int(to))
	for n in res.get("twin_hops", []):
		var pair := int(n) + 8 if int(n) < 8 else int(n) - 8
		if int(n) <= 15 and _move_imbue(int(n), pair):
			said.append("Twin hopped to the %d-ball" % pair)
	return said


## Lucky: a win resets it to ×2 on its ball. A miss sends it to a random ball with
## no Imbue, one step richer (×3, ×4...); with nowhere to go it climbs where it is.
## Returns [[from, to, mult], ...] for the shot log.
func _move_lucky(res: Dictionary) -> Array:
	var moves: Array = []
	for n in res.get("lucky_hits", []):
		lucky_mult.erase(int(n))
	for n in res.get("lucky_misses", []):
		var m := int(lucky_mult.get(int(n), 2)) + 1
		lucky_mult.erase(int(n))
		var free: Array = ball_set.filter(func(b): return b != 8 and b != int(n) and not imbues.has(b))
		var to := int(n)
		if not free.is_empty():
			to = free[rng.randi_range(0, free.size() - 1)]
			imbues.erase(int(n))
			imbues[to] = "lucky"
		lucky_mult[to] = m
		moves.append([int(n), to, m])
	return moves


func _keys_out(dct: Dictionary) -> Dictionary:
	var o := {}
	for k in dct:
		o[str(k)] = dct[k]
	return o


func set_full() -> bool:
	return ball_set.size() >= MAX_SET


## Balls a new Exotic ball may replace: anything but the 8.
func replace_targets() -> Array:
	return ball_set.filter(func(n): return n != 8)


## Adds a numbered ball (11 to 15) to your set with an Imbue already on it.
func _add_numbered(n: int, iso: String) -> void:
	if not ball_set.has(n):
		ball_set.append(n)
		ball_set.sort()
	imbues[n] = iso


## Shop entries that put a new ball in your set: Exotic balls, and balls 11 to 15.
func adds_ball(i: int) -> bool:
	return shop[i].type == "ball" or bool(shop[i].get("adds", false))


## What a new ball costs right now: its price, plus the removal fee for the
## ball it pushes out when the set is already full.
func special_cost(i: int) -> int:
	return int(shop[i].cost) + (removal_cost() if set_full() else 0)


## Buys an Exotic ball. With a full set you also pay to remove ball `replace`
## (it leaves with any Imbue on it, and counts as a removal); with room it just joins.
func buy_special(i: int, replace: int = -1) -> String:
	var item: Dictionary = shop[i]
	if item.sold:
		return "Sold out"
	if money < special_cost(i):
		return "Not enough money"
	if set_full():
		if not replace_targets().has(replace):
			return "Choose a ball for it to replace"
		var err := buy_removal(replace)
		if err != "":
			return err
	if item.type == "ball":
		add_special(item.id)
	else:
		_add_numbered(int(item.ball), item.id)
	money -= item.cost
	item.sold = true
	return ""


func removal_cost() -> int:
	return 0 if has_perk("cleanhouse") else 3 + removals


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
	return ITEM_SLOTS + (1 if has_perk("packrat") else 0)


func tool_slots() -> int:
	return TOOL_SLOTS + (3 if has_perk("packrat") else 0) + int(cue_rule("slots", 0))


func consumable_ids() -> Array:
	return Catalog.ITEMS.keys().filter(func(k): return Catalog.ITEMS[k].kind == "consumable")


## Tools spend a charge, consumables leave the bag (Quick Hands may save one).
## Returns false if there was nothing to spend.
func spend(id: String) -> bool:
	items_this_shot += 1
	if has_perk("afterimage") and not beacon_used:
		beacon_used = true   # Americium Beacon: the first Catalyst each table
		beacon_shot = true
	if has_perk("quickhands") and not quick_used and (tools.has(id) or id == cue_kit()) and int(tool_charges.get(id, 0)) > 0:
		quick_used = true   # Quick Hands: the first Catalyst each table is free
		return true
	if id == cue_kit() and int(tool_charges.get(id, 0)) > 0:
		tool_charges[id] = int(tool_charges[id]) - 1
		return true
	if Catalog.ITEMS[id].kind == "tool":
		if int(tool_charges.get(id, 0)) <= 0:
			return false
		tool_charges[id] = int(tool_charges[id]) - 1
		return true
	if not items.has(id):
		return false
	if Catalog.ITEMS[id].when == "pause" and has_perk("quickhands") and not quick_used:
		quick_used = true
		return true
	items.erase(id)
	return true


func item_cost(id: String) -> int:
	return maxi(1, int(Catalog.ITEMS[id].cost) - (2 if has_perk("quartermaster") else 0))


func imbue_cost(id: String) -> int:
	return maxi(1, int(Catalog.IMBUES[id].cost) - (2 if has_perk("enchanter") else 0))


## Numbered balls (1-15) no longer in your set.
func removed_count() -> int:
	return removed_total


## The placeable object this run's cue carries ("" for most cues).
func cue_kit() -> String:
	return str(Catalog.CUES.get(cue, {}).get("kit", ""))


## How hard a shot hits relative to its power setting.
func power_mult(is_break: bool) -> float:
	var m := 1.3 if has_perk("longarm") else 1.0
	if is_break and has_perk("bigbreak"):
		m *= 1.25
	return m


## Applies an item that needs no aiming or placing. Returns false for the others.
func use_state_item(id: String) -> bool:
	match id:
		"slip":
			if not last_chalk_lost:
				return false
			chalk = mini(MAX_CHALK, chalk + 1)
			last_chalk_lost = false
		_:
			return false
	return true


## True if this build is happy to see the 8 go down early.
func wants_eight() -> bool:
	return has_perk("eight") or has_perk("darkhorse") or has_perk("trouble")


## Called after a table is cleared. Returns a breakdown of the payout.
func payout() -> Array:
	var rows: Array = []
	var base := 4
	rows.append(["Table cleared", base])
	# Scoring well over the target: $1 for every 10% of it, up to $10.
	var over := int(floor((score - target()) / maxf(1.0, target() * 0.1)))
	if over > 0:
		rows.append(["Overkill: %d%% over target" % (over * 10), mini(over, OVERKILL_MAX)])
	# Clearing quickly: $1 for every shot under PAR_SHOTS, up to $5.
	var quick := PAR_SHOTS - shots_taken
	if quick > 0:
		rows.append(["Quick clear: %d shot%s" % [shots_taken, "" if shots_taken == 1 else "s"], mini(quick, QUICK_MAX)])
	if has_perk("thrift") and chalk >= 3:
		rows.append(["Thrift", 5])
	if has_perk("overflow"):
		var nxt := table_index + 1
		var next_target: int = plan[nxt].target if nxt < plan.size() else int(target() * 1.6)
		carry = mini(maxi(score - target(), 0), int(next_target * 0.25))
	if has_perk("alchemy"):
		var plain: Array = ball_set.filter(func(n): return n >= 1 and n <= 15 and n != 8)
		if not plain.is_empty():
			var turned: int = plain[rng.randi_range(0, plain.size() - 1)]
			var types := Catalog.BALL_TYPES.keys().filter(func(k): return not Catalog.BALL_TYPES[k].get("hidden", false))
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
	# Each cleared table adds a Chalk (Calcium Chalk adds one more).
	chalk = mini(MAX_CHALK, chalk + 1 + (1 if has_perk("chalk") else 0))
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
	reroll_cost = 2
	shop.clear()
	for i in 3:
		var f := _random_perk()
		if f != "":
			shop.append({"type": "perk", "id": f, "cost": Catalog.PERKS[f].cost, "sold": false})
	var keys := Catalog.IMBUES.keys()
	# A loose Imbue: you choose the ball when you buy it.
	var loose: String = keys[rng.randi_range(0, keys.size() - 1)]
	shop.append({"type": "imbue", "id": loose, "cost": imbue_cost(loose), "sold": false})
	# A high ball, 11 to 15, that already carries a random Imbue.
	var high: Array = range(11, 16).filter(func(n): return not ball_set.has(n))
	if not high.is_empty():
		var iso: String = keys[rng.randi_range(0, keys.size() - 1)]
		shop.append({"type": "imbue", "id": iso, "ball": high[rng.randi_range(0, high.size() - 1)], "adds": true, "cost": imbue_cost(iso) + 2, "sold": false})
	if not (intro and table_index < 2):
		var types := Catalog.BALL_TYPES.keys().filter(func(k): return not Catalog.BALL_TYPES[k].get("hidden", false))
		var bt: String = types[rng.randi_range(0, types.size() - 1)]
		shop.append({"type": "ball", "id": bt, "cost": int(Catalog.BALL_TYPES[bt].cost), "sold": false})
	# Two Catalysts you don't have yet.
	var free_tools: Array = Catalog.ITEMS.keys().filter(func(k): return not tools.has(k) and k != cue_kit())
	for i in (0 if intro and table_index < 1 else 2):
		if free_tools.is_empty():
			break
		var tl: String = free_tools[rng.randi_range(0, free_tools.size() - 1)]
		free_tools.erase(tl)
		shop.append({"type": "item", "id": tl, "cost": item_cost(tl), "sold": false})


func _random_perk() -> String:
	var pool: Array = []
	for id in Catalog.PERKS:
		if perks.has(id) or locked.has(id):
			continue
		if table_index < int(Catalog.PERKS[id].get("min_table", 0)):
			continue   # e.g. Calcium Chalk only after table 3
		var needs: Array = Catalog.PERKS[id].get("needs_balls", [])
		if not needs.is_empty() and not needs.any(func(b): return ball_set.has(b)):
			continue   # e.g. Actinium Ray only with a 13, 14 or 15 in your set
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
			if perks.size() >= perk_slots():
				return "Element slots full - sell one first"
			perks.append(item.id)
		"imbue":
			if not item.has("ball"):
				return "Choose a ball for this Isotope"
			if item.get("adds", false):
				if set_full():
					return "Choose a ball for it to replace"
				_add_numbered(int(item.ball), item.id)
				money -= item.cost
				item.sold = true
				return ""
			if imbues.has(int(item.ball)):
				return "That ball already has an Isotope"
			imbues[int(item.ball)] = item.id
		"ball":
			if set_full():
				return "Choose a ball for it to replace"
			add_special(item.id)
		"item":
			if Catalog.ITEMS[item.id].kind == "tool":
				if tools.has(item.id):
					return "You already have that Tool"
				if tools.size() >= tool_slots():
					return "Tool slots full"
				tools.append(item.id)
				tool_charges[item.id] = 2 if has_perk("overclock") else 1
			else:
				if items.size() >= item_slots():
					return "Consumable slots full - use one first"
				items.append(item.id)
	money -= item.cost
	item.sold = true
	return ""


## True when the Element is owned and switched on.
func has_perk(id: String) -> bool:
	return perks.has(id) and not perks_off.has(id)


## The owned Elements that are switched on, in slot order.
func live_perks() -> Array:
	return perks.filter(func(p): return not perks_off.has(p))


## Switches an owned Element off, or back on. Returns true if it is now on.
func toggle_perk(id: String) -> bool:
	if not perks.has(id):
		return false
	if perks_off.has(id):
		perks_off.erase(id)
		return true
	perks_off.append(id)
	return false


## A once-per-table Element that has already fired this table.
func perk_spent(id: String) -> bool:
	return perk_used.has(id)


func sell_perk(i: int) -> int:
	if i < 0 or i >= perks.size():
		return 0
	var id := perks[i]
	perks_off.erase(id)
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
	if bet_state == "offer":
		bet_state = "passed"   # the first shot closes the betting
	shots_taken += 1
	called = {}
	last_chalk_lost = false
	if res.get("scored", false):
		for n in res.get("potted", []):
			if int(n) >= 1 and int(n) <= 15:
				last_sunk = int(n)
	_roll_faces()
	next_boost = 1.0   # one-shot items are spent whatever happened
	next_all_hot = false
	next_magnet = false
	var out := {"cleared": false, "over": false, "rack_cleared": false, "ball_in_hand": not cue_on_table, "chalk_lost": false}
	var chalk_cost := 0
	if res.scored:
		var hot_before := hot_pocket
		if not bounty_done and bounty_met(res, hot_before):
			bounty_done = true
			if bet_state == "taken":
				bet_state = "won"
				money += bounty_reward()
				out["bounty"] = bounty
		score += res.total
		total_score += res.total
		heat += 1 + int(res.get("heat_gain", 0))
		best_heat = maxi(best_heat, heat)
		if res.get("jinxed", false):
			heat = int(heat / 2.0)   # Jinxed: the big pay costs half your Heat
		out["lucky_moves"] = _move_lucky(res)
		out["imbue_moves"] = _imbues_after(res)
		heat = maxi(0, heat - int(res.get("bounty_cash", 0)))   # Bounty cashes Heat out
		element_mix = res.get("element_mix", [])
		clock_pos = int(res.get("clock_pos", clock_pos))
		clock_streak = int(res.get("clock_streak", clock_streak))
		solid_run = int(res.get("solid_run", solid_run))
		if res.get("frost", false):
			frost_shield = true
		if res.get("heart", false) and not heart_used:
			heart_used = true
			chalk = mini(MAX_CHALK, chalk + 1)
			out["heart"] = true
		for n in res.get("lost_balls", []):
			remove_ball(int(n))
		for n in res.get("grown", []):
			seed_growth[str(n)] = int(seed_growth.get(str(n), 0)) + 1
		stripe_run = int(res.get("stripe_run", stripe_run))
		money += res.money
		catalyst += res.catalyst_gain
		_avalanche(res.potted.size())
		_fib_track(res.potted)
		for n in res.get("recur", []):
			ball_bonus[int(n)] = int(ball_bonus.get(int(n), 0)) + 4   # Recurring: +4 for the run
		for k in int(res.get("recharge", 0)):
			for t in tools:
				if int(tool_charges.get(t, 0)) <= 0:
					tool_charges[t] = 1   # Catalytic: one spent Catalyst recharges
					break
		if int(res.get("chalk_gain", 0)) > 0 and not chalked_used:
			chalked_used = true
			chalk = mini(MAX_CHALK, chalk + 1)   # Chalked Isotope, once a table
		if beacon_shot:
			heat += 1   # Americium Beacon
		recur_pending.append_array(res.get("recur", []))
		echo_pending.append_array(res.get("echo_src", []))
		for id in res.get("perk_used", []):
			perk_used[id] = true
		total_pots += res.potted.size()
		best_shot = maxi(best_shot, res.total)
		for n in res.shattered:
			imbues.erase(n)
		for k in res.get("pocket_list", []):
			if not pockets_used.has(k):
				pockets_used.append(k)
		var pl: Array = res.get("pocket_list", [])
		if not pl.is_empty():
			last_pocket = int(pl[pl.size() - 1])   # Helium Fusion remembers it
	else:
		var free_break: bool = was_break and res.foul == "Miss"
		# Boss "soft fouls": the shot scores nothing and the heat resets, but no chalk is lost.
		var soft: bool = res.foul == "Wrong pocket" or res.foul == "Wrong ball first" or res.foul == Scorer.EIGHT_FOUL
		var insured: bool = has_perk("insurance") and insured_used < 2
		var excused: bool = current().id == "local" and not forgiven and not free_break and not soft and not insured
		if excused:
			forgiven = true
			out["forgiven"] = true
		if not free_break and not soft and insured:
			insured_used += 1
		if not free_break and not soft and not insured and not excused:
			# A miss costs 1 Chalk; a scratch, or the 8 going in early, costs 2.
			chalk_cost = 2 if res.foul == "Scratch" or res.foul == "The 8 went early" else 1
			if has_perk("glasscannon"):
				chalk_cost += 1   # Astatine Edge: every foul costs one more
		if frost_shield:
			frost_shield = false   # Frost: this miss keeps the Heat
		else:
			if has_perk("migration") and heat >= 4:
				heat -= 1   # Stay Hot: on fire, a miss only costs 1
			else:
				heat = 0 if res.get("kindled_live", false) else int(heat / 2.0)   # a miss halves Heat; Kindled on the table wipes it
		for n in imbues:
			if imbues[n] == "heavy":
				imbue_level.erase(n)   # Weighted drops back to ×3
		element_mix = []
	# The 8 going in early costs 2 Chalk even when the shot scored (Carbon Core makes it safe).
	if res.get("eight_early", false) and not eight_safe():
		chalk_cost = maxi(chalk_cost, 2)
	if chalk_cost > 0 and not res.get("safe", false):
		chalk -= chalk_cost
		last_chalk_lost = true
		out.chalk_lost = true
		out["chalk_cost"] = chalk_cost
	score = maxi(0, score - int(res.get("penalty", 0)))
	money = maxi(0, money - int(res.get("eight_fine", 0)))
	if current().anomaly == "shrink":
		shrink_steps += 1
		out["layout_changed"] = true
	var item_shot := items_this_shot > 0
	items_this_shot = 0
	beacon_shot = false
	if score >= target():
		out.cleared = true
		if item_shot and has_perk("chain"):
			money += table_index + 1   # Sulfur Reagent: the clearing shot used a Catalyst
			out["reagent_pay"] = table_index + 1
		return out
	if chalk <= 0:
		out.over = true
		return out
	roll_hot_pocket(hot_pocket)
	if int(res.get("new_hot", -1)) >= 0 and hot_pocket >= 0 and not (has_perk("side") and int(res.new_hot) in [1, 4]):
		hot_pocket = int(res.new_hot)   # Ember chose it
	if balls_left == 0:
		racks_cleared += 1
		chalk = mini(MAX_CHALK, chalk + 1)
		out.rack_cleared = true
	return out


## ---------------------------------------------------------------- table physics
## Single source of truth for how the current table plays, shared by the game,
## the bots and the tests.
func build_layout() -> TableLayout:
	var layout := TableLayout.new()
	var sh_id: String = str(Catalog.BOSSES.get(current().get("id", ""), {}).get("shape", ""))
	if sh_id != "" and Catalog.SHAPES.has(sh_id):
		var sd: Dictionary = Catalog.SHAPES[sh_id]
		layout.build_shape(sd.verts, sd.pockets, pocket_scale(), closed_pockets(), sd.foot)
	else:
		layout.build(pocket_scale(), closed_pockets())
	for k in table_mods.get("covered", []):
		layout.pockets[k].closed = true
		var opp: int = 5 - int(k)
		layout.pockets[opp].r *= 1.3
	for bp in table_mods.get("bumpers", []):
		layout.add_bumper(Vector2(bp[0], bp[1]), TableLayout.BUMPER_R)
	for pt in table_mods.get("portals", []):
		layout.portals.append({"a": Vector2(pt[0], pt[1]), "b": Vector2(pt[2], pt[3])})
	# Sharks, posts and the pendulum bob (BoardFeatures), then the Sweeper's wall.
	for bp: Dictionary in BoardFeatures.bumpers(board):
		layout.bumpers.append(bp)
	for w: Array in BoardFeatures.walls(board):
		var a: Vector2 = w[0]
		var b: Vector2 = w[1]
		var n := (b - a).orthogonal().normalized()
		layout.segments.append({"a": a, "b": b, "n": n, "board": true})
		layout.segments.append({"a": b, "b": a, "n": -n, "board": true})
	for sg: Dictionary in BoardFeatures.segments(board):
		var d := sg.duplicate()
		d["board"] = true
		layout.segments.append(d)
	for pt: Array in BoardFeatures.portals(board):
		layout.portals.append({"a": pt[0], "b": pt[1]})
	if current().lab == "cyclotron" and board.is_empty():
		layout.add_bumper(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.27), 20.0)
		layout.add_bumper(Vector2(TableLayout.W * 0.5, TableLayout.H * 0.73), 20.0)
	elif current().lab == "pinball":
		for p in [Vector2(390, 125), Vector2(390, 375), Vector2(610, 125), Vector2(610, 375)]:
			layout.add_bumper(p, 18.0)
	return layout


## Applies lab, perk and anomaly physics. Call after the balls are racked.
func apply_physics(s: PoolSim) -> void:
	var t := current()
	s.volatile = {}
	for n in imbues:
		if imbues[n] == "volatile":
			s.volatile[int(n)] = true
	# Absolute values, because this also runs mid-table after temporary effects.
	s.roll_decel = 170.0
	s.drag = 0.1
	s.rail_e = 0.8
	s.tilt = Vector2.ZERO
	s.well_strength = 0.0
	s.pocket_pull = 0.0
	s.cue_damp = 1.0
	s.spin_power = 2.0 if has_perk("backspin") else 1.0
	s.side_power = 2.0 if has_perk("masse") else 1.0
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
	if has_perk("velvet"):
		s.roll_decel *= 0.7
		s.drag *= 0.7
	if has_perk("magnet"):
		s.pocket_pull = 1.0
	if has_perk("stun"):
		s.cue_damp = 0.4
	if has_perk("hothand") and heat >= 3:
		s.pocket_pull = maxf(s.pocket_pull, 0.7)   # Holmium Magnet
	s.anchor8 = has_perk("laststripe")   # Lead Anchor
	s.cue_float = has_perk("featherweight")   # Hydrogen Balloon
	# The board's own fields: Coriolis's turning disc, the Gulf Stream's current,
	# the Capacitor's charged rail and the Leech's victim.
	s.spin_zone = []
	s.flow_zone = []
	s.charged_y = -1.0
	s.no_drop = {}
	s.board_wells = []
	s.lorentz = []
	s.repel = []
	s.pot_pulse = 0.0
	match String(t.id):
		"venturi":
			s.flow_zone = [Rect2(560, 205, 90, 90), Vector2(420.0, 0.0)]   # the throat speeds balls up
		"lorentz":
			s.lorentz = [BoardFeatures.LORENTZ_RECT, 520.0]
		"meissner":
			for p: Vector2 in BoardFeatures.MEISSNER_POSTS:
				s.repel.append([p, 72.0, 2600.0])
		"escape":
			for p: Vector2 in BoardFeatures.ESCAPE_WELLS:
				s.board_wells.append([p, 0.9])
		"chain":
			s.pot_pulse = 1.0
		"tesla":
			if BoardFeatures.coil_on(board):
				s.board_wells = [[Vector2(TableLayout.W * 0.5, TableLayout.H * 0.5), -1.8]]
		"drift":
			s.spin_zone = [Vector2(TableLayout.W * 0.5, TableLayout.H * 0.5), 130.0, 900.0]
		"gulf":
			s.flow_zone = [Rect2(0, TableLayout.H * 0.38, TableLayout.W, TableLayout.H * 0.24), Vector2(0, 0) + Vector2(320.0, 0)]
		"spring_st":
			if BoardFeatures.charged(board):
				s.charged_y = TableLayout.H
	var leech := BoardFeatures.leech_ball(board)
	if leech > 0:
		s.no_drop[leech] = true
	s.cue_magnet = 0.0
	s.first_boost = 1.0   # Uranium Reactor sets this per shot, when the shot is struck
	if has_perk("domino"):
		s.ball_e = 1.0   # Dysprosium Domino: hits lose no speed
	else:
		s.ball_e = 0.97
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
			if has_perk("heavyhit"):
				m *= 1.3
		else:
			if t.anomaly == "lead":
				m = 1.6
			if has_perk("laststripe") and s.num[i] == 8:
				m *= 3.0   # Lead Anchor
			if s.num[i] == BoardFeatures.leech_ball(board):
				m *= 3.0   # the Leech weighs its ball down
			if has_perk("lever") and Catalog.is_stripe(s.num[i]):
				m *= 1.4   # Tungsten Core
			if has_perk("racing") and Catalog.is_stripe(s.num[i]):
				m *= 0.7   # Rubidium Rush
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
			var halo: bool = has_perk("lastcall") and s.num[i] == 8 and s.object_balls_left() == 1   # Polonium Halo
			s.pull[i] = 1.0 if imbues.get(s.num[i], "") == "magnetic" or halo else 0.0
			var charged: bool = has_perk("lowball") and lithium_balls().has(s.num[i])   # Lithium Cell
			s.bounce[i] = 1.0 if Catalog.kind_of(s.num[i]) == "star" or (has_perk("lever") and Catalog.is_stripe(s.num[i])) or charged or imbues.get(s.num[i], "") == "rubber" else 0.0
			if s.num[i] == 0 and has_perk("liverails"):
				s.bounce[i] = 1.15   # Nitrogen Tyres: the cue ball kicks off cushions
		if i < s.rad.size():
			s.rad[i] = TableLayout.R
			if s.num[i] == 0 and has_perk("elastic"):
				s.rad[i] = BOULDER_R   # Neodymium Boulder: as big as still fits a pocket
				m *= 2.0
		s.mass[i] = m
		if i < s.grip.size():
			var g := 1.0
			if s.num[i] == 0 and has_perk("collector"):
				g = 0.6   # Gallium Glide: rolls about 50% further
			if has_perk("slowcloth"):
				g *= 1.5 if s.num[i] == 0 else 0.8   # Thallium Felt: the cue stops sooner, the rest roll on
			if imbues.get(s.num[i], "") == "slick":
				g *= 0.6
			elif s.num[i] != 0 and has_perk("racing") and Catalog.is_stripe(s.num[i]):
				g = 0.8   # Rubidium Rush: rolls 25% further
			s.grip[i] = g


## Uranium Reactor: a full-power shot sends the first ball it hits off 20% faster.
## Lithium Cell: your three lowest-value balls in play (never the 8).
func lithium_balls() -> Array:
	var set_now: Array = ball_set.filter(func(n): return int(n) != 8)
	set_now.sort_custom(func(a, b): return Catalog.ball_points(int(a)) < Catalog.ball_points(int(b)) or (Catalog.ball_points(int(a)) == Catalog.ball_points(int(b)) and int(a) < int(b)))
	return set_now.slice(0, 3)


## Between shots on a board with Sharks or moving parts: they take their hits,
## move, swallow and join, and the parts step on. Shared by the game and the bots.
func board_turn(s: PoolSim, events: Array) -> Dictionary:
	if board.is_empty():
		return {}
	var brng := RandomNumberGenerator.new()
	brng.seed = seed_value * 7 + table_index * 131 + int(board.get("shots", 0)) * 17
	var out := BoardFeatures.after_shot(board, s, events, brng)
	money += int(out.get("money", 0))
	return out


func first_boost(power: float) -> float:
	return 1.2 if has_perk("power") and power >= 0.85 else 1.0


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
		"perks": live_perks(), "imbues": imbues, "hot_pocket": hot_pocket, "beacon": beacon_shot, "safe8": eight_safe(), "portal_chain": bool(cue_rule("portal_chain", false)), "coil": BoardFeatures.coil_on(board), "focus": _focus_pocket(), "ball_bonus": ball_bonus, "perk_used": perk_used, "item_shot": items_this_shot > 0, "boss": current().id, "lab": current().lab,
		"anomaly": current().anomaly, "loan": BoardFeatures.loan_alive(board), "last_pocket": last_pocket, "lithium": lithium_balls() if has_perk("lowball") else [], "heat": heat, "power": power, "shots_taken": shots_taken,
		"catalyst": catalyst, "is_break": is_break, "chalk": chalk, "objects": s.object_balls_left(),
		"money": money, "empty_slots": perk_slots() - perks.size(), "pockets_used": pockets_used,
		"lowest": lowest, "highest": highest, "element_mix": element_mix, "clock_pos": clock_pos, "clock_streak": clock_streak,
		"target": target(), "on_table": on_table, "total_pots": total_pots,
		"solid_run": solid_run, "stripe_run": stripe_run,
		"boost": next_boost, "all_hot": next_all_hot, "removed": removed_count(), "called": called,
		"specials": ball_kinds.size(), "seed_growth": seed_growth, "lucky_mult": lucky_mult, "imbue_level": imbue_level,
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
		"money": money, "perks": perks, "imbues": iso, "perks_off": perks_off, "ball_bonus": _str_keys(ball_bonus), "fib_done": fib_done, "numerals": _str_keys(numerals),
		"catalyst": catalyst, "plan": plan, "endless": endless, "total_pots": total_pots,
		"best_shot": best_shot, "tables_cleared": tables_cleared, "best_heat": best_heat,
		"phase": phase, "carry": carry, "record_id": record_id, "daily_key": daily_key,
		"handicap": handicap, "total_score": total_score, "items": items, "ball_set": ball_set,
		"ball_kinds": _kinds_out(), "lucky_mult": _keys_out(lucky_mult), "imbue_level": _keys_out(imbue_level), "seed_growth": seed_growth, "removals": removals, "removed_total": removed_total, "tools": tools,
	}
	if phase == "table":
		d["table"] = {
			"score": score, "chalk": chalk, "heat": heat, "shots_taken": shots_taken,
			"hot_pocket": hot_pocket, "racks_cleared": racks_cleared, "element_mix": element_mix, "clock_pos": clock_pos, "clock_streak": clock_streak,
			"forgiven": forgiven, "bounty": bounty, "bounty_done": bounty_done, "bet_cap": bet_cap, "bet_state": bet_state, "bet_peeked": bet_peeked,
			"pockets_used": pockets_used, "last_pocket": last_pocket, "perk_used": perk_used.keys(), "beacon_used": beacon_used, "temp_tools": temp_tools, "echo_imbues": _str_keys(echo_imbues), "prime_spawned": prime_spawned, "temp_numerals": temp_numerals, "twin_spawned": twin_spawned, "chalked_used": chalked_used, "shrink_steps": shrink_steps, "insured_used": insured_used,
				"solid_run": solid_run, "stripe_run": stripe_run, "mods": table_mods, "board": board,
				"frost": frost_shield, "heart_used": heart_used, "tool_charges": tool_charges, "chalk_lost": last_chalk_lost,
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
	return load_dict(d)


## Restores a run from a saved dictionary (a save file, or a Rewind point).
func load_dict(d: Dictionary) -> bool:
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
	perks_off.assign((d.get("perks_off", []) as Array).filter(func(x): return perks.has(x)))
	ball_bonus.clear()
	var bb: Dictionary = d.get("ball_bonus", {})
	for k in bb:
		ball_bonus[int(k)] = int(bb[k])
	fib_done.assign(d.get("fib_done", []))
	numerals.clear()
	var nm: Dictionary = d.get("numerals", {})
	for k in nm:
		numerals[int(k)] = int(nm[k])
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
	items.clear()
	# Old saves held one-use items: they become Catalysts if there is room.
	for x in d.get("items", []):
		if Catalog.ITEMS.has(x) and not tools.has(x) and tools.size() < tool_slots():
			tools.append(x)
	tools.assign((d.get("tools", []) as Array).filter(func(x): return Catalog.ITEMS.has(x) and Catalog.ITEMS[x].kind == "tool"))
	var held_items := items.duplicate()
	ball_set = (d.get("ball_set", range(1, 16)) as Array).map(func(x): return int(x))
	ball_kinds = {}
	var bk = d.get("ball_kinds", {})
	if typeof(bk) == TYPE_DICTIONARY:
		for k in bk:
			if Catalog.BALL_TYPES.has(bk[k]):
				ball_kinds[int(k)] = bk[k]
	Catalog.kinds = ball_kinds
	seed_growth = d.get("seed_growth", {}) if typeof(d.get("seed_growth", {})) == TYPE_DICTIONARY else {}
	lucky_mult = {}
	for k in d.get("lucky_mult", {}):
		lucky_mult[int(k)] = int(d.lucky_mult[k])
	imbue_level = {}
	for k in d.get("imbue_level", {}):
		imbue_level[int(k)] = int(d.imbue_level[k])
	removals = int(d.get("removals", 0))
	removed_total = int(d.get("removed_total", removals))
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
		clock_pos = int(t.get("clock_pos", 0))
		clock_streak = int(t.get("clock_streak", 0))
		forgiven = bool(t.get("forgiven", false))
		var b := str(t.get("bounty", bounty))
		if Catalog.BOUNTIES.has(b) or b == "":
			bounty = b
		bet_cap = int(t.get("bet_cap", 0))
		bounty_done = bool(t.get("bounty_done", false))
		bet_state = str(t.get("bet_state", "passed"))
		bet_peeked = bool(t.get("bet_peeked", false))
		pockets_used = (t.get("pockets_used", []) as Array).map(func(x): return int(x))
		last_pocket = int(t.get("last_pocket", -1))
		perk_used = {}
		for id in t.get("perk_used", []):
			perk_used[String(id)] = true
		beacon_used = bool(t.get("beacon_used", false))
		temp_tools.assign(t.get("temp_tools", []))
		echo_imbues.clear()
		var ei: Dictionary = t.get("echo_imbues", {})
		for k in ei:
			echo_imbues[int(k)] = String(ei[k])
		prime_spawned.assign(t.get("prime_spawned", []))
		temp_numerals.assign(t.get("temp_numerals", []))
		twin_spawned = bool(t.get("twin_spawned", false))
		chalked_used = bool(t.get("chalked_used", false))
		shrink_steps = int(t.get("shrink_steps", 0))
		insured_used = int(t.get("insured_used", 0))
		solid_run = int(t.get("solid_run", 0))
		stripe_run = int(t.get("stripe_run", 0))
		if typeof(t.get("mods")) == TYPE_DICTIONARY:
			table_mods = t.mods
		board = t.get("board", {}) if t.get("board", {}) is Dictionary else {}
		next_boost = float(t.get("boost", 1.0))
		next_all_hot = bool(t.get("all_hot", false))
		next_magnet = bool(t.get("magnet", false))
		frost_shield = bool(t.get("frost", false))
		items.assign(held_items)   # begin_table may have added a Tinkerer item
		if typeof(t.get("tool_charges")) == TYPE_DICTIONARY:
			tool_charges = t.tool_charges
		last_chalk_lost = bool(t.get("chalk_lost", false))
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


## Beryllium Avalanche: every sink gives 2 random balls in your set +4 for the run.
func _avalanche(sinks: int) -> void:
	if not has_perk("catalyst") or sinks <= 0:
		return
	var pool: Array = ball_set.filter(func(n): return int(n) >= 1 and int(n) <= 15)
	if pool.is_empty():
		return
	for i in sinks * 2:
		var n := int(pool[rng.randi_range(0, pool.size() - 1)])
		ball_bonus[n] = int(ball_bonus.get(n, 0)) + 4


static func _str_keys(d: Dictionary) -> Dictionary:
	var o := {}
	for k in d:
		o[str(k)] = d[k]
	return o


## The pocket out on the cloth on Parabolic Mirror, Whispering Gallery and Golden
## Spiral (index 5, or 4 for the spiral's drain); -1 on other boards.
func _focus_pocket() -> int:
	match String(current().id):
		"parabolic", "whisper":
			return 5
		"spiral":
			return 4
	return -1


## A rule the starting cue brings (Catalog.CUES[cue].rules), or `def`.
func cue_rule(key: String, def: Variant) -> Variant:
	return (Catalog.CUES.get(cue, {}).get("rules", {}) as Dictionary).get(key, def)


## How many Elements you can hold: 6, or fewer on a cue that says so.
func perk_slots() -> int:
	return int(cue_rule("max_perks", MAX_PERKS))


## The 8 going in early costs nothing: Carbon Core, or the Black Cue.
func eight_safe() -> bool:
	return has_perk("eight") or bool(cue_rule("safe8", false))


## Tidies up what lasts only one table: Tellurium's Catalysts, echoed Isotopes,
## and the big-number balls Promethium brought on.
func _end_table_extras() -> void:
	for t in temp_tools:
		tools.erase(t)
		tool_charges.erase(t)
	temp_tools.clear()
	for n in echo_imbues:
		if imbues.get(n, "") == echo_imbues[n]:
			imbues.erase(n)
	echo_imbues.clear()
	for n in temp_numerals:
		ball_kinds.erase(n)
		numerals.erase(n)
	temp_numerals.clear()
	Catalog.kinds = ball_kinds
	prime_spawned.clear()
	echo_pending.clear()
	recur_pending.clear()
	chalked_used = false
	_roll_faces()


## Tellurium Supply: a random Catalyst for this table, if there is room.
func _table_start_extras() -> void:
	if has_perk("oracle") and tools.size() < tool_slots():
		var pool: Array = Catalog.ITEMS.keys().filter(func(k): return not tools.has(k) and k != cue_kit())
		if not pool.is_empty():
			var id: String = pool[rng.randi_range(0, pool.size() - 1)]
			tools.append(id)
			tool_charges[id] = 2 if has_perk("overclock") else 1
			temp_tools.append(id)


## A big plain ball showing number `face`, kept in the set (permanent) or for this table only.
func add_numeral(face: int, permanent: bool) -> int:
	var num := 100 if not permanent else 16
	while ball_kinds.has(num) or ball_set.has(num):
		num += 1
	ball_kinds[num] = "numeral"
	numerals[num] = face
	if permanent:
		ball_set.append(num)
	else:
		temp_numerals.append(num)
	Catalog.kinds = ball_kinds
	_roll_faces()
	return num


## The number a ball counts as: its own, or the one a Dice, Wild or numeral shows.
func face_of(n: int) -> int:
	if n > 15:
		return int(Catalog.faces.get(n, 0))
	return n


static func _is_prime(n: int) -> bool:
	if n < 2:
		return false
	for d in range(2, int(sqrt(float(n))) + 1):
		if n % d == 0:
			return false
	return true


## Promethium Prime: the next prime to roll on, above every prime this table has seen.
func next_prime() -> int:
	var top := 0
	for n in ball_set:
		var f := face_of(int(n))
		if _is_prime(f):
			top = maxi(top, f)
	for f in prime_spawned:
		top = maxi(top, int(f))
	var p := top + 1
	while not _is_prime(p):
		p += 1
	return p


## Fermium Spiral: the Fibonacci numbers to sink before the next reward.
func fib_needed() -> Array:
	var fibs := [1, 2, 3, 5, 8]
	var top := 8
	for n in ball_set:
		top = maxi(top, face_of(int(n)) if _is_fib(face_of(int(n))) else 0)
	var a := 5
	var b := 8
	while b < top:
		var c := a + b
		a = b
		b = c
		fibs.append(b)
	return fibs


static func _is_fib(n: int) -> bool:
	var a := 1
	var b := 2
	if n == 1:
		return true
	while b < n:
		var c := a + b
		a = b
		b = c
	return b == n


func next_fib() -> int:
	var need := fib_needed()
	var last: int = need[need.size() - 1]
	var prev: int = need[need.size() - 2] if need.size() > 1 else 5
	return last + prev


## Fermium Spiral: tick off Fibonacci balls; with all of them, the next one joins your set.
var fib_reward := 0
func _fib_track(potted: Array) -> void:
	if not has_perk("fibonacci"):
		return
	for n in potted:
		var f := face_of(int(n))
		if _is_fib(f) and not fib_done.has(f):
			fib_done.append(f)
	var need := fib_needed()
	if need.all(func(f): return fib_done.has(f)):
		var nf := next_fib()
		fib_done.clear()
		fib_reward = nf
		if nf <= 15 and not ball_set.has(nf):
			if ball_set.size() >= MAX_SET:
				_drop_lowest_plain()
			ball_set.append(nf)
		else:
			if ball_set.size() >= MAX_SET:
				_drop_lowest_plain()
			add_numeral(nf, true)


## Makes room in a full set: the lowest plain ball that is not a Fibonacci number goes.
func _drop_lowest_plain() -> void:
	var low: Array = ball_set.filter(func(n): return n >= 1 and n <= 15 and n != 8 and not _is_fib(n))
	if low.is_empty():
		low = ball_set.filter(func(n): return n >= 1 and n <= 15 and n != 8)
	low.sort()
	if not low.is_empty():
		remove_ball(low[0])


## Between shots, with the real table: Recurring balls come back, Isotopes echo,
## Promethium brings on the next prime, and Ytterbium's twin cue ball appears.
## Returns {added: [ball numbers put on the table], echoed: [n], back: [n], twin: bool}.
func shot_extras(s: PoolSim) -> Dictionary:
	var out := {"added": [], "echoed": [], "back": [], "twin": false}
	var on_table: Array = []
	for i in s.count():
		if s.alive[i] == 1 and s.num[i] != 0:
			on_table.append(i)
	# Recurring: back on the table in place of a random other ball (never the 8).
	for n in recur_pending:
		var bi := s.index_of(int(n))
		var others: Array = on_table.filter(func(i): return s.num[i] != 8 and s.num[i] != int(n))
		if bi < 0 or others.is_empty():
			continue
		var vi: int = others[rng.randi_range(0, others.size() - 1)]
		s.pos[bi] = s.pos[vi]
		s.vel[bi] = Vector2.ZERO
		s.alive[bi] = 1
		s.alive[vi] = 0
		on_table.erase(vi)
		on_table.append(bi)
		out.back.append(int(n))
	recur_pending.clear()
	# Europium Echo: each Isotope that sank jumps to a ball on the table with none.
	if has_perk("echo"):
		for n in echo_pending:
			var iso: String = imbues.get(int(n), echo_imbues.get(int(n), ""))
			var bare: Array = on_table.filter(func(i): return s.num[i] != 8 and not imbues.has(s.num[i]))
			if iso == "" or bare.is_empty():
				continue
			var m: int = s.num[bare[rng.randi_range(0, bare.size() - 1)]]
			imbues[m] = iso
			echo_imbues[m] = iso
			out.echoed.append(m)
	echo_pending.clear()
	# Promethium Prime: no prime left on the table brings on the next one.
	if has_perk("prime") and s.object_balls_left() > 0:
		if not on_table.any(func(i): return _is_prime(face_of(s.num[i]))):
			var p := next_prime()
			var spot := _free_spot(s)
			if spot != Vector2.INF:
				prime_spawned.append(p)
				var num := p if p <= 15 and not ball_set.has(p) and s.index_of(p) < 0 else add_numeral(p, false)
				s.add_ball(num, spot)
				out.added.append(num)
	# Ytterbium Twin: after the first shot, a second cue ball.
	if has_perk("drawartist") and not twin_spawned and shots_taken >= 1:
		var cues: Array = range(s.count()).filter(func(i): return s.num[i] == 0 and s.alive[i] == 1)
		if cues.size() == 1:
			var spot := _free_spot(s)
			if spot != Vector2.INF:
				s.add_ball(0, spot)
				twin_spawned = true
				out.twin = true
	return out


## A random clear spot on the table, or Vector2.INF.
func _free_spot(s: PoolSim) -> Vector2:
	for tries in 60:
		var p := Vector2(rng.randf_range(120.0, TableLayout.W - 120.0), rng.randf_range(80.0, TableLayout.H - 80.0))
		if s.layout != null and not s.layout.contains(p, 30.0):
			continue
		if s.is_clear_spot(p, -1):
			return p
	return Vector2.INF
