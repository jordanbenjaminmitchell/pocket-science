extends SceneTree
## The 8-ball is an obstacle unless your Perks say otherwise, every table racks
## all 15 balls, and solids and stripes are real builds.

var failures := 0
const TARGET := 1000
const PENALTY := 150


func check(c: bool, m: String) -> void:
	print("  ", "ok  " if c else "FAIL ", m)
	if not c:
		failures += 1


func pot(n: int, k: int = 0, rails: int = 0) -> Dictionary:
	return {"type": "pocket", "a": n, "pocket": k, "rails": rails, "at": Vector2.ZERO}


func hit(a: int, b: int) -> Dictionary:
	return {"type": "ball", "a": a, "b": b}


func score(events: Array, extra: Dictionary = {}) -> Dictionary:
	var c := {"perks": [], "imbues": {}, "hot_pocket": -1, "boss": "local", "lab": "standard", "anomaly": "", "heat": 0,
		"power": 0.5, "shots_taken": 0, "events": events, "target": TARGET, "objects": 10}
	c.merge(extra, true)
	return Scorer.score(c)


func _initialize() -> void:
	var h8 := [hit(0, 8), pot(8)]
	print("the 8-ball")
	var r := score(h8)
	check(not r.scored and r.foul == Scorer.EIGHT_FOUL and r.penalty == PENALTY, "dropping the 8 early costs 15% of the target and scores nothing")
	r = score([hit(0, 5), pot(5), pot(8, 2)])
	check(r.scored and r.total == 20 and r.penalty == PENALTY, "other balls still pay, and the penalty still lands")
	r = score(h8, {"objects": 1})
	check(r.scored and r.total == 26 and r.penalty == 0 and r.last_eight, "the 8 is safe once it is the last ball")
	r = score(h8, {"is_break": true})
	check(r.penalty == 0, "the 8 going down on the break is not punished")
	r = score([hit(0, 5), pot(0), pot(8, 2)])
	check(r.foul == "Scratch" and r.penalty == PENALTY, "a scratch does not excuse the 8")
	var run := RunState.new()
	run.start(3)
	run.begin_table()
	run.score = 40
	var chalk0 := run.chalk
	run.apply_shot({"scored": false, "foul": Scorer.EIGHT_FOUL, "total": 0, "money": 0, "catalyst_gain": 0.0, "potted": [8], "shattered": [], "lines": [], "penalty": 25}, false, 9, true)
	check(run.score == 15 and run.chalk == chalk0, "the penalty comes off the score and costs no Chalk")
	run.apply_shot({"scored": false, "foul": Scorer.EIGHT_FOUL, "total": 0, "money": 0, "catalyst_gain": 0.0, "potted": [8], "shattered": [], "lines": [], "penalty": 500}, false, 9, true)
	check(run.score == 0, "the score never goes below zero")

	print("8-ball Elements")
	r = score(h8, {"perks": ["eight"]})
	check(r.scored and r.total == 26 and r.penalty == 0 and r.money == 3, "Behind the 8 removes the penalty, pays normally and pays $3")
	r = score(h8, {"perks": ["darkhorse"]})
	check(r.total == 208 and r.penalty == PENALTY, "Dark Horse pays ×8 but keeps the penalty")
	r = score(h8, {"perks": ["hushmoney"]})
	check(r.penalty == 0 and r.eight_fine == 3, "Hush Money swaps points for $3")
	r = score([hit(0, 8), hit(8, 5), pot(5)], {"perks": ["kissblack"]})
	check(r.total == 50, "Kiss the Black: each touch of the 8 adds Chain (%d)" % r.total)
	check(score([hit(0, 5), pot(5)], {"perks": ["steerclear"]}).total == 35, "Steer Clear pays when the 8 is untouched")
	check(score([hit(0, 8), hit(0, 5), pot(5)], {"perks": ["steerclear"]}).total == 20, "and not when it was touched")
	r = score(h8, {"perks": ["lastcall"], "objects": 1})
	check(r.total == 130 and r.money == 5, "Last Call pays ×5 and $5 on a last 8")
	check(score([hit(0, 5), pot(5)], {"perks": ["eightcount"], "total_pots": 7}).total == 60, "Eight Count triples every 8th pot")
	check(score([hit(0, 5), pot(5)], {"perks": ["eightcount"], "total_pots": 3}).total == 20, "and only every 8th")
	r = score(h8, {"perks": ["trouble"]})
	check(r.scored and r.heat_gain == 3 and r.penalty == PENALTY, "Trouble Maker turns the penalty into Heat")

	print("solids and stripes")
	var s5 := [hit(0, 5), pot(5)]
	var s12 := [hit(0, 12), pot(12)]
	check(score(s5, {"perks": ["solids"]}).total == 55, "Solids +35")
	check(score(s12, {"perks": ["stripes"]}).total == 51, "Stripes ×1.5")
	check(score([hit(0, 2), pot(2)], {"perks": ["lowball"]}).total == 14, "Lithium Cell changes physics, not points")
	check(score([hit(0, 14), pot(14)], {"perks": ["highball"]}).total == 95 and score(s12, {"perks": ["highball"]}).total == 34, "High Roller: balls 13-15 ×2.5, nothing else")
	check(score(s5, {"perks": ["solidgold"]}).money == 1, "Solid Gold pays $1")
	check(score(s5, {"perks": ["bedrock"]}).heat_gain == 1, "Bedrock: only solids adds Heat")
	check(score([hit(0, 5), pot(5), pot(12, 2)], {"perks": ["bedrock"]}).heat_gain == 0, "but not with a stripe in the shot")
	check(score(s5, {"perks": ["steadyrun"], "solid_run": 3}).total == 56, "Steady Run builds value")
	check(score([hit(0, 5), pot(5), pot(12, 2)], {"perks": ["steadyrun"], "solid_run": 3}).solid_run == 0, "a stripe resets it")
	check(score(s5, {"perks": ["solidsonly"]}).total == 60 and score(s12, {"perks": ["solidsonly"]}).total == 17, "Solids Only ×3 and stripes ×0.5")
	check(score(s12, {"perks": ["stripesonly"]}).total == 68 and score(s5, {"perks": ["stripesonly"]}).total == 10, "Stripes Only ×2 and solids ×0.5")
	check(score(s5, {"perks": ["lastsolid"], "on_table": [5, 8, 9, 12]}).total == 160, "Last Solid ×8")
	check(score(s5, {"perks": ["lastsolid"], "on_table": [5, 3, 9]}).total == 20, "only on the last one")
	check(score(s12, {"perks": ["racing"], "power": 0.7}).total == 34, "Rubidium Rush changes physics, not points")
	var fz := score([hit(0, 3), pot(3), pot(5, 2), pot(0, 1)], {"perks": ["followthru"]})
	check(fz.scored and fz.foul == "" and fz.get("scratch_saved", false), "Francium Fizz: a scratch with 2 sinks still scores")
	check(score([hit(0, 3), pot(3), pot(0, 1)], {"perks": ["followthru"]}).foul == "Scratch", "but not with only 1")
	check(score(s12, {"perks": ["tiger"], "stripe_run": 2}).total == 51, "Tiger Stripes builds Chain")
	var fam := {"solid": 0, "stripe": 0, "eight": 0}
	for id in Catalog.PERKS:
		var f: String = Catalog.PERKS[id].fam
		if fam.has(f):
			fam[f] += 1
		check(IconArt.MOTIFS.has(id), "%s has an icon" % id) if not IconArt.MOTIFS.has(id) else null
	check(fam.solid == 7 and fam.stripe == 7, "seven Elements each for solids and stripes")
	check(fam.eight == 8, "eight Elements in the 8-ball set")

	print("racks")
	var sim := PoolSim.new(TableLayout.new().build(1.0, []))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	Rack.build(sim, rng)
	var nums := Array(sim.num)
	nums.sort()
	check(nums == range(1, 16), "a rack is all 15 balls")
	check(sim.num[4] == 8, "the 8 sits in the middle")
	for t in Catalog.TABLES:
		check(not t.has("rack"), "no table uses a smaller rack")

	print("eight and suits tests: %d failures" % failures)
	quit(1 if failures > 0 else 0)
