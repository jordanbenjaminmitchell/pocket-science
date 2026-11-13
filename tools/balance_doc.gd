extends SceneTree
## Writes docs/BALANCE_REVIEW.md: every number a balance pass might change,
## read straight from the game's data, one table per kind of thing. Each row
## ends in two empty columns: "Your note" for the reviewer, "Done" for whoever
## makes the change.
##   godot --headless --path . --script res://tools/balance_doc.gd

var lines: PackedStringArray = []
var sections: Array = []   # for docs/balance_data.json: [{title, intro, cols, rows: [{key, cells}]}]


func _initialize() -> void:
	_go()
	quit()


func _cell(v) -> String:
	return str(v).replace("|", "/").replace("\n", " ")


func _table(title: String, intro: String, cols: Array, rows: Array) -> void:
	var jrows: Array = []
	for r: Array in rows:
		var key := (title.to_lower().replace(" ", "-") + "-" + str(r[1] if r.size() > 1 and str(r[1]).begins_with("`") else r[0])).replace("`", "")
		var clean := ""
		for ch in key:
			clean += ch if ch.is_valid_identifier() or ch in "0123456789-_" else "-"
		var cells: Array = []
		for v in r:
			cells.append(str(v).replace("`", ""))
		jrows.append({"key": clean.substr(0, 120), "cells": cells})
	sections.append({"title": title, "intro": intro, "cols": cols, "rows": jrows})
	lines.append("## " + title)
	lines.append("")
	if intro != "":
		lines.append(intro)
		lines.append("")
	var head: Array = cols + ["Your note", "Done"]
	lines.append("| " + " | ".join(head) + " |")
	var sep: Array = []
	for c in head:
		sep.append("---")
	lines.append("|" + "|".join(sep) + "|")
	for r: Array in rows:
		var cells: Array = []
		for v in r:
			cells.append(_cell(v))
		lines.append("| " + " | ".join(cells + ["", ""]) + " |")
	lines.append("")


func _go() -> void:
	lines.append("# Balance review")
	lines.append("")
	lines.append("Every number in Pocket Science that a balance pass might change, read from the game's data on %s." % Time.get_date_string_from_system())
	lines.append("")
	lines.append("**How to use it:** write in the **Your note** column on any row, for example \"cost 6 → 5\", \"too strong\" or \"cut\". Leave the rest blank. Whoever makes the change ticks **Done** and notes what changed.")
	lines.append("")
	lines.append("Regenerate it with `godot --headless --path . --script res://tools/balance_doc.gd`. That overwrites notes, so copy them first.")
	lines.append("")

	# Core rules.
	_table("Core rules", "The numbers every run uses.", ["Rule", "Now", "Where"], [
		["Chalk at the start of a run", RunState.BASE_CHALK, "`RunState.BASE_CHALK`"],
		["Most Chalk you can hold", RunState.MAX_CHALK, "`RunState.MAX_CHALK`"],
		["Chalk back for clearing a table", 1, "`RunState.advance_table`"],
		["Chalk back for clearing a rack", 1, "`RunState.apply_shot`"],
		["Chalk cost: a miss or no contact", 1, "`RunState.apply_shot`"],
		["Chalk cost: a scratch, or the 8 going in early", 2, "`RunState.apply_shot`"],
		["Points lost for an early 8", "%d%% of the table's target" % int(Catalog.EIGHT_PENALTY * 100), "`Catalog.EIGHT_PENALTY`"],
		["Heat multiplier", "×(1 + %.1f × Heat)" % Scorer.HEAT_STEP, "`Scorer.HEAT_STEP`"],
		["Chain added by each ball that sinks", "+%.1f" % Scorer.AFTER_POT, "`Scorer.AFTER_POT`"],
		["Ball value", "10 + %d × its number" % Catalog.NUMBER_WEIGHT, "`Catalog.NUMBER_WEIGHT`"],
		["Balls at the start of a run", "1 to %d" % RunState.START_BALLS, "`RunState.START_BALLS`"],
		["Most balls in your set", RunState.MAX_SET, "`RunState.MAX_SET`"],
		["Element slots", RunState.MAX_PERKS, "`RunState.MAX_PERKS`"],
		["Catalyst slots", RunState.TOOL_SLOTS, "`RunState.TOOL_SLOTS`"],
		["Uses of an object cue's object, each table", RunState.CUE_KIT_USES, "`RunState.CUE_KIT_USES`"],
	])
	_table("Money", "What you earn and what the shop's services cost.", ["Rule", "Now", "Where"], [
		["Clearing a table", "$4", "`RunState.payout`"],
		["Overkill: per 10% over the target", "$1, up to $%d" % RunState.OVERKILL_MAX, "`RunState.OVERKILL_MAX`"],
		["Quick clear: per shot under %d" % RunState.PAR_SHOTS, "$1, up to $%d" % RunState.QUICK_MAX, "`RunState.PAR_SHOTS`, `QUICK_MAX`"],
		["Reroll Elements", "$2, then $1 more each reroll", "`RunState.reroll_cost`"],
		["Remove a ball", "$3, then $1 more each removal", "`RunState.removal_cost`"],
		["Selling an Element", "Half its cost (at least $1)", "`RunState.sell_value`"],
	])

	# Tables and difficulty.
	var trows: Array = []
	for i in Catalog.TABLES.size():
		var t: Dictionary = Catalog.TABLES[i]
		var who: String = Catalog.BOSSES[t.boss].name if t.has("boss") else "Any tier %d board" % int(t.tier)
		trows.append([i + 1, t.target, who, "$%d" % int(Catalog.BET_STAKES[mini(i, Catalog.BET_STAKES.size() - 1)])])
	_table("The nine tables", "Endless tables after the ninth raise the target ×1.6 each.", ["Table", "Target", "Board", "Side bet stake"], trows)
	var hrows: Array = []
	for i in Catalog.HANDICAPS.size():
		hrows.append([i, Catalog.HANDICAPS[i].name, Catalog.HANDICAPS[i].desc])
	_table("Handicaps", "Each level includes every rule before it.", ["Level", "Name", "Rule"], hrows)
	var brows: Array = []
	for id in Catalog.BOSSES:
		var b: Dictionary = Catalog.BOSSES[id]
		brows.append([b.name, "`%s`" % id, b.tier, b.lab, b.desc])
	_table("Boards", "Tier 0 is the first table, tier 9 the fixed boss tables.", ["Board", "Id", "Tier", "Physics", "Rule"], brows)

	# Cards.
	var prows: Array = []
	var ids: Array = Catalog.PERKS.keys()
	ids.sort_custom(func(a, b): return int(Catalog.PERKS[a].z) < int(Catalog.PERKS[b].z))
	for id in ids:
		var f: Dictionary = Catalog.PERKS[id]
		prows.append([f.z, f.name, "`%s`" % id, Catalog.rarity_name(f.r), "$%d" % f.cost, Catalog.family_name(id), f.desc])
	_table("Elements", "All 100, by atomic number. Rarity sets how often a card is offered.", ["Z", "Element", "Id", "Rarity", "Cost", "Family", "What it does"], prows)
	var irows: Array = []
	for id in Catalog.IMBUES:
		var r: Dictionary = Catalog.IMBUES[id]
		irows.append([r.name, "`%s`" % id, "$%d" % r.cost, r.desc])
	_table("Isotopes", "", ["Isotope", "Id", "Cost", "What it does"], irows)
	var crows: Array = []
	for id in Catalog.ITEMS:
		var it: Dictionary = Catalog.ITEMS[id]
		crows.append([it.name, "`%s`" % id, Catalog.WHEN_NAMES.get(it.when, it.when), "$%d" % it.cost, it.desc])
	_table("Catalysts", "Each recharges every table.", ["Catalyst", "Id", "When", "Cost", "What it does"], crows)
	var srows: Array = []
	for id in Catalog.BALL_TYPES:
		var bt: Dictionary = Catalog.BALL_TYPES[id]
		srows.append([bt.name + " ball", "`%s`" % id, "$%d" % bt.cost, bt.value, bt.desc])
	_table("Special balls", "", ["Ball", "Id", "Cost", "Value", "What it does"], srows)
	var qrows: Array = []
	for id in Catalog.CUES:
		var c: Dictionary = Catalog.CUES[id]
		var starts: Array = []
		for p in c.get("perks", []):
			starts.append(Catalog.PERKS[p].name)
		for t in c.get("tools", []):
			starts.append(Catalog.ITEMS[t].name)
		qrows.append([c.name, "`%s`" % id, "$%d" % c.money, "%+d" % int(c.chalk) if int(c.chalk) != 0 else "0", ", ".join(starts), c.desc])
	_table("Starting cues", "", ["Cue", "Id", "Money", "Chalk", "Starts with", "Description"], qrows)

	# Side bets.
	var bet_rows: Array = []
	for id in Catalog.BOUNTIES:
		var bt: Dictionary = Catalog.BOUNTIES[id]
		bet_rows.append([bt.name, "`%s`" % id, Catalog.BET_TIERS[int(bt.tier)], "%d× (+0.5× every 3 tables, up to +1×)" % (1 + int(bt.tier))])
	_table("Side bets", "Stakes are in the tables section above. The stake is capped at your money when the bet is dealt, and with less than $%d there is no bet. Peeking costs half the stake." % RunState.MIN_BET, ["Bet", "Id", "Tier", "Wins"], bet_rows)

	var f := FileAccess.open("res://docs/BALANCE_REVIEW.md", FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("WROTE docs/BALANCE_REVIEW.md (%d lines)" % lines.size())
	var j := FileAccess.open("res://docs/balance_data.json", FileAccess.WRITE)
	j.store_string(JSON.stringify({"generated": Time.get_date_string_from_system(), "sections": sections}))
	j.close()
