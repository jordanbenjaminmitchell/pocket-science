class_name Meta
extends RefCounted
## Lifetime progression: milestones unlock Formulas and Cues across runs.
## Stored in user://settings.cfg, section "meta". A fresh profile starts with
## the Classic Maple cue and the core Formula pool.

const PATH := "user://settings.cfg"

## id -> {name, hint, formulas, cue}
const MILESTONES := {
	"first_clear": {"name": "First Clear", "hint": "Clear your first table", "formulas": [], "cue": "optic"},
	"bank": {"name": "Angles", "hint": "Sink a bank shot", "formulas": ["precision", "boomerang", "stun", "afterburner"], "cue": ""},
	"boss": {"name": "Boss Breaker", "hint": "Clear a boss table", "formulas": ["ricochet", "cushion", "geometry", "tracer"], "cue": "hotrod"},
	"triple": {"name": "Hat Trick", "hint": "Pot 3 or more balls in one shot", "formulas": ["supernova", "fusion", "domino"], "cue": ""},
	"streak5": {"name": "On Fire", "hint": "Reach a streak of 5", "formulas": ["rhythm", "hothand", "comeback"], "cue": "momentum"},
	"pots40": {"name": "Regular", "hint": "Pot 40 balls in total", "formulas": ["lowball", "highball", "fibonacci", "rotation", "moneyball"], "cue": ""},
	"table6": {"name": "Deep Run", "hint": "Clear table 6", "formulas": ["venture", "hunter", "coupon", "overflow", "thrift"], "cue": "gilded"},
	"big": {"name": "Big Number", "hint": "Score 1,000 or more in one shot", "formulas": ["echo", "glasscannon", "minimalist"], "cue": ""},
	"lab": {"name": "Field Work", "hint": "Clear a table in any special lab", "formulas": ["featherweight", "velvet", "migration"], "cue": ""},
	"win": {"name": "Pocket Scientist", "hint": "Win a run", "formulas": ["collector", "oracle"], "cue": "glass"},
	"combos10": {"name": "Chain Gang", "hint": "Pot 10 combinations in total", "formulas": [], "cue": "breaker"},
	"banks10": {"name": "Rail Bird", "hint": "Sink 10 bank shots in total", "formulas": [], "cue": "angle"},
	"hot15": {"name": "Heat Seeker", "hint": "Pot 15 balls into hot pockets in total", "formulas": [], "cue": "thermal"},
	"rich": {"name": "Well Funded", "hint": "Hold $30 at once", "formulas": [], "cue": "banker"},
}

var earned: Array = []
var max_stake := 0          # highest difficulty unlocked
var lifetime_pots := 0
var lifetime_combos := 0
var lifetime_banks := 0
var lifetime_hot := 0
var unlock_all := false   # bots, tests and dev builds


func load_file() -> void:
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	earned = (c.get_value("meta", "earned", []) as Array).filter(func(x): return MILESTONES.has(x))
	max_stake = int(c.get_value("meta", "stake", 0))
	lifetime_pots = int(c.get_value("meta", "pots", 0))
	lifetime_combos = int(c.get_value("meta", "combos", 0))
	lifetime_banks = int(c.get_value("meta", "banks", 0))
	lifetime_hot = int(c.get_value("meta", "hot", 0))


func save_file() -> void:
	var c := ConfigFile.new()
	c.load(PATH)
	c.set_value("meta", "earned", earned)
	c.set_value("meta", "stake", max_stake)
	c.set_value("meta", "pots", lifetime_pots)
	c.set_value("meta", "combos", lifetime_combos)
	c.set_value("meta", "banks", lifetime_banks)
	c.set_value("meta", "hot", lifetime_hot)
	c.save(PATH)


func locked_formulas() -> Array:
	if unlock_all:
		return []
	var out: Array = []
	for m in MILESTONES:
		if not earned.has(m):
			out.append_array(MILESTONES[m].formulas)
	return out


func cue_unlocked(id: String) -> bool:
	if unlock_all or id == "maple":
		return true
	for m in MILESTONES:
		if MILESTONES[m].cue == id:
			return earned.has(m)
	return true


func cue_hint(id: String) -> String:
	for m in MILESTONES:
		if MILESTONES[m].cue == id:
			return MILESTONES[m].hint
	return ""


func formula_hint(id: String) -> String:
	for m in MILESTONES:
		if (MILESTONES[m].formulas as Array).has(id):
			return MILESTONES[m].hint
	return ""


func progress() -> String:
	return "%d / %d milestones" % [earned.size(), MILESTONES.size()]


## --- event hooks. Each returns the milestones newly earned (usually none).
func on_shot(res: Dictionary, run: RunState) -> Array:
	if not res.get("scored", false):
		return []
	lifetime_pots += res.potted.size()
	var got: Array = []
	if res.lines.any(func(l): return str(l.label).begins_with("Bank")):
		got.append("bank")
	if res.potted.size() >= 3:
		got.append("triple")
	if run.streak >= 5:
		got.append("streak5")
	if lifetime_pots >= 40:
		got.append("pots40")
	if res.total >= 1000:
		got.append("big")
	for l in res.lines:
		if l.label == "Combination":
			lifetime_combos += 1
		elif str(l.label).begins_with("Bank"):
			lifetime_banks += 1
		elif l.label == "Hot pocket":
			lifetime_hot += 1
	if lifetime_combos >= 10:
		got.append("combos10")
	if lifetime_banks >= 10:
		got.append("banks10")
	if lifetime_hot >= 15:
		got.append("hot15")
	if run.money >= 30:
		got.append("rich")
	return _earn(got)


func on_table_cleared(run: RunState) -> Array:
	var got: Array = ["first_clear"]
	var t := run.current()
	if t.get("anomaly", "") != "":
		got.append("boss")
	if run.table_index >= 5:
		got.append("table6")
	if t.lab != "standard":
		got.append("lab")
	return _earn(got)


## Winning at the highest unlocked Stake opens the next one. Returns newly earned milestones.
func on_win(stake: int = 0) -> Array:
	if stake >= max_stake:
		max_stake = mini(stake + 1, Catalog.STAKES.size() - 1)
	return _earn(["win"])


func _earn(ids: Array) -> Array:
	var fresh: Array = []
	for m in ids:
		if not earned.has(m):
			earned.append(m)
			fresh.append(m)
	save_file()
	return fresh


## Human-readable summary of what a milestone unlocks.
static func reward_text(id: String) -> String:
	var m: Dictionary = MILESTONES[id]
	var parts: Array = []
	if m.cue != "":
		parts.append(Catalog.CUES[m.cue].name)
	for f in m.formulas:
		parts.append(Catalog.FORMULAS[f].name)
	return ", ".join(parts)
