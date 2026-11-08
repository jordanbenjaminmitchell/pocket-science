class_name Records
extends RefCounted
## Local history of finished runs, in user://records.json. Lifetime totals and
## daily bests are derived from the entries, so they can never disagree.

const PATH := "user://records.json"
const MAX_ENTRIES := 500

var entries: Array = []


func load_file() -> void:
	entries = []
	if not FileAccess.file_exists(PATH):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(d) == TYPE_DICTIONARY and typeof(d.get("runs")) == TYPE_ARRAY:
		entries = (d.runs as Array).filter(func(e): return typeof(e) == TYPE_DICTIONARY and e.has("id"))


func save_file() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"v": 1, "runs": entries}))


## Adds a finished run, or updates it (a winner who continues into endless).
func record(run: RunState, won: bool) -> void:
	if run.record_id == "":
		run.record_id = "%d_%d" % [Time.get_unix_time_from_system(), run.seed_value]
	var e := {
		"id": run.record_id, "date": Time.get_date_string_from_system(), "seed": run.seed_value, "cue": run.cue,
		"won": won or run.endless, "tables": run.tables_cleared, "score": run.total_score, "pots": run.total_pots,
		"best_shot": run.best_shot, "best_heat": run.best_heat, "perks": run.perks.duplicate(),
		"daily": run.daily_key, "handicap": run.handicap,
	}
	for i in entries.size():
		if entries[i].id == run.record_id:
			entries[i] = e
			save_file()
			return
	entries.append(e)
	if entries.size() > MAX_ENTRIES:
		entries = entries.slice(entries.size() - MAX_ENTRIES)
	save_file()


func lifetime() -> Dictionary:
	var out := {"runs": entries.size(), "wins": 0, "tables": 0, "pots": 0, "best_shot": 0, "best_heat": 0, "best_tables": 0}
	for e in entries:
		out.wins += 1 if e.won else 0
		out.tables += int(e.tables)
		out.pots += int(e.pots)
		out.best_shot = maxi(out.best_shot, int(e.best_shot))
		out.best_heat = maxi(out.best_heat, int(e.best_heat))
		out.best_tables = maxi(out.best_tables, int(e.tables))
	return out


## Most-carried Perks across all finished runs: [[id, count], ...].
func favourites(n: int = 5) -> Array:
	var counts := {}
	for e in entries:
		for f in e.perks:
			counts[f] = counts.get(f, 0) + 1
	var rows: Array = []
	for f in counts:
		if Catalog.PERKS.has(f):
			rows.append([f, counts[f]])
	rows.sort_custom(func(a, b): return a[1] > b[1])
	return rows.slice(0, n)


## Best attempt at a daily, or {} if not played: most tables, then highest score.
func daily_best(key: String) -> Dictionary:
	var best := {}
	for e in entries:
		if e.get("daily", "") != key:
			continue
		if best.is_empty() or int(e.tables) > int(best.tables) or (int(e.tables) == int(best.tables) and int(e.score) > int(best.score)):
			best = e
	return best


static func today_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d%02d%02d" % [d.year, d.month, d.day]


static func daily_seed(key: String) -> int:
	return int(key) * 7 + 13


static func daily_cue(key: String) -> String:
	var cues := Catalog.CUES.keys()
	return cues[daily_seed(key) % cues.size()]
