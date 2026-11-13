extends SceneTree
## Fast scoring balance probe. Synthesizes plausible shot event logs; never runs PoolSim.
## Uses the production Scorer and RunState for points, Heat, Chalk, racks and clears.
## This is a counterfactual build comparison, not a physics or shop-availability test.

const TABLES := 9
const RUNS := 300
const SHOT_LIMIT := 35

var models := {
	"hard": {"pot": 0.46, "multi": 0.11, "scratch": 0.055},
	"middle": {"pot": 0.58, "multi": 0.16, "scratch": 0.040},
	"strong": {"pot": 0.70, "multi": 0.22, "scratch": 0.025},
}
var builds := ["plain", "scattered", "value", "engine", "engine_no_imbue", "engine_no_exotic", "engine_no_remove"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var count := maxi(1, int(args[0])) if args.size() > 0 else RUNS
	var scale := maxf(0.1, float(args[1])) if args.size() > 1 else 1.0
	print("score_balance runs=%d target_scale=%.2f (synthetic events, production scorer/state)" % [count, scale])
	for model_name in models:
		for build in builds:
			var results: Array = []
			for i in count:
				results.append(_run(i + 11447, model_name, build, scale))
			_report(model_name, build, results)
	quit()


func _build(state: RunState, name: String, table: int) -> void:
	# Guaranteed acquisitions at fixed milestones isolate scoring power from shop RNG.
	# Scattered is deliberately incoherent but receives the same number of cards.
	var random_cards := ["odd", "cushion", "chalk", "rhythm", "side", "highball"]
	var value_cards := ["odd", "solids", "fibonacci", "moneyball", "thinrack", "highball"]
	var engine_cards := ["side", "heat", "even", "prime", "glasscannon", "menagerie"]
	var cards: Array = []
	match name:
		"scattered": cards = random_cards
		"value": cards = value_cards
		"engine", "engine_no_imbue", "engine_no_exotic", "engine_no_remove": cards = engine_cards
	for j in mini(table, cards.size()):
		if not state.perks.has(cards[j]):
			state.perks.append(cards[j])
	if name.begins_with("engine"):
		if name != "engine_no_remove" and table >= 3:
			for n in [1, 2]:
				if state.ball_set.has(n): state.remove_ball(n)
		if name != "engine_no_exotic" and table >= 4 and not state.ball_kinds.values().has("iron"):
			state.add_special("iron")
		if name != "engine_no_exotic" and table >= 6 and not state.ball_kinds.values().has("anchor"):
			state.add_special("anchor")
		if name != "engine_no_imbue":
			for n in [5, 7, 9, 10]:
				if table >= 3 + int(n / 3) and state.ball_set.has(n):
					state.imbues[n] = "leaded" if n % 2 else "glass"
	elif name == "scattered":
		if table >= 4 and not state.ball_kinds.values().has("feather"):
			state.add_special("feather")
		if table >= 5: state.imbues[3] = "gold"
	elif name == "value":
		if table >= 4:
			for n in [1, 2]:
				if state.ball_set.has(n): state.remove_ball(n)


func _run(seed_value: int, model_name: String, build: String, scale: float) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 71 + 8
	var state := RunState.new()
	state.start(seed_value)
	for t in state.plan.size():
		state.plan[t].target = int(ceil(int(state.plan[t].target) * scale))
	var scores: Array = []
	var shots: Array = []
	var boards: Array = []
	var cleared := 0
	for table in TABLES:
		_build(state, build, table)
		state.begin_table()
		boards.append(String(state.current().id))
		var remaining: Array = state.ball_set.duplicate()
		var shot_count := 0
		var target := state.target()
		while state.score < target and state.chalk > 0 and shot_count < SHOT_LIMIT:
			var profile: Dictionary = models[model_name]
			var p: float = float(profile.pot) - 0.025 * table
			var aid := state.perks.has("jaws") or state.perks.has("magnet")
			if aid: p += 0.025
			p = clampf(p, 0.12, 0.9)
			var pots: Array = []
			if rng.randf() < p:
				pots.append(_choose_ball(remaining, rng))
				if remaining.size() > 1 and rng.randf() < float(profile.multi):
					var extra := remaining.duplicate()
					extra.erase(pots[0])
					pots.append(_choose_ball(extra, rng))
			var events: Array = []
			if pots.is_empty() and rng.randf() < 0.9:
				events.append({"type": "ball", "a": 0, "b": _choose_ball(remaining, rng), "at": 0.1})
			if not pots.is_empty():
				var first: int = int(pots[0])
				events.append({"type": "ball", "a": 0, "b": first, "at": 0.1})
				for k in pots.size():
					var n: int = int(pots[k])
					var pocket := rng.randi_range(0, 5)
					if rng.randf() < 0.12:
						events.append({"type": "rail", "a": n, "at": 0.2 + k})
					events.append({"type": "pocket", "a": n, "pocket": pocket, "rails": 1 if events[events.size() - 1].type == "rail" else 0, "at": 0.5 + k})
			if rng.randf() < float(profile.scratch):
				events.append({"type": "pocket", "a": 0, "pocket": rng.randi_range(0, 5), "rails": 0, "at": 3.0})
			var ctx := _context(state, remaining, events, shot_count)
			var result := Scorer.score(ctx)
			for n in result.potted:
				remaining.erase(n)
			var flow := state.apply_shot(result, shot_count == 0, remaining.size(), not result.scratch)
			shot_count += 1
			if flow.cleared or state.score >= target:
				break
			if flow.over:
				break
			if remaining.is_empty(): remaining = state.ball_set.duplicate()
		scores.append(state.score)
		shots.append(shot_count)
		if state.score < target or state.chalk <= 0:
			break
		cleared += 1
		state.payout()
		state.advance_table()
	return {"cleared": cleared, "scores": scores, "shots": shots, "boards": boards}


func _choose_ball(remaining: Array, rng: RandomNumberGenerator) -> int:
	# Early 8 sinks are unusual in intentional play; chance rises as rack empties.
	var pool := remaining.duplicate()
	if pool.size() > 2: pool.erase(8)
	return int(pool[rng.randi_range(0, pool.size() - 1)])


func _context(state: RunState, remaining: Array, events: Array, shot_count: int) -> Dictionary:
	var numbers: Array = remaining.filter(func(n): return n <= 15)
	numbers.sort()
	return {
		"events": events, "perks": state.perks, "imbues": state.imbues, "imbue_level": state.imbue_level,
		"hot_pocket": state.hot_pocket, "last_pocket": state.last_pocket,
		"heat": state.heat, "chalk": state.chalk, "money": state.money, "shots_taken": shot_count,
		"objects": remaining.size(), "on_table": remaining, "lowest": numbers[0] if not numbers.is_empty() else -1,
		"highest": numbers[numbers.size() - 1] if not numbers.is_empty() else -1,
		"boss": state.current().id, "anomaly": state.current().anomaly, "target": state.target(),
		"is_break": shot_count == 0, "power": 0.6, "rng": state.rng, "perk_used": state.perk_used,
		"removed": state.removed_count(), "specials": state.ball_kinds.size(), "ball_bonus": state.ball_bonus,
		"element_mix": state.element_mix, "clock_pos": state.clock_pos, "clock_streak": state.clock_streak,
		"solid_run": state.solid_run, "stripe_run": state.stripe_run, "total_pots": state.total_pots,
		"seed_growth": state.seed_growth, "lucky_mult": state.lucky_mult, "pockets_used": state.pockets_used,
		"focus": -1, "cue_start": Vector2.ZERO,
	}


func _report(model_name: String, build: String, results: Array) -> void:
	var wins := 0
	var total := 0.0
	var reach: Array = []
	var score_sum: Array = []
	var count: Array = []
	for _t in TABLES:
		reach.append(0)
		score_sum.append(0.0)
		count.append(0)
	for r in results:
		wins += int(r.cleared == TABLES)
		total += r.cleared
		for t in r.scores.size():
			reach[t] += int(r.cleared > t)
			score_sum[t] += r.scores[t]
			count[t] += 1
	var parts: Array[String] = []
	for t in TABLES:
		parts.append("%d:%d%%/%.0f" % [t + 1, int(round(100.0 * reach[t] / results.size())), score_sum[t] / maxf(1.0, count[t])])
	print("%s %-6s win=%3d%% clear=%.1f | %s" % [model_name, build, int(round(100.0 * wins / results.size())), total / results.size(), " ".join(parts)])
	if model_name == "strong" and build == "engine":
		var attempts := {}
		for r in results:
			for id in r.boards:
				attempts[id] = int(attempts.get(id, 0)) + 1
		var missing: Array = Catalog.BOSSES.keys().filter(func(id): return not attempts.has(id))
		print("  board coverage: %d/%d attempted; missing: %s" % [attempts.size(), Catalog.BOSSES.size(), ", ".join(missing)])
