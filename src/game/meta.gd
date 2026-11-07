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
	"lab": {"name": "Field Work", "hint": "Clear a Cryo, Gravity, Cyclotron or Spring table", "formulas": ["featherweight", "velvet", "migration"], "cue": ""},
	"win": {"name": "Pocket Scientist", "hint": "Win a run", "formulas": ["collector", "oracle"], "cue": ""},
}

var earned: Array = []
var lifetime_pots := 0
var unlock_all := false   # bots, tests and dev builds


func load_file() -> void:
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	earned = (c.get_value("meta", "earned", []) as Array).filter(func(x): return MILESTONES.has(x))
	lifetime_pots = int(c.get_value("meta", "pots", 0))


func save_file() -> void:
	var c := ConfigFile.new()
	c.load(PATH)
	c.set_value("meta", "earned", earned)
	c.set_value("meta", "pots", lifetime_pots)
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
	return _earn(got)


func on_table_cleared(run: RunState) -> Array:
	var got: Array = ["first_clear"]
	var t := run.current()
	if t.get("anomaly", "") != "":
		got.append("boss")
	if run.table_index >= 5:
		got.append("table6")
	if t.lab in ["cryo", "gravity", "cyclotron", "spring"]:
		got.append("lab")
	return _earn(got)


func on_win() -> Array:
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
